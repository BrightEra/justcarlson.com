---
phase: 16-two-way-sync
verified: 2026-02-01T20:31:31-05:00
status: passed
score: 6/6 must-haves verified
re_verification:
  previous_status: passed
  previous_score: 5/5
  previous_date: 2026-02-01T20:15:00Z
  gaps_closed:
    - "Discovery uses draft: false instead of status: Published (16-04 gap closure)"
  gaps_remaining: []
  regressions: []
  new_must_haves:
    - "publish.sh discovers posts with draft: false (not status: Published)"
    - "list-posts.sh discovers posts with draft: false (not status: Published)"
---

# Phase 16: Two-Way Sync Verification Report

**Phase Goal:** Bidirectional metadata sync keeps Obsidian source and blog copy consistent
**Verified:** 2026-02-01T20:31:31-05:00
**Status:** PASSED
**Re-verification:** Yes — after gap closure (16-04)

## Goal Achievement

### Observable Truths

| # | Truth | Status | Evidence |
|---|-------|--------|----------|
| 1 | Running `just publish` on a post sets `draft: false` and `pubDatetime` in the Obsidian source file | ✓ VERIFIED | `update_obsidian_source` called with "publish" action in publish.sh:855, sets both fields using yq (common.sh:280-281). NO REGRESSION from previous verification. |
| 2 | Running `just unpublish` on a post sets `draft: true` in the Obsidian source file | ✓ VERIFIED | `update_obsidian_source` called with "unpublish" action in unpublish.sh:268, sets draft=true using yq (common.sh:299). NO REGRESSION from previous verification. |
| 3 | A `.bak` file is created before any Obsidian file modification | ✓ VERIFIED | Backup created in both publish and unpublish paths (common.sh:275, 295) with `cp "$obsidian_file" "${obsidian_file}.bak"`. NO REGRESSION from previous verification. |
| 4 | Running `just unpublish --dry-run` shows what would change without modifying any files | ✓ VERIFIED | DRY_RUN flag implemented (unpublish.sh:12,51), passed to update_obsidian_source (unpublish.sh:268), handled in both remove_post (unpublish.sh:182-184) and update_obsidian_source (common.sh:268-272, 289-292). NO REGRESSION from previous verification. |
| 5 | Author field in published posts uses value from settings.local.json, not hardcoded string | ✓ VERIFIED | `get_author_from_config` called in normalize_frontmatter (publish.sh:268), reads from config with fallback to "Justin Carlson" only when config empty (publish.sh:269-271). NO REGRESSION from previous verification. |
| 6 | publish.sh discovers posts with draft: false (not status: Published) | ✓ VERIFIED (NEW) | discover_posts() uses perl regex `draft:\s*false` (publish.sh:427), called at line 1055. User instructions reference "draft: false" (line 1061-1062). NO references to "status: Published" in discovery logic. |
| 7 | list-posts.sh discovers posts with draft: false (not status: Published) | ✓ VERIFIED (NEW) | Discovery uses perl regex `draft:\s*false` (list-posts.sh:165). User instructions reference "draft: false" (line 174). NO references to "status: Published" in discovery logic. |

**Score:** 7/7 truths verified (5 original + 2 from gap closure)

### Required Artifacts

| Artifact | Expected | Status | Details |
|----------|----------|--------|---------|
| `scripts/lib/common.sh` | update_obsidian_source and get_author_from_config functions | ✓ VERIFIED | Both functions exist (lines 237-244, 246-304), substantive implementation (68 lines for update_obsidian_source), exported via source pattern. NO CHANGES since previous verification. |
| `scripts/publish.sh` | Two-way sync integration with config-driven author AND draft: false discovery | ✓ VERIFIED | Calls update_obsidian_source after copy_post (line 855), uses get_author_from_config (line 268), passes DRY_RUN flag. **NEW:** discover_posts() uses draft: false pattern (line 427), user instructions updated (line 1061-1062). |
| `scripts/unpublish.sh` | --dry-run flag and Obsidian source sync | ✓ VERIFIED | DRY_RUN variable (line 12), flag parsing (line 50-52), find_obsidian_source function (lines 205-237), update_obsidian_source call (line 268). NO CHANGES since previous verification. |
| `scripts/list-posts.sh` | draft: false discovery pattern | ✓ VERIFIED (NEW) | Discovery uses draft: false pattern (line 165), user instructions updated (line 174). NO references to "status: Published" remain. |

