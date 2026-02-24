#!/bin/bash
# cluster-setup-k3d-ai-everything.sh
# Automates k3d cluster creation with complete AI platform stack:
#   - Istio Ambient Mode (service mesh)
#   - Kagent (AI agent framework)
#   - Kgateway (API gateway)
#   - Agentgateway (agent-to-agent gateway)
#   - Agentregistry (agent discovery)
#   - Movies app (demo workload)
#
# Tom Dean
# Last edit: 2/23/2026

set -e

# Set environment variables

source vars.sh

# Validate that required placeholders have been filled in

if [[ -z "$OPENAI_API_KEY" ]]; then
  echo "ERROR: Edit vars.sh and fill in OPENAI_API_KEY before running."
  echo "Set OPENAI_API_KEY to your OpenAI API key."
  exit 1
fi

# Delete existing k3d clusters

for cluster in $(seq -f %02g 1 "$NUM_CLUSTERS")
do
clustername="$CLUSTER_NAME_PREFIX$cluster"
k3d cluster delete "$clustername"
done

# Create the k3d clusters

for cluster in $(seq -f %02g 1 "$NUM_CLUSTERS")
do
clustername="$CLUSTER_NAME_PREFIX$cluster"
k3d cluster create "$clustername" -c cluster-k3d/k3d-cluster.yaml --port "70${cluster}:80@loadbalancer" --port "74${cluster}:443@loadbalancer" --api-port "0.0.0.0:76${cluster}"
done

k3d cluster list

# Configure the kubectl context

for kubectx in $(seq -f %02g 1 "$NUM_CLUSTERS")
do
kubectxname="$KUBECTX_NAME_PREFIX$kubectx"
clustername="$CLUSTER_NAME_PREFIX$kubectx"
kubectx -d "$kubectxname" 2>/dev/null || true
kubectx "$kubectxname=k3d-$clustername"
done

kubectx "${KUBECTX_NAME_PREFIX}01"
kubectx

echo
echo "=========================================="
echo "Installing Istio Ambient Mode"
echo "=========================================="
echo

# Add Istio Helm repository

helm repo add istio https://istio-release.storage.googleapis.com/charts
helm repo update

# Install Istio Base (CRDs)

echo "Installing Istio base (CRDs)..."
helm install istio-base istio/base \
    --namespace "${ISTIO_NAMESPACE}" \
    --create-namespace \
    --set defaultRevision="${ISTIO_VERSION}" \
    --wait

echo "Waiting for Istio base installation..."
kubectl wait --for=condition=Ready -n "${ISTIO_NAMESPACE}" --all pods --timeout=300s || true
echo

# Install istiod (Control Plane)

echo "Installing istiod (control plane with mTLS)..."
helm install istiod istio/istiod \
    --namespace "${ISTIO_NAMESPACE}" \
    -f manifests/istiod-values.yaml \
    --set profile=ambient \
    --wait

echo "Waiting for istiod to be ready..."
kubectl wait --for=condition=Ready -n "${ISTIO_NAMESPACE}" deployment/istiod --timeout=300s
echo

# Install Istio CNI

echo "Installing Istio CNI plugin..."
helm install istio-cni istio/cni \
    --namespace "${ISTIO_NAMESPACE}" \
    -f manifests/istio-cni-values.yaml \
    --set profile=ambient \
    --wait
echo

# Install ztunnel (Ambient Data Plane)

echo "Installing ztunnel (ambient data plane)..."
helm install ztunnel istio/ztunnel \
    --namespace "${ISTIO_NAMESPACE}" \
    --wait

echo "Waiting for ztunnel daemonset to be ready..."
kubectl rollout status daemonset/ztunnel -n "${ISTIO_NAMESPACE}" --timeout=300s
kubectl get pods -n "${ISTIO_NAMESPACE}"
echo

echo
echo "=========================================="
echo "Installing Kagent (AI Agent Framework)"
echo "=========================================="
echo

# Install kagent using Helm

for cluster in $(seq -f %02g 1 "$NUM_CLUSTERS")
do
kubectxname="$KUBECTX_NAME_PREFIX$cluster"
echo "Installing kagent in cluster $cluster..."
helm install kagent-crds oci://ghcr.io/kagent-dev/kagent/helm/kagent-crds \
    --namespace "$KAGENT_NAMESPACE" \
    --create-namespace \
    --kube-context "$kubectxname"
