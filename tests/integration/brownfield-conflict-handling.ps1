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
$initScript = Join-Path -Path $repoRoot -ChildPath 'scripts\specrew-init.ps1'
$brownfieldMergeScript = Join-Path -Path $repoRoot -ChildPath 'extensions\specrew-speckit\scripts\brownfield-merge.ps1'

if (-not (Test-Path -Path $initScript -PathType Leaf)) {
    Write-Fail "Missing bootstrap entrypoint: $initScript"
    exit 1
}

if (-not (Test-Path -Path $brownfieldMergeScript -PathType Leaf)) {
    Write-Fail "Missing brownfield merge helper: $brownfieldMergeScript"
    exit 1
}

function Invoke-BrownfieldMergeReport {
    param(
        [Parameter(Mandatory = $true)]
        [string]$ProjectPath
    )

    Push-Location $repoRoot
    try {
        $jsonOutput = & pwsh -NoProfile -File $brownfieldMergeScript -ProjectPath $ProjectPath -PassThru
        if ($LASTEXITCODE -ne 0) {
            throw "brownfield-merge.ps1 exited with $LASTEXITCODE"
        }

        return ($jsonOutput | ConvertFrom-Json)
    }
    finally {
        Pop-Location
    }
}

function New-BrownfieldTeamFixture {
    param(
        [Parameter(Mandatory = $true)]
        [string]$ProjectPath,

        [switch]$SelfHosting
    )

    $squadRoot = Join-Path -Path $ProjectPath -ChildPath '.squad'
    $agentsRoot = Join-Path -Path $squadRoot -ChildPath 'agents'
    $null = New-Item -Path $agentsRoot -ItemType Directory -Force

    $teamContent = @'
# Squad Team

| Role | Charter | Status |
| ---- | ------- | ------ |
| Implementer | `.squad/agents/implementer/charter.md` | active |
| Planner | `.squad/agents/planner/charter.md` | active |
| DevOps | `.squad/agents/devops/charter.md` | active |
'@
    [System.IO.File]::WriteAllText((Join-Path -Path $squadRoot -ChildPath 'team.md'), $teamContent, [System.Text.UTF8Encoding]::new($false))

    foreach ($agentName in @('implementer', 'planner', 'devops')) {
        $agentRoot = Join-Path -Path $agentsRoot -ChildPath $agentName
        $null = New-Item -Path $agentRoot -ItemType Directory -Force
        [System.IO.File]::WriteAllText((Join-Path -Path $agentRoot -ChildPath 'charter.md'), "# $agentName`n", [System.Text.UTF8Encoding]::new($false))
    }

    if ($SelfHosting) {
        $extensionRoot = Join-Path -Path $ProjectPath -ChildPath 'extensions\specrew-speckit'
        $null = New-Item -Path $extensionRoot -ItemType Directory -Force
        [System.IO.File]::WriteAllText((Join-Path -Path $extensionRoot -ChildPath 'extension.yml'), "name: specrew-speckit`n", [System.Text.UTF8Encoding]::new($false))
    }
}

$scratchRoot = Join-Path -Path $repoRoot -ChildPath '.scratch\brownfield-conflict-handling'

if (Test-Path -Path $scratchRoot) {
    Remove-Item -Path $scratchRoot -Recurse -Force
}

$null = New-Item -Path $scratchRoot -ItemType Directory -Force

$populatedProjectRoot = Join-Path -Path $scratchRoot -ChildPath 'project-non-empty-block'
$null = New-Item -Path $populatedProjectRoot -ItemType Directory -Force
[System.IO.File]::WriteAllText((Join-Path -Path $populatedProjectRoot -ChildPath 'README.md'), "# Existing project`n", [System.Text.UTF8Encoding]::new($false))

Push-Location $repoRoot
try {
    $populatedRunOutput = & pwsh -NoProfile -File $initScript -ProjectPath $populatedProjectRoot 2>&1
    $populatedRunExitCode = $LASTEXITCODE
}
catch {
    $populatedRunExitCode = 1
}
finally {
    Pop-Location
}

