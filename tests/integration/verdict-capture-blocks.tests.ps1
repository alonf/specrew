[CmdletBinding()]
param()
Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

# F-174 iteration 011 (T004 building blocks): the conservative human-verdict recognizer
# (Test-SpecrewHumanVerdictToken) + the evidence-source tag on Add-SpecrewBoundaryAuthorization. SAFETY RULE
# (the maintainer's): only a CLEAR approval counts; anything negated / send-back / discuss / ambiguous / a bare
# question falls to NOT-approval so the caller records the crossing un-authorized rather than inventing one.

function Write-Pass { param([string]$m) Write-Host "PASS: $m" -ForegroundColor Green }
function Fail { param([string]$m) Write-Host "FAIL: $m" -ForegroundColor Red; exit 1 }

$repoRoot = (Resolve-Path (Join-Path $PSScriptRoot '..\..')).Path
. (Join-Path $repoRoot 'scripts\internal\bootstrap\ConversationCaptureAccessor.ps1')
. (Join-Path $repoRoot 'extensions\specrew-speckit\scripts\shared-governance.ps1')

$scratch = Join-Path $repoRoot '.scratch\verdict-capture-blocks'
if (Test-Path -LiteralPath $scratch) { Remove-Item -LiteralPath $scratch -Recurse -Force }
New-Item -ItemType Directory -Path $scratch -Force | Out-Null

