[CmdletBinding()]
param(
    [string]$ProjectPath = (Get-Location).Path,
    [string[]]$IterationPath
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

$allowedIterationStatuses = @('planning', 'executing', 'reviewing', 'retro', 'complete', 'abandoned')
$allowedTaskStatuses = @('planned', 'in-progress', 'done', 'needs-rework', 'deferred', 'blocked')
$terminalTaskStatuses = @('done', 'needs-rework', 'deferred', 'blocked')

function Resolve-IterationTarget {
    param(
        [string]$ResolvedProjectPath,
        [string[]]$ExplicitIterationPaths
    )

    if ($ExplicitIterationPaths -and $ExplicitIterationPaths.Count -gt 0) {
        return $ExplicitIterationPaths | ForEach-Object { (Resolve-Path -Path $_).Path }
    }

    $specsPath = Join-Path -Path $ResolvedProjectPath -ChildPath 'specs'
    if (-not (Test-Path -Path $specsPath -PathType Container)) {
        throw "Specs directory not found: $specsPath"
    }

    $targets = Get-ChildItem -Path $specsPath -Directory -Recurse |
        Where-Object { $_.FullName -match '[\\/]iterations[\\/][^\\/]+$' } |
        Where-Object { Test-Path -Path (Join-Path -Path $_.FullName -ChildPath 'plan.md') } |
        Select-Object -ExpandProperty FullName

    if (-not $targets) {
        throw "No iteration directories with plan.md found under $specsPath"
    }

    return $targets
}

function Get-MarkdownContent {
    param([string]$Path)

    return Get-Content -Path $Path -Encoding UTF8
}

function Get-MarkdownMetadataValue {
    param(
        [string[]]$Lines,
        [string]$Label
    )

    $pattern = '^\*\*' + [regex]::Escape($Label) + '\*\*:\s*(.+?)\s*$'
    foreach ($line in $Lines) {
        if ($line -match $pattern) {
            return $Matches[1].Trim()
        }
    }

    return $null
}

function Get-NormalizedKeyword {
    param([AllowNull()][string]$Value)

    if ([string]::IsNullOrWhiteSpace($Value)) {
        return $null
    }

    $normalized = $Value.ToLowerInvariant()
    if ($normalized -match '(planning|executing|reviewing|retro|complete|abandoned)') {
        return $Matches[1]
    }

    if ($normalized -match '(accepted|needs-rework|blocked)') {
        return $Matches[1]
    }

    return $normalized.Trim()
}

function Test-IsNullish {
    param([AllowNull()][string]$Value)

    if ([string]::IsNullOrWhiteSpace($Value)) {
        return $true
    }

    return $Value.Trim() -match '^(?:—|-|none|null|n/a|\(none\)|blank)$'
}

function Test-HeadingPresent {
    param(
        [string[]]$Lines,
        [string]$Heading
    )

    $pattern = '^##\s+' + [regex]::Escape($Heading) + '\b'
    return [bool]($Lines | Where-Object { $_ -match $pattern } | Select-Object -First 1)
}

function Get-MarkdownSectionTable {
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
            $value = if ($cellIndex -lt $cells.Count) { $cells[$cellIndex] } else { '' }
            $row[$headers[$cellIndex]] = $value
        }

        $rows.Add([pscustomobject]$row)
    }

    return $rows
}

function Get-TeamRoleMap {
    param([string]$ResolvedProjectPath)

    $teamPath = Join-Path -Path $ResolvedProjectPath -ChildPath '.squad\team.md'
    if (-not (Test-Path -Path $teamPath -PathType Leaf)) {
        return @{}
    }

    $teamLines = Get-MarkdownContent -Path $teamPath
    $members = @(Get-MarkdownSectionTable -Lines $teamLines -Heading 'Members')
    $teamRoles = @{}

    foreach ($member in $members) {
        if ((Test-IsNullish $member.Name) -or (Test-IsNullish $member.Role)) {
            continue
        }

        $teamRoles[$member.Name.Trim()] = $member.Role.Trim()
    }

    return $teamRoles
}

