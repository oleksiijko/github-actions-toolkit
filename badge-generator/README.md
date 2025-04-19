# Badge Generator

Generates SVG badges based on test results or metrics.

## Inputs

| Name | Description | Required | Default |
|------|-------------|----------|---------|
| example_input | Example description | false | `default_value` |

## Example usage

```yaml
- name: Badge Generator
  uses: ./github-actions-toolkit/badge-generator
  with:
    example_input: value
```
