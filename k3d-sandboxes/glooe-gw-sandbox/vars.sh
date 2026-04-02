#!/bin/bash
# vars.sh
# Environment variables for the sandbox
#
# Tom Dean
# Last edit: 5/23/2025
#
# Set variables here and then execute or source script
# Do this before executing any sandbox scripts

export NUM_CLUSTERS=3
export CLUSTER_NAME_PREFIX=glooe-
export KUBECTX_NAME_PREFIX=glooe-
export CLUSTER_NETWORK=glooe-network
export K3S_VERSION=v1.35.2-k3s1
export HTTP_PORT_PREFIX=88
export HTTPS_PORT_PREFIX=89
export API_PORT_PREFIX=98
export GLOO_NAMESPACE=gloo-system
export GLOOCTL_VERSION=1.21.1
export GLOO_VERSION=1.21.1
export LICENSE_KEY="" # Replace with your Gloo Edge Enterprise license key
