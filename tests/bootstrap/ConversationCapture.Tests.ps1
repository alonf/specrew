$ErrorActionPreference = 'Stop'

# F-174 iteration 010 (T002). Unit floor for the conversation-capture component (FR-022). Asserts the
# format-resilient 4-tier ladder against COMMITTED fixtures (frozen real-shape samples per host - they are
# the "what the format looked like" snapshot + the our-regression guard). NOTE: fixtures catch OUR parser
# regressions, NOT live host format drift - the live cross-host BYOK canary (separate proposal) catches drift.

. "$PSScriptRoot/../../scripts/internal/bootstrap/ConversationCaptureAccessor.ps1"
$FIX = Join-Path $PSScriptRoot 'fixtures/conversation'

function Assert-True { param([bool]$Condition, [string]$Message) if (-not $Condition) { throw "FAIL: $Message" } ; Write-Host "PASS: $Message" -ForegroundColor Green }

# --- Tier 1: each host's REAL schema yields the user+assistant canaries and EXCLUDES the noise. ---
$cases = @(
    @{ host = 'claude';  user = 'CANARY-CLAUDE-USER';  asst = 'CANARY-CLAUDE-ASSISTANT';  noise = @('NOISE-CLAUDE-SUMMARY', 'NOISE-CLAUDE-TOOLUSE') }
    @{ host = 'codex';   user = 'CANARY-CODEX-USER';   asst = 'CANARY-CODEX-ASSISTANT';   noise = @('NOISE-CODEX-META', 'NOISE-CODEX-DEVELOPER', 'NOISE-CODEX-REASONING') }
    @{ host = 'copilot'; user = 'CANARY-COPILOT-USER'; asst = 'CANARY-COPILOT-ASSISTANT'; noise = @('NOISE-COPILOT-START', 'NOISE-COPILOT-SYSTEM', 'NOISE-COPILOT-TOOL') }
    @{ host = 'cursor';  user = 'CANARY-CURSOR-USER';  asst = 'CANARY-CURSOR-ASSISTANT';  noise = @('NOISE-CURSOR-TOOLUSE', '[REDACTED]') }
)
foreach ($c in $cases) {
    # NOTE: literal .Contains() not -like, because fixture markers like "[REDACTED]" are char-class wildcards under -like.
    $out = [string](Get-SpecrewConversationTail -HostKind $c.host -TranscriptPath (Join-Path $FIX ("{0}.jsonl" -f $c.host)))
    Assert-True ($out.Contains($c.user))  "$($c.host): user turn captured"
    Assert-True ($out.Contains($c.asst))  "$($c.host): assistant turn captured"
    foreach ($n in $c.noise) { Assert-True (-not $out.Contains($n)) "$($c.host): noise excluded ($n)" }
    Assert-True ($out.Contains('Full transcript')) "$($c.host): on-demand pointer present"
    Assert-True (-not $out.Contains('format was not recognized')) "$($c.host): recognized (no drift note)"
}

# --- Tier 2: an unrecognized schema -> raw tail + VISIBLE degradation note (no crash, content survives). ---
$drift = Get-SpecrewConversationTail -HostKind codex -TranscriptPath (Join-Path $FIX 'drift.jsonl') -PerTurn 200
Assert-True ($drift -like '*format was not recognized*') 'drift: visible degradation note present'
Assert-True ($drift -like '*DRIFT-FORMAT*') 'drift: raw content still surfaced (graceful, not empty)'

# --- Tier 3: no readable file but a payload last_assistant_message -> render it. ---
$t3 = Get-SpecrewConversationTail -HostKind codex -TranscriptPath 'C:/nonexistent/missing.jsonl' -LastAssistantMessage 'PAYLOAD-LAST-MESSAGE survived'
Assert-True ($t3 -like '*PAYLOAD-LAST-MESSAGE survived*') 'tier3: last_assistant_message rendered when file unreadable'
Assert-True ($t3 -like '*last assistant message from the event payload*') 'tier3: payload-source note present'

