# Project Research Summary

**Project:** v0.4.0 Obsidian + Blog Integration Refactor
**Domain:** Bash script refactoring, blog publishing workflow, two-way sync
**Researched:** 2026-02-01
**Confidence:** HIGH

## Executive Summary

This refactoring milestone addresses technical debt in the blog publishing workflow. The current scripts have ~280 lines of duplicated code across three files, use fragile sed/perl chains for YAML manipulation, and lack two-way sync between Obsidian and the blog. The research shows a clear path forward: adopt **yq (mikefarah/yq v4)** for YAML manipulation, consolidate duplicated code into a single shared library (`scripts/lib/common.sh`), and implement bidirectional metadata sync using `draft: true/false` as the source of truth.

The recommended approach stays bash-only. Adding Python would create unnecessary complexity for what are fundamentally simple file operations with YAML parsing. yq provides the YAML reliability needed (proper boolean handling, frontmatter-aware processing, cross-platform consistency) without leaving bash. For code organization, a single shared library is appropriate for this codebase size - three scripts sharing ~150 lines of common functions doesn't justify multiple library files.

The key risks are YAML corruption via regex manipulation and data loss during two-way sync. These are mitigated by: (1) using yq instead of sed/perl for all YAML modifications, (2) implementing atomic writes with backup before modifying Obsidian source files, and (3) phased schema migration from `status: Published` to `draft: false` with backward compatibility during transition. The refactoring should proceed incrementally: library extraction first, then YAML tooling replacement, then two-way sync features.

## Key Findings

### Recommended Stack

The current scripts use fragile sed/grep/perl chains for YAML frontmatter manipulation. This breaks on edge cases (quoted values, multiline fields, YAML arrays) and creates cross-platform issues (BSD vs GNU sed). The solution is **yq (mikefarah/yq v4)**, a YAML-aware processor with dedicated frontmatter support.

**Core technologies:**
- **yq v4 (mikefarah)**: YAML frontmatter manipulation - Provides `--front-matter=extract` and `--front-matter=process` flags for markdown files, handles boolean values correctly (YAML 1.2 spec), cross-platform consistent behavior
- **Bash shared library pattern**: Code deduplication - Single `scripts/lib/common.sh` file consolidates ~280 lines of duplicated functions, sourced pattern with double-source guard, appropriate for 3-4 consuming scripts
- **Atomic write pattern**: Safe file modifications - Write to temp file then `mv` to target, backup Obsidian files before modification, prevents data loss during two-way sync

**Critical distinction:** The Arch Linux default `yq` (v3.4.3) is kislyuk/yq (Python wrapper around jq) which lacks `--front-matter` support. Must install mikefarah/yq v4 separately.

### Expected Features

Research focused on refactoring behaviors rather than new greenfield features. The workflow already has publishing capabilities; this milestone improves reliability and adds two-way sync.

**Must have (table stakes):**
- **Unpublish updates Obsidian source** - Two-way sync requires both sides stay consistent; without this, manual updates create friction
- **pubDatetime set at publish time** - Publication date should reflect when content went live, not template creation time
- **Reliable YAML manipulation** - Boolean fields, quoted values, arrays must survive round-trip without corruption
- **Atomic operations** - All-or-nothing: copy all files, validate all, commit all

**Should have (competitive):**
- **Dry-run for unpublish** - Matches existing `just publish --dry-run` pattern
- **Preserve pubDatetime on unpublish** - Keeps publication history for potential republish
- **Cross-platform script compatibility** - Works on Linux (dev), macOS (potential contributors), devcontainer

**Defer (v2+):**
- **Batch unpublish** - Single-post unpublish sufficient for personal blog
- **modDatetime tracking** - Nice-to-have for SEO "last updated" display
- **Interactive post selection (fzf/gum)** - Polish feature, not blocking

### Architecture Approach

The current architecture has significant code duplication: ~280 lines duplicated across `publish.sh`, `list-posts.sh`, and `unpublish.sh`. Functions like `slugify()`, `extract_frontmatter()`, `validate_frontmatter()`, and `load_config()` appear in multiple files. The solution is a single shared library with clear component boundaries.

**Major components:**
1. **`scripts/lib/common.sh`** - Shared library containing: colors/exit codes/paths (constants), config loading, frontmatter extraction (using yq), validation functions, slug generation
2. **Script-specific files** - Each script sources `common.sh` and keeps only script-specific logic: `publish.sh` (image handling, rollback, commits), `list-posts.sh` (table formatting, sorting), `unpublish.sh` (removal confirmation)
3. **Two-way sync layer** - Manages bidirectional metadata: publish sets `draft: false` in Obsidian, unpublish sets `draft: true`, preserves `pubDatetime` across operations

