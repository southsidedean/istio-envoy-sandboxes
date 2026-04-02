# ent-ai-sandbox

**Enterprise AI Agent Platform**

Tom Dean
Last edit: 3/27/2026

## Introduction

The `ent-ai-sandbox` is a complete enterprise AI agent testing platform that combines Solo.io's commercial service mesh, API gateway, agent gateway, and agent discovery capabilities in a local k3d environment. Unlike the OSS `ai-sandbox`, this sandbox uses Solo enterprise distributions for Istio, Kagent, Kgateway, and Agentgateway, providing production-grade features, support, and licensing. Agentregistry remains OSS.

### Technology Stack

- **Solo Istio Distribution 1.29.1** (Ambient Mode) - Enterprise Istio with mTLS, distributed from OCI Helm charts at `us-docker.pkg.dev/soloio-img/istio-helm`
- **Solo Enterprise for Kagent 0.3.12** - Enterprise AI agent framework from `oci://us-docker.pkg.dev/solo-public/kagent-enterprise-helm/charts/`
- **Solo Enterprise for Kgateway 2.1.4** - Enterprise API gateway from `oci://us-docker.pkg.dev/solo-public/enterprise-kgateway/charts/`
- **Solo Enterprise for Agentgateway 2.1.1** - Enterprise agent-to-agent gateway from `oci://us-docker.pkg.dev/solo-public/enterprise-agentgateway/charts/`
- **Agentregistry 0.3.2** (OSS) - Centralized agent discovery and governance platform
- **Gateway API v1.5.1** - Kubernetes-native ingress/gateway specification

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

### Required Credentials

This sandbox requires three credentials set in `vars.sh` before deployment:

| Credential | Variable | Purpose |
|------------|----------|---------|
| OpenAI API Key | `OPENAI_API_KEY` | LLM provider for Kagent agents |
| Solo License Key | `LICENSE_KEY` | Solo Enterprise for Kgateway |
| Agentgateway License Key | `AGENTGATEWAY_LICENSE_KEY` | Solo Enterprise for Agentgateway |

## Quick Start

### 1. Configure Environment

Edit `vars.sh` and set your credentials:

```bash
vi vars.sh  # Set OPENAI_API_KEY, LICENSE_KEY, and AGENTGATEWAY_LICENSE_KEY
```

### 2. Deploy the Complete Stack

```bash
./scripts/cluster-setup-k3d-ent-ai-everything.sh
```

This script will install (in order):
1. k3d cluster with custom networking
2. Solo Istio Distribution Ambient Mode (base, istiod, CNI, ztunnel) via OCI Helm charts
3. Solo Enterprise for Kagent (CRDs + agent framework)
4. Movies demo application
5. Istio ambient mode labeling and waypoint proxies
6. Gateway API CRDs
7. Solo Enterprise for Kgateway (CRDs + API gateway)
8. Solo Enterprise for Agentgateway (CRDs + agent-to-agent gateway)
9. Agentregistry OSS for agent discovery

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

- **Kagent UI**: http://localhost:6001
- **Agentgateway**: http://localhost:6001 (with `Host: agentgateway.local` header)
- **Agentregistry**: http://localhost:6001 (with `Host: agentregistry.local` header)

Example with curl:
```bash
# Access Kagent
curl http://localhost:6001

# Access Agentgateway
curl -H "Host: agentgateway.local" http://localhost:6001

# Access Agentregistry
curl -H "Host: agentregistry.local" http://localhost:6001
```

### 5. Tear Down

```bash
./scripts/cluster-destroy-k3d.sh
```

## Deployment Options

### Full Enterprise AI Platform (Recommended)

```bash
./scripts/cluster-setup-k3d-ent-ai-everything.sh
```

Deploys the complete enterprise stack with Solo Istio, Enterprise Kagent, Enterprise Kgateway, Enterprise Agentgateway, Agentregistry OSS, and the movies application.

### Bare Cluster Only

```bash
./scripts/cluster-setup-k3d-naked.sh
```

Creates a clean k3d cluster without any components. Useful for manual installation and experimentation.

## Architecture

### Component Overview

