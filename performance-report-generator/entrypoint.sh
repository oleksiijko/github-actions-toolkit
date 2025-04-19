#!/bin/bash
set -e

URL=$1
OUTPUT_FORMAT=$2

if [ -z "$URL" ]; then
  echo "❌ Please provide a url"
  exit 1
fi

# Запуск Lighthouse
lighthouse "$URL" --output "$OUTPUT_FORMAT" --output-path "./report.$OUTPUT_FORMAT"

echo "✅ Performance report saved as report.$OUTPUT_FORMAT"
