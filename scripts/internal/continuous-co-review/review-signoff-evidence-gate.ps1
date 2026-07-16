$ErrorActionPreference = 'Stop'
Set-StrictMode -Version Latest

# T067 / FR-025: the deterministic co-review gate-floor decision (re-architected).
#
# "You cannot sign off on un-reviewed state." The first model (diff_hash recomputed from an
# operator-chosen baseline) was found unsound by the feature's own dogfooded co-reviews:
# HOLE A (gitignored source invisible) and HOLE B (the operator baseline was never verified
# as reviewed). The sound model:
#   1. FRESHNESS - the CURRENT reviewed-state tree-id (content-addressed; includes tracked,
#      untracked, and gitignored source minus secrets) must equal a passing run's recorded
#      reviewed_tree_id. (Closes HOLE A + the untracked/empty/diff-parsing nits.)
#   2. COVERAGE - that run's chain must reach the merge-base-with-trunk anchor with no gap,
#      so everything the feature added on top of shipped trunk was reviewed. (Closes HOLE B.)
#   3. FAIL-CLOSED on every git/digest failure; an empty reviewed state never counts as fresh.
#   4. The only escape is a human-authorized, RECORDED partial-coverage override - never silent.
#
# This is the DECISION logic only. Wiring it into Invoke-SpecrewBoundaryStateSync as a
# throw-to-refuse gate stays deferred until the F-185 host-neutral gate-enforcement branch
# merges; Assert-ContinuousCoReviewSignoffGate is the thin throw-wrapper that wiring will call.

function New-ContinuousCoReviewSignoffGateDecision {
    param(
        [Parameter(Mandatory)]
        [ValidateSet('allow', 'block')]
        [string] $Decision,

        [Parameter(Mandatory)]
        [string] $Reason,

        [Parameter(Mandatory)]
        [string] $Message,

        [AllowNull()] [string] $CurrentTreeId,
        [AllowNull()] [string] $MatchedRunId,
        [AllowNull()] [string] $AnchorRef,
        [AllowNull()] $OverrideAuthorization,
        [AllowNull()] $EvidenceLabels,
        [AllowNull()] $Acknowledgement
    )

    return [pscustomobject][ordered]@{
        schema_version = '1.0'
        decision       = $Decision
        reason         = $Reason
        message        = $Message
        current_tree_id = $CurrentTreeId
        matched_run_id = $MatchedRunId
        anchor_ref     = $AnchorRef
        override       = $OverrideAuthorization
        evidence_labels = $EvidenceLabels
        acknowledgement = $Acknowledgement
    }
}

function Get-ContinuousCoReviewRunEvidenceLabels {
    # T094/FR-036 (iter-009 D4): a run record's 3-dimension assurance labels with CONSERVATIVE
    # defaults for records that predate the labels: completeness 'full' (promotion always required an
    # affirmative full pass), independence 'unverified' (unprovable -> not independent, SEC-004),
    # budget 'normal' ('time-extended' is NOT reduced assurance either way).
    param([AllowNull()] $Run)
    $labels = [pscustomobject]@{ completeness = 'full'; independence = 'unverified'; budget = 'normal' }
    if ($null -eq $Run) { return $labels }
    $recorded = Get-ContinuousCoReviewRunIndexProperty -Object $Run -Name 'evidence_labels'
    if ($null -eq $recorded) { return $labels }
    foreach ($dim in @('completeness', 'independence', 'budget')) {
        $val = [string](Get-ContinuousCoReviewRunIndexProperty -Object $recorded -Name $dim)
        if (-not [string]::IsNullOrWhiteSpace($val)) { $labels.$dim = $val }
    }
    return $labels
}

function Test-ContinuousCoReviewEvidenceIsDegraded {
    # D4 tiers: full + independent (any budget) is FULL assurance; anything else (partial OR a
    # not-provably-independent reviewer) is DEGRADED and needs a recorded human ack.
    param([Parameter(Mandatory)] $Labels)
    return (([string]$Labels.completeness -ne 'full') -or ([string]$Labels.independence -ne 'independent'))
}

