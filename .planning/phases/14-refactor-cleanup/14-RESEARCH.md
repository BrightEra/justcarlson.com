# Phase 14: Refactor Cleanup - Research

**Researched:** 2026-02-01
**Domain:** CLI Patterns, Dead Code Detection, Bash Error Handling
**Confidence:** HIGH

## Summary

This phase focuses on codebase cleanup across two dimensions: CLI discoverability (--help flags, non-interactive mode) and dead code elimination (unused exports, duplicate constants, orphaned components). Research identified that the existing scripts already have well-implemented --help and non-interactive patterns from recent phases, leaving the primary work as verification and consistency.

For dead code detection, [Knip](https://knip.dev) is the recommended tool - it supersedes ts-prune and has built-in Astro support. Initial codebase analysis suggests several potentially unused files: `src/layouts/BaseLayout.astro`, `src/layouts/BlogPost.astro`, and components like `Breadcrumb.astro`, `ThemeToggle.astro`, and `SocialIcons.astro`.

The constants configuration shows duplication between `consts.ts`, `constants.ts`, and `config.ts` (re-exports both). This should be consolidated.

**Primary recommendation:** Run Knip to generate a definitive unused export report, then consolidate constants files and remove confirmed dead code.

## Standard Stack

### Core (Detection)
| Tool | Version | Purpose | Why Standard |
|------|---------|---------|--------------|
| [Knip](https://knip.dev) | 5.x+ | Dead code detection | Recommended replacement for ts-prune, has Astro plugin |
| `bash --help` | N/A | CLI discoverability | GNU standard, user expectation |

### Supporting
| Tool | Purpose | When to Use |
|------|---------|-------------|
| TypeScript compiler | Type checking during refactor | Already in place |
| Biome | Lint after changes | Already configured |

### Alternatives Considered
| Instead of | Could Use | Tradeoff |
|------------|-----------|----------|
| Knip | ts-prune | ts-prune is deprecated/archived, recommends Knip |
| Knip | Manual grep | Knip handles transitive dependencies, manual misses cases |

**Installation:**
```bash
npm install -D knip
```

**Add to package.json:**
```json
{
  "scripts": {
    "knip": "knip"
  }
}
```

## Architecture Patterns

### Recommended Project Structure (After Cleanup)
```
src/
  config.ts           # Single source for all configuration
  constants.ts        # REMOVE - merge into config.ts
  consts.ts           # KEEP as main config (more imports reference this)
  layouts/
    Layout.astro      # Main layout
    PostDetails.astro # Blog post layout
    Main.astro        # Container layout
    AboutLayout.astro # About page layout
    BlogPostLayout.astro # Currently used in [...slug].astro
    # REMOVE: BaseLayout.astro, BlogPost.astro (no imports found)
  components/
    # Keep active components
    # REMOVE: Breadcrumb.astro, ThemeToggle.astro, SocialIcons.astro (no imports)
  utils/
    # All utils appear to be in use
```

### Pattern 1: CLI --help Flag Implementation
**What:** Consistent help flag handling across all scripts
**When to use:** Every script that accepts arguments
**Example:**
```bash
# Source: Google Shell Style Guide / GNU standards
print_help() {
    cat <<EOF
Usage: $0 [OPTIONS]

Description of what this script does.

Options:
  --flag, -f      Description of flag
  --arg ARG       Description with argument
  --help, -h      Show this help message

Examples:
  $0 --flag
  $0 --arg value
EOF
    exit 0
}

# Parse args - handle --help early
for arg in "$@"; do
    case "$arg" in
        --help|-h)
            print_help
            ;;
    esac
done
```

### Pattern 2: Non-Interactive Mode
**What:** Scripts work without TTY via explicit flags
**When to use:** Any script with interactive prompts
**Example:**
```bash
# Source: Current publish.sh implementation
AUTO_CONFIRM=false
SELECT_ALL=false

parse_args() {
    while [[ $# -gt 0 ]]; do
        case "$1" in
            --yes|-y)
                AUTO_CONFIRM=true
                shift
                ;;
            --all|-a)
                SELECT_ALL=true
                shift
                ;;
        esac
    done
}

# Later in script:
if [[ "$AUTO_CONFIRM" == "true" ]]; then
    # Skip interactive prompt
    proceed=true
else
    read -rp "Continue? [Y/n] " response
    proceed=[[ ! "$response" =~ ^[Nn] ]]
fi
```

### Pattern 3: Constants Consolidation
**What:** Single source of truth for configuration
**When to use:** When multiple files export overlapping data
**Current state:**
```typescript
// config.ts - re-exports both
export * from "./constants";
export * from "./consts";

// consts.ts - main config: SITE, NAV_LINKS, SOCIAL_LINKS, ICON_MAP, NEWSLETTER_CONFIG
// constants.ts - SOCIALS (duplicates SOCIAL_LINKS), SHARE_LINKS
```

**Recommended consolidation:**
```typescript
// consts.ts - becomes single source
export const SITE = { ... };
export const NAV_LINKS = [ ... ];
export const SOCIAL_LINKS = [ ... ];  // Renamed from SOCIALS
export const SHARE_LINKS = [ ... ];   // Move from constants.ts
export const ICON_MAP = { ... };
export const NEWSLETTER_CONFIG = { ... };

// Remove: constants.ts
// Remove: config.ts (or make it just re-export consts.ts)
```

### Anti-Patterns to Avoid
- **Multiple config files with overlapping exports:** Creates confusion about source of truth
- **Commented-out code as documentation:** Remove dead code, use git history
- **Missing --help on scripts:** Frustrates discoverability for users and Claude

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| Dead code detection | Manual grep for unused exports | Knip | Handles transitive imports, has framework awareness |
| Argument parsing | Complex hand-rolled logic | `getopts` or case/shift pattern | Standard, fewer edge cases |
| Exit code handling | Magic numbers | Named constants (EXIT_SUCCESS, EXIT_ERROR) | Already used, maintain pattern |

**Key insight:** The scripts already follow good patterns. This phase is about verification and filling gaps, not rewriting.

## Common Pitfalls

### Pitfall 1: Removing "Unused" Components That Are Actually Used
**What goes wrong:** Component is imported in .astro file but Knip doesn't see it
**Why it happens:** Astro components can be imported dynamically or via glob patterns
**How to avoid:** Verify each removal with manual grep before deleting
**Warning signs:** Build breaks after removal

### Pitfall 2: Breaking Imports When Consolidating Constants
**What goes wrong:** Removing a file breaks imports elsewhere
**Why it happens:** Components import from specific paths
**How to avoid:** Search all import paths before removal, update incrementally
**Warning signs:** TypeScript errors after file deletion

### Pitfall 3: --help Exits Mid-Parse
**What goes wrong:** --help flag processed after partial argument parsing causes issues
**Why it happens:** Help check happens inside the main parsing loop
**How to avoid:** Check for --help in a separate first pass, OR ensure help check exits immediately
**Warning signs:** Side effects (variable changes) visible before help output

### Pitfall 4: Non-Interactive Mode Missing Edge Cases
**What goes wrong:** Script prompts in unexpected code path
**Why it happens:** Not all interactive paths covered by --yes flag
**How to avoid:** Audit all `read -rp` calls and ensure AUTO_CONFIRM path exists
**Warning signs:** Script hangs in CI/Claude Code

## Code Examples

### Knip Configuration for Astro
```json
// knip.json (optional - Knip auto-detects Astro)
{
  "$schema": "https://unpkg.com/knip@5/schema.json",
  "entry": [
    "src/pages/**/*.{astro,ts}",
    "src/content.config.ts"
  ],
  "project": ["src/**/*.{astro,ts,tsx,js,mjs}"],
  "ignore": [
    "src/env.d.ts"
  ],
  "ignoreDependencies": [
    "@types/node"
  ]
}
```

### Running Knip
```bash
# Source: https://knip.dev/overview/getting-started

# First run - see all issues
npx knip

# Limit output for initial review
npx knip --max-issues 10

# Focus on unused exports only
npx knip --include exports

# Auto-fix (removes unused exports)
npx knip --fix  # CAUTION: Review first!
```

### Consistent Error Handling Pattern
```bash
# Source: Current scripts/publish.sh

# Exit codes (define at top)
EXIT_SUCCESS=0
EXIT_ERROR=1
EXIT_CANCELLED=130

# Error output to stderr with color
echo -e "${RED}Error: Description${RESET}" >&2
echo -e "${YELLOW}Suggestion for resolution${RESET}" >&2
exit $EXIT_ERROR
```

### Script Template with All Required Patterns
```bash
#!/usr/bin/env bash
# Script description
set -euo pipefail

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
RESET='\033[0m'

# Exit codes
EXIT_SUCCESS=0
EXIT_ERROR=1

# Non-interactive flags
AUTO_CONFIRM=false

# ============================================================================
# Help
# ============================================================================

print_help() {
    cat <<EOF
Usage: $0 [OPTIONS]

Description of what this script does.

Options:
  --yes, -y       Auto-confirm prompts (non-interactive mode)
  --help, -h      Show this help message

Non-interactive mode (for Claude Code):
  $0 --yes

Examples:
  $0                  # Interactive
  $0 --yes            # Non-interactive
EOF
    exit 0
}

# ============================================================================
# Argument Parsing
# ============================================================================

parse_args() {
    while [[ $# -gt 0 ]]; do
        case "$1" in
            --yes|-y)
                AUTO_CONFIRM=true
                shift
                ;;
            --help|-h)
                print_help
                ;;
            *)
                echo -e "${RED}Error: Unknown option: $1${RESET}" >&2
                print_help
                ;;
        esac
    done
}

# ============================================================================
# Main
# ============================================================================

main() {
    parse_args "$@"

    # Script logic here

    exit $EXIT_SUCCESS
}

main "$@"
```

## State of the Art

| Old Approach | Current Approach | When Changed | Impact |
|--------------|------------------|--------------|--------|
| ts-prune for dead code | Knip | 2023-2024 | Knip has more features, ts-prune archived |
| Manual unused code search | Automated linting | Ongoing | Knip can run in CI |
| Scripts require TTY | Non-interactive flags | Phases 8-13 | Claude Code compatibility |

**Deprecated/outdated:**
- ts-prune: Archived, maintainer recommends Knip
- Manual `grep` for unused exports: Too error-prone for complex projects

## Current Script Status

Analysis of existing scripts for --help and non-interactive support:

| Script | --help | Non-Interactive | Notes |
|--------|--------|-----------------|-------|
| `publish.sh` | YES | YES (--all, --post, --yes) | Fully compliant |
| `setup.sh` | YES | YES (--vault, --force) | Fully compliant |
| `list-posts.sh` | YES | YES (--all, --published) | Fully compliant |
| `unpublish.sh` | YES | YES (--force) | Fully compliant |
| `bootstrap.sh` | YES | N/A (no prompts) | Fully compliant |

**Finding:** All scripts already support --help and non-interactive mode. Phase 14 success criteria appear to be already met based on recent work.

## Candidate Dead Code

Based on grep analysis (needs Knip verification):

### Potentially Unused Layouts
- `src/layouts/BaseLayout.astro` - No imports found
- `src/layouts/BlogPost.astro` - No imports found (distinct from BlogPostLayout.astro)

### Potentially Unused Components
- `src/components/Breadcrumb.astro` - No imports found
- `src/components/ThemeToggle.astro` - No imports found
- `src/components/SocialIcons.astro` - Only imported by Link.astro, which itself appears unused
- `src/components/HeaderLink.astro` - No imports found

### Duplicate/Consolidate
- `src/config.ts` - Just re-exports consts.ts and constants.ts
- `src/constants.ts` - SOCIALS duplicates SOCIAL_LINKS in consts.ts

### Verify Before Removal
Run Knip first to confirm, then manual grep to ensure no dynamic imports.

## Open Questions

1. **SOCIALS vs SOCIAL_LINKS**
   - What we know: `SOCIALS` in constants.ts and `SOCIAL_LINKS` in consts.ts serve similar purposes
   - What's unclear: Which components use which?
   - Recommendation: Run Knip, then consolidate to single export

2. **BlogPostLayout.astro vs PostDetails.astro**
   - What we know: Both are blog post layouts, BlogPostLayout is used in [...slug].astro
   - What's unclear: Whether PostDetails is also used for certain routes
   - Recommendation: Map all imports before consolidation

## Sources

### Primary (HIGH confidence)
- [Knip Official Documentation](https://knip.dev) - Dead code detection
- [Knip Astro Plugin](https://knip.dev/reference/plugins/astro) - Astro-specific configuration
- [Google Shell Style Guide](https://google.github.io/styleguide/shellguide.html) - Bash best practices
- Codebase analysis of existing scripts

### Secondary (MEDIUM confidence)
- [Effective TypeScript - Knip Recommendation](https://effectivetypescript.com/2023/07/29/knip/) - ts-prune successor
- [Bash Flag Handling](https://bertvv.github.io/cheat-sheets/Bash.html) - Best practices

### Tertiary (LOW confidence)
- WebSearch for "bash --help best practices 2026"

## Metadata

**Confidence breakdown:**
- CLI patterns: HIGH - Scripts already implement well, just verification needed
- Dead code detection: HIGH - Knip documentation is authoritative
- Candidate dead code: MEDIUM - Based on grep, needs Knip verification
- Error handling: HIGH - Patterns already established in codebase

**Research date:** 2026-02-01
**Valid until:** 2026-03-01 (Knip version may update, but patterns stable)
