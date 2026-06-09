$ErrorActionPreference = 'Stop'

$base = "$PSScriptRoot/../../scripts/internal/bootstrap"
. "$base/HandoverStore.ps1"
. "$base/ClassificationEngine.ps1"
$provider = (Resolve-Path "$PSScriptRoot/../../scripts/internal/specrew-handover-provider.ps1").Path

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

$tmp = Join-Path ([System.IO.Path]::GetTempPath()) ("specrew-t027-" + [guid]::NewGuid().ToString('N'))
$hd = Join-Path $tmp 'handover'
try {
    # --- Rolling write -> read round-trip + overwrite-in-place (no archive) ---
    # iter-5: the hook no longer authors a body (the AGENT does, via Write-SpecrewHandoverContext); the
    # hook writes the FLOOR and preserves-or-placeholders the body. This block exercises floor/crash-safety.
    $p1 = Write-SpecrewRollingHandover -HandoverDir $hd -Source stop -FromHost claude -RecordedAt '2026-06-09T10:00:00Z' `
        -ActiveFeature myfeat -ActiveBoundary plan
    Assert-True ($p1 -match 'session-handover\.md$') 'rolling file is the single session-handover.md'
    $h1 = Get-SpecrewRollingHandover -HandoverDir $hd -NowUtc '2026-06-09T10:05:00Z'
    Assert-Equal $h1.active_boundary 'plan' 'round-trip reads boundary'
    Assert-True $h1.fresh 'rolling handover is fresh'

    $p2 = Write-SpecrewRollingHandover -HandoverDir $hd -Source stop -FromHost claude -RecordedAt '2026-06-09T10:10:00Z' `
        -ActiveFeature myfeat -ActiveBoundary tasks
    Assert-Equal $p1 $p2 'second write is the SAME path (overwrite-in-place)'
    Assert-Equal (@(Get-ChildItem -LiteralPath $hd -Filter '*.md').Count) 1 'exactly ONE rolling file (no archive)'
    # Crash-safety property: the rolling file always reflects the LAST write (last completed turn).
    $h2 = Get-SpecrewRollingHandover -HandoverDir $hd -NowUtc '2026-06-09T10:11:00Z'
    Assert-Equal $h2.active_boundary 'tasks' 'rolling file is always-latest (crash-safe: reflects the last write)'

    # --- Material-change engine ---
    Assert-Equal (Test-SpecrewHandoverMaterialChange -HandoverExists $false).reason 'no-existing-handover' 'no existing handover -> material'
    Assert-Equal (Test-SpecrewHandoverMaterialChange -CurrentBoundary 'tasks' -LastBoundary 'plan' -HasTrackedChange $false -HandoverExists $true).reason 'boundary-moved' 'boundary moved -> material'
    Assert-Equal (Test-SpecrewHandoverMaterialChange -CurrentBoundary 'plan' -LastBoundary 'plan' -HasTrackedChange $true -HandoverExists $true).reason 'tracked-change' 'tracked change -> material'
    Assert-True (-not (Test-SpecrewHandoverMaterialChange -CurrentBoundary 'plan' -LastBoundary 'plan' -HasTrackedChange $false -HandoverExists $true).material) 'no boundary move + no tracked change -> skip'

    # --- Stop provider integration: writes on a material turn (no existing handover), then skips a quiet turn ---
    $proj = Join-Path $tmp 'proj'
    New-Item -ItemType Directory -Path (Join-Path $proj 'specs/myfeat') -Force | Out-Null
    New-Item -ItemType Directory -Path (Join-Path $proj '.specrew') -Force | Out-Null
    (@{ session_state = @{ feature_ref = 'myfeat'; boundary_type = 'plan'; host = 'claude' } } | ConvertTo-Json -Depth 5) |
        Set-Content -LiteralPath (Join-Path $proj '.specrew/start-context.json') -Encoding UTF8
    # Clean git repo with .specrew/ gitignored, so `git status` is deterministically clean (otherwise
    # git -C walks up to a parent repo, or the gitignored handover file dirties status non-deterministically).
    Set-Content -LiteralPath (Join-Path $proj '.gitignore') -Value ".specrew/`n" -Encoding UTF8
    git -C $proj init -q -b main 2>$null; git -C $proj config user.email 't@t'; git -C $proj config user.name 't'
    git -C $proj add -A 2>$null; git -C $proj commit -q -m init 2>$null
    & pwsh -NoProfile -File $provider --event-json '{"hook_event_name":"Stop"}' --project-root $proj 2>$null | Out-Null
    $rf = Join-Path $proj '.specrew/handover/session-handover.md'
    Assert-True (Test-Path -LiteralPath $rf) 'Stop provider wrote the rolling handover on the first (material) Stop'
    $before = Get-Content -LiteralPath $rf -Raw
    Start-Sleep -Milliseconds 50
    & pwsh -NoProfile -File $provider --event-json '{"hook_event_name":"Stop"}' --project-root $proj 2>$null | Out-Null
    $after = Get-Content -LiteralPath $rf -Raw
    Assert-Equal $after $before 'a quiet Stop (same boundary, no tracked change) does NOT rewrite (material-change skip)'
}
finally {
    Remove-Item -LiteralPath $tmp -Recurse -Force -ErrorAction SilentlyContinue
}
Write-Host 'RollingHandover: all tests passed.' -ForegroundColor Green
