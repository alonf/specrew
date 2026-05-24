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

function Get-SpecrewCharterTagline {
    <#
    .SYNOPSIS
    Extract a one-line description from a charter's markdown — the first blockquote line
    after the title, which by convention is the role's tagline. Used by per-host handlers
    to derive `description:` frontmatter / TOML fields when translating canonical charters
    to host-native subagent formats.
    .OUTPUTS
    string — the tagline if found, otherwise a generic "Specrew Crew specialist: <role>." fallback.
    #>
    param(
        [Parameter(Mandatory = $true)][string]$Charter,
        [Parameter(Mandatory = $true)][string]$Role
    )

    $lines = @($Charter -split "`r?`n" | Where-Object { -not [string]::IsNullOrWhiteSpace($_) })
    foreach ($line in $lines) {
        if ($line -match '^>\s*(.+?)\s*$') {
            return $Matches[1]
        }
    }
    return ("Specrew Crew specialist: {0}." -f $Role)
}

function Test-SpecrewManagedFile {
    <#
    .SYNOPSIS
    Decide whether a host-native subagent file at $Path is safe for Install-<Kind>CrewRuntime to overwrite.
    .DESCRIPTION
    Returns $true if any of the following hold:
      - The file is missing (safe to create).
      - A sidecar marker exists at `$Path + '.specrew-managed'`. Used for hosts whose native
        format does not tolerate an inline comment header (e.g., Copilot's `.squad/agents/<role>/charter.md`
        which Squad CLI parses as the charter body itself).
      - The file contains a "Specrew-managed" comment (`#`, `--`, or `<!--` syntax).
    Returns $false if the file exists without any of those markers, indicating user customization.
    .OUTPUTS
    [bool]
    #>
    param([Parameter(Mandatory = $true)][string]$Path)

    if (-not (Test-Path -LiteralPath $Path -PathType Leaf)) {
        return $true
    }
    if (Test-Path -LiteralPath ("{0}.specrew-managed" -f $Path) -PathType Leaf) {
        return $true
    }
    $content = Get-Content -LiteralPath $Path -Raw -Encoding UTF8 -ErrorAction SilentlyContinue
    if ([string]::IsNullOrEmpty($content)) {
        return $true
    }
    return ($content -match '(?m)^\s*(#|--|<!--)\s*Specrew-managed')
}

function Write-SpecrewManagedSidecar {
    <#
    .SYNOPSIS
    Write a sidecar marker (`<Path>.specrew-managed`) signaling that $Path is Specrew-managed
    without modifying $Path's content. Used by Install-CopilotCrewRuntime so `charter.md`
    stays byte-identical to the canonical charter (Squad CLI consumes the file as the body).
    #>
    param([Parameter(Mandatory = $true)][string]$Path)
    $marker = "{0}.specrew-managed" -f $Path
    [System.IO.File]::WriteAllText($marker, "Generated from .specrew/team/agents/. Delete this file to retain a user-customized $Path on next specrew start.`n", [System.Text.UTF8Encoding]::new($false))
}

function Get-SpecrewHostAgentRoot {
    <#
    .SYNOPSIS
    Resolve the per-host agent-root directory from the manifest's AgentDir field.
    Open-Closed: every supported host declares AgentDir in its manifest, so adding
    a new host adds one manifest line, no edits to the Install-<Kind>CrewRuntime
    handlers or the host-runtime-inventory iterator.
    .OUTPUTS
    string (absolute path with platform-native separators, trailing separator stripped)
    .NOTES
    Throws if the manifest is missing or doesn't declare AgentDir — by design.
    A "supported" host without AgentDir cannot deploy its Crew runtime.
    #>
    param(
        [Parameter(Mandatory = $true)][string]$HostKind,
        [Parameter(Mandatory = $true)][string]$ProjectPath
    )

    $manifest = Get-HostManifest -Kind $HostKind
    if (-not $manifest.ContainsKey('AgentDir') -or [string]::IsNullOrWhiteSpace([string]$manifest.AgentDir)) {
        throw "Host '$HostKind' manifest is missing required AgentDir field. Add AgentDir to hosts/$HostKind/host.psd1."
    }

    $rel = ([string]$manifest.AgentDir) -replace '/', [System.IO.Path]::DirectorySeparatorChar
    return (Join-Path $ProjectPath $rel.TrimEnd([System.IO.Path]::DirectorySeparatorChar))
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
