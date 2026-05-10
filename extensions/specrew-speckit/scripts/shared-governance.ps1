Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

function Resolve-ProjectPath {
    # Resolve a project path argument against PowerShell's current location rather than the
    # .NET process CurrentDirectory, which on Windows often stays at the shell startup dir
    # (e.g. $HOME) even after Set-Location/cd. Without this, [System.IO.Path]::GetFullPath('.')
    # returns the wrong absolute path and entry-point scripts falsely report "Missing config.yml".
    param(
        [Parameter(Mandatory = $true)]
        [string]$Path
    )

    if ([System.IO.Path]::IsPathRooted($Path)) {
        return [System.IO.Path]::GetFullPath($Path)
    }

    $cwd = (Get-Location).Path
    return [System.IO.Path]::GetFullPath((Join-Path -Path $cwd -ChildPath $Path))
}

function Invoke-WithFileLock {
    param(
        [Parameter(Mandatory = $true)]
        [string]$Path,

        [Parameter(Mandatory = $true)]
        [scriptblock]$ScriptBlock,

        [int]$RetryCount = 50,
        [int]$RetryDelayMilliseconds = 100
    )

    $directory = Split-Path -Parent $Path
    if (-not [string]::IsNullOrWhiteSpace($directory) -and -not (Test-Path -LiteralPath $directory -PathType Container)) {
        $null = New-Item -ItemType Directory -Path $directory -Force
    }

    $lockPath = "$Path.lock"
    $lockStream = $null
    for ($attempt = 0; $attempt -lt $RetryCount; $attempt++) {
        try {
            $lockStream = [System.IO.File]::Open($lockPath, [System.IO.FileMode]::OpenOrCreate, [System.IO.FileAccess]::ReadWrite, [System.IO.FileShare]::None)
            break
        }
        catch [System.IO.IOException] {
            if ($attempt -ge ($RetryCount - 1)) {
                throw "Could not acquire file lock for '$Path'."
            }

            Start-Sleep -Milliseconds $RetryDelayMilliseconds
        }
    }

    try {
        & $ScriptBlock
    }
    finally {
        if ($null -ne $lockStream) {
            $lockStream.Dispose()
        }

        if (Test-Path -LiteralPath $lockPath -PathType Leaf) {
            Remove-Item -LiteralPath $lockPath -Force -ErrorAction SilentlyContinue
        }
    }
}

function Write-Utf8FileAtomic {
    param(
        [Parameter(Mandatory = $true)]
        [string]$Path,

        [Parameter(Mandatory = $true)]
        [AllowEmptyString()]
        [string]$Content
    )

    $directory = Split-Path -Parent $Path
    if (-not [string]::IsNullOrWhiteSpace($directory) -and -not (Test-Path -LiteralPath $directory -PathType Container)) {
        $null = New-Item -ItemType Directory -Path $directory -Force
    }

    $tempPath = '{0}.{1}.tmp' -f $Path, ([guid]::NewGuid().ToString('N'))
    try {
        [System.IO.File]::WriteAllText($tempPath, $Content, [System.Text.UTF8Encoding]::new($false))
        Move-Item -LiteralPath $tempPath -Destination $Path -Force
    }
    finally {
        if (Test-Path -LiteralPath $tempPath -PathType Leaf) {
            Remove-Item -LiteralPath $tempPath -Force -ErrorAction SilentlyContinue
        }
    }
}

function Update-LockedFileContent {
    param(
        [Parameter(Mandatory = $true)]
        [string]$Path,

        [Parameter(Mandatory = $true)]
        [scriptblock]$Transform
    )

    Invoke-WithFileLock -Path $Path -ScriptBlock {
        $currentContent = if (Test-Path -LiteralPath $Path -PathType Leaf) {
            Get-Content -LiteralPath $Path -Raw -Encoding UTF8
        }
        else {
            ''
        }

        $updatedContent = & $Transform $currentContent
        if ($null -eq $updatedContent) {
            throw "Transform for '$Path' returned null."
        }

        Write-Utf8FileAtomic -Path $Path -Content $updatedContent
        return $updatedContent
    }
}

function Get-DecisionsLedgerPath {
    param(
        [Parameter(Mandatory = $true)]
        [string]$ProjectRoot
    )

    return Join-Path $ProjectRoot '.squad\decisions.md'
}

function Add-DecisionsLedgerEntry {
    param(
        [Parameter(Mandatory = $true)]
        [string]$ProjectRoot,

        [Parameter(Mandatory = $true)]
        [string]$Title,

        [AllowEmptyCollection()]
        [AllowEmptyString()]
        [Parameter(Mandatory = $true)]
        [string[]]$Lines
    )

    $ledgerPath = Get-DecisionsLedgerPath -ProjectRoot $ProjectRoot
    $timestamp = (Get-Date).ToUniversalTime().ToString('yyyy-MM-ddTHH:mm:ssZ')
    $entryBody = @(
        "## $timestamp — $Title"
        ''
    ) + @($Lines | Where-Object { $null -ne $_ }) + @('')
    $entryText = ($entryBody -join [Environment]::NewLine).TrimEnd() + [Environment]::NewLine

    Invoke-WithFileLock -Path $ledgerPath -ScriptBlock {
        $existingContent = if (Test-Path -LiteralPath $ledgerPath -PathType Leaf) {
            Get-Content -LiteralPath $ledgerPath -Raw -Encoding UTF8
        }
        else {
            "# Decisions Ledger{0}{0}" -f [Environment]::NewLine
        }

        $updatedContent = $existingContent.TrimEnd()
        if (-not [string]::IsNullOrWhiteSpace($updatedContent)) {
            $updatedContent += [Environment]::NewLine + [Environment]::NewLine
        }

        $updatedContent += $entryText
        Write-Utf8FileAtomic -Path $ledgerPath -Content $updatedContent
    } | Out-Null

    return $ledgerPath
}

