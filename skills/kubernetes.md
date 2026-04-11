# Kubernetes

**Scope:** Deployments, Helm, autoscaling, security, networking.

## Rules
- `resources.requests` and `resources.limits` on every container
- Liveness + readiness probes on every pod
- `HorizontalPodAutoscaler` for stateless workloads
- `PodDisruptionBudget` for replicas > 1
- Secrets via ExternalSecret or sealed-secrets — never plain base64
- `NetworkPolicy` for pod-to-pod traffic restriction
- Standard labels: `app.kubernetes.io/name`, `app.kubernetes.io/component`

## Deployment Patterns
- Rolling updates with `maxSurge` and `maxUnavailable`
- Readiness gates before receiving traffic
- Init containers for dependency checks
- Resource quotas per namespace

## Security
- RBAC with least privilege
- Pod security standards (restricted profile)
- No `latest` tag — always pin image digests or versions
- Service accounts per workload, not default

## Helm
- Values files per environment (dev, staging, prod)
- Templates for repeated patterns
- Hooks for migration jobs
