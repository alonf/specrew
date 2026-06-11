# F-174 iteration 9: the Stop hook is the PRIMARY author of the rolling handover - it captures the git/fs
# session delta into the MECHANICAL body sections every material stop (never hollow, no agent cooperation),
# accumulates the activity arc across the boundary window, stamps the real host, and preserves an agent
# interpretive overlay. These tests pin the iter-9 contract the iter-8 cross-host dogfood demanded.
$ErrorActionPreference = 'Stop'

$base = "$PSScriptRoot/../../scripts/internal/bootstrap"
. "$base/HandoverStore.ps1"
. "$base/ClassificationEngine.ps1"
. "$base/ProjectMetadataAccessor.ps1"
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
function Assert-Match {
    param([string]$Text, [string]$Pattern, [string]$Message)
    if ($Text -notmatch $Pattern) { throw "FAIL: $Message (pattern '$Pattern' not found in: $Text)" }
    Write-Host "PASS: $Message" -ForegroundColor Green
}

function Invoke-StopHook {
    param([string]$ProjectRoot, [string]$HostKind = 'codex')
    & pwsh -NoProfile -File $provider --event-json '{"hook_event_name":"Stop"}' --project-root $ProjectRoot --host-kind $HostKind 2>$null | Out-Null
}
function Get-ActivityBulletCount {
    param([string]$Content)
    return @($Content -split "`n" | Where-Object { $_ -match '^\s*-\s' }).Count
}

