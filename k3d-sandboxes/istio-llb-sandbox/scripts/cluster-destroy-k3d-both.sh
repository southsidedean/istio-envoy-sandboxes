#!/bin/bash
# cluster-destroy-k3d-both.sh
# Automates cluster deletion and cleans up the kubectl contexts
# Tom Dean
# Last edit: 5/8/2025

set -e

# Set environment variables

source vars.sh

# Override NUM_CLUSTERS to 2

NUM_CLUSTERS=2

# Remove the k3d clusters

for cluster in $(seq -f %02g 1 "$NUM_CLUSTERS")
do
clustername="$CLUSTER_NAME_PREFIX$cluster"
k3d cluster delete "$clustername"
done

k3d cluster list

# Remove the kubectl context

for kubectx in $(seq -f %02g 1 "$NUM_CLUSTERS")
do
kubectxname="$KUBECTX_NAME_PREFIX$kubectx"
kubectx -d "$kubectxname" || true
done

kubectx

echo "Clusters deleted!"

exit 0
