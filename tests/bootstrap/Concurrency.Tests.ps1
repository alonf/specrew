$ErrorActionPreference = 'Stop'

$base = "$PSScriptRoot/../../scripts/internal/bootstrap"
. "$base/SessionStateAccessor.ps1"
. "$base/ClassificationEngine.ps1"

function Assert-Equal {
    param([AllowNull()]$Actual, [AllowNull()]$Expected, [string]$Message)
    if ($Actual -ne $Expected) { throw "FAIL: $Message (expected '$Expected', got '$Actual')" }
    Write-Host "PASS: $Message" -ForegroundColor Green
}
function Assert-True {
    param([bool]$Condition, [string]$Message)
    if (-not $Condition) { throw "FAIL: $Message" }
    Write-Host "PASS: $Message" -ForegroundColor Green
}

$tmp = Join-Path ([System.IO.Path]::GetTempPath()) ("specrew-t014-" + [guid]::NewGuid().ToString('N'))
New-Item -ItemType Directory -Path $tmp -Force | Out-Null
try {
    # T014 - marker write + read round-trip.
    $mp = Join-Path $tmp 'session-marker.json'
    Write-SpecrewSessionMarker -MarkerPath $mp -HostName claude -ProjectRoot $tmp -Branch main -HeadCommit abc123 -StartedAt '2026-06-08T12:00:00Z' | Out-Null
    $m = Get-SpecrewSessionMarker -MarkerPath $mp
    Assert-Equal $m.host 'claude' 'marker round-trip: host'
    Assert-Equal $m.project_root $tmp 'marker round-trip: project_root'

    # T015 - advisory concurrency (NOT a lock).
    Assert-Equal (Test-SpecrewConcurrentSession -Marker $null -ProjectRoot $tmp -NowUtc '2026-06-08T12:00:00Z').reason 'none' 'no marker -> none'

    $fresh = Test-SpecrewConcurrentSession -Marker $m -ProjectRoot $tmp -NowUtc '2026-06-08T12:30:00Z' -WindowSeconds 3600
    Assert-True $fresh.concurrent 'fresh same-worktree marker (30m < 1h) -> concurrent (advisory)'
    Assert-Equal $fresh.reason 'fresh-marker' 'fresh reason'

    $stale = Test-SpecrewConcurrentSession -Marker $m -ProjectRoot $tmp -NowUtc '2026-06-08T14:00:00Z' -WindowSeconds 3600
    Assert-True (-not $stale.concurrent) 'stale marker (2h > 1h) -> NOT concurrent (no stuck lock)'
    Assert-Equal $stale.reason 'stale-marker-unclean-exit' 'stale marker -> unclean-exit signal'

    $diff = Test-SpecrewConcurrentSession -Marker $m -ProjectRoot (Join-Path $tmp 'other') -NowUtc '2026-06-08T12:30:00Z'
    Assert-True (-not $diff.concurrent) 'different worktree -> not concurrent'
    Assert-Equal $diff.reason 'different-worktree' 'different worktree reason'
}
finally {
    Remove-Item -LiteralPath $tmp -Recurse -Force -ErrorAction SilentlyContinue
}
Write-Host 'Concurrency: all tests passed.' -ForegroundColor Green
