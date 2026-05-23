[CmdletBinding()]
param(
    [Parameter(Mandatory = $false, Position = 0)]
    [string]$Subcommand,

    [Parameter(Mandatory = $false)]
    [string]$ProjectPath = '.',

    [string]$Feature,
    [string]$Iteration,
    [int]$Last = 10,
    [int]$TokensIn,
    [int]$TokensOut,
    [string]$Model,
    [string]$Role,
    [string]$Boundary,
    [string]$HostKind,
    [string]$Note,
    [switch]$Json,
    [switch]$All,
    [switch]$Help,

    [Parameter(ValueFromRemainingArguments = $true)]
    [string[]]$CliArgs
)

# F-042 / Proposal 070: `specrew cost` CLI surface
#
# Three subcommands per spec FR-008/FR-009/FR-010:
#   - summary [--feature <F>] [--last N] [--json]
#   - add --feature <F> --iteration <N> --tokens-in N --tokens-out N [--model M] [--role R] [--boundary B] [--host K] [--note "..."]
#   - recompute [--feature <F> --iteration <N>] (or --all)
#
# DRAFT — pre-staged 2026-05-23. Pending F-040 + F-041 + F-042 merges.

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

$costTrackingHelperPath = Join-Path $PSScriptRoot 'internal/cost-tracking.ps1'
if (Test-Path -LiteralPath $costTrackingHelperPath -PathType Leaf) {
    . $costTrackingHelperPath
}

function Write-Pass { param([string]$M) Write-Host $M -ForegroundColor Green }
function Write-Info { param([string]$M) Write-Host $M -ForegroundColor Cyan }
function Write-WarningMsg { param([string]$M) Write-Host "WARN: $M" -ForegroundColor Yellow }
function Write-ErrorMsg { param([string]$M) Write-Host "ERROR: $M" -ForegroundColor Red }

function Show-CostUsage {
    @'
specrew cost - per-iteration cost tracking + dashboard rollups (F-042)

Usage:
  specrew cost summary [--feature <F>] [--last N] [--json]
  specrew cost add --feature <F> --iteration <N> --tokens-in N --tokens-out N [--model M] [--role R] [--boundary B] [--host K] [--note "..."]
  specrew cost recompute [--feature <F> --iteration <N>] (or --all)

Subcommands:
  summary    Rollup across recent iterations (default: last 10 closed)
  add        Append a source: manual cost record (from billing-page reconciliation)
  recompute  Re-estimate source: estimated records from current catalog;
             source: manual records are left unchanged

Options:
  --feature <F>          Feature slug (e.g., 040-multi-host-launch-path)
  --iteration <N>        Iteration number (e.g., 001)
  --last N               Number of recent iterations to include in summary (default: 10)
  --tokens-in N          Input tokens (for `add`)
  --tokens-out N         Output tokens (for `add`)
  --model <id>           Model id (for `add`; falls back to "unknown" if not provided)
  --role <name>          Crew role (for `add`)
  --boundary <name>      Boundary name (for `add`)
  --host <kind>          Host kind: copilot-cli / claude-code / codex-cli / antigravity (for `add`)
  --note "<text>"        Manual reconciliation note (for `add`)
  --json                 Emit JSON for downstream tooling (for `summary`)
  --all                  Recompute every iteration in the project (for `recompute`)
  --help                 Show this help
'@ | Write-Host
}

