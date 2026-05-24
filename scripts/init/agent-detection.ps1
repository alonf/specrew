# Agent-detection helpers for specrew-init.ps1 (extracted via Proposal 108 Slice 6)
#
# Depends on: scripts/init/_utilities.ps1 (Invoke-NativeCommandForOutput, Get-FirstNonEmptyOutputLine)
#             hosts/_registry.ps1 (Invoke-HostHandler — to dispatch Get-CopilotSignals via the
#             host-package contract instead of the duplicated function)
#
# Functions:
#   - New-AgentRecord              build delegated-agent record
#   - Get-AgentLookup              build Name→record hashtable
#   - Get-GitHubAuthContext        probe "gh api /user"
#   - Get-DelegatedAgentMetadata   parse "copilot help config" for model families
#   - Get-AgentDetection           aggregate Copilot + delegated detection (CALLS REGISTRY for signals)
#   - Get-AgentSelectionMode       parse "--agents copilot,claude"
#   - Resolve-AgentSelection       apply selection to detected agents
#   - Format-AgentSummary          one-line summary for action log
#
# Slice 6 host-coupling notes (Phase D follow-up — NOT addressed in this slice):
# - Get-AgentSelectionMode (line ~1642 of original specrew-init.ps1): @('copilot','claude','codex')
#   hardcoded as the valid --agents catalog. Should derive from Get-RegisteredHostKinds filtered by
#   Status='supported'. Deferred because iteration-config.yml currently has only 3 agent slots —
#   adding antigravity to the validator without first adding the slot to the YAML schema causes
#   downstream init mismatches. Tracked for a dedicated host-coupling slice.
# - Get-AgentDetection seeds @(copilot/claude/codex) records on line ~550. Same issue. Same deferral.
# - Resolve-AgentSelection default-enables 'copilot' as the host fallback. Will derive from
#   Get-SpecrewDefaultHost (registry-driven) when iteration-config.yml schema migration lands.
# - Get-CopilotSignals (original lines 1452-1463) was DUPLICATED here and in hosts/copilot/handlers.ps1.
#   This slice DELETES the specrew-init.ps1 copy and rewires Get-AgentDetection to call the registry:
#     Invoke-HostHandler -Kind copilot -ContractFunction GetSignals
#   The hosts/copilot/handlers.ps1 copy is now the single source of truth.

Set-StrictMode -Version Latest

# Dot-source the host registry so Invoke-HostHandler is available (used by Get-AgentDetection)
$_registryFromInit = Join-Path (Split-Path -Parent (Split-Path -Parent $PSScriptRoot)) 'hosts\_registry.ps1'
if (Test-Path -LiteralPath $_registryFromInit -PathType Leaf) {
    . $_registryFromInit
}

Set-StrictMode -Version Latest

function New-AgentRecord {
    param(
        [Parameter(Mandatory = $true)]
        [string]$Name,

        [Parameter(Mandatory = $true)]
        [string]$AccessPath
    )

    return [pscustomobject]@{
        Name            = $Name
        AccessPath      = $AccessPath
        Availability    = 'unavailable'
        Enabled         = $false
        Detected        = $false
        DetectionSource = $null
    }
}

function Get-AgentLookup {
    param(
        [Parameter(Mandatory = $true)]
        [pscustomobject[]]$Agents
    )

    $lookup = @{}
    foreach ($agent in $Agents) {
        $lookup[$agent.Name] = $agent
    }

    return $lookup
}

function Get-GitHubAuthContext {
    param(
        [Parameter(Mandatory = $true)]
        [string]$WorkingDirectory
    )

    try {
        $probe = Invoke-NativeCommandForOutput -FilePath 'gh' -ArgumentList @('api', '/user') -WorkingDirectory $WorkingDirectory
    }
    catch {
        return [pscustomobject]@{
            Available = $false
            Source    = 'unavailable'
        }
    }

    return [pscustomobject]@{
        Available = ($probe.ExitCode -eq 0)
        Source    = if ($probe.ExitCode -eq 0) { 'gh api /user' } else { 'unavailable' }
    }
}

