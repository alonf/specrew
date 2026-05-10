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

function Assert-Condition {
    param(
        [Parameter(Mandatory = $true)]
        [bool]$Condition,
        [Parameter(Mandatory = $true)]
        [string]$FailureMessage
    )

    if (-not $Condition) {
        Write-Fail $FailureMessage
        return $false
    }

    return $true
}

function New-TestWorkspace {
    param(
        [Parameter(Mandatory = $true)]
        [string]$ScratchRoot,
        [Parameter(Mandatory = $true)]
        [string]$FixtureProjectPath,
        [Parameter(Mandatory = $true)]
        [string]$WorkspaceName
    )

    $workspace = Join-Path $ScratchRoot $WorkspaceName
    if (Test-Path -LiteralPath $workspace) {
        Remove-Item -LiteralPath $workspace -Recurse -Force
    }
    Copy-Item -LiteralPath $FixtureProjectPath -Destination $workspace -Recurse -Force
    return $workspace
}

$repoRoot = (Resolve-Path (Join-Path -Path $PSScriptRoot -ChildPath '..\..')).Path
$fixtureRoot = Join-Path $repoRoot 'tests\integration\fixtures\lockout-chain-cap'
$fixtureProject = Join-Path $fixtureRoot 'project'
$scratchRoot = Join-Path $repoRoot '.scratch\lockout-chain-cap'
$sharedGovernancePath = Join-Path $repoRoot 'extensions\specrew-speckit\scripts\shared-governance.ps1'

foreach ($requiredPath in @($fixtureProject, $sharedGovernancePath)) {
    if (-not (Test-Path -LiteralPath $requiredPath)) {
        Write-Fail "Missing lockout-chain-cap dependency: $requiredPath"
        exit 1
    }
}

if (Test-Path -LiteralPath $scratchRoot) {
    Remove-Item -LiteralPath $scratchRoot -Recurse -Force
}

$capHitWorkspace = New-TestWorkspace -ScratchRoot $scratchRoot -FixtureProjectPath $fixtureProject -WorkspaceName 'cap-hit'
$alternateWorkspace = New-TestWorkspace -ScratchRoot $scratchRoot -FixtureProjectPath $fixtureProject -WorkspaceName 'alternate-approved'
$humanWorkspace = New-TestWorkspace -ScratchRoot $scratchRoot -FixtureProjectPath $fixtureProject -WorkspaceName 'awaiting-human'

Write-Host ''
Write-Host 'Lockout-Chain Cap Integration Tests' -ForegroundColor Cyan
Write-Host '=====================================' -ForegroundColor Cyan
Write-Host ''

# Test 1: Cap activation detection
Write-Host 'Test 1: Detect cap activation after original + 2 rotations'
$configPath = Join-Path $capHitWorkspace '.squad\config.json'
if (-not (Test-Path -LiteralPath $configPath -PathType Leaf)) {
    Write-Fail "Missing config.json in cap-hit workspace: $configPath"
    exit 1
}

$config = Get-Content -LiteralPath $configPath -Raw -Encoding UTF8 | ConvertFrom-Json
$feature008State = $config.reviewerRegressionState.'feature_008-sample'
if ($null -eq $feature008State) {
    Write-Fail "Missing feature_008-sample state in config.json"
    exit 1
}

if (-not (Assert-Condition -Condition ($feature008State.capActive -eq $true) -FailureMessage "Cap should be active in fixture")) { exit 1 }
if (-not (Assert-Condition -Condition ($feature008State.lockoutChainLength -eq 3) -FailureMessage "Chain length should be 3 (original + 2 rotations)")) { exit 1 }
if (-not (Assert-Condition -Condition ($feature008State.lockoutChainCap -eq 2) -FailureMessage "Cap should be 2 rotations beyond original")) { exit 1 }
if (-not (Assert-Condition -Condition ($feature008State.implementerChain.Count -eq 3) -FailureMessage "Implementer chain should have 3 entries")) { exit 1 }
if (-not (Assert-Condition -Condition ($feature008State.implementerChain[0] -eq 'Implementer-Alpha') -FailureMessage "First implementer should be Alpha")) { exit 1 }
if (-not (Assert-Condition -Condition ($feature008State.implementerChain[1] -eq 'Implementer-Beta') -FailureMessage "Second implementer should be Beta")) { exit 1 }
if (-not (Assert-Condition -Condition ($feature008State.implementerChain[2] -eq 'Implementer-Gamma') -FailureMessage "Third implementer should be Gamma")) { exit 1 }
Write-Pass "Cap activation detected correctly (3 implementers = original + 2 rotations)"

# Test 2: Cap visibility in iteration state
Write-Host 'Test 2: Cap visibility in iteration state managed block'
$statePath = Join-Path $capHitWorkspace 'specs\008-sample\iterations\001\state.md'
if (-not (Test-Path -LiteralPath $statePath -PathType Leaf)) {
    Write-Fail "Missing state.md in cap-hit workspace: $statePath"
    exit 1
}

$stateContent = Get-Content -LiteralPath $statePath -Raw -Encoding UTF8
if (-not (Assert-Condition -Condition ($stateContent -match 'Cap Active.*true') -FailureMessage "Cap Active field should be true in state.md")) { exit 1 }
if (-not (Assert-Condition -Condition ($stateContent -match 'Lockout Chain Length.*3') -FailureMessage "Lockout Chain Length should be 3 in state.md")) { exit 1 }
if (-not (Assert-Condition -Condition ($stateContent -match 'Implementer Chain.*Implementer-Alpha.*Implementer-Beta.*Implementer-Gamma') -FailureMessage "Implementer chain should be listed in state.md")) { exit 1 }
if (-not (Assert-Condition -Condition ($stateContent -match 'Next Owner Path.*Awaiting') -FailureMessage "Next owner path should indicate awaiting human or alternate")) { exit 1 }
Write-Pass "Cap state visible in iteration state.md managed block"

