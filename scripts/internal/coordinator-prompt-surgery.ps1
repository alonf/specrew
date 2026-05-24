# Coordinator-prompt surgery — registry-driven rules engine (Phase C.3 refactor)
#
# Originally a 123-line file with hardcoded per-host switches (FR-011 header,
# FR-012 strip non-Copilot, FR-014 Codex pwsh-form). Now a thin rules engine
# that loads hosts/<kind>/coordinator-rules.psd1 and applies declared Rules in order.
#
# The universal header rewrite (FR-011) stays here as a built-in baseline because
# the literal IS the same across all hosts (it's the spec invariant). Per-host
# rule files declare ADDITIONAL surgery on top.
#
# To change a per-host rule: edit hosts/<kind>/coordinator-rules.psd1.
# To add a new host: create hosts/<kind>/coordinator-rules.psd1 — no edits to this engine.

Set-StrictMode -Version Latest

$script:RegistryPath = Join-Path (Split-Path -Parent $PSScriptRoot) 'hosts\_registry.ps1'
if (-not (Test-Path -LiteralPath $script:RegistryPath -PathType Leaf)) {
    # Module-mode lookup
    $script:RegistryPath = Join-Path (Split-Path -Parent (Split-Path -Parent $PSScriptRoot)) 'hosts\_registry.ps1'
}
if (-not (Test-Path -LiteralPath $script:RegistryPath -PathType Leaf)) {
    throw "Host registry not found. Searched: $script:RegistryPath"
}
. $script:RegistryPath

$script:CoordinatorRulesCache = @{}

function Get-SpecrewUniversalCoordinatorHeader {
    # FR-011 invariant: same literal for every host.
    return 'You are the Crew team coordinator running inside a Specrew-bootstrapped repository.'
}

function Get-SpecrewOriginalCoordinatorHeaderPattern {
    # Matches the original Squad header that gets replaced uniformly.
    return '(?m)^You are Squad running inside a Specrew-bootstrapped repository\.'
}

function Get-SpecrewHostCoordinatorRules {
    <#
    .SYNOPSIS
    Loads the declarative coordinator-prompt surgery rules for a given host.
    .OUTPUTS
    array of hashtables, each with @{ Kind = 'Strip'|'Replace'; Pattern; Replacement?; Description }
    Returns empty array if the host has no per-host rules (e.g., Copilot).
    #>
    param([Parameter(Mandatory = $true)][string]$HostKind)

    $kindLower = $HostKind.ToLowerInvariant()
    if ($script:CoordinatorRulesCache.ContainsKey($kindLower)) {
        return $script:CoordinatorRulesCache[$kindLower]
    }

    $manifest = Get-HostManifest -Kind $kindLower
    $rulesFile = if ($manifest.ContainsKey('CoordinatorRulesFile') -and -not [string]::IsNullOrWhiteSpace([string]$manifest.CoordinatorRulesFile)) { $manifest.CoordinatorRulesFile } else { 'coordinator-rules.psd1' }
    $hostsRoot = Get-SpecrewHostsRoot
    $rulesPath = Join-Path (Join-Path $hostsRoot $kindLower) $rulesFile

    if (-not (Test-Path -LiteralPath $rulesPath -PathType Leaf)) {
        # Hosts may legitimately have no per-host rules (e.g., Copilot only needs the engine's universal header)
        $script:CoordinatorRulesCache[$kindLower] = @()
        return @()
    }

    try {
        $rulesData = Import-PowerShellDataFile -LiteralPath $rulesPath
    }
    catch {
        throw "Failed to load coordinator rules for host '$HostKind' at '$rulesPath': $($_.Exception.Message)"
    }

    if (-not $rulesData.ContainsKey('Rules')) {
        $script:CoordinatorRulesCache[$kindLower] = @()
        return @()
    }

    $rules = @($rulesData.Rules)
    $script:CoordinatorRulesCache[$kindLower] = $rules
    return $rules
}

