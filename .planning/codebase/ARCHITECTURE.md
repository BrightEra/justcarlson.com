# Architecture

**Analysis Date:** 2026-01-28

## Pattern Overview

**Overall:** Static Site Generation (SSG) with Astro framework

**Key Characteristics:**
- Content-driven blog platform generating static HTML at build time
- File-based routing using Astro pages convention
- Markdown/MDX content collection system for blog posts
- Component-based UI with Astro components and React islands
- Server-side rendering at build time, client-side interactivity via JavaScript

## Layers

**Content Layer:**
- Purpose: Manage and validate blog post metadata and content
- Location: `src/content/blog/` (markdown/MDX files), `src/content.config.ts` (schema definition)
- Contains: Blog post files organized by year directories (e.g., `2025/`, `2024/`, `2012/`)
- Depends on: Astro content loader
- Used by: Page generators and utilities that query posts

**Configuration Layer:**
- Purpose: Define site-wide settings, constants, and metadata
- Location: `src/consts.ts`, `src/constants.ts`, `src/config.ts`
- Contains: Site metadata (SITE object), navigation links, social links, icon mappings
- Depends on: None
- Used by: All pages, layouts, and components that need site configuration

**Utility Layer:**
- Purpose: Provide pure functions for data transformation and processing
- Location: `src/utils/`
- Contains: Post sorting (`getSortedPosts.ts`), filtering (`postFilter.ts`), slug generation (`slugify.ts`), path resolution (`getPath.ts`), reading time calculation (`readingTime.ts`), tag extraction (`getUniqueTags.ts`), OG image generation (`generateOgImages.ts`)
- Depends on: Content collection entries, configuration
- Used by: Pages, layouts, components

**Component Layer:**
- Purpose: Reusable UI elements for rendering pages
- Location: `src/components/`
- Contains: Astro components (`.astro` files) for page structure (Header, Footer, Breadcrumb), content display (Card, Pagination), metadata (StructuredData, BaseHead), interactive components (ThemeToggle, NewsletterForm)
- Sub-layer: `src/components/ui/` contains React components (`mobile-menu.tsx`, `separator.tsx`)
- Depends on: Configuration, utilities, Astro APIs
- Used by: Layouts and pages

**Layout Layer:**
- Purpose: Template structure for different page types
- Location: `src/layouts/`
- Contains: Page templates (Layout.astro - root template, BaseLayout, Main, BlogPost layouts)
- Depends on: Components, configuration, utilities
- Used by: Pages (specified via layout assignment)

**Page/Route Layer:**
- Purpose: Define routes and render final pages
- Location: `src/pages/`
- Contains: Dynamic and static routes (index.astro, posts/[...slug].astro for individual posts, posts/[...page].astro for pagination, about.md.ts, archives.md.ts)
- Depends on: Layouts, components, content collection, utilities
- Used by: Astro router

**Styling Layer:**
- Purpose: Visual presentation and theming
- Location: `src/styles/` (custom.css, global.css, tailwind.css, typography.css)
- Contains: Global CSS, Tailwind configuration, typography styles
- Depends on: Tailwind CSS framework
- Used by: All components and layouts

**Middleware Layer:**
- Purpose: Request-level URL redirection and routing logic
- Location: `src/middleware.js`
- Contains: Legacy `/blog/` to `/posts/` redirect logic
- Depends on: None
- Used by: Astro request pipeline

## Data Flow

**Content Loading & Filtering:**

1. Blog post files in `src/content/blog/` are loaded via `content.config.ts` using Astro's content loader
2. Schema validation occurs (via Zod schema in `content.config.ts`) on `pubDatetime`, `title`, `tags`, `draft`, `featured`, etc.
3. Posts are filtered by draft status and other criteria via `postFilter.ts` (respects publication date and scheduledPostMargin)
4. Posts are sorted by modification/publication date (newest first) via `getSortedPosts.ts`

**Blog Post Rendering:**

1. Page route `src/pages/posts/[...slug].astro` calls `getStaticPaths()` to generate static routes
2. Post slug is derived from `post.id` (file path relative to content directory)
3. Year is extracted from `pubDatetime` and prepended to slug (e.g., `2025/post-title`)
4. `render(post)` converts markdown/MDX to HTML via Astro
5. Post is wrapped in `BlogPostLayout.astro` with metadata (author, date, reading time)
6. Layout extends base `Layout.astro` which includes structured data, meta tags, and analytics

**Homepage Rendering:**

