#!/bin/bash
# cluster-setup-naked.sh
# Automates eks cluster creation
# Tom Dean
# Last edit: 2/16/2026

set -e

# Set environment variables

source vars.sh

# Validate that required placeholders have been filled in

if [[ "$AWS_PROFILE" == *"INSERT"* ]]; then
  echo "ERROR: Edit vars.sh and fill in all required values before running."
  echo "Look for <<INSERT_..._HERE>> placeholders."
  exit 1
fi

# Create the eks cluster

echo
echo "Creating EKS Cluster..."
envsubst < manifests/eks-cluster.yaml | eksctl create cluster --profile "$AWS_PROFILE" --config-file -
echo
eksctl get cluster --profile "$AWS_PROFILE" --region "$AWS_REGION"
echo

# Display the kubectl contexts

kubectx

exit 0
