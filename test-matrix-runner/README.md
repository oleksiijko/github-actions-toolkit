# Test Matrix Runner

Runs tests using matrix strategy (e.g. different versions/platforms).

## Inputs

| Name | Description | Required | Default |
|------|-------------|----------|---------|
| example_input | Example description | false | `default_value` |

## Example usage

```yaml
- name: Test Matrix Runner
  uses: ./github-actions-toolkit/test-matrix-runner
  with:
    example_input: value
```
