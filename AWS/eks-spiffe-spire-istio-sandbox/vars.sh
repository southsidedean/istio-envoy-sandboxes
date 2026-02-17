# vars.sh
# Environment variables for the sandbox
#
# Tom Dean
# Last edit: 2/16/2026
#
# Set variables here and then execute or source script
# Do this before executing any sandbox scripts

export NUM_CLUSTERS=1
export CLUSTER_NAME_PREFIX=spire-
export KUBECTX_NAME_PREFIX=spire-
export CLUSTER_NETWORK=spire-network
export ISTIO_NAMESPACE=spire-system
export ISTIOCTL_VERSION=1.25.2
export ISTIO_VERSION=1.25.2
export EKS_VERSION=1.33
export SPIRE_VERSION=1.11.3
export AWS_PROFILE=<<INSERT_AWS_PROFILE_HERE>>
export AWS_REGION="us-east-1"
export NODE_TYPE="t3.small"
export LICENSE_KEY=<<INSERT_LICENSE_STRING_HERE>>
