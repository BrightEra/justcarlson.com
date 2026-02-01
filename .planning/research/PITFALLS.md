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

## Bash and YAML Refactoring Pitfalls

**Added:** 2026-02-01
**Context:** Refactoring milestone - updating bash scripts and YAML handling for two-way sync, schema migration (`status: Published` to `draft: false`), and shared library extraction

### Critical: YAML Corruption via sed/regex

**What goes wrong:** Using `sed` or regex to modify YAML frontmatter corrupts whitespace, quoting, or multiline values. YAML is whitespace-significant; naive string manipulation breaks parsing.

**Why it happens:** The current scripts use patterns like:
```bash
sed -n '/^---$/,/^---$/p' "$file"
perl -0777 -pe 's/^author:\s*\n\s*-\s*.*$/author: "Justin Carlson"/m'
```
These work for simple cases but fail on:
- Multiline values (descriptions with line breaks)
- Values containing colons, quotes, or special characters
- Inconsistent indentation
- Trailing whitespace preservation

**Consequences:**
- Post frontmatter becomes unparsable
- Astro build fails with cryptic YAML errors
- User's Obsidian source corrupted if two-way sync writes back

**Detection (warning signs):**
- Build errors mentioning "mapping values" or "unexpected character"
- Frontmatter fields appearing in content body
- Quotes appearing where none existed before

**Prevention:**
1. **Use yq instead of sed for YAML modifications.** yq is a YAML-aware processor that preserves structure:
   ```bash
   yq --front-matter="process" -i '.draft = false' file.md
   ```
2. **Extract, modify, reassemble.** If yq isn't available, extract frontmatter to temp file, modify with proper YAML tools, reassemble.
3. **Validate after modification.** Run `yq '.' file.md` to verify YAML is still valid before writing.

**Which phase addresses:** Phase 1 (Library Extraction) - Replace sed-based YAML manipulation with yq-based functions.

