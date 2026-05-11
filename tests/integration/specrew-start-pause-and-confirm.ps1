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

$scratchRoot = Join-Path -Path $repoRoot -ChildPath '.scratch\specrew-start-pause-confirm'
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
Set-Content -LiteralPath $agentFile -Value "# Squad Agent`nOriginal content`n" -Encoding UTF8

# Commit initial state
$null = & git -C $projectRoot add -A 2>&1
$null = & git -C $projectRoot commit -m "Initial commit" --quiet 2>&1

# First run establishes baseline
Write-Host "Establishing baseline..."
$null = & pwsh -NoProfile -ExecutionPolicy Bypass -File $startScript -ProjectPath $projectRoot -NoLaunch 2>&1

$promptPath = Join-Path $projectRoot '.specrew\last-start-prompt.md'
if (-not (Test-Path -LiteralPath $promptPath)) {
    Write-Fail "last-start-prompt.md was not created"
    exit 1
}

# Test 1: Change to session-loaded file triggers pause-and-confirm
Write-Host "`nTest 1: Pause-and-confirm directive injected when session-loaded file changed..."

Set-Content -LiteralPath $agentFile -Value "# Squad Agent`nUpdated content for pause test`n" -Encoding UTF8
$null = & git -C $projectRoot add -A 2>&1
$null = & git -C $projectRoot commit -m "Update agent" --quiet 2>&1

$null = & pwsh -NoProfile -ExecutionPolicy Bypass -File $startScript -ProjectPath $projectRoot -NoLaunch 2>&1

$promptContent = Get-Content -LiteralPath $promptPath -Raw -Encoding UTF8

# Verify pause-and-confirm directive is present
if ($promptContent -notmatch 'PAUSE-AND-CONFIRM|Session-loaded files changed|Session-Loaded Files Changed') {
    Write-Fail "Pause-and-confirm directive not found in handoff prompt"
    Write-Host "Prompt content preview:" -ForegroundColor Yellow
    Write-Host ($promptContent.Substring(0, [Math]::Min(500, $promptContent.Length)))
    exit 1
}

Write-Pass "Pause-and-confirm directive present"

# Test 2: File list is visible in handoff
Write-Host "`nTest 2: Changed file list visible in handoff..."

if ($promptContent -notmatch '\.github[/\\]agents[/\\]squad\.agent\.md') {
    Write-Fail "Changed file path not visible in handoff prompt"
    exit 1
}

Write-Pass "Changed file list visible in handoff"

# Test 3: Baseline hash still updated after pause
Write-Host "`nTest 3: Baseline hash updated to new HEAD after pause..."

$newHead = & git -C $projectRoot rev-parse HEAD 2>&1
if ($promptContent -notmatch "baseline_commit_hash:\s*$newHead") {
    Write-Fail "Baseline commit hash was not updated to new HEAD"
    exit 1
}

Write-Pass "Baseline hash correctly updated"

# Test 4: Multiple changed files listed
Write-Host "`nTest 4: Multiple changed files trigger pause with full list..."

$charterDir = Join-Path $projectRoot '.squad\agents\planner'
$null = New-Item -Path $charterDir -ItemType Directory -Force
$charterFile = Join-Path $charterDir 'charter.md'
Set-Content -LiteralPath $charterFile -Value "# Planner Charter`nNew charter`n" -Encoding UTF8

$null = & git -C $projectRoot add -A 2>&1
$null = & git -C $projectRoot commit -m "Add charter" --quiet 2>&1

$null = & pwsh -NoProfile -ExecutionPolicy Bypass -File $startScript -ProjectPath $projectRoot -NoLaunch 2>&1

$promptContent = Get-Content -LiteralPath $promptPath -Raw -Encoding UTF8

if ($promptContent -notmatch '\.squad[/\\]agents[/\\]planner[/\\]charter\.md') {
    Write-Fail "New changed file not visible in handoff prompt"
    exit 1
}

Write-Pass "Multiple changed files correctly listed"

# Test 5: Routine resume after no changes shows auto-continue
Write-Host "`nTest 5: Auto-continue preserved after changes committed..."

$null = & pwsh -NoProfile -ExecutionPolicy Bypass -File $startScript -ProjectPath $projectRoot -NoLaunch 2>&1

$promptContent = Get-Content -LiteralPath $promptPath -Raw -Encoding UTF8

# After no new changes, should auto-continue (no pause-and-confirm)
if ($promptContent -match 'PAUSE-AND-CONFIRM|Session-loaded files changed|Session-Loaded Files Changed') {
    Write-Fail "Pause-and-confirm directive present when no changes occurred"
    exit 1
}

Write-Pass "Auto-continue preserved for routine resume"

Write-Host ""
Write-Host "All pause-and-confirm tests passed" -ForegroundColor Green
exit 0
