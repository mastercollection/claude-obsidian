# claude-obsidian: Codex / AGENTS Instructions

This file is the Codex-facing wrapper for the canonical repo instructions in
`CLAUDE.md`.

Read `CLAUDE.md` first. Use this file only for Codex-specific behavior:

1. Resolve wiki binding first. If the current project declares `WikiMode` and
   `WikiPath`, read `{WikiPath}/CLAUDE.md` first and then `{WikiPath}/wiki/hot.md`.
   If the hot cache looks stale or incomplete, read
   `{WikiPath}/wiki/meta/context-state.json`.
   Otherwise, if the current directory is itself the vault, read local
   `CLAUDE.md` and `wiki/hot.md`.
2. Codex does **not** consume this repo's Claude lifecycle hooks from
   `hooks/hooks.json`. Treat those hooks as Claude-only adapter behavior.
3. For wiki workflows (`ingest`, `query`, `lint`, `save`, `autoresearch`, `canvas`),
   follow the relevant skill instructions against the resolved wiki root so the
   same wiki artifacts are maintained: `wiki/index.md`,
   `wiki/meta/context-state.json`, `wiki/log.md`, and `wiki/hot.md`.
4. `allowed-tools` in `SKILL.md` frontmatter are intentionally retained as
   vendor-specific hints. They are not the portable core of the Agent Skills format.
5. If the current project is bound to another wiki, do not create or commit
   `wiki/` or `.raw/` inside the current project repo. Code repo commits stay
   separate from wiki repo commits.

## Project Binding

Use this minimal project-side declaration:

```md
## Wiki Knowledge Base
WikiMode: managed
WikiPath: <ABSOLUTE_PATH_TO_WIKI>
```

- `WikiMode: reference` = read-only wiki access
- `WikiMode: managed` = wiki workflows may write to `{WikiPath}`
- `WikiPath` points at the actual wiki repo root containing `wiki/`, `.raw/`,
  and the canonical `CLAUDE.md`
- Example (Windows): `C:\Wiki_A`
- Example (macOS/Linux): `/Users/name/Wiki_A`

## Skills Discovery

All skills live in `skills/<name>/SKILL.md`. Codex and other AGENTS-compatible
tools can auto-discover them when you symlink the directory:

```bash
# Codex CLI
ln -s "$(pwd)/skills" ~/.codex/skills/claude-obsidian

# OpenCode
ln -s "$(pwd)/skills" ~/.opencode/skills/claude-obsidian
```

Or run the bundled installer:

```bash
bash bin/setup-multi-agent.sh
```

## Available Skills

| Skill | Trigger phrases |
|---|---|
| `wiki` | `/wiki`, set up wiki, scaffold vault |
| `wiki-ingest` | ingest, ingest this url, ingest this image, batch ingest |
| `wiki-query` | query, what do you know about, query quick:, query deep: |
| `wiki-lint` | lint the wiki, health check, find orphans |
| `save` | /save, file this conversation |
| `autoresearch` | autoresearch, autonomous research loop |
| `canvas` | /canvas, add to canvas, create canvas |
| `wiki-backup` | backup wiki, commit wiki, push wiki, sync wiki |
| `defuddle` | clean this url, defuddle |
| `obsidian-markdown` | obsidian syntax, wikilink, callout |
| `obsidian-bases` | obsidian bases, .base file, dynamic table |

## Key Conventions

- **Vault root**: the resolved `WikiPath`, or the current directory if it already contains `wiki/` and `.raw/`
- **Hot cache**: `<vault-root>/wiki/hot.md` (read first for recent context)
- **Context state**: `<vault-root>/wiki/meta/context-state.json` (machine-owned recent-state source of truth)
- **Source documents**: `.raw/` (immutable: agents never modify these)
- **Generated knowledge**: `wiki/` (agent-owned, links to sources via wikilinks)
- **Manifest**: `.raw/.manifest.json` tracks ingested sources (delta tracking)

## Bootstrap

When the user opens this project for the first time:

1. Read `CLAUDE.md` for the canonical repo instructions
2. Read this file for Codex-specific adapter notes
3. Read `skills/wiki/SKILL.md` for the orchestration pattern
4. If a project binding exists, read the bound wiki's `CLAUDE.md` and
   `wiki/hot.md` silently to restore recent context. If the hot cache is stale
   or incomplete, read `wiki/meta/context-state.json`. Otherwise, if the current
   directory is the vault, read local `wiki/hot.md`.
5. If the user types `/wiki` or says "set up wiki", follow the wiki skill's scaffold workflow

## MCP

Codex uses `codex mcp ...`, not `claude mcp ...`.

- Check configuration: `codex mcp list`
- Inspect a server: `codex mcp get obsidian-vault --json`
- Setup details: `skills/wiki/references/mcp-setup.md`

For local `WikiPath` values on the same machine, filesystem access is the
default path. MCP is optional.

## Reference

- Plugin homepage: https://github.com/AgriciDaniel/claude-obsidian
- Pattern source: https://gist.github.com/karpathy/442a6bf555914893e9891c11519de94f
- Cross-reference: https://github.com/kepano/obsidian-skills (authoritative Obsidian-specific skills)
