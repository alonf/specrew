#!/usr/bin/env pwsh
[CmdletBinding(DefaultParameterSetName = 'Json')]
param(
    [Parameter(Mandatory)][string] $ProjectRoot,
    [Parameter(Mandatory)][string] $FeatureRef,
    [Parameter(Mandatory, ParameterSetName = 'Json')][string] $AgendaJson,
    [Parameter(Mandatory, ParameterSetName = 'Fields')][string[]] $SelectedLens,
    [Parameter(Mandatory, ParameterSetName = 'Fields')][string[]] $SelectedDepth,
    [Parameter(Mandatory, ParameterSetName = 'Fields')][string[]] $SelectedDecision,
    [Parameter(Mandatory, ParameterSetName = 'Fields')][AllowEmptyCollection()][string[]] $SkippedLens,
    [Parameter(Mandatory, ParameterSetName = 'Fields')][AllowEmptyCollection()][string[]] $SkippedReason,
    [ValidateSet('human-confirmed')][string] $Confirmation = 'human-confirmed',
    [switch] $RenderOnly,
    [switch] $PassThru
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

function Write-AtomicUtf8NoBom {
    param([Parameter(Mandatory)][string] $Path, [Parameter(Mandatory)][string] $Content)
    $tempPath = '{0}.{1}.tmp' -f $Path, ([Guid]::NewGuid().ToString('N'))
    try {
        [IO.File]::WriteAllText($tempPath, $Content, [Text.UTF8Encoding]::new($false))
        Move-Item -LiteralPath $tempPath -Destination $Path -Force
    }
    finally {
        if (Test-Path -LiteralPath $tempPath -PathType Leaf) {
            Remove-Item -LiteralPath $tempPath -Force -ErrorAction SilentlyContinue
        }
    }
}

function New-SpecrewWorkshopAgendaRefusal {
    param(
        [Parameter(Mandatory)][string]$Summary,
        [AllowEmptyString()][string]$Action
    )
    $parts = [Collections.Generic.List[string]]::new()
    $parts.Add($Summary.Trim()) | Out-Null
    if (-not [string]::IsNullOrWhiteSpace($Action)) { $parts.Add($Action.Trim()) | Out-Null }
    $parts.Add((Get-SpecrewWorkshopRefusalContractText)) | Out-Null
    return ($parts -join ' ')
}

$authorityStorePath = Join-Path $PSScriptRoot 'workshop-authority-store.ps1'
if (-not (Test-Path -LiteralPath $authorityStorePath -PathType Leaf)) {
    throw "Workshop typed-turn authority helper is missing: '$authorityStorePath'."
}
. $authorityStorePath

function Get-CanonicalWorkshopAgendaText {
    param(
        [Parameter(Mandatory)][Collections.IDictionary]$Agenda,
        [Parameter(Mandatory)][Collections.IDictionary]$Skipped
    )
    $lines = [Collections.Generic.List[string]]::new()
    $lines.Add('Workshop agenda') | Out-Null
    $lines.Add('') | Out-Null
    $lines.Add('Selected lenses:') | Out-Null
    foreach ($entry in $Agenda.GetEnumerator()) {
        $lines.Add(('- {0} ({1}): {2}' -f $entry.Key, $entry.Value.depth, $entry.Value.decision)) | Out-Null
    }
    $lines.Add('') | Out-Null
    $lines.Add('Skipped lenses:') | Out-Null
    if ($Skipped.Count -eq 0) { $lines.Add('- none') | Out-Null }
    else { foreach ($entry in $Skipped.GetEnumerator()) { $lines.Add(('- {0}: {1}' -f $entry.Key, $entry.Value)) | Out-Null } }
    $lines.Add('') | Out-Null
    $lines.Add('Does this complete selected + skipped agenda look right? Reply with confirm or tell me what to change.') | Out-Null
    return ($lines -join [Environment]::NewLine)
}

$resolvedProjectRoot = [IO.Path]::GetFullPath($ProjectRoot).TrimEnd(
    [IO.Path]::DirectorySeparatorChar,
    [IO.Path]::AltDirectorySeparatorChar
)
if (-not (Test-Path -LiteralPath (Join-Path $resolvedProjectRoot '.specrew/config.yml') -PathType Leaf)) {
    throw (New-SpecrewWorkshopAgendaRefusal -Summary 'Workshop agenda confirmation requires a Specrew-governed project.' `
        -Action 'Run the agenda command from the project root that contains .specrew/config.yml.')
}
if ($FeatureRef -cnotmatch '^[0-9]{3}-[a-z0-9][a-z0-9-]{0,63}$') {
    throw "FeatureRef must be an exact Specrew feature reference such as '001-article-amplifier'."
}
if ($PSCmdlet.ParameterSetName -eq 'Json') {
    try { $proposal = $AgendaJson | ConvertFrom-Json -AsHashtable -Depth 10 -ErrorAction Stop }
    catch { throw "AgendaJson is not valid JSON: $($_.Exception.Message)" }
    if ($proposal -isnot [Collections.IDictionary] -or -not $proposal.Contains('selected') -or -not $proposal.Contains('skipped') -or
        $proposal.selected -isnot [System.Array] -or $proposal.skipped -isnot [System.Array]) {
        throw 'AgendaJson must contain selected and skipped arrays.'
    }
    $SelectedLens = @($proposal.selected | ForEach-Object { if ($_ -is [Collections.IDictionary] -and $_.Contains('lens')) { [string]$_['lens'] } else { '' } })
    $SelectedDepth = @($proposal.selected | ForEach-Object { if ($_ -is [Collections.IDictionary] -and $_.Contains('depth')) { [string]$_['depth'] } else { '' } })
    $SelectedDecision = @($proposal.selected | ForEach-Object { if ($_ -is [Collections.IDictionary] -and $_.Contains('decision')) { [string]$_['decision'] } else { '' } })
    $SkippedLens = @($proposal.skipped | ForEach-Object { if ($_ -is [Collections.IDictionary] -and $_.Contains('lens')) { [string]$_['lens'] } else { '' } })
    $SkippedReason = @($proposal.skipped | ForEach-Object { if ($_ -is [Collections.IDictionary] -and $_.Contains('reason')) { [string]$_['reason'] } else { '' } })
}

if (@($SelectedLens).Count -eq 0) { throw 'At least one technical lens must be selected.' }
if ($SelectedLens.Count -ne $SelectedDepth.Count -or $SelectedLens.Count -ne $SelectedDecision.Count) {
    throw 'SelectedLens, SelectedDepth, and SelectedDecision must have the same number of entries.'
}
if ($SkippedLens.Count -ne $SkippedReason.Count) {
    throw 'SkippedLens and SkippedReason must have the same number of entries.'
}

$featureRoot = Join-Path (Join-Path $resolvedProjectRoot 'specs') $FeatureRef
$statePath = Join-Path $featureRoot 'lens-applicability.json'
if (-not (Test-Path -LiteralPath $statePath -PathType Leaf)) {
    throw "The feature's workshop progress record is missing: '$statePath'."
}
$state = Get-Content -LiteralPath $statePath -Raw -Encoding UTF8 -ErrorAction Stop | ConvertFrom-Json -Depth 20 -ErrorAction Stop
if ([string]$state.agenda_contract -cne 'complete-coverage-v1' -or [string]$state.agenda_status -cne 'pending-confirmation') {
    throw (New-SpecrewWorkshopAgendaRefusal -Summary 'The technical agenda can only be confirmed while this feature is awaiting agenda confirmation.' `
        -Action 'Resume the feature from its saved workshop progress. Do not replace saved decisions.')
}
$transitionOperation = if ($RenderOnly) { 'render-agenda' } else { 'confirm-agenda' }
$transition = Resolve-SpecrewWorkshopStateTransition -Controller $state -Operation $transitionOperation
if (-not $transition.allowed) {
    throw (New-SpecrewWorkshopAgendaRefusal -Summary 'This feature''s saved workshop progress includes technical decisions before the agenda was confirmed, so the agenda cannot be replaced safely.' `
        -Action 'Propose the governed workshop repair described in the design-workshop skill. It preserves saved product answers and requires typed human approval before changing the unfinished agenda.')
}
if ([string]$state.human_turn_contract -cne 'typed-turns-v1') {
    throw 'The feature workshop cannot prove a typed human reply for this agenda.'
}
$productReceipt = Get-SpecrewWorkshopAuthorityReceipt -ProjectRoot $resolvedProjectRoot -FeatureRef $FeatureRef -Phase 'product-domain'
if ($null -eq $productReceipt -or [string]$productReceipt.confirmation -eq 'invalid') {
    throw (New-SpecrewWorkshopAgendaRefusal -Summary 'Product-domain has no typed human reply receipt.' `
        -Action 'Re-render its question as prose once and wait for a typed answer.')
}
$missingProductRecords = [Collections.Generic.List[string]]::new()
foreach ($relativeProductRecord in @('workshop/product-domain.md', 'workshop/product-domain.yml')) {
    if (-not (Test-Path -LiteralPath (Join-Path $featureRoot $relativeProductRecord) -PathType Leaf)) {
        $missingProductRecords.Add($relativeProductRecord) | Out-Null
    }
}
if ($missingProductRecords.Count -gt 0) {
    throw (New-SpecrewWorkshopAgendaRefusal `
        -Summary ('The product-domain records must be persisted before the technical agenda can be rendered or confirmed. Missing: {0}.' -f ($missingProductRecords -join ', ')) `
        -Action 'Persist both product-domain records from the typed answer already on record, validate them, then run this same agenda command with -RenderOnly once.')
}
$catalogPath = Join-Path $resolvedProjectRoot '.specify/extensions/specrew-speckit/knowledge/design-lenses/index.yml'
if (-not (Test-Path -LiteralPath $catalogPath -PathType Leaf)) {
    throw "Design-lens catalog is missing: '$catalogPath'."
}
$yamlReader = Join-Path $PSScriptRoot 'intake/helpers/Read-IntakeYaml.ps1'
if (-not (Test-Path -LiteralPath $yamlReader -PathType Leaf)) { throw "Design-lens catalog parser is missing: '$yamlReader'." }
. $yamlReader
$catalog = @(Read-IntakeYamlDocument -Path $catalogPath -Kind lenses | ForEach-Object { [string]$_.id } | Where-Object { $_ -and -not (Test-SpecrewWorkshopIntakeLens -Lens $_) })
if ($catalog.Count -eq 0) { throw 'The design-lens catalog contains no technical lenses.' }

$selectedSet = [Collections.Generic.HashSet[string]]::new([StringComparer]::Ordinal)
$skippedSet = [Collections.Generic.HashSet[string]]::new([StringComparer]::Ordinal)
$agenda = [ordered]@{}
$skipped = [ordered]@{}
for ($i = 0; $i -lt $SelectedLens.Count; $i++) {
    $lens = [string]$SelectedLens[$i]
    $depth = [string]$SelectedDepth[$i]
    $decision = [string]$SelectedDecision[$i]
    if ($lens -cnotmatch '^[a-z][a-z0-9-]{1,63}$' -or -not $selectedSet.Add($lens)) {
        throw "Selected lens '$lens' is malformed or duplicated."
    }
    if ($depth -cnotin @('full', 'medium', 'light')) { throw "Selected lens '$lens' has invalid depth '$depth'." }
    if ([string]::IsNullOrWhiteSpace($decision)) { throw "Selected lens '$lens' needs the concrete decision it raises." }
    $agenda[$lens] = [ordered]@{ depth = $depth; decision = $decision.Trim() }
}
for ($i = 0; $i -lt $SkippedLens.Count; $i++) {
    $lens = [string]$SkippedLens[$i]
    $reason = [string]$SkippedReason[$i]
    if ($lens -cnotmatch '^[a-z][a-z0-9-]{1,63}$' -or -not $skippedSet.Add($lens)) {
        throw "Skipped lens '$lens' is malformed or duplicated."
    }
    if ($selectedSet.Contains($lens)) { throw "Lens '$lens' cannot be both selected and skipped." }
    if ([string]::IsNullOrWhiteSpace($reason)) { throw "Skipped lens '$lens' needs a visible reason." }
    $skipped[$lens] = $reason.Trim()
}

$catalogSet = [Collections.Generic.HashSet[string]]::new([StringComparer]::Ordinal)
foreach ($lens in $catalog) { [void]$catalogSet.Add($lens) }
$unknown = @(($SelectedLens + $SkippedLens) | Where-Object { -not $catalogSet.Contains([string]$_) })
if ($unknown.Count -gt 0) { throw ('Unknown technical lens(es): {0}.' -f ($unknown -join ', ')) }
$missing = @($catalog | Where-Object { -not $selectedSet.Contains($_) -and -not $skippedSet.Contains($_) })
if ($missing.Count -gt 0) {
    throw ('Every technical lens must be selected or visibly skipped with a reason. Missing: {0}.' -f ($missing -join ', '))
}

$canonicalAgendaText = Get-CanonicalWorkshopAgendaText -Agenda $agenda -Skipped $skipped
$agendaBinding = ConvertTo-SpecrewWorkshopAgendaBinding -Agenda $agenda -Skipped $skipped
$agendaDigest = Get-SpecrewWorkshopAgendaDigest -Binding $agendaBinding
$proposalPath = Join-Path $resolvedProjectRoot '.specrew/handover/workshop-agenda-proposal.json'
if ($RenderOnly) {
    $proposal = [ordered]@{
        schema_version = '1.0'
        feature_ref = $FeatureRef
        lens = 'product-domain'
        agenda_digest = $agendaDigest
        agenda_binding = $agendaBinding
        canonical_text = $canonicalAgendaText
        recorded_at = [DateTimeOffset]::UtcNow.ToString('o')
    }
    $proposalDir = Split-Path -Parent $proposalPath
    if (-not (Test-Path -LiteralPath $proposalDir -PathType Container)) {
        New-Item -ItemType Directory -Path $proposalDir -Force | Out-Null
    }
    Write-AtomicUtf8NoBom -Path $proposalPath -Content (($proposal | ConvertTo-Json -Depth 10) + [Environment]::NewLine)
    Write-Output $canonicalAgendaText
    exit 0
}
$agendaReceipt = Get-SpecrewWorkshopAuthorityReceipt -ProjectRoot $resolvedProjectRoot -FeatureRef $FeatureRef -Phase 'agenda'
if ($null -eq $agendaReceipt -or [string]$agendaReceipt.confirmation -cne 'human-confirmed' -or
    [string]$agendaReceipt.confirmation_scope -cne 'lens-selection') {
    throw (New-SpecrewWorkshopAgendaRefusal -Summary 'The complete selected + skipped agenda has no typed human confirmation receipt.' `
        -Action 'Run this command with -RenderOnly once, send its complete output, and wait for a typed confirm or change reply.')
}
# SPECREW-AUTHORITY-CONSUMER: workshop-agenda-question-identity
$receiptDigestProperty = $agendaReceipt.PSObject.Properties['agenda_digest']
$receiptBindingProperty = $agendaReceipt.PSObject.Properties['agenda_binding']
if (-not $receiptDigestProperty -or -not $receiptBindingProperty -or $null -eq $receiptBindingProperty.Value) {
    throw (New-SpecrewWorkshopAgendaRefusal -Summary 'The typed agenda confirmation is not bound to agenda content.' `
        -Action 'Run this command with -RenderOnly once, send its complete output, and wait for one new typed reply.')
}
if ([string]$receiptDigestProperty.Value -cne $agendaDigest) {
    $changedLenses = @(Get-SpecrewWorkshopAgendaChangedLenses -ExpectedBinding $receiptBindingProperty.Value -ActualBinding $agendaBinding)
    $changedLabel = if ($changedLenses.Count -gt 0) { $changedLenses -join ', ' } else { '(content digest changed)' }
    throw (New-SpecrewWorkshopAgendaRefusal -Summary ("The agenda decisions changed after the human reply. Changed lenses: {0}." -f $changedLabel) `
        -Action 'Render the current complete agenda once with -RenderOnly and wait for a new typed confirmation.')
}

$confirmed = [ordered]@{
    schema_version            = '1.1'
    workshop_intake           = $true
    confirmation_required     = $true
    agenda_contract           = 'complete-coverage-v1'
    human_turn_contract       = 'typed-turns-v1'
    agenda_status             = 'confirmed'
    selected                  = @($SelectedLens)
    agenda                    = $agenda
    skipped                   = $skipped
    agenda_confirmation       = $Confirmation
    agenda_confirmation_scope = 'lens-selection'
    agenda_turn_receipt       = [string]$agendaReceipt.receipt_id
    agenda_digest             = $agendaDigest
    workshop                  = [ordered]@{}
}
Write-AtomicUtf8NoBom -Path $statePath -Content (($confirmed | ConvertTo-Json -Depth 10) + [Environment]::NewLine)
if (Test-Path -LiteralPath $proposalPath -PathType Leaf) {
    Remove-Item -LiteralPath $proposalPath -Force -ErrorAction SilentlyContinue
}

if ($PassThru) {
    [pscustomobject]@{
        feature_ref = $FeatureRef
        state = 'confirmed'
        selected_count = $SelectedLens.Count
        skipped_count = $SkippedLens.Count
        artifact_path = $statePath
    }
}
