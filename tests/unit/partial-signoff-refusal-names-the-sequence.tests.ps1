# Iteration 002 (DRIFT-199-I002-033/-034): a refusal a human cannot act on is an unrecoverable stop.
#
# MEASURED, 2026-08-30. The maintainer typed a valid partial-signoff approval THREE times and signoff
# refused three times. The phrase was never wrong. What was wrong, in order:
#   attempt 1 - a records commit under specs/** moved the reviewed-state digest between the request being
#               written and the retry, so the approval was bound to a state that no longer existed;
#   attempt 2 - the same, because the agent committed the drift entries describing attempt 1;
#   attempt 3 - the approval was captured as "everything from the dash to end of message", which included
#               two further instruction paragraphs, exceeded the 2000-character rationale cap, and was
#               DISCARDED IN SILENCE.
# The gate said `latest-result-not-current` every time: true, unrelated to what went wrong, and with no
# reachable action in it. A tester who hits this is stuck rather than inconvenienced.
#
# This suite pins the message that makes it recoverable. It is the message-side half only; the durable
# fixes (extend W77's records-delta carry to every acceptance kind; bound the rationale to its own
# paragraph; never drop a matched phrase in silence) are recorded as beta4 items.
#
# Mutations that turn this file red: drop any of the three ordered steps; drop the no-commits-between
# warning; drop the whole-message instruction.
Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'
$repoRoot = (Resolve-Path (Join-Path $PSScriptRoot '..\..')).Path
$script:failCount = 0
function Write-Pass { param([string]$Message) Write-Host "PASS: $Message" -ForegroundColor Green }
function Write-Fail { param([string]$Message) Write-Host "FAIL: $Message" -ForegroundColor Red; $script:failCount++ }
function Assert-True { param([bool]$Condition, [string]$Message) if ($Condition) { Write-Pass $Message } else { Write-Fail $Message } }

# The message is composed inside the gate wiring's block branch and is not reachable as a function, so this
# asserts on the composed literal. Labelled as a source-shape check, as the sibling guard is.
$wiring = Get-Content -LiteralPath (Join-Path $repoRoot 'scripts\internal\continuous-co-review\signoff-gate-wiring.ps1') -Raw -Encoding UTF8
Write-Host 'Case 1: the refusal names the ORDERED sequence, not only the phrase'
Assert-True ($wiring -match 'If you intentionally accept partial coverage for this exact tree') 'the partial-coverage message is composed in the gate wiring'
$body = $wiring
Assert-True ($body -match '\(1\)' -and $body -match '\(2\)' -and $body -match '\(3\)') 'it gives three numbered steps rather than a single instruction'
Assert-True ($body -match 'run this same command once') 'step 1 is REFRESHING the pending request - the clause no user would guess'
Assert-True ($body -match 'approved for partial review signoff') 'step 2 is the phrase itself'
Assert-True ($body -match 'run this same command again immediately') 'step 3 is the retry'

Write-Host 'Case 2: it warns about the thing that actually invalidated three approvals'
Assert-True ($body -match 'NO commits anywhere between them') 'the no-commits window is stated as a condition of the sequence'
Assert-True ($body -match 'drift entry' -or $body -match 'plan note') 'and names the concrete act that does it - writing records, which a signoff requires'
Assert-True ($body -match 'not a rejection of your reasoning') 'it tells the human a repeat refusal is not a verdict on their rationale'

Write-Host 'Case 3: it states the whole-message constraint that silently ate the third approval'
Assert-True ($body -match 'WHOLE message') 'the approval must be the whole message'
Assert-True ($body -match 'nothing after it') 'and nothing may follow it'

Write-Host 'Case 4: an approval binding is explained, not merely asserted'
Assert-True ($body -match 'binds to a specific state') 'the message says WHY a stale request refuses, so the sequence is understandable rather than ritual'

if ($script:failCount -gt 0) { throw ("partial-signoff-refusal-names-the-sequence: {0} assertion(s) failed" -f $script:failCount) }
Write-Host 'partial-signoff-refusal-names-the-sequence: all assertions passed' -ForegroundColor Green
