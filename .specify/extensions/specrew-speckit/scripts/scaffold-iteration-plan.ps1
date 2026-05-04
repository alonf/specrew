[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)]
    [string]$SpecPath,

    [Parameter(Mandatory = $true)]
    [string]$IterationNumber,

    [string[]]$RequirementScope,
    [string]$IterationConfigPath,
    [switch]$DryRun,
    [switch]$PassThru
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

function Add-ScaffoldAction {
    param(
        [AllowEmptyCollection()]
        [Parameter(Mandatory = $true)]
        [System.Collections.ArrayList]$Actions,

        [Parameter(Mandatory = $true)]
        [string]$Action,

        [Parameter(Mandatory = $true)]
        [string]$Path
    )

    $null = $Actions.Add([pscustomobject]@{
            Action = $Action
            Path   = $Path
        })
}

function Ensure-Directory {
    param(
        [Parameter(Mandatory = $true)]
        [string]$Path,

        [AllowEmptyCollection()]
        [Parameter(Mandatory = $true)]
        [System.Collections.ArrayList]$Actions
    )

    if (Test-Path -LiteralPath $Path) {
        Add-ScaffoldAction -Actions $Actions -Action 'preserved-directory' -Path $Path
        return
    }

    Add-ScaffoldAction -Actions $Actions -Action $(if ($DryRun) { 'would-create-directory' } else { 'created-directory' }) -Path $Path
    if (-not $DryRun) {
        New-Item -ItemType Directory -Path $Path -Force | Out-Null
    }
}

function Write-MissingFile {
    param(
        [Parameter(Mandatory = $true)]
        [string]$TargetPath,

        [Parameter(Mandatory = $true)]
        [string]$Content,

        [AllowEmptyCollection()]
        [Parameter(Mandatory = $true)]
        [System.Collections.ArrayList]$Actions
    )

    if (Test-Path -LiteralPath $TargetPath) {
        Add-ScaffoldAction -Actions $Actions -Action 'preserved' -Path $TargetPath
        return
    }

    Add-ScaffoldAction -Actions $Actions -Action $(if ($DryRun) { 'would-create' } else { 'created' }) -Path $TargetPath
    if (-not $DryRun) {
        $parent = Split-Path -Parent $TargetPath
        if (-not (Test-Path -LiteralPath $parent)) {
            New-Item -ItemType Directory -Path $parent -Force | Out-Null
        }

        [System.IO.File]::WriteAllText($TargetPath, $Content, [System.Text.UTF8Encoding]::new($false))
    }
}

function Get-MarkdownContent {
    param([string]$Path)

    return @(Get-Content -LiteralPath $Path -Encoding UTF8)
}