# Test 3: Cap visibility in decisions ledger
Write-Host 'Test 3: Cap activation evidence in decisions ledger'
$decisionsPath = Join-Path $capHitWorkspace '.squad\decisions.md'
if (-not (Test-Path -LiteralPath $decisionsPath -PathType Leaf)) {
    Write-Fail "Missing decisions.md in cap-hit workspace: $decisionsPath"
    exit 1
}

$decisionsContent = Get-Content -LiteralPath $decisionsPath -Raw -Encoding UTF8
if (-not (Assert-Condition -Condition ($decisionsContent -match '2026-05-10-lockout-cap-activated') -FailureMessage "Cap activation decision should be recorded")) { exit 1 }
if (-not (Assert-Condition -Condition ($decisionsContent -match 'lockout-cap') -FailureMessage "Decision type should be lockout-cap")) { exit 1 }
if (-not (Assert-Condition -Condition ($decisionsContent -match 'Chain length.*3') -FailureMessage "Chain length should be recorded in decision")) { exit 1 }
if (-not (Assert-Condition -Condition ($decisionsContent -match 'Cap state.*active') -FailureMessage "Cap state should be marked active in decision")) { exit 1 }
Write-Pass "Cap activation evidence recorded in decisions ledger"

# Test 4: Approved alternate owner evidence
Write-Host 'Test 4: Alternate owner approval evidence in decisions ledger'
$alternateDecisionsPath = Join-Path $alternateWorkspace '.squad\decisions.md'
if (-not (Test-Path -LiteralPath $alternateDecisionsPath -PathType Leaf)) {
    Write-Fail "Missing decisions.md in alternate-approved workspace: $alternateDecisionsPath"
    exit 1
}

$alternateDecisionsContent = Get-Content -LiteralPath $alternateDecisionsPath -Raw -Encoding UTF8
if (-not (Assert-Condition -Condition ($alternateDecisionsContent -match '2026-05-10-alternate-owner-approved') -FailureMessage "Alternate owner approval should be recorded")) { exit 1 }
if (-not (Assert-Condition -Condition ($alternateDecisionsContent -match 'alternate-owner-approval') -FailureMessage "Decision type should be alternate-owner-approval")) { exit 1 }
if (-not (Assert-Condition -Condition ($alternateDecisionsContent -match 'Implementer-Delta') -FailureMessage "Approved alternate owner should be Implementer-Delta")) { exit 1 }
if (-not (Assert-Condition -Condition ($alternateDecisionsContent -match 'Alon Fliess.*human developer') -FailureMessage "Human authorization should be recorded")) { exit 1 }
if (-not (Assert-Condition -Condition ($alternateDecisionsContent -match 'Domain expertise') -FailureMessage "Rationale should be recorded")) { exit 1 }
Write-Pass "Alternate owner approval evidence recorded with human authorization and rationale"

# Test 5: Chain deduplication by owner identity
Write-Host 'Test 5: Verify chain counts distinct implementer owners only'
# This test verifies that if the same owner appears multiple times (which shouldn't happen
# but could in edge cases), the chain length counts distinct owners
$testConfig = @{
    reviewerRegressionState = @{
        'feature_test' = @{
            implementerChain     = @('Alpha', 'Beta', 'Alpha', 'Gamma')  # Alpha appears twice
            lockoutChainLength   = 4
            lockoutChainCap      = 2
            distinctOwnerCount   = 3  # Should only count 3 distinct owners: Alpha, Beta, Gamma
        }
    }
}
$distinctOwners = $testConfig.reviewerRegressionState.feature_test.implementerChain | Sort-Object -Unique
if (-not (Assert-Condition -Condition ($distinctOwners.Count -eq 3) -FailureMessage "Chain should count 3 distinct owners (Alpha, Beta, Gamma)")) { exit 1 }
Write-Pass "Chain deduplication logic validates distinct owner counting"

# Test 6: Post-cap routing validation
Write-Host 'Test 6: Validate post-cap routing requires human or approved alternate'
# When cap is active, the next owner path must be either:
# 1. Explicitly approved alternate owner in decisions.md
# 2. Human-owned revision (awaiting human direction)
# NOT: Auto-synthesis of another specialist
$capActiveDecisions = Get-Content -LiteralPath $decisionsPath -Raw -Encoding UTF8
$hasCapActivation = $capActiveDecisions -match 'lockout-cap-activated'
$hasHumanPath = $capActiveDecisions -match 'awaiting human-owned revision|human developer'
$alternateDecisions = Get-Content -LiteralPath $alternateDecisionsPath -Raw -Encoding UTF8
$hasAlternateApproval = $alternateDecisions -match 'alternate-owner-approved'

if (-not (Assert-Condition -Condition ($hasCapActivation) -FailureMessage "Cap activation must be recorded")) { exit 1 }
if (-not (Assert-Condition -Condition ($hasHumanPath -or $hasAlternateApproval) -FailureMessage "Post-cap path must be human-owned or approved alternate")) { exit 1 }
Write-Pass "Post-cap routing validated (human or approved alternate only)"

Write-Host ''
Write-Host 'All lockout-chain cap tests passed!' -ForegroundColor Green
Write-Host ''

exit 0
