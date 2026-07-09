[CmdletBinding()]
param()
Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

# Feature 197 iteration 004 (T072, #2885): behavior-lock + parse-once guard for the bootstrap transcript
# parse path in ConversationCaptureAccessor.ps1.
#
# #2885: three consumers (Get-SpecrewCapturedBoundaryVerdict / Get-SpecrewCapturedBoundaryPacket /
# Get-SpecrewConversationTail) each independently read the transcript tail and ConvertFrom-Json every line
# (the ~11s of the ~16s Stop-hook latency). T070 refactors them to parse ONCE per (path, mtime, MaxLines)
# and share the extracted {role; parts} turns. This is high-stakes: the verdict reader captures the human's
# boundary VERDICT, so a parsing regression is unacceptable.
#
# This file is TEST-FIRST: STEP 1 is a behavior-lock that runs GREEN on the CURRENT (un-refactored) code,
# snapshotting the three consumers' outputs to DURABLE goldens (write-if-absent, else compare). STEP 3's
# parse-once counter assertion is GUARDED so it is a no-op until the memo + counter accessor exist (it
# cannot pass on un-memoized code). Both the byte-identical lock and the parse-once guard run on EVERY
# invocation; after the refactor lands, the same goldens must still match byte-for-byte AND the parse must
# run once per stop, not three times.
#
# Run discipline (CONSTRAINT): own fresh `pwsh -NoProfile -NonInteractive`, $env:TEMP/$env:TMP on a
# short-path-free dir, $env:SPECREW_MODULE_PATH = repo root.

. "$PSScriptRoot/../../../scripts/internal/bootstrap/ConversationCaptureAccessor.ps1"

$script:Pass = 0
$script:Fail = 0
function Assert-True {
    param([bool]$Condition, [string]$Message)
    if ($Condition) { Write-Host "PASS: $Message" -ForegroundColor Green; $script:Pass++ }
    else { Write-Host "FAIL: $Message" -ForegroundColor Red; $script:Fail++ }
}

# ---------------------------------------------------------------------------------------------------------
# Fixture: a multi-host-schema transcript .jsonl. Each line is one host's REAL message shape so the parse
# path exercises every branch of Get-SpecrewConversationTurnFromLine (claude / codex / copilot / cursor /
# antigravity). The packet-bearing assistant turn carries the invisible verdict marker + a >200-char
# six-section packet body; the following user turn is a CLEAR approval ("approved"). This is the shape the
# verdict/packet readers must capture.
# ---------------------------------------------------------------------------------------------------------

$boundaryMarker = '<!-- SPECREW-VERDICT-BOUNDARY: plan -> tasks -->'
$packetBody = @(
    $boundaryMarker
    '## What I Just Did'
    'Authored the iteration plan covering the #2885 latency fix and the gate-enforcement wiring.'
    '## Why I Stopped'
    'Boundary: plan. The plan is drafted and needs your verdict before tasks are derived.'
    '## What Needs Your Review'
    'The scope table, the effort model, and the traceability summary in plan.md.'
    '## What Happens Next'
    'On approval I derive the task table and begin the test-first implementation of #2885.'
    '## Discussion Prompts'
    '1. Is the opt-in gate flag default-OFF posture acceptable for governed projects?'
    '## What I Need From You'
    'Reply: approved for tasks / rejected for tasks / parked.'
) -join "`n"

# Build per-host JSONL lines. The packet (assistant) + approval (user) pair is rendered in the CLAUDE
# schema (the primary host); the other host schemas carry distinct canary turns so every parse branch is
# exercised and contributes to the shared-parse count.
function ConvertTo-JsonLine { param($Obj) ($Obj | ConvertTo-Json -Depth 40 -Compress) }

