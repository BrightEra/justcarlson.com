# Phase 8: Core Publishing - Context

**Gathered:** 2026-01-30
**Status:** Ready for planning

<domain>
## Phase Boundary

User can publish posts from Obsidian with full validation pipeline. Includes post discovery, frontmatter validation, image handling, lint/build verification, and git commit/push. Utilities (list-drafts, unpublish, preview) are Phase 9.

</domain>

<decisions>
## Implementation Decisions

### Post discovery
- Source: Anywhere in vault with `status: published` (case-insensitive)
- Status format: YAML array (e.g., `status: - Published`)
- Multiple posts: Interactive multi-select prompt (checkbox-style, arrow keys + space to toggle)
- Display per post: Title + pubDatetime, sorted newest first
- Already published detection: Compare content — skip unchanged, include if different (shows as "update")
- No posts ready: Friendly message "No posts ready to publish" and exit 0

### Validation feedback
- Error collection: All errors at once across all posts
- Partial valid scenario: Prompt user ("2 valid, 1 invalid. Publish the valid ones?")
- Error detail level: Helpful (field name + guidance, e.g., "Missing title (required for SEO and display)")
- Image validation: Check existence in vault, warn but don't block if missing
- Lint/build failure: Hard block — no commit or push happens

### Failure recovery
- On lint/build failure: Hook triggers Claude to auto-fix
- After fix: Auto-retry lint/build (no user prompt)
- Retry limit: 3 attempts max
- After 3 failures: Git rollback everything — discard all changes from this publish attempt
- Rationale: Obsidian is source of truth, nothing is lost; repo stays clean

### File placement
- Slug source: Obsidian filename (slugified) — single source of truth
- `url` frontmatter field: Ignored
- Post destination: `src/content/blog/YYYY/` (year from pubDatetime)
- Image destination: `public/assets/blog/[slug]/` (per-post folder)
- Image references in posts: Both wiki-style (`![[image.png]]`) and markdown-style (`![](path)`)
- Local images location: `Attachments/` folder at vault root
- Remote images: Left as-is (URLs preserved)

### Commit behavior
- Commit granularity: One commit per post
- New post message: `docs(blog): add {title}`
- Updated post message: `docs(blog): update {title}`
- Push behavior: Ask first ("Push to remote?") before pushing

### Claude's Discretion
- Multi-select prompt library choice
- Exact image path rewriting implementation
- Wiki-link to markdown conversion approach
- Progress/spinner display during operations

</decisions>

<specifics>
## Specific Ideas

- User's Obsidian template uses Templater: title comes from filename, status defaults to `- Draft`
- Existing Astro setup: slug derives from filename in `src/content/blog/`, no slug field in schema
- Vault path: Configured in `.claude/settings.local.json` (from Phase 7 setup)
- Attachments path: `{vault}/Attachments/`

</specifics>

<deferred>
## Deferred Ideas

- Dry-run mode (`just publish --dry-run`) — mentioned in roadmap success criteria, handle during planning
- List-drafts command — Phase 9
- Preview command — Phase 9
- Unpublish command — Phase 9

</deferred>

---

*Phase: 08-core-publishing*
*Context gathered: 2026-01-30*
