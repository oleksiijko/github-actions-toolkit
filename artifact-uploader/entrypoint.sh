#!/bin/bash
set -e

echo "📦 Uploading artifact: $INPUT_NAME from path: $INPUT_PATH"

if [ ! -e "$INPUT_PATH" ]; then
  echo "❌ Path $INPUT_PATH does not exist."
  exit 1
fi

mkdir -p /artifacts
cp -r "$INPUT_PATH" "/artifacts/$INPUT_NAME"

echo "✅ Artifact prepared at /artifacts/$INPUT_NAME"
