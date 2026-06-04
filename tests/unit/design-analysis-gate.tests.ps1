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

# Iteration 5 T003 (FR-026 / SC-016) — lens-coverage gate: each questionnaire-selected lens needs a
# non-placeholder "Addressed:" entry; anti-omission; grandfather-safe; deterministic; LLM/network-free.
$coverageDir = Join-Path $scratchRoot 'fr026-coverage'
$null = New-Item -ItemType Directory -Path $coverageDir -Force
[System.IO.File]::WriteAllText((Join-Path $coverageDir 'lens-applicability.json'), '{"schema":"v1","selected":["architecture-core","data-storage"]}', [System.Text.UTF8Encoding]::new($false))

$coverageAddressed = @'
# X

## Applicable Lenses

- **architecture-core** - `x`
  - Addressed: see Option B Trade-offs (binding constraints rule C out)
- **data-storage** - `x`
  - Addressed: see Option B (selected-subset-addressed invariant)
'@
Assert-True (@(Test-SpecrewDesignAnalysisLensCoverage -Content $coverageAddressed -IterationDirectory $coverageDir).Count -eq 0) 'FR-026: all selected lenses addressed -> passes'

$coverageUnaddressed = @'
# X

## Applicable Lenses

- **architecture-core** - `x`
  - Addressed: <how these decision points shaped the option comparison — name the option(s) and Trade-offs>
- **data-storage** - `x`
  - Decision points: a; b
'@
$coverageErrors = @(Test-SpecrewDesignAnalysisLensCoverage -Content $coverageUnaddressed -IterationDirectory $coverageDir)
Assert-True ($coverageErrors.Count -eq 2) 'FR-026: a placeholder entry and a missing entry are both flagged'
Assert-Match -Text ($coverageErrors -join "`n") -Pattern 'architecture-core' 'FR-026 (SC-016): failure names the placeholder-addressed lens'
Assert-Match -Text ($coverageErrors -join "`n") -Pattern 'data-storage' 'FR-026 (SC-016): failure names the unaddressed lens'
Write-Pass 'FR-026: unaddressed/placeholder selected lenses are blocked and named (SC-016)'

# Bypass-closed (Proposal 145 Phase 5): selected lenses + NO Addressed entries + NO grandfather
# marker -> FAIL naming every unaddressed lens. Deleting all Addressed lines must NOT no-op the gate.
$coverageNoAddressed = @'
# X

## Applicable Lenses

- **architecture-core** - `x`
- **data-storage** - `x`
'@
$noAddressedErrors = @(Test-SpecrewDesignAnalysisLensCoverage -Content $coverageNoAddressed -IterationDirectory $coverageDir)
Assert-True ($noAddressedErrors.Count -eq 2) 'FR-026: selected lenses + no Addressed entries (no grandfather marker) -> FAIL, not no-op'
Assert-Match -Text ($noAddressedErrors -join "`n") -Pattern 'architecture-core' 'FR-026: no-Addressed failure names architecture-core'
Assert-Match -Text ($noAddressedErrors -join "`n") -Pattern 'data-storage' 'FR-026: no-Addressed failure names data-storage'

# EXPLICIT grandfather: a pre-FR-026 artifact carrying fr026_grandfathered:true is exempt (PASS),
# even with selected lenses and no Addressed entries.
$grandfatherDir = Join-Path $scratchRoot 'fr026-grandfather'
$null = New-Item -ItemType Directory -Path $grandfatherDir -Force
[System.IO.File]::WriteAllText((Join-Path $grandfatherDir 'lens-applicability.json'), '{"schema":"v1","fr026_grandfathered":true,"selected":["architecture-core","data-storage"]}', [System.Text.UTF8Encoding]::new($false))
Assert-True (@(Test-SpecrewDesignAnalysisLensCoverage -Content $coverageNoAddressed -IterationDirectory $grandfatherDir).Count -eq 0) 'FR-026: explicit fr026_grandfathered marker exempts a pre-FR-026 artifact (PASS)'

# No recorded selection -> no-op (SC-006 graceful).
$coverageNoJson = Join-Path $scratchRoot 'fr026-no-json'
$null = New-Item -ItemType Directory -Path $coverageNoJson -Force
Assert-True (@(Test-SpecrewDesignAnalysisLensCoverage -Content $coverageUnaddressed -IterationDirectory $coverageNoJson).Count -eq 0) 'FR-026: no lens-applicability.json -> no-op'

