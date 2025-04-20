#!/bin/bash
set -e

GITHUB_TOKEN=$1
PR_NUMBER=$2
REPOSITORY=$3
GENERATE_DESCRIPTION=$4
VALIDATE_PR=$5
GUIDELINE_FILE=$6
AUTO_FIX_COMMITS=${7:-false}
CUSTOM_RULES_FILE=${8:-.pr_rules.json}

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
import json
import subprocess
from github import Github
import git
from mistletoe import Document

# Parse arguments
github_token = sys.argv[1]
pr_number = int(sys.argv[2])
repository = sys.argv[3]
generate_description = sys.argv[4].lower() == 'true'
validate_pr = sys.argv[5].lower() == 'true'
guideline_file = sys.argv[6]
auto_fix_commits = sys.argv[7].lower() == 'true'
custom_rules_file = sys.argv[8]

# Load custom rules
custom_rules = {
    "min_commit_message_length": 10,
    "require_tests": False
}
if os.path.exists(custom_rules_file):
    with open(custom_rules_file) as f:
        custom_rules.update(json.load(f))

min_msg_len = custom_rules["min_commit_message_length"]

# Connect to GitHub API
g = Github(github_token)
repo = g.get_repo(repository)
pr = repo.get_pull(pr_number)

print(f"Processing PR #{pr_number} in {repository}")

repo_dir = 'repo_clone'
if not os.path.exists(repo_dir):
    git_url = f"https://x-access-token:{github_token}@github.com/{repository}.git"
    git.Repo.clone_from(git_url, repo_dir)

repo_git = git.Repo(repo_dir)
repo_git.git.fetch('origin', f'pull/{pr_number}/head:pr-{pr_number}')
repo_git.git.checkout(f'pr-{pr_number}')

changed_files = list(pr.get_files())
file_types = {}
for file in changed_files:
    ext = os.path.splitext(file.filename)[1]
    file_types[ext] = file_types.get(ext, 0) + 1

additions = sum(file.additions for file in changed_files)
deletions = sum(file.deletions for file in changed_files)
total_changes = additions + deletions

if generate_description and (pr.body is None or pr.body.strip() == ''):
    commits = list(pr.get_commits())
    commit_messages = [c.commit.message for c in commits]
    description = f"""# PR: {pr.title}

## Changes Overview

- Total files changed: {len(changed_files)}
- Lines added: {additions}
- Lines removed: {deletions}
- File types affected: {', '.join(f'{k} ({v})' for k, v in file_types.items())}

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
    pr.edit(body=description)
    print("PR description updated.")

issues = []
if validate_pr:
    print("Validating PR against guidelines...")
    guideline_content = None
    try:
        content_file = repo.get_contents(guideline_file)
        guideline_content = content_file.decoded_content.decode('utf-8')
    except:
        print(f"No guideline file found at {guideline_file}")

    if pr.title.lower().startswith('wip:'):
        issues.append("PR is marked as Work in Progress")

    if pr.body is None or len(pr.body.strip()) < 50:
        issues.append("PR description is too short or missing")

    for commit in pr.get_commits():
        msg = commit.commit.message.split('\n')[0]
        if len(msg) < min_msg_len:
            issues.append(f"Commit message too short: '{msg}'")
            if auto_fix_commits:
                new_msg = f"fix: {msg}"
                subprocess.run(['git', 'commit', '--amend', '-m', new_msg], cwd=repo_dir)

    for file in changed_files:
        if file.changes > 500:
            issues.append(f"File {file.filename} has too many changes ({file.changes} lines)")

    if guideline_content and 'test' in guideline_content.lower():
        if not any('test' in file.filename for file in changed_files):
            issues.append("No test files included in the changes")

status = "passed" if len(issues) == 0 else "failed"
print(f"PR validation status: {status}")
if issues:
    for issue in issues:
        print(f"- {issue}")

# Markdown summary
with open(os.environ.get('GITHUB_STEP_SUMMARY', '/dev/null'), 'a') as f:
    if status == "passed":
        f.write("## ✅ PR Validation Passed\n")
    else:
        f.write("## ❌ PR Validation Failed\n")
        for issue in issues:
            f.write(f"- {issue}\n")

with open(os.environ.get('GITHUB_OUTPUT', '/dev/null'), 'a') as f:
    f.write(f"status={status}\n")
    f.write(f"issues={json.dumps(issues)}\n")

if issues and validate_pr:
    comment = f"""## PR Validation Results

This automated check found some issues with your PR:

{chr(10).join(f'- {issue}' for issue in issues)}

Please address these issues and update your PR. Thank you!
"""
    pr.create_issue_comment(comment)

print("PR processing completed.")
EOF

python3 process_pr.py "$GITHUB_TOKEN" "$PR_NUMBER" "$REPOSITORY" "$GENERATE_DESCRIPTION" "$VALIDATE_PR" "$GUIDELINE_FILE" "$AUTO_FIX_COMMITS" "$CUSTOM_RULES_FILE"
