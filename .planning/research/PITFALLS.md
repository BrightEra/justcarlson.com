# Pitfalls Research: justfile + Hooks Publishing

**Domain:** Blog publishing workflow (Obsidian to Astro)
**Researched:** 2026-01-30
**Confidence:** HIGH (official docs verified)

## justfile Pitfalls

### Critical: Each Recipe Line Runs in a New Shell

**What goes wrong:** Commands that set environment variables or change directories don't persist to subsequent lines.

```just
# BROKEN - cd doesn't persist
build:
  cd src
  npm run build  # Still runs in original directory!
```

**Why it happens:** Just executes each recipe line in a fresh shell instance.

**Prevention:**
- Chain commands with `&&`: `cd src && npm run build`
- Use shebang recipes for complex scripts that need state

```just
# FIXED - shebang recipe keeps shell state
build:
  #!/usr/bin/env bash
  cd src
  npm run build  # Works - same shell instance
```

**Warning signs:** Commands appear to work but have no effect; build runs in wrong directory.

**Phase:** 7 (Setup & Safety) - Establish pattern in first justfile recipes

**Source:** [Just Programmer's Manual](https://just.systems/man/en/)

---

### Critical: Variable Syntax Confusion ({{var}} vs $VAR)

**What goes wrong:** Using shell variable syntax (`$VAR`) when just variable syntax (`{{var}}`) is needed, or vice versa.

```just
# BROKEN - mixing syntax incorrectly
vault_path := "/path/to/vault"
publish:
  cp $vault_path/posts/* ./src/content/  # Wrong! $vault_path is shell variable
```

**Why it happens:** Just uses `{{variable}}` for its own variables, `$VARIABLE` for shell/environment variables.

**Prevention:**
- Just variables: `{{variable_name}}` (defined in justfile)
- Environment variables: `$VARIABLE_NAME` (from .env or shell)
- Use `set dotenv-load` to enable .env file loading

```just
# CORRECT - proper variable syntax
vault_path := "/path/to/vault"
publish:
  cp "{{vault_path}}/posts/"* ./src/content/
```

**Warning signs:** "undefined variable" errors, empty strings where values expected.

**Phase:** 7 (Setup & Safety) - Document syntax in justfile comments

**Source:** [Just Programmer's Manual - Recipe Parameters](https://just.systems/man/en/recipe-parameters.html)

---

### Moderate: Nested Just Invocations Lose State

**What goes wrong:** Calling `just` from within a recipe recalculates assignments and loses CLI arguments.

```just
# PROBLEMATIC - nested just loses context
all:
  just build
  just test   # CLI arguments not propagated, assignments recalculated
```

**Why it happens:** Each `just` invocation is independent with fresh state.

**Prevention:**
- Use dependencies instead of nested calls
- Pass required values explicitly as arguments

```just
# BETTER - use dependencies
all: build test

# Or pass values explicitly
build-and-test target:
  just build {{target}} && just test {{target}}
```

**Warning signs:** Dependencies run twice; behavior differs when run directly vs nested.

**Phase:** 8 (Core Publishing) - Structure publish pipeline as dependencies

**Source:** [GitHub - casey/just](https://github.com/casey/just)

---

### Moderate: Cross-Platform Shell Compatibility

**What goes wrong:** Recipes use bash-specific features that fail on other shells or platforms.

**Why it happens:** Just defaults to `/bin/sh`, which may not support bash features.

**Prevention:**
- Explicitly set shell: `set shell := ["bash", "-cu"]`
- Test on target platforms
- Avoid bash-only features when possible

```just
set shell := ["bash", "-cu"]

# Now bash features work reliably
publish:
  if [[ -f "./config.json" ]]; then
    echo "Config found"
  fi
```

**Warning signs:** `[[` syntax errors; brace expansion fails.

**Phase:** 7 (Setup & Safety) - Set shell explicitly at top of justfile

**Source:** [Just Settings - Configuring the Shell](https://just.systems/man/en/settings.html)

---

### Minor: Indentation Must Be Consistent Within Recipe

**What goes wrong:** Mixing spaces and tabs in recipe lines causes parse errors.

**Prevention:**
- Use consistent indentation (tabs recommended by just)
- Different recipes can use different indentation, but each recipe must be internally consistent

**Warning signs:** Parse errors mentioning indentation; "unexpected character" errors.

**Phase:** 7 (Setup & Safety) - Establish editorconfig pattern

---

## Claude Hooks Pitfalls

### Critical: Exit Code 2 Ignores JSON Output

**What goes wrong:** Hook returns exit code 2 (blocking error) with JSON in stdout, but JSON is ignored. Only stderr is used.

```bash
# BROKEN - JSON ignored with exit code 2
echo '{"decision": "block", "reason": "Dangerous operation"}'
exit 2  # stderr used, stdout JSON ignored!
```

**Why it happens:** By design, exit code 2 means "blocking error" and uses stderr directly.

**Prevention:**
- For blocking with JSON control: exit 0 with `"decision": "block"` in JSON
- For simple blocking: exit 2 with error message in stderr

```bash
# CORRECT - JSON blocking (exit 0)
echo '{"decision": "block", "reason": "Dangerous operation"}'
exit 0

# CORRECT - simple blocking (exit 2)
echo "Dangerous operation blocked: force push not allowed" >&2
exit 2
```

**Warning signs:** Hook blocks operations but custom JSON reasons never appear.

**Phase:** 7 (Setup & Safety) - Use exit 2 + stderr for git safety hooks

**Source:** [Claude Code Hooks Reference](https://code.claude.com/docs/en/hooks)

---

### Critical: PostToolUse JSON Not Processed (Known Bug)

**What goes wrong:** PostToolUse hooks can execute but their JSON output is not captured by Claude.

**Why it happens:** Bug in Claude Code (Issue #3983, July 2025). JSON communication documented but not working.

**Prevention:**
- For PostToolUse, use exit codes + stderr for critical blocking
- Write diagnostic data to external log files as workaround
- Consider PreToolUse hooks instead where possible

**Warning signs:** PostToolUse hooks run but Claude never receives feedback.

**Phase:** 8 (Core Publishing) - Prefer PreToolUse for validation

**Source:** [GitHub Issue #3983](https://github.com/anthropics/claude-code/issues/3983)

---

### Critical: Plugin Hooks vs Inline Hooks Behave Differently

**What goes wrong:** Hooks that work perfectly in `.claude/settings.json` fail when installed via plugins.

**Why it happens:** Plugin hooks' stdout not captured the same way (Issue #10875, November 2025).

**Prevention:**
- Use inline hooks in settings.json for critical safety hooks
- Test hooks in both plugin and inline configurations
- Don't rely on plugins for safety-critical hooks

**Warning signs:** Same hook script works inline but fails via plugin.

**Phase:** 7 (Setup & Safety) - Use inline hooks in settings.json, not plugins

**Source:** [GitHub Issue #10875](https://github.com/anthropics/claude-code/issues/10875)

---

### Moderate: Hook Configuration Changes Require Restart

**What goes wrong:** Edit hooks in settings file, but old behavior persists.

**Why it happens:** Claude Code captures hook snapshot at startup for security.

**Prevention:**
- After editing hooks, restart Claude Code
- Use `/hooks` command to verify configuration loaded correctly
- Changes to running session require explicit review in `/hooks` menu

**Warning signs:** New hook doesn't trigger; old (deleted) hook still runs.

**Phase:** 7 (Setup & Safety) - Document restart requirement

**Source:** [Claude Code Hooks Reference](https://code.claude.com/docs/en/hooks)

---

### Moderate: 60-Second Default Timeout

**What goes wrong:** Long-running hooks (builds, linting) timeout before completion.

**Why it happens:** Default hook timeout is 60 seconds.

**Prevention:**
- Set explicit timeout per command: `"timeout": 300` (5 minutes for builds)
- Keep validation hooks fast; offload heavy work to justfile

```json
{
  "hooks": {
    "PreToolUse": [{
      "matcher": "Bash",
      "hooks": [{
        "type": "command",
        "command": "./validate.sh",
        "timeout": 120
      }]
    }]
  }
}
```

**Warning signs:** Hook exits mid-execution; inconsistent behavior under load.

**Phase:** 8 (Core Publishing) - Set 300s timeout for build hooks

**Source:** [Claude Code Hooks Reference](https://code.claude.com/docs/en/hooks)

---

### Minor: Matcher Patterns Are Case-Sensitive

**What goes wrong:** Hook matches "bash" but tool is "Bash".

**Prevention:**
- Tool names are case-sensitive: `Bash`, `Write`, `Edit`, `Read`
- Use regex for flexibility: `"matcher": "[Bb]ash"`
- Use `*` to match all tools

**Warning signs:** Hook never triggers despite correct event.

**Phase:** 7 (Setup & Safety) - Use exact tool names from documentation

---

### Minor: settings.local.json Must Be Created Carefully

**What goes wrong:** Creating `.claude/settings.local.json` doesn't auto-gitignore; sensitive paths committed.

**Why it happens:** Claude Code auto-configures gitignore only when it creates the file.

**Prevention:**
- Let Claude Code create the file via hooks/skills
- Or manually add to `.gitignore`: `.claude/settings.local.json`
- Never commit vault paths or personal paths

**Warning signs:** Local config appears in git status.

**Phase:** 7 (Setup & Safety) - Verify gitignore entry exists

**Source:** [Claude Code Settings](https://code.claude.com/docs/en/settings)

---

## Publishing Workflow Pitfalls

### Critical: Obsidian Image Syntax Not Standard Markdown

**What goes wrong:** Obsidian's `![[image.png]]` embed syntax doesn't render in Astro.

**Why it happens:** Obsidian uses proprietary wiki-link syntax for embeds.

**Prevention:**
- Configure Obsidian: Settings > Files & Links > New Link Format = "Relative path to file"
- Convert `![[image.png]]` to `![alt](./image.png)` during publishing
- Use Image Converter plugin in Obsidian

```bash
# Convert Obsidian syntax to standard markdown
sed -i 's/!\[\[\([^]]*\)\]\]/![\1](.\/\1)/g' "$post_file"
```

**Warning signs:** Images display in Obsidian but broken in Astro build.

**Phase:** 8 (Core Publishing) - Image syntax conversion in publish pipeline

**Source:** [Write Like a Pro with Astro and Obsidian](https://www.hungrimind.com/articles/obsidian-with-astro)

---

### Critical: Relative Image Paths Break in Astro Content Collections

**What goes wrong:** Image `![](./image.png)` in markdown causes build failure when Astro can't resolve the path.

**Why it happens:** Astro copies/optimizes images to `_astro/` folder, breaking relative references.

**Prevention:**
- Copy images to `public/assets/blog/` with absolute paths
- Update image references in markdown to `/assets/blog/image.png`
- Or use Astro's content collection image helper for type-safe image references

```just
# Copy images alongside posts
copy-images post:
  find "{{vault}}/{{post}}" -name "*.png" -o -name "*.jpg" | \
    xargs -I{} cp {} public/assets/blog/
```

**Warning signs:** Build fails with "could not find image" errors; images work in dev but fail in build.

**Phase:** 8 (Core Publishing) - Establish image copy + path update pattern

**Source:** [GitHub Issue #1188 - withastro/astro](https://github.com/withastro/astro/issues/1188)

---

### Critical: Special Characters in Image Filenames

**What goes wrong:** Images with spaces or special characters (`&`, `\`, etc.) break optimization.

**Why it happens:** Astro's image optimization escapes these characters, breaking paths.

**Prevention:**
- Validate image filenames during publish
- Reject or auto-rename files with spaces/special characters
- Use underscores: `my_image.png` not `my image.png`

```bash
# Check for problematic filenames
find ./posts -name "* *" -o -name "*&*" -o -name "*\\*" | head -1 && \
  echo "ERROR: Invalid image filename" && exit 1
```

**Warning signs:** Some images work, others 404; build completes but images broken.

**Phase:** 8 (Core Publishing) - Add filename validation to image copy

**Source:** [Configuring Obsidian and Astro Assets](https://www.anca.wtf/posts/configuring-obsidian-and-astro-assets-for-markdoc-content-in-an-astro-blog/)

---

### Critical: Partial Commits Leave Broken State

**What goes wrong:** Commit posts without images, or images without posts, leaving site broken.

**Why it happens:** Validation passes on markdown but images not copied; or script fails mid-execution.

**Prevention:**
- Atomic operations: copy all files, then validate all, then commit all
- Stage everything before committing
- Build check before commit catches missing images

```just
# Atomic publish - all or nothing
publish:
  # 1. Copy posts and images together
  ./scripts/copy-content.sh
  # 2. Validate everything
  npm run lint
  # 3. Build check (catches missing images)
  npm run build
  # 4. Only then commit
  git add src/content/blog/ public/assets/blog/
  git commit -m "feat(blog): publish new posts"
```

**Warning signs:** Site breaks after publish; images 404; build fails on Vercel but passed locally.

**Phase:** 8 (Core Publishing) - Atomic copy + build-before-commit

---

### Moderate: Frontmatter Validation Gaps

**What goes wrong:** Posts published with missing `pubDatetime`, empty `description`, or invalid `tags`.

**Why it happens:** Validation only checks required fields exist, not that they're valid.

**Prevention:**
- Validate field values, not just presence
- Check pubDatetime is valid ISO date
- Check description length (SEO: 50-160 chars)
- Check tags array contains valid strings

```bash
# Validate frontmatter values
yq '.pubDatetime' "$post" | grep -qE '^\d{4}-\d{2}-\d{2}' || \
  echo "ERROR: Invalid pubDatetime format"
```

**Warning signs:** Posts appear but SEO broken; date sorting wrong; OG images missing text.

**Phase:** 8 (Core Publishing) - Comprehensive frontmatter validation

---

### Moderate: Year Folder Mismatch

**What goes wrong:** Post with `pubDatetime: 2026-01-30` copied to `src/content/blog/2025/` manually.

**Why it happens:** Year extraction from pubDatetime not automated; manual copy to wrong folder.

**Prevention:**
- Extract year from pubDatetime programmatically
- Validate post path matches pubDatetime year

```just
# Extract year and copy to correct folder
copy-post post:
  year=$(yq '.pubDatetime' "{{post}}" | cut -d'-' -f1)
  mkdir -p "src/content/blog/$year"
  cp "{{post}}" "src/content/blog/$year/"
```

**Warning signs:** Archive pages show wrong years; RSS feed dates inconsistent.

**Phase:** 8 (Core Publishing) - Auto-extract year from pubDatetime

---

### Minor: Status Field Parsing

**What goes wrong:** Post with `status: - Draft` gets published; or `status: - Published` post missed.

**Why it happens:** Status is a YAML list, requires multiline matching.

**Prevention:**
- Use perl for multiline matching (status: followed by list item)
- Parse with YAML-aware tool, not simple grep

```bash
# CORRECT - use perl for multiline YAML list matching
perl -0777 -ne 'exit(!/status:\s*\n\s*-\s*Published/i)' "$post"

# WRONG - grep fails on multiline YAML lists
grep 'status: - Published' "$post"  # Misses when on separate lines
```

**Warning signs:** Some posts not discovered; unexpected posts published.

**Phase:** 9 (Utilities) - Use perl for status field matching

---

## Git Safety Pitfalls

### Critical: --no-verify Bypasses All Hooks

**What goes wrong:** User runs `git commit --no-verify` or `git push --no-verify`, completely bypassing safety hooks.

**Why it happens:** Git provides escape hatch for legitimate edge cases; users discover and misuse it.

**Prevention:**
- Claude hooks run before git hooks, so Claude hooks aren't bypassed by --no-verify
- For additional protection: server-side hooks (branch protection rules)
- Education: document when --no-verify is acceptable

**Warning signs:** Dangerous operations succeed despite hooks.

**Phase:** 7 (Setup & Safety) - Document that Claude hooks can't be bypassed like git hooks

**Source:** [Git Documentation - githooks](https://git-scm.com/docs/githooks)

---

### Critical: Hooks Don't Block Pre-Existing Local State

**What goes wrong:** User already has destructive command in history; re-runs it outside Claude.

**Why it happens:** Claude hooks only protect operations routed through Claude.

**Prevention:**
- Server-side branch protection (force-push blocked at GitHub level)
- Training/documentation for safe git practices
- Consider global git hooks via `core.hooksPath` for additional protection

**Warning signs:** Destructive operations succeed when run directly in terminal.

**Phase:** 7 (Setup & Safety) - Recommend GitHub branch protection in documentation

---

### Moderate: Force Push Detection Pattern Gaps

**What goes wrong:** Hook blocks `git push --force` but not `git push -f` or `git push --force-with-lease`.

**Why it happens:** Pattern matching doesn't cover all force push variations.

**Prevention:**
- Match all variations: `--force`, `-f`, `--force-with-lease`, `+refs/`
- Parse git push arguments properly

```bash
# Comprehensive force push detection
if echo "$cmd" | grep -qE '(push.*(--force|-f|--force-with-lease|\+[a-zA-Z]))'; then
  echo "ERROR: Force push blocked" >&2
  exit 2
fi
```

**Warning signs:** Some force push commands succeed; inconsistent blocking.

**Phase:** 7 (Setup & Safety) - Comprehensive force push pattern

---

### Moderate: Reset Detection Must Include Variations

**What goes wrong:** Hook blocks `git reset --hard` but not `git reset --hard HEAD~1` or `git reset --hard origin/main`.

**Prevention:**
- Match pattern, not exact command
- Block: `reset --hard`, `checkout .`, `clean -f`, `restore .`

```bash
# Block dangerous reset variations
dangerous_patterns=(
  'reset --hard'
  'checkout \.'
  'clean -f'
  'restore \.'
  'branch -D'
)
```

**Warning signs:** Some destructive operations succeed.

**Phase:** 7 (Setup & Safety) - Pattern-based blocking

---

### Minor: Pre-Push vs Pre-Commit Hook Timing

**What goes wrong:** Validation runs at commit time, but problematic code already committed before push blocked.

**Prevention:**
- Run validation at commit time (pre-commit) to prevent bad commits
- Run safety checks at push time (pre-push) as final gate
- Claude PreToolUse hooks can intercept before either

**Warning signs:** Local repo has bad commits that can't be pushed.

**Phase:** 8 (Core Publishing) - Validate at commit time, not just push

---

## Bootstrap and Dev Container Pitfalls

**Added:** 2026-01-31
**Context:** Adding `just bootstrap` and dev container support to existing project

### Critical: Hardcoded Vault Path in Container

**What goes wrong:** The project reads Obsidian vault path from `.claude/settings.local.json`. In a container, this path either does not exist or points to a host path that is not mounted.

**Why it happens:** Dev containers run in isolated filesystems. Host paths like `/home/jc/Documents/Obsidian` mean nothing inside the container unless explicitly mounted.

**Consequences:**
- `just publish` fails with "vault not found"
- Setup script tries to `find $HOME` inside container (finds nothing)
- Contributors cannot test publishing workflow in container

**Warning signs:**
- Setup script contains `find "$HOME"` without container detection
- No mount configuration for external directories in devcontainer.json
- Scripts assume paths from `.env` or local config files exist

**Prevention:**
1. Detect container environment: `if [[ -f /.dockerenv ]] || [[ -n "${REMOTE_CONTAINERS:-}" ]]; then`
2. For container mode: mount vault via `${localEnv:OBSIDIAN_VAULT_PATH}` with fallback
3. Provide mock/stub mode for contributors without vault access
4. Document: "Publishing requires vault mount. For code-only development, skip this."

**Which phase addresses:** Bootstrap/Dev Container milestone - vault mounting strategy

**Confidence:** HIGH (verified via [VS Code advanced containers docs](https://code.visualstudio.com/remote/advancedcontainers/environment-variables))

---

### Critical: Non-Idempotent Bootstrap Script

**What goes wrong:** Running `just bootstrap` twice fails or produces different results. Common causes:
- `mkdir` without `-p` flag
- Appending to config files without checking if entry exists
- npm install race conditions with existing node_modules

**Why it happens:** Bootstrap scripts tested only on clean machines. Second run not tested.

**Consequences:**
- CI pipelines fail on retry
- Contributors get "already exists" errors
- Corrupted configs from duplicate entries

**Warning signs:**
- `mkdir` without `-p`
- `echo "something" >> file` without `grep` guard
- No "already configured" detection

**Prevention:**
```bash
# Pattern: always idempotent
mkdir -p "$DIR"                           # -p makes it safe
ln -sf "$SOURCE" "$TARGET"                # -f overwrites existing
grep -qF "entry" file || echo "entry" >> file  # guard before append

# Pattern: detect already-done state
if [[ -f "$CONFIG_FILE" ]]; then
    echo "Already configured. Run with --force to reconfigure."
    exit 0
fi
```

**Which phase addresses:** Bootstrap/Dev Container milestone - idempotent script design

**Confidence:** HIGH (verified via [idempotent bash article](https://arslan.io/2019/07/03/how-to-write-idempotent-bash-scripts/))

---

### Critical: node_modules Performance Disaster on macOS/Windows

**What goes wrong:** Dev container bind mounts the entire workspace including node_modules. On macOS and Windows (which run Docker in a VM), this makes npm operations 5-10x slower.

**Why it happens:** Bind mounts sync every file operation through the VM. node_modules has 50,000+ files.

**Consequences:**
- `npm install` takes 5-10 minutes instead of 1 minute
- IDE becomes sluggish
- Developers abandon dev container

**Warning signs:**
- No named volume for node_modules in devcontainer.json
- `npm install` in postCreateCommand without volume optimization
- No performance section in dev container documentation

**Prevention:**
```json
{
  "mounts": [
    "source=${localWorkspaceFolderBasename}-node_modules,target=${containerWorkspaceFolder}/node_modules,type=volume"
  ],
  "postCreateCommand": "npm install"
}
```

**Trade-off:** Host cannot see node_modules contents. This is acceptable since the container handles builds.

**Which phase addresses:** Bootstrap/Dev Container milestone - mount configuration

**Confidence:** HIGH (verified via [VS Code performance docs](https://code.visualstudio.com/remote/advancedcontainers/improve-performance))

---

### Critical: Windows Path Format Incompatibility

**What goes wrong:** devcontainer.json with `workspaceMount` or `mounts` using `${localWorkspaceFolder}` breaks on Windows when not using Docker Desktop.

**Why it happens:** Windows paths use backslashes and drive letters (`C:\Users\...`). Docker expects Unix paths (`/mnt/c/Users/...`). Docker Desktop translates automatically; other setups do not.

**Consequences:**
- "Invalid mount path" errors on Windows
- Contributors on Windows cannot use dev container
- Committed devcontainer.json breaks for Windows users

**Warning signs:**
- `workspaceMount` with absolute paths
- Testing only on Linux/macOS
- No Windows contributor testing

**Prevention:**
1. Use `${localWorkspaceFolder}` variable (handled by VS Code)
2. Avoid hardcoded paths in devcontainer.json
3. Test on Windows before declaring dev container "done"
4. Consider WSL2 as documented path (avoids translation issues)

**Which phase addresses:** Bootstrap/Dev Container milestone - cross-platform testing

**Confidence:** MEDIUM (verified via [GitHub issue #6130](https://github.com/microsoft/vscode-remote-release/issues/6130))

---

### Moderate: Interactive Setup Script in Container

**What goes wrong:** The existing `setup.sh` uses `read -rp` for interactive input. This fails in:
- `postCreateCommand` (no TTY)
- CI pipelines
- Codespaces initial setup

**Why it happens:** Setup designed for local terminal, not headless execution.

**Consequences:**
- Container build hangs waiting for input
- Must manually run setup after container starts
- Poor first-run experience

**Warning signs:**
- `read` commands in scripts called by postCreateCommand
- No `--non-interactive` flag
- No environment variable fallback

**Prevention:**
```bash
# Pattern: environment variable takes precedence
if [[ -n "${OBSIDIAN_VAULT_PATH:-}" ]]; then
    VAULT_PATH="$OBSIDIAN_VAULT_PATH"
elif [[ -t 0 ]]; then
    # Interactive mode
    read -rp "Enter vault path: " VAULT_PATH
else
    echo "Error: OBSIDIAN_VAULT_PATH not set and no TTY available"
    exit 1
fi
```

**Which phase addresses:** Bootstrap/Dev Container milestone - non-interactive mode

**Confidence:** HIGH (verified via [VS Code lifecycle commands docs](https://code.visualstudio.com/remote/advancedcontainers/start-processes))

---

### Moderate: Confusing postCreateCommand vs postStartCommand

**What goes wrong:** Dependencies installed in `postStartCommand` run on every container start, wasting time. Or services put in `postCreateCommand` only run once, then are missing on restart.

**Why it happens:** Lifecycle commands are not intuitive. Names suggest timing but not frequency.

**Consequences:**
- Slow container startup (reinstalling deps every time)
- Missing services after restart
- Inconsistent container state

**Warning signs:**
- `npm install` in postStartCommand
- Server start in postCreateCommand
- No documentation of lifecycle expectations

**Prevention:**

| Command | Runs When | Use For |
|---------|-----------|---------|
| `postCreateCommand` | Once after creation | `npm install`, one-time config |
| `postStartCommand` | Every start | Starting servers, services |
| `postAttachCommand` | Every attach | User-specific shell setup |

**Which phase addresses:** Bootstrap/Dev Container milestone - lifecycle command configuration

**Confidence:** HIGH (verified via [containers.dev spec](https://containers.dev/implementors/json_reference/))

---

### Moderate: Justfile Shell Incompatibility Across Platforms

**What goes wrong:** Justfile uses `set shell := ["bash", "-uc"]` which requires bash. Windows without Git Bash, WSL, or Cygwin fails.

**Why it happens:** bash is not default on Windows. Just falls back to sh, which may not exist.

**Consequences:**
- Windows users cannot run just commands
- Must document "install Git Bash first"
- Friction for new contributors

**Warning signs:**
- `set shell := ["bash", ...]` without platform handling
- No Windows testing
- README assumes bash available

**Prevention options:**
1. **Document requirement:** "Requires bash. On Windows, use Git Bash or WSL."
2. **Dev container solves this:** Container has bash, Windows path irrelevant
3. **PowerShell fallback:**
   ```just
   # Platform-specific shell (if needed)
   set windows-shell := ["powershell.exe", "-NoLogo", "-Command"]
   ```

**Which phase addresses:** Bootstrap/Dev Container milestone - prerequisites documentation

**Confidence:** HIGH (verified via [just manual](https://just.systems/man/en/settings.html))

---

### Moderate: Missing Prerequisites for Bootstrap

**What goes wrong:** `just bootstrap` assumes tools are installed (jq, node, npm) without checking.

**Why it happens:** Developer's machine has everything. Fresh machine does not.

**Consequences:**
- Cryptic errors: "jq: command not found"
- Partial setup state (some steps passed, later steps fail)
- Bootstrap does not rollback

**Warning signs:**
- Commands like `jq`, `node` without existence check
- No prerequisites list in documentation
- Bootstrap recipe calls external tools directly

**Prevention:**
```bash
# Check prerequisites at start
check_prereqs() {
    local missing=()
    command -v node &>/dev/null || missing+=("node")
    command -v npm &>/dev/null || missing+=("npm")
    command -v jq &>/dev/null || missing+=("jq")

    if [[ ${#missing[@]} -gt 0 ]]; then
        echo "Missing prerequisites: ${missing[*]}"
        echo "Install with: <platform-specific instructions>"
        exit 1
    fi
}
```

**Which phase addresses:** Bootstrap/Dev Container milestone - prerequisite checking

**Confidence:** HIGH (direct observation of setup.sh using jq)

---

### Minor: No .env.example for Machine-Specific Config

**What goes wrong:** New contributors do not know what environment variables are needed. They discover requirements through trial and error.

**Why it happens:** Gitignored `.env` means config knowledge is not in repo.

**Consequences:**
- "Works on my machine" syndrome
- Documentation drifts from reality
- Onboarding friction

**Prevention:**
```bash
# Provide template (tracked in git)
.env.example:
# Machine-specific configuration
# Copy to .env and fill in values

# Path to Obsidian vault (for publishing workflow)
OBSIDIAN_VAULT_PATH=

# Optional: Override default blog directory name
# BLOG_DIRECTORY=blog
```

**Which phase addresses:** Bootstrap/Dev Container milestone - environment template

**Confidence:** HIGH (common pattern)

---

### Minor: Latest Tag for Container Base Image

**What goes wrong:** Container works today, breaks tomorrow when base image updates.

**Why it happens:** `FROM node:latest` or `image: mcr.microsoft.com/devcontainers/javascript-node:latest`

**Consequences:**
- Surprise breakage on container rebuild
- "It worked last week" debugging sessions
- Version skew between team members

**Prevention:**
```json
{
  "image": "mcr.microsoft.com/devcontainers/javascript-node:1-22-bookworm"
}
```

Pin to specific version. Update deliberately with changelog review.

**Which phase addresses:** Bootstrap/Dev Container milestone - image selection

**Confidence:** HIGH (verified via [devcontainer best practices](https://atoms.dev/insights/6d0570e51ba4430296743ef234f4f74d))

---

### Minor: Forgetting to Update node_modules Volume After Package Changes

**What goes wrong:** Package.json changes on host, but container's node_modules volume has old dependencies.

**Why it happens:** Named volume persists across rebuilds. Volume is not automatically cleared.

**Consequences:**
- "Package not found" errors after adding dependencies on host
- Must manually delete volume or rebuild container

**Warning signs:**
- Using named volume for node_modules (correct for performance)
- No instructions for clearing volume

**Prevention:**
```bash
# Document in README
# After changing package.json, rebuild container:
# Command Palette > Dev Containers: Rebuild Container

# Or clear node_modules volume:
# docker volume rm <project>-node_modules
```

**Which phase addresses:** Bootstrap/Dev Container milestone - maintenance documentation

**Confidence:** HIGH (consequence of named volume optimization)

---

## Bootstrap/Dev Container Phase-Specific Warnings

| Phase | Topic | Likely Pitfall | Mitigation |
|-------|-------|---------------|------------|
| Bootstrap | Idempotency | Script fails on second run | Test `just bootstrap` twice in a row |
| Bootstrap | Prerequisites | Missing jq/node/npm | Add prerequisite check function |
| Bootstrap | Interactivity | Hangs in CI/container | Add environment variable fallback |
| Dev Container | Performance | Slow node_modules | Use named volume mount |
| Dev Container | Vault path | External path not mounted | Document mount or mock strategy |
| Dev Container | Windows paths | Cross-platform failures | Test on Windows or recommend WSL |
| Dev Container | Lifecycle | postCreate vs postStart confusion | Document which command runs when |
| Dev Container | Base image | Drift from latest tag | Pin to specific version tag |

---

## Bootstrap/Dev Container Testing Checklist

Before declaring milestone complete:

### Bootstrap Testing
- [ ] `just bootstrap` on clean clone (no prior setup)
- [ ] `just bootstrap` on already-configured machine (idempotent)
- [ ] Bootstrap with missing jq (error message helpful?)
- [ ] Bootstrap with missing node (error message helpful?)
- [ ] Bootstrap in CI-like environment (no TTY)

### Dev Container Testing
- [ ] Rebuild container (from scratch)
- [ ] Reopen container (after restart)
- [ ] `npm install` performance acceptable (< 2 minutes)
- [ ] All justfile recipes work inside container
- [ ] Windows user can open container (if supporting Windows)
- [ ] Package.json change reflected after rebuild

### Integration Testing
- [ ] Fresh clone -> bootstrap -> dev container -> run dev server
- [ ] Publishing workflow (if vault mounted)
- [ ] Code-only workflow (no vault)

---

## Prevention Checklist

### justfile Setup
- [ ] Set shell explicitly: `set shell := ["bash", "-cu"]`
- [ ] Use `{{variable}}` for just vars, `$VARIABLE` for env vars
- [ ] Chain dependent commands with `&&` or use shebang recipes
- [ ] Test recipes on target platform(s)
- [ ] Consistent indentation per recipe (tabs preferred)

### Claude Hooks Setup
- [ ] Use exit code 2 + stderr for simple blocking
- [ ] Use exit code 0 + JSON for structured control
- [ ] Set explicit timeouts for long-running hooks (builds: 300s)
- [ ] Use inline hooks in settings.json for critical safety
- [ ] Test hooks with `/hooks` command after configuration
- [ ] Restart Claude Code after changing hooks
- [ ] Verify .claude/settings.local.json is in .gitignore

### Publishing Pipeline
- [ ] Convert Obsidian `![[]]` syntax to standard markdown
- [ ] Copy images to public/ with absolute paths
- [ ] Validate image filenames (no spaces, no special chars)
- [ ] Validate frontmatter values, not just presence
- [ ] Extract year from pubDatetime for folder placement
- [ ] Use yq (not grep) for YAML boolean parsing
- [ ] Build check before commit (catches missing images)
- [ ] Atomic operations: copy all, validate all, commit all

### Git Safety
- [ ] Block all force push variations: `--force`, `-f`, `--force-with-lease`, `+ref`
- [ ] Block all destructive commands: `reset --hard`, `checkout .`, `clean -f`, `restore .`
- [ ] Document that Claude hooks work even when git --no-verify used
- [ ] Recommend GitHub branch protection as additional layer
- [ ] Validate at commit time, not just push time

## Sources

### Official Documentation (HIGH confidence)
- [Just Programmer's Manual](https://just.systems/man/en/)
- [Just Settings](https://just.systems/man/en/settings.html)
- [Claude Code Hooks Reference](https://code.claude.com/docs/en/hooks)
- [Claude Code Settings](https://code.claude.com/docs/en/settings)
- [Git Hooks Documentation](https://git-scm.com/docs/githooks)
- [Astro Images Guide](https://docs.astro.build/en/guides/images/)
- [Astro Content Collections](https://docs.astro.build/en/guides/content-collections/)
- [VS Code Dev Containers Documentation](https://code.visualstudio.com/docs/devcontainers/containers)
- [Dev Container Performance Guide](https://code.visualstudio.com/remote/advancedcontainers/improve-performance)
- [Dev Container Environment Variables](https://code.visualstudio.com/remote/advancedcontainers/environment-variables)
- [Dev Container Lifecycle Commands](https://containers.dev/implementors/json_reference/)

### Known Issues (MEDIUM confidence)
- [PostToolUse JSON Bug - Issue #3983](https://github.com/anthropics/claude-code/issues/3983)
- [Plugin Hooks JSON Bug - Issue #10875](https://github.com/anthropics/claude-code/issues/10875)
- [Astro Relative Image Paths - Issue #1188](https://github.com/withastro/astro/issues/1188)
- [Windows Path Issues - Issue #6130](https://github.com/microsoft/vscode-remote-release/issues/6130)

### Community Guides (MEDIUM confidence)
- [Write Like a Pro with Astro and Obsidian](https://www.hungrimind.com/articles/obsidian-with-astro)
- [Configuring Obsidian and Astro Assets](https://www.anca.wtf/posts/configuring-obsidian-and-astro-assets-for-markdoc-content-in-an-astro-blog/)
- [Claude Code Hooks Guide](https://claude.com/blog/how-to-configure-hooks)
- [Idempotent Bash Scripts](https://arslan.io/2019/07/03/how-to-write-idempotent-bash-scripts/)
- [DevContainers Best Practices](https://atoms.dev/insights/6d0570e51ba4430296743ef234f4f74d)
- [Node.js Named Volumes Pattern](https://www.kenmuse.com/blog/dev-containers-and-node_modules/)

---
*Research completed: 2026-01-31*
*Last updated: 2026-01-31 (Bootstrap and Dev Container pitfalls added)*
*Confidence: HIGH - Official documentation verified for all critical pitfalls*
