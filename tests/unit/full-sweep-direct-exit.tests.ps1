[CmdletBinding()]
param()

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

function Fail {
    param([Parameter(Mandatory)][string]$Message)
    Write-Host "FAIL: $Message" -ForegroundColor Red
    exit 1
}

$repoRoot = (Resolve-Path (Join-Path $PSScriptRoot '..\..')).Path
$sourceRunner = Join-Path $repoRoot 'tests\full-powershell-test-sweep.ps1'
$fixtureRoot = Join-Path $repoRoot '.scratch\full-sweep-direct-exit'
$fixtureTests = Join-Path $fixtureRoot 'tests'

try {
    if (Test-Path -LiteralPath $fixtureRoot) {
        Remove-Item -LiteralPath $fixtureRoot -Recurse -Force
    }
    New-Item -ItemType Directory -Path $fixtureTests -Force | Out-Null
    Copy-Item -LiteralPath $sourceRunner -Destination (Join-Path $fixtureTests 'full-powershell-test-sweep.ps1')
    [IO.File]::WriteAllText(
        (Join-Path $fixtureTests 'direct-exit.tests.ps1'),
        "Write-Host 'DIRECT-EXIT-SENTINEL'`nexit 1`n",
        [Text.UTF8Encoding]::new($false))

    & git -C $fixtureRoot init --quiet
    if ($LASTEXITCODE -ne 0) { Fail 'Could not initialize the census fixture repository.' }
    & git -C $fixtureRoot config user.name 'Specrew Census Fixture'
    & git -C $fixtureRoot config user.email 'census-fixture@example.invalid'
    & git -C $fixtureRoot add -- tests
    & git -C $fixtureRoot commit --quiet -m 'fixture: direct exit'
    if ($LASTEXITCODE -ne 0) { Fail 'Could not commit the census fixture baseline.' }

    $output = @(& pwsh -NoProfile -File (Join-Path $fixtureTests 'full-powershell-test-sweep.ps1') -MaxParallel 1 2>&1)
    $exitCode = $LASTEXITCODE
    $text = $output -join "`n"
    if ($exitCode -eq 0) {
        Fail 'Census reported green when its direct assertion script exited 1.'
    }
    if ($text -notmatch 'direct-exit\.tests\.ps1' -or $text -notmatch 'failed=1') {
        Fail "Census failure did not name and count the direct exit. Output:`n$text"
    }
    Write-Host 'PASS: disk-wide census preserves direct assertion-script exit codes' -ForegroundColor Green
}
finally {
    if (Test-Path -LiteralPath $fixtureRoot) {
        Remove-Item -LiteralPath $fixtureRoot -Recurse -Force -ErrorAction SilentlyContinue
    }
}
