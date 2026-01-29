# Blog Rebranding Features Analysis

**Context**: Rebranding steipete.me → justcarlson.com
**Source**: Peter Steinberger's Astro blog (forked)
**Target**: Just Carlson's personal blog
**Date**: 2026-01-28

---

## Executive Summary

Rebranding a forked blog requires changing three layers of identity: **technical ownership** (URLs, configs), **visual identity** (colors, images, typography), and **content ownership** (author attribution, bio, posts). This document categorizes these changes by priority and strategic impact.

---

## Table Stakes
> *Must change or the blog is still Peter's, not yours*

### Identity Elements (Critical)

#### Author & Site Metadata
- **Configuration files**:
  - `/src/consts.ts` - Update `SITE` object:
    - `website`: `https://justcarlson.com/`
    - `author`: `"Just Carlson"`
    - `profile`: `https://justcarlson.com/about`
    - `desc`: Personal tagline/description
    - `title`: `"Just Carlson"` (appears in header, title tags)
    - `timezone`: Update if different from `America/Los_Angeles`
  - `/src/constants.ts` - Update `SOCIALS` array (all hrefs, linkTitles)
  - `/package.json`:
    - `name`: Change from `"steipete-astro"` to `"justcarlson-com"`
    - Remove commitizen/husky if not using conventional commits

#### Social Links & Handles
- **Components**:
  - `/src/constants.ts` → `SOCIALS` array (6 instances of steipete URLs)
  - `/src/consts.ts` → `SOCIAL_LINKS` array
- **Replace**:
  - GitHub: `https://github.com/steipete` → `https://github.com/justcarlson`
  - X/Twitter: `https://x.com/steipete` → your handle
  - BlueSky: `https://bsky.app/profile/steipete.me` → your profile
  - LinkedIn: `https://www.linkedin.com/in/steipete/` → your profile
  - Email: `peter@steipete.me` → your email

#### Visual Assets
- **Files to replace**:
  - `/public/favicon.ico` - Browser tab icon
  - `/public/peter-avatar.jpg` - Used for:
    - PWA manifest icons (192x192, 512x512)
    - Apple touch icon
    - Sidebar/header avatar
    - OG image fallback
  - `/public/peter-office.jpg` & `/public/peter-office-2.jpg` - About page photos
  - `/public/og.png` - Default Open Graph image for link previews

#### Meta Tags & SEO
- **Components to update**:
  - `/src/components/BaseHead.astro`:
    - Line 33: `<link rel="apple-touch-icon" href="/peter-avatar.jpg" />` → your avatar
    - Line 40: `<meta name="apple-mobile-web-app-title" content="steipete" />`
    - Line 41: `<meta name="application-name" content="Peter Steinberger" />`
    - Line 71-72: `<meta name="twitter:site" content="@steipete" />` → your handle
  - PWA Manifest (`/astro.config.mjs` lines 103-131):
    - `name`: `"Peter Steinberger"` → `"Just Carlson"`
    - `short_name`: `"steipete"` → your short name
    - `description`: Update tagline
    - `includeAssets`: Change `"peter-avatar.jpg"` to your avatar filename

#### Domain & URLs
- **Critical config changes**:
  - `/vercel.json` - 19 instances of steipete.me/steipete.md references:
    - Redirects (lines 8-67): Domain canonicalization rules
    - CSP headers (line 144): Allowed origins for scripts/images
  - Remove/update Peter-specific redirects:
    - Markdown domain redirect (`.md` extension feature)
    - Blog post URL migrations
  - Update CSP domains to match your deployment

#### Content Attribution
- **Footer & Legal**:
  - `/src/components/Footer.astro`:
    - Line 19: GitHub repo link `https://github.com/steipete/steipete.me`
    - Consider: Keep "Steal this post" CTA or make it your own
  - `/LICENSE`:
    - Line 27: Copyright `(c) 2025 Peter Steinberger`
  - `/README.md`:
    - Lines 1, 7, 56: Remove Peter's name/bio
    - Line 56: Attribution to original AstroPaper theme (keep this)

---

## Differentiators
> *Makes it feel personal and owned, not just rebranded*

### Content Layer

