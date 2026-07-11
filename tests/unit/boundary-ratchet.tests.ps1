# Paired honesty tests for the F-198 iteration-002 governance core (FR-001..FR-005,
# NFR-007): the ratchet refuses abuse AND permits the legitimate paths; the cycle-reset
# pending crossing works; retroactive authorizations are recorded distinctly and are
# idempotent on re-fire. Fixtures use TEMP project roots only (hardening-gate
# condition-b: never this session's live .specrew state).
#
# The FR-003 validator branch (skipped-boundary-unreconciled) shares its input fields
# with the standing state-advance-without-verdict check inside validate-governance.ps1
# and is exercised there; this file covers the shared primitive both consume.

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

$repoRoot = (Resolve-Path (Join-Path $PSScriptRoot '..\..')).Path
. (Join-Path $repoRoot 'extensions\specrew-speckit\scripts\shared-governance.ps1')
$script:failCount = 0

function Write-Pass { param([string]$Message) Write-Host "PASS: $Message" -ForegroundColor Green }
function Write-Fail { param([string]$Message) Write-Host "FAIL: $Message" -ForegroundColor Red; $script:failCount++ }

function New-RatchetFixture {
    param(
        [string]$WorkingBoundary,
        [string]$LastAuthorized,
        [object[]]$History = @()
    )
    $root = Join-Path ([System.IO.Path]::GetTempPath()) ("ratchet-fixture-{0}" -f [guid]::NewGuid().ToString('N').Substring(0, 8))
    New-Item -ItemType Directory -Force -Path (Join-Path $root '.specrew') | Out-Null
    $context = [ordered]@{
        schema = 'v2'
        boundary_enforcement = [ordered]@{
            enabled = $true
            last_authorized_boundary = $LastAuthorized
            pending_next_boundary = $null
            policy_classes = [ordered]@{
                specify = 'human-judgment-required'; clarify = 'human-judgment-required'
                plan = 'human-judgment-required'; tasks = 'human-judgment-required'
                'before-implement' = 'human-judgment-required'; 'review-signoff' = 'human-judgment-required'
                retro = 'human-judgment-required'; 'iteration-closeout' = 'human-judgment-required'
                'feature-closeout' = 'human-judgment-required'
            }
            verdict_history = @($History)
            bypass_history = @()
        }
        generated_at_utc = '2026-07-11T00:00:00Z'
        session_state = [ordered]@{
            active = $true
            boundary_type = $WorkingBoundary
            feature_ref = 'fixture-feature'
            iteration_number = '001'
            auth_commit_hash = 'aaaaaaaa'
            recorded_at = '2026-07-11T00:00:00Z'
        }
    }
    $context | ConvertTo-Json -Depth 10 | Set-Content -LiteralPath (Join-Path $root '.specrew\start-context.json') -Encoding UTF8
    $root
}

function New-HistoryEntry {
    param([string]$From, [string]$To, [string]$Hash = 'bbbbbbbb1234')
    [ordered]@{
        from_boundary = $From; to_boundary = $To
        verdict_text = "approved for $To"; authorizing_human = 'unattributed'
        recorded_at = '2026-07-11T00:00:00Z'; auth_commit_hash = $Hash
        evidence_source = 'hook-captured-from-transcript'; kind = 'standard'
    }
}

Write-Host "Test 1: authorized working boundary -> clean (no unreconciled state)"
$fx = New-RatchetFixture -WorkingBoundary 'plan' -LastAuthorized 'plan' -History @(New-HistoryEntry -From 'clarify' -To 'plan')
$un = Get-SpecrewUnreconciledBoundary -ProjectRoot $fx
if ($null -ne $un) { Write-Fail "expected clean, got unreconciled '$($un.Boundary)'" } else { Write-Pass "authorized crossing reads clean" }
$gate = Invoke-SpecrewBoundaryRatchetGate -ProjectRoot $fx -RequestedBoundary 'tasks'
if ($gate -ne $true) { Write-Fail "gate should pass on a clean state" } else { Write-Pass "gate passes the next advance on a clean state" }
Remove-Item -Recurse -Force $fx

Write-Host "Test 2: unauthorized crossing detected with the revert anchor"
$fx = New-RatchetFixture -WorkingBoundary 'tasks' -LastAuthorized 'plan' -History @(New-HistoryEntry -From 'clarify' -To 'plan' -Hash 'cafecafe9999')
$un = Get-SpecrewUnreconciledBoundary -ProjectRoot $fx
if ($null -eq $un -or $un.Boundary -ne 'tasks' -or $un.RevertAnchor -ne 'cafecafe9999') { Write-Fail "expected unreconciled 'tasks' with anchor cafecafe9999, got: $($un | ConvertTo-Json -Compress)" }
else { Write-Pass "unauthorized 'tasks' detected; revert anchor is the newest authorized commit" }

