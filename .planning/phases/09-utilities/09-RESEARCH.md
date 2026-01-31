# Phase 9: Utilities - Research

**Researched:** 2026-01-31
**Domain:** Bash CLI utilities with git integration
**Confidence:** HIGH

## Summary

Phase 9 builds on the established publish.sh patterns to create utility commands for blog post management. The core insight is evolving `just publish` into a **sync operation** where Obsidian serves as the single source of truth, with the blog repository converging to match.

Research focused on three technical domains:
1. **Bash scripting patterns** - Table formatting, colored output, interactive prompts, exit codes
2. **Git operations** - Detecting file removals, listing tracked files, commit history queries
3. **Astro dev server** - Integration patterns and default behavior

The codebase already has strong patterns established in publish.sh (ANSI colors, three-tier selection fallback, validation messaging). This phase extends those patterns rather than introducing new approaches.

**Primary recommendation:** Use established bash utilities (`printf` for tables, ANSI escape codes for colors, `git ls-files` for state comparison, `git log --diff-filter=D` for removal detection) rather than external tools. Keep implementation simple - bash built-ins are sufficient for all required operations.

## Standard Stack

The established libraries/tools for this domain:

### Core
| Library | Version | Purpose | Why Standard |
|---------|---------|---------|--------------|
| bash | 4.0+ | Scripting runtime | POSIX standard, available everywhere |
| git | 2.x | Version control operations | Built into workflow, tracks blog state |
| npm | 8.x+ | Astro dev server launcher | Package manager for Node ecosystem |
| perl | 5.x | Multiline regex (YAML) | Already used in publish.sh for status matching |

### Supporting
| Library | Version | Purpose | When to Use |
|---------|---------|---------|-------------|
| jq | 1.6+ | JSON parsing | Already used in setup.sh for config |
| gum/fzf | latest | Interactive selection | Already used in publish.sh (three-tier fallback) |

### Alternatives Considered
| Instead of | Could Use | Tradeoff |
|------------|-----------|----------|
| printf for tables | `column` command | `column` auto-sizes but loses control over exact widths |
| bash arrays | External diff tool | Built-in array operations are simpler for small lists |
| Direct git commands | `rsync` for sync | git already tracks state, no need for separate tool |

**Installation:**
All core tools already installed (verified by existing publish.sh). No new dependencies required.

## Architecture Patterns

### Recommended Project Structure
```
scripts/
├── publish.sh           # Extended to sync operation
├── list-posts.sh        # New utility (reuses discover_posts pattern)
├── unpublish.sh         # New utility (inverse of publish)
└── setup.sh             # Existing
```

### Pattern 1: Colored Table Output with Printf
**What:** Use printf with format specifiers for aligned columns, combined with ANSI escape codes for colors
**When to use:** Displaying structured data (post lists, validation results)
**Example:**
```bash
# Source: established in publish.sh lines 6-10
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
RESET='\033[0m'

# Table with aligned columns
printf "${CYAN}%-40s %-12s %-10s${RESET}\n" "Title" "Date" "Status"
printf "%-40s %-12s ${GREEN}%-10s${RESET}\n" "My Blog Post" "2026-01-15" "Ready"
printf "%-40s %-12s ${RED}%-10s${RESET}\n" "Draft Post" "(no date)" "Invalid"
```
**Notes:**
- `%-40s` = left-aligned, 40-char wide string
- Color codes before text, RESET after
- ANSI codes don't count toward width (important for alignment)

### Pattern 2: Interactive Confirmation Prompts
**What:** Read user input with default behavior and case-insensitive matching
**When to use:** Destructive operations (unpublish, force push), optional operations (post-hook prompts)
**Example:**
```bash
# Source: https://linuxconfig.org/bash-script-yes-no-prompt-example
read -rp "Push commits to remote? [Y/n] " response

if [[ "$response" =~ ^[Nn] ]]; then
    echo "Skipped push"
    return 0
fi

# Default to Yes (empty = yes)
echo "Pushing..."
```
**Notes:**
- `-r` prevents backslash escaping
- `-p` shows prompt inline
- `[Y/n]` convention: uppercase = default
- Regex `^[Nn]` matches N/n at start

