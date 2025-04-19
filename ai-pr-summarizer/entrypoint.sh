#!/bin/bash
set -e

REPO=${INPUT_REPO}
PR_NUMBER=${INPUT_PR_NUMBER}
OPENAI_API_KEY=${INPUT_OPENAI_API_KEY}

echo "📦 Getting PR diff for $REPO #$PR_NUMBER..."

PR_DIFF=$(curl -s -L \
  "https://patch-diff.githubusercontent.com/raw/$REPO/pull/$PR_NUMBER.diff")

if [ -z "$PR_DIFF" ]; then
  echo "❌ Failed to fetch PR diff."
  echo "No diff available." > summary.md
  exit 0
fi

echo "📤 Sending diff to GPT..."

# Write diff to file for proper escaping
echo "$PR_DIFF" > pr.diff

# Build proper JSON payload using jq
jq -n --arg diff "$(cat pr.diff)" '{
  model: "gpt-3.5-turbo",
  messages: [
    { role: "system", content: "Summarize the following pull request diff in markdown format." },
    { role: "user", content: $diff }
  ]
}' > payload.json

# Make GPT request
RESPONSE=$(curl -s https://api.openai.com/v1/chat/completions \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer $OPENAI_API_KEY" \
  -d @payload.json)

echo "🧠 GPT Raw Response:"
echo "$RESPONSE"

# Extract summary safely
SUMMARY=$(echo "$RESPONSE" | jq -r '.choices[0].message.content // empty')

if [ -z "$SUMMARY" ]; then
  echo "⚠️ GPT returned no summary. Writing fallback."
  echo "⚠️ AI summary could not be generated. Please check inputs or OpenAI response." > summary.md
else
  echo "$SUMMARY" > summary.md
fi

echo "✅ AI Summary written to summary.md"
cat summary.md
