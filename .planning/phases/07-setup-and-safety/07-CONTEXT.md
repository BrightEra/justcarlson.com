# Phase 7: Setup & Safety - Context

**Gathered:** 2026-01-30
**Status:** Ready for planning

<domain>
## Phase Boundary

Skills have a configured Obsidian path and git operations are protected. First-run configuration stores the vault path, and dangerous git operations are blocked throughout the workflow.

</domain>

<decisions>
## Implementation Decisions

### Setup flow
- Search for `.obsidian` folders automatically; if not found, prompt user for path
- If multiple vaults found, list them and let user pick
- Validate that `blog/` subfolder exists in the selected vault
- Re-running `/setup-blog` always overwrites existing config (no confirmation)

### Missing setup behavior
- Brief message: "Setup required. Run /setup-blog first?"
- Offer to run setup immediately, then auto-continue the original skill
- No explanatory text needed — keep it short

### Blocked operations
- Block: `git push --force`, `git reset --hard`, `git clean -f`, `git stash drop`, `git stash clear`, `git branch -D`
- Use git hooks (`.githooks/` committed to repo, not `.git/hooks/`)
- `/setup-blog` auto-configures `core.hooksPath` to `.githooks`
- Bypass with inline comment: `# UNSAFE` at end of command
- No branch protection — just destructive operations
- No separate documentation — hooks are self-documenting

### Config storage
- Store in `.claude/settings.local.json` (gitignored)
- Include both vault path and blog subfolder name

### Claude's Discretion
- Key structure in settings.local.json
- Error logging approach when blocked operations are attempted
- Whether to block rebase operations

</decisions>

<specifics>
## Specific Ideas

- Hooks protect against Claude/script errors, not user mistakes — user doesn't interact with block messages
- Setup should feel like a one-time thing that "just works" after the first run

</specifics>

<deferred>
## Deferred Ideas

None — discussion stayed within phase scope

</deferred>

---

*Phase: 07-setup-and-safety*
*Context gathered: 2026-01-30*
