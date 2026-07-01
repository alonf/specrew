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
        [AllowNull()] $OverrideAuthorization
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
    }
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

        [AllowNull()] $OverrideAuthorization
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
    if ($null -eq $matched) {
        return New-ContinuousCoReviewSignoffGateDecision -Decision 'block' -Reason 'stale-co-review-evidence' -Message 'The current working tree does not match any passing co-review; re-run continuous co-review before signoff.' -CurrentTreeId $digest.tree_id -AnchorRef $anchor
    }

    # 5. Coverage: the matched run's chain must reach the anchor with no gap.
    $chain = Get-ContinuousCoReviewChainReachesAnchor -RepoRoot $resolvedRepoRoot -PassingRuns $passingRuns -MatchedRun $matched -AnchorRef $anchor
    if (-not $chain.reached) {
        return New-ContinuousCoReviewSignoffGateDecision -Decision 'block' -Reason 'coverage-gap' -Message "The reviewed chain does not reach the trunk anchor (gap at $($chain.gap_at)); some feature content was never co-reviewed." -CurrentTreeId $digest.tree_id -MatchedRunId ([string] (Get-ContinuousCoReviewRunIndexProperty -Object $matched -Name 'run_id')) -AnchorRef $anchor
    }

    return New-ContinuousCoReviewSignoffGateDecision -Decision 'allow' -Reason 'fresh-and-covered' -Message 'The current reviewed-state matches a passing co-review whose chain covers the feature back to the trunk anchor.' -CurrentTreeId $digest.tree_id -MatchedRunId ([string] (Get-ContinuousCoReviewRunIndexProperty -Object $matched -Name 'run_id')) -AnchorRef $anchor
}

function Assert-ContinuousCoReviewSignoffGate {
    param(
        [Parameter(Mandatory)]
        [string] $RepoRoot,

        [string] $TrunkName = 'main',

        [string[]] $ExcludedPathPatterns = @(),

        [AllowNull()] $OverrideAuthorization
    )

    $decision = Get-ContinuousCoReviewSignoffGateDecision -RepoRoot $RepoRoot -TrunkName $TrunkName -ExcludedPathPatterns $ExcludedPathPatterns -OverrideAuthorization $OverrideAuthorization
    if ($decision.decision -eq 'block') {
        throw "[continuous-co-review-gate] review-signoff refused ($($decision.reason)): $($decision.message)"
    }

    return $decision
}