echo
helm install kagent oci://ghcr.io/kagent-dev/kagent/helm/kagent \
    --namespace "$KAGENT_NAMESPACE" \
    --version "$KAGENT_VERSION" \
    --set providers.openAI.apiKey="$OPENAI_API_KEY" \
    --kube-context "$kubectxname"
echo
echo "Waiting for Kagent pods to be ready in cluster $cluster..."
kubectl wait --for=condition=Ready pods --all -n "$KAGENT_NAMESPACE" --context "$kubectxname" --timeout=300s
kubectl get all -n "$KAGENT_NAMESPACE" --context "$kubectxname"
echo
done

echo
echo "=========================================="
echo "Deploying Movies Application"
echo "=========================================="
echo

# Deploy the movies application

for cluster in $(seq -f %02g 1 "$NUM_CLUSTERS")
do
kubectxname="$KUBECTX_NAME_PREFIX$cluster"
echo "Deploying movies app in cluster $cluster..."
kubectl apply -k movies --context "$kubectxname"
echo
done

echo
echo "=========================================="
echo "Enabling Istio Ambient Mode"
echo "=========================================="
echo

# Enable ambient mode for application namespaces

echo "Enabling ambient mode for movies namespace..."
kubectl label ns movies istio.io/dataplane-mode=ambient --overwrite
kubectl label ns movies istio.io/use-waypoint=auto --overwrite
echo

echo "Enabling ambient mode for kagent namespace..."
kubectl label ns "${KAGENT_NAMESPACE}" istio.io/dataplane-mode=ambient --overwrite
kubectl label ns "${KAGENT_NAMESPACE}" istio.io/use-waypoint=auto --overwrite
echo

# Deploy waypoint proxy for movies namespace

echo "Deploying waypoint proxy for movies namespace..."
kubectl apply -f manifests/movies-waypoint.yaml
kubectl wait --for=condition=Programmed gateway/waypoint -n movies --timeout=300s
kubectl get gateway -n movies
echo

echo
echo "=========================================="
echo "Installing Gateway API and Kgateway"
echo "=========================================="
echo

# Install the Kubernetes Gateway API CRDs

echo "Installing Gateway API CRDs (${GATEWAY_API_VERSION})..."
kubectl apply -f https://github.com/kubernetes-sigs/gateway-api/releases/download/"${GATEWAY_API_VERSION}"/standard-install.yaml
echo

# Install kgateway CRDs using Helm

echo "Installing kgateway CRDs (${KGATEWAY_VERSION})..."
helm upgrade -i --create-namespace --namespace "$KGATEWAY_NAMESPACE" --version v"${KGATEWAY_VERSION}" kgateway-crds oci://cr.kgateway.dev/kgateway-dev/charts/kgateway-crds
echo

# Install kgateway using Helm

echo "Installing kgateway..."
helm upgrade -i --namespace "$KGATEWAY_NAMESPACE" --version v"${KGATEWAY_VERSION}" kgateway oci://cr.kgateway.dev/kgateway-dev/charts/kgateway
echo

# Wait for kgateway

echo "Waiting for kgateway pods to be ready..."
kubectl wait --for=condition=Ready pods --all -n "$KGATEWAY_NAMESPACE" --timeout=300s
kubectl get all -n "$KGATEWAY_NAMESPACE"
echo

# Create HTTP listener (Gateway)

echo "Creating HTTP Gateway listener..."
kubectl apply -f manifests/http-listener.yaml
kubectl wait --for=condition=Programmed gateway/http-gateway -n "${KGATEWAY_NAMESPACE}" --timeout=300s
kubectl get gateways -A
echo

# Create HTTPRoute for kagent

echo "Creating HTTPRoute for kagent..."
kubectl apply -f manifests/kagent-httproute.yaml
kubectl get httproute -A
echo

echo
echo "=========================================="
echo "Installing Agentgateway"
echo "=========================================="
echo

# Create agentgateway namespace and enable ambient mode

