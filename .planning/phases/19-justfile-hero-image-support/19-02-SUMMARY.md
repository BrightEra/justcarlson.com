---
phase: 19-justfile-hero-image-support
plan: 02
subsystem: publishing
tags: [perl, regex, bash, astro, hero-image]

# Dependency graph
requires:
  - phase: 19-01
    provides: "Hero image frontmatter fields in content schema"
  - phase: 18-02
    provides: "Hero image layout support in templates"
provides:
  - "Perl regex fix for heroImage field preservation"
  - "Hero image path transformation from Obsidian to web format"
  - "Automatic hero image copying to public assets"
affects: []

# Tech tracking
tech-stack:
  added: []
  patterns:
    - "Explicit character class [ \\t] for Perl horizontal whitespace"
    - "Hero image path transformation in publish workflow"

key-files:
  created: []
  modified:
    - scripts/publish.sh

key-decisions:
  - "Use [ \\t]*\\n instead of \\s*$\\n? to avoid Perl variable interpolation"
  - "Transform heroImage paths like inline images (Obsidian -> /assets/blog/slug/)"

patterns-established:
  - "Hero images copied alongside inline images to /public/assets/blog/{slug}/"

# Metrics
duration: 3min
completed: 2026-02-02
---

# Phase 19 Plan 02: Perl Regex Bug Fix Summary

**Fixed Perl variable interpolation bug in normalize_frontmatter() and added hero image path transformation for Astro compatibility**

## Performance

- **Duration:** 3 min
- **Started:** 2026-02-02T06:35:19Z
- **Completed:** 2026-02-02T06:38:33Z
- **Tasks:** 2
- **Files modified:** 1

## Accomplishments
- Fixed Perl regex `\s*$\n?` to `[ \t]*\n` preventing variable interpolation
- heroImage fields with values now preserved correctly in published frontmatter
- Added transform_hero_image() to convert Obsidian paths to web paths
- Added extract_hero_image() to include hero images in asset copying
- Hello World post publishes successfully with hero image

## Task Commits

Each task was committed atomically:

1. **Task 1: Fix perl regex pattern in normalize_frontmatter()** - `b563300` (fix)
2. **Task 2: Verify fix with actual publish** - `cd66982` (fix)

Additional commits from publish workflow:
- `6f5856e` - docs(blog): update Hello World (with hero image assets)

## Files Created/Modified
- `scripts/publish.sh` - Fixed regex patterns and added hero image transformation functions

## Decisions Made
- Use explicit whitespace class `[ \t]` instead of `\s` (which includes newlines in Perl)
- Remove problematic `$\n?` anchor (Perl interprets `$\n` as variable `$\` + literal 'n')
- Transform heroImage paths identically to inline image paths for consistency

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 1 - Bug] Hero image paths not transformed from Obsidian format**
- **Found during:** Task 2 (Verify fix with actual publish)
- **Issue:** After fixing the regex, heroImage values were preserved but still contained Obsidian vault paths like "Attachments/image.jpg" which Astro cannot resolve
- **Fix:** Added transform_hero_image() function to convert paths to /assets/blog/{slug}/ format, and extract_hero_image() to include hero images in asset copying
- **Files modified:** scripts/publish.sh
- **Verification:** Build passes, heroImage: /assets/blog/hello-world/fresh-coat-on-solid-foundation.jpg
- **Committed in:** cd66982

---

**Total deviations:** 1 auto-fixed (Rule 1 - Bug)
**Impact on plan:** Necessary bug fix discovered during verification. The original regex fix exposed a second issue where heroImage paths weren't being transformed like inline images.

## Issues Encountered
- Initial publish attempt failed with LocalImageUsedWrongly error from Astro - fixed by adding path transformation

## User Setup Required
None - no external service configuration required.

## Next Phase Readiness
- Hero image support fully functional in publish workflow
- Ready for milestone completion (v0.4.1)

---
*Phase: 19-justfile-hero-image-support*
*Completed: 2026-02-02*