# Determinism: identical inputs -> identical errors.
$cov1 = (@(Test-SpecrewDesignAnalysisLensCoverage -Content $coverageUnaddressed -IterationDirectory $coverageDir)) -join '|'
$cov2 = (@(Test-SpecrewDesignAnalysisLensCoverage -Content $coverageUnaddressed -IterationDirectory $coverageDir)) -join '|'
Assert-True ($cov1 -eq $cov2) 'FR-026: coverage check is deterministic'

# Placeholder detection: empty / TBD-class / angle-bracket default all count as not-addressed; a real pointer does not.
Assert-True (Test-SpecrewDesignAnalysisLensAddressedPlaceholder -Value '') 'FR-026 placeholder: empty value'
Assert-True (Test-SpecrewDesignAnalysisLensAddressedPlaceholder -Value 'TBD') 'FR-026 placeholder: TBD token'
Assert-True (Test-SpecrewDesignAnalysisLensAddressedPlaceholder -Value '<fill me in>') 'FR-026 placeholder: angle-bracket template default'
Assert-True (-not (Test-SpecrewDesignAnalysisLensAddressedPlaceholder -Value 'see Option B Trade-offs')) 'FR-026 placeholder: a real pointer is not a placeholder'
Write-Pass 'FR-026: enforce-by-default, EXPLICIT-marker grandfather (bypass closed), no-op without selection, deterministic, placeholder-aware'

# --- T006 (FR-026 resolution order, Amendment A3 / instruction #1) ---
# The coverage gate resolves the lens-applicability artifact: iteration-level (override / back-compat),
# then feature-level (the specify-phase truth), then graceful no-op. Mandated regression set.
$resolveRoot = Join-Path $scratchRoot 'fr026-resolution'
$noAddressedBody = "# X`n`n## Applicable Lenses`n`n- **architecture-core** - ``x```n- **data-storage** - ``x```n"

# (a) feature-level selected lens + missing Addressed entry => FR-026 fails and names the lens.
$featOnly = Join-Path $resolveRoot 'feat-a\iterations\006'
$null = New-Item -ItemType Directory -Path $featOnly -Force
[System.IO.File]::WriteAllText((Join-Path (Join-Path $resolveRoot 'feat-a') 'lens-applicability.json'), '{"schema":"v1","selected":["architecture-core","data-storage"]}', [System.Text.UTF8Encoding]::new($false))
$featErrors = @(Test-SpecrewDesignAnalysisLensCoverage -Content $noAddressedBody -IterationDirectory $featOnly)
Assert-True ($featErrors.Count -eq 2) 'FR-026 resolution: feature-level artifact (no iteration-level) is resolved; missing Addressed entries FAIL'
Assert-Match -Text ($featErrors -join "`n") -Pattern 'architecture-core' 'FR-026 resolution: feature-level failure names the lens'

# (b) iteration-level artifact OVERRIDES feature-level when present.
$override = Join-Path $resolveRoot 'feat-b\iterations\006'
$null = New-Item -ItemType Directory -Path $override -Force
[System.IO.File]::WriteAllText((Join-Path (Join-Path $resolveRoot 'feat-b') 'lens-applicability.json'), '{"schema":"v1","selected":["architecture-core","data-storage"]}', [System.Text.UTF8Encoding]::new($false))
[System.IO.File]::WriteAllText((Join-Path $override 'lens-applicability.json'), '{"schema":"v1","selected":["ui-ux"]}', [System.Text.UTF8Encoding]::new($false))
$overrideBody = "# X`n`n## Applicable Lenses`n`n- **ui-ux** - ``x```n  - Addressed: see Option B`n"
Assert-True (@(Test-SpecrewDesignAnalysisLensCoverage -Content $overrideBody -IterationDirectory $override).Count -eq 0) 'FR-026 resolution: iteration-level artifact overrides feature-level (only ui-ux required, addressed)'

# (c) neither artifact present => graceful no-op.
$neither = Join-Path $resolveRoot 'feat-c\iterations\006'
$null = New-Item -ItemType Directory -Path $neither -Force
Assert-True (@(Test-SpecrewDesignAnalysisLensCoverage -Content $noAddressedBody -IterationDirectory $neither).Count -eq 0) 'FR-026 resolution: neither iteration- nor feature-level artifact => graceful no-op'
Write-Pass 'FR-026 resolution order (iteration -> feature -> no-op) verified (instruction #1 regression set)'

