[CmdletBinding()]
param()
Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

# Feature 185 FR-011 / FR-015 / FR-004 - SC-008 / SC-011: the conformance Stop-provider DETECTION + BLOCK-request.
#
# The provider now emits a BLOCK SENTINEL (`<<<SPECREW-STOP-BLOCK>>>` + the packet directive) when a stop owes the
# 6-section re-entry packet and it is absent, so the dispatcher can force-continue the turn (the packet renders AT
# the stop, not as a too-late next-turn nudge). This file tests the PROVIDER's detection + sentinel emission against
# REALISTIC fixtures (the dispatcher's per-host envelope translation is tested in dispatcher-stop-block.tests.ps1).
# Each case dispatches the real provider as a child process the way the hook dispatcher does (double-dash flags,
# cwd = the fixture root) and asserts on its stdout (Prop-145 synthetic-fixture + negative-case discipline).

function Write-Pass { param([string]$m) Write-Host "PASS: $m" -ForegroundColor Green }
function Fail { param([string]$m) Write-Host "FAIL: $m" -ForegroundColor Red; exit 1 }

$repoRoot = (Resolve-Path (Join-Path $PSScriptRoot '..\..')).Path
$provider = Join-Path $repoRoot 'extensions\specrew-speckit\scripts\specrew-conformance-provider.ps1'
if (-not (Test-Path -LiteralPath $provider)) { Fail "conformance provider not found at $provider" }

$priorModulePath = $env:SPECREW_MODULE_PATH
$env:SPECREW_MODULE_PATH = $repoRoot  # so the provider resolves ConversationCaptureAccessor + the false-positive guard

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
        boundary_enforcement = [ordered]@{ enabled = $Enabled; last_authorized_boundary = $LastAuth; pending_next_boundary = $null; verdict_history = @(); bypass_history = @() }
    }
    [System.IO.File]::WriteAllText((Join-Path $proj '.specrew\start-context.json'), ($ctx | ConvertTo-Json -Depth 12), [System.Text.UTF8Encoding]::new($false))
    return $proj
}

function New-Spec {
    param([string]$Proj)
    $dir = Join-Path $Proj 'specs\050-host-neutral-gate'
    New-Item -ItemType Directory -Path $dir -Force | Out-Null
    Set-Content -LiteralPath (Join-Path $dir 'spec.md') -Value "# Feature Specification: Host-Neutral Gate Enforcement`n`nThe authoritative contract for the active feature." -Encoding UTF8
}

function New-LensApplicability {
    # Write a feature-level lens-applicability.json so Get-SpecrewWorkshopProgress sees the workshop state.
    # $Done lenses get a moved_on flag (recorded done); selected minus done = remaining (>0 == workshop in progress).
    param([string]$Proj, [string[]]$Selected, [string[]]$Done = @())
    $dir = Join-Path $Proj 'specs\050-host-neutral-gate'
    New-Item -ItemType Directory -Path $dir -Force | Out-Null
    $workshop = [ordered]@{}
    foreach ($d in $Done) { $workshop[$d] = [ordered]@{ moved_on = $true } }
    $obj = [ordered]@{ workshop_intake = $true; confirmation_required = $true; selected = $Selected; workshop = $workshop }
    Set-Content -LiteralPath (Join-Path $dir 'lens-applicability.json') -Value ($obj | ConvertTo-Json -Depth 6) -Encoding UTF8
}

function New-Transcript {
    param([string]$Proj, [object[]]$Turns)
    $dir = Join-Path $Proj '.specrew\runtime'
    New-Item -ItemType Directory -Path $dir -Force | Out-Null
    # Unique per call - a fixture that creates two transcripts in one project (e.g. the loop-guard reset case) must
    # NOT have the second overwrite the first at a shared path.
    $path = Join-Path $dir ('transcript-' + [guid]::NewGuid().ToString('N') + '.jsonl')
    $lines = foreach ($t in $Turns) {
        ([pscustomobject]@{ type = $t.role; message = [pscustomobject]@{ content = @([pscustomobject]@{ type = 'text'; text = $t.text }) } } | ConvertTo-Json -Depth 8 -Compress)
    }
    [System.IO.File]::WriteAllLines($path, [string[]]$lines, [System.Text.UTF8Encoding]::new($false))
    return $path
}

