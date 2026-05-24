# Canonical team-location helpers (Proposal 108 Slice 9)
#
# Single source of truth for the Crew's 5-agent baseline + user-added specialists:
#
#   .specrew/team/
#   ├── agents/
#   │   ├── spec-steward.md          ← canonical charter (host-neutral markdown)
#   │   ├── planner.md
#   │   ├── implementer.md
#   │   ├── reviewer.md
#   │   ├── retro-facilitator.md
#   │   └── <user-added>.md          ← e.g., security-analyst.md
#   └── ROADMAP.md                   ← (future) team-history changelog
#
# Each host's Install-<Kind>CrewRuntime READS from this canonical location and TRANSLATES
# to its host-native format (.claude/agents/*.md, .codex/agents/*.toml, .squad/agents/*/charter.md, .agents/agents/*.md).
#
# When the user runs `specrew team add SecurityAnalyst`, the change writes here ONLY.
# Next `specrew start --host <X>` re-runs Install-<Kind>CrewRuntime to keep the host view in sync.
#
# The shipped baseline charters live in extensions/specrew-speckit/squad-templates/agents/<role>/charter.md.
# Initialize-SpecrewTeamCanonical copies them to .specrew/team/agents/<role>.md on greenfield init
# (without the surrounding directory wrapper — flatter shape, one file per agent).

Set-StrictMode -Version Latest

function Get-SpecrewTeamCanonicalPath {
    param([Parameter(Mandatory = $true)][string]$ProjectPath)
    return (Join-Path $ProjectPath '.specrew\team')
}

function Get-SpecrewTeamAgentsPath {
    param([Parameter(Mandatory = $true)][string]$ProjectPath)
    return (Join-Path (Get-SpecrewTeamCanonicalPath -ProjectPath $ProjectPath) 'agents')
}

function Get-SpecrewBaselineCrewRoles {
    return @('spec-steward', 'planner', 'implementer', 'reviewer', 'retro-facilitator')
}

function Get-SpecrewShippedCharterPath {
    <#
    .SYNOPSIS
    Resolve the path to a shipped baseline charter from the Specrew distribution root.
    Used by Initialize-SpecrewTeamCanonical to seed .specrew/team/ on first init.
    #>
    param([Parameter(Mandatory = $true)][string]$RoleName)

    # Walk up from this file until we find the Specrew distribution root (Specrew.psd1 marker)
    $root = $PSScriptRoot
    for ($i = 0; $i -lt 5; $i++) {
        if (Test-Path -LiteralPath (Join-Path $root 'Specrew.psd1') -PathType Leaf) {
            break
        }
        $parent = Split-Path -Parent $root
        if ([string]::IsNullOrWhiteSpace($parent) -or $parent -eq $root) {
            return $null
        }
        $root = $parent
    }
    return (Join-Path $root ("extensions/specrew-speckit/squad-templates/agents/{0}/charter.md" -f $RoleName))
}

function Get-SpecrewCanonicalCharterContent {
    <#
    .SYNOPSIS
    Read the canonical charter content for a given role from .specrew/team/agents/<role>.md.
    Falls back to the shipped template if the canonical doesn't exist yet.
    .OUTPUTS
    string (raw charter markdown) or $null if neither exists
    #>
    param(
        [Parameter(Mandatory = $true)][string]$ProjectPath,
        [Parameter(Mandatory = $true)][string]$RoleName
    )

    $canonical = Join-Path (Get-SpecrewTeamAgentsPath -ProjectPath $ProjectPath) ("{0}.md" -f $RoleName)
    if (Test-Path -LiteralPath $canonical -PathType Leaf) {
        return (Get-Content -LiteralPath $canonical -Raw -Encoding UTF8)
    }

    # Fallback to shipped template
    $shipped = Get-SpecrewShippedCharterPath -RoleName $RoleName
    if ($null -ne $shipped -and (Test-Path -LiteralPath $shipped -PathType Leaf)) {
        return (Get-Content -LiteralPath $shipped -Raw -Encoding UTF8)
    }

    return $null
}

function Get-SpecrewCanonicalAgentRoles {
    <#
    .SYNOPSIS
    Enumerate all agent roles present in the canonical .specrew/team/agents/ dir.
    Returns the baseline 5 + any user-added specialists.
    If the canonical dir doesn't exist, returns only the baseline.
    .OUTPUTS
    string[] (role names, e.g., 'spec-steward', 'planner', 'security-analyst')
    #>
    param([Parameter(Mandatory = $true)][string]$ProjectPath)

    $agentsDir = Get-SpecrewTeamAgentsPath -ProjectPath $ProjectPath
    if (-not (Test-Path -LiteralPath $agentsDir -PathType Container)) {
        return (Get-SpecrewBaselineCrewRoles)
    }

    $files = Get-ChildItem -Path $agentsDir -Filter '*.md' -ErrorAction SilentlyContinue
    if ($null -eq $files -or $files.Count -eq 0) {
        return (Get-SpecrewBaselineCrewRoles)
    }

    return @($files | ForEach-Object { [System.IO.Path]::GetFileNameWithoutExtension($_.Name) })
}

function Initialize-SpecrewTeamCanonical {
    <#
    .SYNOPSIS
    Populate .specrew/team/agents/ from the shipped baseline charters.
    Idempotent — preserves existing files (user customizations + user-added agents).
    .OUTPUTS
    pscustomobject @{ Actions[]; CanonicalRoot }
    #>
    param(
        [Parameter(Mandatory = $true)][string]$ProjectPath,
        [switch]$DryRun
    )

    $actions = New-Object System.Collections.Generic.List[hashtable]
    $canonicalRoot = Get-SpecrewTeamCanonicalPath -ProjectPath $ProjectPath
    $agentsDir = Get-SpecrewTeamAgentsPath -ProjectPath $ProjectPath

    if (-not (Test-Path -LiteralPath $agentsDir -PathType Container)) {
        if (-not $DryRun) {
            New-Item -ItemType Directory -Path $agentsDir -Force | Out-Null
        }
        $actions.Add(@{ Action = $(if ($DryRun) { 'would-create' } else { 'created' }); Path = $agentsDir }) | Out-Null
    }

    foreach ($role in Get-SpecrewBaselineCrewRoles) {
        $target = Join-Path $agentsDir ("{0}.md" -f $role)
        if (Test-Path -LiteralPath $target -PathType Leaf) {
            $actions.Add(@{ Action = 'preserved'; Path = $target }) | Out-Null
            continue
        }

        $shipped = Get-SpecrewShippedCharterPath -RoleName $role
        if ($null -eq $shipped -or -not (Test-Path -LiteralPath $shipped -PathType Leaf)) {
            $actions.Add(@{ Action = 'skipped'; Path = $target; Warning = "shipped baseline not found at expected path" }) | Out-Null
            continue
        }

        if ($DryRun) {
            $actions.Add(@{ Action = 'would-create'; Path = $target }) | Out-Null
        }
        else {
            $content = Get-Content -LiteralPath $shipped -Raw -Encoding UTF8
            [System.IO.File]::WriteAllText($target, $content, [System.Text.UTF8Encoding]::new($false))
            $actions.Add(@{ Action = 'created'; Path = $target }) | Out-Null
        }
    }

    return [pscustomobject]@{
        Actions       = $actions.ToArray()
        CanonicalRoot = $canonicalRoot
    }
}
