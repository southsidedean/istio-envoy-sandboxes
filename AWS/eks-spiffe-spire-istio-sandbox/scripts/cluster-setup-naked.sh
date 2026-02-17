#!/bin/bash
# cluster-setup-naked.sh
# Automates eks cluster creation
# Tom Dean
# Last edit: 2/16/2026

# Set environment variables

source vars.sh

# Create the eks cluster
# eksctl create cluster --profile $AWS_PROFILE --config-file manifests/eks-cluster.yaml
envsubst < manifests/eks-cluster.yaml | eksctl create cluster --profile $AWS_PROFILE --config-file -
eksctl get cluster

# Display the kubectl contexts

kubectx

exit 0
