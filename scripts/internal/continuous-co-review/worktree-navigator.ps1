$ErrorActionPreference = 'Stop'
Set-StrictMode -Version Latest

# iter-008 — the worktree-engine navigator: a FAST Stop-trigger. It REUSES the legacy navigator's reap +
# stage-gate + dedup-state (the survive-half) and the host-neutral co-review SERVICE for the fire
# (Start-ContinuousCoReviewServiceRun -Detached). It does NO heavy work on the Stop budget — identity is the fast
# HEAD-subtree tree-id and the materialize + review run in the detached orchestrator. The legacy navigator is
# UNTOUCHED; the provider selects this engine by config (co_review_engine=worktree). The legacy path is deleted at
# cutover (the tracked must-happen final step), so the two paths do not ossify.

. (Join-Path $PSScriptRoot 'co-review-service.ps1')   # brings the legacy navigator (reap/stage/dedup) + the service (fire/identity)

function Test-ReviewCampaignBoundaryRequiresIteration {
    # Feature-level intake legitimately has an active lifecycle cursor before any iteration exists.
    # Only a cursor at plan or later proves that a missing iteration is suspicious. Unknown or
    # malformed non-empty cursor values fail closed by returning true.
    param(
        [AllowNull()]
        $BoundaryCursor
    )

    if ($null -eq $BoundaryCursor) { return $false }

    $candidates = [System.Collections.Generic.List[string]]::new()
    if ($BoundaryCursor -is [string]) {
        if ([string]::IsNullOrWhiteSpace([string]$BoundaryCursor)) { return $false }
        $candidates.Add([string]$BoundaryCursor) | Out-Null
    }
    else {
        # pending_crossing is an object. Its destination/working boundary determines whether
        # iteration state is expected; from_boundary may still be the pre-feature 'intake'.
        foreach ($propertyName in @('working_boundary', 'to_boundary')) {
            if (($BoundaryCursor.PSObject.Properties.Name -contains $propertyName) -and
                -not [string]::IsNullOrWhiteSpace([string]$BoundaryCursor.$propertyName)) {
                $candidates.Add([string]$BoundaryCursor.$propertyName) | Out-Null
            }
        }
        if ($candidates.Count -eq 0) { return $true }
    }

    foreach ($candidate in $candidates) {
        $normalized = $candidate.Trim().ToLowerInvariant()
        if (Get-Command -Name 'Normalize-SpecrewCanonicalBoundaryType' -ErrorAction SilentlyContinue) {
            try { $normalized = Normalize-SpecrewCanonicalBoundaryType -Boundary $candidate }
            catch { return $true }
        }
        if ($normalized -notin @('intake', 'specify', 'clarify')) { return $true }
    }
    return $false
}

