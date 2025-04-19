# ChatOps PR Bot 💬

Listens to GitHub webhook comments on PRs and reacts to slash commands like `/run tests`.

## How it works

1. Set up a GitHub webhook with `issue_comment` events.
2. Pass the webhook payload JSON to this action.
3. The bot checks comment content and responds.

## Supported commands

- `/run tests` — triggers CI
- `/deploy staging` — deploy simulation

## Example usage

```yaml
- name: Handle ChatOps
  uses: ./chatops-pr-bot
  with:
    payload_path: ./payload.json
```

> This action expects a GitHub-style webhook payload stored in JSON format.
