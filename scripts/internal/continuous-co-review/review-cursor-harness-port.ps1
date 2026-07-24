$ErrorActionPreference = 'Stop'
Set-StrictMode -Version Latest

# Cursor contributes only its checked-in headless command vector. The shared harness contract owns
# authority, bounds, rendering, preflight, environment minimization, and candidate-file behavior.
if (-not (Get-Command -Name 'New-ReviewFilePrimaryHarnessPort' -ErrorAction SilentlyContinue)) {
    . (Join-Path $PSScriptRoot 'review-harness-contract.ps1')
}

function New-ReviewCursorAgentFilePrimaryHarnessPort {
    [CmdletBinding()]
    param(
        [string]$PromptTemplatePath,
        [ValidateRange(1, 7200)][int]$TimeoutSeconds = 600,
        [ValidatePattern('^[a-z0-9][a-z0-9.-]{0,127}$')][string]$Model,
        [scriptblock]$AgentInvoker,
        [scriptblock]$AvailabilityProbe
    )

    if ([string]::IsNullOrWhiteSpace($PromptTemplatePath)) {
        $PromptTemplatePath = Join-Path $PSScriptRoot 'reviewer-candidate-prompt.md'
    }
    $definition = Get-ContinuousCoReviewProductionHarnessDefinition -HostName cursor-agent
    if ($null -eq $definition) { throw 'cursor-file-primary-catalog-definition-missing' }
    $preArguments = @($definition.pre_arguments)
    $configuredModel = 'configured-by-user'
    if (-not [string]::IsNullOrWhiteSpace($Model)) {
        $preArguments += @('--model', $Model)
        $configuredModel = $Model
    }
    return New-ReviewFilePrimaryHarnessPort -HarnessId $definition.harness_id -HostName $definition.host `
        -CommandName $definition.command -PreArguments $preArguments -PromptTransport $definition.prompt_transport `
        -PromptTemplatePath $PromptTemplatePath -TimeoutSeconds $TimeoutSeconds -ConfiguredModel $configuredModel `
        -AgentInvoker $AgentInvoker -AvailabilityProbe $AvailabilityProbe
}
