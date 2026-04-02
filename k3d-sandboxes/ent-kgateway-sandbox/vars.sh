#!/bin/bash
# vars.sh
# Environment variables for the Enterprise Kgateway sandbox
#
# Tom Dean
# Last edit: 3/27/2026
#
# Set variables here and then execute or source script
# Do this before executing any sandbox scripts

export NUM_CLUSTERS=3
export CLUSTER_NAME_PREFIX=ent-kgw-
export KUBECTX_NAME_PREFIX=ent-kgw-
export CLUSTER_NETWORK=ent-kgw-network
export K3S_VERSION=v1.35.2-k3s1
export HTTP_PORT_PREFIX=61
export HTTPS_PORT_PREFIX=65
export API_PORT_PREFIX=69
export ENT_KGATEWAY_VERSION=2.1.4
export KGATEWAY_NAMESPACE=kgateway-system
export GATEWAY_API_VERSION="v1.5.1"
export LICENSE_KEY="" # Replace with your Solo Enterprise for Kgateway license key
