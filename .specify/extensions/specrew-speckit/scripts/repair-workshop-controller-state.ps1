#!/usr/bin/env pwsh
[CmdletBinding(DefaultParameterSetName = 'Request')]
param(
    [Parameter(Mandatory)][string] $ProjectRoot,
    [Parameter(Mandatory)][string] $FeatureRef,
    [Parameter(ParameterSetName = 'Request')][switch] $Request,
    [Parameter(Mandatory, ParameterSetName = 'Apply')][switch] $Apply,
    [switch] $PassThru
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

function New-SpecrewWorkshopRepairRefusal {
    # The workshop refusal contract: what happened, one action, and the standing reassurance that the
    # human's answers are safe - never machinery vocabulary, never blaming Specrew.
    param([Parameter(Mandatory)][string] $Summary, [Parameter(Mandatory)][string] $Action)
    $contract = if (Get-Command -Name 'Get-SpecrewWorkshopRefusalContractText' -ErrorAction SilentlyContinue) {
        Get-SpecrewWorkshopRefusalContractText -AnswerState 'preserved'
    }
    else {
        'Your saved answers remain unchanged.'
    }
    return ('{0} {1} {2}' -f $Summary, $Action, $contract)
}

function Write-AtomicUtf8NoBom {
    param(
        [Parameter(Mandatory)][string] $Path,
        [Parameter(Mandatory)][string] $Content
    )

    $temporaryPath = '{0}.{1}.tmp' -f $Path, ([Guid]::NewGuid().ToString('N'))
    try {
        [IO.File]::WriteAllText($temporaryPath, $Content, [Text.UTF8Encoding]::new($false))
        Move-Item -LiteralPath $temporaryPath -Destination $Path -Force
    }
    finally {
        if (Test-Path -LiteralPath $temporaryPath -PathType Leaf) {
            Remove-Item -LiteralPath $temporaryPath -Force -ErrorAction SilentlyContinue
        }
    }
}

function Get-Sha256ForBytes {
    param([Parameter(Mandatory)][byte[]] $Bytes)
    return ([Convert]::ToHexString([Security.Cryptography.SHA256]::HashData($Bytes))).ToLowerInvariant()
}

function Get-FileSha256 {
    param([Parameter(Mandatory)][string] $Path)
    return Get-Sha256ForBytes -Bytes ([IO.File]::ReadAllBytes($Path))
}

function Get-CanonicalPendingState {
    return [ordered]@{
        schema_version             = '1.1'
        workshop_intake            = $true
        confirmation_required      = $true
        agenda_contract            = 'complete-coverage-v1'
        human_turn_contract        = 'typed-turns-v1'
        agenda_status              = 'pending-confirmation'
        selected                   = @()
        agenda                     = [ordered]@{}
        skipped                    = [ordered]@{}
        agenda_confirmation        = 'pending'
        agenda_confirmation_scope  = 'lens-selection'
        agenda_turn_receipt        = 'pending'
        workshop                   = [ordered]@{}
    }
}

$resolvedProjectRoot = [IO.Path]::GetFullPath($ProjectRoot).TrimEnd(
    [IO.Path]::DirectorySeparatorChar,
    [IO.Path]::AltDirectorySeparatorChar
)
if (-not (Test-Path -LiteralPath (Join-Path $resolvedProjectRoot '.specrew/config.yml') -PathType Leaf)) {
    throw 'workshop-repair-project-not-governed'
}
if ($FeatureRef -cnotmatch '^[0-9]{3}-[a-z0-9][a-z0-9-]{0,63}$') {
    throw 'workshop-repair-feature-ref-invalid'
}

$featureRoot = Join-Path (Join-Path $resolvedProjectRoot 'specs') $FeatureRef
$statePath = Join-Path $featureRoot 'lens-applicability.json'
if (-not (Test-Path -LiteralPath $statePath -PathType Leaf)) {
    throw 'workshop-repair-state-missing'
}
$authorityStorePath = Join-Path $resolvedProjectRoot '.specify/extensions/specrew-speckit/scripts/workshop-authority-store.ps1'
if (-not (Test-Path -LiteralPath $authorityStorePath -PathType Leaf)) {
    $authorityStorePath = Join-Path $PSScriptRoot 'workshop-authority-store.ps1'
}
if (-not (Test-Path -LiteralPath $authorityStorePath -PathType Leaf)) {
    throw 'workshop-repair-authority-store-missing'
}
. $authorityStorePath

$state = Get-Content -LiteralPath $statePath -Raw -Encoding UTF8 -ErrorAction Stop |
    ConvertFrom-Json -Depth 20 -ErrorAction Stop
if ([string]$state.schema_version -cne '1.1' -or
    [string]$state.agenda_contract -cne 'complete-coverage-v1' -or
    [string]$state.human_turn_contract -cne 'typed-turns-v1') {
    throw 'workshop-repair-state-contract-invalid'
}
if ([string]$state.agenda_status -cne 'pending-confirmation') {
    throw 'workshop-repair-only-pending-state-supported'
}

$transitionOperation = if ($PSCmdlet.ParameterSetName -eq 'Request') { 'request-repair' } else { 'apply-repair' }
$transition = Resolve-SpecrewWorkshopStateTransition -Controller $state -Operation $transitionOperation
if (-not $transition.allowed) {
    if ($transition.state_class -in @('pending-empty', 'pending-product-projection')) {
        throw 'workshop-repair-not-required'
    }
    throw 'workshop-repair-transition-not-allowed'
}

$selected = @($state.selected)
$workshopKeys = if ($null -ne $state.workshop) {
    @($state.workshop.PSObject.Properties | ForEach-Object { [string]$_.Name })
}
else { @() }
$technicalWorkshopKeys = @($workshopKeys | Where-Object { $_ -cne 'product-domain' })
$agendaKeys = if ($null -ne $state.agenda) { @($state.agenda.PSObject.Properties).Count } else { 0 }
$skippedKeys = if ($null -ne $state.skipped) { @($state.skipped.PSObject.Properties).Count } else { 0 }
$hasInconsistentProjection = (
    $selected.Count -gt 0 -or
    $technicalWorkshopKeys.Count -gt 0 -or
    $agendaKeys -gt 0 -or
    $skippedKeys -gt 0 -or
    [string]$state.agenda_confirmation -cne 'pending' -or
    [string]$state.agenda_turn_receipt -cne 'pending'
)
if (-not $hasInconsistentProjection) { throw 'workshop-repair-not-required' }

$preservedRecords = @()
$workshopDirectory = Join-Path $featureRoot 'workshop'
if (Test-Path -LiteralPath $workshopDirectory -PathType Container) {
    $featurePrefix = $featureRoot.TrimEnd([IO.Path]::DirectorySeparatorChar, [IO.Path]::AltDirectorySeparatorChar) + [IO.Path]::DirectorySeparatorChar
    foreach ($recordFile in @(Get-ChildItem -LiteralPath $workshopDirectory -Recurse -File | Sort-Object FullName)) {
        $recordPath = [IO.Path]::GetFullPath($recordFile.FullName)
        if (-not $recordPath.StartsWith($featurePrefix, [StringComparison]::OrdinalIgnoreCase)) {
            throw 'workshop-repair-record-containment-invalid'
        }
        $preservedRecords += [ordered]@{
            path   = $recordPath.Substring($featurePrefix.Length).Replace([IO.Path]::DirectorySeparatorChar, '/')
            sha256 = Get-FileSha256 -Path $recordPath
        }
    }
}

$controllerSha256 = Get-FileSha256 -Path $statePath
$discardedSelected = @($selected | ForEach-Object { [string]$_ })
$discardedWorkshop = @($workshopKeys)
$proposalPath = Get-SpecrewWorkshopRepairProposalPath -ProjectRoot $resolvedProjectRoot

if ($PSCmdlet.ParameterSetName -eq 'Request') {
    $proposalDirectory = Split-Path -Parent $proposalPath
    if (-not (Test-Path -LiteralPath $proposalDirectory -PathType Container)) {
        New-Item -ItemType Directory -Path $proposalDirectory -Force | Out-Null
    }
    $proposal = $null
    if (Test-Path -LiteralPath $proposalPath -PathType Leaf) {
        $existingProposal = Get-Content -LiteralPath $proposalPath -Raw -Encoding UTF8 -ErrorAction Stop |
            ConvertFrom-Json -Depth 8 -ErrorAction Stop
        $existingRecords = @($existingProposal.preserved_records | ForEach-Object { [ordered]@{ path = [string]$_.path; sha256 = [string]$_.sha256 } })
        if ([string]$existingProposal.feature_ref -ceq $FeatureRef -and
            [string]$existingProposal.controller_sha256 -ceq $controllerSha256 -and
            (($existingRecords | ConvertTo-Json -Depth 5 -Compress) -ceq (@($preservedRecords) | ConvertTo-Json -Depth 5 -Compress))) {
            $proposal = $existingProposal
        }
    }
    if ($null -eq $proposal) {
        $proposalNonce = [Guid]::NewGuid().ToString('N')
        $binding = [ordered]@{
            schema_version      = '1.0'
            feature_ref         = $FeatureRef
            controller_sha256   = $controllerSha256
            target_state        = 'pending-confirmation'
            preserved_records   = @($preservedRecords)
            discarded_selected  = @($discardedSelected)
            discarded_workshop  = @($discardedWorkshop)
            proposal_nonce      = $proposalNonce
        }
        $bindingJson = $binding | ConvertTo-Json -Depth 8 -Compress
        $proposalId = Get-Sha256ForBytes -Bytes ([Text.Encoding]::UTF8.GetBytes($bindingJson))
        $proposal = [ordered]@{
            schema_version      = '1.0'
            proposal_id         = $proposalId
            feature_ref         = $FeatureRef
            controller_sha256   = $controllerSha256
            target_state        = 'pending-confirmation'
            preserved_records   = @($preservedRecords)
            discarded_selected  = @($discardedSelected)
            discarded_workshop  = @($discardedWorkshop)
            proposal_nonce      = $proposalNonce
            requested_at        = [DateTimeOffset]::UtcNow.ToString('o')
        }
        Write-AtomicUtf8NoBom -Path $proposalPath -Content ((($proposal | ConvertTo-Json -Depth 8)) + [Environment]::NewLine)
    }
    $proposalId = [string]$proposal.proposal_id

    $preservedLabel = if ($preservedRecords.Count -gt 0) {
        (@($preservedRecords | ForEach-Object { [string]$_.path }) -join ', ')
    }
    else { 'none were present' }
    $message = @(
        'This feature''s workshop progress is out of step with the unfinished technical agenda.'
        ('Your saved product answers remain unchanged ({0}).' -f $preservedLabel)
        'I can return only the unfinished technical agenda to its pre-confirmation state, then show that agenda again.'
        'To authorize that exact repair, type: approved for workshop repair'
    ) -join [Environment]::NewLine
    if ($PassThru) {
        [pscustomobject]@{
            state              = 'awaiting-human-authorization'
            proposal_id        = $proposalId
            controller_sha256  = $controllerSha256
            preserved_records  = @($preservedRecords)
            message            = $message
        }
    }
    else { Write-Output $message }
    return
}

$proposal = Get-Content -LiteralPath $proposalPath -Raw -Encoding UTF8 -ErrorAction Stop |
    ConvertFrom-Json -Depth 8 -ErrorAction Stop
$proposalId = [string]$proposal.proposal_id
$proposalBinding = [ordered]@{
    schema_version      = [string]$proposal.schema_version
    feature_ref         = [string]$proposal.feature_ref
    controller_sha256   = [string]$proposal.controller_sha256
    target_state        = [string]$proposal.target_state
    preserved_records   = @($proposal.preserved_records | ForEach-Object { [ordered]@{ path = [string]$_.path; sha256 = [string]$_.sha256 } })
    discarded_selected  = @($proposal.discarded_selected | ForEach-Object { [string]$_ })
    discarded_workshop  = @($proposal.discarded_workshop | ForEach-Object { [string]$_ })
    proposal_nonce      = [string]$proposal.proposal_nonce
}
$expectedProposalId = Get-Sha256ForBytes -Bytes ([Text.Encoding]::UTF8.GetBytes(($proposalBinding | ConvertTo-Json -Depth 8 -Compress)))
if ($proposalId -cne $expectedProposalId -or $proposalId -cnotmatch '^[a-f0-9]{64}$' -or
    [string]$proposal.proposal_nonce -cnotmatch '^[a-f0-9]{32}$' -or
    [string]$proposal.controller_sha256 -cne $controllerSha256 -or
    [string]$proposal.feature_ref -cne $FeatureRef) {
    # FR-028 (T019): the sibling bare token, given the same treatment.
    throw (New-SpecrewWorkshopRepairRefusal -Summary 'The workshop records changed after this repair was proposed, so the proposal no longer matches what is on disk and was not applied.' `
            -Action 'Ask for the repair to be proposed again, read the fresh proposal, and authorize that one.')
}
# SPECREW-AUTHORITY-CONSUMER: workshop-repair-human-authorization
$authorization = Get-SpecrewWorkshopRepairAuthorization -ProjectRoot $resolvedProjectRoot -ProposalId $proposalId
if ($null -eq $authorization -or
    [string]$authorization.controller_sha256 -cne $controllerSha256 -or
    [string]$authorization.feature_ref -cne $FeatureRef) {
    # FR-028 (iteration 002, T019): this used to throw the bare token
    # 'workshop-repair-human-authorization-missing' - a machine label with no reader. The recognizer is
    # unchanged (still the exact typed phrase, still case-sensitive); only the SILENCE around it is fixed.
    # This script never receives the human's reply text - the authorization is looked up by proposal id -
    # so the refusal says exactly what it can know: no authorization is on record for THIS proposal, and
    # the phrase that creates one. Quoting a reply it does not have would be an invented instance.
    throw (New-SpecrewWorkshopRepairRefusal -Summary 'No typed authorization is on record for this repair, so nothing was changed.' `
            -Action 'To authorize exactly this repair, type: approved for workshop repair')
}

foreach ($record in @($proposal.preserved_records)) {
    $recordPath = Join-Path $featureRoot ([string]$record.path)
    if (-not (Test-Path -LiteralPath $recordPath -PathType Leaf) -or
        (Get-FileSha256 -Path $recordPath) -cne [string]$record.sha256) {
        throw 'workshop-repair-preserved-record-changed'
    }
}

$canonicalState = Get-CanonicalPendingState
$canonicalJson = ($canonicalState | ConvertTo-Json -Depth 8) + [Environment]::NewLine
Write-AtomicUtf8NoBom -Path $statePath -Content $canonicalJson
$afterSha256 = Get-FileSha256 -Path $statePath

$historyPath = Join-Path $resolvedProjectRoot '.specrew/runtime/workshop-controller-repair-history.jsonl'
$historyDirectory = Split-Path -Parent $historyPath
if (-not (Test-Path -LiteralPath $historyDirectory -PathType Container)) {
    New-Item -ItemType Directory -Path $historyDirectory -Force | Out-Null
}
$historyRecord = [ordered]@{
    schema_version     = '1.0'
    proposal_id        = $proposalId
    feature_ref        = $FeatureRef
    before_sha256      = $controllerSha256
    after_sha256       = $afterSha256
    preserved_records  = @($proposal.preserved_records)
    applied_at         = [DateTimeOffset]::UtcNow.ToString('o')
}
[IO.File]::AppendAllText(
    $historyPath,
    (($historyRecord | ConvertTo-Json -Depth 8 -Compress) + [Environment]::NewLine),
    [Text.UTF8Encoding]::new($false)
)
Remove-Item -LiteralPath $proposalPath -Force -ErrorAction Stop

if ($PassThru) {
    [pscustomobject]@{
        state             = 'repaired'
        proposal_id       = $proposalId
        before_sha256     = $controllerSha256
        after_sha256      = $afterSha256
        preserved_records = @($proposal.preserved_records)
    }
}
else {
    Write-Output 'The saved product answers are unchanged. The unfinished technical agenda is ready to be shown again.'
}
