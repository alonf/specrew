$ErrorActionPreference = 'Stop'
Set-StrictMode -Version Latest

# iter-008 cutover: the worktree engine is the one method; the diff-cramming first cut is deleted. These are the
# SHARED leaf-modules the live mechanisms still need (the reap chain, the signoff gate, host-selection/auth, the
# contract helpers, and the diff-provider's Invoke-...Git wrapper used by the dedup). Verified by AST call-graph
# from the live entry points (worktree navigator + service + detached + signoff gate + host-auth).
$proposal197ReviewerModules = @(
    'reviewer-contracts.ps1'
    'checkpoint-diff-provider.ps1'
    'reviewed-state-digest.ps1'
    'test-evidence-recorder.ps1'
    'reviewer-host-catalog.ps1'
    'reviewer-authorization-gate.ps1'
    'reviewer-selection-policy.ps1'
    'reviewer-host-presentation.ps1'
    'review-blackboard-writer.ps1'
    'inline-review-gate-evaluator.ps1'
    'review-run-index-writer.ps1'
    'tracker-honesty-check.ps1'
    'review-signoff-evidence-gate.ps1'
    'escalation-latch.ps1'
)

foreach ($moduleName in $proposal197ReviewerModules) {
    $modulePath = Join-Path $PSScriptRoot $moduleName
    if (-not (Test-Path -LiteralPath $modulePath -PathType Leaf)) {
        continue
    }

    . $modulePath
}
