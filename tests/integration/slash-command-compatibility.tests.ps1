[CmdletBinding()]
param()

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

function Write-Pass {
    param([string]$Message)
    Write-Host "PASS: $Message" -ForegroundColor Green
}

function Write-Fail {
    param([string]$Message)
    Write-Host "FAIL: $Message" -ForegroundColor Red
}

function Assert-True {
    param(
        [Parameter(Mandatory = $true)][bool]$Condition,
        [Parameter(Mandatory = $true)][string]$Message
    )
    if (-not $Condition) {
        Write-Fail $Message
        exit 1
    }
    Write-Pass $Message
}

function Assert-Contains {
    param(
        [Parameter(Mandatory = $true)][string]$Text,
        [Parameter(Mandatory = $true)][string]$Substring,
        [Parameter(Mandatory = $true)][string]$Message
    )
    if ($Text -notlike "*$Substring*") {
        Write-Fail "$Message (expected '$Substring' in text)"
        exit 1
    }
    Write-Pass $Message
}

function Find-StaleCompatibilityMentions {
    param(
        [Parameter(Mandatory = $true)]
        [string]$RepoRoot,

        [switch]$ForceSelectString
    )

    $targets = @(
        'scripts\internal\version-check.ps1',
        'scripts\specrew.ps1',
        'scripts\specrew-version.ps1',
        'scripts\specrew-update.ps1',
        'extensions\specrew-speckit\squad-templates\coordinator\specrew-governance.md',
        'extensions\specrew-speckit\squad-templates\skills\specrew-version\SKILL.md',
        '.agents\skills\specrew-version\SKILL.md',
        '.claude\skills\specrew-version\SKILL.md',
        '.github\skills\specrew-version\SKILL.md',
        '.github\agents\squad.agent.md'
    )
    $patterns = @(
        '0\.24\.0',
        'minimum compatibility is Specrew',
        'pre-v0\.24\.0',
        'Slash-cmd minimum',
        'slash-command minimum'
    )

    $resolvedTargets = @(
        foreach ($target in $targets) {
            $path = Join-Path $RepoRoot $target
            if (Test-Path -LiteralPath $path -PathType Leaf) {
                $path
            }
        }
    )

    if (-not $ForceSelectString -and (Get-Command -Name 'rg' -ErrorAction SilentlyContinue)) {
        $rgPattern = ($patterns -join '|')
        $rgOutput = @(& rg -n --pcre2 $rgPattern @resolvedTargets 2>&1)
        if ($LASTEXITCODE -eq 0) {
            return @($rgOutput | ForEach-Object { [string]$_ })
        }
        if ($LASTEXITCODE -ne 1) {
            throw ("rg active-message scan failed with exit code {0}: {1}" -f $LASTEXITCODE, ($rgOutput -join [Environment]::NewLine))
        }

        return @()
    }

    $selectStringPattern = ($patterns -join '|')
    return @(
        Select-String -LiteralPath $resolvedTargets -Pattern $selectStringPattern -AllMatches |
            ForEach-Object { '{0}:{1}:{2}' -f $_.Path, $_.LineNumber, $_.Line.Trim() }
    )
}

$repoRoot = (Resolve-Path (Join-Path $PSScriptRoot '..\..')).Path
$specrew = Join-Path $repoRoot 'scripts\specrew.ps1'

Write-Host ''
Write-Host '=== Slash-Command Compatibility Integration Tests ===' -ForegroundColor Cyan
Write-Host "Repo root: $repoRoot"
Write-Host ''

Write-Host '--- Test 1: version-check.ps1 no longer exports a fixed slash-command minimum ---'
$versionCheckPath = Join-Path $repoRoot 'scripts\internal\version-check.ps1'
$versionCheckContent = Get-Content -LiteralPath $versionCheckPath -Raw
Assert-True -Condition ($versionCheckContent -notmatch 'Get-SpecrewSlashCommandMinVersion') -Message 'Fixed slash-command minimum helper removed'
Assert-True -Condition ($versionCheckContent -notmatch '0\.24\.0') -Message 'version-check.ps1 no longer embeds stale slash-command baseline'

Write-Host ''
Write-Host '--- Test 2: specrew-version.ps1 reports current module/project compatibility ---'
$versionScriptPath = Join-Path $repoRoot 'scripts\specrew-version.ps1'
$versionScriptContent = Get-Content -LiteralPath $versionScriptPath -Raw
Assert-True -Condition ($versionScriptContent -notmatch '0\.24\.0|Slash-cmd minimum|slash-command minimum') -Message 'specrew-version.ps1 does not surface stale baseline wording'
Assert-Contains -Text $versionScriptContent -Substring 'SPECREW_MODULE_PATH' -Message 'specrew-version.ps1 reports dev-tree remediation'
Assert-Contains -Text $versionScriptContent -Substring '/specrew-help' -Message 'specrew-version.ps1 help guidance references /specrew-help'
Assert-Contains -Text $versionScriptContent -Substring 'compatible' -Message 'specrew-version.ps1 emits a compatibility verdict'

