# AI PR Summarizer 🤖

Summarizes actual Pull Request changes using OpenAI GPT and GitHub API.

## Requirements

- OpenAI API Key (via `openai_api_key` input or secret)
- GitHub Token (automatically available in GitHub Actions as `GITHUB_TOKEN`)
- `jq` installed in container

## Inputs

| Name | Description |
|------|-------------|
| repo | Full repository name (e.g. `user/repo`) |
| pr_number | Pull Request number |
| openai_api_key | Your OpenAI API key |

## Example usage

```yaml
- name: AI PR Summary
  uses: ./ai-pr-summarizer
  with:
    repo: my-org/my-repo
    pr_number: 42
    openai_api_key: ${{ secrets.OPENAI_API_KEY }}
```

> The action fetches a real PR diff and uses GPT to create a summary saved in `summary.md`
