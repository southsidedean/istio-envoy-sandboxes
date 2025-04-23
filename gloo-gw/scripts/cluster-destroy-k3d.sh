#!/bin/bash
# cluster-destroy-k3d.sh
# Automates cluster deletion and cleans up the gloo-gw kubectl context
# Tom Dean
# Last edit: 4/23/2025

# Set environment variables

source vars.sh

# Remove the k3d cluster

k3d cluster delete $CLUSTER_NAME
k3d cluster list

# Remove the kubectl context

kubectx -d gloo-gw
kubectx

echo "Cluster deleted!"

exit 0
