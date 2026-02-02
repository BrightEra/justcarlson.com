# Phase 17: Schema Migration - Research

**Researched:** 2026-02-02
**Domain:** YAML frontmatter manipulation, Obsidian templates, bash scripting
**Confidence:** HIGH

## Summary

This phase migrates the publish state schema from `status: Published` to `draft: true/false` as the single source of truth. The migration involves:

1. **Migration script** - A standalone bash script that transforms existing vault posts
2. **Template update** - Modify the Obsidian Post Template to use the new schema
3. **Obsidian configuration** - Update types.json and Base views for the draft field
4. **Astro schema cleanup** - Remove deprecated fields from content.config.ts

The codebase already uses mikefarah/yq for frontmatter manipulation with the `--front-matter=process` flag, establishing patterns that the migration script should follow. The primary technical challenge is ensuring idempotent, safe transformations with proper backup and verification.

**Primary recommendation:** Use the existing yq infrastructure in common.sh for all frontmatter manipulation, following the established `--front-matter=process -i` pattern with `.bak` backups.

## Standard Stack

The established tools for this domain:

### Core
| Tool | Version | Purpose | Why Standard |
|------|---------|---------|--------------|
| go-yq (mikefarah/yq) | 4.x | YAML frontmatter manipulation | Already in use in common.sh, supports --front-matter flag |
| bash | 5.x | Script execution | Standard shell, set -euo pipefail pattern established |
| date (GNU coreutils) | 9.x | ISO 8601 datetime formatting | Available on Linux, -r flag for file mtime |

### Supporting
| Tool | Purpose | When to Use |
|------|---------|-------------|
| perl | Pattern matching for post discovery | Already used in publish.sh for draft: false detection |
| find | File discovery | Already used for vault traversal |
| jq | JSON config reading | Already used for settings.local.json |

### Alternatives Considered
| Instead of | Could Use | Tradeoff |
|------------|-----------|----------|
| yq | sed/awk | Less reliable for YAML, doesn't preserve formatting |
| date -r | stat | stat syntax differs between Linux/BSD, date -r is more portable |

**No installation required:** All tools already available in the project environment.

## Architecture Patterns

### Recommended Migration Script Structure
```
scripts/
└── migrate-schema.sh     # Standalone migration script (not in justfile)
```

### Pattern 1: Safe Frontmatter Modification
**What:** Backup-then-modify pattern with verification
**When to use:** Any frontmatter modification
**Example:**
```bash
# Source: Established pattern in common.sh update_obsidian_source()
local yq_cmd
yq_cmd=$(_get_yq_cmd)

# Create backup before modification
cp "$file" "${file}.bak"

# Modify frontmatter in-place
"$yq_cmd" --front-matter=process -i 'expression' "$file"

# Verify modification
if ! verify_modification "$file"; then
    # Restore from backup on failure
    mv "${file}.bak" "$file"
    return 1
fi
```

### Pattern 2: Post Discovery by Category (Kepano Ontology)
**What:** Find posts by `categories: - "[[Posts]]"` pattern
**When to use:** Migration discovery (not by status field)
**Example:**
```bash
# Source: CONTEXT.md decision - discover by categories, not status
while IFS= read -r -d '' file; do
    # Check if file contains categories with [[Posts]] wikilink
    if grep -q 'categories:' "$file" && grep -q '\[\[Posts\]\]' "$file"; then
        # This is a post
        process_file "$file"
    fi
done < <(find "$VAULT_PATH" -name "*.md" -type f -print0 2>/dev/null)
```

### Pattern 3: yq Field Operations
**What:** Standard expressions for adding, modifying, and deleting frontmatter fields
**When to use:** All frontmatter transformations
**Example:**
```bash
# Source: mikefarah.gitbook.io/yq/operators/delete

# Delete a field
yq --front-matter=process -i 'del(.status)' "$file"

# Add/set a field (with shell variable)
export VALUE="somevalue"
yq --front-matter=process -i '.fieldname = strenv(VALUE)' "$file"

# Conditional modification
yq --front-matter=process -i 'select(.status == ["Published"]) | .draft = false' "$file"
```

