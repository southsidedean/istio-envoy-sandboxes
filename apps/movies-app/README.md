# movies-app

**Multi-Zone Load Testing Application**

Tom Dean
Last edit: 11/4/2026

## Overview

The `movies-app` is a demo application for testing traffic distribution, locality load balancing, and service mesh features. It has one load generator and one backend in each of three zones.

## Architecture

```
frontend-central (500 QPS) ──┐
frontend-east    (500 QPS) ──┼─→ movieinfo Service (ClusterIP, port 80)
frontend-west    (500 QPS) ──┘           │
                               ┌─────────┼─────────┐
                               │         │         │
                         movieinfo-chi  -lax      -nyc
                           (central)   (west)    (east)
```

Zone placement uses required node affinity on `topology.kubernetes.io/zone`, so the cluster's nodes must carry the labels `central`, `west`, and `east`. The k3d configs in this repository set them.

## Components

**Backends** (`movieinfo-chi`, `movieinfo-lax`, `movieinfo-nyc`) run `nginx:1.27-alpine` and serve an `index.html` from a ConfigMap that names the backend. Each has a HorizontalPodAutoscaler with 1 to 3 replicas and a 25% CPU target.

**Load generators** (`frontend-central`, `frontend-east`, `frontend-west`) run `fortio/fortio:1.63.0` continuously at 500 QPS each, 1500 QPS in total, against `http://movieinfo.movies.svc.cluster.local/index.html`.

**Service:** `movieinfo` is a ClusterIP Service on port 80 that selects `app=movieinfo`.

## Deployment

Run these from `apps/movies-app`.

```bash
# One cluster, with frontends and backends together
kubectl apply -k single-cluster/

# Separate clusters for frontends and backends
kubectl apply -k multi-cluster/frontend/ --context <cluster>
kubectl apply -k multi-cluster/movieinfo/ --context <cluster>
```

The sandboxes use `single-cluster/`. `multi-cluster/` holds the same manifests split in two and isn't used or tested by any sandbox.

## Manifest Structure

```
single-cluster/
├── kustomization.yaml
├── namespace.yaml
├── frontend-{central,east,west}.yaml   # Fortio load generators
├── movieinfo-{chi,lax,nyc}.yaml        # Nginx backends and ConfigMaps
├── movieinfo-service.yaml              # ClusterIP Service
└── movieinfo-hpa.yaml                  # One HPA per backend

multi-cluster/
├── frontend/                           # Namespace and load generators
└── movieinfo/                          # Namespace, backends, Service, and HPAs
```

## Observing Traffic

```bash
kubectl get pods -n movies -o wide      # Pod placement
kubectl get endpoints -n movies movieinfo
kubectl get hpa -n movies
kubectl top pods -n movies
```

For a working locality walkthrough with Kiali and curl test pods, see [istio-llb-sandbox](../../k3d-sandboxes/istio-llb-sandbox/README.md).

## Known Issues

- All frontends share the selector `app: frontend`, and all backends share `app: movieinfo`. `kubectl logs deploy/frontend-central` can therefore return another frontend's logs, so use a pod name instead. The overlap can also skew the HPAs.
- Under Istio sidecars, the HPAs report `<unknown>` CPU.
- `movieinfo-lax` and `movieinfo-nyc` carry leftover linkerd annotations.

## Adjusting Load

Change the `-qps` value in the `args` of each `frontend-*.yaml`:

```yaml
args: ["load", "-t", "0", "-qps", "500", "http://movieinfo.movies.svc.cluster.local/index.html"]
```

## Integration with Sandboxes

This application is used by:

- **istio-llb-sandbox** - Istio locality load balancing
- **kgateway-sandbox** - Sample workload behind Kgateway

Both symlink to `single-cluster/`.

## Cleanup

```bash
kubectl delete -k single-cluster/
```

---

Tom Dean
Last updated: November 4, 2026
