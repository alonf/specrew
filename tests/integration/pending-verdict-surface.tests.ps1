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

    # FIXTURE REPAIR, T092 rework 3/3 (2026-08-06). This fixture used to write start-context.json into
    # a bare directory: no git repo, no feature, no crossing. That was sufficient while the
    # stage-evidence gate failed OPEN — an unverifiable stage was waved through and the awaiting-verdict
    # message survived. DRIFT-198-I011-003/-005 converted the gate to read evidence from the tree the
    # crossing is BOUND to, and to fail CLOSED when it cannot. Against the repaired gate this fixture
    # measured its own emptiness: no bound tree -> unverifiable -> the demand is suppressed and the
    # message becomes "BOUNDARY EVIDENCE COULD NOT BE VERIFIED", so `AWAITING YOUR VERDICT` was absent.
    #
    # THE FAILURE WAS THE FIX WORKING, NOT A DEFECT. The fixture now stands up a REAL COMMITTED feature
    # and a REAL crossing bound to that commit's tree, so the cases measure their actual subject
    # (committed != authorized) instead of the gate's unverifiable path.
    $proj = Join-Path $scratch ([guid]::NewGuid().ToString('N'))
    $featureDir = Join-Path $proj 'specs\046-test'
    $iterDir = Join-Path $featureDir 'iterations\001'
    New-Item -ItemType Directory -Path (Join-Path $proj '.specrew') -Force | Out-Null
    New-Item -ItemType Directory -Path $iterDir -Force | Out-Null

    # The evidence each exercised boundary owes: spec.md for `specify`, iterations/001/plan.md for
    # `plan` and `tasks`. spec.md carries a dated Clarifications session so the strict clarify row
    # (DRIFT-198-I011-006) is satisfied by structure rather than by a placeholder heading.
    Set-Content -LiteralPath (Join-Path $featureDir 'spec.md') -Encoding UTF8 `
        -Value "# Feature Specification: Test Feature`n`n## Clarifications`n`n### Session 2026-01-01 (clarify)`n`n- Q: Is the scope as written? -> A (human): yes.`n`n## Requirements`n`n- **FR-001**: System MUST do the thing."
    # The Tasks table carries the REAL columns the in-flight scan reads
    # (task-progress.ps1:181-187 projects Task/Title/Requirement/Story/Effort). A minimal two-column
    # table throws under StrictMode inside the bootstrap provider, which then fails OPEN and emits
    # nothing — presenting as "the awaiting block is missing" rather than as a broken fixture.
    Set-Content -LiteralPath (Join-Path $iterDir 'plan.md') -Encoding UTF8 `
        -Value "# Iteration Plan: 001`n`n**Status**: implementing`n`n## Tasks`n`n| Task | Title | Requirement | Story | Effort | Owner | Status |`n| --- | --- | --- | --- | --- | --- | --- |`n| T001 | Do the thing | FR-001 | US-1 | 2 | Implementer | pending |"

    $null = & git -C $proj init --quiet
    if ($LASTEXITCODE -ne 0) { Fail 'fixture git init failed' }
    $null = & git -C $proj config core.autocrlf false
    $null = & git -C $proj add -A
    $null = & git -C $proj -c user.name=Fixture -c user.email=fixture@example.invalid commit --quiet -m 'fixture feature'
    if ($LASTEXITCODE -ne 0) { Fail 'fixture baseline commit failed' }
    $commit = (@(& git -C $proj rev-parse HEAD) -join '').Trim()
    $tree = Get-SpecrewGitArtifactStateId -ProjectRoot $proj -BoundaryCommitHash $commit

    # A crossing exists ONLY when the working boundary is genuinely ahead of the authorized one — the
    # same condition this file's subject reports on. Built through the REAL identity helper: the
    # crossing_id is a hash over the crossing's fields and the artifact_state_id is re-derived from
    # the commit, so a hand-written record would be rejected as an integrity mismatch.
    $crossing = $null
    if ($Working -ne $LastAuth) {
        $crossing = New-SpecrewBoundaryCrossingIdentity `
            -FromBoundary $(if ([string]::IsNullOrWhiteSpace($LastAuth)) { 'intake' } else { $LastAuth }) `
            -ToBoundary $Working -WorkingBoundary $Working `
            -BoundaryCommitHash $commit -ArtifactStateId $tree -RecordedAt '2026-01-01T00:00:00Z'
    }

    $ctx = [ordered]@{
        schema           = 'v2'
        feature_path     = $featureDir
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
            pending_crossing         = $crossing
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
    if ($r1.PendingFromMarkerBoundary -ne 'plan' -or $r1.PendingToMarkerBoundary -ne 'tasks') { Fail "pending crossing expected plan -> tasks, got '$($r1.PendingFromMarkerBoundary)' -> '$($r1.PendingToMarkerBoundary)'" }
    if ($r1.Message -notmatch 'AWAITING YOUR VERDICT') { Fail "pending message must say AWAITING YOUR VERDICT" }
    # The fixture now carries a REAL crossing, so this takes the SCOPED branch, whose message names the
    # crossing, its commit and its tree and says the crossing is "NOT human-authorized" — where the
    # legacy-unscoped branch said "is committed / in-progress but NOT human-authorized". The original
    # assertion matched the literal word "committed" and so was branch-specific, not intent-specific.
    # The INTENT is what must hold on both: the message states the boundary is NOT authorized and never
    # implies approval. Asserted across both wordings rather than relaxed to "any message".
    if ($r1.Message -notmatch 'NOT human-authorized') { Fail "pending message must state the boundary is NOT human-authorized (committed != approved)" }
    if ($r1.Message -match '(?i)\bapproved for tasks\b(?!'')' -and $r1.Message -notmatch "verdict 'approved for tasks'") { Fail "pending message must not read as though the boundary were already approved" }
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
    if ($r3.PendingFromMarkerBoundary -ne 'intake' -or $r3.PendingToMarkerBoundary -ne 'specify') { Fail "first pending crossing expected intake -> specify, got '$($r3.PendingFromMarkerBoundary)' -> '$($r3.PendingToMarkerBoundary)'" }
    if (-not $r3.IsFirstBoundary) { Fail "first pending crossing must set IsFirstBoundary" }
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

    # Case 6: the BOOTSTRAP RESUME DIRECTIVE surfaces the AWAITING block when (and only when) pending (T006 part
    # 2). Extract just Format-BootstrapDirective from the provider (the script's top-level body must not run) and
    # exercise its PendingVerdict branch directly.
    $provSrc = Get-Content -LiteralPath (Join-Path $repoRoot 'scripts\internal\specrew-bootstrap-provider.ps1') -Raw
    $fnMatch = [regex]::Match($provSrc, "(?s)^function Format-BootstrapDirective \{.*?\n\}", [System.Text.RegularExpressions.RegexOptions]::Multiline)
    if (-not $fnMatch.Success) { Fail "could not extract Format-BootstrapDirective from the provider" }
    . ([scriptblock]::Create($fnMatch.Value))
    $fakeResult = [pscustomobject]@{ directive = [pscustomobject]@{ mode = 'resume'; required_reads = @('.specrew/last-start-prompt.md', '.specrew/start-context.json'); validation_findings = @() } }
    $pending = [pscustomobject]@{ HasPendingVerdict = $true; WorkingBoundary = 'tasks'; LastAuthorizedBoundary = 'plan'; Message = "AWAITING YOUR VERDICT: 'tasks' is committed / in-progress but NOT human-authorized (last authorized: plan)." }
    $directiveWhenPending = Format-BootstrapDirective -Result $fakeResult -ContractBody '' -InFlight $null -PendingVerdict $pending
    if ($directiveWhenPending -notmatch 'AWAITING YOUR VERDICT \(committed != authorized') { Fail "resume directive MUST surface the awaiting-verdict block when pending" }
    if ($directiveWhenPending -notmatch 'do NOT advance the lifecycle on it') { Fail "resume directive MUST instruct the agent not to advance on a committed-but-unauthorized boundary" }
    $directiveNotPending = Format-BootstrapDirective -Result $fakeResult -ContractBody '' -InFlight $null -PendingVerdict ([pscustomobject]@{ HasPendingVerdict = $false; Message = $null })
    if ($directiveNotPending -match 'AWAITING YOUR VERDICT \(committed') { Fail "resume directive must NOT surface awaiting-verdict when not pending (no false alarm)" }
    $directiveNullPending = Format-BootstrapDirective -Result $fakeResult -ContractBody '' -InFlight $null -PendingVerdict $null
    if ($directiveNullPending -match 'AWAITING YOUR VERDICT \(committed') { Fail "resume directive must tolerate a null PendingVerdict (fail-open, no block)" }
    Write-Pass "bootstrap resume directive surfaces the awaiting-verdict block when pending, stays silent otherwise, tolerates null (T006 part 2)"

    # Case 7/8 (review-signoff P6-002): prove the REAL compute->render integration, not just the isolated renderer
    # + a source-grep. Stand up a scratch project and run the REAL specrew-bootstrap-provider.ps1, asserting the
    # emitted directive surfaces (or omits) the AWAITING block — this catches a regression that broke the provider's
    # call to Get-SpecrewPendingVerdictState or the pass-through into Format-BootstrapDirective (which cases 5-6 miss).
    $provider = Join-Path $repoRoot 'scripts\internal\specrew-bootstrap-provider.ps1'
    # stderr is CAPTURED, not discarded. The provider fails OPEN by design: on an internal fault it
    # warns and emits nothing. With `2>$null` that fault was indistinguishable from a correct decision
    # to stay silent, so a broken provider read as "the awaiting block is missing" — the same
    # two-outcome conflation the fr066/fr068 harnesses guard against with INCONCLUSIVE. A fault is now
    # reported as a fault.
    $p7 = New-Proj -Working 'tasks' -LastAuth 'plan'
    $out7 = (& pwsh -NoProfile -ExecutionPolicy Bypass -File $provider --event-json '{"source":"startup","session_id":"pv-real-7"}' --project-root $p7 2>&1) -join "`n"
    if ($out7 -match 'PROVIDER_FAILED') { Fail "the provider FAULTED rather than deciding — this measures nothing about the awaiting surface: $(($out7 -replace '\s+', ' ').Trim())" }
    if ($out7 -notmatch 'AWAITING YOUR VERDICT \(committed != authorized') { Fail "real provider must surface the AWAITING block when committed != authorized (working 'tasks' > authorized 'plan')" }
    Write-Pass "real provider end-to-end: committed != authorized surfaces the AWAITING block (compute->render integration, not the isolated renderer)"

    $p8 = New-Proj -Working 'plan' -LastAuth 'plan'
    $out8 = (& pwsh -NoProfile -ExecutionPolicy Bypass -File $provider --event-json '{"source":"startup","session_id":"pv-real-8"}' --project-root $p8 2>&1) -join "`n"
    if ($out8 -match 'AWAITING YOUR VERDICT \(committed != authorized') { Fail "real provider must NOT surface the AWAITING block when working == authorized (no false alarm)" }
    Write-Pass "real provider end-to-end: working == authorized does NOT surface the AWAITING block (no false alarm)"

    Write-Host "`n=== pending-verdict-surface.tests.ps1: all assertions passed ===" -ForegroundColor Green
    exit 0
}
finally {
    Remove-Item -LiteralPath $scratch -Recurse -Force -ErrorAction SilentlyContinue
}
