$ErrorActionPreference = 'Stop'
Set-StrictMode -Version Latest

if (-not (Get-Command -Name 'Get-ContinuousCoReviewProductionHarnessDefinition' -ErrorAction SilentlyContinue)) {
    . (Join-Path $PSScriptRoot 'reviewer-host-catalog.ps1')
}

# Shared synchronous process/file contract for production review harnesses. Reviewers write one bounded
# candidate JSON object to the controller-owned path. Stdout may be observed as transient activity, but it
# is never parsed, extracted, or copied into candidate authority.

function Get-ReviewHarnessContractLimits {
    return [pscustomobject][ordered]@{
        schema_version = '1.0'
        max_prompt_template_bytes = 32768
        max_rendered_prompt_bytes = 65536
        max_candidate_bytes = 262144
    }
}

function Test-ReviewFilePrimaryPromptTemplate {
    [CmdletBinding()]
    param([Parameter(Mandatory)][AllowEmptyString()][string]$Template)

    $limits = Get-ReviewHarnessContractLimits
    $errors = [Collections.Generic.List[string]]::new()
    $bytes = [Text.Encoding]::UTF8.GetByteCount($Template)
    if ($bytes -gt $limits.max_prompt_template_bytes) { $errors.Add("prompt-template-too-large:$($limits.max_prompt_template_bytes)") | Out-Null }

    $required = @('__RUN_ID__', '__TARGET_DIGEST__', '__CANDIDATE_RESULT_PATH__', '__REVIEW_SCOPE__', '__DEADLINE__')
    foreach ($placeholder in $required) {
        $count = ([regex]::Matches($Template, [regex]::Escape($placeholder))).Count
        if ($count -ne 1) { $errors.Add(('prompt-placeholder-count:{0}:{1}' -f $placeholder, $count)) | Out-Null }
    }
    foreach ($match in [regex]::Matches($Template, '__[A-Z0-9_]+__')) {
        if ([string]$match.Value -cnotin $required) { $errors.Add(('prompt-placeholder-unknown:' + [string]$match.Value)) | Out-Null }
    }
    foreach ($rule in @(
        @{ name = 'raw-json-only'; pattern = '(?is)ONLY\s+the\s+raw\s+JSON\s+object' },
        @{ name = 'no-prose'; pattern = '(?is)no\s+prose' },
        @{ name = 'no-fences'; pattern = '(?is)no\s+Markdown\s+fences' },
        @{ name = 'stdout-non-authority'; pattern = '(?is)stdout.+never\s+parsed\s+for\s+authority' },
        @{ name = 'source-read-only'; pattern = '(?is)do\s+not\s+modify\s+the\s+source' },
        @{ name = 'single-reviewer-session'; pattern = '(?is)do\s+not\s+delegate\s+to\s+subagents\s+or\s+start\s+other\s+model-backed\s+reviewers' },
        @{ name = 'location-string-type'; pattern = '(?is)`?location`?.+when\s+present.+plain\s+JSON\s+string.+never\s+an\s+object.+array.+number.+boolean' }
    )) {
        if ($Template -notmatch $rule.pattern) { $errors.Add(('prompt-contract-missing:' + $rule.name)) | Out-Null }
    }
    return [pscustomobject]@{ valid = ($errors.Count -eq 0); errors = @($errors); byte_count = $bytes }
}