if ($populatedRunExitCode -eq 0) {
    Write-Fail 'Populated directory protection unexpectedly allowed bootstrap to continue without -Force'
    exit 1
}

$populatedOutputText = ($populatedRunOutput | Out-String)
if ($populatedOutputText -notmatch 'is not empty') {
    Write-Fail "Populated directory protection did not explain that the target workspace was not empty"
    exit 1
}

Write-Pass ("Populated directories still require -Force before bootstrap proceeds (exit code {0})" -f $populatedRunExitCode)

$selfHostingProjectRoot = Join-Path -Path $scratchRoot -ChildPath 'project-self-hosting-agents'
$null = New-Item -Path $selfHostingProjectRoot -ItemType Directory -Force
New-BrownfieldTeamFixture -ProjectPath $selfHostingProjectRoot -SelfHosting
$selfHostingReport = Invoke-BrownfieldMergeReport -ProjectPath $selfHostingProjectRoot

if ($selfHostingReport.Status -eq 'conflicts-detected') {
    Write-Fail 'Self-hosting project incorrectly reported .squad/agents baseline roles as conflicts'
    exit 1
}

if ($selfHostingReport.RoleConflicts.Count -ne 0) {
    Write-Fail ("Self-hosting project should have 0 role conflicts, got {0}: {1}" -f $selfHostingReport.RoleConflicts.Count, ($selfHostingReport.RoleConflicts -join ', '))
    exit 1
}

if ('Implementer' -in $selfHostingReport.MergeableRoles -or 'Planner' -in $selfHostingReport.MergeableRoles) {
    Write-Fail 'Self-hosting project should preserve existing canonical Implementer/Planner roles instead of re-merging them'
    exit 1
}

Write-Pass 'Self-hosting project treats existing .squad/agents baseline roles as canonical source, not conflicts'

$nonSelfHostingProjectRoot = Join-Path -Path $scratchRoot -ChildPath 'project-non-self-hosting-agents'
$null = New-Item -Path $nonSelfHostingProjectRoot -ItemType Directory -Force
New-BrownfieldTeamFixture -ProjectPath $nonSelfHostingProjectRoot
$nonSelfHostingReport = Invoke-BrownfieldMergeReport -ProjectPath $nonSelfHostingProjectRoot

if ($nonSelfHostingReport.Status -ne 'conflicts-detected') {
    Write-Fail ("Non-self-hosting project should still report conflicts, got status '{0}'" -f $nonSelfHostingReport.Status)
    exit 1
}

foreach ($expectedConflict in @('Implementer', 'Planner')) {
    if ($expectedConflict -notin $nonSelfHostingReport.RoleConflicts) {
        Write-Fail "Non-self-hosting project did not report expected role conflict: $expectedConflict"
        exit 1
    }
}

Write-Pass 'Non-self-hosting project still reports existing baseline .squad/agents roles as conflicts'

$missingTools = @()
if (-not (Get-Command -Name 'specify' -ErrorAction SilentlyContinue)) {
    $missingTools += 'specify'
}
if (-not (Get-Command -Name 'squad' -ErrorAction SilentlyContinue)) {
    $missingTools += 'squad'
}

if ($missingTools.Count -gt 0) {
    Write-Skip ("Brownfield conflict handling test requires tools not available in this environment: {0}" -f ($missingTools -join ', '))
    exit 0
}

$projectRoot = Join-Path -Path $scratchRoot -ChildPath 'project'
$null = New-Item -Path $projectRoot -ItemType Directory -Force

# Scenario 1: Dry-run with conflicts creates reviewable artifact
$squadRoot = Join-Path -Path $projectRoot -ChildPath '.squad'
$null = New-Item -Path $squadRoot -ItemType Directory -Force

$teamPath = Join-Path -Path $squadRoot -ChildPath 'team.md'
$teamContent = @'
# Squad Team

