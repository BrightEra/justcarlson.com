# Research Summary: v0.3.0 Polish & Portability

**Project:** justcarlson.com
**Domain:** Astro static blog with development workflow automation
**Researched:** 2026-01-31
**Milestone:** v0.3.0 Polish & Portability
**Confidence:** HIGH

## Executive Summary

v0.3.0 focuses on making the blog repository portable and polished for contributors. The existing stack (Astro 5, Tailwind CSS 4, justfile-based automation) is complete; this milestone adds portability infrastructure with minimal additions. The core insight from research: **layered architecture already works**. The three-layer pattern (justfile commands, Claude hooks, skills) is proven. Now we add bootstrap automation and dev container support to eliminate "works on my machine" issues.

The recommended approach: Add two configuration files (devcontainer.json, .nvmrc), extend the existing justfile with an idempotent bootstrap recipe, and update documentation. No new runtime dependencies. The main risk is hardcoded path assumptions breaking in containerized environments, mitigated by detecting container mode and providing mock/graceful-degradation modes for vault-dependent commands.

Critical success factor: Bootstrap must be idempotent (run twice without breaking). Dev container must handle node_modules performance (named volume mount). Vault paths must gracefully degrade when unavailable (container contributors without Obsidian setup).

## Key Findings

### Recommended Stack

**No new runtime dependencies needed.** Existing stack is complete (Astro 5.16.6, Tailwind CSS 4, sharp, Node 22 LTS). This milestone adds **configuration-only** infrastructure.

**Core additions:**
- **devcontainer.json**: Single file using Microsoft's official typescript-node:22 base image with just feature from ghcr.io/guiyomh/features/just:0
- **.nvmrc**: Pin Node.js 22 for nvm/fnm/mise auto-switching
- **just bootstrap recipe**: Idempotent one-command setup (npm install + just setup with guards)

**Rationale:** Dev containers eliminate environment setup friction. Node version lock prevents "works on my machine" version issues. Bootstrap recipe provides single entry point for new contributors.

**Confidence:** HIGH — based on official VS Code devcontainer docs and just manual.

### Expected Features

**Must have (table stakes):**
- `just bootstrap` command for one-step setup — users expect modern projects to have single-command bootstrap
- Idempotent bootstrap (run twice = safe) — standard expectation for setup scripts
- Dev container configuration — increasingly expected in 2025/2026 for open source projects
- Node version file (.nvmrc) — prevents version-related issues across contributors
- First-run documentation in README — users expect clear "Quick Start" section

**Should have (differentiators):**
- Zero-config preview mode (site works without vault) — allows exploration before full setup
- Container-aware vault detection — gracefully handles missing Obsidian vault in container environments
- Progress indicators in bootstrap — clear feedback during multi-step setup
- Next-step suggestions after setup — guides new users on "what to run next"

**Defer (v2+):**
- Health check command (`just doctor`) — helpful but not essential for MVP
- Non-interactive setup flags — automation nice-to-have, not critical for initial release
- Multiple vault support — YAGNI for personal blog
- Devcontainer Dockerfile customization — pre-built image sufficient

### Architecture Approach

**Three-layer architecture remains unchanged.** This milestone adds bootstrap orchestration that sits alongside existing layers without modifying core patterns.

**Major components:**
1. **Bootstrap layer** (new) — Orchestrates first-run setup, calls existing setup.sh via justfile, validates prerequisites
2. **Justfile layer** (extended) — Add bootstrap recipe that chains npm install + just setup with idempotency guards
3. **Dev container layer** (new) — Wraps entire environment, calls `just bootstrap` in postCreateCommand
4. **Setup detection** (enhanced) — Detect container environment, adapt vault discovery accordingly

**Key pattern:** Bootstrap follows install-and-maintain paradigm with three execution modes already established in research:
- Deterministic: `just bootstrap` from terminal (no Claude)
- Container: devcontainer.json postCreateCommand triggers bootstrap
- Interactive: Existing `just setup` for vault configuration

### Critical Pitfalls

