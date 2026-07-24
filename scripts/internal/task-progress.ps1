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

    # The feature-root tasks.md is the ITERATION 1 task list (authored by /speckit.tasks at feature
    # start; later iterations track their own work in iterations/<N>/plan.md plus the live
    # tasks-progress.yml ledger). When iterations reuse bare task IDs (T0NN) — as Feature 141 does
    # across iterations 1 and 2 — applying the Iteration 1 tasks.md to Iteration N>=2 lets
    # iteration-1 checkbox state (in the hand-driven flow tasks.md is typically left all-unchecked
    # even after the iteration completes) DOWNGRADE iteration-N's live ledger status, corrupting the
    # start/resume summary. So derive status hints from the feature-root tasks.md ONLY for the first
    # iteration; for N>=2 the ledger + iterations/<N>/plan.md are the source of truth. Iteration-001
    # derivation semantics below are intentionally unchanged.
    # NOTE (follow-up, not fixed here): a re-sync of iteration 001 itself is still subject to the
    # tasks.md downgrade if its boxes are unchecked; iteration 001 is not the active summary target
    # in the observed symptom, so it is out of scope for this slice.
    $parsedIteration = 0
    $isFirstIteration = [int]::TryParse($IterationNumber, [ref]$parsedIteration) -and $parsedIteration -le 1

    if ($isFirstIteration) {
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

function ConvertTo-TaskProgressIdList {
    param([AllowNull()][object[]]$TaskIds)

    $ids = @(
        @($TaskIds) |
            ForEach-Object { [string]$_ } |
            Where-Object { -not [string]::IsNullOrWhiteSpace($_) }
    )

    if ($ids.Count -eq 0) {
        return '(none)'
    }

    return ($ids -join ', ')
}

function Set-TaskProgressStateMetadataValue {
    param(
        [Parameter(Mandatory = $true)][AllowEmptyString()][string[]]$Lines,
        [Parameter(Mandatory = $true)][string]$Label,
        [Parameter(Mandatory = $true)][string]$Value,
        [AllowNull()][string]$AfterLabel
    )

    $pattern = '^\*\*' + [regex]::Escape($Label) + '\*\*:\s*'
    for ($index = 0; $index -lt $Lines.Count; $index++) {
        if ($Lines[$index] -match $pattern) {
            $Lines[$index] = ('**{0}**: {1}' -f $Label, $Value)
            return $Lines
        }
    }

    $insertIndex = -1
    if (-not [string]::IsNullOrWhiteSpace($AfterLabel)) {
        $afterPattern = '^\*\*' + [regex]::Escape($AfterLabel) + '\*\*:\s*'
        for ($index = 0; $index -lt $Lines.Count; $index++) {
            if ($Lines[$index] -match $afterPattern) {
                $insertIndex = $index + 1
                break
            }
        }
    }

    if ($insertIndex -lt 0) {
        for ($index = 0; $index -lt $Lines.Count; $index++) {
            if ($Lines[$index] -match '^\*\*[^*]+\*\*:\s*') {
                $insertIndex = $index + 1
            }
            elseif ($insertIndex -ge 0 -and $Lines[$index] -match '^##\s+') {
                break
            }
        }
    }

    if ($insertIndex -lt 0) {
        $insertIndex = [Math]::Min(2, $Lines.Count)
    }

    $updated = [System.Collections.Generic.List[string]]::new()
    foreach ($line in $Lines) {
        $updated.Add($line) | Out-Null
    }
    $updated.Insert($insertIndex, ('**{0}**: {1}' -f $Label, $Value))
    return $updated.ToArray()
}

function Set-TaskProgressMarkdownSection {
    param(
        [Parameter(Mandatory = $true)][string]$Content,
        [Parameter(Mandatory = $true)][string]$Heading,
        [Parameter(Mandatory = $true)][string]$SectionContent
    )

    $replacement = "## $Heading" + [Environment]::NewLine + [Environment]::NewLine + $SectionContent.Trim() + [Environment]::NewLine
    $pattern = '(?ms)^##\s+' + [regex]::Escape($Heading) + '\s*\r?\n.*?(?=^##\s+|\z)'

    if ($Content -match $pattern) {
        return [regex]::Replace($Content, $pattern, $replacement)
    }

    return $Content.TrimEnd() + [Environment]::NewLine + [Environment]::NewLine + $replacement
}

function Set-TaskProgressManagedSummary {
    # NON-DESTRUCTIVE Execution Summary refresh (state-narrative destruction root-cause fix, 2026-07-14 —
    # DRIFT-198-I003-009): the previous Set-TaskProgressMarkdownSection call replaced the ENTIRE
    # '## Execution Summary' section up to the next '## ' heading, silently destroying any hand-authored
    # execution narrative recorded there (the observed iteration-003/005 committed-state truncations: a rich
    # 600-line execution record collapsed to three generated bullets on any task-progress sync). The generated
    # digest now lives in an explicit marker-bounded MANAGED block; everything else in the section is USER
    # content and is preserved. Migration: a section whose every non-empty line is a recognized machinery
    # bullet (the legacy generated digest or the scaffold placeholder) is machinery-owned and is replaced in
    # full; any other content keeps its narrative below the refreshed managed block.
    param(
        [Parameter(Mandatory = $true)][string]$Content,
        [Parameter(Mandatory = $true)][string]$SummaryBlock
    )
    $nl = [Environment]::NewLine
    $begin = '<!-- specrew:task-progress-summary:begin -->'
    $end = '<!-- specrew:task-progress-summary:end -->'
    $managed = $begin + $nl + $SummaryBlock.Trim() + $nl + $end
    $evaluator = { param($m) $managed }.GetNewClosure()

    # 1) An existing managed block refreshes IN PLACE (idempotent; never grows a second block).
    $markerPattern = '(?ms)' + [regex]::Escape($begin) + '.*?' + [regex]::Escape($end)
    if ([regex]::IsMatch($Content, $markerPattern)) {
        return [regex]::Replace($Content, $markerPattern, $evaluator)
    }

    # 2) No section yet -> append a fresh one carrying only the managed block.
    $sectionMatch = [regex]::Match($Content, '(?ms)^##\s+Execution Summary\s*\r?\n(?<body>.*?)(?=^##\s+|\z)')
    if (-not $sectionMatch.Success) {
        return $Content.TrimEnd() + $nl + $nl + '## Execution Summary' + $nl + $nl + $managed + $nl
    }

    # 3) Section exists without markers: machinery-owned bodies (legacy digest / scaffold placeholder) migrate
    #    to the managed block wholesale; ANYTHING else is user narrative and is PRESERVED below the block.
    $body = [string]$sectionMatch.Groups['body'].Value
    $machineryLinePattern = '^\s*-\s+(Execution has not started yet\.|Execution is in progress\.|Execution is blocked on one or more tasks\.|Implementation tasks are complete; review-signoff is next\.|Task progress:\s+\d+\s+complete.*|Latest completed task:.*|This artifact was scaffolded before task execution.*)\s*$'
    $machineryOwned = $true
    foreach ($line in ($body -split "\r?\n")) {
        if ([string]::IsNullOrWhiteSpace($line)) { continue }
        if (-not [regex]::IsMatch($line, $machineryLinePattern)) { $machineryOwned = $false; break }
    }
    $newSection = if ($machineryOwned) {
        '## Execution Summary' + $nl + $nl + $managed + $nl
    }
    else {
        '## Execution Summary' + $nl + $nl + $managed + $nl + $nl + $body.Trim() + $nl
    }
    return $Content.Substring(0, $sectionMatch.Index) + $newSection + $Content.Substring($sectionMatch.Index + $sectionMatch.Length)
}

function Update-IterationStateFromTaskProgress {
    param(
        [Parameter(Mandatory = $true)][string]$ProjectRoot,
        [Parameter(Mandatory = $true)][string]$FeatureRef,
        [Parameter(Mandatory = $true)][string]$IterationNumber,
        [Parameter(Mandatory = $true)][System.Collections.IDictionary]$Tasks,
        [AllowNull()][string]$ResolvedFeaturePath
    )

    $statePath = Get-IterationStatePath -ProjectRoot $ProjectRoot -FeatureRef $FeatureRef -IterationNumber $IterationNumber -ResolvedFeaturePath $ResolvedFeaturePath
    if (-not (Test-Path -LiteralPath $statePath -PathType Leaf)) {
        return $null
    }

    $completeTasks = [System.Collections.Generic.List[object]]::new()
    $inProgressTasks = [System.Collections.Generic.List[object]]::new()
    $pendingTasks = [System.Collections.Generic.List[object]]::new()
    $blockedTasks = [System.Collections.Generic.List[object]]::new()
    $latestCompleted = $null

    foreach ($taskId in $Tasks.Keys) {
        $entry = $Tasks[$taskId]
        $status = ([string]$entry.status).Trim().ToLowerInvariant()
        $record = [pscustomobject]@{
            id           = [string]$taskId
            title        = [string]$entry.title
            status       = $status
            completed_at = [string]$entry.completed_at
        }

        switch ($status) {
            { $_ -in @('done', 'complete') } {
                $completeTasks.Add($record) | Out-Null
                if (-not [string]::IsNullOrWhiteSpace($record.completed_at)) {
                    try {
                        $completedAt = [datetime]::Parse($record.completed_at, [System.Globalization.CultureInfo]::InvariantCulture, [System.Globalization.DateTimeStyles]::AdjustToUniversal)
                        if ($null -eq $latestCompleted -or $completedAt -gt $latestCompleted.timestamp) {
                            $latestCompleted = [pscustomobject]@{ id = $record.id; timestamp = $completedAt }
                        }
                    }
                    catch {
                    }
                }
            }
            'in-progress' { $inProgressTasks.Add($record) | Out-Null }
            'blocked' { $blockedTasks.Add($record) | Out-Null }
            default { $pendingTasks.Add($record) | Out-Null }
        }
    }

    if ($null -eq $latestCompleted -and $completeTasks.Count -gt 0) {
        $latestCompleted = [pscustomobject]@{ id = $completeTasks[$completeTasks.Count - 1].id; timestamp = $null }
    }

    $lastCompletedValue = if ($null -ne $latestCompleted) { [string]$latestCompleted.id } else { '(none)' }
    $remainingValue = ConvertTo-TaskProgressIdList -TaskIds @(@($pendingTasks | ForEach-Object { $_.id }) + @($blockedTasks | ForEach-Object { $_.id }))
    $inProgressValue = ConvertTo-TaskProgressIdList -TaskIds @($inProgressTasks | ForEach-Object { $_.id })
    $iterationStatus = if ($blockedTasks.Count -gt 0) {
        'blocked'
    }
    elseif ($inProgressTasks.Count -gt 0) {
        'executing'
    }
    elseif ($pendingTasks.Count -eq 0 -and $completeTasks.Count -gt 0) {
        'ready-for-review'
    }
    elseif ($completeTasks.Count -gt 0) {
        'executing'
    }
    else {
        'not-started'
    }
    $currentPhaseValue = if ($iterationStatus -eq 'not-started') { 'before-implement' } else { 'implement' }

    $lines = @(Get-Content -LiteralPath $statePath -Encoding UTF8)
    $lines = Set-TaskProgressStateMetadataValue -Lines $lines -Label 'Current Phase' -Value $currentPhaseValue -AfterLabel 'Schema'
    $lines = Set-TaskProgressStateMetadataValue -Lines $lines -Label 'Iteration Status' -Value $iterationStatus -AfterLabel 'Current Phase'
    $lines = Set-TaskProgressStateMetadataValue -Lines $lines -Label 'Last Completed Task' -Value $lastCompletedValue -AfterLabel 'Iteration Status'
    $lines = Set-TaskProgressStateMetadataValue -Lines $lines -Label 'Tasks Remaining' -Value $remainingValue -AfterLabel 'Last Completed Task'
    $lines = Set-TaskProgressStateMetadataValue -Lines $lines -Label 'In Progress' -Value $inProgressValue -AfterLabel 'Tasks Remaining'
    $lines = Set-TaskProgressStateMetadataValue -Lines $lines -Label 'Updated' -Value ((Get-Date).ToUniversalTime().ToString('o')) -AfterLabel 'Baseline Ref'

    $summaryLead = switch ($iterationStatus) {
        'ready-for-review' { 'Implementation tasks are complete; review-signoff is next.' }
        'blocked' { 'Execution is blocked on one or more tasks.' }
        'not-started' { 'Execution has not started yet.' }
        default { 'Execution is in progress.' }
    }

    $summaryBlock = @(
        "- $summaryLead"
        ("- Task progress: {0} complete, {1} in-progress, {2} pending, {3} blocked." -f $completeTasks.Count, $inProgressTasks.Count, $pendingTasks.Count, $blockedTasks.Count)
        ("- Latest completed task: {0}" -f $lastCompletedValue)
    ) -join [Environment]::NewLine

    $content = $lines -join [Environment]::NewLine
    # NON-DESTRUCTIVE (DRIFT-198-I003-009): the generated digest refreshes a marker-bounded managed block;
    # hand-authored narrative in the Execution Summary section is never machinery-replaced again.
    $content = Set-TaskProgressManagedSummary -Content $content -SummaryBlock $summaryBlock
    Write-Utf8FileAtomic -Path $statePath -Content ($content.TrimEnd() + [Environment]::NewLine)

    return [pscustomobject]@{
        Path            = $statePath
        LastCompleted   = $lastCompletedValue
        TasksRemaining  = $remainingValue
        InProgress      = $inProgressValue
        IterationStatus = $iterationStatus
    }
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
            # Preserve live non-pending state (in-progress, blocked, needs-rework, deferred) unless
            # tasks.md derivation promotes the task to 'done'. Without this guard, every sync would
            # downgrade actively worked tasks to 'pending' (the derived status for unchecked rows),
            # silently erasing coordination state.
            $liveExistingStatus = [string]$existing.Tasks[$taskRow.Task].status
            $preserveLiveExisting = ($liveExistingStatus -in @('in-progress', 'blocked', 'needs-rework', 'deferred')) -and ($derivedStatus -ne 'done')
            $entry = [ordered]@{
                title          = $taskRow.Title
                status         = if ($preserveLiveExisting) { $liveExistingStatus } elseif (-not [string]::IsNullOrWhiteSpace($derivedStatus)) { $derivedStatus } elseif ([string]::IsNullOrWhiteSpace($liveExistingStatus)) { 'pending' } else { $liveExistingStatus }
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

    Update-IterationStateFromTaskProgress `
        -ProjectRoot $ProjectRoot `
        -FeatureRef $effectiveFeatureRef `
        -IterationNumber $IterationNumber `
        -Tasks $tasks `
        -ResolvedFeaturePath $ResolvedFeaturePath | Out-Null

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
    Update-IterationStateFromTaskProgress -ProjectRoot $ProjectRoot -FeatureRef $state.FeatureRef -IterationNumber $IterationNumber -Tasks $state.Tasks -ResolvedFeaturePath $ResolvedFeaturePath | Out-Null

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
