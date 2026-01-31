# Phase 9: Utilities - Context

**Gathered:** 2026-01-31
**Status:** Ready for planning

<domain>
## Phase Boundary

CLI recipes for managing blog posts: list posts, preview locally, and unpublish. The publish command evolves into a sync operation where Obsidian is the single source of truth.

</domain>

<decisions>
## Implementation Decisions

### Publish = Sync Model
- `just publish` becomes a **sync** operation, not just "add new posts"
- Compares Obsidian state (`status: - Published`) to blog repo state
- Adds posts with `- Published` that aren't in blog
- Updates posts that have changed
- **Removes posts from blog that no longer have `- Published` in Obsidian**
- Obsidian is the single source of truth — blog converges to match

### List Posts Command
- Renamed from `list-drafts` to `just list-posts` (more accurate)
- **Default:** Show only unpublished/new posts (scales well over years)
- **Flags:** `--all` for everything, `--published` for posts already in repo
- **Output:** Detailed — title + date + status + missing fields for invalid posts
- **Sorting:** By status then date (ready posts first, then invalid)
- **Format:** Human-readable table matching `just publish` visual style
- No `--json` flag — keep it simple, YAGNI

### Unpublish Command
- `just unpublish [file]` for immediate removal without opening Obsidian
- **Confirmation:** Required by default, `--force` to skip prompt
- **Images:** Leave in repo (safer, avoid orphan complexity)
- **Obsidian source:** Leave untouched (YAML list manipulation too risky)
- **Git:** Commit removal but don't push (creates natural checkpoint)
- **Tip at end:** Remind user to update Obsidian status
- Note: With sync model, unpublish is convenience — user can also just change Obsidian status and run `just publish`

### Hooks for Safety
- **Post-unpublish hook:** Prompts "Update status in Obsidian now?" — "yes" pushes, "no" exits without push
- **Pre-publish hook:** Checks if any recently-removed posts still have `- Published` in Obsidian, warns before re-adding
- Hooks only prompt/warn/block — never execute recipes (prevents loops)
- Hooks are complementary layers: checkpoint + safety net

### Preview Command
- `just preview` starts Astro dev server
- **Browser:** Don't auto-open, just print URL
- **Port:** Astro default (4321)
- **Output:** Standard Astro output, no extras
- **Foreground:** Claude's discretion (standard dev server behavior)

### Error Messaging (All Commands)
- **Format:** Specific, single-line with actionable suggestion
  ```
  Error: my-post.md — missing required field: title
    → Add 'title: "Your Title"' to frontmatter
  ```
- **Color coding:** Red = error, Yellow = warning, Green = success
- **Grouping:** Show all errors, not just first
- **Exit codes:** 0 = success, 1 = error, 2 = blocked by hook
- Match Phase 8 validation style for consistency

### Claude's Discretion
- Preview foreground vs background (recommend foreground)
- "Recently removed" window for pre-publish hook (suggest 30 days or 20 commits)
- Exact table column widths and spacing

</decisions>

<specifics>
## Specific Ideas

- The sync model insight: "Obsidian is the single source of truth, blog converges to match"
- Unpublish without updating Obsidian → next sync would re-add → hooks prevent this
- Post count could grow large over years → default to new-only, flags to expand

</specifics>

<deferred>
## Deferred Ideas

- `just clean-images` to find orphaned assets — add if bloat becomes a problem
- `--json` flag for programmatic output — YAGNI for personal blog
- Auto-update Obsidian status from unpublish — too risky with YAML list syntax

</deferred>

---

*Phase: 09-utilities*
*Context gathered: 2026-01-31*
