# Architecture Research: Identity/Branding Elements

**Domain:** Astro blog codebase rebranding
**Research Mode:** Architecture dimension - Identity mapping
**Researched:** 2026-01-28
**Overall confidence:** HIGH

## Executive Summary

This research maps all identity and branding elements in the Astro blog codebase to enable safe rebranding from "steipete.me" (Peter Steinberger) to "justcarlson.com" (Just Carlson). The codebase has a clear separation of configuration, content, and components, with identity elements concentrated in specific files rather than scattered throughout.

**Key Finding:** Identity elements exist in 4 primary layers:
1. **Configuration Layer** - Centralized site metadata and social links
2. **Asset Layer** - Avatar images, favicons, and static files
3. **Component Layer** - Hardcoded references in components and structured data
4. **Infrastructure Layer** - Domain-specific configurations in deployment settings

All changes follow a clear dependency graph with configuration as the foundation.

## Identity Element Mapping

### Configuration Files (Foundation Layer)

#### 1. `/src/consts.ts` - Primary Configuration
**Purpose:** Single source of truth for site-wide identity metadata

**Identity Elements:**
```typescript
export const SITE: Site = {
  website: "https://steipete.me/",           // → https://justcarlson.com/
  author: "Peter Steinberger",                // → "Just Carlson"
  profile: "https://steipete.me/about",       // → https://justcarlson.com/about
  desc: "AI-powered tools...",                // → Update tagline
  title: "Peter Steinberger",                 // → "Just Carlson"
  ogImage: "peter-avatar.jpg",                // → "avatar.jpg" or similar
  // ... other config (no changes needed)
  editPost: {
    url: "https://github.com/steipete/steipete.me/edit/main/", // → Update repo path
  },
}

export const SOCIAL_LINKS: SocialLink[] = [
  { href: "https://github.com/steipete", ... },      // → Update username
  { href: "https://twitter.com/steipete", ... },     // → Update username
  { href: "https://bsky.app/profile/steipete.me", ...}, // → Update handle
]
```

**Dependencies:** None (foundation)
**Used by:** All layouts, components, pages, RSS feed, OG image generation

---

#### 2. `/src/constants.ts` - Social Links Configuration
**Purpose:** Extended social media configuration with display metadata

**Identity Elements:**
```typescript
export const SOCIALS = [
  {
    name: "Github",
    href: "https://github.com/steipete",              // → Update username
    linkTitle: ` ${SITE.title} on Github`,            // Uses SITE.title (auto-updates)
  },
  {
    href: "https://x.com/steipete",                   // → Update username
    linkTitle: `${SITE.title} on X`,                  // Uses SITE.title (auto-updates)
  },
  {
    href: "https://bsky.app/profile/steipete.me",    // → Update handle
    // ...
  },
  {
    href: "mailto:peter@steipete.me",                 // → Update email
    // ...
  },
]
```

**Dependencies:** Imports `SITE` from `./consts` (inherits title)
**Used by:** `Socials.astro`, social sharing components

---

### Component Files (Presentation Layer)

#### 3. `/src/components/StructuredData.astro` - Hardcoded Schema.org Data
**Purpose:** Structured data for SEO (JSON-LD)

**Identity Elements:**
```javascript
structuredData = {
  author: {
    name: "Peter Steinberger",                    // → "Just Carlson"
    url: "https://steipete.me/about",             // → Update domain
  },
  publisher: {
    name: "Peter Steinberger",                    // → "Just Carlson"
    logo: {
      url: "https://steipete.me/peter-avatar.jpg", // → Update domain + filename
    },
  },
  image: "https://steipete.me/peter-avatar.jpg",  // → Update domain + filename
  // Person schema
  name: "Peter Steinberger",                      // → "Just Carlson"
  url: "https://steipete.me",                     // → Update domain
  image: "https://steipete.me/peter-avatar.jpg",  // → Update domain + filename
  sameAs: [
    "https://github.com/steipete",                // → Update username
    "https://twitter.com/steipete",               // → Update username
    "https://bsky.app/profile/steipete.me",       // → Update handle
  ],
  // SearchAction
  target: "https://steipete.me/search?q={search_term_string}", // → Update domain
}
```

