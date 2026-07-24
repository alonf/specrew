[CmdletBinding()]
param()
Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

# FR-045a STOP-INTENT WIRING (T019 piece 4b) - the conformance Stop-provider classifies a MATERIAL, packet-less,
# non-boundary stop as continue|intermediate|real BEFORE the material-work packet enforcement. This is SAFETY-CRITICAL
# (it changes Stop behaviour), so the overriding contract is FAIL-SAFE: any uncertainty, a BOUNDARY stop, a missing
# marker, or an unavailable classifier MUST leave today's real-stop enforcement EXACTLY as it is.
#
# The pure classifier + its precedence/marker/packet-consistency behaviour are proven in
# tests/continuous-co-review/unit/stop-intent-contract.Tests.ps1. This file proves the PROVIDER WIRING against
# realistic fixtures the way the hook dispatcher runs it (double-dash flags, cwd = the fixture root), mirroring the
# conformance-detection.tests.ps1 harness exactly:
#   (a) continue marker + authorized phase + no pending -> a CONTINUATION DIRECTIVE, NOT the five-part material packet
#   (b) intermediate marker + authorized phase        -> SUPPRESSED (turn ends; async completion resumes the agent)
#   (c) material stop with NO marker                  -> the five-part material packet (the fail-safe / real path)
#   (d) continue marker but a PENDING boundary        -> the boundary block STILL fires (never downgraded)
#   (e) a runaway continue on the SAME material surface -> bounded: after the guard trips it falls back to the packet

function Write-Pass { param([string]$m) Write-Host "PASS: $m" -ForegroundColor Green }
function Fail { param([string]$m) Write-Host "FAIL: $m" -ForegroundColor Red; exit 1 }

$repoRoot = (Resolve-Path (Join-Path $PSScriptRoot '..\..')).Path
$provider = Join-Path $repoRoot 'extensions\specrew-speckit\scripts\specrew-conformance-provider.ps1'
if (-not (Test-Path -LiteralPath $provider)) { Fail "conformance provider not found at $provider" }

$continueMarker = '<!-- SPECREW-STOP-INTENT: continue -->'
$intermediateMarker = '<!-- SPECREW-STOP-INTENT: intermediate -->'

$priorModulePath = $env:SPECREW_MODULE_PATH
$env:SPECREW_MODULE_PATH = $repoRoot  # so the provider resolves ConversationCaptureAccessor + the sibling stop-intent-contract.ps1

$scratch = Join-Path ([System.IO.Path]::GetTempPath()) ('specrew-conf-si-' + [guid]::NewGuid().ToString('N'))
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
    $null = & git -C $proj init --quiet
    $null = & git -C $proj config core.autocrlf false
    [IO.File]::WriteAllText((Join-Path $proj '.fixture-base'), "fixture`n", [Text.UTF8Encoding]::new($false))
    $null = & git -C $proj add .fixture-base
    $null = & git -C $proj -c user.name=Fixture -c user.email=fixture@example.invalid commit --quiet -m 'fixture baseline'
    if ($LASTEXITCODE -ne 0) { throw 'fixture baseline commit failed' }
    return $proj
}

function New-Spec {
    param([string]$Proj)
    $dir = Join-Path $Proj 'specs\050-host-neutral-gate'
    New-Item -ItemType Directory -Path $dir -Force | Out-Null
    Set-Content -LiteralPath (Join-Path $dir 'spec.md') -Value "# Feature Specification: Host-Neutral Gate Enforcement`n`nThe authoritative contract for the active feature." -Encoding UTF8
    $null = & git -C $Proj add -- specs
    $null = & git -C $Proj -c user.name=Fixture -c user.email=fixture@example.invalid commit --quiet -m 'fixture spec'
    if ($LASTEXITCODE -ne 0) { throw 'fixture spec commit failed' }
}

