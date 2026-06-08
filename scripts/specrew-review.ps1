[CmdletBinding()]
param(
    [string]$ProjectPath = '.',
    [string]$FeatureId,
    [string]$IterationNumber,
    [switch]$Quiet,
    [switch]$Json,
    [switch]$Open,
    [switch]$Help,
    [Parameter(ValueFromRemainingArguments = $true)]
    [string[]]$CliArgs
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

$sharedGovernancePath = Join-Path (Split-Path -Parent $PSScriptRoot) 'extensions\specrew-speckit\scripts\shared-governance.ps1'
if (-not (Test-Path -LiteralPath $sharedGovernancePath -PathType Leaf)) {
    throw "Missing shared governance helper '$sharedGovernancePath'."
}
. $sharedGovernancePath

$boundaryStateHelperPath = Join-Path $PSScriptRoot 'internal\sync-boundary-state.ps1'
if (-not (Test-Path -LiteralPath $boundaryStateHelperPath -PathType Leaf)) {
    throw "Missing boundary-state helper '$boundaryStateHelperPath'."
}
. $boundaryStateHelperPath

function Show-Usage {
    @'
specrew review - replay the persisted reviewer closeout packet

Usage:
  specrew review [<iteration>] [--project-path <path>] [--feature <id>] [--quiet | --json] [--open]

Options:
  --project-path <path>  Target Specrew project (default: current directory)
  --feature <id>         Restrict lookup to one feature directory under specs\
  --iteration <NNN>      Replay a specific iteration directory
  --quiet                Emit only the stable machine-parseable digest line
  --json                 Emit JSON summary instead of the visual reviewer summary
  --open                 Open reviewer-index.md and review-diagrams.md when present
  --help                 Show this help message
'@ | Write-Host
}

function Convert-UnixStyleArguments {
    param(
        [string]$ProjectPath,
        [string]$FeatureId,
        [string]$IterationNumber,
        [bool]$Quiet,
        [bool]$Json,
        [bool]$Open,
        [bool]$Help,
        [string[]]$CliArgs
    )

    $result = [ordered]@{
        ProjectPath     = $ProjectPath
        FeatureId       = $FeatureId
        IterationNumber = $IterationNumber
        Quiet           = $Quiet
        Json            = $Json
        Open            = $Open
        Help            = $Help
    }

    $CliArgs = @($CliArgs | Where-Object { -not [string]::IsNullOrWhiteSpace($_) })
    for ($index = 0; $index -lt $CliArgs.Count; $index++) {
        $argument = $CliArgs[$index]
        switch -Regex ($argument) {
            '^--project-path(?:=(.+))?$' {
                if ($Matches[1]) {
                    $result.ProjectPath = $Matches[1]
                }
                else {
                    $index++
                    if ($index -ge $CliArgs.Count) { throw '--project-path requires a value.' }
                    $result.ProjectPath = $CliArgs[$index]
                }
            }
            '^--feature(?:=(.+))?$' {
                if ($Matches[1]) {
                    $result.FeatureId = $Matches[1]
                }
                else {
                    $index++
                    if ($index -ge $CliArgs.Count) { throw '--feature requires a value.' }
                    $result.FeatureId = $CliArgs[$index]
                }
            }
            '^--iteration(?:=(.+))?$' {
                if ($Matches[1]) {
                    $result.IterationNumber = $Matches[1]
                }
                else {
                    $index++
                    if ($index -ge $CliArgs.Count) { throw '--iteration requires a value.' }
                    $result.IterationNumber = $CliArgs[$index]
                }
            }
            '^--quiet$' { $result.Quiet = $true }
            '^--json$' { $result.Json = $true }
            '^--open$' { $result.Open = $true }
            '^(?:-h|--help)$' { $result.Help = $true }
            '^\d{3,}$' {
                if ([string]::IsNullOrWhiteSpace($result.IterationNumber)) {
                    $result.IterationNumber = $argument
                }
                else {
                    throw ("Unknown argument for specrew review: {0}" -f $argument)
                }
            }
            default { throw ("Unknown argument for specrew review: {0}" -f $argument) }
        }
    }

    return [pscustomobject]$result
}

function Get-MetadataValue {
    param(
        [string]$Path,
        [string]$Label
    )

    $pattern = '(?m)^\*\*' + [regex]::Escape($Label) + '\*\*:\s*(?<value>.+?)\s*$'
    $match = [regex]::Match((Get-Content -LiteralPath $Path -Raw -Encoding UTF8), $pattern)
    if ($match.Success) {
        return $match.Groups['value'].Value.Trim()
    }

    return $null
}

function Get-MarkdownContent {
    param([string]$Path)

    return @(Get-Content -LiteralPath $Path -Encoding UTF8)
}

function Get-MarkdownSectionLines {
    param(
        [AllowEmptyString()]
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

function Resolve-IterationDirectory {
    param(
        [string]$ProjectRoot,
        [AllowNull()][string]$FeatureId,
        [AllowNull()][string]$IterationNumber
    )

    $specsRoot = Join-Path $ProjectRoot 'specs'
    if (-not (Test-Path -LiteralPath $specsRoot -PathType Container)) {
        throw "Project does not contain a specs directory: $specsRoot"
    }

    $featureDirectories = @(
        if ($FeatureId) {
            Get-ChildItem -LiteralPath $specsRoot -Directory | Where-Object { $_.Name -eq $FeatureId }
        }
        else {
            Get-ChildItem -LiteralPath $specsRoot -Directory
        }
    )

    if ($featureDirectories.Count -eq 0) {
        throw 'No matching feature directories were found.'
    }

    $candidateIterations = New-Object System.Collections.Generic.List[object]
    foreach ($featureDirectory in $featureDirectories) {
        $iterationsRoot = Join-Path $featureDirectory.FullName 'iterations'
        if (-not (Test-Path -LiteralPath $iterationsRoot -PathType Container)) {
            continue
        }

        foreach ($iterationDirectory in @(Get-ChildItem -LiteralPath $iterationsRoot -Directory)) {
            if ($IterationNumber -and $iterationDirectory.Name -ne $IterationNumber) {
                continue
            }

            $reviewerIndexPath = Join-Path $iterationDirectory.FullName 'reviewer-index.md'
            $reviewPath = Join-Path $iterationDirectory.FullName 'review.md'
            if (-not (Test-Path -LiteralPath $reviewerIndexPath -PathType Leaf) -or -not (Test-Path -LiteralPath $reviewPath -PathType Leaf)) {
                continue
            }

            $reviewed = Get-MetadataValue -Path $reviewPath -Label 'Reviewed'
            $candidateIterations.Add([pscustomobject]@{
                    Feature   = $featureDirectory.Name
                    Iteration = $iterationDirectory.Name
                    Path      = $iterationDirectory.FullName
                    Reviewed  = $reviewed
                })
        }
    }

    if ($candidateIterations.Count -eq 0) {
        throw 'No completed iteration with reviewer artifacts was found.'
    }

    return @(
        $candidateIterations |
            Sort-Object -Property @(
                @{ Expression = { if ([string]::IsNullOrWhiteSpace($_.Reviewed)) { '0000-00-00' } else { $_.Reviewed } }; Descending = $true },
                @{ Expression = { $_.Iteration }; Descending = $true }
            ) |
            Select-Object -First 1
    )[0]
}

function Get-RelativePath {
    param(
        [Parameter(Mandatory = $true)]
        [string]$FromDirectory,

        [Parameter(Mandatory = $true)]
        [string]$ToPath
    )

    # System.IO.Path.GetRelativePath is cross-platform safe and uses the platform's
    # native separator. The previous [System.Uri] MakeRelativeUri approach failed on
    # Linux because bare absolute paths like "/home/user/foo" are not auto-recognized
    # as absolute URIs without a "file://" scheme.
    $fromFull = [System.IO.Path]::GetFullPath($FromDirectory)
    $toFull = [System.IO.Path]::GetFullPath($ToPath)
    return [System.IO.Path]::GetRelativePath($fromFull, $toFull)
}

function Try-OpenPath {
    param([string]$Path)

    try {
        Start-Process -FilePath $Path | Out-Null
        return $true
    }
    catch {
        return $false
    }
}

function Get-ReviewBoundarySyncWarning {
    param(
        [Parameter(Mandatory = $true)][string]$ProjectRoot,
        [Parameter(Mandatory = $true)][string]$ReviewPath
    )

    $warnings = [System.Collections.Generic.List[string]]::new()
    $reviewVerdict = Get-MetadataValue -Path $ReviewPath -Label 'Overall Verdict'
    $latestBoundary = Get-LatestSpecrewBoundarySyncState -ProjectRoot $ProjectRoot
    if ($reviewVerdict -match '^(?i)accepted$') {
        if ($null -eq $latestBoundary -or [string]$latestBoundary.boundary_type -notin @('review-signoff', 'retro', 'iteration-closeout', 'feature-closeout')) {
            $warnings.Add('WARN: Accepted review artifacts exist, but lifecycle state is not synced to review-signoff or a later boundary.') | Out-Null
        }
    }
    $requireStateFile = $null -eq $latestBoundary -or [string]$latestBoundary.boundary_type -notin @('retro', 'iteration-closeout', 'feature-closeout')

    $iterationDirectory = Split-Path -Parent $ReviewPath
    $iterationNumber = Split-Path -Leaf $iterationDirectory
    $featurePath = Split-Path -Parent (Split-Path -Parent $iterationDirectory)
    foreach ($issue in @(Get-SpecrewIterationStateTruthIssues -ProjectRoot $ProjectRoot -FeaturePath $featurePath -IterationNumber $iterationNumber -RequireStateFile:$requireStateFile)) {
        $warnings.Add(("WARN: {0}" -f $issue)) | Out-Null
    }

    if ($warnings.Count -eq 0) {
        return $null
    }

    return ($warnings.ToArray() -join [Environment]::NewLine)
}

$parsedArgs = Convert-UnixStyleArguments `
    -ProjectPath $ProjectPath `
    -FeatureId $FeatureId `
    -IterationNumber $IterationNumber `
    -Quiet $Quiet.IsPresent `
    -Json $Json.IsPresent `
    -Open $Open.IsPresent `
    -Help $Help.IsPresent `
    -CliArgs $CliArgs

$ProjectPath = $parsedArgs.ProjectPath
$FeatureId = $parsedArgs.FeatureId
$IterationNumber = $parsedArgs.IterationNumber
$Quiet = [bool]$parsedArgs.Quiet
$Json = [bool]$parsedArgs.Json
$Open = [bool]$parsedArgs.Open
$Help = [bool]$parsedArgs.Help

if ($Help) {
    Show-Usage
    exit 0
}

if ($Quiet -and $Json) {
    Write-Error 'Choose either --quiet or --json, not both.'
    exit 1
}

$resolvedProjectPath = Resolve-ProjectPath -Path $ProjectPath
if (-not (Test-Path -LiteralPath $resolvedProjectPath -PathType Container)) {
    Write-Error ("Project path does not exist: {0}" -f $resolvedProjectPath)
    exit 1
}

try {
    $selection = Resolve-IterationDirectory -ProjectRoot $resolvedProjectPath -FeatureId $FeatureId -IterationNumber $IterationNumber
}
catch {
    Write-Error $_.Exception.Message
    exit 1
}

$iterationDirectory = $selection.Path
$reviewPath = Join-Path $iterationDirectory 'review.md'
$reviewerIndexPath = Join-Path $iterationDirectory 'reviewer-index.md'
$reviewDiagramsPath = Join-Path $iterationDirectory 'review-diagrams.md'
$indexLines = @(Get-MarkdownContent -Path $reviewerIndexPath)
$summaryLines = @(Get-MarkdownSectionLines -Lines $indexLines -Heading 'Summary' | Where-Object { $_.Trim().StartsWith('- ') } | ForEach-Object { $_.Trim().Substring(2) })
$digestLines = @(Get-MarkdownSectionLines -Lines $indexLines -Heading 'Replay Digest' | Where-Object { -not [string]::IsNullOrWhiteSpace($_) })
$digestLine = if ($digestLines.Count -gt 0) {
    ($digestLines[0] -replace '^`|`$', '').Trim()
}
else {
    ''
}

$summary = [pscustomobject]@{
    feature          = $selection.Feature
    iteration        = $selection.Iteration
    reviewed         = Get-MetadataValue -Path $reviewPath -Label 'Reviewed'
    overall_verdict  = Get-MetadataValue -Path $reviewPath -Label 'Overall Verdict'
    reviewer_index   = Get-RelativePath -FromDirectory $resolvedProjectPath -ToPath $reviewerIndexPath
    review_diagrams  = if (Test-Path -LiteralPath $reviewDiagramsPath -PathType Leaf) { Get-RelativePath -FromDirectory $resolvedProjectPath -ToPath $reviewDiagramsPath } else { $null }
    summary_lines    = $summaryLines
    digest           = $digestLine
    cap_active       = if ($digestLine -match 'cap=active') { $true } else { $false }
    cap_chain        = if ($digestLine -match 'cap_chain=(\d+)/(\d+)') { "$($Matches[1])/$($Matches[2])" } else { $null }
    boundary_sync_warning = Get-ReviewBoundarySyncWarning -ProjectRoot $resolvedProjectPath -ReviewPath $reviewPath
}

if ($Json) {
    $summary | ConvertTo-Json -Depth 4
}
elseif ($Quiet) {
    if ([string]::IsNullOrWhiteSpace($digestLine)) {
        Write-Error 'reviewer-index.md does not contain a replay digest.'
        exit 1
    }
    Write-Host $digestLine
}
else {
    $border = ('=' * 60)
    Write-Host $border -ForegroundColor Green
    Write-Host 'SPECREW REVIEWER SUMMARY' -ForegroundColor Green
    Write-Host $border -ForegroundColor Green
    foreach ($line in $summaryLines) {
        Write-Host $line
    }
    if (-not [string]::IsNullOrWhiteSpace($digestLine)) {
        Write-Host ''
        Write-Host $digestLine
    }
    if (-not [string]::IsNullOrWhiteSpace([string]$summary.boundary_sync_warning)) {
        Write-Output $summary.boundary_sync_warning
    }
}

if ($Open) {
    $openedAny = $false
    foreach ($path in @($reviewerIndexPath, $reviewDiagramsPath)) {
        if (-not (Test-Path -LiteralPath $path -PathType Leaf)) {
            continue
        }
        if (Try-OpenPath -Path $path) {
            $openedAny = $true
        }
        else {
            Write-Host ("Open manually: {0}" -f $path)
        }
    }

    if (-not $openedAny -and -not (Test-Path -LiteralPath $reviewerIndexPath -PathType Leaf)) {
        Write-Host ("Open manually: {0}" -f $reviewerIndexPath)
        if (Test-Path -LiteralPath $reviewDiagramsPath -PathType Leaf) {
            Write-Host ("Open manually: {0}" -f $reviewDiagramsPath)
        }
    }
}

exit 0
