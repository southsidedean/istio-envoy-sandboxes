#!/bin/bash
# cluster-setup-k3d-gg-everything.sh
# Automates k3d cluster creation
# Tom Dean
# Last edit: 5/21/2025

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
k3d cluster create $clustername -c cluster-k3d/k3d-cluster.yaml --port 80${cluster}:80@loadbalancer --port 84${cluster}:443@loadbalancer --api-port 0.0.0.0:86${cluster}
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

# Install the 'glooctl' CLI tool

curl -sL https://run.solo.io/gloo/install | sh
export PATH=$HOME/.gloo/bin:$PATH

# Install GlooGateway using 'glooctl'
#
#for cluster in `seq -f %02g 1 $NUM_CLUSTERS`
#do
#kubectxname=$KUBECTX_NAME_PREFIX$cluster
#glooctl install gateway --context $kubectxname
#done

# Install GlooGateway using Helm

echo
helm repo add gloo https://storage.googleapis.com/solo-public-helm
helm repo update
echo

for cluster in `seq -f %02g 1 $NUM_CLUSTERS`
do
kubectxname=$KUBECTX_NAME_PREFIX$cluster
kubectl create namespace gloo-system --context $kubectxname
echo
helm install gloo gloo/gloo --namespace gloo-system --kube-context $kubectxname
echo
watch -n 1 kubectl get all -n gloo-system --context $kubectxname
echo
done

# Deploy the 'movies' application

for cluster in `seq -f %02g 1 $NUM_CLUSTERS`
do
kubectxname=$KUBECTX_NAME_PREFIX$cluster
echo
kubectl apply -k movies --context $kubectxname
echo
done

# Install Grafana using Helm

#helm repo add grafana https://grafana.github.io/helm-charts
#helm repo update
#helm install grafana -n grafana --create-namespace grafana/grafana \
#  -f manifests/grafana-values.yaml --debug

exit 0
