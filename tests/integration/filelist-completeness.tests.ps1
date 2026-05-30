[CmdletBinding()]
param()

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

# Bidirectional FileList completeness guard.
#
# Motivation: v0.28.0-beta1 shipped a broken package — scripts/internal/user-profile.ps1
# existed in source but was omitted from the Specrew.psd1 FileList, so PSGallery never
# packaged it and `specrew start` crashed on first run. The pre-publish Docker harness
# missed it because its FileList check is DIRECTIONAL (every *declared* entry exists on
# disk) and never checked the inverse (every *deployable source file* is declared).
#
# This test closes that blind spot at PR time (fast, deterministic, no Docker): every
# deployable source file under the roots below MUST be declared in FileList. An undeclared
# file is silently dropped from the published package -> runtime crash.

function Write-Pass { param([string]$m) Write-Host "PASS: $m" -ForegroundColor Green }
function Write-Fail { param([string]$m) Write-Host "FAIL: $m" -ForegroundColor Red }

$repoRoot = (Resolve-Path (Join-Path -Path $PSScriptRoot -ChildPath '..\..')).Path
$manifestPath = Join-Path -Path $repoRoot -ChildPath 'Specrew.psd1'

# Deployable source roots whose files must ALL be declared in FileList. These are runtime
# PowerShell that the module dot-sources / requires at run time, where an omission is a
# hard crash. Extend this list as other deployable subdirs are brought under the guard.
$deployableGlobs = @(
    @{ Root = 'scripts'; Filter = '*.ps1' }
)

function Get-UndeclaredDeployableFiles {
    param(
        [string[]]$FileList,
        [string]$RootPath,
        [array]$DeployableGlobs
    )
    $declared = [System.Collections.Generic.HashSet[string]]::new([System.StringComparer]::OrdinalIgnoreCase)
    foreach ($entry in $FileList) { [void]$declared.Add(([string]$entry -replace '\\', '/')) }

    $undeclared = New-Object System.Collections.Generic.List[string]
    foreach ($glob in $DeployableGlobs) {
        $globRoot = Join-Path -Path $RootPath -ChildPath $glob.Root
        if (-not (Test-Path -LiteralPath $globRoot)) { continue }
        foreach ($file in (Get-ChildItem -LiteralPath $globRoot -Recurse -File -Filter $glob.Filter)) {
            $rel = ($file.FullName.Substring($RootPath.Length).TrimStart('\', '/') -replace '\\', '/')
            if (-not $declared.Contains($rel)) { $null = $undeclared.Add($rel) }
        }
    }
    return $undeclared
}

$manifest = Import-PowerShellDataFile -Path $manifestPath
$fileList = @($manifest.FileList | ForEach-Object { [string]$_ })

# --- Test 1: real repo — every deployable source file is declared in FileList. ---
$undeclared = @(Get-UndeclaredDeployableFiles -FileList $fileList -RootPath $repoRoot -DeployableGlobs $deployableGlobs)
if ($undeclared.Count -gt 0) {
    Write-Fail "Specrew.psd1 FileList is missing $($undeclared.Count) deployable source file(s); they would be dropped from the PSGallery package (runtime crash):"
    foreach ($u in $undeclared) { Write-Host "  - $u" -ForegroundColor Red }
    Write-Host "Add each to the FileList array in Specrew.psd1 (alphabetical within its directory)." -ForegroundColor Yellow
    exit 1
}
$rootsLabel = ($deployableGlobs | ForEach-Object { "$($_.Root)/**/$($_.Filter)" }) -join ', '
Write-Pass "Every deployable source file under [$rootsLabel] is declared in FileList ($($fileList.Count) FileList entries)"

# --- Test 2: regression — the F-049 iter-003 scenario (a new deployable file NOT added to
#     FileList) MUST be detected by the bidirectional check. ---
$scratch = Join-Path -Path $repoRoot -ChildPath (".scratch\filelist-completeness-" + [guid]::NewGuid().ToString('N'))
try {
    $null = New-Item -ItemType Directory -Path (Join-Path -Path $scratch -ChildPath 'scripts/internal') -Force
    $newFileRel = 'scripts/internal/new-iter003-helper.ps1'
    Set-Content -LiteralPath (Join-Path -Path $scratch -ChildPath $newFileRel) -Value '# simulated new helper, not in FileList' -Encoding UTF8

    # A FileList that declares NOTHING under scripts/ — the new helper must surface.
    $detected = @(Get-UndeclaredDeployableFiles -FileList @('Specrew.psm1', 'Specrew.psd1') -RootPath $scratch -DeployableGlobs $deployableGlobs)
    if ($detected -notcontains $newFileRel) {
        Write-Fail "Regression: a new undeclared scripts/internal helper was NOT flagged by the bidirectional check (the v0.28.0-beta1 blind spot would recur)."
        exit 1
    }
    Write-Pass "Regression (F-049 iter-003 scenario): an undeclared scripts/internal helper is correctly flagged"
}
finally {
    if (Test-Path -LiteralPath $scratch) { Remove-Item -LiteralPath $scratch -Recurse -Force -ErrorAction SilentlyContinue }
}

Write-Pass "FileList completeness: bidirectional (source -> declared) guard passes"
exit 0
