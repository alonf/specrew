Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

$script:SpecrewDesignAnalysisGateMinimumVersion = [version]'0.30.0'
$script:SpecrewDesignAnalysisDefaultIterationNumber = '001'

function Normalize-SpecrewDesignAnalysisFeatureRef {
    param([AllowNull()][string]$FeatureRef)

    if ([string]::IsNullOrWhiteSpace($FeatureRef)) { return $null }
    $trimmed = $FeatureRef.Trim()
    if ($trimmed -match '^[A-Za-z]:\\' -or $trimmed.StartsWith('\\') -or $trimmed -match '^specs[\\/]') {
        return Split-Path -Leaf $trimmed
    }
    return $trimmed
}

function Normalize-SpecrewDesignAnalysisIterationNumber {
    param([AllowNull()][string]$IterationNumber)

    if ([string]::IsNullOrWhiteSpace($IterationNumber) -or $IterationNumber -eq '(none)') {
        return $script:SpecrewDesignAnalysisDefaultIterationNumber
    }

    if ($IterationNumber -match '^\d+$') {
        return ([int]$IterationNumber).ToString('000')
    }

    return $IterationNumber.Trim()
}

function Get-SpecrewDesignAnalysisArtifactPath {
    param(
        [Parameter(Mandatory = $true)][string]$ProjectRoot,
        [Parameter(Mandatory = $true)][string]$FeatureRef,
        [AllowNull()][string]$IterationNumber
    )

    $feature = Normalize-SpecrewDesignAnalysisFeatureRef -FeatureRef $FeatureRef
    $iteration = Normalize-SpecrewDesignAnalysisIterationNumber -IterationNumber $IterationNumber
    return Join-Path $ProjectRoot ("specs\{0}\iterations\{1}\design-analysis.md" -f $feature, $iteration)
}

function Get-SpecrewDesignAnalysisConfigVersion {
    param([Parameter(Mandatory = $true)][string]$ProjectRoot)

    $configPath = Join-Path $ProjectRoot '.specrew\config.yml'
    if (-not (Test-Path -LiteralPath $configPath -PathType Leaf)) { return $null }

    $content = Get-Content -LiteralPath $configPath -Raw -Encoding UTF8
    if ($content -notmatch '(?m)^\s*specrew_version:\s*["'']?(?<version>\d+\.\d+\.\d+)') { return $null }

    try { return [version]$Matches['version'] }
    catch { return $null }
}

function Get-SpecrewDesignAnalysisStartContext {
    param([Parameter(Mandatory = $true)][string]$ProjectRoot)

    $contextPath = Join-Path $ProjectRoot '.specrew\start-context.json'
    if (-not (Test-Path -LiteralPath $contextPath -PathType Leaf)) { return $null }

    try {
        return Get-Content -LiteralPath $contextPath -Raw -Encoding UTF8 | ConvertFrom-Json -Depth 20
    }
    catch {
        return $null
    }
}

function Test-SpecrewDesignAnalysisSubstantiveFeature {
    param(
        [Parameter(Mandatory = $true)][string]$ProjectRoot,
        [Parameter(Mandatory = $true)][string]$FeatureRef
    )

    $feature = Normalize-SpecrewDesignAnalysisFeatureRef -FeatureRef $FeatureRef
    $specPath = Join-Path $ProjectRoot ("specs\{0}\spec.md" -f $feature)
    if (-not (Test-Path -LiteralPath $specPath -PathType Leaf)) { return $false }

    $specText = Get-Content -LiteralPath $specPath -Raw -Encoding UTF8
    $trivialSignal = $specText -match '(?i)\b(trivial|doc-only|documentation-only|small bug[- ]?fix|small chore|minor copy|typo-only)\b'
    $substantiveSignal = $specText -match '(?i)\b(lifecycle|governance|architecture|architectural|enforcement|boundary|state|helper|validator|validation|security|compatibility|integration)\b'
    if ($trivialSignal -and -not $substantiveSignal) { return $false }

    return $true
}

function Get-SpecrewDesignAnalysisSection {
    param(
        [Parameter(Mandatory = $true)][string]$Content,
        [Parameter(Mandatory = $true)][string[]]$HeadingPatterns
    )

    foreach ($headingPattern in $HeadingPatterns) {
        $regex = "(?ims)^#{1,2}\s*(?:$headingPattern)\s*$\r?\n(?<body>.*?)(?=^#{1,2}\s+|\z)"
        $match = [regex]::Match($Content, $regex)
        if ($match.Success) {
            return [pscustomobject]@{
                Found = $true
                Body  = $match.Groups['body'].Value.Trim()
            }
        }
    }

    return [pscustomobject]@{
        Found = $false
        Body  = ''
    }
}

function Test-SpecrewDesignAnalysisPlaceholderText {
    param([AllowNull()][string]$Text)

    if ([string]::IsNullOrWhiteSpace($Text)) { return $true }
    $trimmed = $Text.Trim()
    return ($trimmed -match '^(?:tbd|todo|placeholder|n/a|none|pending|to be decided|to be filled)(?:\s|\.)*$')
}

