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

function Get-SectionLines {
    param(
        [AllowEmptyCollection()]
        [AllowEmptyString()]
        [Parameter(Mandatory = $true)][string[]]$Lines,
        [Parameter(Mandatory = $true)][string]$Header
    )

    $startIndex = [array]::IndexOf($Lines, $Header)
    if ($startIndex -lt 0) {
        return @()
    }

    $sectionLines = New-Object System.Collections.Generic.List[string]
    for ($index = $startIndex + 1; $index -lt $Lines.Count; $index++) {
        if ([string]::IsNullOrWhiteSpace($Lines[$index])) {
            break
        }

        $sectionLines.Add($Lines[$index]) | Out-Null
    }

    return $sectionLines.ToArray()
}

$repoRoot = (Resolve-Path (Join-Path -Path $PSScriptRoot -ChildPath '..\..')).Path
$rendererPath = Join-Path $repoRoot 'scripts\internal\dashboard-renderer.ps1'
$fixtureRoot = Join-Path $repoRoot 'tests\integration\fixtures\feature-018-dashboard\rich-capable-repository'

. $rendererPath

$richOverride = @{
    IsWindows              = $false
    Term                   = 'xterm-256color'
    ConsoleEncodingName    = 'utf-8'
    Lang                   = 'en_US.UTF-8'
    SupportsVirtualTerminal = $true
}
$windowsFallbackOverride = @{
    IsWindows              = $true
    Term                   = 'xterm-256color'
    ConsoleEncodingName    = 'utf-8'
    Lang                   = 'en_US.UTF-8'
    SupportsVirtualTerminal = $false
}

$richProfile = Get-SpecrewDashboardRenderProfile -RecentCount 6 -BarWidth 28 -CapabilityOverrides $richOverride
Assert-True -Condition ($richProfile.rendering_mode -eq 'rich') -Message 'Rich-capable terminals should default to rich rendering.'
Assert-True -Condition ($richProfile.recent_count -eq 6) -Message 'Recent Shipped should default to 6 entries.'
Assert-True -Condition ($richProfile.bar_width -eq 28) -Message 'Rich-mode shipped bars should default to width 28.'

$asciiProfile = Get-SpecrewDashboardRenderProfile -Ascii -CapabilityOverrides $richOverride
Assert-True -Condition ($asciiProfile.rendering_mode -eq 'monochrome') -Message '--ASCII should force monochrome-safe fallback.'

$previousNoUnicode = $env:NO_UNICODE
try {
    $env:NO_UNICODE = '1'
    $noUnicodeProfile = Get-SpecrewDashboardRenderProfile -CapabilityOverrides $richOverride
    Assert-True -Condition ($noUnicodeProfile.rendering_mode -eq 'monochrome') -Message 'NO_UNICODE should disable rich rendering.'
}
finally {
    $env:NO_UNICODE = $previousNoUnicode
}

$windowsFallbackProfile = Get-SpecrewDashboardRenderProfile -CapabilityOverrides $windowsFallbackOverride
Assert-True -Condition ($windowsFallbackProfile.rendering_mode -eq 'monochrome') -Message 'Missing Windows VT support should force fallback.'
Assert-True -Condition ($windowsFallbackProfile.fallback_reason -match 'Windows virtual-terminal support') -Message 'Windows fallback should explain the VT reason.'

$redirectedWindowsOverride = @{
    IsWindows               = $true
    OutputRedirected        = $true
    Term                    = 'xterm-256color'
    ConsoleEncodingName     = 'utf-8'
    Lang                    = 'en_US.UTF-8'
    SupportsVirtualTerminal = $true
}
$redirectedWindowsProfile = Get-SpecrewDashboardRenderProfile -CapabilityOverrides $redirectedWindowsOverride
Assert-True -Condition ($redirectedWindowsProfile.rendering_mode -eq 'rich') -Message 'Output redirection alone should not disable rich rendering.'
Assert-True -Condition ([string]::IsNullOrWhiteSpace([string]$redirectedWindowsProfile.fallback_reason)) -Message 'Rich rendering should not report a fallback reason when redirected output is the only difference.'

$richSnapshot = Get-SpecrewDashboardSnapshot -ProjectRoot $fixtureRoot -CapabilityOverrides $richOverride
$richLines = @(ConvertTo-SpecrewDashboardLines -Snapshot $richSnapshot)
$richText = $richLines -join "`n"

Assert-True -Condition ($richText -match 'Today: \d{4}-\d{2}-\d{2}') -Message 'Header should include the Today anchor.'
Assert-True -Condition ($richText -match 'Captured: \d{4}-\d{2}-\d{2}T\d{2}:\d{2}:\d{2}Z') -Message 'Header should include the captured timestamp.'
Assert-True -Condition ($richText -match 'Feature: → F-018') -Message 'Rich mode should emphasize the active feature with the arrow.'
Assert-True -Condition ($richText -match 'Sparkline: ') -Message 'Velocity should include the sparkline in rich mode.'
Assert-True -Condition ((@($richLines | Where-Object { $_ -match '^Sparkline:' })).Count -eq 1) -Message 'The sparkline should appear exactly once.'
Assert-True -Condition ($richText -match 'Restore rich dashboard density while preserving truthful fallback semantics .*\.{3}') -Message 'Roadmap descriptions should truncate beyond 80 characters.'

