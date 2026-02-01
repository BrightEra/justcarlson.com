# Codebase Structure

**Analysis Date:** 2026-01-28

## Directory Layout

```
justcarlson.com/
├── src/                           # Source code for the site
│   ├── assets/                    # Static assets (images, icons)
│   │   ├── icons/                 # SVG icon components
│   │   └── images/                # Image files
│   ├── components/                # Reusable Astro & React components
│   │   ├── ui/                    # React interactive components
│   │   ├── Analytics.astro        # Analytics integration
│   │   ├── BaseHead.astro         # Meta tags and head setup
│   │   ├── Card.astro             # Blog post preview card
│   │   ├── Header.astro           # Navigation header
│   │   ├── Footer.astro           # Page footer
│   │   ├── Pagination.astro       # Post list pagination
│   │   ├── StructuredData.astro   # JSON-LD schema markup
│   │   ├── ThemeToggle.astro      # Dark/light theme switcher
│   │   └── [other components]     # Specialized components
│   ├── content/                   # Content collections
│   │   └── blog/                  # Blog post markdown files
│   │       ├── 2025/              # Posts from 2025
│   │       ├── 2024/              # Posts from 2024
│   │       ├── 2023/              # Posts from 2023
│   │       └── [years]/           # Posts organized by year
│   ├── layouts/                   # Page templates
│   │   ├── Layout.astro           # Root HTML template
│   │   ├── BaseLayout.astro       # Base page wrapper
│   │   ├── Main.astro             # Main content area wrapper
│   │   └── BlogPostLayout.astro   # Blog post specific template
│   ├── pages/                     # Routes (file-based routing)
│   │   ├── index.astro            # Homepage
│   │   ├── 404.astro              # Not found page
│   │   ├── about.md.ts            # About page
│   │   ├── archives.md.ts         # Archives page
│   │   ├── posts.md.ts            # Posts index page
│   │   ├── posts/
│   │   │   ├── index.astro        # Posts listing page (/posts)
│   │   │   └── [...slug]/
│   │   │       └── index.astro    # Individual post routes (/posts/YYYY/slug)
│   │   ├── page/
│   │   │   └── [page].astro       # Home page pagination
│   │   ├── tags/
│   │   │   └── [tag].astro        # Tag-based post filtering (if exists)
│   │   └── archives/
│   │       └── index.astro        # Archives view
│   ├── styles/                    # Global styles
│   │   ├── global.css             # Base styles, resets
│   │   ├── custom.css             # Custom utilities and overrides
│   │   ├── tailwind.css           # Tailwind CSS imports
│   │   └── typography.css         # Typography system
│   ├── utils/                     # Utility functions
│   │   ├── getSortedPosts.ts      # Sort posts by date
│   │   ├── postFilter.ts          # Filter published posts
│   │   ├── getPath.ts             # Resolve post URLs
│   │   ├── slugify.ts             # Convert text to URL slugs
│   │   ├── getUniqueTags.ts       # Extract unique tags from posts
│   │   ├── getPostsByTag.ts       # Filter posts by tag
│   │   ├── readingTime.ts         # Calculate article read duration
│   │   ├── generateOgImages.ts    # Create OG images
│   │   ├── og-templates/          # OG image SVG templates
│   │   │   ├── post.ts            # Post OG image template
│   │   │   └── site.ts            # Site OG image template
│   │   ├── criticalCSS.ts         # Critical path CSS extraction
│   │   ├── loadGoogleFont.ts      # Font loading utilities
│   │   ├── getPostsByGroupCondition.ts # Group posts by condition
│   │   └── remarkLazyLoadImages.mjs    # Remark plugin for lazy images
│   ├── consts.ts                  # Site configuration & constants
│   ├── constants.ts               # Additional constants
│   ├── config.ts                  # Config re-exports
│   ├── content.config.ts          # Content collection schema
│   ├── middleware.js              # URL redirect middleware
│   ├── types.d.ts                 # TypeScript type definitions
│   └── env.d.ts                   # Astro environment types
├── public/                        # Static files served as-is
│   ├── assets/
│   │   ├── img/                   # Images served at build time
│   │   └── [other static assets]
│   ├── fonts/                     # Web font files
│   ├── favicon.ico                # Site favicon
│   ├── peter-avatar.jpg           # Profile image
│   ├── toggle-theme.js            # Theme toggle script
│   └── [other public files]
├── .github/
│   └── workflows/                 # GitHub Actions CI/CD
├── .husky/                        # Git hooks (pre-commit, etc.)
├── .vscode/                       # VS Code workspace settings
├── .planning/                     # Planning documents (generated)
│   └── codebase/                  # Analysis documents
│       ├── ARCHITECTURE.md
│       └── STRUCTURE.md
├── scripts/                       # Build and utility scripts
│   ├── deploy.sh                  # Deployment script
│   ├── add-source-metadata.mjs    # Add source field to posts
│   └── remove-tags-from-posts.mjs # Remove tags from posts
├── astro.config.mjs               # Astro configuration
├── tsconfig.json                  # TypeScript configuration
├── biome.json                     # Code formatting/linting config
├── .eslintrc.cjs                  # ESLint configuration
├── package.json                   # Dependencies & scripts
├── package-lock.json              # Locked dependency versions
├── vercel.json                    # Vercel deployment config
├── tailwind.config.js             # Tailwind CSS config (if exists)
├── README.md                      # Project documentation
├── LICENSE                        # License file
├── CHANGELOG.md                   # Release history
├── AGENTS.md                      # Agent instructions for Claude
└── CLAUDE.md                      # Claude memory/preferences
```