function Get-SpecrewDesignAnalysisOptionBlock {
    param(
        [Parameter(Mandatory = $true)][string]$AlternativesText,
        [Parameter(Mandatory = $true)][string]$OptionName
    )

    # FR-022: tolerate normal authored prose for By-the-book ("By the book" with or
    # without a hyphen) while still enforcing the required option shape.
    $namePattern = if ($OptionName -match '(?i)^by[-\s]?the[-\s]?book$') { 'By[-\s]+the[-\s]+book' } else { [regex]::Escape($OptionName) }
    $terminator = '(?:Simplest|Reasonable|By[-\s]+the[-\s]+book)'
    $regex = "(?ims)^#{2,6}\s*(?:Option\s+[A-Z]\s*[:\-]\s*)?$namePattern\b.*?\r?\n(?<body>.*?)(?=^#{2,6}\s+(?:Option\s+[A-Z]\s*[:\-]\s*)?$terminator\b|\z)"
    $match = [regex]::Match($AlternativesText, $regex)
    if (-not $match.Success) {
        return $null
    }

    return $match.Groups['body'].Value.Trim()
}

function Test-SpecrewDesignAnalysisOptionField {
    param(
        [Parameter(Mandatory = $true)][string]$Block,
        [Parameter(Mandatory = $true)][string]$FieldName
    )

    $escaped = [regex]::Escape($FieldName)
    return ($Block -match "(?im)^\s*(?:[-*]\s*)?(?:\*\*)?$escaped(?:\*\*)?\s*[:\-]\s*\S")
}

function Get-SpecrewDesignAnalysisNamedOption {
    param([AllowNull()][string]$Text)

    if ([string]::IsNullOrWhiteSpace($Text)) { return $null }

    $matches = [regex]::Matches($Text, '(?i)\b(Option\s+[A-Z]|Simplest|Reasonable|By[-\s]?the[-\s]?book)\b')
    $unique = New-Object System.Collections.Generic.List[string]
    foreach ($match in $matches) {
        $value = $match.Groups[1].Value.Trim()
        $normalized = if ($value -match '(?i)^option\s+([A-Z])$') {
            'Option ' + $Matches[1].ToUpperInvariant()
        } elseif ($value -match '(?i)^by[-\s]?the[-\s]?book$') {
            'By-the-book'
        } elseif ($value -match '(?i)^simplest$') {
            'Simplest'
        } elseif ($value -match '(?i)^reasonable$') {
            'Reasonable'
        } else {
            $value
        }
        if (-not $unique.Contains($normalized)) {
            $unique.Add($normalized) | Out-Null
        }
    }

    if ($unique.Count -eq 1) { return $unique[0] }
    if ($unique.Count -gt 1) { return ($unique -join ', ') }
    return $null
}

function Get-SpecrewDesignAnalysisMarkedOption {
    # FR-023: resolve exactly one option from a section that carries an explicit
    # marker line (e.g., "Recommended: Option B" or "Chosen option: Option B"),
    # tolerating bold/list markup, so contextual mentions of rejected options in the
    # surrounding rationale do not make the section look multi-valued. Falls back to
    # the legacy whole-text single-token detection when no marker line is present.
    param(
        [AllowNull()][string]$Text,
        [Parameter(Mandatory = $true)][string]$Marker
    )

    if ([string]::IsNullOrWhiteSpace($Text)) { return $null }

    $pattern = '(?im)^\s*[-*>\s]*\**\s*' + $Marker + '\**\s*[:\-]?\s*\**\s*(?<opt>Option\s+[A-Z]|Simplest|Reasonable|By[-\s]?the[-\s]?book)\b'
    $markerMatch = [regex]::Match($Text, $pattern)
    if ($markerMatch.Success) {
        return (Get-SpecrewDesignAnalysisNamedOption -Text $markerMatch.Groups['opt'].Value)
    }

    return (Get-SpecrewDesignAnalysisNamedOption -Text $Text)
}

function Test-SpecrewDesignAnalysisGateRequired {
    param(
        [Parameter(Mandatory = $true)][string]$ProjectRoot,
        [Parameter(Mandatory = $true)][string]$FeatureRef,
        [AllowNull()][string]$IterationNumber
    )

    $feature = Normalize-SpecrewDesignAnalysisFeatureRef -FeatureRef $FeatureRef
    if ([string]::IsNullOrWhiteSpace($feature)) { return $false }

    $artifactPath = Get-SpecrewDesignAnalysisArtifactPath -ProjectRoot $ProjectRoot -FeatureRef $feature -IterationNumber $IterationNumber
    if (Test-Path -LiteralPath $artifactPath -PathType Leaf) { return $true }

    $version = Get-SpecrewDesignAnalysisConfigVersion -ProjectRoot $ProjectRoot
    if ($null -eq $version -or $version -lt $script:SpecrewDesignAnalysisGateMinimumVersion) { return $false }

    $context = Get-SpecrewDesignAnalysisStartContext -ProjectRoot $ProjectRoot
    if ($null -eq $context -or $null -eq $context.session_state) { return $false }
    if (-not [bool]$context.session_state.active) { return $false }

    $contextFeature = Normalize-SpecrewDesignAnalysisFeatureRef -FeatureRef ([string]$context.session_state.feature_ref)
    if ($contextFeature -ne $feature) { return $false }

    $currentBoundary = [string]$context.session_state.boundary_type
    $lastAuthorized = if ($null -ne $context.boundary_enforcement) { [string]$context.boundary_enforcement.last_authorized_boundary } else { '' }
    $isPrePlanActiveBoundary = @('specify', 'clarify', 'before-plan') -contains $currentBoundary -or @('specify', 'clarify', 'before-plan') -contains $lastAuthorized
    if (-not $isPrePlanActiveBoundary) { return $false }

    return (Test-SpecrewDesignAnalysisSubstantiveFeature -ProjectRoot $ProjectRoot -FeatureRef $feature)
}

