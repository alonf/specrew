$ErrorActionPreference = 'Stop'
Set-StrictMode -Version Latest

# F-198 / T050 scoped Iteration-007 pull-forward: Claude delivers the campaign candidate through the
# controller-owned candidate_result_path. The file is the only authority channel; Claude stdout is
# transient process telemetry and is never copied, extracted, or parsed into candidate authority.

if (-not (Get-Command -Name 'Invoke-ContinuousCoReviewAgentInWorktree' -ErrorAction SilentlyContinue)) {
    . (Join-Path $PSScriptRoot 'worktree-reviewer.ps1')
}

function Test-ReviewClaudeFilePrimaryPromptTemplate {
    [CmdletBinding()]
    param([Parameter(Mandatory)][string]$Template)

    $errors = [System.Collections.Generic.List[string]]::new()
    foreach ($placeholder in @('__RUN_ID__', '__TARGET_DIGEST__', '__CANDIDATE_RESULT_PATH__')) {
        $count = ([regex]::Matches($Template, [regex]::Escape($placeholder))).Count
        if ($count -ne 1) { $errors.Add(('prompt-placeholder-count:{0}:{1}' -f $placeholder, $count)) | Out-Null }
    }
    return [pscustomobject]@{ valid = ($errors.Count -eq 0); errors = @($errors) }
}

function New-ReviewClaudeFilePrimaryHarnessPort {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)][string]$PromptTemplatePath,
        [ValidateRange(1, 7200)][int]$TimeoutSeconds = 600,
        [scriptblock]$AgentInvoker,
        [scriptblock]$AvailabilityProbe
    )

    $resolvedPromptPath = [IO.Path]::GetFullPath($PromptTemplatePath)
    if (-not [IO.File]::Exists($resolvedPromptPath)) { throw "claude-file-primary-prompt-missing:$resolvedPromptPath" }
    $template = [IO.File]::ReadAllText($resolvedPromptPath, [Text.Encoding]::UTF8)
    $templateValidation = Test-ReviewClaudeFilePrimaryPromptTemplate -Template $template
    if (-not $templateValidation.valid) {
        throw ('claude-file-primary-prompt-invalid:' + ($templateValidation.errors -join ','))
    }

    $invokeAgentCommand = Get-Command -Name 'Invoke-ContinuousCoReviewAgentInWorktree' -CommandType Function -ErrorAction SilentlyContinue
    if (-not $AgentInvoker) {
        $AgentInvoker = {
            param($worktreePath, $prompt, $timeout)
            & $invokeAgentCommand -WorktreePath $worktreePath -Prompt $prompt -HostName claude -TimeoutSeconds $timeout
        }.GetNewClosure()
    }
    if (-not $AvailabilityProbe) {
        $AvailabilityProbe = { $null -ne (Get-Command -Name claude -CommandType Application -ErrorAction SilentlyContinue) }
    }

    $preflight = {
        param($invocation)
        $candidatePath = [IO.Path]::GetFullPath([string]$invocation.candidate_result_path)
        $candidateParent = [IO.Path]::GetDirectoryName($candidatePath)
        $available = [bool](& $AvailabilityProbe)
        $ready = $available -and [IO.File]::Exists($resolvedPromptPath) -and [IO.Directory]::Exists($candidateParent) -and (-not [IO.File]::Exists($candidatePath))
        $reason = if (-not $available) { 'claude-unavailable' }
        elseif (-not [IO.File]::Exists($resolvedPromptPath)) { 'prompt-missing' }
        elseif (-not [IO.Directory]::Exists($candidateParent)) { 'candidate-parent-missing' }
        elseif ([IO.File]::Exists($candidatePath)) { 'candidate-path-preexists' }
        else { 'claude-file-primary-ready' }
        return [pscustomobject]@{ ok = $ready; reason = $reason }
    }.GetNewClosure()

    $invoke = {
        param($invocation, $environment)
        $candidatePath = [IO.Path]::GetFullPath([string]$invocation.candidate_result_path)
        if ([IO.File]::Exists($candidatePath)) { throw "claude-file-primary-candidate-preexists:$candidatePath" }
        $prompt = $template.
            Replace('__RUN_ID__', [string]$invocation.run_id).
            Replace('__TARGET_DIGEST__', [string]$invocation.target_digest).
            Replace('__CANDIDATE_RESULT_PATH__', $candidatePath)
        $agent = & $AgentInvoker ([string]$invocation.snapshot_path) $prompt $TimeoutSeconds
        $produced = [IO.File]::Exists($candidatePath) -and ([IO.FileInfo]$candidatePath).Length -gt 0
        return [pscustomobject]@{
            agent = $agent
            output_activity = $produced
            result_source = 'file-primary'
            stdout_authority = $false
        }
    }.GetNewClosure()

    return [pscustomobject]@{ id = 'claude-code-file-primary'; preflight = $preflight; invoke = $invoke }
}
