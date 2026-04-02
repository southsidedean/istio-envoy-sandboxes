#!/bin/bash
# vars.sh
# Environment variables for the sandbox
#
# Tom Dean
# Last edit: 4/25/2025
#
# Set variables here and then execute or source script
# Do this before executing any sandbox scripts

export NUM_CLUSTERS=3
export CLUSTER_NAME_PREFIX=istio-
export KUBECTX_NAME_PREFIX=istio-
export CLUSTER_NETWORK=istio-network
export K3S_VERSION=v1.35.2-k3s1
export HTTP_PORT_PREFIX=71
export HTTPS_PORT_PREFIX=75
export API_PORT_PREFIX=79
