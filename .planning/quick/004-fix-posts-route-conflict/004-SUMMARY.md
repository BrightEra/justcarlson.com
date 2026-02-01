# Quick Fix 004: Fix /posts Route Conflict

**Date:** 2026-02-01
**Type:** Bug Fix
**Trigger:** 404 error when navigating to /posts/ (with trailing slash)

## Problem

Navigating to `/posts/` returned a 404 with Astro's trailing slash error page:
> "Your site is configured with trailingSlash set to never. Do you want to go to /posts instead?"

Build logs showed route conflicts:
```
[WARN] [build] Could not render `/posts` from route `/posts/[...page]` as it conflicts with higher priority route `/posts`.
[WARN] [build] Could not render `/posts/2026/hello-world` from route `/posts/[...slug]` as it conflicts with higher priority route `/posts/[...page]`.
```

## Root Cause

Multiple overlapping route files in `src/pages/posts/`:
1. `index.astro` - handled `/posts` (correct)
2. `[page].astro` - empty, returned no paths
3. `[...page].astro` - catch-all pagination that also claimed `/posts`
4. `[...slug].astro` - post routes conflicting with `[...slug]/index.astro`

Additionally, `trailingSlash: "never"` in astro.config.mjs caused 404s for URLs with trailing slashes, which some internal links had.

## Solution

### 1. Removed redundant route files

Deleted 3 files that caused conflicts:
- `src/pages/posts/[page].astro` - empty redirect stub
- `src/pages/posts/[...page].astro` - pagination conflicting with index
- `src/pages/posts/[...slug].astro` - duplicate of `[...slug]/index.astro`

### 2. Changed trailingSlash config

Changed `astro.config.mjs`:
```diff
- trailingSlash: "never",
+ trailingSlash: "ignore",
```

This allows both `/posts` and `/posts/` to work, preventing 404s from trailing slashes in links or browser history.

### 3. Fixed internal link

Changed `src/pages/index.astro` line 103:
```diff
- <LinkButton href="/posts/">
+ <LinkButton href="/posts">
```

## Files Changed

- `astro.config.mjs` - trailingSlash: "ignore"
- `src/pages/index.astro` - removed trailing slash from /posts link
- `src/pages/posts/[page].astro` - DELETED
- `src/pages/posts/[...page].astro` - DELETED
- `src/pages/posts/[...slug].astro` - DELETED

## Verification

```bash
curl -s -o /dev/null -w "%{http_code}" http://localhost:4321/posts   # 200
curl -s -o /dev/null -w "%{http_code}" http://localhost:4321/posts/  # 200
npm run build  # No route conflict warnings
```

## Remaining Route Structure

Clean structure after fix:
- `src/pages/posts/index.astro` - `/posts` listing page
- `src/pages/posts/[...slug]/index.astro` - individual post pages
- `src/pages/posts/[...slug]/index.png.ts` - OG images
- `src/pages/posts/[...slug].md.ts` - markdown export
