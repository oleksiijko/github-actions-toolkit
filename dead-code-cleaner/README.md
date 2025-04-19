# Dead Code Cleaner

Detects and flags unused code (e.g. via vulture or ts-prune).

## Inputs

| Name | Description | Required | Default |
|------|-------------|----------|---------|
| example_input | Example description | false | `default_value` |

## Example usage

```yaml
- name: Dead Code Cleaner
  uses: ./github-actions-toolkit/dead-code-cleaner
  with:
    example_input: value
```
