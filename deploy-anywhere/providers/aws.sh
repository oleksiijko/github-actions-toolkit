#!/bin/bash
set -e

DIRECTORY=$1
ENVIRONMENT=$2
CREDENTIALS=$3

# Configure AWS credentials
echo "$CREDENTIALS" > aws_credentials.json
export AWS_ACCESS_KEY_ID=$(jq -r .accessKeyId aws_credentials.json)
export AWS_SECRET_ACCESS_KEY=$(jq -r .secretAccessKey aws_credentials.json)
export AWS_DEFAULT_REGION=$(jq -r .region aws_credentials.json)

S3_BUCKET=$(jq -r .s3Bucket aws_credentials.json)
CLOUDFRONT_ID=$(jq -r .cloudfrontId aws_credentials.json)

# Deploy to S3
if [ -n "$S3_BUCKET" ]; then
  echo "Deploying to S3 bucket: $S3_BUCKET"
  aws s3 sync "$DIRECTORY" "s3://$S3_BUCKET/$ENVIRONMENT" --delete
  
  # Invalidate CloudFront cache if ID provided
  if [ -n "$CLOUDFRONT_ID" ]; then
    echo "Invalidating CloudFront distribution: $CLOUDFRONT_ID"
    aws cloudfront create-invalidation --distribution-id "$CLOUDFRONT_ID" --paths "/$ENVIRONMENT/*"
  fi
  
  # Set output variables
  DEPLOY_URL="https://$S3_BUCKET.s3.amazonaws.com/$ENVIRONMENT/index.html"
  DEPLOY_VERSION=$(date +%s)
else
  # Check for serverless.yml and deploy with Serverless Framework
  if [ -f "$DIRECTORY/serverless.yml" ]; then
    echo "Detected serverless.yml, deploying with Serverless Framework"
    npm install -g serverless
    cd "$DIRECTORY"
    serverless deploy --stage "$ENVIRONMENT"
    
    # Extract URL from serverless output
    DEPLOY_URL=$(serverless info --stage "$ENVIRONMENT" | grep -oP 'https://[^[:space:]]+')
    DEPLOY_VERSION=$(date +%s)
  else
    echo "No S3 bucket specified and no serverless.yml found"
    exit 1
  fi
fi

# Clean up credentials
rm aws_credentials.json

echo "Deployed to AWS successfully"