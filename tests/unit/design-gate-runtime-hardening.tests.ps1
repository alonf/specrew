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

    # --- T004 (verify-clean guard; also T005 clean-harness-exit / FR-015) ---
    # The iteration-1 smoke flagged a trailing $LASTEXITCODE wrapper error printed after a manual
    # "GATE_VALID: True" echo, and a quality/prereq command path that was wrong-then-self-corrected.
    # Neither is a committed code path: "GATE_VALID: True" exists nowhere in source (it was an
    # improvised manual echo), and the real harness returns cleanly. This guard locks the clean
    # behavior so a future regression (a stray non-zero $LASTEXITCODE or a moved quality/prereq
    # script) would fail. (Valid artifact is in place from the selected-option test above.)
    $global:LASTEXITCODE = 0
    $gateResult = Invoke-SpecrewDesignAnalysisPlanBoundaryGate -ProjectRoot $projectRoot -FeatureRef '141-design-gate-runtime-hardening' -IterationNumber '001'
    Assert-True ($null -ne $gateResult -and $gateResult.Valid -eq $true) 'T004: plan-boundary gate returns Valid on a valid artifact'
    Assert-True ($LASTEXITCODE -eq 0) ("T004: plan-boundary gate leaves a clean exit code on the valid path (got LASTEXITCODE=$LASTEXITCODE)")
    Write-Pass 'T004: plan-boundary gate harness exits clean (LASTEXITCODE=0, no stray error) on a valid artifact'

    $repoRootForT004 = (Resolve-Path (Join-Path $PSScriptRoot '..\..')).Path
    foreach ($qp in '.specify\scripts\powershell\check-prerequisites.ps1', '.specify\extensions\specrew-speckit\scripts\resolve-quality-profile.ps1') {
        Assert-True (Test-Path -LiteralPath (Join-Path $repoRootForT004 $qp) -PathType Leaf) ("T004: quality/prereq command path referenced by the generated guidance resolves: $qp")
    }
    Write-Pass 'T004: quality/prereq command paths in the generated guidance resolve (no wrong-path-first)'

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

    # --- T002 (FR-027 / Amendment A3): specify-boundary lens gate — ENFORCED, not prompt-only ---
    # Scripted proof (maintainer-mandated) that sync-specify cannot finalize before the feature-level
    # lens-applicability.json exists (i.e. the interactive lens intake ran). The applicability map +
    # a substantive spec make the intake required.
    $specifyRoot = Join-Path ([System.IO.Path]::GetTempPath()) ("specrew-141-specify-gate-" + [guid]::NewGuid().ToString('N'))
    try {
        $mapDir = Join-Path $specifyRoot 'extensions\specrew-speckit\knowledge\design-lenses'
        $featDir = Join-Path $specifyRoot 'specs\001-test-feature'
        $null = New-Item -ItemType Directory -Path $mapDir -Force
        $null = New-Item -ItemType Directory -Path $featDir -Force
        [System.IO.File]::WriteAllText((Join-Path $mapDir 'applicability-map.json'), '{"always_on":["architecture-core"],"questions":[]}', [System.Text.UTF8Encoding]::new($false))
        [System.IO.File]::WriteAllText((Join-Path $featDir 'spec.md'), "# Spec`nThis governance lifecycle feature changes boundary enforcement and validation.", [System.Text.UTF8Encoding]::new($false))

        # (1) substantive + map present + NO feature-level artifact -> the gate THROWS (sync-specify blocked).
        $specifyBlocked = $false
        try { Invoke-SpecrewSpecifyBoundaryLensGate -ProjectRoot $specifyRoot -FeatureRef '001-test-feature' | Out-Null }
        catch {
            $specifyBlocked = $true
            Assert-True ($_.Exception.Message -match 'specify-lens-gate' -and $_.Exception.Message -match '001-test-feature') 'specify-lens-gate failure names the gate and the feature'
        }
        Assert-True $specifyBlocked 'FR-027: sync-specify is BLOCKED before the feature-level lens-applicability.json exists (enforced, not prompt-only)'
        Write-Pass 'FR-027/A3: specify boundary refuses to finalize before the lens-intake artifact'

        # (2) feature-level artifact present -> the gate PASSES.
        [System.IO.File]::WriteAllText((Join-Path $featDir 'lens-applicability.json'), '{"schema":"v1","selected":["architecture-core"]}', [System.Text.UTF8Encoding]::new($false))
        $specifyOk = Invoke-SpecrewSpecifyBoundaryLensGate -ProjectRoot $specifyRoot -FeatureRef '001-test-feature'
        Assert-True ($null -ne $specifyOk -and $specifyOk.Valid -eq $true) 'FR-027: sync-specify is allowed once the feature-level lens artifact exists'
        Write-Pass 'FR-027/A3: specify boundary passes once the lens-intake artifact is recorded'

        # (2b) SC-021 (Amendment A4) — the per-lens workshop FLOOR fires HERE, on the FEATURE-level
        # workshop artifact (the i007 dogfood fix: the earlier wiring checked the iteration-level
        # questionnaire and no-opped). An A4 workshop artifact (workshop_intake) with an INCOMPLETE
        # per-lens record blocks sync-specify and names the lens; a complete record passes.
        [System.IO.File]::WriteAllText((Join-Path $featDir 'lens-applicability.json'), '{"schema":"v2","workshop_intake":true,"selected":["architecture-core"],"workshop":{"architecture-core":{"agenda":["q1"],"decision":"<TBD>","depth":"moderate"}}}', [System.Text.UTF8Encoding]::new($false))
        $sc021Blocked = $false
        try { Invoke-SpecrewSpecifyBoundaryLensGate -ProjectRoot $specifyRoot -FeatureRef '001-test-feature' | Out-Null }
        catch { $sc021Blocked = ($_.Exception.Message -match 'SC-021' -and $_.Exception.Message -match 'architecture-core') }
        Assert-True $sc021Blocked 'SC-021: sync-specify is BLOCKED when an A4 workshop artifact has an incomplete per-lens record (names the lens)'
        [System.IO.File]::WriteAllText((Join-Path $featDir 'lens-applicability.json'), '{"schema":"v2","workshop_intake":true,"selected":["architecture-core"],"workshop":{"architecture-core":{"agenda":["q1"],"decision":"modular monolith","depth":"expert-terse","moved_on":true}}}', [System.Text.UTF8Encoding]::new($false))
        $sc021Ok = Invoke-SpecrewSpecifyBoundaryLensGate -ProjectRoot $specifyRoot -FeatureRef '001-test-feature'
        Assert-True ($null -ne $sc021Ok -and $sc021Ok.Valid -eq $true) 'SC-021: sync-specify passes once each selected lens has a complete workshop record'
        Write-Pass 'SC-021: specify gate enforces the per-lens workshop floor on the feature-level artifact (i007 dogfood fix)'

        # (2c) SC-026 (Amendment A7) — the per-lens confirmation PROVENANCE floor rides the SAME specify-gate
        # throw (the gate throws on ANY Test-SpecrewLensWorkshopRecords error). When the artifact opts in via
        # confirmation_required, each selected lens MUST declare a provenance (human-confirmed|delegated|skipped);
        # grandfather-safe (no marker -> no-op). Proven through the REAL gate entry, not only the unit floor.
        [System.IO.File]::WriteAllText((Join-Path $featDir 'lens-applicability.json'), '{"schema":"v2","workshop_intake":true,"confirmation_required":true,"selected":["architecture-core"],"workshop":{"architecture-core":{"agenda":["q1"],"decision":"modular monolith","depth":"expert-terse","moved_on":true}}}', [System.Text.UTF8Encoding]::new($false))
        $sc026Blocked = $false
        try { Invoke-SpecrewSpecifyBoundaryLensGate -ProjectRoot $specifyRoot -FeatureRef '001-test-feature' | Out-Null }
        catch { $sc026Blocked = ($_.Exception.Message -match 'SC-026' -and $_.Exception.Message -match 'architecture-core') }
        Assert-True $sc026Blocked 'SC-026: sync-specify is BLOCKED when a confirmation_required artifact omits a lens provenance (fires through the real gate entry, names the lens)'
        [System.IO.File]::WriteAllText((Join-Path $featDir 'lens-applicability.json'), '{"schema":"v2","workshop_intake":true,"confirmation_required":true,"selected":["architecture-core"],"workshop":{"architecture-core":{"agenda":["q1"],"decision":"modular monolith","depth":"expert-terse","moved_on":true,"confirmation":"human-confirmed"}}}', [System.Text.UTF8Encoding]::new($false))
        $sc026Ok = Invoke-SpecrewSpecifyBoundaryLensGate -ProjectRoot $specifyRoot -FeatureRef '001-test-feature'
        Assert-True ($null -ne $sc026Ok -and $sc026Ok.Valid -eq $true) 'SC-026: sync-specify passes once each lens declares a valid confirmation provenance'
        [System.IO.File]::WriteAllText((Join-Path $featDir 'lens-applicability.json'), '{"schema":"v2","workshop_intake":true,"selected":["architecture-core"],"workshop":{"architecture-core":{"agenda":["q1"],"decision":"modular monolith","depth":"expert-terse","moved_on":true}}}', [System.Text.UTF8Encoding]::new($false))
        $sc026Grandfather = Invoke-SpecrewSpecifyBoundaryLensGate -ProjectRoot $specifyRoot -FeatureRef '001-test-feature'
        Assert-True ($null -ne $sc026Grandfather -and $sc026Grandfather.Valid -eq $true) 'SC-026: pre-A7 artifact (no confirmation_required) -> SC-026 no-op through the real gate (grandfather-safe)'
        Write-Pass 'SC-026: specify gate enforces the per-lens confirmation provenance floor (wired through the real entry; grandfather-safe)'

        # (3) no applicability map (downstream project without lenses) -> graceful no-op (null).
        Remove-Item -LiteralPath (Join-Path $featDir 'lens-applicability.json') -Force
        Remove-Item -LiteralPath (Join-Path $mapDir 'applicability-map.json') -Force
        Assert-True ($null -eq (Invoke-SpecrewSpecifyBoundaryLensGate -ProjectRoot $specifyRoot -FeatureRef '001-test-feature')) 'FR-027: no applicability map -> specify gate is a graceful no-op (downstream without lenses)'
        Write-Pass 'FR-027/A3: specify gate degrades gracefully when no lens catalog is present'
    }
    finally {
        if (Test-Path -LiteralPath $specifyRoot) { Remove-Item -LiteralPath $specifyRoot -Recurse -Force }
    }

    # --- T004 (FR-028): handoff bare-path matcher no longer false-flags token/token prose ---
    $handoffValidator = Join-Path $repoRootForT004 'extensions\specrew-speckit\validators\handoff-governance-validator.ps1'
    $handoffText = @'
