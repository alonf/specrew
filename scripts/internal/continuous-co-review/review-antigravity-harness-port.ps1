$ErrorActionPreference = 'Stop'
Set-StrictMode -Version Latest

# Antigravity contributes only its checked-in, order-sensitive headless command vector. The shared
# harness contract owns authority, bounds, rendering, preflight, environment, and candidate behavior.
if (-not (Get-Command -Name 'New-ReviewFilePrimaryHarnessPort' -ErrorAction SilentlyContinue)) {
    . (Join-Path $PSScriptRoot 'review-harness-contract.ps1')
}

function New-ReviewAntigravityFilePrimaryHarnessPort {
    [CmdletBinding()]
    param(
        [string]$PromptTemplatePath,
        [ValidateRange(1, 7200)][int]$TimeoutSeconds = 900,
        [scriptblock]$AgentInvoker,
        [scriptblock]$AvailabilityProbe
    )

    if ([string]::IsNullOrWhiteSpace($PromptTemplatePath)) {
        $PromptTemplatePath = Join-Path $PSScriptRoot 'reviewer-candidate-prompt.md'
    }
    $definition = Get-ContinuousCoReviewProductionHarnessDefinition -HostName antigravity
    if ($null -eq $definition) { throw 'antigravity-file-primary-catalog-definition-missing' }
    return New-ReviewFilePrimaryHarnessPort -HarnessId $definition.harness_id -HostName $definition.host `
        -CommandName $definition.command -PreArguments $definition.pre_arguments -PromptTransport $definition.prompt_transport `
        -PromptTemplatePath $PromptTemplatePath -TimeoutSeconds $TimeoutSeconds -AgentInvoker $AgentInvoker -AvailabilityProbe $AvailabilityProbe
}