**Sources:**
- [yq Front Matter Documentation](https://mikefarah.gitbook.io/yq/usage/front-matter)
- [YAML Multiline Strings](https://yaml-multiline.info/)

---

### Critical: Data Loss via Two-Way Sync Without Backup

**What goes wrong:** Modifying user's Obsidian vault files without backup causes permanent data loss when scripts malfunction or have bugs.

**Why it happens:** Current `publish.sh` only reads from Obsidian; new two-way sync will write back. Any bug in write logic corrupts the user's source of truth.

**Consequences:**
- User loses post content they've been drafting
- Frontmatter modifications overwrite user's metadata
- No recovery path without manual git operations (if vault is even in git)

**Detection (warning signs):**
- User reports "my post disappeared"
- Frontmatter shows unexpected values
- File modification timestamps change unexpectedly

**Prevention:**
1. **Atomic write pattern.** Write to temp file, then `mv` to target:
   ```bash
   tmp="${file}.tmp.$$"
   echo "$content" > "$tmp" && mv "$tmp" "$file"
   ```
2. **Backup before any modification:**
   ```bash
   backup="${file}.backup.$(date +%s)"
   cp "$file" "$backup"
   # ... make modifications ...
   # On success, remove backup
   rm "$backup"
   ```
3. **Never modify in-place.** Always read -> transform -> write new.
4. **Implement dry-run for sync.** Show what would change without changing.

**Which phase addresses:** Phase 1 (Library Extraction) - Build `safe_write()` function with atomic writes and backup before any Obsidian file modification.

**Sources:**
- [Atomic File Modifications](https://dev.to/martinhaeusler/towards-atomic-file-modifications-2a9n)
- [Two-Way Sync Best Practices](https://www.stacksync.com/blog/two-way-sync-demystified-key-principles-and-best-practices)

---

### Critical: Cross-Platform sed Incompatibility (macOS vs Linux)

**What goes wrong:** Scripts work on developer's machine (Linux) but fail on user's machine (macOS) due to BSD vs GNU sed differences.

**Why it happens:** The `-i` flag behaves differently:
- **GNU sed (Linux):** `sed -i 's/old/new/' file` (no backup)
- **BSD sed (macOS):** `sed -i '' 's/old/new/' file` (requires empty string)

Running Linux syntax on macOS: `sed -i 's/old/new/' file` interprets `'s/old/new/'` as the backup extension, causing bizarre errors.

**Consequences:**
- "undefined label" or "invalid command code" errors
- Unexpected backup files created (e.g., `file's/old/new/'`)
- Scripts work in CI but fail locally (or vice versa)

**Detection (warning signs):**
- Error messages containing "invalid command code" followed by a letter
- Backup files with weird names appearing
- Works on one machine, fails on another

**Prevention:**
1. **Always use backup extension (works on both):**
   ```bash
   sed -i.bak -e 's/old/new/' file && rm file.bak
   ```
2. **Detect platform and branch:**
   ```bash
   if [[ "$OSTYPE" == "darwin"* ]]; then
       sed -i '' -e 's/old/new/' file
   else
       sed -i -e 's/old/new/' file
   fi
   ```
3. **Prefer yq over sed for YAML.** yq is consistent across platforms.
4. **Document macOS requirements.** If using GNU tools, tell macOS users to install via Homebrew.

**Which phase addresses:** Phase 1 (Library Extraction) - Create platform-aware utility functions or standardize on yq.

**Sources:**
- [GNU sed vs BSD sed (Baeldung)](https://www.baeldung.com/linux/gnu-bsd-stream-editor)
- [sed in-place portability fix](https://sqlpey.com/bash/sed-in-place-portability-fix/)

---

### Critical: Migration Breaks Existing Published Posts

**What goes wrong:** Schema migration from `status: Published` to `draft: false` breaks existing published posts or causes them to be re-published/unpublished unexpectedly.

**Why it happens:**
- Migration script misses edge cases (empty values, different formats)
- Both old and new detection logic runs simultaneously during transition
- Posts in intermediate state (has `status` but not `draft`) handled inconsistently

**Consequences:**
- Published posts disappear from site
- Draft posts accidentally published
- Duplicate posts if migration creates new files instead of updating

**Detection (warning signs):**
- Post count changes unexpectedly after migration
- Build output shows different posts than expected
- Posts with neither old nor new field exist

**Prevention:**
1. **Migration phases:**
   - Phase A: Add new field alongside old (both `status` and `draft`)
   - Phase B: Update detection to prefer new field, fall back to old
   - Phase C: Remove old field support
2. **Explicit state mapping:**
   ```
   status: Published  ->  draft: false
   status: Draft      ->  draft: true
   status: (missing)  ->  draft: true (safe default)
   ```
3. **Pre-migration audit:** List all posts with their current status before migrating.
4. **Post-migration verification:** Compare published post count before/after.
5. **Rollback plan:** Keep old detection logic available for quick revert.

**Which phase addresses:** Dedicated migration phase after library extraction is stable.

**Sources:**
- [Database Schema Migration Best Practices](https://amasucci.com/posts/database-migrations-best-practices/)

---

### Moderate: Shared Library Variable Scope Leakage

**What goes wrong:** Extracting shared functions into a library causes variable conflicts because bash variables are global by default.

**Why it happens:** Current scripts declare variables at top level:
```bash
CONFIG_FILE=".claude/settings.local.json"
BLOG_DIR="src/content/blog"
RED='\033[0;31m'
```
When sourced into another script, these overwrite caller's variables with same names.

**Detection:**
- Functions behave differently when called from different scripts
- Variables have unexpected values
- "variable unbound" errors in strict mode

**Prevention:**
1. **Use `local` in all functions:**
   ```bash
   my_function() {
       local config_file=".claude/settings.local.json"
       local result
       # ...
   }
   ```
2. **Namespace prefix for library globals:**
   ```bash
   _BLOG_LIB_CONFIG_FILE=".claude/settings.local.json"
   _BLOG_LIB_RED='\033[0;31m'
   ```
3. **Guard against double-sourcing:**
   ```bash
   if [[ -n "${_BLOG_LIB_LOADED:-}" ]]; then
       return 0
   fi
   _BLOG_LIB_LOADED=1
   ```
4. **Document public vs private functions:** Prefix private helpers with underscore.

**Which phase addresses:** Phase 1 (Library Extraction) - Define naming conventions before extracting.

**Sources:**
- [Designing Modular Bash: Functions, Namespaces, and Library Patterns](https://www.lost-in-it.com/posts/designing-modular-bash-functions-namespaces-library-patterns/)

---

### Moderate: Duplicated Code Drift

**What goes wrong:** During refactoring, the shared library and individual scripts both contain the same function, and they drift out of sync.

**Why it happens:** Incremental refactoring leaves temporary duplication:
- Library has `slugify()`
- `publish.sh` still has its own `slugify()` (not yet updated to source library)
- Bug fix applied to one but not the other

**Detection:**
- Same function name appears in multiple files
- Behavior differs between scripts for same input
- Bug fixes needed in multiple places

**Prevention:**
1. **Extract all-or-nothing per function.** When moving `slugify()` to library, update ALL callers in same commit.
2. **Delete after extraction.** Don't leave old implementations "just in case."
3. **Add tests for library functions.** Catch drift via test failures.
4. **Use shellcheck:** It can warn about function redefinitions.

**Which phase addresses:** Phase 1 (Library Extraction) - Plan extraction order to avoid partial states.

---

### Moderate: Two-Way Sync Conflict Detection Failure

**What goes wrong:** User modifies post in Obsidian while the blog also modified it (via an earlier publish). Sync overwrites one version without warning.

**Why it happens:**
- No conflict detection: sync assumes source always wins
- No modification timestamp comparison
- No diff presentation to user

**Detection:**
- User complains about lost changes
- Unexpected content in either Obsidian or blog
- Same content appearing in both places when it shouldn't

**Prevention:**
1. **Track last sync time per file.** Store hash or timestamp of last synced version.
2. **Detect conflicts before writing:**
   ```bash
   local obsidian_mtime=$(stat -c %Y "$obsidian_file")
   local blog_mtime=$(stat -c %Y "$blog_file")
   local last_sync_time=$(get_last_sync_time "$slug")

   if [[ $obsidian_mtime -gt $last_sync_time && $blog_mtime -gt $last_sync_time ]]; then
       warn "Conflict detected: both files modified since last sync"
       # Show diff, prompt user
   fi
   ```
3. **Default to read-only sync.** Only write back when explicitly requested.
4. **Store sync state.** Create `.sync-state.json` tracking last sync per file.

**Which phase addresses:** Phase 2 (Two-Way Sync) - Design conflict detection before implementing write-back.

**Sources:**
- [Two-Way Data Synchronization Best Practices](https://www.ubackup.com/synchronization/two-way-data-synchronization-5740.html)

---

### Moderate: YAML Quoting Inconsistency

**What goes wrong:** Some values get quoted, others don't, leading to parsing differences or invalid YAML.

**Why it happens:** Different code paths handle quoting differently:
```bash
# Current pattern - inconsistent quoting
title=$(echo "$frontmatter" | sed "s/^title:[[:space:]]*//" | sed 's/^"//' | sed 's/"$//')
```
This strips quotes on read but doesn't preserve the original format on write.

**Consequences:**
- Values with colons break: `title: Foo: A Story` becomes invalid
- Special characters in descriptions cause YAML errors
- Round-trip through sync changes file format

**Detection:**
- YAML parse errors after round-trip
- Values look different after sync
- Colons or quotes appearing/disappearing in frontmatter

**Prevention:**
1. **Always quote string values in YAML output:**
   ```bash
   echo "title: \"$title\""
   ```
2. **Use yq for consistent quoting:**
   ```bash
   yq -i '.title = "'"$title"'"' file.md
   ```
3. **Preserve original quoting style.** If it was single-quoted, keep it single-quoted.
4. **Escape special characters:** Handle `"`, `\`, and newlines in values.

**Which phase addresses:** Phase 1 (Library Extraction) - Standardize YAML output format.

**Sources:**
- [YAML Multiline Strings](https://yaml-multiline.info/)

---

### Minor: Color Codes Breaking Non-TTY Output

**What goes wrong:** Color escape codes appear as garbage in logs, pipes, or non-terminal output.

**Why it happens:** Current scripts unconditionally emit ANSI color codes:
```bash
RED='\033[0;31m'
echo -e "${RED}Error${RESET}"
```

**Detection:**
- Log files contain `[0;31m` sequences
- Output looks garbled when piped

**Prevention:**
```bash
if [[ -t 1 ]]; then
    RED='\033[0;31m'
    RESET='\033[0m'
else
    RED=''
    RESET=''
fi
```

**Which phase addresses:** Phase 1 (Library Extraction) - Add TTY detection to color definitions.

---

### Minor: Perl Dependency Not Checked

**What goes wrong:** Scripts fail with "perl: command not found" on minimal systems.

**Why it happens:** Current scripts use perl for multiline regex:
```bash
perl -0777 -ne 'exit(!/status:\s*\n\s*-\s*[Pp]ublished/i)' "$file"
```
Perl is assumed but not checked.

**Detection:**
- Scripts fail on Docker containers or minimal installs
- "command not found" errors

**Prevention:**
```bash
if ! command -v perl &>/dev/null; then
    echo "Error: perl is required" >&2
    exit 1
fi
```
Or better: replace perl with yq which handles multiline YAML natively.

**Which phase addresses:** Phase 1 (Library Extraction) - Add dependency checks or replace perl usage.

---

### Minor: Rollback Doesn't Restore Git State

**What goes wrong:** Rollback removes created files but doesn't undo git operations like `git add` or `git commit`.

**Why it happens:** Current `rollback_changes()` tracks files but not git state:
```bash
rollback_changes() {
    for ((i=${#CREATED_FILES[@]}-1; i>=0; i--)); do
        rm -f "${CREATED_FILES[$i]}"
    done
}
```

**Detection:**
- After rollback, `git status` shows unexpected staged files
- Commits exist that should have been rolled back

**Prevention:**
1. **Track git state before operations:**
   ```bash
   local initial_commit=$(git rev-parse HEAD)
   ```
2. **Rollback includes git reset:**
   ```bash
   git reset --hard "$initial_commit"
   ```
3. **Use git stash for uncommitted changes.**

**Which phase addresses:** Phase 1 (Library Extraction) - Enhance rollback to include git state.

---

## Existing Code Analysis: Current Fragile Patterns

**Analyzed:** 2026-02-01
**Files:** `/home/jc/developer/justcarlson.com/scripts/`

| File | Pattern | Risk | Recommendation |
|------|---------|------|----------------|
| `publish.sh` | `sed -n '/^---$/,/^---$/p'` | MEDIUM | Replace with yq extraction |
| `publish.sh` | `perl -0777 -pe 's/...'` | HIGH | Replace with yq modification |
| `publish.sh` | No backup before normalize | HIGH | Add backup to normalize_frontmatter |
| `publish.sh` | Hardcoded color codes | LOW | Add TTY detection |
| `list-posts.sh` | Duplicate validation code | MEDIUM | Extract to shared library |
| `list-posts.sh` | Duplicate extract_frontmatter | MEDIUM | Share with publish.sh |
| `unpublish.sh` | Duplicate slugify function | LOW | Extract to shared library |
| `unpublish.sh` | Duplicate extract_frontmatter_value | MEDIUM | Share with other scripts |
| All scripts | No yq dependency check | MEDIUM | Add to prerequisites |
| All scripts | perl assumed available | MEDIUM | Check or replace |

---

## Recommended Tool Adoption: yq

**Replace sed/perl with yq for YAML operations:**

```bash
# Instead of:
perl -0777 -pe 's/^author:\s*\n\s*-\s*.*$/author: "Justin Carlson"/m'

# Use:
yq --front-matter="process" -i '.author = "Justin Carlson"' "$file"
```

```bash
# Instead of:
perl -0777 -ne 'exit(!/status:\s*\n\s*-\s*[Pp]ublished/i)' "$file"

# Use:
yq --front-matter="extract" '.status[] | select(. == "Published" or . == "published")' "$file"
```

**Benefits:**
- YAML-aware: preserves whitespace, quoting, multiline values
- Cross-platform: same behavior on macOS and Linux
- Composable: can chain operations
- Safer: won't corrupt malformed YAML (fails loudly instead)

**Installation:**
```bash
# Arch
pacman -S yq

# macOS
brew install yq

# Check version (need mikefarah/yq, not kislyuk/yq)
yq --version  # should show "yq (https://github.com/mikefarah/yq/)"
```

---

## Bash/YAML Refactoring Phase-Specific Warnings

| Phase | Topic | Likely Pitfall | Mitigation |
|-------|-------|----------------|------------|
| Library extraction | Variable scope | Leakage between scripts | Use `local`, namespace prefixes, guard against double-source |
| Library extraction | Code drift | Duplicated functions diverge | Extract all-or-nothing, delete after extraction |
| YAML manipulation | sed/regex corruption | Whitespace/quoting destroyed | Use yq with `--front-matter` flag |
| YAML manipulation | Platform differences | BSD vs GNU sed | Platform detection or yq standardization |
| Two-way sync | Data loss on write | User's source corrupted | Atomic writes, backup before modify |
| Two-way sync | Conflict detection | Silent overwrite | Track sync state, compare timestamps |
| Schema migration | Breaking posts | Published posts disappear | Phased migration with overlap period |
| Schema migration | Edge cases | Empty values, mixed formats | Pre-migration audit, explicit state mapping |

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

### Bash/YAML Refactoring (NEW)
- [ ] Use yq instead of sed for YAML modifications
- [ ] Back up files before any write to Obsidian vault
- [ ] Use atomic writes (temp file + mv)
- [ ] Use `local` for all function variables
- [ ] Namespace global variables with prefix (e.g., `_BLOG_LIB_`)
- [ ] Guard against double-sourcing in shared library
- [ ] Test cross-platform (macOS and Linux)
- [ ] Add yq to prerequisite checks
- [ ] Extract functions all-or-nothing (no partial duplication)
- [ ] Implement phased schema migration with overlap

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
- [yq Front Matter Documentation](https://mikefarah.gitbook.io/yq/usage/front-matter)
- [YAML Multiline Strings](https://yaml-multiline.info/)

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
- [GNU sed vs BSD sed (Baeldung)](https://www.baeldung.com/linux/gnu-bsd-stream-editor)
- [sed in-place portability fix](https://sqlpey.com/bash/sed-in-place-portability-fix/)
- [Designing Modular Bash: Functions, Namespaces, and Library Patterns](https://www.lost-in-it.com/posts/designing-modular-bash-functions-namespaces-library-patterns/)
- [BashPitfalls - Greg's Wiki](https://mywiki.wooledge.org/BashPitfalls)
- [Atomic File Modifications](https://dev.to/martinhaeusler/towards-atomic-file-modifications-2a9n)
- [Two-Way Sync Best Practices](https://www.stacksync.com/blog/two-way-sync-demystified-key-principles-and-best-practices)
- [Database Schema Migration Best Practices](https://amasucci.com/posts/database-migrations-best-practices/)

---
*Research completed: 2026-01-31*
*Last updated: 2026-02-01 (Bash and YAML Refactoring pitfalls added)*
*Confidence: HIGH - Official documentation verified for all critical pitfalls*
