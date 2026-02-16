#!/bin/bash
# cluster-destroy-eks.sh
# Automates cluster deletion and cleans up the kubectl contexts
# Tom Dean
# Last edit: 2/16/2026

# Set environment variables

source vars.sh

# Remove the eks cluster

for cluster in `seq -f %02g 1 $NUM_CLUSTERS`
do
clustername=$CLUSTER_NAME_PREFIX$cluster
eksctl delete cluster --name $clustername --profile $AWS_PROFILE
done

eksctl get cluster --profile $AWS_PROFILE

# Remove the kubectl context

for kubectx in `seq -f %02g 1 $NUM_CLUSTERS`
do
kubectxname=$KUBECTX_NAME_PREFIX$kubectx
kubectx -d $kubectxname
done

kubectx

echo "Clusters deleted!"

exit 0
