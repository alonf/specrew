[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)]
    [string]$SpecDirectory,

    [Parameter(Mandatory = $true)]
    [string]$IterationNumber,

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

function Get-MarkdownSectionTable {
    param(
        [AllowNull()]
        [AllowEmptyCollection()]
        [string[]]$Lines,
        [string]$Heading
    )

    if ($null -eq $Lines -or $Lines.Count -eq 0) {
        return @()
    }

    $headingPattern = '^#{2,3}\s+' + [regex]::Escape($Heading) + '\b'
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
        if ($currentLine -match '^#{2,3}\s+') {
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

    return $rows.ToArray()
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

function Normalize-MarkdownCell {
    param([AllowNull()][string]$Value)

    if ($null -eq $Value) {
        return ''
    }

    return $Value.Trim().Trim('`')
}

function Convert-ToRepoRelativePath {
    param(
        [Parameter(Mandatory = $true)]
        [string]$BasePath,

        [Parameter(Mandatory = $true)]
        [string]$TargetPath
    )

    return ([System.IO.Path]::GetRelativePath($BasePath, $TargetPath)).Replace('\', '/')
}

function Get-DefaultRequirementRefsForGate {
    param(
        [Parameter(Mandatory = $true)]
        [string]$GateId
    )

    switch ($GateId) {
        'dead-field' { return @('FR-011', 'FR-027', 'FR-030') }
        'anti-pattern' { return @('FR-011', 'FR-028', 'FR-030') }
        'test-integrity' { return @('FR-011', 'FR-029', 'FR-030') }
        'stack-tooling-evidence' { return @('FR-011') }
        'quality-lens-review' { return @('FR-011', 'FR-012') }
        'concurrency-correctness-review' { return @('FR-011', 'FR-012', 'FR-015') }
        'resiliency-semantics-review' { return @('FR-011', 'FR-012', 'FR-015') }
        'retry-idempotency-review' { return @('FR-011', 'FR-012', 'FR-015') }
        default { return @('FR-011') }
    }
}

function Resolve-QualityEvidenceSource {
    param(
        [AllowNull()][string]$Value,
        [Parameter(Mandatory = $true)]
        [string]$FeatureId,
        [Parameter(Mandatory = $true)]
        [string]$IterationNumber,
        [Parameter(Mandatory = $true)]
        [string]$FindingsRef,
        [Parameter(Mandatory = $true)]
        [string]$EvidenceRef
    )

    $normalized = Normalize-MarkdownCell $Value
    if ([string]::IsNullOrWhiteSpace($normalized)) {
        return $EvidenceRef
    }

    $resolved = $normalized.Replace('specs/<feature>/iterations/<NNN>/quality/mechanical-findings.json', $FindingsRef)
    $resolved = $resolved.Replace('specs/<feature>/iterations/<NNN>/quality/quality-evidence.md', $EvidenceRef)
    $resolved = $resolved.Replace('<feature>', $FeatureId)
    $resolved = $resolved.Replace('<NNN>', $IterationNumber)
    return $resolved
}

function Get-DefaultQualityGateRows {
    return @(
        [pscustomobject]@{ 'Required Quality Gate' = 'dead-field'; Category = 'mechanical'; 'Evidence Source' = 'specs/<feature>/iterations/<NNN>/quality/mechanical-findings.json' }
        [pscustomobject]@{ 'Required Quality Gate' = 'anti-pattern'; Category = 'mechanical'; 'Evidence Source' = 'specs/<feature>/iterations/<NNN>/quality/mechanical-findings.json' }
        [pscustomobject]@{ 'Required Quality Gate' = 'test-integrity'; Category = 'mechanical'; 'Evidence Source' = 'specs/<feature>/iterations/<NNN>/quality/mechanical-findings.json' }
        [pscustomobject]@{ 'Required Quality Gate' = 'stack-tooling-evidence'; Category = 'tooling'; 'Evidence Source' = 'specs/<feature>/iterations/<NNN>/quality/quality-evidence.md' }
        [pscustomobject]@{ 'Required Quality Gate' = 'quality-lens-review'; Category = 'manual-evidence'; 'Evidence Source' = 'specs/<feature>/iterations/<NNN>/quality/quality-evidence.md' }
    )
}

function Get-QualityEvidenceContent {
    param(
        [Parameter(Mandatory = $true)]
        [string]$PlanPath,
        [Parameter(Mandatory = $true)]
        [string]$FeatureId,
        [Parameter(Mandatory = $true)]
        [string]$IterationNumber,
        [Parameter(Mandatory = $true)]
        [string]$FindingsRef,
        [Parameter(Mandatory = $true)]
        [string]$EvidenceRef,
        [Parameter(Mandatory = $true)]
        [string]$ReviewedAt
    )

    $planLines = if (Test-Path -LiteralPath $PlanPath -PathType Leaf) {
        @(Get-MarkdownContent -Path $PlanPath)
    }
    else {
        @()
    }

    $profileRef = Normalize-MarkdownCell (Get-MarkdownMetadataValue -Lines $planLines -Label 'Inferred Quality Profile')
    if ([string]::IsNullOrWhiteSpace($profileRef)) {
        $profileRef = 'quality-profile.pending'
    }

    $presetRefs = Normalize-MarkdownCell (Get-MarkdownMetadataValue -Lines $planLines -Label 'Selected preset ref or explicit custom composition')
    if ([string]::IsNullOrWhiteSpace($presetRefs)) {
        $presetRefs = '(pending preset selection)'
    }

    $gateRows = @(Get-MarkdownSectionTable -Lines $planLines -Heading 'Required Quality Gates')
    if ($gateRows.Count -eq 0) {
        $gateRows = @(Get-DefaultQualityGateRows)
    }
    $lines = [System.Collections.Generic.List[string]]::new()
    $null = $lines.Add("# Quality Evidence: Iteration $IterationNumber")
    $null = $lines.Add('')
    $null = $lines.Add(('**Profile Ref**: `' + $profileRef + '`'))
    $null = $lines.Add(('**Preset Refs**: ' + $presetRefs))
    $null = $lines.Add(('**Findings Ref**: `' + $FindingsRef + '`'))
    $null = $lines.Add('**Reviewed By**: Reviewer (pending)')
    $null = $lines.Add(('**Reviewed At**: ' + $ReviewedAt))
    $null = $lines.Add('')
    $null = $lines.Add('## Gate Matrix')
    $null = $lines.Add('')
    $null = $lines.Add('| Gate | Requirement | Evidence Source | Status | Exception |')
    $null = $lines.Add('| --- | --- | --- | --- | --- |')

    foreach ($gateRow in $gateRows) {
        $gateId = Normalize-MarkdownCell ([string]$gateRow.'Required Quality Gate')
        if ([string]::IsNullOrWhiteSpace($gateId)) {
            continue
        }

        $requirementRefs = (Get-DefaultRequirementRefsForGate -GateId $gateId) -join ', '
        $evidenceSource = Resolve-QualityEvidenceSource `
            -Value ([string]$gateRow.'Evidence Source') `
            -FeatureId $FeatureId `
            -IterationNumber $IterationNumber `
            -FindingsRef $FindingsRef `
            -EvidenceRef $EvidenceRef

        $null = $lines.Add(('| `{0}` | {1} | `{2}` | `planned` | `—` |' -f $gateId, $requirementRefs, $evidenceSource))
    }

    return ($lines -join [Environment]::NewLine) + [Environment]::NewLine
}

function Get-MechanicalFindingsScaffoldJson {
    param(
        [Parameter(Mandatory = $true)]
        [string]$FeatureRef,
        [Parameter(Mandatory = $true)]
        [string]$IterationRef,
        [Parameter(Mandatory = $true)]
        [string]$GeneratedAt
    )

    return ([pscustomobject][ordered]@{
            schemaVersion = 'v1'
            featureRef    = $FeatureRef
            iterationRef  = $IterationRef
            generatedAt   = $GeneratedAt
            generator     = [pscustomobject][ordered]@{
                name    = 'specrew-iteration-scaffold'
                version = '1.0.0'
            }
            findings      = @()
        } | ConvertTo-Json -Depth 8)
}

function Test-PhaseTwoQualityArtifactScaffold {
    param(
        [AllowEmptyCollection()]
        [string[]]$PlanLines,
        [string]$QualityContractPath
    )

    $phaseTwoPattern = 'hardening-gate\.md|trap-reapplication\.md|quality[\\/]+lenses'
    $planText = ($PlanLines -join [Environment]::NewLine)
    if ($planText -match $phaseTwoPattern) {
        return $true
    }

    if (Test-Path -LiteralPath $QualityContractPath -PathType Leaf) {
        $contractText = Get-Content -LiteralPath $QualityContractPath -Raw -Encoding UTF8
        return $contractText -match $phaseTwoPattern
    }

    return $false
}

function Get-HardeningGateContent {
    param(
        [Parameter(Mandatory = $true)]
        [string]$FeatureRef,
        [Parameter(Mandatory = $true)]
        [string]$IterationRef,
        [Parameter(Mandatory = $true)]
        [string]$IterationNumber,
        [Parameter(Mandatory = $true)]
        [string]$ReviewedAt
    )

    $lines = [System.Collections.Generic.List[string]]::new()
    $null = $lines.Add("# Hardening Gate: Iteration $IterationNumber")
    $null = $lines.Add('')
    $null = $lines.Add('**Schema**: v1')
    $null = $lines.Add('**Gate ID**: `pre-implementation-hardening`')
    $null = $lines.Add(('**Feature Ref**: `' + $FeatureRef + '`'))
    $null = $lines.Add(('**Iteration Ref**: `' + $IterationRef + '`'))
    $null = $lines.Add('**Requested Review Class**: `strongest-available`')
    $null = $lines.Add('**Effective Review Class**: `(pending hardening review)`')
    $null = $lines.Add('**Overall Verdict**: `blocked`')
    $null = $lines.Add('**Approval Ref**: `—`')
    $null = $lines.Add('**Reviewed By**: Reviewer (pending)')
    $null = $lines.Add(('**Reviewed At**: ' + $ReviewedAt))
    $null = $lines.Add('')
    $null = $lines.Add('## Concern Review')
    $null = $lines.Add('')
    $null = $lines.Add('| Concern | Category | Status | Blocking | Rationale | Approval |')
    $null = $lines.Add('| --- | --- | --- | --- | --- | --- |')
    $null = $lines.Add('| `security-surface` | `security` | `tbd` | `true` | Scaffolded placeholder. Review trust boundaries, privilege changes, and sensitive flows before implementation proceeds. | `—` |')
    $null = $lines.Add('| `error-handling-expectations` | `error-handling` | `tbd` | `true` | Scaffolded placeholder. Record expected failure semantics and incomplete-state handling before implementation proceeds. | `—` |')
    $null = $lines.Add('| `retry-idempotency-requirements` | `retry-idempotency` | `tbd` | `true` | Scaffolded placeholder. Confirm whether retries/idempotency are required or explicitly not applicable. | `—` |')
    $null = $lines.Add('| `test-integrity-targets` | `test-integrity` | `tbd` | `true` | Scaffolded placeholder. Tie negative-path expectations to observable test evidence before implementation proceeds. | `—` |')
    $null = $lines.Add('| `operational-resilience-concerns` | `operational` | `tbd` | `true` | Scaffolded placeholder. Review runtime resilience, fallback, and operator-facing failure signals before implementation proceeds. | `—` |')
    $null = $lines.Add('')
    $null = $lines.Add('## Notes')
    $null = $lines.Add('')
    $null = $lines.Add('- This artifact was scaffolded before the hardening review ran.')
    $null = $lines.Add('- Replace placeholder statuses with reviewed outcomes before marking implementation readiness.')
    return ($lines -join [Environment]::NewLine) + [Environment]::NewLine
}

function Get-TrapReapplicationContent {
    param(
        [Parameter(Mandatory = $true)]
        [string]$IterationNumber,
        [Parameter(Mandatory = $true)]
        [string]$RecordedAt
    )

    $lines = [System.Collections.Generic.List[string]]::new()
    $null = $lines.Add("# Trap Reapplication: Iteration $IterationNumber")
    $null = $lines.Add('')
    $null = $lines.Add('**Schema**: v1')
    $null = $lines.Add('**Scan ID**: `trap-reapplication.pending`')
    $null = $lines.Add(('**Recorded At**: ' + $RecordedAt))
    $null = $lines.Add('')
    $null = $lines.Add('## Scan Log')
    $null = $lines.Add('')
    $null = $lines.Add('| Trap Ref | Scan Scope | Result | Matches |')
    $null = $lines.Add('| --- | --- | --- | --- |')
    $null = $lines.Add('| `(pending trap refs)` | `(pending scan scope)` | `skipped-with-rationale` | Scaffolded placeholder. Known-trap reapplication has not run yet. |')
    $null = $lines.Add('')
    $null = $lines.Add('## Notes')
    $null = $lines.Add('')
    $null = $lines.Add('- Replace the placeholder row with concrete trap scan evidence once reapplication runs.')
    return ($lines -join [Environment]::NewLine) + [Environment]::NewLine
}

function Get-PlanTaskIds {
    param(
        [Parameter(Mandatory = $true)]
        [string]$PlanPath
    )

    if (-not (Test-Path -LiteralPath $PlanPath)) {
        return @()
    }

    $planLines = @(Get-MarkdownContent -Path $PlanPath)
    $taskRows = @(Get-MarkdownSectionTable -Lines $planLines -Heading 'Tasks')
    $seen = New-Object System.Collections.Generic.HashSet[string] ([System.StringComparer]::OrdinalIgnoreCase)
    $taskIds = New-Object System.Collections.Generic.List[string]

    foreach ($taskRow in $taskRows) {
        $taskId = [string]$taskRow.Task
        if ([string]::IsNullOrWhiteSpace($taskId)) {
            continue
        }

        $taskId = $taskId.Trim()
        if ($seen.Add($taskId)) {
            $null = $taskIds.Add($taskId)
        }
    }

    return $taskIds.ToArray()
}

function Get-BaselineRef {
    param(
        [Parameter(Mandatory = $true)]
        [string]$SpecDirectory
    )

    $projectRoot = Split-Path -Parent $SpecDirectory
    $defaultBaselineRef = 'iteration-baseline'
    $configPath = Join-Path $projectRoot '.specrew\iteration-config.yml'

    if (Test-Path -LiteralPath $configPath -PathType Leaf) {
        foreach ($line in Get-Content -LiteralPath $configPath -Encoding UTF8) {
            if ($line -match '^\s{2}baseline_ref:\s*"?([^"#]+?)"?\s*$') {
                $defaultBaselineRef = $Matches[1].Trim()
                break
            }
        }
    }

    $gitCommand = Get-Command -Name 'git' -ErrorAction SilentlyContinue
    if ($null -eq $gitCommand) {
        return $defaultBaselineRef
    }

    $headRef = @(& git -C $projectRoot rev-parse HEAD 2>$null)
    if ($LASTEXITCODE -eq 0 -and $headRef.Count -gt 0 -and -not [string]::IsNullOrWhiteSpace($headRef[0])) {
        return [string]$headRef[0]
    }

    return $defaultBaselineRef
}

$resolvedSpecDirectory = [System.IO.Path]::GetFullPath($SpecDirectory)
$projectRoot = Split-Path -Parent (Split-Path -Parent $resolvedSpecDirectory)
$iterationsRoot = Join-Path $resolvedSpecDirectory 'iterations'
$iterationDirectory = Join-Path $iterationsRoot $IterationNumber
$planPath = Join-Path $iterationDirectory 'plan.md'
$statePath = Join-Path $iterationDirectory 'state.md'
$driftLogPath = Join-Path $iterationDirectory 'drift-log.md'
$timestamp = (Get-Date).ToUniversalTime().ToString('yyyy-MM-ddTHH:mm:ssZ')
$actions = [System.Collections.ArrayList]::new()

if (-not (Test-Path -LiteralPath $resolvedSpecDirectory)) {
    throw "Spec directory '$resolvedSpecDirectory' does not exist."
}

Ensure-Directory -Path $iterationsRoot -Actions $actions
Ensure-Directory -Path $iterationDirectory -Actions $actions

$taskIds = @(Get-PlanTaskIds -PlanPath $planPath)
$tasksRemaining = if ($taskIds.Count -gt 0) { $taskIds -join ', ' } else { '(populate from plan.md)' }
$baselineRef = Get-BaselineRef -SpecDirectory $resolvedSpecDirectory

$stateContent = @"
# Iteration State: $IterationNumber

**Schema**: v1
**Last Completed Task**: (none)
**Tasks Remaining**: $tasksRemaining
**In Progress**: (none)
**Baseline Ref**: $baselineRef
**Updated**: $timestamp

## Execution Summary

- Execution has not started yet.
- This artifact was scaffolded before task execution so resume state can be updated after each task.

## Notes

- Update this file after each task completes.
- Keep task identifiers aligned to plan.md.

<!-- >>> specrew-managed escalation-state >>> -->
## Repair Escalation

- **Status**: inactive
- **Artifact**: (none)
- **Gate**: (none)
- **Failure Count**: 0
- **Current Tier**: efficiency
- **Current Owner**: (none)
- **Locked Out Agents**: (none)
- **Last Escalated**: (none)
- **Resolved At**: (none)
- **Notes**: (none)
<!-- <<< specrew-managed escalation-state <<< -->
"@

$driftLogContent = @"
# Drift Log: Iteration $IterationNumber

**Schema**: v1

## Summary

**Total drift events**: 0
**Resolution rate**: 100% (0/0 resolved)
**Specification drift**: None detected

## Events

No specification drift detected during Iteration $IterationNumber execution to date.

### Resolution Strategies (Unused)

The following resolution strategies remain available if drift is detected later in execution:
- **spec-updated**: Update the spec to reflect implementation choice
- **implementation-reverted**: Revert implementation to match spec
- **deferred**: Mark drift as deferred to next iteration
- **human-decision**: Escalate to Alon for resolution

### Notes

- This artifact was scaffolded before review starts so drift can be logged immediately when detected.
- Replace the zero-drift summary with real counts when the first drift event is recorded.
"@

Write-MissingFile -TargetPath $statePath -Content $stateContent -Actions $actions
Write-MissingFile -TargetPath $driftLogPath -Content $driftLogContent -Actions $actions

$planLines = if (Test-Path -LiteralPath $planPath -PathType Leaf) {
    @(Get-MarkdownContent -Path $planPath)
}
else {
    @()
}

$qualityContractPath = Join-Path $resolvedSpecDirectory 'contracts\quality-governance-artifacts.md'
$qualityGateRows = @(Get-MarkdownSectionTable -Lines $planLines -Heading 'Required Quality Gates')
$hasQualityEvidenceContract = $qualityGateRows.Count -gt 0 -or (Test-Path -LiteralPath $qualityContractPath -PathType Leaf)
$phaseTwoQualityArtifactsRequired = Test-PhaseTwoQualityArtifactScaffold -PlanLines $planLines -QualityContractPath $qualityContractPath
if ($hasQualityEvidenceContract -or $phaseTwoQualityArtifactsRequired) {
    $qualityDirectory = Join-Path $iterationDirectory 'quality'
    $featureId = Split-Path -Leaf $resolvedSpecDirectory
    $featureRef = Convert-ToRepoRelativePath -BasePath $projectRoot -TargetPath (Join-Path $resolvedSpecDirectory 'spec.md')
    $iterationRef = Convert-ToRepoRelativePath -BasePath $projectRoot -TargetPath $iterationDirectory
    $hardeningGatePath = Join-Path $qualityDirectory 'hardening-gate.md'
    $lensesDirectory = Join-Path $qualityDirectory 'lenses'
    $trapReapplicationPath = Join-Path $qualityDirectory 'trap-reapplication.md'
    $qualityEvidencePath = Join-Path $qualityDirectory 'quality-evidence.md'
    $mechanicalFindingsPath = Join-Path $qualityDirectory 'mechanical-findings.json'
    $qualityEvidenceRef = Convert-ToRepoRelativePath -BasePath $projectRoot -TargetPath $qualityEvidencePath
    $mechanicalFindingsRef = Convert-ToRepoRelativePath -BasePath $projectRoot -TargetPath $mechanicalFindingsPath

    Ensure-Directory -Path $qualityDirectory -Actions $actions
    if ($phaseTwoQualityArtifactsRequired) {
        Ensure-Directory -Path $lensesDirectory -Actions $actions
        Write-MissingFile -TargetPath $hardeningGatePath -Content (Get-HardeningGateContent `
                -FeatureRef $featureRef `
                -IterationRef $iterationRef `
                -IterationNumber $IterationNumber `
                -ReviewedAt $timestamp) -Actions $actions
        Write-MissingFile -TargetPath $trapReapplicationPath -Content (Get-TrapReapplicationContent `
                -IterationNumber $IterationNumber `
                -RecordedAt $timestamp) -Actions $actions
    }

    if ($hasQualityEvidenceContract) {
        Write-MissingFile -TargetPath $qualityEvidencePath -Content (Get-QualityEvidenceContent `
                -PlanPath $planPath `
                -FeatureId $featureId `
                -IterationNumber $IterationNumber `
                -FindingsRef $mechanicalFindingsRef `
                -EvidenceRef $qualityEvidenceRef `
                -ReviewedAt $timestamp) -Actions $actions
        Write-MissingFile -TargetPath $mechanicalFindingsPath -Content (Get-MechanicalFindingsScaffoldJson `
                -FeatureRef $featureRef `
                -IterationRef $iterationRef `
                -GeneratedAt $timestamp) -Actions $actions
    }
}

if ($PassThru) {
    $actions
    return
}

$actions | Select-Object Action, Path | Format-Table -AutoSize
Write-Host ("Iteration artifact scaffold {0} for {1}" -f ($(if ($DryRun) { 'previewed' } else { 'completed' }), $iterationDirectory)) -ForegroundColor Green
exit 0
