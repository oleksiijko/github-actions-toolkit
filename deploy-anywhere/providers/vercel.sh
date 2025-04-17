#!/bin/bash
set -e

DIRECTORY=$1
ENVIRONMENT=$2
CREDENTIALS=$3

# Configure Vercel credentials
echo "$CREDENTIALS" > vercel_token.json
VERCEL_TOKEN=$(jq -r .token vercel_token.json)
PROJECT_ID=$(jq -r .projectId vercel_token.json)
TEAM_ID=$(jq -r .teamId vercel_token.json 2>/dev/null || echo "")

# Login to Vercel CLI
export VERCEL_TOKEN="$VERCEL_TOKEN"

# Create vercel.json if it doesn't exist
if [ ! -f "$DIRECTORY/vercel.json" ]; then
  echo "Creating default vercel.json configuration"
  cat > "$DIRECTORY/vercel.json" << EOF
{
  "version": 2,
  "builds": [
    { "src": "**", "use": "@vercel/static" }
  ],
  "routes": [
    { "src": "/(.*)", "dest": "/$1" }
  ]
}
EOF
fi

# Deploy to Vercel
cd "$DIRECTORY"

DEPLOY_ARGS="--prod"
if [ "$ENVIRONMENT" != "prod" ] && [ "$ENVIRONMENT" != "production" ]; then
  DEPLOY_ARGS="--env $ENVIRONMENT"
fi

if [ -n "$PROJECT_ID" ]; then
  DEPLOY_ARGS="$DEPLOY_ARGS --name $PROJECT_ID"
fi

if [ -n "$TEAM_ID" ]; then
  DEPLOY_ARGS="$DEPLOY_ARGS --scope $TEAM_ID"
fi

DEPLOYMENT_OUTPUT=$(vercel deploy $DEPLOY_ARGS -y)

# Extract deployment URL
DEPLOY_URL=$(echo "$DEPLOYMENT_OUTPUT" | grep -o 'https://[^ ]\+' | head -1)
DEPLOY_VERSION=$(echo "$DEPLOYMENT_OUTPUT" | grep -o 'dpl_[^ ]\+' | head -1)

# Clean up credentials
rm vercel_token.json

echo "Deployed to Vercel successfully"