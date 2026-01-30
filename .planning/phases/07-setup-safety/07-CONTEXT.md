# Phase 7: Setup & Safety - Context

**Gathered:** 2026-01-30
**Status:** Ready for planning

<domain>
## Phase Boundary

Justfile foundation with interactive configuration for Obsidian vault path, plus Claude hooks that block dangerous git operations. Users can run `just setup` to configure, and destructive git commands are automatically blocked.

</domain>

<decisions>
## Implementation Decisions

### Setup interaction
- Auto-detect Obsidian vaults by searching home directory for `.obsidian` folders
- If single vault found: show path with Y/n confirmation ("Found vault at /path. Use this? [Y/n]")
- If multiple vaults found: show numbered list for user to pick from
- If no vault found: prompt for manual path entry

### Git blocking behavior
- Block destructive operations only: `--force`, `reset --hard`, `checkout .`, `clean -f`
- Do NOT block risky-but-useful operations like rebase or branch -D
- No bypass mechanism — use terminal directly for emergencies
- Log blocked attempts to a file for review

### Config file location
- Store config in `.claude/settings.local.json` in project root (not user home)
- Gitignore the file — local config stays local, each machine runs setup
- Use nested structure: `{"paths": {"obsidianVault": "/path"}}`
- If config missing when running other recipes: auto-trigger setup inline

### Error messaging
- Professional and direct tone (not cutesy, not terse)
- Always include the exact command to fix the issue
- Use colored output: red for errors, yellow for warnings
- Show success messages (not silent): "✓ Setup complete. Vault: /path"

### Claude's Discretion
- Exact wording of blocked operation messages
- Log file location and format
- Search depth/performance tradeoffs for vault detection
- How to handle edge cases (permissions, symlinks, etc.)

</decisions>

<specifics>
## Specific Ideas

No specific requirements — open to standard approaches

</specifics>

<deferred>
## Deferred Ideas

None — discussion stayed within phase scope

</deferred>

---

*Phase: 07-setup-safety*
*Context gathered: 2026-01-30*
