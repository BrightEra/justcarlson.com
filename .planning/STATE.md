# Project State

## Project Reference

See: .planning/PROJECT.md (updated 2026-01-30)

**Core value:** Frictionless publishing from Obsidian with validation, rollback, and confidence that builds always pass.
**Current focus:** Phase 10: Skills Layer

## Current Position

Phase: 10 of 10 (Skills Layer) - COMPLETE
Plan: 1 of 1 in current phase
Status: v0.2.0 complete - all phases executed
Last activity: 2026-02-01 — Completed 10-01-PLAN.md

Progress: [████████████████████] 100% (27/27 plans)

## Performance Metrics

**v0.1.0 Milestone:**
- Total plans completed: 16
- Average duration: 1.9 min
- Total execution time: 0.49 hours
- Timeline: 1 day (2026-01-29)

**By Phase:**

| Phase | Plans | Total | Avg/Plan |
|-------|-------|-------|----------|
| 01-foundation | 2 | 7 min | 3.5 min |
| 02-components | 2 | 8 min | 4 min |
| 03-infrastructure | 3 | 5 min | 1.67 min |
| 04-content-polish | 4 | 6 min | 1.5 min |
| 05-personal-brand-cleanup | 4 | 4 min | 1 min |
| 06-about-page-photo | 1 | 1 min | 1 min |

**v0.2.0 Milestone:** Complete (10/10 plans)

| Phase | Plans | Total | Avg/Plan |
|-------|-------|-------|----------|
| 07-setup-safety | 2/2 | 4 min | 2 min |
| 08-core-publishing | 5/5 | 11 min | 2.2 min |
| 09-utilities | 3/3 | 8 min | 2.7 min |
| 10-skills-layer | 1/1 | 2 min | 2 min |

## Accumulated Context

### Decisions

All v0.1.0 decisions documented in PROJECT.md Key Decisions table.

v0.2.0 architecture decision:
- Three-layer pattern: justfile (deterministic) + hooks (safety) + skills (optional oversight)
- Justfile is source of truth — all entry points execute same recipes

07-01 decisions:
- Config stored in .claude/settings.local.json (project-local, gitignored)
- Vault detection searches home directory to maxdepth 4
- JSON uses flat structure: {obsidianVaultPath: string}

07-02 decisions:
- Block force push, reset --hard, checkout ., restore ., clean -f
- Allow branch -D and rebase (useful, not catastrophic)
- Log blocked operations to .claude/blocked-operations.log
- Exit code 2 blocks operation, exit code 0 allows

08-01 decisions:
- Use perl for multiline YAML matching (status: followed by newline and - Published)
- Three-tier selection fallback: gum -> fzf -> numbered list
- Slugify from Obsidian filename, not title field
- Identical posts excluded; changed posts marked with (update)

08-02 decisions:
- Validate all posts before displaying errors (collect-all-errors pattern)
- Prompt user to continue with valid posts when some invalid
- Wiki-links with alt text preserve alt text in markdown output
- Missing images warn but don't block publishing
- Search Attachments folder first, then recursive vault search for images

08-03 decisions:
- Lint runs after copy, before commits; build runs after commits, before push
- Retry markers (PUBLISH_LINT_FAILED, PUBLISH_BUILD_FAILED) output to stderr for Claude hook integration
- Rollback only removes files created in current publish run, not updates
- Dry-run selects all posts automatically for complete preview

08-04 decisions:
- Use echo -e flag to enable ANSI escape sequence interpretation
- Add --allow-empty to lint-staged to allow markdown-only commits
- Auto-continue in dry-run mode when partial validation failures occur

08-05 decisions:
- Hardcode site default author string (Justin Carlson) to avoid config file dependency
- Use perl -0777 for multiline YAML pattern matching (consistent with discover_posts)
- Remove empty heroImage entirely (not set to empty string) for proper optional() schema handling
- Pipeline order: normalize_frontmatter before convert_wiki_links (critical for wiki-links in author field)

09-01 decisions:
- Default filter shows unpublished posts only (scales as post count grows)
- Reuse validation functions from publish.sh for consistency
- CLI utilities follow pattern: script in scripts/, recipe in justfile with arg passthrough
- Filter modes via flags: default (most common), --all (everything), --specific (targeted)

09-02 decisions:
- Unpublish commits but does NOT push (creates checkpoint for user review)
- Images left in repo when unpublishing (safer, avoids orphan complexity)
- Obsidian source untouched (YAML list manipulation too risky)

09-03 decisions:
- --published mode scans blog directory directly (no vault dependency)
- User cancellation exits with code 0 (valid outcome, not error)
- v0.1.0 historical docs remain unchanged

10-01 decisions:
- All skills use disable-model-invocation: true (manual-only)
- Stop hooks use exit code 2 blocking pattern
- Check stop_hook_active to prevent infinite loops
- Startup hook suggests /install if vault unconfigured

### Pending Todos

None.

### Blockers/Concerns

None.

### Quick Tasks Completed

| # | Description | Date | Directory |
|---|-------------|------|-----------|
| 001 | Delete obsolete webmanifest, fix PWA name | 2026-01-29 | [001-delete-obsolete-webmanifest-fix-pwa-name](./quick/001-delete-obsolete-webmanifest-fix-pwa-name/) |
| 002 | Add X social profile (x.com/_justcarlson) | 2026-01-29 | [002-add-x-twitter-social-profile](./quick/002-add-x-twitter-social-profile/) |
| 003 | Unify Obsidian post templates | 2026-01-30 | [003-unify-obsidian-post-templates](./quick/003-unify-obsidian-post-templates/) |

## Session Continuity

Last session: 2026-02-01T02:32:37Z
Stopped at: Completed 10-01-PLAN.md — skills layer complete, v0.2.0 ready
Resume file: None

Config:
{
  "obsidianVaultPath": "/home/jc/obsidian/jc",
  "model_profile": "balanced",
  "commit_docs": true
}
