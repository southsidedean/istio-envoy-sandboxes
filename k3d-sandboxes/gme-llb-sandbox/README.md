# gme-llb-sandbox

**Gloo Mesh Enterprise Locality Load Balancing**

Tom Dean
Last edit: 2/23/2026

## Introduction

The `gme-llb-sandbox` provides an enterprise service mesh testing environment with Gloo Mesh, supporting multi-cluster deployments and advanced traffic management. This sandbox demonstrates locality-aware load balancing, where traffic is preferentially routed to services in the same geographic zone to minimize latency.

## Technology Stack

- **Gloo Mesh Enterprise v2.8.0** - Multi-cluster service mesh platform
- **Istio 1.25.2** (Solo distribution) - Service mesh data plane
- **Gateway API v1.2.1** - Kubernetes-native ingress specification
- **Movies app** - Multi-zone load testing application with zone affinity
- **Multi-cluster support** - Scales to multiple Kubernetes clusters

## Prerequisites

- [k3d](https://k3d.io) - Local Kubernetes cluster manager
- [Docker](https://www.docker.com/get-started/) - Container runtime
- [Helm](https://helm.sh/docs/intro/install/) - Kubernetes package manager
- `bash` shell
- [kubectl](https://kubernetes.io/docs/tasks/tools/) - Kubernetes CLI
- [kubectx](https://github.com/ahmetb/kubectx) - Context switching utility
- Internet access to pull containers and Helm charts
- **Solo.io Gloo Mesh Enterprise license** (required)

## Quick Start

### 1. Configure Environment

Edit `vars.sh` and set your Gloo Mesh license key:

```bash
vi vars.sh  # Set GLOO_MESH_LICENSE_KEY
```

### 2. Deploy the Full Stack

Choose deployment mode:

```bash
# Ambient mode (sidecar-less)
./scripts/cluster-setup-k3d-amb-everything.sh

# Sidecar mode (traditional Istio)
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

# Verify Gloo Mesh installation
kubectl get pods -n gloo-mesh

# Check Istio components
kubectl get pods -n istio-system

# Verify movies application
kubectl get pods -n movies
```

### 4. Tear Down

```bash
# Single cluster
./scripts/cluster-destroy-k3d.sh

# Multiple clusters (if deployed)
./scripts/cluster-destroy-k3d-both.sh
```

## Configuration

### Environment Variables (vars.sh)

| Variable | Default | Description |
|----------|---------|-------------|
| `NUM_CLUSTERS` | 1 | Number of k3d clusters |
| `CLUSTER_NAME_PREFIX` | `gme-llb-` | Prefix for cluster names |
| `GLOO_MESH_LICENSE_KEY` | Required | Gloo Mesh Enterprise license |
| `GME_VERSION` | v2.8.0 | Gloo Mesh Enterprise version |
| `ISTIO_VERSION` | 1.25.2 | Istio version (Solo distribution) |
| `GATEWAY_API_VERSION` | v1.2.1 | Gateway API version |

## Use Cases

- **Enterprise multi-cluster service mesh** - Unified mesh across multiple clusters
- **Advanced traffic policies** - Weighted routing, retries, timeouts, circuit breaking
- **Cross-cluster communication** - Seamless service discovery and routing
- **Locality-aware load balancing** - Zone-aware traffic distribution
- **Enterprise security features** - mTLS, authorization policies, zero-trust architecture
- **Multi-tenancy** - Workspace isolation and policy enforcement

## Architecture

### Deployment Layers

```
┌─────────────────────────────────────────────┐
│          Gloo Mesh Management Plane         │
│     (Multi-cluster coordination & policy)   │
├─────────────────────────────────────────────┤
│              Istio Data Plane               │
│  (Service mesh - sidecar or ambient mode)   │
├─────────────────────────────────────────────┤
│           Movies Application                │
│  (3 backends + 3 frontends, zone-labeled)   │
├─────────────────────────────────────────────┤
│            k3d Cluster(s)                   │
└─────────────────────────────────────────────┘
```

### Multi-Zone Configuration

The movies app deploys with zone labels:
- **Central zone**: movieinfo-chi, frontend-central
- **West zone**: movieinfo-lax, frontend-west
- **East zone**: movieinfo-nyc, frontend-east

## Locality Load Balancing

### How It Works

Gloo Mesh configures Istio to preferentially route traffic to services in the same zone:

1. **Same zone (100% preference)** - Traffic stays local when possible
2. **Same region (lower priority)** - Falls back to nearby zones
3. **Any zone (lowest priority)** - Only used when local endpoints unavailable

### Observing Locality

```bash
# Check pod zone labels
kubectl get pods -n movies --show-labels

# View endpoint distribution
kubectl get endpoints -n movies movieinfo -o yaml

# Exec into frontend pod and generate traffic
kubectl exec -n movies deploy/frontend-central -- sh
curl http://movieinfo.movies.svc.cluster.local/index.html
```

## Ambient vs Sidecar Modes

### Ambient Mode
- **Zero sidecar overhead** - No per-pod proxy injection
- **ztunnel DaemonSet** - Node-level L4 proxy
- **Waypoint proxies** - Optional L7 processing
- **Lower resource usage** - Fewer containers overall

### Sidecar Mode
- **Traditional Istio** - Envoy proxy per pod
- **Full L7 features** - All advanced routing in sidecar
- **Well-established** - Mature production pattern

## Troubleshooting

### License Issues

```bash
# Verify license key is set
echo $GLOO_MESH_LICENSE_KEY

# Check Gloo Mesh pods
kubectl get pods -n gloo-mesh
kubectl logs -n gloo-mesh deployment/gloo-mesh-mgmt-server
```

### Istio Issues

```bash
# Check Istio components
kubectl get pods -n istio-system

# For ambient mode
kubectl get daemonset -n istio-system ztunnel

# For sidecar mode
kubectl get pods -n movies -o jsonpath='{.items[*].spec.containers[*].name}'
```

### Movies App Issues

```bash
# Check movies pods
kubectl get pods -n movies

# View load generator status
kubectl logs -n movies deployment/frontend-central

# Test connectivity
kubectl exec -n movies deploy/frontend-central -- curl -v http://movieinfo:8080/index.html
```

## Advanced Usage

### Multi-Cluster Setup

```bash
# Deploy both clusters
./scripts/cluster-setup-k3d-both-everything.sh

# Switch contexts
kubectx gme-llb-01
kubectx gme-llb-02

# Verify cross-cluster discovery
kubectl get serviceentry -A
```

### Traffic Policies

Apply Gloo Mesh traffic policies for advanced routing:

```bash
# Example: Weighted routing between zones
kubectl apply -f manifests/traffic-policy.yaml

# Example: Failover configuration
kubectl apply -f manifests/failover-policy.yaml
```

## Next Steps

- Configure advanced traffic policies
- Test cross-cluster service discovery
- Implement zero-trust security policies
- Add custom applications with zone affinity
- Integrate with observability platforms (Prometheus, Grafana)
- Explore workspace-based multi-tenancy

## Documentation

- [Gloo Mesh Documentation](https://docs.solo.io/gloo-mesh-enterprise/latest/)
- [Locality Load Balancing Guide](https://docs.solo.io/gloo-mesh-enterprise/latest/routing/locality-load-balancing/)
- [Istio Ambient Mode](https://istio.io/latest/docs/ambient/)
- [Solo.io Support](https://support.solo.io/)

---

Tom Dean
Last updated: February 23, 2026
