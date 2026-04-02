# ge-llb-sandbox

**Gloo Edge Locality Load Balancing**

Tom Dean
Last edit: 3/27/2026

## Introduction

The `ge-llb-sandbox` provides a testing environment for Gloo Edge with locality-aware routing and multi-zone deployments. This sandbox demonstrates how Gloo Edge distributes traffic based on geographic zones to minimize latency and improve application performance.

## Technology Stack

- **Gloo Edge** - Enterprise API gateway with Envoy-based data plane
- **Multi-zone configuration** - Simulates central, west, and east regions
- **Movies app** - Multi-zone load testing application
- **Gateway API** - Kubernetes-native ingress specification

## Prerequisites

- [k3d](https://k3d.io) - Local Kubernetes cluster manager
- [Docker](https://www.docker.com/get-started/) - Container runtime
- [Helm](https://helm.sh/docs/intro/install/) - Kubernetes package manager
- `bash` shell
- [kubectl](https://kubernetes.io/docs/tasks/tools/) - Kubernetes CLI
- [kubectx](https://github.com/ahmetb/kubectx) - Context switching utility
- Internet access to pull containers and Helm charts

## Quick Start

### 1. Configure Environment

Edit `vars.sh` and set your Solo.io license key:

```bash
vi vars.sh  # Set GLOO_MESH_LICENSE_KEY
```

### 2. Deploy the Full Stack

Choose deployment mode:

```bash
# Ambient mode (recommended)
./scripts/cluster-setup-k3d-amb-everything.sh

# Sidecar mode
./scripts/cluster-setup-k3d-sc-everything.sh

# Both modes for comparison
./scripts/cluster-setup-k3d-both-everything.sh

# Bare cluster only (manual installation)
./scripts/cluster-setup-k3d-naked.sh
```

### 3. Verify Installation

```bash
# Check all pods are running
kubectl get pods -A

# Verify Gloo Edge installation
kubectl get all -n gloo-system

# Check movies application
kubectl get pods -n movies
```

### 4. Tear Down

```bash
./scripts/cluster-destroy-k3d.sh
```

## Configuration

### Environment Variables (vars.sh)

| Variable | Default | Description |
|----------|---------|-------------|
| `NUM_CLUSTERS` | 1 | Number of k3d clusters |
| `CLUSTER_NAME_PREFIX` | `ge-llb-` | Prefix for cluster names |
| `GLOO_MESH_LICENSE_KEY` | Required | Gloo Mesh Enterprise license |
| `GME_VERSION` | v2.12.1 | Gloo Mesh Enterprise version |
| `ISTIO_VERSION` | 1.29.1 | Istio version (Solo distribution) |
| `GATEWAY_API_VERSION` | v1.5.1 | Gateway API version |
| `GLOO_OPERATOR_VERSION` | 0.5.0 | Gloo Operator version |
| `K3S_VERSION` | v1.35.2-k3s1 | K3s version for cluster nodes |
| `HTTP_PORT_PREFIX` | 91 | HTTP port prefix |
| `HTTPS_PORT_PREFIX` | 95 | HTTPS port prefix |
| `API_PORT_PREFIX` | 97 | API port prefix |

### Port Mappings

| Cluster | HTTP Port | HTTPS Port | API Port |
|---------|-----------|------------|----------|
| ge-llb-01 | 9101 | 9501 | 9701 |

## Use Cases

- **Gloo Edge locality features** - Test zone-aware routing
- **Multi-region API gateways** - Simulate geographically distributed deployments
- **Zone-aware traffic distribution** - Minimize cross-zone traffic
- **Enterprise API gateway patterns** - Learn Gloo Edge capabilities
- **Load testing** - Observe traffic distribution across zones

## Architecture

The sandbox deploys:

1. **k3d cluster** with custom networking
2. **Gloo Edge** in gloo-system namespace
3. **Movies application** with zone labels:
   - movieinfo-chi (central zone)
   - movieinfo-lax (west zone)
   - movieinfo-nyc (east zone)
4. **Fortio load generators** (1500 QPS total)

## Troubleshooting

### License Issues

```bash
# Verify license key is set
echo $GLOO_MESH_LICENSE_KEY

# Check Gloo Edge pods
kubectl get pods -n gloo-system
kubectl logs -n gloo-system deployment/gloo
```

### Movies App Issues

```bash
# Check movies pods
kubectl get pods -n movies

# View load generator status
kubectl logs -n movies deployment/frontend-central
```

## Advanced Usage

### Testing Locality Load Balancing

```bash
# Exec into a frontend pod
kubectl exec -n movies deploy/frontend-central -- sh

# Generate traffic
curl -v http://movieinfo.movies.svc.cluster.local/index.html

# Observe traffic distribution in logs
```

### Viewing Zone Labels

```bash
# Check pod zone labels
kubectl get pods -n movies --show-labels

# View nodes with zone labels
kubectl get nodes --show-labels
```

## Next Steps

- Configure locality load balancing policies
- Test failover between zones
- Experiment with weighted routing
- Add custom applications with zone affinity
- Integrate with observability tools

## Documentation

- [Gloo Edge Documentation](https://docs.solo.io/gloo-edge/latest/)
- [Locality Load Balancing](https://docs.solo.io/gloo-edge/latest/guides/traffic_management/destination_types/discovered_upstream/locality/)
- [Solo.io Support](https://support.solo.io/)

---

Tom Dean
Last updated: March 27, 2026
