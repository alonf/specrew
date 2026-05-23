# Per-host model-selection injection (F-041 / Proposal 068)
#
# Four dispatchers, one per host's selector_strategy. Routing logic in
# cost-routing.ps1 calls Invoke-SpecrewPerHostModelInjection with the
# selected host kind + role + model id; this script dispatches to the
# host-native primitive.
#
# Per F-041 research.md Task 2 + F-040 Abstraction Surface Inventory.
#
# DRAFT — pre-staged 2026-05-23 during F-041 plan-boundary review window.
# Pending F-040 merge + F-041 plan-boundary verdict before production wiring.

Set-StrictMode -Version Latest

function Invoke-SpecrewPerHostModelInjection {
    <#
    .SYNOPSIS
    Dispatch model injection to the host-native primitive based on selector_strategy.

    .DESCRIPTION
    Reads the host's selector_strategy from `.specrew/model-catalog.yml` and dispatches
    to the appropriate per-host writer. When the host is in bootstrap_only mode
    (no per-host Crew runtime deployed — F-040 reports this via crew_runtime_status),
    returns a sentinel indicating the routing decision should be logged in
    .squad/decisions.md but the per-host file update should be skipped.

    .PARAMETER HostKind
    Selected host (copilot | claude | codex | antigravity).

    .PARAMETER Role
    Crew role receiving the model assignment (e.g., 'implementer', 'reviewer').

    .PARAMETER ModelId
    Canonical model identifier from the catalog.

    .PARAMETER ProjectPath
    Project root for resolving host-native file paths.

    .OUTPUTS
    PSCustomObject with Status (`applied` / `bootstrap_only` / `deferred` / `error`),
    Reason (optional), and PerHostPath (the file that was modified, when applicable).
    #>
    param(
        [Parameter(Mandatory = $true)]
        [ValidateSet('copilot', 'claude', 'codex', 'antigravity')]
        [string]$HostKind,

        [Parameter(Mandatory = $true)]
        [string]$Role,

        [Parameter(Mandatory = $true)]
        [string]$ModelId,

        [Parameter(Mandatory = $true)]
        [string]$ProjectPath
    )

    switch ($HostKind.ToLowerInvariant()) {
        'copilot'     { return (Set-CopilotModelOverride     -Role $Role -ModelId $ModelId -ProjectPath $ProjectPath) }
        'claude'      { return (Set-ClaudeSubagentModel      -Role $Role -ModelId $ModelId -ProjectPath $ProjectPath) }
        'codex'       { return (Set-CodexAgentModel          -Role $Role -ModelId $ModelId -ProjectPath $ProjectPath) }
        'antigravity' { return (Set-AntigravityModelOverride -Role $Role -ModelId $ModelId -ProjectPath $ProjectPath) }
    }
}

function Set-CopilotModelOverride {
    <#
    .SYNOPSIS
    Copilot host: write to .squad/config.json agentModelOverrides.
    Delegates to F-019's existing Set-SquadModelOverrides helper (battle-tested code path).
    #>
    param(
        [Parameter(Mandatory = $true)][string]$Role,
        [Parameter(Mandatory = $true)][string]$ModelId,
        [Parameter(Mandatory = $true)][string]$ProjectPath
    )

    $squadConfigPath = Join-Path $ProjectPath '.squad\config.json'
    if (-not (Test-Path -LiteralPath $squadConfigPath -PathType Leaf)) {
        return [pscustomobject]@{
            Status      = 'bootstrap_only'
            Reason      = 'Squad config not present on this Copilot project; routing decision logged in .squad/decisions.md but per-host injection skipped'
            PerHostPath = $null
            HostKind    = 'copilot'
        }
    }

    # The actual F-019 Set-SquadModelOverrides function is defined in scripts/specrew-start.ps1
    # and operates on the in-memory config plus persists to disk. F-041 invocation pattern:
    #
    #   $config = Get-SquadConfig -ProjectPath $ProjectPath
    #   Set-SquadModelOverrides -Config $config -Overrides @{ $Role = $ModelId }
    #   Save-SquadConfig -Config $config -ProjectPath $ProjectPath
    #
    # For the F-041 draft we delegate to a thin wrapper that the F-041
    # implementer wires up post-plan-boundary verdict.
    try {
        Invoke-SpecrewSetSquadModelOverride -ProjectPath $ProjectPath -Role $Role -ModelId $ModelId -ErrorAction Stop
        return [pscustomobject]@{
            Status      = 'applied'
            Reason      = $null
            PerHostPath = $squadConfigPath
            HostKind    = 'copilot'
        }
    }
    catch {
        return [pscustomobject]@{
            Status      = 'error'
            Reason      = "Set-SquadModelOverrides failed: $($_.Exception.Message)"
            PerHostPath = $squadConfigPath
            HostKind    = 'copilot'
        }
    }
}

