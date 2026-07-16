$ErrorActionPreference = 'Stop'
Set-StrictMode -Version Latest

# F-198 / T047: reviewer output is untrusted candidate data in run-owned staging. The controller
# validates identity/schema/bounds, classifies runtime/currentness, and alone publishes immutable
# result.json plus an informational Markdown projection. Markdown is never an authority input.

if (-not (Get-Command -Name 'Resolve-ReviewResultClassification' -ErrorAction SilentlyContinue)) { . (Join-Path $PSScriptRoot 'review-authority-core.ps1') }
if (-not (Get-Command -Name 'Publish-ReviewRunResultFact' -ErrorAction SilentlyContinue)) { . (Join-Path $PSScriptRoot 'review-authority-store.ps1') }

function Get-ReviewRunStagingPaths {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)][string]$StagingRoot,
        [Parameter(Mandatory)][string]$CampaignId,
        [Parameter(Mandatory)][string]$RunId
    )
    if (-not (Test-ReviewAuthorityIdentifier -Value $CampaignId -Kind campaign)) { throw "review-staging-invalid-campaign-id:$CampaignId" }
    if (-not (Test-ReviewAuthorityIdentifier -Value $RunId -Kind run)) { throw "review-staging-invalid-run-id:$RunId" }
    $root = [IO.Path]::GetFullPath($StagingRoot)
    $runRoot = Join-Path $root "campaigns/$CampaignId/runs/$RunId/staging"
    return [pscustomobject]@{
        staging_path = $runRoot
        candidate_result_path = Join-Path $runRoot 'candidate.json'
        candidate_report_path = Join-Path $runRoot 'candidate.md'
    }
}

function Initialize-ReviewRunStaging {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)][string]$StagingRoot,
        [Parameter(Mandatory)][string]$CampaignId,
        [Parameter(Mandatory)][string]$RunId
    )
    $paths = Get-ReviewRunStagingPaths -StagingRoot $StagingRoot -CampaignId $CampaignId -RunId $RunId
    [IO.Directory]::CreateDirectory($paths.staging_path) | Out-Null
    return $paths
}

function Read-ReviewCandidateResult {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)][string]$Path,
        [Parameter(Mandatory)][string]$ExpectedRunId,
        [Parameter(Mandatory)][string]$ExpectedTargetDigest,
        [int]$MaxBytes = 262144
    )
    if (-not [IO.File]::Exists($Path)) { return [pscustomobject]@{ present = $false; valid = $false; category = 'candidate-missing'; errors = @('candidate-missing'); candidate = $null } }
    $stream = [IO.FileStream]::new($Path, [IO.FileMode]::Open, [IO.FileAccess]::Read, [IO.FileShare]::Read)
    try {
        if ($stream.Length -gt $MaxBytes) { return [pscustomobject]@{ present = $true; valid = $false; category = 'payload-too-large'; errors = @("payload-too-large:$MaxBytes"); candidate = $null } }
        $reader = [IO.StreamReader]::new($stream, [Text.UTF8Encoding]::new($false, $true), $false, 4096, $true)
        try {
            try { $json = $reader.ReadToEnd() }
            catch [Text.DecoderFallbackException] {
                return [pscustomobject]@{ present = $true; valid = $false; category = 'invalid-utf8'; errors = @('invalid-utf8'); candidate = $null }
            }
        }
        finally { $reader.Dispose() }
    }
    finally { $stream.Dispose() }
    $validation = Test-ReviewAuthorityContractJson -ContractName ReviewerCandidate -Json $json -MaxBytes $MaxBytes -ExpectedRunId $ExpectedRunId -ExpectedTargetDigest $ExpectedTargetDigest
    if (-not $validation.valid) { return [pscustomobject]@{ present = $true; valid = $false; category = $validation.category; errors = $validation.errors; candidate = $null } }
    $candidate = $json.Trim() | ConvertFrom-Json -Depth 20 -ErrorAction Stop
    return [pscustomobject]@{ present = $true; valid = $true; category = 'valid'; errors = @(); candidate = $candidate }
}

function ConvertTo-ReviewReportText {
    param([AllowNull()]$Value, [int]$MaxLength = 4000)
    $text = if ($null -eq $Value) { '' } else { [string]$Value }
    $text = $text -replace "`r?`n", ' '
    $text = $text.Replace('|', '\|')
    if ($text.Length -gt $MaxLength) { return $text.Substring(0, $MaxLength) + '…' }
    return $text
}

