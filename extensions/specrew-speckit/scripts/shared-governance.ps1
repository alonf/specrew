Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

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

function Test-HardeningConcernBlocksImplementation {
    param(
        [Parameter(Mandatory = $true)]
        [object]$Concern,

        [string]$ProjectRoot
    )

    if (-not (ConvertTo-BooleanMarkdownValue -Value ([string]$Concern.Blocking))) {
        return $false
    }

    $status = (Normalize-MarkdownCell ([string]$Concern.Status)).ToLowerInvariant()
    switch ($status) {
        'addressed' { return $false }
        'not-applicable' { return $false }
        'deferred-with-approval' {
            $approvalRef = Normalize-MarkdownCell ([string]$Concern.Approval)
            if (Test-IsNullish $approvalRef) {
                return $true
            }

            if ([string]::IsNullOrWhiteSpace($ProjectRoot)) {
                return $false
            }

            return -not (Test-ApprovalReferenceHasHumanApproval -ProjectRoot $ProjectRoot -ApprovalRef $approvalRef -AllowedTypes @('decision', 'defer'))
        }
        default { return $true }
    }
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
                    Concern   = Normalize-MarkdownCell ([string]$_.Concern)
                    Category  = Normalize-MarkdownCell ([string]$_.Category)
                    Status    = Normalize-MarkdownCell ([string]$_.Status)
                    Blocking  = Normalize-MarkdownCell ([string]$_.Blocking)
                    Rationale = Normalize-MarkdownCell ([string]$_.Rationale)
                    Approval  = Normalize-MarkdownCell ([string]$_.Approval)
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
