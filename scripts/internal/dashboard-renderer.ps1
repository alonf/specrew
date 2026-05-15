Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

$sharedGovernancePath = Join-Path (Split-Path -Parent (Split-Path -Parent $PSScriptRoot)) 'extensions\specrew-speckit\scripts\shared-governance.ps1'
if (-not (Test-Path -LiteralPath $sharedGovernancePath -PathType Leaf)) {
    throw "Missing shared governance helper '$sharedGovernancePath'."
}
. $sharedGovernancePath

function Reset-SpecrewDashboardWarnings {
    $script:SpecrewDashboardWarnings = New-Object System.Collections.Generic.List[string]
}

function Add-SpecrewDashboardWarning {
    param([AllowNull()][string]$Message)

    if ([string]::IsNullOrWhiteSpace($Message)) {
        return
    }

    if (-not (Get-Variable -Name SpecrewDashboardWarnings -Scope Script -ErrorAction SilentlyContinue)) {
        Reset-SpecrewDashboardWarnings
    }

    $script:SpecrewDashboardWarnings.Add($Message) | Out-Null
}

function Get-SpecrewDashboardWarnings {
    if (-not (Get-Variable -Name SpecrewDashboardWarnings -Scope Script -ErrorAction SilentlyContinue)) {
        return @()
    }

    return @($script:SpecrewDashboardWarnings | Select-Object -Unique)
}

function Get-SpecrewMarkdownContent {
    param([Parameter(Mandatory = $true)][string]$Path)

    return [System.IO.File]::ReadAllLines($Path, [System.Text.Encoding]::UTF8)
}

function Get-SpecrewMarkdownMetadataValue {
    param(
        [AllowNull()]
        [AllowEmptyCollection()]
        [AllowEmptyString()]
        [Parameter(Mandatory = $true)][string[]]$Lines,
        [Parameter(Mandatory = $true)][string]$Label
    )

    $pattern = '^\*\*' + [regex]::Escape($Label) + '\*\*:\s*(.+?)\s*$'
    foreach ($line in $Lines) {
        if ($line -match $pattern) {
            return $Matches[1].Trim()
        }
    }

    return $null
}

function Get-SpecrewMarkdownHeadingValue {
    param(
        [AllowNull()]
        [AllowEmptyCollection()]
        [AllowEmptyString()]
        [Parameter(Mandatory = $true)][string[]]$Lines,
        [Parameter(Mandatory = $false)][string]$Fallback = ''
    )

    foreach ($line in $Lines) {
        if ($line -match '^#\s+(.+?)\s*$') {
            return $Matches[1].Trim()
        }
    }

    return $Fallback
}

function Get-SpecrewMarkdownSectionTable {
    param(
        [AllowNull()]
        [AllowEmptyCollection()]
        [AllowEmptyString()]
        [Parameter(Mandatory = $true)][string[]]$Lines,
        [Parameter(Mandatory = $true)][string]$Heading
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
            $row[$headers[$cellIndex]] = if ($cellIndex -lt $cells.Count) { $cells[$cellIndex] } else { '' }
        }

        $rows.Add([pscustomobject]$row) | Out-Null
    }

    return $rows.ToArray()
}

function Get-SpecrewYamlScalarValue {
    param([AllowNull()][string]$Value)

    if ($null -eq $Value) {
        return $null
    }

    $text = $Value.Trim()
    if ($text.Contains('#')) {
        $text = ($text -split '\s+#', 2)[0].Trim()
    }

    if (($text.StartsWith('"') -and $text.EndsWith('"')) -or ($text.StartsWith("'") -and $text.EndsWith("'"))) {
        $text = $text.Substring(1, $text.Length - 2)
    }

    if ($text -eq 'null') {
        return $null
    }

    return $text
}

function ConvertTo-SpecrewNullableDecimal {
    param([AllowNull()][string]$Value)

    if ([string]::IsNullOrWhiteSpace($Value)) {
        return $null
    }

    $match = [regex]::Match($Value, '-?\d+(?:\.\d+)?')
    if (-not $match.Success) {
        return $null
    }

    return [decimal]::Parse($match.Value, [System.Globalization.CultureInfo]::InvariantCulture)
}

function ConvertTo-SpecrewNullableDate {
    param([AllowNull()][string]$Value)

    if ([string]::IsNullOrWhiteSpace($Value)) {
        return $null
    }

    $match = [regex]::Match($Value, '\d{4}-\d{2}-\d{2}(?:T\d{2}:\d{2}:\d{2}Z)?')
    if (-not $match.Success) {
        return $null
    }

    try {
        return [datetime]::Parse($match.Value, [System.Globalization.CultureInfo]::InvariantCulture, [System.Globalization.DateTimeStyles]::AssumeUniversal)
    }
    catch {
        return $null
    }
}

function ConvertTo-SpecrewTitleCase {
    param([AllowNull()][string]$Value)

    if ([string]::IsNullOrWhiteSpace($Value)) {
        return ''
    }

    return [System.Globalization.CultureInfo]::InvariantCulture.TextInfo.ToTitleCase($Value.ToLowerInvariant())
}

function Get-SpecrewFeatureNumber {
    param([AllowNull()][string]$FeatureRef)

    if ([string]::IsNullOrWhiteSpace($FeatureRef)) {
        return $null
    }

    if ($FeatureRef -match '^(?<number>\d{3})') {
        return $Matches['number']
    }

    return $FeatureRef
}

function Format-SpecrewIterationIdentifier {
    param(
        [Parameter(Mandatory = $true)][string]$FeatureRef,
        [Parameter(Mandatory = $true)][string]$IterationRef
    )

    $featureNumber = Get-SpecrewFeatureNumber -FeatureRef $FeatureRef
    if ([string]::IsNullOrWhiteSpace($featureNumber)) {
        return $IterationRef
    }

    return "feature-$featureNumber.iter-$IterationRef"
}

function Get-SpecrewFeatureShortLabel {
    param([AllowNull()][string]$FeatureRef)

    $featureNumber = Get-SpecrewFeatureNumber -FeatureRef $FeatureRef
    if ([string]::IsNullOrWhiteSpace($featureNumber)) {
        return $FeatureRef
    }

    return "feature-$featureNumber"
}

function Get-SpecrewGitBranch {
    param([Parameter(Mandatory = $true)][string]$ProjectRoot)

    $gitCommand = Get-Command -Name 'git' -ErrorAction SilentlyContinue
    if ($null -eq $gitCommand) {
        return '(git unavailable)'
    }

    $branch = @(& git -C $ProjectRoot rev-parse --abbrev-ref HEAD 2>$null)
    if ($LASTEXITCODE -ne 0 -or $branch.Count -eq 0) {
        return '(detached)'
    }

    return ([string]$branch[0]).Trim()
}

function Get-SpecrewBoundaryCatalog {
    return @(
        [pscustomobject]@{ Name = 'planning'; Pattern = '^Feature \d+.* iteration \d+ planning boundary(?:\s|$)' },
        [pscustomobject]@{ Name = 'iteration-closeout'; Pattern = '^Feature \d+.* iteration \d+ closeout boundary(?:\s|$)' },
        [pscustomobject]@{ Name = 'feature-closeout'; Pattern = '^Feature \d+.*: feature-closeout boundary(?:\s|$)' }
    )
}

function Get-SpecrewBoundaryCommitMatch {
    param([AllowNull()][string]$Subject)

    if ([string]::IsNullOrWhiteSpace($Subject)) {
        return $null
    }

    foreach ($boundary in Get-SpecrewBoundaryCatalog) {
        if ($Subject -match $boundary.Pattern) {
            $featureNumber = if ($Subject -match 'Feature\s+(?<feature>\d+)') { [int]$Matches['feature'] } else { $null }
            $iterationNumber = if ($Subject -match 'iteration\s+(?<iteration>\d+)') { [int]$Matches['iteration'] } else { $null }
            return [pscustomobject]@{
                Boundary        = $boundary.Name
                FeatureNumber   = $featureNumber
                IterationNumber = $iterationNumber
                Subject         = $Subject.Trim()
            }
        }
    }

    return $null
}

function Get-SpecrewGitBoundaryCommits {
    param([Parameter(Mandatory = $true)][string]$ProjectRoot)

    $gitCommand = Get-Command -Name 'git' -ErrorAction SilentlyContinue
    if ($null -eq $gitCommand) {
        return @()
    }

    $rawLog = @(git -C $ProjectRoot --no-pager log --grep='boundary' --regexp-ignore-case --format='%H%x09%cI%x09%s' 2>$null)
    if ($LASTEXITCODE -ne 0) {
        return @()
    }

    $records = New-Object System.Collections.Generic.List[object]
    foreach ($line in $rawLog) {
        if ([string]::IsNullOrWhiteSpace($line)) {
            continue
        }

        $parts = $line -split "`t", 3
        if ($parts.Count -lt 3) {
            continue
        }

        $boundaryMatch = Get-SpecrewBoundaryCommitMatch -Subject $parts[2]
        if ($null -eq $boundaryMatch) {
            continue
        }

        $committedAt = $null
        try {
            $committedAt = [DateTimeOffset]::Parse($parts[1]).UtcDateTime
        }
        catch {
            continue
        }

        $records.Add([pscustomobject]@{
                CommitHash      = $parts[0]
                CommittedAt     = $committedAt
                Boundary        = $boundaryMatch.Boundary
                FeatureNumber   = $boundaryMatch.FeatureNumber
                IterationNumber = $boundaryMatch.IterationNumber
                Subject         = $boundaryMatch.Subject
            }) | Out-Null
    }

    return $records.ToArray()
}

function Get-SpecrewBoundaryCommitTimestamp {
    param(
        [AllowEmptyCollection()][object[]]$BoundaryCommits,
        [Parameter(Mandatory = $true)][string]$Boundary,
        [AllowNull()][int]$FeatureNumber,
        [AllowNull()][int]$IterationNumber,
        [switch]$Latest
    )

    if ($BoundaryCommits.Count -eq 0 -or $null -eq $FeatureNumber) {
        return $null
    }

    $matches = @(
        $BoundaryCommits |
            Where-Object {
                $_.Boundary -eq $Boundary -and
                $_.FeatureNumber -eq $FeatureNumber -and
                ($null -eq $IterationNumber -or $_.IterationNumber -eq $IterationNumber)
            }
    )

    if ($matches.Count -eq 0) {
        return $null
    }

    $ordered = if ($Latest) { $matches | Sort-Object CommittedAt -Descending } else { $matches | Sort-Object CommittedAt }
    return $ordered[0].CommittedAt
}

function Get-SpecrewCalendarDayDuration {
    param(
        [Parameter(Mandatory = $true)][datetime]$Start,
        [Parameter(Mandatory = $true)][datetime]$End
    )

    $startDate = $Start.Date
    $endDate = $End.Date
    if ($endDate -lt $startDate) {
        return 1
    }

    return [math]::Max(1, [int](($endDate - $startDate).TotalDays + 1))
}