1. **Hardcoded vault path in container** — Obsidian vault paths from host filesystem don't exist in container. Detection: check for `/.dockerenv` or `REMOTE_CONTAINERS` env var. Solution: gracefully degrade vault-dependent commands, provide clear error with instructions for mounting vault or using mock mode.

2. **Non-idempotent bootstrap script** — Running `just bootstrap` twice causes failures (mkdir without -p, config file duplication). Prevention: Use `mkdir -p`, `ln -sf`, guard before append (`grep -qF "entry" file || echo "entry" >> file`), detect already-configured state early.

3. **node_modules performance disaster on macOS/Windows** — Bind-mounting node_modules through Docker VM makes npm operations 5-10x slower (1 min becomes 10 min). Prevention: Use named volume mount in devcontainer.json: `"mounts": ["source=${localWorkspaceFolderBasename}-node_modules,target=${containerWorkspaceFolder}/node_modules,type=volume"]`.

4. **Interactive setup script in container** — Existing setup.sh uses `read -rp` for input, which fails in postCreateCommand (no TTY). Prevention: Add environment variable fallback (`OBSIDIAN_VAULT_PATH`), detect TTY availability with `[[ -t 0 ]]`, provide non-interactive mode.

5. **Windows path format incompatibility** — devcontainer.json mount paths break on Windows without Docker Desktop (backslash vs forward slash, drive letter translation). Prevention: Use `${localWorkspaceFolder}` variable (VS Code handles translation), avoid hardcoded absolute paths, document WSL2 as recommended Windows path.

## Implications for Roadmap

Based on research, this milestone naturally splits into two sequential phases:

### Phase 1: Fix Title Duplication & Bootstrap Foundation
**Rationale:** Fix existing bug first, then add bootstrap infrastructure that depends on stable template behavior.

**Delivers:**
- Fixed Obsidian template (title no longer duplicated)
- `just bootstrap` recipe with idempotency guards
- .nvmrc file for Node version consistency
- README updated with Quick Start section

**Addresses:**
- Table stakes: Single-command setup, idempotent bootstrap, node version file
- Pitfall: Non-idempotent bootstrap (guards prevent double-run failures)

**Avoids:**
- Building devcontainer on broken foundation (template fix comes first)
- Bootstrap recipe calling flawed setup script

**Research flag:** Standard pattern — no additional research needed. Justfile patterns well-documented.

### Phase 2: Dev Container & Documentation Polish
**Rationale:** Bootstrap must exist first (devcontainer calls `just bootstrap`). Container environment reveals path assumption issues.

**Delivers:**
- .devcontainer/devcontainer.json with Node 22, just feature, named volume for node_modules
- Container-aware vault detection in setup.sh
- Environment variable fallback for non-interactive setup
- README section on dev container usage

**Addresses:**
- Table stakes: Dev container configuration, first-run documentation
- Differentiators: Zero-config preview mode, container-aware vault detection
- Pitfalls: Hardcoded vault path, interactive script in container, node_modules performance

**Uses:**
- Stack: Microsoft devcontainer base image (typescript-node:22), just feature from ghcr.io/guiyomh/features
- Architecture: Three-layer pattern (devcontainer wraps existing layers)

**Avoids:**
- Windows path issues (use ${localWorkspaceFolder} variable)
- Performance disaster (named volume for node_modules)
- Container hang (environment variable fallback for vault path)

**Research flag:** Container-specific vault mounting may need trial-and-error during implementation. Consider documenting "for publishing workflow, mount vault via mounts config" vs "for code-only development, skip vault setup."

### Phase Ordering Rationale

**Phase 1 before Phase 2 because:**
- Bootstrap recipe must exist before devcontainer can call it in postCreateCommand
- Idempotency patterns established in bootstrap inform container restart behavior
- Template bug fix prevents confusion during container testing (clean foundation)

**Within Phase 2:**
- Dev container configuration comes first (defines environment constraints)
- Container-aware detection added second (responds to environment)
- Documentation last (captures tested workflow)

**Dependency chain:**
```
Template fix → Bootstrap recipe → .nvmrc
                      ↓
              Devcontainer config → Container detection → Docs
```

### Research Flags

