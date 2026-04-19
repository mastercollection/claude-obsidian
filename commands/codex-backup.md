---
description: Hand off wiki backup work from Claude Code to the local Codex CLI and return Codex stdout with minimal transformation.
---

Treat everything after `/codex-backup` as the user request for Codex.

Workflow:

1. Resolve whether the current project is bound to a wiki via `WikiMode` and
   `WikiPath`, or whether the current directory is itself the vault.
2. If no bound wiki or local vault is configured, stop and say:
   "No wiki binding or local vault found. Run /wiki first or configure WikiPath."
3. Verify that `codex` is available. Prefer running from `pwsh`, not Windows
   PowerShell 5.
4. Run an inline PowerShell script from the project root. Do not rely on any
   plugin-relative file path such as `.\bin\...`.
5. The script must:
   - read `AGENTS.md` first, then `CLAUDE.md`
   - ignore fenced code blocks when scanning for `WikiMode:` and `WikiPath:`
   - resolve the target wiki root
   - stop if `WikiMode` is `reference`
   - call `codex exec --skip-git-repo-check --ephemeral --full-auto`
   - pass `--cd` as the current project root
   - add `--add-dir <WikiPath>` when the wiki repo lives outside the project root
   - send the Codex prompt over stdin instead of as a positional CLI argument
6. Build the Codex prompt so it says:
   - this is an explicit Claude Code handoff for wiki backup
   - read the project `AGENTS.md` and `CLAUDE.md` first
   - use the `wiki-backup` skill against the resolved wiki repo only
   - never back up the project repo when it points at a separate `WikiPath`
   - respond in Korean
   - use the text after `/codex-backup` as the user request
7. Return Codex stdout almost verbatim.
8. If the command fails, show stderr and the exact command that was attempted.

Examples:
- `/codex-backup backup wiki`
- `/codex-backup inspect wiki repo status`
- `/codex-backup push wiki`

Execution pattern:

```powershell
$prompt | codex exec --skip-git-repo-check --ephemeral --full-auto --cd $projectRoot --add-dir $wikiPath
```

Omit `--add-dir` when the resolved wiki root is the same as the project root.