## Directory Purposes

**src/:**
- Purpose: Source code for the entire site
- Contains: Components, pages, layouts, utilities, content, styles
- Key files: `astro.config.mjs`, `content.config.ts`, `consts.ts`

**src/components/:**
- Purpose: Reusable UI building blocks
- Contains: Astro components (.astro) for structural elements (Header, Footer, Layout pieces), content display (Card, Pagination), interactive components
- Contains: React components (ui/ subdirectory) for client-side interactivity
- Key files: `Card.astro`, `Header.astro`, `BaseHead.astro`

**src/content/blog/:**
- Purpose: Blog post markdown/MDX files
- Contains: Organized by year directories (2025/, 2024/, 2012/, etc.)
- Each file: Markdown with YAML frontmatter (title, pubDatetime, description, tags, etc.)
- Key files: Any `.md` or `.mdx` files (not starting with underscore)

**src/layouts/:**
- Purpose: Page template structure for different page types
- Contains: Astro components defining overall page HTML structure
- Key files: `Layout.astro` (root HTML template), `BlogPostLayout.astro` (blog post wrapper)

**src/pages/:**
- Purpose: Define all routes via file-based routing
- Contains: `.astro`, `.md.ts`, and `.ts` files (each becomes a route)
- Dynamic routes: `[...slug].astro`, `[...page].astro` use getStaticPaths() for static generation
- Key files: `index.astro` (home), `posts/[...slug].astro` (individual posts), `404.astro` (not found)

**src/utils/:**
- Purpose: Pure utility functions for data transformation
- Contains: Post processing (sorting, filtering), slug generation, metadata extraction
- Key files: `getSortedPosts.ts`, `getPath.ts`, `postFilter.ts`

**src/styles/:**
- Purpose: Global and component-scoped styles
- Contains: CSS files imported into layouts and components
- Build tool: Tailwind CSS (imported via `tailwind.css`)
- Key files: `global.css` (resets, base), `custom.css` (utilities, overrides)

**public/:**
- Purpose: Static files served as-is by the web server
- Contains: Images, fonts, favicon, theme toggle script
- No processing: Files copied to root of dist/ at build time
- Key files: `toggle-theme.js`, `favicon.ico`, `peter-avatar.jpg`

**scripts/:**
- Purpose: Build-time and maintenance scripts
- Contains: Node.js scripts for automation
- Key files: `deploy.sh` (deployment), `add-source-metadata.mjs` (post metadata)

**.vscode/:**
- Purpose: VS Code editor settings and extensions for this project
- Contains: Workspace configuration for formatting, linting, debugging

**.husky/:**
- Purpose: Git hooks for pre-commit checks
- Contains: Hook scripts that run before commit (linting, formatting)

## Key File Locations

**Entry Points:**

- `src/pages/index.astro`: Homepage (blog listing with featured posts)
- `src/pages/posts/index.astro`: Posts listing page (/posts)
- `src/pages/posts/[...slug]/index.astro`: Individual blog post route (/posts/YYYY/slug)
- `src/middleware.js`: Request-level redirects (legacy /blog/ → /posts/)
- `astro.config.mjs`: Astro build configuration

**Configuration:**

- `src/consts.ts`: Site metadata (SITE object), navigation links, social links
- `src/content.config.ts`: Blog collection schema definition (Zod)
- `tsconfig.json`: TypeScript compiler options, path aliases
- `astro.config.mjs`: Astro integrations, markdown plugins, Vite config
- `biome.json`: Code formatting and linting rules
- `package.json`: Dependencies, npm scripts

**Core Logic:**

- `src/utils/getSortedPosts.ts`: Sort posts by modification/publication date
- `src/utils/postFilter.ts`: Filter draft and future-dated posts
- `src/utils/getPath.ts`: Resolve blog post URLs from file paths
- `src/components/Card.astro`: Render post preview card with image, date, reading time
- `src/layouts/BlogPostLayout.astro`: Blog post page structure

**Styling:**

- `src/styles/global.css`: Reset styles, base typography, layout utilities
- `src/styles/custom.css`: Custom utilities, component styles, theme overrides
- `src/styles/tailwind.css`: Tailwind CSS import
- `src/styles/typography.css`: Typography scale and utilities

