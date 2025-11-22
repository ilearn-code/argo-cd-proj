# Argo CD Application Manifests

This directory contains Argo CD Application and ApplicationSet manifests for deploying the GitOps demo app across multiple environments.

## Files

- `application-dev.yaml` - Development environment (auto-sync enabled)
- `application-stage.yaml` - Staging environment (manual sync)
- `application-prod.yaml` - Production environment (manual sync, enhanced monitoring)
- `applicationset.yaml` - ApplicationSet for managing all environments

## Deployment Options

### Option 1: Individual Applications (Recommended for learning)

Deploy each environment separately:

```bash
# Deploy to dev
kubectl apply -f application-dev.yaml

# Deploy to staging
kubectl apply -f application-stage.yaml

# Deploy to production
kubectl apply -f application-prod.yaml
```

### Option 2: ApplicationSet (Recommended for production)

Deploy all environments using ApplicationSet:

```bash
kubectl apply -f applicationset.yaml
```

## Configuration

Before applying these manifests, update the following:

1. Replace `YOUR-ORG/YOUR-REPO` with your actual GitHub organization and repository name
2. Update `targetRevision` if using a different branch (default: main)
3. Adjust sync policies based on your requirements

## Sync Policies

- **Dev**: Auto-sync enabled, self-healing enabled
- **Stage**: Manual sync required, use for pre-production testing
- **Prod**: Manual sync required, enhanced notifications

## Monitoring

Production environment includes:
- Slack notifications on sync success/failure
- Health degradation alerts
- Strict sync policies with reduced retry limits
