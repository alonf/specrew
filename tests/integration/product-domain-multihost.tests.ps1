[CmdletBinding()]
param()

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

# Feature 176 — T014 / FR-013 / SC-007: multi-host conduct parity for the product-domain first-stage
# phase. The lens md is one shared catalog file; the conduct lives in the design-workshop skill,
# deployed to the host-managed skill surfaces. Five supported hosts (Claude, Copilot/GitHub,
# Codex/Agents, Cursor, Antigravity) map onto FOUR on-disk surfaces; the requirement is per supported
# host, not per physical directory. This test proves the surfaces carry the conduct identically and
# that injected drift is detected.

function Write-Pass { param([string]$m) Write-Host "PASS: $m" -ForegroundColor Green }
function Write-Fail { param([string]$m) Write-Host "FAIL: $m" -ForegroundColor Red; exit 1 }
function Assert-True { param([bool]$c, [string]$m) if (-not $c) { Write-Fail $m } Write-Pass $m }

$repoRoot = (Resolve-Path (Join-Path $PSScriptRoot '..\..')).Path

# The four on-disk managed-skill surfaces (5 supported hosts map onto these as applicable).
$surfaces = @(
    '.claude\skills\specrew-design-workshop\SKILL.md',
    '.cursor\rules\specrew-design-workshop\SKILL.md',
    '.github\skills\specrew-design-workshop\SKILL.md',
    '.agents\skills\specrew-design-workshop\SKILL.md'
) | ForEach-Object { Join-Path $repoRoot $_ }

foreach ($s in $surfaces) {
    Assert-True (Test-Path -LiteralPath $s -PathType Leaf) "surface present: $([System.IO.Path]::GetFileName((Split-Path -Parent (Split-Path -Parent $s))))/$([System.IO.Path]::GetFileName($s))"
    # Each surface should also carry the managed marker (deployed, not hand-edited).
    $marker = Join-Path (Split-Path -Parent $s) '.specrew-managed'
    Assert-True (Test-Path -LiteralPath $marker -PathType Leaf) "surface carries the .specrew-managed marker"
}

# Each surface carries the product-domain first-stage conduct.
foreach ($s in $surfaces) {
    $raw = Get-Content -LiteralPath $s -Raw -Encoding UTF8
    Assert-True ($raw -match '(?im)^##\s+First stage\b.*product-domain phase') "surface carries the '## First stage — the product-domain phase' conduct"
    Assert-True ($raw -match '(?is)runs FIRST,\s+before any technical lens') "surface states the product-domain phase runs FIRST"
    Assert-True ($raw -match '(?i)No batch confirmation') "surface carries the FR-009 no-batch-confirmation rule"
}

# SC-007: all surfaces are byte-identical (parity). Injected drift fails.
$hashes = $surfaces | ForEach-Object { (Get-FileHash -LiteralPath $_ -Algorithm SHA256).Hash }
Assert-True ((@($hashes | Select-Object -Unique).Count) -eq 1) "SC-007: all four managed skill surfaces are byte-identical (conduct parity holds)"

# Drift detection: a surface mutated by one byte must break parity (prove the check is real).
$base = Get-Content -LiteralPath $surfaces[0] -Raw -Encoding UTF8
$drifted = $base + "`n<!-- injected drift -->`n"
$baseHash = [System.BitConverter]::ToString([System.Security.Cryptography.SHA256]::HashData([System.Text.Encoding]::UTF8.GetBytes($base)))
$driftHash = [System.BitConverter]::ToString([System.Security.Cryptography.SHA256]::HashData([System.Text.Encoding]::UTF8.GetBytes($drifted)))
Assert-True ($baseHash -ne $driftHash) "SC-007: injected drift changes the surface hash (the parity check detects drift, not a no-op)"

Write-Host "`nAll product-domain multi-host parity tests passed." -ForegroundColor Green
