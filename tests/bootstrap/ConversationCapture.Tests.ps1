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

Write-Host "`n=== ConversationCapture.Tests.ps1: all assertions passed ===" -ForegroundColor Green