function Get-ReviewCampaignNavigatorScopeApplicability {
    # Campaign authority is installed before a greenfield project has an active feature or iteration. Those
    # intake states are expected no-ops, not authority failures. Once any active-feature signal exists, malformed
    # or missing state remains applicable so the packet gate below fails closed with the authoritative reason.
    param([Parameter(Mandatory)][string]$RepoRoot)

    $featureRoot = $null
    $activeFeatureSignal = $false
    $activeIterationSignal = $false
    $featureJsonPath = Join-Path $RepoRoot '.specify/feature.json'
    if (Test-Path -LiteralPath $featureJsonPath -PathType Leaf) {
        $activeFeatureSignal = $true
        try {
            $featureJson = Get-Content -LiteralPath $featureJsonPath -Raw -Encoding UTF8 | ConvertFrom-Json
            if (($featureJson.PSObject.Properties.Name -contains 'feature_directory') -and
                -not [string]::IsNullOrWhiteSpace([string]$featureJson.feature_directory)) {
                $candidate = Join-Path $RepoRoot ([string]$featureJson.feature_directory)
                if (Test-Path -LiteralPath $candidate -PathType Container) { $featureRoot = $candidate }
            }
        }
        catch { return [pscustomobject]@{ applicable = $true; reason = 'active-feature-state-invalid' } }
    }

    $startContextPath = Join-Path $RepoRoot '.specrew/start-context.json'
    if (Test-Path -LiteralPath $startContextPath -PathType Leaf) {
        try {
            $startContext = Get-Content -LiteralPath $startContextPath -Raw -Encoding UTF8 | ConvertFrom-Json
            $featurePath = $null
            if ($startContext.PSObject.Properties['session_state'] -and $null -ne $startContext.session_state) {
                if ($startContext.session_state.PSObject.Properties['feature_path']) {
                    $featurePath = [string]$startContext.session_state.feature_path
                }
                if ($startContext.session_state.PSObject.Properties['iteration_number'] -and
                    -not [string]::IsNullOrWhiteSpace([string]$startContext.session_state.iteration_number)) {
                    $activeFeatureSignal = $true
                    $activeIterationSignal = $true
                }
                if ($startContext.session_state.PSObject.Properties['boundary_type'] -and
                    -not [string]::IsNullOrWhiteSpace([string]$startContext.session_state.boundary_type)) {
                    $activeFeatureSignal = $true
                    if (Test-ReviewCampaignBoundaryRequiresIteration -BoundaryCursor $startContext.session_state.boundary_type) {
                        $activeIterationSignal = $true
                    }
                }
            }
            elseif ($startContext.PSObject.Properties['feature_path']) {
                $featurePath = [string]$startContext.feature_path
            }
            if ($startContext.PSObject.Properties['boundary_enforcement'] -and $null -ne $startContext.boundary_enforcement) {
                foreach ($cursorName in @('last_authorized_boundary', 'pending_next_boundary', 'pending_crossing')) {
                    if ($startContext.boundary_enforcement.PSObject.Properties[$cursorName] -and
                        $null -ne $startContext.boundary_enforcement.$cursorName -and
                        -not [string]::IsNullOrWhiteSpace([string]$startContext.boundary_enforcement.$cursorName)) {
                        $activeFeatureSignal = $true
                        if (Test-ReviewCampaignBoundaryRequiresIteration -BoundaryCursor $startContext.boundary_enforcement.$cursorName) {
                            $activeIterationSignal = $true
                        }
                    }
                }
            }
            if (-not [string]::IsNullOrWhiteSpace($featurePath)) {
                $activeFeatureSignal = $true
                $candidate = if ([IO.Path]::IsPathRooted($featurePath)) { $featurePath } else { Join-Path $RepoRoot $featurePath }
                if (Test-Path -LiteralPath $candidate -PathType Container) { $featureRoot = $candidate }
            }
        }
        catch { return [pscustomobject]@{ applicable = $true; reason = 'active-session-state-invalid' } }
    }

    if ($null -eq $featureRoot) {
        $branch = @(& git -C $RepoRoot branch --show-current 2>$null)
        if ($LASTEXITCODE -eq 0 -and $branch.Count -gt 0 -and -not [string]::IsNullOrWhiteSpace([string]$branch[0])) {
            $candidate = Join-Path $RepoRoot ('specs/' + [string]$branch[0])
            if (Test-Path -LiteralPath $candidate -PathType Container) {
                $featureRoot = $candidate
                $activeFeatureSignal = $true
            }
        }
    }

    if ($null -eq $featureRoot) {
        if ($activeFeatureSignal) { return [pscustomobject]@{ applicable = $true; reason = 'active-feature-unresolved' } }
        return [pscustomobject]@{ applicable = $false; reason = 'campaign-not-applicable:no-active-feature' }
    }

    $iterationsRoot = Join-Path $featureRoot 'iterations'
    $iterations = @(if (Test-Path -LiteralPath $iterationsRoot -PathType Container) {
            Get-ChildItem -LiteralPath $iterationsRoot -Directory | Where-Object { $_.Name -match '^\d{3,}$' }
        })
    if ($iterations.Count -eq 0) {
        if ($activeIterationSignal) { return [pscustomobject]@{ applicable = $true; reason = 'active-iteration-unresolved' } }
        return [pscustomobject]@{ applicable = $false; reason = 'campaign-not-applicable:no-active-iteration' }
    }
    return [pscustomobject]@{ applicable = $true; reason = 'campaign-applicable' }
}