function Invoke-CostSummary {
    param(
        [string]$ResolvedProjectPath,
        [string]$Feature,
        [int]$Last = 10,
        [bool]$JsonOutput = $false
    )

    if (-not [string]::IsNullOrWhiteSpace($Feature)) {
        $rollup = Get-SpecrewCostAggregatesForFeature -ProjectPath $ResolvedProjectPath -Feature $Feature
        if ($null -eq $rollup) {
            Write-ErrorMsg "No cost data found for feature '$Feature'"
            exit 1
        }

        if ($JsonOutput) {
            $rollup | ConvertTo-Json -Depth 10
        }
        else {
            Write-Info "Feature: $Feature"
            Write-Info "Iterations: $($rollup.iteration_count)"
            Write-Info "Total cost: `$$($rollup.total_cost_usd) ($($rollup.total_story_points) SP)"
            Write-Info "Cost/SP: `$$($rollup.cost_per_sp_usd)"
            if ($rollup.by_host.Keys.Count -gt 0) {
                $hostLine = $rollup.by_host.Keys | ForEach-Object { "$_ `$$($rollup.by_host[$_]['cost_usd']) ($([int]($rollup.by_host[$_]['share'] * 100))%)" }
                Write-Info "By host: $($hostLine -join ' / ')"
            }
        }
        return
    }

    # No --feature: aggregate across all features, last N iterations
    $allFeatures = Get-ChildItem -Path (Join-Path $ResolvedProjectPath 'specs') -Directory -ErrorAction SilentlyContinue | Sort-Object Name -Descending
    $allIterations = @()
    foreach ($f in $allFeatures) {
        $iterPath = Join-Path $f.FullName 'iterations'
        if (-not (Test-Path -LiteralPath $iterPath)) { continue }
        $iters = Get-ChildItem -Path $iterPath -Directory | Sort-Object Name -Descending
        foreach ($iter in $iters) {
            $cost = Get-SpecrewCostYml -ProjectPath $ResolvedProjectPath -Feature $f.Name -Iteration $iter.Name
            if ($null -eq $cost) { continue }
            $allIterations += @{
                feature      = $f.Name
                iteration    = $iter.Name
                cost_usd     = [double]($cost.cost.aggregates['total_cost_usd'] ?? 0)
                cost_per_sp  = [double]($cost.cost.aggregates['cost_per_sp_usd'] ?? 0)
                sp           = [int]($cost.cost.story_points ?? 0)
                by_host      = $cost.cost.aggregates['by_host']
            }
            if ($allIterations.Count -ge $Last) { break }
        }
        if ($allIterations.Count -ge $Last) { break }
    }

    if ($allIterations.Count -eq 0) {
        Write-WarningMsg "No iteration cost data found yet."
        return
    }

    if ($JsonOutput) {
        @{ recent_iterations = $allIterations } | ConvertTo-Json -Depth 10
    }
    else {
        Write-Info "Last $($allIterations.Count) iterations across all features:"
        foreach ($i in $allIterations) {
            $hostShare = $i.by_host.Keys | ForEach-Object { "$_ $([int]($i.by_host[$_]['share'] * 100))%" }
            Write-Info ("  F-{0} / {1} — `${2:F2} (`${3:F2}/SP, {4} SP, {5})" -f $i.feature.Split('-')[0], $i.iteration, $i.cost_usd, $i.cost_per_sp, $i.sp, ($hostShare -join ' / '))
        }
        $totalCost = ($allIterations | ForEach-Object { $_.cost_usd } | Measure-Object -Sum).Sum
        $totalSp = ($allIterations | ForEach-Object { $_.sp } | Measure-Object -Sum).Sum
        Write-Info ("Total: `${0:F2} / `${1:F2}/SP average across {2} SP" -f $totalCost, $(if ($totalSp -gt 0) { $totalCost / $totalSp } else { 0 }), $totalSp)
    }
}

function Invoke-CostAdd {
    param(
        [string]$ResolvedProjectPath,
        [string]$Feature,
        [string]$Iteration,
        [int]$TokensIn,
        [int]$TokensOut,
        [string]$Model,
        [string]$Role,
        [string]$Boundary,
        [string]$HostKind,
        [string]$Note
    )

    foreach ($req in @('Feature', $Feature), @('Iteration', $Iteration), @('TokensIn', $TokensIn), @('TokensOut', $TokensOut)) {
        if ([string]::IsNullOrWhiteSpace($req[1]) -or $req[1] -eq 0) {
            Write-ErrorMsg "specrew cost add requires --$($req[0].ToLower()) <value>"
            exit 1
        }
    }

    $record = Add-SpecrewCostRecord `
        -ProjectPath $ResolvedProjectPath `
        -Feature $Feature `
        -Iteration $Iteration `
        -Boundary ($Boundary ?? 'manual') `
        -Role ($Role ?? 'unknown') `
        -Host ($HostKind ?? 'unknown') `
        -Model ($Model ?? 'unknown') `
        -TokensIn $TokensIn `
        -TokensOut $TokensOut `
        -Source 'manual' `
        -ManualNote $Note

    Write-Pass "Added manual cost record to specs/$Feature/iterations/$Iteration/cost.yml"
    Write-Info "Tokens: $TokensIn input / $TokensOut output"
    if ($null -ne $record.estimated_cost_usd) {
        Write-Info ("Computed cost: `${0:F4}" -f $record.estimated_cost_usd)
    }
    else {
        Write-WarningMsg "Cost is null (catalog missing or incomplete data for this model)"
    }
}

