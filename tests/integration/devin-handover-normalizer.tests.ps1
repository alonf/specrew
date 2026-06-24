[CmdletBinding()]
param()

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

# Feature 200 T008 (FR-011, in-package): the Devin handover normalizer (DevinHandoverAdapter)
# converts Devin's --export ATIF output into the EXISTING Claude-like JSONL turn shape that the
# UNCHANGED parser (scripts/internal/bootstrap/ConversationCaptureAccessor.ps1) consumes. This test
# replays the spike-proven path: the spike fixture -> the in-package normalizer -> the unchanged
# parser, asserting the parser reads the turns successfully (reproduces UNCHANGED_PARSER_CAPTURE_PASS).
# It also asserts the normalizer is deterministic (byte-stable on repeated runs).

function Write-Pass { param([string]$Message) Write-Host "PASS: $Message" -ForegroundColor Green }
function Write-Fail { param([string]$Message) Write-Host "FAIL: $Message" -ForegroundColor Red; exit 1 }

$repoRoot = (Resolve-Path (Join-Path -Path $PSScriptRoot -ChildPath '..\..')).Path
$adapterScript = Join-Path $repoRoot 'hosts\devin\handover-adapter.ps1'
$accessorScript = Join-Path $repoRoot 'scripts\internal\bootstrap\ConversationCaptureAccessor.ps1'
$fixturePath = Join-Path $repoRoot 'specs\200-devin-cli-host\iterations\002\research\devin-atif-export.fixture.json'

foreach ($p in @($adapterScript, $accessorScript, $fixturePath)) {
    if (-not (Test-Path -LiteralPath $p -PathType Leaf)) { Write-Fail "Missing required file: $p" }
}

# Dot-source the IN-PACKAGE normalizer and the UNCHANGED production parser (not a reimplementation).
. $adapterScript
. $accessorScript

$canaryUser = 'Reply with exactly: SPECREW_DEVIN_STOP_CANARY_200_WITH_SH'
$canaryAgent = 'SPECREW_DEVIN_STOP_CANARY_200_WITH_SH'

# --- Test 1: normalize the spike ATIF fixture to the parser's Claude-like JSONL shape. ---
$atifText = Get-Content -LiteralPath $fixturePath -Raw -Encoding UTF8
$jsonl = ConvertFrom-DevinAtifToParserJsonl -Atif $atifText
if ([string]::IsNullOrWhiteSpace($jsonl)) {
    Write-Fail 'Normalizer produced empty output for the spike ATIF fixture.'
}
$lines = @($jsonl -split "`n")
if ($lines.Count -ne 2) {
    Write-Fail "Expected 2 normalized JSONL turn lines (user + agent); got $($lines.Count)."
}
foreach ($l in $lines) {
    $o = $l | ConvertFrom-Json -Depth 20
    if ($o.type -notin @('user', 'assistant')) { Write-Fail "Normalized line has unexpected type '$($o.type)': $l" }
    if ($null -eq $o.message -or $null -eq $o.message.content) { Write-Fail "Normalized line missing message.content: $l" }
    if ([string]$o.message.content[0].type -ne 'text') { Write-Fail "Normalized content part is not 'text': $l" }
}
Write-Pass 'Normalizer emits the Claude-like JSONL turn shape (type + message.content[].text) for the spike fixture'

# --- Test 2: the AGENT source maps to assistant, USER stays user (correct turn roles). ---
$turn0 = $lines[0] | ConvertFrom-Json -Depth 20
$turn1 = $lines[1] | ConvertFrom-Json -Depth 20
if ($turn0.type -ne 'user' -or [string]$turn0.message.content[0].text -ne $canaryUser) {
    Write-Fail "First turn is not the expected user canary turn: $($lines[0])"
}
if ($turn1.type -ne 'assistant' -or [string]$turn1.message.content[0].text -ne $canaryAgent) {
    Write-Fail "Second turn is not the expected assistant (ATIF 'agent') canary turn: $($lines[1])"
}
Write-Pass "ATIF 'agent' source maps to the parser's 'assistant' role; 'user' stays user"

