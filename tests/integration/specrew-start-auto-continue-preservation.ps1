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

$scratchRoot = Join-Path -Path $repoRoot -ChildPath '.scratch\specrew-start-auto-continue'
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

# Create required bootstrap files including squad.agent.md
$agentsDir = Join-Path $projectRoot '.github\agents'
$null = New-Item -Path $agentsDir -ItemType Directory -Force
$agentFile = Join-Path $agentsDir 'squad.agent.md'
Set-Content -LiteralPath $agentFile -Value "# Squad Agent`n" -Encoding UTF8

# Create initial commit
$null = & git -C $projectRoot add -A 2>&1
$null = & git -C $projectRoot commit -m "Initial commit" --quiet 2>&1

# Test 1: Auto-continue directive is present when no session-loaded files changed
Write-Host "Test 1: Auto-continue preserved for routine resumes (no changes)..."

$null = & pwsh -NoProfile -ExecutionPolicy Bypass -File $startScript -ProjectPath $projectRoot -NoLaunch 2>&1

$promptPath = Join-Path $projectRoot '.specrew\last-start-prompt.md'
if (-not (Test-Path -LiteralPath $promptPath)) {
    Write-Fail "last-start-prompt.md was not created"
    exit 1
}

$promptContent = Get-Content -LiteralPath $promptPath -Raw -Encoding UTF8

# The prompt should contain the standard Crew handoff content (auto-continue behavior)
# Sentinel string survives the F-040 coordinator-prompt surgery rewrite that replaces
# "You are Squad running..." with "You are the Crew team coordinator running...".
$promptSentinel = 'running inside a Specrew-bootstrapped repository'
if ($promptContent -notmatch $promptSentinel) {
    Write-Fail "Auto-continue prompt content is missing or malformed"
    exit 1
}

Write-Pass "Auto-continue directive preserved for routine resume"

# Test 2: Running specrew-start multiple times with no changes preserves auto-continue
Write-Host "Test 2: Multiple runs with no changes preserve auto-continue..."

$null = & pwsh -NoProfile -ExecutionPolicy Bypass -File $startScript -ProjectPath $projectRoot -NoLaunch 2>&1

$promptContent2 = Get-Content -LiteralPath $promptPath -Raw -Encoding UTF8

if ($promptContent2 -notmatch $promptSentinel) {
    Write-Fail "Auto-continue prompt content is missing after second run"
    exit 1
}

# Verify baseline hash is still present
if ($promptContent2 -notmatch 'baseline_commit_hash:\s*[0-9a-f]{40}') {
    Write-Fail "Baseline hash is missing after second run"
    exit 1
}

Write-Pass "Auto-continue preserved across multiple runs with no changes"

# Test 3: Uncommitted changes do not affect auto-continue (committed state only)
Write-Host "Test 3: Uncommitted changes do not affect auto-continue..."

$agentsDir = Join-Path $projectRoot '.github\agents'
$null = New-Item -Path $agentsDir -ItemType Directory -Force
$agentFile = Join-Path $agentsDir 'squad.agent.md'
Set-Content -LiteralPath $agentFile -Value "# Squad Agent (uncommitted)`n" -Encoding UTF8

$null = & pwsh -NoProfile -ExecutionPolicy Bypass -File $startScript -ProjectPath $projectRoot -NoLaunch 2>&1

$promptContent3 = Get-Content -LiteralPath $promptPath -Raw -Encoding UTF8

if ($promptContent3 -notmatch $promptSentinel) {
    Write-Fail "Auto-continue prompt content is missing with uncommitted changes"
    exit 1
}

Write-Pass "Auto-continue preserved with uncommitted changes (committed state only)"

Write-Host ""
Write-Host "All auto-continue preservation tests passed" -ForegroundColor Green
exit 0
