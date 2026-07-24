# Deterministic source-contract guard for DRIFT-198-I008-056–058.
# The full registry provides the behavioral proof; this bounded test prevents removal of the
# caller-repository invariant or reintroduction of an ancestor-discoverable nested Git fixture.
[CmdletBinding()]
param()

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

function Fail {
    param([Parameter(Mandatory = $true)][string]$Message)
    Write-Host "FAIL: $Message" -ForegroundColor Red
    exit 1
}

$repoRoot = (Resolve-Path (Join-Path $PSScriptRoot '..\..')).Path
$runner = Get-Content -LiteralPath (Join-Path $repoRoot 'tests\f198-regression-suite.ps1') -Raw
$fixture = Get-Content -LiteralPath (Join-Path $repoRoot 'tests\integration\pending-verdict-stop-artifact.tests.ps1') -Raw
$distributionFixture = Get-Content -LiteralPath (Join-Path $repoRoot 'tests\integration\distribution-module-update.ps1') -Raw

foreach ($requiredField in @('Head', 'Branch', 'LocalConfig', 'Status')) {
    if ($runner -notmatch ('(?m)^\s*{0}\s*=' -f [regex]::Escape($requiredField))) {
        Fail "Feature 198 runner no longer snapshots caller field '$requiredField'."
    }
}

if (@([regex]::Matches($runner, 'Get-CallerRepositoryContamination\s+-Baseline')).Count -lt 2) {
    Fail 'Feature 198 runner must check caller contamination after both timeout and normal child completion.'
}
if ($runner -notmatch "FAIL \(CALLER REPOSITORY CONTAMINATED\)" -or
    $runner -notmatch '\$r\.Result\s+-ne\s+''Passed''') {
    Fail 'Feature 198 runner must stop on caller contamination and honor Pester container-level failure.'
}
if ($runner -match 'exit \(\[int\]\$r\.FailedCount\)') {
    Fail 'Feature 198 runner regressed to FailedCount-only Pester evaluation.'
}

if ($fixture -notmatch '\[System\.IO\.Path\]::GetTempPath\(\)' -or
    $fixture -match 'Join-Path\s+\$repoRoot\s+''\.scratch\\pending-verdict-stop-artifact''') {
    Fail 'Pending-verdict fixture must live outside the caller repository.'
}
if ($fixture -notmatch "rev-parse', '--show-toplevel" -or
    $fixture -notmatch 'Fixture repository escaped its isolated root') {
    Fail 'Pending-verdict fixture must verify the exact Git top-level before any branch mutation.'
}
if ($fixture -match 'git\s+-C\s+\$projectRoot\s+config\s+user\.') {
    Fail 'Pending-verdict fixture must not persist test identity; use per-invocation git -c values.'
}

if ($distributionFixture -notmatch '\[string\]::Empty\s*\|\s*&\s*pwsh' -or
    $distributionFixture -match '\$output\s*=\s*@\(\s*&\s*pwsh') {
    Fail 'Distribution-update automation must close child stdin instead of inheriting the caller console.'
}

Write-Host 'PASS: regression harness preserves caller state, isolates Git fixtures, and closes automation stdin' -ForegroundColor Green
exit 0
