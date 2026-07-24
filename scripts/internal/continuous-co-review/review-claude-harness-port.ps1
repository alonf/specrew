$ErrorActionPreference = 'Stop'
Set-StrictMode -Version Latest

# Claude's thin adapter supplies only its cataloged command vector. The shared harness contract owns
# prompt rendering, candidate-path validation, stdout non-authority, and process-spec construction.
if (-not (Get-Command -Name 'New-ReviewFilePrimaryHarnessPort' -ErrorAction SilentlyContinue)) {
    . (Join-Path $PSScriptRoot 'review-harness-contract.ps1')
}

function Test-ReviewClaudeFilePrimaryPromptTemplate {
    [CmdletBinding()]
    param([Parameter(Mandatory)][string]$Template)

    return Test-ReviewFilePrimaryPromptTemplate -Template $Template
}

function New-ReviewClaudeFilePrimaryHarnessPort {
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
    $definition = Get-ContinuousCoReviewProductionHarnessDefinition -HostName claude
    if ($null -eq $definition) { throw 'claude-file-primary-catalog-definition-missing' }
    return New-ReviewFilePrimaryHarnessPort -HarnessId $definition.harness_id -HostName $definition.host `
        -CommandName $definition.command -PreArguments $definition.pre_arguments -PromptTransport $definition.prompt_transport `
        -PromptTemplatePath $PromptTemplatePath -TimeoutSeconds $TimeoutSeconds -AgentInvoker $AgentInvoker -AvailabilityProbe $AvailabilityProbe
}
