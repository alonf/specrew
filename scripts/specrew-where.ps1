[CmdletBinding()]
param(
    [string]$ProjectPath = '.',
    [string]$FeatureId,
    [string]$IterationNumber,
    [switch]$Compact,
    [switch]$Ascii,
    [switch]$NoColor,
    [int]$RecentCount = 6,
    [int]$BarWidth = 28,
    [switch]$Json,
    [switch]$Team,
    [switch]$Help,
    [string]$OutputPath,
    [ValidateSet('live', 'iteration-closeout', 'feature-closeout')]
    [string]$CaptureKind = 'live',
    [switch]$PreserveExistingArtifact,
    [AllowEmptyString()][string]$HistoricalNotice,
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

$rendererPath = Join-Path $PSScriptRoot 'internal\dashboard-renderer.ps1'
if (-not (Test-Path -LiteralPath $rendererPath -PathType Leaf)) {
    throw "Missing dashboard renderer helper '$rendererPath'."
}
. $rendererPath

function Show-Usage {
    @'
specrew where - show the velocity dashboard ("where am I?")

Usage:
  specrew where [options]
  specrew status [options]
  scripts/specrew-where.ps1 [options]

Options:
  --project-path <path>  Target project root (default: current directory)
  --feature <id>         Restrict the dashboard to one feature
  --iteration <NNN>      Focus on one iteration when it exists
  --compact              Render the fixed compact dashboard (24 lines max)
  --ASCII                Force monochrome / ASCII-safe fallback rendering
  --no-color             Force monochrome output
  --RecentCount <N>      Show N Recent Shipped entries (default: 6)
  --BarWidth <N>         Use N columns for rich shipped bars (default: 28)
  --team                 Reserved team path; falls back to the personal dashboard
  --json                 Emit the assembled snapshot as JSON
  --output-path <path>   Persist the rendered dashboard or closeout snapshot
  --capture-kind <kind>  live | iteration-closeout | feature-closeout
  --preserve-existing-artifact
                         When writing an artifact, keep any existing file untouched
  --help                 Show this help message

Examples:
  specrew where
  specrew status --compact
  specrew where --ASCII
  specrew where --RecentCount 4 --BarWidth 20
  specrew where --no-color
  specrew where --team
  pwsh -NoProfile -File .\scripts\specrew-where.ps1 --ASCII --BarWidth 20
'@ | Write-Host
}

function Convert-UnixStyleArguments {
    param(
        [string]$ProjectPath,
        [string]$FeatureId,
        [string]$IterationNumber,
        [bool]$Compact,
        [bool]$Ascii,
        [bool]$NoColor,
        [int]$RecentCount,
        [int]$BarWidth,
        [bool]$Json,
        [bool]$Team,
        [bool]$Help,
        [string]$OutputPath,
        [string]$CaptureKind,
        [bool]$PreserveExistingArtifact,
        [string]$HistoricalNotice,
        [string[]]$CliArgs
    )

    $result = [ordered]@{
        ProjectPath              = $ProjectPath
        FeatureId                = $FeatureId
        IterationNumber          = $IterationNumber
        Compact                  = $Compact
        Ascii                    = $Ascii
        NoColor                  = $NoColor
        RecentCount              = if ($RecentCount -gt 0) { $RecentCount } else { 6 }
        BarWidth                 = if ($BarWidth -gt 0) { $BarWidth } else { 28 }
        Json                     = $Json
        Team                     = $Team
        Help                     = $Help
        OutputPath               = $OutputPath
        CaptureKind              = $CaptureKind
        PreserveExistingArtifact = $PreserveExistingArtifact
        HistoricalNotice         = $HistoricalNotice
    }

    $CliArgs = @($CliArgs | Where-Object { -not [string]::IsNullOrWhiteSpace($_) })
    for ($index = 0; $index -lt $CliArgs.Count; $index++) {
        $argument = $CliArgs[$index]
        $parsedValue = 0
        switch -Regex ($argument) {
            '^--project-path(?:=(.+))?$' {
                if ($Matches[1]) {
                    $result.ProjectPath = $Matches[1]
                }
                else {
                    $index++
                    if ($index -ge $CliArgs.Count) { throw '--project-path requires a value.' }
                    $result.ProjectPath = $CliArgs[$index]
                }
            }
            '^--feature(?:=(.+))?$' {
                if ($Matches[1]) {
                    $result.FeatureId = $Matches[1]
                }
                else {
                    $index++
                    if ($index -ge $CliArgs.Count) { throw '--feature requires a value.' }
                    $result.FeatureId = $CliArgs[$index]
                }
            }
            '^--iteration(?:=(.+))?$' {
                if ($Matches[1]) {
                    $result.IterationNumber = $Matches[1]
                }
                else {
                    $index++
                    if ($index -ge $CliArgs.Count) { throw '--iteration requires a value.' }
                    $result.IterationNumber = $CliArgs[$index]
                }
            }
            '^--output-path(?:=(.+))?$' {
                if ($Matches[1]) {
                    $result.OutputPath = $Matches[1]
                }
                else {
                    $index++
                    if ($index -ge $CliArgs.Count) { throw '--output-path requires a value.' }
                    $result.OutputPath = $CliArgs[$index]
                }
            }
            '^--capture-kind(?:=(.+))?$' {
                if ($Matches[1]) {
                    $result.CaptureKind = $Matches[1]
                }
                else {
                    $index++
                    if ($index -ge $CliArgs.Count) { throw '--capture-kind requires a value.' }
                    $result.CaptureKind = $CliArgs[$index]
                }
            }
            '^--historical-notice(?:=(.+))?$' {
                if ($Matches[1]) {
                    $result.HistoricalNotice = $Matches[1]
                }
                else {
                    $index++
                    if ($index -ge $CliArgs.Count) { throw '--historical-notice requires a value.' }
                    $result.HistoricalNotice = $CliArgs[$index]
                }
            }
            '^--compact$' { $result.Compact = $true }
            '^--ascii$' { $result.Ascii = $true }
            '^--no-color$' { $result.NoColor = $true }
            '^--recentcount(?:=(.+))?$' {
                $value = if ($Matches[1]) {
                    $Matches[1]
                }
                else {
                    $index++
                    if ($index -ge $CliArgs.Count) { throw '--RecentCount requires a value.' }
                    $CliArgs[$index]
                }

                if (-not [int]::TryParse([string]$value, [ref]$parsedValue) -or $parsedValue -le 0) {
                    throw '--RecentCount requires a positive integer.'
                }

                $result.RecentCount = $parsedValue
            }
            '^--barwidth(?:=(.+))?$' {
                $value = if ($Matches[1]) {
                    $Matches[1]
                }
                else {
                    $index++
                    if ($index -ge $CliArgs.Count) { throw '--BarWidth requires a value.' }
                    $CliArgs[$index]
                }

                if (-not [int]::TryParse([string]$value, [ref]$parsedValue) -or $parsedValue -le 0) {
                    throw '--BarWidth requires a positive integer.'
                }

                $result.BarWidth = $parsedValue
            }
            '^--json$' { $result.Json = $true }
            '^--team$' { $result.Team = $true }
            '^--preserve-existing-artifact$' { $result.PreserveExistingArtifact = $true }
            '^(?:-h|--help)$' { $result.Help = $true }
            default { throw ("Unknown argument for specrew where: {0}" -f $argument) }
        }
    }

    return [pscustomobject]$result
}

$parsed = Convert-UnixStyleArguments `
    -ProjectPath $ProjectPath `
    -FeatureId $FeatureId `
    -IterationNumber $IterationNumber `
    -Compact $Compact.IsPresent `
    -Ascii $Ascii.IsPresent `
    -NoColor $NoColor.IsPresent `
    -RecentCount $RecentCount `
    -BarWidth $BarWidth `
    -Json $Json.IsPresent `
    -Team $Team.IsPresent `
    -Help $Help.IsPresent `
    -OutputPath $OutputPath `
    -CaptureKind $CaptureKind `
    -PreserveExistingArtifact $PreserveExistingArtifact.IsPresent `
    -HistoricalNotice $HistoricalNotice `
    -CliArgs $CliArgs

if ($parsed.Help) {
    Show-Usage
    exit 0
}

$snapshot = Get-SpecrewDashboardSnapshot `
    -ProjectRoot $parsed.ProjectPath `
    -FeatureId $parsed.FeatureId `
    -IterationNumber $parsed.IterationNumber `
    -Compact:$parsed.Compact `
    -Ascii:$parsed.Ascii `
    -NoColor:$parsed.NoColor `
    -RecentCount $parsed.RecentCount `
    -BarWidth $parsed.BarWidth `
    -CaptureKind $parsed.CaptureKind `
    -Team:$parsed.Team

$lines = if ($parsed.Compact) {
    ConvertTo-SpecrewCompactDashboardLines -Snapshot $snapshot
}
else {
    ConvertTo-SpecrewDashboardLines -Snapshot $snapshot
}

if (-not [string]::IsNullOrWhiteSpace($parsed.OutputPath)) {
    $resolvedOutputPath = Resolve-ProjectPath -Path $parsed.OutputPath
    if ($parsed.PreserveExistingArtifact -and (Test-Path -LiteralPath $resolvedOutputPath -PathType Leaf)) {
        Write-Host "Preserved existing dashboard artifact at $resolvedOutputPath"
    }
    else {
        $artifactContent = ConvertTo-SpecrewDashboardArtifactContent -Snapshot $snapshot -Lines $lines -CaptureKind $parsed.CaptureKind -HistoricalNotice $parsed.HistoricalNotice
        Write-Utf8FileAtomic -Path $resolvedOutputPath -Content $artifactContent
        Write-Host "Wrote dashboard artifact to $resolvedOutputPath"
    }
}

if ($parsed.Json) {
    $payload = [pscustomobject]@{
        snapshot = $snapshot
        lines    = $lines
    }
    $payload | ConvertTo-Json -Depth 8
    exit 0
}

Write-SpecrewDashboardLines -Lines $lines -ColorMode $snapshot.color_mode
exit 0
