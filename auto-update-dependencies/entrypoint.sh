#!/bin/bash
set -e

PACKAGE_MANAGER=$1
COMMIT_MESSAGE=$2
BRANCH=$3

# Configure Git
git config --global user.email "action-bot@github.com"
git config --global user.name "github-actions[bot]"

# Update dependencies
if [ "$PACKAGE_MANAGER" = "npm" ]; then
  npm install
  npm update
elif [ "$PACKAGE_MANAGER" = "yarn" ]; then
  yarn install
  yarn upgrade
elif [ "$PACKAGE_MANAGER" = "pip" ]; then
  pip install --upgrade -r requirements.txt
else
  echo "Unsupported package manager: $PACKAGE_MANAGER"
  exit 1
fi

git add .
git commit -m "$COMMIT_MESSAGE" || echo "No changes to commit"
git push origin "$BRANCH"
