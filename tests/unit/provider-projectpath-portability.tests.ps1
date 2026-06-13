[CmdletBinding()]
param()

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

# Feature 182 — PR-review-response hardening (Copilot review on PR #2604).
# Proves the fixes for Copilot's adapter/path comments:
#   1. The GitHub adapter runs `gh` against the SUPPLIED -ProjectPath, not the accidental current
#      working directory (Get-SpecrewGitHubCapability + Get-SpecrewGitHubExistingProtection).
#   2. The try/finally location guard restores the working directory (no leak).
#   3. Fail-open behavior is preserved (no governance file -> opt-in DISABLED; the safe direction).
#   4. Path construction is portable (the multi-segment govPath resolves a real governance file).
#
# The "ProjectPath honored" proof uses a STUB `gh` prepended on PATH that records its own cwd — so we
# observe which directory gh actually ran in, without touching the real repo or needing gh auth.

function Write-Pass { param([string]$m) Write-Host "PASS: $m" -ForegroundColor Green }
function Write-Fail { param([string]$m) Write-Host "FAIL: $m" -ForegroundColor Red; exit 1 }
function Assert-True { param([bool]$c, [string]$m) if (-not $c) { Write-Fail $m } Write-Pass $m }

$repoRoot = (Resolve-Path (Join-Path $PSScriptRoot '..' '..')).Path
$scriptsDir = Join-Path $repoRoot 'extensions' 'specrew-speckit' 'scripts'
. (Join-Path $scriptsDir 'provider-github.ps1')
. (Join-Path $scriptsDir 'shared-governance.ps1')

function New-TempDir {
    param([string]$Prefix)
    $d = Join-Path ([System.IO.Path]::GetTempPath()) ($Prefix + [Guid]::NewGuid().ToString('N'))
    $null = New-Item -ItemType Directory -Path $d -Force
    return (Resolve-Path -LiteralPath $d).Path
}

$fixtureRepo = New-TempDir 'wk-pp-repo-'
$stubDir = New-TempDir 'wk-pp-ghstub-'
$marker = Join-Path $stubDir 'gh-cwd.txt'

# Windows stub (gh.cmd): record cwd, emit parseable JSON (satisfies `gh repo view`), exit 0 (satisfies
# `gh api`). Get-Command/& resolve gh.cmd via PATHEXT when $stubDir is first on PATH.
$ghCmd = "@echo off`r`ncd > `"%SPECREW_GH_CWD_MARKER%`"`r`necho {`"visibility`":`"public`",`"isPrivate`":false}`r`nexit /b 0`r`n"
Set-Content -LiteralPath (Join-Path $stubDir 'gh.cmd') -Value $ghCmd -Encoding ascii -NoNewline
# POSIX stub (for when these suites get CI-wired on Linux/macOS; not exercised on Windows)
$ghSh = "#!/bin/sh`npwd > `"`$SPECREW_GH_CWD_MARKER`"`necho '{`"visibility`":`"public`",`"isPrivate`":false}'`nexit 0`n"
Set-Content -LiteralPath (Join-Path $stubDir 'gh') -Value $ghSh -Encoding ascii -NoNewline
if ($IsLinux -or $IsMacOS) { try { & chmod +x (Join-Path $stubDir 'gh') 2>$null } catch { Write-Verbose "chmod skipped (non-fatal): $_" } }

$savedPath = $env:PATH
$hadMarkerVar = Test-Path Env:\SPECREW_GH_CWD_MARKER
$savedMarker = if ($hadMarkerVar) { $env:SPECREW_GH_CWD_MARKER } else { $null }
$startLocation = (Get-Location).Path
$expectedCanon = (Resolve-Path -LiteralPath $fixtureRepo).Path