function Get-RoleToken {
    param([AllowNull()][string]$Value)

    if ([string]::IsNullOrWhiteSpace($Value)) {
        return @()
    }

    $normalized = ($Value.ToLowerInvariant() -replace '[^a-z0-9]+', ' ').Trim()
    if ([string]::IsNullOrWhiteSpace($normalized)) {
        return @()
    }

    return @(
        ($normalized -split '\s+') |
            Where-Object { -not [string]::IsNullOrWhiteSpace($_) }
    )
}

function Test-RoleLabelMatchesCanonical {
    param(
        [string]$ObservedRole,
        [string]$CanonicalRole
    )

    $canonicalTokens = @(Get-RoleToken -Value $CanonicalRole)
    $observedTokens = @(Get-RoleToken -Value $ObservedRole)
    if ($canonicalTokens.Count -eq 0 -or $observedTokens.Count -eq 0) {
        return $false
    }

    foreach ($token in $canonicalTokens) {
        if ($observedTokens -notcontains $token) {
            return $false
        }
    }

    return $true
}

function Get-LifecycleStatusLine {
    param([string[]]$Lines)

    $labelPattern = '^\s*(?:[-*]\s*)?\*\*(?:Status|Current Status|Next Phase|Terminal State)\*\*:'
    return @($Lines | Where-Object { $_ -match $labelPattern })
}

function Test-LifecycleNarrative {
    param(
        [hashtable]$ArtifactContents,
        [bool]$HasReviewArtifact,
        [bool]$HasRetroArtifact,
        [bool]$HasCompleteEvidence,
        [System.Collections.Generic.List[string]]$Errors
    )

    $pendingPattern = '\b(?:await(?:ing)?|pending|blocked|remaining|ready\s+for|not(?:\s+yet)?\s+started|next|to\s+be\s+completed|to\s+begin)\b'
    $pendingSignOffPattern = '\b(?:await(?:ing)?|pending|ready\s+for)\b.*\bsign[\s-]?off\b'

    foreach ($artifactName in $ArtifactContents.Keys) {
        $lines = @(Get-LifecycleStatusLine -Lines $ArtifactContents[$artifactName])
        foreach ($line in $lines) {
            $lowerLine = $line.ToLowerInvariant()
            $isNextPhaseLine = $lowerLine -match '^\s*(?:[-*]\s*)?\*\*next phase\*\*:'

            if ($HasReviewArtifact -and (
                    ($isNextPhaseLine -and $lowerLine -match '\breview(?:ing)?\b') -or
                    (($lowerLine -match '\breview(?:ing)?\b') -and ($lowerLine -match $pendingPattern))
                )) {
                $Errors.Add("$artifactName still describes review as pending even though review.md exists")
            }

            if ($HasRetroArtifact -and (
                    ($isNextPhaseLine -and $lowerLine -match '\b(?:retro|retrospective)\b') -or
                    (($lowerLine -match '\b(?:retro|retrospective)\b') -and ($lowerLine -match $pendingPattern))
                )) {
                $Errors.Add("$artifactName still describes retrospective as pending even though retro.md exists")
            }

            if ($HasCompleteEvidence -and (
                    ($isNextPhaseLine -and $lowerLine -match '\b(?:complete|completion|closeout|closure)\b') -or
                    (($lowerLine -match '\b(?:complete|completion|closeout|closure)\b') -and ($lowerLine -match $pendingPattern))
                )) {
                $Errors.Add("$artifactName still describes completion as pending even though the iteration is complete")
            }

            if ($HasCompleteEvidence -and ($lowerLine -match $pendingSignOffPattern)) {
                $Errors.Add("$artifactName still describes sign-off as pending even though the iteration is complete")
            }
        }
    }
}