# --- T006 (FR-028 file-reference render helper, Amendment A3) ---
Assert-True ((Format-SpecrewFileReference -Path 'specs/x/review.md' -Context console -ProjectRoot 'C:\repo') -eq 'file:///C:/repo/specs/x/review.md') 'FR-028: console context renders a file:/// URL'
Assert-True ((Format-SpecrewFileReference -Path 'specs/x/review.md' -Context persisted -LinkText 'review') -eq '[review](specs/x/review.md)') 'FR-028: persisted context renders a markdown link'
Assert-True ((Format-SpecrewFileReference -Path 'specs/x/review.md' -Context both -ProjectRoot 'C:\repo' -LinkText 'review') -eq '[review](file:///C:/repo/specs/x/review.md)') 'FR-028: both renders a markdown link to the file:/// URL'
Write-Pass 'FR-028: file-reference render helper (console file:/// vs persisted markdown vs both)'

# --- Iteration 7 T002 (SC-021, Amendment A4): per-lens workshop-record floor ---
$wsRoot = Join-Path $scratchRoot 'workshop\iterations\007'
$null = New-Item -ItemType Directory -Path $wsRoot -Force
$wsPath = Join-Path $wsRoot 'lens-applicability.json'
# (a) A4 workshop artifact: 'a' complete, 'b' has no record -> FAIL naming b
[System.IO.File]::WriteAllText($wsPath, '{"workshop_intake":true,"selected":["a","b"],"workshop":{"a":{"agenda":["q1"],"decision":"use X","depth":"moderate","moved_on":true}}}', [System.Text.UTF8Encoding]::new($false))
$wsE1 = @(Test-SpecrewLensWorkshopRecords -ArtifactPath $wsPath)
Assert-True ($wsE1.Count -eq 1 -and (($wsE1 -join '|') -match "'b'")) 'SC-021: selected lens with no workshop record FAILS and names it'
# (b) 'b' present but placeholder decision + missing moved_on -> FAIL listing the fields
[System.IO.File]::WriteAllText($wsPath, '{"workshop_intake":true,"selected":["a","b"],"workshop":{"a":{"agenda":["q1"],"decision":"use X","depth":"moderate","moved_on":true},"b":{"agenda":["q2"],"decision":"<TBD>","depth":"moderate"}}}', [System.Text.UTF8Encoding]::new($false))
$wsE2 = @(Test-SpecrewLensWorkshopRecords -ArtifactPath $wsPath)
Assert-True ($wsE2.Count -eq 1 -and (($wsE2 -join '|') -match 'decision') -and (($wsE2 -join '|') -match 'moved_on')) 'SC-021: placeholder decision + missing moved_on FAILS, naming the missing fields'
# (c) all complete -> PASS
[System.IO.File]::WriteAllText($wsPath, '{"workshop_intake":true,"selected":["a"],"workshop":{"a":{"agenda":["q1"],"decision":"use X","depth":"expert-terse","moved_on":true}}}', [System.Text.UTF8Encoding]::new($false))
Assert-True (@(Test-SpecrewLensWorkshopRecords -ArtifactPath $wsPath).Count -eq 0) 'SC-021: complete per-lens records -> PASS'
# (d) no workshop_intake marker (pre-A4 questionnaire) -> no-op (never retroactively fails iter 4-6)
[System.IO.File]::WriteAllText($wsPath, '{"selected":["a","b"]}', [System.Text.UTF8Encoding]::new($false))
Assert-True (@(Test-SpecrewLensWorkshopRecords -ArtifactPath $wsPath).Count -eq 0) 'SC-021: no workshop_intake marker -> no-op (pre-A4 questionnaire artifacts not retroactively failed)'
# (e) grandfathered -> no-op
[System.IO.File]::WriteAllText($wsPath, '{"workshop_intake":true,"fr026_grandfathered":true,"selected":["a"]}', [System.Text.UTF8Encoding]::new($false))
Assert-True (@(Test-SpecrewLensWorkshopRecords -ArtifactPath $wsPath).Count -eq 0) 'SC-021: explicit fr026_grandfathered exempts'
# placeholder detector
Assert-True (Test-SpecrewLensWorkshopRecordPlaceholder -Value @()) 'SC-021 placeholder: empty agenda array is a placeholder'
Assert-True (Test-SpecrewLensWorkshopRecordPlaceholder -Value '<TBD>') 'SC-021 placeholder: angle-bracket template default is a placeholder'
Assert-True (-not (Test-SpecrewLensWorkshopRecordPlaceholder -Value 'use X')) 'SC-021 placeholder: a real value is not a placeholder'
Write-Pass 'SC-021: per-lens workshop-record floor (presence-only, marker-gated, grandfather-safe)'

