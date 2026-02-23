#!/bin/bash
# vars.sh
# Environment variables for the sandbox
#
# Tom Dean
# Last edit: 5/12/2025
#
# Set variables here and then execute or source script
# Do this before executing any sandbox scripts

export NUM_CLUSTERS=1
export CLUSTER_NAME_PREFIX=gme-llb-
export KUBECTX_NAME_PREFIX=gme-llb-
export CLUSTER_NETWORK=gme-network
export GLOO_MESH_LICENSE_KEY=<<INSERT_LICENSE_STRING_HERE>>
export GME_VERSION=v2.8.0
export ISTIO_VERSION=1.25.2
export ISTIO_IMAGE=${ISTIO_VERSION}-solo
export REPO_KEY=e038d180f90a
export REPO=us-docker.pkg.dev/gloo-mesh/istio-${REPO_KEY}
export HELM_REPO=us-docker.pkg.dev/gloo-mesh/istio-helm-${REPO_KEY}
export GATEWAY_API_VERSION=v1.2.1
