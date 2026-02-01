# Architecture: Bash Script Refactoring

**Domain:** Bash script modularization for blog publishing workflow
**Researched:** 2026-02-01
**Confidence:** HIGH (established patterns, well-documented practices)

## Executive Summary

The current scripts have significant code duplication (~280 lines duplicated across 3 scripts). The recommended solution is a **single shared library** (`scripts/lib/common.sh`) that consolidates all duplicated functions, sourced by each script. This follows established bash library patterns while staying appropriate for a personal blog project.

## Current State Analysis

### Script Inventory

| Script | Lines | Primary Purpose | Duplication |
|--------|-------|-----------------|-------------|
| `publish.sh` | 1326 | Full publish workflow | Source of truth for most functions |
| `list-posts.sh` | 510 | List posts with validation | Duplicates validation, frontmatter |
| `unpublish.sh` | 297 | Remove published posts | Duplicates slugify, config loading |
| `setup.sh` | 205 | Configure vault path | Minimal duplication (color codes) |
| `bootstrap.sh` | 142 | Bootstrap dev environment | Standalone (different domain) |

### Identified Duplications

**1. Color Constants** (12 lines x 4 scripts = 48 lines)
```bash
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
RESET='\033[0m'
```
Duplicated in: `publish.sh`, `list-posts.sh`, `unpublish.sh`, `setup.sh`

**2. Config Loading** (25 lines x 3 scripts = 75 lines)
```bash
load_config() {
    # Validate CONFIG_FILE exists
    # Check jq installed
    # Extract VAULT_PATH
    # Validate vault directory
}
```
Duplicated in: `publish.sh`, `list-posts.sh`, `unpublish.sh`

**3. Exit Codes** (4 lines x 3 scripts = 12 lines)
```bash
EXIT_SUCCESS=0
EXIT_ERROR=1
EXIT_CANCELLED=130
```
Duplicated in: `publish.sh`, `list-posts.sh`, `unpublish.sh`

**4. Frontmatter Functions** (45 lines x 2 scripts = 90 lines)
```bash
extract_frontmatter()
get_frontmatter_field()
extract_frontmatter_value()
validate_iso8601()
validate_frontmatter()
```
Duplicated in: `publish.sh`, `list-posts.sh`

**5. Slugify Function** (15 lines x 3 scripts = 45 lines)
```bash
slugify() {
    local name="$1"
    name="${name%.md}"
    # lowercase, spaces to hyphens, remove special chars
}
```
Duplicated in: `publish.sh`, `list-posts.sh`, `unpublish.sh`

**6. Project Paths** (3 lines x 3 scripts = 9 lines)
```bash
CONFIG_FILE=".claude/settings.local.json"
BLOG_DIR="src/content/blog"
ASSETS_DIR="public/assets/blog"
```
Duplicated in: `publish.sh`, `list-posts.sh`, `unpublish.sh`

**Total duplicated code: ~280 lines**

## Recommended Architecture

### Directory Structure

```
scripts/
  lib/
    common.sh      # Shared library (sourced by other scripts)
  publish.sh       # Main publish workflow (uses lib/common.sh)
  list-posts.sh    # List posts utility (uses lib/common.sh)
  unpublish.sh     # Remove post utility (uses lib/common.sh)
  setup.sh         # Setup wizard (uses lib/common.sh for colors only)
  bootstrap.sh     # Dev environment bootstrap (standalone)
```

### Library Organization

**Single library is sufficient.** With ~280 lines of shared code and only 4 consuming scripts, a single `common.sh` library is the right level of abstraction. Creating multiple libraries (e.g., `colors.sh`, `config.sh`, `frontmatter.sh`) would be over-engineering for this codebase.

### Library Contents: `scripts/lib/common.sh`