try {
    # ---- Part A: the recognizer (conservative classification) ----------------------------------------------
    $approvals = @(
        'Approve as-is',
        'Approve with instructions: keep FR-022 as an amendment',
        'approve plan -> tasks with instructions',
        'Approved for tasks',
        '1',
        '2',
        '2.',
        # review-signoff P7-1: a NEGATED change clause is an approval, not a send-back (the changes-clause must not misfire).
        'approved, no changes needed',
        'approved, no further changes required'
    )
    foreach ($s in $approvals) {
        $v = Test-SpecrewHumanVerdictToken -Text $s
        if (-not $v.IsApproval) { Fail "expected APPROVE for: '$s' (got Action=$($v.Action))" }
    }
    Write-Pass "recognizer: clear approvals classified as approve ($($approvals.Count) phrasings incl. bare option numbers)"

    $notApprovals = @(
        @{ t = 'Send back: the spec needs a non-functional section'; a = 'send-back' },
        @{ t = '3'; a = 'send-back' },
        @{ t = "Approve the idea, but send back the diagram"; a = 'send-back' },   # contradictory -> safe = send-back, NOT approve
        @{ t = "Let's discuss prompt #2 before I decide"; a = 'discuss' },
        @{ t = '4'; a = 'discuss' },
        @{ t = 'do not approve yet'; a = 'none' },
        @{ t = "don't approve until the tests pass"; a = 'none' },
        @{ t = 'approve later, once you fix the clobber'; a = 'none' },
        @{ t = 'what about the antigravity case?'; a = 'none' },
        @{ t = 'I have 1 concern about the plan'; a = 'none' },                    # '1' not the whole turn
        @{ t = 'start'; a = 'none' },                                             # too ambiguous -> pending
        # review-signoff P3-1: an approve-bearing QUESTION is deliberation, NOT authorization (the false-approval hole).
        @{ t = 'approve?'; a = 'none' },
        @{ t = 'is this ready to approve?'; a = 'none' },
        @{ t = 'should I approve this or not?'; a = 'none' },
        @{ t = 'can you explain before I approve?'; a = 'none' },
        @{ t = ''; a = 'none' }
    )
    foreach ($c in $notApprovals) {
        $v = Test-SpecrewHumanVerdictToken -Text $c.t
        if ($v.IsApproval) { Fail "expected NOT-approve for: '$($c.t)' (it was classified approve)" }
        if ($v.Action -ne $c.a) { Fail "expected Action '$($c.a)' for: '$($c.t)', got '$($v.Action)'" }
    }
    Write-Pass "recognizer: send-back / discuss / negated / deferred / question / ambiguous -> NOT approve ($($notApprovals.Count) cases)"

    $named = Test-SpecrewHumanVerdictToken -Text 'approve plan -> tasks'
    if (($named.NamedBoundaries -notcontains 'plan') -or ($named.NamedBoundaries -notcontains 'tasks')) { Fail "named-boundary extraction must find plan + tasks" }
    Write-Pass "recognizer: named boundaries extracted for the contradiction cross-check (plan, tasks)"

    # ---- Part B: the evidence-source tag on Add-SpecrewBoundaryAuthorization --------------------------------
    function New-EnfProj {
        $proj = Join-Path $scratch ([guid]::NewGuid().ToString('N'))
        New-Item -ItemType Directory -Path (Join-Path $proj '.specrew') -Force | Out-Null
        $ctx = [ordered]@{
            schema               = 'v2'
            feature_path         = (Join-Path $proj 'specs\046-test')
            session_state        = [ordered]@{ active = $true; boundary_type = 'plan'; feature_ref = '046-test'; iteration_number = '001'; recorded_at = '2026-01-01T00:00:00Z' }
            boundary_enforcement = [ordered]@{ enabled = $true; last_authorized_boundary = 'plan'; pending_next_boundary = $null; verdict_history = @(); bypass_history = @() }
        }
        [System.IO.File]::WriteAllText((Join-Path $proj '.specrew\start-context.json'), ($ctx | ConvertTo-Json -Depth 12), [System.Text.UTF8Encoding]::new($false))
        return $proj
    }

    $pA = New-EnfProj
    Add-SpecrewBoundaryAuthorization -ProjectRoot $pA -CurrentBoundary 'plan' -AuthorizedBoundary 'tasks' -AuthorizingHuman 'Alon' -VerdictText 'approved for tasks' -AuthCommitHash 'TESTHASH' -RecordedAt '2026-01-01T00:00:00Z' -EvidenceSource 'hook-captured-from-transcript' | Out-Null
    $ctxA = Get-Content -LiteralPath (Join-Path $pA '.specrew\start-context.json') -Raw | ConvertFrom-Json -Depth 12
    $vA = @($ctxA.boundary_enforcement.verdict_history)[-1]
    if ($vA.evidence_source -ne 'hook-captured-from-transcript') { Fail "evidence_source expected 'hook-captured-from-transcript', got '$($vA.evidence_source)'" }
    Write-Pass "evidence tag: a hook-captured authorization records evidence_source='hook-captured-from-transcript'"

    $pB = New-EnfProj
    Add-SpecrewBoundaryAuthorization -ProjectRoot $pB -CurrentBoundary 'plan' -AuthorizedBoundary 'tasks' -AuthorizingHuman 'Alon' -VerdictText 'approved for tasks' -AuthCommitHash 'TESTHASH' -RecordedAt '2026-01-01T00:00:00Z' | Out-Null
    $ctxB = Get-Content -LiteralPath (Join-Path $pB '.specrew\start-context.json') -Raw | ConvertFrom-Json -Depth 12
    $vB = @($ctxB.boundary_enforcement.verdict_history)[-1]
    if ($vB.evidence_source -ne 'unspecified') { Fail "omitted EvidenceSource must default to 'unspecified', got '$($vB.evidence_source)'" }
    Write-Pass "evidence tag: omitted EvidenceSource defaults to 'unspecified' (never blank, never fabricated)"

    # ---- Part C: the transcript reader (Get-SpecrewCapturedBoundaryVerdict) ---------------------------------
    function New-Transcript {
        param([object[]]$Turns)   # each: @{ role='assistant'|'user'; text='...' } in chronological order
        $path = Join-Path $scratch ("tx-" + [guid]::NewGuid().ToString('N') + ".jsonl")
        $lines = foreach ($t in $Turns) {
            (@{ type = $t.role; message = @{ role = $t.role; content = @(@{ type = 'text'; text = $t.text }) } } | ConvertTo-Json -Depth 8 -Compress)
        }
        [System.IO.File]::WriteAllText($path, ($lines -join "`n"), [System.Text.UTF8Encoding]::new($false))
        return $path
    }
    $marker = '<!-- SPECREW-VERDICT-BOUNDARY: tasks -> before-implement -->'

    # C1: marker packet + a clear approval -> captured, tied to the marker's boundary.
    $c1 = Get-SpecrewCapturedBoundaryVerdict -TranscriptPath (New-Transcript -Turns @(
            @{ role = 'user'; text = 'do the tasks work' },
            @{ role = 'assistant'; text = "Here is the tasks boundary packet. $marker What's your verdict?" },
            @{ role = 'user'; text = 'Approve with instructions: fold T008 in' }))
    if (-not $c1.Found) { Fail "C1: marker + approval must capture (reason=$($c1.Reason))" }
    if ($c1.ToBoundary -ne 'before-implement') { Fail "C1: ToBoundary expected before-implement, got '$($c1.ToBoundary)'" }
    if ($c1.VerdictText -ne 'approved for before-implement') { Fail "C1: VerdictText expected 'approved for before-implement', got '$($c1.VerdictText)'" }
    Write-Pass "reader: marker packet + human approval -> captured verdict tied to the marker's boundary"

    # C2: NO marker -> NO capture (the human re-confirms via the pending surface).
    $c2 = Get-SpecrewCapturedBoundaryVerdict -TranscriptPath (New-Transcript -Turns @(
            @{ role = 'assistant'; text = 'Here is a packet with no marker. Verdict?' },
            @{ role = 'user'; text = 'Approve' }))
    if ($c2.Found) { Fail "C2: no marker must NOT capture" }
    if ($c2.Reason -ne 'no-marker') { Fail "C2: reason expected no-marker, got '$($c2.Reason)'" }
    Write-Pass "reader: no packet marker -> no capture (Reason=no-marker)"

    # C3: marker but the human has not responded yet -> awaiting (not captured).
    $c3 = Get-SpecrewCapturedBoundaryVerdict -TranscriptPath (New-Transcript -Turns @(
            @{ role = 'user'; text = 'do the work' },
            @{ role = 'assistant'; text = "packet $marker verdict?" }))
    if ($c3.Found) { Fail "C3: no human response yet must NOT capture" }
    if ($c3.Reason -ne 'awaiting-response') { Fail "C3: reason expected awaiting-response, got '$($c3.Reason)'" }
    Write-Pass "reader: packet rendered, no human turn yet -> awaiting-response (not captured)"

    # C4: marker + send-back -> NOT captured (un-authorized).
    $c4 = Get-SpecrewCapturedBoundaryVerdict -TranscriptPath (New-Transcript -Turns @(
            @{ role = 'assistant'; text = "packet $marker verdict?" },
            @{ role = 'user'; text = 'Send back: needs a non-functional section' }))
    if ($c4.Found) { Fail "C4: send-back must NOT capture" }
    Write-Pass "reader: marker + send-back -> not captured (un-authorized)"

    # C5: marker + an approval that NAMES a contradicting boundary -> NOT captured (ambiguous tie).
    $c5 = Get-SpecrewCapturedBoundaryVerdict -TranscriptPath (New-Transcript -Turns @(
            @{ role = 'assistant'; text = "packet $marker verdict?" },
            @{ role = 'user'; text = 'Approve for plan' }))
    if ($c5.Found) { Fail "C5: approval naming a contradicting boundary (plan vs marker tasks->before-implement) must NOT capture" }
    if ($c5.Reason -ne 'named-boundary-contradicts-marker') { Fail "C5: reason expected named-boundary-contradicts-marker, got '$($c5.Reason)'" }
    Write-Pass "reader: approval naming a boundary that contradicts the marker -> not captured (ambiguous)"

    # C6: TWO packets -> the MOST RECENT marker + its response wins.
    $c6 = Get-SpecrewCapturedBoundaryVerdict -TranscriptPath (New-Transcript -Turns @(
            @{ role = 'assistant'; text = "first packet <!-- SPECREW-VERDICT-BOUNDARY: plan -> tasks --> verdict?" },
            @{ role = 'user'; text = 'Approve' },
            @{ role = 'assistant'; text = "second packet $marker verdict?" },
            @{ role = 'user'; text = 'Approve with instructions' }))
    if (-not $c6.Found) { Fail "C6: must capture the latest" }
    if ($c6.ToBoundary -ne 'before-implement') { Fail "C6: latest packet's boundary (before-implement) must win, got '$($c6.ToBoundary)'" }
    Write-Pass "reader: the MOST RECENT marker packet + its response wins (before-implement, not the earlier plan->tasks)"

    # C7: A later unanswered marker must NOT hide an earlier approved marker. This is the Stop-hook timing gap:
    # the hook records approval only at end-of-turn, so an agent can render the next boundary before the previous
    # approval is persisted. Capture the newest marker that actually has a clear human approval.
    $c7 = Get-SpecrewCapturedBoundaryVerdict -TranscriptPath (New-Transcript -Turns @(
            @{ role = 'assistant'; text = "first packet <!-- SPECREW-VERDICT-BOUNDARY: intake -> specify --> verdict?" },
            @{ role = 'user'; text = 'approved for specify' },
            @{ role = 'assistant'; text = "second packet <!-- SPECREW-VERDICT-BOUNDARY: clarify -> plan --> verdict?" }))
    if (-not $c7.Found) { Fail "C7: earlier approved marker must still capture when a later marker is awaiting response (reason=$($c7.Reason))" }
    if ($c7.FromBoundary -ne 'intake' -or $c7.ToBoundary -ne 'specify') { Fail "C7: expected intake->specify capture, got '$($c7.FromBoundary)->$($c7.ToBoundary)'" }
    Write-Pass "reader: later unanswered marker does NOT hide an earlier approved marker (Stop timing gap)"

    # C8: Codex records hook feedback as a role=user <hook_prompt> item. It can contain example approval text in
    # the hook instruction; it is NOT a human verdict and must never authorize a boundary.
    $c8 = Get-SpecrewCapturedBoundaryVerdict -TranscriptPath (New-Transcript -Turns @(
            @{ role = 'assistant'; text = "packet <!-- SPECREW-VERDICT-BOUNDARY: specify -> clarify --> verdict?" },
            @{ role = 'user'; text = '<hook_prompt hook_run_id="stop:2:C:\Users\alon.HOME\.codex\hooks.json">Please reply with: approved for clarify</hook_prompt>' }))
    if ($c8.Found) { Fail "C8: hook_prompt must not be treated as a human approval" }
    if ($c8.Reason -ne 'awaiting-response') { Fail "C8: expected awaiting-response after ignoring hook_prompt, got '$($c8.Reason)'" }
    Write-Pass "reader: Codex hook_prompt feedback is ignored for verdict capture"

    Write-Host "`n=== verdict-capture-blocks.tests.ps1: all assertions passed ===" -ForegroundColor Green
    exit 0
}
finally {
    Remove-Item -LiteralPath $scratch -Recurse -Force -ErrorAction SilentlyContinue
}
