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

$catalogPath = Join-Path $resolvedProjectRoot '.specify/extensions/specrew-speckit/knowledge/design-lenses/index.yml'
if (-not (Test-Path -LiteralPath $catalogPath -PathType Leaf)) {
    throw "Design-lens catalog is missing: '$catalogPath'."
}
$catalog = @(
    Get-Content -LiteralPath $catalogPath -Encoding UTF8 -ErrorAction Stop |
        ForEach-Object {
            if ($_ -cmatch '^\s*-\s+id:\s*([a-z][a-z0-9-]{1,63})\s*$') { $Matches[1] }
        } |
        Where-Object { $_ -and $_ -cne 'product-domain' }
)
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

$confirmed = [ordered]@{
    schema_version            = '1.1'
    workshop_intake           = $true
    confirmation_required     = $true
    agenda_contract           = 'complete-coverage-v1'
    agenda_status             = 'confirmed'
    selected                  = @($SelectedLens)
    agenda                    = $agenda
    skipped                   = $skipped
    agenda_confirmation       = $Confirmation
    agenda_confirmation_scope = 'lens-selection'
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