### Key Link Verification

| From | To | Via | Status | Details |
|------|----|----|--------|---------|
| publish.sh | common.sh (update_obsidian_source) | Function call after copy_post | ✓ WIRED | Line 855: `update_obsidian_source "$file" "publish" "$DRY_RUN"` - called after successful copy, passes file path and dry-run mode. NO REGRESSION. |
| publish.sh | common.sh (get_author_from_config) | Function call in normalize_frontmatter | ✓ WIRED | Line 268: `author=$(get_author_from_config)` with fallback check on 269-271. NO REGRESSION. |
| unpublish.sh | common.sh (update_obsidian_source) | Function call after find_obsidian_source | ✓ WIRED | Line 268: `update_obsidian_source "$obsidian_source" "unpublish" "$DRY_RUN"` - called after finding source file. NO REGRESSION. |
| unpublish.sh | common.sh (find_obsidian_source) | Custom vault search function | ✓ WIRED | Lines 205-237: function searches vault by slug, line 263 calls it, result used to conditionally sync (line 265). NO REGRESSION. |
| common.sh (update_obsidian_source) | yq | yq --front-matter=process -i for YAML modification | ✓ WIRED | Lines 280-281 (publish action), 299 (unpublish action) - uses yq with strenv pattern for datetime interpolation. NO REGRESSION. |
| common.sh (get_author_from_config) | settings.local.json | jq read of author field | ✓ WIRED | Line 243: `jq -r '.author // empty' "$CONFIG_FILE"` - returns empty if not set, caller handles fallback. NO REGRESSION. |
| publish.sh (discover_posts) | Obsidian frontmatter | perl regex matching draft: false | ✓ WIRED (NEW) | Line 427: `perl -0777 -ne 'exit(!/draft:\s*false/i)' "$file"` - case-insensitive pattern match, called at line 1055 in main flow. |
| list-posts.sh | Obsidian frontmatter | perl regex matching draft: false | ✓ WIRED (NEW) | Line 165: `perl -0777 -ne 'exit(!/draft:\s*false/i)' "$file"` - matches publish.sh pattern for consistency. |

### Requirements Coverage

| Requirement | Status | Evidence |
|-------------|--------|----------|
| SYNC-01: `just unpublish` sets `draft: true` in Obsidian source file | ✓ SATISFIED | Truth 2 verified - update_obsidian_source with "unpublish" action sets draft=true |
| SYNC-02: `just publish` sets `pubDatetime` at publish time | ✓ SATISFIED | Truth 1 verified - update_obsidian_source with "publish" action sets pubDatetime using date -Iseconds (common.sh:266) |
| SYNC-03: `just publish` sets `draft: false` in Obsidian source file | ✓ SATISFIED | Truth 1 verified - update_obsidian_source with "publish" action sets draft=false (common.sh:281) |
| SYNC-04: Backup created before modifying Obsidian files | ✓ SATISFIED | Truth 3 verified - .bak file created in both publish and unpublish flows before any yq modification |
| SYNC-05: `just unpublish --dry-run` previews changes without modifying files | ✓ SATISFIED | Truth 4 verified - DRY_RUN flag implemented, preview messages shown, no file modifications when dry_run=true |
| CONF-01: Author normalization uses config value (not hardcoded string) | ✓ SATISFIED | Truth 5 verified - get_author_from_config reads from settings.local.json, fallback only when config empty |

**Coverage:** 6/6 requirements satisfied

**Gap Closure (16-04) Requirements:**
- Discovery pattern aligned with two-way sync schema (draft: false replaces status: Published)
- User instructions updated to reference correct field
- Consistency across publish.sh and list-posts.sh

### Anti-Patterns Found

| File | Line | Pattern | Severity | Impact |
|------|------|---------|----------|--------|
| - | - | - | - | No anti-patterns detected |

