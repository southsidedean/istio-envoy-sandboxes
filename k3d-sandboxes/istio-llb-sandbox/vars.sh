#!/bin/bash
# vars.sh
# Environment variables for the sandbox
#
# Tom Dean
# Last edit: 5/13/2025
#
# Set variables here and then execute or source script
# Do this before executing any sandbox scripts

export NUM_CLUSTERS=1
export CLUSTER_NAME_PREFIX=istio-llb-
export KUBECTX_NAME_PREFIX=istio-llb-
export CLUSTER_NETWORK=istio-network
export K3S_VERSION=v1.35.2-k3s1
export HTTP_PORT_PREFIX=72
export HTTPS_PORT_PREFIX=82
export API_PORT_PREFIX=92
export ISTIO_VERSION=1.29.1
export ISTIO_NAMESPACE=istio-system
export MOVIES_NAMESPACE=movies
export GRAFANA_NAMESPACE=grafana
export GLOO_MESH_NAMESPACE=gloo-mesh
export KIALI_VERSION=v2.23.0
export GATEWAY_API_VERSION=v1.5.1
export GLOO_MESH_LICENSE_KEY="" # Replace with your Gloo Mesh Enterprise license key
export GLOO_OPERATOR_VERSION=0.5.0
