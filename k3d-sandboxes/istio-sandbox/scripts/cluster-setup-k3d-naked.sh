#!/bin/bash
# cluster-setup-k3d-naked.sh
# Automates k3d cluster creation
# Tom Dean
# Last edit: 4/25/2025

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
k3d cluster create $clustername -c cluster-k3d/k3d-cluster.yaml --port 70${cluster}:80@loadbalancer --port 74${cluster}:443@loadbalancer --api-port 0.0.0.0:76${cluster} --verbose --trace
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

exit 0
