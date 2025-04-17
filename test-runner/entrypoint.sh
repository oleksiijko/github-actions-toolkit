#!/bin/bash
set -e

FRAMEWORK=$1
CUSTOM_COMMAND=$2
DIRECTORIES=$3
PARALLEL=$4
CACHE=$5
PATTERN=$6

IFS=',' read -ra DIR_ARRAY <<< "$DIRECTORIES"

start_time=$(date +%s)
total_passed=0
total_failed=0

# Auto-detect parallel processes if set to "auto"
if [ "$PARALLEL" = "auto" ]; then
  PARALLEL=$(nproc)
fi

# Create cache directory
if [ "$CACHE" = "true" ]; then
  mkdir -p .test_cache
fi

for dir in "${DIR_ARRAY[@]}"; do
  echo "Running tests in directory: $dir"
  cd "$dir" || continue
  
  # Use custom command if provided
  if [ -n "$CUSTOM_COMMAND" ]; then
    eval "$CUSTOM_COMMAND"
    continue
  fi

  # Default commands by framework
  case $FRAMEWORK in
    jest)
      JEST_ARGS="--colors"
      [ -n "$PATTERN" ] && JEST_ARGS="$JEST_ARGS --testMatch '**/$PATTERN'"
      [ "$PARALLEL" != "1" ] && JEST_ARGS="$JEST_ARGS --maxWorkers=$PARALLEL"
      [ "$CACHE" = "true" ] && JEST_ARGS="$JEST_ARGS --cache"
      
      npx jest $JEST_ARGS
      ;;
    pytest)
      PYTEST_ARGS=""
      [ -n "$PATTERN" ] && PYTEST_ARGS="$PYTEST_ARGS -k $PATTERN"
      [ "$PARALLEL" != "1" ] && PYTEST_ARGS="$PYTEST_ARGS -n $PARALLEL"
      
      python3 -m pytest $PYTEST_ARGS
      ;;
    go)
      go_args="-v"
      [ "$PARALLEL" != "1" ] && go_args="$go_args -parallel $PARALLEL"
      [ -n "$PATTERN" ] && go_args="$go_args -run $PATTERN"
      
      go test $go_args ./...
      ;;
    *)
      echo "Framework not supported: $FRAMEWORK"
      exit 1
      ;;
  esac

  # Return to original directory
  cd - > /dev/null
done

end_time=$(date +%s)
time_taken=$((end_time - start_time))

# Set outputs
echo "passed=$total_passed" >> $GITHUB_OUTPUT
echo "failed=$total_failed" >> $GITHUB_OUTPUT
echo "time=$time_taken" >> $GITHUB_OUTPUT

if [ $total_failed -gt 0 ]; then
  echo "Tests completed with failures: $total_failed failed, $total_passed passed in ${time_taken}s"
  exit 1
else
  echo "All tests passed: $total_passed tests in ${time_taken}s"
fi