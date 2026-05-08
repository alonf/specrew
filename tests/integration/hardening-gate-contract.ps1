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

function Assert-True {
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

function Assert-Equal {
    param(
        [AllowNull()]
        [Parameter(Mandatory = $true)]
        [object]$Actual,

        [AllowNull()]
        [Parameter(Mandatory = $true)]
        [object]$Expected,

        [Parameter(Mandatory = $true)]
        [string]$FailureMessage
    )

    if ($Actual -cne $Expected) {
        Write-Fail ("{0} Expected '{1}', observed '{2}'." -f $FailureMessage, $Expected, $Actual)
        return $false
    }

    return $true
}

function Assert-Contains {
    param(
        [Parameter(Mandatory = $true)]
        [string]$Content,

        [Parameter(Mandatory = $true)]
        [string]$Pattern,

        [Parameter(Mandatory = $true)]
        [string]$FailureMessage
    )

    if ($Content -notmatch $Pattern) {
        Write-Fail $FailureMessage
        return $false
    }

    return $true
}

function Assert-StringNotNullish {
    param(
        [AllowNull()]
        [Parameter(Mandatory = $true)]
        [string]$Value,

        [Parameter(Mandatory = $true)]
        [string]$FailureMessage
    )

    if (Test-IsNullish $Value) {
        Write-Fail $FailureMessage
        return $false
    }

    return $true
}

function Assert-ConcernStatus {
    param(
        [Parameter(Mandatory = $true)]
        [object[]]$Concerns,

        [Parameter(Mandatory = $true)]
        [string]$ConcernId,

        [Parameter(Mandatory = $true)]
        [string]$ExpectedStatus,

        [string]$ExpectedApproval,

        [Parameter(Mandatory = $true)]
        [string]$ScenarioName
    )

    $matches = @($Concerns | Where-Object { [string]$_.Concern -eq $ConcernId })
    if ($matches.Count -ne 1) {
        Write-Fail ("{0} fixture should contain exactly one concern row for '{1}'." -f $ScenarioName, $ConcernId)
        return $false
    }

    $allChecksPassed = $true
    $concern = $matches[0]
    if (-not (Assert-Equal -Actual ([string]$concern.Status) -Expected $ExpectedStatus -FailureMessage ("{0} fixture recorded the wrong status for '{1}'." -f $ScenarioName, $ConcernId))) {
        $allChecksPassed = $false
    }

    if (-not (Assert-Equal -Actual ([string]$concern.Blocking) -Expected 'true' -FailureMessage ("{0} fixture should keep '{1}' marked blocking for explicit readiness evaluation." -f $ScenarioName, $ConcernId))) {
        $allChecksPassed = $false
    }

    if (-not (Assert-StringNotNullish -Value ([string]$concern.Rationale) -FailureMessage ("{0} fixture should keep rationale visible for '{1}'." -f $ScenarioName, $ConcernId))) {
        $allChecksPassed = $false
    }

    if ($PSBoundParameters.ContainsKey('ExpectedApproval')) {
        if (-not (Assert-Equal -Actual ([string]$concern.Approval) -Expected $ExpectedApproval -FailureMessage ("{0} fixture recorded the wrong approval reference for '{1}'." -f $ScenarioName, $ConcernId))) {
            $allChecksPassed = $false
        }
    }
    elseif (-not (Assert-True -Condition (Test-IsNullish ([string]$concern.Approval)) -FailureMessage ("{0} fixture should not require an approval reference for '{1}'." -f $ScenarioName, $ConcernId))) {
        $allChecksPassed = $false
    }

    return $allChecksPassed
}

$repoRoot = (Resolve-Path (Join-Path -Path $PSScriptRoot -ChildPath '..\..')).Path
$sharedGovernancePath = Join-Path $repoRoot 'extensions\specrew-speckit\scripts\shared-governance.ps1'
$fixtureRoot = Join-Path $repoRoot 'tests\integration\fixtures\hardening-gate-contract'

foreach ($requiredPath in @($sharedGovernancePath, $fixtureRoot)) {
    if (-not (Test-Path -LiteralPath $requiredPath)) {
        Write-Fail "Missing hardening-gate contract dependency: $requiredPath"
        exit 1
    }
}

. $sharedGovernancePath

$allChecksPassed = $true
$scenarios = @(
    @{
        Name                    = 'blocked'
        Verdict                 = 'blocked'
        BlocksImplementation    = $true
        ExpectedBlockingConcern = 'test-integrity-targets'
        ExpectedMetadataApproval = $null
    },
    @{
        Name                    = 'approved-deferral'
        Verdict                 = 'deferred-with-approval'
        BlocksImplementation    = $false
        ExpectedBlockingConcern = $null
        ExpectedMetadataApproval = 'defer-hardening-operational-follow-up'
    },
    @{
        Name                    = 'ready'
        Verdict                 = 'ready'
        BlocksImplementation    = $false
        ExpectedBlockingConcern = $null
        ExpectedMetadataApproval = $null
    }
)

foreach ($scenario in $scenarios) {
    $scenarioRoot = Join-Path $fixtureRoot $scenario.Name
    $gatePath = Join-Path $scenarioRoot 'specs\005-quality-evidence\iterations\001\quality\hardening-gate.md'

    if (-not (Test-Path -LiteralPath $gatePath -PathType Leaf)) {
        Write-Fail ("Missing hardening-gate fixture for scenario '{0}': {1}" -f $scenario.Name, $gatePath)
        $allChecksPassed = $false
        continue
    }

    $gateState = Get-HardeningGateState -Path $gatePath -ProjectRoot $scenarioRoot
    $metadata = $gateState.Metadata

    foreach ($metadataCheck in @(
            @{ Actual = [string]$metadata.Schema; Expected = 'v1'; Failure = ("{0} fixture should keep schemaVersion v1." -f $scenario.Name) },
            @{ Actual = [string]$metadata.GateId; Expected = 'pre-implementation-hardening'; Failure = ("{0} fixture should keep the canonical hardening gate identifier." -f $scenario.Name) },
            @{ Actual = [string]$metadata.FeatureRef; Expected = 'specs/005-quality-evidence/spec.md'; Failure = ("{0} fixture should point at the fixture feature spec." -f $scenario.Name) },
            @{ Actual = [string]$metadata.IterationRef; Expected = 'specs/005-quality-evidence/iterations/001'; Failure = ("{0} fixture should point at the fixture iteration." -f $scenario.Name) },
            @{ Actual = [string]$metadata.RequestedReviewClass; Expected = 'strongest-available'; Failure = ("{0} fixture should request strongest-available hardening review." -f $scenario.Name) },
            @{ Actual = [string]$metadata.EffectiveReviewClass; Expected = 'claude'; Failure = ("{0} fixture should record the effective review class." -f $scenario.Name) },
            @{ Actual = [string]$metadata.OverallVerdict; Expected = [string]$scenario.Verdict; Failure = ("{0} fixture recorded the wrong overall verdict." -f $scenario.Name) },
            @{ Actual = [string]$metadata.ReviewedBy; Expected = 'Reviewer'; Failure = ("{0} fixture should preserve reviewer identity visibility." -f $scenario.Name) }
        )) {
        if (-not (Assert-Equal -Actual $metadataCheck.Actual -Expected $metadataCheck.Expected -FailureMessage $metadataCheck.Failure)) {
            $allChecksPassed = $false
        }
    }

    if (-not (Assert-StringNotNullish -Value ([string]$metadata.ReviewedAt) -FailureMessage ("{0} fixture should preserve reviewed-at visibility." -f $scenario.Name))) {
        $allChecksPassed = $false
    }

    if ($null -eq $scenario.ExpectedMetadataApproval) {
        if (-not (Assert-True -Condition (Test-IsNullish ([string]$metadata.ApprovalRef)) -FailureMessage ("{0} fixture should keep Approval Ref empty when no human deferment is required." -f $scenario.Name))) {
            $allChecksPassed = $false
        }
    }
    elseif (-not (Assert-Equal -Actual ([string]$metadata.ApprovalRef) -Expected ([string]$scenario.ExpectedMetadataApproval) -FailureMessage ("{0} fixture recorded the wrong gate-level Approval Ref." -f $scenario.Name))) {
        $allChecksPassed = $false
    }

    if (-not (Assert-Equal -Actual $gateState.ConcernRows.Count -Expected 5 -FailureMessage ("{0} fixture should review the full bounded hardening concern set." -f $scenario.Name))) {
        $allChecksPassed = $false
    }

    foreach ($concernCheck in @(
            @{ Concern = 'security-surface'; Status = 'addressed' },
            @{ Concern = 'error-handling-expectations'; Status = 'addressed' },
            @{ Concern = 'retry-idempotency-requirements'; Status = 'not-applicable' },
            @{ Concern = 'test-integrity-targets'; Status = $(if ($scenario.Name -eq 'blocked') { 'tbd' } else { 'addressed' }) },
            @{ Concern = 'operational-resilience-concerns'; Status = $(if ($scenario.Name -eq 'approved-deferral') { 'deferred-with-approval' } else { 'addressed' }); Approval = $(if ($scenario.Name -eq 'approved-deferral') { 'defer-hardening-operational-follow-up' } else { $null }) }
        )) {
        $assertParams = @{
            Concerns      = $gateState.ConcernRows
            ConcernId     = [string]$concernCheck.Concern
            ExpectedStatus = [string]$concernCheck.Status
            ScenarioName  = [string]$scenario.Name
        }

        if ($concernCheck.ContainsKey('Approval') -and $null -ne $concernCheck.Approval) {
            $assertParams.ExpectedApproval = [string]$concernCheck.Approval
        }

        if (-not (Assert-ConcernStatus @assertParams)) {
            $allChecksPassed = $false
        }
    }

    if (-not (Assert-Contains -Content ((@($gateState.ConcernRows | Where-Object { [string]$_.Concern -eq 'retry-idempotency-requirements' })[0]).Rationale) -Pattern 'read-only|idempotent' -FailureMessage ("{0} fixture should keep explicit retry/idempotency rationale visible for the not-applicable concern." -f $scenario.Name))) {
        $allChecksPassed = $false
    }

    if (-not (Assert-Equal -Actual $gateState.BlocksImplementation -Expected ([bool]$scenario.BlocksImplementation) -FailureMessage ("{0} fixture produced the wrong implementation-blocking state." -f $scenario.Name))) {
        $allChecksPassed = $false
    }

    if ($null -eq $scenario.ExpectedBlockingConcern) {
        if (-not (Assert-Equal -Actual $gateState.BlockingConcerns.Count -Expected 0 -FailureMessage ("{0} fixture should not leave any blocking concerns unresolved." -f $scenario.Name))) {
            $allChecksPassed = $false
        }
    }
    else {
        if (-not (Assert-Equal -Actual $gateState.BlockingConcerns.Count -Expected 1 -FailureMessage ("{0} fixture should leave exactly one blocking concern unresolved." -f $scenario.Name))) {
            $allChecksPassed = $false
        }
        elseif (-not (Assert-Equal -Actual ([string]$gateState.BlockingConcerns[0].Concern) -Expected ([string]$scenario.ExpectedBlockingConcern) -FailureMessage ("{0} fixture left the wrong concern blocking implementation." -f $scenario.Name))) {
            $allChecksPassed = $false
        }
    }
}

$approvedDeferralRoot = Join-Path $fixtureRoot 'approved-deferral'
$approvedDeferralGatePath = Join-Path $approvedDeferralRoot 'specs\005-quality-evidence\iterations\001\quality\hardening-gate.md'
$approvedDeferralState = Get-HardeningGateState -Path $approvedDeferralGatePath -ProjectRoot $approvedDeferralRoot
$approvedEntries = @(Get-DecisionsLedgerEntries -ProjectRoot $approvedDeferralRoot)

if (-not (Assert-Equal -Actual $approvedEntries.Count -Expected 1 -FailureMessage 'Approved-deferral fixture should include exactly one canonical decisions-ledger entry.')) {
    $allChecksPassed = $false
}
else {
    $entry = $approvedEntries[0]
    foreach ($entryCheck in @(
            @{ Actual = [string]$entry.DecisionId; Expected = 'defer-hardening-operational-follow-up'; Failure = 'Approved-deferral fixture decisions entry recorded the wrong Decision ID.' },
            @{ Actual = [string]$entry.Type; Expected = 'defer'; Failure = 'Approved-deferral fixture decisions entry should be typed as defer.' },
            @{ Actual = [string]$entry.AffectedRequirement; Expected = 'FR-033'; Failure = 'Approved-deferral fixture decisions entry should trace FR-033.' },
            @{ Actual = [string]$entry.AffectedIteration; Expected = 'specs\005-quality-evidence\iterations\001'; Failure = 'Approved-deferral fixture decisions entry should point at the fixture iteration.' },
            @{ Actual = [string]$entry.ApprovingHuman; Expected = 'Alon Fliess'; Failure = 'Approved-deferral fixture decisions entry should preserve human approval visibility.' }
        )) {
        if (-not (Assert-Equal -Actual $entryCheck.Actual -Expected $entryCheck.Expected -FailureMessage $entryCheck.Failure)) {
            $allChecksPassed = $false
        }
    }

    if (-not (Assert-Contains -Content ([string]$entry.RawText) -Pattern 'Affected Artifact.*quality\\hardening-gate\.md' -FailureMessage 'Approved-deferral fixture decisions entry should point back to the hardening-gate artifact.')) {
        $allChecksPassed = $false
    }
}

if (-not (Assert-True -Condition (Test-ApprovalReferenceHasHumanApproval -ProjectRoot $approvedDeferralRoot -ApprovalRef 'defer-hardening-operational-follow-up' -AllowedTypes @('defer')) -FailureMessage 'Approved-deferral fixture should resolve its defer reference to human approval.')) {
    $allChecksPassed = $false
}

if (-not (Assert-True -Condition ($null -ne $approvedDeferralState.ApprovalRecord) -FailureMessage 'Approved-deferral fixture should materialize an approval record on the hardening-gate state.')) {
    $allChecksPassed = $false
}
else {
    foreach ($approvalCheck in @(
            @{ Actual = [string]$approvedDeferralState.ApprovalRecord.DecisionId; Expected = 'defer-hardening-operational-follow-up'; Failure = 'Approved-deferral hardening state returned the wrong approval Decision ID.' },
            @{ Actual = [string]$approvedDeferralState.ApprovalRecord.Type; Expected = 'defer'; Failure = 'Approved-deferral hardening state returned the wrong approval type.' },
            @{ Actual = [string]$approvedDeferralState.ApprovalRecord.ApprovingHuman; Expected = 'Alon Fliess'; Failure = 'Approved-deferral hardening state returned the wrong approving human.' }
        )) {
        if (-not (Assert-Equal -Actual $approvalCheck.Actual -Expected $approvalCheck.Expected -FailureMessage $approvalCheck.Failure)) {
            $allChecksPassed = $false
        }
    }

    if (-not (Assert-True -Condition $approvedDeferralState.ApprovalRecord.HasHumanApproval -FailureMessage 'Approved-deferral hardening state should flag the defer reference as human-approved.')) {
        $allChecksPassed = $false
    }
}

if (-not $allChecksPassed) {
    exit 1
}

Write-Pass 'Hardening-gate fixtures keep blocked, approved-deferral, and ready scenarios deterministic with reviewable rationale and human-approved deferral evidence'
exit 0