# --- Floor: nothing exposed -> honest placeholder naming the host; never throws. ---
$floor = Get-SpecrewConversationTail -HostKind antigravity
Assert-True ($floor -like '*no conversation transcript exposed by antigravity*') 'floor: honest, host-named placeholder'
$floor2 = Get-SpecrewConversationTail -HostKind claude -TranscriptPath ''
Assert-True ($floor2 -like '*no conversation transcript exposed*') 'floor: empty path degrades to floor (no throw)'

# --- Budget: bounded by turn-count AND a hard char cap, independent of how many turns exist. ---
$big = Join-Path ([System.IO.Path]::GetTempPath()) ("convbig-" + [guid]::NewGuid().ToString('N') + '.jsonl')
try {
    $lines = 1..60 | ForEach-Object { '{"role":"' + (@('user', 'assistant')[$_ % 2]) + '","message":{"content":[{"type":"text","text":"turn ' + $_ + ' ' + ('x' * 300) + '"}]}}' }
    Set-Content -LiteralPath $big -Value $lines -Encoding UTF8
    $capped = Get-SpecrewConversationTail -HostKind cursor -TranscriptPath $big -MaxTurns 8 -MaxChars 4000 -PerTurn 240
    $bulletCount = @($capped -split "`n" | Where-Object { $_ -match '^\- \*\*(user|assistant):\*\*' }).Count
    Assert-True ($bulletCount -le 8) "budget: turn cap honored ($bulletCount <= 8)"
    Assert-True ($capped.Length -le 4000 + 200) "budget: hard char cap honored (len $($capped.Length))"
    Assert-True ($capped -like '*turn 60*') 'budget: keeps the NEWEST turns (turn 60 present)'
    Assert-True (-not ($capped -like '*turn 1 *')) 'budget: drops the oldest turns (turn 1 absent)'
}
finally { Remove-Item -LiteralPath $big -Force -ErrorAction SilentlyContinue }

# --- Tail bound (F3): the read is bounded to the LAST $MaxTailLines lines, so a turn BEYOND the tail window is
#     never read (the O(session)->O(tail) optimization). Isolated from the MaxTurns cap by using a small tail
#     with a LARGE MaxTurns: only the tail can be the limiter, so an early-line turn being absent proves the
#     tail bound, not the turn cap. (Prop-145 P5: a turn past the window is provably skipped.) ---
$tailFix = Join-Path ([System.IO.Path]::GetTempPath()) ("convtail-" + [guid]::NewGuid().ToString('N') + '.jsonl')
try {
    $tlines = 1..30 | ForEach-Object {
        $mark = if ($_ -eq 1) { 'EARLY-CANARY-LINE1' } elseif ($_ -eq 30) { 'LATE-CANARY-LINE30' } else { "mid $_" }
        '{"role":"' + (@('user', 'assistant')[$_ % 2]) + '","message":{"content":[{"type":"text","text":"' + $mark + '"}]}}'
    }
    Set-Content -LiteralPath $tailFix -Value $tlines -Encoding UTF8
    $tailed = [string](Get-SpecrewConversationTail -HostKind cursor -TranscriptPath $tailFix -MaxTailLines 10 -MaxTurns 20 -MaxChars 8000)
    Assert-True ($tailed.Contains('LATE-CANARY-LINE30')) 'tail-bound: a turn INSIDE the tail window survives'
    Assert-True (-not $tailed.Contains('EARLY-CANARY-LINE1')) 'tail-bound: a turn BEYOND the tail window is never read (MaxTurns=20 would have kept it; the tail bound drops it)'
}
finally { Remove-Item -LiteralPath $tailFix -Force -ErrorAction SilentlyContinue }

