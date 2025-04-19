#!/bin/bash
set -e

URL=$1
OUTPUT_FORMAT=$2

if [ -z "$URL" ]; then
  echo "❌ Please provide a url"
  exit 1
fi

echo "🌐 Running Lighthouse on $URL (format: $OUTPUT_FORMAT)..."

lighthouse "$URL" \
  --output "$OUTPUT_FORMAT" \
  --output-path "./report.$OUTPUT_FORMAT" \
  --chrome-flags="--no-sandbox"

echo "✅ Performance report saved as report.$OUTPUT_FORMAT"
