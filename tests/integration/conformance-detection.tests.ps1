[CmdletBinding()]
param()
Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

# Feature 185 FR-011 / FR-015 / FR-004 - SC-008 / SC-011: the conformance Stop-provider DETECTION + BLOCK-request.
#
# The provider now emits a BLOCK SENTINEL (`<<<SPECREW-STOP-BLOCK>>>` + the packet directive) when a stop owes a
# boundary re-entry packet or non-boundary material-work context packet and it is absent, so the dispatcher can
# force-continue the turn (the packet renders AT the stop, not as a too-late next-turn nudge). This file tests the PROVIDER's detection + sentinel emission against
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
    $null = & git -C $proj init --quiet
    if ($LASTEXITCODE -ne 0) { throw 'fixture git init failed' }
    $null = & git -C $proj config core.autocrlf false
    [System.IO.File]::WriteAllText((Join-Path $proj '.fixture-base'), "fixture`n", [System.Text.UTF8Encoding]::new($false))
    $null = & git -C $proj add .fixture-base
    $null = & git -C $proj -c user.name=Fixture -c user.email=fixture@example.invalid commit --quiet -m 'fixture baseline'
    if ($LASTEXITCODE -ne 0) { throw 'fixture baseline commit failed' }
    return $proj
}

function Save-FixtureStructure {
    param([string]$Proj, [string]$Message)
    $null = & git -C $Proj add -- specs
    if ($LASTEXITCODE -ne 0) { throw "fixture structure add failed: $Message" }
    $pending = @(& git -C $Proj diff --cached --name-only -- specs)
    if ($pending.Count -gt 0) {
        $null = & git -C $Proj -c user.name=Fixture -c user.email=fixture@example.invalid commit --quiet -m $Message
        if ($LASTEXITCODE -ne 0) { throw "fixture structure commit failed: $Message" }
    }
}

function New-Spec {
    param([string]$Proj)
    $dir = Join-Path $Proj 'specs\050-host-neutral-gate'
    New-Item -ItemType Directory -Path $dir -Force | Out-Null
    Set-Content -LiteralPath (Join-Path $dir 'spec.md') -Value "# Feature Specification: Host-Neutral Gate Enforcement`n`nThe authoritative contract for the active feature." -Encoding UTF8
    Save-FixtureStructure -Proj $Proj -Message 'fixture spec'
}

