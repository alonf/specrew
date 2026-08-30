# Iteration 002 (DRIFT-199-I002-034): a human authorization that is rejected must never vanish.
#
# MEASURED, 2026-08-30. A maintainer typed a valid partial-signoff approval three times and signoff refused
# three times; the phrase was never wrong. The third attempt was discarded here: the rationale group is read
# with `(?is)` and no `m`, so it is EVERYTHING from the dash to the end of the message rather than the
# sentence attached to the phrase. That approval carried two further instruction paragraphs, measured 2193
# characters, exceeded the 2000 cap, and `return $null` said nothing at all. The gate then reported
# `latest-result-not-current` - true, and about something else - so the human retyped a correct phrase twice.
#
# The rule this pins: a phrase that did NOT match stays silent (that is ordinary conversation); a phrase
# that DID match and was then rejected must say so AND say what to do. The replacement for a silent drop
# has to meet the standard that found it.
#
# Mutations that turn this file red: restore any bare `return $null` after the phrase matches; drop the
# retype instruction; drop the whole-message instruction; make a non-matching message emit a diagnostic.
Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'
$repoRoot = (Resolve-Path (Join-Path $PSScriptRoot '..\..')).Path
. (Join-Path $repoRoot 'scripts\internal\bootstrap\HumanAuthorityStore.ps1')
$script:failCount = 0
function Write-Pass { param([string]$Message) Write-Host "PASS: $Message" -ForegroundColor Green }
function Write-Fail { param([string]$Message) Write-Host "FAIL: $Message" -ForegroundColor Red; $script:failCount++ }
function Assert-True { param([bool]$Condition, [string]$Message) if ($Condition) { Write-Pass $Message } else { Write-Fail $Message } }

function New-CaptureRoot {
    $root = [System.IO.Path]::GetFullPath((Join-Path ([System.IO.Path]::GetTempPath()) ("authcap-{0}" -f [guid]::NewGuid().ToString('N').Substring(0, 10))))
    New-Item -ItemType Directory -Force -Path (Join-Path $root '.specrew/runtime') | Out-Null
    return $root
}
# The diagnostic goes to stderr, which is where a hook's human-visible output belongs. Capture it by
# running the call in a child process, so this asserts on what a human would actually see.
function Invoke-Capture {
    param([string]$Root, [string]$Response)
    $module = (Join-Path $repoRoot 'scripts\internal\bootstrap\HumanAuthorityStore.ps1')
    $encoded = [Convert]::ToBase64String([Text.Encoding]::UTF8.GetBytes($Response))
    $command = @"
Set-StrictMode -Version Latest
`$ErrorActionPreference = 'Continue'
. '$module'
`$r = [Text.Encoding]::UTF8.GetString([Convert]::FromBase64String('$encoded'))
`$null = Write-SpecrewReviewSignoffOverrideAuthorization -ProjectRoot '$Root' -Response `$r -HostKind 'claude' -SourceEvent 'UserPromptSubmit'
"@
    return ((& pwsh -NoProfile -Command $command 2>&1) | ForEach-Object { [string]$_ }) -join ' '
}

$longReason = ('the uncovered delta is round three own output and not new scope. ' * 40)   # > 2000 chars

Write-Host 'Case 1: THE FIELD CASE - an over-length rationale is reported, not swallowed'
$r1 = New-CaptureRoot
$out1 = Invoke-Capture -Root $r1 -Response ("approved for partial review signoff - " + $longReason)
Assert-True ($out1 -match 'YOUR APPROVAL WAS NOT RECORDED') 'the human is told their approval did not land'
Assert-True ($out1 -match 'too long') 'and why - the rationale length, which is the actual cause'
Assert-True ($out1 -match 'everything after the dash counts') 'including the part nobody would guess: text further down the same message counts toward it'
Assert-True ($out1 -match 'WHOLE message') 'the retype instruction says to send it as the whole message'
Assert-True ($out1 -match 'nothing after it') 'with nothing after it'
Assert-True ($out1 -match 'Nothing is wrong with your decision') 'and it does not read as a rejection of their judgement'

Write-Host 'Case 2: the drop is journalled, so an absence is never unexplained after the fact'
$dropJournal = Join-Path $r1 '.specrew/runtime/authority-capture-drops.jsonl'
Assert-True (Test-Path -LiteralPath $dropJournal -PathType Leaf) 'a durable trace exists - every fail-soft owes one'
$entry = (Get-Content -LiteralPath $dropJournal -Raw -Encoding UTF8 | ConvertFrom-Json)
Assert-True ([string]$entry.reason -eq 'rationale-too-long') 'the trace names the reason'
Assert-True ([int]$entry.rationale_length -gt 2000) 'and records the measurement that caused it'

Write-Host 'Case 3: a too-short rationale is reported too, with its own number'
$r3 = New-CaptureRoot
$out3 = Invoke-Capture -Root $r3 -Response 'approved for partial review signoff - ok'
Assert-True ($out3 -match 'YOUR APPROVAL WAS NOT RECORDED') 'the human is told'
Assert-True ($out3 -match 'too short') 'and given the opposite reason'

Write-Host 'Case 4: a matched phrase with nothing outstanding also speaks'
$r4 = New-CaptureRoot
$out4 = Invoke-Capture -Root $r4 -Response 'approved for partial review signoff - the delta is the review round own output and carries mutation proof'
Assert-True ($out4 -match 'YOUR APPROVAL WAS NOT RECORDED') 'a valid phrase with no outstanding request does not vanish either'
Assert-True ($out4 -match 'nothing for it to authorize') 'and the reason is the absence of a request, not the phrase'

Write-Host 'Case 5: ordinary conversation stays silent - the fix must not make every message a diagnostic'
$r5 = New-CaptureRoot
$out5 = Invoke-Capture -Root $r5 -Response 'Looks good, please proceed with the retro when you are ready.'
Assert-True ($out5 -notmatch 'YOUR APPROVAL WAS NOT RECORDED') 'a message that never matched the phrase produces no diagnostic'

foreach ($r in @($r1, $r3, $r4, $r5)) { try { Remove-Item -LiteralPath $r -Recurse -Force -ErrorAction SilentlyContinue } catch { $null = $_ } }
if ($script:failCount -gt 0) { throw ("authority-capture-never-drops-silently: {0} assertion(s) failed" -f $script:failCount) }
Write-Host 'authority-capture-never-drops-silently: all assertions passed' -ForegroundColor Green
