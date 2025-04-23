#!/bin/bash
# cluster-setup-k3d-naked.sh
# Automates k3d cluster creation
# Tom Dean
# Last edit: 4/23/2025

# Set environment variables

source vars.sh

# Create the k3d clusters

k3d cluster delete $CLUSTER_NAME
k3d cluster create -c cluster-k3d/k3d-small.yaml
k3d cluster list

# Configure the kubectl context

kubectx -d gloo-gw
kubectx gloo-gw=k3d-$CLUSTER_NAME
kubectx gloo-gw
kubectx

exit 0
