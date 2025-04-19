#!/bin/bash
set -e

REPO=${INPUT_REPO}
PR_NUMBER=${INPUT_PR_NUMBER}
OPENAI_API_KEY=${INPUT_OPENAI_API_KEY}

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

echo "🧠 GPT Response:"
echo "$RESPONSE"

SUMMARY=$(echo "$RESPONSE" | jq -r '.choices[0].message.content')

if [ -z "$SUMMARY" ] || [ "$SUMMARY" == "null" ]; then
  echo "⚠️ GPT returned empty or invalid response. Writing fallback summary..."
  echo "⚠️ AI summary could not be generated. Please check inputs or API status." > summary.md
else
  echo "$SUMMARY" > summary.md
fi

echo "✅ AI Summary written to summary.md"
