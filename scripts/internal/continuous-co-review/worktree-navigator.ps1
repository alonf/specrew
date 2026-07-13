$ErrorActionPreference = 'Stop'
Set-StrictMode -Version Latest

# iter-008 — the worktree-engine navigator: a FAST Stop-trigger. It REUSES the legacy navigator's reap +
# stage-gate + dedup-state (the survive-half) and the host-neutral co-review SERVICE for the fire
# (Start-ContinuousCoReviewServiceRun -Detached). It does NO heavy work on the Stop budget — identity is the fast
# HEAD-subtree tree-id and the materialize + review run in the detached orchestrator. The legacy navigator is
# UNTOUCHED; the provider selects this engine by config (co_review_engine=worktree). The legacy path is deleted at
# cutover (the tracked must-happen final step), so the two paths do not ossify.

. (Join-Path $PSScriptRoot 'co-review-service.ps1')   # brings the legacy navigator (reap/stage/dedup) + the service (fire/identity)

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