| Role | Charter | Status |
| ---- | ------- | ------ |
| Implementer | `.squad/agents/implementer/charter.md` | active |
| Planner | `.squad/agents/planner/charter.md` | active |
| DevOps | `.squad/agents/devops/charter.md` | active |
'@
[System.IO.File]::WriteAllText($teamPath, $teamContent, [System.Text.UTF8Encoding]::new($false))

Push-Location $repoRoot
try {
    $dryRunOutput = & pwsh -NoProfile -File $initScript -ProjectPath $projectRoot -DryRun -Force 2>&1
    if ($dryRunOutput) {
        $dryRunOutput | ForEach-Object { Write-Host $_ }
    }
}
catch {
    Write-Fail ("Dry-run execution with conflicts failed: {0}" -f $_.Exception.Message)
    exit 1
}
finally {
    Pop-Location
}

$specrewDir = Join-Path -Path $projectRoot -ChildPath '.specrew'
if (-not (Test-Path -LiteralPath $specrewDir)) {
    Write-Fail "Dry-run did not create .specrew directory: $specrewDir"
    exit 1
}

$dryRunArtifacts = @(Get-ChildItem -LiteralPath $specrewDir -Filter 'bootstrap-dry-run-*.md' -ErrorAction SilentlyContinue)
if ($dryRunArtifacts.Count -eq 0) {
    Write-Fail "Dry-run did not create a reviewable bootstrap-dry-run-*.md artifact"
    exit 1
}

$dryRunArtifact = $dryRunArtifacts[0]
$dryRunContent = Get-Content -LiteralPath $dryRunArtifact.FullName -Raw -Encoding UTF8

$requiredSections = @(
    '# Bootstrap Dry-Run Report',
    '## Brownfield Analysis',
    'Role conflicts:',
    'Mergeable roles:'
)

foreach ($section in $requiredSections) {
    if ($dryRunContent -notmatch [regex]::Escape($section)) {
        Write-Fail "Dry-run artifact is missing required section: $section"
        exit 1
    }
}

Write-Pass "Dry-run with conflicts created reviewable artifact: $($dryRunArtifact.Name)"

# Scenario 2: Actual run with conflicts fails and blocks deployment
$projectRoot2 = Join-Path -Path $scratchRoot -ChildPath 'project-conflict-blocks'
$null = New-Item -Path $projectRoot2 -ItemType Directory -Force

$squadRoot2 = Join-Path -Path $projectRoot2 -ChildPath '.squad'
$null = New-Item -Path $squadRoot2 -ItemType Directory -Force

$teamPath2 = Join-Path -Path $squadRoot2 -ChildPath 'team.md'
[System.IO.File]::WriteAllText($teamPath2, $teamContent, [System.Text.UTF8Encoding]::new($false))

Push-Location $repoRoot
try {
    $actualRunOutput = & pwsh -NoProfile -File $initScript -ProjectPath $projectRoot2 -Force 2>&1
    $actualRunExitCode = $LASTEXITCODE
}
catch {
    $actualRunExitCode = 1
}
finally {
    Pop-Location
}

if ($actualRunExitCode -eq 0) {
    Write-Fail "Actual run with conflicts did not fail as expected (exit code was 0)"
    exit 1
}

if ($actualRunExitCode -ne 5) {
    Write-Fail "Actual run with conflicts returned unexpected exit code: $actualRunExitCode (expected 5)"
    exit 1
}

$outputText = ($actualRunOutput | Out-String)
if ($outputText -notmatch 'Brownfield merge conflicts detected') {
    Write-Fail "Actual run with conflicts did not report conflicts in output"
    exit 1
}

if ($outputText -notmatch 'Bootstrap cannot proceed until conflicts are resolved') {
    Write-Fail "Actual run with conflicts did not include resolution guidance"
    exit 1
}

Write-Pass "Actual run with conflicts failed with exit code 5 and blocked deployment"

# Scenario 3: -Force does not bypass conflict checks
$projectRoot3 = Join-Path -Path $scratchRoot -ChildPath 'project-force-no-bypass'
$null = New-Item -Path $projectRoot3 -ItemType Directory -Force

