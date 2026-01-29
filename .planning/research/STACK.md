# Technology Stack: Astro Blog Personalization (justcarlson.com)

**Project:** justcarlson.com (forked from steipete.me)
**Researched:** 2026-01-28
**Overall Confidence:** HIGH

## Executive Summary

The existing codebase already uses a modern 2025/2026 Astro stack with Tailwind CSS 4, Sharp for image processing, and @resvg/resvg-js for OG image generation. For personalization (favicon, colors, avatar), we can leverage existing infrastructure with minimal additions.

## Recommended Stack

### Core Framework (Already Installed)

| Technology | Version | Purpose | Status | Rationale |
|------------|---------|---------|--------|-----------|
| **Astro** | ^5.16.6 | Static site generator | ✅ Installed | Latest Astro 5.x with improved image handling. Already in place. |
| **Tailwind CSS** | ^4.1.18 | Utility-first CSS framework | ✅ Installed | v4 with CSS-native @theme configuration. Already configured. |
| **@tailwindcss/vite** | ^4.1.18 | Vite integration for Tailwind v4 | ✅ Installed | Required for Tailwind CSS 4. Already configured. |
| **TypeScript** | ^5.9.3 | Type safety | ✅ Installed | Standard for modern Astro projects. |

**Confidence:** HIGH - Verified from package.json and astro.config.mjs

### Image Processing

| Technology | Version | Purpose | Status | Rationale |
|------------|---------|---------|--------|-----------|
| **sharp** | ^0.34.5 | Primary image optimization | ✅ Installed | Default image service in Astro 5. 3x faster than alternatives for SVG→PNG. Used for all image optimization. |
| **@resvg/resvg-js** | ^2.6.2 | SVG→PNG conversion | ✅ Installed | Already used for OG image generation. Rust-based, high-quality SVG rendering. |
| **satori** | ^0.18.3 | HTML/CSS→SVG conversion | ✅ Installed | Used with @resvg/resvg-js for dynamic OG images. Already in generateOgImages.ts. |

**Confidence:** HIGH - Verified in package.json and src/utils/generateOgImages.ts

### Favicon Generation

| Approach | Complexity | Status | Rationale |
|----------|-----------|---------|-----------|
| **Manual + SVG** | Low | ⭐ RECOMMENDED | Most control, smallest footprint. Generate sizes manually with existing Sharp/resvg pipeline. |
| **astro-favicons** | Medium | ❌ NOT RECOMMENDED | Package last updated for Astro 4.x (~4.16.18). No confirmed Astro 5 compatibility. Adds 20 HTML tags + 19 files - overkill for simple blog. |
| **Dynamic endpoints** | Medium | 🟡 ALTERNATIVE | Custom Astro endpoints using getImage(). Good for cache-busting but adds build complexity. |

**Recommendation:** Use **manual approach** with SVG source + pre-generated PNG sizes.

**Rationale:**
- Existing codebase already has Sharp and @resvg/resvg-js
- steipete.me uses static files (favicon.ico + peter-avatar.jpg) - simple and effective
- Manual approach = full control, no external dependencies, minimal HTML tags
- Modern browsers support SVG favicons with dark mode via CSS media queries

