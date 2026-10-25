# Iteration 002, round-2 follow-up (DRIFT-199-I002-024): a fix that never reaches a project is not shipped.
#
# THE PACKAGE IS THE FileList. `New-ReleaseStageRoot` (scripts/internal/module-packaging.ps1:245) stages
# exactly the manifest's FileList entries and nothing else, so a machinery file absent from it never reaches
# the installed module, and therefore never reaches any downstream project - no matter how many mirrors it
# sits in, how many parity checks it passes, or how thoroughly its mutation tests are proved.
#
# Measured: this batch added exactly TWO machinery files and BOTH were absent from the FileList.
#   - extensions/specrew-speckit/scripts/confirm-workshop-lens.ps1  (T027/FR-027, the governed lens writer)
#   - scripts/internal/constrained-yaml.ps1                          (FR-026, the shared constrained reader)
# Both existed in both mirrors, both passed parity, both passed their mutation tests, and neither was in
# the installed module or in HelloWinUIReactive. Two of the ten tag-blocking items shipped nothing.
#
# WHY THIS GUARD COMPUTES RATHER THAN LISTS. DRIFT-199-I002-011's rule: never enumerate a subject set by
# hand when something already computes it. The FileList is itself a hand-enumerated set, which is the
# defect; a guard that hand-enumerated the files to check would repeat it one layer up. So this walks the
# directories the FileList already covers and asserts that nothing of the same kind sits beside a listed
# file unlisted.
#
# Mutations that turn this file red: remove either entry from Specrew.psd1's FileList; add a new script
# beside a listed one without listing it.
Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'
$repoRoot = (Resolve-Path (Join-Path $PSScriptRoot '..\..')).Path
$script:failCount = 0
function Write-Pass { param([string]$Message) Write-Host "PASS: $Message" -ForegroundColor Green }
function Write-Fail { param([string]$Message) Write-Host "FAIL: $Message" -ForegroundColor Red; $script:failCount++ }
function Assert-True { param([bool]$Condition, [string]$Message) if ($Condition) { Write-Pass $Message } else { Write-Fail $Message } }

$manifestPath = Join-Path $repoRoot 'Specrew.psd1'
$manifest = Import-PowerShellDataFile -Path $manifestPath
$listed = [System.Collections.Generic.HashSet[string]]::new([System.StringComparer]::OrdinalIgnoreCase)
foreach ($entry in @($manifest.FileList)) {
    if (-not [string]::IsNullOrWhiteSpace($entry)) { [void]$listed.Add(((([string]$entry) -replace '\\', '/'))) }
}

Write-Host 'Case 1: the manifest lists the files this batch added - the instance that started this'
foreach ($required in @(
        'extensions/specrew-speckit/scripts/confirm-workshop-lens.ps1',
        'scripts/internal/constrained-yaml.ps1')) {
    Assert-True ($listed.Contains($required)) ("the package ships '$required' - absent from FileList it reaches no project, whatever its tests say")
}

Write-Host 'Case 2: nothing of the same kind sits beside a listed file, unlisted (the CLASS, computed)'
# For every directory the FileList already covers, take the extensions it ships from that directory and
# assert every same-kind file on disk is listed. This is the check that would have caught both instances.
$byDirectory = @{}
foreach ($entry in $listed) {
    $dir = [System.IO.Path]::GetDirectoryName($entry) -replace '\\', '/'
    if ([string]::IsNullOrWhiteSpace($dir)) { continue }
    $ext = [System.IO.Path]::GetExtension($entry).ToLowerInvariant()
    if (-not $byDirectory.ContainsKey($dir)) { $byDirectory[$dir] = [System.Collections.Generic.HashSet[string]]::new([System.StringComparer]::OrdinalIgnoreCase) }
    [void]$byDirectory[$dir].Add($ext)
}

# `docs/` is SELECTIVELY packaged by design - consumer-facing guides ship, release notes and internal
# methodology do not - so it is not a completeness domain and is excluded deliberately rather than by
# accident. Every other covered directory ships everything of its kind.
$selective = @('docs', 'docs/methodology', 'docs/operations')
$omissions = New-Object System.Collections.Generic.List[string]
foreach ($dir in @($byDirectory.Keys | Sort-Object)) {
    if ($dir -in $selective) { continue }
    $full = Join-Path $repoRoot ($dir -replace '/', [IO.Path]::DirectorySeparatorChar)
    if (-not (Test-Path -LiteralPath $full -PathType Container)) { continue }
    foreach ($file in @(Get-ChildItem -LiteralPath $full -File -ErrorAction SilentlyContinue)) {
        $ext = $file.Extension.ToLowerInvariant()
        if (-not $byDirectory[$dir].Contains($ext)) { continue }
        $relative = ($dir + '/' + $file.Name)
        if (-not $listed.Contains($relative)) { $omissions.Add($relative) | Out-Null }
    }
}
Assert-True ($omissions.Count -eq 0) ("no shippable file sits beside a listed sibling while absent from the FileList (found: " + (@($omissions) -join ', ') + ")")

Write-Host 'Case 3: the packager really does stage only the FileList - the premise this guard rests on'
$packaging = Get-Content -LiteralPath (Join-Path $repoRoot 'scripts/internal/module-packaging.ps1') -Raw -Encoding UTF8
Assert-True ($packaging -match 'foreach \(\$relativePath in @\(\$manifest\.FileList\)\)') 'New-ReleaseStageRoot stages exactly the FileList, so absence from it is absence from the package'

if ($script:failCount -gt 0) { throw ("package-filelist-completeness: {0} assertion(s) failed" -f $script:failCount) }
Write-Host 'package-filelist-completeness: all assertions passed' -ForegroundColor Green
