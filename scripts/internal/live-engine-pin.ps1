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

function Assert-PinClean {
    # A pin with uncommitted or untracked changes would run those edits as the reviewed engine (round 1, finding 3).
    # Checked when the pin is created or advanced; edits made inside the pin afterwards are not caught at runtime,
    # where only its HEAD is compared with the record (DRIFT-010).
    param([string]$Path)
    $status = Invoke-PinGit @('-C', $Path, 'status', '--porcelain', '--untracked-files=all')
    if (-not [string]::IsNullOrWhiteSpace($status)) {
        throw ("The pinned copy at {0} has local changes, so it is not the reviewed commit. Remove it (-Action Remove) and create it again:`n{1}" -f $Path, $status)
    }
}

function Assert-PinAt {
    param([string]$Path, [string]$Sha)
    $head = (Invoke-PinGit @('-C', $Path, 'rev-parse', 'HEAD')).ToLowerInvariant()
    if ($head -ne $Sha) { throw ("The pinned copy at {0} is at {1}, not {2}." -f $Path, $head.Substring(0, 8), $Sha.Substring(0, 8)) }
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
        if (Test-Path -LiteralPath $recordPath -PathType Leaf) { throw 'A pin is already configured for this project; use -Action Advance to move it, or -Action Remove first.' }
        $path = if ([string]::IsNullOrWhiteSpace($PinPath)) { Get-DefaultPinPath } else { [System.IO.Path]::GetFullPath($PinPath) }
        Assert-OutsideWorktree -Path $path
        if (Test-Path -LiteralPath $path) { throw ("{0} already exists; use -Action Advance to move it, or -Action Remove first." -f $path) }
        $parent = Split-Path -Parent $path
        if (-not (Test-Path -LiteralPath $parent -PathType Container)) { New-Item -ItemType Directory -Path $parent -Force | Out-Null }
        Invoke-PinGit @('-C', $ProjectRoot, 'worktree', 'add', '--detach', $path, $sha) | Out-Null
        Assert-PinAt -Path $path -Sha $sha
        Assert-PinClean -Path $path
        Write-PinRecord -Path $path -Sha $sha
        Write-Output ("Pinned the live engine at {0} ({1})." -f $path, $sha.Substring(0, 8))
    }
    'Advance' {
        $pin = Get-SpecrewLiveEnginePin -ProjectRoot $ProjectRoot
        if (-not [bool]$pin.Configured) { throw 'No pin is configured; use -Action Create.' }
        if ([string]$pin.Reason -in @('record-unreadable', 'pin-missing', 'pin-not-a-checkout')) {
            throw ("The configured pin at {0} cannot be advanced ({1}); use -Action Remove, then -Action Create." -f [string]$pin.Root, [string]$pin.Reason)
        }
        $sha = Resolve-PinCommit -Rev $Commit
        Assert-PinClean -Path ([string]$pin.Root)
        Invoke-PinGit @('-C', [string]$pin.Root, 'checkout', '--quiet', '--detach', $sha) | Out-Null
        Assert-PinAt -Path ([string]$pin.Root) -Sha $sha
        Assert-PinClean -Path ([string]$pin.Root)
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
