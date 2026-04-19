---
name: wiki-ingest
description: "Ingest sources into the Obsidian wiki vault. Reads a source, extracts entities and concepts, creates or updates wiki pages, cross-references, and logs the operation. Supports files, URLs, and batch mode. Triggers on: ingest, process this source, add this to the wiki, read and file this, batch ingest, ingest all of these, ingest this url."
allowed-tools: Read Write Edit Glob Grep Bash WebFetch
---

# wiki-ingest: Source Ingestion

Read the source. Write the wiki. Cross-reference everything. A single source typically touches 8-15 wiki pages.

**Syntax standard**: Write all Obsidian Markdown using proper Obsidian Flavored Markdown. Wikilinks as `[[Note Name]]`, callouts as `> [!type] Title`, embeds as `![[file]]`, properties as YAML frontmatter. If the kepano/obsidian-skills plugin is installed, prefer its canonical obsidian-markdown skill for Obsidian syntax reference. Otherwise, follow the guidance in this skill.

---

## Project Binding

Before any ingest work:

1. Read `../wiki/references/project-binding.md`.
2. Resolve the active wiki root.
3. If `WikiMode` is `reference`, stop. Ingest writes to the wiki and is only
   allowed in `managed` mode or local-vault mode.
4. Treat every path below as relative to the resolved wiki root, not the current
   project directory.

## Delta Tracking

Before ingesting any file, check `{WikiPath}/.raw/.manifest.json` to avoid
re-processing unchanged sources.

```bash
# Check if manifest exists
[ -f "{WikiPath}/.raw/.manifest.json" ] && echo "exists" || echo "no manifest yet"
```

**Manifest format** (create if missing):
```json
{
  "sources": {
    "{WikiPath}/.raw/articles/article-slug-2026-04-08.md": {
      "hash": "abc123",
      "ingested_at": "2026-04-08",
      "pages_created": ["wiki/sources/article-slug.md", "wiki/entities/Person.md"],
      "pages_updated": ["wiki/index.md"]
    }
  }
}
```

**Before ingesting a file:**
1. Compute a hash: `md5sum [file] | cut -d' ' -f1` (or `sha256sum` on Linux).
2. Check if the path exists in `.manifest.json` with the same hash.
3. If hash matches, skip. Report: "Already ingested (unchanged). Use `force` to re-ingest."
4. If missing or hash differs, proceed with ingest.

**After ingesting a file:**
1. Record `{hash, ingested_at, pages_created, pages_updated}` in `.manifest.json`.
2. Write the updated manifest back.

Skip delta checking if the user says "force ingest" or "re-ingest".

---

## URL Ingestion

Trigger: user passes a URL starting with `https://`.

Steps:

1. **Fetch** the page using WebFetch.
2. **Clean** (optional): if `defuddle` is available (`which defuddle 2>/dev/null`), run `defuddle [url]` to strip ads, nav, and clutter. Typically saves 40-60% tokens. Fall back to raw WebFetch output if not installed.
3. **Derive slug** from the URL path (last segment, lowercased, spaces→hyphens, strip query strings).
4. **Save** to `{WikiPath}/.raw/articles/[slug]-[YYYY-MM-DD].md` with a frontmatter header:
   ```markdown
   ---
   source_url: [url]
   fetched: [YYYY-MM-DD]
   ---
   ```
5. Proceed with **Single Source Ingest** starting at step 2 (file is now in
   `{WikiPath}/.raw/`).

---

## Image / Vision Ingestion

Trigger: user passes an image file path (`.png`, `.jpg`, `.jpeg`, `.gif`, `.webp`, `.svg`, `.avif`).

Steps:

1. **Read** the image file using the Read tool. Claude can process images natively.
2. **Describe** the image contents: extract all text (OCR), identify key concepts, entities, diagrams, and data visible in the image.
3. **Save** the description to `{WikiPath}/.raw/images/[slug]-[YYYY-MM-DD].md`:
   ```markdown
   ---
   source_type: image
   original_file: [original path]
   fetched: YYYY-MM-DD
   ---
   # Image: [slug]

   [Full description of image contents, transcribed text, entities visible, etc.]
   ```
4. Copy the image to `{WikiPath}/_attachments/images/[slug].[ext]` if it's not
   already in the vault.
5. Proceed with **Single Source Ingest** on the saved description file.

Use cases: whiteboard photos, screenshots, diagrams, infographics, document scans.

---

## Single Source Ingest

Trigger: user drops a file into `.raw/` or pastes content.

