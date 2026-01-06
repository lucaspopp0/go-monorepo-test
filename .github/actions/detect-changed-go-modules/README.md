# Detect Changed Go Modules

A GitHub Action that automatically detects which Go modules in a monorepo have changed, with proper handling of nested modules.

## Description

This action scans your repository for `go.mod` files, generates path filters with proper exclusion patterns for nested modules, and uses `dorny/paths-filter@v3` to detect which modules have actually changed in a pull request or push.

For example, given modules:
- `a/go.mod`
- `a/v2/go.mod`
- `b/go.mod`

The action automatically creates filters:
```yaml
a:
  - 'a/**'
  - '!a/v2/**'
a/v2:
  - 'a/v2/**'
b:
  - 'b/**'
```

And returns which modules changed, e.g., `["a", "b"]`.

## Features

- ✅ Automatically detects all Go modules in the repository
- ✅ Handles arbitrary nesting depth (e.g., `a`, `a/v2`, `a/v2/v3`)
- ✅ Excludes direct child modules from parent filters
- ✅ Returns a JSON array of changed module paths
- ✅ No dependencies to install (uses built-in `@actions/glob`)
- ✅ Integrates `dorny/paths-filter@v3` internally

## Usage

```yaml
- name: Detect changed modules
  id: changed
  uses: ./.github/actions/detect-changed-go-modules

- name: Build changed modules
  if: contains(fromJSON(steps.changed.outputs.changed), 'a')
  run: |
    cd a
    go build ./...
```

## Outputs

### `changed`

A JSON array containing the paths of modules that have changed. Can be parsed using `fromJSON()`.

**Example:** `["a", "b"]`

## Example Workflows

### Build Only Changed Modules

```yaml
name: CI

on:
  pull_request:
  push:
    branches: [main]

jobs:
  detect-changes:
    runs-on: ubuntu-latest
    outputs:
      changed: ${{ steps.detect.outputs.changed }}
    steps:
      - uses: actions/checkout@v4
      
      - name: Detect changed modules
        id: detect
        uses: ./.github/actions/detect-changed-go-modules
  
  build:
    needs: detect-changes
    if: needs.detect-changes.outputs.changed != '[]'
    runs-on: ubuntu-latest
    strategy:
      matrix:
        module: ${{ fromJSON(needs.detect-changes.outputs.changed) }}
    steps:
      - uses: actions/checkout@v4
      
      - uses: actions/setup-go@v5
        with:
          go-version: '1.21'
      
      - name: Build ${{ matrix.module }}
        run: |
          cd ${{ matrix.module }}
          go build ./...
```

### Conditional Job Execution

```yaml
jobs:
  detect-changes:
    runs-on: ubuntu-latest
    outputs:
      changed: ${{ steps.detect.outputs.changed }}
    steps:
      - uses: actions/checkout@v4
      - id: detect
        uses: ./.github/actions/detect-changed-go-modules
  
  build-module-a:
    needs: detect-changes
    if: contains(fromJSON(needs.detect-changes.outputs.changed), 'a')
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - run: cd a && go build ./...
  
  build-module-b:
    needs: detect-changes
    if: contains(fromJSON(needs.detect-changes.outputs.changed), 'b')
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - run: cd b && go build ./...
```

## How It Works

1. **Discovery**: Uses `@actions/glob` to find all `go.mod` files
2. **Path Extraction**: Converts file paths to module paths
3. **Relationship Detection**: Identifies parent-child module relationships
4. **Filter Generation**: Creates inclusion patterns with child exclusions
5. **Change Detection**: Uses `dorny/paths-filter@v3` to detect which modules changed
6. **Output**: Returns JSON array of changed module paths

## Nested Module Behavior

### Parent Changes Don't Trigger Children

When a file in `a/file.go` changes:
- ✅ Module `a` is marked as changed
- ❌ Module `a/v2` is NOT marked as changed

### Child Changes Only Trigger That Child

When a file in `a/v2/file.go` changes:
- ❌ Module `a` is NOT marked as changed
- ✅ Module `a/v2` is marked as changed

## Requirements

- Repository must be checked out before using this action (`actions/checkout@v4`)
- Requires `actions/github-script@v7` (automatically loaded)
- Requires `dorny/paths-filter@v3` (automatically loaded)

## Comparison with dorny/paths-filter Alone

Using `dorny/paths-filter` directly requires manually maintaining filter definitions:

**Before:**
```yaml
- uses: dorny/paths-filter@v3
  with:
    filters: |
      a:
        - 'a/**'
        - '!a/v2/**'  # Must manually exclude nested modules
      a/v2:
        - 'a/v2/**'
      b:
        - 'b/**'
```

**After:**
```yaml
- uses: ./.github/actions/detect-changed-go-modules
  # Automatically discovers modules and handles exclusions!
```

## License

MIT