## What I Just Did
Compared RRT/Bug1 strategies and mapped FR/SC coverage; wrote contracts/robot-path-viz.md.
## Why I Stopped
plan boundary.
## What Needs Your Review
the plan.
## What Happens Next
tasks.
## Discussion Prompts
1. ok?
## What I Need From You
approve.
'@
    $handoffOut = @(& $handoffValidator -ProjectRoot $repoRootForT004 -ResponseText $handoffText -BoundaryName plan -ResponseScope boundary-handoff -BarePathBoundaryHandoffSeverity validation-fail 2>&1)
    $barePathLine = ($handoffOut | Select-String -Pattern 'bare-path') -join "`n"
    Assert-True ($barePathLine -notmatch 'RRT/Bug1') 'FR-028: handoff bare-path no longer false-flags RRT/Bug1 (acronym pair)'
    Assert-True ($barePathLine -notmatch 'FR/SC') 'FR-028: handoff bare-path no longer false-flags FR/SC (abbreviation pair)'
    Assert-True ($barePathLine -match 'contracts/robot-path-viz\.md') 'FR-028: handoff bare-path still flags a genuine bare path'
    # The handoff validator exits 1 on the genuine bare-path finding (expected); clear the leaked
    # exit code so this suite's own exit stays clean.
    $global:LASTEXITCODE = 0
    Write-Pass 'FR-028: handoff bare-path matcher distinguishes real paths from token/token prose'

    Write-Pass 'Design-gate runtime hardening unit tests passed'
}
finally {
    if (Test-Path -LiteralPath $projectRoot) {
        Remove-Item -LiteralPath $projectRoot -Recurse -Force -ErrorAction SilentlyContinue
    }
}
