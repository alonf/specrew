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
# merges; Assert-ContinuousCoReviewSignoffGate is the explicit throw-wrapper for direct callers and
# forwards the complete decision contract. Production boundary wiring persists the decision first,
# then throws itself so evidence cannot be skipped.

# HARD dependency: the ONE path-identity primitive. Test-ReviewCampaignDeltaIsRecordsOnly asks it for
# the volume's case rule, and without this load the call depended on whatever ambient load order the
# caller happened to have - the SHADOWING class where a duplicate loaded later silently answers with
# the OS-family rule, invisibly, at every call site. Third instance of this class in one day
# (DRIFT-199-I001-014 in worktree-navigator.ps1 was the second), which is why beta4's target is making
# the primitive the only REACHABLE path rather than the recommended one.
# Guarded on the exact function this file calls rather than on a sibling name: DRIFT-198-I009-027's
# shadow survived a guard that probed a DIFFERENT name, and a stale copy of path-identity.ps1
# satisfies the older names while lacking anything added since.
if (-not (Get-Command -Name 'Get-ContinuousCoReviewPathComparison' -ErrorAction SilentlyContinue)) {
    . (Join-Path $PSScriptRoot 'path-identity.ps1')
}

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

function Test-ReviewCampaignFinalizationEnvelope {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)][string]$RepoRoot,
        [Parameter(Mandatory)][string]$CampaignId,
        [Parameter(Mandatory)]$Result,
        [Parameter(Mandatory)]$Fact,
        [Parameter(Mandatory)][string]$CurrentDigest,
        [AllowEmptyString()][string]$FeatureId,
        [AllowEmptyString()][string]$IterationNumber,
        [string[]]$ExcludedPathPatterns = @()
    )
    $fail = {
        param([string]$Reason)
        [pscustomobject][ordered]@{
            valid = $false; reason = $Reason; run_id = $null; reviewed_digest = $null
            reviewed_commit = $null; finalization_commit = $null; changed_paths = @()
        }
    }
    if (-not (Test-ReviewCampaignScopeIdentity -FeatureId $FeatureId -IterationNumber $IterationNumber)) {
        return & $fail 'scope-identity-invalid'
    }
    $factValidation = Test-ReviewAuthorityContractObject -ContractName ReviewFinalizationFact -InputObject $Fact -ExpectedCampaignId $CampaignId
    if (-not $factValidation.valid) { return & $fail ('fact-' + $factValidation.category) }
    $runId = [string]$Fact.run_id
    $reviewedDigest = [string]$Fact.reviewed_digest
    $finalizationCommit = [string]$Fact.finalization_commit
    $resultValidation = Test-ReviewAuthorityContractObject -ContractName ReviewResult -InputObject $Result `
        -ExpectedCampaignId $CampaignId -ExpectedRunId $runId -ExpectedTargetDigest $reviewedDigest
    if (-not $resultValidation.valid) { return & $fail ('result-' + $resultValidation.category) }
    if ([string]$Result.completion -cne 'complete' -or [string]$Result.verdict -cne 'pass' -or
        [string]$Result.runtime_outcome -cne 'completed' -or -not [bool]$Result.termination_verified -or
        [string]$Result.containment -cne 'verified' -or [string]$Result.currentness -cne 'current' -or
        [string]$Result.validation -cne 'valid' -or -not [bool]$Result.can_approve_current) {
        return & $fail 'result-not-clean-current-pass'
    }

    $root = (Resolve-Path -LiteralPath $RepoRoot).Path
    $head = [string](@(& git -C $root rev-parse --verify 'HEAD^{commit}' 2>$null) | Select-Object -First 1)
    if ($LASTEXITCODE -ne 0 -or $head.Trim() -cne $finalizationCommit) { return & $fail 'finalization-not-current-head' }
    $parentLine = [string](@(& git -C $root rev-list --parents -n 1 $finalizationCommit 2>$null) | Select-Object -First 1)
    if ($LASTEXITCODE -ne 0) { return & $fail 'finalization-commit-unresolvable' }
    $parentParts = @($parentLine.Trim().Split(' ', [StringSplitOptions]::RemoveEmptyEntries))
    if ($parentParts.Count -ne 2) { return & $fail 'finalization-parent-not-singular' }
    $reviewedCommit = [string]$parentParts[1]
    & git -C $root cat-file -e "$reviewedDigest^{tree}" 2>$null
    if ($LASTEXITCODE -ne 0) { return & $fail 'reviewed-digest-unresolvable' }

    if (-not (Get-Command -Name 'Get-ContinuousCoReviewMachineryPaths' -ErrorAction SilentlyContinue)) {
        $worktreeReviewerPath = Join-Path $PSScriptRoot 'worktree-reviewer.ps1'
        if (Test-Path -LiteralPath $worktreeReviewerPath -PathType Leaf) {
            try { . $worktreeReviewerPath } catch { $null = $_ }
        }
    }
    if (-not (Get-Command -Name 'Get-ContinuousCoReviewDigestRuntimeStripList' -ErrorAction SilentlyContinue) -or
        -not (Get-Command -Name 'Get-ContinuousCoReviewMachineryPaths' -ErrorAction SilentlyContinue) -or
        -not (Get-Command -Name 'Test-ContinuousCoReviewDigestPathDenied' -ErrorAction SilentlyContinue)) {
        return & $fail 'digest-policy-unavailable'
    }
    $stripPatterns = @(Get-ContinuousCoReviewDigestRuntimeStripList) + @($ExcludedPathPatterns)
    try {
        foreach ($machineryPath in @(Get-ContinuousCoReviewMachineryPaths -RepoRoot $root)) {
            if ([string]::IsNullOrWhiteSpace([string]$machineryPath)) { continue }
            $stripPatterns += [string]$machineryPath
            $stripPatterns += ('{0}/**' -f [string]$machineryPath)
        }
    }
    catch { return & $fail 'digest-policy-unavailable' }

    foreach ($comparison in @(
        @{ left = $reviewedDigest; right = $reviewedCommit; reason = 'reviewed-digest-not-parent-state' },
        @{ left = $CurrentDigest; right = $finalizationCommit; reason = 'current-state-not-finalization-commit' }
    )) {
        $differences = @(& git -C $root -c core.quotepath=false diff --name-only --no-renames ([string]$comparison.left) ([string]$comparison.right) 2>$null)
        if ($LASTEXITCODE -ne 0) { return & $fail ([string]$comparison.reason) }
        foreach ($path in $differences) {
            if (-not (Test-ContinuousCoReviewDigestPathDenied -Path ([string]$path).Replace('\', '/') -Denylist $stripPatterns)) {
                return & $fail ([string]$comparison.reason)
            }
        }
    }

    $iterationRoot = "specs/$FeatureId/iterations/$IterationNumber"
    $allowed = [Collections.Generic.HashSet[string]]::new([StringComparer]::Ordinal)
    foreach ($name in @('review.md', 'reviewer-index.md', 'code-map.md', 'coverage-evidence.md', 'dependency-report.md', 'review-diagrams.md')) {
        $null = $allowed.Add("$iterationRoot/$name")
    }
    $changedPaths = [Collections.Generic.List[string]]::new()
    $entries = @(& git -C $root -c core.quotepath=false diff-tree --no-commit-id --name-status --no-renames -r $reviewedCommit $finalizationCommit 2>$null)
    if ($LASTEXITCODE -ne 0 -or $entries.Count -eq 0) { return & $fail 'finalization-diff-empty-or-unresolvable' }
    foreach ($entry in $entries) {
        if ([string]$entry -cnotmatch '^(?<status>[AM])\t(?<path>.+)$') { return & $fail 'finalization-diff-status-denied' }
        $path = [string]$Matches.path
        if (-not $allowed.Contains($path)) { return & $fail ('finalization-path-denied:' + $path) }
        $changedPaths.Add($path) | Out-Null
    }
    return [pscustomobject][ordered]@{
        valid = $true; reason = 'valid'; run_id = $runId; reviewed_digest = $reviewedDigest
        reviewed_commit = $reviewedCommit; finalization_commit = $finalizationCommit; changed_paths = @($changedPaths)
    }
}

function New-ReviewCampaignVerdictPacketDecision {
    param(
        [Parameter(Mandatory)][string]$Route,
        [Parameter(Mandatory)][string]$Reason,
        [Parameter(Mandatory)][string]$Message,
        [string]$CampaignId,
        [string]$RunId,
        [string]$TargetDigest,
        [string]$ReviewedDigest,
        [string]$ReviewedCommit,
        [string]$FinalizationCommit,
        [bool]$RenderBoundaryPacket = $false,
        # ONE VALUE WAS SERVING TWO READERS, which is this iteration's most repeated defect shape.
        # `render_boundary_packet` told the NAVIGATOR to release the boundary packet, and the signoff
        # gate ALSO derived its allow/block from it. So a route could not say "the review still covers
        # you" to the gate without also releasing the packet - and round 4 found the consequence from
        # the other side: a recorded ALLOW returned a BLOCK because the flag defaulted to false.
        #
        # $null means "same as RenderBoundaryPacket", so every existing call site keeps its exact
        # behaviour and only the branches that need to differ say so.
        [AllowNull()][object]$GateAllows = $null,
        [bool]$AskNarrowQuestion = $false,
        [string]$ImplementerAction = 'wait'
    )
    return [pscustomobject][ordered]@{
        schema_version = '1.0'; route = $Route; reason = $Reason; message = $Message
        campaign_id = $CampaignId; run_id = $RunId; target_digest = $TargetDigest
        reviewed_digest = $ReviewedDigest; reviewed_commit = $ReviewedCommit; finalization_commit = $FinalizationCommit
        render_boundary_packet = $RenderBoundaryPacket; render_verdict_marker = $RenderBoundaryPacket
        gate_allows = $(if ($null -eq $GateAllows) { $RenderBoundaryPacket } else { [bool]$GateAllows })
        ask_narrow_question = $AskNarrowQuestion; implementer_action = $ImplementerAction
    }
}

function Test-ReviewCampaignDeltaIsRecordsOnly {
    # FR-009. Reviewable content is everything that is NOT the methodology machinery and NOT the
    # lifecycle records tree. The machinery list comes from the ONE FR-012 resolver so this can never
    # drift from the digest and worktree strips; `specs/` is reviewable to a reviewer but is records,
    # not implementation, which is the distinction that stops a drift-log commit invalidating the
    # review that produced it (DRIFT-199-I001-013).
    #
    # -RepoRoot is REQUIRED for that no-drift promise to hold, and its absence is what made the first
    # revision of this predicate fail OPEN. `Get-ContinuousCoReviewMachineryPaths` answers DIFFERENTLY
    # depending on the root it is given: called bare it cannot run Test-ContinuousCoReviewSpecrewSourceRepo,
    # so it takes the DEPLOYED-project branch and appends `scripts/internal/continuous-co-review`,
    # `scripts/internal/agent-tasks` and `scripts/internal/atomic-write.ps1` to the machinery list. In the
    # Specrew SOURCE repo those paths are the feature under review, not machinery - so a bare call
    # classified a change to the co-review engine itself as records-only and left a stale review looking
    # current. Under-staling is the one direction this feature must never fail in, and the digest strip
    # (Test-ReviewCampaignFinalizationEnvelope) already passes -RepoRoot, so a bare call here was also a
    # live divergence from the very list this comment promises it can never drift from.
    #
    # An EMPTY or unknown delta returns $false - fail closed. Absence of evidence is not evidence. An
    # absent or unresolvable RepoRoot fails closed the same way rather than guessing a machinery list:
    # guessing is exactly what produced the defect above. Not [Parameter(Mandatory)] on purpose - this
    # runs on the Stop path, where a missing mandatory parameter prompts an interactive host and hangs
    # the hook instead of failing.
    [CmdletBinding()]
    param(
        [AllowNull()][object[]]$ChangedPaths,
        [AllowNull()][AllowEmptyString()][string]$RepoRoot,
        # The ACTIVE feature. Only ITS records tree can be records-only; another feature's tree is
        # ordinary content. Absent, no specs/ path counts as records - fail closed.
        [AllowNull()][AllowEmptyString()][string]$FeatureId
    )

    if ($null -eq $ChangedPaths -or @($ChangedPaths).Count -eq 0) { return $false }
    if ([string]::IsNullOrWhiteSpace($RepoRoot)) { return $false }
    try { $resolvedRoot = (Resolve-Path -LiteralPath $RepoRoot -ErrorAction Stop).Path }
    catch { return $false }
    # W51: RESOLVE, DON'T REQUIRE. A caller that passed no feature id used to kill the records
    # allowlist outright - and the shared-classifier overlay excludes specs/, so review.md, state.md
    # and the progress sync staled the review that had just measured them. One human approval per
    # loop, live on the walk. The active feature is lifecycle state the project already holds.
    if ([string]::IsNullOrWhiteSpace($FeatureId) -and (Get-Command -Name 'Resolve-SpecrewActiveFeatureRef' -ErrorAction SilentlyContinue)) {
        try { $FeatureId = [string](Resolve-SpecrewActiveFeatureRef -ProjectRoot $resolvedRoot) } catch { $null = $_ }
    }
    if (-not (Get-Command -Name 'Get-ContinuousCoReviewMachineryPaths' -ErrorAction SilentlyContinue)) {
        $reviewerModule = Join-Path $PSScriptRoot 'worktree-reviewer.ps1'
        if (Test-Path -LiteralPath $reviewerModule -PathType Leaf) { try { . $reviewerModule } catch { $null = $_ } }
    }
    if (-not (Get-Command -Name 'Get-ContinuousCoReviewMachineryPaths' -ErrorAction SilentlyContinue)) { return $false }

    $recordsRoots = @()
    try {
        foreach ($machinery in @(Get-ContinuousCoReviewMachineryPaths -RepoRoot $resolvedRoot)) {
            if (-not [string]::IsNullOrWhiteSpace($machinery)) { $recordsRoots += (([string]$machinery -replace '\\', '/').Trim('/')) }
        }
    }
    catch { return $false }

    # DRIFT-007's TWIN (2026-08-22, found by the downstream walk after b5c84f48 fixed the validator):
    # this predicate classified path-by-path against the machinery list plus the feature allowlist,
    # failing closed on the first unclassifiable path - and the Spec-Kit/Squad deployers write host
    # mirrors (.github/agents/, .github/prompts/, .claude/skills/, Squad skills) that are in NEITHER.
    # So every redeploy permanently staled every review in a downstream project: the same byte-vs-source
    # question the validator had, surviving in a second copy of the check.
    #
    # The fix is the same SHARED classifier the validator got - Test-SpecrewReviewAuthorshipSourcePath,
    # already shared with W33's coverage rule and W34-B's authorship rule - rather than growing this
    # predicate's own parallel list to chase what deployment writes. One decision, now four consumers.
    #
    # SCOPED OUT OF specs/ DELIBERATELY. The classifier calls the whole specs/ tree non-source, but
    # FR-009 as the maintainer ruled it (2026-08-10) distinguishes INPUT from OUTPUT inside the feature
    # tree: spec, plan and tasks are the standard the code was judged against and MUST stale, while
    # review output must not. The allowlist below carries that ruling and stays authoritative for
    # specs/; the shared classifier covers everything outside it. Fail direction preserved: when the
    # classifier is not loaded, nothing changes and an unclassifiable path still stales.
    $sharedClassifier = Get-Command -Name 'Test-SpecrewReviewAuthorshipSourcePath' -ErrorAction SilentlyContinue
    if ($null -eq $sharedClassifier) {
        foreach ($sharedGovernanceCandidate in @(
                (Join-Path $resolvedRoot '.specify/extensions/specrew-speckit/scripts/shared-governance.ps1'),
                (Join-Path $resolvedRoot 'extensions/specrew-speckit/scripts/shared-governance.ps1'))) {
            if (Test-Path -LiteralPath $sharedGovernanceCandidate -PathType Leaf) {
                try { . $sharedGovernanceCandidate } catch { $null = $_ }
                $sharedClassifier = Get-Command -Name 'Test-SpecrewReviewAuthorshipSourcePath' -ErrorAction SilentlyContinue
                if ($null -ne $sharedClassifier) { break }
            }
        }
    }

    # The volume that decides case here is the one holding the CHANGED PATHS - the project - never the
    # one holding this script. They are routinely different volumes: on the default CurrentUser install
    # the engine sits under a OneDrive-backed Modules directory while the project is on a local disk
    # (DRIFT-199-I001-005), and asking the engine's volume for the project's case rule is the same
    # wrong-source mistake as an $IsWindows shortcut. 'distinct' keeps an undetermined volume STALING:
    # this predicate can only ever quiet the surface, so undetermined must never let it.
    $comparison = Get-ContinuousCoReviewPathComparison -Path $resolvedRoot -WhenUndetermined 'distinct'
    foreach ($raw in @($ChangedPaths)) {
        $path = ([string]$raw -replace '\\', '/').Trim().Trim('/')
        if ([string]::IsNullOrWhiteSpace($path)) { continue }
        $isRecords = $false
        foreach ($root in $recordsRoots) {
            if ([string]::IsNullOrWhiteSpace($root)) { continue }
            if ($path.Equals($root, $comparison) -or $path.StartsWith(($root + '/'), $comparison)) {
                $isRecords = $true
                break
            }
        }
        if (-not $isRecords -and (Test-ReviewCampaignPathIsFeatureProcessRecord -Path $path -FeatureId $FeatureId -Comparison $comparison)) {
            $isRecords = $true
        }
        # The shared source classifier, outside specs/ only (see the block above): a host mirror, a
        # document, or a dot-directory deployment write is not the reviewed surface. specs/ paths that
        # the allowlist did not accept keep staling - they are review INPUT.
        if (-not $isRecords -and $null -ne $sharedClassifier -and
            -not $path.StartsWith('specs/', $comparison) -and
            -not (& $sharedClassifier -Path $path)) {
            $isRecords = $true
        }
        if (-not $isRecords) { return $false }
    }
    return $true
}

function Test-ReviewCampaignPathIsFeatureProcessRecord {
    # FR-009 as the maintainer ruled it (2026-08-10): the distinction is NOT the directory, it is whether an
    # artifact is INPUT TO a review or OUTPUT OF one.
    #
    #   OUTPUT - a record of what a review found, or of the process around it. It cannot invalidate the review
    #            that produced it; saying otherwise is circular, and that absurdity is DRIFT-199-I001-013: a
    #            commit whose entire content was the drift log staled the review that wrote it.
    #   INPUT  - spec, plan, tasks, design, contracts, data-model, quickstart, research. These are the STANDARD
    #            the code was judged against. Change one and what the review concluded changes, even though no
    #            code moved. They must stale.
    #
    # ALLOWLIST, deliberately, and this is the one place an enumeration is acceptable in this feature: an
    # allowlist fails toward NAGGING (an artifact nobody listed stales, and the human is asked for a review they
    # may not owe), while a blocklist fails toward SILENCING (an artifact nobody listed goes quiet, and a real
    # change slips past review). An omission here is therefore SAFE - which is exactly what was NOT true of the
    # class guards, where enumeration was rejected for the opposite reason.
    #
    # Scoped to the ACTIVE feature, the narrowing the recorded requirement already named: another feature's
    # records tree is ordinary content to this campaign. No feature id -> nothing qualifies (fail closed).
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)][AllowEmptyString()][string]$Path,
        [AllowNull()][AllowEmptyString()][string]$FeatureId,
        [Parameter(Mandatory)][StringComparison]$Comparison
    )

    if ([string]::IsNullOrWhiteSpace($Path) -or [string]::IsNullOrWhiteSpace($FeatureId)) { return $false }
    # W51: the ONE classification lives in shared-governance (Test-SpecrewLifecycleExecutionRecordPath),
    # consumed by this gate AND the validator's citation-staleness check so the two can never disagree
    # about what recording a review does to the review. Delegate when loaded; the body below is the
    # same logic verbatim, kept for a standalone gate load.
    if (Get-Command -Name 'Test-SpecrewLifecycleExecutionRecordPath' -ErrorAction SilentlyContinue) {
        return [bool](Test-SpecrewLifecycleExecutionRecordPath -Path $Path -FeatureId $FeatureId)
    }
    $featurePrefix = 'specs/' + $FeatureId.Trim().Trim('/') + '/'
    if (-not $Path.StartsWith($featurePrefix, $Comparison)) { return $false }

    # Everything after specs/<feature>/, with a leading iterations/<n>/ removed so one allowlist covers both the
    # feature-level and iteration-level copies of the same artifact.
    $relative = $Path.Substring($featurePrefix.Length)
    $iteration = [regex]::Match($relative, '^iterations/[^/]+/(?<rest>.*)$')
    if ($iteration.Success) { $relative = [string]$iteration.Groups['rest'].Value }
    if ([string]::IsNullOrWhiteSpace($relative)) { return $false }

    # Process records and review OUTPUT. The six review-evidence names are the SAME set this file already
    # allowlists for a finalization envelope, so the two cannot disagree about what counts as review evidence.
    $recordFiles = @(
        'drift-log.md', 'state.md', 'tasks-progress.yml',
        'review.md', 'reviewer-index.md', 'code-map.md', 'coverage-evidence.md', 'dependency-report.md', 'review-diagrams.md',
        'review-signoff.md', 'retro.md'
    )
    foreach ($name in $recordFiles) {
        if ($relative.Equals($name, $Comparison)) { return $true }
    }
    if ($relative.StartsWith('closeout', $Comparison) -and $relative -notmatch '/') { return $true }

    # workshop/ IS DELIBERATELY ABSENT (maintainer ruling, 2026-08-11, on the signoff round's finding).
    # It sat in this list and was the one entry that inverted the list's own safety argument. A design
    # workshop holds architecture-core, requirements-nfr, security-compliance, product-domain: the
    # binding standard the implementation is judged against, INPUT by the ruling's own test. Classified
    # as a record, a maintainer could change a security or architecture decision after a review and the
    # campaign would keep authorizing sign-off from the old result - a real change going quiet, which is
    # precisely the SILENCING failure this allowlist exists to make impossible. An allowlist is safe
    # because omissions nag; that safety is void for any entry wrongly INCLUDED.
    foreach ($directory in @('quality/', 'checklists/', 'dashboards/', 'gates/')) {
        if ($relative.StartsWith($directory, $Comparison)) { return $true }
    }
    return $false
}

function Get-ContinuousCoReviewRecordedSignoffGateDecision {
    # FR-007's consult, as a READ of the signoff-gate decision store - never a live gate call.
    #
    # A live call would recurse without terminating: when campaign authority is enabled,
    # Get-ContinuousCoReviewSignoffGateDecision is a thin wrapper that calls
    # Get-ReviewCampaignVerdictPacketDecision, which is the very function consulting it. The spec
    # names the store, not the gate ("the campaign stop surface MUST consult the signoff-gate
    # decision store"), and resolves the empty case explicitly: with no recorded decision the surface
    # evaluates as it does today.
    #
    # The stored record wraps the decision and spells the tree `current_tree_id`; the decision logic
    # asks for `reviewed_digest`. Normalizing here keeps Resolve- a pure function over plain shapes,
    # which is what lets its fixtures stay store-free. Anything absent, unreadable or malformed
    # returns $null and confers NOTHING - this consult can only ever quiet the surface, so an
    # unreadable store must never be the reason it goes quiet.
    [CmdletBinding()]
    param([AllowNull()][AllowEmptyString()][string]$RepoRoot)

    if ([string]::IsNullOrWhiteSpace($RepoRoot)) { return $null }
    $latestPath = Join-Path $RepoRoot '.specrew/review/signoff-gate/latest.json'
    if (-not (Test-Path -LiteralPath $latestPath -PathType Leaf)) { return $null }
    try { $record = Get-Content -LiteralPath $latestPath -Raw -Encoding UTF8 | ConvertFrom-Json }
    catch { return $null }
    if ($null -eq $record) { return $null }
    $decision = Get-ReviewAuthorityProperty -Object $record -Name 'decision'
    if ($null -eq $decision) { return $null }
    $verdict = [string](Get-ReviewAuthorityProperty -Object $decision -Name 'decision')
    $treeId = [string](Get-ReviewAuthorityProperty -Object $decision -Name 'current_tree_id')
    if ([string]::IsNullOrWhiteSpace($verdict) -or [string]::IsNullOrWhiteSpace($treeId)) { return $null }
    return [pscustomobject][ordered]@{
        decision        = $verdict
        reviewed_digest = $treeId
        reason          = [string](Get-ReviewAuthorityProperty -Object $decision -Name 'reason')
        boundary_type   = [string](Get-ReviewAuthorityProperty -Object $record -Name 'boundary_type')
        recorded_at     = [string](Get-ReviewAuthorityProperty -Object $record -Name 'recorded_at')
    }
}

function Get-ReviewCampaignChangedPathsSinceResult {
    # FR-009's evidence: what actually changed between the reviewed tree and the current one. Both
    # arguments are reviewed-state digests, which ARE git tree objects, so git answers this directly
    # rather than anything reconstructing a diff by hand.
    #
    # $null means UNKNOWN and stales; @() means genuinely nothing changed. The distinction is
    # load-bearing downstream - Test-ReviewCampaignDeltaIsRecordsOnly fails closed on both, but only
    # $null should ever arise from a git failure. Every failure path here returns $null so an
    # unresolvable tree can never be mistaken for a clean delta.
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)][string]$RepoRoot,
        [AllowNull()][AllowEmptyString()][string]$ReviewedDigest,
        [AllowNull()][AllowEmptyString()][string]$CurrentDigest
    )

    if ([string]::IsNullOrWhiteSpace($ReviewedDigest) -or [string]::IsNullOrWhiteSpace($CurrentDigest)) { return $null }
    if ($ReviewedDigest -ceq $CurrentDigest) { return @() }
    try { $root = (Resolve-Path -LiteralPath $RepoRoot -ErrorAction Stop).Path }
    catch { return $null }

    foreach ($digest in @($ReviewedDigest, $CurrentDigest)) {
        & git -C $root cat-file -e ("{0}^{{tree}}" -f $digest) 2>$null
        if ($LASTEXITCODE -ne 0) { return $null }
    }
    $paths = @(& git -C $root -c core.quotepath=false diff --name-only --no-renames $ReviewedDigest $CurrentDigest 2>$null)
    if ($LASTEXITCODE -ne 0) { return $null }
    return @($paths | ForEach-Object { ([string]$_).Trim() } | Where-Object { -not [string]::IsNullOrWhiteSpace($_) })
}

function Test-ReviewCampaignResultReleasesBoundary {
    # "Would this result reach a boundary-releasing route?" - ONE definition, consumed twice below, so
    # the pause guard and the boundary-clean return can never answer it differently. The sequential
    # gates between them stay sequential on purpose: each one owes the consumer a DIFFERENT message
    # about why their review does not release the boundary, which a single predicate cannot give.
    [CmdletBinding()]
    param([AllowNull()]$Result, [Parameter(Mandatory)][AllowEmptyString()][string]$CurrentDigest)

    if ($null -eq $Result) { return $false }
    return (
        (Test-ReviewCampaignResultIsCompleteCurrent -Result $Result -CurrentDigest $CurrentDigest) -and
        [string]$Result.verdict -ceq 'pass' -and
        [bool]$Result.can_approve_current
    )
}

function Test-ReviewCampaignResultIsCompleteCurrent {
    # Everything a result needs before its VERDICT is even worth reading. Split out because a clean pass is not
    # the only boundary-releasing shape: a findings result with a recorded human acceptance releases too, and
    # both need this same conjunction first.
    [CmdletBinding()]
    param([AllowNull()]$Result, [Parameter(Mandatory)][AllowEmptyString()][string]$CurrentDigest)

    if ($null -eq $Result) { return $false }
    return (
        [string]$Result.target_digest -ceq $CurrentDigest -and
        [string]$Result.currentness -ceq 'current' -and
        [string]$Result.completion -ceq 'complete' -and
        [string]$Result.validation -ceq 'valid' -and
        [string]$Result.runtime_outcome -cne 'timed-out'
    )
}

function Test-ReviewCampaignDispositionAcceptsResult {
    # ONE definition of "the human has explicitly accepted this exact result", consumed by the pause guard and
    # by the boundary-human-disposition return, so the two cannot disagree about whether a decision was made.
    # A require-correction anywhere in the matching set wins over an acceptance - a human who asked for a fix
    # has not accepted, whatever else they also said.
    [CmdletBinding()]
    param(
        [AllowNull()][object[]]$HumanDispositions,
        [Parameter(Mandatory)][string]$CampaignId,
        [Parameter(Mandatory)][AllowEmptyString()][string]$RunId,
        [Parameter(Mandatory)][AllowEmptyString()][string]$CurrentDigest
    )

    if ($null -eq $HumanDispositions -or @($HumanDispositions).Count -eq 0) { return $false }
    $matching = @($HumanDispositions | Where-Object {
            (Test-ReviewAuthorityContractObject -ContractName HumanDispositionFact -InputObject $_ `
                    -ExpectedCampaignId $CampaignId -ExpectedRunId $RunId -ExpectedTargetDigest $CurrentDigest).valid
        })
    if (@($matching | Where-Object { [string]$_.decision -ceq 'require-correction' }).Count -gt 0) { return $false }
    return (@($matching | Where-Object { [string]$_.decision -ceq 'accept-current' }).Count -gt 0)
}