```bash
#!/usr/bin/env bash
# Shared library for blog publishing scripts
# Source with: source "${SCRIPT_DIR}/lib/common.sh"

# Guard against double-sourcing
if [[ -n "${_COMMON_LIB_LOADED:-}" ]]; then
    return 0
fi
_COMMON_LIB_LOADED=1

# ============================================================================
# Colors
# ============================================================================
readonly RED='\033[0;31m'
readonly GREEN='\033[0;32m'
readonly YELLOW='\033[1;33m'
readonly CYAN='\033[0;36m'
readonly BLUE='\033[0;34m'
readonly RESET='\033[0m'

# ============================================================================
# Exit Codes
# ============================================================================
readonly EXIT_SUCCESS=0
readonly EXIT_ERROR=1
readonly EXIT_CANCELLED=130

# ============================================================================
# Project Paths
# ============================================================================
readonly CONFIG_FILE=".claude/settings.local.json"
readonly BLOG_DIR="src/content/blog"
readonly ASSETS_DIR="public/assets/blog"

# ============================================================================
# Configuration
# ============================================================================

# Load and validate configuration
# Sets: VAULT_PATH (global)
# Exits on error
load_config() {
    if [[ ! -f "$CONFIG_FILE" ]]; then
        echo -e "${RED}Error: Config file not found: $CONFIG_FILE${RESET}" >&2
        echo -e "${YELLOW}Run 'just setup' first to configure your Obsidian vault path.${RESET}" >&2
        exit $EXIT_ERROR
    fi

    if ! command -v jq &>/dev/null; then
        echo -e "${RED}Error: jq is required but not installed.${RESET}" >&2
        echo -e "${YELLOW}Install with: pacman -S jq (Arch) or brew install jq (macOS)${RESET}" >&2
        exit $EXIT_ERROR
    fi

    VAULT_PATH=$(jq -r '.obsidianVaultPath // empty' "$CONFIG_FILE")

    if [[ -z "$VAULT_PATH" ]]; then
        echo -e "${RED}Error: Obsidian vault path not configured.${RESET}" >&2
        echo -e "${YELLOW}Run 'just setup' to configure your vault path.${RESET}" >&2
        exit $EXIT_ERROR
    fi

    if [[ ! -d "$VAULT_PATH" ]]; then
        echo -e "${RED}Error: Vault directory does not exist: $VAULT_PATH${RESET}" >&2
        echo -e "${YELLOW}Run 'just setup' to reconfigure your vault path.${RESET}" >&2
        exit $EXIT_ERROR
    fi
}

# ============================================================================
# Slug Generation
# ============================================================================

# Convert filename to URL-safe slug
# Args: $1 - filename or string to slugify
# Output: slug on stdout
slugify() {
    local name="$1"
    name="${name%.md}"
    name=$(echo "$name" | tr '[:upper:]' '[:lower:]')
    name=$(echo "$name" | tr ' ' '-')
    name=$(echo "$name" | sed 's/[^a-z0-9-]//g')
    name=$(echo "$name" | sed 's/-\+/-/g')
    name=$(echo "$name" | sed 's/^-//' | sed 's/-$//')
    echo "$name"
}

# ============================================================================
# Frontmatter Extraction
# ============================================================================

# Extract YAML frontmatter content (between --- markers)
# Args: $1 - file path
# Output: frontmatter content on stdout (without --- markers)
extract_frontmatter() {
    local file="$1"
    sed -n '/^---$/,/^---$/p' "$file" | sed '1d;$d'
}

# Extract a field value from frontmatter content
# Args: $1 - frontmatter content, $2 - field name
# Output: field value on stdout
get_frontmatter_field() {
    local frontmatter="$1"
    local field="$2"
    local value
    value=$(echo "$frontmatter" | grep -E "^${field}:" | head -1 | sed "s/^${field}:[[:space:]]*//" | sed 's/^["\x27]//' | sed 's/["\x27]$//' | tr -d '\r')
    echo "$value"
}

# Extract a field directly from a file
# Args: $1 - file path, $2 - field name
# Output: field value on stdout
extract_frontmatter_value() {
    local file="$1"
    local key="$2"
    sed -n '/^---$/,/^---$/p' "$file" | grep -E "^${key}:" | head -1 | sed "s/^${key}:[[:space:]]*//" | sed 's/^"//' | sed 's/"$//' | tr -d '\r'
}

# ============================================================================
# Validation
# ============================================================================

# Validate ISO 8601 datetime format
# Args: $1 - datetime string
# Returns: 0 if valid, 1 if invalid
validate_iso8601() {
    local datetime="$1"
    if [[ "$datetime" =~ ^[0-9]{4}-[0-9]{2}-[0-9]{2}T[0-9]{2}:[0-9]{2}:[0-9]{2} ]]; then
        return 0
    fi
    if [[ "$datetime" =~ ^[0-9]{4}-[0-9]{2}-[0-9]{2}$ ]]; then
        return 0
    fi
    return 1
}

# Validate frontmatter for required fields
# Args: $1 - file path
# Output: error messages on stdout (one per line)
# Returns: 0 if valid, 1 if invalid
validate_frontmatter() {
    local file="$1"
    local errors=()
    local frontmatter
    frontmatter=$(extract_frontmatter "$file")

    if [[ -z "$frontmatter" ]]; then
        errors+=("No frontmatter found (YAML block between --- markers)")
        printf '%s\n' "${errors[@]}"
        return 1
    fi

    local title pubDatetime description
    title=$(get_frontmatter_field "$frontmatter" "title")
    pubDatetime=$(get_frontmatter_field "$frontmatter" "pubDatetime")
    description=$(get_frontmatter_field "$frontmatter" "description")

    if [[ -z "$title" ]]; then
        errors+=("Missing title (required for SEO and display)")
    fi
    if [[ -z "$pubDatetime" ]]; then
        errors+=("Missing pubDatetime (required for post ordering and URLs)")
    elif ! validate_iso8601 "$pubDatetime"; then
        errors+=("Invalid pubDatetime format: '$pubDatetime' (expected YYYY-MM-DDTHH:MM:SS or YYYY-MM-DD)")
    fi
    if [[ -z "$description" ]]; then
        errors+=("Missing description (required for SEO and previews)")
    fi

    if [[ ${#errors[@]} -gt 0 ]]; then
        printf '%s\n' "${errors[@]}"
        return 1
    fi
    return 0
}
```