```
+-------------------------------------------------------------+
|            Enterprise Kgateway (API Gateway)                 |
|          GatewayClass: enterprise-kgateway                   |
|          +--------------------------------------+            |
|          |        HTTP Gateway (port 80)         |            |
|          +-------------------+------------------+            |
+------------------------------+-------------------------------+
                               |
         +---------------------+---------------------+
         |                     |                     |
    +----v-----+    +----------v--------+  +---------v---------+
    |  Kagent  |    | Ent Agentgateway  |  |   Agentregistry   |
    |  (6001)  |    |    (MCP/A2A)      |  |   (Discovery)     |
    +----+-----+    +----------+--------+  +---------+---------+
         |                     |                     |
         |         Istio Ambient Mesh (mTLS)         |
         |    +----------------+------------------+  |
         +----+       ztunnel DaemonSet           +--+
              |   (L4 proxy on each node)         |
              +----------------+------------------+
                               |
                      +--------v--------+
                      |   Movies App    |
                      |  (Load Testing) |
                      +-----------------+
```

### Solo Istio Distribution (Ambient Mode)

**What is it?**
The Solo Istio Distribution is an enterprise build of Istio maintained by Solo.io. It provides the same ambient mesh architecture as upstream Istio -- a sidecar-less service mesh using a per-node Layer 4 proxy (ztunnel) and optional Layer 7 waypoint proxies -- with enterprise support, CVE patches, and FIPS compliance.

**Helm Chart Source:**
Solo Istio uses OCI Helm charts distributed from `us-docker.pkg.dev/soloio-img/istio-helm`. Images are pulled from `us-docker.pkg.dev/soloio-img/istio` with the `${ISTIO_VERSION}-solo` tag.

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
- Enterprise support and CVE patching from Solo.io

**Enabled Namespaces:**
- `movies` - Demo application
- `kagent` - AI agent framework
- `agentgateway-system` - Agent-to-agent gateway

### Solo Enterprise for Kagent (AI Agent Framework)

**What is it?**
Solo Enterprise for Kagent is the enterprise distribution of the Kagent AI agent framework. It extends the open-source Kagent with enterprise features, support, and governance.

**Helm Chart Source:**
Enterprise Kagent uses OCI Helm charts from `oci://us-docker.pkg.dev/solo-public/kagent-enterprise-helm/charts/`. Two charts are installed: `kagent-enterprise-crds` for CRDs and `kagent-enterprise` for the runtime.

**Features:**
- Agent lifecycle management via Kubernetes CRDs
- Multi-LLM provider support (OpenAI, Azure, Anthropic, Ollama, etc.)
- Built-in MCP (Model Context Protocol) server with Kubernetes tools
- OpenTelemetry tracing for agent observability
- Web UI for agent management
- Enterprise governance and support

**Access:**
- UI: http://localhost:6001
- Namespace: `kagent`
- Version: 0.3.12

### Solo Enterprise for Kgateway (API Gateway)

**What is it?**
Solo Enterprise for Kgateway is the enterprise distribution of the Kgateway API gateway. It implements the Kubernetes Gateway API specification with additional enterprise features like advanced rate limiting, authentication, and licensing.

**Helm Chart Source:**
Enterprise Kgateway uses OCI Helm charts from `oci://us-docker.pkg.dev/solo-public/enterprise-kgateway/charts/`. Two charts are installed: `enterprise-kgateway-crds` for CRDs and `enterprise-kgateway` for the runtime.

**Configuration:**
- GatewayClass: `enterprise-kgateway`
- HTTPRoutes define routing rules
- Gateway resource (`http-gateway`) listens on port 80
- Routes traffic to backend services based on Host headers
- Requires `LICENSE_KEY` for activation

**Access:**
- Gateway: http://localhost:6001
- Namespace: `kgateway-system`
- Version: 2.1.4

### Solo Enterprise for Agentgateway (Agent-to-Agent Gateway)

**What is it?**
Solo Enterprise for Agentgateway is the enterprise distribution of the Agentgateway data plane, optimized for agentic AI connectivity.

**Helm Chart Source:**
Enterprise Agentgateway uses OCI Helm charts from `oci://us-docker.pkg.dev/solo-public/enterprise-agentgateway/charts/`. Two charts are installed: `enterprise-agentgateway-crds` for CRDs and `enterprise-agentgateway` for the runtime.

**Features:**
- MCP (Model Context Protocol) multiplexing
- A2A (Agent-to-Agent) protocol support
- Drop-in security, observability, and governance
- OpenTelemetry integration
- Enterprise licensing and support
- Requires `AGENTGATEWAY_LICENSE_KEY` for activation