**⚠️ CRITICAL:** This component has hardcoded URLs that bypass configuration. Must be refactored or deleted.

**Dependencies:** Should use `SITE` from `./consts` but currently doesn't
**Used by:** Page layouts for SEO metadata

---

#### 4. `/src/components/BaseHead.astro` - Meta Tag Overrides
**Purpose:** HTML head metadata

**Identity Elements:**
```html
<meta name="apple-mobile-web-app-title" content="steipete" />  <!-- → "justcarlson" -->
<meta name="twitter:site" content="@steipete" />               <!-- → "@justcarlson" -->
<meta name="twitter:creator" content="@steipete" />            <!-- → "@justcarlson" -->
<link rel="apple-touch-icon" href="/peter-avatar.jpg" />       <!-- → Update filename -->
```

**Dependencies:** Imports `SITE` from `./consts` (partial usage)
**Used by:** All page layouts

---

#### 5. `/src/components/NewsletterForm.astro` - Newsletter Integration
**Purpose:** Newsletter subscription form

**Identity Elements:**
```html
<form action="https://buttondown.com/api/emails/embed-subscribe/steipete">
  <input type="hidden" name="tag" value="steipete" />
</form>
```

**Dependencies:** External service (Buttondown)
**Used by:** About page

**⚠️ ACTION REQUIRED:** Requires creating new Buttondown account or updating existing account settings

---

#### 6. `/src/components/Footer.astro` - Footer Links
**Purpose:** Site footer with copyright/license

**Identity Elements:**
```html
<a href="https://github.com/steipete/steipete.me" ...>  <!-- → Update repo path -->
  Steal this post ➜ CC BY 4.0 · Code MIT
</a>
```

**Dependencies:** None (hardcoded)
**Used by:** All page layouts

---

#### 7. `/src/components/Sidebar.astro` - Sidebar Social Links (Likely Unused)
**Purpose:** Sidebar component with social links

**Identity Elements:**
```html
<a href="https://github.com/steipete">...</a>
<a href="https://twitter.com/steipete">...</a>
<a href="https://www.linkedin.com/in/steipete/">...</a>
<a href="mailto:peter@steipete.me">...</a>
```

**⚠️ NOTE:** This component appears to be from an old theme. Verify if it's actually used in production.

**Dependencies:** None (hardcoded)
**Used by:** Unknown (may be legacy code)

---

### Asset Files (Static Layer)

#### 8. `/public/` - Static Assets
**Purpose:** Static files served directly

**Identity Elements:**
- `peter-avatar.jpg` → Rename to `avatar.jpg` or `justcarlson-avatar.jpg`
- `peter-office.jpg` → Replace or rename to `office.jpg`
- `peter-office-2.jpg` → Replace or rename to `office-2.jpg`
- `favicon.ico` → Replace with new favicon
- `site.webmanifest` → Update name/description

**Dependencies:** Referenced by configuration, components, and PWA manifest
**Used by:** Entire application

---

#### 9. `/public/site.webmanifest` - PWA Manifest
**Purpose:** Progressive Web App configuration

**Identity Elements:**
```json
{
  "name": "Peter Steinberger",              // → "Just Carlson"
  "short_name": "Peter Steinberger",        // → "Just Carlson"
  "description": "iOS developer...",        // → Update bio
}
```

**Dependencies:** None
**Used by:** PWA integration, mobile browsers

---

### Build Configuration (Infrastructure Layer)

#### 10. `/astro.config.mjs` - Astro Build Configuration
**Purpose:** Build-time configuration

**Identity Elements:**
```javascript
AstroPWA({
  includeAssets: ["favicon.ico", "peter-avatar.jpg"],  // → Update asset filenames
  manifest: {
    name: "Peter Steinberger",                          // → "Just Carlson"
    short_name: "steipete",                             // → "justcarlson"
    description: "AI-powered tools...",                 // → Update tagline
    icons: [
      { src: "peter-avatar.jpg", ... },                 // → Update filename
    ],
  },
})
```

**Dependencies:** References `SITE.website` from config
**Used by:** Build process, service worker generation

---

#### 11. `/vercel.json` - Deployment Configuration
**Purpose:** Vercel hosting settings with domain-specific rules

