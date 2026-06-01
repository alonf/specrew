[CmdletBinding()]
param(
    [AllowEmptyString()]
    [string]$ResponseText = '',

    [string]$ProjectRoot = (Get-Location).Path,

    [string]$IterationPath,

    [string]$BoundaryName,

    [ValidateSet('auto', 'boundary-handoff', 'narration')]
    [string]$ResponseScope = 'auto',

    [ValidateSet('soft-warning', 'validation-fail')]
    [string]$BarePathBoundaryHandoffSeverity
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

$sharedGovernancePath = Join-Path (Split-Path -Parent $PSScriptRoot) 'scripts\shared-governance.ps1'
if (-not (Test-Path -LiteralPath $sharedGovernancePath -PathType Leaf)) {
    throw "Missing shared governance helper '$sharedGovernancePath'."
}
. $sharedGovernancePath

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

$boundaryPhraseMap = [ordered]@{
    'planning' = @('planning boundary', 'authorize planning', 'enter planning')
    'hardening-gate-and-implementation-auth' = @('hardening-gate-and-implementation-auth', 'hardening gate and implementation authorization')
    'hardening-gate-signoff' = @('hardening-gate-signoff', 'hardening gate sign-off', 'hardening-gate sign-off')
    'implementation' = @('implementation boundary', 'implementation authorization', 'authorize implementation', 'implementation')
    'review-boundary' = @('review boundary', 'authorize review-boundary', 'enter review-boundary', 'review-boundary')
    'review-verdict-signoff' = @('review-verdict-signoff', 'review verdict sign-off', 'review-verdict signoff')
    'retro-boundary' = @('retro boundary', 'retrospective boundary', 'retro-boundary')
    'iteration-closeout' = @('iteration closeout', 'iteration-closeout')
    'feature-closeout' = @('feature closeout', 'feature-closeout')
}

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

        if ($shouldSkip) {
            continue
        }

        $candidate = ($trimmed -replace '^\*+', '') -replace '\*+$', ''
        $sentenceMatch = [regex]::Match($candidate, '^.+?(?:[.!?](?:\s|$)|$)')
        if ($sentenceMatch.Success) {
            return $sentenceMatch.Value.Trim()
        }

        return $candidate.Trim()
    }

    return ''
}

