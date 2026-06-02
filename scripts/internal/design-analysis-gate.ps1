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

    $escaped = [regex]::Escape($OptionName)
    $regex = "(?ims)^#{2,6}\s*(?:Option\s+[A-Z]\s*[:\-]\s*)?$escaped\b.*?\r?\n(?<body>.*?)(?=^#{2,6}\s+(?:Option\s+[A-Z]\s*[:\-]\s*)?(?:Simplest|Reasonable|By-the-book)\b|\z)"
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

    $matches = [regex]::Matches($Text, '(?i)\b(Option\s+[A-Z]|Simplest|Reasonable|By-the-book)\b')
    $unique = New-Object System.Collections.Generic.List[string]
    foreach ($match in $matches) {
        $value = $match.Groups[1].Value.Trim()
        $normalized = if ($value -match '(?i)^option\s+([A-Z])$') {
            'Option ' + $Matches[1].ToUpperInvariant()
        } elseif ($value -match '(?i)^by-the-book$') {
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

        if ([string]::IsNullOrWhiteSpace($byTheBook) -and $alternatives.Body -notmatch '(?is)by-the-book.*(?:not\s+meaningfully\s+distinct|not\s+distinct|not-applicable|not\s+applicable|deferred)') {
            $errors.Add('Alternatives must include By-the-book when distinct, or state why By-the-book is not meaningfully distinct.') | Out-Null
        }
    }

    $recommendedOption = Get-SpecrewDesignAnalysisNamedOption -Text $recommendation.Body
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

    $selectedOption = Get-SpecrewDesignAnalysisNamedOption -Text $humanDecision.Body
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
