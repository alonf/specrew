[CmdletBinding()]
param(
    [string]$Repository,
    [string]$ProjectOwner = 'alonf',
    [int]$ProjectNumber = 10,
    [string]$RootPath = '.',
    [switch]$IncludeClosedIterations
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

function Invoke-GitHubApiJson {
    param(
        [Parameter(Mandatory)]
        [string]$Endpoint,
        [ValidateSet('GET', 'POST', 'PATCH')]
        [string]$Method = 'GET',
        [object]$Body
    )

    if ($PSBoundParameters.ContainsKey('Body')) {
        $payload = $Body | ConvertTo-Json -Depth 20 -Compress
        return ($payload | gh api $Endpoint --method $Method --input - | ConvertFrom-Json -Depth 20)
    }

    return (gh api $Endpoint --method $Method | ConvertFrom-Json -Depth 20)
}

function Invoke-GitHubGraphQL {
    param(
        [Parameter(Mandatory)]
        [string]$Query,
        [hashtable]$Variables = @{}
    )

    $payload = @{
        query     = $Query
        variables = $Variables
    }

    $response = $payload | ConvertTo-Json -Depth 20 -Compress | gh api graphql --input - | ConvertFrom-Json -Depth 20
    if ($response.PSObject.Properties.Name -contains 'errors' -and $response.errors) {
        $messages = ($response.errors | ForEach-Object { $_.message }) -join '; '
        throw "GitHub GraphQL request failed: $messages"
    }

    return $response.data
}

function ConvertFrom-MarkdownCells {
    param([string]$Line)

    return ($Line.Trim().Trim('|').Split('|') | ForEach-Object { $_.Trim() })
}

function Get-MarkdownMetadata {
    param([string[]]$Lines)

    $metadata = @{}
    foreach ($line in $Lines) {
        if ($line -match '^\*\*(.+?)\*\*:\s*(.*)$') {
            $metadata[$Matches[1].Trim()] = $Matches[2].Trim()
        }
    }

    return $metadata
}

function Get-MarkdownTableRows {
    param(
        [string[]]$Lines,
        [string[]]$RequiredHeaders
    )

    for ($i = 0; $i -lt $Lines.Count - 1; $i++) {
        $headerLine = $Lines[$i].Trim()
        if (-not $headerLine.StartsWith('|')) {
            continue
        }

        $headers = ConvertFrom-MarkdownCells -Line $headerLine
        if ($RequiredHeaders | Where-Object { $_ -notin $headers }) {
            continue
        }

        $separatorLine = $Lines[$i + 1].Trim()
        if (-not $separatorLine.StartsWith('|')) {
            continue
        }

        $rows = @()
        for ($j = $i + 2; $j -lt $Lines.Count; $j++) {
            $rowLine = $Lines[$j].Trim()
            if (-not $rowLine.StartsWith('|')) {
                break
            }

            if ($rowLine -match '^\|[\s\-|:]+\|$') {
                continue
            }

            $cells = ConvertFrom-MarkdownCells -Line $rowLine
            if ($cells.Count -ne $headers.Count) {
                continue
            }

            $row = [ordered]@{}
            for ($k = 0; $k -lt $headers.Count; $k++) {
                $row[$headers[$k]] = $cells[$k]
            }

            $rows += [pscustomobject]$row
        }

        return $rows
    }

    return @()
}

function Normalize-Token {
    param([string]$Value)

    if ([string]::IsNullOrWhiteSpace($Value)) {
        return ''
    }

    return $Value.Trim().ToLowerInvariant()
}

function Get-IterationProjectStatus {
    param([string]$Phase)

    switch (Normalize-Token $Phase) {
        'planning' { return 'Todo' }
        'executing' { return 'In Progress' }
        'reviewing' { return 'In Progress' }
        'retro' { return 'In Progress' }
        'complete' { return 'Done' }
        'abandoned' { return 'Done' }
        default { return 'Todo' }
    }
}

function Get-TaskProjectStatus {
    param(
        [string]$TaskStatus,
        [string]$PlanPhase,
        [string]$Verdict
    )

    $normalizedTaskStatus = Normalize-Token $TaskStatus
    $normalizedVerdict = Normalize-Token $Verdict

    if ($normalizedVerdict -eq 'pass' -or $normalizedVerdict -eq 'accepted') {
        return 'Done'
    }

    switch ($normalizedTaskStatus) {
        'done' { return 'Done' }
        'complete' { return 'Done' }
        'completed' { return 'Done' }
        'pass' { return 'Done' }
        'planned' { return 'Todo' }
        'todo' { return 'Todo' }
        'in_progress' { return 'In Progress' }
        'in progress' { return 'In Progress' }
        'doing' { return 'In Progress' }
        'executing' { return 'In Progress' }
        'reviewing' { return 'In Progress' }
        'retro' { return 'In Progress' }
        'blocked' { return 'In Progress' }
        'needs-work' { return 'In Progress' }
        'needs rework' { return 'In Progress' }
        'deferred' { return 'In Progress' }
    }

    if ((Normalize-Token $PlanPhase) -eq 'complete' -and $normalizedTaskStatus -ne 'planned') {
        return 'Done'
    }

    return 'Todo'
}

function Get-PhaseLabel {
    param([string]$Phase)

    return "phase:$((Normalize-Token $Phase) -replace '\s+', '-')"
}

function Ensure-Labels {
    param(
        [string]$Repository,
        [hashtable[]]$Labels
    )

    $existingNames = @{}
    $existingLabels = gh label list --repo $Repository --limit 200 --json name | ConvertFrom-Json -Depth 5
    foreach ($existingLabel in $existingLabels) {
        $existingNames[$existingLabel.name] = $true
    }

    foreach ($label in $Labels) {
        if ($existingNames.ContainsKey($label.name)) {
            gh label edit $label.name --repo $Repository --color $label.color --description $label.description *> $null
        }
        else {
            gh label create $label.name --repo $Repository --color $label.color --description $label.description *> $null
            $existingNames[$label.name] = $true
        }
    }
}

function Get-IssueState {
    param(
        [string]$ProjectStatus,
        [switch]$CloseWhenDone
    )

    if ($CloseWhenDone -and $ProjectStatus -eq 'Done') {
        return 'closed'
    }

    return 'open'
}

function Set-Issue {
    param(
        [string]$Repository,
        [hashtable]$IssueIndex,
        [string]$IdentityKey,
        [string]$Title,
        [string]$Body,
        [string[]]$Labels,
        [string]$DesiredState
    )

    $existing = $IssueIndex[$IdentityKey]
    $payload = @{
        title  = $Title
        body   = $Body
        labels = $Labels
        state  = $DesiredState
    }

    if ($null -ne $existing) {
        $updated = Invoke-GitHubApiJson -Endpoint "repos/$Repository/issues/$($existing.number)" -Method PATCH -Body $payload
    }
    else {
        $createPayload = @{
            title  = $Title
            body   = $Body
            labels = $Labels
        }
        $updated = Invoke-GitHubApiJson -Endpoint "repos/$Repository/issues" -Method POST -Body $createPayload
        if ($DesiredState -eq 'closed') {
            $updated = Invoke-GitHubApiJson -Endpoint "repos/$Repository/issues/$($updated.number)" -Method PATCH -Body @{ state = 'closed' }
        }
    }

    $IssueIndex[$IdentityKey] = $updated
    return $updated
}

function Ensure-ProjectItem {
    param(
        [string]$ProjectId,
        [string]$IssueNodeId,
        [int]$IssueNumber,
        [hashtable]$ProjectItemsByIssue
    )

    if ($ProjectItemsByIssue.ContainsKey($IssueNumber)) {
        return $ProjectItemsByIssue[$IssueNumber]
    }

    $mutation = @'
mutation($projectId: ID!, $contentId: ID!) {
  addProjectV2ItemById(input: {projectId: $projectId, contentId: $contentId}) {
    item {
      id
    }
  }
}
'@

    $result = Invoke-GitHubGraphQL -Query $mutation -Variables @{
        projectId = $ProjectId
        contentId = $IssueNodeId
    }

    $itemId = $result.addProjectV2ItemById.item.id
    $ProjectItemsByIssue[$IssueNumber] = $itemId
    return $itemId
}

function Set-ProjectItemStatus {
    param(
        [string]$ProjectId,
        [string]$ItemId,
        [string]$FieldId,
        [string]$OptionId
    )

    $mutation = @'
mutation($projectId: ID!, $itemId: ID!, $fieldId: ID!, $optionId: String!) {
  updateProjectV2ItemFieldValue(input: {
    projectId: $projectId,
    itemId: $itemId,
    fieldId: $fieldId,
    value: { singleSelectOptionId: $optionId }
  }) {
    projectV2Item {
      id
    }
  }
}
'@

    Invoke-GitHubGraphQL -Query $mutation -Variables @{
        projectId = $ProjectId
        itemId    = $ItemId
        fieldId   = $FieldId
        optionId  = $OptionId
    } | Out-Null
}

function New-LifecycleBody {
    param(
        [string]$IdentityKey,
        [string]$FeatureSlug,
        [string]$IterationId,
        [string]$PlanPath,
        [hashtable]$PlanMetadata,
        [string]$StatePath,
        [hashtable]$StateMetadata,
        [string]$ReviewPath,
        [hashtable]$ReviewMetadata,
        [string]$RetroPath,
        [hashtable]$RetroMetadata
    )

    $stateDisplay = if ($StatePath) { '`' + $StatePath + '`' } else { 'not found' }
    $reviewDisplay = if ($ReviewPath) { '`' + $ReviewPath + '`' } else { 'not found' }
    $retroDisplay = if ($RetroPath) { '`' + $RetroPath + '`' } else { 'not found' }

    @"
<!-- specrew-sync:key=$IdentityKey -->
> This issue is synchronized from local iteration artifacts. Update the source files, not this issue, to change authoritative state.

## Source Artifacts

- Plan: `$PlanPath`
- State: $stateDisplay
- Review: $reviewDisplay
- Retro: $retroDisplay

## Iteration Summary

| Field | Value |
| ----- | ----- |
| Feature | $FeatureSlug |
| Iteration | $IterationId |
| Phase | $($PlanMetadata['Status']) |
| Capacity | $($PlanMetadata['Capacity']) |
| Started | $($PlanMetadata['Started']) |
| Completed | $($PlanMetadata['Completed']) |
| Last Completed Task | $($StateMetadata['Last Completed Task']) |
| In Progress | $($StateMetadata['In Progress']) |
| Tasks Remaining | $($StateMetadata['Tasks Remaining']) |
| Review Verdict | $($ReviewMetadata['Overall Verdict']) |
| Retro Date | $($RetroMetadata['Date']) |
"@
}

function New-TaskBody {
    param(
        [string]$IdentityKey,
        [string]$FeatureSlug,
        [string]$IterationId,
        [string]$PlanPath,
        [string]$PlanPhase,
        [pscustomobject]$Task,
        [string]$ReviewVerdict
    )

    @"
<!-- specrew-sync:key=$IdentityKey -->
> This issue is synchronized from local iteration artifacts. Update the source files, not this issue, to change authoritative state.

## Source

- Plan: `$PlanPath`
- Feature: `$FeatureSlug`
- Iteration: `$IterationId`
- Iteration phase: `$PlanPhase`

## Task Summary

| Field | Value |
| ----- | ----- |
| Task | $($Task.Task) |
| Title | $($Task.Title) |
| Requirement | $($Task.Requirement) |
| Story | $($Task.Story) |
| Effort | $($Task.Effort) |
| Owner | $($Task.Owner) |
| Status | $($Task.Status) |
| Agent | $($Task.Agent) |
| Actual | $($Task.Actual) |
| Verdict | $(if ($ReviewVerdict) { $ReviewVerdict } else { $Task.Verdict }) |
"@
}

$resolvedRoot = (Resolve-Path $RootPath).Path
Push-Location $resolvedRoot

try {
    if (-not $Repository) {
        $Repository = (gh repo view --json nameWithOwner --jq .nameWithOwner).Trim()
    }

    if (-not $Repository) {
        throw 'Unable to resolve repository name. Pass -Repository owner/name.'
    }

    $projectQuery = @'
query($login: String!, $number: Int!) {
  user(login: $login) {
    projectV2(number: $number) {
      id
      title
      url
      fields(first: 20) {
        nodes {
          ... on ProjectV2FieldCommon {
            id
            name
          }
          ... on ProjectV2SingleSelectField {
            id
            name
            options {
              id
              name
            }
          }
        }
      }
      items(first: 100) {
        nodes {
          id
          content {
            ... on Issue {
              number
            }
          }
        }
      }
    }
  }
}
'@

    $projectData = Invoke-GitHubGraphQL -Query $projectQuery -Variables @{
        login  = $ProjectOwner
        number = $ProjectNumber
    }

    if (-not $projectData.user.projectV2) {
        throw "Cannot access GitHub Project $ProjectOwner/$ProjectNumber. Configure a token with repo + project scopes for unattended sync."
    }

    $project = $projectData.user.projectV2
    $statusField = $project.fields.nodes | Where-Object { $_.name -eq 'Status' } | Select-Object -First 1
    if (-not $statusField) {
        throw 'Project is missing the default Status field.'
    }

    $statusOptionByName = @{}
    foreach ($option in $statusField.options) {
        $statusOptionByName[$option.name] = $option.id
    }

    $projectItemsByIssue = @{}
    foreach ($item in $project.items.nodes) {
        if ($item.content -and $item.content.number) {
            $projectItemsByIssue[[int]$item.content.number] = $item.id
        }
    }

    $requiredLabels = @(
        @{ name = 'specrew:sync'; color = '1D76DB'; description = 'Managed from Specrew local iteration artifacts' },
        @{ name = 'specrew:lifecycle'; color = '5319E7'; description = 'Iteration lifecycle issue mirrored from iteration artifacts' },
        @{ name = 'phase:planning'; color = 'D4E5F7'; description = 'Iteration is in planning' },
        @{ name = 'phase:executing'; color = 'FBCA04'; description = 'Iteration is in execution' },
        @{ name = 'phase:reviewing'; color = 'C5DEF5'; description = 'Iteration is in review/demo' },
        @{ name = 'phase:retro'; color = 'BFDADC'; description = 'Iteration is in retrospective' },
        @{ name = 'phase:complete'; color = '0E8A16'; description = 'Iteration is complete' },
        @{ name = 'phase:abandoned'; color = 'B60205'; description = 'Iteration was abandoned' }
    )
    Ensure-Labels -Repository $Repository -Labels $requiredLabels

    $existingIssues = Invoke-GitHubApiJson -Endpoint "repos/$Repository/issues?state=all&per_page=100"
    $issueIndex = @{}
    foreach ($issue in $existingIssues) {
        if ($issue.PSObject.Properties.Name -contains 'pull_request') {
            continue
        }

        if ($issue.body -match '<!-- specrew-sync:key=(.+?) -->') {
            $issueIndex[$Matches[1]] = $issue
        }
    }

    $planFiles = Get-ChildItem -Path (Join-Path $resolvedRoot 'specs') -Filter 'plan.md' -Recurse -File |
        Where-Object { $_.FullName -match [regex]::Escape('\iterations\') }

    $syncedCount = 0

    foreach ($planFile in $planFiles | Sort-Object FullName) {
        $relativePlanPath = $planFile.FullName.Substring($resolvedRoot.Length).TrimStart('\')
        $segments = $relativePlanPath -split '\\'
        $featureSlug = $segments[1]
        $iterationId = $segments[3]

        $planLines = Get-Content -Path $planFile.FullName
        $planMetadata = Get-MarkdownMetadata -Lines $planLines
        $planPhase = Normalize-Token $planMetadata['Status']
        $lifecycleKey = "${featureSlug}:${iterationId}:lifecycle"

        $shouldSyncIteration = $IncludeClosedIterations -or $planPhase -notin @('complete', 'abandoned') -or $issueIndex.ContainsKey($lifecycleKey)
        if (-not $shouldSyncIteration) {
            continue
        }

        $statePath = Join-Path $planFile.Directory.FullName 'state.md'
        $reviewPath = Join-Path $planFile.Directory.FullName 'review.md'
        $retroPath = Join-Path $planFile.Directory.FullName 'retro.md'

        $stateMetadata = @{}
        $reviewMetadata = @{}
        $retroMetadata = @{}

        if (Test-Path $statePath) {
            $stateMetadata = Get-MarkdownMetadata -Lines (Get-Content -Path $statePath)
        }
        if (Test-Path $reviewPath) {
            $reviewMetadata = Get-MarkdownMetadata -Lines (Get-Content -Path $reviewPath)
        }
        if (Test-Path $retroPath) {
            $retroMetadata = Get-MarkdownMetadata -Lines (Get-Content -Path $retroPath)
        }

        $lifecycleTitle = "[$featureSlug][Iteration $iterationId] Lifecycle"
        $lifecycleBody = New-LifecycleBody -IdentityKey $lifecycleKey `
            -FeatureSlug $featureSlug `
            -IterationId $iterationId `
            -PlanPath $relativePlanPath `
            -PlanMetadata $planMetadata `
            -StatePath $(if (Test-Path $statePath) { $statePath.Substring($resolvedRoot.Length).TrimStart('\') } else { '' }) `
            -StateMetadata $stateMetadata `
            -ReviewPath $(if (Test-Path $reviewPath) { $reviewPath.Substring($resolvedRoot.Length).TrimStart('\') } else { '' }) `
            -ReviewMetadata $reviewMetadata `
            -RetroPath $(if (Test-Path $retroPath) { $retroPath.Substring($resolvedRoot.Length).TrimStart('\') } else { '' }) `
            -RetroMetadata $retroMetadata

        $lifecycleProjectStatus = Get-IterationProjectStatus -Phase $planPhase
        $lifecycleIssue = Set-Issue -Repository $Repository `
            -IssueIndex $issueIndex `
            -IdentityKey $lifecycleKey `
            -Title $lifecycleTitle `
            -Body $lifecycleBody `
            -Labels @('specrew:sync', 'specrew:lifecycle', (Get-PhaseLabel -Phase $planPhase)) `
            -DesiredState (Get-IssueState -ProjectStatus $lifecycleProjectStatus -CloseWhenDone)

        $lifecycleItemId = Ensure-ProjectItem -ProjectId $project.id -IssueNodeId $lifecycleIssue.node_id -IssueNumber $lifecycleIssue.number -ProjectItemsByIssue $projectItemsByIssue
        Set-ProjectItemStatus -ProjectId $project.id -ItemId $lifecycleItemId -FieldId $statusField.id -OptionId $statusOptionByName[$lifecycleProjectStatus]
        $syncedCount++

        $taskRows = Get-MarkdownTableRows -Lines $planLines -RequiredHeaders @('Task', 'Title', 'Requirement', 'Story', 'Effort', 'Owner', 'Status', 'Agent', 'Actual', 'Verdict')
        $reviewRows = @()
        if (Test-Path $reviewPath) {
            $reviewRows = Get-MarkdownTableRows -Lines (Get-Content -Path $reviewPath) -RequiredHeaders @('Task', 'Requirement', 'Verdict', 'Notes')
        }

        $reviewVerdictsByTask = @{}
        foreach ($reviewRow in $reviewRows) {
            $reviewVerdictsByTask[$reviewRow.Task] = $reviewRow.Verdict
        }

        foreach ($task in $taskRows) {
            $taskKey = "${featureSlug}:${iterationId}:task:$($task.Task)"
            $reviewVerdict = if ($reviewVerdictsByTask.ContainsKey($task.Task)) { $reviewVerdictsByTask[$task.Task] } else { '' }
            $taskProjectStatus = Get-TaskProjectStatus -TaskStatus $task.Status -PlanPhase $planPhase -Verdict $reviewVerdict
            $taskDesiredState = Get-IssueState -ProjectStatus $taskProjectStatus -CloseWhenDone:($taskProjectStatus -eq 'Done')
            $taskTitle = "[$featureSlug][Iteration $iterationId][$($task.Task)] $($task.Title)"
            $taskBody = New-TaskBody -IdentityKey $taskKey `
                -FeatureSlug $featureSlug `
                -IterationId $iterationId `
                -PlanPath $relativePlanPath `
                -PlanPhase $planPhase `
                -Task $task `
                -ReviewVerdict $reviewVerdict

            $taskIssue = Set-Issue -Repository $Repository `
                -IssueIndex $issueIndex `
                -IdentityKey $taskKey `
                -Title $taskTitle `
                -Body $taskBody `
                -Labels @('specrew:sync', (Get-PhaseLabel -Phase $planPhase)) `
                -DesiredState $taskDesiredState

            $taskItemId = Ensure-ProjectItem -ProjectId $project.id -IssueNodeId $taskIssue.node_id -IssueNumber $taskIssue.number -ProjectItemsByIssue $projectItemsByIssue
            Set-ProjectItemStatus -ProjectId $project.id -ItemId $taskItemId -FieldId $statusField.id -OptionId $statusOptionByName[$taskProjectStatus]
            $syncedCount++
        }
    }

    Write-Host "Synced $syncedCount issue(s) to $($project.url)."
}
finally {
    Pop-Location
}