function Render-ReviewFilePrimaryPrompt {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)][string]$Template,
        [Parameter(Mandatory)]$Invocation
    )
    $validation = Test-ReviewFilePrimaryPromptTemplate -Template $Template
    if (-not $validation.valid) { throw ('review-file-primary-prompt-invalid:' + ($validation.errors -join ',')) }
    $values = @{
        '__RUN_ID__' = [string]$Invocation.run_id
        '__TARGET_DIGEST__' = [string]$Invocation.target_digest
        '__CANDIDATE_RESULT_PATH__' = [IO.Path]::GetFullPath([string]$Invocation.candidate_result_path)
        '__REVIEW_SCOPE__' = [string]$Invocation.review_scope
        '__DEADLINE__' = [string]$Invocation.deadline
    }
    $rendered = [regex]::Replace($Template, '__[A-Z0-9_]+__', [Text.RegularExpressions.MatchEvaluator]{
        param($match)
        return [string]$values[[string]$match.Value]
    })
    $limits = Get-ReviewHarnessContractLimits
    $bytes = [Text.Encoding]::UTF8.GetByteCount($rendered)
    if ($bytes -gt $limits.max_rendered_prompt_bytes) { throw "review-file-primary-rendered-prompt-too-large:$($limits.max_rendered_prompt_bytes)" }
    return $rendered
}

function New-ReviewHarnessProcessSpec {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)][string]$HarnessId,
        [Parameter(Mandatory)][string]$CommandName,
        [string[]]$PreArguments = @(),
        [Parameter(Mandatory)][ValidateSet('stdin', 'argument')][string]$PromptTransport,
        [Parameter(Mandatory)][string]$Prompt,
        [Parameter(Mandatory)]$Invocation,
        [AllowNull()]$Environment,
        [ValidateRange(1, 7200)][int]$TimeoutSeconds
    )
    $arguments = [Collections.Generic.List[string]]::new()
    foreach ($argument in @($PreArguments)) { $arguments.Add([string]$argument) | Out-Null }
    $stdin = $null
    if ($PromptTransport -ceq 'stdin') { $stdin = $Prompt }
    else { $arguments.Add($Prompt) | Out-Null }

    $environmentDelta = [ordered]@{}
    if ($null -ne $Environment) {
        foreach ($name in @('SPECREW_REFOCUS_DISABLE', 'SPECREW_DISABLE_EVENTS')) {
            if (($Environment -is [Collections.IDictionary]) -and $Environment.Contains($name)) { $environmentDelta[$name] = [string]$Environment[$name] }
            elseif ($Environment.PSObject.Properties[$name]) { $environmentDelta[$name] = [string]$Environment.$name }
        }
    }
    return [pscustomobject][ordered]@{
        schema_version = '1.0'; harness_id = $HarnessId; command = $CommandName; argument_list = @($arguments)
        prompt_transport = $PromptTransport; stdin_text = $stdin; working_directory = [IO.Path]::GetFullPath([string]$Invocation.snapshot_path)
        environment_delta = $environmentDelta; candidate_result_path = [IO.Path]::GetFullPath([string]$Invocation.candidate_result_path)
        deadline = [string]$Invocation.deadline; timeout_seconds = $TimeoutSeconds; result_transport = 'file-primary'; stdout_authority = $false
    }
}

