# Roadmap: justcarlson.com

## Milestones

- ✅ **v0.1.0 MVP Rebranding** - Phases 1-6 (shipped 2026-01-30)
- 🚧 **v0.2.0 Publishing Workflow** - Phases 7-10 (in progress)

## Phases

<details>
<summary>✅ v0.1.0 MVP Rebranding (Phases 1-6) - SHIPPED 2026-01-30</summary>

### Phase 1: Foundation
**Goal**: Project infrastructure and identity setup
**Plans**: 2 plans (complete)

### Phase 2: Components
**Goal**: UI component rebranding
**Plans**: 2 plans (complete)

### Phase 3: Infrastructure
**Goal**: Build and deployment setup
**Plans**: 3 plans (complete)

### Phase 4: Content Polish
**Goal**: Content cleanup and validation
**Plans**: 4 plans (complete)

### Phase 5: Personal Brand Cleanup
**Goal**: Complete identity transition
**Plans**: 4 plans (complete)

### Phase 6: About Page Photo
**Goal**: Personal photo on About page
**Plans**: 1 plan (complete)

</details>

### 🚧 v0.2.0 Publishing Workflow (In Progress)

**Milestone Goal:** Frictionless publishing from Obsidian with validation, rollback, and confidence that builds always pass.

#### Phase 7: Setup & Safety
**Goal**: Skills have a configured Obsidian path and git operations are protected
**Depends on**: Phase 6 (v0.1.0 complete)
**Requirements**: SETUP-01, SETUP-02, SETUP-03, SETUP-04, HOOK-01, HOOK-02
**Success Criteria** (what must be TRUE):
  1. User can run `/setup-blog` and it prompts for Obsidian vault path
  2. After setup, `.claude/settings.local.json` contains the configured path
  3. Running any other skill without setup prompts user to run `/setup-blog` first
  4. Dangerous git operations (force push, reset --hard) are blocked with clear error messages
**Plans**: TBD

Plans:
- [ ] 07-01: Setup skill and config storage
- [ ] 07-02: Git safety hooks

#### Phase 8: Core Publishing
**Goal**: User can publish posts from Obsidian to the blog with full validation
**Depends on**: Phase 7
**Requirements**: PUB-01, PUB-02, PUB-03, PUB-04, PUB-05, PUB-06, PUB-07, PUB-08, PUB-09, PUB-10, PUB-11
**Success Criteria** (what must be TRUE):
  1. User can run `/publish-blog` and it finds all `draft: false` posts in Obsidian
  2. Posts with missing frontmatter (title, pubDatetime, description) are flagged with clear errors
  3. Valid posts are copied to `src/content/blog/YYYY/` with referenced images in `public/assets/blog/`
  4. Biome lint and full build pass before any commit happens
  5. Changes are committed with conventional message and pushed to origin
**Plans**: TBD

Plans:
- [ ] 08-01: Publish skill structure and discovery
- [ ] 08-02: Validation and image handling
- [ ] 08-03: Lint, build, commit, push pipeline

#### Phase 9: Utilities
**Goal**: User can preview drafts and see what's ready to publish
**Depends on**: Phase 7 (uses config), independent of Phase 8
**Requirements**: UTIL-01, UTIL-02, UTIL-03, UTIL-04, UTIL-05
**Success Criteria** (what must be TRUE):
  1. User can run `/list-drafts` and see all `draft: false` posts in Obsidian
  2. Each listed post shows validation status (ready vs missing fields)
  3. User can run `/preview-blog` and Astro dev server starts for local review
**Plans**: TBD

Plans:
- [ ] 09-01: List drafts skill
- [ ] 09-02: Preview blog skill

#### Phase 10: Rollback
**Goal**: User can remove published posts from the blog while keeping Obsidian source
**Depends on**: Phase 8 (unpublishes what was published)
**Requirements**: ROLL-01, ROLL-02, ROLL-03, ROLL-04, ROLL-05
**Success Criteria** (what must be TRUE):
  1. User can run `/unpublish-blog [filename]` and post is removed from repo
  2. Source file in Obsidian is untouched
  3. Removal is committed and pushed with conventional message
**Plans**: TBD

Plans:
- [ ] 10-01: Unpublish blog skill

## Progress

**Execution Order:** Phases execute in numeric order: 7 → 8 → 9 → 10

| Phase | Milestone | Plans Complete | Status | Completed |
|-------|-----------|----------------|--------|-----------|
| 1. Foundation | v0.1.0 | 2/2 | Complete | 2026-01-29 |
| 2. Components | v0.1.0 | 2/2 | Complete | 2026-01-29 |
| 3. Infrastructure | v0.1.0 | 3/3 | Complete | 2026-01-29 |
| 4. Content Polish | v0.1.0 | 4/4 | Complete | 2026-01-29 |
| 5. Personal Brand Cleanup | v0.1.0 | 4/4 | Complete | 2026-01-29 |
| 6. About Page Photo | v0.1.0 | 1/1 | Complete | 2026-01-30 |
| 7. Setup & Safety | v0.2.0 | 0/2 | Not started | - |
| 8. Core Publishing | v0.2.0 | 0/3 | Not started | - |
| 9. Utilities | v0.2.0 | 0/2 | Not started | - |
| 10. Rollback | v0.2.0 | 0/1 | Not started | - |

---
*Roadmap created: 2026-01-30*
*Last updated: 2026-01-30*
