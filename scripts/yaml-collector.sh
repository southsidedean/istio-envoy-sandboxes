#!/bin/bash
# Script to collect manifests for a bunch of k8s objects across all namespaces and create a zipfile
# Grabs Solo api-resources
# Tom Dean
# Last edit: 6/3/2025

# Set object list

OBJECTS=$(kubectl api-resources | grep -i solo | grep -v NAME | awk {'print $1'})

# Create directory to collect all manifests

mkdir manifests
cd manifests

# Let's go!

for obj in $OBJECTS
do
mkdir $obj
cd $obj
for ns in $(kubectl get ns | grep -v NAME | awk {'print $1'})
do
for res in $(kubectl get $obj -n $ns | grep -v NAME | awk {'print $1'})
do
kubectl get $obj $res -n $ns -o yaml > $obj-$res-$ns.yaml
done
done
cd ..
done
cd ..

# Create a tarfile and remove source files

tar cvfz manifests.tar.gz manifests
rm -rf manifests

exit 0
