$ErrorActionPreference = 'Stop'

. "$PSScriptRoot/../../scripts/internal/bootstrap/LauncherIntegration.ps1"
$provider = (Resolve-Path "$PSScriptRoot/../../scripts/internal/specrew-bootstrap-provider.ps1").Path

function Assert-True {
    param([bool]$Condition, [string]$Message)
    if (-not $Condition) { throw "FAIL: $Message" }
    Write-Host "PASS: $Message" -ForegroundColor Green
}

$tmp = Join-Path ([System.IO.Path]::GetTempPath()) ("specrew-t013-" + [guid]::NewGuid().ToString('N'))
New-Item -ItemType Directory -Path (Join-Path $tmp '.specrew') -Force | Out-Null
$tmp2 = Join-Path ([System.IO.Path]::GetTempPath()) ("specrew-t013b-" + [guid]::NewGuid().ToString('N'))
New-Item -ItemType Directory -Path (Join-Path $tmp2 '.specrew') -Force | Out-Null
try {
    # Unit - the dedupe keys on a DEDICATED launcher marker (not last-start-prompt.md, which syncs rewrite).
    Write-SpecrewLauncherBootstrapMarker -ProjectRoot $tmp -RecordedAt '2026-06-08T12:00:00Z' | Out-Null
    Assert-True (Test-SpecrewLauncherBootstrapRecent -ProjectRoot $tmp -NowUtc '2026-06-08T12:01:00Z' -WindowSeconds 120) 'recent launcher marker -> dedupe (hook silent)'
    Assert-True (-not (Test-SpecrewLauncherBootstrapRecent -ProjectRoot $tmp -NowUtc '2026-06-08T14:00:00Z' -WindowSeconds 120)) 'old launcher marker -> no dedupe'
    Assert-True (-not (Test-SpecrewLauncherBootstrapRecent -ProjectRoot $tmp2 -NowUtc '2026-06-08T12:01:00Z')) 'no launcher marker -> no dedupe'

    # Integration - provider stays SILENT when the launcher just emitted a bootstrap (SC-002).
    $now = (Get-Date).ToUniversalTime().ToString('o')
    Write-SpecrewLauncherBootstrapMarker -ProjectRoot $tmp2 -RecordedAt $now | Out-Null
    $deduped = & pwsh -NoProfile -File $provider --event-json '{"source":"startup","session_id":"s1"}' --project-root $tmp2
    Assert-True ([string]::IsNullOrWhiteSpace((($deduped -join '')).Trim())) 'provider dedupes (silent) when launcher marker is recent'

    # Integration - provider bootstraps normally when there is NO launcher marker (direct launch).
    $fresh = & pwsh -NoProfile -File $provider --event-json '{"source":"startup","session_id":"s2"}' --project-root $tmp
    # ($tmp marker is 2026-06-08T12:00:00Z, far older than now -> not recent -> no dedupe)
    Assert-True ((($fresh -join "`n")) -match '\[specrew-bootstrap\]') 'provider bootstraps when no recent launcher marker'
}
finally {
    Remove-Item -LiteralPath $tmp -Recurse -Force -ErrorAction SilentlyContinue
    Remove-Item -LiteralPath $tmp2 -Recurse -Force -ErrorAction SilentlyContinue
}
Write-Host 'LauncherIntegration: all tests passed.' -ForegroundColor Green
