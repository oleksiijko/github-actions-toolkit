# Secrets Scanner

Scans source for secrets (e.g. API keys) using gitleaks or truffleHog.

## Inputs

| Name | Description | Required | Default |
|------|-------------|----------|---------|
| example_input | Example description | false | `default_value` |

## Example usage

```yaml
- name: Secrets Scanner
  uses: ./github-actions-toolkit/secrets-scanner
  with:
    example_input: value
```
