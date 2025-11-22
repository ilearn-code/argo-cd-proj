# GitOps Workflow Diagram

This document provides visual representations of the GitOps workflow.

## Complete CI/CD Flow

```
┌─────────────────────────────────────────────────────────────────────┐
│                         DEVELOPER WORKFLOW                          │
└─────────────────────────────────────────────────────────────────────┘
                                  │
                                  │ git push
                                  ▼
┌─────────────────────────────────────────────────────────────────────┐
│                          GITHUB ACTIONS                             │
│                                                                     │
│  ┌──────────────┐   ┌──────────────┐   ┌──────────────┐          │
│  │   Checkout   │──▶│ Build Docker │──▶│  Push to ACR │          │
│  │     Code     │   │    Image     │   │              │          │
│  └──────────────┘   └──────────────┘   └──────────────┘          │
│                                                │                   │
│                                                ▼                   │
│                                    ┌──────────────────┐           │
│                                    │  Update Manifest │           │
│                                    │  (values.yaml)   │           │
│                                    └──────────────────┘           │
│                                                │                   │
│                                                ▼                   │
│                                    ┌──────────────────┐           │
│                                    │  Commit & Push   │           │
│                                    │   to Git Repo    │           │
│                                    └──────────────────┘           │
└─────────────────────────────────────────────────────────────────────┘
                                  │
                                  │ Git Webhook / Polling
                                  ▼
┌─────────────────────────────────────────────────────────────────────┐
│                            ARGO CD                                  │
│                                                                     │
│  ┌──────────────┐   ┌──────────────┐   ┌──────────────┐          │
│  │   Detect     │──▶│   Compare    │──▶│   Sync to    │          │
│  │   Changes    │   │  Git vs K8s  │   │  Kubernetes  │          │
│  └──────────────┘   └──────────────┘   └──────────────┘          │
│                                                │                   │
└─────────────────────────────────────────────────────────────────────┘
                                  │
                                  ▼
┌─────────────────────────────────────────────────────────────────────┐
│                         AZURE KUBERNETES                            │
│                                                                     │
│   ┌─────────────┐   ┌─────────────┐   ┌─────────────┐            │
│   │     DEV     │   │    STAGE    │   │    PROD     │            │
│   │             │   │             │   │             │            │
│   │  Auto-Sync  │   │ Manual Sync │   │ Manual Sync │            │
│   │  1 Replica  │   │  2 Replicas │   │  3 Replicas │            │
│   │             │   │             │   │    + HPA    │            │
│   └─────────────┘   └─────────────┘   └─────────────┘            │
└─────────────────────────────────────────────────────────────────────┘
```

## Environment Promotion Flow

```
┌──────────────────┐
│                  │
│  Feature Branch  │
│                  │
└────────┬─────────┘
         │
         │ merge / push
         ▼
┌──────────────────┐
│                  │
│   Main Branch    │
│                  │
└────────┬─────────┘
         │
         │ CI builds & pushes
         ▼
┌──────────────────┐      ┌─────────────────────────────┐
│                  │      │   Argo CD Auto-Sync         │
│   DEV (auto)     │◀─────│   • Immediate deployment    │
│                  │      │   • Self-healing enabled    │
└────────┬─────────┘      └─────────────────────────────┘
         │
         │ Testing & validation
         ▼
┌──────────────────┐      ┌─────────────────────────────┐
│                  │      │   Manual Approval           │
│   STAGE (manual) │◀─────│   • Update values.yaml      │
│                  │      │   • Create PR               │
└────────┬─────────┘      │   • Manual sync in Argo CD  │
         │                └─────────────────────────────┘
         │ UAT & final testing
         ▼
┌──────────────────┐      ┌─────────────────────────────┐
│                  │      │   Strict Approval Process   │
│   PROD (manual)  │◀─────│   • Promotion workflow      │
│                  │      │   • Review checklist        │
└──────────────────┘      │   • Manual sync in Argo CD  │
                          │   • Rollback plan ready     │
                          └─────────────────────────────┘
```

## Argo CD Application Sync Process

