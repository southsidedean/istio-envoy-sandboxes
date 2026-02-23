#!/bin/bash
# cluster-setup-k3d-kagent-everything.sh
# Automates k3d cluster creation
# Tom Dean
# Last edit: 5/27/2025

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
kubectx -d "$kubectxname" || true
kubectx "$kubectxname=k3d-$clustername"
done

kubectx "${KUBECTX_NAME_PREFIX}01"
kubectx

# Install the 'kagent' CLI tool
# Download/run the install script
# WARNING: The original script used: curl https://raw.githubusercontent.com/kagent-dev/kagent/refs/heads/main/scripts/get-kagent | bash
# This is a security risk. For production, download and verify the binary manually.
# Uncomment the following lines if you accept the security risk:
# curl https://raw.githubusercontent.com/kagent-dev/kagent/refs/heads/main/scripts/get-kagent | bash
# echo

# For now, assuming kagent CLI is already installed or will be installed manually
echo

# Install 'kagent' using Helm

for cluster in $(seq -f %02g 1 "$NUM_CLUSTERS")
do
kubectxname="$KUBECTX_NAME_PREFIX$cluster"
helm install kagent-crds oci://ghcr.io/kagent-dev/kagent/helm/kagent-crds \
    --namespace "$KAGENT_NAMESPACE" \
    --create-namespace \
    --kube-context "$kubectxname"
echo
helm install kagent oci://ghcr.io/kagent-dev/kagent/helm/kagent \
    --namespace "$KAGENT_NAMESPACE" \
    --set providers.openAI.apiKey="$OPENAI_API_KEY" \
    --kube-context "$kubectxname"
echo
echo "Waiting for Kagent pods to be ready in cluster $cluster..."
kubectl wait --for=condition=Ready pods --all -n "$KAGENT_NAMESPACE" --context "$kubectxname" --timeout=300s
kubectl get all -n "$KAGENT_NAMESPACE" --context "$kubectxname"
echo
done

# Deploy the 'movies' application

for cluster in $(seq -f %02g 1 "$NUM_CLUSTERS")
do
kubectxname="$KUBECTX_NAME_PREFIX$cluster"
echo
kubectl apply -k movies --context "$kubectxname"
echo
done

# Install the Kubernetes Gateway API CRDs

kubectl apply -f https://github.com/kubernetes-sigs/gateway-api/releases/download/"${GATEWAY_API_VERSION}"/standard-install.yaml
echo

# Install 'kgateway' CRDs using Helm

helm upgrade -i --create-namespace --namespace "$KGATEWAY_NAMESPACE" --version v"${KGATEWAY_VERSION}" kgateway-crds oci://cr.kgateway.dev/kgateway-dev/charts/kgateway-crds
echo

# Install 'kgateway' using Helm

helm upgrade -i --namespace "$KGATEWAY_NAMESPACE" --version v"${KGATEWAY_VERSION}" kgateway oci://cr.kgateway.dev/kgateway-dev/charts/kgateway
echo

# Check our 'kgateway' installation

echo "Waiting for kgateway pods to be ready..."
kubectl wait --for=condition=Ready pods --all -n "$KGATEWAY_NAMESPACE" --timeout=300s
kubectl get all -n "$KGATEWAY_NAMESPACE"
echo

# Create an HTTP listener

kubectl apply -f manifests/http-listener.yaml
echo
kubectl get gateways -A
echo

# Create an HTTPRoute for 'kagent'

kubectl apply -f manifests/kagent-httproute.yaml
echo
kubectl get httproute -A
echo

# Install Grafana using Helm

#helm repo add grafana https://grafana.github.io/helm-charts
#helm repo update
#echo
#for cluster in $(seq -f %02g 1 "$NUM_CLUSTERS")
#do
#kubectxname="$KUBECTX_NAME_PREFIX$cluster"
#helm install grafana -n grafana --create-namespace grafana/grafana \
#  -f manifests/grafana-values.yaml --debug --kube-context "$kubectxname"
#echo
#done

exit 0
