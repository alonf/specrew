# Per-iteration cost tracking (F-042 / Proposal 070)
#
# Helpers for reading/writing cost.yml + accumulating per-boundary cost
# records + recomputing aggregates. Per spec.md FR-001 through FR-012.
#
# DRAFT — pre-staged 2026-05-23 during F-042 plan-boundary review window.
# Pending F-040 + F-041 merge + F-042 plan-boundary verdict before
# production wiring.
#
# Functions here have no clarify-decision dependency — they're pure helpers
# operating on the cost.yml v1 schema. The boundary-sync integration (where
# Add-SpecrewCostRecord gets called from) and the dashboard COST block need
# clarify approval; those are NOT in this file.

Set-StrictMode -Version Latest

function Get-SpecrewCostYmlPath {
    <#
    .SYNOPSIS
    Resolve the canonical cost.yml path for a feature + iteration.

    .OUTPUTS
    String path like specs/<feature>/iterations/<NNN>/cost.yml
    #>
    param(
        [Parameter(Mandatory = $true)][string]$ProjectPath,
        [Parameter(Mandatory = $true)][string]$Feature,
        [Parameter(Mandatory = $true)][string]$Iteration
    )

    # Iteration zero-padded to 3 digits if it's bare numeric
    $iter = if ($Iteration -match '^\d+$') { "{0:000}" -f [int]$Iteration } else { $Iteration }
    return (Join-Path $ProjectPath "specs/$Feature/iterations/$iter/cost.yml")
}

function Get-SpecrewCostYml {
    <#
    .SYNOPSIS
    Load the cost.yml for a feature + iteration.

    .OUTPUTS
    Hashtable matching schema v1, or $null if file missing.
    #>
    param(
        [Parameter(Mandatory = $true)][string]$ProjectPath,
        [Parameter(Mandatory = $true)][string]$Feature,
        [Parameter(Mandatory = $true)][string]$Iteration
    )

    $path = Get-SpecrewCostYmlPath -ProjectPath $ProjectPath -Feature $Feature -Iteration $Iteration
    if (-not (Test-Path -LiteralPath $path -PathType Leaf)) {
        return $null
    }

    try {
        $raw = Get-Content -LiteralPath $path -Raw -Encoding UTF8
        if (Get-Command ConvertFrom-Yaml -ErrorAction SilentlyContinue) {
            return (ConvertFrom-Yaml -Yaml $raw)
        }
        throw "ConvertFrom-Yaml not available; F-042 wiring requires the codebase YAML parser"
    }
    catch {
        Write-Warning "Could not read cost.yml at $path : $($_.Exception.Message)"
        return $null
    }
}

function Initialize-SpecrewCostYml {
    <#
    .SYNOPSIS
    Create a new cost.yml with schema v1 baseline + empty records + zeroed aggregates.

    .DESCRIPTION
    Called on the first cost record write for an iteration if no cost.yml exists yet.
    Pulls feature + iteration metadata + story_points from the iteration tasks.md.
    #>
    param(
        [Parameter(Mandatory = $true)][string]$ProjectPath,
        [Parameter(Mandatory = $true)][string]$Feature,
        [Parameter(Mandatory = $true)][string]$Iteration,
        [int]$StoryPoints = 0
    )

    $path = Get-SpecrewCostYmlPath -ProjectPath $ProjectPath -Feature $Feature -Iteration $Iteration
    $dir = Split-Path -Parent $path
    if (-not (Test-Path -LiteralPath $dir)) {
        $null = New-Item -ItemType Directory -Path $dir -Force
    }

    $now = [DateTime]::UtcNow.ToString('o')
    $template = @"
# Cost tracking for iteration $Iteration of $Feature
# Schema v1 per Specrew F-042 / Proposal 070

cost:
  schema_version: 1
  feature: "$Feature"
  iteration: "$Iteration"
  story_points: $StoryPoints
  iteration_status: "in-progress"

  records: []

  aggregates:
    total_tokens_in: 0
    total_tokens_out: 0
    total_cost_usd: 0.00
    cost_per_sp_usd: 0.00
    by_host: {}
    by_role: {}
    cost_estimate_confidence: null
    aggregates_recomputed_at: "$now"
"@

    Write-Utf8FileAtomic -Path $path -Content $template
    return $path
}