function Get-SpecrewActiveFeatureDirectory {
    param([Parameter(Mandatory = $true)][string]$ProjectRoot)

    $featureJsonPath = Join-Path $ProjectRoot '.specify\feature.json'
    if (-not (Test-Path -LiteralPath $featureJsonPath -PathType Leaf)) {
        return $null
    }

    try {
        $featureJson = Get-Content -LiteralPath $featureJsonPath -Raw -Encoding UTF8 | ConvertFrom-Json
        if ([string]::IsNullOrWhiteSpace([string]$featureJson.feature_directory)) {
            return $null
        }

        $candidate = [string]$featureJson.feature_directory
        if (-not [System.IO.Path]::IsPathRooted($candidate)) {
            $candidate = Join-Path $ProjectRoot $candidate
        }

        return [System.IO.Path]::GetFullPath($candidate)
    }
    catch {
        return $null
    }
}

function Get-SpecrewDeliveredStoryPoints {
    param(
        [Parameter(Mandatory = $true)][string]$IterationDirectory,
        [AllowEmptyCollection()][string[]]$RetroLines = @(),
        [AllowEmptyCollection()][string[]]$StateLines = @()
    )

    $retroPath = Join-Path $IterationDirectory 'retro.md'
    if (@($RetroLines).Count -eq 0 -and (Test-Path -LiteralPath $retroPath -PathType Leaf)) {
        $RetroLines = @(Get-SpecrewMarkdownContent -Path $retroPath)
    }

    if (@($RetroLines).Count -gt 0) {
        foreach ($line in @($RetroLines)) {
            if ($line -match '^\|\s*\*\*Total Effort\*\*\s*\|\s*\*\*(?<planned>[^|]+)\*\*\s*\|\s*\*\*(?<actual>[^|]+)\*\*') {
                $actual = ConvertTo-SpecrewNullableDecimal -Value $Matches['actual']
                if ($null -ne $actual) {
                    return $actual
                }
            }
            if ($line -match '^\|\s*Actual Effort\s*\|\s*(?<actual>[^|]+)\|') {
                $actual = ConvertTo-SpecrewNullableDecimal -Value $Matches['actual']
                if ($null -ne $actual) {
                    return $actual
                }
            }
        }
    }

    $statePath = Join-Path $IterationDirectory 'state.md'
    if (@($StateLines).Count -eq 0 -and (Test-Path -LiteralPath $statePath -PathType Leaf)) {
        $StateLines = @(Get-SpecrewMarkdownContent -Path $statePath)
    }

    if (@($StateLines).Count -gt 0) {
        foreach ($line in @($StateLines)) {
            if ($line -match '^\|\s*\*\*Total Story Points(?: \(Iteration \d+\))?\*\*\s*\|\s*(?<value>[^|]+)\|') {
                $total = ConvertTo-SpecrewNullableDecimal -Value $Matches['value']
                if ($null -ne $total) {
                    return $total
                }
            }
        }
    }

    return [decimal]0
}

function Get-SpecrewPlannedStoryPoints {
    param(
        [Parameter(Mandatory = $true)][string]$IterationDirectory,
        [AllowEmptyCollection()][string[]]$PlanLines = @(),
        [AllowEmptyCollection()][string[]]$StateLines = @()
    )

    $planPath = Join-Path $IterationDirectory 'plan.md'
    if (@($PlanLines).Count -eq 0 -and (Test-Path -LiteralPath $planPath -PathType Leaf)) {
        $PlanLines = @(Get-SpecrewMarkdownContent -Path $planPath)
    }

    if (@($PlanLines).Count -gt 0) {
        $capacityLine = Get-SpecrewMarkdownMetadataValue -Lines @($PlanLines) -Label 'Capacity'
        $capacity = ConvertTo-SpecrewNullableDecimal -Value $capacityLine
        if ($null -ne $capacity) {
            return $capacity
        }
    }

    $sum = [decimal]0
    if (@($PlanLines).Count -gt 0) {
        $taskRows = @(Get-SpecrewMarkdownSectionTable -Lines @($PlanLines) -Heading 'Tasks')
        foreach ($taskRow in $taskRows) {
            $effort = ConvertTo-SpecrewNullableDecimal -Value ([string]$taskRow.Effort)
            if ($null -ne $effort) {
                $sum += $effort
            }
        }
    }

    if ($sum -gt 0) {
        return $sum
    }

    $statePath = Join-Path $IterationDirectory 'state.md'
    if (@($StateLines).Count -eq 0 -and (Test-Path -LiteralPath $statePath -PathType Leaf)) {
        $StateLines = @(Get-SpecrewMarkdownContent -Path $statePath)
    }

    if (@($StateLines).Count -gt 0) {
        foreach ($line in @($StateLines)) {
            if ($line -match '^\|\s*\*\*Planned Story Points(?: \(Iteration \d+\))?\*\*\s*\|\s*(?<value>[^|]+)\|') {
                $planned = ConvertTo-SpecrewNullableDecimal -Value $Matches['value']
                if ($null -ne $planned) {
                    return $planned
                }
            }
        }
    }

    return $sum
}

function Get-SpecrewIterationRecord {
    param(
        [Parameter(Mandatory = $true)][string]$FeatureId,
        [Parameter(Mandatory = $true)][string]$FeatureTitle,
        [Parameter(Mandatory = $true)][string]$IterationDirectory,
        [AllowEmptyCollection()][object[]]$BoundaryCommits
    )

    $iterationName = Split-Path -Leaf $IterationDirectory
    $iterationLabel = Format-SpecrewIterationIdentifier -FeatureRef $FeatureId -IterationRef $iterationName
    $featureNumberValue = $null
    $featureNumberText = Get-SpecrewFeatureNumber -FeatureRef $FeatureId
    if (-not [int]::TryParse([string]$featureNumberText, [ref]$featureNumberValue)) {
        $featureNumberValue = $null
    }
    $iterationNumberValue = $null
    if (-not [int]::TryParse([string]$iterationName, [ref]$iterationNumberValue)) {
        $iterationNumberValue = $null
    }
    $statePath = Join-Path $IterationDirectory 'state.md'
    $planPath = Join-Path $IterationDirectory 'plan.md'
    $reviewPath = Join-Path $IterationDirectory 'review.md'
    $retroPath = Join-Path $IterationDirectory 'retro.md'

    if (-not (Test-Path -LiteralPath $statePath -PathType Leaf)) {
        $relatedLifecycleFiles = @(@($planPath, $reviewPath, $retroPath) | Where-Object { Test-Path -LiteralPath $_ -PathType Leaf })
        if ($relatedLifecycleFiles.Count -gt 0) {
            Add-SpecrewDashboardWarning -Message ("Skipping iteration artifact '{0}' because state.md is missing." -f $IterationDirectory)
        }
        return $null
    }

    try {
        $stateLines = @(Get-SpecrewMarkdownContent -Path $statePath)
        $planLines = if (Test-Path -LiteralPath $planPath -PathType Leaf) { @(Get-SpecrewMarkdownContent -Path $planPath) } else { @() }
    }
    catch {
        Add-SpecrewDashboardWarning -Message ("Skipping iteration artifact '{0}' because it could not be read cleanly: {1}" -f $IterationDirectory, $_.Exception.Message)
        return $null
    }

    $statePhase = [string](Get-SpecrewMarkdownMetadataValue -Lines $stateLines -Label 'Current Phase')
    $iterationStatus = [string](Get-SpecrewMarkdownMetadataValue -Lines $stateLines -Label 'Iteration Status')
    $reviewVerdict = ''
    $reviewLines = @()
    $retroLines = @()
    $startedAt = ConvertTo-SpecrewNullableDate -Value (Get-SpecrewMarkdownMetadataValue -Lines $planLines -Label 'Started')
    $completedAt = ConvertTo-SpecrewNullableDate -Value (Get-SpecrewMarkdownMetadataValue -Lines $planLines -Label 'Review Completed')

    $boundaryStartedAt = $null
    $boundaryCompletedAt = $null
    if ($BoundaryCommits.Count -gt 0 -and $null -ne $featureNumberValue -and $null -ne $iterationNumberValue) {
        $boundaryStartedAt = Get-SpecrewBoundaryCommitTimestamp -BoundaryCommits $BoundaryCommits -Boundary 'planning' -FeatureNumber $featureNumberValue -IterationNumber $iterationNumberValue
        $boundaryCompletedAt = Get-SpecrewBoundaryCommitTimestamp -BoundaryCommits $BoundaryCommits -Boundary 'iteration-closeout' -FeatureNumber $featureNumberValue -IterationNumber $iterationNumberValue -Latest
    }
    if ($null -ne $boundaryStartedAt) {
        $startedAt = $boundaryStartedAt
    }
    if ($null -ne $boundaryCompletedAt) {
        $completedAt = $boundaryCompletedAt
    }

    $isClosed = ($statePhase -match '(?i)closed|complete') -or ($iterationStatus -match '(?i)closed')
    if (-not $isClosed -and (Test-Path -LiteralPath $reviewPath -PathType Leaf)) {
        try {
            $reviewLines = @(Get-SpecrewMarkdownContent -Path $reviewPath)
            $reviewVerdict = [string](Get-SpecrewMarkdownMetadataValue -Lines $reviewLines -Label 'Overall Verdict')
            $isClosed = $reviewVerdict -match '(?i)accepted'
        }
        catch {
            Add-SpecrewDashboardWarning -Message ("Skipping review verdict for '{0}' because review.md could not be read cleanly: {1}" -f $IterationDirectory, $_.Exception.Message)
        }
    }

    if ($isClosed -and (Test-Path -LiteralPath $retroPath -PathType Leaf)) {
        try {
            $retroLines = @(Get-SpecrewMarkdownContent -Path $retroPath)
        }
        catch {
            Add-SpecrewDashboardWarning -Message ("Skipping retro evidence for '{0}' because retro.md could not be read cleanly: {1}" -f $IterationDirectory, $_.Exception.Message)
        }
    }

    if ($null -eq $completedAt -and @($retroLines).Count -gt 0) {
        $completedAt = ConvertTo-SpecrewNullableDate -Value (Get-SpecrewMarkdownMetadataValue -Lines $retroLines -Label 'Conducted At')
    }
    if ($null -eq $completedAt) {
        $completedAt = ConvertTo-SpecrewNullableDate -Value (Get-SpecrewMarkdownMetadataValue -Lines $stateLines -Label 'Updated')
    }

    $planned = Get-SpecrewPlannedStoryPoints -IterationDirectory $IterationDirectory -PlanLines $planLines -StateLines $stateLines
    $actual = if ($isClosed) { Get-SpecrewDeliveredStoryPoints -IterationDirectory $IterationDirectory -RetroLines $retroLines -StateLines $stateLines } else { [decimal]0 }
    if ($isClosed -and $actual -le 0 -and $planned -gt 0) {
        $actual = $planned
    }
    $elapsedDays = if ($null -ne $startedAt -and $null -ne $completedAt) {
        Get-SpecrewCalendarDayDuration -Start $startedAt -End $completedAt
    }
    else {
        1
    }

    return [pscustomobject]@{
        feature_ref           = $FeatureId
        feature_title         = $FeatureTitle
        iteration_ref         = $iterationName
        iteration_label       = $iterationLabel
        label                 = $iterationLabel
        display_name          = $iterationLabel
        iteration_directory   = $IterationDirectory
        planned_story_points  = [decimal]$planned
        actual_story_points   = [decimal]$actual
        delivered_story_points = [decimal]$actual
        started_at            = $startedAt
        closed_at             = if ($isClosed) { $completedAt } else { $null }
        elapsed_days          = $elapsedDays
        review_verdict        = $reviewVerdict
        state_phase           = $statePhase
        iteration_status      = $iterationStatus
        is_closed             = $isClosed
    }
}

