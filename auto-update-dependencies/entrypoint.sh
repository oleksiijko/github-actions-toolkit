#!/bin/bash
set -e

PACKAGE_MANAGER=$1
COMMIT_MESSAGE=$2
BRANCH=$3

# Update dependencies
if [ "$PACKAGE_MANAGER" = "npm" ]; then
  echo "Updating npm dependencies..."
  npm install
  npm update
elif [ "$PACKAGE_MANAGER" = "yarn" ]; then
  echo "Updating yarn dependencies..."
  yarn install
  yarn upgrade
elif [ "$PACKAGE_MANAGER" = "pip" ]; then
  echo "Updating pip dependencies..."
  pip install --upgrade -r requirements.txt
else
  echo "Unsupported package manager: $PACKAGE_MANAGER"
  exit 1
fi

# Commit changes
git add .
git commit -m "$COMMIT_MESSAGE"
git push origin "$BRANCH"
