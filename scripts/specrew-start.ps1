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

    [Parameter(Mandatory = $false)]
    [string]$HostKind = '',

    [Parameter(Mandatory = $false)]
    [string]$PostRestartDirective = '',

    [switch]$NoLaunch,
    [switch]$NewWindow,
    [switch]$SameWindow,
    [switch]$AllowAll,
    [switch]$PromptApprovals,
    [switch]$Autonomous,
    [switch]$BypassBoundaryEnforcement,
    [string]$Reason,
    [switch]$Recover,
    [string]$RecoveryChoice,
    [switch]$SkipUpdateCheck,
    [switch]$Help,

    [Parameter(ValueFromRemainingArguments = $true)]
    [string[]]$CliArgs
)

$sharedGovernancePath = Join-Path (Split-Path -Parent $PSScriptRoot) 'extensions\specrew-speckit\scripts\shared-governance.ps1'
if (-not (Test-Path -LiteralPath $sharedGovernancePath -PathType Leaf)) {
    throw "Missing shared governance helper '$sharedGovernancePath'."
}
. $sharedGovernancePath

$copilotInstructionsClassifierPath = Join-Path (Split-Path -Parent $PSScriptRoot) 'extensions\specrew-speckit\scripts\Test-CopilotInstructionsChangeType.ps1'
if (-not (Test-Path -LiteralPath $copilotInstructionsClassifierPath -PathType Leaf)) {
    throw "Missing copilot-instructions classifier helper '$copilotInstructionsClassifierPath'."
}
. $copilotInstructionsClassifierPath

$boundaryStateHelperPath = Join-Path $PSScriptRoot 'internal\sync-boundary-state.ps1'
if (-not (Test-Path -LiteralPath $boundaryStateHelperPath -PathType Leaf)) {
    throw "Missing boundary-state helper '$boundaryStateHelperPath'."
}
. $boundaryStateHelperPath

$taskProgressHelperPath = Join-Path $PSScriptRoot 'internal\task-progress.ps1'
if (-not (Test-Path -LiteralPath $taskProgressHelperPath -PathType Leaf)) {
    throw "Missing task-progress helper '$taskProgressHelperPath'."
}
. $taskProgressHelperPath

$worktreeHelperPath = Join-Path $PSScriptRoot 'internal\worktree-awareness.ps1'
if (-not (Test-Path -LiteralPath $worktreeHelperPath -PathType Leaf)) {
    throw "Missing worktree-awareness helper '$worktreeHelperPath'."
}
. $worktreeHelperPath

$coordinatorResumeHelperPath = Join-Path $PSScriptRoot 'internal\coordinator-resume.ps1'
if (-not (Test-Path -LiteralPath $coordinatorResumeHelperPath -PathType Leaf)) {
    throw "Missing coordinator-resume helper '$coordinatorResumeHelperPath'."
}
. $coordinatorResumeHelperPath

$versionCheckHelperPath = Join-Path $PSScriptRoot 'internal\version-check.ps1'
if (-not (Test-Path -LiteralPath $versionCheckHelperPath -PathType Leaf)) {
    throw "Missing version-check helper '$versionCheckHelperPath'."
}
. $versionCheckHelperPath

$detectHostsHelperPath = Join-Path $PSScriptRoot 'internal\detect-hosts.ps1'
if (-not (Test-Path -LiteralPath $detectHostsHelperPath -PathType Leaf)) {
    throw "Missing detect-hosts helper '$detectHostsHelperPath'."
}
. $detectHostsHelperPath

$skillCatalogStateHelperPath = Join-Path $PSScriptRoot 'internal\skill-catalog-state.ps1'
if (-not (Test-Path -LiteralPath $skillCatalogStateHelperPath -PathType Leaf)) {
    throw "Missing skill-catalog state helper '$skillCatalogStateHelperPath'."
}
. $skillCatalogStateHelperPath

$hostFlagTranslationHelperPath = Join-Path $PSScriptRoot 'internal\host-flag-translation.ps1'
if (-not (Test-Path -LiteralPath $hostFlagTranslationHelperPath -PathType Leaf)) {
    throw "Missing host-flag-translation helper '$hostFlagTranslationHelperPath'."
}
. $hostFlagTranslationHelperPath

$coordinatorPromptSurgeryHelperPath = Join-Path $PSScriptRoot 'internal\coordinator-prompt-surgery.ps1'
if (-not (Test-Path -LiteralPath $coordinatorPromptSurgeryHelperPath -PathType Leaf)) {
    throw "Missing coordinator-prompt-surgery helper '$coordinatorPromptSurgeryHelperPath'."
}
. $coordinatorPromptSurgeryHelperPath

$userProfileHelperPath = Join-Path $PSScriptRoot 'internal\user-profile.ps1'
if (-not (Test-Path -LiteralPath $userProfileHelperPath -PathType Leaf)) {
    throw "Missing user-profile helper '$userProfileHelperPath'."
}
. $userProfileHelperPath

$sessionManagementHelperPath = Join-Path $PSScriptRoot 'internal\session-management.ps1'
if (-not (Test-Path -LiteralPath $sessionManagementHelperPath -PathType Leaf)) {
    throw "Missing session-management helper '$sessionManagementHelperPath'."
}
. $sessionManagementHelperPath

$featureClaimsHelperPath = Join-Path $PSScriptRoot 'internal\feature-claims.ps1'
if (-not (Test-Path -LiteralPath $featureClaimsHelperPath -PathType Leaf)) {
    throw "Missing feature-claims helper '$featureClaimsHelperPath'."
}
. $featureClaimsHelperPath

$autoDetectionHelperPath = Join-Path $PSScriptRoot 'auto-detection.ps1'
if (-not (Test-Path -LiteralPath $autoDetectionHelperPath -PathType Leaf)) {
    throw "Missing auto-detection helper '$autoDetectionHelperPath'."
}
. $autoDetectionHelperPath