function Invoke-Conformance {
    param([string]$Proj, [AllowNull()][string]$TranscriptPath, [string]$Event = 'Stop')
    $tpArg = if ([string]::IsNullOrWhiteSpace($TranscriptPath)) { '' } else { " --transcript-path '$TranscriptPath'" }
    $cmd = "Set-Location -LiteralPath '$Proj'; & '$provider' --host-kind claude --source-event $Event$tpArg"
    $out = & pwsh -NoProfile -ExecutionPolicy Bypass -Command $cmd 2>&1
    return [pscustomobject]@{ Out = (@($out) -join "`n"); Code = $LASTEXITCODE; Blocked = ((@($out) -join "`n") -match '<<<SPECREW-STOP-BLOCK>>>') }
}

# A real six-section packet body (well over the 600-char substantial floor) carrying the verdict marker.
$realPacket = @'
## What I Just Did

Completed the clarify phase for feature 050-host-neutral-gate and reconciled the spec clarifications, updating the artifacts under file:///fixture/specs/050-host-neutral-gate/spec.md with the locked scope and the enforce-or-halt north star agreed with the human.

## Why I Stopped

This is the clarify -> plan boundary. Planning converts the spec into architecture and task direction, so spec mistakes become downstream work. Human judgment is required before I author plan.md.

## What Needs Your Review

The clarifications section and the locked scope. High-impact: the enforce-or-halt north star and the host capability matrix.

## What Happens Next

I will author plan.md with the architecture and the FR-to-test mapping. No code is written at the plan boundary.

## Discussion Prompts

1. Is the locked scope correct? You can approve with the defaults.

## What I Need From You

Approve as-is, approve with instructions, send back, or discuss prompt #N.

<!-- SPECREW-VERDICT-BOUNDARY: clarify -> plan -->
'@

# A long (>600 char) NON-packet hand-back: substantial prose with no section headers and no verdict marker.
$longProse = ('I went ahead and refactored the resolver and the three call sites, tightened the error handling around the cache, ' +
    'added a couple of guard clauses, and tidied the logging so it is consistent across the module. I also looked into the ' +
    'flaky integration path and I think it is a race in the warmup step, though I have not confirmed it yet. There are a few ' +
    'directions we could take from here and I am not sure which you prefer, so let me know how you want to proceed and whether ' +
    'I should keep going on the warmup race or pivot to the other items we discussed earlier this afternoon in some detail. ' +
    'I also want to flag that the dependency bump touches two manifests and a lockfile, so we should decide whether to land ' +
    'that separately or fold it into this change; either way I can prepare both and you can pick the one you would rather take.')

