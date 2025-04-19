#!/bin/bash
set -e

BASE_REF="${INPUT_BASE:-main}"
TARGET_PATH="${INPUT_PATH:-.}"

echo "🔍 Comparing dependencies with base ref: $BASE_REF"

git fetch origin "$BASE_REF"

# Create temporary copies
mkdir -p /tmp/base /tmp/head

git show "origin/$BASE_REF:$TARGET_PATH/package-lock.json" > /tmp/base/package-lock.json || echo "{}" > /tmp/base/package-lock.json
cp "$TARGET_PATH/package-lock.json" /tmp/head/package-lock.json || echo "{}" > /tmp/head/package-lock.json

node /app/utils/diff.js /tmp/base/package-lock.json /tmp/head/package-lock.json > diff.md

echo "📋 Dependency diff generated:"
cat diff.md
