#!/bin/bash
set -e

PACKAGE_MANAGER=${INPUT_PACKAGE_MANAGER:-npm}
COMMIT_MSG=${INPUT_COMMIT_MESSAGE:-"chore: update dependencies"}
BRANCH=${INPUT_BRANCH:-main}

echo "📦 Updating dependencies using $PACKAGE_MANAGER..."

if [ "$PACKAGE_MANAGER" == "npm" ]; then
  npm install
  npm update
  git config --global user.email "bot@example.com"
  git config --global user.name "Update Bot"
  git add package.json package-lock.json
  git commit -m "$COMMIT_MSG" || echo "🟡 Nothing to commit"
fi
