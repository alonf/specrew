$ErrorActionPreference = 'Stop'
Set-StrictMode -Version Latest

# iter-008 cutover: the worktree engine is the one method; the diff-cramming first cut is deleted. These are the
# SHARED leaf-modules the live mechanisms still need (the reap chain, the signoff gate, host-selection/auth, the
# contract helpers, and the diff-provider's Invoke-...Git wrapper used by the dedup). Verified by AST call-graph
# from the live entry points (worktree navigator + service + detached + signoff gate + host-auth).
$proposal197ReviewerModules = @(
    # The ONE shared trunk resolver (6-level precedence) - loaded FIRST so the anchor writer, signoff gate,
    # baseline resolver, and lineage resolver all consume it instead of duplicating 'main' defaults.
    'co-review-trunk-resolver.ps1'
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
    # T019 step 6: the review-identity contracts + the per-lineage lease runtime are now WIRED (were unwired
    # characterization). Pure/self-contained; consumed by the navigator reap (authority) + the fire path (lease).
    'review-identity-contracts.ps1'
    'co-review-lineage-lease.ps1'
    # T019 step 6 / FR-048: the framework-neutral verification-plan seam - the PURE plan contract (validators +
    # the evidence-join) and the EXECUTION runner that drives the universal recorded-run runner over an ordered,
    # provenance-tagged plan. Contract before runner (the runner consumes it).
    'verification-plan-contract.ps1'
    'verification-plan-runner.ps1'
)

foreach ($moduleName in $proposal197ReviewerModules) {
    $modulePath = Join-Path $PSScriptRoot $moduleName
    if (-not (Test-Path -LiteralPath $modulePath -PathType Leaf)) {
        continue
    }

    . $modulePath
}
