# istio-envoy-sandboxes

**Comprehensive Collection of Service Mesh, API Gateway, and AI Agent Testing Environments**

Tom Dean
Last edit: 2/23/2026

## Overview

This repository provides production-ready sandbox environments for testing and learning about service meshes (Istio, Gloo Mesh), API gateways (Kgateway, Gloo Gateway, Gloo Edge), and AI agent frameworks (Kagent, Agentgateway, Agentregistry). All sandboxes are designed for rapid deployment, repeatable testing, and hands-on exploration of cloud-native technologies.

The sandboxes support multiple deployment targets:
- **Local k3d clusters** - Fastest iteration for development and testing
- **Local kind clusters** - Alternative local Kubernetes environment
- **AWS EKS** - Production-like cloud deployments
- **Azure AKS** - Azure cloud environments (coming soon)
- **GCP GKE** - Google Cloud environments (coming soon)

## Repository Structure

```
istio-envoy-sandboxes/
├── k3d-sandboxes/          # Local k3d-based testing environments
├── kind-sandboxes/         # Alternative local Kubernetes sandboxes
├── AWS/                    # AWS EKS deployment sandboxes
├── Azure/                  # Azure AKS sandboxes
├── GCP/                    # GCP GKE sandboxes
├── apps/                   # Shared demo applications
│   └── movies-app/         # Load testing application
└── scripts/                # Shared utility scripts
```

## Quick Start

### Prerequisites

