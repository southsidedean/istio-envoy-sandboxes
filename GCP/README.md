# GCP Sandboxes

**Google Cloud GKE Testing Environments**

Tom Dean
Last edit: 2/23/2026

## Overview

This directory will contain GCP GKE (Google Kubernetes Engine) deployment sandboxes for testing service mesh, API gateway, and AI agent technologies in Google Cloud environments.

## Status

**Coming Soon** - GCP sandboxes are planned for future development.

## Planned Sandboxes

Future GCP-based environments may include:

- **GKE with Istio Ambient** - Service mesh on managed Kubernetes
- **GKE with Gloo Mesh** - Multi-cluster service mesh across regions
- **GKE with Anthos Service Mesh** - Google's managed Istio
- **GKE with Cloud Service Mesh** - Google Cloud's service mesh solution
- **GKE Autopilot with service mesh** - Fully managed Kubernetes
- **Multi-region GKE** - Cross-region deployments

## Current Alternatives

While GCP sandboxes are under development, you can:

1. **Use local k3d sandboxes** - Test locally before GKE deployment
   - See [k3d-sandboxes](../k3d-sandboxes/)

2. **Use AWS EKS sandbox** - Similar cloud patterns on AWS
   - See [AWS/eks-spiffe-spire-istio-sandbox](../AWS/eks-spiffe-spire-istio-sandbox/)

3. **Manual GKE deployment** - Adapt k3d scripts for GKE
   - Create GKE cluster with gcloud CLI
   - Apply same Helm charts and manifests
   - Adjust for GCP LoadBalancer services

## Prerequisites (for future GKE sandboxes)

When GCP sandboxes are available, you'll need:

- [gcloud CLI](https://cloud.google.com/sdk/docs/install) - Google Cloud command-line tools
- [kubectl](https://kubernetes.io/docs/tasks/tools/) - Kubernetes CLI
- [kubectx](https://github.com/ahmetb/kubectx) - Context switching
- [Helm](https://helm.sh/) - Chart installations
- GCP project with GKE API enabled
- Appropriate IAM permissions

## Quick Start Pattern (Future)

Expected workflow for GCP sandboxes:

```bash
# 1. Navigate to sandbox
cd GCP/<sandbox-name>

# 2. Configure environment
vi vars.sh  # Set GCP project, region, zone, etc.

# 3. Deploy GKE cluster
./scripts/cluster-setup-gke-everything.sh

# 4. Access services
# GCP LoadBalancer will provide public IPs

# 5. Tear down
./scripts/cluster-destroy-gke.sh
```

## GCP-Specific Features

Future sandboxes will leverage:

- **Cloud Load Balancing** - Global load balancing
- **VPC-native clusters** - Advanced networking with alias IPs
- **Workload Identity** - Secure access to GCP services
- **Cloud Monitoring** - Metrics and logging
- **Cloud Trace** - Distributed tracing
- **Binary Authorization** - Image signing and verification
- **GKE Autopilot** - Fully managed node pools
- **Multi-cluster Ingress** - Cross-cluster load balancing
- **Anthos** - Hybrid and multi-cloud management

## GKE vs Standard Kubernetes

GKE provides several enhancements:

- **Managed control plane** - Google manages masters
- **Auto-upgrade** - Automatic Kubernetes upgrades
- **Auto-repair** - Self-healing nodes
- **Integrated monitoring** - Built-in Cloud Monitoring
- **Security hardening** - Google security best practices
- **Regional clusters** - Multi-zone high availability
- **Preemptible nodes** - Cost-optimized node pools

## Anthos Service Mesh

GCP's managed Istio offering:

- **Fully managed** - Google operates the control plane
- **SLA-backed** - Production-ready with support
- **Integrated monitoring** - Native Cloud Monitoring integration
- **Certificate management** - Automatic mTLS certificates
- **Multi-cluster** - Unified service mesh across clusters

## Contributing

If you'd like to contribute GCP GKE sandboxes:

1. Follow patterns from AWS/eks-spiffe-spire-istio-sandbox
2. Use gcloud CLI for cluster management
3. Leverage GCP-native services where appropriate
4. Document GCP-specific configuration
5. Test across multiple GCP regions
6. Consider both standard GKE and Autopilot
7. Submit a pull request

## Resources

- [GKE Documentation](https://cloud.google.com/kubernetes-engine/docs)
- [gcloud CLI Reference](https://cloud.google.com/sdk/gcloud/reference)
- [Anthos Service Mesh](https://cloud.google.com/anthos/service-mesh)
- [Cloud Service Mesh](https://cloud.google.com/service-mesh/docs)
- [GKE Best Practices](https://cloud.google.com/kubernetes-engine/docs/best-practices)
- [k3d Sandboxes](../k3d-sandboxes/) - Local testing environments

---

Tom Dean
Last updated: February 23, 2026
