$ErrorActionPreference = 'Stop'

# F-174 iteration 011 (T002 + T003, FR-022 / DF-3 / SC-015): END-TO-END proof of MECHANICAL boundary-packet
# CAPTURE + the CLOBBER GUARD. Invokes the real handover Stop-hook provider with a transcript carrying the agent's
# ACTUALLY-RENDERED six-section verdict packet (marker-bearing) and asserts the VERBATIM packet round-trips into the
# handover body so a resume inherits the AUTHORED packet, not placeholders - then that a later generic Stop, a
# no-marker Stop, and a duplicate Stop never CLOBBER it, while a forward boundary change REPLACES the stale one and
# a packet from a boundary we have moved past is dropped (never regressing active_boundary).
#
# The packet here is a REALISTIC six-'## ' packet on purpose (case 1): a single-line packet would hide the
# handover-file round-trip hazard where the packet's own '## ' headers collide with the flat section parser.

function Assert-True { param([bool]$Condition, [string]$Message) if (-not $Condition) { throw "FAIL: $Message" } ; Write-Host "PASS: $Message" -ForegroundColor Green }

$provider = (Resolve-Path "$PSScriptRoot/../../scripts/internal/specrew-handover-provider.ps1").Path
# The handover reader (ConvertFrom-SpecrewHandoverFile + the section helpers) - the SAME parser a resume uses.
. (Resolve-Path "$PSScriptRoot/../../scripts/internal/bootstrap/HandoverStore.ps1").Path
$capturedTitle = @(Get-SpecrewHandoverCapturedSections)[0]

function New-CaptureProject {
    param([string]$Boundary = 'before-implement')
    $tmp = Join-Path ([System.IO.Path]::GetTempPath()) ("specrew-pcap-" + [guid]::NewGuid().ToString('N'))
    $proj = Join-Path $tmp 'proj'
    New-Item -ItemType Directory -Path (Join-Path $proj 'specs/001-feat') -Force | Out-Null
    New-Item -ItemType Directory -Path (Join-Path $proj '.specrew') -Force | Out-Null
    Set-Content -LiteralPath (Join-Path $proj '.gitignore') -Value ".specrew/`n" -Encoding UTF8
    git -C $proj init -q -b main 2>$null; git -C $proj config user.email 't@t' 2>$null; git -C $proj config user.name 't' 2>$null
    git -C $proj add -A 2>$null; git -C $proj commit -q -m init 2>$null
    git -C $proj checkout -q -b '001-feat' 2>$null
    $ctx = [ordered]@{
        schema               = 'v2'
        session_state        = [ordered]@{ active = $true; boundary_type = $Boundary; feature_ref = '001-feat'; host = 'claude'; iteration_number = '001'; recorded_at = '2026-01-01T00:00:00Z' }
        boundary_enforcement = [ordered]@{ enabled = $true; last_authorized_boundary = 'tasks'; pending_next_boundary = $null; verdict_history = @(); bypass_history = @() }
    }
    [System.IO.File]::WriteAllText((Join-Path $proj '.specrew/start-context.json'), ($ctx | ConvertTo-Json -Depth 12), [System.Text.UTF8Encoding]::new($false))
    return [pscustomobject]@{ Tmp = $tmp; Proj = $proj; Transcript = (Join-Path $tmp 'transcript.jsonl') }
}
function Set-Boundary { param([string]$Proj, [string]$Boundary)
    $p = Join-Path $Proj '.specrew/start-context.json'
    $c = Get-Content -LiteralPath $p -Raw | ConvertFrom-Json -Depth 12
    $c.session_state.boundary_type = $Boundary
    [System.IO.File]::WriteAllText($p, ($c | ConvertTo-Json -Depth 12), [System.Text.UTF8Encoding]::new($false))
}
function Set-Transcript { param([string]$Path, [object[]]$Turns)
    $lines = foreach ($t in $Turns) { (@{ type = $t.role; message = @{ role = $t.role; content = @(@{ type = 'text'; text = $t.text }) } } | ConvertTo-Json -Depth 8 -Compress) }
    [System.IO.File]::WriteAllText($Path, ($lines -join "`n"), [System.Text.UTF8Encoding]::new($false))
}
function Invoke-StopHook { param([string]$Proj, [string]$Tx) & pwsh -NoProfile -File $provider --event-json '{"hook_event_name":"Stop"}' --project-root $Proj --host-kind claude --transcript-path $Tx 2>$null | Out-Null }
function Read-Handover { param([string]$Proj) return (ConvertFrom-SpecrewHandoverFile -Path (Join-Path $Proj '.specrew/handover/session-handover.md')) }
function Read-Frontmatter { param([string]$Proj) return (Get-Content -LiteralPath (Join-Path $Proj '.specrew/handover/session-handover.md') -Raw -Encoding UTF8) }