# --- T004 / FR-010: a leading recognized approval phrase WINS over any instruction wording that
#     follows. Every case below is an iteration-011 reproduction: the classifier scanned the WHOLE
#     utterance for send-back / discuss words, so ordinary instructions after a clear approval flipped
#     the verdict to a non-approval and the crossing recorded un-authorized. The human then had to
#     re-approve using words that avoided a vocabulary they were never told about. ---
$approveWithInstructions = @(
    @{ text = 'approved for before-implement — then discuss prompt 2 with me'; why = 'trailing "discuss prompt 2" is an instruction, not a request to deliberate' }
    @{ text = 'approved for tasks, and send back the draft doc when you are done';  why = 'trailing "send back" refers to a document, not to the verdict' }
    @{ text = 'approved for plan. changes needed in the README are noted for later'; why = 'an affirmative change clause AFTER the approval is instruction wording' }
    @{ text = 'approved for review-signoff with instructions: reject any finding without a failure scenario'; why = '"reject" describes what to do with findings, not the boundary' }
    @{ text = 'approved for implement. should I also update the changelog?';        why = 'a trailing QUESTION is a follow-up, not an interrogative approval' }
)
foreach ($c in $approveWithInstructions) {
    $v = Test-SpecrewHumanVerdictToken -Text $c.text
    Assert-True ($v.IsApproval) "FR-010 leading approval wins: $($c.why)"
    Assert-True ($v.Action -eq 'approve') "FR-010 action is approve: $($c.text)"
}

# --- T004 / FR-010: boundary-name words used as PLAIN ENGLISH in the instructions must never flip the
#     classification. NamedBoundaries is a cross-check against the packet marker, so a stray "plan" or
#     "review" in a sentence of instructions used to contradict the marker and make a clear verdict
#     ambiguous - which the caller records as un-authorized. Only the boundary named BY the approval
#     phrase itself counts. ---
$named = Test-SpecrewHumanVerdictToken -Text 'approved for tasks — the plan looks good and the review list is fine, so implement it'
Assert-True ($named.IsApproval) 'FR-010 plain-English boundary words: still an approval'
Assert-True (@($named.NamedBoundaries).Count -eq 1) "FR-010 plain-English boundary words: exactly one boundary named (got $(@($named.NamedBoundaries) -join ','))"
Assert-True (@($named.NamedBoundaries)[0] -eq 'tasks') 'FR-010 plain-English boundary words: the approval phrase names the boundary, not the prose'

$bare = Test-SpecrewHumanVerdictToken -Text 'approved — the review notes look right'
Assert-True ($bare.IsApproval) 'FR-010 bare approval with prose: still an approval'
Assert-True (@($bare.NamedBoundaries).Count -eq 0) 'FR-010 bare approval with prose: names no boundary, so the marker decides alone'

# --- T004 / FR-010 SAFETY: the conservative floor is UNCHANGED. Capture must never invent an approval
#     the human did not give, so each of these stays a non-approval. Recorded as the paired sibling of
#     the cases above: leading-phrase-wins is a rule about what FOLLOWS a clear approval, never a
#     relaxation of what counts as one. ---
$nonApprovals = @(
    @{ text = 'send back — the plan needs work';                       approval = $false; action = 'send-back' }
    @{ text = 'changes needed before this can go ahead';               approval = $false; action = 'send-back' }
    @{ text = 'discuss prompt 2';                                      approval = $false; action = 'discuss' }
    @{ text = 'do not approve this yet';                               approval = $false; action = 'none' }
    @{ text = 'approve?';                                              approval = $false; action = 'none' }
    @{ text = 'should I approve this or not?';                         approval = $false; action = 'none' }
    @{ text = 'reply with approved for tasks when you are ready';      approval = $false; action = 'none' }
    @{ text = '1';                                                     approval = $false; action = 'none' }
    @{ text = 'yes';                                                   approval = $false; action = 'none' }
)
foreach ($c in $nonApprovals) {
    $v = Test-SpecrewHumanVerdictToken -Text $c.text
    Assert-True ($v.IsApproval -eq $c.approval) "FR-010 safety floor: '$($c.text)' is not an approval"
    Assert-True ($v.Action -eq $c.action) "FR-010 safety floor: '$($c.text)' -> $($c.action) (got $($v.Action))"
}

# --- T004 / FR-010: the captured TEXT keeps the instructions, so what the human authorized and what
#     they asked for are one record rather than an approval with its conditions dropped. ---
$capturedDirect = Get-SpecrewCapturedVerdictText -HumanText 'approved for before-implement — then discuss prompt 2 with me' -ToBoundary 'before-implement'
Assert-True ($capturedDirect.StartsWith('approved for before-implement')) 'FR-010 captured text: canonical prefix preserved for the writer'
Assert-True ($capturedDirect.Contains('discuss prompt 2')) 'FR-010 captured text: the instructions survive byte-for-byte'

