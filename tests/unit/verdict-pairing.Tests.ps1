# Feature 203 T005 (FR-019, FR-020; B4F-112): A VERDICT PAIRS WITH THE WAITING CROSSING, NOT WITH A MARKER FOUND BY WALKING.
#
# B4F-112 (2026-10-13, feature 202): the tasks packet was rendered, Claude compacted the context, and the maintainer's
# `approved for tasks` did not reach the ledger; the capture returned the earlier clarify -> plan pair instead. The
# compaction summary no longer counts as a human turn (202 T017), but the reader still found its crossing by walking the
# transcript for packet markers: a packet that had scrolled out of the tail it reads left the verdict unpaired, and an
# answer that was not an approval sent the walk back to an older packet.
#
# The maintainer's design decision (verdict-pairing-out-of-tail, option 4; spec clarification DRIFT-043): with the waiting
# crossing's marker in the tail, the marker still pairs. Without it, a reply pairs with the durable crossing only at that
# message's own prompt event, only if it names the target boundary, the packet was verified as shown in this session (a
# compaction keeps that; new, resume and clear do not) and what the packet linked is unchanged. The turn end never pairs
# without the marker, and reports what it did not record. No marker but the waiting crossing's is ever used.
#
# Mutations that turn this file red: restore the walk to an older marker (case 2); drop the out-of-tail path (case 1); let
# the disabled markerless fallback run again, DEC-198-GOV-003's shape (case 3b; `verdict-capture-blocks` C10-C17 pin it too); accept the "from" boundary (case 4b); drop the mismatch report (case
# 4); drop the prompt-time line for a bare approval (case 5); drop the turn end's report (case 6); drop the shown check
# (cases 7, 8, 9); read the compact SessionStart as clearing the shown record (case 1) or any other as keeping it (case 11);
# read a raw boundary name instead of its canonical one (case 10); drop the artifact comparison (case 12).
Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'
$repoRoot = (Resolve-Path (Join-Path $PSScriptRoot '..\..')).Path
. (Join-Path $repoRoot 'extensions\specrew-speckit\scripts\shared-governance.ps1')
Get-ChildItem (Join-Path $repoRoot 'scripts\internal\bootstrap\*.ps1') | ForEach-Object { . $_.FullName }
$provider = (Join-Path $repoRoot 'scripts\internal\specrew-handover-provider.ps1')
$conformance = (Join-Path $repoRoot 'extensions\specrew-speckit\scripts\specrew-conformance-provider.ps1')
$declare = (Join-Path $repoRoot 'extensions\specrew-speckit\scripts\declare-turn-end.ps1')
. (Join-Path $repoRoot 'extensions\specrew-speckit\scripts\turn-end-store.ps1')
$savedModulePath = $env:SPECREW_MODULE_PATH
$env:SPECREW_MODULE_PATH = $repoRoot
$compaction = @(Get-Content -LiteralPath (Join-Path $repoRoot 'tests\fixtures\hook-payloads\claude\compaction\tui-compaction-transcript-excerpt.jsonl') -Encoding UTF8)
$script:failCount = 0
$script:roots = @()
function Write-Pass { param([string]$Message) Write-Host "PASS: $Message" -ForegroundColor Green }
function Write-Fail { param([string]$Message) Write-Host "FAIL: $Message" -ForegroundColor Red; $script:failCount++ }
function Assert-True { param([bool]$Condition, [string]$Message) if ($Condition) { Write-Pass $Message } else { Write-Fail $Message } }

