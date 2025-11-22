# Quick Reference Guide

Common commands and configurations for the GitOps demo project.

## Essential Commands

### Azure & AKS

```bash
# Login to Azure
az login
az account set --subscription "Your Subscription"

# Get AKS credentials
az aks get-credentials --resource-group rg-gitops-demo --name aks-gitops-demo

# View AKS status
az aks show --resource-group rg-gitops-demo --name aks-gitops-demo --query powerState

# Start/Stop AKS cluster
az aks stop --name aks-gitops-demo --resource-group rg-gitops-demo
az aks start --name aks-gitops-demo --resource-group rg-gitops-demo

# ACR login
az acr login --name myacr

# List ACR images
az acr repository list --name myacr --output table
az acr repository show-tags --name myacr --repository gitops-demo-app --output table
```

### Kubectl

```bash
# Context and cluster info
kubectl config current-context
kubectl cluster-info
kubectl get nodes

# Namespace operations
kubectl get namespaces
kubectl config set-context --current --namespace=gitops-demo-dev

# View resources
kubectl get all -n gitops-demo-dev
kubectl get pods -n gitops-demo-dev -o wide
kubectl get svc -n gitops-demo-dev
kubectl get ingress -n gitops-demo-dev

# Describe resources
kubectl describe pod <pod-name> -n gitops-demo-dev
kubectl describe svc <service-name> -n gitops-demo-dev

# Logs
kubectl logs -f <pod-name> -n gitops-demo-dev
kubectl logs -f -l app.kubernetes.io/name=gitops-demo-app -n gitops-demo-dev

# Execute commands in pod
kubectl exec -it <pod-name> -n gitops-demo-dev -- /bin/bash
kubectl exec -it <pod-name> -n gitops-demo-dev -- python --version

# Port forwarding
kubectl port-forward -n gitops-demo-dev svc/gitops-demo-app 8080:80

# Delete resources
kubectl delete pod <pod-name> -n gitops-demo-dev
kubectl delete -f argo/application-dev.yaml
```

### Argo CD

```bash
# Get Argo CD admin password
kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath="{.data.password}" | base64 -d

# Get Argo CD server URL
kubectl get svc argocd-server -n argocd

# Port forward to Argo CD UI
kubectl port-forward svc/argocd-server -n argocd 8080:443

# Argo CD CLI login
argocd login <ARGOCD_SERVER_IP> --username admin --password <password> --insecure

# List applications
argocd app list
argocd app get gitops-demo-app-dev

# Sync application
argocd app sync gitops-demo-app-dev
argocd app sync gitops-demo-app-dev --force
argocd app sync gitops-demo-app-dev --prune

# View application history
argocd app history gitops-demo-app-dev

# Rollback application
argocd app rollback gitops-demo-app-dev <revision-number>

# View application diff
argocd app diff gitops-demo-app-dev

# Delete application
argocd app delete gitops-demo-app-dev
```

### Helm

```bash
# Lint chart
helm lint helm/

# Template chart (dry-run)
helm template gitops-demo-app ./helm -f environments/dev/values.yaml

# Install chart
helm install gitops-demo-app ./helm -f environments/dev/values.yaml -n gitops-demo-dev

# Upgrade chart
helm upgrade gitops-demo-app ./helm -f environments/dev/values.yaml -n gitops-demo-dev

# List releases
helm list -n gitops-demo-dev

# Get values
helm get values gitops-demo-app -n gitops-demo-dev

# Uninstall
helm uninstall gitops-demo-app -n gitops-demo-dev

# Show chart info
helm show chart ./helm
helm show values ./helm
```

### Docker

```bash
# Build image locally
docker build -t gitops-demo-app:test ./app

# Run container locally
docker run -p 8080:8080 gitops-demo-app:test

# Tag image
docker tag gitops-demo-app:test myacr.azurecr.io/gitops-demo-app:test

# Push image
docker push myacr.azurecr.io/gitops-demo-app:test

# Pull image
docker pull myacr.azurecr.io/gitops-demo-app:dev-latest

# View logs
docker logs <container-id>

# Execute command in container
docker exec -it <container-id> /bin/bash
```

### Git Operations

