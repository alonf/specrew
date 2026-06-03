[CmdletBinding()]
param()

# Packaging parity for the Unix wrappers (feature 140 / T009, FR-010).
# BIDIRECTIONAL FileList check (the FileList directional-blind-spot lesson): every
# bin/ wrapper on disk must be declared in Specrew.psd1 FileList, AND every FileList
# bin/ entry must exist on disk. Also asserts the new generator + installer scripts
# are in FileList so they ship in the published artifact.

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

function Write-Pass { param([string]$m) Write-Host "PASS: $m" -ForegroundColor Green }
function Write-Fail { param([string]$m) Write-Host "FAIL: $m" -ForegroundColor Red; throw $m }

$repoRoot = Split-Path -Parent (Split-Path -Parent $PSScriptRoot)
$manifestPath = Join-Path $repoRoot 'Specrew.psd1'
$binDir = Join-Path $repoRoot 'bin'

# Import also validates the manifest still parses after the FileList edits.
$psd = Import-PowerShellDataFile -LiteralPath $manifestPath
if (-not $psd.ContainsKey('FileList')) { Write-Fail 'Specrew.psd1 has no FileList' }
$fileList = @($psd.FileList)
Write-Pass "Specrew.psd1 imports and declares a FileList ($($fileList.Count) entries)"

# Normalize FileList separators for comparison
$fileListNorm = @($fileList | ForEach-Object { $_.Replace('\', '/') })

# Direction 1: every bin/ file on disk is declared in FileList (catches a new wrapper
# that was generated but never added to FileList — the v0.27.3-class omission).
$binOnDisk = @(Get-ChildItem -LiteralPath $binDir -File | ForEach-Object { "bin/$($_.Name)" })
$undeclared = @($binOnDisk | Where-Object { $_ -notin $fileListNorm })
if ($undeclared.Count -gt 0) { Write-Fail "bin/ wrappers missing from Specrew.psd1 FileList: $($undeclared -join ', ')" }
Write-Pass "every bin/ wrapper on disk is declared in FileList ($($binOnDisk.Count))"

# Direction 2: every FileList bin/ entry exists on disk (catches a stale/renamed entry).
$binInFileList = @($fileListNorm | Where-Object { $_ -like 'bin/*' })
$stale = @($binInFileList | Where-Object { -not (Test-Path -LiteralPath (Join-Path $repoRoot $_) -PathType Leaf) })
if ($stale.Count -gt 0) { Write-Fail "FileList bin/ entries with no file on disk: $($stale -join ', ')" }
Write-Pass "every FileList bin/ entry exists on disk ($($binInFileList.Count))"

# The user-facing bootstrap (install.sh) + the generator + installer scripts must ship too.
foreach ($required in @('install.sh', 'scripts/internal/generate-shell-wrappers.ps1', 'scripts/specrew-install-shell-wrappers.ps1')) {
    if ($required -notin $fileListNorm) { Write-Fail "required runtime file not in FileList: $required" }
    if (-not (Test-Path -LiteralPath (Join-Path $repoRoot $required) -PathType Leaf)) { Write-Fail "required runtime file not on disk: $required" }
}
Write-Pass 'install.sh + generator + installer scripts are declared in FileList and present on disk'

Write-Host ''
Write-Host 'All wrapper-filelist-parity tests passed.' -ForegroundColor Green
