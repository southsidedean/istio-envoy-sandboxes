# istio-llb-sandboxes

## DRAFT - UNDER DEVELOPMENT

Ok, I've been educating myself on Locality Load Balancing, and keeping traffic in-zone in Istio in general, and have put together an OSS Istio sandbox, with scripts to deploy both sidecar and ambient.  Once the sidecar cluster is deployed, you can observe traffic with the in-cluster Kiali (`localhost:9001/kiali`, you can use IP address as well for you headless k3d users) and use the in-cluster Grafana if you wish as well (`localhost:9001/grafana`).  Apply the `DestinationRule` to the sidecar cluster and, if you're patient (set the interval and refresh to their lowest values), you'll see traffic snap into zone.

Ambient is a work in progress, still trying to get waypoints working with topologySpreadConstraints.  All the Helm values files are in the manifest directory.  I'm applying the topologySpreadConstraints to the Helm installation of istiod through the istio-values.yaml file.  Between smashing through my Dockerhub pull limits mid-day yesterday and just looking at it for a long time, I'm sure I'm missing something basic that another set of eyes might see.

Thanks!