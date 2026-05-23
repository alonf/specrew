# Cost-aware model routing helpers (F-041 / Proposal 068)
#
# Pure-helper layer for reading/writing the model catalog + persisting routing
# decisions to .squad/decisions.md. Per spec.md FR-001 through FR-013.
#
# DRAFT — pre-staged 2026-05-23 during F-041 plan-boundary review window.
# Pending F-040 merge + F-041 plan-boundary verdict before production wiring.
#
# Functions in this file have NO clarify-decision dependency — they're pure
# helpers operating on the catalog/config schemas. The actual routing policy
# (Resolve-RoleToModelTier, Test-RoutingApprovalRequired) depends on clarify
# Q1 (lean vs balanced profiles) and ships in a separate file once user
# confirms the clarify defaults.

Set-StrictMode -Version Latest

function Get-SpecrewCostProfile {
    <#
    .SYNOPSIS
    Read the active cost_profile from .specrew/config.yml.

    .DESCRIPTION
    Returns 'lean' (the F-041 v1 default) or whatever the user has set.
    Returns 'lean' as a safe fallback if the config field is missing
    (handles brownfield projects pre-F-041 migration).

    .OUTPUTS
    String — one of 'lean', 'balanced', 'premium', 'custom'.
    #>
    param(
        [Parameter(Mandatory = $true)]
        [string]$ProjectPath
    )

    $configPath = Join-Path $ProjectPath '.specrew\config.yml'
    if (-not (Test-Path -LiteralPath $configPath -PathType Leaf)) {
        return 'lean'  # safe default for fresh projects
    }

    try {
        # The existing F-019 / F-039 codebase uses Get-SpecrewConfigValue for these reads
        $profile = Get-SpecrewConfigValue -ProjectRoot $ProjectPath -Key 'cost_profile' -ErrorAction SilentlyContinue
        if ([string]::IsNullOrWhiteSpace($profile)) {
            return 'lean'
        }
        $profileLower = $profile.ToLowerInvariant().Trim()
        if ($profileLower -in @('lean', 'balanced', 'premium', 'custom')) {
            return $profileLower
        }
        # Unrecognized value — warn and fall back to lean
        Write-Warning "Unknown cost_profile '$profile' in .specrew/config.yml; falling back to 'lean'"
        return 'lean'
    }
    catch {
        Write-Warning "Could not read cost_profile from $configPath : $($_.Exception.Message). Falling back to 'lean'."
        return 'lean'
    }
}

function Get-SpecrewModelCatalog {
    <#
    .SYNOPSIS
    Load the model catalog from .specrew/model-catalog.yml.

    .DESCRIPTION
    Returns a hashtable representing the catalog v2 schema, or $null if the
    file is missing. Schema validation is via Test-SpecrewModelCatalogSchema.

    .OUTPUTS
    Hashtable matching the catalog v2 schema, or $null if file missing.
    #>
    param(
        [Parameter(Mandatory = $true)]
        [string]$ProjectPath
    )

    $catalogPath = Join-Path $ProjectPath '.specrew\model-catalog.yml'
    if (-not (Test-Path -LiteralPath $catalogPath -PathType Leaf)) {
        return $null
    }

    try {
        $raw = Get-Content -LiteralPath $catalogPath -Raw -Encoding UTF8
        # PowerShell-Yaml or built-in ConvertFrom-Yaml depending on the toolkit
        # The F-041 implementer wires this to whatever the rest of the codebase uses
        if (Get-Command ConvertFrom-Yaml -ErrorAction SilentlyContinue) {
            $catalog = ConvertFrom-Yaml -Yaml $raw
        }
        else {
            # Fallback: rough parse via PowerShell-Yaml module if available, else error
            throw "ConvertFrom-Yaml not available; install PowerShell-Yaml or ensure F-041 wiring uses the codebase's YAML parser"
        }

        if (-not (Test-SpecrewModelCatalogSchema -Catalog $catalog)) {
            Write-Warning "Catalog at $catalogPath failed schema validation; returning anyway with caution"
        }
        return $catalog
    }
    catch {
        Write-Warning "Could not read model catalog: $($_.Exception.Message)"
        return $null
    }
}

