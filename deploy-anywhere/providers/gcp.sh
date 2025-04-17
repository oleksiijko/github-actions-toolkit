#!/bin/bash
set -e

DIRECTORY=$1
ENVIRONMENT=$2
CREDENTIALS=$3

# Configure GCP credentials
echo "$CREDENTIALS" > gcp_credentials.json
export GOOGLE_APPLICATION_CREDENTIALS=gcp_credentials.json

# Login to GCP CLI
gcloud auth activate-service-account --key-file="$GOOGLE_APPLICATION_CREDENTIALS"

# Deploy to Google App Engine
echo "Deploying to Google App Engine..."

gcloud app browse --project "$ENVIRONMENT-$DIRECTORY"

# Set output variables
DEPLOY_URL="https://$DIRECTORY.appspot.com"
DEPLOY_VERSION=$(date +%Y%m%d%H%M%S)

# Clean up credentials
rm gcp_credentials.json

echo "Deployed to GCP successfully"
echo "Deployment URL: $DEPLOY_URL"
echo "Version: $DEPLOY_VERSION"
