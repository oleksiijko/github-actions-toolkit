# Auto Labeler

Automatically adds labels to PRs based on file paths or content.

## Inputs

| Name | Description | Required | Default |
|------|-------------|----------|---------|
| example_input | Example description | false | `default_value` |

## Example usage

```yaml
- name: Auto Labeler
  uses: ./github-actions-toolkit/auto-labeler
  with:
    example_input: value
```
