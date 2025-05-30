# istio-llb-sandboxes

## Tom Dean
## Last edit: 5/15/25

## *INITIAL DRAFT - UNDER DEVELOPMENT*

## Introduction

Introduction, explain zones and why keeping traffic in zone is important.

## Prerequisites

If you don't have the following, you're gonna have a bad time:

- [`k3d`](https://k3d.io)
- [Docker](https://www.docker.com/get-started/)
- [Helm](https://helm.sh/docs/intro/install/)
- The `bash` (or equivalent) shell
- [The `kubectl` command](https://kubernetes.io/docs/tasks/tools/)
- [The `kubectx` command](https://github.com/ahmetb/kubectx)
- [The `curl` command](https://curl.se/download.html)
- The `watch` command
- The contents of [this](https://github.com/southsidedean/istio-envoy-sandboxes/tree/main) GitHub repository
  - We're going to use the sandbox [here](https://github.com/southsidedean/istio-envoy-sandboxes/tree/main/k3d-sandboxes/istio-llb-sandbox)
- Internet access to pull containers

Everything else is self-contained, just run the script to create the cluster(s).

## About the Sandbox

I've been educating myself on **Locality Load Balancing**, and keeping traffic in-zone in **Istio** in general, and have put together an **OSS Istio** sandbox, with scripts to deploy both **sidecar** and **ambient**.  Once the cluster is deployed, you can observe traffic with the in-cluster **Kiali** instance(`localhost:9001/kiali`, you can use IP address as well for you headless k3d users) and use the in-cluster **Grafana** if you wish as well (`localhost:9001/grafana`).  The Istio Grafana dashboards have been deployed alongside Grafana.

All the Helm `values` files and other YAML manifests live in the `manifest` directory:

```bash
manifests
├── curl-central.yaml
├── curl-east.yaml
├── curl-west.yaml
├── grafana-ingress.yaml
├── grafana-values.yaml
├── istio-cni-values.yaml
├── istiod-values.yaml
├── kiali-ingress.yaml
├── kiali-values.yaml
├── movies-destination-rule.yaml
├── movies-waypoint.yaml
├── registries-bak.yaml
└── registries.yaml
```

If you want to tweak the variables for the scripts, look in the `vars.sh` file.

You should use the included scripts to create one or two clusters for local testing:

```bash
scripts
├── cluster-destroy-k3d-both.sh
├── cluster-destroy-k3d.sh
├── cluster-setup-k3d-amb-everything.sh
├── cluster-setup-k3d-both-everything.sh
├── cluster-setup-k3d-naked.sh
└── cluster-setup-k3d-sc-everything.sh
```

Several options exist for deploying cluster(s):

- A *single cluster* with Istio in sidecar mode (`cluster-setup-k3d-sc-everything.sh`)
- A *single cluster* with Istio in Ambient mode (`cluster-setup-k3d-amb-everything.sh`)
- *Two clusters*, one with Istio in sidecar mode, one with Ambient mode (`cluster-setup-k3d-both-everything.sh`)
- A "naked" cluster, no Istio/Prometheus/Kiali/Grafana, but with topology zones (`cluster-setup-k3d-naked.sh`)
  - You'll need to deploy Istio and the "extras" yourself
  - Great for building your own!

Two scripts tear down your cluster(s).  Use the `both` script for two-cluster deployments.

## Keeping Traffic In-Zone Using Locality Load Balancing (LLB) With Sidecars

First, you're going to need a cluster.  Starting in the root of the `istio-envoy-sandboxes` repository you cloned, change to the `k3d-sandboxes/istio-llb-sandbox` directory, and run your commands from there.

```bash
cd k3d-sandboxes/istio-llb-sandbox
./scripts/cluster-setup-k3d-sc-everything.sh
```

This will deploy a single `k3d` cluster with Istio deployed in sidecar mode, and the `movies` app deployed.  Open [`http://localhost:9001/kiali`](http://localhost:9001/kiali) in your browser, and log in with the token provided at the end of the script output.  If you need to retrieve a fresh token, use `kubectl -n istio-system create token kiali`.  You can use the in-cluster **Grafana** if you wish as well (`localhost:9001/grafana`).

In Kiali, navigate to **Traffic Graph**, set your interval and refresh rates to minimums, and select the **Workload Graph** from the drop down.  In the **Display** drop-down, uncheck `Service Nodes`, and check `Traffic Animation` and `Security`.  This should give you a nice representation of traffic flow.  Feel free to drag items around as you see fit.

In order to engage **Locality Load Balancing**, apply the `DestinationRule` to the cluster:

```bash
kubectl apply -f manifests/movies-destination-rule.yaml
```

Hint: If you'd like to reverse what you just did, you can run:

```bash
kubectl delete -f manifests/movies-destination-rule.yaml
```

If you're patient (set the interval and refresh to the lowest values), you'll see traffic snap into zone.  You can toggle the `DestinationRule` on and off and you'll see the traffic flow change.

## Ambient: Keeping Traffic In-Zone

Again, you're going to need a cluster.  Starting in the root of the `istio-envoy-sandboxes` repository you cloned, change to the `k3d-sandboxes/istio-llb-sandbox` directory, and run your commands from there.

```bash
cd k3d-sandboxes/istio-llb-sandbox
./scripts/cluster-setup-k3d-amb-everything.sh
```

This will deploy a single `k3d` cluster with Istio deployed in Ambient mode, and the `movies` app deployed.  Open [`http://localhost:9001/kiali`](http://localhost:9001/kiali) in your browser, and log in with the token provided at the end of the script output.  If you need to retrieve a fresh token, use `kubectl -n istio-system create token kiali`.  You can use the in-cluster **Grafana** if you wish as well (`localhost:9001/grafana`).

In Kiali, navigate to **Traffic Graph**, set your interval and refresh rates to minimums, and select the **Workload Graph** from the drop down.  In the **Display** drop-down, uncheck `Service Nodes`, and check `Traffic Animation`, `Waypoint Proxies` and `Security`.  This should give you a nice representation of traffic flow.  Feel free to drag items around as you see fit.

A few things we need to do to keep traffic in-zone.

First, we're going to need to put a waypoint proxy into each zone.  A freshly-deployed cluster only has a single waypoint proxy for our `movies` application, so let's scale up to three waypoints, one for each of the three zones in our cluster.  Let's take a look.

```bash
kubectl get all -n movies -o wide
```

We see a single waypoint.  Scale it to three.

```bash
kubectl scale deployment waypoint --replicas=3 -n movies
```

Checking our work:

```bash
kubectl get all -n movies -o wide
```

We see three waypoints now, one in each zone.  This is because the waypoints are configured to use `topologySpreadConstraints` to make sure you have at least one waypoint in each of the three zones.

Now that we've added two new waypoints into the mix, we should restart our `ztunnel` daemonset to pick these up.

```bash
kubectl rollout restart daemonset ztunnel -n istio-system
```

In order to tell Istio that you'd prefer to keep traffic in-zone, you will need to apply the `networking.istio.io/traffic-distribution=PreferClose` annotation to both the `waypoint` and `movieinfo` services.

```bash
kubectl annotate service waypoint networking.istio.io/traffic-distribution=PreferClose -n movies --overwrite
kubectl annotate service movieinfo networking.istio.io/traffic-distribution=PreferClose -n movies --overwrite
```

Hint: If you'd like to undo what you just did, you can run:

```bash
kubectl annotate service waypoint networking.istio.io/traffic-distribution=PreferClose- -n movies --overwrite
kubectl annotate service movieinfo networking.istio.io/traffic-distribution=PreferClose- -n movies --overwrite
```

If you're patient (set the interval and refresh to the lowest values), you'll see traffic snap into zone.  There will still only be one waypoint in your traffic graph in Kiali, as this represents the `waypoint` deployment, not the individual waypoint proxies.

## Verifying Traffic Stays In-Zone

So, now that everything is deployed, and Kiali shows traffic flow is in-zone, how can we be sure traffic is staying in-zone?

```bash
kubens movies
```

```bash
kubectl get pods -o wide
```

```bash
for zone in east central west ; do kubectl apply -f manifests/curl-${zone}.yaml ; done
```

```bash
kubectl get pods -o wide
```

```bash
for curlpod in `kubectl get pods -o wide | grep curl | awk {'print $1'}` ; do echo ; echo "Logs for "$curlpod":" ; echo ; kubectl logs $curlpod | grep Movie ; echo ; done
```

What does it look like if we remove the mechanisms keeping traffic in-zone?

```bash
for zone in east central west ; do kubectl delete deploy curl-$zone ; done
```

```bash
kubectl get pods -o wide
```

Now, perform the steps to remove the mechanisms keeping traffic in-zone.  You can find the proper commands for your Istio data plane deployment mode in prior sections.

```bash
kubectl get pods -o wide
```

```bash
for zone in east central west ; do kubectl apply -f manifests/curl-${zone}.yaml ; done
```

```bash
kubectl get pods -o wide
```

```bash
for curlpod in `kubectl get pods -o wide | grep curl | awk {'print $1'}` ; do echo ; echo "Logs for "$curlpod":" ; echo ; kubectl logs $curlpod | grep Movie ; echo ; done
```

```bash

```

```bash

```

```bash

```

```bash

```

```bash

```

```bash

```

```bash

```

## Stress Testing - FUTURE

Need to add a section with some basic stress tests, see how the different implementations react.

Tests:

- Scale up clients in one zone
- Kill one of the `movieinfo` deployments


```bash

```

```bash

```

```bash

```

```bash

```

```bash

```

```bash

```

```bash

```



## Summary

I still need to flesh this out a bit, and do more observability using metrics and Grafana to provide more evidence that traffic remains in-zone.  Still, this will get you up and running for now.
