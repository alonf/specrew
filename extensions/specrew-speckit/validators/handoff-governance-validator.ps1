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

    return $Text -match '(?i)\b(blocked|blocking|failed|skipped|risk|deferred|pending)\b'
}

function Test-PlainlyDisclosesBlockerOrRisk {
    param([AllowEmptyString()][string]$Text)

    if ([string]::IsNullOrWhiteSpace($Text)) {
        return $false
    }

    return $Text -match '(?i)\b(because|cannot|needs|waiting|until|confidence|risk|blocked|skipped|failed)\b'
}

$normalizedText = Get-NormalizedText -Text $ResponseText
$warnings = New-Object System.Collections.Generic.List[string]

if (-not (Test-HasExplicitProgressStatus -Text $normalizedText)) {
    $warnings.Add('soft-warning.missing-progress-status')
}

if (-not (Test-HasExplicitNextStep -Text $normalizedText)) {
    $warnings.Add('soft-warning.missing-next-step')
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