function Test-GovernanceGateConsistency {
    param(
        [string[]]$PlanLines,
        [bool]$HasCompletionEvidence,
        [System.Collections.Generic.List[string]]$Errors
    )

    if (-not $HasCompletionEvidence) {
        return
    }

    $governanceRows = @(Get-MarkdownSectionTable -Lines $PlanLines -Heading 'Governance Consistency Check')
    foreach ($row in $governanceRows) {
        $verdict = if ($null -ne $row.PSObject.Properties['Verdict']) { [string]$row.Verdict } else { $null }
        if (Test-IsNullish $verdict) {
            continue
        }

        $normalizedVerdict = $verdict.ToLowerInvariant()
        if ($normalizedVerdict -match '\b(?:pending|tbd|todo|open|blocked|fail(?:ed)?|needs[- ]rework|partial|incomplete|not(?:\s+yet)?\s+started)\b') {
            $gateName = if (Test-IsNullish $row.Gate) { '(unnamed gate)' } else { $row.Gate.Trim() }
            $Errors.Add("plan.md governance gate '$gateName' still reports non-terminal verdict '$verdict' despite later completion evidence")
        }
    }
}

function Test-SignOffRoleNaming {
    param(
        [hashtable]$ArtifactContents,
        [hashtable]$TeamRoles,
        [System.Collections.Generic.List[string]]$Errors
    )

    if ($TeamRoles.Count -eq 0) {
        return
    }

    foreach ($artifactName in $ArtifactContents.Keys) {
        foreach ($line in $ArtifactContents[$artifactName]) {
            foreach ($memberName in $TeamRoles.Keys) {
                $roleMatch = [regex]::Match($line, [regex]::Escape($memberName) + '\s*\(([^)]+)\)(.*)')
                if (-not $roleMatch.Success) {
                    continue
                }

                $observedRole = $roleMatch.Groups[1].Value.Trim()
                $roleTail = $roleMatch.Groups[2].Value
                if ($roleTail -notmatch '\b(?:sign[\s-]?off|approval|approve(?:d|s)?|verdict)\b' -and $roleTail -notmatch '^\s*:') {
                    continue
                }

                $canonicalRole = [string]$TeamRoles[$memberName]
                if (-not (Test-RoleLabelMatchesCanonical -ObservedRole $observedRole -CanonicalRole $canonicalRole)) {
                    $Errors.Add("$artifactName uses outdated sign-off role naming for $memberName ('$observedRole' vs team role '$canonicalRole')")
                }
            }
        }
    }
}

function Test-StateArtifact {
    param(
        [string]$IterationDirectory,
        [System.Collections.Generic.List[string]]$Errors
    )

    $statePath = Join-Path -Path $IterationDirectory -ChildPath 'state.md'
    if (-not (Test-Path -Path $statePath -PathType Leaf)) {
        $Errors.Add('Missing required artifact: state.md')
        return
    }

    $stateLines = Get-MarkdownContent -Path $statePath
    foreach ($label in @('Last Completed Task', 'Tasks Remaining', 'In Progress', 'Updated')) {
        $value = Get-MarkdownMetadataValue -Lines $stateLines -Label $label
        if ($null -eq $value) {
            $Errors.Add("state.md is missing required metadata: $label")
        }
    }
}

