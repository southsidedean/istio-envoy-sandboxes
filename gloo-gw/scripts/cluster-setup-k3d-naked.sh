#!/bin/bash
# cluster-setup-k3d-naked.sh
# Automates k3d cluster creation
# Tom Dean
# Last edit: 4/22/2025

# Let's set some variables!

# Create the k3d clusters

k3d cluster delete gloo-gw-playground
k3d cluster create -c cluster-k3d/k3d-small.yaml
k3d cluster list

# Configure the kubectl context

kubectx -d gloo-gw
kubectx gloo-gw=k3d-gloo-gw-playground
kubectx gloo-gw
kubectx

exit 0