#### About Page (`/src/pages/about.mdx`)
- **Replace entirely**:
  - Hero image & alt text (line 11)
  - Bio paragraphs (lines 14-20) - your story, not Peter's
  - GitHub activity chart (line 26): `https://ghchart.rshah.org/steipete` → your username
  - Location, work status, speaking history
  - Imprint/legal footer (line 47) - your legal entity/address if required

#### Blog Posts
- **Delete Peter's 107 posts** from `/src/content/blog/`:
  - Organized by year folders (2010-2025)
  - Includes `/public/assets/img/` directories with post images
- **Start fresh** or migrate selectively if referencing his work

#### Newsletter Form
- **Component**: `/src/components/NewsletterForm.astro`
- Update or remove - likely uses Peter's email service integration

### Visual Identity

#### Color Palette
- **CSS Variables** (`/src/styles/custom.css`):
  - Lines 3-12: Root colors (sidebar bg, link colors, box shadows)
  - Line 6: `--link-color: #007bff` (Bootstrap blue - very generic)
  - Lines 211-217: Dark mode overrides
- **Theme colors** (`/src/components/BaseHead.astro`):
  - Line 52: `#006cac` (light mode) - Peter's brand blue
  - Line 58: `#ff6b01` (dark mode) - Orange accent
- **PWA manifest** (`/astro.config.mjs`):
  - Line 107: `theme_color: "#006cac"`
  - Line 108: `background_color: "#fdfdfd"`

#### Typography
- **Font preloading** (`/src/components/BaseHead.astro` lines 92-93):
  - Uses Atkinson (open-source font)
  - Consider: Stick with it or change to match your brand
- **Code syntax themes** (`/astro.config.mjs` line 26):
  - Light: `min-light`
  - Dark: `night-owl`

#### Layout Customization
- **Sidebar** (`/src/styles/custom.css`):
  - `--sidebar-width: 260px` (line 4)
  - `--content-max-width: 800px` (line 6)
- **Features to configure**:
  - Archive page visibility: `/src/consts.ts` → `showArchives: false`
  - Back button: `showBackButton: false`
  - Posts per page: `postPerPage: 10`

### Technical Elements

#### Analytics & Tracking
- **Current setup** (`/src/components/Analytics.astro`):
  - Vercel Analytics (auto-injects in production)
  - Vercel Speed Insights
- **Action**: Keep as-is or integrate Google Analytics, Plausible, etc.

#### "Edit on GitHub" Feature
- **Config** (`/src/consts.ts` lines 46-50):
  - `enabled: true`
  - `text: "Edit on GitHub"`
  - `url: "https://github.com/steipete/steipete.me/edit/main/"`
- **Update**: Change repo URL to yours

#### Build Scripts
- **Optional cleanup** (`/package.json`):
  - Line 13: `add-source-metadata` script (adds Git metadata to posts)
  - Line 14: `remove-tags` script (bulk tag removal)
  - Lines 20-21: Husky/commitizen (if not using conventional commits)

#### Domain-Specific Features
- **Markdown rendering** (`/src/layouts/Layout.astro` lines 135-143):
  - Peter uses `steipete.md` domain to serve markdown versions of posts
  - Remove unless you want this feature with your domain

---

## Anti-Features
> *Things to deliberately NOT do when rebranding*

### Preservation