Write-Host "Test 3: re-sync of the SAME unauthorized boundary passes (idempotent re-record, F-174)"
$gate = Invoke-SpecrewBoundaryRatchetGate -ProjectRoot $fx -RequestedBoundary 'tasks'
if ($gate -ne $true) { Write-Fail "same-boundary re-sync must pass" } else { Write-Pass "same-boundary re-sync passes" }

Write-Host "Test 4: a SECOND advance refuses loudly, consumer-legible (paired: abuse fails)"
$threw = $false
try { Invoke-SpecrewBoundaryRatchetGate -ProjectRoot $fx -RequestedBoundary 'before-implement' | Out-Null }
catch {
    $threw = $true
    $msg = $_.Exception.Message
    if ($msg -notmatch "'tasks'" -or $msg -notmatch "'before-implement'") { Write-Fail "refusal must name both boundaries: $msg" }
    elseif ($msg -notmatch 'approve or decline' -or $msg -notmatch 'roll back' -or $msg -notmatch 'cafecafe') { Write-Fail "refusal must teach both doors + the anchor: $msg" }
    elseif ($msg -match 'T0\d\d|F-19\d|proposal|FR-\d|D-19|SPECREW-VERDICT') { Write-Fail "refusal leaks internal identifiers: $msg" }
    else { Write-Pass "second advance refused; message names both boundaries, both doors, the anchor, zero internal identifiers" }
}
if (-not $threw) { Write-Fail "second advance did not throw" }
Remove-Item -Recurse -Force $fx

Write-Host "Test 5: non-canonical and non-judgment working boundaries never latch"
$fx = New-RatchetFixture -WorkingBoundary 'implement' -LastAuthorized 'before-implement' -History @(New-HistoryEntry -From 'tasks' -To 'before-implement')
$un = Get-SpecrewUnreconciledBoundary -ProjectRoot $fx
if ($null -ne $un) { Write-Fail "a non-canonical alias (implement) must not latch" } else { Write-Pass "non-canonical alias (implement) does not latch or crash the ratchet" }
Remove-Item -Recurse -Force $fx
$fx = New-RatchetFixture -WorkingBoundary 'clarify' -LastAuthorized 'specify' -History @(New-HistoryEntry -From $null -To 'specify')
@(
    'boundary_enforcement:'
    '  policy_classes:'
    '    clarify: future-policy'
) | Set-Content (Join-Path $fx '.specrew\config.yml') -Encoding UTF8
$un = Get-SpecrewUnreconciledBoundary -ProjectRoot $fx
if ($null -ne $un) { Write-Fail "a non-human-judgment-classed boundary must not latch, got: $($un | ConvertTo-Json -Compress)" } else { Write-Pass "non-human-judgment-classed boundary (clarify, future-policy via config.yml - the real policy seam) does not latch the ratchet" }
Remove-Item -Recurse -Force $fx

Write-Host "Test 6: cycle reset - pending crossing for a new iteration (field bug, 2026-07-11)"
$pc = Get-SpecrewPendingBoundaryCrossing -LastAuthorizedBoundary 'iteration-closeout' -WorkingBoundary 'plan'
if (-not $pc.HasPendingVerdict -or $pc.PendingFromBoundary -ne 'iteration-closeout' -or $pc.PendingToBoundary -ne 'plan') { Write-Fail "cycle reset must yield iteration-closeout -> plan, got: $($pc | ConvertTo-Json -Compress)" }
else { Write-Pass "iteration-closeout -> plan pending crossing exists for the new cycle" }
$pc2 = Get-SpecrewPendingBoundaryCrossing -LastAuthorizedBoundary 'iteration-closeout' -WorkingBoundary 'before-implement'
if (-not $pc2.HasPendingVerdict -or $pc2.PendingToBoundary -ne 'plan' -or -not $pc2.IsMultiBoundaryGap) { Write-Fail "deep new-cycle working boundary must ask plan first with a multi-gap flag, got: $($pc2 | ConvertTo-Json -Compress)" }
else { Write-Pass "deep new-cycle crossing asks the earliest cycle boundary first (multi-gap flagged)" }