### Pattern 3: Git State Comparison for Sync
**What:** Compare Obsidian posts (source) with blog repo (destination) to detect adds/updates/removals
**When to use:** Sync operation in evolved `just publish`
**Example:**
```bash
# List blog posts currently in repo
blog_posts=($(git ls-files "src/content/blog/**/*.md" | sed 's|.*/||' | sed 's|\.md$||'))

# List Obsidian posts with Published status (from discover_posts)
obsidian_slugs=("${POST_FILES[@]}" | slugify)

# Find posts in blog but not in Obsidian (removals)
for blog_slug in "${blog_posts[@]}"; do
    found=false
    for obs_slug in "${obsidian_slugs[@]}"; do
        [[ "$blog_slug" == "$obs_slug" ]] && found=true && break
    done
    [[ "$found" == "false" ]] && removals+=("$blog_slug")
done
```
**Notes:**
- `git ls-files` lists tracked files (not working tree state)
- Extract slug from path for comparison
- Array iteration for difference (sufficient for personal blog scale)
- Alternative: associative arrays for O(1) lookup if list grows large

### Pattern 4: Git Log for Removal Detection
**What:** Query git history to find recently removed files
**When to use:** Pre-publish hook to warn about re-adding recently unpublished posts
**Example:**
```bash
# Source: https://betterstack.com/community/questions/how-to-find-deleted-file-in-project-commit-history/
# Find files deleted in last 30 days
recently_removed=$(git log --since="30 days ago" --diff-filter=D --name-only --pretty="format:" -- "src/content/blog/**/*.md" | sed '/^$/d')

# Check if any deleted files still have Published status in Obsidian
for removed_path in $recently_removed; do
    slug=$(basename "$removed_path" .md)
    # Check against discovered posts...
done
```
**Notes:**
- `--diff-filter=D` = only deletions
- `--name-only` = just file paths
- `--pretty="format:"` = suppress commit messages
- `--since` accepts "30 days ago", "1 month ago", etc.

### Pattern 5: Validation with Collect-All-Errors
**What:** Run all validations before failing, collecting errors by file
**When to use:** List posts command (show all invalid posts with reasons)
**Example:**
```bash
# Source: established in publish.sh lines 327-387
declare -A VALIDATION_ERRORS

for post in "${POST_FILES[@]}"; do
    errors=$(validate_frontmatter "$post")
    if [[ -n "$errors" ]]; then
        VALIDATION_ERRORS["$post"]="$errors"
    fi
done

# Display all errors grouped by file
for post in "${!VALIDATION_ERRORS[@]}"; do
    echo -e "${YELLOW}$(basename "$post"):${RESET}"
    echo "${VALIDATION_ERRORS[$post]}" | while read -r err; do
        echo -e "  ${RED}- $err${RESET}"
    done
done
```
**Notes:**
- Associative array maps file → error messages
- Allows showing all problems at once (not fail-fast)
- User can fix multiple issues before retry

### Pattern 6: Exit Code Conventions
**What:** Standard exit codes signal different failure types
**When to use:** All scripts (enables automation and error handling)
**Example:**
```bash
# Source: https://www.baeldung.com/linux/status-codes
EXIT_SUCCESS=0      # Operation completed successfully
EXIT_ERROR=1        # General error (validation failed, git operation failed)
EXIT_BLOCKED=2      # Blocked by hook/check (distinct from general error)
EXIT_CANCELLED=130  # User cancelled (Ctrl-C or explicit cancel at prompt)

# Usage
if [[ ${#valid_posts[@]} -eq 0 ]]; then
    echo -e "${RED}No valid posts found${RESET}"
    exit $EXIT_ERROR
fi
```
**Notes:**
- 0 = success (always)
- 1 = general error (catch-all)
- 2 = misuse/blocked (matches shell builtin convention)
- 130 = SIGINT (128 + 2, user interrupt)
- Avoid 126-165 (reserved for signals)

### Anti-Patterns to Avoid
- **Don't calculate ANSI width manually** - ANSI escape codes don't contribute to visible character width, but bash printf still counts them. Apply colors *around* format strings, not within them.
- **Don't use `git status` for state comparison** - `git status` shows working tree changes. Use `git ls-files` to list tracked files in the repository.
- **Don't use `rsync` for blog sync** - Git already tracks file state. Rsync adds complexity without benefit since we're comparing version-controlled content.
- **Don't parse `git log` output** - Use porcelain flags (`--name-only`, `--pretty="format:"`) instead of parsing formatted output.

## Don't Hand-Roll

