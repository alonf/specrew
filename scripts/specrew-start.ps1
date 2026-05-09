[CmdletBinding()]
param(
    [Parameter(Mandatory = $false, Position = 0)]
    [string]$FeatureRequest,

    [Parameter(Mandatory = $false)]
    [string]$ProjectPath = '.',

    [Parameter(Mandatory = $false)]
    [string]$ResumeFeature,

    [Parameter(Mandatory = $false)]
    [string]$Agent = 'Squad',

    [switch]$NoLaunch,
    [switch]$NewWindow,
    [switch]$SameWindow,
    [switch]$AllowAll,
    [switch]$PromptApprovals,
    [switch]$Help,

    [Parameter(ValueFromRemainingArguments = $true)]
    [string[]]$CliArgs
)

$sharedGovernancePath = Join-Path (Split-Path -Parent $PSScriptRoot) 'extensions\specrew-speckit\scripts\shared-governance.ps1'
if (-not (Test-Path -LiteralPath $sharedGovernancePath -PathType Leaf)) {
    throw "Missing shared governance helper '$sharedGovernancePath'."
}
. $sharedGovernancePath

function Convert-UnixStyleArguments {
    param(
        [string]$FeatureRequest,
        [string]$ProjectPath,
        [string]$ResumeFeature,
        [string]$Agent,
        [bool]$NoLaunch,
        [bool]$NewWindow,
        [bool]$AllowAll,
        [bool]$PromptApprovals,
        [bool]$Help,
        [string[]]$CliArgs
    )

    $result = [ordered]@{
        FeatureRequest = $FeatureRequest
        ProjectPath    = $ProjectPath
        ResumeFeature  = $ResumeFeature
        Agent          = $Agent
        NoLaunch       = $NoLaunch
        NewWindow      = $false
        SameWindow     = $false
        AllowAll       = $AllowAll
        PromptApprovals = $PromptApprovals
        Help           = $Help
    }

    if (-not $CliArgs -or $CliArgs.Count -eq 0) {
        return [pscustomobject]$result
    }

    $i = 0
    while ($i -lt $CliArgs.Count) {
        $arg = $CliArgs[$i]
        switch ($arg) {
            '--project-path' {
                $i++
                if ($i -lt $CliArgs.Count) { $result.ProjectPath = $CliArgs[$i] }
            }
            '--feature-request' {
                $i++
                if ($i -lt $CliArgs.Count) { $result.FeatureRequest = $CliArgs[$i] }
            }
            '--resume-feature' {
                $i++
                if ($i -lt $CliArgs.Count) { $result.ResumeFeature = $CliArgs[$i] }
            }
            '--agent' {
                $i++
                if ($i -lt $CliArgs.Count) { $result.Agent = $CliArgs[$i] }
            }
            '--no-launch' {
                $result.NoLaunch = $true
            }
            '--new-window' {
                $result.NewWindow = $true
            }
            '--same-window' {
                $result.SameWindow = $true
            }
            '--allow-all' {
                $result.AllowAll = $true
            }
            '--prompt-approvals' {
                $result.PromptApprovals = $true
            }
            '--help' {
                $result.Help = $true
            }
            default {
                if (-not $result.FeatureRequest) {
                    $result.FeatureRequest = $arg
                }
                else {
                    $result.FeatureRequest = '{0} {1}' -f $result.FeatureRequest, $arg
                }
            }
        }

        $i++
    }

    return [pscustomobject]$result
}

$parsedArgs = Convert-UnixStyleArguments `
    -FeatureRequest $FeatureRequest `
    -ProjectPath $ProjectPath `
    -ResumeFeature $ResumeFeature `
    -Agent $Agent `
    -NoLaunch $NoLaunch.IsPresent `
    -NewWindow $NewWindow.IsPresent `
    -SameWindow $SameWindow.IsPresent `
    -AllowAll $AllowAll.IsPresent `
    -PromptApprovals $PromptApprovals.IsPresent `
    -Help $Help.IsPresent `
    -CliArgs $CliArgs

$FeatureRequest = $parsedArgs.FeatureRequest
$ProjectPath = $parsedArgs.ProjectPath
$ResumeFeature = $parsedArgs.ResumeFeature
$Agent = $parsedArgs.Agent
$NoLaunch = [bool]$parsedArgs.NoLaunch
$NewWindow = [bool]$parsedArgs.NewWindow
$SameWindow = [bool]$parsedArgs.SameWindow
$AllowAll = [bool]$parsedArgs.AllowAll
$PromptApprovals = [bool]$parsedArgs.PromptApprovals
$Help = [bool]$parsedArgs.Help

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

function Show-Usage {
    @'
specrew start - Start or resume the Squad-driven Spec Kit lifecycle

Usage:
  specrew start
  specrew start "Build a reporting dashboard"
  specrew start --feature-request "Add SSO login"
  specrew start --resume-feature auto

Options:
  -ProjectPath | --project-path <path>     Target project directory (defaults to current directory)
  -ResumeFeature | --resume-feature <path|auto>
                                           Resume an existing feature directory, or use "auto"
  -Agent | --agent <name>                  Copilot agent to launch (default: Squad)
  -NoLaunch | --no-launch                  Generate handoff prompt/context but do not launch Copilot
  -NewWindow | --new-window                Launch Copilot in a new PowerShell window instead of the current terminal
  -SameWindow | --same-window              Compatibility alias for the default current-terminal launch mode
  -AllowAll | --allow-all                  Explicitly launch Copilot with --allow-all (default behavior)
  -PromptApprovals | --prompt-approvals    Keep Copilot's interactive approval prompts enabled
  -Help | --help                           Show this help message

 Notes:
    - Running specrew start with no arguments launches Squad in intake/resume mode.
    - Squad should continue any in-progress feature when possible, or gather the missing feature/fix details from the human developer.
    - A quoted feature request is optional shorthand for a new feature, not a full spec document.
     - Specrew launches Copilot from the target project directory, reuses the current terminal by default, and only uses --new-window when you explicitly ask for a detached shell.
     - Intake-first runs stay out of autopilot until the feature request is grounded; once scope is grounded, Specrew defaults to --allow-all to reduce approval blocking.
     - Copilot CLI may still ask you to trust the project directory on first launch.
     - If Copilot CLI is unavailable, Specrew still writes a handoff prompt and context file.
'@ | Write-Host
}

function Write-Success {
    param([string]$Message)
    Write-Host $Message -ForegroundColor Green
}

function Write-Error-Message {
    param([string]$Message)
    Write-Host "ERROR: $Message" -ForegroundColor Red
}

function Write-Info {
    param([string]$Message)
    Write-Host $Message -ForegroundColor Cyan
}

function Test-BootstrapSurface {
    param(
        [string]$Root,
        [string]$RelativePath
    )

    return Test-Path -LiteralPath (Join-Path $Root $RelativePath)
}

function Resolve-FeatureDirectory {
    param(
        [string]$Root,
        [string]$ResumeFeature
    )

    if ($ResumeFeature) {
        if ($ResumeFeature -eq 'auto') {
            $featureJsonPath = Join-Path $Root '.specify\feature.json'
            if (-not (Test-Path -LiteralPath $featureJsonPath)) {
                throw "Cannot resolve --resume-feature auto because '.specify\feature.json' is missing."
            }

            $featureJson = Get-Content -LiteralPath $featureJsonPath -Raw | ConvertFrom-Json
            if (-not $featureJson.feature_directory) {
                throw "Cannot resolve --resume-feature auto because '.specify\feature.json' does not contain feature_directory."
            }

            $candidate = [string]$featureJson.feature_directory
            if (-not [System.IO.Path]::IsPathRooted($candidate)) {
                $candidate = Join-Path $Root $candidate
            }

            return [System.IO.Path]::GetFullPath($candidate)
        }

        $candidatePath = $ResumeFeature
        if (-not [System.IO.Path]::IsPathRooted($candidatePath)) {
            $candidatePath = Join-Path $Root $candidatePath
        }

        return [System.IO.Path]::GetFullPath($candidatePath)
    }

    $featureJsonPath = Join-Path $Root '.specify\feature.json'
    if (Test-Path -LiteralPath $featureJsonPath) {
        try {
            $featureJson = Get-Content -LiteralPath $featureJsonPath -Raw | ConvertFrom-Json
            if ($featureJson.feature_directory) {
                $candidate = [string]$featureJson.feature_directory
                if (-not [System.IO.Path]::IsPathRooted($candidate)) {
                    $candidate = Join-Path $Root $candidate
                }

                return [System.IO.Path]::GetFullPath($candidate)
            }
        }
        catch {
            throw "Failed to parse '.specify\feature.json': $($_.Exception.Message)"
        }
    }

    return $null
}

function Get-MarkdownContent {
    param([string]$Path)

    return @(Get-Content -LiteralPath $Path -Encoding UTF8)
}

function Get-MarkdownSectionTable {
    param(
        [string[]]$Lines,
        [string]$Heading
    )

    $headingPattern = '^##\s+' + [regex]::Escape($Heading) + '\b'
    $startIndex = -1

    for ($index = 0; $index -lt $Lines.Count; $index++) {
        if ($Lines[$index] -match $headingPattern) {
            $startIndex = $index
            break
        }
    }

    if ($startIndex -lt 0) {
        return @()
    }

    $tableLines = New-Object System.Collections.Generic.List[string]
    for ($index = $startIndex + 1; $index -lt $Lines.Count; $index++) {
        $currentLine = $Lines[$index]
        if ($currentLine -match '^##\s+') {
            break
        }

        if ($currentLine.Trim().StartsWith('|')) {
            $null = $tableLines.Add($currentLine)
        }
    }

    if ($tableLines.Count -lt 2) {
        return @()
    }

    $headers = ($tableLines[0].Trim('|') -split '\|') | ForEach-Object { $_.Trim() }
    $rows = New-Object System.Collections.Generic.List[object]

    for ($rowIndex = 1; $rowIndex -lt $tableLines.Count; $rowIndex++) {
        $cells = ($tableLines[$rowIndex].Trim('|') -split '\|') | ForEach-Object { $_.Trim() }
        $isSeparator = $true

        foreach ($cell in $cells) {
            if ($cell -notmatch '^:?-{3,}:?$') {
                $isSeparator = $false
                break
            }
        }

        if ($isSeparator) {
            continue
        }

        $row = [ordered]@{}
        for ($cellIndex = 0; $cellIndex -lt $headers.Count; $cellIndex++) {
            $value = if ($cellIndex -lt $cells.Count) { $cells[$cellIndex] } else { '' }
            $row[$headers[$cellIndex]] = $value
        }

        $rows.Add([pscustomobject]$row)
    }

    return $rows.ToArray()
}

function ConvertFrom-YamlBoolean {
    param([AllowNull()][string]$Value)

    if ([string]::IsNullOrWhiteSpace($Value)) {
        return $false
    }

    return $Value.Trim().ToLowerInvariant() -in @('true', 'yes', 'on')
}

function Get-TeamRoster {
    param([string]$Root)

    $teamPath = Join-Path $Root '.squad\team.md'
    if (-not (Test-Path -LiteralPath $teamPath -PathType Leaf)) {
        return [pscustomobject]@{
            team_path              = $teamPath
            mode                   = 'missing'
            team_status_configured = $false
            baseline_roles         = @()
            supplemental_members   = @()
        }
    }

    $teamContent = Get-Content -LiteralPath $teamPath -Raw -Encoding UTF8
    $teamLines = Get-MarkdownContent -Path $teamPath
    $baselineRoles = @(
        Get-MarkdownSectionTable -Lines $teamLines -Heading 'Specrew Baseline Roles' |
            ForEach-Object {
                [pscustomobject]@{
                    role    = [string]$_.Role
                    charter = [string]$_.Charter
                    status  = [string]$_.Status
                    type    = 'baseline'
                }
            }
    )
    $supplementalMembers = @(
        Get-MarkdownSectionTable -Lines $teamLines -Heading 'Domain-Specific Members' |
            ForEach-Object {
                [pscustomobject]@{
                    role    = [string]$_.Role
                    charter = [string]$_.Charter
                    status  = [string]$_.Status
                    type    = 'supplemental'
                }
            }
    )

    return [pscustomobject]@{
        team_path              = $teamPath
        mode                   = if ($baselineRoles.Count -gt 0) { 'specrew-managed' } else { 'generic-squad' }
        team_status_configured = ($teamContent -match '\*\*Team Status\*\*:\s*configured')
        baseline_roles         = @($baselineRoles)
        supplemental_members   = @($supplementalMembers)
    }
}

function Get-IterationAgentConfig {
    param([string]$Root)

    $configPath = Join-Path $Root '.specrew\iteration-config.yml'
    $agents = [ordered]@{
        copilot = [pscustomobject]@{
            name        = 'copilot'
            enabled     = $true
            access_path = 'copilot_default'
            availability = 'available'
        }
        claude = [pscustomobject]@{
            name        = 'claude'
            enabled     = $false
            access_path = 'copilot_agent_hq'
            availability = 'unavailable'
        }
        codex = [pscustomobject]@{
            name        = 'codex'
            enabled     = $false
            access_path = 'copilot_agent_hq'
            availability = 'unavailable'
        }
    }

    if (-not (Test-Path -LiteralPath $configPath -PathType Leaf)) {
        return $agents
    }

    $lines = Get-MarkdownContent -Path $configPath
    $inManagedAgentsBlock = $false
    $currentAgent = $null
    foreach ($line in $lines) {
        if ($line -match '^# >>> specrew-managed agents >>>') {
            $inManagedAgentsBlock = $true
            continue
        }

        if (-not $inManagedAgentsBlock) {
            continue
        }

        if ($line -match '^# <<< specrew-managed agents <<<') {
            break
        }

        if ($line -match '^\s{2}([a-z0-9_-]+):\s*$') {
            $currentAgent = $Matches[1]
            continue
        }

        if (-not $currentAgent -or -not $agents.Contains($currentAgent)) {
            continue
        }

        if ($line -match '^\s{4}enabled:\s*("?)([^"#]+)\1\s*$') {
            $agents[$currentAgent].enabled = ConvertFrom-YamlBoolean -Value $Matches[2]
            continue
        }

        if ($line -match '^\s{4}access_path:\s*("?)([^"#]+)\1\s*$') {
            $agents[$currentAgent].access_path = $Matches[2].Trim()
            continue
        }

        if ($line -match '^\s{4}availability:\s*("?)([^"#]+)\1\s*$') {
            $agents[$currentAgent].availability = $Matches[2].Trim()
        }
    }

    return $agents
}

function Get-RoleAssignments {
    param([string]$Root)

    $roleAssignmentsPath = Join-Path $Root '.specrew\role-assignments.yml'
    if (-not (Test-Path -LiteralPath $roleAssignmentsPath -PathType Leaf)) {
        return @()
    }

    $lines = Get-MarkdownContent -Path $roleAssignmentsPath
    $roles = New-Object System.Collections.Generic.List[object]
    $currentRole = $null

    foreach ($line in $lines) {
        if ($line -match '^\s*-\s*name:\s*"([^"]+)"') {
            if ($null -ne $currentRole) {
                $roles.Add([pscustomobject]$currentRole)
            }

            $currentRole = [ordered]@{
                name            = $Matches[1]
                type            = $null
                assigned_to     = $null
                preferred_agent = 'copilot'
            }
            continue
        }

        if ($null -eq $currentRole) {
            continue
        }

        if ($line -match '^\s{4}type:\s*"([^"]+)"') {
            $currentRole.type = $Matches[1]
            continue
        }

        if ($line -match '^\s{4}assigned_to:\s*"([^"]*)"') {
            $currentRole.assigned_to = $Matches[1]
            continue
        }

        if ($line -match '^\s{4}preferred_agent:\s*"([^"]+)"') {
            $currentRole.preferred_agent = $Matches[1].Trim().ToLowerInvariant()
        }
    }

    if ($null -ne $currentRole) {
        $roles.Add([pscustomobject]$currentRole)
    }

    return $roles.ToArray()
}

function Get-PreferredEnabledAgent {
    param(
        [string[]]$EnabledAgents,
        [string[]]$Priority,
        [string]$Exclude
    )

    foreach ($candidate in $Priority) {
        if (($EnabledAgents -contains $candidate) -and ($candidate -ne $Exclude)) {
            return $candidate
        }
    }

    return $null
}

function Resolve-RoleAgentPlan {
    param(
        [string]$RoleName,
        [string]$PreferredAgent,
        [System.Collections.IDictionary]$AgentLookup,
        [string[]]$EnabledAgents,
        [string]$ImplementerAgent,
        [switch]$RequireIndependentOversight
    )

    $requestedAgent = if ([string]::IsNullOrWhiteSpace($PreferredAgent)) { 'copilot' } else { $PreferredAgent.Trim().ToLowerInvariant() }
    $fallbackReasons = New-Object System.Collections.Generic.List[string]
    $effectiveAgent = $null

    if ($EnabledAgents -contains $requestedAgent) {
        $effectiveAgent = $requestedAgent
    }
    else {
        $null = $fallbackReasons.Add(("preferred agent '{0}' is not enabled" -f $requestedAgent))
    }

    if ($RequireIndependentOversight -and $EnabledAgents.Count -gt 1 -and $effectiveAgent -eq $ImplementerAgent) {
        $null = $fallbackReasons.Add('independent oversight requires a different agent than Implementer')
        $effectiveAgent = Get-PreferredEnabledAgent -EnabledAgents $EnabledAgents -Priority @('claude', 'codex', 'copilot') -Exclude $ImplementerAgent
    }

    if (-not $effectiveAgent) {
        $fallbackPriority = if ($RequireIndependentOversight -and $EnabledAgents.Count -gt 1) {
            @('claude', 'codex', 'copilot')
        }
        else {
            @('copilot', 'claude', 'codex')
        }

        $effectiveAgent = Get-PreferredEnabledAgent -EnabledAgents $EnabledAgents -Priority $fallbackPriority -Exclude $(if ($RequireIndependentOversight -and $EnabledAgents.Count -gt 1) { $ImplementerAgent } else { $null })
        if (-not $effectiveAgent) {
            $effectiveAgent = Get-PreferredEnabledAgent -EnabledAgents $EnabledAgents -Priority @('copilot', 'claude', 'codex') -Exclude $null
        }
    }

    $effectiveAgentConfig = $AgentLookup[$effectiveAgent]
    return [pscustomobject]@{
        role             = $RoleName
        requested_agent  = $requestedAgent
        effective_agent  = $effectiveAgent
        delegated        = ($effectiveAgent -ne 'copilot')
        access_path      = if ($null -ne $effectiveAgentConfig) { $effectiveAgentConfig.access_path } else { $null }
        fallback_reason  = if ($fallbackReasons.Count -gt 0) { $fallbackReasons -join '; ' } else { $null }
    }
}

function Get-DelegatedRoutingPlan {
    param(
        [object[]]$RoleAssignments,
        [System.Collections.IDictionary]$AgentLookup
    )

    $roleLookup = @{}
    foreach ($roleAssignment in $RoleAssignments) {
        $roleLookup[$roleAssignment.name] = $roleAssignment
    }

    $enabledAgents = @(
        foreach ($agentName in @('copilot', 'claude', 'codex')) {
            if ($AgentLookup.Contains($agentName) -and $AgentLookup[$agentName].enabled -and $AgentLookup[$agentName].availability -eq 'available') {
                $agentName
            }
        }
    )
    if ($enabledAgents.Count -eq 0) {
        $enabledAgents = @('copilot')
    }

    $routingRoles = [ordered]@{}
    $implementedRoles = New-Object System.Collections.Generic.List[string]
    foreach ($roleName in @('Implementer', 'Spec Steward', 'Planner', 'Reviewer', 'Retro Facilitator')) {
        $implementedRoles.Add($roleName)
    }

    $implementerPreference = if ($roleLookup.ContainsKey('Implementer')) { $roleLookup['Implementer'].preferred_agent } else { 'copilot' }
    $implementerPlan = Resolve-RoleAgentPlan -RoleName 'Implementer' -PreferredAgent $implementerPreference -AgentLookup $AgentLookup -EnabledAgents $enabledAgents -ImplementerAgent $null
    $routingRoles['Implementer'] = $implementerPlan

    foreach ($roleName in @('Spec Steward', 'Planner', 'Reviewer', 'Retro Facilitator')) {
        $preferredAgent = if ($roleLookup.ContainsKey($roleName)) { $roleLookup[$roleName].preferred_agent } else { 'copilot' }
        $routingRoles[$roleName] = Resolve-RoleAgentPlan `
            -RoleName $roleName `
            -PreferredAgent $preferredAgent `
            -AgentLookup $AgentLookup `
            -EnabledAgents $enabledAgents `
            -ImplementerAgent $implementerPlan.effective_agent `
            -RequireIndependentOversight:($roleName -in @('Spec Steward', 'Reviewer'))
    }

    foreach ($roleAssignment in $RoleAssignments) {
        if ($routingRoles.Contains($roleAssignment.name)) {
            continue
        }

        $routingRoles[$roleAssignment.name] = Resolve-RoleAgentPlan `
            -RoleName $roleAssignment.name `
            -PreferredAgent $roleAssignment.preferred_agent `
            -AgentLookup $AgentLookup `
            -EnabledAgents $enabledAgents `
            -ImplementerAgent $implementerPlan.effective_agent
    }

    $fallbackEvents = @(
        foreach ($roleEntry in $routingRoles.GetEnumerator()) {
            if (-not [string]::IsNullOrWhiteSpace($roleEntry.Value.fallback_reason)) {
                [pscustomobject]@{
                    role            = $roleEntry.Value.role
                    requested_agent = $roleEntry.Value.requested_agent
                    actual_agent    = $roleEntry.Value.effective_agent
                    reason          = $roleEntry.Value.fallback_reason
                }
            }
        }
    )

    return [pscustomobject]@{
        enabled_agents              = @($enabledAgents)
        independent_oversight_active = ($enabledAgents.Count -gt 1)
        roles                       = $routingRoles
        fallback_events             = @($fallbackEvents)
    }
}

