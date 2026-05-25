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

$repoRoot = (Resolve-Path (Join-Path $PSScriptRoot '..\..')).Path
$env:SPECREW_MODULE_PATH = $repoRoot
$reviewScaffolder = Join-Path $repoRoot '.specify\extensions\specrew-speckit\scripts\scaffold-review-artifact.ps1'
$retroScaffolder = Join-Path $repoRoot '.specify\extensions\specrew-speckit\scripts\scaffold-retro-artifact.ps1'
$reviewerScaffolder = Join-Path $repoRoot '.specify\extensions\specrew-speckit\scripts\scaffold-reviewer-artifacts.ps1'
$scratchRoot = Join-Path $repoRoot '.scratch\scaffolder-protection'

if (Test-Path -LiteralPath $scratchRoot) {
    Remove-Item -LiteralPath $scratchRoot -Recurse -Force
}
$null = New-Item -ItemType Directory -Path $scratchRoot -Force

# Setup a test project
$projectRoot = Join-Path $scratchRoot 'project'
$null = New-Item -ItemType Directory -Path $projectRoot -Force
$null = & git -C $projectRoot init --quiet 2>&1
$null = & git -C $projectRoot config user.email 'test@specrew.local' 2>&1
$null = & git -C $projectRoot config user.name 'Test User' 2>&1

foreach ($relativeDirectory in @('.specrew', '.specify', '.squad', '.github\agents', 'specs\046-046-bug-bash\iterations\001')) {
    $null = New-Item -ItemType Directory -Path (Join-Path $projectRoot $relativeDirectory) -Force
}

[System.IO.File]::WriteAllText((Join-Path $projectRoot '.specrew\config.yml'), "project_name: sample`nspecrew_version: `"0.0.0`"`nbootstrap_date: `"2026-01-01`"`n", [System.Text.UTF8Encoding]::new($false))
[System.IO.File]::WriteAllText((Join-Path $projectRoot '.specify\feature.json'), "{`n  `"feature_directory`": `"specs/046-046-bug-bash`"`n}", [System.Text.UTF8Encoding]::new($false))
[System.IO.File]::WriteAllText((Join-Path $projectRoot '.squad\team.md'), "# Team`n", [System.Text.UTF8Encoding]::new($false))
[System.IO.File]::WriteAllText((Join-Path $projectRoot '.squad\config.json'), "{}`n", [System.Text.UTF8Encoding]::new($false))
[System.IO.File]::WriteAllText((Join-Path $projectRoot '.squad\decisions.md'), "# Decisions`n", [System.Text.UTF8Encoding]::new($false))
[System.IO.File]::WriteAllText((Join-Path $projectRoot '.github\agents\squad.agent.md'), "# Squad Agent`n", [System.Text.UTF8Encoding]::new($false))
[System.IO.File]::WriteAllText((Join-Path $projectRoot 'README.md'), "# Test Repo`n", [System.Text.UTF8Encoding]::new($false))

$iterationDir = Join-Path $projectRoot 'specs\046-046-bug-bash\iterations\001'
$planPath = Join-Path $iterationDir 'plan.md'
$planContent = @"
# Iteration Plan: Iteration 001

## Tasks

| Task | Title | Owner | Requirement | Status |
| ---- | ----- | ----- | ----------- | ------ |
| T001 | Test Task | Implementer | FR-001      | done   |
"@
[System.IO.File]::WriteAllText($planPath, $planContent, [System.Text.UTF8Encoding]::new($false))

$statePath = Join-Path $iterationDir 'state.md'
[System.IO.File]::WriteAllText($statePath, "# State`n", [System.Text.UTF8Encoding]::new($false))

$driftPath = Join-Path $iterationDir 'drift-log.md'
[System.IO.File]::WriteAllText($driftPath, "# Drift Log`n", [System.Text.UTF8Encoding]::new($false))

$null = & git -C $projectRoot add -A 2>&1
$null = & git -C $projectRoot commit -m 'Seed repository' --quiet 2>&1

# Scenario 1: scaffold-review-artifact protection
$reviewPath = Join-Path $iterationDir 'review.md'
[System.IO.File]::WriteAllText($reviewPath, "# Review`n`n**Overall Verdict**: accepted`n", [System.Text.UTF8Encoding]::new($false))

# Re-run review scaffolder
$reviewRes = Invoke-TestScript -ScriptPath $reviewScaffolder -ArgumentList @('-IterationDirectory', $iterationDir)
if ($reviewRes.ExitCode -ne 0) {
    Write-Fail ("Review scaffolder failed: {0}" -f ($reviewRes.Output -join [Environment]::NewLine))
    exit 1
}

# Verify original review.md is preserved (has accepted Overall Verdict)
$reviewContent = Get-Content -LiteralPath $reviewPath -Raw -Encoding UTF8
if ($reviewContent -notmatch 'Overall Verdict\*\*?:\s*accepted') {
    Write-Fail 'Review scaffolder overwrote accepted review.md!'
    exit 1
}

# Verify review.md.pending sibling exists
$reviewPendingPath = Join-Path $iterationDir 'review.md.pending'
if (-not (Test-Path -LiteralPath $reviewPendingPath -PathType Leaf)) {
    Write-Fail 'Review scaffolder did not write review.md.pending sibling!'
    exit 1
}

Write-Pass 'Scenario 1: Review scaffolder preserves accepted reviews and redirects to .pending sibling'


# Scenario 2: scaffold-reviewer-artifacts protection
# Create review-diagrams.md with custom content
$diagramsPath = Join-Path $iterationDir 'review-diagrams.md'
[System.IO.File]::WriteAllText($diagramsPath, "# Custom Diagram Content", [System.Text.UTF8Encoding]::new($false))

# Re-run reviewer scaffolder
$reviewerRes = Invoke-TestScript -ScriptPath $reviewerScaffolder -ArgumentList @('-IterationDirectory', $iterationDir)
if ($reviewerRes.ExitCode -ne 0) {
    Write-Fail ("Reviewer scaffolder failed: {0}" -f ($reviewerRes.Output -join [Environment]::NewLine))
    exit 1
}

# Verify custom review-diagrams.md is preserved
$diagramsContent = Get-Content -LiteralPath $diagramsPath -Raw -Encoding UTF8
if ($diagramsContent -ne '# Custom Diagram Content') {
    Write-Fail 'Reviewer scaffolder overwrote custom review-diagrams.md!'
    exit 1
}

# Verify review-diagrams.md.pending exists
$diagramsPendingPath = Join-Path $iterationDir 'review-diagrams.md.pending'
if (-not (Test-Path -LiteralPath $diagramsPendingPath -PathType Leaf)) {
    Write-Fail 'Reviewer scaffolder did not write review-diagrams.md.pending!'
    exit 1
}

Write-Pass 'Scenario 2: Reviewer scaffolder preserves custom files when review.md is accepted and redirects to .pending'

exit 0