function New-Transcript {
    param([string]$Proj, [object[]]$Turns)
    $dir = Join-Path $Proj '.specrew\runtime'
    New-Item -ItemType Directory -Path $dir -Force | Out-Null
    $path = Join-Path $dir ('transcript-' + [guid]::NewGuid().ToString('N') + '.jsonl')
    $lines = foreach ($t in $Turns) {
        ([pscustomobject]@{ type = $t.role; message = [pscustomobject]@{ content = @([pscustomobject]@{ type = 'text'; text = $t.text }) } } | ConvertTo-Json -Depth 8 -Compress)
    }
    [System.IO.File]::WriteAllLines($path, [string[]]$lines, [System.Text.UTF8Encoding]::new($false))
    return $path
}

function New-HandoverSnapshot {
    param(
        [string]$Proj,
        [int]$ChangedUserFiles = 0,
        [int]$NewCommits = 0,
        [int]$ActivityOffsetSeconds = 0,
        [string]$Source = 'Stop',
        [string]$FileList,
        [string]$ActiveFeature = '050-host-neutral-gate'
    )
    $dir = Join-Path $Proj '.specrew\handover'
    New-Item -ItemType Directory -Path $dir -Force | Out-Null
    $recordedAt = [datetime]::UtcNow
    $activityAt = $recordedAt.AddSeconds($ActivityOffsetSeconds)
    $stamp = $activityAt.ToUniversalTime().ToString('yyyy-MM-ddTHH:mm:ssZ')
    $commitNote = if ($NewCommits -gt 0) { ("; {0} new commit(s): abc1234 material commit" -f $NewCommits) } else { '' }
    if ([string]::IsNullOrWhiteSpace($FileList)) {
        $FileList = if ($ChangedUserFiles -gt 0) { 'src/provider.ps1, tests/provider.tests.ps1' } else { '(none)' }
    }
    if ($ChangedUserFiles -gt 0) {
        foreach ($relative in @($FileList -split ',' | ForEach-Object { $_.Trim() } | Where-Object { $_ -and $_ -ne '(none)' } | Select-Object -First $ChangedUserFiles)) {
            $full = Join-Path $Proj ($relative -replace '/', [IO.Path]::DirectorySeparatorChar)
            $parent = Split-Path -Parent $full
            if ($parent -and -not (Test-Path -LiteralPath $parent)) { New-Item -ItemType Directory -Path $parent -Force | Out-Null }
            if (-not (Test-Path -LiteralPath $full -PathType Leaf)) {
                [IO.File]::WriteAllText($full, ("fixture material: {0}`n" -f $relative), [Text.UTF8Encoding]::new($false))
            }
        }
    }
    $content = @"
---
schema: v1
source: $Source
from_host: codex
recorded_at: $($recordedAt.ToUniversalTime().ToString('o'))
from_commit: abc1234
active_feature: $ActiveFeature
active_boundary: plan
---

# Session Handover (rolling)

## What I just did (last 3-5 turns or last boundary work)

- [$stamp] ($Source) $ChangedUserFiles changed user file(s) [$FileList]; HEAD abc1234 (material commit)$commitNote

## Why I'm stopping (the switch trigger)

Hook-captured at trigger '$Source'. Boundary: plan. Refresh reason: tracked-change.

## Recommended next-immediate-step

Resume feature $ActiveFeature at boundary plan.
"@
    Set-Content -LiteralPath (Join-Path $dir 'session-handover.md') -Value $content -Encoding UTF8
}

function Invoke-Conformance {
    param([string]$Proj, [AllowNull()][string]$TranscriptPath, [string]$Event = 'Stop')
    $tpArg = if ([string]::IsNullOrWhiteSpace($TranscriptPath)) { '' } else { " --transcript-path '$TranscriptPath'" }
    $cmd = "Set-Location -LiteralPath '$Proj'; & '$provider' --host-kind claude --source-event $Event$tpArg"
    $out = & pwsh -NoProfile -ExecutionPolicy Bypass -Command $cmd 2>&1
    return [pscustomobject]@{ Out = (@($out) -join "`n"); Code = $LASTEXITCODE; Blocked = ((@($out) -join "`n") -match '<<<SPECREW-STOP-BLOCK>>>') }
}

