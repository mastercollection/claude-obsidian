#!/usr/bin/env pwsh
# claude-obsidian vault setup script for PowerShell
# Run this ONCE before opening Obsidian for the first time.
# Usage: pwsh -File bin/setup-vault.ps1 [-VaultPath /path/to/vault]
# Default: uses the parent directory of this script (the vault root)

[CmdletBinding()]
param(
  [string]$VaultPath
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

$scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$defaultVault = Split-Path -Parent $scriptDir
$vault = [System.IO.Path]::GetFullPath($(if ($VaultPath) { $VaultPath } else { $defaultVault }))
$obsidian = Join-Path $vault ".obsidian"

Write-Host "Setting up claude-obsidian vault at: $vault"

# 1. Create directories
$directories = @(
  (Join-Path $obsidian "snippets"),
  (Join-Path $vault ".raw"),
  (Join-Path $vault "wiki\concepts"),
  (Join-Path $vault "wiki\entities"),
  (Join-Path $vault "wiki\sources"),
  (Join-Path $vault "wiki\meta"),
  (Join-Path $vault "_templates")
)

foreach ($dir in $directories) {
  New-Item -ItemType Directory -Path $dir -Force | Out-Null
}

# 2. Write graph.json
$graphJson = @'
{
  "collapse-filter": false,
  "search": "path:wiki",
  "showTags": false,
  "showAttachments": false,
  "hideUnresolved": true,
  "showOrphans": false,
  "collapse-color-groups": false,
  "colorGroups": [
    { "query": "path:wiki/entities",    "color": { "a": 1, "rgb": 12945088 } },
    { "query": "path:wiki/concepts",    "color": { "a": 1, "rgb": 5227007  } },
    { "query": "path:wiki/sources",     "color": { "a": 1, "rgb": 6986069  } },
    { "query": "path:wiki/meta",        "color": { "a": 1, "rgb": 5676246  } },
    { "query": "path:wiki",             "color": { "a": 1, "rgb": 5676246  } }
  ],
  "showArrow": true,
  "textFadeMultiplier": -1,
  "nodeSizeMultiplier": 1.8,
  "lineSizeMultiplier": 1.2,
  "centerStrength": 0.5,
  "repelStrength": 30,
  "linkStrength": 1.5,
  "linkDistance": 120,
  "scale": 1.0
}
'@
Set-Content -Path (Join-Path $obsidian "graph.json") -Value $graphJson

# 3. Write app.json (excluded files)
$appJson = @'
{
  "userIgnoreFilters": [
    "agents/",
    "commands/",
    "hooks/",
    "skills/",
    "_templates/",
    "README.md",
    "CLAUDE.md",
    "WIKI.md",
    "Welcome.md"
  ]
}
'@
Set-Content -Path (Join-Path $obsidian "app.json") -Value $appJson

# 4. Write appearance.json (enable CSS snippets)
$appearanceJson = @'
{
  "enabledCssSnippets": [
    "vault-colors",
    "ITS-Dataview-Cards",
    "ITS-Image-Adjustments"
  ]
}
'@
Set-Content -Path (Join-Path $obsidian "appearance.json") -Value $appearanceJson

# 5. Download Excalidraw main.js (8MB, not in git)
$excalidraw = Join-Path $obsidian "plugins\obsidian-excalidraw-plugin"
$excalidrawManifest = Join-Path $excalidraw "manifest.json"
$excalidrawMain = Join-Path $excalidraw "main.js"

if ((Test-Path -LiteralPath $excalidrawManifest) -and -not (Test-Path -LiteralPath $excalidrawMain)) {
  Write-Host "Downloading Excalidraw main.js (~8MB)..."
  Invoke-WebRequest `
    -Uri "https://github.com/zsviczian/obsidian-excalidraw-plugin/releases/latest/download/main.js" `
    -OutFile $excalidrawMain
  Write-Host "✓ Excalidraw main.js downloaded"
} elseif (Test-Path -LiteralPath $excalidrawMain) {
  Write-Host "✓ Excalidraw main.js already present"
}

Write-Host ""
Write-Host "✓ Setup complete."
Write-Host ""
Write-Host "Next steps:"
Write-Host "  1. Open Obsidian"
Write-Host "  2. Manage Vaults → Open folder as vault → select: $vault"
Write-Host "  3. Enable community plugins when prompted (Calendar, Thino, Excalidraw, Banners are pre-installed)"
Write-Host "  4. Install: Dataview, Templater, Obsidian Git  (Settings → Community Plugins)"
Write-Host "  5. Type /wiki in Claude Code to scaffold your knowledge base"
Write-Host ""
Write-Host "Pre-installed plugins:"
Write-Host "  - Calendar (sidebar calendar with word count + task dots)"
Write-Host "  - Thino (quick memo capture)"
Write-Host "  - Excalidraw (freehand drawing + image annotation)"
Write-Host "  - Banners (add banner: to any note frontmatter for header images)"
Write-Host ""
Write-Host "CSS snippets enabled:"
Write-Host "  - vault-colors: color-codes wiki/ folders in file explorer"
Write-Host "  - ITS-Dataview-Cards: use ```dataviewjs with .cards for card grids"
Write-Host "  - ITS-Image-Adjustments: append |100 to image embeds for sizing"
Write-Host ""
Write-Host "Views available:"
Write-Host "  - Wiki Map canvas (wiki/Wiki Map.canvas) — knowledge graph"
Write-Host "  - Design Ideas canvas (projects/visual-vault/design-ideas.canvas) — visual reference board"
Write-Host "  - Graph view filtered to wiki/ only, color-coded by type"
Write-Host ""
Write-Host "To switch to the visual layout (Canvas + Calendar + Thino sidebar):"
Write-Host "  Quit Obsidian, then run:"
Write-Host "    Copy-Item '$obsidian\workspace-visual.json' '$obsidian\workspace.json' -Force"
Write-Host "  Then reopen Obsidian."
Write-Host ""
Write-Host "Graph colors: if they reset after closing Obsidian, open Graph settings"
Write-Host "→ Color groups and re-add them once. They persist permanently after that."
