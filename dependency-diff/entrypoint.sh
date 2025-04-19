#!/bin/bash
set -e

TARGET_DIR="${INPUT_PATH:-.}"

echo "📦 Comparing dependencies in: $TARGET_DIR"

cd "$TARGET_DIR"

if [ ! -f package.json ]; then
  echo "❌ No package.json found in $TARGET_DIR"
  exit 1
fi

cp package.json package.json.before

echo "🧪 Installing..."
npm install --package-lock-only > /dev/null 2>&1

echo "🔄 Comparing package-lock.json diff..."
npm install > /dev/null 2>&1
cp package.json package.json.after

ADDED=$(diff -u package.json.before package.json.after | grep '^+\s*"' | grep -v '^+++' || true)
REMOVED=$(diff -u package.json.before package.json.after | grep '^-\s*"' | grep -v '^---' || true)

{
  echo "## 📦 Dependency Diff"
  echo ""
  if [[ -n "$ADDED" ]]; then
    echo "### ➕ Added:"
    echo '```diff'
    echo "$ADDED"
    echo '```'
  fi
  if [[ -n "$REMOVED" ]]; then
    echo "### ➖ Removed:"
    echo '```diff'
    echo "$REMOVED"
    echo '```'
  fi
  if [[ -z "$ADDED" && -z "$REMOVED" ]]; then
    echo "✅ No changes in dependencies."
  fi
} > deps-diff.md

echo "✅ Dependency diff saved to deps-diff.md"