function Get-SpecrewTokenEstimate {
    <#
    .SYNOPSIS
    Estimate token count for a given text content + model id.

    .DESCRIPTION
    Reads tokenizer_method from the model entry in .specrew/model-catalog.yml.
    When the hint names a known tokenizer AND the tokenizer is available on the
    system, uses it. Otherwise falls back to naive byte/4 estimate.

    .OUTPUTS
    PSCustomObject with Tokens (int), Method (string), Confidence (high/medium/low).
    #>
    param(
        [Parameter(Mandatory = $true)][string]$Content,
        [Parameter(Mandatory = $true)][string]$ModelId,
        [object]$Catalog = $null
    )

    if ([string]::IsNullOrEmpty($Content)) {
        return [pscustomobject]@{ Tokens = 0; Method = 'empty_content'; Confidence = 'high' }
    }

    # Look up tokenizer hint in the catalog
    $tokenizerHint = $null
    if ($null -ne $Catalog) {
        $catalogBlock = if ($Catalog -is [hashtable] -and $Catalog.ContainsKey('catalog')) { $Catalog['catalog'] } else { $Catalog }
        foreach ($hostBlock in $catalogBlock['hosts'].Values) {
            $modelEntry = $hostBlock['models'] | Where-Object { $_['id'] -eq $ModelId } | Select-Object -First 1
            if ($modelEntry -and $modelEntry.ContainsKey('tokenizer_method')) {
                $tokenizerHint = $modelEntry['tokenizer_method']
                break
            }
        }
    }

    # If hint names a tokenizer, try to invoke it (currently stubbed — tokenizer wiring
    # is opt-in via cost_profile extension per F-042 plan)
    if (-not [string]::IsNullOrWhiteSpace($tokenizerHint) -and $tokenizerHint -ne 'null') {
        $tokenizerResult = Invoke-PerModelTokenizer -Method $tokenizerHint -Content $Content -ErrorAction SilentlyContinue
        if ($null -ne $tokenizerResult) {
            return [pscustomobject]@{
                Tokens     = [int]$tokenizerResult.Count
                Method     = $tokenizerHint
                Confidence = 'high'
            }
        }
    }

    # Naive byte/4 fallback
    $byteCount = [System.Text.Encoding]::UTF8.GetByteCount($Content)
    return [pscustomobject]@{
        Tokens     = [int][Math]::Ceiling($byteCount / 4.0)
        Method     = 'naive_byte_4'
        Confidence = 'low'
    }
}

function Invoke-PerModelTokenizer {
    <#
    .SYNOPSIS
    Tokenizer invocation stub (F-042 v1 always returns $null; tokenizer wiring
    is a follow-up small-fix slice).

    .DESCRIPTION
    When this returns $null, Get-SpecrewTokenEstimate falls back to naive byte/4.
    Future implementation: shell out to a python helper with tiktoken, or call
    the relevant tokenizer's native PowerShell/.NET binding when one is available.
    #>
    param(
        [Parameter(Mandatory = $true)][string]$Method,
        [Parameter(Mandatory = $true)][string]$Content
    )
    return $null   # v1: naive fallback always
}

