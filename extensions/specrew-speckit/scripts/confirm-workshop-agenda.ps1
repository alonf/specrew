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

function Get-WorkshopAgendaQuestionHash {
    param(
        [Parameter(Mandatory)][string]$FeatureRef,
        [AllowEmptyString()][string]$CurrentLens,
        [Parameter(Mandatory)][string]$Text
    )
    return Get-SpecrewWorkshopAuthorityHash -Text ('feature|' + $FeatureRef + '||' + $CurrentLens + '|' + $Text)
}

$resolvedProjectRoot = [IO.Path]::GetFullPath($ProjectRoot).TrimEnd(
    [IO.Path]::DirectorySeparatorChar,
    [IO.Path]::AltDirectorySeparatorChar
)
if (-not (Test-Path -LiteralPath (Join-Path $resolvedProjectRoot '.specrew/config.yml') -PathType Leaf)) {
    throw 'Workshop agenda confirmation requires a Specrew-governed project.'
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
    throw "Workshop controller state is missing: '$statePath'."
}
$state = Get-Content -LiteralPath $statePath -Raw -Encoding UTF8 -ErrorAction Stop | ConvertFrom-Json -Depth 20 -ErrorAction Stop
if ([string]$state.agenda_contract -cne 'complete-coverage-v1' -or [string]$state.agenda_status -cne 'pending-confirmation') {
    throw 'The workshop agenda can only be confirmed from the complete-coverage-v1 pending-confirmation state.'
}
if (@($state.selected).Count -ne 0 -or @($state.workshop.PSObject.Properties).Count -ne 0) {
    throw 'The pending workshop controller already contains decisions; refusing to overwrite it.'
}
if ([string]$state.human_turn_contract -cne 'typed-turns-v1') {
    throw 'The workshop controller does not carry the typed-turn authority contract.'
}
$authorityStorePath = Join-Path $PSScriptRoot 'workshop-authority-store.ps1'
if (-not (Test-Path -LiteralPath $authorityStorePath -PathType Leaf)) {
    throw "Workshop typed-turn authority helper is missing: '$authorityStorePath'."
}
. $authorityStorePath
$productReceipt = Get-SpecrewWorkshopAuthorityReceipt -ProjectRoot $resolvedProjectRoot -FeatureRef $FeatureRef -Phase 'product-domain'
if ($null -eq $productReceipt -or [string]$productReceipt.confirmation -eq 'invalid') {
    throw 'Product-domain has no typed human reply receipt. Re-render its question as prose and wait for a typed answer.'
}
$catalogPath = Join-Path $resolvedProjectRoot '.specify/extensions/specrew-speckit/knowledge/design-lenses/index.yml'
if (-not (Test-Path -LiteralPath $catalogPath -PathType Leaf)) {
    throw "Design-lens catalog is missing: '$catalogPath'."
}
$yamlReader = Join-Path $PSScriptRoot 'intake/helpers/Read-IntakeYaml.ps1'
if (-not (Test-Path -LiteralPath $yamlReader -PathType Leaf)) { throw "Design-lens catalog parser is missing: '$yamlReader'." }
. $yamlReader
$catalog = @(Read-IntakeYamlDocument -Path $catalogPath -Kind lenses | ForEach-Object { [string]$_.id } | Where-Object { $_ -and $_ -cne 'product-domain' })
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
if ($RenderOnly) {
    Write-Output $canonicalAgendaText
    exit 0
}
$agendaReceipt = Get-SpecrewWorkshopAuthorityReceipt -ProjectRoot $resolvedProjectRoot -FeatureRef $FeatureRef -Phase 'agenda'
if ($null -eq $agendaReceipt -or [string]$agendaReceipt.confirmation -cne 'human-confirmed' -or
    [string]$agendaReceipt.confirmation_scope -cne 'lens-selection') {
    throw 'The complete selected + skipped agenda has no typed human confirmation receipt. Render it in full and wait for a typed confirm/change reply.'
}
# During pending-confirmation the strict controller projects product-domain as the current
# lens; it does not persist a current_lens field in the pre-agenda JSON. Bind to the same
# value the conformance provider used when it hashed the rendered agenda question.
$currentLens = 'product-domain'
# SPECREW-AUTHORITY-CONSUMER: workshop-agenda-question-identity
$expectedQuestionHash = Get-WorkshopAgendaQuestionHash -FeatureRef $FeatureRef -CurrentLens $currentLens -Text $canonicalAgendaText
if ([string]$agendaReceipt.question_hash -cne $expectedQuestionHash) {
    throw 'The typed agenda confirmation belongs to different agenda text. Render this exact agenda with -RenderOnly, wait for a typed reply, then confirm without changing selected or skipped lenses.'
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
    workshop                  = [ordered]@{}
}
Write-AtomicUtf8NoBom -Path $statePath -Content (($confirmed | ConvertTo-Json -Depth 10) + [Environment]::NewLine)

if ($PassThru) {
    [pscustomobject]@{
        feature_ref = $FeatureRef
        state = 'confirmed'
        selected_count = $SelectedLens.Count
        skipped_count = $SkippedLens.Count
        artifact_path = $statePath
    }
}
