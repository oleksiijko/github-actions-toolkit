#!/bin/bash
set -e

REPO=$1
PR_NUMBER=$2
OPENAI_API_KEY=$3

echo "📦 Getting PR diff for $REPO #$PR_NUMBER..."

PR_DIFF=$(curl -s -H "Authorization: Bearer $GITHUB_TOKEN" \
  -H "Accept: application/vnd.github.v3.diff" \
  https://api.github.com/repos/$REPO/pulls/$PR_NUMBER)

echo "📤 Sending diff to GPT..."

RESPONSE=$(curl -s https://api.openai.com/v1/chat/completions \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer $OPENAI_API_KEY" \
  -d '{
    "model": "gpt-3.5-turbo",
    "messages": [
      {"role": "system", "content": "Summarize the following pull request diff in markdown format."},
      {"role": "user", "content": "'"$PR_DIFF"'"}
    ]
  }')

SUMMARY=$(echo "$RESPONSE" | jq -r '.choices[0].message.content')

echo "$SUMMARY" > summary.md
echo "✅ AI Summary written to summary.md"
