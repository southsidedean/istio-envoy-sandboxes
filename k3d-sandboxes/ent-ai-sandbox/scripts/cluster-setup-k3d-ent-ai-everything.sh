#!/bin/bash
# cluster-setup-k3d-ent-ai-everything.sh
# Automates k3d cluster creation with Enterprise AI platform stack:
#   - Solo Istio Distribution (Ambient Mode)
#   - Solo Enterprise for Kagent (AI agent framework)
#   - Solo Enterprise for Kgateway (API gateway)
#   - Solo Enterprise for Agentgateway (agent-to-agent gateway)
#   - Agentregistry OSS (agent discovery)
#   - Movies app (demo workload)
#
# Tom Dean
# Last edit: 3/27/2026

set -e

# Set environment variables

source vars.sh

# Validate that required placeholders have been filled in

if [[ -z "$OPENAI_API_KEY" ]]; then
  echo "ERROR: Edit vars.sh and fill in OPENAI_API_KEY before running."
  exit 1
fi

if [[ "$LICENSE_KEY" == *"INSERT"* || -z "$LICENSE_KEY" ]]; then
  echo "ERROR: Edit vars.sh and fill in LICENSE_KEY (Solo Enterprise for Kgateway)."
  exit 1
fi

if [[ -z "$AGENTGATEWAY_LICENSE_KEY" ]]; then
  echo "ERROR: Edit vars.sh and fill in AGENTGATEWAY_LICENSE_KEY (Solo Enterprise for Agentgateway)."
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
k3d cluster create "$clustername" -c cluster-k3d/k3d-cluster.yaml --port "${HTTP_PORT_PREFIX}${cluster}:80@loadbalancer" --port "${HTTPS_PORT_PREFIX}${cluster}:443@loadbalancer" --api-port "0.0.0.0:${API_PORT_PREFIX}${cluster}"
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
echo "Installing Solo Istio Distribution (Ambient Mode)"
echo "=========================================="
echo

# Install Istio Base (CRDs) via OCI

echo "Installing Istio base (CRDs)..."
helm upgrade -i istio-base oci://${HELM_REPO}/base \
    --namespace "${ISTIO_NAMESPACE}" \
    --create-namespace \
    --set defaultRevision="${ISTIO_VERSION}" \
    --version "${ISTIO_IMAGE}" \
    --wait

echo "Waiting for Istio base installation..."
kubectl wait --for=condition=Ready -n "${ISTIO_NAMESPACE}" --all pods --timeout=300s || true
echo

# Install istiod (Control Plane) via OCI

echo "Installing istiod (control plane with mTLS)..."
helm upgrade -i istiod oci://${HELM_REPO}/istiod \
    --namespace "${ISTIO_NAMESPACE}" \
    -f manifests/istiod-values.yaml \
    --set profile=ambient \
    --version "${ISTIO_IMAGE}" \
    --wait

echo "Waiting for istiod to be ready..."
kubectl wait --for=condition=Ready -n "${ISTIO_NAMESPACE}" deployment/istiod --timeout=300s
echo

# Install Istio CNI via OCI

echo "Installing Istio CNI plugin..."
helm upgrade -i istio-cni oci://${HELM_REPO}/cni \
    --namespace "${ISTIO_NAMESPACE}" \
    -f manifests/istio-cni-values.yaml \
    --set profile=ambient \
    --version "${ISTIO_IMAGE}" \
    --wait
echo

# Install ztunnel (Ambient Data Plane) via OCI

echo "Installing ztunnel (ambient data plane)..."
helm upgrade -i ztunnel oci://${HELM_REPO}/ztunnel \
    --namespace "${ISTIO_NAMESPACE}" \
    --version "${ISTIO_IMAGE}" \
    --wait

echo "Waiting for ztunnel daemonset to be ready..."
kubectl rollout status daemonset/ztunnel -n "${ISTIO_NAMESPACE}" --timeout=300s
kubectl get pods -n "${ISTIO_NAMESPACE}"
echo

echo
echo "=========================================="
echo "Installing Solo Enterprise for Kagent"
echo "=========================================="
echo

# Install kagent-enterprise CRDs