**Identity Elements:**
```json
{
  "redirects": [
    {
      "has": [{ "type": "host", "value": "steipete.me" }],     // → Update domain
      "destination": "https://steipete.md/:path*"              // → Remove or update
    }
  ],
  "headers": [
    {
      "key": "Content-Security-Policy",
      "value": "...https://steipete.me..."                     // → Update CSP domains
    }
  ]
}
```

**⚠️ CRITICAL:** Contains domain-specific security policies and redirects

**Dependencies:** None (infrastructure)
**Used by:** Vercel deployment

---

### Content Files (Content Layer)

#### 12. `/src/pages/about.mdx` - About Page
**Purpose:** Personal bio and information

**Identity Elements:**
```markdown
<img src="/peter-office.jpg" alt="Peter in his office setup" />  <!-- → Update filename/alt -->
I split my time between Vienna ↔ London.                         <!-- → Update bio -->
[Check out my speaking history & topics](https://github.com/steipete/speaking)  <!-- → Update link -->
[Follow me on GitHub](https://github.com/steipete/)              <!-- → Update username -->

<p>Imprint: Peter Steinberger, Siebensterngasse 15, 1070 Vienna, Austria</p>  <!-- → Update legal info -->
```

**Dependencies:** References public assets
**Used by:** About page route

---

#### 13. `/src/pages/about.md.ts` - About Page Frontmatter (If exists)
**Purpose:** Programmatic about page generation

**Identity Elements:** (To be verified - file name suggests it exists)

---

#### 14. `/src/utils/og-templates/site.js` - OG Image Template
**Purpose:** Generates Open Graph social preview images

**Identity Elements:**
```javascript
children: SITE.title,                    // Uses SITE.title (auto-updates)
children: SITE.desc,                     // Uses SITE.desc (auto-updates)
children: new URL(SITE.website).hostname // Uses SITE.website (auto-updates)
```

**Dependencies:** Imports `SITE` from config (✅ already configured correctly)
**Used by:** Build process for generating OG images

---

#### 15. `/src/layouts/Layout.astro` - Root Layout
**Purpose:** Base HTML layout template

**Identity Elements:**
```html
<!-- Domain-based markdown redirect -->
<script is:inline>
  if ((hostname === 'steipete.md' || hostname === 'www.steipete.md') && ...) {
    // Redirect to .md version
  }
</script>
```

**Dependencies:** Uses `SITE` from config for most metadata
**Used by:** All pages

---

## File-to-Change Mapping

### Tier 1: Foundation (Change First)
These files are the single source of truth. Change these before anything else.

| File | Changes | Priority | Risk |
|------|---------|----------|------|
| `/src/consts.ts` | Update `SITE` object (website, author, title, desc, ogImage, editPost.url), `SOCIAL_LINKS` array | **P0** | Low - Config only |
| `/src/constants.ts` | Update `SOCIALS` array (hrefs, email) | **P0** | Low - Config only |

**Dependencies:** None (foundation layer)

---

### Tier 2: Static Assets (Change Before Components)
Physical files that need renaming/replacement.

| File | Changes | Priority | Risk |
|------|---------|----------|------|
| `/public/peter-avatar.jpg` | Replace with new avatar, rename to `avatar.jpg` | **P1** | Medium - Referenced everywhere |
| `/public/peter-office.jpg` | Replace with new photo, rename to `office.jpg` | **P1** | Low - Only in about page |
| `/public/peter-office-2.jpg` | Replace or delete, rename if keeping | **P1** | Low - Verify usage |
| `/public/favicon.ico` | Replace with new favicon | **P1** | Medium - Browser identity |
| `/public/site.webmanifest` | Update name, short_name, description | **P1** | Low - PWA only |

**Dependencies:** Must complete before updating component references

---

### Tier 3: Components (Change After Assets)
Components that reference configuration or assets.

| File | Changes | Priority | Risk |
|------|---------|----------|------|
| `/src/components/StructuredData.astro` | **Refactor to use SITE config** or delete and use Layout.astro structured data | **P0** | High - SEO impact |
| `/src/components/BaseHead.astro` | Update hardcoded Twitter handles, app title, avatar filename | **P1** | Medium - SEO/PWA |
| `/src/components/Footer.astro` | Update GitHub repo URL | **P1** | Low - Just a link |
| `/src/components/NewsletterForm.astro` | Update Buttondown account URL and tag | **P2** | High - External service |
| `/src/components/Sidebar.astro` | Update social links **IF USED** (verify first) | **P2** | Low - May be unused |

