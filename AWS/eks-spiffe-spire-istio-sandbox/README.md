# EKS SPIFFE/SPIRE Istio Ambient Sandbox

An automated sandbox for deploying an AWS EKS cluster with [SPIFFE/SPIRE](https://spiffe.io/) workload identity and [Istio Ambient mode](https://istio.io/latest/docs/ambient/) using [Solo.io's enterprise Istio distribution](https://www.solo.io/products/istio/). Includes a sample load-testing application to exercise the mesh.

## Architecture

The full deployment stack builds up in layers:

```
┌─────────────────────────────────────────────────┐
│              Movies Sample App                  │
│   (3x movieinfo backends + 3x Fortio clients)   │
├─────────────────────────────────────────────────┤
│          Istio Ambient Mode (Solo)              │
│   (istiod, CNI, ztunnel + Gateway API CRDs)     │
├─────────────────────────────────────────────────┤
│              SPIRE Identity                     │
│         (Server + Agent + CRDs)                 │
├─────────────────────────────────────────────────┤
│              AWS EKS Cluster                    │
│      (managed node group, t3a.large x2)         │
└─────────────────────────────────────────────────┘
```

**Istio Ambient mode** provides a sidecar-less service mesh using ztunnel for Layer 4 encryption and routing, avoiding the per-pod proxy overhead of traditional sidecar injection.

**SPIRE** provides cryptographic workload identities (SPIFFE IDs) to all workloads, with the trust domain `example.org`. A `ClusterSPIFFEID` resource maps identities to Istio's ingress gateway.

## Prerequisites

The following tools must be installed and available on your `PATH`:

- [AWS CLI](https://aws.amazon.com/cli/) - configured with a named profile that has permissions to create EKS clusters
- [eksctl](https://eksctl.io/) - EKS cluster lifecycle management
- [kubectl](https://kubernetes.io/docs/tasks/tools/) - Kubernetes CLI
- [kubectx](https://github.com/ahmetb/kubectx) - context switching
- [Helm](https://helm.sh/) - chart installations
- `envsubst` (part of GNU gettext) - template variable substitution

## Configuration

Copy or edit `vars.sh` and fill in the three placeholder values:

| Variable | Description |
|---|---|
| `AWS_PROFILE` | Your AWS CLI profile name |
| `REPO_KEY` | Solo.io container registry key (constructs the OCI image and Helm chart URLs) |
| `SOLO_ISTIO_LICENSE_KEY` | Solo enterprise Istio license string |

### Optional Tuning

| Variable | Default | Description |
|---|---|---|
| `CLUSTER_NAME` | `spire-01` | EKS cluster name |
| `AWS_REGION` | `us-east-1` | AWS region |
| `NODE_TYPE` | `t3a.large` | EC2 instance type for worker nodes |
| `EKS_VERSION` | `1.33` | Kubernetes version |
| `ISTIO_VERSION` | `1.25.3` | Solo Istio version |
| `SPIRE_VERSION` | `0.24.1` | SPIRE Helm chart version |

## Quick Start

```bash
# 1. Configure your environment
vi vars.sh  # Set AWS_PROFILE, REPO_KEY, and SOLO_ISTIO_LICENSE_KEY

# 2. Deploy the full stack (EKS + SPIRE + Istio Ambient + movies app)
./scripts/cluster-setup-everything.sh

# 3. When finished, tear it all down
./scripts/cluster-destroy-eks.sh
```

### Alternative: Bare Cluster

To create just the EKS cluster without any components installed:

```bash
./scripts/cluster-setup-naked.sh
```

This is useful for manually installing and experimenting with individual components.

## What Gets Deployed

### `cluster-setup-everything.sh` Step by Step

1. **EKS cluster** - Creates the cluster using `eksctl` with the templated `manifests/eks-cluster.yaml` (2 nodes, autoscaling 1-4)
2. **istioctl CLI** - Downloads Solo's `istioctl` binary to `~/.istioctl/bin`
3. **Gateway API CRDs** - Installs Kubernetes Gateway API v1.4.0 standard resources
4. **SPIRE** - Installs CRDs, server, and agent via the `spire-h` Helm repo with configuration from `manifests/spire-values.yaml`
5. **Istio Ambient** - Installs four Helm charts from Solo's OCI registry:
   - `base` - Istio CRDs
   - `istiod` - Control plane (with DNS capture, access logging, SPIRE trust domain skip)
   - `cni` - Ambient CNI plugin (excludes `istio-system` and `kube-system`)
   - `ztunnel` - Layer 4 data plane (distroless variant, L7 enabled)
6. **Movies app** - Deploys via Kustomize and labels the namespace for ambient mode

### Movies Sample Application

The `movies/` directory contains a load-testing application deployed into the `movies` namespace:

**Backend services** (`movieinfo-chi`, `movieinfo-lax`, `movieinfo-nyc`):
- Nginx containers serving location-specific HTML responses
- All three share the `app: movieinfo` label and are load-balanced behind a single `movieinfo` ClusterIP Service
- Each has an HPA configured to scale 1-3 replicas at 25% CPU utilization (90s scale-down stabilization)

**Load generators** (`frontend-central`, `frontend-east`, `frontend-west`):
- [Fortio](https://github.com/fortio/fortio) containers running continuous load at 500 QPS each (1500 QPS total)
- Target: `http://movieinfo.movies.svc.cluster.local/index.html`
- Traffic flows through the ambient mesh's ztunnel, providing mTLS without sidecars

```
frontend-central ──┐
frontend-east    ──┼── 1500 QPS ──► movieinfo (ClusterIP) ──┬── movieinfo-chi (1-3 pods)
frontend-west    ──┘                                        ├── movieinfo-lax (1-3 pods)
                                                            └── movieinfo-nyc (1-3 pods)
```

You can deploy the movies app independently:

```bash
kubectl apply -k movies
kubectl label ns movies istio.io/dataplane-mode=ambient
```

## Repository Structure

```
├── vars.sh                              # Environment variables (edit before use)
├── scripts/
│   ├── cluster-setup-everything.sh      # Full stack deployment
│   ├── cluster-setup-naked.sh           # Bare EKS cluster only
│   └── cluster-destroy-eks.sh           # Cluster teardown
├── manifests/
│   ├── eks-cluster.yaml                 # eksctl cluster config (envsubst template)
│   ├── spire-values.yaml                # SPIRE Helm values (envsubst template)
│   ├── istio-values.yaml                # Istio Helm overrides (placeholder)
│   ├── istio-gateway-spiffeid.yaml      # ClusterSPIFFEID for ingress gateway
│   ├── grafana-values.yaml              # Grafana with 7 Istio dashboards
│   └── grafana-ingress.yaml             # Traefik ingress for Grafana
└── movies/
    ├── kustomization.yaml               # Kustomize overlay
    ├── namespace.yaml                   # movies namespace
    ├── movieinfo-service.yaml           # ClusterIP service
    ├── movieinfo-{chi,lax,nyc}.yaml     # Backend deployments + ConfigMaps
    ├── movieinfo-hpa.yaml               # HPA for all backends
    └── frontend-{central,east,west}.yaml # Fortio load generators
```

## Observability (Optional)

Grafana configuration is included but commented out in the setup script. To enable it:

```bash
helm repo add grafana https://grafana.github.io/helm-charts
helm repo update
helm install grafana -n grafana --create-namespace grafana/grafana \
  -f manifests/grafana-values.yaml
```

This installs Grafana with anonymous access enabled and seven pre-configured dashboards:
- Istio Mesh, Control Plane, Service, Workload, Performance, and Wasm Extension dashboards
- Ztunnel dashboard

The dashboards pull metrics from a Prometheus instance expected at `prometheus.istio-system.svc.cluster.local:9090`.

## SPIRE Identity Integration

The `manifests/istio-gateway-spiffeid.yaml` defines a `ClusterSPIFFEID` resource that assigns SPIFFE identities to the Istio ingress gateway:

```
spiffe://<trust-domain>/ns/<namespace>/sa/<service-account>
```

To apply it:

```bash
kubectl apply -f manifests/istio-gateway-spiffeid.yaml
```

## Cleanup

```bash
./scripts/cluster-destroy-eks.sh
```

This deletes the EKS cluster (including all workloads) and cleans up the local kubectl context.
