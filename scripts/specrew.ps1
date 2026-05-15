param(
    [Parameter(Mandatory = $false, Position = 0)]
    [string]$Command,

    [Alias('help')]
    [switch]$HelpRequested,

    [Alias('info')]
    [switch]$InfoRequested,

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

function Show-Usage {
    @'
specrew - Spec-governed AI crew operating model

Usage:
  specrew init [options]           Bootstrap Specrew in the current or target project
  specrew start [args]             Start or resume the Squad-driven Spec Kit lifecycle
  specrew review [options]         Replay the persisted reviewer closeout packet
  specrew where [options]          Show the velocity dashboard ("where am I?")
  specrew status [options]         Alias for specrew where
  specrew update [options]         Refresh Specrew assets or upgrade managed platforms
  specrew team <command> [args]    Manage Squad team members

Commands:
  init     Initialize Specrew (Spec Kit + Squad + governance)
  start    Start or resume feature delivery through Squad + Spec Kit
  review   Show reviewer summary for a completed iteration
  where    Show the velocity dashboard
  status   Alias for where
  update   Refresh Specrew or upgrade Spec Kit / Squad in an existing project
  team     Manage team members (add, update, remove, list)
  help     Show this help message

Examples:
  specrew init --project-path .
  specrew start
  specrew start "Build a REST API for user management"
  specrew review --project-path .
  specrew where
  specrew status --compact
  specrew update
  specrew update --info
  specrew update --all
  specrew team list
  specrew team add security-analyst --role "Security Analyst" --charter "Review security"
  specrew team update security-analyst --charter "Updated charter"
  specrew team remove security-analyst

For detailed command help:
  specrew init --help
  specrew start --help
  specrew review --help
  specrew where --help
  specrew update --help
  specrew team --help (shows usage when no subcommand provided)
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

$scriptRoot = Split-Path -Parent $PSCommandPath

if (-not $Command -or $Command -eq 'help' -or $Command -eq '--help' -or $Command -eq '-h') {
    Show-Usage
    exit 0
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
    
    'team' {
        $teamScript = Join-Path $scriptRoot 'specrew-team.ps1'
        if (-not (Test-Path -LiteralPath $teamScript)) {
            Write-Host "ERROR: specrew-team.ps1 not found at $teamScript" -ForegroundColor Red
            exit 1
        }
        
        # If no subcommand provided, show usage
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
        $reviewScript = Join-Path $scriptRoot 'specrew-review.ps1'
        if (-not (Test-Path -LiteralPath $reviewScript)) {
            Write-Host "ERROR: specrew-review.ps1 not found at $reviewScript" -ForegroundColor Red
            exit 1
        }

        & pwsh -NoProfile -ExecutionPolicy Bypass -File $reviewScript @Arguments
        exit $LASTEXITCODE
    }

    'where' {
        $whereScript = Join-Path $scriptRoot 'specrew-where.ps1'
        if (-not (Test-Path -LiteralPath $whereScript)) {
            Write-Host "ERROR: specrew-where.ps1 not found at $whereScript" -ForegroundColor Red
            exit 1
        }

        & pwsh -NoProfile -ExecutionPolicy Bypass -File $whereScript @Arguments
        exit $LASTEXITCODE
    }

    'status' {
        $whereScript = Join-Path $scriptRoot 'specrew-where.ps1'
        if (-not (Test-Path -LiteralPath $whereScript)) {
            Write-Host "ERROR: specrew-where.ps1 not found at $whereScript" -ForegroundColor Red
            exit 1
        }

        & pwsh -NoProfile -ExecutionPolicy Bypass -File $whereScript @Arguments
        exit $LASTEXITCODE
    }

    'update' {
        $updateScript = Join-Path $scriptRoot 'specrew-update.ps1'
        if (-not (Test-Path -LiteralPath $updateScript)) {
            Write-Host "ERROR: specrew-update.ps1 not found at $updateScript" -ForegroundColor Red
            exit 1
        }

        & pwsh -NoProfile -ExecutionPolicy Bypass -File $updateScript @Arguments
        exit $LASTEXITCODE
    }
    
    default {
        Write-Host "ERROR: Unknown command '$Command'" -ForegroundColor Red
        Write-Host ""
        Show-Usage
        exit 1
    }
}