Write-Host "Test 7: cycle-reset authorization does not throw backward + records kind"
$fx = New-RatchetFixture -WorkingBoundary 'plan' -LastAuthorized 'iteration-closeout' -History @(New-HistoryEntry -From 'retro' -To 'iteration-closeout')
Add-SpecrewBoundaryAuthorization -ProjectRoot $fx -CurrentBoundary 'iteration-closeout' -AuthorizedBoundary 'plan' -AuthorizingHuman 'fixture-human' -VerdictText 'approved for plan' -AuthCommitHash 'dddddddd' -EvidenceSource 'human-confirmed-at-resume' -Kind 'retroactive' | Out-Null
$state = Get-Content (Join-Path $fx '.specrew\start-context.json') -Raw | ConvertFrom-Json
$newest = @($state.boundary_enforcement.verdict_history)[-1]
if ($newest.to_boundary -ne 'plan' -or $newest.kind -ne 'retroactive') { Write-Fail "cycle-reset authorization must record to=plan kind=retroactive, got: $($newest | ConvertTo-Json -Compress)" }
else { Write-Pass "iteration-closeout -> plan authorization recorded with kind=retroactive (no backward throw)" }

Write-Host "Test 8: re-fired authorization for the cursor boundary is a no-op (no duplicate entry)"
$countBefore = @((Get-Content (Join-Path $fx '.specrew\start-context.json') -Raw | ConvertFrom-Json).boundary_enforcement.verdict_history).Count
Add-SpecrewBoundaryAuthorization -ProjectRoot $fx -CurrentBoundary 'iteration-closeout' -AuthorizedBoundary 'plan' -AuthorizingHuman 'fixture-human' -VerdictText 'approved for plan' -EvidenceSource 'human-confirmed-at-resume' -Kind 'retroactive' | Out-Null
$countAfter = @((Get-Content (Join-Path $fx '.specrew\start-context.json') -Raw | ConvertFrom-Json).boundary_enforcement.verdict_history).Count
if ($countAfter -ne $countBefore) { Write-Fail "re-fired authorization appended a duplicate ($countBefore -> $countAfter)" } else { Write-Pass "re-fired authorization is a no-op" }
Remove-Item -Recurse -Force $fx

Write-Host "Test 9: primitive purity - same inputs, same answer"
$fx = New-RatchetFixture -WorkingBoundary 'tasks' -LastAuthorized 'plan' -History @(New-HistoryEntry -From 'clarify' -To 'plan')
$a = Get-SpecrewUnreconciledBoundary -ProjectRoot $fx
$b = Get-SpecrewUnreconciledBoundary -ProjectRoot $fx
if (($a | ConvertTo-Json -Compress) -ne ($b | ConvertTo-Json -Compress)) { Write-Fail "primitive is not pure" } else { Write-Pass "primitive returns identical results on identical state" }
Remove-Item -Recurse -Force $fx

Write-Host "Test 10: DEC-198-GOV-002 regression - a PRIOR cycle's same-named approval must not reconcile this cycle's crossing"
# The exact field shape (2026-07-11): iteration 001 closed with an authorized retro,
# the cycle reset into 002, 002 advanced to review-signoff, and its retro crossing was
# recorded but NOT yet human-authorized. The name-matching scan let 001's retro entry
# satisfy 002's retro, and the closeout sync passed a gate that had to refuse.
$fieldHistory = @(
    (New-HistoryEntry -From 'before-implement' -To 'review-signoff' -Hash 'c0c0c0c00001'),
    (New-HistoryEntry -From 'review-signoff' -To 'retro' -Hash 'c0c0c0c00002'),
    (New-HistoryEntry -From 'retro' -To 'iteration-closeout' -Hash 'c0c0c0c00003'),
    (New-HistoryEntry -From 'iteration-closeout' -To 'plan' -Hash 'c0c0c0c00004'),
    (New-HistoryEntry -From 'plan' -To 'tasks' -Hash 'c0c0c0c00005'),
    (New-HistoryEntry -From 'tasks' -To 'before-implement' -Hash 'c0c0c0c00006'),
    (New-HistoryEntry -From 'before-implement' -To 'review-signoff' -Hash 'c0c0c0c00007')
)
$fx = New-RatchetFixture -WorkingBoundary 'retro' -LastAuthorized 'review-signoff' -History $fieldHistory
$un = Get-SpecrewUnreconciledBoundary -ProjectRoot $fx
if ($null -eq $un -or $un.Boundary -ne 'retro') { Write-Fail "prior-cycle retro entry reconciled the current crossing (cycle-blind), got: $($un | ConvertTo-Json -Compress)" }
else { Write-Pass "current-cycle retro stays unreconciled despite the prior cycle's same-named approval" }
$threw = $false
try { Invoke-SpecrewBoundaryRatchetGate -ProjectRoot $fx -RequestedBoundary 'iteration-closeout' | Out-Null }
catch { $threw = $true; if ($_.Exception.Message -notmatch "'retro'" -or $_.Exception.Message -notmatch "'iteration-closeout'") { Write-Fail "refusal must name both boundaries: $($_.Exception.Message)" } else { Write-Pass "the closeout advance refuses while the current-cycle retro awaits its verdict (the field sequence, now caught)" } }
if (-not $threw) { Write-Fail "the closeout advance passed over an unreconciled current-cycle retro (the field failure reproduced)" }
Remove-Item -Recurse -Force $fx

