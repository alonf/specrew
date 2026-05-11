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

$scratchRoot = Join-Path -Path $repoRoot -ChildPath '.scratch\specrew-start-baseline'
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

$initialHead = & git -C $projectRoot rev-parse HEAD 2>&1

# Test 1: Baseline hash is recorded on first run
Write-Host "Test 1: Baseline hash is recorded in YAML frontmatter..."

$null = & pwsh -NoProfile -ExecutionPolicy Bypass -File $startScript -ProjectPath $projectRoot -NoLaunch 2>&1

$promptPath = Join-Path $projectRoot '.specrew\last-start-prompt.md'
if (-not (Test-Path -LiteralPath $promptPath)) {
    Write-Fail "last-start-prompt.md was not created"
    exit 1
}

$promptContent = Get-Content -LiteralPath $promptPath -Raw -Encoding UTF8

if ($promptContent -notmatch '---\s*\r?\nbaseline_commit_hash:\s*([0-9a-f]{40})\s*\r?\n---') {
    Write-Fail "Baseline commit hash not found in YAML frontmatter"
    exit 1
}

$recordedHash = $Matches[1]

if ($recordedHash -ne $initialHead) {
    Write-Fail "Recorded hash ($recordedHash) does not match current HEAD ($initialHead)"
    exit 1
}

Write-Pass "Baseline hash correctly recorded"

# Test 2: Baseline hash survives round-trip
Write-Host "Test 2: Baseline hash survives round-trip (read/write cycle)..."

$null = & pwsh -NoProfile -ExecutionPolicy Bypass -File $startScript -ProjectPath $projectRoot -NoLaunch 2>&1

$promptContent2 = Get-Content -LiteralPath $promptPath -Raw -Encoding UTF8

if ($promptContent2 -notmatch 'baseline_commit_hash:\s*([0-9a-f]{40})') {
    Write-Fail "Baseline commit hash missing after round-trip"
    exit 1
}

$roundTripHash = $Matches[1]

if ($roundTripHash -ne $initialHead) {
    Write-Fail "Round-trip hash ($roundTripHash) does not match expected ($initialHead)"
    exit 1
}

Write-Pass "Baseline hash survived round-trip"

# Test 3: Baseline hash format validation
Write-Host "Test 3: Baseline hash format is valid (40 hex characters)..."

if ($roundTripHash -notmatch '^[0-9a-f]{40}$') {
    Write-Fail "Baseline hash format is invalid: $roundTripHash"
    exit 1
}

Write-Pass "Baseline hash format is valid"

Write-Host ""
Write-Host "All baseline tracking tests passed" -ForegroundColor Green
exit 0