function New-PairingFixture {
    # A project whose crossing $From -> $To was opened by the boundary sync at $RecordedAt (a scoped pending_crossing).
    param([string]$From, [string]$To, [string]$RecordedAt = '2026-08-29T00:00:01Z')
    $root = [IO.Path]::GetFullPath((Join-Path ([IO.Path]::GetTempPath()) ("pairing-{0}" -f [guid]::NewGuid().ToString('N').Substring(0, 10))))
    $script:roots += $root
    $feature = Join-Path $root 'specs\001-feat'
    $iter = Join-Path $feature 'iterations\001'
    New-Item -ItemType Directory -Force -Path (Join-Path $root '.specrew\runtime') | Out-Null
    New-Item -ItemType Directory -Force -Path (Join-Path $iter 'quality') | Out-Null
    Set-Content -LiteralPath (Join-Path $feature 'spec.md') -Value "# Feature Specification: Feat`n`nBody.`n`n## Clarifications`n`n### Session 2026-08-29`n`n- Q: none. A: none." -Encoding UTF8
    Set-Content -LiteralPath (Join-Path $iter 'plan.md') -Value "# Iteration Plan: 001`n`n**Status**: planning" -Encoding UTF8
    Set-Content -LiteralPath (Join-Path $iter 'state.md') -Value "# Iteration State: 001`n`n**Current Phase**: tasks" -Encoding UTF8
    Set-Content -LiteralPath (Join-Path $iter 'tasks.md') -Value "# Tasks`n`n- [ ] T001 a task" -Encoding UTF8
    Set-Content -LiteralPath (Join-Path $iter 'quality\hardening-gate.md') -Value "# Hardening Gate`n`n**Overall Verdict**: ready" -Encoding UTF8
    Set-Content -LiteralPath (Join-Path $iter 'review.md') -Value "# Review`n`n**Verdict**: pass" -Encoding UTF8
    Set-Content -LiteralPath (Join-Path $root '.gitignore') -Value ".specrew/`n" -Encoding UTF8
    & git -C $root init -q -b main
    & git -C $root config user.email 't@t'
    & git -C $root config user.name 't'
    & git -C $root config core.autocrlf false
    & git -C $root add -A
    & git -C $root commit -q -m fixture
    $head = ([string](& git -C $root rev-parse HEAD)).Trim()
    $ctx = [ordered]@{
        schema = 'v2'
        feature_path = $feature
        session_state = [ordered]@{ active = $true; boundary_type = $To; feature_ref = '001-feat'; host = 'claude'; iteration_number = '001'; auth_commit_hash = $head; recorded_at = '2026-08-29T00:00:00Z' }
        boundary_enforcement = [ordered]@{ enabled = $true; last_authorized_boundary = $From; pending_next_boundary = $null; verdict_history = @(); bypass_history = @() }
    }
    [IO.File]::WriteAllText((Join-Path $root '.specrew\start-context.json'), ($ctx | ConvertTo-Json -Depth 12), [Text.UTF8Encoding]::new($false))
    $null = Set-SpecrewPendingBoundaryCrossingScope -ProjectRoot $root -WorkingBoundary $To -BoundaryCommitHash $head -RecordedAt $RecordedAt
    return $root
}
function Read-Enforcement { param([string]$Root) return (Get-Content -LiteralPath (Join-Path $Root '.specrew\start-context.json') -Raw -Encoding UTF8 | ConvertFrom-Json -Depth 12).boundary_enforcement }
function Get-VerdictCount { param([string]$Root) return @((Read-Enforcement -Root $Root).verdict_history).Count }
function New-Line {
    # One transcript entry as Claude writes it: a human entry carries its prompt id, origin and timestamp.
    param([string]$Role, [string]$Text, [string]$At)
    $entry = [ordered]@{ type = $Role; timestamp = $At; message = @{ role = $Role; content = @(@{ type = 'text'; text = $Text }) } }
    if ($Role -eq 'user') { $entry['promptId'] = 'prompt-' + [guid]::NewGuid().ToString('N').Substring(0, 12); $entry['origin'] = @{ kind = 'human' } }
    return ($entry | ConvertTo-Json -Depth 8 -Compress)
}
function New-Packet { param([string]$From, [string]$To, [string]$At) return (New-Line -Role assistant -At $At -Text "boundary packet. <!-- SPECREW-VERDICT-BOUNDARY: $From -> $To --> What's your verdict?") }
function New-ToolChatter {
    # The long run of tool calls a compaction follows: more lines than the reader's tail holds.
    param([int]$Count = 520)
    return @(1..$Count | ForEach-Object { New-Line -Role assistant -At '2026-08-29T00:05:00Z' -Text ("tool call {0}" -f $_) })
}
function Write-Transcript { param([string]$Root, [string[]]$Lines)
    $tx = Join-Path $Root 'transcript.jsonl'
    [IO.File]::WriteAllText($tx, ($Lines -join "`n"), [Text.UTF8Encoding]::new($false))
    return $tx
}
function New-RolloutLine {
    # One entry as a Codex rollout holds it (tests/bootstrap/fixtures/conversation/codex.jsonl).
    param([string]$Role, [string]$Text)
    $part = if ($Role -eq 'user') { 'input_text' } else { 'output_text' }
    return ([ordered]@{ timestamp = '2026-08-29T00:05:00Z'; type = 'response_item'; payload = @{ type = 'message'; role = $Role; content = @(@{ type = $part; text = $Text }) } } | ConvertTo-Json -Depth 8 -Compress)
}
function New-PacketText { param([string]$From, [string]$To, [string]$Linked)
    $link = ([Uri]::new($Linked)).AbsoluteUri
    return "## What I Just Did`n`nThe stage's work.`n`n## Why I Stopped`n`nThe $To boundary needs your verdict. My recommendation: approve.`n`n## What Needs Your Review`n`nThe specification: $link`n`n## What Happens Next`n`nThe next stage starts on approval.`n`n## Discussion Prompts`n`n1. Is the order right?`n`n## What I Need From You`n`nWhat would you like to do? Type one of these:`n`n  approved for $To`n  approved for $To - <your instructions>`n  changes needed: <what to change>`n  discuss prompt 1`n`n<!-- SPECREW-VERDICT-BOUNDARY: $From -> $To -->"
}
function Show-Packet {
    # The packet reaches the reply and the real Stop verifies it: the conformance provider and declare-turn-end, as a session
    # runs them. Returns the transcript so far.
    param([string]$Root, [string]$Session, [string]$From, [string]$To, [string]$HostKind = 'claude', [switch]$Rollout)
    [IO.File]::WriteAllText((Join-Path $Root '.specrew\runtime\pending-verdict-stop.md'), (@('# Specrew Pending Verdict Stop', '', "Boundary to ask for: $From -> $To", "Human approval phrase: approved for $To", 'Marker last line exactly:', "<!-- SPECREW-VERDICT-BOUNDARY: $From -> $To -->") -join "`n"), [Text.UTF8Encoding]::new($false))
    Push-Location -LiteralPath $Root
    try {
        $out = (& pwsh -NoProfile -File $conformance --host-kind $HostKind --source-event UserPromptSubmit --session-id $Session --last-user-message 'Continue.' --turn-origin typed-user --message-identity declared --message-id ('prompt-' + [guid]::NewGuid().ToString('N').Substring(0, 12)) 2>&1) -join "`n"
        $token = [regex]::Match($out, '-Token\s+([0-9a-f]{16,})').Groups[1].Value
        $text = New-PacketText -From $From -To $To -Linked (Join-Path $Root 'specs\001-feat\spec.md')
        $draft = Join-Path $Root '.specrew\runtime\draft-packet.md'
        [IO.File]::WriteAllText($draft, $text, [Text.UTF8Encoding]::new($false))
        $null = (& pwsh -NoProfile -File $declare -Kind boundary -MessagePath $draft -Summary 'packet' -Token $token 2>&1)
        $tx = Join-Path $Root 'transcript.jsonl'
        $turnLines = if ($Rollout) { @((New-RolloutLine -Role user -Text 'Continue.'), (New-RolloutLine -Role assistant -Text $text)) } else { @((New-Line -Role user -At '2026-08-29T00:00:30Z' -Text 'Continue.'), (New-Line -Role assistant -At '2026-08-29T00:01:00Z' -Text $text)) }
        [IO.File]::WriteAllLines($tx, [string[]]$turnLines, [Text.UTF8Encoding]::new($false))
        $null = (& pwsh -NoProfile -File $conformance --host-kind $HostKind --source-event Stop --session-id $Session --transcript-path $tx 2>&1)
        return $tx
    }
    finally { Pop-Location }
}
function Add-TranscriptLines { param([string]$Tx, [string[]]$Lines) [IO.File]::AppendAllLines($Tx, [string[]]$Lines, [Text.UTF8Encoding]::new($false)) }
function Start-SessionKind { param([string]$Root, [string]$Session, [string]$Kind, [string]$HostKind = 'claude')
    Push-Location -LiteralPath $Root
    try { $null = (& pwsh -NoProfile -File $conformance --host-kind $HostKind --source-event SessionStart --session-id $Session --session-start-source $Kind 2>&1) } finally { Pop-Location }
}
function Send-Prompt {
    # This message's own prompt event, through the real handover provider. Returns what it said.
    param([string]$Root, [string]$Session, [string]$Tx, [string]$Text, [string]$HostKind = 'claude')
    return ((& pwsh -NoProfile -File $provider --project-root $Root --host-kind $HostKind --session-id $Session --source-event UserPromptSubmit --transcript-path $Tx --last-user-message $Text `
                --turn-origin typed-user --message-identity declared --message-id ('prompt-' + [guid]::NewGuid().ToString('N').Substring(0, 12)) 2>$null) -join "`n")
}
function Get-LastEvidence { param([string]$Root) return [string]@((Read-Enforcement -Root $Root).verdict_history)[-1].evidence_source }
function Test-Told { param([string]$Output, [string]$Phrase) return ($Output -match '(?i)not\s+recorded|nothing\s+was\s+recorded' -and $Output -match [regex]::Escape($Phrase)) }
function Invoke-Stop { param([string]$Root, [string]$Tx)
    & pwsh -NoProfile -File $provider --event-json '{"hook_event_name":"Stop"}' --project-root $Root --host-kind claude --transcript-path $Tx 2>$null | Out-Null
}

try {
    Write-Host 'Case 1: packet, long run of tool calls, a real compact SessionStart, verdict: recorded once, at its prompt event (US2 scenario 3)'
    $r1 = New-PairingFixture -From 'tasks' -To 'before-implement'
    $tx1 = Show-Packet -Root $r1 -Session 'sess-c1' -From 'tasks' -To 'before-implement'
    $presented1 = Join-Path (Get-SpecrewTurnEndPaths -ProjectRoot $r1 -HostKind claude -SessionId 'sess-c1').TurnEndRoot 'presented-crossings.json'
    Assert-True (Test-Path -LiteralPath $presented1) 'the real Stop verified the packet'
    Add-TranscriptLines -Tx $tx1 -Lines ((New-ToolChatter) + $compaction)
    Start-SessionKind -Root $r1 -Session 'sess-c1' -Kind 'compact'
    Assert-True (-not (Test-Path -LiteralPath $presented1)) 'the compaction still clears the repaint memory (the repaint is unchanged)'
    Add-TranscriptLines -Tx $tx1 -Lines @(New-Line -Role user -At '2026-08-29T00:21:00Z' -Text 'approved for before-implement')
    $out1 = Send-Prompt -Root $r1 -Session 'sess-c1' -Tx $tx1 -Text 'approved for before-implement'
    $e1 = Read-Enforcement -Root $r1
    Assert-True ([string]$e1.last_authorized_boundary -eq 'before-implement') "the verdict after a compaction authorizes the waiting crossing (got '$($e1.last_authorized_boundary)'; output '$out1')"
    Assert-True ((Get-VerdictCount -Root $r1) -eq 1 -and (Get-LastEvidence -Root $r1) -ceq 'hook-captured-user-prompt') "and the ledger says it came from the prompt (got '$(Get-LastEvidence -Root $r1)')"
    Invoke-Stop -Root $r1 -Tx $tx1
    Invoke-Stop -Root $r1 -Tx $tx1
    Assert-True ((Get-VerdictCount -Root $r1) -eq 1) "and it records once across two turn ends (got $(Get-VerdictCount -Root $r1))"

    Write-Host 'Case 1b: the same transcript with no prompt event: the turn end records nothing'
    $r1b = New-PairingFixture -From 'tasks' -To 'before-implement'
    $tx1b = Write-Transcript -Root $r1b -Lines (@(New-Packet -From 'tasks' -To 'before-implement' -At '2026-08-29T00:01:00Z') + (New-ToolChatter) + $compaction +
        @(New-Line -Role assistant -At '2026-08-29T00:20:00Z' -Text 'Waiting for your before-implement verdict.') +
        @(New-Line -Role user -At '2026-08-29T00:21:00Z' -Text 'approved for before-implement'))
    Invoke-Stop -Root $r1b -Tx $tx1b
    Assert-True ((Get-VerdictCount -Root $r1b) -eq 0) "the turn end never pairs without the waiting crossing's marker (got $(Get-VerdictCount -Root $r1b))"

    Write-Host 'Case 2: no fallback to an older pair'
    $r2 = New-PairingFixture -From 'tasks' -To 'before-implement'
    $tx2 = Write-Transcript -Root $r2 -Lines @(
        (New-Packet -From 'plan' -To 'tasks' -At '2026-08-28T23:00:00Z'), (New-Line -Role user -At '2026-08-28T23:01:00Z' -Text 'approved for tasks'),
        (New-Packet -From 'tasks' -To 'before-implement' -At '2026-08-29T00:01:00Z'), (New-Line -Role user -At '2026-08-29T00:02:00Z' -Text 'changes needed: split T001'))
    $c2 = Get-SpecrewCapturedBoundaryVerdict -TranscriptPath $tx2 -ProjectRoot $r2 -HostKind claude
    Assert-True (-not [bool]$c2.Found) "a send-back to the waiting packet is not answered by the older plan -> tasks pair (got Found=$($c2.Found) $($c2.FromBoundary)->$($c2.ToBoundary))"
    $c2b = Get-SpecrewCapturedBoundaryVerdict -TranscriptPath $tx2 -HostKind claude
    Assert-True (-not [bool]$c2b.Found -or [string]$c2b.ToBoundary -ne 'tasks') "with no project to read, the reader still does not walk back to the older pair (got Found=$($c2b.Found) $($c2b.FromBoundary)->$($c2b.ToBoundary))"
    Invoke-Stop -Root $r2 -Tx $tx2
    Assert-True ((Get-VerdictCount -Root $r2) -eq 0 -and [string](Read-Enforcement -Root $r2).last_authorized_boundary -eq 'tasks') 'and the turn end records nothing'

    Write-Host 'Case 3 (the July sequence, DEC-198-GOV-003): an approval older than the crossing, read at the turn end, pairs with nothing'
    $r3 = New-PairingFixture -From 'tasks' -To 'before-implement' -RecordedAt '2026-08-29T00:10:00Z'
    $tx3 = Write-Transcript -Root $r3 -Lines (@(New-Line -Role user -At '2026-08-29T00:05:00Z' -Text 'approved for before-implement') + (New-ToolChatter) + $compaction +
        @(New-Line -Role assistant -At '2026-08-29T00:20:00Z' -Text 'The before-implement crossing is open; waiting for your verdict.'))
    Invoke-Stop -Root $r3 -Tx $tx3
    Assert-True ((Get-VerdictCount -Root $r3) -eq 0) "an approval older than the crossing records nothing (got $(Get-VerdictCount -Root $r3))"

    Write-Host 'Case 3b (the fallback that fabricated in July): a packet whose marker was dropped, then an approval, read at the turn end, pairs with nothing'
    $r3b = New-PairingFixture -From 'tasks' -To 'before-implement'
    $unmarked = (New-PacketText -From 'tasks' -To 'before-implement' -Linked (Join-Path $r3b 'specs\001-feat\spec.md')) -replace '<!-- SPECREW-VERDICT-BOUNDARY:.*?-->', ''
    $tx3b = Write-Transcript -Root $r3b -Lines @((New-Line -Role assistant -At '2026-08-29T00:01:00Z' -Text $unmarked), (New-Line -Role user -At '2026-08-29T00:02:00Z' -Text 'approved for before-implement'))
    $c3b = Get-SpecrewCapturedBoundaryVerdict -TranscriptPath $tx3b -ProjectRoot $r3b -HostKind claude
    Assert-True (-not [bool]$c3b.Found) "the reader finds no verdict at the turn end (got Found=$($c3b.Found) $($c3b.Reason))"
    Invoke-Stop -Root $r3b -Tx $tx3b
    Assert-True ((Get-VerdictCount -Root $r3b) -eq 0) "and the turn end records nothing (got $(Get-VerdictCount -Root $r3b))"

    Write-Host 'Case 4: a verdict naming another boundary records nothing and is reported (FR-020)'
    $r4 = New-PairingFixture -From 'clarify' -To 'plan'
    $tx4 = Write-Transcript -Root $r4 -Lines @((New-Packet -From 'clarify' -To 'plan' -At '2026-08-29T00:01:00Z'), (New-Line -Role user -At '2026-08-29T00:02:00Z' -Text 'approved for tasks'))
    $out4 = (& pwsh -NoProfile -File $provider --project-root $r4 --host-kind claude --source-event UserPromptSubmit --transcript-path $tx4 --last-user-message 'approved for tasks' `
            --turn-origin typed-user --message-identity declared --message-id 'prompt-c4' 2>&1) -join "`n"
    Invoke-Stop -Root $r4 -Tx $tx4
    $e4 = Read-Enforcement -Root $r4
    Assert-True ((Get-VerdictCount -Root $r4) -eq 0 -and [string]$e4.last_authorized_boundary -eq 'clarify') "'approved for tasks' while plan waits records nothing (got '$($e4.last_authorized_boundary)')"
    $drops = Join-Path $r4 '.specrew\runtime\authority-capture-drops.jsonl'
    $reported = ($out4 -match '(?i)not\s+recorded|was\s+not\s+recorded|nothing\s+was\s+recorded') -or ((Test-Path -LiteralPath $drops) -and ((Get-Content -LiteralPath $drops -Raw) -match 'boundary-mismatch'))
    Assert-True $reported 'and the human is told it was not recorded'

    # Red on 8308d468, both silent today. Neither reply can pair: the packet has left the tail, and the first names no
    # boundary while the second never reached the prompt hook. Nothing records, and the human has to be told so.
    Write-Host 'Case 5: a bare approval with the packet out of the tail records nothing and is reported in that turn'
    $r5 = New-PairingFixture -From 'tasks' -To 'before-implement'
    $tx5 = Show-Packet -Root $r5 -Session 'sess-c5' -From 'tasks' -To 'before-implement'
    Add-TranscriptLines -Tx $tx5 -Lines ((New-ToolChatter) + $compaction + @(New-Line -Role user -At '2026-08-29T00:21:00Z' -Text 'approved'))
    $out5 = (& pwsh -NoProfile -File $provider --project-root $r5 --host-kind claude --session-id 'sess-c5' --source-event UserPromptSubmit --transcript-path $tx5 --last-user-message 'approved' `
            --turn-origin typed-user --message-identity declared --message-id 'prompt-c5' 2>$null) -join "`n"
    Assert-True ((Get-VerdictCount -Root $r5) -eq 0) "a bare 'approved' whose packet left the tail records nothing (got $(Get-VerdictCount -Root $r5))"
    Assert-True ($out5 -match '(?i)not\s+recorded' -and $out5 -match 'approved for before-implement') "and that turn tells the human to type 'approved for before-implement' (got '$out5')"

    Write-Host 'Case 6: a verdict the prompt hook never received is reported by that turn end (T006: the same turn)'
    $r6 = New-PairingFixture -From 'tasks' -To 'before-implement'
    # The packet left the tail, the verdict reached the transcript, and no prompt event ran for it (the Stop that
    # verified the packet reads 'presented-unchanged', so the conformance Stop raises nothing either).
    $tx6 = Write-Transcript -Root $r6 -Lines (@(New-Packet -From 'tasks' -To 'before-implement' -At '2026-08-29T00:01:00Z') + (New-ToolChatter) + $compaction +
        @(New-Line -Role user -At '2026-08-29T00:21:00Z' -Text 'approved for before-implement'))
    $out6 = (& pwsh -NoProfile -File $provider --event-json '{"hook_event_name":"Stop"}' --project-root $r6 --host-kind claude --session-id 'sess-c6' --transcript-path $tx6 2>$null) -join "`n"
    Assert-True ((Get-VerdictCount -Root $r6) -eq 0) "the turn end does not record a verdict with no marker in the tail (got $(Get-VerdictCount -Root $r6))"
    Assert-True ($out6 -match '(?i)<<<SPECREW-VISIBLE-LINE>>>.*not\s+recorded' -and $out6 -match 'approved for before-implement') "and that turn end tells the human it was not recorded (got '$out6')"

    Write-Host 'Case 4b: naming the boundary already approved does not cross the next one (FR-020), on every path'
    $r4b = New-PairingFixture -From 'tasks' -To 'before-implement'
    $tx4b = Write-Transcript -Root $r4b -Lines @((New-Packet -From 'tasks' -To 'before-implement' -At '2026-08-29T00:01:00Z'), (New-Line -Role user -At '2026-08-29T00:02:00Z' -Text 'approved for tasks'))
    $marker4b = Get-SpecrewCapturedBoundaryVerdict -TranscriptPath $tx4b -ProjectRoot $r4b -HostKind claude
    Assert-True (-not [bool]$marker4b.Found) "the marker reader refuses it, not only the writer behind it (got $($marker4b.Reason))"
    $out4b = Send-Prompt -Root $r4b -Session 'sess-c4b' -Tx $tx4b -Text 'approved for tasks'
    Invoke-Stop -Root $r4b -Tx $tx4b
    Assert-True ((Get-VerdictCount -Root $r4b) -eq 0) "'approved for tasks' with the marker in the tail records nothing (got $(Get-VerdictCount -Root $r4b))"
    Assert-True (Test-Told -Output $out4b -Phrase 'approved for before-implement') "and the human is told what would (got '$out4b')"
    $direct4b = Get-SpecrewPromptEntryBoundaryVerdict -ProjectRoot $r4b -LastUserMessage 'approved for tasks' -HostKind copilot
    Assert-True (-not [bool]$direct4b.Found) "the prompt reader refuses it too (got $($direct4b.Reason))"
    $act4b = Resolve-SpecrewTypedAct -Turn ([pscustomobject]@{ host = 'claude'; message_id = 'm-4b'; message_identity = 'declared'; origin = 'typed-user'; text = 'approved for tasks' }) -Pending ([pscustomobject]@{ Crossing = [pscustomobject]@{ From = 'tasks'; To = 'before-implement'; StageEvidenceAbsent = $false }; Pause = $null; WorkshopQuestion = $null })
    Assert-True ([string]$act4b.Reason -ceq 'boundary-mismatch' -and [bool]$act4b.Report) "the classifier refuses it and reports it (got '$($act4b.Reason)')"
    $r4c = New-PairingFixture -From 'tasks' -To 'before-implement'
    $tx4c = Write-Transcript -Root $r4c -Lines @((New-Packet -From 'tasks' -To 'before-implement' -At '2026-08-29T00:01:00Z'), (New-Line -Role user -At '2026-08-29T00:02:00Z' -Text 'approve tasks -> before-implement'))
    $null = Send-Prompt -Root $r4c -Session 'sess-c4c' -Tx $tx4c -Text 'approve tasks -> before-implement'
    Assert-True ([string](Read-Enforcement -Root $r4c).last_authorized_boundary -eq 'before-implement') "naming both ends still approves the target (got '$((Read-Enforcement -Root $r4c).last_authorized_boundary)')"

    Write-Host 'Case 7: a crossing whose packet this session never showed records nothing and says so'
    $r7 = New-PairingFixture -From 'tasks' -To 'before-implement'
    $tx7 = Write-Transcript -Root $r7 -Lines (@(New-ToolChatter -Count 3) + @(New-Line -Role user -At '2026-08-29T00:21:00Z' -Text 'approved for before-implement'))
    $out7 = Send-Prompt -Root $r7 -Session 'sess-c7' -Tx $tx7 -Text 'approved for before-implement'
    Assert-True ((Get-VerdictCount -Root $r7) -eq 0) "a marker missing because no packet was rendered is not a marker that left the tail (got $(Get-VerdictCount -Root $r7))"
    Assert-True (Test-Told -Output $out7 -Phrase 'approved for before-implement') "and the human is told (got '$out7')"

    Write-Host 'Case 8: a second session in the same project, with no marker in its transcript, records nothing'
    $r8 = New-PairingFixture -From 'tasks' -To 'before-implement'
    $null = Show-Packet -Root $r8 -Session 'sess-c8-first' -From 'tasks' -To 'before-implement'
    $tx8 = Join-Path $r8 'second-session.jsonl'
    [IO.File]::WriteAllLines($tx8, [string[]]@((New-Line -Role user -At '2026-08-29T00:21:00Z' -Text 'approved for before-implement')), [Text.UTF8Encoding]::new($false))
    $out8 = Send-Prompt -Root $r8 -Session 'sess-c8-second' -Tx $tx8 -Text 'approved for before-implement'
    Assert-True ((Get-VerdictCount -Root $r8) -eq 0) "the first session's presentation does not vouch for the second (got $(Get-VerdictCount -Root $r8))"
    Assert-True (Test-Told -Output $out8 -Phrase 'approved for before-implement') "and the second session's human is told (got '$out8')"

    Write-Host 'Case 9: a shown record for a different crossing records nothing'
    $r9 = New-PairingFixture -From 'tasks' -To 'before-implement'
    $tx9 = Show-Packet -Root $r9 -Session 'sess-c9' -From 'tasks' -To 'before-implement'
    $shown9 = Get-SpecrewShownCrossingPath -TurnEndRoot (Get-SpecrewTurnEndPaths -ProjectRoot $r9 -HostKind claude -SessionId 'sess-c9').TurnEndRoot
    $record9 = Get-Content -LiteralPath $shown9 -Raw -Encoding UTF8 | ConvertFrom-Json
    Assert-True ([string]$record9.crossing_id -ceq [string](Get-SpecrewPendingVerdictState -ProjectRoot $r9).CrossingId) 'the real Stop wrote the shown record for the waiting crossing'
    $record9.crossing_id = 'crossing-00000000deadbeef'
    [IO.File]::WriteAllText($shown9, ($record9 | ConvertTo-Json -Depth 8 -Compress), [Text.UTF8Encoding]::new($false))
    Add-TranscriptLines -Tx $tx9 -Lines ((New-ToolChatter) + @(New-Line -Role user -At '2026-08-29T00:21:00Z' -Text 'approved for before-implement'))
    $out9 = Send-Prompt -Root $r9 -Session 'sess-c9' -Tx $tx9 -Text 'approved for before-implement'
    Assert-True ((Get-VerdictCount -Root $r9) -eq 0) "a packet shown for another crossing does not count (got $(Get-VerdictCount -Root $r9))"
    Assert-True (Test-Told -Output $out9 -Phrase 'approved for before-implement') "and the human is told (got '$out9')"

    Write-Host 'Case 10: the target check reads boundary aliases as one boundary, and another family never pairs through one'
    $r10 = New-PairingFixture -From 'before-implement' -To 'review-signoff'
    $null = Write-SpecrewPresentedCrossing -TurnEndRoot (Get-SpecrewTurnEndPaths -ProjectRoot $r10 -HostKind claude -SessionId 'sess-c10').TurnEndRoot -CrossingId (Get-SpecrewPresentedCrossingKey -Pending (Get-SpecrewPendingVerdictState -ProjectRoot $r10)) -ApprovalPhrase 'approved for review-signoff' -Marker '' -Message ''
    $tx10 = Write-Transcript -Root $r10 -Lines (@(New-ToolChatter -Count 3))
    foreach ($family in 'approved for review round', 'approved for allowance reset', 'approved for partial review signoff - accepted') {
        $null = Send-Prompt -Root $r10 -Session 'sess-c10' -Tx $tx10 -Text $family
        Assert-True ((Get-VerdictCount -Root $r10) -eq 0) "'$family' does not pair through the alias (got $(Get-VerdictCount -Root $r10))"
    }
    $null = Send-Prompt -Root $r10 -Session 'sess-c10' -Tx $tx10 -Text 'approved for plan'
    Assert-True ((Get-VerdictCount -Root $r10) -eq 0) "'approved for plan' names another boundary (got $(Get-VerdictCount -Root $r10))"
    # The fixture has no completed review campaign, so the stage's evidence gate refuses the write; the alias is read before it.
    $alias10 = Get-SpecrewOutOfTailPromptVerdict -ProjectRoot $r10 -LastUserMessage 'approved for review' -HostKind claude -SessionId 'sess-c10'
    Assert-True ([bool]$alias10.Found -and [string]$alias10.ToBoundary -ceq 'review-signoff') "'approved for review' pairs with review-signoff by its alias on the out-of-tail path (got $($alias10.Found) $($alias10.Reason))"
    $aliasTx = Write-Transcript -Root $r10 -Lines @((New-Packet -From 'before-implement' -To 'review-signoff' -At '2026-08-29T00:01:00Z'), (New-Line -Role user -At '2026-08-29T00:02:00Z' -Text 'approved for review'))
    $aliasMarker = Get-SpecrewCapturedBoundaryVerdict -TranscriptPath $aliasTx -ProjectRoot $r10 -HostKind claude
    Assert-True ([bool]$aliasMarker.Found -and [string]$aliasMarker.ToBoundary -ceq 'review-signoff') "and on the marker path (got $($aliasMarker.Found) $($aliasMarker.Reason))"
    $aliasAct = Resolve-SpecrewTypedAct -Turn ([pscustomobject]@{ host = 'claude'; message_id = 'm-10'; message_identity = 'declared'; origin = 'typed-user'; text = 'approved for review' }) -Pending ([pscustomobject]@{ Crossing = [pscustomobject]@{ From = 'before-implement'; To = 'review-signoff'; StageEvidenceAbsent = $false }; Pause = $null; WorkshopQuestion = $null })
    Assert-True ([string]$aliasAct.Kind -ceq 'boundary-verdict') "and in the classifier (got '$($aliasAct.Kind)' '$($aliasAct.Reason)')"
    $out10 = Send-Prompt -Root $r10 -Session 'sess-c10' -Tx $tx10 -Text 'approved for review'
    Assert-True ($out10 -notmatch "reads as a verdict for 'review'") "and the disclosure does not call the alias another crossing (got '$out10')"
    Assert-True (Test-SpecrewVerdictNamesBoundary -Named @('review') -Boundary @('review-signoff')) 'the check itself reads the alias'
    Assert-True (-not (Test-SpecrewVerdictNamesBoundary -Named @('before-implement') -Boundary @('review-signoff'))) 'and does not read the "from" end as the target'

    Write-Host 'Case 11: the shown record survives a compaction and nothing else'
    foreach ($kind in 'startup', 'resume', 'clear', 'something-new') {
        $r11 = New-PairingFixture -From 'tasks' -To 'before-implement'
        $s11 = "sess-c11-$kind"
        $tx11 = Show-Packet -Root $r11 -Session $s11 -From 'tasks' -To 'before-implement'
        Add-TranscriptLines -Tx $tx11 -Lines ((New-ToolChatter) + @(New-Line -Role user -At '2026-08-29T00:21:00Z' -Text 'approved for before-implement'))
        Start-SessionKind -Root $r11 -Session $s11 -Kind $kind
        $null = Send-Prompt -Root $r11 -Session $s11 -Tx $tx11 -Text 'approved for before-implement'
        Assert-True ((Get-VerdictCount -Root $r11) -eq 0) "a '$kind' start ends what was shown (got $(Get-VerdictCount -Root $r11))"
    }

    Write-Host 'Case 12: what the packet linked changed after it was shown: treated as not shown, across a compaction too'
    $r12 = New-PairingFixture -From 'tasks' -To 'before-implement'
    $tx12 = Show-Packet -Root $r12 -Session 'sess-c12' -From 'tasks' -To 'before-implement'
    Add-TranscriptLines -Tx $tx12 -Lines ((New-ToolChatter) + $compaction + @(New-Line -Role user -At '2026-08-29T00:21:00Z' -Text 'approved for before-implement'))
    Start-SessionKind -Root $r12 -Session 'sess-c12' -Kind 'compact'
    Add-Content -LiteralPath (Join-Path $r12 'specs\001-feat\spec.md') -Value 'changed after the packet' -Encoding UTF8
    $out12 = Send-Prompt -Root $r12 -Session 'sess-c12' -Tx $tx12 -Text 'approved for before-implement'
    Assert-True ((Get-VerdictCount -Root $r12) -eq 0) "a changed review target records nothing (got $(Get-VerdictCount -Root $r12))"
    Assert-True (Test-Told -Output $out12 -Phrase 'approved for before-implement') "and the human is told (got '$out12')"

    Write-Host "Case 13: Codex supplies a transcript too: its Stop reads the rollout format, writes the shown record, and the path works for it"
    $r13 = New-PairingFixture -From 'tasks' -To 'before-implement'
    $tx13 = Show-Packet -Root $r13 -Session 'sess-c13' -From 'tasks' -To 'before-implement' -HostKind 'codex' -Rollout
    $shown13 = Get-SpecrewShownCrossingPath -TurnEndRoot (Get-SpecrewTurnEndPaths -ProjectRoot $r13 -HostKind codex -SessionId 'sess-c13').TurnEndRoot
    Assert-True (Test-Path -LiteralPath $shown13) 'the Stop verified the packet from a Codex rollout and wrote the shown record'
    Add-TranscriptLines -Tx $tx13 -Lines (@(1..520 | ForEach-Object { New-RolloutLine -Role assistant -Text "tool call $_" }) + @(New-RolloutLine -Role user -Text 'approved for before-implement'))
    $c13 = Get-SpecrewCapturedBoundaryVerdict -TranscriptPath $tx13 -ProjectRoot $r13 -HostKind codex
    Assert-True ($c13.WaitingMarkerInTail -eq $false) 'the packet has left the tail of the rollout'
    $null = Send-Prompt -Root $r13 -Session 'sess-c13' -Tx $tx13 -Text 'approved for before-implement' -HostKind 'codex'
    Assert-True ([string](Read-Enforcement -Root $r13).last_authorized_boundary -eq 'before-implement') "the verdict records on Codex (got '$((Read-Enforcement -Root $r13).last_authorized_boundary)')"
}
finally {
    $env:SPECREW_MODULE_PATH = $savedModulePath
    foreach ($r in $script:roots) { Remove-Item -LiteralPath $r -Recurse -Force -ErrorAction SilentlyContinue }
}
if ($script:failCount -gt 0) { Write-Host "verdict-pairing.Tests.ps1: $($script:failCount) failure(s)" -ForegroundColor Red; exit 1 }
Write-Host 'verdict-pairing.Tests.ps1: all assertions passed' -ForegroundColor Green