function Test-SpecrewDesignAnalysisLensAddressedPlaceholder {
    # FR-026: an "Addressed:" coverage value does NOT count as addressing a lens when it is empty, a
    # TBD-class token, or the unfilled angle-bracket template default emitted by the enriched render.
    param([AllowNull()][string]$Value)

    if (Test-SpecrewDesignAnalysisPlaceholderText -Text $Value) { return $true }
    return ([string]$Value).Trim() -match '^<.*>$'
}

function Test-SpecrewDesignAnalysisLensCoverage {
    # FR-026 (Amendment A2): deterministic, LLM/network-free lens-coverage enforcement. For each lens
    # the FR-025 questionnaire selected (lens-applicability.json `selected`), the design analysis MUST
    # carry a non-placeholder "Addressed:" coverage entry in its "## Applicable Lenses" section; else
    # the gate blocks plan, naming the unaddressed lens.
    #
    # This is an ANTI-OMISSION backstop, NOT a quality guarantee: it proves no selected lens was
    # silently dropped from the analysis. It deliberately does NOT judge whether the engagement is
    # genuine — a deterministic check cannot. Genuine engagement is enforced by the human design-
    # analysis gate plus the blocking delete-the-`Addressed:`-lines discriminator at review-signoff.
    #
    # Enforcement is the DEFAULT whenever a questionnaire recorded selected lenses: absence of the
    # "Addressed:" entries FAILS (every selected lens is reported unaddressed). Grandfathering is
    # EXPLICIT, never inferred from missing "Addressed:" lines — a pre-FR-026 artifact must carry an
    # explicit `fr026_grandfathered: true` marker in its lens-applicability.json to be exempt. This
    # closes the deleting-all-`Addressed:`-lines bypass that would otherwise silently no-op the gate
    # (the gate-completeness hole found by the Proposal 145 Phase 5 review). Returns a string[] of
    # error messages (empty = OK / not applicable).
    param(
        [Parameter(Mandatory = $true)][string]$Content,
        [Parameter(Mandatory = $true)][string]$IterationDirectory
    )

    $errors = New-Object System.Collections.Generic.List[string]

    # Selected lenses + the explicit grandfather marker both come from the recorded questionnaire
    # artifact (decoupled; the JSON is the audit record). Resolution order (A3 — the lens intake is
    # now feature/specify-phase truth, recorded once at the feature level, not copied per iteration):
    #   1. iterations/<NNN>/lens-applicability.json   (override / Iteration 4-5 back-compat)
    #   2. feature-level lens-applicability.json       (the specify-phase truth)
    #   3. neither present -> graceful no-op (SC-006)
    # Resolving (not copying) keeps a single source of truth and avoids drift between duplicates.
    $iterationArtifact = Join-Path $IterationDirectory 'lens-applicability.json'
    $featureDirectory = Split-Path -Parent (Split-Path -Parent $IterationDirectory)
    $featureArtifact = if (-not [string]::IsNullOrWhiteSpace($featureDirectory)) { Join-Path $featureDirectory 'lens-applicability.json' } else { $null }

    $answersPath = if (Test-Path -LiteralPath $iterationArtifact -PathType Leaf) {
        $iterationArtifact
    }
    elseif ($null -ne $featureArtifact -and (Test-Path -LiteralPath $featureArtifact -PathType Leaf)) {
        $featureArtifact
    }
    else {
        $null
    }
    if ($null -eq $answersPath) { return @() }

    $doc = $null
    try { $doc = Get-Content -LiteralPath $answersPath -Raw -Encoding UTF8 | ConvertFrom-Json }
    catch { return @() }
    if ($null -eq $doc) { return @() }

    $selected = @()
    if ($doc.PSObject.Properties['selected']) {
        $selected = @($doc.selected | ForEach-Object { [string]$_ } | Where-Object { -not [string]::IsNullOrWhiteSpace($_) })
    }
    if ($selected.Count -eq 0) { return @() }

    # EXPLICIT grandfather (not inferred): a recorded `fr026_grandfathered: true` marker exempts a
    # pre-FR-026 artifact. Enforcement is otherwise the default, so deleting every "Addressed:" line
    # from an FR-026-era artifact does NOT no-op the gate — every selected lens is reported below.
    if ($doc.PSObject.Properties['fr026_grandfathered'] -and [bool]$doc.fr026_grandfathered) { return @() }

    $section = Get-SpecrewDesignAnalysisSection -Content $Content -HeadingPatterns @('Applicable\s+Lenses')
    $body = if ($section.Found) { $section.Body } else { '' }

    foreach ($id in $selected) {
        $blockRegex = '(?ims)^[-*]\s*\*\*' + [regex]::Escape($id) + '\*\*.*?(?=^[-*]\s*\*\*|\z)'
        $blockMatch = [regex]::Match($body, $blockRegex)
        $addressed = $null
        if ($blockMatch.Success) {
            $addressedMatch = [regex]::Match($blockMatch.Value, '(?im)^\s*[-*]?\s*Addressed\s*:\s*(?<v>.*)$')
            if ($addressedMatch.Success) { $addressed = $addressedMatch.Groups['v'].Value }
        }
        if ($null -eq $addressed -or (Test-SpecrewDesignAnalysisLensAddressedPlaceholder -Value $addressed)) {
            $errors.Add(("design-analysis.md does not address selected lens '{0}' (FR-026 anti-omission): add a non-placeholder 'Addressed:' coverage entry for it in the Applicable Lenses section, pointing into the option comparison." -f $id)) | Out-Null
        }
    }

    return $errors.ToArray()
}