function Add-ContinuousCoReviewDegradedAck {
    <#
        T094/FR-036: record the FIRST-CLASS human acknowledgement of degraded review evidence, as a
        durable per-run artifact (.specrew/review/inline/<run-id>/degraded-ack.json) the gate reads.
        TRUST BOUNDARY (same as the override + review-run.json, see Test-...OverrideAuthorization):
        construct only from a genuinely human-authored action (the `specrew review --ack-degraded`
        command / a captured human verdict), never from agent-forgeable input.
    #>
    param(
        [Parameter(Mandatory)][string] $RepoRoot,
        [Parameter(Mandatory)][string] $RunId,
        [Parameter(Mandatory)][string] $AuthorizedBy,
        [Parameter(Mandatory)][string] $Rationale,
        [datetime] $Now = [datetime]::UtcNow
    )
    if ([string]::IsNullOrWhiteSpace($AuthorizedBy) -or [string]::IsNullOrWhiteSpace($Rationale)) {
        throw 'Add-ContinuousCoReviewDegradedAck: -AuthorizedBy and -Rationale are both required (an ack is never implicit).'
    }
    $dir = Join-Path (Resolve-Path -LiteralPath $RepoRoot).Path ".specrew/review/inline/$RunId"
    New-Item -ItemType Directory -Path $dir -Force | Out-Null
    $ack = [pscustomobject][ordered]@{
        schema_version = '1.0'
        run_id         = $RunId
        authorized_by  = $AuthorizedBy
        rationale      = $Rationale
        acknowledged_at = $Now.ToUniversalTime().ToString('yyyy-MM-ddTHH:mm:ssZ', [System.Globalization.CultureInfo]::InvariantCulture)
    }
    $path = Join-Path $dir 'degraded-ack.json'
    Set-Content -LiteralPath $path -Value ($ack | ConvertTo-Json -Depth 8) -Encoding UTF8 -NoNewline
    return $ack
}

function Get-ContinuousCoReviewDegradedAck {
    param([Parameter(Mandatory)][string] $RepoRoot, [Parameter(Mandatory)][string] $RunId)
    $path = Join-Path (Resolve-Path -LiteralPath $RepoRoot).Path ".specrew/review/inline/$RunId/degraded-ack.json"
    if (-not (Test-Path -LiteralPath $path -PathType Leaf)) { return $null }
    try { return (Get-Content -LiteralPath $path -Raw -Encoding UTF8 | ConvertFrom-Json) } catch { return $null }
}

function Test-ContinuousCoReviewOverrideAuthorization {
    # A well-formed override is an object carrying a non-empty authorized_by AND rationale.
    # Anything less is ignored (the gate proceeds normally) - an override is never implicit.
    #
    # F3/F4 (145 adversarial review) - TRUST BOUNDARY, bound to the deferred F-185 wiring:
    # this decision layer AUTHENTICATES nothing (it trusts the structural object) and
    # PERSISTS nothing. The wiring owner (the boundary-sync integration) MUST (1) construct
    # this object only from a genuinely human-authored authorization (e.g. the captured
    # verdict / Add-SpecrewBoundaryAuthorization), never from agent-forgeable input, and
    # (2) persist the returned decision (incl. the override) to durable gate-verdict evidence
    # so "RECORDED, never silent" holds. The same boundary applies to the review-run.json
    # records the chain walk trusts. A test MUST assert override persistence when wired.
    param([AllowNull()] $OverrideAuthorization)

    if ($null -eq $OverrideAuthorization) {
        return $false
    }

    $authorizedBy = [string] (Get-ContinuousCoReviewRunIndexProperty -Object $OverrideAuthorization -Name 'authorized_by')
    $rationale = [string] (Get-ContinuousCoReviewRunIndexProperty -Object $OverrideAuthorization -Name 'rationale')
    return (-not [string]::IsNullOrWhiteSpace($authorizedBy)) -and (-not [string]::IsNullOrWhiteSpace($rationale))
}

function Get-ContinuousCoReviewChainReachesAnchor {
    # Walk the chain from the digest-matched run back toward the anchor: each link is a
    # passing run whose reviewed_ref equals the current run's baseline_ref. The chain reaches
    # the anchor when a baseline is an ancestor-of-or-equal-to the anchor (so [anchor, HEAD]
    # is fully covered); a baseline that is neither the anchor-or-earlier nor a prior pass's
    # reviewed point is a GAP (un-reviewed span -> block).
    param(
        [Parameter(Mandatory)]
        [string] $RepoRoot,

        [Parameter(Mandatory)]
        [object[]] $PassingRuns,

        [Parameter(Mandatory)]
        $MatchedRun,

        [Parameter(Mandatory)]
        [string] $AnchorRef
    )

    $byReviewedRef = @{}
    foreach ($run in @($PassingRuns)) {
        $reviewedRef = [string] (Get-ContinuousCoReviewRunIndexProperty -Object $run -Name 'reviewed_ref')
        if (-not [string]::IsNullOrWhiteSpace($reviewedRef) -and -not $byReviewedRef.ContainsKey($reviewedRef)) {
            $byReviewedRef[$reviewedRef] = $run
        }
    }

    $current = $MatchedRun
    $visited = New-Object System.Collections.Generic.HashSet[string]
    for ($i = 0; $i -lt 4096; $i++) {
        $baseline = [string] (Get-ContinuousCoReviewRunIndexProperty -Object $current -Name 'baseline_ref')
        if ([string]::IsNullOrWhiteSpace($baseline)) {
            return [pscustomobject]@{ reached = $false; gap_at = [string] (Get-ContinuousCoReviewRunIndexProperty -Object $current -Name 'run_id') }
        }

        if (Get-ContinuousCoReviewGitIsAncestor -RepoRoot $RepoRoot -Ancestor $baseline -Descendant $AnchorRef) {
            return [pscustomobject]@{ reached = $true; gap_at = $null }
        }

        $runId = [string] (Get-ContinuousCoReviewRunIndexProperty -Object $current -Name 'run_id')
        if (-not $visited.Add($runId)) {
            return [pscustomobject]@{ reached = $false; gap_at = 'cycle' }
        }

        if (-not $byReviewedRef.ContainsKey($baseline)) {
            return [pscustomobject]@{ reached = $false; gap_at = $baseline }
        }

        $current = $byReviewedRef[$baseline]
    }

    return [pscustomobject]@{ reached = $false; gap_at = 'chain-too-long' }
}

