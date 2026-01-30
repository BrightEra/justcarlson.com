# Technology Stack

**Analysis Date:** 2026-01-28

## Languages

**Primary:**
- TypeScript 5.9.3 - All source code
- JavaScript (ESM) - Build scripts, configuration
- Markdown/MDX - Blog content and pages

**Secondary:**
- HTML/CSS - Generated from Astro templates
- SQL (implicit) - Content schema via Zod validation

## Runtime

**Environment:**
- Node.js 20 (as per `.github/workflows/lint.yml`)
- Package manager: npm (lockfile: `package-lock.json`)

**Module system:**
- ES Modules (ESM) - "type": "module" in `package.json`

## Frameworks

**Core:**
- Astro 5.16.6 - Static site generation and page rendering
  - `astro.config.mjs` - Main configuration
  - Markdown rendering with remark plugins
  - Content collections via `astro:content` API

**Frontend UI:**
- React 19.2.3 - Interactive components via `@astrojs/react`
- React DOM 19.2.3

**Styling:**
- Tailwind CSS 4.1.18 - Utility-first CSS framework
  - `@tailwindcss/vite` 4.1.18 - Vite integration
  - `@tailwindcss/postcss` 4.1.18 - PostCSS plugin
  - `@tailwindcss/typography` 0.5.19 - Prose styling

**Content & Markdown:**
- MDX 4.3.13 via `@astrojs/mdx` - Markdown + JSX in content
- remark-toc 9.0.0 - Table of contents generation
- remark-collapse 0.1.2 - Collapsible section support
- gray-matter 4.0.3 - Front matter parsing
- reading-time 1.5.0 - Reading time estimates
- github-slugger 2.0.0 - URL slug generation

**Image & Graphics:**
- Sharp 0.34.5 - Image processing
- Satori 0.18.3 - Font rendering for OG images
- @resvg/resvg-js 2.6.2 - SVG to PNG conversion

**Utilities:**
- dayjs 1.11.19 - Date/time manipulation
- fuse.js 7.1.0 - Client-side search
- lodash.kebabcase 4.1.1 - String transformation

## Build & Development Tools

**Build:**
- Vite 6.3.5 (via Astro) - Module bundling
- Pagefind 1.4.0 - Site search indexing
- esbuild 0.25.5 - Fast JavaScript bundler

**Linting & Formatting:**
- Biome 2.3.10 - Unified linter and formatter
  - Configuration: `biome.json`
  - Rules: Recommended with custom overrides

**Type Checking:**
- @astrojs/check 0.9.6 - Astro component type validation
- TypeScript strict mode

**Git Hooks:**
- Husky 9.1.7 - Git hook management
- lint-staged 16.2.7 - Run linters on staged files
- Commitizen 4.3.1 - Interactive commit messages
- cz-conventional-changelog 3.3.0 - Conventional commits

**Post-CSS:**
- PostCSS 8.5.6 - CSS transformation
- autoprefixer 10.4.23 - Vendor prefixes

## Key Dependencies

**Critical:**
- astro 5.16.6 - Framework and static site generator
- react, react-dom 19.2.3 - Interactive UI components
- typescript 5.9.3 - Type safety

**Content & MDX:**
- @astrojs/mdx 4.3.13 - MDX support in Astro
- @astrojs/rss 4.0.14 - RSS feed generation at `/rss.xml`
- @astrojs/sitemap 3.6.0 - Sitemap generation with filtering
- gray-matter 4.0.3 - Parse markdown front matter

**Performance & Analytics:**
- @vercel/analytics 1.6.1 - Web vitals tracking
- @vercel/speed-insights 1.3.1 - Performance monitoring
- @vite-pwa/astro 1.2.0 - Progressive Web App support

**Search & Utilities:**
- pagefind 1.4.0 - Static site search engine
- @pagefind/default-ui 1.4.0 - Search UI component
- fuse.js 7.1.0 - Fuzzy search library

**Image Processing:**
- sharp 0.34.5 - High-performance image operations
- @resvg/resvg-js 2.6.2 - SVG rendering for OG images
- satori 0.18.3 - Font support for dynamic images

## Configuration Files

**Framework:**
- `astro.config.mjs` - Astro configuration with integrations, markdown plugins, PWA settings
- `tsconfig.json` - TypeScript compiler options with strict mode and path aliases
- `biome.json` - Linter and formatter rules (2-space indent, 100 char line width)

**Build & Deployment:**
- `vercel.json` - Vercel deployment configuration with redirects, rewrites, CSP headers
- `.github/workflows/astro-build.yml` - CI: Build and test on push/PR
- `.github/workflows/lint.yml` - CI: Lint check with Biome
- `package.json` - Scripts for dev, build, preview, lint, format, type checking

**Content:**
- `src/content.config.ts` - Astro content collection schema for blog posts
- `.gitignore` - Excludes build output, node_modules, environment files

## Environment Configuration

**Deployment:**
- Target: Vercel (specified in `vercel.json`)
- Framework: Astro (auto-detected by Vercel)
- Build command: `npm run build` (runs `astro build && pagefind --site dist`)
- Output directory: `dist/`

**Environment Variables:**
- No required env vars detected in codebase (analytics are injected client-side only in production)
- Astro telemetry disabled via `ASTRO_TELEMETRY_DISABLED=1` in CI

**Development:**
- Dev command: `npm run dev` (Astro dev server)
- Port: Default Astro dev port (3000)
- No local database or backend service

## Platform Requirements

**Development:**
- Node.js 20.x
- npm 8.x+
- Bash/shell for scripts
- Text editor with TypeScript/Astro support

**Production:**
- Node.js runtime not required (static site)
- Vercel deployment platform
- CDN and static file hosting (via Vercel)
- No database or backend servers needed

---

*Stack analysis: 2026-01-28*