function Test-SpecrewModelCatalogSchema {
    <#
    .SYNOPSIS
    Validate a parsed catalog against the v2 schema.

    .DESCRIPTION
    Checks structural requirements: schema_version, last_refreshed_at, confidence,
    hosts keyed by canonical kinds, models[] with required fields per entry.
    Returns $true if valid; $false otherwise (writes specific warnings).
    #>
    param(
        [Parameter(Mandatory = $true)]
        [object]$Catalog
    )

    if ($null -eq $Catalog) {
        Write-Warning "Catalog is null"
        return $false
    }

    $catalog = if ($Catalog -is [hashtable] -and $Catalog.ContainsKey('catalog')) { $Catalog['catalog'] } else { $Catalog }

    foreach ($required in 'schema_version', 'last_refreshed_at', 'confidence', 'hosts') {
        if (-not ($catalog -is [hashtable]) -or -not $catalog.ContainsKey($required)) {
            Write-Warning "Catalog missing required top-level field: $required"
            return $false
        }
    }

    if ($catalog['schema_version'] -ne 2) {
        Write-Warning "Catalog schema_version is $($catalog['schema_version']); expected 2 (F-041 baseline)"
        return $false
    }

    if ($catalog['confidence'] -notin @('high', 'medium', 'low')) {
        Write-Warning "Catalog confidence is '$($catalog['confidence'])'; expected high|medium|low"
        return $false
    }

    foreach ($hostKind in $catalog['hosts'].Keys) {
        $hostBlock = $catalog['hosts'][$hostKind]
        foreach ($required in 'available', 'selector_strategy', 'models') {
            if (-not ($hostBlock -is [hashtable]) -or -not $hostBlock.ContainsKey($required)) {
                Write-Warning "Host '$hostKind' missing required field: $required"
                return $false
            }
        }
        if ($hostBlock['selector_strategy'] -notin @('squad_config_field', 'subagent_frontmatter', 'agent_toml_field', 'cli_flag')) {
            Write-Warning "Host '$hostKind' has invalid selector_strategy '$($hostBlock['selector_strategy'])'"
            return $false
        }
    }

    return $true
}

function Test-SpecrewCatalogStaleness {
    <#
    .SYNOPSIS
    Determine catalog staleness status: fresh | warn | auto-refresh-required.

    .DESCRIPTION
    Per spec FR-006:
      - Less than 30 days old: fresh
      - 30-90 days old: warn (advise user to refresh)
      - 90+ days old: auto-refresh-required (block routing decisions until refreshed)
      - Catalog missing entirely: auto-refresh-required

    .OUTPUTS
    PSCustomObject with Status ('fresh' / 'warn' / 'auto-refresh-required' / 'missing'),
    AgeDays (integer or null if missing), LastRefreshedAt (ISO8601 string or null).
    #>
    param(
        [Parameter(Mandatory = $true)]
        [string]$ProjectPath
    )

    $catalog = Get-SpecrewModelCatalog -ProjectPath $ProjectPath
    if ($null -eq $catalog) {
        return [pscustomobject]@{
            Status          = 'missing'
            AgeDays         = $null
            LastRefreshedAt = $null
        }
    }

    $catalogBlock = if ($catalog -is [hashtable] -and $catalog.ContainsKey('catalog')) { $catalog['catalog'] } else { $catalog }
    $lastRefreshed = $catalogBlock['last_refreshed_at']
    if ([string]::IsNullOrWhiteSpace($lastRefreshed)) {
        return [pscustomobject]@{
            Status          = 'missing'
            AgeDays         = $null
            LastRefreshedAt = $null
        }
    }

    try {
        $refreshedDate = [DateTime]::Parse($lastRefreshed, [System.Globalization.CultureInfo]::InvariantCulture, [System.Globalization.DateTimeStyles]::AssumeUniversal)
        $ageDays = [int]([DateTime]::UtcNow - $refreshedDate.ToUniversalTime()).TotalDays

        $status = if ($ageDays -lt 30) { 'fresh' }
                  elseif ($ageDays -lt 90) { 'warn' }
                  else { 'auto-refresh-required' }

        return [pscustomobject]@{
            Status          = $status
            AgeDays         = $ageDays
            LastRefreshedAt = $lastRefreshed
        }
    }
    catch {
        Write-Warning "Could not parse last_refreshed_at '$lastRefreshed': $($_.Exception.Message)"
        return [pscustomobject]@{
            Status          = 'auto-refresh-required'
            AgeDays         = $null
            LastRefreshedAt = $lastRefreshed
        }
    }
}

