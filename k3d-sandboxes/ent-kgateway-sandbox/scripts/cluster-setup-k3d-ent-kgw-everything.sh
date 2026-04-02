#!/bin/bash
# cluster-setup-k3d-ent-kgw-everything.sh
# Automates k3d cluster creation with Solo Enterprise for Kgateway
# Tom Dean
# Last edit: 3/27/2026

set -e

# Set environment variables

source vars.sh

# Validate that required placeholders have been filled in

if [[ "$LICENSE_KEY" == *"INSERT"* ]]; then
  echo "ERROR: Edit vars.sh and fill in LICENSE_KEY before running."
  echo "Look for <<INSERT_LICENSE_STRING_HERE>> placeholder."
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

# Install Gateway API CRDs

echo
echo "Installing Gateway API CRDs ${GATEWAY_API_VERSION}..."
kubectl apply --server-side --force-conflicts -f "https://github.com/kubernetes-sigs/gateway-api/releases/download/${GATEWAY_API_VERSION}/experimental-install.yaml"
echo

# Install Solo Enterprise for Kgateway using Helm (OCI)

for cluster in $(seq -f %02g 1 "$NUM_CLUSTERS")
do
kubectxname="$KUBECTX_NAME_PREFIX$cluster"

echo "Installing Enterprise Kgateway CRDs on cluster $cluster..."
helm upgrade -i enterprise-kgateway-crds \
    oci://us-docker.pkg.dev/solo-public/enterprise-kgateway/charts/enterprise-kgateway-crds \
    --create-namespace \
    --namespace "$KGATEWAY_NAMESPACE" \
    --version "${ENT_KGATEWAY_VERSION}" \
    --kube-context "$kubectxname"

echo "Installing Enterprise Kgateway on cluster $cluster..."
helm upgrade -i enterprise-kgateway \
    oci://us-docker.pkg.dev/solo-public/enterprise-kgateway/charts/enterprise-kgateway \
    --namespace "$KGATEWAY_NAMESPACE" \
    --version "${ENT_KGATEWAY_VERSION}" \
    --set-string licensing.licenseKey="$LICENSE_KEY" \
    --kube-context "$kubectxname"

echo "Waiting for Enterprise Kgateway pods to be ready in cluster $cluster..."
sleep 10
kubectl wait --for=condition=Ready pods --all -n "$KGATEWAY_NAMESPACE" --context "$kubectxname" --timeout=300s
kubectl get all -n "$KGATEWAY_NAMESPACE" --context "$kubectxname"
echo
done

# Create the HTTP Gateway listener

for cluster in $(seq -f %02g 1 "$NUM_CLUSTERS")
do
kubectxname="$KUBECTX_NAME_PREFIX$cluster"
echo "Creating HTTP Gateway on cluster $cluster..."
kubectl apply -f manifests/http-listener.yaml --context "$kubectxname"
done

# Deploy the 'movies' application

for cluster in $(seq -f %02g 1 "$NUM_CLUSTERS")
do
kubectxname="$KUBECTX_NAME_PREFIX$cluster"
echo
kubectl apply -k movies --context "$kubectxname"
echo
done

echo
echo "Enterprise Kgateway sandbox deployment complete!"
echo "Access clusters via:"
for cluster in $(seq -f %02g 1 "$NUM_CLUSTERS")
do
echo "  Cluster $cluster: http://localhost:${HTTP_PORT_PREFIX}${cluster}"
done
echo

exit 0