function Set-ClaudeSubagentModel {
    <#
    .SYNOPSIS
    Claude host: write `model:` field in YAML frontmatter of .claude/agents/<role>.md.

    .DESCRIPTION
    Round-trip integrity: read existing file, parse frontmatter, set/replace the model: field,
    preserve all other frontmatter keys + body content, write back atomically.

    When `.claude/agents/<role>.md` doesn't exist (F-040 crew_runtime_status: bootstrap_only),
    returns the bootstrap_only sentinel — Proposal 024 Slice 3 fills that gap.
    #>
    param(
        [Parameter(Mandatory = $true)][string]$Role,
        [Parameter(Mandatory = $true)][string]$ModelId,
        [Parameter(Mandatory = $true)][string]$ProjectPath
    )

    $subagentPath = Join-Path $ProjectPath ".claude\agents\$Role.md"
    if (-not (Test-Path -LiteralPath $subagentPath -PathType Leaf)) {
        return [pscustomobject]@{
            Status      = 'bootstrap_only'
            Reason      = "Claude subagent file at $subagentPath not deployed (crew_runtime_install_required — Proposal 024 Slice 3)"
            PerHostPath = $subagentPath
            HostKind    = 'claude'
        }
    }

    try {
        $original = Get-Content -LiteralPath $subagentPath -Raw -Encoding UTF8

        # YAML frontmatter regex — captures opening ---, captures frontmatter body, captures closing ---
        $frontmatterPattern = '(?ms)\A(---\s*\r?\n)(.*?)(\r?\n---\s*\r?\n)'
        $match = [regex]::Match($original, $frontmatterPattern)
        if (-not $match.Success) {
            return [pscustomobject]@{
                Status      = 'error'
                Reason      = "Claude subagent file lacks YAML frontmatter delimiters: $subagentPath"
                PerHostPath = $subagentPath
                HostKind    = 'claude'
            }
        }

        $opening = $match.Groups[1].Value
        $frontmatterBody = $match.Groups[2].Value
        $closing = $match.Groups[3].Value
        $bodyAfter = $original.Substring($match.Length)

        # Update or insert the `model:` field. Preserves indentation + ordering of other keys.
        if ($frontmatterBody -match '(?m)^model\s*:\s*.+$') {
            $newFrontmatter = [regex]::Replace($frontmatterBody, '(?m)^model\s*:\s*.+$', "model: $ModelId")
        }
        else {
            # Append to end of frontmatter
            $newFrontmatter = $frontmatterBody.TrimEnd() + "`nmodel: $ModelId"
        }

        $rewritten = $opening + $newFrontmatter + $closing + $bodyAfter
        # Use atomic write helper from existing F-019 shared-governance toolkit
        Write-Utf8FileAtomic -Path $subagentPath -Content $rewritten

        return [pscustomobject]@{
            Status      = 'applied'
            Reason      = $null
            PerHostPath = $subagentPath
            HostKind    = 'claude'
        }
    }
    catch {
        return [pscustomobject]@{
            Status      = 'error'
            Reason      = "Set-ClaudeSubagentModel write failed: $($_.Exception.Message)"
            PerHostPath = $subagentPath
            HostKind    = 'claude'
        }
    }
}