# --- T004 / FR-010: marker-FORWARD capture. The first VERDICT-BEARING human turn after the packet
#     wins, and non-verdict turns in between are scanned PAST rather than taken as the answer.
#
#     The shape that motivated it is the commonest one there is: packet rendered -> human asks a
#     clarifying question -> agent answers -> human approves. Taking the first human turn whatever it
#     said classified the QUESTION as the verdict ('none'), abandoned the marker, and never read the
#     approval two turns later - so a verdict sitting in the transcript recorded as un-authorized.
#
#     The two safety properties are asserted alongside it, because both are directions this could
#     have failed in: a send-back or discuss request IS verdict-bearing and can never be scanned past
#     to reach an approval behind it, and the window ENDS at the next packet so one crossing's
#     approval is never attributed to another. ---
function New-CaptureTurn { param([string]$Role, [string]$Text) '{"role":"' + $Role + '","message":{"content":[{"type":"text","text":' + ($Text | ConvertTo-Json) + '}]}}' }
function Get-CaptureVerdictFor {
    param([string[]]$Lines)
    $p = Join-Path ([IO.Path]::GetTempPath()) ("capfwd-" + [guid]::NewGuid().ToString('N') + '.jsonl')
    Set-Content -LiteralPath $p -Value $Lines -Encoding UTF8
    try { return Get-SpecrewCapturedBoundaryVerdict -TranscriptPath $p }
    finally { Remove-Item -LiteralPath $p -Force -ErrorAction SilentlyContinue }
}
$packetOne = 'Packet body. <!-- SPECREW-VERDICT-BOUNDARY: tasks -> before-implement -->'

$fwd = Get-CaptureVerdictFor @(
    (New-CaptureTurn assistant $packetOne)
    (New-CaptureTurn user 'what about the antigravity case?')
    (New-CaptureTurn assistant 'It is covered by T006.')
    (New-CaptureTurn user 'approved for before-implement')
)
Assert-True ([bool]$fwd.Found) 'FR-010 marker-forward: an approval AFTER a clarifying question is captured'
Assert-True ($fwd.ToBoundary -eq 'before-implement') 'FR-010 marker-forward: captured against the marker''s own crossing'

$blocked = Get-CaptureVerdictFor @(
    (New-CaptureTurn assistant $packetOne)
    (New-CaptureTurn user 'send back - the plan needs a security section')
    (New-CaptureTurn assistant 'Understood.')
    (New-CaptureTurn user 'approved for before-implement')
)
Assert-True (-not [bool]$blocked.Found) 'FR-010 marker-forward SAFETY: a send-back is never scanned past to reach an approval behind it'

$discussed = Get-CaptureVerdictFor @(
    (New-CaptureTurn assistant $packetOne)
    (New-CaptureTurn user 'discuss prompt 2')
    (New-CaptureTurn assistant 'Here is prompt 2.')
    (New-CaptureTurn user 'approved for before-implement')
)
Assert-True (-not [bool]$discussed.Found) 'FR-010 marker-forward SAFETY: a discuss request is never scanned past either'

$bounded = Get-CaptureVerdictFor @(
    (New-CaptureTurn assistant $packetOne)
    (New-CaptureTurn user 'what about the antigravity case?')
    (New-CaptureTurn assistant 'Second packet. <!-- SPECREW-VERDICT-BOUNDARY: before-implement -> review-signoff -->')
    (New-CaptureTurn user 'approved for review-signoff')
)
Assert-True ($bounded.ToBoundary -eq 'review-signoff') 'FR-010 marker-forward SAFETY: the window ends at the next packet, so no approval is attributed across crossings'

$awaiting = Get-CaptureVerdictFor @(
    (New-CaptureTurn assistant $packetOne)
    (New-CaptureTurn user 'what about the antigravity case?')
    (New-CaptureTurn assistant 'It is covered by T006.')
    (New-CaptureTurn user 'and the OneDrive one?')
)
Assert-True (-not [bool]$awaiting.Found) 'FR-010 marker-forward: a window of only non-verdict turns stays awaiting, never captured'

Write-Host "`n=== ConversationCapture.Tests.ps1: all assertions passed ===" -ForegroundColor Green
