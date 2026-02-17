#!/bin/bash
# cluster-setup-everything.sh
# Automates eks cluster creation
# Tom Dean
# Last edit: 2/16/2026

# Set environment variables

source vars.sh

# Create the eks cluster

echo
echo "Creating EKS Cluster..."
envsubst < manifests/eks-cluster.yaml | eksctl create cluster --profile $AWS_PROFILE --config-file -
echo
eksctl get cluster
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

# Install Gateway API CRDs

kubectl apply -f https://github.com/kubernetes-sigs/gateway-api/releases/download/v1.4.0/standard-install.yaml

# Add and update the SPIRE Helm Repository

echo
helm repo add spire-h https://spiffe.github.io/helm-charts-hardened/
helm repo update
echo

# Install SPIRE CRDs

helm upgrade --install -n spire-server spire-crds spire-h/spire-crds --create-namespace --version $SPIRE_VERSION

# Install SPIRE Server/Agent

envsubst < manifests/spire-values.yaml | helm upgrade --install -n spire-server spire spire-h/spire --version $SPIRE_VERSION -f -

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
tag: ${ISTIO_IMAGE}
terminationGracePeriodSeconds: 29
variant: distroless
EOF
echo

# Verify Istio installation

watch -n 1 kubectl get pods -A | grep -E "istio|ztunnel"

# Deploy the 'movies' application

echo
kubectl apply -k movies
echo
kubectl label ns movies istio.io/dataplane-mode=ambient
echo

# Install Grafana using Helm

#helm repo add grafana https://grafana.github.io/helm-charts
#helm repo update
#helm install grafana -n grafana --create-namespace grafana/grafana \
#  -f manifests/grafana-values.yaml --debug

exit 0