$tmp = Join-Path ([System.IO.Path]::GetTempPath()) ("specrew-iter9-" + [guid]::NewGuid().ToString('N'))
$activityTitle = 'What I just did (last 3-5 turns or last boundary work)'
$contextTitle = "Context the receiving host needs that artifacts don't carry"
$recTitle = 'Recommended next-immediate-step'
try {
    $proj = Join-Path $tmp 'proj'
    New-Item -ItemType Directory -Path (Join-Path $proj 'specs/001-notekeep') -Force | Out-Null
    New-Item -ItemType Directory -Path (Join-Path $proj '.specrew') -Force | Out-Null
    Set-Content -LiteralPath (Join-Path $proj '.gitignore') -Value ".specrew/`n" -Encoding UTF8
    git -C $proj init -q -b main 2>$null; git -C $proj config user.email 't@t'; git -C $proj config user.name 't'
    git -C $proj add -A 2>$null; git -C $proj commit -q -m init 2>$null
    git -C $proj checkout -q -b '001-notekeep' 2>$null
    (@{ session_state = @{ feature_ref = '001-notekeep'; boundary_type = 'before-implement'; host = 'claude' } } | ConvertTo-Json -Depth 5) |
        Set-Content -LiteralPath (Join-Path $proj '.specrew/start-context.json') -Encoding UTF8
    # THE NEAR-MISS the dogfood exposed: an implementation file written but NOT committed.
    Set-Content -LiteralPath (Join-Path $proj 'notekeep.py') -Value "print('hi')`n" -Encoding UTF8

    # --- Get-SpecrewSessionDelta sees the uncommitted file (host-universal, no agent/transcript) ---
    $delta = Get-SpecrewSessionDelta -ProjectRoot $proj
    Assert-True $delta.has_uncommitted 'delta: detects the uncommitted implementation file'
    Assert-Equal $delta.uncommitted_count 1 'delta: one uncommitted file'
    Assert-True ($delta.uncommitted_files -contains 'notekeep.py') 'delta: names notekeep.py'
    Assert-Equal $delta.branch '001-notekeep' 'delta: resolves the feature branch'

    # --- The Stop hook AUTHORS the mechanical body from the delta: never hollow, real from_host ---
    Invoke-StopHook -ProjectRoot $proj -HostKind codex
    $hd = Join-Path $proj '.specrew/handover'
    $h = Get-SpecrewRollingHandover -HandoverDir $hd -NowUtc '2026-06-11T00:00:00Z'
    Assert-True ($null -ne $h) 'hook wrote the rolling handover on a material Stop'
    Assert-Equal $h.from_host 'codex' 'from_host is the REAL host from --host-kind, not the literal "host"'
    Assert-True (-not (Test-SpecrewHandoverBodyPlaceholder -Sections $h.sections).placeholder) 'body is NOT hollow - the hook authored mechanical sections from the delta with zero agent cooperation'
    Assert-Match ([string]$h.sections[$contextTitle]) 'notekeep\.py' 'Context surfaces the UNCOMMITTED notekeep.py (the exact near-miss the dogfood exposed)'
    Assert-Match ([string]$h.sections[$recTitle]) 'uncommitted' 'Recommended next-immediate-step warns about the uncommitted work'
    Assert-Match ([string]$h.sections[$activityTitle]) '^\s*-\s' 'What I just did is a bulleted activity line'

    # --- Activity ACCUMULATES across same-boundary stops (newest-first, bounded) ---
    Add-Content -LiteralPath (Join-Path $proj 'notekeep.py') -Value "print('more')`n" -Encoding UTF8
    Invoke-StopHook -ProjectRoot $proj -HostKind codex
    $h2 = Get-SpecrewRollingHandover -HandoverDir $hd -NowUtc '2026-06-11T00:01:00Z'
    Assert-True ((Get-ActivityBulletCount -Content ([string]$h2.sections[$activityTitle])) -ge 2) 'What I just did ACCUMULATES across same-boundary stops (the between-gate arc survives)'

    # --- A boundary change RESETS the activity arc ---
    (@{ session_state = @{ feature_ref = '001-notekeep'; boundary_type = 'review-signoff'; host = 'claude' } } | ConvertTo-Json -Depth 5) |
        Set-Content -LiteralPath (Join-Path $proj '.specrew/start-context.json') -Encoding UTF8
    Invoke-StopHook -ProjectRoot $proj -HostKind codex
    $h3 = Get-SpecrewRollingHandover -HandoverDir $hd -NowUtc '2026-06-11T00:02:00Z'
    Assert-Equal $h3.active_boundary 'review-signoff' 'boundary advanced'
    Assert-Equal (Get-ActivityBulletCount -Content ([string]$h3.sections[$activityTitle])) 1 'a boundary change RESETS the activity arc to a single fresh bullet'

    # --- An agent interpretive overlay is PRESERVED across a hook stop; mechanical still refreshes ---
    $interp0 = (Get-SpecrewHandoverAgentOwnedSections)[0]
    Write-SpecrewHandoverContext -HandoverDir $hd -FromHost codex -RecordedAt '2026-06-11T00:03:00Z' `
        -ActiveFeature '001-notekeep' -ActiveBoundary 'review-signoff' -Sections @{ $interp0 = 'AGENT: the store schema migration is the open risk.' } | Out-Null
    Add-Content -LiteralPath (Join-Path $proj 'notekeep.py') -Value "print('again')`n" -Encoding UTF8
    Invoke-StopHook -ProjectRoot $proj -HostKind codex
    $h4 = Get-SpecrewRollingHandover -HandoverDir $hd -NowUtc '2026-06-11T00:04:00Z'
    Assert-Match ([string]$h4.sections[$interp0]) 'store schema migration' 'agent interpretive overlay PRESERVED across the next hook stop (section ownership)'
    Assert-Match ([string]$h4.sections[$recTitle]) 'uncommitted' 'mechanical sections still refresh alongside the preserved interpretive overlay'

    # --- No hollow-handover journal entry while the hook captures a real delta (recalibrated) ---
    Assert-True (-not (Test-Path -LiteralPath (Join-Path $proj '.specrew/runtime/handover-journal.jsonl'))) 'NO hollow-handover-at-stop journaled while the hook captures a delta (recalibrated from the iter-5 every-build-stop hollow)'

    # --- Section classification stays consistent with the fixed order ---
    $mech = Get-SpecrewHandoverMechanicalSections
    $agent = Get-SpecrewHandoverAgentOwnedSections
    Assert-Equal (@($mech).Count) 4 'four mechanical (hook-owned) sections'
    Assert-Equal (@($agent).Count) 2 'two interpretive (agent-owned) sections'
    Assert-True (@(@($mech) + @($agent) | Sort-Object -Unique).Count -eq @(Get-SpecrewHandoverSectionOrder).Count) 'mechanical + interpretive partition the full section order with no overlap or gap'
}
finally {
    Remove-Item -LiteralPath $tmp -Recurse -Force -ErrorAction SilentlyContinue
}
Write-Host 'HandoverHookPrimary: all tests passed.' -ForegroundColor Green