Steps:

1. **Read** the source completely. Do not skim.
2. **Discuss** key takeaways with the user. Ask: "What should I emphasize? How granular?" Skip this if the user says "just ingest it."
3. **Create** source summary in `{WikiPath}/wiki/sources/`. Use the source
   frontmatter schema from `references/frontmatter.md`.
4. **Create or update** entity pages for every person, org, product, and repo mentioned. One page per entity.
5. **Create or update** concept pages for significant ideas and frameworks.
6. **Update** relevant domain page(s) and their `_index.md` sub-indexes.
7. **Update** `{WikiPath}/wiki/overview.md` if the big picture changed.
8. **Update** `{WikiPath}/wiki/index.md`. Add entries for all new pages.
9. **Update** `{WikiPath}/wiki/hot.md` with this ingest's context.
10. **Append** to `{WikiPath}/wiki/log.md` (new entries at the TOP):
    ```markdown
    ## [YYYY-MM-DD] ingest | Source Title
    - Source: `{WikiPath}/.raw/articles/filename.md`
    - Summary: [[Source Title]]
    - Pages created: [[Page 1]], [[Page 2]]
    - Pages updated: [[Page 3]], [[Page 4]]
    - Key insight: One sentence on what is new.
    ```
11. **Check for contradictions.** If new info conflicts with existing pages, add `> [!contradiction]` callouts on both pages.

---

## Optional Frontmatter Fields

If `related` or `sources` would be empty on a page created or updated during
ingest, omit the field entirely. Do not write empty arrays or placeholder
values.

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

When updating `wiki/index.md`, add notes to existing sections only. Do not
create duplicate section headings.

When updating a folder-local `_index.md`:

- if notes exist in that folder, list the actual notes
- if no notes exist, keep a single explicit empty-state line
- do not leave scaffold instructions or generic placeholder text

---

## Batch Ingest

Trigger: user drops multiple files or says "ingest all of these."

Steps:

1. List all files to process. Confirm with user before starting.
2. Process each source following the single ingest flow. Defer cross-referencing between sources until step 3.
3. After all sources: do a cross-reference pass. Look for connections between the newly ingested sources.
4. Update `{WikiPath}/wiki/index.md`, `hot.md`, and `log.md` once at the end
   (not per-source).
5. Report: "Processed N sources. Created X pages, updated Y pages. Here are the key connections I found."

Batch ingest is less interactive. For 30+ sources, expect significant processing time. Check in with the user after every 10 sources.

---

## Context Window Discipline

Token budget matters. Follow these rules during ingest:

- Read `{WikiPath}/wiki/hot.md` first. If it contains the relevant context,
  don't re-read full pages.
- Read `{WikiPath}/wiki/index.md` to find existing pages before creating new ones.
- Read only 3-5 existing pages per ingest. If you need 10+, you are reading too broadly.
- Use PATCH for surgical edits. Never re-read an entire file just to update one field.
- Keep wiki pages short. 100-300 lines max. If a page grows beyond 300 lines, split it.
- Use search (`/search/simple/`) to find specific content without reading full pages.

---

## Contradictions

> [!note] Custom callout dependency
> The `[!contradiction]` callout type used below is a **custom callout** defined in `.obsidian/snippets/vault-colors.css` (auto-installed by `/wiki` scaffold). It renders with reddish-brown styling and an alert-triangle icon when the snippet is enabled. If the snippet is missing, Obsidian falls back to default callout styling, so the page still works without the visual flourish. See [[skills/wiki/references/css-snippets.md]] for the four custom callouts (`contradiction`, `gap`, `key-insight`, `stale`).

When new info contradicts an existing wiki page:

On the existing page, add:
```markdown
> [!contradiction] Conflict with [[New Source]]
> [[Existing Page]] claims X. [[New Source]] says Y.
> Needs resolution. Check dates, context, and primary sources.
```

On the new source summary, reference it:
```markdown
> [!contradiction] Contradicts [[Existing Page]]
> This source says Y, but existing wiki says X. See [[Existing Page]] for details.
```

Do not silently overwrite old claims. Flag and let the user decide.

---

## What Not to Do

- Do not modify anything in `{WikiPath}/.raw/`. These are immutable source
  documents.
- Do not create duplicate pages. Always check the index and search before creating.
- Do not skip the log entry. Every ingest must be recorded.
- Do not skip the hot cache update. It is what keeps future sessions fast.
- Do not create `wiki/` or `.raw/` in the current project when the project is
  bound to another `WikiPath`.
