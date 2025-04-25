#!/bin/bash
# cluster-destroy-k3d.sh
# Automates cluster deletion and cleans up the kubectl contexts
# Tom Dean
# Last edit: 4/24/2025

# Set environment variables

source vars.sh

# Remove the k3d cluster

k3d cluster delete $CLUSTER1_NAME
k3d cluster delete $CLUSTER2_NAME
k3d cluster delete $CLUSTER3_NAME
k3d cluster list

# Remove the kubectl context

kubectx -d $KUBECTX_NAME1
kubectx -d $KUBECTX_NAME2
kubectx -d $KUBECTX_NAME3
kubectx

echo "Clusters deleted!"

exit 0
