---
status: complete
phase: 19-justfile-hero-image-support
source: 19-01-SUMMARY.md, 19-02-SUMMARY.md
started: 2026-02-02T07:00:00Z
updated: 2026-02-02T07:10:00Z
---

## Current Test

[testing complete]

## Tests

### 1. Hero Image Field Preservation
expected: When publishing a post with heroImage, heroImageAlt, and heroImageCaption fields, all three fields appear in the published frontmatter with their values intact.
result: issue
reported: "heroImage path not transformed - still shows [[forrest-gump-quote.png]] instead of /assets/blog/hello-world/forrest-gump-quote.png. Warning: Image not found during publish. 404 errors in dev server."
severity: blocker

### 2. Hero Image Path Transformation
expected: The heroImage path is transformed from Obsidian format (e.g., "Attachments/image.jpg") to web format (e.g., "/assets/blog/slug/image.jpg") in published frontmatter.
result: issue
reported: "failed, same issue - heroImage still shows [[forrest-gump-quote.png]] not transformed"
severity: blocker

### 3. Hero Image Asset Copying
expected: The hero image file is copied to /public/assets/blog/{slug}/ alongside inline images.
result: issue
reported: "failed, same issue - image not copied because wiki-link not resolved"
severity: blocker

### 4. Build Success with Hero Image
expected: Running `npm run build` succeeds without YAML parse errors or LocalImageUsedWrongly errors when posts have hero images.
result: pass

### 5. Empty Hero Image Field Cleanup
expected: Publishing a post with empty heroImageAlt or heroImageCaption fields results in those empty fields being stripped from published frontmatter (not left as empty strings).
result: pass

## Summary

total: 5
passed: 2
issues: 3
pending: 0
skipped: 0

## Gaps

- truth: "heroImage field value preserved and transformed correctly in published frontmatter"
  status: failed
  reason: "User reported: heroImage path not transformed - still shows [[forrest-gump-quote.png]] instead of /assets/blog/hello-world/forrest-gump-quote.png. Warning: Image not found during publish. 404 errors in dev server."
  severity: blocker
  test: 1
  root_cause: ""
  artifacts: []
  missing: []
  debug_session: ""
