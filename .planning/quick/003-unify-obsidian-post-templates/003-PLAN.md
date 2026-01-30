---
id: quick-003
type: quick
autonomous: true
files_modified:
  - /home/jc/notes/personal-vault/Templates/Post Template.md
  - /home/jc/notes/personal-vault/Templates/Blog Post (justcarlson).md
must_haves:
  truths:
    - "Single unified Post Template exists with all required fields"
    - "Blog Post (justcarlson).md is deleted"
    - "Template works with Templater for dynamic fields"
  artifacts:
    - path: "/home/jc/notes/personal-vault/Templates/Post Template.md"
      provides: "Unified post template with justcarlson.com fields"
      contains: "pubDatetime"
---

<objective>
Unify Obsidian post templates by merging justcarlson.com-specific fields into the standard Post Template and deleting the duplicate.

Purpose: Eliminate template sprawl and establish single source of truth for post creation that works with both Kepano's Posts.base system and justcarlson.com's Astro frontmatter requirements.

Output: Single unified Post Template.md with all required fields, Blog Post (justcarlson).md deleted.
</objective>

<context>
Current state:
- `Blog Post (justcarlson).md` has: title, pubDatetime, description, tags, draft, heroImage (Templater syntax)
- `Post Template.md` has: categories, author, url, created, published, topics, status (standard syntax)

Phase 8 context:
- Publish script will map `status: published` to publishable state
- Template must preserve `categories: "[[Posts]]"` for Posts.base compatibility
</context>

<tasks>

<task type="auto">
  <name>Task 1: Extend Post Template with justcarlson.com fields</name>
  <files>/home/jc/notes/personal-vault/Templates/Post Template.md</files>
  <action>
Update Post Template.md to merge fields from both templates:

```yaml
---
title: "<% tp.file.title %>"
pubDatetime: <% tp.date.now("YYYY-MM-DDTHH:mm:ss.000ZZ") %>
description: ""
heroImage:
categories:
  - "[[Posts]]"
author:
  - "[[Me]]"
url:
created: <% tp.date.now("YYYY-MM-DD") %>
published:
topics: []
status: draft
---

# <% tp.file.title %>

[Your content here]
```

Field mapping:
- `title`: From Blog Post template, Templater syntax
- `pubDatetime`: From Blog Post template, Templater syntax for Astro
- `description`: From Blog Post template (empty string default)
- `heroImage`: From Blog Post template (optional, no default)
- `categories`: Keep from Post Template (Posts.base compatibility)
- `author`: Keep from Post Template
- `url`: Keep from Post Template
- `created`: Convert to Templater syntax (was {{date}})
- `published`: Keep from Post Template
- `topics`: Keep from Post Template
- `status`: Keep from Post Template (replaces draft: true/false)

Note: Remove `tags: []` from Blog Post - not needed (topics serves same purpose). Remove `draft:` - replaced by `status:`.
  </action>
  <verify>cat "/home/jc/notes/personal-vault/Templates/Post Template.md" | grep -E "(title|pubDatetime|categories|status)"</verify>
  <done>Post Template.md contains all required fields from both templates with Templater syntax</done>
</task>

<task type="auto">
  <name>Task 2: Delete duplicate Blog Post template</name>
  <files>/home/jc/notes/personal-vault/Templates/Blog Post (justcarlson).md</files>
  <action>
Delete the file: `/home/jc/notes/personal-vault/Templates/Blog Post (justcarlson).md`

This template is now fully superseded by the unified Post Template.md.
  </action>
  <verify>ls "/home/jc/notes/personal-vault/Templates/Blog Post (justcarlson).md" 2>&1 | grep -q "No such file"</verify>
  <done>Blog Post (justcarlson).md no longer exists</done>
</task>

</tasks>

<verification>
1. Post Template.md exists with unified fields: `cat "/home/jc/notes/personal-vault/Templates/Post Template.md"`
2. Blog Post (justcarlson).md is deleted: `ls "/home/jc/notes/personal-vault/Templates/" | grep -i "blog post"`
3. Posts.base compatibility preserved: template has `categories: "[[Posts]]"`
4. Templater syntax works: template uses `<% tp.` expressions
</verification>

<success_criteria>
- Single Post Template.md contains: title, pubDatetime, description, heroImage, categories, author, url, created, published, topics, status
- Blog Post (justcarlson).md is deleted
- Template uses Templater syntax for dynamic fields (tp.file.title, tp.date.now)
- Posts.base link preserved (categories: "[[Posts]]")
</success_criteria>
