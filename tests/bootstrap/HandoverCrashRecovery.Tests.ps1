# F-174 iter-10 (T006): hard-kill / crash-recovery simulation for the handover + marker writers.
#
# A SIGKILL / crash / power-loss fires NO hook and can land mid-write. The M3 hardening (T050 + the iter-10
# marker atomic write) makes that survivable: per-PID temp names so a dead writer's orphan is never adopted,
# atomic File.Replace so the dest is whole, a `.old` backup the reader falls back to, and an honest $null floor
# when nothing valid survives. These tests SIMULATE the crash artifacts deterministically and lock the
# invariants (no live host needed — the harm is a half-written/orphaned FILE, reproducible directly on disk).
$ErrorActionPreference = 'Stop'

$base = "$PSScriptRoot/../../scripts/internal/bootstrap"
. "$base/HandoverStore.ps1"
. "$base/ClassificationEngine.ps1"
. "$base/ProjectMetadataAccessor.ps1"
. "$base/SessionStateAccessor.ps1"

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

$tmp = Join-Path ([System.IO.Path]::GetTempPath()) ("specrew-crash-" + [guid]::NewGuid().ToString('N'))
New-Item -ItemType Directory -Path $tmp -Force | Out-Null
try {
    $hd = Join-Path $tmp 'handover'
    New-Item -ItemType Directory -Path $hd -Force | Out-Null
    $path = Get-SpecrewRollingHandoverPath -HandoverDir $hd

    # --- 1. Torn LIVE file + valid .old -> reader recovers from the .old backup --------------------
    # Seed a valid .old (a previous good handover) + a live file truncated mid-write (frontmatter without
    # recorded_at = structurally invalid; the M3 strictness the iter-10 reader added).
    Write-SpecrewRollingHandoverContent -Path "$path.old" -Source stop -FromHost claude -RecordedAt '2026-06-12T01:00:00Z' -ActiveFeature '174-x' -ActiveBoundary 'plan' | Out-Null
    [System.IO.File]::WriteAllText($path, "---`nschema: v1`nsource: stop`n", [System.Text.UTF8Encoding]::new($false))   # torn: no recorded_at
    $r1 = Get-SpecrewRollingHandover -HandoverDir $hd -NowUtc '2026-06-12T01:30:00Z'
    Assert-True ($null -ne $r1) 'torn live + valid .old -> reader returns a handover (crash-recovery), not null'
    Assert-Equal $r1.recorded_at '2026-06-12T01:00:00Z' 'reader recovered the .OLD backup content (its recorded_at), not the torn live file'

    # --- 2. MISSING live (kill inside the delete+recreate window) + valid .old -> recovers ---------
    Remove-Item -LiteralPath $path -Force
    $r2 = Get-SpecrewRollingHandover -HandoverDir $hd -NowUtc '2026-06-12T01:30:00Z'
    Assert-True ($null -ne $r2 -and $r2.recorded_at -eq '2026-06-12T01:00:00Z') 'missing live + valid .old -> reader recovers from .old (delete+recreate-window kill survived)'

    # --- 3. Both live AND .old torn -> honest $null floor (NO false recovery) ----------------------
    [System.IO.File]::WriteAllText($path, "garbage, not a handover", [System.Text.UTF8Encoding]::new($false))
    [System.IO.File]::WriteAllText("$path.old", "---`nschema: v1`n", [System.Text.UTF8Encoding]::new($false))   # .old also torn
    Assert-True ($null -eq (Get-SpecrewRollingHandover -HandoverDir $hd -NowUtc '2026-06-12T01:30:00Z')) 'both live AND .old invalid -> reader returns $null (honest floor; the disk scan + artifacts carry resume instead)'

    # --- 4. PER-PID guarantee: an orphaned .new from a DIFFERENT (dead) PID is NEVER adopted -------
    # Simulate a writer killed after creating its temp but before the atomic swap, with a FOREIGN pid.
    Remove-Item -LiteralPath "$path.old" -Force -ErrorAction SilentlyContinue
    Remove-Item -LiteralPath $path -Force -ErrorAction SilentlyContinue
    $foreignNew = "$path.99999.new"
    [System.IO.File]::WriteAllText($foreignNew, "---`nschema: v1`nrecorded_at: 1999-01-01T00:00:00Z`nfrom_host: GHOST`n", [System.Text.UTF8Encoding]::new($false))
    Write-SpecrewRollingHandoverContent -Path $path -Source stop -FromHost claude -RecordedAt '2026-06-12T03:00:00Z' -ActiveFeature '174-x' -ActiveBoundary 'tasks' | Out-Null
    $r4 = Get-SpecrewRollingHandover -HandoverDir $hd -NowUtc '2026-06-12T03:30:00Z'
    Assert-True ($null -ne $r4) 'a foreign-PID .new orphan present -> the writer still produces a valid live handover'
    Assert-Equal $r4.recorded_at '2026-06-12T03:00:00Z' 'the live handover is the FRESH write, never the foreign-PID orphan (per-PID temp isolation)'
    Assert-Equal $r4.from_host 'claude' 'the live handover is NOT the GHOST orphan content (no foreign-temp adoption)'
    Assert-True (Test-Path -LiteralPath $foreignNew) 'the foreign-PID orphan is left untouched (not mistaken for our own temp), harmless on disk'

    # --- 5. MARKER crash-recovery: torn live marker -> fail-open null, next write self-heals -------
    $mp = Join-Path $tmp 'session-marker.json'
    Write-SpecrewSessionMarker -MarkerPath $mp -HostName claude -ProjectRoot $tmp -StartedAt '2026-06-12T04:00:00Z' | Out-Null
    [System.IO.File]::WriteAllText($mp, '{ "started_at": "2026-06-12T04:0', [System.Text.UTF8Encoding]::new($false))   # half-written
    Assert-True ($null -eq (Get-SpecrewSessionMarker -MarkerPath $mp)) 'torn live marker -> reader fails open to $null (never a half-true marker)'
    $foreignTmp = "$mp.88888.tmp"
    [System.IO.File]::WriteAllText($foreignTmp, 'orphan', [System.Text.UTF8Encoding]::new($false))
    Write-SpecrewSessionMarker -MarkerPath $mp -HostName codex -ProjectRoot $tmp -StartedAt '2026-06-12T05:00:00Z' | Out-Null
    $m5 = Get-SpecrewSessionMarker -MarkerPath $mp
    # NB: started_at round-trips as a [datetime] (PS7 ConvertFrom-Json auto-parses ISO-8601); host is the
    # string discriminator proving the self-heal landed the FRESH write over the torn file.
    Assert-True ($null -ne $m5 -and $m5.host -eq 'codex' -and $null -ne $m5.started_at) 'next marker write SELF-HEALS to a valid marker (foreign-PID .tmp orphan ignored — per-PID isolation)'
    Assert-True (-not (Test-Path -LiteralPath "$mp.$PID.tmp")) 'our own marker temp is cleaned after the write'
}
finally {
    Remove-Item -LiteralPath $tmp -Recurse -Force -ErrorAction SilentlyContinue
}
Write-Host 'HandoverCrashRecovery: all tests passed.' -ForegroundColor Green
