---
name: save
description: >
  Save the current conversation, answer, or insight into the Obsidian wiki vault as a
  structured note. Analyzes the chat, determines the right note type, creates frontmatter,
  files it in the correct wiki folder, and updates index, log, context state,
  and the generated hot cache.
  Triggers on: "save this", "save that answer", "/save", "file this",
  "save to wiki", "save this session", "file this conversation", "keep this",
  "save this analysis", "add this to the wiki".
allowed-tools: Read Write Edit Glob Grep
---

# save: File Conversations Into the Wiki

Good answers and insights shouldn't disappear into chat history. This skill takes what was just discussed and files it as a permanent wiki page.

The wiki compounds. Save often.

---

## Project Binding

Before saving:

1. Read `../wiki/references/project-binding.md`.
2. Read `../wiki/references/context-state.md`.
3. Resolve the active wiki root.
4. If `WikiMode` is `reference`, stop. `/save` writes to the wiki and is only
   allowed in `managed` mode or local-vault mode.
5. Treat every `wiki/...` path below as `{WikiPath}/wiki/...` when a project
   binding exists.

## Note Type Decision

Determine the best type from the conversation content:

| Type | Folder | Use when |
|------|--------|---------|
| synthesis | `{WikiPath}/wiki/questions/` | Multi-step analysis, comparison, or answer to a specific question |
| concept | `{WikiPath}/wiki/concepts/` | Explaining or defining an idea, pattern, or framework |
| source | `{WikiPath}/wiki/sources/` | Summary of external material discussed in the session |
| decision | `{WikiPath}/wiki/meta/` | Architectural, project, or strategic decision that was made |
| session | `{WikiPath}/wiki/meta/` | Full session summary: captures everything discussed |

If the user specifies a type, use that. If not, pick the best fit based on the content. When in doubt, use `synthesis`.

---

## Save Workflow

1. **Scan** the current conversation. Identify the most valuable content to preserve.
2. **Ask** (if not already named): "What should I call this note?" Keep the name short and descriptive.
3. **Determine** note type using the table above.
4. **Extract** all relevant content from the conversation. Rewrite it in declarative present tense (not "the user asked" but the actual content itself).
5. **Create** the note in the correct folder with full frontmatter.
6. **Collect links**: identify any wiki pages mentioned in the conversation.
   Add them to `related` in frontmatter only if the page already exists or is a
   real concept/entity page that belongs in this wiki.
7. **Update** `{WikiPath}/wiki/index.md`. Add the new entry at the top of the relevant section.
8. **Append** to `{WikiPath}/wiki/log.md`. New entry at the TOP:
   ```
   ## [YYYY-MM-DD] save | Note Title
   - Type: [note type]
   - Location: `{WikiPath}/wiki/[folder]/Note Title.md`
   - From: conversation on [brief topic description]
   ```
9. **Upsert** `{WikiPath}/wiki/meta/context-state.json` using the saved note as
   the stable identity. Store only compact metadata:
   - `id`: stable id such as `save:[slug]`
   - `source`: `save`
   - `title` and `link`
   - `summary`: one or two short lines
   - `status`: default `active`
   - `priority`: default `1`
   - `session_key`: thread/session identifier if available, otherwise `manual`
   - `created_at`, `updated_at`
   - `expires_at`: default 3 days after `updated_at`
   - `tags`: compact topical tags
10. **Regenerate** `{WikiPath}/wiki/hot.md` from `context-state.json`. Never
    update `hot.md` directly first.
11. If the context-state upsert fails, stop and report a partial failure. Do not
    rewrite `hot.md`.
12. **Confirm**: "Saved as [[Note Title]] in `{WikiPath}/wiki/[folder]/`."

---

## Frontmatter Template

```yaml
---
type: <synthesis|concept|source|decision|session>
title: "Note Title"
created: YYYY-MM-DD
updated: YYYY-MM-DD
tags:
  - <relevant-tag>
status: developing
related:
  - "[[Any Wiki Page Mentioned]]"
sources:
  - "[[.raw/source-if-applicable.md]]"
---
```

If `related` or `sources` would be empty, omit the field entirely. Do not write
empty inline arrays like `sources: []`.

## Optional Frontmatter Fields

If `related` or `sources` would be empty, omit the field entirely. Do not write
empty arrays or placeholder values.

## Infrastructure Terms

Do not create wikilinks for infrastructure or configuration terms such as
`Wiki Binding`, `WikiMode`, `WikiPath`, `AGENTS.md`, `CLAUDE.md`, MCP server
names, or literal file paths unless this wiki intentionally maintains a real
page for that term. Use backticks instead.

## Operational Notes

Do not auto-add `[[CLAUDE]]` or project `AGENTS.md` to `related` only to
justify an operational note. Add those links only if the user explicitly wants
a real wiki page relationship.

## Index Update Discipline

When updating `wiki/index.md`, add the note to an existing section only. Do not
create a duplicate section heading.

When updating a folder-local `_index.md`:

- if notes exist in that folder, list the actual notes
- if no notes exist, keep a single explicit empty-state line
- do not leave scaffold instructions or generic placeholder text

For `question` type, add:
```yaml
question: "The original query as asked."
answer_quality: solid
```

For `decision` type, add:
```yaml
decision_date: YYYY-MM-DD
status: active
```

---

## Writing Style

- Declarative, present tense. Write the knowledge, not the conversation.
- Not: "The user asked about X and Claude explained..."
- Yes: "X works by doing Y. The key insight is Z."
- Include all relevant context. Future sessions should be able to read this page cold.
- Link only concepts, entities, or wiki pages that already exist or clearly
  belong as pages in this wiki.
- Cite sources where applicable: `(Source: [[Page]])`.

---

## What to Save vs. Skip

Save:
- Non-obvious insights or synthesis
- Decisions with rationale
- Analyses that took significant effort
- Comparisons that are likely to be referenced again
- Research findings

Skip:
- Mechanical Q&A (lookup questions with obvious answers)
- Setup steps already documented elsewhere
- Temporary debugging sessions with no lasting insight
- Anything already in the wiki

If it's already in the wiki, update the existing page instead of creating a duplicate.
