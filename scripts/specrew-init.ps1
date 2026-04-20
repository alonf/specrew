[CmdletBinding(PositionalBinding = $false)]
param(
    [Alias('project-path')]
    [string]$ProjectPath = (Get-Location).Path,
    [Alias('dry-run')]
    [switch]$DryRun,
    [switch]$Force,
    [Alias('speckit-version')]
    [string]$SpecKitVersion = '0.7.3',
    [Alias('squad-version')]
    [string]$SquadVersion = '0.9.1',
    [string]$Agents = 'copilot',
    [Alias('no-agents')]
    [switch]$NoAgents,
    [switch]$Help,
    [Parameter(ValueFromRemainingArguments = $true)]
    [string[]]$CliArgs
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

function Get-NativeExitCode {
    if (Get-Variable -Name LASTEXITCODE -Scope Global -ErrorAction SilentlyContinue) {
        return $global:LASTEXITCODE
    }

    return 0
}

function ConvertTo-YamlBoolean {
    param(
        [Parameter(Mandatory = $true)]
        [bool]$Value
    )

    if ($Value) {
        return 'true'
    }

    return 'false'
}

function Test-ConsoleInputRedirected {
    try {
        return [Console]::IsInputRedirected
    }
    catch {
        return $true
    }
}

function Test-CanPrompt {
    return (-not $Force) -and (-not (Test-ConsoleInputRedirected))
}

function Show-Usage {
    @'
specrew init [options]

Options:
  -ProjectPath | --project-path <path>
                         Target project directory (defaults to current directory)
  -DryRun | --dry-run     Show planned changes without writing
  -Force | --force        Skip interactive prompts and use default selections
  -SpecKitVersion | --speckit-version
                         Minimum Spec Kit version (default: 0.7.3)
  -SquadVersion | --squad-version
                         Minimum Squad version (default: 0.9.1)
  -Agents | --agents      Agent selection: copilot | comma list | all (default: copilot)
  -NoAgents | --no-agents Disable all agents
  -Help | --help          Show usage
'@ | Write-Host
}

function Write-Step {
    param(
        [Parameter(Mandatory = $true)]
        [string]$Message
    )

    Write-Host ("==> {0}" -f $Message) -ForegroundColor Cyan
}

function Invoke-NativeCommand {
    param(
        [Parameter(Mandatory = $true)]
        [string]$FilePath,

        [Parameter(Mandatory = $true)]
        [string[]]$ArgumentList,

        [Parameter(Mandatory = $true)]
        [string]$WorkingDirectory
    )

    Push-Location $WorkingDirectory
    try {
        & $FilePath @ArgumentList
        if ((Get-NativeExitCode) -ne 0) {
            throw ("Command failed: {0} {1}" -f $FilePath, ($ArgumentList -join ' '))
        }
    }
    finally {
        Pop-Location
    }
}

function Invoke-NativeCommandForOutput {
    param(
        [Parameter(Mandatory = $true)]
        [string]$FilePath,

        [Parameter(Mandatory = $true)]
        [string[]]$ArgumentList,

        [Parameter(Mandatory = $true)]
        [string]$WorkingDirectory
    )

    Push-Location $WorkingDirectory
    try {
        $output = @(& $FilePath @ArgumentList 2>&1)
        return [pscustomobject]@{
            ExitCode = Get-NativeExitCode
            Output   = @($output | ForEach-Object { [string]$_ })
        }
    }
    finally {
        Pop-Location
    }
}

function Add-Action {
    param(
        [AllowEmptyCollection()]
        [Parameter(Mandatory = $true)]
        [System.Collections.ArrayList]$Actions,

        [Parameter(Mandatory = $true)]
        [string]$Step,

        [Parameter(Mandatory = $true)]
        [string]$Outcome
    )

    $null = $Actions.Add([pscustomobject]@{
            Step    = $Step
            Outcome = $Outcome
        })
}

function Install-MissingDependency {
    param(
        [Parameter(Mandatory = $true)]
        [pscustomobject]$Dependency,

        [Parameter(Mandatory = $true)]
        [switch]$PreviewOnly
    )

    switch ($Dependency.Platform) {
        'Spec Kit' {
            if (-not (Get-Command uv -ErrorAction SilentlyContinue)) {
                throw "Spec Kit is missing and 'uv' is not available to install it."
            }

            $command = 'uv'
            $arguments = @('tool', 'install', '--upgrade', ('specify-cli>={0}' -f $Dependency.MinimumVersion))
        }
        'Squad' {
            if (-not (Get-Command npm -ErrorAction SilentlyContinue)) {
                throw "Squad is missing and 'npm' is not available to install it."
            }

            $command = 'npm'
            $arguments = @('install', '-g', ('@bradygaster/squad-cli@{0}' -f $Dependency.MinimumVersion))
        }
        default {
            throw "Unsupported dependency platform '$($Dependency.Platform)'."
        }
    }

    if ($PreviewOnly) {
        Write-Host ("[dry-run] {0} {1}" -f $command, ($arguments -join ' ')) -ForegroundColor Yellow
        return
    }

    & $command @arguments
    if ((Get-NativeExitCode) -ne 0) {
        throw ("Failed to install {0}." -f $Dependency.Platform)
    }
}

function Test-SquadInitSupportsNonInteractive {
    param(
        [Parameter(Mandatory = $true)]
        [string]$ProbeRoot
    )

    $probeDirectory = Join-Path $ProbeRoot ('.specrew-squad-probe-{0}' -f [guid]::NewGuid().ToString('N'))

    New-Item -Path $probeDirectory -ItemType Directory -Force | Out-Null
    try {
        try {
            $squadHelp = Invoke-NativeCommandForOutput -FilePath 'squad' -ArgumentList @('init', '--help') -WorkingDirectory $probeDirectory
        }
        catch {
            return $false
        }

        if ($squadHelp.ExitCode -ne 0) {
            return $false
        }

        return (($squadHelp.Output | ForEach-Object { [string]$_ }) -join [Environment]::NewLine) -match '--non-interactive'
    }
    finally {
        if (Test-Path -LiteralPath $probeDirectory) {
            Remove-Item -LiteralPath $probeDirectory -Recurse -Force -ErrorAction SilentlyContinue
        }
    }
}

function Get-SquadInitArgumentList {
    param(
        [Parameter(Mandatory = $true)]
        [string]$ProbeRoot
    )

    $arguments = @('init')

    if (Test-SquadInitSupportsNonInteractive -ProbeRoot $ProbeRoot) {
        $arguments += '--non-interactive'
    }

    return $arguments
}

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

function Get-CopilotSignals {
    $signals = @()

    foreach ($variableName in @('COPILOT_CLI', 'COPILOT_AGENT_SESSION_ID', 'COPILOT_CLI_BINARY_VERSION')) {
        $value = [Environment]::GetEnvironmentVariable($variableName)
        if (-not [string]::IsNullOrWhiteSpace($value)) {
            $signals += $variableName
        }
    }

    return $signals
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
    $copilotSignals = @(Get-CopilotSignals)
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

function Read-AgentConsent {
    param(
        [Parameter(Mandatory = $true)]
        [pscustomobject]$Agent
    )

    $displayName = (Get-Culture).TextInfo.ToTitleCase($Agent.Name)
    Write-Host '---' -ForegroundColor Yellow
    Write-Host ("Agent Name: {0}" -f $displayName) -ForegroundColor Yellow
    Write-Host ("Access Path: {0}" -f $Agent.AccessPath) -ForegroundColor Yellow
    Write-Host ("Availability: {0}" -f $Agent.Availability) -ForegroundColor Yellow
    Write-Host '---' -ForegroundColor Yellow
    $response = Read-Host ("Enable {0} for Specrew-managed delegation? (y/N)" -f $Agent.Name)
    return $response -match '^(?i)y(?:es)?$'
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

function Resolve-AgentConsent {
    param(
        [Parameter(Mandatory = $true)]
        [pscustomobject[]]$DetectedAgents,

        [Parameter(Mandatory = $true)]
        [bool]$PromptUser,

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
                Enabled         = $false
                Detected        = $agent.Detected
                DetectionSource = $agent.DetectionSource
            }
        }
    )

    if ($DisableAll) {
        return $resolvedAgents
    }

    if ($PromptUser) {
        foreach ($agent in $resolvedAgents | Where-Object { $_.Detected -and $_.Availability -eq 'available' }) {
            $agent.Enabled = Read-AgentConsent -Agent $agent
        }

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
                $lookup[$name].Enabled = $true
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

function Get-ManagedAgentsBlock {
    param(
        [Parameter(Mandatory = $true)]
        [pscustomobject[]]$Agents
    )

    $lookup = Get-AgentLookup -Agents $Agents
    $lines = @(
        '# >>> specrew-managed agents >>>',
        '# Specrew-managed agent consent and detection state (FR-022).',
        'agents:'
    )

    foreach ($name in @('copilot', 'claude', 'codex')) {
        $agent = $lookup[$name]
        $lines += "  ${name}:"
        $lines += "    enabled: $(ConvertTo-YamlBoolean -Value $agent.Enabled)"
        $lines += "    access_path: $($agent.AccessPath)"
        $lines += "    availability: $($agent.Availability)"
    }

    $lines += '# <<< specrew-managed agents <<<'
    return $lines -join [Environment]::NewLine
}

function Set-IterationConfigAgents {
    param(
        [Parameter(Mandatory = $true)]
        [string]$IterationConfigPath,

        [Parameter(Mandatory = $true)]
        [pscustomobject[]]$Agents,

        [Parameter(Mandatory = $true)]
        [System.Collections.ArrayList]$Actions,

        [Parameter(Mandatory = $true)]
        [switch]$PreviewOnly
    )

    if (-not (Test-Path -LiteralPath $IterationConfigPath)) {
        if ($PreviewOnly) {
            Add-Action -Actions $Actions -Step 'agent-config' -Outcome ("would update {0}" -f $IterationConfigPath)
            return
        }

        throw "Iteration config not found at '$IterationConfigPath'."
    }

    $content = Get-Content -LiteralPath $IterationConfigPath -Raw
    $managedBlock = Get-ManagedAgentsBlock -Agents $Agents
    $managedPattern = '(?ms)(\r?\n)?# >>> specrew-managed agents >>>.*?# <<< specrew-managed agents <<<(\r?\n)?'
    $baseContent = [regex]::Replace($content, $managedPattern, '')
    $updatedContent = $baseContent.TrimEnd()

    if ([string]::IsNullOrWhiteSpace($updatedContent)) {
        $updatedContent = $managedBlock
    }
    else {
        $updatedContent = $updatedContent + [Environment]::NewLine + [Environment]::NewLine + $managedBlock
    }

    if ($PreviewOnly) {
        Add-Action -Actions $Actions -Step 'agent-config' -Outcome ("would update {0}" -f $IterationConfigPath)
        return
    }

    [System.IO.File]::WriteAllText($IterationConfigPath, ($updatedContent + [Environment]::NewLine), [System.Text.UTF8Encoding]::new($false))
    Add-Action -Actions $Actions -Step 'agent-config' -Outcome ("updated {0}" -f $IterationConfigPath)
}

$explicitAgentsValueSpecified = $PSBoundParameters.ContainsKey('Agents')
$explicitNoAgentsSpecified = $PSBoundParameters.ContainsKey('NoAgents')
$cliArguments = @($CliArgs)

for ($cliIndex = 0; $cliIndex -lt $cliArguments.Count; $cliIndex++) {
    $cliArg = $cliArguments[$cliIndex]
    if ([string]::IsNullOrWhiteSpace($cliArg)) {
        continue
    }

    switch -Regex ($cliArg) {
        '^--dry-run$' {
            $DryRun = $true
            continue
        }
        '^--force$' {
            $Force = $true
            continue
        }
        '^--help$' {
            $Help = $true
            continue
        }
        '^--no-agents$' {
            $NoAgents = $true
            $explicitNoAgentsSpecified = $true
            continue
        }
        '^--agents=(.+)$' {
            $Agents = $Matches[1]
            $explicitAgentsValueSpecified = $true
            continue
        }
        '^--agents$' {
            if (($cliIndex + 1) -ge $cliArguments.Count -or [string]::IsNullOrWhiteSpace($cliArguments[$cliIndex + 1])) {
                Write-Error '--agents requires a value.'
                exit 3
            }

            $cliIndex++
            $Agents = $cliArguments[$cliIndex]
            $explicitAgentsValueSpecified = $true
            continue
        }
        '^--project-path=(.+)$' {
            $ProjectPath = $Matches[1]
            continue
        }
        '^--project-path$' {
            if (($cliIndex + 1) -ge $cliArguments.Count -or [string]::IsNullOrWhiteSpace($cliArguments[$cliIndex + 1])) {
                Write-Error '--project-path requires a value.'
                exit 3
            }

            $cliIndex++
            $ProjectPath = $cliArguments[$cliIndex]
            continue
        }
        '^--speckit-version=(.+)$' {
            $SpecKitVersion = $Matches[1]
            continue
        }
        '^--speckit-version$' {
            if (($cliIndex + 1) -ge $cliArguments.Count -or [string]::IsNullOrWhiteSpace($cliArguments[$cliIndex + 1])) {
                Write-Error '--speckit-version requires a value.'
                exit 3
            }

            $cliIndex++
            $SpecKitVersion = $cliArguments[$cliIndex]
            continue
        }
        '^--squad-version=(.+)$' {
            $SquadVersion = $Matches[1]
            continue
        }
        '^--squad-version$' {
            if (($cliIndex + 1) -ge $cliArguments.Count -or [string]::IsNullOrWhiteSpace($cliArguments[$cliIndex + 1])) {
                Write-Error '--squad-version requires a value.'
                exit 3
            }

            $cliIndex++
            $SquadVersion = $cliArguments[$cliIndex]
            continue
        }
        default {
            Write-Error ("Unknown option '{0}'." -f $cliArg)
            exit 3
        }
    }
}

if ($explicitAgentsValueSpecified -and $explicitNoAgentsSpecified) {
    Write-Error "Specify either --agents or --no-agents, not both."
    exit 3
}

if ($Help) {
    Show-Usage
    exit 0
}

$resolvedProjectPath = [System.IO.Path]::GetFullPath($ProjectPath)
$repoRoot = Split-Path -Parent $PSScriptRoot
$validateVersionsScript = Join-Path $repoRoot 'extensions\specrew-speckit\scripts\validate-versions.ps1'
$scaffoldGovernanceScript = Join-Path $repoRoot 'extensions\specrew-speckit\scripts\scaffold-governance.ps1'
$deploySpeckitExtensionScript = Join-Path $repoRoot 'extensions\specrew-speckit\scripts\deploy-speckit-extension.ps1'
$deploySquadRuntimeScript = Join-Path $repoRoot 'extensions\specrew-speckit\scripts\deploy-squad-runtime.ps1'
$actions = [System.Collections.ArrayList]::new()

if (-not (Test-Path -LiteralPath $resolvedProjectPath)) {
    if ($DryRun) {
        Add-Action -Actions $actions -Step 'project-path' -Outcome "would create $resolvedProjectPath"
    }
    else {
        New-Item -Path $resolvedProjectPath -ItemType Directory -Force | Out-Null
        Add-Action -Actions $actions -Step 'project-path' -Outcome "created $resolvedProjectPath"
    }
}

$existingEntries = @(Get-ChildItem -Path $resolvedProjectPath -Force -ErrorAction SilentlyContinue)
$hadSpecify = Test-Path -LiteralPath (Join-Path $resolvedProjectPath '.specify')
$hadSquad = Test-Path -LiteralPath (Join-Path $resolvedProjectPath '.squad')
$bootstrapMode = if ($hadSpecify -or $hadSquad) { 'brownfield' } else { 'greenfield' }

if ($existingEntries.Count -gt 0 -and -not $Force -and -not $hadSpecify -and -not $hadSquad) {
    Write-Error "Target directory '$resolvedProjectPath' is not empty. Re-run with -Force to allow bootstrap into a populated workspace."
    exit 3
}

Write-Step 'Validating platform dependencies'
$versionResults = @(& $validateVersionsScript -MinimumSpecKitVersion $SpecKitVersion -MinimumSquadVersion $SquadVersion -PassThru)
$missingDependencies = @($versionResults | Where-Object { -not $_.IsInstalled })
$incompatibleDependencies = @($versionResults | Where-Object { $_.IsInstalled -and -not $_.IsCompatible })

if ($incompatibleDependencies.Count -gt 0) {
    foreach ($dependency in $incompatibleDependencies) {
        Write-Error ("Specrew requires {0} >= {1} but found {2}. Run '{3}' to upgrade." -f $dependency.Platform, $dependency.MinimumVersion, $dependency.Version, $dependency.SuggestedUpgrade)
    }

    exit 1
}

foreach ($dependency in $missingDependencies) {
    Write-Step ("Installing missing dependency: {0}" -f $dependency.Platform)
    try {
        Install-MissingDependency -Dependency $dependency -PreviewOnly:$DryRun
        Add-Action -Actions $actions -Step 'dependency' -Outcome ("{0}: {1}" -f $dependency.Platform, $(if ($DryRun) { 'would install' } else { 'installed' }))
    }
    catch {
        Write-Error $_
        exit 4
    }
}

if ($missingDependencies.Count -gt 0 -and -not $DryRun) {
    $versionResults = @(& $validateVersionsScript -MinimumSpecKitVersion $SpecKitVersion -MinimumSquadVersion $SquadVersion -PassThru)
}

$specKitDetectedVersion = ($versionResults | Where-Object Platform -EQ 'Spec Kit' | Select-Object -First 1).Version
$squadDetectedVersion = ($versionResults | Where-Object Platform -EQ 'Squad' | Select-Object -First 1).Version

Write-Step 'Detecting Copilot runtime and delegated agents'
$agentDetection = Get-AgentDetection -WorkingDirectory $repoRoot
$shouldPromptForAgents = (-not $explicitAgentsValueSpecified) -and (-not $explicitNoAgentsSpecified) -and (Test-CanPrompt)
try {
    $resolvedAgents = Resolve-AgentConsent -DetectedAgents $agentDetection.Agents -PromptUser:$shouldPromptForAgents -DisableAll:$NoAgents -RequestedAgents $Agents
}
catch {
    Write-Error $_
    exit 3
}

Add-Action -Actions $actions -Step 'agent-detection' -Outcome (Format-AgentSummary -Agents $resolvedAgents)

if (-not $agentDetection.AuthContextAvailable) {
    Write-Host 'GitHub auth context is unavailable in this environment. Continuing without failing bootstrap.' -ForegroundColor Yellow
}

if (-not $agentDetection.DelegatedMetadataAvailable) {
    Write-Host 'Delegated-agent metadata is unavailable in this environment. Continuing without failing bootstrap.' -ForegroundColor Yellow
}

if (-not $hadSpecify) {
    Write-Step 'Running specify init'
    if ($DryRun) {
        Write-Host ("[dry-run] specify init --here --integration copilot --script ps --ignore-agent-tools --offline{0}" -f $(if ($Force) { ' --force' } else { '' })) -ForegroundColor Yellow
        Add-Action -Actions $actions -Step 'specify-init' -Outcome 'would initialize .specify'
    }
    else {
        $specifyArguments = @('init', '--here', '--integration', 'copilot', '--script', 'ps', '--ignore-agent-tools', '--offline')
        if ($Force) {
            $specifyArguments += '--force'
        }

        Invoke-NativeCommand -FilePath 'specify' -ArgumentList $specifyArguments -WorkingDirectory $resolvedProjectPath
        Add-Action -Actions $actions -Step 'specify-init' -Outcome 'initialized .specify'
    }
}
else {
    Add-Action -Actions $actions -Step 'specify-init' -Outcome 'preserved existing .specify'
}

if (-not $hadSquad) {
    Write-Step 'Running squad init'
    $squadInitArguments = @(Get-SquadInitArgumentList -ProbeRoot $repoRoot)
    if ($DryRun) {
        Write-Host ("[dry-run] squad {0}" -f ($squadInitArguments -join ' ')) -ForegroundColor Yellow
        Add-Action -Actions $actions -Step 'squad-init' -Outcome 'would initialize .squad'
    }
    else {
        Invoke-NativeCommand -FilePath 'squad' -ArgumentList $squadInitArguments -WorkingDirectory $resolvedProjectPath
        Add-Action -Actions $actions -Step 'squad-init' -Outcome 'initialized .squad'
    }
}
else {
    Add-Action -Actions $actions -Step 'squad-init' -Outcome 'preserved existing .squad'
}

Write-Step 'Scaffolding downstream governance'
$governanceActions = @(
    & $scaffoldGovernanceScript `
        -ProjectPath $resolvedProjectPath `
        -SpecrewVersion '0.1.0-dev' `
        -SpecKitVersion $specKitDetectedVersion `
        -SquadVersion $squadDetectedVersion `
        -BootstrapMode $bootstrapMode `
        -DryRun:$DryRun `
        -PassThru
)

foreach ($governanceAction in $governanceActions) {
    Add-Action -Actions $actions -Step 'governance' -Outcome ("{0}: {1}" -f $governanceAction.Action, $governanceAction.Path)
}

$iterationConfigPath = Join-Path $resolvedProjectPath '.specrew\iteration-config.yml'
Set-IterationConfigAgents -IterationConfigPath $iterationConfigPath -Agents $resolvedAgents -Actions $actions -PreviewOnly:$DryRun

Write-Step 'Deploying Specrew Spec Kit extension'
$specKitDeploymentActions = @(
    & $deploySpeckitExtensionScript `
        -ProjectPath $resolvedProjectPath `
        -DryRun:$DryRun `
        -PassThru
)

foreach ($deploymentAction in $specKitDeploymentActions) {
    Add-Action -Actions $actions -Step 'spec-kit-extension' -Outcome ("{0}: {1}" -f $deploymentAction.Action, $deploymentAction.Path)
}

Write-Step 'Deploying Squad runtime surfaces'
$squadDeploymentActions = @(
    & $deploySquadRuntimeScript `
        -ProjectPath $resolvedProjectPath `
        -DryRun:$DryRun `
        -PassThru
)

foreach ($deploymentAction in $squadDeploymentActions) {
    Add-Action -Actions $actions -Step 'squad-runtime' -Outcome ("{0}: {1}" -f $deploymentAction.Action, $deploymentAction.Path)
}

Write-Host ''
Write-Host 'Bootstrap summary' -ForegroundColor Green
$actions | Format-Table -AutoSize

if ($DryRun) {
    Write-Host 'Dry run complete. No files were changed.' -ForegroundColor Yellow
}
else {
    Write-Host ("Bootstrap completed for {0}." -f $resolvedProjectPath) -ForegroundColor Green
}

exit 0