function Invoke-ContinuousCoReviewWorktreeNavigator {
    # Param shape MATCHES the legacy Invoke-ContinuousCoReviewNavigator so the provider config-selects between
    # the two by name with the SAME @navParams. -SessionStart = the cross-session sweep. -CodeWriterHost threads
    # through the service to the orchestrator's reviewer-host SELECTION (independent + authorized).
    param(
        [Parameter(Mandatory)][string]$RepoRoot,
        [AllowEmptyString()][string]$TrunkName = '',
        [switch]$SessionStart,
        [string]$CodeWriterHost,
        # T106/N4: the host transcript path (optional) - threads to the reap so the escalation-latch
        # can read REAL user turns to detect human closure.
        [string]$TranscriptPath,
        [int]$TimeoutSeconds = 900
    )
    $resolved = (Resolve-Path -LiteralPath $RepoRoot).Path
    $decision = [pscustomobject]@{ action = 'no-op'; reason = ''; engine = 'worktree'; fired_run_id = $null; fired_tree_id = $null; stop_block = $null; inject_notes = @() }

    $authority = Get-ContinuousCoReviewAuthorityDecision
    if (-not $authority.valid -or [string]$authority.mode -eq 'disabled') {
        $decision.reason = ('review-authority-disabled:' + [string]$authority.reason)
        return $decision
    }
    if ([bool]$authority.campaign_authority_enabled) {
        if ($SessionStart) { $decision.reason = 'campaign-cross-session-no-legacy-reap'; return $decision }
        $scope = Get-ReviewCampaignNavigatorScopeApplicability -RepoRoot $resolved
        if (-not [bool]$scope.applicable) {
            $decision.reason = [string]$scope.reason
            return $decision
        }
        try { $packet = Get-ReviewCampaignVerdictPacketDecision -RepoRoot $resolved }
        catch {
            $decision.reason = 'campaign-packet-gate-failed'
            $decision.stop_block = "Campaign review authority could not be read safely: $($_.Exception.Message)`n(Campaign review block, not a lifecycle verdict - do NOT emit a SPECREW-VERDICT-BOUNDARY marker.)"
            return $decision
        }
        $decision.reason = [string]$packet.reason
        if ([bool]$packet.render_boundary_packet) {
            $decision.inject_notes = @(("[co-review] campaign run {0} authorizes the exact current digest; the lifecycle boundary packet may now be rendered." -f $packet.run_id))
        }
        elseif ([string]$packet.route -eq 'review-running') {
            $decision.inject_notes = @(("[co-review] campaign run {0} is still reviewing the current digest; no decision is required." -f $packet.run_id))
        }
        else { $decision.stop_block = Build-ReviewCampaignNavigatorStopBlock -PacketDecision $packet }
        return $decision
    }

    # REAP (reuse) — surfaces any completed verdict (incl. the worktree engine's result.out) + cleans orphans.
    $reap = Invoke-ContinuousCoReviewNavigatorReap -RepoRoot $resolved -TrunkName $TrunkName -CrossSession:$SessionStart -TranscriptPath $TranscriptPath
    $decision.stop_block = $reap.stop_block
    $decision.inject_notes = @($reap.inject_notes)
    if ($SessionStart) { $decision.reason = 'cross-session-sweep'; return $decision }

    # IMPLEMENT-stage gate (reuse).
    $stage = Get-ContinuousCoReviewNavigatorImplementStage -RepoRoot $resolved
    if ($stage -ne 'implement') { $decision.reason = "not-implement-stage ($stage)"; return $decision }

    # Identity + dedup: the CERTIFIED digest identity (working tree), so a dirty increment CHANGES the
    # key and fires a new review - HEAD-tree keying deduped uncommitted edits as already-reviewed
    # (codex finding, run 20260708T225439577; the D-197-I010-004 follow-on). Digest failure falls back
    # to the HEAD subtree inside the helper (the navigator never breaks on a digest error).
    $treeId = Get-ContinuousCoReviewCheckpointIdentity -RepoRoot $resolved
    if ([string]::IsNullOrWhiteSpace($treeId)) { $decision.reason = 'identity-unresolved'; return $decision }
    $decision.fired_tree_id = $treeId
    if ($treeId -eq (Get-ContinuousCoReviewNavigatorLastFiredTreeId -RepoRoot $resolved)) { $decision.reason = 'deduped (already reviewed this tree)'; return $decision }

    # FIRE via the host-neutral service (detached; all heavy work off the Stop budget). T019 piece 3: the service
    # acquires the per-lineage LEASE atomically BEFORE spawning any reviewer (piece 2), so a concurrent DUPLICATE
    # (e.g. a manual --live already reviewing this lineage - the DRIFT-198-I003-002 collision class that
    # last_fired_tree_id misses because other drivers never set it) or a NEWER tree queued behind a live owner is
    # SUPPRESSED there rather than spawning a second reviewer. The LEASE is the SINGLE in-flight dedup source: we
    # consume its suppression here rather than add a second competing mechanism. last_fired_tree_id stays purely the
    # CHANGED-tree trigger above (don't re-review an unchanged, already-reviewed tree) and is advanced ONLY on a run
    # that actually fired - a suppressed acquire must NOT advance it (else the queued newer tree would be treated as
    # already-fired and never reviewed).
    try {
        $run = Start-ContinuousCoReviewServiceRun -RepoRoot $resolved -TreeId $treeId -CodeWriterHost $CodeWriterHost -TimeoutSeconds $TimeoutSeconds -Detached
        if (($run.PSObject.Properties['status']) -and ([string]$run.status -eq 'suppressed')) {
            $supReason = if ($run.PSObject.Properties['suppressed_reason']) { [string]$run.suppressed_reason } else { 'lease-not-acquired' }
            $decision.reason = ('deduped-by-lease ({0})' -f $supReason)   # NOT fired: no spawn, no spend/round, last_fired_tree_id UNCHANGED
        }
        else {
            Set-ContinuousCoReviewNavigatorLastFiredTreeId -RepoRoot $resolved -TreeId $treeId -RunId $run.run_id
            $decision.action = 'fired'; $decision.reason = 'registered-checkpoint'; $decision.fired_run_id = $run.run_id
        }
    }
    catch {
        $decision.reason = ('fire-failed: ' + $_.Exception.Message)
    }
    return $decision
}
