$ErrorActionPreference = 'Stop'
$repoRoot = (Resolve-Path (Join-Path $PSScriptRoot '..\..')).Path
$workflow = Get-Content -LiteralPath (Join-Path $repoRoot '.github/workflows/specrew-ci.yml') -Raw -Encoding UTF8
if ($workflow -notmatch '(?m)^\s*run:\s*pwsh -NoProfile -File \./tests/manual/review-production-harness-dry-run\.ps1\s*$') {
    throw 'The zero-provider production harness dry run is not wired into CI.'
}

& pwsh -NoProfile -File (Join-Path $repoRoot 'tests/manual/review-production-harness-dry-run.ps1')
if ($LASTEXITCODE -ne 0) { throw 'The production harness dry run failed.' }
Write-Host 'PASS: Tier-2 production harness dry run is CI-wired and green.'
