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

function Get-ContinuousCoReviewSignoffGateDecision {
    param(
        [Parameter(Mandatory)]
        [string] $RepoRoot,

        [string] $TrunkName = 'main',

        [string[]] $ExcludedPathPatterns = @(),

        [AllowNull()] $OverrideAuthorization,

        # T094/FR-036: an explicit degraded-evidence acknowledgement (authorized_by + rationale).
        # When omitted, the persisted per-run ack (degraded-ack.json) is honoured instead.
        [AllowNull()] $DegradedAcknowledgement
    )

    $resolvedRepoRoot = (Resolve-Path -LiteralPath $RepoRoot).Path

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
        return New-ContinuousCoReviewSignoffGateDecision -Decision 'allow' -Reason 'degraded-evidence-acknowledged' -Message ("Signoff allowed on DEGRADED review evidence (completeness={0}, independence={1}, budget={2}) under a recorded human acknowledgement." -f $labels.completeness, $labels.independence, $labels.budget) -CurrentTreeId $digest.tree_id -MatchedRunId $matchedRunId -AnchorRef $anchor -EvidenceLabels $labels -Acknowledgement $ack
    }

    return New-ContinuousCoReviewSignoffGateDecision -Decision 'block' -Reason 'degraded-evidence-needs-ack' -Message ("The matching co-review evidence is DEGRADED (completeness={0}, independence={1}, budget={2}); signing off on it needs a recorded human acknowledgement: run ``specrew review --ack-degraded {3} --ack-reason `"<why this assurance level is acceptable>`"`` (or re-run a full independent review)." -f $labels.completeness, $labels.independence, $labels.budget, $matchedRunId) -CurrentTreeId $digest.tree_id -MatchedRunId $matchedRunId -AnchorRef $anchor -EvidenceLabels $labels
}

function Assert-ContinuousCoReviewSignoffGate {
    param(
        [Parameter(Mandatory)]
        [string] $RepoRoot,

        [string] $TrunkName = 'main',

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