function Get-GovernanceHitCount {
    param([AllowEmptyString()][string]$Text)

    if ([string]::IsNullOrWhiteSpace($Text)) {
        return 0
    }

    $hitCount = 0
    foreach ($pattern in $governancePatterns) {
        $hitCount += [regex]::Matches($Text, $pattern).Count
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
    foreach ($prefix in @('we need', 'you need', 'review ', 'approve', 'confirm', 'run ', 'manually', 'updated', 'completed', 'finished', 'i updated', 'i completed', 'i finished', 'this slice', 'next step', 'provide')) {
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

    foreach ($pattern in @('(?i)\b(completed|updated|implemented|changed|reviewed|verified|created|recorded|fixed|finished|added)\b', '(?i)no files changed', '(?i)\b(blocked|waiting|pending|stopped|open|remaining)\b')) {
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

    foreach ($pattern in @('(?i)\bnext step\b', '(?i)\b(no further action needed)\b', '(?i)\b(review|approve|confirm|run|provide|reply|authorize|sign off|continue|restart)\b')) {
        if ($Text -match $pattern) {
            return $true
        }
    }

    return $false
}

function Test-MentionsBlockerOrRisk {
    param([AllowEmptyString()][string]$Text)

    return -not [string]::IsNullOrWhiteSpace($Text) -and ($Text -match '(?i)\b(blocked|failed|skipped|risk|deferred|pending)\b|(?<!non-)blocking\b')
}

function Test-PlainlyDisclosesBlockerOrRisk {
    param([AllowEmptyString()][string]$Text)

    return -not [string]::IsNullOrWhiteSpace($Text) -and ($Text -match '(?i)\b(because|cannot|needs|waiting|until|confidence|risk|blocked|skipped|failed)\b')
}

function Test-HasFileUri {
    param([AllowEmptyString()][string]$Text)

    return -not [string]::IsNullOrWhiteSpace($Text) -and ($Text -match '(?i)file:///')
}

function Test-HasWindowsAbsolutePath {
    param([AllowEmptyString()][string]$Text)

    return -not [string]::IsNullOrWhiteSpace($Text) -and ($Text -match '(?i)\b[A-Z]:[\\/][^\s`]+' )
}

function Test-HasReviewCue {
    param([AllowEmptyString()][string]$Text)

    return -not [string]::IsNullOrWhiteSpace($Text) -and ($Text -match '(?i)\breview\b')
}

function Test-MissingReviewFileReference {
    param([AllowEmptyString()][string]$Text)

    if (-not (Test-HasReviewCue -Text $Text) -or -not (Test-HasWindowsAbsolutePath -Text $Text)) {
        return $false
    }

    return -not (Test-HasFileUri -Text $Text)
}

function Test-UsesStopMessageFormat {
    param([hashtable]$SectionMap)

    return $SectionMap.Contains('What I just did') -and $SectionMap.Contains('Why I stopped') -and $SectionMap.Contains('What I need from you')
}

function Test-UsesHumanReentryPacketCandidate {
    param([hashtable]$SectionMap)

    foreach ($heading in @('What needs your review', 'What happens next', 'Discussion prompts')) {
        if ($SectionMap.Contains($heading)) {
            return $true
        }
    }

    return $false
}

function Get-MissingHumanReentryPacketSections {
    param([hashtable]$SectionMap)

    $missing = New-Object System.Collections.Generic.List[string]
    foreach ($heading in @('What I just did', 'Why I stopped', 'What needs your review', 'What happens next', 'Discussion prompts', 'What I need from you')) {
        if (-not $SectionMap.Contains($heading)) {
            $missing.Add($heading) | Out-Null
        }
    }

    return @($missing.ToArray())
}

function Test-DiscussionPromptsCompliant {
    param([AllowEmptyString()][string]$Text)

    if ([string]::IsNullOrWhiteSpace($Text)) {
        return $false
    }

    $generalFallbackPattern = '(?i)Before I plan from this spec, is there anything you want corrected, constrained, expanded, or discussed\?'
    if ($Text -match $generalFallbackPattern) {
        return $true
    }

    $hasQuestion = $Text -match '\?'
    $hasContext = $Text -match '(?i)\b(context|because|decision|assumption|risk|tradeoff|uncertain|triggered|scope|package|architecture|release-blocking)\b'
    $hasDefaultOrConsequence = $Text -match '(?i)\b(default|recommend|recommended|consequence|changing direction|if we change|if you change|otherwise)\b'
    return $hasQuestion -and $hasContext -and $hasDefaultOrConsequence
}

function Test-HasEmptyUserActionSection {
    param([AllowEmptyString()][string]$Text)

    if ([string]::IsNullOrWhiteSpace($Text)) {
        return $true
    }

    foreach ($phrase in $placeholderUserActionPhrases) {
        if ($Text -match ('(?i)^\s*' + [regex]::Escape($phrase) + '\s*$')) {
            return $true
        }
    }

    return -not ($Text -match '(?i)\b(review|approve|confirm|run|provide|reply|authorize|sign off|restart|test)\b')
}

function Test-HasTransitionalStopClaim {
    param(
        [AllowEmptyString()][string]$WhyStoppedText,
        [AllowEmptyString()][string]$UserActionText
    )

    if ([string]::IsNullOrWhiteSpace($WhyStoppedText)) {
        return $false
    }

    $looksTransitional = $WhyStoppedText -match '(?i)\b(waiting|in progress|still running|background|transition|paused for now|slice is complete)\b'
    $hasSubstantiveAction = -not (Test-HasEmptyUserActionSection -Text $UserActionText)
    return $looksTransitional -and -not $hasSubstantiveAction
}

function Get-AuthoredParagraphs {
    param([AllowEmptyString()][string]$Text)

    if ([string]::IsNullOrWhiteSpace($Text)) {
        return @()
    }

    $normalized = $Text -replace "`r`n", "`n"
    $normalized = [regex]::Replace($normalized, '(?ms)```.*?```', '')
    $normalized = [regex]::Replace($normalized, '(?m)^\s*>.+$', '')
    return @($normalized -split '(?:\n\s*\n)+' | ForEach-Object { $_.Trim() } | Where-Object { -not [string]::IsNullOrWhiteSpace($_) })
}

function Get-OpaqueReferenceCount {
    param([AllowEmptyString()][string]$Paragraph)

    if ([string]::IsNullOrWhiteSpace($Paragraph)) {
        return 0
    }

    $referencePattern = '(?i)\b(?:feature\s+\d+|iteration\s+\d+|T\d{3,}|FR-\d+|TG-[A-Za-z0-9-]+|[0-9a-f]{7,40})\b'
    $referenceCount = [regex]::Matches($Paragraph, $referencePattern).Count
    if ($referenceCount -lt 3) {
        return 0
    }

    $descriptorPatterns = @(
        '(?i)\bfeature\s+\d+,\s+\w',
        '(?i)\biteration\s+\d+,\s+\w',
        '(?i)\(T\d{3,}\s+(?:and|through|-)\s*T\d{3,}\)',
        '(?i)\bT\d{3,}(?:\s+(?:and|through|-)\s*T\d{3,})?,\s+(?!T\d|FR-\d|TG-|[0-9a-f]{7,40}\b)(?:the|\w{3,})',
        '(?i)\(FR-\d+\s+(?:and|through|-)\s*FR-\d+\)',
        '(?i)\bFR-\d+(?:\s+(?:and|through|-)\s*FR-\d+)?,\s+(?!T\d|FR-\d|TG-|[0-9a-f]{7,40}\b)(?:the|\w{3,})',
        '(?i)\bTG-[A-Za-z0-9-]+,\s+\w',
        '(?i)\b[0-9a-f]{7,40},\s+(?!T\d|FR-\d|TG-|[0-9a-f]{7,40}\b)(?:the|\w{3,})'
    )

    $describedPatternCount = 0
    foreach ($pattern in $descriptorPatterns) {
        if ($Paragraph -match $pattern) {
            $describedPatternCount++
        }
    }

    if ($describedPatternCount -ge 2) {
        return 0
    }

    return $referenceCount
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

function Get-ResolvedResponseScope {
    param(
        [string]$RequestedScope,
        [hashtable]$SectionMap
    )

    if ($RequestedScope -ne 'auto') {
        return $RequestedScope
    }

    if (Test-UsesStopMessageFormat -SectionMap $SectionMap) {
        return 'boundary-handoff'
    }

    return 'narration'
}

function Get-IdentifierCount {
    param([AllowEmptyString()][string]$Text)

    if ([string]::IsNullOrWhiteSpace($Text)) {
        return 0
    }

    $patterns = @(
        '(?i)\bFR-\d+\b',
        '(?i)\bT\d{3,}\b',
        '(?i)\b[a-f0-9]{7,40}\b',
        '(?i)\b(?:authorization|decision|sign-off)-[a-z0-9-]+\b',
        '(?i)file:///[^\s)]+'
    )

    $count = 0
    foreach ($pattern in $patterns) {
        $count += [regex]::Matches($Text, $pattern).Count
    }

    return $count
}

function Get-WordCount {
    param([AllowEmptyString()][string]$Text)

    if ([string]::IsNullOrWhiteSpace($Text)) {
        return 0
    }

    return [regex]::Matches($Text, '\b[\p{L}\p{N}][\p{L}\p{N}\-/]*\b').Count
}

function Get-ExpectedBoundary {
    param(
        [string]$ResolvedProjectRoot,
        [string]$ResolvedIterationPath,
        [string]$ProvidedBoundaryName
    )

    if (-not [string]::IsNullOrWhiteSpace($ProvidedBoundaryName)) {
        return Normalize-InteractionModelBoundaryName -Boundary $ProvidedBoundaryName
    }

    if ([string]::IsNullOrWhiteSpace($ResolvedIterationPath) -or -not (Test-Path -LiteralPath $ResolvedIterationPath -PathType Container)) {
        return $null
    }

    $statePath = Join-Path $ResolvedIterationPath 'state.md'
    if (Test-Path -LiteralPath $statePath -PathType Leaf) {
        $stateLines = @(Get-MarkdownContent -Path $statePath)
        foreach ($label in @('Current Boundary', 'Next Boundary')) {
            $value = Get-MarkdownMetadataValue -Lines $stateLines -Label $label
            if (-not [string]::IsNullOrWhiteSpace($value)) {
                return Normalize-InteractionModelBoundaryName -Boundary $value
            }
        }

        $canonicalStateText = @(
            Get-MarkdownMetadataValue -Lines $stateLines -Label 'Current Phase'
            Get-MarkdownMetadataValue -Lines $stateLines -Label 'Iteration Status'
        ) -join ' '

        if (-not [string]::IsNullOrWhiteSpace($canonicalStateText)) {
            $normalizedStateText = $canonicalStateText.ToLowerInvariant()
            $boundaryPatterns = @(
                @{ Pattern = '(?i)\breview-verdict-signoff\b|review verdict sign-?off'; Boundary = 'review-verdict-signoff' }
                @{ Pattern = '(?i)\breview-boundary\b|\breview boundary\b|\breview authorization\b'; Boundary = 'review-boundary' }
                @{ Pattern = '(?i)\bretro-boundary\b|\bretrospective boundary\b|\bretrospective\b'; Boundary = 'retro-boundary' }
                @{ Pattern = '(?i)\biteration-closeout\b|\biteration closeout\b|\bcloseout boundary\b'; Boundary = 'iteration-closeout' }
                @{ Pattern = '(?i)\bhardening-gate-signoff\b|\bhardening gate sign-?off\b'; Boundary = 'hardening-gate-signoff' }
                @{ Pattern = '(?i)\bhardening-gate-and-implementation-auth\b|\bhardening gate and implementation authorization\b'; Boundary = 'hardening-gate-and-implementation-auth' }
                @{ Pattern = '(?i)\bimplementation\b|\bimplementation authorization\b'; Boundary = 'implementation' }
                @{ Pattern = '(?i)\bplanning\b'; Boundary = 'planning' }
            )

            foreach ($candidate in $boundaryPatterns) {
                if ($normalizedStateText -match $candidate.Pattern) {
                    return $candidate.Boundary
                }
            }
        }
    }

    $planPath = Join-Path $ResolvedIterationPath 'plan.md'
    if (-not (Test-Path -LiteralPath $planPath -PathType Leaf)) {
        return $null
    }

    $planLines = @(Get-MarkdownContent -Path $planPath)
    $status = (Get-MarkdownMetadataValue -Lines $planLines -Label 'Status')
    switch (($status | ForEach-Object { if ($null -eq $_) { '' } else { $_.ToLowerInvariant() } })) {
        'planning' { return 'planning' }
        'executing' { return 'implementation' }
        'reviewing' { return 'review-boundary' }
        'retro' { return 'retro-boundary' }
        'complete' { return 'iteration-closeout' }
        default { return $null }
    }
}

function Test-MentionsBoundary {
    param(
        [AllowEmptyString()][string]$Text,
        [AllowNull()][string]$Boundary
    )

    $normalizedBoundary = Normalize-InteractionModelBoundaryName -Boundary $Boundary
    if ([string]::IsNullOrWhiteSpace($Text) -or [string]::IsNullOrWhiteSpace($normalizedBoundary)) {
        return $false
    }

    if (-not $boundaryPhraseMap.Contains($normalizedBoundary)) {
        return $Text.ToLowerInvariant().Contains($normalizedBoundary)
    }

    foreach ($phrase in $boundaryPhraseMap[$normalizedBoundary]) {
        if ($Text -match ('(?i)\b' + [regex]::Escape($phrase) + '\b')) {
            return $true
        }
    }

    return $false
}

function Test-HasVerdictCue {
    param([AllowEmptyString()][string]$Text)

    return -not [string]::IsNullOrWhiteSpace($Text) -and ($Text -match '(?i)\b(approve|reject|authorize|sign off|confirm|accept|decline|pass|needs-work|blocked)\b')
}

function Get-MissingUserRequestComponents {
    param(
        [AllowEmptyString()][string]$Text,
        [AllowNull()][string]$ExpectedBoundary
    )

    $missing = New-Object System.Collections.Generic.List[string]
    if (-not (Test-MentionsBoundary -Text $Text -Boundary $ExpectedBoundary)) {
        $missing.Add('boundary-name') | Out-Null
    }

    if (-not (Test-HasFileUri -Text $Text)) {
        $missing.Add('inspection-target') | Out-Null
    }

    if (-not (Test-HasVerdictCue -Text $Text)) {
        $missing.Add('verdict-required') | Out-Null
    }

    return $missing.ToArray()
}

function Get-FileUriMatches {
    param([AllowEmptyString()][string]$Text)

    if ([string]::IsNullOrWhiteSpace($Text)) {
        return @()
    }

    return @([regex]::Matches($Text, '(?i)file:///[^\s)`"''<>]+') | ForEach-Object { $_.Value.TrimEnd(',', '.', ';', ':') })
}

function Convert-FileUriToWindowsPath {
    param([Parameter(Mandatory = $true)][string]$FileUri)

    try {
        $uri = [System.Uri]$FileUri
        return [System.Uri]::UnescapeDataString($uri.LocalPath)
    }
    catch {
        return $null
    }
}

function Get-BrokenFileUriFindings {
    param([AllowEmptyString()][string]$Text)

    $findings = New-Object System.Collections.Generic.List[string]
    foreach ($fileUri in (Get-FileUriMatches -Text $Text | Select-Object -Unique)) {
        $windowsPath = Convert-FileUriToWindowsPath -FileUri $fileUri
        if ([string]::IsNullOrWhiteSpace($windowsPath) -or -not (Test-Path -LiteralPath $windowsPath)) {
            $findings.Add("soft-warning.broken-file-url-reference :: reference=$fileUri") | Out-Null
        }
    }

    return $findings.ToArray()
}

function Get-PathScanLines {
    param([AllowEmptyString()][string]$Text)

    if ([string]::IsNullOrWhiteSpace($Text)) {
        return @()
    }

    $withoutCodeBlocks = [regex]::Replace(($Text -replace "`r`n", "`n"), '(?ms)```.*?```', '')
    $withoutMarkdownFileLinks = [regex]::Replace($withoutCodeBlocks, '(?i)\[[^\]\r\n]*\]\(file:///[^\s)]+\)', '')
    $withoutInlineCode = [regex]::Replace($withoutMarkdownFileLinks, '(?s)`[^`\r\n]+`', '')
    $withoutUrls = [regex]::Replace($withoutInlineCode, '(?i)\b[a-z][a-z0-9+\.-]*://[^\s)]+', '')
    return @($withoutUrls -split "`n")
}

function Test-IsExemptPathLine {
    param([AllowEmptyString()][string]$Line)

    if ([string]::IsNullOrWhiteSpace($Line)) {
        return $true
    }

    $trimmed = $Line.Trim()
    if ($trimmed -match '^(?i)(?:ps>|cmd>|info:|warn:|error:|trace:|\[[A-Z]+\])') {
        return $true
    }

    if ($trimmed -match '^\s*[\{\[].*[:=].*[\\/].*[\}\]]?\s*$') {
        return $true
    }

    if ($trimmed -match '^\s*[\w\.\-"]+\s*:\s*["'']?.+[\\/].*$') {
        return $true
    }

    if ($trimmed -match '^\s*/.+/[a-z]*\s*$') {
        return $true
    }

    if ($trimmed -match '(?i)\b(?:git|pwsh|powershell|npm|node|python|go|dotnet|gh|curl|Get-ChildItem|Select-String|Resolve-Path)\b.+(?:[\\/]|[\*\?])') {
        return $true
    }

    return $false
}

function Get-BarePathMatches {
    param(
        [AllowEmptyString()][string]$Text,
        [AllowEmptyCollection()][object[]]$ExemptionExtensions
    )

    $patterns = @(
        '(?i)(?<path>(?:[A-Z]:[\\/]|\.{1,2}[\\/]|(?:[A-Za-z0-9_.-]+[\\/])+[A-Za-z0-9_.-]+)(?:[\\/][A-Za-z0-9_.-]+)*)',
        '(?i)(?<![\w./\\-])(?<path>README\.md)(?![\w./\\-])'
    )
    $matches = New-Object System.Collections.Generic.List[string]

    foreach ($line in (Get-PathScanLines -Text $Text)) {
        if (Test-IsExemptPathLine -Line $line) {
            continue
        }

        foreach ($pattern in $patterns) {
            foreach ($match in [regex]::Matches($line, $pattern)) {
                $candidate = $match.Groups['path'].Value
                if ([string]::IsNullOrWhiteSpace($candidate)) {
                    continue
                }

                $isExtensionExempt = $false
                foreach ($extension in @($ExemptionExtensions)) {
                    if (-not [string]::IsNullOrWhiteSpace([string]$extension.Pattern) -and $candidate -match [string]$extension.Pattern) {
                        $isExtensionExempt = $true
                        break
                    }
                }

                if (-not $isExtensionExempt) {
                    $matches.Add($candidate) | Out-Null
                }
            }
        }
    }

    return @($matches | Select-Object -Unique)
}

$normalizedText = Get-NormalizedText -Text $ResponseText
$sectionMap = Get-InteractionModelSectionMap -Text $normalizedText
$resolvedResponseScope = Get-ResolvedResponseScope -RequestedScope $ResponseScope -SectionMap $sectionMap
$resolvedProjectRoot = Resolve-ProjectPath -Path $ProjectRoot
$resolvedIterationPath = if ([string]::IsNullOrWhiteSpace($IterationPath)) { $null } else { Resolve-ProjectPath -Path $IterationPath }
$settings = Get-InteractionModelSettings -ProjectRoot $resolvedProjectRoot
$effectiveBarePathSeverity = if ($PSBoundParameters.ContainsKey('BarePathBoundaryHandoffSeverity')) { $BarePathBoundaryHandoffSeverity } else { $settings.BarePathBoundaryHandoffSeverity }
$expectedBoundary = Get-ExpectedBoundary -ResolvedProjectRoot $resolvedProjectRoot -ResolvedIterationPath $resolvedIterationPath -ProvidedBoundaryName $BoundaryName
$hasInteractionBoundaryContext = -not [string]::IsNullOrWhiteSpace($expectedBoundary) -or -not [string]::IsNullOrWhiteSpace($BoundaryName) -or -not [string]::IsNullOrWhiteSpace($IterationPath)

$warnings = New-Object System.Collections.Generic.List[string]
$failures = New-Object System.Collections.Generic.List[string]
$summaryLines = New-Object System.Collections.Generic.List[string]

if (-not (Test-HasExplicitProgressStatus -Text $normalizedText)) {
    $warnings.Add('soft-warning.missing-progress-status') | Out-Null
}

if (-not (Test-HasExplicitNextStep -Text $normalizedText)) {
    $warnings.Add('soft-warning.missing-next-step') | Out-Null
}

if (Test-MissingReviewFileReference -Text $normalizedText) {
    $warnings.Add('soft-warning.review-file-reference-format') | Out-Null
}

if (Test-HasOpaqueReferenceWarning -Text $normalizedText) {
    $warnings.Add('soft-warning.opaque-numeric-references') | Out-Null
}

foreach ($section in (Get-InteractionModelSections -Text $normalizedText)) {
    $lead = Get-LeadSentence -Section $section
    if ([string]::IsNullOrWhiteSpace($lead)) {
        continue
    }

    $governanceHitCount = Get-GovernanceHitCount -Text $lead
    if ($governanceHitCount -ge 3 -and -not (Test-HasPlainLanguageParaphrase -Lead $lead -GovernanceHitCount $governanceHitCount)) {
        if (-not $warnings.Contains('soft-warning.jargon-first-lead')) {
            $warnings.Add('soft-warning.jargon-first-lead') | Out-Null
        }
    }
}

if ((Test-MentionsBlockerOrRisk -Text $normalizedText) -and -not (Test-PlainlyDisclosesBlockerOrRisk -Text $normalizedText)) {
    $warnings.Add('soft-warning.hidden-blocker-or-risk') | Out-Null
}

if (Test-UsesStopMessageFormat -SectionMap $sectionMap) {
    $whatIJustDid = [string]$sectionMap['What I just did']
    $whyStopped = [string]$sectionMap['Why I stopped']
    $whatINeed = [string]$sectionMap['What I need from you']

    if (Test-HasEmptyUserActionSection -Text $whatINeed) {
        $warnings.Add('soft-warning.empty-user-action-section') | Out-Null
    }

    if (Test-HasTransitionalStopClaim -WhyStoppedText $whyStopped -UserActionText $whatINeed) {
        $warnings.Add('soft-warning.transitional-stop-claim') | Out-Null
    }

    if ($resolvedResponseScope -eq 'boundary-handoff' -and $hasInteractionBoundaryContext) {
        $identifierCount = Get-IdentifierCount -Text $whatIJustDid
        $wordCount = Get-WordCount -Text $whatIJustDid
        $isCloseoutBoundary = $expectedBoundary -in @('iteration-closeout', 'feature-closeout')
        $meetsSubstance = if ($isCloseoutBoundary) { $identifierCount -ge 3 -or $wordCount -ge 50 } else { $identifierCount -ge 3 -and $wordCount -ge 50 }
        if (-not $meetsSubstance) {
            $warnings.Add(("soft-warning.thin-what-i-just-did :: boundary={0}; identifiers={1}; words={2}" -f $(if ([string]::IsNullOrWhiteSpace($expectedBoundary)) { 'unknown' } else { $expectedBoundary }), $identifierCount, $wordCount)) | Out-Null
        }

        if (-not (Test-MentionsBoundary -Text $whyStopped -Boundary $expectedBoundary)) {
            $warnings.Add(("soft-warning.unspecific-stop-boundary :: expected-boundary={0}" -f $(if ([string]::IsNullOrWhiteSpace($expectedBoundary)) { 'unknown' } else { $expectedBoundary }))) | Out-Null
        }

        $missingComponents = @(Get-MissingUserRequestComponents -Text $whatINeed -ExpectedBoundary $expectedBoundary)
        if ($missingComponents.Count -gt 0) {
            $warnings.Add(("soft-warning.unactionable-user-request :: missing={0}" -f ($missingComponents -join ','))) | Out-Null
        }
    }
}

if ($resolvedResponseScope -eq 'boundary-handoff' -and (Test-UsesHumanReentryPacketCandidate -SectionMap $sectionMap)) {
    $missingPacketSections = @(Get-MissingHumanReentryPacketSections -SectionMap $sectionMap)
    if ($missingPacketSections.Count -gt 0) {
        $failures.Add(("validation-fail.incomplete-human-reentry-packet :: missing={0}" -f ($missingPacketSections -join ','))) | Out-Null
    }

    if ($sectionMap.Contains('Discussion prompts') -and -not (Test-DiscussionPromptsCompliant -Text ([string]$sectionMap['Discussion prompts']))) {
        $failures.Add('validation-fail.non-contextual-discussion-prompts') | Out-Null
    }
}

foreach ($configIssue in @($settings.ConfigIssues)) {
    $warnings.Add("soft-warning.bare-path-config-issue :: $configIssue") | Out-Null
}

foreach ($brokenFileUri in (Get-BrokenFileUriFindings -Text $normalizedText)) {
    $warnings.Add($brokenFileUri) | Out-Null
}

$barePathMatches = @(Get-BarePathMatches -Text $normalizedText -ExemptionExtensions $settings.ExemptionExtensions)
if ($barePathMatches.Count -gt 0) {
    $detail = $barePathMatches -join ', '
    if ($resolvedResponseScope -eq 'boundary-handoff' -and $hasInteractionBoundaryContext) {
        $ruleId = "{0}.bare-path-in-boundary-handoff" -f $effectiveBarePathSeverity
        $finding = "$ruleId :: paths=$detail"
        if ($effectiveBarePathSeverity -eq 'validation-fail') {
            $failures.Add($finding) | Out-Null
        }
        else {
            $warnings.Add($finding) | Out-Null
        }
    }
    elseif ($resolvedResponseScope -eq 'narration') {
        $warnings.Add("soft-warning.bare-path-in-narration :: paths=$detail") | Out-Null
    }
}

if ($warnings.Contains('soft-warning.jargon-first-lead')) {
    $summaryLines.Add('Rewrite the lead sentence in plain language before formal lifecycle references.') | Out-Null
}

if ($warnings.Contains('soft-warning.missing-progress-status')) {
    $summaryLines.Add('Add an explicit current progress status statement.') | Out-Null
}

if ($warnings.Contains('soft-warning.missing-next-step')) {
    $summaryLines.Add('Add a single explicit next step.') | Out-Null
}

if ($warnings.Contains('soft-warning.hidden-blocker-or-risk')) {
    $summaryLines.Add('State blockers or verification gaps plainly when they exist.') | Out-Null
}

if ($warnings.Contains('soft-warning.review-file-reference-format')) {
    $summaryLines.Add('Include a file:/// URI with the absolute Windows path when requesting local file review.') | Out-Null
}

if ($warnings.Contains('soft-warning.opaque-numeric-references')) {
    $summaryLines.Add('Add descriptive scope when three or more feature, iteration, task, requirement, corpus, or commit references appear in authored prose.') | Out-Null
}

if ($warnings.Contains('soft-warning.empty-user-action-section')) {
    $summaryLines.Add('Replace empty or placeholder user-action wording with one substantive immediate human action.') | Out-Null
}

if ($warnings.Contains('soft-warning.transitional-stop-claim')) {
    $summaryLines.Add('Use the three-section stop-message format only for real human blockers; keep transitional waiting updates as single-line progress prose.') | Out-Null
}

if (@($warnings | Where-Object { $_ -like 'soft-warning.thin-what-i-just-did*' }).Count -gt 0) {
    $summaryLines.Add('Strengthen "What I just did" with at least three concrete identifiers and enough words for the active boundary.') | Out-Null
}

if (@($warnings | Where-Object { $_ -like 'soft-warning.unspecific-stop-boundary*' }).Count -gt 0) {
    $summaryLines.Add('Name the exact boundary in "Why I stopped" and keep it aligned with the active iteration state.') | Out-Null
}

if (@($warnings | Where-Object { $_ -like 'soft-warning.unactionable-user-request*' }).Count -gt 0) {
    $summaryLines.Add('Name the boundary, provide file:/// inspection targets, and request an explicit verdict in "What I need from you".') | Out-Null
}

if (@($warnings | Where-Object { $_ -like 'soft-warning.bare-path-in-*' }).Count -gt 0) {
    $summaryLines.Add('Replace bare paths with file:/// URIs unless the path is inside an approved exempt context.') | Out-Null
}

if (@($warnings | Where-Object { $_ -like 'soft-warning.broken-file-url-reference*' }).Count -gt 0) {
    $summaryLines.Add('Repair or remove file:/// references that do not resolve to existing files.') | Out-Null
}

if ($failures.Count -gt 0) {
    $summaryLines.Add('Hard validation findings block this handoff until the referenced path or boundary issue is repaired.') | Out-Null
}

if ($summaryLines.Count -eq 0) {
    $summaryLines.Add('No soft warnings.') | Out-Null
}

$status = if ($failures.Count -gt 0) { 'fail' } elseif ($warnings.Count -gt 0) { 'warn' } else { 'pass' }

Write-Output ("status: {0}" -f $status)
Write-Output 'findings:'
if ($failures.Count -eq 0 -and $warnings.Count -eq 0) {
    Write-Output '  - none'
}
else {
    foreach ($finding in @($failures + $warnings)) {
        Write-Output ("  - {0}" -f $finding)
    }
}

Write-Output 'summary:'
foreach ($summaryLine in $summaryLines) {
    Write-Output ("  - {0}" -f $summaryLine)
}

if ($failures.Count -gt 0) {
    exit 1
}

exit 0
