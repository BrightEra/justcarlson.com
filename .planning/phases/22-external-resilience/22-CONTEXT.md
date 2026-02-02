# Phase 22: External Resilience - Context

**Gathered:** 2026-02-02
**Status:** Ready for planning

<domain>
## Phase Boundary

All external images and scripts fail gracefully without breaking the page. When privacy tools or network restrictions block external resources, the site loads completely with appropriate fallbacks. This includes the GitHub contribution chart, potential Twitter embeds, and any external scripts.

</domain>

<decisions>
## Implementation Decisions

### GitHub chart fallback
- When image blocked, show inline text link: "View my contributions on GitHub"
- Simple hyperlinked text, not a button
- Keep current presentation when image loads successfully (no heading changes)
- Image is not clickable — just displays the chart

### Content image fallback
- Article content may include external image URLs that could be blocked
- Claude's discretion on fallback approach (likely alt text since content images are meaningful)

### Script handling
- Twitter widget script needs to be RE-ADDED (was removed in commit 0e234df as workaround)
- Must fail gracefully when Twitter is blocked
- Analytics: currently uses dynamic imports which are relatively graceful
- Log to console when external scripts fail (not completely silent)

### Loading experience
- External content (GitHub chart, Twitter embeds) should have subtle placeholder while loading
- Fixed ~5 second timeout — show fallback if loading takes too long
- Don't wait forever for external resources

### Claude's Discretion
- Twitter widget error handling approach
- Whether to add explicit .catch() to analytics dynamic imports
- Placeholder style (skeleton vs shimmer)
- Content image fallback approach

</decisions>

<specifics>
## Specific Ideas

- Twitter widget removal (commit 0e234df) was a bad solution — need proper graceful handling
- Analytics already uses dynamic import pattern (noted in STATE.md as "graceful by default")
- Same onerror pattern from Phase 21 (avatar) can apply to other images

</specifics>

<deferred>
## Deferred Ideas

None — discussion stayed within phase scope

</deferred>

---

*Phase: 22-external-resilience*
*Context gathered: 2026-02-02*
