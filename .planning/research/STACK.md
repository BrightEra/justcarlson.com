# Technology Stack: Astro Blog Personalization (justcarlson.com)

**Project:** justcarlson.com (forked from steipete.me)
**Researched:** 2026-01-28 (Personalization), 2026-01-31 (Dev Containers)
**Overall Confidence:** HIGH

## Executive Summary

The existing codebase already uses a modern 2025/2026 Astro stack with Tailwind CSS 4, Sharp for image processing, and @resvg/resvg-js for OG image generation. For personalization (favicon, colors, avatar), we can leverage existing infrastructure with minimal additions.

---

## Part 2: Dev Containers & Bootstrap (v0.3.0)

**Researched:** 2026-01-31
**Focus:** Minimal additions for portable first-run experience

### Executive Summary

The existing stack (Astro, npm, justfile, bash scripts) is complete. No new runtime dependencies are needed. The additions are purely configuration files:

1. **Dev container:** Single `devcontainer.json` file (no Dockerfile needed)
2. **Bootstrap:** Extend existing justfile with idempotent `bootstrap` recipe
3. **Node version lock:** `.nvmrc` file for consistency

Total new files: 2 (devcontainer.json, .nvmrc) + 1 justfile recipe modification

### Recommended Additions

#### Dev Container Configuration

| Component | Value | Purpose | Why |
|-----------|-------|---------|-----|
| Base image | `mcr.microsoft.com/devcontainers/typescript-node:22` | Node.js 22 LTS with TypeScript support | Official Microsoft image, maintained, includes common tools |
| Just feature | `ghcr.io/guiyomh/features/just:0` | Install just command runner | Community feature, stable at v0.1.0, listed in official registry |
| postCreateCommand | `just bootstrap` | Auto-run setup after container creation | Single entry point for all setup |

**Configuration file:** `.devcontainer/devcontainer.json`

```json
{
  "name": "justcarlson.com",
  "image": "mcr.microsoft.com/devcontainers/typescript-node:22",
  "features": {
    "ghcr.io/guiyomh/features/just:0": {}
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

**Confidence:** HIGH - Based on official VS Code documentation and containers.dev feature registry.

#### Node Version Lock

| File | Content | Purpose |
|------|---------|---------|
| `.nvmrc` | `22` | Pin Node.js version for nvm/fnm users |

Current project uses Node 22 LTS (package.json targets ES modules compatible with Node 22). The .nvmrc ensures consistency across machines and dev containers.

**Confidence:** HIGH - Standard practice, no runtime impact.

#### Bootstrap Recipe Pattern

Extend existing justfile with idempotent bootstrap recipe:

```just
# === Bootstrap ===

# One-command setup for fresh clone (idempotent)
bootstrap:
    #!/usr/bin/env bash
    set -euo pipefail

    # Install dependencies if needed
    if [[ ! -d "node_modules" ]] || [[ "package.json" -nt "node_modules" ]]; then
        npm install
    fi

    # Run interactive setup only if not configured
    if [[ ! -f ".claude/settings.local.json" ]]; then
        echo "First run detected. Starting setup..."
        just setup
    else
        echo "Already configured. Run 'just setup' to reconfigure."
    fi

    echo ""
    echo "Ready! Run 'just preview' to start dev server."
```

**Key patterns:**
- Shebang for multi-line bash (required for conditionals)
- Check node_modules existence AND freshness (package.json newer = reinstall)
- Leverage existing `just setup` for vault configuration
- Exit message with next step

**Confidence:** HIGH - Uses documented justfile patterns.

### Alternatives Considered

| Category | Recommended | Alternative | Why Not |
|----------|-------------|-------------|---------|
| Container base | typescript-node:22 | javascript-node:22 | TypeScript tooling already in use (astro check) |
| Just feature | guiyomh/features | jsburckhardt/features | guiyomh is listed first in registry, same functionality |
| Just feature | guiyomh/features | postCreateCommand install | Feature is cleaner, versioned, cached |
| Dockerfile | None | Custom Dockerfile | Overkill - no custom system deps needed |
| Docker Compose | None | docker-compose.yml | Single container, no services to orchestrate |

### What NOT to Add

| Temptation | Why Skip |
|------------|----------|
| Dockerfile | The pre-built image has everything needed. Dockerfile adds maintenance burden for no benefit. |
| Docker Compose | No database, no multi-container setup. Single dev container is sufficient. |
| mise/asdf config | Project only needs Node.js. .nvmrc is simpler and universally understood. |
| Devcontainer Dockerfile | Only needed for custom system packages. npm packages install via postCreateCommand. |
| Shell script for bootstrap | justfile already exists, keep it as single entry point. |
| Pre-built devcontainer scripts | Just needs `npm install` and `just setup` - no complexity needed. |

### Files to Create/Modify

```bash
# New files:
.devcontainer/devcontainer.json  # Dev container config
.nvmrc                           # Node version lock