function ConvertTo-ReviewRunReportMarkdown {
    param([Parameter(Mandatory)]$Result)
    $lines = [System.Collections.Generic.List[string]]::new()
    $lines.Add('# Review Result') | Out-Null; $lines.Add('') | Out-Null
    foreach ($pair in @(
        @('Campaign', $Result.campaign_id), @('Run', $Result.run_id), @('Harness', $Result.harness_id),
        @('Target digest', $Result.target_digest), @('Completion', $Result.completion), @('Verdict', $Result.verdict),
        @('Runtime outcome', $Result.runtime_outcome), @('Currentness', $Result.currentness),
        @('Can approve current snapshot', ([string]$Result.can_approve_current).ToLowerInvariant())
    )) { $lines.Add(('- **{0}**: `{1}`' -f $pair[0], (ConvertTo-ReviewReportText -Value $pair[1] -MaxLength 256))) | Out-Null }
    $lines.Add('') | Out-Null
    $lines.Add('## Summary') | Out-Null; $lines.Add('') | Out-Null
    $lines.Add((ConvertTo-ReviewReportText -Value $Result.summary)) | Out-Null
    if (-not [string]::IsNullOrWhiteSpace([string]$Result.failure_reason)) {
        $lines.Add('') | Out-Null; $lines.Add(('Failure reason: {0}' -f (ConvertTo-ReviewReportText -Value $Result.failure_reason -MaxLength 2000))) | Out-Null
    }
    $lines.Add('') | Out-Null; $lines.Add('## Findings') | Out-Null; $lines.Add('') | Out-Null
    if (@($Result.findings).Count -eq 0) { $lines.Add('No validated findings were published.') | Out-Null }
    else {
        $lines.Add('| ID | Severity | Relevance | Location | Finding |') | Out-Null
        $lines.Add('| --- | --- | --- | --- | --- |') | Out-Null
        foreach ($finding in @($Result.findings)) {
            $findingText = '{0}: {1}' -f (ConvertTo-ReviewReportText -Value $finding.title -MaxLength 200), (ConvertTo-ReviewReportText -Value $finding.description -MaxLength 1000)
            $lines.Add(('| `{0}` | {1} | {2} | {3} | {4} |' -f $finding.finding_id, $finding.severity, $finding.relevance, (ConvertTo-ReviewReportText -Value $finding.location -MaxLength 500), $findingText)) | Out-Null
        }
    }
    $lines.Add('') | Out-Null
    $lines.Add('_This Markdown is a controller-generated projection. Authority is the sibling immutable `result.json`._') | Out-Null
    return ($lines -join "`n")
}

function Write-ReviewRunReportCreateNew {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)][string]$StoreRoot,
        [Parameter(Mandatory)][string]$CampaignId,
        [Parameter(Mandatory)][string]$RunId,
        [Parameter(Mandatory)][string]$Content
    )
    $relative = (Get-ReviewAuthorityCampaignRelativeRoot -CampaignId $CampaignId) + "/runs/$RunId/report.md"
    $path = Get-ReviewAuthorityStorePath -StoreRoot $StoreRoot -RelativePath $relative
    [IO.Directory]::CreateDirectory((Split-Path -Parent $path)) | Out-Null
    $bytes = [Text.UTF8Encoding]::new($false).GetBytes($Content)
    try {
        $stream = [IO.FileStream]::new($path, [IO.FileMode]::CreateNew, [IO.FileAccess]::Write, [IO.FileShare]::None)
        try { $stream.Write($bytes, 0, $bytes.Length); $stream.Flush($true) } finally { $stream.Dispose() }
        return [pscustomobject]@{ created = $true; idempotent = $false; path = $path }
    }
    catch [IO.IOException] {
        if (-not [IO.File]::Exists($path)) { throw }
        $existing = [IO.File]::ReadAllText($path, [Text.UTF8Encoding]::new($false))
        if ($existing -ceq $Content) { return [pscustomobject]@{ created = $false; idempotent = $true; path = $path } }
        throw "review-store-corruption:conflicting-report-projection:$relative"
    }
}

