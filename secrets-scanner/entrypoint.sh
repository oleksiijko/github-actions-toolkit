#!/bin/bash
set -e

echo "🔍 Scanning for secrets..."

# Простой пример поиска API ключей в коде
grep -r --exclude-dir=.git -E "AKIA[0-9A-Z]{16}" . || echo "✅ No AWS keys found"
grep -r --exclude-dir=.git -E "ghp_[A-Za-z0-9]{36}" . || echo "✅ No GitHub tokens found"

echo "✅ Scan completed."
