#!/bin/bash
# cluster-setup-everything.sh
# Automates eks cluster creation
# Tom Dean
# Last edit: 2/16/2026

set -e

# Set environment variables

source vars.sh

# Validate that required placeholders have been filled in

if [[ "$REPO_KEY" == *"INSERT"* ]] || [[ "$AWS_PROFILE" == *"INSERT"* ]] || \
   [[ "$SOLO_ISTIO_LICENSE_KEY" == *"INSERT"* ]] || [[ "$GRAFANA_ADMIN_PASSWORD" == *"INSERT"* ]]; then
  echo "ERROR: Edit vars.sh and fill in all required values before running."
  echo "Look for <<INSERT_..._HERE>> placeholders."
  exit 1
fi

# Create the eks cluster

echo
echo "Creating EKS Cluster..."
envsubst < manifests/eks-cluster.yaml | eksctl create cluster --profile "$AWS_PROFILE" --config-file -
echo
eksctl get cluster --profile "$AWS_PROFILE" --region "$AWS_REGION"
echo

# Display the kubectl contexts

kubectx

# Install the 'istioctl' CLI tool

echo
echo "Installing the istioctl CLI..."
echo
OS=$(uname | tr '[:upper:]' '[:lower:]' | sed -E 's/darwin/osx/')
ARCH=$(uname -m | sed -E 's/aarch/arm/; s/x86_64/amd64/; s/armv7l/armv7/')
echo "Operating system detected: "$OS
echo "Architecture detected: "$ARCH
echo
mkdir -p ~/.istioctl/bin
curl -sSL https://storage.googleapis.com/istio-binaries-"$REPO_KEY"/"$ISTIO_IMAGE"/istioctl-"$ISTIO_IMAGE"-"$OS"-"$ARCH".tar.gz | tar xzf - -C ~/.istioctl/bin
chmod +x ~/.istioctl/bin/istioctl
export PATH=${HOME}/.istioctl/bin:${PATH}
echo
echo "Istio "`istioctl version --remote=false`" installed!"
echo

# Install Gateway API CRDs (standard + experimental)
echo
echo "Installing Gateway API v${GATEWAY_API_VERSION} CRDs (standard + experimental)..."
kubectl apply -f https://github.com/kubernetes-sigs/gateway-api/releases/download/v"${GATEWAY_API_VERSION}"/standard-install.yaml
kubectl apply --server-side -f https://github.com/kubernetes-sigs/gateway-api/releases/download/v"${GATEWAY_API_VERSION}"/experimental-install.yaml
echo

# Install kgateway (Gateway API controller)

echo
echo "Installing kgateway ${KGATEWAY_VERSION}..."
echo
helm upgrade --install kgateway-crds oci://cr.kgateway.dev/kgateway-dev/charts/kgateway-crds \
  --namespace kgateway-system \
  --create-namespace \
  --version ${KGATEWAY_VERSION}
helm upgrade --install kgateway oci://cr.kgateway.dev/kgateway-dev/charts/kgateway \
  --namespace kgateway-system \
  --version ${KGATEWAY_VERSION} \
  --set controller.image.pullPolicy=Always \
  --set controller.extraEnv.KGW_ENABLE_GATEWAY_API_EXPERIMENTAL_FEATURES=true
echo
echo "Waiting for kgateway pods to be ready..."
kubectl wait --for=condition=Ready pods --all -n kgateway-system --timeout=120s
echo "kgateway pods are ready!"
kubectl get pods -n kgateway-system
echo

# SPIRE Prerequisites
# Create namespace

kubectl create namespace spire-server

# Create certificates

mkdir -p certs/{root-ca,intermediate-ca}
cd certs

cat >root-ca.cnf <<EOF
[req]
distinguished_name = req_distinguished_name
req_extensions = v3_req
prompt = no

[req_distinguished_name]
CN = SPIRE Root CA

[v3_req]
keyUsage = critical, keyCertSign, cRLSign
basicConstraints = critical, CA:true, pathlen:2
subjectKeyIdentifier = hash
EOF

cat >intermediate-ca.cnf <<EOF
[req]
distinguished_name = req_distinguished_name
req_extensions = v3_req
prompt = no

[req_distinguished_name]
CN = SPIRE Intermediate CA

[v3_req]
keyUsage = critical, keyCertSign, cRLSign
basicConstraints = critical, CA:true, pathlen:1
subjectKeyIdentifier = hash
EOF

# Create root CA

openssl genrsa -out root-ca/root-ca.key 2048
openssl req -new -x509 -key root-ca/root-ca.key -out root-ca/root-ca.crt -config root-ca.cnf -days 3650

# Create intermediate CA

openssl genrsa -out intermediate-ca/ca.key 2048
openssl req -new -key intermediate-ca/ca.key -out intermediate-ca/ca.csr -config intermediate-ca.cnf -subj "/CN=SPIRE INTERMEDIATE CA"

# Sign CSR with root CA

openssl x509 -req -in intermediate-ca/ca.csr -CA root-ca/root-ca.crt -CAkey root-ca/root-ca.key -CAcreateserial \
  -out intermediate-ca/ca.crt -days 1825 -extensions v3_req -extfile intermediate-ca.cnf

# Create the bundle file (intermediate + root)

cat intermediate-ca/ca.crt root-ca/root-ca.crt > intermediate-ca/ca-chain.pem

# Create the root CA bundle

cp root-ca/root-ca.crt root-ca-bundle.pem
cd ..

# Create a secret from the certificate

