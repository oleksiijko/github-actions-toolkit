#!/bin/bash
set -e

MODULES=$1
CONFIG_DIR=$2
WORKFLOW_DIR=$3

IFS=',' read -ra MODULE_ARRAY <<< "$MODULES"

# Check if all modules should be included
if [[ "$MODULES" == "all" ]]; then
  MODULE_ARRAY=("code-formatter" "test-runner" "deploy-anywhere" "security-scanner" "pr-automator")
fi

echo "Setting up GitHub Actions Toolkit..."

# Setup configuration files
if [[ " ${MODULE_ARRAY[*]} " =~ " code-formatter " ]]; then
  echo "Setting up Code Formatter..."
  
  # Create configuration file
  cat > "$CONFIG_DIR/.formatrc" << EOF
# Code Formatter Configuration
# Customize formatting rules for different languages

# JavaScript/TypeScript
JS_SINGLE_QUOTE=true
JS_TRAILING_COMMA=all
JS_PRINT_WIDTH=100

# Python
PY_LINE_LENGTH=88
PY_USE_TABS=false

# Go
GO_SIMPLIFY=true

# Rust
RUST_EDITION=2021
EOF
  
  # Create workflow file
  cat > "$WORKFLOW_DIR/format.yml" << EOF
name: Format Code

on:
  push:
    branches: [ main, master ]
  pull_request:
    branches: [ main, master ]

jobs:
  format:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3
      
      - name: Format Code
        uses: ./.github/actions/code-formatter@main
        with:
          languages: js,ts,py,go,rust
          config_file: $CONFIG_DIR/.formatrc
          auto_fix: true
EOF

  # Create action directory
  mkdir -p ".github/actions/code-formatter"
  echo "Code Formatter setup complete."
fi

if [[ " ${MODULE_ARRAY[*]} " =~ " test-runner " ]]; then
  echo "Setting up Test Runner..."
  
  # Create workflow file
  cat > "$WORKFLOW_DIR/test.yml" << EOF
name: Run Tests

on:
  push:
    branches: [ main, master ]
  pull_request:
    branches: [ main, master ]

jobs:
  test:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3
      
      - name: Detect Language and Framework
        id: detect
        run: |
          if [ -f "package.json" ]; then
            echo "framework=jest" >> \$GITHUB_OUTPUT
          elif [ -f "requirements.txt" ]; then
            echo "framework=pytest" >> \$GITHUB_OUTPUT
          elif [ -f "go.mod" ]; then
            echo "framework=go" >> \$GITHUB_OUTPUT
          else
            echo "framework=unknown" >> \$GITHUB_OUTPUT
          fi
      
      - name: Run Tests
        if: steps.detect.outputs.framework != 'unknown'
        uses: ./.github/actions/test-runner@main
        with:
          framework: \${{ steps.detect.outputs.framework }}
          parallel: auto
          cache: true
EOF

  # Create action directory
  mkdir -p ".github/actions/test-runner"
  echo "Test Runner setup complete."
fi

if [[ " ${MODULE_ARRAY[*]} " =~ " deploy-anywhere " ]]; then
  echo "Setting up Deploy Anywhere..."
  
  # Create configuration file
  cat > "$CONFIG_DIR/.deployrc" << EOF
# Deploy Anywhere Configuration
# Uncomment and edit for your deployment needs

# AWS Configuration
#AWS_REGION=us-east-1
#S3_BUCKET=my-app-bucket
#CLOUDFRONT_ID=E12345ABCDEF

# Vercel Configuration
#VERCEL_PROJECT=my-vercel-project
#VERCEL_ORG=my-organization

# Netlify Configuration
#NETLIFY_SITE=my-netlify-site

# Environment-specific settings
# [development]
#BASE_URL=https://dev.example.com

# [staging]
#BASE_URL=https://staging.example.com

# [production]
#BASE_URL=https://example.com
EOF
  
  # Create workflow file
  cat > "$WORKFLOW_DIR/deploy.yml" << EOF
name: Deploy Application

on:
  push:
    branches: [ main, master ]
  workflow_dispatch:
    inputs:
      environment:
        description: 'Environment to deploy to'
        required: true
        default: 'dev'
        type: choice
        options:
          - dev
          - staging
          - prod

jobs:
  deploy:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3
      
      - name: Deploy to Environment
        uses: ./.github/actions/deploy-anywhere@main
        with:
          provider: \${{ secrets.DEPLOY_PROVIDER }}
          directory: ./dist
          environment: \${{ github.event.inputs.environment || 'dev' }}
          credentials: \${{ secrets.DEPLOY_CREDENTIALS }}
EOF

  # Create action directory
  mkdir -p ".github/actions/deploy-anywhere"
  echo "Deploy Anywhere setup complete."
fi

if [[ " ${MODULE_ARRAY[*]} " =~ " security-scanner " ]]; then
  echo "Setting up Security Scanner..."
  
  # Create workflow file
  cat > "$WORKFLOW_DIR/security.yml" << EOF
name: Security Scan

on:
  push:
    branches: [ main, master ]
  pull_request:
    branches: [ main, master ]
  schedule:
    - cron: '0 0 * * 1'  # Weekly on Mondays

jobs:
  security:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3
      
      - name: Scan for Vulnerabilities
        uses: ./.github/actions/security-scanner@main
        with:
          scan_type: all
          severity: medium
          fail_on: high
          pr_comment: true
EOF

  # Create action directory
  mkdir -p ".github/actions/security-scanner"
  echo "Security Scanner setup complete."
fi

if [[ " ${MODULE_ARRAY[*]} " =~ " pr-automator " ]]; then
  echo "Setting up PR Automator..."
  
  # Create PR guidelines file
  cat > "$CONFIG_DIR/pr_guidelines.md" << EOF
# Pull Request Guidelines

## Requirements

- All PRs must have a clear title and description
- Include tests for new features
- Ensure all tests pass
- Follow code style guidelines
- Keep changes focused and related
- Update documentation if necessary

## PR Size Guidelines

- Aim for PRs under 500 lines of code
- If larger, consider splitting into multiple PRs
- Avoid mixing features and bug fixes in one PR

## Commit Message Format

- Use present tense ("Add feature" not "Added feature")
- Use imperative mood ("Move cursor to..." not "Moves cursor to...")
- First line is a summary (max 50 chars)
- If needed, add detailed description after blank line
EOF
  
  # Create workflow file
  cat > "$WORKFLOW_DIR/pr-check.yml" << EOF
name: PR Validation

on:
  pull_request:
    types: [opened, synchronize, reopened, edited]

jobs:
  validate:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3
      
      - name: Validate Pull Request
        uses: ./.github/actions/pr-automator@main
        with:
          github_token: \${{ secrets.GITHUB_TOKEN }}
          generate_description: true
          validate_pr: true
          guideline_file: $CONFIG_DIR/pr_guidelines.md
EOF

  # Create action directory
  mkdir -p ".github/actions/pr-automator"
  echo "PR Automator setup complete."
fi

echo "GitHub Actions Toolkit setup completed successfully!"
echo "To complete the setup, copy the action implementations into the .github/actions/ directories."