function Add-SpecrewCostRecord {
    <#
    .SYNOPSIS
    Append a new cost record to cost.yml + recompute aggregates.

    .DESCRIPTION
    Per FR-001 / FR-002. Called from Invoke-SpecrewBoundaryStateSync after F-039
    authorization passes. Initializes cost.yml if absent.

    .PARAMETER ProjectPath
    Project root.

    .PARAMETER Feature
    Feature slug (e.g., 040-multi-host-launch-path).

    .PARAMETER Iteration
    Iteration number (zero-padded or bare int).

    .PARAMETER Boundary
    Canonical 9-boundary name from F-039.

    .PARAMETER Role
    Crew role (planner / implementer / reviewer / spec-steward / retro-facilitator / specialist).

    .PARAMETER Host
    Canonical host kind matching F-040 selected_host (copilot-cli / claude-code / codex-cli / antigravity).

    .PARAMETER Model
    Model id from .specrew/model-catalog.yml.

    .PARAMETER TokensIn
    Input token count (estimated or reported).

    .PARAMETER TokensOut
    Output token count.

    .PARAMETER Source
    estimated | reported | manual.

    .PARAMETER TaskId
    Optional task identifier from tasks.md.

    .PARAMETER ManualNote
    Optional human-readable note (when Source == manual).
    #>
    param(
        [Parameter(Mandatory = $true)][string]$ProjectPath,
        [Parameter(Mandatory = $true)][string]$Feature,
        [Parameter(Mandatory = $true)][string]$Iteration,
        [Parameter(Mandatory = $true)][string]$Boundary,
        [Parameter(Mandatory = $true)][string]$Role,
        [Parameter(Mandatory = $true)][string]$Host,
        [Parameter(Mandatory = $true)][string]$Model,
        [Parameter(Mandatory = $true)][int]$TokensIn,
        [Parameter(Mandatory = $true)][int]$TokensOut,
        [ValidateSet('estimated', 'reported', 'manual')]
        [string]$Source = 'estimated',
        [string]$TaskId,
        [string]$ManualNote
    )

    $path = Get-SpecrewCostYmlPath -ProjectPath $ProjectPath -Feature $Feature -Iteration $Iteration
    if (-not (Test-Path -LiteralPath $path -PathType Leaf)) {
        $null = Initialize-SpecrewCostYml -ProjectPath $ProjectPath -Feature $Feature -Iteration $Iteration
    }

    # Read catalog for cost-per-token + currency normalization
    $catalog = Get-SpecrewModelCatalog -ProjectPath $ProjectPath
    $costMetrics = Compute-CostFromCatalog -Catalog $catalog -Model $Model -Host $Host -TokensIn $TokensIn -TokensOut $TokensOut

    # Read current cost.yml
    $cost = Get-SpecrewCostYml -ProjectPath $ProjectPath -Feature $Feature -Iteration $Iteration

    $now = [DateTime]::UtcNow.ToString('o')
    $newRecord = @{
        timestamp                = $now
        boundary                 = $Boundary
        role                     = $Role
        task_id                  = $TaskId
        host                     = $Host
        model                    = $Model
        tokens_in                = $TokensIn
        tokens_out               = $TokensOut
        estimated_cost_usd       = $costMetrics.CostUsd
        cost_estimate_confidence = $costMetrics.Confidence
        source                   = $Source
        tokenizer_method         = $costMetrics.TokenizerMethod
        catalog_refresh_at       = $costMetrics.CatalogRefreshedAt
        pricing_unit             = $costMetrics.PricingUnit
        credit_value_usd         = $costMetrics.CreditValueUsd
        manual_note              = $ManualNote
    }

    if ($null -eq $cost.cost.records) { $cost.cost.records = @() }
    $cost.cost.records += $newRecord

    # Recompute aggregates
    $cost.cost.aggregates = Get-SpecrewCostAggregates -Records $cost.cost.records -StoryPoints $cost.cost.story_points

    # Persist
    Write-SpecrewCostYml -ProjectPath $ProjectPath -Feature $Feature -Iteration $Iteration -CostHashtable $cost
    return $newRecord
}

