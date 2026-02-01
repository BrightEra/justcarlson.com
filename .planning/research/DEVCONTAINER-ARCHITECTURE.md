# Architecture: Dev Container Integration with Justfile Workflow

**Project:** justcarlson.com portable setup
**Researched:** 2026-01-31
**Focus:** Dev container + bootstrap integration with three-layer architecture

## Executive Summary

Dev containers integrate cleanly with justfile-based workflows through the `postCreateCommand` lifecycle hook. The existing three-layer architecture (justfile recipes -> Claude hooks -> Claude skills) requires minimal changes: add a single `bootstrap` recipe and a `.devcontainer/` directory.

**Key insight:** The `postCreateCommand` runs after container creation with full user context, making it the right place to call `just bootstrap`. The bootstrap recipe delegates to existing scripts, preserving the established pattern.

## Existing Architecture

```
Layer 1: justfile           Layer 2: Claude hooks      Layer 3: Claude skills
(command runner)            (safety/automation)         (human-in-the-loop)
        |                           |                          |
        v                           v                          v
+---------------+            +---------------+           +---------------+
| just setup    |            | git-safety.sh |           | /install      |
| just publish  |            | verify-build  |           | /publish      |
| just preview  |            | verify-install|           | /unpublish    |
+---------------+            +---------------+           +---------------+
        |
        v
+---------------+
| scripts/*.sh  |  (business logic)
+---------------+
```

**Current setup flow:**
1. Developer runs `just setup` (Layer 1)
2. `setup.sh` prompts for Obsidian vault path (scripts/)
3. Config saved to `.claude/settings.local.json` (gitignored)
4. SessionStart hook checks config exists (Layer 2)

## Proposed Architecture

```
+-------------------+
| .devcontainer/    |  NEW: Container definition
| devcontainer.json |
+-------------------+
        |
        | postCreateCommand: "just bootstrap"
        v
+---------------+
| just bootstrap|  NEW: Idempotent setup recipe
+---------------+
        |
        | delegates to
        v
+---------------+
| just setup    |  EXISTING: Vault configuration
| npm install   |  EXISTING: Dependencies
| npm run build |  EXISTING: Verify build
+---------------+
```

## File Locations

### New Files

| File | Purpose | Notes |
|------|---------|-------|
| `.devcontainer/devcontainer.json` | Container definition | Standard location, auto-detected by VS Code/Codespaces |
| `.devcontainer/Dockerfile` | Custom image (optional) | Only if base image needs modification |

### Modified Files

| File | Change | Notes |
|------|--------|-------|
| `justfile` | Add `bootstrap` recipe | Calls npm install, delegates to setup, runs build |
| `.gitignore` | No change needed | `.claude/settings.local.json` already gitignored |

### Unchanged Files

| File | Reason |
|------|--------|
| `scripts/setup.sh` | Already idempotent (checks existing config) |
| `.claude/settings.json` | Hooks already work in containers |
| `.claude/hooks/*` | No container-specific changes needed |
| `.claude/skills/*` | `/install` skill still valid for manual setup |

## Dev Container Configuration

### Recommended devcontainer.json

```json
{
  "name": "justcarlson.com",
  "image": "mcr.microsoft.com/devcontainers/javascript-node:22-bookworm",
  "features": {
    "ghcr.io/jsburckhardt/devcontainer-features/just:1": {}
  },
  "postCreateCommand": "just bootstrap",
  "forwardPorts": [4321],
  "customizations": {
    "vscode": {
      "extensions": [
        "astro-build.astro-vscode",
        "biomejs.biome"
      ]
    }
  }
}
```

### Lifecycle Hook Selection

| Hook | When | Why Not Use |
|------|------|-------------|
| `onCreateCommand` | Before user context available | No access to user secrets/config |
| `postCreateCommand` | After container assigned to user | **Recommended** - has full context |
| `postStartCommand` | Every container start | Too frequent for npm install |

**Decision:** Use `postCreateCommand` because:
- Runs once after container creation
- Has access to user context (for vault path prompts if needed)
- Runs before VS Code connects (clean startup)

