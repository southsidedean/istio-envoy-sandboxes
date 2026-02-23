# movies-app

**Multi-Zone Load Testing Application**

Tom Dean
Last edit: 2/23/2026

## Overview

The `movies-app` is a demo application used across multiple sandboxes for testing traffic distribution, locality load balancing, and service mesh features. It simulates a multi-zone deployment with load generators and backends distributed across geographic regions.

## Architecture

```
Frontend (Fortio Load Generators):
  - frontend-central (500 QPS) ──┐
  - frontend-east (500 QPS)    ──┼─→ movieinfo Service (ClusterIP)
  - frontend-west (500 QPS)    ──┘           │
                                     ┌────────┼────────┐
                                     │        │        │
                              movieinfo-chi  -lax  -nyc
                              (central)    (west)  (east)
```

## Components

### Backend Services

Three nginx instances serving static content:
- **movieinfo-chi** - Central zone (Chicago)
- **movieinfo-lax** - West zone (Los Angeles)
- **movieinfo-nyc** - East zone (New York)

Each backend:
- Runs nginx serving `index.html`
- Labeled with `topology.kubernetes.io/zone`
- Configured with HorizontalPodAutoscaler (1-3 replicas)
- CPU target: 25%

### Frontend Load Generators

Three Fortio instances generating continuous traffic:
- **frontend-central** - 500 QPS
- **frontend-east** - 500 QPS
- **frontend-west** - 500 QPS

**Total traffic: 1500 QPS**

Each frontend:
- Runs Fortio load testing tool
- Labeled with matching zone affinity
- Continuously requests `http://movieinfo:8080/index.html`

### Service

- **Name**: movieinfo
- **Type**: ClusterIP
- **Port**: 8080
- **Selectors**: app=movieinfo
- **Endpoints**: All 3 backends (chi, lax, nyc)

## Deployment Variants

### Single Cluster

Located in `single-cluster/`:

```bash
# Deploy to current cluster
kubectl apply -k single-cluster/
```

Includes:
- All 6 pods (3 backends + 3 frontends)
- movieinfo service
- HPA configurations
- Zone labels for locality testing

### Multi-Cluster

Located in `multi-cluster/`:

```bash
# Deploy across multiple clusters
kubectl apply -k multi-cluster/ --context cluster-01
kubectl apply -k multi-cluster/ --context cluster-02
```

Designed for:
- Multi-cluster service mesh testing
- Cross-cluster traffic distribution
- Federated service discovery

## Use Cases

### Locality Load Balancing

Test zone-aware traffic distribution:

```bash
# Deploy the app
kubectl apply -k single-cluster/

# Check pod zones
kubectl get pods -n movies --show-labels

# Exec into frontend-central
kubectl exec -n movies deploy/frontend-central -- sh

# Generate traffic (should prefer chi backend)
curl http://movieinfo:8080/index.html
```

### Service Mesh Traffic Observation

Monitor traffic patterns:

```bash
# View service endpoints
kubectl get endpoints -n movies movieinfo

# Check traffic distribution in Kiali/Grafana
# Traffic should prefer same-zone backends
```

### Load Testing

Stress test service mesh:

```bash
# Deploy with HPA enabled
kubectl apply -k single-cluster/

# Watch autoscaling
kubectl get hpa -n movies --watch

# Monitor resource usage
kubectl top pods -n movies
```

### Multi-Zone Failover

Test zone failure scenarios:

```bash
# Scale down central zone backend
kubectl scale deploy/movieinfo-chi -n movies --replicas=0

# Observe traffic shift to lax/nyc backends
# Frontend-central should failover to other zones
```

## Configuration

### Zone Labels

Pods are labeled with Kubernetes topology labels:

```yaml
topology.kubernetes.io/zone: central  # or west, east
topology.kubernetes.io/region: us     # all pods
```

### Load Generator Settings

Fortio is configured with:
- QPS: 500 per frontend (1500 total)
- Connections: 100
- Target: http://movieinfo:8080/index.html
- Duration: Continuous (infinity loop)