function Test-SpecrewDesignAnalysisArtifact {
    param(
        [Parameter(Mandatory = $true)][string]$ProjectRoot,
        [Parameter(Mandatory = $true)][string]$FeatureRef,
        [AllowNull()][string]$IterationNumber
    )

    $feature = Normalize-SpecrewDesignAnalysisFeatureRef -FeatureRef $FeatureRef
    $iteration = Normalize-SpecrewDesignAnalysisIterationNumber -IterationNumber $IterationNumber
    $artifactPath = Get-SpecrewDesignAnalysisArtifactPath -ProjectRoot $ProjectRoot -FeatureRef $feature -IterationNumber $iteration
    $errors = New-Object System.Collections.Generic.List[string]

    if (-not (Test-Path -LiteralPath $artifactPath -PathType Leaf)) {
        $errors.Add("Missing design-analysis artifact: $artifactPath") | Out-Null
        return [pscustomobject]@{
            Valid          = $false
            ArtifactPath   = $artifactPath
            Errors         = @($errors)
            SelectedOption = $null
        }
    }

    $content = Get-Content -LiteralPath $artifactPath -Raw -Encoding UTF8
    $problem = Get-SpecrewDesignAnalysisSection -Content $content -HeadingPatterns @('Problem\s+Framing', 'Problem')
    $decisionPoints = Get-SpecrewDesignAnalysisSection -Content $content -HeadingPatterns @('Key\s+Design\s+Decision\s+Points', 'Decision\s+Points')
    $alternatives = Get-SpecrewDesignAnalysisSection -Content $content -HeadingPatterns @('Alternatives', 'Design\s+Alternatives')
    $recommendation = Get-SpecrewDesignAnalysisSection -Content $content -HeadingPatterns @('Crew\s+Recommendation', 'Recommendation')
    $humanDecision = Get-SpecrewDesignAnalysisSection -Content $content -HeadingPatterns @('Human\s+Decision')

    foreach ($section in @(
            @{ Name = 'Problem Framing'; Value = $problem },
            @{ Name = 'Key Design Decision Points'; Value = $decisionPoints },
            @{ Name = 'Alternatives'; Value = $alternatives },
            @{ Name = 'Crew Recommendation'; Value = $recommendation },
            @{ Name = 'Human Decision'; Value = $humanDecision }
        )) {
        if (-not $section.Value.Found -or (Test-SpecrewDesignAnalysisPlaceholderText -Text $section.Value.Body)) {
            $errors.Add("design-analysis.md is missing a populated $($section.Name) section.") | Out-Null
        }
    }

    if ($alternatives.Found) {
        $simplest = Get-SpecrewDesignAnalysisOptionBlock -AlternativesText $alternatives.Body -OptionName 'Simplest'
        $reasonable = Get-SpecrewDesignAnalysisOptionBlock -AlternativesText $alternatives.Body -OptionName 'Reasonable'
        $byTheBook = Get-SpecrewDesignAnalysisOptionBlock -AlternativesText $alternatives.Body -OptionName 'By-the-book'

        if ([string]::IsNullOrWhiteSpace($simplest)) {
            $errors.Add('Alternatives must include a populated Simplest option.') | Out-Null
        }
        if ([string]::IsNullOrWhiteSpace($reasonable)) {
            $errors.Add('Alternatives must include a populated Reasonable option.') | Out-Null
        }

        foreach ($option in @(
                @{ Name = 'Simplest'; Block = $simplest },
                @{ Name = 'Reasonable'; Block = $reasonable },
                @{ Name = 'By-the-book'; Block = $byTheBook }
            )) {
            if ([string]::IsNullOrWhiteSpace($option.Block)) { continue }

            foreach ($field in @('Approach', 'Architectural pattern', 'Quality features considered', 'Effort estimate', 'Reversibility cost', 'Trade-offs')) {
                if (-not (Test-SpecrewDesignAnalysisOptionField -Block $option.Block -FieldName $field)) {
                    $errors.Add("$($option.Name) option is missing required field: $field.") | Out-Null
                }
            }

            if ($option.Block -notmatch '(?is)```mermaid|diagram\s+(?:link|url)\s*[:\-]\s*\S|diagram\s*[:\-]\s*\S') {
                $errors.Add("$($option.Name) option is missing a Mermaid diagram or diagram link.") | Out-Null
            }
        }

        if ([string]::IsNullOrWhiteSpace($byTheBook) -and $alternatives.Body -notmatch '(?is)by[-\s]?the[-\s]?book.*(?:not\s+meaningfully\s+distinct|not\s+distinct|not-applicable|not\s+applicable|deferred)') {
            $errors.Add('Alternatives must include By-the-book when distinct, or state why By-the-book is not meaningfully distinct.') | Out-Null
        }
    }

    $recommendedOption = Get-SpecrewDesignAnalysisMarkedOption -Text $recommendation.Body -Marker 'Recommended'
    if ($recommendation.Found) {
        if (Test-SpecrewDesignAnalysisPlaceholderText -Text $recommendation.Body) {
            $errors.Add('Crew Recommendation must be populated and cannot be placeholder text.') | Out-Null
        }
        elseif ([string]::IsNullOrWhiteSpace($recommendedOption)) {
            $errors.Add('Crew Recommendation must name exactly one recommended option.') | Out-Null
        }
        elseif ($recommendedOption -like '*,*') {
            $errors.Add("Crew Recommendation names multiple options ($recommendedOption); name exactly one.") | Out-Null
        }
    }

    $selectedOption = Get-SpecrewDesignAnalysisMarkedOption -Text $humanDecision.Body -Marker 'Chosen\s+Option'
    if ($humanDecision.Found) {
        if (Test-SpecrewDesignAnalysisPlaceholderText -Text $humanDecision.Body) {
            $errors.Add('Human Decision must be populated and cannot be placeholder text.') | Out-Null
        }
        if ($humanDecision.Body -notmatch '(?i)approved\s+for\s+plan\s+with\s+Option\s+[A-Z]' -and $humanDecision.Body -notmatch '(?im)^\s*(?:[-*]\s*)?(?:\*\*)?Chosen\s+Option(?:\*\*)?\s*[:\-]\s*\S') {
            $errors.Add('Human Decision must record a verdict equivalent to "approved for plan with Option <X>" or a Chosen Option field.') | Out-Null
        }
        if ([string]::IsNullOrWhiteSpace($selectedOption)) {
            $errors.Add('Human Decision must name the chosen option.') | Out-Null
        }
        if ($humanDecision.Body -notmatch '(?i)\b(reason|rationale|modification|modifications|instruction|instructions)\b') {
            $errors.Add('Human Decision must record the human reason, modifications, or instructions.') | Out-Null
        }
        if ($humanDecision.Body -notmatch '(?i)\b[0-9a-f]{7,40}\b') {
            $errors.Add('Human Decision must record a commit hash.') | Out-Null
        }
        # FR-003 metadata integrity (Fix 3, 2026-06-02 smoke): the decision commit must be
        # the commit that contains the populated Human Decision, NOT the design-analysis
        # draft commit. Reject recording the draft commit as the decision commit.
        $draftCommit = [regex]::Match($humanDecision.Body, '(?im)^\s*[-*]?\s*\**\s*Design-analysis draft commit\**\s*[:\-]\s*`?([0-9a-f]{7,40})`?')
        $decisionCommit = [regex]::Match($humanDecision.Body, '(?im)^\s*[-*]?\s*\**\s*Decision recorded in commit\**\s*[:\-]\s*`?([0-9a-f]{7,40})`?')
        if ($draftCommit.Success -and $decisionCommit.Success -and $draftCommit.Groups[1].Value -eq $decisionCommit.Groups[1].Value) {
            $errors.Add('Human Decision "Decision recorded in commit" must differ from the "Design-analysis draft commit"; record the commit that contains the populated decision, not the draft.') | Out-Null
        }
    }

    # FR-026 (Amendment A2): lens-coverage enforcement. Each questionnaire-selected lens must carry a
    # non-placeholder "Addressed:" entry (anti-omission); grandfather-safe + LLM/network-free.
    $iterationDirectory = Split-Path -Parent $artifactPath
    foreach ($coverageError in @(Test-SpecrewDesignAnalysisLensCoverage -Content $content -IterationDirectory $iterationDirectory)) {
        $errors.Add($coverageError) | Out-Null
    }

    return [pscustomobject]@{
        Valid             = ($errors.Count -eq 0)
        ArtifactPath      = $artifactPath
        Errors            = @($errors)
        SelectedOption    = $selectedOption
        RecommendedOption = $recommendedOption
    }
}

