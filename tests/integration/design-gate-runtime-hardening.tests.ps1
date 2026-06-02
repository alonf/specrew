[CmdletBinding()]
param()

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

function Write-Pass { param([string]$Message) Write-Host "PASS: $Message" -ForegroundColor Green }
function Write-Fail { param([string]$Message) Write-Host "FAIL: $Message" -ForegroundColor Red; exit 1 }
function Assert-True { param([bool]$Condition, [string]$Message) if (-not $Condition) { Write-Fail $Message } }

function Test-Throws {
    param([scriptblock]$Action)
    try { & $Action | Out-Null; return $false } catch { return $true }
}

$gateScript = Join-Path $PSScriptRoot '..\..\scripts\internal\design-analysis-gate.ps1'
. $gateScript

function New-RuntimeHardeningFixture {
    param(
        [Parameter(Mandatory = $true)][string]$ProjectRoot,
        [string]$FeatureRef = '141-design-gate-runtime-hardening',
        [string]$SessionFeatureRef = '141-design-gate-runtime-hardening',
        [string]$Boundary = 'clarify',
        [string]$SpecrewVersion = '0.30.0'
    )

    $null = New-Item -ItemType Directory -Path (Join-Path $ProjectRoot '.specrew') -Force
    $null = New-Item -ItemType Directory -Path (Join-Path $ProjectRoot ('specs\{0}\iterations\001' -f $FeatureRef)) -Force
    [System.IO.File]::WriteAllText((Join-Path $ProjectRoot '.specrew\config.yml'), ("specrew_version: `"{0}`"`n" -f $SpecrewVersion), [System.Text.UTF8Encoding]::new($false))
    [System.IO.File]::WriteAllText((Join-Path $ProjectRoot ('specs\{0}\spec.md' -f $FeatureRef)), @'
# Feature Specification: Runtime Hardening

This substantive lifecycle governance feature changes boundary enforcement, helper validation, and state behavior.
'@, [System.Text.UTF8Encoding]::new($false))
    [System.IO.File]::WriteAllText((Join-Path $ProjectRoot '.specrew\start-context.json'), (@{
                schema               = 'v2'
                session_state        = @{ active = $true; boundary_type = $Boundary; feature_ref = $SessionFeatureRef; iteration_number = '001' }
                boundary_enforcement = @{ enabled = $true; last_authorized_boundary = $Boundary }
            } | ConvertTo-Json -Depth 8), [System.Text.UTF8Encoding]::new($false))
}

function Get-ValidArtifact {
    return @'
# Design Analysis: Runtime Hardening

## Problem Framing

Surface alternatives before plan so the design is chosen explicitly.

## Key Design Decision Points

1. Enforcement placement.

## Alternatives

### Option A: Simplest

**Approach**: Prompt-only.
**Architectural pattern**: single helper.
**Quality features considered**: robustness.
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

By-the-book is not meaningfully distinct from Reasonable for this slice, so it is not offered as a separate option.

## Crew Recommendation

**Recommended: Option B.**

## Human Decision

- **Chosen option**: Option B
- **Reason**: Balanced.
- **Modifications**: None.
- **Decided at commit**: `1a2b3c4d`
'@
}

$projectRoot = Join-Path ([System.IO.Path]::GetTempPath()) ("specrew-141-int-" + [guid]::NewGuid().ToString('N'))
try {
    $feature = '141-design-gate-runtime-hardening'
    $artifactPath = Join-Path $projectRoot ('specs\{0}\iterations\001\design-analysis.md' -f $feature)

    # --- Block: missing artifact (FR-002 / FR-003) ---
    New-RuntimeHardeningFixture -ProjectRoot $projectRoot
    $blockedMissing = Test-Throws { Invoke-SpecrewDesignAnalysisPrePlanGate -ProjectRoot $projectRoot -FeatureRef $feature -IterationNumber '001' }
    Assert-True $blockedMissing 'Pre-plan gate blocks plan authoring when design-analysis.md is missing'
    Write-Pass 'Pre-plan gate blocks before plan when the artifact is missing'

    # --- Block: artifact present but Human Decision invalid ---
    $noDecision = (Get-ValidArtifact) -replace '(?s)## Human Decision.*$', "## Human Decision`n`n- **Chosen option**: <pending>`n"
    [System.IO.File]::WriteAllText($artifactPath, $noDecision, [System.Text.UTF8Encoding]::new($false))
    $blockedNoDecision = Test-Throws { Invoke-SpecrewDesignAnalysisPrePlanGate -ProjectRoot $projectRoot -FeatureRef $feature -IterationNumber '001' }
    Assert-True $blockedNoDecision 'Pre-plan gate blocks plan authoring when the Human Decision is not recorded'
    Write-Pass 'Pre-plan gate blocks before plan when the human decision is missing'

    # --- Pass: valid artifact + decision ---
    [System.IO.File]::WriteAllText($artifactPath, (Get-ValidArtifact), [System.Text.UTF8Encoding]::new($false))
    $passResult = Invoke-SpecrewDesignAnalysisPrePlanGate -ProjectRoot $projectRoot -FeatureRef $feature -IterationNumber '001'
    Assert-True ($null -ne $passResult -and $passResult.Valid -eq $true) 'Pre-plan gate passes for a valid artifact + recorded decision'
    Write-Pass 'Pre-plan gate passes only when artifact and decision are valid'

    # --- Compatibility skip: gate not required for a feature that is not the active session feature ---
    $otherRoot = Join-Path ([System.IO.Path]::GetTempPath()) ("specrew-141-int-other-" + [guid]::NewGuid().ToString('N'))
    New-RuntimeHardeningFixture -ProjectRoot $otherRoot -FeatureRef '099-unrelated-feature' -SessionFeatureRef '141-design-gate-runtime-hardening'
    $skip = Invoke-SpecrewDesignAnalysisPrePlanGate -ProjectRoot $otherRoot -FeatureRef '099-unrelated-feature' -IterationNumber '001'
    Assert-True ($null -eq $skip) 'Pre-plan gate skips (no hard-fail) for a feature that is not the active substantive session feature'
    Write-Pass 'Compatibility: pre-plan gate is scoped to the active substantive feature'
    Remove-Item -LiteralPath $otherRoot -Recurse -Force -ErrorAction SilentlyContinue

    # --- Legacy compatibility: pre-0.30.0 project without an artifact does not hard-fail ---
    $legacyRoot = Join-Path ([System.IO.Path]::GetTempPath()) ("specrew-141-int-legacy-" + [guid]::NewGuid().ToString('N'))
    New-RuntimeHardeningFixture -ProjectRoot $legacyRoot -SpecrewVersion '0.29.0'
    Remove-Item -LiteralPath (Join-Path $legacyRoot ('specs\{0}\iterations\001\design-analysis.md' -f $feature)) -Force -ErrorAction SilentlyContinue
    $legacySkip = Invoke-SpecrewDesignAnalysisPrePlanGate -ProjectRoot $legacyRoot -FeatureRef $feature -IterationNumber '001'
    Assert-True ($null -eq $legacySkip) 'Pre-plan gate does not hard-fail a pre-0.30.0 legacy project without an artifact'
    Write-Pass 'Compatibility: legacy pre-0.30.0 project without artifact is not hard-failed'
    Remove-Item -LiteralPath $legacyRoot -Recurse -Force -ErrorAction SilentlyContinue

    Write-Pass 'Design-gate runtime hardening integration tests passed'
}
finally {
    if (Test-Path -LiteralPath $projectRoot) {
        Remove-Item -LiteralPath $projectRoot -Recurse -Force -ErrorAction SilentlyContinue
    }
}
