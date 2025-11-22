# Azure Infrastructure Scripts

This directory contains scripts for setting up and managing the Azure infrastructure for the GitOps demo.

## Prerequisites

- Azure CLI installed: `https://docs.microsoft.com/en-us/cli/azure/install-azure-cli`
- kubectl installed: `https://kubernetes.io/docs/tasks/tools/`
- An active Azure subscription
- Bash shell (Linux/macOS/WSL)

## Scripts

### 01-setup-azure-resources.sh
Creates the complete Azure infrastructure:
- Resource Group
- Azure Container Registry (ACR)
- Azure Kubernetes Service (AKS) cluster
- Network configuration
- Namespaces and secrets

**Usage:**
```bash
# Make script executable
chmod +x 01-setup-azure-resources.sh

# Run setup
./01-setup-azure-resources.sh
```

**Configuration:**
Edit the following variables in the script before running:
- `RESOURCE_GROUP`: Name of the Azure resource group
- `LOCATION`: Azure region (e.g., eastus, westus2)
- `AKS_CLUSTER_NAME`: Name for the AKS cluster
- `ACR_NAME`: Name for the container registry (must be globally unique)
- `NODE_COUNT`: Number of nodes in the cluster
- `NODE_SIZE`: VM size for nodes

### 02-install-argocd.sh
Installs and configures Argo CD:
- Deploys Argo CD to the cluster
- Configures LoadBalancer service
- Retrieves admin credentials
- Optionally installs Argo CD CLI

**Usage:**
```bash
# Make script executable
chmod +x 02-install-argocd.sh

# Run installation
./02-install-argocd.sh
```

### 99-teardown.sh
Completely removes all Azure resources:
- Deletes the entire resource group
- Removes local kubectl context

**Usage:**
```bash
# Make script executable
chmod +x 99-teardown.sh

# Run teardown
./99-teardown.sh
```

**⚠️ WARNING:** This action cannot be undone!

## Setup Flow

1. **Azure Login**
   ```bash
   az login
   az account set --subscription "Your Subscription Name"
   ```

2. **Run Infrastructure Setup**
   ```bash
   ./01-setup-azure-resources.sh
   ```
   
   This takes approximately 10-15 minutes.

3. **Install Argo CD**
   ```bash
   ./02-install-argocd.sh
   ```
   
   This takes approximately 3-5 minutes.

4. **Configure GitHub Secrets**
   
   After setup, create these secrets in your GitHub repository:
   
   - `AZURE_CREDENTIALS`: Azure service principal credentials
     ```bash
     az ad sp create-for-rbac --name 'github-actions-gitops' \
       --role contributor \
       --scopes /subscriptions/<SUBSCRIPTION_ID>/resourceGroups/<RESOURCE_GROUP> \
       --sdk-auth
     ```
   
   - `GITOPS_PAT`: GitHub Personal Access Token with repo permissions

5. **Update Repository URLs**
   
   Update the repository URL in:
   - `argo/application-dev.yaml`
   - `argo/application-stage.yaml`
   - `argo/application-prod.yaml`
   - `argo/applicationset.yaml`

6. **Update ACR Name**
   
   Update the ACR name in:
   - `helm/values.yaml`
   - `environments/dev/values.yaml`
   - `environments/stage/values.yaml`
   - `environments/prod/values.yaml`
   - `.github/workflows/ci-cd.yaml`

## Cost Estimation

Approximate monthly costs (as of 2024):
- AKS cluster (3 x Standard_D2s_v3): ~$150-200/month
- ACR Standard: ~$20/month
- Load Balancers: ~$20-30/month
- Network egress: Variable

**Total: ~$200-250/month**

Remember to run `99-teardown.sh` when done to avoid charges!

## Troubleshooting

### AKS cluster creation fails
- Check subscription limits
- Verify the VM size is available in your region
- Ensure you have sufficient quota

### Cannot access Argo CD UI
- Wait 2-3 minutes for LoadBalancer to provision
- Check firewall rules
- Verify service is running: `kubectl get svc -n argocd`

### ACR authentication issues
- Verify ACR admin user is enabled
- Check secret creation in namespaces
- Re-run secret creation section if needed

## Additional Resources

- [Azure AKS Documentation](https://docs.microsoft.com/en-us/azure/aks/)
- [Azure ACR Documentation](https://docs.microsoft.com/en-us/azure/container-registry/)
- [Argo CD Documentation](https://argo-cd.readthedocs.io/)
