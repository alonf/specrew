[CmdletBinding()]
param()
Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

# Feature 185 FR-011 / FR-015 - SC-008 / SC-011: the conformance Stop-provider DETECTION logic.
#
# Proves the three #2884-era deviations are DETECTED at end-of-turn, against REALISTIC fixtures (real marker
# grammar, a real >200-char six-section packet body over Get-SpecrewCapturedBoundaryPacket's MinPacketChars
# floor, real intake phrasings, a real `specify workflow` token) - NOT a 4-line toy that matches only the
# provider's own code (the Prop-145 "synthetic-fixture stand-in" / "negative-case" rules; the scaffold was
# already DOA once - c6f97021). Each case DISPATCHES the real provider as a child process the way the hook
# dispatcher does (double-dash flags, cwd = the fixture root) and asserts on its stdout (the injection fragment).

function Write-Pass { param([string]$m) Write-Host "PASS: $m" -ForegroundColor Green }
function Fail { param([string]$m) Write-Host "FAIL: $m" -ForegroundColor Red; exit 1 }

$repoRoot = (Resolve-Path (Join-Path $PSScriptRoot '..\..')).Path
$provider = Join-Path $repoRoot 'extensions\specrew-speckit\scripts\specrew-conformance-provider.ps1'
if (-not (Test-Path -LiteralPath $provider)) { Fail "conformance provider not found at $provider" }

# The provider resolves ConversationCaptureAccessor from <cwd>/scripts/internal/bootstrap, else SPECREW_MODULE_PATH,
# else the installed module. The fixture cwd has no scripts/internal, so point SPECREW_MODULE_PATH at the repo so
# the false-positive guard (Get-SpecrewCapturedBoundaryPacket) + the turn parser load. shared-governance loads
# from beside the provider regardless. (This mirrors the self-host resolution the handover provider uses.)
$priorModulePath = $env:SPECREW_MODULE_PATH
$env:SPECREW_MODULE_PATH = $repoRoot

# Per-run-unique scratch under the OS temp dir (NOT a fixed repo-rooted path): the fixtures are destroyed and
# the child pwsh Set-Locations into them, so a shared fixed root is clobbered under concurrency / by repo
# watchers (145 TI-1). Mirrors the seam test's GetTempPath()+GUID pattern.
$scratch = Join-Path ([System.IO.Path]::GetTempPath()) ('specrew-conf-det-' + [guid]::NewGuid().ToString('N'))
if (Test-Path -LiteralPath $scratch) { Remove-Item -LiteralPath $scratch -Recurse -Force -ErrorAction SilentlyContinue }

function New-Fixture {
    param([string]$Working, [string]$LastAuth, [bool]$Enabled = $true)
    $proj = Join-Path $scratch ([guid]::NewGuid().ToString('N'))
    New-Item -ItemType Directory -Path (Join-Path $proj '.specrew') -Force | Out-Null
    $ss = $null
    if (-not [string]::IsNullOrWhiteSpace($Working)) {
        $ss = [ordered]@{ active = $true; boundary_type = $Working; feature_ref = '050-host-neutral-gate'; iteration_number = '001'; recorded_at = '2026-06-20T00:00:00Z' }
    }
    $ctx = [ordered]@{
        schema               = 'v2'
        feature_path         = (Join-Path $proj 'specs\050-host-neutral-gate')
        session_state        = $ss
        boundary_enforcement = [ordered]@{
            enabled                  = $Enabled
            last_authorized_boundary = $LastAuth
            pending_next_boundary    = $null
            verdict_history          = @()
            bypass_history           = @()
        }
    }
    [System.IO.File]::WriteAllText((Join-Path $proj '.specrew\start-context.json'), ($ctx | ConvertTo-Json -Depth 12), [System.Text.UTF8Encoding]::new($false))
    return $proj
}

function New-Spec {
    # An active feature on disk (the #1 deviation needs a spec to exist).
    param([string]$Proj)
    $dir = Join-Path $Proj 'specs\050-host-neutral-gate'
    New-Item -ItemType Directory -Path $dir -Force | Out-Null
    Set-Content -LiteralPath (Join-Path $dir 'spec.md') -Value "# Feature Specification: Host-Neutral Gate Enforcement`n`nThe authoritative contract for the active feature." -Encoding UTF8
}