function Get-SpecrewDerivedFeatureStatus {
    param(
        [AllowNull()][object]$ActiveIteration,
        [AllowEmptyCollection()][object[]]$ClosedIterations,
        [switch]$HasFeatureCloseout,
        [switch]$IsMainBranch,
        [switch]$IsActiveFeature
    )

    $canShip = if ($IsActiveFeature) { $HasFeatureCloseout -and $IsMainBranch } else { $true }

    if ($null -ne $ActiveIteration) {
        $phase = [string]$ActiveIteration.state_phase
        if (-not [string]::IsNullOrWhiteSpace($phase)) {
            $normalizedPhase = $phase.ToLowerInvariant()
            switch -Regex ($normalizedPhase) {
                'planning' { return 'Planning' }
                'review|demo' { return 'In Review' }
                'closed|complete' { return $(if ($canShip) { 'Shipped' } else { 'Iteration Complete' }) }
                default { return 'In Progress' }
            }
        }

        return 'In Progress'
    }

    if ($ClosedIterations.Count -gt 0) {
        return $(if ($canShip) { 'Shipped' } else { 'Implementation Complete' })
    }

    return 'Planning'
}

function Get-SpecrewFeatureRecords {
    param(
        [Parameter(Mandatory = $true)][string]$ProjectRoot,
        [AllowNull()][string]$ActiveFeatureRef
    )

    $specsPath = Join-Path $ProjectRoot 'specs'
    if (-not (Test-Path -LiteralPath $specsPath -PathType Container)) {
        return @()
    }

    $boundaryCommits = @(Get-SpecrewGitBoundaryCommits -ProjectRoot $ProjectRoot)
    $branchName = Get-SpecrewGitBranch -ProjectRoot $ProjectRoot
    $isMainBranch = $branchName -in @('main', 'master')

    $features = New-Object System.Collections.Generic.List[object]
    foreach ($featureDirectory in Get-ChildItem -LiteralPath $specsPath -Directory | Sort-Object Name) {
        $specPath = Join-Path $featureDirectory.FullName 'spec.md'
        if (-not (Test-Path -LiteralPath $specPath -PathType Leaf)) {
            continue
        }

        try {
            $specLines = @(Get-SpecrewMarkdownContent -Path $specPath)
        }
        catch {
            Add-SpecrewDashboardWarning -Message ("Skipping feature spec '{0}' because it could not be read cleanly: {1}" -f $specPath, $_.Exception.Message)
            continue
        }

        $featureTitle = Get-SpecrewMarkdownHeadingValue -Lines $specLines -Fallback $featureDirectory.Name
        $iterationRoot = Join-Path $featureDirectory.FullName 'iterations'
        $iterations = @()
        if (Test-Path -LiteralPath $iterationRoot -PathType Container) {
            $iterations = @(
                Get-ChildItem -LiteralPath $iterationRoot -Directory |
                    Where-Object { $_.Name -match '^\d+$' } |
                    Sort-Object Name |
                    ForEach-Object {
                        $iterationDirectoryPath = $_.FullName
                        try {
                            Get-SpecrewIterationRecord -FeatureId $featureDirectory.Name -FeatureTitle $featureTitle -IterationDirectory $iterationDirectoryPath -BoundaryCommits $boundaryCommits
                        }
                        catch {
                            Add-SpecrewDashboardWarning -Message ("Skipping iteration artifact '{0}' because it could not be parsed cleanly: {1}" -f $iterationDirectoryPath, $_.Exception.Message)
                            $null
                        }
                    } |
                    Where-Object { $null -ne $_ }
            )
        }

        $delivered = [decimal]0
        foreach ($iteration in @($iterations | Where-Object { $_.is_closed })) {
            $delivered += [decimal]$iteration.delivered_story_points
        }

        $activeIteration = @($iterations | Where-Object { -not $_.is_closed } | Sort-Object iteration_ref -Descending | Select-Object -First 1)
        $closedIterations = @($iterations | Where-Object { $_.is_closed } | Sort-Object closed_at, iteration_ref)
        $plannedTotal = [decimal]0
        foreach ($iteration in $iterations) {
            $plannedTotal += [decimal]$iteration.planned_story_points
        }
        $remainingTotal = [math]::Max(0, $plannedTotal - $delivered)
        $activeIterationValue = if ($activeIteration.Count -gt 0) { $activeIteration[0] } else { $null }
        $featureNumberValue = $null
        $featureNumberText = Get-SpecrewFeatureNumber -FeatureRef $featureDirectory.Name
        if (-not [int]::TryParse([string]$featureNumberText, [ref]$featureNumberValue)) {
            $featureNumberValue = $null
        }
        $hasFeatureCloseout = if ($null -ne $featureNumberValue) {
            $null -ne (Get-SpecrewBoundaryCommitTimestamp -BoundaryCommits $boundaryCommits -Boundary 'feature-closeout' -FeatureNumber $featureNumberValue -Latest)
        }
        else {
            $false
        }
        $isActiveFeature = -not [string]::IsNullOrWhiteSpace($ActiveFeatureRef) -and $featureDirectory.Name -eq $ActiveFeatureRef
        $featureStatus = Get-SpecrewDerivedFeatureStatus -ActiveIteration $activeIterationValue -ClosedIterations $closedIterations -HasFeatureCloseout:$hasFeatureCloseout -IsMainBranch:$isMainBranch -IsActiveFeature:$isActiveFeature
        $features.Add([pscustomobject]@{
                feature_ref             = $featureDirectory.Name
                feature_title           = $featureTitle
                feature_status          = $featureStatus
                spec_path               = $specPath
                closeout_dashboard_path = Join-Path $featureDirectory.FullName 'closeout-dashboard.md'
                iterations              = @($iterations)
                closed_iterations       = @($closedIterations)
                active_iteration        = $activeIterationValue
                delivered_story_points  = $delivered
                planned_story_points    = [decimal]$plannedTotal
                remaining_story_points  = [decimal]$remainingTotal
            }) | Out-Null
    }

    return $features.ToArray()
}

function Read-SpecrewRoadmapDefinition {
    param([Parameter(Mandatory = $true)][string]$ProjectRoot)

    $roadmapPath = Join-Path $ProjectRoot '.specrew\roadmap.yml'
    if (-not (Test-Path -LiteralPath $roadmapPath -PathType Leaf)) {
        return [pscustomobject]@{
            path      = $roadmapPath
            exists    = $false
            phases    = @()
            warnings  = @()
            parse_ok  = $true
        }
    }

    $phases = New-Object System.Collections.Generic.List[object]
    $warnings = New-Object System.Collections.Generic.List[string]
    $lines = @(Get-SpecrewMarkdownContent -Path $roadmapPath)
    $current = $null
    $inFeatureRefs = $false
    foreach ($rawLine in $lines) {
        $line = $rawLine.TrimEnd()
        if ([string]::IsNullOrWhiteSpace($line) -or $line.TrimStart().StartsWith('#')) {
            continue
        }

        if ($line -match '^\s*phases:\s*$') {
            continue
        }

        if ($line -match '^\s*-\s+id:\s*(.+?)\s*$') {
            if ($null -ne $current) {
                $phases.Add([pscustomobject]$current) | Out-Null
            }

            $current = [ordered]@{
                id                = Get-SpecrewYamlScalarValue $Matches[1]
                name              = ''
                description       = ''
                planned_effort_sp = 0
                status            = 'queued'
                feature_refs      = New-Object System.Collections.Generic.List[string]
            }
            $inFeatureRefs = $false
            continue
        }

        if ($null -eq $current) {
            $warnings.Add("Ignoring roadmap content outside phases list: $line") | Out-Null
            continue
        }

        if ($line -match '^\s+name:\s*(.+?)\s*$') {
            $current.name = Get-SpecrewYamlScalarValue $Matches[1]
            $inFeatureRefs = $false
            continue
        }

        if ($line -match '^\s+description:\s*(.+?)\s*$') {
            $current.description = Get-SpecrewYamlScalarValue $Matches[1]
            $inFeatureRefs = $false
            continue
        }

        if ($line -match '^\s+planned_effort_sp:\s*(.+?)\s*$') {
            $value = ConvertTo-SpecrewNullableDecimal -Value (Get-SpecrewYamlScalarValue $Matches[1])
            $current.planned_effort_sp = if ($null -ne $value) { [int]$value } else { 0 }
            $inFeatureRefs = $false
            continue
        }

        if ($line -match '^\s+status:\s*(.+?)\s*$') {
            $current.status = (Get-SpecrewYamlScalarValue $Matches[1]).ToLowerInvariant()
            $inFeatureRefs = $false
            continue
        }

        if ($line -match '^\s+feature_refs:\s*$') {
            $inFeatureRefs = $true
            continue
        }

        if ($inFeatureRefs -and $line -match '^\s+-\s+(.+?)\s*$') {
            $current.feature_refs.Add((Get-SpecrewYamlScalarValue $Matches[1])) | Out-Null
            continue
        }
    }

    if ($null -ne $current) {
        $phases.Add([pscustomobject]$current) | Out-Null
    }

    if ($phases.Count -eq 0) {
        $warnings.Add('roadmap.yml does not declare any phases.') | Out-Null
    }

    return [pscustomobject]@{
        path      = $roadmapPath
        exists    = $true
        phases    = $phases.ToArray()
        warnings  = $warnings.ToArray()
        parse_ok  = $warnings.Count -eq 0
    }
}

