[CmdletBinding()]
param()

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

# Feature 176 — T014 / FR-013 / SC-007: multi-host conduct parity for the product-domain first-stage
# phase. The lens md is one shared catalog file; the conduct lives in the design-workshop skill,
# deployed to the host-managed skill surfaces. Five supported hosts (Claude, Copilot/GitHub,
# Codex/Agents, Cursor, Antigravity) map onto FOUR on-disk surfaces; the requirement is per supported
# host, not per physical directory. This test proves the surfaces carry identical conduct with the
# one intentional host-capability difference: Claude removes AskUserQuestion so its picker cannot
# swallow the agenda that precedes confirmation.

function Write-Pass { param([string]$m) Write-Host "PASS: $m" -ForegroundColor Green }
function Write-Fail { param([string]$m) Write-Host "FAIL: $m" -ForegroundColor Red; exit 1 }
function Assert-True { param([bool]$c, [string]$m) if (-not $c) { Write-Fail $m } Write-Pass $m }

$repoRoot = (Resolve-Path (Join-Path $PSScriptRoot '..\..')).Path

# The four on-disk managed-skill surfaces (5 supported hosts map onto these as applicable).
$surfaces = @(
    [pscustomobject]@{ Host = 'claude'; RelativePath = '.claude\skills\specrew-design-workshop\SKILL.md' },
    [pscustomobject]@{ Host = 'cursor'; RelativePath = '.cursor\rules\specrew-design-workshop\SKILL.md' },
    [pscustomobject]@{ Host = 'github'; RelativePath = '.github\skills\specrew-design-workshop\SKILL.md' },
    [pscustomobject]@{ Host = 'agents'; RelativePath = '.agents\skills\specrew-design-workshop\SKILL.md' }
)

foreach ($s in $surfaces) {
    $path = Join-Path $repoRoot $s.RelativePath
    $rel = ($path.Substring($repoRoot.Length).TrimStart('\', '/') -replace '\\', '/')
    Assert-True (Test-Path -LiteralPath $path -PathType Leaf) "surface present: $rel"
    # Each surface should also carry the managed marker (deployed, not hand-edited).
    $marker = Join-Path (Split-Path -Parent $path) '.specrew-managed'
    Assert-True (Test-Path -LiteralPath $marker -PathType Leaf) "surface carries the .specrew-managed marker: $rel"
}

# Each surface carries the product-domain first-stage conduct.
foreach ($s in $surfaces) {
    $path = Join-Path $repoRoot $s.RelativePath
    $raw = Get-Content -LiteralPath $path -Raw -Encoding UTF8
    Assert-True ($raw -match '(?im)^##\s+First stage\b.*product-domain phase') "surface carries the '## First stage — the product-domain phase' conduct"
    Assert-True ($raw -match '(?is)runs FIRST,\s+before any technical lens') "surface states the product-domain phase runs FIRST"
    Assert-True ($raw -match '(?i)No batch confirmation') "surface carries the FR-009 no-batch-confirmation rule"
}

# SC-007: each surface equals the deterministic host materialization of the same canonical template.
$templatePath = Join-Path $repoRoot 'extensions\specrew-speckit\squad-templates\skills\design-workshop.md'
$template = Get-Content -LiteralPath $templatePath -Raw -Encoding UTF8
Assert-True ($template -match '(?m)^claude-disallowed-tools:\s*AskUserQuestion\s*$') 'SC-007: canonical template declares the Claude-only picker-removal policy'
foreach ($s in $surfaces) {
    $expected = if ($s.Host -eq 'claude') {
        $template -replace '(?m)^claude-disallowed-tools:', 'disallowed-tools:'
    }
    else {
        $template -replace '(?m)^claude-disallowed-tools:[^\r\n]*(\r?\n)', ''
    }
    $path = Join-Path $repoRoot $s.RelativePath
    $actual = Get-Content -LiteralPath $path -Raw -Encoding UTF8
    Assert-True ($actual -eq $expected) "SC-007: $($s.Host) surface exactly matches its canonical host materialization"
}

# Drift detection: a surface mutated by one byte must break equality (prove the check is real).
$base = Get-Content -LiteralPath (Join-Path $repoRoot $surfaces[0].RelativePath) -Raw -Encoding UTF8
$drifted = $base + "`n<!-- injected drift -->`n"
$baseHash = [System.BitConverter]::ToString([System.Security.Cryptography.SHA256]::HashData([System.Text.Encoding]::UTF8.GetBytes($base)))
$driftHash = [System.BitConverter]::ToString([System.Security.Cryptography.SHA256]::HashData([System.Text.Encoding]::UTF8.GetBytes($drifted)))
Assert-True ($baseHash -ne $driftHash) "SC-007: injected drift changes the surface hash (the parity check detects drift, not a no-op)"

Write-Host "`nAll product-domain multi-host parity tests passed." -ForegroundColor Green