function Invoke-SpecrewDesignAnalysisPlanBoundaryGate {
    param(
        [Parameter(Mandatory = $true)][string]$ProjectRoot,
        [AllowNull()][string]$FeatureRef,
        [AllowNull()][string]$IterationNumber
    )

    $feature = Normalize-SpecrewDesignAnalysisFeatureRef -FeatureRef $FeatureRef
    if ([string]::IsNullOrWhiteSpace($feature)) { return $null }

    $required = Test-SpecrewDesignAnalysisGateRequired -ProjectRoot $ProjectRoot -FeatureRef $feature -IterationNumber $IterationNumber
    if (-not $required) { return $null }

    $result = Test-SpecrewDesignAnalysisArtifact -ProjectRoot $ProjectRoot -FeatureRef $feature -IterationNumber $IterationNumber
    if (-not $result.Valid) {
        $messageLines = New-Object System.Collections.Generic.List[string]
        $messageLines.Add(("[design-analysis-gate] Plan boundary cannot advance for active substantive feature '{0}'." -f $feature)) | Out-Null
        $messageLines.Add(("Required artifact: {0}" -f $result.ArtifactPath)) | Out-Null
        foreach ($error in $result.Errors) {
            $messageLines.Add(("  - {0}" -f $error)) | Out-Null
        }
        throw ($messageLines -join [Environment]::NewLine)
    }

    return $result
}

