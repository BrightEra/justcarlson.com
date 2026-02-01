# Phase 10: Skills Layer - Research

**Researched:** 2026-01-31
**Domain:** Claude Code Skills and Hooks System
**Confidence:** HIGH

## Summary

Phase 10 implements optional Claude oversight wrapping existing justfile commands through the Claude Code skills system. Skills are markdown-based command definitions stored in `.claude/skills/<name>/SKILL.md` that provide human-in-the-loop interaction for publishing workflows, guided onboarding, and maintenance tasks.

The standard approach uses skill frontmatter to configure invocation control (`disable-model-invocation: true` for manual-only), lifecycle-scoped hooks for verification (stop hooks), and the `$ARGUMENTS` placeholder for parameter passing. Skills wrap—not duplicate—existing justfile recipes, maintaining the three-layer architecture: justfile (deterministic) → hooks (safety) → skills (optional oversight).

**Primary recommendation:** Use skill frontmatter hooks for verification (stop hooks with exit code 2 blocking), `disable-model-invocation: true` for all skills to ensure manual invocation only, and leverage existing bash scripts through justfile recipes rather than reimplementing logic in skills.

## Standard Stack

The established libraries/tools for skills and hooks in Claude Code:

### Core
| Library | Version | Purpose | Why Standard |
|---------|---------|---------|--------------|
| Claude Code | 2.1.0+ | CLI with skills/hooks system | Official Anthropic implementation, Agent Skills open standard |
| jq | 1.7+ | JSON parsing in hooks | Universal for hook stdin/stdout JSON handling |
| bash | 5.0+ | Hook command execution | Default shell for command hooks |

### Supporting
| Library | Version | Purpose | When to Use |
|---------|---------|---------|-------------|
| markdown-link-check | 6.0+ | Link validation | For /maintain link rot checking |
| lychee | 0.15+ | Fast link checker (Rust) | Alternative to markdown-link-check, faster for large sites |
| npm | 10.0+ | Dependency management | For checking outdated packages in /maintain |

### Alternatives Considered
| Instead of | Could Use | Tradeoff |
|------------|-----------|----------|
| Command hooks | Prompt hooks | Prompt hooks use LLM evaluation (slower, non-deterministic), command hooks are deterministic scripts |
| Command hooks | Agent hooks | Agent hooks spawn subagents with tools (multi-turn, up to 50 turns), command hooks are single-turn scripts |
| Skills | Commands (.claude/commands/) | Commands are legacy, skills support lifecycle hooks and supporting files |

**Installation:**
```bash
# No installation needed - skills are markdown files
# Claude Code discovers from .claude/skills/ automatically
```

## Architecture Patterns

### Recommended Project Structure
```
.claude/
├── settings.json           # Global hooks (Setup, PreToolUse safety)
├── settings.local.json     # Local config (vault path, gitignored)
├── hooks/
│   ├── git-safety.sh       # Global PreToolUse hook
│   └── unpublish.post.md   # Post-unpublish prompt hook
└── skills/
    ├── publish/
    │   └── SKILL.md        # /publish skill
    ├── install/
    │   └── SKILL.md        # /install skill
    ├── maintain/
    │   └── SKILL.md        # /maintain skill
    ├── list-posts/
    │   └── SKILL.md        # /list-posts skill
    └── unpublish/
        └── SKILL.md        # /unpublish skill
```

### Pattern 1: Manual-Only Skill with Stop Hook
**What:** Skill that wraps a justfile recipe with pre-flight checks and post-execution verification
**When to use:** Publishing workflows, deployments, or any operation requiring human confirmation and automated verification

**Example:**
```yaml
---
name: publish
description: Publish blog posts from Obsidian vault with human oversight
disable-model-invocation: true
hooks:
  Stop:
    - hooks:
        - type: command
          command: "$CLAUDE_PROJECT_DIR/.claude/hooks/verify-build.sh"
          timeout: 120
---

# Publish Blog Posts

Guide the user through publishing posts from Obsidian to the blog repo.

## Process

1. **List available posts** - run `just list-posts` to show unpublished posts
2. **Confirm selection** - ask user which posts to publish
3. **Show preview** - for each post, show frontmatter and first paragraph
4. **Execute publish** - run `just publish` for confirmed posts
5. **Verify build** - stop hook ensures build succeeds before finishing

## Important

- Use `just publish --dry-run` first to preview changes
- Always confirm before running actual publish
- Stop hook verifies build passes before Claude stops
```

### Pattern 2: Interactive Q&A Skill
**What:** Skill that guides user through multi-step setup with validation
**When to use:** Onboarding, configuration wizards, or guided troubleshooting