function Get-RelativePath {
    param(
        [Parameter(Mandatory = $true)]
        [string]$FromDirectory,

        [Parameter(Mandatory = $true)]
        [string]$ToPath
    )

    $fromUri = [System.Uri]([System.IO.Path]::GetFullPath($FromDirectory).TrimEnd('\') + '\')
    $toUri = [System.Uri]([System.IO.Path]::GetFullPath($ToPath))
    $relative = $fromUri.MakeRelativeUri($toUri).ToString()
    return [System.Uri]::UnescapeDataString($relative)
}

function Get-RequirementSummaryMap {
    param(
        [AllowEmptyString()]
        [string[]]$Lines
    )

    $requirements = [ordered]@{}
    foreach ($line in $Lines) {
        if ($line -match '^\s*-\s+\*\*(FR-\d+)\*\*:\s+(.+?)\s*$') {
            $requirements[$Matches[1]] = $Matches[2].Trim()
        }
    }

    return $requirements
}

function Get-RequirementStoryMap {
    param(
        [AllowEmptyString()]
        [string[]]$Lines
    )

    $storyMap = @{}
    foreach ($line in $Lines) {
        if ($line -match '^\s*-\s+(US-\d+)(?:\s*\([^)]+\))?\s+→\s+(.+?)\s*$') {
            $storyId = $Matches[1]
            $requirements = $Matches[2] -split ',' | ForEach-Object { $_.Trim() } | Where-Object { $_ -match '^FR-\d+$' }
            foreach ($requirement in $requirements) {
                if (-not $storyMap.ContainsKey($requirement)) {
                    $storyMap[$requirement] = New-Object System.Collections.Generic.List[string]
                }

                if (-not $storyMap[$requirement].Contains($storyId)) {
                    $storyMap[$requirement].Add($storyId)
                }
            }
        }
    }

    return $storyMap
}

function Get-IterationConfig {
    param(
        [AllowNull()]
        [string]$Path
    )

    $config = @{
        effort_unit            = 'story_points'
        capacity_per_iteration = '20'
        iteration_bounding     = 'scope'
        time_limit_hours       = 'null'
        overcommit_threshold   = '1.0'
        calibration_enabled    = 'true'
        defer_strategy         = 'manual'
    }

    if ([string]::IsNullOrWhiteSpace($Path) -or -not (Test-Path -LiteralPath $Path)) {
        return $config
    }

    foreach ($line in Get-MarkdownContent -Path $Path) {
        if ($line -match '^\s*effort_unit:\s*"?([^"#]+?)"?\s*$') {
            $config.effort_unit = $Matches[1].Trim()
        }
        elseif ($line -match '^\s*capacity_per_iteration:\s*("?)([^"#]+)\1\s*$') {
            $config.capacity_per_iteration = $Matches[2].Trim()
        }
        elseif ($line -match '^\s*iteration_bounding:\s*"?([^"#]+?)"?\s*$') {
            $config.iteration_bounding = $Matches[1].Trim()
        }
        elseif ($line -match '^\s*time_limit_hours:\s*("?)([^"#]+)\1\s*$') {
            $config.time_limit_hours = $Matches[2].Trim()
        }
        elseif ($line -match '^\s*overcommit_threshold:\s*("?)([^"#]+)\1\s*$') {
            $config.overcommit_threshold = $Matches[2].Trim()
        }
        elseif ($line -match '^\s*calibration_enabled:\s*("?)([^"#]+)\1\s*$') {
            $config.calibration_enabled = $Matches[2].Trim()
        }
        elseif ($line -match '^\s*defer_strategy:\s*"?([^"#]+?)"?\s*$') {
            $config.defer_strategy = $Matches[1].Trim()
        }
    }

    return $config
}

$resolvedSpecPath = [System.IO.Path]::GetFullPath($SpecPath)
if (-not (Test-Path -LiteralPath $resolvedSpecPath)) {
    throw "Spec file '$resolvedSpecPath' does not exist."
}

$specDirectory = Split-Path -Parent $resolvedSpecPath
$projectSpecsRoot = Split-Path -Parent $specDirectory
$projectRoot = Split-Path -Parent $projectSpecsRoot
$iterationDirectory = Join-Path (Join-Path $specDirectory 'iterations') $IterationNumber
$planPath = Join-Path $iterationDirectory 'plan.md'
$resolvedConfigPath = if ($IterationConfigPath) {
    [System.IO.Path]::GetFullPath($IterationConfigPath)
}
else {
    Join-Path $projectRoot '.specrew\iteration-config.yml'
}

$specLines = @(Get-MarkdownContent -Path $resolvedSpecPath)
$requirementSummaries = Get-RequirementSummaryMap -Lines $specLines
$requirementStories = Get-RequirementStoryMap -Lines $specLines

$scopeList = if ($RequirementScope -and $RequirementScope.Count -gt 0) {
    @($RequirementScope | ForEach-Object { $_.Trim() } | Where-Object { -not [string]::IsNullOrWhiteSpace($_) })
}
else {
    @($requirementSummaries.Keys)
}

if ($scopeList.Count -eq 0) {
    throw "No functional requirements were found in '$resolvedSpecPath'."
}

$missingRequirements = @($scopeList | Where-Object { -not $requirementSummaries.Contains($_) })
if ($missingRequirements.Count -gt 0) {
    throw "Requirement(s) not found in spec: $($missingRequirements -join ', ')"
}

$iterationConfig = Get-IterationConfig -Path $resolvedConfigPath
$actions = [System.Collections.ArrayList]::new()

Ensure-Directory -Path (Split-Path -Parent $iterationDirectory) -Actions $actions
Ensure-Directory -Path $iterationDirectory -Actions $actions

$scopeRows = @(
    '| Requirement | Summary | Stories |'
    '| ----------- | ------- | ------- |'
)
foreach ($requirementId in $scopeList) {
    $stories = if ($requirementStories.ContainsKey($requirementId)) {
        [string]::Join(', ', $requirementStories[$requirementId])
    }
    else {
        '—'
    }

    $scopeRows += ('| {0} | {1} | {2} |' -f $requirementId, ($requirementSummaries[$requirementId] -replace '\|', '\|'), $stories)
}

$relativeSpecPath = Get-RelativePath -FromDirectory $iterationDirectory -ToPath $resolvedSpecPath
$startedDate = (Get-Date).ToString('yyyy-MM-dd')
$capacityLimit = $iterationConfig.capacity_per_iteration
$overcommitMessage = 'Warn planners when total estimated effort exceeds configured capacity.'

$parsedCapacity = 0.0
$parsedThreshold = 0.0
if ([double]::TryParse([string]$iterationConfig.capacity_per_iteration, [ref]$parsedCapacity) -and
    [double]::TryParse([string]$iterationConfig.overcommit_threshold, [ref]$parsedThreshold)) {
    $warnAt = [math]::Round(($parsedCapacity * $parsedThreshold), 2)
    $overcommitMessage = 'Warn planners when total estimated effort exceeds {0} {1} (capacity {2} x threshold {3}).' -f $warnAt, $iterationConfig.effort_unit, $iterationConfig.capacity_per_iteration, $iterationConfig.overcommit_threshold
}

$timeLimitDisplay = if ([string]::IsNullOrWhiteSpace($iterationConfig.time_limit_hours) -or $iterationConfig.time_limit_hours -eq 'null') {
    'n/a'
}
else {
    $iterationConfig.time_limit_hours
}

$effortModelRows = @(
    '| Setting | Value | Notes |'
    '| ------- | ----- | ----- |'
    ('| Effort Unit | {0} | Unit used in task effort, capacity, and retro variance. |' -f $iterationConfig.effort_unit)
    ('| Capacity per Iteration | {0} | Maximum planned effort before overcommit guidance applies. |' -f $iterationConfig.capacity_per_iteration)
    ('| Iteration Bounding | {0} | `scope` keeps requirements fixed; `time` enforces a time ceiling. |' -f $iterationConfig.iteration_bounding)
    ('| Time Limit (hours) | {0} | Only applies when iteration bounding is `time`. |' -f $timeLimitDisplay)
    ('| Overcommit Threshold | {0} | {1} |' -f $iterationConfig.overcommit_threshold, $overcommitMessage)
    ('| Defer Strategy | {0} | How planning should choose deferrals when the iteration is over capacity. |' -f $iterationConfig.defer_strategy)
    ('| Calibration Enabled | {0} | When true, retrospectives should suggest future capacity adjustments. |' -f $iterationConfig.calibration_enabled)
)

$phaseRows = @(
    '| Phase | Estimated Effort | Notes |'
    '| ----- | ---------------- | ----- |'
    '| Planning | TBD | Populate after task decomposition and approval gating |'
    '| Discovery/Spikes | TBD | Capture any required risk-reduction work revealed during planning |'
    '| Implementation | TBD | Sum planned delivery tasks once the task table is complete |'
    '| Review | TBD | Estimate review/demo effort after verdict flow is defined |'
    '| Rework | TBD | Expected needs-work buffer if review finds gaps |'
)

$planContent = @"
# Iteration Plan: $IterationNumber (Stub)

**Schema**: v1
**Spec**: [$relativeSpecPath]($relativeSpecPath)
**Status**: planning
**Capacity**: 0/$($iterationConfig.capacity_per_iteration) $($iterationConfig.effort_unit)
**Started**: $startedDate
**Completed**:

## Scope Summary

$($scopeRows -join [Environment]::NewLine)

## Tasks

| Task | Title | Requirement | Story | Effort | Owner | Status | Agent | Actual | Verdict |
| ---- | ----- | ----------- | ----- | ------ | ----- | ------ | ----- | ------ | ------- |

## Effort Model

$($effortModelRows -join [Environment]::NewLine)

## Phase Baseline

$($phaseRows -join [Environment]::NewLine)

## Traceability Summary

- Requirement scope for this stub: $($scopeList -join ', ')
- User stories represented in current scope: $((@($scopeList | ForEach-Object { if ($requirementStories.ContainsKey($_)) { $requirementStories[$_] } }) | Select-Object -Unique) -join ', ')
- Pending detailed planning: populate the task table, then run `specrew-capacity-planning` and `specrew-traceability-check` before approval.
- Overcommit guardrail: compare planned task effort against the configured threshold and record any required deferrals from the lowest-priority requirement slices before leaving `planning`.

## Notes

- This stub captures the planned scope pending detailed planning in the Specrew Planning ceremony.
- Add task rows only for work that is traceable to the scoped requirements above.
- Keep `Status: planning` until the plan is fully decomposed and approved.
- If task effort exceeds the configured threshold, make the deferral decision explicit in this plan before execution starts and name the lowest-priority requirement slices proposed for deferral.
"@

Write-MissingFile -TargetPath $planPath -Content $planContent -Actions $actions

if ($PassThru) {
    $actions
    return
}

$actions | Select-Object Action, Path | Format-Table -AutoSize
Write-Host ("Iteration plan scaffold {0} for {1}" -f ($(if ($DryRun) { 'previewed' } else { 'completed' }), $planPath)) -ForegroundColor Green
exit 0
