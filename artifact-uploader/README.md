# Artifact Uploader

Uploads build artifacts to GitHub Artifacts or external storage (e.g. S3).

## Inputs

| Name | Description | Required | Default |
|------|-------------|----------|---------|
| example_input | Example description | false | `default_value` |

## Example usage

```yaml
- name: Artifact Uploader
  uses: ./github-actions-toolkit/artifact-uploader
  with:
    example_input: value
```
