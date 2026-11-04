# istio-envoy-sandboxes

**Scripted OSS sandboxes for Istio, Kgateway, and Kagent on k3d**

Tom Dean
Last edit: 11/4/2026

> **Status:** These sandboxes aren't actively developed, and a cleanup is in progress. No sandbox has been re-tested since the April 2026 versions were set, and the [known issues](#known-issues) below haven't been fixed yet. See [PLAN.md](PLAN.md).

## Sandboxes

| Sandbox | What it runs | Setup script | HTTP port | Needs |
|---|---|---|---|---|
| [ai-sandbox](k3d-sandboxes/ai-sandbox/README.md) | Istio Ambient, Kagent, Kgateway, Agentgateway, Agentregistry | `cluster-setup-k3d-ai-everything.sh` | 7001 | `OPENAI_API_KEY` |
| [kagent-sandbox](k3d-sandboxes/kagent-sandbox/README.md) | Kagent, Kgateway | `cluster-setup-k3d-kagent-everything.sh` | 7301 | `OPENAI_API_KEY` |
| [kgateway-sandbox](k3d-sandboxes/kgateway-sandbox/README.md) | Kgateway, Gateway API | `cluster-setup-k3d-kgw-everything.sh` | 8001 | — |
| [istio-llb-sandbox](k3d-sandboxes/istio-llb-sandbox/README.md) | Istio locality load balancing with Kiali, Grafana, Prometheus | `cluster-setup-k3d-amb-everything.sh` (ambient) or `cluster-setup-k3d-sc-everything.sh` (sidecar) | 7201 | — |

The sandboxes share [movies-app](apps/movies-app/README.md), a load-test app with 3 Fortio frontends and 3 Nginx backends spread across 3 zones.

### Unverified: AWS

[eks-spiffe-spire-istio-sandbox](AWS/eks-spiffe-spire-istio-sandbox/README.md) combines SPIFFE/SPIRE identity with Istio Ambient on EKS. It's **stale and unverified**, and it needs a Solo.io license, so it's kept as a reference only.

## Quick Start

You need [Docker](https://www.docker.com/get-started/), [k3d](https://k3d.io/), [kubectl](https://kubernetes.io/docs/tasks/tools/), [kubectx](https://github.com/ahmetb/kubectx), [Helm](https://helm.sh/), and `bash`.

```bash
cd k3d-sandboxes/<sandbox-name>
vi vars.sh                                  # Set credentials, if the sandbox needs them
./scripts/cluster-setup-k3d-<variant>-everything.sh
kubectl get pods -A
./scripts/cluster-destroy-k3d.sh            # When you're finished
```

Don't commit real credentials to `vars.sh`.

## Known Issues

These come from reading the scripts and rendering the charts. No cluster was started. [PLAN.md](PLAN.md) has the full list.

| Sandbox | Issue |
|---|---|
| `ai-sandbox` | Setup is expected to stop at the `istiod` wait. Agentregistry 0.3.2 needs an external PostgreSQL, and the Agentgateway and Kagent routes point at Services or ports that don't exist. |
| `kagent-sandbox` | The UI route points at a Service that the chart doesn't create. |
| `kgateway-sandbox` | The default of 3 clusters fails on clusters 2 and 3. Set `NUM_CLUSTERS=1` in `vars.sh`. |
| `istio-llb-sandbox` | The Kiali and Grafana URLs need Traefik, which the cluster config disables. Istio also installs a newer version than the scripts report. |
| `scripts/yaml-collector.sh` | It deletes `./manifests`, so don't run it from inside a sandbox. |

## Older Content

Tag [`pre-oss-cleanup-2026-11`](https://github.com/southsidedean/istio-envoy-sandboxes/releases/tag/pre-oss-cleanup-2026-11) keeps the repository as it was before this cleanup, including the Gloo and enterprise sandboxes. It's archived and unmaintained, and those sandboxes need vendor licenses.

## Contributing

This is a personal learning and testing repository. Feel free to fork it and adapt it for your own use.

## License

[MIT](LICENSE). Third-party components keep their own licenses.
