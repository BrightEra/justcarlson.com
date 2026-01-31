---
phase: 09-utilities
plan: 01
subsystem: cli
tags: [bash, just, jq, validation, frontmatter]

# Dependency graph
requires:
  - phase: 08-core-publishing
    provides: publish.sh validation patterns
provides:
  - list-posts.sh utility for viewing post status
  - justfile recipe for easy CLI access
affects: [09-02, utilities]

# Tech tracking
tech-stack:
  added: []
  patterns: [reuse validation from publish.sh, filter-based CLI flags]

key-files:
  created: [scripts/list-posts.sh]
  modified: [justfile]

key-decisions:
  - "Default filter shows unpublished posts only (scales as post count grows)"
  - "Reuse validation functions from publish.sh for consistency"
  - "Use echo -e for ANSI color output (matching publish.sh pattern)"

patterns-established:
  - "CLI utilities follow pattern: script in scripts/, recipe in justfile with arg passthrough"
  - "Filter modes via flags: default (most common), --all (everything), --specific (targeted)"

# Metrics
duration: 3min
completed: 2026-01-31
---

# Phase 9 Plan 1: List Posts Summary

**CLI utility to view Obsidian posts with validation status, filtering by published/unpublished state**

## Performance

- **Duration:** 3 min
- **Started:** 2026-01-31T22:15:28Z
- **Completed:** 2026-01-31T22:18:16Z
- **Tasks:** 2
- **Files modified:** 2

## Accomplishments
- Created list-posts.sh script with validation and filtering
- Added Utilities section to justfile with list-posts recipe
- Support for three filter modes: unpublished (default), --all, --published
- Table output with title, date, status, and validation errors

## Task Commits

Each task was committed atomically:

1. **Task 1: Create list-posts.sh script** - `6063dbc` (feat)
2. **Task 2: Wire list-posts recipe into justfile** - `743713d` (feat)

## Files Created/Modified
- `scripts/list-posts.sh` - List posts from Obsidian with validation status and filtering
- `justfile` - Added Utilities section with list-posts recipe

## Decisions Made

**Filter mode design:**
- Default shows unpublished posts only - most useful mode as post count grows
- `--all` shows everything with Published status
- `--published` shows only posts already in blog repo
- Scales well for long-term use (won't overwhelm user with old posts)

**Pattern reuse from publish.sh:**
- Validation functions (validate_frontmatter, extract_frontmatter_value, etc.)
- Color definitions (RED, GREEN, YELLOW, CYAN, RESET)
- Config loading pattern (jq for settings.local.json)
- Post discovery pattern (perl -0777 for multiline YAML matching)
- Ensures consistency between publish and list operations

**Output formatting:**
- Table with fixed-width columns for readability
- ANSI colors for status (green=Ready, red=Invalid, yellow=warnings)
- Error messages indented below invalid posts with arrow prefix
- Sorting: ready posts first, then invalid; within each group by date descending

## Deviations from Plan

None - plan executed exactly as written.

## Issues Encountered

None - straightforward implementation reusing existing patterns.

## User Setup Required

None - no external service configuration required.

## Next Phase Readiness

- List posts utility complete and functional
- Ready for 09-02 (preview utility) and 09-03 (unpublish utility)
- Pattern established for future CLI utilities

---
*Phase: 09-utilities*
*Completed: 2026-01-31*
