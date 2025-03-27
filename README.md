# Clang Formatter GitHub Action

A GitHub Action to check or apply clang-format using your project's `.clang-format` file.

## Features

- Uses your project's existing `.clang-format` file
- Can be used as a standalone action or included in other workflows
- Supports both check-only mode and automatic formatting
- Configurable file patterns for inclusion/exclusion
- Auto-reformats code when PR comment contains "%reformat"

## Usage

### Basic Usage

```yaml
name: Format Check

on:
  push:
    branches: [ main ]
  pull_request:
    branches: [ main ]
  issue_comment:
    types: [ created ]

jobs:
  clang-format:
    runs-on: ubuntu-latest
    # Only run on PR comments
    if: ${{ github.event_name != 'issue_comment' || github.event.issue.pull_request }}
    steps:
      - uses: actions/checkout@v3
        with:
          # Ensure full git history for PR checks
          fetch-depth: 0
          # Required for pushing to PR branch
          ref: ${{ github.event.pull_request.head.ref }}
      - name: Run clang-format check
        uses: your-username/clang-formatter@main
        with:
          check-only: 'true'
          github-token: ${{ secrets.GITHUB_TOKEN }}
```

### Available Options

- `check-only`: Set to 'true' to only check formatting without modifying files (default: 'true')
- `include-pattern`: File pattern to include in formatting check (default: '*.cpp *.hpp *.c *.h')
- `exclude-pattern`: File pattern to exclude from formatting (default: 'build/ third_party/')
- `github-token`: GitHub token for commenting and pushing to PR branches (default: `github.token`)

### Using as a Reusable Workflow

You can also include this as a reusable workflow:

```yaml
name: CI

on:
  push:
    branches: [ main ]
  pull_request:
    branches: [ main ]
  issue_comment:
    types: [ created ]

jobs:
  format-check:
    uses: your-username/clang-formatter/.github/workflows/clang-format-check.yml@main
    with:
      include-pattern: '*.cpp *.hpp'
```

## Auto-Formatting with Comments

This action supports an interactive workflow where users can request automatic formatting:

1. When a PR check fails due to formatting issues, users can comment on the PR with "%reformat"
2. The action will then automatically:
   - Format all code files according to the project's .clang-format rules
   - Commit the changes
   - Push the changes to the PR branch

This is useful for quickly fixing formatting issues without requiring manual intervention.

## Requirements

- Your project must have a `.clang-format` file in the root directory
- For PR auto-formatting to work, the workflow must be triggered on `issue_comment` events
- The `github-token` must have permission to push to PR branches (the default token has this)

## License

MIT