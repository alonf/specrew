[CmdletBinding()]
param()

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

function Write-Pass {
    param([string]$Message)
    Write-Host "PASS: $Message" -ForegroundColor Green
}

function Write-Fail {
    param([string]$Message)
    Write-Host "FAIL: $Message" -ForegroundColor Red
}

$repoRoot = (Resolve-Path (Join-Path -Path $PSScriptRoot -ChildPath '..\..')).Path
$startScript = Join-Path -Path $repoRoot -ChildPath 'scripts\specrew-start.ps1'

if (-not (Test-Path -LiteralPath $startScript -PathType Leaf)) {
    Write-Fail "Missing required script: $startScript"
    exit 1
}

$scratchRoot = Join-Path -Path $repoRoot -ChildPath '.scratch\specrew-start-e2e'
$projectRoot = Join-Path -Path $scratchRoot -ChildPath 'project'

if (Test-Path -Path $scratchRoot) {
    Remove-Item -Path $scratchRoot -Recurse -Force
}

$null = New-Item -Path $projectRoot -ItemType Directory -Force

# Initialize git repository
$null = & git -C $projectRoot init --quiet 2>&1
if ($LASTEXITCODE -ne 0) {
    Write-Fail "Failed to initialize git repository"
    exit 1
}

$null = & git -C $projectRoot config user.email "test@specrew.local" 2>&1
$null = & git -C $projectRoot config user.name "Test User" 2>&1

# Bootstrap Specrew structure
$specrewRoot = Join-Path $projectRoot '.specrew'
$null = New-Item -Path $specrewRoot -ItemType Directory -Force
$null = New-Item -Path (Join-Path $projectRoot '.specify') -ItemType Directory -Force
$null = New-Item -Path (Join-Path $projectRoot '.squad') -ItemType Directory -Force

# Create minimal bootstrap surfaces
$null = New-Item -Path (Join-Path $specrewRoot 'config.yml') -ItemType File -Force
Set-Content -LiteralPath (Join-Path $specrewRoot 'config.yml') -Value "version: 1" -Encoding UTF8

$null = New-Item -Path (Join-Path $projectRoot '.squad\team.md') -ItemType File -Force
Set-Content -LiteralPath (Join-Path $projectRoot '.squad\team.md') -Value "# Team`n" -Encoding UTF8

$null = New-Item -Path (Join-Path $projectRoot '.squad\config.json') -ItemType File -Force
Set-Content -LiteralPath (Join-Path $projectRoot '.squad\config.json') -Value "{}" -Encoding UTF8

$null = New-Item -Path (Join-Path $projectRoot '.squad\decisions.md') -ItemType File -Force
Set-Content -LiteralPath (Join-Path $projectRoot '.squad\decisions.md') -Value "# Decisions`n" -Encoding UTF8

# Create session-loaded files
$agentsDir = Join-Path $projectRoot '.github\agents'
$null = New-Item -Path $agentsDir -ItemType Directory -Force
$agentFile = Join-Path $agentsDir 'squad.agent.md'
Set-Content -LiteralPath $agentFile -Value "# Squad Agent`n" -Encoding UTF8

# Commit initial state
$null = & git -C $projectRoot add -A 2>&1
$null = & git -C $projectRoot commit -m "Initial commit" --quiet 2>&1

$promptPath = Join-Path $projectRoot '.specrew\last-start-prompt.md'

# Scenario 1: baseline → no changes → custom directive → auto-continue
Write-Host "Scenario 1: No changes + custom directive → auto-continue..."

$null = & pwsh -NoProfile -ExecutionPolicy Bypass -File $startScript -ProjectPath $projectRoot -NoLaunch 2>&1
$customDirective1 = "Start with iteration planning."
$null = & pwsh -NoProfile -ExecutionPolicy Bypass -File $startScript -ProjectPath $projectRoot -NoLaunch -PostRestartDirective $customDirective1 2>&1

$promptContent = Get-Content -LiteralPath $promptPath -Raw -Encoding UTF8

# Verify custom directive present
if ($promptContent -notmatch [regex]::Escape($customDirective1)) {
    Write-Fail "Scenario 1: Custom directive not found"
    exit 1
}

# Verify no pause-and-confirm (auto-continue behavior)
if ($promptContent -match 'PAUSE-AND-CONFIRM|Session-loaded files changed|Session-Loaded Files Changed') {
    Write-Fail "Scenario 1: Pause-and-confirm present when no changes occurred"
    exit 1
}

