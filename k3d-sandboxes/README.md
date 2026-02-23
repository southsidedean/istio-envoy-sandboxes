# k3d Sandboxes

**Local Kubernetes Testing Environments for Service Mesh and API Gateway Technologies**

Tom Dean
Last edit: 2/23/2026

## Overview

This directory contains production-ready k3d-based sandbox environments for rapid iteration and testing of service mesh, API gateway, and AI agent technologies. All sandboxes run locally using k3d (Kubernetes in Docker), providing fast deployment and teardown for development and learning.

## Available Sandboxes

### AI Agent Platforms

#### [ai-sandbox](ai-sandbox/)
Comprehensive AI agent platform combining Istio Ambient, Kagent, Kgateway, Agentgateway, and Agentregistry.

**Stack:** Istio 1.29.0 (Ambient) • Kagent 0.7.17 • Kgateway 2.2.1 • Agentgateway 0.12.0 • Agentregistry 0.1.26

**Use For:** AI agent development, agent-to-agent communication, service mesh integration with AI workloads

#### [kagent-sandbox](kagent-sandbox/)
Dedicated Kagent testing environment with Kgateway ingress.

**Stack:** Kagent • Kgateway • Gateway API

**Use For:** AI agent framework testing, multi-LLM provider integration, agent lifecycle management

---

### Service Mesh

#### [istio-llb-sandbox](istio-llb-sandbox/)
Istio OSS with locality load balancing, supporting both sidecar and ambient modes.

**Stack:** Istio OSS • Kiali • Grafana • Prometheus • Movies app

**Use For:** Locality load balancing, multi-zone traffic distribution, Istio ambient vs sidecar comparison

#### [istio-sandbox](istio-sandbox/)
Basic Istio OSS environment for learning core service mesh features.

**Stack:** Istio OSS • Demo workloads

**Use For:** Learning Istio basics, testing service mesh policies, traffic management

#### [gme-llb-sandbox](gme-llb-sandbox/)
Gloo Mesh Enterprise with locality load balancing and multi-cluster support.

**Stack:** Gloo Mesh Enterprise • Istio (via Gloo Mesh) • Movies app

**Use For:** Enterprise multi-cluster service mesh, advanced traffic policies, cross-cluster communication

---

### API Gateway

#### [kgateway-sandbox](kgateway-sandbox/)
Kgateway (Gloo Gateway OSS) implementing the Kubernetes Gateway API specification.

**Stack:** Kgateway • Gateway API CRDs

**Use For:** Gateway API learning, cloud-native ingress patterns, HTTP routing

#### [gloo-gw-sandbox](gloo-gw-sandbox/)
Gloo Gateway v2 for advanced API gateway use cases.

**Stack:** Gloo Gateway v2 • Gateway API • Advanced routing

**Use For:** Modern API gateway patterns, GraphQL federation, AI gateway features

#### [glooe-gw-sandbox](glooe-gw-sandbox/)
Gloo Edge Gateway with Envoy-based data plane.

**Stack:** Gloo Edge Gateway • Envoy proxy

**Use For:** Enterprise API management, legacy application integration, hybrid cloud gateways

#### [ge-llb-sandbox](ge-llb-sandbox/)
Gloo Edge with locality-aware routing and multi-zone deployments.

**Stack:** Gloo Edge • Multi-zone configuration

**Use For:** Gloo Edge locality features, multi-region API gateways, zone-aware traffic distribution

---

## Quick Start

### Prerequisites