function Get-DecisionLedgerOptionalValue {
    param([AllowNull()][string]$Value)

    if ([string]::IsNullOrWhiteSpace($Value)) {
        return '(none)'
    }

    return $Value.Trim()
}

function New-DecisionsLedgerEntryId {
    param(
        [Parameter(Mandatory = $true)]
        [string]$Type
    )

    $prefix = ($Type.ToLowerInvariant() -replace '[^a-z0-9]+', '-').Trim('-')
    return ('{0}-{1}' -f $prefix, ([guid]::NewGuid().ToString('N').Substring(0, 12)))
}

function Add-StructuredDecisionsLedgerEntry {
    param(
        [Parameter(Mandatory = $true)]
        [string]$ProjectRoot,

        [Parameter(Mandatory = $true)]
        [string]$Title,

        [Parameter(Mandatory = $true)]
        [ValidateSet('decision', 'defer', 'escalation', 'routing-evidence', 'clarify-skip', 'review-gap')]
        [string]$Type,

        [string]$DecisionId,
        [string]$AffectedRequirement,
        [string]$AffectedIteration,
        [string]$ApprovingHuman,
        [string]$NextAction = 'none',
        [string]$Rationale,
        [string[]]$DetailLines
    )

    $recordedAt = (Get-Date).ToUniversalTime().ToString('yyyy-MM-ddTHH:mm:ssZ')
    $effectiveDecisionId = if ([string]::IsNullOrWhiteSpace($DecisionId)) {
        New-DecisionsLedgerEntryId -Type $Type
    }
    else {
        $DecisionId.Trim()
    }

    $lines = @(
        "- **Decision ID**: $effectiveDecisionId"
        "- **Type**: $Type"
        "- **Affected Requirement**: $(Get-DecisionLedgerOptionalValue -Value $AffectedRequirement)"
        "- **Affected Iteration**: $(Get-DecisionLedgerOptionalValue -Value $AffectedIteration)"
        "- **Approving Human**: $(Get-DecisionLedgerOptionalValue -Value $ApprovingHuman)"
        "- **Recorded At**: $recordedAt"
        "- **Next Action**: $(Get-DecisionLedgerOptionalValue -Value $NextAction)"
        "- **Rationale**: $(Get-DecisionLedgerOptionalValue -Value $Rationale)"
    )

    if ($null -ne $DetailLines -and $DetailLines.Count -gt 0) {
        $lines += @('') + @($DetailLines | Where-Object { -not [string]::IsNullOrWhiteSpace($_) })
    }

    return Add-DecisionsLedgerEntry -ProjectRoot $ProjectRoot -Title $Title -Lines $lines
}

function Get-DecisionsLedgerEntries {
    param(
        [Parameter(Mandatory = $true)]
        [string]$ProjectRoot
    )

    $ledgerPath = Get-DecisionsLedgerPath -ProjectRoot $ProjectRoot
    if (-not (Test-Path -LiteralPath $ledgerPath -PathType Leaf)) {
        return @()
    }

    $lines = @(Get-Content -LiteralPath $ledgerPath -Encoding UTF8)
    $entries = New-Object System.Collections.Generic.List[object]
    $entryRegex = '^(?:##|###)\s+(\d{4}-\d{2}-\d{2}(?:T\d{2}:\d{2}:\d{2}Z)?)\s*[—:-]\s*(.+?)\s*$'

    $currentTimestamp = $null
    $currentTitle = $null
    $currentLines = New-Object System.Collections.Generic.List[string]

    foreach ($line in $lines) {
        $entryMatch = [regex]::Match($line, $entryRegex)
        if ($entryMatch.Success) {
            if ($null -ne $currentTimestamp) {
                $entries.Add((New-DecisionsLedgerParsedEntry -Timestamp $currentTimestamp -Title $currentTitle -EntryLines $currentLines)) | Out-Null
            }

            $currentTimestamp = $entryMatch.Groups[1].Value.Trim()
            $currentTitle = $entryMatch.Groups[2].Value.Trim()
            $currentLines = New-Object System.Collections.Generic.List[string]
            continue
        }

        if ($null -ne $currentTimestamp) {
            $currentLines.Add($line) | Out-Null
        }
    }

    if ($null -ne $currentTimestamp) {
        $entries.Add((New-DecisionsLedgerParsedEntry -Timestamp $currentTimestamp -Title $currentTitle -EntryLines $currentLines)) | Out-Null
    }

    return $entries.ToArray()
}