### Anti-Patterns to Avoid
- **Direct sed on YAML:** Can corrupt multi-line values, doesn't understand YAML structure
- **Modifying without backup:** No recovery path if script fails
- **Processing content/blog copies:** Only migrate vault source files; blog copies updated via normal publish workflow

## Don't Hand-Roll

Problems that look simple but have existing solutions:

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| YAML parsing | Custom regex | yq --front-matter | Edge cases: multi-line values, escaping, comments |
| ISO 8601 datetime | String concatenation | date -Iseconds | Handles timezone offset correctly |
| File modification time | stat (inconsistent) | date -r file -Iseconds | Portable across Linux variants |
| Frontmatter field extraction | grep/sed | get_frontmatter_field() from common.sh | Already handles quotes, colons, missing fields |

**Key insight:** The codebase already has yq infrastructure and helper functions. Use them rather than building parallel implementations.

## Common Pitfalls

### Pitfall 1: yq Array vs String Field Types
**What goes wrong:** yq treats `status: Published` differently from `status: - Published`
**Why it happens:** Kepano ontology uses array format for status: `status:\n  - Published`
**How to avoid:** Use array-aware expressions
```bash
# Wrong - assumes string
yq '.status == "Published"'

# Right - handles array
yq '.status | select(. != null) | contains(["Published"])'
```
**Warning signs:** Migration succeeds but wrong posts selected

### Pitfall 2: Empty vs Missing Fields
**What goes wrong:** `pubDatetime:` (empty) vs missing field treated differently
**Why it happens:** yq returns empty string for both, but they're semantically different
**How to avoid:** Check for null explicitly
```bash
# Check if field exists and has value
yq --front-matter=extract '.pubDatetime | select(. != null and . != "")' "$file"
```
**Warning signs:** Posts with empty pubDatetime get wrong backfill date

### Pitfall 3: Dry-Run Doesn't Test Verification
**What goes wrong:** --dry-run passes but actual migration fails verification
**Why it happens:** Dry-run shows what would change, doesn't execute re-read verification
**How to avoid:** Dry-run should simulate the full flow including verification logic
**Warning signs:** Script works in dry-run, fails in actual execution

### Pitfall 4: Non-Idempotent Transformations
**What goes wrong:** Running migration twice corrupts data
**Why it happens:** Transformation assumes pre-migration state
**How to avoid:** Check current state before transforming
```bash
# Idempotent: only add draft if missing
if ! yq --front-matter=extract 'has("draft")' "$file" | grep -q true; then
    yq --front-matter=process -i '.draft = true' "$file"
fi
```
**Warning signs:** Second run produces different results than first

### Pitfall 5: Obsidian types.json Boolean Syntax
**What goes wrong:** draft field doesn't render as checkbox in Obsidian
**Why it happens:** types.json expects `"draft": "checkbox"` not `"draft": "boolean"`
**How to avoid:** Use Obsidian's property type names
```json
{
  "types": {
    "draft": "checkbox"
  }
}
```
**Warning signs:** draft shows as text field instead of checkbox

## Code Examples

Verified patterns from existing codebase and official sources:

### Delete Fields from Frontmatter
```bash
# Source: mikefarah.gitbook.io/yq/operators/delete + existing common.sh patterns
local yq_cmd
yq_cmd=$(_get_yq_cmd)

# Delete status field
"$yq_cmd" --front-matter=process -i 'del(.status)' "$file"

# Delete published field (if exists)
"$yq_cmd" --front-matter=process -i 'del(.published)' "$file"
```

### Set Draft Based on Status
```bash
# Source: Common.sh strenv pattern + yq documentation
local yq_cmd
yq_cmd=$(_get_yq_cmd)

# Check if status contains "Published"
local status
status=$("$yq_cmd" --front-matter=extract '.status // []' "$file")

if echo "$status" | grep -q "Published"; then
    "$yq_cmd" --front-matter=process -i '.draft = false' "$file"
else
    "$yq_cmd" --front-matter=process -i '.draft = true' "$file"
fi
```

