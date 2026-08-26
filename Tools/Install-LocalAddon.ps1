<#
.SYNOPSIS
    Sets up this repo checkout as a locally loadable WoW addon for in-game testing.

.DESCRIPTION
    Replaces the old "clone the repo directly inside the AddOns folder" workflow.
    Instead, this script:
      1. Creates a directory junction from each detected WoW AddOns folder to this
         repo, so the client loads the addon straight from your working copy.
      2. Fetches the Ace3/CallbackHandler/LibStub/LibDataBroker libraries declared
         in .pkgmeta into Libs/, so the addon actually has its dependencies.

    No SVN client is installed or required: the svn:// externals are fetched with
    `git svn`, which ships as part of Git for Windows. The only external tool used
    is `git`, which this repo already requires.

    This is a lighter-weight alternative to running the full BigWigsMods packager
    (https://github.com/BigWigsMods/packager) locally, which is still an option -
    see CONTRIBUTING.md - if you want an actual packaged zip instead of a live junction.

.PARAMETER AddonsPath
    One or more "Interface\AddOns" folders to link into. Defaults to auto-detecting
    every "_retail_", "_beta_", "_anniversary_", "_classic_", "_classic_era_" and
    "_classic_ptr_" install under
    "C:\Program Files (x86)\World of Warcraft" and "C:\Program Files\World of Warcraft".

.PARAMETER SkipLibs
    Skip fetching/updating the Libs/ folder.

.PARAMETER SkipLink
    Skip creating the AddOns folder junction(s).

.PARAMETER UpdateLibs
    Re-fetch libraries even if Libs/<name> already exists.

.PARAMETER Uninstall
    Remove the junction(s) created by a previous run (only removes actual
    junctions/reparse points, never a real folder) and exit. Libs/ is left alone.

.EXAMPLE
    .\Tools\Install-LocalAddon.ps1

.EXAMPLE
    .\Tools\Install-LocalAddon.ps1 -AddonsPath 'D:\Games\World of Warcraft\_retail_\Interface\AddOns'

.EXAMPLE
    .\Tools\Install-LocalAddon.ps1 -Uninstall
#>
[CmdletBinding()]
param(
    [string[]] $AddonsPath,
    [switch] $SkipLibs,
    [switch] $SkipLink,
    [switch] $UpdateLibs,
    [switch] $Uninstall
)

$ErrorActionPreference = 'Continue'
$RepoRoot = (Resolve-Path (Join-Path $PSScriptRoot '..')).Path
$AddonName = 'PersonalPlayerNotes'

function Find-AddonsFolders {
    $roots = @(
        'C:\Program Files (x86)\World of Warcraft',
        'C:\Program Files\World of Warcraft'
    )
    $flavors = @('_retail_', '_beta_', '_anniversary_', '_classic_', '_classic_era_', '_classic_ptr_')
    $found = @()
    foreach ($root in $roots) {
        foreach ($flavor in $flavors) {
            $candidate = Join-Path $root "$flavor\Interface\AddOns"
            if (Test-Path $candidate) {
                $found += (Resolve-Path $candidate).Path
            }
        }
    }
    return $found
}

function Test-IsReparsePoint([string] $Path) {
    if (-not (Test-Path $Path)) { return $false }
    $item = Get-Item -LiteralPath $Path -Force
    return [bool]($item.Attributes -band [IO.FileAttributes]::ReparsePoint)
}

function Remove-AddonLinks {
    param([string[]] $Targets)
    foreach ($addonsFolder in $Targets) {
        $link = Join-Path $addonsFolder $AddonName
        if (Test-IsReparsePoint $link) {
            Write-Host "Removing junction: $link"
            (Get-Item -LiteralPath $link -Force).Delete()
        }
        elseif (Test-Path $link) {
            Write-Warning "Skipping $link - it's a real folder, not a junction created by this script. Leaving it alone."
        }
    }
}

function New-AddonLinks {
    param([string[]] $Targets)
    foreach ($addonsFolder in $Targets) {
        if (-not (Test-Path $addonsFolder)) {
            Write-Warning "AddOns folder not found, skipping: $addonsFolder"
            continue
        }
        $link = Join-Path $addonsFolder $AddonName
        if (Test-IsReparsePoint $link) {
            $existingTarget = (Get-Item -LiteralPath $link -Force).Target
            if ($existingTarget -contains $RepoRoot -or $existingTarget -eq $RepoRoot) {
                Write-Host "Already linked: $link"
                continue
            }
            Write-Warning "$link is a junction pointing elsewhere ($existingTarget). Remove it manually (or run -Uninstall first) if you want to relink it."
            continue
        }
        if (Test-Path $link) {
            Write-Warning "Skipping $link - a real folder already exists there (not a junction). Move/remove it manually first if you want this repo linked instead."
            continue
        }
        Write-Host "Linking $link -> $RepoRoot"
        New-Item -ItemType Junction -Path $link -Target $RepoRoot | Out-Null
    }
}

function Get-PkgmetaExternals {
    $pkgmetaPath = Join-Path $RepoRoot '.pkgmeta'
    $lines = Get-Content -LiteralPath $pkgmetaPath
    $externals = [ordered]@{}
    $inExternals = $false
    $currentKey = $null
    foreach ($line in $lines) {
        if ($line -match '^externals:\s*$') {
            $inExternals = $true
            continue
        }
        if (-not $inExternals) { continue }
        if ($line -match '^\S') {
            # a new top-level key ends the externals block
            break
        }
        if ($line -match '^\s{2}(\S+):\s*(\S+)\s*$') {
            # single-line form, e.g. "  Libs/AceAddon-3.0: svn://..."
            $externals[$matches[1]] = @{ Url = $matches[2] }
            $currentKey = $null
        }
        elseif ($line -match '^\s{2}(\S+):\s*$') {
            # multi-line block form, e.g. "  Libs/LibDataBroker-1.1:"
            $currentKey = $matches[1]
            $externals[$currentKey] = @{}
        }
        elseif ($currentKey -and $line -match '^\s{4}(\S+):\s*(\S+)\s*$') {
            $externals[$currentKey][$matches[1]] = $matches[2]
        }
    }
    return $externals
}

function Install-Libs {
    $externals = Get-PkgmetaExternals
    foreach ($key in $externals.Keys) {
        $dest = Join-Path $RepoRoot $key
        if ((Test-Path $dest) -and -not $UpdateLibs) {
            Write-Host "Already present, skipping: $key"
            continue
        }
        if (Test-Path $dest) {
            Remove-Item -LiteralPath $dest -Recurse -Force
        }

        $url = $externals[$key].Url
        Write-Host "Fetching $key"
        if ($url -like 'svn://*' -or $url -like '*repos.wowace.com*' -or $url -like '*repos.curseforge.net*') {
            # WowAce/CurseForge host these as plain Subversion repositories (dumb HTTP or
            # svn:// protocol). git svn ships with Git for Windows, so no separate svn
            # client install is required. git/git-svn write normal progress to stderr, so
            # capture it as plain text (not an error record) and check the exit code instead.
            $output = git svn clone --quiet -r HEAD "$url" "$dest" *>&1 | Out-String
        }
        elseif ($url) {
            $output = git clone --quiet --depth 1 "$url" "$dest" *>&1 | Out-String
        }
        else {
            Write-Warning "Could not determine URL for $key, skipping."
            continue
        }

        if ($LASTEXITCODE -ne 0) {
            Write-Warning "Failed to fetch $key`: $output"
            continue
        }
        Write-Verbose $output

        $gitMeta = Join-Path $dest '.git'
        if (Test-Path $gitMeta) {
            Remove-Item -LiteralPath $gitMeta -Recurse -Force
        }
    }
}

if ($Uninstall) {
    $targets = if ($AddonsPath) { $AddonsPath } else { Find-AddonsFolders }
    Remove-AddonLinks -Targets $targets
    return
}

if (-not $SkipLink) {
    $targets = if ($AddonsPath) { $AddonsPath } else { Find-AddonsFolders }
    if (-not $targets) {
        Write-Warning 'No WoW AddOns folders found/specified. Pass -AddonsPath explicitly.'
    }
    else {
        New-AddonLinks -Targets $targets
    }
}

if (-not $SkipLibs) {
    Install-Libs
}

Write-Host "`nDone. Reload/restart WoW (or /reload) to pick up the linked addon."
