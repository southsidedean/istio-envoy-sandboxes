#!/bin/bash
# vars.sh
# Environment variables for the Enterprise AI sandbox
#
# Tom Dean
# Last edit: 3/27/2026
#
# Set variables here and then execute or source script
# Do this before executing any sandbox scripts

export NUM_CLUSTERS=1
export CLUSTER_NAME_PREFIX=ent-ai-
export KUBECTX_NAME_PREFIX=ent-ai-
export CLUSTER_NETWORK=ent-ai-network
export K3S_VERSION=v1.35.2-k3s1
export HTTP_PORT_PREFIX=60
export HTTPS_PORT_PREFIX=64
export API_PORT_PREFIX=68

# Solo Istio Distribution (Service Mesh - Ambient Mode)
export ISTIO_VERSION=1.29.1
export ISTIO_IMAGE=${ISTIO_VERSION}-solo
export REPO=us-docker.pkg.dev/soloio-img/istio
export HELM_REPO=us-docker.pkg.dev/soloio-img/istio-helm
export ISTIO_NAMESPACE=istio-system
export MOVIES_NAMESPACE=movies

# Solo Enterprise for Kagent (AI Agent Framework)
export KAGENT_NAMESPACE=kagent
export KAGENT_ENT_VERSION=0.3.12

# Solo Enterprise for Kgateway (API Gateway)
export ENT_KGATEWAY_VERSION=2.1.4
export KGATEWAY_NAMESPACE=kgateway-system

# Solo Enterprise for Agentgateway (Agent-to-Agent Gateway)
export ENT_AGENTGATEWAY_VERSION=2.1.1
export AGENTGATEWAY_NAMESPACE=agentgateway-system

# Agentregistry (Agent Discovery) - OSS
export AGENTREGISTRY_VERSION=0.3.2
export AGENTREGISTRY_NAMESPACE=agentregistry-system

# Gateway API
export GATEWAY_API_VERSION="v1.5.1"

# Credentials (set before running)
export OPENAI_API_KEY="" # Replace with your OpenAI API key
export LICENSE_KEY="" # Replace with your Solo Enterprise for Kgateway license key
export KAGENT_ENT_LICENSE_KEY=""   # Solo Enterprise for Kagent (if required)
export AGENTGATEWAY_LICENSE_KEY="" # Replace with your Solo Enterprise for Agentgateway license key