function Get-SpecrewRoadmapProgress {
    param(
        [Parameter(Mandatory = $true)][object]$RoadmapDefinition,
        [Parameter(Mandatory = $true)][object[]]$FeatureRecords
    )

    $featureByRef = @{}
    foreach ($featureRecord in $FeatureRecords) {
        $featureByRef[$featureRecord.feature_ref] = $featureRecord
    }

    $warnings = New-Object System.Collections.Generic.List[string]
    $progress = New-Object System.Collections.Generic.List[object]
    $order = 0
    foreach ($phase in $RoadmapDefinition.phases) {
        $order++
        $derivedShipped = [decimal]0
        foreach ($featureRef in @($phase.feature_refs)) {
            if ($featureByRef.ContainsKey($featureRef)) {
                $derivedShipped += [decimal]$featureByRef[$featureRef].delivered_story_points
            }
            else {
                $warnings.Add("Roadmap phase '$($phase.name)' references missing feature '$featureRef'.") | Out-Null
            }
        }

        $remaining = [math]::Max(0, [decimal]$phase.planned_effort_sp - $derivedShipped)
        $overage = [math]::Max(0, $derivedShipped - [decimal]$phase.planned_effort_sp)
        $effectiveStatus = $phase.status
        if ($overage -gt 0) {
            $effectiveStatus = 'drifted-over'
            $warnings.Add("Roadmap drift: phase '$($phase.name)' shipped effort exceeds plan by $overage SP ($derivedShipped / $($phase.planned_effort_sp) SP).") | Out-Null
        }
        elseif (($derivedShipped -ge [decimal]$phase.planned_effort_sp -and $phase.planned_effort_sp -gt 0 -and $phase.status -ne 'shipped') -or
            ($derivedShipped -eq 0 -and $phase.status -eq 'shipped') -or
            ($derivedShipped -gt 0 -and $derivedShipped -lt [decimal]$phase.planned_effort_sp -and $phase.status -eq 'queued')) {
            $effectiveStatus = 'drifted'
            $warnings.Add("Roadmap drift: phase '$($phase.name)' declares '$($phase.status)' but derived shipped effort is $derivedShipped / $($phase.planned_effort_sp) SP.") | Out-Null
        }

        $progress.Add([pscustomobject]@{
                phase_id                  = $phase.id
                order                     = $order
                name                      = $phase.name
                description               = $phase.description
                planned_effort_sp         = [decimal]$phase.planned_effort_sp
                declared_status           = $phase.status
                effective_status          = $effectiveStatus
                feature_refs              = @($phase.feature_refs)
                derived_shipped_effort_sp = $derivedShipped
                remaining_effort_sp       = [decimal]$remaining
                overage_story_points      = [decimal]$overage
            }) | Out-Null
    }

    return [pscustomobject]@{
        phases   = $progress.ToArray()
        warnings = $warnings.ToArray()
    }
}

function Get-SpecrewDashboardDefaultRecentCount {
    return 6
}

function Get-SpecrewDashboardDefaultBarWidth {
    return 28
}

function Get-SpecrewDashboardCapabilityValue {
    param(
        [AllowNull()][object]$CapabilityOverrides,
        [Parameter(Mandatory = $true)][string]$Name,
        $DefaultValue
    )

    if ($null -eq $CapabilityOverrides) {
        return $DefaultValue
    }

    if ($CapabilityOverrides -is [System.Collections.IDictionary] -and $CapabilityOverrides.Contains($Name)) {
        return $CapabilityOverrides[$Name]
    }

    $property = $CapabilityOverrides.PSObject.Properties[$Name]
    if ($null -ne $property) {
        return $property.Value
    }

    return $DefaultValue
}

function Get-SpecrewConsoleEncodingName {
    try {
        return [Console]::OutputEncoding.WebName
    }
    catch {
        return ''
    }
}

function Get-SpecrewIsWindowsHost {
    param([AllowNull()][object]$CapabilityOverrides)

    $defaultValue = $false
    if ($PSVersionTable.PSVersion.Major -ge 6) {
        $defaultValue = [bool]$IsWindows
    }

    return [bool](Get-SpecrewDashboardCapabilityValue -CapabilityOverrides $CapabilityOverrides -Name 'IsWindows' -DefaultValue $defaultValue)
}

function Test-SpecrewUtf8Output {
    param(
        [AllowNull()][object]$CapabilityOverrides,
        [ValidateSet('live', 'iteration-closeout', 'feature-closeout')][string]$CaptureKind = 'live'
    )

    if ($CaptureKind -ne 'live') {
        return $true
    }

    $encodingName = [string](Get-SpecrewDashboardCapabilityValue -CapabilityOverrides $CapabilityOverrides -Name 'ConsoleEncodingName' -DefaultValue (Get-SpecrewConsoleEncodingName))
    if ($encodingName -match 'utf-?8') {
        return $true
    }

    if (-not (Get-SpecrewIsWindowsHost -CapabilityOverrides $CapabilityOverrides)) {
        $language = [string](Get-SpecrewDashboardCapabilityValue -CapabilityOverrides $CapabilityOverrides -Name 'Lang' -DefaultValue $(if (-not [string]::IsNullOrWhiteSpace($env:LC_ALL)) { $env:LC_ALL } elseif (-not [string]::IsNullOrWhiteSpace($env:LC_CTYPE)) { $env:LC_CTYPE } else { $env:LANG }))
        if ($language -match 'utf-?8') {
            return $true
        }
    }

    return $false
}

function Test-SpecrewVirtualTerminalSupport {
    param(
        [AllowNull()][object]$CapabilityOverrides,
        [ValidateSet('live', 'iteration-closeout', 'feature-closeout')][string]$CaptureKind = 'live'
    )

    if ($CaptureKind -ne 'live') {
        return $false
    }

    if (-not (Get-SpecrewIsWindowsHost -CapabilityOverrides $CapabilityOverrides)) {
        return $true
    }

    $override = Get-SpecrewDashboardCapabilityValue -CapabilityOverrides $CapabilityOverrides -Name 'SupportsVirtualTerminal' -DefaultValue $null
    if ($null -ne $override) {
        return [bool]$override
    }

    try {
        if ($null -ne $Host.UI -and $Host.UI.PSObject.Properties.Match('SupportsVirtualTerminal').Count -gt 0) {
            return [bool]$Host.UI.SupportsVirtualTerminal
        }
    }
    catch {
        return $false
    }

    return $false
}

function Get-SpecrewDashboardRenderProfile {
    param(
        [switch]$Ascii,
        [switch]$NoColor,
        [int]$RecentCount = 6,
        [int]$BarWidth = 28,
        [ValidateSet('live', 'iteration-closeout', 'feature-closeout')][string]$CaptureKind = 'live',
        [AllowNull()][object]$CapabilityOverrides
    )

    $effectiveRecentCount = if ($RecentCount -gt 0) { $RecentCount } else { Get-SpecrewDashboardDefaultRecentCount }
    $effectiveBarWidth = if ($BarWidth -gt 0) { $BarWidth } else { Get-SpecrewDashboardDefaultBarWidth }
    $isWindowsHost = Get-SpecrewIsWindowsHost -CapabilityOverrides $CapabilityOverrides
    $termValue = [string](Get-SpecrewDashboardCapabilityValue -CapabilityOverrides $CapabilityOverrides -Name 'Term' -DefaultValue $env:TERM)
    $utf8Eligible = Test-SpecrewUtf8Output -CapabilityOverrides $CapabilityOverrides -CaptureKind $CaptureKind
    $virtualTerminalSupported = Test-SpecrewVirtualTerminalSupport -CapabilityOverrides $CapabilityOverrides -CaptureKind $CaptureKind
    $fallbackReason = $null

    if ($Ascii) {
        $fallbackReason = 'ASCII rendering forced by --ASCII.'
    }
    elseif ($NoColor -or -not [string]::IsNullOrWhiteSpace($env:NO_COLOR)) {
        $fallbackReason = 'Monochrome-safe fallback forced by --no-color / NO_COLOR.'
    }
    elseif (-not [string]::IsNullOrWhiteSpace($env:NO_UNICODE)) {
        $fallbackReason = 'Unicode rendering disabled by NO_UNICODE.'
    }
    elseif ($CaptureKind -eq 'live' -and $termValue -eq 'dumb') {
        $fallbackReason = 'TERM=dumb disables rich terminal rendering.'
    }
    elseif (-not $utf8Eligible) {
        $fallbackReason = 'UTF-8-capable output is unavailable.'
    }
    elseif ($CaptureKind -eq 'live' -and $isWindowsHost -and -not $virtualTerminalSupported) {
        $fallbackReason = 'Windows virtual-terminal support is unavailable.'
    }

    $renderingMode = if ([string]::IsNullOrWhiteSpace($fallbackReason)) { 'rich' } else { 'monochrome' }
    $ansiEnabled = $renderingMode -eq 'rich' -and $CaptureKind -eq 'live' -and $virtualTerminalSupported

    return [pscustomobject]@{
        rendering_mode            = $renderingMode
        ansi_enabled              = $ansiEnabled
        unicode_enabled           = $renderingMode -eq 'rich'
        ascii_forced              = $Ascii.IsPresent
        fallback_reason           = $fallbackReason
        recent_count              = $effectiveRecentCount
        bar_width                 = $effectiveBarWidth
        snapshot_strip_ansi       = $CaptureKind -ne 'live'
        capture_kind              = $CaptureKind
        color_mode                = if ($ansiEnabled) { 'semantic-color' } else { 'monochrome' }
        utf8_eligible             = $utf8Eligible
        supports_virtual_terminal = $virtualTerminalSupported
        term                      = $termValue
        is_windows                = $isWindowsHost
    }
}

function Get-SpecrewDashboardColorMode {
    param(
        [switch]$Ascii,
        [switch]$NoColor,
        [ValidateSet('live', 'iteration-closeout', 'feature-closeout')][string]$CaptureKind = 'live',
        [AllowNull()][object]$CapabilityOverrides
    )

    return (Get-SpecrewDashboardRenderProfile -Ascii:$Ascii -NoColor:$NoColor -CaptureKind $CaptureKind -CapabilityOverrides $CapabilityOverrides).color_mode
}

function Get-SpecrewDashboardGlyphPalette {
    param([Parameter(Mandatory = $true)][object]$RenderProfile)

    if ($RenderProfile.rendering_mode -eq 'rich') {
        return [pscustomobject]@{
            RuleChar      = '─'
            ActiveArrow   = '→'
            ActiveMarker  = '◐'
            ShippedMarker = '✓'
            QueuedMarker  = '○'
            WarnMarker    = '⚠'
            BarFill       = '█'
            BarEmpty      = '░'
            ProgressFill  = '█'
            ProgressEmpty = '░'
            SparkChars    = @('▁', '▂', '▃', '▄', '▅', '▆', '▇', '█')
            FooterMarker  = 'ℹ'
        }
    }

    return [pscustomobject]@{
        RuleChar      = '-'
        ActiveArrow   = '>'
        ActiveMarker  = '[~]'
        ShippedMarker = '[x]'
        QueuedMarker  = '[ ]'
        WarnMarker    = '!'
        BarFill       = '#'
        BarEmpty      = '.'
        ProgressFill  = '#'
        ProgressEmpty = '.'
        SparkChars    = @()
        FooterMarker  = 'i'
    }
}

function Format-SpecrewDashboardMeter {
    param(
        [decimal]$Value,
        [decimal]$Maximum,
        [int]$Width,
        [Parameter(Mandatory = $true)][object]$RenderProfile
    )

    $palette = Get-SpecrewDashboardGlyphPalette -RenderProfile $RenderProfile
    $safeWidth = [math]::Max(1, $Width)
    $filled = if ($Maximum -gt 0) {
        [math]::Min($safeWidth, [int][math]::Round(($Value / $Maximum) * $safeWidth))
    }
    else {
        0
    }
    $filled = [math]::Max(0, $filled)

    return ('{0}{1}' -f ($palette.BarFill * $filled), ($palette.BarEmpty * ($safeWidth - $filled)))
}