function New-ReviewCampaignVerdictPacketDecision {
    param(
        [Parameter(Mandatory)][string]$Route,
        [Parameter(Mandatory)][string]$Reason,
        [Parameter(Mandatory)][string]$Message,
        [string]$CampaignId,
        [string]$RunId,
        [string]$TargetDigest,
        [bool]$RenderBoundaryPacket = $false,
        [bool]$AskNarrowQuestion = $false,
        [string]$ImplementerAction = 'wait'
    )
    return [pscustomobject][ordered]@{
        schema_version = '1.0'; route = $Route; reason = $Reason; message = $Message
        campaign_id = $CampaignId; run_id = $RunId; target_digest = $TargetDigest
        render_boundary_packet = $RenderBoundaryPacket; render_verdict_marker = $RenderBoundaryPacket
        ask_narrow_question = $AskNarrowQuestion; implementer_action = $ImplementerAction
    }
}

function Resolve-ReviewCampaignVerdictPacketDecision {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)][string]$CampaignId,
        [Parameter(Mandatory)][string]$CurrentDigest,
        [AllowEmptyCollection()][string[]]$OrderedRunIds = @(),
        [AllowEmptyCollection()][object[]]$Results = @(),
        [AllowNull()]$ActiveRun,
        [AllowEmptyCollection()][object[]]$HumanDispositions = @()
    )
    if (-not (Test-ReviewAuthorityIdentifier -Value $CampaignId -Kind campaign) -or [string]::IsNullOrWhiteSpace($CurrentDigest)) {
        return New-ReviewCampaignVerdictPacketDecision -Route 'review-failure' -Reason 'campaign-or-digest-invalid' -Message 'Campaign identity or current digest is unavailable; no lifecycle verdict may be requested.' -CampaignId $CampaignId -TargetDigest $CurrentDigest -ImplementerAction 'repair-review-state'
    }
    $byRun = @{}
    foreach ($result in @($Results)) {
        $validation = Test-ReviewAuthorityContractObject -ContractName ReviewResult -InputObject $result -ExpectedCampaignId $CampaignId
        if (-not $validation.valid) {
            return New-ReviewCampaignVerdictPacketDecision -Route 'review-failure' -Reason ('campaign-result-invalid:' + $validation.category) -Message 'Campaign result authority is malformed or identity-mismatched; no lifecycle verdict may be requested.' -CampaignId $CampaignId -TargetDigest $CurrentDigest -ImplementerAction 'repair-review-state'
        }
        $runId = [string]$result.run_id
        if ($byRun.ContainsKey($runId)) {
            return New-ReviewCampaignVerdictPacketDecision -Route 'review-failure' -Reason 'duplicate-terminal-result-for-run' -Message 'Conflicting terminal results exist for one run; review authority fails closed.' -CampaignId $CampaignId -RunId $runId -TargetDigest $CurrentDigest -ImplementerAction 'repair-review-state'
        }
        $byRun[$runId] = $result
    }
    $ordered = [Collections.Generic.List[string]]::new()
    foreach ($runId in @($OrderedRunIds)) {
        if (-not (Test-ReviewAuthorityIdentifier -Value $runId -Kind run) -or $ordered.Contains($runId)) {
            return New-ReviewCampaignVerdictPacketDecision -Route 'review-failure' -Reason 'campaign-run-order-invalid' -Message 'Campaign run order is malformed or ambiguous; review authority fails closed.' -CampaignId $CampaignId -TargetDigest $CurrentDigest -ImplementerAction 'repair-review-state'
        }
        $ordered.Add($runId) | Out-Null
    }

    if ($null -ne $ActiveRun) {
        $activeValidation = Test-ReviewAuthorityContractObject -ContractName ReviewRun -InputObject $ActiveRun -ExpectedCampaignId $CampaignId
        if (-not $activeValidation.valid) {
            return New-ReviewCampaignVerdictPacketDecision -Route 'review-failure' -Reason 'active-run-invalid' -Message 'The active campaign run is malformed; review authority fails closed.' -CampaignId $CampaignId -TargetDigest $CurrentDigest -ImplementerAction 'repair-review-state'
        }
        $activeRunId = [string]$ActiveRun.run_id
        if ($byRun.ContainsKey($activeRunId)) {
            return New-ReviewCampaignVerdictPacketDecision -Route 'review-failure' -Reason 'terminal-result-still-has-active-claim' -Message 'A terminal result exists while its run claim is still active; reconciliation must retire the claim before signoff.' -CampaignId $CampaignId -RunId $activeRunId -TargetDigest $CurrentDigest -ImplementerAction 'reconcile-run-claim'
        }
        if ([string]$ActiveRun.target_digest -ceq $CurrentDigest) {
            return New-ReviewCampaignVerdictPacketDecision -Route 'review-running' -Reason 'current-review-in-flight' -Message 'The single campaign review for the current digest is still running; no human decision is required.' -CampaignId $CampaignId -RunId $activeRunId -TargetDigest $CurrentDigest -ImplementerAction 'poll-existing-run'
        }
        return New-ReviewCampaignVerdictPacketDecision -Route 'review-stale' -Reason 'in-flight-review-target-moved' -Message 'The active review targets an earlier digest and cannot authorize the current tree.' -CampaignId $CampaignId -RunId $activeRunId -TargetDigest $CurrentDigest -ImplementerAction 'complete-or-reconcile-then-rerun-current'
    }

    if ($ordered.Count -eq 0) {
        return New-ReviewCampaignVerdictPacketDecision -Route 'review-required' -Reason 'no-authoritative-campaign-result' -Message 'No claim-ordered campaign result can authorize the current digest.' -CampaignId $CampaignId -TargetDigest $CurrentDigest -ImplementerAction 'request-authorized-review'
    }

    # A newer claimed invocation supersedes every older result, including an older clean result.
    # Otherwise a final timed-out/partial review (for example T061's signoff harness) could silently
    # fall back to an earlier pass. A claimed run without its terminal result is recovery work, not
    # permission to select around the gap.
    $latestRunId = $ordered[$ordered.Count - 1]
    if (-not $byRun.ContainsKey($latestRunId)) {
        return New-ReviewCampaignVerdictPacketDecision -Route 'review-failure' -Reason 'latest-claimed-run-missing-result' -Message 'The latest claimed campaign run has no terminal result; reconciliation must close the gap before signoff.' -CampaignId $CampaignId -RunId $latestRunId -TargetDigest $CurrentDigest -ImplementerAction 'reconcile-run-claim'
    }
    $latest = $byRun[$latestRunId]
    if ([string]$latest.target_digest -cne $CurrentDigest -or [string]$latest.currentness -ceq 'snapshot-moved') {
        return New-ReviewCampaignVerdictPacketDecision -Route 'review-stale' -Reason 'latest-result-not-current' -Message 'The latest campaign result remains useful evidence but targets a moved or earlier snapshot and cannot authorize the current tree.' -CampaignId $CampaignId -RunId $latestRunId -TargetDigest $CurrentDigest -ImplementerAction 'request-current-digest-review'
    }
    if ([string]$latest.runtime_outcome -ceq 'timed-out') {
        return New-ReviewCampaignVerdictPacketDecision -Route 'review-timeout' -Reason 'latest-review-timed-out' -Message ('The review timed out: ' + [string]$latest.failure_reason) -CampaignId $CampaignId -RunId $latestRunId -TargetDigest $CurrentDigest -ImplementerAction 'report-failure-and-request-rerun-grant'
    }
    if ([string]$latest.completion -cne 'complete') {
        return New-ReviewCampaignVerdictPacketDecision -Route 'review-partial' -Reason 'latest-review-incomplete' -Message 'Validated partial findings remain advisory, but a complete separately authorized run is required.' -CampaignId $CampaignId -RunId $latestRunId -TargetDigest $CurrentDigest -ImplementerAction 'use-partial-findings-and-request-rerun-grant'
    }
    if ([string]$latest.validation -cne 'valid' -or [string]$latest.currentness -cne 'current') {
        return New-ReviewCampaignVerdictPacketDecision -Route 'review-failure' -Reason ('latest-review-' + [string]$latest.runtime_outcome) -Message ('The campaign review failed: ' + [string]$latest.failure_reason) -CampaignId $CampaignId -RunId $latestRunId -TargetDigest $CurrentDigest -ImplementerAction 'report-failure-and-request-rerun-grant'
    }
    if ([bool]$latest.can_approve_current -and [string]$latest.verdict -ceq 'pass') {
        return New-ReviewCampaignVerdictPacketDecision -Route 'boundary-clean' -Reason 'complete-current-clean-result' -Message 'The authoritative campaign result is a complete valid pass for the exact current digest.' -CampaignId $CampaignId -RunId $latestRunId -TargetDigest $CurrentDigest -RenderBoundaryPacket $true -ImplementerAction 'render-boundary-packet'
    }
    if ([string]$latest.verdict -ceq 'findings') {
        $matchingDispositions = @($HumanDispositions | Where-Object {
            $v = Test-ReviewAuthorityContractObject -ContractName HumanDispositionFact -InputObject $_ -ExpectedCampaignId $CampaignId -ExpectedRunId $latestRunId -ExpectedTargetDigest $CurrentDigest
            $v.valid
        })
        $requiresCorrection = @($matchingDispositions | Where-Object { [string]$_.decision -ceq 'require-correction' }).Count -gt 0
        $accepted = @($matchingDispositions | Where-Object { [string]$_.decision -ceq 'accept-current' }).Count -gt 0
        if ($accepted -and -not $requiresCorrection) {
            return New-ReviewCampaignVerdictPacketDecision -Route 'boundary-human-disposition' -Reason 'complete-current-findings-human-accepted' -Message 'The exact current result has an explicit identity-bound human disposition accepting its findings.' -CampaignId $CampaignId -RunId $latestRunId -TargetDigest $CurrentDigest -RenderBoundaryPacket $true -ImplementerAction 'render-boundary-packet'
        }
        $actionable = @($latest.findings | Where-Object { [string]$_.resolution -ceq 'open' -and [string]$_.severity -in @('blocking', 'major') }).Count -gt 0
        if ($actionable -or $requiresCorrection) {
            return New-ReviewCampaignVerdictPacketDecision -Route 'review-actionable' -Reason 'complete-current-actionable-findings' -Message 'The exact current review has actionable findings; suppress the boundary packet, correct them, and run a separately authorized review.' -CampaignId $CampaignId -RunId $latestRunId -TargetDigest $CurrentDigest -ImplementerAction 'fix-and-request-rerun-grant'
        }
        return New-ReviewCampaignVerdictPacketDecision -Route 'review-human-decision' -Reason 'complete-current-advisory-findings' -Message 'The exact current review has advisory findings that require a narrow human disposition before any boundary packet.' -CampaignId $CampaignId -RunId $latestRunId -TargetDigest $CurrentDigest -AskNarrowQuestion $true -ImplementerAction 'ask-narrow-non-boundary-question'
    }
    return New-ReviewCampaignVerdictPacketDecision -Route 'review-failure' -Reason ('latest-review-' + [string]$latest.runtime_outcome) -Message ('The campaign review failed: ' + [string]$latest.failure_reason) -CampaignId $CampaignId -RunId $latestRunId -TargetDigest $CurrentDigest -ImplementerAction 'report-failure-and-request-rerun-grant'
}