function Add-SpecrewRoutingDecisionEntry {
    <#
    .SYNOPSIS
    Append a routing-decision entry to .squad/decisions.md (FR-007 + FR-013).

    .DESCRIPTION
    Per spec FR-007: each entry includes role, task summary, selected model id,
    model tier, host kind, cost_profile, fallback_reason (nullable), override_source
    (one of 'lean-profile-default' / 'human-config' / 'host-builtin-primitive').

    Per spec FR-013: decisions persist in .squad/decisions.md regardless of host
    (canonical ledger location until Proposal 024 Slice 3 introduces per-host equivalents).
    #>
    param(
        [Parameter(Mandatory = $true)][string]$ProjectPath,
        [Parameter(Mandatory = $true)][string]$Role,
        [Parameter(Mandatory = $true)][string]$TaskSummary,
        [Parameter(Mandatory = $true)][string]$ModelId,
        [Parameter(Mandatory = $true)][ValidateSet('free', 'cheap', 'balanced', 'premium')][string]$ModelTier,
        [Parameter(Mandatory = $true)][ValidateSet('copilot', 'claude', 'codex', 'antigravity')][string]$HostKind,
        [Parameter(Mandatory = $true)][string]$CostProfile,
        [string]$FallbackReason,
        [Parameter(Mandatory = $true)][ValidateSet('lean-profile-default', 'human-config', 'host-builtin-primitive', 'override')][string]$OverrideSource,
        [string]$PerHostInjectionStatus  # 'applied' / 'bootstrap_only' / 'deferred' / 'error' from per-host-model-injection
    )

    $decisionsPath = Join-Path $ProjectPath '.squad\decisions.md'
    if (-not (Test-Path -LiteralPath (Split-Path -Parent $decisionsPath))) {
        # F-040 may launch on non-Squad host with no .squad/ directory.
        # Routing decisions still log to .squad/decisions.md per FR-013 — create the dir if needed.
        $null = New-Item -ItemType Directory -Path (Split-Path -Parent $decisionsPath) -Force
    }

    $timestamp = [DateTime]::UtcNow.ToString('o')
    $entry = @"

### Routing decision — $Role @ $timestamp

- **Role**: $Role
- **Task**: $TaskSummary
- **Selected model**: ``$ModelId`` (tier: $ModelTier)
- **Host**: $HostKind
- **Cost profile**: $CostProfile
- **Override source**: $OverrideSource
- **Fallback reason**: $(if ($FallbackReason) { $FallbackReason } else { 'none' })
- **Per-host injection**: $(if ($PerHostInjectionStatus) { $PerHostInjectionStatus } else { 'not-attempted' })
"@

    Add-Content -LiteralPath $decisionsPath -Value $entry -Encoding UTF8

    return [pscustomobject]@{
        Status         = 'logged'
        DecisionsPath  = $decisionsPath
        Timestamp      = $timestamp
    }
}
