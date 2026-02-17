#!/bin/bash
# cluster-destroy-eks.sh
# Automates cluster deletion and cleans up the kubectl context
# Tom Dean
# Last edit: 2/16/2026

set -e

# Set environment variables

source vars.sh

# Remove the eks cluster

eksctl delete cluster --name $CLUSTER_NAME --profile $AWS_PROFILE --region $AWS_REGION
eksctl get cluster --profile $AWS_PROFILE --region $AWS_REGION || true

kubectx

echo "Cluster deleted!"

exit 0
