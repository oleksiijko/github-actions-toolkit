# GitHub Actions Toolkit 🚀

A collection of reusable, Docker-based GitHub Actions to supercharge your CI/CD workflows.

## 📦 Available Actions

| Action | Description |
|--------|-------------|
| `auto-update-dependencies` | Automatically updates dependencies and pushes changes |
| `code-formatter` | Formats code using Prettier or Black |
| `deploy-anywhere` | Simulates deployment to any environment |
| `performance-report-generator` | [Coming soon] Generate performance reports |
| `pr-automator` | [Coming soon] Automate PR labels and reviews |
| `security-scanner` | [Coming soon] Run security scans |
| `setup-toolkit` | [Coming soon] Prepare environment for other actions |
| `test-runner` | [Coming soon] Run tests across stacks |

## 🚀 Example Usage

```yaml
- name: Auto Update Dependencies
  uses: ./auto-update-dependencies
  with:
    package_manager: npm
    commit_message: "chore: update deps"
    branch: main
```

## 🛠 Setup

1. Clone this repo into `.github/actions/toolkit`
2. Reference any action in your workflow using relative path
3. Customize inputs as needed

---

> ⭐ Star this repo if you find it helpful! PRs are welcome.