function Get-ReviewCampaignVerdictPacketDecision {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)][string]$RepoRoot,
        [string]$CampaignId,
        [string]$TargetLineage,
        [string]$StoreRoot,
        [string]$FeatureId,
        [string]$IterationNumber,
        [string[]]$ExcludedPathPatterns = @()
    )
    $root = (Resolve-Path -LiteralPath $RepoRoot).Path
    if ([string]::IsNullOrWhiteSpace($CampaignId) -or [string]::IsNullOrWhiteSpace($TargetLineage)) {
        $identity = Resolve-ReviewCampaignPublicIdentity -RepoRoot $root -FeatureId $FeatureId -IterationNumber $IterationNumber -RunId 'run-gate-probe'
        if ([string]::IsNullOrWhiteSpace($CampaignId)) { $CampaignId = [string]$identity.campaign_id }
        if ([string]::IsNullOrWhiteSpace($TargetLineage)) { $TargetLineage = [string]$identity.target_lineage }
    }
    if ([string]::IsNullOrWhiteSpace($StoreRoot)) { $StoreRoot = Join-Path $root '.specrew/review/authority' }
    $digest = Get-ContinuousCoReviewReviewedStateDigest -RepoRoot $root -ExcludedPathPatterns $ExcludedPathPatterns
    if ($null -eq $digest -or -not $digest.ok -or [string]::IsNullOrWhiteSpace([string]$digest.tree_id)) {
        return New-ReviewCampaignVerdictPacketDecision -Route 'review-failure' -Reason 'digest-unresolvable' -Message 'The current reviewed-state digest could not be computed; no lifecycle verdict may be requested.' -CampaignId $CampaignId -ImplementerAction 'repair-review-state'
    }
    $claimFacts = @(Get-ReviewAuthorityClaimFacts -StoreRoot $StoreRoot -CampaignId $CampaignId -TargetLineage $TargetLineage)
    $orderedRunIds = @($claimFacts | Where-Object { [string]$_.fact_type -ceq 'claim-held' } | Sort-Object { [int]$_.generation } | ForEach-Object { [string]$_.run_id })
    $activeClaim = Get-ReviewAuthorityActiveClaim -Facts $claimFacts
    $activeRun = if ($null -ne $activeClaim) { Get-ReviewRunLatestStateFact -StoreRoot $StoreRoot -CampaignId $CampaignId -RunId ([string]$activeClaim.run_id) } else { $null }
    if ($null -ne $activeClaim -and $null -eq $activeRun) {
        return New-ReviewCampaignVerdictPacketDecision -Route 'review-failure' -Reason 'active-claim-run-state-missing' -Message 'An active campaign claim has no readable run state; reconciliation must repair the authority gap before signoff.' -CampaignId $CampaignId -RunId ([string]$activeClaim.run_id) -TargetDigest ([string]$digest.tree_id) -ImplementerAction 'reconcile-run-claim'
    }
    $results = @(Get-ReviewAuthorityCampaignRunResults -StoreRoot $StoreRoot -CampaignId $CampaignId)
    $dispositions = @(Get-ReviewCampaignHumanDispositionFacts -StoreRoot $StoreRoot -CampaignId $CampaignId)
    return Resolve-ReviewCampaignVerdictPacketDecision -CampaignId $CampaignId -CurrentDigest ([string]$digest.tree_id) -OrderedRunIds $orderedRunIds -Results $results -ActiveRun $activeRun -HumanDispositions $dispositions
}

