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
- [ ] Merge to `main`
- [ ] Update the GitHub description and topics. Remove `gloo-gateway`, `gloo-mesh`, `kind`

Suggested description: *Scripted OSS sandboxes for Istio ambient, locality load balancing, kgateway, and kagent on k3d.*

## Phase 2: Fix and verify the OSS sandboxes

Fix each sandbox, then run it from a clean start. A sandbox only counts as verified after setup, the documented access URLs, and destroy have all worked. `ai-sandbox` and `kagent-sandbox` also need an `OPENAI_API_KEY`.

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

- [ ] `scripts/cluster-setup-k3d-kgw-everything.sh:48`: Gateway API CRDs are applied without `--context`, so clusters 02 and 03 fail under the `NUM_CLUSTERS=3` default. Add `--context` and default to 1
- [ ] Delete unused manifests: `grafana-*`, `registries`

### `istio-llb-sandbox`

- [ ] The ingress manifests use `ingressClassName: traefik`, but the k3d configs set `--disable=traefik`, so the Kiali and Grafana URLs fail. Enable Traefik in this sandbox's config
- [ ] `grafana-values.yaml` `root_url` and `kiali-values.yaml` `external_url` are hardcoded to port 9001. This sandbox uses 7201
- [ ] Remove `--registry-config` and `registries.yaml`, which use undefined `$DOCKER_USERNAME` and `$DOCKER_PASSWORD`, from the `amb`, `sc`, and `naked` scripts
- [ ] Remove or use `KIALI_VERSION`, which is unused
- [ ] README: remove the `both` references and the nonexistent `registries-bak.yaml`

### Shared across sandboxes

- [ ] kagent: `manifests/kagent-httproute.yaml` (`ai`, `kagent`) points at `kagent:80`, but chart 0.8.1 creates `kagent-ui`, `kagent-controller`, and others, with no `kagent` Service. Fix the route and the READMEs' `svc/kagent` and `deployment/kagent` commands
- [ ] Istio: Helm installs have no `--version`, so 1.30.7 installs while the scripts report 1.29.1. Pass `--version "$ISTIO_VERSION"`
- [ ] Istio: `--set defaultRevision="${ISTIO_VERSION}"` points the validation webhook at `istiod-1.29.1` with `failurePolicy: Ignore`, which effectively turns validation off. Remove it
- [ ] Pin `kagent-crds`
- [ ] Make the `movies/` copies in `ai`, `kagent`, and `kgateway` symlinks to `../../apps/movies-app/single-cluster`, as `istio-llb` does. They are byte-identical today
- [ ] Delete unused `k3d-tiny`, `k3d-small`, and `k3d-large` configs. Tiny and small lack the zones that movies requires, and most large configs disable the load balancer
- [ ] Make `vars.sh` load an ignored `.env`. `.gitignore` says to use `.env`, but nothing reads it

### `apps/movies-app`

- [ ] Deployments share the selectors `app: movieinfo` and `app: frontend`. The overlap can skew the HPAs, so add a per-Deployment label
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
| Istio | 1.29.1 (1.30.7 actually installs) | 1.30.7 |
| kagent | 0.8.1 | 0.10.4 |
| kgateway | 2.2.2 | 2.5.0 |
| agentgateway | 1.0.1 | 1.0.1 |
| agentregistry | 0.3.2 | 0.4.0 |
| Gateway API | v1.5.1 | v1.7.0 |
| Kiali | v2.23.0 (variable unused) | v2.34.1 |
| k3s | v1.35.2 | v1.35.5 (k3d v5.9.0 default) |
