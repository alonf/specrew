[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)]
    [string]$IterationDirectory,

    [switch]$PassThru
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

function Resolve-ProjectRoot {
    param([string]$StartPath)

    $current = [System.IO.DirectoryInfo]::new([System.IO.Path]::GetFullPath($StartPath))
    while ($null -ne $current) {
        if ((Test-Path -LiteralPath (Join-Path $current.FullName '.squad') -PathType Container) -or
            (Test-Path -LiteralPath (Join-Path $current.FullName '.specrew') -PathType Container)) {
            return $current.FullName
        }

        $current = $current.Parent
    }

    throw "Could not resolve project root from '$StartPath'."
}

function Get-SquadConfigPath {
    param([string]$Root)

    return Join-Path $Root '.squad\config.json'
}

function Get-SquadConfig {
    param([string]$Root)

    $configPath = Get-SquadConfigPath -Root $Root
    if (-not (Test-Path -LiteralPath $configPath -PathType Leaf)) {
        return [ordered]@{ version = 1 }
    }

    $config = Get-Content -LiteralPath $configPath -Raw -Encoding UTF8 | ConvertFrom-Json -AsHashtable
    if ($null -eq $config) {
        return [ordered]@{ version = 1 }
    }

    return $config
}

function Convert-ToOrderedMap {
    param([AllowNull()]$Value)

    $result = [ordered]@{}
    if ($null -eq $Value) {
        return $result
    }

    if ($Value -is [System.Collections.IDictionary]) {
        foreach ($key in $Value.Keys) {
            $result[[string]$key] = $Value[$key]
        }

        return $result
    }

    foreach ($property in $Value.PSObject.Properties) {
        $result[$property.Name] = $property.Value
    }

    return $result
}

function Test-MapKey {
    param(
        [System.Collections.IDictionary]$Map,
        [string]$Key
    )

    if ($null -eq $Map) {
        return $false
    }

    return $Map.Contains($Key)
}

function Get-ManagedRoutingMetadata {
    param([System.Collections.IDictionary]$Config)

    if (Test-MapKey -Map $Config -Key 'specrewManagedModelRouting') {
        return Convert-ToOrderedMap -Value $Config['specrewManagedModelRouting']
    }

    return [ordered]@{}
}

function Get-BaselineOverrides {
    param(
        [System.Collections.IDictionary]$Config,
        [System.Collections.IDictionary]$ManagedRouting
    )

    if (Test-MapKey -Map $ManagedRouting -Key 'baselineAgentModelOverrides') {
        return Convert-ToOrderedMap -Value $ManagedRouting['baselineAgentModelOverrides']
    }

    if (Test-MapKey -Map $Config -Key 'agentModelOverrides') {
        return Convert-ToOrderedMap -Value $Config['agentModelOverrides']
    }

    return [ordered]@{}
}

function Get-RoleAgentFamilies {
    param([System.Collections.IDictionary]$ManagedRouting)

    if (Test-MapKey -Map $ManagedRouting -Key 'roleAgentFamilies') {
        return Convert-ToOrderedMap -Value $ManagedRouting['roleAgentFamilies']
    }

    return [ordered]@{}
}

function Get-ModelForEscalation {
    param(
        [string]$AgentFamily,
        [string]$Tier
    )

    switch ($AgentFamily) {
        'claude' {
            switch ($Tier) {
                'deep' { return 'claude-opus-4.7' }
                'balanced' { return 'claude-sonnet-4.5' }
                default { return 'claude-haiku-4.5' }
            }
        }
        'codex' {
            switch ($Tier) {
                'deep' { return 'gpt-5.5' }
                'balanced' { return 'gpt-5.3-codex' }
                default { return 'gpt-5.2-codex' }
            }
        }
        default {
            switch ($Tier) {
                'deep' { return 'gpt-5.4' }
                'balanced' { return 'gpt-5.2' }
                default { return 'gpt-5-mini' }
            }
        }
    }
}

$resolvedIterationDirectory = [System.IO.Path]::GetFullPath($IterationDirectory)
$projectRoot = Resolve-ProjectRoot -StartPath $resolvedIterationDirectory
$manageEscalationPath = Join-Path $PSScriptRoot 'manage-escalation-state.ps1'
if (-not (Test-Path -LiteralPath $manageEscalationPath -PathType Leaf)) {
    throw "Missing escalation helper '$manageEscalationPath'."
}

$escalation = & $manageEscalationPath -IterationDirectory $resolvedIterationDirectory -Mode get -PassThru
$config = Get-SquadConfig -Root $projectRoot
if (-not (Test-MapKey -Map $config -Key 'version')) {
    $config['version'] = 1
}

$managedRouting = Get-ManagedRoutingMetadata -Config $config
$baselineOverrides = Get-BaselineOverrides -Config $config -ManagedRouting $managedRouting
$roleAgentFamilies = Get-RoleAgentFamilies -ManagedRouting $managedRouting
$effectiveOverrides = [ordered]@{}
foreach ($key in $baselineOverrides.Keys) {
    $effectiveOverrides[$key] = $baselineOverrides[$key]
}

$appliedModel = $null
$roleName = $null
if ($escalation.status -eq 'active' -and -not [string]::IsNullOrWhiteSpace($escalation.current_owner)) {
    $roleName = $escalation.current_owner.Trim()
    $agentFamily = if (Test-MapKey -Map $roleAgentFamilies -Key $roleName) { [string]$roleAgentFamilies[$roleName] } else { 'copilot' }
    $appliedModel = Get-ModelForEscalation -AgentFamily $agentFamily -Tier $escalation.current_tier
    $effectiveOverrides[$roleName] = $appliedModel
}

if ($effectiveOverrides.Count -gt 0) {
    $config['agentModelOverrides'] = $effectiveOverrides
}
elseif (Test-MapKey -Map $config -Key 'agentModelOverrides') {
    $config.Remove('agentModelOverrides')
}

$managedRouting['baselineAgentModelOverrides'] = $baselineOverrides
$managedRouting['roleAgentFamilies'] = $roleAgentFamilies
$managedRouting['activeEscalation'] = [ordered]@{
    status          = $escalation.status
    role            = $roleName
    tier            = $escalation.current_tier
    sourceIteration = $resolvedIterationDirectory
    sourceArtifact  = $escalation.artifact
    sourceGate      = $escalation.gate
    updatedAt       = (Get-Date).ToUniversalTime().ToString('yyyy-MM-ddTHH:mm:ssZ')
}
$config['specrewManagedModelRouting'] = $managedRouting

$configPath = Get-SquadConfigPath -Root $projectRoot
$json = $config | ConvertTo-Json -Depth 10
[System.IO.File]::WriteAllText($configPath, $json + [Environment]::NewLine, [System.Text.UTF8Encoding]::new($false))

$result = [pscustomobject]@{
    project_root          = $projectRoot
    iteration_directory   = $resolvedIterationDirectory
    escalation_status     = $escalation.status
    escalation_role       = $roleName
    escalation_tier       = $escalation.current_tier
    applied_model         = $appliedModel
    agent_model_overrides = $effectiveOverrides
}

if ($PassThru) {
    $result
    return
}

$result | ConvertTo-Json -Depth 10
exit 0