function Get-TeamRosterPromptBlock {
    param([pscustomobject]$TeamRoster)

    $lines = @(
        'Operational Specrew roster snapshot:'
        ('- Mode: {0}' -f $TeamRoster.mode)
    )

    if ($TeamRoster.mode -eq 'specrew-managed') {
        $lines += '- Treat this roster as operational state. Do NOT enter generic Squad team-setup mode or recast the roster.'
        $lines += ('- Baseline roles: {0}' -f (($TeamRoster.baseline_roles | ForEach-Object { $_.role }) -join ', '))
        $lines += ('- Supplemental members: {0}' -f $(if ($TeamRoster.supplemental_members.Count -gt 0) { ($TeamRoster.supplemental_members | ForEach-Object { $_.role }) -join ', ' } else { '(none)' }))
    }
    else {
        $lines += '- No Specrew-managed roster snapshot was detected.'
    }

    return $lines -join [Environment]::NewLine
}

function Get-ProjectStateSnapshot {
    param(
        [string]$Root,
        [string]$ResolvedFeaturePath
    )

    $bootstrapEntries = @(
        '.git',
        '.github',
        '.copilot',
        '.specify',
        '.specrew',
        '.squad',
        '.gitignore',
        '.gitattributes'
    )

    $topLevelEntries = @(
        Get-ChildItem -LiteralPath $Root -Force |
            Where-Object { $bootstrapEntries -notcontains $_.Name }
    )

    $brownfieldIndicators = @(
        'src',
        'app',
        'apps',
        'api',
        'client',
        'server',
        'lib',
        'cmd',
        'services',
        'web',
        'tests',
        'test',
        'package.json',
        'package-lock.json',
        'pnpm-lock.yaml',
        'yarn.lock',
        'pyproject.toml',
        'requirements.txt',
        'Pipfile',
        'go.mod',
        'Cargo.toml',
        'pom.xml',
        'build.gradle',
        'build.gradle.kts',
        'settings.gradle',
        'settings.gradle.kts',
        'composer.json',
        'Gemfile',
        'mix.exs',
        'Dockerfile',
        'docker-compose.yml',
        'docker-compose.yaml'
    )

    $hasBrownfieldIndicators = $false
    foreach ($entry in $topLevelEntries) {
        if ($brownfieldIndicators -contains $entry.Name) {
            $hasBrownfieldIndicators = $true
            break
        }

        if ($entry.PSIsContainer -and $entry.Name -match '^(frontend|backend|service|services|worker|workers)$') {
            $hasBrownfieldIndicators = $true
            break
        }

        if (-not $entry.PSIsContainer -and $entry.Name -match '\.(csproj|fsproj|vbproj|sln)$') {
            $hasBrownfieldIndicators = $true
            break
        }
    }

    $specDirectories = @()
    $specsRoot = Join-Path $Root 'specs'
    if (Test-Path -LiteralPath $specsRoot -PathType Container) {
        $specDirectories = @(
            Get-ChildItem -LiteralPath $specsRoot -Directory -ErrorAction SilentlyContinue |
                Select-Object -ExpandProperty FullName
        )
    }

    $state = if ($ResolvedFeaturePath) {
        'existing-continue'
    }
    elseif ($hasBrownfieldIndicators) {
        'brownfield-new'
    }
    else {
        'greenfield-new'
    }

    return [pscustomobject]@{
        state                = $state
        detected_entries     = @($topLevelEntries | ForEach-Object { $_.Name })
        has_brownfield_indicators = $hasBrownfieldIndicators
        has_specs_directory  = (Test-Path -LiteralPath $specsRoot -PathType Container)
        spec_directories     = @($specDirectories | ForEach-Object { Split-Path -Leaf $_ })
    }
}

function Get-ProjectStatePromptBlock {
    param([pscustomobject]$ProjectState)

    $lines = @(
        'Project state snapshot:'
        ('- State: {0}' -f $ProjectState.state)
        ('- Existing feature directories: {0}' -f $(if ($ProjectState.spec_directories.Count -gt 0) { $ProjectState.spec_directories -join ', ' } else { '(none)' }))
        ('- Non-bootstrap top-level entries: {0}' -f $(if ($ProjectState.detected_entries.Count -gt 0) { $ProjectState.detected_entries -join ', ' } else { '(none)' }))
    )

    return $lines -join [Environment]::NewLine
}

