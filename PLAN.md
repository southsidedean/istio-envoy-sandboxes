# Cleanup Plan

Tom Dean
Last edit: 11/4/2026

## Status

**Cleanup complete as of 11/4/2026.** Nothing is scheduled. The repository is two verified OSS sandboxes and a shared app, and everything removed is at tag `pre-oss-cleanup-2026-11`.

Known and left open, none of them blocking:

- `apps/movies-app`: overlapping selectors, HPAs reporting `<unknown>` CPU under sidecars, and leftover linkerd annotations
- `kgateway-sandbox`: multi-cluster teardown leaves a Docker network behind
- `istio-llb-sandbox`: `NUM_CLUSTERS` above 1 isn't supported

## Goal

Make this repository presentable and useful without committing ongoing resources to it: two OSS-only local sandboxes, Istio locality load balancing and Kgateway, that do what their docs say.

## How these findings were produced

The November 2026 review read every tracked file, ran `shellcheck`, built the Kustomize trees, and rendered the pinned Helm charts. **No cluster was started.** The Phase 2 runs that followed confirmed or corrected those findings for the sandboxes that remain.

## Decisions

| Topic | Decision |
|---|---|
| Archive | Tag and release the untouched repository before any cleanup |
| Git history | Leave as is, with no rewrite or force-push |
| Solo.io | No contact and no dependency on Solo access |
| License-only sandboxes | Cull. Only OSS sandboxes stay |
| `gloo-gw-sandbox`, `istio-sandbox` | Cull |
| `ai-sandbox`, `kagent-sandbox` | Cull. No further work planned on them |
| Azure, GCP, kind | Cull. These were empty placeholders |
| AWS EKS sandbox | Cull. It needs a Solo license, so it can't be tested |
| `scripts/yaml-collector.sh` | Delete. It could remove a sandbox's manifests, and no sandbox uses it |
| `istio-llb` `both` scripts | Delete. They were an unusable Gloo Mesh copy |

## Phase 0: Archive (done)

