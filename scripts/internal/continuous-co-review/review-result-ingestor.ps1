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
        implementer_evidence_path = Join-Path $runRoot 'implementer-evidence.json'
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
        [int]$MaxBytes = $script:ReviewAuthorityCandidateLimits.max_candidate_bytes
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

function Test-ReviewFindingStatesFailureScenario {
    # T005 / FR-006. A prompt is a REQUEST; a contract needs a REJECTION. The reviewer prompt demands an
    # explicit `Failure scenario:` clause on every finding, and THIS is where that demand either binds or
    # is decoration - if a scenario-less finding is accepted at its stated severity anyway, "every finding
    # states a concrete failure scenario or it is not a finding" changes nothing about what happens.
    #
    # Detection is deliberately the LITERAL clause, not a heuristic read of the prose. A contract is
    # explicit by construction; the generosity lives in the CONSEQUENCE (demote, never discard), not in
    # pretending to infer a failure scenario from wording. `-> ` alone is not enough - a clause header
    # with nothing after it is not a scenario either.
    [OutputType([bool])]
    param([AllowNull()][AllowEmptyString()][string]$Description)

    if ([string]::IsNullOrWhiteSpace($Description)) { return $false }
    $match = [regex]::Match($Description, '(?is)failure\s+scenario\s*:\s*(?<body>.+)$')
    if (-not $match.Success) { return $false }
    return (([string]$match.Groups['body'].Value).Trim().Length -ge 12)
}

function Resolve-ReviewFindingGatingEligibility {
    # T005 / FR-006 - DEMOTE, NEVER DISCARD (maintainer ruling 2026-08-10).
    #
    # The fail direction matters more than the rule: losing a real blocking finding is worse than
    # admitting a weak one. So a finding without a concrete failure scenario is not dropped and not
    # rejected - it lands BELOW THE GATING FLOOR as a `minor`, carried as a recorded follow-up exactly
    # like any other minor. That keeps the signal, removes its power to hold sign-off hostage, and is the
    # same shape as the existing "minors never gate" rule rather than a new mechanism beside it.
    #
    # It also attacks the gold-plating economics at the point where they bite: an observation with no
    # failure scenario can still be REPORTED, it just cannot cost the human a round.
    #
    # Only a GATING severity can be demoted. A finding that never gated is returned untouched - in
    # particular its description is NOT rewritten, because a demotion note on something that was never
    # demoted would be a lie in the record.
    [CmdletBinding()]
    param([AllowNull()][object[]]$Findings)

    $graded = [System.Collections.Generic.List[object]]::new()
    foreach ($finding in @($Findings)) {
        if ($null -eq $finding) { continue }
        $severity = ([string](Get-ReviewAuthorityProperty -Object $finding -Name 'severity')).Trim().ToLowerInvariant()
        $description = [string](Get-ReviewAuthorityProperty -Object $finding -Name 'description')
        $gates = ($severity -ceq 'blocking' -or $severity -ceq 'major')
        $demote = $gates -and -not (Test-ReviewFindingStatesFailureScenario -Description $description)

        $copy = [pscustomobject]@{}
        foreach ($property in $finding.PSObject.Properties) {
            $copy | Add-Member -NotePropertyName $property.Name -NotePropertyValue $property.Value -Force
        }
        if ($demote) {
            $copy | Add-Member -NotePropertyName 'severity' -NotePropertyValue 'minor' -Force
            # The demotion is recorded IN the finding rather than only in a counter, so a human reading
            # the follow-up list can see why this one is not gating and judge it for themselves. The
            # original severity is named, never silently erased.
            $note = ('[demoted to minor: no concrete failure scenario, so it cannot gate; reported as {0} by the reviewer] ' -f $severity)
            $copy | Add-Member -NotePropertyName 'description' -NotePropertyValue ($note + $description) -Force
        }
        $copy | Add-Member -NotePropertyName 'demoted' -NotePropertyValue $demote -Force
        # The reviewer's ORIGINAL severity as structured data, not only inside the note above. The
        # human-facing surface has to say "reported as blocking" rather than a vague "reported higher",
        # and the alternative is re-parsing our own prose out of the description - a string contract
        # between two files, which is the shape that drifts silently.
        $copy | Add-Member -NotePropertyName 'demoted_from' -NotePropertyValue $(if ($demote) { $severity } else { '' }) -Force
        $graded.Add($copy) | Out-Null
    }
    return @($graded)
}