function New-Transcript {
    # A realistic Claude-schema JSONL transcript (type in {user,assistant} + message.content[{type:text,text}]).
    param([string]$Proj, [object[]]$Turns)
    $dir = Join-Path $Proj '.specrew\runtime'
    New-Item -ItemType Directory -Path $dir -Force | Out-Null
    $path = Join-Path $dir 'transcript.jsonl'
    $lines = foreach ($t in $Turns) {
        ([pscustomobject]@{ type = $t.role; message = [pscustomobject]@{ content = @([pscustomobject]@{ type = 'text'; text = $t.text }) } } | ConvertTo-Json -Depth 8 -Compress)
    }
    [System.IO.File]::WriteAllLines($path, [string[]]$lines, [System.Text.UTF8Encoding]::new($false))
    return $path
}

function Invoke-Conformance {
    # Dispatch the provider the way the hook dispatcher does: child pwsh, double-dash flags, cwd = the fixture
    # root (the dispatcher sets ProcessStartInfo.WorkingDirectory; we Set-Location in the child so Get-Location
    # resolves the fixture - Push-Location in the parent does NOT sync the child's .NET working directory).
    param([string]$Proj, [AllowNull()][string]$TranscriptPath, [string]$Event = 'Stop')
    $tpArg = if ([string]::IsNullOrWhiteSpace($TranscriptPath)) { '' } else { " --transcript-path '$TranscriptPath'" }
    $cmd = "Set-Location -LiteralPath '$Proj'; & '$provider' --host-kind claude --source-event $Event$tpArg"
    $out = & pwsh -NoProfile -ExecutionPolicy Bypass -Command $cmd 2>&1
    return [pscustomobject]@{ Out = (@($out) -join "`n"); Code = $LASTEXITCODE }
}

# A real six-section boundary packet body (well over the 200-char MinPacketChars floor) carrying the verdict marker.
$realPacket = @'
## What I Just Did

Completed the clarify phase for feature 050-host-neutral-gate and reconciled the spec clarifications. Artifacts updated under file:///fixture/specs/050-host-neutral-gate/spec.md.

## Why I Stopped

This is the clarify -> plan boundary. Planning converts the spec into architecture and task direction, so spec mistakes become downstream work. Human judgment is required before I author plan.md.

## What Needs Your Review

The clarifications section and the locked scope. High-impact: the enforce-or-halt north star.

## What Happens Next

I will author plan.md with the architecture and FR-to-test mapping. No code is written at the plan boundary.

## Discussion Prompts

1. Is the locked scope correct? You can approve with the defaults.

## What I Need From You

Approve as-is, approve with instructions, send back, or discuss prompt #N.

<!-- SPECREW-VERDICT-BOUNDARY: clarify -> plan -->
'@

