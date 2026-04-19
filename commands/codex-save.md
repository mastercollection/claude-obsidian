---
description: Hand off wiki save work from Claude Code to the local Codex CLI and return Codex stdout with minimal transformation.
---

Treat everything after `/codex-save` as the user request for Codex.

Workflow:

1. Resolve whether the current project is bound to a wiki via `WikiMode` and
   `WikiPath`, or whether the current directory is itself the vault.
2. If no bound wiki or local vault is configured, stop and say:
   "No wiki binding or local vault found. Run /wiki first or configure WikiPath."
3. Run this PowerShell command from the project root:

```powershell
pwsh -File .\bin\invoke-codex-command.ps1 -Mode save -Prompt "<user text after /codex-save>"
```

4. Return Codex stdout almost verbatim.
5. If the command fails, show stderr and the exact command that was attempted.

Examples:
- `/codex-save`
- `/codex-save architecture notes`
- `/codex-save decision ADR for wiki backup`