**Dependencies:**
- Requires Tier 1 (config) complete
- References Tier 2 (assets) filenames

---

### Tier 4: Build Configuration (Change After Components)
Build-time settings that aggregate other changes.

| File | Changes | Priority | Risk |
|------|---------|----------|------|
| `/astro.config.mjs` | Update PWA manifest (name, short_name, description), asset filenames | **P1** | Medium - Build output |
| `/vercel.json` | Update domain in redirects, CSP headers | **P0** | **HIGH** - Deployment |
| `/src/layouts/Layout.astro` | Update or remove `steipete.md` redirect script | **P1** | Medium - Routing |

**Dependencies:** Must align with Tier 1-3 changes

---

### Tier 5: Content (Change Last)
Content files with embedded identity references.

| File | Changes | Priority | Risk |
|------|---------|----------|------|
| `/src/pages/about.mdx` | Update bio, photos, GitHub links, legal imprint | **P1** | Low - Content only |
| Blog posts in `/src/content/blog/` | **No changes needed** - Historical context preserved | **N/A** | Low - Archive |

**Dependencies:** References Tier 2 (assets) and should align with Tier 1 (config)

---

## Change Order & Dependencies

### Phase 1: Configuration Foundation (Do First)
```
1. Update /src/consts.ts (SITE object, SOCIAL_LINKS)
2. Update /src/constants.ts (SOCIALS array)
```
**Why first:** These are imported by everything else. Changes cascade automatically.

**Validation:** Run `npm run build` - should succeed with no errors.

---

### Phase 2: Static Assets (Do Second)
```
3. Replace /public/peter-avatar.jpg → avatar.jpg
4. Replace /public/peter-office.jpg → office.jpg (or delete)
5. Replace /public/peter-office-2.jpg → office-2.jpg (or delete)
6. Replace /public/favicon.ico
7. Update /public/site.webmanifest
```
**Why second:** Assets must exist before components reference them.

**Validation:** Check that old filenames are not referenced anywhere:
```bash
grep -r "peter-avatar\|peter-office" src/
```

---

### Phase 3: Component Updates (Do Third)
```
8. Update /src/components/BaseHead.astro (Twitter handles, app title, avatar path)
9. Refactor /src/components/StructuredData.astro (use SITE config) OR delete it
10. Update /src/components/Footer.astro (GitHub repo URL)
11. Update /src/components/NewsletterForm.astro (Buttondown account)
12. Verify /src/components/Sidebar.astro usage, update if needed
```
**Why third:** Components depend on config + assets being in place.

**Validation:** Run `npm run dev`, visit pages, check:
- Meta tags in HTML source
- Social links work
- Newsletter form posts to correct URL

---

### Phase 4: Build & Deploy Config (Do Fourth)
```
13. Update /astro.config.mjs (PWA manifest, asset references)
14. Update /vercel.json (domain redirects, CSP headers)
15. Update /src/layouts/Layout.astro (domain redirect script)
```
**Why fourth:** These reference everything above. Must be last infrastructure changes.

**Validation:**
- Build succeeds: `npm run build`
- Preview works: `npm run preview`
- Check service worker manifest: `/manifest.webmanifest`

---

### Phase 5: Content Updates (Do Last)
```
16. Update /src/pages/about.mdx (bio, photos, links, imprint)
17. Review /src/content/blog/ posts (optional - historical context is fine)
```
**Why last:** Content is presentation layer only, doesn't affect functionality.

**Validation:** Visual review of about page.

---

## Critical Dependencies

### Asset Filename Dependencies
**If renaming `peter-avatar.jpg` → `avatar.jpg`:**

Must update:
- `/src/consts.ts` → `ogImage: "avatar.jpg"`
- `/src/components/BaseHead.astro` → `href="/avatar.jpg"`
- `/src/components/StructuredData.astro` → All hardcoded URLs
- `/astro.config.mjs` → `includeAssets` and `manifest.icons`

**Recommendation:** Use find/replace for filename changes to ensure nothing is missed.

