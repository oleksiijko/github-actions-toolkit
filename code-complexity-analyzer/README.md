# Code Complexity Analyzer

Analyzes code complexity and outputs a report (e.g. via radon, eslint).

## Inputs

| Name | Description | Required | Default |
|------|-------------|----------|---------|
| example_input | Example description | false | `default_value` |

## Example usage

```yaml
- name: Code Complexity Analyzer
  uses: ./github-actions-toolkit/code-complexity-analyzer
  with:
    example_input: value
```