### Backfill pubDatetime from File mtime
```bash
# Source: GNU coreutils date documentation
# Get file modification time as ISO 8601
local mtime
mtime=$(date -r "$file" -Iseconds)

# Set pubDatetime if missing/empty
export MTIME="$mtime"
"$yq_cmd" --front-matter=process -i \
    'select(.pubDatetime == null or .pubDatetime == "") | .pubDatetime = strenv(MTIME)' \
    "$file"
unset MTIME
```

### Obsidian Template with Templater Syntax
```yaml
# Source: silentvoid13.github.io/Templater + CONTEXT.md field order decision
---
title: <% tp.file.title %>
description: ""
draft: true
created: <% tp.date.now("YYYY-MM-DD") %>
pubDatetime:
tags: []
heroImage:
categories:
  - "[[Posts]]"
author:
  - "[[Me]]"
url:
topics: []
---

[Your content here]
```

### Obsidian Base View Filter for Draft
```yaml
# Source: help.obsidian.md/bases/syntax + blog.optional.page/misc/bases
views:
  - type: table
    name: All Posts
    filters:
      and:
        - list(categories).contains(link("Posts"))
        - '!file.name.contains("Template")'
    order:
      - file.name
      - draft
      - created
      - pubDatetime
    sort:
      - property: created
        direction: DESC
```

### Obsidian types.json for Draft Field
```json
{
  "types": {
    "draft": "checkbox",
    "created": "date",
    "pubDatetime": "datetime"
  }
}
```

## State of the Art

| Old Approach | Current Approach | When Changed | Impact |
|--------------|------------------|--------------|--------|
| `status: Published` | `draft: false` | Phase 16/17 | Single source of truth, boolean instead of string |
| `published:` field | `pubDatetime:` | Phase 17 | Consistent naming with Astro schema |
| Multi-value status | Boolean draft | Phase 17 | Simpler filtering, checkbox in Obsidian |

**Deprecated/outdated:**
- `status` field: Replaced by `draft` boolean, to be removed
- `published` field: Redundant with `pubDatetime`, to be removed

## Open Questions

Things that couldn't be fully resolved:

1. **Obsidian Base view styling for draft indicator**
   - What we know: Can filter by `draft == true/false`, can show in column
   - What's unclear: Best visual indicator (icon, text, color)
   - Recommendation: Use default display, Claude's discretion per CONTEXT.md

2. **yq behavior with YAML arrays containing wikilinks**
   - What we know: `status: - "[[Draft]]"` may have quoting issues
   - What's unclear: Whether yq preserves exact formatting
   - Recommendation: Test with actual vault files before batch migration

## Sources

### Primary (HIGH confidence)
- Existing codebase: `/home/jc/developer/justcarlson.com/scripts/lib/common.sh` - established yq patterns
- [mikefarah/yq Front Matter](https://mikefarah.gitbook.io/yq/usage/front-matter) - --front-matter flag options
- [yq Delete Operator](https://mikefarah.gitbook.io/yq/operators/delete) - del() syntax

### Secondary (MEDIUM confidence)
- [Templater Date Module](https://silentvoid13.github.io/Templater/internal-functions/internal-modules/date-module.html) - tp.date.now() syntax
- [Obsidian Bases Tips](https://blog.optional.page/misc/bases/) - filter syntax examples
- Existing vault: `/home/jc/notes/personal-vault/.obsidian/types.json` - current property types

### Tertiary (LOW confidence)
- WebSearch results for Obsidian Bases boolean filtering - confirmed with official docs

## Metadata

**Confidence breakdown:**
- Standard stack: HIGH - using existing codebase tools and patterns
- Architecture: HIGH - following established patterns in common.sh
- Pitfalls: HIGH - verified against yq documentation and codebase

**Research date:** 2026-02-02
**Valid until:** 2026-03-02 (30 days - stable domain, no rapid changes expected)
