$ErrorActionPreference = 'Stop'
Set-StrictMode -Version Latest

# iter-008 — the worktree-engine navigator: a FAST Stop-trigger. It REUSES the legacy navigator's reap +
# stage-gate + dedup-state (the survive-half) and the host-neutral co-review SERVICE for the fire
# (Start-ContinuousCoReviewServiceRun -Detached). It does NO heavy work on the Stop budget — identity is the fast
# HEAD-subtree tree-id and the materialize + review run in the detached orchestrator. The legacy navigator is
# UNTOUCHED; the provider selects this engine by config (co_review_engine=worktree). The legacy path is deleted at
# cutover (the tracked must-happen final step), so the two paths do not ossify.

. (Join-Path $PSScriptRoot 'co-review-service.ps1')   # brings the legacy navigator (reap/stage/dedup) + the service (fire/identity)
# HARD dependency: the ONE path-identity primitive, loaded at FILE SCOPE. The implementation-presence
# predicate below asks it for the volume's case rule, and a Get-Command-guarded CALL that substitutes
# a different comparison would be the same defect as an $IsWindows shortcut - it answers, it answers
# wrongly, and nothing reports it. Guarded on a name unique to this module so a same-named duplicate
# cannot satisfy the check (DRIFT-198-I009-027).
if (-not (Get-Command -Name 'Get-ContinuousCoReviewPathCaseSensitive' -ErrorAction SilentlyContinue)) { . (Join-Path $PSScriptRoot 'path-identity.ps1') }

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
    $sessionBoundaryCursor = $null
    $crossingWorkingBoundary = $null
    $authorizedBoundaryCursor = $null
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
                    $sessionBoundaryCursor = [string]$startContext.session_state.boundary_type
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
                        if ($cursorName -eq 'last_authorized_boundary' -and [string]::IsNullOrWhiteSpace($authorizedBoundaryCursor)) {
                            $authorizedBoundaryCursor = [string]$startContext.boundary_enforcement.$cursorName
                        }
                        if ($cursorName -eq 'pending_crossing' -and $startContext.boundary_enforcement.pending_crossing -is [object] -and
                            $startContext.boundary_enforcement.pending_crossing.PSObject.Properties['working_boundary'] -and
                            -not [string]::IsNullOrWhiteSpace([string]$startContext.boundary_enforcement.pending_crossing.working_boundary)) {
                            $crossingWorkingBoundary = [string]$startContext.boundary_enforcement.pending_crossing.working_boundary
                        }
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

    # DRIFT pre-tag slice #2 (testbeta3, journal 2026-08-08T01:13:28Z; dry-run correction
    # 2026-08-08): applicability turned ON at iteration-directory existence while the auto-fire
    # path stays implement-only, so a consumer at design-analysis received a standing
    # review-required block nothing could ever satisfy — the i009 quiet-no-op family's missing
    # edge. The first fix quieted only plan/tasks — the PATTERN, not the INSTANCE: testbeta3's
    # actual cursor at the flip was 'clarify', because before-plan scaffolds the iteration BEFORE
    # any plan sync advances the cursor. Stated as the INVERSION so no future cursor rejoins the
    # gap: with an iteration present, the campaign surface is LIVE from 'before-implement' onward
    # (plus the legacy 'implement' alias) — there is implementation to review and the block is
    # satisfiable by a human CLI review; every EARLIER resolved canonical cursor is quiet
    # not-applicable (nothing reviewable exists yet; auto-fire stays implement-only; pre-code
    # reviews remain human-CLI-initiated). The WORKING position decides, in precedence order:
    # session_state.boundary_type, then pending_crossing.working_boundary, then
    # last_authorized_boundary — a pending crossing INTO before-implement is the implement
    # window's edge (the v2 missing-iteration fail-closed case pins this). Unresolved or
    # non-canonical cursors stay applicable so the packet gate fails closed with the
    # authoritative reason (this function's standing philosophy).
    $effectiveCursor = $sessionBoundaryCursor
    if ([string]::IsNullOrWhiteSpace($effectiveCursor)) { $effectiveCursor = $crossingWorkingBoundary }
    if ([string]::IsNullOrWhiteSpace($effectiveCursor)) { $effectiveCursor = $authorizedBoundaryCursor }
    if (-not [string]::IsNullOrWhiteSpace($effectiveCursor)) {
        $cursorNorm = $effectiveCursor.Trim().ToLowerInvariant()
        if (Get-Command -Name 'Normalize-SpecrewCanonicalBoundaryType' -ErrorAction SilentlyContinue) {
            try { $cursorNorm = Normalize-SpecrewCanonicalBoundaryType -Boundary $effectiveCursor } catch { $cursorNorm = $null }
        }
        if (-not [string]::IsNullOrWhiteSpace($cursorNorm) -and $cursorNorm -ne 'implement') {
            $boundaryOrder = @('specify', 'clarify', 'plan', 'tasks', 'before-implement', 'review-signoff', 'retro', 'iteration-closeout', 'feature-closeout')
            if (Get-Command -Name 'Get-SpecrewBoundaryOrder' -ErrorAction SilentlyContinue) {
                try { $boundaryOrder = @(Get-SpecrewBoundaryOrder) } catch { $null = $_ }
            }
            $cursorIdx = [Array]::IndexOf($boundaryOrder, $cursorNorm)
            $liveIdx = [Array]::IndexOf($boundaryOrder, 'before-implement')
            if ($cursorIdx -ge 0 -and $liveIdx -ge 0 -and $cursorIdx -lt $liveIdx) {
                return [pscustomobject]@{ applicable = $false; reason = ('campaign-not-applicable:pre-implement-stage ({0})' -f $cursorNorm) }
            }
        }
    }

    # DRIFT-199-I001-006 (FR-007/FR-008; T003 landing early under the maintainer's 2026-08-10
    # in-scope ruling). The cursor rule above states the premise for going live: "there is
    # implementation to review". At the before-implement edge that premise can be FALSE - the
    # cursor has advanced but the coverage delta still holds only planning records. The consumer
    # then meets a review-required block for the PLANNING digest that no disposition can decline,
    # because every --remediate choice binds to a run id and no run exists. Align activation with
    # the premise the rule already states: quiet while nothing reviewable has been implemented.
    # This REMOVES NO GATE - the surface goes live the moment implementation appears, and every
    # unresolvable input fails CLOSED (applicable), so a broken anchor can never quiet the block.
    $implementation = Test-ReviewCampaignCoverageDeltaHasImplementation -RepoRoot $RepoRoot
    if (-not $implementation.has_implementation) {
        return [pscustomobject]@{ applicable = $false; reason = ('campaign-not-applicable:no-implementation-yet ({0})' -f $implementation.reason) }
    }
    return [pscustomobject]@{ applicable = $true; reason = 'campaign-applicable' }
}