function Invoke-CostRecompute {
    param(
        [string]$ResolvedProjectPath,
        [string]$Feature,
        [string]$Iteration,
        [bool]$AllScope = $false
    )

    if ($AllScope) {
        Write-Info "Recomputing all iteration cost records project-wide..."
        $allFeatures = Get-ChildItem -Path (Join-Path $ResolvedProjectPath 'specs') -Directory -ErrorAction SilentlyContinue
        foreach ($f in $allFeatures) {
            $iterPath = Join-Path $f.FullName 'iterations'
            if (-not (Test-Path -LiteralPath $iterPath)) { continue }
            foreach ($iter in (Get-ChildItem -Path $iterPath -Directory)) {
                Recompute-OneIteration -ProjectPath $ResolvedProjectPath -Feature $f.Name -Iteration $iter.Name
            }
        }
        Write-Pass "Project-wide recompute complete."
        return
    }

    if ([string]::IsNullOrWhiteSpace($Feature) -or [string]::IsNullOrWhiteSpace($Iteration)) {
        Write-ErrorMsg "specrew cost recompute requires either --all OR (--feature <F> --iteration <N>)"
        exit 1
    }

    Recompute-OneIteration -ProjectPath $ResolvedProjectPath -Feature $Feature -Iteration $Iteration
    Write-Pass "Recompute complete for F-$Feature iteration $Iteration"
}

function Recompute-OneIteration {
    param(
        [Parameter(Mandatory = $true)][string]$ProjectPath,
        [Parameter(Mandatory = $true)][string]$Feature,
        [Parameter(Mandatory = $true)][string]$Iteration
    )

    $cost = Get-SpecrewCostYml -ProjectPath $ProjectPath -Feature $Feature -Iteration $Iteration
    if ($null -eq $cost) { return }

    $catalog = Get-SpecrewModelCatalog -ProjectPath $ProjectPath
    if ($null -eq $catalog) {
        Write-WarningMsg "No catalog at .specrew/model-catalog.yml; cannot recompute"
        return
    }

    foreach ($r in $cost.cost.records) {
        if ($r['source'] -eq 'manual') { continue }  # FR-010: manual records untouched
        $metrics = Compute-CostFromCatalog -Catalog $catalog -Model $r['model'] -Host $r['host'] -TokensIn $r['tokens_in'] -TokensOut $r['tokens_out']
        $r['estimated_cost_usd'] = $metrics.CostUsd
        $r['cost_estimate_confidence'] = $metrics.Confidence
        $r['catalog_refresh_at'] = $metrics.CatalogRefreshedAt
    }

    $cost.cost.aggregates = Get-SpecrewCostAggregates -Records $cost.cost.records -StoryPoints $cost.cost.story_points
    Write-SpecrewCostYml -ProjectPath $ProjectPath -Feature $Feature -Iteration $Iteration -CostHashtable $cost
}

# Main dispatch
if ($Help -or [string]::IsNullOrWhiteSpace($Subcommand)) {
    Show-CostUsage
    exit 0
}

$resolvedProjectPath = (Resolve-Path -LiteralPath $ProjectPath).Path

switch ($Subcommand.ToLowerInvariant()) {
    'summary'   { Invoke-CostSummary -ResolvedProjectPath $resolvedProjectPath -Feature $Feature -Last $Last -JsonOutput $Json.IsPresent }
    'add'       { Invoke-CostAdd -ResolvedProjectPath $resolvedProjectPath -Feature $Feature -Iteration $Iteration -TokensIn $TokensIn -TokensOut $TokensOut -Model $Model -Role $Role -Boundary $Boundary -HostKind $HostKind -Note $Note }
    'recompute' { Invoke-CostRecompute -ResolvedProjectPath $resolvedProjectPath -Feature $Feature -Iteration $Iteration -AllScope $All.IsPresent }
    default {
        Write-ErrorMsg "Unknown subcommand: $Subcommand"
        Show-CostUsage
        exit 1
    }
}