Source: [Dev Container metadata reference](https://containers.dev/implementors/json_reference/)

## Bootstrap Recipe Design

### Justfile Addition

```just
# === Bootstrap (Dev Container / Fresh Clone) ===

# Bootstrap development environment (idempotent)
bootstrap:
    @echo "Bootstrapping development environment..."
    npm install
    @echo ""
    @echo "Dependencies installed. Run 'just setup' to configure Obsidian vault."
    @echo "Or use /install skill in Claude Code for guided setup."
```

### Why This Approach

1. **Separation of concerns:**
   - `bootstrap`: Machine setup (npm install, env check)
   - `setup`: User configuration (vault path)
   - `/install`: Human-guided full setup

2. **Idempotency:**
   - `npm install` is already idempotent (checks package-lock.json)
   - `setup.sh` already checks for existing config

3. **No vault in container:**
   - Dev containers cannot access host Obsidian vault
   - Bootstrap skips vault config (handled manually or via `/install`)
   - This is intentional: publishing requires vault access

### Alternative: Non-Interactive Bootstrap

For fully automated container setup (e.g., CI):

```just
# Bootstrap without vault configuration (for CI/containers)
bootstrap-ci:
    npm install
    npm run build:check
```

## Integration Points

### 1. Container -> Justfile

```
devcontainer.json
    postCreateCommand: "just bootstrap"
                            |
                            v
                      justfile::bootstrap
                            |
                            v
                      npm install
```

**Confidence:** HIGH (standard pattern, verified in official docs)

### 2. Bootstrap -> Existing Scripts

```
justfile::bootstrap
        |
        +-> npm install (direct)
        |
        +-> (optional) justfile::setup
                    |
                    v
              scripts/setup.sh
```

**Confidence:** HIGH (existing scripts already support this)

### 3. Claude Hooks in Container

```
.claude/settings.json (committed)
        |
        v
SessionStart hook checks vault config
        |
        +-> If missing: "Run /install for guided setup"
        |
        +-> If present: Silent (vault configured)
```

**Confidence:** HIGH (hooks are path-relative, work in containers)

### 4. Skills in Container

```
/install skill
    |
    +-> Runs just setup (vault config)
    +-> Runs npm install
    +-> Runs npm run build
    +-> verify-install.sh hook validates
```

**Confidence:** HIGH (skill is shell-based, container-agnostic)

## Implementation Order

### Phase 1: Bootstrap Recipe (Minimal Changes)

1. Add `bootstrap` recipe to justfile
2. Test locally: `just bootstrap` should be idempotent

### Phase 2: Dev Container Configuration

1. Create `.devcontainer/devcontainer.json`
2. Use Node 22 base image with just feature
3. Set `postCreateCommand: "just bootstrap"`
4. Test in VS Code: Rebuild Container

### Phase 3: Verification

1. Confirm hooks work in container
2. Confirm `/install` skill works
3. Document container limitations (no vault access)

## Container Limitations

| Feature | Works in Container | Notes |
|---------|-------------------|-------|
| `just preview` | Yes | Port 4321 forwarded |
| `just build` | Yes | Full build works |
| `just lint` | Yes | All tooling available |
| `just publish` | Partial | Requires vault mount or skip |
| `just setup` | Partial | Can configure, but vault inaccessible |
| `/install` | Partial | Same as setup |

**Vault access options:**
1. **None (default):** Container for code review/build only
2. **Volume mount:** Add vault path to devcontainer.json (user-specific)
3. **Codespaces secret:** Store vault content as secret (complex)

**Recommendation:** Accept that dev containers are for code work, not publishing. Vault access is a local-machine concern.

## Patterns to Follow

### Marker File for Complex Setup

If bootstrap becomes more complex, use marker files:

```bash
# In bootstrap script
MARKER=".devcontainer/.bootstrap-complete"
if [[ -f "$MARKER" ]]; then
    echo "Already bootstrapped"
    exit 0
fi
# ... do setup ...
touch "$MARKER"
```

Source: [Ken Muse - DevContainer initializeCommand](https://www.kenmuse.com/blog/new-devcontainer-initializecommand/)

### Feature Selection

For `just` command runner, use community feature:

```json
"features": {
    "ghcr.io/jsburckhardt/devcontainer-features/just:1": {}
}
```

Source: [jsburckhardt/devcontainer-features](https://github.com/jsburckhardt/devcontainer-features)

**Confidence:** MEDIUM (community feature, not official, but widely used)

## Anti-Patterns to Avoid

### 1. Installing Just via postCreateCommand

**Bad:**
```json
"postCreateCommand": "curl -sSf https://just.systems/install.sh | bash && just bootstrap"
```

**Why bad:** Duplicates work that features handle; less maintainable.

**Good:** Use the just feature, call `just bootstrap` only.

### 2. Running Setup in postCreateCommand

**Bad:**
```json
"postCreateCommand": "just bootstrap && just setup"
```

**Why bad:** `setup` is interactive; fails in non-TTY context.

**Good:** Bootstrap installs deps; user runs `/install` or `just setup` manually.

### 3. Assuming Vault Access

**Bad:** Hard-coding vault path in devcontainer.json

**Good:** Accept that vault configuration is local/manual.

## Confidence Assessment

| Component | Confidence | Source |
|-----------|------------|--------|
| postCreateCommand usage | HIGH | [Official dev container spec](https://containers.dev/implementors/json_reference/) |
| Just feature availability | MEDIUM | [Community feature repo](https://github.com/jsburckhardt/devcontainer-features) |
| Justfile integration | HIGH | Direct observation of existing justfile |
| Hook compatibility | HIGH | Hooks are shell scripts, container-agnostic |
| Skill compatibility | HIGH | Skills are markdown + shell, container-agnostic |

## Sources

- [Dev Container metadata reference](https://containers.dev/implementors/json_reference/) - Lifecycle hooks and configuration
- [Feature authoring best practices](https://containers.dev/guide/feature-authoring-best-practices) - Idempotency patterns
- [jsburckhardt/devcontainer-features](https://github.com/jsburckhardt/devcontainer-features) - Just command runner feature
- [Astro devcontainer example](https://github.com/withastro/astro/blob/main/.devcontainer/basics/devcontainer.json) - Astro-specific patterns
- [Ken Muse - DevContainer initializeCommand](https://www.kenmuse.com/blog/new-devcontainer-initializecommand/) - Marker file pattern

---

*Architecture research: 2026-01-31*