function Set-CodexAgentModel {
    <#
    .SYNOPSIS
    Codex host: write `model = "..."` field in .codex/agents/<role>.toml.

    .DESCRIPTION
    Minimal TOML editor (sufficient for the narrow case of setting the model field).
    Preserves comments + ordering. Returns bootstrap_only when the agent .toml
    doesn't exist (Proposal 024 Slice 3 territory).
    #>
    param(
        [Parameter(Mandatory = $true)][string]$Role,
        [Parameter(Mandatory = $true)][string]$ModelId,
        [Parameter(Mandatory = $true)][string]$ProjectPath
    )

    $tomlPath = Join-Path $ProjectPath ".codex\agents\$Role.toml"
    if (-not (Test-Path -LiteralPath $tomlPath -PathType Leaf)) {
        return [pscustomobject]@{
            Status      = 'bootstrap_only'
            Reason      = "Codex agent .toml at $tomlPath not deployed (crew_runtime_install_required — Proposal 024 Slice 3)"
            PerHostPath = $tomlPath
            HostKind    = 'codex'
        }
    }

    try {
        $original = Get-Content -LiteralPath $tomlPath -Raw -Encoding UTF8

        # Look for an existing `model = "..."` line at the top level (NOT inside a [section])
        # Simple regex — TOML top-level keys appear before the first [section.header]
        if ($original -match '(?m)^model\s*=\s*".*"') {
            $rewritten = [regex]::Replace($original, '(?m)^model\s*=\s*".*"', "model = `"$ModelId`"")
        }
        else {
            # Insert before the first [section] header, or at the end if no sections
            $sectionMatch = [regex]::Match($original, '(?m)^\[')
            if ($sectionMatch.Success) {
                $insertPos = $sectionMatch.Index
                $rewritten = $original.Substring(0, $insertPos) + "model = `"$ModelId`"`n`n" + $original.Substring($insertPos)
            }
            else {
                $rewritten = $original.TrimEnd() + "`nmodel = `"$ModelId`"`n"
            }
        }

        Write-Utf8FileAtomic -Path $tomlPath -Content $rewritten

        return [pscustomobject]@{
            Status      = 'applied'
            Reason      = $null
            PerHostPath = $tomlPath
            HostKind    = 'codex'
        }
    }
    catch {
        return [pscustomobject]@{
            Status      = 'error'
            Reason      = "Set-CodexAgentModel write failed: $($_.Exception.Message)"
            PerHostPath = $tomlPath
            HostKind    = 'codex'
        }
    }
}

function Set-AntigravityModelOverride {
    <#
    .SYNOPSIS
    Antigravity host: per F-041 catalog schema, selector_strategy: cli_flag.
    No persistent per-host file to update (the -m <model> flag is per-invocation).
    F-041 records the routing decision; actual flag injection happens at launch
    time via the Antigravity follow-up slice.

    .DESCRIPTION
    Always returns `deferred` in F-041 v1 — Antigravity host is itself deferred
    from F-040 (clarify Q1). When the Antigravity follow-up slice ships, this
    function may be updated to write a per-invocation override file at
    `.specrew/per-invocation-overrides/antigravity-<role>.txt` or similar.
    For now, the routing decision is logged in .squad/decisions.md and Specrew
    relies on Antigravity's `-m` flag being passed at launch (separate concern).
    #>
    param(
        [Parameter(Mandatory = $true)][string]$Role,
        [Parameter(Mandatory = $true)][string]$ModelId,
        [Parameter(Mandatory = $true)][string]$ProjectPath
    )

    return [pscustomobject]@{
        Status      = 'deferred'
        Reason      = 'Antigravity host deferred per F-040 clarify Q1; routing decision logged but per-host injection not wired in F-041 v1'
        PerHostPath = $null
        HostKind    = 'antigravity'
    }
}

# Placeholder for the F-019 wrapper that the F-041 implementer wires up.
# DRAFT — pre-staged; final implementation will delegate to existing F-019 Set-SquadModelOverrides
# inside scripts/specrew-start.ps1 (or a refactored shared location).
function Invoke-SpecrewSetSquadModelOverride {
    param(
        [Parameter(Mandatory = $true)][string]$ProjectPath,
        [Parameter(Mandatory = $true)][string]$Role,
        [Parameter(Mandatory = $true)][string]$ModelId
    )
    throw "Invoke-SpecrewSetSquadModelOverride: WIRING-PENDING. Final implementation delegates to F-019's existing Set-SquadModelOverrides function in scripts/specrew-start.ps1. Will be wired up during F-041 implementation post-plan-boundary verdict."
}