Problems that look simple but have existing solutions:

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| Table column alignment | String padding loops | `printf "%-20s %10s"` | Printf handles padding/alignment natively |
| Date range filtering | Parse dates in bash | `git log --since="30 days ago"` | Git understands relative dates |
| Array difference | Nested loops | `comm -23 <(printf "%s\n" "${a[@]}" \| sort)` | `comm` is designed for set operations |
| Listing tracked files | `find` with git checks | `git ls-files` | Git knows what's tracked |
| File removal detection | Scan directory diffs | `git log --diff-filter=D` | Git tracks all changes |
| Interactive selection | Custom menu code | gum/fzf fallback chain | Established pattern in publish.sh |

**Key insight:** Git is a database of file state changes. Query it directly instead of reimplementing diff logic. Bash printf handles formatting - don't parse/pad strings manually.

## Common Pitfalls

### Pitfall 1: ANSI Escape Codes Affect String Length Calculations
**What goes wrong:** Table columns misalign when ANSI codes are embedded in formatted strings
**Why it happens:** `${#string}` counts escape code characters, but terminal doesn't display them
**How to avoid:** Apply color codes outside printf format strings
**Warning signs:** Columns align correctly without colors, break when colors added

**Bad:**
```bash
# Color codes mess up width calculation
colored_text="${RED}Error${RESET}"
printf "%-20s\n" "$colored_text"  # Doesn't align (counts escape chars)
```

**Good:**
```bash
# Format first, colorize after
printf "${RED}%-20s${RESET}\n" "Error"  # Aligns correctly
```

### Pitfall 2: Not Handling Missing Fields in Frontmatter
**What goes wrong:** List-posts shows broken output when pubDatetime or title is missing
**Why it happens:** Extract functions return empty strings, which break table formatting
**How to avoid:** Use fallback values for display (e.g., "(no date)", "(untitled)")
**Warning signs:** Table rows with gaps or truncated columns

**Solution:**
```bash
# Source: established in publish.sh lines 540-543
display_date="${pub_date:0:10}"
if [[ -z "$display_date" || "$display_date" == "null" ]]; then
    display_date="(no date)"
fi
```

### Pitfall 3: Git Diff-Filter on Untracked Files
**What goes wrong:** `git log --diff-filter=D` misses files that were never committed
**Why it happens:** Diff-filter operates on commit history, not working tree
**How to avoid:** Only use for detecting *committed-then-removed* files (which is correct for unpublish safety check)
**Warning signs:** Hook doesn't detect recently unpublished posts

**Correct usage:**
```bash
# This finds files that WERE in repo and got deleted (correct for hook)
git log --since="30 days ago" --diff-filter=D --name-only -- "src/content/blog/**/*.md"

# This would NOT find files that were unpublished but never pushed
# (Which is fine - the hook warns about repo state, not local changes)
```

### Pitfall 4: Array Iteration Order Not Guaranteed
**What goes wrong:** Posts displayed in random order instead of newest-first
**Why it happens:** Bash associative arrays don't preserve insertion order
**How to avoid:** Sort arrays before display (by date or status, as needed)
**Warning signs:** List order changes between runs

**Solution:**
```bash
# Source: established in publish.sh lines 559-592
# Create date|index pairs, sort, reorder arrays
for i in "${!POST_DATES[@]}"; do
    date_index_pairs+=("${POST_DATES[$i]}|$i")
done

mapfile -t sorted_pairs < <(printf '%s\n' "${date_index_pairs[@]}" | sort -t'|' -k1 -r)
```

### Pitfall 5: Astro Dev Server Background vs Foreground
**What goes wrong:** `npm run dev &` runs in background but dies when terminal closes
**Why it happens:** Background processes receive SIGHUP on terminal exit unless disowned
**How to avoid:** Run in foreground for interactive use (standard dev workflow), or use tmux/screen for persistence
**Warning signs:** Dev server stops when terminal closes

**Recommendation:**
```bash
# For just preview: run in foreground (standard behavior)
npm run dev

# NOT this (adds complexity, unexpected for dev command)
nohup npm run dev &
disown
```

## Code Examples

Verified patterns from official sources and established codebase:

