# Blog Rebranding Pitfalls

**Domain:** Blog rebranding from forked repository (steipete.me → justcarlson.com)
**Researched:** 2026-01-28
**Confidence:** HIGH (based on codebase analysis + 2026 SEO migration sources)

## Critical Pitfalls

Mistakes that cause broken functionality, SEO damage, or require extensive rework.

### Pitfall 1: Hardcoded Domain References

**What goes wrong:** Domain name "steipete.me" hardcoded in multiple locations instead of using config variables. This causes broken links, incorrect metadata, and mixed branding.

**Why it happens:** Developers hardcode domains for "convenience" or miss obscure locations where the domain appears.

**Consequences:**
- Broken canonical URLs and redirects
- Social media cards showing wrong domain
- CSP headers blocking legitimate requests
- Mixed branding in user-facing content

**Warning signs:**
- Direct string literals like `"steipete.me"` in code
- Hardcoded URLs in OG image templates
- Domain references in comments/documentation

**Prevention:**
- Use `SITE.website` from config everywhere
- Search entire codebase: `grep -r "steipete\.me" --exclude-dir=node_modules`
- Validate all URLs resolve to new domain after deployment

**Files to audit:**
- `/src/consts.ts` - Primary site config (SITE.website, author, profile)
- `/vercel.json` - CSP headers, redirect rules, domain allowlists (lines 62, 142)
- `/src/utils/og-templates/post.js` - Hardcoded "steipete.me" at line 216
- `/astro.config.mjs` - PWA manifest, start URLs (lines 102-131)
- `/src/components/BaseHead.astro` - Meta tags, Twitter handle (lines 40, 71-72)

---

### Pitfall 2: Leftover Identity References

**What goes wrong:** Original owner's name, social handles, and personal info scattered throughout codebase. Creates confusion about authorship and ownership.

**Why it happens:** Identity is embedded in 120+ files including all blog posts, config, components, and metadata. Easy to miss non-obvious locations.

**Consequences:**
- Copyright/licensing confusion (LICENSE file has "Peter Steinberger")
- SEO penalties for inconsistent authorship signals
- User confusion about who maintains the site
- Social media cards showing wrong creator handles

**Warning signs:**
- 123 files contain "steipete", "steinberger", or "peter" (case-insensitive)
- Default author in content schema (`content.config.ts` line 11)
- Social links in consts.ts (GitHub, Twitter, BlueSky handles)
- License file copyright holder
- README.md "About" section

**Prevention:**
- Global search-replace for name/handles (use case-insensitive)
- Update content schema default author
- Regenerate all dynamic OG images after author change
- Replace avatar/profile images in `/public/`

**Files to audit:**
- `/src/consts.ts` - SITE.author, SOCIAL_LINKS (lines 35, 72-88)
- `/src/content.config.ts` - Default author in schema (line 11)
- `/LICENSE` - Copyright holder (line 27)
- `/README.md` - About section, author description (lines 1-7)
- `/package.json` - Package name "steipete-astro" (line 2)
- `/public/peter-avatar.jpg` - Profile image filename
- `/src/components/BaseHead.astro` - Twitter handle @steipete (lines 71-72)
- `/public/site.webmanifest` - App name and description (lines 2-4)

---

### Pitfall 3: SEO Redirect Configuration Errors

**What goes wrong:** Using 302 (temporary) redirects instead of 301 (permanent), missing redirect mappings, or catch-all redirects to homepage.

**Why it happens:** Developers don't understand SEO implications or rush redirect implementation. Vercel JSON has complex redirect rules that need careful updating.

**Consequences:**
- Search engines won't transfer link equity/authority
- Duplicate content penalties
- Lost organic traffic (20-40% according to migration studies)
- Broken inbound links from other sites
- Users hit 404 pages on old URLs