# Modification:
justfile                         # Add bootstrap recipe
```

### Compatibility Notes

#### Dev Container Support

| Environment | Support | Notes |
|-------------|---------|-------|
| VS Code + Docker | Full | Primary target |
| GitHub Codespaces | Full | Uses same devcontainer.json |
| Cursor | Full | Uses VS Code extension |
| JetBrains (Gateway) | Partial | May need adjustments |
| Local (no container) | N/A | Use existing `just setup && npm install` |

#### Justfile Compatibility

The bootstrap recipe uses bash shebang, which works on:
- Linux (native)
- macOS (native)
- Windows (WSL2, Git Bash)
- Dev containers (all have bash)

### Sources

**Dev Container Configuration:**
- [VS Code Create Dev Container](https://code.visualstudio.com/docs/devcontainers/create-dev-container) - Official documentation
- [Dev Container Features Registry](https://containers.dev/features) - Feature discovery
- [guiyomh/features](https://github.com/guiyomh/features) - Just feature source

**Justfile Patterns:**
- [Just Manual](https://just.systems/man/en/) - Official documentation
- [Just GitHub](https://github.com/casey/just) - Examples and patterns

### Confidence Assessment (Dev Containers)

| Component | Confidence | Reason |
|-----------|------------|--------|
| Dev container base image | HIGH | Official Microsoft image |
| Just devcontainer feature | MEDIUM | Community feature, but listed in official registry |
| Bootstrap recipe pattern | HIGH | Standard bash + justfile patterns |
| .nvmrc | HIGH | Universal standard |

---

## Part 1: Personalization Stack (v0.2.0)

### Recommended Stack

#### Core Framework (Already Installed)

| Technology | Version | Purpose | Status | Rationale |
|------------|---------|---------|--------|-----------|
| **Astro** | ^5.16.6 | Static site generator | Installed | Latest Astro 5.x with improved image handling. Already in place. |
| **Tailwind CSS** | ^4.1.18 | Utility-first CSS framework | Installed | v4 with CSS-native @theme configuration. Already configured. |
| **@tailwindcss/vite** | ^4.1.18 | Vite integration for Tailwind v4 | Installed | Required for Tailwind CSS 4. Already configured. |
| **TypeScript** | ^5.9.3 | Type safety | Installed | Standard for modern Astro projects. |

**Confidence:** HIGH - Verified from package.json and astro.config.mjs

#### Image Processing

| Technology | Version | Purpose | Status | Rationale |
|------------|---------|---------|--------|-----------|
| **sharp** | ^0.34.5 | Primary image optimization | Installed | Default image service in Astro 5. 3x faster than alternatives for SVG-PNG. Used for all image optimization. |
| **@resvg/resvg-js** | ^2.6.2 | SVG-PNG conversion | Installed | Already used for OG image generation. Rust-based, high-quality SVG rendering. |
| **satori** | ^0.18.3 | HTML/CSS-SVG conversion | Installed | Used with @resvg/resvg-js for dynamic OG images. Already in generateOgImages.ts. |

**Confidence:** HIGH - Verified in package.json and src/utils/generateOgImages.ts

#### Favicon Generation

| Approach | Complexity | Status | Rationale |
|----------|-----------|---------|-----------|
| **Manual + SVG** | Low | RECOMMENDED | Most control, smallest footprint. Generate sizes manually with existing Sharp/resvg pipeline. |
| **astro-favicons** | Medium | NOT RECOMMENDED | Package last updated for Astro 4.x (~4.16.18). No confirmed Astro 5 compatibility. Adds 20 HTML tags + 19 files - overkill for simple blog. |
| **Dynamic endpoints** | Medium | ALTERNATIVE | Custom Astro endpoints using getImage(). Good for cache-busting but adds build complexity. |

**Recommendation:** Use **manual approach** with SVG source + pre-generated PNG sizes.

**Rationale:**
- Existing codebase already has Sharp and @resvg/resvg-js
- steipete.me uses static files (favicon.ico + peter-avatar.jpg) - simple and effective
- Manual approach = full control, no external dependencies, minimal HTML tags
- Modern browsers support SVG favicons with dark mode via CSS media queries

**Confidence:** HIGH - Based on [Rodney Lab](https://rodneylab.com/astro-js-favicon/), [kremalicious.com](https://kremalicious.com/favicon-generation-with-astro/), and astro-favicons [GitHub releases](https://github.com/ACP-CODE/astro-favicons/releases/)

#### Color Theming (Tailwind CSS 4)

| Technology | Version | Purpose | Status | Rationale |
|------------|---------|---------|--------|-----------|
| **CSS Custom Properties** | Native | Theme variables | Configured | Already using CSS variables in src/styles/global.css with @theme directive. |
| **@theme directive** | Tailwind v4 | Color registration | Configured | Bridges CSS vars to Tailwind utilities. Already configured in global.css. |
| **@custom-variant** | Tailwind v4 | Dark mode variant | Configured | Already using `@custom-variant dark` for data-theme attribute. |

**Current Implementation:**
```css
/* Already in src/styles/global.css */
:root {
  --background: #fdfdfd;
  --foreground: #282728;
  --accent: #006cac;        /* Current: Peter's blue */
  --muted: #e6e6e6;
  --border: #ece9e9;
}

