---
description: Run an autonomous research loop on a topic. Searches the web, synthesizes findings, and files everything into the wiki as structured pages.
---

Read the `autoresearch` skill. Then run the research loop.

Before starting, resolve whether the current project is bound to a wiki via
`WikiMode` and `WikiPath`, or whether the current directory is itself the vault.

Usage:
- `/autoresearch [topic]` — research a specific topic
- `/autoresearch` — ask "What topic should I research?"

Before starting, read `skills/autoresearch/references/program.md` to load the research constraints and objectives.

If no bound wiki or local vault is configured yet, say: "No wiki binding or local vault found. Run /wiki first or configure WikiPath."

After research is complete, update wiki/index.md, wiki/log.md, and wiki/hot.md.

Report how many pages were created and what the key findings are.
