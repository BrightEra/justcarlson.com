# Technology Stack: Script Refactoring (v0.4.0)

**Project:** justcarlson.com publishing workflow refactor
**Researched:** 2026-02-01
**Focus:** YAML frontmatter manipulation, bash library patterns, bash vs Python tradeoffs
**Overall Confidence:** HIGH

## Executive Summary

The current publishing scripts use fragile sed/grep/perl chains for YAML frontmatter. For reliable YAML manipulation (especially updating boolean fields like `draft: true/false`), **yq (mikefarah/yq v4)** is the recommended tool. For bash code sharing, a **single library file with source pattern** is appropriate for this codebase size.

**Key recommendation:** Stay bash-only. The scripts are bash scripts with bash logic; adding Python would create a hybrid that is harder to maintain. yq provides the YAML reliability needed without leaving bash.

---

## Question 1: YAML Frontmatter Manipulation

### Current Problems

The existing scripts use fragile patterns that break on edge cases:

```bash
# Current: fragile sed/grep chains (from publish.sh lines 279, 506)
sed -n '/^---$/,/^---$/p' "$file" | grep -E "^${key}:" | head -1 | ...

# Current: perl for multiline matching (publish.sh line 592)
perl -0777 -ne 'exit(!/status:\s*\n\s*-\s*[Pp]ublished/i)' "$file"
```

**Problems with current approach:**
1. Cannot handle quoted values reliably
2. Cannot handle YAML arrays/lists properly
3. Cannot UPDATE fields in-place (only READ)
4. No handling of nested structures
5. Different tools mixed (sed, grep, perl, awk)

### Recommended Solution: yq (mikefarah/yq v4)

| Tool | Version | Purpose | Why |
|------|---------|---------|-----|
| **yq** | v4.x (mikefarah) | YAML frontmatter read/write | Proper YAML parser, `--front-matter` flag for markdown files, jq-like syntax, single binary |

**CRITICAL:** There are TWO different `yq` tools:

| Project | Language | `--front-matter` | Arch Linux default |
|---------|----------|------------------|-------------------|
| mikefarah/yq | Go | Yes (v4+) | No |
| kislyuk/yq | Python (wraps jq) | No | Yes (v3.4.3) |

The currently installed `yq` (v3.4.3) is kislyuk/yq (Python), which **does NOT have `--front-matter` support**. Must install mikefarah/yq v4.