```bash
# Update image tag for an environment
sed -i 's/tag: .*/tag: "new-tag"/' environments/dev/values.yaml
git add environments/dev/values.yaml
git commit -m "chore: Update dev image tag"
git push origin main

# Create promotion branch
git checkout -b promote-to-stage
# Make changes
git add .
git commit -m "chore: Promote to staging"
git push origin promote-to-stage

# Revert deployment
git revert <commit-hash>
git push origin main
```

## Configuration Files Quick Reference

### Update ACR Name

```bash
# Find and replace ACR name in all files
find . -type f \( -name "*.yaml" -o -name "*.yml" \) -exec sed -i 's/myacr.azurecr.io/YOUR_ACR.azurecr.io/g' {} +
```

### Update Repository URL

```bash
# Update Argo CD application manifests
sed -i 's|YOUR-ORG/YOUR-REPO|your-org/your-repo|g' argo/*.yaml
```

### Environment Variable Override

```yaml
# In environments/*/values.yaml
env:
  - name: CUSTOM_VAR
    value: "custom-value"
```

### Resource Limits

```yaml
# In environments/*/values.yaml
resources:
  limits:
    cpu: 500m
    memory: 512Mi
  requests:
    cpu: 250m
    memory: 256Mi
```

## Troubleshooting Quick Fixes

### Pod CrashLoopBackOff

```bash
kubectl describe pod <pod-name> -n gitops-demo-dev
kubectl logs <pod-name> -n gitops-demo-dev
kubectl logs <pod-name> -n gitops-demo-dev --previous
```

### ImagePullBackOff

```bash
# Recreate ACR secret
kubectl delete secret acr-secret -n gitops-demo-dev
kubectl create secret docker-registry acr-secret \
  --docker-server=myacr.azurecr.io \
  --docker-username=<username> \
  --docker-password=<password> \
  -n gitops-demo-dev
```

### Argo CD Out of Sync

```bash
# Check diff
argocd app diff gitops-demo-app-dev

# Force sync
argocd app sync gitops-demo-app-dev --force

# Hard refresh
argocd app get gitops-demo-app-dev --hard-refresh
```

### Ingress Not Working

```bash
# Check ingress controller
kubectl get pods -n ingress-nginx
kubectl logs -n ingress-nginx -l app.kubernetes.io/component=controller

# Check ingress resource
kubectl describe ingress -n gitops-demo-dev

# Get external IP
kubectl get svc -n ingress-nginx ingress-nginx-controller
```

## Useful One-liners

```bash
# Get all pod IPs
kubectl get pods -n gitops-demo-dev -o wide --no-headers | awk '{print $1"\t"$6}'

# Watch pod status
watch kubectl get pods -n gitops-demo-dev

# Get pod resource usage
kubectl top pods -n gitops-demo-dev

# Get node resource usage
kubectl top nodes

# Count pods by status
kubectl get pods -n gitops-demo-dev --no-headers | awk '{print $3}' | sort | uniq -c

# Delete all pods in namespace (they'll be recreated)
kubectl delete pods --all -n gitops-demo-dev

# Get all events
kubectl get events -n gitops-demo-dev --sort-by='.lastTimestamp'

# Get pod YAML
kubectl get pod <pod-name> -n gitops-demo-dev -o yaml

# Test DNS resolution
kubectl run -it --rm debug --image=busybox --restart=Never -- nslookup gitops-demo-app.gitops-demo-dev.svc.cluster.local
```

## GitHub Secrets Configuration

Required secrets for GitHub Actions:

```
AZURE_CREDENTIALS:
{
  "clientId": "<GUID>",
  "clientSecret": "<GUID>",
  "subscriptionId": "<GUID>",
  "tenantId": "<GUID>"
}

GITOPS_PAT:
ghp_xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx
```

## Environment URLs

```
Dev:   http://gitops-demo-dev.example.com
Stage: http://gitops-demo-stage.example.com
Prod:  http://gitops-demo.example.com

Argo CD: https://<ARGOCD_SERVER_IP>
```

## Default Credentials

```
Argo CD:
  Username: admin
  Password: kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath="{.data.password}" | base64 -d

ACR:
  Username: az acr credential show --name myacr --query username -o tsv
  Password: az acr credential show --name myacr --query passwords[0].value -o tsv
```
