---
phase: 08-core-publishing
plan: 05
subsystem: publishing
tags: [bash, perl, yaml, frontmatter, astro, schema-validation]

# Dependency graph
requires:
  - phase: 08-01
    provides: "publish.sh workflow with copy_post function"
  - phase: 08-02
    provides: "convert_wiki_links function for content transformation"
provides:
  - "normalize_frontmatter() function for type coercion (author array→string, heroImage null→undefined)"
  - "Frontmatter normalization integrated into publish pipeline before wiki-link conversion"
affects: [future-posts, content-schema]

# Tech tracking
tech-stack:
  added: []
  patterns:
    - "Frontmatter type normalization pattern using perl for multiline YAML matching"
    - "Pipeline order: normalize_frontmatter → convert_wiki_links (order critical for wiki-links in author field)"

key-files:
  created: []
  modified:
    - scripts/publish.sh
    - src/content/blog/2026/ai-helped-me-resurrect-a-five-year-old-codebase.md

key-decisions:
  - "Hardcode site default author string (Justin Carlson) to avoid config file dependency"
  - "Use perl -0777 for multiline pattern matching (consistent with discover_posts)"
  - "Remove empty heroImage entirely (not set to empty string) for proper optional() schema handling"

patterns-established:
  - "normalize_frontmatter runs before convert_wiki_links to handle wiki-links in frontmatter fields"

# Metrics
duration: 2min
completed: 2026-01-31
---

# Phase 8 Plan 5: Frontmatter Type Normalization Summary

**Frontmatter type coercion (author array→string, heroImage null→undefined) via normalize_frontmatter() function using perl multiline YAML matching**

## Performance

- **Duration:** 2 min
- **Started:** 2026-01-31T19:09:12Z
- **Completed:** 2026-01-31T19:11:14Z
- **Tasks:** 2
- **Files modified:** 2

## Accomplishments
- normalize_frontmatter() function transforms Obsidian YAML array author format to Astro string schema
- Empty heroImage fields removed (null→undefined) to satisfy optional() schema validation
- Build now passes without InvalidContentEntryDataError for author/heroImage fields

## Task Commits

Each task was committed atomically:

1. **Task 1: Add normalize_frontmatter() function** - `29b5da2` (feat)
2. **Task 2: Wire normalize_frontmatter() into copy_post()** - `5d12a3b` (feat)

**Deviation fix:** `c51463e` (fix: normalize existing blog post frontmatter)

**Plan metadata:** (to be committed)

## Files Created/Modified
- `scripts/publish.sh` - Added normalize_frontmatter() function and integrated into copy_post() before convert_wiki_links()
- `src/content/blog/2026/ai-helped-me-resurrect-a-five-year-old-codebase.md` - Fixed frontmatter to pass schema validation

## Decisions Made

**1. Hardcode site default author**
- Rationale: Avoids dependency on config file parsing at this point, simpler implementation
- Value: `"Justin Carlson"` (matches SITE.author in src/consts.ts)

**2. Use perl for multiline YAML matching**
- Rationale: Consistent with existing discover_posts() pattern
- Handles `author:\n  - "[[Me]]"` format correctly

**3. Remove empty heroImage entirely**
- Rationale: Astro schema `heroImage: z.string().optional()` expects undefined or string, not null
- Empty line removal is cleaner than setting empty string

**4. Pipeline order: normalize_frontmatter before convert_wiki_links**
- Rationale: Wiki-links in author field (`[[Me]]`) must be replaced with default string before link conversion
- Critical for correctness

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 1 - Bug] Normalized frontmatter in existing published post**
- **Found during:** Task 2 (Build verification)
- **Issue:** Existing blog post had author array and empty heroImage, causing InvalidContentEntryDataError
- **Fix:** Manually normalized frontmatter in ai-helped-me-resurrect-a-five-year-old-codebase.md
- **Files modified:** src/content/blog/2026/ai-helped-me-resurrect-a-five-year-old-codebase.md
- **Verification:** npm run build passes without schema errors
- **Committed in:** c51463e (separate deviation commit)

---

**Total deviations:** 1 auto-fixed (1 bug - schema validation failure)
**Impact on plan:** Essential fix to unblock build. The normalize_frontmatter() function will prevent this issue for future publishes, but existing post needed manual correction.

## Issues Encountered
None - plan executed smoothly after auto-fixing existing blog post

## User Setup Required
None - no external service configuration required

## Next Phase Readiness
- Frontmatter type normalization complete
- Build passes without schema validation errors
- Publish workflow now handles Obsidian YAML array author format automatically
- Ready for Phase 9 (Utilities) and future publishing operations

---
*Phase: 08-core-publishing*
*Completed: 2026-01-31*