1. `src/pages/index.astro` fetches all posts via `getCollection("blog")`
2. Posts are filtered: 2025+ only, separated into `featured` and `recent` arrays
3. Featured posts are rendered first, then recent posts (limited by `SITE.postPerIndex`)
4. Layout: hero section → featured section → recent posts section → "All Posts" link
5. Client-side script stores back navigation URL in sessionStorage

**Pagination:**

1. `src/pages/posts/[...page].astro` paginate helper creates routes for all post pages
2. Posts per page defined by `SITE.postPerPage`
3. `Pagination.astro` component renders prev/next links based on `page` object

**OG Image Generation:**

1. During build, if `SITE.dynamicOgImage` is true, OG images are generated
2. `generateOgImages.ts` creates SVG via template (`og-templates/post.ts` or `og-templates/site.ts`)
3. SVG is converted to PNG buffer via `Resvg` (resvg-js)
4. Images served as static assets at build time

**State Management:**

- Client-side navigation state: `sessionStorage.backUrl` (set in index.astro, used by BackButton component)
- Theme state: Toggle theme via `ThemeToggle.astro` component (reads/writes `data-theme` attribute via `toggle-theme.js` script)
- View transitions: Astro's ViewTransitions API enables smooth page transitions (scoped to same-origin)

## Key Abstractions

**CollectionEntry<"blog">:**
- Purpose: Type-safe representation of a blog post from the content collection
- Examples: Used in `getSortedPosts.ts`, `Card.astro`, `src/pages/posts/[...slug].astro`
- Pattern: Astro content collection entries with `data` (frontmatter) and `body` (markdown content)

**Post Data Schema:**
- Purpose: Validate and structure blog post metadata
- Examples: Defined in `src/content.config.ts` using Zod
- Pattern: `pubDatetime` (required), `modDatetime` (optional), `title`, `description`, `tags`, `featured`, `draft`, `heroImage`, `ogImage`

**Slug Resolution:**
- Purpose: Convert file paths to web URLs
- Examples: `getPath()` in `src/utils/getPath.ts`, `slugifyStr()` in `src/utils/slugify.ts`
- Pattern: Extract year from `pubDatetime`, combine with slug from post ID, handle subdirectories

**Post Filtering Pipeline:**
- Purpose: Apply multiple conditions to determine post visibility
- Examples: `postFilter.ts` applies draft check, date margin check
- Pattern: Composed filter functions applied via `.filter()`

## Entry Points

**Static Site Generation:**
- Location: `src/pages/index.astro`, `src/pages/posts/[...slug].astro`, `src/pages/posts/[...page].astro`
- Triggers: Astro build command (`npm run build`)
- Responsibilities: Generate static HTML for all routes via `getStaticPaths()` and content queries

**Development Server:**
- Location: Entry point is Astro's built-in dev server
- Triggers: `npm run dev`
- Responsibilities: Serve pages with hot module replacement, watch for file changes

**Request Middleware:**
- Location: `src/middleware.js`
- Triggers: All incoming HTTP requests
- Responsibilities: Redirect legacy `/blog/` URLs to `/posts/`

**Content Sync:**
- Location: Astro content generation (implicit)
- Triggers: `npm run sync` (manual) or build process (automatic)
- Responsibilities: Generate TypeScript types for content collection

## Error Handling

**Strategy:** Graceful degradation with console warnings

**Patterns:**
- Missing post IDs logged via `console.warn()` in `src/pages/posts/[...slug].astro` getStaticPaths
- Null/undefined values filtered out via `.filter(Boolean)` after mapping
- Fallback values used when data is missing (e.g., current year if post year cannot be extracted)
- Filtered routes to exclude draft posts via `getCollection("blog", ({ data }) => !data.draft)`

## Cross-Cutting Concerns

**Logging:** Console-based for build-time warnings; no production logging framework

**Validation:** Zod schema validation in `src/content.config.ts` for all blog posts at build time

**Authentication:** Not applicable (static site)

**SEO & Metadata:**
- Structured data via JSON-LD in `Layout.astro` (BlogPosting schema)
- Meta tags for OG, Twitter card in `Layout.astro`
- Dynamic OG images via SVG-to-PNG conversion if enabled
- RSS feed auto-discovery via link element in `Layout.astro`

**Caching (PWA):**
- Service Worker configured via `@vite-pwa/astro` integration
- Runtime cache strategies: CacheFirst for Google Fonts (1 year expiry), images (30 days expiry)
- Offline fallback: 404 page
- Manifest: Standalone PWA with app icons

**Performance:**
- Image optimization: Astro Image component with format conversion to WebP, lazy loading, density-aware serving
- CSS: Tailwind CSS for utility-first styling, minimized at build
- Code splitting: Astro automatically code-splits routes, React islands only load when needed

---

*Architecture analysis: 2026-01-28*
