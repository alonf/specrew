<#
.SYNOPSIS
    `specrew config` - read and set Specrew project configuration (F-051 Iteration 1).

.DESCRIPTION
    Iteration 1 supports the multi-session switch:
      specrew config get session_mode
      specrew config set session_mode <single|multi>

    Dispatched from the `config` case in scripts/specrew.ps1. Session-mode logic lives
    in scripts/internal/session-config.ps1.
#>
[CmdletBinding()]
param(
    [Parameter(Position = 0)]
    [string]$Command,

    [Parameter(Position = 1)]
    [string]$Key,

    [Parameter(Position = 2)]
    [string]$Value,

    [string]$ProjectPath,

    [Parameter(ValueFromRemainingArguments = $true)]
    [string[]]$Rest
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

# Resolve --project-path / --project-path=<value> from remaining args when -ProjectPath
# was not bound PowerShell-style (the CLI dispatcher passes Unix-style flags).
if (-not $ProjectPath) {
    $remaining = @($Rest | Where-Object { -not [string]::IsNullOrWhiteSpace($_) })
    for ($i = 0; $i -lt $remaining.Count; $i++) {
        $arg = $remaining[$i]
        if ($arg -match '^--project-path=(.+)$') { $ProjectPath = $Matches[1]; break }
        if ($arg -ieq '--project-path' -and ($i + 1) -lt $remaining.Count) { $ProjectPath = $remaining[$i + 1]; break }
    }
}
if (-not $ProjectPath) { $ProjectPath = (Get-Location).Path }

function Write-ConfigError {
    param([Parameter(Mandatory = $true)][string]$Message)
    Write-Host ("ERROR: {0}" -f $Message) -ForegroundColor Red
    Write-Host "Usage: specrew config <get|set> session_mode [<single|multi>]" -ForegroundColor Yellow
    exit 1
}

if ([string]::IsNullOrWhiteSpace($Command)) {
    Write-ConfigError "Missing subcommand."
}

$sessionConfig = Join-Path $PSScriptRoot 'internal/session-config.ps1'
if (-not (Test-Path -LiteralPath $sessionConfig -PathType Leaf)) {
    Write-ConfigError "Internal helper not found: $sessionConfig"
}
. $sessionConfig

$normalizedCommand = $Command.Trim().ToLowerInvariant()
$normalizedKey = if ($Key) { $Key.Trim().ToLowerInvariant() } else { '' }

switch ($normalizedCommand) {
    'get' {
        if ($normalizedKey -ne 'session_mode') {
            Write-ConfigError ("Unknown config key '{0}'. Iteration 1 supports: session_mode." -f $Key)
        }
        $mode = Get-SessionMode -ProjectRoot $ProjectPath
        Write-Output $mode
        exit 0
    }

    'set' {
        if ($normalizedKey -ne 'session_mode') {
            Write-ConfigError ("Unknown config key '{0}'. Iteration 1 supports: session_mode." -f $Key)
        }
        if ([string]::IsNullOrWhiteSpace($Value)) {
            Write-ConfigError "'config set session_mode' requires a value (single|multi)."
        }
        try {
            $applied = Set-SessionMode -ProjectRoot $ProjectPath -Value $Value
        }
        catch {
            Write-ConfigError $_.Exception.Message
        }
        Write-Host ("session_mode set to '{0}'." -f $applied) -ForegroundColor Green
        exit 0
    }

    default {
        Write-ConfigError ("Unknown subcommand '{0}'. Valid: get, set." -f $Command)
    }
}
