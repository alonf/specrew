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
        [string]$TrunkName = 'main',
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

    # FAST identity + dedup (reuse the state). No heavy digest.
    $treeId = Get-ContinuousCoReviewWorktreeIdentity -RepoRoot $resolved
    if ([string]::IsNullOrWhiteSpace($treeId)) { $decision.reason = 'identity-unresolved'; return $decision }
    $decision.fired_tree_id = $treeId
    if ($treeId -eq (Get-ContinuousCoReviewNavigatorLastFiredTreeId -RepoRoot $resolved)) { $decision.reason = 'deduped (already reviewed this tree)'; return $decision }

    # FIRE via the host-neutral service (detached; all heavy work off the Stop budget).
    try {
        $run = Start-ContinuousCoReviewServiceRun -RepoRoot $resolved -TreeId $treeId -CodeWriterHost $CodeWriterHost -TimeoutSeconds $TimeoutSeconds -Detached
        Set-ContinuousCoReviewNavigatorLastFiredTreeId -RepoRoot $resolved -TreeId $treeId -RunId $run.run_id
        $decision.action = 'fired'; $decision.reason = 'registered-checkpoint'; $decision.fired_run_id = $run.run_id
    }
    catch {
        $decision.reason = ('fire-failed: ' + $_.Exception.Message)
    }
    return $decision
}
