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
export GLOO_MESH_LICENSE_KEY="" # Replace with your Gloo Mesh Enterprise license key
export GME_VERSION=v2.12.1
export K3S_VERSION=v1.35.2-k3s1
export HTTP_PORT_PREFIX=90
export HTTPS_PORT_PREFIX=94
export API_PORT_PREFIX=96
export ISTIO_VERSION=1.29.1
export ISTIO_NAMESPACE=istio-system
export MOVIES_NAMESPACE=movies
export GRAFANA_NAMESPACE=grafana
export GLOO_MESH_NAMESPACE=gloo-mesh
export ISTIO_IMAGE=${ISTIO_VERSION}-solo
export REPO=us-docker.pkg.dev/soloio-img/istio
export HELM_REPO=us-docker.pkg.dev/soloio-img/istio-helm
export GATEWAY_API_VERSION=v1.5.1
export GLOO_OPERATOR_VERSION=0.5.0