**Warning signs:**
- Redirects using `"permanent": false`
- All old URLs redirecting to homepage instead of equivalent pages
- Domain-specific redirect rules pointing to old domain
- Missing redirects for renamed/moved content

**Prevention:**
- Use 301 (permanent) redirects for all URL changes
- Map old URLs to equivalent new URLs (not homepage)
- Test all redirects before DNS cutover
- Implement gradual redirect testing with subset of URLs
- Monitor 404 errors after migration

**Files to audit:**
- `/vercel.json` - Redirect rules (lines 8-67)
  - Line 11-14: steipete.me specific redirect (needs domain update)
  - Line 59-66: Catch-all domain redirect (needs new domain)
- `/astro.config.mjs` - Sitemap configuration and URLs
- Content-Security-Policy headers referencing old domain (vercel.json line 142)

**Sources:**
- [SEO Migration 2026 Complete Guide](https://www.veloxmedia.com/blog/seo-migration-2026-the-complete-guide)
- [12 Site Migration Mistakes That Damage SEO](https://embryo.com/blog/12-site-migration-mistakes-that-damage-seo/)
- [Site Migration SEO Common Mistakes](https://marketinglabs.co.uk/site-migration-seo-common-mistakes/)

---

### Pitfall 4: Asset References and Image Paths

**What goes wrong:** Image filenames, asset paths, and CDN URLs contain original owner's identity or reference old domain. Causes broken images and stale cache issues.

**Why it happens:** Assets stored with descriptive names like "peter-avatar.jpg" or "peter-office.jpg". PWA manifests cache these by filename.

**Consequences:**
- Broken profile images across site
- PWA cache serves old brand images
- Social media previews show wrong person
- Service worker serves stale assets

**Warning signs:**
- Files named after original owner in `/public/`
- Hardcoded asset URLs in PWA manifest
- Image references in CSS/components using old filenames
- OG image default points to renamed file

**Prevention:**
- Rename all identity-specific assets
- Update PWA manifest asset list
- Clear service worker cache after deployment
- Update all component references to new filenames
- Replace actual image files (not just rename)

**Files to audit:**
- `/public/peter-avatar.jpg` - Profile image (referenced 5+ places)
- `/public/peter-office.jpg` and `/public/peter-office-2.jpg` - About page images
- `/src/consts.ts` - ogImage: "peter-avatar.jpg" (line 39)
- `/src/components/BaseHead.astro` - Apple touch icon (line 33)
- `/astro.config.mjs` - PWA includeAssets (line 102), manifest icons (lines 120-130)

---

### Pitfall 5: Git History Reveals Original Owner

**What goes wrong:** Git commit history, author metadata, and contributor info still shows original owner. GitHub UI displays fork relationship prominently.

**Why it happens:** Forking preserves entire git history. Even rebasing/squashing leaves traces in commit metadata.

**Consequences:**
- GitHub shows "forked from steipete/steipete.me" banner
- Git blame points to original author
- Contributors page shows wrong maintainer
- Legal ambiguity about derivative works
- SEO crawlers may attribute content to original author

**Warning signs:**
- GitHub repository page shows fork relationship
- `git log` shows original author in all commits
- Repository insights show original contributors
- Remote URLs still point to original repository

**Prevention options:**
1. **Keep fork relationship** (recommended for attribution)
   - Acknowledge source in README
   - Update LICENSE to reflect derivative work
   - Clear documentation about fork origin

2. **Break fork relationship** (for complete rebrand)
   - Contact GitHub support to detach fork
   - Rewrite commit history with new author
   - Start fresh repo and import files (loses history)

**Files to audit:**
- `.git/config` - Remote URLs
- `README.md` - Fork attribution/acknowledgment
- `LICENSE` - Derivative work clause
- GitHub repository settings

**Note:** Breaking fork relationship is irreversible. Consider licensing implications before proceeding.

---

## Moderate Pitfalls

Mistakes that cause technical debt or user confusion but don't break core functionality.

### Pitfall 6: Package Names and Project Identifiers

**What goes wrong:** Package.json name, npm scripts, and project identifiers use original branding.

**Consequences:**
- Confusing dev experience for contributors
- Build artifacts labeled with wrong name
- Analytics/monitoring tools show wrong project name

**Prevention:**
- Update package.json name field
- Rename project in package managers
- Update CI/CD pipeline labels

**Files to audit:**
- `/package.json` - "name": "steipete-astro" (line 2)

---

### Pitfall 7: Content Schema Default Values

**What goes wrong:** Blog post schema has default author that applies to all posts without explicit author field.

**Consequences:**
- New posts inherit wrong author
- Bulk content imports use incorrect attribution
- Mixed authorship across content

**Prevention:**
- Update content.config.ts default author
- Add validation to catch missing author fields
- Consider removing default to force explicit author

**Files to audit:**
- `/src/content.config.ts` - Default author: SITE.author (line 11)

---

### Pitfall 8: Browser Manifest and PWA Configuration

**What goes wrong:** PWA manifest has app name, short name, and description tied to original brand. Users who install PWA see old branding.

**Consequences:**
- Home screen shortcut shows wrong name
- App switcher displays old brand
- Share targets use incorrect app info

**Prevention:**
- Update manifest name/short_name/description
- Update PWA config in astro.config.mjs
- Test PWA installation after changes
- Clear browser PWA cache

**Files to audit:**
- `/public/site.webmanifest` - Name and description (lines 2-4)
- `/astro.config.mjs` - PWA manifest config (lines 103-131)
- `/src/components/BaseHead.astro` - PWA meta tags (lines 36-42)

---

### Pitfall 9: Edit Links and GitHub Integration

**What goes wrong:** "Edit on GitHub" links point to original repository, not forked repo.

**Consequences:**
- Users can't suggest edits
- Edit button links to 404 or wrong repo
- Broken contributor workflow

**Prevention:**
- Update editPost.url in consts.ts
- Update GitHub URLs in documentation
- Test edit links after deployment

**Files to audit:**
- `/src/consts.ts` - editPost.url with GitHub link (line 49)

---

## Minor Pitfalls

Mistakes that cause annoyance but are easily fixable.

### Pitfall 10: Comments and Documentation

**What goes wrong:** Code comments reference original project/author. Documentation uses old examples.

**Consequences:**
- Developer confusion
- Onboarding friction for new contributors

**Prevention:**
- Search for comment blocks with references
- Update CHANGELOG.md entries
- Review all .md files for old project references

**Files to audit:**
- All files in `/src/content/blog/` (120+ files)
- `/CHANGELOG.md`
- `/CLAUDE.MD`
- `/docs/` directory if exists

---

### Pitfall 11: Theme Colors and Design Tokens

**What goes wrong:** Theme colors, CSS variables, and design tokens may reflect original brand identity.

**Consequences:**
- Visual inconsistency with new brand
- Stale design system

**Prevention:**
- Audit CSS custom properties
- Review theme-color meta tags
- Update tailwind config if branded

**Files to audit:**
- `/src/styles/custom.css` - CSS variables and theme tokens
- `/src/components/BaseHead.astro` - Theme color meta tags (lines 49-59)
- `/astro.config.mjs` - PWA theme_color (line 107)

---

### Pitfall 12: Search Index and Pagefind

**What goes wrong:** Pagefind search index may cache old metadata, author names, or URLs.

**Consequences:**
- Search results show old author/domain
- Stale snippets in search preview

**Prevention:**
- Rebuild pagefind index after content changes
- Clear dist/ directory before production build
- Test search functionality post-migration

**Files to audit:**
- Build output in `/dist/` (regenerated)
- Search index files generated by pagefind

---

## Checklist for Systematic Audit

Use this checklist to ensure complete rebranding:

### Identity References
- [ ] Update SITE config in `/src/consts.ts`
- [ ] Update default author in `/src/content.config.ts`
- [ ] Replace social links (GitHub, Twitter, BlueSky)
- [ ] Update LICENSE copyright holder
- [ ] Rewrite README.md About section
- [ ] Update package.json name
- [ ] Rename avatar/profile images in `/public/`

### Domain References
- [ ] Search codebase for "steipete.me" hardcoded strings
- [ ] Update `/vercel.json` redirects and CSP headers
- [ ] Update `/src/utils/og-templates/post.js` hardcoded domain
- [ ] Update `/astro.config.mjs` PWA config
- [ ] Update `/src/components/BaseHead.astro` meta tags
- [ ] Test robots.txt generation (uses SITE.website)

### SEO and Redirects
- [ ] Configure 301 redirects in vercel.json
- [ ] Map old content URLs to new equivalents
- [ ] Update domain in CSP headers
- [ ] Test all redirects before DNS cutover
- [ ] Monitor 404 errors post-migration

### Assets and Caching
- [ ] Rename identity-specific image files
- [ ] Update PWA manifest asset references
- [ ] Clear service worker cache strategy
- [ ] Replace actual image files (not just paths)
- [ ] Update OG image default

### Git and Repository
- [ ] Decide: keep or break fork relationship
- [ ] Update README fork attribution
- [ ] Update LICENSE if derivative work
- [ ] Update remote URLs if detached
- [ ] Update "Edit on GitHub" links

### Content and Schema
- [ ] Update content schema defaults
- [ ] Search all blog posts for identity references
- [ ] Regenerate OG images after author change
- [ ] Clear search index and rebuild

### PWA and Metadata
- [ ] Update site.webmanifest name/description
- [ ] Update PWA config in astro.config.mjs
- [ ] Update meta tags in BaseHead.astro
- [ ] Test PWA installation

### Build and Deployment
- [ ] Update package.json scripts if needed
- [ ] Clear dist/ before production build
- [ ] Rebuild pagefind search index
- [ ] Test entire site in staging environment
- [ ] Verify CSP doesn't block new domain

---

## Search Queries for Audit

Run these searches to catch missed references:

```bash
# Identity references (case-insensitive)
grep -ri "steipete" --exclude-dir=node_modules --exclude-dir=dist
grep -ri "steinberger" --exclude-dir=node_modules --exclude-dir=dist
grep -ri "peter" --exclude-dir=node_modules --exclude-dir=dist

# Domain references
grep -r "steipete\.me" --exclude-dir=node_modules --exclude-dir=dist

# Social handles
grep -r "@steipete" --exclude-dir=node_modules --exclude-dir=dist

# Asset files
find public -name "*peter*"
find public -name "*steipete*"

# Hardcoded URLs
grep -r "https://steipete" --exclude-dir=node_modules --exclude-dir=dist
```

---

## Sources

Web research on blog rebranding and SEO migration best practices for 2026:

- [Top Rebranding Mistakes to Avoid in 2026](https://devopus.com/blog/top-rebranding-mistakes-to-avoid-in-2026/)
- [When Rebrands Go Wrong: Common Mistakes](https://www.threerooms.com/blog/when-rebrands-go-wrong-common-mistakes-and-lessons-to-learn)
- [SEO Migration 2026: The Complete Guide](https://www.veloxmedia.com/blog/seo-migration-2026-the-complete-guide)
- [12 Site Migration Mistakes That Damage SEO](https://embryo.com/blog/12-site-migration-mistakes-that-damage-seo/)
- [Common Website Migration Mistakes](https://www.oncrawl.com/technical-seo/common-website-migration-mistakes-drag-down-seo-performance/)
- [Site Migration SEO: Common Mistakes](https://marketinglabs.co.uk/site-migration-seo-common-mistakes/)

Codebase analysis revealed 123 files containing identity references and multiple hardcoded domain locations requiring updates.