$lines = @(
    # --- Antigravity: explicit human turn (USER_EXPLICIT/USER_INPUT, <USER_REQUEST> wrapper) ---
    (ConvertTo-JsonLine ([ordered]@{ source = 'USER_EXPLICIT'; type = 'USER_INPUT'; content = '<USER_REQUEST>ANTIGRAVITY-USER kick off the plan boundary</USER_REQUEST>' }))
    # --- Antigravity: planner response (MODEL/PLANNER_RESPONSE, top-level content) ---
    (ConvertTo-JsonLine ([ordered]@{ source = 'MODEL'; type = 'PLANNER_RESPONSE'; content = 'ANTIGRAVITY-ASSISTANT planning the iteration now.' }))
    # --- Codex: response_item -> payload.role + payload.content[] ---
    (ConvertTo-JsonLine ([ordered]@{ type = 'response_item'; payload = [ordered]@{ type = 'message'; role = 'user'; content = @([ordered]@{ type = 'input_text'; text = 'CODEX-USER what is the latency budget?' }) } }))
    (ConvertTo-JsonLine ([ordered]@{ type = 'response_item'; payload = [ordered]@{ type = 'message'; role = 'assistant'; content = @([ordered]@{ type = 'output_text'; text = 'CODEX-ASSISTANT the budget is roughly sixteen seconds today.' }) } }))
    # --- Copilot: type prefix carries role; data.content is the text string ---
    (ConvertTo-JsonLine ([ordered]@{ type = 'user.message'; data = [ordered]@{ content = 'COPILOT-USER show me the scope.' } }))
    (ConvertTo-JsonLine ([ordered]@{ type = 'assistant.message'; data = [ordered]@{ content = 'COPILOT-ASSISTANT here is the scope summary.' } }))
    # --- Cursor: top-level role + message.content[] ---
    (ConvertTo-JsonLine ([ordered]@{ role = 'user'; message = [ordered]@{ content = @([ordered]@{ type = 'text'; text = 'CURSOR-USER ready when you are.' }) } }))
    (ConvertTo-JsonLine ([ordered]@{ role = 'assistant'; message = [ordered]@{ content = @([ordered]@{ type = 'text'; text = 'CURSOR-ASSISTANT acknowledged.' }) } }))
    # --- Claude: the packet-bearing assistant turn (carries the verdict marker + six-section body) ---
    (ConvertTo-JsonLine ([ordered]@{ type = 'assistant'; message = [ordered]@{ content = @([ordered]@{ type = 'text'; text = $packetBody }) } }))
    # --- Claude: the human's verdict response to that packet ---
    (ConvertTo-JsonLine ([ordered]@{ type = 'user'; message = [ordered]@{ content = @([ordered]@{ type = 'text'; text = 'approved' }) } }))
)

$tmpRoot = if (-not [string]::IsNullOrWhiteSpace($env:TEMP)) { $env:TEMP } else { [System.IO.Path]::GetTempPath() }
$fixture = Join-Path $tmpRoot ('t072-parse-once-' + [guid]::NewGuid().ToString('N') + '.jsonl')
Set-Content -LiteralPath $fixture -Value $lines -Encoding UTF8

# Durable goldens live next to the test so they survive the STEP-1 -> refactor -> STEP-3 process boundary.
# They are the COMMITTED, pre-refactor reference behavior. The guard is only real if a missing golden FAILS
# (not silently re-records against whatever code is present - that would lock in a regression on a fresh
# checkout). Record mode is EXPLICIT and one-time: set $env:RECORD_GOLDENS=1 (the very first run, on KNOWN-GOOD
# code) to write the references; every run after that COMPARES and FAILS on drift OR on an absent golden.
$goldenDir = Join-Path $PSScriptRoot 'fixtures/transcript-parse-once'
$recordGoldens = ($env:RECORD_GOLDENS -eq '1' -or $env:RECORD_GOLDENS -eq 'true')
if ($recordGoldens -and -not (Test-Path -LiteralPath $goldenDir)) { New-Item -ItemType Directory -Path $goldenDir -Force | Out-Null }

function Assert-Golden {
    param([string]$Name, [string]$Actual)
    $path = Join-Path $goldenDir ($Name + '.golden.txt')
    # Normalize the volatile fixture path out of any captured value so the golden is portable.
    $normalized = $Actual -replace [regex]::Escape($fixture), '<FIXTURE>'
    if ($recordGoldens) {
        if (-not (Test-Path -LiteralPath $goldenDir)) { New-Item -ItemType Directory -Path $goldenDir -Force | Out-Null }
        Set-Content -LiteralPath $path -Value $normalized -Encoding UTF8 -NoNewline
        Write-Host "RECORDED GOLDEN: $Name (RECORD_GOLDENS mode)" -ForegroundColor Cyan
        $script:Pass++
        return
    }
    if (-not (Test-Path -LiteralPath $path)) {
        # Absent golden in COMPARE mode = a dead guard. FAIL loudly instead of silently re-recording.
        Assert-True $false "golden MISSING (run once with RECORD_GOLDENS=1 on known-good code to record): $Name"
        return
    }
    $expected = [System.IO.File]::ReadAllText($path)
    Assert-True ($normalized -ceq $expected) "golden byte-identical: $Name"
    if ($normalized -cne $expected) {
        Write-Host "  --- expected (len $($expected.Length)) ---`n$expected" -ForegroundColor DarkYellow
        Write-Host "  --- actual   (len $($normalized.Length)) ---`n$normalized" -ForegroundColor DarkYellow
    }
}

