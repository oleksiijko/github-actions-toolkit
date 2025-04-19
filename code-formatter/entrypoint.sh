#!/bin/bash
set -e

echo "🧹 Running prettier on current directory"
npx prettier --write .
