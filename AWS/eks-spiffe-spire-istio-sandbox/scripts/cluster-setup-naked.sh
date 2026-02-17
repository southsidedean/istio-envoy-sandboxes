#!/bin/bash
# cluster-setup-naked.sh
# Automates eks cluster creation
# Tom Dean
# Last edit: 2/16/2026

# Set environment variables

source vars.sh

# Create the eks clusters

for cluster in `seq -f %02g 1 $NUM_CLUSTERS`
do
clustername=$CLUSTER_NAME_PREFIX$cluster
eksctl create cluster --profile $AWS_PROFILE --config-file manifests/eks-cluster.yaml
done

eksctl get cluster

# Configure the kubectl context

#for kubectx in `seq -f %02g 1 $NUM_CLUSTERS`
#do
#kubectxname=$KUBECTX_NAME_PREFIX$kubectx
#clustername=$CLUSTER_NAME_PREFIX$kubectx
#kubectx -d $kubectxname
#kubectx $kubectxname=k3d-$clustername
#done

kubectx ${KUBECTX_NAME_PREFIX}01
kubectx

exit 0