Write-Host "Test 11: same-cycle reconciliation still works, incl. a lagging cursor (paired: legitimate path passes)"
$sameCycle = $fieldHistory + @(New-HistoryEntry -From 'review-signoff' -To 'retro' -Hash 'c0c0c0c00008')
$fx = New-RatchetFixture -WorkingBoundary 'retro' -LastAuthorized 'review-signoff' -History $sameCycle
$un = Get-SpecrewUnreconciledBoundary -ProjectRoot $fx
if ($null -ne $un) { Write-Fail "a same-cycle retro authorization (after the cycle-reset edge) must reconcile even with a lagging cursor, got: $($un | ConvertTo-Json -Compress)" }
else { Write-Pass "same-cycle authorization reconciles; lagging-cursor defensive read preserved" }
$gate = Invoke-SpecrewBoundaryRatchetGate -ProjectRoot $fx -RequestedBoundary 'iteration-closeout'
if ($gate -ne $true) { Write-Fail "gate should pass once the current-cycle crossing is reconciled" } else { Write-Pass "gate passes the closeout advance after same-cycle reconciliation" }
Remove-Item -Recurse -Force $fx

Write-Host "Test 12: unreadable ledger identity fails CLOSED - loud hard fail, never silent-clean (paired: abuse cannot fail open)"
$corrupt = $fieldHistory + @(New-HistoryEntry -From 'review-signoff' -To 'not-a-boundary' -Hash 'c0c0c0c00009')
$fx = New-RatchetFixture -WorkingBoundary 'retro' -LastAuthorized 'review-signoff' -History $corrupt
$threw = $false
try { Get-SpecrewUnreconciledBoundary -ProjectRoot $fx | Out-Null }
catch {
    $threw = $true
    if ($_.Exception.Message -notmatch 'ledger' -or $_.Exception.Message -notmatch 'not-a-boundary') { Write-Fail "the hard fail must name the ledger and the offending value: $($_.Exception.Message)" }
    elseif ($_.Exception.Message -match 'T0\d\d|F-19\d|proposal|FR-\d') { Write-Fail "the hard fail leaks internal identifiers: $($_.Exception.Message)" }
    else { Write-Pass "unreadable ledger identity hard-fails loud, naming the offending value, zero internal identifiers" }
}
if (-not $threw) { Write-Fail "unreadable ledger identity was read as clean (fail open) - the pre-fix behavior" }
$threw = $false
try { Invoke-SpecrewBoundaryRatchetGate -ProjectRoot $fx -RequestedBoundary 'iteration-closeout' | Out-Null }
catch { $threw = $true }
if (-not $threw) { Write-Fail "the ratchet gate passed on an unreadable ledger (fail open)" } else { Write-Pass "the ratchet gate refuses to advance over an unreadable ledger" }
Remove-Item -Recurse -Force $fx

Write-Host "Test 13: live gate (Test-SpecrewBoundaryAuthorization) is cycle-scoped - the run-2594b7b5 reviewer repro"
# The reviewer's exact live repro: cursor=iteration-closeout (cycle closed, nothing since),
# a single prior-cycle clarify->plan entry with a human. The gate authorized it (name match
# across unscoped history). It must BLOCK: a closed cycle authorizes nothing further.
$fx = New-RatchetFixture -WorkingBoundary 'plan' -LastAuthorized 'iteration-closeout' -History @(New-HistoryEntry -From 'clarify' -To 'plan' -Hash 'a1a1a1a10001')
$auth = Test-SpecrewBoundaryAuthorization -ProjectRoot $fx -CurrentBoundary 'clarify' -RequestedBoundary 'plan'
if ([bool]$auth.Authorized) { Write-Fail "prior-cycle clarify->plan entry authorized the new cycle's crossing (the reviewer's live repro, cycle-blind)" }
else { Write-Pass "closed-cycle cursor blocks the prior-cycle name match (Decision: $($auth.Decision))" }
Remove-Item -Recurse -Force $fx
# Paired legitimate path: the same-cycle authorization (the cycle-reset edge itself) authorizes.
$fx = New-RatchetFixture -WorkingBoundary 'plan' -LastAuthorized 'plan' -History @(
    (New-HistoryEntry -From 'retro' -To 'iteration-closeout' -Hash 'a1a1a1a10002'),
    (New-HistoryEntry -From 'iteration-closeout' -To 'plan' -Hash 'a1a1a1a10003')
)
$auth = Test-SpecrewBoundaryAuthorization -ProjectRoot $fx -CurrentBoundary 'iteration-closeout' -RequestedBoundary 'plan'
if (-not [bool]$auth.Authorized) { Write-Fail "the current cycle's own reset-edge authorization must authorize, got Decision: $($auth.Decision)" }
else { Write-Pass "the same-cycle reset-edge authorization authorizes the gate" }
Remove-Item -Recurse -Force $fx