**Testing:**

- No test files found in this codebase (static site generation, minimal client-side logic)

## Naming Conventions

**Files:**

- Astro components: PascalCase (e.g., `Card.astro`, `Header.astro`)
- TypeScript/JavaScript files: camelCase (e.g., `getSortedPosts.ts`, `postFilter.ts`)
- CSS files: kebab-case or .css (e.g., `global.css`, `custom.css`)
- Utility files: descriptive verbs (get, calculate, filter) + noun (e.g., `getUniqueTags.ts`, `calculateReadingTime.ts`)
- Config files: camelCase for .ts/.mjs, .json for config (e.g., `astro.config.mjs`, `biome.json`)

**Directories:**

- Plural nouns for collections: `components/`, `pages/`, `layouts/`, `utils/`, `styles/`, `assets/`
- Year directories in blog: Numeric format (e.g., `2025/`, `2024/`)
- Group directories (optional): describe grouping (e.g., `og-templates/`, `ui/`)

**Routing (Pages):**

- Index routes: `index.astro` (becomes `/`)
- Dynamic segments: `[param].astro` (single segment), `[...slug].astro` (catch-all)
- Posts index: `posts/index.astro` (becomes `/posts`)
- Post routes: `posts/[...slug]/index.astro` (becomes `/posts/2025/post-title`)
- Trailing slashes: Config uses `trailingSlash: "ignore"` - both `/posts` and `/posts/` work

**Variables & Functions:**

- Functions: camelCase, verb-first (e.g., `getSortedPosts`, `filterDraftPosts`)
- Constants: UPPER_SNAKE_CASE (e.g., `SITE`, `SOCIAL_LINKS`, `ICON_MAP`)
- Types/Interfaces: PascalCase (e.g., `CollectionEntry<"blog">`, `Site`)

## Where to Add New Code

**New Blog Post:**
- Location: `src/content/blog/YYYY/post-title.md`
- Format: Markdown with YAML frontmatter (pubDatetime required)
- Will automatically appear in sorted lists via `getCollection("blog")`

**New Feature/Component:**
- Implementation: `src/components/NewComponent.astro` (for Astro components) or `src/components/ui/new-component.tsx` (for React)
- Usage: Import in layouts or pages, pass data as props
- Pattern: Follow existing component structure (interface Props, destructure Astro.props or React props)

**New Utility Function:**
- Location: `src/utils/newUtility.ts`
- Pattern: Export as default or named export; use TypeScript types; handle null/undefined gracefully
- Usage: Import in pages, components, or other utilities

**New Page/Route:**
- Static page: `src/pages/new-page.astro` (becomes `/new-page`)
- Dynamic route: `src/pages/section/[slug].astro` (becomes `/section/value`)
- Data-driven page: Use `getStaticPaths()` to generate routes from data
- Layout: Extend one of the existing layouts (`Layout.astro`, `BaseLayout.astro`)

**New Style/Theme:**
- Global styles: Add to `src/styles/global.css` or `src/styles/custom.css`
- Component styles: Use `<style>` block in `.astro` files or Tailwind classes
- Theme colors: Modify Tailwind config in `astro.config.mjs` or use CSS custom properties

**Adding a New Integration:**
- Register integration in `astro.config.mjs` (in the `integrations` array)
- Example: Current integrations include MDX, Sitemap, React, PWA, Analytics
- Dependencies: Add to `package.json` via `npm install`

**Content Configuration Changes:**
- Schema changes: Update Zod schema in `src/content.config.ts`
- Site config: Update `SITE` object in `src/consts.ts`
- Navigation: Update `NAV_LINKS` or `SOCIAL_LINKS` in `src/consts.ts`

## Special Directories

**src/content/blog/:**
- Purpose: Content collection for blog posts
- Generated: No (manually created markdown files)
- Committed: Yes (all .md/.mdx files committed)
- Loading: Via Astro content loader (glob pattern `**/[^_]*.{md,mdx}`)
- Exclusion: Files/dirs starting with `_` are excluded from output

**dist/:**
- Purpose: Build output (generated static site)
- Generated: Yes (created by `astro build`)
- Committed: No (.gitignore excludes)
- Cleanup: Removed during build, regenerated fresh

**.astro/:**
- Purpose: Astro cache and generated types
- Generated: Yes (created by Astro during dev and build)
- Committed: No (.gitignore excludes)
- Auto-managed: Created and cleaned by Astro

**.vscode/:**
- Purpose: Editor configuration for consistency across team
- Generated: No (manually maintained)
- Committed: Yes (checked into repo)
- Use: Copy to local .vscode for workspace settings

**public/:**
- Purpose: Assets served at root of site without processing
- Generated: No (static files)
- Committed: Yes (images, fonts, scripts)
- Behavior: Copied as-is to dist root during build (no minification/optimization)

---

*Structure analysis: 2026-01-28*
*Updated: 2026-02-01 (routing structure after quick fix 004)*
