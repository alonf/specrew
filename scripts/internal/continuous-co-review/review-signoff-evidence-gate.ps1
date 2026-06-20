$ErrorActionPreference = 'Stop'
Set-StrictMode -Version Latest

# T061 / FR-025: the deterministic co-review gate floor decision.
#
# "You cannot sign off on un-reviewed state." A pass/escalated co-review run must
# exist whose recorded diff_hash, recomputed from its baseline_ref to the CURRENT
# working tree, still matches — proving the working tree has not drifted since it
# passed. Because the co-review baseline advances only on a pass
# (Get-ContinuousCoReviewLastPassingReviewState returns only pass/escalated runs),
# this single current-state check transitively proves every prior increment was
# reviewed, with no per-increment git-history archaeology.
#
# This is the DECISION logic only. Wiring it into Invoke-SpecrewBoundaryStateSync as
# a throw-to-refuse gate is the F-184/F-185-coordinated step deferred until the 185
# host-neutral gate-enforcement branch merges; Assert-ContinuousCoReviewSignoffGate
# is the thin throw-wrapper that wiring will call.

function New-ContinuousCoReviewSignoffGateDecision {
    param(
        [Parameter(Mandatory)]
        [ValidateSet('allow', 'block')]
        [string] $Decision,

        [Parameter(Mandatory)]
        [string] $Reason,

        [Parameter(Mandatory)]
        [string] $Message,

        [AllowNull()] $LastPassingState,
        [AllowNull()] [string] $CurrentDiffHash
    )

    return [pscustomobject][ordered]@{
        schema_version     = '1.0'
        decision           = $Decision
        reason             = $Reason
        message            = $Message
        last_run_id        = if ($null -ne $LastPassingState) { $LastPassingState.run_id } else { $null }
        baseline_ref       = if ($null -ne $LastPassingState) { $LastPassingState.baseline_ref } else { $null }
        expected_diff_hash = if ($null -ne $LastPassingState) { $LastPassingState.diff_hash } else { $null }
        current_diff_hash  = $CurrentDiffHash
    }
}

function Get-ContinuousCoReviewSignoffGateDecision {
    param(
        [Parameter(Mandatory)]
        [string] $RepoRoot,

        [AllowNull()]
        [string] $CheckpointIdPrefix,

        [string[]] $ExcludedPathPatterns = @()
    )

    $resolvedRepoRoot = (Resolve-Path -LiteralPath $RepoRoot).Path

    $lastPass = Get-ContinuousCoReviewLastPassingReviewState -RepoRoot $resolvedRepoRoot -CheckpointIdPrefix $CheckpointIdPrefix
    if ($null -eq $lastPass) {
        return New-ContinuousCoReviewSignoffGateDecision -Decision 'block' -Reason 'no-co-review-evidence' -Message 'No passing or escalated continuous co-review run exists; the current state has not been co-reviewed.'
    }

    if ([string]::IsNullOrWhiteSpace([string] $lastPass.baseline_ref) -or [string]::IsNullOrWhiteSpace([string] $lastPass.diff_hash)) {
        return New-ContinuousCoReviewSignoffGateDecision -Decision 'block' -Reason 'malformed-co-review-evidence' -Message 'The latest passing co-review run is missing its baseline_ref or diff_hash and is unsafe to trust.' -LastPassingState $lastPass
    }

    $changeSet = Get-ContinuousCoReviewCheckpointDiff -RepoRoot $resolvedRepoRoot -BaselineRef ([string] $lastPass.baseline_ref) -CheckpointId 'signoff-evidence-gate' -ExcludedPathPatterns $ExcludedPathPatterns -RunId 'signoff-evidence-gate'
    if ($changeSet.status -eq 'infrastructure_failure') {
        return New-ContinuousCoReviewSignoffGateDecision -Decision 'block' -Reason 'baseline-unresolvable' -Message 'The last passing co-review baseline could not be resolved against the current tree; treat as unsafe.' -LastPassingState $lastPass
    }

    $currentDiffHash = [string] $changeSet.diff_hash
    if ($currentDiffHash -eq [string] $lastPass.diff_hash) {
        return New-ContinuousCoReviewSignoffGateDecision -Decision 'allow' -Reason 'fresh-co-review-evidence' -Message 'The current working tree matches a passing or escalated co-review run from the same baseline.' -LastPassingState $lastPass -CurrentDiffHash $currentDiffHash
    }

    return New-ContinuousCoReviewSignoffGateDecision -Decision 'block' -Reason 'stale-co-review-evidence' -Message 'The working tree has changed since the last passing co-review; re-run continuous co-review before signoff.' -LastPassingState $lastPass -CurrentDiffHash $currentDiffHash
}

function Assert-ContinuousCoReviewSignoffGate {
    param(
        [Parameter(Mandatory)]
        [string] $RepoRoot,

        [AllowNull()]
        [string] $CheckpointIdPrefix,

        [string[]] $ExcludedPathPatterns = @()
    )

    $decision = Get-ContinuousCoReviewSignoffGateDecision -RepoRoot $RepoRoot -CheckpointIdPrefix $CheckpointIdPrefix -ExcludedPathPatterns $ExcludedPathPatterns
    if ($decision.decision -eq 'block') {
        throw "[continuous-co-review-gate] review-signoff refused ($($decision.reason)): $($decision.message)"
    }

    return $decision
}
