[CmdletBinding()]
param()

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

function Write-Pass { param([string]$Message) Write-Host "PASS: $Message" -ForegroundColor Green }
function Write-Fail { param([string]$Message) Write-Host "FAIL: $Message" -ForegroundColor Red; exit 1 }

function Invoke-TestScript {
    param(
        [Parameter(Mandatory = $true)][string]$ScriptPath,
        [Parameter(Mandatory = $true)][string[]]$ArgumentList
    )

    $output = @(& pwsh -NoProfile -ExecutionPolicy Bypass -File $ScriptPath @ArgumentList 2>&1)
    return @{
        Output   = @($output | ForEach-Object { [string]$_ })
        ExitCode = $LASTEXITCODE
    }
}

function New-DesignAnalysisBoundaryProject {
    param(
        [Parameter(Mandatory = $true)][string]$ProjectRoot,
        [string]$FeatureRef = '140-design-analysis-gate',
        [string]$SpecrewVersion = '0.30.0',
        [string]$ContextBoundary = 'clarify',
        [string]$ContextFeatureRef = $FeatureRef
    )

    $null = New-Item -ItemType Directory -Path $ProjectRoot -Force
    $null = & git -C $ProjectRoot init --quiet 2>&1
    $null = & git -C $ProjectRoot config user.email 'test@specrew.local' 2>&1
    $null = & git -C $ProjectRoot config user.name 'Test User' 2>&1

    foreach ($relativeDirectory in @('.specrew', '.specify', '.squad', '.github\agents', ("specs\{0}\iterations\001" -f $FeatureRef))) {
        $null = New-Item -ItemType Directory -Path (Join-Path $ProjectRoot $relativeDirectory) -Force
    }

    [System.IO.File]::WriteAllText((Join-Path $ProjectRoot '.specrew\config.yml'), ("project_name: sample`nspecrew_version: `"{0}`"`nbootstrap_date: `"2026-01-01`"`n" -f $SpecrewVersion), [System.Text.UTF8Encoding]::new($false))
    [System.IO.File]::WriteAllText((Join-Path $ProjectRoot '.specify\feature.json'), ("{{`n  `"feature_directory`": `"specs/{0}`"`n}}`n" -f $FeatureRef), [System.Text.UTF8Encoding]::new($false))
    [System.IO.File]::WriteAllText((Join-Path $ProjectRoot '.squad\team.md'), "# Team`n", [System.Text.UTF8Encoding]::new($false))
    [System.IO.File]::WriteAllText((Join-Path $ProjectRoot '.squad\config.json'), "{}`n", [System.Text.UTF8Encoding]::new($false))
    [System.IO.File]::WriteAllText((Join-Path $ProjectRoot '.squad\decisions.md'), "# Decisions`n", [System.Text.UTF8Encoding]::new($false))
    [System.IO.File]::WriteAllText((Join-Path $ProjectRoot '.github\agents\squad.agent.md'), "# Squad Agent`n", [System.Text.UTF8Encoding]::new($false))
    [System.IO.File]::WriteAllText((Join-Path $ProjectRoot ("specs\{0}\spec.md" -f $FeatureRef)), @'
# Feature Specification: Design Gate

This substantive lifecycle governance feature changes boundary enforcement, helper validation, compatibility, and state behavior.
'@, [System.Text.UTF8Encoding]::new($false))

    $context = [ordered]@{
        schema = 'v2'
        session_state = [ordered]@{
            active = $true
            boundary_type = $ContextBoundary
            feature_ref = $ContextFeatureRef
            feature_path = Join-Path $ProjectRoot ("specs\{0}" -f $ContextFeatureRef)
            iteration_number = '001'
            task_id = $null
            auth_commit_hash = 'SEEDHASH'
            recorded_at = '2026-06-02T00:00:00Z'
        }
        boundary_enforcement = [ordered]@{
            enabled = $true
            last_authorized_boundary = $ContextBoundary
            pending_next_boundary = $null
            verdict_history = @(
                [ordered]@{
                    from_boundary = 'specify'
                    to_boundary = $ContextBoundary
                    verdict_text = "approved for $ContextBoundary"
                    authorizing_human = 'Test User'
                    recorded_at = '2026-06-02T00:00:00Z'
                    auth_commit_hash = 'SEEDHASH'
                }
            )
            bypass_history = @()
        }
    }
    [System.IO.File]::WriteAllText((Join-Path $ProjectRoot '.specrew\start-context.json'), ($context | ConvertTo-Json -Depth 12), [System.Text.UTF8Encoding]::new($false))
    [System.IO.File]::WriteAllText((Join-Path $ProjectRoot 'README.md'), "# Test Repo`n", [System.Text.UTF8Encoding]::new($false))

    $null = & git -C $ProjectRoot add -A 2>&1
    $null = & git -C $ProjectRoot commit -m 'Seed design-analysis boundary project' --quiet 2>&1
    $null = & git -C $ProjectRoot branch -M main 2>&1
    $null = & git -C $ProjectRoot checkout -b $FeatureRef 2>&1
}

function Write-ValidDesignAnalysisArtifact {
    param(
        [Parameter(Mandatory = $true)][string]$ProjectRoot,
        [string]$FeatureRef = '140-design-analysis-gate'
    )

    $artifactPath = Join-Path $ProjectRoot ("specs\{0}\iterations\001\design-analysis.md" -f $FeatureRef)
    [System.IO.File]::WriteAllText($artifactPath, @'
# Design Analysis: Design Gate

## Problem Framing

The lifecycle needs visible design alternatives before planning locks in architecture.

## Key Design Decision Points

- Artifact validation must be reusable.
- Plan-boundary enforcement must be active and narrow.

## Alternatives

### Option A: Simplest

- Approach: Prompt-only discipline.
- Architectural pattern: Generated prompt guidance.
- Quality features considered: Simple maintenance, weak enforcement.
- Effort estimate: 1 story point.
- Reversibility cost: Low.
- Trade-offs: Cheap but does not block missing decisions.
- Diagram:

```mermaid
flowchart LR
  Prompt --> Plan
```

### Option B: Reasonable

- Approach: Helper plus active plan-boundary sync enforcement.
- Architectural pattern: Helper validation consumed by lifecycle sync.
- Quality features considered: Fail-closed evidence checks with narrow compatibility.
- Effort estimate: 5 story points.
- Reversibility cost: Moderate.
- Trade-offs: Touches shared sync code but proves the gate.
- Diagram:

```mermaid
flowchart LR
  Artifact --> Helper --> Sync
```

By-the-book option is not meaningfully distinct for this first slice because broad command deployment is deferred.

## Crew Recommendation

Recommend Option B because it adds enforcement without broad validator rollout.

## Human Decision

Verdict: approved for plan with Option B.
Reason: Keep active-iteration enforcement and defer broad rollout.
Commit Hash: 9c301637
'@, [System.Text.UTF8Encoding]::new($false))
}

$repoRoot = (Resolve-Path (Join-Path $PSScriptRoot '..\..')).Path
$env:SPECREW_MODULE_PATH = $repoRoot
$syncScript = Join-Path $repoRoot '.specify\extensions\specrew-speckit\scripts\sync-boundary-state.ps1'
$scratchRoot = Join-Path $repoRoot '.scratch\design-analysis-boundary'
if (Test-Path -LiteralPath $scratchRoot) {
    Remove-Item -LiteralPath $scratchRoot -Recurse -Force
}
$null = New-Item -ItemType Directory -Path $scratchRoot -Force

$blockedProject = Join-Path $scratchRoot 'blocked'
New-DesignAnalysisBoundaryProject -ProjectRoot $blockedProject
$blockedResult = Invoke-TestScript -ScriptPath $syncScript -ArgumentList @(
    '-ProjectPath', $blockedProject,
    '-BoundaryType', 'plan',
    '-FeatureRef', '140-design-analysis-gate',
    '-IterationNumber', '001',
    '-AuthCommitHash', 'HEAD'
)
$blockedOutput = $blockedResult.Output -join [Environment]::NewLine
if ($blockedResult.ExitCode -eq 0) {
    Write-Fail 'Plan boundary sync unexpectedly passed without design-analysis.md.'
}
foreach ($pattern in @('\[design-analysis-gate\]', 'design-analysis', 'Human Decision|Crew Recommendation|Missing design-analysis artifact')) {
    if ($blockedOutput -notmatch $pattern) {
        Write-Fail ("Blocked sync output is missing expected pattern '{0}':`n{1}" -f $pattern, $blockedOutput)
    }
}
$blockedContext = Get-Content -LiteralPath (Join-Path $blockedProject '.specrew\start-context.json') -Raw -Encoding UTF8 | ConvertFrom-Json -Depth 12
if ($blockedContext.session_state.boundary_type -ne 'clarify') {
    Write-Fail 'Failed design-analysis gate advanced start-context.json despite blocking plan sync.'
}
Write-Pass 'Active substantive plan sync blocks before state advancement when design-analysis.md is missing'

Write-ValidDesignAnalysisArtifact -ProjectRoot $blockedProject
$null = & git -C $blockedProject add -A 2>&1
$null = & git -C $blockedProject commit -m 'Add design-analysis decision artifact' --quiet 2>&1
$validAuth = (@(& git -C $blockedProject rev-parse HEAD 2>&1))[0].ToString().Trim()
$passResult = Invoke-TestScript -ScriptPath $syncScript -ArgumentList @(
    '-ProjectPath', $blockedProject,
    '-BoundaryType', 'plan',
    '-FeatureRef', '140-design-analysis-gate',
    '-IterationNumber', '001',
    '-AuthCommitHash', $validAuth
)
if ($passResult.ExitCode -ne 0) {
    Write-Fail ("Plan boundary sync failed after valid design-analysis artifact:`n{0}" -f ($passResult.Output -join [Environment]::NewLine))
}
$passedContext = Get-Content -LiteralPath (Join-Path $blockedProject '.specrew\start-context.json') -Raw -Encoding UTF8 | ConvertFrom-Json -Depth 12
if ($passedContext.session_state.boundary_type -ne 'plan') {
    Write-Fail 'Valid design-analysis artifact did not allow plan boundary advancement.'
}
Write-Pass 'Active substantive plan sync passes after valid recommendation and Human Decision evidence'

$legacyProject = Join-Path $scratchRoot 'legacy'
New-DesignAnalysisBoundaryProject -ProjectRoot $legacyProject -SpecrewVersion '0.0.0'
$legacyResult = Invoke-TestScript -ScriptPath $syncScript -ArgumentList @(
    '-ProjectPath', $legacyProject,
    '-BoundaryType', 'plan',
    '-FeatureRef', '140-design-analysis-gate',
    '-IterationNumber', '001',
    '-AuthCommitHash', 'HEAD'
)
if ($legacyResult.ExitCode -ne 0) {
    Write-Fail ("Legacy compatibility plan sync should pass without a design-analysis artifact:`n{0}" -f ($legacyResult.Output -join [Environment]::NewLine))
}
Write-Pass 'Legacy compatibility path does not hard-fail old projects without design-analysis.md'

$otherActiveProject = Join-Path $scratchRoot 'other-active-feature'
New-DesignAnalysisBoundaryProject -ProjectRoot $otherActiveProject -ContextFeatureRef '139-existing-inflight'
$otherActiveResult = Invoke-TestScript -ScriptPath $syncScript -ArgumentList @(
    '-ProjectPath', $otherActiveProject,
    '-BoundaryType', 'plan',
    '-FeatureRef', '140-design-analysis-gate',
    '-IterationNumber', '001',
    '-AuthCommitHash', 'HEAD'
)
if ($otherActiveResult.ExitCode -ne 0) {
    Write-Fail ("Non-active feature plan sync should not be blocked by the active design-analysis gate:`n{0}" -f ($otherActiveResult.Output -join [Environment]::NewLine))
}
Write-Pass 'Design-analysis enforcement is scoped to the active feature/iteration'

Write-Pass 'Design-analysis boundary integration tests passed'
exit 0