try {
    # =====================================================================================================
    # STEP 1 - behavior-lock the three consumers against durable goldens.
    # =====================================================================================================

    $verdict = Get-SpecrewCapturedBoundaryVerdict -TranscriptPath $fixture -LastUserMessage 'approved'
    Assert-True ([bool]$verdict.Found) 'verdict: Found is true (marker + clear approval captured)'
    Assert-Golden 'verdict-found' ([string]$verdict.Found)
    Assert-Golden 'verdict-from' ([string]$verdict.FromBoundary)
    Assert-Golden 'verdict-to' ([string]$verdict.ToBoundary)
    Assert-Golden 'verdict-text' ([string]$verdict.VerdictText)
    Assert-Golden 'verdict-human' ([string]$verdict.HumanText)
    Assert-Golden 'verdict-reason' ([string]$verdict.Reason)

    $packet = Get-SpecrewCapturedBoundaryPacket -TranscriptPath $fixture
    Assert-True ([bool]$packet.Found) 'packet: Found is true (marker + substantive body captured)'
    Assert-Golden 'packet-found' ([string]$packet.Found)
    Assert-Golden 'packet-from' ([string]$packet.FromBoundary)
    Assert-Golden 'packet-to' ([string]$packet.ToBoundary)
    Assert-Golden 'packet-body' ([string]$packet.PacketBody)
    Assert-Golden 'packet-reason' ([string]$packet.Reason)

    $tail = [string](Get-SpecrewConversationTail -HostKind claude -TranscriptPath $fixture)
    Assert-True ($tail.Length -gt 0) 'tail: non-empty'
    Assert-Golden 'conversation-tail' $tail

    # Structural cross-checks (independent of the golden literals) so a wrong-but-self-consistent golden is
    # still caught on the very first run.
    Assert-True ($verdict.FromBoundary -eq 'plan' -and $verdict.ToBoundary -eq 'tasks') 'verdict: boundary is plan -> tasks (marker parsed)'
    Assert-True ($verdict.VerdictText -eq 'approved for tasks') 'verdict: VerdictText is canonical "approved for tasks"'
    Assert-True ($verdict.HumanText -eq 'approved') 'verdict: HumanText is the human approval token'
    Assert-True ($packet.PacketBody -like '*## What I Just Did*' -and $packet.PacketBody -like '*## What I Need From You*') 'packet: six-section body round-tripped (## headers preserved by -Raw)'
    Assert-True ($packet.PacketBody.Contains("`n")) 'packet: newline structure preserved (-Raw path)'
    # The default (non-Raw) tail collapses ALL internal whitespace to single spaces, so the packet's
    # newline-prefixed "## " block structure is gone. The text "## What I Just Did" still appears (flattened),
    # but never with a NEWLINE before a "## " header the way the -Raw packet preserves it.
    Assert-True (-not ($tail -match "`n\s*## What I Just Did")) 'tail: whitespace collapsed (no newline-prefixed ## block structure, unlike -Raw)'

    # =====================================================================================================
    # STEP 3a - synthetic-user-turn leak guard. The verdict reader appends a synthetic user turn from
    # $LastUserMessage onto ITS OWN turn list; that must NEVER leak into the packet or the conversation
    # tail (the shared memo must hand each consumer a COPY). Run the verdict consumer with a DISTINCT
    # synthetic marker first, then re-read packet + tail and assert the marker is absent.
    # =====================================================================================================
    $syntheticCanary = 'SYNTHETIC-LEAK-CANARY-approved'
    $null = Get-SpecrewCapturedBoundaryVerdict -TranscriptPath $fixture -LastUserMessage $syntheticCanary
    $packetAfter = Get-SpecrewCapturedBoundaryPacket -TranscriptPath $fixture
    $tailAfter = [string](Get-SpecrewConversationTail -HostKind claude -TranscriptPath $fixture)
    $packetLeaks = ([string]$packetAfter.PacketBody).Contains($syntheticCanary)
    $tailLeaks = $tailAfter.Contains($syntheticCanary)
    Assert-True (-not $packetLeaks) 'leak-guard: synthetic user turn does NOT leak into the packet'
    Assert-True (-not $tailLeaks) 'leak-guard: synthetic user turn does NOT leak into the conversation tail'
    # And the packet/tail are still byte-identical to the goldens after the verdict consumer mutated its copy.
    Assert-Golden 'packet-body' ([string]$packetAfter.PacketBody)
    Assert-Golden 'conversation-tail' $tailAfter

    # =====================================================================================================
    # STEP 3b - PARSE-ONCE guard (GUARDED: no-op until the T070 memo + counter accessor exist).
    # One "stop" = the three consumers reading the SAME (path, mtime, MaxLines). On the refactored code the
    # shared extract must run ONCE for that key, not once per consumer. We count the number of LINES the
    # extract ConvertFrom-Json'd: it must equal the line-count of a SINGLE tail parse (parse-once), not
    # three times that (parse-thrice). Skipped on un-memoized code so STEP 1 stays green.
    # =====================================================================================================
    if ((Get-Command Get-SpecrewTranscriptParseCount -ErrorAction SilentlyContinue) -and
        (Get-Command Reset-SpecrewTranscriptParseCount -ErrorAction SilentlyContinue) -and
        (Get-Command Clear-SpecrewTranscriptParseMemo -ErrorAction SilentlyContinue)) {

        # Baseline: how many lines does ONE cold tail parse cost? (the per-stop floor). Clear the memo so this
        # measurement is a guaranteed cache MISS, isolated from any prior populate.
        Clear-SpecrewTranscriptParseMemo
        Reset-SpecrewTranscriptParseCount
        $null = Get-SpecrewConversationTail -HostKind claude -TranscriptPath $fixture
        $onePassCount = Get-SpecrewTranscriptParseCount
        Assert-True ($onePassCount -gt 0) "parse-once: a single consumer parses > 0 lines (got $onePassCount)"

        # One stop, COLD: all three consumers, same (path, mtime, MaxLines) key. The shared memo must make the
        # expensive ConvertFrom-Json extract run ONCE for the key - the first consumer misses, the other two hit.
        Clear-SpecrewTranscriptParseMemo
        Reset-SpecrewTranscriptParseCount
        $null = Get-SpecrewCapturedBoundaryVerdict -TranscriptPath $fixture -LastUserMessage 'approved'
        $null = Get-SpecrewCapturedBoundaryPacket -TranscriptPath $fixture
        $null = Get-SpecrewConversationTail -HostKind claude -TranscriptPath $fixture
        $threeConsumerCount = Get-SpecrewTranscriptParseCount

        Assert-True ($threeConsumerCount -eq $onePassCount) "parse-once: three consumers parse ONCE per stop ($threeConsumerCount == $onePassCount), not thrice ($([int]$onePassCount * 3))"

        # And prove the memo actually serves hits: a second identical stop with NO clear parses ZERO new lines.
        Reset-SpecrewTranscriptParseCount
        $null = Get-SpecrewCapturedBoundaryVerdict -TranscriptPath $fixture -LastUserMessage 'approved'
        $null = Get-SpecrewCapturedBoundaryPacket -TranscriptPath $fixture
        $null = Get-SpecrewConversationTail -HostKind claude -TranscriptPath $fixture
        $warmCount = Get-SpecrewTranscriptParseCount
        Assert-True ($warmCount -eq 0) "parse-once: a warm stop (memo populated, same key) parses ZERO new lines (got $warmCount)"
    }
    else {
        Write-Host "SKIP: parse-once counter accessor not present yet (pre-T070-refactor) - guard is a no-op on un-memoized code." -ForegroundColor Yellow
    }
}
finally {
    Remove-Item -LiteralPath $fixture -Force -ErrorAction SilentlyContinue
}

Write-Host "`n=== transcript-parse-once.Tests.ps1: $script:Pass passed, $script:Fail failed ===" -ForegroundColor $(if ($script:Fail -eq 0) { 'Green' } else { 'Red' })
if ($script:Fail -gt 0) { exit 1 }
exit 0
