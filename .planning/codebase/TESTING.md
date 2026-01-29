# Testing Patterns

**Analysis Date:** 2026-01-28

## Test Framework

**Runner:**
- Not detected - no testing framework configured
- No test files found in codebase

**Assertion Library:**
- Not detected

**Run Commands:**
- No test commands defined in `package.json`

## Test File Organization

**Location:**
- Not applicable - no tests present

**Naming:**
- Not applicable - no tests present

**Structure:**
- Not applicable - no tests present

## Test Structure

**Suite Organization:**
- Not applicable - no tests present

## Mocking

**Framework:**
- Not detected

**Patterns:**
- Not applicable - no mocking patterns present

**What to Mock:**
- Not applicable

**What NOT to Mock:**
- Not applicable

## Fixtures and Factories

**Test Data:**
- Not applicable

**Location:**
- Not applicable

## Coverage

**Requirements:**
- Not enforced - no coverage configuration found

**View Coverage:**
- Not applicable

## Test Types

**Unit Tests:**
- Not implemented

**Integration Tests:**
- Not implemented

**E2E Tests:**
- Not implemented
- Note: Astro build process (`build:check` command) includes type checking via `astro check`

## Type Checking

**Build-time Validation:**
- TypeScript strict mode enabled: `astro/tsconfigs/strict`
- `strictNullChecks: true` in `tsconfig.json`
- Astro content validation via Zod schema in `content.config.ts`:
  ```typescript
  const blog = defineCollection({
    loader: glob({ pattern: "**/[^_]*.{md,mdx}", base: `./${BLOG_PATH}` }),
    schema: ({ image }) =>
      z.object({
        author: z.string().default(SITE.author),
        pubDatetime: z.coerce.date(),
        modDatetime: z.date().optional().nullable(),
        title: z.string(),
        featured: z.boolean().optional(),
        draft: z.boolean().optional(),
        unlisted: z.boolean().optional(),
        tags: z.array(z.string()).default(["others"]),
        ogImage: image().or(z.string()).optional(),
        heroImage: z.string().optional(),
        description: z.string(),
        canonicalURL: z.string().optional(),
        hideEditPost: z.boolean().optional(),
        timezone: z.string().optional(),
        source: z.string().optional(),
        AIDescription: z.boolean().optional(),
      }),
  });
  ```

**Linting as Validation:**
- Biome performs correctness checks during CI/CD
- Pre-commit hook runs `biome check --write` before commits
- GitHub Actions workflow: `lint.yml` runs on all PRs and pushes to main
- Build check command: `npm run build:check` includes `astro check` for type validation

## Static Validation

**Command: `npm run check`**
- Runs: `biome check src`
- Checks: linting, formatting, and correctness without fixing

**Command: `npm run check:fix`**
- Runs: `biome check --write src`
- Auto-fixes linting and formatting issues

**Command: `npm run build:check`**
- Runs: `astro check && astro build && pagefind --site dist`
- Validates types, builds project, generates search index

## Common Patterns (Substitute for Tests)

**Runtime Guard Conditions:**
- Null checks before operations:
  ```typescript
  const post = posts.find((p) => p.id === postId);
  if (!post || !post.body) {
    return "5 min read"; // fallback
  }
  ```

**Type Safety Through Interfaces:**
- Content collection validation via Zod enforces data shape at build time
- Blog posts must match schema or build fails
- Rich types prevent null pointer errors:
  ```typescript
  interface SocialLink {
    href: string;
    label: string;
  }
  ```

**Error Messages as Documentation:**
- Descriptive errors guide developers:
  ```typescript
  if (!resource) throw new Error("Failed to download dynamic font");
  ```

**Middleware Validation:**
- URL pattern matching in middleware validates request routing:
  ```typescript
  if (url.pathname.startsWith("/blog/")) {
    return context.redirect("/posts/" + url.pathname.slice(6), 301);
  }
  ```

---

## Recommendation Summary

**Current State:** No automated tests present. Project relies on:
1. TypeScript strict mode (`strictNullChecks: true`)
2. Zod validation for content collections at build time
3. Biome linting/formatting enforcement via pre-commit hooks and CI
4. Astro type checking during build (`astro check`)

**Testing Gaps:**
- No unit tests for utility functions
- No integration tests for content processing
- No E2E tests for site functionality
- No regression testing

**High-Value Test Targets (if testing is implemented):**
- `src/utils/getPath.ts` - path construction logic (critical for routing)
- `src/utils/getSortedPosts.ts` - sorting/filtering logic
- `src/utils/postFilter.ts` - draft/scheduled post filtering
- `src/utils/generateOgImages.ts` - async image generation
- Middleware path redirects

---

*Testing analysis: 2026-01-28*