function Format-SpecrewDashboardProgressBar {
    param(
        [decimal]$Current,
        [decimal]$Total,
        [int]$Width = 16,
        [Parameter(Mandatory = $true)][object]$RenderProfile
    )

    $palette = Get-SpecrewDashboardGlyphPalette -RenderProfile $RenderProfile
    $safeWidth = [math]::Max(1, $Width)
    $percent = if ($Total -gt 0) { [math]::Min(100, [math]::Round(($Current / $Total) * 100)) } else { 0 }
    $filled = [math]::Min($safeWidth, [int][math]::Round(($percent / 100) * $safeWidth))
    return ('[{0}{1}] {2,3}%' -f ($palette.ProgressFill * $filled), ($palette.ProgressEmpty * ($safeWidth - $filled)), $percent)
}

function Format-SpecrewDashboardBarRow {
    param(
        [Parameter(Mandatory = $true)][string]$Label,
        [decimal]$Value,
        [decimal]$Maximum,
        [int]$Width = 14,
        [Parameter(Mandatory = $true)][object]$RenderProfile
    )

    $meter = Format-SpecrewDashboardMeter -Value $Value -Maximum $Maximum -Width $Width -RenderProfile $RenderProfile
    return ('{0,-18} {1,5:0.#} SP {2}' -f $Label, $Value, $meter)
}

function Get-SpecrewVelocityHeadline {
    param(
        [AllowEmptyCollection()]
        [Parameter(Mandatory = $true)][object[]]$ClosedIterations
    )

    $recent = @($ClosedIterations | Sort-Object closed_at -Descending | Select-Object -First 10)
    if ($recent.Count -eq 0) {
        return [pscustomobject]@{
            sample_size                  = 0
            total_story_points           = [decimal]0
            total_elapsed_days           = [decimal]0
            average_elapsed_days         = [decimal]0
            points_per_day               = [decimal]0
            confidence                   = 'low'
            trend_tokens                 = ''
            recent_values                = @()
            sample_basis_text            = 'Awaiting the first closed iteration before velocity can be summarized.'
            insufficient_history_message = 'Need at least one closed iteration before velocity can be calculated.'
            iterations                   = @()
        }
    }

    $totalStoryPoints = [decimal]0
    $totalDays = [decimal]0
    $tokens = New-Object System.Collections.Generic.List[string]
    $recentValues = New-Object System.Collections.Generic.List[decimal]
    foreach ($iteration in $recent) {
        $storyPoints = [decimal]$iteration.actual_story_points
        $elapsedDays = [decimal]([math]::Max(1, $iteration.elapsed_days))
        $totalStoryPoints += $storyPoints
        $totalDays += $elapsedDays
        $tokens.Add(('{0:0.#}' -f $storyPoints)) | Out-Null
        $recentValues.Add($storyPoints) | Out-Null
    }

    $pointsPerDay = if ($totalDays -gt 0) { [math]::Round(($totalStoryPoints / $totalDays), 2) } else { [decimal]0 }
    $averageDays = if ($recent.Count -gt 0) { [math]::Round(($totalDays / $recent.Count), 1) } else { [decimal]0 }
    $confidence = if ($recent.Count -ge 10) { 'high' } elseif ($recent.Count -ge 4) { 'moderate' } else { 'low' }
    $insufficientHistoryMessage = if ($recent.Count -lt 2) {
        'Need at least two closed iterations before the velocity trend can show a stable direction.'
    }
    else {
        $null
    }

    return [pscustomobject]@{
        sample_size                  = $recent.Count
        total_story_points           = $totalStoryPoints
        total_elapsed_days           = $totalDays
        average_elapsed_days         = $averageDays
        points_per_day               = $pointsPerDay
        confidence                   = $confidence
        trend_tokens                 = ($tokens -join ' / ')
        recent_values                = $recentValues.ToArray()
        sample_basis_text            = ('Based on {0} closed iteration(s), {1:0.#} SP across {2:0.#} calendar day(s) (avg {3:0.#} day(s)).' -f $recent.Count, $totalStoryPoints, $totalDays, $averageDays)
        insufficient_history_message = $insufficientHistoryMessage
        iterations                   = $recent
    }
}

function Get-SpecrewEtaText {
    param(
        [AllowNull()][object]$Remaining,
        [decimal]$PointsPerDay,
        [string]$CompletedLabel = 'shipped'
    )

    if ($null -eq $Remaining) {
        return 'TBD'
    }

    $remainingValue = [decimal]$Remaining

    if ($remainingValue -le 0) {
        return $CompletedLabel
    }

    if ($PointsPerDay -le 0) {
        return 'TBD'
    }

    $etaDays = [math]::Ceiling($remainingValue / $PointsPerDay)
    return "$etaDays calendar day(s)"
}

function Resolve-SpecrewEtaCompletionLabel {
    param(
        [AllowNull()][string]$Status,
        [string]$Default = 'in-progress'
    )

    if ([string]::IsNullOrWhiteSpace($Status)) {
        return $Default
    }

    $normalized = $Status.ToLowerInvariant()
    switch ($normalized) {
        'shipped' { return 'shipped' }
        'queued' { return 'queued' }
        'in-progress' { return 'in-progress' }
        'drifted' { return 'in-progress' }
        'drifted-over' { return 'in-progress' }
        default { return $Default }
    }
}

function Get-SpecrewFeatureDisplayCode {
    param([AllowNull()][string]$FeatureRef)

    $featureNumber = Get-SpecrewFeatureNumber -FeatureRef $FeatureRef
    if ([string]::IsNullOrWhiteSpace($featureNumber)) {
        return $FeatureRef
    }

    return ('F-{0}' -f $featureNumber)
}

function Get-SpecrewFeatureReadableTitle {
    param(
        [AllowNull()][string]$FeatureTitle,
        [AllowNull()][string]$FeatureRef
    )

    $title = if (-not [string]::IsNullOrWhiteSpace($FeatureTitle)) {
        $FeatureTitle -replace '^Feature Specification:\s*', ''
    }
    else {
        $FeatureRef
    }

    return $title.Trim()
}

function Get-SpecrewRecentShippedLabel {
    param(
        [AllowNull()][string]$FeatureRef,
        [AllowNull()][string]$IterationLabel
    )

    $featureCode = Get-SpecrewFeatureDisplayCode -FeatureRef $FeatureRef
    $iterationToken = $IterationLabel
    if (-not [string]::IsNullOrWhiteSpace($IterationLabel) -and $IterationLabel -match '(iter-\d+)$') {
        $iterationToken = $Matches[1]
    }

    if (-not [string]::IsNullOrWhiteSpace($featureCode) -and -not [string]::IsNullOrWhiteSpace($iterationToken)) {
        return ('{0} · {1}' -f $featureCode, $iterationToken)
    }

    if (-not [string]::IsNullOrWhiteSpace($featureCode)) {
        return $featureCode
    }

    return $iterationToken
}

function New-SpecrewRecentShippedEntry {
    param(
        [Parameter(Mandatory = $true)][object]$Iteration,
        [AllowNull()][object]$FeatureRecord
    )

    $closeDateText = if ($null -ne $Iteration.closed_at) { $Iteration.closed_at.ToString('yyyy-MM-dd') } else { 'unknown-date' }
    $closedIterationCount = if ($null -ne $FeatureRecord) { @($FeatureRecord.closed_iterations).Count } else { 1 }

    return [pscustomobject]@{
        feature_ref            = $Iteration.feature_ref
        feature_code           = Get-SpecrewFeatureDisplayCode -FeatureRef $Iteration.feature_ref
        label                  = Get-SpecrewRecentShippedLabel -FeatureRef $Iteration.feature_ref -IterationLabel $Iteration.iteration_label
        short_name             = Get-SpecrewFeatureReadableTitle -FeatureTitle $Iteration.feature_title -FeatureRef $Iteration.feature_ref
        iteration_label        = $Iteration.iteration_label
        delivered_story_points = [decimal]$Iteration.actual_story_points
        iteration_count        = [int]$closedIterationCount
        close_date_text        = $closeDateText
        closed_at              = $Iteration.closed_at
        actual_story_points    = [decimal]$Iteration.actual_story_points
        planned_story_points   = [decimal]$Iteration.planned_story_points
        elapsed_days           = [int]$Iteration.elapsed_days
        feature_title          = $Iteration.feature_title
        iteration_ref          = $Iteration.iteration_ref
        feature_status         = $Iteration.iteration_status
    }
}

function Get-SpecrewVelocitySparkline {
    param(
        [AllowEmptyCollection()][decimal[]]$Values,
        [Parameter(Mandatory = $true)][object]$RenderProfile
    )

    if ($RenderProfile.rendering_mode -ne 'rich' -or $Values.Count -eq 0) {
        return $null
    }

    $palette = Get-SpecrewDashboardGlyphPalette -RenderProfile $RenderProfile
    if ($palette.SparkChars.Count -eq 0) {
        return $null
    }

    $minimum = ($Values | Measure-Object -Minimum).Minimum
    $maximum = ($Values | Measure-Object -Maximum).Maximum
    $spark = New-Object System.Collections.Generic.List[string]

    foreach ($value in $Values) {
        if ($maximum -eq $minimum) {
            $index = [math]::Floor(($palette.SparkChars.Count - 1) / 2)
        }
        else {
            $ratio = ([decimal]$value - [decimal]$minimum) / ([decimal]$maximum - [decimal]$minimum)
            $index = [math]::Min($palette.SparkChars.Count - 1, [int][math]::Round($ratio * ($palette.SparkChars.Count - 1)))
        }
        $spark.Add($palette.SparkChars[$index]) | Out-Null
    }

    return ($spark -join '')
}

function Format-SpecrewRoadmapDescription {
    param([AllowNull()][string]$Description)

    if ([string]::IsNullOrWhiteSpace($Description)) {
        return 'No roadmap description recorded.'
    }

    $trimmed = $Description.Trim()
    if ($trimmed.Length -le 80) {
        return $trimmed
    }

    return ($trimmed.Substring(0, 77) + '...')
}

