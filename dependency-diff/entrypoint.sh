#!/bin/sh
set -e

git config --global --add safe.directory /github/workspace

echo "🔍 Comparing dependencies with base ref: $INPUT_BASE"

cd "$INPUT_PATH"

git fetch origin "$INPUT_BASE"

diff=$(git diff origin/"$INPUT_BASE"...HEAD -- package.json || true)

if [ -z "$diff" ]; then
  echo "✅ No changes in package.json"
  echo "No dependency changes detected." > dep-diff.md
else
  echo "📦 Changes detected in package.json:"
  echo "$diff"
  echo '```diff' > dep-diff.md
  echo "$diff" >> dep-diff.md
  echo '```' >> dep-diff.md
fi

cp dep-diff.md /github/workspace/dep-diff.md