function Resolve-ReviewCampaignVerdictPacketDecision {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)][string]$CampaignId,
        [Parameter(Mandatory)][string]$CurrentDigest,
        # The project root the delta below belongs to. Absent, the records-only classification fails
        # CLOSED (stales) rather than guessing a machinery list - see Test-ReviewCampaignDeltaIsRecordsOnly.
        [AllowNull()][AllowEmptyString()][string]$RepoRoot,
        # The ACTIVE feature, so its PROCESS RECORDS can be told apart from its requirement- and
        # design-bearing artifacts, and from another feature's tree entirely. Absent -> nothing under
        # specs/ counts as records (fail closed).
        [AllowNull()][AllowEmptyString()][string]$FeatureId,
        [AllowEmptyCollection()][string[]]$OrderedRunIds = @(),
        [AllowEmptyCollection()][object[]]$Results = @(),
        [AllowNull()]$ActiveRun,
        [AllowEmptyCollection()][object[]]$HumanDispositions = @(),
        # T003 / FR-009: the paths that changed since the latest result. A delta touching only the
        # methodology machinery or the lifecycle records tree is not reviewable content, so it must
        # not stale a reviewed state - DRIFT-199-I001-013 caught this twice in one session, once when
        # a commit containing nothing but the drift log invalidated the review that produced it.
        # $null (unknown) fails CLOSED and stales as before: absence of evidence is not evidence.
        [AllowNull()][object[]]$ChangedPathsSinceResult = $null,
        # FR-009 ON THE IN-FLIGHT PATH (maintainer ruling 2026-08-11, DRIFT-199-I001-036). The same
        # question as ChangedPathsSinceResult, asked against the RUNNING round's frozen target instead
        # of the last published result. It needs its own baseline: while a round is in flight the newest
        # reviewed tree is that round's target, not the previous result's.
        #
        # This closes DRIFT-199-I001-013 on the path it was never applied to. The terminal branch below
        # has exempted records-only deltas since T003; this branch compared digests exactly, so writing
        # down what a review is about invalidated the review that was running - and every
        # governance-required commit during a round made the human pay for a round they could not use.
        # $null (unknown) fails CLOSED and stales, exactly as on the terminal path.
        [AllowNull()][object[]]$ChangedPathsSinceActiveRun = $null,
        # T003 / FR-007: the recorded signoff-gate decision. T067's two-governor collision made an
        # agent adjudicate between a gate that said allow and a surface that said blocked - a call a
        # consumer cannot make. The surface consults the record instead of contradicting it.
        [AllowNull()]$SignoffGateDecision = $null,
        # T003: a pending pause on the CURRENT tree is a sanctioned quiet state (the maintainer's
        # architecture-lens addition). A superseded pause - one describing a tree that has moved on -
        # confers nothing, because a stale pause would SILENCE the surface rather than nag it.
        [AllowNull()]$PendingPause = $null
    )
    if (-not (Test-ReviewAuthorityIdentifier -Value $CampaignId -Kind campaign) -or [string]::IsNullOrWhiteSpace($CurrentDigest)) {
        return New-ReviewCampaignVerdictPacketDecision -Route 'review-failure' -Reason 'campaign-or-digest-invalid' -Message 'Specrew cannot tell which review this is, or what state your files are in, so it cannot ask you for a decision yet.' -CampaignId $CampaignId -TargetDigest $CurrentDigest -ImplementerAction 'repair-review-state'
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
            return New-ReviewCampaignVerdictPacketDecision -Route 'review-running' -Reason 'current-review-in-flight' -Message 'A review of your files as they are now is still running; there is nothing for you to decide yet.' -CampaignId $CampaignId -RunId $activeRunId -TargetDigest $CurrentDigest -ImplementerAction 'poll-existing-run'
        }
        # The tree moved while the round runs - but a records-only move is not reviewable content, and
        # the running round still covers the code. Same predicate, same fail-closed default, as the
        # terminal path: the exemption exists so that WRITING DOWN what a review is about cannot
        # invalidate that review, and a round in flight has exactly the same claim to it.
        if ($null -ne $ChangedPathsSinceActiveRun -and
            (Test-ReviewCampaignDeltaIsRecordsOnly -ChangedPaths $ChangedPathsSinceActiveRun -RepoRoot $RepoRoot -FeatureId $FeatureId)) {
            return New-ReviewCampaignVerdictPacketDecision -Route 'review-running' -Reason 'current-review-in-flight-records-only-delta' -Message 'A review of your files is still running; only governance and records files have changed since it started, so it still covers your project. There is nothing for you to decide yet.' -CampaignId $CampaignId -RunId $activeRunId -TargetDigest $CurrentDigest -ImplementerAction 'poll-existing-run'
        }
        return New-ReviewCampaignVerdictPacketDecision -Route 'review-stale' -Reason 'in-flight-review-target-moved' -Message 'The review that is running started from an earlier version of your files, so it cannot sign off what you have now.' -CampaignId $CampaignId -RunId $activeRunId -TargetDigest $CurrentDigest -ImplementerAction 'complete-or-reconcile-then-rerun-current'
    }

    # A pause recorded against the CURRENT tree is a decision already sitting with the human. Nagging
    # for a review there would ask them to spend on a question they are mid-answer to.
    #
    # The quiet rule comes from Test-ReviewCampaignPendingPauseQuiet rather than being re-decided
    # here. An inline copy of the comparison was the shadowing class in miniature: two
    # implementations of one rule, and the SILENCING direction is where a divergence does real harm -
    # a stale pause that still confers quiet suppresses the surface on a tree it never described.
    #
    # ...AND A PAUSE NEVER SUPPRESSES A BOUNDARY-RELEASING RESULT. This ordering was latent while the
    # consult was inert and became a wedge the moment it went live: T001 makes EVERY round end in a
    # pause, so after any completed round a pending pause and that round's clean pass describe the
    # same tree simultaneously. Quieting there left the human holding a decision with no packet to
    # answer it through - the boundary packet IS how they answer - which is the wedge class this
    # feature exists to remove, arriving from the direction the pause rule was meant to protect.
    # What the pause legitimately suppresses is a DEMAND: do not nag for another review or
    # disposition while one is already sitting with them. Releasing what they need in order to answer
    # is not a demand. Caught by T051's own fixture rather than by reasoning.
    $pauseQuiets = (Test-ReviewCampaignPendingPauseQuiet -PendingPause $PendingPause -CurrentDigest $CurrentDigest).confers_quiet
    if ($pauseQuiets -and $ordered.Count -gt 0) {
        $newestRunId = $ordered[$ordered.Count - 1]
        if ($byRun.ContainsKey($newestRunId)) {
            $newest = $byRun[$newestRunId]
            # A CLEAN pass is not the only boundary-releasing shape. A findings result the human has explicitly
            # ACCEPTED releases too - and an acceptance IS an answer to the pause, recorded through a different
            # instrument. Exempting only the clean pass left that case wedged in exactly the way the clean case
            # was: the human answers, and the surface keeps telling them a decision is outstanding.
            if (Test-ReviewCampaignResultReleasesBoundary -Result $newest -CurrentDigest $CurrentDigest) {
                $pauseQuiets = $false
            }
            elseif ((Test-ReviewCampaignResultIsCompleteCurrent -Result $newest -CurrentDigest $CurrentDigest) -and
                [string]$newest.verdict -ceq 'findings' -and
                (Test-ReviewCampaignDispositionAcceptsResult -HumanDispositions $HumanDispositions -CampaignId $CampaignId -RunId $newestRunId -CurrentDigest $CurrentDigest)) {
                $pauseQuiets = $false
            }
        }
    }
    if ($pauseQuiets) {
        return New-ReviewCampaignVerdictPacketDecision -Route 'pause-pending' -Reason 'human-pause-decision-outstanding' -Message 'This review is waiting for your decision; nothing is running and nothing is being spent.' -CampaignId $CampaignId -RunId ([string](Get-ReviewAuthorityProperty -Object $PendingPause -Name 'run_id')) -TargetDigest $CurrentDigest -ImplementerAction 'await-human-pause-decision'
    }

    if ($ordered.Count -eq 0) {
        return New-ReviewCampaignVerdictPacketDecision -Route 'review-required' -Reason 'no-authoritative-campaign-result' -Message 'No completed review covers your files as they are now. Approving a review round is the human''s decision and costs one of their rounds, so ASK them for it: their typed reply `approved for review round` is the approval, and Specrew captures it from the conversation. Once they have typed it, run specrew review --live --approve-round yourself. If they prefer not to spend a round, they can review the artifacts themselves and say what they conclude.' -CampaignId $CampaignId -TargetDigest $CurrentDigest -ImplementerAction 'request-authorized-review'
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
        # FR-007: a recorded gate decision for THIS tree is authority, not an opinion to argue with.
        if ($null -ne $SignoffGateDecision -and
            [string](Get-ReviewAuthorityProperty -Object $SignoffGateDecision -Name 'decision') -ceq 'allow' -and
            [string](Get-ReviewAuthorityProperty -Object $SignoffGateDecision -Name 'reviewed_digest') -ceq $CurrentDigest) {
            # -RenderBoundaryPacket $true, because line ~1007 maps this flag DIRECTLY to allow/block and
            # it defaults to $false. Without it this branch said "Your review is signed off for the files
            # as they are now" and returned a BLOCK - the message and the decision contradicting each
            # other, with the message being the true one. A recorded allow for THIS exact tree is
            # authority (FR-007); projecting it back into a block wedges sign-off against the store's own
            # record.
            return New-ReviewCampaignVerdictPacketDecision -Route 'review-current' -Reason 'signoff-gate-allow-recorded' -Message 'Your review is signed off for the files as they are now.' -CampaignId $CampaignId -RunId $latestRunId -TargetDigest $CurrentDigest -GateAllows $true -ImplementerAction 'proceed'
        }
        # FR-009: only reviewable content stales a review. Machinery and the lifecycle records tree
        # are not reviewable content, so recording what a review found cannot invalidate it.
        if ($null -ne $ChangedPathsSinceResult -and
            (Test-ReviewCampaignDeltaIsRecordsOnly -ChangedPaths $ChangedPathsSinceResult -RepoRoot $RepoRoot -FeatureId $FeatureId)) {
            # THE EXEMPTION PRESERVES AN ALREADY-AUTHORIZING RESULT; IT NEVER PROMOTES ONE.
            #
            # My own regression, found by round 5. Setting GateAllows here unconditionally meant a
            # reviewer that TIMED OUT or published a partial/invalid findings result, followed by a
            # drift-log commit, produced a digest differing only by that record - and this branch handed
            # the signoff gate an ALLOW for a result that could never have authorized anything. The
            # records-only rule is about STALENESS, not about authority: it says a records commit does
            # not take your review away. It must not be able to give you one you never had.
            #
            # So the allow is conditional on the result being one that authorizes on its own terms. When
            # it is not, this falls through to the ordinary handling, which stales - the safe direction.
            $recordsOnlyAuthorizes = (
                [string](Get-ReviewAuthorityProperty -Object $latest -Name 'runtime_outcome') -ceq 'completed' -and
                [string](Get-ReviewAuthorityProperty -Object $latest -Name 'completion') -ceq 'complete' -and
                [string](Get-ReviewAuthorityProperty -Object $latest -Name 'validation') -ceq 'valid' -and
                [bool](Get-ReviewAuthorityProperty -Object $latest -Name 'can_approve_current')
            )
            if (-not $recordsOnlyAuthorizes) {
                return New-ReviewCampaignVerdictPacketDecision -Route 'review-stale' -Reason 'records-only-delta-over-non-authorizing-result' -Message 'Only governance and records files changed since your last review, but that review did not finish with a result that can sign anything off. Run a fresh review of your files as they are now: specrew review --live' -CampaignId $CampaignId -RunId $latestRunId -TargetDigest $CurrentDigest -ImplementerAction 'request-current-digest-review'
            }
            return New-ReviewCampaignVerdictPacketDecision -Route 'review-current' -Reason 'records-only-delta-does-not-stale' -Message 'Only governance and records files changed since your review, so it still covers your project.' -CampaignId $CampaignId -RunId $latestRunId -TargetDigest $CurrentDigest -GateAllows $true -ImplementerAction 'proceed'
        }
        # T010 / FR-015, FR-016. MEASURED four times in one reviewer session: every word of the old
        # sentence was true and the reader still could not act, because the two facts that resolve it
        # were missing.
        #
        # (1) WHOSE result it is - and the FIRST attempt at this got the mechanism wrong, so the
        #     corrected version is recorded here. The observed block named `run-f198-beta2-...-certify`
        #     during beta3 work, which reads as a beta2 result leaking in. It is NOT: results are
        #     validated with -ExpectedCampaignId above, so a foreign-campaign result returns
        #     review-failure and can never reach this branch. What actually happened is a RUN ID whose
        #     TEXT names another feature (an explicit --run-id) inside THIS campaign. So the fix is not
        #     a conditional "belongs to a different review" - that case is unreachable - it is to state
        #     unconditionally which campaign the result belongs to, so a misleading run id cannot imply
        #     otherwise. The reader then sees the run id and its true owner in the same sentence.
        # (2) WHO CAN CLEAR IT. The only remediation, `request-current-digest-review`, is addressed to
        #     the implementer. A reader in any other role holds an instruction they cannot execute, so
        #     the block re-fires at every stop - and a block correctly declined every time trains people
        #     to stop reading blocks, which is how the one that matters gets missed.
        #
        # The structured `implementer_action` is UNCHANGED; only the human sentence gains these clauses.
        $latestCampaignId = [string](Get-ReviewAuthorityProperty -Object $latest -Name 'campaign_id')
        $ownership = if (-not [string]::IsNullOrWhiteSpace($latestCampaignId)) {
            ' That result belongs to this review ({0}) - whatever its run name suggests - so it is about your own earlier snapshot, not another project.' -f $latestCampaignId
        }
        else { '' }
        $staleMessage = 'The latest campaign result remains useful evidence but targets a moved or earlier snapshot and cannot authorize the current tree.' +
        $ownership +
        ' If you are not the person running reviews for this project, this is advisory: there is nothing here for you to run, and it does not block your work.'
        return New-ReviewCampaignVerdictPacketDecision -Route 'review-stale' -Reason 'latest-result-not-current' -Message $staleMessage -CampaignId $CampaignId -RunId $latestRunId -TargetDigest $CurrentDigest -ImplementerAction 'request-current-digest-review'
    }
    if ([string]$latest.runtime_outcome -ceq 'timed-out') {
        # FR-018: a consumer who loses a review to the budget must be told which setting to change.
        # Shape: what happened -> what it means for their project -> the exact next step.
        return New-ReviewCampaignVerdictPacketDecision -Route 'review-timeout' -Reason 'latest-review-timed-out' -Message (
            'The review ran out of time before it finished (' + [string]$latest.failure_reason + '), so it produced no usable result. ' +
            'Reviews of this size often need a longer window: raise co_review_timeout_seconds in .specrew/config.yml, ' +
            'or pass --timeout-seconds on the next run, then run the review again.'
        ) -CampaignId $CampaignId -RunId $latestRunId -TargetDigest $CurrentDigest -ImplementerAction 'report-failure-and-request-rerun-grant'
    }
    if ([string]$latest.completion -cne 'complete') {
        return New-ReviewCampaignVerdictPacketDecision -Route 'review-partial' -Reason 'latest-review-incomplete' -Message 'Validated partial findings remain advisory, but a complete separately authorized run is required.' -CampaignId $CampaignId -RunId $latestRunId -TargetDigest $CurrentDigest -ImplementerAction 'use-partial-findings-and-request-rerun-grant'
    }
    if ([string]$latest.validation -cne 'valid' -or [string]$latest.currentness -cne 'current') {
        return New-ReviewCampaignVerdictPacketDecision -Route 'review-failure' -Reason ('latest-review-' + [string]$latest.runtime_outcome) -Message ('The campaign review failed: ' + [string]$latest.failure_reason) -CampaignId $CampaignId -RunId $latestRunId -TargetDigest $CurrentDigest -ImplementerAction 'report-failure-and-request-rerun-grant'
    }
    # The SAME predicate the pause guard above consults. Reaching here means the sequential gates have
    # already excluded every other shape, so this is equivalent to the conjunction it replaces - and
    # sharing one definition is what stops the pause guard and this return drifting apart.
    if (Test-ReviewCampaignResultReleasesBoundary -Result $latest -CurrentDigest $CurrentDigest) {
        return New-ReviewCampaignVerdictPacketDecision -Route 'boundary-clean' -Reason 'complete-current-clean-result' -Message 'Your review passed, and it covers your files exactly as they are now.' -CampaignId $CampaignId -RunId $latestRunId -TargetDigest $CurrentDigest -RenderBoundaryPacket $true -ImplementerAction 'render-boundary-packet'
    }
    if ([string]$latest.verdict -ceq 'findings') {
        $matchingDispositions = @($HumanDispositions | Where-Object {
            $v = Test-ReviewAuthorityContractObject -ContractName HumanDispositionFact -InputObject $_ -ExpectedCampaignId $CampaignId -ExpectedRunId $latestRunId -ExpectedTargetDigest $CurrentDigest
            $v.valid
        })
        $requiresCorrection = @($matchingDispositions | Where-Object { [string]$_.decision -ceq 'require-correction' }).Count -gt 0
        # The SAME predicate the pause guard consults, so a disposition can never answer the pause and fail to
        # release here, or the reverse.
        if (Test-ReviewCampaignDispositionAcceptsResult -HumanDispositions $HumanDispositions -CampaignId $CampaignId -RunId $latestRunId -CurrentDigest $CurrentDigest) {
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
    $identity = $null
    if ([string]::IsNullOrWhiteSpace($CampaignId) -or [string]::IsNullOrWhiteSpace($TargetLineage)) {
        $identity = Resolve-ReviewCampaignPublicIdentity -RepoRoot $root -FeatureId $FeatureId -IterationNumber $IterationNumber -RunId 'run-gate-probe'
        if ([string]::IsNullOrWhiteSpace($CampaignId)) { $CampaignId = [string]$identity.campaign_id }
        if ([string]::IsNullOrWhiteSpace($TargetLineage)) { $TargetLineage = [string]$identity.target_lineage }
        if ([string]::IsNullOrWhiteSpace($FeatureId)) { $FeatureId = [string]$identity.feature_id }
        if ([string]::IsNullOrWhiteSpace($IterationNumber)) { $IterationNumber = [string]$identity.iteration_number }
    }
    if ($null -ne $identity -and ([string]::IsNullOrWhiteSpace($CampaignId) -or [string]::IsNullOrWhiteSpace($TargetLineage) -or
        -not (Test-ReviewCampaignScopeIdentity -FeatureId $FeatureId -IterationNumber $IterationNumber))) {
        return New-ReviewCampaignVerdictPacketDecision -Route 'review-failure' -Reason 'scope-identity-unresolvable' `
            -Message 'Campaign, lineage, feature, and iteration identity must resolve before finalization validation or publication.' `
            -CampaignId $CampaignId -ImplementerAction 'repair-review-state'
    }
    if ([string]::IsNullOrWhiteSpace($StoreRoot)) { $StoreRoot = Join-Path $root '.specrew/review/authority' }
    $digest = Get-ContinuousCoReviewReviewedStateDigest -RepoRoot $root -ExcludedPathPatterns $ExcludedPathPatterns
    if ($null -eq $digest -or -not $digest.ok -or [string]::IsNullOrWhiteSpace([string]$digest.tree_id)) {
        return New-ReviewCampaignVerdictPacketDecision -Route 'review-failure' -Reason 'digest-unresolvable' -Message 'Specrew could not read the current state of your files, so it cannot ask you for a decision yet.' -CampaignId $CampaignId -ImplementerAction 'repair-review-state'
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
    $finalizationFact = Get-ReviewCampaignFinalizationFact -StoreRoot $StoreRoot -CampaignId $CampaignId
    $finalizationEnvelope = $null
    $latestResult = $null
    if ($orderedRunIds.Count -gt 0) {
        $latestRunId = [string]$orderedRunIds[$orderedRunIds.Count - 1]
        $latestResult = @($results | Where-Object { [string]$_.run_id -ceq $latestRunId } | Select-Object -First 1)
        if ($latestResult.Count -gt 0) { $latestResult = $latestResult[0] } else { $latestResult = $null }
    }
    $finalizationCandidateEligible = $null -eq $activeRun -and $null -ne $latestResult -and
        [string]$latestResult.target_digest -cne [string]$digest.tree_id -and
        [string]$latestResult.completion -ceq 'complete' -and [string]$latestResult.verdict -ceq 'pass' -and
        [string]$latestResult.runtime_outcome -ceq 'completed' -and [bool]$latestResult.can_approve_current
    if (($null -ne $finalizationFact -or $finalizationCandidateEligible) -and
        -not (Test-ReviewCampaignScopeIdentity -FeatureId $FeatureId -IterationNumber $IterationNumber)) {
        return New-ReviewCampaignVerdictPacketDecision -Route 'review-failure' -Reason 'scope-identity-unresolvable' `
            -Message 'Feature and iteration identity must resolve before finalization validation or publication.' `
            -CampaignId $CampaignId -RunId $(if ($null -ne $latestResult) { [string]$latestResult.run_id } else { $null }) `
            -TargetDigest ([string]$digest.tree_id) -ImplementerAction 'repair-review-state'
    }
    if ($null -ne $finalizationFact) {
        if ($null -eq $latestResult) {
            return New-ReviewCampaignVerdictPacketDecision -Route 'review-failure' -Reason 'review-finalization-result-missing' -Message 'The one-time finalization fact has no matching latest campaign result; authority fails closed.' -CampaignId $CampaignId -TargetDigest ([string]$digest.tree_id) -ImplementerAction 'repair-review-state'
        }
        $finalizationEnvelope = Test-ReviewCampaignFinalizationEnvelope -RepoRoot $root -CampaignId $CampaignId -Result $latestResult `
            -Fact $finalizationFact -CurrentDigest ([string]$digest.tree_id) -FeatureId $FeatureId -IterationNumber $IterationNumber `
            -ExcludedPathPatterns $ExcludedPathPatterns
        if (-not $finalizationEnvelope.valid) {
            return New-ReviewCampaignVerdictPacketDecision -Route 'review-failure' -Reason ('review-finalization-invalid:' + [string]$finalizationEnvelope.reason) -Message 'The one-time review finalization fact or its commit envelope is invalid; authority fails closed.' -CampaignId $CampaignId -RunId ([string]$finalizationFact.run_id) -TargetDigest ([string]$digest.tree_id) -ImplementerAction 'repair-review-state'
        }
    }
    elseif ($finalizationCandidateEligible) {
        $candidateFact = [pscustomobject][ordered]@{
            schema_version = '1.0'; fact_type = 'review-finalization'; campaign_id = $CampaignId
            run_id = [string]$latestResult.run_id; reviewed_digest = [string]$latestResult.target_digest
            finalization_commit = [string](@(& git -C $root rev-parse --verify 'HEAD^{commit}' 2>$null) | Select-Object -First 1)
        }
        $candidateEnvelope = Test-ReviewCampaignFinalizationEnvelope -RepoRoot $root -CampaignId $CampaignId -Result $latestResult `
            -Fact $candidateFact -CurrentDigest ([string]$digest.tree_id) -FeatureId $FeatureId -IterationNumber $IterationNumber `
            -ExcludedPathPatterns $ExcludedPathPatterns
        if ($candidateEnvelope.valid) {
            try {
                Write-ReviewCampaignFinalizationFact -StoreRoot $StoreRoot -Fact $candidateFact | Out-Null
            }
            catch {
                if ($_.Exception.Message -notlike 'review-store-corruption:conflicting-immutable-fact:*') { throw }
                # Another gate may have won CreateNew after this gate validated its candidate. The
                # winner is authoritative only if the normal read + envelope validation below proves
                # it binds this same clean result and current finalization commit.
            }
            $finalizationFact = Get-ReviewCampaignFinalizationFact -StoreRoot $StoreRoot -CampaignId $CampaignId
            if ($null -eq $finalizationFact) { throw 'review-finalization-post-publish-missing' }
            $finalizationEnvelope = Test-ReviewCampaignFinalizationEnvelope -RepoRoot $root -CampaignId $CampaignId -Result $latestResult `
                -Fact $finalizationFact -CurrentDigest ([string]$digest.tree_id) -FeatureId $FeatureId -IterationNumber $IterationNumber `
                -ExcludedPathPatterns $ExcludedPathPatterns
            if (-not $finalizationEnvelope.valid) { throw ('review-finalization-post-publish-invalid:' + [string]$finalizationEnvelope.reason) }
        }
    }
    $decisionDigest = if ($null -ne $finalizationEnvelope) { [string]$finalizationEnvelope.reviewed_digest } else { [string]$digest.tree_id }

    # T003: the four consults, resolved HERE because this is the only place that holds the store, the
    # repository and the digests at once. They were accepted by Resolve- but never supplied, so every
    # rule they carry was inert on the path a consumer actually runs - the stop surface kept demanding
    # reviews it had the evidence to skip. Each resolves to $null on any failure, and $null is the
    # fail-closed value for all four: the surface stays LIVE rather than going quiet on a bad read.
    $pendingPause = $null
    try { $pendingPause = Get-ReviewCampaignPendingPause -StoreRoot $StoreRoot -CampaignId $CampaignId }
    catch { $pendingPause = $null }

    $recordedGateDecision = Get-ContinuousCoReviewRecordedSignoffGateDecision -RepoRoot $root

    # FR-009 evidence, computed only when there IS a latest result to have moved away from. Note this
    # deliberately uses the LATEST RESULT's digest rather than $decisionDigest's history: the question
    # is "what changed since the thing that reviewed you", not "what changed recently".
    $changedSinceResult = $null
    if ($null -ne $latestResult) {
        $changedSinceResult = Get-ReviewCampaignChangedPathsSinceResult -RepoRoot $root `
            -ReviewedDigest ([string]$latestResult.target_digest) -CurrentDigest $decisionDigest
    }

    # The same evidence for a RUNNING round, against its own frozen target. Computed separately rather
    # than reusing the delta above, because while a round is in flight the newest reviewed tree is that
    # round's target and the last result's digest is older - so the result baseline would report changes
    # the running round already covers (DRIFT-199-I001-036).
    $changedSinceActiveRun = $null
    if ($null -ne $activeRun) {
        $changedSinceActiveRun = Get-ReviewCampaignChangedPathsSinceResult -RepoRoot $root `
            -ReviewedDigest ([string]$activeRun.target_digest) -CurrentDigest $decisionDigest
    }

    $packet = Resolve-ReviewCampaignVerdictPacketDecision -CampaignId $CampaignId -CurrentDigest $decisionDigest `
        -RepoRoot $root -OrderedRunIds $orderedRunIds -Results $results -ActiveRun $activeRun `
        -FeatureId $FeatureId -HumanDispositions $dispositions -PendingPause $pendingPause `
        -SignoffGateDecision $recordedGateDecision -ChangedPathsSinceResult $changedSinceResult `
        -ChangedPathsSinceActiveRun $changedSinceActiveRun
    if ($null -eq $finalizationEnvelope) { return $packet }
    if ([string]$packet.route -cne 'boundary-clean') {
        return New-ReviewCampaignVerdictPacketDecision -Route 'review-failure' -Reason 'review-finalization-result-not-clean' -Message 'The finalization envelope is valid but its bound result is not an authorizing clean result; authority fails closed.' -CampaignId $CampaignId -RunId ([string]$finalizationEnvelope.run_id) -TargetDigest ([string]$digest.tree_id) -ImplementerAction 'repair-review-state'
    }
    $message = 'The authoritative campaign result reviewed commit {0} at digest {1}; the controller finalized its allowlisted review evidence exactly once as commit {2}.' -f `
        [string]$finalizationEnvelope.reviewed_commit, [string]$finalizationEnvelope.reviewed_digest, [string]$finalizationEnvelope.finalization_commit
    return New-ReviewCampaignVerdictPacketDecision -Route 'boundary-finalized' -Reason 'complete-clean-finalized-result' -Message $message `
        -CampaignId $CampaignId -RunId ([string]$finalizationEnvelope.run_id) -TargetDigest ([string]$digest.tree_id) `
        -ReviewedDigest ([string]$finalizationEnvelope.reviewed_digest) -ReviewedCommit ([string]$finalizationEnvelope.reviewed_commit) `
        -FinalizationCommit ([string]$finalizationEnvelope.finalization_commit) -RenderBoundaryPacket $true -ImplementerAction 'render-boundary-packet'
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

    # T067 / FR-025: the explicit human-authorized partial-coverage escape hatch applies
    # to both authority models. Campaign cutover originally returned at line 1047 before
    # reaching the legacy-positioned check below, which made the documented escape hatch
    # unreachable precisely when the hard gate became the default. Keep authority config
    # validation ahead of the override (a missing trust model is never bypassed), then let
    # a complete, explicit authorization short-circuit either evidence evaluator.
    if (Test-ContinuousCoReviewOverrideAuthorization -OverrideAuthorization $OverrideAuthorization) {
        return New-ContinuousCoReviewSignoffGateDecision -Decision 'allow' -Reason 'human-authorized-partial-override' -Message 'Signoff allowed under a recorded human-authorized partial-coverage override.' -OverrideAuthorization $OverrideAuthorization
    }

    if ([bool]$authority.campaign_authority_enabled) {
        try {
            $packet = Get-ReviewCampaignVerdictPacketDecision -RepoRoot $resolvedRepoRoot -CampaignId $CampaignId -TargetLineage $TargetLineage -StoreRoot $CampaignStoreRoot -FeatureId $FeatureId -IterationNumber $IterationNumber -ExcludedPathPatterns $ExcludedPathPatterns
        }
        catch {
            return New-ContinuousCoReviewSignoffGateDecision -Decision 'block' -Reason 'campaign-review-state-invalid' -Message ('Campaign review authority could not be read safely: ' + $_.Exception.Message)
        }
        $decision = New-ContinuousCoReviewSignoffGateDecision -Decision $(if ($packet.gate_allows) { 'allow' } else { 'block' }) -Reason $packet.reason -Message $packet.message -CurrentTreeId $packet.target_digest -MatchedRunId $packet.run_id
        foreach ($property in @('route', 'campaign_id', 'render_boundary_packet', 'render_verdict_marker', 'gate_allows', 'ask_narrow_question', 'implementer_action', 'reviewed_digest', 'reviewed_commit', 'finalization_commit')) {
            $decision | Add-Member -NotePropertyName $property -NotePropertyValue $packet.$property
        }
        return $decision
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

        [AllowNull()] $DegradedAcknowledgement,

        [string] $AuthorityConfigPath,
        [string] $CampaignId,
        [string] $TargetLineage,
        [string] $FeatureId,
        [string] $IterationNumber,
        [string] $CampaignStoreRoot
    )

    $decision = Get-ContinuousCoReviewSignoffGateDecision -RepoRoot $RepoRoot -TrunkName $TrunkName `
        -ExcludedPathPatterns $ExcludedPathPatterns -OverrideAuthorization $OverrideAuthorization `
        -DegradedAcknowledgement $DegradedAcknowledgement -AuthorityConfigPath $AuthorityConfigPath `
        -CampaignId $CampaignId -TargetLineage $TargetLineage -FeatureId $FeatureId `
        -IterationNumber $IterationNumber -CampaignStoreRoot $CampaignStoreRoot
    if ($decision.decision -eq 'block') {
        throw "[continuous-co-review-gate] review-signoff refused ($($decision.reason)): $($decision.message)"
    }

    return $decision
}