function Get-SpecrewCostAggregates {
    <#
    .SYNOPSIS
    Recompute the aggregates block from a records array.

    .DESCRIPTION
    Per FR-005: total tokens, total cost, cost per SP, by_host (cost + share + count),
    by_role (cost + share + count), iteration-level cost_estimate_confidence (min of records).
    #>
    param(
        [Parameter(Mandatory = $true)][array]$Records,
        [int]$StoryPoints = 0
    )

    $totalIn = 0
    $totalOut = 0
    $totalCost = 0.0
    $byHost = @{}
    $byRole = @{}
    $confidences = @()

    foreach ($r in $Records) {
        $totalIn  += [int]($r['tokens_in']  ?? 0)
        $totalOut += [int]($r['tokens_out'] ?? 0)
        $cost = [double]($r['estimated_cost_usd'] ?? 0.0)
        $totalCost += $cost

        $hostKey = [string]($r['host'] ?? 'unknown')
        if (-not $byHost.ContainsKey($hostKey)) {
            $byHost[$hostKey] = @{ cost_usd = 0.0; record_count = 0 }
        }
        $byHost[$hostKey]['cost_usd'] += $cost
        $byHost[$hostKey]['record_count'] += 1

        $roleKey = [string]($r['role'] ?? 'unknown')
        if (-not $byRole.ContainsKey($roleKey)) {
            $byRole[$roleKey] = @{ cost_usd = 0.0; record_count = 0 }
        }
        $byRole[$roleKey]['cost_usd'] += $cost
        $byRole[$roleKey]['record_count'] += 1

        $confidences += [string]($r['cost_estimate_confidence'] ?? 'low')
    }

    # Compute shares
    foreach ($k in $byHost.Keys) {
        $byHost[$k]['share'] = if ($totalCost -gt 0) { [Math]::Round($byHost[$k]['cost_usd'] / $totalCost, 4) } else { 0 }
    }
    foreach ($k in $byRole.Keys) {
        $byRole[$k]['share'] = if ($totalCost -gt 0) { [Math]::Round($byRole[$k]['cost_usd'] / $totalCost, 4) } else { 0 }
    }

    # Iteration-level confidence = min of per-record confidences (low > medium > high in worst-first)
    $iterConfidence = if ($confidences -contains 'low') { 'low' }
                      elseif ($confidences -contains 'medium') { 'medium' }
                      elseif ($confidences -contains 'high') { 'high' }
                      else { $null }

    $costPerSp = if ($StoryPoints -gt 0) { [Math]::Round($totalCost / $StoryPoints, 4) } else { 0 }

    return @{
        total_tokens_in            = $totalIn
        total_tokens_out           = $totalOut
        total_cost_usd             = [Math]::Round($totalCost, 4)
        cost_per_sp_usd            = $costPerSp
        by_host                    = $byHost
        by_role                    = $byRole
        cost_estimate_confidence   = $iterConfidence
        aggregates_recomputed_at   = [DateTime]::UtcNow.ToString('o')
    }
}

function Compute-CostFromCatalog {
    <#
    .SYNOPSIS
    Compute USD cost for given tokens_in/out + model id + host, using catalog rates.
    Handles currency normalization (credits → USD via credit_value_usd).
    #>
    param(
        [object]$Catalog,
        [Parameter(Mandatory = $true)][string]$Model,
        [Parameter(Mandatory = $true)][string]$Host,
        [Parameter(Mandatory = $true)][int]$TokensIn,
        [Parameter(Mandatory = $true)][int]$TokensOut
    )

    if ($null -eq $Catalog) {
        return @{
            CostUsd            = $null
            Confidence         = 'low'
            TokenizerMethod    = 'naive_byte_4'
            CatalogRefreshedAt = $null
            PricingUnit        = $null
            CreditValueUsd     = $null
        }
    }

    $catalogBlock = if ($Catalog -is [hashtable] -and $Catalog.ContainsKey('catalog')) { $Catalog['catalog'] } else { $Catalog }
    $catalogRefreshedAt = $catalogBlock['last_refreshed_at']
    $hostBlock = $catalogBlock['hosts'][$Host]
    if ($null -eq $hostBlock) {
        return @{
            CostUsd            = $null
            Confidence         = 'low'
            TokenizerMethod    = 'naive_byte_4'
            CatalogRefreshedAt = $catalogRefreshedAt
            PricingUnit        = $null
            CreditValueUsd     = $null
        }
    }

    $pricingUnit = [string]($hostBlock['pricing_unit'] ?? 'usd')
    $creditValueUsd = $hostBlock['credit_value_usd']

    $modelEntry = $hostBlock['models'] | Where-Object { $_['id'] -eq $Model } | Select-Object -First 1
    if ($null -eq $modelEntry) {
        return @{
            CostUsd            = $null
            Confidence         = 'low'
            TokenizerMethod    = 'naive_byte_4'
            CatalogRefreshedAt = $catalogRefreshedAt
            PricingUnit        = $pricingUnit
            CreditValueUsd     = $creditValueUsd
        }
    }

    $inputRate  = [double]($modelEntry['cost_per_million_input']  ?? 0.0)
    $outputRate = [double]($modelEntry['cost_per_million_output'] ?? 0.0)

    # Compute raw cost in the host's pricing unit
    $rawCost = ($TokensIn / 1e6) * $inputRate + ($TokensOut / 1e6) * $outputRate

    # Normalize to USD (credits-based hosts: multiply by credit_value_usd)
    $costUsd = if ($pricingUnit -eq 'credits' -and $null -ne $creditValueUsd) {
        $rawCost * [double]$creditValueUsd
    }
    else {
        $rawCost
    }

    $confidence = if ($inputRate -gt 0 -and $outputRate -gt 0) { 'medium' } else { 'low' }
    $tokenizerMethod = [string]($modelEntry['tokenizer_method'] ?? 'naive_byte_4')

    return @{
        CostUsd            = [Math]::Round($costUsd, 6)
        Confidence         = $confidence
        TokenizerMethod    = $tokenizerMethod
        CatalogRefreshedAt = $catalogRefreshedAt
        PricingUnit        = $pricingUnit
        CreditValueUsd     = $creditValueUsd
    }
}

