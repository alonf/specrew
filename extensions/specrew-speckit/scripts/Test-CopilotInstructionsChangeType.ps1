[CmdletBinding()]
param(
    [AllowNull()]
    [Alias('BeforePath')]
    [string]$ClassifierBeforePath,

    [AllowNull()]
    [Alias('AfterPath')]
    [string]$ClassifierAfterPath,

    [AllowNull()]
    [Alias('ProjectPath')]
    [string]$ClassifierProjectPath,

    [AllowNull()]
    [Alias('BaselineCommitHash')]
    [string]$ClassifierBaselineCommitHash,

    [Alias('TargetPath')]
    [string]$ClassifierTargetPath = '.github/copilot-instructions.md',

    [switch]$AsJson
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

$sharedGovernancePath = Join-Path $PSScriptRoot 'shared-governance.ps1'
if (-not (Test-Path -LiteralPath $sharedGovernancePath -PathType Leaf)) {
    throw "Missing shared governance helper '$sharedGovernancePath'."
}
. $sharedGovernancePath

function Get-CopilotInstructionsDocumentParts {
    param(
        [AllowNull()]
        [string]$Content
    )

    $normalizedContent = if ($null -eq $Content) { '' } else { $Content -replace "`r`n", "`n" }
    $lines = @($normalizedContent -split "`n")
    $lineCount = if ($lines.Count -eq 1 -and $lines[0] -eq '') { 0 } else { $lines.Count }

    $timestampLines = New-Object System.Collections.Generic.List[string]
    $preambleLines = New-Object System.Collections.Generic.List[string]
    $sections = [ordered]@{}
    $currentHeading = $null
    $currentLines = New-Object System.Collections.Generic.List[string]
    $inFrontmatter = $false
    $frontmatterClosed = $false

    for ($index = 0; $index -lt $lineCount; $index++) {
        $line = [string]$lines[$index]

        if ($index -eq 0 -and $line.Trim() -eq '---') {
            $inFrontmatter = $true
            continue
        }

        if ($inFrontmatter) {
            if ($line.Trim() -eq '---') {
                $inFrontmatter = $false
                $frontmatterClosed = $true
                continue
            }

            if ($line -match '^\s*last_updated\s*:') {
                $timestampLines.Add($line.Trim()) | Out-Null
            }
            else {
                $preambleLines.Add($line) | Out-Null
            }
            continue
        }

        if ($line -match '^##\s+') {
            if ($null -ne $currentHeading) {
                $sections[$currentHeading] = ($currentLines.ToArray() -join "`n").Trim()
            }

            $currentHeading = $line.Trim()
            $currentLines = New-Object System.Collections.Generic.List[string]
            continue
        }

        if ($null -eq $currentHeading) {
            if ($frontmatterClosed -or -not [string]::IsNullOrWhiteSpace($line)) {
                $preambleLines.Add($line) | Out-Null
            }
            continue
        }

        $currentLines.Add($line) | Out-Null
    }

    if ($null -ne $currentHeading) {
        $sections[$currentHeading] = ($currentLines.ToArray() -join "`n").Trim()
    }

    return [pscustomobject]@{
        Timestamp = ($timestampLines.ToArray() -join "`n").Trim()
        Preamble  = ($preambleLines.ToArray() -join "`n").Trim()
        Sections  = [pscustomobject]$sections
    }
}

function Test-CopilotInstructionsChangeType {
    [CmdletBinding(DefaultParameterSetName = 'Content')]
    param(
        [Parameter(ParameterSetName = 'Content', Mandatory = $true)]
        [AllowNull()]
        [string]$BeforeContent,

        [Parameter(ParameterSetName = 'Content', Mandatory = $true)]
        [AllowNull()]
        [string]$AfterContent,

        [Parameter(ParameterSetName = 'Paths', Mandatory = $true)]
        [string]$BeforePath,

        [Parameter(ParameterSetName = 'Paths', Mandatory = $true)]
        [string]$AfterPath,

        [Parameter(ParameterSetName = 'Repository', Mandatory = $true)]
        [string]$ProjectPath,

        [Parameter(ParameterSetName = 'Repository')]
        [AllowNull()]
        [string]$BaselineCommitHash,

        [Parameter(ParameterSetName = 'Repository')]
        [string]$TargetPath = '.github/copilot-instructions.md'
    )

    if ($PSCmdlet.ParameterSetName -eq 'Paths') {
        $BeforeContent = if (Test-Path -LiteralPath $BeforePath -PathType Leaf) { Get-Content -LiteralPath $BeforePath -Raw -Encoding UTF8 } else { '' }
        $AfterContent = if (Test-Path -LiteralPath $AfterPath -PathType Leaf) { Get-Content -LiteralPath $AfterPath -Raw -Encoding UTF8 } else { '' }
    }
    elseif ($PSCmdlet.ParameterSetName -eq 'Repository') {
        $resolvedProjectPath = Resolve-ProjectPath -Path $ProjectPath
        $resolvedTargetPath = $TargetPath -replace '/', '\'
        $gitTargetPath = $TargetPath -replace '\\', '/'
        $afterPath = Join-Path $resolvedProjectPath $resolvedTargetPath
        $AfterContent = if (Test-Path -LiteralPath $afterPath -PathType Leaf) { Get-Content -LiteralPath $afterPath -Raw -Encoding UTF8 } else { '' }

        if ([string]::IsNullOrWhiteSpace($BaselineCommitHash)) {
            $BeforeContent = $AfterContent
        }
        else {
            $beforeOutput = @(& git -C $resolvedProjectPath show "$BaselineCommitHash`:$gitTargetPath" 2>$null)
            $BeforeContent = if ($LASTEXITCODE -eq 0) {
                ($beforeOutput -join [Environment]::NewLine)
            }
            else {
                ''
            }
        }
    }

    $beforeParts = Get-CopilotInstructionsDocumentParts -Content $BeforeContent
    $afterParts = Get-CopilotInstructionsDocumentParts -Content $AfterContent

    $bookkeepingSections = @('timestamp', '## Active Technologies', '## Recent Changes')
    $changedSections = New-Object System.Collections.Generic.List[string]
    $behaviorSections = New-Object System.Collections.Generic.List[string]

    if ($beforeParts.Timestamp -cne $afterParts.Timestamp) {
        $changedSections.Add('timestamp') | Out-Null
    }

    if ($beforeParts.Preamble -cne $afterParts.Preamble) {
        $changedSections.Add('preamble') | Out-Null
        $behaviorSections.Add('preamble') | Out-Null
    }

    $beforeSectionNames = @($beforeParts.Sections.PSObject.Properties | ForEach-Object { $_.Name })
    $afterSectionNames = @($afterParts.Sections.PSObject.Properties | ForEach-Object { $_.Name })
    $sectionNames = @(
        $beforeSectionNames +
        $afterSectionNames
    ) | Sort-Object -Unique

    foreach ($sectionName in $sectionNames) {
        $beforeProperty = $beforeParts.Sections.PSObject.Properties[$sectionName]
        $afterProperty = $afterParts.Sections.PSObject.Properties[$sectionName]
        $beforeSection = if ($null -ne $beforeProperty) { [string]$beforeProperty.Value } else { '' }
        $afterSection = if ($null -ne $afterProperty) { [string]$afterProperty.Value } else { '' }
        if ($beforeSection -ceq $afterSection) {
            continue
        }

        $changedSections.Add($sectionName) | Out-Null
        if ($sectionName -notin @('## Active Technologies', '## Recent Changes')) {
            $behaviorSections.Add($sectionName) | Out-Null
        }
    }

    $classification = if ($behaviorSections.Count -gt 0) { 'behavior' } else { 'bookkeeping' }

    return [pscustomobject]@{
        Classification     = $classification
        ChangedSections    = $changedSections.ToArray()
        BookkeepingSections = $bookkeepingSections
        BehaviorSections   = $behaviorSections.ToArray()
        RequiresRestart    = $classification -eq 'behavior'
    }
}

if ($MyInvocation.InvocationName -ne '.') {
    $result = if (-not [string]::IsNullOrWhiteSpace($ClassifierProjectPath)) {
        Test-CopilotInstructionsChangeType -ProjectPath $ClassifierProjectPath -BaselineCommitHash $ClassifierBaselineCommitHash -TargetPath $ClassifierTargetPath
    }
    elseif (-not [string]::IsNullOrWhiteSpace($ClassifierBeforePath) -or -not [string]::IsNullOrWhiteSpace($ClassifierAfterPath)) {
        if ([string]::IsNullOrWhiteSpace($ClassifierBeforePath) -or [string]::IsNullOrWhiteSpace($ClassifierAfterPath)) {
            throw 'BeforePath and AfterPath must both be provided when classifying explicit files.'
        }

        Test-CopilotInstructionsChangeType -BeforePath $ClassifierBeforePath -AfterPath $ClassifierAfterPath
    }
    else {
        throw 'Provide either ProjectPath or both BeforePath and AfterPath.'
    }

    if ($AsJson) {
        $result | ConvertTo-Json -Depth 5
    }
    else {
        $result
    }
}