Write-Pass "Scenario 1: Custom directive + auto-continue works"

# Scenario 2: baseline → changes → custom directive → pause-and-confirm → resume
Write-Host "`nScenario 2: Changes + custom directive → pause-and-confirm..."

Set-Content -LiteralPath $agentFile -Value "# Squad Agent`nUpdated for scenario 2`n" -Encoding UTF8
$null = & git -C $projectRoot add -A 2>&1
$null = & git -C $projectRoot commit -m "Update agent" --quiet 2>&1

$customDirective2 = "Focus on reviewer escalation."
$null = & pwsh -NoProfile -ExecutionPolicy Bypass -File $startScript -ProjectPath $projectRoot -NoLaunch -PostRestartDirective $customDirective2 2>&1

$promptContent = Get-Content -LiteralPath $promptPath -Raw -Encoding UTF8

# Verify custom directive present
if ($promptContent -notmatch [regex]::Escape($customDirective2)) {
    Write-Fail "Scenario 2: Custom directive not found"
    exit 1
}

# Verify pause-and-confirm present
if ($promptContent -notmatch 'PAUSE-AND-CONFIRM|Session-loaded files changed|Session-Loaded Files Changed') {
    Write-Fail "Scenario 2: Pause-and-confirm missing"
    exit 1
}

# Verify changed file listed
if ($promptContent -notmatch '\.github[/\\]agents[/\\]squad\.agent\.md') {
    Write-Fail "Scenario 2: Changed file not listed"
    exit 1
}

# Verify directive comes before pause
$directiveIndex = $promptContent.IndexOf($customDirective2)
$pauseIndex = $promptContent.IndexOf('Session-Loaded Files Changed', [System.StringComparison]::OrdinalIgnoreCase)
if ($pauseIndex -lt 0) {
    $pauseIndex = $promptContent.IndexOf('Session-loaded files changed', [System.StringComparison]::OrdinalIgnoreCase)
}

if ($directiveIndex -lt 0 -or $pauseIndex -lt 0) {
    Write-Fail "Scenario 2: Could not find both directive and pause message"
    exit 1
}

if ($directiveIndex -gt $pauseIndex) {
    Write-Fail "Scenario 2: Custom directive appears after pause message"
    exit 1
}

Write-Pass "Scenario 2: Custom directive + pause-and-confirm works"

# Scenario 3: After changes committed, next run auto-continues
Write-Host "`nScenario 3: After changes committed, auto-continue resumes..."

$null = & pwsh -NoProfile -ExecutionPolicy Bypass -File $startScript -ProjectPath $projectRoot -NoLaunch 2>&1

$promptContent = Get-Content -LiteralPath $promptPath -Raw -Encoding UTF8

# Verify no pause-and-confirm (auto-continue restored)
if ($promptContent -match 'PAUSE-AND-CONFIRM|Session-loaded files changed|Session-Loaded Files Changed') {
    Write-Fail "Scenario 3: Pause-and-confirm present after routine resume"
    exit 1
}

Write-Pass "Scenario 3: Auto-continue restored after changes committed"

# Scenario 4: Baseline tracking persists across scenarios
Write-Host "`nScenario 4: Baseline tracking persistent across all scenarios..."

# Make another change
Set-Content -LiteralPath $agentFile -Value "# Squad Agent`nFinal update`n" -Encoding UTF8
$null = & git -C $projectRoot add -A 2>&1
$null = & git -C $projectRoot commit -m "Final update" --quiet 2>&1

$null = & pwsh -NoProfile -ExecutionPolicy Bypass -File $startScript -ProjectPath $projectRoot -NoLaunch 2>&1

$promptContent = Get-Content -LiteralPath $promptPath -Raw -Encoding UTF8

# Verify baseline hash updated to latest HEAD
$newHead = & git -C $projectRoot rev-parse HEAD 2>&1
if ($promptContent -notmatch "baseline_commit_hash:\s*$newHead") {
    Write-Fail "Scenario 4: Baseline commit hash not updated"
    exit 1
}

# Verify pause triggered
if ($promptContent -notmatch 'PAUSE-AND-CONFIRM|Session-loaded files changed|Session-Loaded Files Changed') {
    Write-Fail "Scenario 4: Pause-and-confirm missing on new change"
    exit 1
}

Write-Pass "Scenario 4: Baseline tracking persists correctly"

Write-Host ""
Write-Host "All end-to-end tests passed" -ForegroundColor Green
exit 0
