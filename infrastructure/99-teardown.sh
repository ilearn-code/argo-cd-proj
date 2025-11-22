#!/bin/bash

################################################################################
# Teardown Script - Complete Azure Resource Cleanup
#
# This script will DELETE ALL resources created for the GitOps demo:
# - Azure Container Registry (ACR)
# - Azure Kubernetes Service (AKS) cluster
# - All associated networking, storage, and compute resources
# - Entire resource group
#
# WARNING: THIS OPERATION IS IRREVERSIBLE!
#
# Usage:
#   ./99-teardown.sh
#
################################################################################

set -e

# Color codes for output
RED='\033[0;31m'
YELLOW='\033[1;33m'
GREEN='\033[0;32m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configuration
RESOURCE_GROUP="rg-gitops-demo"
CLUSTER_NAME="aks-gitops-demo"
ACR_NAME="acrilearncode2024"

echo -e "${YELLOW}╔════════════════════════════════════════════════════════════════╗${NC}"
echo -e "${YELLOW}║                   RESOURCE TEARDOWN SCRIPT                     ║${NC}"
echo -e "${YELLOW}║                                                                ║${NC}"
echo -e "${YELLOW}║  ⚠️  WARNING: This will DELETE ALL resources in:              ║${NC}"
echo -e "${YELLOW}║      Resource Group: ${RESOURCE_GROUP}                        ║${NC}"
echo -e "${YELLOW}║                                                                ║${NC}"
echo -e "${YELLOW}║  This includes:                                                ║${NC}"
echo -e "${YELLOW}║  - AKS Cluster: ${CLUSTER_NAME}                               ║${NC}"
echo -e "${YELLOW}║  - ACR: ${ACR_NAME}.azurecr.io                                ║${NC}"
echo -e "${YELLOW}║  - All container images                                       ║${NC}"
echo -e "${YELLOW}║  - All deployments and workloads                              ║${NC}"
echo -e "${YELLOW}║  - Load Balancers and Public IPs                              ║${NC}"
echo -e "${YELLOW}║  - Virtual Networks                                           ║${NC}"
echo -e "${YELLOW}║  - All persistent volumes and data                            ║${NC}"
echo -e "${YELLOW}║                                                                ║${NC}"
echo -e "${RED}║  THIS OPERATION CANNOT BE UNDONE!                              ║${NC}"
echo -e "${YELLOW}╚════════════════════════════════════════════════════════════════╝${NC}"
echo ""

# Check if logged into Azure
echo -e "${BLUE}▶ Checking Azure login status...${NC}"
if ! az account show &> /dev/null; then
    echo -e "${RED}✗ Not logged into Azure. Please run 'az login' first.${NC}"
    exit 1
fi

SUBSCRIPTION_ID=$(az account show --query id -o tsv)
SUBSCRIPTION_NAME=$(az account show --query name -o tsv)
echo -e "${GREEN}✓ Logged into Azure${NC}"
echo -e "  Subscription: ${SUBSCRIPTION_NAME}"
echo -e "  ID: ${SUBSCRIPTION_ID}"
echo ""

# Check if resource group exists
echo -e "${BLUE}▶ Checking if resource group exists...${NC}"
if ! az group exists --name $RESOURCE_GROUP -o tsv | grep -q "true"; then
    echo -e "${GREEN}✓ Resource group '${RESOURCE_GROUP}' does not exist.${NC}"
    echo -e "${GREEN}✓ Nothing to delete. Cleaning up kubectl config...${NC}"
    
    # Clean up kubectl context anyway
    kubectl config delete-context $CLUSTER_NAME 2>/dev/null || true
    kubectl config delete-cluster $CLUSTER_NAME 2>/dev/null || true
    
    echo -e "${GREEN}✓ Cleanup complete!${NC}"
    exit 0
fi

echo -e "${GREEN}✓ Resource group found${NC}"
echo ""

# List all resources that will be deleted
echo -e "${BLUE}▶ Resources to be deleted:${NC}"
echo -e "${YELLOW}───────────────────────────────────────────────────────────────${NC}"
az resource list --resource-group $RESOURCE_GROUP --output table
echo -e "${YELLOW}───────────────────────────────────────────────────────────────${NC}"
echo ""

# Calculate approximate cost savings
echo -e "${BLUE}▶ Estimated cost impact:${NC}"
echo -e "  Stopping these resources will save approximately:"
echo -e "  ${GREEN}\$200-250/month${NC} (2-node AKS + Standard ACR + networking)"
echo ""

# Confirmation prompts
echo -e "${RED}═══════════════════════════════════════════════════════════════${NC}"
echo -e "${RED}CONFIRMATION REQUIRED${NC}"
echo -e "${RED}═══════════════════════════════════════════════════════════════${NC}"
echo ""

read -p "$(echo -e ${RED}Type \'DELETE\' to confirm deletion: ${NC})" CONFIRMATION

