$ErrorActionPreference = 'Stop'

$base = "$PSScriptRoot/../../scripts/internal/bootstrap"
. "$base/HostEventAdapter.ps1"
. "$base/HandoverStore.ps1"
. "$base/SessionEndHandoverManager.ps1"

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

$tmp = Join-Path ([System.IO.Path]::GetTempPath()) ("specrew-t011-" + [guid]::NewGuid().ToString('N'))
New-Item -ItemType Directory -Path $tmp -Force | Out-Null
try {
    # T011 - write-only by default (clear -> full detail).
    $r = Invoke-SpecrewSessionEndHandover -RawEvent '{"source":"clear","session_id":"s1"}' -HostName claude `
        -ProjectRoot $tmp -RecordedAt '2026-06-08T12:00:00Z' -ActiveFeature '174-x' -ActiveBoundary review-signoff `
        -Sections @{ 'Recommended next-immediate-step' = 'resume iteration 002' }
    Assert-True (Test-Path -LiteralPath $r.path) 'handover written'
    Assert-Equal $r.detail 'full' 'clear source resolves full detail'
    Assert-True $r.write_only 'write-only by default'
    Assert-True (-not $r.committed) 'no git commit by default (FR-021)'

    # T012 - SessionEnd -> SessionStart round-trip read.
    $h = Get-SpecrewHandover -HandoverDir (Join-Path $tmp '.specrew/handover') -NowUtc '2026-06-08T13:00:00Z'
    Assert-Equal $h.active_feature '174-x' 'round-trip read recovers active_feature'
    Assert-True $h.fresh 'round-trip handover is fresh'

    # compact -> best-effort + the 130 compaction note.
    $r2 = Invoke-SpecrewSessionEndHandover -RawEvent '{"source":"compact","session_id":"s2"}' -HostName claude `
        -ProjectRoot $tmp -RecordedAt '2026-06-08T12:30:00Z'
    Assert-Equal $r2.detail 'best-effort' 'compact source resolves best-effort detail'
    Assert-True ((Get-Content -LiteralPath $r2.path -Raw) -match 'transcript dropped by compaction') 'compaction note added'

    # Opt-in scoped commit proves NO `git add -A` (decoy stays untracked).
    $g = Join-Path $tmp 'gitrepo'
    New-Item -ItemType Directory -Path $g -Force | Out-Null
    git -C $g init -q -b main 2>$null
    git -C $g config user.email 't@t'; git -C $g config user.name 't'
    git -C $g commit --allow-empty -q -m base
    Set-Content -LiteralPath (Join-Path $g 'DECOY.txt') -Value 'untracked decoy' -Encoding UTF8
    $r3 = Invoke-SpecrewSessionEndHandover -RawEvent '{"source":"clear","session_id":"s3"}' -HostName claude `
        -ProjectRoot $g -RecordedAt '2026-06-08T12:45:00Z' -CommitOnExit $true
    Assert-True $r3.committed 'opt-in scoped commit succeeded'
    $status = ((git -C $g status --porcelain) -join "`n")
    Assert-True ($status -match 'DECOY.txt') 'decoy NOT swept into the handover commit (no git add -A)'
}
finally {
    Remove-Item -LiteralPath $tmp -Recurse -Force -ErrorAction SilentlyContinue
}
Write-Host 'SessionEndHandover: all tests passed.' -ForegroundColor Green
