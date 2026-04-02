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
export CLUSTER_NAME_PREFIX=gloo-
export KUBECTX_NAME_PREFIX=gloo-
export CLUSTER_NETWORK=gloo-network
export K3S_VERSION=v1.35.2-k3s1
export HTTP_PORT_PREFIX=81
export HTTPS_PORT_PREFIX=85
export API_PORT_PREFIX=87
export GLOO_NAMESPACE=gloo-system
export GLOOCTL_VERSION=1.21.1
export GLOO_VERSION=1.21.1
export LICENSE_KEY="" # Replace with your Gloo Gateway license key
