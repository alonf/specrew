$ErrorActionPreference = 'Stop'
Set-StrictMode -Version Latest

$proposal197ReviewerModules = @(
    'reviewer-contracts.ps1'
    'review-visibility-policy-builder.ps1'
    'design-context-collector.ps1'
    'checkpoint-diff-provider.ps1'
    'reviewed-state-digest.ps1'
    'review-request-builder.ps1'
    'review-prompt-composer.ps1'
    'host-agent-mirror.ps1'
    'review-run-workspace-manager.ps1'
    'review-result-normalizer.ps1'
    'reviewer-host-catalog.ps1'
    'reviewer-authorization-sync.ps1'
    'reviewer-host-presentation.ps1'
    'reviewer-model-capability.ps1'
    'reviewer-authorization-gate.ps1'
    'reviewer-selection-policy.ps1'
    'reviewer-host-adapter-registry.ps1'
    'workspace-mutation-guard.ps1'
    'reviewer-host-adapter-fixture.ps1'
    'reviewer-host-adapter-claude-prompt.ps1'
    'reviewer-host-adapter-codex-exec.ps1'
    'reviewer-host-adapter-copilot-prompt.ps1'
    'reviewer-host-adapter-cursor-agent-prompt.ps1'
    'reviewer-host-adapter-antigravity-prompt.ps1'
    'reviewer-execution-engine.ps1'
    'review-blackboard-writer.ps1'
    'inline-review-gate-evaluator.ps1'
    'review-run-index-writer.ps1'
    'review-signoff-evidence-gate.ps1'
    'gate-review-registry.ps1'
    'gate-review-dispatcher.ps1'
    'checkpoint-review-orchestrator.ps1'
)

foreach ($moduleName in $proposal197ReviewerModules) {
    $modulePath = Join-Path $PSScriptRoot $moduleName
    if (-not (Test-Path -LiteralPath $modulePath -PathType Leaf)) {
        continue
    }

    . $modulePath
}
