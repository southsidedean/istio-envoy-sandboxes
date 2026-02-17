#!/bin/bash
# cluster-setup-everything.sh
# Automates eks cluster creation
# Tom Dean
# Last edit: 2/16/2026

set -e

# Set environment variables

source vars.sh

# Create the eks cluster

echo
echo "Creating EKS Cluster..."
envsubst < manifests/eks-cluster.yaml | eksctl create cluster --profile $AWS_PROFILE --config-file -
echo
eksctl get cluster --profile $AWS_PROFILE --region $AWS_REGION
echo

# Display the kubectl contexts

kubectx

# Install the 'istioctl' CLI tool

OS=$(uname | tr '[:upper:]' '[:lower:]' | sed -E 's/darwin/osx/')
ARCH=$(uname -m | sed -E 's/aarch/arm/; s/x86_64/amd64/; s/armv7l/armv7/')
echo $OS
echo $ARCH
mkdir -p ~/.istioctl/bin
curl -sSL https://storage.googleapis.com/istio-binaries-$REPO_KEY/$ISTIO_IMAGE/istioctl-$ISTIO_IMAGE-$OS-$ARCH.tar.gz | tar xzf - -C ~/.istioctl/bin
chmod +x ~/.istioctl/bin/istioctl
export PATH=${HOME}/.istioctl/bin:${PATH}

echo "Istio "`istioctl version --remote=false`" installed!"

# Install Gateway API CRDs (standard + experimental)
echo
echo "Installing Gateway API v"$GATEWAY_API_VERSION" CRDs (standard + experimental)..."
kubectl apply -f https://github.com/kubernetes-sigs/gateway-api/releases/download/v$GATEWAY_API_VERSION/standard-install.yaml
kubectl apply --server-side -f https://github.com/kubernetes-sigs/gateway-api/releases/download/v$GATEWAY_API_VERSION/experimental-install.yaml
echo

# Install kgateway (Gateway API controller)

echo
echo "Installing kgateway ${KGATEWAY_VERSION}..."
echo
helm upgrade --install kgateway-crds oci://cr.kgateway.dev/kgateway-dev/charts/kgateway-crds \
  --namespace kgateway-system \
  --create-namespace \
  --version ${KGATEWAY_VERSION} \
  --set controller.image.pullPolicy=Always
helm upgrade --install kgateway oci://cr.kgateway.dev/kgateway-dev/charts/kgateway \
  --namespace kgateway-system \
  --version ${KGATEWAY_VERSION} \
  --set controller.image.pullPolicy=Always \
  --set controller.extraEnv.KGW_ENABLE_GATEWAY_API_EXPERIMENTAL_FEATURES=true
echo
sleep 30
kubectl get pods -n kgateway-system
echo

# Add and update the SPIRE Helm Repository

#echo
#helm repo add spire-h https://spiffe.github.io/helm-charts-hardened/
#helm repo update
#echo

# Install SPIRE CRDs

helm upgrade --install -n spire-mgmt spire-crds spire-crds --repo https://spiffe.github.io/helm-charts-hardened/ --create-namespace --version $SPIRE_VERSION

# Install SPIRE Server/Agent

envsubst < manifests/spire-values.yaml | helm upgrade --install -n spire-mgmt spire spire --repo https://spiffe.github.io/helm-charts-hardened/ -f -

# Wait for SPIRE CRDs to be established

kubectl wait --for=condition=Established crd clusterspiffeids.spire.spiffe.io --timeout=60s

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