- [x] Annotated tag `pre-oss-cleanup-2026-11` on `a978068`
- [x] [GitHub release](https://github.com/southsidedean/istio-envoy-sandboxes/releases/tag/pre-oss-cleanup-2026-11)

Everything removed below, including the Gloo screenshots, is still available from that tag.

## Phase 1: Cull and document (done)

- [x] Remove `Azure/`, `GCP/`, `kind-sandboxes/`
- [x] Remove `k3d-sandboxes/{ent-ai,ent-kgateway,gme-llb,ge-llb,gloo-gw,glooe-gw,istio}-sandbox`
- [x] Remove the `istio-llb` `both` setup and destroy scripts
- [x] Remove unused license and Gloo variables from `ai`, `kagent`, and `istio-llb` `vars.sh`
- [x] Remove the AWS sandbox and `scripts/yaml-collector.sh`
- [x] Rewrite the root and `k3d-sandboxes` READMEs for the remaining content, listing known issues
- [x] Rewrite root `CLAUDE.md`
- [x] Write this plan
- [x] Merge to `main`
- [x] Update the GitHub description and topics. Remove `gloo-gateway`, `gloo-mesh`, `kind`, `agentgateway`, `ai-agents`, `kagent`, `eks`

## Phase 2: Fix and verify the OSS sandboxes

Fix each sandbox, then run it from a clean start. A sandbox only counts as verified after setup, the documented access URLs, and destroy have all worked.

| Sandbox | Status |
|---|---|
| `kgateway-sandbox` | Verified 11/4/2026 |
| `istio-llb-sandbox` | Verified 11/4/2026 in ambient, sidecar, and naked modes |

### `kgateway-sandbox`

- [x] `scripts/cluster-setup-k3d-kgw-everything.sh`: Gateway API CRDs were applied without `--context`, so extra clusters failed under the `NUM_CLUSTERS=3` default. Added `--context` and defaulted to 1. Also tested with 2 clusters
- [x] Wait for the Gateway and the movies Deployments before reporting success
- [x] Delete unused manifests: `grafana-*`, `registries`
- [x] Replace the `movies/` copy with a symlink, and delete unused k3d configs
- [ ] Multi-cluster teardown leaves the shared Docker network (seen with `kgw-network`). It's harmless, and `docker network rm` clears it

Verified: kgateway 2.2.2, Gateway API v1.5.1, k3s v1.35.2-k3s1. With no route, `localhost:8001` returns 404. With a temporary HTTPRoute, requests reached all three backends.

### `istio-llb-sandbox`

- [x] The ingress manifests need Traefik, but the k3d config sets `--disable=traefik`. Enabling the k3s Traefik isn't an option: its CRD chart fails once the Gateway API CRDs exist, which breaks ambient mode. The scripts now install upstream Traefik from a pinned chart, with `--skip-crds` and the CRD provider off
- [x] The ingress manifests set both the `kubernetes.io/ingress.class` annotation and `ingressClassName`. Removed the annotation
- [x] `grafana-values.yaml` `root_url` and `kiali-values.yaml` `external_url` were hardcoded to port 9001. Changed to 7201
- [x] Remove `--registry-config` and `registries.yaml`, which used undefined `$DOCKER_USERNAME` and `$DOCKER_PASSWORD`, from the `amb`, `sc`, and `naked` scripts
- [x] Pin the Istio, Kiali, Grafana, and Traefik charts, and remove `--set defaultRevision`
- [x] Replace the invalid `kubectl rollout status deployment` call in the ambient script
- [x] `movies-destination-rule.yaml`: `maxRequestsPerConnection: 1` overloaded the backends under sidecars, causing resets, a liveness restart, and traffic leaving the zone. Removed it
- [x] Remove the `istioctl` PATH leftovers and Grafana's `--debug`
- [x] Delete unused k3d configs. `k3d-cluster.yaml` was a symlink to `k3d-medium.yaml` and is now the real file
- [x] README: remove the `both` references and the nonexistent `registries-bak.yaml`
- [ ] The setup scripts create `NUM_CLUSTERS` clusters but install only on the first, because their `kubectl` and `helm` calls have no explicit context. Only the default of 1 was tested

Verified: Istio 1.29.1, Kiali 2.23.0, Grafana chart 10.5.15, Traefik chart 39.0.2, Gateway API v1.5.1, k3s v1.35.2-k3s1, k3d 5.9.0, Helm 4.3.1. In both modes, `/kiali` and `/grafana` returned 200, and traffic moved from mixed to 9 of 9 curl pods in-zone once the README's locality steps were applied. Removing the `DestinationRule` restored mixed traffic. The Kiali graph itself wasn't checked in a browser.

### `apps/movies-app`

The open items here are known and left as is. They change the app both verified sandboxes depend on, so fixing them means re-running both.

- [ ] Deployments share the selectors `app: movieinfo` and `app: frontend`. The overlap can skew the HPAs and confirmed misdirects `kubectl logs deploy/frontend-central` to another frontend's pod. Add a per-Deployment label
- [ ] Under sidecars, the HPAs report `<unknown>` CPU. Find out why
- [ ] Remove stale linkerd annotations from `lax` and `nyc`
- [x] README: rewritten from the manifests. It had a wrong port, labels, selectors, Fortio settings, HPA names, and file layout

### Repository

- [x] Add an MIT `LICENSE` file. The README had claimed MIT without one
- [x] Record the versions that passed in each sandbox README

## Out of scope

- New cloud targets
- A shared script library
- CI that starts clusters
- Keeping up with every release. Update a version only when it's tested

## Versions

Pinned today, against the latest seen during the review. Upgrade only when re-verifying.

| Component | Pinned | Latest seen |
|---|---|---|
| Istio | 1.29.1 | 1.30.7 |
| kgateway | 2.2.2 | 2.5.0 |
| Gateway API | v1.5.1 | v1.7.0 |
| Kiali | 2.23.0 | v2.34.1 |
| Grafana chart | 10.5.15 | Not compared |
| Traefik chart | 39.0.2 | Not compared |
| k3s | v1.35.2 | v1.35.5 (k3d v5.9.0 default) |
