# Project Milestones: justcarlson.com

## v0.2.0 Publishing Workflow (Shipped: 2026-01-31)

**Delivered:** Frictionless Obsidian-to-blog publishing with validation, git safety, and optional Claude oversight

**Phases completed:** 7-10 (12 plans total)

**Key accomplishments:**
- Justfile-based publishing workflow — `just publish`, `just setup`, `just list-posts`, `just unpublish`, `just preview`
- Obsidian integration — Interactive vault configuration, posts discovered by `status: - Published` in frontmatter
- Full validation pipeline — Frontmatter validation, image handling (wiki-links → markdown), lint/build gates
- Git safety hooks — Blocks dangerous operations (`--force`, `reset --hard`, `checkout .`) with clear errors
- Optional Claude skills — 5 skills with human-in-the-loop oversight and stop hooks for verification
- UAT-driven quality — 4 gap closure plans addressed real-world usage issues (ANSI, lint-staged, frontmatter types)

**Stats:**
- 62 files changed (+8,543 / -112 lines)
- 2,393 lines of Bash scripts + justfile + hooks
- 4 phases, 12 plans, ~45 tasks
- 2 days from v0.1.0 to ship (2026-01-30 → 2026-01-31)

**Git range:** `feat(07-01)` → `docs(blog): add Hello World` (tagged v0.2.0)

**What's next:** Newsletter setup, actual blog content, About page bio

---

## v0.1.0 MVP (Shipped: 2026-01-30)

**Delivered:** Personal blog fully rebranded from steipete.me to justcarlson.com with custom theme, favicon, and clean content slate

**Phases completed:** 1-6 (16 plans total)

**Key accomplishments:**
- Complete identity rebrand — All config, components, and structured data updated to Justin Carlson identity
- Removed all previous owner content — Deleted 110 blog posts, 191 images, and all Peter Steinberger references
- Custom theme and branding — Leaf Blue light / AstroPaper v4 dark color scheme with JC monogram favicon
- Config-driven components — Refactored structured data, sidebar, newsletter to consume centralized config
- Personal brand cleanup — Person name (Justin Carlson) vs brand name (justcarlson) distinction with Gravatar
- About page with optimized photo — Personal photo using Astro Image with WebP and responsive widths

**Stats:**
- 391 files changed (+8,037 / -15,241 lines — net content removal)
- 5,615 lines of TypeScript/Astro/CSS
- 6 phases, 16 plans, ~40 tasks
- 1 day from start to ship (2026-01-29)

**Git range:** `feat(01-01)` → `docs(06)` (tagged v0.1.0)

**What's next:** Newsletter setup, actual blog content, About page bio

---
