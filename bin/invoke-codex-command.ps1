#!/usr/bin/env pwsh
[CmdletBinding()]
param(
  [Parameter(Mandatory = $true)]
  [ValidateSet("wiki", "backup", "save")]
  [string]$Mode,

  [string]$Prompt,

  [string]$ProjectPath
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

function Get-FullPath {
  param([Parameter(Mandatory = $true)][string]$Path)
  return [System.IO.Path]::GetFullPath($Path)
}

function Get-BindingFromFile {
  param([Parameter(Mandatory = $true)][string]$FilePath)

  if (-not (Test-Path -LiteralPath $FilePath)) {
    return $null
  }

  $wikiMode = $null
  $wikiPath = $null
  $insideFence = $false

  foreach ($line in Get-Content -LiteralPath $FilePath) {
    if ($line -match '^\s*```') {
      $insideFence = -not $insideFence
      continue
    }

    if ($insideFence) {
      continue
    }

    if (-not $wikiMode -and $line -match '^\s*WikiMode:\s*(.+)\s*$') {
      $wikiMode = $matches[1].Trim()
      continue
    }

    if (-not $wikiPath -and $line -match '^\s*WikiPath:\s*(.+)\s*$') {
      $candidate = $matches[1].Trim()
      if ($candidate -notmatch '^<.*>$') {
        $wikiPath = $candidate
      }
    }
  }

  if (-not $wikiMode -and -not $wikiPath) {
    return $null
  }

  return [pscustomobject]@{
    WikiMode = $wikiMode
    WikiPath = $wikiPath
  }
}

function Resolve-WikiContext {
  param([Parameter(Mandatory = $true)][string]$Root)

  $agentsFile = Join-Path $Root "AGENTS.md"
  $claudeFile = Join-Path $Root "CLAUDE.md"

  $binding = Get-BindingFromFile -FilePath $agentsFile
  if (-not $binding) {
    $binding = Get-BindingFromFile -FilePath $claudeFile
  }

  $wikiMode = if ($binding) { $binding.WikiMode } else { $null }
  $wikiPath = if ($binding) { $binding.WikiPath } else { $null }

  if ($wikiPath) {
    $resolvedWikiPath = Get-FullPath -Path $wikiPath
    return [pscustomobject]@{
      Root = $Root
      WikiMode = $wikiMode
      WikiPath = $resolvedWikiPath
      IsBound = $true
      IsLocalVault = $false
    }
  }

  $localWiki = Join-Path $Root "wiki"
  $localRaw = Join-Path $Root ".raw"
  if ((Test-Path -LiteralPath $localWiki) -and (Test-Path -LiteralPath $localRaw)) {
    return [pscustomobject]@{
      Root = $Root
      WikiMode = "managed"
      WikiPath = $Root
      IsBound = $false
      IsLocalVault = $true
    }
  }

  throw "No wiki binding or local vault found."
}

function New-CodexPrompt {
  param(
    [Parameter(Mandatory = $true)][ValidateSet("wiki", "backup", "save")][string]$Mode,
    [Parameter(Mandatory = $true)][pscustomobject]$Context,
    [string]$UserPrompt
  )

  $wikiPathText = $Context.WikiPath.Replace("\", "\\")
  $modeText = if ($Context.IsBound) { "bound wiki" } else { "local vault" }
  $instruction = if ($Mode -eq "wiki") {
@"
You are being invoked from Claude Code as an explicit Codex handoff for wiki work.
Work from project root: $($Context.Root)
Resolved wiki mode: $($Context.WikiMode)
Resolved wiki path: $wikiPathText
Context type: $modeText

Read AGENTS.md and CLAUDE.md in the project root first. Then resolve the wiki root and use the wiki-related skills as needed. Follow the project's instruction hierarchy. All responses must be in Korean. Keep the final answer concise.

User request:
$UserPrompt
"@
  } elseif ($Mode -eq "save") {
@"
You are being invoked from Claude Code as an explicit Codex handoff for saving the current conversation into the wiki.
Work from project root: $($Context.Root)
Resolved wiki mode: $($Context.WikiMode)
Resolved wiki path: $wikiPathText
Context type: $modeText

Read AGENTS.md and CLAUDE.md in the project root first. Then use the save skill against the resolved wiki root. Treat the user request as the save instruction, including any requested title or save type. All responses must be in Korean. Keep the final answer concise.

User request:
$UserPrompt
"@
  } else {
@"
You are being invoked from Claude Code as an explicit Codex handoff for wiki backup.
Work from project root: $($Context.Root)
Resolved wiki mode: $($Context.WikiMode)
Resolved wiki path: $wikiPathText
Context type: $modeText

Read AGENTS.md and CLAUDE.md in the project root first. Then use the wiki-backup skill against the resolved wiki repository only. Never back up the project repository when it points at a separate WikiPath. All responses must be in Korean. Keep the final answer concise.

User request:
$UserPrompt
"@
  }

  return $instruction.Trim()
}

$root = if ($ProjectPath) { Get-FullPath -Path $ProjectPath } else { (Get-Location).Path }
$context = Resolve-WikiContext -Root $root

if (-not (Get-Command codex -ErrorAction SilentlyContinue)) {
  throw "codex CLI is not installed or not on PATH."
}

if ($context.WikiMode -eq "reference" -and ($Mode -eq "backup" -or $Mode -eq "save")) {
  throw "WikiMode is reference. This action is not allowed for a read-only binding."
}

$userPrompt = if ([string]::IsNullOrWhiteSpace($Prompt)) {
  if ($Mode -eq "wiki") {
    "Inspect the configured wiki and continue the requested wiki workflow."
  } elseif ($Mode -eq "save") {
    "Save the current conversation into the resolved wiki."
  } else {
    "Inspect the resolved wiki repository and back it up if needed."
  }
} else {
  $Prompt
}

$codexPrompt = New-CodexPrompt -Mode $Mode -Context $context -UserPrompt $userPrompt
$args = @(
  "exec",
  "--skip-git-repo-check",
  "--ephemeral",
  "--full-auto",
  "--cd", $root
)

if ($context.IsBound -and $context.WikiPath -ne $root) {
  $args += @("--add-dir", $context.WikiPath)
}

$args += $codexPrompt

& codex @args
exit $LASTEXITCODE