if [ "$CONFIRMATION" != "DELETE" ]; then
    echo -e "${GREEN}✓ Teardown cancelled. No resources were deleted.${NC}"
    exit 0
fi

echo ""
read -p "$(echo -e ${RED}Type the resource group name \'${RESOURCE_GROUP}\' to proceed: ${NC})" RG_CONFIRMATION

if [ "$RG_CONFIRMATION" != "$RESOURCE_GROUP" ]; then
    echo -e "${GREEN}✓ Teardown cancelled. No resources were deleted.${NC}"
    exit 0
fi

echo ""
echo -e "${RED}Starting deletion in 10 seconds... Press Ctrl+C to cancel!${NC}"
for i in {10..1}; do
    echo -ne "${RED}${i}... ${NC}"
    sleep 1
done
echo ""
echo ""

# Start deletion
echo -e "${YELLOW}═══════════════════════════════════════════════════════════════${NC}"
echo -e "${RED}Starting resource deletion...${NC}"
echo -e "${YELLOW}═══════════════════════════════════════════════════════════════${NC}"
echo ""

# Step 1: Delete the resource group
echo -e "${BLUE}▶ Step 1/2: Deleting Azure resource group...${NC}"
echo -e "  This will delete all resources within the group"
echo -e "  Estimated time: 10-15 minutes"
echo ""

START_TIME=$(date +%s)

az group delete \
    --name $RESOURCE_GROUP \
    --yes \
    --no-wait=false

END_TIME=$(date +%s)
DURATION=$((END_TIME - START_TIME))
MINUTES=$((DURATION / 60))
SECONDS=$((DURATION % 60))

echo ""
echo -e "${GREEN}✓ Resource group deleted successfully${NC}"
echo -e "  Time taken: ${MINUTES}m ${SECONDS}s"
echo ""

# Step 2: Clean up kubectl configuration
echo -e "${BLUE}▶ Step 2/2: Cleaning up local kubectl configuration...${NC}"

if kubectl config get-contexts -o name 2>/dev/null | grep -q "$CLUSTER_NAME"; then
    kubectl config delete-context $CLUSTER_NAME 2>/dev/null || true
    echo -e "${GREEN}✓ Removed kubectl context: ${CLUSTER_NAME}${NC}"
fi

if kubectl config get-clusters 2>/dev/null | grep -q "$CLUSTER_NAME"; then
    kubectl config delete-cluster $CLUSTER_NAME 2>/dev/null || true
    echo -e "${GREEN}✓ Removed kubectl cluster: ${CLUSTER_NAME}${NC}"
fi

# Remove cluster user credentials
CLUSTER_USER="clusterUser_${RESOURCE_GROUP}_${CLUSTER_NAME}"
if kubectl config view -o jsonpath='{.users[*].name}' 2>/dev/null | grep -q "$CLUSTER_USER"; then
    kubectl config unset users.$CLUSTER_USER 2>/dev/null || true
    echo -e "${GREEN}✓ Removed kubectl user credentials${NC}"
fi

echo ""
echo -e "${YELLOW}═══════════════════════════════════════════════════════════════${NC}"
echo -e "${GREEN}✓ TEARDOWN COMPLETE${NC}"
echo -e "${YELLOW}═══════════════════════════════════════════════════════════════${NC}"
echo ""
echo -e "${GREEN}Successfully deleted:${NC}"
echo -e "  ✓ Resource Group: ${RESOURCE_GROUP}"
echo -e "  ✓ AKS Cluster: ${CLUSTER_NAME}"
echo -e "  ✓ ACR: ${ACR_NAME}.azurecr.io"
echo -e "  ✓ All container images"
echo -e "  ✓ All networking resources (Load Balancers, Public IPs, VNets)"
echo -e "  ✓ All storage resources"
echo -e "  ✓ kubectl configuration"
echo ""
echo -e "${BLUE}Manual cleanup (if applicable):${NC}"
echo -e "  • DNS records for custom domains:"
echo -e "    - dev.satyamay.tech"
echo -e "    - stage.satyamay.tech"
echo -e "    - prod.satyamay.tech"
echo -e "    - argocd.satyamay.tech"
echo -e ""
echo -e "  • GitHub repository secrets (Settings → Secrets):"
echo -e "    - AZURE_CREDENTIALS"
echo -e "    - GITOPS_PAT"
echo -e ""
echo -e "  • Azure service principal (if you want to remove it):"
echo -e "    ${YELLOW}az ad sp list --display-name 'github-actions-gitops-demo' --query [].appId -o tsv${NC}"
echo -e "    ${YELLOW}az ad sp delete --id <service-principal-id>${NC}"
echo -e ""
echo -e "${GREEN}Cost savings: ~\$200-250/month${NC}"
echo -e ""
echo -e "${BLUE}Thank you for using this GitOps demo!${NC}"
echo -e "${BLUE}Repository: https://github.com/ilearn-code/argo-cd-proj${NC}"
echo ""
