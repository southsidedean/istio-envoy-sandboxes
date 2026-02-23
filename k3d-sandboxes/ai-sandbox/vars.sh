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

# Kagent (AI Agent Framework)
export KAGENT_NAMESPACE=kagent
export KAGENT_VERSION=0.7.17

# Kgateway (API Gateway)
export KGATEWAY_VERSION=2.2.1
export KGATEWAY_NAMESPACE=kgateway-system

# Gateway API
export GATEWAY_API_VERSION="v1.4.1"

# Istio (Service Mesh - Ambient Mode)
export ISTIO_VERSION=1.29.0
export ISTIO_NAMESPACE=istio-system

# Agentgateway (Agent-to-Agent Gateway)
export AGENTGATEWAY_VERSION=0.12.0
export AGENTGATEWAY_NAMESPACE=agentgateway-system

# Agentregistry (Agent Discovery)
export AGENTREGISTRY_VERSION=0.1.26
export AGENTREGISTRY_NAMESPACE=agentregistry-system

# Credentials
export OPENAI_API_KEY=""
export LICENSE_KEY=""
