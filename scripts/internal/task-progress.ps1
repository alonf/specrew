Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

$sharedGovernancePath = Join-Path (Split-Path -Parent (Split-Path -Parent $PSScriptRoot)) 'extensions\specrew-speckit\scripts\shared-governance.ps1'
if (-not (Test-Path -LiteralPath $sharedGovernancePath -PathType Leaf)) {
    throw "Missing shared governance helper '$sharedGovernancePath'."
}
. $sharedGovernancePath

function Get-TaskProgressMarkdownContent {
    param([string]$Path)

    return @(Get-Content -LiteralPath $Path -Encoding UTF8)
}

function Get-TaskProgressMarkdownSectionTable {
    param(
        [string[]]$Lines,
        [string]$Heading
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
    if (($text.StartsWith('"') -and $text.EndsWith('"')) -or ($text.StartsWith("'") -and $text.EndsWith("'"))) {
        $text = $text.Substring(1, $text.Length - 2)
    }

    if ($text -eq 'null') {
        return $null
    }

    return $text.Replace('\"', '"')
}

function ConvertTo-SpecrewYamlScalar {
    param([AllowNull()][string]$Value)

    if ($null -eq $Value) {
        return 'null'
    }

    return '"' + $Value.Replace('\', '\\').Replace('"', '\"') + '"'
}

function Resolve-TaskProgressFeatureRef {
    param(
        [Parameter(Mandatory = $true)][string]$ProjectRoot,
        [AllowNull()][string]$FeatureRef,
        [AllowNull()][string]$ResolvedFeaturePath
    )

    if (-not [string]::IsNullOrWhiteSpace($FeatureRef)) {
        return $FeatureRef.Trim()
    }

    if (-not [string]::IsNullOrWhiteSpace($ResolvedFeaturePath)) {
        return Split-Path -Leaf $ResolvedFeaturePath
    }

    $featureJsonPath = Join-Path (Resolve-ProjectPath -Path $ProjectRoot) '.specify\feature.json'
    if (Test-Path -LiteralPath $featureJsonPath -PathType Leaf) {
        try {
            $featureJson = Get-Content -LiteralPath $featureJsonPath -Raw -Encoding UTF8 | ConvertFrom-Json
            if (-not [string]::IsNullOrWhiteSpace([string]$featureJson.feature_directory)) {
                return Split-Path -Leaf ([string]$featureJson.feature_directory)
            }
        }
        catch {
        }
    }

    throw 'Could not resolve the active feature reference for task-progress tracking.'
}

function Get-IterationTaskProgressPath {
    param(
        [Parameter(Mandatory = $true)][string]$ProjectRoot,
        [AllowNull()][string]$FeatureRef,
        [Parameter(Mandatory = $true)][string]$IterationNumber,
        [AllowNull()][string]$ResolvedFeaturePath
    )

    $resolvedProjectRoot = Resolve-ProjectPath -Path $ProjectRoot
    $effectiveFeatureRef = Resolve-TaskProgressFeatureRef -ProjectRoot $resolvedProjectRoot -FeatureRef $FeatureRef -ResolvedFeaturePath $ResolvedFeaturePath
    return Join-Path $resolvedProjectRoot ("specs\{0}\iterations\{1}\tasks-progress.yml" -f $effectiveFeatureRef, $IterationNumber)
}

function Get-IterationPlanPath {
    param(
        [Parameter(Mandatory = $true)][string]$ProjectRoot,
        [AllowNull()][string]$FeatureRef,
        [Parameter(Mandatory = $true)][string]$IterationNumber,
        [AllowNull()][string]$ResolvedFeaturePath
    )

    $resolvedProjectRoot = Resolve-ProjectPath -Path $ProjectRoot
    $effectiveFeatureRef = Resolve-TaskProgressFeatureRef -ProjectRoot $resolvedProjectRoot -FeatureRef $FeatureRef -ResolvedFeaturePath $ResolvedFeaturePath
    return Join-Path $resolvedProjectRoot ("specs\{0}\iterations\{1}\plan.md" -f $effectiveFeatureRef, $IterationNumber)
}

function Get-IterationTaskCatalog {
    param(
        [Parameter(Mandatory = $true)][string]$ProjectRoot,
        [AllowNull()][string]$FeatureRef,
        [Parameter(Mandatory = $true)][string]$IterationNumber,
        [AllowNull()][string]$ResolvedFeaturePath
    )

    $planPath = Get-IterationPlanPath -ProjectRoot $ProjectRoot -FeatureRef $FeatureRef -IterationNumber $IterationNumber -ResolvedFeaturePath $ResolvedFeaturePath
    if (-not (Test-Path -LiteralPath $planPath -PathType Leaf)) {
        throw "Iteration plan not found: $planPath"
    }

    $rows = @(Get-TaskProgressMarkdownSectionTable -Lines (Get-TaskProgressMarkdownContent -Path $planPath) -Heading 'Tasks')
    return @(
        $rows |
            Where-Object { -not [string]::IsNullOrWhiteSpace([string]$_.Task) } |
            ForEach-Object {
                [pscustomobject]@{
                    Task        = [string]$_.Task
                    Title       = [string]$_.Title
                    Requirement = [string]$_.Requirement
                    Story       = [string]$_.Story
                    Effort      = [string]$_.Effort
                }
            }
    )
}

function Get-FeatureTasksPath {
    param(
        [Parameter(Mandatory = $true)][string]$ProjectRoot,
        [Parameter(Mandatory = $true)][string]$FeatureRef,
        [AllowNull()][string]$ResolvedFeaturePath
    )

    $resolvedProjectRoot = Resolve-ProjectPath -Path $ProjectRoot
    $featurePath = if (-not [string]::IsNullOrWhiteSpace($ResolvedFeaturePath)) {
        $ResolvedFeaturePath
    }
    else {
        Join-Path $resolvedProjectRoot ("specs\{0}" -f $FeatureRef)
    }

    return Join-Path $featurePath 'tasks.md'
}

function Get-IterationStatePath {
    param(
        [Parameter(Mandatory = $true)][string]$ProjectRoot,
        [Parameter(Mandatory = $true)][string]$FeatureRef,
        [Parameter(Mandatory = $true)][string]$IterationNumber,
        [AllowNull()][string]$ResolvedFeaturePath
    )

    $resolvedProjectRoot = Resolve-ProjectPath -Path $ProjectRoot
    $featurePath = if (-not [string]::IsNullOrWhiteSpace($ResolvedFeaturePath)) {
        $ResolvedFeaturePath
    }
    else {
        Join-Path $resolvedProjectRoot ("specs\{0}" -f $FeatureRef)
    }

    return Join-Path $featurePath ("iterations\{0}\state.md" -f $IterationNumber)
}

function Get-TaskProgressDerivedStatusHints {
    param(
        [Parameter(Mandatory = $true)][string]$ProjectRoot,
        [Parameter(Mandatory = $true)][string]$FeatureRef,
        [Parameter(Mandatory = $true)][string]$IterationNumber,
        [AllowNull()][string]$ResolvedFeaturePath
    )

    $statuses = [ordered]@{}
    $divergences = New-Object System.Collections.Generic.List[string]
    $tasksPath = Get-FeatureTasksPath -ProjectRoot $ProjectRoot -FeatureRef $FeatureRef -ResolvedFeaturePath $ResolvedFeaturePath
    if (Test-Path -LiteralPath $tasksPath -PathType Leaf) {
        foreach ($line in Get-Content -LiteralPath $tasksPath -Encoding UTF8) {
            if ($line -match '^\s*-\s+\[(?<mark>[ xX])\]\s+(?<task>T\d+)\b') {
                $taskId = $Matches['task']
                $statuses[$taskId] = if ($Matches['mark'] -match '[xX]') { 'done' } else { 'pending' }
            }
        }
    }

    $statePath = Get-IterationStatePath -ProjectRoot $ProjectRoot -FeatureRef $FeatureRef -IterationNumber $IterationNumber -ResolvedFeaturePath $ResolvedFeaturePath
    if (Test-Path -LiteralPath $statePath -PathType Leaf) {
        $lastCompletedTask = ''
        foreach ($line in Get-Content -LiteralPath $statePath -Encoding UTF8) {
            if ($line -match '^\*\*Last Completed Task\*\*:\s*(?<value>.+?)\s*$') {
                $lastCompletedTask = $Matches['value'].Trim()
                break
            }
        }

        if (-not [string]::IsNullOrWhiteSpace($lastCompletedTask) -and $lastCompletedTask -notmatch '^\(?none') {
            foreach ($taskId in @($lastCompletedTask -split '\s*,\s*')) {
                $trimmedTaskId = $taskId.Trim()
                if ($statuses.Contains($trimmedTaskId) -and $statuses[$trimmedTaskId] -ne 'done') {
                    $divergences.Add(("state.md reports Last Completed Task '{0}', but tasks.md does not mark it complete; tasks.md remains authoritative." -f $trimmedTaskId)) | Out-Null
                }
            }
        }
    }

    return [pscustomobject]@{
        Statuses    = $statuses
        Divergences = $divergences.ToArray()
    }
}

function New-TaskProgressEntry {
    param([Parameter(Mandatory = $true)][pscustomobject]$TaskRow)

    return [ordered]@{
        title          = $TaskRow.Title
        status         = 'pending'
        started_at     = $null
        completed_at   = $null
        blocked_reason = $null
    }
}

function Get-TaskProgressState {
    param([Parameter(Mandatory = $true)][string]$Path)

    $metadata = [ordered]@{}
    $tasks = [ordered]@{}
    if (-not (Test-Path -LiteralPath $Path -PathType Leaf)) {
        return [pscustomobject]@{
            Metadata = $metadata
            Tasks    = $tasks
        }
    }

    $currentTaskId = $null
    foreach ($line in Get-Content -LiteralPath $Path -Encoding UTF8) {
        if ($line -match '^(schema|feature|iteration|updated_at):\s*(.+?)\s*$') {
            $metadata[$Matches[1]] = Get-SpecrewYamlScalarValue -Value $Matches[2]
            continue
        }

        if ($line -match '^  ([^:]+):\s*$') {
            $currentTaskId = $Matches[1]
            $tasks[$currentTaskId] = [ordered]@{}
            continue
        }

        if (-not [string]::IsNullOrWhiteSpace($currentTaskId) -and $line -match '^    ([^:]+):\s*(.+?)\s*$') {
            $tasks[$currentTaskId][$Matches[1]] = Get-SpecrewYamlScalarValue -Value $Matches[2]
        }
    }

    return [pscustomobject]@{
        Metadata = $metadata
        Tasks    = $tasks
    }
}

function ConvertTo-TaskProgressContent {
    param(
        [Parameter(Mandatory = $true)][string]$FeatureRef,
        [Parameter(Mandatory = $true)][string]$IterationNumber,
        [Parameter(Mandatory = $true)][System.Collections.Specialized.OrderedDictionary]$Tasks
    )

    $lines = New-Object System.Collections.Generic.List[string]
    $lines.Add(('schema: {0}' -f (ConvertTo-SpecrewYamlScalar -Value 'v1'))) | Out-Null
    $lines.Add(('feature: {0}' -f (ConvertTo-SpecrewYamlScalar -Value $FeatureRef))) | Out-Null
    $lines.Add(('iteration: {0}' -f (ConvertTo-SpecrewYamlScalar -Value $IterationNumber))) | Out-Null
    $lines.Add(('updated_at: {0}' -f (ConvertTo-SpecrewYamlScalar -Value ((Get-Date).ToUniversalTime().ToString('o'))))) | Out-Null
    $lines.Add('tasks:') | Out-Null

    foreach ($taskId in $Tasks.Keys) {
        $entry = $Tasks[$taskId]
        $lines.Add(("  {0}:" -f $taskId)) | Out-Null
        $lines.Add(("    title: {0}" -f (ConvertTo-SpecrewYamlScalar -Value ([string]$entry.title)))) | Out-Null
        $lines.Add(("    status: {0}" -f (ConvertTo-SpecrewYamlScalar -Value ([string]$entry.status)))) | Out-Null
        $lines.Add(("    started_at: {0}" -f (ConvertTo-SpecrewYamlScalar -Value ([string]$entry.started_at)))) | Out-Null
        $lines.Add(("    completed_at: {0}" -f (ConvertTo-SpecrewYamlScalar -Value ([string]$entry.completed_at)))) | Out-Null
        $lines.Add(("    blocked_reason: {0}" -f (ConvertTo-SpecrewYamlScalar -Value ([string]$entry.blocked_reason)))) | Out-Null
    }

    return ($lines -join [Environment]::NewLine) + [Environment]::NewLine
}

function Sync-IterationTaskProgress {
    param(
        [Parameter(Mandatory = $true)][string]$ProjectRoot,
        [AllowNull()][string]$FeatureRef,
        [Parameter(Mandatory = $true)][string]$IterationNumber,
        [AllowNull()][string]$ResolvedFeaturePath
    )

    $effectiveFeatureRef = Resolve-TaskProgressFeatureRef -ProjectRoot $ProjectRoot -FeatureRef $FeatureRef -ResolvedFeaturePath $ResolvedFeaturePath
    $catalog = @(Get-IterationTaskCatalog -ProjectRoot $ProjectRoot -FeatureRef $effectiveFeatureRef -IterationNumber $IterationNumber -ResolvedFeaturePath $ResolvedFeaturePath)
    $path = Get-IterationTaskProgressPath -ProjectRoot $ProjectRoot -FeatureRef $effectiveFeatureRef -IterationNumber $IterationNumber -ResolvedFeaturePath $ResolvedFeaturePath
    $existing = Get-TaskProgressState -Path $path
    $derivedHints = Get-TaskProgressDerivedStatusHints -ProjectRoot $ProjectRoot -FeatureRef $effectiveFeatureRef -IterationNumber $IterationNumber -ResolvedFeaturePath $ResolvedFeaturePath
    foreach ($divergence in @($derivedHints.Divergences)) {
        Write-Warning ("[task-progress-reconciliation] {0}" -f $divergence)
    }

    $tasks = [ordered]@{}

    foreach ($taskRow in $catalog) {
        $derivedStatus = if ($derivedHints.Statuses.Contains($taskRow.Task)) { [string]$derivedHints.Statuses[$taskRow.Task] } else { $null }
        if ($existing.Tasks.Contains($taskRow.Task)) {
            $entry = [ordered]@{
                title          = $taskRow.Title
                status         = if (-not [string]::IsNullOrWhiteSpace($derivedStatus)) { $derivedStatus } elseif ([string]::IsNullOrWhiteSpace([string]$existing.Tasks[$taskRow.Task].status)) { 'pending' } else { [string]$existing.Tasks[$taskRow.Task].status }
                started_at     = [string]$existing.Tasks[$taskRow.Task].started_at
                completed_at   = [string]$existing.Tasks[$taskRow.Task].completed_at
                blocked_reason = [string]$existing.Tasks[$taskRow.Task].blocked_reason
            }
        }
        else {
            $entry = New-TaskProgressEntry -TaskRow $taskRow
            if (-not [string]::IsNullOrWhiteSpace($derivedStatus)) {
                $entry.status = $derivedStatus
            }
        }

        if ($entry.status -eq 'done' -and [string]::IsNullOrWhiteSpace([string]$entry.completed_at)) {
            $entry.completed_at = (Get-Date).ToUniversalTime().ToString('o')
        }

        $tasks[$taskRow.Task] = $entry
    }

    $content = ConvertTo-TaskProgressContent -FeatureRef $effectiveFeatureRef -IterationNumber $IterationNumber -Tasks $tasks
    $existingContent = if (Test-Path -LiteralPath $path -PathType Leaf) {
        Get-Content -LiteralPath $path -Raw -Encoding UTF8
    }
    else {
        $null
    }

    if ($content -ne $existingContent) {
        Write-Utf8FileAtomic -Path $path -Content $content
    }

    return [pscustomobject]@{
        Path      = $path
        FeatureRef = $effectiveFeatureRef
        Iteration = $IterationNumber
        Tasks     = $tasks
    }
}

function Set-TaskStatus {
    param(
        [Parameter(Mandatory = $true)][string]$ProjectRoot,
        [AllowNull()][string]$FeatureRef,
        [Parameter(Mandatory = $true)][string]$IterationNumber,
        [Parameter(Mandatory = $true)][string]$TaskId,
        [Parameter(Mandatory = $true)][ValidateSet('pending', 'in-progress', 'complete', 'blocked')][string]$Status,
        [AllowNull()][string]$Reason,
        [AllowNull()][string]$ResolvedFeaturePath
    )

    $state = Sync-IterationTaskProgress -ProjectRoot $ProjectRoot -FeatureRef $FeatureRef -IterationNumber $IterationNumber -ResolvedFeaturePath $ResolvedFeaturePath
    if (-not $state.Tasks.Contains($TaskId)) {
        throw "Task ID '$TaskId' is not present in Iteration $IterationNumber."
    }

    if ($Status -eq 'blocked' -and [string]::IsNullOrWhiteSpace($Reason)) {
        throw "Task '$TaskId' requires -Reason when status is 'blocked'."
    }

    $entry = $state.Tasks[$TaskId]
    $timestamp = (Get-Date).ToUniversalTime().ToString('o')
    $entry.status = $Status

    switch ($Status) {
        'pending' {
            $entry.blocked_reason = $null
        }
        'in-progress' {
            if ([string]::IsNullOrWhiteSpace([string]$entry.started_at)) {
                $entry.started_at = $timestamp
            }
            $entry.completed_at = $null
            $entry.blocked_reason = $null
        }
        'complete' {
            if ([string]::IsNullOrWhiteSpace([string]$entry.started_at)) {
                $entry.started_at = $timestamp
            }
            $entry.completed_at = $timestamp
            $entry.blocked_reason = $null
        }
        'blocked' {
            if ([string]::IsNullOrWhiteSpace([string]$entry.started_at)) {
                $entry.started_at = $timestamp
            }
            $entry.completed_at = $null
            $entry.blocked_reason = $Reason.Trim()
        }
    }

    $content = ConvertTo-TaskProgressContent -FeatureRef $state.FeatureRef -IterationNumber $IterationNumber -Tasks $state.Tasks
    Write-Utf8FileAtomic -Path $state.Path -Content $content

    return [pscustomobject]@{
        Path      = $state.Path
        TaskId    = $TaskId
        Status    = $Status
        StartedAt = $entry.started_at
        CompletedAt = $entry.completed_at
        BlockedReason = $entry.blocked_reason
    }
}

function Set-TaskComplete {
    param(
        [Parameter(Mandatory = $true)][string]$ProjectRoot,
        [AllowNull()][string]$FeatureRef,
        [Parameter(Mandatory = $true)][string]$IterationNumber,
        [Parameter(Mandatory = $true)][string]$TaskId,
        [AllowNull()][string]$ResolvedFeaturePath
    )

    return Set-TaskStatus -ProjectRoot $ProjectRoot -FeatureRef $FeatureRef -IterationNumber $IterationNumber -TaskId $TaskId -Status 'complete' -ResolvedFeaturePath $ResolvedFeaturePath
}

function Set-TaskBlocked {
    param(
        [Parameter(Mandatory = $true)][string]$ProjectRoot,
        [AllowNull()][string]$FeatureRef,
        [Parameter(Mandatory = $true)][string]$IterationNumber,
        [Parameter(Mandatory = $true)][string]$TaskId,
        [Parameter(Mandatory = $true)][string]$Reason,
        [AllowNull()][string]$ResolvedFeaturePath
    )

    return Set-TaskStatus -ProjectRoot $ProjectRoot -FeatureRef $FeatureRef -IterationNumber $IterationNumber -TaskId $TaskId -Status 'blocked' -Reason $Reason -ResolvedFeaturePath $ResolvedFeaturePath
}

function Get-TaskProgressSummary {
    param(
        [Parameter(Mandatory = $true)][string]$ProjectRoot,
        [AllowNull()][string]$FeatureRef,
        [Parameter(Mandatory = $true)][string]$IterationNumber,
        [AllowNull()][string]$ResolvedFeaturePath
    )

    $effectiveFeatureRef = Resolve-TaskProgressFeatureRef -ProjectRoot $ProjectRoot -FeatureRef $FeatureRef -ResolvedFeaturePath $ResolvedFeaturePath
    $planPath = Get-IterationPlanPath -ProjectRoot $ProjectRoot -FeatureRef $effectiveFeatureRef -IterationNumber $IterationNumber -ResolvedFeaturePath $ResolvedFeaturePath
    $progressPath = Get-IterationTaskProgressPath -ProjectRoot $ProjectRoot -FeatureRef $effectiveFeatureRef -IterationNumber $IterationNumber -ResolvedFeaturePath $ResolvedFeaturePath
    $state = if (Test-Path -LiteralPath $planPath -PathType Leaf) {
        Sync-IterationTaskProgress -ProjectRoot $ProjectRoot -FeatureRef $effectiveFeatureRef -IterationNumber $IterationNumber -ResolvedFeaturePath $ResolvedFeaturePath
    }
    else {
        [pscustomobject]@{
            Path       = $progressPath
            FeatureRef = $effectiveFeatureRef
            Iteration  = $IterationNumber
            Tasks      = (Get-TaskProgressState -Path $progressPath).Tasks
        }
    }
    $complete = New-Object System.Collections.Generic.List[object]
    $inProgress = New-Object System.Collections.Generic.List[object]
    $pending = New-Object System.Collections.Generic.List[object]
    $blocked = New-Object System.Collections.Generic.List[object]
    $latestCompleted = $null

    foreach ($taskId in $state.Tasks.Keys) {
        $entry = $state.Tasks[$taskId]
        $taskRecord = [pscustomobject]@{
            id             = $taskId
            title          = [string]$entry.title
            status         = [string]$entry.status
            started_at     = [string]$entry.started_at
            completed_at   = [string]$entry.completed_at
            blocked_reason = [string]$entry.blocked_reason
        }

        switch ($taskRecord.status) {
            'done' {
                $complete.Add($taskRecord) | Out-Null
                if (-not [string]::IsNullOrWhiteSpace($taskRecord.completed_at)) {
                    $completedAt = [datetime]::Parse($taskRecord.completed_at, [System.Globalization.CultureInfo]::InvariantCulture, [System.Globalization.DateTimeStyles]::AdjustToUniversal)
                    if ($null -eq $latestCompleted -or $completedAt -gt $latestCompleted.timestamp) {
                        $latestCompleted = [pscustomobject]@{
                            id        = $taskRecord.id
                            title     = $taskRecord.title
                            timestamp = $completedAt
                        }
                    }
                }
            }
            'complete' {
                $complete.Add($taskRecord) | Out-Null
                if (-not [string]::IsNullOrWhiteSpace($taskRecord.completed_at)) {
                    $completedAt = [datetime]::Parse($taskRecord.completed_at, [System.Globalization.CultureInfo]::InvariantCulture, [System.Globalization.DateTimeStyles]::AdjustToUniversal)
                    if ($null -eq $latestCompleted -or $completedAt -gt $latestCompleted.timestamp) {
                        $latestCompleted = [pscustomobject]@{
                            id        = $taskRecord.id
                            title     = $taskRecord.title
                            timestamp = $completedAt
                        }
                    }
                }
            }
            'in-progress' { $inProgress.Add($taskRecord) | Out-Null }
            'blocked' { $blocked.Add($taskRecord) | Out-Null }
            default { $pending.Add($taskRecord) | Out-Null }
        }
    }

    return [pscustomobject]@{
        Path             = $state.Path
        Complete         = $complete.ToArray()
        InProgress       = $inProgress.ToArray()
        Pending          = $pending.ToArray()
        Blocked          = $blocked.ToArray()
        LatestCompleted  = if ($null -ne $latestCompleted) {
            [pscustomobject]@{
                id        = $latestCompleted.id
                title     = $latestCompleted.title
                timestamp = $latestCompleted.timestamp.ToString('o')
            }
        } else { $null }
    }
}