$recentShippedLines = @(Get-SectionLines -Lines $richLines -Header 'RECENT SHIPPED')
$recentPattern = '^[✓] F-\d{3}\s+· iter-\d{3}\s+[█░]{28}\s+\d+\.\d SP\s+\d+ iter \d{4}-\d{2}-\d{2}\s+.{1,32}$'
Assert-True -Condition ((@($recentShippedLines | Where-Object { $_ -match $recentPattern })).Count -eq $recentShippedLines.Count) -Message 'Recent Shipped rows should keep aligned fixed-width columns and a 32-character max title.'
$recentBarStartIndexes = @($recentShippedLines | ForEach-Object { [regex]::Match($_, '[█░]{28}').Index } | Select-Object -Unique)
Assert-True -Condition ($recentBarStartIndexes.Count -eq 1) -Message 'Recent Shipped bars should align to a fixed column.'

$roadmapLines = @(Get-SectionLines -Lines $richLines -Header 'ROADMAP')
$roadmapSummaryLines = @($roadmapLines | Where-Object { $_ -match '^[✓○◐] \[[█░]{16}\]\s+\d{1,3}%\s+.{1,12}\s+(?:shipped|queued|in-progress|drifted-over)\s+.+' })
Assert-True -Condition ($roadmapSummaryLines.Count -eq 3) -Message 'Roadmap summary rows should render aligned fixed-width bar, SP, and status columns.'
$roadmapBarStartIndexes = @($roadmapSummaryLines | ForEach-Object { [regex]::Match($_, '\[[█░]{16}\]\s+\d{1,3}%').Index } | Select-Object -Unique)
Assert-True -Condition ($roadmapBarStartIndexes.Count -eq 1) -Message 'Roadmap bars should align to a fixed early column.'
for ($index = 0; $index -lt $roadmapSummaryLines.Count; $index++) {
    $summaryLine = $roadmapSummaryLines[$index]
    $detailLine = $roadmapLines[($index * 2) + 1]
    $phaseStart = ([regex]::Match($summaryLine, '(?:shipped|queued|in-progress|drifted-over)\s+').Index + [regex]::Match($summaryLine, '(?:shipped|queued|in-progress|drifted-over)\s+').Length)
    $detailStart = [regex]::Match($detailLine, '\S').Index
    Assert-True -Condition ($detailStart -eq $phaseStart) -Message 'Roadmap descriptions should align with the phase-name column.'
}

$overrideSnapshot = Get-SpecrewDashboardSnapshot -ProjectRoot $fixtureRoot -RecentCount 4 -BarWidth 20 -CapabilityOverrides $richOverride
Assert-True -Condition ($overrideSnapshot.recent_shipped.Count -eq 4) -Message '--RecentCount should limit the Recent Shipped section.'
$overrideMeter = Format-SpecrewDashboardMeter -Value 10 -Maximum 10 -Width $overrideSnapshot.render_profile.bar_width -RenderProfile $overrideSnapshot.render_profile
Assert-True -Condition ($overrideMeter.Length -eq 20) -Message '--BarWidth should control the rich-mode meter width.'

$sampleWithAnsi = ('{0}[32m✓ שלום{0}[0m' -f [char]27)
$stripped = Remove-SpecrewAnsiEscapeSequences -Text $sampleWithAnsi
Assert-True -Condition ($stripped -eq '✓ שלום') -Message 'ANSI stripping should preserve Unicode text.'

$artifactContent = ConvertTo-SpecrewDashboardArtifactContent -Snapshot $richSnapshot -Lines $richLines -CaptureKind 'feature-closeout' -HistoricalNotice $null
Assert-True -Condition ($artifactContent -notmatch ([char]27 + '\[[0-9;]*[A-Za-z]')) -Message 'Stored dashboard artifacts should not contain ANSI escapes.'
Assert-True -Condition ($artifactContent -match '✓ F-017|→ F-018|ℹ ') -Message 'Stored dashboard artifacts should preserve rich Unicode glyphs.'
Assert-True -Condition ($artifactContent -match '\*\*Rendering Mode\*\*:\s+rich') -Message 'Stored dashboard artifacts should record the effective rendering mode.'

$iterationOne = [pscustomobject]@{
    feature_ref          = '017-velocity-dashboard'
    feature_title        = 'Feature Specification: Velocity Dashboard'
    iteration_label      = 'feature-017.iter-001'
    actual_story_points  = [decimal]18
    planned_story_points = [decimal]11
    elapsed_days         = 1
    closed_at            = [datetime]'2026-05-15T00:00:00Z'
    iteration_ref        = '001'
    iteration_status     = 'closed'
}
$iterationTwo = [pscustomobject]@{
    feature_ref          = '017-velocity-dashboard'
    feature_title        = 'Feature Specification: Velocity Dashboard'
    iteration_label      = 'feature-017.iter-002'
    actual_story_points  = [decimal]18
    planned_story_points = [decimal]16
    elapsed_days         = 1
    closed_at            = [datetime]'2026-05-15T00:00:00Z'
    iteration_ref        = '002'
    iteration_status     = 'closed'
}
$featureRecord = [pscustomobject]@{ closed_iterations = @($iterationOne, $iterationTwo) }
$recentEntryOne = New-SpecrewRecentShippedEntry -Iteration $iterationOne -FeatureRecord $featureRecord
$recentEntryTwo = New-SpecrewRecentShippedEntry -Iteration $iterationTwo -FeatureRecord $featureRecord
Assert-True -Condition ($recentEntryOne.label -ne $recentEntryTwo.label) -Message 'Recent Shipped labels should stay unique across multiple closed iterations for the same feature.'
Assert-True -Condition ($recentEntryOne.label -eq 'F-017 · iter-001') -Message 'Recent Shipped labels should combine the feature code with the iteration token.'

Write-Pass 'Feature 018 dashboard unit coverage: render-profile precedence, rich rendering, override knobs, sparkline scope, roadmap truncation, and ANSI stripping with Unicode preservation'
exit 0