for cluster in $(seq -f %02g 1 "$NUM_CLUSTERS")
do
kubectxname="$KUBECTX_NAME_PREFIX$cluster"
echo "Installing Kagent Enterprise CRDs in cluster $cluster..."
helm upgrade -i kagent-crds \
    oci://us-docker.pkg.dev/solo-public/kagent-enterprise-helm/charts/kagent-enterprise-crds \
    --namespace "$KAGENT_NAMESPACE" \
    --create-namespace \
    --version "${KAGENT_ENT_VERSION}" \
    --kube-context "$kubectxname"
echo

echo "Installing Kagent Enterprise in cluster $cluster..."
helm upgrade -i kagent \
    oci://us-docker.pkg.dev/solo-public/kagent-enterprise-helm/charts/kagent-enterprise \
    --namespace "$KAGENT_NAMESPACE" \
    --version "${KAGENT_ENT_VERSION}" \
    --set providers.openAI.apiKey="$OPENAI_API_KEY" \
    --set agents.k8s-agent.enabled=true \
    --set kagent-tools.enabled=true \
    --set-string licensing.licenseKey="$LICENSE_KEY" \
    --kube-context "$kubectxname"
echo

echo "Waiting for Kagent Enterprise pods to be ready in cluster $cluster..."
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
echo "Installing Gateway API CRDs"
echo "=========================================="
echo

# Install the Kubernetes Gateway API CRDs (must be before waypoint and kgateway)

echo "Installing Gateway API CRDs (${GATEWAY_API_VERSION})..."
kubectl apply --server-side --force-conflicts -f https://github.com/kubernetes-sigs/gateway-api/releases/download/"${GATEWAY_API_VERSION}"/experimental-install.yaml
echo

echo
echo "=========================================="
echo "Enabling Istio Ambient Mode"
echo "=========================================="
echo

# Enable ambient mode for application namespaces

echo "Enabling ambient mode for movies namespace..."
kubectl label ns "$MOVIES_NAMESPACE" istio.io/dataplane-mode=ambient --overwrite
kubectl label ns "$MOVIES_NAMESPACE" istio.io/use-waypoint=auto --overwrite
echo

echo "Enabling ambient mode for kagent namespace..."
kubectl label ns "${KAGENT_NAMESPACE}" istio.io/dataplane-mode=ambient --overwrite
kubectl label ns "${KAGENT_NAMESPACE}" istio.io/use-waypoint=auto --overwrite
echo

# Deploy waypoint proxy for movies namespace

echo "Deploying waypoint proxy for movies namespace..."
kubectl apply -f manifests/movies-waypoint.yaml
kubectl wait --for=condition=Programmed gateway/waypoint -n "$MOVIES_NAMESPACE" --timeout=300s
kubectl get gateway -n "$MOVIES_NAMESPACE"
echo

echo
echo "=========================================="
echo "Installing Enterprise Kgateway"
echo "=========================================="
echo

# Install Enterprise Kgateway CRDs

echo "Installing Enterprise Kgateway CRDs (${ENT_KGATEWAY_VERSION})..."
helm upgrade -i enterprise-kgateway-crds \
    oci://us-docker.pkg.dev/solo-public/enterprise-kgateway/charts/enterprise-kgateway-crds \
    --create-namespace \
    --namespace "$KGATEWAY_NAMESPACE" \
    --version "${ENT_KGATEWAY_VERSION}"
echo

# Install Enterprise Kgateway

echo "Installing Enterprise Kgateway..."
helm upgrade -i enterprise-kgateway \
    oci://us-docker.pkg.dev/solo-public/enterprise-kgateway/charts/enterprise-kgateway \
    --namespace "$KGATEWAY_NAMESPACE" \
    --version "${ENT_KGATEWAY_VERSION}" \
    --set-string licensing.licenseKey="$LICENSE_KEY"
echo

# Wait for Enterprise Kgateway

echo "Waiting for Enterprise Kgateway pods to be ready..."
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
echo "Installing Enterprise Agentgateway"
echo "=========================================="
echo

# Create agentgateway namespace and enable ambient mode

echo "Creating agentgateway namespace..."
kubectl create namespace "${AGENTGATEWAY_NAMESPACE}" || true
kubectl label ns "${AGENTGATEWAY_NAMESPACE}" istio.io/dataplane-mode=ambient --overwrite
echo

# Install Enterprise Agentgateway CRDs