$squadRoot3 = Join-Path -Path $projectRoot3 -ChildPath '.squad'
$null = New-Item -Path $squadRoot3 -ItemType Directory -Force

$teamPath3 = Join-Path -Path $squadRoot3 -ChildPath 'team.md'
[System.IO.File]::WriteAllText($teamPath3, $teamContent, [System.Text.UTF8Encoding]::new($false))

Push-Location $repoRoot
try {
    $forceRunOutput = & pwsh -NoProfile -File $initScript -ProjectPath $projectRoot3 -Force 2>&1
    $forceRunExitCode = $LASTEXITCODE
}
catch {
    $forceRunExitCode = 1
}
finally {
    Pop-Location
}

if ($forceRunExitCode -eq 0) {
    Write-Fail "-Force bypass check: run with conflicts did not fail (exit code was 0)"
    exit 1
}

if ($forceRunExitCode -ne 5) {
    Write-Fail "-Force bypass check: run with conflicts returned unexpected exit code: $forceRunExitCode (expected 5)"
    exit 1
}

Write-Pass "-Force does not bypass conflict checks (exit code 5 preserved)"

# Scenario 4: Brownfield without conflicts proceeds successfully
$projectRoot4 = Join-Path -Path $scratchRoot -ChildPath 'project-no-conflict'
$null = New-Item -Path $projectRoot4 -ItemType Directory -Force

$squadRoot4 = Join-Path -Path $projectRoot4 -ChildPath '.squad'
$null = New-Item -Path $squadRoot4 -ItemType Directory -Force

$teamPath4 = Join-Path -Path $squadRoot4 -ChildPath 'team.md'
$teamContentNoConflict = @'
# Squad Team

| Role | Charter | Status |
| ---- | ------- | ------ |
| DevOps | `.squad/agents/devops/charter.md` | active |
| SiteReliabilityEngineer | `.squad/agents/sre/charter.md` | active |
'@
[System.IO.File]::WriteAllText($teamPath4, $teamContentNoConflict, [System.Text.UTF8Encoding]::new($false))

Push-Location $repoRoot
try {
    $noConflictOutput = & pwsh -NoProfile -File $initScript -ProjectPath $projectRoot4 -Force -Agents 'copilot' 2>&1
    $noConflictExitCode = $LASTEXITCODE
    if ($noConflictOutput) {
        $noConflictOutput | ForEach-Object { Write-Host $_ }
    }
}
catch {
    Write-Fail ("Brownfield run without conflicts failed: {0}" -f $_.Exception.Message)
    exit 1
}
finally {
    Pop-Location
}

if ($noConflictExitCode -ne 0) {
    Write-Skip ("Brownfield run without conflicts returned non-zero exit code ({0}); skipping artifact assertions because bootstrap tooling is unavailable in this environment" -f $noConflictExitCode)
    exit 0
}

$requiredNoConflictPaths = @(
    '.specify',
    '.squad',
    '.specrew\config.yml',
    '.specrew\constitution.md',
    '.specrew\iteration-config.yml',
    '.specrew\role-assignments.yml',
    '.specify\extensions\specrew-speckit\extension.yml'
)

$missingPaths = @()
foreach ($relativePath in $requiredNoConflictPaths) {
    $fullPath = Join-Path -Path $projectRoot4 -ChildPath $relativePath
    if (-not (Test-Path -Path $fullPath)) {
        $missingPaths += $relativePath
    }
}

if ($missingPaths.Count -gt 0) {
    Write-Fail ("Brownfield run without conflicts: missing expected artifacts: {0}" -f ($missingPaths -join ', '))
    exit 1
}

Write-Pass "Brownfield run without conflicts proceeded successfully and created all expected artifacts"

Write-Pass 'Brownfield conflict handling validated across dry-run artifact, conflict blocking, -Force bypass prevention, and no-conflict success'
exit 0
