#!/bin/bash
# vars.sh
# Environment variables for the AI sandbox
#
# Tom Dean
# Last edit: 2/23/2026
#
# Set variables here and then execute or source script
# Do this before executing any sandbox scripts

export NUM_CLUSTERS=1
export CLUSTER_NAME_PREFIX=ai-sandbox-
export KUBECTX_NAME_PREFIX=ai-sandbox-
export CLUSTER_NETWORK=ai-sandbox-network
export K3S_VERSION=v1.35.2-k3s1
export HTTP_PORT_PREFIX=70
export HTTPS_PORT_PREFIX=74
export API_PORT_PREFIX=76

# Kagent (AI Agent Framework)
export KAGENT_NAMESPACE=kagent
export KAGENT_VERSION=0.8.1

# Kgateway (API Gateway)
export KGATEWAY_VERSION=2.2.2
export KGATEWAY_NAMESPACE=kgateway-system

# Gateway API
export GATEWAY_API_VERSION="v1.5.1"

# Istio (Service Mesh - Ambient Mode)
export ISTIO_VERSION=1.29.1
export ISTIO_NAMESPACE=istio-system
export MOVIES_NAMESPACE=movies

# Agentgateway (Agent-to-Agent Gateway)
export AGENTGATEWAY_VERSION=1.0.1
export AGENTGATEWAY_NAMESPACE=agentgateway-system

# Agentregistry (Agent Discovery)
export AGENTREGISTRY_VERSION=0.3.2
export AGENTREGISTRY_NAMESPACE=agentregistry-system

# Credentials
export OPENAI_API_KEY="" # Replace with your OpenAI API key
export LICENSE_KEY=""
