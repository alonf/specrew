# Cost-catalog display helpers (F-042 FR-013)
#
# Pretty-print the model catalog as a table (default), with overrides applied
# (--effective), or as a diff between public and effective (--diff).
# Supports --json for downstream tooling.
#
# DRAFT — pre-staged 2026-05-23 while user is offline. Pending F-041 + F-042
# merge before production wiring.

Set-StrictMode -Version Latest

function Format-SpecrewCatalogTable {
    <#
    .SYNOPSIS
    Format the model catalog as a console-friendly table.

    .DESCRIPTION
    Per FR-013: default form shows public rates; --effective applies the
    pricing-overrides overlay; --diff shows only rows where effective != public.

    .PARAMETER Mode
    'public' (catalog as-is) | 'effective' (with overrides applied) | 'diff' (override-vs-public delta only)

    .PARAMETER Catalog
    Parsed model-catalog.yml content.

    .PARAMETER Overrides
    Parsed pricing-overrides.yml content (or $null).

    .OUTPUTS
    String — formatted table ready to write to console.
    #>
    param(
        [Parameter(Mandatory = $true)][object]$Catalog,
        [object]$Overrides,
        [ValidateSet('public', 'effective', 'diff')]
        [string]$Mode = 'public'
    )

    $catalogBlock = if ($Catalog -is [hashtable] -and $Catalog.ContainsKey('catalog')) { $Catalog['catalog'] } else { $Catalog }
    $rows = @()

    foreach ($hostKind in $catalogBlock['hosts'].Keys) {
        $hostBlock = $catalogBlock['hosts'][$hostKind]
        if (-not $hostBlock['models']) { continue }

        foreach ($model in $hostBlock['models']) {
            $modelId = [string]$model['id']
            $tier = [string]($model['tier'] ?? '?')
            $publicIn = [double]($model['cost_per_million_input'] ?? 0.0)
            $publicOut = [double]($model['cost_per_million_output'] ?? 0.0)
            $bestFor = if ($model['best_for']) { ($model['best_for'] | ForEach-Object { $_ }) -join ', ' } else { '' }

            # Resolve effective rate (if Overrides provided)
            $effectiveIn = $publicIn
            $effectiveOut = $publicOut
            $source = 'public-list'
            $contractId = $null

            if ($null -ne $Overrides -and $Mode -ne 'public') {
                $resolved = Get-SpecrewEffectivePricing -Catalog $Catalog -Overrides $Overrides -Host $hostKind -Model $modelId -ErrorAction SilentlyContinue
                if ($null -ne $resolved) {
                    $effectiveIn = $resolved.EffectiveInputCost
                    $effectiveOut = $resolved.EffectiveOutputCost
                    $source = $resolved.PricingSource
                    $contractId = $resolved.OverrideContractId
                }
            }

            # In diff mode, skip rows where effective == public
            if ($Mode -eq 'diff' -and $effectiveIn -eq $publicIn -and $effectiveOut -eq $publicOut) {
                continue
            }

            $rows += [pscustomobject]@{
                Host          = $hostKind
                Model         = $modelId
                Tier          = $tier
                PublicInput   = $publicIn
                PublicOutput  = $publicOut
                EffectiveIn   = $effectiveIn
                EffectiveOut  = $effectiveOut
                Source        = $source
                ContractId    = $contractId
                BestFor       = $bestFor
            }
        }
    }

    if ($rows.Count -eq 0) {
        if ($Mode -eq 'diff') {
            return "No pricing overrides applied. All rates match the public catalog."
        }
        return "Catalog is empty."
    }

    # Build formatted output
    $sb = New-Object System.Text.StringBuilder

    # Header banner
    $catalogRefreshedAt = $catalogBlock['last_refreshed_at']
    $confidence = $catalogBlock['confidence']
    [void]$sb.AppendLine("Model catalog (refreshed $catalogRefreshedAt; confidence: $confidence)")
    [void]$sb.AppendLine('')

    # Column widths (computed for alignment)
    $hostW = ([Math]::Max(($rows | ForEach-Object { $_.Host.Length } | Measure-Object -Maximum).Maximum, 12))
    $modelW = ([Math]::Max(($rows | ForEach-Object { $_.Model.Length } | Measure-Object -Maximum).Maximum, 24))
    $tierW = 10

    if ($Mode -eq 'public') {
        $header = ("{0,-$hostW}  {1,-$modelW}  {2,-$tierW}  {3,12}  {4,13}  {5}" -f 'HOST', 'MODEL', 'TIER', 'INPUT $/MTok', 'OUTPUT $/MTok', 'BEST_FOR')
        [void]$sb.AppendLine($header)
        [void]$sb.AppendLine(('-' * $header.Length))
        foreach ($r in $rows) {
            [void]$sb.AppendLine(("{0,-$hostW}  {1,-$modelW}  {2,-$tierW}  `${3,11:F2}  `${4,12:F2}  {5}" -f $r.Host, $r.Model, $r.Tier, $r.PublicInput, $r.PublicOutput, $r.BestFor))
        }
    }
    elseif ($Mode -eq 'effective') {
        $header = ("{0,-$hostW}  {1,-$modelW}  {2,-$tierW}  {3,16}  {4,17}  {5}" -f 'HOST', 'MODEL', 'TIER', 'EFFECTIVE IN $/MTok', 'EFFECTIVE OUT $/MTok', 'SOURCE')
        [void]$sb.AppendLine($header)
        [void]$sb.AppendLine(('-' * $header.Length))
        foreach ($r in $rows) {
            $sourceMark = if ($r.Source -ne 'public-list') { "$($r.Source) [$($r.ContractId)]" } else { 'public-list' }
            [void]$sb.AppendLine(("{0,-$hostW}  {1,-$modelW}  {2,-$tierW}  `${3,15:F4}  `${4,16:F4}  {5}" -f $r.Host, $r.Model, $r.Tier, $r.EffectiveIn, $r.EffectiveOut, $sourceMark))
        }
    }
    elseif ($Mode -eq 'diff') {
        [void]$sb.AppendLine("Showing only rows where effective ≠ public (rows with overrides applied):")
        [void]$sb.AppendLine('')
        $header = ("{0,-$hostW}  {1,-$modelW}  {2,16}  {3,16}  {4,16}  {5}" -f 'HOST', 'MODEL', 'PUBLIC IN/MTok', 'EFFECTIVE IN/MTok', 'DELTA IN', 'CONTRACT')
        [void]$sb.AppendLine($header)
        [void]$sb.AppendLine(('-' * $header.Length))
        foreach ($r in $rows) {
            $delta = $r.EffectiveIn - $r.PublicInput
            $deltaPct = if ($r.PublicInput -gt 0) { ($delta / $r.PublicInput) * 100 } else { 0 }
            $deltaStr = ("{0:+0.00;-0.00;0.00} ({1:+0.0;-0.0;0.0}%)" -f $delta, $deltaPct)
            [void]$sb.AppendLine(("{0,-$hostW}  {1,-$modelW}  `${2,15:F4}  `${3,15:F4}  {4,16}  {5}" -f $r.Host, $r.Model, $r.PublicInput, $r.EffectiveIn, $deltaStr, ($r.ContractId ?? '')))
        }
    }

    # Append expiry warning if active (FR-019)
    return $sb.ToString()
}