function Test-ReviewArtifact {
    param(
        [string]$ReviewPath,
        [object[]]$PlanTasks,
        [System.Collections.Generic.List[string]]$Errors,
        [switch]$RequireAcceptedVerdict
    )

    if (-not (Test-Path -Path $ReviewPath -PathType Leaf)) {
        $Errors.Add('Missing required artifact: review.md')
        return
    }

    $reviewLines = Get-MarkdownContent -Path $ReviewPath
    $overallVerdict = Get-NormalizedKeyword (Get-MarkdownMetadataValue -Lines $reviewLines -Label 'Overall Verdict')
    if ($overallVerdict -notin @('accepted', 'needs-rework', 'blocked')) {
        $Errors.Add('review.md must record a valid overall verdict (accepted | needs-rework | blocked)')
    }
    elseif ($RequireAcceptedVerdict -and $overallVerdict -ne 'accepted') {
        $Errors.Add("Complete iterations require review.md overall verdict 'accepted' (found '$overallVerdict')")
    }

    $taskVerdicts = Get-MarkdownSectionTable -Lines $reviewLines -Heading 'Task Verdicts'
    if ($taskVerdicts.Count -eq 0) {
        $Errors.Add('review.md must contain a populated Task Verdicts table')
        return
    }

    $reviewedTaskIds = @{}
    foreach ($row in $taskVerdicts) {
        $taskId = $row.Task
        if (Test-IsNullish $taskId) {
            $Errors.Add('review.md contains a verdict row without a task identifier')
            continue
        }

        $reviewedTaskIds[$taskId] = $true
        if (Test-IsNullish $row.Verdict) {
            $Errors.Add("review.md is missing a verdict for task '$taskId'")
        }
    }

    foreach ($task in $PlanTasks) {
        if (-not $reviewedTaskIds.ContainsKey($task.Task)) {
            $Errors.Add("review.md is missing a verdict row for plan task '$($task.Task)'")
        }
    }
}

function Test-RetroArtifact {
    param(
        [string]$RetroPath,
        [System.Collections.Generic.List[string]]$Errors
    )

    if (-not (Test-Path -Path $RetroPath -PathType Leaf)) {
        $Errors.Add('Missing required artifact: retro.md')
        return
    }

    $retroLines = Get-MarkdownContent -Path $RetroPath
    foreach ($heading in @('Estimation Accuracy', 'Drift Summary', 'Improvement Actions')) {
        if (-not (Test-HeadingPresent -Lines $retroLines -Heading $heading)) {
            $Errors.Add("retro.md is missing required section: $heading")
        }
    }

    $hasProcessNotes = (Test-HeadingPresent -Lines $retroLines -Heading 'Process Notes') -or (
        (Test-HeadingPresent -Lines $retroLines -Heading 'What Went Well') -and
        (Test-HeadingPresent -Lines $retroLines -Heading "What Didn't Go Well")
    )

    if (-not $hasProcessNotes) {
        $Errors.Add("retro.md must capture process notes via 'Process Notes' or both 'What Went Well' and 'What Didn't Go Well'")
    }
}

function Test-PlanTaskSet {
    param(
        [object[]]$Tasks,
        [System.Collections.Generic.List[string]]$Errors
    )

    if ($Tasks.Count -eq 0) {
        $Errors.Add('plan.md must contain at least one task row')
        return
    }

    foreach ($task in $Tasks) {
        if (Test-IsNullish $task.Task) {
            $Errors.Add('plan.md contains a task row without a task ID')
            continue
        }

        if (Test-IsNullish $task.Requirement) {
            $Errors.Add("Task '$($task.Task)' is missing a requirement reference")
        }

        if (Test-IsNullish $task.Story) {
            $Errors.Add("Task '$($task.Task)' is missing a story reference")
        }

        if (Test-IsNullish $task.Owner) {
            $Errors.Add("Task '$($task.Task)' is missing an owner")
        }

        if (Test-IsNullish $task.Status) {
            $Errors.Add("Task '$($task.Task)' is missing a task status")
            continue
        }

        $normalizedTaskStatus = $task.Status.Trim().ToLowerInvariant()
        if ($normalizedTaskStatus -notin $allowedTaskStatuses) {
            $Errors.Add("Task '$($task.Task)' uses invalid status '$($task.Status)'")
        }
    }
}

