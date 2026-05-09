[CmdletBinding()]
param(
    [string]$ProjectPath = (Get-Location).Path,
    [string]$FeaturePath,
    [string]$IterationPath,
    [string]$SpecPath,
    [string]$ReviewedBy,
    [string]$ReviewedAt,
    [ValidateSet('Object', 'Json', 'Markdown')]
    [string]$OutputFormat = 'Object'
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

$sharedGovernancePath = Join-Path $PSScriptRoot 'shared-governance.ps1'
if (-not (Test-Path -LiteralPath $sharedGovernancePath -PathType Leaf)) {
    throw "Shared governance helper not found at '$sharedGovernancePath'."
}

. $sharedGovernancePath

function Convert-ToRepoRelativePath {
    param(
        [Parameter(Mandatory = $true)]
        [string]$BasePath,

        [Parameter(Mandatory = $true)]
        [string]$TargetPath
    )

    $baseUri = [System.Uri]([System.IO.Path]::GetFullPath($BasePath).TrimEnd('\') + '\')
    $targetUri = [System.Uri][System.IO.Path]::GetFullPath($TargetPath)
    $relativeUri = $baseUri.MakeRelativeUri($targetUri)
    return [System.Uri]::UnescapeDataString($relativeUri.ToString()).Replace('\', '/')
}

function Resolve-HardeningContext {
    param(
        [Parameter(Mandatory = $true)]
        [string]$ProjectRoot,
        [string]$FeaturePath,
        [string]$IterationPath,
        [string]$SpecPath
    )

    $resolvedFeaturePath = $null
    if (-not [string]::IsNullOrWhiteSpace($FeaturePath)) {
        $resolvedFeaturePath = Resolve-ProjectPath -Path $FeaturePath
    }
    elseif (-not [string]::IsNullOrWhiteSpace($SpecPath)) {
        $resolvedFeaturePath = Split-Path -Parent (Resolve-ProjectPath -Path $SpecPath)
    }

    $resolvedIterationPath = $null
    if (-not [string]::IsNullOrWhiteSpace($IterationPath)) {
        $resolvedIterationPath = Resolve-ProjectPath -Path $IterationPath
        if ([string]::IsNullOrWhiteSpace($resolvedFeaturePath)) {
            $resolvedFeaturePath = Split-Path -Parent (Split-Path -Parent $resolvedIterationPath)
        }
    }

    if ([string]::IsNullOrWhiteSpace($resolvedFeaturePath)) {
        $specsRoot = Join-Path $ProjectRoot 'specs'
        if (Test-Path -LiteralPath $specsRoot -PathType Container) {
            $featureCandidates = @(
                Get-ChildItem -LiteralPath $specsRoot -Directory |
                    Where-Object { Test-Path -LiteralPath (Join-Path $_.FullName 'spec.md') -PathType Leaf } |
                    Sort-Object Name
            )

            if ($featureCandidates.Count -eq 1) {
                $resolvedFeaturePath = $featureCandidates[0].FullName
            }
            elseif ($featureCandidates.Count -gt 1) {
                $iterationCandidates = foreach ($featureCandidate in $featureCandidates) {
                    $iterationsRoot = Join-Path $featureCandidate.FullName 'iterations'
                    if (-not (Test-Path -LiteralPath $iterationsRoot -PathType Container)) {
                        continue
                    }

                    foreach ($directory in Get-ChildItem -LiteralPath $iterationsRoot -Directory | Sort-Object Name) {
                        $numericValue = 0
                        if ([int]::TryParse($directory.Name, [ref]$numericValue)) {
                            [pscustomobject]@{
                                FeaturePath     = $featureCandidate.FullName
                                IterationPath   = $directory.FullName
                                IterationNumber = $numericValue
                            }
                        }
                    }
                }

                $selectedCandidate = @($iterationCandidates | Sort-Object IterationNumber -Descending | Select-Object -First 1)[0]
                if ($null -ne $selectedCandidate) {
                    $resolvedFeaturePath = $selectedCandidate.FeaturePath
                    if ([string]::IsNullOrWhiteSpace($resolvedIterationPath)) {
                        $resolvedIterationPath = $selectedCandidate.IterationPath
                    }
                }
            }
        }
    }

    if ([string]::IsNullOrWhiteSpace($resolvedFeaturePath)) {
        throw 'Unable to resolve a feature path for the hardening gate. Provide -FeaturePath, -SpecPath, or -IterationPath.'
    }

    if ([string]::IsNullOrWhiteSpace($resolvedIterationPath)) {
        $iterationsRoot = Join-Path $resolvedFeaturePath 'iterations'
        if (Test-Path -LiteralPath $iterationsRoot -PathType Container) {
            $iterationDirectories = foreach ($directory in Get-ChildItem -LiteralPath $iterationsRoot -Directory | Sort-Object Name) {
                $numericValue = 0
                if ([int]::TryParse($directory.Name, [ref]$numericValue)) {
                    [pscustomobject]@{
                        FullName        = $directory.FullName
                        IterationNumber = $numericValue
                    }
                }
            }

            $resolvedIterationPath = @(
                $iterationDirectories |
                    Sort-Object IterationNumber -Descending |
                    Select-Object -First 1 |
                    ForEach-Object { $_.FullName }
            )[0]
        }
    }

    if ([string]::IsNullOrWhiteSpace($resolvedIterationPath)) {
        throw "Unable to resolve an iteration path under '$resolvedFeaturePath'."
    }

    $resolvedSpecPath = if (-not [string]::IsNullOrWhiteSpace($SpecPath)) {
        Resolve-ProjectPath -Path $SpecPath
    }
    else {
        Join-Path $resolvedFeaturePath 'spec.md'
    }

    if (-not (Test-Path -LiteralPath $resolvedSpecPath -PathType Leaf)) {
        throw "Spec path '$resolvedSpecPath' does not exist."
    }

    return [pscustomobject]@{
        ProjectRoot   = $ProjectRoot
        FeaturePath   = $resolvedFeaturePath
        IterationPath = $resolvedIterationPath
        SpecPath      = $resolvedSpecPath
        FeatureRef    = Convert-ToRepoRelativePath -BasePath $ProjectRoot -TargetPath $resolvedSpecPath
        IterationRef  = Convert-ToRepoRelativePath -BasePath $ProjectRoot -TargetPath $resolvedIterationPath
    }
}

function Get-HardeningConcernDefinitions {
    return @(
        [pscustomobject]@{
            Concern          = 'security-surface'
            Category         = 'security'
            Rationale        = 'Scaffolded placeholder. Review trust boundaries, privilege changes, and sensitive flows before implementation proceeds.'
            ExpectedControls = 'Document trust boundaries, authorization expectations, and the runtime verification signals required before closure.'
        }
        [pscustomobject]@{
            Concern          = 'error-handling-expectations'
            Category         = 'error-handling'
            Rationale        = 'Scaffolded placeholder. Record expected failure semantics and incomplete-state handling before implementation proceeds.'
            ExpectedControls = 'Describe fail-closed behavior, surfaced errors, and the validation evidence that will confirm the failure contract once implementation exists.'
        }
        [pscustomobject]@{
            Concern          = 'retry-idempotency-requirements'
            Category         = 'retry-idempotency'
            Rationale        = 'Scaffolded placeholder. Confirm whether retries/idempotency are required or explicitly not applicable.'
            ExpectedControls = 'Record whether retries are forbidden, idempotent, or not applicable for this slice before implementation begins.'
        }
        [pscustomobject]@{
            Concern          = 'test-integrity-targets'
            Category         = 'test-integrity'
            Rationale        = 'Scaffolded placeholder. Tie negative-path expectations to observable test evidence before implementation proceeds.'
            ExpectedControls = 'Name the deterministic regression assertions and observable validation commands required before the slice can close.'
        }
        [pscustomobject]@{
            Concern          = 'operational-resilience-concerns'
            Category         = 'operational'
            Rationale        = 'Scaffolded placeholder. Review runtime resilience, fallback, and operator-facing failure signals before implementation proceeds.'
            ExpectedControls = 'Record runtime resilience checks, rollback expectations, and the operational proof required before closure.'
        }
    )
}

function Get-MarkdownSectionLines {
    param(
        [AllowEmptyCollection()]
        [AllowEmptyString()]
        [Parameter(Mandatory = $true)]
        [string[]]$Lines,

        [Parameter(Mandatory = $true)]
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

    $sectionLines = New-Object System.Collections.Generic.List[string]
    for ($index = $startIndex + 1; $index -lt $Lines.Count; $index++) {
        $currentLine = $Lines[$index]
        if ($currentLine -match '^#{2,3}\s+') {
            break
        }

        $sectionLines.Add($currentLine) | Out-Null
    }

    return $sectionLines.ToArray()
}

function Escape-MarkdownTableCell {
    param([AllowNull()][string]$Value)

    if ($null -eq $Value) {
        return ''
    }

    return ($Value -replace '\|', '\|').Trim()
}

function Get-CanonicalMarkdownToken {
    param([AllowNull()][string]$Value)

    $normalized = Normalize-MarkdownCell $Value
    if (Test-IsNullish $normalized) {
        return '—'
    }

    return $normalized
}

function Merge-HardeningConcernRows {
    param(
        [AllowNull()][object]$ExistingState
    )

    $existingByConcern = @{}
    if ($null -ne $ExistingState) {
        foreach ($row in @($ExistingState.ConcernRows)) {
            $concernId = Normalize-MarkdownCell ([string]$row.Concern)
            if (-not [string]::IsNullOrWhiteSpace($concernId)) {
                $existingByConcern[$concernId] = $row
            }
        }
    }

    $rows = New-Object System.Collections.Generic.List[object]
    foreach ($definition in @(Get-HardeningConcernDefinitions)) {
        $existingRow = if ($existingByConcern.ContainsKey($definition.Concern)) { $existingByConcern[$definition.Concern] } else { $null }
        $existingStatus = if ($null -ne $existingRow) { [string]$existingRow.Status } else { $null }
        $status = Normalize-MarkdownCell $existingStatus
        if ([string]::IsNullOrWhiteSpace($status)) {
            $status = 'tbd'
        }

        $allowedStatuses = @('addressed', 'not-applicable', 'tbd', 'deferred-with-approval')
        if ($status.ToLowerInvariant() -notin $allowedStatuses) {
            $status = 'tbd'
        }

        $existingEvidenceBasis = if ($null -ne $existingRow) { [string]$existingRow.EvidenceBasis } else { $null }
        $evidenceBasis = Normalize-MarkdownCell $existingEvidenceBasis
        if (Test-IsNullish $evidenceBasis) {
            switch ($status) {
                'addressed' { $evidenceBasis = 'planning-time-analysis' }
                'deferred-with-approval' { $evidenceBasis = 'planning-time-analysis' }
                'not-applicable' { $evidenceBasis = 'not-applicable' }
                default { $evidenceBasis = '—' }
            }
        }

        $existingRuntimeEvidenceStatus = if ($null -ne $existingRow) { [string]$existingRow.RuntimeEvidenceStatus } else { $null }
        $runtimeEvidenceStatus = Normalize-MarkdownCell $existingRuntimeEvidenceStatus
        if (Test-IsNullish $runtimeEvidenceStatus) {
            switch ($status) {
                'addressed' { $runtimeEvidenceStatus = 'pending-post-implementation' }
                'deferred-with-approval' { $runtimeEvidenceStatus = 'pending-post-implementation' }
                'not-applicable' { $runtimeEvidenceStatus = 'not-needed' }
                default { $runtimeEvidenceStatus = '—' }
            }
        }

        $existingExpectedControls = if ($null -ne $existingRow) { [string]$existingRow.ExpectedControls } else { $null }
        $expectedControls = Normalize-MarkdownCell $existingExpectedControls
        if (Test-IsNullish $expectedControls) {
            if ($status -eq 'not-applicable') {
                $expectedControls = '—'
            }
            elseif ($status -eq 'tbd') {
                $expectedControls = '—'
            }
            else {
                $expectedControls = $definition.ExpectedControls
            }
        }

        $existingRationale = if ($null -ne $existingRow) { [string]$existingRow.Rationale } else { $null }
        $rationale = Normalize-MarkdownCell $existingRationale
        if (Test-IsNullish $rationale) {
            $rationale = $definition.Rationale
        }

        $existingApproval = if ($null -ne $existingRow) { [string]$existingRow.Approval } else { $null }
        $approval = Normalize-MarkdownCell $existingApproval
        if ($status -ne 'deferred-with-approval') {
            $approval = '—'
        }
        elseif (Test-IsNullish $approval) {
            $approval = '—'
        }

        $rows.Add([pscustomobject]@{
                Concern               = $definition.Concern
                Category              = $definition.Category
                Status                = $status
                EvidenceBasis         = $evidenceBasis
                RuntimeEvidenceStatus = $runtimeEvidenceStatus
                ExpectedControls      = $expectedControls
                Blocking              = 'true'
                Rationale             = $rationale
                Approval              = $approval
            }) | Out-Null
    }

    return $rows.ToArray()
}

function Get-HardeningVerdict {
    param(
        [Parameter(Mandatory = $true)]
        [object[]]$ConcernRows,
        [Parameter(Mandatory = $true)]
        [string]$ProjectRoot
    )

    $blockingConcerns = @(
        $ConcernRows |
            Where-Object {
                Test-HardeningConcernBlocksImplementation -Concern $_ -ProjectRoot $ProjectRoot
            }
    )

    if ($blockingConcerns.Count -gt 0) {
        return [pscustomobject]@{
            OverallVerdict       = 'blocked'
            BlockingConcerns     = $blockingConcerns
            BlocksImplementation = $true
        }
    }

    $hasApprovedDeferral = [bool]@(
        $ConcernRows |
            Where-Object { (Normalize-MarkdownCell ([string]$_.Status)).ToLowerInvariant() -eq 'deferred-with-approval' } |
            Select-Object -First 1
    )

    return [pscustomobject]@{
        OverallVerdict       = if ($hasApprovedDeferral) { 'deferred-with-approval' } else { 'ready' }
        BlockingConcerns     = @()
        BlocksImplementation = $false
    }
}

function Get-GateApprovalReference {
    param(
        [AllowNull()][object]$ExistingState,
        [Parameter(Mandatory = $true)]
        [object[]]$ConcernRows,
        [Parameter(Mandatory = $true)]
        [string]$ProjectRoot,
        [Parameter(Mandatory = $true)]
        [string]$OverallVerdict
    )

    if ($OverallVerdict -ne 'deferred-with-approval') {
        return '—'
    }

    $candidateRefs = New-Object System.Collections.Generic.List[string]
    foreach ($row in @($ConcernRows | Where-Object { (Normalize-MarkdownCell ([string]$_.Status)).ToLowerInvariant() -eq 'deferred-with-approval' })) {
        $approvalRef = Normalize-MarkdownCell ([string]$row.Approval)
        if (-not (Test-IsNullish $approvalRef) -and -not $candidateRefs.Contains($approvalRef)) {
            $candidateRefs.Add($approvalRef) | Out-Null
        }
    }

    $existingMetadataApproval = if ($null -ne $ExistingState) {
        Normalize-MarkdownCell ([string]$ExistingState.Metadata.ApprovalRef)
    }
    else {
        $null
    }

    if (-not (Test-IsNullish $existingMetadataApproval)) {
        $approvalRecord = Get-ApprovalReferenceRecord -ProjectRoot $ProjectRoot -ApprovalRef $existingMetadataApproval -AllowedTypes @('decision', 'defer')
        if ($null -ne $approvalRecord -and $approvalRecord.HasHumanApproval) {
            return $existingMetadataApproval
        }
    }

    if ($candidateRefs.Count -eq 0) {
        return '—'
    }

    return ($candidateRefs.ToArray() -join ', ')
}

function Get-HardeningNotes {
    param(
        [AllowNull()][object]$ExistingState,
        [AllowEmptyCollection()]
        [AllowEmptyString()]
        [Parameter(Mandatory = $true)]
        [string[]]$ExistingLines,
        [Parameter(Mandatory = $true)]
        [string]$OverallVerdict
    )

    $existingNotes = @(
        Get-MarkdownSectionLines -Lines $ExistingLines -Heading 'Notes' |
            ForEach-Object { $_.TrimEnd() } |
            Where-Object { -not [string]::IsNullOrWhiteSpace($_) }
    )
    if ($existingNotes.Count -gt 0) {
        return $existingNotes
    }

    if ($null -ne $ExistingState) {
        return @()
    }

    switch ($OverallVerdict) {
        'ready' {
            return @(
                '- All bounded pre-implementation hardening concerns currently resolve without blocking implementation.'
                '- Re-run this orchestration after any material scope change so readiness remains truthful.'
            )
        }
        'deferred-with-approval' {
            return @(
                '- At least one bounded hardening concern is deferred with explicit human approval and visible rationale.'
                '- Re-run this orchestration after the approved follow-up is completed or the deferral changes.'
            )
        }
        default {
            return @(
                '- This artifact blocks implementation until every critical concern is addressed, explicitly not applicable with rationale, or deferred with human approval.'
                '- Re-run this orchestration after the concern rows are reviewed so the verdict stays truthful.'
            )
        }
    }
}

function Get-HardeningGateContent {
    param(
        [Parameter(Mandatory = $true)]
        [pscustomobject]$Context,
        [AllowNull()][object]$ExistingState,
        [Parameter(Mandatory = $true)]
        [object[]]$ConcernRows,
        [Parameter(Mandatory = $true)]
        [string]$ReviewedBy,
        [Parameter(Mandatory = $true)]
        [string]$ReviewedAt,
        [Parameter(Mandatory = $true)]
        [string]$OverallVerdict,
        [Parameter(Mandatory = $true)]
        [string]$ApprovalRef,
        [AllowEmptyCollection()]
        [AllowEmptyString()]
        [Parameter(Mandatory = $true)]
        [string[]]$ExistingLines
    )

    $requestedReviewClass = if ($null -ne $ExistingState) {
        Normalize-MarkdownCell ([string]$ExistingState.Metadata.RequestedReviewClass)
    }
    else {
        $null
    }
    if (Test-IsNullish $requestedReviewClass) {
        $requestedReviewClass = 'strongest-available'
    }

    $effectiveReviewClass = if ($null -ne $ExistingState) {
        Normalize-MarkdownCell ([string]$ExistingState.Metadata.EffectiveReviewClass)
    }
    else {
        $null
    }
    if (Test-IsNullish $effectiveReviewClass) {
        $effectiveReviewClass = '(pending hardening review)'
    }

    $notes = @(Get-HardeningNotes -ExistingState $ExistingState -ExistingLines $ExistingLines -OverallVerdict $OverallVerdict)
    $iterationNumber = Split-Path -Leaf $Context.IterationPath
    $lines = [System.Collections.Generic.List[string]]::new()
    $null = $lines.Add("# Hardening Gate: Iteration $iterationNumber")
    $null = $lines.Add('')
    $null = $lines.Add('**Schema**: v1')
    $null = $lines.Add('**Gate ID**: `pre-implementation-hardening`')
    $null = $lines.Add(('**Feature Ref**: `' + $Context.FeatureRef + '`'))
    $null = $lines.Add(('**Iteration Ref**: `' + $Context.IterationRef + '`'))
    $null = $lines.Add(('**Requested Review Class**: `' + $requestedReviewClass + '`'))
    $null = $lines.Add(('**Effective Review Class**: `' + $effectiveReviewClass + '`'))
    $null = $lines.Add(('**Overall Verdict**: `' + $OverallVerdict + '`'))
    $null = $lines.Add(('**Approval Ref**: `' + (Get-CanonicalMarkdownToken -Value $ApprovalRef) + '`'))
    $null = $lines.Add(('**Reviewed By**: ' + $ReviewedBy))
    $null = $lines.Add(('**Reviewed At**: ' + $ReviewedAt))
    $null = $lines.Add('')
    $null = $lines.Add('## Concern Review')
    $null = $lines.Add('')
    $null = $lines.Add('| Concern | Category | Status | Evidence Basis | Runtime Evidence Status | Expected Controls | Blocking | Rationale | Approval |')
    $null = $lines.Add('| --- | --- | --- | --- | --- | --- | --- | --- | --- |')

    foreach ($row in $ConcernRows) {
        $null = $lines.Add((
                '| `{0}` | `{1}` | `{2}` | `{3}` | `{4}` | {5} | `{6}` | {7} | `{8}` |' -f
                (Escape-MarkdownTableCell -Value ([string]$row.Concern)),
                (Escape-MarkdownTableCell -Value ([string]$row.Category)),
                (Escape-MarkdownTableCell -Value ([string]$row.Status)),
                (Escape-MarkdownTableCell -Value ([string]$row.EvidenceBasis)),
                (Escape-MarkdownTableCell -Value ([string]$row.RuntimeEvidenceStatus)),
                (Escape-MarkdownTableCell -Value (Get-CanonicalMarkdownToken -Value ([string]$row.ExpectedControls))),
                (Escape-MarkdownTableCell -Value ([string]$row.Blocking)),
                (Escape-MarkdownTableCell -Value ([string]$row.Rationale)),
                (Escape-MarkdownTableCell -Value (Get-CanonicalMarkdownToken -Value ([string]$row.Approval)))
            ))
    }

    if ($notes.Count -gt 0) {
        $null = $lines.Add('')
        $null = $lines.Add('## Notes')
        $null = $lines.Add('')
        foreach ($note in $notes) {
            $null = $lines.Add($note)
        }
    }

    return ($lines -join [Environment]::NewLine) + [Environment]::NewLine
}

$resolvedProjectPath = Resolve-ProjectPath -Path $ProjectPath
if (-not (Test-Path -LiteralPath $resolvedProjectPath -PathType Container)) {
    throw "Project path '$resolvedProjectPath' does not exist."
}

$context = Resolve-HardeningContext -ProjectRoot $resolvedProjectPath -FeaturePath $FeaturePath -IterationPath $IterationPath -SpecPath $SpecPath
$qualityDirectory = Join-Path $context.IterationPath 'quality'
$hardeningGatePath = Join-Path $qualityDirectory 'hardening-gate.md'

if (-not (Test-Path -LiteralPath $qualityDirectory -PathType Container)) {
    $null = New-Item -ItemType Directory -Path $qualityDirectory -Force
}

$existingLines = if (Test-Path -LiteralPath $hardeningGatePath -PathType Leaf) {
    @(Get-MarkdownContent -Path $hardeningGatePath)
}
else {
    @()
}
$existingState = if (Test-Path -LiteralPath $hardeningGatePath -PathType Leaf) {
    Get-HardeningGateState -Path $hardeningGatePath -ProjectRoot $resolvedProjectPath
}
else {
    $null
}

$effectiveReviewedBy = if (-not [string]::IsNullOrWhiteSpace($ReviewedBy)) {
    $ReviewedBy.Trim()
}
elseif ($null -ne $existingState -and -not (Test-IsNullish ([string]$existingState.Metadata.ReviewedBy))) {
    Normalize-MarkdownCell ([string]$existingState.Metadata.ReviewedBy)
}
else {
    'Reviewer (pending)'
}

$effectiveReviewedAt = if (-not [string]::IsNullOrWhiteSpace($ReviewedAt)) {
    $ReviewedAt.Trim()
}
elseif ($null -ne $existingState -and -not (Test-IsNullish ([string]$existingState.Metadata.ReviewedAt))) {
    Normalize-MarkdownCell ([string]$existingState.Metadata.ReviewedAt)
}
else {
    (Get-Date).ToUniversalTime().ToString('yyyy-MM-ddTHH:mm:ssZ')
}

$concernRows = @(Merge-HardeningConcernRows -ExistingState $existingState)
$verdict = Get-HardeningVerdict -ConcernRows $concernRows -ProjectRoot $resolvedProjectPath
$approvalRef = Get-GateApprovalReference -ExistingState $existingState -ConcernRows $concernRows -ProjectRoot $resolvedProjectPath -OverallVerdict $verdict.OverallVerdict
$content = Get-HardeningGateContent `
    -Context $context `
    -ExistingState $existingState `
    -ConcernRows $concernRows `
    -ReviewedBy $effectiveReviewedBy `
    -ReviewedAt $effectiveReviewedAt `
    -OverallVerdict $verdict.OverallVerdict `
    -ApprovalRef $approvalRef `
    -ExistingLines $existingLines

Write-Utf8FileAtomic -Path $hardeningGatePath -Content $content
$finalState = Get-HardeningGateState -Path $hardeningGatePath -ProjectRoot $resolvedProjectPath
$result = [pscustomobject]@{
    Path                 = $hardeningGatePath
    FeatureRef           = $context.FeatureRef
    IterationRef         = $context.IterationRef
    OverallVerdict       = [string]$finalState.Metadata.OverallVerdict
    ApprovalRef          = [string]$finalState.Metadata.ApprovalRef
    ReviewedBy           = [string]$finalState.Metadata.ReviewedBy
    ReviewedAt           = [string]$finalState.Metadata.ReviewedAt
    BlocksImplementation = [bool]$finalState.BlocksImplementation
    BlockingConcernIds   = @($finalState.BlockingConcerns | ForEach-Object { [string]$_.Concern })
    ConcernRows          = @($finalState.ConcernRows)
}

switch ($OutputFormat) {
    'Json' {
        $result | ConvertTo-Json -Depth 8
    }
    'Markdown' {
        $content
    }
    default {
        $result
    }
}
