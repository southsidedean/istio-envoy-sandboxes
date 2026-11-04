# k3d Sandboxes

**Local OSS environments for service mesh, API gateway, and AI agent testing**

Tom Dean
Last edit: 11/4/2026

> **Status:** `kgateway-sandbox` and `istio-llb-sandbox` were verified on 11/4/2026. `ai-sandbox` and `kagent-sandbox` haven't been re-tested. See the [known issues](../README.md#known-issues) and [PLAN.md](../PLAN.md).

## Sandboxes

| Sandbox | Service mesh | API gateway | AI agents | Observability | Locality LB |
|---|---|---|---|---|---|
| [ai-sandbox](ai-sandbox/) | Istio Ambient | Kgateway | ✓ | - | - |
| [kagent-sandbox](kagent-sandbox/) | - | Kgateway | ✓ | - | - |
| [kgateway-sandbox](kgateway-sandbox/) | - | Kgateway | - | - | - |
| [istio-llb-sandbox](istio-llb-sandbox/) | Istio (ambient or sidecar) | - | - | Kiali, Grafana, Prometheus | ✓ |

## Usage

You need [k3d](https://k3d.io/), [Docker](https://www.docker.com/get-started/), [kubectl](https://kubernetes.io/docs/tasks/tools/), [kubectx](https://github.com/ahmetb/kubectx), [Helm](https://helm.sh/), and `bash`.

```bash
cd <sandbox-name>
vi vars.sh                                  # Set credentials, if the sandbox needs them
./scripts/cluster-setup-k3d-<variant>-everything.sh
kubectl get pods -A
./scripts/cluster-destroy-k3d.sh            # When you're finished
```

Other scripts:

- `cluster-setup-k3d-naked.sh` creates a bare cluster with zone labels.
- `cluster-setup-k3d-amb-everything.sh` and `cluster-setup-k3d-sc-everything.sh` deploy `istio-llb-sandbox` in ambient and sidecar mode.

## Ports

Ports are `${PREFIX}${CLUSTER_NUM}`, so prefix `70` on cluster `01` is `7001`. Each sandbox has its own prefixes, so they can run at the same time.

| Sandbox | HTTP | HTTPS | API | First HTTP port |
|---|---|---|---|---|
| ai-sandbox | 70 | 74 | 76 | 7001 |
| istio-llb-sandbox | 72 | 82 | 92 | 7201 |
| kagent-sandbox | 73 | 83 | 93 | 7301 |
| kgateway-sandbox | 80 | 84 | 86 | 8001 |

## Troubleshooting

```bash
k3d cluster list                    # List clusters
k3d cluster delete <cluster-name>   # Delete a stuck cluster
docker system df                    # Check Docker disk use
lsof -i :7001                       # Find what's using a port
```

To change a port, edit `cluster-k3d/k3d-cluster.yaml` or the prefixes in `vars.sh`.