# Note: CRDs are applied via server-side apply to avoid Helm ownership conflicts
# with shared CRDs (e.g. authconfigs.extauth.solo.io) already owned by enterprise-kgateway
echo "Installing Enterprise Agentgateway CRDs (${ENT_AGENTGATEWAY_VERSION})..."
helm template enterprise-agentgateway-crds \
    oci://us-docker.pkg.dev/solo-public/enterprise-agentgateway/charts/enterprise-agentgateway-crds \
    --version "${ENT_AGENTGATEWAY_VERSION}" | kubectl apply --server-side --force-conflicts -f -
echo

# Install Enterprise Agentgateway

echo "Installing Enterprise Agentgateway (${ENT_AGENTGATEWAY_VERSION})..."
helm upgrade -i enterprise-agentgateway \
    oci://us-docker.pkg.dev/solo-public/enterprise-agentgateway/charts/enterprise-agentgateway \
    --namespace "${AGENTGATEWAY_NAMESPACE}" \
    --version "${ENT_AGENTGATEWAY_VERSION}" \
    --set-string licensing.licenseKey="${AGENTGATEWAY_LICENSE_KEY}" \
    -f manifests/agentgateway-values.yaml

echo "Waiting for Enterprise Agentgateway pods to be ready..."
kubectl wait --for=condition=Ready pods --all -n "${AGENTGATEWAY_NAMESPACE}" --timeout=300s || echo "Warning: Agentgateway pods not ready yet"
kubectl get all -n "${AGENTGATEWAY_NAMESPACE}"
echo

# Create HTTPRoute for agentgateway

echo "Creating HTTPRoute for agentgateway..."
kubectl apply -f manifests/agentgateway-httproute.yaml || echo "Warning: HTTPRoute creation may be pending service availability"
echo

echo
echo "=========================================="
echo "Installing Agentregistry (OSS)"
echo "=========================================="
echo

# Create agentregistry namespace and enable ambient mode

echo "Creating agentregistry namespace..."
kubectl create namespace "${AGENTREGISTRY_NAMESPACE}" || true
kubectl label ns "${AGENTREGISTRY_NAMESPACE}" istio.io/dataplane-mode=ambient --overwrite
echo

# Install agentregistry via Helm (OCI)

echo "Installing agentregistry (${AGENTREGISTRY_VERSION})..."
helm install agentregistry oci://ghcr.io/agentregistry-dev/agentregistry/charts/agentregistry \
    --namespace "${AGENTREGISTRY_NAMESPACE}" \
    --version "${AGENTREGISTRY_VERSION}" \
    -f manifests/agentregistry-values.yaml || echo "Warning: Agentregistry install failed — values file may need updating for this version"

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
echo "Enterprise Deployment Complete!"
echo "=========================================="
echo
echo "Enterprise AI Platform Stack Summary:"
echo "  - Solo Istio ${ISTIO_VERSION} (Ambient Mode with mTLS)"
echo "  - Solo Enterprise for Kagent ${KAGENT_ENT_VERSION}"
echo "  - Solo Enterprise for Kgateway ${ENT_KGATEWAY_VERSION}"
echo "  - Solo Enterprise for Agentgateway ${ENT_AGENTGATEWAY_VERSION}"
echo "  - Agentregistry ${AGENTREGISTRY_VERSION} (OSS)"
echo "  - Gateway API ${GATEWAY_API_VERSION}"
echo
echo "Access Points:"
echo "  - Kagent: http://localhost:${HTTP_PORT_PREFIX}01"
echo "  - Enterprise Kgateway: http://localhost:${HTTP_PORT_PREFIX}01 (with Host header routing)"
echo "  - Enterprise Agentgateway: http://localhost:${HTTP_PORT_PREFIX}01 (Host: agentgateway.local)"
echo "  - Agentregistry: http://localhost:${HTTP_PORT_PREFIX}01 (Host: agentregistry.local)"
echo
echo "Verify installation:"
echo "  kubectl get pods -n istio-system"
echo "  kubectl get pods -n kagent"
echo "  kubectl get pods -n kgateway-system"
echo "  kubectl get pods -n agentgateway-system"
echo "  kubectl get pods -n agentregistry-system"
echo "  kubectl get pods -n "$MOVIES_NAMESPACE""
echo

exit 0
