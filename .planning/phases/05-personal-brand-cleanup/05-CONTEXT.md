# Phase 5: Personal Brand Cleanup - Context

**Gathered:** 2026-01-29
**Status:** Ready for planning

<domain>
## Phase Boundary

Distinguish between person identity (Justin Carlson) and brand identity (justcarlson) across the site. Update avatar to use Gravatar. Regenerate favicon.ico with JC monogram styling.

</domain>

<decisions>
## Implementation Decisions

### Name context rules
- Social link titles use person name: "Justin Carlson on GitHub", "Justin Carlson on LinkedIn"
- Site title (browser tabs, SEO) displays as "Justin Carlson" not "justcarlson"
- Blog post bylines show "Justin Carlson" as author
- Change SITE.author from "justcarlson" to "Justin Carlson" (handle username separately where needed)

### Avatar source
- Use Gravatar with email: justincarlson0@gmail.com
- Request size: 400px for retina quality
- Fallback: identicon (generated geometric pattern)
- Replace current mystery person placeholder

### Favicon appearance
- favicon.ico uses accent blue theme: white JC letters on transparent background with accent blue color
- Include extended size set: 16, 32, 48, 64, 128, 256px
- favicon.svg keeps existing theme-adaptive behavior (responds to light/dark mode)
- .ico and .svg intentionally differ: .ico is fixed accent blue, .svg adapts to theme

### Claude's Discretion
- Exact Gravatar URL construction and hash generation
- favicon.ico generation tooling (ImageMagick, etc.)
- Which components need author vs username references

</decisions>

<specifics>
## Specific Ideas

- Person name ("Justin Carlson") for human-facing contexts: social links, bylines, titles
- Brand name ("justcarlson") only where technically required: URLs, usernames
- Gravatar identicon fallback preferred over mystery person silhouette

</specifics>

<deferred>
## Deferred Ideas

None — discussion stayed within phase scope

</deferred>

---

*Phase: 05-personal-brand-cleanup*
*Context gathered: 2026-01-29*
