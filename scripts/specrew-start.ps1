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
    [switch]$AllowAll,
    [switch]$PromptApprovals,
    [switch]$Help,

    [Parameter(ValueFromRemainingArguments = $true)]
    [string[]]$CliArgs
)

function Convert-UnixStyleArguments {
    param(
        [string]$FeatureRequest,
        [string]$ProjectPath,
        [string]$ResumeFeature,
        [string]$Agent,
        [bool]$NoLaunch,
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
    -AllowAll $AllowAll.IsPresent `
    -PromptApprovals $PromptApprovals.IsPresent `
    -Help $Help.IsPresent `
    -CliArgs $CliArgs

$FeatureRequest = $parsedArgs.FeatureRequest
$ProjectPath = $parsedArgs.ProjectPath
$ResumeFeature = $parsedArgs.ResumeFeature
$Agent = $parsedArgs.Agent
$NoLaunch = [bool]$parsedArgs.NoLaunch
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
  -AllowAll | --allow-all                  Explicitly launch Copilot with --allow-all (default behavior)
  -PromptApprovals | --prompt-approvals    Keep Copilot's interactive approval prompts enabled
  -Help | --help                           Show this help message

 Notes:
   - Running specrew start with no arguments launches Squad in intake/resume mode.
   - Squad should continue any in-progress feature when possible, or gather the missing feature/fix details from the human developer.
   - A quoted feature request is optional shorthand for a new feature, not a full spec document.
   - Specrew launches Copilot from the target project directory and defaults to --allow-all to reduce approval blocking.
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

function Get-StartPrompt {
    param(
        [string]$ResolvedProjectPath,
        [string]$Mode,
        [string]$FeatureRequest,
        [string]$ResolvedFeaturePath
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

    return @"
You are Squad running inside a Specrew-bootstrapped repository.

Project root: $ResolvedProjectPath
Mode: $Mode
$featureLine
$requestLine

Follow the formal Specrew + Spec Kit lifecycle end to end:
1. Use the Spec Kit flow in order: speckit.specify -> speckit.clarify when needed -> speckit.plan -> speckit.tasks -> speckit.implement.
2. If Mode is new-feature, treat the provided text as a short plain-language request and start from specify. Do not expect the human to provide a full spec upfront.
3. If Mode is resume-feature, inspect the active feature artifacts and continue from the earliest incomplete phase without asking the human to restate the feature.
4. If Mode is intake-or-resume, first inspect the repository, .specify\feature.json, existing specs, and iteration artifacts. Continue any in-progress feature automatically. If there is no active work or the last feature is complete, ask the human whether they want to fix something or start a new feature, then gather only the missing information needed to begin specify.
5. Before starting a brand-new feature, inspect the current Squad roster and ask whether additional specialist team members are needed only when the existing baseline/supplemental crew appears insufficient or the human explicitly wants to add specialists.
6. Answer clarification questions yourself whenever repo context, existing artifacts, or reasonable defaults make the answer clear enough.
7. Only ask the human developer questions that are still unresolved and materially affect scope, behavior, governance, or UX.
8. Once clarifications are resolved and the spec/design is clear, continue automatically through planning, tasks, and implementation without waiting for the human to manually trigger each phase.
9. Preserve the canonical artifact chain on disk: specs/<feature>/spec.md, plan.md, tasks.md, and specs/<feature>/iterations/<NNN>/{plan.md,state.md,drift-log.md,review.md,retro.md} as phases progress.
10. Keep the spec authoritative, surface drift explicitly, and do not claim Spec-Kit/Specrew compliance if you bypass the lifecycle.

Your goal is to let the human developer primarily answer unresolved questions while Squad handles the rest of the lifecycle automatically.
"@
}

function Save-StartArtifacts {
    param(
        [string]$ResolvedProjectPath,
        [string]$PromptContent,
        [string]$Mode,
        [string]$FeatureRequest,
        [string]$ResolvedFeaturePath,
        [string]$Agent,
        [string]$ApprovalMode
    )

    $specrewRoot = Join-Path $ResolvedProjectPath '.specrew'
    $promptPath = Join-Path $specrewRoot 'last-start-prompt.md'
    $contextPath = Join-Path $specrewRoot 'start-context.json'

    [System.IO.File]::WriteAllText($promptPath, $PromptContent, [System.Text.UTF8Encoding]::new($false))

    $context = [ordered]@{
        mode             = $Mode
        feature_request  = $FeatureRequest
        feature_path     = $ResolvedFeaturePath
        agent            = $Agent
        approval_mode    = $ApprovalMode
        prompt_path      = $promptPath
        generated_at_utc = [DateTime]::UtcNow.ToString('o')
    } | ConvertTo-Json -Depth 5

    [System.IO.File]::WriteAllText($contextPath, $context, [System.Text.UTF8Encoding]::new($false))

    return [pscustomobject]@{
        PromptPath  = $promptPath
        ContextPath = $contextPath
    }
}

function Start-CopilotSession {
    param(
        [string]$ResolvedProjectPath,
        [string]$PromptContent,
        [string]$Agent,
        [bool]$AllowAll
    )

    $copilotCommand = Get-Command copilot -ErrorAction SilentlyContinue
    if (-not $copilotCommand) {
        return $false
    }

    $copilotArgs = @(
        '--agent', $Agent,
        '--autopilot',
        '--add-dir', $ResolvedProjectPath,
        '-i', $PromptContent
    )

    if ($AllowAll) {
        $copilotArgs += '--allow-all'
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

$effectiveAllowAll = if ($PromptApprovals) { $false } else { $true }
$approvalMode = if ($effectiveAllowAll) { 'allow-all' } else { 'prompt-approvals' }

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
$promptContent = Get-StartPrompt `
    -ResolvedProjectPath $resolvedProjectPath `
    -Mode $mode `
    -FeatureRequest $FeatureRequest `
    -ResolvedFeaturePath $resolvedFeaturePath

$artifactPaths = Save-StartArtifacts `
    -ResolvedProjectPath $resolvedProjectPath `
    -PromptContent $promptContent `
    -Mode $mode `
    -FeatureRequest $FeatureRequest `
    -ResolvedFeaturePath $resolvedFeaturePath `
    -Agent $Agent `
    -ApprovalMode $approvalMode

Write-Success "Prepared Specrew start context."
Write-Info ("Prompt:  {0}" -f $artifactPaths.PromptPath)
Write-Info ("Context: {0}" -f $artifactPaths.ContextPath)
Write-Info ("Copilot approval mode: {0}" -f $approvalMode)

if ($NoLaunch) {
    Write-Info "Launch skipped by --no-launch."
    if ($effectiveAllowAll) {
        Write-Info "Open Copilot with the Squad agent from the project root and include --allow-all for the closest match."
    }
    else {
        Write-Info "Open Copilot with the Squad agent from the project root and keep interactive approvals enabled."
    }
    exit 0
}

$copilotStarted = Start-CopilotSession `
    -ResolvedProjectPath $resolvedProjectPath `
    -PromptContent $promptContent `
    -Agent $Agent `
    -AllowAll $effectiveAllowAll

if (-not $copilotStarted) {
    Write-Info "Copilot CLI was not available, so Specrew wrote a resume-safe handoff prompt instead."
    $manualCommand = "copilot --agent {0} --autopilot --add-dir ""{1}"" -i ""<paste prompt from {2}>""" -f $Agent, $resolvedProjectPath, $artifactPaths.PromptPath
    if ($effectiveAllowAll) {
        $manualCommand = "{0} --allow-all" -f $manualCommand
    }
    Write-Info ("When ready, run from {0}: {1}" -f $resolvedProjectPath, $manualCommand)
}