### List Posts with Colored Status
```bash
# Format: Title (40 chars) | Date (12 chars) | Status (10 chars)
printf "${CYAN}%-40s %-12s %-10s${RESET}\n" "TITLE" "DATE" "STATUS"
printf "%s\n" "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

for i in "${!POST_TITLES[@]}"; do
    local title="${POST_TITLES[$i]}"
    local date="${POST_DATES[$i]:0:10}"
    local status="Ready"
    local color="${GREEN}"

    # Truncate title to 40 chars
    [[ ${#title} -gt 40 ]] && title="${title:0:37}..."

    # Check if invalid
    if [[ -n "${VALIDATION_ERRORS[$file]}" ]]; then
        status="Invalid"
        color="${RED}"
    fi

    printf "%-40s %-12s ${color}%-10s${RESET}\n" "$title" "$date" "$status"
done
```

### Sync Operation (Detect Removals)
```bash
# Get current blog state
blog_posts=($(git ls-files "src/content/blog/**/*.md"))

# Extract slugs from paths (year/slug.md -> slug)
blog_slugs=()
for path in "${blog_posts[@]}"; do
    slug=$(basename "$path" .md)
    blog_slugs+=("$slug")
done

# Get Obsidian state (posts with Published status)
# discover_posts() already populates POST_FILES array
obsidian_slugs=()
for file in "${POST_FILES[@]}"; do
    slug=$(slugify "$(basename "$file")")
    obsidian_slugs+=("$slug")
done

# Find removals (in blog but not in Obsidian)
removals=()
for blog_slug in "${blog_slugs[@]}"; do
    found=false
    for obs_slug in "${obsidian_slugs[@]}"; do
        [[ "$blog_slug" == "$obs_slug" ]] && found=true && break
    done
    [[ "$found" == "false" ]] && removals+=("$blog_slug")
done

# Process removals
for slug in "${removals[@]}"; do
    echo -e "${YELLOW}Removing:${RESET} $slug (no longer Published in Obsidian)"
    # Remove from git...
done
```

### Pre-Publish Hook (Check Recently Removed)
```bash
# Check if any selected posts were recently removed from blog
check_recently_removed() {
    # Find files deleted in last 30 days
    local recently_removed
    recently_removed=$(git log --since="30 days ago" --diff-filter=D --name-only --pretty="format:" -- "src/content/blog/**/*.md" | sed '/^$/d')

    if [[ -z "$recently_removed" ]]; then
        return 0  # No recent removals
    fi

    # Check if any selected posts match recently removed
    local warnings=()
    for file in "${SELECTED_FILES[@]}"; do
        local slug=$(slugify "$(basename "$file")")

        # Check against recently removed
        for removed_path in $recently_removed; do
            removed_slug=$(basename "$removed_path" .md)
            if [[ "$slug" == "$removed_slug" ]]; then
                warnings+=("$slug was unpublished in the last 30 days")
            fi
        done
    done

    if [[ ${#warnings[@]} -gt 0 ]]; then
        echo ""
        echo -e "${YELLOW}Warning: Re-publishing recently removed posts${RESET}"
        for warning in "${warnings[@]}"; do
            echo -e "  ${YELLOW}- $warning${RESET}"
        done

        read -rp "Continue anyway? [y/N] " response
        if [[ ! "$response" =~ ^[Yy] ]]; then
            exit $EXIT_BLOCKED
        fi
    fi
}
```

### Unpublish with Confirmation
```bash
# Unpublish a specific post
unpublish_post() {
    local file="$1"
    local force="${2:-false}"

    # Extract metadata
    local slug=$(slugify "$(basename "$file")")
    local title=$(extract_frontmatter_value "$file" "title")
    local pub_date=$(extract_frontmatter_value "$file" "pubDatetime")
    local year="${pub_date:0:4}"

    local blog_path="${BLOG_DIR}/${year}/${slug}.md"

    # Check if exists
    if [[ ! -f "$blog_path" ]]; then
        echo -e "${RED}Error: Post not found in blog repo${RESET}"
        echo -e "  Expected: $blog_path"
        exit $EXIT_ERROR
    fi

    # Confirm unless --force
    if [[ "$force" != "true" ]]; then
        echo ""
        echo -e "${YELLOW}Remove from blog:${RESET} $title"
        echo -e "  Path: $blog_path"
        echo ""
        read -rp "Confirm removal? [y/N] " response

        if [[ ! "$response" =~ ^[Yy] ]]; then
            echo -e "${YELLOW}Cancelled${RESET}"
            exit $EXIT_SUCCESS
        fi
    fi

    # Remove file
    git rm "$blog_path"

    # Commit (but don't push - checkpoint)
    git commit -m "docs(blog): unpublish $title"

    echo ""
    echo -e "${GREEN}Post removed from blog${RESET}"
    echo -e "${YELLOW}Note: Update status in Obsidian to prevent re-publishing${RESET}"
}
```

