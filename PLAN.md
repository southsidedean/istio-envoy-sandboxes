# Cleanup Plan

Tom Dean
Last edit: 11/4/2026

## Goal

Make this repository presentable and useful without committing ongoing resources to it. It becomes a small, OSS-only set of local sandboxes that do what their docs say.

## How these findings were produced

The November 2026 review read every tracked file, ran `shellcheck`, built the Kustomize trees, and rendered the pinned Helm charts. **No cluster was started.** Runtime failures below are expected from that reading and still need to be confirmed in Phase 2.

## Decisions

| Topic | Decision |
|---|---|
| Archive | Tag and release the untouched repository before any cleanup |
| Git history | Leave as is, with no rewrite or force-push |
| Solo.io | No contact and no dependency on Solo access |
| License-only sandboxes | Cull. Only OSS sandboxes stay |
| `gloo-gw-sandbox`, `istio-sandbox` | Cull |
| Azure, GCP, kind | Cull. These were empty placeholders |
| AWS EKS sandbox | Keep as a labeled exception: unverified, stale, needs a Solo license. Do not run it |
| `istio-llb` `both` scripts | Delete. They were an unusable Gloo Mesh copy |

## Phase 0: Archive (done)

- [x] Annotated tag `pre-oss-cleanup-2026-11` on `a978068`
- [x] [GitHub release](https://github.com/southsidedean/istio-envoy-sandboxes/releases/tag/pre-oss-cleanup-2026-11)

Everything removed below, including the Gloo screenshots, is still available from that tag.

## Phase 1: Cull and document (this branch)

- [x] Remove `Azure/`, `GCP/`, `kind-sandboxes/`
- [x] Remove `k3d-sandboxes/{ent-ai,ent-kgateway,gme-llb,ge-llb,gloo-gw,glooe-gw,istio}-sandbox`
- [x] Remove the `istio-llb` `both` setup and destroy scripts
- [x] Remove unused license and Gloo variables from `ai`, `kagent`, and `istio-llb` `vars.sh`
- [x] Label the AWS sandbox unverified and stale
- [x] Rewrite the root and `k3d-sandboxes` READMEs for the remaining content, listing known issues
- [x] Rewrite root `CLAUDE.md`; remove the stale changelog from the AWS `CLAUDE.md`
- [x] Write this plan
- [x] Merge to `main`
- [x] Update the GitHub description and topics. Remove `gloo-gateway`, `gloo-mesh`, `kind`

Suggested description: *Scripted OSS sandboxes for Istio ambient, locality load balancing, kgateway, and kagent on k3d.*

## Phase 2: Fix and verify the OSS sandboxes

Fix each sandbox, then run it from a clean start. A sandbox only counts as verified after setup, the documented access URLs, and destroy have all worked. `ai-sandbox` and `kagent-sandbox` also need an `OPENAI_API_KEY`.

| Sandbox | Status |
|---|---|
| `kgateway-sandbox` | Verified 11/4/2026 |
| `istio-llb-sandbox` | Verified 11/4/2026 in ambient, sidecar, and naked modes |
| `kagent-sandbox` | Not started |
| `ai-sandbox` | Not started |

### `ai-sandbox`

- [ ] `scripts/cluster-setup-k3d-ai-everything.sh:93`: `kubectl wait --for=condition=Ready deployment/istiod` targets a condition Deployments don't have. Use `Available` or `rollout status`
- [ ] `:184`: the waypoint is applied before the Gateway API CRDs at `:198`. Swap the order
- [ ] `:173`, `:178`: `istio.io/use-waypoint=auto` doesn't match the Gateway named `waypoint`, so the waypoint is probably bypassed
- [ ] `:290`: `|| echo` hides agentregistry install failures
- [ ] `:328`: quoting error (SC2027)
- [ ] Remove agentregistry. Chart 0.3.2 won't render without an external PostgreSQL with pgvector
- [ ] Agentgateway 1.0.1: the values keys `mcp`, `a2a`, `observability`, and `service` aren't in the chart, and the route targets port 8080 while the Service exposes 9978, 9093, and 9092. Install the controller only, with no route
- [ ] `manifests/kagent-httproute.yaml`: see the shared kagent item below
- [ ] Delete `scripts/cluster-setup-k3d-kagent-everything.sh`, a near-duplicate of the `kagent-sandbox` script
- [ ] Delete unused manifests: `grafana-ingress`, `grafana-values`, `kagent-values`, `registries`
- [ ] README: fix `kagent-` names and invented API examples; remove "Kubernetes CRD-based storage", "Full observability", and "production-like"

### `kagent-sandbox`

- [ ] Pin the kagent chart. `KAGENT_VERSION` is set but unused
- [ ] Delete unused manifests: `grafana-ingress`, `grafana-values`, `kagent-values`, `registries`
- [ ] README: check the `Agent` CRD example against the installed chart. It's probably outdated

### `kgateway-sandbox`

- [x] `scripts/cluster-setup-k3d-kgw-everything.sh`: Gateway API CRDs were applied without `--context`, so extra clusters failed under the `NUM_CLUSTERS=3` default. Added `--context` and defaulted to 1. Also tested with 2 clusters
- [x] Wait for the Gateway and the movies Deployments before reporting success
- [x] Delete unused manifests: `grafana-*`, `registries`
- [x] Replace the `movies/` copy with a symlink, and delete unused k3d configs

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

Verified: Istio 1.29.1, Kiali 2.23.0, Grafana chart 10.5.15, Traefik chart 39.0.2, Gateway API v1.5.1, k3s v1.35.2-k3s1, k3d 5.9.0, Helm 4.3.1. In both modes, `/kiali` and `/grafana` returned 200, and traffic moved from mixed to 9 of 9 curl pods in-zone once the README's locality steps were applied. Removing the `DestinationRule` restored mixed traffic. The Kiali graph itself wasn't checked in a browser.

### Shared across sandboxes

- [ ] kagent: `manifests/kagent-httproute.yaml` (`ai`, `kagent`) points at `kagent:80`, but chart 0.8.1 creates `kagent-ui`, `kagent-controller`, and others, with no `kagent` Service. Fix the route and the READMEs' `svc/kagent` and `deployment/kagent` commands
- [ ] Istio (`ai` only, `istio-llb` is done): Helm installs have no `--version`, so 1.30.7 installs while the scripts report 1.29.1. Pass `--version "$ISTIO_VERSION"`
- [ ] Istio (`ai` only, `istio-llb` is done): `--set defaultRevision="${ISTIO_VERSION}"` points the validation webhook at `istiod-1.29.1` with `failurePolicy: Ignore`, which effectively turns validation off. Remove it
- [ ] Pin `kagent-crds`
- [ ] Make the `movies/` copies in `ai` and `kagent` symlinks to `../../apps/movies-app/single-cluster`, as `istio-llb` and `kgateway` do. They are byte-identical today
- [ ] Delete unused `k3d-tiny`, `k3d-small`, `k3d-medium`, and `k3d-large` configs in `ai` and `kagent`. Tiny and small lack the zones that movies requires, and most large configs disable the load balancer
- [ ] Multi-cluster teardown leaves the shared Docker network (seen with `kgw-network`). It's harmless, and `docker network rm` clears it
- [ ] Make `vars.sh` load an ignored `.env`. `.gitignore` says to use `.env`, but nothing reads it

### `apps/movies-app`

- [ ] Deployments share the selectors `app: movieinfo` and `app: frontend`. The overlap can skew the HPAs and confirmed misdirects `kubectl logs deploy/frontend-central` to another frontend's pod. Add a per-Deployment label
- [ ] Under sidecars, the HPAs report `<unknown>` CPU. Find out why
- [ ] Remove stale linkerd annotations from `lax` and `nyc`
- [ ] README: wrong port (8080, actual 80), wrong `tier=frontend` selector, and a file layout that doesn't exist

### `scripts/yaml-collector.sh`

- [ ] `:45`: `rm -rf manifests` in the current directory deletes a sandbox's manifests if run from inside one. Use `mktemp`
- [ ] `:18`: the default filter collects Solo resources only. Choose an OSS-appropriate default

### Repository

- [x] Add an MIT `LICENSE` file. The README had claimed MIT without one
- [ ] Record the versions that passed in each sandbox README

## Phase 3: AWS sandbox (not scheduled)

Nothing here runs until someone chooses to return to it. If it stays unrun, either keep the label or cull it. The tag preserves it either way.

Known issues:

- Requires Solo Istio 1.25.3, `REPO_KEY`, and `SOLO_ISTIO_LICENSE_KEY`, so it can't run without a Solo license
- EKS 1.33 is probably past standard support (not checked)
- README says there are 4 SPIRE registrations (there are 3), mentions the deleted `istio-values.yaml`, and gives SPIRE 0.24.1 (`vars.sh` has 0.24.2)
- `cluster-destroy-eks.sh` doesn't delete the kubectl context
- Setup prints the Grafana password
- Unused variables: `KUBECTX_NAME_PREFIX`, `ISTIO_NAMESPACE`, `ISTIOCTL_VERSION`, `SPIRE_APP_VERSION`

Moving it to upstream Istio would be a separate project. Whether upstream supports this SPIRE integration hasn't been checked.

## Out of scope

- New cloud targets
- A shared script library
- CI that starts clusters
- Keeping up with every release. Update a version only when it's tested

## Versions

Pinned today, against the latest seen during the review. Upgrade only during Phase 2 verification.

| Component | Pinned | Latest seen |
|---|---|---|
| Istio | 1.29.1 (`ai` actually installs 1.30.7) | 1.30.7 |
| kagent | 0.8.1 | 0.10.4 |
| kgateway | 2.2.2 | 2.5.0 |
| agentgateway | 1.0.1 | 1.0.1 |
| agentregistry | 0.3.2 | 0.4.0 |
| Gateway API | v1.5.1 | v1.7.0 |
| Kiali | 2.23.0 | v2.34.1 |
| Grafana chart | 10.5.15 | Not compared |
| Traefik chart | 39.0.2 | Not compared |
| k3s | v1.35.2 | v1.35.5 (k3d v5.9.0 default) |