function Get-SpecrewProjection {
    param(
        [Parameter(Mandatory = $true)][object]$VelocityHeadline,
        [AllowEmptyCollection()]
        [Parameter(Mandatory = $true)][object[]]$RoadmapPhases,
        [AllowNull()][object]$ActiveFeature,
        [AllowNull()][object]$ActivePhase
    )

    $pointsPerDay = [decimal]$VelocityHeadline.points_per_day
    $roadmapRemaining = if ($RoadmapPhases.Count -gt 0) {
        $total = [decimal]0
        foreach ($phase in $RoadmapPhases) {
            $total += [decimal]$phase.remaining_effort_sp
        }
        $total
    }
    else {
        $null
    }

    $activeFeatureRemaining = $null
    if ($null -ne $ActiveFeature -and $ActiveFeature.planned_story_points -gt 0) {
        $activeFeatureRemaining = [decimal]$ActiveFeature.remaining_story_points
        if ($activeFeatureRemaining -le 0 -and $ActiveFeature.delivered_story_points -le 0) {
            $activeFeatureRemaining = $null
        }
        if ($ActiveFeature.feature_status -eq 'Planning') {
            $activeFeatureRemaining = $null
        }
    }
    $activePhaseRemaining = if ($null -ne $ActivePhase) { [decimal]$ActivePhase.remaining_effort_sp } else { $null }
    $featureCompletedLabel = 'shipped'
    if ($null -ne $ActiveFeature -and -not [string]::IsNullOrWhiteSpace([string]$ActiveFeature.feature_status)) {
        $statusText = [string]$ActiveFeature.feature_status
        switch -Regex ($statusText) {
            'implementation complete' { $featureCompletedLabel = 'implementation complete' }
            'iteration complete' { $featureCompletedLabel = 'iteration complete' }
            'shipped' { $featureCompletedLabel = 'shipped' }
            default { $featureCompletedLabel = 'TBD' }
        }
    }

    $phaseCompletedLabel = 'in-progress'
    if ($null -ne $ActivePhase) {
        $phaseStatus = if (-not [string]::IsNullOrWhiteSpace([string]$ActivePhase.effective_status)) {
            [string]$ActivePhase.effective_status
        }
        elseif (-not [string]::IsNullOrWhiteSpace([string]$ActivePhase.declared_status)) {
            [string]$ActivePhase.declared_status
        }
        else {
            $null
        }
        $phaseCompletedLabel = Resolve-SpecrewEtaCompletionLabel -Status $phaseStatus -Default 'in-progress'
    }

    $roadmapCompletedLabel = 'in-progress'
    if ($RoadmapPhases.Count -gt 0) {
        $normalizedStatuses = @()
        foreach ($phase in $RoadmapPhases) {
            $phaseStatus = if (-not [string]::IsNullOrWhiteSpace([string]$phase.effective_status)) {
                [string]$phase.effective_status
            }
            elseif (-not [string]::IsNullOrWhiteSpace([string]$phase.declared_status)) {
                [string]$phase.declared_status
            }
            else {
                $null
            }
            if (-not [string]::IsNullOrWhiteSpace($phaseStatus)) {
                $normalizedStatuses += $phaseStatus.ToLowerInvariant()
            }
        }

        if ($normalizedStatuses.Count -gt 0 -and -not ($normalizedStatuses | Where-Object { $_ -ne 'shipped' } | Select-Object -First 1)) {
            $roadmapCompletedLabel = 'shipped'
        }
        elseif ($normalizedStatuses.Count -gt 0 -and -not ($normalizedStatuses | Where-Object { $_ -ne 'queued' } | Select-Object -First 1)) {
            $roadmapCompletedLabel = 'queued'
        }
    }

    $etaScopes = @(
        [pscustomobject]@{
            scope_id              = 'active-feature'
            label                 = 'Active feature'
            remaining_story_points = $activeFeatureRemaining
            eta_text              = Get-SpecrewEtaText -Remaining $activeFeatureRemaining -PointsPerDay $pointsPerDay -CompletedLabel $featureCompletedLabel
            confidence            = $VelocityHeadline.confidence
        },
        [pscustomobject]@{
            scope_id              = 'current-phase'
            label                 = 'Current phase'
            remaining_story_points = $activePhaseRemaining
            eta_text              = Get-SpecrewEtaText -Remaining $activePhaseRemaining -PointsPerDay $pointsPerDay -CompletedLabel $phaseCompletedLabel
            confidence            = $VelocityHeadline.confidence
        },
        [pscustomobject]@{
            scope_id              = 'roadmap'
            label                 = 'Roadmap'
            remaining_story_points = $roadmapRemaining
            eta_text              = Get-SpecrewEtaText -Remaining $roadmapRemaining -PointsPerDay $pointsPerDay -CompletedLabel $roadmapCompletedLabel
            confidence            = $VelocityHeadline.confidence
        }
    )

    return [pscustomobject]@{
            remaining_story_points = $roadmapRemaining
            eta_text               = Get-SpecrewEtaText -Remaining $roadmapRemaining -PointsPerDay $pointsPerDay -CompletedLabel $roadmapCompletedLabel
        confidence             = $VelocityHeadline.confidence
        eta_scopes             = @($etaScopes)
    }
}

function Get-SpecrewDashboardSnapshot {
    param(
        [Parameter(Mandatory = $true)][string]$ProjectRoot,
        [AllowNull()][string]$FeatureId,
        [AllowNull()][string]$IterationNumber,
        [switch]$Compact,
        [switch]$Ascii,
        [switch]$NoColor,
        [int]$RecentCount = 6,
        [int]$BarWidth = 28,
        [ValidateSet('live', 'iteration-closeout', 'feature-closeout')][string]$CaptureKind = 'live',
        [AllowNull()][object]$CapabilityOverrides,
        [switch]$Team
    )

    $resolvedProjectRoot = (Resolve-Path -Path (Resolve-ProjectPath -Path $ProjectRoot)).Path
    Reset-SpecrewDashboardWarnings
    $renderProfile = Get-SpecrewDashboardRenderProfile -Ascii:$Ascii -NoColor:$NoColor -RecentCount $RecentCount -BarWidth $BarWidth -CaptureKind $CaptureKind -CapabilityOverrides $CapabilityOverrides
    $activeFeatureRef = $null
    if (-not [string]::IsNullOrWhiteSpace($FeatureId)) {
        $activeFeatureRef = $FeatureId
    }
    else {
        $activeFeatureDirectory = Get-SpecrewActiveFeatureDirectory -ProjectRoot $resolvedProjectRoot
        $activeFeatureRef = if ($activeFeatureDirectory) { Split-Path -Leaf $activeFeatureDirectory } else { $null }
    }
    $features = @(Get-SpecrewFeatureRecords -ProjectRoot $resolvedProjectRoot -ActiveFeatureRef $activeFeatureRef)
    $featureLookup = @{}
    foreach ($feature in $features) {
        $featureLookup[$feature.feature_ref] = $feature
    }

    $warnings = New-Object System.Collections.Generic.List[string]
    if ($Team) {
        $warnings.Add('Team mode is reserved for future multi-developer support; rendering the personal dashboard instead.') | Out-Null
    }
    if ($renderProfile.rendering_mode -eq 'monochrome' -and -not [string]::IsNullOrWhiteSpace([string]$renderProfile.fallback_reason)) {
        $warnings.Add($renderProfile.fallback_reason) | Out-Null
    }

    $featureRecord = @($features | Where-Object { $_.feature_ref -eq $activeFeatureRef } | Select-Object -First 1)
    if ($featureRecord.Count -eq 0 -and $features.Count -gt 0) {
        $featureRecord = @($features | Select-Object -First 1)
    }
    $featureRecord = if ($featureRecord.Count -gt 0) { $featureRecord[0] } else { $null }

    $closedIterations = @(
        $features |
            ForEach-Object { $_.closed_iterations } |
            Where-Object { $null -ne $_ } |
            Sort-Object closed_at -Descending
    )
    $velocityHeadline = Get-SpecrewVelocityHeadline -ClosedIterations $closedIterations

    if ($closedIterations.Count -eq 0) {
        $warnings.Add('No closed iterations yet. Velocity and shipped sections will stay in empty-state mode until the first closeout lands.') | Out-Null
    }
    elseif ($closedIterations.Count -le 3) {
        $warnings.Add("Velocity uses only $($closedIterations.Count) closed iteration(s); confidence remains low until 4+ iterations are available.") | Out-Null
    }

    $roadmapDefinition = Read-SpecrewRoadmapDefinition -ProjectRoot $resolvedProjectRoot
    if (-not $roadmapDefinition.exists) {
        $warnings.Add('No .specrew/roadmap.yml file found. Add one to enable roadmap progress and remaining-effort projection (see docs/roadmap-maintenance.md).') | Out-Null
    }
    foreach ($warning in $roadmapDefinition.warnings) {
        $warnings.Add($warning) | Out-Null
    }

    $roadmapProgress = Get-SpecrewRoadmapProgress -RoadmapDefinition $roadmapDefinition -FeatureRecords $features
    foreach ($warning in $roadmapProgress.warnings) {
        $warnings.Add($warning) | Out-Null
    }
    foreach ($warning in Get-SpecrewDashboardWarnings) {
        $warnings.Add($warning) | Out-Null
    }

    $activePhase = $null
    if ($null -ne $featureRecord -and $roadmapProgress.phases.Count -gt 0) {
        $activePhase = @($roadmapProgress.phases | Where-Object { $_.feature_refs -contains $featureRecord.feature_ref } | Sort-Object order | Select-Object -First 1)
        if ($activePhase.Count -gt 0) {
            $activePhase = $activePhase[0]
        }
        else {
            $activePhase = $null
        }
    }

    $activeIteration = $null
    if ($null -ne $featureRecord) {
        if (-not [string]::IsNullOrWhiteSpace($IterationNumber)) {
            $activeIteration = @($featureRecord.iterations | Where-Object { $_.iteration_ref -eq $IterationNumber } | Select-Object -First 1)
            if ($activeIteration.Count -gt 0) {
                $activeIteration = $activeIteration[0]
            }
            else {
                $activeIteration = $null
                $warnings.Add("Requested iteration '$IterationNumber' was not found under feature '$($featureRecord.feature_ref)'.") | Out-Null
            }
        }

        if ($null -eq $activeIteration) {
            $activeIteration = $featureRecord.active_iteration
        }
    }

    if ($null -eq $featureRecord) {
        $warnings.Add('No feature specifications were found under specs/.') | Out-Null
    }
    elseif ($null -eq $activeIteration) {
        $warnings.Add("Feature '$($featureRecord.feature_ref)' has no active iteration artifact; showing feature-level context only.") | Out-Null
    }

    $projection = Get-SpecrewProjection -VelocityHeadline $velocityHeadline -RoadmapPhases $roadmapProgress.phases -ActiveFeature $featureRecord -ActivePhase $activePhase
    $recentShipped = @(
        $closedIterations |
            Select-Object -First $renderProfile.recent_count |
            ForEach-Object { New-SpecrewRecentShippedEntry -Iteration $_ -FeatureRecord $featureLookup[$_.feature_ref] }
    )
    $snapshot = [pscustomobject]@{
        schema_version       = 'v1'
        captured_at          = (Get-Date).ToUniversalTime().ToString('yyyy-MM-ddTHH:mm:ssZ')
        today_anchor         = (Get-Date).ToString('yyyy-MM-dd')
        render_mode          = if ($Compact) { 'compact' } else { 'full' }
        color_mode           = $renderProfile.color_mode
        render_profile       = $renderProfile
        repository_identity  = [pscustomobject]@{
            name   = Split-Path -Leaf $resolvedProjectRoot
            branch = Get-SpecrewGitBranch -ProjectRoot $resolvedProjectRoot
            root   = $resolvedProjectRoot
        }
        active_feature       = $featureRecord
        active_iteration     = $activeIteration
        active_phase         = $activePhase
        summary_line         = ''
        velocity_headline    = $velocityHeadline
        recent_shipped       = @($recentShipped)
        recent_variance      = @($closedIterations | Select-Object -First 3)
        history              = @($closedIterations | Select-Object -First 8)
        roadmap_progress     = @($roadmapProgress.phases)
        projection           = $projection
        footer_note          = ''
        warnings             = @($warnings | Select-Object -Unique)
    }
    $snapshot.summary_line = Get-SpecrewSummaryLine -Snapshot $snapshot -Compact:$Compact
    $snapshot.footer_note = if ($renderProfile.rendering_mode -eq 'rich') {
        'Use --ASCII any time you need the monochrome-safe fallback; stored closeout snapshots keep Unicode glyphs but never ANSI escapes.'
    }
    else {
        'Monochrome-safe fallback is active. Re-run without --ASCII / --no-color in a UTF-8 + ANSI-capable terminal to see the richer view.'
    }
    return $snapshot
}

