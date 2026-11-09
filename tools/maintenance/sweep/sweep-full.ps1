# Feature 203 sweep driver (crew maintenance tooling; not packaged in Specrew.psd1). Committed 2026-11-09 from the session
# scratchpad, where it was written for the maintainer's DRIFT-045 item 2 and DRIFT-050 rule: every suite and lane it starts
# gets ONE redirected home (SPECREW_USER_HOME_OVERRIDE, set once here and inherited by every child process), and the real
# home's hook files are copied before and compared after. Reports, home snapshots and checkouts are written under the temp
# folder (specrew-sweeps), never into the repository. Launch from PowerShell, not Git Bash (GNU tar on PATH breaks a suite).
# Usage: pwsh -File tools/maintenance/sweep/sweep-full.ps1 -Rev <commit> [-List <file in this folder or a path>] [-SkipLanes]
param([string]$Repo = (Resolve-Path (Join-Path $PSScriptRoot '../../..')).Path, [Parameter(Mandatory)][string]$Rev, [string]$List = 't008iii-list.txt', [switch]$SkipLanes, [int]$SuiteTimeoutSeconds = 900, [int]$Throttle = 6, [string]$Tag = '')
$ErrorActionPreference = 'Stop'
$tools = Split-Path -Parent $PSCommandPath
# Outputs go outside the repository, so a sweep never dirties the tree it is checking.
$scratch = Join-Path ([IO.Path]::GetTempPath()) 'specrew-sweeps'
New-Item -ItemType Directory -Force -Path $scratch | Out-Null
$listPath = if (Test-Path -LiteralPath $List) { (Resolve-Path -LiteralPath $List).Path } else { Join-Path $tools $List }
function Assert-NotSessionTree([string]$Path) { $p = [IO.Path]::GetFullPath($Path).TrimEnd('\') + '\'; $s = [IO.Path]::GetFullPath($Repo).TrimEnd('\') + '\'; if ($s.StartsWith($p, [StringComparison]::OrdinalIgnoreCase)) { throw "refusing to remove ${Path}: it is the session's worktree or a parent of it (B5F-035)" } }
$homeHookFiles = @(
    "$env:USERPROFILE\.claude\settings.json", "$env:USERPROFILE\.claude\settings.local.json",
    "$env:USERPROFILE\.codex\hooks.json", "$env:USERPROFILE\.codex\config.toml",
    "$env:USERPROFILE\.copilot\config.json", "$env:USERPROFILE\.copilot\hooks\specrew-refocus.json", "$env:USERPROFILE\.cursor\hooks.json", "$env:USERPROFILE\.gemini\settings.json")
function Get-HomeSnapshot {
    foreach ($f in $homeHookFiles) {
        if (Test-Path -LiteralPath $f) { [pscustomobject]@{ File = $f; Hash = (Get-FileHash -LiteralPath $f).Hash; Written = (Get-Item -LiteralPath $f).LastWriteTime.ToString('yyyy-MM-dd HH:mm:ss') } }
        else { [pscustomobject]@{ File = $f; Hash = 'absent'; Written = '' } }
    }
}
function Get-HomeChanges($From, $To) {
    foreach ($t in $To) {
        $f = $From | Where-Object File -eq $t.File
        if ($null -eq $f -or $f.Hash -ne $t.Hash) { '  {0} (written {1} local)' -f $t.File, $(if ($t.Written) { $t.Written } else { 'removed' }) }
    }
}

# B5F-032: every suite and lane this sweep starts gets one redirected home, set once here. The deployer honours it
# (GetFolderPath ignores USERPROFILE); the real-home check below stays, and now checks the runner as well.
$fakeHome = Join-Path ([IO.Path]::GetTempPath()) ('sweep-home-' + $Rev)
if (Test-Path -LiteralPath $fakeHome) { Remove-Item -LiteralPath $fakeHome -Recurse -Force }
New-Item -ItemType Directory -Force -Path $fakeHome | Out-Null
$env:SPECREW_USER_HOME_OVERRIDE = $fakeHome

$before = @(Get-HomeSnapshot)
# Changes made between the previous sweep and this one are reported too, not only changes during this sweep.
$lastAfterPath = Join-Path $scratch 'home-last-after.json'
$hadPrevious = Test-Path -LiteralPath $lastAfterPath
$sincePrevious = @(if ($hadPrevious) { Get-HomeChanges (Get-Content -LiteralPath $lastAfterPath -Raw | ConvertFrom-Json) $before })
$keep = Join-Path $scratch "home-before-$Rev"; New-Item -ItemType Directory -Force -Path $keep | Out-Null
foreach ($f in $homeHookFiles) { if (Test-Path -LiteralPath $f) { Copy-Item -LiteralPath $f -Destination (Join-Path $keep (($f -replace '[:\\]', '_'))) -Force } }

& pwsh -NoProfile -File (Join-Path $tools 'sweep-list.ps1') -Repo $Repo -Rev $Rev -ListFile $listPath -SuiteTimeoutSeconds $SuiteTimeoutSeconds -Throttle $Throttle *> (Join-Path $scratch "neighbour-$Rev$Tag.txt")

$co = Join-Path ([IO.Path]::GetTempPath()) ('lanes-' + $Rev)
if (Test-Path $co) { Assert-NotSessionTree $co; & git -C $Repo worktree remove --force $co 2>&1 | Out-Null }
& git -C $Repo worktree add -q --detach $co $Rev
$lanes = @(if (-not $SkipLanes) { 'iteration-001-governance-203', 'f203-i001-suites', 'f203-i001-validator-scope', 'f203-i001-carried', 'f199-class-guards-a', 'f199-class-guards-b' })
try {
    $out = @("lanes: " + ($lanes -join ', '))
    if ($lanes.Count -gt 0) { $out += @(& (Join-Path $tools 'run-lane.ps1') -Dir $co -LaneIds $lanes 2>&1 | ForEach-Object { [string]$_ }) }
}
finally { Assert-NotSessionTree $co; & git -C $Repo worktree remove --force $co 2>&1 | Out-Null }
$after = @(Get-HomeSnapshot)
$during = @(Get-HomeChanges $before $after)
$after | ConvertTo-Json | Set-Content -LiteralPath $lastAfterPath -Encoding UTF8
$out += $(if ($hadPrevious) { 'real home hook files changed since the previous sweep, before this one started: {0}' -f $sincePrevious.Count } else { 'real home hook files changed since the previous sweep: no previous sweep recorded' })
$out += $sincePrevious
$out += 'real home hook files changed during this sweep: {0}' -f $during.Count
$out += $during
$out += 'files the suites wrote to the redirected home: {0}' -f @(Get-ChildItem -LiteralPath $fakeHome -Recurse -File -ErrorAction SilentlyContinue).Count
$out += @(Get-ChildItem -LiteralPath $fakeHome -Recurse -File -ErrorAction SilentlyContinue | Select-Object -First 12 | ForEach-Object { '  ' + $_.FullName.Substring($fakeHome.Length) })
$out | Set-Content -LiteralPath (Join-Path $scratch "sweep-$Rev$Tag.txt") -Encoding UTF8
'--- neighbours'; Get-Content (Join-Path $scratch "neighbour-$Rev$Tag.txt") | Select-Object -Last 3
'--- lanes'; $out
