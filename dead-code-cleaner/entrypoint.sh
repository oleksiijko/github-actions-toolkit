#!/bin/sh
set -e

echo "🧹 Scanning for dead code in $INPUT_PATH..."

cd "$INPUT_PATH"

unimported --silent || true
