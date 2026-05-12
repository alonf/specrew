[CmdletBinding()]
param(
    [AllowEmptyString()]
    [string]$ResponseText = ''
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

$governancePatterns = @(
    '(?i)before-implement',
    '(?i)hardening-gate',
    '(?i)approval ref',
    '(?i)implementation approval',
    '(?i)traceability',
    '(?i)schema',
    '\bFR-\d+\b',
    '\bTG-[A-Za-z0-9-]+\b',
    '(?i)\bgate\b',
    '(?i)\bvalidator\b'
)

$placeholderUserActionPhrases = @(
    'Nothing yet',
    'No action needed',
    'No action required',
    'Nothing to do',
    'No further action needed'
)

function Get-NormalizedText {
    param([AllowEmptyString()][string]$Text)

    if ([string]::IsNullOrWhiteSpace($Text)) {
        return ''
    }

    $normalized = $Text -replace "`r`n", "`n"
    $normalized = $normalized -replace "[`t ]+", ' '
    $normalized = $normalized -replace " *`n *", "`n"
    return $normalized.Trim()
}

function Get-HandoffSections {
    param([AllowEmptyString()][string]$Text)

    if ([string]::IsNullOrWhiteSpace($Text)) {
        return @('')
    }

    $lines = $Text -split "`n"
    $sections = New-Object System.Collections.Generic.List[string]
    $currentLines = New-Object System.Collections.Generic.List[string]
    $headingPattern = '^(?:#{1,6}\s*)?(?:\*\*)?(What I just did|Why I stopped|What I need from you)(?:\*\*)?\s*$'

    foreach ($line in $lines) {
        if ($line.Trim() -match $headingPattern) {
            if ($currentLines.Count -gt 0) {
                $sections.Add(($currentLines -join "`n").Trim())
                $currentLines.Clear()
            }

            continue
        }

        $currentLines.Add($line)
    }

    if ($currentLines.Count -gt 0) {
        $sections.Add(($currentLines -join "`n").Trim())
    }

    if ($sections.Count -eq 0) {
        return @($Text.Trim())
    }

    return $sections.ToArray()
}

function Get-HandoffSectionMap {
    param([AllowEmptyString()][string]$Text)

    $sectionMap = [ordered]@{}
    if ([string]::IsNullOrWhiteSpace($Text)) {
        return $sectionMap
    }

    $lines = $Text -split "`n"
    $currentHeading = $null
    $currentLines = New-Object System.Collections.Generic.List[string]
    $headingPattern = '^(?:#{1,6}\s*)?(?:\*\*)?(What I just did|Why I stopped|What I need from you)(?:\*\*)?\s*$'

    foreach ($line in $lines) {
        $trimmed = $line.Trim()
        if ($trimmed -match $headingPattern) {
            if ($null -ne $currentHeading) {
                $sectionMap[$currentHeading] = ($currentLines -join "`n").Trim()
                $currentLines.Clear()
            }

            $currentHeading = $Matches[1]
            continue
        }

        if ($null -ne $currentHeading) {
            $currentLines.Add($line)
        }
    }

    if ($null -ne $currentHeading) {
        $sectionMap[$currentHeading] = ($currentLines -join "`n").Trim()
    }

    return $sectionMap
}

function Get-LeadSentence {
    param([AllowEmptyString()][string]$Section)

    if ([string]::IsNullOrWhiteSpace($Section)) {
        return ''
    }

    $lines = $Section -split "`n"
    $skipPatterns = @(
        '^(?:\*\*)?(Current progress status|Recommended next step|Owner|Reference)(?:\*\*)?$',
        '^[#>*`\-\s]+$'
    )

    $contentLine = ''
    foreach ($line in $lines) {
        $trimmed = $line.Trim()
        if ([string]::IsNullOrWhiteSpace($trimmed)) {
            continue
        }

        $shouldSkip = $false
        foreach ($pattern in $skipPatterns) {
            if ($trimmed -match $pattern) {
                $shouldSkip = $true
                break
            }
        }

        if (-not $shouldSkip) {
            $contentLine = $trimmed
            break
        }
    }

    if ([string]::IsNullOrWhiteSpace($contentLine)) {
        return ''
    }

    $contentLine = $contentLine -replace '^\*+', ''
    $contentLine = $contentLine -replace '\*+$', ''
    $sentenceMatch = [regex]::Match($contentLine, '^.+?(?:[.!?](?:\s|$)|$)')
    if ($sentenceMatch.Success) {
        return $sentenceMatch.Value.Trim()
    }

    return $contentLine.Trim()
}

function Get-GovernanceHitCount {
    param([AllowEmptyString()][string]$Text)

    if ([string]::IsNullOrWhiteSpace($Text)) {
        return 0
    }

    $hitCount = 0
    foreach ($pattern in $governancePatterns) {
        $matches = [regex]::Matches($Text, $pattern)
        if ($matches.Count -gt 0) {
            $hitCount += $matches.Count
        }
    }

    return $hitCount
}

function Test-HasPlainLanguageParaphrase {
    param(
        [AllowEmptyString()][string]$Lead,
        [int]$GovernanceHitCount
    )

    if ($GovernanceHitCount -lt 3) {
        return $false
    }

    $leadLower = $Lead.ToLowerInvariant()
    $plainLanguageStarts = @(
        'we need',
        'you need',
        'review ',
        'approve',
        'confirm',
        'run ',
        'manually',
        'updated',
        'completed',
        'finished',
        'i updated',
        'i completed',
        'i finished',
        'this slice',
        'next step',
        'provide'
    )

    foreach ($prefix in $plainLanguageStarts) {
        if ($leadLower.StartsWith($prefix)) {
            return $true
        }
    }

    return $false
}

function Test-HasExplicitProgressStatus {
    param([AllowEmptyString()][string]$Text)

    if ([string]::IsNullOrWhiteSpace($Text)) {
        return $false
    }

    $patterns = @(
        '(?i)\b(completed|updated|implemented|changed|reviewed|verified|created|recorded|fixed|finished|added)\b',
        '(?i)no files changed',
        '(?i)\b(blocked|waiting|pending|stopped|open|remaining)\b'
    )

    foreach ($pattern in $patterns) {
        if ($Text -match $pattern) {
            return $true
        }
    }

    return $false
}

function Test-HasExplicitNextStep {
    param([AllowEmptyString()][string]$Text)

    if ([string]::IsNullOrWhiteSpace($Text)) {
        return $false
    }

    $patterns = @(
        '(?i)\bnext step\b',
        '(?i)\b(no further action needed)\b',
        '(?i)\b(review|approve|confirm|run|provide|reply|authorize|sign off|test|continue)\b'
    )

    foreach ($pattern in $patterns) {
        if ($Text -match $pattern) {
            return $true
        }
    }

    return $false
}

function Test-MentionsBlockerOrRisk {
    param([AllowEmptyString()][string]$Text)

    if ([string]::IsNullOrWhiteSpace($Text)) {
        return $false
    }

    return $Text -match '(?i)\b(blocked|failed|skipped|risk|deferred|pending)\b|(?<!non-)blocking\b'
}

function Test-PlainlyDisclosesBlockerOrRisk {
    param([AllowEmptyString()][string]$Text)

    if ([string]::IsNullOrWhiteSpace($Text)) {
        return $false
    }

    return $Text -match '(?i)\b(because|cannot|needs|waiting|until|confidence|risk|blocked|skipped|failed)\b'
}

function Test-HasFileUri {
    param([AllowEmptyString()][string]$Text)

    if ([string]::IsNullOrWhiteSpace($Text)) {
        return $false
    }

    return $Text -match '(?i)file:///'
}

function Test-HasWindowsAbsolutePath {
    param([AllowEmptyString()][string]$Text)

    if ([string]::IsNullOrWhiteSpace($Text)) {
        return $false
    }

    return $Text -match '(?i)\b[A-Z]:[\\/][^\s`]+'
}

function Test-HasReviewCue {
    param([AllowEmptyString()][string]$Text)

    if ([string]::IsNullOrWhiteSpace($Text)) {
        return $false
    }

    return $Text -match '(?i)\breview\b'
}

function Test-MissingReviewFileReference {
    param([AllowEmptyString()][string]$Text)

    if ([string]::IsNullOrWhiteSpace($Text)) {
        return $false
    }

    if (Test-HasFileUri -Text $Text) {
        return $false
    }

    if (-not (Test-HasReviewCue -Text $Text)) {
        return $false
    }

    return Test-HasWindowsAbsolutePath -Text $Text
}

function Get-MeaningfulHandoffSectionText {
    param([AllowEmptyString()][string]$Text)

    if ([string]::IsNullOrWhiteSpace($Text)) {
        return ''
    }

    $meaningfulLines = New-Object System.Collections.Generic.List[string]
    foreach ($line in ($Text -split "`n")) {
        $trimmed = $line.Trim()
        if ([string]::IsNullOrWhiteSpace($trimmed)) {
            continue
        }

        if ($trimmed -match '^(?:\*\*)?(Current progress status|Recommended next step|Reference)(?:\*\*)?$') {
            continue
        }

        if ($trimmed -match '^(?:\*\*)?Owner(?:\*\*)?:') {
            continue
        }

        $meaningfulLines.Add($trimmed)
    }

    return ($meaningfulLines -join "`n").Trim()
}

function Get-NormalizedSemanticPhrase {
    param([AllowEmptyString()][string]$Text)

    if ([string]::IsNullOrWhiteSpace($Text)) {
        return ''
    }

    $normalized = $Text.ToLowerInvariant()
    $normalized = $normalized -replace "`r`n", "`n"
    $normalized = $normalized -replace '[`*_#>\[\]\(\),.:;!?-]+', ' '
    $normalized = $normalized -replace '\s+', ' '
    $normalized = $normalized.Trim()
    $normalized = $normalized -replace '^(recommended next step|next step)\s+', ''
    return $normalized.Trim()
}

function Test-UsesStopMessageFormat {
    param($SectionMap)

    return $SectionMap.Contains('What I just did') -and
        $SectionMap.Contains('Why I stopped') -and
        $SectionMap.Contains('What I need from you')
}

function Test-HasHumanActionCue {
    param([AllowEmptyString()][string]$Text)

    if ([string]::IsNullOrWhiteSpace($Text)) {
        return $false
    }

    return $Text -match '(?i)\b(review|approve|approval|confirm|clarify|answer|reply|authorize|sign off|provide|choose|decide|run|test)\b'
}

function Test-HasEmptyUserActionSection {
    param([AllowEmptyString()][string]$Text)

    $meaningfulText = Get-MeaningfulHandoffSectionText -Text $Text
    if ([string]::IsNullOrWhiteSpace($meaningfulText)) {
        return $true
    }

    $normalizedAction = Get-NormalizedSemanticPhrase -Text $meaningfulText
    if ([string]::IsNullOrWhiteSpace($normalizedAction)) {
        return $true
    }

    foreach ($placeholderPhrase in $placeholderUserActionPhrases) {
        if ($normalizedAction -eq (Get-NormalizedSemanticPhrase -Text $placeholderPhrase)) {
            return $true
        }
    }

    return $false
}

function Test-HasTransitionalStopClaim {
    param(
        [AllowEmptyString()][string]$WhyStoppedText,
        [AllowEmptyString()][string]$UserActionText
    )

    $whyText = Get-MeaningfulHandoffSectionText -Text $WhyStoppedText
    if ([string]::IsNullOrWhiteSpace($whyText)) {
        return $false
    }

    $hasTransitionalCue = $whyText -match '(?i)\b(waiting|wait|still working|still running|background (?:run|work|task|process)|transition(?:ing)?|in[- ]flight|underway|continue once|then i will continue|will continue once|pending completion)\b'
    if (-not $hasTransitionalCue) {
        return $false
    }

    $hasHumanBlockerCue = $whyText -match '(?i)\b(until you|waiting for your|need you to|once you|after you|your approval|your review|your confirmation|your clarification)\b'
    if ($hasHumanBlockerCue) {
        return $false
    }

    $actionText = Get-MeaningfulHandoffSectionText -Text $UserActionText
    return (Test-HasEmptyUserActionSection -Text $UserActionText) -or -not (Test-HasHumanActionCue -Text $actionText)
}

function Get-AuthoredParagraphs {
    param([AllowEmptyString()][string]$Text)

    if ([string]::IsNullOrWhiteSpace($Text)) {
        return @()
    }

    $headingPattern = '^(?:#{1,6}\s*)?(?:\*\*)?(What I just did|Why I stopped|What I need from you)(?:\*\*)?\s*$'
    $toolOutputPattern = '^(?:status:|findings:|summary:|PASS:|FAIL:|<command\b)'
    $paragraphs = New-Object System.Collections.Generic.List[string]
    $currentLines = New-Object System.Collections.Generic.List[string]
    $inCodeBlock = $false

    foreach ($line in ($Text -split "`n")) {
        $trimmed = $line.Trim()

        if ($trimmed -match '^```') {
            if ($currentLines.Count -gt 0) {
                $paragraphs.Add(($currentLines -join ' ').Trim())
                $currentLines.Clear()
            }

            $inCodeBlock = -not $inCodeBlock
            continue
        }

        if ($inCodeBlock) {
            continue
        }

        if ([string]::IsNullOrWhiteSpace($trimmed)) {
            if ($currentLines.Count -gt 0) {
                $paragraphs.Add(($currentLines -join ' ').Trim())
                $currentLines.Clear()
            }

            continue
        }

        if ($trimmed -match $headingPattern -or $trimmed -match $toolOutputPattern -or $trimmed -match '^\s*>') {
            if ($currentLines.Count -gt 0) {
                $paragraphs.Add(($currentLines -join ' ').Trim())
                $currentLines.Clear()
            }

            continue
        }

        $normalizedLine = $trimmed
        $normalizedLine = $normalizedLine -replace '^(?:[-*+]\s+|\d+\.\s+)', ''
        if (-not [string]::IsNullOrWhiteSpace($normalizedLine)) {
            $currentLines.Add($normalizedLine.Trim())
        }
    }

    if ($currentLines.Count -gt 0) {
        $paragraphs.Add(($currentLines -join ' ').Trim())
    }

    return $paragraphs.ToArray()
}

function Get-ReferencePattern {
    return '(?i)\b(?:feature\s+\d{3}|iteration\s+\d{3}|T\d{3}|FR-\d{3}|TG-[A-Za-z0-9-]+|(?:corpus\s+row|row)\s+\d+|[0-9a-f]{7,40}|0\d{2})\b'
}

function Get-ReferenceMatches {
    param([AllowEmptyString()][string]$Text)

    if ([string]::IsNullOrWhiteSpace($Text)) {
        return @()
    }

    $matches = [regex]::Matches($Text, (Get-ReferencePattern))
    $results = New-Object System.Collections.Generic.List[object]
    foreach ($match in $matches) {
        $results.Add([pscustomobject]@{
                Value  = $match.Value
                Index  = $match.Index
                Length = $match.Length
            })
    }

    return $results.ToArray()
}

function Test-HasMeaningfulDescriptor {
    param([AllowEmptyString()][string]$Text)

    if ([string]::IsNullOrWhiteSpace($Text)) {
        return $false
    }

    $cleanText = $Text -replace '(?i)file:///[^\s\)`]+' , ' '
    $cleanText = $cleanText -replace '(?i)\b[A-Z]:\\[^\s\)`]+', ' '
    $cleanText = $cleanText -replace '[`*_#\[\]\(\),.:;!?]+', ' '
    $words = @(
        $cleanText -split '\s+' |
        Where-Object { -not [string]::IsNullOrWhiteSpace($_) } |
        ForEach-Object { $_.ToLowerInvariant() } |
        Where-Object { $_ -match '^[a-z][a-z0-9-]*$' }
    )

    if ($words.Count -lt 2) {
        return $false
    }

    $genericWords = @(
        'a', 'an', 'and', 'are', 'as', 'at', 'be', 'before', 'being', 'by', 'complete', 'completed', 'confirm',
        'current', 'did', 'evidence', 'for', 'from', 'gate', 'guidance', 'hardening', 'i', 'implementation',
        'implemented', 'in', 'is', 'it', 'just', 'need', 'needs', 'next', 'of', 'on', 'or', 'pending', 'progress',
        'recorded', 'response', 'review', 'reviewed', 'schema', 'sign', 'signed', 'status', 'step', 'stopped',
        'that', 'the', 'this', 'to', 'updated', 'validator', 'verified', 'waiting', 'what', 'why', 'with', 'you'
    )

    $meaningfulWords = @($words | Where-Object { $genericWords -notcontains $_ })
    return $meaningfulWords.Count -ge 2
}

function Add-DescribedReferenceStarts {
    param(
        [System.Collections.Generic.HashSet[int]]$DescribedStarts,
        [string]$Paragraph,
        [string]$GroupValue,
        [int]$GroupStart
    )

    foreach ($referenceMatch in (Get-ReferenceMatches -Text $GroupValue)) {
        [void]$DescribedStarts.Add($GroupStart + $referenceMatch.Index)
    }
}

function Get-OpaqueReferenceCount {
    param([AllowEmptyString()][string]$Paragraph)

    if ([string]::IsNullOrWhiteSpace($Paragraph)) {
        return 0
    }

    $workingParagraph = $Paragraph -replace '(?i)file:///[^\s\)`]+', ' '
    $workingParagraph = $workingParagraph -replace '(?i)\b[A-Z]:\\[^\s\)`]+', ' '
    $referenceMatches = @(Get-ReferenceMatches -Text $workingParagraph)
    if ($referenceMatches.Count -lt 3) {
        return 0
    }

    $describedStarts = [System.Collections.Generic.HashSet[int]]::new()
    $referencePattern = Get-ReferencePattern
    $separatorPattern = '(?:\s*(?:,|\band\b|\bor\b|\bthrough\b|\bto\b|[-–])\s*)'
    $groupPattern = "(?<group>$referencePattern(?:$separatorPattern$referencePattern)*)"
    $afterDescriptorPattern = "^(?<group>$referencePattern(?:$separatorPattern$referencePattern)*)\s*(?:,|:|—|–|-)\s*(?<desc>[^.;:`n]+)"
    $beforeDescriptorPattern = '(?i)(?<desc>(?:the\s+)?[a-z][a-z-]*(?:\s+[a-z][a-z-]*){1,8})\s*(?:\(|for\s+|in\s+)$'

    foreach ($referenceMatch in $referenceMatches) {
        if ($describedStarts.Contains($referenceMatch.Index)) {
            continue
        }

        $afterText = $workingParagraph.Substring([Math]::Min($referenceMatch.Index + $referenceMatch.Length, $workingParagraph.Length))
        if ($afterText -match '^\s*(?:,|:|—|–|-)\s*(?<desc>[^.;:`n]+)' -and (Test-HasMeaningfulDescriptor -Text $Matches['desc'])) {
            [void]$describedStarts.Add($referenceMatch.Index)
            continue
        }

        $remainingText = $workingParagraph.Substring($referenceMatch.Index)
        $afterGroupMatch = [regex]::Match($remainingText, $afterDescriptorPattern)
        if ($afterGroupMatch.Success -and (Test-HasMeaningfulDescriptor -Text $afterGroupMatch.Groups['desc'].Value)) {
            Add-DescribedReferenceStarts -DescribedStarts $describedStarts -Paragraph $workingParagraph -GroupValue $afterGroupMatch.Groups['group'].Value -GroupStart $referenceMatch.Index
            continue
        }

        $prefixLength = [Math]::Min(80, $referenceMatch.Index)
        $prefixStart = $referenceMatch.Index - $prefixLength
        $beforeText = $workingParagraph.Substring($prefixStart, $prefixLength)
        if ($beforeText -match $beforeDescriptorPattern -and (Test-HasMeaningfulDescriptor -Text $Matches['desc'])) {
            $beforeGroupMatch = [regex]::Match($remainingText, "^(?<group>$referencePattern(?:$separatorPattern$referencePattern)*)")
            if ($beforeGroupMatch.Success) {
                Add-DescribedReferenceStarts -DescribedStarts $describedStarts -Paragraph $workingParagraph -GroupValue $beforeGroupMatch.Groups['group'].Value -GroupStart $referenceMatch.Index
                continue
            }

            [void]$describedStarts.Add($referenceMatch.Index)
        }
    }

    $describedValues = [System.Collections.Generic.HashSet[string]]::new([System.StringComparer]::OrdinalIgnoreCase)
    foreach ($referenceMatch in $referenceMatches) {
        if ($describedStarts.Contains($referenceMatch.Index)) {
            [void]$describedValues.Add($referenceMatch.Value)
        }
    }

    foreach ($referenceMatch in $referenceMatches) {
        if ($describedValues.Contains($referenceMatch.Value)) {
            [void]$describedStarts.Add($referenceMatch.Index)
        }
    }

    return @($referenceMatches | Where-Object { -not $describedStarts.Contains($_.Index) }).Count
}

function Test-HasOpaqueReferenceWarning {
    param([AllowEmptyString()][string]$Text)

    foreach ($paragraph in (Get-AuthoredParagraphs -Text $Text)) {
        if ((Get-OpaqueReferenceCount -Paragraph $paragraph) -ge 3) {
            return $true
        }
    }

    return $false
}

$normalizedText = Get-NormalizedText -Text $ResponseText
$warnings = New-Object System.Collections.Generic.List[string]
$sectionMap = Get-HandoffSectionMap -Text $normalizedText

if (-not (Test-HasExplicitProgressStatus -Text $normalizedText)) {
    $warnings.Add('soft-warning.missing-progress-status')
}

if (-not (Test-HasExplicitNextStep -Text $normalizedText)) {
    $warnings.Add('soft-warning.missing-next-step')
}

if (Test-MissingReviewFileReference -Text $normalizedText) {
    $warnings.Add('soft-warning.review-file-reference-format')
}

if (Test-HasOpaqueReferenceWarning -Text $normalizedText) {
    $warnings.Add('soft-warning.opaque-numeric-references')
}

foreach ($section in (Get-HandoffSections -Text $normalizedText)) {
    $lead = Get-LeadSentence -Section $section
    if ([string]::IsNullOrWhiteSpace($lead)) {
        continue
    }

    $governanceHitCount = Get-GovernanceHitCount -Text $lead
    if ($governanceHitCount -ge 3 -and -not (Test-HasPlainLanguageParaphrase -Lead $lead -GovernanceHitCount $governanceHitCount)) {
        if (-not $warnings.Contains('soft-warning.jargon-first-lead')) {
            $warnings.Add('soft-warning.jargon-first-lead')
        }
    }
}

if ((Test-MentionsBlockerOrRisk -Text $normalizedText) -and -not (Test-PlainlyDisclosesBlockerOrRisk -Text $normalizedText)) {
    $warnings.Add('soft-warning.hidden-blocker-or-risk')
}

if (Test-UsesStopMessageFormat -SectionMap $sectionMap) {
    $userActionSection = [string]$sectionMap['What I need from you']
    $whyStoppedSection = [string]$sectionMap['Why I stopped']

    if (Test-HasEmptyUserActionSection -Text $userActionSection) {
        $warnings.Add('soft-warning.empty-user-action-section')
    }

    if (Test-HasTransitionalStopClaim -WhyStoppedText $whyStoppedSection -UserActionText $userActionSection) {
        $warnings.Add('soft-warning.transitional-stop-claim')
    }
}

$status = if ($warnings.Count -gt 0) { 'warn' } else { 'pass' }
$summaryLines = New-Object System.Collections.Generic.List[string]
if ($warnings.Contains('soft-warning.jargon-first-lead')) {
    $summaryLines.Add('Rewrite the lead sentence in plain language before formal lifecycle references.')
}

if ($warnings.Contains('soft-warning.missing-progress-status')) {
    $summaryLines.Add('Add an explicit current progress status statement.')
}

if ($warnings.Contains('soft-warning.missing-next-step')) {
    $summaryLines.Add('Add a single explicit next step.')
}

if ($warnings.Contains('soft-warning.hidden-blocker-or-risk')) {
    $summaryLines.Add('State blockers or verification gaps plainly when they exist.')
}

if ($warnings.Contains('soft-warning.review-file-reference-format')) {
    $summaryLines.Add('Include a file:/// URI with the absolute Windows path when requesting local file review.')
}

if ($warnings.Contains('soft-warning.opaque-numeric-references')) {
    $summaryLines.Add('Add descriptive scope when three or more feature, iteration, task, requirement, corpus, or commit references appear in authored prose.')
}

if ($warnings.Contains('soft-warning.empty-user-action-section')) {
    $summaryLines.Add('Replace empty or placeholder user-action wording with one substantive immediate human action.')
}

if ($warnings.Contains('soft-warning.transitional-stop-claim')) {
    $summaryLines.Add('Use the three-section stop-message format only for real human blockers; keep transitional waiting updates as single-line progress prose.')
}

if ($summaryLines.Count -eq 0) {
    $summaryLines.Add('No soft warnings.')
}

Write-Output ("status: {0}" -f $status)
Write-Output 'findings:'
if ($warnings.Count -eq 0) {
    Write-Output '  - none'
}
else {
    foreach ($warning in $warnings) {
        Write-Output ("  - {0}" -f $warning)
    }
}

Write-Output 'summary:'
foreach ($summaryLine in $summaryLines) {
    Write-Output ("  - {0}" -f $summaryLine)
}

exit 0