# W33: A COMPLETE CODE REVIEW MUST HAVE EXAMINED CODE.
#
# Measured 2026-08-19/20 (KeyContextAI). Two runs recorded `pass`/`complete`/`current` with zero
# findings against a frozen target that held the whole implementation, and neither had read any of
# it. Their own summaries said so, in plain language: "the frozen iteration 001 plan" (57s) and
# "the frozen iteration artifacts" (67s), against 186s for the one run that walked the source. The
# reviewer was HONEST both times. The record held the truth and nothing consumed it, so a review of
# a planning document became the recorded independent review of an implementation, and - because a
# passing run becomes the baseline the next round advances from - every later round inherited it.
#
# The controller cannot know which files a reviewer opened, and a duration threshold is a guess. So
# the candidate DECLARES what it examined and the controller checks that declaration against the
# target it froze. This catches the honest-but-misframed reviewer, which is the case that actually
# occurred; it does not pretend to catch a lying one.
#
# FAIL-OPEN ON ABSENCE, deliberately. A deployed reviewer that never emits `examined_paths` behaves
# exactly as it does today. Fail-closed would wedge the signoff gate shut on every project already
# in flight, which is a worse failure than the one being fixed.
function Test-ReviewExaminedPathIsSource {
    param([Parameter(Mandatory)][AllowEmptyString()][string]$Path)
    # A NEGATIVE rule on purpose: everything is source unless it is recognisably a record or a
    # document. An unknown extension counts as source, so a language nobody here anticipated is
    # never mistaken for paperwork and never triggers a degrade.
    # NOT TrimStart('./') - that trims those two CHARACTERS repeatedly, so '.specrew/config.yml'
    # arrives as 'specrew/config.yml' and a governance file classifies as source. Strip the one
    # leading './' and nothing else.
    $p = ([string]$Path).Trim().Replace('\', '/')
    while ($p.StartsWith('./')) { $p = $p.Substring(2) }
    if ([string]::IsNullOrWhiteSpace($p)) { return $false }
    if ($p -match '(?i)^(specs|docs)/') { return $false }
    if ($p -match '(?i)^\.(specrew|squad|specify|github|agents|cursor|copilot|claude)/') { return $false }
    if ($p -match '(?i)\.(md|markdown|txt|rst|adoc)$') { return $false }
    return $true
}

function Resolve-ReviewDeclaredCoverage {
    # Returns what the candidate SAYS it examined, split by whether it is source. `declared` is the
    # gate: when the reviewer said nothing, there is nothing to check and nothing is claimed.
    #
    # Round-11 blocking finding (DRIFT-199-I001-118): a PRESENT empty list is not "said nothing" -
    # it is an honest declaration of ZERO coverage, and mapping it to declared=false let a
    # complete/pass candidate that opened no files stay approval authority over a source-bearing
    # target. Only ABSENCE of the field keeps the legacy fail-open, for reviewers that predate the
    # declared-coverage contract.
    param([object]$Candidate)
    $empty = [pscustomobject]@{ declared = $false; paths = @(); source_paths = @() }
    if ($null -eq $Candidate) { return $empty }
    if (-not ($Candidate.PSObject.Properties.Name -contains 'examined_paths')) { return $empty }
    $paths = @(@($Candidate.examined_paths) |
            ForEach-Object { [string]$_ } |
            Where-Object { -not [string]::IsNullOrWhiteSpace($_) })
    return [pscustomobject]@{
        declared     = $true
        paths        = @($paths)
        source_paths = @($paths | Where-Object { Test-ReviewExaminedPathIsSource -Path $_ })
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
        # W33. Whether the tree the controller FROZE contains source at all. Supplied by the caller
        # because only the orchestrator holds the snapshot. Default $false keeps every existing
        # caller - fixtures included - on exactly today's behaviour: with no claim that the target
        # held code, a declared docs-only review is not evidence of anything being missed.
        [bool]$TargetHasSource = $false,
        [object[]]$PriorFindings = @()
    )
    $paths = Get-ReviewRunStagingPaths -StagingRoot $StagingRoot -CampaignId $CampaignId -RunId $RunId
    $candidateLimits = Get-ReviewAuthorityCandidateLimits
    $candidateRead = Read-ReviewCandidateResult -Path $paths.candidate_result_path -ExpectedRunId $RunId -ExpectedTargetDigest $TargetDigest -MaxBytes $candidateLimits.max_candidate_bytes
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
    # T005 / FR-006: the failure-scenario contract binds HERE, before lineage and before publication, so a
    # scenario-less finding is carried into the terminal result as a non-gating follow-up rather than
    # arriving at the human with the power to demand a round.
    if ($candidateFindings.Count -gt 0) { $candidateFindings = @(Resolve-ReviewFindingGatingEligibility -Findings $candidateFindings) }
    $links = if ($candidateFindings.Count -gt 0) { @(Resolve-ReviewFindingLineage -RunId $RunId -CurrentFindings $candidateFindings -PriorFindings $PriorFindings) } else { @() }
    $terminalFindings = [System.Collections.Generic.List[object]]::new()
    for ($i = 0; $i -lt $candidateFindings.Count; $i++) {
        $candidateFinding = $candidateFindings[$i]; $link = $links[$i]
        $terminalFindings.Add([pscustomobject][ordered]@{
            finding_id = [string]$link.finding_id; source_local_id = [string]$candidateFinding.local_id; lineage_id = [string]$link.lineage_id
            severity = [string]$candidateFinding.severity; title = [string]$candidateFinding.title; description = [string]$candidateFinding.description
            location = $(if ($candidateFinding.PSObject.Properties.Name -contains 'location') { $candidateFinding.location } else { $null })
            relevance = $Currentness; resolution = 'open'
            # T005 / FR-006, maintainer ruling 2026-08-10. These two marks are carried into the TERMINAL
            # result rather than being left on the in-memory graded copy. A demotion the human cannot see
            # is a SILENCING - the reviewer meant this to gate, and without the marks it arrives in the
            # follow-up list indistinguishable from a typo. The projection below is an explicit field
            # list, so anything not named here is dropped: that is precisely how the marks were lost.
            demoted = [bool]$candidateFinding.demoted
            demoted_from = [string]$candidateFinding.demoted_from
        }) | Out-Null
    }
    $validationState = if ($candidateRead.valid) { 'valid' } elseif (-not $candidateRead.present) { 'not-produced' } else { 'invalid' }
    $derivedFailure = if (-not [string]::IsNullOrWhiteSpace($FailureReason)) { $FailureReason }
    elseif ($candidateRead.valid -and $classification.reason -ceq 'complete-result') { $null }
    elseif (-not $candidateRead.valid) { '{0}: {1}' -f $candidateRead.category, ($candidateRead.errors -join ',') }
    else { [string]$classification.reason }
    # W32: A FAILURE FIELD MUST NOT CARRY A SUCCESS TOKEN.
    #
    # `$classification.reason` is the classifier's verdict word, not a fault, so a completed run whose
    # candidate merely declared partial coverage landed `failure_reason: "completed"` in the immutable
    # store. Read back later that is worse than empty: it invites "the run failed with 'completed'".
    # Partiality is already carried honestly by `completion` and `verdict`; this field is for faults.
    if (-not [string]::IsNullOrWhiteSpace($derivedFailure) -and
        ([string]$derivedFailure -ceq [string]$effectiveOutcome -or [string]$derivedFailure -ceq 'completed')) {
        $derivedFailure = $null
    }
    $derivedFailure = ConvertTo-ReviewAuthorityBoundedText -Value $derivedFailure -MaximumLength 2000
    $summary = if ($candidateRead.valid) { [string]$candidateRead.candidate.summary } else { [string]$classification.reason }
    $completion = [string]$classification.completion
    $verdict = [string]$classification.verdict
    $canApproveCurrent = [bool]$classification.can_approve_current

    # W33. A candidate that declares its coverage and declares no source, against a target the
    # controller knows holds source, has not reviewed the code - whatever its verdict says. Routed
    # through the SAME degrade the design-context rule uses, so it cannot approve the current target
    # and cannot become the baseline a later round advances from.
    $coverage = Resolve-ReviewDeclaredCoverage -Candidate $candidateRead.candidate
    if ($candidateRead.valid -and $TargetHasSource -and $coverage.declared -and
        @($coverage.source_paths).Count -eq 0) {
        $coverageDegrade = if (@($coverage.paths).Count -eq 0) {
            # The empty declaration reads differently from a docs-only one: nothing was opened at all.
            'REVIEW_EXAMINED_NO_SOURCE: the review declares it examined no files at all, while the frozen target contains source; this run is partial evidence about the code and cannot approve the current target.'
        }
        else {
            $examinedNote = (@($coverage.paths) | Select-Object -First 5) -join ', '
            ('REVIEW_EXAMINED_NO_SOURCE: the review declares it examined only records or documents ({0}), while the frozen target contains source; this run is partial evidence about the code and cannot approve the current target.' -f $examinedNote)
        }
        $ControllerDegradeReason = if ([string]::IsNullOrWhiteSpace($ControllerDegradeReason)) { $coverageDegrade }
        else { "$ControllerDegradeReason $coverageDegrade" }
    }

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
        # W33. The coverage the verdict rests on, carried into the terminal record. This
        # projection is an explicit field list - the same one that silently dropped the demotion
        # marks - so a field added upstream and not named here never reaches a single reader.
        examined_paths = @($coverage.paths)
    }
    $published = Publish-ReviewRunResultFact -StoreRoot $StoreRoot -CampaignId $CampaignId -RunId $RunId -Fact $result
    $report = Write-ReviewRunReportCreateNew -StoreRoot $StoreRoot -CampaignId $CampaignId -RunId $RunId -Content (ConvertTo-ReviewRunReportMarkdown -Result $result)
    return [pscustomobject]@{
        published = $true; reason = $(if ($published.created) { 'terminal-result-published' } else { 'terminal-result-idempotent' })
        result = $result; result_path = $published.path; report_path = $report.path; candidate_category = $candidateRead.category
    }
}
