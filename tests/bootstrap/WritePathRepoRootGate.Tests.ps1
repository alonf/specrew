$ErrorActionPreference = 'Stop'

# F-174 iteration 010 (Prop-145 round-6, HIGH - write-path half of Finding 1). The reviewer's Finding 1 was the
# resume/read path (Get-SpecrewSessionDelta, once per session-start). The advisor flagged the same defect class in
# the HOTTER path: Update-SpecrewRollingHandover's material-change gate runs an inline `git status --porcelain`
# on EVERY PostToolUse. Without a repo-root check, from a nested / non-repo project root under a parent git repo
# or worktree that scan walks the WHOLE parent tree (unbounded -> the hook hangs on the first file-editing turn)
# AND reports the PARENT'S dirty files as this project's change. This pins the gate: a PostToolUse from a nested
# root with a DIRTY PARENT must NOT scan the parent (wrote=false, no-material-change), while the repo root still
# scans + writes on a real change.

$base = "$PSScriptRoot/../../scripts/internal/bootstrap"
. "$base/HandoverStore.ps1"
. "$base/ClassificationEngine.ps1"
. "$base/ProjectMetadataAccessor.ps1"
. "$base/ConversationCaptureAccessor.ps1"

function Assert-True { param([bool]$Condition, [string]$Message) if (-not $Condition) { throw "FAIL: $Message" } ; Write-Host "PASS: $Message" -ForegroundColor Green }
function Assert-Equal { param([AllowNull()]$Actual, [AllowNull()]$Expected, [string]$Message) if ($Actual -ne $Expected) { throw "FAIL: $Message (expected '$Expected', got '$Actual')" } ; Write-Host "PASS: $Message" -ForegroundColor Green }

# Seed an EXISTING handover under $Root so HandoverExists=true (first-write is always 'material'; we need the
# gate to depend ONLY on the tracked-change signal). No start-context.json -> CurrentBoundary stays $null ->
# the boundary-moved branch is skipped, so the inline `git status` is the sole material lever.
function Seed-Handover {
    param([string]$Root)
    $dir = Join-Path $Root '.specrew/handover'
    New-Item -ItemType Directory -Path $dir -Force | Out-Null
    $body = @(
        '---', 'schema: v1', 'source: stop', 'from_host: claude', 'recorded_at: 2026-06-12T11:00:00Z',
        'from_commit: deadbee', 'active_feature: ', 'active_boundary: ', '---', '',
        '# Session Handover (rolling)', '', '## What I just did', '', 'prior bullet', ''
    ) -join "`n"
    Set-Content -LiteralPath (Join-Path $dir 'session-handover.md') -Value $body -Encoding UTF8
}

$repo = Join-Path ([System.IO.Path]::GetTempPath()) ("specrew-wpgate-" + [guid]::NewGuid().ToString('N'))
New-Item -ItemType Directory -Path $repo -Force | Out-Null
try {
    & git -C $repo init -q 2>$null | Out-Null
    Set-Content -LiteralPath (Join-Path $repo 'seed.txt') -Value 'seed' -Encoding UTF8
    & git -C $repo add -A 2>$null | Out-Null
    & git -C $repo -c user.email='t@t' -c user.name='t' commit -q -m init 2>$null | Out-Null
    # The bait: a DIRTY file at the parent repo root. A nested-root scan that reaches the parent sees this.
    Set-Content -LiteralPath (Join-Path $repo 'dirty-at-root.txt') -Value 'x' -Encoding UTF8

    # === NESTED root: the gate must skip the scan -> wrote=false despite the dirty parent. ===
    $nested = Join-Path $repo 'sub/proj'
    New-Item -ItemType Directory -Path $nested -Force | Out-Null
    Seed-Handover -Root $nested
    $rn = Update-SpecrewRollingHandover -ProjectRoot $nested -HostKind claude -Source 'PostToolUse' -NowUtc '2026-06-12T12:00:00Z'
    Assert-Equal $rn.wrote $false 'NESTED root + PostToolUse: no write (the parent tree is NOT scanned for tracked changes)'
    Assert-Equal $rn.reason 'no-material-change' 'NESTED root: the material gate saw NO tracked change (the parent dirty file was never counted)'

    # === Repo ROOT: the gate passes -> the real scan runs and a real local change drives a write. ===
    Seed-Handover -Root $repo
    $rr = Update-SpecrewRollingHandover -ProjectRoot $repo -HostKind claude -Source 'PostToolUse' -NowUtc '2026-06-12T12:05:00Z'
    Assert-Equal $rr.wrote $true 'repo ROOT + PostToolUse: the real scan runs and the local change drives a write (no regression)'
    Assert-Equal $rr.reason 'tracked-change' 'repo ROOT: the write reason is the detected tracked change'
}
finally {
    Remove-Item -LiteralPath $repo -Recurse -Force -ErrorAction SilentlyContinue
}
Write-Host "`n=== WritePathRepoRootGate.Tests.ps1: all assertions passed ===" -ForegroundColor Green