# --- Iteration 9 T004/T005 (SC-025, Amendment A6): co-design-record floor ---
# Marker-gated by `co_design` in lens-applicability.json + grandfather-safe; presence-only (the
# collaboration QUALITY is SC-024's runtime dogfood, not this gate). Mirrors the SC-021 floor shape.
$cdRoot = Join-Path $scratchRoot 'codesign\iterations\009'
$null = New-Item -ItemType Directory -Path $cdRoot -Force
$cdPath = Join-Path $cdRoot 'lens-applicability.json'
$cdComplete = @'
# X

## Co-Design Record

**Components and responsibilities (co-designed with the human):**

- **WebApi**: hosts the UI and the BFF; owns no domain responsibility.
- **JobManager**: owns the translation workflow; delegates to engines.

**Flow (agreed):**

```mermaid
sequenceDiagram
  User->>WebApi: upload
  WebApi->>JobManager: enqueue
```

- **Human-agreed**: yes
'@

# (a) co_design marked + complete record -> PASS
[System.IO.File]::WriteAllText($cdPath, '{"co_design":true,"selected":["architecture-core"]}', [System.Text.UTF8Encoding]::new($false))
Assert-True (@(Test-SpecrewDesignCoDesignRecord -Content $cdComplete -IterationDirectory $cdRoot).Count -eq 0) 'SC-025: co_design marked + complete Co-Design Record -> PASS'

# (b) co_design marked + missing section -> FAIL naming the section
$cdNoSection = "# X`n`n## Problem Framing`n`nsomething useful`n"
$cdE1 = @(Test-SpecrewDesignCoDesignRecord -Content $cdNoSection -IterationDirectory $cdRoot)
Assert-True ($cdE1.Count -ge 1 -and (($cdE1 -join '|') -match 'Co-Design Record')) 'SC-025: co_design marked + missing Co-Design Record section -> FAIL naming it'

# (c) co_design marked + section present but missing flow + missing agreed marker -> FAIL listing the gaps
$cdPartial = @'
# X

## Co-Design Record

**Components and responsibilities (co-designed with the human):**

- **WebApi**: hosts the UI; owns no domain responsibility.
'@
$cdE2 = @(Test-SpecrewDesignCoDesignRecord -Content $cdPartial -IterationDirectory $cdRoot)
Assert-True ($cdE2.Count -ge 1 -and (($cdE2 -join '|') -match 'flow') -and (($cdE2 -join '|') -match 'human-agreed')) 'SC-025: marked + incomplete record (no flow, no agreed marker) -> FAIL listing the gaps'

# (d) NO co_design marker (pre-A6) -> no-op (grandfather: never retroactively fails i1-i8/140)
[System.IO.File]::WriteAllText($cdPath, '{"selected":["architecture-core"]}', [System.Text.UTF8Encoding]::new($false))
Assert-True (@(Test-SpecrewDesignCoDesignRecord -Content $cdNoSection -IterationDirectory $cdRoot).Count -eq 0) 'SC-025: no co_design marker (pre-A6) -> no-op (grandfather-safe)'

# (e) explicit fr026_grandfathered exempts even when co_design is set
[System.IO.File]::WriteAllText($cdPath, '{"co_design":true,"fr026_grandfathered":true,"selected":["architecture-core"]}', [System.Text.UTF8Encoding]::new($false))
Assert-True (@(Test-SpecrewDesignCoDesignRecord -Content $cdNoSection -IterationDirectory $cdRoot).Count -eq 0) 'SC-025: explicit fr026_grandfathered exempts'

# (f) no lens-applicability.json -> graceful no-op
$cdNoJson = Join-Path $scratchRoot 'codesign-no-json'
$null = New-Item -ItemType Directory -Path $cdNoJson -Force
Assert-True (@(Test-SpecrewDesignCoDesignRecord -Content $cdNoSection -IterationDirectory $cdNoJson).Count -eq 0) 'SC-025: no lens-applicability.json -> no-op'
Write-Pass 'SC-025: co-design-record floor (presence-only, marker-gated, grandfather-safe)'

