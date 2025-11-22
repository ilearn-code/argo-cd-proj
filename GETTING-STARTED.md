# Getting Started Checklist

Use this checklist to deploy your GitOps project step by step.

## Pre-Deployment Checklist

### ☐ Prerequisites Installed

- [ ] Azure CLI installed (`az --version`)
- [ ] kubectl installed (`kubectl version --client`)
- [ ] Helm 3 installed (`helm version`)
- [ ] Git installed (`git --version`)
- [ ] Docker installed (optional, for local testing)
- [ ] Active Azure subscription
- [ ] GitHub account with repository created

### ☐ Azure Account Setup

- [ ] Logged into Azure CLI (`az login`)
- [ ] Correct subscription selected (`az account show`)
- [ ] Sufficient permissions (Contributor role or higher)
- [ ] Quota available for 3+ VMs in chosen region

### ☐ GitHub Setup

- [ ] New repository created (or fork this project)
- [ ] GitHub Personal Access Token created with `repo` scope
- [ ] Repository URL noted for configuration

## Configuration Checklist

### ☐ Update Infrastructure Scripts

Edit `infrastructure/01-setup-azure-resources.sh`:

- [ ] `RESOURCE_GROUP` - Your preferred name (default: rg-gitops-demo)
- [ ] `LOCATION` - Your Azure region (default: eastus)
- [ ] `AKS_CLUSTER_NAME` - Your cluster name (default: aks-gitops-demo)
- [ ] `ACR_NAME` - **MUST BE GLOBALLY UNIQUE** (default: myacr)
- [ ] `NODE_COUNT` - Number of nodes (default: 3)
- [ ] `NODE_SIZE` - VM size (default: Standard_D2s_v3)

### ☐ Update Helm Values

Replace ACR name in these files (if you changed it):

- [ ] `helm/values.yaml` - Line 9: `repository: YOUR_ACR.azurecr.io/gitops-demo-app`
- [ ] `environments/dev/values.yaml` - Line 4: `repository: YOUR_ACR.azurecr.io/gitops-demo-app`
- [ ] `environments/stage/values.yaml` - Line 4: `repository: YOUR_ACR.azurecr.io/gitops-demo-app`
- [ ] `environments/prod/values.yaml` - Line 4: `repository: YOUR_ACR.azurecr.io/gitops-demo-app`

### ☐ Update Argo CD Applications

Replace GitHub repository URL in these files:

- [ ] `argo/application-dev.yaml` - Line 16: `repoURL: https://github.com/YOUR-ORG/YOUR-REPO.git`
- [ ] `argo/application-stage.yaml` - Line 16: `repoURL: https://github.com/YOUR-ORG/YOUR-REPO.git`
- [ ] `argo/application-prod.yaml` - Line 18: `repoURL: https://github.com/YOUR-ORG/YOUR-REPO.git`
- [ ] `argo/applicationset.yaml` - Line 31: `repoURL: https://github.com/YOUR-ORG/YOUR-REPO.git`

### ☐ Update CI/CD Workflows

Edit `.github/workflows/ci-cd.yaml`:

- [ ] Line 19: `REGISTRY_NAME: YOUR_ACR` (without .azurecr.io)
- [ ] Line 20: `ACR_LOGIN_SERVER: YOUR_ACR.azurecr.io`

Edit `.github/workflows/promote-to-prod.yaml`:

- [ ] Line 25-26: Replace `myacr` with your ACR name (2 occurrences)
- [ ] Line 33: `az acr login --name YOUR_ACR`
- [ ] Line 35-37: Update ACR URLs with your ACR name

### ☐ Update Ingress Hostnames (Optional)

If you have custom domains, update:

- [ ] `environments/dev/values.yaml` - Line 24: `host: YOUR-DOMAIN-dev.com`
- [ ] `environments/stage/values.yaml` - Line 24: `host: YOUR-DOMAIN-stage.com`
- [ ] `environments/prod/values.yaml` - Line 29: `host: YOUR-DOMAIN.com`

## Deployment Checklist

### ☐ Phase 1: Azure Infrastructure

```bash
cd infrastructure
chmod +x *.sh
```

- [ ] Run `./01-setup-azure-resources.sh`
- [ ] Wait 10-15 minutes for completion
- [ ] Verify AKS cluster created: `kubectl get nodes`
- [ ] Note the Ingress Controller IP address
- [ ] Save ACR credentials (displayed at end)

### ☐ Phase 2: Argo CD Installation

```bash
# Still in infrastructure directory
```