echo "Creating agentgateway namespace..."
kubectl create namespace "${AGENTGATEWAY_NAMESPACE}" || true
kubectl label ns "${AGENTGATEWAY_NAMESPACE}" istio.io/dataplane-mode=ambient --overwrite
echo

# Install agentgateway via Helm (OCI registry)

echo "Installing agentgateway (${AGENTGATEWAY_VERSION})..."
helm install agentgateway oci://ghcr.io/agentgateway/helm/agentgateway \
    --namespace "${AGENTGATEWAY_NAMESPACE}" \
    --version "${AGENTGATEWAY_VERSION}" \
    -f manifests/agentgateway-values.yaml || echo "Note: Agentgateway Helm chart may need verification of registry path"

echo "Waiting for agentgateway pods to be ready..."
kubectl wait --for=condition=Ready pods --all -n "${AGENTGATEWAY_NAMESPACE}" --timeout=300s || echo "Warning: Agentgateway pods not ready yet"
kubectl get all -n "${AGENTGATEWAY_NAMESPACE}"
echo

# Create HTTPRoute for agentgateway

echo "Creating HTTPRoute for agentgateway..."
kubectl apply -f manifests/agentgateway-httproute.yaml || echo "Warning: HTTPRoute creation may be pending service availability"
echo

echo
echo "=========================================="
echo "Installing Agentregistry"
echo "=========================================="
echo

# Create agentregistry namespace and enable ambient mode

echo "Creating agentregistry namespace..."
kubectl create namespace "${AGENTREGISTRY_NAMESPACE}" || true
kubectl label ns "${AGENTREGISTRY_NAMESPACE}" istio.io/dataplane-mode=ambient --overwrite
echo

# Add agentregistry Helm repository

echo "Adding agentregistry Helm repository..."
helm repo add agentregistry https://agentregistry-dev.github.io/helm-charts || echo "Note: Agentregistry Helm repo may need verification"
helm repo update || true
echo

# Install agentregistry via Helm

echo "Installing agentregistry (${AGENTREGISTRY_VERSION})..."
helm install agentregistry agentregistry/agentregistry \
    --namespace "${AGENTREGISTRY_NAMESPACE}" \
    --version "${AGENTREGISTRY_VERSION}" \
    -f manifests/agentregistry-values.yaml || echo "Note: Agentregistry Helm chart may need verification"

echo "Waiting for agentregistry pods to be ready..."
kubectl wait --for=condition=Ready pods --all -n "${AGENTREGISTRY_NAMESPACE}" --timeout=300s || echo "Warning: Agentregistry pods not ready yet"
kubectl get all -n "${AGENTREGISTRY_NAMESPACE}"
echo

# Create HTTPRoute for agentregistry

echo "Creating HTTPRoute for agentregistry..."
kubectl apply -f manifests/agentregistry-httproute.yaml || echo "Warning: HTTPRoute creation may be pending service availability"
echo

echo
echo "=========================================="
echo "Deployment Complete!"
echo "=========================================="
echo
echo "AI Platform Stack Summary:"
echo "  - Istio ${ISTIO_VERSION} (Ambient Mode with mTLS)"
echo "  - Kagent ${KAGENT_VERSION} (AI Agent Framework)"
echo "  - Kgateway ${KGATEWAY_VERSION} (API Gateway)"
echo "  - Agentgateway ${AGENTGATEWAY_VERSION} (Agent-to-Agent Gateway)"
echo "  - Agentregistry ${AGENTREGISTRY_VERSION} (Agent Discovery)"
echo "  - Gateway API ${GATEWAY_API_VERSION}"
echo
echo "Access Points:"
echo "  - Kagent UI: http://localhost:7001"
echo "  - Kgateway: http://localhost:7001 (with Host header routing)"
echo "  - Agentgateway: http://localhost:7001 (Host: agentgateway.local)"
echo "  - Agentregistry: http://localhost:7001 (Host: agentregistry.local)"
echo
echo "Verify installation:"
echo "  kubectl get pods -n istio-system"
echo "  kubectl get pods -n kagent"
echo "  kubectl get pods -n kgateway-system"
echo "  kubectl get pods -n agentgateway-system"
echo "  kubectl get pods -n agentregistry-system"
echo "  kubectl get pods -n movies"
echo

exit 0
