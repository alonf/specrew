[CmdletBinding()]
param(
    [string]$ProjectPath = (Get-Location).Path,
    [string[]]$IterationPath,
    [switch]$AsJson,
    [switch]$PassThru,
    [switch]$WriteReport,
    [string]$ReportPath
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

$allowedStatuses = @('planning', 'executing', 'reviewing', 'retro', 'complete', 'abandoned')

function Resolve-IterationTarget {
    param(
        [string]$ResolvedProjectPath,
        [string[]]$ExplicitIterationPaths
    )

    if ($ExplicitIterationPaths -and $ExplicitIterationPaths.Count -gt 0) {
        return @($ExplicitIterationPaths | ForEach-Object { (Resolve-Path -Path $_).Path })
    }

    $specsPath = Join-Path -Path $ResolvedProjectPath -ChildPath 'specs'
    if (-not (Test-Path -Path $specsPath -PathType Container)) {
        throw "Specs directory not found: $specsPath"
    }

    return @(
        Get-ChildItem -Path $specsPath -Directory -Recurse |
            Where-Object { $_.FullName -match '[\\/]iterations[\\/][^\\/]+$' } |
            Where-Object { Test-Path -Path (Join-Path -Path $_.FullName -ChildPath 'plan.md') } |
            Select-Object -ExpandProperty FullName
    )
}

function Get-MarkdownContent {
    param([string]$Path)

    return @(Get-Content -LiteralPath $Path -Encoding UTF8)
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

    return $Value.Trim().ToLowerInvariant()
}

function Get-ExpectedArtifactsForStatus {
    param([string]$Status)

    switch ($Status) {
        'planning' { return @('plan.md') }
        'executing' { return @('plan.md', 'state.md', 'drift-log.md') }
        'reviewing' { return @('plan.md', 'state.md', 'drift-log.md', 'review.md') }
        'retro' { return @('plan.md', 'state.md', 'drift-log.md', 'review.md', 'retro.md') }
        'complete' { return @('plan.md', 'state.md', 'drift-log.md', 'review.md', 'retro.md') }
        'abandoned' { return @('plan.md', 'state.md') }
        default { return @('plan.md') }
    }
}

function Resolve-ReportPath {
    param(
        [string]$ResolvedProjectPath,
        [AllowNull()][string]$RequestedPath
    )

    if ([string]::IsNullOrWhiteSpace($RequestedPath)) {
        return [System.IO.Path]::GetFullPath((Join-Path -Path $ResolvedProjectPath -ChildPath 'test-results/process-quality-report.md'))
    }

    if ([System.IO.Path]::IsPathRooted($RequestedPath)) {
        return [System.IO.Path]::GetFullPath($RequestedPath)
    }

    return [System.IO.Path]::GetFullPath((Join-Path -Path $ResolvedProjectPath -ChildPath $RequestedPath))
}

function Test-PhaseAdherence {
    param(
        [string]$Status,
        [hashtable]$Artifacts
    )

    $issues = New-Object System.Collections.Generic.List[string]

    if ($Status -notin $allowedStatuses) {
        $issues.Add("Invalid iteration status '$Status' in plan.md")
        return $issues
    }

    $expectedArtifacts = @(Get-ExpectedArtifactsForStatus -Status $Status)
    foreach ($artifact in $expectedArtifacts) {
        if (-not $Artifacts[$artifact]) {
            $issues.Add("Status '$Status' requires $artifact")
        }
    }

    if ($Artifacts['review.md'] -and $Status -in @('planning', 'executing')) {
        $issues.Add("Status '$Status' is stale because review.md already exists")
    }

    if ($Artifacts['retro.md'] -and $Status -notin @('retro', 'complete')) {
        $issues.Add("Status '$Status' is stale because retro.md already exists")
    }

    if ($Status -eq 'complete' -and -not $Artifacts['review.md']) {
        $issues.Add("Complete iterations require review.md")
    }

    if ($Status -eq 'complete' -and -not $Artifacts['retro.md']) {
        $issues.Add("Complete iterations require retro.md")
    }

    return $issues
}

function Get-IterationScore {
    param([string]$IterationDirectory)

    $planPath = Join-Path -Path $IterationDirectory -ChildPath 'plan.md'
    $planLines = @(Get-MarkdownContent -Path $planPath)
    $status = Get-NormalizedKeyword (Get-MarkdownMetadataValue -Lines $planLines -Label 'Status')
    $expectedArtifacts = @(Get-ExpectedArtifactsForStatus -Status $status)

    $artifacts = @{
        'plan.md'      = $true
        'state.md'     = Test-Path -LiteralPath (Join-Path -Path $IterationDirectory -ChildPath 'state.md') -PathType Leaf
        'drift-log.md' = Test-Path -LiteralPath (Join-Path -Path $IterationDirectory -ChildPath 'drift-log.md') -PathType Leaf
        'review.md'    = Test-Path -LiteralPath (Join-Path -Path $IterationDirectory -ChildPath 'review.md') -PathType Leaf
        'retro.md'     = Test-Path -LiteralPath (Join-Path -Path $IterationDirectory -ChildPath 'retro.md') -PathType Leaf
    }

    $artifactChecks = @(
        foreach ($artifactName in @('plan.md', 'state.md', 'drift-log.md', 'review.md', 'retro.md')) {
            $required = $expectedArtifacts -contains $artifactName
            [pscustomobject]@{
                artifact = $artifactName
                required = $required
                present  = [bool]$artifacts[$artifactName]
                result   = if (-not $required -or $artifacts[$artifactName]) { 'PASS' } else { 'FAIL' }
            }
        }
    )

    $phaseIssues = @(Test-PhaseAdherence -Status $status -Artifacts $artifacts)
    $missingArtifacts = @($artifactChecks | Where-Object { $_.required -and -not $_.present } | ForEach-Object { $_.artifact })

    return [pscustomobject]@{
        iteration_id        = Split-Path -Leaf $IterationDirectory
        iteration_path      = $IterationDirectory
        status              = $status
        artifact_adherence  = [pscustomobject]@{
            status  = if ($missingArtifacts.Count -eq 0) { 'PASS' } else { 'FAIL' }
            checks  = $artifactChecks
            missing = $missingArtifacts
        }
        phase_adherence     = [pscustomobject]@{
            status             = if ($phaseIssues.Count -eq 0) { 'PASS' } else { 'FAIL' }
            expected_artifacts = $expectedArtifacts
            issues             = $phaseIssues
        }
    }
}

function Get-ProcessReportMarkdown {
    param(
        [pscustomobject]$Result,
        [string]$ResolvedProjectPath
    )

    $completeStatuses = @('complete', 'retro')
    $completedIterations = @($Result.iterations | Where-Object { $_.status -in $completeStatuses }).Count
    $artifactFailed = if ($Result.criteria.artifact_adherence.failed_iterations.Count -gt 0) {
        $Result.criteria.artifact_adherence.failed_iterations -join ', '
    }
    else {
        'none'
    }
    $phaseFailed = if ($Result.criteria.phase_adherence.failed_iterations.Count -gt 0) {
        $Result.criteria.phase_adherence.failed_iterations -join ', '
    }
    else {
        'none'
    }

    $lines = New-Object System.Collections.Generic.List[string]
    $lines.Add('# Evaluation Report')
    $lines.Add('')
    $lines.Add('**Schema**: v1')
    $lines.Add(('**Evaluated**: {0}' -f $Result.evaluated_at.Substring(0, 10)))
    $lines.Add(('**Reference Spec**: Process slice over iteration lifecycle artifacts under `{0}`' -f (Join-Path -Path $ResolvedProjectPath -ChildPath 'specs')))
    $lines.Add(('**Iterations Completed**: {0}' -f $completedIterations))
    $lines.Add(('**Iterations Evaluated**: {0}' -f $Result.summary.iterations_evaluated))
    $lines.Add('')
    $lines.Add(('## Overall: {0}' -f $Result.overall))
    $lines.Add('')
    $lines.Add('## Process Quality')
    $lines.Add('')
    $lines.Add('| Criterion | Score | Details |')
    $lines.Add('| --------- | ----- | ------- |')
    $lines.Add(('| Required artifact adherence | {0}/{1} checks | Failed iterations: {2} |' -f $Result.summary.artifact_checks_passed, $Result.summary.artifact_checks_total, $artifactFailed))
    $lines.Add(('| Phase adherence | {0}/{1} iterations | Failed iterations: {2} |' -f $Result.summary.phase_checks_passed, $Result.summary.phase_checks_total, $phaseFailed))
    $lines.Add(('| Process score | {0}% | Combined artifact + phase adherence for the Iteration 2 process slice. |' -f $Result.summary.process_score_percent))
    $lines.Add('| Capacity accuracy | Deferred | Full estimate-vs-actual scoring remains part of the later evaluation harness expansion. |')
    $lines.Add('| Drift detection verification | Deferred | This standalone scorer checks lifecycle artifacts; harness-driven drift verification remains staged follow-on work. |')
    $lines.Add('')
    $lines.Add('## Outcome Quality')
    $lines.Add('')
    $lines.Add('| Criterion | Score | Details |')
    $lines.Add('| --------- | ----- | ------- |')
    $lines.Add('| Outcome scorer | Deferred to Iteration 3 | Requirement coverage, acceptance pass rate, and artifact consistency land with the full harness. |')
    $lines.Add('')
    $lines.Add('## Per-Iteration Breakdown')
    $lines.Add('')

    foreach ($iteration in $Result.iterations) {
        $missingArtifacts = if ($iteration.artifact_adherence.missing.Count -gt 0) {
            $iteration.artifact_adherence.missing -join ', '
        }
        else {
            'none'
        }
        $phaseIssues = if ($iteration.phase_adherence.issues.Count -gt 0) {
            $iteration.phase_adherence.issues -join '; '
        }
        else {
            'none'
        }

        $lines.Add(('### Iteration {0}' -f $iteration.iteration_id))
        $lines.Add(('- Status: `{0}`' -f $iteration.status))
        $lines.Add(('- Artifact adherence: **{0}** (missing: {1})' -f $iteration.artifact_adherence.status, $missingArtifacts))
        $lines.Add(('- Phase adherence: **{0}** (issues: {1})' -f $iteration.phase_adherence.status, $phaseIssues))
        $lines.Add(('- Expected artifacts: {0}' -f ($iteration.phase_adherence.expected_artifacts -join ', ')))
        $lines.Add('')
    }

    return ($lines -join [Environment]::NewLine) + [Environment]::NewLine
}

$resolvedProjectPath = (Resolve-Path -Path $ProjectPath).Path
$targets = @(Resolve-IterationTarget -ResolvedProjectPath $resolvedProjectPath -ExplicitIterationPaths $IterationPath)
$iterations = @($targets | Sort-Object | ForEach-Object { Get-IterationScore -IterationDirectory $_ })

$artifactPassed = (@($iterations | ForEach-Object { $_.artifact_adherence.checks | Where-Object { $_.required -and $_.present } })).Count
$artifactTotal = (@($iterations | ForEach-Object { $_.artifact_adherence.checks | Where-Object { $_.required } })).Count
$phasePassed = (@($iterations | Where-Object { $_.phase_adherence.status -eq 'PASS' })).Count
$phaseTotal = $iterations.Count
$totalChecks = $artifactTotal + $phaseTotal
$passedChecks = $artifactPassed + $phasePassed
$scorePercent = if ($totalChecks -eq 0) { 0 } else { [math]::Round((($passedChecks / $totalChecks) * 100), 2) }

$result = [pscustomobject]@{
    evaluated_at = (Get-Date).ToUniversalTime().ToString('yyyy-MM-ddTHH:mm:ssZ')
    project_path = $resolvedProjectPath
    overall      = if (($iterations | Where-Object { $_.artifact_adherence.status -ne 'PASS' -or $_.phase_adherence.status -ne 'PASS' } | Select-Object -First 1)) { 'FAIL' } else { 'PASS' }
    summary      = [pscustomobject]@{
        iterations_evaluated  = $iterations.Count
        artifact_checks_passed = $artifactPassed
        artifact_checks_total  = $artifactTotal
        phase_checks_passed    = $phasePassed
        phase_checks_total     = $phaseTotal
        process_score_percent  = $scorePercent
    }
    criteria     = [pscustomobject]@{
        artifact_adherence = [pscustomobject]@{
            status            = if (($iterations | Where-Object { $_.artifact_adherence.status -ne 'PASS' } | Select-Object -First 1)) { 'FAIL' } else { 'PASS' }
            failed_iterations = @($iterations | Where-Object { $_.artifact_adherence.status -ne 'PASS' } | ForEach-Object { $_.iteration_id })
        }
        phase_adherence = [pscustomobject]@{
            status            = if (($iterations | Where-Object { $_.phase_adherence.status -ne 'PASS' } | Select-Object -First 1)) { 'FAIL' } else { 'PASS' }
            failed_iterations = @($iterations | Where-Object { $_.phase_adherence.status -ne 'PASS' } | ForEach-Object { $_.iteration_id })
        }
    }
    iterations   = $iterations
}

$resolvedReportPath = $null
if ($WriteReport -or -not [string]::IsNullOrWhiteSpace($ReportPath)) {
    $resolvedReportPath = Resolve-ReportPath -ResolvedProjectPath $resolvedProjectPath -RequestedPath $ReportPath
    $reportDirectory = Split-Path -Parent $resolvedReportPath
    if (-not (Test-Path -LiteralPath $reportDirectory)) {
        New-Item -Path $reportDirectory -ItemType Directory -Force | Out-Null
    }

    $reportContent = Get-ProcessReportMarkdown -Result $result -ResolvedProjectPath $resolvedProjectPath
    [System.IO.File]::WriteAllText($resolvedReportPath, $reportContent, [System.Text.UTF8Encoding]::new($false))

    $result = [pscustomobject]@{
        evaluated_at = $result.evaluated_at
        project_path = $result.project_path
        report_path  = $resolvedReportPath
        overall      = $result.overall
        summary      = $result.summary
        criteria     = $result.criteria
        iterations   = $result.iterations
    }
}

if ($PassThru) {
    $result
    return
}

if ($AsJson) {
    $result | ConvertTo-Json -Depth 8
}
else {
    $result | ConvertTo-Json -Depth 8
}