**Anti-pattern scan results:**
- No TODO/FIXME/XXX/HACK comments in modified files
- No placeholder content ("coming soon", "will be", "not implemented")
- No empty implementations
- No console.log-only stubs
- No references to old "status: Published" pattern in discovery logic

All implementations are substantive with proper error handling.

### Human Verification Required

Optional manual testing for end-to-end confidence:

#### 1. Test publish discovery with draft: false

**Test:** Create test post in Obsidian vault with `draft: false` frontmatter, run `just publish --dry-run`
**Expected:** Post discovered and shown in publish menu, shows "[DRY-RUN]" messages
**Why human:** Validates end-to-end discovery flow with real vault file

#### 2. Test publish two-way sync

**Test:** Create test post in Obsidian vault with `draft: false`, run `just publish test-post`, check vault file
**Expected:** Obsidian source file has `draft: false` and `pubDatetime` set, .bak file exists
**Why human:** Validates end-to-end behavior with real filesystem operations

#### 3. Test unpublish two-way sync

**Test:** Publish a post, then run `just unpublish test-post`, check vault file
**Expected:** Obsidian source file has `draft: true`, .bak file exists
**Why human:** Validates reverse sync and file lookup by slug

#### 4. Test dry-run mode

**Test:** Run `just unpublish test-post --dry-run`
**Expected:** Shows "[DRY-RUN]" messages, no .bak file created, vault file unchanged
**Why human:** Validates preview mode doesn't modify any files

#### 5. Test config-driven author

**Test:** Add `"author": "Test Author"` to settings.local.json, run `just publish test-post --dry-run`, check output
**Expected:** Published post shows author transformation to "Test Author"
**Why human:** Validates config integration

---

## Re-Verification Summary

### Gap Closure (16-04)

**Issue identified in UAT:** publish script discovery used `status: Published` pattern instead of `draft: false`, preventing two-way sync from being testable.

**Gap closure implemented:**
1. Updated publish.sh discover_posts() to use `draft: false` pattern (line 427)
2. Updated list-posts.sh discovery to use `draft: false` pattern (line 165)
3. Updated user instructions in both scripts to reference `draft: false` field
4. Removed all references to `status: Published` in discovery logic

**Verification results:**
- ✓ publish.sh uses `draft:\s*false` perl regex pattern (case-insensitive)
- ✓ list-posts.sh uses `draft:\s*false` perl regex pattern (case-insensitive)
- ✓ User instructions updated: "set draft: false in the frontmatter"
- ✓ No references to "status: Published" remain in discovery sections
- ✓ Pattern consistency across both scripts

**Regression check:**
- ✓ All 5 original truths still verified (no breakage)
- ✓ All original artifacts still substantive and wired
- ✓ All original key links still functional
- ✓ No anti-patterns introduced

### New Must-Haves Added

**From 16-04-PLAN.md frontmatter:**
- Truth 6: "publish.sh discovers posts with draft: false (not status: Published)"
- Truth 7: "list-posts.sh discovers posts with draft: false (not status: Published)"
- Artifact: scripts/list-posts.sh with draft: false discovery pattern
- Key Link: Discovery functions → Obsidian frontmatter via perl regex pattern matching

**All new must-haves VERIFIED.**

### Commits Verified (Gap Closure)

Gap closure commits from 16-04-SUMMARY.md:

1. `5565d2d` - fix(16-04): update publish.sh discovery to use draft: false
2. `5db5095` - fix(16-04): update list-posts.sh discovery to use draft: false

Both commits follow atomic task pattern. No WIP commits.

---

## Verification Methodology

### Level 1: Existence Verification
All required artifacts exist:
- `scripts/lib/common.sh` - ✓ 310 lines (substantive)
- `scripts/publish.sh` - ✓ Modified with two integration points + discovery pattern fix
- `scripts/unpublish.sh` - ✓ Modified with flag support and integration
- `scripts/list-posts.sh` - ✓ Modified with discovery pattern fix

