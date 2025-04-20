#!/bin/bash
set -e

FRAMEWORK=$1
CUSTOM_COMMAND=$2
DIRECTORIES=$3
PARALLEL=$4
CACHE=$5
PATTERN=$6
RETRY=${7:-1}
OPENAI_KEY=$8

IFS=',' read -ra DIR_ARRAY <<< "$DIRECTORIES"
mkdir -p artifacts reports logs

start_time=$(date +%s)

if [ "$PARALLEL" = "auto" ]; then
  PARALLEL=$(nproc)
fi

for dir in "${DIR_ARRAY[@]}"; do
  echo "🧪 Running tests in: $dir"
  cd "$dir" || continue

  mkdir -p ../artifacts

  for attempt in $(seq 1 "$RETRY"); do
    echo "🔁 Attempt $attempt"
    STATUS=0

    if [ -n "$CUSTOM_COMMAND" ]; then
      bash -c "$CUSTOM_COMMAND" > ../artifacts/test.log 2>&1 || STATUS=$?
    else
      case "$FRAMEWORK" in
        jest)
          npx jest --ci \
            ${PATTERN:+--testMatch "**/$PATTERN"} \
            --maxWorkers="$PARALLEL" \
            --coverage --coverageReporters=text --coverageReporters=lcov \
            --outputFile="../artifacts/junit.xml" \
            --reporters=default \
            --reporters=jest-junit > ../artifacts/test.log 2>&1 || STATUS=$?
          [ -f coverage/lcov-report/index.html ] && cp coverage/lcov-report/index.html ../artifacts/coverage.html || echo "ℹ️ No coverage HTML found"
          ;;
        vitest)
          npx vitest run --coverage.enabled=true > ../artifacts/test.log 2>&1 || STATUS=$?
          ;;
        ava)
          npx ava ${PATTERN:+$PATTERN} > ../artifacts/test.log 2>&1 || STATUS=$?
          ;;
        pytest)
          pytest ${PATTERN:+-k "$PATTERN"} -n "$PARALLEL" \
            --cov=. --cov-report=term --cov-report=html \
            --junitxml="../artifacts/junit.xml" > ../artifacts/test.log 2>&1 || STATUS=$?
          [ -d htmlcov ] && cp -r htmlcov ../artifacts/htmlcov || echo "ℹ️ No htmlcov folder found"
          ;;
        nose)
          nosetests --with-xunit --xunit-file=../artifacts/junit.xml > ../artifacts/test.log 2>&1 || STATUS=$?
          ;;
        go)
          go test -v -coverprofile=coverage.out ./... > ../artifacts/test.log 2>&1 || STATUS=$?
          [ -f coverage.out ] && go tool cover -html=coverage.out -o ../artifacts/coverage.html || echo "ℹ️ No Go coverage file found"
          ;;
        *)
          echo "❌ Unsupported framework: $FRAMEWORK"
          exit 1
          ;;
      esac
    fi

    if [ "$STATUS" = "0" ]; then
      echo "✅ Tests passed"
      break
    elif [ "$attempt" -eq "$RETRY" ]; then
      echo "❌ Tests failed after $RETRY attempts"
      break
    fi
  done

  cd - > /dev/null
done

end_time=$(date +%s)
time_taken=$((end_time - start_time))

echo "time=$time_taken" >> "$GITHUB_OUTPUT"

# Extract coverage
coverage=0
if grep -qi "Coverage" artifacts/test.log; then
  coverage=$(grep -i 'Coverage' artifacts/test.log | grep -oE '[0-9]+(\.[0-9]+)?' | head -n1)
  echo "coverage=$coverage" >> "$GITHUB_OUTPUT"
fi

# Markdown summary
{
  echo "## ✅ Test Summary"
  echo ""
  echo "- Framework: $FRAMEWORK"
  echo "- Time: ${time_taken}s"
  echo "- Coverage: ${coverage:-unknown}%"
  echo "- Retries: $RETRY"
} >> "${GITHUB_STEP_SUMMARY:-/dev/null}"

# Badge generation
if [ -n "$coverage" ]; then
  COLOR="red"
  if (( $(echo "$coverage >= 80" | bc -l) )); then COLOR="green"
  elif (( $(echo "$coverage >= 50" | bc -l) )); then COLOR="yellow"; fi

  echo "<svg xmlns='http://www.w3.org/2000/svg' width='120' height='20'>
  <rect width='120' height='20' fill='#555'/>
  <rect x='60' width='60' height='20' fill='$COLOR'/>
  <text x='30' y='14' fill='#fff' font-family='Verdana' font-size='11'>coverage</text>
  <text x='90' y='14' fill='#000' font-family='Verdana' font-size='11'>${coverage}%</text>
</svg>" > artifacts/coverage-badge.svg
fi

# AI analysis
if [[ "$STATUS" != "0" && -n "$OPENAI_KEY" ]]; then
  echo "🤖 Analyzing failures with OpenAI..."
  MSG=$(tail -n 50 artifacts/test.log | jq -Rs .)
  curl https://api.openai.com/v1/chat/completions \
    -H "Authorization: Bearer $OPENAI_KEY" \
    -H "Content-Type: application/json" \
    -d '{
      "model": "gpt-4",
      "messages": [
        {"role": "system", "content": "You are a test failure analyzer."},
        {"role": "user", "content": "Analyze this test output and suggest a fix: '"$MSG"'"}
      ]
    }' > artifacts/ai-analysis.json || echo "⚠️ AI analysis failed"
fi

echo "✅ Test Runner completed in ${time_taken}s"
