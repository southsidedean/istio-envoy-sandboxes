# Istio Sandbox

Local k3d sandbox for testing Istio service mesh.

## Prerequisites

The following tools must be installed and available on your `PATH`:

- [k3d](https://k3d.io/) - Local Kubernetes cluster
- [kubectl](https://kubernetes.io/docs/tasks/tools/) - Kubernetes CLI
- [kubectx](https://github.com/ahmetb/kubectx) - Context switching
- [Helm](https://helm.sh/) - Chart installations

## Configuration

Edit `vars.sh` before running scripts:

| Variable | Default | Description |
|----------|---------|-------------|
| `NUM_CLUSTERS` | 3 | Number of k3d clusters to create |
| `CLUSTER_NAME_PREFIX` | `istio-` | Prefix for cluster names |
| `KUBECTX_NAME_PREFIX` | `istio-` | Prefix for kubectl context names |
| `CLUSTER_NETWORK` | `istio-network` | Network name for k3d clusters |
| `K3S_VERSION` | `v1.35.2-k3s1` | K3s version for cluster nodes |
| `HTTP_PORT_PREFIX` | `71` | HTTP port prefix |
| `HTTPS_PORT_PREFIX` | `75` | HTTPS port prefix |
| `API_PORT_PREFIX` | `79` | API port prefix |

## Quick Start

```bash
# 1. Create bare k3d clusters
./scripts/cluster-setup-k3d-naked.sh

# 2. Install Istio manually using istioctl or Helm
# (Instructions depend on your Istio installation method)

# 3. When finished, tear it all down
./scripts/cluster-destroy-k3d.sh
```

## What Gets Deployed

### `cluster-setup-k3d-naked.sh`

Creates 3 local Kubernetes clusters with:
- HTTP ports: 7101, 7102, 7103 (mapped to port 80 in cluster)
- HTTPS ports: 7501, 7502, 7503 (mapped to port 443 in cluster)
- API ports: 7901, 7902, 7903

**Note:** This script creates bare clusters without Istio installed. You'll need to install Istio manually using your preferred method (istioctl, Helm, or Operator).

## Repository Structure

```
├── vars.sh                       # Environment variables (edit before use)
├── scripts/
│   ├── cluster-setup-k3d-naked.sh     # Bare k3d clusters only
│   └── cluster-destroy-k3d.sh         # Cluster teardown
└── cluster-k3d/
    ├── k3d-cluster.yaml               # Default k3d cluster configuration
    ├── k3d-tiny.yaml                  # Minimal resource configuration
    ├── k3d-small.yaml                 # Small resource configuration
    ├── k3d-medium.yaml                # Medium resource configuration
    └── k3d-large.yaml                 # Large resource configuration
```

## Accessing the Clusters

After deployment, you can switch between cluster contexts:

```bash
# List all contexts
kubectx

# Switch to a specific cluster
kubectx istio-01
kubectx istio-02
kubectx istio-03

# View resources in a cluster
kubectl get all -n istio-system
```

## Port Mappings

Each cluster has its own port mappings on localhost:

| Cluster | HTTP Port | HTTPS Port | API Port |
|---------|-----------|------------|----------|
| istio-01 | 7101 | 7501 | 7901 |
| istio-02 | 7102 | 7502 | 7902 |
| istio-03 | 7103 | 7503 | 7903 |

Access services via:
```bash
# Example: Access cluster 1
curl http://localhost:7101
```

## Installing Istio

After creating the clusters, install Istio using one of the following methods:

### Using istioctl

```bash
# Download istioctl
curl -L https://istio.io/downloadIstio | sh -
cd istio-*
export PATH=$PWD/bin:$PATH

# Install Istio
istioctl install --set profile=demo -y
```

### Using Helm

```bash
# Add Istio Helm repository
helm repo add istio https://istio-release.storage.googleapis.com/charts
helm repo update

# Install Istio base
helm install istio-base istio/base -n istio-system --create-namespace

# Install Istio discovery (istiod)
helm install istiod istio/istiod -n istio-system --wait
```

## Troubleshooting

### Cluster Status
```bash
# List all k3d clusters
k3d cluster list

# View cluster contexts
kubectx
```

### Pod Issues
```bash
# Check pod status
kubectl get pods -n istio-system

# View pod logs
kubectl logs -n istio-system <pod-name>
```

## Cleanup

```bash
./scripts/cluster-destroy-k3d.sh
```

This deletes all k3d clusters and cleans up kubectl contexts.
