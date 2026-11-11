<#
Feature 206, T005 (FR-008a, design condition 1): every iteration's closed/open answer under today's three rules
and the new definition, before T006 changes anything. Read-only: it dot-sources the validator's shared library
and the dashboard renderer and calls their own functions; it writes only the Markdown file given by -OutFile.

  index      .specrew/closed-iterations.yml has the iteration (Get-SpecrewClosedIterationIndex)
  heuristic  state.md text heuristic (Get-SpecrewClosedIterationFromStateFile)
  validator  what the nightly's unscoped closed filter skips today: index OR heuristic
  renderer   the dashboard renderer's is_closed, which the dashboard check reads (Get-SpecrewFeatureRecords)
  new        the D3 definition: index OR canonical Iteration Status complete/abandoned; a frozen entry is
             "frozen" (judged by no check, not closed)
#>
param(
    [string]$ProjectRoot = (Resolve-Path (Join-Path $PSScriptRoot '..\..\..\..')).Path,
    [Parameter(Mandatory = $true)][string]$OutFile
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

. (Join-Path $ProjectRoot 'extensions\specrew-speckit\scripts\shared-governance.ps1')
. (Join-Path $ProjectRoot 'scripts\internal\dashboard-renderer.ps1')

# The frozen list's 18 entries as FR-006/data-model name them (the list itself is written by T007).
$frozenKeys = @(
    '048/001', '197/001', '198/008',
    '141/006', '141/007', '141/008', '174/006', '174/008', '174/009', '174/010', '174/011',
    '182/002', '182/003', '182/004', '197/003', '197/004', '197/005', '198/003'
)

$index = Get-SpecrewClosedIterationIndex -ProjectRoot $ProjectRoot

$rendererClosed = @{}
foreach ($feature in @(Get-SpecrewFeatureRecords -ProjectRoot $ProjectRoot)) {
    foreach ($iteration in @($feature.closed_iterations)) {
        $key = '{0}/{1}' -f (Split-Path -Leaf (Split-Path -Parent (Split-Path -Parent $iteration.iteration_directory))), (Split-Path -Leaf $iteration.iteration_directory)
        $rendererClosed[$key] = $true
    }
}

function Get-CanonicalIterationStatus {
    param([string]$StatePath)
    if (-not (Test-Path -LiteralPath $StatePath -PathType Leaf)) { return '' }
    $lines = @(Get-Content -LiteralPath $StatePath -Encoding UTF8)
    $value = Get-MarkdownMetadataValue -Lines $lines -Label 'Iteration Status'
    if ($null -eq $value) { return '' }
    return ((Normalize-MarkdownCell $value) -replace '`', '').Trim()
}

$rows = New-Object System.Collections.Generic.List[object]
foreach ($iterationDir in @(Get-ChildItem -Path (Join-Path $ProjectRoot 'specs\*\iterations\*') -Directory | Sort-Object FullName)) {
    $featureDir = Split-Path -Leaf (Split-Path -Parent (Split-Path -Parent $iterationDir.FullName))
    $iterationRef = $iterationDir.Name
    $key = "$featureDir/$iterationRef"
    $shortKey = '{0}/{1}' -f ($featureDir -replace '^(\d+).*$', '$1'), $iterationRef
    $statePath = Join-Path $iterationDir.FullName 'state.md'

    $inIndex = $index.ContainsKey($key)
    $byHeuristic = $null -ne (Get-SpecrewClosedIterationFromStateFile -StatePath $statePath)
    $validatorClosed = $inIndex -or $byHeuristic
    $byRenderer = $rendererClosed.ContainsKey($key)
    $status = Get-CanonicalIterationStatus -StatePath $statePath
    $isFrozen = $frozenKeys -contains $shortKey
    $new = if ($isFrozen) { 'frozen' } elseif ($inIndex -or $status.ToLowerInvariant() -in @('complete', 'abandoned')) { 'closed' } else { 'open' }

    $newClosed = $new -eq 'closed'
    $changes = New-Object System.Collections.Generic.List[string]
    if ($new -ne 'frozen') {
        if ($newClosed -ne $validatorClosed) { $changes.Add($(if ($newClosed) { 'validator: open -> closed' } else { 'validator: closed -> open' })) }
        if ($newClosed -ne $byRenderer) { $changes.Add($(if ($newClosed) { 'renderer: open -> closed' } else { 'renderer: closed -> open' })) }
    }
    else {
        if ($validatorClosed) { $changes.Add('validator: closed -> frozen') } else { $changes.Add('validator: open -> frozen') }
        if ($byRenderer) { $changes.Add('renderer: closed -> frozen') } else { $changes.Add('renderer: open -> frozen') }
    }

    $rows.Add([pscustomobject]@{
            Key       = $key
            Status    = $(if ([string]::IsNullOrWhiteSpace($status)) { '(none)' } elseif ($status.Length -gt 40) { $status.Substring(0, 37) + '...' } else { $status })
            Index     = $inIndex
            Heuristic = $byHeuristic
            Validator = $validatorClosed
            Renderer  = $byRenderer
            New       = $new
            Changes   = ($changes -join '; ')
        }) | Out-Null
}

function Format-Answer { param([bool]$Closed) if ($Closed) { 'closed' } else { 'open' } }
function Format-Cell { param([string]$Text) ($Text -replace '\|', '\|') }

$changed = @($rows | Where-Object { -not [string]::IsNullOrWhiteSpace($_.Changes) })
$lines = New-Object System.Collections.Generic.List[string]
$lines.Add('| Iteration | Iteration Status | Index | Heuristic | Validator today | Renderer today | New | Change |') | Out-Null
$lines.Add('| --- | --- | --- | --- | --- | --- | --- | --- |') | Out-Null
foreach ($row in $rows) {
    $lines.Add(('| {0} | {1} | {2} | {3} | {4} | {5} | {6} | {7} |' -f $row.Key, (Format-Cell $row.Status),
            (Format-Answer $row.Index), (Format-Answer $row.Heuristic), (Format-Answer $row.Validator),
            (Format-Answer $row.Renderer), $row.New, $(if ($row.Changes) { $row.Changes } else { '-' }))) | Out-Null
}

$summary = [pscustomobject]@{
    Total            = $rows.Count
    NewClosed        = @($rows | Where-Object New -eq 'closed').Count
    NewOpen          = @($rows | Where-Object New -eq 'open').Count
    Frozen           = @($rows | Where-Object New -eq 'frozen').Count
    ChangedIterations = $changed.Count
}
[System.IO.File]::WriteAllText($OutFile, (($lines.ToArray()) -join "`n") + "`n", [System.Text.UTF8Encoding]::new($false))
$summary
$changed | Select-Object Key, Status, Index, Heuristic, Renderer, New, Changes
