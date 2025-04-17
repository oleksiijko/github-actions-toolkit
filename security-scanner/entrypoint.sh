#!/bin/bash
set -e

SCAN_TYPE=$1
DIRECTORY=$2
MIN_SEVERITY=$3
FAIL_SEVERITY=$4
PR_COMMENT=$5

# Create report directory
mkdir -p security_reports

# Map severity levels to numerical values for comparison
function severity_value {
  case $1 in
    info) echo 1 ;;
    low) echo 2 ;;
    medium) echo 3 ;;
    high) echo 4 ;;
    critical) echo 5 ;;
    *) echo 0 ;;
  esac
}

MIN_SEVERITY_VALUE=$(severity_value "$MIN_SEVERITY")
FAIL_SEVERITY_VALUE=$(severity_value "$FAIL_SEVERITY")
HIGHEST_SEVERITY_VALUE=0
TOTAL_VULNERABILITIES=0

# Function to check if a severity should be reported
function should_report {
  local severity_val=$(severity_value "$1")
  if [ "$severity_val" -ge "$MIN_SEVERITY_VALUE" ]; then
    return 0
  else
    return 1
  fi
}

# Function to update highest severity found
function update_highest_severity {
  local severity_val=$(severity_value "$1")
  if [ "$severity_val" -gt "$HIGHEST_SEVERITY_VALUE" ]; then
    HIGHEST_SEVERITY_VALUE=$severity_val
    case $severity_val in
      1) HIGHEST_SEVERITY="info" ;;
      2) HIGHEST_SEVERITY="low" ;;
      3) HIGHEST_SEVERITY="medium" ;;
      4) HIGHEST_SEVERITY="high" ;;
      5) HIGHEST_SEVERITY="critical" ;;
    esac
  fi
}

echo "Starting security scan of $DIRECTORY"

# Scan dependencies if requested
if [ "$SCAN_TYPE" = "dependencies" ] || [ "$SCAN_TYPE" = "all" ]; then
  echo "Scanning dependencies..."
  
  # Check for package.json (Node.js)
  if [ -f "$DIRECTORY/package.json" ]; then
    echo "Detected Node.js project, scanning npm dependencies"
    cd "$DIRECTORY"
    npm audit --json > ../security_reports/npm_audit.json || true
    cd - > /dev/null
    
    # Count vulnerabilities
    NPM_VULNS=$(cat security_reports/npm_audit.json | jq -r '.vulnerabilities | length')
    TOTAL_VULNERABILITIES=$((TOTAL_VULNERABILITIES + NPM_VULNS))
    
    # Update highest severity
    SEVERITIES=$(cat security_reports/npm_audit.json | jq -r '.metadata.vulnerabilities | to_entries[] | select(.value > 0) | .key')
    for sev in $SEVERITIES; do
      update_highest_severity "$sev"
    done
  fi
  
  # Check for requirements.txt (Python)
  if [ -f "$DIRECTORY/requirements.txt" ]; then
    echo "Detected Python project, scanning pip dependencies"
    cd "$DIRECTORY"
    safety check -r requirements.txt --json > ../security_reports/pip_safety.json || true
    cd - > /dev/null
    
    # Count vulnerabilities
    PIP_VULNS=$(cat security_reports/pip_safety.json | jq length)
    TOTAL_VULNERABILITIES=$((TOTAL_VULNERABILITIES + PIP_VULNS))
    
    # Update highest severity
    SEVERITIES=$(cat security_reports/pip_safety.json | jq -r '.[].severity')
    for sev in $SEVERITIES; do
      update_highest_severity "$sev"
    done
  fi
fi

# Scan for secrets if requested
if [ "$SCAN_TYPE" = "secrets" ] || [ "$SCAN_TYPE" = "all" ]; then
  echo "Scanning for secrets..."
  detect-secrets scan "$DIRECTORY" > security_reports/secrets_scan.json
  
  # Count secrets found
  SECRETS_COUNT=$(cat security_reports/secrets_scan.json | jq '.results | length')
  TOTAL_VULNERABILITIES=$((TOTAL_VULNERABILITIES + SECRETS_COUNT))
  
  # Secrets are considered high severity
  if [ "$SECRETS_COUNT" -gt 0 ]; then
    update_highest_severity "high"
  fi
fi

# Scan code for vulnerabilities if requested
if [ "$SCAN_TYPE" = "code" ] || [ "$SCAN_TYPE" = "all" ]; then
  echo "Scanning code for vulnerabilities..."
  
  # Check for Python code
  if find "$DIRECTORY" -name "*.py" -type f -print -quit | grep -q .; then
    echo "Found Python files, running Bandit"
    bandit -r "$DIRECTORY" -f json > security_reports/python_bandit.json || true
    
    # Count vulnerabilities
    BANDIT_VULNS=$(cat security_reports/python_bandit.json | jq '.results | length')
    TOTAL_VULNERABILITIES=$((TOTAL_VULNERABILITIES + BANDIT_VULNS))
    
    # Update highest severity
    SEVERITIES=$(cat security_reports/python_bandit.json | jq -r '.results[].issue_severity')
    for sev in $SEVERITIES; do
      update_highest_severity "$sev"
    done
  fi
  
  # Additional language scanners can be added here
fi

# Generate summary report
echo "Generating summary report..."
cat > security_reports/summary.md << EOF
# Security Scan Summary

- **Total vulnerabilities found:** $TOTAL_VULNERABILITIES
- **Highest severity:** $HIGHEST_SEVERITY
- **Scan types performed:** $SCAN_TYPE
- **Directory scanned:** $DIRECTORY

## Detailed Reports

The following detailed reports are available:
EOF

find security_reports -name "*.json" | while read report; do
  echo "- [$(basename $report)](./$(basename $report))" >> security_reports/summary.md
done

# Set GitHub Action outputs
echo "vulnerabilities=$TOTAL_VULNERABILITIES" >> $GITHUB_OUTPUT
echo "highest_severity=$HIGHEST_SEVERITY" >> $GITHUB_OUTPUT
echo "report_path=security_reports/summary.md" >> $GITHUB_OUTPUT

# Check if we should fail the workflow
if [ "$HIGHEST_SEVERITY_VALUE" -ge "$FAIL_SEVERITY_VALUE" ]; then
  echo "Found vulnerabilities with severity $HIGHEST_SEVERITY (threshold: $FAIL_SEVERITY)"
  echo "Failing workflow as configured."
  exit 1
fi

echo "Security scan completed successfully."