All sandboxes require these common tools:
- [Docker](https://www.docker.com/get-started/) - Container runtime
- [kubectl](https://kubernetes.io/docs/tasks/tools/) - Kubernetes CLI
- [kubectx](https://github.com/ahmetb/kubectx) - Context switching utility
- [Helm](https://helm.sh/) - Kubernetes package manager
- `bash` shell

**For local k3d sandboxes**, additionally install:
- [k3d](https://k3d.io/) - Lightweight Kubernetes in Docker

**For local kind sandboxes**, additionally install:
- [kind](https://kind.sigs.k8s.io/) - Kubernetes in Docker

**For cloud sandboxes**, see individual cloud directories for specific CLI requirements.

### Usage Pattern

Each sandbox follows a consistent pattern:

```bash
# 1. Navigate to the sandbox directory
cd k3d-sandboxes/<sandbox-name>

# 2. Configure environment variables
vi vars.sh  # Set API keys, licenses, etc.

# 3. Deploy the full stack
./scripts/cluster-setup-k3d-*-everything.sh

# 4. Verify deployment
kubectl get pods -A

# 5. Access services (see individual README)
# Most sandboxes expose services on localhost

# 6. Clean up when finished
./scripts/cluster-destroy-k3d.sh
```

## k3d Sandboxes

Local Kubernetes sandboxes using k3d for rapid iteration and testing.

### ai-sandbox
**Comprehensive AI Agent Platform**

The most complete AI agent testing environment, combining service mesh, API gateway, agent gateway, and agent discovery.

**Technology Stack:**
- Istio 1.29.0 (Ambient Mode with mTLS)
- Kagent 0.7.17 (AI agent framework)
- Kgateway 2.2.1 (API gateway)
- Agentgateway 0.12.0 (agent-to-agent gateway)
- Agentregistry 0.1.26 (agent discovery)
- Gateway API v1.4.1

**Use Cases:**
- AI agent development and testing
- Agent-to-agent communication patterns
- Service mesh integration with AI workloads
- Agent discovery and governance
- Production-like AI infrastructure testing

**Quick Start:**
```bash
cd k3d-sandboxes/ai-sandbox
vi vars.sh  # Set OPENAI_API_KEY
./scripts/cluster-setup-k3d-ai-everything.sh
# Access: http://localhost:7001
```

[Full Documentation](k3d-sandboxes/ai-sandbox/README.md)

---

### istio-llb-sandbox
**Istio Locality Load Balancing**

Testing environment for Istio's locality-aware load balancing features, supporting both sidecar and ambient modes.

**Technology Stack:**
- Istio OSS (sidecar and ambient mode)
- Kiali (service mesh observability)
- Grafana (metrics visualization)
- Prometheus (metrics collection)
- Movies app (multi-zone load testing)

**Use Cases:**
- Locality load balancing testing
- Multi-zone traffic distribution
- Istio ambient vs sidecar comparison
- Service mesh observability
- mTLS and security policies

**Quick Start:**
```bash
cd k3d-sandboxes/istio-llb-sandbox
./scripts/cluster-setup-k3d-amb-everything.sh  # Ambient mode
# OR
./scripts/cluster-setup-k3d-sc-everything.sh   # Sidecar mode
# Access Kiali: http://localhost:9001/kiali
# Access Grafana: http://localhost:9001/grafana
```

[Full Documentation](k3d-sandboxes/istio-llb-sandbox/README.md)

---

### istio-sandbox
**Basic Istio OSS Environment**

Lightweight Istio sandbox for learning and testing core service mesh features.

**Technology Stack:**
- Istio OSS
- Demo workloads

**Use Cases:**
- Learning Istio basics
- Testing service mesh policies
- Traffic management experimentation
- Security policy validation

**Quick Start:**
```bash
cd k3d-sandboxes/istio-sandbox
./scripts/cluster-setup-k3d-istio-everything.sh
```

[Full Documentation](k3d-sandboxes/istio-sandbox/README.md)

---

### gme-llb-sandbox
**Gloo Mesh Enterprise Locality Load Balancing**

Enterprise service mesh testing with Gloo Mesh, supporting multi-cluster deployments and advanced traffic management.

**Technology Stack:**
- Gloo Mesh Enterprise
- Istio (via Gloo Mesh)
- Multi-cluster support
- Movies app (multi-zone testing)

**Use Cases:**
- Enterprise multi-cluster service mesh
- Advanced traffic policies
- Cross-cluster communication
- Locality-aware load balancing
- Enterprise security features

**Quick Start:**
```bash
cd k3d-sandboxes/gme-llb-sandbox
vi vars.sh  # Set LICENSE_KEY
./scripts/cluster-setup-k3d-gme-everything.sh
```

[Full Documentation](k3d-sandboxes/gme-llb-sandbox/README.md)

---

### kgateway-sandbox
**Kgateway API Gateway**

Testing environment for Kgateway (formerly Gloo Gateway OSS), implementing the Kubernetes Gateway API specification.

**Technology Stack:**
- Kgateway (Gateway API implementation)
- Gateway API CRDs
- Demo applications

**Use Cases:**
- Gateway API learning and testing
- Cloud-native ingress patterns
- HTTP routing and traffic splitting
- Rate limiting and authentication
- AI gateway capabilities

**Quick Start:**
```bash
cd k3d-sandboxes/kgateway-sandbox
./scripts/cluster-setup-k3d-gg-everything.sh
```

[Full Documentation](k3d-sandboxes/kgateway-sandbox/README.md)

---

### gloo-gw-sandbox
**Gloo Gateway 2.x**

Latest version of Solo.io's Gloo Gateway for advanced API gateway use cases.

**Technology Stack:**
- Gloo Gateway v2
- Gateway API integration
- Advanced routing capabilities

**Use Cases:**
- Modern API gateway patterns
- GraphQL federation
- Advanced authentication/authorization
- Rate limiting and caching
- AI gateway features

**Quick Start:**
```bash
cd k3d-sandboxes/gloo-gw-sandbox
vi vars.sh  # Set LICENSE_KEY
./scripts/cluster-setup-k3d-gg-everything.sh
```

[Full Documentation](k3d-sandboxes/gloo-gw-sandbox/README.md)

---

### glooe-gw-sandbox
**Gloo Edge Gateway**

Enterprise API gateway with Envoy-based data plane.

**Technology Stack:**
- Gloo Edge Gateway
- Envoy proxy
- Enterprise features

**Use Cases:**
- Enterprise API management
- Legacy application integration
- Hybrid cloud gateways
- Advanced transformation policies

**Quick Start:**
```bash
cd k3d-sandboxes/glooe-gw-sandbox
vi vars.sh  # Set LICENSE_KEY
./scripts/cluster-setup-k3d-gg-everything.sh
```

[Full Documentation](k3d-sandboxes/glooe-gw-sandbox/README.md)

---

### ge-llb-sandbox
**Gloo Edge Locality Load Balancing**

Gloo Edge testing with locality-aware routing and multi-zone deployments.

**Technology Stack:**
- Gloo Edge
- Multi-zone configuration
- Load testing applications

**Use Cases:**
- Gloo Edge locality features
- Multi-region API gateways
- Zone-aware traffic distribution

**Quick Start:**
```bash
cd k3d-sandboxes/ge-llb-sandbox
vi vars.sh  # Set LICENSE_KEY
./scripts/cluster-setup-k3d-gg-everything.sh
```

[Full Documentation](k3d-sandboxes/ge-llb-sandbox/README.md)

---

### kagent-sandbox
**Kagent AI Agent Framework**

Dedicated environment for testing Kagent, the CNCF AI agent framework for Kubernetes.

**Technology Stack:**
- Kagent (AI agent framework)
- Kgateway (ingress)
- OpenAI integration

**Use Cases:**
- AI agent development
- Kubernetes-native agent deployment
- Multi-LLM provider testing
- Agent lifecycle management
- MCP server integration

**Quick Start:**
```bash
cd k3d-sandboxes/kagent-sandbox
vi vars.sh  # Set OPENAI_API_KEY
./scripts/cluster-setup-k3d-kagent-everything.sh
# Access: http://localhost:7001
```

[Full Documentation](k3d-sandboxes/kagent-sandbox/README.md)

---

## Cloud Sandboxes

### AWS

#### eks-spiffe-spire-istio-sandbox
**EKS with SPIRE Identity and Istio Ambient**

Production-grade AWS deployment combining SPIFFE/SPIRE workload identity with Istio Ambient mode.

**Technology Stack:**
- AWS EKS (managed Kubernetes)
- SPIRE (workload identity)
- Istio Ambient (Solo.io distribution)
- Kgateway (ingress)
- Prometheus + Grafana (observability)
- Movies app (load testing)

**Architecture Highlights:**
- SPIRE provides cryptographic workload identities (SPIFFE IDs)
- Ztunnel uses SPIRE DelegatedIdentity API for certificate management
- Trust domain: `example.org`
- Sidecar-less service mesh with automatic mTLS

**Use Cases:**
- Production SPIFFE/SPIRE integration
- Zero-trust architecture on AWS
- Istio Ambient in cloud environments
- Enterprise security requirements
- Cloud-native identity management

**Prerequisites:**
- AWS CLI configured with appropriate credentials
- eksctl
- Helm
- kubectl, kubectx
- envsubst (GNU gettext)

**Quick Start:**
```bash
cd AWS/eks-spiffe-spire-istio-sandbox
vi vars.sh  # Configure AWS profile, region, license keys
./scripts/cluster-setup-eks-everything.sh
# Teardown: ./scripts/cluster-destroy-eks.sh
```

[Full Documentation](AWS/eks-spiffe-spire-istio-sandbox/README.md)

---

### Azure
Azure AKS sandboxes (coming soon)

### GCP
GCP GKE sandboxes (coming soon)

---

## Shared Applications

### movies-app
**Multi-Zone Load Testing Application**

Demo application used across multiple sandboxes for testing traffic distribution, locality load balancing, and service mesh features.

**Architecture:**
- 3 nginx backends (movieinfo-chi, movieinfo-lax, movieinfo-nyc)
- 3 Fortio load generators (frontend-central, frontend-east, frontend-west)
- Zone-aware affinity (central, west, east regions)
- HorizontalPodAutoscaler support
- Generates 1500 QPS total traffic

**Use Cases:**
- Locality load balancing validation
- Service mesh traffic observation
- Multi-zone deployment testing
- Load testing service mesh performance
- Observability dashboard population

**Deployment:**
```bash
kubectl apply -k apps/movies-app
```

[Full Documentation](apps/movies-app/README.md)

---

## Common Patterns

### Configuration Files

All sandboxes use a consistent `vars.sh` file for environment configuration:

```bash
# Cluster configuration
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
- `cluster-setup-eks-everything.sh` - AWS EKS deployment
- `cluster-destroy-eks.sh` - AWS teardown

### Port Mappings

Most local sandboxes expose services on `localhost` with predictable port patterns:

| Service | Port | Access |
|---------|------|--------|
| Kagent UI | 7001 | http://localhost:7001 |
| Kiali | 9001 | http://localhost:9001/kiali |
| Grafana | 9001 | http://localhost:9001/grafana |
| Kgateway HTTP | 7001, 8001, 9001 | http://localhost:port |
| Kgateway HTTPS | 7401, 8401, 9401 | https://localhost:port |

### Manifest Organization

Each sandbox organizes configuration in a `manifests/` directory:

```
manifests/
├── *-values.yaml        # Helm chart values
├── *-httproute.yaml     # Gateway API routing
├── *-waypoint.yaml      # Istio waypoint proxies
├── *-ingress.yaml       # Ingress resources
└── registries.yaml      # Docker registry config
```

---

## Technology Index

Quick reference for finding sandboxes by technology:

### Service Mesh
- **Istio OSS Ambient**: ai-sandbox, istio-llb-sandbox, eks-spiffe-spire-istio-sandbox
- **Istio OSS Sidecar**: istio-llb-sandbox, istio-sandbox
- **Gloo Mesh Enterprise**: gme-llb-sandbox

### API Gateway
- **Kgateway (OSS)**: ai-sandbox, kgateway-sandbox, kagent-sandbox, eks-spiffe-spire-istio-sandbox
- **Gloo Gateway v2**: gloo-gw-sandbox
- **Gloo Edge**: glooe-gw-sandbox, ge-llb-sandbox

### AI & Agents
- **Kagent**: ai-sandbox, kagent-sandbox
- **Agentgateway**: ai-sandbox
- **Agentregistry**: ai-sandbox

### Identity & Security
- **SPIFFE/SPIRE**: eks-spiffe-spire-istio-sandbox
- **mTLS**: ai-sandbox, istio-llb-sandbox, gme-llb-sandbox, eks-spiffe-spire-istio-sandbox

### Observability
- **Kiali**: istio-llb-sandbox
- **Grafana**: istio-llb-sandbox, eks-spiffe-spire-istio-sandbox
- **Prometheus**: istio-llb-sandbox, eks-spiffe-spire-istio-sandbox

### Locality Features
- **Istio Locality LB**: istio-llb-sandbox
- **Gloo Mesh Locality LB**: gme-llb-sandbox
- **Gloo Edge Locality LB**: ge-llb-sandbox

### Cloud Platforms
- **AWS EKS**: eks-spiffe-spire-istio-sandbox
- **Azure AKS**: Coming soon
- **GCP GKE**: Coming soon

---

## Version Information

This repository is actively maintained with the latest stable versions:

| Component | Version | Updated |
|-----------|---------|---------|
| Istio | 1.29.0 | Feb 2026 |
| Kagent | 0.7.17 | Feb 2026 |
| Kgateway | 2.2.1 | Feb 2026 |
| Gateway API | v1.4.1 | Feb 2026 |
| Agentgateway | 0.12.0 | Feb 2026 |
| Agentregistry | 0.1.26 | Feb 2026 |

---

## Contributing

This is a personal learning and testing repository. Feel free to fork and adapt for your own use.

---

## License

MIT License - See individual sandboxes for third-party component licenses.

---

## Support

For questions about:
- **Istio**: [Istio Documentation](https://istio.io/)
- **Kagent**: [Kagent GitHub](https://github.com/kagent-dev/kagent)
- **Kgateway**: [Kgateway Documentation](https://docs.kgateway.dev/)
- **Solo.io Products**: [Solo.io Documentation](https://docs.solo.io/)
- **SPIFFE/SPIRE**: [SPIFFE Documentation](https://spiffe.io/)

---

## Acknowledgments

Built with technologies from:
- [CNCF](https://www.cncf.io/) - Kubernetes, Istio, Gateway API
- [Solo.io](https://www.solo.io/) - Gloo Mesh, Gloo Gateway, Kgateway
- [Kagent Community](https://github.com/kagent-dev) - AI agent framework
- [Agentgateway](https://agentgateway.dev/) - Agent connectivity
- [SPIFFE/SPIRE](https://spiffe.io/) - Workload identity

---

**Tom Dean**
Last updated: February 23, 2026
