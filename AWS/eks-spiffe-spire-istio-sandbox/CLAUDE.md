# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

This is an AWS EKS sandbox environment for experimenting with SPIFFE/SPIRE and Istio service mesh. The sandbox automates EKS cluster creation and configuration for testing identity and service mesh technologies.

## Prerequisites

- AWS CLI configured with appropriate profile
- `eksctl` for EKS cluster management
- `kubectl` and `kubectx` for Kubernetes context management
- Helm for chart installations

## Configuration

Before running any scripts, edit `vars.sh` to set:
- `AWS_PROFILE` - Your AWS CLI profile name
- `LICENSE_KEY` - Solo.io license key (if using Solo Enterprise)
- Optionally adjust: `AWS_REGION`, `NODE_TYPE`, `EKS_VERSION`, `ISTIO_VERSION`, `SPIRE_VERSION`

## Common Commands

```bash
# Source environment variables (required before running scripts)
source vars.sh

# Create EKS cluster with full stack (Istio, Gloo, sample apps)
./scripts/cluster-setup-everything.sh

# Create bare EKS cluster only (no additional components)
./scripts/cluster-setup-naked.sh

# Destroy cluster and clean up kubectl contexts
./scripts/cluster-destroy-eks.sh
```

## Architecture

- **vars.sh** - Central configuration file for all environment variables
- **scripts/** - Cluster lifecycle scripts (create, destroy)
- **manifests/** - Kubernetes/Helm configuration files:
  - `eks-cluster.yaml` - eksctl cluster configuration
  - `istio-values.yaml` - Istio Helm values (customize here)
  - `grafana-values.yaml` - Grafana with Istio dashboards pre-configured
  - `grafana-ingress.yaml` - Traefik ingress for Grafana

## Notes

- Scripts currently have a typo: `mainfests/` should be `manifests/` in cluster setup scripts
- Scripts contain k3d references that need updating to EKS equivalents (leftover from conversion)
- Default cluster naming: `spire-01`, `spire-02`, etc. based on `NUM_CLUSTERS`
- kubectl contexts are configured as `spire-01`, `spire-02`, etc.