function Test-IterationGovernance {
    param(
        [string]$IterationDirectory,
        [hashtable]$TeamRoles
    )

    $errors = New-Object System.Collections.Generic.List[string]
    $planPath = Join-Path -Path $IterationDirectory -ChildPath 'plan.md'

    if (-not (Test-Path -Path $planPath -PathType Leaf)) {
        $errors.Add('Missing required artifact: plan.md')
        return [pscustomobject]@{
            Path = $IterationDirectory
            Errors = $errors
        }
    }

    $planLines = Get-MarkdownContent -Path $planPath
    foreach ($label in @('Schema', 'Status', 'Capacity', 'Started')) {
        if (Test-IsNullish (Get-MarkdownMetadataValue -Lines $planLines -Label $label)) {
            $errors.Add("plan.md is missing required metadata: $label")
        }
    }

    $status = Get-NormalizedKeyword (Get-MarkdownMetadataValue -Lines $planLines -Label 'Status')
    if ($status -notin $allowedIterationStatuses) {
        $errors.Add("plan.md has invalid iteration status '$status'")
    }

    $capacity = Get-MarkdownMetadataValue -Lines $planLines -Label 'Capacity'
    if (-not (Test-IsNullish $capacity) -and $capacity -notmatch '^\d+(?:\.\d+)?/\d+(?:\.\d+)?\s+\S+$') {
        $errors.Add("plan.md has invalid Capacity format '$capacity' (expected '<used>/<total> <unit>')")
    }

    $completed = Get-MarkdownMetadataValue -Lines $planLines -Label 'Completed'
    if ($status -eq 'complete' -and (Test-IsNullish $completed)) {
        $errors.Add('Complete iterations must record a Completed date in plan.md')
    }

    $tasks = @(Get-MarkdownSectionTable -Lines $planLines -Heading 'Tasks')
    Test-PlanTaskSet -Tasks $tasks -Errors $errors

    $taskStatuses = $tasks | ForEach-Object { $_.Status.Trim().ToLowerInvariant() }
    $hasNonTerminalTasks = [bool]($taskStatuses | Where-Object { $_ -notin $terminalTaskStatuses } | Select-Object -First 1)

    $driftPath = Join-Path -Path $IterationDirectory -ChildPath 'drift-log.md'
    $reviewPath = Join-Path -Path $IterationDirectory -ChildPath 'review.md'
    $retroPath = Join-Path -Path $IterationDirectory -ChildPath 'retro.md'
    $statePath = Join-Path -Path $IterationDirectory -ChildPath 'state.md'
    $stateLines = if (Test-Path -Path $statePath -PathType Leaf) { @(Get-MarkdownContent -Path $statePath) } else { @() }
    $reviewLines = if (Test-Path -Path $reviewPath -PathType Leaf) { @(Get-MarkdownContent -Path $reviewPath) } else { @() }
    $retroLines = if (Test-Path -Path $retroPath -PathType Leaf) { @(Get-MarkdownContent -Path $retroPath) } else { @() }
    $reviewOverallVerdict = if ($reviewLines.Count -gt 0) {
        Get-NormalizedKeyword (Get-MarkdownMetadataValue -Lines $reviewLines -Label 'Overall Verdict')
    }
    else {
        $null
    }
    $hasAcceptedReview = $reviewOverallVerdict -eq 'accepted'
    $hasReviewArtifact = $reviewLines.Count -gt 0
    $hasRetroArtifact = $retroLines.Count -gt 0
    $hasCompleteEvidence = ($status -eq 'complete') -or $hasRetroArtifact

    Test-GovernanceGateConsistency -PlanLines $planLines -HasCompletionEvidence ($hasAcceptedReview -or $hasCompleteEvidence) -Errors $errors

    $lifecycleArtifacts = @{
        'plan.md' = $planLines
    }
    if ($stateLines.Count -gt 0) {
        $lifecycleArtifacts['state.md'] = $stateLines
    }
    if ($hasReviewArtifact) {
        $lifecycleArtifacts['review.md'] = $reviewLines
    }
    if ($hasRetroArtifact) {
        $lifecycleArtifacts['retro.md'] = $retroLines
    }

    Test-LifecycleNarrative -ArtifactContents $lifecycleArtifacts -HasReviewArtifact $hasReviewArtifact -HasRetroArtifact $hasRetroArtifact -HasCompleteEvidence $hasCompleteEvidence -Errors $errors

    $signOffArtifacts = @{
        'plan.md' = $planLines
    }
    if ($hasReviewArtifact) {
        $signOffArtifacts['review.md'] = $reviewLines
    }
    if ($hasRetroArtifact) {
        $signOffArtifacts['retro.md'] = $retroLines
    }

    Test-SignOffRoleNaming -ArtifactContents $signOffArtifacts -TeamRoles $TeamRoles -Errors $errors

    switch ($status) {
        'executing' {
            Test-StateArtifact -IterationDirectory $IterationDirectory -Errors $errors
        }
        'reviewing' {
            Test-StateArtifact -IterationDirectory $IterationDirectory -Errors $errors
            if (-not (Test-Path -Path $driftPath -PathType Leaf)) {
                $errors.Add('Reviewing iterations require drift-log.md before review can start')
            }
            if ($hasNonTerminalTasks) {
                $errors.Add('Reviewing iterations require all tasks to be in terminal states')
            }
        }
        'retro' {
            Test-StateArtifact -IterationDirectory $IterationDirectory -Errors $errors
            if (-not (Test-Path -Path $driftPath -PathType Leaf)) {
                $errors.Add('Retro iterations require drift-log.md')
            }
            if ($hasNonTerminalTasks) {
                $errors.Add('Retro iterations require all tasks to be in terminal states')
            }
            Test-ReviewArtifact -ReviewPath $reviewPath -PlanTasks $tasks -Errors $errors
        }
        'complete' {
            Test-StateArtifact -IterationDirectory $IterationDirectory -Errors $errors
            if (-not (Test-Path -Path $driftPath -PathType Leaf)) {
                $errors.Add('Complete iterations require drift-log.md')
            }
            if ($hasNonTerminalTasks) {
                $errors.Add('Complete iterations require all tasks to be in terminal states')
            }
            Test-ReviewArtifact -ReviewPath $reviewPath -PlanTasks $tasks -Errors $errors -RequireAcceptedVerdict
            Test-RetroArtifact -RetroPath $retroPath -Errors $errors
        }
        'abandoned' {
            Test-StateArtifact -IterationDirectory $IterationDirectory -Errors $errors
            if (-not (Test-Path -Path $statePath -PathType Leaf)) {
                $errors.Add('Abandoned iterations require state.md with explicit reason')
            }
            else {
                $stateLines = Get-MarkdownContent -Path $statePath
                $stateText = ($stateLines -join "`n").ToLowerInvariant()
                if ($stateText -notmatch 'reason' -and $stateText -notmatch 'abandon') {
                    $errors.Add('Abandoned iterations must record an explicit abandonment reason in state.md')
                }
            }
        }
    }

    return [pscustomobject]@{
        Path = $IterationDirectory
        Errors = $errors
    }
}

$resolvedProjectPath = (Resolve-Path -Path $ProjectPath).Path
$teamRoles = Get-TeamRoleMap -ResolvedProjectPath $resolvedProjectPath
$targets = Resolve-IterationTarget -ResolvedProjectPath $resolvedProjectPath -ExplicitIterationPaths $IterationPath
$results = $targets | ForEach-Object { Test-IterationGovernance -IterationDirectory $_ -TeamRoles $teamRoles }
$hasFailures = $false

foreach ($result in $results) {
    if ($result.Errors.Count -eq 0) {
        Write-Host "PASS $($result.Path)" -ForegroundColor Green
        continue
    }

    $hasFailures = $true
    Write-Host "FAIL $($result.Path)" -ForegroundColor Red
    foreach ($errorMessage in $result.Errors) {
        Write-Host "  - $errorMessage" -ForegroundColor Red
    }
}

if ($hasFailures) {
    exit 1
}

exit 0