function New-ReviewFilePrimaryHarnessPort {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)][string]$HarnessId,
        [Parameter(Mandatory)][string]$HostName,
        [Parameter(Mandatory)][string]$CommandName,
        [string[]]$PreArguments = @(),
        [Parameter(Mandatory)][ValidateSet('stdin', 'argument')][string]$PromptTransport,
        [Parameter(Mandatory)][string]$PromptTemplatePath,
        [ValidateRange(1, 7200)][int]$TimeoutSeconds,
        [string]$ConfiguredModel = 'configured-by-user',
        [scriptblock]$AgentInvoker,
        [scriptblock]$AvailabilityProbe
    )
    $promptPath = [IO.Path]::GetFullPath($PromptTemplatePath)
    if (-not [IO.File]::Exists($promptPath)) { throw "review-file-primary-prompt-missing:$promptPath" }
    $template = [IO.File]::ReadAllText($promptPath, [Text.UTF8Encoding]::new($false, $true))
    $templateValidation = Test-ReviewFilePrimaryPromptTemplate -Template $template
    if (-not $templateValidation.valid) { throw ('review-file-primary-prompt-invalid:' + ($templateValidation.errors -join ',')) }

    if (-not $AvailabilityProbe) { $AvailabilityProbe = { $null -ne (Get-Command -Name $CommandName -CommandType Application -ErrorAction SilentlyContinue) }.GetNewClosure() }
    if (-not $AgentInvoker) {
        $legacy = Get-Command -Name 'Invoke-ContinuousCoReviewAgentInWorktree' -CommandType Function -ErrorAction SilentlyContinue
        if ($null -ne $legacy) {
            $AgentInvoker = {
                param($worktreePath, $prompt, $timeout)
                & $legacy -WorktreePath $worktreePath -Prompt $prompt -HostName $HostName -TimeoutSeconds $timeout
            }.GetNewClosure()
        }
    }

    $renderPromptCommand = ${function:Render-ReviewFilePrimaryPrompt}
    $newProcessSpecCommand = ${function:New-ReviewHarnessProcessSpec}

    $preflight = {
        param($invocation)
        try {
            $candidate = [IO.Path]::GetFullPath([string]$invocation.candidate_result_path)
            $report = [IO.Path]::GetFullPath([string]$invocation.candidate_report_path)
            $sameParent = [IO.Path]::GetDirectoryName($candidate) -ceq [IO.Path]::GetDirectoryName($report)
            $deadline = [DateTimeOffset]::MinValue
            $deadlineValid = [DateTimeOffset]::TryParse([string]$invocation.deadline, [ref]$deadline)
            $contractValid = $true
            if (Get-Command -Name 'Test-ReviewAuthorityContractObject' -ErrorAction SilentlyContinue) {
                $contractValid = [bool](Test-ReviewAuthorityContractObject -ContractName ReviewInvocation -InputObject $invocation -ExpectedCampaignId ([string]$invocation.campaign_id) -ExpectedRunId ([string]$invocation.run_id) -ExpectedTargetDigest ([string]$invocation.target_digest)).valid
            }
            $available = [bool](& $AvailabilityProbe)
            $reason = if (-not $available) { "$HostName-unavailable" }
            elseif (-not $contractValid) { 'invocation-contract-invalid' }
            elseif (-not [IO.Directory]::Exists([string]$invocation.snapshot_path)) { 'snapshot-missing' }
            elseif (-not $sameParent -or [IO.Path]::GetFileName($candidate) -cne 'candidate.json' -or [IO.Path]::GetFileName($report) -cne 'candidate.md') { 'candidate-path-contract-invalid' }
            elseif (-not [IO.Directory]::Exists([IO.Path]::GetDirectoryName($candidate))) { 'candidate-parent-missing' }
            elseif ([IO.File]::Exists($candidate)) { 'candidate-path-preexists' }
            elseif (-not $deadlineValid) { 'deadline-invalid' }
            else { "$HostName-file-primary-ready" }
            return [pscustomobject]@{ ok = ($reason -ceq "$HostName-file-primary-ready"); reason = $reason }
        }
        catch { return [pscustomobject]@{ ok = $false; reason = ('harness-preflight-failed:' + $_.Exception.Message) } }
    }.GetNewClosure()

    $buildProcess = {
        param($invocation, $environment)
        $candidate = [IO.Path]::GetFullPath([string]$invocation.candidate_result_path)
        if ([IO.File]::Exists($candidate)) { throw "review-file-primary-candidate-preexists:$candidate" }
        $prompt = & $renderPromptCommand -Template $template -Invocation $invocation
        return & $newProcessSpecCommand -HarnessId $HarnessId -CommandName $CommandName -PreArguments $PreArguments -PromptTransport $PromptTransport -Prompt $prompt -Invocation $invocation -Environment $environment -TimeoutSeconds $TimeoutSeconds
    }.GetNewClosure()

    $invoke = {
        param($invocation, $environment)
        if (-not $AgentInvoker) { throw "review-harness-runtime-process-contract-required:$HarnessId" }
        $spec = & $buildProcess $invocation $environment
        $prompt = if ($spec.prompt_transport -ceq 'stdin') { [string]$spec.stdin_text } else { [string]$spec.argument_list[-1] }
        $agent = & $AgentInvoker ([string]$invocation.snapshot_path) $prompt $TimeoutSeconds
        $candidate = [IO.Path]::GetFullPath([string]$invocation.candidate_result_path)
        $produced = [IO.File]::Exists($candidate) -and ([IO.FileInfo]$candidate).Length -gt 0
        return [pscustomobject]@{ agent = $agent; output_activity = $produced; result_source = 'file-primary'; stdout_authority = $false }
    }.GetNewClosure()

    return [pscustomobject]@{
        id = $HarnessId; host = $HostName; configured_model = $ConfiguredModel
        contract_version = '1.0'; result_transport = 'file-primary'; stdout_authority = $false
        preflight = $preflight; build_process = $buildProcess; invoke = $invoke
    }
}