function Test-ReviewCampaignCoverageDeltaHasImplementation {
    # Does the coverage delta (merge-base anchor -> HEAD, plus the working tree) contain anything
    # a reviewer would review as IMPLEMENTATION? Non-implementation is exactly two classes: the
    # methodology machinery (the ONE FR-012 resolver, so this can never drift from the digest and
    # worktree strips) and the lifecycle records tree `specs/`. Everything else - source, tests,
    # docs, CI - counts as implementation.
    #
    # FAIL CLOSED in every uncertain case: an unresolvable trunk/anchor, an unavailable machinery
    # resolver, or a failing git call all return has_implementation = $true, which keeps the
    # campaign surface LIVE. The quiet answer is only ever returned from a fully resolved delta.
    param([Parameter(Mandatory)][string]$RepoRoot)

    $mk = { param($has, $reason) [pscustomobject]@{ has_implementation = [bool]$has; reason = [string]$reason } }

    if (-not (Get-Command -Name 'Get-ContinuousCoReviewMachineryPaths' -ErrorAction SilentlyContinue)) {
        $reviewerModule = Join-Path $PSScriptRoot 'worktree-reviewer.ps1'
        if (Test-Path -LiteralPath $reviewerModule -PathType Leaf) { try { . $reviewerModule } catch { $null = $_ } }
    }
    if (-not (Get-Command -Name 'Get-ContinuousCoReviewMachineryPaths' -ErrorAction SilentlyContinue)) {
        return & $mk $true 'machinery-resolver-unavailable'
    }

    $anchor = $null
    try { $anchor = Get-ContinuousCoReviewMergeBaseAnchor -RepoRoot $RepoRoot -TrunkName '' } catch { $anchor = $null }
    if ([string]::IsNullOrWhiteSpace($anchor)) { return & $mk $true 'coverage-anchor-unresolved' }

    $changed = New-Object System.Collections.Generic.List[string]
    $committed = @(& git -C $RepoRoot diff --name-only ($anchor + '..HEAD') 2>$null)
    if ($LASTEXITCODE -ne 0) { return & $mk $true 'coverage-delta-unreadable' }
    foreach ($path in $committed) { if (-not [string]::IsNullOrWhiteSpace($path)) { $changed.Add([string]$path) } }

    # The working tree counts too: uncommitted implementation must keep the surface live.
    $porcelain = @(& git -C $RepoRoot status --porcelain 2>$null)
    if ($LASTEXITCODE -ne 0) { return & $mk $true 'working-tree-unreadable' }
    foreach ($entry in $porcelain) {
        if ([string]::IsNullOrWhiteSpace($entry) -or $entry.Length -le 3) { continue }
        $path = $entry.Substring(3).Trim().Trim('"')
        # Rename entries read `old -> new`; the destination is the reviewable path.
        $arrow = $path.IndexOf(' -> ', [StringComparison]::Ordinal)
        if ($arrow -ge 0) { $path = $path.Substring($arrow + 4).Trim().Trim('"') }
        if (-not [string]::IsNullOrWhiteSpace($path)) { $changed.Add($path) }
    }

    $machinery = @()
    try {
        foreach ($m in @(Get-ContinuousCoReviewMachineryPaths -RepoRoot $RepoRoot)) {
            if ([string]::IsNullOrWhiteSpace($m)) { continue }
            $machinery += (([string]$m -replace '\\', '/').Trim('/'))
        }
    }
    catch { return & $mk $true 'machinery-resolver-failed' }
    # The lifecycle records tree is not machinery (a reviewer DOES read it) but it is not
    # implementation either - it is the planning digest this alignment exists to stop demanding.
    $recordsRoots = @($machinery) + @('specs')

    # Round-1 review finding (major), and the beta2 certify-round-3 path-identity class recurring:
    # a hardcoded case rule here is silently unsafe. On a case-SENSITIVE volume `Specs/` is a
    # DIFFERENT directory from `specs/` - genuinely reviewable content - and folding the case
    # classified it as records-only, which quiets the campaign surface and skips the review
    # entirely. The case rule belongs to the ONE volume-derived source (path-identity.ps1); this
    # predicate asks it rather than deciding for itself. -WhenUndetermined 'distinct' keeps the
    # fail-closed direction: an undetermined volume treats the spellings as different, so the
    # surface stays LIVE rather than going quiet on an assumption.
    $pathComparison = Get-ContinuousCoReviewPathComparison -Path $RepoRoot -WhenUndetermined 'distinct'

    foreach ($raw in $changed) {
        $path = ([string]$raw -replace '\\', '/').Trim().Trim('/')
        if ([string]::IsNullOrWhiteSpace($path)) { continue }
        $isRecords = $false
        foreach ($root in $recordsRoots) {
            if ([string]::IsNullOrWhiteSpace($root)) { continue }
            if ($path.Equals($root, $pathComparison) -or
                $path.StartsWith(($root + '/'), $pathComparison)) {
                $isRecords = $true
                break
            }
        }
        if (-not $isRecords) { return & $mk $true ('implementation-present:' + $path) }
    }

    return & $mk $false 'coverage-delta-is-records-only'
}