function Format-SpecrewCatalogJson {
    <#
    .SYNOPSIS
    Emit the catalog as JSON for downstream tooling (--json mode of FR-013).
    Effective rates with overrides applied; both public and effective values present.
    #>
    param(
        [Parameter(Mandatory = $true)][object]$Catalog,
        [object]$Overrides
    )

    $catalogBlock = if ($Catalog -is [hashtable] -and $Catalog.ContainsKey('catalog')) { $Catalog['catalog'] } else { $Catalog }
    $output = @{
        last_refreshed_at = $catalogBlock['last_refreshed_at']
        confidence        = $catalogBlock['confidence']
        rates             = @()
    }

    foreach ($hostKind in $catalogBlock['hosts'].Keys) {
        $hostBlock = $catalogBlock['hosts'][$hostKind]
        if (-not $hostBlock['models']) { continue }

        foreach ($model in $hostBlock['models']) {
            $modelId = [string]$model['id']
            $resolved = Get-SpecrewEffectivePricing -Catalog $Catalog -Overrides $Overrides -Host $hostKind -Model $modelId -ErrorAction SilentlyContinue

            $output.rates += @{
                host          = $hostKind
                model         = $modelId
                tier          = [string]($model['tier'] ?? '')
                public_input  = [double]($model['cost_per_million_input'] ?? 0)
                public_output = [double]($model['cost_per_million_output'] ?? 0)
                effective_input  = if ($null -ne $resolved) { $resolved.EffectiveInputCost } else { [double]($model['cost_per_million_input'] ?? 0) }
                effective_output = if ($null -ne $resolved) { $resolved.EffectiveOutputCost } else { [double]($model['cost_per_million_output'] ?? 0) }
                pricing_source = if ($null -ne $resolved) { $resolved.PricingSource } else { 'public-list' }
                contract_id    = if ($null -ne $resolved) { $resolved.OverrideContractId } else { $null }
                pricing_unit   = if ($null -ne $resolved) { $resolved.PricingUnit } else { 'usd' }
                best_for       = @($model['best_for'] ?? @())
                capability_tags = @($model['capability_tags'] ?? @())
            }
        }
    }

    return ($output | ConvertTo-Json -Depth 10)
}

function Invoke-SpecrewCostCatalog {
    <#
    .SYNOPSIS
    The implementation behind `specrew cost catalog [--effective] [--diff] [--json]`.

    .PARAMETER Mode
    Display mode: 'public' / 'effective' / 'diff'.

    .PARAMETER JsonOutput
    If true, emit JSON instead of formatted table.
    #>
    param(
        [Parameter(Mandatory = $true)][string]$ProjectPath,
        [ValidateSet('public', 'effective', 'diff')]
        [string]$Mode = 'public',
        [bool]$JsonOutput = $false
    )

    $catalog = Get-SpecrewModelCatalog -ProjectPath $ProjectPath
    if ($null -eq $catalog) {
        Write-Warning "No catalog at .specrew/model-catalog.yml. Run `/specrew-research-models` or copy templates/model-catalog-fixture.yml."
        return
    }

    $overrides = if ($Mode -ne 'public') {
        Get-SpecrewPricingOverrides -ProjectPath $ProjectPath
    } else { $null }

    if ($JsonOutput) {
        Format-SpecrewCatalogJson -Catalog $catalog -Overrides $overrides
    }
    else {
        Format-SpecrewCatalogTable -Catalog $catalog -Overrides $overrides -Mode $Mode

        # Append expiry warning if applicable
        if ($null -ne $overrides) {
            $expiryCheck = Test-SpecrewPricingOverridesExpiry -ProjectPath $ProjectPath -ErrorAction SilentlyContinue
            if ($null -ne $expiryCheck -and $expiryCheck.ShouldWarn) {
                Write-Host ''
                Write-Host "WARNING: $($expiryCheck.Message)" -ForegroundColor Yellow
            }
        }
    }
}
