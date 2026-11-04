# k3d Sandboxes

**Local OSS environments for service mesh and API gateway testing**

Tom Dean
Last edit: 11/4/2026

> **Status:** Both sandboxes were verified on 11/4/2026. See [PLAN.md](../PLAN.md) for versions.

## Sandboxes

| Sandbox | Service mesh | API gateway | Observability | Locality LB |
|---|---|---|---|---|
| [kgateway-sandbox](kgateway-sandbox/) | - | Kgateway | - | - |
| [istio-llb-sandbox](istio-llb-sandbox/) | Istio (ambient or sidecar) | - | Kiali, Grafana, Prometheus | ✓ |

## Usage

You need [k3d](https://k3d.io/), [Docker](https://www.docker.com/get-started/), [kubectl](https://kubernetes.io/docs/tasks/tools/), [kubectx](https://github.com/ahmetb/kubectx), [Helm](https://helm.sh/), and `bash`.

```bash
cd <sandbox-name>
./scripts/cluster-setup-k3d-<variant>-everything.sh
kubectl get pods -A
./scripts/cluster-destroy-k3d.sh            # When you're finished
```

Other scripts:

- `cluster-setup-k3d-naked.sh` creates a bare cluster with zone labels.
- `cluster-setup-k3d-amb-everything.sh` and `cluster-setup-k3d-sc-everything.sh` deploy `istio-llb-sandbox` in ambient and sidecar mode.

## Ports

Ports are `${PREFIX}${CLUSTER_NUM}`, so prefix `72` on cluster `01` is `7201`. Each sandbox has its own prefixes, so they can run at the same time.

| Sandbox | HTTP | HTTPS | API | First HTTP port |
|---|---|---|---|---|
| istio-llb-sandbox | 72 | 82 | 92 | 7201 |
| kgateway-sandbox | 80 | 84 | 86 | 8001 |

## Troubleshooting

```bash
k3d cluster list                    # List clusters
k3d cluster delete <cluster-name>   # Delete a stuck cluster
docker system df                    # Check Docker disk use
lsof -i :7201                       # Find what's using a port
```

To change a port, edit `cluster-k3d/k3d-cluster.yaml` or the prefixes in `vars.sh`.