### Level 2: Substantive Verification
All implementations are non-stub:
- `get_author_from_config()` - 8 lines, uses jq to read config, returns empty if not set
- `update_obsidian_source()` - 68 lines, handles publish/unpublish actions, dry-run mode, backup creation, yq integration
- `find_obsidian_source()` - 32 lines, searches vault using find, slugifies to match
- Author normalization integration - 10 lines in normalize_frontmatter, calls config function with fallback
- Publish sync integration - 1 line call to update_obsidian_source after copy_post
- Unpublish sync integration - 8 lines to find source and update, with fallback warning
- **NEW:** discover_posts() - 25 lines, uses perl regex for draft: false pattern matching (publish.sh:416-440)
- **NEW:** list-posts.sh discovery - 18 lines, uses same perl regex pattern (list-posts.sh:159-176)

### Level 3: Wiring Verification
All key links are connected:
- Both scripts source common.sh (publish.sh:7, unpublish.sh:7)
- publish.sh calls both new functions (get_author_from_config:268, update_obsidian_source:855)
- unpublish.sh defines find_obsidian_source and calls update_obsidian_source (268)
- update_obsidian_source uses yq with --front-matter=process pattern from Phase 15
- get_author_from_config reads from CONFIG_FILE constant defined in common.sh
- DRY_RUN variable properly threaded through all call sites
- **NEW:** discover_posts() called in main flow at publish.sh:1055
- **NEW:** list-posts.sh discovery executed in main flow (line 162-168)
- **NEW:** Both use perl -0777 -ne for pattern matching with case-insensitive flag

### Pattern Verification
yq usage follows Phase 15 patterns:
- Uses `_get_yq_cmd()` helper to get correct command (go-yq or yq)
- Uses `--front-matter=process -i` for in-place YAML modification
- Uses `strenv(DATETIME)` pattern to pass shell variables to yq expressions
- Exports environment variable before yq call, unsets after (common.sh:279-283)

**NEW: Discovery pattern verification:**
- Uses perl with `-0777` (slurp mode) and `-ne` (print nothing, just exit code)
- Pattern `draft:\s*false` matches "draft: false" with optional whitespace around colon
- Case-insensitive flag `/i` allows "Draft: false" or "DRAFT: false"
- Consistent pattern across publish.sh and list-posts.sh

### Backup Pattern Verification
Atomic write pattern implemented correctly:
- Backup created with `cp "$obsidian_file" "${obsidian_file}.bak"` BEFORE yq modification
- Backup creation in both publish (common.sh:275) and unpublish (common.sh:295) paths
- No backup created in dry-run mode (guarded by dry_run check)

### Dry-Run Pattern Verification
Preview mode implemented consistently:
- DRY_RUN variable declared and parsed from --dry-run flag
- Passed to update_obsidian_source function as third parameter
- Guards all file modifications (git rm, yq calls, cp for backup)
- Shows preview messages with [DRY-RUN] prefix
- Skips display_next_steps in dry-run mode for cleaner output

---

## Summary

**PHASE GOAL ACHIEVED**

All 7 success criteria verified (5 original + 2 from gap closure):
1. ✓ Publish sets draft: false and pubDatetime in Obsidian source
2. ✓ Unpublish sets draft: true in Obsidian source
3. ✓ .bak file created before modifications
4. ✓ Dry-run mode previews changes without modifying files
5. ✓ Author field uses config value with fallback
6. ✓ publish.sh discovers posts with draft: false (not status: Published)
7. ✓ list-posts.sh discovers posts with draft: false (not status: Published)

All 6 requirements satisfied:
- SYNC-01 through SYNC-05: Two-way sync fully implemented
- CONF-01: Config-driven defaults established

**Gap closure successful:**
- Discovery pattern aligned with two-way sync schema
- UAT issue resolved: publish discovery now uses `draft: false`
- Consistency achieved across publish.sh and list-posts.sh
- User instructions updated to reference correct field
- No regressions detected in original functionality

**Bidirectional metadata sync keeps Obsidian source and blog copy consistent.**

Phase 16 establishes the foundation for Phase 17 (schema migration) by ensuring all publish/unpublish operations maintain synchronization between the blog and the source vault. The gap closure (16-04) ensures discovery is aligned with the new schema, making the two-way sync testable and functional.

---

_Verified: 2026-02-01T20:31:31-05:00_
_Verifier: Claude (gsd-verifier)_
_Re-verification: Yes (after 16-04 gap closure)_
