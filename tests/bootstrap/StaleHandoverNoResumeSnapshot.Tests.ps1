$ErrorActionPreference = 'Stop'

# F-174 iteration 010 (Prop-145 round-6, MEDIUM). FALSIFICATION floor for "a stale/invalid handover still drives
# resume-looking reconciliation". The bug: Invoke-SpecrewSessionBootstrap passed the RAW parsed handover into
# Get-SpecrewResumeReconciliation even when Test-SpecrewHandoverValidity said invalid, so the directive emitted
# "Last captured stop: <old timestamp> (boundary <old>)" + "READ those files ... THEN continue" off a STALE
# snapshot - conflicting with the spec's "invalid state is never authoritative resume truth". Worse, the stale
# REASON was never surfaced in validation_findings, so the human had no signal the snapshot was being ignored.
# Fix: pass the handover to reconciliation ONLY when valid; surface the invalid reason in validation_findings.

$base = "$PSScriptRoot/../../scripts/internal/bootstrap"
. "$base/HostEventAdapter.ps1"
. "$base/SessionStateAccessor.ps1"
. "$base/ProjectMetadataAccessor.ps1"
. "$base/HandoverStore.ps1"
. "$base/ClassificationEngine.ps1"
. "$base/ValidationEngine.ps1"
. "$base/DirectiveEngine.ps1"
. "$base/SessionBootstrapManager.ps1"

function Assert-True { param([bool]$Condition, [string]$Message) if (-not $Condition) { throw "FAIL: $Message" } ; Write-Host "PASS: $Message" -ForegroundColor Green }
function Assert-Equal { param([AllowNull()]$Actual, [AllowNull()]$Expected, [string]$Message) if ($Actual -ne $Expected) { throw "FAIL: $Message (expected '$Expected', got '$Actual')" } ; Write-Host "PASS: $Message" -ForegroundColor Green }

# Write a rolling handover file with a chosen recorded_at (the freshness lever) + feature/boundary.
function Write-Handover {
    param([string]$Root, [string]$RecordedAt, [string]$Feature = 'feat-x', [string]$Boundary = 'plan')
    $dir = Join-Path $Root '.specrew/handover'
    New-Item -ItemType Directory -Path $dir -Force | Out-Null
    $body = @(
        '---', 'schema: v1', 'source: stop', 'from_host: claude', "recorded_at: $RecordedAt",
        'from_commit: deadbee', "active_feature: $Feature", "active_boundary: $Boundary", '---', '',
        '# Session Handover (rolling)', '',
        '## What I just did', '', 'edited the planner', '',
        '## Recent conversation', '', 'discussed the gate', ''
    ) -join "`n"
    Set-Content -LiteralPath (Join-Path $dir 'session-handover.md') -Value $body -Encoding UTF8
}

$evt = '{"session_id":"sess-1","source":"startup","hook_event_name":"SessionStart"}'
$now = '2026-06-12T12:00:00Z'
$staleAt = '2026-06-01T12:00:00Z'   # 11 days old -> beyond the 24h freshness window
$freshAt = '2026-06-12T11:00:00Z'   # 1h old -> fresh

$root = Join-Path ([System.IO.Path]::GetTempPath()) ("specrew-staleho-" + [guid]::NewGuid().ToString('N'))
New-Item -ItemType Directory -Path (Join-Path $root 'specs/feat-x') -Force | Out-Null
# Hermetic: its own repo root (so Get-SpecrewSessionDelta scans THIS tiny tree, not the temp parent worktree).
& git -C $root init -q 2>$null | Out-Null
& git -C $root -c user.email='t@t' -c user.name='t' commit -q --allow-empty -m init 2>$null | Out-Null
try {
    # === STALE handover: must NOT drive a resume snapshot, and the reason MUST be surfaced. ===
    Write-Handover -Root $root -RecordedAt $staleAt
    $rs = Invoke-SpecrewSessionBootstrap -RawEvent $evt -HostName claude -ProjectRoot $root -StatePath (Join-Path $root 'absent.json') -NowUtc $now -BaseBranch 'main'

    Assert-Equal $rs.record.handover_valid $false 'stale handover is classified invalid'
    Assert-True ($null -eq $rs.directive.handover) 'stale handover is NOT surfaced in the directive (handover == null)'

    $recon = $rs.directive.reconciliation
    Assert-True ($null -ne $recon) 'reconciliation is still computed (current git delta) even with a stale handover'
    Assert-Equal $recon.last_stop_recorded_at '' 'reconciliation carries NO last-stop timestamp from the stale snapshot'
    Assert-Equal $recon.last_boundary '' 'reconciliation carries NO last-boundary from the stale snapshot'
    Assert-True (-not ($recon.directive_text -match 'Last captured stop')) 'the directive text omits "Last captured stop" for a stale handover'
    Assert-True (-not ($recon.directive_text -match [regex]::Escape($staleAt))) 'the stale timestamp never appears in the directive text'

    $findingsText = ($rs.directive.validation_findings -join ' | ')
    Assert-True ($findingsText -match 'freshness window') 'the STALE reason is surfaced in validation_findings (the human is told the snapshot was ignored)'

    # === FRESH control: a VALID handover MUST still drive the resume snapshot (no regression). ===
    Remove-Item -LiteralPath (Join-Path $root '.specrew/handover/session-handover.md.old') -Force -ErrorAction SilentlyContinue
    Write-Handover -Root $root -RecordedAt $freshAt
    $rf = Invoke-SpecrewSessionBootstrap -RawEvent $evt -HostName claude -ProjectRoot $root -StatePath (Join-Path $root 'absent.json') -NowUtc $now -BaseBranch 'main'

    Assert-Equal $rf.record.handover_valid $true 'fresh+present+unmerged handover is classified valid'
    Assert-True ($null -ne $rf.directive.handover) 'a VALID handover IS surfaced in the directive'
    $reconF = $rf.directive.reconciliation
    Assert-Equal $reconF.last_stop_recorded_at $freshAt 'a VALID handover seeds the last-stop timestamp into reconciliation'
    Assert-True ($reconF.directive_text -match 'Last captured stop') 'a VALID handover DOES emit "Last captured stop" (the feature is intact)'
    $findingsF = ($rf.directive.validation_findings -join ' | ')
    Assert-True (-not ($findingsF -match 'freshness window')) 'a VALID handover surfaces NO stale/ignored finding'
}
finally {
    Remove-Item -LiteralPath $root -Recurse -Force -ErrorAction SilentlyContinue
}
Write-Host "`n=== StaleHandoverNoResumeSnapshot.Tests.ps1: all assertions passed ===" -ForegroundColor Green
