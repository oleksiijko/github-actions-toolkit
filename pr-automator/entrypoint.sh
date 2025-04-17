#!/bin/bash
set -e

GITHUB_TOKEN=$1
PR_NUMBER=$2
REPOSITORY=$3
GENERATE_DESCRIPTION=$4
VALIDATE_PR=$5
GUIDELINE_FILE=$6

# If PR_NUMBER is not provided, try to get it from GITHUB_EVENT_PATH
if [ -z "$PR_NUMBER" ] && [ ! -z "$GITHUB_EVENT_PATH" ]; then
  PR_NUMBER=$(jq -r ".pull_request.number" "$GITHUB_EVENT_PATH")
fi

# If REPOSITORY is not provided, try to get it from GITHUB_REPOSITORY
if [ -z "$REPOSITORY" ] && [ ! -z "$GITHUB_REPOSITORY" ]; then
  REPOSITORY="$GITHUB_REPOSITORY"
fi

# Validate required inputs
if [ -z "$GITHUB_TOKEN" ] || [ -z "$PR_NUMBER" ] || [ -z "$REPOSITORY" ]; then
  echo "Error: Missing required inputs (github_token, pr_number, repository)"
  exit 1
fi

# Create Python script to process PR
cat > process_pr.py << 'EOF'
import os
import re
import sys
from github import Github
import git
import mistletoe
from mistletoe
import subprocess
import json
from mistletoe.markdown_renderer import MarkdownRenderer

# Parse arguments
github_token = sys.argv[1]
pr_number = int(sys.argv[2])
repository = sys.argv[3]
generate_description = sys.argv[4].lower() == 'true'
validate_pr = sys.argv[5].lower() == 'true'
guideline_file = sys.argv[6]

# Connect to GitHub API
g = Github(github_token)
repo = g.get_repo(repository)
pr = repo.get_pull(pr_number)

print(f"Processing PR #{pr_number} in {repository}")

# Clone repository to analyze changes
repo_dir = 'repo_clone'
if not os.path.exists(repo_dir):
    print(f"Cloning repository {repository}...")
    git_url = f"https://x-access-token:{github_token}@github.com/{repository}.git"
    git.Repo.clone_from(git_url, repo_dir)

# Get PR changes
repo_git = git.Repo(repo_dir)
repo_git.git.fetch('origin', f'pull/{pr_number}/head:pr-{pr_number}')
repo_git.git.checkout(f'pr-{pr_number}')

# Get changed files
changed_files = list(pr.get_files())
file_types = {}
for file in changed_files:
    ext = os.path.splitext(file.filename)[1]
    if ext in file_types:
        file_types[ext] += 1
    else:
        file_types[ext] = 1

# Count lines changed
additions = sum(file.additions for file in changed_files)
deletions = sum(file.deletions for file in changed_files)
total_changes = additions + deletions

# Generate PR description if enabled and current description is empty
if generate_description and (pr.body is None or pr.body.strip() == ''):
    print("Generating PR description...")
    
    # Get commit messages
    commits = list(pr.get_commits())
    commit_messages = [commit.commit.message for commit in commits]
    
    # Generate description
    description = f"""# PR: {pr.title}

## Changes Overview

This PR makes the following changes:

- Total files changed: {len(changed_files)}
- Lines added: {additions}
- Lines removed: {deletions}
- File types affected: {', '.join(f'{ext} ({count})' for ext, count in file_types.items())}

## Commits

{chr(10).join(f'- {msg.split(chr(10))[0]}' for msg in commit_messages)}

## Changed Files

{chr(10).join(f'- {file.filename}' for file in changed_files[:10])}
{'...(and more)' if len(changed_files) > 10 else ''}

## Purpose

<!-- Please describe the purpose of these changes -->

## Testing Done

<!-- Please describe the testing that has been done -->
"""
    
    # Update PR description
    pr.edit(body=description)
    print("PR description updated.")

# Validate PR against guidelines if enabled
issues = []
if validate_pr:
    print("Validating PR against guidelines...")
    
    # Check if guideline file exists
    guideline_content = None
    try:
        content_file = repo.get_contents(guideline_file)
        guideline_content = content_file.decoded_content.decode('utf-8')
    except:
        print(f"No guideline file found at {guideline_file}")
    
    # Basic validations
    if pr.title.lower().startswith('wip:'):
        issues.append("PR is marked as Work in Progress")
    
    if pr.body is None or len(pr.body.strip()) < 50:
        issues.append("PR description is too short or missing")
    
    # Check commit messages
    for commit in pr.get_commits():
        msg = commit.commit.message.split('\n')[0]
        if len(msg) < 10:
            issues.append(f"Commit message too short: '{msg}'")
    
    # Check file size
    for file in changed_files:
        if file.changes > 500:
            issues.append(f"File {file.filename} has too many changes ({file.changes} lines)")
    
    # Apply custom guidelines if available
    if guideline_content:
        # Parse guidelines and apply custom checks
        # (simplified implementation)
        if 'test' in guideline_content.lower() and not any('test' in file.filename for file in changed_files):
            issues.append("No test files included in the changes")

# Output results
status = "passed" if len(issues) == 0 else "failed"
print(f"PR validation status: {status}")
if issues:
    print("Issues found:")
    for issue in issues:
        print(f"- {issue}")

# Write outputs to GitHub Actions
with open(os.environ.get('GITHUB_OUTPUT', '/dev/null'), 'a') as f:
    f.write(f"status={status}\n")
    f.write(f"issues={json.dumps(issues)}\n")

# Comment on PR if issues were found
if issues and validate_pr:
    issue_list = "\n".join(f"- {issue}" for issue in issues)
    comment = f"""## PR Validation Results

This automated check found some issues with your PR:

{issue_list}

Please address these issues and update your PR. Thank you!
"""
    pr.create_issue_comment(comment)
    
print("PR processing completed.")