Write-Host "Test 14: first crossing of a NEW cycle - no reset edge recorded yet, prior cycle cannot leak forward"
# History ends at the prior cycle's closeout (no iteration-closeout->plan edge exists yet).
# The primitive must report the new cycle's plan crossing unreconciled even though a
# prior-cycle plan entry exists further back.
$fx = New-RatchetFixture -WorkingBoundary 'plan' -LastAuthorized 'iteration-closeout' -History @(
    (New-HistoryEntry -From 'clarify' -To 'plan' -Hash 'b2b2b2b20001'),
    (New-HistoryEntry -From 'plan' -To 'tasks' -Hash 'b2b2b2b20002'),
    (New-HistoryEntry -From 'retro' -To 'iteration-closeout' -Hash 'b2b2b2b20003')
)
$un = Get-SpecrewUnreconciledBoundary -ProjectRoot $fx
if ($null -eq $un -or $un.Boundary -ne 'plan') { Write-Fail "first-crossing-of-new-cycle must stay unreconciled, got: $($un | ConvertTo-Json -Compress)" }
else { Write-Pass "new-cycle first crossing stays unreconciled; the prior cycle's plan entry cannot leak forward" }
Remove-Item -Recurse -Force $fx

Write-Host "Test 15: prior cycle's closeout entry cannot reconcile the current cycle's closeout crossing"
# Mid-cycle entries exist for the current cycle, its closeout is unauthorized; the prior
# cycle's retro->iteration-closeout entry sits further back. The closeout-terminator rule
# must stop the walk instead of matching across the cycle edge.
$fx = New-RatchetFixture -WorkingBoundary 'iteration-closeout' -LastAuthorized 'retro' -History @(
    (New-HistoryEntry -From 'retro' -To 'iteration-closeout' -Hash 'c3c3c3c30001'),
    (New-HistoryEntry -From 'iteration-closeout' -To 'plan' -Hash 'c3c3c3c30002'),
    (New-HistoryEntry -From 'plan' -To 'tasks' -Hash 'c3c3c3c30003'),
    (New-HistoryEntry -From 'review-signoff' -To 'retro' -Hash 'c3c3c3c30004')
)
$un = Get-SpecrewUnreconciledBoundary -ProjectRoot $fx
if ($null -eq $un -or $un.Boundary -ne 'iteration-closeout') { Write-Fail "the prior cycle's closeout entry reconciled the current closeout crossing, got: $($un | ConvertTo-Json -Compress)" }
else { Write-Pass "current-cycle closeout stays unreconciled; the prior cycle's closeout entry stops the walk" }
# Paired legitimate path: the current cycle's own closeout authorization reconciles.
$fx2 = New-RatchetFixture -WorkingBoundary 'iteration-closeout' -LastAuthorized 'iteration-closeout' -History @(
    (New-HistoryEntry -From 'iteration-closeout' -To 'plan' -Hash 'c3c3c3c30005'),
    (New-HistoryEntry -From 'plan' -To 'tasks' -Hash 'c3c3c3c30006'),
    (New-HistoryEntry -From 'retro' -To 'iteration-closeout' -Hash 'c3c3c3c30007')
)
$un2 = Get-SpecrewUnreconciledBoundary -ProjectRoot $fx2
if ($null -ne $un2) { Write-Fail "the current cycle's own closeout authorization must reconcile, got: $($un2 | ConvertTo-Json -Compress)" }
else { Write-Pass "the current cycle's own closeout authorization reconciles" }
Remove-Item -Recurse -Force $fx, $fx2

Write-Host ""
if ($script:failCount -gt 0) { Write-Host "$script:failCount test(s) FAILED" -ForegroundColor Red; exit 1 }
Write-Host "All boundary-ratchet paired tests passed." -ForegroundColor Green
exit 0