function Get-DelegatedAgentMetadata {
    param(
        [Parameter(Mandatory = $true)]
        [string]$WorkingDirectory
    )

    $families = [System.Collections.Generic.HashSet[string]]::new([System.StringComparer]::OrdinalIgnoreCase)
    $probe = Invoke-NativeCommandForOutput -FilePath 'copilot' -ArgumentList @('help', 'config') -WorkingDirectory $WorkingDirectory

    if ($probe.ExitCode -ne 0) {
        return [pscustomobject]@{
            Source    = 'unavailable'
            Families  = @()
            Available = $false
        }
    }

    $inModelSection = $false
    foreach ($line in $probe.Output) {
        if ($line -match '^\s*`model`') {
            $inModelSection = $true
            continue
        }

        if (-not $inModelSection) {
            continue
        }

        if ($line -match '^\s*`[^`]+`') {
            break
        }

        if ($line -match '^\s*-\s*"([^"]+)"') {
            $modelName = $Matches[1]
            if ($modelName -match '^claude-') {
                $null = $families.Add('claude')
            }

            if ($modelName -match 'codex') {
                $null = $families.Add('codex')
            }
        }
    }

    return [pscustomobject]@{
        Source    = 'copilot help config'
        Families  = @($families)
        Available = ($families.Count -gt 0)
    }
}

function Get-AgentDetection {
    param(
        [Parameter(Mandatory = $true)]
        [string]$WorkingDirectory
    )

    $agents = @(
        (New-AgentRecord -Name 'copilot' -AccessPath 'copilot_default'),
        (New-AgentRecord -Name 'claude' -AccessPath 'copilot_agent_hq'),
        (New-AgentRecord -Name 'codex' -AccessPath 'copilot_agent_hq')
    )
    $lookup = Get-AgentLookup -Agents $agents
    # Slice 6 rewire: dispatch Copilot env-var detection through the host-package registry.
    # Falls back to legacy Get-CopilotSignals if it still exists in scope (transition safety).
    if (Get-Command Invoke-HostHandler -ErrorAction SilentlyContinue) {
        $copilotSignals = @(Invoke-HostHandler -Kind copilot -ContractFunction GetSignals)
    }
    elseif (Get-Command Get-CopilotSignals -ErrorAction SilentlyContinue) {
        $copilotSignals = @(Get-CopilotSignals)
    }
    else {
        $copilotSignals = @()
    }
    $copilotVersion = $null
    $authContext = [pscustomobject]@{
        Available = $false
        Source    = 'unavailable'
    }

    try {
        $copilotVersionProbe = Invoke-NativeCommandForOutput -FilePath 'copilot' -ArgumentList @('--version') -WorkingDirectory $WorkingDirectory
        if ($copilotVersionProbe.ExitCode -eq 0) {
            $copilotVersion = ($copilotVersionProbe.Output -join [Environment]::NewLine).Trim()
            $copilotSignals += 'copilot --version'
        }
    }
    catch {
        $copilotVersion = $null
    }

    if ($copilotSignals.Count -gt 0) {
        $lookup['copilot'].Availability = 'available'
        $lookup['copilot'].Detected = $true
        $lookup['copilot'].DetectionSource = ($copilotSignals | Select-Object -Unique) -join ', '
    }

    $authContext = Get-GitHubAuthContext -WorkingDirectory $WorkingDirectory
    if ($authContext.Available -and $lookup['copilot'].Detected) {
        $detectionSources = @($lookup['copilot'].DetectionSource)
        $detectionSources += $authContext.Source
        $lookup['copilot'].DetectionSource = ($detectionSources | Where-Object {
                -not [string]::IsNullOrWhiteSpace($_)
            } | Select-Object -Unique) -join ', '
    }

    $delegatedMetadata = [pscustomobject]@{
        Source    = 'unavailable'
        Families  = @()
        Available = $false
    }

    try {
        $delegatedMetadata = Get-DelegatedAgentMetadata -WorkingDirectory $WorkingDirectory
    }
    catch {
        $delegatedMetadata = [pscustomobject]@{
            Source    = 'unavailable'
            Families  = @()
            Available = $false
        }
    }

    foreach ($family in $delegatedMetadata.Families) {
        if ($lookup.ContainsKey($family)) {
            $lookup[$family].Availability = 'available'
            $lookup[$family].Detected = $true
            $lookup[$family].DetectionSource = $delegatedMetadata.Source
        }
    }

    return [pscustomobject]@{
        Agents                     = $agents
        CopilotVersion             = $copilotVersion
        AuthContextAvailable       = $authContext.Available
        AuthContextSource          = $authContext.Source
        DelegatedMetadataSource    = $delegatedMetadata.Source
        DelegatedMetadataAvailable = $delegatedMetadata.Available
    }
}

