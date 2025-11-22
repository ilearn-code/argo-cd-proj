#!/bin/bash

#############################################
# Azure Infrastructure Setup Script
# Creates AKS cluster and ACR for GitOps demo
#############################################

set -e

# Configuration variables - UPDATE THESE
export RESOURCE_GROUP="rg-gitops-demo"
export LOCATION="eastus"
export AKS_CLUSTER_NAME="aks-gitops-demo"
export ACR_NAME="acrilearncode2024"  # Must be globally unique, lowercase alphanumeric only
export NODE_COUNT=3
export NODE_SIZE="Standard_D2s_v3"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo -e "${GREEN}========================================${NC}"
echo -e "${GREEN}Azure GitOps Infrastructure Setup${NC}"
echo -e "${GREEN}========================================${NC}"

# Check if Azure CLI is installed
if ! command -v az &> /dev/null; then
    echo -e "${RED}Error: Azure CLI is not installed${NC}"
    echo "Please install from: https://docs.microsoft.com/en-us/cli/azure/install-azure-cli"
    exit 1
fi

# Login to Azure
echo -e "\n${YELLOW}Step 1: Azure Login${NC}"
az account show &> /dev/null || az login

# Get current subscription
SUBSCRIPTION_ID=$(az account show --query id -o tsv)
echo -e "${GREEN}Using subscription: ${SUBSCRIPTION_ID}${NC}"

# Create Resource Group
echo -e "\n${YELLOW}Step 2: Creating Resource Group${NC}"
az group create \
    --name ${RESOURCE_GROUP} \
    --location ${LOCATION} \
    --tags environment=demo project=gitops

# Create Azure Container Registry
echo -e "\n${YELLOW}Step 3: Creating Azure Container Registry${NC}"
az acr create \
    --resource-group ${RESOURCE_GROUP} \
    --name ${ACR_NAME} \
    --sku Standard \
    --location ${LOCATION} \
    --admin-enabled true

echo -e "${GREEN}ACR created successfully: ${ACR_NAME}.azurecr.io${NC}"

# Create AKS Cluster
echo -e "\n${YELLOW}Step 4: Creating AKS Cluster (this may take 10-15 minutes)${NC}"
az aks create \
    --resource-group ${RESOURCE_GROUP} \
    --name ${AKS_CLUSTER_NAME} \
    --node-count ${NODE_COUNT} \
    --node-vm-size ${NODE_SIZE} \
    --network-plugin azure \
    --enable-managed-identity \
    --attach-acr ${ACR_NAME} \
    --generate-ssh-keys \
    --enable-addons monitoring \
    --tags environment=demo project=gitops

echo -e "${GREEN}AKS cluster created successfully${NC}"

# Get AKS credentials
echo -e "\n${YELLOW}Step 5: Configuring kubectl${NC}"
az aks get-credentials \
    --resource-group ${RESOURCE_GROUP} \
    --name ${AKS_CLUSTER_NAME} \
    --overwrite-existing

# Verify cluster connection
echo -e "\n${YELLOW}Step 6: Verifying cluster connection${NC}"
kubectl cluster-info
kubectl get nodes

# Create namespaces for environments
echo -e "\n${YELLOW}Step 7: Creating namespaces${NC}"
kubectl create namespace argocd --dry-run=client -o yaml | kubectl apply -f -
kubectl create namespace gitops-demo-dev --dry-run=client -o yaml | kubectl apply -f -
kubectl create namespace gitops-demo-stage --dry-run=client -o yaml | kubectl apply -f -
kubectl create namespace gitops-demo-prod --dry-run=client -o yaml | kubectl apply -f -

echo -e "${GREEN}Namespaces created successfully${NC}"

# Get ACR credentials for Kubernetes secret
echo -e "\n${YELLOW}Step 8: Creating ACR credentials secret${NC}"
ACR_USERNAME=$(az acr credential show --name ${ACR_NAME} --query username -o tsv)
ACR_PASSWORD=$(az acr credential show --name ${ACR_NAME} --query passwords[0].value -o tsv)

for NS in gitops-demo-dev gitops-demo-stage gitops-demo-prod; do
    kubectl create secret docker-registry acr-secret \
        --namespace ${NS} \
        --docker-server=${ACR_NAME}.azurecr.io \
        --docker-username=${ACR_USERNAME} \
        --docker-password=${ACR_PASSWORD} \
        --dry-run=client -o yaml | kubectl apply -f -
done

echo -e "${GREEN}ACR credentials configured in all namespaces${NC}"

# Install NGINX Ingress Controller
echo -e "\n${YELLOW}Step 9: Installing NGINX Ingress Controller${NC}"
kubectl apply -f https://raw.githubusercontent.com/kubernetes/ingress-nginx/controller-v1.8.2/deploy/static/provider/cloud/deploy.yaml

echo -e "${GREEN}Waiting for Ingress Controller to be ready...${NC}"
kubectl wait --namespace ingress-nginx \
    --for=condition=ready pod \
    --selector=app.kubernetes.io/component=controller \
    --timeout=300s

# Get Ingress Controller IP
echo -e "\n${YELLOW}Getting Ingress Controller IP...${NC}"
sleep 30
INGRESS_IP=$(kubectl get svc ingress-nginx-controller -n ingress-nginx -o jsonpath='{.status.loadBalancer.ingress[0].ip}')
echo -e "${GREEN}Ingress Controller IP: ${INGRESS_IP}${NC}"

# Output summary
echo -e "\n${GREEN}========================================${NC}"
echo -e "${GREEN}Infrastructure Setup Complete!${NC}"
echo -e "${GREEN}========================================${NC}"
echo -e "\n${YELLOW}Resource Details:${NC}"
echo -e "Resource Group: ${RESOURCE_GROUP}"
echo -e "Location: ${LOCATION}"
echo -e "AKS Cluster: ${AKS_CLUSTER_NAME}"
echo -e "ACR Registry: ${ACR_NAME}.azurecr.io"
echo -e "Ingress IP: ${INGRESS_IP}"
echo -e "\n${YELLOW}Next Steps:${NC}"
echo -e "1. Install Argo CD: ./02-install-argocd.sh"
echo -e "2. Configure GitHub secrets for CI/CD"
echo -e "3. Update DNS records to point to: ${INGRESS_IP}"
echo -e "\n${YELLOW}Credentials:${NC}"
echo -e "ACR Username: ${ACR_USERNAME}"
echo -e "ACR Password: ${ACR_PASSWORD}"
echo -e "\n${YELLOW}Export these for GitHub Secrets:${NC}"
echo -e "AZURE_CREDENTIALS (for GitHub Actions):"
echo -e "${GREEN}Run: az ad sp create-for-rbac --name 'github-actions-gitops' --role contributor --scopes /subscriptions/${SUBSCRIPTION_ID}/resourceGroups/${RESOURCE_GROUP} --sdk-auth${NC}"
