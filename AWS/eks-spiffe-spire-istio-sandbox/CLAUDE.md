# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Status

**Unverified and stale.** This is the one exception to the repository's OSS-only rule, because it needs Solo.io credentials the maintainer no longer has. Don't run it, or spend effort updating it, unless asked. Known issues are in the root `PLAN.md`.

## Project Overview

AWS EKS sandbox for testing SPIFFE/SPIRE identity with Istio Ambient mode, using Solo.io's enterprise Istio distribution. The full stack deploys: EKS cluster -> SPIRE (identity) -> Istio Ambient (mesh) -> movies sample app (load test).

## Prerequisites

- AWS CLI configured with a named profile
- `eksctl`, `kubectl`, `kubectx`, `helm`, `envsubst`

## Configuration

Edit `vars.sh` before running any scripts. Four values require manual insertion (marked with `<<INSERT_..._HERE>>`):
- `AWS_PROFILE` - AWS CLI profile name
- `REPO_KEY` - Solo.io container registry key (used to construct `REPO` and `HELM_REPO` URLs)
- `SOLO_ISTIO_LICENSE_KEY` - Solo enterprise Istio license
- `GRAFANA_ADMIN_PASSWORD` - Grafana admin password (username defaults to `admin` via `GRAFANA_ADMIN_USER`)

Other configurable values: `AWS_REGION`, `NODE_TYPE`, `EKS_VERSION`, `ISTIO_VERSION`, `SPIRE_VERSION`, `KGATEWAY_VERSION`, `GATEWAY_API_VERSION`.

## Common Commands

```bash
source vars.sh                          # Required before any script
./scripts/cluster-setup-everything.sh   # Full stack: EKS + SPIRE + Istio Ambient + movies app
./scripts/cluster-setup-naked.sh        # Bare EKS cluster only
./scripts/cluster-destroy-eks.sh        # Delete cluster and clean up kubectl contexts
kubectl apply -k movies                 # Deploy movies app independently
```

## Architecture

### Deployment Stack (cluster-setup-everything.sh order)

1. **EKS cluster** via `eksctl` using `manifests/eks-cluster.yaml` (template with envsubst)
2. **istioctl CLI** installed from Solo.io's private binaries to `~/.istioctl/bin`
3. **Gateway API CRDs** (standard + experimental, version configurable via `GATEWAY_API_VERSION`)
4. **kgateway** (OSS Gateway API controller) via Helm from `oci://cr.kgateway.dev/kgateway-dev/charts` (`kgateway-crds` + `kgateway`), with experimental Gateway API features enabled
5. **SPIRE** via Helm (`spire-crds` + `spire`) using `--repo` from `https://spiffe.github.io/helm-charts-hardened/` into `spire-server` namespace, configured in `manifests/spire-values.yaml`
6. **ClusterSPIFFEID registrations** applied from `manifests/istio-gateway-spiffeid.yaml` (ztunnel, ambient workloads, waypoints)
7. **Istio Ambient mode** via 4 Helm charts from Solo OCI registry: `base`, `istiod`, `cni`, `ztunnel` (values inline in script)
8. **Prometheus** via `prometheus-community/prometheus` Helm chart into `istio-system`, configured in `manifests/prometheus-values.yaml`
9. **Movies app** via Kustomize, then labeled for ambient mode (`istio.io/dataplane-mode=ambient`)
10. **Grafana** via Helm with 7 pre-configured Istio dashboards, exposed on `/grafana` via kgateway Gateway + HTTPRoute

### Movies Sample App (`movies/`)

- **movieinfo-{chi,lax,nyc}** - Nginx pods serving location-specific HTML responses, with HPA (1-3 replicas, 25% CPU target)
- **frontend-{central,east,west}** - Fortio load generators sending 500 QPS each to `movieinfo.movies.svc.cluster.local`
- All resources deployed via Kustomize (`movies/kustomization.yaml`) into `movies` namespace

### Key Manifests

- `manifests/eks-cluster.yaml` - eksctl template using env vars (cluster name, region, version, node type)
- `manifests/spire-values.yaml` - SPIRE config with trust domain `example.org`, ztunnel authorized as delegate, agent socket on host
- `manifests/istio-gateway-spiffeid.yaml` - ClusterSPIFFEID registrations for ztunnel, ambient workloads, and waypoint proxies
- `manifests/prometheus-values.yaml` - Prometheus server config (service named `prometheus` on port 9090, sub-charts disabled)
- `manifests/grafana-values.yaml` - Grafana with 7 pre-configured Istio/ztunnel dashboards (admin credentials passed via `--set` from `vars.sh`)
- `manifests/grafana-gateway.yaml` - Gateway + HTTPRoute to expose Grafana on `/grafana` via kgateway

### SPIRE-Istio Integration

SPIRE is wired into Istio Ambient so that ztunnel fetches workload certificates from SPIRE (via the DelegatedIdentity API) instead of Istio's built-in CA. Key integration points:

- **SPIRE agent** authorizes ztunnel as a delegate (`spiffe://example.org/ns/istio-system/sa/ztunnel`) and exposes its socket at `/run/spire/agent/sockets`
- **ztunnel** has `spire.enabled: true` in its Helm values (inline in setup script)
- **istiod** has `gateways.spire.workloads: true` so waypoint proxies use the SPIRE CSI driver for identity
- **ClusterSPIFFEID resources** register three workload classes with SPIRE: ztunnel, ambient-labeled namespaces, and waypoint proxies
