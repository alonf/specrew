$ErrorActionPreference = 'Stop'
Set-StrictMode -Version Latest

$proposal197ReviewerModules = @(
    'reviewer-contracts.ps1'
    'review-visibility-policy-builder.ps1'
    'design-context-collector.ps1'
    'checkpoint-diff-provider.ps1'
    'review-request-builder.ps1'
    'review-run-workspace-manager.ps1'
    'review-result-normalizer.ps1'
    'reviewer-host-adapter-fixture.ps1'
    'review-blackboard-writer.ps1'
    'inline-review-gate-evaluator.ps1'
    'review-run-index-writer.ps1'
)

foreach ($moduleName in $proposal197ReviewerModules) {
    $modulePath = Join-Path $PSScriptRoot $moduleName
    if (-not (Test-Path -LiteralPath $modulePath -PathType Leaf)) {
        continue
    }

    . $modulePath
}
