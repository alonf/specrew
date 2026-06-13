[CmdletBinding()]
param()
Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

# F-174 iteration 011 (T006, FR-027 / decision f174-i011-verdict-authority-stop-hook): committed != authorized.
# Get-SpecrewPendingVerdictState reports whether the session's WORKING boundary (session_state.boundary_type,
# advanced mechanically by sync) is AHEAD of the last HUMAN-authorized boundary (boundary_enforcement.
# last_authorized_boundary, advanced ONLY by a captured human verdict). When it is, the crossing is AWAITING the
# human's verdict — the resume + `specrew where` surface it, never auto-advance, never imply approval. This is the
# honest-pending half of the floor (the falsification: a committed boundary is NOT reported as authorized).

function Write-Pass { param([string]$m) Write-Host "PASS: $m" -ForegroundColor Green }
function Fail { param([string]$m) Write-Host "FAIL: $m" -ForegroundColor Red; exit 1 }

$repoRoot = (Resolve-Path (Join-Path $PSScriptRoot '..\..')).Path
. (Join-Path $repoRoot 'extensions\specrew-speckit\scripts\shared-governance.ps1')

$scratch = Join-Path $repoRoot '.scratch\pending-verdict-surface'
if (Test-Path -LiteralPath $scratch) { Remove-Item -LiteralPath $scratch -Recurse -Force }

function New-Proj {
    param([string]$Working, [string]$LastAuth)
    $proj = Join-Path $scratch ([guid]::NewGuid().ToString('N'))
    New-Item -ItemType Directory -Path (Join-Path $proj '.specrew') -Force | Out-Null
    $ctx = [ordered]@{
        schema           = 'v2'
        feature_path     = (Join-Path $proj 'specs\046-test')
        session_state    = [ordered]@{
            active           = $true
            boundary_type    = $Working
            feature_ref      = '046-test'
            iteration_number = '001'
            recorded_at      = '2026-01-01T00:00:00Z'
        }
        boundary_enforcement = [ordered]@{
            enabled                  = $true
            last_authorized_boundary = $LastAuth
            pending_next_boundary    = $null
            verdict_history          = @()
            bypass_history           = @()
        }
    }
    [System.IO.File]::WriteAllText((Join-Path $proj '.specrew\start-context.json'), ($ctx | ConvertTo-Json -Depth 12), [System.Text.UTF8Encoding]::new($false))
    return $proj
}

try {
    # Case 1: working AHEAD of authorized -> pending (the DF-4/DF-5 honest state).
    $p1 = New-Proj -Working 'tasks' -LastAuth 'plan'
    $r1 = Get-SpecrewPendingVerdictState -ProjectRoot $p1
    if (-not $r1.HasPendingVerdict) { Fail "working 'tasks' ahead of authorized 'plan' MUST be pending" }
    if ($r1.WorkingBoundary -ne 'tasks') { Fail "WorkingBoundary expected 'tasks', got '$($r1.WorkingBoundary)'" }
    if ($r1.LastAuthorizedBoundary -ne 'plan') { Fail "LastAuthorizedBoundary expected 'plan', got '$($r1.LastAuthorizedBoundary)'" }
    if ($r1.Message -notmatch 'AWAITING YOUR VERDICT') { Fail "pending message must say AWAITING YOUR VERDICT" }
    if ($r1.Message -notmatch 'committed') { Fail "pending message must say the boundary is committed (not approved)" }
    Write-Pass "working ahead of authorized -> HasPendingVerdict + honest message ('tasks' committed, 'plan' authorized)"

    # Case 2: working EQUALS authorized -> NOT pending (no false alarm on a properly-authorized boundary).
    $p2 = New-Proj -Working 'plan' -LastAuth 'plan'
    $r2 = Get-SpecrewPendingVerdictState -ProjectRoot $p2
    if ($r2.HasPendingVerdict) { Fail "working == authorized MUST NOT be pending" }
    Write-Pass "working == authorized -> not pending (no false alarm)"

    # Case 3: NO authorized boundary yet, working at the first gate -> pending (committed != authorized from t=0).
    $p3 = New-Proj -Working 'specify' -LastAuth ''
    $r3 = Get-SpecrewPendingVerdictState -ProjectRoot $p3
    if (-not $r3.HasPendingVerdict) { Fail "working 'specify' with NO authorized boundary MUST be pending" }
    if ($r3.Message -notmatch 'none recorded yet') { Fail "no-authorized message must say '(none recorded yet)'" }
    Write-Pass "working with NO authorized boundary -> pending (committed != authorized from the start)"

    # Case 4: enforcement DISABLED -> never pending (the helper does not fabricate a pending state).
    $p4 = New-Proj -Working 'tasks' -LastAuth 'plan'
    $raw = Get-Content -LiteralPath (Join-Path $p4 '.specrew\start-context.json') -Raw | ConvertFrom-Json -AsHashtable -Depth 12
    $raw['boundary_enforcement']['enabled'] = $false
    [System.IO.File]::WriteAllText((Join-Path $p4 '.specrew\start-context.json'), ($raw | ConvertTo-Json -Depth 12), [System.Text.UTF8Encoding]::new($false))
    $r4 = Get-SpecrewPendingVerdictState -ProjectRoot $p4
    if ($r4.HasPendingVerdict) { Fail "enforcement disabled MUST NOT report pending (no fabricated state)" }
    Write-Pass "enforcement disabled -> not pending (helper never fabricates a pending state; fail-open)"

    # Case 5: `specrew where` WIRES the helper (leading awaiting alert + JSON payload).
    $whereSrc = Get-Content -LiteralPath (Join-Path $repoRoot 'scripts\specrew-where.ps1') -Raw
    if ($whereSrc -notmatch 'Get-SpecrewPendingVerdictState') { Fail "specrew-where must call Get-SpecrewPendingVerdictState" }
    if ($whereSrc -notmatch 'HasPendingVerdict') { Fail "specrew-where must lead with the awaiting alert when HasPendingVerdict" }
    if ($whereSrc -notmatch 'pending_verdict\s*=') { Fail "specrew-where JSON payload must include pending_verdict" }
    Write-Pass "specrew where wires Get-SpecrewPendingVerdictState (leading alert + JSON payload)"

    Write-Host "`n=== pending-verdict-surface.tests.ps1: all assertions passed ===" -ForegroundColor Green
    exit 0
}
finally {
    Remove-Item -LiteralPath $scratch -Recurse -Force -ErrorAction SilentlyContinue
}