**Phase 1 (Fix & Bootstrap):**
- **Low risk** — Standard justfile patterns, npm install, bash guards. Well-documented territory.
- **No additional research needed** — Patterns from just manual and idempotent bash articles cover all cases.

**Phase 2 (Dev Container):**
- **Medium risk** — Container-specific path issues require testing in actual container environment.
- **Potential research:** Vault mounting strategies (bind mount vs volume, host path translation, environment variable expansion). Consider `/gsd:research-phase` if mount config becomes complex.
- **Testing required:** Windows container testing to validate path handling (if supporting Windows contributors).

**Standard patterns (skip research-phase):**
- .nvmrc creation — 1-line file, no complexity
- README updates — documentation task, not technical research
- Bootstrap idempotency — patterns already documented in PITFALLS.md

## Confidence Assessment

| Area | Confidence | Notes |
|------|------------|-------|
| Stack | HIGH | No new dependencies; configuration files only. Official MS devcontainer image verified. |
| Features | HIGH | Table stakes well-defined from UX research (clig.dev, CLI patterns). Bootstrap patterns from install-and-maintain repo. |
| Architecture | HIGH | Three-layer pattern already proven in v0.2.0. Bootstrap is additive, doesn't modify existing layers. |
| Pitfalls | HIGH | All critical pitfalls verified against official docs (VS Code, containers.dev, just manual). Container-specific pitfalls from known issues and performance docs. |

**Overall confidence:** HIGH

### Gaps to Address

**During Phase 1 implementation:**
- **Gap:** Exact idempotency guards for setup.sh — script may have undocumented side effects. **Resolution:** Test `just bootstrap` twice in clean environment before committing.
- **Gap:** Prerequisites list completeness — setup.sh may use tools beyond jq. **Resolution:** Run prerequisite check against minimal container to discover all dependencies.

**During Phase 2 implementation:**
- **Gap:** Vault mount configuration for contributors with Obsidian — unclear if bind mount or volume better for large vaults. **Resolution:** Document both approaches; let users choose based on vault size and sync tool (if using Obsidian Sync, bind mount better for file watching).
- **Gap:** Windows testing coverage — no Windows machine available for testing. **Resolution:** Document WSL2 as recommended path, ask for community testing feedback in PR.

**Post-milestone validation:**
- **Gap:** GitHub Codespaces compatibility — devcontainer.json should work but untested. **Resolution:** Test in actual Codespace environment after merge; add badge to README if working.

## Sources

### Primary (HIGH confidence)
- [VS Code Create Dev Container](https://code.visualstudio.com/docs/devcontainers/create-dev-container) — Official devcontainer.json reference, lifecycle commands
- [Dev Container Features Registry](https://containers.dev/features) — Just feature discovery and versioning
- [Just Programmer's Manual](https://just.systems/man/en/) — Recipe patterns, shebang usage, idempotency
- [VS Code Dev Container Performance](https://code.visualstudio.com/remote/advancedcontainers/improve-performance) — Named volume pattern for node_modules
- [containers.dev Lifecycle Reference](https://containers.dev/implementors/json_reference/) — postCreateCommand vs postStartCommand

### Secondary (MEDIUM confidence)
- [Command Line Interface Guidelines (clig.dev)](https://clig.dev/) — Bootstrap UX patterns, single entry point principle
- [UX patterns for CLI tools](https://lucasfcosta.com/2022/06/01/ux-patterns-cli-tools.html) — Interactive vs non-interactive modes
- [Idempotent Bash Scripts](https://arslan.io/2019/07/03/how-to-write-idempotent-bash-scripts/) — Guard patterns, safe operations
- [DevContainers Best Practices](https://atoms.dev/insights/6d0570e51ba4430296743ef234f4f74d) — Image pinning, volume optimization

### Tertiary (LOW confidence)
- GitHub Issue #6130 (Windows path handling) — Community reports of path translation issues, not official guidance
- Community devcontainer examples — Patterns vary; official docs take precedence

---
*Research completed: 2026-01-31*
*Ready for roadmap: yes*
*Milestone context: v0.3.0 Polish & Portability*
