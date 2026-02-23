# kagent-sandbox

**Kagent AI Agent Framework**

Tom Dean
Last edit: 2/23/2026

## Introduction

The `kagent-sandbox` provides a dedicated testing environment for Kagent, the first open-source agentic AI framework for Kubernetes contributed to CNCF. This sandbox focuses on AI agent development, lifecycle management, and integration with Kgateway for ingress routing.

## Technology Stack

- **Kagent** - CNCF AI agent framework for Kubernetes
- **Kgateway** - Cloud-native API gateway (Gateway API implementation)
- **Gateway API** - Kubernetes-native ingress specification
- **OpenAI integration** - Supports multiple LLM providers

## Prerequisites

- [k3d](https://k3d.io) - Local Kubernetes cluster manager
- [Docker](https://www.docker.com/get-started/) - Container runtime
- [Helm](https://helm.sh/docs/intro/install/) - Kubernetes package manager
- `bash` shell
- [kubectl](https://kubernetes.io/docs/tasks/tools/) - Kubernetes CLI
- [kubectx](https://github.com/ahmetb/kubectx) - Context switching utility
- Internet access to pull containers and Helm charts
- **OpenAI API key** (or other LLM provider credentials)

## Quick Start

### 1. Configure Environment

Edit `vars.sh` and set your OpenAI API key:

```bash
vi vars.sh  # Set OPENAI_API_KEY
```

### 2. Deploy the Full Stack

```bash
# Deploy Kagent with Kgateway
./scripts/cluster-setup-k3d-kagent-everything.sh

# OR: Deploy bare cluster for manual installation
./scripts/cluster-setup-k3d-naked.sh
```

### 3. Verify Installation

```bash
# Check all pods are running
kubectl get pods -A

# Verify Kagent installation
kubectl get pods -n kagent

# Check Kgateway
kubectl get pods -n kgateway-system

# View Kagent CRDs
kubectl get crds | grep kagent
```

### 4. Access Kagent UI

The Kagent dashboard is accessible at:

- http://localhost:7001
- http://YOUR_IP_ADDRESS:7001

### 5. Tear Down

```bash
./scripts/cluster-destroy-k3d.sh
```

## Configuration

### Environment Variables (vars.sh)

| Variable | Default | Description |
|----------|---------|-------------|
| `NUM_CLUSTERS` | 1 | Number of k3d clusters |
| `CLUSTER_NAME_PREFIX` | `kagent-` | Prefix for cluster names |
| `KAGENT_VERSION` | Latest | Kagent version to deploy |
| `KGATEWAY_VERSION` | Latest | Kgateway version to deploy |
| `OPENAI_API_KEY` | Required | OpenAI API key for agent operations |

### Manifest Files

```
manifests/
├── http-listener.yaml      # Kgateway HTTP Gateway
├── kagent-httproute.yaml   # HTTPRoute for Kagent UI
├── kagent-values.yaml      # Kagent Helm values
├── grafana-ingress.yaml    # Optional Grafana ingress
├── grafana-values.yaml     # Optional Grafana config
└── registries.yaml         # Docker registry config
```

## Use Cases

- **AI agent development** - Build and test autonomous agents
- **Kubernetes-native agent deployment** - Deploy agents as K8s resources
- **Multi-LLM provider testing** - Test with OpenAI, Azure, Anthropic, Ollama
- **Agent lifecycle management** - Create, update, and delete agents via CRDs
- **MCP server integration** - Connect agents to tools via Model Context Protocol

## Kagent Features

### Agent CRDs

Kagent provides Kubernetes Custom Resource Definitions for managing agents:

```yaml
apiVersion: kagent.dev/v1alpha1
kind: Agent
metadata:
  name: my-agent
spec:
  provider: openai
  model: gpt-4
  instructions: "You are a helpful assistant"
```

### Built-in Tools

Kagent includes a built-in MCP server with Kubernetes tools:
- Pod management
- Service discovery
- ConfigMap operations
- Secret access
- Resource monitoring

### Web UI

The Kagent UI provides:
- Agent creation and configuration
- Real-time agent monitoring
- Conversation history
- Tool usage tracking
- Provider configuration

## Kgateway Integration

The sandbox uses Kgateway to expose the Kagent UI:

```
Internet → Kgateway (port 7001) → Kagent Service → Kagent UI
```

The HTTPRoute configuration routes traffic based on hostname and path.

## Working with Agents

### Create an Agent via UI

1. Access http://localhost:7001
2. Click "Create Agent"
3. Select provider (OpenAI, Azure, etc.)
4. Configure model and instructions
5. Save and start chatting

### Create an Agent via kubectl

```bash
# Apply agent manifest
kubectl apply -f - <<EOF
apiVersion: kagent.dev/v1alpha1
kind: Agent
metadata:
  name: demo-agent
  namespace: kagent
spec:
  provider: openai
  model: gpt-4
  instructions: "You are a Kubernetes expert assistant"
EOF

# View agents
kubectl get agents -n kagent

# Describe agent
kubectl describe agent demo-agent -n kagent
```

### Delete an Agent

```bash
kubectl delete agent demo-agent -n kagent
```

## Troubleshooting

### Kagent Pods Not Starting

```bash
# Check if OpenAI API key is set
kubectl get secret -n kagent

# View Kagent logs
kubectl logs -n kagent deployment/kagent

# Verify CRDs are installed
kubectl get crds | grep kagent
```

### UI Not Accessible

```bash
# Check Kgateway service
kubectl get svc -n kgateway-system

# Verify HTTPRoute
kubectl get httproute -A

# Test with port-forward as fallback
kubectl port-forward -n kagent svc/kagent 8080:80
```

### Agent Creation Failures

```bash
# Check agent status
kubectl get agent -n kagent
kubectl describe agent <agent-name> -n kagent

# View agent logs
kubectl logs -n kagent -l app=kagent

# Verify API key configuration
kubectl get configmap -n kagent
```

## Advanced Usage

### Multiple LLM Providers

Configure additional providers in `manifests/kagent-values.yaml`:

```yaml
providers:
  openAI:
    apiKey: "sk-..."
  azure:
    endpoint: "https://..."
    apiKey: "..."
  anthropic:
    apiKey: "..."
```

### Custom MCP Servers

Connect agents to external MCP servers:

```yaml
spec:
  mcpServers:
    - name: my-tools
      url: http://mcp-server:8080
```

### OpenTelemetry Tracing

Enable tracing to observe agent behavior:

```yaml
observability:
  tracing:
    enabled: true
    endpoint: http://jaeger:4318
```

## Next Steps

- Create custom agents for specific tasks
- Integrate with external MCP servers
- Build agent workflows and pipelines
- Implement agent-to-agent communication
- Deploy production agents with proper security
- Explore multi-agent collaboration patterns

## Documentation

- [Kagent GitHub](https://github.com/kagent-dev/kagent)
- [Kagent Documentation](https://kagent.dev/)
- [Model Context Protocol](https://modelcontextprotocol.io/)
- [Kgateway Documentation](https://docs.kgateway.dev/)

---

Tom Dean
Last updated: February 23, 2026
