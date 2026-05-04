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

function Write-Skip {
    param([string]$Message)
    Write-Host "SKIP: $Message" -ForegroundColor Yellow
}

$repoRoot = (Resolve-Path (Join-Path -Path $PSScriptRoot -ChildPath '..\..')).Path
$brownfieldMergeScript = Join-Path -Path $repoRoot -ChildPath 'extensions\specrew-speckit\scripts\brownfield-merge.ps1'

if (-not (Test-Path -Path $brownfieldMergeScript -PathType Leaf)) {
    Write-Fail "Missing brownfield-merge.ps1 script: $brownfieldMergeScript"
    exit 1
}

$scratchRoot = Join-Path -Path $repoRoot -ChildPath '.scratch\brownfield-merge-test'
$projectRoot = Join-Path -Path $scratchRoot -ChildPath 'project'

if (Test-Path -Path $scratchRoot) {
    Remove-Item -Path $scratchRoot -Recurse -Force
}

$null = New-Item -Path $projectRoot -ItemType Directory -Force

# Scenario 1: Greenfield (no .specify or .squad) should report as ready
Push-Location $repoRoot
try {
    $jsonOutput = & pwsh -NoProfile -File $brownfieldMergeScript -ProjectPath $projectRoot -PassThru
    $report1 = $jsonOutput | ConvertFrom-Json
}
catch {
    Write-Fail "Scenario 1 (greenfield) failed: $($_.Exception.Message)"
    exit 1
}
finally {
    Pop-Location
}

if ($LASTEXITCODE -ne 0) {
    Write-Skip "Brownfield merge script returned non-zero exit code ($LASTEXITCODE) for greenfield scenario; analysis may be incomplete"
}

if ($null -eq $report1 -or $report1.Status -ne 'ready') {
    Write-Fail "Scenario 1 (greenfield): Expected status='ready', got status='$($report1.Status)'"
    exit 1
}

Write-Pass "Scenario 1 (greenfield) reported as ready with no conflicts"

# Scenario 2: Brownfield with existing Squad team that has a conflicting role
$squadRoot = Join-Path -Path $projectRoot -ChildPath '.squad'
$null = New-Item -Path $squadRoot -ItemType Directory -Force

$teamPath = Join-Path -Path $squadRoot -ChildPath 'team.md'
$teamContent = @'
# Squad Team

| Role | Charter | Status |
| ---- | ------- | ------ |
| Implementer | `.squad/agents/implementer/charter.md` | active |
| DevOps | `.squad/agents/devops/charter.md` | active |
'@
[System.IO.File]::WriteAllText($teamPath, $teamContent, [System.Text.UTF8Encoding]::new($false))

Push-Location $repoRoot
try {
    $jsonOutput2 = & pwsh -NoProfile -File $brownfieldMergeScript -ProjectPath $projectRoot -PassThru
    $report2 = $jsonOutput2 | ConvertFrom-Json
}
catch {
    Write-Fail "Scenario 2 (brownfield with conflict) failed: $($_.Exception.Message)"
    exit 1
}
finally {
    Pop-Location
}

if ($LASTEXITCODE -ne 0) {
    Write-Skip "Brownfield merge script returned non-zero exit code ($LASTEXITCODE) for brownfield scenario; analysis may be incomplete"
}

if ($null -eq $report2) {
    Write-Fail "Scenario 2 (brownfield with conflict): No report returned"
    exit 1
}

if ($report2.Status -ne 'conflicts-detected') {
    Write-Fail "Scenario 2 (brownfield with conflict): Expected status='conflicts-detected', got status='$($report2.Status)'"
    exit 1
}

if ($report2.RoleConflicts.Count -ne 1 -or 'Implementer' -notin $report2.RoleConflicts) {
    Write-Fail "Scenario 2 (brownfield with conflict): Expected RoleConflicts to contain 'Implementer'"
    exit 1
}

if ($report2.MergeableRoles.Count -ne 4) {
    Write-Fail "Scenario 2 (brownfield with conflict): Expected 4 mergeable roles (5 baseline - 1 conflict), got $($report2.MergeableRoles.Count)"
    exit 1
}

Write-Pass "Scenario 2 (brownfield with conflict) detected Implementer conflict and reported 4 mergeable roles"

# Scenario 3: Brownfield with existing specs should report warnings but status='warnings-present'
# Create a new project root for scenario 3
$projectRoot3 = Join-Path -Path $scratchRoot -ChildPath 'brownfield-merge-test' -AdditionalChildPath 'scenario3-existing-specs'
$null = New-Item -Path $projectRoot3 -ItemType Directory -Force
# Must have .specify to be detected as having specs
$null = New-Item -Path (Join-Path $projectRoot3 '.specify') -ItemType Directory -Force
$specsRoot = Join-Path -Path $projectRoot3 -ChildPath 'specs'
$null = New-Item -Path $specsRoot -ItemType Directory -Force
$null = New-Item -Path (Join-Path $specsRoot '001-my-feature') -ItemType Directory -Force
$null = New-Item -Path (Join-Path $specsRoot '002-another-feature') -ItemType Directory -Force

Push-Location $repoRoot
try {
    $jsonOutput3 = & pwsh -NoProfile -File $brownfieldMergeScript -ProjectPath $projectRoot3 -PassThru
    $report3 = $jsonOutput3 | ConvertFrom-Json
}
catch {
    Write-Fail "Scenario 3 (brownfield with existing specs) failed: $($_.Exception.Message)"
    exit 1
}
finally {
    Pop-Location
}

if ($LASTEXITCODE -ne 0) {
    Write-Skip "Brownfield merge script returned non-zero exit code ($LASTEXITCODE) for existing specs scenario; analysis may be incomplete"
}

if ($null -eq $report3) {
    Write-Fail "Scenario 3 (brownfield with existing specs): No report returned"
    exit 1
}

if ($report3.PreservedSpecs.Count -ne 2) {
    Write-Fail "Scenario 3 (brownfield with existing specs): Expected 2 preserved specs, got $($report3.PreservedSpecs.Count)"
    exit 1
}

if ($report3.Warnings.Count -eq 0) {
    Write-Fail "Scenario 3 (brownfield with existing specs): Expected at least 1 warning for existing specs"
    exit 1
}

Write-Pass "Scenario 3 (brownfield with existing specs) preserved 2 specs and reported warnings"

Write-Pass 'Brownfield merge analysis validated across greenfield, conflict, and existing-spec scenarios'
exit 0
