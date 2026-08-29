#!/usr/bin/env pwsh
[CmdletBinding()]
param(
    [switch] $Json,
    [switch] $AllowExistingBranch,
    [string] $ShortName,
    [Parameter()]
    [long] $Number = 0,
    [switch] $Timestamp,
    [switch] $Help,
    [Parameter(Position = 0, ValueFromRemainingArguments = $true)]
    [string[]] $FeatureDescription
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

function Resolve-ProjectRoot {
    param([string] $StartPath)

    $candidate = [IO.Path]::GetFullPath($StartPath)
    while (-not [string]::IsNullOrWhiteSpace($candidate)) {
        if (Test-Path -LiteralPath (Join-Path $candidate '.specrew\config.yml') -PathType Leaf) { return $candidate }
        $parent = Split-Path -Parent $candidate
        if ([string]::IsNullOrWhiteSpace($parent) -or $parent -eq $candidate) { break }
        $candidate = $parent
    }
    throw 'Run the governed feature scaffold from inside a Specrew project.'
}

function Invoke-FeatureScaffold {
    param(
        [string] $ScriptPath,
        [string] $WorkingDirectory,
        [string[]] $Arguments
    )

    Push-Location $WorkingDirectory
    try {
        $lines = @(& pwsh -NoProfile -File $ScriptPath @Arguments 2>&1)
        $exitCode = $LASTEXITCODE
    }
    finally { Pop-Location }

    if ($exitCode -ne 0) {
        $detail = (@($lines | ForEach-Object { [string]$_ }) -join [Environment]::NewLine).Trim()
        if ([string]::IsNullOrWhiteSpace($detail)) { $detail = "exit code $exitCode" }
        throw "Feature scaffold failed: $detail"
    }
    return @($lines | ForEach-Object { [string]$_ })
}

function Get-ScaffoldRecord {
    param([string[]] $OutputLines)

    foreach ($line in $OutputLines) {
        try {
            $record = $line | ConvertFrom-Json -ErrorAction Stop
            if ($record.PSObject.Properties['BRANCH_NAME'] -and -not [string]::IsNullOrWhiteSpace([string]$record.BRANCH_NAME)) {
                return $record
            }
        }
        catch { $null = $_ }
    }
    $featureRef = $null
    foreach ($line in $OutputLines) {
        if ($line -match '^BRANCH_NAME:\s*(?<feature>\S+)\s*$') { $featureRef = [string]$Matches.feature; break }
    }
    if (-not [string]::IsNullOrWhiteSpace($featureRef)) {
        return [pscustomobject]@{ BRANCH_NAME = $featureRef; FEATURE_NUM = ($featureRef -split '-', 2)[0]; HAS_GIT = $true }
    }
    throw 'Feature scaffold did not report BRANCH_NAME; workshop controller was not initialized.'
}

$projectRoot = Resolve-ProjectRoot -StartPath (Get-Location).Path
$scaffoldScript = Join-Path $projectRoot '.specify\scripts\powershell\create-new-feature.ps1'
if (-not (Test-Path -LiteralPath $scaffoldScript -PathType Leaf)) {
    throw "Spec Kit feature scaffold is missing: '$scaffoldScript'."
}

if ($Help) {
    & pwsh -NoProfile -File $scaffoldScript -Help
    exit $LASTEXITCODE
}
if ($null -eq $FeatureDescription -or @($FeatureDescription).Count -eq 0) {
    throw 'FeatureDescription is required.'
}

$scaffoldArgs = New-Object System.Collections.Generic.List[string]
$scaffoldArgs.Add('-Json') | Out-Null
if ($AllowExistingBranch) { $scaffoldArgs.Add('-AllowExistingBranch') | Out-Null }
if (-not [string]::IsNullOrWhiteSpace($ShortName)) { $scaffoldArgs.Add('-ShortName') | Out-Null; $scaffoldArgs.Add($ShortName) | Out-Null }
if ($Number -gt 0) { $scaffoldArgs.Add('-Number') | Out-Null; $scaffoldArgs.Add([string]$Number) | Out-Null }
if ($Timestamp) { $scaffoldArgs.Add('-Timestamp') | Out-Null }
foreach ($part in @($FeatureDescription)) { $scaffoldArgs.Add([string]$part) | Out-Null }

$scaffoldOutput = Invoke-FeatureScaffold -ScriptPath $scaffoldScript -WorkingDirectory $projectRoot -Arguments $scaffoldArgs.ToArray()
$scaffoldRecord = Get-ScaffoldRecord -OutputLines $scaffoldOutput
$featureRef = [string]$scaffoldRecord.BRANCH_NAME

$initializer = Join-Path $projectRoot '.specify\extensions\specrew-speckit\scripts\initialize-workshop-controller-state.ps1'
if (-not (Test-Path -LiteralPath $initializer -PathType Leaf)) {
    throw "Workshop controller initializer is missing after feature scaffold: '$initializer'."
}
& pwsh -NoProfile -File $initializer -ProjectRoot $projectRoot -FeatureRef $featureRef
if ($LASTEXITCODE -ne 0) { throw "Workshop controller initialization failed for '$featureRef'." }

$specFile = Join-Path (Join-Path (Join-Path $projectRoot 'specs') $featureRef) 'spec.md'

# FR-029 (iteration 002, T020): the upstream scaffold copies the spec TEMPLATE here - a file full of
# `[Brief Title]` and `FR-001: System MUST [specific capability]` - and this script then prints SPEC_FILE as a
# headline output, pointing the agent at it BEFORE lens 1 has run. CLAUDE.md states the rule that contradicts:
# "A spec written before the workshop skips the part that decides what the spec should say."
#
# Measured in one walk: the template sat in the tree through the entire workshop; writing into it mid-workshop
# is the outside work that triggered the lens re-ask; and at the end the agent did not edit it - it DELETED it
# (151 lines) and wrote a fresh 441-line spec. Delete-and-recreate is the measurement: the scaffolded file
# carried nothing into what replaced it.
#
# So the placeholder is replaced by a STUB that says what it is. The upstream scaffold is untouched (this
# wrapper owns the replacement), SPEC_FILE keeps its contract, and the file it names now redirects instead of
# inviting. The sentinel is what the specify gate reads.
$specStub = @(
    '<!-- specrew:spec-not-yet-authored -->',
    ('# Feature Specification: {0}' -f $featureRef),
    '',
    '**Status**: not yet authored',
    '',
    'This specification has not been written yet, and that is deliberate.',
    '',
    'Specrew writes the specification AFTER the design workshop, because the workshop is what decides what',
    'the specification should say - who this is for, what hurts today, the smallest version worth building,',
    'the stack, and the constraints. A specification drafted before those answers exist records the',
    'assumptions nobody has examined yet.',
    '',
    '## What happens next',
    '',
    '1. The design workshop runs, one topic at a time, and records each agreement.',
    '2. The specification is authored from those agreements, into this file.',
    '3. The specify boundary is where you approve what it says.',
    '',
    'Nothing is missing and nothing has failed. Until step 2 runs, this file stays as it is - do not write',
    'requirements into it, and do not delete it.'
) -join [Environment]::NewLine
if (Test-Path -LiteralPath $specFile -PathType Leaf) {
    $existingSpec = Get-Content -LiteralPath $specFile -Raw -Encoding UTF8
    # Only ever replace the UPSTREAM TEMPLATE. An authored spec (a re-run over an existing feature) is never
    # touched: this must not become a way to lose a written specification.
    if ($existingSpec -match '\[Brief Title\]' -or $existingSpec -match 'FR-001: System MUST' -or $existingSpec -match '\[FEATURE NAME\]') {
        [System.IO.File]::WriteAllText($specFile, ($specStub + [Environment]::NewLine), [System.Text.UTF8Encoding]::new($false))
    }
}
else {
    [System.IO.File]::WriteAllText($specFile, ($specStub + [Environment]::NewLine), [System.Text.UTF8Encoding]::new($false))
}

if ($Json) {
    [pscustomobject]@{
        BRANCH_NAME = $featureRef
        SPEC_FILE = $specFile
        FEATURE_NUM = if ($scaffoldRecord.PSObject.Properties['FEATURE_NUM']) { [string]$scaffoldRecord.FEATURE_NUM } else { ($featureRef -split '-', 2)[0] }
        HAS_GIT = if ($scaffoldRecord.PSObject.Properties['HAS_GIT']) { [bool]$scaffoldRecord.HAS_GIT } else { $true }
        WORKSHOP_STATE = (Join-Path (Split-Path -Parent $specFile) 'lens-applicability.json')
    } | ConvertTo-Json -Compress
}
else {
    Write-Output "BRANCH_NAME: $featureRef"
    Write-Output "SPEC_FILE: $specFile"
    Write-Output "WORKSHOP_STATE: $(Join-Path (Split-Path -Parent $specFile) 'lens-applicability.json')"
}
