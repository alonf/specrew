[CmdletBinding()]
param(
    [string]$ProjectPath = (Get-Location).Path,
    [string[]]$IterationPath,
    [switch]$ChangedOnly,
    [switch]$FullRun,
    [switch]$NoCacheRead,
    [switch]$NoParallel,
    [int]$ThrottleLimit = 6,
    [switch]$IncludeClosed,
    [switch]$RebuildClosedIndex,
    [AllowEmptyString()][string]$ResponseText = '',
    [string]$BoundaryName,
    [ValidateSet('auto', 'boundary-handoff', 'narration')][string]$ResponseScope = 'auto',
    [ValidateSet('soft-warning', 'validation-fail')][string]$BarePathBoundaryHandoffSeverity
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

$sharedGovernancePath = Join-Path $PSScriptRoot 'shared-governance.ps1'
if (-not (Test-Path -LiteralPath $sharedGovernancePath -PathType Leaf)) {
    throw "Missing shared governance helper '$sharedGovernancePath'."
}
. $sharedGovernancePath

$script:ValidatorCommand = 'validate-governance'
$script:ValidatorSoftWarnings = 0
$script:ValidatorMediumWarnings = 0
$script:ValidatorStartTime = [System.Diagnostics.Stopwatch]::StartNew()
$script:ValidatorMode = 'unscoped'
$script:ValidatorIterationsValidated = 0
$script:ValidatorTriggerSource = if ($env:CI) { 'ci' } else { 'local' }

function Write-ValidatorSummaryAndExit {
    param(
        [AllowNull()]
        [string]$ProjectRoot,

        [Parameter(Mandatory = $true)]
        [int]$ExitCode,

        [int]$HardWarnings = 0
    )

    $durationMs = if ($null -ne $script:ValidatorStartTime) {
        [int]$script:ValidatorStartTime.ElapsedMilliseconds
    }
    else {
        0
    }

    if (-not [string]::IsNullOrWhiteSpace($ProjectRoot)) {
        try {
            Write-SpecrewValidatorSummary `
                -ProjectRoot $ProjectRoot `
                -Command $script:ValidatorCommand `
                -SoftWarnings $script:ValidatorSoftWarnings `
                -MediumWarnings $script:ValidatorMediumWarnings `
                -HardWarnings $HardWarnings `
                -DurationMs $durationMs | Out-Null
        }
        catch {
        }
    }

    Write-Output ("[validator-timing] mode={0} elapsed_ms={1} iterations_validated={2} trigger_source={3}" -f $script:ValidatorMode, $durationMs, $script:ValidatorIterationsValidated, $script:ValidatorTriggerSource)
    exit $ExitCode
}

function Get-GitCurrentBranchName {
    param(
        [Parameter(Mandatory = $true)]
        [string]$ProjectRoot
    )

    $resolvedProjectRoot = Resolve-ProjectPath -Path $ProjectRoot
    $branchOutput = @(& git -C $resolvedProjectRoot branch --show-current 2>$null)
    if ($branchOutput.Count -eq 0) {
        return $null
    }

    $branchName = [string]$branchOutput[0]
    if ([string]::IsNullOrWhiteSpace($branchName)) {
        return $null
    }

    return $branchName.Trim()
}

function Get-ValidatorScopeReasonText {
    param(
        [AllowNull()]
        [string]$Reason,

        [AllowNull()]
        [string]$CurrentBranch
    )

    switch ($Reason) {
        'on-main' {
            if ($CurrentBranch -eq 'master') {
                return 'on master'
            }

            return 'on main'
        }
        'base-ref-undetectable' {
            return 'base-undetectable'
        }
        default {
            return $Reason
        }
    }
}

function Get-ValidatorScopeBanner {
    param(
        [Parameter(Mandatory = $true)]
        [ValidateSet('explicit-targets', 'changed-only', 'auto-scoped', 'full-repo')]
        [string]$Mode,

        [Parameter(Mandatory = $true)]
        [int]$IterationCount,

        [AllowNull()]
        [string]$BaseRef,

        [int]$DiffFileCount = 0,

        [AllowNull()]
        [string]$Reason,

        [AllowNull()]
        [string]$CurrentBranch
    )

    switch ($Mode) {
        'explicit-targets' {
            return "[validator-scope] explicit-targets ($IterationCount iterations)"
        }
        'changed-only' {
            return "[validator-scope] changed-only to $BaseRef...HEAD ($IterationCount iterations, $DiffFileCount files in diff)"
        }
        'auto-scoped' {
            return "[validator-scope] auto-scoped to $BaseRef...HEAD ($IterationCount iterations, $DiffFileCount files in diff)"
        }
        'full-repo' {
            $reasonText = Get-ValidatorScopeReasonText -Reason $Reason -CurrentBranch $CurrentBranch
            return "[validator-scope] full-repo ($reasonText; $IterationCount iterations)"
        }
    }
}

$copilotInstructionsClassifierPath = Join-Path $PSScriptRoot 'Test-CopilotInstructionsChangeType.ps1'
if (-not (Test-Path -LiteralPath $copilotInstructionsClassifierPath -PathType Leaf)) {
    throw "Missing copilot-instructions classifier helper '$copilotInstructionsClassifierPath'."
}
. $copilotInstructionsClassifierPath

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
$allowedProposalStatuses = @('candidate', 'draft', 'active', 'promoted', 'shipped', 'partially-shipped', 'superseded', 'withdrawn')
$postShipProposalStatuses = @('shipped', 'partially-shipped', 'superseded')
$postShipAmendmentRequiredFields = @('amendment-id', 'date', 'status', 'delta-summary', 'implementation-owner', 'preserve', 'tests-required')
$postShipAmendmentAllowedStatuses = @('proposed', 'accepted-unimplemented', 'active', 'implemented', 'rejected', 'superseded')

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
        # Pre-implement / pre-iteration-scaffold state: the spec exists but no iteration plan.md
        # has been written yet (T005 in the typical task plan creates it). This is NORMAL during
        # /speckit.specrew-speckit.after-tasks and the before-implement gate, so we emit a clear
        # INFO line and return zero iterations rather than throwing an "unexpected-validator-error".
        # Downstream checks see zero iterations and skip iteration-scoped work cleanly; the
        # script exits 0 with the summary "0 iterations validated", which is the truth.
        Write-Host ('[validator-info] No iteration directories with plan.md yet under {0}. This is expected pre-implementation; the iteration plan is scaffolded as the first implement task.' -f $specsPath) -ForegroundColor DarkYellow
        return @()
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

function Get-ProposalFrontMatterBounds {
    param(
        [AllowEmptyCollection()]
        [AllowEmptyString()]
        [string[]]$Lines
    )

    if ($Lines.Count -lt 2 -or $Lines[0].Trim() -ne '---') {
        return $null
    }

    for ($index = 1; $index -lt $Lines.Count; $index++) {
        if ($Lines[$index].Trim() -eq '---') {
            return [pscustomobject]@{
                StartLine = 1
                EndLine   = $index + 1
            }
        }
    }

    return $null
}

function Get-ProposalFrontMatterValue {
    param(
        [AllowEmptyCollection()]
        [AllowEmptyString()]
        [string[]]$Lines,

        [Parameter(Mandatory = $true)]
        [string]$Name
    )

    $bounds = Get-ProposalFrontMatterBounds -Lines $Lines
    if ($null -eq $bounds) {
        return $null
    }

    $pattern = '^\s*' + [regex]::Escape($Name) + '\s*:\s*(?<value>.+?)\s*$'
    for ($index = 1; $index -lt ($bounds.EndLine - 1); $index++) {
        if ($Lines[$index] -match $pattern) {
            $value = [string]$Matches['value']
            $value = ($value -replace '\s+#.*$', '').Trim().Trim('"').Trim("'")
            return $value
        }
    }

    return $null
}

function ConvertTo-NormalizedProposalSectionName {
    param([AllowNull()][string]$Value)

    if ([string]::IsNullOrWhiteSpace($Value)) {
        return '(preamble)'
    }

    return (($Value -replace '\s+', ' ').Trim()).ToLowerInvariant()
}

function Get-ProposalTopLevelSectionName {
    param(
        [AllowEmptyCollection()]
        [AllowEmptyString()]
        [string[]]$Lines,

        [Parameter(Mandatory = $true)]
        [int]$LineNumber
    )

    if ($LineNumber -le 0 -or $Lines.Count -eq 0) {
        return '(unknown)'
    }

    $bounds = Get-ProposalFrontMatterBounds -Lines $Lines
    if ($null -ne $bounds -and $LineNumber -ge $bounds.StartLine -and $LineNumber -le $bounds.EndLine) {
        return 'frontmatter'
    }

    $maxIndex = [Math]::Min($Lines.Count - 1, $LineNumber - 1)
    $current = '(preamble)'
    for ($index = 0; $index -le $maxIndex; $index++) {
        if ($Lines[$index] -match '^(?<marks>#{1,6})\s+(?<heading>.+?)\s*$') {
            $level = ([string]$Matches['marks']).Length
            if ($level -le 2) {
                $current = ConvertTo-NormalizedProposalSectionName -Value $Matches['heading']
            }
        }
    }

    return $current
}

function Test-AllowedPostShipProposalDirectEdit {
    param(
        [AllowNull()][string]$Section,
        [AllowNull()][string]$LineText
    )

    if ([string]::IsNullOrWhiteSpace($LineText)) {
        return $true
    }

    $normalizedSection = ConvertTo-NormalizedProposalSectionName -Value $Section
    if ($normalizedSection -in @('post-ship amendments', 'status history', 'cross-references', 'errata', 'historical errata', 'typo and link corrections', 'corrections')) {
        return $true
    }

    if ($normalizedSection -eq 'frontmatter') {
        return [bool]($LineText -match '^\s*(?:status|superseded-by|supersedes|replaced-by|replacement-proposal|replacement|discussion)\s*:')
    }

    return $false
}

function Get-ProposalDiffChangedLines {
    param(
        [Parameter(Mandatory = $true)][string]$ProjectRoot,
        [Parameter(Mandatory = $true)][string]$BaseRef,
        [Parameter(Mandatory = $true)][string]$RelativePath
    )

    $diffArgs = @('diff', '--unified=0', '--diff-filter=ACMRT', "$BaseRef...HEAD", '--', $RelativePath)
    $diffLines = @(& git -C $ProjectRoot @diffArgs 2>$null)
    if ($LASTEXITCODE -ne 0) {
        return @()
    }

    $changes = New-Object System.Collections.Generic.List[object]
    $oldCursor = 0
    $newCursor = 0
    foreach ($lineObject in $diffLines) {
        $line = [string]$lineObject
        $hunkMatch = [regex]::Match($line, '^@@\s+-(?<oldStart>\d+)(?:,(?<oldCount>\d+))?\s+\+(?<newStart>\d+)(?:,(?<newCount>\d+))?\s+@@')
        if ($hunkMatch.Success) {
            $oldCursor = [int]$hunkMatch.Groups['oldStart'].Value
            $newCursor = [int]$hunkMatch.Groups['newStart'].Value
            continue
        }

        if ($line.StartsWith('+++') -or $line.StartsWith('---')) {
            continue
        }

        if ($line.StartsWith('+')) {
            $null = $changes.Add([pscustomobject]@{
                    Side       = 'current'
                    LineNumber = $newCursor
                    Text       = $line.Substring(1)
                })
            $newCursor++
            continue
        }

        if ($line.StartsWith('-')) {
            $null = $changes.Add([pscustomobject]@{
                    Side       = 'baseline'
                    LineNumber = $oldCursor
                    Text       = $line.Substring(1)
                })
            $oldCursor++
            continue
        }

        if ($line.StartsWith(' ')) {
            $oldCursor++
            $newCursor++
        }
    }

    return $changes.ToArray()
}

function Get-GitBlobLines {
    param(
        [Parameter(Mandatory = $true)][string]$ProjectRoot,
        [Parameter(Mandatory = $true)][string]$Ref,
        [Parameter(Mandatory = $true)][string]$RelativePath
    )

    $blobText = @(& git -C $ProjectRoot show "$Ref`:$RelativePath" 2>$null)
    if ($LASTEXITCODE -ne 0) {
        return @()
    }

    return @($blobText | ForEach-Object { [string]$_ })
}

function Get-PostShipAmendmentSection {
    param(
        [AllowEmptyCollection()]
        [AllowEmptyString()]
        [string[]]$Lines
    )

    $startIndex = -1
    for ($index = 0; $index -lt $Lines.Count; $index++) {
        if ($Lines[$index] -match '^##\s+Post-Ship Amendments\b') {
            $startIndex = $index
            break
        }
    }

    if ($startIndex -lt 0) {
        return $null
    }

    $sectionLines = New-Object System.Collections.Generic.List[string]
    for ($index = $startIndex + 1; $index -lt $Lines.Count; $index++) {
        if ($Lines[$index] -match '^##\s+') {
            break
        }

        $null = $sectionLines.Add($Lines[$index])
    }

    return [pscustomobject]@{
        StartLine = $startIndex + 2
        Lines     = $sectionLines.ToArray()
    }
}

function Get-PostShipAmendmentField {
    param([AllowNull()][string]$Line)

    if ([string]::IsNullOrWhiteSpace($Line)) {
        return $null
    }

    $fieldPattern = '(?<key>amendment-id|date|status|delta-summary|implementation-owner|preserve|tests-required)'
    $bulletMatch = [regex]::Match($Line, '^\s*(?:[-*]\s*)?(?:\*\*)?' + $fieldPattern + '(?:\*\*)?\s*:\s*(?<value>.*?)\s*$', [System.Text.RegularExpressions.RegexOptions]::IgnoreCase)
    if ($bulletMatch.Success) {
        return [pscustomobject]@{
            Key   = $bulletMatch.Groups['key'].Value.ToLowerInvariant()
            Value = $bulletMatch.Groups['value'].Value.Trim()
        }
    }

    $tableMatch = [regex]::Match($Line, '^\s*\|\s*' + $fieldPattern + '\s*\|\s*(?<value>[^|]+)\|', [System.Text.RegularExpressions.RegexOptions]::IgnoreCase)
    if ($tableMatch.Success) {
        return [pscustomobject]@{
            Key   = $tableMatch.Groups['key'].Value.ToLowerInvariant()
            Value = $tableMatch.Groups['value'].Value.Trim()
        }
    }

    return $null
}

function Get-PostShipAmendmentRecords {
    param(
        [AllowNull()]
        [object]$Section
    )

    if ($null -eq $Section) {
        return @()
    }

    $records = New-Object System.Collections.Generic.List[object]
    $current = [ordered]@{}
    $currentStartLine = [int]$Section.StartLine

    for ($index = 0; $index -lt $Section.Lines.Count; $index++) {
        $field = Get-PostShipAmendmentField -Line $Section.Lines[$index]
        if ($null -eq $field) {
            continue
        }

        if ($field.Key -eq 'amendment-id' -and $current.Count -gt 0 -and $current.Contains('amendment-id')) {
            $null = $records.Add([pscustomobject]@{
                    StartLine = $currentStartLine
                    Fields    = $current
                })
            $current = [ordered]@{}
            $currentStartLine = [int]$Section.StartLine + $index
        }

        if ($current.Count -eq 0) {
            $currentStartLine = [int]$Section.StartLine + $index
        }

        $current[$field.Key] = $field.Value
    }

    if ($current.Count -gt 0) {
        $null = $records.Add([pscustomobject]@{
                StartLine = $currentStartLine
                Fields    = $current
            })
    }

    return $records.ToArray()
}

function Test-PostShipAmendmentRecords {
    param(
        [Parameter(Mandatory = $true)][string]$RelativePath,
        [AllowNull()][object]$Section
    )

    $records = @(Get-PostShipAmendmentRecords -Section $Section)
    foreach ($record in $records) {
        $fields = $record.Fields
        $amendmentId = if ($fields.Contains('amendment-id') -and -not [string]::IsNullOrWhiteSpace([string]$fields['amendment-id'])) {
            [string]$fields['amendment-id']
        }
        else {
            '(missing amendment-id)'
        }

        $missingFields = @(
            $postShipAmendmentRequiredFields |
                Where-Object {
                    -not $fields.Contains($_) -or [string]::IsNullOrWhiteSpace([string]$fields[$_])
                }
        )
        if ($missingFields.Count -gt 0) {
            Write-PostShipProposalWarning -Category 'malformed-amendment' -Detail ("{0} amendment {1} is missing required fields: {2}" -f $RelativePath, $amendmentId, ($missingFields -join ', '))
        }

        if ($fields.Contains('status') -and -not [string]::IsNullOrWhiteSpace([string]$fields['status'])) {
            $status = ([string]$fields['status']).Trim().ToLowerInvariant()
            if ($status -notin $postShipAmendmentAllowedStatuses) {
                Write-PostShipProposalWarning -Category 'malformed-amendment' -Detail ("{0} amendment {1} has invalid status '{2}' (expected one of: {3})" -f $RelativePath, $amendmentId, $status, ($postShipAmendmentAllowedStatuses -join ', '))
            }
        }
    }
}

function Test-PostShipProposalAmendmentGovernance {
    param(
        [Parameter(Mandatory = $true)]
        [string]$ProjectRoot
    )

    $baseRef = Get-SpecrewLocalScopeBaseRef -ProjectRoot $ProjectRoot
    if ([string]::IsNullOrWhiteSpace($baseRef)) {
        return
    }

    $diffArgs = @('diff', '--name-only', '--diff-filter=ACMRT', "$baseRef...HEAD", '--', 'proposals/*.md')
    $changedProposalFiles = @(
        & git -C $ProjectRoot @diffArgs 2>$null |
            ForEach-Object { ([string]$_).Trim() } |
            Where-Object { -not [string]::IsNullOrWhiteSpace($_) -and $_ -ne 'proposals/INDEX.md' }
    )
    if ($LASTEXITCODE -ne 0 -or $changedProposalFiles.Count -eq 0) {
        return
    }

    foreach ($relativePath in @($changedProposalFiles | Sort-Object -Unique)) {
        $proposalPath = Join-Path -Path $ProjectRoot -ChildPath $relativePath
        if (-not (Test-Path -LiteralPath $proposalPath -PathType Leaf)) {
            continue
        }

        $currentLines = Get-MarkdownContent -Path $proposalPath
        $status = Get-ProposalFrontMatterValue -Lines $currentLines -Name 'status'
        $normalizedStatus = if ([string]::IsNullOrWhiteSpace($status)) { '' } else { $status.Trim().ToLowerInvariant() }
        if ($normalizedStatus -notin $allowedProposalStatuses) {
            Write-PostShipProposalWarning -Category 'proposal-status' -Detail ("{0} has missing or unknown status '{1}'; skipped shipped/superseded mutability checks." -f $relativePath, $(if ([string]::IsNullOrWhiteSpace($status)) { '(missing)' } else { $status }))
            continue
        }

        if ($normalizedStatus -notin $postShipProposalStatuses) {
            continue
        }

        $amendmentSection = Get-PostShipAmendmentSection -Lines $currentLines
        Test-PostShipAmendmentRecords -RelativePath $relativePath -Section $amendmentSection

        $baselineLines = Get-GitBlobLines -ProjectRoot $ProjectRoot -Ref $baseRef -RelativePath $relativePath
        $changedLines = @(Get-ProposalDiffChangedLines -ProjectRoot $ProjectRoot -BaseRef $baseRef -RelativePath $relativePath)
        $unsafeSections = New-Object System.Collections.Generic.List[string]

        foreach ($change in $changedLines) {
            $linesForSection = if ($change.Side -eq 'baseline') { $baselineLines } else { $currentLines }
            $section = Get-ProposalTopLevelSectionName -Lines $linesForSection -LineNumber ([int]$change.LineNumber)
            if (Test-AllowedPostShipProposalDirectEdit -Section $section -LineText ([string]$change.Text)) {
                continue
            }

            $sectionLabel = if ([string]::IsNullOrWhiteSpace($section)) { '(unknown)' } else { $section }
            if (-not $unsafeSections.Contains($sectionLabel)) {
                $null = $unsafeSections.Add($sectionLabel)
            }
        }

        if ($unsafeSections.Count -gt 0) {
            Write-PostShipProposalWarning -Category 'normative-body-edit' -Detail ("{0} changed {1} proposal sections outside Post-Ship Amendments: {2}. Use a Post-Ship Amendments entry or a new/superseding proposal; direct edits are limited to typo/link/errata/status-history/cross-reference/supersession metadata." -f $relativePath, $normalizedStatus, (($unsafeSections.ToArray() | Sort-Object) -join ', '))
        }
    }
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

function Test-ReviewEvidenceTreeIntegrity {
    <#
    Pillar 5 (Proposal 120 / FR-022, AC9-AC11): when an iteration's review.md is accepted (or the
    iteration is at retro/complete), production files cited as delivered evidence MUST exist in the
    cited "Tree Under Review" commit. A production file cited + present in the working tree + absent
    from the cited commit is the Shape-5 working-tree-only lie → FAIL (gates iteration-closeout).
    Test files → WARN (AC10); cited-but-nonexistent prod files → WARN. Pre-2026-05-27 iterations
    without a Tree Under Review field are unaffected (helper returns no hash).
    #>
    param(
        [string[]]$ReviewLines,
        [string]$ProjectRoot,
        [string]$IterationDirectory,
        [string]$OverallVerdict,
        [string]$IterationStatus,
        [System.Collections.Generic.List[string]]$Errors
    )

    if ($OverallVerdict -ne 'accepted' -and $IterationStatus -notin @('retro', 'complete')) {
        return
    }

    $treeCheck = Test-ReviewCitedFilesInTree -ReviewLines $ReviewLines -ProjectRoot $ProjectRoot
    if ($null -eq $treeCheck -or $null -eq $treeCheck.TreeHash) {
        return
    }

    $relativeIteration = ([System.IO.Path]::GetRelativePath($ProjectRoot, $IterationDirectory)) -replace '/', '\'

    if (-not $treeCheck.TreeResolved) {
        Write-TrustHardeningWarning -Category 'review-tree-unresolved' -Detail ("review.md for {0} cites Tree Under Review '{1}' but git ls-tree could not resolve it; Pillar 5 verification was skipped." -f $relativeIteration, $treeCheck.TreeHash)
        return
    }

    foreach ($missing in @($treeCheck.MissingProduction)) {
        $Errors.Add(("review.md (FR-022/Pillar 5) cites production evidence file '{0}' that is present in the working tree but absent from the cited Tree Under Review commit '{1}' for {2}. Either stage + commit the file then re-issue the verdict, or remove it from review.md evidence." -f $missing, $treeCheck.TreeHash, $relativeIteration))
    }

    foreach ($missingTest in @($treeCheck.MissingTest)) {
        Write-TrustHardeningWarning -Category 'review-cited-test-not-in-tree' -Detail ("review.md for {0} cites test file '{1}' that is absent from the cited Tree Under Review commit '{2}'." -f $relativeIteration, $missingTest, $treeCheck.TreeHash)
    }

    foreach ($unresolvedCited in @($treeCheck.UnresolvedCited)) {
        Write-TrustHardeningWarning -Category 'review-cited-file-missing' -Detail ("review.md for {0} cites production file '{1}' that is absent from both the cited tree '{2}' and the working tree (possible stale/typo reference)." -f $relativeIteration, $unresolvedCited, $treeCheck.TreeHash)
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

function Add-RepoStructuredValidationFailure {
    param(
        [AllowEmptyCollection()]
        [Parameter(Mandatory = $true)]
        [System.Collections.Generic.List[string]]$Errors,

        [Parameter(Mandatory = $true)]
        [string]$ProjectRoot,

        [AllowNull()][string]$TargetPath,
        [AllowNull()][int]$LineNumber,
        [Parameter(Mandatory = $true)][string]$Category,
        [Parameter(Mandatory = $true)][string]$Message,
        [Parameter(Mandatory = $true)][string]$RemediationHint
    )

    $relativePath = if ([string]::IsNullOrWhiteSpace($TargetPath)) {
        '(none)'
    }
    else {
        Convert-ToRepoMarkdownPath -ProjectRoot $ProjectRoot -TargetPath $TargetPath
    }

    Add-StructuredValidationFailure -Errors $Errors -FilePath $relativePath -LineNumber $LineNumber -Category $Category -Message $Message -RemediationHint $RemediationHint
}

function Write-PublicReadinessWarning {
    param(
        [Parameter(Mandatory = $true)][string]$Category,
        [Parameter(Mandatory = $true)][string]$Detail
    )

    $script:ValidatorSoftWarnings++
    Write-Host ("WARN [public-readiness] {0}: {1}" -f $Category.Trim(), $Detail.Trim()) -ForegroundColor Yellow
}

function Write-DashboardGovernanceWarning {
    param(
        [Parameter(Mandatory = $true)][string]$Category,
        [Parameter(Mandatory = $true)][string]$Detail
    )

    $script:ValidatorSoftWarnings++
    Write-Host ("WARN [dashboard] {0}: {1}" -f $Category.Trim(), $Detail.Trim()) -ForegroundColor Yellow
}

function Write-TrustHardeningWarning {
    param(
        [Parameter(Mandatory = $true)][string]$Category,
        [Parameter(Mandatory = $true)][string]$Detail
    )

    $script:ValidatorSoftWarnings++
    Write-Host ("WARN [trust-hardening] {0}: {1}" -f $Category.Trim(), $Detail.Trim()) -ForegroundColor Yellow
}

function Write-PostShipProposalWarning {
    param(
        [Parameter(Mandatory = $true)][string]$Category,
        [Parameter(Mandatory = $true)][string]$Detail
    )

    $script:ValidatorSoftWarnings++
    Write-Host ("WARN [post-ship-proposal] {0}: {1}" -f $Category.Trim(), $Detail.Trim()) -ForegroundColor Yellow
}

function Get-ObjectPropertyString {
    param(
        [AllowNull()][object]$InputObject,
        [Parameter(Mandatory = $true)][string[]]$Names
    )

    if ($null -eq $InputObject) {
        return ''
    }

    if ($InputObject -is [System.Collections.IDictionary] -or $InputObject -is [System.Collections.Specialized.IOrderedDictionary]) {
        foreach ($name in $Names) {
            if ($InputObject.Contains($name) -and -not [string]::IsNullOrWhiteSpace([string]$InputObject[$name])) {
                return [string]$InputObject[$name]
            }
        }

        return ''
    }

    foreach ($name in $Names) {
        $property = @($InputObject.PSObject.Properties | Where-Object { $_.Name -eq $name } | Select-Object -First 1)
        if ($property.Count -gt 0) {
            $property = $property[0]
        }
        else {
            $property = $null
        }
        if ($null -ne $property -and -not [string]::IsNullOrWhiteSpace([string]$property.Value)) {
            return [string]$property.Value
        }
    }

    return ''
}

function Get-ObjectPropertyBool {
    param(
        [AllowNull()][object]$InputObject,
        [Parameter(Mandatory = $true)][string[]]$Names
    )

    if ($null -eq $InputObject) {
        return $false
    }

    if ($InputObject -is [System.Collections.IDictionary] -or $InputObject -is [System.Collections.Specialized.IOrderedDictionary]) {
        foreach ($name in $Names) {
            if (-not $InputObject.Contains($name)) {
                continue
            }

            $rawValue = [string]$InputObject[$name]
            if ($rawValue -match '^(?i:true|1|yes)$') {
                return $true
            }
        }

        return $false
    }

    foreach ($name in $Names) {
        $property = @($InputObject.PSObject.Properties | Where-Object { $_.Name -eq $name } | Select-Object -First 1)
        if ($property.Count -gt 0) {
            $property = $property[0]
        }
        else {
            $property = $null
        }
        if ($null -eq $property) {
            continue
        }

        $rawValue = [string]$property.Value
        if ($rawValue -match '^(?i:true|1|yes)$') {
            return $true
        }
    }

    return $false
}

function Get-SpecrewHandoffBlocks {
    param([AllowEmptyString()][AllowNull()][string]$Content)

    if ([string]::IsNullOrWhiteSpace($Content)) {
        return @()
    }

    return @(
        [regex]::Matches($Content, '(?ms)===\s*SPECREW HANDOFF\s*===(?<body>.+?)===\s*END SPECREW HANDOFF\s*===') |
            ForEach-Object { [string]$_.Value }
    )
}

function Test-HandoffEvidenceGovernance {
    # Proposal 120 Pillar 1 (FR-018): detect missing === SPECREW HANDOFF === evidence at boundary/
    # lifecycle stops. Shipped in F-047; certified live in F-049 i004 once Add-SpecrewHandoffEvidence
    # (T006) populates .specrew/handoff-evidence.json from real boundary syncs.
    param([Parameter(Mandatory = $true)][string]$ProjectRoot)

    $evidencePath = Join-Path $ProjectRoot '.specrew\handoff-evidence.json'
    if (-not (Test-Path -LiteralPath $evidencePath -PathType Leaf)) {
        return 0
    }

    try {
        $raw = Get-Content -LiteralPath $evidencePath -Raw -Encoding UTF8
        $parsed = $raw | ConvertFrom-Json -AsHashtable -Depth 12
    }
    catch {
        Write-TrustHardeningWarning -Category 'handoff-evidence-unreadable' -Detail ("Could not parse {0}; handoff-block validation evidence was skipped." -f (Convert-ToRepoMarkdownPath -ProjectRoot $ProjectRoot -TargetPath $evidencePath))
        return 0
    }

    $events = @()
    if ($parsed -is [array]) {
        $events = @($parsed)
    }
    elseif (($parsed -is [System.Collections.IDictionary] -or $parsed -is [System.Collections.Specialized.IOrderedDictionary]) -and $parsed.Contains('boundary_events')) {
        $events = @($parsed['boundary_events'])
    }
    elseif (($parsed -is [System.Collections.IDictionary] -or $parsed -is [System.Collections.Specialized.IOrderedDictionary]) -and $parsed.Contains('events')) {
        $events = @($parsed['events'])
    }
    else {
        $boundaryEvents = @($parsed | Select-Object -ExpandProperty boundary_events -ErrorAction SilentlyContinue)
        $legacyEvents = @($parsed | Select-Object -ExpandProperty events -ErrorAction SilentlyContinue)
        if ($boundaryEvents.Count -gt 0) {
            $events = $boundaryEvents
        }
        elseif ($legacyEvents.Count -gt 0) {
            $events = $legacyEvents
        }
        else {
            $events = @($parsed)
        }
    }
    $flattenedEvents = New-Object System.Collections.Generic.List[object]
    foreach ($candidateEvent in $events) {
        if ($candidateEvent -is [array]) {
            foreach ($innerEvent in $candidateEvent) {
                $flattenedEvents.Add($innerEvent) | Out-Null
            }
        }
        else {
            $flattenedEvents.Add($candidateEvent) | Out-Null
        }
    }
    $events = @($flattenedEvents.ToArray())

    $hardFailureCount = 0
    $handoffValidatorScript = Join-Path (Split-Path -Parent $PSScriptRoot) 'validators\handoff-governance-validator.ps1'
    $latestPacketEvidenceByBoundary = @{}
    for ($eventIndex = 0; $eventIndex -lt $events.Count; $eventIndex++) {
        $event = $events[$eventIndex]
        $boundary = Get-ObjectPropertyString -InputObject $event -Names @('boundary', 'boundary_type', 'BoundaryType')
        if ([string]::IsNullOrWhiteSpace($boundary)) {
            $boundary = '__unknown_boundary__'
        }
        $latestPacketEvidenceByBoundary[$boundary] = $eventIndex
    }

    $eventIndex = -1
    foreach ($event in $events) {
        $eventIndex++
        $commit = Get-ObjectPropertyString -InputObject $event -Names @('commit', 'commit_hash', 'CommitHash')
        $boundary = Get-ObjectPropertyString -InputObject $event -Names @('boundary', 'boundary_type', 'BoundaryType')
        $hasCompactionMarker = Get-ObjectPropertyBool -InputObject $event -Names @('compaction_marker', 'post_compaction', 'PostCompaction')
        $commitMessage = Get-ObjectPropertyString -InputObject $event -Names @('commit_message', 'CommitMessage')
        $responseText = Get-ObjectPropertyString -InputObject $event -Names @('response_text', 'ResponseText', 'handoff_text', 'HandoffText', 'text', 'Text')
        $hasHandoffBlock = Test-SpecrewHandoffBlockPresent -CommitMessage $commitMessage -SessionMetadata $event
        $packetValidationBoundary = if ([string]::IsNullOrWhiteSpace($boundary)) { '__unknown_boundary__' } else { $boundary }
        $isLatestPacketEvidenceForBoundary = $latestPacketEvidenceByBoundary.ContainsKey($packetValidationBoundary) -and $latestPacketEvidenceByBoundary[$packetValidationBoundary] -eq $eventIndex

        if ($isLatestPacketEvidenceForBoundary -and -not [string]::IsNullOrWhiteSpace($responseText)) {
            if (Test-Path -LiteralPath $handoffValidatorScript -PathType Leaf) {
                $validatorArgs = @{
                    ProjectRoot = $ProjectRoot
                    ResponseText = $responseText
                    ResponseScope = 'boundary-handoff'
                    BarePathBoundaryHandoffSeverity = 'validation-fail'
                }
                if (-not [string]::IsNullOrWhiteSpace($boundary)) {
                    $validatorArgs['BoundaryName'] = $boundary
                }

                $packetOutput = @(& pwsh -NoProfile -ExecutionPolicy Bypass -File $handoffValidatorScript @validatorArgs 2>&1)
                if ($LASTEXITCODE -ne 0) {
                    $hardFailureCount++
                    $label = if ([string]::IsNullOrWhiteSpace($commit)) { '(unknown commit)' } else { $commit }
                    if (-not [string]::IsNullOrWhiteSpace($boundary)) {
                        $label = "$label at $boundary"
                    }
                    Write-Host ("FAIL [trust-hardening] handoff-evidence-packet-invalid: Boundary packet evidence for {0} failed handoff governance validation." -f $label) -ForegroundColor Red
                    foreach ($line in $packetOutput) {
                        Write-Host ("  {0}" -f $line) -ForegroundColor Red
                    }
                }
            }
            else {
                Write-TrustHardeningWarning -Category 'handoff-evidence-validator-missing' -Detail ("Could not find handoff validator at {0}; packet evidence validation was skipped." -f (Convert-ToRepoMarkdownPath -ProjectRoot $ProjectRoot -TargetPath $handoffValidatorScript))
            }
        }

        if ($hasHandoffBlock) {
            continue
        }

        $label = if ([string]::IsNullOrWhiteSpace($commit)) { '(unknown commit)' } else { $commit }
        if (-not [string]::IsNullOrWhiteSpace($boundary)) {
            $label = "$label at $boundary"
        }

        if ($hasCompactionMarker) {
            Write-TrustHardeningWarning -Category 'post-compaction-handoff-drop' -Detail ("Boundary commit {0} has compaction metadata but no preceding SPECREW HANDOFF block." -f $label)
        }
        else {
            Write-TrustHardeningWarning -Category 'handoff-block-missing' -Detail ("Boundary commit {0} has no preceding SPECREW HANDOFF block in session evidence." -f $label)
        }
    }

    return $hardFailureCount
}

function Test-WrongLocationCanonicalArtifacts {
    # Proposal 120 Pillar 3 (FR-020): detect canonical artifacts written to ephemeral host
    # session-scratch locations. Shipped in F-047; runs on every validation (certified live F-049 i004).
    param([Parameter(Mandatory = $true)][string]$ProjectRoot)

    $artifactNames = @(
        'review.md',
        'retro.md',
        'reviewer-index.md',
        'review-diagrams.md',
        'code-map.md',
        'coverage-evidence.md',
        'dependency-report.md',
        'hardening-gate.md',
        'dashboard.md',
        'closeout-dashboard.md'
    )

    $ephemeralRoots = @(
        (Join-Path $ProjectRoot '.gemini'),
        (Join-Path $ProjectRoot '.antigravitycli')
    )

    foreach ($root in $ephemeralRoots) {
        if (-not (Test-Path -LiteralPath $root -PathType Container)) {
            continue
        }

        foreach ($file in @(Get-ChildItem -LiteralPath $root -Recurse -File -ErrorAction SilentlyContinue)) {
            if ($artifactNames -notcontains $file.Name) {
                continue
            }

            $relativePath = Convert-ToRepoMarkdownPath -ProjectRoot $ProjectRoot -TargetPath $file.FullName
            Write-TrustHardeningWarning -Category 'canonical-artifact-wrong-location' -Detail ("Canonical lifecycle artifact '{0}' was found under an ephemeral host-scratch path: {1}" -f $file.Name, $relativePath)
        }
    }
}

function Test-HandoffInternalReferenceSurfaces {
    param([Parameter(Mandatory = $true)][string]$ProjectRoot)

    $internalReferencePattern = '\b(?:F-\d{3,}|Proposal\s+\d{3,}|Feature\s+\d{3,})\b'
    $candidatePaths = New-Object System.Collections.Generic.List[string]
    $excludedSegments = [System.Collections.Generic.HashSet[string]]::new([System.StringComparer]::OrdinalIgnoreCase)
    foreach ($segment in @('.git', '.specrew', '.squad', '.scratch', '.agents', '.antigravitycli', '.claude', '.codex', '.github', 'docs', 'proposals', 'specs', 'tests')) {
        $excludedSegments.Add($segment) | Out-Null
    }

    foreach ($file in @(Get-ChildItem -LiteralPath $ProjectRoot -Recurse -Filter '*.md' -File -ErrorAction SilentlyContinue)) {
        $relativePath = Convert-ToRepoMarkdownPath -ProjectRoot $ProjectRoot -TargetPath $file.FullName
        $firstSegment = ($relativePath -split '/')[0]
        if ($excludedSegments.Contains($firstSegment)) {
            continue
        }

        $candidatePaths.Add($file.FullName) | Out-Null
    }

    foreach ($extraPath in @(
            (Join-Path $ProjectRoot 'scripts\specrew-start.ps1'),
            (Join-Path $ProjectRoot 'extensions\specrew-speckit\prompts\coordinator-response.md'),
            (Join-Path $ProjectRoot 'extensions\specrew-speckit\prompts\coordinator-decision-guidance.md')
        )) {
        if ((Test-Path -LiteralPath $extraPath -PathType Leaf) -and -not $candidatePaths.Contains($extraPath)) {
            $candidatePaths.Add($extraPath) | Out-Null
        }
    }

    foreach ($path in $candidatePaths.ToArray()) {
        try {
            $content = Get-Content -LiteralPath $path -Raw -Encoding UTF8
        }
        catch {
            continue
        }

        $blocks = @(Get-SpecrewHandoffBlocks -Content $content)
        if ($blocks.Count -eq 0) {
            continue
        }

        foreach ($block in $blocks) {
            foreach ($match in [regex]::Matches($block, $internalReferencePattern)) {
                Write-TrustHardeningWarning -Category 'internal-reference-in-handoff' -Detail ("Internal reference '{0}' appears inside a SPECREW HANDOFF block in {1}." -f $match.Value, (Convert-ToRepoMarkdownPath -ProjectRoot $ProjectRoot -TargetPath $path))
            }
        }
    }
}

function Test-ReviewDiagramsMermaidBlock {
    param(
        [Parameter(Mandatory = $true)][string]$IterationDirectory,
        [Parameter(Mandatory = $true)][string]$ProjectRoot
    )

    $reviewDiagramsPath = Join-Path $IterationDirectory 'review-diagrams.md'
    if (-not (Test-Path -LiteralPath $reviewDiagramsPath -PathType Leaf)) {
        return
    }

    try {
        $content = Get-Content -LiteralPath $reviewDiagramsPath -Raw -Encoding UTF8
    }
    catch {
        return
    }

    if ($content -notmatch '(?m)^```\s*mermaid\s*$') {
        Write-TrustHardeningWarning -Category 'review-diagrams-missing-mermaid' -Detail ("review-diagrams.md exists but contains no mermaid fence: {0}" -f (Convert-ToRepoMarkdownPath -ProjectRoot $ProjectRoot -TargetPath $reviewDiagramsPath))
    }
}

function Get-MissingDashboardDiagnosis {
    # Proposal 120 Pillar 2 (FR-019): distinguish a trigger-bypass artifact gap (closed iteration
    # missing dashboard.md) from a generic missing-artifact failure. Shipped in F-047; fired live in
    # real F-049 runs (missing-dashboard-non-specrew-managed / -auto-render-regression).
    param(
        [Parameter(Mandatory = $true)][string]$IterationDirectory
    )

    $specrewManagedMarkers = @('plan.md', 'state.md', 'review.md', 'retro.md') |
        Where-Object { Test-Path -LiteralPath (Join-Path $IterationDirectory $_) -PathType Leaf }

    if (@($specrewManagedMarkers).Count -ge 2) {
        return [pscustomobject]@{
            Category = 'missing-dashboard-auto-render-regression'
            DetailPrefix = 'Specrew-managed closed iteration is missing dashboard.md; auto-render regression suspected'
        }
    }

    return [pscustomobject]@{
        Category = 'missing-dashboard-non-specrew-managed'
        DetailPrefix = 'Closed iteration is missing dashboard.md but does not have enough Specrew-managed markers; likely non-Specrew-managed history'
    }
}

function Get-DeclaredSpecrewVersion {
    param([string]$ProjectRoot)

    $configPath = Join-Path $ProjectRoot '.specrew\config.yml'
    if (-not (Test-Path -LiteralPath $configPath -PathType Leaf)) {
        return $null
    }

    try {
        foreach ($line in Get-MarkdownContent -Path $configPath) {
            if ($line -match '^\s*specrew_version:\s*"?(?<version>[^"#]+?)"?\s*$') {
                return $Matches['version'].Trim()
            }
        }
    }
    catch {
        return $null
    }

    return $null
}

function Get-ExtensionManifestVersion {
    param(
        [Parameter(Mandatory = $true)]
        [string]$ManifestPath
    )

    if (-not (Test-Path -LiteralPath $ManifestPath -PathType Leaf)) {
        return $null
    }

    try {
        foreach ($line in Get-MarkdownContent -Path $ManifestPath) {
            if ($line -match '^\s*version:\s*"?(?<version>[^"#]+?)"?\s*$') {
                return $Matches['version'].Trim()
            }
        }
    }
    catch {
        return $null
    }

    return $null
}

function Test-BoundaryStateAdvanceVerdict {
    <#
    Pillar 4 (Proposal 120 / FR-021, AC7): live session-state counterpart to the boundary-sync
    hard-block. If the active session's recorded boundary is a human-judgment boundary
    (before-implement | review-signoff | iteration-closeout | feature-closeout) but
    boundary_enforcement.verdict_history has no matching `to_boundary` entry with a non-empty
    authorizing_human, the state advanced without a recorded human verdict -> WARN. This catches the
    silent-state-progression class (PlanningPoC iter-002 Picard catch; the F-049 i005 stale-cursor
    skip) at validation time; the recording-path repair (T005) prevents it at sync time.
    #>
    param([Parameter(Mandatory = $true)][string]$ProjectRoot)

    $contextPath = Join-Path $ProjectRoot '.specrew\start-context.json'
    if (-not (Test-Path -LiteralPath $contextPath -PathType Leaf)) { return }

    try {
        $context = Get-Content -LiteralPath $contextPath -Raw -Encoding UTF8 | ConvertFrom-Json -Depth 20
    }
    catch {
        Write-TrustHardeningWarning -Category 'boundary-enforcement-unreadable' -Detail 'Could not parse .specrew/start-context.json; state-advance-without-verdict check was skipped.'
        return
    }

    # Direct PSObject.Properties access (NOT Get-ObjectPropertyString): validate-governance.ps1
    # defines that helper twice with different parameter names (-Names vs -PropertyNames); the later
    # definition shadows the first, so -Names silently returns null. Direct access is unambiguous.
    $sessionState = $context.PSObject.Properties['session_state']
    if ($null -eq $sessionState -or $null -eq $sessionState.Value) { return }
    $btProp = $sessionState.Value.PSObject.Properties['boundary_type']
    $boundary = if ($null -ne $btProp) { [string]$btProp.Value } else { '' }
    if ([string]::IsNullOrWhiteSpace($boundary)) { return }

    $humanVerdictBoundaries = @('before-implement', 'review-signoff', 'iteration-closeout', 'feature-closeout')
    if ($boundary -notin $humanVerdictBoundaries) { return }

    $enforcement = $context.PSObject.Properties['boundary_enforcement']
    $history = @()
    if ($null -ne $enforcement -and $null -ne $enforcement.Value -and $null -ne $enforcement.Value.PSObject.Properties['verdict_history']) {
        $history = @($enforcement.Value.verdict_history)
    }

    $authorized = @($history | Where-Object {
            $null -ne $_ -and
            $null -ne $_.PSObject.Properties['to_boundary'] -and
            ([string]$_.PSObject.Properties['to_boundary'].Value -eq $boundary) -and
            $null -ne $_.PSObject.Properties['authorizing_human'] -and
            (-not [string]::IsNullOrWhiteSpace([string]$_.PSObject.Properties['authorizing_human'].Value))
        })

    if ($authorized.Count -eq 0) {
        $iterProp = $sessionState.Value.PSObject.Properties['iteration_number']
        $iterationRef = if ($null -ne $iterProp) { [string]$iterProp.Value } else { '' }
        Write-TrustHardeningWarning -Category 'state-advance-without-verdict' -Detail ("Active session boundary advanced to human-judgment gate '{0}' (iteration {1}) without a matching boundary_enforcement.verdict_history entry naming an authorizing human. Record the human verdict explicitly or roll the boundary back." -f $boundary, $(if ([string]::IsNullOrWhiteSpace($iterationRef)) { '(unknown)' } else { $iterationRef }))
    }
}

function Test-ApprovedFeatureStatusVerdictEvidence {
    param([Parameter(Mandatory = $true)][string]$ProjectRoot)

    $contextPath = Join-Path $ProjectRoot '.specrew\start-context.json'
    if (-not (Test-Path -LiteralPath $contextPath -PathType Leaf)) { return 0 }

    try {
        $context = Get-Content -LiteralPath $contextPath -Raw -Encoding UTF8 | ConvertFrom-Json -Depth 20
    }
    catch {
        return 0
    }

    $sessionState = $context.PSObject.Properties['session_state']
    if ($null -eq $sessionState -or $null -eq $sessionState.Value) { return 0 }

    $featurePathProp = $sessionState.Value.PSObject.Properties['feature_path']
    $featurePath = if ($null -ne $featurePathProp) { [string]$featurePathProp.Value } else { '' }
    if ([string]::IsNullOrWhiteSpace($featurePath)) { return 0 }
    if (-not [System.IO.Path]::IsPathRooted($featurePath)) {
        $featurePath = Join-Path $ProjectRoot $featurePath
    }

    $specPath = Join-Path $featurePath 'spec.md'
    if (-not (Test-Path -LiteralPath $specPath -PathType Leaf)) { return 0 }

    $specText = Get-Content -LiteralPath $specPath -Raw -Encoding UTF8
    if ($specText -notmatch '(?mi)^\s*\*\*Status\*\*:\s*Approved\s*$' -and $specText -notmatch '(?mi)^\s*Status:\s*Approved\s*$') {
        return 0
    }

    $hasVerdictHistoryEvidence = $false
    $enforcement = $context.PSObject.Properties['boundary_enforcement']
    if ($null -ne $enforcement -and $null -ne $enforcement.Value -and $null -ne $enforcement.Value.PSObject.Properties['verdict_history']) {
        $hasVerdictHistoryEvidence = @($enforcement.Value.verdict_history | Where-Object {
                $null -ne $_ -and
                $null -ne $_.PSObject.Properties['authorizing_human'] -and
                -not [string]::IsNullOrWhiteSpace([string]$_.PSObject.Properties['authorizing_human'].Value) -and
                $null -ne $_.PSObject.Properties['verdict_text'] -and
                ([string]$_.PSObject.Properties['verdict_text'].Value -match '(?i)\bapprov')
            }).Count -gt 0
    }

    $decisionsPath = Join-Path $ProjectRoot '.squad\decisions.md'
    $hasDecisionEvidence = $false
    if (Test-Path -LiteralPath $decisionsPath -PathType Leaf) {
        $decisionsText = Get-Content -LiteralPath $decisionsPath -Raw -Encoding UTF8
        $hasDecisionEvidence = (
            $decisionsText -match '(?i)\b(Type|Decision)\*\*:\s*(authorization|sign-off)' -and
            $decisionsText -match '(?i)\b(Approving Human|Authorizing Human)\*\*:\s*(?!pending|none|null)\S+' -and
            $decisionsText -match '(?i)\b(Authorization Text|Verdict Text)\*\*:\s*.*\bapprov'
        )
    }

    if (-not $hasVerdictHistoryEvidence -and -not $hasDecisionEvidence) {
        Write-TrustHardeningWarning -Category 'approved-status-without-verdict' -Detail ("Feature spec declares Status: Approved without matching human verdict evidence in boundary_enforcement.verdict_history or .squad/decisions.md: {0}" -f (Convert-ToRepoMarkdownPath -ProjectRoot $ProjectRoot -TargetPath $specPath))
        return 1
    }

    return 0
}

function Test-SessionStateBoundaryCanonical {
    # Proposal 090: catches non-canonical boundary strings (e.g., 'feature-closed',
    # 'iteration-closed') and active=true + boundary=feature-closeout contradiction.
    # Both failure modes manifest when the Crew bypasses Invoke-SpecrewBoundaryStateSync
    # and manually edits state files. See Proposal 090 for empirical motivation.
    param(
        [Parameter(Mandatory = $true)]
        [string]$ProjectRoot
    )

    $canonicalSet = Get-SpecrewCanonicalBoundaryTypes
    $closureSet = Get-SpecrewClosureBoundaryTypes
    $failures = New-Object System.Collections.Generic.List[string]

    # Check 1: .specrew/start-context.json
    $startContextPath = Join-Path -Path $ProjectRoot -ChildPath '.specrew\start-context.json'
    if (Test-Path -LiteralPath $startContextPath -PathType Leaf) {
        try {
            $startContext = Get-Content -LiteralPath $startContextPath -Raw -Encoding UTF8 | ConvertFrom-Json
            if ($null -ne $startContext.session_state) {
                $boundary = [string]$startContext.session_state.boundary_type
                $active = $startContext.session_state.active
                if (-not [string]::IsNullOrWhiteSpace($boundary) -and $boundary -notin $canonicalSet) {
                    $null = $failures.Add("$startContextPath`: session_state.boundary_type value '$boundary' is not in the canonical set. Canonical: $($canonicalSet -join ', '). Use the appropriate /speckit.specrew-speckit.sync-<phase> command (Proposal 090) instead of manual edits.")
                }
                if ($active -eq $true -and $boundary -in $closureSet) {
                    $null = $failures.Add("$startContextPath`: session_state.active=true is contradictory with session_state.boundary_type='$boundary' (closure boundaries imply inactive state). Invoke /speckit.specrew-speckit.sync-feature-closeout to canonicalize.")
                }
            }
        }
        catch {
            # Skip parse failures; other validator rules handle malformed JSON
        }
    }

    # Check 2: .specrew/last-start-prompt.md frontmatter
    $promptPath = Join-Path -Path $ProjectRoot -ChildPath '.specrew\last-start-prompt.md'
    if (Test-Path -LiteralPath $promptPath -PathType Leaf) {
        try {
            $promptLines = @(Get-Content -LiteralPath $promptPath -Encoding UTF8)
            $promptBoundary = $null
            $promptActive = $null
            $inFrontmatter = $false
            $frontmatterDelimiterCount = 0
            for ($i = 0; $i -lt $promptLines.Count; $i++) {
                $line = $promptLines[$i]
                if ($line.Trim() -eq '---') {
                    $frontmatterDelimiterCount++
                    $inFrontmatter = ($frontmatterDelimiterCount -eq 1)
                    if ($frontmatterDelimiterCount -ge 2) { break }
                    continue
                }
                if (-not $inFrontmatter) { continue }
                if ($line -match '^session_state_boundary:\s*(.+?)\s*$') {
                    $promptBoundary = $matches[1].Trim().Trim('"').Trim("'")
                }
                elseif ($line -match '^session_state_active:\s*(.+?)\s*$') {
                    $promptActive = $matches[1].Trim().ToLower()
                }
            }
            if (-not [string]::IsNullOrWhiteSpace($promptBoundary) -and $promptBoundary -notin $canonicalSet) {
                $null = $failures.Add("$promptPath`: session_state_boundary value '$promptBoundary' is not in the canonical set. Canonical: $($canonicalSet -join ', '). Use the appropriate /speckit.specrew-speckit.sync-<phase> command (Proposal 090) instead of manual edits.")
            }
            if ($promptActive -eq 'true' -and $promptBoundary -in $closureSet) {
                $null = $failures.Add("$promptPath`: session_state_active=true is contradictory with session_state_boundary='$promptBoundary' (closure boundaries imply inactive state). Invoke /speckit.specrew-speckit.sync-feature-closeout to canonicalize.")
            }
        }
        catch {
            # Skip parse failures
        }
    }

    # Check 3: .squad/identity/now.md frontmatter
    $nowPath = Join-Path -Path $ProjectRoot -ChildPath '.squad\identity\now.md'
    if (Test-Path -LiteralPath $nowPath -PathType Leaf) {
        try {
            $nowLines = @(Get-Content -LiteralPath $nowPath -Encoding UTF8)
            $nowBoundary = $null
            $nowActive = $null
            $inFrontmatter = $false
            $frontmatterDelimiterCount = 0
            for ($i = 0; $i -lt $nowLines.Count; $i++) {
                $line = $nowLines[$i]
                if ($line.Trim() -eq '---') {
                    $frontmatterDelimiterCount++
                    $inFrontmatter = ($frontmatterDelimiterCount -eq 1)
                    if ($frontmatterDelimiterCount -ge 2) { break }
                    continue
                }
                if (-not $inFrontmatter) { continue }
                if ($line -match '^session_state_boundary:\s*(.+?)\s*$') {
                    $nowBoundary = $matches[1].Trim().Trim('"').Trim("'")
                }
                elseif ($line -match '^session_state_active:\s*(.+?)\s*$') {
                    $nowActive = $matches[1].Trim().ToLower()
                }
            }
            if (-not [string]::IsNullOrWhiteSpace($nowBoundary) -and $nowBoundary -notin $canonicalSet) {
                $null = $failures.Add("$nowPath`: session_state_boundary value '$nowBoundary' is not in the canonical set. Canonical: $($canonicalSet -join ', '). Use the appropriate /speckit.specrew-speckit.sync-<phase> command (Proposal 090) instead of manual edits.")
            }
            if ($nowActive -eq 'true' -and $nowBoundary -in $closureSet) {
                $null = $failures.Add("$nowPath`: session_state_active=true is contradictory with session_state_boundary='$nowBoundary' (closure boundaries imply inactive state). Invoke /speckit.specrew-speckit.sync-feature-closeout to canonicalize.")
            }
        }
        catch {
            # Skip parse failures
        }
    }

    # Check 4: iteration state.md Current Phase value — scoped to the ACTIVE
    # iteration only (per session_state in start-context.json). Legacy historical
    # iterations with non-canonical Current Phase values (e.g., 'complete',
    # 'closed') are out of scope here per Proposal 090 — they're addressed by
    # a separate one-time migration chore. The point of this check is to catch
    # the bug class in NEWLY-active iterations, not retroactively across history.
    $activeFeatureRef = $null
    $activeIterationNumber = $null
    if (Test-Path -LiteralPath $startContextPath -PathType Leaf) {
        try {
            $startContext = Get-Content -LiteralPath $startContextPath -Raw -Encoding UTF8 | ConvertFrom-Json
            if ($null -ne $startContext.session_state -and $startContext.session_state.active -eq $true) {
                $activeFeatureRef = [string]$startContext.session_state.feature_ref
                $activeIterationNumber = [string]$startContext.session_state.iteration_number
            }
        }
        catch {
            # Skip parse failures
        }
    }

    if (-not [string]::IsNullOrWhiteSpace($activeFeatureRef) -and -not [string]::IsNullOrWhiteSpace($activeIterationNumber)) {
        $activeIterationStatePath = Join-Path -Path $ProjectRoot -ChildPath ("specs\{0}\iterations\{1}\state.md" -f $activeFeatureRef, $activeIterationNumber)
        if (Test-Path -LiteralPath $activeIterationStatePath -PathType Leaf) {
            try {
                $stateLines = @(Get-Content -LiteralPath $activeIterationStatePath -Encoding UTF8)
                for ($i = 0; $i -lt $stateLines.Count; $i++) {
                    if ($stateLines[$i] -match '^\*\*Current Phase\*\*:\s*(.+?)\s*$') {
                        $value = $matches[1].Trim().Trim('"').Trim("'")
                        if (-not [string]::IsNullOrWhiteSpace($value) -and $value -notin $canonicalSet) {
                            $null = $failures.Add(("{0}:{1}: 'Current Phase' value '{2}' is not in the canonical set. Canonical: {3}. Use the canonical sync command (Proposal 090) instead of manual edits." -f $activeIterationStatePath, ($i + 1), $value, ($canonicalSet -join ', ')))
                        }
                        break
                    }
                }
            }
            catch {
                # Skip parse failures
            }
        }
    }

    if ($failures.Count -gt 0) {
        Write-Host 'FAIL Test-SessionStateBoundaryCanonical' -ForegroundColor Red
        foreach ($failure in $failures) {
            Write-Host "  - $failure" -ForegroundColor Red
        }
        return $failures.Count
    }

    return 0
}

function Get-PublicReadinessEnabled {
    # Reads `.specrew/config.yml` for `public_readiness.enabled: true|false`.
    # Default false — new projects start private and only opt in to public-readiness
    # checks (LICENSE / NOTICE.md / CHANGELOG.md / docs/versioning.md / README-version-
    # sync) when the user explicitly classifies the project as public-facing. F-025
    # intake (Proposal 063) will flip this to true based on the project-classification
    # question; until then it stays off so new projects don't get noisy WARNs.
    param([string]$ProjectRoot)

    $configPath = Join-Path $ProjectRoot '.specrew\config.yml'
    if (-not (Test-Path -LiteralPath $configPath -PathType Leaf)) {
        return $false
    }

    $insidePublicReadinessBlock = $false
    try {
        foreach ($line in Get-MarkdownContent -Path $configPath) {
            if ($line -match '^public_readiness:\s*$') {
                $insidePublicReadinessBlock = $true
                continue
            }
            if ($insidePublicReadinessBlock) {
                if ($line -match '^\s{2}enabled:\s*"?(true|false)"?\s*$') {
                    return [bool]::Parse($Matches[1])
                }
                if ($line -match '^[^\s]') {
                    # Hit the next top-level key — stop scanning the public_readiness block
                    break
                }
            }
        }
    }
    catch {
        return $false
    }

    return $false
}

function Test-PublicReadinessSurfaces {
    param(
        [Parameter(Mandatory = $true)]
        [string]$ProjectRoot
    )

    # F-040 dogfooding fix (tip-calc-v2 2026-05-23): public-readiness checks are now
    # opt-in via `.specrew/config.yml#public_readiness.enabled`. New projects default
    # to false — they only fire when the project owner has classified the project as
    # public-facing (intake F-025 will write this from the project-classification
    # answer). Specrew's own dogfooding tree DOES have `public_readiness.enabled: true`
    # in its config so the warnings continue to surface there.
    if (-not (Get-PublicReadinessEnabled -ProjectRoot $ProjectRoot)) {
        return
    }

    try {
        foreach ($artifact in @('LICENSE', 'NOTICE.md', 'CHANGELOG.md')) {
            $artifactPath = Join-Path $ProjectRoot $artifact
            if (-not (Test-Path -LiteralPath $artifactPath -PathType Leaf)) {
                Write-PublicReadinessWarning -Category 'missing-artifact' -Detail $artifact
            }
        }

        $versioningPath = Join-Path $ProjectRoot 'docs\versioning.md'
        if (-not (Test-Path -LiteralPath $versioningPath -PathType Leaf)) {
            Write-PublicReadinessWarning -Category 'missing-artifact' -Detail 'docs/versioning.md'
        }

        $declaredVersion = Get-DeclaredSpecrewVersion -ProjectRoot $ProjectRoot
        if ([string]::IsNullOrWhiteSpace($declaredVersion)) {
            return
        }

        $readmePath = Join-Path $ProjectRoot 'README.md'
        if (-not (Test-Path -LiteralPath $readmePath -PathType Leaf)) {
            return
        }

        $readmeContent = Get-Content -LiteralPath $readmePath -Raw -Encoding UTF8
        if ($readmeContent -notmatch [regex]::Escape($declaredVersion)) {
            Write-PublicReadinessWarning -Category 'stale-version-in-readme' -Detail ("README.md does not contain declared version {0}" -f $declaredVersion)
        }

        $extensionManifestPaths = @(
            @{ Path = (Join-Path $ProjectRoot 'extensions\specrew-speckit\extension.yml'); Label = 'extensions/specrew-speckit/extension.yml' },
            @{ Path = (Join-Path $ProjectRoot '.specify\extensions\specrew-speckit\extension.yml'); Label = '.specify/extensions/specrew-speckit/extension.yml' }
        )

        foreach ($manifest in $extensionManifestPaths) {
            $manifestVersion = Get-ExtensionManifestVersion -ManifestPath $manifest.Path
            if ([string]::IsNullOrWhiteSpace($manifestVersion)) {
                continue
            }

            if ($manifestVersion -ne $declaredVersion) {
                Write-PublicReadinessWarning -Category 'stale-version-in-extension-manifest' -Detail ("{0} declares version '{1}' but .specrew/config.yml declares specrew_version '{2}'. Rule 15 (feature-closeout version management) requires these to match." -f $manifest.Label, $manifestVersion, $declaredVersion)
            }
        }
    }
    catch {
        return
    }
}

function Get-DashboardRendererPath {
    # Resolve the velocity dashboard renderer path. Two layouts supported (same pattern as
    # the sync-boundary-state wrapper after F-040 dogfooding 2026-05-23):
    #   1) Dev-tree: <project>/scripts/internal/dashboard-renderer.ps1
    #   2) Downstream: <installed-Specrew-module-base>/scripts/internal/dashboard-renderer.ps1
    # Returns the first that exists; if neither, returns the dev-tree path so callers'
    # Test-Path checks fail in a predictable way.
    param([Parameter(Mandatory = $true)][string]$ProjectRoot)

    $devTreePath = Join-Path $ProjectRoot 'scripts\internal\dashboard-renderer.ps1'
    if (Test-Path -LiteralPath $devTreePath -PathType Leaf) {
        return $devTreePath
    }

    $specrewModule = Get-Module -Name 'Specrew' -ListAvailable -ErrorAction SilentlyContinue |
        Sort-Object Version -Descending |
        Select-Object -First 1
    if ($null -ne $specrewModule) {
        $modulePath = Join-Path $specrewModule.ModuleBase 'scripts\internal\dashboard-renderer.ps1'
        if (Test-Path -LiteralPath $modulePath -PathType Leaf) {
            return $modulePath
        }
    }

    return $devTreePath
}

function Get-FeatureOrdinalFromRef {
    param([AllowNull()][string]$FeatureRef)

    if ([string]::IsNullOrWhiteSpace($FeatureRef)) {
        return $null
    }

    if ($FeatureRef -match '^(?<ordinal>\d+)-') {
        return [int]$Matches['ordinal']
    }

    return $null
}

function Get-IterationOrdinalFromRef {
    param([AllowNull()][string]$IterationRef)

    if ([string]::IsNullOrWhiteSpace($IterationRef)) {
        return $null
    }

    if ($IterationRef -match '^\d+$') {
        return [int]$IterationRef
    }

    return $null
}

function Test-DashboardGovernanceSurfaces {
    param([Parameter(Mandatory = $true)][string]$ProjectRoot)

    $rendererPath = Get-DashboardRendererPath -ProjectRoot $ProjectRoot
    if (-not (Test-Path -LiteralPath $rendererPath -PathType Leaf)) {
        return
    }

    . $rendererPath

    $features = @(Get-SpecrewFeatureRecords -ProjectRoot $ProjectRoot)
    $roadmapDefinition = Read-SpecrewRoadmapDefinition -ProjectRoot $ProjectRoot
    if ($roadmapDefinition.exists) {
        foreach ($warning in @($roadmapDefinition.warnings)) {
            Write-DashboardGovernanceWarning -Category 'roadmap-schema' -Detail $warning
        }

        $roadmapProgress = Get-SpecrewRoadmapProgress -RoadmapDefinition $roadmapDefinition -FeatureRecords $features
        foreach ($warning in @($roadmapProgress.warnings)) {
            $category = if ($warning -like 'Roadmap drift:*') { 'roadmap-drift' } else { 'roadmap-schema' }
            Write-DashboardGovernanceWarning -Category $category -Detail $warning
        }
    }

    $dashboardRolloutFeatureOrdinal = 17
    $dashboardRolloutIterationFloor = 2

    foreach ($feature in $features) {
        $featureOrdinal = Get-FeatureOrdinalFromRef -FeatureRef $feature.feature_ref
        if ($null -eq $featureOrdinal -or $featureOrdinal -lt $dashboardRolloutFeatureOrdinal) {
            continue
        }

        foreach ($iteration in @($feature.closed_iterations)) {
            $iterationOrdinal = Get-IterationOrdinalFromRef -IterationRef $iteration.iteration_ref
            $requiresDashboard = ($featureOrdinal -gt $dashboardRolloutFeatureOrdinal) -or `
                ($featureOrdinal -eq $dashboardRolloutFeatureOrdinal -and $null -ne $iterationOrdinal -and $iterationOrdinal -ge $dashboardRolloutIterationFloor)
            if (-not $requiresDashboard) {
                continue
            }

            $dashboardPath = Join-Path $iteration.iteration_directory 'dashboard.md'
            if (-not (Test-Path -LiteralPath $dashboardPath -PathType Leaf)) {
                $diagnosis = Get-MissingDashboardDiagnosis -IterationDirectory $iteration.iteration_directory
                Write-DashboardGovernanceWarning -Category $diagnosis.Category -Detail ("{0}: closed iteration '{1} {2}'." -f $diagnosis.DetailPrefix, $feature.feature_ref, $iteration.iteration_ref)
            }
            else {
                $dashboardText = Get-Content -LiteralPath $dashboardPath -Raw -Encoding UTF8
                if ($dashboardText -notmatch '\*\*Schema\*\*:\s*v1') {
                    Write-DashboardGovernanceWarning -Category 'dashboard-schema-version' -Detail ("Iteration dashboard '{0}' is missing the expected schema marker." -f $dashboardPath)
                }
                if ($dashboardText -match ([char]27 + '\[[0-9;]*[A-Za-z]')) {
                    Write-DashboardGovernanceWarning -Category 'dashboard-artifact-ansi' -Detail ("Iteration dashboard '{0}' still contains ANSI escape sequences; stored snapshots must strip ANSI while preserving Unicode." -f $dashboardPath)
                }
            }
        }

        $hasFeatureCloseout = $false
        if ($null -ne $feature -and $null -ne $feature.PSObject.Properties['has_feature_closeout']) {
            $hasFeatureCloseout = [bool]$feature.has_feature_closeout
        }
        elseif ([string]$feature.feature_status -match '(?i)complete|closed|shipped') {
            $hasFeatureCloseout = $true
        }

        if ($hasFeatureCloseout) {
            $requiresFeatureDashboard = $false
            if ($featureOrdinal -gt $dashboardRolloutFeatureOrdinal) {
                $requiresFeatureDashboard = $true
            }
            elseif ($featureOrdinal -eq $dashboardRolloutFeatureOrdinal) {
                $requiresFeatureDashboard = (@($feature.closed_iterations | Where-Object {
                            $iterationOrdinal = Get-IterationOrdinalFromRef -IterationRef $_.iteration_ref
                            $null -ne $iterationOrdinal -and $iterationOrdinal -ge $dashboardRolloutIterationFloor
                        })).Count -gt 0
            }

            if (-not $requiresFeatureDashboard) {
                continue
            }

            if (-not (Test-Path -LiteralPath $feature.closeout_dashboard_path -PathType Leaf)) {
                Write-DashboardGovernanceWarning -Category 'missing-feature-dashboard-auto-render-regression' -Detail ("Closed Specrew feature '{0}' is missing closeout-dashboard.md; feature-closeout auto-render regression suspected." -f $feature.feature_ref)
            }
            else {
                $closeoutText = Get-Content -LiteralPath $feature.closeout_dashboard_path -Raw -Encoding UTF8
                if ($closeoutText -notmatch '\*\*Schema\*\*:\s*v1') {
                    Write-DashboardGovernanceWarning -Category 'dashboard-schema-version' -Detail ("Feature closeout dashboard '{0}' is missing the expected schema marker." -f $feature.closeout_dashboard_path)
                }
                if ($closeoutText -match ([char]27 + '\[[0-9;]*[A-Za-z]')) {
                    Write-DashboardGovernanceWarning -Category 'dashboard-artifact-ansi' -Detail ("Feature closeout dashboard '{0}' still contains ANSI escape sequences; stored snapshots must strip ANSI while preserving Unicode." -f $feature.closeout_dashboard_path)
                }
            }
        }
    }
}

function Test-CopilotInstructionsClassifierCompatibility {
    param(
        [string]$ProjectRoot,
        [System.Collections.Generic.List[string]]$Errors
    )

    $instructionsPath = Join-Path $ProjectRoot '.github\copilot-instructions.md'
    if (-not (Test-Path -LiteralPath $instructionsPath -PathType Leaf)) {
        return
    }

    try {
        $classification = Test-CopilotInstructionsChangeType -BeforePath $instructionsPath -AfterPath $instructionsPath
    }
    catch {
        Add-RepoStructuredValidationFailure -Errors $Errors -ProjectRoot $ProjectRoot -TargetPath $instructionsPath -LineNumber $null -Category 'bookkeeping-classifier' -Message ("Unable to evaluate .github/copilot-instructions.md with the classifier helper: {0}" -f $_.Exception.Message) -RemediationHint 'Repair Test-CopilotInstructionsChangeType.ps1 so validator compatibility checks can classify copilot-instructions changes.'
        return
    }

    if ($null -eq $classification -or $classification.Classification -notin @('bookkeeping', 'behavior')) {
        Add-RepoStructuredValidationFailure -Errors $Errors -ProjectRoot $ProjectRoot -TargetPath $instructionsPath -LineNumber $null -Category 'bookkeeping-classifier' -Message 'The copilot-instructions classifier helper returned an invalid classification.' -RemediationHint 'Return either bookkeeping or behavior from Test-CopilotInstructionsChangeType.ps1.'
        return
    }

    if ($classification.Classification -ne 'bookkeeping' -or [bool]$classification.RequiresRestart) {
        Add-RepoStructuredValidationFailure -Errors $Errors -ProjectRoot $ProjectRoot -TargetPath $instructionsPath -LineNumber $null -Category 'bookkeeping-classifier' -Message 'Identical copilot-instructions content must classify as bookkeeping with no restart requirement.' -RemediationHint 'Keep Test-CopilotInstructionsChangeType.ps1 conservative for real behavior changes, but allow identical or bookkeeping-only content to stay restart-free.'
    }
}

function Find-CanonicalMetadataLabelLineNumber {
    param(
        [string[]]$Lines,
        [string]$Label
    )

    $pattern = '^\*\*' + [regex]::Escape($Label) + '\*\*:\s*(.*?)\s*$'
    return Find-LineNumberByPattern -Lines $Lines -Pattern $pattern -CaseSensitive
}

function Find-NonCanonicalMetadataLabelLineNumber {
    param(
        [string[]]$Lines,
        [string]$Label
    )

    $aliasPatterns = switch ($Label) {
        'Iteration Status' { @('^(?!\*\*)\s*Overall Status\s*:\s*.*$') ; break }
        'Current Phase' { @('^(?!\*\*)\s*Planning Phase\s*:\s*.*$') ; break }
        default { @() }
    }

    $trimmedLabel = [regex]::Escape($Label.Trim())
    $patterns = @(
        '^\*\*' + $trimmedLabel + '\*\*:\s*.*$',
        '^(?!\*\*)\s*' + $trimmedLabel + '\s*:\s*.*$',
        '^#+\s*' + $trimmedLabel + '\s*$',
        '^\s*-\s*' + $trimmedLabel + '\s*:\s*.*$'
    ) + $aliasPatterns

    foreach ($pattern in $patterns) {
        $lineNumber = Find-LineNumberByPattern -Lines $Lines -Pattern $pattern
        if ($null -ne $lineNumber) {
            return $lineNumber
        }
    }

    return $null
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

        [Alias('Names')]
        [string[]]$PropertyNames
    )

    if ($null -eq $InputObject) {
        return $null
    }

    if ($InputObject -is [System.Collections.IDictionary] -or $InputObject -is [System.Collections.Specialized.IOrderedDictionary]) {
        foreach ($propertyName in $PropertyNames) {
            if ($InputObject.Contains($propertyName) -and -not [string]::IsNullOrWhiteSpace([string]$InputObject[$propertyName])) {
                return [string]$InputObject[$propertyName]
            }
        }

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

    if (Test-IterationRequiresCanonicalHardeningConcerns -IterationDirectory $IterationDirectory) {
        $hardeningGatePath = $planContext.HardeningGateArtifactPath
        $hardeningGateLines = @(Get-MarkdownContent -Path $hardeningGatePath)
        $concernHeadingLine = Find-LineNumberByPattern -Lines $hardeningGateLines -Pattern '^#{2,3}\s+Concern Review\b'
        $expectedConcernDefinitions = @(Get-CanonicalHardeningConcernDefinitions -ProjectRoot $ProjectRoot)
        $expectedConcernIds = @($expectedConcernDefinitions | ForEach-Object { $_.ConcernId })

        if ($hardeningState.ConcernRows.Count -lt $expectedConcernIds.Count) {
            Add-RepoStructuredValidationFailure -Errors $Errors -ProjectRoot $ProjectRoot -TargetPath $hardeningGatePath -LineNumber $concernHeadingLine -Category 'concern-order' -Message ("hardening-gate.md is missing canonical concern rows; expected at least {0} Concern Review rows but found {1}" -f $expectedConcernIds.Count, $hardeningState.ConcernRows.Count) -RemediationHint 'Ensure the five canonical concerns appear as rows 1 through 5 before any feature-specific concerns.'
        }

        foreach ($definition in $expectedConcernDefinitions) {
            $concernId = $definition.ConcernId
            $matches = @($hardeningState.ConcernRows | Where-Object { [string]$_.Concern -eq $concernId })
            if ($matches.Count -ne 1) {
                Add-RepoStructuredValidationFailure -Errors $Errors -ProjectRoot $ProjectRoot -TargetPath $hardeningGatePath -LineNumber $concernHeadingLine -Category 'concern-order' -Message ("hardening-gate.md must contain exactly one canonical concern row for '{0}'" -f $concernId) -RemediationHint 'Keep each canonical concern visible exactly once in the Concern Review table.'
                continue
            }

            $rowIndex = $definition.Position - 1
            if ($rowIndex -ge $hardeningState.ConcernRows.Count) {
                Add-RepoStructuredValidationFailure -Errors $Errors -ProjectRoot $ProjectRoot -TargetPath $hardeningGatePath -LineNumber $concernHeadingLine -Category 'concern-order' -Message ("hardening-gate.md is missing canonical concern '{0}' at required row position {1}" -f $concernId, $definition.Position) -RemediationHint 'Add the missing canonical concern so rows 1 through 5 match the canonical contract order.'
                continue
            }

            $actualConcern = Normalize-MarkdownCell ([string]$hardeningState.ConcernRows[$rowIndex].Concern)
            if ($actualConcern -ne $concernId) {
                $actualLineNumber = Find-LineNumberByPattern -Lines $hardeningGateLines -Pattern ('^\|\s*`?' + [regex]::Escape($actualConcern) + '`?\s*\|')
                Add-RepoStructuredValidationFailure -Errors $Errors -ProjectRoot $ProjectRoot -TargetPath $hardeningGatePath -LineNumber $actualLineNumber -Category 'concern-order' -Message ("hardening-gate.md row {0} must be canonical concern '{1}' but found '{2}'" -f $definition.Position, $concernId, $actualConcern) -RemediationHint 'Reorder the Concern Review table so the five canonical concerns appear first in the required order.'
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
        [string]$ProjectRoot,
        [System.Collections.Generic.List[string]]$Errors
    )

    $statePath = Join-Path -Path $IterationDirectory -ChildPath 'state.md'
    if (-not (Test-Path -Path $statePath -PathType Leaf)) {
        Add-RepoStructuredValidationFailure -Errors $Errors -ProjectRoot $ProjectRoot -TargetPath $statePath -LineNumber $null -Category 'missing-artifact' -Message 'Missing required artifact: state.md' -RemediationHint 'Add state.md to the iteration directory before continuing the lifecycle.'
        return
    }

    try {
        $stateLines = @(Get-MarkdownContent -Path $statePath)
    }
    catch {
        Add-RepoStructuredValidationFailure -Errors $Errors -ProjectRoot $ProjectRoot -TargetPath $statePath -LineNumber $null -Category 'parse-failure' -Message ("Unable to read state.md: {0}" -f $_.Exception.Message) -RemediationHint 'Repair the state.md file encoding or contents and rerun validate-governance.ps1.'
        return
    }

    if (Test-IterationRequiresCanonicalStateSchema -IterationDirectory $IterationDirectory) {
        foreach ($field in @(Get-CanonicalIterationStateFields -ProjectRoot $ProjectRoot)) {
            $label = [string]$field.FieldName
            $canonicalLineNumber = Find-CanonicalMetadataLabelLineNumber -Lines $stateLines -Label $label
            if ($null -ne $canonicalLineNumber) {
                continue
            }

            $nonCanonicalLineNumber = Find-NonCanonicalMetadataLabelLineNumber -Lines $stateLines -Label $label
            if ($null -ne $nonCanonicalLineNumber) {
                Add-RepoStructuredValidationFailure -Errors $Errors -ProjectRoot $ProjectRoot -TargetPath $statePath -LineNumber $nonCanonicalLineNumber -Category 'canonical-schema' -Message ("state.md uses a non-canonical label for '{0}'" -f $label) -RemediationHint ("Replace it with the canonical metadata line '**{0}**:' on its own line." -f $label)
                continue
            }

            $caseVariantLineNumber = Find-LineNumberByPattern -Lines $stateLines -Pattern ('^\*\*' + [regex]::Escape($label) + '\*\*:\s*(.*?)\s*$')
            if ($null -ne $caseVariantLineNumber) {
                Add-RepoStructuredValidationFailure -Errors $Errors -ProjectRoot $ProjectRoot -TargetPath $statePath -LineNumber $caseVariantLineNumber -Category 'canonical-schema' -Message ("state.md uses a non-canonical label for '{0}'" -f $label) -RemediationHint ("Replace it with the canonical metadata line '**{0}**:' on its own line." -f $label)
                continue
            }

            Add-RepoStructuredValidationFailure -Errors $Errors -ProjectRoot $ProjectRoot -TargetPath $statePath -LineNumber $null -Category 'canonical-schema' -Message ("state.md is missing canonical field '{0}'" -f $label) -RemediationHint ("Add the canonical metadata line '**{0}**:' to state.md." -f $label)
        }

        return
    }

    foreach ($label in @('Last Completed Task', 'Tasks Remaining', 'In Progress', 'Baseline Ref', 'Updated')) {
        $value = Get-MarkdownMetadataValue -Lines $stateLines -Label $label
        if ($null -eq $value) {
            Add-RepoStructuredValidationFailure -Errors $Errors -ProjectRoot $ProjectRoot -TargetPath $statePath -LineNumber $null -Category 'missing-artifact' -Message ("state.md is missing required metadata: {0}" -f $label) -RemediationHint ("Add the '{0}' metadata line to state.md." -f $label)
        }
    }
}

function Test-ReaderTolerance {
    param(
        [Parameter(Mandatory = $true)]
        [string]$ProjectRoot,

        [AllowEmptyCollection()]
        [Parameter(Mandatory = $true)]
        [System.Collections.Generic.List[string]]$Errors
    )

    # TODO (future feature): widen to heuristic detection — flag any function whose body contains a .specrew\ / .specify\ / .squad\ literal AND a ConvertFrom-Json call without -AsHashtable. Current allowlist is correct-but-narrow; new readers added outside this list will not be caught.
    $targets = @(
        @{
            Path      = Join-Path $ProjectRoot 'scripts\specrew-start.ps1'
            Functions = @('Get-SpecrewStartContextSessionState', 'Resolve-FeatureDirectory')
        },
        @{
            Path      = Join-Path $ProjectRoot 'scripts\internal\worktree-awareness.ps1'
            Functions = @('Get-WorktreeFeatureRef')
        },
        @{
            Path      = Join-Path $ProjectRoot 'scripts\internal\coordinator-resume.ps1'
            Functions = @('Get-ValidatorWarningSummary')
        },
        @{
            Path      = Join-Path $ProjectRoot 'scripts\internal\version-check.ps1'
            Functions = @('Get-SpecrewVersionCheckCacheState')
        },
        @{
            Path      = Join-Path $ProjectRoot 'scripts\internal\sync-boundary-state.ps1'
            Functions = @('Update-SpecrewStartContext', 'Clear-SpecrewActiveFeature', 'Invoke-SpecrewBoundaryStateSync')
        },
        @{
            Path      = Join-Path $ProjectRoot 'extensions\specrew-speckit\scripts\scaffold-feature-closeout-dashboard.ps1'
            Functions = @('Get-ResolvedFeatureDirectory')
        },
        @{
            Path      = Join-Path $ProjectRoot '.specify\extensions\specrew-speckit\scripts\scaffold-feature-closeout-dashboard.ps1'
            Functions = @('Get-ResolvedFeatureDirectory')
        }
    )

    foreach ($target in $targets) {
        $scriptPath = $target.Path
        if (-not (Test-Path -LiteralPath $scriptPath -PathType Leaf)) {
            continue
        }

        $tokens = $null
        $parseErrors = $null
        $ast = [System.Management.Automation.Language.Parser]::ParseFile($scriptPath, [ref]$tokens, [ref]$parseErrors)
        if ($parseErrors.Count -gt 0) {
            Add-RepoStructuredValidationFailure -Errors $Errors -ProjectRoot $ProjectRoot -TargetPath $scriptPath -LineNumber $parseErrors[0].Extent.StartLineNumber -Category 'reader-tolerance' -Message 'Could not parse script for reader-tolerance validation.' -RemediationHint 'Repair the PowerShell syntax errors before rerunning validate-governance.ps1.'
            continue
        }

        foreach ($functionName in @($target.Functions)) {
            $functionAst = @(
                $ast.FindAll({
                        param($node)
                        $node -is [System.Management.Automation.Language.FunctionDefinitionAst] -and $node.Name -eq $functionName
                    }, $true)
            ) | Select-Object -First 1

            if ($null -eq $functionAst) {
                continue
            }

            $convertCommands = @(
                $functionAst.FindAll({
                        param($node)
                        if ($node -isnot [System.Management.Automation.Language.CommandAst]) {
                            return $false
                        }

                        if ($node.CommandElements.Count -eq 0) {
                            return $false
                        }

                        $commandName = $node.CommandElements[0].Extent.Text.Trim()
                        return $commandName -eq 'ConvertFrom-Json'
                    }, $true)
            )

            foreach ($commandAst in $convertCommands) {
                if ($commandAst.Extent.Text -match '(?i)-AsHashtable\b') {
                    continue
                }

                Add-RepoStructuredValidationFailure -Errors $Errors -ProjectRoot $ProjectRoot -TargetPath $scriptPath -LineNumber $commandAst.Extent.StartLineNumber -Category 'reader-tolerance' -Message ("Function {0} reads Specrew state with ConvertFrom-Json but without -AsHashtable." -f $functionName) -RemediationHint 'Add -AsHashtable and use hashtable indexers so missing fields do not crash under Set-StrictMode -Version Latest.'
            }
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

    # Pillar 5 (FR-022): production evidence cited in review.md must exist in the cited Tree Under Review.
    Test-ReviewEvidenceTreeIntegrity -ReviewLines $reviewLines -ProjectRoot $ProjectRoot -IterationDirectory $IterationDirectory -OverallVerdict $overallVerdict -IterationStatus $IterationStatus -Errors $Errors
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

function Get-IterationCanonicalArtifactRelativePaths {
    param(
        [string]$IterationDirectory,
        [string]$ProjectRoot
    )

    $iterationRelativePath = ([System.IO.Path]::GetRelativePath($ProjectRoot, $IterationDirectory)) -replace '\\', '/'
    return @(
        "$iterationRelativePath/plan.md",
        "$iterationRelativePath/state.md",
        "$iterationRelativePath/drift-log.md",
        "$iterationRelativePath/review.md",
        "$iterationRelativePath/retro.md",
        "$iterationRelativePath/reviewer-index.md",
        "$iterationRelativePath/review-diagrams.md",
        "$iterationRelativePath/code-map.md",
        "$iterationRelativePath/coverage-evidence.md",
        "$iterationRelativePath/dependency-report.md",
        "$iterationRelativePath/quality/hardening-gate.md",
        "$iterationRelativePath/quality/trap-reapplication.md"
    )
}

function Get-IterationDirtyCanonicalArtifacts {
    param(
        [string]$IterationDirectory,
        [string]$ProjectRoot
    )

    $gitCommand = Get-Command -Name 'git' -ErrorAction SilentlyContinue
    if ($null -eq $gitCommand) {
        return @()
    }

    $iterationRelativePath = ([System.IO.Path]::GetRelativePath($ProjectRoot, $IterationDirectory)) -replace '\\', '/'
    $canonicalPaths = @(
        Get-IterationCanonicalArtifactRelativePaths -IterationDirectory $IterationDirectory -ProjectRoot $ProjectRoot |
            ForEach-Object { $_.ToLowerInvariant() }
    )

    $statusOutput = @(& git -C $ProjectRoot status --porcelain --untracked-files=all -- $iterationRelativePath 2>$null)
    if ($LASTEXITCODE -ne 0) {
        throw 'Unable to inspect git working tree state for the iteration directory.'
    }

    $dirtyArtifacts = New-Object System.Collections.Generic.List[object]
    foreach ($statusLine in $statusOutput) {
        if ([string]::IsNullOrWhiteSpace($statusLine) -or $statusLine.Length -lt 4) {
            continue
        }

        $normalizedPath = $statusLine.Substring(3).Trim()
        if ($normalizedPath -match '->\s*(.+)$') {
            $normalizedPath = $Matches[1].Trim()
        }

        $normalizedPath = $normalizedPath -replace '/', '\'
        if ($normalizedPath.ToLowerInvariant() -notin $canonicalPaths) {
            continue
        }

        $dirtyArtifacts.Add([pscustomobject]@{
                Status = $statusLine.Substring(0, 2).Trim()
                Path   = $normalizedPath
            }) | Out-Null
    }

    return $dirtyArtifacts.ToArray()
}

function Test-IterationCloseoutEvidence {
    param(
        [string]$IterationDirectory,
        [string]$ProjectRoot,
        [string[]]$StateLines,
        [System.Collections.Generic.List[string]]$Errors
    )

    if (-not (Test-IterationRequiresCanonicalStateSchema -IterationDirectory $IterationDirectory)) {
        return
    }

    $iterationStatus = Normalize-MarkdownCell (Get-MarkdownMetadataValue -Lines $StateLines -Label 'Iteration Status')
    if (-not (Test-ClosedIterationStatus -IterationStatus $iterationStatus)) {
        return
    }

    $statePath = Join-Path $IterationDirectory 'state.md'
    $iterationStatusLineNumber = Find-CanonicalMetadataLabelLineNumber -Lines $StateLines -Label 'Iteration Status'
    $reviewPath = Join-Path $IterationDirectory 'review.md'
    $retroPath = Join-Path $IterationDirectory 'retro.md'
    $gatePath = Join-Path $IterationDirectory 'quality\hardening-gate.md'

    if (-not (Test-Path -LiteralPath $reviewPath -PathType Leaf)) {
        Add-RepoStructuredValidationFailure -Errors $Errors -ProjectRoot $ProjectRoot -TargetPath $reviewPath -LineNumber $null -Category 'over-claim' -Message 'Iteration Status claims closure but review.md is missing.' -RemediationHint 'Add an accepted review.md artifact before claiming the iteration is closed.'
    }
    else {
        $reviewLines = @(Get-MarkdownContent -Path $reviewPath)
        $reviewVerdictLineNumber = Find-LineNumberByPattern -Lines $reviewLines -Pattern '^\*\*Overall Verdict\*\*:\s*(.+?)\s*$'
        $reviewVerdict = Get-NormalizedKeyword (Get-MarkdownMetadataValue -Lines $reviewLines -Label 'Overall Verdict')
        if ($reviewVerdict -ne 'accepted') {
            Add-RepoStructuredValidationFailure -Errors $Errors -ProjectRoot $ProjectRoot -TargetPath $reviewPath -LineNumber $reviewVerdictLineNumber -Category 'over-claim' -Message ("Iteration Status claims closure but review.md overall verdict is '{0}' instead of accepted." -f $reviewVerdict) -RemediationHint 'Record an accepted review.md verdict before claiming the iteration is closed.'
        }
    }

    if (-not (Test-Path -LiteralPath $retroPath -PathType Leaf)) {
        Add-RepoStructuredValidationFailure -Errors $Errors -ProjectRoot $ProjectRoot -TargetPath $retroPath -LineNumber $null -Category 'over-claim' -Message 'Iteration Status claims closure but retro.md is missing.' -RemediationHint 'Add retro.md before claiming the iteration is closed.'
    }

    if (-not (Test-Path -LiteralPath $gatePath -PathType Leaf)) {
        Add-RepoStructuredValidationFailure -Errors $Errors -ProjectRoot $ProjectRoot -TargetPath $gatePath -LineNumber $null -Category 'over-claim' -Message 'Iteration Status claims closure but quality/hardening-gate.md is missing.' -RemediationHint 'Add the hardening gate artifact with recorded post-implementation verification before claiming the iteration is closed.'
    }
    else {
        $gateLines = @(Get-MarkdownContent -Path $gatePath)
        $postImplementationVerification = Normalize-MarkdownCell (Get-MarkdownMetadataValue -Lines $gateLines -Label 'Post-Implementation Verification')
        $verifiedAt = Normalize-MarkdownCell (Get-MarkdownMetadataValue -Lines $gateLines -Label 'Verified At')
        if (Test-IsNullish $postImplementationVerification -or $postImplementationVerification.ToLowerInvariant().Contains('pending')) {
            Add-RepoStructuredValidationFailure -Errors $Errors -ProjectRoot $ProjectRoot -TargetPath $gatePath -LineNumber (Find-LineNumberByPattern -Lines $gateLines -Pattern '^\*\*Post-Implementation Verification\*\*:') -Category 'over-claim' -Message 'Iteration Status claims closure but the hardening gate still shows pending post-implementation verification.' -RemediationHint 'Record post-implementation verification in quality/hardening-gate.md before claiming the iteration is closed.'
        }

        if (Test-IsNullish $verifiedAt -or $verifiedAt.ToLowerInvariant().Contains('pending')) {
            Add-RepoStructuredValidationFailure -Errors $Errors -ProjectRoot $ProjectRoot -TargetPath $gatePath -LineNumber (Find-LineNumberByPattern -Lines $gateLines -Pattern '^\*\*Verified At\*\*:') -Category 'over-claim' -Message 'Iteration Status claims closure but quality/hardening-gate.md does not record Verified At.' -RemediationHint 'Record Verified At in quality/hardening-gate.md before claiming the iteration is closed.'
        }

        $gateState = Get-HardeningGateState -Path $gatePath -ProjectRoot $ProjectRoot
        foreach ($concern in @($gateState.ConcernRows | Where-Object { Test-HardeningConcernBlocksClosure -Concern $_ -ProjectRoot $ProjectRoot })) {
            $concernLineNumber = Find-LineNumberByPattern -Lines $gateLines -Pattern ('\|\s*`?' + [regex]::Escape([string]$concern.Concern) + '`?\s*\|')
            Add-RepoStructuredValidationFailure -Errors $Errors -ProjectRoot $ProjectRoot -TargetPath $gatePath -LineNumber $concernLineNumber -Category 'over-claim' -Message ("Iteration Status claims closure but hardening-gate concern '{0}' still lacks recorded post-implementation evidence." -f $concern.Concern) -RemediationHint 'Promote the concern to runtime evidence or mark it not-applicable before claiming the iteration is closed.'
        }
    }

    $dirtyArtifacts = @(Get-IterationDirtyCanonicalArtifacts -IterationDirectory $IterationDirectory -ProjectRoot $ProjectRoot)
    if ($dirtyArtifacts.Count -gt 0) {
        $dirtyList = ($dirtyArtifacts | ForEach-Object { $_.Path }) -join ', '
        Add-RepoStructuredValidationFailure -Errors $Errors -ProjectRoot $ProjectRoot -TargetPath $statePath -LineNumber $iterationStatusLineNumber -Category 'over-claim' -Message ("Iteration Status claims closure while canonical iteration artifacts still have uncommitted changes: {0}" -f $dirtyList) -RemediationHint 'Commit or revert the iteration directory canonical artifacts before claiming the iteration is closed.'
    }
}

function Get-ReviewerCloseoutDiffArtifacts {
    # Determine which files this iteration touched, for the reviewer-closeout artifact gate.
    #
    # Resolution order (Fix following F-040 calc-v2 dogfooding 2026-05-23 — same pattern as the
    # F-033 markdownlint gate fix in shared-governance.ps1):
    #   1. If BaselineRef resolves: include `git diff $BaselineRef -- ` (committed delta).
    #   2. ALWAYS additionally include working-tree state via:
    #        `git ls-files -m`                 (modified tracked files)
    #        `git ls-files --others --exclude-standard`  (untracked, not gitignored)
    #      Union with the diff results; dedupe by path.
    #
    # The fallback is necessary because:
    #   - Greenfield-new projects (zero commits) cannot resolve BaselineRef = 'iteration-baseline'
    #     OR HEAD, which used to make this function return @() and silently disable the entire
    #     reviewer-artifact requirement check. That's exactly how calc-v2 produced a code-touching
    #     iteration with zero reviewer artifacts (code-map / coverage-evidence / reviewer-index /
    #     review-diagrams / dependency-report) and still passed validation.
    #   - Even in brownfield iterations with a resolvable BaselineRef, in-progress uncommitted edits
    #     should count toward "what this iteration touched" — otherwise the validator sees stale data.
    #
    # BaselineResolved is true when EITHER the diff path OR the working-tree path returned anything,
    # so downstream callers (Test-ReviewerCloseoutArtifacts) can proceed to file-level requirements.
    param(
        [string]$ProjectRoot,
        [AllowNull()][string]$BaselineRef
    )

    $result = [ordered]@{
        BaselineResolved = $false
        Files            = @()
    }

    $gitCommand = Get-Command -Name 'git' -ErrorAction SilentlyContinue
    if ($null -eq $gitCommand) {
        return [pscustomobject]$result
    }

    $pathsCollected = New-Object System.Collections.Generic.HashSet[string]
    $addPath = {
        param([string]$rawPath)
        $trimmed = ([string]$rawPath).Trim()
        if ([string]::IsNullOrWhiteSpace($trimmed)) { return }
        if (-not $pathsCollected.Add($trimmed)) { return }
        $result.Files += [pscustomobject]@{
            Path       = $trimmed
            IsManifest = Test-IsManifestPath -Path $trimmed
            IsSource   = Test-IsReviewerSourcePath -Path $trimmed
        }
    }

    # Path 1: committed diff against BaselineRef (preserves existing semantics when ref resolves).
    if (-not [string]::IsNullOrWhiteSpace($BaselineRef)) {
        $null = & git -C $ProjectRoot rev-parse --verify $BaselineRef 2>$null
        $baselineExit = $LASTEXITCODE
        $global:LASTEXITCODE = 0
        if ($baselineExit -eq 0) {
            $result.BaselineResolved = $true
            $diffLines = @(& git -C $ProjectRoot diff --name-only $BaselineRef -- 2>$null)
            $global:LASTEXITCODE = 0
            foreach ($line in $diffLines) {
                & $addPath $line
            }
        }
    }

    # Path 2: working-tree state — modified tracked files + untracked-not-ignored.
    # Always runs so brownfield WIP edits + greenfield first-commit-pending state both surface.
    $modifiedLines = @(& git -C $ProjectRoot ls-files -m 2>$null)
    $global:LASTEXITCODE = 0
    foreach ($line in $modifiedLines) {
        & $addPath $line
    }

    $untrackedLines = @(& git -C $ProjectRoot ls-files --others --exclude-standard 2>$null)
    $global:LASTEXITCODE = 0
    foreach ($line in $untrackedLines) {
        & $addPath $line
    }

    # Treat fallback-only success as "baseline resolved enough to proceed". The caller's error
    # message about Baseline Ref still fires when nothing at all could be enumerated (no git, no
    # working tree changes, no resolvable ref). That's the genuinely-broken-state case.
    if (-not $result.BaselineResolved -and $result.Files.Count -gt 0) {
        $result.BaselineResolved = $true
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
            $Errors.Add("Task '$($task.Task)' uses invalid status '$($task.Status)' (expected one of: $($allowedTaskStatuses -join ' | ') — note hyphens, e.g. ``in-progress`` not ``in_progress``)")
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
        [System.Collections.Generic.List[string]]$Errors,
        [AllowNull()][string]$IterationDirectory,
        [AllowNull()][string]$ProjectRoot
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

    # Grandfather NON-in-flight iterations: the capacity check is a PLANNING-TIME guard. Only iterations
    # still being planned or executed must match the CURRENT iteration-config; once an iteration reaches
    # reviewing / retro / closeout its capacity is HISTORICAL TRUTH (the baseline at plan time), and a
    # later config change must not retroactively FAIL it. Firing the check on work that is already
    # executed and under review is the actual defect this guards against.
    #
    # Per Specrew's canonical iteration statuses, IN-FLIGHT = planning | executing (subject to current
    # config). Everything past implementation — reviewing | retro | complete | abandoned | *-complete |
    # closed | ... — is grandfathered (validated for self-consistency against the plan's own stated
    # Capacity per Iteration, below). This in-flight blacklist is forward-compatible: future / unlisted
    # closed status forms grandfather automatically without re-editing a whitelist (the bare-`retro`
    # historical corpus regression). A status-less plan is treated as in-flight (enforce config) unless
    # the durable closed-iteration index records it.
    $iterationStatus = ([string](Get-MarkdownMetadataValue -Lines $PlanLines -Label 'Status')).Trim().ToLowerInvariant()
    $inFlightStatuses = @('planning', 'executing')
    $isClosedIteration = (-not [string]::IsNullOrWhiteSpace($iterationStatus)) -and ($iterationStatus -notin $inFlightStatuses)

    # Belt-and-suspenders (Proposal 085): an explicit closed-iteration index entry forces grandfathering
    # even when the plan Status is blank or an unexpected in-flight value. Not load-bearing for the CI
    # path (indexed iterations are filtered out upstream) — covers manual -IncludeClosed audits.
    if (-not $isClosedIteration -and -not (Test-IsNullish $IterationDirectory) -and -not (Test-IsNullish $ProjectRoot)) {
        try {
            $relIterationPath = ([System.IO.Path]::GetRelativePath($ProjectRoot, $IterationDirectory)) -replace '\\', '/'
            if ($relIterationPath -match 'specs/([^/]+)/iterations/([^/]+)/?$') {
                if (Test-SpecrewIterationClosed -ProjectRoot $ProjectRoot -Feature $Matches[1] -Iteration $Matches[2]) {
                    $isClosedIteration = $true
                }
            }
        }
        catch {
            # Index unavailable / unreadable — fall back to status-based detection.
        }
    }

    foreach ($expectedSetting in $expectedValues.Keys) {
        if (-not $rowMap.ContainsKey($expectedSetting)) {
            $Errors.Add("plan.md Effort Model section is missing required setting '$expectedSetting'")
            continue
        }

        if ($isClosedIteration -and $expectedSetting -eq 'Capacity per Iteration') {
            continue  # grandfathered: historical capacity baseline, not current config
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
    # Closed iterations: validate the Capacity line cap against the plan's OWN stated Effort Model
    # 'Capacity per Iteration' (self-consistency / historical truth), not the current config baseline.
    $expectedCapacityTotal = if ($isClosedIteration -and $rowMap.ContainsKey('Capacity per Iteration')) {
        [string]$rowMap['Capacity per Iteration']
    }
    else {
        [string]$IterationConfig.capacity_per_iteration
    }
    if ($capacityTotal -ne $expectedCapacityTotal) {
        $mismatchSource = if ($isClosedIteration) { "the plan's own stated Capacity per Iteration (closed-iteration grandfathering)" } else { 'iteration-config capacity_per_iteration' }
        $Errors.Add("plan.md Capacity total '$capacityTotal' does not match $mismatchSource '$expectedCapacityTotal'")
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

# ============================================================================
# Spec 008 Extension: Reviewer-Regression Governance Validation
# ============================================================================

function Test-ReviewerRegressionLedgerInvariants {
    <#
    .SYNOPSIS
    Validates reviewer-regression ledger append-only and schema consistency invariants.
    
    .PARAMETER ProjectRoot
    The root directory of the project.
    #>
    param(
        [Parameter(Mandatory = $true)]
        [string]$ProjectRoot
    )

    $issues = New-Object System.Collections.Generic.List[string]
    $ledgerPath = Get-ReviewerRegressionLedgerPath -ProjectRoot $ProjectRoot
    
    if (-not (Test-Path -LiteralPath $ledgerPath -PathType Leaf)) {
        # Ledger is optional; no events means no violations
        return [pscustomobject]@{
            Pass   = $true
            Issues = @()
        }
    }

    $entries = Get-ReviewerRegressionLedgerEntries -ProjectRoot $ProjectRoot
    
    foreach ($entry in $entries) {
        # FR-006: Validate required fields
        if ([string]::IsNullOrWhiteSpace($entry.Feature)) {
            $issues.Add("$($entry.EventId): Missing required field 'Feature'") | Out-Null
        }
        
        if ([string]::IsNullOrWhiteSpace($entry.EventStatus)) {
            $issues.Add("$($entry.EventId): Missing required field 'Event Status'") | Out-Null
        }
        elseif ($entry.EventStatus -notin @('active', 'resolved', 'withdrawn')) {
            $issues.Add("$($entry.EventId): Invalid Event Status '$($entry.EventStatus)'. Must be active, resolved, or withdrawn.") | Out-Null
        }

        # FR-007: Validate soft-warning classification
        if ($null -ne $entry.Severity -and $entry.Severity -ne 'soft-warning') {
            $issues.Add("$($entry.EventId): Severity must always be 'soft-warning' per FR-007, found '$($entry.Severity)'") | Out-Null
        }

        # FR-015: Validate escalation action consistency
        if ($null -ne $entry.EscalationAction) {
            $validActions = @('stronger-class', 'same-class-independent-owner', 'human-direction-hold', 'none-yet')
            if ($entry.EscalationAction -notin $validActions) {
                $issues.Add("$($entry.EventId): Invalid Escalation Action '$($entry.EscalationAction)'") | Out-Null
            }

            if ($entry.EscalationAction -eq 'stronger-class' -and [string]::IsNullOrWhiteSpace($entry.EscalatedToClass)) {
                $issues.Add("$($entry.EventId): Escalation Action 'stronger-class' requires 'Escalated To Class' to be specified") | Out-Null
            }

            if ($entry.EscalationAction -eq 'same-class-independent-owner' -and [string]::IsNullOrWhiteSpace($entry.SameClassFallbackOwner)) {
                $issues.Add("$($entry.EventId): Escalation Action 'same-class-independent-owner' requires 'Same-Class Fallback Owner' to be specified") | Out-Null
            }
        }

        # FR-008: Validate withdrawal consistency
        if ($entry.EventStatus -eq 'withdrawn' -and [string]::IsNullOrWhiteSpace($entry.WithdrawalReference)) {
            $issues.Add("$($entry.EventId): Status 'withdrawn' requires 'Withdrawal Reference' per FR-008") | Out-Null
        }
    }

    return [pscustomobject]@{
        Pass   = $issues.Count -eq 0
        Issues = $issues.ToArray()
    }
}

function Test-ReviewerRegressionStateMirrorConsistency {
    <#
    .SYNOPSIS
    Validates that reviewer-regression-state managed blocks mirror ledger state correctly.
    
    .PARAMETER IterationDirectory
    The iteration directory containing state.md.
    
    .PARAMETER ProjectRoot
    The root directory of the project.
    #>
    param(
        [Parameter(Mandatory = $true)]
        [string]$IterationDirectory,
        
        [Parameter(Mandatory = $true)]
        [string]$ProjectRoot
    )

    $issues = New-Object System.Collections.Generic.List[string]
    $stateFilePath = Join-Path $IterationDirectory 'state.md'
    
    if (-not (Test-Path -LiteralPath $stateFilePath -PathType Leaf)) {
        # No state.md means no state mirror to validate
        return [pscustomobject]@{
            Pass   = $true
            Issues = @()
        }
    }

    $stateLines = @(Get-Content -LiteralPath $stateFilePath -Encoding UTF8)
    $hasReviewerRegressionBlock = (@($stateLines | Where-Object { $_ -match '<!-- >>> specrew-managed reviewer-regression-state >>> -->' })).Count -gt 0

    if (-not $hasReviewerRegressionBlock) {
        # Block is optional; no violation if absent
        return [pscustomobject]@{
            Pass   = $true
            Issues = @()
        }
    }

    # Parse the block
    $inBlock = $false
    $blockStatus = $null
    $blockFeature = $null

    foreach ($line in $stateLines) {
        if ($line -match '<!-- >>> specrew-managed reviewer-regression-state >>> -->') {
            $inBlock = $true
            continue
        }

        if ($line -match '<!-- <<< specrew-managed reviewer-regression-state <<< -->') {
            $inBlock = $false
            continue
        }

        if ($inBlock) {
            if ($line -match '^\s*-\s+\*\*Status\*\*:\s*(.+?)\s*$') {
                $blockStatus = $Matches[1].Trim()
            }
            elseif ($line -match '^\s*-\s+\*\*Feature\*\*:\s*(.+?)\s*$') {
                $featureValue = $Matches[1].Trim()
                if ($featureValue -ne '(none)') {
                    $blockFeature = $featureValue
                }
            }
        }
    }

    # Validate status is valid
    $validStatuses = @('inactive', 'active', 'held', 'resolved')
    if ($null -ne $blockStatus -and $blockStatus -notin $validStatuses) {
        $issues.Add("reviewer-regression-state block Status '$blockStatus' is invalid. Must be one of: $($validStatuses -join ', ')") | Out-Null
    }

    return [pscustomobject]@{
        Pass   = $issues.Count -eq 0
        Issues = $issues.ToArray()
    }
}

function Test-ReviewerRegressionDecisionsEntries {
    <#
    .SYNOPSIS
    Validates that decisions ledger entries for reviewer-regression events follow the correct schema.
    
    .PARAMETER ProjectRoot
    The root directory of the project.
    #>
    param(
        [Parameter(Mandatory = $true)]
        [string]$ProjectRoot
    )

    $issues = New-Object System.Collections.Generic.List[string]
    $decisionsEntries = Get-DecisionsLedgerEntries -ProjectRoot $ProjectRoot
    
    $reviewerRegressionEntries = @($decisionsEntries | Where-Object { 
        $null -ne $_.Type -and $_.Type -match 'reviewer-regression'
    })

    foreach ($entry in $reviewerRegressionEntries) {
        $validTypes = @('reviewer-regression-escalation', 'reviewer-regression-withdrawal', 'lockout-cap')
        if ($entry.Type -notin $validTypes) {
            $issues.Add("Decision entry '$($entry.DecisionId)' has unknown reviewer-regression Type '$($entry.Type)'. Expected: $($validTypes -join ', ')") | Out-Null
        }

        # FR-011: Lockout-cap decisions must be visible
        if ($entry.Type -eq 'lockout-cap' -and [string]::IsNullOrWhiteSpace($entry.DecisionId)) {
            $issues.Add("Lockout-cap decision entry must have a Decision ID per FR-011") | Out-Null
        }
    }

    return [pscustomobject]@{
        Pass   = $issues.Count -eq 0
        Issues = $issues.ToArray()
    }
}

# ============================================================================
# Main Execution (existing code continues)
# ============================================================================

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

<#
.SYNOPSIS
Tests form-vs-meaning parity for pre-review commit gate validation.

.DESCRIPTION
Validates that declared task completion in state.md matches observed committed changes
in git diff. Blocks review boundary advancement when form-vs-meaning gap is detected.

.PARAMETER IterationDirectory
Path to iteration directory (e.g., C:\Dev\Specrew\specs\028-review-evidence-integrity).

.PARAMETER Baseline
Git baseline reference to compare against HEAD (e.g., 'main', commit SHA).
Must be resolvable in the current repository.

.OUTPUTS
PSCustomObject with ValidationResult structure when violation detected, $null otherwise.
Returns error severity when declared >= 1 tasks but git diff is empty.

.NOTES
Feature: F-028 (Review Evidence Integrity)
Contract: specs/028-review-evidence-integrity/contracts/validator-rule-contract.md
RuleID: pre-review-commit-gate
Category: review-evidence-integrity
#>
function Test-PreReviewCommitGate {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true)]
        [string]$IterationDirectory,

        [Parameter(Mandatory=$true)]
        [string]$ProjectRoot,

        [AllowEmptyCollection()]
        [AllowEmptyString()]
        [string[]]$PlanLines = @(),

        [AllowEmptyCollection()]
        [AllowEmptyString()]
        [string[]]$StateLines = @(),
        
        [Parameter(Mandatory=$true)]
        [string]$Baseline
    )
    
    $statePath = Join-Path -Path $IterationDirectory -ChildPath 'state.md'
    if ($StateLines.Count -eq 0) {
        if (-not (Test-Path -LiteralPath $statePath -PathType Leaf)) {
            return $null
        }

        $StateLines = Get-MarkdownContent -Path $statePath
    }

    if ($PlanLines.Count -eq 0) {
        $planPath = Join-Path -Path $IterationDirectory -ChildPath 'plan.md'
        if (Test-Path -LiteralPath $planPath -PathType Leaf) {
            $PlanLines = Get-MarkdownContent -Path $planPath
        }
    }

    $completedTaskCount = Get-DeclaredCompletedTaskCount -PlanLines $PlanLines -StateLines $StateLines
    if ($completedTaskCount -lt 0) {
        $completedTaskCount = 0
    }
    
    $observedFileCount = 0
    try {
        $resolvedBaseline = @(& git -C $ProjectRoot rev-parse --verify "$Baseline" 2>$null)
        if ($LASTEXITCODE -ne 0) {
            return $null
        }
        
        $diffFiles = @(& git -C $ProjectRoot diff --name-only "$Baseline...HEAD" -- 2>$null)
        if ($LASTEXITCODE -eq 0) {
            $observedFileCount = @(
                $diffFiles |
                    ForEach-Object { [string]$_ } |
                    Where-Object { -not [string]::IsNullOrWhiteSpace($_) }
            ).Count
        }
    }
    catch {
        return $null
    }
    
    $parityResult = Test-FormMeaningParity -Declared $completedTaskCount -Observed $observedFileCount
    
    if ($parityResult.Gap -and $parityResult.Severity -eq 'error') {
        $message = "Form-vs-meaning gap detected: iteration artifacts declare $($parityResult.Declared) completed task(s) but git diff $Baseline...HEAD is empty (0 files changed)"
        $remediationHint = "Commit implementation work before review. Verify with ``git diff $Baseline...HEAD --stat``, then rerun validate-governance.ps1 before advancing to review."
        
        return [PSCustomObject]@{
            RuleID = 'pre-review-commit-gate'
            Category = 'review-evidence-integrity'
            Severity = 'error'
            Message = $message
            RemediationHint = $remediationHint
            Evidence = @{
                DeclaredTaskCount = $parityResult.Declared
                CommittedFileCount = $parityResult.Observed
                Baseline = $Baseline
                IterationPath = "file:///$($IterationDirectory -replace '\\', '/')"
            }
        }
    }
    
    # No violation detected
    return $null
}

function Test-IterationGovernance {
    param(
        [string]$IterationDirectory,
        [string]$ProjectRoot,
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
        $errors.Add("plan.md has invalid iteration status '$status' (expected one of: $($allowedIterationStatuses -join ' | '))")
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
    Test-Phase2HardeningGate -IterationDirectory $IterationDirectory -ProjectRoot $ProjectRoot -PlanLines $planLines -IterationStatus $status -Errors $errors

    $iterationConfig = Get-IterationConfigForValidation -IterationDirectory $IterationDirectory
    Test-PlanEffortModel -PlanLines $planLines -Capacity $capacity -IterationConfig $iterationConfig -Errors $errors -IterationDirectory $IterationDirectory -ProjectRoot $ProjectRoot
    Test-PlanningCapacity -IterationDirectory $IterationDirectory -Status $status -Capacity $capacity -Tasks $tasks -IterationConfig $iterationConfig -Errors $errors

    $taskStatuses = $tasks | ForEach-Object { $_.Status.Trim().ToLowerInvariant() }
    $hasNonTerminalTasks = [bool]($taskStatuses | Where-Object { $_ -notin $terminalTaskStatuses } | Select-Object -First 1)

    $driftPath = Join-Path -Path $IterationDirectory -ChildPath 'drift-log.md'
    $reviewPath = Join-Path -Path $IterationDirectory -ChildPath 'review.md'
    $retroPath = Join-Path -Path $IterationDirectory -ChildPath 'retro.md'
    $statePath = Join-Path -Path $IterationDirectory -ChildPath 'state.md'
    Test-ReviewDiagramsMermaidBlock -IterationDirectory $IterationDirectory -ProjectRoot $ProjectRoot
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
    if ($stateLines.Count -gt 0) {
        Test-IterationCloseoutEvidence -IterationDirectory $IterationDirectory -ProjectRoot $ProjectRoot -StateLines $stateLines -Errors $errors
    }

    switch ($status) {
        'executing' {
            Test-StateArtifact -IterationDirectory $IterationDirectory -ProjectRoot $ProjectRoot -Errors $errors
        }
        'reviewing' {
            Test-StateArtifact -IterationDirectory $IterationDirectory -ProjectRoot $ProjectRoot -Errors $errors
            if (-not (Test-Path -Path $driftPath -PathType Leaf)) {
                $errors.Add('Reviewing iterations require drift-log.md before review can start')
            }
            if ($hasNonTerminalTasks) {
                $errors.Add('Reviewing iterations require all tasks to be in terminal states')
            }
            
            # F-028: Pre-review commit gate - validate form-vs-meaning parity
            if ($stateLines.Count -gt 0) {
                $baselineRef = Get-MarkdownMetadataValue -Lines $stateLines -Label 'Baseline Ref'
                if (-not [string]::IsNullOrWhiteSpace($baselineRef)) {
                    $preReviewGateResult = Test-PreReviewCommitGate -IterationDirectory $IterationDirectory -ProjectRoot $ProjectRoot -PlanLines $planLines -StateLines $stateLines -Baseline $baselineRef
                    if ($null -ne $preReviewGateResult -and $preReviewGateResult.Severity -eq 'error') {
                        $errors.Add("[$($preReviewGateResult.Category)] $($preReviewGateResult.Message)`n    Remediation: $($preReviewGateResult.RemediationHint)")
                    }
                }
            }
            
            Test-ReviewArtifact -ReviewPath $reviewPath -ProjectRoot $ProjectRoot -IterationDirectory $IterationDirectory -IterationStatus $status -PlanTasks $tasks -Errors $errors
        }
        'retro' {
            Test-StateArtifact -IterationDirectory $IterationDirectory -ProjectRoot $ProjectRoot -Errors $errors
            if (-not (Test-Path -Path $driftPath -PathType Leaf)) {
                $errors.Add('Retro iterations require drift-log.md')
            }
            if ($hasNonTerminalTasks) {
                $errors.Add('Retro iterations require all tasks to be in terminal states')
            }
            Test-ReviewArtifact -ReviewPath $reviewPath -ProjectRoot $ProjectRoot -IterationDirectory $IterationDirectory -IterationStatus $status -PlanTasks $tasks -Errors $errors -RequireAcceptedVerdict
            Test-ReviewerCloseoutArtifacts -IterationDirectory $IterationDirectory -ProjectRoot $ProjectRoot -StateLines $stateLines -EnforceReviewerCloseout $EnforceReviewerCloseout -Errors $errors
        }
        'complete' {
            Test-StateArtifact -IterationDirectory $IterationDirectory -ProjectRoot $ProjectRoot -Errors $errors
            if (-not (Test-Path -Path $driftPath -PathType Leaf)) {
                $errors.Add('Complete iterations require drift-log.md')
            }
            if ($hasNonTerminalTasks) {
                $errors.Add('Complete iterations require all tasks to be in terminal states')
            }
            Test-ReviewArtifact -ReviewPath $reviewPath -ProjectRoot $ProjectRoot -IterationDirectory $IterationDirectory -IterationStatus $status -PlanTasks $tasks -Errors $errors -RequireAcceptedVerdict
            Test-RetroArtifact -RetroPath $retroPath -Errors $errors
            Test-ReviewerCloseoutArtifacts -IterationDirectory $IterationDirectory -ProjectRoot $ProjectRoot -StateLines $stateLines -EnforceReviewerCloseout $EnforceReviewerCloseout -Errors $errors
        }
        'abandoned' {
            Test-StateArtifact -IterationDirectory $IterationDirectory -ProjectRoot $ProjectRoot -Errors $errors
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

    # Reviewer-regression governance validation (spec 008)
    $ledgerValidation = Test-ReviewerRegressionLedgerInvariants -ProjectRoot $ProjectRoot
    if (-not $ledgerValidation.Pass) {
        $ledgerValidation.Issues | ForEach-Object { $errors.Add($_) }
    }
    
    $stateMirrorValidation = Test-ReviewerRegressionStateMirrorConsistency -IterationDirectory $IterationDirectory -ProjectRoot $ProjectRoot
    if (-not $stateMirrorValidation.Pass) {
        $stateMirrorValidation.Issues | ForEach-Object { $errors.Add($_) }
    }
    
    $decisionsValidation = Test-ReviewerRegressionDecisionsEntries -ProjectRoot $ProjectRoot
    if (-not $decisionsValidation.Pass) {
        $decisionsValidation.Issues | ForEach-Object { $errors.Add($_) }
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

function Add-ApprovalReuseValidationErrors {
    param(
        [AllowEmptyCollection()]
        [string[]]$Targets,
        [string]$ProjectRoot,
        [hashtable]$ResultMap
    )

    if (@($Targets).Count -eq 0) {
        return
    }

    $groupedTargets = @{}
    foreach ($target in @($Targets | Where-Object { Test-IterationRequiresCanonicalStateSchema -IterationDirectory $_ })) {
        $featureDirectory = Split-Path -Parent (Split-Path -Parent $target)
        if (-not $groupedTargets.ContainsKey($featureDirectory)) {
            $groupedTargets[$featureDirectory] = New-Object System.Collections.Generic.List[string]
        }

        $null = $groupedTargets[$featureDirectory].Add($target)
    }

    foreach ($featureDirectory in $groupedTargets.Keys) {
        $featureTargets = @($groupedTargets[$featureDirectory])
        if ($featureTargets.Count -lt 2) {
            continue
        }

        $recordsByTarget = @{}
        foreach ($target in $featureTargets) {
            $recordsByTarget[$target] = @(Get-ImplementationApprovalEvidenceRecords -IterationDirectory $target -ProjectRoot $ProjectRoot)
        }

        $seenPairs = @{}
        for ($leftIndex = 0; $leftIndex -lt $featureTargets.Count; $leftIndex++) {
            for ($rightIndex = $leftIndex + 1; $rightIndex -lt $featureTargets.Count; $rightIndex++) {
                $leftTarget = $featureTargets[$leftIndex]
                $rightTarget = $featureTargets[$rightIndex]

                foreach ($leftRecord in $recordsByTarget[$leftTarget]) {
                    foreach ($rightRecord in $recordsByTarget[$rightTarget]) {
                        if ([string]::IsNullOrWhiteSpace($leftRecord.NormalizedText) -or $leftRecord.NormalizedText -cne $rightRecord.NormalizedText) {
                            continue
                        }

                        if ([bool]$leftRecord.BlanketScopeDeclared -or [bool]$rightRecord.BlanketScopeDeclared) {
                            continue
                        }

                        $pairKey = '{0}|{1}|{2}|{3}' -f $leftRecord.RelativeArtifactPath, $rightRecord.RelativeArtifactPath, $leftRecord.NormalizedText, $leftRecord.Heading
                        if ($seenPairs.ContainsKey($pairKey)) {
                            continue
                        }

                        $seenPairs[$pairKey] = $true
                        $leftErrors = $ResultMap[$leftTarget].Errors
                        $rightErrors = $ResultMap[$rightTarget].Errors
                        $leftIterationPath = Convert-ToRepoMarkdownPath -ProjectRoot $ProjectRoot -TargetPath $leftTarget
                        $rightIterationPath = Convert-ToRepoMarkdownPath -ProjectRoot $ProjectRoot -TargetPath $rightTarget
                        $quoteText = $leftRecord.NormalizedText
                        $remediationHint = 'Use iteration-specific implementation approval evidence, or explicitly declare a blanket multi-iteration authorization scope in the approval block.'

                        Add-RepoStructuredValidationFailure -Errors $leftErrors -ProjectRoot $ProjectRoot -TargetPath $leftRecord.ArtifactPath -LineNumber $leftRecord.LineNumber -Category 'approval-reuse' -Message ("Implementation approval evidence in {0} reuses the normalized quote from {1}: ""{2}""" -f $leftIterationPath, $rightRecord.RelativeArtifactPath, $quoteText) -RemediationHint $remediationHint
                        Add-RepoStructuredValidationFailure -Errors $rightErrors -ProjectRoot $ProjectRoot -TargetPath $rightRecord.ArtifactPath -LineNumber $rightRecord.LineNumber -Category 'approval-reuse' -Message ("Implementation approval evidence in {0} reuses the normalized quote from {1}: ""{2}""" -f $rightIterationPath, $leftRecord.RelativeArtifactPath, $quoteText) -RemediationHint $remediationHint
                    }
                }
            }
        }
    }
}

function Get-InteractionModelIterationContextFromPath {
    param([AllowNull()][string]$IterationDirectory)

    if ([string]::IsNullOrWhiteSpace($IterationDirectory)) {
        return $null
    }

    $normalizedPath = [System.IO.Path]::GetFullPath($IterationDirectory)
    $match = [regex]::Match($normalizedPath, '[\\/]specs[\\/](?<feature>\d+)-[^\\/]+[\\/]iterations[\\/](?<iteration>\d+)$')
    if (-not $match.Success) {
        return $null
    }

    return [pscustomobject]@{
        FeatureNumber = [int]$match.Groups['feature'].Value
        IterationNumber = [int]$match.Groups['iteration'].Value
    }
}

function Get-InteractionModelGitBoundaryCommits {
    param([Parameter(Mandatory = $true)][string]$ProjectRoot)

    $rawLog = @(git -C $ProjectRoot --no-pager log --reverse --format='%H%x09%cI%x09%s' 2>$null)
    $records = New-Object System.Collections.Generic.List[object]
    foreach ($line in $rawLog) {
        if ([string]::IsNullOrWhiteSpace($line)) {
            continue
        }

        $parts = $line -split "`t", 3
        if ($parts.Count -lt 3) {
            continue
        }

        $boundaryMatch = Get-InteractionModelBoundaryCommitMatch -Subject $parts[2]
        if ($null -eq $boundaryMatch) {
            continue
        }

        $committedAt = $null
        try {
            $committedAt = [DateTimeOffset]::Parse($parts[1])
        }
        catch {
            continue
        }

        $records.Add([pscustomobject]@{
                CommitHash      = $parts[0]
                CommittedAt     = $committedAt
                Boundary        = $boundaryMatch.Boundary
                FeatureNumber   = $boundaryMatch.FeatureNumber
                IterationNumber = $boundaryMatch.IterationNumber
                Subject         = $boundaryMatch.Subject
            }) | Out-Null
    }

    return $records.ToArray()
}

function Add-InteractionModelValidationErrors {
    param(
        [AllowEmptyCollection()]
        [Parameter(Mandatory = $true)][string[]]$Targets,
        [Parameter(Mandatory = $true)][string]$ProjectRoot,
        [Parameter(Mandatory = $true)][hashtable]$ResultMap
    )

    if (@($Targets).Count -eq 0) {
        return
    }

    $boundaryCommits = @(Get-InteractionModelGitBoundaryCommits -ProjectRoot $ProjectRoot)
    foreach ($target in $Targets) {
        if (-not $ResultMap.ContainsKey($target)) {
            continue
        }

        $context = Get-InteractionModelIterationContextFromPath -IterationDirectory $target
        if ($null -eq $context -or $context.FeatureNumber -lt 16) {
            continue
        }

        $errors = $ResultMap[$target].Errors
        $authorizationEntries = @(Get-InteractionModelAuthorizationEntries -ProjectRoot $ProjectRoot -FeatureNumber $context.FeatureNumber -IterationNumber $context.IterationNumber)
        foreach ($entry in $authorizationEntries) {
            $missingFields = New-Object System.Collections.Generic.List[string]
            foreach ($requiredField in @('DecisionId', 'Type', 'Boundary', 'ApprovingHuman', 'RecordedAt', 'CommitReference', 'AuthorizationText')) {
                $value = [string]$entry.$requiredField
                if ([string]::IsNullOrWhiteSpace($value)) {
                    $missingFields.Add($requiredField) | Out-Null
                }
            }

            if ($missingFields.Count -gt 0) {
                Add-RepoStructuredValidationFailure -Errors $errors -ProjectRoot $ProjectRoot -TargetPath (Get-DecisionsLedgerPath -ProjectRoot $ProjectRoot) -LineNumber $null -Category 'authorization-record-shape' -Message ("Authorization entry '{0}' is missing required field(s): {1}" -f $entry.Title, ($missingFields -join ', ')) -RemediationHint 'Record Decision ID, Type, Boundary, Approving Human, Recorded At, Commit Reference, and Authorization Text on every authorization entry.'
            }

            if ($entry.Type -notin @('authorization', 'sign-off')) {
                Add-RepoStructuredValidationFailure -Errors $errors -ProjectRoot $ProjectRoot -TargetPath (Get-DecisionsLedgerPath -ProjectRoot $ProjectRoot) -LineNumber $null -Category 'authorization-record-shape' -Message ("Authorization entry '{0}' uses invalid Type '{1}'" -f $entry.Title, $entry.Type) -RemediationHint 'Use Type authorization or sign-off for Feature 016 boundary approvals.'
            }

            if ([string]$entry.RecordedAt -notmatch '^\d{4}-\d{2}-\d{2}T\d{2}:\d{2}:\d{2}Z$') {
                Add-RepoStructuredValidationFailure -Errors $errors -ProjectRoot $ProjectRoot -TargetPath (Get-DecisionsLedgerPath -ProjectRoot $ProjectRoot) -LineNumber $null -Category 'authorization-record-shape' -Message ("Authorization entry '{0}' uses non-canonical Recorded At '{1}'" -f $entry.Title, $entry.RecordedAt) -RemediationHint 'Use UTC ISO 8601 seconds precision (YYYY-MM-DDTHH:MM:SSZ) for Feature 016 authorization entries.'
            }

            $normalizedBoundary = Normalize-InteractionModelBoundaryName -Boundary $entry.Boundary
            if ([string]$entry.Boundary -match '[,;/]' -or ([string]$entry.Boundary -match '\band\b' -and $normalizedBoundary -ne 'hardening-gate-and-implementation-auth')) {
                Add-RepoStructuredValidationFailure -Errors $errors -ProjectRoot $ProjectRoot -TargetPath (Get-DecisionsLedgerPath -ProjectRoot $ProjectRoot) -LineNumber $null -Category 'authorization-record-shape' -Message ("Authorization entry '{0}' records multiple boundaries in one entry: '{1}'" -f $entry.Title, $entry.Boundary) -RemediationHint 'Record one boundary per authorization entry and split paired hardening-gate + implementation authorization into two entries.'
            }
            elseif ($normalizedBoundary -notin @('planning', 'hardening-gate-and-implementation-auth', 'hardening-gate-signoff', 'implementation', 'review-boundary', 'review-verdict-signoff', 'retro-boundary', 'iteration-closeout', 'feature-closeout')) {
                Add-RepoStructuredValidationFailure -Errors $errors -ProjectRoot $ProjectRoot -TargetPath (Get-DecisionsLedgerPath -ProjectRoot $ProjectRoot) -LineNumber $null -Category 'authorization-record-shape' -Message ("Authorization entry '{0}' uses unknown Boundary '{1}'" -f $entry.Title, $entry.Boundary) -RemediationHint 'Use the canonical boundary names from Feature 016.'
            }
        }

        $seenAuthorizationTexts = [System.Collections.Generic.HashSet[string]]::new([System.StringComparer]::OrdinalIgnoreCase)
        foreach ($entry in $authorizationEntries) {
            $normalizedText = if ([string]::IsNullOrWhiteSpace([string]$entry.AuthorizationText)) {
                ''
            }
            else {
                (([string]$entry.AuthorizationText -replace '(?m)^\s*>\s?', '' -replace '\s+', ' ').Trim().ToLowerInvariant())
            }

            if ([string]::IsNullOrWhiteSpace($normalizedText) -or -not $seenAuthorizationTexts.Add($normalizedText)) {
                continue
            }

            if ($normalizedText -notmatch '(?i)hardening-gate|hardening gate' -or $normalizedText -notmatch '(?i)implement(?:ation)?') {
                continue
            }

            $matchingEntries = @(
                $authorizationEntries |
                    Where-Object {
                        $candidateText = if ([string]::IsNullOrWhiteSpace([string]$_.AuthorizationText)) {
                            ''
                        }
                        else {
                            (([string]$_.AuthorizationText -replace '(?m)^\s*>\s?', '' -replace '\s+', ' ').Trim().ToLowerInvariant())
                        }

                        $candidateText -eq $normalizedText
                    }
            )
            $groupBoundaries = @($matchingEntries | ForEach-Object { Normalize-InteractionModelBoundaryName -Boundary $_.Boundary })
            Write-Verbose "[DEBUG] Paired-auth check: Found $($matchingEntries.Count) matching entries with boundaries: $($groupBoundaries -join ', ')"
            Write-Verbose "[DEBUG] Has hardening-gate-signoff: $($groupBoundaries -contains 'hardening-gate-signoff')"
            Write-Verbose "[DEBUG] Has implementation: $($groupBoundaries -contains 'implementation')"
            
            # Only flag as paired-auth issue if the text appears to be authorizing (not just mentioning) both boundaries
            # Heuristic: if we found entries for this text, at least one must be hardening-gate-signoff or implementation
            # AND the group must have < 2 distinct boundaries when it should have both
            $hasCoreAuthBoundary = ($groupBoundaries -contains 'hardening-gate-signoff') -or ($groupBoundaries -contains 'implementation')
            if (-not $hasCoreAuthBoundary) {
                Write-Verbose "[DEBUG] Skipping paired-auth check for authorization text that mentions both boundaries but isn't authorizing either"
                continue
            }
            
            if ($groupBoundaries -notcontains 'hardening-gate-signoff' -or $groupBoundaries -notcontains 'implementation' -or $matchingEntries.Count -lt 2) {
                Add-RepoStructuredValidationFailure -Errors $errors -ProjectRoot $ProjectRoot -TargetPath (Get-DecisionsLedgerPath -ProjectRoot $ProjectRoot) -LineNumber $null -Category 'authorization-record-shape' -Message 'A paired hardening-gate sign-off + implementation authorization paste was not expanded into two distinct entries.' -RemediationHint 'Create separate hardening-gate-signoff and implementation authorization records that preserve the same authorization text.'
            }
        }

        $iterationBoundaryCommits = @(
            $boundaryCommits |
                Where-Object {
                    $_.FeatureNumber -eq $context.FeatureNumber -and
                    $_.IterationNumber -eq $context.IterationNumber
                }
        )

        if ($iterationBoundaryCommits.Count -eq 0) {
            continue
        }

        foreach ($boundaryCommit in $iterationBoundaryCommits) {
            $normalizedBoundary = Normalize-InteractionModelBoundaryName -Boundary $boundaryCommit.Boundary
            
            # The 'hardening-gate-and-implementation-auth' boundary is a bookkeeping commit that RECORDS authorizations
            # rather than a boundary that requires its own authorization. Skip it.
            if ($normalizedBoundary -eq 'hardening-gate-and-implementation-auth') {
                Write-Verbose "[DEBUG] Skipping hardening-gate-and-implementation-auth boundary commit (bookkeeping boundary)"
                continue
            }
            
            Write-Verbose "[DEBUG] Checking boundary commit: subject='$($boundaryCommit.Subject)' hash='$($boundaryCommit.CommitHash)' boundary='$normalizedBoundary'"
            $matchingAuthorization = @(
                $authorizationEntries |
                    Where-Object {
                        $entryCommitRef = [string]$_.CommitReference
                        if ([string]::IsNullOrWhiteSpace($entryCommitRef) -or $entryCommitRef.Trim().ToLowerInvariant() -eq 'pending') {
                            return $false
                        }

                        $entryNormalizedBoundary = Normalize-InteractionModelBoundaryName -Boundary $_.Boundary
                        $trimmedEntryRef = $entryCommitRef.Trim()
                        $fullHashMatch = $trimmedEntryRef -eq $boundaryCommit.CommitHash
                        $shortHashMatch = $boundaryCommit.CommitHash.StartsWith($trimmedEntryRef, [System.StringComparison]::OrdinalIgnoreCase)
                        
                        $hashMatch = $fullHashMatch -or $shortHashMatch
                        $boundaryMatch = $entryNormalizedBoundary -eq $normalizedBoundary
                        $humanNonNull = -not (Test-IsNullish ([string]$_.ApprovingHuman))
                        
                        if ($hashMatch -and $boundaryMatch -and $humanNonNull) {
                            Write-Verbose "[DEBUG]   ✓ MATCHED: entry boundary='$entryNormalizedBoundary' ref='$trimmedEntryRef' human='$($_.ApprovingHuman)'"
                        }
                        
                        $hashMatch -and $boundaryMatch -and $humanNonNull
                    }
            )

            if ($matchingAuthorization.Count -eq 0) {
                Add-RepoStructuredValidationFailure -Errors $errors -ProjectRoot $ProjectRoot -TargetPath (Join-Path $target 'state.md') -LineNumber $null -Category 'bundled-boundary-advance' -Message ("Boundary commit '{0}' (hash {1}) for Feature {2:d3} iteration {3:d3} was recorded without a matching authorization entry in .squad\decisions.md whose Commit Reference equals or starts with that hash and whose Approving Human is non-null." -f $boundaryCommit.Subject, $boundaryCommit.CommitHash, $context.FeatureNumber, $context.IterationNumber) -RemediationHint 'Record a human authorization whose Commit Reference matches this boundary commit hash (full or short form); one authorization advances at most one boundary.'
            }
        }
    }
}

function Invoke-InteractionModelResponseValidation {
    param(
        [Parameter(Mandatory = $true)][string]$ProjectRoot,
        [AllowEmptyString()][string]$ResponseText,
        [string[]]$IterationTargets,
        [string]$BoundaryName,
        [string]$ResponseScope,
        [string]$BarePathBoundaryHandoffSeverity
    )

    $validatorScript = Join-Path (Split-Path -Parent $PSScriptRoot) 'validators\handoff-governance-validator.ps1'
    if (-not (Test-Path -LiteralPath $validatorScript -PathType Leaf)) {
        throw "Missing handoff governance validator '$validatorScript'."
    }

    $validatorArgs = @{
        ResponseText = $ResponseText
        ProjectRoot  = $ProjectRoot
        ResponseScope = $ResponseScope
    }

    if ($IterationTargets.Count -gt 0) {
        $validatorArgs['IterationPath'] = $IterationTargets[0]
    }

    if (-not [string]::IsNullOrWhiteSpace($BoundaryName)) {
        $validatorArgs['BoundaryName'] = $BoundaryName
    }

    if (-not [string]::IsNullOrWhiteSpace($BarePathBoundaryHandoffSeverity)) {
        $validatorArgs['BarePathBoundaryHandoffSeverity'] = $BarePathBoundaryHandoffSeverity
    }

    $validatorOutput = @(& $validatorScript @validatorArgs 2>&1)
    foreach ($line in $validatorOutput) {
        Write-Host $line
    }
    return [int]$LASTEXITCODE
}

try {
    $resolvedProjectPath = (Resolve-Path -Path (Resolve-ProjectPath -Path $ProjectPath)).Path
    if ($FullRun -and $ChangedOnly) {
        throw '-FullRun and -ChangedOnly are mutually exclusive. Use -FullRun for a deliberate full-repo run or -ChangedOnly for explicit changed-only scope.'
    }

    if (-not [string]::IsNullOrWhiteSpace($ResponseText)) {
        $responseValidationExitCode = Invoke-InteractionModelResponseValidation -ProjectRoot $resolvedProjectPath -ResponseText $ResponseText -IterationTargets @() -BoundaryName $BoundaryName -ResponseScope $ResponseScope -BarePathBoundaryHandoffSeverity $BarePathBoundaryHandoffSeverity
        Write-ValidatorSummaryAndExit -ProjectRoot $resolvedProjectPath -ExitCode $responseValidationExitCode -HardWarnings $(if ($responseValidationExitCode -eq 0) { 0 } else { 1 })
    }

    # Proposal 086 Pillar 5: repetition detector. Log the invocation; if the
    # last 2 invocations have the same (target_hash, code_hash), this is the 3rd
    # consecutive run against unchanged code — emit a diagnostic warning.
    # Wrapped in try/catch so the detector never blocks validation (FR-005).
    # Per Copilot review PR #695: target signature normalizes each IterationPath
    # to its absolute resolved form (when the file exists) so different relative
    # vs absolute spellings for the same iteration hash identically.
    try {
        $detectorTargetSig = if ($null -ne $IterationPath -and @($IterationPath | Where-Object { -not [string]::IsNullOrWhiteSpace([string]$_) }).Count -gt 0) {
            $normalized = foreach ($p in $IterationPath) {
                if ([string]::IsNullOrWhiteSpace([string]$p)) { continue }
                try {
                    $resolved = (Resolve-Path -LiteralPath $p -ErrorAction Stop).Path
                    $resolved.Replace('\', '/').ToLowerInvariant()
                }
                catch {
                    ([string]$p).Replace('\', '/').ToLowerInvariant()
                }
            }
            (@($normalized) | Sort-Object) -join '|'
        } else { '<all>' }
        $detectorTargetHash = [System.BitConverter]::ToString(
            [System.Security.Cryptography.SHA256]::Create().ComputeHash(
                [System.Text.Encoding]::UTF8.GetBytes($detectorTargetSig)
            )
        ).Replace('-', '').ToLowerInvariant()
        $detectorCodeHash = Get-ValidatorCodeHash -ProjectRoot $resolvedProjectPath
        if (-not [string]::IsNullOrWhiteSpace($detectorCodeHash)) {
            $repetitionCount = Test-SpecrewCommandRepetition -ProjectRoot $resolvedProjectPath -TargetHash $detectorTargetHash -CodeHash $detectorCodeHash
            if ($repetitionCount -ge 2) {
                Write-Host ("[validator-repetition-warning] Detected {0}-consecutive invocation against unchanged code (target_hash={1}). Cache served prior runs; re-running is unlikely to surface new findings. To force fresh validation: -NoCacheRead." -f ($repetitionCount + 1), $detectorTargetHash.Substring(0, 8))
            }
            Add-SpecrewCommandInvocation -ProjectRoot $resolvedProjectPath -Command 'validate-governance.ps1' -TargetHash $detectorTargetHash -CodeHash $detectorCodeHash
        }
    }
    catch {
        # Detector failure must not block validation (FR-005)
    }

    # Proposal 085: -RebuildClosedIndex is a special early-exit mode. Walks every
    # specs/<feature>/iterations/<iter>/state.md, detects closed iterations, and
    # regenerates .specrew/closed-iterations.yml from scratch. Use after the index
    # is deleted or appears stale.
    #
    # Per Copilot review on PR #661: the rebuild must hold the same file lock that
    # Add-SpecrewClosedIterationEntry uses, otherwise a concurrent iteration-closeout
    # append could be lost. Acquire the lock once, walk state.md files, build the
    # complete YAML in memory, write atomically. No nested locking.
    if ($RebuildClosedIndex) {
        $indexPath = Get-SpecrewClosedIterationIndexPath -ProjectRoot $resolvedProjectPath
        $indexDir = Split-Path -Parent $indexPath
        if (-not (Test-Path -LiteralPath $indexDir -PathType Container)) {
            $null = New-Item -ItemType Directory -Path $indexDir -Force
        }
        $specsRoot = Join-Path -Path $resolvedProjectPath -ChildPath 'specs'
        $stateFiles = if (Test-Path -LiteralPath $specsRoot -PathType Container) {
            Get-ChildItem -Path $specsRoot -Filter 'state.md' -Recurse -File -ErrorAction SilentlyContinue
        }
        else { @() }

        # Build entries in memory (read-only state.md walk; no lock needed for reads).
        $entries = New-Object System.Collections.Generic.List[hashtable]
        foreach ($sf in $stateFiles) {
            $entry = Get-SpecrewClosedIterationFromStateFile -StatePath $sf.FullName
            if ($null -ne $entry) {
                $null = $entries.Add(@{
                    feature   = $entry.feature
                    iteration = $entry.iteration
                    closed_at = $entry.closed_at
                })
            }
        }

        # Acquire the same file lock Add-SpecrewClosedIterationEntry uses, then
        # write the complete YAML in one atomic operation. No interleaving possible.
        Invoke-WithFileLock -Path $indexPath -ScriptBlock {
            $lines = @(
                '# Specrew closed-iteration index (Proposal 085).',
                '# Append-only. Append at iteration-closeout boundary via Add-SpecrewClosedIterationEntry.',
                '# Regenerate from state.md walk via: validate-governance.ps1 -RebuildClosedIndex',
                'closed:'
            )
            foreach ($e in $entries) {
                $lines += "  - feature: $($e.feature)"
                $lines += "    iteration: $($e.iteration)"
                $lines += "    closed_at: $($e.closed_at)"
            }
            $combined = $lines -join [Environment]::NewLine
            Set-Content -LiteralPath $indexPath -Value $combined -Encoding UTF8
        }

        Write-Host ("[closed-iteration-index] rebuilt: {0} closed iterations indexed at {1}" -f $entries.Count, $indexPath)
        exit 0
    }

    $explicitIterationPathsProvided = ($null -ne $IterationPath) -and @(
        $IterationPath | Where-Object { -not [string]::IsNullOrWhiteSpace([string]$_) }
    ).Count -gt 0
    $targets = @()
    $validatorScoped = $false
    $scopeChangedIterations = $null
    $scopeFallbackVerboseMessage = $null
    $currentBranch = Get-GitCurrentBranchName -ProjectRoot $resolvedProjectPath

    if ($explicitIterationPathsProvided) {
        $targets = @(Resolve-IterationTarget -ResolvedProjectPath $resolvedProjectPath -ExplicitIterationPaths $IterationPath)
        $validatorScoped = $true
        $scopeBanner = Get-ValidatorScopeBanner -Mode 'explicit-targets' -IterationCount $targets.Count
    }
    elseif ($FullRun) {
        $targets = @(Resolve-IterationTarget -ResolvedProjectPath $resolvedProjectPath -ExplicitIterationPaths $IterationPath)
        $scopeBanner = Get-ValidatorScopeBanner -Mode 'full-repo' -IterationCount $targets.Count -Reason '-FullRun override' -CurrentBranch $currentBranch
    }
    elseif ($ChangedOnly) {
        $scopeChangedIterations = Get-ChangedIterations -ProjectRoot $resolvedProjectPath
        if ($scopeChangedIterations.UseScopedTargets) {
            $targets = @($scopeChangedIterations.IterationPaths)
            $validatorScoped = $true
            $scopeBanner = Get-ValidatorScopeBanner -Mode 'changed-only' -IterationCount $targets.Count -BaseRef $scopeChangedIterations.BaseRef -DiffFileCount $scopeChangedIterations.DiffFileCount
        }
        else {
            $targets = @(Resolve-IterationTarget -ResolvedProjectPath $resolvedProjectPath -ExplicitIterationPaths $IterationPath)
            $scopeReason = if ($scopeChangedIterations.Reason -in @('base-ref-undetectable', 'base-ref-unresolved')) {
                'base-ref-undetectable'
            }
            else {
                $scopeChangedIterations.Reason
            }
            $scopeBanner = Get-ValidatorScopeBanner -Mode 'full-repo' -IterationCount $targets.Count -Reason $scopeReason -CurrentBranch $currentBranch
            if ($env:SPECREW_VALIDATOR_VERBOSE -eq '1') {
                $resolvedBase = if ([string]::IsNullOrWhiteSpace([string]$scopeChangedIterations.BaseRef)) { '(unresolved)' } else { [string]$scopeChangedIterations.BaseRef }
                $scopeFallbackVerboseMessage = "[validator] -ChangedOnly fallback to full validation: {0} (base {1})" -f $scopeChangedIterations.Reason, $resolvedBase
            }
        }
    }
    else {
        if ($currentBranch -in @('main', 'master')) {
            $targets = @(Resolve-IterationTarget -ResolvedProjectPath $resolvedProjectPath -ExplicitIterationPaths $IterationPath)
            $scopeBanner = Get-ValidatorScopeBanner -Mode 'full-repo' -IterationCount $targets.Count -Reason 'on-main' -CurrentBranch $currentBranch
        }
        else {
            $scopeChangedIterations = Get-ChangedIterations -ProjectRoot $resolvedProjectPath
            if ($scopeChangedIterations.UseScopedTargets) {
                $targets = @($scopeChangedIterations.IterationPaths)
                $validatorScoped = $true
                $scopeBanner = Get-ValidatorScopeBanner -Mode 'auto-scoped' -IterationCount $targets.Count -BaseRef $scopeChangedIterations.BaseRef -DiffFileCount $scopeChangedIterations.DiffFileCount
            }
            else {
                $targets = @(Resolve-IterationTarget -ResolvedProjectPath $resolvedProjectPath -ExplicitIterationPaths $IterationPath)
                $scopeReason = if ($scopeChangedIterations.Reason -in @('base-ref-undetectable', 'base-ref-unresolved')) {
                    'base-ref-undetectable'
                }
                else {
                    $scopeChangedIterations.Reason
                }
                $scopeBanner = Get-ValidatorScopeBanner -Mode 'full-repo' -IterationCount $targets.Count -Reason $scopeReason -CurrentBranch $currentBranch
                if ($env:SPECREW_VALIDATOR_VERBOSE -eq '1') {
                    $resolvedBase = if ([string]::IsNullOrWhiteSpace([string]$scopeChangedIterations.BaseRef)) { '(unresolved)' } else { [string]$scopeChangedIterations.BaseRef }
                    $scopeFallbackVerboseMessage = "[validator] Auto-scope fallback to full validation: {0} (base {1})" -f $scopeChangedIterations.Reason, $resolvedBase
                }
            }
        }
    }

    # Proposal 085: on full-repo paths, filter out closed iterations unless
    # -IncludeClosed. Scoped paths (changed-only / auto-scoped / explicit-targets)
    # are unaffected — closed iterations naturally aren't in those sets.
    $closedSkippedCount = 0
    if (-not $IncludeClosed -and -not $validatorScoped -and $targets.Count -gt 0) {
        $closedIndex = Get-SpecrewClosedIterationIndex -ProjectRoot $resolvedProjectPath
        if ($closedIndex.Count -gt 0) {
            $filtered = New-Object System.Collections.Generic.List[string]
            foreach ($tp in $targets) {
                $normalized = $tp -replace '\\', '/'
                if ($normalized -match 'specs/([^/]+)/iterations/([^/]+)$') {
                    $feature = $Matches[1]
                    $iteration = $Matches[2]
                    if ($closedIndex.ContainsKey("$feature/$iteration")) {
                        $closedSkippedCount++
                        continue
                    }
                }
                $null = $filtered.Add($tp)
            }
            $targets = @($filtered.ToArray())
            if ($closedSkippedCount -gt 0) {
                Write-Host ("[validator-scope] closed-iteration filter: {0} closed iterations skipped (use -IncludeClosed to validate them)" -f $closedSkippedCount)
            }
        }
    }
    Write-Host $scopeBanner
    $script:ValidatorMode = if ($validatorScoped) { 'scoped' } else { 'unscoped' }
    $script:ValidatorIterationsValidated = $targets.Count

    $teamRoles = Get-TeamRoleMap -ResolvedProjectPath $resolvedProjectPath

    $teamValidationErrors = New-Object System.Collections.Generic.List[string]
    Test-BaselineTeamMembers -TeamRoles $teamRoles -Errors $teamValidationErrors

    if ($teamValidationErrors.Count -gt 0) {
        Write-Host "FAIL Squad team validation" -ForegroundColor Red
        foreach ($errorMessage in $teamValidationErrors) {
            Write-Host "  - $errorMessage" -ForegroundColor Red
        }
        Write-ValidatorSummaryAndExit -ProjectRoot $resolvedProjectPath -ExitCode 1 -HardWarnings $teamValidationErrors.Count
    }

    $classifierCompatibilityErrors = New-Object System.Collections.Generic.List[string]
    Test-CopilotInstructionsClassifierCompatibility -ProjectRoot $resolvedProjectPath -Errors $classifierCompatibilityErrors
    if ($classifierCompatibilityErrors.Count -gt 0) {
        Write-Host 'FAIL validate-governance' -ForegroundColor Red
        foreach ($errorMessage in $classifierCompatibilityErrors) {
            Write-Host "  - $errorMessage" -ForegroundColor Red
        }
        Write-ValidatorSummaryAndExit -ProjectRoot $resolvedProjectPath -ExitCode 1 -HardWarnings $classifierCompatibilityErrors.Count
    }

    Test-PublicReadinessSurfaces -ProjectRoot $resolvedProjectPath
    Test-DashboardGovernanceSurfaces -ProjectRoot $resolvedProjectPath
    Test-PostShipProposalAmendmentGovernance -ProjectRoot $resolvedProjectPath
    $handoffEvidenceFailureCount = Test-HandoffEvidenceGovernance -ProjectRoot $resolvedProjectPath
    if ($handoffEvidenceFailureCount -gt 0) {
        Write-ValidatorSummaryAndExit -ProjectRoot $resolvedProjectPath -ExitCode 1 -HardWarnings $handoffEvidenceFailureCount
    }
    Test-WrongLocationCanonicalArtifacts -ProjectRoot $resolvedProjectPath
    # Pillar 4 (FR-021): live state-advance-without-verdict cross-check.
    Test-BoundaryStateAdvanceVerdict -ProjectRoot $resolvedProjectPath
    $approvedStatusFailureCount = Test-ApprovedFeatureStatusVerdictEvidence -ProjectRoot $resolvedProjectPath
    if ($approvedStatusFailureCount -gt 0) {
        Write-ValidatorSummaryAndExit -ProjectRoot $resolvedProjectPath -ExitCode 1 -HardWarnings $approvedStatusFailureCount
    }
    Test-HandoffInternalReferenceSurfaces -ProjectRoot $resolvedProjectPath

    # Proposal 090: session-state boundary canonical-string + active/boundary
    # contradiction rule. Catches the Crew-bypass bug class that bit F-030/083
    # four separate times (feature-closed string, iteration-closed string,
    # active=true post-closeout, etc.).
    $boundaryCanonicalFailureCount = Test-SessionStateBoundaryCanonical -ProjectRoot $resolvedProjectPath
    if ($boundaryCanonicalFailureCount -gt 0) {
        Write-ValidatorSummaryAndExit -ProjectRoot $resolvedProjectPath -ExitCode 1 -HardWarnings $boundaryCanonicalFailureCount
    }

    if (-not [string]::IsNullOrWhiteSpace($scopeFallbackVerboseMessage)) {
        Write-Host $scopeFallbackVerboseMessage
    }
    if (-not [string]::IsNullOrWhiteSpace($ResponseText)) {
        $responseValidationExitCode = Invoke-InteractionModelResponseValidation -ProjectRoot $resolvedProjectPath -ResponseText $ResponseText -IterationTargets $targets -BoundaryName $BoundaryName -ResponseScope $ResponseScope -BarePathBoundaryHandoffSeverity $BarePathBoundaryHandoffSeverity
        Write-ValidatorSummaryAndExit -ProjectRoot $resolvedProjectPath -ExitCode $responseValidationExitCode -HardWarnings $(if ($responseValidationExitCode -eq 0) { 0 } else { 1 })
    }
    $iterationConfig = if ($targets.Count -gt 0) { Get-IterationConfigForValidation -IterationDirectory $targets[0] } else { @{ closeout_packet_required_since_iteration = '' } }
    $reviewerCloseoutEnforcement = Get-ReviewerCloseoutEnforcementMap -Targets $targets -ExplicitTargetsProvided $explicitIterationPathsProvided -RequiredSinceIteration $iterationConfig.closeout_packet_required_since_iteration
    # Proposal 086 Pillar 1: precompute validator code hash for memoization cache.
    $validatorCodeHash = Get-ValidatorCodeHash -ProjectRoot $resolvedProjectPath
    $cacheEnabled = -not [string]::IsNullOrWhiteSpace($validatorCodeHash)
    $iterationTotal = $targets.Count
    $iterationStart = Get-Date
    $script:cacheHitCount = 0

    # Proposal 084: parallel iteration validation.
    # 1) Pre-pass (serial, fast): identify cache hits and cache misses.
    # 2) Parallel pass: subprocesses validate misses; each writes to the
    #    file-locked cache (FR-002). Skipped if -NoParallel, PS < 7, or only
    #    one miss (overhead not worth it).
    # 3) Post-pass: re-read cache for all targets; render in sorted order.
    $parallelAvailable = (-not $NoParallel) -and ($PSVersionTable.PSVersion.Major -ge 7) -and $cacheEnabled
    $cacheHitResults = @{}
    $missTargets = New-Object System.Collections.Generic.List[string]
    $cacheKeysByTarget = @{}

    $preIndex = 0
    foreach ($targetPath in $targets) {
        $preIndex++
        $relativeTarget = try { [System.IO.Path]::GetRelativePath($resolvedProjectPath, $targetPath) } catch { $targetPath }
        $cacheKey = $null
        if ($cacheEnabled) {
            $cacheKey = Get-ValidatorCacheKey -IterationPath $targetPath -ValidatorCodeHash $validatorCodeHash
            $cacheKeysByTarget[$targetPath] = $cacheKey
        }
        if (-not $NoCacheRead -and $cacheEnabled -and -not [string]::IsNullOrWhiteSpace($cacheKey)) {
            $cachedEntry = Get-ValidatorCacheEntry -ProjectRoot $resolvedProjectPath -CacheKey $cacheKey
            if ($null -ne $cachedEntry) {
                $script:cacheHitCount++
                $cachedErrors = New-Object System.Collections.Generic.List[string]
                foreach ($e in @($cachedEntry['errors'])) {
                    if (-not [string]::IsNullOrWhiteSpace([string]$e)) {
                        $null = $cachedErrors.Add([string]$e)
                    }
                }
                $cacheHitResults[$targetPath] = [pscustomobject]@{
                    Path   = $targetPath
                    Errors = $cachedErrors
                }
                if ($env:SPECREW_VALIDATOR_VERBOSE -eq '1') {
                    Write-Host ("[validator] ({0}/{1}) {2} -> CACHE HIT" -f $preIndex, $iterationTotal, $relativeTarget)
                }
                continue
            }
        }
        $null = $missTargets.Add($targetPath)
    }

    $useParallel = $parallelAvailable -and ($missTargets.Count -gt 1)
    $missResults = @{}

    if ($useParallel) {
        $validatorScriptPath = $PSCommandPath
        $effectiveThrottle = [Math]::Max(1, $ThrottleLimit)
        Write-Host ("[validator-parallelism] {0} targets, {1} cache hits served from pre-pass, {2} misses validated in parallel (throttle={3})" -f $iterationTotal, $script:cacheHitCount, $missTargets.Count, $effectiveThrottle)

        # Propagate -NoCacheRead through to subprocesses so parallel mode preserves
        # the same cache-bypass semantics as the serial path (per Copilot review PR #627).
        $propagatedNoCacheRead = $NoCacheRead.IsPresent
        $parallelOutputs = $missTargets | ForEach-Object -Parallel {
            $iter = $_
            $script = $using:validatorScriptPath
            $proj = $using:resolvedProjectPath
            $passNoCacheRead = $using:propagatedNoCacheRead
            try {
                $argList = @('-NoProfile', '-NoLogo', '-File', $script, '-ProjectPath', $proj, '-IterationPath', $iter, '-NoParallel')
                if ($passNoCacheRead) { $argList += '-NoCacheRead' }
                $out = & pwsh @argList 2>&1 | Out-String
                [pscustomobject]@{
                    Path     = $iter
                    ExitCode = $LASTEXITCODE
                    Output   = $out
                }
            }
            catch {
                [pscustomobject]@{
                    Path     = $iter
                    ExitCode = -1
                    Output   = "[validator-parallel-launch-error] $($_.Exception.Message)"
                }
            }
        } -ThrottleLimit $effectiveThrottle

        # After parallel pass, re-read cache for each miss target. Subprocesses
        # populate the cache (file-locked) so the parent reads results uniformly.
        foreach ($po in $parallelOutputs) {
            $missCacheKey = $cacheKeysByTarget[$po.Path]
            $cacheEntry = $null
            if (-not [string]::IsNullOrWhiteSpace($missCacheKey)) {
                $cacheEntry = Get-ValidatorCacheEntry -ProjectRoot $resolvedProjectPath -CacheKey $missCacheKey
            }
            if ($null -ne $cacheEntry) {
                $errs = New-Object System.Collections.Generic.List[string]
                foreach ($e in @($cacheEntry['errors'])) {
                    if (-not [string]::IsNullOrWhiteSpace([string]$e)) { $null = $errs.Add([string]$e) }
                }
                $missResults[$po.Path] = [pscustomobject]@{ Path = $po.Path; Errors = $errs }
            }
            else {
                $errs = New-Object System.Collections.Generic.List[string]
                Add-RepoStructuredValidationFailure -Errors $errs -ProjectRoot $resolvedProjectPath -TargetPath $po.Path -LineNumber $null -Category 'parallel-subprocess-error' -Message ("Parallel subprocess exited with code {0} and did not populate cache. Output: {1}" -f $po.ExitCode, $po.Output) -RemediationHint 'Re-run validate-governance.ps1 with -NoParallel for direct diagnostic output.'
                $missResults[$po.Path] = [pscustomobject]@{ Path = $po.Path; Errors = $errs }
            }
        }
    }
    else {
        # Serial path: original behavior (PS < 7, -NoParallel, single miss, or cache disabled).
        $serialIndex = $script:cacheHitCount
        foreach ($targetPath in $missTargets) {
            $serialIndex++
            $stepStart = Get-Date
            $relativeTarget = try { [System.IO.Path]::GetRelativePath($resolvedProjectPath, $targetPath) } catch { $targetPath }
            if ($env:SPECREW_VALIDATOR_VERBOSE -eq '1') {
                Write-Host ("[validator] ({0}/{1}) validating {2}" -f $serialIndex, $iterationTotal, $relativeTarget)
            }
            $cacheKey = $cacheKeysByTarget[$targetPath]
            try {
                $result = Test-IterationGovernance -IterationDirectory $targetPath -ProjectRoot $resolvedProjectPath -TeamRoles $teamRoles -EnforceReviewerCloseout $reviewerCloseoutEnforcement.ContainsKey($targetPath)
                if ($env:SPECREW_VALIDATOR_VERBOSE -eq '1') {
                    $stepElapsed = [Math]::Round(((Get-Date) - $stepStart).TotalSeconds, 1)
                    Write-Host ("[validator] ({0}/{1}) {2} -> {3}s" -f $serialIndex, $iterationTotal, $relativeTarget, $stepElapsed)
                }
                if ($cacheEnabled -and -not [string]::IsNullOrWhiteSpace($cacheKey)) {
                    $errorsArray = @($result.Errors | ForEach-Object { [string]$_ })
                    Set-ValidatorCacheEntry -ProjectRoot $resolvedProjectPath -CacheKey $cacheKey -Errors $errorsArray -ValidatorCodeHash $validatorCodeHash
                }
                $missResults[$targetPath] = $result
            }
            catch {
                $iterationErrors = New-Object System.Collections.Generic.List[string]
                Add-RepoStructuredValidationFailure -Errors $iterationErrors -ProjectRoot $resolvedProjectPath -TargetPath $targetPath -LineNumber $null -Category 'unexpected-validator-error' -Message $_.Exception.Message -RemediationHint 'Repair the malformed governance artifact or validator input for this iteration and rerun validate-governance.ps1.'
                $missResults[$targetPath] = [pscustomobject]@{ Path = $targetPath; Errors = $iterationErrors }
            }
        }
    }

    # Merge results in target order (deterministic; AC2).
    $results = @($targets | ForEach-Object {
        if ($cacheHitResults.ContainsKey($_)) { $cacheHitResults[$_] } else { $missResults[$_] }
    })

    if ($env:SPECREW_VALIDATOR_VERBOSE -eq '1' -and $script:cacheHitCount -gt 0) {
        Write-Host ("[validator-cache] {0} of {1} iterations served from memoization cache" -f $script:cacheHitCount, $iterationTotal)
    }
    if ($env:SPECREW_VALIDATOR_VERBOSE -eq '1') {
        $totalElapsed = [Math]::Round(((Get-Date) - $iterationStart).TotalSeconds, 1)
        Write-Host ("[validator] iteration loop complete: {0} iterations in {1}s" -f $iterationTotal, $totalElapsed)
    }
    $resultMap = @{}
    foreach ($result in $results) {
        $resultMap[$result.Path] = $result
    }
    Add-ApprovalReuseValidationErrors -Targets $targets -ProjectRoot $resolvedProjectPath -ResultMap $resultMap
    Add-InteractionModelValidationErrors -Targets $targets -ProjectRoot $resolvedProjectPath -ResultMap $resultMap
    $readerToleranceErrors = New-Object System.Collections.Generic.List[string]
    Test-ReaderTolerance -ProjectRoot $resolvedProjectPath -Errors $readerToleranceErrors
    if ($readerToleranceErrors.Count -gt 0) {
        $results += [pscustomobject]@{
            Path   = $resolvedProjectPath
            Errors = $readerToleranceErrors
        }
    }
    $hasFailures = $false
    $hardFailureCount = 0

    foreach ($result in $results) {
        $hardFailureCount += $result.Errors.Count
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

    # Proposal 089: PR review integration soft-warning. NOT counted toward exit
    # code; informational only. Fires when host has automated review AND any
    # target iteration past pr-open boundary is missing the resolution artifact.
    # Wrapped in try/catch to keep validator robust if helpers misbehave.
    # Per Copilot review PR #728: emit BEFORE the failure exit so the warning
    # surfaces on both passing and failing runs (it's independent of pass/fail).
    try {
        $prHostInfo = Test-HostProvidesAutomatedPrReview -ProjectRoot $resolvedProjectPath
        if ($null -ne $prHostInfo -and $prHostInfo.Active) {
            foreach ($iter in $targets) {
                $statePath = Join-Path -Path $iter -ChildPath 'state.md'
                if (-not (Test-Path -LiteralPath $statePath -PathType Leaf)) { continue }
                $stateContent = Get-Content -LiteralPath $statePath -Raw -Encoding UTF8
                # Heuristic: iteration mentions PR / pr-open / pr-merge / Copilot review
                if ($stateContent -notmatch '\b(pr-open|pr-merge|PR open|Copilot review|Copilot PR review|pr-review-resolution)\b') { continue }
                $artifactPath = Get-SpecrewPrReviewResolutionPath -IterationPath $iter
                if (-not (Test-Path -LiteralPath $artifactPath -PathType Leaf)) {
                    $relIter = try { [System.IO.Path]::GetRelativePath($resolvedProjectPath, $iter) } catch { $iter }
                    Write-Host ("[pr-review-soft-warning] Iteration '{0}' mentions PR/Copilot but is missing pr-review-resolution.md. Host '{1}' provides automated review ({2}). Author the artifact to record findings + outcome/root-cause fixes before merging." -f $relIter, $prHostInfo.Host, $prHostInfo.Reviewer)
                }
            }
        }
    }
    catch {
        # Soft warning failure must not affect validation outcome
    }

    if ($hasFailures) {
        Write-ValidatorSummaryAndExit -ProjectRoot $resolvedProjectPath -ExitCode 1 -HardWarnings $hardFailureCount
    }

    Write-ValidatorSummaryAndExit -ProjectRoot $resolvedProjectPath -ExitCode 0 -HardWarnings 0
}
catch {
    Write-Host 'FAIL validate-governance' -ForegroundColor Red
    Write-Host ('  - {0}' -f (New-StructuredValidationFailureText -FilePath '(none)' -LineNumber $null -Category 'unexpected-validator-error' -Message $_.Exception.Message -RemediationHint 'Repair the validator inputs or configuration and rerun validate-governance.ps1.')) -ForegroundColor Red
    $summaryProjectRoot = $null
    try {
        $summaryProjectRoot = (Resolve-Path -Path (Resolve-ProjectPath -Path $ProjectPath)).Path
    }
    catch {
    }
    Write-ValidatorSummaryAndExit -ProjectRoot $summaryProjectRoot -ExitCode 1 -HardWarnings 1
}