$script:SpecrewDesignAnalysisPacketSections = @(
    'What I Just Did',
    'Why I Stopped',
    'What Needs Your Review',
    'What Happens Next',
    'Discussion Prompts',
    'What I Need From You'
)

function New-SpecrewDesignAnalysisGatePacket {
    # FR-004: render the design-analysis human gate packet from typed fields, so the
    # authoritative approval object is Specrew-rendered rather than free-form prose.
    # Scoped to the design-analysis gate only (FR-006) — not a general packet system.
    param(
        [Parameter(Mandatory = $true)][hashtable]$Fields
    )

    $feature = if ($Fields.ContainsKey('Feature')) { [string]$Fields['Feature'] } else { '<feature>' }
    $iteration = if ($Fields.ContainsKey('Iteration')) { [string]$Fields['Iteration'] } else { '001' }
    $verdict = if ($Fields.ContainsKey('Verdict')) { [string]$Fields['Verdict'] } else { 'approved for plan with Option <X>' }

    $lines = New-Object System.Collections.Generic.List[string]
    $lines.Add('---') | Out-Null
    $lines.Add('gate: design-analysis') | Out-Null
    $lines.Add(('feature: {0}' -f $feature)) | Out-Null
    $lines.Add(('iteration: "{0}"' -f $iteration)) | Out-Null
    $lines.Add('from_boundary: design-analysis') | Out-Null
    $lines.Add('to_boundary: plan') | Out-Null
    $lines.Add(('verdict_shape: "{0}"' -f $verdict)) | Out-Null
    $lines.Add('---') | Out-Null
    $lines.Add('') | Out-Null

    foreach ($section in $script:SpecrewDesignAnalysisPacketSections) {
        $key = $section -replace '[^A-Za-z]', ''
        $body = if ($Fields.ContainsKey($key)) { [string]$Fields[$key] } else { '<to be filled>' }
        $lines.Add(('## {0}' -f $section)) | Out-Null
        $lines.Add('') | Out-Null
        $lines.Add($body.Trim()) | Out-Null
        $lines.Add('') | Out-Null
    }

    return (($lines -join [Environment]::NewLine).TrimEnd() + [Environment]::NewLine)
}

function Test-SpecrewDesignAnalysisGatePacket {
    # FR-005: validate the rendered design-analysis gate packet — six human re-entry
    # sections present, the `approved for plan with Option <X>` verdict shape present,
    # and no bare artifact paths in prose (file:/// URLs and code spans are exempt).
    param(
        [Parameter(Mandatory = $true)][AllowNull()][string]$PacketText
    )

    $errors = New-Object System.Collections.Generic.List[string]

    if ([string]::IsNullOrWhiteSpace($PacketText)) {
        $errors.Add('Packet text is empty.') | Out-Null
        return [pscustomobject]@{ Valid = $false; Errors = @($errors) }
    }

    foreach ($section in $script:SpecrewDesignAnalysisPacketSections) {
        $pattern = '(?im)^#{1,3}\s*' + [regex]::Escape($section) + '\s*$'
        if ($PacketText -notmatch $pattern) {
            $errors.Add(("Packet is missing required section: {0}." -f $section)) | Out-Null
        }
    }

    if ($PacketText -notmatch '(?i)approved for plan with option\b') {
        $errors.Add('Packet must reference the verdict shape `approved for plan with Option <X>`.') | Out-Null
    }

    # Strip code blocks, inline code, and file:/// URLs, then flag any remaining bare
    # artifact-path reference in prose.
    $stripped = $PacketText
    $stripped = [regex]::Replace($stripped, '(?s)```.*?```', '')
    $stripped = [regex]::Replace($stripped, '`[^`]*`', '')
    $stripped = [regex]::Replace($stripped, '(?i)file:///\S+', '')
    $barePaths = [regex]::Matches($stripped, '(?<![\w./])(?:specs|\.specrew|\.squad|tests)[\\/]\S')
    if ($barePaths.Count -gt 0) {
        $errors.Add('Packet prose contains a bare artifact path; use a file:/// URL or a code span.') | Out-Null
    }

    return [pscustomobject]@{ Valid = ($errors.Count -eq 0); Errors = @($errors) }
}