function Get-RelativeDisplayPath {
    param(
        [string]$Root,
        [string]$Path
    )

    $rootUri = [System.Uri](([System.IO.Path]::GetFullPath($Root).TrimEnd('\')) + '\')
    $targetUri = [System.Uri]([System.IO.Path]::GetFullPath($Path))
    return [System.Uri]::UnescapeDataString($rootUri.MakeRelativeUri($targetUri).ToString()).Replace('/', '\')
}

function Get-LanguageNameFromExtension {
    param([string]$Extension)

    switch ($Extension.ToLowerInvariant()) {
        '.ts' { return 'TypeScript' }
        '.tsx' { return 'TypeScript React' }
        '.js' { return 'JavaScript' }
        '.jsx' { return 'JavaScript React' }
        '.py' { return 'Python' }
        '.go' { return 'Go' }
        '.rs' { return 'Rust' }
        '.cs' { return 'C#' }
        '.java' { return 'Java' }
        '.kt' { return 'Kotlin' }
        '.swift' { return 'Swift' }
        '.php' { return 'PHP' }
        '.rb' { return 'Ruby' }
        '.md' { return 'Markdown' }
        '.yml' { return 'YAML' }
        '.yaml' { return 'YAML' }
        '.json' { return 'JSON' }
        '.sql' { return 'SQL' }
        default {
            if ([string]::IsNullOrWhiteSpace($Extension)) {
                return '(no extension)'
            }

            return $Extension.TrimStart('.').ToUpperInvariant()
        }
    }
}

function Get-BrownfieldLanguageSummary {
    param([string]$Root)

    $excludePatterns = @(
        '\.git\\',
        '\.specify\\',
        '\.specrew\\',
        '\.squad\\',
        '\.copilot\\',
        'node_modules\\',
        'dist\\',
        'build\\',
        'coverage\\',
        'vendor\\',
        'bin\\',
        'obj\\'
    )

    $extensionCounts = @{}
    $files = @(Get-ChildItem -LiteralPath $Root -Recurse -File -ErrorAction SilentlyContinue)
    foreach ($file in $files) {
        $relativePath = Get-RelativeDisplayPath -Root $Root -Path $file.FullName
        $skip = $false
        foreach ($pattern in $excludePatterns) {
            if ($relativePath -match $pattern) {
                $skip = $true
                break
            }
        }

        if ($skip) {
            continue
        }

        $extension = if ([string]::IsNullOrWhiteSpace($file.Extension)) { '(none)' } else { $file.Extension.ToLowerInvariant() }
        if (-not $extensionCounts.ContainsKey($extension)) {
            $extensionCounts[$extension] = 0
        }

        $extensionCounts[$extension]++
    }

    $topExtensions = @(
        $extensionCounts.GetEnumerator() |
            Sort-Object -Property Value -Descending |
            Select-Object -First 6 |
            ForEach-Object {
                [pscustomobject]@{
                    extension = $_.Key
                    language  = Get-LanguageNameFromExtension -Extension $_.Key
                    count     = [int]$_.Value
                }
            }
    )

    return [pscustomobject]@{
        total_files    = $files.Count
        top_extensions = $topExtensions
    }
}

function Add-TechnologyEvidence {
    param(
        [System.Collections.Generic.List[object]]$Bucket,
        [System.Collections.Generic.HashSet[string]]$Seen,
        [string]$Name,
        [string]$Reason
    )

    if ([string]::IsNullOrWhiteSpace($Name)) {
        return
    }

    if ($Seen.Add($Name)) {
        $Bucket.Add([pscustomobject]@{
            name   = $Name
            reason = $Reason
        }) | Out-Null
    }
}

function Get-BrownfieldTechnologySignals {
    param([string]$Root)

    $technologies = New-Object System.Collections.Generic.List[object]
    $seen = [System.Collections.Generic.HashSet[string]]::new([System.StringComparer]::OrdinalIgnoreCase)

    $packageJsonPath = Join-Path $Root 'package.json'
    if (Test-Path -LiteralPath $packageJsonPath -PathType Leaf) {
        Add-TechnologyEvidence -Bucket $technologies -Seen $seen -Name 'Node.js' -Reason 'package.json present'

        try {
            $packageJson = Get-Content -LiteralPath $packageJsonPath -Raw -Encoding UTF8 | ConvertFrom-Json
            $dependencyNames = New-Object System.Collections.Generic.List[string]
            foreach ($propertyName in @('dependencies', 'devDependencies', 'peerDependencies')) {
                $property = $null
                if ($packageJson -is [System.Collections.IDictionary]) {
                    if ($packageJson.Contains($propertyName)) {
                        $property = $packageJson[$propertyName]
                    }
                }
                else {
                    $propertyBag = @($packageJson.PSObject.Properties | Where-Object { $_.Name -eq $propertyName } | Select-Object -First 1)
                    if ($propertyBag.Count -gt 0) {
                        $property = $propertyBag[0].Value
                    }
                }

                if ($null -ne $property) {
                    if ($property -is [System.Collections.IDictionary]) {
                        foreach ($name in $property.Keys) {
                            $dependencyNames.Add([string]$name) | Out-Null
                        }
                    }
                    else {
                        foreach ($noteProperty in @($property.PSObject.Properties | Where-Object { $_.MemberType -eq 'NoteProperty' })) {
                            $dependencyNames.Add([string]$noteProperty.Name) | Out-Null
                        }
                    }
                }
            }

            $dependencySet = [System.Collections.Generic.HashSet[string]]::new([System.StringComparer]::OrdinalIgnoreCase)
            foreach ($name in $dependencyNames) {
                $dependencySet.Add($name) | Out-Null
            }

            if ($dependencySet.Contains('typescript')) { Add-TechnologyEvidence -Bucket $technologies -Seen $seen -Name 'TypeScript' -Reason 'package.json dependency' }
            if ($dependencySet.Contains('react')) { Add-TechnologyEvidence -Bucket $technologies -Seen $seen -Name 'React' -Reason 'package.json dependency' }
            if ($dependencySet.Contains('next')) { Add-TechnologyEvidence -Bucket $technologies -Seen $seen -Name 'Next.js' -Reason 'package.json dependency' }
            if ($dependencySet.Contains('vue')) { Add-TechnologyEvidence -Bucket $technologies -Seen $seen -Name 'Vue' -Reason 'package.json dependency' }
            if ($dependencySet.Contains('@angular/core')) { Add-TechnologyEvidence -Bucket $technologies -Seen $seen -Name 'Angular' -Reason 'package.json dependency' }
            if ($dependencySet.Contains('svelte')) { Add-TechnologyEvidence -Bucket $technologies -Seen $seen -Name 'Svelte' -Reason 'package.json dependency' }
            if ($dependencySet.Contains('express')) { Add-TechnologyEvidence -Bucket $technologies -Seen $seen -Name 'Express' -Reason 'package.json dependency' }
            if ($dependencySet.Contains('@nestjs/core')) { Add-TechnologyEvidence -Bucket $technologies -Seen $seen -Name 'NestJS' -Reason 'package.json dependency' }
            if ($dependencySet.Contains('fastify')) { Add-TechnologyEvidence -Bucket $technologies -Seen $seen -Name 'Fastify' -Reason 'package.json dependency' }
            if ($dependencySet.Contains('electron')) { Add-TechnologyEvidence -Bucket $technologies -Seen $seen -Name 'Electron' -Reason 'package.json dependency' }
            if ($dependencySet.Contains('vite')) { Add-TechnologyEvidence -Bucket $technologies -Seen $seen -Name 'Vite' -Reason 'package.json dependency' }
            if ($dependencySet.Contains('tailwindcss')) { Add-TechnologyEvidence -Bucket $technologies -Seen $seen -Name 'Tailwind CSS' -Reason 'package.json dependency' }
            if ($dependencySet.Contains('prisma')) { Add-TechnologyEvidence -Bucket $technologies -Seen $seen -Name 'Prisma' -Reason 'package.json dependency' }
            if ($dependencySet.Contains('pg')) { Add-TechnologyEvidence -Bucket $technologies -Seen $seen -Name 'PostgreSQL' -Reason 'package.json dependency' }
            if ($dependencySet.Contains('mongoose')) { Add-TechnologyEvidence -Bucket $technologies -Seen $seen -Name 'MongoDB' -Reason 'package.json dependency' }
            if ($dependencySet.Contains('redis')) { Add-TechnologyEvidence -Bucket $technologies -Seen $seen -Name 'Redis' -Reason 'package.json dependency' }
            if ($dependencySet.Contains('playwright')) { Add-TechnologyEvidence -Bucket $technologies -Seen $seen -Name 'Playwright' -Reason 'package.json dependency' }
            if ($dependencySet.Contains('cypress')) { Add-TechnologyEvidence -Bucket $technologies -Seen $seen -Name 'Cypress' -Reason 'package.json dependency' }
            if ($dependencySet.Contains('vitest')) { Add-TechnologyEvidence -Bucket $technologies -Seen $seen -Name 'Vitest' -Reason 'package.json dependency' }
            if ($dependencySet.Contains('jest')) { Add-TechnologyEvidence -Bucket $technologies -Seen $seen -Name 'Jest' -Reason 'package.json dependency' }
        }
        catch {
            Add-TechnologyEvidence -Bucket $technologies -Seen $seen -Name 'Node.js' -Reason 'package.json present but unreadable'
        }
    }

    foreach ($manifest in @(
        @{ Path = 'pyproject.toml'; Name = 'Python'; Reason = 'pyproject.toml present' },
        @{ Path = 'requirements.txt'; Name = 'Python'; Reason = 'requirements.txt present' },
        @{ Path = 'go.mod'; Name = 'Go'; Reason = 'go.mod present' },
        @{ Path = 'Cargo.toml'; Name = 'Rust'; Reason = 'Cargo.toml present' },
        @{ Path = 'pom.xml'; Name = 'Java'; Reason = 'pom.xml present' },
        @{ Path = 'build.gradle'; Name = 'Gradle'; Reason = 'build.gradle present' },
        @{ Path = 'build.gradle.kts'; Name = 'Gradle'; Reason = 'build.gradle.kts present' },
        @{ Path = 'Gemfile'; Name = 'Ruby'; Reason = 'Gemfile present' },
        @{ Path = 'composer.json'; Name = 'PHP'; Reason = 'composer.json present' },
        @{ Path = 'Dockerfile'; Name = 'Docker'; Reason = 'Dockerfile present' },
        @{ Path = 'docker-compose.yml'; Name = 'Docker Compose'; Reason = 'docker-compose.yml present' },
        @{ Path = 'docker-compose.yaml'; Name = 'Docker Compose'; Reason = 'docker-compose.yaml present' }
    )) {
        if (Test-Path -LiteralPath (Join-Path $Root $manifest.Path) -PathType Leaf) {
            Add-TechnologyEvidence -Bucket $technologies -Seen $seen -Name $manifest.Name -Reason $manifest.Reason
        }
    }

    $csprojFiles = @(Get-ChildItem -LiteralPath $Root -Recurse -Filter *.csproj -File -ErrorAction SilentlyContinue | Select-Object -First 1)
    if ($csprojFiles.Count -gt 0) {
        Add-TechnologyEvidence -Bucket $technologies -Seen $seen -Name '.NET' -Reason (($csprojFiles[0].Name) + ' present')
    }

    return $technologies.ToArray()
}

function Get-BrownfieldDocsSnapshot {
    param([string]$Root)

    $docFiles = New-Object System.Collections.Generic.List[object]
    $candidates = New-Object System.Collections.Generic.List[System.IO.FileInfo]

    foreach ($pattern in @('README*.md', '*.md')) {
        foreach ($file in @(Get-ChildItem -LiteralPath $Root -Filter $pattern -File -ErrorAction SilentlyContinue)) {
            if ($file.Name -like 'README*' -or $file.Name -in @('README.md', 'readme.md', 'docs.md', 'architecture.md')) {
                $candidates.Add($file) | Out-Null
            }
        }
    }

    $docsRoot = Join-Path $Root 'docs'
    if (Test-Path -LiteralPath $docsRoot -PathType Container) {
        foreach ($file in @(Get-ChildItem -LiteralPath $docsRoot -Recurse -Filter *.md -File -ErrorAction SilentlyContinue | Select-Object -First 6)) {
            $candidates.Add($file) | Out-Null
        }
    }

    $seenPaths = [System.Collections.Generic.HashSet[string]]::new([System.StringComparer]::OrdinalIgnoreCase)
    foreach ($file in $candidates) {
        if (-not $seenPaths.Add($file.FullName)) {
            continue
        }

        $lines = @(Get-Content -LiteralPath $file.FullName -Encoding UTF8 -ErrorAction SilentlyContinue | Select-Object -First 40)
        $summary = $null
        foreach ($line in $lines) {
            $trimmed = $line.Trim()
            if ($trimmed -match '^#\s+') {
                $summary = $trimmed.TrimStart('#').Trim()
                break
            }

            if (-not [string]::IsNullOrWhiteSpace($trimmed)) {
                $summary = $trimmed
                break
            }
        }

        $docFiles.Add([pscustomobject]@{
            path    = Get-RelativeDisplayPath -Root $Root -Path $file.FullName
            summary = if ($summary) { $summary } else { '(no summary found)' }
        }) | Out-Null
    }

    return @($docFiles | Select-Object -First 6)
}

function Get-BrownfieldRecentCommits {
    param([string]$Root)

    if (-not (Test-Path -LiteralPath (Join-Path $Root '.git'))) {
        return @()
    }

    $gitCommand = Get-Command git -ErrorAction SilentlyContinue
    if (-not $gitCommand) {
        return @()
    }

    $commitLines = @(& $gitCommand.Source -C $Root log --max-count=6 --pretty=format:%s 2>$null)
    if ($LASTEXITCODE -ne 0) {
        return @()
    }

    return @($commitLines | ForEach-Object { ([string]$_).Trim() } | Where-Object { -not [string]::IsNullOrWhiteSpace($_) })
}

function Get-BrownfieldDomainSignals {
    param(
        [object[]]$DocsSnapshot,
        [string[]]$RecentCommits,
        [pscustomobject]$ProjectState
    )

    $textFragments = New-Object System.Collections.Generic.List[string]
    foreach ($doc in $DocsSnapshot) {
        $textFragments.Add([string]$doc.summary) | Out-Null
        $textFragments.Add([string]$doc.path) | Out-Null
    }
    foreach ($commit in $RecentCommits) {
        $textFragments.Add([string]$commit) | Out-Null
    }
    foreach ($entry in $ProjectState.detected_entries) {
        $textFragments.Add([string]$entry) | Out-Null
    }

    $combined = ($textFragments -join ' ').ToLowerInvariant()
    $signals = New-Object System.Collections.Generic.List[string]

    foreach ($signal in @(
        @{ Name = 'Authentication & Security'; Pattern = '\b(auth|oauth|oidc|jwt|login|identity|permission|rbac|security)\b' },
        @{ Name = 'Analytics & Reporting'; Pattern = '\b(report|reporting|analytics|dashboard|metric|kpi)\b' },
        @{ Name = 'Messaging & Notifications'; Pattern = '\b(message|messaging|chat|email|notification|queue|webhook)\b' },
        @{ Name = 'Sync & Data Transfer'; Pattern = '\b(sync|synchroni[sz]e|clipboard|import|export|replication|offline)\b' },
        @{ Name = 'AI & Knowledge Workflows'; Pattern = '\b(ai|llm|copilot|agent|prompt|rag|embedding|search)\b' },
        @{ Name = 'Commerce & Billing'; Pattern = '\b(cart|checkout|billing|invoice|payment|order|subscription)\b' },
        @{ Name = 'Media & Content'; Pattern = '\b(image|video|audio|media|content|asset)\b' }
    )) {
        if ($combined -match $signal.Pattern) {
            $signals.Add($signal.Name) | Out-Null
        }
    }

    return $signals.ToArray()
}

function Get-BrownfieldSpecialistRecommendations {
    param(
        [object[]]$TechnologySignals,
        [string[]]$DomainSignals,
        [pscustomobject]$TeamRoster
    )

    $recommendations = New-Object System.Collections.Generic.List[object]
    $seenRoles = [System.Collections.Generic.HashSet[string]]::new([System.StringComparer]::OrdinalIgnoreCase)
    $existingRoles = [System.Collections.Generic.HashSet[string]]::new([System.StringComparer]::OrdinalIgnoreCase)

    foreach ($member in @($TeamRoster.baseline_roles) + @($TeamRoster.supplemental_members)) {
        $existingRoles.Add([string]$member.role) | Out-Null
    }

    function Add-Recommendation {
        param(
            [string]$Role,
            [string]$MemberName,
            [string]$Charter,
            [string]$Reason
        )

        if ($existingRoles.Contains($Role)) {
            return
        }

        if ($seenRoles.Add($Role)) {
            $recommendations.Add([pscustomobject]@{
                role        = $Role
                member_name = $MemberName
                charter     = $Charter
                reason      = $Reason
            }) | Out-Null
        }
    }

    $technologyNames = @($TechnologySignals | ForEach-Object { $_.name })
    if ($technologyNames -contains 'React' -or $technologyNames -contains 'Next.js' -or $technologyNames -contains 'Vue' -or $technologyNames -contains 'Angular' -or $technologyNames -contains 'Svelte') {
        $frontendTech = @($technologyNames | Where-Object { $_ -in @('React', 'Next.js', 'Vue', 'Angular', 'Svelte') } | Select-Object -First 1)[0]
        Add-Recommendation -Role ("{0} Frontend Specialist" -f $frontendTech) -MemberName (($frontendTech.ToLowerInvariant() -replace '[^a-z0-9]+', '-') + '-frontend-specialist') -Charter ("Own architecture and implementation guidance for the existing {0} frontend surface, component patterns, and UI integration constraints." -f $frontendTech) -Reason ("Detected {0} in repo dependencies." -f $frontendTech)
    }

    if ($technologyNames -contains 'Express' -or $technologyNames -contains 'NestJS' -or $technologyNames -contains 'Fastify') {
        $backendTech = @($technologyNames | Where-Object { $_ -in @('NestJS', 'Express', 'Fastify', 'Node.js') } | Select-Object -First 1)[0]
        Add-Recommendation -Role 'Backend API Specialist' -MemberName 'backend-api-specialist' -Charter ("Own the existing {0} service boundaries, API contracts, and backend implementation constraints." -f $backendTech) -Reason ("Detected {0}-based backend signals." -f $backendTech)
    }

    if ($technologyNames -contains 'Python' -or $technologyNames -contains 'Go' -or $technologyNames -contains '.NET' -or $technologyNames -contains 'Rust') {
        $platformTech = @($technologyNames | Where-Object { $_ -in @('Python', 'Go', '.NET', 'Rust', 'Java') } | Select-Object -First 1)[0]
        Add-Recommendation -Role ("{0} Platform Specialist" -f $platformTech) -MemberName (($platformTech.ToLowerInvariant() -replace '[^a-z0-9]+', '-') + '-platform-specialist') -Charter ("Own architecture, implementation constraints, and maintenance patterns for the existing {0} codebase." -f $platformTech) -Reason ("Detected {0} project manifests or source files." -f $platformTech)
    }

    if ($technologyNames -contains 'PostgreSQL' -or $technologyNames -contains 'MongoDB' -or $technologyNames -contains 'Prisma' -or $technologyNames -contains 'Redis') {
        Add-Recommendation -Role 'Data Persistence Specialist' -MemberName 'data-persistence-specialist' -Charter 'Own schema, query, migration, and data-integrity decisions across the existing persistence layer.' -Reason 'Detected persistence technology signals in the existing repo.'
    }

    if ($technologyNames -contains 'Docker' -or $technologyNames -contains 'Docker Compose') {
        Add-Recommendation -Role 'Platform DevOps Specialist' -MemberName 'platform-devops-specialist' -Charter 'Own container, deployment, and runtime-environment concerns for the existing system.' -Reason 'Detected deployment/runtime manifests in the existing repo.'
    }

    foreach ($domain in $DomainSignals) {
        switch ($domain) {
            'Authentication & Security' {
                Add-Recommendation -Role 'Security Specialist' -MemberName 'security-specialist' -Charter 'Own authentication, authorization, identity, and security hardening decisions for the existing product.' -Reason 'Repo docs or git history mention auth/security concerns.'
            }
            'Analytics & Reporting' {
                Add-Recommendation -Role 'Analytics Domain Specialist' -MemberName 'analytics-domain-specialist' -Charter 'Own reporting, metrics, and dashboard domain constraints while clarifying brownfield requirements.' -Reason 'Repo docs or git history mention reporting/analytics concepts.'
            }
            'Sync & Data Transfer' {
                Add-Recommendation -Role 'Synchronization Specialist' -MemberName 'synchronization-specialist' -Charter 'Own sync flows, import/export boundaries, and state-consistency concerns in the existing product.' -Reason 'Repo docs or git history mention sync/data-transfer concepts.'
            }
            'AI & Knowledge Workflows' {
                Add-Recommendation -Role 'AI Integration Specialist' -MemberName 'ai-integration-specialist' -Charter 'Own agent, LLM, prompt, or retrieval workflow concerns present in the existing product.' -Reason 'Repo docs or git history mention AI/agent workflows.'
            }
        }
    }

    return @($recommendations | Select-Object -First 4)
}

function Get-BrownfieldDiscoverySnapshot {
    param(
        [string]$Root,
        [pscustomobject]$ProjectState,
        [pscustomobject]$TeamRoster
    )

    if ($ProjectState.state -ne 'brownfield-new') {
        return $null
    }

    $languageSummary = Get-BrownfieldLanguageSummary -Root $Root
    $technologySignals = @(Get-BrownfieldTechnologySignals -Root $Root)
    $docsSnapshot = @(Get-BrownfieldDocsSnapshot -Root $Root)
    $recentCommits = @(Get-BrownfieldRecentCommits -Root $Root)
    $domainSignals = @(Get-BrownfieldDomainSignals -DocsSnapshot $docsSnapshot -RecentCommits $recentCommits -ProjectState $ProjectState)
    $specialistRecommendations = @(Get-BrownfieldSpecialistRecommendations -TechnologySignals $technologySignals -DomainSignals $domainSignals -TeamRoster $TeamRoster)

    return [pscustomobject]@{
        technologies             = $technologySignals
        dominant_languages       = @($languageSummary.top_extensions | ForEach-Object { $_.language })
        docs_snapshot            = $docsSnapshot
        recent_commits           = $recentCommits
        domain_signals           = $domainSignals
        suggested_specialists    = $specialistRecommendations
    }
}

function Get-BrownfieldDiscoveryPromptBlock {
    param([AllowNull()][pscustomobject]$BrownfieldDiscovery)

    if ($null -eq $BrownfieldDiscovery) {
        return ''
    }

    $technologySummary = if ($BrownfieldDiscovery.technologies.Count -gt 0) {
        ($BrownfieldDiscovery.technologies | ForEach-Object { '{0} ({1})' -f $_.name, $_.reason }) -join '; '
    }
    else {
        '(none detected)'
    }

    $docsSummary = if ($BrownfieldDiscovery.docs_snapshot.Count -gt 0) {
        ($BrownfieldDiscovery.docs_snapshot | ForEach-Object { '{0}: {1}' -f $_.path, $_.summary }) -join '; '
    }
    else {
        '(none found)'
    }

    $commitSummary = if ($BrownfieldDiscovery.recent_commits.Count -gt 0) {
        $BrownfieldDiscovery.recent_commits -join '; '
    }
    else {
        '(no recent git history found)'
    }

    $specialistSummary = if ($BrownfieldDiscovery.suggested_specialists.Count -gt 0) {
        ($BrownfieldDiscovery.suggested_specialists | ForEach-Object { '{0} [{1}] - {2}' -f $_.role, $_.member_name, $_.reason }) -join '; '
    }
    else {
        '(no additional specialists inferred from current evidence)'
    }

    $domainSummary = if ($BrownfieldDiscovery.domain_signals.Count -gt 0) {
        $BrownfieldDiscovery.domain_signals -join ', '
    }
    else {
        '(none inferred yet)'
    }

    return @(
        'Brownfield discovery snapshot:'
        ('- Technologies: {0}' -f $technologySummary)
        ('- Domain signals: {0}' -f $domainSummary)
        ('- Existing docs: {0}' -f $docsSummary)
        ('- Recent git intent: {0}' -f $commitSummary)
        ('- Suggested specialists: {0}' -f $specialistSummary)
    ) -join [Environment]::NewLine
}

function Get-DeliveryGuidanceTextProfile {
    param(
        [string]$FeatureRequest,
        [pscustomobject]$ProjectState,
        [AllowNull()][pscustomobject]$BrownfieldDiscovery
    )

    $textFragments = New-Object System.Collections.Generic.List[string]
    if (-not [string]::IsNullOrWhiteSpace($FeatureRequest)) {
        $textFragments.Add($FeatureRequest) | Out-Null
    }

    if ($null -ne $BrownfieldDiscovery) {
        foreach ($technology in @($BrownfieldDiscovery.technologies)) {
            if ($null -eq $technology) {
                continue
            }

            $textFragments.Add([string]$technology.name) | Out-Null
            $textFragments.Add([string]$technology.reason) | Out-Null
        }

        foreach ($domain in @($BrownfieldDiscovery.domain_signals)) {
            $textFragments.Add([string]$domain) | Out-Null
        }

        foreach ($doc in @($BrownfieldDiscovery.docs_snapshot)) {
            if ($null -eq $doc) {
                continue
            }

            $textFragments.Add([string]$doc.summary) | Out-Null
        }

        foreach ($commit in @($BrownfieldDiscovery.recent_commits)) {
            $textFragments.Add([string]$commit) | Out-Null
        }
    }

    foreach ($entry in @($ProjectState.detected_entries)) {
        $textFragments.Add([string]$entry) | Out-Null
    }

    $technologyNames = if ($null -ne $BrownfieldDiscovery) {
        @($BrownfieldDiscovery.technologies | ForEach-Object { $_.name })
    }
    else {
        @()
    }

    return [pscustomobject]@{
        combined_text        = ($textFragments -join ' ').ToLowerInvariant()
        technology_names     = $technologyNames
        feature_request_text = if ([string]::IsNullOrWhiteSpace($FeatureRequest)) { '' } else { $FeatureRequest.ToLowerInvariant() }
    }
}

function Get-FeatureWorkstreamMatchProfile {
    param([string]$FeatureRequestText)

    if ([string]::IsNullOrWhiteSpace($FeatureRequestText)) {
        return [pscustomobject]@{
            frontend_workstream_count = 0
            backend_workstream_count  = 0
            frontend_conflict_count   = 0
            backend_conflict_count    = 0
        }
    }

    return [pscustomobject]@{
        frontend_workstream_count = @([regex]::Matches($FeatureRequestText, '\b(dashboard|report|reporting|export|form|admin|page|component|ui|workflow)\b')).Count
        backend_workstream_count  = @([regex]::Matches($FeatureRequestText, '\b(api|service|endpoint|worker|queue|sync|realtime|webhook|import|export|integration)\b')).Count
        frontend_conflict_count   = @([regex]::Matches($FeatureRequestText, '\b(shared state|global state|migration|monolith|rewrite)\b')).Count
        backend_conflict_count    = @([regex]::Matches($FeatureRequestText, '\b(schema|migration|lock|transaction|global refactor)\b')).Count
    }
}

# Builds intake/planning guidance from repo signals, brownfield discovery, and feature-request cues.
function Get-DeliveryGuidanceSnapshot {
    param(
        [string]$FeatureRequest,
        [pscustomobject]$ProjectState,
        [AllowNull()][pscustomobject]$BrownfieldDiscovery,
        [pscustomobject]$TeamRoster
    )

    $existingRoles = [System.Collections.Generic.HashSet[string]]::new([System.StringComparer]::OrdinalIgnoreCase)
    foreach ($member in @($TeamRoster.baseline_roles) + @($TeamRoster.supplemental_members)) {
        if (-not [string]::IsNullOrWhiteSpace([string]$member.role)) {
            $existingRoles.Add([string]$member.role) | Out-Null
        }
    }

    $specialistHints = New-Object System.Collections.Generic.List[object]
    $sameSpecialtyPairHints = New-Object System.Collections.Generic.List[object]
    $qualityAttributes = New-Object System.Collections.Generic.List[object]
    $semanticsWatchouts = New-Object System.Collections.Generic.List[string]
    $parallelismSignals = New-Object System.Collections.Generic.List[string]
    $routingGuardrails = New-Object System.Collections.Generic.List[string]
    $seenSpecialists = [System.Collections.Generic.HashSet[string]]::new([System.StringComparer]::OrdinalIgnoreCase)
    $seenPairs = [System.Collections.Generic.HashSet[string]]::new([System.StringComparer]::OrdinalIgnoreCase)
    $seenQualities = [System.Collections.Generic.HashSet[string]]::new([System.StringComparer]::OrdinalIgnoreCase)
    $seenWatchouts = [System.Collections.Generic.HashSet[string]]::new([System.StringComparer]::OrdinalIgnoreCase)
    $seenParallelSignals = [System.Collections.Generic.HashSet[string]]::new([System.StringComparer]::OrdinalIgnoreCase)
    $seenRoutingGuardrails = [System.Collections.Generic.HashSet[string]]::new([System.StringComparer]::OrdinalIgnoreCase)

    function Add-SpecialistHint {
        param(
            [string]$Role,
            [string]$MemberName,
            [string]$Charter,
            [string]$Reason
        )

        if ([string]::IsNullOrWhiteSpace($Role) -or $existingRoles.Contains($Role)) {
            return
        }

        if ($seenSpecialists.Add($Role)) {
            $specialistHints.Add([pscustomobject]@{
                role        = $Role
                member_name = $MemberName
                charter     = $Charter
                reason      = $Reason
            }) | Out-Null
        }
    }

    function Add-QualityAttribute {
        param(
            [string]$Name,
            [string]$Reason,
            [string]$ValidationFocus
        )

        if ([string]::IsNullOrWhiteSpace($Name)) {
            return
        }

        if ($seenQualities.Add($Name)) {
            $qualityAttributes.Add([pscustomobject]@{
                name             = $Name
                reason           = $Reason
                validation_focus = $ValidationFocus
            }) | Out-Null
        }
    }

    function Add-ParallelismSignal {
        param([string]$Message)

        if ([string]::IsNullOrWhiteSpace($Message)) {
            return
        }

        if ($seenParallelSignals.Add($Message)) {
            $parallelismSignals.Add($Message) | Out-Null
        }
    }

    function Add-RoutingGuardrail {
        param([string]$Message)

        if ([string]::IsNullOrWhiteSpace($Message)) {
            return
        }

        if ($seenRoutingGuardrails.Add($Message)) {
            $routingGuardrails.Add($Message) | Out-Null
        }
    }

    function Add-SemanticsWatchout {
        param([string]$Message)

        if ([string]::IsNullOrWhiteSpace($Message)) {
            return
        }

        if ($seenWatchouts.Add($Message)) {
            $semanticsWatchouts.Add($Message) | Out-Null
        }
    }

    function Add-SameSpecialtyPairHint {
        param(
            [string]$Specialty,
            [string]$Reason,
            [string]$JuniorTaskProfile,
            [string]$SeniorTaskProfile,
            [string]$ParallelismGuard
        )

        if ([string]::IsNullOrWhiteSpace($Specialty)) {
            return
        }

        $pairKey = $Specialty.Trim()
        if (-not $seenPairs.Add($pairKey)) {
            return
        }

        $specialtySlug = ($Specialty.ToLowerInvariant() -replace '[^a-z0-9]+', '-').Trim('-')
        $juniorRole = "Junior $Specialty Developer"
        $seniorRole = "Senior $Specialty Developer"

        if ($existingRoles.Contains($juniorRole) -and $existingRoles.Contains($seniorRole)) {
            return
        }

        $sameSpecialtyPairHints.Add([pscustomobject]@{
                specialty             = $Specialty
                junior_role           = $juniorRole
                junior_member_name    = "junior-$specialtySlug-developer"
                junior_charter        = "Implement bounded, lower-risk $($Specialty.ToLowerInvariant()) slices with a high professional bar once ownership boundaries and acceptance criteria are clear. Be careful, responsible, knowledgeable, and review-ready: check correctness, edge cases, tests, and maintainability before handoff."
                senior_role           = $seniorRole
                senior_member_name    = "senior-$specialtySlug-developer"
                senior_charter        = "Own ambiguous, cross-cutting, integration-heavy, or higher-risk $($Specialty.ToLowerInvariant()) work and provide escalation support for Junior-owned slices when needed. Bring deep technical judgment across architecture, systems thinking, computer science fundamentals, tradeoff analysis, forecasting, and long-range software engineering consequences."
                reason                = $Reason
                junior_task_profile   = $JuniorTaskProfile
                senior_task_profile   = $SeniorTaskProfile
                parallelism_guard     = $ParallelismGuard
            }) | Out-Null
    }

    if ($null -ne $BrownfieldDiscovery) {
        foreach ($specialist in @($BrownfieldDiscovery.suggested_specialists)) {
            if ($null -eq $specialist) {
                continue
            }

            Add-SpecialistHint -Role $specialist.role -MemberName $specialist.member_name -Charter $specialist.charter -Reason $specialist.reason
        }
    }

    $guidanceTextProfile = Get-DeliveryGuidanceTextProfile -FeatureRequest $FeatureRequest -ProjectState $ProjectState -BrownfieldDiscovery $BrownfieldDiscovery
    $combinedText = [string]$guidanceTextProfile.combined_text
    $technologyNames = @($guidanceTextProfile.technology_names)

    Add-QualityAttribute `
        -Name 'Maintainability & Testability' `
        -Reason 'Every feature should stay reviewable, modular, and covered by meaningful verification rather than only compiling or passing a happy-path test.' `
        -ValidationFocus 'Keep responsibilities clear, avoid speculative complexity, and explain how tests exercise the requirement-critical paths.'

    if ($combinedText -match '\b(auth|oauth|oidc|jwt|login|identity|permission|rbac|security|secret|token|privacy)\b') {
        Add-SpecialistHint -Role 'Security Specialist' -MemberName 'security-specialist' -Charter 'Own authentication, authorization, secrets handling, and security hardening decisions for this feature.' -Reason 'The request or repo context indicates auth, security, or privacy-sensitive behavior.'
        Add-QualityAttribute -Name 'Security & Privacy' -Reason 'The requested behavior touches auth, secrets, permissions, or privacy-sensitive data.' -ValidationFocus 'Validate authentication and authorization flows, secret handling, and abuse-resistant failure behavior.'
        Add-SemanticsWatchout 'Validate authn/authz and secret handling end to end rather than treating schemas, guards, or token fields as sufficient proof of security.'
    }

    if (($technologyNames -contains 'Express') -or
        ($technologyNames -contains 'Fastify') -or
        ($technologyNames -contains 'NestJS') -or
        ($technologyNames -contains '.NET') -or
        ($technologyNames -contains 'Go') -or
        ($technologyNames -contains 'Python') -or
        ($technologyNames -contains 'Java') -or
        ($technologyNames -contains 'Rust') -or
        ($combinedText -match '\b(api|backend|service|endpoint|webhook|worker)\b')) {
        Add-SpecialistHint -Role 'Backend API Specialist' -MemberName 'backend-api-specialist' -Charter 'Own service boundaries, integration contracts, and backend runtime behavior for this feature.' -Reason 'The request or repo context indicates service, API, or backend work.'
    }

    if ($combinedText -match '\b(api|backend|service|endpoint|webhook|integration|sync|realtime|queue|worker|websocket|retry|error|telemetry|logging|observability)\b' -or $ProjectState.state -eq 'brownfield-new') {
        Add-QualityAttribute -Name 'Error Handling & Observability' -Reason 'Service, brownfield, or integration work needs actionable failure behavior and diagnostics to be production-usable.' -ValidationFocus 'Make retry/error paths explicit, ensure logs and telemetry are actionable, and avoid silent failures or success-shaped fallbacks.'
    }

    if ($combinedText -match '\b(sync|realtime|websocket|retry|idempot|dedupe|conflict|concurr|lock|revision|event|queue|clipboard|import|export|offline)\b') {
        Add-SpecialistHint -Role 'Synchronization Specialist' -MemberName 'synchronization-specialist' -Charter 'Own sync, retry, concurrency, and state-consistency behavior for collaborative or cross-system flows.' -Reason 'The request or repo context indicates synchronization, retry, or conflict-prone behavior.'
        Add-QualityAttribute -Name 'Reliability & Idempotency' -Reason 'The feature appears to rely on retries, synchronization, or repeated delivery where duplicate or stale operations can corrupt behavior.' -ValidationFocus 'Verify retry, dedupe, conflict handling, reconnect, and ordering behavior under unhappy paths rather than only on the happy path.'
        Add-SemanticsWatchout 'Do not add revision, idempotency, retry, conflict, or lock fields unless the runtime actually enforces those semantics.'
    }

    if ($combinedText -match '\b(data|database|postgres|redis|cache|schema|migration|store|persist|import|export|analytics|reporting)\b') {
        Add-SpecialistHint -Role 'Data Persistence Specialist' -MemberName 'data-persistence-specialist' -Charter 'Own schema, migration, persistence, and data-integrity decisions for this feature.' -Reason 'The request or repo context indicates persistence, data movement, or reporting behavior.'
        Add-QualityAttribute -Name 'Data Integrity & Safe Change' -Reason 'The feature reads, writes, or transports state that must remain internally consistent as the system evolves.' -ValidationFocus 'Check migration safety, stale-write protection, compatibility of stored data, and whether protocol/state fields have real semantics.'
    }

    if ($combinedText -match '\b(ui|ux|frontend|dashboard|page|form|react|next|vue|angular|svelte)\b') {
        Add-SpecialistHint -Role 'Frontend Experience Specialist' -MemberName 'frontend-experience-specialist' -Charter 'Own user-facing flows, UI consistency, and frontend integration quality for this feature.' -Reason 'The request or repo context indicates a significant UI or frontend surface.'
    }

    if ($combinedText -match '\b(metric|metrics|telemetry|logging|monitor|observability|trace|tracing|alert)\b') {
        Add-SpecialistHint -Role 'Observability Specialist' -MemberName 'observability-specialist' -Charter 'Own telemetry, operational visibility, and production diagnostics for this feature.' -Reason 'The request or repo context explicitly mentions telemetry or operational observability.'
        Add-SemanticsWatchout 'Ensure logging and telemetry produce actionable runtime signals instead of decorative wrappers or permanently disabled sinks.'
    }

    if ($combinedText -match '\b(report|reporting|dashboard|search|stream|realtime|performance|latency|throughput|scale)\b') {
        Add-QualityAttribute -Name 'Performance & Capacity' -Reason 'The feature includes dashboarding, reporting, or other flows where latency or throughput can materially affect usability.' -ValidationFocus 'Check the slow path, not just the happy path, and justify any caching, batching, or pagination behavior.'
    }

    if ($ProjectState.state -eq 'brownfield-new') {
        Add-QualityAttribute -Name 'Brownfield Compatibility' -Reason 'Changes landing in an existing codebase must respect current contracts, extension points, and operational behavior.' -ValidationFocus 'Validate that the feature integrates with existing structure, keeps compatibility where required, and documents any intentional contract changes.'
    }

    if ($combinedText -match '\b(sync|realtime|websocket|queue|event|cache)\b') {
        Add-SemanticsWatchout 'Validate reconnect, retry, dedupe, and ordering behavior under failure paths instead of assuming eventual consistency from protocol shape alone.'
    }

    $featureRequestText = [string]$guidanceTextProfile.feature_request_text
    if (-not [string]::IsNullOrWhiteSpace($featureRequestText)) {
        $workstreamMatchProfile = Get-FeatureWorkstreamMatchProfile -FeatureRequestText $featureRequestText

        if ($workstreamMatchProfile.frontend_workstream_count -ge 3 -and $workstreamMatchProfile.frontend_conflict_count -eq 0) {
            Add-ParallelismSignal 'The requested feature hints at multiple frontend-facing workstreams that can likely be partitioned after clarify.'
            Add-RoutingGuardrail 'Only run Junior/Senior frontend work in parallel when screens, components, or acceptance slices are explicitly partitioned.'
            Add-SameSpecialtyPairHint `
                -Specialty 'Frontend' `
                -Reason 'The feature request implies multiple frontend-facing slices (for example dashboard/reporting, export flows, forms, or UI workflows) that could be executed in parallel after clarify.' `
                -JuniorTaskProfile 'Bounded component work, view wiring, small UI states, and well-scoped test additions once the interface contract is clear. Junior execution must still be careful, knowledgeable, and review-ready, with explicit checks for correctness, edge cases, and maintainability.' `
                -SeniorTaskProfile 'Ambiguous UX decisions, shared-state boundaries, complex integration paths, and risky frontend slices that need deeper reasoning or final integration ownership. Senior ownership should reflect deep technical understanding, architectural judgment, systems thinking, and strong forecasting of long-term frontend consequences.' `
                -ParallelismGuard 'Partition ownership by screen, component tree, or acceptance slice before launching parallel frontend work. Escalate shared-surface or repeated gate failures to the Senior frontend role.'
        }

        if ($workstreamMatchProfile.backend_workstream_count -ge 3 -and $workstreamMatchProfile.backend_conflict_count -eq 0) {
            Add-ParallelismSignal 'The requested feature hints at multiple backend/service workstreams that may justify same-specialty parallel execution after planning.'
            Add-RoutingGuardrail 'Only run Junior/Senior backend work in parallel when APIs, workers, or data-flow slices have explicit ownership boundaries.'
            Add-SameSpecialtyPairHint `
                -Specialty 'Backend' `
                -Reason 'The feature request implies multiple backend slices (for example APIs, workers, sync paths, webhooks, or service integrations) that could be partitioned safely after clarify and planning.' `
                -JuniorTaskProfile 'Bounded endpoint handlers, isolated service methods, adapter wiring, and well-scoped tests once the contract is stable. Junior execution must still be careful, knowledgeable, and review-ready, with explicit checks for correctness, edge cases, and maintainability.' `
                -SeniorTaskProfile 'Shared contracts, concurrency-sensitive behavior, cross-service integration, data consistency concerns, and escalation ownership for repeated failures. Senior ownership should reflect deep technical understanding, architectural judgment, systems thinking, computer science depth, and strong forecasting of long-term backend consequences.' `
                -ParallelismGuard 'Partition ownership by API surface, worker boundary, or integration slice before parallel backend execution. Escalate shared-contract or repeated gate failures to the Senior backend role.'
        }
    }

    if ($sameSpecialtyPairHints.Count -gt 0) {
        Add-RoutingGuardrail 'Do not treat Junior/Senior pairs as cloned identities. They are distinct named members with different task profiles and escalation responsibilities.'
    }

    return [pscustomobject]@{
        specialist_hints          = @($specialistHints | Select-Object -First 5)
        same_specialty_pair_hints = @($sameSpecialtyPairHints | Select-Object -First 3)
        parallelism_signals       = $parallelismSignals.ToArray()
        routing_guardrails        = $routingGuardrails.ToArray()
        quality_attributes        = $qualityAttributes.ToArray()
        semantics_watchouts       = $semanticsWatchouts.ToArray()
    }
}

function Get-DeliveryGuidancePromptBlock {
    param([AllowNull()][pscustomobject]$DeliveryGuidance)

    if ($null -eq $DeliveryGuidance) {
        return ''
    }

    $specialistSummary = if (@($DeliveryGuidance.specialist_hints).Count -gt 0) {
        ($DeliveryGuidance.specialist_hints | ForEach-Object { '{0} [{1}] - {2}' -f $_.role, $_.member_name, $_.reason }) -join '; '
    }
    else {
        '(none inferred yet)'
    }

    $qualitySummary = if (@($DeliveryGuidance.quality_attributes).Count -gt 0) {
        ($DeliveryGuidance.quality_attributes | ForEach-Object { '{0} ({1})' -f $_.name, $_.reason }) -join '; '
    }
    else {
        '(derive from the grounded spec before planning)'
    }

    $watchoutSummary = if (@($DeliveryGuidance.semantics_watchouts).Count -gt 0) {
        $DeliveryGuidance.semantics_watchouts -join '; '
    }
    else {
        '(none inferred yet)'
    }

    $pairSummary = if (@($DeliveryGuidance.same_specialty_pair_hints).Count -gt 0) {
        ($DeliveryGuidance.same_specialty_pair_hints | ForEach-Object { '{0} + {1} ({2})' -f $_.junior_role, $_.senior_role, $_.reason }) -join '; '
    }
    else {
        '(none inferred yet)'
    }

    $parallelismSummary = if (@($DeliveryGuidance.parallelism_signals).Count -gt 0) {
        $DeliveryGuidance.parallelism_signals -join '; '
    }
    else {
        '(no safe same-specialty parallelism inferred yet)'
    }

    $guardrailSummary = if (@($DeliveryGuidance.routing_guardrails).Count -gt 0) {
        $DeliveryGuidance.routing_guardrails -join '; '
    }
    else {
        '(derive from the grounded plan before parallel execution)'
    }

    return @(
        'Implementation readiness hints:'
        ('- Candidate specialists after spec/clarify: {0}' -f $specialistSummary)
        ('- Candidate Junior/Senior same-specialty pairs after spec/clarify: {0}' -f $pairSummary)
        ('- Safe-parallelism signals: {0}' -f $parallelismSummary)
        ('- Junior/Senior routing guardrails: {0}' -f $guardrailSummary)
        ('- Quality focus to carry into planning/review: {0}' -f $qualitySummary)
        ('- Semantic watchouts: {0}' -f $watchoutSummary)
    ) -join [Environment]::NewLine
}

function Get-ModelForRoleRouting {
    param(
        [string]$RoleName,
        [pscustomobject]$RolePlan
    )

    switch ($RolePlan.effective_agent) {
        'codex' {
            return 'gpt-5.2-codex'
        }
        'claude' {
            if ($RoleName -in @('Reviewer', 'Spec Steward')) {
                return 'claude-sonnet-4.5'
            }

            if ($RoleName -eq 'Implementer') {
                return 'claude-sonnet-4.5'
            }

            return 'claude-sonnet-4.5'
        }
        default {
            return $null
        }
    }
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

    try {
        $existingConfig = Get-Content -LiteralPath $configPath -Raw -Encoding UTF8 | ConvertFrom-Json -AsHashtable
        if ($null -eq $existingConfig) {
            return [ordered]@{ version = 1 }
        }

        return $existingConfig
    }
    catch {
        throw "Failed to parse Squad config '$configPath': $($_.Exception.Message)"
    }
}

function Set-SquadModelOverrides {
    param(
        [string]$Root,
        [pscustomobject]$RoutingPlan
    )

    $configPath = Get-SquadConfigPath -Root $Root
    $agentModelOverrides = [ordered]@{}
    $roleAgentFamilies = [ordered]@{}
    foreach ($roleEntry in $RoutingPlan.roles.GetEnumerator()) {
        $roleAgentFamilies[$roleEntry.Key] = $roleEntry.Value.effective_agent
        $resolvedModel = Get-ModelForRoleRouting -RoleName $roleEntry.Key -RolePlan $roleEntry.Value
        if (-not [string]::IsNullOrWhiteSpace($resolvedModel)) {
            $agentModelOverrides[$roleEntry.Key] = $resolvedModel
        }
    }

    $null = Update-LockedFileContent -Path $configPath -Transform {
        param([string]$CurrentContent)

        $config = if ([string]::IsNullOrWhiteSpace($CurrentContent)) {
            [ordered]@{ version = 1 }
        }
        else {
            try {
                $parsedConfig = $CurrentContent | ConvertFrom-Json -AsHashtable
                if ($null -eq $parsedConfig) { [ordered]@{ version = 1 } } else { $parsedConfig }
            }
            catch {
                throw "Failed to parse Squad config '$configPath': $($_.Exception.Message)"
            }
        }

        if (-not $config.ContainsKey('version')) {
            $config['version'] = 1
        }

        if ($agentModelOverrides.Count -gt 0) {
            $config['agentModelOverrides'] = $agentModelOverrides
        }
        elseif ($config.ContainsKey('agentModelOverrides')) {
            $config.Remove('agentModelOverrides')
        }

        $config['specrewManagedModelRouting'] = [ordered]@{
            baselineAgentModelOverrides = $agentModelOverrides
            roleAgentFamilies           = $roleAgentFamilies
            activeEscalation            = [ordered]@{
                status            = 'inactive'
                role              = $null
                tier              = 'efficiency'
                sourceIteration   = $null
                sourceArtifact    = $null
                sourceGate        = $null
                updatedAt         = $null
            }
        }

        return (($config | ConvertTo-Json -Depth 10) + [Environment]::NewLine)
    }

    return $agentModelOverrides
}

function Get-RoutingPlanPromptBlock {
    param([pscustomobject]$RoutingPlan)

    $lines = @(
        'Effective delegated agent routing plan:'
        ('- Enabled agents: {0}' -f ($RoutingPlan.enabled_agents -join ', '))
    )

    foreach ($roleEntry in $RoutingPlan.roles.GetEnumerator()) {
        $line = '- {0} -> {1} (preferred: {2}; access path: {3}' -f $roleEntry.Value.role, $roleEntry.Value.effective_agent, $roleEntry.Value.requested_agent, $roleEntry.Value.access_path
        if (-not [string]::IsNullOrWhiteSpace($roleEntry.Value.fallback_reason)) {
            $line = '{0}; fallback: {1}' -f $line, $roleEntry.Value.fallback_reason
        }

        $line = '{0})' -f $line
        $lines += $line
    }

    if ($RoutingPlan.fallback_events.Count -gt 0) {
        $lines += '- Start-time fallback events were detected; preserve them in lifecycle logging if they recur.'
    }
    else {
        $lines += '- No start-time fallback events detected.'
    }

    return $lines -join [Environment]::NewLine
}

function Get-StartPrompt {
    param(
        [string]$ResolvedProjectPath,
        [string]$Mode,
        [string]$FeatureRequest,
        [string]$ResolvedFeaturePath,
        [pscustomobject]$TeamRoster,
        [pscustomobject]$RoutingPlan,
        [pscustomobject]$ProjectState,
        [AllowNull()][pscustomobject]$BrownfieldDiscovery,
        [pscustomobject]$DeliveryGuidance
    )

    $featureLine = if ($ResolvedFeaturePath) {
        "Active feature directory: $ResolvedFeaturePath"
    }
    else {
        'Active feature directory: (create or resolve from this request)'
    }

    $requestLine = if ($FeatureRequest) {
        "User feature request: $FeatureRequest"
    }
    else {
        'User feature request: (not provided yet; gather or confirm during intake)'
    }

    $teamRosterBlock = Get-TeamRosterPromptBlock -TeamRoster $TeamRoster
    $routingPlanBlock = Get-RoutingPlanPromptBlock -RoutingPlan $RoutingPlan
    $projectStateBlock = Get-ProjectStatePromptBlock -ProjectState $ProjectState
    $brownfieldDiscoveryBlock = Get-BrownfieldDiscoveryPromptBlock -BrownfieldDiscovery $BrownfieldDiscovery
    $deliveryGuidanceBlock = Get-DeliveryGuidancePromptBlock -DeliveryGuidance $DeliveryGuidance

    return @"
You are Squad running inside a Specrew-bootstrapped repository.

Project root: $ResolvedProjectPath
Mode: $Mode
$featureLine
$requestLine

$teamRosterBlock

$projectStateBlock

$brownfieldDiscoveryBlock

$deliveryGuidanceBlock

$routingPlanBlock

Follow this conversational sequence before implementation work:
1. Preserve the roster snapshot first. Treat the operational roster above as active project state, do not recast it, and defer specialist additions until the spec and clarify outcome are grounded.
2. Classify the repository using the project-state snapshot above before asking for spec details:
   - "greenfield-new": freshly bootstrapped project with no meaningful app code or active specs yet
   - "brownfield-new": existing app/project content but no active Specrew feature to continue
   - "existing-continue": active feature directory or in-progress lifecycle work already exists
3. If the state is "existing-continue", continue from the earliest incomplete lifecycle phase without asking the human to restate the feature.
4. If the state is "greenfield-new" and no concrete feature request is available yet, ask an explicit interactive question such as "What do you want to build?" and wait for the human developer's answer before invoking any `speckit.*` lifecycle agent or command.
5. If greenfield intake is still incomplete after the first answer, continue with one targeted follow-up question at a time and keep intake open until the scope is concrete enough for `speckit.specify`.
6. If the state is "brownfield-new", perform brownfield discovery before asking the human broad intake questions: inspect existing code structure, package/manifests, markdown/docs files, and recent git history to reconstruct the current product/system baseline.
7. For "brownfield-new", use that repo evidence to draft or update the starting spec context yourself, identify likely technology/domain constraints, and ask only targeted follow-up questions about the intended change, corrections, or unresolved decisions.
8. Continue negotiating brownfield scope until the requested change is concrete enough for `speckit.specify`; discovery alone is never sufficient scope, and unresolved intake still requires a human answer before lifecycle execution begins.

Then follow the formal Specrew + Spec Kit lifecycle end to end:
9. Use the Spec Kit flow in order by invoking the dedicated Speckit agents or commands (not generic skills): speckit.specify -> speckit.clarify -> speckit.specrew-speckit.before-plan -> speckit.plan -> speckit.tasks -> speckit.specrew-speckit.after-tasks -> speckit.specrew-speckit.before-implement -> speckit.implement.
10. After speckit.specify, run speckit.clarify for every newly generated spec before speckit.plan so Spec Kit can surface unresolved questions and validate the spec shape.
11. Only skip speckit.clarify when resuming an existing feature whose current spec has already been clarified or is demonstrably unchanged and already materially complete for planning.
12. If you skip speckit.clarify, record a concrete dated skip rationale in .squad\decisions.md before speckit.plan, naming why the current spec is already clear enough to plan safely.
13. If Mode is new-feature, treat the provided text as a short plain-language request or source-spec pointer, ground any missing intake first, and only then invoke `speckit.specify`. Do not expect the human to provide a full spec upfront.
14. If Mode is intake-or-resume, inspect the repository, .specify\feature.json, existing specs, and iteration artifacts. Continue any in-progress feature automatically; otherwise gather only the missing intake needed to begin specify, and do not call `speckit.specify` until that intake is grounded.
15. If the human provides a URL, pasted draft, or other source document during intake, extract the relevant scope from it, confirm any remaining behavior questions at intake, and then pass the grounded request into `speckit.specify`.
16. Answer clarification questions yourself whenever repo context, existing artifacts, or reasonable defaults make the answer clear enough, and write those clarification outcomes back into the active spec before planning.
17. Only ask the human developer questions that are still unresolved and materially affect scope, behavior, governance, or UX.
18. Once speckit.clarify completes, or you explicitly skip it with the recorded rationale above, continue automatically through `speckit.specrew-speckit.before-plan`, `speckit.plan`, `speckit.tasks`, and `speckit.specrew-speckit.after-tasks` without waiting for the human to manually trigger each phase.
19. After speckit.specify and the clarify outcome are grounded, analyze the planned feature, inferred technology constraints, the roster snapshot, and the readiness hints above. Propose only the missing specialists, and only propose Junior/Senior same-specialty pairs when the clarified work can be partitioned safely enough for meaningful parallel execution.
20. Preserve any user-added Specrew members, present the resulting team composition clearly before implementation, and describe Junior/Senior pairs as distinct named members with different task profiles rather than cloned copies of one role.
21. If the human approves new specialists or Junior/Senior same-specialty pairs, materialize them with `specrew team add <member-name> --role <role> --charter "<charter>"` before invoking `speckit.specrew-speckit.before-implement` or `speckit.implement`.
22. If an approved Junior/Senior pair exists, route bounded, lower-risk, well-scoped work to the Junior role, but keep the quality bar high: Junior execution must still be careful, responsible, knowledgeable, and review-ready, with explicit checks for correctness, edge cases, tests, and maintainability. Route ambiguous, cross-cutting, integration-heavy, concurrency-sensitive, or reviewer-gated work to the Senior role, whose ownership should reflect deep technical judgment across architecture, systems thinking, computer science depth, tradeoff analysis, and long-range software engineering consequences.
23. Only run Junior and Senior same-specialty work in parallel when ownership boundaries are explicit enough to avoid redundant or conflicting execution. If the slices overlap, stay serial or define a concrete coordination plan first.
24. If Junior-owned work hits repeated governance failures, integration risk, or a shared-surface conflict, escalate that slice to the Senior role or to an independent reviewer instead of looping with unsafe same-specialty parallelism.
25. Derive the quality bar from the current feature and project context. Carry the applicable quality attributes into spec clarifications, plan, tasks, implementation, and review. Focus on production-grade concerns that materially apply, such as robustness, retries, idempotency, error handling, logging, telemetry, security, clean code, SOLID boundaries, and semantic correctness.
26. Treat mechanisms such as revisions, idempotency keys, retries, conflict detection, locks, or telemetry as incomplete until they have real runtime semantics and review evidence. Flag ceremonial sophistication rather than assuming the presence of fields equals correctness.
27. Before implementation begins, summarize readiness for the human developer: active feature, clarify outcome, quality focus, and final team composition. If the active slice includes Phase 2 hardening-gate scope, include the hardening-gate verdict and any human-approved deferral status in that readiness summary. Then ask the human developer to explicitly start implementation. Do not invoke speckit.implement until the human approves.
28. After speckit.specrew-speckit.after-tasks succeeds, treat speckit.specrew-speckit.before-implement as the next automatic lifecycle step once implementation approval is granted. Do not stop at the after-tasks boundary to ask the human to manually trigger hardening review, explain the blocker, or request a deferral decision that belongs to before-implement.
29. If speckit.specrew-speckit.before-implement blocks, explain the concrete blocking artifact or verdict, why it blocks implementation, and the next valid human action before stopping.
30. After the explicit implementation go-ahead, run `speckit.specrew-speckit.before-implement` and continue through implementation, review/demo, and retrospective without asking the human to manually trigger each remaining phase.
31. Preserve the canonical artifact chain on disk: specs/<feature>/spec.md, plan.md, tasks.md, and specs/<feature>/iterations/<NNN>/{plan.md,state.md,drift-log.md,review.md,retro.md} as phases progress.
32. If any lifecycle agent reports a file-write or tool-contract failure, or a required artifact is missing on disk, stop and repair that underlying failure before claiming the phase succeeded or invoking the next governance gate.
33. At the end of implementation and review, provide a developer-facing implementation briefing covering what was built, requirement coverage, the main happy path and relevant alternative flows, dependency usage including newly introduced packages, the testing strategy, and an explicitly labeled estimate of coverage or confidence.
34. Keep the spec authoritative, surface drift explicitly, and do not claim Spec-Kit/Specrew compliance if you bypass the lifecycle.
35. If the roster snapshot says Mode is specrew-managed, treat it as active project state. Do NOT run generic Squad team setup, do NOT replace the baseline roles, and do NOT discard supplemental members.
36. Use the delegated routing plan above for lifecycle work and repair ownership unless the human explicitly overrides it. Planning/problem-solving work should prefer Planner or Spec Steward delegated routing when enabled, and review/governance work should prefer Reviewer or Spec Steward delegated routing when enabled.
37. For every delegated lifecycle, review, governance, or repair spawn, append a short dated runtime-evidence entry to .squad\decisions.md naming the role or work item, requested agent, actual agent, concrete model ID, whether the assignment was honored or fell back, and any fallback reason.
38. Operate with a no-gap policy for lifecycle-governed work. If review, governance, or validation reveals a known alignment gap across spec, implementation, tests, docs, or observability, do not close the run as complete until the gap is fixed or the human explicitly approves a defer that is recorded in the governing artifacts.
39. During review and final readiness checks, act as a critical reviewer for hardened lifecycle/governance requirements: classify them as implemented, enforced, observable, and documented, and emit a gap ledger whenever any dimension is missing.
40. If review finds an ambiguity, contradiction, or missing decision in the governing spec, stop closure, ask targeted clarification questions, update the spec with the answers, and reconcile any affected plan, tasks, review, or governance artifacts before continuing.
41. If the human approves deferring a known gap, record the defer rationale, affected requirement or artifact, and next action explicitly instead of letting the gap roll into the next iteration invisibly.
42. Before spawning lifecycle agents, read .squad\config.json and honor any "agentModelOverrides". Re-read it before each repair spawn instead of caching it once for the entire session.
43. When a governance-gate failure activates or resolves repair escalation, run `.specify\extensions\specrew-speckit\scripts\sync-squad-model-overrides.ps1 -IterationDirectory <active-iteration>` so `.squad\config.json` is updated immediately from the current escalation state.
44. On repeated governance-gate failures, use that sync helper to raise the failing repair owner's model tier (balanced -> deep) and clear the temporary override after the gate passes.

Your goal is to let the human developer primarily answer unresolved questions while Squad handles the rest of the lifecycle automatically.
"@
}

function Get-DelegatedRoutingSummaryLines {
    param(
        [pscustomobject]$RoutingPlan,
        [System.Collections.IDictionary]$SquadModelOverrides
    )

    $lines = New-Object System.Collections.Generic.List[string]
    foreach ($roleEntry in $RoutingPlan.roles.GetEnumerator()) {
        $modelId = if ($SquadModelOverrides.Contains($roleEntry.Key)) { [string]$SquadModelOverrides[$roleEntry.Key] } else { '(platform default)' }
        $status = if ([string]::IsNullOrWhiteSpace($roleEntry.Value.fallback_reason)) { 'honored' } else { 'fell-back' }
        $fallbackReason = if ([string]::IsNullOrWhiteSpace($roleEntry.Value.fallback_reason)) { '(none)' } else { $roleEntry.Value.fallback_reason }
        $lines.Add(("  - {0} | requested={1} | actual={2} | model={3} | status={4} | fallback={5}" -f $roleEntry.Value.role, $roleEntry.Value.requested_agent, $roleEntry.Value.effective_agent, $modelId, $status, $fallbackReason)) | Out-Null
    }

    return $lines.ToArray()
}

function Write-DelegatedRoutingLedgerEntries {
    param(
        [string]$ResolvedProjectPath,
        [pscustomobject]$RoutingPlan,
        [System.Collections.IDictionary]$SquadModelOverrides
    )

    $hasDelegatedAssignment = $false
    foreach ($roleEntry in $RoutingPlan.roles.GetEnumerator()) {
        if ($roleEntry.Value.delegated -or -not [string]::IsNullOrWhiteSpace($roleEntry.Value.fallback_reason)) {
            $hasDelegatedAssignment = $true
            break
        }
    }

    if (-not $hasDelegatedAssignment) {
        return
    }

    $ledgerLines = @(
        "- **Enabled Agents**: $(@($RoutingPlan.enabled_agents) -join ', ')"
        "- **Independent Oversight Active**: $($RoutingPlan.independent_oversight_active)"
        '- **Roles**:'
    ) + (Get-DelegatedRoutingSummaryLines -RoutingPlan $RoutingPlan -SquadModelOverrides $SquadModelOverrides)

    Add-DecisionsLedgerEntry -ProjectRoot $ResolvedProjectPath -Title 'Delegated routing plan' -Lines $ledgerLines | Out-Null

    foreach ($roleEntry in $RoutingPlan.roles.GetEnumerator()) {
        if (-not $roleEntry.Value.delegated -and [string]::IsNullOrWhiteSpace($roleEntry.Value.fallback_reason)) {
            continue
        }

        $modelId = if ($SquadModelOverrides.Contains($roleEntry.Key)) { [string]$SquadModelOverrides[$roleEntry.Key] } else { '(platform default)' }
        $status = if ([string]::IsNullOrWhiteSpace($roleEntry.Value.fallback_reason)) { 'honored' } else { 'fell-back' }
        $fallbackReason = if ([string]::IsNullOrWhiteSpace($roleEntry.Value.fallback_reason)) { '(none)' } else { $roleEntry.Value.fallback_reason }

        Add-StructuredDecisionsLedgerEntry -ProjectRoot $ResolvedProjectPath -Title ("Routing evidence: {0}" -f $roleEntry.Value.role) -Type 'routing-evidence' -AffectedRequirement 'FR-043' -NextAction 'none' -Rationale ("Delegated lifecycle routing was applied for role '{0}'." -f $roleEntry.Value.role) -DetailLines @(
            ('- **Routing Evidence**: {0} | requested={1} | actual={2} | model={3} | status={4} | fallback={5}' -f $roleEntry.Value.role, $roleEntry.Value.requested_agent, $roleEntry.Value.effective_agent, $modelId, $status, $fallbackReason)
        ) | Out-Null
    }
}

function Get-StartSummaryContent {
    param(
        [string]$ResolvedProjectPath,
        [string]$Mode,
        [string]$FeatureRequest,
        [string]$ResolvedFeaturePath,
        [string]$ApprovalMode,
        [string]$LaunchMode,
        [bool]$UseAutopilot,
        [pscustomobject]$ProjectState,
        [AllowNull()][pscustomobject]$BrownfieldDiscovery,
        [pscustomobject]$DeliveryGuidance,
        [pscustomobject]$RoutingPlan,
        [System.Collections.IDictionary]$SquadModelOverrides
    )

    $summaryLines = New-Object System.Collections.Generic.List[string]
    $summaryLines.Add('# Specrew Start Summary') | Out-Null
    $summaryLines.Add('') | Out-Null
    $summaryLines.Add(("## Session")) | Out-Null
    $summaryLines.Add(("- **Mode**: {0}" -f $Mode)) | Out-Null
    $summaryLines.Add(("- **Project State**: {0}" -f $ProjectState.state)) | Out-Null
    $summaryLines.Add(("- **Feature Request**: {0}" -f $(if ([string]::IsNullOrWhiteSpace($FeatureRequest)) { '(none provided)' } else { $FeatureRequest }))) | Out-Null
    $summaryLines.Add(("- **Active Feature Path**: {0}" -f $(if ([string]::IsNullOrWhiteSpace($ResolvedFeaturePath)) { '(create or resolve during lifecycle)' } else { Get-DisplayPathFromProjectRoot -ResolvedProjectPath $ResolvedProjectPath -Path $ResolvedFeaturePath }))) | Out-Null
    $summaryLines.Add('') | Out-Null
    $summaryLines.Add('## Launch Contract') | Out-Null
    $summaryLines.Add(("- **Approval Mode**: {0}" -f $ApprovalMode)) | Out-Null
    $summaryLines.Add(("- **Launch Mode**: {0}" -f $LaunchMode)) | Out-Null
    $summaryLines.Add(("- **Copilot Autopilot**: {0}" -f $UseAutopilot)) | Out-Null
    $summaryLines.Add(("- **Operator Note**: {0}" -f $(if ($ApprovalMode -eq 'allow-all' -and -not $UseAutopilot) { 'allow-all reduces later tool-approval blocking, but intake still remains interactive until the scope is grounded.' } elseif ($ApprovalMode -eq 'allow-all') { 'allow-all reduces tool-approval blocking after the request is grounded.' } else { 'prompt-approvals keeps Copilot permission prompts interactive throughout the session.' }))) | Out-Null
    $summaryLines.Add('') | Out-Null
    $summaryLines.Add('## Human Gates') | Out-Null
    $summaryLines.Add('- Clarify is mandatory for newly generated specs unless a concrete skip rationale is recorded first.') | Out-Null
    $summaryLines.Add('- After spec + clarify, Squad presents the final team and asks for explicit implementation approval.') | Out-Null
    $summaryLines.Add('- Review/closure use a no-gap policy: known gaps are fixed now or explicitly deferred with human approval and recorded in artifacts.') | Out-Null
    $summaryLines.Add('- End-of-run handoff includes a developer-facing implementation briefing.') | Out-Null
    $summaryLines.Add('') | Out-Null
    $summaryLines.Add('## Delegated Routing') | Out-Null
    $summaryLines.Add(("- **Enabled Agents**: {0}" -f $(@($RoutingPlan.enabled_agents) -join ', '))) | Out-Null
    $summaryLines.Add(("- **Independent Oversight Active**: {0}" -f $RoutingPlan.independent_oversight_active)) | Out-Null
    foreach ($line in Get-DelegatedRoutingSummaryLines -RoutingPlan $RoutingPlan -SquadModelOverrides $SquadModelOverrides) {
        $summaryLines.Add($line) | Out-Null
    }

    if ($null -ne $BrownfieldDiscovery) {
        $summaryLines.Add('') | Out-Null
        $summaryLines.Add('## Brownfield Discovery') | Out-Null
        $technologies = @($BrownfieldDiscovery.technologies | ForEach-Object { $_.name })
        $summaryLines.Add(("- **Technologies**: {0}" -f $(if ($technologies.Count -gt 0) { $technologies -join ', ' } else { '(none inferred)' }))) | Out-Null
        $summaryLines.Add(("- **Domain Signals**: {0}" -f $(if (@($BrownfieldDiscovery.domain_signals).Count -gt 0) { @($BrownfieldDiscovery.domain_signals) -join ', ' } else { '(none inferred)' }))) | Out-Null
    }

    $qualityNames = @($DeliveryGuidance.quality_attributes | ForEach-Object { $_.name })
    $summaryLines.Add('') | Out-Null
    $summaryLines.Add('## Quality Focus') | Out-Null
    $summaryLines.Add(("- **Applicable Attributes**: {0}" -f $(if ($qualityNames.Count -gt 0) { $qualityNames -join ', ' } else { '(none inferred)' }))) | Out-Null

    return (($summaryLines -join [Environment]::NewLine).TrimEnd() + [Environment]::NewLine)
}

function Save-StartArtifacts {
    param(
        [string]$ResolvedProjectPath,
        [string]$PromptContent,
        [string]$Mode,
        [string]$FeatureRequest,
        [string]$ResolvedFeaturePath,
        [string]$Agent,
        [string]$ApprovalMode,
        [pscustomobject]$TeamRoster,
        [pscustomobject]$RoutingPlan,
        [System.Collections.IDictionary]$SquadModelOverrides,
        [string]$LaunchMode,
        [bool]$UseAutopilot,
        [pscustomobject]$ProjectState,
        [AllowNull()][pscustomobject]$BrownfieldDiscovery,
        [pscustomobject]$DeliveryGuidance
    )

    $specrewRoot = Join-Path $ResolvedProjectPath '.specrew'
    $promptPath = Join-Path $specrewRoot 'last-start-prompt.md'
    $contextPath = Join-Path $specrewRoot 'start-context.json'
    $summaryPath = Join-Path $specrewRoot 'start-summary.md'

    Write-Utf8FileAtomic -Path $promptPath -Content $PromptContent

    $context = [ordered]@{
        mode             = $Mode
        feature_request  = $FeatureRequest
        feature_path     = $ResolvedFeaturePath
        agent            = $Agent
        approval_mode    = $ApprovalMode
        launch_mode      = $LaunchMode
        copilot_autopilot = $UseAutopilot
        project_state    = $ProjectState
        brownfield_discovery = $BrownfieldDiscovery
        delivery_guidance = $DeliveryGuidance
        team_roster      = $TeamRoster
        delegated_routing = $RoutingPlan
        delegated_routing_evidence = [ordered]@{
            ledger_path     = '.squad\decisions.md'
            required_fields = @('role_or_work_item', 'requested_agent', 'actual_agent', 'model_id', 'status', 'fallback_reason')
        }
        squad_model_overrides = $SquadModelOverrides
        prompt_path      = $promptPath
        summary_path     = $summaryPath
        generated_at_utc = [DateTime]::UtcNow.ToString('o')
    } | ConvertTo-Json -Depth 7

    Write-Utf8FileAtomic -Path $contextPath -Content $context
    Write-Utf8FileAtomic -Path $summaryPath -Content (Get-StartSummaryContent `
            -ResolvedProjectPath $ResolvedProjectPath `
            -Mode $Mode `
            -FeatureRequest $FeatureRequest `
            -ResolvedFeaturePath $ResolvedFeaturePath `
            -ApprovalMode $ApprovalMode `
            -LaunchMode $LaunchMode `
            -UseAutopilot $UseAutopilot `
            -ProjectState $ProjectState `
            -BrownfieldDiscovery $BrownfieldDiscovery `
            -DeliveryGuidance $DeliveryGuidance `
            -RoutingPlan $RoutingPlan `
            -SquadModelOverrides $SquadModelOverrides)

    return [pscustomobject]@{
        PromptPath  = $promptPath
        ContextPath = $contextPath
        SummaryPath = $summaryPath
    }
}

function Get-DisplayPathFromProjectRoot {
    param(
        [string]$ResolvedProjectPath,
        [string]$Path
    )

    $projectRoot = [System.IO.Path]::GetFullPath($ResolvedProjectPath).TrimEnd('\')
    $resolvedPath = [System.IO.Path]::GetFullPath($Path)
    if ($resolvedPath.StartsWith($projectRoot, [System.StringComparison]::OrdinalIgnoreCase)) {
        $relativePath = $resolvedPath.Substring($projectRoot.Length).TrimStart('\')
        if (-not [string]::IsNullOrWhiteSpace($relativePath)) {
            return $relativePath
        }
    }

    return $resolvedPath
}

function Get-CopilotBootstrapInput {
    param(
        [string]$ResolvedProjectPath,
        [string]$PromptPath,
        [string]$ContextPath,
        [bool]$RequireInteractiveIntake
    )

    $promptDisplayPath = Get-DisplayPathFromProjectRoot -ResolvedProjectPath $ResolvedProjectPath -Path $PromptPath
    $contextDisplayPath = Get-DisplayPathFromProjectRoot -ResolvedProjectPath $ResolvedProjectPath -Path $ContextPath
    $lines = @(
        "Read '$promptDisplayPath' and '$contextDisplayPath' from the project root before doing anything else."
        "Treat '$promptDisplayPath' as the authoritative Specrew handoff and '$contextDisplayPath' as the current lifecycle state."
    )

    if ($RequireInteractiveIntake) {
        $lines += "If intake is still unresolved after reading those files, ask the next intake question and wait for the human developer's answer before invoking any Speckit lifecycle agent or command, skipping clarify, or guessing missing scope."
    }
    else {
        $lines += "After reading those files, follow the lifecycle exactly as directed by the handoff and do not bypass required clarify or governance gates."
    }

    return $lines -join ' '
}

function Get-ManualCopilotCommand {
    param(
        [string]$ResolvedProjectPath,
        [string]$PromptPath,
        [string]$ContextPath,
        [string]$Agent,
        [bool]$AllowAll,
        [bool]$UseAutopilot,
        [bool]$RequireInteractiveIntake
    )

    $quotedProjectPath = $ResolvedProjectPath.Replace("'", "''")
    $quotedAgent = $Agent.Replace("'", "''")
    $quotedBootstrap = (Get-CopilotBootstrapInput -ResolvedProjectPath $ResolvedProjectPath -PromptPath $PromptPath -ContextPath $ContextPath -RequireInteractiveIntake $RequireInteractiveIntake).Replace("'", "''")
    $autopilotSegment = if ($UseAutopilot) { ' --autopilot' } else { '' }
    $allowAllSegment = if ($AllowAll) { ' --allow-all' } else { '' }

    return '$bootstrap = ''{0}''; copilot --agent ''{1}''{2} --add-dir ''{3}'' -i $bootstrap{4}' -f $quotedBootstrap, $quotedAgent, $autopilotSegment, $quotedProjectPath, $allowAllSegment
}

function Start-CopilotSession {
    param(
        [string]$ResolvedProjectPath,
        [string]$PromptPath,
        [string]$ContextPath,
        [string]$Agent,
        [bool]$AllowAll,
        [bool]$SameWindow,
        [bool]$UseAutopilot,
        [bool]$RequireInteractiveIntake
    )

    $copilotCommand = Get-Command copilot -ErrorAction SilentlyContinue
    if (-not $copilotCommand) {
        return $false
    }

    $bootstrapInput = Get-CopilotBootstrapInput -ResolvedProjectPath $ResolvedProjectPath -PromptPath $PromptPath -ContextPath $ContextPath -RequireInteractiveIntake $RequireInteractiveIntake
    $copilotArgs = @('--agent', $Agent)

    if ($UseAutopilot) {
        $copilotArgs += '--autopilot'
    }

    $copilotArgs += @(
        '--add-dir', $ResolvedProjectPath,
        '-i', $bootstrapInput
    )

    if ($AllowAll) {
        $copilotArgs += '--allow-all'
    }

    if ($IsWindows) {
        $quotedProjectPath = $ResolvedProjectPath.Replace("'", "''")
        $quotedAgent = $Agent.Replace("'", "''")
        $quotedCopilotSource = $copilotCommand.Source.Replace("'", "''")
        $quotedBootstrap = $bootstrapInput.Replace("'", "''")
        $autopilotSnippet = if ($UseAutopilot) { '$args += ''--autopilot''' } else { '' }
        $allowAllSnippet = if ($AllowAll) { '$args += ''--allow-all''' } else { '' }
        $launchScript = @'
Set-Location -LiteralPath '{0}'
$bootstrapInput = '{1}'
$args = @('--agent', '{2}')
{3}
$args += @('--add-dir', '{0}', '-i', $bootstrapInput)
{4}
& '{5}' @args
'@ -f $quotedProjectPath, $quotedBootstrap, $quotedAgent, $autopilotSnippet, $allowAllSnippet, $quotedCopilotSource

        if ($SameWindow) {
            $process = Start-Process -FilePath 'pwsh' -ArgumentList @('-NoLogo', '-NoProfile', '-ExecutionPolicy', 'Bypass', '-Command', $launchScript) -WorkingDirectory $ResolvedProjectPath -NoNewWindow -PassThru -Wait
            return ($null -ne $process -and $process.ExitCode -eq 0)
        }

        Start-Process -FilePath 'pwsh' -ArgumentList @('-NoLogo', '-NoExit', '-NoProfile', '-ExecutionPolicy', 'Bypass', '-Command', $launchScript) -WorkingDirectory $ResolvedProjectPath | Out-Null
        return $true
    }

    Push-Location -LiteralPath $ResolvedProjectPath
    try {
        & $copilotCommand.Source @copilotArgs
        return $true
    }
    finally {
        Pop-Location
    }
}

if ($Help) {
    Show-Usage
    exit 0
}

$resolvedProjectPath = [System.IO.Path]::GetFullPath($ProjectPath)

if (-not (Test-Path -LiteralPath $resolvedProjectPath -PathType Container)) {
    Write-Error-Message "Project path does not exist: $resolvedProjectPath"
    exit 1
}

$requiredBootstrapPaths = @(
    '.specrew\config.yml',
    '.specify',
    '.squad',
    '.github\agents\squad.agent.md'
)

$missingBootstrapPaths = @(
    foreach ($relativePath in $requiredBootstrapPaths) {
        if (-not (Test-BootstrapSurface -Root $resolvedProjectPath -RelativePath $relativePath)) {
            $relativePath
        }
    }
)

if ($missingBootstrapPaths.Count -gt 0) {
    Write-Error-Message "Project is not fully bootstrapped for Specrew start."
    Write-Error-Message ("Missing required paths: {0}" -f ($missingBootstrapPaths -join ', '))
    Write-Error-Message "Run 'specrew init' first."
    exit 1
}

if ($AllowAll -and $PromptApprovals) {
    Write-Error-Message "Use either --allow-all or --prompt-approvals, not both."
    exit 1
}

if ($NewWindow -and $SameWindow) {
    Write-Error-Message "Use either --new-window or --same-window, not both."
    exit 1
}

if ($FeatureRequest -and -not $ResumeFeature) {
    $resolvedFeaturePath = $null
}
elseif (-not $FeatureRequest -and -not $ResumeFeature) {
    try {
        $resolvedFeaturePath = Resolve-FeatureDirectory -Root $resolvedProjectPath -ResumeFeature 'auto'
    }
    catch {
        $resolvedFeaturePath = $null
    }
}
else {
    try {
        $resolvedFeaturePath = Resolve-FeatureDirectory -Root $resolvedProjectPath -ResumeFeature $ResumeFeature
    }
    catch {
        Write-Error-Message $_.Exception.Message
        exit 1
    }
}
$mode = if ($FeatureRequest) {
    'new-feature'
}
elseif ($ResumeFeature -or $resolvedFeaturePath) {
    'resume-feature'
}
else {
    'intake-or-resume'
}
$teamRoster = Get-TeamRoster -Root $resolvedProjectPath
$projectState = Get-ProjectStateSnapshot -Root $resolvedProjectPath -ResolvedFeaturePath $resolvedFeaturePath
$brownfieldDiscovery = Get-BrownfieldDiscoverySnapshot -Root $resolvedProjectPath -ProjectState $projectState -TeamRoster $teamRoster
$deliveryGuidance = Get-DeliveryGuidanceSnapshot -FeatureRequest $FeatureRequest -ProjectState $projectState -BrownfieldDiscovery $brownfieldDiscovery -TeamRoster $teamRoster
$agentConfig = Get-IterationAgentConfig -Root $resolvedProjectPath
$roleAssignments = @(Get-RoleAssignments -Root $resolvedProjectPath)
$routingPlan = Get-DelegatedRoutingPlan -RoleAssignments $roleAssignments -AgentLookup $agentConfig
$squadModelOverrides = Set-SquadModelOverrides -Root $resolvedProjectPath -RoutingPlan $routingPlan
Write-DelegatedRoutingLedgerEntries -ResolvedProjectPath $resolvedProjectPath -RoutingPlan $routingPlan -SquadModelOverrides $squadModelOverrides
$requiresInteractiveIntake = ($mode -eq 'intake-or-resume' -and -not $FeatureRequest -and -not $resolvedFeaturePath)
$useAutopilot = -not $requiresInteractiveIntake
$effectiveAllowAll = if ($PromptApprovals) { $false } else { $true }
$approvalMode = if ($effectiveAllowAll) { 'allow-all' } else { 'prompt-approvals' }
$launchMode = if ($NoLaunch) { 'none' } elseif ($NewWindow -and $IsWindows) { 'new-window' } else { 'same-window' }
$promptContent = Get-StartPrompt `
    -ResolvedProjectPath $resolvedProjectPath `
    -Mode $mode `
    -FeatureRequest $FeatureRequest `
    -ResolvedFeaturePath $resolvedFeaturePath `
    -TeamRoster $teamRoster `
    -RoutingPlan $routingPlan `
    -ProjectState $projectState `
    -BrownfieldDiscovery $brownfieldDiscovery `
    -DeliveryGuidance $deliveryGuidance

$artifactPaths = Save-StartArtifacts `
    -ResolvedProjectPath $resolvedProjectPath `
    -PromptContent $promptContent `
    -Mode $mode `
    -FeatureRequest $FeatureRequest `
    -ResolvedFeaturePath $resolvedFeaturePath `
    -Agent $Agent `
    -ApprovalMode $approvalMode `
    -TeamRoster $teamRoster `
    -RoutingPlan $routingPlan `
    -SquadModelOverrides $squadModelOverrides `
    -LaunchMode $launchMode `
    -UseAutopilot $useAutopilot `
    -ProjectState $projectState `
    -BrownfieldDiscovery $brownfieldDiscovery `
    -DeliveryGuidance $deliveryGuidance

Write-Success "Prepared Specrew start context."
Write-Info ("Prompt:  {0}" -f $artifactPaths.PromptPath)
Write-Info ("Context: {0}" -f $artifactPaths.ContextPath)
Write-Info ("Summary: {0}" -f $artifactPaths.SummaryPath)
Write-Info ("Copilot approval mode: {0}" -f $approvalMode)
if ($approvalMode -eq 'allow-all' -and -not $useAutopilot) {
    Write-Info 'allow-all reduces later tool-approval blocking, but intake still stays interactive until the request is grounded.'
}
elseif ($approvalMode -eq 'allow-all') {
    Write-Info 'allow-all reduces tool-approval blocking after the request is grounded.'
}

if ($NoLaunch) {
    Write-Info "Launch skipped by --no-launch."
    Write-Info ("Manual launch command (run from the project root): {0}" -f (Get-ManualCopilotCommand -ResolvedProjectPath $resolvedProjectPath -PromptPath $artifactPaths.PromptPath -ContextPath $artifactPaths.ContextPath -Agent $Agent -AllowAll $effectiveAllowAll -UseAutopilot $useAutopilot -RequireInteractiveIntake $requiresInteractiveIntake))
    exit 0
}

if ($launchMode -eq 'same-window') {
    Write-Info ("Delegating to Copilot + {0} in the current terminal..." -f $Agent)
}
else {
    Write-Info ("Delegating to Copilot + {0} in a new PowerShell window..." -f $Agent)
}

$copilotStarted = Start-CopilotSession `
    -ResolvedProjectPath $resolvedProjectPath `
    -PromptPath $artifactPaths.PromptPath `
    -ContextPath $artifactPaths.ContextPath `
    -Agent $Agent `
    -AllowAll $effectiveAllowAll `
    -SameWindow ($launchMode -eq 'same-window') `
    -UseAutopilot $useAutopilot `
    -RequireInteractiveIntake $requiresInteractiveIntake

if (-not $copilotStarted) {
    Write-Info "Copilot CLI was not available, so Specrew wrote a resume-safe handoff prompt instead."
    Write-Info ("Manual launch command (run from {0}): {1}" -f $resolvedProjectPath, (Get-ManualCopilotCommand -ResolvedProjectPath $resolvedProjectPath -PromptPath $artifactPaths.PromptPath -ContextPath $artifactPaths.ContextPath -Agent $Agent -AllowAll $effectiveAllowAll -UseAutopilot $useAutopilot -RequireInteractiveIntake $requiresInteractiveIntake))
    exit 0
}

if ($launchMode -eq 'new-window') {
    Write-Success ("Delegated to Copilot + {0} in a new PowerShell window." -f $Agent)
    Write-Info "Continue the lifecycle in the new window. This terminal can stay open for reference."
}