**Example:**
```yaml
---
name: install
description: Guide setup of Obsidian vault path, dependencies, and build verification
disable-model-invocation: true
hooks:
  Stop:
    - hooks:
        - type: command
          command: "$CLAUDE_PROJECT_DIR/.claude/hooks/verify-install.sh"
          timeout: 60
---

# Install and Setup

Interactive setup guide for new developers.

## Steps

1. **Obsidian vault** - run `just setup` to configure vault path
2. **Dependencies** - verify npm packages installed with `npm list`
3. **Build test** - run `npm run build` to verify setup works

## Verification (Stop Hook)

Stop hook checks:
- Vault path configured in .claude/settings.local.json
- node_modules exists
- Build passes without errors

If any check fails, block stop with exit code 2 and explain what's missing.
```

### Pattern 3: Report-Only Maintenance Skill
**What:** Skill that runs checks and reports issues without auto-fixing
**When to use:** Maintenance tasks where user should decide what to fix

**Example:**
```yaml
---
name: maintain
description: Check for outdated dependencies, lint issues, and broken links
disable-model-invocation: true
---

# Maintenance Checks

Run comprehensive health checks and report issues. User decides what to fix.

## Checks to Run

1. **Outdated packages** - `npm outdated` (show table)
2. **Lint** - `npm run lint` (show errors)
3. **Build** - `npm run build` (verify no errors)
4. **Content validation** - check blog post frontmatter
5. **Link rot** - run markdown-link-check on src/content/blog

## Reporting

Present findings in sections:
- **Critical**: Build failures, broken links
- **Warning**: Outdated major versions, lint errors
- **Info**: Outdated minor versions

Let user decide which issues to address.
```

### Pattern 4: Minimal Oversight Skill
**What:** Skill that wraps simple operations with confirmation
**When to use:** Destructive operations that need confirmation but minimal checking

**Example:**
```yaml
---
name: unpublish
description: Remove a post from blog repo (keeps Obsidian source)
disable-model-invocation: true
---

# Unpublish Post

Remove a published post from the blog repo.

## Process

1. **Confirm post** - verify user wants to unpublish $ARGUMENTS
2. **Run unpublish** - execute `just unpublish "$ARGUMENTS"`
3. **Remind** - tell user to update Obsidian status to prevent re-publishing

## Note

This only removes from blog repo - Obsidian source is unchanged.
```

### Anti-Patterns to Avoid

- **Duplicating justfile logic in skills:** Skills should `just <recipe>`, not reimplement bash logic
- **Auto-invocation for side effects:** Always use `disable-model-invocation: true` for publishing, deploying, or state-changing operations
- **Complex validation in skills:** Use stop hooks for verification, keep skill content focused on guiding user
- **Missing rollback:** Skills wrapping destructive operations should mention rollback or undo steps

## Don't Hand-Roll

Problems that look simple but have existing solutions:

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| Link checking markdown | Custom curl loop | markdown-link-check or lychee | Handles redirects, timeouts, retries, concurrent checking |
| Hook JSON parsing | grep/sed/awk | jq | Standard for JSON in/out, handles escaping, nested fields |
| Stop hook verification | Inline checks in skill | Command hook with exit code 2 | Deterministic, reusable, separates concerns |
| Dependency checking | Manual npm commands | npm outdated --json | Structured output, programmatic parsing |
| Interactive confirmation | Read user input in skill | Claude's natural conversation | Skills guide, Claude asks questions naturally |

**Key insight:** Skills are orchestration, not implementation. Wrap justfile recipes (which wrap scripts) rather than reimplementing logic. Stop hooks enforce deterministic verification after agentic guidance completes.

## Common Pitfalls

### Pitfall 1: Skill Auto-Invocation for Side Effects
**What goes wrong:** Claude automatically runs /publish because description matches conversation context, publishing posts without user confirmation
**Why it happens:** Default behavior is `disable-model-invocation: false`, allowing Claude to invoke skills based on description
**How to avoid:** Add `disable-model-invocation: true` to all skills with side effects (publish, deploy, unpublish)
**Warning signs:** Skills triggering unexpectedly during conversation

### Pitfall 2: Stop Hook Infinite Loops
**What goes wrong:** Stop hook always returns exit code 2 (block stop), Claude never completes, infinite loop
**Why it happens:** Hook doesn't check `stop_hook_active` field in JSON input
**How to avoid:** Check `stop_hook_active` in hook script, exit 0 if already true
**Warning signs:** "Stop hook prevented continuation" message appearing repeatedly

