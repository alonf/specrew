[CmdletBinding()]
param()

# Registry <-> wrapper parity for the REAL repo (feature 140 / T006).
# Enforces generate-then-commit: every Specrew.psd1 alias has a committed bin/
# wrapper, bin/ has no extra wrappers, and the committed wrappers are byte-in-sync
# with the generator (-Check). This is the drift guard CI runs on command-surface
# changes (cascade: registry -> wrappers -> installer -> FileList -> docs).

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

function Write-Pass { param([string]$m) Write-Host "PASS: $m" -ForegroundColor Green }
function Write-Fail { param([string]$m) Write-Host "FAIL: $m" -ForegroundColor Red; throw $m }

$repoRoot = Split-Path -Parent (Split-Path -Parent $PSScriptRoot)
$generator = Join-Path $repoRoot 'scripts/internal/generate-shell-wrappers.ps1'
$binDir = Join-Path $repoRoot 'bin'
foreach ($p in @($generator, (Join-Path $repoRoot 'Specrew.psd1'))) {
    if (-not (Test-Path -LiteralPath $p)) { Write-Fail "required path not found: $p" }
}
if (-not (Test-Path -LiteralPath $binDir -PathType Container)) { Write-Fail "bin/ directory not found: $binDir" }

$registry = @((Import-PowerShellDataFile -LiteralPath (Join-Path $repoRoot 'Specrew.psd1')).AliasesToExport)
if ($registry.Count -eq 0) { Write-Fail 'Specrew.psd1 AliasesToExport is empty' }

$missing = @($registry | Where-Object { -not (Test-Path -LiteralPath (Join-Path $binDir $_) -PathType Leaf) })
if ($missing.Count -gt 0) { Write-Fail "registry aliases with no bin/ wrapper: $($missing -join ', ')" }
Write-Pass "every AliasesToExport alias has a committed bin/ wrapper ($($registry.Count))"

$extra = @(Get-ChildItem -LiteralPath $binDir -File | Where-Object { $_.Name -notin $registry } | ForEach-Object { $_.Name })
if ($extra.Count -gt 0) { Write-Fail "bin/ contains wrappers not in the registry: $($extra -join ', ')" }
Write-Pass 'bin/ contains no wrappers beyond the registry'

& pwsh -NoProfile -File $generator -Check *> $null
if ($LASTEXITCODE -ne 0) { Write-Fail 'committed bin/ wrappers drift from the generator; run: pwsh -File scripts/internal/generate-shell-wrappers.ps1' }
Write-Pass 'committed bin/ wrappers are byte-in-sync with the generator (-Check green)'

Write-Host ''
Write-Host 'All wrapper-registry-parity tests passed.' -ForegroundColor Green
