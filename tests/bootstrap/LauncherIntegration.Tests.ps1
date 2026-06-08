$ErrorActionPreference = 'Stop'

. "$PSScriptRoot/../../scripts/internal/bootstrap/LauncherIntegration.ps1"
$provider = (Resolve-Path "$PSScriptRoot/../../scripts/internal/specrew-bootstrap-provider.ps1").Path

function Assert-True {
    param([bool]$Condition, [string]$Message)
    if (-not $Condition) { throw "FAIL: $Message" }
    Write-Host "PASS: $Message" -ForegroundColor Green
}
function Write-LastStart {
    param([string]$Dir, [string]$RecordedAt)
    $p = Join-Path $Dir '.specrew/last-start-prompt.md'
    @('---', "session_state_recorded_at: $RecordedAt", 'session_state_active: true', '---', '', 'prompt body') |
        Set-Content -LiteralPath $p -Encoding UTF8
}

$tmp = Join-Path ([System.IO.Path]::GetTempPath()) ("specrew-t013-" + [guid]::NewGuid().ToString('N'))
New-Item -ItemType Directory -Path (Join-Path $tmp '.specrew') -Force | Out-Null
$tmp2 = Join-Path ([System.IO.Path]::GetTempPath()) ("specrew-t013b-" + [guid]::NewGuid().ToString('N'))
New-Item -ItemType Directory -Path (Join-Path $tmp2 '.specrew') -Force | Out-Null
try {
    # Unit - the dedupe freshness primitive.
    Write-LastStart -Dir $tmp -RecordedAt '2026-06-08T12:00:00Z'
    Assert-True (Test-SpecrewLauncherBootstrapRecent -ProjectRoot $tmp -NowUtc '2026-06-08T12:01:00Z' -WindowSeconds 120) 'recent launcher prompt -> dedupe (hook stays silent)'
    Assert-True (-not (Test-SpecrewLauncherBootstrapRecent -ProjectRoot $tmp -NowUtc '2026-06-08T14:00:00Z' -WindowSeconds 120)) 'old launcher prompt -> no dedupe'
    Assert-True (-not (Test-SpecrewLauncherBootstrapRecent -ProjectRoot $tmp2 -NowUtc '2026-06-08T12:01:00Z')) 'no launcher prompt -> no dedupe'

    # Integration - provider stays SILENT when the launcher just bootstrapped (exactly-once, SC-002).
    $now = (Get-Date).ToUniversalTime().ToString('o')
    Write-LastStart -Dir $tmp2 -RecordedAt $now
    $deduped = & pwsh -NoProfile -File $provider --event-json '{"source":"startup","session_id":"s1"}' --project-root $tmp2
    Assert-True ([string]::IsNullOrWhiteSpace((($deduped -join '')).Trim())) 'provider dedupes (silent) when launcher just bootstrapped'

    # Integration - provider bootstraps normally with no recent launcher prompt.
    $fresh = & pwsh -NoProfile -File $provider --event-json '{"source":"startup","session_id":"s2"}' --project-root $tmp
    Assert-True ((($fresh -join "`n")) -match '\[specrew-bootstrap\]') 'provider still bootstraps when no recent launcher prompt'
}
finally {
    Remove-Item -LiteralPath $tmp -Recurse -Force -ErrorAction SilentlyContinue
    Remove-Item -LiteralPath $tmp2 -Recurse -Force -ErrorAction SilentlyContinue
}
Write-Host 'LauncherIntegration: all tests passed.' -ForegroundColor Green
