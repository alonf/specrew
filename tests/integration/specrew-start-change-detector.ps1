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

$scratchRoot = Join-Path -Path $repoRoot -ChildPath '.scratch\specrew-start-detector'
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

# Create required bootstrap files including session-loaded squad.agent.md
$agentsDir = Join-Path $projectRoot '.github\agents'
$null = New-Item -Path $agentsDir -ItemType Directory -Force
$agentFile = Join-Path $agentsDir 'squad.agent.md'
Set-Content -LiteralPath $agentFile -Value "# Squad Agent`n" -Encoding UTF8

# Commit initial state (including squad.agent.md for bootstrap check)
$null = & git -C $projectRoot add -A 2>&1
$null = & git -C $projectRoot commit -m "Initial commit" --quiet 2>&1

# Test 1: No changes to session-loaded files (routine resume)
Write-Host "Test 1: Detector returns empty list when no session-loaded files changed..."

$null = & pwsh -NoProfile -ExecutionPolicy Bypass -File $startScript -ProjectPath $projectRoot -NoLaunch 2>&1

$promptPath = Join-Path $projectRoot '.specrew\last-start-prompt.md'
if (-not (Test-Path -LiteralPath $promptPath)) {
    Write-Fail "last-start-prompt.md was not created"
    exit 1
}

$promptContent = Get-Content -LiteralPath $promptPath -Raw -Encoding UTF8

# Baseline hash should be present in YAML frontmatter
if ($promptContent -notmatch '---\s*\r?\nbaseline_commit_hash:\s*[0-9a-f]{40}\s*\r?\n---') {
    Write-Fail "Baseline commit hash not found in YAML frontmatter"
    exit 1
}

Write-Pass "Detector correctly handled routine resume (no changes)"

# Test 2: Change to session-loaded file should be detected
Write-Host "Test 2: Detector identifies change to session-loaded file..."

# Modify session-loaded file and commit
Set-Content -LiteralPath $agentFile -Value "# Squad Agent`n## Updated`n" -Encoding UTF8
$null = & git -C $projectRoot add -A 2>&1
$null = & git -C $projectRoot commit -m "Update agent" --quiet 2>&1

$null = & pwsh -NoProfile -ExecutionPolicy Bypass -File $startScript -ProjectPath $projectRoot -NoLaunch 2>&1

$promptContent = Get-Content -LiteralPath $promptPath -Raw -Encoding UTF8

# Verify baseline hash updated to new HEAD
$newHead = & git -C $projectRoot rev-parse HEAD 2>&1
if ($promptContent -notmatch "baseline_commit_hash:\s*$newHead") {
    Write-Fail "Baseline commit hash was not updated to new HEAD"
    exit 1
}

Write-Pass "Detector correctly updated baseline after change"

Write-Host ""
Write-Host "All change detector tests passed" -ForegroundColor Green
exit 0
