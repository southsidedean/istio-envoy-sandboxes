# kgateway-sandbox

**Kgateway (OSS) API Gateway**

Tom Dean
Last edit: 11/4/2026

## Introduction

The `kgateway-sandbox` provides a testing environment for kgateway, the open source Kubernetes-native API gateway implementing the Gateway API specification. This sandbox deploys kgateway 2.x via OCI Helm charts with the movies app for load testing.

> **Verified 11/4/2026** with kgateway 2.2.2, Gateway API v1.5.1, and k3s v1.35.2-k3s1.

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
| `NUM_CLUSTERS` | 1 | Number of k3d clusters to create |
| `CLUSTER_NAME_PREFIX` | `kgw-` | Prefix for cluster names |
| `KUBECTX_NAME_PREFIX` | `kgw-` | Prefix for kubectl context names |
| `KGATEWAY_VERSION` | 2.2.2 | Kgateway version |
| `GATEWAY_API_VERSION` | v1.5.1 | Gateway API CRD version |
| `K3S_VERSION` | v1.35.2-k3s1 | K3s version for cluster nodes |
| `HTTP_PORT_PREFIX` | 80 | HTTP port prefix |
| `HTTPS_PORT_PREFIX` | 84 | HTTPS port prefix |
| `API_PORT_PREFIX` | 86 | API port prefix |

## Quick Start

```bash
# 1. Configure your environment
vi vars.sh

# 2. Deploy the full stack (k3d + kgateway + movies app)
./scripts/cluster-setup-k3d-kgw-everything.sh

# 3. When finished, tear it all down
./scripts/cluster-destroy-k3d.sh
```

## Alternative: Bare Clusters

To create just the k3d clusters without installing kgateway:

```bash
./scripts/cluster-setup-k3d-naked.sh
```

## What Gets Deployed

### `cluster-setup-k3d-kgw-everything.sh` Step by Step

1. **k3d clusters** - Creates `NUM_CLUSTERS` local Kubernetes clusters. The first cluster uses:
   - HTTP port 8001 (mapped to port 80 in cluster)
   - HTTPS port 8401 (mapped to port 443 in cluster)
   - API port 8601

2. **Gateway API CRDs** - Installs the Kubernetes Gateway API experimental CRDs on each cluster

3. **kgateway** - Installs kgateway OSS via OCI Helm charts into `kgateway-system` namespace on each cluster
   - Chart: `oci://cr.kgateway.dev/kgateway-dev/charts/kgateway`
   - GatewayClass: `kgateway`

4. **HTTP Gateway** - Creates a Gateway listener on port 80

5. **Movies app** - Deploys a sample load-testing application into the `movies` namespace on each cluster

### Movies Sample Application

The `movies/` directory contains a load-testing application:

**Backend services** (`movieinfo-chi`, `movieinfo-lax`, `movieinfo-nyc`):
- Nginx containers serving location-specific HTML responses
- All three share the `app: movieinfo` label and are load-balanced behind a single `movieinfo` ClusterIP Service
- Resource limits: 50m/200m CPU, 64Mi/128Mi memory

**Load generators** (`frontend-central`, `frontend-east`, `frontend-west`):
- [Fortio](https://github.com/fortio/fortio) containers running continuous load at 500 QPS each (1500 QPS total)
- Target: `http://movieinfo.movies.svc.cluster.local/index.html`

```
frontend-central ──┐
frontend-east    ──┼── 1500 QPS ──► movieinfo (ClusterIP) ──┬── movieinfo-chi
frontend-west    ──┘                                        ├── movieinfo-lax
                                                            └── movieinfo-nyc
```

## Repository Structure

```
├── vars.sh                              # Environment variables (edit before use)
├── scripts/
│   ├── cluster-setup-k3d-kgw-everything.sh  # Full stack deployment
│   ├── cluster-setup-k3d-naked.sh           # Bare k3d clusters only
│   └── cluster-destroy-k3d.sh               # Cluster teardown
├── cluster-k3d/
│   └── k3d-cluster.yaml                     # k3d cluster configuration
├── manifests/
│   └── http-listener.yaml                   # Gateway API HTTP listener
└── movies/
    ├── namespace.yaml                       # movies namespace
    ├── movieinfo-service.yaml               # ClusterIP service
    ├── movieinfo-{chi,lax,nyc}.yaml         # Backend deployments + ConfigMaps
    └── frontend-{central,east,west}.yaml    # Fortio load generators
```

## Accessing the Clusters

After deployment, you can switch between cluster contexts:

```bash
# List all contexts
kubectx

# Switch to a specific cluster
kubectx kgw-01

# View resources in a cluster
kubectl get all -n kgateway-system
kubectl get all -n movies
```

## Port Mappings

Each cluster has its own port mappings on localhost. These are the first three, if you raise `NUM_CLUSTERS`:

| Cluster | HTTP Port | HTTPS Port | API Port |
|---------|-----------|------------|----------|
| kgw-01 | 8001 | 8401 | 8601 |
| kgw-02 | 8002 | 8402 | 8602 |
| kgw-03 | 8003 | 8403 | 8603 |

Access services via:
```bash
# Example: Access cluster 1
curl http://localhost:8001
```

This returns a 404 until you add an HTTPRoute, because the sandbox creates the Gateway but no routes.

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
kubectl get pods -n kgateway-system
kubectl get pods -n movies

# View pod logs
kubectl logs -n kgateway-system <pod-name>

# Check Gateway status
kubectl get gateways -A
kubectl get gatewayclass
```

## Cleanup

```bash
./scripts/cluster-destroy-k3d.sh
```

This deletes all k3d clusters and cleans up kubectl contexts.

## Documentation

- [Kgateway Documentation](https://kgateway.dev/docs/)
- [Gateway API Specification](https://gateway-api.sigs.k8s.io/)

---

Tom Dean
Last updated: November 4, 2026
