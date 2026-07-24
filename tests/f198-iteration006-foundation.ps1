#requires -Version 7.0
[CmdletBinding()]
param([switch]$RecordEvidence)

$ErrorActionPreference = 'Stop'
Set-StrictMode -Version Latest

$repoRoot = (Resolve-Path (Join-Path $PSScriptRoot '..')).Path
$suitePaths = @(
    'tests/continuous-co-review/unit/review-authority-cutover.Tests.ps1'
    'tests/continuous-co-review/unit/review-authority-core.Tests.ps1'
    'tests/continuous-co-review/unit/review-authority-store.Tests.ps1'
    'tests/continuous-co-review/unit/review-target-port.Tests.ps1'
    'tests/continuous-co-review/unit/review-result-ingestor.Tests.ps1'
    'tests/continuous-co-review/unit/review-campaign-orchestrator.Tests.ps1'
    'tests/continuous-co-review/unit/co-review-service.Tests.ps1'
    'tests/continuous-co-review/unit/continuous-co-review-navigator.Tests.ps1'
) | ForEach-Object { Join-Path $repoRoot $_ }

$missing = @($suitePaths | Where-Object { -not (Test-Path -LiteralPath $_ -PathType Leaf) })
if ($missing.Count -gt 0) { throw ('foundation-suite-missing:' + ($missing -join ',')) }

$started = [Diagnostics.Stopwatch]::StartNew()
$result = Invoke-Pester -Path $suitePaths -Output Detailed -PassThru
$started.Stop()

$summary = [pscustomobject][ordered]@{
    schema_version = '1.0'
    suite = 'f198-iteration006-foundation'
    passed = [int]$result.PassedCount
    failed = [int]$result.FailedCount
    skipped = [int]$result.SkippedCount
    duration_seconds = [Math]::Round($started.Elapsed.TotalSeconds, 3)
    git_head = [string](& git -C $repoRoot rev-parse HEAD)
    suites = @($suitePaths | ForEach-Object { [IO.Path]::GetRelativePath($repoRoot, $_).Replace('\', '/') })
}

if ($RecordEvidence) {
    . (Join-Path $repoRoot 'scripts/internal/continuous-co-review/test-evidence-recorder.ps1')
    $record = Write-ContinuousCoReviewTestEvidence -RepoRoot $repoRoot -Suite $summary.suite -Passed $summary.passed -Failed $summary.failed -Skipped $summary.skipped -ExitCode ([int]($summary.failed -gt 0)) -DurationSeconds $summary.duration_seconds -Command 'pwsh -NoProfile -File tests/f198-iteration006-foundation.ps1 -RecordEvidence'
    $summary | Add-Member -NotePropertyName evidence_recorded -NotePropertyValue ($null -ne $record)
    if ($null -ne $record) { $summary | Add-Member -NotePropertyName reviewed_digest_tree_id -NotePropertyValue ([string]$record.reviewed_digest_tree_id) }
}

Write-Host ('FOUNDATION_RESULT_JSON=' + ($summary | ConvertTo-Json -Depth 6 -Compress))
exit [int]($result.FailedCount -gt 0)