Write-Host ''
Write-Host '--- Test 3: active generated/routine surfaces do not expose stale 0.24.0 baseline messaging ---'
$activeMentions = @(Find-StaleCompatibilityMentions -RepoRoot $repoRoot)
Assert-True -Condition ($activeMentions.Count -eq 0) -Message 'Active surfaces are free of stale baseline wording via default scanner'
$fallbackMentions = @(Find-StaleCompatibilityMentions -RepoRoot $repoRoot -ForceSelectString)
Assert-True -Condition ($fallbackMentions.Count -eq 0) -Message 'Active surfaces are free of stale baseline wording via Select-String fallback'

Write-Host ''
Write-Host '--- Test 4: specrew dispatcher advertises the hyphenated slash-command catalog ---'
$specrewContent = Get-Content -LiteralPath $specrew -Raw
Assert-Contains -Text $specrewContent -Substring '/specrew-where' -Message 'specrew.ps1 help includes /specrew-where'
Assert-Contains -Text $specrewContent -Substring '/specrew-help' -Message 'specrew.ps1 help includes /specrew-help'
Assert-True -Condition ($specrewContent -notmatch '/specrew\.') -Message 'specrew.ps1 no longer publishes dot-form slash commands'

Write-Host ''
Write-Host '--- Test 5: project-setup gate still fires for where on an uninitialized project ---'
$scratchDir = Join-Path $repoRoot '.scratch\compat-test-uninit'
try {
    if (Test-Path -LiteralPath $scratchDir) { Remove-Item -LiteralPath $scratchDir -Recurse -Force }
    $null = New-Item -ItemType Directory -Path $scratchDir -Force
    $output = & pwsh -NoProfile -ExecutionPolicy Bypass -File $specrew 'where' '--project-path' $scratchDir 2>&1 | Out-String
    $exitCode = $LASTEXITCODE
    Assert-True -Condition ($exitCode -ne 0) -Message 'specrew where on an uninitialized project exits non-zero'
    Assert-Contains -Text $output -Substring 'WARNING:' -Message 'specrew where emits a reviewer-visible WARNING'
    Assert-Contains -Text $output -Substring 'specrew init' -Message 'specrew where suggests specrew init remediation'
}
finally {
    if (Test-Path -LiteralPath $scratchDir) { Remove-Item -LiteralPath $scratchDir -Recurse -Force }
}

Write-Host ''
Write-Host '--- Test 6: project-setup gate still fires for review on an uninitialized project ---'
$scratchDir = Join-Path $repoRoot '.scratch\compat-test-review'
try {
    if (Test-Path -LiteralPath $scratchDir) { Remove-Item -LiteralPath $scratchDir -Recurse -Force }
    $null = New-Item -ItemType Directory -Path $scratchDir -Force
    $output = & pwsh -NoProfile -ExecutionPolicy Bypass -File $specrew 'review' '--project-path' $scratchDir 2>&1 | Out-String
    $exitCode = $LASTEXITCODE
    Assert-True -Condition ($exitCode -ne 0) -Message 'specrew review on an uninitialized project exits non-zero'
    Assert-Contains -Text $output -Substring 'specrew init' -Message 'specrew review suggests specrew init remediation'
}
finally {
    if (Test-Path -LiteralPath $scratchDir) { Remove-Item -LiteralPath $scratchDir -Recurse -Force }
}

Write-Host ''
Write-Host '--- Test 7: specrew version remains project-setup tolerant ---'
$scratchDir = Join-Path $repoRoot '.scratch\compat-test-version'
try {
    if (Test-Path -LiteralPath $scratchDir) { Remove-Item -LiteralPath $scratchDir -Recurse -Force }
    $null = New-Item -ItemType Directory -Path $scratchDir -Force
    & pwsh -NoProfile -ExecutionPolicy Bypass -File $specrew 'version' '--project-path' $scratchDir | Out-Null
    Assert-True -Condition ($LASTEXITCODE -eq 0) -Message 'specrew version runs without project setup'
}
finally {
    if (Test-Path -LiteralPath $scratchDir) { Remove-Item -LiteralPath $scratchDir -Recurse -Force }
}

Write-Host ''
Write-Host '=== All compatibility integration tests passed ===' -ForegroundColor Green
Write-Host ''
