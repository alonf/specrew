[CmdletBinding(PositionalBinding = $false)]
param(
    [Alias('project-path')]
    [string]$ProjectPath = (Get-Location).Path,
    [Alias('dry-run')]
    [switch]$DryRun,
    [switch]$Force,
    [Alias('speckit-version')]
    [string]$SpecKitVersion = '0.8.4',
    [Alias('squad-version')]
    [string]$SquadVersion = '0.9.1',
    [string]$Agents = 'copilot',
    [Alias('no-agents')]
    [switch]$NoAgents,
    [Alias('spec-kit-extension-only')]
    [switch]$SpecKitExtensionOnly,
    [switch]$SkipUpdateCheck,
    [switch]$Help,
    [Parameter(ValueFromRemainingArguments = $true)]
    [string[]]$CliArgs
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

$sharedGovernancePath = Join-Path (Split-Path -Parent $PSScriptRoot) 'extensions\specrew-speckit\scripts\shared-governance.ps1'
if (-not (Test-Path -LiteralPath $sharedGovernancePath -PathType Leaf)) {
    throw "Missing shared governance helper '$sharedGovernancePath'."
}
. $sharedGovernancePath

$versionCheckHelperPath = Join-Path $PSScriptRoot 'internal\version-check.ps1'
if (-not (Test-Path -LiteralPath $versionCheckHelperPath -PathType Leaf)) {
    throw "Missing version-check helper '$versionCheckHelperPath'."
}
. $versionCheckHelperPath

$initUtilitiesPath = Join-Path $PSScriptRoot 'init\_utilities.ps1'
if (-not (Test-Path -LiteralPath $initUtilitiesPath -PathType Leaf)) {
    throw "Missing init/_utilities.ps1 helper at '$initUtilitiesPath'."
}
. $initUtilitiesPath

$initPreflightPath = Join-Path $PSScriptRoot 'init\preflight.ps1'
if (-not (Test-Path -LiteralPath $initPreflightPath -PathType Leaf)) {
    throw "Missing init/preflight.ps1 helper at '$initPreflightPath'."
}
. $initPreflightPath

$initTemplateDeployPath = Join-Path $PSScriptRoot 'init\template-deploy.ps1'
if (-not (Test-Path -LiteralPath $initTemplateDeployPath -PathType Leaf)) {
    throw "Missing init/template-deploy.ps1 helper at '$initTemplateDeployPath'."
}
. $initTemplateDeployPath

$initSpecKitDeployPath = Join-Path $PSScriptRoot 'init\spec-kit-deploy.ps1'
if (-not (Test-Path -LiteralPath $initSpecKitDeployPath -PathType Leaf)) {
    throw "Missing init/spec-kit-deploy.ps1 helper at '$initSpecKitDeployPath'."
}
. $initSpecKitDeployPath

$initDependencyInstallPath = Join-Path $PSScriptRoot 'init\dependency-install.ps1'
if (-not (Test-Path -LiteralPath $initDependencyInstallPath -PathType Leaf)) {
    throw "Missing init/dependency-install.ps1 helper at '$initDependencyInstallPath'."
}
. $initDependencyInstallPath

function Write-PostBootstrapGuidance {
    param(
        [Parameter(Mandatory = $true)]
        [string]$ProjectPath
    )

    $baselineRoles = 'Spec Steward, Planner, Implementer, Reviewer, Retro Facilitator'
    $teamPath = Join-Path $ProjectPath '.squad\team.md'
    $specrewScriptsPath = $PSScriptRoot
    $executionLayout = Get-SpecrewExecutionLayout
    $isModuleContext = ($executionLayout.Mode -eq 'module')

    Write-Host ''
    Write-Host '         ╱─────────────────╲' -ForegroundColor Cyan
    Write-Host '        ╱  ●━━●━━●          ╲' -ForegroundColor Cyan
    Write-Host '       │       ╲             │' -ForegroundColor Cyan
    Write-Host '       │   ●━━●━━●           │' -ForegroundColor Blue
    Write-Host '       │        ╲            │' -ForegroundColor Blue
    Write-Host '        ╲  ●━━●━━●          ╱' -ForegroundColor Blue
    Write-Host '         ╲─────────────────╱' -ForegroundColor Blue
    Write-Host ''
    Write-Host '         S  P  E  C  R  E  W' -ForegroundColor White
    Write-Host '    ─── GOVERNED AGENTIC SDLC ───' -ForegroundColor DarkGray
    Write-Host ''
    Write-Host '         Bootstrap Complete' -ForegroundColor Green
    Write-Host ''
    Write-Host ("Baseline Specrew crew installed: {0}." -f $baselineRoles) -ForegroundColor White
    Write-Host ''
    Write-Host '=== Usage Flow ===' -ForegroundColor Cyan
    Write-Host ''
    Write-Host 'Baseline crew → specrew start → Squad drives specify → clarify for new specs (or recorded skip on resumed clarified work) → plan → tasks → implement → review → retro' -ForegroundColor Yellow
    Write-Host ''
    Write-Host '=== Next Steps ===' -ForegroundColor Cyan
    Write-Host ''
    Write-Host '1. Start spec authoring (Spec Kit workflows):' -ForegroundColor Yellow
    Write-Host '   - Run specrew start from the project root (optionally add a short feature request)' -ForegroundColor White
    Write-Host '   - Specrew launches the selected host CLI (default: Copilot; `--host claude` or `--host codex` available since v0.26.0) from the project directory in the current terminal by default, stays out of autopilot until intake is grounded, and supports --new-window or --prompt-approvals when you want them' -ForegroundColor White
    Write-Host '   - Specrew will launch or hand off to the Squad agent with lifecycle context' -ForegroundColor White
    Write-Host '   - Squad should drive specify -> clarify -> plan -> tasks -> implement (skip clarify only for resumed clarified work with a recorded rationale)' -ForegroundColor White
    Write-Host ''
    Write-Host '2. Resuming work later:' -ForegroundColor Yellow
    Write-Host '   - Every later session also starts with specrew start from the project root' -ForegroundColor White
    Write-Host '   - specrew start regenerates the runtime handoff before launch' -ForegroundColor White
    Write-Host '   - Do not run the host CLI directly (e.g., `copilot ...` / `claude ...` / `codex ...`); going around `specrew start` skips the bootstrap refresh and leaves the launch contract stale' -ForegroundColor White
    Write-Host ''
    Write-Host '3. Run the iteration lifecycle:' -ForegroundColor Yellow
    Write-Host '   - Materialize iteration artifacts under specs/<feature>/iterations/<NNN>/' -ForegroundColor White
    Write-Host '   - Keep plan.md, state.md, drift-log.md, review.md, and retro.md current by phase' -ForegroundColor White
    Write-Host '   - Run validate-governance.ps1 before phase transitions' -ForegroundColor White
    Write-Host ''
    Write-Host 'Slash-command surface provisioned:' -ForegroundColor Green
    Write-Host '   - /specrew-where, /specrew-status, /specrew-update, /specrew-team, /specrew-review, /specrew-help, /specrew-version' -ForegroundColor White
    Write-Host '   - Deployed to .claude/skills/, .github/skills/, and .agents/skills/ with identical SKILL.md content' -ForegroundColor White
    Write-Host '   - If host-native /specrew- discovery is unavailable, use /specrew-help as the catalog fallback' -ForegroundColor White
    Write-Host ''
    Write-Host '4. (Optional) Add domain-specific team members:' -ForegroundColor Yellow
    Write-Host '   Add extra Squad members after bootstrap with Security Analyst, UX Designer,' -ForegroundColor White
    Write-Host '   DBA, or other specialists using Specrew team management commands:' -ForegroundColor White
    Write-Host ''

    if ($isModuleContext) {
        Write-Host '  specrew team add <member-name> --role <role> --charter "<charter-text>"' -ForegroundColor White
        Write-Host '  specrew start' -ForegroundColor White
        Write-Host '  specrew team list' -ForegroundColor White
        Write-Host '  specrew team update <member-name> --charter "<new-charter>"' -ForegroundColor White
        Write-Host '  specrew team remove <member-name>' -ForegroundColor White
    } else {
        Write-Host '  pwsh -File <specrew-repo>\scripts\specrew.ps1 team add <member-name> --role <role> --charter "<charter-text>"' -ForegroundColor White
        Write-Host '  pwsh -File <specrew-repo>\scripts\specrew.ps1 start' -ForegroundColor White
        Write-Host '  pwsh -File <specrew-repo>\scripts\specrew.ps1 team list' -ForegroundColor White
        Write-Host '  pwsh -File <specrew-repo>\scripts\specrew.ps1 team update <member-name> --charter "<new-charter>"' -ForegroundColor White
        Write-Host '  pwsh -File <specrew-repo>\scripts\specrew.ps1 team remove <member-name>' -ForegroundColor White
    }

    Write-Host ''
    Write-Host '   Keep the Specrew-managed baseline block intact in .squad/team.md.' -ForegroundColor Yellow
    Write-Host ''

    if (-not $isModuleContext) {
        Write-Host 'Replace <specrew-repo> with the actual path where you cloned Specrew.' -ForegroundColor Yellow
        Write-Host ''
        Write-Host '=== Optional: Add Specrew to PATH for Convenience ===' -ForegroundColor Cyan
        Write-Host ''
        Write-Host 'To use the short form (e.g., "specrew team list") instead of full paths,' -ForegroundColor White
        Write-Host 'you can add the scripts directory to your PATH.' -ForegroundColor White
        Write-Host ''

        if ($IsWindows) {
            Write-Host 'OPTION 1: Current Session Only (Windows)' -ForegroundColor Yellow
            Write-Host 'Run this command in your current PowerShell session:' -ForegroundColor White
            Write-Host ''
            Write-Host ('  $env:PATH = "$env:PATH;{0}"' -f $specrewScriptsPath) -ForegroundColor Green
            Write-Host ''
            Write-Host '(This only affects the current shell and is lost when you close it.)' -ForegroundColor DarkGray
            Write-Host ''
            Write-Host 'OPTION 2: Persistent (All Future Sessions, Windows)' -ForegroundColor Yellow
            Write-Host 'To make this permanent for your user account, run:' -ForegroundColor White
            Write-Host ''
            Write-Host ('  $currentPath = [Environment]::GetEnvironmentVariable("PATH", "User")') -ForegroundColor Green
            Write-Host ('  $pathEntries = $currentPath -split "";""') -ForegroundColor Green
            Write-Host ('  if ($pathEntries -notcontains ""{0}"") {{' -f $specrewScriptsPath) -ForegroundColor Green
            Write-Host ('      [Environment]::SetEnvironmentVariable("PATH", "$currentPath;{0}", "User")' -f $specrewScriptsPath) -ForegroundColor Green
            Write-Host ('      Write-Host "Added Specrew scripts to user PATH. Restart your shell to apply." -ForegroundColor Green') -ForegroundColor Green
            Write-Host ('  }') -ForegroundColor Green
            Write-Host ''
            Write-Host '(This adds the path to your user-level environment and persists across sessions.' -ForegroundColor DarkGray
            Write-Host ' Restart your shell after running this command.)' -ForegroundColor DarkGray
        } elseif ($IsLinux -or $IsMacOS) {
            $shellProfile = if ($IsMacOS) { '~/.zshrc or ~/.bash_profile' } else { '~/.bashrc or ~/.profile' }
            Write-Host 'Adding Specrew to PATH (Linux/macOS)' -ForegroundColor Yellow
            Write-Host ('Add this line to your shell profile ({0}):' -f $shellProfile) -ForegroundColor White
            Write-Host ''
            Write-Host ('  export PATH="$PATH:{0}"' -f $specrewScriptsPath) -ForegroundColor Green
            Write-Host ''
            Write-Host 'Then reload your shell:' -ForegroundColor White
            Write-Host ''
            Write-Host ('  source {0}' -f $shellProfile) -ForegroundColor Green
            Write-Host ''
            Write-Host 'Or restart your terminal.' -ForegroundColor DarkGray
        }

        Write-Host ''
    }

    Write-Host '============================================================' -ForegroundColor Cyan
    Write-Host ''
    Write-Host 'Documentation:' -ForegroundColor White
    Write-Host '  - Getting Started: docs/getting-started.md' -ForegroundColor DarkGray
    Write-Host '  - User Guide: docs/user-guide.md' -ForegroundColor DarkGray
    Write-Host ''
}

function Write-BootstrapSummary {
    param(
        [AllowEmptyCollection()]
        [Parameter(Mandatory = $true)]
        [System.Collections.ArrayList]$Actions,

        [Parameter(Mandatory = $true)]
        [bool]$DryRunMode,

        [Parameter(Mandatory = $true)]
        [string]$ProjectPath,

        [Parameter(Mandatory = $true)]
        [bool]$ShowGuidance
    )

    Write-Host ''
    Write-Host 'Bootstrap summary' -ForegroundColor Green
    $Actions | Format-Table -AutoSize

    if ($DryRunMode) {
        Write-Host 'Dry run complete. No files were changed.' -ForegroundColor Yellow
        return
    }

    Write-Host ("Bootstrap completed for {0}." -f $ProjectPath) -ForegroundColor Green
    if ($ShowGuidance) {
        Write-PostBootstrapGuidance -ProjectPath $ProjectPath
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
            $probeResult = Invoke-NativeCommandForOutput -FilePath 'squad' -ArgumentList @('init', '--non-interactive') -WorkingDirectory $probeDirectory
        }
        catch {
            return $false
        }

        if ($probeResult.ExitCode -ne 0) {
            return $false
        }

        return (Test-Path -LiteralPath (Join-Path $probeDirectory '.squad'))
    }
    finally {
        if (Test-Path -LiteralPath $probeDirectory) {
            Remove-Item -LiteralPath $probeDirectory -Recurse -Force -ErrorAction SilentlyContinue
        }
    }
}

