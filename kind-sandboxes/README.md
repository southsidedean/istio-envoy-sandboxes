# kind Sandboxes

**Alternative Local Kubernetes Testing Environments**

Tom Dean
Last edit: 2/23/2026

## Overview

This directory contains kind-based (Kubernetes in Docker) sandbox environments as an alternative to k3d. While the repository primarily uses k3d for local testing, kind sandboxes provide compatibility with environments where kind is preferred or required.

## kind vs k3d

Both tools run Kubernetes clusters locally using Docker containers, but have different characteristics:

### kind (Kubernetes in Docker)
- **Official CNCF project** - Part of Kubernetes SIG Testing
- **Designed for testing** - Primary use case is CI/CD
- **Multi-node clusters** - Easier multi-node local setups
- **Closer to prod** - More similar to production Kubernetes
- **Image loading** - Requires explicit `kind load docker-image`

### k3d (k3s in Docker)
- **Rancher's k3s** - Lightweight Kubernetes distribution
- **Fast deployment** - Optimized for quick iterations
- **Lower resources** - Smaller footprint than kind
- **Built-in registry** - Optional local registry support
- **Port mapping** - Simpler LoadBalancer port exposure

## When to Use kind

Choose kind over k3d when:

- Testing Kubernetes upgrades or compatibility
- Replicating production Kubernetes behavior
- CI/CD pipelines require kind (GitHub Actions, etc.)
- Multi-node cluster features needed locally
- Working with upstream Kubernetes directly

## Current Status

**Note**: The kind-sandboxes directory currently contains placeholder content. The primary sandbox environments are available in the [k3d-sandboxes](../k3d-sandboxes/) directory.

## Planned Sandboxes

Future kind-based sandboxes may include:

- Istio with kind clusters
- Multi-node service mesh testing
- Kubernetes upgrade testing
- Gateway API validation
- CI/CD integration examples

## Using kind

### Installation

```bash
# macOS
brew install kind

# Linux
curl -Lo ./kind https://kind.sigs.k8s.io/dl/latest/kind-linux-amd64
chmod +x ./kind
sudo mv ./kind /usr/local/bin/kind

# Windows
choco install kind
```

### Basic Usage

```bash
# Create a cluster
kind create cluster --name my-cluster

# Create with custom config
kind create cluster --config kind-config.yaml

# Load images
kind load docker-image my-image:tag --name my-cluster

# Delete cluster
kind delete cluster --name my-cluster

# List clusters
kind get clusters
```

### Example Configuration

```yaml
# kind-config.yaml
kind: Cluster
apiVersion: kind.x-k8s.io/v1alpha4
nodes:
  - role: control-plane
    kubeadmConfigPatches:
      - |
        kind: InitConfiguration
        nodeRegistration:
          kubeletExtraArgs:
            node-labels: "topology.kubernetes.io/zone=central"
  - role: worker
    kubeadmConfigPatches:
      - |
        kind: JoinConfiguration
        nodeRegistration:
          kubeletExtraArgs:
            node-labels: "topology.kubernetes.io/zone=west"
  - role: worker
    kubeadmConfigPatches:
      - |
        kind: JoinConfiguration
        nodeRegistration:
          kubeletExtraArgs:
            node-labels: "topology.kubernetes.io/zone=east"
```

## Migration from k3d

To adapt k3d sandboxes for kind:

1. **Replace cluster creation**:
   ```bash
   # k3d
   k3d cluster create --config k3d-config.yaml

   # kind
   kind create cluster --config kind-config.yaml
   ```

2. **Adjust port mappings**:
   ```yaml
   # kind-config.yaml
   nodes:
     - role: control-plane
       extraPortMappings:
         - containerPort: 30080
           hostPort: 7001
   ```

3. **Load images explicitly**:
   ```bash
   kind load docker-image my-app:latest --name cluster-name
   ```

4. **Update kubeconfig context**:
   ```bash
   kind export kubeconfig --name cluster-name
   ```

## Contributing

If you'd like to contribute kind-based sandboxes:

1. Follow the structure from k3d-sandboxes
2. Create kind-specific configuration files
3. Document any kind-specific requirements
4. Test with multiple Kubernetes versions
5. Submit a pull request

## Resources

- [kind Documentation](https://kind.sigs.k8s.io/)
- [kind Quick Start](https://kind.sigs.k8s.io/docs/user/quick-start/)
- [kind Configuration](https://kind.sigs.k8s.io/docs/user/configuration/)
- [k3d Sandboxes](../k3d-sandboxes/) - Primary sandbox collection

---

Tom Dean
Last updated: February 23, 2026