@theme {
  --color-*: initial;
  --color-background: var(--background);
  --color-accent: var(--accent);  /* Maps to bg-accent, text-accent */
}
```

**Required Changes for Personalization:**
1. Update CSS variables in `:root` and `html[data-theme="dark"]` blocks
2. Change `--accent` values to match your color scheme (Leaf Blue light / AstroPaper v4 dark)
3. No new dependencies needed - pure CSS variable updates

**Confidence:** HIGH - Verified in codebase. Based on [Tailwind CSS v4 docs](https://tailwindcss.com/docs/v4-beta), [TailKits guide](https://tailkits.com/blog/tailwind-v4-custom-colors/), and [GitHub discussion](https://github.com/tailwindlabs/tailwindcss/discussions/18471)

#### Avatar/Image Handling

| Approach | Purpose | Status | Rationale |
|----------|---------|--------|-----------|
| **Static file in public/** | Avatar images | Current | Simplest approach. steipete.me uses peter-avatar.jpg (36KB) in public/ root. |
| **Astro Image** | Responsive optimization | Available | For images requiring multiple sizes/formats. Built-in component. |
| **getImage()** | Programmatic optimization | Available | For dynamic image processing in .astro files. |

**Recommendation:** Use **static file in public/** for avatar (replace peter-avatar.jpg).

**Rationale:**
- Avatar is referenced in multiple places (manifest, OG images, about page)
- No responsive sizes needed - single optimized image works
- Pre-optimize with Sharp externally: `sharp input.jpg -o public/avatar.jpg --quality 85 --resize 512x512`
- Keeps build fast, avoids redundant processing

**Confidence:** HIGH - Verified in astro.config.mjs. Based on [Astro docs](https://docs.astro.build/en/guides/images/) and [Uploadcare guide](https://uploadcare.com/blog/how-to-optimize-images-in-astro/)

#### PWA & Manifest

| Technology | Version | Purpose | Status | Rationale |
|------------|---------|---------|--------|-----------|
| **@vite-pwa/astro** | ^1.2.0 | PWA integration | Installed | Zero-config PWA with manifest generation. Already configured in astro.config.mjs. |

**Current Configuration:** Already in `astro.config.mjs` with manifest, service worker, and icon registration.

**Required Changes for Personalization:**
1. Update manifest `name`, `short_name`, `description`
2. Update `theme_color` and `background_color` to match new color scheme
3. Replace `peter-avatar.jpg` with your avatar in manifest `icons` array
4. Update `favicon.ico` reference

**Confidence:** HIGH - Verified in astro.config.mjs. Based on [vite-pwa/astro docs](https://vite-pwa-org.netlify.app/frameworks/astro)

#### Build & Deployment

| Technology | Version | Purpose | Status | Rationale |
|------------|---------|---------|--------|-----------|
| **Vercel** | N/A | Deployment platform | Target | Zero-config Astro detection. Edge network. Free for static sites. |
| **pagefind** | ^1.4.0 | Static search | Installed | Already integrated in build script. No changes needed. |

**Deployment Configuration:**
- Astro auto-detected by Vercel (no config needed)
- Static output (default) - no adapter required
- Build command: `npm run build` (already includes pagefind)
- Output directory: `dist/`

**Confidence:** HIGH - Based on [Vercel Astro docs](https://vercel.com/docs/frameworks/frontend/astro) and [Astro deployment guide](https://docs.astro.build/en/guides/deploy/vercel/)

### Alternatives Considered

#### Favicon Generation

| Option | Pros | Cons | Why Not |
|--------|------|------|---------|
| **astro-favicons** | Automated, comprehensive | 19 files + 20 HTML tags, no Astro 5 confirmation | Overkill for blog. Unconfirmed Astro 5 support. |
| **Dynamic endpoints** | Cache-busting, flexible | Adds complexity, slower builds | Unnecessary for static blog. |
| **Manual + scripts** | Full control, minimal footprint | More setup work | Chosen - best balance for this use case |

#### Image Processing

| Option | Pros | Cons | Why Not |
|--------|------|------|---------|
| **@resvg/resvg-js only** | High quality SVG rendering | 3x slower than Sharp for bulk operations, crashes on 400+ SVGs | Sharp already installed and faster. Use resvg only for OG images (as currently done). |
| **Unpic** | Multi-CDN support | External dependency, CDN lock-in | Static blog doesn't need CDN abstraction. |

#### Color Management

| Option | Pros | Cons | Why Not |
|--------|------|------|---------|
| **Radix Colors** | Curated palettes, accessibility | External dependency, prescriptive | Simple blog doesn't need design system. CSS vars sufficient. |
| **OKLCH color space** | Perceptually uniform | Browser support still maturing | Hex colors work fine for simple palette. |

### Installation

**No new packages required.** All necessary tools already installed.

For reference, existing relevant packages:
```bash
# Core (already installed)
astro@^5.16.6
tailwindcss@^4.1.18
@tailwindcss/vite@^4.1.18

