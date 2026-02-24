# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

Collection of self-contained sandbox environments for testing service meshes (Istio, Gloo Mesh), API gateways (Kgateway, Gloo Gateway, Gloo Edge), and AI agent frameworks (Kagent, Agentgateway, Agentregistry). Each sandbox is fully independent with its own scripts, manifests, and configuration.

## Repository Layout

- `k3d-sandboxes/` — 9 local sandboxes using k3d (Kubernetes via k3s in Docker)
  - `ai-sandbox/` — Full AI platform: Istio Ambient + Kagent + Kgateway + Agentgateway + Agentregistry
  - `istio-llb-sandbox/` — Istio locality load balancing (ambient & sidecar modes)
  - `istio-sandbox/` — Basic Istio OSS
  - `gme-llb-sandbox/` — Gloo Mesh Enterprise with locality LB (requires LICENSE_KEY)
  - `kagent-sandbox/` — Dedicated Kagent AI framework
  - `kgateway-sandbox/` — OSS Gateway API implementation
  - `gloo-gw-sandbox/` — Gloo Gateway v2
  - `glooe-gw-sandbox/` — Gloo Edge Gateway
  - `ge-llb-sandbox/` — Gloo Edge with locality LB
- `AWS/eks-spiffe-spire-istio-sandbox/` — Production AWS EKS with SPIRE + Istio Ambient (has its own CLAUDE.md)
- `apps/movies-app/` — Shared multi-zone load testing application (Fortio frontends + Nginx backends, 1500 QPS across 3 zones)
- `scripts/yaml-collector.sh` — Utility to collect Kubernetes manifests for debugging

## Sandbox Structure Convention

Every sandbox follows the same internal layout:

```
<sandbox>/
├── vars.sh                              # Environment variables (versions, names, credentials)
├── scripts/
│   ├── cluster-setup-k3d-*-everything.sh  # Full stack deployment
│   ├── cluster-setup-k3d-naked.sh         # Bare cluster only
│   └── cluster-destroy-k3d.sh             # Teardown
├── manifests/                           # Helm values and Kubernetes YAML
├── cluster-k3d/                         # k3d cluster configs (tiny/small/medium/large)
└── README.md
```

**To use any sandbox**: `cd` into it, edit `vars.sh` with credentials, then run the desired setup script.

## Common Commands

```bash
# All sandboxes require sourcing vars.sh first (setup scripts do this automatically)
source vars.sh

# Deploy full stack (script name varies by sandbox)
./scripts/cluster-setup-k3d-<variant>-everything.sh

# Deploy bare cluster only
./scripts/cluster-setup-k3d-naked.sh

# Destroy cluster
./scripts/cluster-destroy-k3d.sh

# Deploy movies app (from within a sandbox that uses it)
kubectl apply -k ../apps/movies-app/single-cluster/
```

## Architecture Patterns

### Deployment Stack Order
Scripts install components in this order: cluster infrastructure → Gateway API CRDs → service mesh (Istio base → istiod → CNI → ztunnel) → API gateway → AI frameworks → demo apps → observability

### k3d Cluster Topology
Each cluster creates 1 server + 3 agent nodes with zone labels:
- `agent:0` → `topology.kubernetes.io/zone=central`
- `agent:1` → `topology.kubernetes.io/zone=west`
- `agent:2` → `topology.kubernetes.io/zone=east`

### Port Mapping Convention
k3d sandboxes use port ranges by cluster number: HTTP `70XX`, HTTPS `74XX`, API `76XX` where XX is the cluster number (01, 02, 03).

### Istio Ambient Mode
Most sandboxes use sidecar-less ambient mode: ztunnel DaemonSet handles L4 mTLS on each node, optional waypoint proxies for L7 policies. Namespaces opt in via `istio.io/dataplane-mode=ambient` label.

## Key Technical Details

- **No build system or test framework** — this is an infrastructure-as-code repo. Shell scripts are the primary automation. Validation is done via `kubectl wait` for pod readiness.
- **Credentials go in `vars.sh`** — never committed. Scripts validate required credentials before proceeding.
- **All scripts use `set -e`** — they exit immediately on error.
- **Helm is the primary installer** — components are installed via Helm charts with values files in `manifests/`.
- **Kustomize** is used for the movies-app deployment.
- **k3d cluster configs** disable Traefik (`--disable=traefik`) since sandboxes install their own ingress.

## When Modifying Scripts

- Always quote shell variables (`"$VAR"` not `$VAR`)
- Use variables from `vars.sh` for versions and names — don't hardcode
- Follow the existing pattern: source vars.sh → validate credentials → delete old cluster → create new → install components → wait for readiness → display access info
- Port mappings must not conflict between sandboxes that might run simultaneously