**Sourcing pattern:**
```bash
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/lib/common.sh"
```

This pattern works regardless of where scripts are invoked from, handles symlinks correctly, and works in devcontainers.

### Critical Pitfalls

From PITFALLS.md, filtered for refactoring-specific risks:

1. **YAML Corruption via sed/regex** - Using sed or regex to modify YAML frontmatter corrupts whitespace, quoting, or multiline values. YAML is whitespace-significant; naive string manipulation breaks parsing. **Prevention:** Use yq with `--front-matter=process` for all modifications; validate with `yq '.' file.md` after changes.

2. **Data Loss via Two-Way Sync Without Backup** - Modifying Obsidian vault files without backup causes permanent data loss when scripts malfunction. **Prevention:** Atomic write pattern (write to temp, then mv); backup before modification; implement dry-run mode for sync operations.

3. **Cross-Platform sed Incompatibility** - Scripts work on Linux but fail on macOS due to BSD vs GNU sed differences. The `-i` flag requires different syntax. **Prevention:** Use yq instead of sed for YAML (consistent across platforms); or use `sed -i.bak` pattern (works on both).

4. **Schema Migration Breaks Existing Posts** - Migration from `status: Published` to `draft: false` can break existing published posts if edge cases are missed. **Prevention:** Phased migration with overlap period; explicit state mapping (`status: Published` → `draft: false`, `status: Draft` → `draft: true`, missing → `draft: true`); pre-migration audit of all posts.

5. **Shared Library Variable Scope Leakage** - Bash variables are global by default; sourcing library overwrites caller's variables. **Prevention:** Use `local` in all functions; namespace global variables with prefix (`_BLOG_LIB_`); guard against double-sourcing.

## Implications for Roadmap

Based on research, suggested phase structure prioritizes risk reduction and incremental validation:

### Phase 1: Library Extraction + yq Integration
**Rationale:** Deduplicates code before adding complexity; establishes yq patterns before two-way sync depends on them. Low-risk changes that improve maintainability immediately.

**Delivers:**
- `scripts/lib/common.sh` with all duplicated functions
- yq-based frontmatter functions (`fm_get()`, `fm_set()`)
- Platform-aware utility functions
- Reduced codebase from ~2500 lines to ~2320 lines

**Addresses:**
- Must-have: Reliable YAML manipulation
- Architecture: Single shared library pattern
- Pitfall: YAML corruption via sed/regex

**Avoids:**
- Variable scope leakage (guard, locals, readonly)
- Code drift (extract all-or-nothing)
- Cross-platform sed issues (standardize on yq)

### Phase 2: Two-Way Sync Implementation
**Rationale:** Builds on stable library foundation; implements core workflow improvement. Depends on yq being proven in Phase 1.

**Delivers:**
- Unpublish updates Obsidian source (`draft: true`)
- Publish sets `draft: false` in Obsidian
- pubDatetime set at publish time (if not already set)
- Atomic write pattern with backup
- Dry-run mode for unpublish

**Uses:**
- yq for frontmatter modification (from Phase 1)
- Atomic write helpers (from Phase 1)
- Shared validation functions (from Phase 1)

**Implements:**
- Two-way sync layer (architecture component 3)

**Avoids:**
- Data loss (atomic writes, backup before modify)
- Conflict detection gaps (track sync state, compare timestamps)

### Phase 3: Schema Migration (status → draft)
**Rationale:** Deferred until two-way sync is stable; changes source of truth field. Risky migration happens last when tooling is proven.

**Delivers:**
- Migration script: `status: Published` → `draft: false`
- Backward compatibility during transition
- Deprecation of `status` field
- Template updates

**Addresses:**
- Should-have: Standard `draft` field semantics
- Pitfall: Migration breaks existing posts

**Migration strategy:**
- Phase A: Add `draft` alongside `status` (both fields coexist)
- Phase B: Update detection to prefer `draft`, fall back to `status`
- Phase C: Remove `status` field support after verification

### Phase Ordering Rationale

- **Library extraction first:** Eliminates duplication before adding features; yq patterns proven on read operations before write operations depend on them
- **Two-way sync second:** Core workflow improvement; depends on stable library and yq tooling
- **Schema migration last:** Changes source of truth; riskiest operation happens when all tooling is battle-tested
- **Incremental validation:** Each phase produces working state; can pause after any phase without broken workflow

This ordering minimizes risk by:
1. Establishing safe patterns (yq, atomic writes) before using them in critical paths
2. Proving tooling on read operations before write operations
3. Keeping migration separate from feature work
4. Allowing rollback at each phase boundary

### Research Flags

