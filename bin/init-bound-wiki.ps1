#!/usr/bin/env pwsh
# Initialize or normalize a bound wiki root into the standard claude-obsidian
# layout on first use. This script is not an ongoing maintenance or backfill
# tool after initialization.
# Usage:
#   pwsh -File .\bin\init-bound-wiki.ps1 -VaultPath D:\wiki\actionFlow
#   pwsh -File .\bin\init-bound-wiki.ps1 -VaultPath D:\wiki\actionFlow -WhatIf

[CmdletBinding(SupportsShouldProcess = $true)]
param(
  [Parameter(Mandatory = $true)]
  [string]$VaultPath,

  [string]$WikiName,

  [string]$Purpose = "Replace this with the purpose of this wiki.",

  [string]$Owner = "Unassigned"
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

$vault = [System.IO.Path]::GetFullPath($VaultPath)
if (-not $WikiName) {
  $WikiName = Split-Path -Leaf $vault
}

$today = Get-Date -Format "yyyy-MM-dd"
$wikiRoot = Join-Path $vault "wiki"
$rawRoot = Join-Path $vault ".raw"
$attachmentsRoot = Join-Path $vault "_attachments"
$templatesRoot = Join-Path $vault "_templates"
$claudeFile = Join-Path $vault "CLAUDE.md"

function Ensure-Directory {
  param(
    [Parameter(Mandatory = $true)]
    [string]$Path
  )

  if (-not (Test-Path -LiteralPath $Path)) {
    if ($PSCmdlet.ShouldProcess($Path, "Create directory")) {
      New-Item -ItemType Directory -Path $Path -Force | Out-Null
    }
  }
}

function Write-FileIfMissing {
  param(
    [Parameter(Mandatory = $true)]
    [string]$Path,

    [Parameter(Mandatory = $true)]
    [string]$Content
  )

  if (Test-Path -LiteralPath $Path) {
    Write-Host "Skipped existing file: $Path"
    return
  }

  if ($PSCmdlet.ShouldProcess($Path, "Create file")) {
    Set-Content -LiteralPath $Path -Value $Content -Encoding utf8
  }
}

function Ensure-Frontmatter {
  param(
    [Parameter(Mandatory = $true)]
    [string]$Path,

    [Parameter(Mandatory = $true)]
    [string]$Frontmatter
  )

  if (-not (Test-Path -LiteralPath $Path)) {
    return
  }

  $current = Get-Content -LiteralPath $Path -Raw
  if ($current.TrimStart().StartsWith("---")) {
    return
  }

  $normalized = $current.TrimStart("`r", "`n")
  $content = "$Frontmatter`r`n`r`n$normalized"
  if ($PSCmdlet.ShouldProcess($Path, "Prepend missing frontmatter")) {
    Set-Content -LiteralPath $Path -Value $content -Encoding utf8
  }
}

function Move-ExistingDirectoryIntoWiki {
  param(
    [Parameter(Mandatory = $true)]
    [string]$DirectoryName
  )

  $source = Join-Path $vault $DirectoryName
  if (-not (Test-Path -LiteralPath $source)) {
    return
  }

  $target = Join-Path $wikiRoot $DirectoryName
  Ensure-Directory -Path $target

  $children = @(Get-ChildItem -LiteralPath $source -Force)
  foreach ($child in $children) {
    $destination = Join-Path $target $child.Name
    if (Test-Path -LiteralPath $destination) {
      throw "Cannot migrate '$($child.FullName)' because '$destination' already exists."
    }

    if ($PSCmdlet.ShouldProcess($child.FullName, "Move to $destination")) {
      Move-Item -LiteralPath $child.FullName -Destination $destination
    }
  }

  $remaining = @(Get-ChildItem -LiteralPath $source -Force)
  if ($remaining.Count -eq 0 -and $PSCmdlet.ShouldProcess($source, "Remove empty directory")) {
    Remove-Item -LiteralPath $source -Force
  }
}

function Move-ExistingFileIntoWiki {
  param(
    [Parameter(Mandatory = $true)]
    [string]$FileName
  )

  $source = Join-Path $vault $FileName
  if (-not (Test-Path -LiteralPath $source)) {
    return
  }

  $target = Join-Path $wikiRoot $FileName
  if (Test-Path -LiteralPath $target) {
    throw "Cannot migrate '$source' because '$target' already exists."
  }

  if ($PSCmdlet.ShouldProcess($source, "Move to $target")) {
    Move-Item -LiteralPath $source -Destination $target
  }
}

Write-Host "Initializing bound wiki root: $vault"

Ensure-Directory -Path $vault
Ensure-Directory -Path $wikiRoot
Ensure-Directory -Path $rawRoot
Ensure-Directory -Path (Join-Path $wikiRoot "concepts")
Ensure-Directory -Path (Join-Path $wikiRoot "entities")
Ensure-Directory -Path (Join-Path $wikiRoot "sources")
Ensure-Directory -Path (Join-Path $wikiRoot "meta")
Ensure-Directory -Path (Join-Path $wikiRoot "domains")
Ensure-Directory -Path (Join-Path $wikiRoot "comparisons")
Ensure-Directory -Path (Join-Path $wikiRoot "questions")
Ensure-Directory -Path (Join-Path $wikiRoot "canvases")
Ensure-Directory -Path (Join-Path $attachmentsRoot "images")
Ensure-Directory -Path (Join-Path $attachmentsRoot "pdfs")
Ensure-Directory -Path $templatesRoot

foreach ($directoryName in @(
  "concepts",
  "entities",
  "sources",
  "meta",
  "domains",
  "comparisons",
  "questions",
  "canvases"
)) {
  Move-ExistingDirectoryIntoWiki -DirectoryName $directoryName
}

foreach ($fileName in @("index.md", "log.md", "hot.md", "overview.md")) {
  Move-ExistingFileIntoWiki -FileName $fileName
}

$manifestJson = @'
{
  "sources": {}
}
'@

$indexMd = @"
---
type: meta
title: "Index"
created: $today
updated: $today
tags:
  - meta
  - index
status: developing
---

# Index

## Overview
- [[overview]]

## Domains
- [[domains/_index|Domains Index]]

## Entities
- [[entities/_index|Entities Index]]

## Concepts
- [[concepts/_index|Concepts Index]]

## Sources

## Questions

## Comparisons

## Decisions

## Sessions
"@

$logMd = @"
---
type: meta
title: "Log"
created: $today
updated: $today
tags:
  - meta
  - log
status: developing
---

# Log

New entries go at the top.
"@

$hotMd = @"
---
type: meta
title: "Hot Cache"
created: $today
updated: $today
tags:
  - meta
  - hot-cache
status: developing
---

# Recent Context

## Last Updated
$today. Wiki initialized.

## Key Recent Facts
- This wiki now follows the standard claude-obsidian bound-wiki layout.

## Recent Changes
- Initialized standard folders and baseline files.

## Active Threads
- Replace this section with the current active work.
"@

$overviewMd = @"
---
type: meta
title: "Overview"
created: $today
updated: $today
tags:
  - meta
  - overview
status: seed
---

# Overview

Purpose: $Purpose

## Current State
- Wiki initialized and ready for ingest, query, save, lint, and autoresearch workflows.

## Navigation
- [[index]]
- [[concepts/_index|Concepts Index]]
- [[entities/_index|Entities Index]]
- [[domains/_index|Domains Index]]
"@

$conceptsIndex = @"
---
type: meta
title: "Concepts Index"
created: $today
updated: $today
tags:
  - meta
  - index
status: developing
---

# Concepts

No concept notes have been created yet.
"@

$entitiesIndex = @"
---
type: meta
title: "Entities Index"
created: $today
updated: $today
tags:
  - meta
  - index
status: developing
---

# Entities

No entity notes have been created yet.
"@

$domainsIndex = @"
---
type: meta
title: "Domains Index"
created: $today
updated: $today
tags:
  - meta
  - index
status: developing
---

# Domains

No domain notes have been created yet.
"@

$claudeMd = @"
# $WikiName

SchemaStandard: claude-obsidian-binding-v1
Purpose: $Purpose
Owner: $Owner
Created: $today

## Role

This file defines the local policy for this wiki. The base folder layout and
workflow semantics come from the shared claude-obsidian skills and binding rules.
Do not redefine the core vault schema here.

## Scope

- Replace this section with the domains this wiki covers.
- Replace this section with what should stay out of this wiki.

## Operating Rules

- This wiki follows the standard claude-obsidian layout rooted in this folder.
- `.raw/` stores immutable source material.
- `wiki/index.md` is the master catalog and should be updated on write workflows.
- `wiki/log.md` is append-only with newest entries at the top.
- `wiki/hot.md` is a rolling cache and should be overwritten, not appended.
- Bound projects should resolve this file before running wiki workflows.

## Conventions

- Use YAML frontmatter on wiki notes.
- Use wikilinks for internal references.
- Prefer updating existing notes over creating duplicates.
"@

Write-FileIfMissing -Path (Join-Path $rawRoot ".manifest.json") -Content $manifestJson
Write-FileIfMissing -Path (Join-Path $wikiRoot "index.md") -Content $indexMd
Write-FileIfMissing -Path (Join-Path $wikiRoot "log.md") -Content $logMd
Write-FileIfMissing -Path (Join-Path $wikiRoot "hot.md") -Content $hotMd
Write-FileIfMissing -Path (Join-Path $wikiRoot "overview.md") -Content $overviewMd
Write-FileIfMissing -Path (Join-Path $wikiRoot "concepts\_index.md") -Content $conceptsIndex
Write-FileIfMissing -Path (Join-Path $wikiRoot "entities\_index.md") -Content $entitiesIndex
Write-FileIfMissing -Path (Join-Path $wikiRoot "domains\_index.md") -Content $domainsIndex
Write-FileIfMissing -Path $claudeFile -Content $claudeMd

$indexFrontmatter = @"
---
type: meta
title: "Index"
created: $today
updated: $today
tags:
  - meta
  - index
status: developing
---
"@

$logFrontmatter = @"
---
type: meta
title: "Log"
created: $today
updated: $today
tags:
  - meta
  - log
status: developing
---
"@

$hotFrontmatter = @"
---
type: meta
title: "Hot Cache"
created: $today
updated: $today
tags:
  - meta
  - hot-cache
status: developing
---
"@

Ensure-Frontmatter -Path (Join-Path $wikiRoot "index.md") -Frontmatter $indexFrontmatter
Ensure-Frontmatter -Path (Join-Path $wikiRoot "log.md") -Frontmatter $logFrontmatter
Ensure-Frontmatter -Path (Join-Path $wikiRoot "hot.md") -Frontmatter $hotFrontmatter

Write-Host ""
if ($WhatIfPreference) {
  Write-Host "Bound wiki dry run complete."
} else {
  Write-Host "Bound wiki initialization complete."
}
Write-Host ""
Write-Host "Vault root: $vault"
Write-Host "Canonical wiki instructions: $claudeFile"
Write-Host "Wiki content root: $wikiRoot"
Write-Host "Raw source root: $rawRoot"
Write-Host ""
Write-Host "Project binding example:"
Write-Host "  WikiMode: managed"
Write-Host "  WikiPath: $vault"
Write-Host ""
Write-Host "Use -WhatIf first if you want a dry run."