**Example prevention:**
```bash
#!/usr/bin/env bash
# Stop hook that checks build
INPUT=$(cat)
STOP_ACTIVE=$(echo "$INPUT" | jq -r '.stop_hook_active // false')

# Prevent infinite loop
if [[ "$STOP_ACTIVE" == "true" ]]; then
    exit 0
fi

# Run build check
if npm run build 2>&1 | grep -q "error"; then
    echo "Build failed - fix errors before stopping" >&2
    exit 2  # Block stop
fi

exit 0  # Allow stop
```

### Pitfall 3: Missing $CLAUDE_PROJECT_DIR in Hook Paths
**What goes wrong:** Hook script paths break when current directory changes
**Why it happens:** Relative paths in hook command field
**How to avoid:** Always use `"$CLAUDE_PROJECT_DIR"/path/to/hook.sh` for project-scoped hooks
**Warning signs:** Hooks work initially but fail after directory navigation

### Pitfall 4: Skill Duplication of Justfile Logic
**What goes wrong:** Skill reimplements publish.sh logic inline, diverges from actual implementation
**Why it happens:** Copying script logic into skill instructions
**How to avoid:** Skills should only call `just <recipe>`, never reimplement
**Warning signs:** Skill instructions contain bash loops, validation logic, or file operations

### Pitfall 5: Stop Hook Exit Code Misunderstanding
**What goes wrong:** Hook exits 2 expecting to show message to Claude, but nothing happens
**Why it happens:** Exit code 2 stderr only shown to Claude for blocking events (PreToolUse, UserPromptSubmit, Stop, SubagentStop, PermissionRequest)
**How to avoid:** For Stop hooks, exit 0 with JSON `{"decision": "block", "reason": "..."}` OR exit 2 with stderr message
**Warning signs:** Hook blocks but Claude doesn't receive feedback

## Code Examples

Verified patterns from official sources:

### Stop Hook with Build Verification
```bash
#!/usr/bin/env bash
# Source: Claude Code Hooks Reference (https://code.claude.com/docs/en/hooks)
# .claude/hooks/verify-build.sh

set -euo pipefail
INPUT=$(cat)

# Prevent infinite loop
STOP_ACTIVE=$(echo "$INPUT" | jq -r '.stop_hook_active // false')
if [[ "$STOP_ACTIVE" == "true" ]]; then
    exit 0
fi

# Run build
if ! npm run build 2>&1 | tee /tmp/build.log; then
    echo "Build failed. Fix errors before stopping:" >&2
    tail -20 /tmp/build.log >&2
    exit 2  # Block stop
fi

exit 0  # Allow stop
```

### Skill with Lifecycle-Scoped Hook
```yaml
# Source: Claude Code Skills Documentation (https://code.claude.com/docs/en/skills)
---
name: publish
description: Publish blog posts with oversight
disable-model-invocation: true
hooks:
  Stop:
    - hooks:
        - type: command
          command: "$CLAUDE_PROJECT_DIR/.claude/hooks/verify-build.sh"
          timeout: 120
---

Guide user through publishing workflow using `just publish`.
```

### PreToolUse Hook for Git Safety
```bash
# Source: Existing codebase (.claude/hooks/git-safety.sh)
#!/usr/bin/env bash
set -euo pipefail

INPUT=$(cat)
COMMAND=$(echo "$INPUT" | jq -r '.tool_input.command // ""')

# Block dangerous operations
if [[ "$COMMAND" =~ git[[:space:]]+push[[:space:]]+(.*[[:space:]])?--force ]]; then
    echo "Force push detected - blocked" >&2
    echo "Force pushing overwrites remote history" >&2
    exit 2
fi

exit 0
```

### Setup Hook with Environment Persistence
```bash
# Source: Claude Code Hooks Reference (https://code.claude.com/docs/en/hooks)
#!/usr/bin/env bash
# SessionStart hook that sets environment variables

if [ -n "$CLAUDE_ENV_FILE" ]; then
  echo 'export NODE_ENV=production' >> "$CLAUDE_ENV_FILE"
  echo 'export PATH="$PATH:./node_modules/.bin"' >> "$CLAUDE_ENV_FILE"
fi

exit 0
```

### Maintenance Check (Report-Only Pattern)
```bash
#!/usr/bin/env bash
# Pattern for /maintain skill - check and report, don't auto-fix

echo "=== Dependency Check ==="
npm outdated --json | jq -r 'to_entries[] | "\(.key): \(.value.current) → \(.value.latest)"'

echo ""
echo "=== Lint Check ==="
npm run lint || echo "Lint errors found (see above)"

echo ""
echo "=== Link Check ==="
npx markdown-link-check src/content/blog/*.md --quiet

exit 0  # Always report, never block
```