# The five-part material context packet (mirrors conformance-detection.tests.ps1 $materialPacket) for the negative
# (already-rendered) shape reused where needed.
$materialPacket = @'
## What I Just Did

I updated the conformance provider and the focused regression tests, with the changed files under file:///fixture.

## Why I Stopped

This is a non-boundary material-work stop after code and test changes.

## What Needs Your Review

Review the material-work Stop enforcement path and the negative conversation-only case.

## What Happens Next

I will run the focused Pester checks and sync the deployed provider copy.

## What I Need From You

Review the result and tell me whether to continue.
'@

try {
    # ---- Case (a): CONTINUE. A material, packet-less stop whose CURRENT assistant turn carries the `continue` marker,
    #                with an authorized-phase start-context (last_authorized_boundary + session_state.boundary_type set)
    #                and NO pending verdict -> the classifier returns 'continue': the provider SUPPRESSES the five-part
    #                material packet and instead force-continues with a CONTINUATION DIRECTIVE (perform the next
    #                authorized action; do NOT render a status packet).
    $pa = New-Fixture -Working 'plan' -LastAuth 'plan'   # authorized in-phase: boundary_type=plan, last_auth=plan, working==auth -> no pending
    New-Spec -Proj $pa
    New-HandoverSnapshot -Proj $pa -ChangedUserFiles 2
    $ta = New-Transcript -Proj $pa -Turns @(@{ role = 'user'; text = 'continue' }, @{ role = 'assistant'; text = ("I applied the resolver change and updated the three call sites; more authorized in-phase work remains.`n`n" + $continueMarker) })
    $ra = Invoke-Conformance -Proj $pa -TranscriptPath $ta
    if ($ra.Code -ne 0) { Fail "Case (a): provider must exit 0 (got $($ra.Code)); out: $($ra.Out)" }
    if (-not $ra.Blocked) { Fail "Case (a): a continue-marker stop still force-continues the turn (it emits the STOP-BLOCK sentinel carrying the continuation directive). Out: $($ra.Out)" }
    if ($ra.Out -match 'five-part context packet') { Fail "Case (a): a continue classification MUST NOT render the five-part material packet. Out: $($ra.Out)" }
    if ($ra.Out -match 'What I Just Did' -or $ra.Out -match 'What I Need From You') { Fail "Case (a): the continuation directive MUST NOT carry the packet section headings. Out: $($ra.Out)" }
    if ($ra.Out -match 'SPECREW-VERDICT-BOUNDARY') { Fail "Case (a): a non-boundary continue MUST NOT demand a verdict-boundary marker. Out: $($ra.Out)" }
    if ($ra.Out -notmatch 'CONTINUATION DIRECTIVE') { Fail "Case (a): the output MUST be the continuation directive. Out: $($ra.Out)" }
    if ($ra.Out -notmatch 'perform the NEXT authorized action') { Fail "Case (a): the continuation directive must instruct the next authorized action. Out: $($ra.Out)" }
    $guardPath = Join-Path $pa '.specrew\runtime\conformance-continue-guard.json'
    if (-not (Test-Path -LiteralPath $guardPath)) { Fail "Case (a): the continue loop-guard counter must be written. Out: $($ra.Out)" }
    $guard = Get-Content -LiteralPath $guardPath -Raw -Encoding UTF8 | ConvertFrom-Json
    if ([int]$guard.count -ne 1) { Fail "Case (a): the continue loop-guard count must increment to 1 (got $($guard.count))." }
    if ([string]$guard.key -notlike 'continue|*') { Fail "Case (a): the continue loop-guard must be keyed 'continue|<surface>' (got $($guard.key))." }
    Write-Pass "Case (a): a material CONTINUE-marker stop in an authorized phase suppresses the five-part packet and force-continues with a continuation directive (loop-guard incremented to 1)"

    # ---- Case (b): INTERMEDIATE. Same authorized-phase material stop, but the CURRENT assistant turn carries the
    #                `intermediate` marker -> the classifier returns 'intermediate': the block is SUPPRESSED entirely
    #                (no sentinel, the turn ends; the async work's completion resumes the agent).
    $pb = New-Fixture -Working 'plan' -LastAuth 'plan'
    New-Spec -Proj $pb
    New-HandoverSnapshot -Proj $pb -ChangedUserFiles 2
    $tb = New-Transcript -Proj $pb -Turns @(@{ role = 'assistant'; text = ("Kicked off the long-running verification suite; it is still running in the background.`n`n" + $intermediateMarker) })
    $rb = Invoke-Conformance -Proj $pb -TranscriptPath $tb
    if ($rb.Code -ne 0) { Fail "Case (b): provider must exit 0 (got $($rb.Code)); out: $($rb.Out)" }
    if ($rb.Blocked) { Fail "Case (b): an intermediate-marker stop MUST NOT block (async in flight; the turn ends and resumes on completion). Out: $($rb.Out)" }
    if ($rb.Out -match 'five-part context packet') { Fail "Case (b): an intermediate stop MUST NOT render the material packet. Out: $($rb.Out)" }
    if ($rb.Out -match 'CONTINUATION DIRECTIVE') { Fail "Case (b): an intermediate stop is not a continuation directive. Out: $($rb.Out)" }
    Write-Pass "Case (b): a material INTERMEDIATE-marker stop is SUPPRESSED (no block, no packet, no directive) - the async completion resumes the agent"

    # ---- Case (c): NO MARKER -> the FAIL-SAFE / real path. A material, packet-less stop with NO stop-intent marker
    #                classifies as 'real' and the existing five-part material packet fires EXACTLY as before (this is
    #                Case 4c of conformance-detection, now proven unchanged under the classifier wiring).
    $pc = New-Fixture -Working 'plan' -LastAuth 'plan'
    New-Spec -Proj $pc
    New-HandoverSnapshot -Proj $pc -ChangedUserFiles 2
    $tc = New-Transcript -Proj $pc -Turns @(@{ role = 'assistant'; text = 'I updated the provider and tests. Stopping here.' })
    $rc = Invoke-Conformance -Proj $pc -TranscriptPath $tc
    if (-not $rc.Blocked) { Fail "Case (c): a material stop with NO marker MUST still block with the five-part packet (fail-safe/real). Out: $($rc.Out)" }
    if ($rc.Out -notmatch 'five-part context packet') { Fail "Case (c): the no-marker material block must demand the five-part context packet. Out: $($rc.Out)" }
    if ($rc.Out -notmatch 'What I Just Did' -or $rc.Out -notmatch 'What I Need From You') { Fail "Case (c): the material block directive must name the packet headings. Out: $($rc.Out)" }
    if ($rc.Out -match 'CONTINUATION DIRECTIVE') { Fail "Case (c): a no-marker material stop is NOT a continuation. Out: $($rc.Out)" }
    if ($rc.Out -match '<!-- SPECREW-VERDICT-BOUNDARY') { Fail "Case (c): a material stop must not demand a boundary verdict marker. Out: $($rc.Out)" }
    Write-Pass "Case (c): a material stop with NO stop-intent marker falls through to the existing five-part packet (fail-safe / real path unchanged)"

    # ---- Case (d): CONTINUE MARKER at a PENDING BOUNDARY -> the boundary block STILL fires (never downgraded). A
    #                pending verdict makes this a BOUNDARY stop; the classifier is scoped to MATERIAL non-boundary stops
    #                and is not even consulted, so the continue marker has ZERO effect. The block demands the contiguous
    #                clarify -> plan verdict marker exactly as today.
    $pd = New-Fixture -Working 'plan' -LastAuth 'clarify'   # working 'plan' ahead of authorized 'clarify' -> pending verdict
    New-Spec -Proj $pd
    $td = New-Transcript -Proj $pd -Turns @(@{ role = 'user'; text = 'continue' }, @{ role = 'assistant'; text = ("I wrote plan.md and started on tasks.`n`n" + $continueMarker) })
    $rd = Invoke-Conformance -Proj $pd -TranscriptPath $td
    if (-not $rd.Blocked) { Fail "Case (d): a continue marker at a PENDING boundary MUST NOT suppress the boundary block. Out: $($rd.Out)" }
    if ($rd.Out -notmatch 'SPECREW-VERDICT-BOUNDARY: clarify -> plan') { Fail "Case (d): the boundary block must still demand the contiguous clarify -> plan marker. Out: $($rd.Out)" }
    if ($rd.Out -match 'CONTINUATION DIRECTIVE') { Fail "Case (d): a boundary stop MUST NOT be downgraded to a continuation directive by the continue marker. Out: $($rd.Out)" }
    Write-Pass "Case (d): a continue marker at a pending boundary is IGNORED - the boundary block still fires (never downgraded across a boundary)"

    # ---- Case (e): RUNAWAY CONTINUE is BOUNDED. Repeated continue markers on the SAME material surface with no
    #                intervening progress accumulate the continue loop-guard; once it reaches the bound (3) the
    #                classifier returns 'real' and the standard five-part material packet fires instead - a continue can
    #                never loop forever. (Distinct messages per fire so the idempotency guard does not dedup them.)
    $pe = New-Fixture -Working 'plan' -LastAuth 'plan'
    New-Spec -Proj $pe
    for ($n = 1; $n -le 3; $n++) {
        New-HandoverSnapshot -Proj $pe -ChangedUserFiles 2   # SAME surface (default file list) -> guard accumulates
        $tn = New-Transcript -Proj $pe -Turns @(@{ role = 'assistant'; text = ("In-phase work continues (attempt $n).`n`n" + $continueMarker) })
        $rn = Invoke-Conformance -Proj $pe -TranscriptPath $tn
        if (-not $rn.Blocked) { Fail "Case (e): continue #$n (within the bound) must force-continue. Out: $($rn.Out)" }
        if ($rn.Out -notmatch 'CONTINUATION DIRECTIVE') { Fail "Case (e): continue #$n must emit the continuation directive. Out: $($rn.Out)" }
        if ($rn.Out -match 'five-part context packet') { Fail "Case (e): continue #$n must NOT yet fall back to the material packet. Out: $($rn.Out)" }
    }
    New-HandoverSnapshot -Proj $pe -ChangedUserFiles 2
    $t4 = New-Transcript -Proj $pe -Turns @(@{ role = 'assistant'; text = ("Still the same surface, no progress (attempt 4).`n`n" + $continueMarker) })
    $r4 = Invoke-Conformance -Proj $pe -TranscriptPath $t4
    if (-not $r4.Blocked) { Fail "Case (e): the 4th continue (guard tripped) must still block. Out: $($r4.Out)" }
    if ($r4.Out -match 'CONTINUATION DIRECTIVE') { Fail "Case (e): once the guard trips, the classifier returns 'real' - it must NOT keep emitting continuation directives. Out: $($r4.Out)" }
    if ($r4.Out -notmatch 'five-part context packet') { Fail "Case (e): once the guard trips, the standard five-part material packet MUST fire (runaway-continue fallback). Out: $($r4.Out)" }
    Write-Pass "Case (e): a runaway continue on the same material surface is BOUNDED - after 3 continues the guard trips and the five-part material packet fires (never an infinite continue loop)"

    Write-Host "`n=== conformance-stop-intent-wiring.tests.ps1: all assertions passed ===" -ForegroundColor Green
    exit 0
}
finally {
    Remove-Item -LiteralPath $scratch -Recurse -Force -ErrorAction SilentlyContinue
    if ($null -eq $priorModulePath) { Remove-Item Env:\SPECREW_MODULE_PATH -ErrorAction SilentlyContinue } else { $env:SPECREW_MODULE_PATH = $priorModulePath }
}
