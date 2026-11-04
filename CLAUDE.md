# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

Self-contained local sandboxes for trying open source service mesh and gateway projects on k3d: Istio and Kgateway. The repository is **OSS-only** and low-maintenance. `PLAN.md` tracks the cleanup and lists known bugs, so read it before changing a sandbox.

Licensed, Gloo, AI agent, and AWS sandboxes were removed. They remain available at tag `pre-oss-cleanup-2026-11`. Don't add anything that needs a commercial license or vendor credentials.

## Repository Layout

- `k3d-sandboxes/`
  - `kgateway-sandbox/` — Kgateway OSS (Gateway API)
  - `istio-llb-sandbox/` — Istio locality load balancing, ambient or sidecar, with Kiali and Grafana
- `apps/movies-app/` — Shared load-test app: 3 Fortio frontends and 3 Nginx backends, 1500 QPS across 3 zones

## Sandbox Structure

```
<sandbox>/
├── vars.sh                                # Versions, names, port prefixes
├── scripts/
│   ├── cluster-setup-k3d-<variant>-everything.sh  # Full stack
│   ├── cluster-setup-k3d-naked.sh                 # Bare cluster
│   └── cluster-destroy-k3d.sh                     # Teardown
├── manifests/                             # Helm values and Kubernetes YAML
├── cluster-k3d/k3d-cluster.yaml           # The k3d config the scripts use
├── movies/                                # Symlink to the shared movies app
└── README.md
```

Variants are `kgw` and, for `istio-llb`, `amb` and `sc`.

## Common Commands

Run these from inside a sandbox directory. Setup scripts source `vars.sh` themselves.

```bash
./scripts/cluster-setup-k3d-<variant>-everything.sh   # Deploy full stack
./scripts/cluster-setup-k3d-naked.sh                  # Deploy bare cluster
./scripts/cluster-destroy-k3d.sh                      # Destroy cluster
kubectl apply -k ../../apps/movies-app/single-cluster/  # Deploy movies app
```

There's no build system or test suite. To check changes without a cluster:

```bash
shellcheck <script>
kubectl kustomize apps/movies-app/single-cluster > /dev/null
helm template <release> <chart> --version <version> -f <values>
```

## Architecture Notes

- **Install order:** cluster → Gateway API CRDs → mesh (Istio base → istiod → CNI → ztunnel) → gateway → demo apps → observability.
- **Topology:** `k3d-cluster.yaml` creates 1 server and 3 agents, labeled `topology.kubernetes.io/zone` as `central`, `west`, and `east`. Movies has required affinity on those zones.
- **Traefik:** the k3d configs set `--disable=traefik`. `istio-llb` installs upstream Traefik from a pinned chart with `--skip-crds`, because the k3s Traefik CRD chart fails once Gateway API CRDs exist.
- **Ambient:** namespaces opt in with `istio.io/dataplane-mode=ambient`. L7 policy needs a waypoint.

### Ports

Ports are `${PREFIX}${CLUSTER_NUM}`, with a zero-padded cluster number, so prefix `72` on cluster `01` is `7201`.

| Sandbox | HTTP | HTTPS | API |
|---------|------|-------|-----|
| istio-llb-sandbox | 72XX | 82XX | 92XX |
| kgateway-sandbox | 80XX | 84XX | 86XX |

Keep prefixes unique so sandboxes can run at the same time.

## Rules for Changes

- **Secrets:** `vars.sh` is tracked, so it only ever holds empty values or placeholders. Never commit a real key or license, and don't print one in output or docs.
- **Versions:** keep them in `vars.sh` and pass every one to `helm --version`. Don't leave a chart unpinned.
- **Failures:** scripts use `set -e`. Don't hide failures with `|| echo` or `|| true`.
- **Context:** in multi-cluster loops, every `kubectl` and `helm` call needs an explicit `--context` or `--kube-context`.
- **Shell:** quote variables, and keep the flow: source `vars.sh` → delete old cluster → create cluster → install → wait → print access info.
- **Waits:** Deployments have `Available`, not `Ready`. Prefer `kubectl rollout status`.
- **Testing:** a clean exit isn't enough. Send traffic through the path you changed, and read raw output before filtering it.
- **Docs:** only claim what's been run. Say "verified" with a date and versions, and don't describe a sandbox as production-ready. When a fix lands, tick it off in `PLAN.md`.
