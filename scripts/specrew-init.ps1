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

function Show-Usage {
    @'
specrew init [options]

Options:
  -ProjectPath | --project-path <path>
                         Target project directory (defaults to current directory)
  -DryRun | --dry-run     Show planned changes without writing
  -Force | --force        Skip interactive prompts and use default selections
  -SpecKitVersion | --speckit-version
                         Minimum Spec Kit version (default: 0.8.4)
  -SquadVersion | --squad-version
                         Minimum Squad version (default: 0.9.1)
  -Agents | --agents      Optional delegated agents: claude | codex | comma list | all (Copilot host stays enabled)
  -NoAgents | --no-agents Disable optional delegated agents (Copilot host stays enabled)
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

function Write-PostBootstrapGuidance {
    param(
        [Parameter(Mandatory = $true)]
        [string]$ProjectPath
    )

    $baselineRoles = 'Spec Steward, Planner, Implementer, Reviewer, Retro Facilitator'
    $teamPath = Join-Path $ProjectPath '.squad\team.md'
    $specrewScriptsPath = $PSScriptRoot

    Write-Host ''
    Write-Host '============================================================' -ForegroundColor Cyan
    Write-Host '  Specrew Bootstrap Complete' -ForegroundColor Green
    Write-Host '============================================================' -ForegroundColor Cyan
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
    Write-Host '   - Specrew launches Copilot from the project directory in the current terminal by default, stays out of autopilot until intake is grounded, and supports --new-window or --prompt-approvals when you want them' -ForegroundColor White
    Write-Host '   - Specrew will launch or hand off to the Squad agent with lifecycle context' -ForegroundColor White
    Write-Host '   - Squad should drive specify -> clarify -> plan -> tasks -> implement (skip clarify only for resumed clarified work with a recorded rationale)' -ForegroundColor White
    Write-Host ''
    Write-Host '2. Run the iteration lifecycle:' -ForegroundColor Yellow
    Write-Host '   - Materialize iteration artifacts under specs/<feature>/iterations/<NNN>/' -ForegroundColor White
    Write-Host '   - Keep plan.md, state.md, drift-log.md, review.md, and retro.md current by phase' -ForegroundColor White
    Write-Host '   - Run validate-governance.ps1 before phase transitions' -ForegroundColor White
    Write-Host ''
    Write-Host '3. (Optional) Add domain-specific team members:' -ForegroundColor Yellow
    Write-Host '   Add extra Squad members after bootstrap with Security Analyst, UX Designer,' -ForegroundColor White
    Write-Host '   DBA, or other specialists using Specrew team management commands:' -ForegroundColor White
    Write-Host ''
    Write-Host '  pwsh -File <specrew-repo>\scripts\specrew.ps1 team add <member-name> --role <role> --charter "<charter-text>"' -ForegroundColor White
    Write-Host '  pwsh -File <specrew-repo>\scripts\specrew.ps1 start' -ForegroundColor White
    Write-Host '  pwsh -File <specrew-repo>\scripts\specrew.ps1 team list' -ForegroundColor White
    Write-Host '  pwsh -File <specrew-repo>\scripts\specrew.ps1 team update <member-name> --charter "<new-charter>"' -ForegroundColor White
    Write-Host '  pwsh -File <specrew-repo>\scripts\specrew.ps1 team remove <member-name>' -ForegroundColor White
    Write-Host ''
    Write-Host '   Keep the Specrew-managed baseline block intact in .squad/team.md.' -ForegroundColor Yellow
    Write-Host ''
    Write-Host 'Replace <specrew-repo> with the actual path where you cloned Specrew.' -ForegroundColor Yellow
    Write-Host ''
    Write-Host '=== Optional: Add Specrew to PATH for Convenience ===' -ForegroundColor Cyan
    Write-Host ''
    Write-Host 'To use the short form (e.g., "specrew team list") instead of full paths,' -ForegroundColor White
    Write-Host 'you can add the scripts directory to your PATH.' -ForegroundColor White
    Write-Host ''
    Write-Host 'OPTION 1: Current Session Only' -ForegroundColor Yellow
    Write-Host 'Run this command in your current PowerShell session:' -ForegroundColor White
    Write-Host ''
    Write-Host ('  $env:PATH = "$env:PATH;{0}"' -f $specrewScriptsPath) -ForegroundColor Green
    Write-Host ''
    Write-Host '(This only affects the current shell and is lost when you close it.)' -ForegroundColor DarkGray
    Write-Host ''
    Write-Host 'OPTION 2: Persistent (All Future Sessions)' -ForegroundColor Yellow
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
    Write-Host ''
    Write-Host '============================================================' -ForegroundColor Cyan
    Write-Host ''
    Write-Host 'Documentation:' -ForegroundColor White
    Write-Host '  - Getting Started: docs/getting-started.md' -ForegroundColor DarkGray
    Write-Host '  - User Guide: docs/user-guide.md' -ForegroundColor DarkGray
    Write-Host ''
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
        Invoke-WithNativeCommandEncoding -FilePath $FilePath -ScriptBlock {
            & $FilePath @ArgumentList
            if ((Get-NativeExitCode) -ne 0) {
                throw ("Command failed: {0} {1}" -f $FilePath, ($ArgumentList -join ' '))
            }
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
        $output = Invoke-WithNativeCommandEncoding -FilePath $FilePath -ScriptBlock {
            @(& $FilePath @ArgumentList 2>&1)
        }
        return [pscustomobject]@{
            ExitCode = Get-NativeExitCode
            Output   = @($output | ForEach-Object { [string]$_ })
        }
    }
    finally {
        Pop-Location
    }
}

function Invoke-WithNativeCommandEncoding {
    param(
        [Parameter(Mandatory = $true)]
        [string]$FilePath,

        [Parameter(Mandatory = $true)]
        [scriptblock]$ScriptBlock
    )

    $shouldForceUtf8 = $IsWindows -and $FilePath -eq 'specify'
    if (-not $shouldForceUtf8) {
        return & $ScriptBlock
    }

    $utf8 = [System.Text.UTF8Encoding]::new($false)
    $previousOutputEncoding = $null
    $previousInputEncoding = $null
    $previousPipelineEncoding = $OutputEncoding
    $previousPythonUtf8 = [Environment]::GetEnvironmentVariable('PYTHONUTF8', 'Process')
    $previousPythonIoEncoding = [Environment]::GetEnvironmentVariable('PYTHONIOENCODING', 'Process')

    try {
        $previousOutputEncoding = [Console]::OutputEncoding
        $previousInputEncoding = [Console]::InputEncoding
    }
    catch {
        $shouldForceUtf8 = $false
    }

    if (-not $shouldForceUtf8) {
        return & $ScriptBlock
    }

    try {
        [Console]::OutputEncoding = $utf8
        [Console]::InputEncoding = $utf8
        $script:OutputEncoding = $utf8
        [Environment]::SetEnvironmentVariable('PYTHONUTF8', '1', 'Process')
        [Environment]::SetEnvironmentVariable('PYTHONIOENCODING', 'utf-8', 'Process')
        return & $ScriptBlock
    }
    finally {
        [Console]::OutputEncoding = $previousOutputEncoding
        [Console]::InputEncoding = $previousInputEncoding
        $script:OutputEncoding = $previousPipelineEncoding
        [Environment]::SetEnvironmentVariable('PYTHONUTF8', $previousPythonUtf8, 'Process')
        [Environment]::SetEnvironmentVariable('PYTHONIOENCODING', $previousPythonIoEncoding, 'Process')
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

function Ensure-DirectoryExists {
    param(
        [Parameter(Mandatory = $true)]
        [string]$Path,

        [Parameter(Mandatory = $true)]
        [switch]$PreviewOnly
    )

    if (Test-Path -LiteralPath $Path) {
        return
    }

    if ($PreviewOnly) {
        return
    }

    New-Item -ItemType Directory -Path $Path -Force | Out-Null
}

function Write-MissingUtf8File {
    param(
        [Parameter(Mandatory = $true)]
        [string]$Path,

        [AllowEmptyString()]
        [Parameter(Mandatory = $true)]
        [string]$Content,

        [Parameter(Mandatory = $true)]
        [switch]$PreviewOnly
    )

    if (Test-Path -LiteralPath $Path) {
        return
    }

    if ($PreviewOnly) {
        return
    }

    $parent = Split-Path -Parent $Path
    if (-not [string]::IsNullOrWhiteSpace($parent) -and -not (Test-Path -LiteralPath $parent)) {
        New-Item -ItemType Directory -Path $parent -Force | Out-Null
    }

    [System.IO.File]::WriteAllText($Path, $Content, [System.Text.UTF8Encoding]::new($false))
}

function Get-SpecKitGitReference {
    param(
        [Parameter(Mandatory = $true)]
        [string]$Version
    )

    $trimmedVersion = $Version.Trim()
    if ([string]::IsNullOrWhiteSpace($trimmedVersion)) {
        throw 'Spec Kit version cannot be empty.'
    }

    if ($trimmedVersion.StartsWith('v', [System.StringComparison]::OrdinalIgnoreCase)) {
        return $trimmedVersion
    }

    return ('v{0}' -f $trimmedVersion)
}

function Get-SpecKitInstallArguments {
    param(
        [Parameter(Mandatory = $true)]
        [string]$Version,

        [Parameter(Mandatory = $true)]
        [bool]$ForceInstall
    )

    $arguments = @('tool', 'install')
    if ($ForceInstall) {
        $arguments += '--force'
    }

    $arguments += @(
        'specify-cli',
        '--from',
        ('git+https://github.com/github/spec-kit.git@{0}' -f (Get-SpecKitGitReference -Version $Version))
    )

    return $arguments
}

function Get-SpecKitInstallCommandText {
    param(
        [Parameter(Mandatory = $true)]
        [string]$Version,

        [Parameter(Mandatory = $true)]
        [bool]$ForceInstall
    )

    return ('uv {0}' -f ((Get-SpecKitInstallArguments -Version $Version -ForceInstall $ForceInstall) -join ' '))
}

function Get-FirstNonEmptyOutputLine {
    param(
        [AllowEmptyCollection()]
        [string[]]$OutputLines
    )

    return @($OutputLines | Where-Object { -not [string]::IsNullOrWhiteSpace($_) } | Select-Object -First 1)[0]
}

function Test-SpecifyReleaseAssetBlocker {
    param(
        [AllowEmptyCollection()]
        [string[]]$OutputLines
    )

    $combinedOutput = (@($OutputLines) -join [Environment]::NewLine)
    return $combinedOutput -match 'No matching release asset found for .+spec-kit-template-'
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
            $arguments = Get-SpecKitInstallArguments -Version $Dependency.MinimumVersion -ForceInstall $false
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

function Invoke-VersionValidation {
    param(
        [Parameter(Mandatory = $true)]
        [string]$ScriptPath,

        [Parameter(Mandatory = $true)]
        [string]$MinimumSpecKitVersion,

        [Parameter(Mandatory = $true)]
        [string]$MinimumSquadVersion
    )

    try {
        return @(& $ScriptPath -MinimumSpecKitVersion $MinimumSpecKitVersion -MinimumSquadVersion $MinimumSquadVersion -PassThru)
    }
    catch {
        Write-Error ("Dependency validation failed unexpectedly. Re-run '{0}' directly for details. {1}" -f $ScriptPath, $_.Exception.Message)
        exit 4
    }
}

function Get-DependencyValidationIssue {
    param(
        [Parameter(Mandatory = $true)]
        [pscustomobject[]]$Results,

        [Parameter(Mandatory = $true)]
        [bool]$IncludeMissing,

        [Parameter(Mandatory = $true)]
        [bool]$AfterInstallAttempt
    )

    $failures = [System.Collections.ArrayList]::new()

    if ($IncludeMissing) {
        foreach ($dependency in @($Results | Where-Object { -not $_.IsInstalled })) {
            $message = if ($AfterInstallAttempt) {
                "{0} is still not installed after the installation attempt. Run '{1}' to install it, then re-run specrew init." -f $dependency.Platform, $dependency.SuggestedInstall
            }
            else {
                "{0} is not installed. Run '{1}'." -f $dependency.Platform, $dependency.SuggestedInstall
            }

            $null = $failures.Add([pscustomobject]@{
                    ExitCode = 4
                    Message  = $message
                    Outcome  = ("{0}: missing ({1})" -f $dependency.Platform, $dependency.SuggestedInstall)
                })
        }
    }

    foreach ($dependency in @($Results | Where-Object { $_.IsInstalled -and -not $_.IsOperational })) {
        $failureDetail = if ($dependency.ProbeError) { $dependency.ProbeError } elseif ($dependency.ValidationError) { $dependency.ValidationError } else { 'the command did not complete successfully' }
        $message = "{0} is installed but the '{1}' command is not healthy ({2}). Run '{3}' to repair it, then re-run specrew init." -f $dependency.Platform, $dependency.CommandName, $failureDetail, $dependency.SuggestedRepair

        $null = $failures.Add([pscustomobject]@{
                ExitCode = 1
                Message  = $message
                Outcome  = ("{0}: requires repair ({1})" -f $dependency.Platform, $dependency.SuggestedRepair)
            })
    }

    foreach ($dependency in @($Results | Where-Object { $_.IsInstalled -and -not $_.IsCompatible })) {
        $message = "Specrew requires {0} >= {1} but found {2}. Run '{3}' to upgrade." -f $dependency.Platform, $dependency.MinimumVersion, $dependency.Version, $dependency.SuggestedUpgrade

        $null = $failures.Add([pscustomobject]@{
                ExitCode = 1
                Message  = $message
                Outcome  = ("{0}: requires upgrade ({1})" -f $dependency.Platform, $dependency.SuggestedUpgrade)
            })
    }

    return @($failures)
}

function Resolve-DependencyValidationIssue {
    param(
        [Parameter(Mandatory = $true)]
        [pscustomobject[]]$Results,

        [AllowEmptyCollection()]
        [Parameter(Mandatory = $true)]
        [System.Collections.ArrayList]$Actions,

        [Parameter(Mandatory = $true)]
        [switch]$PreviewOnly,

        [Parameter(Mandatory = $true)]
        [bool]$IncludeMissing,

        [Parameter(Mandatory = $true)]
        [bool]$AfterInstallAttempt
    )

    $failures = @(Get-DependencyValidationIssue -Results $Results -IncludeMissing $IncludeMissing -AfterInstallAttempt $AfterInstallAttempt)
    if ($failures.Count -eq 0) {
        return 0
    }

    foreach ($failure in $failures) {
        if ($PreviewOnly) {
            Write-Warning ("[dry-run] {0}" -f $failure.Message)
            Add-Action -Actions $Actions -Step 'dependency' -Outcome $failure.Outcome
            continue
        }

        Write-Error $failure.Message -ErrorAction Continue
    }

    if ($failures.ExitCode -contains 4) {
        return 4
    }

    return 1
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

function Test-SpecifyExtensionAddAvailable {
    param(
        [Parameter(Mandatory = $true)]
        [string]$WorkingDirectory
    )

    try {
        $probe = Invoke-NativeCommandForOutput -FilePath 'specify' -ArgumentList @('extension', 'add', '--help') -WorkingDirectory $WorkingDirectory
    }
    catch {
        return $false
    }

    if ($probe.ExitCode -ne 0) {
        return $false
    }

    $output = ($probe.Output -join [Environment]::NewLine)
    return $output -match 'specify extension add' -and $output -match 'Install an extension'
}

function Test-SpecifyInitPreflight {
    param(
        [Parameter(Mandatory = $true)]
        [string]$ProjectPath,

        [Parameter(Mandatory = $true)]
        [string[]]$ArgumentList,

        [Parameter(Mandatory = $true)]
        [string]$SpecKitVersion
    )

    $probeDirectory = Join-Path $ProjectPath ('.specrew-specify-probe-{0}' -f [guid]::NewGuid().ToString('N'))
    New-Item -Path $probeDirectory -ItemType Directory -Force | Out-Null

    try {
        $probeResult = Invoke-NativeCommandForOutput -FilePath 'specify' -ArgumentList $ArgumentList -WorkingDirectory $probeDirectory
        if ($probeResult.ExitCode -eq 0) {
            return Get-SpecifyInitPreflightResult -Ready $true -Repaired $false -RepairOutcome $null -FailureMessage $null
        }

        $failureSummary = Get-FirstNonEmptyOutputLine -OutputLines $probeResult.Output
        if (-not (Test-SpecifyReleaseAssetBlocker -OutputLines $probeResult.Output)) {
            return Get-SpecifyInitPreflightResult -Ready $false -Repaired $false -RepairOutcome $null -FailureMessage ("Spec Kit preflight failed before Specrew touched your project: {0}" -f $(if ($failureSummary) { $failureSummary } else { 'specify init exited without any diagnostic output' }))
        }

        if (-not (Get-Command uv -ErrorAction SilentlyContinue)) {
            return Get-SpecifyInitPreflightResult -Ready $false -Repaired $false -RepairOutcome $null -FailureMessage ("Spec Kit preflight hit the upstream release-asset blocker ({0}). Install the official GitHub release with '{1}', then re-run specrew init." -f $failureSummary, (Get-SpecKitInstallCommandText -Version $SpecKitVersion -ForceInstall $true))
        }

        Write-Host ("[info] Detected Spec Kit release-asset blocker during preflight; reinstalling official Spec Kit {0} from GitHub." -f (Get-SpecKitGitReference -Version $SpecKitVersion)) -ForegroundColor Yellow
        $repairResult = Invoke-NativeCommandForOutput -FilePath 'uv' -ArgumentList (Get-SpecKitInstallArguments -Version $SpecKitVersion -ForceInstall $true) -WorkingDirectory $probeDirectory
        foreach ($line in @($repairResult.Output)) {
            if (-not [string]::IsNullOrWhiteSpace($line)) {
                Write-Host $line
            }
        }
        if ($repairResult.ExitCode -ne 0) {
            $repairFailureSummary = Get-FirstNonEmptyOutputLine -OutputLines $repairResult.Output
            return Get-SpecifyInitPreflightResult -Ready $false -Repaired $false -RepairOutcome $null -FailureMessage ("Spec Kit preflight hit the upstream release-asset blocker ({0}), and automatic repair failed{1}. Run '{2}' manually, then re-run specrew init." -f $failureSummary, $(if ($repairFailureSummary) { ": $repairFailureSummary" } else { '' }), (Get-SpecKitInstallCommandText -Version $SpecKitVersion -ForceInstall $true))
        }

        $retryResult = Invoke-NativeCommandForOutput -FilePath 'specify' -ArgumentList $ArgumentList -WorkingDirectory $probeDirectory
        if ($retryResult.ExitCode -eq 0) {
            return Get-SpecifyInitPreflightResult -Ready $true -Repaired $true -RepairOutcome ("reinstalled Spec Kit from official GitHub release {0}" -f (Get-SpecKitGitReference -Version $SpecKitVersion)) -FailureMessage $null
        }

        $retryFailureSummary = Get-FirstNonEmptyOutputLine -OutputLines $retryResult.Output
        return Get-SpecifyInitPreflightResult -Ready $false -Repaired $true -RepairOutcome ("reinstalled Spec Kit from official GitHub release {0}" -f (Get-SpecKitGitReference -Version $SpecKitVersion)) -FailureMessage ("Spec Kit was repaired to the official GitHub release, but `specify init` still failed in preflight: {0}" -f $(if ($retryFailureSummary) { $retryFailureSummary } else { 'specify init exited without any diagnostic output' }))
    }
    finally {
        if (Test-Path -LiteralPath $probeDirectory) {
            Remove-Item -LiteralPath $probeDirectory -Recurse -Force -ErrorAction SilentlyContinue
        }
    }
}

function Get-SpecifyInitPreflightResult {
    param(
        [Parameter(Mandatory = $true)]
        [bool]$Ready,

        [Parameter(Mandatory = $true)]
        [bool]$Repaired,

        [AllowNull()]
        [string]$RepairOutcome,

        [AllowNull()]
        [string]$FailureMessage
    )

    return [pscustomobject]@{
        Ready          = $Ready
        Repaired       = $Repaired
        RepairOutcome  = $RepairOutcome
        FailureMessage = $FailureMessage
    }
}

function Invoke-SpecKitExtensionDeployment {
    param(
        [Parameter(Mandatory = $true)]
        [string]$ProjectPath,

        [Parameter(Mandatory = $true)]
        [string]$RepoRoot,

        [Parameter(Mandatory = $true)]
        [string]$FallbackScriptPath,

        [Parameter(Mandatory = $true)]
        [switch]$PreviewOnly
    )

    $targetExtensionRoot = Join-Path $ProjectPath '.specify\extensions\specrew-speckit'
    if (Test-Path -LiteralPath $targetExtensionRoot) {
        return [pscustomobject]@{
                Action = 'preserved'
                Path   = $targetExtensionRoot
            }
    }

    $extensionSourceRoot = Join-Path $RepoRoot 'extensions\specrew-speckit'
    if (Test-SpecifyExtensionAddAvailable -WorkingDirectory $ProjectPath) {
        if ($PreviewOnly) {
            Write-Host ("[dry-run] specify extension add --dev {0}" -f $extensionSourceRoot) -ForegroundColor Yellow
            return [pscustomobject]@{
                    Action = 'would-install-via-cli'
                    Path   = $targetExtensionRoot
                }
        }

        try {
            Invoke-NativeCommand -FilePath 'specify' -ArgumentList @('extension', 'add', '--dev', $extensionSourceRoot) -WorkingDirectory $ProjectPath
            return [pscustomobject]@{
                    Action = 'installed-via-cli'
                    Path   = $targetExtensionRoot
                }
        }
        catch {
            Write-Host '[info] specify extension add failed; falling back to manual Specrew extension deployment.' -ForegroundColor Yellow
        }
    }

    $null = @(
        & $FallbackScriptPath `
            -ProjectPath $ProjectPath `
            -DryRun:$PreviewOnly `
            -PassThru
    )

    return [pscustomobject]@{
        Action = $(if ($PreviewOnly) { 'would-install-manual-fallback' } else { 'installed-manual-fallback' })
        Path   = $targetExtensionRoot
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

$resolvedProjectPath = Resolve-ProjectPath -Path $ProjectPath
$repoRoot = Split-Path -Parent $PSScriptRoot
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
    }
    else {
        Add-Action -Actions $actions -Step 'squad-runtime' -Outcome 'skipped: .squad is absent in brownfield workspace'
    }
}

Write-Host ''
Write-Host 'Bootstrap summary' -ForegroundColor Green
$actions | Format-Table -AutoSize

if ($DryRun) {
    Write-Host 'Dry run complete. No files were changed.' -ForegroundColor Yellow
}
else {
    Write-Host ("Bootstrap completed for {0}." -f $resolvedProjectPath) -ForegroundColor Green
    if (-not $SpecKitExtensionOnly -and $squadSurfaceReady) {
        Write-PostBootstrapGuidance -ProjectPath $resolvedProjectPath
    }
}

exit 0
