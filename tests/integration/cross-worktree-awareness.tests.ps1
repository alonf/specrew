[CmdletBinding()]
param()

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

function Write-Pass { param([string]$Message) Write-Host "PASS: $Message" -ForegroundColor Green }
function Write-Fail { param([string]$Message) Write-Host "FAIL: $Message" -ForegroundColor Red }

function New-WorktreePrompt {
    param(
        [Parameter(Mandatory = $true)][string]$WorktreePath,
        [Parameter(Mandatory = $true)][string]$FeatureRef,
        [Parameter(Mandatory = $true)][string]$Boundary,
        [Parameter(Mandatory = $true)][string]$RecordedAt
    )

    $specrewRoot = Join-Path $WorktreePath '.specrew'
    $specifyRoot = Join-Path $WorktreePath '.specify'
    $null = New-Item -ItemType Directory -Path $specrewRoot -Force
    $null = New-Item -ItemType Directory -Path $specifyRoot -Force
    [System.IO.File]::WriteAllText((Join-Path $specifyRoot 'feature.json'), "{`n  `"feature_directory`": `"specs/$FeatureRef`"`n}", [System.Text.UTF8Encoding]::new($false))
    [System.IO.File]::WriteAllText((Join-Path $specrewRoot 'last-start-prompt.md'), @"
---
session_state_boundary: $Boundary
session_state_feature: $FeatureRef
session_state_recorded_at: $RecordedAt
---

# Prompt
"@, [System.Text.UTF8Encoding]::new($false))
}

function Invoke-TestScript {
    param(
        [Parameter(Mandatory = $true)][string]$ScriptPath,
        [Parameter(Mandatory = $true)][string[]]$ArgumentList
    )

    $output = @(& pwsh -NoProfile -ExecutionPolicy Bypass -File $ScriptPath @ArgumentList 2>&1)
    return @{
        Output = @($output | ForEach-Object { [string]$_ })
        ExitCode = $LASTEXITCODE
    }
}

$repoRoot = (Resolve-Path (Join-Path $PSScriptRoot '..\..')).Path
$whereScript = Join-Path $repoRoot 'scripts\specrew-where.ps1'
$worktreeHelperPath = Join-Path $repoRoot 'scripts\internal\worktree-awareness.ps1'
. $worktreeHelperPath

$scratchRoot = Join-Path $repoRoot '.scratch\cross-worktree-awareness'
if (Test-Path -LiteralPath $scratchRoot) {
    Remove-Item -LiteralPath $scratchRoot -Recurse -Force
}

$projectRoot = Join-Path $scratchRoot 'repo'
$null = New-Item -ItemType Directory -Path $projectRoot -Force
$null = & git -C $projectRoot init --quiet 2>&1
$null = & git -C $projectRoot config user.email 'test@specrew.local' 2>&1
$null = & git -C $projectRoot config user.name 'Test User' 2>&1
[System.IO.File]::WriteAllText((Join-Path $projectRoot 'README.md'), "# Worktree repo`n", [System.Text.UTF8Encoding]::new($false))
$null = & git -C $projectRoot add -A 2>&1
$null = & git -C $projectRoot commit -m 'Initial commit' --quiet 2>&1
$null = & git -C $projectRoot branch -M main 2>&1
New-WorktreePrompt -WorktreePath $projectRoot -FeatureRef '020-session-state-durability' -Boundary 'tasks' -RecordedAt '2026-05-18T00:00:00Z'

$secondaryWorktree = Join-Path $scratchRoot 'wt-021'
$null = & git -C $projectRoot worktree add -b 021-other-feature $secondaryWorktree HEAD 2>&1
New-WorktreePrompt -WorktreePath $secondaryWorktree -FeatureRef '021-other-feature' -Boundary 'plan' -RecordedAt '2026-05-18T00:05:00Z'

$whereResult = Invoke-TestScript -ScriptPath $whereScript -ArgumentList @('--project-path', $projectRoot, '--worktrees', '--ascii')
$whereOutput = $whereResult.Output -join [Environment]::NewLine
if ($whereResult.ExitCode -ne 0) {
    Write-Fail ("specrew where --worktrees failed:`n{0}" -f $whereOutput)
    exit 1
}

foreach ($pattern in @('Specrew worktrees', [regex]::Escape($projectRoot), [regex]::Escape($secondaryWorktree), 'Feature:\s+020', 'Feature:\s+021', 'Boundary:\s+tasks', 'Boundary:\s+plan')) {
    if ($whereOutput -notmatch $pattern) {
        Write-Fail ("Worktree listing is missing expected pattern '{0}'." -f $pattern)
        exit 1
    }
}
Write-Pass 'specrew where --worktrees lists feature and boundary state for active worktrees'

$extraWorktrees = @()
for ($index = 1; $index -le 8; $index++) {
    $path = Join-Path $scratchRoot ("wt-extra-{0:D2}" -f $index)
    $branchName = "extra-$index"
    $null = & git -C $projectRoot worktree add -b $branchName $path HEAD 2>&1
    $featureRef = '{0:D3}-feature' -f (30 + $index)
    New-WorktreePrompt -WorktreePath $path -FeatureRef $featureRef -Boundary 'plan' -RecordedAt '2026-05-18T00:10:00Z'
    $extraWorktrees += $path
}

$elapsed = [System.Diagnostics.Stopwatch]::StartNew()
$worktreeState = @(Get-WorktreeState -ProjectRoot $projectRoot)
$elapsed.Stop()
if ($worktreeState.Count -ne 10 -or $elapsed.ElapsedMilliseconds -ge 2000) {
    Write-Fail ("Worktree derivation should cover 10 worktrees in under 2s (count={0}, elapsed={1} ms)." -f $worktreeState.Count, $elapsed.ElapsedMilliseconds)
    exit 1
}
Write-Pass 'Cross-worktree derivation stays under the 2s budget for 10 worktrees'

Remove-Item -LiteralPath $secondaryWorktree -Recurse -Force
$missingResult = Invoke-TestScript -ScriptPath $whereScript -ArgumentList @('--project-path', $projectRoot, '--worktrees', '--ascii')
$missingOutput = $missingResult.Output -join [Environment]::NewLine
if ($missingResult.ExitCode -ne 0 -or $missingOutput -notmatch '\(path not found; run git worktree prune\)') {
    Write-Fail 'Missing worktree path did not produce the prune guidance annotation.'
    exit 1
}
Write-Pass 'Missing worktree paths are annotated with prune guidance'

exit 0
