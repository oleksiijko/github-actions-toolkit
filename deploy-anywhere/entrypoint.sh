#!/bin/bash
set -e

PROVIDER=$1
CONFIG_FILE=$2
DIRECTORY=$3
ENVIRONMENT=$4
CREDENTIALS=$5
LANGUAGE=$6

# Load configuration if file exists
if [ -f "$CONFIG_FILE" ]; then
  echo "Loading deployment configuration from $CONFIG_FILE"
  source "$CONFIG_FILE"
fi

# Prepare credentials
if [ -f "$CREDENTIALS" ]; then
  CREDENTIALS_CONTENT=$(cat "$CREDENTIALS")
else
  CREDENTIALS_CONTENT="$CREDENTIALS"
fi

# Check if directory exists
if [ ! -d "$DIRECTORY" ]; then
  echo "Directory not found: $DIRECTORY"
  exit 1
fi

# Build project based on language
echo "Building project for $LANGUAGE..."
case $LANGUAGE in
  node|javascript|typescript|react|nextjs)
    echo "Running npm build..."
    npm install --prefix $DIRECTORY
    npm run build --prefix $DIRECTORY
    ;;
  python)
    echo "Running pip install..."
    pip install -r $DIRECTORY/requirements.txt
    ;;
  java)
    echo "Running maven build..."
    mvn clean install -f $DIRECTORY/pom.xml
    ;;
  go)
    echo "Running go build..."
    go build -o $DIRECTORY/output $DIRECTORY/*.go
    ;;
  ruby)
    echo "Running bundle install..."
    bundle install --path vendor/bundle --deployment --gemfile=$DIRECTORY/Gemfile
    ;;
  php)
    echo "Running composer install..."
    composer install --working-dir=$DIRECTORY
    ;;
  rust)
    echo "Running cargo build..."
    cargo build --release --manifest-path=$DIRECTORY/Cargo.toml
    ;;
  elixir)
    echo "Running mix deps.get..."
    mix deps.get --only prod
    mix compile
    ;;
  dotnet)
    echo "Running dotnet publish..."
    dotnet publish $DIRECTORY/*.csproj -c Release -o ./publish
    ;;
  *)
    echo "Unsupported language: $LANGUAGE"
    exit 1
    ;;
esac

# Call provider-specific deployment script
case $PROVIDER in
  aws)
    source /providers/aws.sh "$DIRECTORY" "$ENVIRONMENT" "$CREDENTIALS_CONTENT"
    ;;
  azure)
    source /providers/azure.sh "$DIRECTORY" "$ENVIRONMENT" "$CREDENTIALS_CONTENT"
    ;;
  gcp)
    source /providers/gcp.sh "$DIRECTORY" "$ENVIRONMENT" "$CREDENTIALS_CONTENT"
    ;;
  netlify)
    source /providers/netlify.sh "$DIRECTORY" "$ENVIRONMENT" "$CREDENTIALS_CONTENT"
    ;;
  vercel)
    source /providers/vercel.sh "$DIRECTORY" "$ENVIRONMENT" "$CREDENTIALS_CONTENT"
    ;;
  *)
    echo "Provider not supported: $PROVIDER"
    exit 1
    ;;
esac

# Set GitHub outputs
echo "url=$DEPLOY_URL" >> $GITHUB_OUTPUT
echo "version=$DEPLOY_VERSION" >> $GITHUB_OUTPUT

echo "Deployment completed successfully!"
