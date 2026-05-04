[CmdletBinding(PositionalBinding = $false)]
param(
    [Parameter(Mandatory = $false, Position = 0)]
    [string]$Command,
    
    [Parameter(ValueFromRemainingArguments = $true)]
    [string[]]$Arguments
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

function Show-Usage {
    @'
specrew - Spec-governed AI crew operating model

Usage:
  specrew init [options]           Bootstrap Specrew in the current or target project
  specrew start [args]             Start or resume the Squad-driven Spec Kit lifecycle
  specrew team <command> [args]    Manage Squad team members

Commands:
  init     Initialize Specrew (Spec Kit + Squad + governance)
  start    Start or resume feature delivery through Squad + Spec Kit
  team     Manage team members (add, update, remove, list)
  help     Show this help message

Examples:
  specrew init --project-path .
  specrew start
  specrew start "Build a REST API for user management"
  specrew team list
  specrew team add security-analyst --role "Security Analyst" --charter "Review security"
  specrew team update security-analyst --charter "Updated charter"
  specrew team remove security-analyst

For detailed command help:
  specrew init --help
  specrew start --help
  specrew team --help (shows usage when no subcommand provided)
'@ | Write-Host
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

        & pwsh -NoProfile -ExecutionPolicy Bypass -File $startScript @Arguments
        exit $LASTEXITCODE
    }
    
    default {
        Write-Host "ERROR: Unknown command '$Command'" -ForegroundColor Red
        Write-Host ""
        Show-Usage
        exit 1
    }
}
