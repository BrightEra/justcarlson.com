# Coding Conventions

**Analysis Date:** 2026-01-28

## Naming Patterns

**Files:**
- Kebab-case for component and utility files: `mobile-menu.tsx`, `get-path.ts`, `critical-css.ts`
- PascalCase for React components when exported: `Separator` in `separator.tsx`
- Descriptive names with action verbs for utilities: `getSortedPosts.ts`, `getPostsByTag.ts`, `generateOgImages.ts`
- Config files use simple names: `config.ts`, `consts.ts`, `constants.ts`, `content.config.ts`

**Functions:**
- camelCase for all functions and exported functions
- Action-verb prefix pattern for utilities: `getPath()`, `getSortedPosts()`, `getPostsByTag()`, `slugifyStr()`, `calculateReadingTime()`
- Async functions use `async` keyword: `generateOgImageForPost()`, `getReadingTime()`
- Private/internal functions use lowercase: `svgBufferToPngBuffer()`, `loadGoogleFont()`

**Variables:**
- camelCase for all variables: `isOpen`, `isPublishTimePassed`, `postPerIndex`
- UPPERCASE_SNAKE_CASE for constants: `SITE`, `NAV_LINKS`, `SOCIAL_LINKS`, `BLOG_PATH`, `ICON_MAP`
- Single letter variables avoided (except loop counters and destructuring)

**Types:**
- PascalCase for interfaces: `SocialLink`, `Site`, `CollapseOptions`
- Descriptive interface names: `interface SocialLink { href: string; label: string; }`
- Use `type` for aliases and `interface` for object shapes
- Generic types from libraries imported as-is: `CollectionEntry<"blog">`

## Code Style

**Formatting:**
- Tool: Biome v2.3.10
- Line width: 100 characters
- Indent style: space, 2 spaces per level
- Quote style: double quotes
- Trailing commas: ES5 (valid for objects/arrays, not function params)
- Semicolons: always

**Linting:**
- Tool: Biome (recommended rules enabled)
- Rules disabled:
  - `style/noNonNullAssertion`: off (non-null assertions allowed)
  - `style/useNodejsImportProtocol`: off
  - `style/useTemplate`: off
  - `suspicious/noExplicitAny`: off (any types allowed)
  - `complexity/noForEach`: off (forEach allowed)
  - `correctness/noUnusedVariables`: off
  - `correctness/noUnusedImports`: off
  - `a11y/noSvgWithoutTitle`: off
  - `a11y/useAriaPropsSupportedByRole`: off

**ESLint:**
- Base configs: `eslint:recommended`, `plugin:@typescript-eslint/recommended`, `plugin:astro/recommended`
- Parser: `@typescript-eslint/parser`
- Custom rules:
  - `no-unused-vars`: warn
  - `@typescript-eslint/no-unused-vars`: warn
  - `prefer-const`: warn
  - `no-trailing-spaces`: warn
  - `no-multiple-empty-lines`: warn (max: 2, maxEOF: 1)

**Pre-commit:**
- Git hook via Husky runs: `npx lint-staged`
- Lint-staged runs: `biome check --write --files-ignore-unknown=true` on `*.{js,ts,tsx,json}` files

## Import Organization

**Order:**
1. External dependencies: `import { useState } from "react"`, `import { getCollection } from "astro:content"`
2. Type imports: `import type { CollectionEntry } from "astro:content"`
3. Local imports: `import { SITE } from "@/config"`
4. Relative imports: `import postFilter from "./postFilter"`

**Path Aliases:**
- `@/*` → `src/*` (configured in `tsconfig.json`)
- Used consistently in imports: `import { SITE } from "@/config"`, `import { slugifyStr } from "@/utils/slugify"`

## Error Handling

**Patterns:**
- Throw descriptive errors with context: `throw new Error("Failed to download dynamic font")`
- Include error context/status when available: `throw new Error("Failed to download dynamic font. Status: " + res.status)`
- Fallback values for non-critical operations: `return "5 min read"` when post not found
- Null-coalescing in calculations: `new Date(b.data.modDatetime ?? b.data.pubDatetime)`

**No try-catch blocks observed** - errors propagate to caller or handled via nullish coalescing

## Logging

**Framework:** console (no external logging framework)

**Patterns:**
- No explicit logging found in codebase
- Middleware uses Astro's built-in request context
- Error messages thrown as descriptive strings

## Comments

**When to Comment:**
- JSDoc comments for exported functions with parameters and return values
- Inline comments for complex logic or non-obvious decisions
- Explanation of why, not what (code shows what, comment explains why)

**JSDoc/TSDoc:**
- Used for utility functions with parameters:
  ```typescript
  /**
   * Get full path of a blog post
   * @param id - id of the blog post (aka slug)
   * @param filePath - the blog post full file location
   * @param includeBase - whether to include `/posts` in return value
   * @returns blog post path
   */
  export function getPath(id: string, filePath: string | undefined, includeBase = true)
  ```
- Not universally used; used selectively for complex public APIs

**Inline Comments:**
- Explain intent: `// remove empty string in the segments ["", "other-path"] <- empty string will be removed`
- Exclude patterns: `// exclude directories start with underscore "_"`
- Document assumptions: `// Making sure `id` does not contain the directory`

## Function Design

**Size:**
- Small utility functions preferred: `slugify.ts` is 6 lines, `postFilter.ts` is 11 lines
- Composed from smaller functions: `getSortedPosts()` uses `postFilter()` then sort
- Larger functions document sections with comments: `getPageCriticalCSS()` has 50+ lines with clear if branches

**Parameters:**
- Destructuring used for object params: `({ data }: CollectionEntry<"blog">)`
- Optional parameters use defaults: `includeBase = true`
- Type annotations required for all params
- Spread syntax avoided for configuration (explicit params preferred)

**Return Values:**
- Explicit return types for all exported functions
- Early returns for guard conditions: `if (!resource) throw new Error(...)`
- Array/string joins for path construction: `[basePath, ...pathSegments, slug].join("/")`

## Module Design

**Exports:**
- Single default export for utilities: `export default getSortedPosts`
- Named exports for re-exports: `export * from "./constants"` in `config.ts`
- Named exports for components: `export { Separator }` in `separator.tsx`
- Mixed exports allowed: both `export default` and named exports in same file

**Barrel Files:**
- Used in `config.ts` for compatibility: re-exports from `constants.ts` and `consts.ts`
- Not used for component directories (direct imports preferred)

## TypeScript Configuration

**Strict Mode:**
- Extends: `astro/tsconfigs/strict`
- `strictNullChecks`: true
- Path alias configured: `"@/*": ["src/*"]`

## Formatting Rules in Practice

**Example from `mobile-menu.tsx`:**
- Ternary operators broken across lines for readability
- Object spread used for HTML attributes: `{...props}`
- Template literals for conditional class names
- 2-space indentation throughout

**Example from `loadGoogleFont.ts`:**
- Long strings broken after operators
- Array methods chained: `fontsConfig.map(async ...)` using Promise.all
- Async/await used for clarity over .then() chains

---

*Convention analysis: 2026-01-28*