function Get-SpecrewSummaryLine {
    param(
        [Parameter(Mandatory = $true)][object]$Snapshot,
        [switch]$Compact
    )

    $palette = Get-SpecrewDashboardGlyphPalette -RenderProfile $Snapshot.render_profile
    $featureLabel = if ($null -ne $Snapshot.active_feature) {
        '{0} {1}' -f (Get-SpecrewFeatureDisplayCode -FeatureRef $Snapshot.active_feature.feature_ref), (Get-SpecrewFeatureReadableTitle -FeatureTitle $Snapshot.active_feature.feature_title -FeatureRef $Snapshot.active_feature.feature_ref)
    }
    else {
        'No active feature'
    }

    if ($null -ne $Snapshot.active_feature) {
        $featureLabel = '{0} {1}' -f $palette.ActiveArrow, $featureLabel
    }

    $statusText = if ($null -ne $Snapshot.active_feature -and -not [string]::IsNullOrWhiteSpace([string]$Snapshot.active_feature.feature_status)) {
        $Snapshot.active_feature.feature_status
    }
    else {
        'Unknown'
    }

    $phaseText = if ($null -ne $Snapshot.active_iteration -and -not [string]::IsNullOrWhiteSpace([string]$Snapshot.active_iteration.state_phase)) {
        $Snapshot.active_iteration.state_phase.ToLowerInvariant()
    }
    else {
        $null
    }

    $velocityText = if ($Snapshot.velocity_headline.sample_size -gt 0) {
        '{0:0.##} SP/day ({1} closed iterations, {2})' -f $Snapshot.velocity_headline.points_per_day, $Snapshot.velocity_headline.sample_size, $Snapshot.velocity_headline.confidence
    }
    else {
        'Velocity TBD'
    }

    $etaScopes = @($Snapshot.projection.eta_scopes)
    $featureEta = (@($etaScopes | Where-Object { $_.scope_id -eq 'active-feature' } | Select-Object -First 1).eta_text | Select-Object -First 1)
    $phaseEta = (@($etaScopes | Where-Object { $_.scope_id -eq 'current-phase' } | Select-Object -First 1).eta_text | Select-Object -First 1)
    $roadmapEta = (@($etaScopes | Where-Object { $_.scope_id -eq 'roadmap' } | Select-Object -First 1).eta_text | Select-Object -First 1)
    if ([string]::IsNullOrWhiteSpace($featureEta)) { $featureEta = 'TBD' }
    if ([string]::IsNullOrWhiteSpace($phaseEta)) { $phaseEta = 'TBD' }
    if ([string]::IsNullOrWhiteSpace($roadmapEta)) { $roadmapEta = 'TBD' }

    if ($null -eq $Snapshot.active_feature) {
        if ($Compact) {
            return ('Summary: {0} | {1}' -f $featureLabel, $velocityText)
        }

        return ('Summary: {0} | Velocity {1}' -f $featureLabel, $velocityText)
    }

    if ($Compact) {
        $statusSegment = if ($null -ne $phaseText) { "$statusText · $phaseText" } else { $statusText }
        return ('Summary: {0} | {1} | {2}' -f $featureLabel, $statusSegment, $velocityText)
    }

    $phaseSegment = if ($null -ne $phaseText) { " · phase $phaseText" } else { '' }
    return ('Summary: {0} ({1}{2}) | Velocity {3}' -f $featureLabel, $statusText, $phaseSegment, $velocityText)
}

function ConvertTo-SpecrewDashboardLines {
    param([Parameter(Mandatory = $true)][object]$Snapshot)

    $palette = Get-SpecrewDashboardGlyphPalette -RenderProfile $Snapshot.render_profile
    $lines = New-Object System.Collections.Generic.List[string]
    $rule = $palette.RuleChar * 72
    $lines.Add('SPECREW VELOCITY DASHBOARD') | Out-Null
    $lines.Add($rule) | Out-Null
    $lines.Add(('Today: {0} | Captured: {1}' -f $Snapshot.today_anchor, $Snapshot.captured_at)) | Out-Null
    $lines.Add(('Repo: {0} | Branch: {1}' -f $Snapshot.repository_identity.name, $Snapshot.repository_identity.branch)) | Out-Null
    $lines.Add(('Rendering: {0}' -f $(if ($Snapshot.render_profile.rendering_mode -eq 'rich') { 'rich default' } else { 'monochrome-safe fallback' }))) | Out-Null
    $lines.Add($Snapshot.summary_line) | Out-Null
    $lines.Add('') | Out-Null

    $lines.Add('ACTIVE WORK') | Out-Null
    if ($null -ne $Snapshot.active_feature) {
        $lines.Add(('Feature: {0} {1} | {2} | status {3}' -f $palette.ActiveArrow, (Get-SpecrewFeatureDisplayCode -FeatureRef $Snapshot.active_feature.feature_ref), (Get-SpecrewFeatureReadableTitle -FeatureTitle $Snapshot.active_feature.feature_title -FeatureRef $Snapshot.active_feature.feature_ref), $Snapshot.active_feature.feature_status)) | Out-Null
        if ($null -ne $Snapshot.active_iteration) {
            $phaseHighlight = if (-not [string]::IsNullOrWhiteSpace([string]$Snapshot.active_iteration.state_phase)) { $Snapshot.active_iteration.state_phase.ToUpperInvariant() } else { 'UNKNOWN' }
            $startedText = if ($null -ne $Snapshot.active_iteration.started_at) { $Snapshot.active_iteration.started_at.ToString('yyyy-MM-dd') } else { 'unknown-start' }
            $lines.Add(('Iteration: {0} | phase {1} | started {2}' -f $Snapshot.active_iteration.iteration_label, $phaseHighlight, $startedText)) | Out-Null
            $lines.Add(('In-flight: {0:0.#} SP planned | {1:0.#} SP delivered | {2:0.#} SP remaining' -f $Snapshot.active_feature.planned_story_points, $Snapshot.active_feature.delivered_story_points, $Snapshot.active_feature.remaining_story_points)) | Out-Null
        }
        else {
            $lines.Add('No active iteration is recorded for the current feature.') | Out-Null
        }
    }
    else {
        $lines.Add('No active feature is set. Start or resume a feature to populate this section.') | Out-Null
    }
    $lines.Add('') | Out-Null

    $lines.Add('VELOCITY') | Out-Null
    if ($Snapshot.velocity_headline.sample_size -gt 0) {
        $lines.Add(('Headline: {0:0.##} SP/day | confidence {1}' -f $Snapshot.velocity_headline.points_per_day, $Snapshot.velocity_headline.confidence)) | Out-Null
        $lines.Add(('Sample basis: {0}' -f $Snapshot.velocity_headline.sample_basis_text)) | Out-Null
        $sparkline = Get-SpecrewVelocitySparkline -Values $Snapshot.velocity_headline.recent_values -RenderProfile $Snapshot.render_profile
        if (-not [string]::IsNullOrWhiteSpace($sparkline)) {
            $lines.Add(('Sparkline: {0} | values {1}' -f $sparkline, $Snapshot.velocity_headline.trend_tokens)) | Out-Null
        }
        elseif (-not [string]::IsNullOrWhiteSpace([string]$Snapshot.velocity_headline.insufficient_history_message)) {
            $lines.Add(('Trend: {0}' -f $Snapshot.velocity_headline.insufficient_history_message)) | Out-Null
        }
        else {
            $lines.Add(('Trend: {0}' -f $Snapshot.velocity_headline.trend_tokens)) | Out-Null
        }
    }
    else {
        $lines.Add('Headline: waiting for the first closed iteration') | Out-Null
        $lines.Add('Trend: Need at least one closed iteration before velocity can be calculated.') | Out-Null
    }
    $lines.Add('') | Out-Null

    $lines.Add('RECENT SHIPPED') | Out-Null
    if ($Snapshot.recent_shipped.Count -eq 0) {
        $lines.Add('No shipped iterations yet. Close the first iteration to seed shipped history.') | Out-Null
    }
    else {
        $maxDelivered = ($Snapshot.recent_shipped | Measure-Object -Property delivered_story_points -Maximum).Maximum
        foreach ($entry in $Snapshot.recent_shipped) {
            $meter = Format-SpecrewDashboardMeter -Value $entry.delivered_story_points -Maximum $maxDelivered -Width $Snapshot.render_profile.bar_width -RenderProfile $Snapshot.render_profile
            $lines.Add(('{0} {1} | {2} | {3:0.#} SP | {4} iter | closed {5} | {6}' -f $palette.ShippedMarker, $entry.label, $entry.short_name, $entry.delivered_story_points, $entry.iteration_count, $entry.close_date_text, $meter)) | Out-Null
        }
    }
    $lines.Add('') | Out-Null

    $lines.Add('RECENT ITERATIONS (PLAN VS REALITY)') | Out-Null
    $lines.Add('Iter                  Planned Actual Delta Days') | Out-Null
    foreach ($iteration in $Snapshot.recent_variance) {
        $delta = [decimal]$iteration.actual_story_points - [decimal]$iteration.planned_story_points
        $lines.Add(('{0,-20} {1,7:0.#} {2,6:0.#} {3,5:+0.##;-0.##;0} {4,4}' -f $iteration.display_name, $iteration.planned_story_points, $iteration.actual_story_points, $delta, $iteration.elapsed_days)) | Out-Null
    }
    if ($Snapshot.recent_variance.Count -eq 0) {
        $lines.Add('No closed iterations available for variance reporting.') | Out-Null
    }
    $lines.Add('') | Out-Null

    $lines.Add('FULL HISTORY') | Out-Null
    if ($Snapshot.history.Count -eq 0) {
        $lines.Add('No closed iterations available for history.') | Out-Null
    }
    else {
        $historyMax = ($Snapshot.history | Measure-Object -Property actual_story_points -Maximum).Maximum
        foreach ($iteration in $Snapshot.history) {
            $lines.Add((Format-SpecrewDashboardBarRow -Label $iteration.label -Value $iteration.actual_story_points -Maximum $historyMax -Width ([math]::Min(16, $Snapshot.render_profile.bar_width)) -RenderProfile $Snapshot.render_profile)) | Out-Null
        }
    }
    $lines.Add('') | Out-Null

    $lines.Add('ROADMAP') | Out-Null
    if ($Snapshot.roadmap_progress.Count -eq 0) {
        $lines.Add('Roadmap unavailable yet; add .specrew/roadmap.yml (see docs/roadmap-maintenance.md) to enable this section.') | Out-Null
    }
    else {
        foreach ($phase in $Snapshot.roadmap_progress) {
            $marker = if ($null -ne $Snapshot.active_phase -and $Snapshot.active_phase.phase_id -eq $phase.phase_id) { $palette.ActiveMarker } elseif ($phase.effective_status -eq 'shipped') { $palette.ShippedMarker } else { $palette.QueuedMarker }
            $phaseLabel = if ($null -ne $Snapshot.active_phase -and $Snapshot.active_phase.phase_id -eq $phase.phase_id) { "$($phase.name) (current)" } else { $phase.name }
            $bar = Format-SpecrewDashboardProgressBar -Current $phase.derived_shipped_effort_sp -Total $phase.planned_effort_sp -Width 16 -RenderProfile $Snapshot.render_profile
            $lines.Add(('{0} {1} | {2} | {3:0.#}/{4:0.#} SP | {5}' -f $marker, $phaseLabel, $bar, $phase.derived_shipped_effort_sp, $phase.planned_effort_sp, $phase.effective_status)) | Out-Null
            $lines.Add(('  {0}' -f (Format-SpecrewRoadmapDescription -Description $phase.description))) | Out-Null
        }
    }
    $lines.Add('') | Out-Null

    $lines.Add('PROJECTION') | Out-Null
    foreach ($scope in $Snapshot.projection.eta_scopes) {
        $remainingText = if ($null -ne $scope.remaining_story_points) { '{0:0.#} SP' -f $scope.remaining_story_points } else { 'n/a' }
        $lines.Add(('{0} remaining: {1} | ETA: {2} | confidence {3}' -f $scope.label, $remainingText, $scope.eta_text, $scope.confidence)) | Out-Null
    }
    $lines.Add('') | Out-Null

    $lines.Add('WARNINGS') | Out-Null
    if ($Snapshot.warnings.Count -eq 0) {
        $lines.Add('No active dashboard warnings.') | Out-Null
    }
    else {
        foreach ($warning in $Snapshot.warnings) {
            $lines.Add(('WARN: {0}' -f $warning)) | Out-Null
        }
    }

    $lines.Add('') | Out-Null
    $lines.Add('FOOTER') | Out-Null
    $lines.Add(('{0} {1}' -f $palette.FooterMarker, $Snapshot.footer_note)) | Out-Null

    return $lines.ToArray()
}

