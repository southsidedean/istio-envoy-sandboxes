#!/bin/bash
# cluster-setup-everything.sh
# Automates eks cluster creation
# Tom Dean
# Last edit: 2/16/2026

# Set environment variables

source vars.sh

# Create the eks clusters

for cluster in `seq -f %02g 1 $NUM_CLUSTERS`
do
clustername=$CLUSTER_NAME_PREFIX$cluster
eksctl create cluster --name $clustername --profile $AWS_PROFILE --version $EKS_VERSION --region $AWS_REGION --node-type $NODE_TYPE --config-file mainfests/eks-cluster.yaml
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

# Install the 'istioctl' CLI tool

curl -sL https://run.solo.io/gloo/install | sh
export PATH=$HOME/.gloo/bin:$PATH

# Install Istio using Helm - USE SOLO IMAGES!

echo
helm repo add gloo https://storage.googleapis.com/solo-public-helm
helm repo update
echo

for cluster in `seq -f %02g 1 $NUM_CLUSTERS`
do
kubectxname=$KUBECTX_NAME_PREFIX$cluster
kubectl create namespace $GLOO_NAMESPACE --context $kubectxname
echo
helm install gloo gloo/gloo --namespace $GLOO_NAMESPACE --kube-context $kubectxname
echo
watch -n 1 kubectl get all -n $GLOO_NAMESPACE --context $kubectxname
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
