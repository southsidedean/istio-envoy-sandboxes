# EKS SPIFFE/SPIRE Istio Ambient Sandbox

An automated sandbox for deploying an AWS EKS cluster with [SPIFFE/SPIRE](https://spiffe.io/) workload identity and [Istio Ambient mode](https://istio.io/latest/docs/ambient/) using [Solo.io's enterprise Istio distribution](https://www.solo.io/products/istio/). Includes a sample load-testing application to exercise the mesh.

## Architecture

The full deployment stack builds up in layers:

```
┌─────────────────────────────────────────────────┐
│      Grafana Observability (7 dashboards)       │
│         exposed on /grafana via kgateway        │
├─────────────────────────────────────────────────┤
│              Movies Sample App                  │
│   (3x movieinfo backends + 3x Fortio clients)   │
├─────────────────────────────────────────────────┤
│         Prometheus (metrics collection)         │
├─────────────────────────────────────────────────┤
│          Istio Ambient Mode (Solo)              │
│   (istiod, CNI, ztunnel + Gateway API CRDs)     │
├─────────────────────────────────────────────────┤
│              SPIRE Identity                     │
│         (Server + Agent + CRDs)                 │
├─────────────────────────────────────────────────┤
│     kgateway (Gateway API controller, OSS)      │
├─────────────────────────────────────────────────┤
│              AWS EKS Cluster                    │
│      (managed node group, t3a.large x2)         │
└─────────────────────────────────────────────────┘
```

**Istio Ambient mode** provides a sidecar-less service mesh using ztunnel for Layer 4 encryption and routing, avoiding the per-pod proxy overhead of traditional sidecar injection.

**SPIRE** provides cryptographic workload identities (SPIFFE IDs) to all workloads, with the trust domain `example.org`. Ztunnel acts as a trusted delegate of SPIRE, fetching workload certificates via the DelegatedIdentity API instead of Istio's built-in CA. This means workloads get SPIRE-issued mTLS identities automatically without mounting sockets or volumes into each pod.

## Prerequisites

The following tools must be installed and available on your `PATH`:

- [AWS CLI](https://aws.amazon.com/cli/) - configured with a named profile that has permissions to create EKS clusters
- [eksctl](https://eksctl.io/) - EKS cluster lifecycle management
- [kubectl](https://kubernetes.io/docs/tasks/tools/) - Kubernetes CLI
- [kubectx](https://github.com/ahmetb/kubectx) - context switching
- [Helm](https://helm.sh/) - chart installations
- `envsubst` (part of GNU gettext) - template variable substitution

## Configuration

Copy or edit `vars.sh` and fill in the four placeholder values:

| Variable | Description |
|---|---|
| `AWS_PROFILE` | Your AWS CLI profile name |
| `REPO_KEY` | Solo.io container registry key (constructs the OCI image and Helm chart URLs) |
| `SOLO_ISTIO_LICENSE_KEY` | Solo enterprise Istio license string |
| `GRAFANA_ADMIN_PASSWORD` | Grafana admin password |

### Optional Tuning

| Variable | Default | Description |
|---|---|---|
| `CLUSTER_NAME` | `spire-01` | EKS cluster name |
| `AWS_REGION` | `us-east-1` | AWS region |
| `NODE_TYPE` | `t3a.large` | EC2 instance type for worker nodes |
| `EKS_VERSION` | `1.33` | Kubernetes version |
| `ISTIO_VERSION` | `1.25.3` | Solo Istio version |
| `SPIRE_VERSION` | `0.24.1` | SPIRE Helm chart version |
| `KGATEWAY_VERSION` | `v2.2.0` | kgateway Helm chart version |
| `GATEWAY_API_VERSION` | `1.4.0` | Gateway API CRD version |
| `GRAFANA_ADMIN_USER` | `admin` | Grafana admin username |

## Quick Start

```bash
# 1. Configure your environment
vi vars.sh  # Set AWS_PROFILE, REPO_KEY, SOLO_ISTIO_LICENSE_KEY, and GRAFANA_ADMIN_PASSWORD

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
3. **Gateway API CRDs** - Installs Kubernetes Gateway API standard and experimental CRDs (version configurable via `GATEWAY_API_VERSION`)
4. **kgateway** - Installs the OSS Gateway API controller (`kgateway-crds` + `kgateway`) from `oci://cr.kgateway.dev/kgateway-dev/charts`, with experimental Gateway API features enabled
5. **SPIRE** - Installs CRDs, server, and agent into `spire-mgmt` namespace via `--repo https://spiffe.github.io/helm-charts-hardened/` with configuration from `manifests/spire-values.yaml`. The agent authorizes ztunnel as a delegate and exposes its socket on the host at `/run/spire/agent/sockets`
6. **ClusterSPIFFEID registrations** - Registers four workload classes with SPIRE: ztunnel, ambient-labeled namespaces, waypoint proxies, and the ingress gateway
7. **Istio Ambient** - Installs four Helm charts from Solo's OCI registry:
   - `base` - Istio CRDs
   - `istiod` - Control plane (with DNS capture, access logging, SPIRE gateway support via `gateways.spire.workloads: true`)
   - `cni` - Ambient CNI plugin (excludes `istio-system` and `kube-system`)
   - `ztunnel` - Layer 4 data plane (SPIRE enabled, distroless variant, L7 enabled)
8. **Prometheus** - Installs via `prometheus-community/prometheus` Helm chart into `istio-system` with values from `manifests/prometheus-values.yaml`. Automatically discovers Istio metrics via pod annotations.
9. **Movies app** - Deploys via Kustomize and labels the namespace for ambient mode
10. **Grafana** - Installs via Helm with 7 pre-configured Istio dashboards, exposed on `/grafana` via a kgateway Gateway + HTTPRoute

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
│   ├── spire-values.yaml                # SPIRE Helm values with ztunnel delegate auth
│   ├── istio-values.yaml                # Istio Helm overrides (placeholder)
│   ├── istio-gateway-spiffeid.yaml      # ClusterSPIFFEID registrations (4 workload classes)
│   ├── prometheus-values.yaml            # Prometheus server config (metrics collection)
│   ├── grafana-values.yaml              # Grafana with 7 Istio dashboards
│   └── grafana-gateway.yaml             # Gateway + HTTPRoute for Grafana via kgateway
└── movies/
    ├── kustomization.yaml               # Kustomize overlay
    ├── namespace.yaml                   # movies namespace
    ├── movieinfo-service.yaml           # ClusterIP service
    ├── movieinfo-{chi,lax,nyc}.yaml     # Backend deployments + ConfigMaps
    ├── movieinfo-hpa.yaml               # HPA for all backends
    └── frontend-{central,east,west}.yaml # Fortio load generators
```

## Observability

Grafana is installed automatically by `cluster-setup-everything.sh` and exposed externally on `/grafana` via a kgateway Gateway + HTTPRoute. After deployment, the script prints the external URL.

To access Grafana manually:

```bash
# Get the LoadBalancer hostname/IP
kubectl get svc -n kgateway-system http

# Open in browser
# http://<external-address>:8080/grafana
```

Login with the credentials configured in `vars.sh` (`GRAFANA_ADMIN_USER` / `GRAFANA_ADMIN_PASSWORD`). The deploy script prints these at the end. Seven pre-configured dashboards are included:
- Istio Mesh, Control Plane, Service, Workload, Performance, and Wasm Extension dashboards
- Ztunnel dashboard

Prometheus is deployed into `istio-system` and automatically discovers Istio metrics (istiod, ztunnel) via `prometheus.io/*` pod annotations. No custom scrape configuration is needed.

## SPIRE Identity Integration

SPIRE is fully integrated with Istio Ambient mode using Solo.io's enterprise feature set. The integration works as follows:

1. **SPIRE agent** runs on each node and is configured to authorize ztunnel as a trusted delegate (`authorizedDelegates` in `spire-values.yaml`)
2. **Ztunnel** connects to the SPIRE agent socket on the host and uses the DelegatedIdentity API to request certificates on behalf of workloads, replacing Istio's built-in CA
3. **ClusterSPIFFEID resources** tell SPIRE which workloads should receive identities, using the template:

```
spiffe://<trust-domain>/ns/<namespace>/sa/<service-account>
```

Four workload classes are registered in `manifests/istio-gateway-spiffeid.yaml`:

| Registration | Selector | Purpose |
|---|---|---|
| `istio-ztunnel-reg` | `app: ztunnel` | Ztunnel's own identity for DelegatedIdentity API |
| `istio-ambient-reg` | namespace label `istio.io/dataplane-mode: ambient` | All ambient workloads (e.g. movies app) |
| `istio-waypoint-reg` | `istio.io/gateway-name: waypoint` | L7 waypoint proxies |
| `istio-ingressgateway-reg` | `istio: ingressgateway` | Istio ingress gateway |

The registrations are applied automatically by `cluster-setup-everything.sh` after SPIRE is installed and before Istio is deployed. To apply them manually:

```bash
kubectl apply -f manifests/istio-gateway-spiffeid.yaml
```

## Cleanup

```bash
./scripts/cluster-destroy-eks.sh
```

This deletes the EKS cluster (including all workloads) and cleans up the local kubectl context.