try {
    $env:PATH = $stubDir + [System.IO.Path]::PathSeparator + $env:PATH   # prepend: the stub wins over real gh
    $env:SPECREW_GH_CWD_MARKER = $marker

    # --- location-not-leaked: cheap + cannot flake. Banked first. ---
    Remove-Item -LiteralPath $marker -Force -ErrorAction SilentlyContinue
    $null = Get-SpecrewGitHubCapability -ProjectPath $fixtureRepo
    Assert-True ((Get-Location).Path -eq $startLocation) 'location guard restored the working directory after Get-SpecrewGitHubCapability (no leak)'

    # --- premise + ProjectPath honored: the stub ran AND recorded $fixtureRepo as its cwd ---
    Assert-True (Test-Path -LiteralPath $marker) 'premise: the prepended stub gh is the gh that executed (marker written)'
    $recorded = (Get-Content -LiteralPath $marker -Raw).Trim()
    Write-Host "  [debug] capability: recorded cwd = '$recorded' ; expected = '$expectedCanon'"
    $recordedCanon = (Resolve-Path -LiteralPath $recorded).Path
    Assert-True ($recordedCanon -eq $expectedCanon) "ProjectPath honored: Get-SpecrewGitHubCapability ran gh in the supplied ProjectPath (not cwd)"

    # --- the brownfield protection read also honors -ProjectPath ---
    Remove-Item -LiteralPath $marker -Force -ErrorAction SilentlyContinue
    $null = Get-SpecrewGitHubExistingProtection -Branch 'main' -ProjectPath $fixtureRepo
    Assert-True ((Get-Location).Path -eq $startLocation) 'location guard restored cwd after Get-SpecrewGitHubExistingProtection (no leak)'
    Assert-True (Test-Path -LiteralPath $marker) 'premise: stub gh executed for the protection read'
    $recorded2 = (Resolve-Path -LiteralPath ((Get-Content -LiteralPath $marker -Raw).Trim())).Path
    Assert-True ($recorded2 -eq $expectedCanon) 'ProjectPath honored: Get-SpecrewGitHubExistingProtection ran gh in the supplied ProjectPath (not cwd)'
}
finally {
    $env:PATH = $savedPath
    if ($hadMarkerVar) { $env:SPECREW_GH_CWD_MARKER = $savedMarker } else { Remove-Item Env:\SPECREW_GH_CWD_MARKER -ErrorAction SilentlyContinue }
    Set-Location -LiteralPath $startLocation -ErrorAction SilentlyContinue
}

# --- fail-open (no gh dependency): no governance file -> opt-in DISABLED (the safe direction) ---
$bareProj = New-TempDir 'wk-pp-bare-'
try {
    $optin = Get-SpecrewAutomatedReviewOptIn -ProjectRoot $bareProj
    Assert-True (-not [bool]$optin.Enabled) 'fail-open: no repository-governance.yml -> automated-review opt-in DISABLED (safe direction preserved)'
}
finally { Remove-Item -LiteralPath $bareProj -Recurse -Force -ErrorAction SilentlyContinue }

# --- path portability: the multi-segment govPath resolves a real .specrew/repository-governance.yml ---
$portProj = New-TempDir 'wk-pp-port-'
try {
    $null = New-Item -ItemType Directory -Path (Join-Path $portProj '.specrew') -Force
    $gov = "repository_governance:`n  review_gate:`n    automated_review:`n      enabled: true`n      provider_suggestion: copilot`n"
    Set-Content -LiteralPath (Join-Path $portProj '.specrew' 'repository-governance.yml') -Value $gov -Encoding UTF8
    $optin2 = Get-SpecrewAutomatedReviewOptIn -ProjectRoot $portProj
    Assert-True ([bool]$optin2.Enabled) 'path portability: the opt-in reader RESOLVES + reads .specrew/repository-governance.yml via the multi-segment path (Enabled reflects the file)'
}
finally { Remove-Item -LiteralPath $portProj -Recurse -Force -ErrorAction SilentlyContinue }

Remove-Item -LiteralPath $fixtureRepo -Recurse -Force -ErrorAction SilentlyContinue
Remove-Item -LiteralPath $stubDir -Recurse -Force -ErrorAction SilentlyContinue

Write-Host "`nProvider -ProjectPath + path-portability hardening (Copilot review #2604): all assertions pass" -ForegroundColor Green
