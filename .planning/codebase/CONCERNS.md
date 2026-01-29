# Codebase Concerns

**Analysis Date:** 2026-01-28

## Tech Debt

**Duplicate Configuration Files:**
- Issue: Three separate config files for similar concerns: `consts.ts`, `constants.ts`, and `config.ts`. `consts.ts` is imported by `constants.ts`, which is re-exported by `config.ts`. This creates confusion about which file to use and increases maintenance burden.
- Files: `src/config.ts`, `src/constants.ts`, `src/consts.ts`
- Impact: Developers may import from wrong file, inconsistent patterns across codebase. Makes refactoring difficult if configuration needs to be restructured.
- Fix approach: Consolidate into single source of truth. Merge all configuration into `consts.ts` (most complete), remove `constants.ts` and `config.ts`, update all imports to point to single file.

**TypeScript `@ts-ignore` Without Documentation:**
- Issue: `astro.config.mjs` line 20 has `@ts-ignore` for remark plugin tuple syntax without explanation of why it's needed or alternative solutions.
- Files: `astro.config.mjs:20`
- Impact: Makes codebase fragile to TypeScript updates. Future maintainers may remove the ignore without understanding the underlying issue.
- Fix approach: Either fix the underlying type issue with proper remark plugin typing, or add detailed comment explaining why the ignore is necessary and what attempts were made to resolve it.

**Biome Linting Overly Permissive:**
- Issue: Several important linting rules are disabled in `biome.json`: `noExplicitAny`, `noUnusedVariables`, `noUnusedImports`. Rules for accessibility (`noSvgWithoutTitle`, `useAriaPropsSupportedByRole`) also disabled.
- Files: `biome.json:32-50`
- Impact: Allows accumulation of dead code, implicit types, and accessibility issues. Makes codebase harder to refactor and less accessible to users.
- Fix approach: Gradually enable rules, starting with `noUnusedVariables` and `noUnusedImports`. Review current codebase for violations and address them incrementally.

## Performance Bottlenecks

**Dynamic Google Font Loading on Every Build:**
- Issue: `loadGoogleFont.ts` fetches fonts from Google Fonts API at build time. The `loadGoogleFonts()` function is called during OG image generation for every single post build. No caching mechanism exists between builds.
- Files: `src/utils/loadGoogleFont.ts:1-54`, `src/utils/og-templates/post.js:234`, `src/utils/og-templates/site.js:125`
- Cause: Each font fetch is a network call. With 100+ posts, this could add significant build time. Network failures would fail the entire build.
- Improvement path: Implement build-time caching (persist downloaded fonts in `.cache/` directory). Use font data checksums to validate cache. Add fallback to system fonts if network fails.

**Overly Complex OG Image Generation:**
- Issue: Post OG image template (`og-templates/post.js`) is 237 lines of nested object literals representing JSX-like structure. Makes it hard to read and modify. Large number of nested style objects increases serialization overhead during build.
- Files: `src/utils/og-templates/post.js:106-237`
- Cause: Satori requires object-based VNode structure instead of JSX, leading to deeply nested unreadable code.
- Improvement path: Consider extracting style objects to constants for reusability. Add type definitions to catch structure errors early. Evaluate if satori-html plugin could simplify this.

**Content Collection Glob Pattern Without Optimization:**
- Issue: `content.config.ts` uses unoptimized glob pattern `**/[^_]*.{md,mdx}` that scans entire file system including potential hidden files.
- Files: `src/content.config.ts:8`
- Cause: Overly broad pattern may scan unnecessary directories on large contentful sites.
- Improvement path: Limit glob to specific content directories. Add performance monitoring to build output.

## Fragile Areas

**Post Filtering Logic Depends on Environment Detection:**
- Issue: `postFilter.ts` uses `import.meta.env.DEV` to conditionally show unpublished/unlisted posts. This makes development builds differ from production in hard-to-trace ways.
- Files: `src/utils/postFilter.ts:4-8`
- Why fragile: If environment detection changes or is misconfigured, wrong posts appear publicly. Scheduled posts depend on margin calculation that could drift with timezone/system time changes.
- Safe modification: Add comprehensive tests for post filtering with various date/environment combinations. Document assumptions about timezone handling clearly. Consider using explicit environment variables instead of auto-detection.
- Test coverage: No test files exist for this critical filtering logic.

**Middleware Redirect Logic Susceptible to Edge Cases:**
- Issue: `middleware.js` implements path redirects for legacy `/blog/` URLs. Redirect logic has multiple conditions that could create redirect chains if not careful.
- Files: `src/middleware.js:1-15`
- Why fragile: Multiple redirect patterns in `vercel.json` could interact unexpectedly. Regex patterns for year/month/day format are error-prone and unmaintained.
- Safe modification: Add comprehensive redirect test suite mapping old URLs to expected destinations. Document why each redirect exists and when it can be removed.
- Test coverage: No test coverage for middleware redirects.

**Vercel Configuration Heavily Customized:**
- Issue: `vercel.json` contains 67 lines of custom redirects, rewrites, and headers specific to this site. Complex regex patterns for year-based URL migration. Hardcoded CSP policy that's difficult to maintain.
- Files: `vercel.json`
- Why fragile: Adding new content types or URL structures requires careful regex updates. CSP policy hardcodes multiple domains that could break if URLs change. Host-based routing logic is brittle.
- Safe modification: Extract redirect patterns to documented mapping. Use simpler, more explicit redirect rules. Move CSP policy to code-based configuration where it can be more easily validated.
- Test coverage: No automated tests for redirect behavior.

