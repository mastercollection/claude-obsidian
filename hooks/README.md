# claude-obsidian Hooks

Plugin hooks for the claude-obsidian wiki vault. All hooks are defined in
`hooks.json`.

These hooks are a **Claude-only convenience adapter**. They are useful when the
current working directory is itself the wiki vault, and they can optionally
restore a bound wiki hot cache at session start. They are **not** the correctness
mechanism for project-bound wiki workflows. In bound-project mode, the skills are
responsible for updating the target wiki's `index.md`, `log.md`, and `hot.md`.

## Events

| Event | Type | Purpose |
|---|---|---|
| `SessionStart` | command + prompt | Command hook restores local `wiki/hot.md` when the current directory is the vault. Prompt hook may additionally direct Claude to read a bound `WikiPath` cache when the project declares one. Matcher: `startup\|resume`. |
| `PostCompact` | prompt | Re-loads the same hot cache after context compaction. Hook-injected context does NOT survive compaction (only `CLAUDE.md` does), so this hook restores the cache mid-session. |
| `PostToolUse` | command | Auto-commits local `wiki/` and `.raw/` changes after Write or Edit tool calls, but only when the current directory is the vault and no `WikiPath` binding is declared. |
| `Stop` | command | Reminds Claude to refresh local `wiki/hot.md` only in local-vault mode. Bound-project mode is intentionally skipped. |

## Known Issue: Plugin Hooks STDOUT Bug

`anthropics/claude-code#10875` documents that **plugin hook STDOUT may not be captured** by Claude Code, while identical inline hooks in `settings.json` work correctly.

**Impact**: If this bug is active in your Claude Code version, the prompt-type
SessionStart and PostCompact hooks may not inject context as expected.

**Workaround**: The command-type SessionStart hook is the canonical safety check.
It reads local `wiki/hot.md` and still relies on STDOUT capture for context
injection, so test against this issue if hot cache restoration fails. As a
fallback, copy the hook config from `hooks.json` into your user-level
`~/.claude/settings.json` instead of relying on plugin hooks.

**Test for the bug**: After installing the plugin, open a fresh Claude Code session in a directory containing a populated `wiki/hot.md`. Ask Claude "what's in the hot cache?". If Claude has no idea, the STDOUT bug is active in your version.

## Non-Vault Sessions

The SessionStart command hook always exits 0, even when no wiki binding or local
vault is present. This keeps the plugin safe to install globally without
breaking non-vault Claude Code sessions.
