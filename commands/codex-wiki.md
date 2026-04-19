---
description: Hand off wiki work from Claude Code to the local Codex CLI and return Codex stdout with minimal transformation.
---

Treat everything after `/codex-wiki` as the user request for Codex.

Workflow:

1. Resolve whether the current project is bound to a wiki via `WikiMode` and
   `WikiPath`, or whether the current directory is itself the vault.
2. If no bound wiki or local vault is configured, stop and say:
   "No wiki binding or local vault found. Run /wiki first or configure WikiPath."
3. Verify that `codex` is available. Prefer `cmd /c codex ...` for execution.
4. Run an inline PowerShell script from the project root. Do not rely on any
   plugin-relative file path such as `.\bin\...`.
5. The script must:
   - read `AGENTS.md` first, then `CLAUDE.md`
   - ignore fenced code blocks when scanning for `WikiMode:` and `WikiPath:`
   - use `WikiPath` if present
   - otherwise use the current directory only if both `wiki/` and `.raw/` exist
   - fail if no wiki root is configured
   - call `cmd /c codex exec --skip-git-repo-check --ephemeral --full-auto`
   - pass `--cd` as the current project root
   - add `--add-dir <WikiPath>` when the wiki lives outside the project root
6. Build the Codex prompt so it says:
   - this is an explicit Claude Code handoff for wiki work
   - read the project `AGENTS.md` and `CLAUDE.md` first
   - resolve the wiki root and use the wiki-related skills as needed
   - respond in Korean
   - use the text after `/codex-wiki` as the user request
7. Return Codex stdout almost verbatim.
8. If the command fails, show stderr and the exact command that was attempted.

Examples:
- `/codex-wiki ingest .raw/article.md`
- `/codex-wiki query: what do you know about MCP setup?`
- `/codex-wiki lint the wiki`
