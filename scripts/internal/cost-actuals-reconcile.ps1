# Provider-billing reconciliation primitives (F-042 FR-014 / FR-015 / FR-016)
#
# MVP scope (per FR-016): reporting only — does NOT auto-apply calibration
# factors. Calibration write-back is reserved for Proposal 106.
#
# DRAFT — pre-staged 2026-05-23. Pending F-041 + F-042 merge + plan-boundary
# verdict before production wiring.

Set-StrictMode -Version Latest

function Get-SpecrewActualsPath {
    param(
        [Parameter(Mandatory = $true)][string]$ProjectPath,
        [Parameter(Mandatory = $true)][string]$Provider,
        [Parameter(Mandatory = $true)][string]$Month
    )
    return (Join-Path $ProjectPath ".specrew\actuals\$Provider-$Month.yml")
}

function Import-SpecrewActualsFromAnthropic {
    <#
    .SYNOPSIS
    Parse an Anthropic billing CSV export (downloaded from console.anthropic.com).

    .DESCRIPTION
    MVP per FR-014: Anthropic first. Expected CSV header columns:
    timestamp,model,input_tokens,output_tokens,charged_usd,api_key_name
    (Anthropic's exact column names may vary; helper is parameterized to
    accept the user's actual export format.)

    Stores parsed records at .specrew/actuals/anthropic-<YYYY-MM>.yml in
    Specrew canonical schema.
    #>
    param(
        [Parameter(Mandatory = $true)][string]$ProjectPath,
        [Parameter(Mandatory = $true)][string]$CsvPath,
        [Parameter(Mandatory = $true)][string]$Month   # YYYY-MM
    )

    if (-not (Test-Path -LiteralPath $CsvPath -PathType Leaf)) {
        throw "CSV file not found: $CsvPath"
    }

    $csv = Import-Csv -LiteralPath $CsvPath
    $records = @()
    foreach ($row in $csv) {
        # Normalize column names (Anthropic CSV varies slightly across regions/eras)
        $timestamp = $row.timestamp ?? $row.created_at ?? $row.date
        $model = $row.model ?? $row.model_id
        $inputTokens = [int]($row.input_tokens ?? $row.tokens_in ?? 0)
        $outputTokens = [int]($row.output_tokens ?? $row.tokens_out ?? 0)
        $chargedUsd = [double]($row.charged_usd ?? $row.amount ?? $row.cost ?? 0)
        $lineItemId = $row.id ?? $row.line_item_id ?? "anthropic-$timestamp-$model"

        $records += @{
            timestamp     = $timestamp
            model         = $model
            tokens_in     = $inputTokens
            tokens_out    = $outputTokens
            charged_usd   = $chargedUsd
            line_item_id  = $lineItemId
            provider      = 'anthropic'
        }
    }

    $actuals = @{
        actuals = @{
            schema_version = 1
            provider       = 'anthropic'
            month          = $Month
            imported_at    = [DateTime]::UtcNow.ToString('o')
            source_file    = $CsvPath
            record_count   = $records.Count
            total_charged_usd = ($records | ForEach-Object { $_.charged_usd } | Measure-Object -Sum).Sum
            records        = $records
        }
    }

    $outPath = Get-SpecrewActualsPath -ProjectPath $ProjectPath -Provider 'anthropic' -Month $Month
    $dir = Split-Path -Parent $outPath
    if (-not (Test-Path -LiteralPath $dir)) {
        $null = New-Item -ItemType Directory -Path $dir -Force
    }

    if (Get-Command ConvertTo-Yaml -ErrorAction SilentlyContinue) {
        $yaml = ConvertTo-Yaml -Data $actuals
        Write-Utf8FileAtomic -Path $outPath -Content $yaml
    }
    else {
        throw "ConvertTo-Yaml not available"
    }

    return [pscustomobject]@{
        Provider    = 'anthropic'
        Month       = $Month
        RecordCount = $records.Count
        TotalCharged = $actuals.actuals.total_charged_usd
        OutputPath  = $outPath
    }
}

function Get-SpecrewActuals {
    <#
    .SYNOPSIS
    Load actuals for a given provider + month.
    Returns $null if absent.
    #>
    param(
        [Parameter(Mandatory = $true)][string]$ProjectPath,
        [Parameter(Mandatory = $true)][string]$Provider,
        [Parameter(Mandatory = $true)][string]$Month
    )

    $path = Get-SpecrewActualsPath -ProjectPath $ProjectPath -Provider $Provider -Month $Month
    if (-not (Test-Path -LiteralPath $path -PathType Leaf)) { return $null }

    try {
        $raw = Get-Content -LiteralPath $path -Raw -Encoding UTF8
        if (Get-Command ConvertFrom-Yaml -ErrorAction SilentlyContinue) {
            return (ConvertFrom-Yaml -Yaml $raw)
        }
        throw "ConvertFrom-Yaml not available"
    }
    catch {
        Write-Warning "Could not read actuals at $path : $($_.Exception.Message)"
        return $null
    }
}

function Invoke-SpecrewCostReconcile {
    <#
    .SYNOPSIS
    Reconciliation report (FR-015) — compare Specrew's estimated cost from
    cost.yml records against provider actuals.

    .DESCRIPTION
    Aggregates all cost.yml records in scope (by month or by feature), groups
    by model, sums estimated cost; loads matching actuals; computes deltas
    and per-model accuracy ratios.

    Reporting only — does NOT write calibration factors back (per FR-016).
    Surfaces suggestions for models where accuracy is consistently off >5%.

    .PARAMETER Month
    Restrict to records in this YYYY-MM. If omitted, all-time.

    .PARAMETER Feature
    Restrict to records in this feature. If omitted, all features.
    #>
    param(
        [Parameter(Mandatory = $true)][string]$ProjectPath,
        [string]$Month,
        [string]$Feature
    )

    # Gather estimated records from cost.yml across iterations
    $estimatedRecords = @()
    $featuresPath = Join-Path $ProjectPath 'specs'
    if (-not (Test-Path -LiteralPath $featuresPath -PathType Container)) {
        return @{ error = "No specs/ directory; nothing to reconcile" }
    }

    $featureDirs = if ([string]::IsNullOrWhiteSpace($Feature)) {
        Get-ChildItem -Path $featuresPath -Directory
    } else {
        @(Get-Item (Join-Path $featuresPath $Feature) -ErrorAction SilentlyContinue) | Where-Object { $null -ne $_ }
    }

    foreach ($fdir in $featureDirs) {
        $iterPath = Join-Path $fdir.FullName 'iterations'
        if (-not (Test-Path -LiteralPath $iterPath)) { continue }
        foreach ($iter in (Get-ChildItem -Path $iterPath -Directory)) {
            $cost = Get-SpecrewCostYml -ProjectPath $ProjectPath -Feature $fdir.Name -Iteration $iter.Name
            if ($null -eq $cost) { continue }
            foreach ($r in $cost.cost.records) {
                if (-not [string]::IsNullOrWhiteSpace($Month)) {
                    $rTimestamp = [string]$r['timestamp']
                    if (-not $rTimestamp.StartsWith($Month)) { continue }
                }
                $estimatedRecords += $r
            }
        }
    }

    # Aggregate by model
    $estimatedByModel = @{}
    foreach ($r in $estimatedRecords) {
        $m = [string]$r['model']
        if (-not $estimatedByModel.ContainsKey($m)) {
            $estimatedByModel[$m] = @{ total_cost_usd = 0.0; tokens_in = 0; tokens_out = 0; record_count = 0 }
        }
        $estimatedByModel[$m]['total_cost_usd'] += [double]($r['estimated_cost_usd'] ?? 0)
        $estimatedByModel[$m]['tokens_in'] += [int]($r['tokens_in'] ?? 0)
        $estimatedByModel[$m]['tokens_out'] += [int]($r['tokens_out'] ?? 0)
        $estimatedByModel[$m]['record_count'] += 1
    }

    # Load actuals for the month (try all known providers)
    $actualsByModel = @{}
    if (-not [string]::IsNullOrWhiteSpace($Month)) {
        foreach ($provider in 'anthropic', 'copilot', 'codex', 'google') {
            $actuals = Get-SpecrewActuals -ProjectPath $ProjectPath -Provider $provider -Month $Month
            if ($null -eq $actuals) { continue }
            foreach ($r in $actuals.actuals.records) {
                $m = [string]$r['model']
                if (-not $actualsByModel.ContainsKey($m)) {
                    $actualsByModel[$m] = @{ total_charged_usd = 0.0; tokens_in = 0; tokens_out = 0; line_item_count = 0 }
                }
                $actualsByModel[$m]['total_charged_usd'] += [double]($r['charged_usd'] ?? 0)
                $actualsByModel[$m]['tokens_in'] += [int]($r['tokens_in'] ?? 0)
                $actualsByModel[$m]['tokens_out'] += [int]($r['tokens_out'] ?? 0)
                $actualsByModel[$m]['line_item_count'] += 1
            }
        }
    }

    # Compute per-model accuracy + suggested calibration factors
    $accuracy = @()
    $allModels = @($estimatedByModel.Keys + $actualsByModel.Keys) | Sort-Object -Unique
    $totalEstimated = 0.0
    $totalActual = 0.0
    foreach ($m in $allModels) {
        $est = if ($estimatedByModel.ContainsKey($m)) { $estimatedByModel[$m]['total_cost_usd'] } else { 0.0 }
        $act = if ($actualsByModel.ContainsKey($m)) { $actualsByModel[$m]['total_charged_usd'] } else { 0.0 }
        $totalEstimated += $est
        $totalActual += $act

        $ratio = if ($act -gt 0) { $est / $act } else { $null }
        $calibrationSuggestion = if ($null -ne $ratio -and ([Math]::Abs(1 - $ratio) -gt 0.05)) {
            "naive × $('{0:F4}' -f (1 / $ratio))"
        } else { $null }

        $accuracy += @{
            model                  = $m
            estimated_usd          = [Math]::Round($est, 4)
            actual_usd             = [Math]::Round($act, 4)
            delta_usd              = [Math]::Round($est - $act, 4)
            estimator_ratio        = if ($null -ne $ratio) { [Math]::Round($ratio, 4) } else { $null }
            estimator_accuracy_pct = if ($null -ne $ratio) { [Math]::Round($ratio * 100, 1) } else { $null }
            calibration_suggestion = $calibrationSuggestion
        }
    }

    $overallConfidence = if ($totalActual -gt 0) {
        # confidence = 1 - |estimated_total - actual_total| / actual_total
        $deltaRatio = [Math]::Abs($totalEstimated - $totalActual) / $totalActual
        [Math]::Round((1 - $deltaRatio) * 100, 1)
    } else { $null }

    return @{
        scope = @{
            month   = $Month
            feature = $Feature
        }
        totals = @{
            estimated_usd = [Math]::Round($totalEstimated, 4)
            actual_usd    = [Math]::Round($totalActual, 4)
            delta_usd     = [Math]::Round($totalEstimated - $totalActual, 4)
            confidence    = $overallConfidence
        }
        per_model_accuracy = $accuracy
        notes = "F-042 v1: reporting only. Calibration factors are SUGGESTIONS; auto-apply ships with Proposal 106."
    }
}

function Format-SpecrewReconcileReport {
    <#
    .SYNOPSIS
    Format the reconciliation report from Invoke-SpecrewCostReconcile as a
    readable console table.
    #>
    param([Parameter(Mandatory = $true)][hashtable]$Report)

    if ($Report.ContainsKey('error')) {
        return $Report['error']
    }

    $sb = New-Object System.Text.StringBuilder

    $scope = $Report['scope']
    $totals = $Report['totals']
    [void]$sb.AppendLine("Reconciliation report (scope: month=$($scope['month'] ?? 'all-time'), feature=$($scope['feature'] ?? 'all'))")
    [void]$sb.AppendLine('')
    [void]$sb.AppendLine(("  Estimated (Specrew):  `${0:F2}" -f $totals['estimated_usd']))
    [void]$sb.AppendLine(("  Provider billed:      `${0:F2}" -f $totals['actual_usd']))
    [void]$sb.AppendLine(("  Delta:                `${0:F2}" -f $totals['delta_usd']))
    if ($null -ne $totals['confidence']) {
        [void]$sb.AppendLine(("  Confidence:           {0}%" -f $totals['confidence']))
    }
    [void]$sb.AppendLine('')

    if ($Report['per_model_accuracy'].Count -eq 0) {
        [void]$sb.AppendLine('No per-model data — both estimated and actuals are empty.')
        return $sb.ToString()
    }

    [void]$sb.AppendLine('Per-model accuracy:')
    [void]$sb.AppendLine('')
    [void]$sb.AppendLine('  MODEL                        ESTIMATED    ACTUAL     RATIO    CALIBRATION SUGGESTION')
    [void]$sb.AppendLine('  ---------------------------  ----------  ----------  -------  ----------------------')
    foreach ($a in $Report['per_model_accuracy']) {
        $ratio = if ($null -ne $a['estimator_ratio']) { ("{0:F3}" -f $a['estimator_ratio']) } else { '   n/a' }
        $cal = $a['calibration_suggestion'] ?? ''
        [void]$sb.AppendLine(("  {0,-27}  `${1,9:F2}  `${2,9:F2}  {3,7}  {4}" -f $a['model'], $a['estimated_usd'], $a['actual_usd'], $ratio, $cal))
    }

    [void]$sb.AppendLine('')
    [void]$sb.AppendLine("Note: $($Report['notes'])")

    return $sb.ToString()
}
