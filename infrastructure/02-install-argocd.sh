#!/bin/bash

#############################################
# Argo CD Installation Script
# Installs and configures Argo CD on AKS
#############################################

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo -e "${GREEN}========================================${NC}"
echo -e "${GREEN}Argo CD Installation${NC}"
echo -e "${GREEN}========================================${NC}"

# Check if kubectl is configured
if ! kubectl cluster-info &> /dev/null; then
    echo -e "${RED}Error: kubectl is not configured or cluster is not accessible${NC}"
    exit 1
fi

# Install Argo CD
echo -e "\n${YELLOW}Step 1: Installing Argo CD${NC}"
kubectl apply -n argocd -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml

echo -e "${GREEN}Waiting for Argo CD to be ready...${NC}"
kubectl wait --for=condition=available --timeout=300s deployment/argocd-server -n argocd

# Change Argo CD service to LoadBalancer (or use Ingress in production)
echo -e "\n${YELLOW}Step 2: Configuring Argo CD Service${NC}"
kubectl patch svc argocd-server -n argocd -p '{"spec": {"type": "LoadBalancer"}}'

# Wait for external IP
echo -e "${GREEN}Waiting for LoadBalancer IP...${NC}"
sleep 30

ARGOCD_SERVER=$(kubectl get svc argocd-server -n argocd -o jsonpath='{.status.loadBalancer.ingress[0].ip}')
echo -e "${GREEN}Argo CD Server IP: ${ARGOCD_SERVER}${NC}"

# Get initial admin password
echo -e "\n${YELLOW}Step 3: Retrieving Admin Credentials${NC}"
ARGOCD_PASSWORD=$(kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath="{.data.password}" | base64 -d)

echo -e "${GREEN}========================================${NC}"
echo -e "${GREEN}Argo CD Installation Complete!${NC}"
echo -e "${GREEN}========================================${NC}"
echo -e "\n${YELLOW}Access Details:${NC}"
echo -e "URL: https://${ARGOCD_SERVER}"
echo -e "Username: admin"
echo -e "Password: ${ARGOCD_PASSWORD}"
echo -e "\n${YELLOW}Note: Accept the self-signed certificate warning in your browser${NC}"

# Optional: Install Argo CD CLI
echo -e "\n${YELLOW}Step 4: Installing Argo CD CLI (optional)${NC}"
read -p "Do you want to install Argo CD CLI? (y/n) " -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]; then
    if [[ "$OSTYPE" == "linux-gnu"* ]]; then
        curl -sSL -o /tmp/argocd https://github.com/argoproj/argo-cd/releases/latest/download/argocd-linux-amd64
        sudo install -m 555 /tmp/argocd /usr/local/bin/argocd
        rm /tmp/argocd
    elif [[ "$OSTYPE" == "darwin"* ]]; then
        brew install argocd
    fi
    echo -e "${GREEN}Argo CD CLI installed${NC}"
    
    # Login with CLI
    echo -e "\n${YELLOW}Logging in to Argo CD...${NC}"
    argocd login ${ARGOCD_SERVER} --username admin --password ${ARGOCD_PASSWORD} --insecure
fi

# Configure Argo CD for Git repository
echo -e "\n${YELLOW}Step 5: Repository Configuration${NC}"
echo -e "To connect your Git repository to Argo CD:"
echo -e "1. Go to Settings → Repositories"
echo -e "2. Click 'Connect Repo'"
echo -e "3. Choose 'Via HTTPS' and enter your repository URL"
echo -e "4. Use GitHub Personal Access Token for authentication"

# Create example project (optional)
echo -e "\n${YELLOW}Step 6: Creating example project${NC}"
kubectl apply -f - <<EOF
apiVersion: argoproj.io/v1alpha1
kind: AppProject
metadata:
  name: gitops-demo
  namespace: argocd
spec:
  description: GitOps Demo Project
  sourceRepos:
    - '*'
  destinations:
    - namespace: 'gitops-demo-*'
      server: https://kubernetes.default.svc
    - namespace: argocd
      server: https://kubernetes.default.svc
  clusterResourceWhitelist:
    - group: '*'
      kind: '*'
EOF

echo -e "${GREEN}Example project created${NC}"

echo -e "\n${YELLOW}Next Steps:${NC}"
echo -e "1. Access Argo CD UI at https://${ARGOCD_SERVER}"
echo -e "2. Change the default admin password"
echo -e "3. Connect your Git repository"
echo -e "4. Deploy applications using: kubectl apply -f argo/application-dev.yaml"
