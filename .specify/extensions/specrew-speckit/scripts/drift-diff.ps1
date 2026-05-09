[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)]
    [string]$SpecPath,

    [Parameter(Mandatory = $true)]
    [string]$TaskId,

    [Parameter(Mandatory = $true)]
    [string]$ImplementationPath
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

$sharedGovernancePath = Join-Path $PSScriptRoot 'shared-governance.ps1'
if (-not (Test-Path -LiteralPath $sharedGovernancePath -PathType Leaf)) {
    throw "Missing shared governance helper '$sharedGovernancePath'."
}
. $sharedGovernancePath

function Get-MarkdownContent {
    param([string]$Path)

    return @(Get-Content -LiteralPath $Path -Encoding UTF8)
}

function Get-RequirementSummaryMap {
    param([string[]]$Lines)

    $requirements = [ordered]@{}
    foreach ($line in $Lines) {
        if ($line -match '^\s*-\s+\*\*(FR-\d+)\*\*:\s+(.+?)\s*$') {
            $requirements[$Matches[1]] = $Matches[2].Trim()
        }
    }

    return $requirements
}

function Get-ImplementationEvidence {
    param([string]$Path)

    $resolvedPath = Resolve-ProjectPath -Path $Path
    if (-not (Test-Path -LiteralPath $resolvedPath)) {
        throw "Implementation path '$resolvedPath' does not exist."
    }

    if (Test-Path -LiteralPath $resolvedPath -PathType Leaf) {
        return [pscustomobject]@{
            ResolvedPath = $resolvedPath
            EvidenceText = [System.IO.File]::ReadAllText($resolvedPath, [System.Text.UTF8Encoding]::new($false))
        }
    }

    $files = @(Get-ChildItem -LiteralPath $resolvedPath -Recurse -File | Sort-Object FullName)
    if ($files.Count -eq 0) {
        throw "Implementation path '$resolvedPath' does not contain any files."
    }

    $sections = foreach ($file in $files) {
        $relativePath = $file.FullName.Substring($resolvedPath.TrimEnd('\').Length).TrimStart('\')
        @(
            ('# File: {0}' -f $relativePath),
            [System.IO.File]::ReadAllText($file.FullName, [System.Text.UTF8Encoding]::new($false))
        ) -join [Environment]::NewLine
    }

    return [pscustomobject]@{
        ResolvedPath = $resolvedPath
        EvidenceText = $sections -join ([Environment]::NewLine + [Environment]::NewLine)
    }
}

function Get-RequirementRefFromEvidence {
    param([string]$EvidenceText)

    $explicitMatch = [regex]::Match($EvidenceText, '(?im)^\s*RequirementRef\s*:\s*(FR-\d+)\s*$')
    if ($explicitMatch.Success) {
        return $explicitMatch.Groups[1].Value
    }

    $inlineMatch = [regex]::Match($EvidenceText, '\b(FR-\d+)\b')
    if ($inlineMatch.Success) {
        return $inlineMatch.Groups[1].Value
    }

    return $null
}

function Get-RequirementConstraints {
    param([string]$RequirementText)

    $requiredTokens = [regex]::Matches($RequirementText, '(?i)must\s+(?:include|contain)\s+`([^`]+)`') |
        ForEach-Object { $_.Groups[1].Value.Trim() } |
        Where-Object { -not [string]::IsNullOrWhiteSpace($_) }

    $forbiddenTokens = [regex]::Matches($RequirementText, '(?i)must\s+not\s+(?:include|contain)\s+`([^`]+)`') |
        ForEach-Object { $_.Groups[1].Value.Trim() } |
        Where-Object { -not [string]::IsNullOrWhiteSpace($_) }

    return [pscustomobject]@{
        RequiredTokens  = @($requiredTokens)
        ForbiddenTokens = @($forbiddenTokens)
    }
}

function Test-EvidenceContainsToken {
    param(
        [string]$EvidenceText,
        [string]$Token
    )

    $escapedToken = [regex]::Escape($Token)
    $pattern = if ($Token -match '^[A-Za-z0-9_-]+$') {
        '(?<![A-Za-z0-9_-]){0}(?![A-Za-z0-9_-])' -f $escapedToken
    }
    else {
        $escapedToken
    }

    $regex = [regex]::new(
        $pattern,
        [System.Text.RegularExpressions.RegexOptions]::IgnoreCase
    )

    return $regex.IsMatch($EvidenceText)
}

$resolvedSpecPath = Resolve-ProjectPath -Path $SpecPath
if (-not (Test-Path -LiteralPath $resolvedSpecPath -PathType Leaf)) {
    throw "Spec file '$resolvedSpecPath' does not exist."
}

$specLines = @(Get-MarkdownContent -Path $resolvedSpecPath)
$requirements = Get-RequirementSummaryMap -Lines $specLines
if ($requirements.Count -eq 0) {
    throw "Spec file '$resolvedSpecPath' does not contain any FR requirement summaries."
}

$implementationEvidence = Get-ImplementationEvidence -Path $ImplementationPath
$requirementRef = Get-RequirementRefFromEvidence -EvidenceText $implementationEvidence.EvidenceText
if ([string]::IsNullOrWhiteSpace($requirementRef)) {
    throw "Implementation evidence '$($implementationEvidence.ResolvedPath)' does not declare a RequirementRef."
}

if (-not $requirements.Contains($requirementRef)) {
    throw "Requirement '$requirementRef' was not found in '$resolvedSpecPath'."
}

$requirementText = [string]$requirements[$requirementRef]
$constraints = Get-RequirementConstraints -RequirementText $requirementText
$timestamp = (Get-Date).ToUniversalTime().ToString('yyyy-MM-ddTHH:mm:ssZ')
$driftEvents = New-Object System.Collections.Generic.List[object]
$descriptions = New-Object System.Collections.Generic.List[string]
$evidenceSummaryParts = New-Object System.Collections.Generic.List[string]
$eventCounter = 1

foreach ($token in $constraints.RequiredTokens) {
    if (Test-EvidenceContainsToken -EvidenceText $implementationEvidence.EvidenceText -Token $token) {
        $null = $evidenceSummaryParts.Add(('contains required token `{0}`' -f $token))
        continue
    }

    $description = ('Delivered output is missing required token `{0}`.' -f $token)
    $null = $descriptions.Add($description)
    $driftEvents.Add([pscustomobject]@{
            type                 = 'incomplete'
            drift_id             = ('DR-{0:000}' -f $eventCounter)
            detected_at          = $timestamp
            task_ref             = $TaskId
            requirement_ref      = $requirementRef
            severity             = 'moderate'
            description          = $description
            requirement_citation = $requirementText
            resolution           = 'implementation-reverted'
            resolution_detail    = ('Update the delivered output so it includes required token `{0}`.' -f $token)
            log_snippet          = @(
                ('- **DR-{0:000}**: Detected {1} during {2}' -f $eventCounter, $timestamp.Substring(0, 10), $TaskId),
                ('  - **Requirement**: {0}' -f $requirementRef),
                ('  - **Deviation**: {0}' -f $description),
                '  - **Resolution**: implementation-reverted',
                ('  - **Detail**: Update the delivered output so it includes required token `{0}`.' -f $token)
            ) -join [Environment]::NewLine
        })
    $eventCounter++
}

foreach ($token in $constraints.ForbiddenTokens) {
    if (-not (Test-EvidenceContainsToken -EvidenceText $implementationEvidence.EvidenceText -Token $token)) {
        $null = $evidenceSummaryParts.Add(('does not contain forbidden token `{0}`' -f $token))
        continue
    }

    $description = ('Delivered output contains forbidden token `{0}`.' -f $token)
    $null = $descriptions.Add($description)
    $driftEvents.Add([pscustomobject]@{
            type                 = 'violation'
            drift_id             = ('DR-{0:000}' -f $eventCounter)
            detected_at          = $timestamp
            task_ref             = $TaskId
            requirement_ref      = $requirementRef
            severity             = 'critical'
            description          = $description
            requirement_citation = $requirementText
            resolution           = 'implementation-reverted'
            resolution_detail    = ('Remove forbidden token `{0}` from the delivered output.' -f $token)
            log_snippet          = @(
                ('- **DR-{0:000}**: Detected {1} during {2}' -f $eventCounter, $timestamp.Substring(0, 10), $TaskId),
                ('  - **Requirement**: {0}' -f $requirementRef),
                ('  - **Deviation**: {0}' -f $description),
                '  - **Resolution**: implementation-reverted',
                ('  - **Detail**: Remove forbidden token `{0}` from the delivered output.' -f $token)
            ) -join [Environment]::NewLine
        })
    $eventCounter++
}

if ($constraints.RequiredTokens.Count -eq 0 -and $constraints.ForbiddenTokens.Count -eq 0) {
    $description = 'Requirement text does not contain explicit `MUST include/contain` or `MUST NOT include/contain` constraints that drift-diff.ps1 can evaluate.'
    $driftEvents.Add([pscustomobject]@{
            type                 = 'human-decision'
            drift_id             = 'DR-001'
            detected_at          = $timestamp
            task_ref             = $TaskId
            requirement_ref      = $requirementRef
            severity             = 'moderate'
            description          = $description
            requirement_citation = $requirementText
            resolution           = 'human-decision'
            resolution_detail    = 'Refine the requirement or evaluate this task manually with the Spec Steward.'
            log_snippet          = @(
                ('- **DR-001**: Detected {0} during {1}' -f $timestamp.Substring(0, 10), $TaskId),
                ('  - **Requirement**: {0}' -f $requirementRef),
                ('  - **Deviation**: {0}' -f $description),
                '  - **Resolution**: human-decision',
                '  - **Detail**: Refine the requirement or evaluate this task manually with the Spec Steward.'
            ) -join [Environment]::NewLine
        })
}

$result = if ($driftEvents.Count -gt 0) {
    [pscustomobject]@{
        verdict               = 'DRIFT'
        task_ref              = $TaskId
        requirement_ref       = $requirementRef
        requirement_text      = $requirementText
        evidence_summary      = if ($descriptions.Count -gt 0) { $descriptions -join ' ' } else { 'Drift detected.' }
        drift_events          = $driftEvents
        drift_log_update_note = 'Replace the zero-drift summary in drift-log.md with the real event count and resolution status before review accepts the iteration.'
    }
}
else {
    [pscustomobject]@{
        verdict               = 'PASS'
        task_ref              = $TaskId
        requirement_ref       = $requirementRef
        requirement_text      = $requirementText
        evidence_summary      = if ($evidenceSummaryParts.Count -gt 0) { $evidenceSummaryParts -join '; ' } else { 'Evidence matches the requirement.' }
        drift_events          = @()
        drift_log_update_note = 'No drift-log update is required.'
    }
}

$result | ConvertTo-Json -Depth 6
exit 0