# --- Test 3: the UNCHANGED parser consumes the normalized JSONL line-by-line. ---
$parsedTurns = New-Object System.Collections.Generic.List[object]
foreach ($l in $lines) {
    $tn = Get-SpecrewConversationTurnFromLine -Line $l
    if ($null -ne $tn) { $parsedTurns.Add($tn) | Out-Null }
}
if ($parsedTurns.Count -ne 2) {
    Write-Fail "Unchanged parser read $($parsedTurns.Count) turns from the normalized JSONL; expected 2."
}
if ([string]$parsedTurns[0].role -ne 'user' -or [string]$parsedTurns[0].text -ne $canaryUser) {
    Write-Fail "Parser did not read the user canary turn correctly: role='$($parsedTurns[0].role)' text='$($parsedTurns[0].text)'"
}
if ([string]$parsedTurns[1].role -ne 'assistant' -or [string]$parsedTurns[1].text -ne $canaryAgent) {
    Write-Fail "Parser did not read the assistant canary turn correctly: role='$($parsedTurns[1].role)' text='$($parsedTurns[1].text)'"
}
Write-Pass 'UNCHANGED parser Get-SpecrewConversationTurnFromLine reads both normalized turns with correct role+text'

# --- Test 4: the full parser tail render (Get-SpecrewConversationTail) consumes a normalized file
#     and surfaces both turns — reproduces the spike UNCHANGED_PARSER_CAPTURE_PASS end-to-end. ---
$scratch = Join-Path $repoRoot ('.scratch\devin-handover-' + [guid]::NewGuid().ToString('N'))
try {
    New-Item -ItemType Directory -Path $scratch -Force | Out-Null
    $normalizedFile = Join-Path $scratch 'normalized.jsonl'
    [System.IO.File]::WriteAllText($normalizedFile, $jsonl, [System.Text.UTF8Encoding]::new($false))

    $tail = Get-SpecrewConversationTail -HostKind 'devin' -TranscriptPath $normalizedFile
    if ([string]::IsNullOrWhiteSpace($tail)) { Write-Fail 'Get-SpecrewConversationTail returned empty for the normalized transcript.' }
    if ($tail -notmatch [regex]::Escape($canaryUser)) { Write-Fail "Tail render is missing the user canary turn:`n$tail" }
    if ($tail -notmatch [regex]::Escape($canaryAgent)) { Write-Fail "Tail render is missing the assistant canary turn:`n$tail" }
    if ($tail -match '(?i)not recognized') { Write-Fail "Tail render fell back to the unrecognized-schema (Tier-2) note; the parser did not structurally read the normalized shape:`n$tail" }
    Write-Pass 'UNCHANGED parser tail render (Get-SpecrewConversationTail) surfaces both Devin canary turns (UNCHANGED_PARSER_CAPTURE_PASS reproduced)'
}
finally {
    if (Test-Path -LiteralPath $scratch) { Remove-Item -LiteralPath $scratch -Recurse -Force -ErrorAction SilentlyContinue }
}

# --- Test 5: determinism — repeated normalization of the same input is byte-stable. ---
$run1 = ConvertFrom-DevinAtifToParserJsonl -Atif $atifText
$run2 = ConvertFrom-DevinAtifToParserJsonl -Atif $atifText
if ($run1 -cne $run2) {
    Write-Fail "Normalizer is not byte-stable across runs.`nRun1: $run1`nRun2: $run2"
}
# Also stable when fed an already-parsed object vs the raw string (same canonical output).
$run3 = ConvertFrom-DevinAtifToParserJsonl -Atif ($atifText | ConvertFrom-Json -Depth 40)
if ($run3 -cne $run1) {
    Write-Fail "Normalizer output differs between string input and parsed-object input.`nString: $run1`nObject: $run3"
}
Write-Pass 'Normalizer is byte-stable across repeated runs and across string vs parsed-object input'

# --- Test 6: tool/non-conversational steps are skipped (no tool noise in the handover). ---
$noisyAtif = @'
{"atif_version":"1.7","steps":[
  {"source":"user","message":"hello"},
  {"source":"agent","message":{"tool":"shell","input":"ls"}},
  {"source":"system","message":"session started"},
  {"source":"agent","message":"world"}
]}
'@
$noisyJsonl = ConvertFrom-DevinAtifToParserJsonl -Atif $noisyAtif
$noisyLines = @($noisyJsonl -split "`n" | Where-Object { -not [string]::IsNullOrWhiteSpace($_) })
if ($noisyLines.Count -ne 2) {
    Write-Fail "Expected 2 conversational turns after skipping tool/system/structured steps; got $($noisyLines.Count): $noisyJsonl"
}
Write-Pass 'Non-conversational steps (structured tool payload, system role) are skipped; only user/agent string turns are emitted'

Write-Host "`nDevin handover normalizer: all assertions pass" -ForegroundColor Green
exit 0
