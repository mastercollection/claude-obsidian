---
name: wiki-lint
description: >
  Health check the Obsidian wiki vault. Finds orphan pages, dead wikilinks, stale claims,
  missing cross-references, frontmatter gaps, and empty sections. Creates or updates
  Dataview dashboards. Generates canvas maps. Triggers on: "lint", "health check",
  "clean up wiki", "check the wiki", "wiki maintenance", "find orphans", "wiki audit".
allowed-tools: Read Write Edit Glob Grep
---

# wiki-lint: Wiki Health Check

Run lint after every 10-15 ingests, or weekly. Ask before auto-fixing anything.
In `managed` mode, write the lint report to the resolved wiki root under
`wiki/meta/lint-report-YYYY-MM-DD.md`.

---

## Project Binding

Before linting:

1. Read `../wiki/references/project-binding.md`.
2. Resolve the active wiki root.
3. Treat every `wiki/...` path below as `{WikiPath}/wiki/...` when a project
   binding exists.
4. `WikiMode: managed` may write reports, dashboards, and canvas files.
5. `WikiMode: reference` is read-only. In that mode, report findings in chat
   only. Do not create `lint-report`, `dashboard.md`, or `overview.canvas`.

## Lint Checks

Work through these in order:

1. **Orphan pages**. Wiki pages with no inbound wikilinks. They exist but nothing points to them.
2. **Dead links**. Wikilinks that reference a page that does not exist.
3. **Stale claims**. Assertions on older pages that newer sources have contradicted or updated.
4. **Missing pages**. Concepts or entities mentioned in multiple pages but lacking their own page.
5. **Missing cross-references**. Entities mentioned in a page but not linked.
6. **Frontmatter gaps**. Pages missing required fields (type, status, created, updated, tags).
7. **Empty sections**. Headings with no content underneath.
8. **Stale index entries**. Items in `wiki/index.md` pointing to renamed or deleted pages.

---

## Orphan Exceptions

Do not report these files as orphan pages:

- `wiki/hot.md`
- `wiki/log.md`

These are system meta files and may exist without inbound wikilinks.

---

## Duplicate Heading Check

Apply duplicate-heading checks only to structural documents:

- `wiki/index.md`
- `wiki/overview.md`
- `wiki/meta/dashboard.md`
- `wiki/meta/lint-report-*.md`
- any folder-local `wiki/**/_index.md`

In those files, do not repeat the same heading text at the same heading level.
Example: two `## Concepts` headings in one file is a lint finding.

---

## Placeholder Text

Treat these as lint findings in folder-local `_index.md` files:

- `Use this page to collect concept pages stored in this folder.`
- `Use this page to collect entity pages stored in this folder.`
- `Use this page to collect domain pages stored in this folder.`

Replace placeholder instructions with one of these states only:

- a list of actual notes in that folder
- a single explicit empty-state line such as `No concept notes have been created yet.`

---

## Operational Terms

Do not require `[[CLAUDE]]` or project `AGENTS.md` references as evidence for
operational notes.

Treat these as infrastructure/configuration terms by default:

- `Wiki Binding`
- `WikiMode`
- `WikiPath`
- `AGENTS.md`
- `CLAUDE.md`
- MCP server names
- literal file paths

Write them as code-formatted text, not wikilinks, unless the wiki
intentionally maintains a real page for that term.

---

## Overview Placeholder Severity

If `wiki/overview.md` still contains the default purpose placeholder, report it
as a low-severity reminder, not a structural error.

---

## Lint Report Format

Create at `{WikiPath}/wiki/meta/lint-report-YYYY-MM-DD.md` when writes are
allowed:

```markdown
---
type: meta
title: "Lint Report YYYY-MM-DD"
created: YYYY-MM-DD
updated: YYYY-MM-DD
tags:
  - meta
  - lint
status: developing
---

# Lint Report: YYYY-MM-DD

## Summary
- Pages scanned: N
- Issues found: N
- Auto-fixed: N
- Needs review: N

## Orphan Pages
- [[Page Name]]: no inbound links. Suggest: link from [[Related Page]] or delete.

## Dead Links
- [[Missing Page]]: referenced in [[Source Page]] but does not exist. Suggest: create stub or remove link.

## Missing Pages
- "concept name": mentioned in [[Page A]], [[Page B]], [[Page C]]. Suggest: create a concept page.

## Frontmatter Gaps
- [[Page Name]]: missing fields: status, tags

## Stale Claims
- [[Page Name]]: claim "X" may conflict with newer source [[Newer Source]].

## Cross-Reference Gaps
- [[Entity Name]] mentioned in [[Page A]] without a wikilink.
```

---

## Naming Conventions

Enforce these during lint:

| Element | Convention | Example |
|---------|-----------|---------|
| Filenames | Title Case with spaces | `Machine Learning.md` |
| Folders | lowercase with dashes | `wiki/data-models/` |
| Tags | lowercase, hierarchical | `#domain/architecture` |
| Wikilinks | match filename exactly | `[[Machine Learning]]` |

Filenames must be unique across the vault. Wikilinks work without paths only if
filenames are unique.

Exception: folder-local `_index.md` files are allowed to repeat. Link those with
folder-qualified wikilinks such as `[[concepts/_index|Concepts Index]]`,
`[[entities/_index|Entities Index]]`, and `[[domains/_index|Domains Index]]`.

---

## Writing Style Check

During lint, flag pages that violate the style guide:

- Not declarative present tense ("X basically does Y" instead of "X does Y")
- Missing source citations where claims are made
- Uncertainty not flagged with `> [!gap]`
- Contradictions not flagged with `> [!contradiction]`

Do not treat the absence of `[[CLAUDE]]` or project `AGENTS.md` links as a
missing citation for operational notes.

---

## Dataview Dashboard

Create or update `{WikiPath}/wiki/meta/dashboard.md` with these queries when
`WikiMode` is `managed`:

````markdown
---
type: meta
title: "Dashboard"
updated: YYYY-MM-DD
---
# Wiki Dashboard

## Recent Activity
```dataview
TABLE type, status, updated FROM "wiki" SORT updated DESC LIMIT 15
```

## Seed Pages (Need Development)
```dataview
LIST FROM "wiki" WHERE status = "seed" SORT updated ASC
```

## Entities Missing Sources
```dataview
LIST FROM "wiki/entities" WHERE !sources OR length(sources) = 0
```

## Open Questions
```dataview
LIST FROM "wiki/questions" WHERE answer_quality = "draft" SORT created DESC
```
````

---

## Canvas Map

Create or update `{WikiPath}/wiki/meta/overview.canvas` for a visual domain map
when `WikiMode` is `managed`:

```json
{
  "nodes": [
    {
      "id": "1",
      "type": "file",
      "file": "wiki/overview.md",
      "x": 0, "y": 0,
      "width": 300, "height": 140,
      "color": "1"
    }
  ],
  "edges": []
}
```

Add one node per domain page. Connect domains that have significant cross-references. Colors map to the CSS scheme: 1=blue, 2=purple, 3=yellow, 4=orange, 5=green, 6=red.

---

## Before Auto-Fixing

In `managed` mode, always show the lint report first. Ask: "Should I fix these
automatically, or do you want to review each one?"

In `reference` mode, never apply fixes. Summarize the issues and tell the user
that the current project has read-only wiki access.

Safe to auto-fix:
- Adding missing frontmatter fields with placeholder values
- Creating stub pages for missing entities
- Adding wikilinks for unlinked mentions

Needs review before fixing:
- Deleting orphan pages (they might be intentionally isolated)
- Resolving contradictions (requires human judgment)
- Merging duplicate pages