function Invoke-SpecrewCoordinatorPromptSurgery {
    <#
    .SYNOPSIS
    Applies multi-host coordinator-prompt surgery — registry-driven rules engine.

    .DESCRIPTION
    Two surgeries applied in order:
      1. Universal header rewrite (FR-011 invariant; built-in baseline applied to ALL hosts).
      2. Per-host declarative rules from hosts/<kind>/coordinator-rules.psd1 applied in declared order.

    Per-host rules are hashtables with:
      - Kind = 'Strip' | 'Replace'
      - Pattern = regex string
      - Replacement = string (required only for Replace; supports regex backreferences like `$1`)
      - Description = human-readable label (for diagnostics)

    Returns the rewritten prompt body.
    #>
    param(
        [Parameter(Mandatory = $true)]
        [string]$Prompt,

        [Parameter(Mandatory = $true)]
        [ValidateSet('copilot', 'claude', 'codex', 'antigravity')]
        [string]$HostKind
    )

    if ([string]::IsNullOrEmpty($Prompt)) {
        return $Prompt
    }

    $result = $Prompt

    # Surgery 1: universal header rewrite (FR-011) — applies to ALL hosts as a built-in baseline.
    $result = [regex]::Replace($result, (Get-SpecrewOriginalCoordinatorHeaderPattern), (Get-SpecrewUniversalCoordinatorHeader))

    # Surgery 2: per-host declarative rules
    $rules = Get-SpecrewHostCoordinatorRules -HostKind $HostKind
    $appliedStrip = $false
    foreach ($rule in $rules) {
        if (-not $rule.ContainsKey('Kind') -or -not $rule.ContainsKey('Pattern')) {
            Write-Warning ("Skipping malformed coordinator rule for host '{0}': missing Kind or Pattern" -f $HostKind)
            continue
        }
        switch ($rule.Kind) {
            'Strip' {
                $result = [regex]::Replace($result, $rule.Pattern, '')
                $appliedStrip = $true
            }
            'Replace' {
                if (-not $rule.ContainsKey('Replacement')) {
                    Write-Warning ("Skipping malformed Replace rule for host '{0}': missing Replacement" -f $HostKind)
                    continue
                }
                $result = [regex]::Replace($result, $rule.Pattern, [string]$rule.Replacement)
            }
            default {
                Write-Warning ("Unknown rule Kind '{0}' for host '{1}'; skipping" -f $rule.Kind, $HostKind)
            }
        }
    }

    # If any Strip rules fired, tidy up blank-line clusters that get left behind.
    if ($appliedStrip) {
        $result = [regex]::Replace($result, '(?m)(^\s*$\r?\n){3,}', "`r`n`r`n")
    }

    return $result
}

# Back-compat helpers (preserved for callers + tests that import these names directly)
function Get-SpecrewSquadRuntimePathDirectivePatterns {
    # Aggregate from non-Copilot hosts' declarative rules so existing introspection callsites keep working.
    $patterns = New-Object System.Collections.Generic.HashSet[string]
    foreach ($kind in Get-RegisteredHostKinds) {
        if ($kind -eq 'copilot') { continue }
        foreach ($rule in (Get-SpecrewHostCoordinatorRules -HostKind $kind)) {
            if ($rule.Kind -eq 'Strip' -and $rule.ContainsKey('Pattern')) {
                $null = $patterns.Add([string]$rule.Pattern)
            }
        }
    }
    return @($patterns)
}

function Get-SpecrewSlashCommandToPwshFormMap {
    # Aggregate from Codex (the only host with FR-014 Replace rules) so existing introspection callsites keep working.
    $maps = New-Object System.Collections.Generic.List[hashtable]
    foreach ($rule in (Get-SpecrewHostCoordinatorRules -HostKind 'codex')) {
        if ($rule.Kind -eq 'Replace' -and $rule.ContainsKey('Pattern') -and $rule.ContainsKey('Replacement')) {
            $maps.Add(@{ Pattern = [string]$rule.Pattern; Replacement = [string]$rule.Replacement }) | Out-Null
        }
    }
    return @($maps)
}
