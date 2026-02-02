---
status: resolved
trigger: "Website doesn't load gracefully when social media services (Twitter) are blocked by firewall/VPN"
created: 2026-02-02T12:00:00Z
updated: 2026-02-02T12:00:00Z
---

## Current Focus

hypothesis: CONFIRMED - Twitter widget script in Layout.astro loads unconditionally and fails when Twitter is blocked
test: N/A - root cause identified
expecting: N/A
next_action: Remove or make Twitter widget script conditional/fault-tolerant

## Symptoms

expected: All pages load gracefully and fully functional even when social media services are blocked by firewall/VPN
actual: Partial load with errors - some sections broken or missing when Twitter is blocked
errors: |
  syndication.twitter.com/settings?session_id=...: Failed to load resource: net::ERR_NAME_NOT_RESOLVED
  about.BYldAH4T.css:1: Failed to load resource: the server responded with a status of 403 (Forbidden)
  Multiple "Tracking Prevention blocked access to storage" warnings
reproduction: Block Twitter/social media via firewall or VPN, then load www.justcarlson.com
started: Works perfectly when social media services are accessible; only breaks when blocked

## Eliminated

## Evidence

- timestamp: 2026-02-02T12:00:00Z
  checked: Grep for twitter/syndication references
  found: 5 files contain Twitter references - PostDetails.astro, ShareLinks.astro, Socials.astro, consts.ts, Layout.astro
  implication: Twitter integration exists in multiple places - need to check each for blocking behavior

- timestamp: 2026-02-02T12:01:00Z
  checked: Layout.astro line 136
  found: `<script async src="https://platform.twitter.com/widgets.js" charset="utf-8"></script>` loads unconditionally
  implication: This is the source of syndication.twitter.com requests - fails when Twitter blocked

- timestamp: 2026-02-02T12:01:30Z
  checked: ShareLinks.astro, Socials.astro, consts.ts
  found: These only contain Twitter LINKS (share buttons, profile links) - no external scripts
  implication: These are fine - they're just static href links that don't cause network requests on page load

- timestamp: 2026-02-02T12:02:00Z
  checked: Blog content (src/content/blog/*.md)
  found: No Twitter embeds in any blog posts
  implication: The widgets.js script is not actually needed - no twitter-tweet blockquotes exist in content

## Resolution

root_cause: |
  Layout.astro unconditionally loads Twitter widgets.js script on EVERY page:
  `<script async src="https://platform.twitter.com/widgets.js">`

  This script makes requests to syndication.twitter.com even though no Twitter embeds exist
  in the content. When Twitter is blocked, these requests fail, causing console errors and
  potentially blocking/slowing page load.

fix: Remove the Twitter widget script from Layout.astro since no Twitter embeds are used
verification: |
  1. Build completed successfully
  2. Grep for platform.twitter.com in dist/ returns no matches
  3. Twitter widget script no longer present in any generated HTML
  4. Only remaining "twitter" references are Open Graph meta tags (twitter:card, etc.) which are static
files_changed:
  - src/layouts/Layout.astro: Removed Twitter widget script (line 135-136)
