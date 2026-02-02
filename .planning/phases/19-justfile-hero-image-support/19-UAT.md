---
status: complete
phase: 19-justfile-hero-image-support
source: 19-01-SUMMARY.md, 19-02-SUMMARY.md, 19-03-SUMMARY.md
started: 2026-02-02T07:15:00Z
updated: 2026-02-02T07:25:00Z
---

## Current Test

## Current Test

[testing complete]

## Tests

### 1. Hero Image Wiki-Link Transformation
expected: When publishing a post with heroImage in wiki-link format (e.g., heroImage: "[[forrest-gump-quote.png]]"), the path is transformed to web format (e.g., /assets/blog/hello-world/forrest-gump-quote.png) in published frontmatter.
result: pass

### 2. Hero Image Asset Copying
expected: The hero image file is copied to /public/assets/blog/{slug}/ alongside inline images when publishing.
result: pass

### 3. Hero Image Alt and Caption Fields
expected: When publishing a post with heroImageAlt and heroImageCaption fields, all fields appear in the published frontmatter with their values intact.
result: pass

### 4. Empty Hero Image Field Cleanup
expected: Publishing a post with empty heroImageAlt or heroImageCaption fields results in those empty fields being stripped from published frontmatter (not left as empty strings).
result: pass

### 5. Build Success with Hero Image
expected: Running `npm run build` succeeds without errors when posts have hero images in wiki-link format.
result: pass

## Summary

total: 5
passed: 5
issues: 0
pending: 0
skipped: 0

## Gaps

[none]
