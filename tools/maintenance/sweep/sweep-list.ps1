# Part of the 203 sweep driver (see sweep-full.ps1). Runs a list of suites in a detached checkout of -Rev.
param([string]$Repo = (Resolve-Path (Join-Path $PSScriptRoot '../../..')).Path, [Parameter(Mandatory)][string]$Rev, [Parameter(Mandatory)][string]$ListFile, [int]$Throttle = 6, [int]$SuiteTimeoutSeconds = 900)
$ErrorActionPreference = 'Stop'
$scratch = Split-Path -Parent $PSCommandPath
$outside = [IO.Path]::GetTempPath()
function Assert-NotSessionTree([string]$Path) { $p = [IO.Path]::GetFullPath($Path).TrimEnd('\') + '\'; $s = [IO.Path]::GetFullPath($Repo).TrimEnd('\') + '\'; if ($s.StartsWith($p, [StringComparison]::OrdinalIgnoreCase)) { throw "refusing to remove ${Path}: it is the session's worktree or a parent of it (B5F-035)" } }
$co = Join-Path ([IO.Path]::GetTempPath()) ('sweep-' + $Rev)
if (Test-Path $co) { Assert-NotSessionTree $co; & git -C $Repo worktree remove --force $co 2>&1 | Out-Null }
& git -C $Repo worktree add -q --detach $co $Rev
try {
    Set-Location $co
    & (Join-Path $scratch 'run-suites.ps1') -ListFile $ListFile -Throttle $Throttle -Repo $co -SuiteTimeoutSeconds $SuiteTimeoutSeconds
    "--- untracked left in the checkout:"
    & git -C $co status --short --untracked-files=all | Select-Object -First 20
}
finally {
    Set-Location $outside
    Assert-NotSessionTree $co; & git -C $Repo worktree remove --force $co 2>&1 | Out-Null
}
