---
status: resolved
trigger: "publish-lint-staged-exit-code: just publish hello-world fails with exit code 1 on line 43"
created: 2026-01-31T00:00:00Z
updated: 2026-01-31T00:04:00Z
---

## Current Focus

hypothesis: CONFIRMED - bash arithmetic `((commit_count++))` with `set -e` causes exit when commit_count is 0
test: Applied fix and verified with isolated bash test + git commit test
expecting: Script should complete successfully with pre-increment
next_action: COMPLETE - Archive session

## Symptoms

expected: `just publish hello-world` should complete successfully after copying and committing a blog post
actual: Recipe fails with exit code 1 on line 43, even though the commit message shows "Committed: docs(blog): add Hello World"
errors: `lint-staged could not find any staged files matching configured tasks.` then `error: Recipe publish failed on line 43 with exit code 1`
reproduction: Run `just unpublish hello-world` then `just publish hello-world`
started: Current issue - appears to be a bug in the publish workflow

## Eliminated

- hypothesis: lint-staged exit code causing failure
  evidence: Tested `npx lint-staged --allow-empty` with only .md file staged - exits with code 0, just prints warning message
  timestamp: 2026-01-31T00:02:00Z

- hypothesis: pre-commit hook failing
  evidence: The commit message "Committed: docs(blog): add Hello World" appears in output, proving the git commit succeeded
  timestamp: 2026-01-31T00:02:00Z

## Evidence

- timestamp: 2026-01-31T00:01:00Z
  checked: justfile line 43
  found: Line 43 is `./scripts/publish.sh {{args}}` - just invokes publish.sh
  implication: The exit code 1 comes from publish.sh, not justfile directly

- timestamp: 2026-01-31T00:01:00Z
  checked: scripts/publish.sh
  found: Uses `set -euo pipefail` at line 3, meaning any non-zero exit propagates
  implication: Any command returning non-zero will exit the script

- timestamp: 2026-01-31T00:02:00Z
  checked: scripts/publish.sh line 1034
  found: `((commit_count++))` is a post-increment operator that returns the OLD value
  implication: When commit_count is 0, `((0++))` returns 0, which bash treats as false (exit code 1)

- timestamp: 2026-01-31T00:02:00Z
  checked: bash arithmetic with set -e
  found: `bash -c 'set -e; commit_count=0; ((commit_count++)); echo "success"'` exits with code 1
  implication: This is the root cause - the first commit triggers set -e exit due to post-increment returning 0

- timestamp: 2026-01-31T00:02:00Z
  checked: Output ordering in symptoms
  found: Order is: lint-staged warning -> "Committed:" -> exit code 1
  implication: The script executes: git commit (prints lint-staged warning) -> echo "Committed" -> ((commit_count++)) EXIT

- timestamp: 2026-01-31T00:03:00Z
  checked: Post-fix verification (isolated test)
  found: `bash -c 'set -e; commit_count=0; ((++commit_count)); echo "success with commit_count=$commit_count"'` exits with code 0
  implication: Pre-increment fix works correctly

- timestamp: 2026-01-31T00:03:00Z
  checked: Other occurrences in scripts/publish.sh
  found: Lines 183 and 210 also use `((attempt++))` but attempt starts at 1, not 0 - technically safe
  implication: Changed to pre-increment for consistency and defensive coding

- timestamp: 2026-01-31T00:04:00Z
  checked: Git commit test with markdown-only file
  found: `git commit -m "test"` with only .md file staged completes with exit code 0, lint-staged warning is printed but doesn't cause failure
  implication: Full git workflow works correctly after fix

## Resolution

root_cause: |
  In scripts/publish.sh line 1034, `((commit_count++))` uses post-increment which returns the OLD value.
  When publishing the first post, commit_count starts at 0. `((0++))` increments to 1 but RETURNS 0.
  In bash arithmetic, returning 0 is treated as false (exit code 1).
  With `set -e` enabled (line 3), this causes the script to exit immediately.

  The lint-staged warning is a red herring - it's just a printed message, not the failure cause.
  The actual failure is the bash arithmetic expression with set -e.

fix: |
  Changed all post-increment expressions to pre-increment:
  - Line 1034: `((commit_count++))` -> `((++commit_count))`
  - Line 183: `((attempt++))` -> `((++attempt))`
  - Line 210: `((attempt++))` -> `((++attempt))`

  Pre-increment returns the NEW value, which is always >= 1 (truthy), preventing set -e from triggering.

verification: |
  1. Isolated bash test confirms pre-increment with set -e works correctly
  2. Git commit with markdown-only file completes with exit code 0
  3. Lint-staged warning is printed but does not cause script failure
  4. All affected post-increment expressions updated for consistency

files_changed:
  - scripts/publish.sh