try {
    # ---- Case 1: BOUNDARY block. Working 'plan' ahead of authorized 'clarify', no packet -> emit the block sentinel
    #              with the packet directive + the CONTIGUOUS clarify -> plan verdict marker.
    $p1 = New-Fixture -Working 'plan' -LastAuth 'clarify'
    $t1 = New-Transcript -Proj $p1 -Turns @(@{ role = 'user'; text = 'continue' }, @{ role = 'assistant'; text = 'I have written plan.md and moved on to tasks.' })
    $r1 = Invoke-Conformance -Proj $p1 -TranscriptPath $t1
    if ($r1.Code -ne 0) { Fail "Case 1: provider must exit 0 (got $($r1.Code)); out: $($r1.Out)" }
    if (-not $r1.Blocked) { Fail "Case 1: a boundary stop (working 'plan' > authorized 'clarify') with no packet MUST emit the block sentinel. Out: $($r1.Out)" }
    if ($r1.Out -notmatch 'What I Just Did') { Fail "Case 1: the block directive must instruct the six-section packet. Out: $($r1.Out)" }
    if ($r1.Out -notmatch 'SPECREW-VERDICT-BOUNDARY: clarify -> plan') { Fail "Case 1: the block directive must carry the contiguous clarify -> plan marker. Out: $($r1.Out)" }
    Write-Pass "Case 1: a boundary silent-advance emits the block sentinel + the six-section directive + the contiguous clarify -> plan marker (#2884 / SC-008 #2)"

    # ---- Case 2: FALSE-POSITIVE GUARD (boundary). Same state, but the packet WAS rendered this turn (to=plan==working) -> no block.
    $p2 = New-Fixture -Working 'plan' -LastAuth 'clarify'
    $t2 = New-Transcript -Proj $p2 -Turns @(@{ role = 'user'; text = 'continue' }, @{ role = 'assistant'; text = $realPacket })
    $r2 = Invoke-Conformance -Proj $p2 -TranscriptPath $t2
    if ($r2.Blocked) { Fail "Case 2: a rendered packet (to=plan==working) is a legitimate awaiting-verdict stop - MUST NOT block. Out: $($r2.Out)" }
    Write-Pass "Case 2: a rendered six-section packet matching the working boundary SUPPRESSES the block (false-positive guard)"

    # ---- Case 3: cursor caught up. working == authorized, no spec, short msg -> not pending, not substantial -> no block.
    $p3 = New-Fixture -Working 'plan' -LastAuth 'plan'
    $t3 = New-Transcript -Proj $p3 -Turns @(@{ role = 'assistant'; text = 'Plan approved; proceeding.' })
    $r3 = Invoke-Conformance -Proj $p3 -TranscriptPath $t3
    if ($r3.Blocked) { Fail "Case 3: working == authorized + short message MUST NOT block. Out: $($r3.Out)" }
    Write-Pass "Case 3: working == authorized + a short reply does NOT block (no false alarm)"

    # ---- Case 4: SUBSTANTIAL non-boundary block. No pending verdict, but a spec exists (past intake) and the agent
    #              ended the turn with a long hand-back lacking the packet -> block, packet directive, NO verdict marker.
    $p4 = New-Fixture -Working 'plan' -LastAuth 'plan'
    New-Spec -Proj $p4
    $t4 = New-Transcript -Proj $p4 -Turns @(@{ role = 'user'; text = 'go' }, @{ role = 'assistant'; text = $longProse })
    $r4 = Invoke-Conformance -Proj $p4 -TranscriptPath $t4
    if (-not $r4.Blocked) { Fail "Case 4: a substantial post-intake hand-back with no packet MUST block (the every-stop rule). Out: $($r4.Out)" }
    if ($r4.Out -notmatch 'What I Just Did') { Fail "Case 4: the block directive must instruct the six-section packet. Out: $($r4.Out)" }
    if ($r4.Out -match 'SPECREW-VERDICT-BOUNDARY') { Fail "Case 4: a non-boundary stop MUST NOT carry a verdict marker. Out: $($r4.Out)" }
    Write-Pass "Case 4: a SUBSTANTIAL non-boundary hand-back lacking the packet blocks (six-section directive, no verdict marker) - the every-stop rule (FR-015 / SC-011)"

    # ---- Case 4b: SUBSTANTIAL but PRE-SPEC (workshop excluded). Same long message, NO spec, no pending -> NO block.
    $p4b = New-Fixture -Working 'plan' -LastAuth 'plan'
    $t4b = New-Transcript -Proj $p4b -Turns @(@{ role = 'assistant'; text = $longProse })
    $r4b = Invoke-Conformance -Proj $p4b -TranscriptPath $t4b
    if ($r4b.Blocked) { Fail "Case 4b: a substantial message pre-spec (intake/workshop) MUST NOT block - the workshop is excluded. Out: $($r4b.Out)" }
    Write-Pass "Case 4b: a substantial message PRE-SPEC (the design-workshop window) does NOT block (workshop exclusion)"

    # ---- Case 5: INTAKE QUESTION -> a cooperative NUDGE (not a block). Short intake question, spec exists.
    $p5 = New-Fixture -Working 'plan' -LastAuth 'plan'
    New-Spec -Proj $p5
    $t5 = New-Transcript -Proj $p5 -Turns @(@{ role = 'assistant'; text = "Welcome! What would you like to build today?" })
    $r5 = Invoke-Conformance -Proj $p5 -TranscriptPath $t5
    if ($r5.Blocked) { Fail "Case 5: a short intake question is a redirect nudge, not a packet block. Out: $($r5.Out)" }
    if ($r5.Out -notmatch 'INTAKE QUESTION') { Fail "Case 5: an intake question while a spec exists MUST fire the #1 redirect nudge. Out: $($r5.Out)" }
    Write-Pass "Case 5: an intake question while an active feature exists fires the #1 redirect NUDGE (SC-008 #1)"

    # ---- Case 6: RAW SPEC KIT -> a cooperative NUDGE. Short message running `specify workflow`, no spec.
    $p6 = New-Fixture -Working 'plan' -LastAuth 'plan'
    $t6 = New-Transcript -Proj $p6 -Turns @(@{ role = 'assistant'; text = "I'll run: specify workflow --type feature." })
    $r6 = Invoke-Conformance -Proj $p6 -TranscriptPath $t6
    if ($r6.Out -notmatch 'RAW SPEC KIT') { Fail "Case 6: a raw 'specify workflow' invocation MUST fire the #3 redirect. Out: $($r6.Out)" }
    Write-Pass "Case 6: a raw 'specify workflow' invocation fires the #3 redirect NUDGE (SC-008 #3)"

    # ---- Case 7: LOOP-GUARD. Consecutive packet-less boundary stops block up to the cap, then degrade to a nudge
    #              (never hang); a packet-present stop resets the counter so a later advance re-blocks.
    $p7 = New-Fixture -Working 'plan' -LastAuth 'clarify'
    $t7 = New-Transcript -Proj $p7 -Turns @(@{ role = 'assistant'; text = 'plan.md written.' })
    for ($n = 1; $n -le 3; $n++) {
        $rb = Invoke-Conformance -Proj $p7 -TranscriptPath $t7
        if (-not $rb.Blocked) { Fail "Case 7: block #$n (within the cap of 3) MUST block. Out: $($rb.Out)" }
    }
    $r7cap = Invoke-Conformance -Proj $p7 -TranscriptPath $t7
    if ($r7cap.Blocked) { Fail "Case 7: the 4th consecutive block exceeds the cap and MUST degrade (release the stop) to avoid a hang. Out: $($r7cap.Out)" }
    if ($r7cap.Out -notmatch 'RE-ENTRY PACKET still missing') { Fail "Case 7: over the cap, degrade to a plain re-entry nudge. Out: $($r7cap.Out)" }
    # A packet-present stop resets the counter.
    $t7ok = New-Transcript -Proj $p7 -Turns @(@{ role = 'assistant'; text = $realPacket })
    $null = Invoke-Conformance -Proj $p7 -TranscriptPath $t7ok
    $r7reset = Invoke-Conformance -Proj $p7 -TranscriptPath $t7
    if (-not $r7reset.Blocked) { Fail "Case 7: after a packet-present stop reset the counter, a fresh packet-less advance MUST re-block. Out: $($r7reset.Out)" }
    Write-Pass "Case 7: loop-guard - consecutive packet-less stops block up to the cap then degrade (no hang); a packet-present stop resets so a later advance re-blocks"

    # ---- Case 8: ISOLATION. A firing leaves start-context.json (the gate authority) byte-unchanged.
    $p8 = New-Fixture -Working 'plan' -LastAuth 'clarify'
    $ctx8 = Join-Path $p8 '.specrew\start-context.json'
    $before = (Get-FileHash -LiteralPath $ctx8).Hash
    $t8 = New-Transcript -Proj $p8 -Turns @(@{ role = 'assistant'; text = 'plan.md written.' })
    $null = Invoke-Conformance -Proj $p8 -TranscriptPath $t8
    if ((Get-FileHash -LiteralPath $ctx8).Hash -ne $before) { Fail "Case 8: the provider MUST NOT mutate start-context.json (the gate authority). Hash changed." }
    Write-Pass "Case 8: a firing leaves start-context.json (verdict_history / cursor) byte-unchanged - the provider is read-only to gate state (runtime-proven)"

    # ---- Case 9: MULTI-GATE-GAP marker. working 'tasks' two gates past authorized 'clarify' -> the block names the
    #              CONTIGUOUS first-unauthorized crossing clarify -> plan, never the gate-skipping plan -> tasks.
    $p9 = New-Fixture -Working 'tasks' -LastAuth 'clarify'
    $t9 = New-Transcript -Proj $p9 -Turns @(@{ role = 'assistant'; text = 'tasks.md drafted; proceeding.' })
    $r9 = Invoke-Conformance -Proj $p9 -TranscriptPath $t9
    if (-not $r9.Blocked) { Fail "Case 9: a 2-gate jump MUST block. Out: $($r9.Out)" }
    if ($r9.Out -notmatch 'SPECREW-VERDICT-BOUNDARY: clarify -> plan') { Fail "Case 9: MUST name the contiguous clarify -> plan crossing. Out: $($r9.Out)" }
    if ($r9.Out -match 'SPECREW-VERDICT-BOUNDARY: (plan -> tasks|clarify -> tasks)') { Fail "Case 9: MUST NOT name a non-contiguous crossing. Out: $($r9.Out)" }
    Write-Pass "Case 9: a multi-gate-gap block names the CONTIGUOUS clarify -> plan crossing, not a gate-skipping marker (145 F2)"

    # ---- Case 10: STALE-PACKET still blocks. working 'tasks', authorized 'plan', a stale clarify->plan packet (to=plan)
    #               in the tail must NOT suppress the genuine plan->tasks advance (to != working).
    $p10 = New-Fixture -Working 'tasks' -LastAuth 'plan'
    $t10 = New-Transcript -Proj $p10 -Turns @(
        @{ role = 'assistant'; text = $realPacket },
        @{ role = 'user'; text = 'approved for plan' },
        @{ role = 'assistant'; text = 'Plan approved. I have written tasks.md and am starting implementation now in earnest.' }
    )
    $r10 = Invoke-Conformance -Proj $p10 -TranscriptPath $t10
    if (-not $r10.Blocked) { Fail "Case 10: a stale clarify->plan packet (to=plan) MUST NOT suppress the genuine plan->tasks advance. Out: $($r10.Out)" }
    if ($r10.Out -notmatch 'SPECREW-VERDICT-BOUNDARY: plan -> tasks') { Fail "Case 10: the block must name the contiguous plan -> tasks crossing. Out: $($r10.Out)" }
    Write-Pass "Case 10: a STALE/unrelated packet does NOT suppress a genuine new advance - the guard matches ToBoundary to the working boundary (145 TI-2/F1)"

    # ---- Case 11: RELEVANT packet (to==working) suppresses. working 'tasks', authorized 'plan', a plan->tasks packet rendered.
    $packetTasks = $realPacket -replace 'clarify -> plan', 'plan -> tasks'
    $p11 = New-Fixture -Working 'tasks' -LastAuth 'plan'
    $t11 = New-Transcript -Proj $p11 -Turns @(@{ role = 'user'; text = 'continue' }, @{ role = 'assistant'; text = $packetTasks })
    $r11 = Invoke-Conformance -Proj $p11 -TranscriptPath $t11
    if ($r11.Blocked) { Fail "Case 11: a packet whose ToBoundary == the working boundary is a legitimate awaiting stop - MUST suppress. Out: $($r11.Out)" }
    Write-Pass "Case 11: the RELEVANT packet (ToBoundary == working) correctly suppresses the block (guard precision)"

    # ---- Case 12: ENFORCEMENT DISABLED -> never blocks.
    $p12 = New-Fixture -Working 'plan' -LastAuth 'clarify' -Enabled $false
    $t12 = New-Transcript -Proj $p12 -Turns @(@{ role = 'assistant'; text = 'plan.md written.' })
    $r12 = Invoke-Conformance -Proj $p12 -TranscriptPath $t12
    if ($r12.Blocked) { Fail "Case 12: enforcement disabled MUST NOT block. Out: $($r12.Out)" }
    Write-Pass "Case 12: enforcement disabled does NOT block (no fabricated state; fail-open)"

    # ---- Case 13 (145 HANG-1): the consecutive-block count is keyed by the ADVANCE, with NO time window. A
    #      pre-seeded count at the cap for this advance caps regardless of elapsed time (the old epoch window let a
    #      >120s/turn loop reset to 0 forever and never cap -> an unbounded hang on a capless host).
    $p13 = New-Fixture -Working 'plan' -LastAuth 'clarify'
    $cf13 = Join-Path $p13 '.specrew\runtime\conformance-stop-block.json'
    New-Item -ItemType Directory -Path (Split-Path $cf13) -Force | Out-Null
    Set-Content -LiteralPath $cf13 -Value '{"key":"plan|clarify","count":3}' -Encoding UTF8
    $t13 = New-Transcript -Proj $p13 -Turns @(@{ role = 'assistant'; text = 'plan.md written.' })
    $r13 = Invoke-Conformance -Proj $p13 -TranscriptPath $t13
    if ($r13.Blocked) { Fail "Case 13: a count at the cap for this advance key MUST cap (count persists by advance, no time window). Out: $($r13.Out)" }
    if ($r13.Out -notmatch 'RE-ENTRY PACKET still missing') { Fail "Case 13: at the cap, degrade to the plain nudge. Out: $($r13.Out)" }
    Write-Pass "Case 13: the consecutive-block count is keyed by the advance (no time window) - a count at the cap releases regardless of elapsed time (145 HANG-1)"

    # ---- Case 14 (145 HANG-2): an unpersistable counter degrades to NO block (fail-open). A directory placed at the
    #      counter file path makes the verified write fail -> the provider must NOT start an uncappable loop on a capless host.
    $p14 = New-Fixture -Working 'plan' -LastAuth 'clarify'
    New-Item -ItemType Directory -Path (Join-Path $p14 '.specrew\runtime\conformance-stop-block.json') -Force | Out-Null
    $t14 = New-Transcript -Proj $p14 -Turns @(@{ role = 'assistant'; text = 'plan.md written.' })
    $r14 = Invoke-Conformance -Proj $p14 -TranscriptPath $t14
    if ($r14.Blocked) { Fail "Case 14: an unpersistable loop-guard counter MUST fail-open (no block) - a capless host could otherwise hang. Out: $($r14.Out)" }
    Write-Pass "Case 14: an unwritable/unverifiable loop-guard counter degrades to NO block (fail-open) - never an uncappable loop (145 HANG-2)"

    # ---- Case 15 (145 F1-CC-FAIL-CLOSED): an UNREADABLE last message (no transcript / ConversationCaptureAccessor
    #      dark) degrades to NO block. We cannot claim the packet is absent without reading the message -> fail-OPEN,
    #      matching the boundary-trigger load-failure direction (never fail-closed on a missing component).
    $p15 = New-Fixture -Working 'plan' -LastAuth 'clarify'
    $r15 = Invoke-Conformance -Proj $p15 -TranscriptPath $null
    if ($r15.Blocked) { Fail "Case 15: with no readable last message the provider MUST NOT block (cannot claim the packet is absent; 145 F1-CC). Out: $($r15.Out)" }
    Write-Pass "Case 15: an unreadable last message (no transcript / CC unresolved) degrades to NO block (fail-open, never fail-closed on a missing component; 145 F1-CC)"

    # ---- Case 16 (DOGFOOD BUG / FR-015 workshop exclusion): the lens workshop CONTINUES after spec.md is scaffolded.
    #      A substantial lens question post-scaffold (spec exists + lens-applicability with lenses REMAINING) MUST NOT
    #      block - the design workshop is the only exclusion. (The old pre-spec proxy false-blocked exactly this.)
    $p16 = New-Fixture -Working 'plan' -LastAuth 'plan'
    New-Spec -Proj $p16
    New-LensApplicability -Proj $p16 -Selected @('product-domain','architecture-core','component-design','ui-ux','data-storage','integration-api','requirements-nfr','code-implementation','observability-resilience') -Done @()
    $t16 = New-Transcript -Proj $p16 -Turns @(@{ role = 'assistant'; text = $longProse })
    $r16 = Invoke-Conformance -Proj $p16 -TranscriptPath $t16
    if ($r16.Blocked) { Fail "Case 16: a substantial lens question DURING the workshop (spec scaffolded, lenses remaining) MUST NOT block - the workshop is the FR-015 exclusion. Out: $($r16.Out)" }
    Write-Pass "Case 16: a substantial lens question post-scaffold (workshop in progress) does NOT block - robust workshop exclusion (dogfood bug / FR-015)"

    # ---- Case 16b: the workshop exclusion overrides even the BOUNDARY trigger - a pending verdict during the
    #      workshop still must not block (lens questions are not boundary stops).
    $p16b = New-Fixture -Working 'plan' -LastAuth 'clarify'
    New-Spec -Proj $p16b
    New-LensApplicability -Proj $p16b -Selected @('product-domain','architecture-core','data-storage') -Done @()
    $t16b = New-Transcript -Proj $p16b -Turns @(@{ role = 'assistant'; text = 'Lens 1 of 3: product domain. Who are the users?' })
    $r16b = Invoke-Conformance -Proj $p16b -TranscriptPath $t16b
    if ($r16b.Blocked) { Fail "Case 16b: a pending verdict DURING the workshop must still be suppressed (the workshop exclusion overrides the boundary trigger). Out: $($r16b.Out)" }
    Write-Pass "Case 16b: the workshop exclusion overrides the boundary trigger - no block during the lens workshop even with a pending verdict"

    # ---- Case 17: workshop COMPLETE (all selected lenses done -> remaining = 0) -> the exclusion CLEARS, and a real
    #      boundary stop blocks again. Proves the exclusion is scoped to the in-progress workshop, not "forever after a spec".
    $p17 = New-Fixture -Working 'plan' -LastAuth 'clarify'
    New-Spec -Proj $p17
    New-LensApplicability -Proj $p17 -Selected @('product-domain','data-storage') -Done @('product-domain','data-storage')
    $t17 = New-Transcript -Proj $p17 -Turns @(@{ role = 'assistant'; text = 'spec.md written; plan.md drafted.' })
    $r17 = Invoke-Conformance -Proj $p17 -TranscriptPath $t17
    if (-not $r17.Blocked) { Fail "Case 17: with the workshop COMPLETE (remaining=0), a real boundary silent-advance MUST block again - the exclusion clears. Out: $($r17.Out)" }
    Write-Pass "Case 17: the workshop exclusion CLEARS when all lenses are done (remaining=0) - a real boundary then blocks (exclusion scoped to the in-progress workshop)"

    # ---- Case 18 (#3 negation guard): the contract's OWN prohibition prose ('do NOT run the raw `specify.exe
    #      workflow`') must NOT fire the #3 redirect (no spec, no pending -> only #3 could fire).
    $p18 = New-Fixture -Working 'plan' -LastAuth 'plan'
    $t18 = New-Transcript -Proj $p18 -Turns @(@{ role = 'assistant'; text = 'Per the contract, I will do NOT run the raw `specify.exe workflow` automation - I will use the governed flow.' })
    $r18 = Invoke-Conformance -Proj $p18 -TranscriptPath $t18
    if ($r18.Out -match 'RAW SPEC KIT') { Fail "Case 18: the contract's prohibition prose ('do NOT run the raw `specify.exe workflow`') MUST NOT fire #3 (negation guard). Out: $($r18.Out)" }
    Write-Pass "Case 18: the contract's own 'do NOT run the raw specify.exe workflow' prohibition prose does NOT false-fire #3 (negation guard; dogfood)"

    Write-Host "`n=== conformance-detection.tests.ps1: all assertions passed ===" -ForegroundColor Green
    exit 0
}
finally {
    Remove-Item -LiteralPath $scratch -Recurse -Force -ErrorAction SilentlyContinue
    if ($null -eq $priorModulePath) { Remove-Item Env:\SPECREW_MODULE_PATH -ErrorAction SilentlyContinue } else { $env:SPECREW_MODULE_PATH = $priorModulePath }
}
