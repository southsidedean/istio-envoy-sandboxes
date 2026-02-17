# vars.sh
# Environment variables for the sandbox
#
# Tom Dean
# Last edit: 2/16/2026
#
# Set variables here and then execute or source script
# Do this before executing any sandbox scripts

export CLUSTER_NAME="spire-01"
export KUBECTX_NAME_PREFIX="spire-"
export CLUSTER_NETWORK="spire-network"
export ISTIO_NAMESPACE="istio-system"
export ISTIOCTL_VERSION="1.25.3"
export ISTIO_VERSION="1.25.3"
export ISTIO_IMAGE=${ISTIO_VERSION}-solo
export REPO_KEY="<<INSERT_REPO_KEY_HERE>>"
export REPO=us-docker.pkg.dev/gloo-mesh/istio-${REPO_KEY}
export HELM_REPO=us-docker.pkg.dev/gloo-mesh/istio-helm-${REPO_KEY}
export EKS_VERSION="1.33"
export KGATEWAY_VERSION="v2.2.0"
export GATEWAY_API_VERSION="1.4.0"
export SPIRE_VERSION="0.24.1"
export SPIRE_APP_VERSION="1.11.0"
export AWS_PROFILE="<<INSERT_AWS_PROFILE_HERE>>"
export AWS_REGION="us-east-1"
export NODE_TYPE="t3a.large"
export SOLO_ISTIO_LICENSE_KEY="<<INSERT_LICENSE_STRING_HERE>>"
export GRAFANA_ADMIN_USER="admin"
export GRAFANA_ADMIN_PASSWORD="<<INSERT_GRAFANA_PASSWORD_HERE>>"