```
┌────────────────────────────────────────────────────────────────┐
│                     Git Repository                              │
│                                                                 │
│  helm/                 environments/                            │
│  ├── templates/        ├── dev/                                │
│  └── values.yaml       ├── stage/                              │
│                        └── prod/                                │
└────────────────────┬───────────────────────────────────────────┘
                     │
                     │ Argo CD monitors
                     ▼
┌────────────────────────────────────────────────────────────────┐
│                    Argo CD Controller                          │
│                                                                │
│  1. Fetch manifest from Git                                   │
│  2. Render Helm chart with environment values                 │
│  3. Compare with current cluster state                        │
│  4. Generate diff                                              │
│  5. Apply changes (if auto-sync or manual trigger)            │
└────────────────────┬───────────────────────────────────────────┘
                     │
                     │ Apply manifests
                     ▼
┌────────────────────────────────────────────────────────────────┐
│                  Kubernetes Cluster                            │
│                                                                │
│  Namespace: gitops-demo-dev / stage / prod                    │
│                                                                │
│  ┌──────────────┐  ┌──────────────┐  ┌──────────────┐        │
│  │  Deployment  │  │   Service    │  │   Ingress    │        │
│  └──────────────┘  └──────────────┘  └──────────────┘        │
│                                                                │
│  ┌──────────────┐  ┌──────────────┐                          │
│  │     HPA      │  │     PDB      │                          │
│  └──────────────┘  └──────────────┘                          │
└────────────────────────────────────────────────────────────────┘
```

## Azure Architecture

```
┌─────────────────────────────────────────────────────────────────┐
│                         Azure Cloud                             │
│                                                                 │
│  ┌──────────────────────────────────────────────────────────┐  │
│  │              Azure Container Registry (ACR)              │  │
│  │                                                          │  │
│  │  myacr.azurecr.io/gitops-demo-app:dev-latest           │  │
│  │  myacr.azurecr.io/gitops-demo-app:stage-v1.0.0         │  │
│  │  myacr.azurecr.io/gitops-demo-app:prod-v1.0.0          │  │
│  └────────────────────────┬─────────────────────────────────┘  │
│                           │ Image Pull                         │
│                           ▼                                    │
│  ┌──────────────────────────────────────────────────────────┐  │
│  │      Azure Kubernetes Service (AKS)                      │  │
│  │                                                          │  │
│  │  ┌────────────────────────────────────────────────────┐ │  │
│  │  │              Control Plane                         │ │  │
│  │  └────────────────────────────────────────────────────┘ │  │
│  │                                                          │  │
│  │  ┌───────────┐  ┌───────────┐  ┌───────────┐          │  │
│  │  │  Node 1   │  │  Node 2   │  │  Node 3   │          │  │
│  │  │           │  │           │  │           │          │  │
│  │  │  Dev Pods │  │Stage Pods │  │Prod Pods  │          │  │
│  │  └───────────┘  └───────────┘  └───────────┘          │  │
│  │                                                          │  │
│  │  ┌────────────────────────────────────────────────────┐ │  │
│  │  │          NGINX Ingress Controller                  │ │  │
│  │  └─────────────────────┬──────────────────────────────┘ │  │
│  └────────────────────────┼─────────────────────────────────┘  │
│                           │                                    │
│  ┌────────────────────────┴──────────────────────────────────┐ │
│  │              Azure Load Balancer                          │ │
│  └────────────────────────┬──────────────────────────────────┘ │
└─────────────────────────┼─────────────────────────────────────┘
                          │
                          ▼
                  Internet / Users
```

## GitHub Actions Workflow

```
┌───────────────────────────────────────────────────────────┐
│                     Trigger Events                        │
│                                                           │
│  • Push to main/develop                                  │
│  • Pull Request                                           │
│  • Manual workflow_dispatch                              │
└───────────────────┬───────────────────────────────────────┘
                    │
                    ▼
┌───────────────────────────────────────────────────────────┐
│              Job: build-and-push                          │
│                                                           │
│  1. Checkout code                                         │
│  2. Determine environment (dev/stage/prod)               │
│  3. Generate image tag                                    │
│  4. Azure login                                           │
│  5. ACR login                                             │
│  6. Build Docker image                                    │
│  7. Push to ACR                                           │
│  8. Scan for vulnerabilities (optional)                  │
└───────────────────┬───────────────────────────────────────┘
                    │
                    ▼
┌───────────────────────────────────────────────────────────┐
│         Job: update-gitops-manifest                       │
│                                                           │
│  1. Checkout code                                         │
│  2. Update environments/[env]/values.yaml                │
│  3. Commit changes                                        │
│  4. Push to repository                                    │
└───────────────────┬───────────────────────────────────────┘
                    │
                    ▼
┌───────────────────────────────────────────────────────────┐
│         Job: verify-deployment                            │
│                                                           │
│  1. Wait for Argo CD sync                                │
│  2. Check deployment status                               │
│  3. Run health checks (optional)                         │
└───────────────────────────────────────────────────────────┘
```