---

### Domain Dependencies
**If changing from `steipete.me` → `justcarlson.com`:**

Must update:
- `/src/consts.ts` → `website`, `profile` URLs
- `/vercel.json` → All domain references in redirects and CSP
- `/src/components/StructuredData.astro` → All hardcoded URLs
- `/src/layouts/Layout.astro` → Domain redirect script

**Recommendation:** Update Vercel project settings to point to new domain AFTER code changes deployed.

---

### External Service Dependencies
**Newsletter (Buttondown):**
- Requires new Buttondown account OR updating existing account username
- Update form action URL in `/src/components/NewsletterForm.astro`
- **Risk:** Subscribers may be lost if account not properly migrated

**GitHub Repository:**
- Update repo path in `/src/consts.ts` editPost.url
- Update repo link in `/src/components/Footer.astro`
- Consider forking/renaming the `steipete/steipete.me` repo to `justcarlson/justcarlson.com`

---

## Suggested Change Sequence (Ideal Order)

### Week 1: Preparation & Foundation
```
Day 1-2: Preparation
- [ ] Create new avatar/office photos
- [ ] Create new favicon
- [ ] Create new Buttondown newsletter account (or migrate)
- [ ] Set up new GitHub repo (justcarlson/justcarlson.com)

Day 3: Configuration
- [ ] Update /src/consts.ts
- [ ] Update /src/constants.ts
- [ ] Test build: npm run build

Day 4-5: Assets
- [ ] Add new avatar/photos to /public/
- [ ] Update /public/site.webmanifest
- [ ] Update all component references to new filenames
- [ ] Remove old peter-* files
- [ ] Test build and visual review
```

---

### Week 2: Components & Infrastructure
```
Day 1-2: Components
- [ ] Refactor /src/components/StructuredData.astro
- [ ] Update /src/components/BaseHead.astro
- [ ] Update /src/components/Footer.astro
- [ ] Update /src/components/NewsletterForm.astro
- [ ] Test all pages in dev mode

Day 3: Build Configuration
- [ ] Update /astro.config.mjs
- [ ] Update /vercel.json
- [ ] Update /src/layouts/Layout.astro redirect script
- [ ] Test production build

Day 4: Content
- [ ] Update /src/pages/about.mdx
- [ ] Review blog posts for identity mentions (optional)

Day 5: Deployment
- [ ] Deploy to staging (preview deployment)
- [ ] Full manual testing
- [ ] Deploy to production
- [ ] Update Vercel domain settings
- [ ] Monitor for issues
```

---

## Anti-Patterns to Avoid

### ❌ Don't Change Files Out of Order
**Problem:** Updating components before config causes broken imports.
**Solution:** Always follow Tier 1 → Tier 2 → Tier 3 → Tier 4 → Tier 5 sequence.

---

### ❌ Don't Do Partial Renames
**Problem:** Renaming `peter-avatar.jpg` but forgetting to update all references causes broken images.
**Solution:** Use global find/replace and validation grep after each rename.

---

### ❌ Don't Skip Testing Between Tiers
**Problem:** Accumulating errors makes debugging difficult.
**Solution:** Run `npm run build` and manual testing after each tier completes.

---

### ❌ Don't Update Production DNS Before Code Deployment
**Problem:** Pointing justcarlson.com to site before code changes causes broken identity.
**Solution:** Deploy code changes first, THEN update DNS/domain settings.

---

### ❌ Don't Forget External Service Dependencies
**Problem:** Newsletter form breaks if Buttondown account not updated.
**Solution:** Create/migrate external services BEFORE updating component references.

---

## Testing Checklist

After each tier completion:

### Tier 1 (Config) Testing
- [ ] `npm run build` succeeds
- [ ] No TypeScript errors
- [ ] Config values import correctly in components

### Tier 2 (Assets) Testing
- [ ] Old filenames no longer referenced: `grep -r "peter-" src/`
- [ ] New files exist: `ls public/avatar.jpg public/office.jpg`
- [ ] Images display correctly in dev mode

### Tier 3 (Components) Testing
- [ ] Meta tags correct in HTML source (view source on any page)
- [ ] Social links point to correct accounts
- [ ] Newsletter form posts to correct URL
- [ ] No console errors in browser DevTools