# A REALISTIC marker-bearing six-section verdict packet (the gate-stop render). Well over the substance floor.
function SixSectionPacket {
    param([string]$From, [string]$To)
    return @"
<!-- SPECREW-VERDICT-BOUNDARY: $From -> $To -->

## What I Just Did
Completed the $From boundary work and recorded it in file:///C:/proj/specs/001-feat/tasks-progress.yml.

## Why I Stopped
This is a human-verdict boundary; advancing from $From to $To needs your explicit approval.

## What Needs Your Review
The task breakdown and the estimates traced to the spec acceptance criteria.

## What Happens Next
On approval the lifecycle advances to $To and implementation begins.

## Discussion Prompts
1. Are the estimates right-sized? 2. Any missing tasks?

## What I Need From You
What's your verdict?
  1. Approve as-is
  2. Approve with instructions
  3. Send back
  4. Discuss prompt #N
"@
}
$genericTurn = @{ role = 'assistant'; text = ('Here is a brief status update with no boundary packet and no marker. ' * 8) }

$cases = @()
try {
    # === Case 1 (test 1) — a rendered marker-bearing SIX-SECTION packet is captured VERBATIM into the body. ===
    $c1 = New-CaptureProject -Boundary 'before-implement'; $cases += $c1.Tmp
    Set-Transcript -Path $c1.Transcript -Turns @(@{ role = 'assistant'; text = (SixSectionPacket 'tasks' 'before-implement') })
    Invoke-StopHook -Proj $c1.Proj -Tx $c1.Transcript
    $h1 = Read-Handover -Proj $c1.Proj
    $body1 = [string]$h1.sections[$capturedTitle]
    Assert-True (Test-SpecrewHandoverSectionAuthored -Content $body1) "1: captured section is AUTHORED (not a placeholder) after a marker-bearing packet"
    foreach ($hdr in @('## What I Just Did', '## Why I Stopped', '## What Needs Your Review', '## What Happens Next', '## Discussion Prompts', '## What I Need From You')) {
        Assert-True ($body1 -like "*$hdr*") "1: the six-section structure survives the handover-file round-trip - '$hdr' present (the inner '## ' did NOT shred the section)"
    }
    Assert-True ($body1 -like '*SPECREW-VERDICT-BOUNDARY: tasks -> before-implement*') "1: the boundary marker is preserved verbatim in the captured body"
    Assert-True ($body1 -like "*What's your verdict?*") "1: the verdict prompt body is captured (not synthesized away)"

    # === Case 2 (test 2) — a RESUME inherits the authored packet, not placeholders (active_boundary set from marker). ===
    Assert-True ([string]$h1.active_boundary -eq 'before-implement') "2: active_boundary set from the captured boundary (before-implement)"
    Assert-True ($body1 -notlike '(placeholder*') "2: the resume body is the authored packet, NOT the placeholder marker"

    # === Case 3 (test 3) — NO marker -> NO capture (degrade honestly to the placeholder). ===
    $c3 = New-CaptureProject -Boundary 'before-implement'; $cases += $c3.Tmp
    $noMarker = (SixSectionPacket 'tasks' 'before-implement') -replace '<!-- SPECREW-VERDICT-BOUNDARY:.*?-->', '(no marker here)'
    Set-Transcript -Path $c3.Transcript -Turns @(@{ role = 'assistant'; text = $noMarker })
    Invoke-StopHook -Proj $c3.Proj -Tx $c3.Transcript
    $body3 = [string](Read-Handover -Proj $c3.Proj).sections[$capturedTitle]
    Assert-True (-not (Test-SpecrewHandoverSectionAuthored -Content $body3)) "3: a six-section message with NO marker is NOT captured (the section stays a placeholder)"

    # === Case 4 (test 4) — a STALE packet (TO behind the current boundary) does NOT regress active_boundary nor get written. ===
    $c4 = New-CaptureProject -Boundary 'review-signoff'; $cases += $c4.Tmp
    Set-Transcript -Path $c4.Transcript -Turns @(@{ role = 'assistant'; text = (SixSectionPacket 'tasks' 'before-implement') })
    Invoke-StopHook -Proj $c4.Proj -Tx $c4.Transcript
    $h4 = Read-Handover -Proj $c4.Proj
    Assert-True ([string]$h4.active_boundary -eq 'review-signoff') "4: a stale 'tasks->before-implement' packet does NOT regress the already-forward active_boundary (stays review-signoff)"
    Assert-True (-not (Test-SpecrewHandoverSectionAuthored -Content ([string]$h4.sections[$capturedTitle]))) "4: the stale packet (TO behind the working boundary) is NOT written into the captured section"

    # === Case 5 (test 5) — a later Stop with NO packet PRESERVES the richer captured body (same boundary). ===
    $c5 = New-CaptureProject -Boundary 'before-implement'; $cases += $c5.Tmp
    Set-Transcript -Path $c5.Transcript -Turns @(@{ role = 'assistant'; text = (SixSectionPacket 'tasks' 'before-implement') })
    Invoke-StopHook -Proj $c5.Proj -Tx $c5.Transcript
    $before5 = [string](Read-Handover -Proj $c5.Proj).sections[$capturedTitle]
    Set-Transcript -Path $c5.Transcript -Turns @($genericTurn, @{ role = 'user'; text = 'thanks, keep going' })   # no packet
    Invoke-StopHook -Proj $c5.Proj -Tx $c5.Transcript
    $after5 = [string](Read-Handover -Proj $c5.Proj).sections[$capturedTitle]
    Assert-True (Test-SpecrewHandoverSectionAuthored -Content $after5) "5: a later Stop with NO packet PRESERVES the captured packet (not placeholdered)"
    Assert-True ($after5 -eq $before5) "5: the preserved captured body is UNCHANGED (clobber guard, SC-015)"

    # === Case 6 (test 6) — a generic/placeholder Stop does not clobber the authored packet (distinct from 5: a real assistant turn, no marker). ===
    $c6 = New-CaptureProject -Boundary 'before-implement'; $cases += $c6.Tmp
    Set-Transcript -Path $c6.Transcript -Turns @(@{ role = 'assistant'; text = (SixSectionPacket 'tasks' 'before-implement') })
    Invoke-StopHook -Proj $c6.Proj -Tx $c6.Transcript
    Add-Content -LiteralPath (Join-Path $c6.Proj 'specs/001-feat/notes.md') -Value 'edit' -Encoding UTF8   # a real delta on the SAME boundary
    Set-Transcript -Path $c6.Transcript -Turns @($genericTurn)
    Invoke-StopHook -Proj $c6.Proj -Tx $c6.Transcript
    Assert-True (Test-SpecrewHandoverSectionAuthored -Content ([string](Read-Handover -Proj $c6.Proj).sections[$capturedTitle])) "6: a generic Stop WITH a real git delta (no new packet) still preserves the authored packet"

    # === Case 8 (advisor test 8) — consecutive identical packets are IDEMPOTENT (no drift, one section). ===
    $c8 = New-CaptureProject -Boundary 'before-implement'; $cases += $c8.Tmp
    Set-Transcript -Path $c8.Transcript -Turns @(@{ role = 'assistant'; text = (SixSectionPacket 'tasks' 'before-implement') })
    Invoke-StopHook -Proj $c8.Proj -Tx $c8.Transcript
    $first8 = [string](Read-Handover -Proj $c8.Proj).sections[$capturedTitle]
    Invoke-StopHook -Proj $c8.Proj -Tx $c8.Transcript   # fire again, same packet
    $second8 = [string](Read-Handover -Proj $c8.Proj).sections[$capturedTitle]
    Assert-True ($second8 -eq $first8) "8 IDEMPOTENT: re-firing the same packet leaves the captured body identical"
    $hdrCount = ([regex]::Matches((Read-Frontmatter -Proj $c8.Proj), [regex]::Escape("## $capturedTitle"))).Count
    Assert-True ($hdrCount -eq 1) "8 IDEMPOTENT: exactly ONE captured-section header in the file (no duplication) (got $hdrCount)"

    # === Case 9 (advisor test 9) — a FORWARD boundary change REPLACES the stale packet with the new one. ===
    $c9 = New-CaptureProject -Boundary 'before-implement'; $cases += $c9.Tmp
    Set-Transcript -Path $c9.Transcript -Turns @(@{ role = 'assistant'; text = (SixSectionPacket 'tasks' 'before-implement') })
    Invoke-StopHook -Proj $c9.Proj -Tx $c9.Transcript
    Set-Boundary -Proj $c9.Proj -Boundary 'review-signoff'   # the working position advanced
    Set-Transcript -Path $c9.Transcript -Turns @(@{ role = 'assistant'; text = (SixSectionPacket 'before-implement' 'review-signoff') })
    Invoke-StopHook -Proj $c9.Proj -Tx $c9.Transcript
    $h9 = Read-Handover -Proj $c9.Proj
    $body9 = [string]$h9.sections[$capturedTitle]
    Assert-True ([string]$h9.active_boundary -eq 'review-signoff') "9: a forward boundary change advances active_boundary to review-signoff"
    Assert-True ($body9 -like '*SPECREW-VERDICT-BOUNDARY: before-implement -> review-signoff*') "9: the NEW packet replaces the stale one (new marker present)"
    Assert-True ($body9 -notlike '*SPECREW-VERDICT-BOUNDARY: tasks -> before-implement*') "9: the STALE packet (tasks->before-implement) is GONE after the forward boundary change"

    # === Case 10 (review-signoff P2-1) — a packet whose inner '## ' header EXACTLY matches a verbose canonical
    #     handover title must NOT shred the captured section (the colliding case the safe gate-stop headers hide). ===
    $activityTitle = (@(Get-SpecrewHandoverSectionOrder))[0]   # 'What I just did (last 3-5 turns or last boundary work)'
    $c10 = New-CaptureProject -Boundary 'before-implement'; $cases += $c10.Tmp
    $collidingPacket = @"
<!-- SPECREW-VERDICT-BOUNDARY: tasks -> before-implement -->

## $activityTitle
COLLIDING-BODY-MARKER: this rich body must survive VERBATIM inside the captured section, not leak out.

## Why I Stopped
Advancing from tasks to before-implement needs your explicit approval.

## What I Need From You
What's your verdict? 1. Approve as-is 2. Approve with instructions 3. Send back
"@
    Set-Transcript -Path $c10.Transcript -Turns @(@{ role = 'assistant'; text = $collidingPacket })
    Invoke-StopHook -Proj $c10.Proj -Tx $c10.Transcript
    $h10 = Read-Handover -Proj $c10.Proj
    $cap10 = [string]$h10.sections[$capturedTitle]
    Assert-True (Test-SpecrewHandoverSectionAuthored -Content $cap10) "10: a colliding-header packet is still captured AUTHORED (not shredded to the bare marker)"
    Assert-True ($cap10 -like '*COLLIDING-BODY-MARKER*') "10: the captured section keeps the rich body VERBATIM even when an inner header matches a canonical title (P2-1 fix)"
    Assert-True ($cap10 -like "*## $activityTitle*") "10: the colliding inner header is preserved inside the captured body (not treated as a section break)"
    $canon10 = [string]$h10.sections[$activityTitle]
    Assert-True ($canon10 -notlike '*COLLIDING-BODY-MARKER*') "10: the canonical '$activityTitle' section is NOT polluted by the packet body (no leak)"

    Write-Host "`n=== HookPacketCapture.Tests.ps1: all assertions passed (verbatim packet capture + clobber guard + stale/forward handling + colliding-header P2-1) ===" -ForegroundColor Green
}
finally {
    foreach ($t in $cases) { Remove-Item -LiteralPath $t -Recurse -Force -ErrorAction SilentlyContinue }
}