kubectl create secret generic spiffe-upstream-ca \
  --namespace spire-server \
  --from-file=tls.crt=certs/intermediate-ca/ca.crt \
  --from-file=tls.key=certs/intermediate-ca/ca.key \
  --from-file=bundle.crt=certs/intermediate-ca/ca-chain.pem

# Add Helm repository

helm repo add spire https://spiffe.github.io/helm-charts-hardened/
helm repo update spire

# Install SPIRE CRDs

helm upgrade -i spire-crds spire/spire-crds \
  --namespace spire-server \
  --create-namespace \
  --version ${SPIRE_CRD_VERSION} \
  --wait

# Install SPIRE Server/Agent

envsubst < manifests/spire-values.yaml | helm upgrade -i spire spire/spire --namespace spire-server --version "${SPIRE_VERSION}" -f -

# Wait for SPIRE CRDs to be established

kubectl wait --for=condition=Established crd clusterspiffeids.spire.spiffe.io --timeout=60s

# Wait for SPIRE components to be ready

echo "Waiting for SPIRE server pods to be ready..."
kubectl wait --for=condition=Ready pods --all -n spire-server --timeout=300s

# Register SPIRE workload identities (ClusterSPIFFEID resources)

kubectl apply -f manifests/istio-gateway-spiffeid.yaml

# Install Istio using Helm - USE SOLO IMAGES!
# Install Istio CRDs

echo
helm upgrade --install istio-base oci://${HELM_REPO}/base \
  --namespace istio-system \
  --create-namespace \
  --version ${ISTIO_IMAGE} \
  -f - <<EOF
defaultRevision: ""
profile: ambient
EOF
echo

# Install istiod control plane

echo
helm upgrade --install istiod oci://${HELM_REPO}/istiod \
  --namespace istio-system \
  --version ${ISTIO_IMAGE} \
  -f - <<EOF
global:
  hub: ${REPO}
  proxy:
    clusterDomain: cluster.local
  tag: ${ISTIO_IMAGE}
meshConfig:
  accessLogFile: /dev/stdout
  defaultConfig:
    proxyMetadata:
      ISTIO_META_DNS_AUTO_ALLOCATE: "true"
      ISTIO_META_DNS_CAPTURE: "true"
env:
  PILOT_ENABLE_IP_AUTOALLOCATE: "true"
  PILOT_SKIP_VALIDATE_TRUST_DOMAIN: "true"
pilot:
  cni:
    namespace: istio-system
    enabled: true
gateways:
  spire:
    workloads: true
profile: ambient
license:
  value: ${SOLO_ISTIO_LICENSE_KEY}
EOF
echo

# Install Istio CNI

echo
helm upgrade --install istio-cni oci://${HELM_REPO}/cni \
  --namespace istio-system \
  --version ${ISTIO_IMAGE} \
  -f - <<EOF
ambient:
  dnsCapture: true
excludeNamespaces:
  - istio-system
  - kube-system
global:
  hub: ${REPO}
  tag: ${ISTIO_IMAGE}
profile: ambient
EOF
echo

# Install ztunnel

echo
helm upgrade --install ztunnel oci://${HELM_REPO}/ztunnel \
  --namespace istio-system \
  --version ${ISTIO_IMAGE} \
  -f - <<EOF
configValidation: true
enabled: true
env:
  L7_ENABLED: "true"
hub: ${REPO}
istioNamespace: istio-system
namespace: istio-system
profile: ambient
proxy:
  clusterDomain: cluster.local
spire:
  enabled: true
tag: ${ISTIO_IMAGE}
terminationGracePeriodSeconds: 29
variant: distroless
EOF
echo

# Wait for Istio components to be ready

echo "Waiting for Istio pods to be ready..."
kubectl wait --for=condition=Ready pods --all -n istio-system --timeout=300s
echo "Istio pods are ready!"
echo
kubectl get pods -n istio-system

# Install Prometheus for Istio metrics

echo
echo "Installing Prometheus..."
helm repo add prometheus-community https://prometheus-community.github.io/helm-charts
helm repo update
helm install prometheus -n istio-system prometheus-community/prometheus \
  -f manifests/prometheus-values.yaml
echo

# Deploy the 'movies' application

echo
kubectl apply -k movies
echo
kubectl label ns movies istio.io/dataplane-mode=ambient
echo

# Install Grafana using Helm

echo
echo "Installing Grafana..."
helm repo add grafana https://grafana.github.io/helm-charts
helm repo update
helm install grafana -n grafana --create-namespace grafana/grafana \
  -f manifests/grafana-values.yaml \
  --set adminUser="${GRAFANA_ADMIN_USER}" \
  --set adminPassword="${GRAFANA_ADMIN_PASSWORD}"
echo

# Expose Grafana via kgateway (Gateway + HTTPRoute)

kubectl apply -f manifests/grafana-gateway.yaml

# Wait for the Gateway to be programmed

echo
echo "Waiting for Gateway to be programmed..."
kubectl wait --for=condition=Programmed gateway/http -n kgateway-system --timeout=120s
echo

# Print the Grafana external URL

GRAFANA_LB=$(kubectl get svc -n kgateway-system http -o jsonpath='{.status.loadBalancer.ingress[0].hostname}')
if [ -z "$GRAFANA_LB" ]; then
  GRAFANA_LB=$(kubectl get svc -n kgateway-system http -o jsonpath='{.status.loadBalancer.ingress[0].ip}')
fi
echo "============================================"
echo "Grafana is available at:"
echo "  http://${GRAFANA_LB}:8080/grafana"
echo ""
echo "Login credentials:"
echo "  Username: ${GRAFANA_ADMIN_USER}"
echo "  Password: ${GRAFANA_ADMIN_PASSWORD}"
echo "============================================"
echo

exit 0
