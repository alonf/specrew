# Feature 203 T002 (DA-8): create, advance or show the live-engine pin for a Specrew self-host worktree.
#
# The pin is a detached `git worktree` of a reviewed commit, OUTSIDE the project worktree (a checkout under the
# worktree would be counted as source and picked up by the census and lint). Its record,
# .specrew/runtime/live-engine.json, is machine-local and git-ignored; the live hooks read it through
# extensions/specrew-speckit/scripts/live-engine-resolution.ps1. Without a record the hooks behave as before.
#
#   -Action Show                 print the record and whether the pin is usable (the default)
#   -Action Create -Commit <sha> add the pin at <sha> and write the record
#   -Action Advance -Commit <sha> move an existing pin to <sha> and update the record
#   -Action Remove               remove the pin and its record (the hooks return to today's resolution)
[CmdletBinding()]
param(
    [ValidateSet('Show', 'Create', 'Advance', 'Remove')][string]$Action = 'Show',
    [string]$Commit,
    [string]$ProjectRoot = (Get-Location).Path,
    [string]$PinPath
)
Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

$ProjectRoot = (Resolve-Path -LiteralPath $ProjectRoot).Path
$helper = @((Join-Path $PSScriptRoot '../../extensions/specrew-speckit/scripts/live-engine-resolution.ps1'),
    (Join-Path $ProjectRoot 'extensions/specrew-speckit/scripts/live-engine-resolution.ps1')) |
    Where-Object { Test-Path -LiteralPath $_ -PathType Leaf } | Select-Object -First 1
if ([string]::IsNullOrWhiteSpace([string]$helper)) { throw 'live-engine-resolution.ps1 was not found beside this repository.' }
. $helper
$recordPath = Get-SpecrewLiveEngineRecordPath -ProjectRoot $ProjectRoot

function Invoke-PinGit {
    param([string[]]$GitArgs)
    $output = & git @GitArgs 2>&1
    if ($LASTEXITCODE -ne 0) { throw ("git {0} failed: {1}" -f ($GitArgs -join ' '), (($output | Out-String).Trim())) }
    return (($output | Out-String).Trim())
}

function Resolve-PinCommit {
    param([string]$Rev)
    if ([string]::IsNullOrWhiteSpace($Rev)) { throw '-Commit is required for this action.' }
    return (Invoke-PinGit @('-C', $ProjectRoot, 'rev-parse', '--verify', ("{0}^{{commit}}" -f $Rev))).ToLowerInvariant()
}

function Write-PinRecord {
    param([string]$Path, [string]$Sha)
    $dir = Split-Path -Parent $recordPath
    if (-not (Test-Path -LiteralPath $dir -PathType Container)) { New-Item -ItemType Directory -Path $dir -Force | Out-Null }
    $record = [ordered]@{ schema_version = '1'; path = $Path; commit = $Sha; recorded_at = [datetime]::UtcNow.ToString('o') }
    $tmp = "$recordPath.tmp"
    Set-Content -LiteralPath $tmp -Value ($record | ConvertTo-Json) -Encoding UTF8
    Move-Item -LiteralPath $tmp -Destination $recordPath -Force
}

function Get-DefaultPinPath {
    $branch = (Invoke-PinGit @('-C', $ProjectRoot, 'rev-parse', '--abbrev-ref', 'HEAD'))
    if ([string]::IsNullOrWhiteSpace($branch) -or $branch -eq 'HEAD') { $branch = Split-Path -Leaf $ProjectRoot }
    $base = if ($env:USERPROFILE) { $env:USERPROFILE } else { $HOME }
    return (Join-Path $base (Join-Path '.specrew/live-engine' ($branch -replace '[\\/:*?"<>|]', '-')))
}

function Assert-OutsideWorktree {
    param([string]$Path)
    $full = [System.IO.Path]::GetFullPath($Path).TrimEnd('\', '/')
    $root = $ProjectRoot.TrimEnd('\', '/')
    if ($full.StartsWith($root + [System.IO.Path]::DirectorySeparatorChar, [System.StringComparison]::OrdinalIgnoreCase) -or
        $full.Equals($root, [System.StringComparison]::OrdinalIgnoreCase)) {
        throw ("The pin must be outside the project worktree; {0} is inside {1}." -f $full, $root)
    }
}

switch ($Action) {
    'Show' {
        $pin = Get-SpecrewLiveEnginePin -ProjectRoot $ProjectRoot
        if (-not [bool]$pin.Configured) { Write-Output 'No live-engine pin is configured; the hooks use this worktree''s engine code as before.'; break }
        Write-Output ("Pin:    {0}" -f [string]$pin.Root)
        Write-Output ("Commit: {0}" -f [string]$pin.Commit)
        if ([bool]$pin.Valid) { Write-Output 'Status: usable; the hooks load engine code from the pin.' }
        else { Write-Output ("Status: unusable ({0}); the hooks refuse until it is repaired." -f [string]$pin.Reason) }
    }
    'Create' {
        $sha = Resolve-PinCommit -Rev $Commit
        $path = if ([string]::IsNullOrWhiteSpace($PinPath)) { Get-DefaultPinPath } else { [System.IO.Path]::GetFullPath($PinPath) }
        Assert-OutsideWorktree -Path $path
        if (Test-Path -LiteralPath $path) { throw ("{0} already exists; use -Action Advance to move it, or -Action Remove first." -f $path) }
        $parent = Split-Path -Parent $path
        if (-not (Test-Path -LiteralPath $parent -PathType Container)) { New-Item -ItemType Directory -Path $parent -Force | Out-Null }
        Invoke-PinGit @('-C', $ProjectRoot, 'worktree', 'add', '--detach', $path, $sha) | Out-Null
        Write-PinRecord -Path $path -Sha $sha
        Write-Output ("Pinned the live engine at {0} ({1})." -f $path, $sha.Substring(0, 8))
    }
    'Advance' {
        $pin = Get-SpecrewLiveEnginePin -ProjectRoot $ProjectRoot
        if (-not [bool]$pin.Configured) { throw 'No pin is configured; use -Action Create.' }
        $sha = Resolve-PinCommit -Rev $Commit
        Invoke-PinGit @('-C', [string]$pin.Root, 'checkout', '--quiet', '--detach', $sha) | Out-Null
        Write-PinRecord -Path ([string]$pin.Root) -Sha $sha
        Write-Output ("Advanced the live engine pin to {0}." -f $sha.Substring(0, 8))
    }
    'Remove' {
        $pin = Get-SpecrewLiveEnginePin -ProjectRoot $ProjectRoot
        if ([bool]$pin.Configured -and -not [string]::IsNullOrWhiteSpace([string]$pin.Root) -and (Test-Path -LiteralPath ([string]$pin.Root))) {
            Invoke-PinGit @('-C', $ProjectRoot, 'worktree', 'remove', '--force', [string]$pin.Root) | Out-Null
        }
        if (Test-Path -LiteralPath $recordPath -PathType Leaf) { Remove-Item -LiteralPath $recordPath -Force }
        Write-Output 'Removed the live-engine pin; the hooks use this worktree''s engine code again.'
    }
}