# SC-025 INTEGRATION (the i7 wiring lesson, applied to A6): prove the floor fires THROUGH the real gate
# entry point Test-SpecrewDesignAnalysisArtifact — not just in isolation. The full-suite validator never
# exercised this path because iteration 9's own lens-applicability.json carries no `co_design` marker, so
# the floor no-ops on the only artifact in the run; and the T006 dogfood cannot catch a fail-open floor
# (a genuine co-design HAS the record, so the gate passes whether the floor is live or dead). Only the
# negative path through the wired-in gate proves the wiring. `selected:[]` keeps FR-026 a no-op so the
# co-design floor is the sole discriminator.
$cdIntFail = Join-Path $scratchRoot 'codesign-integration-fail'
New-DesignAnalysisFixtureProject -ProjectRoot $cdIntFail
$cdIntFailIterDir = Split-Path -Parent (Get-SpecrewDesignAnalysisArtifactPath -ProjectRoot $cdIntFail -FeatureRef '140-design-analysis-gate' -IterationNumber '001')
[System.IO.File]::WriteAllText((Join-Path $cdIntFailIterDir 'lens-applicability.json'), '{"schema":"v1","co_design":true,"selected":[]}', [System.Text.UTF8Encoding]::new($false))
[System.IO.File]::WriteAllText((Get-SpecrewDesignAnalysisArtifactPath -ProjectRoot $cdIntFail -FeatureRef '140-design-analysis-gate' -IterationNumber '001'), (Get-ValidDesignAnalysisFixture), [System.Text.UTF8Encoding]::new($false))
$cdIntFailResult = Test-SpecrewDesignAnalysisArtifact -ProjectRoot $cdIntFail -FeatureRef '140-design-analysis-gate' -IterationNumber '001'
Assert-True (-not $cdIntFailResult.Valid) 'SC-025 integration: co_design marker + no Co-Design Record makes the FULL gate (Test-SpecrewDesignAnalysisArtifact) FAIL -> the wiring fires, not a silent no-op'
Assert-Match -Text ($cdIntFailResult.Errors -join "`n") -Pattern 'Co-Design Record' 'SC-025 integration: the full-gate failure names the missing Co-Design Record'

$cdIntPass = Join-Path $scratchRoot 'codesign-integration-pass'
New-DesignAnalysisFixtureProject -ProjectRoot $cdIntPass
$cdIntPassIterDir = Split-Path -Parent (Get-SpecrewDesignAnalysisArtifactPath -ProjectRoot $cdIntPass -FeatureRef '140-design-analysis-gate' -IterationNumber '001')
[System.IO.File]::WriteAllText((Join-Path $cdIntPassIterDir 'lens-applicability.json'), '{"schema":"v1","co_design":true,"selected":[]}', [System.Text.UTF8Encoding]::new($false))
$cdRecord = @'


## Co-Design Record

**Components and responsibilities (co-designed with the human):**

- **Helper**: validates the artifact; owns no boundary state.
- **Sync**: records boundary state; consumes the helper.

**Flow (agreed):**

```mermaid
flowchart LR
  Artifact --> Helper --> Sync
```

- **Human-agreed**: yes
'@
[System.IO.File]::WriteAllText((Get-SpecrewDesignAnalysisArtifactPath -ProjectRoot $cdIntPass -FeatureRef '140-design-analysis-gate' -IterationNumber '001'), ((Get-ValidDesignAnalysisFixture) + $cdRecord), [System.Text.UTF8Encoding]::new($false))
$cdIntPassResult = Test-SpecrewDesignAnalysisArtifact -ProjectRoot $cdIntPass -FeatureRef '140-design-analysis-gate' -IterationNumber '001'
Assert-True $cdIntPassResult.Valid ("SC-025 integration: co_design marker + a complete Co-Design Record passes the FULL gate (valid path intact): {0}" -f ($cdIntPassResult.Errors -join '; '))
Write-Pass 'SC-025 integration: the co-design floor fires through Test-SpecrewDesignAnalysisArtifact (wiring proven on the negative path; valid path intact)'

Write-Pass 'Design-analysis gate unit tests passed'
exit 0