### Sourcing Pattern

Each script should source the library using a robust path resolution:

```bash
#!/usr/bin/env bash
set -euo pipefail

# Resolve script directory for relative imports
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/lib/common.sh"

# Script-specific code follows...
```

This pattern:
1. Works regardless of where the script is called from
2. Uses `${BASH_SOURCE[0]}` which is correct even when sourced
3. Creates absolute path to library

### Justfile Integration

The justfile remains unchanged - it already uses thin wrappers:

```just
publish *args='':
    ./scripts/publish.sh {{args}}

list-posts *args='':
    ./scripts/list-posts.sh {{args}}
```

The library extraction is transparent to justfile consumers.

## Refactoring Order

Based on dependencies and risk, refactor in this order:

### Phase 1: Create Library (LOW RISK)

1. Create `scripts/lib/common.sh` with extracted functions
2. Add double-source guard
3. Document each function with comments

No scripts change yet - library exists but is not used.

### Phase 2: Migrate `unpublish.sh` (LOW RISK)

**Why first:** Smallest script (297 lines), simplest dependencies, lowest usage frequency.

Changes:
- Add SCRIPT_DIR resolution
- Source common.sh
- Remove: color constants, exit codes, slugify, extract_frontmatter_value, load_config (partial)

### Phase 3: Migrate `list-posts.sh` (MEDIUM RISK)

**Why second:** Medium complexity, uses validation functions.

Changes:
- Add SCRIPT_DIR resolution
- Source common.sh
- Remove: all duplicated functions

### Phase 4: Migrate `publish.sh` (MEDIUM RISK)

**Why third:** Largest script, but shared functions are now proven.

Changes:
- Add SCRIPT_DIR resolution
- Source common.sh
- Remove: all duplicated functions
- Keep publish-specific functions (rollback, image handling, commits)

### Phase 5: Migrate `setup.sh` (LOW RISK)

**Why last:** Only uses color constants, standalone otherwise.

Changes:
- Add SCRIPT_DIR resolution
- Source common.sh
- Remove: color constants only

**Note:** `bootstrap.sh` stays standalone - different domain, no meaningful overlap.

## What NOT to Over-Engineer

This is a personal blog, not a framework. Avoid these temptations:

### 1. Multiple Library Files
**Do not:** `lib/colors.sh`, `lib/config.sh`, `lib/frontmatter.sh`, `lib/validation.sh`

**Why not:** With 4 consuming scripts and ~150 lines of shared code, one file is cleaner. Multiple files add cognitive overhead and require managing multiple sources.

### 2. Namespace Prefixes
**Do not:** `blog_slugify()`, `blog_validate_frontmatter()`

**Why not:** We have no namespace collision risks. These scripts are consumed only by this project. Prefixes add verbosity without benefit.

### 3. Testing Framework
**Do not:** Add BATS, create `tests/` directory, write unit tests for each function.

**Why not:** These scripts are:
- Simple transformations (easily verified manually)
- Integration-focused (actual test is "does publish work?")
- Low change frequency

A `--dry-run` flag (which already exists on publish.sh) is sufficient.

