#!/bin/bash
set -e

PAYLOAD_FILE=${INPUT_PAYLOAD_PATH}
COMMENT=$(jq -r '.comment.body' "$PAYLOAD_FILE")
PR_NUMBER=$(jq -r '.issue.number' "$PAYLOAD_FILE")

echo "🔔 Received comment: $COMMENT on PR #$PR_NUMBER"

if [[ "$COMMENT" == *"/run tests"* ]]; then
  echo "✅ CI triggered for PR #$PR_NUMBER"
elif [[ "$COMMENT" == *"/deploy staging"* ]]; then
  echo "🚀 Deploy to staging for PR #$PR_NUMBER"
else
  echo "❓ Unknown command"
fi
