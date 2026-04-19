# claude-obsidian — Claude + Obsidian Wiki Vault

This folder is both a Claude Code plugin and an Obsidian vault. It is also the
canonical instruction source for the repo's other host adapters (`AGENTS.md`,
`GEMINI.md`, Cursor/Windsurf rules).

**Plugin name:** `claude-obsidian`
**Skills:** `/wiki`, `/wiki-ingest`, `/wiki-query`, `/wiki-lint`
**Vault path:** This directory (open in Obsidian directly)

## What This Vault Is For

This vault demonstrates the LLM Wiki pattern — a persistent, compounding knowledge base for Claude + Obsidian. Drop any source, ask any question, and the wiki grows richer with every session.

## Host Adapters

- `CLAUDE.md`: canonical repo instructions and the Claude Code entrypoint
- `AGENTS.md`: Codex/AGENTS-compatible wrapper that points back here
- `GEMINI.md`: Gemini wrapper that points back here
- `hooks/hooks.json`: Claude-only lifecycle adapter for hot cache restore and auto-commit

If another host-specific bootstrap file disagrees with this file on repo behavior,
follow this file for the canonical wiki workflow and treat the bootstrap file as
host-specific glue.

## Vault Structure

```
.raw/           source documents — immutable, Claude reads but never modifies
wiki/           Claude-generated knowledge base
_templates/     Obsidian Templater templates
_attachments/   images and PDFs referenced by wiki pages
```

## How to Use

Drop a source file into `.raw/`, then tell Claude: "ingest [filename]".

Ask any question. Claude reads the index first, then drills into relevant pages.

Run `/wiki` to scaffold a new vault or check setup status.

Run "lint the wiki" every 10-15 ingests to catch orphans and gaps.

Claude Code restores `wiki/hot.md` through `hooks/hooks.json`. Other hosts do not
share Claude's repo-local hook system, so their wrappers should read `wiki/hot.md`
at session start and follow the skill instructions to update `wiki/index.md`,
`wiki/log.md`, and `wiki/hot.md` during wiki workflows.

## Cross-Project Access

To reference this wiki from another Claude Code project, add to that project's CLAUDE.md:

```markdown
## Wiki Knowledge Base
Path: /path/to/this/vault

When you need context not already in this project:
1. Read wiki/hot.md first (recent context, ~500 words)
2. If not enough, read wiki/index.md
3. If you need domain specifics, read wiki/<domain>/_index.md
4. Only then read individual wiki pages

Do NOT read the wiki for general coding questions or things already in this project.
```

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
