# Azure Sandboxes

**Azure AKS Testing Environments**

Tom Dean
Last edit: 2/23/2026

## Overview

This directory will contain Azure AKS (Azure Kubernetes Service) deployment sandboxes for testing service mesh, API gateway, and AI agent technologies in Azure cloud environments.

## Status

**Coming Soon** - Azure sandboxes are planned for future development.

## Planned Sandboxes

Future Azure-based environments may include:

- **AKS with Istio Ambient** - Service mesh on managed Kubernetes
- **AKS with Gloo Mesh** - Multi-cluster service mesh across regions
- **AKS with Azure AD integration** - Identity and access management
- **AKS with Azure Monitor** - Native Azure observability
- **AKS with Azure Service Mesh (ASM)** - Microsoft's managed service mesh

## Current Alternatives

While Azure sandboxes are under development, you can:

1. **Use local k3d sandboxes** - Test locally before Azure deployment
   - See [k3d-sandboxes](../k3d-sandboxes/)

2. **Use AWS EKS sandbox** - Similar cloud patterns on AWS
   - See [AWS/eks-spiffe-spire-istio-sandbox](../AWS/eks-spiffe-spire-istio-sandbox/)

3. **Manual AKS deployment** - Adapt k3d scripts for AKS
   - Create AKS cluster with Azure CLI
   - Apply same Helm charts and manifests
   - Adjust for Azure LoadBalancer services

## Prerequisites (for future AKS sandboxes)

When Azure sandboxes are available, you'll need:

- [Azure CLI](https://docs.microsoft.com/en-us/cli/azure/install-azure-cli) - Azure command-line tools
- [kubectl](https://kubernetes.io/docs/tasks/tools/) - Kubernetes CLI
- [kubectx](https://github.com/ahmetb/kubectx) - Context switching
- [Helm](https://helm.sh/) - Chart installations
- Azure subscription with AKS permissions

## Quick Start Pattern (Future)

Expected workflow for Azure sandboxes:

```bash
# 1. Navigate to sandbox
cd Azure/<sandbox-name>

# 2. Configure environment
vi vars.sh  # Set Azure subscription, resource group, etc.

# 3. Deploy AKS cluster
./scripts/cluster-setup-aks-everything.sh

# 4. Access services
# Azure LoadBalancer will provide public IPs

# 5. Tear down
./scripts/cluster-destroy-aks.sh
```

## Azure-Specific Features

Future sandboxes will leverage:

- **Azure Load Balancer** - Native load balancing
- **Azure CNI** - Advanced networking
- **Azure AD Pod Identity** - Workload identity
- **Azure Monitor** - Metrics and logging
- **Azure Key Vault** - Secrets management
- **Azure Container Registry** - Private registries
- **Virtual nodes** - Serverless burst capacity
- **Availability Zones** - Multi-zone deployments

## Contributing

If you'd like to contribute Azure AKS sandboxes:

1. Follow patterns from AWS/eks-spiffe-spire-istio-sandbox
2. Use Azure CLI for cluster management
3. Leverage Azure-native services where appropriate
4. Document Azure-specific configuration
5. Test across multiple Azure regions
6. Submit a pull request

## Resources

- [Azure AKS Documentation](https://docs.microsoft.com/en-us/azure/aks/)
- [Azure CLI Reference](https://docs.microsoft.com/en-us/cli/azure/)
- [Istio on AKS](https://docs.microsoft.com/en-us/azure/aks/istio-about)
- [Azure Service Mesh](https://docs.microsoft.com/en-us/azure/service-mesh/)
- [k3d Sandboxes](../k3d-sandboxes/) - Local testing environments

---

Tom Dean
Last updated: February 23, 2026
