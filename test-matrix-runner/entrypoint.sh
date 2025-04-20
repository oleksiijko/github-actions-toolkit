#!/bin/bash
set -e

TEST_COMMAND=$1

echo "📦 Installing dependencies..."
if [ -f "package-lock.json" ]; then
  npm ci
else
  npm install
fi

echo "🧪 Running test command: $TEST_COMMAND"
eval "$TEST_COMMAND"
