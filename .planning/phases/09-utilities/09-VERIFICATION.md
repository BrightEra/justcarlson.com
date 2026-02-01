---
phase: 09-utilities
verified: 2026-02-01T00:15:00Z
status: passed
score: 6/6 must-haves verified
re_verification:
  previous_status: passed
  previous_score: 6/6
  gaps_closed:
    - "--published flag now scans blog directory directly (not via Obsidian)"
    - "User cancellation exits with code 0 instead of 130"
    - "ANSI escape codes display properly in unpublish tip"
    - "Documentation uses status: - Published terminology"
  gaps_remaining: []
  regressions: []
---

# Phase 9: Utilities Verification Report

**Phase Goal:** User can list posts and unpublish posts (preview already exists)
**Verified:** 2026-02-01T00:15:00Z
**Status:** passed
**Re-verification:** Yes - after UAT gap closure (09-03)

## Goal Achievement

### Observable Truths

| # | Truth | Status | Evidence |
|---|-------|--------|----------|
| 1 | User can run `just list-posts` to see posts with Published status in Obsidian | VERIFIED | Recipe exists (justfile:48-49), script implements discovery with perl multiline YAML matching (line 327) |
| 2 | `just list-posts --all` shows all, `--published` shows only in-repo posts | VERIFIED | Filter mode parsing (lines 47-54), --published mode calls list_published_posts() which scans BLOG_DIR directly (lines 236-312) |
| 3 | Each listed post shows title, date, status (ready vs invalid), and validation errors | VERIFIED | Table display (lines 448-450), status coloring (lines 471-476), error display (lines 482-486) |
| 4 | User can run `just unpublish <file>` to remove a post from repo (keeps Obsidian source) | VERIFIED | Recipe in justfile (line 52-53), script resolves slug (lines 161-188), git rm (line 243), Obsidian untouched |
| 5 | Unpublish commits removal (does NOT push - user can push when ready) | VERIFIED | Git commit (line 247), NO git push in script, tip displays "Run 'git push' when ready" (line 263) |
| 6 | `just preview` starts Astro dev server (already implemented in Phase 7) | VERIFIED | Recipe exists in justfile (line 20-21), runs `npm run dev` |

**Score:** 6/6 truths verified

### Required Artifacts

| Artifact | Expected | Status | Details |
|----------|----------|--------|---------|
| `scripts/list-posts.sh` | Post listing with filters and validation display | VERIFIED | 509 lines, executable, complete implementation with discovery, validation, filtering, sorting, direct blog scan |
| `scripts/unpublish.sh` | Post removal with confirmation and git commit | VERIFIED | 296 lines, executable, confirmation prompt (line 217), clean exit on cancel (line 222), git rm + commit, no push |
| `justfile` (list-posts recipe) | Recipe with flag support | VERIFIED | Line 48-49, args passthrough pattern `*args=''` |
| `justfile` (unpublish recipe) | Recipe with file and force args | VERIFIED | Line 52-53, positional file + args passthrough |
| `justfile` (preview recipe) | Astro dev server recipe | VERIFIED | Line 20-21, runs `npm run dev` (from Phase 7) |

**All artifacts:** VERIFIED (5/5)

### Key Link Verification

| From | To | Via | Status | Details |
|------|-----|-----|--------|---------|
| justfile | scripts/list-posts.sh | recipe invocation | WIRED | Recipe calls `./scripts/list-posts.sh {{args}}` |
| scripts/list-posts.sh | .claude/settings.local.json | config loading | WIRED | Line 83: `jq -r '.obsidianVaultPath'` |
| scripts/list-posts.sh | src/content/blog | direct scan for --published | WIRED | Line 244: `find "$BLOG_DIR" -name "*.md" -type f` |
| scripts/list-posts.sh | validation functions | frontmatter validation | WIRED | Functions defined (lines 137-213), called in post processing |
| justfile | scripts/unpublish.sh | recipe invocation | WIRED | Recipe calls `./scripts/unpublish.sh {{file}} {{args}}` |
| scripts/unpublish.sh | git rm | file removal | WIRED | Line 243: `git rm "$post_path" --quiet` |
| scripts/unpublish.sh | git commit | commit creation | WIRED | Line 247: `git commit -m "$commit_msg" --quiet` |

**All key links:** WIRED (7/7)

### UAT Gap Closure Verification

All 4 gaps from 09-UAT.md have been addressed:

| Gap | Root Cause | Fix Applied | Status |
|-----|------------|-------------|--------|
| --published shows "No published posts" with posts in blog | Cross-referenced Obsidian instead of blog scan | Added `list_published_posts()` function (lines 236-312) that uses `find "$BLOG_DIR"` directly | CLOSED |
| Cancellation exits with code 130 | Used EXIT_CANCELLED constant | Changed to `exit $EXIT_SUCCESS` (line 222) | CLOSED |
| ANSI escape codes printed literally | Line 261 missing `-e` flag | Changed to `echo -e` (line 261) | CLOSED |
| Documentation uses draft: false | Legacy terminology from v0.1.0 | Updated all v0.2.0 docs to use `status: - Published` | CLOSED |

### Requirements Coverage

| Requirement | Status | Evidence |
|-------------|--------|----------|
| JUST-15: User can run `just list-drafts` to see ready-to-publish posts | EVOLVED | Implemented as `just list-posts` (more accurate name). Default mode shows unpublished posts. |
| JUST-16: `just list-drafts` shows validation status per post | SATISFIED | Table shows status (ready/invalid), validation errors displayed |
| JUST-17: User can run `just unpublish [file]` to remove a post | SATISFIED | Recipe exists, accepts file/slug argument |
| JUST-18: `just unpublish` keeps source file in Obsidian | SATISFIED | Script only operates on blog repo files |
| JUST-19: `just unpublish` commits and pushes removal | EVOLVED | Commits but deliberately does NOT auto-push (safer design, user controls push timing) |
| JUST-20: User can run `just preview` to start Astro dev server | SATISFIED | Recipe exists from Phase 7 |

**Coverage:** 4 satisfied, 2 evolved (improved upon original requirements)

### Anti-Patterns Check

| Check | Result |
|-------|--------|
| TODO/FIXME comments | None found |
| Placeholder content | None found |
| Empty implementations | None found |
| Bash syntax validation | Both scripts pass `bash -n` |
| Executable permissions | Both scripts are executable |
| Echo -e consistency | All color outputs use `echo -e` |

### Human Verification Required

None - all success criteria verifiable programmatically through code inspection.

## Summary

**Phase 9 goal ACHIEVED.** All 6 observable truths verified, all 5 required artifacts substantive and wired, all 7 key links functioning.

**Gap Closure Complete:** All 4 UAT issues resolved in 09-03:
1. `list_published_posts()` function scans blog directory directly
2. User cancellation exits cleanly (code 0)
3. ANSI colors display properly in all tip messages
4. Documentation terminology consistent with implementation

**No gaps, no blockers, no human verification needed.**

---

*Verified: 2026-02-01T00:15:00Z*
*Verifier: Claude (gsd-verifier)*
