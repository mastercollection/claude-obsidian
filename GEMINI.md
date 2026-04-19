# claude-obsidian: Gemini CLI Instructions

This file is the Gemini-facing wrapper for the canonical repo instructions in
`CLAUDE.md`.

Read `CLAUDE.md` first. Use this file for Gemini-specific bootstrap only.

If the current project declares `WikiMode` and `WikiPath`, resolve that binding
first, read `{WikiPath}/CLAUDE.md`, then read `{WikiPath}/wiki/hot.md`. If no
binding exists but the current directory is the vault, use local `CLAUDE.md` and
`wiki/hot.md`.

## Skills Discovery

Skills live in `skills/<name>/SKILL.md`. To make them available to Gemini CLI:

```bash
ln -s "$(pwd)/skills" ~/.gemini/skills/claude-obsidian
```

Or run the bundled installer:

```bash
bash bin/setup-multi-agent.sh
```

## Skills

| Skill | What it does |
|---|---|
| `wiki` | Scaffolds a new vault, manages hot cache, routes to sub-skills |
| `wiki-ingest` | Reads sources (files, URLs, images) and creates 8-15 wiki pages each |
| `wiki-query` | Answers questions from the wiki with three depth modes |
| `wiki-lint` | Health checks: orphans, dead links, stale claims, gaps |
| `save` | Files the current conversation as a wiki note |
| `autoresearch` | Autonomous research loop: search → fetch → synthesize → file |
| `canvas` | Creates and edits Obsidian canvas (.canvas) files |
| `defuddle` | Cleans web pages before ingest (saves 40-60% tokens) |
| `obsidian-markdown` | Obsidian Flavored Markdown syntax reference |
| `obsidian-bases` | Obsidian Bases (.base files): native database views |

## Trigger Phrases (Examples)

- "set up wiki" → `wiki`
- "ingest this article" → `wiki-ingest`
- "ingest https://example.com/article" → `wiki-ingest` (URL mode)
- "what do you know about X" → `wiki-query`
- "lint the wiki" → `wiki-lint`
- "save this conversation" → `save`
- "research [topic]" → `autoresearch`

## Vault Conventions

- `<vault-root>/.raw/`: source documents, immutable (never modify)
- `<vault-root>/wiki/`: agent-generated knowledge (you own this)
- `<vault-root>/wiki/hot.md`: recent context cache (~500 tokens), read first at session start
- `<vault-root>/wiki/index.md`: master catalog
- `<vault-root>/.raw/.manifest.json`: delta tracking for ingest
- `allowed-tools`: vendor-specific skill hints retained intentionally; do not treat them as the portable core of the Agent Skills format

## Bootstrap

On first session:
1. Read `CLAUDE.md` for canonical repo behavior
2. Read this file for Gemini-specific bootstrap
3. If a binding exists, silently read the bound wiki hot cache. Otherwise, if
   the current directory is the vault, silently read local `wiki/hot.md`
4. Gemini does not share Claude Code's repo-local hook system; follow the skill
   instructions to keep the resolved wiki's `wiki/index.md`, `wiki/log.md`, and
   `wiki/hot.md` in sync during wiki workflows
5. Wait for user to type `/wiki` or `ingest` or `query`

## Project Links

- Plugin: https://github.com/AgriciDaniel/claude-obsidian
- Pattern: https://gist.github.com/karpathy/442a6bf555914893e9891c11519de94f