### Astro Dev Server (Simple Passthrough)
```bash
# Just preview - run Astro dev server
# Source: https://docs.astro.build/en/reference/cli-reference/
preview() {
    echo ""
    echo -e "${CYAN}Starting Astro dev server...${RESET}"
    echo -e "  URL: ${GREEN}http://localhost:4321${RESET}"
    echo ""
    echo -e "${YELLOW}Press Ctrl+C to stop${RESET}"
    echo ""

    # Run in foreground (standard dev server behavior)
    npm run dev
}
```

## State of the Art

| Old Approach | Current Approach | When Changed | Impact |
|--------------|------------------|--------------|--------|
| Publish = add new posts | Publish = sync operation | Phase 9 (2026-01) | Blog converges to Obsidian state (removals automated) |
| Manual unpublish (delete + git) | `just unpublish` with hooks | Phase 9 (2026-01) | Safety checks prevent accidental re-publishing |
| List drafts only | List posts with filters | Phase 9 (2026-01) | Scales better as post count grows |
| Fail-fast validation | Collect-all-errors | Phase 8 (2026-01) | Show all problems at once |

**Deprecated/outdated:**
- N/A (Phase 9 builds on Phase 8, no deprecations)

## Open Questions

Things that couldn't be fully resolved:

1. **Recently-removed time window**
   - What we know: `git log --since` accepts relative dates ("30 days ago", "1 month ago")
   - What's unclear: Optimal window for "recently removed" detection (30 days vs 20 commits vs other)
   - Recommendation: Start with 30 days (aligns with monthly publishing cadence), make configurable if needed

2. **Table column widths**
   - What we know: Printf supports fixed widths (`%-40s`), truncation needed for long titles
   - What's unclear: Exact widths for optimal readability (40 chars for title? 50?)
   - Recommendation: Use 40 (title) / 12 (date) / 10 (status) - matches visual style in publish.sh

3. **Foreground vs background for preview**
   - What we know: Foreground is standard for dev servers, background requires process management
   - What's unclear: User preference for this specific project
   - Recommendation: Foreground (matches standard `npm run dev` behavior, keeps it simple)

## Sources

### Primary (HIGH confidence)
- [Astro CLI Reference](https://docs.astro.build/en/reference/cli-reference/) - Official docs for dev server command, port, flags
- publish.sh (lines 1-1174) - Established patterns for colors, validation, git operations
- package.json (lines 5-9) - Actual npm scripts and dev command
- [Git ls-files Documentation](https://git-scm.com/docs/git-ls-files) - Official reference for listing tracked files

### Secondary (MEDIUM confidence)
- [Bash ANSI Color Codes](https://misc.flogisoft.com/bash/tip_colors_and_formatting) - Color code reference
- [Standard Exit Status Codes in Linux](https://www.baeldung.com/linux/status-codes) - Exit code conventions
- [How to Find a Deleted File in Git](https://betterstack.com/community/questions/how-to-find-deleted-file-in-project-commit-history/) - Git log diff-filter patterns
- [Bash Yes/No Prompt Examples](https://linuxconfig.org/bash-script-yes-no-prompt-example) - Interactive confirmation patterns
- [Git Log with Date Range](https://labex.io/tutorials/git-how-to-use-git-log-command-with-date-range-options-414998) - Relative date syntax

### Tertiary (LOW confidence)
- [Bash Printf Table Formatting](https://linuxvox.com/blog/bash-printf-command/) - General printf examples (verified against established patterns)
- [Bash Array Comparison](https://fabianlee.org/2020/09/06/bash-difference-between-two-arrays/) - Array diff patterns (supplemental to git approach)

## Metadata

**Confidence breakdown:**
- Standard stack: HIGH - All tools already in use (bash, git, npm, perl, jq)
- Architecture: HIGH - Patterns verified in existing publish.sh, official Astro docs
- Pitfalls: HIGH - Based on established code patterns and official documentation
- Code examples: HIGH - Derived from existing codebase and official sources

**Research date:** 2026-01-31
**Valid until:** 2026-03-31 (60 days - stable bash/git tooling, Astro stable)