# Image processing (already installed)
sharp@^0.34.5
@resvg/resvg-js@^2.6.2
satori@^0.18.3

# PWA (already installed)
@vite-pwa/astro@^1.2.0
```

### Version Verification

**Last verified:** 2026-01-28

| Package | Current | Latest Stable | Status |
|---------|---------|---------------|--------|
| astro | 5.16.6 | ~5.16.x | Current |
| tailwindcss | 4.1.18 | ~4.1.x | Current |
| sharp | 0.34.5 | ~0.34.x | Current |
| @resvg/resvg-js | 2.6.2 | ~2.6.x | Current |

**Note:** Versions checked against package.json. Astro 5.x and Tailwind 4.x are latest stable as of early 2026.

---

## Combined Sources & References

### Official Documentation
- [Astro Images Guide](https://docs.astro.build/en/guides/images/) - Official image handling
- [Tailwind CSS v4 Beta](https://tailwindcss.com/docs/v4-beta) - v4 theming and configuration
- [Vercel Astro Docs](https://vercel.com/docs/frameworks/frontend/astro) - Deployment guide
- [Vite PWA for Astro](https://vite-pwa-org.netlify.app/frameworks/astro) - PWA integration
- [VS Code Create Dev Container](https://code.visualstudio.com/docs/devcontainers/create-dev-container) - Dev container setup
- [Dev Container Features Registry](https://containers.dev/features) - Feature discovery

### Technical Comparisons
- [Sharp vs resvg-js benchmark](https://github.com/privatenumber/sharp-vs-resvgjs) - Performance comparison (Sharp 3x faster)
- [GitHub: Theming in v4](https://github.com/tailwindlabs/tailwindcss/discussions/18471) - Tailwind CSS 4 best practices

### Implementation Guides
- [Favicon Generation with Astro - kremalicious](https://kremalicious.com/favicon-generation-with-astro/) - Manual favicon approach
- [Rodney Lab: Astro JS Favicon](https://rodneylab.com/astro-js-favicon/) - Required favicon files
- [Tailwind v4 Colors - TailKits](https://tailkits.com/blog/tailwind-v4-custom-colors/) - Color customization
- [How to optimize images in Astro - Uploadcare](https://uploadcare.com/blog/how-to-optimize-images-in-astro/) - Image optimization
- [Just Manual](https://just.systems/man/en/) - Justfile patterns
- [guiyomh/features](https://github.com/guiyomh/features) - Dev container just feature

### Package Documentation
- [astro-favicons on GitHub](https://github.com/ACP-CODE/astro-favicons) - Evaluated but not recommended
- [@resvg/resvg-js on npm](https://www.npmjs.com/package/@resvg/resvg-js) - SVG rendering library

---

## Confidence Assessment (Combined)

| Area | Confidence | Notes |
|------|-----------|-------|
| **Favicon approach** | HIGH | Verified codebase uses static files. Manual approach proven in production. |
| **Color theming** | HIGH | Tailwind CSS 4 @theme configuration verified in global.css. |
| **Image handling** | HIGH | Sharp + @resvg confirmed in package.json. Sharp is Astro 5 default. |
| **PWA manifest** | HIGH | @vite-pwa/astro config verified in astro.config.mjs. |
| **Deployment** | HIGH | Vercel + Astro is well-documented standard. |
| **Dev container base** | HIGH | Official Microsoft image. |
| **Just devcontainer feature** | MEDIUM | Community feature, listed in official registry. |
| **Bootstrap pattern** | HIGH | Standard bash + justfile idioms. |
| **astro-favicons** | MEDIUM-LOW | No explicit Astro 5 compatibility statement found. |

## Open Questions

None. All personalization and portability requirements can be addressed with existing infrastructure plus minimal configuration additions.
