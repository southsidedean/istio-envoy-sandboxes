#!/bin/bash
# cluster-setup-k3d-sc-everything.sh
# Automates k3d cluster creation with Sidecar mesh
# Tom Dean
# Last edit: 5/8/2025

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
k3d cluster create $clustername -c cluster-k3d/k3d-cluster.yaml --port 90${cluster}:80@loadbalancer --port 94${cluster}:443@loadbalancer --api-port 0.0.0.0:96${cluster} --verbose --trace
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

kubectl label ns movies istio.io/rev=gloo --overwrite=true

# Deploy Gloo Mesh Enterprise
# Deploy 'meshctl'

curl -sL https://run.solo.io/meshctl/install | GLOO_MESH_VERSION=$GME_VERSION sh -
export PATH=$HOME/.gloo-mesh/bin:$PATH

# Deploy Gloo Mesh Enterprise
export CLUSTER_NAME=${CLUSTER_NAME_PREFIX}01
echo
echo "Cluster name is: "$CLUSTER_NAME
echo

meshctl install --profiles gloo-mesh-enterprise-single,ratelimit,extauth \
--set common.cluster=${CLUSTER_NAME} \
--set glooMgmtServer.createGlobalWorkspace=true \
--set licensing.glooMeshLicenseKey=${GLOO_MESH_LICENSE_KEY}

# Check our deployment after sleeping for 90 seconds

sleep 90
meshctl check

# Install Gloo Operator to the 'gloo-mesh namespace'

helm install gloo-operator oci://us-docker.pkg.dev/solo-public/gloo-operator-helm/gloo-operator \
--version 0.2.3 \
-n gloo-mesh \
--create-namespace \
--set manager.env.SOLO_ISTIO_LICENSE_KEY=${GLOO_MESH_LICENSE_KEY}

kubectl get pods -n gloo-mesh -l app.kubernetes.io/name=gloo-operator

# Create configmap in the 'gloo-mesh' namespace to fix CNI configuration for k3d/k3s nodes

kubectl apply -f manifests/gloo-extensions-config-cm.yaml

# Deploy a managed Istio installation, using the Gloo Operator

kubectl apply -n gloo-mesh -f manifests/managed-istio-sidecars.yaml

# Verify installation

watch -n 1 kubectl get all -n istio-system

# Rollout restart the deployments in the 'movies' namespace, in case they didn't get injected

kubectl rollout restart deploy -n movies

# Verify the 'movies' app is good

watch -n 1 kubectl get all -n movies

# Create 'gloo-mesh-ui-ingress' for off-cluster access to Gloo Dashboard

#kubectl apply -f manifests/gloo-mesh-ui-ingress.yaml

# Install Grafana

helm repo add grafana https://grafana.github.io/helm-charts
helm install grafana -n grafana --create-namespace grafana/grafana \
  -f manifests/grafana-values.yaml --debug

# Create ingress for UI and Grafana

#kubectl apply -f manifests/grafana-ext-svc.yaml
#kubectl apply -f manifests/cluster-ingress.yaml
kubectl apply -f manifests/grafana-ingress.yaml
kubectl apply -f manifests/gloo-mesh-ui-ingress.yaml

# Start the Gloo Dashboard in the background and suppress output

#meshctl dashboard > /dev/null 2>&1 &

exit 0
