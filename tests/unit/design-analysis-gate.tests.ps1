[CmdletBinding()]
param()

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

function Write-Pass { param([string]$Message) Write-Host "PASS: $Message" -ForegroundColor Green }
function Write-Fail { param([string]$Message) Write-Host "FAIL: $Message" -ForegroundColor Red; exit 1 }

function Assert-True {
    param([bool]$Condition, [string]$Message)
    if (-not $Condition) { Write-Fail $Message }
}

function Assert-Match {
    param([string]$Text, [string]$Pattern, [string]$Message)
    if ($Text -notmatch $Pattern) { Write-Fail $Message }
}

function Assert-PowerShellParses {
    param([string]$Path)

    $tokens = $null
    $parseErrors = $null
    [System.Management.Automation.Language.Parser]::ParseFile($Path, [ref]$tokens, [ref]$parseErrors) | Out-Null
    $message = if ($parseErrors.Count -gt 0) { $parseErrors[0].Message } else { '' }
    Assert-True ($parseErrors.Count -eq 0) "$Path parse errors: $message"
}

function New-DesignAnalysisFixtureProject {
    param(
        [Parameter(Mandatory = $true)][string]$ProjectRoot,
        [string]$FeatureRef = '140-design-analysis-gate',
        [string]$SpecrewVersion = '0.30.0'
    )

    foreach ($relativeDirectory in @('.specrew', ('specs\{0}\iterations\001' -f $FeatureRef))) {
        $null = New-Item -ItemType Directory -Path (Join-Path $ProjectRoot $relativeDirectory) -Force
    }

    [System.IO.File]::WriteAllText((Join-Path $ProjectRoot '.specrew\config.yml'), ("specrew_version: `"{0}`"`n" -f $SpecrewVersion), [System.Text.UTF8Encoding]::new($false))
    [System.IO.File]::WriteAllText((Join-Path $ProjectRoot ("specs\{0}\spec.md" -f $FeatureRef)), @'
# Feature Specification: Design Gate

This substantive lifecycle governance feature changes boundary enforcement, helper validation, compatibility, and state behavior.
'@, [System.Text.UTF8Encoding]::new($false))
    [System.IO.File]::WriteAllText((Join-Path $ProjectRoot '.specrew\start-context.json'), (@{
            schema = 'v2'
            session_state = @{
                active = $true
                boundary_type = 'clarify'
                feature_ref = $FeatureRef
                iteration_number = '001'
            }
            boundary_enforcement = @{
                enabled = $true
                last_authorized_boundary = 'clarify'
            }
        } | ConvertTo-Json -Depth 8), [System.Text.UTF8Encoding]::new($false))
}

function Get-ValidDesignAnalysisFixture {
    return @'
# Design Analysis: Design Gate

## Problem Framing

The lifecycle must expose architecture alternatives before plan so substantive governance changes do not choose design implicitly.

## Key Design Decision Points

- Artifact validation must stay reusable.
- Plan-boundary enforcement must be active and narrow.

## Alternatives

### Option A: Simplest

- Approach: Add prompt-only guidance and ask the Crew to remember the stop.
- Architectural pattern: Prompt contract only.
- Quality features considered: Maintainability is simple, but enforcement is weak.
- Effort estimate: 1 story point.
- Reversibility cost: Low.
- Trade-offs: Cheap to ship but does not block missing evidence.
- Diagram:

```mermaid
flowchart LR
  Prompt --> Plan
```

### Option B: Reasonable

- Approach: Add a helper plus active plan-boundary sync enforcement.
- Architectural pattern: Reusable validation helper consumed by boundary sync.
- Quality features considered: Maintains compatibility while adding fail-closed behavior.
- Effort estimate: 5 story points.
- Reversibility cost: Moderate.
- Trade-offs: Touches lifecycle code but gives durable enforcement.
- Diagram:

```mermaid
flowchart LR
  Artifact --> Helper --> Sync
```

By-the-book option is not meaningfully distinct in this slice because full Proposal 137 command deployment is deferred.

## Crew Recommendation

Recommend Option B because it blocks missing decision evidence without broad rollout.

## Human Decision

Verdict: approved for plan with Option B.
Reason: Preserve narrow active-boundary enforcement and defer full command rollout.
Commit Hash: 9c301637
'@
}

$repoRoot = (Resolve-Path (Join-Path $PSScriptRoot '..\..')).Path
$helperPath = Join-Path $repoRoot 'scripts\internal\design-analysis-gate.ps1'
$syncPath = Join-Path $repoRoot 'scripts\internal\sync-boundary-state.ps1'
$startPath = Join-Path $repoRoot 'scripts\specrew-start.ps1'

Assert-PowerShellParses -Path $helperPath
Assert-PowerShellParses -Path $syncPath
Assert-PowerShellParses -Path $startPath
Write-Pass 'Design-analysis PowerShell surfaces parse'

. $helperPath

$scratchRoot = Join-Path $repoRoot '.scratch\design-analysis-gate-unit'
if (Test-Path -LiteralPath $scratchRoot) {
    Remove-Item -LiteralPath $scratchRoot -Recurse -Force
}
$null = New-Item -ItemType Directory -Path $scratchRoot -Force

$projectRoot = Join-Path $scratchRoot 'valid'
New-DesignAnalysisFixtureProject -ProjectRoot $projectRoot
$artifactPath = Get-SpecrewDesignAnalysisArtifactPath -ProjectRoot $projectRoot -FeatureRef '140-design-analysis-gate' -IterationNumber '001'
[System.IO.File]::WriteAllText($artifactPath, (Get-ValidDesignAnalysisFixture), [System.Text.UTF8Encoding]::new($false))

$validResult = Test-SpecrewDesignAnalysisArtifact -ProjectRoot $projectRoot -FeatureRef '140-design-analysis-gate' -IterationNumber '001'
Assert-True $validResult.Valid ("Valid artifact failed: {0}" -f ($validResult.Errors -join '; '))
Assert-True ($validResult.SelectedOption -eq 'Option B') 'Valid artifact did not extract Option B as the human-selected option.'
Assert-True (Test-SpecrewDesignAnalysisGateRequired -ProjectRoot $projectRoot -FeatureRef '140-design-analysis-gate' -IterationNumber '001') 'Active substantive fixture should require design analysis.'
Write-Pass 'Valid design-analysis artifact passes and extracts selected option'

$missingProject = Join-Path $scratchRoot 'missing'
New-DesignAnalysisFixtureProject -ProjectRoot $missingProject
$missingResult = Test-SpecrewDesignAnalysisArtifact -ProjectRoot $missingProject -FeatureRef '140-design-analysis-gate' -IterationNumber '001'
Assert-True (-not $missingResult.Valid) 'Missing artifact unexpectedly passed.'
Assert-Match -Text ($missingResult.Errors -join "`n") -Pattern 'Missing design-analysis artifact' 'Missing artifact error was not actionable.'
Write-Pass 'Missing artifact is rejected'

$sectionProject = Join-Path $scratchRoot 'missing-section'
New-DesignAnalysisFixtureProject -ProjectRoot $sectionProject
[System.IO.File]::WriteAllText((Get-SpecrewDesignAnalysisArtifactPath -ProjectRoot $sectionProject -FeatureRef '140-design-analysis-gate' -IterationNumber '001'), ((Get-ValidDesignAnalysisFixture) -replace '(?ms)^## Problem Framing.*?(?=^## Key Design Decision Points)', ''), [System.Text.UTF8Encoding]::new($false))
$sectionResult = Test-SpecrewDesignAnalysisArtifact -ProjectRoot $sectionProject -FeatureRef '140-design-analysis-gate' -IterationNumber '001'
Assert-True (-not $sectionResult.Valid) 'Artifact missing Problem Framing unexpectedly passed.'
Assert-Match -Text ($sectionResult.Errors -join "`n") -Pattern 'Problem Framing' 'Missing section error did not name Problem Framing.'
Write-Pass 'Missing required section is rejected'

$oneOptionProject = Join-Path $scratchRoot 'one-option'
New-DesignAnalysisFixtureProject -ProjectRoot $oneOptionProject
$oneOption = (Get-ValidDesignAnalysisFixture) -replace '(?ms)^### Option B: Reasonable.*?By-the-book option is not meaningfully distinct', 'By-the-book option is not meaningfully distinct'
[System.IO.File]::WriteAllText((Get-SpecrewDesignAnalysisArtifactPath -ProjectRoot $oneOptionProject -FeatureRef '140-design-analysis-gate' -IterationNumber '001'), $oneOption, [System.Text.UTF8Encoding]::new($false))
$oneOptionResult = Test-SpecrewDesignAnalysisArtifact -ProjectRoot $oneOptionProject -FeatureRef '140-design-analysis-gate' -IterationNumber '001'
Assert-True (-not $oneOptionResult.Valid) 'One-option artifact unexpectedly passed.'
Assert-Match -Text ($oneOptionResult.Errors -join "`n") -Pattern 'Reasonable option' 'One-option error did not identify missing Reasonable option.'
Write-Pass 'One-option artifact is rejected'

$missingFieldProject = Join-Path $scratchRoot 'missing-field'
New-DesignAnalysisFixtureProject -ProjectRoot $missingFieldProject
$missingField = (Get-ValidDesignAnalysisFixture) -replace '(?m)^- Reversibility cost: Moderate\.\r?\n', ''
[System.IO.File]::WriteAllText((Get-SpecrewDesignAnalysisArtifactPath -ProjectRoot $missingFieldProject -FeatureRef '140-design-analysis-gate' -IterationNumber '001'), $missingField, [System.Text.UTF8Encoding]::new($false))
$missingFieldResult = Test-SpecrewDesignAnalysisArtifact -ProjectRoot $missingFieldProject -FeatureRef '140-design-analysis-gate' -IterationNumber '001'
Assert-True (-not $missingFieldResult.Valid) 'Missing option field artifact unexpectedly passed.'
Assert-Match -Text ($missingFieldResult.Errors -join "`n") -Pattern 'Reversibility cost' 'Missing field error did not name Reversibility cost.'
Write-Pass 'Missing option field is rejected'

$missingRecommendationProject = Join-Path $scratchRoot 'missing-recommendation'
New-DesignAnalysisFixtureProject -ProjectRoot $missingRecommendationProject
$missingRecommendation = (Get-ValidDesignAnalysisFixture) -replace '(?ms)^## Crew Recommendation.*?(?=^## Human Decision)', "## Crew Recommendation`n`nTBD`n`n"
[System.IO.File]::WriteAllText((Get-SpecrewDesignAnalysisArtifactPath -ProjectRoot $missingRecommendationProject -FeatureRef '140-design-analysis-gate' -IterationNumber '001'), $missingRecommendation, [System.Text.UTF8Encoding]::new($false))
$missingRecommendationResult = Test-SpecrewDesignAnalysisArtifact -ProjectRoot $missingRecommendationProject -FeatureRef '140-design-analysis-gate' -IterationNumber '001'
Assert-True (-not $missingRecommendationResult.Valid) 'Placeholder Crew Recommendation unexpectedly passed.'
Assert-Match -Text ($missingRecommendationResult.Errors -join "`n") -Pattern 'Crew Recommendation' 'Recommendation failure did not name Crew Recommendation.'
Write-Pass 'Placeholder recommendation is rejected'

$missingHumanProject = Join-Path $scratchRoot 'missing-human-decision'
New-DesignAnalysisFixtureProject -ProjectRoot $missingHumanProject
$missingHuman = (Get-ValidDesignAnalysisFixture) -replace '(?ms)^## Human Decision.*', "## Human Decision`n`nPending`n"
[System.IO.File]::WriteAllText((Get-SpecrewDesignAnalysisArtifactPath -ProjectRoot $missingHumanProject -FeatureRef '140-design-analysis-gate' -IterationNumber '001'), $missingHuman, [System.Text.UTF8Encoding]::new($false))
$missingHumanResult = Test-SpecrewDesignAnalysisArtifact -ProjectRoot $missingHumanProject -FeatureRef '140-design-analysis-gate' -IterationNumber '001'
Assert-True (-not $missingHumanResult.Valid) 'Placeholder Human Decision unexpectedly passed.'
Assert-Match -Text ($missingHumanResult.Errors -join "`n") -Pattern 'Human Decision' 'Human decision failure did not name Human Decision.'
Write-Pass 'Missing human decision is rejected'

$missingCommitProject = Join-Path $scratchRoot 'missing-commit'
New-DesignAnalysisFixtureProject -ProjectRoot $missingCommitProject
$missingCommit = (Get-ValidDesignAnalysisFixture) -replace '(?m)^Commit Hash: [0-9a-f]+(?:\r?\n)?', ''
[System.IO.File]::WriteAllText((Get-SpecrewDesignAnalysisArtifactPath -ProjectRoot $missingCommitProject -FeatureRef '140-design-analysis-gate' -IterationNumber '001'), $missingCommit, [System.Text.UTF8Encoding]::new($false))
$missingCommitResult = Test-SpecrewDesignAnalysisArtifact -ProjectRoot $missingCommitProject -FeatureRef '140-design-analysis-gate' -IterationNumber '001'
Assert-True (-not $missingCommitResult.Valid) 'Human Decision without commit hash unexpectedly passed.'
Assert-Match -Text ($missingCommitResult.Errors -join "`n") -Pattern 'commit hash' 'Missing commit failure did not mention commit hash.'
Write-Pass 'Missing decision commit hash is rejected'

$legacyProject = Join-Path $scratchRoot 'legacy'
New-DesignAnalysisFixtureProject -ProjectRoot $legacyProject -SpecrewVersion '0.0.0'
Assert-True (-not (Test-SpecrewDesignAnalysisGateRequired -ProjectRoot $legacyProject -FeatureRef '140-design-analysis-gate' -IterationNumber '001')) 'Legacy version fixture should not require the new gate without an artifact.'
Write-Pass 'Legacy compatibility fixture does not require the new gate'

$startScript = Get-Content -LiteralPath $startPath -Raw -Encoding UTF8
Assert-Match -Text $startScript -Pattern 'design-analysis stop for substantive features' 'Generated lifecycle guidance is missing the design-analysis flow insertion.'
Assert-Match -Text $startScript -Pattern 'approved for plan with Option <X>' 'Generated lifecycle guidance is missing the explicit option-verdict shape.'
Assert-Match -Text $startScript -Pattern 'Human Decision must record the chosen option' 'Generated lifecycle guidance is missing Human Decision evidence requirements.'
Write-Pass 'Lifecycle guidance mentions design-analysis stop and verdict shape'

Write-Pass 'Design-analysis gate unit tests passed'
exit 0