### 4. Configuration Override Pattern
**Do not:** `export BLOG_DIR="${BLOG_DIR:-src/content/blog}"`

**Why not:** These paths are project constants, not user configuration. They only change if the Astro project structure changes, which would require code changes anyway.

### 5. Splitting publish.sh Into Multiple Scripts
**Do not:** `discover.sh`, `validate.sh`, `copy.sh`, `commit.sh`

**Why not:** The publish workflow is a single logical operation. Breaking it up would:
- Require orchestration logic
- Lose the rollback capability (which depends on tracking state)
- Make the workflow harder to understand

**Do:** Keep `publish.sh` as a single script with well-organized internal sections.

## Patterns to Follow

### 1. Double-Source Guard
Prevent issues when library is sourced multiple times:
```bash
if [[ -n "${_COMMON_LIB_LOADED:-}" ]]; then
    return 0
fi
_COMMON_LIB_LOADED=1
```

### 2. Function Documentation
Document each function's purpose and parameters:
```bash
# Validate frontmatter for required fields
# Args: $1 - file path
# Output: error messages on stdout (one per line)
# Returns: 0 if valid, 1 if invalid
validate_frontmatter() {
```

### 3. Readonly Constants
Use `readonly` for values that should never change:
```bash
readonly RED='\033[0;31m'
readonly EXIT_SUCCESS=0
readonly CONFIG_FILE=".claude/settings.local.json"
```

### 4. Local Variables in Functions
Prevent global scope pollution:
```bash
slugify() {
    local name="$1"  # local, not global
    # ...
}
```

### 5. Robust Path Resolution
Handle being called from any directory:
```bash
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/lib/common.sh"
```

## Estimated Line Changes

| Script | Current | After Refactor | Reduction |
|--------|---------|----------------|-----------|
| `common.sh` | 0 | ~150 | (new file) |
| `publish.sh` | 1326 | ~1180 | -146 (11%) |
| `list-posts.sh` | 510 | ~400 | -110 (22%) |
| `unpublish.sh` | 297 | ~230 | -67 (23%) |
| `setup.sh` | 205 | ~195 | -10 (5%) |

**Net reduction:** ~180 lines (duplicates consolidated)

## Component Boundaries

### What Goes in common.sh

| Function | Rationale |
|----------|-----------|
| Color constants | Used by all scripts |
| Exit codes | Used by all publishing scripts |
| Project paths | Used by all publishing scripts |
| `load_config()` | Used by publish, list-posts, unpublish |
| `slugify()` | Used by publish, list-posts, unpublish |
| `extract_frontmatter()` | Used by publish, list-posts |
| `get_frontmatter_field()` | Used by publish, list-posts |
| `extract_frontmatter_value()` | Used by publish, list-posts, unpublish |
| `validate_iso8601()` | Used by publish, list-posts |
| `validate_frontmatter()` | Used by publish, list-posts |

### What Stays in Each Script

| Script | Script-Specific Functions |
|--------|--------------------------|
| `publish.sh` | Image handling, wiki-link conversion, rollback, commits, git push |
| `list-posts.sh` | Table formatting, sorting logic |
| `unpublish.sh` | Post resolution, removal confirmation |
| `setup.sh` | Vault discovery, interactive prompts |
| `bootstrap.sh` | Everything (standalone script) |

## Success Criteria

After refactoring:

- [ ] `scripts/lib/common.sh` exists with all shared functions
- [ ] Each script sources common.sh correctly
- [ ] `just publish --dry-run` works unchanged
- [ ] `just list-posts` works unchanged
- [ ] `just unpublish` (on test post) works unchanged
- [ ] `just setup --help` works unchanged
- [ ] No duplicate function definitions across scripts
- [ ] Color codes, exit codes, paths defined in one place only

## Sources

- [Designing Modular Bash: Functions, Namespaces, and Library Patterns](https://www.lost-in-it.com/posts/designing-modular-bash-functions-namespaces-library-patterns/)
- [How to Write and Test Bash Libraries](https://gabrielstaples.com/bash-libraries/)
- [Advanced Bash Scripting: Mastering Functions and Libraries](https://www.turing.com/blog/advanced-bash-scripting-mastering-functions-and-libraries)
- [Shell Functions Library - Linux Bash Tutorial](https://bash.cyberciti.biz/guide/Shell_functions_library)

---

*Architecture research: 2026-02-01*
