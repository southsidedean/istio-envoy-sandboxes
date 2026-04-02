# ent-kgateway-sandbox

## Solo Enterprise for Kgateway

Local k3d sandbox for testing Solo Enterprise for Kgateway.

Tom Dean
Last edit: 3/27/2026

## Prerequisites

The following tools must be installed and available on your `PATH`:

- [k3d](https://k3d.io/) - Local Kubernetes cluster
- [kubectl](https://kubernetes.io/docs/tasks/tools/) - Kubernetes CLI
- [kubectx](https://github.com/ahmetb/kubectx) - Context switching
- [Helm](https://helm.sh/) - Chart installations

## Configuration

Edit `vars.sh` before running scripts:

| Variable | Default | Description |
|----------|---------|-------------|
| `NUM_CLUSTERS` | 3 | Number of k3d clusters to create |
| `CLUSTER_NAME_PREFIX` | `ent-kgw-` | Prefix for cluster names |
| `KUBECTX_NAME_PREFIX` | `ent-kgw-` | Prefix for kubectl context names |
| `CLUSTER_NETWORK` | `ent-kgw-network` | Docker network for the clusters |
| `K3S_VERSION` | `v1.35.2-k3s1` | k3s Kubernetes version |
| `ENT_KGATEWAY_VERSION` | `2.1.4` | Solo Enterprise for Kgateway version |
| `GATEWAY_API_VERSION` | `v1.5.1` | Gateway API CRD version |
| `LICENSE_KEY` | Required | Solo.io enterprise license key (set this before running) |

## Quick Start

```bash
# 1. Configure your environment
vi vars.sh  # Set LICENSE_KEY to your Solo.io enterprise license

# 2. Deploy the full stack (k3d + Enterprise Kgateway + movies app)
./scripts/cluster-setup-k3d-ent-kgw-everything.sh

# 3. When finished, tear it all down
./scripts/cluster-destroy-k3d.sh
```

## Alternative: Bare Clusters

To create just the k3d clusters without installing Enterprise Kgateway:

```bash
./scripts/cluster-setup-k3d-naked.sh
```

This is useful for manually installing and experimenting with individual components.

## What Gets Deployed

### `cluster-setup-k3d-ent-kgw-everything.sh` Step by Step

1. **k3d clusters** - Creates 3 local Kubernetes clusters (1 server + 3 agent nodes each) with:
   - HTTP ports: 6101, 6102, 6103 (mapped to port 80 in cluster)
   - HTTPS ports: 6501, 6502, 6503 (mapped to port 443 in cluster)
   - API ports: 6901, 6902, 6903
   - Agent nodes labeled with topology zones (central, west, east)

2. **Gateway API CRDs** - Installs the Gateway API standard CRDs (v1.5.1) from the upstream Kubernetes SIG release

3. **Solo Enterprise for Kgateway** - Installs Enterprise Kgateway v2.1.4 via Helm (OCI) into the `kgateway-system` namespace on each cluster:
   - CRDs chart: `oci://us-docker.pkg.dev/solo-public/enterprise-kgateway/charts/enterprise-kgateway-crds`
   - Main chart: `oci://us-docker.pkg.dev/solo-public/enterprise-kgateway/charts/enterprise-kgateway`
   - License key is passed via `--set-string licensing.licenseKey`

4. **HTTP Gateway** - Creates a `Gateway` resource using the `enterprise-kgateway` GatewayClass, listening on port 80 with routes allowed from all namespaces

5. **Movies app** - Deploys a sample load-testing application into the `movies` namespace on each cluster

### Movies Sample Application

The `movies/` directory is a symlink to the shared `apps/movies-app/` application:

**Backend services** (`movieinfo-chi`, `movieinfo-lax`, `movieinfo-nyc`):
- Nginx containers serving location-specific HTML responses
- All three share the `app: movieinfo` label and are load-balanced behind a single `movieinfo` ClusterIP Service
- Resource limits: 50m/200m CPU, 64Mi/128Mi memory

**Load generators** (`frontend-central`, `frontend-east`, `frontend-west`):
- [Fortio](https://github.com/fortio/fortio) containers running continuous load at 500 QPS each (1500 QPS total)
- Target: `http://movieinfo.movies.svc.cluster.local/index.html`

```
frontend-central --+
frontend-east    --+-- 1500 QPS --> movieinfo (ClusterIP) --+-- movieinfo-chi
frontend-west    --+                                        +-- movieinfo-lax
                                                            +-- movieinfo-nyc
```

## Repository Structure

```
ent-kgateway-sandbox/
+-- vars.sh                                    # Environment variables (edit before use)
+-- scripts/
|   +-- cluster-setup-k3d-ent-kgw-everything.sh  # Full stack deployment
|   +-- cluster-setup-k3d-naked.sh                # Bare k3d clusters only
|   +-- cluster-destroy-k3d.sh                    # Cluster teardown
+-- cluster-k3d/
|   +-- k3d-cluster.yaml                          # Default k3d cluster configuration (medium)
|   +-- k3d-large.yaml                            # Large cluster variant
|   +-- k3d-medium.yaml                           # Medium cluster variant
|   +-- k3d-small.yaml                            # Small cluster variant
|   +-- k3d-tiny.yaml                             # Tiny cluster variant
+-- manifests/
|   +-- http-listener.yaml                        # Gateway resource (enterprise-kgateway class)
+-- movies -> ../../apps/movies-app               # Symlink to shared movies app
```

## Accessing the Clusters

After deployment, you can switch between cluster contexts:

```bash
# List all contexts
kubectx

# Switch to a specific cluster
kubectx ent-kgw-01
kubectx ent-kgw-02
kubectx ent-kgw-03

# View resources in a cluster
kubectl get all -n kgateway-system
kubectl get all -n movies

# Check the Gateway resource
kubectl get gateway -n kgateway-system
```

## Port Mappings

Each cluster has its own port mappings on localhost:

| Cluster | HTTP Port | HTTPS Port | API Port |
|---------|-----------|------------|----------|
| ent-kgw-01 | 6101 | 6501 | 6901 |
| ent-kgw-02 | 6102 | 6502 | 6902 |
| ent-kgw-03 | 6103 | 6503 | 6903 |

Access services via:
```bash
# Example: Access cluster 1
curl http://localhost:6101
```

## Troubleshooting

### License Key Issues
Ensure `LICENSE_KEY` is set in `vars.sh` before running setup scripts. The script will exit with an error if the placeholder value is still present.

### Cluster Status
```bash
# List all k3d clusters
k3d cluster list

# View cluster contexts
kubectx
```

### Pod Issues
```bash
# Check pod status
kubectl get pods -n kgateway-system
kubectl get pods -n movies

# View pod logs
kubectl logs -n kgateway-system <pod-name>
```

### Gateway Status
```bash
# Check Gateway resource status
kubectl get gateway -n kgateway-system
kubectl describe gateway http-gateway -n kgateway-system
```

## Cleanup

```bash
./scripts/cluster-destroy-k3d.sh
```

This deletes all k3d clusters and cleans up kubectl contexts.
