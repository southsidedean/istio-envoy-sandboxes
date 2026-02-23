# ai-sandbox

**Comprehensive AI Agent Platform Sandbox**

Tom Dean
Last edit: 2/23/2026

## Introduction

The `ai-sandbox` is a complete AI agent testing platform that combines service mesh, API gateway, agent gateway, and agent discovery capabilities in a local k3d environment. This sandbox integrates multiple cutting-edge technologies to provide a production-like AI agent development and testing environment.

### Technology Stack

- **Istio 1.29.0** (Ambient Mode) - Service mesh with mTLS for secure service-to-service communication
- **Kagent 0.7.17** - AI agent framework for autonomous agent lifecycle management
- **Kgateway 2.2.1** - Cloud-native API gateway implementing Kubernetes Gateway API
- **Agentgateway 0.12.0** - Agent-to-agent gateway with MCP multiplexing and A2A protocol support
- **Agentregistry 0.1.26** - Centralized agent discovery and governance platform
- **Gateway API v1.4.1** - Kubernetes-native ingress/gateway specification

## Prerequisites

Ensure you have the following tools installed:

- [`k3d`](https://k3d.io) - Local Kubernetes cluster manager
- [Docker](https://www.docker.com/get-started/) - Container runtime
- [Helm](https://helm.sh/docs/intro/install/) - Kubernetes package manager
- The `bash` shell
- [`kubectl`](https://kubernetes.io/docs/tasks/tools/) - Kubernetes CLI
- [`kubectx`](https://github.com/ahmetb/kubectx) - Kubernetes context switching utility
- [`curl`](https://curl.se/download.html) - HTTP client
- Internet access to pull containers and Helm charts

## Quick Start

### 1. Configure Environment

Edit `vars.sh` and set your OpenAI API key:

```bash
vi vars.sh  # Set OPENAI_API_KEY to your key
```

### 2. Deploy the Complete Stack

```bash
./scripts/cluster-setup-k3d-ai-everything.sh
```

This script will install (in order):
1. k3d cluster with custom networking
2. Istio Ambient Mode (base, istiod, CNI, ztunnel)
3. Kagent AI agent framework
4. Movies demo application
5. Istio waypoint proxies
6. Gateway API CRDs
7. Kgateway API gateway
8. Agentgateway for agent-to-agent communication
9. Agentregistry for agent discovery

### 3. Verify Installation

```bash
# Check all pods are running
kubectl get pods -n istio-system
kubectl get pods -n kagent
kubectl get pods -n kgateway-system
kubectl get pods -n agentgateway-system
kubectl get pods -n agentregistry-system
kubectl get pods -n movies

# Verify Istio ambient mode
kubectl get daemonsets -n istio-system ztunnel
kubectl get gateway -n movies waypoint
```

### 4. Access Services

- **Kagent UI**: http://localhost:7001
- **Agentgateway**: http://localhost:7001 (with `Host: agentgateway.local` header)
- **Agentregistry**: http://localhost:7001 (with `Host: agentregistry.local` header)

Example with curl:
```bash
# Access Kagent
curl http://localhost:7001

# Access Agentgateway
curl -H "Host: agentgateway.local" http://localhost:7001

# Access Agentregistry
curl -H "Host: agentregistry.local" http://localhost:7001
```

### 5. Tear Down

```bash
./scripts/cluster-destroy-k3d.sh
```

## Deployment Options

### Full AI Platform (Recommended)

```bash
./scripts/cluster-setup-k3d-ai-everything.sh
```

Deploys the complete stack with Istio, Kagent, Kgateway, Agentgateway, Agentregistry, and the movies application.

### Bare Cluster Only

```bash
./scripts/cluster-setup-k3d-naked.sh
```

Creates a clean k3d cluster without any components. Useful for manual installation and experimentation.

### Legacy Kagent-Only Setup

```bash
./scripts/cluster-setup-k3d-kagent-everything.sh
```

Deploys only Kagent and Kgateway (older configuration without Istio or agentgateway components).

## Architecture

### Component Overview

```
┌─────────────────────────────────────────────────────────────┐
│                        Kgateway (API Gateway)                │
│                     Gateway API v1.4.1                       │
│          ┌──────────────────────────────────────┐           │
│          │        HTTP Gateway (port 80)         │           │
│          └───────────────┬──────────────────────┘           │
└──────────────────────────┼──────────────────────────────────┘
                           │
         ┌─────────────────┼─────────────────┐
         │                 │                 │
    ┌────▼─────┐    ┌─────▼────────┐  ┌────▼──────────┐
    │  Kagent  │    │ Agentgateway │  │ Agentregistry │
    │  (7001)  │    │   (MCP/A2A)  │  │  (Discovery)  │
    └────┬─────┘    └──────┬───────┘  └───────┬───────┘
         │                 │                   │
         │         Istio Ambient Mesh (mTLS)  │
         │    ┌────────────┴────────────┐     │
         └────┤      ztunnel DaemonSet   ├────┘
              │   (L4 proxy on each node)│
              └────────────┬──────────────┘
                           │
                  ┌────────▼────────┐
                  │  Movies App     │
                  │  (Load Testing) │
                  └─────────────────┘
```

### Istio Ambient Mode

**What is it?**
Istio Ambient Mode is a sidecar-less service mesh architecture that uses a per-node Layer 4 proxy (ztunnel) and optional Layer 7 waypoint proxies. This provides service mesh capabilities without modifying application pods.

**Components:**
- **istio-base**: Custom Resource Definitions (CRDs)
- **istiod**: Control plane managing mesh configuration
- **istio-cni**: CNI plugin for traffic redirection (k3d/k3s optimized)
- **ztunnel**: Ambient data plane (DaemonSet) providing mTLS and L4 features
- **waypoint**: L7 proxy for advanced traffic management (deployed per namespace)

**Benefits:**
- No sidecar injection required
- Lower resource overhead
- Simplified pod lifecycle
- Transparent mTLS encryption
- Full observability and telemetry

**Enabled Namespaces:**
- `movies` - Demo application
- `kagent` - AI agent framework
- `agentgateway-system` - Agent-to-agent gateway

### Kagent (AI Agent Framework)

**What is it?**
Kagent is the first open-source agentic AI framework for Kubernetes, contributed to CNCF. It brings autonomous agents to cloud-native environments.

**Features:**
- Agent lifecycle management via Kubernetes CRDs
- Multi-LLM provider support (OpenAI, Azure, Anthropic, Ollama, etc.)
- Built-in MCP (Model Context Protocol) server with Kubernetes tools
- OpenTelemetry tracing for agent observability
- Web UI for agent management

**Access:**
- UI: http://localhost:7001
- Namespace: `kagent`
- Version: 0.7.17

### Kgateway (API Gateway)

**What is it?**
Kgateway is a cloud-native API gateway and AI gateway, implementing the Kubernetes Gateway API specification. It's a CNCF Sandbox project.

**Features:**
- Full Gateway API v1 compliance
- Advanced routing (path, header, method-based)
- Rate limiting and authentication
- AI gateway capabilities
- Envoy-powered data plane

**Configuration:**
- HTTPRoutes define routing rules
- Gateway resource (`http-gateway`) listens on port 80
- Routes traffic to backend services based on Host headers

### Agentgateway (Agent-to-Agent Gateway)

**What is it?**
Agentgateway is an open-source data plane optimized for agentic AI connectivity, part of the Linux Foundation.

**Features:**
- MCP (Model Context Protocol) multiplexing
- A2A (Agent-to-Agent) protocol support
- Drop-in security, observability, and governance
- OpenTelemetry integration
- Written in Rust for performance

**Access:**
- API: http://localhost:7001 (Host: agentgateway.local)
- Namespace: `agentgateway-system`
- Version: 0.12.0

### Agentregistry (Agent Discovery)

**What is it?**
Agentregistry provides centralized governance and control for AI artifacts and infrastructure.

**Features:**
- Centralized registry for MCP servers, agents, and skills
- Automatic validation and scoring
- Governance and access control
- Kubernetes CRD-based storage
- Integration with agentgateway and kagent

**Access:**
- API: http://localhost:7001 (Host: agentregistry.local)
- Namespace: `agentregistry-system`
- Version: 0.1.26

### Movies Application (Demo Workload)

**Purpose:**
Load testing application demonstrating service mesh traffic distribution and agent workload patterns.

**Architecture:**
```
Frontend (Fortio Load Generators):
  - frontend-central (500 QPS) ──┐
  - frontend-east (500 QPS)    ──┼─→ movieinfo Service (ClusterIP)
  - frontend-west (500 QPS)    ──┘           │
                                     ┌────────┼────────┐
                                     │        │        │
                              movieinfo-chi  -lax  -nyc
                              (central)    (west)  (east)
```

**Components:**
- 3 nginx backends (movieinfo-chi, movieinfo-lax, movieinfo-nyc)
- 3 Fortio load generators (1500 QPS total)
- HorizontalPodAutoscaler (1-3 replicas, 25% CPU threshold)
- Zone-aware affinity (central, west, east)

## Configuration

### Environment Variables (vars.sh)

| Variable | Default | Description |
|----------|---------|-------------|
| `NUM_CLUSTERS` | 1 | Number of k3d clusters |
| `CLUSTER_NAME_PREFIX` | `kagent-` | Prefix for cluster names |
| `KAGENT_VERSION` | 0.7.17 | Kagent version |
| `KGATEWAY_VERSION` | 2.2.1 | Kgateway version |
| `GATEWAY_API_VERSION` | v1.4.1 | Gateway API version |
| `ISTIO_VERSION` | 1.29.0 | Istio version |
| `AGENTGATEWAY_VERSION` | 0.12.0 | Agentgateway version |
| `AGENTREGISTRY_VERSION` | 0.1.26 | Agentregistry version |
| `OPENAI_API_KEY` | **Required** | OpenAI API key for Kagent |

### Port Mappings

| Cluster | HTTP Port | HTTPS Port | API Port |
|---------|-----------|------------|----------|
| kagent-01 | 7001 | 7401 | 7601 |

### Manifest Files

```
manifests/
├── istiod-values.yaml              # Istio control plane config (with mTLS)
├── istio-cni-values.yaml           # CNI plugin config (k3d optimized)
├── movies-waypoint.yaml            # Waypoint proxy for movies namespace
├── agentgateway-values.yaml        # Agentgateway config (MCP/A2A)
├── agentgateway-httproute.yaml     # HTTPRoute for agentgateway
├── agentregistry-values.yaml       # Agentregistry config
├── agentregistry-httproute.yaml    # HTTPRoute for agentregistry
├── http-listener.yaml              # Kgateway HTTP Gateway
├── kagent-httproute.yaml           # HTTPRoute for kagent
├── kagent-values.yaml              # Kagent Helm overrides
├── grafana-values.yaml             # Grafana config (optional)
├── grafana-ingress.yaml            # Grafana ingress (optional)
└── registries.yaml                 # Docker registry config
```

## Troubleshooting

### Istio Issues

**Pods not getting ambient mesh:**
```bash
# Check namespace labels
kubectl get ns movies --show-labels

# Verify ztunnel is running
kubectl get daemonset -n istio-system ztunnel

# Check pod logs
kubectl logs -n istio-system -l app=ztunnel
```

**Waypoint proxy not ready:**
```bash
# Check gateway status
kubectl get gateway -n movies waypoint -o yaml

# Verify waypoint pods
kubectl get pods -n movies -l istio.io/gateway-name=waypoint
```

### Kagent Issues

**Kagent pods not starting:**
```bash
# Check if OPENAI_API_KEY is set
kubectl get pods -n kagent
kubectl logs -n kagent deployment/kagent

# Verify CRDs are installed
kubectl get crds | grep kagent
```

### Kgateway Issues

**HTTPRoutes not working:**
```bash
# Check gateway status
kubectl get gateway -n kgateway-system http-gateway

# Verify HTTPRoutes
kubectl get httproute -A

# Check kgateway logs
kubectl logs -n kgateway-system deployment/kgateway
```

### Agentgateway/Agentregistry Issues

**Note:** The Helm chart locations for agentgateway and agentregistry may need verification. If installation fails:

```bash
# Check if namespaces exist
kubectl get ns agentgateway-system agentregistry-system

# Manual inspection
kubectl get all -n agentgateway-system
kubectl get all -n agentregistry-system

# Logs
kubectl logs -n agentgateway-system -l app=agentgateway
kubectl logs -n agentregistry-system -l app=agentregistry
```

If Helm charts are not available, consult the official documentation:
- Agentgateway: https://agentgateway.dev/docs/standalone/latest/
- Agentregistry: https://aregistry.ai/

### Network Issues

**Can't access services on localhost:7001:**
```bash
# Check k3d cluster port mappings
k3d cluster list

# Verify kgateway service
kubectl get svc -n kgateway-system

# Test with port-forward as fallback
kubectl port-forward -n kagent svc/kagent 8080:80
```

## Advanced Usage

### Testing mTLS

Verify mutual TLS is working between services:

```bash
# Exec into a frontend pod
kubectl exec -n movies deploy/frontend-central -- sh

# Test connection (should work with mTLS)
curl -v http://movieinfo.movies.svc.cluster.local/index.html
```

### Viewing Istio Configuration

```bash
# Check mesh config
kubectl get configmap -n istio-system istio -o yaml

# View ztunnel configuration
kubectl exec -n istio-system ds/ztunnel -- cat /var/lib/istio/envoy/envoy.yaml
```

### Agent-to-Agent Communication

Example using agentgateway (assuming service is running):

```bash
# Test MCP endpoint
curl -H "Host: agentgateway.local" http://localhost:7001/v1/mcp

# Test A2A protocol
curl -H "Host: agentgateway.local" http://localhost:7001/v1/agents
```

### Agent Discovery

Example using agentregistry (assuming service is running):

```bash
# List registered agents
curl -H "Host: agentregistry.local" http://localhost:7001/v1/agents

# Register an agent (POST)
curl -X POST -H "Host: agentregistry.local" \
  -H "Content-Type: application/json" \
  -d '{"name":"my-agent","type":"openai"}' \
  http://localhost:7001/v1/agents
```

## What's Next?

- Add Grafana/Prometheus for observability
- Configure locality load balancing for multi-zone traffic distribution
- Integrate Kagent with Agentregistry for automatic agent registration
- Set up agent-to-agent communication via Agentgateway
- Deploy custom AI agents using Kagent CRDs
- Implement advanced traffic policies with Istio waypoint proxies

## Summary

The `ai-sandbox` provides a complete, production-like environment for developing and testing AI agent applications with:

- ✅ Service mesh security (Istio Ambient with mTLS)
- ✅ AI agent lifecycle management (Kagent)
- ✅ API gateway (Kgateway)
- ✅ Agent-to-agent communication (Agentgateway)
- ✅ Agent discovery and governance (Agentregistry)
- ✅ Demo application for load testing (Movies app)
- ✅ Full observability and telemetry

All running locally on k3d with a single command!
