#!/bin/bash
# vars.sh
# Environment variables for the sandbox
#
# Tom Dean
# Last edit: 5/27/2025
#
# Set variables here and then execute or source script
# Do this before executing any sandbox scripts

export NUM_CLUSTERS=1
export CLUSTER_NAME_PREFIX=kagent-
export KUBECTX_NAME_PREFIX=kagent-
export CLUSTER_NETWORK=kagent-network
export K3S_VERSION=v1.35.2-k3s1
export HTTP_PORT_PREFIX=73
export HTTPS_PORT_PREFIX=83
export API_PORT_PREFIX=93
export KAGENT_NAMESPACE=kagent
export KAGENT_VERSION=0.8.1
export OPENAI_API_KEY="" # Replace with your OpenAI API key
export KGATEWAY_VERSION=2.2.2
export KGATEWAY_NAMESPACE=kgateway-system
export GATEWAY_API_VERSION="v1.5.1"
export LICENSE_KEY=""
