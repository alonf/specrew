[CmdletBinding()]
param()

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

function Write-Pass { param([string]$Message) Write-Host "PASS: $Message" -ForegroundColor Green }
function Write-Fail { param([string]$Message) Write-Host "FAIL: $Message" -ForegroundColor Red }

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

function New-TestProject {
    param(
        [Parameter(Mandatory = $true)][string]$ProjectRoot
    )

    $null = New-Item -ItemType Directory -Path $ProjectRoot -Force
    $null = & git -C $ProjectRoot init --quiet 2>&1
    $null = & git -C $ProjectRoot config user.email 'test@specrew.local' 2>&1
    $null = & git -C $ProjectRoot config user.name 'Test User' 2>&1

    foreach ($relativeDirectory in @('.specrew', '.specify', '.squad', '.github\agents', 'specs\046-046-bug-bash\iterations\001')) {
        $null = New-Item -ItemType Directory -Path (Join-Path $ProjectRoot $relativeDirectory) -Force
    }

    [System.IO.File]::WriteAllText((Join-Path $ProjectRoot '.specrew\config.yml'), "project_name: sample`nspecrew_version: `"0.0.0`"`nbootstrap_date: `"2026-01-01`"`n", [System.Text.UTF8Encoding]::new($false))
    [System.IO.File]::WriteAllText((Join-Path $ProjectRoot '.specify\feature.json'), "{`n  `"feature_directory`": `"specs/046-046-bug-bash`"`n}", [System.Text.UTF8Encoding]::new($false))
    [System.IO.File]::WriteAllText((Join-Path $ProjectRoot '.squad\team.md'), "# Team`n", [System.Text.UTF8Encoding]::new($false))
    [System.IO.File]::WriteAllText((Join-Path $ProjectRoot '.squad\config.json'), "{}`n", [System.Text.UTF8Encoding]::new($false))
    [System.IO.File]::WriteAllText((Join-Path $ProjectRoot '.squad\decisions.md'), "# Decisions`n", [System.Text.UTF8Encoding]::new($false))
    [System.IO.File]::WriteAllText((Join-Path $ProjectRoot '.github\agents\squad.agent.md'), "# Squad Agent`n", [System.Text.UTF8Encoding]::new($false))
    [System.IO.File]::WriteAllText((Join-Path $ProjectRoot 'specs\046-046-bug-bash\spec.md'), "# Spec`n", [System.Text.UTF8Encoding]::new($false))
    [System.IO.File]::WriteAllText((Join-Path $ProjectRoot 'README.md'), "# Test Repo`n", [System.Text.UTF8Encoding]::new($false))

    $null = & git -C $ProjectRoot add -A 2>&1
    $null = & git -C $ProjectRoot commit -m 'Seed repository' --quiet 2>&1
    $null = & git -C $ProjectRoot branch -M main 2>&1
    $null = & git -C $ProjectRoot checkout -b 046-046-bug-bash 2>&1

    return (Join-Path $ProjectRoot 'specs\046-046-bug-bash')
}

function Sync-Boundary {
    param(
        [Parameter(Mandatory = $true)][string]$ProjectRoot,
        [Parameter(Mandatory = $true)][string]$SyncScript,
        [Parameter(Mandatory = $true)][string]$BoundaryType
    )

    $syncResult = Invoke-TestScript -ScriptPath $SyncScript -ArgumentList @(
        '-ProjectPath', $ProjectRoot,
        '-BoundaryType', $BoundaryType,
        '-FeatureRef', '046-046-bug-bash',
        '-IterationNumber', '001',
        '-AuthCommitHash', 'HEAD'
    )

    if ($syncResult.ExitCode -ne 0) {
        throw ("Boundary sync to $BoundaryType failed:`n{0}" -f ($syncResult.Output -join [Environment]::NewLine))
    }
}

$repoRoot = (Resolve-Path (Join-Path $PSScriptRoot '..\..')).Path
$env:SPECREW_MODULE_PATH = $repoRoot
$startScript = Join-Path $repoRoot 'scripts\specrew-start.ps1'
$reviewScript = Join-Path $repoRoot 'scripts\specrew-review.ps1'
$syncScript = Join-Path $repoRoot '.specify\extensions\specrew-speckit\scripts\sync-boundary-state.ps1'
$scratchRoot = Join-Path $repoRoot '.scratch\stale-state-retro'

if (Test-Path -LiteralPath $scratchRoot) {
    Remove-Item -LiteralPath $scratchRoot -Recurse -Force
}
$null = New-Item -ItemType Directory -Path $scratchRoot -Force

# Setup a common accepted review.md
# We'll create two projects to test retro vs tasks boundaries when review.md is accepted.

# Case 1: retro boundary (Should NOT trigger late boundary sync warnings/mismatch)
$retroProject = Join-Path $scratchRoot 'retro-boundary'
New-TestProject -ProjectRoot $retroProject | Out-Null

# Create an accepted review.md in iterations/001/review.md
$reviewPath = Join-Path $retroProject 'specs\046-046-bug-bash\iterations\001\review.md'
$reviewerIndexPath = Join-Path $retroProject 'specs\046-046-bug-bash\iterations\001\reviewer-index.md'
[System.IO.File]::WriteAllText($reviewPath, "# Review`n`n**Reviewed**: 2026-05-25`n**Overall Verdict**: accepted`n", [System.Text.UTF8Encoding]::new($false))
[System.IO.File]::WriteAllText($reviewerIndexPath, "# Reviewer Index`n`n## Summary`n- Passed all tests`n`n## Replay Digest`n`digest``n", [System.Text.UTF8Encoding]::new($false))
$null = & git -C $retroProject add -A 2>&1
$null = & git -C $retroProject commit -m 'Add accepted review and index' --quiet 2>&1

# Sync boundary to retro
Sync-Boundary -ProjectRoot $retroProject -SyncScript $syncScript -BoundaryType 'retro'

# Verify specrew-start does NOT complain about stale state on retro boundary
$startResult = Invoke-TestScript -ScriptPath $startScript -ArgumentList @('-ProjectPath', $retroProject, '-NoLaunch', '-RecoveryChoice', 'C')
if ($startResult.ExitCode -ne 0) {
    Write-Fail ("Specrew start failed on retro boundary:`n{0}" -f ($startResult.Output -join [Environment]::NewLine))
    exit 1
}

$startOutput = $startResult.Output -join [Environment]::NewLine
if ($startOutput -match 'Stale state detected') {
    Write-Fail "Specrew start falsely flagged retro as drift. Output:`n$startOutput"
    exit 1
}

# Verify specrew-review does NOT trigger a warning warning on retro boundary when accepted review exists
$reviewResult = Invoke-TestScript -ScriptPath $reviewScript -ArgumentList @('-ProjectPath', $retroProject, '-Json')
if ($reviewResult.ExitCode -ne 0) {
    Write-Fail ("Specrew review failed on retro boundary:`n{0}" -f ($reviewResult.Output -join [Environment]::NewLine))
    exit 1
}

$reviewOutput = $reviewResult.Output -join [Environment]::NewLine
if ($reviewOutput -like '*WARN:*') {
    Write-Fail "Specrew review returned a warning on retro boundary when accepted review exists: $reviewOutput"
    exit 1
}

Write-Pass "Scenario 1: Retro boundary with accepted review does NOT trigger stale-state warnings."


# Case 2: tasks boundary (SHOULD trigger stale-state warnings/mismatch)
$tasksProject = Join-Path $scratchRoot 'tasks-boundary'
New-TestProject -ProjectRoot $tasksProject | Out-Null

$reviewPath2 = Join-Path $tasksProject 'specs\046-046-bug-bash\iterations\001\review.md'
$reviewerIndexPath2 = Join-Path $tasksProject 'specs\046-046-bug-bash\iterations\001\reviewer-index.md'
[System.IO.File]::WriteAllText($reviewPath2, "# Review`n`n**Reviewed**: 2026-05-25`n**Overall Verdict**: accepted`n", [System.Text.UTF8Encoding]::new($false))
[System.IO.File]::WriteAllText($reviewerIndexPath2, "# Reviewer Index`n`n## Summary`n- Passed all tests`n`n## Replay Digest`n`digest``n", [System.Text.UTF8Encoding]::new($false))
$null = & git -C $tasksProject add -A 2>&1
$null = & git -C $tasksProject commit -m 'Add accepted review and index' --quiet 2>&1

# Sync boundary to tasks
Sync-Boundary -ProjectRoot $tasksProject -SyncScript $syncScript -BoundaryType 'tasks'

# Verify specrew-start DOES warn about stale state on tasks boundary
$startResult2 = Invoke-TestScript -ScriptPath $startScript -ArgumentList @('-ProjectPath', $tasksProject, '-NoLaunch', '-RecoveryChoice', 'C')
$startOutput2 = $startResult2.Output -join [Environment]::NewLine
if ($startOutput2 -notmatch 'Late boundary sync mismatch: review.md is accepted') {
    Write-Fail "Specrew start failed to complain about stale state on tasks boundary when accepted review exists. Output:`n$startOutput2"
    exit 1
}

# Verify specrew-review DOES trigger a warning on tasks boundary
$reviewResult2 = Invoke-TestScript -ScriptPath $reviewScript -ArgumentList @('-ProjectPath', $tasksProject, '-Json')
$reviewOutput2 = $reviewResult2.Output -join [Environment]::NewLine
if ($reviewOutput2 -notmatch 'WARN: Accepted review artifacts exist') {
    Write-Fail "Specrew review failed to trigger warning on tasks boundary when accepted review exists. Output:`n$reviewOutput2"
    exit 1
}

Write-Pass "Scenario 2: Tasks boundary with accepted review STILL triggers stale-state warnings."
exit 0