function Invoke-ReviewResultIngress {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)][string]$StoreRoot,
        [Parameter(Mandatory)][string]$StagingRoot,
        [Parameter(Mandatory)][string]$CampaignId,
        [Parameter(Mandatory)][string]$RunId,
        [Parameter(Mandatory)][string]$TargetDigest,
        [Parameter(Mandatory)][string]$HarnessId,
        [Parameter(Mandatory)][ValidateSet('completed', 'preflight-failed', 'claim-contended', 'launch-failed', 'timed-out', 'terminated', 'invalid-output', 'identity-mismatch', 'containment-violated', 'abandoned')][string]$RuntimeOutcome,
        [Parameter(Mandatory)][bool]$Invoked,
        [Parameter(Mandatory)][bool]$TerminationVerified,
        [Parameter(Mandatory)][ValidateSet('verified', 'violated', 'unknown')][string]$Containment,
        [Parameter(Mandatory)][ValidateSet('current', 'snapshot-moved', 'unknown')][string]$Currentness,
        [Parameter(Mandatory)][string]$StartedAt,
        [Parameter(Mandatory)][string]$EndedAt,
        [Parameter(Mandatory)][long]$DurationMs,
        [string]$FailureReason,
        [string]$ControllerDegradeReason,
        [object[]]$PriorFindings = @()
    )
    $paths = Get-ReviewRunStagingPaths -StagingRoot $StagingRoot -CampaignId $CampaignId -RunId $RunId
    $candidateRead = Read-ReviewCandidateResult -Path $paths.candidate_result_path -ExpectedRunId $RunId -ExpectedTargetDigest $TargetDigest
    $effectiveOutcome = $RuntimeOutcome
    if ($RuntimeOutcome -ceq 'completed' -and -not $candidateRead.valid) {
        $effectiveOutcome = if ($candidateRead.category -ceq 'identity-mismatch') { 'identity-mismatch' } else { 'invalid-output' }
    }
    $classification = Resolve-ReviewResultClassification -RuntimeOutcome $effectiveOutcome -Invoked $Invoked -TerminationVerified $TerminationVerified -Containment $Containment -Currentness $Currentness -Candidate $candidateRead.candidate -CandidateValid ([bool]$candidateRead.valid)
    if (-not $classification.publish_permitted) {
        return [pscustomobject]@{ published = $false; reason = $classification.reason; result_path = $null; report_path = $null; candidate_category = $candidateRead.category }
    }

    $candidateFindings = @()
    if ($candidateRead.valid) { $candidateFindings = @($candidateRead.candidate.findings | Where-Object { $null -ne $_ }) }
    $links = if ($candidateFindings.Count -gt 0) { @(Resolve-ReviewFindingLineage -RunId $RunId -CurrentFindings $candidateFindings -PriorFindings $PriorFindings) } else { @() }
    $terminalFindings = [System.Collections.Generic.List[object]]::new()
    for ($i = 0; $i -lt $candidateFindings.Count; $i++) {
        $candidateFinding = $candidateFindings[$i]; $link = $links[$i]
        $terminalFindings.Add([pscustomobject][ordered]@{
            finding_id = [string]$link.finding_id; source_local_id = [string]$candidateFinding.local_id; lineage_id = [string]$link.lineage_id
            severity = [string]$candidateFinding.severity; title = [string]$candidateFinding.title; description = [string]$candidateFinding.description
            location = $(if ($candidateFinding.PSObject.Properties.Name -contains 'location') { $candidateFinding.location } else { $null })
            relevance = $Currentness; resolution = 'open'
        }) | Out-Null
    }
    $validationState = if ($candidateRead.valid) { 'valid' } elseif (-not $candidateRead.present) { 'not-produced' } else { 'invalid' }
    $derivedFailure = if (-not [string]::IsNullOrWhiteSpace($FailureReason)) { $FailureReason }
    elseif ($candidateRead.valid -and $classification.reason -ceq 'complete-result') { $null }
    elseif (-not $candidateRead.valid) { '{0}: {1}' -f $candidateRead.category, ($candidateRead.errors -join ',') }
    else { [string]$classification.reason }
    $derivedFailure = ConvertTo-ReviewAuthorityBoundedText -Value $derivedFailure -MaximumLength 2000
    $summary = if ($candidateRead.valid) { [string]$candidateRead.candidate.summary } else { [string]$classification.reason }
    $completion = [string]$classification.completion
    $verdict = [string]$classification.verdict
    $canApproveCurrent = [bool]$classification.can_approve_current
    if (-not [string]::IsNullOrWhiteSpace($ControllerDegradeReason)) {
        # Controller-known missing evidence outranks a reviewer's optimistic candidate. Preserve
        # validated findings, but never let a design-blind run become approval authority.
        $completion = 'partial'; $verdict = 'incomplete'; $canApproveCurrent = $false
        $combinedFailure = if ([string]::IsNullOrWhiteSpace($derivedFailure)) { $ControllerDegradeReason } else { "$ControllerDegradeReason $derivedFailure" }
        $derivedFailure = ConvertTo-ReviewAuthorityBoundedText -Value $combinedFailure -MaximumLength 2000
    }
    $result = [pscustomobject][ordered]@{
        schema_version = '1.0'; campaign_id = $CampaignId; run_id = $RunId; target_digest = $TargetDigest; harness_id = $HarnessId
        completion = $completion; verdict = $verdict; runtime_outcome = $effectiveOutcome
        termination_verified = $TerminationVerified; containment = $Containment; currentness = $Currentness; validation = $validationState
        can_approve_current = $canApproveCurrent; failure_reason = $derivedFailure; summary = $summary; findings = @($terminalFindings)
        started_at = $StartedAt; ended_at = $EndedAt; duration_ms = $DurationMs
    }
    $published = Publish-ReviewRunResultFact -StoreRoot $StoreRoot -CampaignId $CampaignId -RunId $RunId -Fact $result
    $report = Write-ReviewRunReportCreateNew -StoreRoot $StoreRoot -CampaignId $CampaignId -RunId $RunId -Content (ConvertTo-ReviewRunReportMarkdown -Result $result)
    return [pscustomobject]@{
        published = $true; reason = $(if ($published.created) { 'terminal-result-published' } else { 'terminal-result-idempotent' })
        result = $result; result_path = $published.path; report_path = $report.path; candidate_category = $candidateRead.category
    }
}