**Access:**
- API: http://localhost:6001 (Host: agentgateway.local)
- Namespace: `agentgateway-system`
- Version: 2.1.1

### Agentregistry (Agent Discovery - OSS)

**What is it?**
Agentregistry provides centralized governance and control for AI artifacts and infrastructure. This component remains OSS in the enterprise sandbox.

**Features:**
- Centralized registry for MCP servers, agents, and skills
- Automatic validation and scoring
- Governance and access control
- Kubernetes CRD-based storage
- Integration with agentgateway and kagent

**Access:**
- API: http://localhost:6001 (Host: agentregistry.local)
- Namespace: `agentregistry-system`
- Version: 0.3.2

### Movies Application (Demo Workload)

**Purpose:**
Load testing application demonstrating service mesh traffic distribution and agent workload patterns.

**Architecture:**
```
Frontend (Fortio Load Generators):
  - frontend-central (500 QPS) --+
  - frontend-east (500 QPS)    --+--> movieinfo Service (ClusterIP)
  - frontend-west (500 QPS)    --+           |
                                     +-------+--------+
                                     |       |        |
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
| `CLUSTER_NAME_PREFIX` | `ent-ai-` | Prefix for cluster names |
| `K3S_VERSION` | v1.35.2-k3s1 | k3s Kubernetes version |
| `ISTIO_VERSION` | 1.29.1 | Solo Istio Distribution version |
| `KAGENT_ENT_VERSION` | 0.3.12 | Solo Enterprise for Kagent version |
| `ENT_KGATEWAY_VERSION` | 2.1.4 | Solo Enterprise for Kgateway version |
| `ENT_AGENTGATEWAY_VERSION` | 2.1.1 | Solo Enterprise for Agentgateway version |
| `AGENTREGISTRY_VERSION` | 0.3.2 | Agentregistry OSS version |
| `GATEWAY_API_VERSION` | v1.5.1 | Gateway API version |
| `OPENAI_API_KEY` | **Required** | OpenAI API key for Kagent |
| `LICENSE_KEY` | **Required** | Solo Enterprise for Kgateway license |
| `AGENTGATEWAY_LICENSE_KEY` | **Required** | Solo Enterprise for Agentgateway license |

### Port Mappings

| Cluster | HTTP Port | HTTPS Port | API Port |
|---------|-----------|------------|----------|
| ent-ai-01 | 6001 | 6401 | 6801 |

### Manifest Files

```
manifests/
+-- istiod-values.yaml              # Istio control plane config (with mTLS)
+-- istio-cni-values.yaml           # CNI plugin config (k3d optimized)
+-- movies-waypoint.yaml            # Waypoint proxy for movies namespace
+-- agentgateway-values.yaml        # Enterprise Agentgateway config (MCP/A2A)
+-- agentgateway-httproute.yaml     # HTTPRoute for agentgateway
+-- agentregistry-values.yaml       # Agentregistry config
+-- agentregistry-httproute.yaml    # HTTPRoute for agentregistry
+-- http-listener.yaml              # Enterprise Kgateway HTTP Gateway
+-- kagent-httproute.yaml           # HTTPRoute for kagent
+-- registries.yaml                 # Docker registry config
```

## Use Cases

### Enterprise AI Agent Development
Deploy and test AI agents in a production-like environment with enterprise-grade security, observability, and governance. Solo enterprise distributions provide CVE patching, FIPS compliance, and commercial support.

### Agent-to-Agent Communication
Use Enterprise Agentgateway to establish secure MCP and A2A protocol connections between agents, with enterprise licensing and governance controls.

### Service Mesh Security Testing
Validate mTLS enforcement and traffic policies across AI agent workloads using the Solo Istio Distribution with ambient mode.

### Gateway API with Enterprise Features
Test advanced API gateway patterns using Enterprise Kgateway's `enterprise-kgateway` GatewayClass, including rate limiting, authentication, and licensed features.

### Agent Discovery and Governance
Use Agentregistry to catalog, validate, and govern AI agents, MCP servers, and skills across the platform.

## Troubleshooting

### Solo Istio Issues

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

### Enterprise Kagent Issues

**Kagent pods not starting:**
```bash
# Check if OPENAI_API_KEY is set
kubectl get pods -n kagent
kubectl logs -n kagent deployment/kagent

