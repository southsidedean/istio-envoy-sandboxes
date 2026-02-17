# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

AWS EKS sandbox for testing SPIFFE/SPIRE identity with Istio Ambient mode, using Solo.io's enterprise Istio distribution. The full stack deploys: EKS cluster -> SPIRE (identity) -> Istio Ambient (mesh) -> movies sample app (load test).

## Prerequisites

- AWS CLI configured with a named profile
- `eksctl`, `kubectl`, `kubectx`, `helm`, `envsubst`

## Configuration

Edit `vars.sh` before running any scripts. Three values require manual insertion (marked with `<<INSERT_..._HERE>>`):
- `AWS_PROFILE` - AWS CLI profile name
- `REPO_KEY` - Solo.io container registry key (used to construct `REPO` and `HELM_REPO` URLs)
- `SOLO_ISTIO_LICENSE_KEY` - Solo enterprise Istio license

Other configurable values: `AWS_REGION`, `NODE_TYPE`, `EKS_VERSION`, `ISTIO_VERSION`, `SPIRE_VERSION`.

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
3. **Gateway API CRDs** (v1.4.0)
4. **SPIRE** via Helm (`spire-h/spire-crds` + `spire-h/spire`), configured in `manifests/spire-values.yaml`
5. **Istio Ambient mode** via 4 Helm charts from Solo OCI registry: `base`, `istiod`, `cni`, `ztunnel` (values inline in script)
6. **Movies app** via Kustomize, then labeled for ambient mode (`istio.io/dataplane-mode=ambient`)

### Movies Sample App (`movies/`)

- **movieinfo-{chi,lax,nyc}** - Nginx pods serving location-specific HTML responses, with HPA (1-3 replicas, 25% CPU target)
- **frontend-{central,east,west}** - Fortio load generators sending 500 QPS each to `movieinfo.movies.svc.cluster.local`
- All resources deployed via Kustomize (`movies/kustomization.yaml`) into `movies` namespace

### Key Manifests

- `manifests/eks-cluster.yaml` - eksctl template using env vars (cluster name, region, version, node type)
- `manifests/spire-values.yaml` - SPIRE config with trust domain `example.org`, uses envsubst for cluster name
- `manifests/istio-values.yaml` - Placeholder for Istio Helm overrides (currently minimal; most values are inline in the setup script)
- `manifests/istio-gateway-spiffeid.yaml` - ClusterSPIFFEID mapping for Istio ingress gateway
- `manifests/grafana-values.yaml` - Grafana with 7 pre-configured Istio/ztunnel dashboards (installation currently commented out)

## Known Issues

- Grafana installation is commented out in `cluster-setup-everything.sh`
- `manifests/istio-values.yaml` is mostly empty; Istio Helm values are defined inline in the setup script
- `EKS_VERSION` in vars.sh has escaped quotes (`\"1.33\"`) which may cause issues