function New-DecisionsLedgerParsedEntry {
    param(
        [string]$Timestamp,
        [string]$Title,
        [System.Collections.Generic.List[string]]$EntryLines
    )

    $rawText = $EntryLines -join "`n"
    return [pscustomobject]@{
        Timestamp           = $Timestamp
        Title               = $Title
        DecisionId          = if (($rawText -match '(?m)^-\s+\*\*Decision ID\*\*:\s*(.+?)\s*$')) { $Matches[1].Trim() } else { $null }
        Type                = if (($rawText -match '(?m)^-\s+\*\*Type\*\*:\s*(.+?)\s*$')) { $Matches[1].Trim() } else { $null }
        AffectedRequirement = if (($rawText -match '(?m)^-\s+\*\*Affected Requirement\*\*:\s*(.+?)\s*$')) { $Matches[1].Trim() } else { $null }
        AffectedIteration   = if (($rawText -match '(?m)^-\s+\*\*Affected Iteration\*\*:\s*(.+?)\s*$')) { $Matches[1].Trim() } else { $null }
        ApprovingHuman      = if (($rawText -match '(?m)^-\s+\*\*Approving Human\*\*:\s*(.+?)\s*$')) { $Matches[1].Trim() } else { $null }
        RecordedAt          = if (($rawText -match '(?m)^-\s+\*\*Recorded At\*\*:\s*(.+?)\s*$')) { $Matches[1].Trim() } else { $Timestamp }
        NextAction          = if (($rawText -match '(?m)^-\s+\*\*Next Action\*\*:\s*(.+?)\s*$')) { $Matches[1].Trim() } else { $null }
        RawLines            = $EntryLines.ToArray()
        RawText             = $rawText
        RoutingStatus       = if (($rawText -match 'status=(honored|fell-back)')) { $Matches[1] } else { $null }
        FallbackReason      = if (($rawText -match 'fallback=([^\r\n]+)')) { $Matches[1].Trim() } else { $null }
    }
}

function Get-MarkdownContent {
    param(
        [Parameter(Mandatory = $true)]
        [string]$Path
    )

    return @(Get-Content -LiteralPath $Path -Encoding UTF8)
}

