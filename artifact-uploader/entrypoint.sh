#!/bin/bash
set -e

echo "📦 Auto-collecting artifacts..."

DEFAULT_PATHS=(
  "dist"
  "*.log"
  "*.md"
  "report.*"
  "coverage"
)

FOUND_FILES=()

for pattern in "${DEFAULT_PATHS[@]}"; do
  matches=( $(find . -type f -path "./$pattern" -o -name "$pattern" 2>/dev/null) )
  for match in "${matches[@]}"; do
    FOUND_FILES+=("$match")
  done
done

if [ ${#FOUND_FILES[@]} -eq 0 ]; then
  echo "⚠️ No matching artifacts found. Exiting."
  exit 0
fi

mkdir -p /artifacts
for file in "${FOUND_FILES[@]}"; do
  cp --parents "$file" /artifacts/
done

echo "✅ Collected ${#FOUND_FILES[@]} files:"
for f in "${FOUND_FILES[@]}"; do
  echo "  - $f"
done
