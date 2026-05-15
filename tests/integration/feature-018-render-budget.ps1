[CmdletBinding()]
param()

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

function Write-Pass {
    param([string]$Message)
    Write-Host "PASS: $Message" -ForegroundColor Green
}

function Write-Fail {
    param([string]$Message)
    Write-Host "FAIL: $Message" -ForegroundColor Red
}

function Assert-True {
    param(
        [Parameter(Mandatory = $true)][bool]$Condition,
        [Parameter(Mandatory = $true)][string]$Message
    )

    if (-not $Condition) {
        Write-Fail $Message
        exit 1
    }
}

$repoRoot = (Resolve-Path (Join-Path -Path $PSScriptRoot -ChildPath '..\..')).Path
$rendererPath = Join-Path $repoRoot 'scripts\internal\dashboard-renderer.ps1'
$fixtureRoot = Join-Path $repoRoot 'tests\integration\fixtures\feature-018-dashboard\performance-repository'

. $rendererPath

$richOverride = @{
    IsWindows               = $false
    OutputRedirected        = $false
    Term                    = 'xterm-256color'
    ConsoleEncodingName     = 'utf-8'
    Lang                    = 'en_US.UTF-8'
    SupportsVirtualTerminal = $true
}

$featureCount = @(Get-ChildItem -LiteralPath (Join-Path $fixtureRoot 'specs') -Directory).Count
Assert-True -Condition ($featureCount -eq 16) -Message 'The performance fixture should contain 16 feature directories.'

$null = Get-SpecrewDashboardSnapshot -ProjectRoot $fixtureRoot -CapabilityOverrides $richOverride
$elapsed = (Measure-Command {
        $snapshot = Get-SpecrewDashboardSnapshot -ProjectRoot $fixtureRoot -CapabilityOverrides $richOverride
        $null = ConvertTo-SpecrewDashboardLines -Snapshot $snapshot
    }).TotalMilliseconds

Assert-True -Condition ($elapsed -le 1500) -Message ("Render-budget fixture exceeded the 1.5 second budget ({0:N0} ms)." -f $elapsed)
Write-Pass ("Feature 018 render-budget fixture stayed within budget at {0:N0} ms" -f $elapsed)
exit 0
