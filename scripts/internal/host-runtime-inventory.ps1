# Per-host Crew-runtime install detection (F-043 / Proposal 104)
#
# Helpers for determining whether each host has a Crew runtime deployed
# for the current project. Per spec FR-007 (specrew host status).
#
# Detection rules:
#   - copilot: .squad/ exists (Squad CLI deployed)
#   - claude:  .claude/agents/ exists with at least one *.md subagent file
#   - codex:   .codex/agents/ exists with at least one *.toml agent file
#
# DRAFT — pre-staged 2026-05-23. Pending F-040 + F-041 + F-042 merge +
# F-043 plan-boundary verdict before production wiring.

Set-StrictMode -Version Latest

function Test-CopilotRuntimeInstalled {
    <#
    .SYNOPSIS
    Copilot host's Crew runtime is Squad. Detect via presence of .squad/ directory.
    #>
    param([Parameter(Mandatory = $true)][string]$ProjectPath)
    $squadDir = Join-Path $ProjectPath '.squad'
    return [bool](Test-Path -LiteralPath $squadDir -PathType Container)
}

function Test-ClaudeRuntimeInstalled {
    <#
    .SYNOPSIS
    Claude host's Crew runtime is .claude/agents/ subagent files.
    Detect via .claude/agents/*.md existence (at least one).
    Proposal 024 Slice 3 ships the deploy logic; F-043 only detects.
    #>
    param([Parameter(Mandatory = $true)][string]$ProjectPath)
    $agentsDir = Join-Path $ProjectPath '.claude\agents'
    if (-not (Test-Path -LiteralPath $agentsDir -PathType Container)) {
        return $false
    }
    $subagentFiles = Get-ChildItem -Path $agentsDir -Filter '*.md' -ErrorAction SilentlyContinue
    return ([bool]$subagentFiles) -and ($subagentFiles.Count -gt 0)
}

function Test-CodexRuntimeInstalled {
    <#
    .SYNOPSIS
    Codex host's Crew runtime is .codex/agents/ TOML files.
    Detect via .codex/agents/*.toml existence (at least one).
    Proposal 024 Slice 3 ships the deploy logic; F-043 only detects.
    #>
    param([Parameter(Mandatory = $true)][string]$ProjectPath)
    $agentsDir = Join-Path $ProjectPath '.codex\agents'
    if (-not (Test-Path -LiteralPath $agentsDir -PathType Container)) {
        return $false
    }
    $tomlFiles = Get-ChildItem -Path $agentsDir -Filter '*.toml' -ErrorAction SilentlyContinue
    return ([bool]$tomlFiles) -and ($tomlFiles.Count -gt 0)
}

function Test-AntigravityRuntimeInstalled {
    <#
    .SYNOPSIS
    Antigravity host's Crew runtime convention is TBD until Antigravity follow-up
    slice ships. F-043 v1 always returns $false.
    #>
    param([Parameter(Mandatory = $true)][string]$ProjectPath)
    return $false
}

function Get-SpecrewHostRuntimeInventory {
    <#
    .SYNOPSIS
    Aggregate per-host Crew-runtime install state for this project.

    .OUTPUTS
    Hashtable keyed by host kind with @{ installed = $bool; path = $string-or-null }.
    #>
    param([Parameter(Mandatory = $true)][string]$ProjectPath)

    $result = [ordered]@{}

    if (Test-CopilotRuntimeInstalled -ProjectPath $ProjectPath) {
        $result['copilot'] = @{ installed = $true; path = (Join-Path $ProjectPath '.squad') }
    }
    else {
        $result['copilot'] = @{ installed = $false; path = $null }
    }

    if (Test-ClaudeRuntimeInstalled -ProjectPath $ProjectPath) {
        $result['claude'] = @{ installed = $true; path = (Join-Path $ProjectPath '.claude\agents') }
    }
    else {
        $result['claude'] = @{ installed = $false; path = $null }
    }

    if (Test-CodexRuntimeInstalled -ProjectPath $ProjectPath) {
        $result['codex'] = @{ installed = $true; path = (Join-Path $ProjectPath '.codex\agents') }
    }
    else {
        $result['codex'] = @{ installed = $false; path = $null }
    }

    if (Test-AntigravityRuntimeInstalled -ProjectPath $ProjectPath) {
        $result['antigravity'] = @{ installed = $true; path = (Join-Path $ProjectPath '.agents\agents') }
    }
    else {
        $result['antigravity'] = @{ installed = $false; path = $null }
    }

    return $result
}
