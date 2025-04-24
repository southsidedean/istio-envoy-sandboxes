#!/bin/bash
# cluster-setup-k3d-naked.sh
# Automates k3d cluster creation
# Tom Dean
# Last edit: 4/24/2025

# Set environment variables

source vars.sh

# Create the k3d clusters

k3d cluster delete $CLUSTER1_NAME
k3d cluster delete $CLUSTER2_NAME
k3d cluster delete $CLUSTER3_NAME
k3d cluster create $CLUSTER1_NAME -c cluster-k3d/k3d-cluster.yaml --port '8000:80@loadbalancer' --port '8443:443@loadbalancer' --api-port 0.0.0.0:6550 --verbose --trace
echo "Sleeping for 30 seconds..."
k3d cluster create $CLUSTER2_NAME -c cluster-k3d/k3d-cluster.yaml --port '8001:80@loadbalancer' --port '8444:443@loadbalancer' --api-port 0.0.0.0:6551 --verbose --trace
echo "Sleeping for 30 seconds..."
k3d cluster create $CLUSTER3_NAME -c cluster-k3d/k3d-cluster.yaml --port '8002:80@loadbalancer' --port '8445:443@loadbalancer' --api-port 0.0.0.0:6552 --verbose --trace
k3d cluster list

# Configure the kubectl context

kubectx -d $KUBECTX_NAME1
kubectx -d $KUBECTX_NAME2
kubectx -d $KUBECTX_NAME3
kubectx $KUBECTX_NAME1=k3d-$CLUSTER1_NAME
kubectx $KUBECTX_NAME2=k3d-$CLUSTER2_NAME
kubectx $KUBECTX_NAME3=k3d-$CLUSTER3_NAME
kubectx $KUBECTX_NAME1
kubectx

exit 0