All sandboxes require:
- [k3d](https://k3d.io/) - Local Kubernetes cluster manager
- [Docker](https://www.docker.com/get-started/) - Container runtime
- [kubectl](https://kubernetes.io/docs/tasks/tools/) - Kubernetes CLI
- [kubectx](https://github.com/ahmetb/kubectx) - Context switching utility
- [Helm](https://helm.sh/) - Kubernetes package manager
- `bash` shell

### Usage Pattern

Each sandbox follows a consistent workflow:

```bash
# 1. Navigate to the sandbox
cd <sandbox-name>

# 2. Configure environment
vi vars.sh  # Set API keys, licenses, etc.

# 3. Deploy full stack
./scripts/cluster-setup-k3d-*-everything.sh

# 4. Verify deployment
kubectl get pods -A

# 5. Access services
# See individual sandbox README for access details

# 6. Clean up
./scripts/cluster-destroy-k3d.sh
```

## Common Features

### Configuration Files

All sandboxes use `vars.sh` for environment configuration:

```bash
export NUM_CLUSTERS=1
export CLUSTER_NAME_PREFIX=my-cluster-
export KUBECTX_NAME_PREFIX=my-cluster-

# Component versions
export KAGENT_VERSION=0.7.17
export KGATEWAY_VERSION=2.2.1
export ISTIO_VERSION=1.29.0

# Credentials (set before running)
export OPENAI_API_KEY=""
export LICENSE_KEY=""
```

### Script Naming Conventions

- `cluster-setup-k3d-*-everything.sh` - Full stack deployment
- `cluster-setup-k3d-naked.sh` - Bare cluster only
- `cluster-destroy-k3d.sh` - Complete teardown
- `cluster-setup-k3d-amb-everything.sh` - Ambient mode (Istio sandboxes)
- `cluster-setup-k3d-sc-everything.sh` - Sidecar mode (Istio sandboxes)

### Port Mappings

Most sandboxes expose services on `localhost`:

| Service | Port | Access |
|---------|------|--------|
| Kagent UI | 7001 | http://localhost:7001 |
| Kiali | 9001 | http://localhost:9001/kiali |
| Grafana | 9001 | http://localhost:9001/grafana |
| Kgateway HTTP | 7001-9001 | http://localhost:port |
| Kgateway HTTPS | 7401-9401 | https://localhost:port |

### Directory Structure

Each sandbox organizes files consistently:

```
sandbox-name/
├── README.md                   # Sandbox documentation
├── vars.sh                     # Environment variables
├── cluster-k3d/               # k3d cluster configurations
├── manifests/                 # Helm values and YAML
├── scripts/                   # Setup and teardown scripts
└── movies -> ../../apps/movies-app  # Symlink to demo app
```

## Technology Comparison

| Sandbox | Service Mesh | API Gateway | AI Agents | Observability | Locality LB |
|---------|--------------|-------------|-----------|---------------|-------------|
| ai-sandbox | Istio Ambient | Kgateway | ✓ | Basic | - |
| istio-llb-sandbox | Istio (both modes) | - | - | Full | ✓ |
| istio-sandbox | Istio | - | - | Basic | - |
| gme-llb-sandbox | Gloo Mesh | - | - | Basic | ✓ |
| kagent-sandbox | - | Kgateway | ✓ | - | - |
| kgateway-sandbox | - | Kgateway | - | - | - |
| gloo-gw-sandbox | - | Gloo Gateway v2 | - | - | - |
| glooe-gw-sandbox | - | Gloo Edge | - | - | - |
| ge-llb-sandbox | - | Gloo Edge | - | - | ✓ |

## Troubleshooting

### k3d Cluster Issues

```bash
# List running clusters
k3d cluster list

# Delete stuck cluster
k3d cluster delete <cluster-name>

# Check Docker resources
docker system df
docker system prune  # Free up space if needed
```

### Port Conflicts

If ports are already in use:

```bash
# Find what's using the port
lsof -i :7001

# Change port mapping in k3d cluster config
vi cluster-k3d/k3d-cluster.yaml
```

### Image Pull Issues

```bash
# Check Docker Hub rate limits
docker pull busybox  # Test pull

# Use registry mirror (configure in vars.sh)
export REGISTRY_MIRROR=https://mirror.gcr.io
```

## Best Practices

1. **Clean up regularly** - Run `cluster-destroy-k3d.sh` when done
2. **One sandbox at a time** - Avoid port conflicts
3. **Check Docker resources** - Ensure sufficient CPU/memory
4. **Update regularly** - Pull latest images and charts
5. **Read the sandbox README** - Each has specific requirements

## Getting Help

- **General issues**: See main repository [README](../README.md)
- **Sandbox-specific**: Check individual sandbox README
- **k3d documentation**: https://k3d.io/
- **Component docs**: Links in each sandbox README

---

Tom Dean
Last updated: February 23, 2026
