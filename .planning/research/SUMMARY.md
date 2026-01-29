# Project Research Summary

**Project:** justcarlson.com Rebranding
**Domain:** Astro Blog Personalization & Identity Migration
**Researched:** 2026-01-28
**Confidence:** HIGH

## Executive Summary

This project involves rebranding a forked Astro blog from steipete.me (Peter Steinberger) to justcarlson.com (Just Carlson). The research reveals excellent news: the existing codebase already uses a modern, production-ready stack (Astro 5, Tailwind CSS 4, Sharp for image processing) with well-architected configuration layers that centralize identity elements. **No new dependencies are required.**

The recommended approach is a systematic, tier-based migration that updates configuration first (single source of truth), then static assets, then components that reference them, and finally deployment configuration. This ordering prevents broken references and ensures changes cascade correctly. The architecture separates concerns cleanly: identity elements are concentrated in 2 primary config files (`src/consts.ts` and `src/constants.ts`), with predictable references in components and build config.

The critical risk is **incomplete identity replacement** — 123 files contain references to "steipete", "peter", or "steinberger". Missing even a few creates mixed branding that damages credibility and SEO. The mitigation is systematic: use the 5-tier change sequence documented in ARCHITECTURE.md, validate with grep searches after each tier, and test builds between phases. A secondary risk is SEO degradation from redirect misconfiguration, which requires 301 (permanent) redirects and careful vercel.json updates.

## Key Findings

### Recommended Stack

The existing stack is already optimal for this use case — no additions needed. The codebase uses Astro 5.16.6 with Tailwind CSS 4.1.18, Sharp 0.34.5 for image optimization, and @resvg/resvg-js 2.6.2 for SVG-to-PNG conversion (used in OG image generation). This is the 2025/2026 recommended stack for static blogs.

**Core technologies (all already installed):**
- **Astro 5.16.6**: Static site generator — latest stable with improved image handling
- **Tailwind CSS 4.1.18**: Utility-first CSS — v4 uses CSS-native @theme configuration for easy color customization
- **Sharp 0.34.5**: Image optimization — Astro 5 default, 3x faster than alternatives for SVG conversion
- **@resvg/resvg-js 2.6.2**: SVG rendering — already used for OG images, high-quality Rust-based rendering
- **@vite-pwa/astro 1.2.0**: PWA support — zero-config manifest generation already configured

**For personalization specifically:**
- **Favicon generation**: Manual approach using existing Sharp/resvg pipeline (most control, smallest footprint)
- **Color theming**: Pure CSS custom properties with Tailwind v4 @theme directive (no new dependencies)
- **Avatar handling**: Static file in public/ (simplest, already used by steipete.me)

### Expected Features

The research categorized rebranding changes into three strategic layers: table stakes (critical for launch), differentiators (makes it feel personal), and anti-features (things to deliberately avoid).

**Must have (table stakes):**
- Author metadata update in config files (SITE object, social links)
- Domain references changed from steipete.me to justcarlson.com
- Visual assets replaced (favicon, avatar, office photos)
- Meta tags and SEO updated (BaseHead component, PWA manifest)
- Deployment config updated (vercel.json redirects and CSP headers)
- Content attribution correct (footer, LICENSE file, README)

