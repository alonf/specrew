$ErrorActionPreference = 'Stop'
Set-StrictMode -Version Latest

# Codex contributes only its checked-in command vector. All authority, bounds, rendering, preflight,
# environment minimization, and candidate-file behavior remain in the shared harness contract.
if (-not (Get-Command -Name 'New-ReviewFilePrimaryHarnessPort' -ErrorAction SilentlyContinue)) {
    . (Join-Path $PSScriptRoot 'review-harness-contract.ps1')
}

function New-ReviewCodexFilePrimaryHarnessPort {
    [CmdletBinding()]
    param(
        [string]$PromptTemplatePath,
        [ValidateRange(1, 7200)][int]$TimeoutSeconds = 600,
        [scriptblock]$AgentInvoker,
        [scriptblock]$AvailabilityProbe
    )

    if ([string]::IsNullOrWhiteSpace($PromptTemplatePath)) {
        $PromptTemplatePath = Join-Path $PSScriptRoot 'reviewer-candidate-prompt.md'
    }
    $definition = Get-ContinuousCoReviewProductionHarnessDefinition -HostName codex
    if ($null -eq $definition) { throw 'codex-file-primary-catalog-definition-missing' }
    return New-ReviewFilePrimaryHarnessPort -HarnessId $definition.harness_id -HostName $definition.host `
        -CommandName $definition.command -PreArguments $definition.pre_arguments -PromptTransport $definition.prompt_transport `
        -PromptTemplatePath $PromptTemplatePath -TimeoutSeconds $TimeoutSeconds -AgentInvoker $AgentInvoker -AvailabilityProbe $AvailabilityProbe
}
