# Phase 3: Infrastructure - Context

**Gathered:** 2026-01-29
**Status:** Ready for planning

<domain>
## Phase Boundary

Build configuration and deployment preparation for production. PWA manifest branding, Vercel config cleanup, CSP headers with correct allowlist, and production build validation. Does not include content changes or new features.

</domain>

<decisions>
## Implementation Decisions

### Redirect strategy
- Clean slate approach — remove all steipete-specific redirects
- Remove the catch-all redirect (lines 58-67) that routes unknown domains to steipete.me
- Remove Peter-specific post redirects (`a-new-beginning`, `llm-codes-transform-developer-docs`, etc.)
- No internal redirects — clean URL structure, let 404s be 404s
- Custom 404 page — branded with navigation back home

### CSP strictness
- No analytics — no tracking services allowed
- Keep: YouTube embeds (`youtube.com`, `*.youtube-nocookie.com`)
- Keep: Twitter embeds (`platform.twitter.com`, `syndication.twitter.com`, `cdn.syndication.twimg.com`)
- Keep: Vimeo embeds (`player.vimeo.com`, `vimeo.com`)
- Keep: GitHub contribution chart (`ghchart.rshah.org`)
- Keep: Vercel services (`*.vercel.app`, `vercel.live`, `va.vercel-scripts.com`, `vitals.vercel-insights.com`)
- Remove: `steipete.me` and `*.sweetistics.com` from all CSP directives

### Build validation
- Identity leak detection: Warn only (grep for steipete/Peter Steinberger, log warnings, don't fail)
- Broken internal links: Warn only (log but allow deploy)
- TypeScript/lint errors: Fail build (strict)
- Smoke test: Basic verification that home, about, and posts pages render after build

### Claude's Discretion
- Trailing slash behavior (follow Astro defaults or existing config)
- Inline script/style CSP handling (follow existing patterns)
- Exact smoke test implementation approach
- Which generic blog redirects to keep vs remove (legacy URL patterns → /posts/:slug)

</decisions>

<specifics>
## Specific Ideas

- Markdown content negotiation rewrites can stay (generic feature, not identity-specific)
- The existing `X-Content-Type-Options`, `X-Frame-Options`, `X-XSS-Protection`, `Referrer-Policy` headers are good security defaults — keep them

</specifics>

<deferred>
## Deferred Ideas

None — discussion stayed within phase scope

</deferred>

---

*Phase: 03-infrastructure*
*Context gathered: 2026-01-29*