function Get-ContinuousCoReviewSignoffGateDecision {
    param(
        [Parameter(Mandatory)]
        [string] $RepoRoot,

        [AllowEmptyString()][string] $TrunkName = '',

        [string[]] $ExcludedPathPatterns = @(),

        [AllowNull()] $OverrideAuthorization,

        # T094/FR-036: an explicit degraded-evidence acknowledgement (authorized_by + rationale).
        # When omitted, the persisted per-run ack (degraded-ack.json) is honoured instead.
        [AllowNull()] $DegradedAcknowledgement,

        [string] $AuthorityConfigPath,
        [string] $CampaignId,
        [string] $TargetLineage,
        [string] $FeatureId,
        [string] $IterationNumber,
        [string] $CampaignStoreRoot
    )

    $resolvedRepoRoot = (Resolve-Path -LiteralPath $RepoRoot).Path

    $authority = if (Get-Command -Name 'Get-ContinuousCoReviewAuthorityDecision' -ErrorAction SilentlyContinue) {
        Get-ContinuousCoReviewAuthorityDecision -ConfigPath $AuthorityConfigPath
    }
    else { [pscustomobject]@{ mode = 'disabled'; valid = $false; legacy_promotion_enabled = $false; campaign_authority_enabled = $false; reason = 'authority-cutover-helper-missing' } }
    if (-not $authority.valid -or [string]$authority.mode -ceq 'disabled') {
        return New-ContinuousCoReviewSignoffGateDecision -Decision 'block' -Reason ('review-authority-disabled:' + [string]$authority.reason) -Message 'Review authority is missing, malformed, or disabled; neither legacy nor campaign evidence may authorize signoff.'
    }
    if ([bool]$authority.campaign_authority_enabled) {
        try {
            $packet = Get-ReviewCampaignVerdictPacketDecision -RepoRoot $resolvedRepoRoot -CampaignId $CampaignId -TargetLineage $TargetLineage -StoreRoot $CampaignStoreRoot -FeatureId $FeatureId -IterationNumber $IterationNumber -ExcludedPathPatterns $ExcludedPathPatterns
        }
        catch {
            return New-ContinuousCoReviewSignoffGateDecision -Decision 'block' -Reason 'campaign-review-state-invalid' -Message ('Campaign review authority could not be read safely: ' + $_.Exception.Message)
        }
        $decision = New-ContinuousCoReviewSignoffGateDecision -Decision $(if ($packet.render_boundary_packet) { 'allow' } else { 'block' }) -Reason $packet.reason -Message $packet.message -CurrentTreeId $packet.target_digest -MatchedRunId $packet.run_id
        foreach ($property in @('route', 'campaign_id', 'render_boundary_packet', 'render_verdict_marker', 'ask_narrow_question', 'implementer_action')) {
            $decision | Add-Member -NotePropertyName $property -NotePropertyValue $packet.$property
        }
        return $decision
    }

    # A well-formed human-authorized recorded override short-circuits, with the authorization
    # captured in the decision evidence (auditable, never silent).
    if (Test-ContinuousCoReviewOverrideAuthorization -OverrideAuthorization $OverrideAuthorization) {
        return New-ContinuousCoReviewSignoffGateDecision -Decision 'allow' -Reason 'human-authorized-partial-override' -Message 'Signoff allowed under a recorded human-authorized partial-coverage override.' -OverrideAuthorization $OverrideAuthorization
    }

    # 1. Current reviewed-state digest (fail-closed on any digest/git failure).
    $digest = Get-ContinuousCoReviewReviewedStateDigest -RepoRoot $resolvedRepoRoot -ExcludedPathPatterns $ExcludedPathPatterns
    if (-not $digest.ok) {
        return New-ContinuousCoReviewSignoffGateDecision -Decision 'block' -Reason 'digest-unresolvable' -Message "The current reviewed-state digest could not be computed ($($digest.failure_reason)); treat as unsafe."
    }
    if ($digest.is_empty) {
        return New-ContinuousCoReviewSignoffGateDecision -Decision 'block' -Reason 'empty-reviewed-state' -Message 'The current reviewable working tree is empty; there is no reviewed content to sign off on.' -CurrentTreeId $digest.tree_id
    }

    # 2. Trusted anchor = merge-base with the trunk (fail-closed if it cannot be resolved).
    $anchor = Get-ContinuousCoReviewMergeBaseAnchor -RepoRoot $resolvedRepoRoot -TrunkName $TrunkName
    if ([string]::IsNullOrWhiteSpace($anchor)) {
        return New-ContinuousCoReviewSignoffGateDecision -Decision 'block' -Reason 'anchor-unresolvable' -Message "The trusted anchor (merge-base with '$TrunkName') could not be resolved; coverage cannot be verified." -CurrentTreeId $digest.tree_id
    }

    # 3. Lineage-valid passing runs.
    $passingRuns = @(Get-ContinuousCoReviewPassingReviewRuns -RepoRoot $resolvedRepoRoot -AncestorOfRef 'HEAD')
    if ($passingRuns.Count -eq 0) {
        return New-ContinuousCoReviewSignoffGateDecision -Decision 'block' -Reason 'no-co-review-evidence' -Message 'No passing or escalated co-review run on this lineage; the current state has not been co-reviewed.' -CurrentTreeId $digest.tree_id -AnchorRef $anchor
    }

    # 4. Freshness: a passing run whose recorded reviewed_tree_id equals the current digest.
    $matched = $null
    $emptyTreeId = Get-ContinuousCoReviewEmptyTreeId
    foreach ($run in $passingRuns) {
        $recordedTreeId = [string] (Get-ContinuousCoReviewRunIndexProperty -Object $run -Name 'reviewed_tree_id')
        if ([string]::IsNullOrWhiteSpace($recordedTreeId) -or $recordedTreeId -eq $emptyTreeId) {
            continue
        }
        if ($recordedTreeId -eq $digest.tree_id) {
            $matched = $run
            break
        }
    }
    # 4b. F-198 FR-020 (mechanism b): the ANNOUNCED tracker-only bypass. When no run matches
    # exactly, a passing run whose ONLY delta to the current tree is machine-managed tracker
    # bookkeeping - with claims verified as a subset of the review record that run already
    # accepted - keeps its evidence fresh. Fail-closed: any parse ambiguity or claim increase
    # falls through to the stale block exactly as before. The digest formula is untouched.
    $honestyBypassNote = $null
    $dishonestReason = $null
    if ($null -eq $matched -and (Get-Command -Name 'Get-ContinuousCoReviewTrackerOnlyDelta' -ErrorAction SilentlyContinue)) {
        foreach ($run in $passingRuns) {
            $recordedTreeId = [string] (Get-ContinuousCoReviewRunIndexProperty -Object $run -Name 'reviewed_tree_id')
            if ([string]::IsNullOrWhiteSpace($recordedTreeId) -or $recordedTreeId -eq $emptyTreeId) { continue }
            $delta = Get-ContinuousCoReviewTrackerOnlyDelta -RepoRoot $resolvedRepoRoot -FromTreeId $recordedTreeId -ToTreeId $digest.tree_id
            if (-not $delta.Ok -or -not $delta.TrackerOnly) { continue }
            $honesty = Test-ContinuousCoReviewTrackerReconcileHonest -RepoRoot $resolvedRepoRoot -FromTreeId $recordedTreeId -ToTreeId $digest.tree_id -TrackerPaths @($delta.Paths)
            if ($honesty.Honest) {
                $matched = $run
                $honestyBypassNote = ("TRACKER-ONLY RECONCILE ACCEPTED: the only change since the reviewed tree is tracker bookkeeping ({0}) whose claims match the already-accepted review record; that run's evidence is kept fresh. " -f (@($delta.Paths) -join ', '))
                break
            }
            $dishonestReason = $honesty.Reason
        }
    }
    if ($null -eq $matched) {
        $staleMessage = 'The current working tree does not match any passing co-review; re-run continuous co-review before signoff.'
        if (-not [string]::IsNullOrWhiteSpace($dishonestReason)) {
            $staleMessage = ("The current working tree does not match any passing co-review, and the tracker-only change could not be accepted ({0}) - a claims-increasing tracker edit needs a fresh review, exactly as any content change." -f $dishonestReason)
        }
        return New-ContinuousCoReviewSignoffGateDecision -Decision 'block' -Reason 'stale-co-review-evidence' -Message $staleMessage -CurrentTreeId $digest.tree_id -AnchorRef $anchor
    }

    # 5. Coverage: the matched run's chain must reach the anchor with no gap.
    $chain = Get-ContinuousCoReviewChainReachesAnchor -RepoRoot $resolvedRepoRoot -PassingRuns $passingRuns -MatchedRun $matched -AnchorRef $anchor
    if (-not $chain.reached) {
        return New-ContinuousCoReviewSignoffGateDecision -Decision 'block' -Reason 'coverage-gap' -Message "The reviewed chain does not reach the trunk anchor (gap at $($chain.gap_at)); some feature content was never co-reviewed." -CurrentTreeId $digest.tree_id -MatchedRunId ([string] (Get-ContinuousCoReviewRunIndexProperty -Object $matched -Name 'run_id')) -AnchorRef $anchor
    }

    # 6. T094/FR-036 (iter-009 D4) - the TIERED assurance decision on the matched evidence:
    #    full + independent (any budget: 'time-extended' is NOT reduced assurance) -> auto-allow;
    #    partial OR not-provably-independent -> allow ONLY with a recorded first-class human ack.
    #    NEVER deadlocks: the worst case is the ack ask below, always satisfiable via
    #    `specrew review --ack-degraded <run-id> --ack-reason "<why>"`.
    $matchedRunId = [string] (Get-ContinuousCoReviewRunIndexProperty -Object $matched -Name 'run_id')
    $labels = Get-ContinuousCoReviewRunEvidenceLabels -Run $matched
    if (-not (Test-ContinuousCoReviewEvidenceIsDegraded -Labels $labels)) {
        return New-ContinuousCoReviewSignoffGateDecision -Decision 'allow' -Reason 'fresh-and-covered' -Message ("{0}The current reviewed-state matches a passing co-review whose chain covers the feature back to the trunk anchor." -f [string]$honestyBypassNote) -CurrentTreeId $digest.tree_id -MatchedRunId $matchedRunId -AnchorRef $anchor -EvidenceLabels $labels
    }

    $ack = $DegradedAcknowledgement
    if (-not (Test-ContinuousCoReviewOverrideAuthorization -OverrideAuthorization $ack)) {
        $ack = Get-ContinuousCoReviewDegradedAck -RepoRoot $resolvedRepoRoot -RunId $matchedRunId
    }
    if (Test-ContinuousCoReviewOverrideAuthorization -OverrideAuthorization $ack) {
        # FR-020 ANNOUNCED (run-86af61e6 review catch): when the matched run was accepted via the
        # tracker-only reconcile, the human's ack decision must carry that fact too - the reviewed
        # tree id was reused across a tracker-only reconcile, not reviewed against the exact
        # current tree. Withholding it from the degraded-ack paths hid a material fact from the
        # human decision while the fresh path announced it.
        return New-ContinuousCoReviewSignoffGateDecision -Decision 'allow' -Reason 'degraded-evidence-acknowledged' -Message ("{0}Signoff allowed on DEGRADED review evidence (completeness={1}, independence={2}, budget={3}) under a recorded human acknowledgement." -f [string]$honestyBypassNote, $labels.completeness, $labels.independence, $labels.budget) -CurrentTreeId $digest.tree_id -MatchedRunId $matchedRunId -AnchorRef $anchor -EvidenceLabels $labels -Acknowledgement $ack
    }

    return New-ContinuousCoReviewSignoffGateDecision -Decision 'block' -Reason 'degraded-evidence-needs-ack' -Message ("{0}The matching co-review evidence is DEGRADED (completeness={1}, independence={2}, budget={3}); signing off on it needs a recorded human acknowledgement: run ``specrew review --ack-degraded {4} --ack-reason `"<why this assurance level is acceptable>`"`` (or re-run a full independent review)." -f [string]$honestyBypassNote, $labels.completeness, $labels.independence, $labels.budget, $matchedRunId) -CurrentTreeId $digest.tree_id -MatchedRunId $matchedRunId -AnchorRef $anchor -EvidenceLabels $labels
}

function Assert-ContinuousCoReviewSignoffGate {
    param(
        [Parameter(Mandatory)]
        [string] $RepoRoot,

        [AllowEmptyString()][string] $TrunkName = '',

        [string[]] $ExcludedPathPatterns = @(),

        [AllowNull()] $OverrideAuthorization,

        [AllowNull()] $DegradedAcknowledgement
    )

    $decision = Get-ContinuousCoReviewSignoffGateDecision -RepoRoot $RepoRoot -TrunkName $TrunkName -ExcludedPathPatterns $ExcludedPathPatterns -OverrideAuthorization $OverrideAuthorization -DegradedAcknowledgement $DegradedAcknowledgement
    if ($decision.decision -eq 'block') {
        throw "[continuous-co-review-gate] review-signoff refused ($($decision.reason)): $($decision.message)"
    }

    return $decision
}
