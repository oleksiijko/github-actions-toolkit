#!/bin/bash
set -e

DIRECTORY=$1
ENVIRONMENT=$2
CREDENTIALS=$3

# Configure Netlify credentials
echo "$CREDENTIALS" > netlify_credentials.json
export NETLIFY_API_TOKEN=$(jq -r .token netlify_credentials.json)
export NETLIFY_SITE_ID=$(jq -r .siteId netlify_credentials.json)

# Login to Netlify CLI
export NETLIFY_TOKEN="$NETLIFY_API_TOKEN"

# Deploy to Netlify using CLI
echo "Deploying to Netlify..."
netlify deploy --prod --dir="$DIRECTORY" --site="$NETLIFY_SITE_ID" --token="$NETLIFY_API_TOKEN"

# Set output variables
DEPLOY_URL="https://$ENVIRONMENT-$DIRECTORY.netlify.app"
DEPLOY_VERSION=$(date +%Y%m%d%H%M%S)

# Clean up credentials
rm netlify_credentials.json

echo "Deployed to Netlify successfully"
echo "Deployment URL: $DEPLOY_URL"
echo "Version: $DEPLOY_VERSION"
