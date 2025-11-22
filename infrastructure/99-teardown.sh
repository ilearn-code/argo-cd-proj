#!/bin/bash

#############################################
# Complete Teardown Script
# Removes all Azure resources
#############################################

set -e

# Configuration variables - MUST match setup script
export RESOURCE_GROUP="rg-gitops-demo"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo -e "${RED}========================================${NC}"
echo -e "${RED}Azure GitOps Infrastructure Teardown${NC}"
echo -e "${RED}========================================${NC}"

echo -e "\n${YELLOW}WARNING: This will delete the following resources:${NC}"
echo -e "- Resource Group: ${RESOURCE_GROUP}"
echo -e "- All resources within the group (AKS, ACR, etc.)"
echo -e "\n${RED}This action cannot be undone!${NC}"
read -p "Are you sure you want to continue? (type 'yes' to confirm): " CONFIRM

if [ "$CONFIRM" != "yes" ]; then
    echo -e "${GREEN}Teardown cancelled${NC}"
    exit 0
fi

# Delete Resource Group (this deletes everything inside)
echo -e "\n${YELLOW}Deleting Resource Group (this may take 5-10 minutes)...${NC}"
az group delete \
    --name ${RESOURCE_GROUP} \
    --yes \
    --no-wait

echo -e "${GREEN}Deletion initiated. Resources are being removed in the background.${NC}"
echo -e "${YELLOW}Check status with: az group show --name ${RESOURCE_GROUP}${NC}"

# Clean up local kubectl context
echo -e "\n${YELLOW}Cleaning up kubectl context...${NC}"
kubectl config delete-context "aks-gitops-demo" 2>/dev/null || true

echo -e "${GREEN}========================================${NC}"
echo -e "${GREEN}Teardown Complete!${NC}"
echo -e "${GREEN}========================================${NC}"
