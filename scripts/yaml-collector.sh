#!/bin/bash
# Script to collect manifests for a bunch of k8s objects across all namespaces and create a zipfile
# Tom Dean
# Last edit: 2/23/2026

set -e

# Set object list - what are we collecting?
# Use the OBJECTS variable to set this

# Fixed list - in this example services, deployments and pods
#OBJECTS="svc deploy pods"

# All objects on the cluster
#OBJECTS=$(kubectl api-resources | grep -v NAME | awk '{print $1}')

# All Solo objects
OBJECTS=$(kubectl api-resources | grep -i solo | grep -v NAME | awk '{print $1}')

# Create directory to collect all manifests

mkdir -p manifests
cd manifests

# Let's go!

for obj in $OBJECTS
do
  mkdir -p "$obj"
  cd "$obj"
  for ns in $(kubectl get ns --no-headers -o custom-columns=NAME:.metadata.name)
  do
    for res in $(kubectl get "$obj" -n "$ns" --no-headers -o custom-columns=NAME:.metadata.name 2>/dev/null)
    do
      kubectl get "$obj" "$res" -n "$ns" -o yaml > "$obj-$res-$ns.yaml"
    done
  done
  cd ..
done
cd ..

# Create a tarfile and remove source files

tar czf manifests.tar.gz manifests
rm -rf manifests

exit 0
