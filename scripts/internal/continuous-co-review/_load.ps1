$ErrorActionPreference = 'Stop'
Set-StrictMode -Version Latest

# iter-008 cutover: the worktree engine is the one method; the diff-cramming first cut is deleted. These are the
# SHARED leaf-modules the live mechanisms still need (the reap chain, the signoff gate, host-selection/auth, the
# contract helpers, and the diff-provider's Invoke-...Git wrapper used by the dedup). Verified by AST call-graph
# from the live entry points (worktree navigator + service + detached + signoff gate + host-auth).
$proposal197ReviewerModules = @(
    # F-198 iter-006 / T041: ONE fail-closed terminal-authority cutover seam. It is loaded first so
    # every legacy/new consumer gets the same mutually-exclusive decision.
    'review-authority-cutover.ps1'
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
    # F-198 iter-005 / T035 (FR-050): the truthful host+surface support-tier model + doctor/status renderer.
    # Pure/self-contained (no cross-module deps); the ONE place a host+surface support CLAIM is recorded.
    'host-support-tier.ps1'
    # F-198 iter-005 / T038 (FR-053) + T036 preflight (FR-051): sanitized hook-health receipts (missing is never
    # healthy) + the Codex untrusted-headless governance preflight (read-only; never mutates ~/.codex). Self-contained.
    'hook-health-receipt.ps1'
    # F-198 iter-005 / T039 (FR-050 + FR-053 + FR-051): the doctor/status AGGREGATOR - one call renders the
    # host-support tiers + hook-health evidence + the Codex headless preflight. Loaded AFTER its two siblings
    # above (it also self-loads them fail-open so it stays drop-in for the protected doctor surface).
    'host-support-doctor.ps1'
    'review-blackboard-writer.ps1'
    'inline-review-gate-evaluator.ps1'
    'review-run-index-writer.ps1'
    'tracker-honesty-check.ps1'
    'review-signoff-evidence-gate.ps1'
    'escalation-latch.ps1'
    # T019 step 6: the review-identity contracts + the per-lineage lease runtime are now WIRED (were unwired
    # characterization). Pure/self-contained; consumed by the navigator reap (authority) + the fire path (lease).
    'review-identity-contracts.ps1'
    # F-198 iter-006 / T042-T044: closed review contracts + pure campaign/run authority decisions.
    'review-authority-core.ps1'
    # F-198 iter-006 / T045: immutable JSON campaign/run/claim repositories + reconciliation.
    'review-authority-store.ps1'
    # F-198 iter-006 / T046: production external-Git target + thin target-neutral fixture.
    'review-target-port.ps1'
    # F-198 iter-006 / T047: strict candidate ingress + controller-owned JSON/Markdown publication.
    'review-result-ingestor.ps1'
    # F-198 iter-006 / T048: synchronous port-composed campaign/run orchestration + fixtures.
    'review-campaign-orchestrator.ps1'
    # Shared file-primary production harness contract, followed by thin provider adapters.
    'review-harness-contract.ps1'
    'review-claude-harness-port.ps1'
    'review-codex-harness-port.ps1'
    'review-copilot-harness-port.ps1'
    'review-cursor-harness-port.ps1'
    'review-antigravity-harness-port.ps1'
    'review-runtime-contract.ps1'
    'review-windows-runtime-port.ps1'
    'review-posix-runtime-common.ps1'
    'review-linux-runtime-port.ps1'
    'review-macos-runtime-port.ps1'
    'review-runtime-factory.ps1'
    # T019 piece 4b / FR-045a: the PURE Stop-intent classifier (intermediate operational yield vs a real handoff).
    'stop-intent-contract.ps1'
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