**Confidence:** HIGH - Verified via [yq front-matter documentation](https://mikefarah.gitbook.io/yq/usage/front-matter)

### yq Installation

**For Arch Linux (local development):**
```bash
# Option 1: Download binary directly
wget https://github.com/mikefarah/yq/releases/latest/download/yq_linux_amd64 -O ~/.local/bin/yq
chmod +x ~/.local/bin/yq

# Option 2: Snap (if using AUR)
snap install yq

# Option 3: Go install
go install github.com/mikefarah/yq/v4@latest
```

**For devcontainer:**
```json
// Add to .devcontainer/devcontainer.json features
"features": {
  "ghcr.io/devcontainers-extra/features/yq:1": {}
}
```

Or in postCreateCommand:
```bash
wget -qO /usr/local/bin/yq https://github.com/mikefarah/yq/releases/latest/download/yq_linux_amd64 && chmod +x /usr/local/bin/yq
```

**For macOS (Homebrew):**
```bash
brew install yq  # This IS mikefarah/yq
```

**Confidence:** HIGH - Based on [mikefarah/yq GitHub](https://github.com/mikefarah/yq) and [install docs](https://mikefarah.gitbook.io/yq/)

### yq Usage Patterns for Frontmatter

**Read a frontmatter field:**
```bash
# Extract title from markdown file with frontmatter
yq --front-matter=extract '.title' post.md

# Read boolean field
yq --front-matter=extract '.draft' post.md
```

**Update a frontmatter field (in-place):**
```bash
# Set draft to true
yq --front-matter=process -i '.draft = true' post.md

# Set draft to false (boolean, not string)
yq --front-matter=process -i '.draft = false' post.md

# Update string field
yq --front-matter=process -i '.title = "New Title"' post.md
```

**Conditional updates:**
```bash
# Only set draft if field exists
yq --front-matter=process -i 'select(.draft != null) | .draft = true' post.md

# Add field if missing
yq --front-matter=process -i '.draft //= false' post.md
```

**Working with arrays (status field):**
```bash
# Check if status contains "Published"
yq --front-matter=extract '.status | contains(["Published"])' post.md

# Add "Published" to status array
yq --front-matter=process -i '.status += ["Published"]' post.md

# Remove "Draft" from status array
yq --front-matter=process -i '.status -= ["Draft"]' post.md
```

**Confidence:** HIGH - Based on [yq operators documentation](https://mikefarah.gitbook.io/yq/operators)

### Boolean Handling Note

YAML 1.2 (which yq uses) only recognizes `true`/`false` as boolean literals. Older values like `yes`/`no`/`on`/`off` are treated as strings.

```bash
# Correct: produces boolean true
yq --front-matter=process -i '.draft = true' post.md

# Incorrect: produces string "yes"
yq --front-matter=process -i '.draft = "yes"' post.md
```

**Confidence:** HIGH - Based on [yq boolean operators docs](https://mikefarah.gitbook.io/yq/operators/boolean-operators)

### Alternatives Considered

| Tool | Pros | Cons | Verdict |
|------|------|------|---------|
| **yq (mikefarah)** | Proper YAML parser, `--front-matter` flag, jq syntax, single binary | Need to install (not default on Arch) | **RECOMMENDED** |
| **python-frontmatter** | Full Python API, handles edge cases | Adds Python dependency, different paradigm | Not for bash scripts |
| **sed/awk/perl** | Already installed | Fragile, no proper YAML parsing, can't handle arrays | Current problem |
| **kislyuk/yq** | Already installed on Arch | No `--front-matter` flag, wraps jq | Insufficient |

**Confidence:** HIGH - Based on [python-frontmatter PyPI](https://pypi.org/project/python-frontmatter/) and practical comparison

---

## Question 2: Bash Library Pattern

### Current Problem: Duplicated Functions

These functions are duplicated across 3 scripts:

| Function | publish.sh | list-posts.sh | unpublish.sh |
|----------|------------|---------------|--------------|
| `extract_frontmatter()` | Line 276 | Line 102 | - |
| `get_frontmatter_field()` | Line 282 | Line 108 | - |
| `extract_frontmatter_value()` | Line 500 | Line 188 | Line 128 |
| `slugify()` | Line 482 | Line 197 | Line 110 |
| `validate_iso8601()` | Line 295 | Line 120 | - |
| `validate_frontmatter()` | Line 312 | Line 137 | - |
| `load_config()` | Line 448 | Line 70 | Line 92 |
| Color variables | Lines 6-10 | Lines 6-10 | Lines 6-10 |
| Exit codes | Lines 19-22 | Lines 19-21 | Lines 21-24 |

**Total:** ~200 lines of duplicated code across 3 scripts.

### Recommended Solution: Single Library File

For a codebase this size (3 scripts, ~200 duplicated lines), a **single shared library file** is the right approach.

**File:** `scripts/lib/common.sh`

**Structure:**
```bash
#!/usr/bin/env bash
# Common library for blog publishing scripts
# Source this file: source "$(dirname "$0")/lib/common.sh"

# Guard against double-sourcing
[[ -n "${_COMMON_SH_LOADED:-}" ]] && return
_COMMON_SH_LOADED=1

# ============================================================================
# Constants
# ============================================================================

# Colors for output
export RED='\033[0;31m'
export GREEN='\033[0;32m'
export YELLOW='\033[1;33m'
export CYAN='\033[0;36m'
export RESET='\033[0m'

# Exit codes
export EXIT_SUCCESS=0
export EXIT_ERROR=1
export EXIT_CANCELLED=130

# Paths
export CONFIG_FILE=".claude/settings.local.json"
export BLOG_DIR="src/content/blog"
export ASSETS_DIR="public/assets/blog"

# ============================================================================
# Configuration
# ============================================================================

load_config() {
    # Load and validate Obsidian vault configuration
    # Sets: VAULT_PATH (global)
    ...
}

# ============================================================================
# YAML/Frontmatter (using yq)
# ============================================================================

fm_get() {
    # Get a frontmatter field value
    # Usage: fm_get <file> <field>
    local file="$1" field="$2"
    yq --front-matter=extract ".$field" "$file"
}

fm_set() {
    # Set a frontmatter field value (in-place)
    # Usage: fm_set <file> <field> <value>
    local file="$1" field="$2" value="$3"
    yq --front-matter=process -i ".$field = $value" "$file"
}

fm_has_status() {
    # Check if status array contains a value
    # Usage: fm_has_status <file> <status>
    local file="$1" status="$2"
    [[ "$(yq --front-matter=extract ".status | contains([\"$status\"])" "$file")" == "true" ]]
}

# ============================================================================
# Utilities
# ============================================================================

slugify() {
    # Convert string to URL-safe slug
    local name="$1"
    name="${name%.md}"
    echo "$name" | tr '[:upper:]' '[:lower:]' | tr ' ' '-' | sed 's/[^a-z0-9-]//g' | sed 's/-\+/-/g' | sed 's/^-//' | sed 's/-$//'
}

validate_iso8601() {
    # Validate ISO 8601 datetime format
    local datetime="$1"
    [[ "$datetime" =~ ^[0-9]{4}-[0-9]{2}-[0-9]{2}(T[0-9]{2}:[0-9]{2}:[0-9]{2})?$ ]]
}

# ============================================================================
# Validation
# ============================================================================

validate_frontmatter() {
    # Validate frontmatter for required fields
    # Returns: 0 if valid, 1 if invalid (errors on stdout)
    ...
}
```

**Confidence:** HIGH - Based on [bash library patterns](https://www.lost-in-it.com/posts/designing-modular-bash-functions-namespaces-library-patterns/) and standard practice

### Sourcing Pattern

Each script sources the library relative to its own location:

```bash
#!/usr/bin/env bash
set -euo pipefail

# Resolve script directory and source library
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/lib/common.sh"

# Rest of script...
```

**Why this pattern:**
- `${BASH_SOURCE[0]}` is the actual script path, even when sourced
- `dirname` + `cd` resolves symlinks and relative paths
- Works regardless of where script is invoked from
- Works in dev containers and CI

**Confidence:** HIGH - Based on [Baeldung bash source](https://www.baeldung.com/linux/source-include-files)

### Directory Structure

```
scripts/
  lib/
    common.sh         # Shared functions and constants
  publish.sh          # Sources lib/common.sh
  list-posts.sh       # Sources lib/common.sh
  unpublish.sh        # Sources lib/common.sh
  setup.sh            # Standalone (no shared code needed)
  bootstrap.sh        # Standalone (no shared code needed)
```

### Why NOT Multiple Library Files

For 3 scripts with ~200 lines of shared code, splitting into multiple files (logging.sh, yaml.sh, validation.sh) adds complexity without benefit:

| Approach | Files | Imports per script | Benefit |
|----------|-------|-------------------|---------|
| Single library | 1 | 1 | Simpler, all constants in one place |
| Multiple libraries | 3-4 | 2-4 | Overkill for this size |

**Rule of thumb:** Split when a library file exceeds ~300-400 lines or when scripts need different subsets.

---

## Question 3: Bash vs Python

### Recommendation: Stay Bash-Only

**Verdict:** Keep scripts in bash, use yq for YAML handling.

### Analysis

| Factor | Bash + yq | Bash + Python hybrid |
|--------|-----------|---------------------|
| **Complexity** | Single paradigm | Two languages, two runtimes |
| **Dependencies** | yq binary (easy to install) | Python + pip + packages |
| **Devcontainer** | Add yq feature | Add Python feature + pip packages |
| **Maintainability** | One skill set | Requires both bash and Python |
| **CI compatibility** | Universal | May need Python setup |
| **Current scripts** | Minor refactor | Major rewrite |

### When Python WOULD Make Sense

Python would be justified if:
- Complex data transformations (JSON APIs, data pipelines)
- Need for python-frontmatter's advanced features (custom YAML handlers)
- Already have Python in the stack for other tooling
- Scripts grow beyond ~500 lines of complex logic

**None of these apply here.** The scripts are simple file operations with YAML parsing.

### Migration Path

If Python becomes needed later, the path is clear:
1. Create `scripts/lib/yaml_utils.py` with python-frontmatter
2. Call from bash: `python scripts/lib/yaml_utils.py get "$file" "$field"`
3. Gradually migrate scripts to Python as needed

**Confidence:** HIGH - This is an architectural judgment based on the codebase analysis

---

## Implementation Summary

### Files to Create

| File | Purpose | Lines (est.) |
|------|---------|--------------|
| `scripts/lib/common.sh` | Shared functions and constants | ~150 |

### Files to Modify

| File | Changes |
|------|---------|
| `scripts/publish.sh` | Remove duplicated functions, source common.sh, use yq |
| `scripts/list-posts.sh` | Remove duplicated functions, source common.sh, use yq |
| `scripts/unpublish.sh` | Remove duplicated functions, source common.sh, use yq |
| `.devcontainer/devcontainer.json` | Add yq feature |

### Dependencies to Add

| Tool | Installation | Version |
|------|--------------|---------|
| yq (mikefarah) | devcontainer feature + local install | v4.x |

---

## Installation Commands

### Local (Arch Linux)

```bash
# Install mikefarah/yq (not kislyuk/yq which is default)
wget https://github.com/mikefarah/yq/releases/latest/download/yq_linux_amd64 -O ~/.local/bin/yq
chmod +x ~/.local/bin/yq

# Verify correct version
yq --version  # Should show v4.x, not v3.x
yq --help | grep front-matter  # Should show --front-matter flag
```

### Devcontainer

```json
{
  "features": {
    "ghcr.io/devcontainers-extra/features/yq:1": {}
  }
}
```

### macOS (Homebrew)

```bash
brew install yq  # This IS mikefarah/yq on Homebrew
```

---

## Quality Gate Checklist

- [x] YAML manipulation approach is reliable (yq handles edge cases)
- [x] Library pattern is practical for this codebase size (single file)
- [x] Cross-platform compatibility considered (install instructions for Arch, macOS, devcontainer)

---

## Sources

### YAML/yq
- [yq Front Matter Documentation](https://mikefarah.gitbook.io/yq/usage/front-matter) - Official front-matter handling
- [yq GitHub (mikefarah)](https://github.com/mikefarah/yq) - Installation and usage
- [yq Boolean Operators](https://mikefarah.gitbook.io/yq/operators/boolean-operators) - Boolean handling
- [yq Issue #1123: Boolean String](https://github.com/mikefarah/yq/issues/1123) - Boolean edge cases
- [Upgrading from yq v3](https://mikefarah.gitbook.io/yq/upgrading-from-v3) - v3 vs v4 differences

### Bash Libraries
- [Designing Modular Bash](https://www.lost-in-it.com/posts/designing-modular-bash-functions-namespaces-library-patterns/) - Library patterns
- [Baeldung: Source Include Files](https://www.baeldung.com/linux/source-include-files) - Source command patterns
- [Gabriel Staples: Bash Libraries](https://gabrielstaples.com/bash-libraries/) - Practical examples

### Python Frontmatter (for comparison)
- [python-frontmatter PyPI](https://pypi.org/project/python-frontmatter/) - Package details
- [python-frontmatter Docs](https://python-frontmatter.readthedocs.io/) - API documentation
- [Python Frontmatter Comparison](https://safjan.com/python-packages-yaml-front-matter-markdown/) - Package comparison

---

## Confidence Assessment

| Area | Confidence | Reason |
|------|------------|--------|
| yq for YAML | HIGH | Official docs, verified `--front-matter` flag |
| yq installation | HIGH | Multiple verified methods |
| Bash library pattern | HIGH | Standard practice, appropriate for size |
| Bash vs Python | HIGH | Clear architectural analysis |
| Boolean handling | HIGH | YAML 1.2 spec + yq docs |
