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

function Get-MechanicalFindingsSchemaJson {
    # JSON Schema for `iterations/<NNN>/quality/mechanical-findings.json` as written by
    # `run-mechanical-checks.ps1`. Lives at the FEATURE level (`<feature>/contracts/
    # mechanical-findings.schema.json`) because it's a stable contract across iterations.
    #
    # Empirical motivation: tip-calc-v2 dogfooding 2026-05-23 caught
    # `run-mechanical-checks.ps1` throwing "Mechanical findings schema not found at
    # '<feature>/contracts/mechanical-findings.schema.json'" because the scaffold
    # never created it. Claude hand-authored it to match the runner's documented v1
    # output (logged as drift D-001). Now the scaffold writes it proactively so the
    # runner works on first invocation.
    return @'
{
  "$schema": "http://json-schema.org/draft-07/schema#",
  "title": "Specrew Mechanical Findings (v1)",
  "description": "Schema for iterations/<NNN>/quality/mechanical-findings.json emitted by run-mechanical-checks.ps1 (dead-field, anti-pattern, test-integrity lenses).",
  "type": "object",
  "additionalProperties": false,
  "required": [
    "schemaVersion",
    "featureRef",
    "iterationRef",
    "generatedAt",
    "generator",
    "findings"
  ],
  "properties": {
    "schemaVersion": { "type": "string", "enum": ["v1"] },
    "featureRef": { "type": "string" },
    "iterationRef": { "type": "string" },
    "generatedAt": { "type": "string" },
    "generator": {
      "type": "object",
      "additionalProperties": false,
      "required": ["name", "version"],
      "properties": {
        "name": { "type": "string" },
        "version": { "type": "string" }
      }
    },
    "findings": {
      "type": "array",
      "items": {
        "type": "object",
        "additionalProperties": true,
        "required": [
          "findingId",
          "gateId",
          "ruleId",
          "surfaceId",
          "severity",
          "message",
          "remediation",
          "source",
          "requirementRefs",
          "demoted"
        ],
        "properties": {
          "findingId": { "type": "string" },
          "gateId": {
            "type": "string",
            "enum": ["dead-field", "anti-pattern", "test-integrity"]
          },
          "ruleId": { "type": "string" },
          "surfaceId": { "type": "string" },
          "severity": { "type": "string" },
          "message": { "type": "string" },
          "remediation": { "type": "string" },
          "source": {
            "type": "object",
            "additionalProperties": true,
            "required": ["path", "line"],
            "properties": {
              "path": { "type": "string" },
              "line": { "type": "integer" },
              "column": { "type": "integer" }
            }
          },
          "requirementRefs": {
            "type": "array",
            "items": { "type": "string" }
          },
          "demoted": { "type": "boolean" },
          "dispositionRef": { "type": "string" }
        }
      }
    }
  }
}
'@
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
    $null = $lines.Add('<!--')
    $null = $lines.Add('  Concern Review schema (validator-enforced):')
    $null = $lines.Add('  - Status MUST be one of: `addressed` | `not-applicable` | `deferred-with-approval`. The validator')
    $null = $lines.Add('    rejects placeholder values like `tbd`. Pick a real status per concern before implementation.')
    $null = $lines.Add('  - When Status is `addressed`: EvidenceBasis = `planning-time-analysis`, RuntimeEvidenceStatus =')
    $null = $lines.Add('    `pending-post-implementation`, ExpectedControls = concrete controls you will enforce.')
    $null = $lines.Add('  - When Status is `not-applicable`: EvidenceBasis = `not-applicable`, RuntimeEvidenceStatus =')
    $null = $lines.Add('    `not-needed`, ExpectedControls = `—`. Rationale must explain WHY this concern does not apply.')
    $null = $lines.Add('  - When Status is `deferred-with-approval`: same evidence fields as `addressed`, AND the Approval')
    $null = $lines.Add('    column must reference an approval record (decision or defer) with a recorded human approval.')
    $null = $lines.Add('  - Overall Verdict is computed: `ready` when every concern is addressed/not-applicable/deferred-')
    $null = $lines.Add('    with-approval; `blocked` otherwise. Update the metadata above when you change the table.')
    $null = $lines.Add('-->')
    $null = $lines.Add('')
    $null = $lines.Add('## Concern Review')
    $null = $lines.Add('')
    $null = $lines.Add('| Concern | Category | Status | Evidence Basis | Runtime Evidence Status | Expected Controls | Blocking | Rationale | Approval |')
    $null = $lines.Add('| --- | --- | --- | --- | --- | --- | --- | --- | --- |')
    $null = $lines.Add('| `security-surface` | `security` | `addressed` | `planning-time-analysis` | `pending-post-implementation` | `<list concrete controls: input validation, allowlists, no eval/innerHTML on user data, no persistence APIs unless required, etc.>` | `true` | `<describe the trust boundary, privilege model, and sensitive flows in this iteration>` | `—` |')
    $null = $lines.Add('| `error-handling-expectations` | `robustness` | `addressed` | `planning-time-analysis` | `pending-post-implementation` | `<list failure modes and the single transition path that handles them, plus positive + negative test coverage you will assert>` | `true` | `<describe expected failure semantics, incomplete-state handling, and recovery preservation rules>` | `—` |')
    $null = $lines.Add('| `retry-idempotency-requirements` | `resilience` | `not-applicable` | `not-applicable` | `not-needed` | `—` | `false` | `<flip to `addressed` and fill in if this iteration has retries, idempotency keys, transactional state, or shared resources. Otherwise record the rationale for why those primitives have no surface here.>` | `—` |')
    $null = $lines.Add('| `test-integrity-targets` | `verification` | `addressed` | `planning-time-analysis` | `pending-post-implementation` | `<list the FR → named-test mapping, the negative-path requirements, and which evidence artifacts will record empirical results>` | `true` | `<describe coverage strategy: positive + negative per FR; smoke-only is disallowed for failure-mode FRs>` | `—` |')
    $null = $lines.Add('| `operational-resilience-concerns` | `operability` | `not-applicable` | `not-applicable` | `not-needed` | `—` | `false` | `<flip to `addressed` and fill in if this iteration ships server, SLO, telemetry pipeline, oncall surface, or operational dependencies. Otherwise record the rationale for why those primitives have no surface here.>` | `—` |')
    $null = $lines.Add('')
    $null = $lines.Add('## Lens Activation (Planning Baseline)')
    $null = $lines.Add('')
    $null = $lines.Add('| Lens Ref | Activation | Planned Evidence Path |')
    $null = $lines.Add('| --- | --- | --- |')
    $null = $lines.Add(('| `security-baseline@v1.0.0` | required | `' + $IterationRef + '/quality/lenses/security-baseline.md` |'))
    $null = $lines.Add(('| `robustness-baseline@v1.0.0` | required | `' + $IterationRef + '/quality/lenses/robustness-baseline.md` |'))
    $null = $lines.Add(('| `test-integrity@v1.0.0` | required | `' + $IterationRef + '/quality/lenses/test-integrity.md` |'))
    $null = $lines.Add('')
    $null = $lines.Add('## Notes')
    $null = $lines.Add('')
    $null = $lines.Add('- Replace every `<placeholder>` and every angle-bracketed instruction with iteration-specific content before crossing the `before-implement` boundary.')
    $null = $lines.Add('- After every row in the table is filled in with a canonical Status, flip the metadata `Overall Verdict` to `ready` (if every concern is `addressed` / `not-applicable` / `deferred-with-approval`) or keep `blocked`.')
    $null = $lines.Add('- Runtime evidence (lens execution, test counts, mechanical-findings results) is collected after implementation lands; the gate is a PLANNING-time artifact and that deferral is intentional.')
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
    $gitExit = $LASTEXITCODE
    # Reset $LASTEXITCODE so the caller doesn't inherit our git exit code. In greenfield-new projects
    # `git rev-parse HEAD` returns 128 (no commits yet); without this reset the surrounding script
    # exits 128 even though we successfully fell back to the default baseline ref.
    $global:LASTEXITCODE = 0
    if ($gitExit -eq 0 -and $headRef.Count -gt 0 -and -not [string]::IsNullOrWhiteSpace($headRef[0])) {
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

<!--
  Markdown authoring note (Specrew lifecycle convention):

  When you add new drift events to this file, watch for MD032 (blanks-around-lists).
  A sentence ending with a colon, immediately followed by a bullet list, is the most
  common violation. Always put a BLANK LINE between the colon line and the list:

      BAD:                              GOOD:
      Resolution steps:                 Resolution steps:
      - Step one                        <— blank line here
      - Step two                        - Step one
                                        - Step two

  The F-033 pre-boundary markdownlint gate runs `markdownlint-cli --fix` on .md
  changes before every boundary-sync write, so most violations auto-fix — but the
  blank line you write in the first place avoids the cleanup churn.
-->

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

# F-040 dogfooding fix (tip-calc-v2 + codex-test, 2026-05-24): unconditionally write the
# feature-level contracts/mechanical-findings.schema.json so run-mechanical-checks.ps1
# works on first invocation. Previously Claude had to hand-author this on encountering
# the runner's "Mechanical findings schema not found" error (logged as drift D-001).
$featureContractsDirectory = Join-Path $resolvedSpecDirectory 'contracts'
Ensure-Directory -Path $featureContractsDirectory -Actions $actions
$mechanicalSchemaPath = Join-Path $featureContractsDirectory 'mechanical-findings.schema.json'
Write-MissingFile -TargetPath $mechanicalSchemaPath -Content (Get-MechanicalFindingsSchemaJson) -Actions $actions

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
