# Gloo Edge Enterprise Gateway Sandbox

Local k3d sandbox for testing Gloo Edge Enterprise Gateway.

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
| `CLUSTER_NAME_PREFIX` | `gloo-` | Prefix for cluster names |
| `KUBECTX_NAME_PREFIX` | `gloo-` | Prefix for kubectl context names |
| `GLOO_NAMESPACE` | `gloo-system` | Namespace for Gloo Gateway |
| `GLOOCTL_VERSION` | `1.18.17` | Version of glooctl CLI to install |
| `GLOO_VERSION` | `1.18.17` | Version of Gloo Gateway to install |
| `LICENSE_KEY` | Required | Solo.io license key (set this before running) |

## Quick Start

```bash
# 1. Configure your environment
vi vars.sh  # Set LICENSE_KEY to your Solo.io license

# 2. Deploy the full stack (k3d + Gloo Gateway + movies app)
./scripts/cluster-setup-k3d-glooe-everything.sh

# 3. When finished, tear it all down
./scripts/cluster-destroy-k3d.sh
```

## Alternative: Bare Clusters

To create just the k3d clusters without installing Gloo Gateway:

```bash
./scripts/cluster-setup-k3d-naked.sh
```

This is useful for manually installing and experimenting with individual components.

## What Gets Deployed

### `cluster-setup-k3d-glooe-everything.sh` Step by Step

1. **k3d clusters** - Creates 3 local Kubernetes clusters with:
   - HTTP ports: 8001, 8002, 8003 (mapped to port 80 in cluster)
   - HTTPS ports: 8401, 8402, 8403 (mapped to port 443 in cluster)
   - API ports: 8601, 8602, 8603

2. **Gloo Edge Enterprise Gateway** - Installs Gloo Gateway via Helm into `gloo-system` namespace on each cluster

3. **Movies app** - Deploys a sample load-testing application into the `movies` namespace on each cluster

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
├── vars.sh                                   # Environment variables (edit before use)
├── scripts/
│   ├── cluster-setup-k3d-glooe-everything.sh # Full stack deployment
│   ├── cluster-setup-k3d-naked.sh            # Bare k3d clusters only
│   └── cluster-destroy-k3d.sh                # Cluster teardown
├── cluster-k3d/
│   ├── k3d-cluster.yaml                      # Default k3d cluster configuration
│   ├── k3d-tiny.yaml                         # Minimal resource configuration
│   ├── k3d-small.yaml                        # Small resource configuration
│   ├── k3d-medium.yaml                       # Medium resource configuration
│   └── k3d-large.yaml                        # Large resource configuration
├── manifests/
│   ├── gloo-gateway-values.yaml              # Gloo Gateway Helm overrides
│   ├── grafana-values.yaml                   # Grafana Helm overrides (optional)
│   └── grafana-ingress.yaml                  # Grafana ingress configuration (optional)
└── movies/                                   # Symlink to apps/movies-app/single-cluster
    ├── namespace.yaml                        # movies namespace
    ├── movieinfo-service.yaml                # ClusterIP service
    ├── movieinfo-{chi,lax,nyc}.yaml          # Backend deployments + ConfigMaps
    └── frontend-{central,east,west}.yaml     # Fortio load generators
```

## Accessing the Clusters

After deployment, you can switch between cluster contexts:

```bash
# List all contexts
kubectx

# Switch to a specific cluster
kubectx gloo-01
kubectx gloo-02
kubectx gloo-03

# View resources in a cluster
kubectl get all -n gloo-system
kubectl get all -n movies
```

## Port Mappings

Each cluster has its own port mappings on localhost:

| Cluster | HTTP Port | HTTPS Port | API Port |
|---------|-----------|------------|----------|
| gloo-01 | 8001 | 8401 | 8601 |
| gloo-02 | 8002 | 8402 | 8602 |
| gloo-03 | 8003 | 8403 | 8603 |

Access services via:
```bash
# Example: Access cluster 1
curl http://localhost:8001
```

## Troubleshooting

### License Key Issues
Ensure `LICENSE_KEY` is set in `vars.sh` before running setup scripts.

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
kubectl get pods -n gloo-system
kubectl get pods -n movies

# View pod logs
kubectl logs -n gloo-system <pod-name>
```

## Cleanup

```bash
./scripts/cluster-destroy-k3d.sh
```

This deletes all k3d clusters and cleans up kubectl contexts.
