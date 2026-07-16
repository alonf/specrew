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
        'I approve for tasks',
        'Yes - approved for tasks',
        '2. Approve with instructions: retain the drift note',
        # review-signoff P7-1: a NEGATED change clause is an approval, not a send-back (the changes-clause must not misfire).
        'approved, no changes needed',
        'approved, no further changes required'
    )
    foreach ($s in $approvals) {
        $v = Test-SpecrewHumanVerdictToken -Text $s
        if (-not $v.IsApproval) { Fail "expected APPROVE for: '$s' (got Action=$($v.Action))" }
    }
    Write-Pass "recognizer: clear leading verdict utterances classified as approve ($($approvals.Count) phrasings)"

    $notApprovals = @(
        @{ t = 'Send back: the spec needs a non-functional section'; a = 'send-back' },
        @{ t = '3'; a = 'none' },
        @{ t = "Approve the idea, but send back the diagram"; a = 'send-back' },   # contradictory -> safe = send-back, NOT approve
        @{ t = "Let's discuss prompt #2 before I decide"; a = 'discuss' },
        @{ t = '4'; a = 'none' },
        @{ t = 'do not approve yet'; a = 'none' },
        @{ t = "don't approve until the tests pass"; a = 'none' },
        @{ t = 'approve later, once you fix the clobber'; a = 'none' },
        @{ t = 'what about the antigravity case?'; a = 'none' },
        @{ t = 'I have 1 concern about the plan'; a = 'none' },                    # '1' not the whole turn
        @{ t = '1'; a = 'none' },                                                  # numeric aliases are not authority
        @{ t = 'option 1'; a = 'none' },
        @{ t = '2.'; a = 'none' },
        @{ t = 'if you already approved, please re-confirm'; a = 'none' },          # mention, not a verdict
        @{ t = 'please reply with approved for tasks'; a = 'none' },                # teaching text
        @{ t = 'the approval phrase is approved for tasks'; a = 'none' },           # phrase definition
        @{ t = '"approved for tasks"'; a = 'none' },                               # quoted text
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

    $pFallbackEvidence = New-EnfProj
    Add-SpecrewBoundaryAuthorization -ProjectRoot $pFallbackEvidence -CurrentBoundary 'plan' -AuthorizedBoundary 'tasks' -AuthorizingHuman 'Alon' -VerdictText 'approved for tasks' -AuthCommitHash 'TESTHASH' -RecordedAt '2026-01-01T00:00:00Z' -EvidenceSource 'hook-captured-from-transcript-pending-artifact' | Out-Null
    $ctxFallbackEvidence = Get-Content -LiteralPath (Join-Path $pFallbackEvidence '.specrew\start-context.json') -Raw | ConvertFrom-Json -Depth 12
    $vFallbackEvidence = @($ctxFallbackEvidence.boundary_enforcement.verdict_history)[-1]
    if ($vFallbackEvidence.evidence_source -ne 'hook-captured-from-transcript-pending-artifact') { Fail "fallback evidence_source expected 'hook-captured-from-transcript-pending-artifact', got '$($vFallbackEvidence.evidence_source)'" }
    Write-Pass "evidence tag: pending-artifact fallback authorizations can be audited distinctly"

    $pB = New-EnfProj
    Add-SpecrewBoundaryAuthorization -ProjectRoot $pB -CurrentBoundary 'plan' -AuthorizedBoundary 'tasks' -AuthorizingHuman 'Alon' -VerdictText 'approved for tasks' -AuthCommitHash 'TESTHASH' -RecordedAt '2026-01-01T00:00:00Z' | Out-Null
    $ctxB = Get-Content -LiteralPath (Join-Path $pB '.specrew\start-context.json') -Raw | ConvertFrom-Json -Depth 12
    $vB = @($ctxB.boundary_enforcement.verdict_history)[-1]
    if ($vB.evidence_source -ne 'unspecified') { Fail "omitted EvidenceSource must default to 'unspecified', got '$($vB.evidence_source)'" }
    Write-Pass "evidence tag: omitted EvidenceSource defaults to 'unspecified' (never blank, never fabricated)"

    # ---- Part C: the transcript reader (Get-SpecrewCapturedBoundaryVerdict) ---------------------------------
    function New-Transcript {
        param([object[]]$Turns)   # each: @{ role='assistant'|'user'; text='...'; is_meta=$true? } in chronological order
        $path = Join-Path $scratch ("tx-" + [guid]::NewGuid().ToString('N') + ".jsonl")
        $lines = foreach ($t in $Turns) {
            $record = [ordered]@{ type = $t.role; message = @{ role = $t.role; content = @(@{ type = 'text'; text = $t.text }) } }
            if (($t -is [System.Collections.IDictionary] -and $t.Contains('is_meta')) -or $null -ne $t.PSObject.Properties['is_meta']) {
                $record.isMeta = [bool]$t.is_meta
            }
            ($record | ConvertTo-Json -Depth 8 -Compress)
        }
        [System.IO.File]::WriteAllText($path, ($lines -join "`n"), [System.Text.UTF8Encoding]::new($false))
        return $path
    }
    function Read-TranscriptTurns {
        param([string]$Path)
        $turns = New-Object System.Collections.Generic.List[object]
        foreach ($rp in @(Get-SpecrewTranscriptParsedTurns -TranscriptPath $Path)) {
            $turn = Format-SpecrewConversationTurnText -Turn $rp -Raw
            if ($null -ne $turn) { $turns.Add($turn) | Out-Null }
        }
        return , $turns.ToArray()
    }
    function New-AntigravityTranscript {
        param([object[]]$Turns)   # each: @{ source='MODEL'|'USER_EXPLICIT'; type='...'; content='...' }
        $path = Join-Path $scratch ("ag-" + [guid]::NewGuid().ToString('N') + ".jsonl")
        $lines = foreach ($t in $Turns) {
            (@{ source = $t.source; type = $t.type; content = $t.content } | ConvertTo-Json -Depth 8 -Compress)
        }
        [System.IO.File]::WriteAllText($path, ($lines -join "`n"), [System.Text.UTF8Encoding]::new($false))
        return $path
    }
    function New-PendingProject {
        param(
            [AllowNull()][string]$LastAuthorizedBoundary = 'plan',
            [AllowNull()][string]$WorkingBoundary = 'tasks'
        )
        $proj = Join-Path $scratch ("pending-" + [guid]::NewGuid().ToString('N'))
        New-Item -ItemType Directory -Path (Join-Path $proj '.specrew') -Force | Out-Null
        $ctx = [ordered]@{
            schema               = 'v2'
            feature_path         = (Join-Path $proj 'specs\046-test')
            session_state        = [ordered]@{ active = $true; boundary_type = $WorkingBoundary; feature_ref = '046-test'; iteration_number = '001'; recorded_at = '2026-01-01T00:00:00Z' }
            boundary_enforcement = [ordered]@{ enabled = $true; last_authorized_boundary = $LastAuthorizedBoundary; pending_next_boundary = $null; verdict_history = @(); bypass_history = @() }
        }
        [System.IO.File]::WriteAllText((Join-Path $proj '.specrew\start-context.json'), ($ctx | ConvertTo-Json -Depth 12), [System.Text.UTF8Encoding]::new($false))
        return $proj
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

    # C8: Claude records hook feedback as role=user but isMeta=true. The IDENTICAL approval text captures as a
    # genuine human turn and does not capture as machinery. Codex's <hook_prompt> envelope is likewise machinery.
    $pairedVerdictText = 'approved for clarify'
    $c8a = Get-SpecrewCapturedBoundaryVerdict -TranscriptPath (New-Transcript -Turns @(
            @{ role = 'assistant'; text = "packet <!-- SPECREW-VERDICT-BOUNDARY: specify -> clarify --> verdict?" },
            @{ role = 'user'; text = $pairedVerdictText }))
    if (-not $c8a.Found) { Fail "C8a: genuine human approval text must capture (reason=$($c8a.Reason))" }
    $c8b = Get-SpecrewCapturedBoundaryVerdict -TranscriptPath (New-Transcript -Turns @(
            @{ role = 'assistant'; text = "packet <!-- SPECREW-VERDICT-BOUNDARY: specify -> clarify --> verdict?" },
            @{ role = 'user'; text = $pairedVerdictText; is_meta = $true }))
    if ($c8b.Found) { Fail "C8b: identical isMeta hook feedback must not be treated as a human approval" }
    if ($c8b.Reason -ne 'awaiting-response') { Fail "C8b: expected awaiting-response after excluding isMeta feedback, got '$($c8b.Reason)'" }
    $c8d = Get-SpecrewCapturedBoundaryVerdict -LastUserMessage $pairedVerdictText -TranscriptPath (New-Transcript -Turns @(
            @{ role = 'assistant'; text = "packet <!-- SPECREW-VERDICT-BOUNDARY: specify -> clarify --> verdict?" },
            @{ role = 'user'; text = $pairedVerdictText; is_meta = $true }))
    if (-not $c8d.Found) { Fail "C8d: a genuine prompt-submit approval identical to prior isMeta text must capture (reason=$($c8d.Reason))" }
    $c8c = Get-SpecrewCapturedBoundaryVerdict -TranscriptPath (New-Transcript -Turns @(
            @{ role = 'assistant'; text = "packet <!-- SPECREW-VERDICT-BOUNDARY: specify -> clarify --> verdict?" },
            @{ role = 'user'; text = '<hook_prompt hook_run_id="stop:2:C:\Users\alon.HOME\.codex\hooks.json">Please reply with: approved for clarify</hook_prompt>' }))
    if ($c8c.Found) { Fail "C8c: hook_prompt must not be treated as a human approval" }
    if ($c8c.Reason -ne 'awaiting-response') { Fail "C8c: expected awaiting-response after ignoring hook_prompt, got '$($c8c.Reason)'" }
    Write-Pass "reader: identical human/isMeta text is provenance-separated, genuine prompt-submit survives dedup, and Codex hook_prompt is ignored"

    # C9: Antigravity transcript roles parse as real assistant/user turns, including USER_REQUEST wrapper removal.
    $c9 = Get-SpecrewCapturedBoundaryVerdict -TranscriptPath (New-AntigravityTranscript -Turns @(
            @{ source = 'MODEL'; type = 'PLANNER_RESPONSE'; content = "packet <!-- SPECREW-VERDICT-BOUNDARY: plan -> tasks --> verdict?" },
            @{ source = 'USER_EXPLICIT'; type = 'USER_INPUT'; content = "<USER_REQUEST>`napproved for tasks`n</USER_REQUEST>" }))
    if (-not $c9.Found) { Fail "C9: Antigravity MODEL/USER_EXPLICIT transcript must capture marker + approval (reason=$($c9.Reason))" }
    if ($c9.FromBoundary -ne 'plan' -or $c9.ToBoundary -ne 'tasks') { Fail "C9: expected plan->tasks capture, got '$($c9.FromBoundary)->$($c9.ToBoundary)'" }
    Write-Pass "reader: Antigravity MODEL/USER_EXPLICIT transcript format is parsed for verdict capture"

    $markerlessPacket = @"
## What I Just Did
Generated the tasks artifact.

## Why I Stopped
This is the plan -> tasks boundary.

## What Needs Your Review
Review the tasks file.

## What Happens Next
Implementation preparation follows after approval.

## Discussion Prompts
No open prompts.

## What I Need From You
• Option 1: approved for tasks
• Option 2: Rejections or specific adjustment instructions.
"@
    $pendingPlanTasks = New-PendingProject -LastAuthorizedBoundary 'plan' -WorkingBoundary 'tasks'
    $pendingPlanTasksState = Get-SpecrewPendingVerdictState -ProjectRoot $pendingPlanTasks

    # The fallback remains publicly disabled until T032/T033 complete, but its pure candidate evaluator must
    # already prove temporal ordering and cursor binding. Option numbers are labels only; explicit words decide.
    $coreAccepted = Find-SpecrewPendingVerdictFallbackCandidate -Pending $pendingPlanTasksState -Turns (Read-TranscriptTurns -Path (New-Transcript -Turns @(
                @{ role = 'assistant'; text = $markerlessPacket },
                @{ role = 'user'; text = '2. Approve with instructions: keep the drift note' })))
    if (-not $coreAccepted.Found -or $coreAccepted.ToBoundary -ne 'tasks') { Fail "fallback core: explicit approval after current-cursor packet must capture" }

    $wrongCursorPacket = $markerlessPacket -replace 'approved for tasks', 'approved for clarify'
    $coreWrongCursor = Find-SpecrewPendingVerdictFallbackCandidate -Pending $pendingPlanTasksState -Turns (Read-TranscriptTurns -Path (New-Transcript -Turns @(
                @{ role = 'assistant'; text = $wrongCursorPacket },
                @{ role = 'user'; text = 'Approve as-is' })))
    if ($coreWrongCursor.Found -or $coreWrongCursor.Reason -ne 'packet-cursor-mismatch') { Fail "fallback core: packet for another cursor must fail with packet-cursor-mismatch" }

    $corePredates = Find-SpecrewPendingVerdictFallbackCandidate -Pending $pendingPlanTasksState -Turns (Read-TranscriptTurns -Path (New-Transcript -Turns @(
                @{ role = 'user'; text = 'approved for tasks' },
                @{ role = 'assistant'; text = $markerlessPacket })))
    if ($corePredates.Found -or $corePredates.Reason -ne 'candidate-predates-packet') { Fail "fallback core: candidate before packet must fail temporal ordering" }

    $coreBareNumber = Find-SpecrewPendingVerdictFallbackCandidate -Pending $pendingPlanTasksState -Turns (Read-TranscriptTurns -Path (New-Transcript -Turns @(
                @{ role = 'assistant'; text = $markerlessPacket },
                @{ role = 'user'; text = '1' })))
    if ($coreBareNumber.Found -or $coreBareNumber.Reason -ne 'no-clear-human-approval') { Fail "fallback core: bare number must remain non-authoritative" }
    Write-Pass "fallback core: human-after-packet ordering, exact pending cursor, explicit words, and number-as-label semantics pass"

    # C10-C14/C16 (REWRITTEN for the DEC-198-GOV-003 interim mitigation, maintainer-instructed
    # at the iteration-002 closeout): the pending-artifact fallback is DISABLED after fabricating
    # two authorizations in one day. EVERY markerless path - including the previously-legitimate
    # option-1 binds (old C10/C11/C16) - now refuses with 'fallback-capture-disabled-interim'.
    # The old expectations are the iteration-003 re-enable acceptance surface (T030-T033): the
    # redesigned fallback must restore them WITH machinery-turn exclusion, tokenizer tightening,
    # and the temporal-ordering guard.

    # C10: markerless packet + genuine option 1 does NOT authorize while the mitigation is active.
    $c10 = Get-SpecrewCapturedBoundaryVerdict -ProjectRoot $pendingPlanTasks -TranscriptPath (New-Transcript -Turns @(
            @{ role = 'assistant'; text = $markerlessPacket },
            @{ role = 'user'; text = 'option 1' }))
    if ($c10.Found) { Fail "C10: the disabled fallback authorized a markerless option 1" }
    if ($c10.Reason -ne 'fallback-capture-disabled-interim') { Fail "C10: expected fallback-capture-disabled-interim, got '$($c10.Reason)'" }
    Write-Pass "reader (interim): markerless option 1 refuses - one re-confirm keystroke beats a fabricated authorization"

    # C11: bare '1' likewise refuses while disabled.
    $c11 = Get-SpecrewCapturedBoundaryVerdict -ProjectRoot $pendingPlanTasks -TranscriptPath (New-Transcript -Turns @(
            @{ role = 'assistant'; text = $markerlessPacket },
            @{ role = 'user'; text = '1' }))
    if ($c11.Found) { Fail "C11: the disabled fallback authorized a markerless bare 1" }
    Write-Pass "reader (interim): markerless bare 1 refuses while the mitigation is active"

    # C12/C13/C14: the abuse paths stay refused (now via the disable, previously via per-path guards).
    $c12 = Get-SpecrewCapturedBoundaryVerdict -ProjectRoot $pendingPlanTasks -TranscriptPath (New-Transcript -Turns @(
            @{ role = 'assistant'; text = $markerlessPacket },
            @{ role = 'user'; text = 'option 2' }))
    if ($c12.Found) { Fail "C12: markerless fallback must not authorize option 2" }
    Write-Pass "reader (interim): markerless option 2 stays refused"
    $noPending = New-PendingProject -LastAuthorizedBoundary 'tasks' -WorkingBoundary 'tasks'
    $c13 = Get-SpecrewCapturedBoundaryVerdict -ProjectRoot $noPending -TranscriptPath (New-Transcript -Turns @(
            @{ role = 'assistant'; text = $markerlessPacket },
            @{ role = 'user'; text = 'approved for tasks' }))
    if ($c13.Found) { Fail "C13: markerless fallback must not authorize without a pending verdict state" }
    Write-Pass "reader (interim): markerless approval without pending state stays refused"
    $c14 = Get-SpecrewCapturedBoundaryVerdict -ProjectRoot $pendingPlanTasks -TranscriptPath (New-Transcript -Turns @(
            @{ role = 'assistant'; text = $markerlessPacket },
            @{ role = 'user'; text = 'approved for clarify' }))
    if ($c14.Found) { Fail "C14: approval naming a different boundary must not fall back to pending" }
    Write-Pass "reader (interim): markerless contradicting-boundary approval stays refused"

    # C15: MARKER-BOUND capture is UNAFFECTED by the mitigation - the exact path that records
    # genuine verdicts (incl. instruction-carrying ones) keeps working.
    $c15 = Get-SpecrewCapturedBoundaryVerdict -LastUserMessage 'approved for tasks' -TranscriptPath (New-Transcript -Turns @(
            @{ role = 'assistant'; text = "packet <!-- SPECREW-VERDICT-BOUNDARY: plan -> tasks --> verdict?" }))
    if (-not $c15.Found) { Fail "C15: prompt-submit supplied user approval should capture against the prior marker (reason=$($c15.Reason))" }
    if ($c15.FromBoundary -ne 'plan' -or $c15.ToBoundary -ne 'tasks') { Fail "C15: expected plan->tasks capture, got '$($c15.FromBoundary)->$($c15.ToBoundary)'" }
    Write-Pass "reader: marker-bound capture stays fully active under the mitigation"

    # C15a-numeric: even with a marker, a bare option number is not an authorization token. The packet text may
    # use numbered labels for readability, but only an explicit verdict utterance can cross the boundary.
    $c15Numeric = Get-SpecrewCapturedBoundaryVerdict -TranscriptPath (New-Transcript -Turns @(
            @{ role = 'assistant'; text = "packet <!-- SPECREW-VERDICT-BOUNDARY: plan -> tasks --> 1. approved for tasks" },
            @{ role = 'user'; text = '1' }))
    if ($c15Numeric.Found) { Fail "C15a-numeric: bare 1 must not authorize a marker-bound packet" }
    Write-Pass "reader: bare numeric reply never authorizes, even against a numbered marker-bound packet"

    # C15b: the prompt-submit seam must not reintroduce machinery that the structured transcript parser rejects.
    $c15b = Get-SpecrewCapturedBoundaryVerdict -LastUserMessage '<hook_prompt hook_run_id="stop:test">approved for tasks</hook_prompt>' -TranscriptPath (New-Transcript -Turns @(
            @{ role = 'assistant'; text = "packet <!-- SPECREW-VERDICT-BOUNDARY: plan -> tasks --> verdict?" }))
    if ($c15b.Found) { Fail "C15b: synthetic hook_prompt text must not authorize the prior marker" }
    if ($c15b.Reason -ne 'awaiting-response') { Fail "C15b: expected awaiting-response after excluding synthetic hook_prompt, got '$($c15b.Reason)'" }
    Write-Pass "reader: synthetic prompt-submit seam excludes hook machinery"

    # C16: prompt-submit markerless fallback likewise refuses while disabled.
    $c16 = Get-SpecrewCapturedBoundaryVerdict -ProjectRoot $pendingPlanTasks -LastUserMessage '1' -TranscriptPath (New-Transcript -Turns @(
            @{ role = 'assistant'; text = $markerlessPacket }))
    if ($c16.Found) { Fail "C16: the disabled fallback authorized a prompt-submit bare 1" }
    if ($c16.Reason -ne 'fallback-capture-disabled-interim') { Fail "C16: expected fallback-capture-disabled-interim, got '$($c16.Reason)'" }
    Write-Pass "reader (interim): prompt-submit markerless path refuses while the mitigation is active"

    # C17 (DEC-198-GOV-003 regression, maintainer-instructed): the EXACT fabrication sequence -
    # a rendered packet followed by hook-injected approval-shaped machinery text in a user-role
    # turn, with NO human reply - must produce NO fallback authorization while the mitigation is
    # active. Same for agent-authored approval text.
    $hookFeedbackTurn = 'Stop hook feedback: Specrew: boundary state is pending. AWAITING YOUR VERDICT: if you already approved, please re-confirm. Give the boundary verdict to authorize it.'
    $c17a = Get-SpecrewCapturedBoundaryVerdict -ProjectRoot $pendingPlanTasks -TranscriptPath (New-Transcript -Turns @(
            @{ role = 'assistant'; text = $markerlessPacket },
            @{ role = 'user'; text = $hookFeedbackTurn }))
    if ($c17a.Found) { Fail "C17a: hook-injected approval-shaped machinery text produced a fallback authorization (the GOV-001/GOV-003 fabrication)" }
    Write-Pass "regression: hook-injected user-role machinery text cannot produce fallback authorization"
    $c17b = Get-SpecrewCapturedBoundaryVerdict -ProjectRoot $pendingPlanTasks -TranscriptPath (New-Transcript -Turns @(
            @{ role = 'assistant'; text = $markerlessPacket },
            @{ role = 'assistant'; text = 'approved for tasks - proceeding.' }))
    if ($c17b.Found) { Fail "C17b: agent-authored approval text produced a fallback authorization" }
    Write-Pass "regression: agent-authored approval text cannot produce fallback authorization"

    Write-Host "`n=== verdict-capture-blocks.tests.ps1: all assertions passed ===" -ForegroundColor Green
    exit 0
}
finally {
    Remove-Item -LiteralPath $scratch -Recurse -Force -ErrorAction SilentlyContinue
}