- [ ] Run `./02-install-argocd.sh`
- [ ] Wait 3-5 minutes for completion
- [ ] Save Argo CD URL (displayed at end)
- [ ] Save admin password (displayed at end)
- [ ] Test Argo CD access in browser (accept self-signed cert)
- [ ] Login to Argo CD UI successfully

### ☐ Phase 3: GitHub Configuration

#### Create Azure Service Principal

```bash
az ad sp create-for-rbac \
  --name 'github-actions-gitops' \
  --role contributor \
  --scopes /subscriptions/SUBSCRIPTION_ID/resourceGroups/rg-gitops-demo \
  --sdk-auth
```

- [ ] Run command above (replace SUBSCRIPTION_ID)
- [ ] Copy the entire JSON output
- [ ] In GitHub repo: Settings → Secrets and variables → Actions
- [ ] Click "New repository secret"
- [ ] Name: `AZURE_CREDENTIALS`
- [ ] Paste JSON output
- [ ] Click "Add secret"

#### Create GitHub Personal Access Token

- [ ] Go to GitHub Settings → Developer settings → Personal access tokens
- [ ] Click "Generate new token (classic)"
- [ ] Name: "GitOps Demo PAT"
- [ ] Select scope: `repo` (all repo permissions)
- [ ] Click "Generate token"
- [ ] Copy the token (you won't see it again!)
- [ ] In your repository: Settings → Secrets and variables → Actions
- [ ] Click "New repository secret"
- [ ] Name: `GITOPS_PAT`
- [ ] Paste token
- [ ] Click "Add secret"

### ☐ Phase 4: Push to GitHub

```bash
cd /path/to/argo-cd
git init
git add .
git commit -m "feat: Initial GitOps project setup"
git branch -M main
git remote add origin https://github.com/YOUR-ORG/YOUR-REPO.git
git push -u origin main
```

- [ ] Repository initialized
- [ ] All files committed
- [ ] Pushed to GitHub
- [ ] Verify files visible on GitHub

### ☐ Phase 5: Deploy Applications

**Option A: Deploy all environments using ApplicationSet (Recommended)**

```bash
kubectl apply -f argo/applicationset.yaml
```

- [ ] ApplicationSet applied
- [ ] Wait 30 seconds
- [ ] Check Argo CD UI - 3 applications should appear
- [ ] All applications should show "Healthy" status

**Option B: Deploy environments individually**

```bash
kubectl apply -f argo/application-dev.yaml
kubectl apply -f argo/application-stage.yaml
kubectl apply -f argo/application-prod.yaml
```

- [ ] Dev application applied
- [ ] Stage application applied
- [ ] Prod application applied
- [ ] All visible in Argo CD UI

### ☐ Phase 6: Build and Deploy Application

**Trigger the first build:**

```bash
# Make a small change to trigger CI/CD
echo "# Build trigger" >> README.md
git add README.md
git commit -m "chore: Trigger first build"
git push origin main
```

- [ ] Commit pushed to GitHub
- [ ] GitHub Actions workflow triggered (check Actions tab)
- [ ] Docker image built successfully
- [ ] Image pushed to ACR
- [ ] values.yaml updated by CI
- [ ] Argo CD detected change (check UI)
- [ ] Dev environment auto-synced
- [ ] Application deployed successfully

### ☐ Phase 7: Verify Deployment

```bash
# Check pods
kubectl get pods -n gitops-demo-dev

# Check service
kubectl get svc -n gitops-demo-dev

# Check ingress
kubectl get ingress -n gitops-demo-dev

# Test application
kubectl port-forward -n gitops-demo-dev svc/gitops-demo-app 8080:80
# Visit http://localhost:8080 in browser
```

- [ ] Pods running (1/1 Ready)
- [ ] Service created
- [ ] Ingress configured
- [ ] Application accessible via port-forward
- [ ] Health endpoint responds: `http://localhost:8080/health`
- [ ] Main endpoint responds: `http://localhost:8080/`

## Post-Deployment Checklist

### ☐ Argo CD Configuration

- [ ] Change default admin password in Argo CD UI
- [ ] Configure repository connection (if not using public repo)
- [ ] Test manual sync for stage environment
- [ ] Test manual sync for prod environment
- [ ] Configure notifications (optional, see Argo CD docs)

### ☐ DNS Configuration (Optional)

If using custom domains:

- [ ] Create A records pointing to Ingress IP
- [ ] Update ingress annotations for TLS
- [ ] Install cert-manager (optional)
- [ ] Test domain access

### ☐ Monitoring Setup (Optional)

- [ ] Install Prometheus + Grafana
- [ ] Configure dashboards
- [ ] Set up alerts
- [ ] Configure log aggregation

### ☐ Security Hardening (Optional)

- [ ] Review and tighten RBAC policies
- [ ] Configure network policies
- [ ] Set up Azure Key Vault integration
- [ ] Enable Azure Defender for AKS
- [ ] Configure vulnerability scanning

### ☐ Documentation

- [ ] Update README.md with your specific values
- [ ] Document any custom configurations
- [ ] Add team-specific runbooks
- [ ] Update contact information

## Testing Checklist

### ☐ End-to-End Testing

**Dev Environment:**

- [ ] Make code change to `app/main.py`
- [ ] Commit and push to main
- [ ] CI/CD runs successfully
- [ ] Image updated in ACR
- [ ] Argo CD auto-syncs
- [ ] New version deployed
- [ ] Application accessible

**Stage Environment:**

- [ ] Update `environments/stage/values.yaml` with dev image tag
- [ ] Commit and push
- [ ] Manually sync in Argo CD UI
- [ ] Stage deployment successful
- [ ] Test application in stage

**Prod Environment:**

- [ ] Run promotion workflow in GitHub Actions
- [ ] Review and merge PR
- [ ] Manually sync in Argo CD UI
- [ ] Production deployment successful
- [ ] Verify prod application

### ☐ Rollback Testing

- [ ] Make a breaking change
- [ ] Deploy to dev
- [ ] Rollback using Argo CD history
- [ ] Verify previous version restored

### ☐ Scaling Testing

- [ ] Update replica count in values.yaml
- [ ] Commit and sync
- [ ] Verify pods scaled correctly
- [ ] Test load balancing

## Troubleshooting Checklist

### ☐ If Azure Setup Fails

- [ ] Check Azure CLI version: `az --version`
- [ ] Verify logged in: `az account show`
- [ ] Check subscription quota
- [ ] Verify ACR name is globally unique
- [ ] Check region availability
- [ ] Review script output for errors

### ☐ If Argo CD Won't Sync

- [ ] Check repository URL is correct
- [ ] Verify Argo CD can access repository
- [ ] Check Argo CD logs: `kubectl logs -n argocd -l app.kubernetes.io/name=argocd-application-controller`
- [ ] Verify Helm chart syntax: `helm lint helm/`
- [ ] Check values.yaml syntax

### ☐ If Pods Won't Start

- [ ] Check image name and tag
- [ ] Verify ACR credentials: `kubectl get secret acr-secret -n gitops-demo-dev -o yaml`
- [ ] Check pod logs: `kubectl logs -n gitops-demo-dev <pod-name>`
- [ ] Describe pod: `kubectl describe pod -n gitops-demo-dev <pod-name>`
- [ ] Verify resource availability on nodes

### ☐ If CI/CD Fails

- [ ] Verify GitHub secrets are set
- [ ] Check Azure credentials format
- [ ] Verify ACR name in workflow
- [ ] Check GitHub Actions logs
- [ ] Verify repository permissions

## Success Criteria

You've successfully deployed when:

✅ AKS cluster running with 3 nodes
✅ ACR created and accessible
✅ Argo CD UI accessible and logged in
✅ 3 applications visible in Argo CD (dev/stage/prod)
✅ Dev environment shows "Synced" and "Healthy"
✅ Application responds to HTTP requests
✅ CI/CD workflow completes successfully
✅ Code change triggers automatic dev deployment

## Estimated Time

- **Configuration**: 15-20 minutes
- **Azure Infrastructure Setup**: 15-20 minutes
- **Argo CD Installation**: 5 minutes
- **GitHub Configuration**: 5 minutes
- **Application Deployment**: 5-10 minutes
- **Testing & Validation**: 10-15 minutes

**Total: 55-85 minutes** (first time)

## Next Steps After Success

1. ✅ Explore Argo CD UI features
2. ✅ Make a code change and watch it deploy
3. ✅ Practice promoting from dev → stage → prod
4. ✅ Set up monitoring and alerts
5. ✅ Configure custom domains
6. ✅ Add more applications
7. ✅ Implement Argo Rollouts for advanced deployments
8. ✅ Configure Argo CD notifications
9. ✅ Add integration tests to CI/CD
10. ✅ Share with your team!

## Cleanup When Done

- [ ] Run `./infrastructure/99-teardown.sh`
- [ ] Verify resource group deleted in Azure Portal
- [ ] Remove GitHub secrets (optional)
- [ ] Delete GitHub repository (if test only)

---

**Need Help?**

- Check `docs/QUICK-REFERENCE.md` for commands
- See `docs/WORKFLOW-DIAGRAM.md` for visual guides
- Review `infrastructure/README.md` for infrastructure details
- Open an issue on GitHub

**Happy GitOps! 🚀**
