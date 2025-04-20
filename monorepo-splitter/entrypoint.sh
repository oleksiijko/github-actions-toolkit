#!/bin/sh
set -e

SOURCE="$INPUT_SOURCE"
TARGET_REPO="$INPUT_TARGET_REPO"
BRANCH="${INPUT_BRANCH:-main}"

echo "📦 Splitting $SOURCE to $TARGET_REPO (branch: $BRANCH)..."

# Git config
git config --global user.email "github-actions@github.com"
git config --global user.name "GitHub Actions"

TMP_DIR=$(mktemp -d)

cp -r "$SOURCE" "$TMP_DIR/repo"
cd "$TMP_DIR/repo"
git init
git remote add origin "$TARGET_REPO"
git checkout -b "$BRANCH"
git add .
git commit -m "🔄 Automated split from monorepo"
git push -f origin "$BRANCH"

echo "✅ Split completed and pushed to $TARGET_REPO"
