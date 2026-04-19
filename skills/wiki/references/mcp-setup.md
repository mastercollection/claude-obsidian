# MCP Setup

MCP lets supported agents read and write vault notes directly without copy-paste.
This repo currently documents host-specific examples for:

- Claude Code: `claude mcp ...`
- Codex CLI / IDE: `codex mcp ...`

Four options are listed below, ordered from simplest to most featureful.

> [!tip] Recommendation
> If you have **Obsidian v1.12 or newer**, start with **Option D: Obsidian CLI**. It needs no MCP server, no plugins, and no TLS workarounds. It is also the most portable option across Claude Code, Codex, and other hosts. Use Options A or B only if you need persistent MCP integration or are on an older Obsidian version.

> [!note] Filesystem-first for local bindings
> If a project declares a local `WikiPath` such as
> `<ABSOLUTE_PATH_TO_WIKI>`, the default path is direct filesystem access
> against that folder. Example `WikiPath` values: `C:\Wiki_A` on Windows or
> `/Users/name/Wiki_A` on macOS/Linux. MCP is optional transport for host
> integration, not the primary correctness path for project-bound local wikis.

---

## Step 1: Install the Local REST API Plugin

You must do this in Obsidian (the agent cannot do it programmatically):

1. Obsidian > Settings > Community Plugins > Turn off Restricted Mode
2. Browse > Search "Local REST API" > Install > Enable
3. Settings > Local REST API > Copy the API key

The plugin runs on `https://127.0.0.1:27124` with a self-signed certificate.

Test it:
```bash
curl -sk -H "Authorization: Bearer <YOUR_KEY>" https://127.0.0.1:27124/
```

You should get a JSON response with vault info.

---

## Option A: mcp-obsidian (REST API based)

Uses MarkusPfundstein's mcp-obsidian. Requires the Local REST API plugin running.

**Claude Code**
```bash
claude mcp add-json obsidian-vault '{
  "type": "stdio",
  "command": "uvx",
  "args": ["mcp-obsidian"],
  "env": {
    "OBSIDIAN_API_KEY": "<YOUR_KEY>",
    "OBSIDIAN_HOST": "127.0.0.1",
    "OBSIDIAN_PORT": "27124",
    "NODE_TLS_REJECT_UNAUTHORIZED": "0"
  }
}' --scope user
```

**Codex**
```bash
codex mcp add \
  --env OBSIDIAN_API_KEY=<YOUR_KEY> \
  --env OBSIDIAN_HOST=127.0.0.1 \
  --env OBSIDIAN_PORT=27124 \
  --env NODE_TLS_REJECT_UNAUTHORIZED=0 \
  obsidian-vault -- uvx mcp-obsidian
```

> [!warning] Security
> `NODE_TLS_REJECT_UNAUTHORIZED: "0"` **disables TLS certificate verification process-wide** for the MCP server. It is required here because the Local REST API plugin uses a self-signed certificate. This is acceptable for `127.0.0.1` (localhost) connections only. Never use this setting for any non-loopback connection. If you are uncomfortable with the global TLS bypass, prefer **Option D (Obsidian CLI)** or **Option B (filesystem-based)** which avoid this entirely.

Capabilities: read notes, write notes, search, patch frontmatter fields, append under headings.

---

## Option B: MCPVault (filesystem based)

No Obsidian plugin needed. Reads the vault directory directly.

**Claude Code**
```bash
claude mcp add-json obsidian-vault '{
  "type": "stdio",
  "command": "npx",
  "args": ["-y", "@bitbonsai/mcpvault@latest", "/absolute/path/to/your/vault"]
}' --scope user
```

**Codex**
```bash
codex mcp add obsidian-vault -- npx -y @bitbonsai/mcpvault@latest /absolute/path/to/your/vault
```

Replace `/absolute/path/to/your/vault` with the actual vault path.

Tools available: `search_notes` (BM25), `read_note`, `create_note`, `update_note`, `get_frontmatter`, `update_frontmatter`, `list_all_tags`, `read_multiple_notes`.

---

## Option C: Direct REST API via curl

No MCP needed. Use curl in bash throughout the session. See `rest-api.md` for all commands.

---

## Option D: Obsidian CLI (recommended for v1.12+)

Obsidian shipped a native CLI in v1.12 (2026). It exposes vault operations directly to the terminal. No REST API plugin, no MCP server, no self-signed certs, no TLS workarounds. Claude, Codex, and other terminal agents can call it through their shell tools.

**Check if available:**
```bash
which obsidian-cli 2>/dev/null && obsidian-cli --version
# or, on flatpak:
flatpak run md.obsidian.Obsidian --cli --version
```

**Common operations:**
```bash
# List all notes in a folder
obsidian-cli list /path/to/vault wiki/

# Read a note
obsidian-cli read /path/to/vault wiki/index.md

# Create or update a note
obsidian-cli write /path/to/vault wiki/new-note.md < content.md

# Search notes by content
obsidian-cli search /path/to/vault "query term"
```

**Why prefer this**:
- No plugin install required (CLI is built into Obsidian)
- No MCP server process to manage
- No TLS certificate bypass needed
- Survives Obsidian restarts (no persistent connection)
- Works identically across desktop and headless environments

**When to use Options A/B/C instead**: If you need persistent semantic search, frontmatter patching, or are on Obsidian < v1.12.

The `kepano/obsidian-skills` repo includes an `obsidian-cli` skill that wraps these commands as reusable patterns. Install it alongside this plugin for first-class CLI support.

---

## Host Notes

- Claude Code examples use `--scope user` so the vault is available across all Claude Code projects, not just the one where you ran the command.
- Codex stores MCP configuration in its shared client config. `codex mcp add` writes a server entry that is reused by the CLI and IDE extension.
- If you maintain both Claude Code and Codex, keep the server name the same (`obsidian-vault`) so the skill text can stay host-agnostic.

---

## Verification

After setup:

**Claude Code**
```bash
claude mcp list               # confirm the server appears
claude mcp get obsidian-vault # confirm the path or URL is correct
```

**Codex**
```bash
codex mcp list
codex mcp get obsidian-vault --json
```

In a Claude Code session, type `/mcp` to check connection status. In Codex, ask the
agent to use the configured `obsidian-vault` MCP server.

Then test: "List all notes in my wiki folder."
