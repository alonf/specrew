[CmdletBinding()]
param(
    [string]$ProjectPath = (Get-Location).Path,
    [string[]]$IterationPath
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

$sharedGovernancePath = Join-Path $PSScriptRoot 'shared-governance.ps1'
if (-not (Test-Path -LiteralPath $sharedGovernancePath -PathType Leaf)) {
    throw "Missing shared governance helper '$sharedGovernancePath'."
}
. $sharedGovernancePath

$sharedGovernancePath = Join-Path $PSScriptRoot 'shared-governance.ps1'
if (-not (Test-Path -LiteralPath $sharedGovernancePath -PathType Leaf)) {
    throw "Missing shared governance helper '$sharedGovernancePath'."
}
. $sharedGovernancePath

$allowedIterationStatuses = @('planning', 'executing', 'reviewing', 'retro', 'complete', 'abandoned')
$allowedTaskStatuses = @('planned', 'in-progress', 'done', 'needs-rework', 'deferred', 'blocked')
$terminalTaskStatuses = @('done', 'needs-rework', 'deferred', 'blocked')
$allowedReviewTaskVerdicts = @('pass', 'needs-work', 'blocked')
$allowedQualityGateStatuses = @('planned', 'passed', 'failed', 'excepted', 'not-applicable')

function Resolve-IterationTarget {
    param(
        [string]$ResolvedProjectPath,
        [string[]]$ExplicitIterationPaths
    )

    if ($ExplicitIterationPaths -and $ExplicitIterationPaths.Count -gt 0) {
        return @($ExplicitIterationPaths | ForEach-Object { (Resolve-Path -Path (Resolve-ProjectPath -Path $_)).Path })
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

    return @($targets)
}

function Get-MarkdownContent {
    param([string]$Path)

    return @(Get-Content -Path $Path -Encoding UTF8)
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

function Get-IterationOrdinal {
    param([AllowNull()][string]$Value)

    if ([string]::IsNullOrWhiteSpace($Value)) {
        return $null
    }

    $candidate = [System.IO.Path]::GetFileName($Value.Trim().TrimEnd('\', '/'))
    if ($candidate -match '^(?<ordinal>\d+)$') {
        return [int]$Matches['ordinal']
    }

    return $null
}

function Test-IterationMeetsCloseoutCutoff {
    param(
        [string]$IterationDirectory,
        [AllowNull()][string]$RequiredSinceIteration
    )

    if (Test-IsNullish $RequiredSinceIteration) {
        return $true
    }

    $cutoffOrdinal = Get-IterationOrdinal -Value $RequiredSinceIteration
    if ($null -eq $cutoffOrdinal) {
        return $true
    }

    $iterationOrdinal = Get-IterationOrdinal -Value $IterationDirectory
    if ($null -eq $iterationOrdinal) {
        return $true
    }

    return $iterationOrdinal -ge $cutoffOrdinal
}

function Test-IsNullish {
    param([AllowNull()][string]$Value)

    if ([string]::IsNullOrWhiteSpace($Value)) {
        return $true
    }

    return $Value.Trim() -match '^(?:—|-|none|null|n/a|\(none\)|blank)$'
}

function Test-IsPlaceholderReviewNote {
    param([AllowNull()][string]$Value)

    if (Test-IsNullish $Value) {
        return $false
    }

    return $Value.Trim() -match '^(?:Review delivered output against .+ and adjust verdict if needed\.|Execution reported blocked; confirm blocker status and escalation path\.|Deferred work; confirm the deferral is still acceptable for this iteration\.|Task already marked needs-rework during execution; confirm re-entry scope\.|Populate verdict after reviewing the delivered evidence\.)$'
}

function Normalize-MarkdownCell {
    param([AllowNull()][string]$Value)

    if ($null -eq $Value) {
        return ''
    }

    return $Value.Trim().Trim('`')
}

function Test-ReviewContainsScaffoldReminder {
    param([string[]]$ReviewLines)

    foreach ($line in $ReviewLines) {
        $trimmed = $line.Trim()
        if ($trimmed -eq '- Replace default verdicts with the actual per-task review outcome before closing the review phase.' -or
            $trimmed -eq '- Replace this reminder with either: (a) `No known gaps remain.` or (b) explicit gap entries covering the affected requirement/artifact, whether the gap is fixed now or deferred with approval, and any required spec/plan/tasks updates.') {
            return $true
        }
    }

    return $false
}

function Get-NormalizedReviewTaskVerdict {
    param([AllowNull()][string]$Value)

    if (Test-IsNullish $Value) {
        return $null
    }

    $normalized = $Value.Trim().ToLowerInvariant()
    if ($normalized -match '\bneeds[- ]work\b') {
        return 'needs-work'
    }

    if ($normalized -match '\bblocked\b') {
        return 'blocked'
    }

    if ($normalized -match '\bpass(?:ed)?\b') {
        return 'pass'
    }

    return $normalized
}

function Test-HeadingPresent {
    param(
        [string[]]$Lines,
        [string]$Heading
    )

    $pattern = '^##\s+' + [regex]::Escape($Heading) + '\b'
    return [bool]($Lines | Where-Object { $_ -match $pattern } | Select-Object -First 1)
}

function Get-ActiveGapLedgerLines {
    param([string[]]$ReviewLines)

    $gapLedgerLines = @(Get-MarkdownSectionLines -Lines $ReviewLines -Heading 'Gap Ledger')
    $activeLines = New-Object System.Collections.Generic.List[string]
    foreach ($line in $gapLedgerLines) {
        $trimmed = $line.Trim()
        if ([string]::IsNullOrWhiteSpace($trimmed) -or $trimmed -eq 'No known gaps remain.' -or $trimmed -eq '---') {
            continue
        }

        $null = $activeLines.Add($trimmed)
    }

    return $activeLines.ToArray()
}

function Test-NoGapClosurePolicy {
    param(
        [string[]]$ReviewLines,
        [string]$ProjectRoot,
        [string]$IterationDirectory,
        [string]$OverallVerdict,
        [string]$IterationStatus,
        [System.Collections.Generic.List[string]]$Errors
    )

    $activeGapLines = @(Get-ActiveGapLedgerLines -ReviewLines $ReviewLines)
    if ($activeGapLines.Count -eq 0) {
        return
    }

    if ($OverallVerdict -ne 'accepted' -and $IterationStatus -notin @('retro', 'complete')) {
        return
    }

    $relativeIteration = ([System.IO.Path]::GetRelativePath($ProjectRoot, $IterationDirectory)) -replace '/', '\'
    $reviewText = $ReviewLines -join "`n"
    $deferEntries = @(
        Get-DecisionsLedgerEntries -ProjectRoot $ProjectRoot |
            Where-Object {
                $_.Type -eq 'defer' -and
                $_.AffectedIteration -eq $relativeIteration -and
                -not (Test-IsNullish $_.ApprovingHuman)
            }
    )

    foreach ($gapLine in $activeGapLines) {
        $normalizedGap = $gapLine.ToLowerInvariant()
        $isDeferred = $normalizedGap -match '\bdefer(?:red)?\b'
        $isFixedNow = $normalizedGap -match '\b(?:fixed[- ]now|resolved[- ]now|repaired[- ]now|fixed this iteration|resolved this iteration)\b'

        if (-not $isDeferred -and -not $isFixedNow) {
            $Errors.Add("review.md Gap Ledger entry must classify the concern as fixed-now or deferred before closure: $gapLine")
            continue
        }

        if (-not $isDeferred) {
            continue
        }

        if ($reviewText -notmatch '\.squad\\decisions\.md') {
            $Errors.Add('Deferred gap entries must link review.md back to .squad\decisions.md')
        }

        if ($deferEntries.Count -eq 0) {
            $Errors.Add("Deferred gap entries require a canonical defer entry with approving human in .squad\\decisions.md for $relativeIteration")
            continue
        }

        $requirementMatch = [regex]::Match($gapLine, '(FR-\d+)')
        if ($requirementMatch.Success) {
            $matchingRequirement = @($deferEntries | Where-Object { [string]$_.AffectedRequirement -eq $requirementMatch.Groups[1].Value })
            if ($matchingRequirement.Count -eq 0) {
                $Errors.Add("Deferred gap for $($requirementMatch.Groups[1].Value) is missing a matching defer entry in .squad\\decisions.md")
            }
        }
    }
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

    return $rows.ToArray()
}

function Get-MarkdownSectionTableAnyLevel {
    param(
        [string[]]$Lines,
        [string]$Heading
    )

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

function Convert-ToRepoMarkdownPath {
    param(
        [Parameter(Mandatory = $true)]
        [string]$ProjectRoot,

        [Parameter(Mandatory = $true)]
        [string]$TargetPath
    )

    return ([System.IO.Path]::GetRelativePath($ProjectRoot, $TargetPath)) -replace '\\', '/'
}

function Resolve-RepoMarkdownArtifactPath {
    param(
        [Parameter(Mandatory = $true)]
        [string]$ProjectRoot,

        [AllowNull()][string]$ArtifactRef
    )

    $normalizedRef = Normalize-MarkdownCell $ArtifactRef
    if (Test-IsNullish $normalizedRef) {
        return $null
    }

    if ($normalizedRef -match '<[^>]+>') {
        return $null
    }

    $candidate = $normalizedRef -replace '/', '\'
    if ([System.IO.Path]::IsPathRooted($candidate)) {
        return [System.IO.Path]::GetFullPath($candidate)
    }

    return [System.IO.Path]::GetFullPath((Join-Path $ProjectRoot $candidate))
}

function Get-ObjectPropertyString {
    param(
        [AllowNull()][object]$InputObject,

        [string[]]$PropertyNames
    )

    if ($null -eq $InputObject) {
        return $null
    }

    foreach ($propertyName in $PropertyNames) {
        $property = $InputObject.PSObject.Properties[$propertyName]
        if ($null -ne $property) {
            return [string]$property.Value
        }
    }

    return $null
}

function Get-Phase2HardeningPlanContext {
    param(
        [AllowEmptyCollection()]
        [AllowEmptyString()]
        [Parameter(Mandatory = $true)]
        [string[]]$PlanLines,

        [Parameter(Mandatory = $true)]
        [string]$ProjectRoot
    )

    $hasPhase2Section = Test-HeadingPresent -Lines $PlanLines -Heading 'Phase 2 Hardening and Specialist Review Planning'
    $sliceScope = Normalize-MarkdownCell (Get-MarkdownMetadataValue -Lines $PlanLines -Label 'Phase 2 Slice Scope')
    $artifactRef = Normalize-MarkdownCell (Get-MarkdownMetadataValue -Lines $PlanLines -Label 'Hardening Gate Artifact')

    if (-not $hasPhase2Section -and (Test-IsNullish $sliceScope) -and (Test-IsNullish $artifactRef)) {
        return $null
    }

    $routingRows = @(Get-MarkdownSectionTableAnyLevel -Lines $PlanLines -Heading 'Routing Policy')
    $requestedReviewClass = if ($routingRows.Count -gt 0) {
        Normalize-MarkdownCell (Get-ObjectPropertyString -InputObject $routingRows[0] -PropertyNames @('Requested Reasoning / Review Class', 'Requested Review Class'))
    }
    else {
        $null
    }

    return [pscustomobject]@{
        HasSection                 = $hasPhase2Section
        SliceScope                 = $sliceScope
        HardeningGateArtifactRef   = $artifactRef
        HardeningGateArtifactPath  = Resolve-RepoMarkdownArtifactPath -ProjectRoot $ProjectRoot -ArtifactRef $artifactRef
        RequestedReviewClass       = $requestedReviewClass
        IsImplicit                 = $false
    }
}

function Get-HardeningExpectedVerdict {
    param(
        [Parameter(Mandatory = $true)]
        [object]$HardeningState
    )

    if ($HardeningState.BlocksImplementation) {
        return 'blocked'
    }

    $hasApprovedDeferral = @(
        $HardeningState.ConcernRows |
            Where-Object { (Normalize-MarkdownCell ([string]$_.Status)).ToLowerInvariant() -eq 'deferred-with-approval' } |
            Select-Object -First 1
    ).Count -gt 0

    if ($hasApprovedDeferral) {
        return 'deferred-with-approval'
    }

    return 'ready'
}

function Test-Phase2HardeningGate {
    param(
        [Parameter(Mandatory = $true)]
        [string]$IterationDirectory,

        [Parameter(Mandatory = $true)]
        [string]$ProjectRoot,

        [AllowEmptyCollection()]
        [AllowEmptyString()]
        [Parameter(Mandatory = $true)]
        [string[]]$PlanLines,

        [Parameter(Mandatory = $true)]
        [string]$IterationStatus,

        [System.Collections.Generic.List[string]]$Errors
    )

    $requiresGateEnforcement = $IterationStatus -in @('executing', 'reviewing', 'retro', 'complete')
    $planContext = Get-Phase2HardeningPlanContext -PlanLines $PlanLines -ProjectRoot $ProjectRoot
    if ($null -eq $planContext) {
        $implicitHardeningGatePath = Join-Path $IterationDirectory 'quality\hardening-gate.md'
        $implicitHardeningGateRef = Convert-ToRepoMarkdownPath -ProjectRoot $ProjectRoot -TargetPath $implicitHardeningGatePath
        $hasImplicitArtifact = Test-Path -LiteralPath $implicitHardeningGatePath -PathType Leaf
        $hasImplicitPlanSignal = @(
            $PlanLines |
                Where-Object { $_ -match '(?i)hardening-gate\.md|hardening gate' } |
                Select-Object -First 1
        ).Count -gt 0

        if (-not $hasImplicitArtifact -and -not $hasImplicitPlanSignal) {
            return
        }

        if (-not $requiresGateEnforcement -and -not $hasImplicitArtifact) {
            return
        }

        $planContext = [pscustomobject]@{
            HasSection                = $false
            SliceScope                = $null
            HardeningGateArtifactRef  = $implicitHardeningGateRef
            HardeningGateArtifactPath = $implicitHardeningGatePath
            RequestedReviewClass      = $null
            IsImplicit                = $true
        }
    }

    if (-not $planContext.IsImplicit -and -not $planContext.HasSection) {
        $Errors.Add('plan.md must keep the Phase 2 Hardening and Specialist Review Planning section when hardening-gate metadata is present')
        return
    }

    if (-not $planContext.IsImplicit) {
        foreach ($requiredField in @(
                @{ Label = 'Phase 2 Slice Scope'; Value = $planContext.SliceScope },
                @{ Label = 'Hardening Gate Artifact'; Value = $planContext.HardeningGateArtifactRef }
            )) {
            if (Test-IsNullish ([string]$requiredField.Value)) {
                $Errors.Add(("plan.md is missing required Phase 2 hardening metadata: {0}" -f $requiredField.Label))
            }
        }
    }

    if (-not $requiresGateEnforcement -and [string]::IsNullOrWhiteSpace($planContext.HardeningGateArtifactPath)) {
        return
    }

    if ([string]::IsNullOrWhiteSpace($planContext.HardeningGateArtifactPath)) {
        $Errors.Add('plan.md Hardening Gate Artifact must resolve to a concrete repo-relative path before implementation can proceed')
        return
    }

    if (-not (Test-Path -LiteralPath $planContext.HardeningGateArtifactPath -PathType Leaf)) {
        $Errors.Add(("Missing required hardening artifact: {0}" -f $planContext.HardeningGateArtifactRef))
        return
    }

    $hardeningState = Get-HardeningGateState -Path $planContext.HardeningGateArtifactPath -ProjectRoot $ProjectRoot
    $expectedIterationRef = Convert-ToRepoMarkdownPath -ProjectRoot $ProjectRoot -TargetPath $IterationDirectory
    $expectedSpecPath = Resolve-PlanSpecPath -PlanLines $PlanLines -IterationDirectory $IterationDirectory
    $expectedFeatureRef = if ($null -ne $expectedSpecPath) {
        Convert-ToRepoMarkdownPath -ProjectRoot $ProjectRoot -TargetPath $expectedSpecPath
    }
    else {
        $null
    }

    foreach ($metadataCheck in @(
            @{ Label = 'Schema'; Actual = [string]$hardeningState.Metadata.Schema; Expected = 'v1' },
            @{ Label = 'Gate ID'; Actual = [string]$hardeningState.Metadata.GateId; Expected = 'pre-implementation-hardening' },
            @{ Label = 'Iteration Ref'; Actual = [string]$hardeningState.Metadata.IterationRef; Expected = $expectedIterationRef }
        )) {
        if ((Normalize-MarkdownCell $metadataCheck.Actual) -ne (Normalize-MarkdownCell $metadataCheck.Expected)) {
            $Errors.Add(("hardening-gate.md metadata '{0}' should be '{1}' but found '{2}'" -f $metadataCheck.Label, $metadataCheck.Expected, $metadataCheck.Actual))
        }
    }

    if (-not (Test-IsNullish $expectedFeatureRef) -and (Normalize-MarkdownCell ([string]$hardeningState.Metadata.FeatureRef)) -ne $expectedFeatureRef) {
        $Errors.Add(("hardening-gate.md metadata 'Feature Ref' should be '{0}' but found '{1}'" -f $expectedFeatureRef, $hardeningState.Metadata.FeatureRef))
    }

    if (-not (Test-IsNullish $planContext.RequestedReviewClass) -and
        (Normalize-MarkdownCell ([string]$hardeningState.Metadata.RequestedReviewClass)) -ne $planContext.RequestedReviewClass) {
        $Errors.Add(("hardening-gate.md requested review class '{0}' does not match the Phase 2 routing policy '{1}'" -f $hardeningState.Metadata.RequestedReviewClass, $planContext.RequestedReviewClass))
    }

    $expectedConcernIds = @(
        'security-surface',
        'error-handling-expectations',
        'retry-idempotency-requirements',
        'test-integrity-targets',
        'operational-resilience-concerns'
    )

    # Only enforce the bounded five-concern contract for explicit Phase 2 planning
    if (-not $planContext.IsImplicit) {
        if ($hardeningState.ConcernRows.Count -ne $expectedConcernIds.Count) {
            $Errors.Add(("hardening-gate.md must keep the bounded five-concern contract; found {0} concern rows" -f $hardeningState.ConcernRows.Count))
        }

        foreach ($concernId in $expectedConcernIds) {
            $matches = @($hardeningState.ConcernRows | Where-Object { [string]$_.Concern -eq $concernId })
            if ($matches.Count -ne 1) {
                $Errors.Add(("hardening-gate.md must contain exactly one '{0}' concern row" -f $concernId))
            }
        }
    }

    $concernEvaluations = @()
    foreach ($concern in @($hardeningState.ConcernRows)) {
        $evaluation = Get-HardeningConcernEvaluation -Concern $concern -ProjectRoot $ProjectRoot
        $concernEvaluations += $evaluation

        foreach ($issue in @($evaluation.Issues)) {
            # Skip "before implementation can proceed" errors for iterations past executing status
            if ($IterationStatus -ne 'executing' -and $issue -match 'before implementation can proceed') {
                continue
            }
            $Errors.Add(("hardening-gate.md concern '{0}' {1}" -f $concern.Concern, $issue))
        }
    }

    $expectedVerdict = Get-HardeningExpectedVerdict -HardeningState $hardeningState
    $actualVerdict = (Normalize-MarkdownCell ([string]$hardeningState.Metadata.OverallVerdict)).ToLowerInvariant()
    if ($actualVerdict -ne $expectedVerdict) {
        $Errors.Add(("hardening-gate.md overall verdict should be '{0}' based on the concern rows but found '{1}'" -f $expectedVerdict, $hardeningState.Metadata.OverallVerdict))
    }

    switch ($expectedVerdict) {
        'blocked' {
            if (-not (Test-IsNullish ([string]$hardeningState.Metadata.ApprovalRef))) {
                $Errors.Add('hardening-gate.md must not publish a gate-level Approval Ref while the overall verdict remains blocked')
            }

            # Only block validation during executing status (before implementation completes)
            # For retro/complete, the gate records historical state but doesn't block validation
            if ($IterationStatus -eq 'executing') {
                $blockingConcernIds = @($hardeningState.BlockingConcerns | ForEach-Object { [string]$_.Concern })
                $Errors.Add(("hardening-gate.md still blocks implementation via unresolved concern(s): {0}" -f ($blockingConcernIds -join ', ')))
            }
        }
        'deferred-with-approval' {
            if (Test-IsNullish ([string]$hardeningState.Metadata.ApprovalRef)) {
                $Errors.Add('hardening-gate.md must record a gate-level Approval Ref when the verdict is deferred-with-approval')
            }
            elseif ($null -eq $hardeningState.ApprovalRecord -or -not $hardeningState.ApprovalRecord.HasHumanApproval) {
                $Errors.Add(("hardening-gate.md approval reference '{0}' is missing explicit human approval evidence in .squad\decisions.md" -f $hardeningState.Metadata.ApprovalRef))
            }
        }
        'ready' {
            if (-not (Test-IsNullish ([string]$hardeningState.Metadata.ApprovalRef))) {
                $Errors.Add('hardening-gate.md must not retain a gate-level Approval Ref after all blocking concerns are fully ready')
            }
        }
    }

    $explicitEvidenceRows = @(
        $concernEvaluations |
            Where-Object { $_.HasExplicitEvidenceFields }
    )
    if ($IterationStatus -eq 'complete' -and $explicitEvidenceRows.Count -gt 0) {
        $closureBlockingConcernIds = @(
            $hardeningState.ConcernRows |
                Where-Object { Test-HardeningConcernBlocksClosure -Concern $_ -ProjectRoot $ProjectRoot } |
                ForEach-Object { [string]$_.Concern }
        )

        if ($closureBlockingConcernIds.Count -gt 0) {
            $Errors.Add(("hardening-gate.md still requires runtime evidence or explicit closure follow-through for concern(s): {0}" -f ($closureBlockingConcernIds -join ', ')))
        }
    }
}

function Get-Phase1RequiredQualityGateRows {
    param([string[]]$PlanLines)

    $phaseScope = Normalize-MarkdownCell (Get-MarkdownMetadataValue -Lines $PlanLines -Label 'Phase Scope')
    if ($phaseScope -ne 'phase-1-first-slice') {
        return @()
    }

    return @(Get-MarkdownSectionTableAnyLevel -Lines $PlanLines -Heading 'Required Quality Gates')
}

function Get-QualityEvidenceRowMap {
    param([string[]]$EvidenceLines)

    $rowsByGate = @{}
    foreach ($row in @(Get-MarkdownSectionTable -Lines $EvidenceLines -Heading 'Gate Matrix')) {
        $gateId = Normalize-MarkdownCell ([string]$row.Gate)
        if ([string]::IsNullOrWhiteSpace($gateId)) {
            continue
        }

        $rowsByGate[$gateId] = [pscustomobject]@{
            Gate           = $gateId
            Requirement    = Normalize-MarkdownCell ([string]$row.Requirement)
            EvidenceSource = Normalize-MarkdownCell ([string]$row.'Evidence Source')
            Status         = Normalize-MarkdownCell ([string]$row.Status).ToLowerInvariant()
            Exception      = Normalize-MarkdownCell ([string]$row.Exception)
        }
    }

    return $rowsByGate
}

function Get-MechanicalFindingsByGate {
    param(
        [string]$MechanicalFindingsPath,
        [System.Collections.Generic.List[string]]$Errors
    )

    $findingsByGate = @{}
    if (-not (Test-Path -LiteralPath $MechanicalFindingsPath -PathType Leaf)) {
        return $findingsByGate
    }

    try {
        $payload = Get-Content -LiteralPath $MechanicalFindingsPath -Encoding UTF8 -Raw | ConvertFrom-Json -Depth 20
    }
    catch {
        $Errors.Add(("mechanical-findings.json is not valid JSON: {0}" -f $_.Exception.Message))
        return $findingsByGate
    }

    if ($null -eq $payload -or $null -eq $payload.findings) {
        return $findingsByGate
    }

    foreach ($finding in @($payload.findings)) {
        $gateId = Normalize-MarkdownCell ([string]$finding.gateId)
        if ([string]::IsNullOrWhiteSpace($gateId)) {
            continue
        }

        if (-not $findingsByGate.ContainsKey($gateId)) {
            $findingsByGate[$gateId] = New-Object System.Collections.Generic.List[object]
        }

        $null = $findingsByGate[$gateId].Add($finding)
    }

    return $findingsByGate
}

function Test-Phase1QualityEvidence {
    param(
        [string]$IterationDirectory,
        [string[]]$PlanLines,
        [System.Collections.Generic.List[string]]$Errors
    )

    $requiredGateRows = @(Get-Phase1RequiredQualityGateRows -PlanLines $PlanLines)
    if ($requiredGateRows.Count -eq 0) {
        return
    }

    $qualityDirectory = Join-Path $IterationDirectory 'quality'
    $qualityEvidencePath = Join-Path $qualityDirectory 'quality-evidence.md'
    $mechanicalFindingsPath = Join-Path $qualityDirectory 'mechanical-findings.json'

    if (-not (Test-Path -LiteralPath $qualityEvidencePath -PathType Leaf)) {
        $Errors.Add('quality-evidence.md is required for Phase 1 required quality gates but is missing')
        return
    }

    $evidenceLines = Get-MarkdownContent -Path $qualityEvidencePath
    $evidenceRowsByGate = Get-QualityEvidenceRowMap -EvidenceLines $evidenceLines
    if ($evidenceRowsByGate.Count -eq 0) {
        $Errors.Add('quality-evidence.md is missing the Gate Matrix table required for Phase 1 quality evidence')
        return
    }

    foreach ($label in @('Profile Ref', 'Findings Ref', 'Reviewed By', 'Reviewed At')) {
        if (Test-IsNullish (Get-MarkdownMetadataValue -Lines $evidenceLines -Label $label)) {
            $Errors.Add(("quality-evidence.md is missing required metadata: {0}" -f $label))
        }
    }

    $mechanicalGateRequired = @($requiredGateRows | Where-Object {
            (Normalize-MarkdownCell ([string]$_.Category)).ToLowerInvariant() -eq 'mechanical'
        }).Count -gt 0
    if ($mechanicalGateRequired -and -not (Test-Path -LiteralPath $mechanicalFindingsPath -PathType Leaf)) {
        $Errors.Add('mechanical-findings.json is required for declared Phase 1 mechanical gates but is missing')
    }

    $mechanicalFindingsByGate = Get-MechanicalFindingsByGate -MechanicalFindingsPath $mechanicalFindingsPath -Errors $Errors

    foreach ($requiredGate in $requiredGateRows) {
        $gateId = Normalize-MarkdownCell ([string]$requiredGate.'Required Quality Gate')
        if ([string]::IsNullOrWhiteSpace($gateId)) {
            continue
        }

        $category = Normalize-MarkdownCell ([string]$requiredGate.Category).ToLowerInvariant()
        if (-not $evidenceRowsByGate.ContainsKey($gateId)) {
            $Errors.Add(("quality-evidence.md is missing evidence for required gate '{0}'" -f $gateId))
            continue
        }

        $evidenceRow = $evidenceRowsByGate[$gateId]
        if ([string]::IsNullOrWhiteSpace($evidenceRow.EvidenceSource)) {
            $Errors.Add(("quality-evidence.md gate '{0}' is missing an Evidence Source entry" -f $gateId))
        }

        if ([string]::IsNullOrWhiteSpace($evidenceRow.Status)) {
            $Errors.Add(("quality-evidence.md gate '{0}' is missing a Status entry" -f $gateId))
        }
        elseif ($evidenceRow.Status -notin $allowedQualityGateStatuses) {
            $Errors.Add(("quality-evidence.md gate '{0}' uses invalid status '{1}'" -f $gateId, $evidenceRow.Status))
        }
        elseif ($evidenceRow.Status -eq 'planned') {
            $Errors.Add(("quality-evidence.md gate '{0}' is still marked planned, so required Phase 1 evidence is incomplete" -f $gateId))
        }

        if ($evidenceRow.Status -eq 'excepted' -and (Test-IsNullish $evidenceRow.Exception)) {
            $Errors.Add(("quality-evidence.md gate '{0}' is excepted but does not cite an approved exception reference" -f $gateId))
        }

        if ($category -ne 'mechanical') {
            continue
        }

        $gateFindings = if ($mechanicalFindingsByGate.ContainsKey($gateId)) {
            @($mechanicalFindingsByGate[$gateId])
        }
        else {
            @()
        }

        $demotedFindings = @($gateFindings | Where-Object { $_.demoted -eq $true })
        if ($demotedFindings.Count -eq 0) {
            continue
        }

        $demotionRefs = New-Object System.Collections.Generic.List[string]
        foreach ($finding in $demotedFindings) {
            $dispositionRef = Normalize-MarkdownCell ([string]$finding.dispositionRef)
            if ([string]::IsNullOrWhiteSpace($dispositionRef)) {
                $Errors.Add(("mechanical finding gate '{0}' includes a demoted rule without dispositionRef visibility" -f $gateId))
                continue
            }

            if ($demotionRefs -notcontains $dispositionRef) {
                $null = $demotionRefs.Add($dispositionRef)
            }
        }

        if ($gateFindings.Count -eq $demotedFindings.Count -and $demotionRefs.Count -gt 0) {
            if ($evidenceRow.Status -ne 'excepted') {
                $Errors.Add(("quality-evidence.md gate '{0}' must remain visible as excepted when all mechanical findings are demoted" -f $gateId))
            }

            foreach ($demotionRef in $demotionRefs) {
                if ($evidenceRow.Exception -notlike ("*{0}*" -f $demotionRef)) {
                    $Errors.Add(("quality-evidence.md gate '{0}' must cite demotion reference '{1}' in the Exception column" -f $gateId, $demotionRef))
                }
            }
        }
    }
}

function Test-IsManifestPath {
    param([string]$Path)

    return $Path -match '(?:^|\\)(package\.json|package-lock\.json|pnpm-lock\.yaml|yarn\.lock|requirements(?:-dev)?\.txt|pyproject\.toml|Cargo\.toml|Cargo\.lock|go\.mod|go\.sum|pom\.xml|packages\.lock\.json|global\.json|.*\.csproj)$'
}

function Test-IsReviewerSourcePath {
    param([string]$Path)

    $extension = [System.IO.Path]::GetExtension([string]$Path).ToLowerInvariant()
    return $extension -in @('.ps1', '.psm1', '.js', '.jsx', '.ts', '.tsx', '.py', '.go', '.cs', '.java', '.rb', '.php', '.rs', '.kt', '.swift', '.c', '.cc', '.cpp', '.h', '.hpp')
}

function Get-MarkdownSectionLines {
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

    $sectionLines = New-Object System.Collections.Generic.List[string]
    for ($index = $startIndex + 1; $index -lt $Lines.Count; $index++) {
        $currentLine = $Lines[$index]
        if ($currentLine -match '^##\s+') {
            break
        }

        $null = $sectionLines.Add($currentLine)
    }

    return $sectionLines.ToArray()
}

function Get-TeamRoleMap {
    param([string]$ResolvedProjectPath)

    $teamPath = Join-Path -Path $ResolvedProjectPath -ChildPath '.squad\team.md'
    if (-not (Test-Path -Path $teamPath -PathType Leaf)) {
        return @{}
    }

    $teamLines = Get-MarkdownContent -Path $teamPath
    $teamRoles = @{}

    # Read from Members section (standard Squad format)
    $members = @(Get-MarkdownSectionTable -Lines $teamLines -Heading 'Members')
    foreach ($member in $members) {
        if ((Test-IsNullish $member.Name) -or (Test-IsNullish $member.Role)) {
            continue
        }
        $teamRoles[$member.Name.Trim()] = $member.Role.Trim()
    }

    # Read from Specrew Baseline Roles section (Specrew-managed baseline format)
    $baselineRoles = @(Get-MarkdownSectionTable -Lines $teamLines -Heading 'Specrew Baseline Roles')
    foreach ($role in $baselineRoles) {
        if ((Test-IsNullish $role.Role)) {
            continue
        }
        # For baseline roles, use the role name as both key and value
        $roleName = $role.Role.Trim()
        $teamRoles[$roleName] = $roleName
    }

    return $teamRoles
}

function Test-BaselineTeamMembers {
    param(
        [hashtable]$TeamRoles,
        [System.Collections.Generic.List[string]]$Errors
    )

    $requiredBaselineRoles = @('Spec Steward', 'Planner', 'Implementer', 'Reviewer', 'Retro Facilitator')
    $missingRoles = New-Object System.Collections.Generic.List[string]

    foreach ($requiredRole in $requiredBaselineRoles) {
        $roleFound = $false
        foreach ($memberName in $TeamRoles.Keys) {
            $actualRole = $TeamRoles[$memberName]
            if ($actualRole -eq $requiredRole) {
                $roleFound = $true
                break
            }
        }

        if (-not $roleFound) {
            $null = $missingRoles.Add($requiredRole)
        }
    }

    if ($missingRoles.Count -gt 0) {
        $Errors.Add("Squad team is missing required baseline role(s): $($missingRoles -join ', ')")
    }
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
    $reviewSatisfiedPattern = '\b(?:accepted|pass(?:ed)?|complete|closed|done|recorded)\b'
    $retroSatisfiedPattern = '\b(?:complete|closed|done|recorded)\b'

    foreach ($artifactName in $ArtifactContents.Keys) {
        $lines = @(Get-LifecycleStatusLine -Lines $ArtifactContents[$artifactName])
        foreach ($line in $lines) {
            $lowerLine = $line.ToLowerInvariant()
            $isNextPhaseLine = $lowerLine -match '^\s*(?:[-*]\s*)?\*\*next phase\*\*:'

            if ($HasReviewArtifact -and (
                    ($isNextPhaseLine -and $lowerLine -match '\breview(?:ing)?\b') -or
                    (($lowerLine -match '\breview(?:ing)?\b') -and ($lowerLine -match $pendingPattern) -and ($lowerLine -notmatch $reviewSatisfiedPattern))
                )) {
                $Errors.Add("$artifactName still describes review as pending even though review.md exists")
            }

            if ($HasRetroArtifact -and (
                    ($isNextPhaseLine -and $lowerLine -match '\b(?:retro|retrospective)\b') -or
                    (($lowerLine -match '\b(?:retro|retrospective)\b') -and ($lowerLine -match $pendingPattern) -and ($lowerLine -notmatch $retroSatisfiedPattern))
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

function Test-PlanMetadataEvidenceDrift {
    param(
        [hashtable]$ArtifactContents,
        [string]$PlanStatus,
        [AllowNull()][string]$PlanCompleted,
        [System.Collections.Generic.List[string]]$Errors
    )

    $actualCompletedDate = [regex]::Match([string]$PlanCompleted, '\b\d{4}-\d{2}-\d{2}\b').Value

    foreach ($artifactName in $ArtifactContents.Keys) {
        foreach ($line in $ArtifactContents[$artifactName]) {
            if ($line -notmatch '\bplan\.md\b') {
                continue
            }

            $lowerLine = $line.ToLowerInvariant()

            $statusMatch = [regex]::Match($line, '\*\*Status\*\*:\s*([^|`.;]+)')
            if ($statusMatch.Success) {
                $claimedStatus = Get-NormalizedKeyword $statusMatch.Groups[1].Value
                if ($claimedStatus -and $claimedStatus -ne $PlanStatus) {
                    $Errors.Add("$artifactName contains stale plan.md status evidence ('$claimedStatus') that contradicts current plan.md status '$PlanStatus'")
                }
            }

            $completedMatch = [regex]::Match($line, '\*\*Completed\*\*:\s*([^|`]+)')
            if ($completedMatch.Success) {
                $claimedCompletedDate = [regex]::Match($completedMatch.Groups[1].Value, '\b\d{4}-\d{2}-\d{2}\b').Value
                if ((Test-IsNullish $PlanCompleted) -and $claimedCompletedDate) {
                    $Errors.Add("$artifactName contains stale plan.md completion evidence ('$claimedCompletedDate') even though plan.md Completed is blank")
                }
                elseif (-not (Test-IsNullish $PlanCompleted) -and $actualCompletedDate -and $claimedCompletedDate -and $claimedCompletedDate -ne $actualCompletedDate) {
                    $Errors.Add("$artifactName contains stale plan.md completion evidence ('$claimedCompletedDate') that contradicts current plan.md Completed '$actualCompletedDate'")
                }
            }

            if ((Test-IsNullish $PlanCompleted) -and
                $lowerLine -match '\bplan\.md\b' -and
                $lowerLine -match '\bcompleted date\b' -and
                $lowerLine -match '\b(?:present|recorded|set|filled|available)\b' -and
                $lowerLine -notmatch '\bblank\b' -and
                $lowerLine -notmatch '\b(?:after|pending|await(?:ing)?)\b.{0,24}\bsign[\s-]?off\b') {
                $Errors.Add("$artifactName still claims plan.md has a recorded Completed date even though plan.md Completed is blank")
            }
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
    foreach ($label in @('Last Completed Task', 'Tasks Remaining', 'In Progress', 'Baseline Ref', 'Updated')) {
        $value = Get-MarkdownMetadataValue -Lines $stateLines -Label $label
        if ($null -eq $value) {
            $Errors.Add("state.md is missing required metadata: $label")
        }
    }
}

function Test-ReviewArtifact {
    param(
        [string]$ReviewPath,
        [string]$ProjectRoot,
        [string]$IterationDirectory,
        [string]$IterationStatus,
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

    $taskVerdicts = @(Get-MarkdownSectionTable -Lines $reviewLines -Heading 'Task Verdicts')
    if ($taskVerdicts.Count -eq 0) {
        $Errors.Add('review.md must contain a populated Task Verdicts table')
        return
    }

    if (-not (Test-HeadingPresent -Lines $reviewLines -Heading 'Gap Ledger')) {
        $Errors.Add('review.md must contain a Gap Ledger section for no-gap closure tracking')
    }

    if (Test-ReviewContainsScaffoldReminder -ReviewLines $reviewLines) {
        $Errors.Add('review.md still contains scaffold reminder text and is not yet a completed review artifact')
    }

    $reviewedTaskIds = @{}
    $nonPassingVerdictTaskIds = New-Object System.Collections.Generic.List[string]
    foreach ($row in $taskVerdicts) {
        $taskId = $row.Task
        if (Test-IsNullish $taskId) {
            $Errors.Add('review.md contains a verdict row without a task identifier')
            continue
        }

        $reviewedTaskIds[$taskId] = $true
        $normalizedVerdict = Get-NormalizedReviewTaskVerdict -Value ([string]$row.Verdict)
        if ($null -eq $normalizedVerdict) {
            $Errors.Add("review.md is missing a verdict for task '$taskId'")
        }
        elseif ($normalizedVerdict -notin $allowedReviewTaskVerdicts) {
            $Errors.Add("review.md contains invalid verdict '$($row.Verdict)' for task '$taskId' (expected pass | needs-work | blocked)")
        }
        elseif ($normalizedVerdict -ne 'pass') {
            $null = $nonPassingVerdictTaskIds.Add([string]$taskId)
        }

        $notes = if ($null -ne $row.PSObject.Properties['Notes']) { [string]$row.Notes } else { $null }
        if (Test-IsPlaceholderReviewNote -Value $notes) {
            $Errors.Add("review.md still contains scaffold placeholder notes for task '$taskId'")
        }
    }

    foreach ($task in $PlanTasks) {
        if (-not $reviewedTaskIds.ContainsKey($task.Task)) {
            $Errors.Add("review.md is missing a verdict row for plan task '$($task.Task)'")
        }
    }

    if ($overallVerdict -eq 'accepted' -and $nonPassingVerdictTaskIds.Count -gt 0) {
        $Errors.Add(("review.md cannot record overall verdict 'accepted' while tasks remain non-passing: {0}" -f ($nonPassingVerdictTaskIds -join ', ')))
    }

    Test-NoGapClosurePolicy -ReviewLines $reviewLines -ProjectRoot $ProjectRoot -IterationDirectory $IterationDirectory -OverallVerdict $overallVerdict -IterationStatus $IterationStatus -Errors $Errors
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

function Get-ReviewerCloseoutDiffArtifacts {
    param(
        [string]$ProjectRoot,
        [AllowNull()][string]$BaselineRef
    )

    $result = [ordered]@{
        BaselineResolved = $false
        Files            = @()
    }

    if ([string]::IsNullOrWhiteSpace($BaselineRef)) {
        return [pscustomobject]$result
    }

    $gitCommand = Get-Command -Name 'git' -ErrorAction SilentlyContinue
    if ($null -eq $gitCommand) {
        return [pscustomobject]$result
    }

    $revParseOutput = @(& git -C $ProjectRoot rev-parse --verify $BaselineRef 2>$null)
    if ($LASTEXITCODE -ne 0) {
        return [pscustomobject]$result
    }

    $result.BaselineResolved = $true
    foreach ($line in @(& git -C $ProjectRoot diff --name-only $BaselineRef -- 2>$null)) {
        $path = ([string]$line).Trim()
        if ([string]::IsNullOrWhiteSpace($path)) {
            continue
        }

        $result.Files += [pscustomobject]@{
            Path       = $path
            IsManifest = Test-IsManifestPath -Path $path
            IsSource    = Test-IsReviewerSourcePath -Path $path
        }
    }

    return [pscustomobject]$result
}

function Test-ReviewerCloseoutArtifacts {
    param(
        [string]$IterationDirectory,
        [string]$ProjectRoot,
        [string[]]$StateLines,
        [bool]$EnforceReviewerCloseout,
        [System.Collections.Generic.List[string]]$Errors
    )

    if (-not $EnforceReviewerCloseout) {
        return
    }

    $baselineRef = Get-MarkdownMetadataValue -Lines $StateLines -Label 'Baseline Ref'
    $diffArtifacts = Get-ReviewerCloseoutDiffArtifacts -ProjectRoot $ProjectRoot -BaselineRef $baselineRef
    if (-not $diffArtifacts.BaselineResolved) {
        $Errors.Add('Reviewer closeout enforcement requires state.md Baseline Ref to resolve to a valid git revision')
        return
    }

    $codeTouched = @($diffArtifacts.Files | Where-Object { $_.IsSource }).Count -gt 0
    $manifestTouched = @($diffArtifacts.Files | Where-Object { $_.IsManifest }).Count -gt 0
    if (-not $codeTouched -and -not $manifestTouched) {
        return
    }

    $requiredArtifacts = New-Object System.Collections.Generic.List[string]
    if ($codeTouched) {
        foreach ($artifactName in @('code-map.md', 'coverage-evidence.md', 'reviewer-index.md', 'review-diagrams.md')) {
            $null = $requiredArtifacts.Add($artifactName)
        }
    }
    if ($manifestTouched) {
        $null = $requiredArtifacts.Add('dependency-report.md')
    }

    foreach ($artifactName in ($requiredArtifacts | Select-Object -Unique)) {
        $artifactPath = Join-Path $IterationDirectory $artifactName
        if (-not (Test-Path -LiteralPath $artifactPath -PathType Leaf)) {
            $Errors.Add(("Missing required reviewer closeout artifact: {0}. Run scaffold-reviewer-artifacts.ps1 before closing a code-touching iteration." -f $artifactName))
        }
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

function Get-TaskOwnerFileGlobs {
    param([object]$Task)

    if ($null -eq $Task) {
        return $null
    }

    foreach ($propertyName in @('Owner File Globs', 'owner_file_globs', 'OwnerFileGlobs')) {
        $property = $Task.PSObject.Properties[$propertyName]
        if ($null -ne $property) {
            return [string]$property.Value
        }
    }

    return $null
}

function Get-SameSpecialtyPairGroups {
    param([object[]]$Tasks)

    $groupMap = @{}
    foreach ($task in $Tasks) {
        $owner = [string]$task.Owner
        $match = [regex]::Match($owner, '^(?<tier>Junior|Senior)\s+(?<specialty>.+?)\s+Developer$')
        if (-not $match.Success) {
            continue
        }

        $specialtyKey = $match.Groups['specialty'].Value.Trim().ToLowerInvariant()
        if (-not $groupMap.ContainsKey($specialtyKey)) {
            $groupMap[$specialtyKey] = [ordered]@{
                Specialty = $match.Groups['specialty'].Value.Trim()
                Junior    = New-Object System.Collections.Generic.List[object]
                Senior    = New-Object System.Collections.Generic.List[object]
            }
        }

        $targetList = $groupMap[$specialtyKey][$match.Groups['tier'].Value]
        $null = $targetList.Add($task)
    }

    return @($groupMap.Values | Where-Object { $_.Junior.Count -gt 0 -and $_.Senior.Count -gt 0 })
}

function Test-ConcurrencyPlanningPolicy {
    param(
        [string[]]$PlanLines,
        [object[]]$Tasks,
        [System.Collections.Generic.List[string]]$Errors
    )

    $pairGroups = @(Get-SameSpecialtyPairGroups -Tasks $Tasks)
    if ($pairGroups.Count -eq 0) {
        return
    }

    if (-not (Test-HeadingPresent -Lines $PlanLines -Heading 'Concurrency Rationale')) {
        $Errors.Add('plan.md must contain a Concurrency Rationale section before same-specialty Junior/Senior pair work is planned')
        return
    }

    $concurrencyLines = @(Get-MarkdownSectionLines -Lines $PlanLines -Heading 'Concurrency Rationale')
    $concurrencyText = ($concurrencyLines -join "`n").ToLowerInvariant()
    $serialFallbackDeclared = $concurrencyText -match '\bserial\b'

    foreach ($group in $pairGroups) {
        $pairTasks = @($group.Junior + $group.Senior | Where-Object {
                $normalizedStatus = ([string]$_.Status).Trim().ToLowerInvariant()
                $normalizedStatus -notin @('blocked', 'deferred')
            })

        if ($pairTasks.Count -lt 2) {
            continue
        }

        $missingBoundaryTasks = @($pairTasks | Where-Object { Test-IsNullish (Get-TaskOwnerFileGlobs -Task $_) })
        if ($missingBoundaryTasks.Count -gt 0 -and -not $serialFallbackDeclared) {
            $taskLabels = $missingBoundaryTasks | ForEach-Object { [string]$_.Task }
            $Errors.Add(("plan.md schedules Junior/Senior {0} work without explicit Owner File Globs for task(s) {1}. Add ownership boundaries or state in Concurrency Rationale that the work must remain serial." -f $group.Specialty, ($taskLabels -join ', ')))
            continue
        }

        if ($missingBoundaryTasks.Count -gt 0) {
            continue
        }

        $normalizedBoundaryMap = @{}
        foreach ($task in $pairTasks) {
            $normalizedBoundaries = ((Get-TaskOwnerFileGlobs -Task $task) -split ',' | ForEach-Object { $_.Trim().ToLowerInvariant() } | Where-Object { -not [string]::IsNullOrWhiteSpace($_) } | Select-Object -Unique)
            $boundaryKey = $normalizedBoundaries -join ';'
            if ([string]::IsNullOrWhiteSpace($boundaryKey)) {
                continue
            }

            if ($normalizedBoundaryMap.ContainsKey($boundaryKey)) {
                $Errors.Add(("plan.md assigns overlapping Owner File Globs '{0}' to same-specialty Junior/Senior {1} tasks '{2}' and '{3}'. Keep the work serial or partition ownership more explicitly." -f $boundaryKey, $group.Specialty, $normalizedBoundaryMap[$boundaryKey], $task.Task))
                break
            }

            $normalizedBoundaryMap[$boundaryKey] = [string]$task.Task
        }
    }
}

function Get-IterationConfigForValidation {
    param([string]$IterationDirectory)

    $config = @{
        effort_unit            = 'story_points'
        capacity_per_iteration = '20'
        iteration_bounding     = 'scope'
        time_limit_hours       = 'null'
        overcommit_threshold   = '1.0'
        defer_strategy         = 'manual'
        calibration_enabled    = 'true'
        closeout_packet_required_since_iteration = ''
        config_present         = $false
    }

    $resolvedIterationDirectory = [System.IO.Path]::GetFullPath($IterationDirectory)
    $specDirectory = Split-Path -Parent (Split-Path -Parent $resolvedIterationDirectory)
    $specsRoot = Split-Path -Parent $specDirectory
    $projectRoot = Split-Path -Parent $specsRoot
    $configPath = Join-Path $projectRoot '.specrew\iteration-config.yml'

    if (-not (Test-Path -LiteralPath $configPath -PathType Leaf)) {
        return $config
    }

    $config.config_present = $true

    foreach ($line in Get-MarkdownContent -Path $configPath) {
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
        elseif ($line -match '^\s*defer_strategy:\s*"?([^"#]+?)"?\s*$') {
            $config.defer_strategy = $Matches[1].Trim()
        }
        elseif ($line -match '^\s*calibration_enabled:\s*("?)([^"#]+)\1\s*$') {
            $config.calibration_enabled = $Matches[2].Trim()
        }
        elseif ($line -match '^\s{2}closeout_packet_required_since_iteration:\s*("?)([^"#]+)\1\s*$') {
            $config.closeout_packet_required_since_iteration = $Matches[2].Trim()
        }
    }

    return $config
}

function Test-PlanEffortModel {
    param(
        [string[]]$PlanLines,
        [string]$Capacity,
        [hashtable]$IterationConfig,
        [System.Collections.Generic.List[string]]$Errors
    )

    $hasEffortModel = Test-HeadingPresent -Lines $PlanLines -Heading 'Effort Model'
    if (-not $IterationConfig.config_present -and -not $hasEffortModel) {
        return
    }

    if (-not $hasEffortModel) {
        $Errors.Add('plan.md is missing required section: Effort Model')
        return
    }

    $effortModelRows = @(Get-MarkdownSectionTable -Lines $PlanLines -Heading 'Effort Model')
    if ($effortModelRows.Count -eq 0) {
        $Errors.Add('plan.md Effort Model section must contain a settings table')
        return
    }

    $rowMap = @{}
    foreach ($row in $effortModelRows) {
        $setting = [string]$row.Setting
        if ([string]::IsNullOrWhiteSpace($setting)) {
            continue
        }

        $rowMap[$setting.Trim()] = [string]$row.Value
    }

    $timeLimitDisplay = if ([string]::IsNullOrWhiteSpace([string]$IterationConfig.time_limit_hours) -or [string]$IterationConfig.time_limit_hours -eq 'null') {
        'n/a'
    }
    else {
        [string]$IterationConfig.time_limit_hours
    }

    $expectedValues = [ordered]@{
        'Effort Unit'            = [string]$IterationConfig.effort_unit
        'Capacity per Iteration' = [string]$IterationConfig.capacity_per_iteration
        'Iteration Bounding'     = [string]$IterationConfig.iteration_bounding
        'Time Limit (hours)'     = $timeLimitDisplay
        'Overcommit Threshold'   = [string]$IterationConfig.overcommit_threshold
        'Defer Strategy'         = [string]$IterationConfig.defer_strategy
        'Calibration Enabled'    = [string]$IterationConfig.calibration_enabled
    }

    foreach ($expectedSetting in $expectedValues.Keys) {
        if (-not $rowMap.ContainsKey($expectedSetting)) {
            $Errors.Add("plan.md Effort Model section is missing required setting '$expectedSetting'")
            continue
        }

        $actualValue = [string]$rowMap[$expectedSetting]
        $expectedValue = [string]$expectedValues[$expectedSetting]
        if ($actualValue.Trim().ToLowerInvariant() -ne $expectedValue.Trim().ToLowerInvariant()) {
            $Errors.Add("plan.md Effort Model '$expectedSetting' value '$actualValue' does not match iteration-config '$expectedValue'")
        }
    }

    if (Test-IsNullish $Capacity) {
        return
    }

    $capacityMatch = [regex]::Match($Capacity, '^(?<used>\d+(?:\.\d+)?)/(?<total>\d+(?:\.\d+)?)\s+(?<unit>\S+)$')
    if (-not $capacityMatch.Success) {
        return
    }

    $capacityTotal = $capacityMatch.Groups['total'].Value
    $capacityUnit = $capacityMatch.Groups['unit'].Value
    if ($capacityTotal -ne [string]$IterationConfig.capacity_per_iteration) {
        $Errors.Add("plan.md Capacity total '$capacityTotal' does not match iteration-config capacity_per_iteration '$($IterationConfig.capacity_per_iteration)'")
    }

    if ($capacityUnit.Trim().ToLowerInvariant() -ne ([string]$IterationConfig.effort_unit).Trim().ToLowerInvariant()) {
        $Errors.Add("plan.md Capacity unit '$capacityUnit' does not match iteration-config effort_unit '$($IterationConfig.effort_unit)'")
    }
}

function Resolve-PlanSpecPath {
    param(
        [string[]]$PlanLines,
        [string]$IterationDirectory
    )

    $specMetadata = Get-MarkdownMetadataValue -Lines $PlanLines -Label 'Spec'
    if (Test-IsNullish $specMetadata) {
        return $null
    }

    $candidate = $null
    $linkMatch = [regex]::Match($specMetadata, '\(([^)]+)\)')
    if ($linkMatch.Success) {
        $candidate = $linkMatch.Groups[1].Value.Trim()
    }
    elseif ($specMetadata -match '^\[([^\]]+)\]$') {
        $candidate = $Matches[1].Trim()
    }
    else {
        $candidate = $specMetadata.Trim()
    }

    if (Test-IsNullish $candidate) {
        return $null
    }

    if ([System.IO.Path]::IsPathRooted($candidate)) {
        return [System.IO.Path]::GetFullPath($candidate)
    }

    return [System.IO.Path]::GetFullPath((Join-Path $IterationDirectory $candidate))
}

function Get-RequirementPriorityContext {
    param([AllowNull()][string]$SpecPath)

    $context = @{
        RequirementPriority = @{}
        StoryPriority       = @{}
    }

    if ((Test-IsNullish $SpecPath) -or -not (Test-Path -LiteralPath $SpecPath -PathType Leaf)) {
        return $context
    }

    $specLines = Get-MarkdownContent -Path $SpecPath
    foreach ($line in $specLines) {
        if ($line -match '^###\s+User Story\s+(\d+)\s+.*\(Priority:\s*(P\d)\)\s*$') {
            $context.StoryPriority["US-$($Matches[1])"] = $Matches[2].ToUpperInvariant()
        }
    }

    foreach ($line in $specLines) {
        if ($line -notmatch '^\s*-\s+(US-\d+)(?:\s*\([^)]+\))?\s+→\s+(.+?)\s*$') {
            continue
        }

        $storyId = $Matches[1].Trim()
        $requirementRefText = $Matches[2]
        if (-not $context.StoryPriority.ContainsKey($storyId)) {
            continue
        }

        $priorityLabel = $context.StoryPriority[$storyId]
        $priorityRank = 99
        if ($priorityLabel -match '^P(\d+)$') {
            $priorityRank = [int]$Matches[1]
        }

        foreach ($requirementId in ([regex]::Matches($requirementRefText, 'FR-\d+') | ForEach-Object { $_.Value } | Select-Object -Unique)) {
            if (-not $context.RequirementPriority.ContainsKey($requirementId) -or $priorityRank -lt $context.RequirementPriority[$requirementId].Rank) {
                $context.RequirementPriority[$requirementId] = [pscustomobject]@{
                    Label = $priorityLabel
                    Rank  = $priorityRank
                }
            }
        }
    }

    return $context
}

function Get-TaskPriorityEvidence {
    param(
        [object]$Task,
        [hashtable]$PriorityContext
    )

    $bestRank = 99
    $bestLabel = $null
    $prioritySources = New-Object System.Collections.Generic.List[string]

    foreach ($requirementId in ([regex]::Matches([string]$Task.Requirement, 'FR-\d+') | ForEach-Object { $_.Value } | Select-Object -Unique)) {
        if (-not $PriorityContext.RequirementPriority.ContainsKey($requirementId)) {
            continue
        }

        $priority = $PriorityContext.RequirementPriority[$requirementId]
        if ($priority.Rank -lt $bestRank) {
            $bestRank = $priority.Rank
            $bestLabel = $priority.Label
        }

        $null = $prioritySources.Add(('{0}→{1}' -f $requirementId, $priority.Label))
    }

    foreach ($storyId in ([regex]::Matches([string]$Task.Story, 'US-\d+') | ForEach-Object { $_.Value } | Select-Object -Unique)) {
        if (-not $PriorityContext.StoryPriority.ContainsKey($storyId)) {
            continue
        }

        $storyPriorityLabel = $PriorityContext.StoryPriority[$storyId]
        $storyPriorityRank = 99
        if ($storyPriorityLabel -match '^P(\d+)$') {
            $storyPriorityRank = [int]$Matches[1]
        }

        if ($storyPriorityRank -lt $bestRank) {
            $bestRank = $storyPriorityRank
            $bestLabel = $storyPriorityLabel
        }

        $null = $prioritySources.Add(('{0}→{1}' -f $storyId, $storyPriorityLabel))
    }

    if ($null -eq $bestLabel) {
        return [pscustomobject]@{
            Rank     = 99
            Label    = 'unmapped'
            Evidence = 'priority unavailable'
        }
    }

    return [pscustomobject]@{
        Rank     = $bestRank
        Label    = $bestLabel
        Evidence = ($prioritySources | Select-Object -Unique) -join ', '
    }
}

function Test-PlanningCapacity {
    param(
        [string]$IterationDirectory,
        [string]$Status,
        [string]$Capacity,
        [object[]]$Tasks,
        [hashtable]$IterationConfig,
        [System.Collections.Generic.List[string]]$Errors
    )

    if ($Status -ne 'planning' -or $Tasks.Count -eq 0 -or (Test-IsNullish $Capacity)) {
        return
    }

    $capacityMatch = [regex]::Match($Capacity, '^(?<used>\d+(?:\.\d+)?)/(?<total>\d+(?:\.\d+)?)\s+(?<unit>\S+)$')
    if (-not $capacityMatch.Success) {
        return
    }

    $used = [double]$capacityMatch.Groups['used'].Value
    $total = [double]$capacityMatch.Groups['total'].Value
    $unit = $capacityMatch.Groups['unit'].Value
    $plannedEffort = 0.0
    foreach ($task in $Tasks) {
        $numericEffort = 0.0
        if ([double]::TryParse([string]$task.Effort, [ref]$numericEffort)) {
            $plannedEffort += $numericEffort
        }
    }

    if ([math]::Abs($plannedEffort - $used) -gt 0.001) {
        $Errors.Add(("plan.md Capacity used value '{0}' does not match summed task effort '{1}' for planning status" -f $used, ([math]::Round($plannedEffort, 2))))
    }

    $threshold = 1.0
    if (-not [double]::TryParse([string]$IterationConfig.overcommit_threshold, [ref]$threshold)) {
        $threshold = 1.0
    }

    $allowed = [math]::Round(($total * $threshold), 2)
    if ($used -le $allowed) {
        return
    }

    $excess = [math]::Round(($used - $allowed), 2)
    $reclaimed = 0.0
    $candidateLabels = New-Object System.Collections.Generic.List[string]
    $specPath = Resolve-PlanSpecPath -PlanLines @(
        Get-MarkdownContent -Path (Join-Path -Path $IterationDirectory -ChildPath 'plan.md')
    ) -IterationDirectory $IterationDirectory
    $priorityContext = Get-RequirementPriorityContext -SpecPath $specPath
    $orderedTasks = @(
        $Tasks |
            ForEach-Object {
                $priority = Get-TaskPriorityEvidence -Task $_ -PriorityContext $priorityContext
                $numericEffort = 0.0
                [double]::TryParse([string]$_.Effort, [ref]$numericEffort) | Out-Null
                [pscustomobject]@{
                    Task     = $_
                    Priority = $priority
                    Effort   = $numericEffort
                }
            } |
            Sort-Object `
                @{ Expression = { $_.Priority.Rank }; Descending = $true }, `
                @{ Expression = { $_.Effort }; Descending = $true }, `
                @{ Expression = { [string]$_.Task.Task }; Descending = $false }
    )

    foreach ($candidate in $orderedTasks) {
        $task = $candidate.Task
        $effort = 0.0
        if (-not [double]::TryParse([string]$task.Effort, [ref]$effort) -or $effort -le 0) {
            continue
        }

        $priorityLabel = $candidate.Priority.Label
        $priorityEvidence = $candidate.Priority.Evidence
        $candidateLabels.Add(('{0} [{1}; {2}] ({3} {4})' -f $task.Task, $priorityLabel, $priorityEvidence, $effort, $unit))
        $reclaimed += $effort
        if ($reclaimed -ge $excess) {
            break
        }
    }

    $suggestion = if ($candidateLabels.Count -gt 0) {
        if ($IterationConfig.defer_strategy -eq 'lowest_priority') {
            "Configured defer_strategy is 'lowest_priority'; defer the lowest-priority requirement slices first: $($candidateLabels -join ', ')."
        }
        else {
            "Configured defer_strategy is 'manual'; explicit defer candidates ranked by mapped requirement priority are: $($candidateLabels -join ', ')."
        }
    }
    else {
        'Review task effort and mapped requirement priority, then defer enough lowest-priority work to return within the configured threshold.'
    }

    $Errors.Add(("plan.md is over capacity: planned effort {0} {1} exceeds the allowed {2} {1} (capacity {3} x threshold {4}). {5}" -f $used, $unit, $allowed, $total, $IterationConfig.overcommit_threshold, $suggestion))
}

function Test-IsEarlyPlanningStub {
    param(
        [string[]]$PlanLines,
        [string]$Status,
        [object[]]$Tasks
    )

    if ($Status -ne 'planning' -or $Tasks.Count -gt 0) {
        return $false
    }

    $titleLine = $PlanLines | Select-Object -First 1
    $planText = ($PlanLines -join "`n").ToLowerInvariant()

    return ($titleLine -match '\(stub\)\s*$') -or
        ($planText -match 'pending detailed planning') -or
        ($planText -match 'stub captures the planned scope')
}

function Test-IterationGovernance {
    param(
        [string]$IterationDirectory,
        [hashtable]$TeamRoles,
        [bool]$EnforceReviewerCloseout = $false
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

    $completed = Get-MarkdownMetadataValue -Lines $planLines -Label 'Completed'
    if ($status -eq 'complete' -and (Test-IsNullish $completed)) {
        $errors.Add('Complete iterations must record a Completed date in plan.md')
    }

    $tasks = @(Get-MarkdownSectionTable -Lines $planLines -Heading 'Tasks')
    $isEarlyPlanningStub = Test-IsEarlyPlanningStub -PlanLines $planLines -Status $status -Tasks $tasks

    $capacity = Get-MarkdownMetadataValue -Lines $planLines -Label 'Capacity'
    if (-not $isEarlyPlanningStub -and -not (Test-IsNullish $capacity) -and $capacity -notmatch '^\d+(?:\.\d+)?/\d+(?:\.\d+)?\s+\S+$') {
        $errors.Add("plan.md has invalid Capacity format '$capacity' (expected '<used>/<total> <unit>')")
    }

    if (-not $isEarlyPlanningStub) {
        Test-PlanTaskSet -Tasks $tasks -Errors $errors
        Test-ConcurrencyPlanningPolicy -PlanLines $planLines -Tasks $tasks -Errors $errors
    }

    Test-Phase1QualityEvidence -IterationDirectory $IterationDirectory -PlanLines $planLines -Errors $errors
    Test-Phase2HardeningGate -IterationDirectory $IterationDirectory -ProjectRoot $ResolvedProjectPath -PlanLines $planLines -IterationStatus $status -Errors $errors

    $iterationConfig = Get-IterationConfigForValidation -IterationDirectory $IterationDirectory
    Test-PlanEffortModel -PlanLines $planLines -Capacity $capacity -IterationConfig $iterationConfig -Errors $errors
    Test-PlanningCapacity -IterationDirectory $IterationDirectory -Status $status -Capacity $capacity -Tasks $tasks -IterationConfig $iterationConfig -Errors $errors

    $taskStatuses = $tasks | ForEach-Object { $_.Status.Trim().ToLowerInvariant() }
    $hasNonTerminalTasks = [bool]($taskStatuses | Where-Object { $_ -notin $terminalTaskStatuses } | Select-Object -First 1)

    $driftPath = Join-Path -Path $IterationDirectory -ChildPath 'drift-log.md'
    $reviewPath = Join-Path -Path $IterationDirectory -ChildPath 'review.md'
    $retroPath = Join-Path -Path $IterationDirectory -ChildPath 'retro.md'
    $statePath = Join-Path -Path $IterationDirectory -ChildPath 'state.md'
    $stateLines = @(if (Test-Path -Path $statePath -PathType Leaf) { Get-MarkdownContent -Path $statePath } else { @() })
    $reviewLines = @(if (Test-Path -Path $reviewPath -PathType Leaf) { Get-MarkdownContent -Path $reviewPath } else { @() })
    $retroLines = @(if (Test-Path -Path $retroPath -PathType Leaf) { Get-MarkdownContent -Path $retroPath } else { @() })
    $reviewOverallVerdict = if ($reviewLines.Count -gt 0) {
        Get-NormalizedKeyword (Get-MarkdownMetadataValue -Lines $reviewLines -Label 'Overall Verdict')
    }
    else {
        $null
    }
    $hasAcceptedReview = $reviewOverallVerdict -eq 'accepted'
    $hasReviewArtifact = $reviewLines.Count -gt 0
    $hasRetroArtifact = $retroLines.Count -gt 0
    $hasCompleteEvidence = $status -eq 'complete'

    if ($hasReviewArtifact -and $status -in @('planning', 'executing')) {
        $errors.Add("plan.md status '$status' is stale: review.md exists, so the iteration must be in reviewing, retro, or complete")
    }

    if ($hasRetroArtifact -and $status -notin @('retro', 'complete')) {
        $errors.Add("plan.md status '$status' is stale: retro.md exists, so the iteration must be in retro or complete")
    }

    Test-GovernanceGateConsistency -PlanLines $planLines -HasCompletionEvidence ($hasAcceptedReview -or $hasCompleteEvidence) -Errors $errors

    $closureEvidenceArtifacts = @{}
    if ($hasReviewArtifact) {
        $closureEvidenceArtifacts['review.md'] = $reviewLines
    }
    if ($hasRetroArtifact) {
        $closureEvidenceArtifacts['retro.md'] = $retroLines
    }
    Test-PlanMetadataEvidenceDrift -ArtifactContents $closureEvidenceArtifacts -PlanStatus $status -PlanCompleted $completed -Errors $errors

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
            Test-ReviewArtifact -ReviewPath $reviewPath -ProjectRoot $ResolvedProjectPath -IterationDirectory $IterationDirectory -IterationStatus $status -PlanTasks $tasks -Errors $errors
        }
        'retro' {
            Test-StateArtifact -IterationDirectory $IterationDirectory -Errors $errors
            if (-not (Test-Path -Path $driftPath -PathType Leaf)) {
                $errors.Add('Retro iterations require drift-log.md')
            }
            if ($hasNonTerminalTasks) {
                $errors.Add('Retro iterations require all tasks to be in terminal states')
            }
            Test-ReviewArtifact -ReviewPath $reviewPath -ProjectRoot $ResolvedProjectPath -IterationDirectory $IterationDirectory -IterationStatus $status -PlanTasks $tasks -Errors $errors -RequireAcceptedVerdict
            Test-ReviewerCloseoutArtifacts -IterationDirectory $IterationDirectory -ProjectRoot $ResolvedProjectPath -StateLines $stateLines -EnforceReviewerCloseout $EnforceReviewerCloseout -Errors $errors
        }
        'complete' {
            Test-StateArtifact -IterationDirectory $IterationDirectory -Errors $errors
            if (-not (Test-Path -Path $driftPath -PathType Leaf)) {
                $errors.Add('Complete iterations require drift-log.md')
            }
            if ($hasNonTerminalTasks) {
                $errors.Add('Complete iterations require all tasks to be in terminal states')
            }
            Test-ReviewArtifact -ReviewPath $reviewPath -ProjectRoot $ResolvedProjectPath -IterationDirectory $IterationDirectory -IterationStatus $status -PlanTasks $tasks -Errors $errors -RequireAcceptedVerdict
            Test-RetroArtifact -RetroPath $retroPath -Errors $errors
            Test-ReviewerCloseoutArtifacts -IterationDirectory $IterationDirectory -ProjectRoot $ResolvedProjectPath -StateLines $stateLines -EnforceReviewerCloseout $EnforceReviewerCloseout -Errors $errors
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

function Get-ReviewerCloseoutEnforcementMap {
    param(
        [string[]]$Targets,
        [bool]$ExplicitTargetsProvided,
        [AllowNull()][string]$RequiredSinceIteration
    )

    $enforcementMap = @{}
    if (@($Targets).Count -eq 0) {
        return $enforcementMap
    }

    if ($ExplicitTargetsProvided) {
        foreach ($target in $Targets) {
            if (Test-IterationMeetsCloseoutCutoff -IterationDirectory $target -RequiredSinceIteration $RequiredSinceIteration) {
                $enforcementMap[$target] = $true
            }
        }

        return $enforcementMap
    }

    $groupedTargets = @{}
    foreach ($target in $Targets) {
        $featureDirectory = Split-Path -Parent (Split-Path -Parent $target)
        if (-not $groupedTargets.ContainsKey($featureDirectory)) {
            $groupedTargets[$featureDirectory] = New-Object System.Collections.Generic.List[string]
        }

        $null = $groupedTargets[$featureDirectory].Add($target)
    }

    foreach ($featureDirectory in $groupedTargets.Keys) {
        $latestTarget = $groupedTargets[$featureDirectory] |
            Sort-Object { [System.IO.Path]::GetFileName($_) } -Descending |
            Select-Object -First 1

        if (-not [string]::IsNullOrWhiteSpace($latestTarget) -and (Test-IterationMeetsCloseoutCutoff -IterationDirectory $latestTarget -RequiredSinceIteration $RequiredSinceIteration)) {
            $enforcementMap[$latestTarget] = $true
        }
    }

    return $enforcementMap
}

$resolvedProjectPath = (Resolve-Path -Path (Resolve-ProjectPath -Path $ProjectPath)).Path
$teamRoles = Get-TeamRoleMap -ResolvedProjectPath $resolvedProjectPath

$teamValidationErrors = New-Object System.Collections.Generic.List[string]
Test-BaselineTeamMembers -TeamRoles $teamRoles -Errors $teamValidationErrors

if ($teamValidationErrors.Count -gt 0) {
    Write-Host "FAIL Squad team validation" -ForegroundColor Red
    foreach ($errorMessage in $teamValidationErrors) {
        Write-Host "  - $errorMessage" -ForegroundColor Red
    }
    exit 1
}

$explicitIterationPathsProvided = ($null -ne $IterationPath) -and @(
    $IterationPath | Where-Object { -not [string]::IsNullOrWhiteSpace([string]$_) }
).Count -gt 0
$targets = @(Resolve-IterationTarget -ResolvedProjectPath $resolvedProjectPath -ExplicitIterationPaths $IterationPath)
$iterationConfig = if ($targets.Count -gt 0) { Get-IterationConfigForValidation -IterationDirectory $targets[0] } else { @{ closeout_packet_required_since_iteration = '' } }
$reviewerCloseoutEnforcement = Get-ReviewerCloseoutEnforcementMap -Targets $targets -ExplicitTargetsProvided $explicitIterationPathsProvided -RequiredSinceIteration $iterationConfig.closeout_packet_required_since_iteration
$results = @($targets | ForEach-Object {
        Test-IterationGovernance -IterationDirectory $_ -TeamRoles $teamRoles -EnforceReviewerCloseout $reviewerCloseoutEnforcement.ContainsKey($_)
    })
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