function ConvertTo-SpecrewCompactDashboardLines {
    param([Parameter(Mandatory = $true)][object]$Snapshot)

    $palette = Get-SpecrewDashboardGlyphPalette -RenderProfile $Snapshot.render_profile
    $lines = New-Object System.Collections.Generic.List[string]
    $lines.Add('SPECREW VELOCITY DASHBOARD') | Out-Null
    $lines.Add((Get-SpecrewSummaryLine -Snapshot $Snapshot -Compact)) | Out-Null
    $lines.Add(('Today {0} | Repo {1}' -f $Snapshot.today_anchor, $Snapshot.repository_identity.name)) | Out-Null
    $lines.Add(('Rendering {0}' -f $Snapshot.render_profile.rendering_mode)) | Out-Null
    $lines.Add('ACTIVE') | Out-Null
    $lines.Add($(if ($null -ne $Snapshot.active_feature) {
                '{0} {1} | {2}' -f $palette.ActiveArrow, (Get-SpecrewFeatureDisplayCode -FeatureRef $Snapshot.active_feature.feature_ref), (Get-SpecrewFeatureReadableTitle -FeatureTitle $Snapshot.active_feature.feature_title -FeatureRef $Snapshot.active_feature.feature_ref)
            }
            else { 'No active feature' })) | Out-Null
    $lines.Add('VELOCITY') | Out-Null
    $lines.Add($(if ($Snapshot.velocity_headline.sample_size -gt 0) { '{0:0.##} SP/day | {1}' -f $Snapshot.velocity_headline.points_per_day, $Snapshot.velocity_headline.confidence } else { 'Awaiting first closeout' })) | Out-Null
    $sparkline = Get-SpecrewVelocitySparkline -Values $Snapshot.velocity_headline.recent_values -RenderProfile $Snapshot.render_profile
    $lines.Add($(if (-not [string]::IsNullOrWhiteSpace($sparkline)) { $sparkline } elseif ($Snapshot.velocity_headline.sample_size -gt 0) { $Snapshot.velocity_headline.trend_tokens } else { 'No trend yet' })) | Out-Null
    $lines.Add('RECENT SHIPPED') | Out-Null
    foreach ($entry in @($Snapshot.recent_shipped | Select-Object -First 3)) {
        $lines.Add(('{0} {1} | {2:0.#} SP' -f $palette.ShippedMarker, $entry.label, $entry.delivered_story_points)) | Out-Null
    }
    while ($lines.Count -lt 13) {
        $lines.Add('-') | Out-Null
    }
    $lines.Add('ROADMAP') | Out-Null
    foreach ($phase in @($Snapshot.roadmap_progress | Select-Object -First 2)) {
        $marker = if ($null -ne $Snapshot.active_phase -and $Snapshot.active_phase.phase_id -eq $phase.phase_id) { $palette.ActiveMarker } elseif ($phase.effective_status -eq 'shipped') { $palette.ShippedMarker } else { $palette.QueuedMarker }
        $lines.Add(('{0} {1} {2:0.#}/{3:0.#} SP' -f $marker, $phase.phase_id, $phase.derived_shipped_effort_sp, $phase.planned_effort_sp)) | Out-Null
    }
    while ($lines.Count -lt 17) {
        $lines.Add('-') | Out-Null
    }
    $lines.Add('PROJECTION') | Out-Null
    $etaScopes = @($Snapshot.projection.eta_scopes)
    $featureScope = @($etaScopes | Where-Object { $_.scope_id -eq 'active-feature' } | Select-Object -First 1)
    $phaseScope = @($etaScopes | Where-Object { $_.scope_id -eq 'current-phase' } | Select-Object -First 1)
    $roadmapScope = @($etaScopes | Where-Object { $_.scope_id -eq 'roadmap' } | Select-Object -First 1)
    $featureScope = if ($featureScope.Count -gt 0) { $featureScope[0] } else { $null }
    $phaseScope = if ($phaseScope.Count -gt 0) { $phaseScope[0] } else { $null }
    $roadmapScope = if ($roadmapScope.Count -gt 0) { $roadmapScope[0] } else { $null }
    $lines.Add(('F:{0} {1} | P:{2} {3}' -f ($(if ($null -ne $featureScope -and $null -ne $featureScope.remaining_story_points) { '{0:0.#}SP' -f $featureScope.remaining_story_points } else { 'n/a' })), $(if ($null -ne $featureScope) { $featureScope.eta_text } else { 'TBD' }), ($(if ($null -ne $phaseScope -and $null -ne $phaseScope.remaining_story_points) { '{0:0.#}SP' -f $phaseScope.remaining_story_points } else { 'n/a' })), $(if ($null -ne $phaseScope) { $phaseScope.eta_text } else { 'TBD' }))) | Out-Null
    $lines.Add(('R:{0} {1}' -f ($(if ($null -ne $roadmapScope -and $null -ne $roadmapScope.remaining_story_points) { '{0:0.#}SP' -f $roadmapScope.remaining_story_points } else { 'n/a' })), $(if ($null -ne $roadmapScope) { $roadmapScope.eta_text } else { 'TBD' }))) | Out-Null
    $lines.Add('WARNINGS') | Out-Null
    $warningSummary = if ($Snapshot.warnings.Count -gt 0) { $Snapshot.warnings[0] } else { 'No active dashboard warnings.' }
    if ($warningSummary.Length -gt 84) {
        $warningSummary = $warningSummary.Substring(0, 81) + '...'
    }
    $lines.Add($warningSummary) | Out-Null
    $lines.Add('FOOTER') | Out-Null
    $footer = $Snapshot.footer_note
    if ($footer.Length -gt 84) {
        $footer = $footer.Substring(0, 81) + '...'
    }
    $lines.Add($footer) | Out-Null
    if ($lines.Count -gt 24) {
        return @($lines | Select-Object -First 24)
    }

    while ($lines.Count -lt 24) {
        $lines.Add('') | Out-Null
    }

    return $lines.ToArray()
}

function Write-SpecrewDashboardLines {
    param(
        [AllowEmptyCollection()]
        [AllowEmptyString()]
        [Parameter(Mandatory = $true)][string[]]$Lines,
        [Parameter(Mandatory = $true)][string]$ColorMode
    )

    foreach ($line in $Lines) {
        if ($ColorMode -eq 'semantic-color') {
            if ($line -eq 'SPECREW VELOCITY DASHBOARD' -or $line -like 'Summary:*') {
                Write-Host $line -ForegroundColor Green
                continue
            }

            if ($line -match '^(ACTIVE WORK|VELOCITY|RECENT SHIPPED|RECENT ITERATIONS \(PLAN VS REALITY\)|FULL HISTORY|ROADMAP|PROJECTION|WARNINGS|FOOTER|ACTIVE)$') {
                Write-Host $line -ForegroundColor Cyan
                continue
            }

            if ($line -like 'Today:*' -or $line -like 'Repo:*' -or $line -like 'Rendering:*') {
                Write-Host $line -ForegroundColor DarkGray
                continue
            }

            if ($line -match '^WARN:') {
                Write-Host $line -ForegroundColor Yellow
                continue
            }
        }

        Write-Host $line
    }
}

function Remove-SpecrewAnsiEscapeSequences {
    param([AllowNull()][string]$Text)

    if ($null -eq $Text) {
        return ''
    }

    return [regex]::Replace($Text, ([string][char]27 + '\[[0-9;]*[A-Za-z]'), '')
}

function ConvertTo-SpecrewDashboardArtifactContent {
    param(
        [Parameter(Mandatory = $true)][object]$Snapshot,
        [AllowEmptyCollection()]
        [AllowEmptyString()]
        [Parameter(Mandatory = $true)][string[]]$Lines,
        [Parameter(Mandatory = $true)][ValidateSet('live', 'iteration-closeout', 'feature-closeout')][string]$CaptureKind,
        [AllowNull()][string]$HistoricalNotice
    )

    $notice = if ([string]::IsNullOrWhiteSpace($HistoricalNotice)) {
        if ($CaptureKind -eq 'iteration-closeout') {
            'Historical snapshot captured during iteration closeout. Re-running the dashboard later produces a new live view and must not overwrite this file.'
        }
        elseif ($CaptureKind -eq 'feature-closeout') {
            'Historical snapshot captured during feature closeout. Re-running the dashboard later produces a new live view and must not overwrite this file.'
        }
        else {
            'Live dashboard snapshot.'
        }
    }
    else {
        $HistoricalNotice
    }

    $lineFeed = "`n"
    $dashboardText = Remove-SpecrewAnsiEscapeSequences -Text ($Lines -join $lineFeed)

    return @(
        '# Velocity Dashboard Snapshot',
        '',
        '**Schema**: v1',
        ('**Capture Kind**: {0}' -f $CaptureKind),
        ('**Captured At**: {0}' -f $Snapshot.captured_at),
        ('**Render Mode**: {0}' -f $Snapshot.render_mode),
        ('**Rendering Mode**: {0}' -f $Snapshot.render_profile.rendering_mode),
        ('**Color Mode**: {0}' -f $Snapshot.color_mode),
        ('**Historical Notice**: {0}' -f $notice),
        '',
        '## Dashboard',
        '',
        '```text',
        $dashboardText,
        '```',
        ''
    ) -join $lineFeed
}