function Get-AgentSelectionMode {
    param(
        [Parameter(Mandatory = $true)]
        [string]$RequestedAgents
    )

    $normalized = $RequestedAgents.Trim().ToLowerInvariant()
    if ([string]::IsNullOrWhiteSpace($normalized)) {
        throw 'Agent selection cannot be empty.'
    }

    if ($normalized -eq 'all') {
        return [pscustomobject]@{
            Mode  = 'all'
            Names = @()
        }
    }

    $names = @(
        $normalized.Split(',', [System.StringSplitOptions]::RemoveEmptyEntries) |
            ForEach-Object { $_.Trim() } |
            Where-Object { -not [string]::IsNullOrWhiteSpace($_) }
    )

    $invalidNames = @($names | Where-Object { $_ -notin @('copilot', 'claude', 'codex') })
    if ($invalidNames.Count -gt 0) {
        throw ("Unknown agent selection '{0}'. Valid values: copilot, claude, codex, all." -f ($invalidNames -join ', '))
    }

    return [pscustomobject]@{
        Mode  = 'list'
        Names = @($names | Select-Object -Unique)
    }
}

function Resolve-AgentSelection {
    param(
        [Parameter(Mandatory = $true)]
        [pscustomobject[]]$DetectedAgents,

        [Parameter(Mandatory = $true)]
        [bool]$DisableAll,

        [Parameter(Mandatory = $true)]
        [string]$RequestedAgents
    )

    $resolvedAgents = @(
        foreach ($agent in $DetectedAgents) {
            [pscustomobject]@{
                Name            = $agent.Name
                AccessPath      = $agent.AccessPath
                Availability    = $agent.Availability
                Enabled         = ($agent.Name -eq 'copilot')
                Detected        = $agent.Detected
                DetectionSource = $agent.DetectionSource
            }
        }
    )

    if ($DisableAll) {
        return $resolvedAgents
    }

    $selection = Get-AgentSelectionMode -RequestedAgents $RequestedAgents
    $lookup = Get-AgentLookup -Agents $resolvedAgents

    switch ($selection.Mode) {
        'all' {
            foreach ($agent in $resolvedAgents | Where-Object { $_.Availability -eq 'available' }) {
                $agent.Enabled = $true
            }
        }
        'list' {
            foreach ($name in $selection.Names) {
                if ($name -ne 'copilot') {
                    $lookup[$name].Enabled = $true
                }
            }
        }
    }

    return $resolvedAgents
}

function Format-AgentSummary {
    param(
        [Parameter(Mandatory = $true)]
        [pscustomobject[]]$Agents
    )

    return (
        $Agents |
            ForEach-Object {
                "{0}={1}/{2}" -f $_.Name, $_.Availability, ($(if ($_.Enabled) { 'enabled' } else { 'disabled' }))
            }
    ) -join '; '
}