try {
    # ---- Case 1: SILENT ADVANCE FIRES (the #2884 headline). Working 'plan' is ahead of authorized 'clarify',
    #              and the last assistant turn did NOT render a verdict packet -> a silent advance -> correction.
    $p1 = New-Fixture -Working 'plan' -LastAuth 'clarify'
    $t1 = New-Transcript -Proj $p1 -Turns @(
        @{ role = 'user'; text = 'continue' },
        @{ role = 'assistant'; text = 'I have written plan.md with the architecture and moved on to drafting tasks.' }
    )
    $r1 = Invoke-Conformance -Proj $p1 -TranscriptPath $t1
    if ($r1.Code -ne 0) { Fail "Case 1: provider must exit 0 (got $($r1.Code)); out: $($r1.Out)" }
    if ($r1.Out -notmatch 'SILENT BOUNDARY ADVANCE') { Fail "Case 1: a working boundary ahead of authorized with NO rendered packet MUST fire the silent-advance correction. Out: $($r1.Out)" }
    if ($r1.Out -notmatch 'SPECREW-VERDICT-BOUNDARY: clarify -> plan') { Fail "Case 1: the correction must template the contiguous clarify -> plan verdict marker. Out: $($r1.Out)" }
    if ($r1.Out -notmatch 'six-section') { Fail "Case 1: the correction must instruct rendering the six-section packet (FR-015). Out: $($r1.Out)" }
    Write-Pass "Case 1: silent boundary advance (working 'plan' > authorized 'clarify', no packet rendered) FIRES the correction with the contiguous marker template (#2884 headline / SC-008 #2)"

    # ---- Case 2: FALSE-POSITIVE GUARD. SAME committed-!=-authorized state, but the agent DID render the full
    #              six-section packet + marker this turn -> a legitimate awaiting-verdict stop -> NO correction.
    $p2 = New-Fixture -Working 'plan' -LastAuth 'clarify'
    $t2 = New-Transcript -Proj $p2 -Turns @(
        @{ role = 'user'; text = 'continue' },
        @{ role = 'assistant'; text = $realPacket }
    )
    $r2 = Invoke-Conformance -Proj $p2 -TranscriptPath $t2
    if ($r2.Code -ne 0) { Fail "Case 2: provider must exit 0 (got $($r2.Code)); out: $($r2.Out)" }
    if ($r2.Out -match 'SILENT BOUNDARY ADVANCE') { Fail "Case 2: a rendered verdict packet this turn is a LEGITIMATE awaiting-verdict stop - it MUST NOT fire (the false-positive guard). Out: $($r2.Out)" }
    Write-Pass "Case 2: a rendered six-section packet + marker this turn SUPPRESSES the correction (false-positive guard; no nag on a legitimate awaiting-verdict stop)"

    # ---- Case 3: CURSOR CAUGHT UP. Working == authorized ('plan'/'plan') -> not pending -> no correction.
    $p3 = New-Fixture -Working 'plan' -LastAuth 'plan'
    $t3 = New-Transcript -Proj $p3 -Turns @(@{ role = 'assistant'; text = 'Plan approved and recorded; proceeding to author plan.md.' })
    $r3 = Invoke-Conformance -Proj $p3 -TranscriptPath $t3
    if ($r3.Out -match 'SILENT BOUNDARY ADVANCE') { Fail "Case 3: working == authorized is a properly-authorized boundary - MUST NOT fire. Out: $($r3.Out)" }
    Write-Pass "Case 3: working == authorized (cursor caught up) does NOT fire (no false alarm on an authorized boundary)"

    # ---- Case 4: INTAKE QUESTION while an active feature exists (#1). Not pending (working==auth so #2 is quiet),
    #              the last turn asks what to build, and a spec.md is on disk -> redirect-to-continue correction.
    $p4 = New-Fixture -Working 'plan' -LastAuth 'plan'
    New-Spec -Proj $p4
    $t4 = New-Transcript -Proj $p4 -Turns @(
        @{ role = 'user'; text = 'hi' },
        @{ role = 'assistant'; text = "Welcome! What would you like to build today? Tell me about the feature and I'll get started." }
    )
    $r4 = Invoke-Conformance -Proj $p4 -TranscriptPath $t4
    if ($r4.Out -notmatch 'INTAKE QUESTION') { Fail "Case 4: an intake 'what would you like to build' question while a spec exists MUST fire the #1 redirect. Out: $($r4.Out)" }
    if ($r4.Out -match 'SILENT BOUNDARY ADVANCE') { Fail "Case 4: #2 must stay quiet here (working == authorized). Out: $($r4.Out)" }
    Write-Pass "Case 4: an intake question ('what would you like to build') while an active feature exists FIRES the #1 redirect (SC-008 #1)"

    # ---- Case 4b: intake question but NO active feature (greenfield) -> must NOT fire #1 (asking what to build
    #               is correct on a truly empty project).
    $p4b = New-Fixture -Working 'plan' -LastAuth 'plan'
    $t4b = New-Transcript -Proj $p4b -Turns @(@{ role = 'assistant'; text = 'What would you like to build?' })
    $r4b = Invoke-Conformance -Proj $p4b -TranscriptPath $t4b
    if ($r4b.Out -match 'INTAKE QUESTION') { Fail "Case 4b: asking what to build with NO spec on disk is legitimate greenfield intake - MUST NOT fire. Out: $($r4b.Out)" }
    Write-Pass "Case 4b: an intake question with NO active feature (greenfield) does NOT fire #1 (no false alarm)"

    # ---- Case 5: RAW SPEC KIT (#3). The last turn ran the un-governed `specify workflow` engine -> redirect.
    $p5 = New-Fixture -Working 'plan' -LastAuth 'plan'
    $t5 = New-Transcript -Proj $p5 -Turns @(
        @{ role = 'assistant'; text = "I'll scaffold the spec now by running: specify workflow --type feature. This kicks off the SDD engine." }
    )
    $r5 = Invoke-Conformance -Proj $p5 -TranscriptPath $t5
    if ($r5.Out -notmatch 'RAW SPEC KIT') { Fail "Case 5: a raw 'specify workflow' invocation MUST fire the #3 redirect. Out: $($r5.Out)" }
    Write-Pass "Case 5: a raw 'specify workflow' SDD-engine invocation FIRES the #3 redirect to the governed flow (SC-008 #3)"

    # ---- Case 6: IDEMPOTENCE. Re-dispatching the SAME silent advance does NOT re-nudge (fire-once per
    #               (working,auth) via the conformance journal); a NEW advance DOES re-fire.
    $p6 = New-Fixture -Working 'plan' -LastAuth 'clarify'
    $t6 = New-Transcript -Proj $p6 -Turns @(@{ role = 'assistant'; text = 'plan.md written; continuing.' })
    $r6a = Invoke-Conformance -Proj $p6 -TranscriptPath $t6
    if ($r6a.Out -notmatch 'SILENT BOUNDARY ADVANCE') { Fail "Case 6: first dispatch MUST fire. Out: $($r6a.Out)" }
    $r6b = Invoke-Conformance -Proj $p6 -TranscriptPath $t6
    if ($r6b.Out -match 'SILENT BOUNDARY ADVANCE') { Fail "Case 6: the SAME advance MUST NOT re-nudge (fire-once idempotence). Out: $($r6b.Out)" }
    # A NEW advance (working moves on to 'tasks') re-fires.
    $ctxPath = Join-Path $p6 '.specrew\start-context.json'
    $raw = Get-Content -LiteralPath $ctxPath -Raw | ConvertFrom-Json -AsHashtable -Depth 12
    $raw['session_state']['boundary_type'] = 'tasks'
    [System.IO.File]::WriteAllText($ctxPath, ($raw | ConvertTo-Json -Depth 12), [System.Text.UTF8Encoding]::new($false))
    $r6c = Invoke-Conformance -Proj $p6 -TranscriptPath $t6
    if ($r6c.Out -notmatch 'SILENT BOUNDARY ADVANCE') { Fail "Case 6: a NEW advance (working 'tasks') MUST re-fire (fire-once is per (working,auth), not permanent). Out: $($r6c.Out)" }
    # F2: working='tasks' with last_authorized='clarify' is a MULTI-gate gap; the contiguous crossing the cursor
    # can authorize next is clarify -> plan (successor of last-authorized), NOT plan -> tasks (predecessor of working,
    # which order-30 capture refuses as MARKER_CURSOR_MISMATCH).
    if ($r6c.Out -notmatch 'SPECREW-VERDICT-BOUNDARY: clarify -> plan') { Fail "Case 6: the multi-gate re-fire MUST template the CONTIGUOUS clarify -> plan marker (successor of last-authorized). Out: $($r6c.Out)" }
    if ($r6c.Out -match 'SPECREW-VERDICT-BOUNDARY: plan -> tasks') { Fail "Case 6 (F2): MUST NOT template plan -> tasks - that skips the unauthorized clarify -> plan gate. Out: $($r6c.Out)" }
    Write-Pass "Case 6: fire-once idempotence - same advance no re-nudge, new advance re-fires; the multi-gate re-fire templates the CONTIGUOUS clarify -> plan marker, not plan -> tasks (145 F2)"

    # ---- Case 7: ENFORCEMENT DISABLED -> never fires (the helper never fabricates a pending state).
    $p7 = New-Fixture -Working 'plan' -LastAuth 'clarify' -Enabled $false
    $t7 = New-Transcript -Proj $p7 -Turns @(@{ role = 'assistant'; text = 'plan.md written.' })
    $r7 = Invoke-Conformance -Proj $p7 -TranscriptPath $t7
    if ($r7.Out -match 'SILENT BOUNDARY ADVANCE') { Fail "Case 7: enforcement disabled MUST NOT fire. Out: $($r7.Out)" }
    Write-Pass "Case 7: enforcement disabled does NOT fire (no fabricated state; fail-open)"

    # ---- Case 8: ISOLATION at runtime - the provider NEVER mutates the gate authority state. Assert the fixture's
    #               start-context.json (verdict_history / last_authorized_boundary) is byte-unchanged after a firing.
    $p8 = New-Fixture -Working 'plan' -LastAuth 'clarify'
    $ctx8 = Join-Path $p8 '.specrew\start-context.json'
    $before = (Get-FileHash -LiteralPath $ctx8).Hash
    $t8 = New-Transcript -Proj $p8 -Turns @(@{ role = 'assistant'; text = 'plan.md written.' })
    $null = Invoke-Conformance -Proj $p8 -TranscriptPath $t8
    $after = (Get-FileHash -LiteralPath $ctx8).Hash
    if ($before -ne $after) { Fail "Case 8: the provider MUST NOT mutate start-context.json (the gate authority) - it is read-only. Hash changed." }
    Write-Pass "Case 8: a firing leaves start-context.json (verdict_history / cursor) byte-unchanged - the provider is read-only to gate state (FR-011 isolation, runtime-proven)"

    # ---- Case 9 (145 F2): MULTI-GATE-GAP marker correctness. Working 'tasks' jumped two gates past authorized
    #      'clarify'; the correction must name the FIRST unauthorized contiguous crossing clarify -> plan, never
    #      plan -> tasks (which order-30 capture refuses as MARKER_CURSOR_MISMATCH and would skip a gate).
    $p9 = New-Fixture -Working 'tasks' -LastAuth 'clarify'
    $t9 = New-Transcript -Proj $p9 -Turns @(@{ role = 'assistant'; text = 'tasks.md drafted; proceeding to implement.' })
    $r9 = Invoke-Conformance -Proj $p9 -TranscriptPath $t9
    if ($r9.Out -notmatch 'SILENT BOUNDARY ADVANCE') { Fail "Case 9: a 2-gate jump (clarify->...->tasks) MUST fire. Out: $($r9.Out)" }
    if ($r9.Out -notmatch 'SPECREW-VERDICT-BOUNDARY: clarify -> plan') { Fail "Case 9 (F2): MUST template the contiguous clarify -> plan crossing (successor of last-authorized). Out: $($r9.Out)" }
    if ($r9.Out -match 'SPECREW-VERDICT-BOUNDARY: (plan -> tasks|clarify -> tasks)') { Fail "Case 9 (F2): MUST NOT name a non-contiguous crossing (plan->tasks / clarify->tasks). Out: $($r9.Out)" }
    Write-Pass "Case 9: a multi-gate-gap advance templates the CONTIGUOUS first-unauthorized crossing clarify -> plan, not a gate-skipping marker (145 F2)"

    # ---- Case 10 (145 TI-2/F1): STALE-PACKET must NOT suppress a genuine NEW silent advance. Working 'tasks',
    #      authorized 'plan' (plan->tasks gate never offered), but an OLD already-consumed clarify->plan packet
    #      still sits in the tail. ToBoundary(plan) != WorkingBoundary(tasks) -> the guard must NOT suppress -> fire.
    $p10 = New-Fixture -Working 'tasks' -LastAuth 'plan'
    $t10 = New-Transcript -Proj $p10 -Turns @(
        @{ role = 'assistant'; text = $realPacket },                                  # stale clarify->plan packet (to=plan)
        @{ role = 'user'; text = 'approved for plan' },
        @{ role = 'assistant'; text = 'Plan approved. I have now written tasks.md and am starting implementation.' }
    )
    $r10 = Invoke-Conformance -Proj $p10 -TranscriptPath $t10
    if ($r10.Out -notmatch 'SILENT BOUNDARY ADVANCE') { Fail "Case 10 (TI-2/F1): a stale clarify->plan packet (to=plan) MUST NOT suppress the genuine plan->tasks silent advance (working=tasks). Out: $($r10.Out)" }
    if ($r10.Out -notmatch 'SPECREW-VERDICT-BOUNDARY: plan -> tasks') { Fail "Case 10: the fired correction must template the contiguous plan -> tasks crossing. Out: $($r10.Out)" }
    Write-Pass "Case 10: a STALE/unrelated packet in the tail does NOT suppress a genuine new silent advance - the guard matches the packet's ToBoundary to the WORKING boundary (145 TI-2/F1)"

    # ---- Case 11 (guard precision): the RELEVANT packet (to == working) DOES suppress. Working 'tasks',
    #      authorized 'plan', and THIS turn renders the plan->tasks packet (to=tasks) -> legitimate awaiting -> no fire.
    $packetTasks = $realPacket -replace 'clarify -> plan', 'plan -> tasks'
    $p11 = New-Fixture -Working 'tasks' -LastAuth 'plan'
    $t11 = New-Transcript -Proj $p11 -Turns @(@{ role = 'user'; text = 'continue' }, @{ role = 'assistant'; text = $packetTasks })
    $r11 = Invoke-Conformance -Proj $p11 -TranscriptPath $t11
    if ($r11.Out -match 'SILENT BOUNDARY ADVANCE') { Fail "Case 11: a packet whose ToBoundary == the working boundary (plan->tasks, working=tasks) is a legitimate awaiting-verdict stop - MUST suppress. Out: $($r11.Out)" }
    Write-Pass "Case 11: the RELEVANT packet (ToBoundary == working) correctly suppresses - the guard is precise, not just present (145 TI-2 positive side)"

    Write-Host "`n=== conformance-detection.tests.ps1: all assertions passed ===" -ForegroundColor Green
    exit 0
}
finally {
    Remove-Item -LiteralPath $scratch -Recurse -Force -ErrorAction SilentlyContinue
    if ($null -eq $priorModulePath) { Remove-Item Env:\SPECREW_MODULE_PATH -ErrorAction SilentlyContinue } else { $env:SPECREW_MODULE_PATH = $priorModulePath }
}
