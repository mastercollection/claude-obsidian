# claude-obsidian — Claude + Obsidian Wiki Vault

This folder is both a Claude Code plugin and an Obsidian vault. It is also the
canonical instruction source for the repo's other host adapters (`AGENTS.md`,
`GEMINI.md`, Cursor/Windsurf rules).

**Plugin name:** `claude-obsidian`
**Skills:** `/wiki`, `/wiki-ingest`, `/wiki-query`, `/wiki-lint`
**Vault path:** This directory (open in Obsidian directly)

## What This Vault Is For

This vault demonstrates the LLM Wiki pattern — a persistent, compounding knowledge base for Claude + Obsidian. Drop any source, ask any question, and the wiki grows richer with every session.

This repo now supports two operating modes:

- **Local vault mode**: the current directory itself contains `wiki/` and `.raw/`
- **Project-bound mode**: another project declares `WikiMode` and `WikiPath`,
  and the skills operate on that bound wiki root instead of the current repo

## Host Adapters

- `CLAUDE.md`: canonical repo instructions and the Claude Code entrypoint
- `AGENTS.md`: Codex/AGENTS-compatible wrapper that points back here
- `GEMINI.md`: Gemini wrapper that points back here
- `hooks/hooks.json`: Claude-only lifecycle adapter for local-vault hot cache restore and optional local-vault auto-commit

If another host-specific bootstrap file disagrees with this file on repo
behavior, follow this file for the canonical wiki workflow and treat the
bootstrap file as host-specific glue.

## Vault Structure

```
.raw/           source documents — immutable, Claude reads but never modifies
wiki/           Claude-generated knowledge base
_templates/     Obsidian Templater templates
_attachments/   images and PDFs referenced by wiki pages
```

## How to Use

If you are working inside the wiki repo itself, drop a source file into `.raw/`,
then tell Claude: "ingest [filename]".

If you are working inside a separate project repo that declares `WikiMode` and
`WikiPath`, Claude should resolve that binding first and then read or write the
bound wiki instead of creating `wiki/` or `.raw/` inside the project repo.

Ask any question. Claude reads the index first, then drills into relevant pages.

Run `/wiki` to scaffold a new wiki repo, inspect setup status, or initialize the
bound wiki pointed to by `WikiPath`.

Run "lint the wiki" every 10-15 ingests to catch orphans and gaps.

Claude Code restores `wiki/hot.md` through `hooks/hooks.json` in local-vault
mode. Other hosts do not share Claude's repo-local hook system, and even Claude
should not rely on hooks for correctness in project-bound mode. The skill
workflows are responsible for updating `wiki/index.md`, `wiki/log.md`, and
`wiki/hot.md` in the resolved wiki root.

## Project Binding

To bind another project to a dedicated wiki, add this to that project's
`AGENTS.md` or `CLAUDE.md`:

```markdown
## Wiki Knowledge Base
WikiMode: managed
WikiPath: <ABSOLUTE_PATH_TO_WIKI>
```

Interpretation:

Examples:

- Windows: `C:\Wiki_A`
- macOS/Linux: `/Users/name/Wiki_A`

1. Read `{WikiPath}/CLAUDE.md` as the canonical wiki contract.
2. Read `{WikiPath}/wiki/hot.md` first for recent context.
3. If not enough, read `{WikiPath}/wiki/index.md`.
4. If you need domain specifics, read the relevant sub-index or page inside
   `{WikiPath}/wiki/`.

`WikiMode: reference` means read-only access. `WikiMode: managed` allows wiki
workflows to write back into the bound wiki.

Keep the git boundary clean:

- The project repo commits code only.
- The bound wiki repo stores `wiki/`, `.raw/`, `_attachments/`, and its own
  `CLAUDE.md`.
- Auto-commit is optional and local-vault-only by default. Bound wiki repos are
  manual commit unless the user opts in separately.

## Plugin Skills

| Skill | Trigger |
|-------|---------|
| `/wiki` | Setup, scaffold, route to sub-skills |
| `ingest [source]` | Single or batch source ingestion |
| `query: [question]` | Answer from wiki content |
| `lint the wiki` | Health check |
| `/save` | File the current conversation as a structured wiki note |
| `/autoresearch [topic]` | Autonomous research loop: search, fetch, synthesize, file |
| `/canvas` | Visual layer: add images, PDFs, notes to Obsidian canvas |

## MCP (Optional)

If you configured an MCP server, the active host can read and write vault notes
directly. `skills/wiki/references/mcp-setup.md` includes host-specific examples
for Claude Code (`claude mcp ...`) and Codex (`codex mcp ...`).

For project-bound local wikis, prefer direct filesystem access when `WikiPath`
points to a local folder on the same machine. MCP is optional transport, not the
default correctness path.
