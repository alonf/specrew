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

$scratchRoot = Join-Path -Path $repoRoot -ChildPath '.scratch\specrew-start-parameter'
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

# Test 1: Parameter is accepted and prepended
Write-Host "Test 1: -PostRestartDirective parameter accepted and prepended..."

$customDirective = "Focus on reviewer performance validation."
$null = & pwsh -NoProfile -ExecutionPolicy Bypass -File $startScript -ProjectPath $projectRoot -NoLaunch -PostRestartDirective $customDirective 2>&1

if (-not (Test-Path -LiteralPath $promptPath)) {
    Write-Fail "last-start-prompt.md was not created"
    exit 1
}

$promptContent = Get-Content -LiteralPath $promptPath -Raw -Encoding UTF8

if ($promptContent -notmatch [regex]::Escape($customDirective)) {
    Write-Fail "Custom directive not found in handoff prompt"
    exit 1
}

Write-Pass "Custom directive prepended correctly"

# Test 2: Parameter text appears verbatim
Write-Host "`nTest 2: Custom directive appears verbatim (no modification)..."

$testDirective = "Test **bold** and `code` formatting."
$null = & pwsh -NoProfile -ExecutionPolicy Bypass -File $startScript -ProjectPath $projectRoot -NoLaunch -PostRestartDirective $testDirective 2>&1

$promptContent = Get-Content -LiteralPath $promptPath -Raw -Encoding UTF8

if ($promptContent -notmatch [regex]::Escape($testDirective)) {
    Write-Fail "Verbatim directive not preserved"
    exit 1
}

Write-Pass "Directive text preserved verbatim"

# Test 3: Parameter is optional (empty string handled gracefully)
Write-Host "`nTest 3: Empty parameter handled gracefully..."

$null = & pwsh -NoProfile -ExecutionPolicy Bypass -File $startScript -ProjectPath $projectRoot -NoLaunch -PostRestartDirective '' 2>&1

if (-not (Test-Path -LiteralPath $promptPath)) {
    Write-Fail "last-start-prompt.md was not created with empty parameter"
    exit 1
}

Write-Pass "Empty parameter handled gracefully"

# Test 4: Parameter not supplied (default behavior)
Write-Host "`nTest 4: Parameter omission works (default behavior)..."

$null = & pwsh -NoProfile -ExecutionPolicy Bypass -File $startScript -ProjectPath $projectRoot -NoLaunch 2>&1

if (-not (Test-Path -LiteralPath $promptPath)) {
    Write-Fail "last-start-prompt.md was not created without parameter"
    exit 1
}

Write-Pass "Default behavior works without parameter"

# Test 5: Parameter prepended before pause-and-confirm
Write-Host "`nTest 5: Custom directive prepended before pause-and-confirm..."

# Modify session-loaded file to trigger pause
Set-Content -LiteralPath $agentFile -Value "# Squad Agent`nUpdated`n" -Encoding UTF8
$null = & git -C $projectRoot add -A 2>&1
$null = & git -C $projectRoot commit -m "Update agent" --quiet 2>&1

$pauseDirective = "Review the agent changes carefully."
$null = & pwsh -NoProfile -ExecutionPolicy Bypass -File $startScript -ProjectPath $projectRoot -NoLaunch -PostRestartDirective $pauseDirective 2>&1

$promptContent = Get-Content -LiteralPath $promptPath -Raw -Encoding UTF8

# Verify custom directive appears
if ($promptContent -notmatch [regex]::Escape($pauseDirective)) {
    Write-Fail "Custom directive not found with pause-and-confirm"
    exit 1
}

# Verify pause-and-confirm also appears
if ($promptContent -notmatch 'PAUSE-AND-CONFIRM|Session-loaded files changed|Session-Loaded Files Changed') {
    Write-Fail "Pause-and-confirm directive missing"
    exit 1
}

# Verify directive comes before pause message (rough check - custom directive should appear earlier)
$directiveIndex = $promptContent.IndexOf($pauseDirective)
$pauseIndex = $promptContent.IndexOf('Session-Loaded Files Changed', [System.StringComparison]::OrdinalIgnoreCase)
if ($pauseIndex -lt 0) {
    $pauseIndex = $promptContent.IndexOf('Session-loaded files changed', [System.StringComparison]::OrdinalIgnoreCase)
}

if ($directiveIndex -lt 0 -or $pauseIndex -lt 0) {
    Write-Fail "Could not find both directive and pause message for ordering check"
    exit 1
}

if ($directiveIndex -gt $pauseIndex) {
    Write-Fail "Custom directive appears after pause message (should be before)"
    exit 1
}

Write-Pass "Custom directive prepended before pause-and-confirm"

Write-Host ""
Write-Host "All parameter handling tests passed" -ForegroundColor Green
exit 0