function Get-MarkdownMetadataValue {
    param(
        [AllowEmptyCollection()]
        [AllowEmptyString()]
        [Parameter(Mandatory = $true)]
        [string[]]$Lines,
        [Parameter(Mandatory = $true)]
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

function Get-MarkdownSectionTable {
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

function Normalize-MarkdownCell {
    param([AllowNull()][string]$Value)

    if ($null -eq $Value) {
        return ''
    }

    return $Value.Trim().Trim('`')
}

function Get-ObjectPropertyString {
    param(
        [Parameter(Mandatory = $true)]
        [object]$InputObject,

        [Parameter(Mandatory = $true)]
        [string[]]$PropertyNames
    )

    foreach ($propertyName in $PropertyNames) {
        $property = $InputObject.PSObject.Properties[$propertyName]
        if ($null -ne $property) {
            return [string]$property.Value
        }
    }

    return $null
}

function Test-IsNullish {
    param([AllowNull()][string]$Value)

    if ([string]::IsNullOrWhiteSpace($Value)) {
        return $true
    }

    return $Value.Trim() -match '^(?:—|-|none|null|n/a|\(none\)|blank|tbd|unknown)$'
}

function Convert-ToDecisionReferenceId {
    param([AllowNull()][string]$ApprovalRef)

    $normalized = Normalize-MarkdownCell $ApprovalRef
    if (Test-IsNullish $normalized) {
        return $null
    }

    if ($normalized -match '(?i)\.squad\\decisions\.md#(?<id>[a-z0-9][a-z0-9-]*)') {
        return $Matches['id'].Trim()
    }

    if ($normalized -match '(?i)#(?<id>[a-z0-9][a-z0-9-]*)$') {
        return $Matches['id'].Trim()
    }

    if ($normalized -match '(?i)\b(?<id>(?:decision|defer|escalation|routing-evidence|clarify-skip|review-gap)-[a-f0-9]{12})\b') {
        return $Matches['id'].Trim()
    }

    return $normalized
}

function Get-ApprovalReferenceRecord {
    param(
        [Parameter(Mandatory = $true)]
        [string]$ProjectRoot,

        [AllowNull()][string]$ApprovalRef,

        [string[]]$AllowedTypes = @()
    )

    $normalizedRef = Normalize-MarkdownCell $ApprovalRef
    if (Test-IsNullish $normalizedRef) {
        return $null
    }

    $decisionId = Convert-ToDecisionReferenceId -ApprovalRef $normalizedRef
    $matches = @(
        Get-DecisionsLedgerEntries -ProjectRoot $ProjectRoot |
            Where-Object {
                ($_.DecisionId -eq $decisionId -or $_.Title -eq $normalizedRef) -and
                ($AllowedTypes.Count -eq 0 -or $_.Type -in $AllowedTypes)
            } |
            Select-Object -First 1
    )

    if ($matches.Count -eq 0) {
        return [pscustomobject]@{
            ApprovalRef      = $normalizedRef
            DecisionId       = $decisionId
            Entry            = $null
            HasHumanApproval = $false
            ApprovingHuman   = $null
            Type             = $null
        }
    }

    $entry = $matches[0]
    return [pscustomobject]@{
        ApprovalRef      = $normalizedRef
        DecisionId       = $entry.DecisionId
        Entry            = $entry
        HasHumanApproval = -not (Test-IsNullish $entry.ApprovingHuman)
        ApprovingHuman   = $entry.ApprovingHuman
        Type             = $entry.Type
    }
}

function Test-ApprovalReferenceHasHumanApproval {
    param(
        [Parameter(Mandatory = $true)]
        [string]$ProjectRoot,

        [AllowNull()][string]$ApprovalRef,

        [string[]]$AllowedTypes = @()
    )

    $record = Get-ApprovalReferenceRecord -ProjectRoot $ProjectRoot -ApprovalRef $ApprovalRef -AllowedTypes $AllowedTypes
    return $null -ne $record -and $record.HasHumanApproval
}

function ConvertTo-BooleanMarkdownValue {
    param([AllowNull()][string]$Value)

    $normalized = Normalize-MarkdownCell $Value
    if ([string]::IsNullOrWhiteSpace($normalized)) {
        return $false
    }

    return $normalized.ToLowerInvariant() -in @('true', 'yes', '1')
}

function Get-HardeningConcernEvidenceProjection {
    param(
        [Parameter(Mandatory = $true)]
        [object]$Concern
    )

    $status = (Normalize-MarkdownCell ([string]$Concern.Status)).ToLowerInvariant()
    $explicitEvidenceBasis = Normalize-MarkdownCell ([string]$Concern.EvidenceBasis)
    $explicitRuntimeEvidenceStatus = Normalize-MarkdownCell ([string]$Concern.RuntimeEvidenceStatus)
    $explicitExpectedControls = Normalize-MarkdownCell ([string]$Concern.ExpectedControls)
    $hasExplicitEvidenceFields = -not (
        (Test-IsNullish $explicitEvidenceBasis) -and
        (Test-IsNullish $explicitRuntimeEvidenceStatus) -and
        (Test-IsNullish $explicitExpectedControls)
    )

    $evidenceBasis = $explicitEvidenceBasis
    $runtimeEvidenceStatus = $explicitRuntimeEvidenceStatus
    $expectedControls = $explicitExpectedControls

    if (-not $hasExplicitEvidenceFields) {
        switch ($status) {
            'addressed' {
                $evidenceBasis = 'planning-time-analysis'
                $runtimeEvidenceStatus = 'pending-post-implementation'
                $expectedControls = Normalize-MarkdownCell ([string]$Concern.Rationale)
            }
            'deferred-with-approval' {
                $evidenceBasis = 'planning-time-analysis'
                $runtimeEvidenceStatus = 'pending-post-implementation'
                $expectedControls = Normalize-MarkdownCell ([string]$Concern.Rationale)
            }
            'not-applicable' {
                $evidenceBasis = 'not-applicable'
                $runtimeEvidenceStatus = 'not-needed'
                $expectedControls = '—'
            }
            default {
                $evidenceBasis = '—'
                $runtimeEvidenceStatus = '—'
                $expectedControls = '—'
            }
        }
    }

    return [pscustomobject]@{
        Status                     = $status
        EvidenceBasis              = $evidenceBasis
        RuntimeEvidenceStatus      = $runtimeEvidenceStatus
        ExpectedControls           = $expectedControls
        HasExplicitEvidenceFields  = $hasExplicitEvidenceFields
    }
}

function Get-HardeningConcernEvaluation {
    param(
        [Parameter(Mandatory = $true)]
        [object]$Concern,

        [string]$ProjectRoot
    )

    $issues = New-Object System.Collections.Generic.List[string]
    $status = (Normalize-MarkdownCell ([string]$Concern.Status)).ToLowerInvariant()
    $rationale = Normalize-MarkdownCell ([string]$Concern.Rationale)
    $approvalRef = Normalize-MarkdownCell ([string]$Concern.Approval)
    $evidence = Get-HardeningConcernEvidenceProjection -Concern $Concern
    $evidenceBasis = (Normalize-MarkdownCell ([string]$evidence.EvidenceBasis)).ToLowerInvariant()
    $runtimeEvidenceStatus = (Normalize-MarkdownCell ([string]$evidence.RuntimeEvidenceStatus)).ToLowerInvariant()
    $expectedControls = Normalize-MarkdownCell ([string]$evidence.ExpectedControls)
    $approvalRecord = if ([string]::IsNullOrWhiteSpace($ProjectRoot)) {
        $null
    }
    else {
        Get-ApprovalReferenceRecord -ProjectRoot $ProjectRoot -ApprovalRef $approvalRef -AllowedTypes @('decision', 'defer')
    }

    if (Test-IsNullish $rationale) {
        $issues.Add('must record rationale for the current hardening disposition') | Out-Null
    }

    switch ($status) {
        'addressed' {
            if ($evidence.HasExplicitEvidenceFields) {
                if ($evidenceBasis -notin @('planning-time-analysis', 'runtime-evidence')) {
                    $issues.Add("must use Evidence Basis 'planning-time-analysis' before closure or 'runtime-evidence' once runtime proof is recorded") | Out-Null
                }

                if (Test-IsNullish $expectedControls) {
                    $issues.Add('must record Expected Controls before implementation can proceed') | Out-Null
                }

                switch ($evidenceBasis) {
                    'planning-time-analysis' {
                        if ($runtimeEvidenceStatus -notin @('pending-post-implementation', 'not-needed')) {
                            $issues.Add("must keep Runtime Evidence Status 'pending-post-implementation' or 'not-needed' when Evidence Basis is planning-time-analysis") | Out-Null
                        }
                    }
                    'runtime-evidence' {
                        if ($runtimeEvidenceStatus -ne 'recorded') {
                            $issues.Add("must keep Runtime Evidence Status 'recorded' when Evidence Basis is runtime-evidence") | Out-Null
                        }
                    }
                }
            }
        }
        'not-applicable' {
            if ($evidence.HasExplicitEvidenceFields) {
                if ($evidenceBasis -ne 'not-applicable') {
                    $issues.Add("must use Evidence Basis 'not-applicable' when Status is not-applicable") | Out-Null
                }

                if ($runtimeEvidenceStatus -ne 'not-needed') {
                    $issues.Add("must use Runtime Evidence Status 'not-needed' when Status is not-applicable") | Out-Null
                }
            }
        }
        'deferred-with-approval' {
            if ($evidence.HasExplicitEvidenceFields) {
                if ($evidenceBasis -ne 'planning-time-analysis') {
                    $issues.Add("must keep Evidence Basis 'planning-time-analysis' when Status is deferred-with-approval") | Out-Null
                }

                if ($runtimeEvidenceStatus -ne 'pending-post-implementation') {
                    $issues.Add("must keep Runtime Evidence Status 'pending-post-implementation' when Status is deferred-with-approval") | Out-Null
                }

                if (Test-IsNullish $expectedControls) {
                    $issues.Add('must keep Expected Controls visible when Status is deferred-with-approval') | Out-Null
                }
            }

            if (Test-IsNullish $approvalRef) {
                $issues.Add('must record a human-approved Approval reference when Status is deferred-with-approval') | Out-Null
            }
            elseif (-not [string]::IsNullOrWhiteSpace($ProjectRoot) -and ($null -eq $approvalRecord -or -not $approvalRecord.HasHumanApproval)) {
                $issues.Add(("approval reference '{0}' is missing explicit human approval evidence" -f $approvalRef)) | Out-Null
            }
        }
        default {
            $issues.Add('must resolve the concern before implementation can proceed') | Out-Null
            if ($evidenceBasis -ne 'planning-time-analysis') {
                $issues.Add("must record planning-time analysis before implementation can proceed") | Out-Null
            }
            if (Test-IsNullish $expectedControls) {
                $issues.Add('must record Expected Controls before implementation can proceed') | Out-Null
            }
        }
    }

    $blocksClosure = $false
    switch ($status) {
        'addressed' {
            $blocksClosure = $runtimeEvidenceStatus -eq 'pending-post-implementation'
        }
        'deferred-with-approval' {
            $blocksClosure = $true
        }
        'not-applicable' {
            $blocksClosure = $false
        }
        default {
            $blocksClosure = $true
        }
    }

    return [pscustomobject]@{
        Status                    = $status
        EvidenceBasis             = $evidence.EvidenceBasis
        RuntimeEvidenceStatus     = $evidence.RuntimeEvidenceStatus
        ExpectedControls          = $evidence.ExpectedControls
        HasExplicitEvidenceFields = $evidence.HasExplicitEvidenceFields
        ApprovalRecord            = $approvalRecord
        Issues                    = $issues.ToArray()
        BlocksImplementation      = $issues.Count -gt 0
        BlocksClosure             = $blocksClosure
        HasHumanApproval          = -not [string]::IsNullOrWhiteSpace($approvalRef) -and ($null -ne $approvalRecord -and $approvalRecord.HasHumanApproval)
    }
}

# ============================================================================
# Reviewer-Regression Governance Functions (Spec 008 Extension)
# ============================================================================

function Get-ReviewerRegressionLedgerPath {
    <#
    .SYNOPSIS
    Returns the path to the reviewer-regression ledger.
    
    .PARAMETER ProjectRoot
    The root directory of the project.
    #>
    param(
        [Parameter(Mandatory = $true)]
        [string]$ProjectRoot
    )

    return Join-Path $ProjectRoot '.specrew\reviewer-regression-log.md'
}

function Get-ReviewerRegressionLedgerEntries {
    <#
    .SYNOPSIS
    Parses the reviewer-regression ledger and returns all event entries.
    
    .PARAMETER ProjectRoot
    The root directory of the project.
    #>
    param(
        [Parameter(Mandatory = $true)]
        [string]$ProjectRoot
    )

    $ledgerPath = Get-ReviewerRegressionLedgerPath -ProjectRoot $ProjectRoot
    if (-not (Test-Path -LiteralPath $ledgerPath -PathType Leaf)) {
        return @()
    }

    $lines = @(Get-Content -LiteralPath $ledgerPath -Encoding UTF8)
    $entries = New-Object System.Collections.Generic.List[object]
    $eventRegex = '^#{3}\s+(RRE-\d{3,})\s*$'

    $currentEventId = $null
    $currentLines = New-Object System.Collections.Generic.List[string]

    foreach ($line in $lines) {
        $eventMatch = [regex]::Match($line, $eventRegex)
        if ($eventMatch.Success) {
            if ($null -ne $currentEventId) {
                $entries.Add((New-ReviewerRegressionEventEntry -EventId $currentEventId -EntryLines $currentLines)) | Out-Null
            }

            $currentEventId = $eventMatch.Groups[1].Value.Trim()
            $currentLines = New-Object System.Collections.Generic.List[string]
            continue
        }

        if ($null -ne $currentEventId) {
            $currentLines.Add($line) | Out-Null
        }
    }

    if ($null -ne $currentEventId) {
        $entries.Add((New-ReviewerRegressionEventEntry -EventId $currentEventId -EntryLines $currentLines)) | Out-Null
    }

    return $entries.ToArray()
}

function New-ReviewerRegressionEventEntry {
    <#
    .SYNOPSIS
    Creates a parsed reviewer-regression event object from ledger lines.
    
    .PARAMETER EventId
    The event identifier (e.g., RRE-001).
    
    .PARAMETER EntryLines
    The raw lines from the ledger entry.
    #>
    param(
        [string]$EventId,
        [System.Collections.Generic.List[string]]$EntryLines
    )

    $rawText = $EntryLines -join "`n"
    
    return [pscustomobject]@{
        EventId                = $EventId
        Feature                = Get-LedgerFieldValue -RawText $rawText -Label 'Feature'
        Iteration              = Get-LedgerFieldValue -RawText $rawText -Label 'Iteration'
        Slice                  = Get-LedgerFieldValue -RawText $rawText -Label 'Slice'
        PriorReviewerVerdict   = Get-LedgerFieldValue -RawText $rawText -Label 'Prior Reviewer Verdict'
        PriorReviewerClass     = Get-LedgerFieldValue -RawText $rawText -Label 'Prior Reviewer Class'
        PriorReviewerOwner     = Get-LedgerFieldValue -RawText $rawText -Label 'Prior Reviewer Owner'
        DefectDescription      = Get-LedgerFieldValue -RawText $rawText -Label 'Defect Description'
        DefectSourceLocation   = Get-LedgerFieldValue -RawText $rawText -Label 'Defect Source Location'
        EventStatus            = Get-LedgerFieldValue -RawText $rawText -Label 'Event Status'
        Severity               = Get-LedgerFieldValue -RawText $rawText -Label 'Severity'
        EscalationAction       = Get-LedgerFieldValue -RawText $rawText -Label 'Escalation Action'
        EscalatedToClass       = Get-LedgerFieldValue -RawText $rawText -Label 'Escalated To Class'
        SameClassFallbackOwner = Get-LedgerFieldValue -RawText $rawText -Label 'Same-Class Fallback Owner'
        CarryForwardIteration  = Get-LedgerFieldValue -RawText $rawText -Label 'Carry Forward Iteration'
        CandidateTrapStatus    = Get-LedgerFieldValue -RawText $rawText -Label 'Candidate Trap Status'
        WithdrawalReference    = Get-LedgerFieldValue -RawText $rawText -Label 'Withdrawal Reference'
        DeEscalationOutcome    = Get-LedgerFieldValue -RawText $rawText -Label 'De-Escalation Outcome'
        RecordedAt             = Get-LedgerFieldValue -RawText $rawText -Label 'Recorded At'
        RawLines               = $EntryLines.ToArray()
        RawText                = $rawText
    }
}

function Get-LedgerFieldValue {
    <#
    .SYNOPSIS
    Extracts a field value from ledger entry text.
    
    .PARAMETER RawText
    The raw text content of the ledger entry.
    
    .PARAMETER Label
    The field label to extract.
    #>
    param(
        [string]$RawText,
        [string]$Label
    )

    $pattern = '(?m)^-\s+\*\*' + [regex]::Escape($Label) + '\*\*:\s*`?(.+?)`?\s*$'
    if ($RawText -match $pattern) {
        $value = $Matches[1].Trim()
        if ($value -eq '(none)' -or $value -eq '(pending)' -or [string]::IsNullOrWhiteSpace($value)) {
            return $null
        }
        return $value
    }

    return $null
}

function Get-ActiveReviewerRegressionChain {
    <#
    .SYNOPSIS
    Returns the active reviewer-regression chain for a specific feature.
    
    .PARAMETER ProjectRoot
    The root directory of the project.
    
    .PARAMETER Feature
    The feature path to filter by.
    #>
    param(
        [Parameter(Mandatory = $true)]
        [string]$ProjectRoot,
        
        [Parameter(Mandatory = $true)]
        [string]$Feature
    )

    $entries = Get-ReviewerRegressionLedgerEntries -ProjectRoot $ProjectRoot
    $activeEntries = @($entries | Where-Object { 
        $_.Feature -eq $Feature -and 
        $_.EventStatus -eq 'active' 
    })

    if ($activeEntries.Count -eq 0) {
        return [pscustomobject]@{
            Status                     = 'inactive'
            Feature                    = $Feature
            ActiveEventIds             = @()
            StrongestUnresolvedAction  = $null
            CurrentReviewerClass       = $null
            PriorReviewerClass         = $null
            CurrentReviewerOwner       = $null
            CleanPassesRequired        = 1
            CleanPassesObserved        = 0
            CarryForwardFromIteration  = $null
            Notes                      = $null
        }
    }

    # Find the strongest unresolved escalation action
    $strongestAction = $null
    $currentClass = $null
    $priorClass = $null
    $currentOwner = $null
    $carryForward = $null

    foreach ($entry in $activeEntries) {
        if ($entry.EscalationAction -eq 'human-direction-hold') {
            $strongestAction = 'human-direction-hold'
            $currentClass = $entry.EscalatedToClass
            $priorClass = $entry.PriorReviewerClass
            break
        }
        elseif ($entry.EscalationAction -eq 'stronger-class') {
            $strongestAction = 'stronger-class'
            $currentClass = $entry.EscalatedToClass
            $priorClass = $entry.PriorReviewerClass
        }
        elseif ($strongestAction -ne 'stronger-class' -and $entry.EscalationAction -eq 'same-class-independent-owner') {
            $strongestAction = 'same-class-independent-owner'
            $currentClass = $entry.PriorReviewerClass
            $priorClass = $entry.PriorReviewerClass
            $currentOwner = $entry.SameClassFallbackOwner
        }

        if ($null -ne $entry.CarryForwardIteration) {
            $carryForward = $entry.CarryForwardIteration
        }
    }

    return [pscustomobject]@{
        Status                     = if ($strongestAction -eq 'human-direction-hold') { 'held' } else { 'active' }
        Feature                    = $Feature
        ActiveEventIds             = @($activeEntries | ForEach-Object { $_.EventId })
        StrongestUnresolvedAction  = $strongestAction
        CurrentReviewerClass       = $currentClass
        PriorReviewerClass         = $priorClass
        CurrentReviewerOwner       = $currentOwner
        CleanPassesRequired        = 1
        CleanPassesObserved        = 0
        CarryForwardFromIteration  = $carryForward
        Notes                      = $null
    }
}

function Add-StructuredDecisionsLedgerEntry {
    <#
    .SYNOPSIS
    Adds a structured decision entry to the decisions ledger with extended type support.
    
    .PARAMETER Type
    The decision type. Spec 008 adds: reviewer-regression-escalation, reviewer-regression-withdrawal, lockout-cap.
    #>
    param(
        [Parameter(Mandatory = $true)]
        [string]$ProjectRoot,

        [Parameter(Mandatory = $true)]
        [string]$Title,

        [Parameter(Mandatory = $true)]
        [ValidateSet('decision', 'defer', 'escalation', 'routing-evidence', 'clarify-skip', 'review-gap', 
                     'reviewer-regression-escalation', 'reviewer-regression-withdrawal', 'lockout-cap')]
        [string]$Type,

        [string]$DecisionId,
        [string]$AffectedRequirement,
        [string]$AffectedIteration,
        [string]$ApprovingHuman,
        [string]$NextAction = 'none',
        [string]$Rationale,
        [string[]]$DetailLines
    )

    $recordedAt = (Get-Date).ToUniversalTime().ToString('yyyy-MM-ddTHH:mm:ssZ')
    $effectiveDecisionId = if ([string]::IsNullOrWhiteSpace($DecisionId)) {
        New-DecisionsLedgerEntryId -Type $Type
    }
    else {
        $DecisionId.Trim()
    }

    $lines = @(
        "- **Decision ID**: $effectiveDecisionId"
        "- **Type**: $Type"
        "- **Affected Requirement**: $(Get-DecisionLedgerOptionalValue -Value $AffectedRequirement)"
        "- **Affected Iteration**: $(Get-DecisionLedgerOptionalValue -Value $AffectedIteration)"
        "- **Approving Human**: $(Get-DecisionLedgerOptionalValue -Value $ApprovingHuman)"
        "- **Recorded At**: $recordedAt"
        "- **Next Action**: $(Get-DecisionLedgerOptionalValue -Value $NextAction)"
        "- **Rationale**: $(Get-DecisionLedgerOptionalValue -Value $Rationale)"
    )

    if ($null -ne $DetailLines -and $DetailLines.Count -gt 0) {
        $lines += @('') + @($DetailLines | Where-Object { -not [string]::IsNullOrWhiteSpace($_) })
    }

    return Add-DecisionsLedgerEntry -ProjectRoot $ProjectRoot -Title $Title -Lines $lines
}

function Test-HardeningConcernBlocksImplementation {
    param(
        [Parameter(Mandatory = $true)]
        [object]$Concern,

        [string]$ProjectRoot
    )

    if (-not (ConvertTo-BooleanMarkdownValue -Value ([string]$Concern.Blocking))) {
        return $false
    }

    $evaluation = Get-HardeningConcernEvaluation -Concern $Concern -ProjectRoot $ProjectRoot
    return [bool]$evaluation.BlocksImplementation
}

function Test-HardeningConcernBlocksClosure {
    param(
        [Parameter(Mandatory = $true)]
        [object]$Concern,

        [string]$ProjectRoot
    )

    if (-not (ConvertTo-BooleanMarkdownValue -Value ([string]$Concern.Blocking))) {
        return $false
    }

    $evaluation = Get-HardeningConcernEvaluation -Concern $Concern -ProjectRoot $ProjectRoot
    return [bool]$evaluation.BlocksClosure
}

function Get-HardeningGateState {
    param(
        [Parameter(Mandatory = $true)]
        [string]$Path,

        [string]$ProjectRoot
    )

    $lines = @(Get-MarkdownContent -Path $Path)
    $metadata = [ordered]@{
        Schema               = Normalize-MarkdownCell (Get-MarkdownMetadataValue -Lines $lines -Label 'Schema')
        GateId               = Normalize-MarkdownCell (Get-MarkdownMetadataValue -Lines $lines -Label 'Gate ID')
        FeatureRef           = Normalize-MarkdownCell (Get-MarkdownMetadataValue -Lines $lines -Label 'Feature Ref')
        IterationRef         = Normalize-MarkdownCell (Get-MarkdownMetadataValue -Lines $lines -Label 'Iteration Ref')
        RequestedReviewClass = Normalize-MarkdownCell (Get-MarkdownMetadataValue -Lines $lines -Label 'Requested Review Class')
        EffectiveReviewClass = Normalize-MarkdownCell (Get-MarkdownMetadataValue -Lines $lines -Label 'Effective Review Class')
        OverallVerdict       = Normalize-MarkdownCell (Get-MarkdownMetadataValue -Lines $lines -Label 'Overall Verdict')
        ApprovalRef          = Normalize-MarkdownCell (Get-MarkdownMetadataValue -Lines $lines -Label 'Approval Ref')
        ReviewedBy           = Normalize-MarkdownCell (Get-MarkdownMetadataValue -Lines $lines -Label 'Reviewed By')
        ReviewedAt           = Normalize-MarkdownCell (Get-MarkdownMetadataValue -Lines $lines -Label 'Reviewed At')
    }

    $concerns = @(
        Get-MarkdownSectionTable -Lines $lines -Heading 'Concern Review' |
            ForEach-Object {
                [pscustomobject]@{
                    Concern               = Normalize-MarkdownCell (Get-ObjectPropertyString -InputObject $_ -PropertyNames @('Concern'))
                    Category              = Normalize-MarkdownCell (Get-ObjectPropertyString -InputObject $_ -PropertyNames @('Category'))
                    Status                = Normalize-MarkdownCell (Get-ObjectPropertyString -InputObject $_ -PropertyNames @('Status'))
                    EvidenceBasis         = Normalize-MarkdownCell (Get-ObjectPropertyString -InputObject $_ -PropertyNames @('Evidence Basis'))
                    RuntimeEvidenceStatus = Normalize-MarkdownCell (Get-ObjectPropertyString -InputObject $_ -PropertyNames @('Runtime Evidence Status'))
                    ExpectedControls      = Normalize-MarkdownCell (Get-ObjectPropertyString -InputObject $_ -PropertyNames @('Expected Controls'))
                    Blocking              = Normalize-MarkdownCell (Get-ObjectPropertyString -InputObject $_ -PropertyNames @('Blocking'))
                    Rationale             = Normalize-MarkdownCell (Get-ObjectPropertyString -InputObject $_ -PropertyNames @('Rationale'))
                    Approval              = Normalize-MarkdownCell (Get-ObjectPropertyString -InputObject $_ -PropertyNames @('Approval'))
                }
            }
    )

    $blockingConcerns = @(
        $concerns |
            Where-Object {
                Test-HardeningConcernBlocksImplementation -Concern $_ -ProjectRoot $ProjectRoot
            }
    )

    return [pscustomobject]@{
        Path                       = $Path
        Metadata                   = [pscustomobject]$metadata
        ConcernRows                = $concerns
        BlockingConcerns           = $blockingConcerns
        BlocksImplementation       = $blockingConcerns.Count -gt 0
        ApprovalRecord             = if ([string]::IsNullOrWhiteSpace($ProjectRoot)) {
            $null
        }
        else {
            Get-ApprovalReferenceRecord -ProjectRoot $ProjectRoot -ApprovalRef $metadata.ApprovalRef -AllowedTypes @('decision', 'defer')
        }
    }
}

function Get-RoutingEvidenceRecords {
    param(
        [Parameter(Mandatory = $true)]
        [string]$ProjectRoot,

        [string]$IterationRelativePath
    )

    $pattern = '(?im)^\s*-\s+\*\*Routing Evidence\*\*:\s*(?<actor>[^|]+?)\s*\|\s*requested=(?<requested>[^|]+?)\s*\|\s*actual=(?<actual>[^|]+?)\s*\|\s*model=(?<model>[^|]+?)\s*\|\s*status=(?<status>[^|\r\n]+?)(?:\s*\|\s*fallback=(?<fallback>[^\r\n]+))?\s*$'
    return @(
        Get-DecisionsLedgerEntries -ProjectRoot $ProjectRoot |
            Where-Object {
                $_.Type -eq 'routing-evidence' -and
                (
                    [string]::IsNullOrWhiteSpace($IterationRelativePath) -or
                    [string]$_.AffectedIteration -eq $IterationRelativePath
                )
            } |
            ForEach-Object {
                $entry = $_
                $match = [regex]::Match($entry.RawText, $pattern)
                [pscustomobject]@{
                    DecisionId     = $entry.DecisionId
                    AffectedIteration = $entry.AffectedIteration
                    Actor          = if ($match.Success) { $match.Groups['actor'].Value.Trim() } else { $null }
                    RequestedClass = if ($match.Success) { $match.Groups['requested'].Value.Trim() } else { $null }
                    EffectiveClass = if ($match.Success) { $match.Groups['actual'].Value.Trim() } else { $null }
                    Model          = if ($match.Success) { $match.Groups['model'].Value.Trim() } else { $null }
                    Status         = if ($match.Success) { $match.Groups['status'].Value.Trim() } else { $entry.RoutingStatus }
                    FallbackReason = if ($match.Success -and $match.Groups['fallback'].Success) { $match.Groups['fallback'].Value.Trim() } else { $entry.FallbackReason }
                    Entry          = $entry
                }
            }
    )
}