function Convert-UnixStyleArguments {
    param(
        [string]$FeatureRequest,
        [string]$ProjectPath,
        [string]$ResumeFeature,
        [string]$Agent,
        [string]$HostKind,
        [string]$PostRestartDirective,
        [bool]$NoLaunch,
        [bool]$NewWindow,
        [bool]$SameWindow,
        [bool]$AllowAll,
        [bool]$PromptApprovals,
        [bool]$BypassBoundaryEnforcement,
        [AllowNull()][string]$Reason,
        [bool]$Recover,
        [AllowNull()][string]$RecoveryChoice,
        [bool]$SkipUpdateCheck,
        [bool]$Help,
        [string[]]$CliArgs
    )

    $result = [ordered]@{
        FeatureRequest = $FeatureRequest
        ProjectPath    = $ProjectPath
        ResumeFeature  = $ResumeFeature
        Agent          = $Agent
        HostKind       = $HostKind
        PostRestartDirective = $PostRestartDirective
        NoLaunch       = $NoLaunch
        NewWindow      = $false
        SameWindow     = $false
        AllowAll       = $AllowAll
        PromptApprovals = $PromptApprovals
        Autonomous     = $Autonomous
        BypassBoundaryEnforcement = $BypassBoundaryEnforcement
        Reason         = $Reason
        Recover        = $Recover
        RecoveryChoice = $RecoveryChoice
        SkipUpdateCheck = $SkipUpdateCheck
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
            '--host' {
                $i++
                if ($i -lt $CliArgs.Count) { $result.HostKind = $CliArgs[$i] }
            }
            '--post-restart-directive' {
                $i++
                if ($i -lt $CliArgs.Count) { $result.PostRestartDirective = $CliArgs[$i] }
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
            '--autonomous' {
                $result.Autonomous = $true
            }
            '--bypass-boundary-enforcement' {
                $result.BypassBoundaryEnforcement = $true
            }
            '--reason' {
                $i++
                if ($i -lt $CliArgs.Count) { $result.Reason = $CliArgs[$i] }
            }
            '--recover' {
                $result.Recover = $true
            }
            '--recovery-choice' {
                $i++
                if ($i -lt $CliArgs.Count) { $result.RecoveryChoice = $CliArgs[$i].ToUpperInvariant() }
            }
            '--skip-update-check' {
                $result.SkipUpdateCheck = $true
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
    -HostKind $HostKind `
    -PostRestartDirective $PostRestartDirective `
    -NoLaunch $NoLaunch.IsPresent `
    -NewWindow $NewWindow.IsPresent `
    -SameWindow $SameWindow.IsPresent `
    -AllowAll $AllowAll.IsPresent `
    -PromptApprovals $PromptApprovals.IsPresent `
    -BypassBoundaryEnforcement $BypassBoundaryEnforcement.IsPresent `
    -Reason $Reason `
    -Recover $Recover.IsPresent `
    -RecoveryChoice $RecoveryChoice `
    -SkipUpdateCheck $SkipUpdateCheck.IsPresent `
    -Help $Help.IsPresent `
    -CliArgs $CliArgs

$FeatureRequest = $parsedArgs.FeatureRequest
$ProjectPath = $parsedArgs.ProjectPath
$ResumeFeature = $parsedArgs.ResumeFeature
$Agent = $parsedArgs.Agent
$HostKind = $parsedArgs.HostKind
$PostRestartDirective = $parsedArgs.PostRestartDirective
$NoLaunch = [bool]$parsedArgs.NoLaunch
$NewWindow = [bool]$parsedArgs.NewWindow
$SameWindow = [bool]$parsedArgs.SameWindow
$AllowAll = [bool]$parsedArgs.AllowAll
$PromptApprovals = [bool]$parsedArgs.PromptApprovals
$Autonomous = [bool]$parsedArgs.Autonomous
$BypassBoundaryEnforcement = [bool]$parsedArgs.BypassBoundaryEnforcement
$Reason = [string]$parsedArgs.Reason
$Recover = [bool]$parsedArgs.Recover
$RecoveryChoice = [string]$parsedArgs.RecoveryChoice
$SkipUpdateCheck = [bool]$parsedArgs.SkipUpdateCheck
$Help = [bool]$parsedArgs.Help

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

function Show-Usage {
    @'
specrew start - Start or resume the Crew-driven Spec Kit lifecycle

Usage:
  specrew start
  specrew start "Build a reporting dashboard"
  specrew start --feature-request "Add SSO login"
  specrew start --resume-feature auto
  specrew start --host claude "Build a TODO app"
  specrew start --host codex --resume-feature auto

Options:
  -ProjectPath | --project-path <path>     Target project directory (defaults to current directory)
  -ResumeFeature | --resume-feature <path|auto>
                                           Resume an existing feature directory, or use "auto"
  -Agent | --agent <name>                  Crew runtime agent label (default: Squad — required by Copilot host's --agent flag; non-Squad hosts ignore this since they don't have a host-side --agent surface)
  -HostKind | --host <copilot|claude|codex>
                                           Select the agent host runtime (default: copilot). 'antigravity' and
                                           'auto' are reserved but rejected with deferred-guidance pointing to
                                           Proposal 069 follow-up / Proposal 104 respectively.
  -NoLaunch | --no-launch                  Generate handoff prompt/context but do not launch the host CLI
  -NewWindow | --new-window                Launch the host CLI in a new PowerShell window instead of the current terminal
  -SameWindow | --same-window              Compatibility alias for the default current-terminal launch mode
  -AllowAll | --allow-all                  Launch the host with its tool-approval-bypass flag (Copilot --allow-all, Claude --dangerously-skip-permissions, Codex --dangerously-bypass-approvals-and-sandbox). Default for tool calls; does not bypass lifecycle boundary approval.
  -PromptApprovals | --prompt-approvals    Keep the host's interactive tool-approval prompts enabled (disables --allow-all translation)
  -Autonomous | --autonomous               Specrew-side flag (independent of any host autopilot): the Crew advances through lifecycle gates without stopping for explicit approval. Use for unattended runs such as overnight execution; default is gate-respecting mode where the Crew stops at every approval boundary.
  --bypass-boundary-enforcement            Suspend boundary enforcement for this session only; requires --reason
  --reason "<text>"                        Required justification for --bypass-boundary-enforcement
  -Recover | --recover                     Bypass stale-state blocking and enter recovery mode directly
  -SkipUpdateCheck | --skip-update-check   Skip the PSGallery latest-version check for this run
  -Help | --help                           Show this help message

 Notes:
    - Running specrew start with no arguments launches Squad in intake/resume mode.
    - Squad should continue any in-progress feature when possible, or gather the missing feature/fix details from the human developer.
    - A quoted feature request is optional shorthand for a new feature, not a full spec document.
     - Specrew launches the selected host CLI (--host copilot|claude|codex, default copilot) from the target project directory, reuses the current terminal by default, and only uses --new-window when you explicitly ask for a detached shell.
     - Specrew auto-loads the bootstrap so the host reads the Crew handoff at `.specrew/last-start-prompt.md` and `.specrew/start-context.json` before doing anything else.
     - The default behavior is gate-respecting: the Crew stops at every lifecycle approval boundary (specify, clarify, plan, tasks, before-implement, review-signoff, retro, iteration-closeout, feature-closeout) and waits for explicit human verdict. Pass --autonomous to advance through gates without stopping (unattended runs).
     - --allow-all (default) and --autonomous are independent: --allow-all controls tool-call approval only (translated per host) and does not bypass lifecycle boundary approval; --autonomous controls whether the Crew advances through lifecycle gates without input. Intake stage stays interactive regardless of --autonomous so initial scope is never auto-resolved.
     - The selected host may still ask you to trust the project directory on first launch.
     - If the selected host CLI is unavailable, Specrew still writes a handoff prompt and context file.
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

function Read-SpecrewYesNo {
    param(
        [Parameter(Mandatory = $true)]
        [string]$Prompt,

        [bool]$Default = $false
    )

    if ([Console]::IsInputRedirected) {
        $redirectedResponse = [Console]::In.ReadLine()
        if ([string]::IsNullOrWhiteSpace($redirectedResponse)) {
            return $Default
        }

        return ($redirectedResponse.Trim().ToLowerInvariant() -in @('y', 'yes'))
    }

    while ($true) {
        $response = Read-Host $Prompt
        if ([string]::IsNullOrWhiteSpace($response)) {
            return $Default
        }

        switch ($response.Trim().ToLowerInvariant()) {
            { $_ -in @('y', 'yes') } { return $true }
            { $_ -in @('n', 'no') } { return $false }
            default { Write-Info "Enter y/yes or n/no." }
        }
    }
}

function Invoke-SpecrewStartMultiSessionGuard {
    param(
        [Parameter(Mandatory = $true)]
        [string]$ProjectRoot,

        [AllowNull()]
        [string]$ResolvedFeaturePath
    )

    if ([string]::IsNullOrWhiteSpace($ResolvedFeaturePath)) {
        return
    }

    $featureId = Split-Path -Leaf $ResolvedFeaturePath
    if ([string]::IsNullOrWhiteSpace($featureId)) {
        return
    }

    $fingerprint = Get-MachineFingerprint
    $identity = Get-SpecrewCoarseIdentity

    $cleared = Clear-StaleSessionLocks -ProjectRoot $ProjectRoot -ThresholdHours 24
    if ($cleared -gt 0) {
        Write-Info ("Cleared {0} stale active session lock(s)." -f $cleared)
    }

    $sessionCollision = Test-SessionCollision -ProjectRoot $ProjectRoot -FeatureId $featureId -Fingerprint $fingerprint
    if ($null -ne $sessionCollision) {
        $holder = ('{0}@{1}' -f $sessionCollision['user'], $sessionCollision['machine_fingerprint'])
        Write-Info ("WARN: Another active session detected for feature {0} (started by {1} at {2})." -f $featureId, $holder, $sessionCollision['session_start_time'])
    }

    $claimConflict = Test-FeatureClaimConflict -ProjectRoot $ProjectRoot -FeatureId $featureId -ClaimedBy $identity
    if ($null -ne $claimConflict) {
        Write-Info ("WARN: Feature {0} is already claimed by {1} on branch {2} (last refresh {3})." -f $featureId, $claimConflict['claimed_by'], $claimConflict['branch_name'], $claimConflict['last_refresh_time'])
        $continue = Read-SpecrewYesNo -Prompt 'Continue anyway? [y/N]' -Default $false
        if (-not $continue) {
            Write-Info 'Start declined; no active session lock was recorded.'
            exit 2
        }
    }

    Register-SessionLock -ProjectRoot $ProjectRoot -FeatureId $featureId -User ([System.Environment]::UserName) -Fingerprint $fingerprint

    $recommendation = Get-SpecrewMultiDeveloperRecommendation -ProjectRoot $ProjectRoot
    if (-not [string]::IsNullOrWhiteSpace($recommendation)) {
        Write-Info $recommendation
    }
}

function Get-SpecrewConfigValue {
    param(
        [Parameter(Mandatory = $true)]
        [string]$ProjectRoot,

        [Parameter(Mandatory = $true)]
        [string]$Key
    )

    $configPath = Join-Path $ProjectRoot '.specrew\config.yml'
    if (-not (Test-Path -LiteralPath $configPath -PathType Leaf)) {
        return $null
    }

    foreach ($line in Get-Content -LiteralPath $configPath -Encoding UTF8) {
        if ($line -match ('^\s*{0}:\s*"?(?<value>[^"#]+?)"?\s*$' -f [regex]::Escape($Key))) {
            return $Matches['value'].Trim()
        }
    }

    return $null
}

function Get-InstalledSpecrewVersion {
    param([Parameter(Mandatory = $true)][string]$ProjectRoot)

    $module = @(Get-Module -Name Specrew -ListAvailable | Sort-Object Version -Descending | Select-Object -First 1)
    if ($module.Count -gt 0 -and $module[0].Version) {
        return $module[0].Version.ToString()
    }

    $manifestCandidates = @(
        (Join-Path (Split-Path -Parent $PSScriptRoot) 'Specrew.psd1'),
        (Join-Path $ProjectRoot 'Specrew.psd1')
    ) | Select-Object -Unique

    foreach ($manifestPath in $manifestCandidates) {
        if (Test-Path -LiteralPath $manifestPath -PathType Leaf) {
            try {
                $manifest = Import-PowerShellDataFile -LiteralPath $manifestPath
                if ($manifest.ContainsKey('ModuleVersion')) {
                    return [string]$manifest.ModuleVersion
                }
            }
            catch {
            }
        }
    }

    return $null
}

function Get-ManifestSpecrewVersionText {
    param([Parameter(Mandatory = $true)][System.Collections.IDictionary]$Manifest)

    if (-not $Manifest.ContainsKey('ModuleVersion') -or [string]::IsNullOrWhiteSpace([string]$Manifest.ModuleVersion)) {
        return $null
    }

    $version = [string]$Manifest.ModuleVersion
    $prerelease = ''
    if ($Manifest.ContainsKey('PrivateData') -and
        $null -ne $Manifest.PrivateData -and
        $Manifest.PrivateData.ContainsKey('PSData') -and
        $null -ne $Manifest.PrivateData.PSData -and
        $Manifest.PrivateData.PSData.ContainsKey('Prerelease') -and
        $null -ne $Manifest.PrivateData.PSData.Prerelease) {
        $prerelease = [string]$Manifest.PrivateData.PSData.Prerelease
    }

    if ([string]::IsNullOrWhiteSpace($prerelease)) {
        return $version
    }

    return ('{0}-{1}' -f $version, $prerelease.Trim())
}

function Get-InstalledSpecrewRuntimeVersion {
    param([Parameter(Mandatory = $true)][string]$ProjectRoot)

    $manifestCandidates = @(
        (Join-Path (Split-Path -Parent $PSScriptRoot) 'Specrew.psd1'),
        (Join-Path $ProjectRoot 'Specrew.psd1')
    ) | Select-Object -Unique

    foreach ($manifestPath in $manifestCandidates) {
        if (Test-Path -LiteralPath $manifestPath -PathType Leaf) {
            try {
                $manifest = Import-PowerShellDataFile -LiteralPath $manifestPath
                $versionText = Get-ManifestSpecrewVersionText -Manifest $manifest
                if (-not [string]::IsNullOrWhiteSpace($versionText)) {
                    return $versionText
                }
            }
            catch {
            }
        }
    }

    $module = @(Get-Module -Name Specrew -ListAvailable -ErrorAction SilentlyContinue | Sort-Object Version -Descending | Select-Object -First 1)
    if ($module.Count -gt 0) {
        $moduleVersion = if ($module[0].Version) { $module[0].Version.ToString() } else { '' }
        $modulePrerelease = ''
        if ($module[0].PrivateData -and $module[0].PrivateData.PSData -and $module[0].PrivateData.PSData.Prerelease) {
            $modulePrerelease = [string]$module[0].PrivateData.PSData.Prerelease
        }

        if (-not [string]::IsNullOrWhiteSpace($moduleVersion)) {
            if (-not [string]::IsNullOrWhiteSpace($modulePrerelease)) {
                return ('{0}-{1}' -f $moduleVersion, $modulePrerelease.Trim())
            }

            return $moduleVersion
        }
    }

    return $null
}

function Get-SpecrewRuntimeClassForStatus {
    param([AllowNull()][string]$CrewRuntimeStatus)

    if ([string]$CrewRuntimeStatus -eq 'squad-runtime') {
        return 'Squad'
    }

    return 'non-Squad'
}

function Get-SpecrewVersionMismatchWarning {
    param([Parameter(Mandatory = $true)][string]$ProjectRoot)

    $projectVersion = Get-SpecrewConfigValue -ProjectRoot $ProjectRoot -Key 'specrew_version'
    $installedVersion = Get-InstalledSpecrewVersion -ProjectRoot $ProjectRoot
    if ([string]::IsNullOrWhiteSpace($projectVersion) -or [string]::IsNullOrWhiteSpace($installedVersion)) {
        return $null
    }

    if ($projectVersion -eq $installedVersion) {
        return $null
    }

    return "Module version mismatch detected: installed $installedVersion, project expects $projectVersion. To update: specrew update"
}

function Get-SpecrewPromptSessionState {
    param([Parameter(Mandatory = $true)][string]$ProjectRoot)

    $paths = Get-SpecrewSessionStatePaths -ProjectRoot $ProjectRoot
    if (-not (Test-Path -LiteralPath $paths.PromptPath -PathType Leaf)) {
        return $null
    }

    $parsed = ConvertFrom-SpecrewFrontmatter -Content (Get-Content -LiteralPath $paths.PromptPath -Raw -Encoding UTF8)
    return Get-SpecrewSessionStateFromFrontmatter -Frontmatter $parsed.Frontmatter
}

function Get-SpecrewIdentitySessionState {
    param([Parameter(Mandatory = $true)][string]$ProjectRoot)

    $paths = Get-SpecrewSessionStatePaths -ProjectRoot $ProjectRoot
    if (-not (Test-Path -LiteralPath $paths.IdentityPath -PathType Leaf)) {
        return $null
    }

    $parsed = ConvertFrom-SpecrewFrontmatter -Content (Get-Content -LiteralPath $paths.IdentityPath -Raw -Encoding UTF8)
    return Get-SpecrewSessionStateFromFrontmatter -Frontmatter $parsed.Frontmatter
}

function Get-SpecrewStartContextSessionState {
    param([Parameter(Mandatory = $true)][string]$ProjectRoot)

    $paths = Get-SpecrewSessionStatePaths -ProjectRoot $ProjectRoot
    if (-not (Test-Path -LiteralPath $paths.ContextPath -PathType Leaf)) {
        return $null
    }

    # -AsHashtable is critical here: legacy start-context.json files from
    # pre-F-020 projects (initialized at 0.19.0 or earlier) do NOT have the
    # session_state field. With ConvertFrom-Json producing PSCustomObject,
    # Set-StrictMode -Version Latest throws on the missing-property access.
    # Hashtable indexer returns $null for missing keys without throwing,
    # which is the migration-tolerant semantics we want here.
    try {
        $context = Get-Content -LiteralPath $paths.ContextPath -Raw -Encoding UTF8 | ConvertFrom-Json -Depth 12 -AsHashtable
    }
    catch {
        if (Test-IsUnsupportedSpecrewSchemaError -ErrorRecord $_) {
            throw
        }
        return $null
    }

    $schema = Get-SpecrewStateSchemaVersion -State $context -Path $paths.ContextPath
    # v0/v1 behavior: session_state payload remains optional for legacy workspaces

    if ($null -eq $context -or $null -eq $context['session_state']) {
        return $null
    }

    $sessionState = $context['session_state']
    return [pscustomobject]@{
        active           = if ($sessionState['active']) { 'true' } else { 'false' }
        boundary_type    = [string]$sessionState['boundary_type']
        feature_ref      = [string]$sessionState['feature_ref']
        feature_path     = [string]$sessionState['feature_path']
        iteration_number = [string]$sessionState['iteration_number']
        task_id          = [string]$sessionState['task_id']
        auth_commit_hash = [string]$sessionState['auth_commit_hash']
        recorded_at      = [string]$sessionState['recorded_at']
    }
}

function Get-SpecrewSessionStateSnapshot {
    param([Parameter(Mandatory = $true)][string]$ProjectRoot)

    $promptState = Get-SpecrewPromptSessionState -ProjectRoot $ProjectRoot
    $contextState = Get-SpecrewStartContextSessionState -ProjectRoot $ProjectRoot
    $identityState = Get-SpecrewIdentitySessionState -ProjectRoot $ProjectRoot
    $decisionsState = Get-LatestSpecrewBoundarySyncState -ProjectRoot $ProjectRoot
    $states = @(
        foreach ($candidate in @($promptState, $contextState, $identityState, $decisionsState)) {
            if ($null -ne $candidate) {
                $candidate
            }
        }
    )

    # File paths surfaced so Test-SpecrewSessionStateConsistency can distinguish
    # "file absent on disk" from "file present but stale/unparseable" — fixes the
    # misleading "missing or unreadable" message from tip-calc-v2 dogfooding 2026-05-23.
    $resolvedProjectRoot = Resolve-ProjectPath -Path $ProjectRoot

    return [pscustomobject]@{
        prompt         = $promptState
        prompt_path    = Join-Path $resolvedProjectRoot '.specrew\last-start-prompt.md'
        context        = $contextState
        context_path   = Join-Path $resolvedProjectRoot '.specrew\start-context.json'
        identity       = $identityState
        identity_path  = Join-Path $resolvedProjectRoot '.squad\identity\now.md'
        decisions      = $decisionsState
        session_state  = if ($states.Count -gt 0) { $states[0] } else { $null }
    }
}

function Test-SpecrewFeatureMergedToMain {
    param(
        [Parameter(Mandatory = $true)][string]$ProjectRoot,
        [AllowNull()][string]$FeatureRef
    )

    $featureNumber = Get-SpecrewFeatureNumber -FeatureRef $FeatureRef
    if ([string]::IsNullOrWhiteSpace($featureNumber)) {
        return [pscustomobject]@{ IsMerged = $false; Detail = $null }
    }

    $bootstrapDate = Get-SpecrewConfigValue -ProjectRoot $ProjectRoot -Key 'bootstrap_date'
    if ([string]::IsNullOrWhiteSpace($bootstrapDate)) {
        $bootstrapDate = '90 days ago'
    }

    $logOutput = @(& git -C $ProjectRoot log main --since="$bootstrapDate" --merges --oneline --grep="$featureNumber" 2>&1)
    if ($LASTEXITCODE -ne 0) {
        return [pscustomobject]@{ IsMerged = $false; Detail = $null }
    }

    if ($logOutput.Count -gt 0) {
        return [pscustomobject]@{
            IsMerged = $true
            Detail   = ('Feature {0} appears in merge history on main: {1}' -f $featureNumber, ($logOutput[0].ToString().Trim()))
        }
    }

    return [pscustomobject]@{ IsMerged = $false; Detail = $null }
}

function Test-SpecrewFeatureBranchExists {
    param(
        [Parameter(Mandatory = $true)][string]$ProjectRoot,
        [AllowNull()][string]$FeatureRef
    )

    if ([string]::IsNullOrWhiteSpace($FeatureRef)) {
        return $true
    }

    & git -C $ProjectRoot show-ref --verify --quiet ("refs/heads/{0}" -f $FeatureRef)
    if ($LASTEXITCODE -eq 0) {
        return $true
    }

    & git -C $ProjectRoot show-ref --verify --quiet ("refs/remotes/origin/{0}" -f $FeatureRef)
    return ($LASTEXITCODE -eq 0)
}

function Test-SpecrewAuthorizationRecord {
    param(
        [Parameter(Mandatory = $true)][string]$ProjectRoot,
        [pscustomobject]$SessionState
    )

    if ($null -eq $SessionState -or [string]::IsNullOrWhiteSpace([string]$SessionState.feature_ref)) {
        return $true
    }

    $paths = Get-SpecrewSessionStatePaths -ProjectRoot $ProjectRoot
    if (-not (Test-Path -LiteralPath $paths.DecisionsPath -PathType Leaf)) {
        return $false
    }

    $content = Get-Content -LiteralPath $paths.DecisionsPath -Raw -Encoding UTF8
    if (-not [string]::IsNullOrWhiteSpace([string]$SessionState.auth_commit_hash) -and $content -match [regex]::Escape([string]$SessionState.auth_commit_hash)) {
        return $true
    }

    $featureNumber = Get-SpecrewFeatureNumber -FeatureRef $SessionState.feature_ref
    if ([string]::IsNullOrWhiteSpace($featureNumber)) {
        return $false
    }

    return ($content -match ('Feature\s+{0}' -f [regex]::Escape($featureNumber)) -and $content -match 'authorization')
}

function Test-SpecrewSessionStateConsistency {
    param([Parameter(Mandatory = $true)][pscustomobject]$Snapshot)

    $issues = New-Object System.Collections.Generic.List[string]
    # Each entry now optionally carries a Path so we can distinguish "file absent on disk"
    # from "file present but unparseable / stale frontmatter". Wording fix following
    # tip-calc-v2 dogfooding 2026-05-23/24: the prior "missing or unreadable" message
    # fired even when the file was present and readable, just stale relative to the git
    # log — that misled the human into thinking the file had been deleted.
    $namedStates = @(
        @{ Name = 'last-start-prompt.md'; State = $Snapshot.prompt;   Path = $Snapshot.prompt_path }
        @{ Name = 'start-context.json';   State = $Snapshot.context;  Path = $Snapshot.context_path }
        @{ Name = 'identity/now.md';      State = $Snapshot.identity; Path = $Snapshot.identity_path }
    )

    $existingCount = @($namedStates | Where-Object { $null -ne $_.State }).Count
    if ($existingCount -gt 0) {
        foreach ($entry in $namedStates) {
            if ($null -eq $entry.State) {
                $fileOnDisk = $false
                if (-not [string]::IsNullOrWhiteSpace([string]$entry.Path)) {
                    $fileOnDisk = Test-Path -LiteralPath ([string]$entry.Path) -PathType Leaf
                }
                if ($fileOnDisk) {
                    $issues.Add(("Session-state file is present but stale or unparseable: {0} (file is on disk but its frontmatter / JSON could not be loaded; re-anchor or recreate to refresh)" -f $entry.Name)) | Out-Null
                }
                else {
                    $issues.Add(("Session-state file missing on disk: {0} (re-anchor will recreate it from the current spec)" -f $entry.Name)) | Out-Null
                }
            }
        }
    }

    $activeStates = @(
        foreach ($entry in $namedStates) {
            if ($null -ne $entry.State) {
                $entry.State
            }
        }
        if ($null -ne $Snapshot.decisions) {
            $Snapshot.decisions
        }
    )
    $featureRefs = @($activeStates | ForEach-Object { [string]$_.feature_ref } | Where-Object { -not [string]::IsNullOrWhiteSpace($_) } | Select-Object -Unique)
    if ($featureRefs.Count -gt 1) {
        $issues.Add(("Session-state feature mismatch detected: {0}" -f ($featureRefs -join ', '))) | Out-Null
    }

    $boundaries = @($activeStates | ForEach-Object { [string]$_.boundary_type } | Where-Object { -not [string]::IsNullOrWhiteSpace($_) } | Select-Object -Unique)
    if ($boundaries.Count -gt 1) {
        $issues.Add(("Session-state boundary mismatch detected: {0}" -f ($boundaries -join ', '))) | Out-Null
    }

    return $issues.ToArray()
}

function Get-SpecrewLatestIterationDirectory {
    param(
        [Parameter(Mandatory = $true)][string]$FeaturePath
    )

    $iterationsRoot = Join-Path $FeaturePath 'iterations'
    if (-not (Test-Path -LiteralPath $iterationsRoot -PathType Container)) {
        return $null
    }

    return @(
        Get-ChildItem -LiteralPath $iterationsRoot -Directory |
            Sort-Object Name -Descending |
            Select-Object -First 1
    )[0]
}

function Get-SpecrewMetadataValueFromFile {
    param(
        [Parameter(Mandatory = $true)][string]$Path,
        [Parameter(Mandatory = $true)][string]$Label
    )

    if (-not (Test-Path -LiteralPath $Path -PathType Leaf)) {
        return $null
    }

    $pattern = '(?m)^\*\*' + [regex]::Escape($Label) + '\*\*:\s*(?<value>.+?)\s*$'
    $match = [regex]::Match((Get-Content -LiteralPath $Path -Raw -Encoding UTF8), $pattern)
    if ($match.Success) {
        return $match.Groups['value'].Value.Trim()
    }

    return $null
}

function Get-SpecrewLateBoundaryIssues {
    param(
        [Parameter(Mandatory = $true)][string]$ProjectRoot,
        [AllowNull()][pscustomobject]$SessionState
    )

    if ($null -eq $SessionState) {
        return @()
    }

    $issues = New-Object System.Collections.Generic.List[string]
    $featurePath = if (-not [string]::IsNullOrWhiteSpace([string]$SessionState.feature_path)) {
        [string]$SessionState.feature_path
    }
    elseif (-not [string]::IsNullOrWhiteSpace([string]$SessionState.feature_ref)) {
        Join-Path $ProjectRoot ('specs\' + [string]$SessionState.feature_ref)
    }
    else {
        $null
    }

    if ([string]::IsNullOrWhiteSpace($featurePath) -or -not (Test-Path -LiteralPath $featurePath -PathType Container)) {
        return @()
    }

    $latestIterationDirectory = Get-SpecrewLatestIterationDirectory -FeaturePath $featurePath
    if ($null -ne $latestIterationDirectory) {
        $reviewPath = Join-Path $latestIterationDirectory.FullName 'review.md'
        $reviewVerdict = Get-SpecrewMetadataValueFromFile -Path $reviewPath -Label 'Overall Verdict'
        if ($reviewVerdict -match '^(?i)accepted$' -and [string]$SessionState.boundary_type -notin @('review-signoff', 'retro', 'iteration-closeout', 'feature-closeout')) {
            $issues.Add(("Late boundary sync mismatch: review.md is accepted in iteration {0}, but the recorded boundary is '{1}' instead of review-signoff or later." -f $latestIterationDirectory.Name, $SessionState.boundary_type)) | Out-Null
        }
    }

    $closeoutDashboardPath = Join-Path $featurePath 'closeout-dashboard.md'
    if ((Test-Path -LiteralPath $closeoutDashboardPath -PathType Leaf) -and [string]$SessionState.boundary_type -ne 'feature-closeout') {
        $issues.Add(("Late boundary sync mismatch: closeout-dashboard.md exists for '{0}', but the recorded boundary is '{1}' instead of feature-closeout." -f (Split-Path -Leaf $featurePath), $SessionState.boundary_type)) | Out-Null
    }

    return $issues.ToArray()
}

function Test-SpecrewStaleSessionState {
    param([Parameter(Mandatory = $true)][string]$ProjectRoot)

    $snapshot = Get-SpecrewSessionStateSnapshot -ProjectRoot $ProjectRoot
    $sessionState = $snapshot.session_state
    if ($null -eq $sessionState) {
        return [pscustomobject]@{
            IsStale = $false
            Issues = @()
            SessionState = $null
        }
    }

    $issues = New-Object System.Collections.Generic.List[string]
    foreach ($issue in (Test-SpecrewSessionStateConsistency -Snapshot $snapshot)) {
        $issues.Add($issue) | Out-Null
    }

    foreach ($issue in (Get-SpecrewLateBoundaryIssues -ProjectRoot $ProjectRoot -SessionState $sessionState)) {
        $issues.Add($issue) | Out-Null
    }

    if ([string]$sessionState.active -eq 'false') {
        return [pscustomobject]@{
            IsStale      = ($issues.Count -gt 0)
            Issues       = $issues.ToArray()
            SessionState = $sessionState
        }
    }

    $mergeCheck = Test-SpecrewFeatureMergedToMain -ProjectRoot $ProjectRoot -FeatureRef $sessionState.feature_ref
    if ($mergeCheck.IsMerged) {
        $issues.Add($mergeCheck.Detail) | Out-Null
    }

    if (-not (Test-SpecrewFeatureBranchExists -ProjectRoot $ProjectRoot -FeatureRef $sessionState.feature_ref)) {
        $issues.Add(("Feature branch is missing: {0}" -f $sessionState.feature_ref)) | Out-Null
    }

    if (-not (Test-SpecrewAuthorizationRecord -ProjectRoot $ProjectRoot -SessionState $sessionState)) {
        $issues.Add(("Authorization record missing for {0}." -f $sessionState.feature_ref)) | Out-Null
    }

    return [pscustomobject]@{
        IsStale = ($issues.Count -gt 0)
        Issues = $issues.ToArray()
        SessionState = $sessionState
    }
}

function Read-SpecrewRecoveryChoice {
    param([AllowNull()][string]$PreferredChoice)

    if (-not [string]::IsNullOrWhiteSpace($PreferredChoice)) {
        return $PreferredChoice.Trim().ToUpperInvariant()
    }

    while ($true) {
        $selection = Read-Host 'Choose recovery path [A/B/C]'
        if (-not [string]::IsNullOrWhiteSpace($selection)) {
            $normalizedSelection = $selection.Trim().ToUpperInvariant()
            if ($normalizedSelection -in @('A', 'B', 'C')) {
                return $normalizedSelection
            }
        }

        Write-Output "WARN: Invalid recovery choice. Enter A, B, or C." | Out-Host
    }
}

function New-SpecrewRecoverySession {
    param(
        [Parameter(Mandatory = $true)][string]$EntryMode,
        [Parameter(Mandatory = $true)][string[]]$StaleReasons,
        [Parameter(Mandatory = $true)][bool]$BypassGate,
        [AllowNull()][string]$SelectedChoice,
        [Parameter(Mandatory = $true)][string]$NextActionMessage
    )

    return [pscustomobject]@{
        entry_mode              = $EntryMode
        stale_reasons           = @($StaleReasons)
        choice_set              = if ($EntryMode -eq 'detected-stale-state') { @('A', 'B', 'C') } else { @('recover') }
        selected_choice         = $SelectedChoice
        bypass_gate             = $BypassGate
        approval_mode_changed   = $false
        next_action_message     = $NextActionMessage
    }
}

function Resolve-SpecrewRecoverySelection {
    param(
        [Parameter(Mandatory = $true)][string]$Choice,
        [AllowNull()][pscustomobject]$SessionState
    )

    $recoveryFeaturePath = if ($null -ne $SessionState -and -not [string]::IsNullOrWhiteSpace([string]$SessionState.feature_path)) {
        [string]$SessionState.feature_path
    }
    else {
        $null
    }

    switch ($Choice) {
        'A' {
            return [pscustomobject]@{
                ResumeFeatureOverride = if (-not [string]::IsNullOrWhiteSpace($recoveryFeaturePath)) { $recoveryFeaturePath } else { 'auto' }
                SkipAutoResume        = $false
                ForceNoLaunch         = $false
                NextActionMessage     = if (-not [string]::IsNullOrWhiteSpace($recoveryFeaturePath)) {
                    "Recovery will re-anchor to '$recoveryFeaturePath' so you can repair or continue the last known feature state."
                }
                else {
                    'Recovery will try to re-anchor to the last known feature automatically so you can repair or continue.'
                }
                Directive             = 'Recovery choice A selected: re-anchor to the last known feature, inspect the stale-state evidence, and continue with an explicit repair or resume plan.'
            }
        }
        'B' {
            return [pscustomobject]@{
                ResumeFeatureOverride = $null
                SkipAutoResume        = $true
                ForceNoLaunch         = $false
                NextActionMessage     = 'Recovery will bypass the stale feature state and return you to fresh feature intake.'
                Directive             = 'Recovery choice B selected: do not resume the stale feature automatically. Start fresh intake for a new feature after acknowledging the stale-state evidence.'
            }
        }
        default {
            return [pscustomobject]@{
                ResumeFeatureOverride = $null
                SkipAutoResume        = $true
                ForceNoLaunch         = $true
                NextActionMessage     = 'Recovery will stop after writing diagnostics so you can manually fix or document the stale state before restarting.'
                Directive             = 'Recovery choice C selected: do not launch the host CLI automatically. Review the recorded stale-state evidence, repair the session-state artifacts manually, then rerun specrew start.'
            }
        }
    }
}

function Get-UnresolvedTemplateRefreshArtifacts {
    param(
        [Parameter(Mandatory = $true)]
        [string]$ResolvedProjectPath
    )

    $artifactRoot = Join-Path $ResolvedProjectPath '.specrew\template-conflicts'
    if (-not (Test-Path -LiteralPath $artifactRoot -PathType Container)) {
        return @()
    }

    return @(
        Get-ChildItem -LiteralPath $artifactRoot -File -Recurse -ErrorAction SilentlyContinue |
            Where-Object { $_.Extension -in @('.conflict', '.deletion') } |
            Sort-Object FullName |
            ForEach-Object {
                [pscustomobject]@{
                    Path         = $_.FullName
                    RelativePath = Get-DisplayPathFromProjectRoot -ResolvedProjectPath $ResolvedProjectPath -Path $_.FullName
                    Kind         = $_.Extension.TrimStart('.')
                }
            }
    )
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

            # F-023: Use -AsHashtable for StrictMode compatibility; hashtable indexer tolerates missing fields
            $featureJson = Get-Content -LiteralPath $featureJsonPath -Raw -Encoding UTF8 | ConvertFrom-Json -AsHashtable -Depth 12

            # F-023: Legacy schema handling - missing 'schema' field implies v0
            $schema = Get-SpecrewStateSchemaVersion -State $featureJson -Path $featureJsonPath
            # v0 behavior: feature_directory field is required
            # v1+ behavior: same as v0 for this field (no behavioral divergence yet)

            if (-not $featureJson['feature_directory']) {
                throw "Cannot resolve --resume-feature auto because '.specify\feature.json' does not contain feature_directory."
            }

            $candidate = [string]$featureJson['feature_directory']
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
            # F-023: Use -AsHashtable for StrictMode compatibility; hashtable indexer tolerates missing fields
            $featureJson = Get-Content -LiteralPath $featureJsonPath -Raw -Encoding UTF8 | ConvertFrom-Json -AsHashtable -Depth 12

            # F-023: Legacy schema handling - missing 'schema' field implies v0
            $schema = Get-SpecrewStateSchemaVersion -State $featureJson -Path $featureJsonPath
            # v0 behavior: feature_directory field is optional
            # v1+ behavior: same as v0 for this field (no behavioral divergence yet)

            if ($featureJson['feature_directory']) {
                $candidate = [string]$featureJson['feature_directory']
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
        [string]$SelectedHost,
        [switch]$RequireIndependentOversight
    )

    $requestedAgent = if ([string]::IsNullOrWhiteSpace($PreferredAgent)) { 'copilot' } else { $PreferredAgent.Trim().ToLowerInvariant() }
    $resolvedHost = if ([string]::IsNullOrWhiteSpace($SelectedHost)) { 'copilot' } else { $SelectedHost.Trim().ToLowerInvariant() }
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
        # Proposal 107: host-first oversight priority (prefer the launch host over copilot when it can play
        # both implementer and reviewer-of-record). The constraint that follows still requires the agent to
        # differ from the Implementer for true independence — that's a separate gap tracked in Proposal 102.
        $oversightPriority = @($resolvedHost, 'claude', 'codex', 'copilot') | Select-Object -Unique
        $effectiveAgent = Get-PreferredEnabledAgent -EnabledAgents $EnabledAgents -Priority $oversightPriority -Exclude $ImplementerAgent
    }

    if (-not $effectiveAgent) {
        # Proposal 107: host-first fallback. The launch host is the only agent we know is runnable in this
        # session — copilot can't be invoked from inside Claude/Codex — so we prefer it before copilot.
        $fallbackPriority = if ($RequireIndependentOversight -and $EnabledAgents.Count -gt 1) {
            @($resolvedHost, 'claude', 'codex', 'copilot') | Select-Object -Unique
        }
        else {
            @($resolvedHost, 'copilot', 'claude', 'codex') | Select-Object -Unique
        }

        $effectiveAgent = Get-PreferredEnabledAgent -EnabledAgents $EnabledAgents -Priority $fallbackPriority -Exclude $(if ($RequireIndependentOversight -and $EnabledAgents.Count -gt 1) { $ImplementerAgent } else { $null })
        if (-not $effectiveAgent) {
            $effectiveAgent = Get-PreferredEnabledAgent -EnabledAgents $EnabledAgents -Priority (@($resolvedHost, 'copilot', 'claude', 'codex') | Select-Object -Unique) -Exclude $null
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
        [System.Collections.IDictionary]$AgentLookup,
        [string]$SelectedHost = 'copilot'
    )

    $roleLookup = @{}
    foreach ($roleAssignment in $RoleAssignments) {
        $roleLookup[$roleAssignment.name] = $roleAssignment
    }

    $resolvedHost = if ([string]::IsNullOrWhiteSpace($SelectedHost)) { 'copilot' } else { $SelectedHost.Trim().ToLowerInvariant() }

    $enabledAgents = @(
        foreach ($agentName in @('copilot', 'claude', 'codex')) {
            if ($AgentLookup.Contains($agentName) -and $AgentLookup[$agentName].enabled -and $AgentLookup[$agentName].availability -eq 'available') {
                $agentName
            }
        }
    )
    # Proposal 107: the launch host is always enabled-for-routing, even when iteration-config.yml marks
    # it disabled. The user explicitly chose to run in this host, so it IS the runnable process — any role
    # routing to it is literally the same process serving multiple slots.
    if (-not [string]::IsNullOrWhiteSpace($resolvedHost) -and ($enabledAgents -notcontains $resolvedHost)) {
        $enabledAgents = @($resolvedHost) + $enabledAgents
    }
    if ($enabledAgents.Count -eq 0) {
        $enabledAgents = @('copilot')
    }

    $routingRoles = [ordered]@{}
    $implementedRoles = New-Object System.Collections.Generic.List[string]
    foreach ($roleName in @('Implementer', 'Spec Steward', 'Planner', 'Reviewer', 'Retro Facilitator')) {
        $implementedRoles.Add($roleName)
    }

    $implementerPreference = if ($roleLookup.ContainsKey('Implementer')) { $roleLookup['Implementer'].preferred_agent } else { 'copilot' }
    $implementerPlan = Resolve-RoleAgentPlan -RoleName 'Implementer' -PreferredAgent $implementerPreference -AgentLookup $AgentLookup -EnabledAgents $enabledAgents -ImplementerAgent $null -SelectedHost $resolvedHost
    $routingRoles['Implementer'] = $implementerPlan

    foreach ($roleName in @('Spec Steward', 'Planner', 'Reviewer', 'Retro Facilitator')) {
        $preferredAgent = if ($roleLookup.ContainsKey($roleName)) { $roleLookup[$roleName].preferred_agent } else { 'copilot' }
        $routingRoles[$roleName] = Resolve-RoleAgentPlan `
            -RoleName $roleName `
            -PreferredAgent $preferredAgent `
            -AgentLookup $AgentLookup `
            -EnabledAgents $enabledAgents `
            -ImplementerAgent $implementerPlan.effective_agent `
            -SelectedHost $resolvedHost `
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
            -ImplementerAgent $implementerPlan.effective_agent `
            -SelectedHost $resolvedHost
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

    # Use System.IO.Path.GetRelativePath (cross-platform safe on .NET Core 2.0+).
    # The previous System.Uri / MakeRelativeUri approach failed on Linux because
    # bare absolute paths like "/home/user/foo" are not auto-recognized as
    # absolute URIs by the [System.Uri] constructor without a "file://" scheme,
    # producing "This operation is not supported for a relative URI" exceptions.
    $rootFull = [System.IO.Path]::GetFullPath($Root)
    $targetFull = [System.IO.Path]::GetFullPath($Path)
    return [System.IO.Path]::GetRelativePath($rootFull, $targetFull)
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
        '\.git[\\/]',
        '\.specify[\\/]',
        '\.specrew[\\/]',
        '\.squad[\\/]',
        '\.copilot[\\/]',
        'node_modules[\\/]',
        'dist[\\/]',
        'build[\\/]',
        'coverage[\\/]',
        'vendor[\\/]',
        'bin[\\/]',
        'obj[\\/]'
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

function Get-SessionLoadedPaths {
    return @(
        '.github/agents/*'
        '.github/copilot-instructions.md'
        'extensions/specrew-speckit/squad-templates/coordinator/*'
        '.specify/extensions/specrew-speckit/squad-templates/coordinator/*'
        '.squad/agents/*/charter.md'
    )
}

function Get-BaselineCommitHash {
    param(
        [string]$ResolvedProjectPath
    )

    $promptPath = Join-Path $ResolvedProjectPath '.specrew\last-start-prompt.md'
    if (-not (Test-Path -LiteralPath $promptPath -PathType Leaf)) {
        return $null
    }

    try {
        $content = Get-Content -LiteralPath $promptPath -Raw -Encoding UTF8
        if ($content -match '(?ms)^---\s*\r?\n(.*?)\r?\n---') {
            $frontmatterBlock = $Matches[1]
            if ($frontmatterBlock -match '(?m)^\s*baseline_commit_hash:\s*([0-9a-f]{40})\s*$'){ 
                return $Matches[1]
            }
        }
    }
    catch {
        # Parsing failed; return null to default to HEAD
    }

    return $null
}

function Test-SessionLoadedFilesChanged {
    param(
        [string]$ResolvedProjectPath,
        [AllowNull()][string]$BaselineCommitHash
    )

    try {
        $gitRoot = & git -C $ResolvedProjectPath rev-parse --show-toplevel 2>&1
        if ($LASTEXITCODE -ne 0) {
            return @()
        }

        $currentHead = & git -C $ResolvedProjectPath rev-parse HEAD 2>&1
        if ($LASTEXITCODE -ne 0) {
            return @()
        }

        $baseline = if ([string]::IsNullOrWhiteSpace($BaselineCommitHash)) { $currentHead } else { $BaselineCommitHash }

        $sessionLoadedGlobs = Get-SessionLoadedPaths
        $changedFiles = @()

        foreach ($glob in $sessionLoadedGlobs) {
            $diffOutput = @(& git -C $ResolvedProjectPath diff --name-only $baseline HEAD -- $glob 2>&1)
            if ($LASTEXITCODE -eq 0) {
                $changedFiles += $diffOutput | Where-Object { -not [string]::IsNullOrWhiteSpace($_) }
            }
        }

        return @($changedFiles | Select-Object -Unique)
    }
    catch {
        return @()
    }
}

function Get-RestartTriggerFiles {
    param(
        [string]$ResolvedProjectPath,
        [AllowNull()][string]$BaselineCommitHash,
        [string[]]$ChangedFiles
    )

    $restartTriggerFiles = New-Object System.Collections.Generic.List[string]
    foreach ($changedFile in @($ChangedFiles | Select-Object -Unique)) {
        if ([string]::IsNullOrWhiteSpace($changedFile)) {
            continue
        }

        $normalizedChangedFile = ([string]$changedFile).Trim() -replace '/', '\'
        if ($normalizedChangedFile -ieq '.github\copilot-instructions.md') {
            $classification = Test-CopilotInstructionsChangeType -ProjectPath $ResolvedProjectPath -BaselineCommitHash $BaselineCommitHash -TargetPath '.github/copilot-instructions.md'
            if ($classification.RequiresRestart) {
                $restartTriggerFiles.Add($normalizedChangedFile) | Out-Null
            }
            continue
        }

        $restartTriggerFiles.Add($normalizedChangedFile) | Out-Null
    }

    return $restartTriggerFiles.ToArray()
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
        [pscustomobject]$DeliveryGuidance,
        [AllowNull()][pscustomobject]$SessionState,
        [AllowNull()][pscustomobject]$RecoverySession
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

    $resumePromptBlock = Get-CoordinatorResumePromptBlock -ProjectRoot $ResolvedProjectPath -ResolvedFeaturePath $ResolvedFeaturePath -SessionState $SessionState
    $recoveryPromptBlock = Get-CoordinatorRecoveryPromptBlock -RecoverySession $RecoverySession
    $teamRosterBlock = Get-TeamRosterPromptBlock -TeamRoster $TeamRoster
    $routingPlanBlock = Get-RoutingPlanPromptBlock -RoutingPlan $RoutingPlan
    $projectStateBlock = Get-ProjectStatePromptBlock -ProjectState $ProjectState
    $brownfieldDiscoveryBlock = Get-BrownfieldDiscoveryPromptBlock -BrownfieldDiscovery $BrownfieldDiscovery
    $deliveryGuidanceBlock = Get-DeliveryGuidancePromptBlock -DeliveryGuidance $DeliveryGuidance
    $boundaryPolicyClasses = Get-SpecrewBoundaryPolicyClassMap -ProjectRoot $ResolvedProjectPath
    $humanJudgmentBoundaries = @($boundaryPolicyClasses.GetEnumerator() | Where-Object { [string]$_.Value -eq 'human-judgment-required' } | ForEach-Object { [string]$_.Key })
    $boundaryPolicyPromptBlock = if ($humanJudgmentBoundaries.Count -gt 0) {
        "- Resolved from ``.specrew/config.yml`` into ``boundary_enforcement.policy_classes`` in ``start-context.json``: $($humanJudgmentBoundaries -join ', ') require human judgment."
    }
    else {
        '- Resolved from ``.specrew/config.yml`` into ``boundary_enforcement.policy_classes`` in ``start-context.json``: no human-judgment boundaries are configured for this run.'
    }

    # Forward-slash form of the project path for use in `file:///` URLs in the
    # orientation block + Rule 52 (visible file:/// artifact references in user output).
    $projectPathUrl = ([string]$ResolvedProjectPath).Replace('\', '/').TrimEnd('/')

    return @"
You are Squad running inside a Specrew-bootstrapped repository.

Project root: $ResolvedProjectPath
Project root (file:// URL form for clickable references): file:///$projectPathUrl
Mode: $Mode
$featureLine
$requestLine

$resumePromptBlock

$recoveryPromptBlock

$teamRosterBlock

$projectStateBlock

$brownfieldDiscoveryBlock

$deliveryGuidanceBlock

$routingPlanBlock

## Lifecycle Quick Reference

This is the authoritative map of Specrew's lifecycle and governance machinery as of the running version. Read this once. Do NOT re-derive it from source — see Rule 49.

**Phase agents and the artifacts they produce:**

| Phase agent (invoke as) | What it does | Artifact(s) on disk | Readiness gate / hard-block |
|---|---|---|---|
| ``/speckit.specify`` | Generates ``spec.md`` + ``checklists/requirements.md`` for the feature | ``specs/<feature>/spec.md`` + ``specs/<feature>/checklists/requirements.md`` + ``.specify/feature.json`` | none (readiness only) |
| ``/speckit.clarify`` | Asks 2-3 ambiguity questions; appends ``## Clarifications`` section to spec.md | ``spec.md`` Clarifications section | none |
| ``/speckit.specrew-speckit.before-plan`` | Runs ``resolve-quality-profile.ps1``; resolved profile becomes the Phase 1 + Phase 2 quality-bar planning input embedded in plan.md | output consumed by plan.md | readiness only — does NOT hard-block |
| ``/speckit.plan`` | Writes plan.md with architecture, FR-to-test mapping, embedded quality-planning sections | ``specs/<feature>/plan.md`` | none |
| ``/speckit.tasks`` | Writes ``tasks.md`` decomposing plan.md into per-task delivery work, each traced to >=1 FR/SC | ``specs/<feature>/tasks.md`` | none |
| ``/speckit.specrew-speckit.after-tasks`` | Runs the traceability check (every task maps to >=1 FR/SC; every FR/SC has >=1 task) | output only; nothing on disk | readiness only — does NOT hard-block |
| ``/speckit.specrew-speckit.before-implement`` | **HUMAN APPROVAL GATE.** Demands hardening-gate.md + iteration plan with ``Overall Verdict: ready``; calls ``Test-SpecrewBoundaryAuthorization`` which requires a verdict_history entry for ``tasks -> before-implement`` crossing | ``specs/<feature>/iterations/<NNN>/quality/hardening-gate.md`` (planning-time) + iteration plan.md | **YES — hard-blocks without human approval** |
| ``/speckit.implement`` | Writes code + tests per tasks.md; emits ONE short progress sentence per major task | source files + tests under repo root | none — but boundary-commit per Rule 45 is mandatory |
| ``/specrew-review`` (after implement) | Writes ``review.md`` + reviewer artifacts (``code-map.md``, ``coverage-evidence.md``, ``reviewer-index.md``, ``review-diagrams.md``, ``dependency-report.md``) when code/manifests were touched | ``specs/<feature>/iterations/<NNN>/review.md`` + reviewer artifacts | validator demands reviewer artifacts when code touched (F-040 dogfooding Fix A) |
| retro phase | Writes ``retro.md`` with what-went-well / what-was-hard / lessons-learned / signals-for-next-iteration | ``specs/<feature>/iterations/<NNN>/retro.md`` | none |

**Governance scripts (these exist; invoke them by path, do NOT read them as research):**

| Script | What it does | When to invoke |
|---|---|---|
| ``.specify/scripts/powershell/create-new-feature.ps1 -ShortName <slug> -Json "<feature description>"`` | Creates feature branch ``001-<ShortName>`` + scaffolds spec.md from template. **Always pass ``-ShortName``** (e.g., ``tip-calculator``); without it the branch slug is auto-derived from the description and tends to be awkward (``001-build-single-page`` vs ``001-tip-calculator``). | Once per new feature, before /speckit.specify |
| ``.specify/scripts/powershell/check-prerequisites.ps1`` | Resolves REPO_ROOT / BRANCH / FEATURE_DIR / FEATURE_SPEC / IMPL_PLAN / TASKS paths | At the start of each phase that needs them |
| ``.specify/extensions/specrew-speckit/scripts/resolve-quality-profile.ps1`` | Resolves quality profile + lens activation; output goes into plan.md | Invoked by /before-plan |
| ``.specify/extensions/specrew-speckit/scripts/scaffold-iteration-artifacts.ps1 -SpecDirectory <dir> -IterationNumber <NNN>`` | Scaffolds iterations/<NNN>/{state.md, drift-log.md, quality/hardening-gate.md, quality/quality-evidence.md, quality/mechanical-findings.json, quality/lenses/*}. **The emitted hardening-gate.md already carries the canonical 9-column schema with default ``addressed`` / ``not-applicable`` statuses and an ``Overall Verdict: ready`` — you do NOT need to additionally run run-hardening-gate.ps1; only refine the per-concern Rationale + Expected Controls cells with feature-specific text.** | Before iteration plan write |
| ``.specify/extensions/specrew-speckit/scripts/scaffold-iteration-plan.ps1 -SpecPath <spec> -IterationNumber <NNN>`` | Scaffolds iterations/<NNN>/plan.md stub | Before /speckit.implement |
| ``.specify/extensions/specrew-speckit/scripts/run-hardening-gate.ps1`` | OPTIONAL gate-regeneration helper. Takes a seed file with concern rows + computes the canonical Concern Review table + verdict. Useful only when you've edited concerns externally and want the gate file regenerated. **For normal lifecycle execution, skip this — the scaffold above already emits a ready gate.** | Rarely; only when regenerating from a seed |
| ``.specify/extensions/specrew-speckit/scripts/run-mechanical-checks.ps1`` | Runs the dead-field / anti-pattern / test-integrity mechanical lenses; writes findings to quality/mechanical-findings.json | After implement; before review |
| ``.specify/extensions/specrew-speckit/scripts/scaffold-review-artifact.ps1 -IterationDirectory <dir>`` | Scaffolds review.md stub for the active iteration. **Param is ``-IterationDirectory``, NOT ``-SpecDirectory``** (latter is only on scaffold-iteration-artifacts). | At the start of review phase |
| ``.specify/extensions/specrew-speckit/scripts/scaffold-retro-artifact.ps1 -IterationDirectory <dir>`` | Scaffolds retro.md stub for the active iteration | At the start of retro phase |
| ``.specify/extensions/specrew-speckit/scripts/scaffold-reviewer-artifacts.ps1 -IterationDirectory <dir>`` | Scaffolds code-map / coverage-evidence / reviewer-index / review-diagrams / dependency-report. **Param is ``-IterationDirectory``, NOT ``-SpecDirectory``.** | After implement, before /specrew-review |
| ``.specify/extensions/specrew-speckit/scripts/scaffold-feature-closeout-dashboard.ps1 -ProjectPath . -FeatureId <NNN>`` | Scaffolds the closeout-dashboard.md at feature-closeout boundary. **Note: auto-render at feature-closeout is now wired into sync-boundary-state.ps1 (F-040 dogfooding Fix B), so you don't normally invoke this directly.** | Rarely; only for manual re-render |
| ``.specify/extensions/specrew-speckit/scripts/validate-governance.ps1 -ProjectPath .`` | Runs the full validator; emits PASS/WARN/FAIL findings | Before each boundary commit and at iteration close |
| ``.specify/extensions/specrew-speckit/scripts/sync-boundary-state.ps1`` | Advances the boundary cursor in ``.specrew/start-context.json``; auto-renders dashboard.md at iteration-closeout + closeout-dashboard.md at feature-closeout. Use this WRAPPER path from downstream projects — it discovers the installed Specrew module and loads the actual implementation from there. | Called by sync-* agents; invoke directly via ``pwsh -File`` after each boundary commit when the sync-* agents aren't available |

**Any other .ps1 file in the deployment is a utility / deploy / library helper invoked automatically by the system. Do NOT explore them during normal lifecycle execution.** Specifically: ``shared-governance.ps1``, ``common.ps1``, ``Test-CopilotInstructionsChangeType.ps1`` are libraries (not invokable); ``deploy-speckit-extension.ps1``, ``deploy-squad-runtime.ps1``, ``scaffold-governance.ps1``, ``validate-versions.ps1``, ``collision-detect.ps1``, ``brownfield-merge.ps1`` are init/update helpers; ``manage-escalation-state.ps1``, ``manage-reviewer-regression.ps1``, ``sync-squad-model-overrides.ps1``, ``drift-diff.ps1``, ``resume-iteration.ps1`` are internal helpers called by other scripts. If a script isn't in the table above, you do NOT need to invoke or understand it during normal lifecycle execution.

**Boundary authorization (policy-derived lifecycle stops):**

$boundaryPolicyPromptBlock
- A transition into a boundary whose policy class is ``human-judgment-required`` requires explicit human authorization before producing the next phase's substantive artifacts. Under the default policy this includes ``clarify -> plan`` and ``plan -> tasks``.
- Readiness helpers such as ``before-plan`` and ``after-tasks`` may emit warning/readiness findings, but they do not authorize skipping the human verdict for the next lifecycle boundary.
- ``boundary_enforcement`` in ``start-context.json`` is initialized on every ``specrew start`` and includes the resolved policy snapshot used by this prompt.
- ``approval_mode`` (``allow-all`` vs ``prompt-approvals``) controls tool-call approval, NOT lifecycle boundary approval. They are independent. ``--allow-all`` controls tool-call approval only and does not bypass lifecycle boundary approval. ``--autonomous`` (NOT default) controls whether the Crew stops at lifecycle gates without human input.

**What's deployed in this project (read from start-context.json):**

The ``crew_runtime_status`` field tells you whether the downstream sync-* agents are wired up. If ``bootstrap_only``, those agents may not be available — invoke the deployed wrapper directly via ``pwsh -File .specify/extensions/specrew-speckit/scripts/sync-boundary-state.ps1 -ProjectPath . -BoundaryType <boundary> -FeatureRef <feature> -AuthCommitHash <hash>`` for boundary advances. The wrapper auto-resolves the actual implementation from the installed Specrew module, so this works in any downstream project. Iteration / feature closeout auto-renders dashboards (F-040 dogfooding Fix B).

**Common pitfalls (already-fixed gaps from F-040 multi-host dogfooding 2026-05-23/24):**

- ``Status: approved`` / ``in_progress`` are INVALID iteration / task statuses. Canonical iteration statuses: ``planning | executing | reviewing | retro | complete | abandoned``. Canonical task statuses: ``planned | in-progress | done | needs-rework | deferred | blocked`` (hyphens, not underscores).
- Hardening-gate concern ``Status: tbd`` is rejected. Use ``addressed | not-applicable | deferred-with-approval``.
- ``Capacity: <consumed>/<cap> <effort_unit>`` with NO trailing prose. Notes go in the Notes section.
- **Windows shell rule:** on Windows/PowerShell, do not use Bash syntax, Unix-only path assumptions, or cross-shell deletion/move pipelines. Use PowerShell-native commands with quoted ``-LiteralPath`` values for file operations.
- **Web-form feature pitfall:** for any feature whose deliverable is an HTML form (calculator, registration, search box, etc.), browsers submit the form on **Enter key inside any ``<input>``** — which triggers a full page reload to the form's ``action`` URL and wipes computed output. If the form is rendered by your app and you want Enter to compute-without-reload, either (a) bind a ``submit`` handler that calls ``event.preventDefault()`` or (b) use ``<input type="button">`` (not ``submit``) for the action and avoid the form's default submission. Cover this in the test plan: a Cypress / Playwright test that types into the field and presses Enter must verify the computed value appears AND the URL does not change. This pitfall was the dominant bug class in F-040 tip-calc-v2 + calc-v2 dogfooding.
- **Web-feature acceptance evidence:** for browser features, the review-time evidence must include a screenshot or recorded interaction showing the golden-path AND Enter-key behavior — running ``Invoke-WebRequest`` against the static HTML proves the file deployed, NOT that the feature works. Lighthouse / DOM-inspection MCPs (or manual browser steps documented in quickstart.md) are the canonical evidence layer.

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
18. Once speckit.clarify completes, or you explicitly skip it with the recorded rationale above, check ``boundary_enforcement.policy_classes`` before the next transition. If ``plan`` is ``human-judgment-required``, stop at ``clarify -> plan`` before running ``speckit.specrew-speckit.before-plan`` or generating a substantive ``plan.md``; explain that planning will turn the spec into architecture and task direction. Apply the same one-boundary-at-a-time rule to ``plan -> tasks`` and every other configured human-judgment boundary.
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
45. **Boundary-commit discipline.** After every lifecycle artifact write that closes a boundary (spec.md after specify, plan.md after plan, tasks.md after tasks, iteration plan + hardening-gate after before-implement, source/tests after implement, review.md after review, retro.md after retro), stage and commit the affected files with a focused message like ``boundary(specify): write spec.md`` or ``boundary(implement): T013 reducer + tests``. Without these commits the F-033 markdownlint gate, F-039 boundary discipline, and the git-history audit trail cannot function — the lifecycle silently bypasses every commit-scoped guardrail.
46. **Human re-entry packet (mandatory).** At every human-judgment boundary stop, make the stop a human re-entry point. Do not duplicate the same stop with a legacy ``=== SPECREW HANDOFF ===`` block unless a transitional host/runtime explicitly requires that compatibility. The primary stop contract is this six-section packet:

``````markdown
## What I Just Did

Summarize the meaningful past outcome, not just file names. Include artifacts created or changed, committed evidence, decisions captured, assumptions added, scope changes, and notable risks or uncertainties discovered. Every artifact, file, or directory reference in this section must use ``file:///`` URL form.

## Why I Stopped

Name the exact lifecycle boundary and explain why human judgment is required before the next step. For ``clarify -> plan``, say that planning will convert the spec into architecture and task direction, so spec mistakes become downstream work.

## What Needs Your Review

Point to targeted review surfaces with ``file:///`` links, exact sections worth inspecting, high-impact choices, assumptions, uncertainties, and what can be safely skimmed. Identify release-blocking items when in scope, including ``Status: Approved`` verdict-evidence checks and beta smoke evidence.

## What Happens Next

Preview the next lifecycle phase, what artifacts will be produced, whether code will be written or only planning/tasks, which decisions become harder to change afterward, and the next expected boundary stop. Every future artifact, file, or directory reference in this section must use ``file:///`` URL form.

## Discussion Prompts

Show one to three prompts together. Each targeted prompt includes the context that triggered it, the question, the recommended/default path when one exists, and the consequence of changing direction when relevant. Include: "You can answer any prompt that should change direction, or approve with the defaults."

## What I Need From You

Allowed responses: approve as-is, approve with instructions, send back, or discuss prompt #N. If you ask the human to review an artifact, file, or directory here, use ``file:///`` URL form. Approval must be explicit; free-form discussion or feedback is not approval unless the human clearly authorizes this boundary.
``````

Every artifact, file, or directory reference in every packet section MUST use visible ``file:///`` URL form, not bare repository paths such as ``specs/...``, ``.specrew/...``, ``.squad/...``, ``tests/...``, or ``README.md``. Command/code blocks and explicit command examples are exempt. The packet text recorded as boundary evidence MUST be the exact human-visible packet you emit for approval; do not validate one packet and then summarize, relabel, or rewrite artifact references in the final visible approval packet. If the human chooses ``discuss prompt #N``, discuss that item only, summarize the agreed decision, and ask again for explicit boundary approval before advancing. One approval advances at most one lifecycle boundary.
47. The handoff block must use the canonical lifecycle boundary names (``specify``, ``clarify``, ``plan``, ``tasks``, ``before-implement``, ``implement``, ``review``, ``retro``, ``feature-closeout``) or the literal string ``lifecycle-end``. Do not invent boundary labels.
48. **Session opening orientation (mandatory FIRST output).** Your very first user-visible output, immediately after reading ``.specrew\last-start-prompt.md`` + ``.specrew\start-context.json``, must be a short friendly orientation block in the host-rendered shape below (8-15 lines, conversational tone, no bullet-list of phases). The visible Specrew version, selected host, runtime class, and lifecycle position in this block are generated from the installed runtime and saved start context; do not substitute, infer, omit, or claim any other host/runtime behavior. **All artifact and directory references in this block MUST use visible bare ``file:///`` URLs** built from the Project root URL above (see Rule 52):

<<SPECREW_HOST_ORIENTATION_BLOCK>>

The rendered block already contains the correct initial/resume opening line and lifecycle position. Emit that host-rendered version/host/runtime truth as-is except for replacing ``<project-root-url>``, ``<feature>``, and ``<NNN>`` placeholders with the actual visible ``file:///`` URLs/identifiers from this start context. After the orientation block, just execute. Do NOT produce any "let me orient myself" / "let me read the governance" / "I now have a full picture" prose ever again in this session.
49. **The Lifecycle Quick Reference section above (under ``## Lifecycle Quick Reference``) is authoritative as of the Specrew version that wrote this prompt.** Trust it. Do NOT read ``shared-governance.ps1``, ``sync-boundary-state.ps1``, ``validate-governance.ps1``, ``scaffold-*.ps1``, ``resolve-quality-profile.ps1``, or any ``*.agent.md`` / ``*.prompt.md`` file as "background research" before producing artifacts. Read them ONLY when (a) a tool you actually invoked failed and you need to debug it, or (b) you are writing CODE that extends or invokes a governance helper. Re-discovering Specrew's machinery per session is wasted tokens, wasted wall-clock, and noise the human has to read.
50. **Narration discipline (mandatory).** Reserve prose for: (a) the orientation block (once, per Rule 48), (b) clarify questions, (c) the HANDOFF block at boundary stops, (d) genuine decisions that affect the spec/plan, (e) ONE short progress sentence per major step ("Spec written.", "Iteration plan scaffolded.", "Tests passing — 51/51."), (f) status when the human asks. Avoid forever: "Let me read X", "Now let me check Y", "I'll gather Z context", "Let me orient myself", "I now have a complete picture", "Let me reconcile with the advisor", "Let me verify before committing". Use TaskList updates to show progress between boundaries — that's what the task pane is for. If you find yourself writing a narration sentence that says what you're ABOUT to do rather than what you JUST DID, delete it.
51. **Advisor calls are for strategic decisions, not mechanical execution.** Call ``advisor()`` only when you have a genuine strategic decision: a contested architectural choice, an unclear scope-vs-cost tradeoff, a stuck loop on real errors. Mechanical lifecycle execution on small slices (<=2 user stories, <=5 FRs, no architectural ambiguity) proceeds without consulting. You do NOT need to "confirm the approach" before writing a spec.md or a plan.md for a 3-FR feature. Default to no. When in doubt: do the work, get the artifact on disk, and only call advisor if the work surfaces a real disagreement with the spec or a real architectural fork. The user is paying for both tokens and wall-clock on every advisor call.
52. **File references in user-visible output must be visible ``file:///`` URLs.** When you mention an artifact, source file, directory, or any other file-system path in ANY user-visible prose — orientation block (Rule 48), one-sentence progress updates (Rule 50), HANDOFF blocks (Rule 46), clarify questions, decisions, developer briefings, retro notes — emit the full bare ``file:///`` URL built from the Project root URL above. Use forward slashes (the URL form is supplied for you at the top of this prompt as ``Project root (file:// URL form for clickable references): file:///...``). Apply this to directory references too (use the URL ending with ``/``). Example: instead of writing ``"the spec at specs/001-tip-calculator/spec.md"`` or ``"[spec.md](file:///C:/Temp/specrew-tip-calc-v2/specs/001-tip-calculator/spec.md)"``, write ``"the spec at file:///C:/Temp/specrew-tip-calc-v2/specs/001-tip-calculator/spec.md"``. Do not use markdown-link syntax for boundary packets; terminal hosts do not render it reliably and can hide the clickable target. Tool outputs and code blocks where the host already shows file paths are exempt; this rule only governs PROSE the Crew writes.
54. **Mandatory pre-implementation review artifact set (Wave B).** After ``/speckit.plan`` produces ``plan.md``, you MUST ensure all four of the following artifacts exist under ``specs/<feature>/`` BEFORE proceeding to ``/speckit.tasks``. They give the human reviewer a coherent view of WHAT will be built and HOW, BEFORE any code lands. If the Spec Kit plan agent did not emit a particular file, author it yourself from the templates below:

  (a) **``specs/<feature>/data-model.md``** — domain entities + attributes + validation rules + relationships, even for simple features (a minimal "no persisted state; transient inputs only" note + 1-2 entity descriptions is fine for a stateless calculator). Format:

``````markdown
# Data Model: <Feature Name>

**Feature**: <feature-ref>
**Date**: <YYYY-MM-DD>
**Purpose**: Define entities, attributes, relationships, and validation rules for <feature>.

## Entity: <EntityName>

**Purpose**: <one line>

### Attributes
| Attribute | Type | Required | Validation Rules | Description |
| --- | --- | --- | --- | --- |
| ... | ... | ... | ... | ... |

### Lifecycle / Relationships
<one-paragraph: how it's created, mutated, destroyed; what links to it>
``````

For state-free features, include a short "No persisted data" note + transient-input entities (CalculatorInput / CalculatorResult pattern).

  (b) **``specs/<feature>/quickstart.md``** — "how to try this feature in 5 minutes" walkthrough. Covers: run command(s), canonical happy-path input, expected output, one acceptance scenario the human can replay by hand. Format:

``````markdown
# Quickstart: <Feature Name>

**Feature**: <feature-ref>
**Last verified**: <YYYY-MM-DD>

## Run it
<exact commands — ``npm test`` / ``python -m http.server`` / ``pwsh -File ...``>

## Try the canonical scenario
<numbered steps + expected result per step>

## Verify the edge cases
<2-3 short edge-case scenarios from spec.md acceptance criteria>
``````

  (c) **``specs/<feature>/contracts/<feature-name>.md``** — document the feature's public API surface (function signatures, command-line surface, file format, IPC schema). Even code-only features have a contract: the exported functions of any pure module, the on-disk format produced, the CLI flags. Format:

``````markdown
# Contract: <Feature Name> Public Surface

**Feature**: <feature-ref>
**Stability**: <pre-1.0 | stable | deprecated>

## <Module / Component Name>
<one-paragraph description of what it does>

### Exported API
| Symbol | Signature | Purpose | Errors |
| --- | --- | --- | --- |
| ``parseAmount`` | ``(value): number`` | normalize raw input → 0 on bad input | never throws, never NaN |

### Invariants
<bullet list of guarantees this contract makes — e.g., "perPerson * people >= total">
``````

  (d) **``specs/<feature>/review-diagrams.md``** — at least one Mermaid component diagram + one Mermaid sequence diagram for the canonical user flow. Even simple features benefit. Format (outer fence uses 4 backticks so the inner Mermaid 3-backtick fences nest cleanly):

````````markdown
# Review Diagrams: <Feature Name>

**Feature**: <feature-ref>
**Phase**: pre-implementation (planning artifact for reviewer)

## Component diagram
``````mermaid
flowchart LR
  Inputs[User Inputs] --> Engine[Pure Calc Module]
  Engine --> Render[DOM Renderer]
  Render --> UI[Page]
``````

## Sequence: <canonical user flow>
``````mermaid
sequenceDiagram
  participant User
  participant UI
  participant Engine
  User->>UI: types bill amount
  UI->>Engine: calculate(input)
  Engine-->>UI: {tip, total, perPerson}
  UI-->>User: renders formatted result
``````
````````

These four artifacts together address the empirical complaint from tip-calc-v2 dogfooding (2026-05-24): "I see only some of the md files compared to what we have in Specrew itself ... some should be there to assist the review after plan before implement." After ``/speckit.plan`` runs, verify each file exists and has substantive (not template-placeholder) content; commit them with the plan boundary. They become the foundation the human reviews to approve the ``before-implement`` gate.

53. **Structured verdict menu at every human-approval boundary stop (mandatory where available).** Core Specrew defines the response contract and allowed response shapes. The selected host package renders the interaction behavior below. Immediately AFTER you emit the human re-entry packet at a human-verdict gate, follow the host-rendered guidance:

``````text
What's your verdict?
  1. Approve as-is — proceed with the defaults
  2. Approve with instructions — proceed and carry the added instructions
  3. Send back — describe what to change before this boundary can advance
  4. Discuss prompt #N — discuss that prompt only, then return for explicit approval
``````

<<SPECREW_HOST_INTERACTION_GUIDANCE_BLOCK>>

Discussion is not approval unless the human clearly authorizes the boundary after the discussion. The goal is to let the human developer decide unresolved questions and approval boundaries while Specrew follows the lifecycle contract for the selected host/runtime.
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
        [System.Collections.IDictionary]$SquadModelOverrides,
        [string]$ApprovalOperatorNote,
        [AllowNull()][pscustomobject]$RecoverySession
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
    
    # Feature 049 Iteration 003 (FR-026) + Iteration 005 (FR-032/FR-038): current-user Crew Interaction Profile.
    # This is soft, current-user collaboration guidance for all agents — not shared project truth.
    $userProfile = Get-UserProfile
    if ($null -ne $userProfile) {
        $summaryLines.Add('## Crew Interaction Profile (current user)') | Out-Null
        $profileSummary = Show-UserProfileSummary -Profile $userProfile
        foreach ($line in $profileSummary -split "`n") {
            if (-not [string]::IsNullOrWhiteSpace($line)) {
                $summaryLines.Add($line) | Out-Null
            }
        }
        $summaryLines.Add('') | Out-Null
    }
    
    $summaryLines.Add('## Launch Contract') | Out-Null
    $summaryLines.Add(("- **Approval Mode**: {0}" -f $ApprovalMode)) | Out-Null
    $summaryLines.Add(("- **Launch Mode**: {0}" -f $LaunchMode)) | Out-Null
    $summaryLines.Add(("- **Host Autopilot** (Copilot --autopilot / Codex --dangerously-bypass-approvals-and-sandbox; Claude has no equivalent): {0}" -f $UseAutopilot)) | Out-Null
    $summaryLines.Add(("- **Operator Note**: {0}" -f $ApprovalOperatorNote)) | Out-Null
    $summaryLines.Add('') | Out-Null
    if ($null -ne $RecoverySession) {
        $summaryLines.Add('## Recovery') | Out-Null
        $summaryLines.Add(("- **Entry Mode**: {0}" -f $RecoverySession.entry_mode)) | Out-Null
        $summaryLines.Add(("- **Selected Choice**: {0}" -f $(if ($RecoverySession.selected_choice) { $RecoverySession.selected_choice } else { '(none)' }))) | Out-Null
        $summaryLines.Add(("- **Bypass Gate**: {0}" -f $RecoverySession.bypass_gate)) | Out-Null
        $summaryLines.Add(("- **Approval Mode Changed**: {0}" -f $RecoverySession.approval_mode_changed)) | Out-Null
        $summaryLines.Add(("- **Next Action**: {0}" -f $RecoverySession.next_action_message)) | Out-Null
        $summaryLines.Add('') | Out-Null
    }
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
        [pscustomobject]$DeliveryGuidance,
        [string]$ApprovalOperatorNote,
        [AllowNull()][pscustomobject]$SessionState,
        [AllowNull()][pscustomobject]$RecoverySession,
        [string]$PostRestartDirective = '',
        [bool]$BypassBoundaryEnforcement = $false,
        [AllowNull()][string]$BoundaryBypassReason,
        [AllowNull()][string]$SelectedHost,
        [AllowNull()][string]$CrewRuntimeStatus,
        [AllowNull()][string]$RuntimeClass,
        [AllowNull()][string]$SpecrewRuntimeVersion,
        [AllowNull()][System.Collections.IDictionary]$AvailableHostsMap,
        [AllowNull()][string]$HostResolution
    )

    $specrewRoot = Join-Path $ResolvedProjectPath '.specrew'
    $promptPath = Join-Path $specrewRoot 'last-start-prompt.md'
    $contextPath = Join-Path $specrewRoot 'start-context.json'
    $summaryPath = Join-Path $specrewRoot 'start-summary.md'
    $existingStartContextState = Get-SpecrewStartContextState -ProjectRoot $ResolvedProjectPath
    $existingBoundaryEnforcement = if ($existingStartContextState.Context.Contains('boundary_enforcement')) { $existingStartContextState.Context['boundary_enforcement'] } else { $null }
    $resolvedBoundaryPolicyClasses = Get-SpecrewBoundaryPolicyClassMap -ProjectRoot $ResolvedProjectPath

    # Get current HEAD for baseline tracking
    $currentHead = $null
    try {
        $currentHead = & git -C $ResolvedProjectPath rev-parse HEAD 2>&1
        if ($LASTEXITCODE -ne 0) {
            $currentHead = $null
        }
    }
    catch {
        $currentHead = $null
    }

    # Get baseline commit and check for session-loaded file changes
    $baselineCommit = Get-BaselineCommitHash -ResolvedProjectPath $ResolvedProjectPath
    $changedFiles = @(Test-SessionLoadedFilesChanged -ResolvedProjectPath $ResolvedProjectPath -BaselineCommitHash $baselineCommit)
    $restartTriggerFiles = @(Get-RestartTriggerFiles -ResolvedProjectPath $ResolvedProjectPath -BaselineCommitHash $baselineCommit -ChangedFiles $changedFiles)
    $hasChanges = ($restartTriggerFiles.Count -gt 0)
    $templateRefreshArtifacts = @(Get-UnresolvedTemplateRefreshArtifacts -ResolvedProjectPath $ResolvedProjectPath)

    # Build frontmatter with baseline hash and changed files visibility
    $frontmatterLines = @('---')
    if ($null -ne $currentHead -and $currentHead -match '^[0-9a-f]{40}$') {
        $frontmatterLines += "baseline_commit_hash: $currentHead"
    }
    if ($null -ne $SessionState) {
        $frontmatterLines += ('session_state_active: {0}' -f $SessionState.active)
        $frontmatterLines += ('session_state_boundary: {0}' -f $SessionState.boundary_type)
        $frontmatterLines += ('session_state_feature: {0}' -f $(if ($SessionState.feature_ref) { $SessionState.feature_ref } else { '(none)' }))
        $frontmatterLines += ('session_state_feature_path: {0}' -f $(if ($SessionState.feature_path) { $SessionState.feature_path } else { '(none)' }))
        $frontmatterLines += ('session_state_iteration: {0}' -f $(if ($SessionState.iteration_number) { $SessionState.iteration_number } else { '(none)' }))
        $frontmatterLines += ('session_state_task: {0}' -f $(if ($SessionState.task_id) { $SessionState.task_id } else { '(none)' }))
        $frontmatterLines += ('session_state_auth_commit: {0}' -f $(if ($SessionState.auth_commit_hash) { $SessionState.auth_commit_hash } else { '(none)' }))
        $frontmatterLines += ('session_state_recorded_at: {0}' -f $SessionState.recorded_at)
    }
    if ($hasChanges) {
        $frontmatterLines += 'session_loaded_files_changed:'
        foreach ($file in $restartTriggerFiles) {
            $frontmatterLines += "  - $file"
        }
    }
    $frontmatterLines += '---'
    $frontmatterBlock = ($frontmatterLines -join [Environment]::NewLine)

    # Build directive blocks
    $directiveBlocks = @()

    # Prepend custom post-restart directive if provided
    if (-not [string]::IsNullOrWhiteSpace($PostRestartDirective)) {
        $directiveBlocks += @"

## Post-Restart Directive

$PostRestartDirective
"@
    }

    if ($BypassBoundaryEnforcement) {
        $directiveBlocks += @"

## Boundary Enforcement Bypass

[BYPASS ACTIVE] Boundary enforcement is bypassed for this session.
Reason: $BoundaryBypassReason
"@
    }

    $recoveryPromptBlock = Get-CoordinatorRecoveryPromptBlock -RecoverySession $RecoverySession
    if (-not [string]::IsNullOrWhiteSpace($recoveryPromptBlock)) {
        $directiveBlocks += ([Environment]::NewLine + $recoveryPromptBlock)
    }

    # Inject pause-and-confirm directive if session-loaded files changed
    if ($hasChanges) {
        $fileListFormatted = ($restartTriggerFiles | ForEach-Object { "- $_" }) -join [Environment]::NewLine
        $directiveBlocks += @"

## PAUSE-AND-CONFIRM: Session-Loaded Files Changed

**Session-loaded files have changed since the last run.** Review the changes below and provide any additional context or directives before continuing.

### Changed Files

$fileListFormatted

**What to do next:**
- Type **CONFIRM** to continue with the lifecycle as planned
- OR provide a directive to adjust the approach (e.g., "Skip iteration planning and go directly to implementation")
- OR provide context about the changes (e.g., "The agent charter was updated to improve escalation handling")
"@
    }

    if ($templateRefreshArtifacts.Count -gt 0) {
        $artifactListFormatted = ($templateRefreshArtifacts | ForEach-Object { "- $($_.RelativePath)" }) -join [Environment]::NewLine
        $directiveBlocks += @"

## ACTION REQUIRED: Unresolved Template Refresh Artifacts

specrew update left $($templateRefreshArtifacts.Count) unresolved template-refresh artifact(s). Review these before continuing:

$artifactListFormatted

- For .conflict artifacts, guide the user through accept-new, keep-user, or manual-resolve.
- For .deletion artifacts, review whether the preserved project file should be kept, archived, or removed manually.
"@
    }

    # Combine all parts: frontmatter + directives + original prompt
    $promptContentWithFrontmatter = $frontmatterBlock + [Environment]::NewLine + ($directiveBlocks -join '') + [Environment]::NewLine + $PromptContent

    Write-Utf8FileAtomic -Path $promptPath -Content $promptContentWithFrontmatter

    $context = [ordered]@{
        schema           = if ($null -ne $existingBoundaryEnforcement) { 'v2' } else { 'v1' }
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
        session_state    = if ($null -ne $SessionState) {
            [ordered]@{
                active           = ($SessionState.active -eq 'true')
                boundary_type    = $SessionState.boundary_type
                feature_ref      = $SessionState.feature_ref
                feature_path     = $SessionState.feature_path
                iteration_number = $SessionState.iteration_number
                task_id          = $SessionState.task_id
                auth_commit_hash = $SessionState.auth_commit_hash
                recorded_at      = $SessionState.recorded_at
            }
        }
        else {
            $null
        }
        recovery_session = if ($null -ne $RecoverySession) {
            [ordered]@{
                entry_mode            = $RecoverySession.entry_mode
                stale_reasons         = @($RecoverySession.stale_reasons)
                choice_set            = @($RecoverySession.choice_set)
                selected_choice       = $RecoverySession.selected_choice
                bypass_gate           = $RecoverySession.bypass_gate
                approval_mode_changed = $RecoverySession.approval_mode_changed
                next_action_message   = $RecoverySession.next_action_message
            }
        }
        else {
            $null
        }
        squad_model_overrides = $SquadModelOverrides
        prompt_path      = $promptPath
        summary_path     = $summaryPath
        generated_at_utc = [DateTime]::UtcNow.ToString('o')
        # F-040: per-host launch metadata (FR-006)
        specrew_version  = if ([string]::IsNullOrWhiteSpace($SpecrewRuntimeVersion)) { $null } else { $SpecrewRuntimeVersion }
        selected_host    = if ([string]::IsNullOrWhiteSpace($SelectedHost)) { 'copilot' } else { $SelectedHost.ToLowerInvariant() }
        available_hosts  = if ($null -ne $AvailableHostsMap) {
            $hostsOrdered = [ordered]@{}
            foreach ($key in $AvailableHostsMap.Keys) { $hostsOrdered[$key] = [bool]$AvailableHostsMap[$key] }
            $hostsOrdered
        }
        else {
            $null
        }
        crew_runtime_status = if ([string]::IsNullOrWhiteSpace($CrewRuntimeStatus)) { 'bootstrap_only' } else { $CrewRuntimeStatus }
        runtime_class = if ([string]::IsNullOrWhiteSpace($RuntimeClass)) { 'non-Squad' } else { $RuntimeClass }
        # F-043 FR-012: record HOW the host was resolved + the alternatives at probe time
        host_resolution = if (-not [string]::IsNullOrWhiteSpace($HostResolution)) { $HostResolution } else { $null }
    }

    # Feature 049 Iteration 003 (FR-026) + Iteration 005 (FR-038/FR-040): surface the resolved
    # current-user Crew Interaction Profile as SOFT runtime guidance, explicitly not shared project
    # truth, and applied hard only inside /speckit.specify. Stable persisted keys + persona IDs preserved.
    $userProfile = Get-UserProfile
    if ($null -ne $userProfile) {
        $context['user_profile'] = New-CrewInteractionProfileSessionContext -Profile $userProfile
    }

    if ($null -ne $existingBoundaryEnforcement) {
        $boundaryEnforcementForContext = [ordered]@{}
        $existingBoundaryMap = if ($existingBoundaryEnforcement -is [System.Collections.IDictionary]) {
            $existingBoundaryEnforcement
        }
        else {
            $existingBoundaryEnforcement | ConvertTo-Json -Depth 12 | ConvertFrom-Json -AsHashtable -Depth 12
        }

        foreach ($entry in $existingBoundaryMap.GetEnumerator()) {
            $boundaryEnforcementForContext[$entry.Key] = $entry.Value
        }
        $boundaryEnforcementForContext['policy_classes'] = $resolvedBoundaryPolicyClasses
        $context['boundary_enforcement'] = $boundaryEnforcementForContext
    }

    $context = $context | ConvertTo-Json -Depth 12

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
            -SquadModelOverrides $SquadModelOverrides `
            -ApprovalOperatorNote $ApprovalOperatorNote `
            -RecoverySession $RecoverySession)

    # Bootstrap boundary_enforcement on every start (Fix following F-040 calc-v2 dogfooding 2026-05-23).
    # Previously this was gated on $SessionState -ne $null, which meant greenfield-new projects never
    # got the boundary_enforcement block written. Any subsequent Test-SpecrewBoundaryAuthorization call
    # then threw "Boundary enforcement state is missing from '<context>'. Run the migration flow from
    # specrew start before crossing '<boundary>'." — even though the user HAD run specrew start.
    $effectiveBoundaryEnforcement = Get-SpecrewBoundaryEnforcementState -ProjectRoot $ResolvedProjectPath
    if ($effectiveBoundaryEnforcement.NeedsMigration) {
        $boundaryTypeForInit = if ($null -ne $SessionState) { $SessionState.boundary_type } else { $null }
        Initialize-SpecrewBoundaryEnforcementState -ProjectRoot $ResolvedProjectPath -CurrentBoundary $boundaryTypeForInit | Out-Null
        if ($null -ne $SessionState) {
            # Real schema-migration from a session that pre-dates schema v2 — record it in the ledger.
            Add-SpecrewBoundaryEnforcementLedgerEntry -ProjectRoot $ResolvedProjectPath -Boundary $SessionState.boundary_type -EnforcementAction 'migration' -CurrentBoundary $SessionState.boundary_type -RequestedBoundary $null -LaunchMode $LaunchMode -Reason 'Migrated start-context.json to schema v2 boundary_enforcement state.'
        }
        # Greenfield-new: no migration ledger entry needed — the block is being written for the
        # first time in a brand-new project, which is normal lifecycle initialization, not a fix-up.
    }

    if ($BypassBoundaryEnforcement) {
        $runtimeContextState = Get-SpecrewStartContextState -ProjectRoot $ResolvedProjectPath
        $runtimeSessionId = if ($runtimeContextState.Context.Contains('generated_at_utc')) { [string]$runtimeContextState.Context['generated_at_utc'] } else { [guid]::NewGuid().ToString() }
        Add-SpecrewBoundaryBypassRecord -ProjectRoot $ResolvedProjectPath -SessionId $runtimeSessionId -Reason $BoundaryBypassReason -Boundary $(if ($null -ne $SessionState) { $SessionState.boundary_type } else { $null }) -LaunchMode $LaunchMode -AgentResponseSnippet '[BYPASS ACTIVE] specrew start session bootstrap' -AuthCommitHash $(if ($null -ne $SessionState) { $SessionState.auth_commit_hash } else { $null }) | Out-Null
        Add-SpecrewBoundaryEnforcementLedgerEntry -ProjectRoot $ResolvedProjectPath -Boundary $(if ($null -ne $SessionState) { $SessionState.boundary_type } else { 'before-implement' }) -EnforcementAction 'bypassed' -CurrentBoundary $(if ($null -ne $SessionState) { $SessionState.boundary_type } else { $null }) -RequestedBoundary $(if ($null -ne $SessionState) { $SessionState.boundary_type } else { $null }) -LaunchMode $LaunchMode -AgentResponseSnippet '[BYPASS ACTIVE] specrew start session bootstrap' -Reason $BoundaryBypassReason
    }

    return [pscustomobject]@{
        PromptPath               = $promptPath
        ContextPath              = $contextPath
        SummaryPath              = $summaryPath
        TemplateRefreshArtifacts = $templateRefreshArtifacts
    }
}

function Get-DisplayRelativePath {
    param(
        [string]$ProjectRoot,
        [string]$ResolvedPath
    )

    $trimmedProjectRoot = $ProjectRoot.TrimEnd('\', '/')
    if ($ResolvedPath.StartsWith($trimmedProjectRoot, [System.StringComparison]::OrdinalIgnoreCase)) {
        $relativePath = $ResolvedPath.Substring($trimmedProjectRoot.Length).TrimStart('\', '/')
        if (-not [string]::IsNullOrWhiteSpace($relativePath)) {
            return $relativePath
        }
    }

    return $ResolvedPath
}

function Get-DisplayPathFromProjectRoot {
    param(
        [string]$ResolvedProjectPath,
        [string]$Path
    )

    $projectRoot = [System.IO.Path]::GetFullPath($ResolvedProjectPath)
    $resolvedPath = [System.IO.Path]::GetFullPath($Path)
    return Get-DisplayRelativePath -ProjectRoot $projectRoot -ResolvedPath $resolvedPath
}

function Get-HostBootstrapInput {
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

function Get-SpecrewHostLaunchInvocation {
    <#
    .SYNOPSIS
    Build the per-host launch invocation (Binary + Args) for the selected host — registry-driven (Phase C refactor).
    Per F-040 research.md Task 1 (verified per-host CLI surfaces).

    .DESCRIPTION
    Delegates to hosts/<kind>/handlers.ps1 New-<Kind>LaunchInvocation via Invoke-HostHandler.
    Adding a new host = creating hosts/<kind>/ — no edits to this function. The ValidateSet
    accepts every registered host kind; the legacy 3-host limitation is removed.
    #>
    param(
        [Parameter(Mandatory = $true)]
        [ValidateSet('copilot', 'claude', 'codex', 'antigravity', 'cursor')]
        [string]$HostKind,

        [Parameter(Mandatory = $true)]
        [string]$ResolvedProjectPath,

        [Parameter(Mandatory = $true)]
        [string]$BootstrapPrompt,

        [Parameter(Mandatory = $true)]
        [string]$Agent,

        [bool]$AllowAll = $false,

        [bool]$UseAutopilot = $false,

        [bool]$UseRemote = $false
    )

    return Invoke-HostHandler -Kind $HostKind -ContractFunction NewLaunchInvocation -Arguments @{
        ProjectPath  = $ResolvedProjectPath
        Prompt       = $BootstrapPrompt
        Agent        = $Agent
        AllowAll     = $AllowAll
        UseAutopilot = $UseAutopilot
        UseRemote    = $UseRemote
    }
}

function Get-ManualLaunchCommand {
    <#
    .SYNOPSIS
    Generate a printable, host-aware manual launch command string.
    Name retained for back-compat — covers all hosts now.
    #>
    param(
        [string]$ResolvedProjectPath,
        [string]$PromptPath,
        [string]$ContextPath,
        [string]$Agent,
        [bool]$AllowAll,
        [bool]$UseAutopilot,
        [bool]$RequireInteractiveIntake,
        [string]$HostKind = 'copilot'
    )

    $bootstrapInput = Get-HostBootstrapInput -ResolvedProjectPath $ResolvedProjectPath -PromptPath $PromptPath -ContextPath $ContextPath -RequireInteractiveIntake $RequireInteractiveIntake

    $invocation = Get-SpecrewHostLaunchInvocation `
        -HostKind $HostKind `
        -ResolvedProjectPath $ResolvedProjectPath `
        -BootstrapPrompt $bootstrapInput `
        -Agent $Agent `
        -AllowAll $AllowAll `
        -UseAutopilot $UseAutopilot

    $binary = Get-SpecrewHostBinary -HostKind $HostKind
    # Quote every arg whose preceding token introduces a value (`--agent`, `--add-dir`, `-i`, `-p`, `--cd`).
    # Flag tokens (start with `-`) stay unquoted; value tokens stay quoted for unambiguous copy-paste.
    $quotedArgs = @()
    $argList = @($invocation.Args)
    for ($i = 0; $i -lt $argList.Count; $i++) {
        $arg = $argList[$i]
        if ($arg.StartsWith('-')) {
            $quotedArgs += $arg
        }
        else {
            $quotedArgs += "'" + $arg.Replace("'", "''") + "'"
        }
    }
    return "$binary $($quotedArgs -join ' ')"
}

function Get-AllowAllRuntimePlan {
    param([bool]$AllowAll)

    return [pscustomobject]@{
        PassAllowAll        = $AllowAll
        ApprovalMode        = if ($AllowAll) { 'allow-all' } else { 'prompt-approvals' }
        DisplayMode         = if ($AllowAll) { 'allow-all' } else { 'prompt-approvals' }
        SuppressionNote     = $null
        ApprovalOperatorNote = if ($AllowAll) {
            'allow-all controls tool-call approval only; it does not bypass lifecycle boundary approval.'
        }
        else {
            'prompt-approvals keeps the host CLI permission prompts interactive throughout the session.'
        }
    }
}

function Get-SpecrewCrewRuntimeStatusForLaunch {
    param(
        [string]$SelectedHost,
        [string]$Agent
    )

    if ((-not [string]::IsNullOrWhiteSpace($SelectedHost)) -and
        $SelectedHost.ToLowerInvariant() -eq 'copilot' -and
        (-not [string]::IsNullOrWhiteSpace($Agent)) -and
        $Agent.ToLowerInvariant() -eq 'squad') {
        return 'squad-runtime'
    }

    return 'bootstrap_only'
}

function Start-HostSession {
    <#
    .SYNOPSIS
    Launch the selected host (copilot/claude/codex) with Specrew's bootstrap context.
    Per F-040: dispatcher uses Get-SpecrewHostLaunchInvocation to build per-host argv.
    Name retained for back-compat — handles all three hosts now.
    #>
    param(
        [string]$ResolvedProjectPath,
        [string]$PromptPath,
        [string]$ContextPath,
        [string]$Agent,
        [bool]$AllowAll,
        [bool]$SameWindow,
        [bool]$UseAutopilot,
        [bool]$RequireInteractiveIntake,
        [string]$HostKind = 'copilot'
    )

    $hostBinary = Get-SpecrewHostBinary -HostKind $HostKind
    $hostCommand = Get-Command $hostBinary -ErrorAction SilentlyContinue
    if (-not $hostCommand) {
        return $false
    }

    $bootstrapInput = Get-HostBootstrapInput -ResolvedProjectPath $ResolvedProjectPath -PromptPath $PromptPath -ContextPath $ContextPath -RequireInteractiveIntake $RequireInteractiveIntake

    $invocation = Get-SpecrewHostLaunchInvocation `
        -HostKind $HostKind `
        -ResolvedProjectPath $ResolvedProjectPath `
        -BootstrapPrompt $bootstrapInput `
        -Agent $Agent `
        -AllowAll $AllowAll `
        -UseAutopilot $UseAutopilot

    foreach ($notice in $invocation.Notices) {
        if (-not [string]::IsNullOrWhiteSpace($notice)) {
            Write-Info ("[host-flag] {0}" -f $notice)
        }
    }

    $launchArgs = @($invocation.Args)
    $resolvedBinary = $invocation.Binary

    if ($IsWindows) {
        $quotedProjectPath = $ResolvedProjectPath.Replace("'", "''")
        $quotedBinary = $resolvedBinary.Replace("'", "''")
        $launchArgsLiteral = ($launchArgs | ForEach-Object {
            "'" + ($_.ToString().Replace("'", "''")) + "'"
        }) -join ', '
        $launchScript = @'
Set-Location -LiteralPath '{0}'
$launchArgs = @({1})
& '{2}' @launchArgs
'@ -f $quotedProjectPath, $launchArgsLiteral, $quotedBinary

        if ($SameWindow) {
            $process = Start-Process -FilePath 'pwsh' -ArgumentList @('-NoLogo', '-NoProfile', '-ExecutionPolicy', 'Bypass', '-Command', $launchScript) -WorkingDirectory $ResolvedProjectPath -NoNewWindow -PassThru -Wait
            return ($null -ne $process -and $process.ExitCode -eq 0)
        }

        Start-Process -FilePath 'pwsh' -ArgumentList @('-NoLogo', '-NoExit', '-NoProfile', '-ExecutionPolicy', 'Bypass', '-Command', $launchScript) -WorkingDirectory $ResolvedProjectPath | Out-Null
        return $true
    }

    # Linux/macOS: defer the actual launch to the Specrew module function so
    # it happens in PowerShell FUNCTION context (which preserves TTY on Linux)
    # instead of SCRIPT context (which strips TTY for native command children).
    # Mechanism unchanged from pre-F-040; only the args list is now per-host.
    $deferredLaunchPath = $env:SPECREW_DEFERRED_LAUNCH_FILE
    if ([string]::IsNullOrWhiteSpace($deferredLaunchPath)) {
        # Direct script invocation (not via the module proxy). Fall back to
        # in-script launch — TUI won't render but the command will run.
        Push-Location -LiteralPath $ResolvedProjectPath
        try {
            & $resolvedBinary @launchArgs
            return $true
        }
        finally {
            Pop-Location
        }
    }

    $launchInfo = [pscustomobject]@{
        CopilotPath      = $resolvedBinary
        CopilotArgs      = @($launchArgs)
        WorkingDirectory = $ResolvedProjectPath
        HostKind         = $HostKind.ToLowerInvariant()
    }
    $launchInfo | ConvertTo-Json -Depth 5 | Set-Content -LiteralPath $deferredLaunchPath -Encoding UTF8
    return $true
}

if ($Help) {
    Show-Usage
    exit 0
}

$resolvedProjectPath = Resolve-ProjectPath -Path $ProjectPath

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

# Feature 049 Iteration 003: User profile first-run check (FR-023, FR-024, FR-026)
# Check for user profile and prompt on first run
if (-not (Test-UserProfileExists)) {
    Write-Host ""
    Write-Host "First-time setup: Configuring your Crew Interaction Profile..." -ForegroundColor Cyan
    Write-Host ""
    
    $expertiseDials = Invoke-FirstRunExpertisePrompt -NonInteractive:([Console]::IsInputRedirected)
    Save-UserProfile -ExpertiseDials $expertiseDials
    
    Write-Host ""
    Write-Host "Setup complete! Starting Specrew..." -ForegroundColor Green
    Write-Host ""
}

if ($AllowAll -and $PromptApprovals) {
    Write-Error-Message "Use either --allow-all or --prompt-approvals, not both."
    exit 1
}

# F-040 + F-043: Host selection chain (per F-043 spec FR-002)
#   priority order: --host flag → host-history last_selected_host → first-run probe → exit-with-guidance (non-TTY)
$hostHistoryHelperPath = Join-Path $PSScriptRoot 'internal\host-history.ps1'
if (Test-Path -LiteralPath $hostHistoryHelperPath -PathType Leaf) {
    . $hostHistoryHelperPath
}
$hostRuntimeInventoryHelperPath = Join-Path $PSScriptRoot 'internal\host-runtime-inventory.ps1'
if (Test-Path -LiteralPath $hostRuntimeInventoryHelperPath -PathType Leaf) {
    . $hostRuntimeInventoryHelperPath
}

# Proposal 108 Slice 9: crew-bootstrap dispatcher (translates .specrew/team/agents/<role>.md
# to selected host's native location every launch — keeps per-host views in sync with the canonical).
$crewBootstrapHelperPath = Join-Path $PSScriptRoot 'init\crew-bootstrap.ps1'
if (Test-Path -LiteralPath $crewBootstrapHelperPath -PathType Leaf) {
    . $crewBootstrapHelperPath
}

$hostResolution = $null   # tracks how the host was resolved, for FR-012 start-context.json

if (-not [string]::IsNullOrWhiteSpace($HostKind)) {
    # 1. --host flag explicitly provided
    $selectedHost = $HostKind.ToLowerInvariant()
    $hostResolution = 'flag'
}
else {
    # 2. Try host-history.json last_selected_host (F-043 FR-002)
    $historyResult = $null
    if (Get-Command Resolve-SpecrewHostFromHistory -ErrorAction SilentlyContinue) {
        $historyResult = Resolve-SpecrewHostFromHistory -ProjectPath $resolvedProjectPath
    }

    if ($null -ne $historyResult -and $historyResult.Source -eq 'last-selected') {
        $selectedHost = $historyResult.Host
        $hostResolution = 'last-selected'
        Write-Info ("Host resolved from .specrew/host-history.json: {0} (use --host to override)" -f $selectedHost)
    }
    elseif (Get-Command Invoke-SpecrewFirstRunHostProbe -ErrorAction SilentlyContinue) {
        # 3. First-run probe (FR-003 + FR-013)
        $probe = Invoke-SpecrewFirstRunHostProbe
        switch ($probe.Source) {
            'auto-single-available' {
                $selectedHost = $probe.Host
                $hostResolution = 'auto-single-available'
                Write-Info ("Auto-selected the only available host: {0}" -f $selectedHost)
            }
            'first-run-prompt' {
                $selectedHost = $probe.Host
                $hostResolution = 'first-run-prompt'
                # Probe already wrote the selection to console; no extra log line needed
            }
            'non-interactive-no-default' {
                # FR-013 non-TTY exit with actionable guidance, BUT dry-run (-NoLaunch)
                # callers still need the host gate to fall through to a default so that
                # baseline-tracking + start-prompt artifacts are still written. Same
                # rationale as the missing-host check below (lines ~3771).
                if ($NoLaunch) {
                    $selectedHost = 'copilot'
                    $hostResolution = 'no-launch-default'
                }
                else {
                    Write-Error-Message ("Non-interactive run with no --host flag and no last-selected host on file.")
                    Write-Error-Message ("Available hosts on PATH: {0}" -f ($probe.Available -join ', '))
                    Write-Error-Message ("Pass --host <kind> explicitly (e.g., 'specrew start --host copilot') or run interactively to pick a host.")
                    exit 1
                }
            }
            'no-hosts-available' {
                # FR-003 zero-hosts case; same -NoLaunch carve-out as above
                if ($NoLaunch) {
                    $selectedHost = 'copilot'
                    $hostResolution = 'no-launch-default'
                }
                else {
                    Write-Error-Message 'No supported host CLIs found on PATH.'
                    foreach ($k in Get-SpecrewSupportedHostKinds) {
                        Write-Error-Message ("  " + (Get-SpecrewHostInstallGuidance -HostKind $k))
                    }
                    exit 1
                }
            }
            default {
                # Defensive fallback: shouldn't reach here; fall back to copilot
                $selectedHost = 'copilot'
                $hostResolution = 'fallback-copilot'
            }
        }
    }
    else {
        # Legacy path (host-history helper not loaded; pre-F-043 behavior)
        $selectedHost = 'copilot'
        $hostResolution = 'legacy-default'
    }
}

$availableHostsMap = Get-SpecrewAvailableHosts

# Reject deferred hosts with explicit guidance per research.md Task 3
if ($selectedHost -in (Get-SpecrewDeferredHostKinds)) {
    Write-Error-Message (Get-SpecrewDeferredHostGuidance -HostKind $selectedHost)
    exit 1
}

# Validate the host kind is supported
if ($selectedHost -notin (Get-SpecrewSupportedHostKinds)) {
    $supported = (Get-SpecrewSupportedHostKinds) -join ', '
    $deferred = (Get-SpecrewDeferredHostKinds) -join ', '
    Write-Error-Message ("Unsupported --host '{0}'. Supported: {1}. Reserved-but-deferred: {2}." -f $selectedHost, $supported, $deferred)
    exit 1
}

# Probe PATH for selected host. With --no-launch we still want to write the
# handoff prompt/context/summary artifacts (the user may install the host CLI
# later and run the printed manual launch command), so the missing-host check
# is enforced ONLY when an actual launch is requested. Pre-F-040 behavior:
# Start-CopilotSession returned $false on missing copilot, then the no-launch
# path printed the manual command anyway. F-040 preserves that contract by
# deferring the missing-host fail-fast to the launch path below.
if (-not $availableHostsMap[$selectedHost] -and -not $NoLaunch) {
    Write-Error-Message (Get-SpecrewHostInstallGuidance -HostKind $selectedHost)
    exit 1
}

# Skill catalog verification and repair. Missing roots are deployable gaps, not
# operator action items, so start repairs them before normal continuation.
$skillCatalogState = Get-SpecrewSkillCatalogState -ProjectPath $resolvedProjectPath
if ($skillCatalogState.HasMissingRoots) {
    Write-Info ("WARN: Skill catalog directories missing: {0}" -f (Format-SpecrewSkillCatalogRoots -Roots $skillCatalogState.MissingRoots))
    Write-Info "Attempting skill catalog auto-repair via bundled runtime deployment."
    try {
        $skillCatalogRepair = Invoke-SpecrewSkillCatalogRepair -ProjectPath $resolvedProjectPath
        foreach ($repairAction in @($skillCatalogRepair.Actions)) {
            if ($repairAction.PSObject.Properties['Action'] -and $repairAction.PSObject.Properties['Path']) {
                Write-Info ("Skill catalog repair: {0}: {1}" -f $repairAction.Action, $repairAction.Path)
            }
        }

        if ($skillCatalogRepair.AfterState.HasMissingRoots) {
            Write-Info ("WARN: Skill catalog auto-repair incomplete: {0}" -f (Format-SpecrewSkillCatalogRoots -Roots $skillCatalogRepair.AfterState.MissingRoots))
        }
        else {
            Write-Info "Skill catalog auto-repair completed."
        }
    }
    catch {
        Write-Info ("WARN: Skill catalog auto-repair failed: {0}" -f $_.Exception.Message)
    }
}

# Per-host skill verification (FR-009 non-fatal warning; FR-013 Codex informational note)
$skillCheck = Test-HostSkillRoot -HostKind $selectedHost -ProjectPath $resolvedProjectPath
foreach ($warning in $skillCheck.Warnings) {
    if ($warning -like 'INFO:*') {
        Write-Info $warning
    }
    else {
        Write-Info ("WARN: {0}" -f $warning)
    }
}

if ($BypassBoundaryEnforcement -and [string]::IsNullOrWhiteSpace($Reason)) {
    Write-Error-Message 'Boundary enforcement bypass requires --reason "<text>".'
    exit 1
}

if (-not $BypassBoundaryEnforcement -and -not [string]::IsNullOrWhiteSpace($Reason)) {
    Write-Error-Message "Use --reason only together with --bypass-boundary-enforcement."
    exit 1
}

if (-not [string]::IsNullOrWhiteSpace($RecoveryChoice) -and $RecoveryChoice -notin @('A', 'B', 'C')) {
    Write-Error-Message "Recovery choice must be A, B, or C."
    exit 1
}

if ($Recover -and -not [string]::IsNullOrWhiteSpace($RecoveryChoice)) {
    Write-Error-Message "Use either --recover or --recovery-choice, not both."
    exit 1
}

if ($NewWindow -and $SameWindow) {
    Write-Error-Message "Use either --new-window or --same-window, not both."
    exit 1
}

$staleSessionStateCheck = Test-SpecrewStaleSessionState -ProjectRoot $resolvedProjectPath
$validatedSessionState = $staleSessionStateCheck.SessionState
$recoverySession = $null
$recoveryDirective = $PostRestartDirective
$skipAutoResumeResolution = $false
$forceNoLaunch = $false

if ($Recover) {
    $recoveryReasons = if ($staleSessionStateCheck.Issues.Count -gt 0) {
        @($staleSessionStateCheck.Issues)
    }
    else {
        @('Recovery mode was requested explicitly by the operator.')
    }

    $recoverySession = New-SpecrewRecoverySession -EntryMode 'explicit-recover-flag' -StaleReasons $recoveryReasons -BypassGate $true -SelectedChoice $null -NextActionMessage 'Recovery mode is active. Review the stale-state evidence, choose whether to re-anchor or start fresh, and continue without changing approval behavior.'
    if (-not [string]::IsNullOrWhiteSpace($recoveryDirective)) {
        $recoveryDirective += [Environment]::NewLine + [Environment]::NewLine
    }
    $recoveryDirective += 'Recovery mode was entered with --recover. Bypass the stale-state gate, preserve the existing approval/autopilot behavior, and guide the operator through the next recovery action explicitly.'
}
elseif ($staleSessionStateCheck.IsStale) {
    Write-Output 'Stale state detected.'
    foreach ($issue in $staleSessionStateCheck.Issues) {
        Write-Output ("- {0}" -f $issue)
    }
    Write-Output 'Options:'
    Write-Output '  A) re-anchor to the correct feature'
    Write-Output '  B) create a new feature'
    Write-Output '  C) exit and manually fix state'

    $selectedRecoveryChoice = Read-SpecrewRecoveryChoice -PreferredChoice $RecoveryChoice
    $recoveryPlan = Resolve-SpecrewRecoverySelection -Choice $selectedRecoveryChoice -SessionState $validatedSessionState
    $recoverySession = New-SpecrewRecoverySession -EntryMode 'detected-stale-state' -StaleReasons @($staleSessionStateCheck.Issues) -BypassGate $false -SelectedChoice $selectedRecoveryChoice -NextActionMessage $recoveryPlan.NextActionMessage
    $ResumeFeature = $recoveryPlan.ResumeFeatureOverride
    $skipAutoResumeResolution = $recoveryPlan.SkipAutoResume
    $forceNoLaunch = $recoveryPlan.ForceNoLaunch
    if (-not [string]::IsNullOrWhiteSpace($recoveryDirective)) {
        $recoveryDirective += [Environment]::NewLine + [Environment]::NewLine
    }
    $recoveryDirective += $recoveryPlan.Directive
}

$versionMismatchWarning = Get-SpecrewVersionMismatchWarning -ProjectRoot $resolvedProjectPath
$psGalleryUpdateWarning = Get-PSGalleryUpdateWarning -ProjectRoot $resolvedProjectPath -SkipCheck:$SkipUpdateCheck

if ($FeatureRequest -and -not $ResumeFeature) {
    $resolvedFeaturePath = $null
}
elseif ($skipAutoResumeResolution) {
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

if ($null -eq $resolvedFeaturePath -and $null -ne $validatedSessionState -and -not [string]::IsNullOrWhiteSpace([string]$validatedSessionState.feature_path)) {
    if (Test-Path -LiteralPath ([string]$validatedSessionState.feature_path) -PathType Container) {
        $resolvedFeaturePath = [string]$validatedSessionState.feature_path
    }
}

$validatedSessionState = if ($null -ne $validatedSessionState -and $resolvedFeaturePath) {
    [pscustomobject]@{
        active           = if ($validatedSessionState.active) { $validatedSessionState.active } else { 'true' }
        boundary_type    = $validatedSessionState.boundary_type
        feature_ref      = if ($validatedSessionState.feature_ref) { $validatedSessionState.feature_ref } else { Split-Path -Leaf $resolvedFeaturePath }
        feature_path     = $resolvedFeaturePath
        iteration_number = $validatedSessionState.iteration_number
        task_id          = $validatedSessionState.task_id
        auth_commit_hash = $validatedSessionState.auth_commit_hash
        recorded_at      = $validatedSessionState.recorded_at
    }
}
else {
    $validatedSessionState
}

Invoke-SpecrewStartMultiSessionGuard -ProjectRoot $resolvedProjectPath -ResolvedFeaturePath $resolvedFeaturePath

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
$routingPlan = Get-DelegatedRoutingPlan -RoleAssignments $roleAssignments -AgentLookup $agentConfig -SelectedHost $HostKind
$squadModelOverrides = Set-SquadModelOverrides -Root $resolvedProjectPath -RoutingPlan $routingPlan
Write-DelegatedRoutingLedgerEntries -ResolvedProjectPath $resolvedProjectPath -RoutingPlan $routingPlan -SquadModelOverrides $squadModelOverrides
$requiresInteractiveIntake = ($mode -eq 'intake-or-resume' -and -not $FeatureRequest -and -not $resolvedFeaturePath)
# Default: gate-respecting mode. Specrew stops at every lifecycle gate for explicit human approval.
# Autopilot mode is opt-in via -Autonomous flag (or --autonomous CLI argument) for unattended runs
# such as overnight execution. Intake stage still requires interactive scope grounding regardless
# of -Autonomous, so Specrew never tries to auto-resolve initial scope decisions.
$useAutopilot = $Autonomous -and -not $requiresInteractiveIntake
$requestedAllowAll = if ($PromptApprovals) { $false } else { $true }
$allowAllRuntimePlan = Get-AllowAllRuntimePlan -AllowAll $requestedAllowAll
$approvalMode = $allowAllRuntimePlan.ApprovalMode
$approvalOperatorNote = if ($useAutopilot -and $approvalMode -eq 'allow-all') {
    'autopilot mode is on (Specrew advances through lifecycle gates without explicit approval) and allow-all is on (tool calls run without approval prompts). Unattended-run posture.'
}
elseif ($useAutopilot) {
    'autopilot mode is on (Specrew advances through lifecycle gates without explicit approval) but prompt-approvals is on (each tool call still prompts).'
}
elseif ($approvalMode -eq 'allow-all') {
    'gate-respecting mode (default): Specrew stops at every lifecycle approval boundary for human verdict. allow-all controls tool-call approval only; it does not bypass lifecycle boundary approval.'
}
else {
    'gate-respecting mode (default) plus prompt-approvals: Specrew stops at every lifecycle gate and the selected host prompts before each tool call.'
}
$launchMode = if ($NoLaunch -or $forceNoLaunch) { 'none' } elseif ($NewWindow -and $IsWindows) { 'new-window' } else { 'same-window' }
$crewRuntimeStatus = Get-SpecrewCrewRuntimeStatusForLaunch -SelectedHost $selectedHost -Agent $Agent
$runtimeClass = Get-SpecrewRuntimeClassForStatus -CrewRuntimeStatus $crewRuntimeStatus
$specrewRuntimeVersion = Get-InstalledSpecrewRuntimeVersion -ProjectRoot $resolvedProjectPath
$promptContent = Get-StartPrompt `
    -ResolvedProjectPath $resolvedProjectPath `
    -Mode $mode `
    -FeatureRequest $FeatureRequest `
    -ResolvedFeaturePath $resolvedFeaturePath `
    -TeamRoster $teamRoster `
    -RoutingPlan $routingPlan `
    -ProjectState $projectState `
    -BrownfieldDiscovery $brownfieldDiscovery `
    -DeliveryGuidance $deliveryGuidance `
    -SessionState $validatedSessionState `
    -RecoverySession $recoverySession

# F-040: apply per-host coordinator-prompt surgery (FR-011 universal header for all hosts;
# FR-012 Squad-runtime-path strip for non-Copilot; FR-014 Codex pwsh-form rewrite;
# release-closeout Step 11: host-accurate orientation rendered from selected host + runtime status)
$promptContent = Invoke-SpecrewCoordinatorPromptSurgery `
    -Prompt $promptContent `
    -HostKind $selectedHost `
    -CrewRuntimeStatus $crewRuntimeStatus `
    -SpecrewVersion $specrewRuntimeVersion `
    -LifecycleMode $mode `
    -FeatureRef $(if ($null -ne $validatedSessionState -and -not [string]::IsNullOrWhiteSpace([string]$validatedSessionState.feature_ref)) { [string]$validatedSessionState.feature_ref } elseif ($resolvedFeaturePath) { Split-Path -Leaf $resolvedFeaturePath } else { $null }) `
    -BoundaryType $(if ($null -ne $validatedSessionState -and -not [string]::IsNullOrWhiteSpace([string]$validatedSessionState.boundary_type)) { [string]$validatedSessionState.boundary_type } else { $null })

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
    -DeliveryGuidance $deliveryGuidance `
    -ApprovalOperatorNote $approvalOperatorNote `
    -SessionState $validatedSessionState `
    -RecoverySession $recoverySession `
    -PostRestartDirective $recoveryDirective `
    -BypassBoundaryEnforcement $BypassBoundaryEnforcement `
    -BoundaryBypassReason $Reason `
    -SelectedHost $selectedHost `
    -CrewRuntimeStatus $crewRuntimeStatus `
    -RuntimeClass $runtimeClass `
    -SpecrewRuntimeVersion $specrewRuntimeVersion `
    -AvailableHostsMap $availableHostsMap `
    -HostResolution $hostResolution

# F-043 FR-004: update host-history.json after host selection (any source)
if (Get-Command Update-SpecrewHostHistory -ErrorAction SilentlyContinue) {
    try {
        $hostInventory = $null
        if (Get-Command Get-SpecrewHostRuntimeInventory -ErrorAction SilentlyContinue) {
            $hostInventory = Get-SpecrewHostRuntimeInventory -ProjectPath $resolvedProjectPath
        }
        $crewInstalled = $false
        $crewPath = ''
        if ($null -ne $hostInventory -and $hostInventory.Contains($selectedHost)) {
            $crewInstalled = [bool]$hostInventory[$selectedHost].installed
            $crewPath = [string]$hostInventory[$selectedHost].path
        }
        $null = Update-SpecrewHostHistory `
            -ProjectPath $resolvedProjectPath `
            -SelectedHost $selectedHost `
            -CrewRuntimeInstalled $crewInstalled `
            -CrewRuntimePath $crewPath
    }
    catch {
        Write-Info ("WARN: Failed to update .specrew/host-history.json: {0}" -f $_.Exception.Message)
    }
}

# Proposal 108 Slice 9: deploy the selected host's Crew runtime from the canonical .specrew/team/.
# Translation runs every launch — cheap (~50ms for 5-7 files), keeps per-host view in sync.
if (Get-Command Invoke-CrewBootstrap -ErrorAction SilentlyContinue) {
    try {
        $crewResult = Invoke-CrewBootstrap -ProjectPath $resolvedProjectPath -HostKind $selectedHost
        $writeCount = @($crewResult.Actions | Where-Object { $_.Action -eq 'written' }).Count
        if ($writeCount -gt 0) {
            Write-Info ("Crew runtime synced: {0} agent file(s) written to {1}." -f $writeCount, $crewResult.CrewRuntimePath)
        }
        foreach ($notice in $crewResult.Notices) {
            Write-Info ("Crew runtime: {0}" -f $notice)
        }
    }
    catch {
        Write-Info ("WARN: Crew runtime sync failed for host '{0}': {1}" -f $selectedHost, $_.Exception.Message)
    }
}

Write-Success "Prepared Specrew start context."
if ($selectedHost -ne 'copilot') {
    Write-Info ("Selected host: {0} (non-Squad runtime; coordinator prompt rewritten per FR-011/FR-012)" -f $selectedHost)
}
$promptDisplayPath = Get-DisplayPathFromProjectRoot -ResolvedProjectPath $resolvedProjectPath -Path $artifactPaths.PromptPath
$contextDisplayPath = Get-DisplayPathFromProjectRoot -ResolvedProjectPath $resolvedProjectPath -Path $artifactPaths.ContextPath
$summaryDisplayPath = Get-DisplayPathFromProjectRoot -ResolvedProjectPath $resolvedProjectPath -Path $artifactPaths.SummaryPath
Write-Info ("Prompt:  {0}" -f $promptDisplayPath)
Write-Info ("Context: {0}" -f $contextDisplayPath)
Write-Info ("Summary: {0}" -f $summaryDisplayPath)
Write-Info ("Copilot approval mode: {0}" -f $allowAllRuntimePlan.DisplayMode)
if ($artifactPaths.TemplateRefreshArtifacts.Count -gt 0) {
    Write-Info ("Unresolved template-refresh artifacts detected: {0}" -f $artifactPaths.TemplateRefreshArtifacts.Count)
    foreach ($artifact in $artifactPaths.TemplateRefreshArtifacts) {
        Write-Info ("  - {0}" -f $artifact.RelativePath)
    }
}
if (-not [string]::IsNullOrWhiteSpace($versionMismatchWarning)) {
    Write-Output ("WARN: {0}" -f $versionMismatchWarning)
}
if (-not [string]::IsNullOrWhiteSpace($psGalleryUpdateWarning)) {
    Write-Output ("WARN: {0}" -f $psGalleryUpdateWarning)
}
if (-not $useAutopilot) {
    Write-Info 'Specrew auto-loads the bootstrap with -i and stays out of autopilot until the request is grounded.'
}
elseif ($approvalMode -eq 'allow-all') {
    Write-Info 'allow-all reduces tool-approval blocking after the request is grounded.'
}
if ($BypassBoundaryEnforcement) {
    Write-Info ("[BYPASS ACTIVE] Boundary enforcement is bypassed for this session only. Reason: {0}" -f $Reason)
}
if (-not [string]::IsNullOrWhiteSpace($allowAllRuntimePlan.SuppressionNote)) {
    Write-Info $allowAllRuntimePlan.SuppressionNote
}

if ($NoLaunch -or $forceNoLaunch) {
    Write-Info "Launch skipped by --no-launch."
    Write-Info ("Manual launch command (run from the project root; bootstrap is auto-loaded): {0}" -f (Get-ManualLaunchCommand -ResolvedProjectPath $resolvedProjectPath -PromptPath $artifactPaths.PromptPath -ContextPath $artifactPaths.ContextPath -Agent $Agent -AllowAll $allowAllRuntimePlan.PassAllowAll -UseAutopilot $useAutopilot -RequireInteractiveIntake $requiresInteractiveIntake -HostKind $selectedHost))
    exit 0
}

if ($launchMode -eq 'same-window') {
    $hostLabel = switch ($selectedHost) {
        'copilot' { "Copilot + $Agent" }
        'claude'  { 'Claude Code' }
        'codex'   { 'Codex CLI' }
        default   { $selectedHost }
    }
    Write-Info ("Delegating to {0} in the current terminal with auto-loaded bootstrap..." -f $hostLabel)
}
else {
    $hostLabel = switch ($selectedHost) {
        'copilot' { "Copilot + $Agent" }
        'claude'  { 'Claude Code' }
        'codex'   { 'Codex CLI' }
        default   { $selectedHost }
    }
    Write-Info ("Delegating to {0} in a new PowerShell window with auto-loaded bootstrap..." -f $hostLabel)
}

$hostStarted = Start-HostSession `
    -ResolvedProjectPath $resolvedProjectPath `
    -PromptPath $artifactPaths.PromptPath `
    -ContextPath $artifactPaths.ContextPath `
    -Agent $Agent `
    -AllowAll $allowAllRuntimePlan.PassAllowAll `
    -SameWindow ($launchMode -eq 'same-window') `
    -UseAutopilot $useAutopilot `
    -RequireInteractiveIntake $requiresInteractiveIntake `
    -HostKind $selectedHost

if (-not $hostStarted) {
    Write-Info ("{0} CLI was not available, so Specrew wrote a resume-safe handoff prompt instead." -f $selectedHost)
    Write-Info ("Manual launch command (run from {0}; bootstrap is auto-loaded): {1}" -f $resolvedProjectPath, (Get-ManualLaunchCommand -ResolvedProjectPath $resolvedProjectPath -PromptPath $artifactPaths.PromptPath -ContextPath $artifactPaths.ContextPath -Agent $Agent -AllowAll $allowAllRuntimePlan.PassAllowAll -UseAutopilot $useAutopilot -RequireInteractiveIntake $requiresInteractiveIntake -HostKind $selectedHost))
    exit 0
}

if ($launchMode -eq 'new-window') {
    Write-Success ("Delegated to Copilot + {0} in a new PowerShell window." -f $Agent)
    Write-Info "Continue the lifecycle in the new window. This terminal can stay open for reference."
}
