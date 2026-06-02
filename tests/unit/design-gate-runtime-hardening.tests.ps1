[CmdletBinding()]
param()

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

function Write-Pass { param([string]$Message) Write-Host "PASS: $Message" -ForegroundColor Green }
function Write-Fail { param([string]$Message) Write-Host "FAIL: $Message" -ForegroundColor Red; exit 1 }
function Assert-True { param([bool]$Condition, [string]$Message) if (-not $Condition) { Write-Fail $Message } }

$gateScript = Join-Path $PSScriptRoot '..\..\scripts\internal\design-analysis-gate.ps1'
. $gateScript

function New-RuntimeHardeningFixture {
    param(
        [Parameter(Mandatory = $true)][string]$ProjectRoot,
        [string]$FeatureRef = '141-design-gate-runtime-hardening',
        [string]$Boundary = 'clarify'
    )

    $null = New-Item -ItemType Directory -Path (Join-Path $ProjectRoot '.specrew') -Force
    $null = New-Item -ItemType Directory -Path (Join-Path $ProjectRoot ('specs\{0}\iterations\001' -f $FeatureRef)) -Force
    [System.IO.File]::WriteAllText((Join-Path $ProjectRoot '.specrew\config.yml'), "specrew_version: `"0.30.0`"`n", [System.Text.UTF8Encoding]::new($false))
    [System.IO.File]::WriteAllText((Join-Path $ProjectRoot ('specs\{0}\spec.md' -f $FeatureRef)), @'
# Feature Specification: Runtime Hardening

This substantive lifecycle governance feature changes boundary enforcement, helper validation, and state behavior.
'@, [System.Text.UTF8Encoding]::new($false))
    [System.IO.File]::WriteAllText((Join-Path $ProjectRoot '.specrew\start-context.json'), (@{
                schema               = 'v2'
                session_state        = @{ active = $true; boundary_type = $Boundary; feature_ref = $FeatureRef; iteration_number = '001' }
                boundary_enforcement = @{ enabled = $true; last_authorized_boundary = $Boundary }
            } | ConvertTo-Json -Depth 8), [System.Text.UTF8Encoding]::new($false))
}

# A valid artifact that intentionally exercises FR-022 (By-the-book in prose with
# spaces) and FR-023 (recommendation names one option via a marker while mentioning
# a rejected option contextually).
function Get-ToleranceFixtureArtifact {
    return @'
# Design Analysis: Runtime Hardening

## Problem Framing

The lifecycle must expose architecture alternatives before plan so substantive governance changes do not pick a design implicitly.

## Key Design Decision Points

1. Where the enforcement lives.

## Alternatives

### Option A: Simplest

**Approach**: Minimal prompt-only shape.
**Architectural pattern**: single helper.
**Quality features considered**: robustness baseline.
**Effort estimate**: low.
**Reversibility cost**: High.
**Trade-offs**:

- (+) cheap
- (-) unauditable

**Diagram**:

```mermaid
flowchart LR
  A --> B
```

### Option B: Reasonable

**Approach**: Helper plus durable evidence.
**Architectural pattern**: layered helper.
**Quality features considered**: robustness and test-integrity.
**Effort estimate**: medium.
**Reversibility cost**: Medium.
**Trade-offs**:

- (+) auditable
- (-) larger

**Diagram**:

```mermaid
flowchart LR
  A --> B --> C
```

### Option C: By the book

**Approach**: Full hook-enforced shape.
**Architectural pattern**: hook plus hashed packet.
**Quality features considered**: comprehensive.
**Effort estimate**: high.
**Reversibility cost**: Low.
**Trade-offs**:

- (+) robust
- (-) exceeds scope

**Diagram**:

```mermaid
flowchart LR
  A --> B --> C --> D
```

## Crew Recommendation

**Recommended: Option B.** Option A is cheaper but leaves the approval object unauditable, so Option B is preferred here.

## Human Decision

- **Chosen option**: Option B
- **Reason**: Balanced and auditable.
- **Modifications**: None.
- **Decided at commit**: `1a2b3c4d`
'@
}

$projectRoot = Join-Path ([System.IO.Path]::GetTempPath()) ("specrew-141-unit-" + [guid]::NewGuid().ToString('N'))
try {
    # --- Scaffold (FR-001) ---
    New-RuntimeHardeningFixture -ProjectRoot $projectRoot
    $scaffold = New-SpecrewDesignAnalysisArtifact -ProjectRoot $projectRoot -FeatureRef '141-design-gate-runtime-hardening' -IterationNumber '001'
    Assert-True ($scaffold.Created -eq $true) 'Scaffold creates design-analysis.md from the template'
    Assert-True (Test-Path -LiteralPath $scaffold.Path -PathType Leaf) 'Scaffolded artifact exists on disk'
    Write-Pass 'Scaffold creates the artifact from template'

    $scaffoldAgain = New-SpecrewDesignAnalysisArtifact -ProjectRoot $projectRoot -FeatureRef '141-design-gate-runtime-hardening' -IterationNumber '001'
    Assert-True ($scaffoldAgain.Created -eq $false) 'Scaffold does not overwrite an existing artifact'
    Write-Pass 'Scaffold is non-destructive on re-run'

    # The freshly scaffolded (template-placeholder) artifact must NOT validate yet.
    $templateResult = Test-SpecrewDesignAnalysisArtifact -ProjectRoot $projectRoot -FeatureRef '141-design-gate-runtime-hardening' -IterationNumber '001'
    Assert-True ($templateResult.Valid -eq $false) 'Unfilled scaffold template is not yet valid'
    Write-Pass 'Unfilled scaffold is correctly invalid until filled'

    # --- Validator robustness (FR-022 + FR-023) ---
    [System.IO.File]::WriteAllText($scaffold.Path, (Get-ToleranceFixtureArtifact), [System.Text.UTF8Encoding]::new($false))
    $toleranceResult = Test-SpecrewDesignAnalysisArtifact -ProjectRoot $projectRoot -FeatureRef '141-design-gate-runtime-hardening' -IterationNumber '001'
    Assert-True ($toleranceResult.Valid -eq $true) ("Prose By-the-book + marker recommendation validate (errors: " + ($toleranceResult.Errors -join '; ') + ')')
    Write-Pass 'FR-022: By-the-book written in prose ("By the book") is accepted'
    Assert-True ($toleranceResult.RecommendedOption -eq 'Option B') "FR-023: recommendation resolves to exactly one option despite contextual mention ($($toleranceResult.RecommendedOption))"
    Write-Pass 'FR-023: single recommendation resolved despite contextual rejected-option mention'
    Assert-True ($toleranceResult.SelectedOption -eq 'Option B') "Selected option resolves to one option ($($toleranceResult.SelectedOption))"
    Write-Pass 'Selected option resolves cleanly for plan input (FR-007)'

    # A genuine multi-recommendation (no marker, two equally-named options) still fails.
    $ambiguous = (Get-ToleranceFixtureArtifact) -replace '\*\*Recommended: Option B\.\*\* Option A is cheaper but leaves the approval object unauditable, so Option B is preferred here\.', 'We could pick Option A or Option B; both are viable.'
    [System.IO.File]::WriteAllText($scaffold.Path, $ambiguous, [System.Text.UTF8Encoding]::new($false))
    $ambiguousResult = Test-SpecrewDesignAnalysisArtifact -ProjectRoot $projectRoot -FeatureRef '141-design-gate-runtime-hardening' -IterationNumber '001'
    Assert-True ($ambiguousResult.Valid -eq $false) 'FR-023: genuine multi-recommendation (no marker) is still rejected'
    Write-Pass 'FR-023: genuinely ambiguous multi-recommendation still fails'

    # --- Selected option accessor (FR-007) ---
    [System.IO.File]::WriteAllText($scaffold.Path, (Get-ToleranceFixtureArtifact), [System.Text.UTF8Encoding]::new($false))
    $selected = Get-SpecrewDesignAnalysisSelectedOption -ProjectRoot $projectRoot -FeatureRef '141-design-gate-runtime-hardening' -IterationNumber '001'
    Assert-True ($selected -eq 'Option B') "Get-SpecrewDesignAnalysisSelectedOption returns the chosen option ($selected)"
    Write-Pass 'Selected-option accessor returns the chosen option'

    # --- Typed packet (FR-004 / FR-005 / FR-020) ---
    $packet = New-SpecrewDesignAnalysisGatePacket -Fields @{
        Feature           = '141-design-gate-runtime-hardening'
        Iteration         = '001'
        Verdict           = 'approved for plan with Option B'
        WhatIJustDid      = 'Authored the design-analysis artifact.'
        WhyIStopped       = 'Design-analysis decision gate.'
        WhatNeedsYourReview = 'Review file:///C:/x/specs/141/iterations/001/design-analysis.md'
        WhatHappensNext   = 'Plan after a decision is recorded.'
        DiscussionPrompts = 'Which option?'
        WhatINeedFromYou  = 'Approve an option.'
    }
    $packetCheck = Test-SpecrewDesignAnalysisGatePacket -PacketText $packet
    Assert-True ($packetCheck.Valid -eq $true) ("Rendered packet validates (errors: " + ($packetCheck.Errors -join '; ') + ')')
    Write-Pass 'FR-004/FR-005: typed packet renders and validates'

    # Missing section fails.
    $brokenPacket = $packet -replace '(?m)^## What I Need From You\s*$', '## Something Else'
    $brokenCheck = Test-SpecrewDesignAnalysisGatePacket -PacketText $brokenPacket
    Assert-True ($brokenCheck.Valid -eq $false) 'Packet missing a required section fails validation'
    Write-Pass 'FR-005: packet missing a section is rejected'

    # Bare-path prose fails.
    $barePacket = $packet -replace 'file:///C:/x/specs/141/iterations/001/design-analysis.md', 'specs/141/iterations/001/design-analysis.md'
    $bareCheck = Test-SpecrewDesignAnalysisGatePacket -PacketText $barePacket
    Assert-True ($bareCheck.Valid -eq $false) 'Packet with a bare artifact path in prose fails validation'
    Write-Pass 'FR-005: packet bare-path reference is rejected'

    # Persist (FR-020): durable packet under gates/, scoped to the design-analysis gate.
    $saved = Save-SpecrewDesignAnalysisGatePacket -ProjectRoot $projectRoot -FeatureRef '141-design-gate-runtime-hardening' -IterationNumber '001' -PacketText $packet
    Assert-True (Test-Path -LiteralPath $saved.Path -PathType Leaf) 'Durable packet is persisted'
    Assert-True ($saved.Path -match 'specs[\\/]141-design-gate-runtime-hardening[\\/]gates[\\/]') 'FR-020/FR-006: packet is stored under the feature gates/ directory only'
    Write-Pass 'FR-020: durable 155-lite packet persisted under gates/'

    # --- Fix 3 (decision-commit metadata integrity) ---
    $newDecisionBlock = "## Human Decision`n`n- **Decision verdict**: approved for plan with Option B`n- **Chosen option**: Option B`n- **Reason**: Balanced.`n- **Modifications**: None.`n- **Design-analysis draft commit**: aaaaaaa`n- **Decision recorded in commit**: bbbbbbb`n"
    $newModelOk = (Get-ToleranceFixtureArtifact) -replace '(?s)## Human Decision.*$', $newDecisionBlock
    [System.IO.File]::WriteAllText($scaffold.Path, $newModelOk, [System.Text.UTF8Encoding]::new($false))
    $okRes = Test-SpecrewDesignAnalysisArtifact -ProjectRoot $projectRoot -FeatureRef '141-design-gate-runtime-hardening' -IterationNumber '001'
    Assert-True ($okRes.Valid -eq $true) ("New decision-commit model with distinct draft/decision commits validates (errors: " + ($okRes.Errors -join '; ') + ')')
    Write-Pass 'FR-003: new decision-commit metadata model (distinct draft/decision commits) validates'

    $driftBlock = "## Human Decision`n`n- **Decision verdict**: approved for plan with Option B`n- **Chosen option**: Option B`n- **Reason**: Balanced.`n- **Modifications**: None.`n- **Design-analysis draft commit**: aaaaaaa`n- **Decision recorded in commit**: aaaaaaa`n"
    $driftArtifact = (Get-ToleranceFixtureArtifact) -replace '(?s)## Human Decision.*$', $driftBlock
    [System.IO.File]::WriteAllText($scaffold.Path, $driftArtifact, [System.Text.UTF8Encoding]::new($false))
    $driftRes = Test-SpecrewDesignAnalysisArtifact -ProjectRoot $projectRoot -FeatureRef '141-design-gate-runtime-hardening' -IterationNumber '001'
    Assert-True ($driftRes.Valid -eq $false) 'FR-003: recording the draft commit as the decision commit is rejected'
    Write-Pass 'FR-003: decision-commit == draft-commit drift is rejected'

    Write-Pass 'Design-gate runtime hardening unit tests passed'
}
finally {
    if (Test-Path -LiteralPath $projectRoot) {
        Remove-Item -LiteralPath $projectRoot -Recurse -Force -ErrorAction SilentlyContinue
    }
}
