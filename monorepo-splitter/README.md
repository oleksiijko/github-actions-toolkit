# Monorepo Splitter

Helps split monorepo packages into independent branches or mirrors.

## Inputs

| Name | Description | Required | Default |
|------|-------------|----------|---------|
| example_input | Example description | false | `default_value` |

## Example usage

```yaml
- name: Monorepo Splitter
  uses: ./github-actions-toolkit/monorepo-splitter
  with:
    example_input: value
```
