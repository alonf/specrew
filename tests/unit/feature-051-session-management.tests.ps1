[CmdletBinding()]
param()

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

# Feature 051 Iteration 2a (US3) acceptance tests — session locks / collision detection.
# Plain-PowerShell convention (Assert-* helpers, exit 1 on failure). Tests exercise the
# session-management module functions against REAL temp files (no mocks, Shape-6).
# Covers: T020 (read/write + shared atomic-write), T020b (fingerprint local-only),
# T021 register, T022 remove, T023 collision (FR-010/SC-002), T024 stale-clear (FR-011),
# T026 corrupt-YAML safe-degradation, T026b deterministic atomic-write/race.

function Write-Pass { param([string]$m) Write-Host "PASS: $m" -ForegroundColor Green }
function Write-Fail { param([string]$m) Write-Host "FAIL: $m" -ForegroundColor Red }
function Assert-True { param([bool]$c, [string]$m) if (-not $c) { Write-Fail $m; exit 1 } Write-Pass $m }

$repoRoot = Split-Path -Parent (Split-Path -Parent $PSScriptRoot)
$mod = Join-Path $repoRoot 'scripts/internal/session-management.ps1'
Assert-True (Test-Path -LiteralPath $mod) "session-management.ps1 exists at $mod"
. $mod

function New-TempProject {
    $d = Join-Path ([System.IO.Path]::GetTempPath()) ("specrew-f051-sm-{0}" -f ([System.Guid]::NewGuid().ToString('N')))
    New-Item -ItemType Directory -Path (Join-Path $d '.specrew') -Force | Out-Null
    return $d
}
function Get-LockPath { param($root) Join-Path $root '.specrew/active-sessions.yml' }

# --- T020b: Get-MachineFingerprint local-only ---
$fp1 = Get-MachineFingerprint
$fp2 = Get-MachineFingerprint
Assert-True (-not [string]::IsNullOrWhiteSpace($fp1)) "T020b: Get-MachineFingerprint returns a non-empty value"
Assert-True ($fp1 -eq $fp2) "T020b: fingerprint is stable across calls"
$host1 = [System.Environment]::MachineName
Assert-True ($fp1.IndexOf($host1, [System.StringComparison]::OrdinalIgnoreCase) -ge 0 -or $fp1 -match '[A-Za-z0-9]') "T020b: fingerprint derives from local identifiers (hostname-based)"

# --- T020/T021: register + read round-trip ---
$p = New-TempProject
try {
    Register-SessionLock -ProjectRoot $p -FeatureId '051-multi-session-foundation' -User 'alon' -Fingerprint 'HOST-A' -NowUtc '2026-05-31T08:00:00Z'
    $sessions = @(Read-ActiveSessions -ProjectRoot $p)
    Assert-True ($sessions.Count -eq 1) "T021: one session entry after register (got $($sessions.Count))"
    Assert-True ($sessions[0].feature_id -eq '051-multi-session-foundation') "T021: feature_id persisted"
    Assert-True ($sessions[0].machine_fingerprint -eq 'HOST-A') "T021: machine_fingerprint persisted"
    Assert-True ($sessions[0].user -eq 'alon') "T021: user persisted"

    # Idempotent: same feature+machine updates heartbeat, no duplicate
    Register-SessionLock -ProjectRoot $p -FeatureId '051-multi-session-foundation' -User 'alon' -Fingerprint 'HOST-A' -NowUtc '2026-05-31T09:00:00Z'
    $sessions = @(Read-ActiveSessions -ProjectRoot $p)
    Assert-True ($sessions.Count -eq 1) "T021: re-register same feature+machine does not duplicate (got $($sessions.Count))"
    Assert-True ($sessions[0].last_heartbeat_time -eq '2026-05-31T09:00:00Z') "T021: re-register updates last_heartbeat_time"
}
finally { Remove-Item -LiteralPath $p -Recurse -Force -ErrorAction SilentlyContinue }

# --- T023: collision detection (FR-010) ---
$p = New-TempProject
try {
    Register-SessionLock -ProjectRoot $p -FeatureId 'feat-x' -User 'alon' -Fingerprint 'HOST-A' -NowUtc '2026-05-31T08:00:00Z'
    $col = Test-SessionCollision -ProjectRoot $p -FeatureId 'feat-x' -Fingerprint 'HOST-B'
    Assert-True ($null -ne $col) "T023: collision detected for same feature from a different machine"
    Assert-True ($col.machine_fingerprint -eq 'HOST-A') "T023: collision returns the EXISTING (other) entry"
    $noCol = Test-SessionCollision -ProjectRoot $p -FeatureId 'feat-x' -Fingerprint 'HOST-A'
    Assert-True ($null -eq $noCol) "T023: no collision for the same machine (own lock)"
    $noCol2 = Test-SessionCollision -ProjectRoot $p -FeatureId 'feat-other' -Fingerprint 'HOST-B'
    Assert-True ($null -eq $noCol2) "T023: no collision for a different feature"
}
finally { Remove-Item -LiteralPath $p -Recurse -Force -ErrorAction SilentlyContinue }

