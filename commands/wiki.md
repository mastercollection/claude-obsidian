---
description: Bootstrap or check the claude-obsidian wiki vault. Reads the wiki skill and runs setup workflow.
---

Read the `wiki` skill. Then run the setup workflow:

1. Read `skills/wiki/references/project-binding.md` first.
2. Resolve whether this project is bound to an external wiki via `WikiMode` and `WikiPath`, or whether the current directory is itself the vault.
3. Check if Obsidian is installed. If not, offer to install it (see `skills/wiki/references/plugins.md`).
4. Check if the MCP server is configured for the current host. Use `claude mcp list` in Claude Code or `codex mcp list` in Codex. If not, ask if the user wants to set it up.
5. Ask ONE question: "What is this vault for?"

Then build the entire wiki structure based on the answer. Don't ask more questions. Scaffold it, show what was created, and ask: "Want to adjust anything before we start?"

If the project is already bound to a `WikiPath`, do not create a new local `wiki/`
directory in the current project.

- If `WikiMode` is `managed`, inspect or initialize the bound wiki instead.
- If `WikiMode` is `reference`, inspect only and explain that scaffolding requires
  `managed` mode or direct access to the wiki repo.

Examples of what the user might say:
- "Map the architecture of github.com/org/repo"
- "Build a sitemap and content analysis for example.com"
- "Track my SaaS business — product, customers, metrics, roadmap"
- "Research project on [topic] — papers, concepts, open questions"
- "Personal second brain — health, goals, learning, projects"
- "Organize my YouTube channel — transcripts, topics, tools mentioned"
- "Executive assistant brain — meetings, tasks, business context"

If the vault is already set up, skip to checking what has been ingested recently and offering to continue where things left off.
