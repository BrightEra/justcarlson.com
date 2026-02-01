# Requirements: justcarlson.com v0.2.0

**Defined:** 2026-01-30
**Architecture:** Three-layer pattern (justfile + hooks + optional skills)
**Core Value:** Frictionless publishing from Obsidian with validation, rollback, and confidence that builds always pass.

## v0.2.0 Requirements

### Layer 1: justfile Commands

#### Setup
- [x] **JUST-01**: User can run `just setup` to configure Obsidian vault path interactively
- [x] **JUST-02**: `just setup` writes vault path to `.claude/settings.local.json` (gitignored)
- [x] **JUST-03**: All other recipes read vault path from config

#### Publishing
- [x] **JUST-04**: User can run `just publish` to publish all ready posts
- [x] **JUST-05**: `just publish` finds all `status: - Published` posts in configured Obsidian path (case-insensitive)
- [x] **JUST-06**: `just publish` validates frontmatter (title, pubDatetime, description required)
- [x] **JUST-07**: `just publish` copies posts to `src/content/blog/YYYY/` (year from pubDatetime)
- [x] **JUST-08**: `just publish` detects and copies referenced images to `public/assets/blog/`
- [x] **JUST-09**: `just publish` runs Biome lint before commit
- [x] **JUST-10**: `just publish` runs `npm run build` before push
- [x] **JUST-11**: `just publish` commits with conventional message (`docs(blog): add` for new, `docs(blog): update` for changed)
- [x] **JUST-12**: `just publish` pushes to origin
- [x] **JUST-13**: User can run `just publish --dry-run` to preview actions without executing
- [x] **JUST-14**: `just publish` reports progress (echoes step names during execution)

#### Utilities
- [x] **JUST-15**: User can run `just list-posts` to see ready-to-publish posts
- [x] **JUST-16**: `just list-posts` shows validation status per post (ready vs missing fields)
- [x] **JUST-17**: User can run `just unpublish [file]` to remove a post from repo
- [x] **JUST-18**: `just unpublish` keeps source file in Obsidian
- [x] **JUST-19**: `just unpublish` commits removal (does not push)
- [x] **JUST-20**: User can run `just preview` to start Astro dev server

### Layer 2: Hooks & Safety

- [x] **HOOK-01**: Setup hook runs `just setup` on `claude --init`
- [x] **HOOK-02**: Hook configuration stored in `.claude/settings.json` (committed)
- [x] **HOOK-03**: Git safety hook blocks dangerous operations (`--force`, `reset --hard`, `checkout .`, `clean -f`)
- [ ] **HOOK-04**: Maintenance hook runs health checks on `claude --maintenance` (deferred)

### Layer 3: Skills (Optional)

- [x] **SKILL-01**: User can run `/publish` skill for human-in-the-loop oversight
- [x] **SKILL-02**: `/publish` skill wraps `just publish` (doesn't duplicate logic)
- [x] **SKILL-03**: `/publish` uses `disable-model-invocation: true` (manual only)

## Future Requirements

| Feature | Milestone | Rationale |
|---------|-----------|-----------|
| Newsletter integration | v0.3.0+ | Separate concern from publishing |
| Social auto-posting | v0.3.0+ | API complexity, rate limits |
| Real-time sync (file watcher) | v0.3.0+ | Batch publish sufficient for manual workflow |
| Multiple vault support | v0.3.0+ | YAGNI for personal blog |

## Out of Scope

| Feature | Reason |
|---------|--------|
| Auto-linting hook | Biome runs in publish workflow already |
| Series/related posts | Not in original blog, not adding |
| Comments system | Not in original, not adding now |
| Skills for every command | justfile is sufficient; /publish skill for oversight only |

## Traceability

| Requirement | Phase | Status |
|-------------|-------|--------|
| JUST-01 | Phase 7 | Complete |
| JUST-02 | Phase 7 | Complete |
| JUST-03 | Phase 7 | Complete (pattern ready, reads in Phase 8) |
| JUST-04 | Phase 8 | Complete |
| JUST-05 | Phase 8 | Complete |
| JUST-06 | Phase 8 | Complete |
| JUST-07 | Phase 8 | Complete |
| JUST-08 | Phase 8 | Complete |
| JUST-09 | Phase 8 | Complete |
| JUST-10 | Phase 8 | Complete |
| JUST-11 | Phase 8 | Complete |
| JUST-12 | Phase 8 | Complete |
| JUST-13 | Phase 8 | Complete |
| JUST-14 | Phase 8 | Complete |
| JUST-15 | Phase 9 | Complete |
| JUST-16 | Phase 9 | Complete |
| JUST-17 | Phase 9 | Complete |
| JUST-18 | Phase 9 | Complete |
| JUST-19 | Phase 9 | Complete |
| JUST-20 | Phase 9 | Complete |
| HOOK-01 | Phase 7 | Complete |
| HOOK-02 | Phase 7 | Complete |
| HOOK-03 | Phase 7 | Complete |
| HOOK-04 | Deferred | Pending (not in Phase 7 success criteria) |
| SKILL-01 | Phase 10 | Complete |
| SKILL-02 | Phase 10 | Complete |
| SKILL-03 | Phase 10 | Complete |

**Coverage:**
- v0.2.0 requirements: 27 total
- Mapped to phases: 27
- Unmapped: 0

---
*Requirements defined: 2026-01-30*
*Architecture: justfile + hooks + optional skills*
