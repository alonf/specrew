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

    # --- F-174 (T050): anchorless WORKSHOP window -> the floor stamps the BRANCH-resolved feature ---
    # Before the fix the pre-specify anchor (no feature_ref) made the floor stamp an EMPTY active_feature, so
    # Test-SpecrewHandoverValidity returned 'no-feature' and the handover was NEVER surfaced on resume (the
    # agent re-derived from scratch - "resync takes minutes"). Now the floor resolves the feature from the
    # branch (Spec Kit: branch == feature slug, specs/<branch>/ already scaffolded), so the handover is
    # stampable mid-workshop and becomes surfaceable - the copilot resume-repair path, on every host.
    $proj2 = Join-Path $tmp 'proj2'
    New-Item -ItemType Directory -Path (Join-Path $proj2 'specs/001-pomodoro-cli') -Force | Out-Null
    New-Item -ItemType Directory -Path (Join-Path $proj2 '.specrew') -Force | Out-Null
    # The WORKSHOP anchor: a session_state with NO feature_ref and NO boundary (nothing has crossed yet).
    (@{ session_state = @{ host = 'claude' } } | ConvertTo-Json -Depth 5) |
        Set-Content -LiteralPath (Join-Path $proj2 '.specrew/start-context.json') -Encoding UTF8
    Set-Content -LiteralPath (Join-Path $proj2 '.gitignore') -Value ".specrew/`n" -Encoding UTF8
    git -C $proj2 init -q -b main 2>$null; git -C $proj2 config user.email 't@t'; git -C $proj2 config user.name 't'
    git -C $proj2 add -A 2>$null; git -C $proj2 commit -q -m init 2>$null
    # The agent is on the feature branch during the workshop (specs/<branch>/ already scaffolded by Spec Kit).
    git -C $proj2 checkout -q -b '001-pomodoro-cli' 2>$null
    & pwsh -NoProfile -File $provider --event-json '{"hook_event_name":"Stop"}' --project-root $proj2 2>$null | Out-Null
    $wf = Get-SpecrewRollingHandover -HandoverDir (Join-Path $proj2 '.specrew/handover') -NowUtc '2026-06-10T00:00:00Z'
    Assert-True ($null -ne $wf) 'workshop Stop wrote a rolling handover (material: no existing handover)'
    Assert-Equal $wf.active_feature '001-pomodoro-cli' 'anchorless workshop Stop stamps the BRANCH-resolved feature (empty before the fix -> handover now surfaceable on resume)'

    # --- F-174 T050 (maintainer finding): crash-safe replace + .old backup + reader fallback ---
    $hd2 = Join-Path $tmp 'handover-crash'
    $rp = Join-Path $hd2 'session-handover.md'
    # First write -> file exists, no .old yet (nothing to back up).
    Write-SpecrewRollingHandover -HandoverDir $hd2 -Source stop -FromHost claude -RecordedAt '2026-06-10T10:00:00Z' `
        -ActiveFeature myfeat -ActiveBoundary plan | Out-Null
    Assert-True (Test-Path -LiteralPath $rp) 'atomic writer: first write lands the live file'
    Assert-True (-not (Test-Path -LiteralPath "$rp.new")) 'atomic writer: no .new residue after promote'
    # Second write -> atomic swap keeps the PREVIOUS version as .old.
    Write-SpecrewRollingHandover -HandoverDir $hd2 -Source stop -FromHost claude -RecordedAt '2026-06-10T10:10:00Z' `
        -ActiveFeature myfeat -ActiveBoundary tasks | Out-Null
    Assert-True (Test-Path -LiteralPath "$rp.old") 'atomic writer: previous version kept as .old (crash backup)'
    Assert-Equal (Get-SpecrewRollingHandover -HandoverDir $hd2 -NowUtc '2026-06-10T10:11:00Z').active_boundary 'tasks' 'live file is the NEW version after the swap'
    Assert-Equal (ConvertFrom-SpecrewHandoverFile -Path "$rp.old").active_boundary 'plan' '.old is the PREVIOUS version'
    # THE KILL WINDOW: the live file vanishes (killed between an agent delete + create) -> reader falls back to .old.
    Remove-Item -LiteralPath $rp -Force
    $rec = Get-SpecrewRollingHandover -HandoverDir $hd2 -NowUtc '2026-06-10T10:12:00Z'
    Assert-True ($null -ne $rec) 'reader falls back to .old when the live file is missing (the delete-create kill window)'
    Assert-Equal $rec.active_boundary 'plan' 'fallback serves the .old content (one version stale beats nothing)'
    # And the floor-writer PRESERVE path also recovers the body from .old: author a body, lose the live file, Stop.
    $sections = @{}
    foreach ($t in (Get-SpecrewHandoverSectionOrder)) { $sections[$t] = "authored: $t" }
    Write-SpecrewHandoverContext -HandoverDir $hd2 -FromHost claude -RecordedAt '2026-06-10T10:20:00Z' `
        -ActiveFeature myfeat -ActiveBoundary tasks -Sections $sections | Out-Null
    # A floor refresh swaps the authored version into .old (preserve keeps it in the live file too).
    Write-SpecrewRollingHandover -HandoverDir $hd2 -Source stop -FromHost claude -RecordedAt '2026-06-10T10:25:00Z' `
        -ActiveFeature myfeat -ActiveBoundary tasks | Out-Null
    Remove-Item -LiteralPath $rp -Force   # the kill window again - live file gone, .old has the authored body
    Write-SpecrewRollingHandover -HandoverDir $hd2 -Source stop -FromHost claude -RecordedAt '2026-06-10T10:30:00Z' `
        -ActiveFeature myfeat -ActiveBoundary tasks | Out-Null
    $rec2 = Get-SpecrewRollingHandover -HandoverDir $hd2 -NowUtc '2026-06-10T10:31:00Z'
    Assert-True (Test-SpecrewHandoverSectionAuthored -Content ([string]$rec2.sections[(Get-SpecrewHandoverSectionOrder)[0]])) 'floor-writer preserve path recovers the AUTHORED body from .old after the live file was lost'
}
finally {
    Remove-Item -LiteralPath $tmp -Recurse -Force -ErrorAction SilentlyContinue
}
Write-Host 'RollingHandover: all tests passed.' -ForegroundColor Green
