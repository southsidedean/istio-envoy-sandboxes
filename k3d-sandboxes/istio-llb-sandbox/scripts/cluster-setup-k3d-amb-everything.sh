#!/bin/bash
# cluster-setup-k3d-amb-everything.sh
# Automates k3d cluster creation with Ambient mesh
# Tom Dean
# Last edit: 5/13/2025

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
k3d cluster create "$clustername" -c cluster-k3d/k3d-cluster.yaml --registry-config manifests/registries.yaml --port "${HTTP_PORT_PREFIX}${cluster}:80@loadbalancer" --port "${HTTPS_PORT_PREFIX}${cluster}:443@loadbalancer" --api-port "0.0.0.0:${API_PORT_PREFIX}${cluster}"
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

# Deploy the 'movies' application

kubectl apply -k movies

# Label the 'movies' namespace for Istio injection and to use a waypoint

kubectl label ns "$MOVIES_NAMESPACE" istio.io/dataplane-mode=ambient --overwrite=true
kubectl label ns "$MOVIES_NAMESPACE" istio.io/use-waypoint=waypoint --overwrite=true

# Deploy OSS Istio
# Deploy 'istioctl'
# WARNING: The original script used: curl -L https://istio.io/downloadIstio | sh -
# This is a security risk. For production, download and verify the binary manually.
# Uncomment the following lines if you accept the security risk:
# curl -L https://istio.io/downloadIstio | sh -
# export PATH=$PWD/istio-${ISTIO_VERSION}/bin:$PATH

# For now, assuming istioctl is already installed or will be installed manually
export PATH=$PWD/istio-${ISTIO_VERSION}/bin:$PATH

# Here we go!

export CLUSTER_NAME="${CLUSTER_NAME_PREFIX}01"
echo
echo "Cluster name is: $CLUSTER_NAME"
echo

# Install the Kubernetes Gateway API CRDs (required before Istio waypoint proxies)

kubectl get crd gateways.gateway.networking.k8s.io &> /dev/null || \
kubectl apply -f "https://github.com/kubernetes-sigs/gateway-api/releases/download/${GATEWAY_API_VERSION}/standard-install.yaml"

# Configure the Istio Helm repository

helm repo add istio https://istio-release.storage.googleapis.com/charts
helm repo update

# Install Istio base

helm install istio-base istio/base -n "$ISTIO_NAMESPACE" --set defaultRevision="${ISTIO_VERSION}" --create-namespace --wait
echo
helm ls -n "$ISTIO_NAMESPACE"
echo

# Install Istio discovery chart (istiod)

helm install istiod istio/istiod -n "$ISTIO_NAMESPACE" -f manifests/istiod-values.yaml --set profile=ambient --wait
echo
helm ls -n "$ISTIO_NAMESPACE"
echo
helm status istiod -n "$ISTIO_NAMESPACE"
echo
kubectl get deployments -n "$ISTIO_NAMESPACE" --output wide
echo

# Install Istio CNI

helm install istio-cni istio/cni -n "$ISTIO_NAMESPACE" -f manifests/istio-cni-values.yaml --set profile=ambient --wait
echo
helm ls -n "$ISTIO_NAMESPACE"
echo

# Install ztunnel DaemonSet

helm install ztunnel istio/ztunnel -n "$ISTIO_NAMESPACE" --wait

# Verify installation

echo "Waiting for Istio system pods to be ready..."
kubectl wait --for=condition=Ready pods --all -n "$ISTIO_NAMESPACE" --timeout=300s
kubectl get all -n "$ISTIO_NAMESPACE"

# Rollout restart the deployments in the 'movies' namespace, in case they didn't get injected

kubectl rollout restart deploy -n "$MOVIES_NAMESPACE"
echo

# Create a waypoint proxy for the 'movies' application

kubectl apply -f manifests/movies-waypoint.yaml

# Verify the 'movies' app is good

echo "Waiting for movies app deployments to be ready..."
kubectl rollout status deployment -n "$MOVIES_NAMESPACE" --timeout=300s
kubectl get all -n "$MOVIES_NAMESPACE"

# Install Istio's Prometheus integration

kubectl apply -f "https://raw.githubusercontent.com/istio/istio/release-${ISTIO_VERSION%.*}/samples/addons/prometheus.yaml"

# Install Kiali dashboard
# Add Kiali Helm charts if needed

helm repo add kiali https://kiali.org/helm-charts
helm repo update

# Install Kiali without the operator

helm install \
    --namespace "$ISTIO_NAMESPACE" \
    kiali-server \
    kiali/kiali-server -f manifests/kiali-values.yaml

# Install Grafana

helm repo add grafana https://grafana.github.io/helm-charts
helm install grafana -n "$GRAFANA_NAMESPACE" --create-namespace grafana/grafana \
  -f manifests/grafana-values.yaml --debug

# Create ingress(es) for cluster

kubectl apply -f manifests/kiali-ingress.yaml
kubectl apply -f manifests/grafana-ingress.yaml

# Display the kiali login token

echo
echo "Kiali login token: $(kubectl -n "$ISTIO_NAMESPACE" create token kiali)"

exit 0
