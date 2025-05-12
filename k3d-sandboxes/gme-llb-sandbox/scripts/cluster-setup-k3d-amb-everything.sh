#!/bin/bash
# cluster-setup-k3d-amb-everything.sh
# Automates k3d cluster creation with Ambient mesh
# Tom Dean
# Last edit: 5/12/2025

# Set environment variables

source vars.sh

# Delete existing k3d clusters

for cluster in `seq -f %02g 1 $NUM_CLUSTERS`
do
clustername=$CLUSTER_NAME_PREFIX$cluster
k3d cluster delete $clustername
done

# Create the k3d clusters

for cluster in `seq -f %02g 1 $NUM_CLUSTERS`
do
clustername=$CLUSTER_NAME_PREFIX$cluster
k3d cluster create $clustername -c cluster-k3d/k3d-cluster.yaml --port 90${cluster}:80@loadbalancer --port 94${cluster}:443@loadbalancer --api-port 0.0.0.0:96${cluster}
done

k3d cluster list

# Configure the kubectl context

for kubectx in `seq -f %02g 1 $NUM_CLUSTERS`
do
kubectxname=$KUBECTX_NAME_PREFIX$kubectx
clustername=$CLUSTER_NAME_PREFIX$kubectx
kubectx -d $kubectxname
kubectx $kubectxname=k3d-$clustername
done

kubectx ${KUBECTX_NAME_PREFIX}01
kubectx

# Deploy the 'movies' application

kubectl apply -k movies

# Label the 'movies' namespace to enable Isio Ambient mesh
# Also, enable waypoint for the 'movies' namespace

kubectl label ns movies istio.io/dataplane-mode=ambient
kubectl label ns movies istio.io/use-waypoint=auto

# Deploy Gloo Mesh Enterprise
# Deploy 'meshctl'

#curl -sL https://run.solo.io/meshctl/install | GLOO_MESH_VERSION=$GME_VERSION sh -
#export PATH=$HOME/.gloo-mesh/bin:$PATH

# Deploy 'istioctl'

curl -L https://istio.io/downloadIstio | ISTIO_VERSION=${ISTIO_VERSION} sh -
export PATH=$PWD/istio-${ISTIO_VERSION}/bin:$PATH

# Install Gateway API CRDs

kubectl apply -f https://github.com/kubernetes-sigs/gateway-api/releases/download/$GATEWAY_API_VERSION/standard-install.yaml

# Deploy Istio

export CLUSTER_NAME=${CLUSTER_NAME_PREFIX}01
echo
echo "Cluster name is: "$CLUSTER_NAME
echo

# Deploy Gloo Mesh Enterprise
# Install Gloo Operator to the 'gloo-mesh' namespace

#meshctl install --profiles gloo-mesh-enterprise-single,ratelimit,extauth \
#--set common.cluster=${CLUSTER_NAME} \
#--set glooMgmtServer.createGlobalWorkspace=true \
#--set licensing.glooMeshLicenseKey=${GLOO_MESH_LICENSE_KEY}

# Check our deployment after sleeping for 90 seconds

sleep 90
istioctl check

# Using Helm

helm upgrade --install istio-base oci://${HELM_REPO}/base \
--namespace istio-system \
--create-namespace \
--version ${ISTIO_IMAGE} \
-f - <<EOF
defaultRevision: ""
profile: ambient
EOF

helm upgrade --install istiod oci://${HELM_REPO}/istiod \
--namespace istio-system \
--version ${ISTIO_IMAGE} \
-f - <<EOF
global:
  hub: ${REPO}
  proxy:
    clusterDomain: cluster.local
  tag: ${ISTIO_IMAGE}
istio_cni:
  namespace: istio-system
  enabled: true
meshConfig:
  accessLogFile: /dev/stdout
  defaultConfig:
    proxyMetadata:
      ISTIO_META_DNS_AUTO_ALLOCATE: "true"
      ISTIO_META_DNS_CAPTURE: "true"
env:
  PILOT_ENABLE_IP_AUTOALLOCATE: "true"
  PILOT_ENABLE_K8S_SELECT_WORKLOAD_ENTRIES: "false"
  PILOT_SKIP_VALIDATE_TRUST_DOMAIN: "true"
profile: ambient
license:
  value: ${GLOO_MESH_LICENSE_KEY}
waypoint:
  topologySpreadConstraints:
  - maxSkew: 1
    topologyKey: topology.kubernetes.io/zone
    whenUnsatisfiable: DoNotSchedule
    labelSelector:
      matchLabels:
        waypoint-for:
EOF

helm upgrade --install istio-cni oci://${HELM_REPO}/cni \
--namespace istio-system \
--version ${ISTIO_IMAGE} \
-f - <<EOF
ambient:
  dnsCapture: true
excludeNamespaces:
  - istio-system
  - kube-system
global:
  hub: ${REPO}
  tag: ${ISTIO_IMAGE}
profile: ambient
EOF

# Using the Gloo Mesh Operator
#helm install gloo-operator oci://us-docker.pkg.dev/solo-public/gloo-operator-helm/gloo-operator \
#--version 0.2.3 \
#-n gloo-mesh \
#--create-namespace \
#--set manager.env.SOLO_ISTIO_LICENSE_KEY=${GLOO_MESH_LICENSE_KEY}

#kubectl get pods -n gloo-mesh -l app.kubernetes.io/name=gloo-operator

# Create configmap in the 'gloo-mesh' namespace to fix CNI configuration for k3d/k3s nodes

kubectl apply -f manifests/gloo-extensions-config-cm.yaml

# Deploy a managed Istio installation, using the Gloo Operator

#kubectl apply -n gloo-mesh -f manifests/managed-istio-ambient.yaml

# Verify installation

watch -n 1 kubectl get all -n istio-system

# Deploy the Ambient data plane

helm upgrade --install ztunnel oci://${HELM_REPO}/ztunnel \
--namespace istio-system \
--version ${ISTIO_IMAGE} \
-f - <<EOF
configValidation: true
enabled: true
env:
  L7_ENABLED: "true"
hub: ${REPO}
istioNamespace: istio-system
namespace: istio-system
profile: ambient
proxy:
  clusterDomain: cluster.local
tag: ${ISTIO_IMAGE}
terminationGracePeriodSeconds: 29
variant: distroless
EOF

# Verify Ambient data plane deployment

watch -n 1 'kubectl get pods -A | grep ztunnel'

# Rollout restart the deployments in the 'movies' namespace, in case they didn't get injected

#kubectl rollout restart deploy -n movies

# Verify the 'movies' app is good

watch -n 1 kubectl get all -n movies

# Install Grafana

helm repo add grafana https://grafana.github.io/helm-charts
helm install grafana -n grafana --create-namespace grafana/grafana \
  -f manifests/grafana-values.yaml --debug

# Create ingress for UI and Grafana

#kubectl apply -f manifests/grafana-ext-svc.yaml
#kubectl apply -f manifests/cluster-ingress.yaml
kubectl apply -f manifests/grafana-ingress.yaml
kubectl apply -f manifests/gloo-mesh-ui-ingress.yaml

# Start the Gloo Dashboard in the background and suppress output

#meshctl dashboard > /dev/null 2>&1 &

exit 0