### Tier 4 (Build Config) Testing
- [ ] Production build succeeds: `npm run build && npm run preview`
- [ ] Service worker generated: check `/manifest.webmanifest`
- [ ] PWA manifest correct: check Chrome DevTools → Application → Manifest
- [ ] No CSP violations: check browser console

### Tier 5 (Content) Testing
- [ ] About page displays correctly
- [ ] Photos render correctly
- [ ] Links work
- [ ] Legal imprint updated

---

## Risk Assessment

| Change Area | Risk Level | Impact | Mitigation |
|-------------|-----------|--------|------------|
| Configuration files | **Low** | High - affects everything | Test build after each change |
| Asset renaming | **Medium** | High - broken images | Use find/replace, grep validation |
| StructuredData component | **High** | High - SEO impact | Refactor to use config, validate JSON-LD |
| Vercel.json CSP | **High** | High - site may break | Test thoroughly in preview deployment |
| Newsletter form | **High** | Medium - external service | Set up new service first, test form submission |
| Domain redirect script | **Medium** | Medium - routing | Remove if not needed for justcarlson.com |

---

## Confidence Assessment

| Area | Confidence | Notes |
|------|------------|-------|
| Configuration mapping | **HIGH** | Clear single source of truth in consts.ts |
| Asset references | **HIGH** | Grep found all references |
| Component dependencies | **HIGH** | Import chains are clear |
| Build config impact | **MEDIUM** | Vercel.json is complex, needs careful testing |
| External services | **MEDIUM** | Buttondown migration needs verification |

---

## Open Questions

1. **Sidebar Component Usage:** Is `/src/components/Sidebar.astro` actually used in production? It has hardcoded links but wasn't found in current layouts.
   - **Action:** Grep for `<Sidebar` in src/ to confirm usage
   - **If unused:** Delete the file

2. **Newsletter Migration:** Should existing Buttondown subscribers be migrated to new account, or start fresh?
   - **Action:** Contact Buttondown support about account username change
   - **Alternative:** Export subscribers, import to new account

3. **Old Blog Post References:** Blog posts contain embedded tweets and mentions of "Peter Steinberger". Should these be updated?
   - **Recommendation:** Leave as-is for historical context
   - **Alternative:** Add author note at top of old posts

4. **GitHub Repository:** Fork `steipete/steipete.me` or create fresh repo?
   - **Recommendation:** Fork to preserve history, then update remote URLs
   - **Action:** Update git remote after fork

5. **Domain Redirect Strategy:** Should steipete.me redirect to justcarlson.com after rebrand?
   - **Decision needed:** Preserve old domain with redirect? Or let it expire?
   - **If redirect:** Keep vercel.json redirect rules, reverse the direction

---

## Gaps to Address

1. **StructuredData.astro Refactoring:** This component should import from `SITE` config instead of hardcoding. Consider deleting it entirely and using the structured data already in `/src/layouts/Layout.astro`.

2. **Social Media Account Creation:** New accounts needed for:
   - GitHub: justcarlson
   - Twitter/X: @justcarlson
   - BlueSky: justcarlson.com
   - LinkedIn: justcarlson
   - Email: contact@justcarlson.com or similar

3. **Asset Creation:** Need to create:
   - Personal avatar photo
   - Office/workspace photos
   - Favicon (16x16, 32x32, 48x48)

4. **Legal Review:** About page imprint needs updating with current legal information.

---

## Summary for Roadmap

**Rebranding is straightforward due to good architecture:**
- Configuration is centralized in 2 files
- Most components use config values (auto-update)
- Asset renaming is the main manual effort
- Critical path: Config → Assets → Components → Deploy

**Estimated effort:**
- Tier 1 (Config): 1 hour
- Tier 2 (Assets): 2-3 hours (includes creation)
- Tier 3 (Components): 2-4 hours
- Tier 4 (Build Config): 1-2 hours
- Tier 5 (Content): 1 hour
- Testing & Deployment: 2-3 hours

**Total: 9-14 hours** of focused work, spread across 1-2 weeks for safety.

**Recommended approach:** Feature branch → preview deployment → full testing → production deployment → DNS update (in that order).

---

*Architecture research complete: 2026-01-28*
