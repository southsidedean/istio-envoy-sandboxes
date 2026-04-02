#!/bin/bash
# cluster-setup-k3d-kgw-everything.sh
# Automates k3d cluster creation with kgateway (OSS) 2.x
# Tom Dean
# Last edit: 3/27/2026

set -e

# Set environment variables

source vars.sh

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

# Install kgateway using Helm (OCI)

for cluster in $(seq -f %02g 1 "$NUM_CLUSTERS")
do
kubectxname="$KUBECTX_NAME_PREFIX$cluster"

echo "Installing kgateway CRDs on cluster $cluster..."
helm upgrade -i kgateway-crds \
    oci://cr.kgateway.dev/kgateway-dev/charts/kgateway-crds \
    --create-namespace \
    --namespace "$KGATEWAY_NAMESPACE" \
    --version "v${KGATEWAY_VERSION}" \
    --kube-context "$kubectxname"

echo "Installing kgateway on cluster $cluster..."
helm upgrade -i kgateway \
    oci://cr.kgateway.dev/kgateway-dev/charts/kgateway \
    --namespace "$KGATEWAY_NAMESPACE" \
    --version "v${KGATEWAY_VERSION}" \
    --kube-context "$kubectxname"

echo "Waiting for kgateway pods to be ready in cluster $cluster..."
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
echo "kgateway sandbox deployment complete!"
echo "Access clusters via:"
for cluster in $(seq -f %02g 1 "$NUM_CLUSTERS")
do
echo "  Cluster $cluster: http://localhost:${HTTP_PORT_PREFIX}${cluster}"
done
echo

exit 0