function New-ReviewUnavailableProductionHarnessPort {
    param([string]$HarnessId, [string]$HostName, [string]$Reason)
    $preflight = { param($invocation) [pscustomobject]@{ ok = $false; reason = $Reason } }.GetNewClosure()
    $build = { param($invocation, $environment) throw $Reason }.GetNewClosure()
    $invoke = { param($invocation, $environment) throw $Reason }.GetNewClosure()
    return [pscustomobject]@{ id = $HarnessId; host = $HostName; contract_version = '1.0'; result_transport = 'file-primary'; stdout_authority = $false; preflight = $preflight; build_process = $build; invoke = $invoke }
}

function New-ReviewProductionHarnessPort {
    [CmdletBinding()]
    param(
        [string]$HostName,
        [ValidateRange(1, 7200)][int]$TimeoutSeconds = 900,
        [string]$PromptTemplatePath,
        [string]$Model
    )
    if ([string]::IsNullOrWhiteSpace($HostName)) { return New-ReviewUnavailableProductionHarnessPort -HarnessId 'unselected-harness' -HostName '' -Reason 'reviewer-host-required' }
    $normalizedHost = $HostName.ToLowerInvariant()
    $definition = Get-ContinuousCoReviewProductionHarnessDefinition -HostName $normalizedHost
    if ($null -eq $definition) {
        return New-ReviewUnavailableProductionHarnessPort -HarnessId $normalizedHost -HostName $normalizedHost -Reason "production-harness-not-cataloged:$normalizedHost"
    }
    $constructorName = [string]$definition.constructor
    if ($constructorName -cnotmatch '^New-Review[A-Za-z0-9]+FilePrimaryHarnessPort$') {
        return New-ReviewUnavailableProductionHarnessPort -HarnessId ([string]$definition.harness_id) -HostName $normalizedHost -Reason "production-harness-constructor-invalid:$normalizedHost"
    }
    $constructor = Get-Command -Name $constructorName -CommandType Function -ErrorAction SilentlyContinue
    if ($null -eq $constructor) {
        return New-ReviewUnavailableProductionHarnessPort -HarnessId ([string]$definition.harness_id) -HostName $normalizedHost -Reason "production-harness-not-implemented:$normalizedHost"
    }
    $parameters = @{ TimeoutSeconds = $TimeoutSeconds }
    if (-not [string]::IsNullOrWhiteSpace($PromptTemplatePath)) { $parameters.PromptTemplatePath = $PromptTemplatePath }
    if (-not [string]::IsNullOrWhiteSpace($Model)) {
        if (-not $constructor.Parameters.ContainsKey('Model')) {
            return New-ReviewUnavailableProductionHarnessPort -HarnessId ([string]$definition.harness_id) -HostName $normalizedHost -Reason "production-harness-model-override-unsupported:$normalizedHost"
        }
        $parameters.Model = $Model
    }
    return & $constructor @parameters
}
