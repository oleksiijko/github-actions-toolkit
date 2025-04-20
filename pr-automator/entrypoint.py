import os
import sys
import json
import subprocess
import git
from github import Github
from mistletoe import Document

def main():
    github_token = sys.argv[1]
    pr_number = int(sys.argv[2])
    repository = sys.argv[3]
    generate_description = sys.argv[4].lower() == 'true'
    validate_pr = sys.argv[5].lower() == 'true'
    guideline_file = sys.argv[6]
    auto_fix_commits = sys.argv[7].lower() == 'true' if len(sys.argv) > 7 else False
    custom_rules_file = sys.argv[8] if len(sys.argv) > 8 else ".pr_rules.json"

    rules = {
        "min_commit_message_length": 10,
        "require_tests": False
    }
    if os.path.exists(custom_rules_file):
        with open(custom_rules_file) as f:
            rules.update(json.load(f))

    min_msg_len = rules["min_commit_message_length"]

    g = Github(github_token)
    repo = g.get_repo(repository)
    pr = repo.get_pull(pr_number)

    print(f"📌 Processing PR #{pr_number} in {repository}")

    repo_dir = "repo_clone"
    if not os.path.exists(repo_dir):
        git_url = f"https://x-access-token:{github_token}@github.com/{repository}.git"
        git.Repo.clone_from(git_url, repo_dir)

    repo_git = git.Repo(repo_dir)
    repo_git.git.fetch("origin", f"pull/{pr_number}/head:pr-{pr_number}")
    repo_git.git.checkout(f"pr-{pr_number}")

    changed_files = list(pr.get_files())
    additions = sum(f.additions for f in changed_files)
    deletions = sum(f.deletions for f in changed_files)
    file_types = {}
    for f in changed_files:
        ext = os.path.splitext(f.filename)[1]
        file_types[ext] = file_types.get(ext, 0) + 1

    if generate_description and (not pr.body or pr.body.strip() == ""):
        commits = pr.get_commits()
        commit_msgs = [c.commit.message for c in commits]

        description = f"""# PR: {pr.title}

## Changes Overview
- Files changed: {len(changed_files)}
- Additions: {additions}
- Deletions: {deletions}
- File types: {', '.join(f"{k} ({v})" for k, v in file_types.items())}

## Commits
{chr(10).join(f"- {msg.splitlines()[0]}" for msg in commit_msgs)}

## Files
{chr(10).join(f"- {f.filename}" for f in changed_files[:10])}
{'...(and more)' if len(changed_files) > 10 else ''}

## Purpose

<!-- Describe what this PR does -->

## Testing

<!-- Describe what has been tested -->
"""
        pr.edit(body=description)
        print("✍️ PR description added.")

    issues = []
    if validate_pr:
        try:
            guideline_content = repo.get_contents(guideline_file).decoded_content.decode("utf-8")
        except:
            print(f"⚠️ No guideline file found at {guideline_file}")
            guideline_content = None

        if pr.title.lower().startswith("wip:"):
            issues.append("PR marked as WIP")

        if not pr.body or len(pr.body.strip()) < 50:
            issues.append("PR description is too short")

        for commit in pr.get_commits():
            msg = commit.commit.message.splitlines()[0]
            if len(msg) < min_msg_len:
                issues.append(f"Commit message too short: '{msg}'")
                if auto_fix_commits:
                    subprocess.run(["git", "commit", "--amend", "-m", f"fix: {msg}"], cwd=repo_dir)

        for file in changed_files:
            if file.changes > 500:
                issues.append(f"Too many changes in {file.filename} ({file.changes} lines)")

        if rules["require_tests"] and not any("test" in f.filename.lower() for f in changed_files):
            issues.append("No test files found")

    # Summary
    status = "passed" if not issues else "failed"
    print(f"✅ PR validation status: {status}")
    for issue in issues:
        print(f"- {issue}")

    if "GITHUB_OUTPUT" in os.environ:
        with open(os.environ["GITHUB_OUTPUT"], "a") as f:
            f.write(f"status={status}\n")
            f.write(f"issues={json.dumps(issues)}\n")

    if "GITHUB_STEP_SUMMARY" in os.environ:
        with open(os.environ["GITHUB_STEP_SUMMARY"], "a") as f:
            f.write(f"## {'✅ Passed' if not issues else '❌ Failed'} PR Validation\n")
            for issue in issues:
                f.write(f"- {issue}\n")

    if issues and validate_pr:
        pr.create_issue_comment(f"## PR Validation Issues\n\n" + "\n".join(f"- {i}" for i in issues))

    print("✅ PR processing completed.")

if __name__ == "__main__":
    main()
