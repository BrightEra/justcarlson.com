---
phase: 05-personal-brand-cleanup
plan: 01
subsystem: ui
tags: [gravatar, branding, configuration]

# Dependency graph
requires:
  - phase: 04-content-polish
    provides: Cleaned source code and content
provides:
  - SITE.authorFullName config field for person vs brand name distinction
  - Social link titles using person name context
  - Gravatar avatar placeholder with hash slot
affects: [any future social sharing, author attribution, branding contexts]

# Tech tracking
tech-stack:
  added: []
  patterns:
    - Person name (Justin Carlson) vs brand name (justcarlson) separation in config

key-files:
  created: []
  modified:
    - src/consts.ts
    - src/constants.ts
    - src/components/Sidebar.astro

key-decisions:
  - "Use authorFullName field for person name contexts (social links)"
  - "Use author/title for brand name contexts (site identity)"
  - "Gravatar hash as placeholder with clear replacement instructions"

patterns-established:
  - "SITE.author/SITE.title for brand identity (justcarlson)"
  - "SITE.authorFullName for person contexts (Justin Carlson)"

# Metrics
duration: 1.6min
completed: 2026-01-29
---

# Phase 5 Plan 1: Personal Brand Cleanup Summary

**Person vs brand name distinction in config with authorFullName field, social links now show "Justin Carlson on GitHub" instead of "justcarlson on Github"**

## Performance

- **Duration:** 1.6 min (96 seconds)
- **Started:** 2026-01-29T21:01:07Z
- **Completed:** 2026-01-29T21:02:43Z
- **Tasks:** 3
- **Files modified:** 3

## Accomplishments
- Added authorFullName field to SITE configuration for person name contexts
- Updated social link titles to use person name (Justin Carlson) instead of brand name
- Prepared Gravatar integration with hash placeholder and clear documentation

## Task Commits

Each task was committed atomically:

1. **Task 1: Add authorFullName to SITE configuration** - `50b133a` (feat)
2. **Task 2: Update social link titles to use person name** - `c8df570` (feat)
3. **Task 3: Update Gravatar URL with hash placeholder** - `621192a` (feat)

## Files Created/Modified
- `src/consts.ts` - Added authorFullName field to Site interface and SITE object, changed author/title to "justcarlson" brand name
- `src/constants.ts` - Updated SOCIALS linkTitle to use SITE.authorFullName for person name context
- `src/components/Sidebar.astro` - Added Gravatar URL with [GRAVATAR_HASH] placeholder and comment for replacement, updated alt text to use authorFullName

## Decisions Made

**1. Person vs Brand Name Separation**
- Rationale: External profiles show "Justin Carlson" (person name) but site was showing "justcarlson" (brand name) in social link titles, creating disconnect
- Solution: Separate concerns with authorFullName for person contexts and author/title for brand contexts

**2. Gravatar Hash as Placeholder**
- Rationale: Asking for email publicly is a security risk, MD5 hash should be generated offline
- Solution: Use [GRAVATAR_HASH] placeholder with clear documentation comment for user to replace

## Deviations from Plan

None - plan executed exactly as written.

## Issues Encountered

None - all tasks completed smoothly with build passing on first attempt.

## User Setup Required

**Manual action needed:** Replace `[GRAVATAR_HASH]` in `src/components/Sidebar.astro` with MD5 hash of Gravatar email address.

To generate hash offline:
```bash
echo -n "your@email.com" | md5sum
```

Then replace `[GRAVATAR_HASH]` in the Gravatar URL with the generated hash.

## Next Phase Readiness

- Personal brand cleanup configuration complete
- Person name correctly attributed in social contexts
- Site identity maintains brand name (justcarlson)
- Gravatar placeholder ready for user to add their hash
- No blockers for future work

---
*Phase: 05-personal-brand-cleanup*
*Completed: 2026-01-29*
