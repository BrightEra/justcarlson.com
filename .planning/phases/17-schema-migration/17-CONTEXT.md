# Phase 17: Schema Migration - Context

**Gathered:** 2026-02-02
**Status:** Ready for planning

<domain>
## Phase Boundary

Replace `status: Published` with `draft: true/false` as the single source of truth for publish state. Migrate existing posts, update Obsidian template, configure types.json, and update views to use the new schema.

</domain>

<decisions>
## Implementation Decisions

### Migration strategy
- One-time migration script (not gradual)
- Standalone script: `./scripts/migrate-schema.sh` (not in justfile)
- Create `.bak` backup files before modifying each post
- Support `--dry-run` flag to preview changes
- Remove old schema fields (`status`, `published`) after migration
- Discover posts by `categories: - "[[Posts]]"` pattern (not by status field)
- Posts without status or draft field default to `draft: true`
- Stop on first error (fail fast)
- Verify each file after modification (re-read to confirm)
- Idempotent: safe to run multiple times
- Report summary at end: X migrated, Y already done, Z errors

### Migration scope
- Migrate Obsidian vault files only
- Blog copies in `content/blog/` updated via normal `just publish` after migration
- Template update is a separate task from post migration
- Obsidian config (types.json, views) is a separate task from post migration

### Template fields
- Field order: content first (title, description), then metadata (draft, dates)
- Include `created` field, auto-filled by Templater at note creation
- Include `pubDatetime` as empty placeholder (filled by publish script)
- Default `draft: true` (new posts are unpublished by default)

### Existing post handling
- `status: Published` → `draft: false`
- Any other status (Draft, etc.) or no status → `draft: true`
- Preserve existing `pubDatetime` values
- Backfill missing `pubDatetime` with file mtime for published posts

### Obsidian view behavior
- Posts Base view shows all posts (both drafts and published)
- Sort by created date (newest first)
- Show pubDatetime column for published posts

### Claude's Discretion
- Visual indicator style for draft status in views (use sensible defaults)
- Which vault location to migrate (Claude decides based on sync architecture)
- Exact error message formatting

</decisions>

<specifics>
## Specific Ideas

- Only one post is currently published, so no need for fancy re-publish list output
- Discovery uses Kepano ontology pattern: `categories: - "[[Posts]]"`

</specifics>

<deferred>
## Deferred Ideas

None — discussion stayed within phase scope

</deferred>

---

*Phase: 17-schema-migration*
*Context gathered: 2026-02-02*
