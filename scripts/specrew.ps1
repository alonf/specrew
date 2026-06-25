param(
    [Parameter(Mandatory = $false, Position = 0)]
    [string]$Command,

    [Alias('help')]
    [switch]$HelpRequested,

    [Alias('info')]
    [switch]$InfoRequested,

    [Alias('version', 'v')]
    [switch]$VersionRequested,

    [Parameter(ValueFromRemainingArguments = $true)]
    [string[]]$Arguments
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

$Arguments = @($Arguments | Where-Object { -not [string]::IsNullOrWhiteSpace($_) })

if ($HelpRequested.IsPresent) {
    $Arguments = @($Arguments) + '--help'
}

if ($InfoRequested.IsPresent) {
    $Arguments = @($Arguments) + '--info'
}

if ($VersionRequested.IsPresent) {
    $Command = 'version'
}

function Show-Usage {
    @'
specrew - Spec-governed AI crew operating model

Usage:
  specrew init [options]           Bootstrap Specrew in the current or target project
  specrew start [args]             Start or resume the Squad-driven Spec Kit lifecycle
  specrew review [options]         Run live co-review or replay persisted reviewer evidence
  specrew where [options]          Show the velocity dashboard ("where am I?")
  specrew status [options]         Alias for specrew where
  specrew update [options]         Refresh Specrew assets or upgrade managed platforms
  specrew team <command> [args]    Manage Squad team members
  specrew hooks <command> [args]   Inspect / install / repair Specrew host hooks
  specrew handover <command> [args] Author the cross-session handover body (agent-callable)
  specrew version [options]        Show version and slash-command compatibility state

Commands:
  init     Initialize Specrew (Spec Kit + Squad + governance)
  start    Start or resume feature delivery through Squad + Spec Kit
  review   Run live reviewer evidence or show reviewer summary for a completed iteration
  where    Show the velocity dashboard
  status   Alias for where
  update   Refresh Specrew or upgrade Spec Kit / Squad in an existing project
  team     Manage team members (add, update, remove, list)
  hooks    Inspect/install/repair host hooks (status, install [--host], remove [--host])
  handover Author the rolling cross-session handover body (author [--from <file>])
  version  Show the installed Specrew version and slash-command compatibility
  install-shell-wrappers  Install/refresh the Unix shell wrappers (macOS/Linux)
  help     Show this help message

Examples:
  specrew init --project-path .
  specrew start
  specrew start "Build a REST API for user management"
  specrew review --project-path .
  specrew review --live --baseline-ref origin/main --host claude --authorization-ref manual-review
  specrew where
  specrew status --compact
  specrew update
  specrew update --info
  specrew update --all
  specrew team list
  specrew hooks status
  specrew hooks install --host codex
  specrew hooks remove --host cursor
  specrew handover author --from .specrew/handover-draft.md
  specrew version
  specrew team add security-analyst --role "Security Analyst" --charter "Review security"
  specrew team update security-analyst --charter "Updated charter"
  specrew team remove security-analyst

For detailed command help:
  specrew init --help
  specrew start --help
  specrew review --help
  specrew where --help
  specrew update --help
  specrew version --help
  specrew team --help (shows usage when no subcommand provided)

Slash-command catalog (`/specrew-help` fallback):
  /specrew-where    Current Specrew project dashboard
  /specrew-status   Alias for /specrew-where
  /specrew-update   Refresh Specrew-managed assets and runtime surfaces
  /specrew-team     Manage Squad team members
  /specrew-review   Run live reviewer evidence or replay closeout state without approving a boundary
  /specrew-help     Canonical catalog/help fallback
  /specrew-version  Installed version and compatibility state
'@ | Write-Host
}

function Test-ArgumentPresent {
    param(
        [string[]]$ArgumentList,
        [string[]]$OptionNames
    )

    foreach ($argument in $ArgumentList) {
        foreach ($optionName in $OptionNames) {
            if ($argument -eq $optionName -or $argument.StartsWith(('{0}=' -f $optionName), [System.StringComparison]::OrdinalIgnoreCase)) {
                return $true
            }
        }
    }

    return $false
}

function Write-UnsupportedArgumentError {
    param(
        [Parameter(Mandatory = $true)][string]$CommandName,
        [Parameter(Mandatory = $true)][string]$Argument
    )

    Write-Output "WARNING: Unsupported argument '$Argument' for 'specrew $CommandName'."
    Write-Host ("ERROR: Unsupported argument '{0}'." -f $Argument) -ForegroundColor Red
    Write-Host ("Run 'specrew {0} --help' for usage or '/specrew-help' for the full Specrew catalog." -f $CommandName) -ForegroundColor Yellow
    exit 1
}

function Write-MissingArgumentValueError {
    param(
        [Parameter(Mandatory = $true)][string]$CommandName,
        [Parameter(Mandatory = $true)][string]$OptionName
    )

    Write-Output "WARNING: Missing value for '$OptionName' in 'specrew $CommandName'."
    Write-Host ("ERROR: '{0}' requires a value." -f $OptionName) -ForegroundColor Red
    Write-Host ("Run 'specrew {0} --help' for usage or '/specrew-help' for the full Specrew catalog." -f $CommandName) -ForegroundColor Yellow
    exit 1
}

function Resolve-ProjectPathFromArguments {
    param([AllowEmptyCollection()][string[]]$ArgumentList)

    $normalizedArguments = @($ArgumentList | Where-Object { -not [string]::IsNullOrWhiteSpace($_) })
    for ($index = 0; $index -lt $normalizedArguments.Count; $index++) {
        $argument = $normalizedArguments[$index]
        if ($argument -match '^--project-path=(.+)$') {
            return $Matches[1]
        }

        if ($argument -ieq '--project-path') {
            $index++
            if ($index -lt $normalizedArguments.Count) {
                return $normalizedArguments[$index]
            }

            return $null
        }
    }

    return (Get-Location).Path
}

function Assert-OptionArguments {
    param(
        [Parameter(Mandatory = $true)][string]$CommandName,
        [Parameter(Mandatory = $true)][AllowEmptyCollection()][string[]]$ArgumentList,
        [string[]]$SwitchOptions = @(),
        [string[]]$ValueOptions = @(),
        [int]$MaxPositionals = 0
    )

    $normalizedArguments = @($ArgumentList | Where-Object { -not [string]::IsNullOrWhiteSpace($_) })
    $remainingPositionals = $MaxPositionals

    for ($index = 0; $index -lt $normalizedArguments.Count; $index++) {
        $argument = $normalizedArguments[$index]

        if ($SwitchOptions -icontains $argument) {
            continue
        }

        $matchedValueOption = $null
        foreach ($optionName in $ValueOptions) {
            if ($argument -ieq $optionName -or $argument.StartsWith(('{0}=' -f $optionName), [System.StringComparison]::OrdinalIgnoreCase)) {
                $matchedValueOption = $optionName
                break
            }
        }

        if ($null -ne $matchedValueOption) {
            if ($argument -ieq $matchedValueOption) {
                $index++
                if ($index -ge $normalizedArguments.Count) {
                    Write-MissingArgumentValueError -CommandName $CommandName -OptionName $matchedValueOption
                }
            }

            continue
        }

        if (-not $argument.StartsWith('-') -and $remainingPositionals -gt 0) {
            $remainingPositionals--
            continue
        }

        Write-UnsupportedArgumentError -CommandName $CommandName -Argument $argument
    }
}

function Assert-TeamArguments {
    param([AllowEmptyCollection()][string[]]$ArgumentList)

    $normalizedArguments = @($ArgumentList | Where-Object { -not [string]::IsNullOrWhiteSpace($_) })
    if ($normalizedArguments.Count -eq 0) {
        return
    }

    if ($normalizedArguments[0] -in @('--help', '-h')) {
        return
    }

    $subcommand = $normalizedArguments[0]
    $index = 1

    switch ($subcommand) {
        'list' {
            while ($index -lt $normalizedArguments.Count) {
                $argument = $normalizedArguments[$index]
                if ($argument -ieq '--project-path') {
                    $index++
                    if ($index -ge $normalizedArguments.Count) {
                        Write-MissingArgumentValueError -CommandName 'team' -OptionName '--project-path'
                    }
                }
                elseif (-not $argument.StartsWith('--project-path=', [System.StringComparison]::OrdinalIgnoreCase)) {
                    Write-UnsupportedArgumentError -CommandName 'team' -Argument $argument
                }

                $index++
            }

            return
        }
        'add' {
            if ($index -lt $normalizedArguments.Count -and -not $normalizedArguments[$index].StartsWith('-')) {
                $index++
            }
        }
        'update' {
            if ($index -lt $normalizedArguments.Count -and -not $normalizedArguments[$index].StartsWith('-')) {
                $index++
            }
        }
        'remove' {
            if ($index -lt $normalizedArguments.Count -and -not $normalizedArguments[$index].StartsWith('-')) {
                $index++
            }

            while ($index -lt $normalizedArguments.Count) {
                $argument = $normalizedArguments[$index]
                if ($argument -ieq '--project-path') {
                    $index++
                    if ($index -ge $normalizedArguments.Count) {
                        Write-MissingArgumentValueError -CommandName 'team' -OptionName '--project-path'
                    }
                }
                elseif (-not $argument.StartsWith('--project-path=', [System.StringComparison]::OrdinalIgnoreCase)) {
                    Write-UnsupportedArgumentError -CommandName 'team' -Argument $argument
                }

                $index++
            }

            return
        }
        default {
            Write-UnsupportedArgumentError -CommandName 'team' -Argument $subcommand
        }
    }

    while ($index -lt $normalizedArguments.Count) {
        $argument = $normalizedArguments[$index]
        switch -Regex ($argument) {
            '^--project-path(?:=.+)?$' {
                if ($argument -ieq '--project-path') {
                    $index++
                    if ($index -ge $normalizedArguments.Count) {
                        Write-MissingArgumentValueError -CommandName 'team' -OptionName '--project-path'
                    }
                }
            }
            '^--role(?:=.+)?$' {
                if ($argument -ieq '--role') {
                    $index++
                    if ($index -ge $normalizedArguments.Count) {
                        Write-MissingArgumentValueError -CommandName 'team' -OptionName '--role'
                    }
                }
            }
            '^--charter(?:=.+)?$' {
                if ($argument -ieq '--charter') {
                    $index++
                    if ($index -ge $normalizedArguments.Count) {
                        Write-MissingArgumentValueError -CommandName 'team' -OptionName '--charter'
                    }
                }
            }
            default {
                Write-UnsupportedArgumentError -CommandName 'team' -Argument $argument
            }
        }

        $index++
    }
}

function Assert-WhitelistedArguments {
    param(
        [Parameter(Mandatory = $true)][string]$CommandName,
        [AllowEmptyCollection()][string[]]$ArgumentList
    )

    switch ($CommandName) {
        'where' {
            Assert-OptionArguments -CommandName $CommandName -ArgumentList $ArgumentList -SwitchOptions @('--compact', '--ascii', '--no-color', '--json', '--team', '--worktrees', '--help', '-h') -ValueOptions @('--project-path', '--feature', '--iteration', '--recentcount', '--barwidth')
        }
        'status' {
            Assert-OptionArguments -CommandName $CommandName -ArgumentList $ArgumentList -SwitchOptions @('--compact', '--ascii', '--no-color', '--json', '--team', '--worktrees', '--help', '-h') -ValueOptions @('--project-path', '--feature', '--iteration', '--recentcount', '--barwidth')
        }
        'update' {
            Assert-OptionArguments -CommandName $CommandName -ArgumentList $ArgumentList -SwitchOptions @('--info', '--all', '--specrew', '--squad', '--spec-kit', '--skip-update-check', '--upstream-latest', '--help', '-h') -ValueOptions @('--project-path')
        }
        'review' {
            Assert-OptionArguments -CommandName $CommandName -ArgumentList $ArgumentList -SwitchOptions @('--quiet', '--json', '--open', '--live', '--preserve-debug', '--list-hosts', '--help', '-h') -ValueOptions @('--project-path', '--feature', '--iteration', '--baseline-ref', '--checkpoint-id', '--run-id', '--host', '--model', '--effort', '--authorization-ref', '--code-writer-host', '--fallback-policy', '--reviewer-config', '--schema-root', '--run-root', '--timeout-seconds', '--design-context-ref', '--allowed-path', '--forbidden-path', '--exclude-path') -MaxPositionals 1
        }
        'version' {
            Assert-OptionArguments -CommandName $CommandName -ArgumentList $ArgumentList -SwitchOptions @('--help', '-h') -ValueOptions @('--project-path')
        }
        'team' {
            Assert-TeamArguments -ArgumentList $ArgumentList
        }
        'help' {
            Assert-OptionArguments -CommandName $CommandName -ArgumentList $ArgumentList -SwitchOptions @('--help', '-h')
        }
    }
}

$scriptRoot = Split-Path -Parent $PSCommandPath
$versionCheckHelperPath = Join-Path $scriptRoot 'internal\version-check.ps1'
if (-not (Test-Path -LiteralPath $versionCheckHelperPath -PathType Leaf)) {
    throw "Missing version-check helper '$versionCheckHelperPath'."
}
. $versionCheckHelperPath

function Assert-ProjectSetup {
    param(
        [Parameter(Mandatory = $true)][string]$CommandName,
        [AllowEmptyCollection()][string[]]$ArgumentList
    )

    $projectPath = Resolve-ProjectPathFromArguments -ArgumentList $ArgumentList
    if ([string]::IsNullOrWhiteSpace($projectPath)) {
        Write-MissingArgumentValueError -CommandName $CommandName -OptionName '--project-path'
    }

    $resolvedProjectPath = Resolve-ProjectPath -Path $projectPath
    $configPath = Join-Path $resolvedProjectPath '.specrew\config.yml'
    if (Test-Path -LiteralPath $configPath -PathType Leaf) {
        return
    }

    Write-Output "WARNING: Specrew project setup is missing at '$resolvedProjectPath'."
    Write-Host ("ERROR: 'specrew {0}' requires a Specrew-managed project." -f $CommandName) -ForegroundColor Red
    Write-Host ("Run 'specrew init --project-path {0}' first, then retry the command." -f $resolvedProjectPath) -ForegroundColor Yellow
    exit 1
}

function Get-SpecrewDispatcherRuntimeVersion {
    param(
        [Parameter(Mandatory = $true)][string]$ProjectRoot
    )

    $moduleManifestPath = Join-Path (Split-Path -Parent $scriptRoot) 'Specrew.psd1'
    if (Test-Path -LiteralPath $moduleManifestPath -PathType Leaf) {
        try {
            $manifest = Import-PowerShellDataFile -LiteralPath $moduleManifestPath
            if ($manifest -and $manifest.ContainsKey('ModuleVersion')) {
                return [string]$manifest.ModuleVersion
            }
        }
        catch {
            # Fall through to installed module resolution.
        }
    }

    return Get-SpecrewInstalledVersion -ProjectRoot $ProjectRoot
}

function Assert-SlashCommandCompatibility {
    param(
        [Parameter(Mandatory = $true)][string]$CommandName,
        [AllowEmptyCollection()][string[]]$ArgumentList
    )

    $projectPath = Resolve-ProjectPathFromArguments -ArgumentList $ArgumentList
    if ([string]::IsNullOrWhiteSpace($projectPath)) {
        return
    }

    $resolvedProjectPath = Resolve-ProjectPath -Path $projectPath
    $projectBaselineVersionText = Get-SpecrewVersionConfigValue -ProjectRoot $resolvedProjectPath -Key 'specrew_version'
    $projectBaselineVersion = ConvertTo-SpecrewSemanticVersion -Value $projectBaselineVersionText
    if ($null -eq $projectBaselineVersion) {
        return
    }

    $installedVersionText = Get-SpecrewDispatcherRuntimeVersion -ProjectRoot $resolvedProjectPath
    $installedVersion = ConvertTo-SpecrewSemanticVersion -Value $installedVersionText
    if ($null -eq $installedVersion -or $installedVersion -ge $projectBaselineVersion) {
        return
    }

    Write-Output "WARNING: Specrew module is older than this project's recorded baseline for 'specrew $CommandName'."
    Write-Host ("ERROR: 'specrew {0}' cannot safely run with Specrew version {1} against project baseline {2}." -f $CommandName, $installedVersionText, $projectBaselineVersionText) -ForegroundColor Red
    Write-Host 'Update the module with Update-Module Specrew, or set SPECREW_MODULE_PATH to a matching Specrew development tree before retrying.' -ForegroundColor Yellow
    exit 1
}

if (-not $Command -or $Command -eq 'help' -or $Command -eq '--help' -or $Command -eq '-h') {
    Show-Usage
    exit 0
}

# feature 140: Unix interactive `start` must launch the host (copilot/claude/codex) in
# module-FUNCTION context, not script context. The native wrapper (bin/specrew) and
# clone-mode both run this dispatcher via `pwsh -File`, which is SCRIPT context. On
# Linux/macOS, PowerShell strips the controlling TTY from native command children
# spawned in a script body, so specrew-start.ps1 falls into its no-TTY fallback
# (`& copilot ...` with the comment "TUI won't render but the command will run") — the
# host runs headless once and exits straight back to the shell instead of opening an
# interactive session. The TTY-preserving launch lives in the module function
# Invoke-SpecrewScript (the proven R-019-V2 deferred-launch handoff). Re-dispatch
# `start` THROUGH that module function so the launch happens in function context.
#
# Guard on SPECREW_DEFERRED_LAUNCH_FILE, which is set ONLY by Invoke-SpecrewScript, so
# the in-process re-entry it triggers (`& specrew.ps1 start`) skips this block and runs
# the normal start arm. (Do NOT guard on SPECREW_INVOKED_FROM_MODULE: bin/specrew sets
# that too, so it cannot distinguish the already-in-module-flow re-entry.) Import the
# module BY PATH (module root = parent of scripts/) to avoid the side-by-side trap where
# `Import-Module Specrew` by name loads the highest STABLE instead of this build.
if (-not $IsWindows -and $Command -eq 'start' -and [string]::IsNullOrEmpty($env:SPECREW_DEFERRED_LAUNCH_FILE)) {
    $specrewManifestPath = Join-Path (Split-Path -Parent $scriptRoot) 'Specrew.psd1'
    if (Test-Path -LiteralPath $specrewManifestPath -PathType Leaf) {
        Import-Module -Name $specrewManifestPath -Force
        Invoke-Specrew @(@($Command) + @($Arguments))
        exit $LASTEXITCODE
    }
}

switch ($Command) {
    'init' {
        $initScript = Join-Path $scriptRoot 'specrew-init.ps1'
        if (-not (Test-Path -LiteralPath $initScript)) {
            Write-Host "ERROR: specrew-init.ps1 not found at $initScript" -ForegroundColor Red
            exit 1
        }
        
        & pwsh -NoProfile -ExecutionPolicy Bypass -File $initScript @Arguments
        exit $LASTEXITCODE
    }

    'config' {
        # config takes a positional subcommand (get|set) + key [+ value], like `host`/`team`,
        # so it skips the flag-whitelist but still requires an initialized project.
        Assert-ProjectSetup -CommandName 'config' -ArgumentList $Arguments
        Assert-SlashCommandCompatibility -CommandName 'config' -ArgumentList $Arguments

        $configScript = Join-Path $scriptRoot 'specrew-config.ps1'
        if (-not (Test-Path -LiteralPath $configScript)) {
            Write-Host "ERROR: specrew-config.ps1 not found at $configScript" -ForegroundColor Red
            exit 1
        }

        if (-not $Arguments -or $Arguments.Count -eq 0) {
            Write-Host "Usage: specrew config <get|set> session_mode [<single|multi>]" -ForegroundColor Yellow
            Write-Host ""
            Write-Host "Examples:" -ForegroundColor Cyan
            Write-Host "  specrew config get session_mode"
            Write-Host "  specrew config set session_mode multi"
            exit 0
        }

        & pwsh -NoProfile -ExecutionPolicy Bypass -File $configScript @Arguments
        exit $LASTEXITCODE
    }

    'team' {
        Assert-WhitelistedArguments -CommandName 'team' -ArgumentList $Arguments
        Assert-ProjectSetup -CommandName 'team' -ArgumentList $Arguments
        Assert-SlashCommandCompatibility -CommandName 'team' -ArgumentList $Arguments

        $teamScript = Join-Path $scriptRoot 'specrew-team.ps1'
        if (-not (Test-Path -LiteralPath $teamScript)) {
            Write-Host "ERROR: specrew-team.ps1 not found at $teamScript" -ForegroundColor Red
            exit 1
        }
        
        if (-not $Arguments -or $Arguments.Count -eq 0) {
            Write-Host "Usage: specrew team <command> [options]" -ForegroundColor Yellow
            Write-Host ""
            Write-Host "Commands:" -ForegroundColor Cyan
            Write-Host "  add <member-name> --role <role> --charter <charter-text>"
            Write-Host "  list"
            Write-Host "  update <member-name> [--role <role>] [--charter <charter-text>]"
            Write-Host "  remove <member-name>"
            Write-Host ""
            Write-Host "Examples:" -ForegroundColor Cyan
            Write-Host "  specrew team list"
            Write-Host "  specrew team add security-analyst --role 'Security Analyst' --charter 'Review security'"
            exit 0
        }
        
        & pwsh -NoProfile -ExecutionPolicy Bypass -File $teamScript @Arguments
        exit $LASTEXITCODE
    }

    'start' {
        $startScript = Join-Path $scriptRoot 'specrew-start.ps1'
        if (-not (Test-Path -LiteralPath $startScript)) {
            Write-Host "ERROR: specrew-start.ps1 not found at $startScript" -ForegroundColor Red
            exit 1
        }

        $startArguments = @($Arguments)
        if (-not (Test-ArgumentPresent -ArgumentList $startArguments -OptionNames @('--project-path', '-ProjectPath', '-project-path'))) {
            $startArguments = @('--project-path', (Get-Location).Path) + $startArguments
        }

        & $startScript -CliArgs $startArguments
        exit $LASTEXITCODE
    }

    'review' {
        Assert-WhitelistedArguments -CommandName 'review' -ArgumentList $Arguments
        Assert-ProjectSetup -CommandName 'review' -ArgumentList $Arguments
        Assert-SlashCommandCompatibility -CommandName 'review' -ArgumentList $Arguments

        $reviewScript = Join-Path $scriptRoot 'specrew-review.ps1'
        if (-not (Test-Path -LiteralPath $reviewScript)) {
            Write-Host "ERROR: specrew-review.ps1 not found at $reviewScript" -ForegroundColor Red
            exit 1
        }

        & pwsh -NoProfile -ExecutionPolicy Bypass -File $reviewScript @Arguments
        exit $LASTEXITCODE
    }

    'where' {
        Assert-WhitelistedArguments -CommandName 'where' -ArgumentList $Arguments
        Assert-ProjectSetup -CommandName 'where' -ArgumentList $Arguments
        Assert-SlashCommandCompatibility -CommandName 'where' -ArgumentList $Arguments

        $whereScript = Join-Path $scriptRoot 'specrew-where.ps1'
        if (-not (Test-Path -LiteralPath $whereScript)) {
            Write-Host "ERROR: specrew-where.ps1 not found at $whereScript" -ForegroundColor Red
            exit 1
        }

        & $whereScript -CliArgs $Arguments
        exit $LASTEXITCODE
    }

    'status' {
        Assert-WhitelistedArguments -CommandName 'status' -ArgumentList $Arguments
        Assert-ProjectSetup -CommandName 'status' -ArgumentList $Arguments
        Assert-SlashCommandCompatibility -CommandName 'status' -ArgumentList $Arguments

        $whereScript = Join-Path $scriptRoot 'specrew-where.ps1'
        if (-not (Test-Path -LiteralPath $whereScript)) {
            Write-Host "ERROR: specrew-where.ps1 not found at $whereScript" -ForegroundColor Red
            exit 1
        }

        # Alias parity safeguard: `status` MUST NOT diverge from `where`.
        & $whereScript -CliArgs $Arguments
        exit $LASTEXITCODE
    }

    'update' {
        Assert-WhitelistedArguments -CommandName 'update' -ArgumentList $Arguments
        Assert-ProjectSetup -CommandName 'update' -ArgumentList $Arguments

        $updateScript = Join-Path $scriptRoot 'specrew-update.ps1'
        if (-not (Test-Path -LiteralPath $updateScript)) {
            Write-Host "ERROR: specrew-update.ps1 not found at $updateScript" -ForegroundColor Red
            exit 1
        }

        & pwsh -NoProfile -ExecutionPolicy Bypass -File $updateScript @Arguments
        exit $LASTEXITCODE
    }

    'version' {
        Assert-WhitelistedArguments -CommandName 'version' -ArgumentList $Arguments

        $versionScript = Join-Path $scriptRoot 'specrew-version.ps1'
        if (-not (Test-Path -LiteralPath $versionScript)) {
            Write-Host "ERROR: specrew-version.ps1 not found at $versionScript" -ForegroundColor Red
            exit 1
        }

        & pwsh -NoProfile -ExecutionPolicy Bypass -File $versionScript @Arguments
        exit $LASTEXITCODE
    }

    'install-shell-wrappers' {
        # feature 140 / Proposal 153: install/refresh Unix shell wrappers (macOS/Linux).
        # Module-level command (no project required). The installer validates its own
        # args (PS-style -BinDir/-Force/-WhatIf and shell-style --bin-dir/--force/--whatif).
        $installShellWrappersScript = Join-Path $scriptRoot 'specrew-install-shell-wrappers.ps1'
        if (-not (Test-Path -LiteralPath $installShellWrappersScript)) {
            Write-Host "ERROR: specrew-install-shell-wrappers.ps1 not found at $installShellWrappersScript" -ForegroundColor Red
            exit 1
        }

        & pwsh -NoProfile -ExecutionPolicy Bypass -File $installShellWrappersScript @Arguments
        exit $LASTEXITCODE
    }

    'host' {
        # F-043 multi-host inspection + selection command (Proposal 104)
        # No Assert-WhitelistedArguments — host command takes positional subcommand + kind, not flags
        $hostScript = Join-Path $scriptRoot 'specrew-host.ps1'
        if (-not (Test-Path -LiteralPath $hostScript)) {
            Write-Host "ERROR: specrew-host.ps1 not found at $hostScript" -ForegroundColor Red
            exit 1
        }

        # Forward positional args: <subcommand> [<kind>] [--project-path <path>]
        & pwsh -NoProfile -ExecutionPolicy Bypass -File $hostScript @Arguments
        exit $LASTEXITCODE
    }

    'hooks' {
        # F-174 iter-11 (FR-028 layer 2): discoverable hook install/repair/status surface.
        # No Assert-WhitelistedArguments / no project-setup gate — `status` must run even in a broken
        # project (it is the repair surface); the script parses its own Unix-style flags.
        $hooksScript = Join-Path $scriptRoot 'specrew-hooks.ps1'
        if (-not (Test-Path -LiteralPath $hooksScript)) {
            Write-Host "ERROR: specrew-hooks.ps1 not found at $hooksScript" -ForegroundColor Red
            exit 1
        }

        # Forward positional args: <status|install|remove> [--host <h>] [--force] [--project-path <path>]
        & pwsh -NoProfile -ExecutionPolicy Bypass -File $hooksScript @Arguments
        exit $LASTEXITCODE
    }

    'handover' {
        # F-174 iter-11 (T001, FR-022 / DF-7): the agent-callable handover BODY-authoring surface (the
        # reachable replacement for the un-exported Write-SpecrewHandoverContext). No project-setup gate —
        # it is fail-open and parses its own Unix-style flags + reads the body from --from/stdin.
        $handoverScript = Join-Path $scriptRoot 'specrew-handover.ps1'
        if (-not (Test-Path -LiteralPath $handoverScript)) {
            Write-Host "ERROR: specrew-handover.ps1 not found at $handoverScript" -ForegroundColor Red
            exit 1
        }

        # Forward positional args: author [--from <file>] [--feature <ref>] [--boundary <stage>] [--host <kind>]
        & pwsh -NoProfile -ExecutionPolicy Bypass -File $handoverScript @Arguments
        exit $LASTEXITCODE
    }

    default {
        Write-Host "ERROR: Unknown command '$Command'" -ForegroundColor Red
        Write-Host "Run 'specrew help' or '/specrew-help' to see the supported Specrew command catalog." -ForegroundColor Yellow
        Write-Host ""
        Show-Usage
        exit 1
    }
}
