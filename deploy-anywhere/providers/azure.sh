#!/bin/bash
set -e

DIRECTORY=$1
ENVIRONMENT=$2
CREDENTIALS=$3

# Configure Azure credentials
echo "$CREDENTIALS" > azure_credentials.json
export AZURE_SUBSCRIPTION_ID=$(jq -r .subscriptionId azure_credentials.json)
export AZURE_CLIENT_ID=$(jq -r .clientId azure_credentials.json)
export AZURE_CLIENT_SECRET=$(jq -r .clientSecret azure_credentials.json)
export AZURE_TENANT_ID=$(jq -r .tenantId azure_credentials.json)

# Login to Azure CLI
az login --service-principal --username "$AZURE_CLIENT_ID" --password "$AZURE_CLIENT_SECRET" --tenant "$AZURE_TENANT_ID"
az account set --subscription "$AZURE_SUBSCRIPTION_ID"

# Create or use existing Web App Service
echo "Deploying to Azure Web App..."

az webapp up --name "$ENVIRONMENT-$DIRECTORY" --resource-group "$ENVIRONMENT-rg" --plan "$ENVIRONMENT-plan" --sku B1 --location EastUS

# Set output variables
DEPLOY_URL="https://$ENVIRONMENT-$DIRECTORY.azurewebsites.net"
DEPLOY_VERSION=$(date +%Y%m%d%H%M%S)

# Clean up credentials
rm azure_credentials.json

echo "Deployed to Azure successfully"
echo "Deployment URL: $DEPLOY_URL"
echo "Version: $DEPLOY_VERSION"