Phases likely needing deeper research during planning:
- **Phase 2 (Two-Way Sync):** Conflict detection strategy needs validation - how to handle Obsidian and blog both modified since last sync? Research didn't fully address this edge case.
- **Phase 3 (Schema Migration):** Data migration testing approach - need strategy for validating migration without risking production posts.

Phases with standard patterns (skip research-phase):
- **Phase 1 (Library Extraction):** Well-documented bash library patterns; yq usage is straightforward from official docs
- **All phases:** Git safety hooks already researched in PITFALLS.md; no new research needed

## Confidence Assessment

| Area | Confidence | Notes |
|------|------------|-------|
| Stack | HIGH | yq official docs verified; `--front-matter` flag confirmed for mikefarah/yq v4; installation paths documented |
| Features | HIGH | Two-way sync patterns from authoritative sources; current workflow analyzed in detail; clear gap identification |
| Architecture | HIGH | Bash library patterns are established practice; component boundaries clear from code analysis; ~280 lines duplication measured |
| Pitfalls | HIGH | Critical pitfalls backed by official docs and known issues; YAML corruption risks well-documented; cross-platform sed issues verified |

**Overall confidence:** HIGH

### Gaps to Address

Research identified these areas needing attention during planning/execution:

- **yq version verification:** Must verify correct yq version (mikefarah v4) during setup; existing Arch installation is kislyuk v3. Add prerequisite check to `scripts/lib/common.sh` or bootstrap script.
- **Conflict detection strategy:** Two-way sync research covered basic cases but not full conflict resolution (both Obsidian and blog modified since last sync). Need to design conflict detection before Phase 2 implementation.
- **Migration testing approach:** Schema migration needs testing strategy that doesn't risk production posts. Consider: test migration script on post copies, dry-run mode, or staging environment.
- **Rollback enhancement:** Current rollback removes created files but doesn't restore git state. Should rollback include `git reset --hard $initial_commit`? Need to define rollback scope.

## Sources

### Primary (HIGH confidence)

**YAML/yq:**
- [yq Front Matter Documentation](https://mikefarah.gitbook.io/yq/usage/front-matter) - Official front-matter handling
- [yq GitHub (mikefarah)](https://github.com/mikefarah/yq) - Installation and usage
- [yq Boolean Operators](https://mikefarah.gitbook.io/yq/operators/boolean-operators) - Boolean handling in YAML 1.2
- [YAML Multiline Strings](https://yaml-multiline.info/) - Whitespace-significant syntax rules

**Bash Libraries:**
- [Designing Modular Bash: Functions, Namespaces, and Library Patterns](https://www.lost-in-it.com/posts/designing-modular-bash-functions-namespaces-library-patterns/)
- [Baeldung: Source Include Files](https://www.baeldung.com/linux/source-include-files)
- [Gabriel Staples: Bash Libraries](https://gabrielstaples.com/bash-libraries/)

**Two-Way Sync Patterns:**
- [Two-Way Sync Demystified: Key Principles And Best Practices](https://www.stacksync.com/blog/two-way-sync-demystified-key-principles-and-best-practices)
- [Atomic File Modifications](https://dev.to/martinhaeusler/towards-atomic-file-modifications-2a9n)

**Publishing Workflows:**
- [Date and Time with a Static Site Generator](https://blog.jim-nielsen.com/2023/date-and-time-in-ssg/) - pubDatetime best practices
- [Publishing from Obsidian](https://cassidoo.co/post/publishing-from-obsidian/) - Obsidian to blog workflow

### Secondary (MEDIUM confidence)

**Cross-Platform Compatibility:**
- [GNU sed vs BSD sed (Baeldung)](https://www.baeldung.com/linux/gnu-bsd-stream-editor)
- [sed in-place portability fix](https://sqlpey.com/bash/sed-in-place-portability-fix/)

**Schema Migration:**
- [Database Schema Migration Best Practices](https://amasucci.com/posts/database-migrations-best-practices/) - Phased migration patterns

**UX Patterns:**
- [Confirmation Dialogs Can Prevent User Errors - NN/g](https://www.nngroup.com/articles/confirmation-dialog/)
- [How To Manage Dangerous Actions](https://www.smashingmagazine.com/2024/09/how-manage-dangerous-actions-user-interfaces/)

### Tertiary (existing codebase analysis)

**Code Analysis:**
- `/home/jc/developer/justcarlson.com/scripts/publish.sh` - Current implementation patterns
- `/home/jc/developer/justcarlson.com/scripts/list-posts.sh` - Validation and frontmatter extraction
- `/home/jc/developer/justcarlson.com/scripts/unpublish.sh` - Post removal logic
- Measured duplication: ~280 lines across 3 scripts

---
*Research completed: 2026-02-01*
*Ready for roadmap: yes*