**Should have (competitive differentiation):**
- New color palette (CSS variables in global.css — update accent colors from Peter's blue #006cac to your brand)
- About page completely rewritten with your bio/story
- Old blog posts deleted (107 posts from 2010-2025)
- Newsletter form updated or removed (currently uses Peter's Buttondown account)
- GitHub contribution graph replaced with yours

**Defer (v2+ or not needed):**
- Typography changes (Atkinson font is open-source and works well, consider keeping it)
- Layout customization (AstroPaper structure is solid, avoid bikeshedding)
- Peter-specific redirects (remove unless you have equivalent content structure)
- Markdown domain feature (steipete.md — only keep if you need this niche feature)

**Anti-features (deliberately avoid):**
- Copying Peter's writing voice or style
- Keeping his 107 blog posts as if they were yours
- Using his GitHub contribution graph on your about page
- Keeping his CSP domain allowlist (audit what YOU need)
- Removing attribution to AstroPaper theme (open-source etiquette)

### Architecture Approach

The codebase has a clean 4-layer architecture for identity elements: Configuration Layer (foundation), Asset Layer (static files), Component Layer (presentation), and Infrastructure Layer (deployment). Identity changes follow a clear dependency graph with configuration as the single source of truth.

**Major components by change tier:**

1. **Configuration Layer (Tier 1 — change first)**
   - `/src/consts.ts` — Primary SITE object with website URL, author, title, description, ogImage, editPost URL
   - `/src/constants.ts` — SOCIALS array with social media links
   - **Why first:** These files are imported everywhere. Changes cascade automatically.

2. **Asset Layer (Tier 2 — change second)**
   - `/public/peter-avatar.jpg` → rename to `avatar.jpg` or `justcarlson-avatar.jpg`
   - `/public/peter-office.jpg`, `/public/peter-office-2.jpg` → replace/rename
   - `/public/favicon.ico`, `/public/site.webmanifest` → replace
   - **Why second:** Assets must exist before components reference them.

3. **Component Layer (Tier 3 — change third)**
   - `/src/components/BaseHead.astro` — Meta tags, Twitter handles, app title
   - `/src/components/StructuredData.astro` — **CRITICAL:** Has hardcoded URLs bypassing config (refactor or delete)
   - `/src/components/Footer.astro` — GitHub repo link
   - `/src/components/NewsletterForm.astro` — External service integration
   - **Why third:** Components depend on config and assets being in place.

4. **Infrastructure Layer (Tier 4 — change fourth)**
   - `/astro.config.mjs` — PWA manifest configuration, asset references
   - `/vercel.json` — **HIGH RISK:** Domain redirects and CSP headers
   - `/src/layouts/Layout.astro` — Domain redirect script
   - **Why fourth:** These reference everything above. Must be last infrastructure changes.

5. **Content Layer (Tier 5 — change last)**
   - `/src/pages/about.mdx` — Personal bio and information
   - Blog posts in `/src/content/blog/` — Historical archive (likely delete all)
   - **Why last:** Content is presentation only, doesn't affect functionality.

**Key architectural insight:** Most components already use SITE config values, which means updating `/src/consts.ts` auto-updates 90% of references. The exceptions are hardcoded URLs in StructuredData.astro and vercel.json — these need manual attention.

### Critical Pitfalls

The research identified 12 pitfalls; these are the top 5 that would derail the rebrand:

1. **Hardcoded Domain References** — Domain name "steipete.me" hardcoded in vercel.json CSP headers, OG templates, and StructuredData.astro instead of using config. Prevention: Search entire codebase with `grep -r "steipete\.me"`, update all to use `SITE.website`, validate all URLs resolve to new domain.

2. **Leftover Identity References** — 123 files contain "steipete", "steinberger", or "peter". Missing even one creates confusion about authorship. Prevention: Global case-insensitive search-replace, update content schema default author, regenerate OG images after author change. Use systematic grep validation: `grep -ri "steipete\|steinberger\|peter" --exclude-dir=node_modules`.

3. **SEO Redirect Errors** — Using 302 (temporary) instead of 301 (permanent) redirects, or catch-all redirects to homepage instead of equivalent pages. Causes 20-40% organic traffic loss. Prevention: Use 301 redirects for all URL changes, map old URLs to equivalent new URLs (not homepage), test all redirects before DNS cutover. vercel.json lines 8-67 need careful audit.

4. **Asset Path Breakage** — Image filenames like "peter-avatar.jpg" referenced in 5+ places (PWA manifest, BaseHead component, SITE.ogImage, astro.config.mjs). Renaming without updating all references breaks images site-wide. Prevention: If renaming `peter-avatar.jpg` → `avatar.jpg`, use find/replace and update: consts.ts ogImage, BaseHead.astro apple-touch-icon, StructuredData hardcoded URLs, astro.config.mjs includeAssets and manifest.icons.

5. **Git History Attribution** — Fork relationship means GitHub shows "forked from steipete/steipete.me" banner, git blame points to Peter. Creates legal ambiguity and SEO confusion. Prevention: Decision required — either keep fork relationship with clear attribution in README (recommended for honesty), or contact GitHub support to detach fork (irreversible). Do NOT rewrite commit history without understanding licensing implications.

**Moderate pitfalls to avoid:** Package name still "steipete-astro", content schema default author, PWA manifest showing old branding, edit links pointing to wrong repo.

## Implications for Roadmap

Based on research, suggested 5-phase structure that follows the architecture tier model:

### Phase 1: Foundation Configuration
**Rationale:** Configuration is the single source of truth. Update this first so changes cascade automatically to components. Low risk, high impact.

**Delivers:**
- Updated SITE object in consts.ts (website, author, title, desc, ogImage filename, editPost URL)
- Updated SOCIALS array in constants.ts (GitHub, Twitter, BlueSky, email)
- Validation that build succeeds with new config

**Addresses (from FEATURES.md):**
- Author metadata (table stakes)
- Social links (table stakes)

**Avoids (from PITFALLS.md):**
- Pitfall 2 (identity references) — updates central config
- Pitfall 7 (content schema defaults) — sets correct default author

**Research flag:** Standard pattern, no phase-specific research needed.

---

### Phase 2: Asset Generation & Replacement
**Rationale:** Must come after config (which references asset filenames) but before components (which load assets). Asset creation is offline work, making this phase independent.

**Delivers:**
- New favicon (16×16, 32×32, 192×192, 512×512, apple-touch-icon, .ico multi-size)
- New avatar image (512×512, optimized with Sharp)
- New office/about page photos (or delete if not using)
- Updated site.webmanifest with new app name/description
- All old peter-* files removed from public/

**Addresses (from FEATURES.md):**
- Visual assets replaced (table stakes)
- Color palette updated in CSS variables (differentiator)

**Uses (from STACK.md):**
- Manual favicon generation with Sharp/resvg pipeline
- Static file approach (no new dependencies)

**Avoids (from PITFALLS.md):**
- Pitfall 4 (asset path breakage) — systematic filename replacement with validation
- Pitfall 11 (theme colors) — updates CSS custom properties for new brand

**Research flag:** Standard image optimization, no research needed. Use Sharp CLI or existing pipeline.

---

### Phase 3: Component Updates
**Rationale:** Components depend on config (Tier 1) and assets (Tier 2). This phase updates hardcoded references that don't use config imports. Most risky is StructuredData.astro with hardcoded URLs.

**Delivers:**
- BaseHead.astro updated (Twitter handles, app title, avatar path)
- StructuredData.astro refactored to use SITE config OR deleted (already has structured data in Layout.astro)
- Footer.astro GitHub repo URL updated
- NewsletterForm.astro updated with new Buttondown account OR removed
- Sidebar.astro verified (may be unused legacy code) and updated if needed

**Addresses (from FEATURES.md):**
- Meta tags and SEO updated (table stakes)
- Newsletter integration updated (differentiator)

**Implements (from ARCHITECTURE.md):**
- Component layer (Tier 3) changes
- Hardcoded URL elimination in StructuredData

**Avoids (from PITFALLS.md):**
- Pitfall 1 (hardcoded domains) — removes direct string literals, uses config
- Pitfall 8 (PWA metadata) — updates manifest meta tags
- Pitfall 9 (edit links) — updates GitHub integration

**Research flag:** StructuredData.astro needs decision — refactor vs delete. Quick architectural review needed (15 min). Standard component patterns otherwise.

---

### Phase 4: Infrastructure & Deployment
**Rationale:** Build config references everything above (config values, asset filenames, component structure). Must be done after Tiers 1-3 complete. Highest risk phase due to vercel.json complexity.

**Delivers:**
- astro.config.mjs PWA manifest updated (name, short_name, description, asset references)
- vercel.json domain redirects updated (steipete.me → justcarlson.com references)
- vercel.json CSP headers updated (remove Peter's domains, add yours if needed)
- Layout.astro domain redirect script removed or updated (steipete.md feature)
- Production build tested with `npm run build && npm run preview`
- Service worker manifest validated

**Addresses (from FEATURES.md):**
- Deployment config updated (table stakes)
- Domain references changed (table stakes)

**Uses (from STACK.md):**
- Existing Vercel deployment setup (zero-config Astro detection)
- @vite-pwa/astro for manifest generation

**Avoids (from PITFALLS.md):**
- Pitfall 3 (SEO redirects) — use 301 permanent redirects, map old → new equivalents
- Pitfall 1 (hardcoded domains) — updates vercel.json CSP with new domain
- Pitfall 12 (search index) — clears dist/ before production build

**Research flag:** HIGH — vercel.json redirect strategy needs careful review. CSP configuration needs audit. Estimated 30-45 min review of Vercel redirect docs + CSP best practices. Consider separate `/gsd:research-phase` for redirect mapping if site has complex URL structure.

---

### Phase 5: Content & Final Cleanup
**Rationale:** Content is presentation layer only — doesn't affect functionality. Can be done last. Includes deleting old blog posts and rewriting about page.

**Delivers:**
- About page rewritten with your bio, story, photos, links
- 107 old blog posts deleted from src/content/blog/ (or selectively kept with clear attribution)
- Legal imprint updated in about page
- README.md updated (attribution, project description)
- LICENSE copyright holder updated (keep dual CC BY 4.0 + MIT structure)
- Package.json name changed to "justcarlson-com"
- Final grep validation that no identity references remain

**Addresses (from FEATURES.md):**
- About page rewritten (differentiator)
- Content attribution correct (table stakes)
- Old posts deleted (anti-feature avoidance)

**Implements (from ARCHITECTURE.md):**
- Content layer (Tier 5) changes

**Avoids (from PITFALLS.md):**
- Pitfall 2 (leftover identity) — final sweep with grep searches
- Pitfall 6 (package names) — updates project identifiers
- Pitfall 10 (comments/docs) — cleans up documentation references

**Anti-features avoided:**
- Don't copy Peter's writing voice
- Don't keep his GitHub contribution graph
- Don't inherit his blog posts without attribution

**Research flag:** No research needed. Standard content creation.

---

### Phase Ordering Rationale

This 5-phase structure follows the architecture's dependency graph:
1. **Configuration first** because it's imported by everything (changes cascade)
2. **Assets second** because components reference them (must exist before use)
3. **Components third** because they depend on config + assets
4. **Infrastructure fourth** because it aggregates all above changes into build output
5. **Content last** because it's presentation-only and doesn't affect functionality

**Dependency-based grouping:**
- Phases 1-2 can have some overlap (config + asset creation are independent)
- Phase 3 MUST wait for Phases 1-2 to complete (component imports fail otherwise)
- Phase 4 MUST wait for Phase 3 (build config validates against component structure)
- Phase 5 can start after Phase 2 (content creation is independent work)

**Risk-based ordering:**
- Low-risk changes (config, assets) before high-risk (vercel.json)
- Testable checkpoints after each phase (npm run build validation)
- Reversible changes (content) separated from infrastructure changes

**Estimated timeline:**
- Phase 1: 1 hour (pure config updates)
- Phase 2: 2-3 hours (asset creation + CSS color updates)
- Phase 3: 2-4 hours (component refactoring, especially StructuredData)
- Phase 4: 1-2 hours (build config, vercel.json careful updates)
- Phase 5: 1 hour (content creation is ongoing but deployment-blocking work is minimal)
- **Total:** 7-11 hours of focused work, ideally spread over 1-2 weeks for testing between phases

### Research Flags

**Needs phase-specific research:**
- **Phase 4 (Infrastructure):** vercel.json redirect strategy and CSP configuration. This is complex with 15+ redirect rules and security implications. Recommend 30-45 min focused research on Vercel redirect best practices and CSP header configuration. Alternatively, could use `/gsd:research-phase` for "SEO redirect mapping" if you have complex content structure requiring URL migration.

**Standard patterns (skip research):**
- **Phase 1:** Configuration updates are straightforward JS object changes
- **Phase 2:** Image optimization is well-documented, Sharp CLI usage is standard
- **Phase 3:** Component updates follow existing Astro patterns in codebase
- **Phase 5:** Content creation doesn't need technical research

**Validation points:**
Each phase should end with validation:
- Phase 1: `npm run build` succeeds, no TypeScript errors
- Phase 2: `grep -r "peter-" src/` returns no matches, images display in dev mode
- Phase 3: Manual testing of all pages, no console errors
- Phase 4: Production build + preview, CSP validation, service worker check
- Phase 5: Visual review, final grep for identity references

## Confidence Assessment

| Area | Confidence | Notes |
|------|------------|-------|
| Stack | **HIGH** | All recommendations verified in package.json and source code. Astro 5 + Tailwind 4 + Sharp is proven 2025/2026 stack. No new dependencies needed. |
| Features | **HIGH** | Feature categorization based on codebase analysis + SEO migration research. Table stakes vs differentiators clearly delineated. 123 identity reference locations mapped. |
| Architecture | **HIGH** | Clear 5-tier structure with explicit dependencies. File-to-change mapping complete. Import chains verified. Only unknown is whether Sidebar.astro is actually used (needs grep check). |
| Pitfalls | **HIGH** | 12 pitfalls identified from codebase analysis + 6 authoritative 2026 SEO migration sources. Validation strategies provided for each. Grep searches documented for systematic audit. |

**Overall confidence:** **HIGH**

The high confidence is due to:
1. **Codebase access:** All research based on actual source code analysis, not speculation
2. **Existing infrastructure:** Everything needed is already installed and working
3. **Clear architecture:** Identity elements are well-organized, not scattered
4. **Proven patterns:** Astro 5 blog rebranding is well-documented domain

### Gaps to Address

**Minor gaps requiring validation during implementation:**

1. **Sidebar component usage:** `/src/components/Sidebar.astro` has hardcoded social links but wasn't found in current layouts. Need to grep for `<Sidebar` usage and either update or delete.
   - **How to handle:** Quick grep search during Phase 3. If unused, delete it.

2. **Newsletter service migration:** Requires Buttondown account creation or username change. External service dependency outside codebase control.
   - **How to handle:** Create new Buttondown account during Phase 2 prep. Update form action URL in Phase 3. Test form submission. OR remove newsletter form entirely if not needed.

3. **GitHub repository strategy:** Need to decide whether to keep fork relationship (shows "forked from steipete/steipete.me" on GitHub) or detach it.
   - **How to handle:** Recommend keeping fork with clear attribution in README for open-source etiquette. If detaching needed, contact GitHub support (irreversible). Decision doesn't block development — can be done anytime.

4. **Old blog post handling:** 107 blog posts from 2010-2025. Need to decide: delete all, keep some with attribution, or keep all with author note.
   - **How to handle:** Recommended approach is delete all (they're Peter's expertise, not yours). If keeping any, add author attribution note. This is content decision, not technical gap.

5. **Domain redirect strategy:** If you own steipete.me after rebrand, should it redirect to justcarlson.com? Or let it expire?
   - **How to handle:** Not blocking. If redirecting, reverse the direction of existing vercel.json rules. If not, remove redirect rules entirely.

**No blocking gaps identified.** All technical unknowns can be resolved during implementation with <15 min of validation each.

## Sources

### Primary Sources (HIGH confidence)

**Codebase Analysis:**
- `/package.json` — Verified installed packages and versions
- `/astro.config.mjs` — Confirmed Astro 5 config, PWA setup, image service
- `/src/consts.ts` — Analyzed site configuration structure
- `/src/styles/global.css` — Examined Tailwind CSS 4 theming with @theme directive
- `/vercel.json` — Mapped redirect rules and CSP headers (60+ lines)
- `/src/components/` — Analyzed all component identity references
- `/src/content/blog/` — Counted 107 blog posts across year folders

**Official Documentation:**
- [Astro Images Guide](https://docs.astro.build/en/guides/images/) — Image handling patterns
- [Tailwind CSS v4 Beta](https://tailwindcss.com/docs/v4-beta) — v4 theming with @theme directive
- [Vercel Astro Docs](https://vercel.com/docs/frameworks/frontend/astro) — Deployment configuration
- [Vite PWA for Astro](https://vite-pwa-org.netlify.app/frameworks/astro) — PWA integration guide

### Secondary Sources (MEDIUM confidence)

**Technical Implementation Guides:**
- [Favicon Generation with Astro - kremalicious](https://kremalicious.com/favicon-generation-with-astro/) — Manual favicon approach
- [Rodney Lab: Astro JS Favicon](https://rodneylab.com/astro-js-favicon/) — Required favicon files
- [Tailwind v4 Colors - TailKits](https://tailkits.com/blog/tailwind-v4-custom-colors/) — Color customization patterns
- [Sharp vs resvg-js benchmark](https://github.com/privatenumber/sharp-vs-resvgjs) — Performance comparison (Sharp 3x faster)
- [GitHub: Theming in v4](https://github.com/tailwindlabs/tailwindcss/discussions/18471) — Tailwind CSS 4 best practices

**SEO Migration Research (2026):**
- [SEO Migration 2026: Complete Guide](https://www.veloxmedia.com/blog/seo-migration-2026-the-complete-guide) — Redirect best practices
- [12 Site Migration Mistakes That Damage SEO](https://embryo.com/blog/12-site-migration-mistakes-that-damage-seo/) — Pitfall analysis
- [Site Migration SEO Common Mistakes](https://marketinglabs.co.uk/site-migration-seo-common-mistakes/) — 301 vs 302 implications
- [Common Website Migration Mistakes](https://www.oncrawl.com/technical-seo/common-website-migration-mistakes-drag-down-seo-performance/) — Technical SEO
- [Top Rebranding Mistakes to Avoid 2026](https://devopus.com/blog/top-rebranding-mistakes-to-avoid-in-2026/) — Brand consistency
- [When Rebrands Go Wrong](https://www.threerooms.com/blog/when-rebrands-go-wrong-common-mistakes-and-lessons-to-learn) — Case studies

### Tertiary Sources (LOW confidence, validation needed)

**Package Evaluation:**
- [astro-favicons on GitHub](https://github.com/ACP-CODE/astro-favicons) — Evaluated but NOT recommended (no Astro 5 confirmation, overkill with 19 files + 20 HTML tags)
- [@resvg/resvg-js on npm](https://www.npmjs.com/package/@resvg/resvg-js) — Already installed, verified usage in generateOgImages.ts

**Methodology note:** Codebase analysis used grep searches to count references:
- 123 files containing identity references (case-insensitive "steipete", "steinberger", "peter")
- 19 instances of steipete.me in vercel.json alone
- 107 blog posts in src/content/blog/ across year folders (2010-2025)

---

*Research completed: 2026-01-28*
*Synthesis confidence: HIGH — all 4 research dimensions analyzed*
*Ready for roadmap: YES — 5 phases suggested with clear dependencies*