function New-LensApplicability {
    # Write both the feature projection and the exact iteration artifact. The feature projection feeds the
    # existing progress accessor; FR-056 authorizes a workshop-intermediate Stop only from the exact iteration.
    param([string]$Proj, [string[]]$Selected, [string[]]$Done = @(), [string]$FeatureRef = '050-host-neutral-gate', [string]$Iteration = '001')
    $dir = Join-Path $Proj (Join-Path 'specs' $FeatureRef)
    New-Item -ItemType Directory -Path $dir -Force | Out-Null
    $workshop = [ordered]@{}
    foreach ($d in $Done) { $workshop[$d] = [ordered]@{ moved_on = $true } }
    $obj = [ordered]@{ workshop_intake = $true; confirmation_required = $true; selected = $Selected; workshop = $workshop }
    $json = $obj | ConvertTo-Json -Depth 6
    Set-Content -LiteralPath (Join-Path $dir 'lens-applicability.json') -Value $json -Encoding UTF8
    $iterationDir = Join-Path $dir ("iterations/{0}" -f $Iteration)
    New-Item -ItemType Directory -Path $iterationDir -Force | Out-Null
    Set-Content -LiteralPath (Join-Path $iterationDir 'lens-applicability.json') -Value $json -Encoding UTF8
    Save-FixtureStructure -Proj $Proj -Message 'fixture lens state'
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

function New-HandoverSnapshot {
    param(
        [string]$Proj,
        [int]$ChangedUserFiles = 0,
        [int]$NewCommits = 0,
        [int]$ActivityOffsetSeconds = 0,
        [string]$Source = 'Stop',
        [string]$FileList,
        [string]$ActiveFeature = '050-host-neutral-gate',
        [string]$Head = 'abc1234',
        [string]$HeadTitle = 'material commit'
    )
    $dir = Join-Path $Proj '.specrew\handover'
    New-Item -ItemType Directory -Path $dir -Force | Out-Null
    $recordedAt = [datetime]::UtcNow
    $activityAt = $recordedAt.AddSeconds($ActivityOffsetSeconds)
    $stamp = $activityAt.ToUniversalTime().ToString('yyyy-MM-ddTHH:mm:ssZ')
    $commitNote = if ($NewCommits -gt 0) { ("; {0} new commit(s): {1} {2}" -f $NewCommits, $Head, $HeadTitle) } else { '' }
    if ([string]::IsNullOrWhiteSpace($FileList)) {
        $defaults = @('src/provider.ps1', 'tests/provider.tests.ps1', 'docs/new.md', 'src/new-module.ps1', 'tests/new-module.tests.ps1')
        $FileList = if ($ChangedUserFiles -gt 0) { (@($defaults | Select-Object -First $ChangedUserFiles) -join ', ') } else { '(none)' }
    }
    if ($ChangedUserFiles -gt 0) {
        $paths = @($FileList -split ',' | ForEach-Object { $_.Trim() } | Where-Object { $_ -and $_ -ne '(none)' } | Select-Object -First $ChangedUserFiles)
        foreach ($relative in $paths) {
            $full = Join-Path $Proj ($relative -replace '/', [IO.Path]::DirectorySeparatorChar)
            $parent = Split-Path -Parent $full
            if ($parent -and -not (Test-Path -LiteralPath $parent)) { New-Item -ItemType Directory -Path $parent -Force | Out-Null }
            if (-not (Test-Path -LiteralPath $full -PathType Leaf)) {
                [IO.File]::WriteAllText($full, ("fixture material: {0}`n" -f $relative), [Text.UTF8Encoding]::new($false))
            }
        }
    }
    if ($NewCommits -gt 0) {
        foreach ($n in 1..$NewCommits) {
            $sequence = @(& git -C $Proj rev-list --count HEAD)
            $marker = ".fixture-commit-$($sequence[0])-$n.txt"
            [IO.File]::WriteAllText((Join-Path $Proj $marker), ("commit $marker`n"), [Text.UTF8Encoding]::new($false))
            $null = & git -C $Proj add -- $marker
            $null = & git -C $Proj -c user.name=Fixture -c user.email=fixture@example.invalid commit --quiet -m $HeadTitle
            if ($LASTEXITCODE -ne 0) { throw "fixture material commit failed: $HeadTitle" }
        }
    }
    $content = @"
---
schema: v1
source: $Source
from_host: codex
recorded_at: $($recordedAt.ToUniversalTime().ToString('o'))
from_commit: $Head
active_feature: $ActiveFeature
active_boundary: plan
---

# Session Handover (rolling)

## What I just did (last 3-5 turns or last boundary work)

- [$stamp] ($Source) $ChangedUserFiles changed user file(s) [$FileList]; HEAD $Head ($HeadTitle)$commitNote

## Why I'm stopping (the switch trigger)

Hook-captured at trigger '$Source'. Boundary: plan. Refresh reason: tracked-change.

## Open questions / pending clarifications

(placeholder)

## Agent's working hypothesis / mental model

(placeholder)

## Recommended next-immediate-step

Resume feature $ActiveFeature at boundary plan.

## Context the receiving host needs that artifacts don't carry

branch 185-host-neutral-gate-enforcement, HEAD $Head ($HeadTitle).

## Recent conversation (last few exchanges, hook-captured)

(placeholder)

## Authored boundary packet (captured at stop)

(placeholder)
"@
    Set-Content -LiteralPath (Join-Path $dir 'session-handover.md') -Value $content -Encoding UTF8
}

function Invoke-Conformance {
    param([string]$Proj, [AllowNull()][string]$TranscriptPath, [string]$Event = 'Stop', [AllowNull()][string]$SessionId)
    $tpArg = if ([string]::IsNullOrWhiteSpace($TranscriptPath)) { '' } else { " --transcript-path '$TranscriptPath'" }
    $sessionArg = if ([string]::IsNullOrWhiteSpace($SessionId)) { '' } else { " --session-id '$SessionId'" }
    $cmd = "Set-Location -LiteralPath '$Proj'; & '$provider' --host-kind claude --source-event $Event$sessionArg$tpArg"
    $out = & pwsh -NoProfile -ExecutionPolicy Bypass -Command $cmd 2>&1
    return [pscustomobject]@{ Out = (@($out) -join "`n"); Code = $LASTEXITCODE; Blocked = ((@($out) -join "`n") -match '<<<SPECREW-STOP-BLOCK>>>') }
}

function Get-TestSessionStatePath {
    param([string]$Proj, [string]$SessionId, [string]$Leaf = 'turn-baseline.json')
    $owner = "claude|$SessionId"
    $bytes = [System.Text.Encoding]::UTF8.GetBytes($owner)
    $hash = -join ([System.Security.Cryptography.SHA256]::Create().ComputeHash($bytes) | ForEach-Object { $_.ToString('x2') })
    return (Join-Path (Join-Path (Join-Path $Proj '.specrew/runtime/conformance-sessions') $hash) $Leaf)
}

function Invoke-BarrierSynchronizedSessionStarts {
    param([string]$Proj, [string[]]$SessionIds)
    $barrier = Join-Path $Proj ('.specrew/runtime/barrier-' + [guid]::NewGuid().ToString('N'))
    New-Item -ItemType Directory -Path $barrier -Force | Out-Null
    $release = Join-Path $barrier 'release'
    $jobs = @()
    $worker = {
        param($ProviderPath, $ProjectPath, $SessionId, $ReadyPath, $ReleasePath, $ModulePath)
        $env:SPECREW_MODULE_PATH = $ModulePath
        [System.IO.File]::WriteAllText($ReadyPath, $SessionId, [System.Text.UTF8Encoding]::new($false))
        $deadline = [DateTime]::UtcNow.AddSeconds(20)
        while (-not (Test-Path -LiteralPath $ReleasePath -PathType Leaf) -and [DateTime]::UtcNow -lt $deadline) { Start-Sleep -Milliseconds 20 }
        if (-not (Test-Path -LiteralPath $ReleasePath -PathType Leaf)) { throw "barrier-release-timeout:$SessionId" }
        Set-Location -LiteralPath $ProjectPath
        $out = & pwsh -NoProfile -ExecutionPolicy Bypass -File $ProviderPath --host-kind claude --source-event SessionStart --session-id $SessionId 2>&1
        [pscustomobject]@{ session_id = $SessionId; code = $LASTEXITCODE; output = (@($out) -join "`n") }
    }
    try {
        foreach ($sessionId in $SessionIds) {
            $ready = Join-Path $barrier ("ready-$sessionId")
            $jobs += Start-Job -ScriptBlock $worker -ArgumentList $provider, $Proj, $sessionId, $ready, $release, $repoRoot
        }
        $deadline = [DateTime]::UtcNow.AddSeconds(20)
        while (@(Get-ChildItem -LiteralPath $barrier -Filter 'ready-*' -File -ErrorAction SilentlyContinue).Count -lt $SessionIds.Count -and [DateTime]::UtcNow -lt $deadline) { Start-Sleep -Milliseconds 20 }
        if (@(Get-ChildItem -LiteralPath $barrier -Filter 'ready-*' -File -ErrorAction SilentlyContinue).Count -ne $SessionIds.Count) { throw 'barrier-ready-timeout' }
        [System.IO.File]::WriteAllText($release, 'go', [System.Text.UTF8Encoding]::new($false))
        $null = Wait-Job -Job $jobs -Timeout 40
        if (@($jobs | Where-Object State -ne 'Completed').Count -gt 0) { throw 'barrier-sessionstart-timeout' }
        return @($jobs | Receive-Job)
    }
    finally {
        $jobs | Stop-Job -ErrorAction SilentlyContinue
        $jobs | Remove-Job -Force -ErrorAction SilentlyContinue
    }
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

# A long (>600 char) NON-packet hand-back: substantial prose with no section headers and no verdict marker.
$longProse = ('I went ahead and refactored the resolver and the three call sites, tightened the error handling around the cache, ' +
    'added a couple of guard clauses, and tidied the logging so it is consistent across the module. I also looked into the ' +
    'flaky integration path and I think it is a race in the warmup step, though I have not confirmed it yet. There are a few ' +
    'directions we could take from here and I am not sure which you prefer, so let me know how you want to proceed and whether ' +
    'I should keep going on the warmup race or pivot to the other items we discussed earlier this afternoon in some detail. ' +
    'I also want to flag that the dependency bump touches two manifests and a lockfile, so we should decide whether to land ' +
    'that separately or fold it into this change; either way I can prepare both and you can pick the one you would rather take.')

$workshopQuestion = @'
### architecture-core lens

The architecture-core discussion has established the component boundary and the remaining choice is who owns the durable transition. The current iteration record still names this as the first unfinished lens.

Should the repository own that transition directly, or should the application service own it behind a port?
<!-- SPECREW-WORKSHOP-QUESTION: feature=050-host-neutral-gate; iteration=001; lens=architecture-core -->
'@

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

    # ---- Case 2: FALSE-POSITIVE GUARD (boundary). Same state, but the packet WAS rendered this turn
    #              (clarify -> plan == pending crossing) -> no block.
    $p2 = New-Fixture -Working 'plan' -LastAuth 'clarify'
    $t2 = New-Transcript -Proj $p2 -Turns @(@{ role = 'user'; text = 'continue' }, @{ role = 'assistant'; text = $realPacket })
    $r2 = Invoke-Conformance -Proj $p2 -TranscriptPath $t2
    if ($r2.Blocked) { Fail "Case 2: a rendered packet (clarify -> plan == pending crossing) is a legitimate awaiting-verdict stop - MUST NOT block. Out: $($r2.Out)" }
    Write-Pass "Case 2: a rendered six-section packet matching the pending crossing SUPPRESSES the block (false-positive guard)"

    # ---- Case 3: cursor caught up. working == authorized, no spec, short msg -> not pending, not substantial -> no block.
    $p3 = New-Fixture -Working 'plan' -LastAuth 'plan'
    $t3 = New-Transcript -Proj $p3 -Turns @(@{ role = 'assistant'; text = 'Plan approved; proceeding.' })
    $r3 = Invoke-Conformance -Proj $p3 -TranscriptPath $t3
    if ($r3.Blocked) { Fail "Case 3: working == authorized + short message MUST NOT block. Out: $($r3.Out)" }
    Write-Pass "Case 3: working == authorized + a short reply does NOT block (no false alarm)"

    # ---- Case 4: a SUBSTANTIAL non-boundary hand-back (a long but communicative DISCUSSION / status answer) MUST NOT
    #              block. The >=600-char "substantial" trigger was DROPPED (maintainer 2026-06-21): a long answer is
    #              not a decision-yield; only BOUNDARY stops force the packet. (This is the over-block the maintainer hit.)
    $p4 = New-Fixture -Working 'plan' -LastAuth 'plan'
    New-Spec -Proj $p4
    $t4 = New-Transcript -Proj $p4 -Turns @(@{ role = 'user'; text = 'go' }, @{ role = 'assistant'; text = $longProse })
    $r4 = Invoke-Conformance -Proj $p4 -TranscriptPath $t4
    if ($r4.Blocked) { Fail "Case 4: a substantial non-boundary DISCUSSION answer MUST NOT block (the length trigger was dropped; conversation flows). Out: $($r4.Out)" }
    Write-Pass "Case 4: a SUBSTANTIAL non-boundary hand-back (a long discussion/status answer) does NOT block - only decision-yield boundaries force the packet (maintainer 2026-06-21)"

    # ---- Case 4b: SUBSTANTIAL but PRE-SPEC. Same long message, NO spec, no pending -> NO block.
    $p4b = New-Fixture -Working 'plan' -LastAuth 'plan'
    $t4b = New-Transcript -Proj $p4b -Turns @(@{ role = 'assistant'; text = $longProse })
    $r4b = Invoke-Conformance -Proj $p4b -TranscriptPath $t4b
    if ($r4b.Blocked) { Fail "Case 4b: a substantial message pre-spec MUST NOT block on length alone. Out: $($r4b.Out)" }
    Write-Pass "Case 4b: a substantial PRE-SPEC message does not create a packet obligation by length alone"

    # ---- Case 4c: MATERIAL non-boundary stop. The current Stop handover reports changed user files and the last
    #               assistant message has no packet -> emit the block sentinel with the five-part context directive.
    $p4c = New-Fixture -Working 'plan' -LastAuth 'plan'
    New-Spec -Proj $p4c
    New-HandoverSnapshot -Proj $p4c -ChangedUserFiles 2
    $t4c = New-Transcript -Proj $p4c -Turns @(@{ role = 'assistant'; text = 'I updated the provider and tests. Stopping here.' })
    $r4c = Invoke-Conformance -Proj $p4c -TranscriptPath $t4c
    if (-not $r4c.Blocked) { Fail "Case 4c: a material non-boundary Stop with no context packet MUST block. Out: $($r4c.Out)" }
    if ($r4c.Out -notmatch 'five-part context packet') { Fail "Case 4c: material block must demand the five-part context packet, not a boundary verdict packet. Out: $($r4c.Out)" }
    if ($r4c.Out -notmatch 'What I Just Did' -or $r4c.Out -notmatch 'What I Need From You') { Fail "Case 4c: material block directive must name the packet headings. Out: $($r4c.Out)" }
    if ($r4c.Out -match '<!-- SPECREW-VERDICT-BOUNDARY') { Fail "Case 4c: material block must not demand a boundary verdict marker. Out: $($r4c.Out)" }
    Write-Pass "Case 4c: a MATERIAL non-boundary Stop without the context packet emits the stop-block sentinel + five-part directive"

    # ---- Case 4d: MATERIAL non-boundary stop with the five-part context packet already rendered -> no block.
    $p4d = New-Fixture -Working 'plan' -LastAuth 'plan'
    New-Spec -Proj $p4d
    New-HandoverSnapshot -Proj $p4d -ChangedUserFiles 2
    $t4d = New-Transcript -Proj $p4d -Turns @(@{ role = 'assistant'; text = $materialPacket })
    $r4d = Invoke-Conformance -Proj $p4d -TranscriptPath $t4d
    if ($r4d.Blocked) { Fail "Case 4d: a material Stop with the five-part context packet already rendered MUST NOT block. Out: $($r4d.Out)" }
    Write-Pass "Case 4d: a MATERIAL non-boundary Stop with the five-part context packet does NOT block"

    # ---- Case 4d2: SAME dirty surface after a packet was rendered. A later quick answer while the same files remain
    #                uncommitted MUST NOT keep demanding the packet over and over.
    New-HandoverSnapshot -Proj $p4d -ChangedUserFiles 2
    $t4d2 = New-Transcript -Proj $p4d -Turns @(@{ role = 'assistant'; text = 'That is the remaining open issue list.' })
    $r4d2 = Invoke-Conformance -Proj $p4d -TranscriptPath $t4d2
    if ($r4d2.Blocked) { Fail "Case 4d2: once a packet was rendered for the same dirty-state surface, a later quick answer MUST NOT re-block. Out: $($r4d2.Out)" }
    Write-Pass "Case 4d2: a quick follow-up on the SAME dirty-state surface does NOT re-block after the material packet was rendered"

    # ---- Case 4d3: CHANGED dirty surface after satisfaction. A new material surface needs a fresh packet.
    New-HandoverSnapshot -Proj $p4d -ChangedUserFiles 3 -FileList 'src/provider.ps1, tests/provider.tests.ps1, docs/new.md'
    $t4d3 = New-Transcript -Proj $p4d -Turns @(@{ role = 'assistant'; text = 'I made one more related change.' })
    $r4d3 = Invoke-Conformance -Proj $p4d -TranscriptPath $t4d3
    if (-not $r4d3.Blocked) { Fail "Case 4d3: a changed dirty-state surface after a satisfied material packet MUST re-block. Out: $($r4d3.Out)" }
    Write-Pass "Case 4d3: a CHANGED dirty-state surface after satisfaction requires a fresh material packet"

    # ---- Case 4e: CONVERSATION-only stop after earlier material work. Handover recorded_at is current, but the
    #               latest activity bullet is older, so this is a conversation refresh and MUST NOT block.
    $p4e = New-Fixture -Working 'plan' -LastAuth 'plan'
    New-Spec -Proj $p4e
    New-HandoverSnapshot -Proj $p4e -ChangedUserFiles 2 -ActivityOffsetSeconds -120
    $null = Invoke-Conformance -Proj $p4e -Event SessionStart
    $t4e = New-Transcript -Proj $p4e -Turns @(@{ role = 'assistant'; text = $longProse })
    $r4e = Invoke-Conformance -Proj $p4e -TranscriptPath $t4e
    if ($r4e.Blocked) { Fail "Case 4e: a conversation-only Stop with only an older material bullet MUST NOT block. Out: $($r4e.Out)" }
    Write-Pass "Case 4e: an end-of-turn conversation refresh after earlier material work does NOT block"

    # ---- Case 4f: MATERIAL retry loop. If the forced-continue response still omits the packet, the previous
    #               material block key keeps enforcing until the packet appears or the cap releases.
    $p4f = New-Fixture -Working 'plan' -LastAuth 'plan'
    New-Spec -Proj $p4f
    New-HandoverSnapshot -Proj $p4f -ChangedUserFiles 2
    $t4f1 = New-Transcript -Proj $p4f -Turns @(@{ role = 'assistant'; text = 'I changed code and tests, stopping.' })
    $r4f1 = Invoke-Conformance -Proj $p4f -TranscriptPath $t4f1
    if (-not $r4f1.Blocked) { Fail "Case 4f: first material packet-less stop MUST block. Out: $($r4f1.Out)" }
    New-HandoverSnapshot -Proj $p4f -ChangedUserFiles 2 -ActivityOffsetSeconds -120
    $t4f2 = New-Transcript -Proj $p4f -Turns @(@{ role = 'assistant'; text = 'Still stopping without the packet.' })
    $r4f2 = Invoke-Conformance -Proj $p4f -TranscriptPath $t4f2
    if (-not $r4f2.Blocked) { Fail "Case 4f: a forced-continue response that still omits the packet MUST re-block against the existing material key. Out: $($r4f2.Out)" }
    $t4f3 = New-Transcript -Proj $p4f -Turns @(@{ role = 'assistant'; text = $materialPacket })
    $r4f3 = Invoke-Conformance -Proj $p4f -TranscriptPath $t4f3
    if ($r4f3.Blocked) { Fail "Case 4f: rendering the material context packet must reset/release the material retry block. Out: $($r4f3.Out)" }
    Write-Pass "Case 4f: material stop-block retries until the packet is rendered, then releases"

    # ---- Case 4g / FR-056(b): the same material question OUTSIDE exact durable workshop state still owes the
    #               ordinary packet. A question-shaped turn alone must never create the exception.
    $p4g = New-Fixture -Working '' -LastAuth ''
    New-Spec -Proj $p4g
    New-HandoverSnapshot -Proj $p4g -ChangedUserFiles 3 -FileList 'AGENTS.md, CLAUDE.md, specs/001-multi-ai-arena-ui/spec.md'
    $t4g = New-Transcript -Proj $p4g -Turns @(@{ role = 'assistant'; text = $workshopQuestion })
    $r4g = Invoke-Conformance -Proj $p4g -TranscriptPath $t4g
    if (-not $r4g.Blocked -or $r4g.Out -notmatch 'five-part context packet') { Fail "Case 4g: a material workshop-shaped turn without exact iteration state MUST require the ordinary packet. Out: $($r4g.Out)" }
    Write-Pass "Case 4g: a workshop-shaped material turn outside exact durable workshop state still requires the five-part packet"

    # ---- Case 4h: MATERIAL after WORKSHOP COMPLETE, even if lifecycle state still has no active boundary/auth.
    #               Clean/dirty is not the rule: a new commit is material. Anchorless lifecycle state must not mask
    #               post-workshop material work merely because start-context has not advanced.
    $p4h = New-Fixture -Working '' -LastAuth ''
    New-Spec -Proj $p4h
    New-LensApplicability -Proj $p4h -Selected @('product-domain','architecture-core') -Done @('product-domain','architecture-core')
    $null = Invoke-Conformance -Proj $p4h -Event SessionStart
    New-HandoverSnapshot -Proj $p4h -NewCommits 1 -FileList '(none)'
    $t4h = New-Transcript -Proj $p4h -Turns @(@{ role = 'assistant'; text = 'I committed the hook budget fix and the repository is clean.' })
    $r4h = Invoke-Conformance -Proj $p4h -TranscriptPath $t4h
    if (-not $r4h.Blocked) { Fail "Case 4h: completed-workshop material commit MUST still block for the material packet even when start-context is pre-boundary. Out: $($r4h.Out)" }
    if ($r4h.Out -notmatch 'five-part context packet') { Fail "Case 4h: completed-workshop material block must demand the five-part context packet. Out: $($r4h.Out)" }
    Write-Pass "Case 4h: completed-workshop material commit still requires the five-part context packet"

    # ---- Case 4i: MATERIAL after WORKSHOP COMPLETE in a multi-feature repo. If start-context is anchorless, the
    #               active feature must come from the current Stop handover, not the first specs/* directory.
    $p4i = New-Fixture -Working '' -LastAuth ''
    $abandonedDir = Join-Path $p4i 'specs\001-abandoned-feature'
    New-Item -ItemType Directory -Path $abandonedDir -Force | Out-Null
    Set-Content -LiteralPath (Join-Path $abandonedDir 'spec.md') -Value "# Feature Specification: Abandoned`n" -Encoding UTF8
    New-LensApplicability -Proj $p4i -FeatureRef '001-abandoned-feature' -Selected @('product-domain','architecture-core') -Done @('product-domain')
    $activeDir = Join-Path $p4i 'specs\185-host-neutral-gate-enforcement'
    New-Item -ItemType Directory -Path $activeDir -Force | Out-Null
    Set-Content -LiteralPath (Join-Path $activeDir 'spec.md') -Value "# Feature Specification: Host-Neutral Gate Enforcement`n" -Encoding UTF8
    New-LensApplicability -Proj $p4i -FeatureRef '185-host-neutral-gate-enforcement' -Selected @('product-domain','architecture-core') -Done @('product-domain','architecture-core')
    Save-FixtureStructure -Proj $p4i -Message 'fixture multi-feature state'
    $null = Invoke-Conformance -Proj $p4i -Event SessionStart
    New-HandoverSnapshot -Proj $p4i -NewCommits 1 -FileList '(none)' -ActiveFeature '185-host-neutral-gate-enforcement'
    $t4i = New-Transcript -Proj $p4i -Turns @(@{ role = 'assistant'; text = 'I committed the verdict capture fix and refreshed the dogfood project.' })
    $r4i = Invoke-Conformance -Proj $p4i -TranscriptPath $t4i
    if (-not $r4i.Blocked) { Fail "Case 4i: handover active_feature must beat first-spec fallback; completed active feature material commit MUST block. Out: $($r4i.Out)" }
    if ($r4i.Out -notmatch 'five-part context packet') { Fail "Case 4i: material block must demand the five-part context packet. Out: $($r4i.Out)" }
    Write-Pass "Case 4i: handover active_feature scopes material enforcement in multi-feature pre-boundary state"

    # ==== Maintainer packet-hardening fixtures (a)-(f), 2026-07-14: the Stop packet demand keys on the TURN'S
    # ====   OWN delta (session baseline), long read-only investigations, and the unchanged boundary contract.

    # ---- Case PH-a: SHORT CONSULTATION, no writes -> no packet demand.
    $pha = New-Fixture -Working 'plan' -LastAuth 'plan'
    New-Spec -Proj $pha
    New-HandoverSnapshot -Proj $pha -ChangedUserFiles 0
    $tha = New-Transcript -Proj $pha -Turns @(@{ role = 'user'; text = 'what does the resolver do?' }, @{ role = 'assistant'; text = 'It resolves the machinery path list from the one source of truth.' })
    $rha = Invoke-Conformance -Proj $pha -TranscriptPath $tha
    if ($rha.Blocked) { Fail "Case PH-a: a short consultation with no writes MUST NOT demand the packet. Out: $($rha.Out)" }
    Write-Pass "Case PH-a: a short consultation turn with no writes owes no packet (maintainer fixture a)"

    # ---- Case PH-b: READ-ONLY STATUS over a PRE-EXISTING dirty tree -> no packet demand. The exact 2026-07-14
    #      regression: files an earlier session left dirty made a status answer read as material and forced a
    #      duplicate five-part packet. SessionStart absorbs the surface into the baseline; the identical surface
    #      at the Stop is then NOT this turn's work.
    $phb = New-Fixture -Working 'plan' -LastAuth 'plan'
    New-Spec -Proj $phb
    New-HandoverSnapshot -Proj $phb -ChangedUserFiles 2   # the previous session's dirty surface
    $rbBase = Invoke-Conformance -Proj $phb -Event SessionStart
    if ($rbBase.Code -ne 0) { Fail "Case PH-b: the SessionStart baseline lane must exit 0. Out: $($rbBase.Out)" }
    if (-not (Test-Path -LiteralPath (Join-Path $phb '.specrew\runtime\conformance-turn-baseline.json'))) { Fail "Case PH-b: SessionStart must persist the live turn baseline." }
    New-HandoverSnapshot -Proj $phb -ChangedUserFiles 2   # the SAME surface, refreshed at this turn's stop
    $thb = New-Transcript -Proj $phb -Turns @(@{ role = 'user'; text = 'status' }, @{ role = 'assistant'; text = 'Iteration 003 is executing; 8 tasks done, T019 in progress, validator has 40 soft warnings.' })
    $rhb = Invoke-Conformance -Proj $phb -TranscriptPath $thb
    if ($rhb.Blocked) { Fail "Case PH-b: a read-only status turn over a PRE-EXISTING dirty surface (== session baseline) MUST NOT demand the packet. Out: $($rhb.Out)" }
    Write-Pass "Case PH-b: read-only status over a pre-session dirty tree owes no packet - the SessionStart baseline absorbs foreign dirt (maintainer fixture b)"

    # ---- Case PH-prompt: Claude's real UserPromptSubmit provider path refreshes the live baseline. A same-path
    # edit afterwards is exact turn work, and the nudge may say "this turn" only in that exact mode.
    $phPrompt = New-Fixture -Working 'plan' -LastAuth 'plan'
    New-Spec -Proj $phPrompt
    New-HandoverSnapshot -Proj $phPrompt -ChangedUserFiles 1 -FileList 'src/prompt-owned.ps1'
    $promptSession = 'prompt-owner'
    $promptStart = Invoke-Conformance -Proj $phPrompt -Event UserPromptSubmit -SessionId $promptSession
    if ($promptStart.Code -ne 0) { Fail "Case PH-prompt: Claude UserPromptSubmit baseline capture failed. Out: $($promptStart.Out)" }
    $promptBaselinePath = Get-TestSessionStatePath -Proj $phPrompt -SessionId $promptSession
    $promptBaseline = Get-Content -LiteralPath $promptBaselinePath -Raw | ConvertFrom-Json
    if ([string]$promptBaseline.capture_event -ne 'UserPromptSubmit') { Fail "Case PH-prompt: baseline was not captured by the genuine prompt event. Record: $($promptBaseline | ConvertTo-Json -Compress)" }
    [IO.File]::WriteAllText((Join-Path $phPrompt 'src/prompt-owned.ps1'), "same path, new content`n", [Text.UTF8Encoding]::new($false))
    $promptNudge = Invoke-Conformance -Proj $phPrompt -Event PostToolUse -SessionId $promptSession
    if ($promptNudge.Out -notmatch 'MATERIAL WORK IN PROGRESS this turn \(1 changed user file\(s\)') { Fail "Case PH-prompt: exact prompt-owned same-path edit did not render an exact-turn nudge. Out: $($promptNudge.Out)" }
    Write-Pass "Case PH-prompt: Claude UserPromptSubmit reaches the production provider, captures the owner baseline, and enables exact same-path turn attribution"

    # ---- Case PH-degraded: no prompt baseline means capability is absent/stale. The cooperative message is honest
    # about CURRENT worktree dirt and never claims that another session's dirty files were changed "this turn".
    $phDegraded = New-Fixture -Working 'plan' -LastAuth 'plan'
    New-Spec -Proj $phDegraded
    New-HandoverSnapshot -Proj $phDegraded -ChangedUserFiles 2
    $degradedNudge = Invoke-Conformance -Proj $phDegraded -Event PostToolUse -SessionId 'degraded-owner'
    if ($degradedNudge.Out -notmatch 'CURRENTLY DIRTY IN THE WORKTREE \(2 user file\(s\)\)') { Fail "Case PH-degraded: missing prompt baseline did not display the degraded current-worktree message. Out: $($degradedNudge.Out)" }
    if ($degradedNudge.Out -match 'this turn') { Fail "Case PH-degraded: degraded attribution must never say 'this turn'. Out: $($degradedNudge.Out)" }
    Write-Pass "Case PH-degraded: missing prompt capability reports only current worktree dirt and never fabricates turn ownership"

    # ---- Case PH-ms: two real child sessions cross the SessionStart barrier together and retain distinct
    # baselines. Session B then owns a new exact surface through PostToolUse. Session A's routine status Stop must
    # not be billed for B's files, while B's own packet-less Stop must request exactly one context packet.
    $phms = New-Fixture -Working 'plan' -LastAuth 'plan'
    New-Spec -Proj $phms
    New-HandoverSnapshot -Proj $phms -ChangedUserFiles 2 -FileList 'src/preexisting.ps1, tests/preexisting.tests.ps1'
    $sessionA = 't069-session-a'
    $sessionB = 't069-session-b'
    $sessionStarts = @(Invoke-BarrierSynchronizedSessionStarts -Proj $phms -SessionIds @($sessionA, $sessionB))
    if ($sessionStarts.Count -ne 2 -or @($sessionStarts | Where-Object { [int]$_.code -ne 0 }).Count -gt 0) { Fail "Case PH-ms: barrier-synchronized SessionStart calls failed: $($sessionStarts | ConvertTo-Json -Compress)" }
    $baselineA = Get-TestSessionStatePath -Proj $phms -SessionId $sessionA
    $baselineB = Get-TestSessionStatePath -Proj $phms -SessionId $sessionB
    if (-not (Test-Path -LiteralPath $baselineA -PathType Leaf) -or -not (Test-Path -LiteralPath $baselineB -PathType Leaf) -or $baselineA -eq $baselineB) { Fail 'Case PH-ms: concurrent sessions did not receive distinct owner-scoped baseline files.' }
    if (Test-Path -LiteralPath (Join-Path $phms '.specrew/runtime/conformance-turn-baseline.json') -PathType Leaf) { Fail 'Case PH-ms: production session dispatch must not write the legacy shared turn baseline.' }
    $null = Invoke-Conformance -Proj $phms -Event UserPromptSubmit -SessionId $sessionA
    $null = Invoke-Conformance -Proj $phms -Event UserPromptSubmit -SessionId $sessionB

    $ownedFiles = 'src/preexisting.ps1, tests/preexisting.tests.ps1, src/session-b.ps1, tests/session-b.tests.ps1'
    New-HandoverSnapshot -Proj $phms -ChangedUserFiles 4 -FileList $ownedFiles -Source 'PostToolUse'
    $postB = Invoke-Conformance -Proj $phms -Event PostToolUse -SessionId $sessionB
    if ($postB.Code -ne 0) { Fail "Case PH-ms: session B PostToolUse attribution failed. Out: $($postB.Out)" }
    if ($postB.Out -notmatch 'MATERIAL WORK IN PROGRESS this turn') { Fail "Case PH-ms: exact owner PostToolUse did not render the exact-turn message. Out: $($postB.Out)" }
    $ownerRecord = Get-Content -LiteralPath (Join-Path $phms '.specrew/runtime/conformance-material-owner.json') -Raw -Encoding UTF8 | ConvertFrom-Json
    if ([string]$ownerRecord.owner -ne "claude|$sessionB") { Fail "Case PH-ms: exact material surface was not attributed to session B (owner='$($ownerRecord.owner)')." }

    New-HandoverSnapshot -Proj $phms -ChangedUserFiles 4 -FileList $ownedFiles -Source 'Stop'
    $statusA = New-Transcript -Proj $phms -Turns @(@{ role = 'user'; text = 'status' }, @{ role = 'assistant'; text = 'The other session is still working; I made no changes in this discussion.' })
    $stopA = Invoke-Conformance -Proj $phms -TranscriptPath $statusA -SessionId $sessionA
    if ($stopA.Blocked) { Fail "Case PH-ms: session A was billed for session B's exact material surface. Out: $($stopA.Out)" }
    $workB = New-Transcript -Proj $phms -Turns @(@{ role = 'user'; text = 'finish the repair' }, @{ role = 'assistant'; text = 'I implemented the session B repair and its tests.' })
    $stopB = Invoke-Conformance -Proj $phms -TranscriptPath $workB -SessionId $sessionB
    if (-not $stopB.Blocked) { Fail "Case PH-ms: the owning session's genuine material Stop did not request its packet. Out: $($stopB.Out)" }
    if ([regex]::Matches($stopB.Out, 'five-part context packet').Count -ne 1) { Fail "Case PH-ms: the owning session must receive exactly one packet request. Out: $($stopB.Out)" }
    Write-Pass 'Case PH-ms: barrier-synchronized sessions keep separate baselines; foreign work stays conversational and same-owner work requests one packet'

    # ---- Case PH-c: SUBSTANTIAL STATE-CHANGING WORK -> packet required. Same project: the surface CHANGES
    #      relative to the baseline (new files appear), the last message has no packet -> block.
    New-HandoverSnapshot -Proj $phb -ChangedUserFiles 4 -FileList 'src/provider.ps1, tests/provider.tests.ps1, src/new-module.ps1, tests/new-module.tests.ps1'
    $thc = New-Transcript -Proj $phb -Turns @(@{ role = 'user'; text = 'fix it' }, @{ role = 'assistant'; text = 'I implemented the module and its tests. Stopping here.' })
    $rhc = Invoke-Conformance -Proj $phb -TranscriptPath $thc
    if (-not $rhc.Blocked) { Fail "Case PH-c: state-changing work (surface != baseline) without the packet MUST block. Out: $($rhc.Out)" }
    if ($rhc.Out -notmatch 'five-part context packet') { Fail "Case PH-c: the demand must be the five-part non-boundary packet. Out: $($rhc.Out)" }
    Write-Pass "Case PH-c: substantial state-changing work still requires the five-heading packet (maintainer fixture c)"

    # ---- Case PH-e: an ALREADY VALID packet is accepted without another turn (same changed surface).
    $the = New-Transcript -Proj $phb -Turns @(@{ role = 'user'; text = 'fix it' }, @{ role = 'assistant'; text = $materialPacket })
    $rhe = Invoke-Conformance -Proj $phb -TranscriptPath $the
    if ($rhe.Blocked) { Fail "Case PH-e: a rendered five-part packet MUST be accepted without another forced turn. Out: $($rhe.Out)" }
    Write-Pass "Case PH-e: an already-valid five-part packet is accepted as-is - no duplicate turn (maintainer fixture e)"

    # ---- Case PH-b2: after the packet discharged the changed surface, a follow-up READ-ONLY turn over the
    #      (still dirty, unchanged) tree owes nothing - the baseline advanced at the discharged stop.
    New-HandoverSnapshot -Proj $phb -ChangedUserFiles 4 -FileList 'src/provider.ps1, tests/provider.tests.ps1, src/new-module.ps1, tests/new-module.tests.ps1'
    $thb2 = New-Transcript -Proj $phb -Turns @(@{ role = 'user'; text = 'thanks' }, @{ role = 'assistant'; text = 'Summarized above; nothing else changed.' })
    $rhb2 = Invoke-Conformance -Proj $phb -TranscriptPath $thb2
    if ($rhb2.Blocked) { Fail "Case PH-b2: a read-only follow-up over the SAME discharged surface MUST NOT re-demand the packet. Out: $($rhb2.Out)" }
    Write-Pass "Case PH-b2: the baseline advances at a discharged stop, so unchanged-dirty follow-ups stay quiet"

    # ---- Case PH-b3: the first Stop after a commit carries a TRANSIENT '; 1 new commit(s)' annotation. The next
    #      ordinary discussion over the exact same HEAD/files loses only that annotation. It is the same material
    #      surface and MUST stay quiet; the transient observation is not a second turn delta. This is the live
    #      DRIFT-198-I007-002 reproduction from the local-Mac discussion.
    $phb3 = New-Fixture -Working 'plan' -LastAuth 'plan'
    New-Spec -Proj $phb3
    New-HandoverSnapshot -Proj $phb3 -ChangedUserFiles 2 -NewCommits 1 -Head 'def5678' -HeadTitle 'record substantial work'
    $thb3a = New-Transcript -Proj $phb3 -Turns @(@{ role = 'assistant'; text = $materialPacket })
    $rhb3a = Invoke-Conformance -Proj $phb3 -TranscriptPath $thb3a
    if ($rhb3a.Blocked) { Fail "Case PH-b3: the packet rendered for the newly observed commit MUST discharge that surface. Out: $($rhb3a.Out)" }
    New-HandoverSnapshot -Proj $phb3 -ChangedUserFiles 2 -Head 'def5678' -HeadTitle 'record substantial work'
    $thb3b = New-Transcript -Proj $phb3 -Turns @(@{ role = 'user'; text = 'what happens next?' }, @{ role = 'assistant'; text = 'The Mac test is complete; the remaining provider slots are separate.' })
    $rhb3b = Invoke-Conformance -Proj $phb3 -TranscriptPath $thb3b
    if ($rhb3b.Blocked) { Fail "Case PH-b3: disappearance of the transient new-commit annotation on the SAME HEAD/files MUST NOT fabricate another material delta. Out: $($rhb3b.Out)" }
    Write-Pass "Case PH-b3: an unchanged committed surface stays quiet when its transient new-commit annotation disappears"

    # ---- Case PH-c2: stripping the transient annotation must not hide a REAL later commit. HEAD remains in the
    #      canonical surface key, so a different HEAD still creates a new obligation even when files are unchanged.
    New-HandoverSnapshot -Proj $phb3 -ChangedUserFiles 2 -NewCommits 1 -Head 'fed9876' -HeadTitle 'second substantial change'
    $thc2 = New-Transcript -Proj $phb3 -Turns @(@{ role = 'assistant'; text = 'I committed a second substantial change.' })
    $rhc2 = Invoke-Conformance -Proj $phb3 -TranscriptPath $thc2
    if (-not $rhc2.Blocked -or $rhc2.Out -notmatch 'five-part context packet') { Fail "Case PH-c2: a genuinely different HEAD MUST still require the material packet. Out: $($rhc2.Out)" }
    Write-Pass "Case PH-c2: a genuinely new HEAD remains a new material surface and still requires the packet"

    # ---- Case PH-d: LONG READ-ONLY INVESTIGATION (no material delta) -> packet required. >= 15 assistant
    #      entries since the last human message = a genuinely long turn with a real re-entry cost.
    $phd = New-Fixture -Working 'plan' -LastAuth 'plan'
    New-Spec -Proj $phd
    New-HandoverSnapshot -Proj $phd -ChangedUserFiles 0   # read-only: no user files, no commits
    $longTurns = @(@{ role = 'user'; text = 'investigate the flaky test' })
    for ($li = 1; $li -le 16; $li++) { $longTurns += @{ role = 'assistant'; text = "Investigation step $li - reading module $li and correlating the failure signature." } }
    $thd = New-Transcript -Proj $phd -Turns $longTurns
    $rhd = Invoke-Conformance -Proj $phd -TranscriptPath $thd
    if (-not $rhd.Blocked) { Fail "Case PH-d: a LONG read-only investigation (16 assistant entries) without the packet MUST block. Out: $($rhd.Out)" }
    if ($rhd.Out -notmatch 'five-part context packet') { Fail "Case PH-d: the long-turn demand is the five-part packet. Out: $($rhd.Out)" }
    # and the SAME long turn WITH the packet is accepted.
    $longTurnsOk = @($longTurns[0..($longTurns.Count - 2)]) + @(@{ role = 'assistant'; text = $materialPacket })
    $thdOk = New-Transcript -Proj $phd -Turns $longTurnsOk
    $rhdOk = Invoke-Conformance -Proj $phd -TranscriptPath $thdOk
    if ($rhdOk.Blocked) { Fail "Case PH-d: the long-turn packet, once rendered, MUST be accepted. Out: $($rhdOk.Out)" }
    Write-Pass "Case PH-d: a long read-only investigation owes the packet; rendering it satisfies the demand (maintainer fixture d)"

    # ---- Case PH-f: BOUNDARY stop contract UNCHANGED - the six-section directive + the exact verdict marker,
    #      even with a session baseline on disk (the baseline lane never weakens boundary authorization).
    $phf = New-Fixture -Working 'plan' -LastAuth 'clarify'
    New-HandoverSnapshot -Proj $phf -ChangedUserFiles 2
    $null = Invoke-Conformance -Proj $phf -Event SessionStart   # baseline present; must not matter at a boundary
    $thf = New-Transcript -Proj $phf -Turns @(@{ role = 'user'; text = 'continue' }, @{ role = 'assistant'; text = 'plan.md is written; moving on.' })
    $rhf = Invoke-Conformance -Proj $phf -TranscriptPath $thf
    if (-not $rhf.Blocked) { Fail "Case PH-f: a pending-verdict boundary stop MUST still block regardless of the material baseline. Out: $($rhf.Out)" }
    if ($rhf.Out -notmatch 'Discussion Prompts') { Fail "Case PH-f: the boundary demand is the SIX-section packet (Discussion Prompts included). Out: $($rhf.Out)" }
    if ($rhf.Out -notmatch 'SPECREW-VERDICT-BOUNDARY: clarify -> plan') { Fail "Case PH-f: the boundary demand carries the exact contiguous verdict marker. Out: $($rhf.Out)" }
    Write-Pass "Case PH-f: the six-section boundary contract is untouched by the packet-hardening lanes (maintainer fixture f)"

    # ---- Case 5 (reconciled 2026-07-14 to the T099/FR-040 design-N3 contract): an intake question on an IDLE
    #      conversational stop (no boundary pending, no material work) no longer pays the per-line transcript
    #      parse, so the conformance provider emits NOTHING there - the bootstrap orientation surface owns idle
    #      intake drift. This case was RED at HEAD since the T099 gate change; the fixture now asserts the
    #      ratified contract instead of the retired trigger. The intake nudge itself is proven in Case 5b on a
    #      stop that already warranted the parse.
    $p5 = New-Fixture -Working 'plan' -LastAuth 'plan'
    New-Spec -Proj $p5
    $t5 = New-Transcript -Proj $p5 -Turns @(@{ role = 'assistant'; text = "Welcome! What would you like to build today?" })
    $r5 = Invoke-Conformance -Proj $p5 -TranscriptPath $t5
    if ($r5.Blocked) { Fail "Case 5: a short intake question is never a packet block. Out: $($r5.Out)" }
    if ($r5.Out -match 'INTAKE QUESTION') { Fail "Case 5: an idle conversational stop does not pay the parse, so no intake nudge fires there (T099/N3). Out: $($r5.Out)" }
    Write-Pass "Case 5: an idle conversational intake stop emits nothing - idle intake drift belongs to the bootstrap orientation surface (T099/FR-040 N3)"

    # ---- Case 5b: INTAKE QUESTION on a stop that ALREADY warranted the parse (material surface + rendered
    #      packet) -> the #1 redirect NUDGE still fires (the lane survives; only the idle trigger was retired).
    $p5b = New-Fixture -Working 'plan' -LastAuth 'plan'
    New-Spec -Proj $p5b
    New-HandoverSnapshot -Proj $p5b -ChangedUserFiles 2
    $packetWithIntake = $materialPacket + "`n`nBefore I continue: what would you like to build next?"
    $t5b = New-Transcript -Proj $p5b -Turns @(@{ role = 'assistant'; text = $packetWithIntake })
    $r5b = Invoke-Conformance -Proj $p5b -TranscriptPath $t5b
    if ($r5b.Blocked) { Fail "Case 5b: the packet is rendered, so no block. Out: $($r5b.Out)" }
    if ($r5b.Out -notmatch 'INTAKE QUESTION') { Fail "Case 5b: an intake question on a parsed (material) stop MUST fire the #1 redirect nudge. Out: $($r5b.Out)" }
    Write-Pass "Case 5b: the intake redirect nudge still fires on a stop that warranted the parse (SC-008 #1, post-T099 shape)"

    # ---- Case 6: RAW SPEC KIT -> a cooperative NUDGE. Short message running `specify workflow`, no spec.
    $p6 = New-Fixture -Working 'plan' -LastAuth 'plan'
    $t6 = New-Transcript -Proj $p6 -Turns @(@{ role = 'assistant'; text = "I'll run: specify workflow --type feature." })
    $r6 = Invoke-Conformance -Proj $p6 -TranscriptPath $t6
    if ($r6.Out -notmatch 'RAW SPEC KIT') { Fail "Case 6: a raw 'specify workflow' invocation MUST fire the #3 redirect. Out: $($r6.Out)" }
    Write-Pass "Case 6: a raw 'specify workflow' invocation fires the #3 redirect NUDGE (SC-008 #3)"

    # ---- Case 7: LOOP-GUARD. Consecutive packet-less boundary stops block up to the cap, then degrade to a nudge
    #              (never hang); a packet-present stop resets the counter so a later advance re-blocks.
    $p7 = New-Fixture -Working 'plan' -LastAuth 'clarify'
    # DISTINCT message per dispatch - the real loop-guard scenario is the agent re-rendering DIFFERENT no-packet
    # messages (same advance), which the idempotency guard does NOT dedup (different identities). (A truly identical
    # re-fire is Case 22.)
    for ($n = 1; $n -le 3; $n++) {
        $tn = New-Transcript -Proj $p7 -Turns @(@{ role = 'assistant'; text = "plan.md written (attempt $n)." })
        $rb = Invoke-Conformance -Proj $p7 -TranscriptPath $tn
        if (-not $rb.Blocked) { Fail "Case 7: block #$n (within the cap of 3) MUST block. Out: $($rb.Out)" }
    }
    $t7cap = New-Transcript -Proj $p7 -Turns @(@{ role = 'assistant'; text = 'plan.md written (attempt 4).' })
    $r7cap = Invoke-Conformance -Proj $p7 -TranscriptPath $t7cap
    if ($r7cap.Blocked) { Fail "Case 7: the 4th consecutive block exceeds the cap and MUST degrade (release the stop) to avoid a hang. Out: $($r7cap.Out)" }
    if ($r7cap.Out -notmatch 'BOUNDARY VERDICT MARKER still missing') { Fail "Case 7: over the cap, degrade to a plain marker nudge. Out: $($r7cap.Out)" }
    # A packet-present stop resets the counter.
    $t7ok = New-Transcript -Proj $p7 -Turns @(@{ role = 'assistant'; text = $realPacket })
    $null = Invoke-Conformance -Proj $p7 -TranscriptPath $t7ok
    $t7re = New-Transcript -Proj $p7 -Turns @(@{ role = 'assistant'; text = 'plan.md written (post-reset attempt).' })
    $r7reset = Invoke-Conformance -Proj $p7 -TranscriptPath $t7re
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

    # ---- Case 9b: MULTI-GATE-GAP rendered packet. working 'tasks' two gates past authorized 'clarify', but the
    #               rendered packet targets the FIRST unauthorized crossing clarify -> plan -> suppress and let capture bind.
    $p9b = New-Fixture -Working 'tasks' -LastAuth 'clarify'
    $t9b = New-Transcript -Proj $p9b -Turns @(@{ role = 'assistant'; text = $realPacket })
    $r9b = Invoke-Conformance -Proj $p9b -TranscriptPath $t9b
    if ($r9b.Blocked) { Fail "Case 9b: a marker for the first unauthorized crossing clarify -> plan MUST suppress even when working already jumped to tasks. Out: $($r9b.Out)" }
    Write-Pass "Case 9b: multi-gate over-advance suppresses only when the packet names the FIRST unauthorized crossing (clarify -> plan)"

    # ---- Case 9c: MULTI-GATE-GAP wrong marker. The gate-skipping plan -> tasks marker must NOT suppress; it would
    #               let the human authorize a later crossing while clarify -> plan is still missing.
    $packetPlanTasks = $realPacket -replace 'clarify -> plan', 'plan -> tasks'
    $p9c = New-Fixture -Working 'tasks' -LastAuth 'clarify'
    $t9c = New-Transcript -Proj $p9c -Turns @(@{ role = 'assistant'; text = $packetPlanTasks })
    $r9c = Invoke-Conformance -Proj $p9c -TranscriptPath $t9c
    if (-not $r9c.Blocked) { Fail "Case 9c: a gate-skipping plan -> tasks marker MUST NOT suppress while clarify -> plan is first unauthorized. Out: $($r9c.Out)" }
    if ($r9c.Out -notmatch 'SPECREW-VERDICT-BOUNDARY: clarify -> plan') { Fail "Case 9c: block must demand the first unauthorized clarify -> plan marker. Out: $($r9c.Out)" }
    Write-Pass "Case 9c: multi-gate over-advance rejects a later marker and demands the first unauthorized crossing"

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
    Write-Pass "Case 10: a STALE/unrelated packet does NOT suppress a genuine new advance - the guard matches the exact pending crossing (145 TI-2/F1)"

    # ---- Case 11: RELEVANT packet (matches pending crossing) suppresses. working 'tasks', authorized 'plan',
    #                a plan->tasks packet rendered.
    $packetTasks = $realPacket -replace 'clarify -> plan', 'plan -> tasks'
    $p11 = New-Fixture -Working 'tasks' -LastAuth 'plan'
    $t11 = New-Transcript -Proj $p11 -Turns @(@{ role = 'user'; text = 'continue' }, @{ role = 'assistant'; text = $packetTasks })
    $r11 = Invoke-Conformance -Proj $p11 -TranscriptPath $t11
    if ($r11.Blocked) { Fail "Case 11: a packet whose marker matches the pending crossing is a legitimate awaiting stop - MUST suppress. Out: $($r11.Out)" }
    Write-Pass "Case 11: the RELEVANT packet (plan -> tasks == pending crossing) correctly suppresses the block (guard precision)"

    # ---- Case 11b: FIRST boundary marker. With no authorized boundary and working already at clarify, the first
    #                 authorizable crossing is still intake -> specify. That exact marker suppresses.
    $packetFirst = $realPacket -replace 'clarify -> plan', 'intake -> specify'
    $p11b = New-Fixture -Working 'clarify' -LastAuth ''
    $t11b = New-Transcript -Proj $p11b -Turns @(@{ role = 'assistant'; text = $packetFirst })
    $r11b = Invoke-Conformance -Proj $p11b -TranscriptPath $t11b
    if ($r11b.Blocked) { Fail "Case 11b: first-boundary marker intake -> specify MUST suppress even when working already jumped to clarify. Out: $($r11b.Out)" }
    Write-Pass "Case 11b: first-boundary over-advance suppresses on the marker-only intake -> specify crossing"

    # ---- Case 11c: FIRST boundary wrong marker. specify -> clarify is the NEXT crossing, not the first
    #                 authorization from an empty ledger; it must block and demand intake -> specify.
    $packetWrongFirst = $realPacket -replace 'clarify -> plan', 'specify -> clarify'
    $p11c = New-Fixture -Working 'clarify' -LastAuth ''
    $t11c = New-Transcript -Proj $p11c -Turns @(@{ role = 'assistant'; text = $packetWrongFirst })
    $r11c = Invoke-Conformance -Proj $p11c -TranscriptPath $t11c
    if (-not $r11c.Blocked) { Fail "Case 11c: first-boundary wrong marker specify -> clarify MUST block when specify is not authorized yet. Out: $($r11c.Out)" }
    if ($r11c.Out -notmatch 'SPECREW-VERDICT-BOUNDARY: intake -> specify') { Fail "Case 11c: block must demand intake -> specify for the first unauthorized boundary. Out: $($r11c.Out)" }
    Write-Pass "Case 11c: first-boundary wrong marker is rejected; the block demands intake -> specify"

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
    if ($r13.Out -notmatch 'BOUNDARY VERDICT MARKER still missing') { Fail "Case 13: at the cap, degrade to the plain marker nudge. Out: $($r13.Out)" }
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

    # ---- Case 16 / FR-056(a,e): exact feature+iteration+first-remaining-lens state plus the current question marker
    #      produces one workshop-intermediate pause, no generic packet, and a durable bounded re-entry record.
    $p16 = New-Fixture -Working 'plan' -LastAuth 'plan'
    New-Spec -Proj $p16
    New-LensApplicability -Proj $p16 -Selected @('architecture-core','data-storage') -Done @()
    New-HandoverSnapshot -Proj $p16 -ChangedUserFiles 2
    $t16 = New-Transcript -Proj $p16 -Turns @(@{ role = 'assistant'; text = $workshopQuestion })
    $r16a = Invoke-Conformance -Proj $p16 -TranscriptPath $t16
    $r16bDuplicate = Invoke-Conformance -Proj $p16 -TranscriptPath $t16
    if ($r16a.Blocked -or $r16a.Out -match 'five-part context packet') { Fail "Case 16: a proved current-lens question MUST remain the final visible turn. Out: $($r16a.Out)" }
    if ($r16bDuplicate.Blocked -or $r16bDuplicate.Out -match 'five-part context packet') { Fail "Case 16: a duplicate Stop delivery MUST remain a no-op. Out: $($r16bDuplicate.Out)" }
    $workshopHandoverPath = Join-Path $p16 '.specrew\handover\workshop-question.json'
    if (-not (Test-Path -LiteralPath $workshopHandoverPath -PathType Leaf)) { Fail 'Case 16: workshop-intermediate must persist bounded re-entry context' }
    $workshopHandover = Get-Content -LiteralPath $workshopHandoverPath -Raw | ConvertFrom-Json
    if ([string]$workshopHandover.feature_ref -ne '050-host-neutral-gate' -or [string]$workshopHandover.iteration_number -ne '001' -or [string]$workshopHandover.lens -ne 'architecture-core' -or [string]::IsNullOrWhiteSpace([string]$workshopHandover.question)) {
        Fail "Case 16: durable re-entry context must retain exact feature/iteration/lens/question: $($workshopHandover | ConvertTo-Json -Compress)"
    }
    Write-Pass "Case 16: exact current-lens question stops once without a generic packet and retains durable re-entry context"

    # ---- Case 16b / FR-056(d): lifecycle boundary state has precedence even when every workshop-question signal
    #      is otherwise valid. The six-section packet and exact boundary marker remain mandatory.
    $p16b = New-Fixture -Working 'plan' -LastAuth 'clarify'
    New-Spec -Proj $p16b
    New-LensApplicability -Proj $p16b -Selected @('architecture-core','data-storage') -Done @()
    New-HandoverSnapshot -Proj $p16b -ChangedUserFiles 2
    $t16b = New-Transcript -Proj $p16b -Turns @(@{ role = 'assistant'; text = $workshopQuestion })
    $r16b = Invoke-Conformance -Proj $p16b -TranscriptPath $t16b
    if (-not $r16b.Blocked -or $r16b.Out -notmatch 'SPECREW-VERDICT-BOUNDARY: clarify -> plan') { Fail "Case 16b: a lifecycle boundary MUST override workshop state and demand the boundary packet. Out: $($r16b.Out)" }
    Write-Pass "Case 16b: lifecycle boundary state overrides the workshop marker and retains the six-section contract"

    # ---- Case 16c / FR-056(c): durable remaining-lens state plus prose that merely claims a workshop is still
    #      insufficient. Without the exact marker/current-lens proof, a material hand-back owes the packet.
    $p16c = New-Fixture -Working 'plan' -LastAuth 'plan'
    New-Spec -Proj $p16c
    New-LensApplicability -Proj $p16c -Selected @('architecture-core','data-storage') -Done @()
    New-HandoverSnapshot -Proj $p16c -ChangedUserFiles 2
    $fabricatedWorkshop = 'I am in the architecture-core workshop and this is definitely a lens question. The component material is finished and the rest can wait. Which ownership option should we choose?'
    $t16c = New-Transcript -Proj $p16c -Turns @(@{ role = 'assistant'; text = $fabricatedWorkshop })
    $r16c = Invoke-Conformance -Proj $p16c -TranscriptPath $t16c
    if (-not $r16c.Blocked -or $r16c.Out -notmatch 'five-part context packet') { Fail "Case 16c: workshop-claim prose without the exact marker MUST NOT bypass material enforcement. Out: $($r16c.Out)" }
    Write-Pass "Case 16c: fabricated workshop prose cannot bypass the ordinary material-work packet"

    # ---- Case 16d / FR-056 narrow scope: a real old iteration artifact and matching marker are still stale when
    #      active session state names another iteration. The old question cannot suppress the current Stop packet.
    $p16d = New-Fixture -Working 'plan' -LastAuth 'plan'
    New-Spec -Proj $p16d
    New-LensApplicability -Proj $p16d -Selected @('architecture-core','data-storage') -Done @() -Iteration '002'
    New-HandoverSnapshot -Proj $p16d -ChangedUserFiles 2
    $staleIterationQuestion = $workshopQuestion.Replace('iteration=001', 'iteration=002')
    $t16d = New-Transcript -Proj $p16d -Turns @(@{ role = 'assistant'; text = $staleIterationQuestion })
    $r16d = Invoke-Conformance -Proj $p16d -TranscriptPath $t16d
    if (-not $r16d.Blocked -or $r16d.Out -notmatch 'five-part context packet') { Fail "Case 16d: a marker/artifact for a non-active iteration MUST NOT bypass material enforcement. Out: $($r16d.Out)" }
    Write-Pass "Case 16d: stale iteration state and its matching marker cannot suppress the active iteration's packet"

    # ---- Case 17: workshop COMPLETE (all selected lenses done -> remaining = 0) cannot prove an intermediate pause;
    #      a real boundary stop blocks again.
    $p17 = New-Fixture -Working 'plan' -LastAuth 'clarify'
    New-Spec -Proj $p17
    New-LensApplicability -Proj $p17 -Selected @('product-domain','data-storage') -Done @('product-domain','data-storage')
    $t17 = New-Transcript -Proj $p17 -Turns @(@{ role = 'assistant'; text = 'spec.md written; plan.md drafted.' })
    $r17 = Invoke-Conformance -Proj $p17 -TranscriptPath $t17
    if (-not $r17.Blocked) { Fail "Case 17: with the workshop COMPLETE (remaining=0), a real boundary silent-advance MUST block. Out: $($r17.Out)" }
    Write-Pass "Case 17: completed workshop state cannot suppress a lifecycle boundary"

    # ---- Case 18 (#3 negation guard): the contract's OWN prohibition prose ('do NOT run the raw `specify.exe
    #      workflow`') must NOT fire the #3 redirect (no spec, no pending -> only #3 could fire).
    $p18 = New-Fixture -Working 'plan' -LastAuth 'plan'
    $t18 = New-Transcript -Proj $p18 -Turns @(@{ role = 'assistant'; text = 'Per the contract, I will do NOT run the raw `specify.exe workflow` automation - I will use the governed flow.' })
    $r18 = Invoke-Conformance -Proj $p18 -TranscriptPath $t18
    if ($r18.Out -match 'RAW SPEC KIT') { Fail "Case 18: the contract's prohibition prose ('do NOT run the raw `specify.exe workflow`') MUST NOT fire #3 (negation guard). Out: $($r18.Out)" }
    Write-Pass "Case 18: the contract's own 'do NOT run the raw specify.exe workflow' prohibition prose does NOT false-fire #3 (negation guard; dogfood)"

    # ---- Case 19 (ANTIGRAVITY DOGFOOD GAP): at a BOUNDARY, the six section HEADERS alone do NOT authorize the
    #      crossing - the verdict MARKER captures the verdict. A weak host rendered the headers but NO marker, so the
    #      gate stayed un-authorized (last_authorized=none) while the header check wrongly suppressed the block. Now a
    #      headers-without-marker boundary stop MUST block (demand the marker so the verdict gets captured).
    $packetNoMarker = ($realPacket -replace '(?m)^.*SPECREW-VERDICT-BOUNDARY.*$', '')  # 6 headers, NO marker (strip the whole marker line)
    # Guard the fixture's DISCRIMINATING properties (145 TI-1): >=4 headers preserved AND the marker stripped, so a
    # future strip-regex drift that ate the headers cannot silently degrade this into a Case-1 (0-header) duplicate.
    $hdrs19 = @('What I Just Did', 'Why I Stopped', 'What Needs Your Review', 'What Happens Next', 'Discussion Prompts', 'What I Need From You')
    $h19 = (@($hdrs19) | Where-Object { $packetNoMarker -match [regex]::Escape($_) }).Count
    if ($h19 -lt 4) { Fail "Case 19 fixture INVALID: expected >=4 section headers preserved, got $h19 (the strip-regex ate the headers - this case would silently become a Case-1 dup)" }
    if ($packetNoMarker -match 'SPECREW-VERDICT-BOUNDARY') { Fail "Case 19 fixture INVALID: the verdict marker was NOT stripped (the case would not test the headers-without-marker path)" }
    $p19 = New-Fixture -Working 'plan' -LastAuth 'clarify'
    $t19 = New-Transcript -Proj $p19 -Turns @(@{ role = 'user'; text = 'continue' }, @{ role = 'assistant'; text = $packetNoMarker })
    $r19 = Invoke-Conformance -Proj $p19 -TranscriptPath $t19
    if (-not $r19.Blocked) { Fail "Case 19: a boundary stop with the six section HEADERS but NO verdict marker MUST block (headers don't authorize the crossing; the verdict was never captured). Out: $($r19.Out)" }
    if ($r19.Out -notmatch 'SPECREW-VERDICT-BOUNDARY: clarify -> plan') { Fail "Case 19: the block must demand the contiguous verdict marker. Out: $($r19.Out)" }
    Write-Pass "Case 19: a boundary packet with HEADERS but NO marker still BLOCKS - the marker (not the headers) authorizes the boundary (Antigravity dogfood gap); fixture properties asserted (145 TI-1)"

    # ---- Case 20 (145 OB-1): workshop validation must scope to the ACTIVE feature. A DIFFERENT abandoned feature
    #      whose lens workshop still has lenses remaining MUST NOT affect the ACTIVE feature's boundary block.
    $p20 = New-Fixture -Working 'plan' -LastAuth 'clarify'  # ACTIVE feature 050 at a real boundary; NO lens-applicability of its own
    $abDir = Join-Path $p20 'specs\049-abandoned'
    New-Item -ItemType Directory -Path $abDir -Force | Out-Null
    Set-Content -LiteralPath (Join-Path $abDir 'spec.md') -Value '# abandoned feature' -Encoding UTF8
    Set-Content -LiteralPath (Join-Path $abDir 'lens-applicability.json') -Value (([ordered]@{ workshop_intake = $true; confirmation_required = $true; selected = @('product-domain', 'architecture-core', 'data-storage'); workshop = [ordered]@{} }) | ConvertTo-Json -Depth 6) -Encoding UTF8
    $t20 = New-Transcript -Proj $p20 -Turns @(@{ role = 'assistant'; text = 'plan.md written; proceeding.' })
    $r20 = Invoke-Conformance -Proj $p20 -TranscriptPath $t20
    if (-not $r20.Blocked) { Fail "Case 20: a DIFFERENT abandoned feature's in-progress workshop MUST NOT affect the ACTIVE feature's boundary block (145 OB-1 cross-feature scope leak). Out: $($r20.Out)" }
    Write-Pass "Case 20: an abandoned feature's unfinished workshop does not affect the active feature's enforcement"

    # ---- Case 21 (145 TI-2): a #3 raw-Spec-Kit hit concurrent with a FIRING boundary block folds the redirect INTO
    #      the block directive (the standalone-nudge path is covered by Case 6; the fold-into-block path was not).
    $p21 = New-Fixture -Working 'plan' -LastAuth 'clarify'
    $t21 = New-Transcript -Proj $p21 -Turns @(@{ role = 'assistant'; text = 'I will now invoke specify workflow --type feature to scaffold the next phase.' })
    $r21 = Invoke-Conformance -Proj $p21 -TranscriptPath $t21
    if (-not $r21.Blocked) { Fail "Case 21: the boundary block should fire. Out: $($r21.Out)" }
    if ($r21.Out -notmatch 'do NOT run the raw') { Fail "Case 21: a #3 hit concurrent with a firing block MUST fold the redirect into the block directive. Out: $($r21.Out)" }
    Write-Pass "Case 21: a #3 raw-Spec-Kit hit concurrent with a firing boundary block FOLDS the redirect into the block directive (fold coverage; 145 TI-2)"

    # ---- Case 22 (IDEMPOTENCY): a DUPLICATE hook fire for the SAME message (identical transcript + boundary state)
    #      within the dedup window is a no-op - the stop blocks ONCE; the re-fire does not re-block (maintainer 2026-06-21).
    $p22 = New-Fixture -Working 'plan' -LastAuth 'clarify'
    $t22 = New-Transcript -Proj $p22 -Turns @(@{ role = 'assistant'; text = 'plan.md written.' })
    $r22a = Invoke-Conformance -Proj $p22 -TranscriptPath $t22
    $r22b = Invoke-Conformance -Proj $p22 -TranscriptPath $t22  # identical re-fire (same transcript content + state)
    if (-not $r22a.Blocked) { Fail "Case 22: the first fire of a boundary stop MUST block. Out: $($r22a.Out)" }
    if ($r22b.Blocked) { Fail "Case 22: a DUPLICATE fire for the same message MUST be idempotent (no second block). Out: $($r22b.Out)" }
    Write-Pass "Case 22: a duplicate hook fire for the same message is idempotent - blocks once, the re-fire is a no-op (maintainer 2026-06-21)"

    # ---- Case 23 (145 SC-2 / IDEMP-2): the idempotency dedup FILE failing must FAIL-OPEN - a corrupt or unwritable
    #      conformance-last-fire.json still lets a genuine boundary stop BLOCK (dedup disabled, never skip-or-hang).
    $p23 = New-Fixture -Working 'plan' -LastAuth 'clarify'
    New-Item -ItemType Directory -Path (Join-Path $p23 '.specrew\runtime') -Force | Out-Null
    Set-Content -LiteralPath (Join-Path $p23 '.specrew\runtime\conformance-last-fire.json') -Value '{ not valid json ::' -Encoding UTF8  # corrupt read
    $t23 = New-Transcript -Proj $p23 -Turns @(@{ role = 'assistant'; text = 'plan.md written.' })
    $r23 = Invoke-Conformance -Proj $p23 -TranscriptPath $t23
    if (-not $r23.Blocked) { Fail "Case 23: a CORRUPT conformance-last-fire.json must fail-open (the boundary stop still blocks). Out: $($r23.Out)" }
    $p23b = New-Fixture -Working 'plan' -LastAuth 'clarify'
    New-Item -ItemType Directory -Path (Join-Path $p23b '.specrew\runtime\conformance-last-fire.json') -Force | Out-Null  # a DIRECTORY at the file path -> unwritable
    $t23b = New-Transcript -Proj $p23b -Turns @(@{ role = 'assistant'; text = 'plan.md written.' })
    $r23b = Invoke-Conformance -Proj $p23b -TranscriptPath $t23b
    if (-not $r23b.Blocked) { Fail "Case 23: an UNWRITABLE conformance-last-fire.json (directory at the path) must fail-open (still blocks). Out: $($r23b.Out)" }
    Write-Pass "Case 23: a corrupt / unwritable idempotency dedup file fails OPEN - the boundary stop still blocks (dedup disabled, never skip-or-hang; 145 SC-2)"

    # ---- Case 24 (145 IDEMP-1 regression): two genuinely-DIFFERENT boundary messages whose trailing 40+ transcript
    #      entries are IDENTICAL (the distinguishing assistant text is >40 entries back) MUST get different identities
    #      and both block - the identity uses the ROLE-AWARE last-assistant message, not a coarse tail-40 that collides.
    $trail24 = @(1..45 | ForEach-Object { @{ role = 'user'; text = 'identical trailing tool/user entry' } })
    $p24 = New-Fixture -Working 'plan' -LastAuth 'clarify'
    $t24a = New-Transcript -Proj $p24 -Turns (@(@{ role = 'assistant'; text = 'MESSAGE A: plan.md written, no packet.' }) + $trail24)
    $t24b = New-Transcript -Proj $p24 -Turns (@(@{ role = 'assistant'; text = 'MESSAGE B: a different summary, still no packet.' }) + $trail24)
    $r24a = Invoke-Conformance -Proj $p24 -TranscriptPath $t24a
    $r24b = Invoke-Conformance -Proj $p24 -TranscriptPath $t24b
    if (-not $r24a.Blocked) { Fail "Case 24: stop A (boundary, no marker) MUST block. Out: $($r24a.Out)" }
    if (-not $r24b.Blocked) { Fail "Case 24: stop B (a DIFFERENT boundary message with identical trailing 40+ entries) MUST also block - it must NOT be falsely deduped against A (145 IDEMP-1). Out: $($r24b.Out)" }
    Write-Pass "Case 24: two distinct boundary messages with identical trailing 40+ entries get DIFFERENT identities and BOTH block - no false dedup via tail-40 collision (145 IDEMP-1)"

    Write-Host "`n=== conformance-detection.tests.ps1: all assertions passed ===" -ForegroundColor Green
    exit 0
}
finally {
    Remove-Item -LiteralPath $scratch -Recurse -Force -ErrorAction SilentlyContinue
    if ($null -eq $priorModulePath) { Remove-Item Env:\SPECREW_MODULE_PATH -ErrorAction SilentlyContinue } else { $env:SPECREW_MODULE_PATH = $priorModulePath }
}
