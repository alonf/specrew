#!/usr/bin/env pwsh
<#
.SYNOPSIS
Install or refresh the Specrew Unix shell wrappers into a user bin directory.

.DESCRIPTION
feature 140 / Proposal 153, T007. macOS/Linux only. Creates a SYMLINK in the bin
directory for each committed module wrapper (bin/specrew, bin/specrew-*), pointing
back at the module's bin/. Symlinks (not copies) are required so the wrapper's
symlink-resolution loop locates the installed module root (FR-003); a copy at
~/.local/bin would resolve module_root to ~ and break.

Safety (FR-006): never writes outside the requested bin directory; never edits shell
profiles; a missing bin directory requires -Force to create; not-on-PATH is warn-only;
-WhatIf reports without changing anything; an existing non-managed file requires -Force
to overwrite. On Windows it is an explained no-op (the PowerShell module commands work
directly).

.PARAMETER BinDir
Target bin directory. Default: $HOME/.local/bin.

.PARAMETER Force
Create a missing bin directory, and overwrite an existing non-symlink file at a target.

.PARAMETER DryRun
Alias -WhatIf. Report planned actions; change nothing.
#>
[CmdletBinding()]
param(
    [string]$BinDir,
    [switch]$Force,
    [Alias('WhatIf')]
    [switch]$DryRun,
    [switch]$Help,
    [Parameter(ValueFromRemainingArguments = $true)]
    [string[]]$CliArgs
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

# --- Pure, testable helpers (dot-sourceable; no side effects) ---

function ConvertFrom-UnixStyleInstallerArgs {
    # Normalize shell-style flags (--bin-dir <v> / --force / --whatif|--dry-run / --help)
    # to the PS parameter values, so the command works typed either way.
    param(
        [string]$BinDir,
        [bool]$Force,
        [bool]$DryRun,
        [bool]$Help,
        [AllowEmptyCollection()][string[]]$CliArgs
    )

    $result = [ordered]@{ BinDir = $BinDir; Force = $Force; DryRun = $DryRun; Help = $Help }
    $args = @($CliArgs | Where-Object { -not [string]::IsNullOrWhiteSpace($_) })
    for ($i = 0; $i -lt $args.Count; $i++) {
        switch -Regex ($args[$i]) {
            '^--bin-dir=(.+)$' { $result.BinDir = $Matches[1] }
            '^--bin-dir$' {
                $i++
                if ($i -ge $args.Count) { throw '--bin-dir requires a value.' }
                $result.BinDir = $args[$i]
            }
            '^(--force|-f)$' { $result.Force = $true }
            '^(--whatif|--dry-run)$' { $result.DryRun = $true }
            '^(--help|-h)$' { $result.Help = $true }
            default { throw ("Unknown argument '{0}'." -f $args[$i]) }
        }
    }
    return [pscustomobject]$result
}

function Resolve-SpecrewBinDir {
    param([AllowNull()][string]$BinDir)

    if ([string]::IsNullOrWhiteSpace($BinDir)) {
        $userHome = if ($env:HOME) { $env:HOME } else { [Environment]::GetFolderPath('UserProfile') }
        return (Join-Path $userHome '.local/bin')
    }
    return $BinDir
}

function Test-DirOnPath {
    param(
        [Parameter(Mandatory = $true)][string]$Dir,
        [AllowNull()][string]$PathValue
    )

    if ([string]::IsNullOrEmpty($PathValue)) { return $false }
    $sep = [System.IO.Path]::PathSeparator
    $normalizedDir = $Dir.TrimEnd('/', '\')
    foreach ($entry in ($PathValue -split [regex]::Escape($sep))) {
        if ([string]::IsNullOrWhiteSpace($entry)) { continue }
        if ($entry.TrimEnd('/', '\') -eq $normalizedDir) { return $true }
    }
    return $false
}

function Get-WrapperInstallPlan {
    # Pure decision logic for one wrapper. Returns an action without touching disk.
    #   Existing: 'none' | 'symlink-managed' (already -> our wrapper) | 'symlink-foreign' (-> other target) | 'file'
    # Actions: would-create | create | would-replace-symlink | replace-symlink |
    #          skip-needs-force | would-overwrite-file | overwrite-file
    # A MANAGED symlink (already points at our module wrapper) is replaced freely (idempotent).
    # A FOREIGN symlink (points elsewhere) or a regular file is NOT clobbered without -Force.
    param(
        [Parameter(Mandatory = $true)][ValidateSet('none', 'symlink-managed', 'symlink-foreign', 'file')][string]$Existing,
        [bool]$Force,
        [bool]$DryRun
    )

    if ($Existing -eq 'none') {
        return $(if ($DryRun) { 'would-create' } else { 'create' })
    }
    if ($Existing -eq 'symlink-managed') {
        return $(if ($DryRun) { 'would-replace-symlink' } else { 'replace-symlink' })
    }
    # Foreign symlink or regular file at the target: do not clobber a user-owned entry without -Force.
    if (-not $Force) {
        return 'skip-needs-force'
    }
    if ($Existing -eq 'symlink-foreign') {
        return $(if ($DryRun) { 'would-replace-symlink' } else { 'replace-symlink' })
    }
    return $(if ($DryRun) { 'would-overwrite-file' } else { 'overwrite-file' })
}

function Test-IsUnixPlatform {
    # PS7 exposes $IsWindows; fall back to env for older hosts.
    if (Get-Variable -Name IsWindows -Scope Global -ErrorAction SilentlyContinue) {
        return (-not $IsWindows)
    }
    return ($env:OS -ne 'Windows_NT')
}

function Get-ExistingTargetKind {
    # Classify what already exists at $Path, relative to the wrapper we intend to install:
    #   'none' | 'symlink-managed' (symlink already points at $ExpectedTarget) |
    #   'symlink-foreign' (symlink points somewhere else) | 'file' (regular file/dir)
    param(
        [Parameter(Mandatory = $true)][string]$Path,
        [string]$ExpectedTarget
    )

    $item = Get-Item -LiteralPath $Path -Force -ErrorAction SilentlyContinue
    if ($null -eq $item) { return 'none' }
    $isLink = ($item.LinkType -eq 'SymbolicLink') -or `
        (($item.Attributes -band [System.IO.FileAttributes]::ReparsePoint) -eq [System.IO.FileAttributes]::ReparsePoint)
    if (-not $isLink) { return 'file' }

    # A symlink is "managed" only if it already points at the exact wrapper we would install;
    # anything else is foreign and must not be clobbered without -Force.
    $actualTarget = $item.Target
    if ($actualTarget -is [array]) { $actualTarget = $actualTarget | Select-Object -First 1 }
    if ([string]::IsNullOrWhiteSpace($ExpectedTarget) -or [string]::IsNullOrWhiteSpace([string]$actualTarget)) {
        return 'symlink-foreign'
    }
    $normActual = try { [System.IO.Path]::GetFullPath([string]$actualTarget) } catch { [string]$actualTarget }
    $normExpected = try { [System.IO.Path]::GetFullPath($ExpectedTarget) } catch { $ExpectedTarget }
    if ($normActual -eq $normExpected) { return 'symlink-managed' }
    return 'symlink-foreign'
}

# --- Main (skipped when the file is dot-sourced for unit testing) ---

function Invoke-SpecrewInstallShellWrappers {
    param(
        [AllowNull()][string]$BinDir,
        [bool]$Force,
        [bool]$DryRun
    )

    $moduleRoot = Split-Path -Parent $PSScriptRoot
    $sourceBin = Join-Path $moduleRoot 'bin'
    if (-not (Test-Path -LiteralPath $sourceBin -PathType Container)) {
        Write-Host "ERROR: module bin/ directory not found at '$sourceBin'. The installed module appears corrupt." -ForegroundColor Red
        return 1
    }

    if (-not (Test-IsUnixPlatform)) {
        Write-Host "specrew install-shell-wrappers is for macOS/Linux." -ForegroundColor Yellow
        Write-Host "On Windows, use the PowerShell module commands directly (e.g. 'specrew version'). No wrappers were installed."
        return 0
    }

    $resolvedBinDir = Resolve-SpecrewBinDir -BinDir $BinDir

    if (-not (Test-Path -LiteralPath $resolvedBinDir -PathType Container)) {
        if ($DryRun) {
            Write-Host "[dry-run] would create bin directory: $resolvedBinDir"
        }
        elseif ($Force) {
            New-Item -ItemType Directory -Path $resolvedBinDir -Force | Out-Null
            Write-Host "created bin directory: $resolvedBinDir"
        }
        else {
            Write-Host "ERROR: bin directory '$resolvedBinDir' does not exist." -ForegroundColor Red
            Write-Host "Re-run with -Force to create it: specrew install-shell-wrappers -BinDir '$resolvedBinDir' -Force" -ForegroundColor Yellow
            return 1
        }
    }

    $wrappers = @(Get-ChildItem -LiteralPath $sourceBin -File)
    $installed = New-Object System.Collections.Generic.List[string]
    $skipped = New-Object System.Collections.Generic.List[string]

    foreach ($wrapper in $wrappers) {
        $link = Join-Path $resolvedBinDir $wrapper.Name
        $existing = Get-ExistingTargetKind -Path $link -ExpectedTarget $wrapper.FullName
        $action = Get-WrapperInstallPlan -Existing $existing -Force:$Force -DryRun:$DryRun

        switch ($action) {
            'skip-needs-force' {
                Write-Warning "skipping $($wrapper.Name): '$link' already exists and is not a Specrew-managed wrapper (a regular file, or a symlink pointing elsewhere); re-run with -Force to overwrite it."
                $skipped.Add($wrapper.Name)
                continue
            }
            { $_ -like 'would-*' } {
                Write-Host "[dry-run] $action $link -> $($wrapper.FullName)"
                $installed.Add($wrapper.Name)
                continue
            }
            default {
                if ($action -in @('replace-symlink', 'overwrite-file')) {
                    Remove-Item -LiteralPath $link -Force
                }
                New-Item -ItemType SymbolicLink -Path $link -Target $wrapper.FullName | Out-Null
                # Install-Module (NuGet/PSGallery) strips the Unix execute bit from packaged files, so a
                # symlink to the wrapper would be non-executable ("Permission denied"). Restore +x on the
                # target (Unix-only code path; no-op if already executable).
                if (Get-Command chmod -ErrorAction SilentlyContinue) { & chmod +x -- "$($wrapper.FullName)" 2>$null }
                $installed.Add($wrapper.Name)
            }
        }
    }

    if (-not (Test-DirOnPath -Dir $resolvedBinDir -PathValue $env:PATH)) {
        Write-Warning "$resolvedBinDir is not on PATH. Add it to use the commands, e.g.: export PATH=`"$resolvedBinDir`:`$PATH`""
    }

    $verb = if ($DryRun) { 'Would install' } else { 'Installed' }
    Write-Host ("{0} {1} Specrew shell wrapper(s) into {2}:" -f $verb, $installed.Count, $resolvedBinDir) -ForegroundColor Green
    foreach ($name in $installed) { Write-Host "  $name" }
    if ($skipped.Count -gt 0) {
        Write-Host ("Skipped (re-run with -Force): {0}" -f ($skipped -join ', ')) -ForegroundColor Yellow
    }
    return 0
}

function Show-InstallShellWrappersUsage {
    @'
specrew install-shell-wrappers [options]

Install or refresh the Specrew Unix shell wrappers (macOS/Linux) into a bin directory.

Options:
  -BinDir | --bin-dir <path>   Target bin directory (default: $HOME/.local/bin)
  -Force  | --force            Create a missing bin dir; overwrite a non-symlink file
  -WhatIf | --whatif           Report planned actions without changing anything
  -Help   | --help             Show this help

Notes:
  - Wrappers are installed as symlinks back to the module so they resolve the module root.
  - Never writes outside the requested bin directory; never edits shell profiles.
  - On Windows this is an explained no-op; use the PowerShell module commands directly.
'@ | Write-Host
}

if ($MyInvocation.InvocationName -ne '.') {
    $normalized = ConvertFrom-UnixStyleInstallerArgs -BinDir $BinDir -Force:$Force.IsPresent -DryRun:$DryRun.IsPresent -Help:$Help.IsPresent -CliArgs $CliArgs
    if ($normalized.Help) {
        Show-InstallShellWrappersUsage
        exit 0
    }
    $exitCode = Invoke-SpecrewInstallShellWrappers -BinDir $normalized.BinDir -Force:$normalized.Force -DryRun:$normalized.DryRun
    exit $exitCode
}
