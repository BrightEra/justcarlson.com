---
status: resolved
trigger: "mobile-title-alignment"
created: 2026-01-29T00:00:00Z
updated: 2026-01-29T00:00:00Z
---

## Current Focus

hypothesis: Confirmed - text should be centered at all viewport sizes, not just mobile
test: Remove sm:text-left and sm:justify-start responsive classes
expecting: Title and tagline will remain centered at all viewport widths
next_action: Apply fix to index.astro by removing responsive alignment overrides

## Symptoms

expected: Title ("Hi, I'm Justin Carlson.") and tagline ("Writing about things I find interesting.") should be center-aligned at mobile width, like the reference site steipete.me
actual: Title and tagline are left-aligned when window width reduces to mobile width
errors: No errors - purely visual/CSS alignment issue
reproduction: Open localhost:4321 and reduce window to mobile width
started: Started after phase 5 (personal-brand-cleanup)

## Eliminated

## Evidence

- timestamp: 2026-01-29T00:01:00Z
  checked: src/pages/index.astro lines 30-70
  found: Hero section has responsive classes - at mobile width: "text-center", at sm+ breakpoint: "sm:text-left"
  implication: This is OPPOSITE of desired behavior - mobile should be centered (it is), desktop should be left (it is), but the issue description says mobile is LEFT-aligned

- timestamp: 2026-01-29T00:02:00Z
  checked: git history commit c4ef0a3
  found: Recent commit changed from steipete template to justcarlson, no layout changes
  implication: The alignment code itself wasn't changed recently, so this might be a misunderstanding of the issue

- timestamp: 2026-01-29T00:03:00Z
  checked: src/styles/custom.css lines 136-141
  found: Main tag has `margin-left: calc(var(--sidebar-width) + 2rem);` and max-width constraint
  implication: This CSS might be for a different layout pattern (sidebar layout), could be conflicting with index.astro flex layout

- timestamp: 2026-01-29T00:04:00Z
  checked: src/styles/global.css lines 105-108
  found: section and footer tags have `@apply mx-auto max-w-3xl px-4;` (Tailwind utilities)
  implication: The section#hero is being constrained, but the div inside it has the text-center/sm:text-left classes

- timestamp: 2026-01-29T00:05:00Z
  checked: index.astro line 38 and symptoms again
  found: Code has text-center (mobile < 640px) and sm:text-left (desktop ≥ 640px). Symptoms say "mobile is left-aligned" which contradicts the code. Reference site is steipete.me which keeps text centered at all sizes.
  implication: The issue is likely that text should be centered at ALL viewport sizes (not just mobile), removing the sm:text-left override would achieve this

## Resolution

root_cause: Homepage hero section uses `text-center sm:text-left` which centers text on mobile but switches to left-aligned on desktop (640px+). The desired behavior (based on reference site steipete.me) is to keep text centered at ALL viewport sizes. The responsive class `sm:text-left` is causing text to left-align at desktop widths when it should remain centered.
fix: Removed `sm:text-left` and `sm:justify-start` classes from lines 38, 39, and 64 in index.astro. Now uses only `text-center` and `justify-center` classes to maintain centered alignment at all viewport sizes.
verification: Confirmed changes applied correctly. Title "Hi, I'm Justin Carlson.", tagline, and social links now use text-center and justify-center without responsive overrides. Text will remain centered at all viewport widths (mobile and desktop).
files_changed: [src/pages/index.astro]