**OG Image Generation Has No Error Recovery:**
- Issue: `generateOgImages.ts` and font loading will completely fail the build if Google Fonts API is unavailable or returns unexpected response format.
- Files: `src/utils/loadGoogleFont.ts:13-21`, `src/utils/generateOgImages.ts`
- Why fragile: Network dependency without timeout or retry logic. No fallback font or graceful degradation.
- Safe modification: Add timeout to fetch calls (3-5 second limit). Implement retry with exponential backoff. Add local font fallback if network fails. Allow build to continue with warning if OG generation fails.
- Test coverage: No tests for network failure scenarios.

## Known Issues

**Inconsistent Social Link Data Structure:**
- Issue: Two different data structures for social links: `SOCIALS` in `constants.ts` (uses `icon` field) vs `SOCIAL_LINKS` in `consts.ts` (uses `label` field). Similar discrepancy between `NAV_LINKS` and other navigation structures.
- Files: `src/constants.ts:3-39`, `src/consts.ts:60-89`
- Symptoms: Components must handle multiple formats. Risk of rendering broken links if using wrong data source.
- Workaround: Always reference `SOCIALS` from `constants.ts` for actual social media links.

**Unused Import in OG Generator:**
- Issue: `og-templates/site.js` imports `{ SITE }` from `@/config` (line 2) but the actual SITE configuration object should come from config.ts which re-exports from consts.ts. This indirect import path is hard to trace.
- Files: `src/utils/og-templates/site.js:2`
- Symptoms: Not immediately visible but creates fragile dependency chain. If config.ts export structure changes, this breaks silently.
- Workaround: Currently works but should be refactored when consolidating config files.

## Security Considerations

**Content Security Policy Is Complex and Permissive:**
- Risk: CSP policy in `vercel.json:144` uses `'unsafe-inline'` and `'unsafe-eval'` for scripts and styles. Uses broad patterns like `https://*.vercel.app` that allow loading from any Vercel deployment. Contains multiple third-party domains (Twitter, Vimeo).
- Files: `vercel.json:144`
- Current mitigation: Default CSP is restrictive baseline; specific allowances are intentional for analytics and social embeds.
- Recommendations: Document why each origin is needed. Consider moving to nonce-based CSP instead of unsafe-inline. Audit third-party scripts annually. Add CSP violation monitoring to catch unexpected content loads.

**Hardcoded User Agent in Font Loading:**
- Risk: `loadGoogleFont.ts:7-8` uses fake User-Agent string to fetch fonts. This could be detected and blocked by Google Fonts or misinterpreted as bot activity.
- Files: `src/utils/loadGoogleFont.ts:7-8`
- Current mitigation: None - this appears to be workaround for some issue with font fetching.
- Recommendations: Document why fake User-Agent is necessary. Use legitimate User-Agent or consider using official Google Fonts API client. Monitor for changes in Google Fonts that break this workaround.

**Environment Variables Not Documented:**
- Risk: No `.env.example` file or documentation of required environment variables. SITE configuration in `consts.ts` is hardcoded rather than environment-based.
- Files: All config files
- Current mitigation: Config is public (blog site), no secrets currently stored.
- Recommendations: Create `.env.example` documenting all expected variables. If adding analytics or other services that require API keys, ensure they're properly documented and never committed.

## Test Coverage Gaps

**No Test Coverage for Core Utilities:**
- What's not tested: Post filtering (`postFilter.ts`), post sorting (`getSortedPosts.ts`), post grouping (`getPostsByGroupCondition.ts`), slug generation (`slugify.ts`), reading time calculation (`readingTime.ts`).
- Files: All utility files in `src/utils/`
- Risk: Logic errors in post processing could silently affect site behavior. Changes to sorting or filtering logic could break site without developer noticing during development.
- Priority: High - these utilities are critical to site functionality.

**No Test Coverage for Middleware and Redirects:**
- What's not tested: URL redirect logic in `middleware.js`, Vercel redirects in `vercel.json`, old URL patterns mapping.
- Files: `src/middleware.js`, `vercel.json`
- Risk: Breaking changes to old URLs wouldn't be caught. Redirect chains could silently develop and harm SEO.
- Priority: High - broken redirects impact user experience and SEO.

**No Test Coverage for Content Schema Validation:**
- What's not tested: Blog post frontmatter schema enforcement, missing required fields, invalid date formats.
- Files: `src/content.config.ts`
- Risk: Invalid post data could cause build failures or runtime errors on specific pages. Type coercion for dates could silently produce unexpected results.
- Priority: Medium - caught at build time but should be validated earlier.

**No Tests for OG Image Generation:**
- What's not tested: Font loading, SVG to PNG conversion, error handling, fallback behavior when fonts unavailable.
- Files: `src/utils/generateOgImages.ts`, `src/utils/loadGoogleFont.ts`, `src/utils/og-templates/`
- Risk: OG image generation failures would break entire build. No visibility into what's actually being generated.
- Priority: Medium - high impact on build success but less critical to site functionality.

---

*Concerns audit: 2026-01-28*