function Get-SpecrewDesignAnalysisGatePacketPath {
    param(
        [Parameter(Mandatory = $true)][string]$ProjectRoot,
        [Parameter(Mandatory = $true)][string]$FeatureRef,
        [AllowNull()][string]$IterationNumber
    )

    $feature = Normalize-SpecrewDesignAnalysisFeatureRef -FeatureRef $FeatureRef
    $iteration = Normalize-SpecrewDesignAnalysisIterationNumber -IterationNumber $IterationNumber
    # FR-020 / FR-006: durable packet scoped to the design-analysis gate only.
    return Join-Path $ProjectRoot ("specs\{0}\gates\design-analysis-{1}.md" -f $feature, $iteration)
}

function Save-SpecrewDesignAnalysisGatePacket {
    # FR-020: persist the validated packet as a narrow durable 155-lite record under
    # specs/<feature>/gates/ for the design-analysis gate only. Validates before save.
    param(
        [Parameter(Mandatory = $true)][string]$ProjectRoot,
        [Parameter(Mandatory = $true)][string]$FeatureRef,
        [AllowNull()][string]$IterationNumber,
        [Parameter(Mandatory = $true)][string]$PacketText
    )

    $validation = Test-SpecrewDesignAnalysisGatePacket -PacketText $PacketText
    if (-not $validation.Valid) {
        $messageLines = New-Object System.Collections.Generic.List[string]
        $messageLines.Add('[design-analysis-gate-packet] Refusing to persist an invalid design-analysis gate packet.') | Out-Null
        foreach ($err in $validation.Errors) {
            $messageLines.Add(("  - {0}" -f $err)) | Out-Null
        }
        throw ($messageLines -join [Environment]::NewLine)
    }

    $packetPath = Get-SpecrewDesignAnalysisGatePacketPath -ProjectRoot $ProjectRoot -FeatureRef $FeatureRef -IterationNumber $IterationNumber
    $directory = Split-Path -Parent $packetPath
    if (-not [string]::IsNullOrWhiteSpace($directory) -and -not (Test-Path -LiteralPath $directory -PathType Container)) {
        $null = New-Item -ItemType Directory -Path $directory -Force
    }

    [System.IO.File]::WriteAllText($packetPath, ($PacketText.TrimEnd() + [Environment]::NewLine), [System.Text.UTF8Encoding]::new($false))
    return [pscustomobject]@{ Path = $packetPath; Valid = $true }
}

function Get-SpecrewDesignAnalysisSelectedOption {
    # FR-007: expose the human-selected option as authoritative plan input. Returns
    # the single selected option string, or $null when the artifact is missing/invalid.
    param(
        [Parameter(Mandatory = $true)][string]$ProjectRoot,
        [Parameter(Mandatory = $true)][string]$FeatureRef,
        [AllowNull()][string]$IterationNumber
    )

    $result = Test-SpecrewDesignAnalysisArtifact -ProjectRoot $ProjectRoot -FeatureRef $FeatureRef -IterationNumber $IterationNumber
    if (-not $result.Valid) { return $null }
    return $result.SelectedOption
}

function Get-SpecrewDesignAnalysisTemplatePath {
    # Resolve the versioned design-analysis template that the scaffold emits.
    # Reconciled with the validator contract (FR-001 / TG-007). Prefers the
    # repo/module source path; falls back to the deployed .specify mirror.
    $moduleRoot = Split-Path -Parent (Split-Path -Parent $PSScriptRoot)
    $candidates = @(
        (Join-Path $moduleRoot 'extensions\specrew-speckit\templates\design-analysis.template.md'),
        (Join-Path $moduleRoot '.specify\extensions\specrew-speckit\templates\design-analysis.template.md')
    )
    foreach ($candidate in $candidates) {
        if (Test-Path -LiteralPath $candidate -PathType Leaf) { return $candidate }
    }
    return $null
}