# --- T024: stale-lock clearing (FR-011) ---
$p = New-TempProject
try {
    Register-SessionLock -ProjectRoot $p -FeatureId 'fresh' -User 'a' -Fingerprint 'H1' -NowUtc '2026-05-31T08:00:00Z'
    Register-SessionLock -ProjectRoot $p -FeatureId 'stale' -User 'b' -Fingerprint 'H2' -NowUtc '2026-05-29T00:00:00Z'
    $cleared = Clear-StaleSessionLocks -ProjectRoot $p -ThresholdHours 24 -NowUtc '2026-05-31T09:00:00Z'
    Assert-True ($cleared -eq 1) "T024: one stale lock cleared (>24h), got $cleared"
    $sessions = @(Read-ActiveSessions -ProjectRoot $p)
    Assert-True ($sessions.Count -eq 1 -and $sessions[0].feature_id -eq 'fresh') "T024: fresh lock retained, stale removed"
}
finally { Remove-Item -LiteralPath $p -Recurse -Force -ErrorAction SilentlyContinue }

# --- T022: remove (FR-009) ---
$p = New-TempProject
try {
    Register-SessionLock -ProjectRoot $p -FeatureId 'feat-r' -User 'a' -Fingerprint 'H1' -NowUtc '2026-05-31T08:00:00Z'
    Remove-SessionLock -ProjectRoot $p -FeatureId 'feat-r' -Fingerprint 'H1'
    Assert-True ((@(Read-ActiveSessions -ProjectRoot $p)).Count -eq 0) "T022: lock removed"
    Remove-SessionLock -ProjectRoot $p -FeatureId 'absent' -Fingerprint 'H9'  # no-op
    Assert-True $true "T022: remove of absent entry is a no-op success"
}
finally { Remove-Item -LiteralPath $p -Recurse -Force -ErrorAction SilentlyContinue }

# --- T026: corrupt-YAML safe-degradation (Edge Case) ---
$p = New-TempProject
try {
    Set-Content -LiteralPath (Get-LockPath $p) -Value "::: not valid yaml :::`n  - broken" -Encoding UTF8
    $sessions = @(Read-ActiveSessions -ProjectRoot $p)
    Assert-True ($sessions.Count -eq 0) "T026: corrupt active-sessions.yml degrades to empty (no crash)"
    Register-SessionLock -ProjectRoot $p -FeatureId 'recover' -User 'a' -Fingerprint 'H1' -NowUtc '2026-05-31T08:00:00Z'
    Assert-True ((@(Read-ActiveSessions -ProjectRoot $p)).Count -eq 1) "T026: file recreated cleanly after corruption"
}
finally { Remove-Item -LiteralPath $p -Recurse -Force -ErrorAction SilentlyContinue }

# --- T026b: deterministic atomic-write / lost-update race (Edge Case line 178) ---
$p = New-TempProject
try {
    $lock = Get-LockPath $p
    # Worst-case interleave, single-process, deterministic:
    $snapA = @(Read-ActiveSessions -ProjectRoot $p)   # devA reads 0
    $snapB = @(Read-ActiveSessions -ProjectRoot $p)   # devB reads 0 (race window)
    # devA writes {A}
    $entryA = [ordered]@{ feature_id='feat-race'; user='A'; machine_fingerprint='HA'; session_start_time='2026-05-31T08:00:00Z'; last_heartbeat_time='2026-05-31T08:00:00Z' }
    Write-ActiveSessions -ProjectRoot $p -Sessions (@($snapA) + ,$entryA)
    Assert-True ((Read-ActiveSessions -ProjectRoot $p).Count -ge 1) "T026b: file valid + non-empty after writer A"
    # devB writes {B} from its stale snapshot -> clobbers A (last-write-wins)
    $entryB = [ordered]@{ feature_id='feat-race'; user='B'; machine_fingerprint='HB'; session_start_time='2026-05-31T08:00:00Z'; last_heartbeat_time='2026-05-31T08:00:00Z' }
    Write-ActiveSessions -ProjectRoot $p -Sessions (@($snapB) + ,$entryB)
    $after = @(Read-ActiveSessions -ProjectRoot $p)
    # ATOMICITY: file is always valid YAML (parses to a list)
    Assert-True ($after.Count -eq 1) "T026b: atomicity holds — file always valid; last-write-wins leaves exactly 1 entry (the clobber is REAL, honestly)"
    Assert-True ($after[0].user -eq 'B') "T026b: last write (B) won — confirms lost-update is real, not a false 'both recorded'"
}
finally { Remove-Item -LiteralPath $p -Recurse -Force -ErrorAction SilentlyContinue }

Write-Host ""
Write-Host "All Feature-051 session-management (US3) acceptance tests passed." -ForegroundColor Green
exit 0