#### Keep Attribution to Original Theme
- **README acknowledgment** (lines 54-56):
  - Credit to [Sat Naing](https://github.com/satnaing) for AstroPaper theme
  - **Rationale**: Open-source etiquette; helps others discover the upstream

#### Respect Dual Licensing
- **LICENSE file**:
  - Keep structure: CC BY 4.0 for content, MIT for code
  - Update copyright holder name only
  - **Rationale**: Common pattern for blogs; protects content while sharing code

### Content Strategy

#### Don't Copy Peter's Voice
- **Writing style**:
  - Peter's bio: "Deep in vibe-coding mode – tinkering with shiny web tech"
  - His brand: iOS expert → web developer transition narrative
- **Action**: Write in your own voice, don't mimic his casual-technical style

#### Don't Inherit His Old Posts
- **107 existing posts** cover:
  - iOS development (2010-2020)
  - Swift, UIKit, debugging deep-dives
  - Remote work/hiring (PSPDFKit context)
  - Recent web development exploration
- **Rationale**: They're his expertise/experience, not yours
- **Exception**: If citing/responding to his work, link to original steipete.me

### Technical

#### Don't Keep Peter-Specific Redirects
- **vercel.json has 15+ redirects** for:
  - Old Jekyll URL patterns → new Astro URLs
  - Blog post slug migrations
  - Category → tags renames
- **Action**: Remove unless you're migrating from a previous blog with same URL structure

#### Don't Use His GitHub Contribution Graph
- **About page** embeds `https://ghchart.rshah.org/steipete`
- Showing his commit history on your blog makes no sense

#### Don't Keep His CSP Domain Allowlist
- **Content Security Policy** (vercel.json line 144):
  - Whitelists `steipete.me`, `*.vercel.app`, `*.sweetistics.com`
  - Includes Twitter/Vimeo/YouTube embeds
- **Action**: Audit what YOU need, remove Peter's domains

### Branding

#### Avoid Generic Color Schemes
- Current `#007bff` link color is Bootstrap default blue
- Peter's `#006cac` theme color is distinctive but tied to his brand
- **Opportunity**: Choose colors that reflect YOUR identity

#### Don't Over-Customize the Layout Initially
- AstroPaper's structure is well-designed
- Focus on content/identity first, visual tweaks later
- **Rationale**: Avoid bikeshedding; ship content quickly

---

## Implementation Checklist

### Phase 1: Critical Identity (Can't deploy without)
- [ ] Update all author names in `/src/consts.ts` + `/src/constants.ts`
- [ ] Replace avatar/favicon images
- [ ] Update social media links (6 profiles)
- [ ] Change GitHub repo URL in footer
- [ ] Update LICENSE copyright holder
- [ ] Modify PWA manifest (name, description, icons)
- [ ] Update vercel.json domain references

### Phase 2: Content Ownership
- [ ] Delete Peter's 107 blog posts
- [ ] Write new About page
- [ ] Remove/update newsletter form
- [ ] Clear `/public/assets/img/` of Peter's post images
- [ ] Remove GitHub contribution chart embed

### Phase 3: Visual Differentiation
- [ ] Choose brand colors (update CSS variables + theme-color meta tags)
- [ ] Decide on typography (keep Atkinson or change)
- [ ] Set OG image default
- [ ] Configure syntax highlighting themes
- [ ] Adjust layout dimensions if desired

### Phase 4: Technical Cleanup
- [ ] Remove Peter-specific redirects from vercel.json
- [ ] Audit CSP headers for your domains
- [ ] Update "Edit on GitHub" URL
- [ ] Configure analytics (keep Vercel or switch)
- [ ] Remove markdown domain feature if not using
- [ ] Clean up unused npm scripts

---

## Testing Requirements

After rebranding, verify:

1. **Link integrity**: No broken social links, GitHub URLs point to your repos
2. **Image loading**: All avatars/favicons render correctly (check PWA manifest)
3. **Meta tags**: OG previews on Twitter/LinkedIn show your name/image
4. **Analytics**: Tracking works on your domain (not Peter's)
5. **RSS feed**: `/rss.xml` shows your author name
6. **Search**: Pagefind indexing works (rebuilds on deploy)
7. **Mobile PWA**: "Add to home screen" shows correct app name
8. **Legal**: LICENSE file has your copyright, footer links to your GitHub

---

## Notes

- **107 blog posts**: Peter's archive is substantial (10+ years). Consider keeping folder structure if you plan similar volume.
- **Vercel deployment**: Config is tightly coupled to Vercel. If hosting elsewhere, much of `vercel.json` won't apply.
- **Markdown domain**: Peter's `.md` domain feature is clever but requires second domain. Skip unless you have specific use case.
- **Build scripts**: `add-source-metadata.mjs` adds Git commit data to posts. Useful if tracking post history.
- **Theme consistency**: AstroPaper base theme uses Tailwind 4 + Astro 5. Upgrading might break Peter's customizations.

---

## Upstream Reference

- **Original fork**: [steipete/steipete.me](https://github.com/steipete/steipete.me)
- **Base theme**: [AstroPaper](https://astro-paper.pages.dev/) by [Sat Naing](https://github.com/satnaing)
- **File count**: ~200 files, ~25k lines (including blog content)
- **Last updated**: Fork date unknown, research based on current state

---

**Research completed**: 2026-01-28
**Researcher**: GSD Project Researcher
**Downstream**: Requirements definition for rebrand implementation