function Get-SquadInitPlan {
    param(
        [Parameter(Mandatory = $true)]
        [string]$ProbeRoot
    )

    $supportsNonInteractive = Test-SquadInitSupportsNonInteractive -ProbeRoot $ProbeRoot

    $arguments = @('init')
    if ($supportsNonInteractive) {
        $arguments += '--non-interactive'
    }

    return [pscustomobject]@{
        SupportsNonInteractive = $supportsNonInteractive
        ArgumentList           = $arguments
    }
}

function Initialize-SquadFallbackScaffold {
    param(
        [Parameter(Mandatory = $true)]
        [string]$ProjectPath,

        [Parameter(Mandatory = $true)]
        [switch]$PreviewOnly
    )

    $baselineAgentDirectories = @('spec-steward', 'planner', 'implementer', 'reviewer', 'retro-facilitator')
    $directories = @(
        (Join-Path $ProjectPath '.squad'),
        (Join-Path $ProjectPath '.squad\agents'),
        (Join-Path $ProjectPath '.squad\identity'),
        (Join-Path $ProjectPath '.squad\templates')
    ) + @(
        foreach ($agentDirectory in $baselineAgentDirectories) {
            Join-Path $ProjectPath ('.squad\agents\{0}' -f $agentDirectory)
        }
    )

    foreach ($directory in $directories) {
        Ensure-DirectoryExists -Path $directory -PreviewOnly:$PreviewOnly
    }

    $files = @(
        @{
            Path    = Join-Path $ProjectPath '.squad\.first-run'
            Content = ''
        },
        @{
            Path    = Join-Path $ProjectPath '.squad\config.json'
            Content = @'
{
  "version": 1
}
'@
        },
        @{
            Path    = Join-Path $ProjectPath '.squad\team.md'
            Content = @'
# Squad Team
'@
        },
        @{
            Path    = Join-Path $ProjectPath '.squad\ceremonies.md'
            Content = @'
# Ceremonies
'@
        },
        @{
            Path    = Join-Path $ProjectPath '.squad\decisions.md'
            Content = @'
# Decisions
'@
        },
        @{
            Path    = Join-Path $ProjectPath '.squad\routing.md'
            Content = @'
# Routing
'@
        },
        @{
            Path    = Join-Path $ProjectPath '.squad\identity\now.md'
            Content = @'
---
---

# What We''re Focused On
'@
        },
        @{
            Path    = Join-Path $ProjectPath '.squad\identity\wisdom.md'
            Content = @'
# Team Wisdom
'@
        },
        @{
            Path    = Join-Path $ProjectPath '.squad\agents\spec-steward\charter.md'
            Content = @'
# Spec Steward
'@
        },
        @{
            Path    = Join-Path $ProjectPath '.squad\agents\spec-steward\history.md'
            Content = @'
# Spec Steward History
'@
        },
        @{
            Path    = Join-Path $ProjectPath '.squad\agents\planner\charter.md'
            Content = @'
# Planner
'@
        },
        @{
            Path    = Join-Path $ProjectPath '.squad\agents\planner\history.md'
            Content = @'
# Planner History
'@
        },
        @{
            Path    = Join-Path $ProjectPath '.squad\agents\implementer\charter.md'
            Content = @'
# Implementer
'@
        },
        @{
            Path    = Join-Path $ProjectPath '.squad\agents\implementer\history.md'
            Content = @'
# Implementer History
'@
        },
        @{
            Path    = Join-Path $ProjectPath '.squad\agents\reviewer\charter.md'
            Content = @'
# Reviewer
'@
        },
        @{
            Path    = Join-Path $ProjectPath '.squad\agents\reviewer\history.md'
            Content = @'
# Reviewer History
'@
        },
        @{
            Path    = Join-Path $ProjectPath '.squad\agents\retro-facilitator\charter.md'
            Content = @'
# Retro Facilitator
'@
        },
        @{
            Path    = Join-Path $ProjectPath '.squad\agents\retro-facilitator\history.md'
            Content = @'
# Retro Facilitator History
'@
        }
    )

    foreach ($file in $files) {
        Write-MissingUtf8File -Path $file.Path -Content $file.Content -PreviewOnly:$PreviewOnly
    }
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

function Get-ManagedAgentsBlock {
    param(
        [Parameter(Mandatory = $true)]
        [pscustomobject[]]$Agents
    )

    $lookup = Get-AgentLookup -Agents $Agents
    $lines = @(
        '# >>> specrew-managed agents >>>',
        '# Specrew-managed delegated-agent opt-in and detection state (FR-022).',
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

    $managedBlock = Get-ManagedAgentsBlock -Agents $Agents
    if (-not (Test-Path -LiteralPath $IterationConfigPath)) {
        if ($PreviewOnly) {
            Add-Action -Actions $Actions -Step 'agent-config' -Outcome ("would create {0}" -f $IterationConfigPath)
            return
        }

        $parent = Split-Path -Parent $IterationConfigPath
        if (-not (Test-Path -LiteralPath $parent)) {
            New-Item -ItemType Directory -Path $parent -Force | Out-Null
        }

        [System.IO.File]::WriteAllText($IterationConfigPath, ($managedBlock + [Environment]::NewLine), [System.Text.UTF8Encoding]::new($false))
        Add-Action -Actions $Actions -Step 'agent-config' -Outcome ("created {0}" -f $IterationConfigPath)
        return
    }

    $content = Get-Content -LiteralPath $IterationConfigPath -Raw
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
        '^--spec-kit-extension-only$' {
            $SpecKitExtensionOnly = $true
            continue
        }
        '^--skip-update-check$' {
            $SkipUpdateCheck = $true
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

# Pre-flight dependency check
Write-Step 'Checking required dependencies'
$preFlightCheck = Test-PreFlightDependencies -IncludeOptional

if (-not $preFlightCheck.AllOk) {
    $hasErrors = $preFlightCheck.MissingDeps.Count -gt 0 -or ($preFlightCheck.OutdatedDeps | Where-Object { $_.Tool -ne 'gh' }).Count -gt 0
    
    if ($preFlightCheck.MissingDeps.Count -gt 0) {
        Write-Host ''
        Write-Host 'Missing required dependencies:' -ForegroundColor Red
        Write-Host ''
        foreach ($dep in $preFlightCheck.MissingDeps) {
            if ($dep.Tool -eq 'gh') {
                Write-Host ("  [{0}] {1} (optional but recommended)" -f $dep.Platform, $dep.Tool) -ForegroundColor Yellow
                Write-Host ("      {0}" -f $dep.InstallHint) -ForegroundColor DarkGray
            } else {
                Write-Host ("  [{0}] {1} {2} (required: {3})" -f $dep.Platform, $dep.Tool, $dep.Current, $dep.Required) -ForegroundColor Red
                Write-Host ("      {0}" -f $dep.InstallHint) -ForegroundColor DarkGray
            }
            Write-Host ''
        }
    }
    
    if ($preFlightCheck.OutdatedDeps.Count -gt 0) {
        Write-Host ''
        Write-Host 'Outdated dependencies:' -ForegroundColor Yellow
        Write-Host ''
        foreach ($dep in $preFlightCheck.OutdatedDeps) {
            Write-Host ("  [{0}] {1} {2} (required: {3})" -f $dep.Platform, $dep.Tool, $dep.Current, $dep.Required) -ForegroundColor Yellow
            Write-Host ("      {0}" -f $dep.InstallHint) -ForegroundColor DarkGray
            Write-Host ''
        }
    }
    
    if ($hasErrors) {
        Write-Host 'Install all required dependencies before running specrew init.' -ForegroundColor Red
        exit 4
    } else {
        Write-Host 'All required dependencies are installed.' -ForegroundColor Green
    }
} else {
    Write-Host 'All required dependencies are installed.' -ForegroundColor Green
}
Write-Host ''

$resolvedProjectPath = Resolve-ProjectPath -Path $ProjectPath
$executionLayout = Get-SpecrewExecutionLayout
$repoRoot = $executionLayout.RootPath
$validateVersionsScript = Join-Path $repoRoot 'extensions\specrew-speckit\scripts\validate-versions.ps1'
$deploySpeckitExtensionScript = Join-Path $repoRoot 'extensions\specrew-speckit\scripts\deploy-speckit-extension.ps1'
$deploySquadRuntimeScript = Join-Path $repoRoot 'extensions\specrew-speckit\scripts\deploy-squad-runtime.ps1'
$scaffoldGovernanceScript = Join-Path $repoRoot 'extensions\specrew-speckit\scripts\scaffold-governance.ps1'
$specrewExtensionManifestPath = Join-Path $repoRoot 'extensions\specrew-speckit\extension.yml'
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
$blockingEntries = @($existingEntries | Where-Object { $_.Name -ne '.git' })
$hadSpecify = Test-Path -LiteralPath (Join-Path $resolvedProjectPath '.specify')
$hadSquad = Test-Path -LiteralPath (Join-Path $resolvedProjectPath '.squad')
$hadGitHub = Test-Path -LiteralPath (Join-Path $resolvedProjectPath '.github')
$hadSpecifyContent = $hadSpecify -and ((@(
            Get-ChildItem -LiteralPath (Join-Path $resolvedProjectPath '.specify') -Force -ErrorAction SilentlyContinue
        ).Count) -gt 0)
$hadSquadContent = $hadSquad -and ((@(
            Get-ChildItem -LiteralPath (Join-Path $resolvedProjectPath '.squad') -Force -ErrorAction SilentlyContinue
        ).Count) -gt 0)
$hadGitHubContent = $hadGitHub -and ((@(
            Get-ChildItem -LiteralPath (Join-Path $resolvedProjectPath '.github') -Force -ErrorAction SilentlyContinue
        ).Count) -gt 0)
$hasSpecrewConfig = Test-Path -LiteralPath (Join-Path $resolvedProjectPath '.specrew\config.yml')
$alreadyBootstrapped = $hadSpecify -and $hasSpecrewConfig
if (-not $SpecKitExtensionOnly) {
    $alreadyBootstrapped = $alreadyBootstrapped -and $hadSquad -and $hadGitHub
}
$bootstrapMode = if ($hadSpecify -or $hadSquad) { 'brownfield' } else { 'greenfield' }
$shouldInitializeSpecify = -not $hadSpecify
$shouldInitializeSquad = -not $hadSquad
$shouldForceSpecifyInit = $Force -or ($blockingEntries.Count -eq 0)
$specifySurfaceReady = $hadSpecify -or $shouldInitializeSpecify
$squadSurfaceReady = $hadSquad -or $shouldInitializeSquad

if ($blockingEntries.Count -gt 0 -and -not $Force -and -not $hadSpecify -and -not $hadSquad) {
    Write-Error "Target directory '$resolvedProjectPath' is not empty. Re-run with -Force to allow bootstrap into a populated workspace."
    exit 3
}

if ($alreadyBootstrapped -and -not $Force) {
    Write-Step 'Checking idempotent bootstrap state'
    Add-Action -Actions $actions -Step 'specify-init' -Outcome 'preserved existing .specify'
    if (-not $SpecKitExtensionOnly) {
        Add-Action -Actions $actions -Step 'squad-init' -Outcome 'preserved existing .squad'
    }
    Add-Action -Actions $actions -Step 'template-source' -Outcome ("{0}: {1}" -f $executionLayout.Mode, $executionLayout.TemplateRoot)
    Add-Action -Actions $actions -Step 'template-copy' -Outcome 'preserved existing .specify; re-run with -Force to refresh bundled templates'
    if (-not $SpecKitExtensionOnly) {
        Add-Action -Actions $actions -Step 'template-copy' -Outcome 'preserved existing .squad; re-run with -Force to refresh bundled templates'
        Add-Action -Actions $actions -Step 'template-copy' -Outcome 'preserved existing .github; re-run with -Force to refresh bundled templates'
    }

    if ($DryRun) {
        Add-Action -Actions $actions -Step 'bootstrap-validation' -Outcome 'would validate .specify templates, .squad agents, .github workflows, and .github/agents/squad.agent.md'
    }
    else {
        $bootstrapValidation = Test-BootstrappedProjectState -ProjectPath $resolvedProjectPath -SpecKitExtensionOnly:$SpecKitExtensionOnly
        if (-not $bootstrapValidation.Succeeded) {
            foreach ($failure in $bootstrapValidation.Failures) {
                Write-Error $failure -ErrorAction Continue
            }

            exit 1
        }

        Add-Action -Actions $actions -Step 'bootstrap-validation' -Outcome 'validated .specify templates, .squad agents, .github workflows, and .github/agents/squad.agent.md'
        Write-Host ("Specrew is already bootstrapped in '{0}'. Re-run with -Force to refresh bundled templates." -f $resolvedProjectPath) -ForegroundColor Yellow
    }

    Write-BootstrapSummary -Actions $actions -DryRunMode:$DryRun -ProjectPath $resolvedProjectPath -ShowGuidance:$false
    exit 0
}

if ($bootstrapMode -eq 'brownfield') {
    Write-Step 'Running brownfield merge analysis'
    $brownfieldMergeScript = Join-Path $repoRoot 'extensions\specrew-speckit\scripts\brownfield-merge.ps1'
    $brownfieldReportJson = & $brownfieldMergeScript `
        -ProjectPath $resolvedProjectPath `
        -PassThru

    if ($null -eq $brownfieldReportJson) {
        Write-Error 'Brownfield merge analysis failed to produce a report.'
        exit 5
    }

    $brownfieldReport = $brownfieldReportJson | ConvertFrom-Json

    if ($DryRun) {
        $timestamp = [datetime]::UtcNow.ToString('yyyyMMddTHHmmss')
        $dryRunArtifactPath = Join-Path $resolvedProjectPath ".specrew\bootstrap-dry-run-${timestamp}.md"
        $dryRunContent = @(
            "# Bootstrap Dry-Run Report"
            ""
            "**Generated**: $([datetime]::UtcNow.ToString('yyyy-MM-dd HH:mm:ss')) UTC"
            "**Project**: $resolvedProjectPath"
            "**Mode**: brownfield"
            "**Status**: $($brownfieldReport.Status)"
            ""
            "## Brownfield Analysis"
            ""
            "- Preserved specs: $($brownfieldReport.PreservedSpecs.Count)"
            "- Preserved roles: $($brownfieldReport.PreservedRoles.Count)"
            "- Preserved ceremonies: $($brownfieldReport.PreservedCeremonies.Count)"
            "- Role conflicts: $($brownfieldReport.RoleConflicts.Count)"
            "- Ceremony conflicts: $($brownfieldReport.CeremonyConflicts.Count)"
            "- Mergeable roles: $($brownfieldReport.MergeableRoles.Count)"
            "- Mergeable ceremonies: $($brownfieldReport.MergeableCeremonies.Count)"
            ""
        )

        if ($brownfieldReport.Conflicts.Count -gt 0) {
            $dryRunContent += "## Conflicts"
            $dryRunContent += ""
            foreach ($conflict in $brownfieldReport.Conflicts) {
                $dryRunContent += "### $($conflict.Type)"
                $dryRunContent += ""
                $dryRunContent += "**Description**: $($conflict.Description)"
                $dryRunContent += ""
                $dryRunContent += "**Resolution**: $($conflict.Resolution)"
                $dryRunContent += ""
            }
        }

        if ($brownfieldReport.Warnings.Count -gt 0) {
            $dryRunContent += "## Warnings"
            $dryRunContent += ""
            foreach ($warning in $brownfieldReport.Warnings) {
                $dryRunContent += "### $($warning.Type)"
                $dryRunContent += ""
                $dryRunContent += "**Description**: $($warning.Description)"
                $dryRunContent += ""
                $dryRunContent += "**Resolution**: $($warning.Resolution)"
                $dryRunContent += ""
            }
        }

        $dryRunContent += "## Planned Actions"
        $dryRunContent += ""
        $dryRunContent += "The following actions would be performed during actual bootstrap:"
        $dryRunContent += ""
        $dryRunContent += "1. Preserve existing specs: $($brownfieldReport.PreservedSpecs -join ', ')"
        if ($brownfieldReport.MergeableRoles.Count -gt 0) {
            $dryRunContent += "2. Merge baseline roles: $($brownfieldReport.MergeableRoles -join ', ')"
        }
        if ($brownfieldReport.MergeableCeremonies.Count -gt 0) {
            $dryRunContent += "3. Merge ceremonies: $($brownfieldReport.MergeableCeremonies -join ', ')"
        }
        $dryRunContent += ""

        $parentDir = Split-Path -Parent $dryRunArtifactPath
        if (-not (Test-Path -LiteralPath $parentDir)) {
            New-Item -ItemType Directory -Path $parentDir -Force | Out-Null
        }

        [System.IO.File]::WriteAllText($dryRunArtifactPath, ($dryRunContent -join [Environment]::NewLine), [System.Text.UTF8Encoding]::new($false))
        Write-Host "Dry-run report written to: $dryRunArtifactPath" -ForegroundColor Cyan
    }

    if ($brownfieldReport.Conflicts.Count -gt 0) {
        Write-Host 'Brownfield merge conflicts detected:' -ForegroundColor Red
        foreach ($conflict in $brownfieldReport.Conflicts) {
            Write-Host "  - [$($conflict.Type)] $($conflict.Description)" -ForegroundColor Red
            Write-Host "    Resolution: $($conflict.Resolution)" -ForegroundColor Yellow
        }
        Write-Host ''
        Write-Host 'Bootstrap cannot proceed until conflicts are resolved. Run with --dry-run to generate a detailed report, review conflicts, then manually merge or rename conflicting roles/ceremonies before re-running bootstrap.' -ForegroundColor Red
        exit 5
    }

    if ($brownfieldReport.Warnings.Count -gt 0) {
        Write-Host 'Brownfield merge warnings:' -ForegroundColor Yellow
        foreach ($warning in $brownfieldReport.Warnings) {
            Write-Host "  - [$($warning.Type)] $($warning.Description)" -ForegroundColor Yellow
            Write-Host "    Resolution: $($warning.Resolution)" -ForegroundColor Cyan
        }
        Write-Host ''
    }

    Add-Action -Actions $actions -Step 'brownfield-analysis' -Outcome ("status={0}, conflicts={1}, warnings={2}" -f $brownfieldReport.Status, $brownfieldReport.Conflicts.Count, $brownfieldReport.Warnings.Count)
}

Write-Step 'Validating platform dependencies'
$requiredPlatforms = if ($SpecKitExtensionOnly) { @('Spec Kit') } else { @('Spec Kit', 'Squad') }
$versionResults = @(
    Invoke-VersionValidation -ScriptPath $validateVersionsScript -MinimumSpecKitVersion $SpecKitVersion -MinimumSquadVersion $SquadVersion |
        Where-Object { $requiredPlatforms -contains $_.Platform }
)
$missingDependencies = @($versionResults | Where-Object { -not $_.IsInstalled })
$preInstallFailureExitCode = Resolve-DependencyValidationIssue -Results $versionResults -Actions $actions -PreviewOnly:$DryRun -IncludeMissing:$false -AfterInstallAttempt:$false
if ($preInstallFailureExitCode -ne 0 -and -not $DryRun) {
    exit $preInstallFailureExitCode
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
    $versionResults = @(
        Invoke-VersionValidation -ScriptPath $validateVersionsScript -MinimumSpecKitVersion $SpecKitVersion -MinimumSquadVersion $SquadVersion |
            Where-Object { $requiredPlatforms -contains $_.Platform }
    )
    $postInstallFailureExitCode = Resolve-DependencyValidationIssue -Results $versionResults -Actions $actions -PreviewOnly:$false -IncludeMissing:$true -AfterInstallAttempt:$true
    if ($postInstallFailureExitCode -ne 0) {
        exit $postInstallFailureExitCode
    }
}

$resolvedAgents = @()
if (-not $SpecKitExtensionOnly) {
Write-Step 'Detecting Copilot runtime and delegated agents'
    $agentDetection = Get-AgentDetection -WorkingDirectory $repoRoot
    try {
        $resolvedAgents = Resolve-AgentSelection -DetectedAgents $agentDetection.Agents -DisableAll:$NoAgents -RequestedAgents $Agents
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
}

if ($shouldInitializeSpecify) {
    Write-Step 'Running specify init'
    if ($DryRun) {
        Write-Host ("[dry-run] specify init --here --ai copilot --script ps --ignore-agent-tools{0}" -f $(if ($shouldForceSpecifyInit) { ' --force' } else { '' })) -ForegroundColor Yellow
        Add-Action -Actions $actions -Step 'specify-init' -Outcome 'would initialize .specify'
    }
    else {
        $specifyArguments = @('init', '--here', '--ai', 'copilot', '--script', 'ps', '--ignore-agent-tools')
        if ($shouldForceSpecifyInit) {
            $specifyArguments += '--force'
        }

        Write-Step 'Preflighting specify init'
        $specifyPreflight = Test-SpecifyInitPreflight -ProjectPath $resolvedProjectPath -ArgumentList $specifyArguments -SpecKitVersion $SpecKitVersion
        if (-not $specifyPreflight.Ready) {
            Write-Error $specifyPreflight.FailureMessage
            exit 1
        }

        if ($specifyPreflight.Repaired) {
            Add-Action -Actions $actions -Step 'dependency' -Outcome ("Spec Kit: {0}" -f $specifyPreflight.RepairOutcome)
        }

        $specifyInitResult = Invoke-NativeCommandForOutput -FilePath 'specify' -ArgumentList $specifyArguments -WorkingDirectory $resolvedProjectPath
        if ($specifyInitResult.ExitCode -ne 0) {
            $failureSummary = Get-FirstNonEmptyOutputLine -OutputLines $specifyInitResult.Output
            if ($failureSummary) {
                Write-Error ("specify init failed after preflight: {0}" -f $failureSummary)
            }
            else {
                Write-Error 'specify init failed after preflight with no diagnostic output.'
            }

            exit 1
        }

        Add-Action -Actions $actions -Step 'specify-init' -Outcome 'initialized .specify'
    }
}
else {
    if ($hadSpecify) {
        Add-Action -Actions $actions -Step 'specify-init' -Outcome 'preserved existing .specify'
    }
    else {
        Add-Action -Actions $actions -Step 'specify-init' -Outcome 'skipped: brownfield bootstrap does not initialize missing .specify'
    }
}

if (-not $SpecKitExtensionOnly -and $shouldInitializeSquad) {
    Write-Step 'Running squad init'
    $squadInitPlan = Get-SquadInitPlan -ProbeRoot $repoRoot
    if ($squadInitPlan.SupportsNonInteractive) {
        if ($DryRun) {
            Write-Host ("[dry-run] squad {0}" -f ($squadInitPlan.ArgumentList -join ' ')) -ForegroundColor Yellow
            Add-Action -Actions $actions -Step 'squad-init' -Outcome 'would initialize .squad via squad init --non-interactive'
        }
        else {
            Invoke-NativeCommand -FilePath 'squad' -ArgumentList $squadInitPlan.ArgumentList -WorkingDirectory $resolvedProjectPath
            Add-Action -Actions $actions -Step 'squad-init' -Outcome 'initialized .squad via squad init --non-interactive'
        }
    }
    else {
        Write-Step 'Scaffolding .squad fallback'
        Write-Host '[info] squad init --non-interactive is unavailable; using direct .squad scaffold fallback.' -ForegroundColor Yellow
        Initialize-SquadFallbackScaffold -ProjectPath $resolvedProjectPath -PreviewOnly:$DryRun
        Add-Action -Actions $actions -Step 'squad-init' -Outcome ($(if ($DryRun) { 'would initialize .squad via fallback scaffold' } else { 'initialized .squad via fallback scaffold' }))
    }
}
else {
    if (-not $SpecKitExtensionOnly -and $hadSquad) {
        Add-Action -Actions $actions -Step 'squad-init' -Outcome 'preserved existing .squad'
    }
    elseif (-not $SpecKitExtensionOnly) {
        Add-Action -Actions $actions -Step 'squad-init' -Outcome 'skipped: brownfield bootstrap does not initialize missing .squad'
    }
}

Write-Step 'Deploying Specrew Spec Kit extension'
if ($specifySurfaceReady) {
    $specKitDeploymentResult = Invoke-SpecKitExtensionDeployment `
        -ProjectPath $resolvedProjectPath `
        -RepoRoot $repoRoot `
        -FallbackScriptPath $deploySpeckitExtensionScript `
        -PreviewOnly:$DryRun

    $specKitDeploymentAction = if ($null -ne $specKitDeploymentResult -and $specKitDeploymentResult.PSObject.Properties['Action']) {
        [string]$specKitDeploymentResult.Action
    }
    else {
        if ($DryRun) { 'would-install' } else { 'installed' }
    }

    $specKitDeploymentPath = if ($null -ne $specKitDeploymentResult -and $specKitDeploymentResult.PSObject.Properties['Path']) {
        [string]$specKitDeploymentResult.Path
    }
    else {
        Join-Path $resolvedProjectPath '.specify\extensions\specrew-speckit'
    }

    Add-Action -Actions $actions -Step 'spec-kit-extension' -Outcome ("{0}: {1}" -f $specKitDeploymentAction, $specKitDeploymentPath)
}
else {
    Add-Action -Actions $actions -Step 'spec-kit-extension' -Outcome 'skipped: .specify is absent in brownfield workspace'
}

Write-Step 'Deploying bundled project templates'
Invoke-BundledTemplateDeployment `
    -ExecutionLayout $executionLayout `
    -ProjectPath $resolvedProjectPath `
    -ForceRefresh:$Force `
    -SpecKitReady:$specifySurfaceReady `
    -SquadReady:$squadSurfaceReady `
    -HadSpecify:$hadSpecifyContent `
    -HadSquad:$hadSquadContent `
    -HadGitHub:$hadGitHubContent `
    -SpecKitExtensionOnly:$SpecKitExtensionOnly `
    -Actions $actions `
    -PreviewOnly:$DryRun

if (-not $SpecKitExtensionOnly) {
    $resolvedSpecKitVersion = (($versionResults | Where-Object { $_.Platform -eq 'Spec Kit' } | Select-Object -First 1).Version)
    if ([string]::IsNullOrWhiteSpace($resolvedSpecKitVersion)) {
        $resolvedSpecKitVersion = $SpecKitVersion
    }

    $resolvedSquadVersion = (($versionResults | Where-Object { $_.Platform -eq 'Squad' } | Select-Object -First 1).Version)
    if ([string]::IsNullOrWhiteSpace($resolvedSquadVersion)) {
        $resolvedSquadVersion = $SquadVersion
    }

    $specrewManifestContent = Get-Content -LiteralPath $specrewExtensionManifestPath -Raw
    $specrewVersionMatch = [regex]::Match($specrewManifestContent, '(?m)^\s*version:\s*"?(?<version>[^"\r\n]+)')
    $resolvedSpecrewVersion = if ($specrewVersionMatch.Success) { $specrewVersionMatch.Groups['version'].Value.Trim() } else { '0.1.0-dev' }

    Write-Step 'Scaffolding downstream governance'
    $governanceActions = @(
        & $scaffoldGovernanceScript `
            -ProjectPath $resolvedProjectPath `
            -SpecrewVersion $resolvedSpecrewVersion `
            -SpecKitVersion $resolvedSpecKitVersion `
            -SquadVersion $resolvedSquadVersion `
            -BootstrapMode $bootstrapMode `
            -DryRun:$DryRun `
            -PassThru
    )

    foreach ($governanceAction in $governanceActions) {
        Add-Action -Actions $actions -Step 'governance-scaffold' -Outcome ("{0}: {1}" -f $governanceAction.Action, $governanceAction.Path)
    }

    Write-Step 'Deploying Squad runtime'
    $iterationConfigPath = Join-Path $resolvedProjectPath '.specrew\iteration-config.yml'
    Set-IterationConfigAgents -IterationConfigPath $iterationConfigPath -Agents $resolvedAgents -Actions $actions -PreviewOnly:$DryRun

    if ($squadSurfaceReady) {
        $squadDeploymentActions = @(
            & $deploySquadRuntimeScript `
                -ProjectPath $resolvedProjectPath `
                -DryRun:$DryRun `
                -PassThru
        )

        foreach ($deploymentAction in $squadDeploymentActions) {
            Add-Action -Actions $actions -Step 'squad-runtime' -Outcome ("{0}: {1}" -f $deploymentAction.Action, $deploymentAction.Path)
        }

        Add-Action -Actions $actions -Step 'slash-surface' -Outcome 'provisioned /specrew-where, /specrew-status, /specrew-update, /specrew-team, /specrew-review, /specrew-help, /specrew-version across .claude/skills, .github/skills, and .agents/skills'
    }
    else {
        Add-Action -Actions $actions -Step 'squad-runtime' -Outcome 'skipped: .squad is absent in brownfield workspace'
    }
}

Write-Step 'Configuring git for boundary-commit hygiene'
# F-040 dogfooding fix (calc-v2 + tip-calc 2026-05-23): when the project is in a git repo,
# silence the LF/CRLF warning wall that otherwise dumps 150+ lines on the user during
# `git add` for the very first boundary commit. Use `core.safecrlf=false` (warnings off) +
# `core.autocrlf=true` on Windows / `input` on POSIX (right normalization). Both are scoped
# to THIS repo only via `git config --local`, so we don't touch the user's global config.
$gitRepoCheck = Test-Path -LiteralPath (Join-Path $resolvedProjectPath '.git') -PathType Container
if ($gitRepoCheck -and -not $DryRun) {
    try {
        & git -C $resolvedProjectPath config --local core.safecrlf false 2>$null
        $global:LASTEXITCODE = 0
        $autocrlfValue = if ($IsWindows -or $env:OS -eq 'Windows_NT') { 'true' } else { 'input' }
        & git -C $resolvedProjectPath config --local core.autocrlf $autocrlfValue 2>$null
        $global:LASTEXITCODE = 0
        Add-Action -Actions $actions -Step 'git-config' -Outcome ("set local core.safecrlf=false + core.autocrlf={0} to suppress harmless CRLF warnings on first commit" -f $autocrlfValue)
    }
    catch {
        Add-Action -Actions $actions -Step 'git-config' -Outcome ("skipped (git config failed: {0})" -f $_.Exception.Message)
    }
}
elseif ($gitRepoCheck -and $DryRun) {
    Add-Action -Actions $actions -Step 'git-config' -Outcome 'would set local core.safecrlf + core.autocrlf to suppress CRLF warnings'
}
else {
    Add-Action -Actions $actions -Step 'git-config' -Outcome 'skipped (no .git directory found; this is not a git repo yet)'
}

Write-Step 'Validating bootstrapped project state'
if ($DryRun) {
    Add-Action -Actions $actions -Step 'bootstrap-validation' -Outcome 'would validate .specify templates, .squad agents, .github workflows, and .github/agents/squad.agent.md'
}
else {
    $bootstrapValidation = Test-BootstrappedProjectState -ProjectPath $resolvedProjectPath -SpecKitExtensionOnly:$SpecKitExtensionOnly
    if (-not $bootstrapValidation.Succeeded) {
        foreach ($failure in $bootstrapValidation.Failures) {
            Write-Error $failure -ErrorAction Continue
        }

        exit 1
    }

    Add-Action -Actions $actions -Step 'bootstrap-validation' -Outcome 'validated .specify templates, .squad agents, .github workflows, and .github/agents/squad.agent.md'
}

Write-BootstrapSummary -Actions $actions -DryRunMode:$DryRun -ProjectPath $resolvedProjectPath -ShowGuidance:(-not $SpecKitExtensionOnly -and $squadSurfaceReady)

if (-not $DryRun) {
    $psGalleryUpdateWarning = Get-PSGalleryUpdateWarning -ProjectRoot $resolvedProjectPath -SkipCheck:$SkipUpdateCheck
    if (-not [string]::IsNullOrWhiteSpace($psGalleryUpdateWarning)) {
        Write-Output ("WARN: {0}" -f $psGalleryUpdateWarning)
    }
}

exit 0