function New-SpecrewDesignAnalysisArtifact {
    # FR-001: scaffold a per-iteration design-analysis.md from the template if it
    # does not already exist. Never overwrites an existing decision record.
    param(
        [Parameter(Mandatory = $true)][string]$ProjectRoot,
        [Parameter(Mandatory = $true)][string]$FeatureRef,
        [AllowNull()][string]$IterationNumber
    )

    $feature = Normalize-SpecrewDesignAnalysisFeatureRef -FeatureRef $FeatureRef
    if ([string]::IsNullOrWhiteSpace($feature)) {
        throw 'New-SpecrewDesignAnalysisArtifact requires a non-empty feature ref.'
    }

    $artifactPath = Get-SpecrewDesignAnalysisArtifactPath -ProjectRoot $ProjectRoot -FeatureRef $feature -IterationNumber $IterationNumber
    if (Test-Path -LiteralPath $artifactPath -PathType Leaf) {
        return [pscustomobject]@{ Path = $artifactPath; Created = $false; Reason = 'exists' }
    }

    $templatePath = Get-SpecrewDesignAnalysisTemplatePath
    if ($null -eq $templatePath) {
        throw 'design-analysis.template.md not found under extensions/specrew-speckit/templates; cannot scaffold the design-analysis artifact.'
    }

    $directory = Split-Path -Parent $artifactPath
    if (-not [string]::IsNullOrWhiteSpace($directory) -and -not (Test-Path -LiteralPath $directory -PathType Container)) {
        $null = New-Item -ItemType Directory -Path $directory -Force
    }

    $template = Get-Content -LiteralPath $templatePath -Raw -Encoding UTF8
    [System.IO.File]::WriteAllText($artifactPath, $template, [System.Text.UTF8Encoding]::new($false))
    return [pscustomobject]@{ Path = $artifactPath; Created = $true; Reason = 'scaffolded-from-template' }
}

function Invoke-SpecrewDesignAnalysisPrePlanGate {
    # FR-002 / FR-003 / FR-021: callable pre-plan validator invoked BEFORE plan.md
    # is authored (in addition to the at-sync plan-boundary gate). Coordinator-prompt
    # enforcement (no host-native hooks) calls this; it fails closed when the active
    # substantive iteration's design-analysis artifact or human decision is invalid.
    param(
        [Parameter(Mandatory = $true)][string]$ProjectRoot,
        [AllowNull()][string]$FeatureRef,
        [AllowNull()][string]$IterationNumber
    )

    $feature = Normalize-SpecrewDesignAnalysisFeatureRef -FeatureRef $FeatureRef
    if ([string]::IsNullOrWhiteSpace($feature)) { return $null }

    $required = Test-SpecrewDesignAnalysisGateRequired -ProjectRoot $ProjectRoot -FeatureRef $feature -IterationNumber $IterationNumber
    if (-not $required) { return $null }

    $result = Test-SpecrewDesignAnalysisArtifact -ProjectRoot $ProjectRoot -FeatureRef $feature -IterationNumber $IterationNumber
    if (-not $result.Valid) {
        $messageLines = New-Object System.Collections.Generic.List[string]
        $messageLines.Add(("[design-analysis-pre-plan-gate] Do not author plan.md for active substantive feature '{0}' until design analysis is valid." -f $feature)) | Out-Null
        $messageLines.Add(("Required artifact: {0}" -f $result.ArtifactPath)) | Out-Null
        foreach ($err in $result.Errors) {
            $messageLines.Add(("  - {0}" -f $err)) | Out-Null
        }
        throw ($messageLines -join [Environment]::NewLine)
    }

    # FR-004/FR-005/FR-020 enforced flow (Fix 1/2, 2026-06-02 smoke): the durable
    # design-gate packet MUST exist and validate before plan.md is authored, so packet
    # persistence is a required step in the real flow, not an unused helper. The at-sync
    # plan-boundary gate stays the artifact/decision backstop if this call is bypassed.
    $packetPath = Get-SpecrewDesignAnalysisGatePacketPath -ProjectRoot $ProjectRoot -FeatureRef $feature -IterationNumber $IterationNumber
    if (-not (Test-Path -LiteralPath $packetPath -PathType Leaf)) {
        throw ("[design-analysis-pre-plan-gate] Do not author plan.md for active substantive feature '{0}': the durable design-gate packet is missing at {1}. Render, validate, and persist it (Save-SpecrewDesignAnalysisGatePacket) before plan.md." -f $feature, $packetPath)
    }
    $packetText = Get-Content -LiteralPath $packetPath -Raw -Encoding UTF8
    $packetCheck = Test-SpecrewDesignAnalysisGatePacket -PacketText $packetText
    if (-not $packetCheck.Valid) {
        $packetLines = New-Object System.Collections.Generic.List[string]
        $packetLines.Add(("[design-analysis-pre-plan-gate] Durable design-gate packet at {0} is invalid:" -f $packetPath)) | Out-Null
        foreach ($perr in $packetCheck.Errors) {
            $packetLines.Add(("  - {0}" -f $perr)) | Out-Null
        }
        throw ($packetLines -join [Environment]::NewLine)
    }

    return [pscustomobject]@{
        Valid          = $true
        ArtifactPath   = $result.ArtifactPath
        Errors         = @()
        SelectedOption = $result.SelectedOption
        PacketPath     = $packetPath
    }
}
