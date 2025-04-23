#!/bin/bash
# cluster-destroy-k3d.sh
# Automates cluster deletion and cleans up the gloo-gw kubectl context
# Tom Dean
# Last edit: 4/22/2025

# Remove the k3d cluster

k3d cluster delete gloo-gw-playground
k3d cluster list

# Remove the kubectl context

kubectx -d gloo-gw
kubectx

echo "Cluster deleted!"

exit 0