## State of the Art

| Old Approach | Current Approach | When Changed | Impact |
|--------------|------------------|--------------|--------|
| Commands (.claude/commands/*.md) | Skills (.claude/skills/*/SKILL.md) | Claude Code 2.0 (2025) | Skills support lifecycle hooks, supporting files, and directory structure |
| Prompt hooks only | Command, prompt, and agent hooks | Claude Code 2.1 (Jan 2026) | Enables deterministic validation alongside AI evaluation |
| Manual permission prompts | PreToolUse hooks with auto-approval | Claude Code 2.0 | Hooks can approve/deny/modify tool calls programmatically |
| Global hooks only | Skill/agent-scoped hooks | Claude Code 2.1 | Hooks can be scoped to component lifetime, auto-cleanup |

**Deprecated/outdated:**
- `.claude/commands/` - Still works but skills are recommended for new features (lifecycle hooks, supporting files)
- `decision: "approve"` in PreToolUse hooks - Use `permissionDecision: "allow"` in `hookSpecificOutput` instead
- `decision: "block"` in PreToolUse hooks - Use `permissionDecision: "deny"` in `hookSpecificOutput` instead

## Open Questions

Things that couldn't be fully resolved:

1. **Plugin-installed stop hooks exit code 2 behavior**
   - What we know: GitHub issue #10412 reports stop hooks with exit code 2 fail when installed via plugins but work from .claude/hooks/
   - What's unclear: Whether this is resolved in Claude Code 2.1+ or still requires workaround
   - Recommendation: Install stop hooks in .claude/hooks/ directory, not via plugin system

2. **Best link checker for this use case**
   - What we know: markdown-link-check (npm) and lychee (Rust) both work, lychee is faster
   - What's unclear: Whether lychee installation is worth the complexity vs npm-based tool
   - Recommendation: Start with markdown-link-check (already in npm ecosystem), switch to lychee if performance matters

3. **Setup hook frequency concerns**
   - What we know: Setup hooks run on every session start (startup, resume, clear, compact)
   - What's unclear: Whether config-only checks (vault path) are fast enough to avoid perceived slowdown
   - Recommendation: Keep setup hook minimal (config check only), move health checks to /maintain skill

## Sources

### Primary (HIGH confidence)
- [Claude Code Skills Documentation](https://code.claude.com/docs/en/skills) - Skill structure, frontmatter, lifecycle hooks
- [Claude Code Hooks Reference](https://code.claude.com/docs/en/hooks) - Hook events, JSON I/O, exit codes
- [OpenCode Skills Documentation](https://opencode.ai/docs/skills) - Agent Skills open standard, permissions
- Existing codebase scripts (setup.sh, publish.sh, list-posts.sh, unpublish.sh) - Current implementation patterns

### Secondary (MEDIUM confidence)
- [Claude Code Hooks Guide](https://code.claude.com/docs/en/hooks-guide) - Best practices, troubleshooting, examples
- [Stop Speedrunning Claude Code](https://paddo.dev/blog/stop-speedrunning-claude-code/) - Human-in-the-loop workflow patterns (2026)
- [Claude Code 2026 SDLC Workflow](https://developersvoice.com/blog/ai/claude_code_2026_end_to_end_sdlc/) - Plan mode, feedback loop patterns
- [Claude Code Showcase Repository](https://github.com/ChrisWiles/claude-code-showcase) - Skills and hooks examples
- [Claude Code Hooks Mastery](https://github.com/disler/claude-code-hooks-mastery) - Hook patterns, deterministic control

### Tertiary (LOW confidence)
- [markdown-link-check npm](https://www.npmjs.com/package/markdown-link-check) - Link validation tool
- [lychee link checker](https://lychee.cli.rs/) - Fast Rust-based alternative
- [just-claude npm](https://github.com/tombedor/just-claude) - Tool for creating skills from justfile recipes
- [GitHub Issue #10412](https://github.com/anthropics/claude-code/issues/10412) - Plugin stop hook bug (2025, status unclear)

## Metadata

**Confidence breakdown:**
- Standard stack: HIGH - Official Claude Code documentation and Agent Skills standard
- Architecture: HIGH - Verified from official docs and working codebase examples
- Pitfalls: MEDIUM - Documented in official troubleshooting, some from community experience
- Stop hook plugin issue: LOW - GitHub issue from Oct 2025, unclear if resolved in 2.1

**Research date:** 2026-01-31
**Valid until:** 2026-02-28 (30 days - stable API, minor updates expected)