**Confidence:** HIGH - Based on [Rodney Lab](https://rodneylab.com/astro-js-favicon/), [kremalicious.com](https://kremalicious.com/favicon-generation-with-astro/), and astro-favicons [GitHub releases](https://github.com/ACP-CODE/astro-favicons/releases/)

### Color Theming (Tailwind CSS 4)

| Technology | Version | Purpose | Status | Rationale |
|------------|---------|---------|--------|-----------|
| **CSS Custom Properties** | Native | Theme variables | ✅ Configured | Already using CSS variables in src/styles/global.css with @theme directive. |
| **@theme directive** | Tailwind v4 | Color registration | ✅ Configured | Bridges CSS vars to Tailwind utilities. Already configured in global.css. |
| **@custom-variant** | Tailwind v4 | Dark mode variant | ✅ Configured | Already using `@custom-variant dark` for data-theme attribute. |

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

### Avatar/Image Handling

| Approach | Purpose | Status | Rationale |
|----------|---------|--------|-----------|
| **Static file in public/** | Avatar images | ✅ Current | Simplest approach. steipete.me uses peter-avatar.jpg (36KB) in public/ root. |
| **Astro <Image />** | Responsive optimization | ✅ Available | For images requiring multiple sizes/formats. Built-in component. |
| **getImage()** | Programmatic optimization | ✅ Available | For dynamic image processing in .astro files. |

**Recommendation:** Use **static file in public/** for avatar (replace peter-avatar.jpg).

**Rationale:**
- Avatar is referenced in multiple places (manifest, OG images, about page)
- No responsive sizes needed - single optimized image works
- Pre-optimize with Sharp externally: `sharp input.jpg -o public/avatar.jpg --quality 85 --resize 512x512`
- Keeps build fast, avoids redundant processing

**Confidence:** HIGH - Verified in astro.config.mjs. Based on [Astro docs](https://docs.astro.build/en/guides/images/) and [Uploadcare guide](https://uploadcare.com/blog/how-to-optimize-images-in-astro/)

### PWA & Manifest

| Technology | Version | Purpose | Status | Rationale |
|------------|---------|---------|--------|-----------|
| **@vite-pwa/astro** | ^1.2.0 | PWA integration | ✅ Installed | Zero-config PWA with manifest generation. Already configured in astro.config.mjs. |

**Current Configuration:** Already in `astro.config.mjs` with manifest, service worker, and icon registration.

**Required Changes for Personalization:**
1. Update manifest `name`, `short_name`, `description`
2. Update `theme_color` and `background_color` to match new color scheme
3. Replace `peter-avatar.jpg` with your avatar in manifest `icons` array
4. Update `favicon.ico` reference

**Confidence:** HIGH - Verified in astro.config.mjs. Based on [vite-pwa/astro docs](https://vite-pwa-org.netlify.app/frameworks/astro)

### Build & Deployment

| Technology | Version | Purpose | Status | Rationale |
|------------|---------|---------|--------|-----------|
| **Vercel** | N/A | Deployment platform | 🎯 Target | Zero-config Astro detection. Edge network. Free for static sites. |
| **pagefind** | ^1.4.0 | Static search | ✅ Installed | Already integrated in build script. No changes needed. |

**Deployment Configuration:**
- Astro auto-detected by Vercel (no config needed)
- Static output (default) - no adapter required
- Build command: `npm run build` (already includes pagefind)
- Output directory: `dist/`

**Confidence:** HIGH - Based on [Vercel Astro docs](https://vercel.com/docs/frameworks/frontend/astro) and [Astro deployment guide](https://docs.astro.build/en/guides/deploy/vercel/)

## Alternatives Considered

### Favicon Generation

| Option | Pros | Cons | Why Not |
|--------|------|------|---------|
| **astro-favicons** | Automated, comprehensive | 19 files + 20 HTML tags, no Astro 5 confirmation | Overkill for blog. Unconfirmed Astro 5 support. |
| **Dynamic endpoints** | Cache-busting, flexible | Adds complexity, slower builds | Unnecessary for static blog. |
| **Manual + scripts** | Full control, minimal footprint | More setup work | ✅ Chosen - best balance for this use case |

### Image Processing

| Option | Pros | Cons | Why Not |
|--------|------|------|---------|
| **@resvg/resvg-js only** | High quality SVG rendering | 3x slower than Sharp for bulk operations, crashes on 400+ SVGs | Sharp already installed and faster. Use resvg only for OG images (as currently done). |
| **Unpic** | Multi-CDN support | External dependency, CDN lock-in | Static blog doesn't need CDN abstraction. |

### Color Management

| Option | Pros | Cons | Why Not |
|--------|------|------|---------|
| **Radix Colors** | Curated palettes, accessibility | External dependency, prescriptive | Simple blog doesn't need design system. CSS vars sufficient. |
| **OKLCH color space** | Perceptually uniform | Browser support still maturing | Hex colors work fine for simple palette. |

## Installation

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

## Personalization Checklist

### 1. Favicon Generation
- [ ] Export new favicon as SVG (512×512px recommended)
- [ ] Generate PNG sizes: 16×16, 32×32, 192×192, 512×512
- [ ] Generate apple-touch-icon.png (180×180)
- [ ] Generate favicon.ico (multi-size: 16, 32, 48)
- [ ] Place files in `public/` directory
- [ ] Update `includeAssets` in astro.config.mjs

**Tools to use:** Sharp CLI or existing @resvg/resvg-js pipeline

### 2. Color Theme
- [ ] Update `--accent` in `:root` (light mode) to Leaf Blue
- [ ] Update `--accent` in `html[data-theme="dark"]` to AstroPaper v4 dark accent
- [ ] Verify other colors (background, foreground, muted, border) complement new accent
- [ ] Update `theme_color` and `background_color` in astro.config.mjs manifest

**Files to edit:** `src/styles/global.css`, `astro.config.mjs`

### 3. Avatar/Profile Image
- [ ] Optimize new avatar image (512×512px, 85% quality JPEG or WebP)
- [ ] Place in `public/` as `avatar.jpg` (or update all references to new filename)
- [ ] Update `SITE.ogImage` in `src/consts.ts`
- [ ] Update manifest `icons` array in `astro.config.mjs`
- [ ] Update any hardcoded references (search for `peter-avatar.jpg`)

### 4. Site Metadata
- [ ] Update `SITE` object in `src/consts.ts` (author, website, profile, desc, title)
- [ ] Update manifest in `astro.config.mjs` (name, short_name, description)
- [ ] Update `SOCIAL_LINKS` in `src/consts.ts`
- [ ] Update `editPost.url` to point to your GitHub repo

### 5. Deployment
- [ ] Connect GitHub repo to Vercel
- [ ] Verify build completes (should auto-detect Astro)
- [ ] Configure custom domain (if applicable)
- [ ] Set up environment variables (if needed)

## Migration Notes from steipete.me

**Existing Infrastructure (Keep):**
- ✅ Astro 5 + Tailwind CSS 4 already configured correctly
- ✅ Sharp + @resvg/resvg-js pipeline already optimal
- ✅ OG image generation (satori + resvg) already working
- ✅ PWA manifest already configured with @vite-pwa/astro
- ✅ Build pipeline (pagefind, sitemap, RSS) already complete

**Items to Replace:**
1. Static assets: favicon.ico, peter-avatar.jpg, peter-office.jpg, peter-office-2.jpg
2. CSS variables: colors in global.css
3. Configuration: SITE object in consts.ts, manifest in astro.config.mjs
4. Content: About page, blog posts (already done or in progress)

**Low-Risk Changes:** All personalization is content/asset replacement, not architectural changes.

## Version Verification

**Last verified:** 2026-01-28

| Package | Current | Latest Stable | Status |
|---------|---------|---------------|--------|
| astro | 5.16.6 | ~5.16.x | ✅ Current |
| tailwindcss | 4.1.18 | ~4.1.x | ✅ Current |
| sharp | 0.34.5 | ~0.34.x | ✅ Current |
| @resvg/resvg-js | 2.6.2 | ~2.6.x | ✅ Current |

**Note:** Versions checked against package.json. Astro 5.x and Tailwind 4.x are latest stable as of early 2026.

## Sources & References

### Official Documentation
- [Astro Images Guide](https://docs.astro.build/en/guides/images/) - Official image handling
- [Tailwind CSS v4 Beta](https://tailwindcss.com/docs/v4-beta) - v4 theming and configuration
- [Vercel Astro Docs](https://vercel.com/docs/frameworks/frontend/astro) - Deployment guide
- [Vite PWA for Astro](https://vite-pwa-org.netlify.app/frameworks/astro) - PWA integration

### Technical Comparisons
- [Sharp vs resvg-js benchmark](https://github.com/privatenumber/sharp-vs-resvgjs) - Performance comparison (Sharp 3x faster)
- [GitHub: Theming in v4](https://github.com/tailwindlabs/tailwindcss/discussions/18471) - Tailwind CSS 4 best practices

### Implementation Guides
- [Favicon Generation with Astro - kremalicious](https://kremalicious.com/favicon-generation-with-astro/) - Manual favicon approach
- [Rodney Lab: Astro JS Favicon](https://rodneylab.com/astro-js-favicon/) - Required favicon files
- [Tailwind v4 Colors - TailKits](https://tailkits.com/blog/tailwind-v4-custom-colors/) - Color customization
- [How to optimize images in Astro - Uploadcare](https://uploadcare.com/blog/how-to-optimize-images-in-astro/) - Image optimization

### Package Documentation
- [astro-favicons on GitHub](https://github.com/ACP-CODE/astro-favicons) - Evaluated but not recommended
- [@resvg/resvg-js on npm](https://www.npmjs.com/package/@resvg/resvg-js) - SVG rendering library

## Confidence Assessment

| Area | Confidence | Notes |
|------|-----------|-------|
| **Favicon approach** | HIGH | Verified codebase uses static files. Manual approach proven in production. |
| **Color theming** | HIGH | Tailwind CSS 4 @theme configuration verified in global.css. |
| **Image handling** | HIGH | Sharp + @resvg confirmed in package.json. Sharp is Astro 5 default. |
| **PWA manifest** | HIGH | @vite-pwa/astro config verified in astro.config.mjs. |
| **Deployment** | HIGH | Vercel + Astro is well-documented standard. |
| **astro-favicons** | MEDIUM-LOW | No explicit Astro 5 compatibility statement found. Last updates reference Astro 4.16.x. |

## Open Questions

None. All major personalization requirements can be addressed with existing infrastructure.

## Next Steps for Roadmap

Based on this stack research, suggested roadmap structure:

1. **Phase 1: Asset Replacement** - Favicon generation, avatar optimization, static file updates
2. **Phase 2: Color Personalization** - CSS variable updates, theme color testing
3. **Phase 3: Configuration Updates** - consts.ts, manifest, metadata
4. **Phase 4: Content Updates** - About page, existing blog post updates (if needed)
5. **Phase 5: Deployment** - Vercel setup, domain configuration, final verification

**Rationale:** Asset generation can be done offline, making it independent. Color changes affect all pages, so should be done before content updates. Configuration and content can be updated in parallel. Deployment is final verification.
