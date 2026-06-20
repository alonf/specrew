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

function Get-ContinuousCoReviewUntrackedReviewablePaths {
    # F1 (145 review): `git diff <commit>` only sees TRACKED files, so untracked
    # reviewable content is invisible to both the reviewer and diff_hash. List untracked
    # files that would be reviewable source, excluding Specrew's own runtime/state/
    # deployed/scratch trees (the co-review writes its own evidence under .specrew/review,
    # so those must never count as un-reviewed source).
    param(
        [Parameter(Mandatory)]
        [string] $RepoRoot,

        [string[]] $ExcludedPathPatterns = @()
    )

    $statusResult = Invoke-ContinuousCoReviewGit -RepoRoot $RepoRoot -Arguments @('status', '--porcelain', '--untracked-files=all')
    if ($statusResult.ExitCode -ne 0) {
        return @()
    }

    $effectiveExclusions = @($ExcludedPathPatterns) + @('.git/**', '.specrew/**', '.squad/**', '.specify/**', '.scratch/**')
    $paths = New-Object System.Collections.Generic.List[string]
    foreach ($line in @($statusResult.Output)) {
        $statusLine = [string] $line
        if (-not $statusLine.StartsWith('?? ')) {
            continue
        }

        $path = $statusLine.Substring(3).Trim().Trim('"')
        $normalized = ($path -replace '\\', '/')
        if (Test-ContinuousCoReviewPathExcluded -Path $normalized -ExcludedPathPatterns $effectiveExclusions) {
            continue
        }

        [void] $paths.Add($normalized)
    }

    return @($paths)
}

function Get-ContinuousCoReviewSignoffGateDecision {
    param(
        [Parameter(Mandatory)]
        [string] $RepoRoot,

        [AllowNull()]
        [string] $Scope,

        [string[]] $ExcludedPathPatterns = @()
    )

    $resolvedRepoRoot = (Resolve-Path -LiteralPath $RepoRoot).Path

    $lastPass = Get-ContinuousCoReviewLastPassingReviewState -RepoRoot $resolvedRepoRoot -Scope $Scope
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

    $untrackedReviewable = Get-ContinuousCoReviewUntrackedReviewablePaths -RepoRoot $resolvedRepoRoot -ExcludedPathPatterns $ExcludedPathPatterns
    if (@($untrackedReviewable).Count -gt 0) {
        return New-ContinuousCoReviewSignoffGateDecision -Decision 'block' -Reason 'unreviewed-working-tree' -Message "Untracked reviewable content exists that no co-review has seen ($([string]::Join(', ', @($untrackedReviewable)))); add or commit it and re-run co-review before signoff." -LastPassingState $lastPass -CurrentDiffHash ([string] $changeSet.diff_hash)
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
        [string] $Scope,

        [string[]] $ExcludedPathPatterns = @()
    )

    $decision = Get-ContinuousCoReviewSignoffGateDecision -RepoRoot $RepoRoot -Scope $Scope -ExcludedPathPatterns $ExcludedPathPatterns
    if ($decision.decision -eq 'block') {
        throw "[continuous-co-review-gate] review-signoff refused ($($decision.reason)): $($decision.message)"
    }

    return $decision
}
