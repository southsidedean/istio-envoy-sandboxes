#!/bin/bash
# Script to collect manifests for a bunch of k8s objects across all namespaces and create a zipfile
# Tom Dean
# Last edit: 6/3/2025

# Set object list - what are we collecting?
# Use the OBJECTS variable to set this

# Fixed list - in this example services, deployments and pods
#OBJECTS="svc deploy pods"

# All objects on the cluster
#OBJECTS=$(kubectl api-resources | grep -v NAME | awk {'print $1'})

# All Solo objects
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
