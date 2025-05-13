#!/bin/bash
# cluster-setup-k3d-sc-everything.sh
# Automates k3d cluster creation with Sidecar mesh
# Tom Dean
# Last edit: 5/13/2025

# Set environment variables

source vars.sh

# Delete existing k3d clusters

for cluster in `seq -f %02g 1 $NUM_CLUSTERS`
do
clustername=$CLUSTER_NAME_PREFIX$cluster
k3d cluster delete $clustername
done

# Create the k3d clusters

for cluster in `seq -f %02g 1 $NUM_CLUSTERS`
do
clustername=$CLUSTER_NAME_PREFIX$cluster
k3d cluster create $clustername -c cluster-k3d/k3d-cluster.yaml --port 90${cluster}:80@loadbalancer --port 94${cluster}:443@loadbalancer --api-port 0.0.0.0:96${cluster} --registry-config manifests/registries.yaml
done

k3d cluster list

# Configure the kubectl context

for kubectx in `seq -f %02g 1 $NUM_CLUSTERS`
do
kubectxname=$KUBECTX_NAME_PREFIX$kubectx
clustername=$CLUSTER_NAME_PREFIX$kubectx
kubectx -d $kubectxname
kubectx $kubectxname=k3d-$clustername
done

kubectx ${KUBECTX_NAME_PREFIX}01
kubectx

# Deploy the 'movies' application

kubectl apply -k movies

# Label the 'movies' namespace for Isio injection

kubectl label ns movies istio-injection=enabled --overwrite=true

# Deploy OSS Istio
# Deploy 'istioctl'

curl -L https://istio.io/downloadIstio | sh -
export PATH=$PWD/istio-${ISTIO_VERSION}/bin:$PATH

# Here we go!

export CLUSTER_NAME=${CLUSTER_NAME_PREFIX}01
echo
echo "Cluster name is: "$CLUSTER_NAME
echo

# Configure the Istio Helm repository

helm repo add istio https://istio-release.storage.googleapis.com/charts
helm repo update

# Install Istio base

helm install istio-base istio/base -n istio-system --set defaultRevision=${ISTIO_VERSION} --create-namespace
echo
helm ls -n istio-system
echo

# Install Istio CNI

helm install istio-cni istio/cni -n istio-system -f manifests/istio-cni-values.yaml --wait
echo
helm ls -n istio-system
echo

# Install Istio discovery chart (istiod)

helm install istiod istio/istiod -n istio-system --wait
echo
helm ls -n istio-system
echo
helm status istiod -n istio-system
echo
kubectl get deployments -n istio-system --output wide
echo

# Verify installation

watch -n 1 kubectl get all -n istio-system

# Rollout restart the deployments in the 'movies' namespace, in case they didn't get injected

kubectl rollout restart deploy -n movies
#echo

# Verify the 'movies' app is good

watch -n 1 kubectl get all -n movies

# Install Istio's Prometheus integration

kubectl apply -f https://raw.githubusercontent.com/istio/istio/release-1.26/samples/addons/prometheus.yaml

# Install Kiali dashboard
# Add Kiali Helm charts if needed

helm repo add kiali https://kiali.org/helm-charts
helm repo update

# Install Kiali without the operator

helm install \
    --namespace istio-system \
    kiali-server \
    kiali/kiali-server -f manifests/kiali-values.yaml

# Install Grafana

helm repo add grafana https://grafana.github.io/helm-charts
helm install grafana -n grafana --create-namespace grafana/grafana \
  -f manifests/grafana-values.yaml --debug

# Create ingress(es) for cluster

kubectl apply -f manifests/kiali-ingress.yaml
kubectl apply -f manifests/grafana-ingress.yaml

# Display the kiali login token

echo
echo "Kiali login token: " `kubectl -n istio-system create token kiali`

exit 0