### HPA Settings

```yaml
minReplicas: 1
maxReplicas: 3
targetCPUUtilizationPercentage: 25
```

## Observing Traffic

### Using kubectl

```bash
# View service endpoints
kubectl get endpoints -n movies movieinfo -o yaml

# Check pod distribution
kubectl get pods -n movies -o wide

# View logs from load generators
kubectl logs -n movies deploy/frontend-central

# Monitor HPA status
kubectl get hpa -n movies
```

### Using Service Mesh UI (Kiali)

1. Access Kiali (typically http://localhost:9001/kiali)
2. Navigate to Graph view
3. Select "movies" namespace
4. Observe traffic distribution between frontends and backends
5. Check if traffic stays within zones (locality preference)

### Using Metrics (Grafana)

1. Access Grafana (typically http://localhost:9001/grafana)
2. View Istio dashboards
3. Filter by "movies" namespace
4. Observe request rates and latencies
5. Compare cross-zone vs same-zone traffic

## Manifest Structure

```
single-cluster/
├── kustomization.yaml          # Kustomize config
├── deployment-backends.yaml    # 3 nginx backends
├── deployment-frontends.yaml   # 3 Fortio frontends
├── service.yaml                # movieinfo ClusterIP service
└── hpa.yaml                    # HorizontalPodAutoscaler

multi-cluster/
├── kustomization.yaml
└── [cluster-specific configs]
```

## Troubleshooting

### Pods Not Starting

```bash
# Check pod status
kubectl get pods -n movies

# View pod events
kubectl describe pod <pod-name> -n movies

# Check logs
kubectl logs -n movies <pod-name>
```

### No Traffic Generation

```bash
# Check if frontends are running
kubectl get pods -n movies -l tier=frontend

# View Fortio logs
kubectl logs -n movies deploy/frontend-central

# Test service connectivity
kubectl exec -n movies deploy/frontend-central -- curl -v http://movieinfo:8080/index.html
```

### HPA Not Scaling

```bash
# Check HPA status
kubectl get hpa -n movies
kubectl describe hpa movieinfo-hpa -n movies

# Verify metrics-server is running
kubectl get pods -n kube-system | grep metrics

# Check CPU utilization
kubectl top pods -n movies
```

### Traffic Not Staying in Zone

```bash
# Verify zone labels
kubectl get pods -n movies --show-labels | grep topology

# Check service mesh configuration
# For Istio: verify DestinationRule locality settings
kubectl get destinationrule -n movies

# View endpoint distribution
kubectl get endpoints -n movies movieinfo -o yaml
```

## Advanced Usage

### Adjust Load

Modify QPS in frontend deployments:

```yaml
# In deployment-frontends.yaml, change -qps flag
args:
  - load
  - -qps=1000  # Increase from 500
  - -c=100
  - -t=0s
  - http://movieinfo:8080/index.html
```

### Add More Zones

Create additional backends:

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: movieinfo-sea
  labels:
    zone: pacific-northwest
spec:
  template:
    metadata:
      labels:
        topology.kubernetes.io/zone: pacific-northwest
```

### Custom Content

Replace `index.html` in backends:

```bash
# Create ConfigMap with custom content
kubectl create configmap movieinfo-content \
  --from-file=index.html=./my-content.html \
  -n movies

# Mount in nginx pods (modify deployment)
```

## Integration with Sandboxes

This application is used by:

- **istio-llb-sandbox** - Istio locality load balancing
- **gme-llb-sandbox** - Gloo Mesh locality features
- **ge-llb-sandbox** - Gloo Edge multi-zone routing
- **ai-sandbox** - Service mesh testing with AI workloads

Each sandbox symlinks to this shared application directory.

## Cleanup

```bash
# Delete from current cluster
kubectl delete -k single-cluster/

# Or delete namespace
kubectl delete namespace movies
```

---

Tom Dean
Last updated: February 23, 2026