function Write-SpecrewCostYml {
    <#
    .SYNOPSIS
    Serialize and write the cost.yml back to disk.
    Atomic via Write-Utf8FileAtomic.
    #>
    param(
        [Parameter(Mandatory = $true)][string]$ProjectPath,
        [Parameter(Mandatory = $true)][string]$Feature,
        [Parameter(Mandatory = $true)][string]$Iteration,
        [Parameter(Mandatory = $true)][object]$CostHashtable
    )

    $path = Get-SpecrewCostYmlPath -ProjectPath $ProjectPath -Feature $Feature -Iteration $Iteration

    if (Get-Command ConvertTo-Yaml -ErrorAction SilentlyContinue) {
        $yaml = ConvertTo-Yaml -Data $CostHashtable
        Write-Utf8FileAtomic -Path $path -Content $yaml
    }
    else {
        throw "ConvertTo-Yaml not available; F-042 wiring requires the codebase YAML serializer"
    }
}

function Get-SpecrewCostAggregatesForFeature {
    <#
    .SYNOPSIS
    Aggregate cost across ALL iterations of a feature (rollup).

    .DESCRIPTION
    Used by dashboard COST section + `specrew cost summary --feature <F>`.
    Sums per-iteration cost.yml aggregates; preserves per-host attribution
    by summing dollar amounts then re-computing shares (NOT averaging
    iteration-level shares, which would lose accuracy across alternating
    hosts).
    #>
    param(
        [Parameter(Mandatory = $true)][string]$ProjectPath,
        [Parameter(Mandatory = $true)][string]$Feature
    )

    $featurePath = Join-Path $ProjectPath "specs/$Feature/iterations"
    if (-not (Test-Path -LiteralPath $featurePath -PathType Container)) {
        return $null
    }

    $iterations = Get-ChildItem -Path $featurePath -Directory | Sort-Object Name
    $totalCost = 0.0
    $totalSp = 0
    $byHost = @{}
    $iterationRollups = @()

    foreach ($iter in $iterations) {
        $cost = Get-SpecrewCostYml -ProjectPath $ProjectPath -Feature $Feature -Iteration $iter.Name
        if ($null -eq $cost) { continue }

        $iterAgg = $cost.cost.aggregates
        $totalCost += [double]($iterAgg['total_cost_usd'] ?? 0.0)
        $totalSp += [int]($cost.cost.story_points ?? 0)

        foreach ($hostKey in $iterAgg['by_host'].Keys) {
            if (-not $byHost.ContainsKey($hostKey)) {
                $byHost[$hostKey] = @{ cost_usd = 0.0 }
            }
            $byHost[$hostKey]['cost_usd'] += [double]$iterAgg['by_host'][$hostKey]['cost_usd']
        }

        $iterationRollups += @{
            iteration   = $iter.Name
            cost_usd    = [double]($iterAgg['total_cost_usd'] ?? 0.0)
            sp          = [int]($cost.cost.story_points ?? 0)
            cost_per_sp = [double]($iterAgg['cost_per_sp_usd'] ?? 0.0)
            by_host     = $iterAgg['by_host']
        }
    }

    # Recompute shares at feature level
    foreach ($k in $byHost.Keys) {
        $byHost[$k]['share'] = if ($totalCost -gt 0) { [Math]::Round($byHost[$k]['cost_usd'] / $totalCost, 4) } else { 0 }
    }

    return @{
        feature                   = $Feature
        iteration_count           = $iterationRollups.Count
        total_cost_usd            = [Math]::Round($totalCost, 4)
        total_story_points        = $totalSp
        cost_per_sp_usd           = if ($totalSp -gt 0) { [Math]::Round($totalCost / $totalSp, 4) } else { 0 }
        by_host                   = $byHost
        iteration_rollups         = $iterationRollups
    }
}
