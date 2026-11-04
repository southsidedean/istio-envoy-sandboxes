#!/bin/bash
# vars.sh
# Environment variables for the sandbox
#
# Tom Dean
# Last edit: 11/4/2026
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
export KIALI_VERSION=2.23.0
export GRAFANA_CHART_VERSION=10.5.15
export TRAEFIK_CHART_VERSION=39.0.2
export GATEWAY_API_VERSION=v1.5.1
