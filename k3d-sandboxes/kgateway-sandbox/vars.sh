#!/bin/bash
# vars.sh
# Environment variables for the sandbox
#
# Tom Dean
# Last edit: 3/27/2026
#
# Set variables here and then execute or source script
# Do this before executing any sandbox scripts

export NUM_CLUSTERS=3
export CLUSTER_NAME_PREFIX=kgw-
export KUBECTX_NAME_PREFIX=kgw-
export CLUSTER_NETWORK=kgw-network
export K3S_VERSION=v1.35.2-k3s1
export HTTP_PORT_PREFIX=80
export HTTPS_PORT_PREFIX=84
export API_PORT_PREFIX=86
export KGATEWAY_VERSION=2.2.2
export KGATEWAY_NAMESPACE=kgateway-system
export GATEWAY_API_VERSION="v1.5.1"
