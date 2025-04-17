#!/bin/bash
set -e

LANGUAGES=$1
CONFIG_FILE=$2
DIRECTORIES=$3
FAIL_ON_ERROR=$4
AUTO_FIX=$5

IFS=',' read -ra LANG_ARRAY <<< "$LANGUAGES"
IFS=',' read -ra DIR_ARRAY <<< "$DIRECTORIES"

ERRORS=0

# Load config file if exists
if [ -f "$CONFIG_FILE" ]; then
  echo "Loading configuration from $CONFIG_FILE"
  source "$CONFIG_FILE"
fi

for dir in "${DIR_ARRAY[@]}"; do
  echo "Scanning directory: $dir"
  
  for lang in "${LANG_ARRAY[@]}"; do
    case $lang in
      js|jsx|ts|tsx|node|typescript)
        echo "Formatting JavaScript/TypeScript files..."
        if [ "$AUTO_FIX" = "true" ]; then
          npx prettier --write "$dir/**/*.{js,jsx,ts,tsx}"
        else
          if ! npx prettier --check "$dir/**/*.{js,jsx,ts,tsx}"; then
            ERRORS=$((ERRORS+1))
          fi
        fi
        ;;
      py)
        echo "Formatting Python files..."
        if [ "$AUTO_FIX" = "true" ]; then
          python3 -m black "$dir"
          python3 -m isort "$dir"
        else
          if ! python3 -m black --check "$dir" || ! python3 -m isort --check "$dir"; then
            ERRORS=$((ERRORS+1))
          fi
        fi
        ;;
      go)
        echo "Formatting Go files..."
        if [ "$AUTO_FIX" = "true" ]; then
          goimports -w "$dir"
        else
          if ! goimports -l "$dir" | grep -q .; then
            ERRORS=$((ERRORS+1))
          fi
        fi
        ;;
      rust)
        echo "Formatting Rust files..."
        if [ "$AUTO_FIX" = "true" ]; then
          ~/.cargo/bin/rustfmt "$dir/**/*.rs"
        else
          if ! ~/.cargo/bin/rustfmt --check "$dir/**/*.rs"; then
            ERRORS=$((ERRORS+1))
          fi
        fi
        ;;
      java)
        echo "Formatting Java files..."
        if [ "$AUTO_FIX" = "true" ]; then
          java -jar google-java-format.jar --replace "$dir/**/*.java"
        else
          if ! java -jar google-java-format.jar --dry-run "$dir/**/*.java"; then
            ERRORS=$((ERRORS+1))
          fi
        fi
        ;;
      csharp)
        echo "Formatting C# files..."
        if [ "$AUTO_FIX" = "true" ]; then
          dotnet-format "$dir" --fix
        else
          if ! dotnet-format "$dir" --check; then
            ERRORS=$((ERRORS+1))
          fi
        fi
        ;;
      *)
        echo "Unsupported language: $lang"
        ;;
    esac
  done
done

if [ $ERRORS -gt 0 ] && [ "$FAIL_ON_ERROR" = "true" ]; then
  echo "Found $ERRORS formatting issues. Failing job."
  exit 1
else
  echo "Code formatting completed successfully."
fi