function Get-ReviewCampaignRecordedPendingCrossing {
    # Controller truth: the crossing the lifecycle is currently waiting on, read from
    # .specrew/start-context.json. Returns $null when there is none, when the file is unreadable, or
    # when the record does not name a destination - all three are "no crossing to defer to", and the
    # campaign block keeps its unconditional no-marker clause. Fail-closed direction: only a crossing
    # that genuinely exists may relax that clause.
    [CmdletBinding()]
    param([Parameter(Mandatory)][string]$RepoRoot)

    $startContextPath = Join-Path $RepoRoot '.specrew/start-context.json'
    if (-not (Test-Path -LiteralPath $startContextPath -PathType Leaf)) { return $null }
    try { $startContext = Get-Content -LiteralPath $startContextPath -Raw -Encoding UTF8 | ConvertFrom-Json }
    catch { return $null }
    if ($null -eq $startContext) { return $null }
    $enforcement = $startContext.PSObject.Properties['boundary_enforcement']
    if ($null -eq $enforcement -or $null -eq $enforcement.Value) { return $null }
    $crossing = $enforcement.Value.PSObject.Properties['pending_crossing']
    if ($null -eq $crossing -or $null -eq $crossing.Value) { return $null }
    return $crossing.Value
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
        else {
            # T003 / FR-007: hand the block the recorded crossing so it can scope itself instead of
            # blanket-suppressing a marker the lifecycle may genuinely owe. Reading controller truth
            # must never be able to break the stop, so an unreadable record yields $null and the block
            # falls back to its original unconditional clause.
            $pendingCrossing = $null
            try { $pendingCrossing = Get-ReviewCampaignRecordedPendingCrossing -RepoRoot $resolved }
            catch { $pendingCrossing = $null }
            $decision.stop_block = Build-ReviewCampaignNavigatorStopBlock -PacketDecision $packet -PendingCrossing $pendingCrossing
            # T010 (emission-point rule): the agent's directives travel BESIDE the human's block, never
            # inside it. MOVED, not deleted - the agent is a different reader, not a lesser one, and it
            # still has to be told whether a verdict marker applies.
            $decision | Add-Member -NotePropertyName agent_directives `
                -NotePropertyValue (Build-ReviewCampaignNavigatorAgentDirective -PacketDecision $packet -PendingCrossing $pendingCrossing) -Force
        }
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
