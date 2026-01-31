---
status: complete
phase: 08-core-publishing
source: [08-01-SUMMARY.md, 08-02-SUMMARY.md, 08-03-SUMMARY.md]
started: 2026-01-31T18:30:00Z
updated: 2026-01-31T19:45:00Z
---

## Current Test

[testing complete]

## Tests

### 1. Post Discovery from Obsidian
expected: Running `just publish` reads vault path from config and finds all posts with `status: - Published` in YAML frontmatter. Posts appear sorted by pubDatetime (newest first).
result: issue
reported: "ANSI escape codes printed literally: Found \033[0;32m1\033[0m post(s) instead of colored text"
severity: cosmetic

### 2. Interactive Post Selection
expected: After discovery, you see an interactive multi-select UI (gum choose, fzf, or numbered list). You can select multiple posts to publish. Already-identical posts are excluded; changed posts show "(update)" marker.
result: pass

### 3. Frontmatter Validation Errors
expected: If a selected post is missing title, pubDatetime, or description, clear error messages show which fields are missing. All posts validated before showing errors (not fail-fast).
result: pass

### 4. Partial Valid Posts Prompt
expected: When some posts valid and some invalid, you're prompted "X of Y posts are valid. Publish the valid ones? [Y/n]" to continue with valid subset.
result: pass

### 5. Wiki-Link Image Conversion
expected: Obsidian `![[image.png]]` syntax converted to markdown `![](/assets/blog/slug/image.png)`. Images copied from vault Attachments to public/assets/blog/[slug]/.
result: pass

### 6. Post Copied to Year Directory
expected: Valid posts are copied to `src/content/blog/YYYY/` where YYYY is extracted from pubDatetime. Content is transformed with updated image paths.
result: pass

### 7. Lint Verification Before Commit
expected: `npm run lint` runs after files copied. If lint fails, you see error output and retry prompt. After 3 failures, rollback removes created files.
result: pass

### 8. Build Verification Before Push
expected: After commits, `npm run build` runs. If build fails, you see error output and retry prompt. Commits are not pushed until build passes.
result: issue
reported: "Script exits with error after commit, never reaches build step. lint-staged returns non-zero despite successful commit, killing pipeline."
severity: blocker

### 9. Conventional Commit Messages
expected: Each post gets its own commit with message like `docs(blog): add {title}` for new posts or `docs(blog): update {title}` for updates.
result: pass

### 10. Interactive Push Confirmation
expected: After successful build, you're prompted to confirm before pushing to remote. Can decline to keep changes local.
result: skipped
reason: Blocked by Test 8 (pipeline exits before reaching push). Also, build fails due to schema validation (author array, heroImage null) - see Test 8 gap.

### 11. Dry-Run Mode
expected: Running `just publish --dry-run` shows complete preview of all planned actions (discovery, validation, copy, commits, push) without executing any mutations.
result: issue
reported: "Dry-run prompts for input (Publish the valid ones? [Y/n]) instead of auto-continuing. Should preview all actions without prompts."
severity: major

### 12. No Posts Ready Message
expected: When no posts have `status: - Published`, friendly message explains how to mark posts ready and exits gracefully.
result: pass

## Summary

total: 12
passed: 8
issues: 3
pending: 0
skipped: 1

## Gaps

- truth: "Post count displayed with colored text"
  status: failed
  reason: "User reported: ANSI escape codes printed literally: Found \\033[0;32m1\\033[0m post(s) instead of colored text"
  severity: cosmetic
  test: 1
  root_cause: ""
  artifacts: []
  missing: []
  debug_session: ""

- truth: "Build verification runs after commits, before push"
  status: failed
  reason: "User reported: Script exits with error after commit, never reaches build step. lint-staged returns non-zero despite successful commit, killing pipeline. Additionally, build fails due to schema validation (author as array, heroImage as null) - validation doesn't check type correctness."
  severity: blocker
  test: 8
  root_cause: ""
  artifacts: []
  missing: []
  debug_session: ""

- truth: "Dry-run shows complete preview without prompts or mutations"
  status: failed
  reason: "User reported: Dry-run prompts for input (Publish the valid ones? [Y/n]) instead of auto-continuing. Should preview all actions without prompts."
  severity: major
  test: 11
  root_cause: ""
  artifacts: []
  missing: []
  debug_session: ""
