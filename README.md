# istio-envoy-sandboxes

**Scripted OSS sandboxes for Istio and Kgateway on k3d**

Tom Dean
Last edit: 11/4/2026

> **Status:** These sandboxes aren't actively developed. Both k3d sandboxes were verified on 11/4/2026 with the versions in [PLAN.md](PLAN.md).

## Sandboxes

| Sandbox | What it runs | Setup script | HTTP port |
|---|---|---|---|
| [kgateway-sandbox](k3d-sandboxes/kgateway-sandbox/README.md) | Kgateway, Gateway API | `cluster-setup-k3d-kgw-everything.sh` | 8001 |
| [istio-llb-sandbox](k3d-sandboxes/istio-llb-sandbox/README.md) | Istio locality load balancing with Kiali, Grafana, Prometheus | `cluster-setup-k3d-amb-everything.sh` (ambient) or `cluster-setup-k3d-sc-everything.sh` (sidecar) | 7201 |

The sandboxes share [movies-app](apps/movies-app/README.md), a load-test app with 3 Fortio frontends and 3 Nginx backends spread across 3 zones.

### Unverified: AWS

[eks-spiffe-spire-istio-sandbox](AWS/eks-spiffe-spire-istio-sandbox/README.md) combines SPIFFE/SPIRE identity with Istio Ambient on EKS. It's **stale and unverified**, and it needs a Solo.io license, so it's kept as a reference only.

## Quick Start

You need [Docker](https://www.docker.com/get-started/), [k3d](https://k3d.io/), [kubectl](https://kubernetes.io/docs/tasks/tools/), [kubectx](https://github.com/ahmetb/kubectx), [Helm](https://helm.sh/), and `bash`.

```bash
cd k3d-sandboxes/<sandbox-name>
./scripts/cluster-setup-k3d-<variant>-everything.sh
kubectl get pods -A
./scripts/cluster-destroy-k3d.sh            # When you're finished
```

## Known Issues

[PLAN.md](PLAN.md) has the full list.

| Area | Issue |
|---|---|
| `scripts/yaml-collector.sh` | It deletes `./manifests`, so don't run it from inside a sandbox. |

## Older Content

Tag [`pre-oss-cleanup-2026-11`](https://github.com/southsidedean/istio-envoy-sandboxes/releases/tag/pre-oss-cleanup-2026-11) keeps the repository as it was before this cleanup, including the AI agent, Gloo, and enterprise sandboxes. It's archived and unmaintained, the AI agent sandboxes have known bugs, and the enterprise sandboxes need vendor licenses.

## Contributing

This is a personal learning and testing repository. Feel free to fork it and adapt it for your own use.

## License

[MIT](LICENSE). Third-party components keep their own licenses.