# Verify CRDs are installed
kubectl get crds | grep kagent
```

### Enterprise Kgateway Issues

**HTTPRoutes not working:**
```bash
# Check gateway status
kubectl get gateway -n kgateway-system http-gateway

# Verify GatewayClass
kubectl get gatewayclass enterprise-kgateway

# Verify HTTPRoutes
kubectl get httproute -A

# Check enterprise kgateway logs
kubectl logs -n kgateway-system deployment/enterprise-kgateway
```

**License key issues:**
```bash
# Verify license key is set in vars.sh
echo $LICENSE_KEY

# Check for license-related errors
kubectl logs -n kgateway-system deployment/enterprise-kgateway | grep -i license
```

### Enterprise Agentgateway Issues

**Agentgateway pods not starting:**
```bash
# Check namespace and pods
kubectl get ns agentgateway-system
kubectl get all -n agentgateway-system

# Check logs for license errors
kubectl logs -n agentgateway-system -l app=agentgateway

# Verify license key
echo $AGENTGATEWAY_LICENSE_KEY
```

### Agentregistry Issues

**Agentregistry pods not ready:**
```bash
# Check namespace exists
kubectl get ns agentregistry-system

# Manual inspection
kubectl get all -n agentregistry-system

# Logs
kubectl logs -n agentregistry-system -l app=agentregistry
```

### Network Issues

**Can't access services on localhost:6001:**
```bash
# Check k3d cluster port mappings
k3d cluster list

# Verify enterprise kgateway service
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

Example using Enterprise Agentgateway:

```bash
# Test MCP endpoint
curl -H "Host: agentgateway.local" http://localhost:6001/v1/mcp

# Test A2A protocol
curl -H "Host: agentgateway.local" http://localhost:6001/v1/agents
```

### Agent Discovery

Example using Agentregistry:

```bash
# List registered agents
curl -H "Host: agentregistry.local" http://localhost:6001/v1/agents

# Register an agent (POST)
curl -X POST -H "Host: agentregistry.local" \
  -H "Content-Type: application/json" \
  -d '{"name":"my-agent","type":"openai"}' \
  http://localhost:6001/v1/agents
```

## OSS vs Enterprise Comparison

| Component | OSS Sandbox (`ai-sandbox`) | Enterprise Sandbox (`ent-ai-sandbox`) |
|-----------|---------------------------|--------------------------------------|
| Istio | Istio OSS 1.29.1 | Solo Istio Distribution 1.29.1 |
| Kagent | Kagent OSS 0.8.1 | Solo Enterprise for Kagent 0.3.12 |
| Kgateway | Kgateway OSS 2.2.2 | Solo Enterprise for Kgateway 2.1.4 |
| Agentgateway | Agentgateway OSS 1.0.1 | Solo Enterprise for Agentgateway 2.1.1 |
| Agentregistry | Agentregistry OSS 0.3.2 | Agentregistry OSS 0.3.2 |
| GatewayClass | `kgateway` | `enterprise-kgateway` |
| License Keys | None (OPENAI_API_KEY only) | LICENSE_KEY + AGENTGATEWAY_LICENSE_KEY + OPENAI_API_KEY |
| Helm Sources | Public Helm repos | Solo OCI registries |

## What's Next?

- Add Grafana/Prometheus for observability
- Configure locality load balancing for multi-zone traffic distribution
- Integrate Enterprise Kagent with Agentregistry for automatic agent registration
- Set up agent-to-agent communication via Enterprise Agentgateway
- Deploy custom AI agents using Kagent CRDs
- Implement advanced traffic policies with Istio waypoint proxies
- Explore enterprise-specific features like FIPS compliance and advanced governance

## Summary

The `ent-ai-sandbox` provides a complete, enterprise-grade environment for developing and testing AI agent applications with:

- Solo Istio Distribution for service mesh security (Ambient Mode with mTLS)
- Solo Enterprise for Kagent for AI agent lifecycle management
- Solo Enterprise for Kgateway as the API gateway (GatewayClass: enterprise-kgateway)
- Solo Enterprise for Agentgateway for agent-to-agent communication
- Agentregistry OSS for agent discovery and governance
- Demo application for load testing (Movies app)
- Full observability and telemetry

All running locally on k3d with a single command!
