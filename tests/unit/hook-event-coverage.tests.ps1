# Iteration 002, round-3 follow-up (DRIFT-199-I002-025): aggregate liveness is not per-event arrival.
#
# THE MOTIVATING DIAGNOSIS WAS RETRACTED; THE GAP IS NOT. This suite was first written on a report that a
# host had stopped firing `UserPromptSubmit`. The maintainer retracted that the same day - a fresh project
# on the same Codex CLI 0.151.0 minted a `source_event: UserPromptSubmit` receipt, so there is no
# host-level event regression and the one project's cause is unknown (DRIFT-199-I002-025). No assertion
# here claims anything about any host's behaviour.
#
# What the suite pins is the gap itself, which is independent of that story: hook health classifies
# AGGREGATE liveness, checks REGISTRATION per event, and checks ARRIVAL for SessionStart only - so a
# declared event that never produced a receipt is invisible to it. Registered is not fired.
#
# BOTH SETS ARE ALREADY COMPUTABLE AND NOTHING COMPARED THEM - the same shape as the FileList omission:
#   declared: the host manifest's RefocusHookBindings Registrations
#   observed: the receipt store, keyed per (host, surface, event) as <host>-<surface>-<event>.json
# A guard covering less than its name claims: `hook_status` answers "is there a fresh, well-formed
# receipt", which is a different question from "has every declared event produced one".
#
# Mutations that turn this file red: make Get-SpecrewHookEventCoverage ignore the declared set; make it
# report complete without comparing; drop prompt_capture_silent; weaken the refusal so it stops naming the
# missing event or stops offering a host other than the one the reader is on.
Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'
$repoRoot = (Resolve-Path (Join-Path $PSScriptRoot '..\..')).Path
. (Join-Path $repoRoot 'scripts\internal\specrew-hook-health.ps1')
. (Join-Path $repoRoot 'scripts\internal\continuous-co-review\hook-health-receipt.ps1')
$script:failCount = 0
function Write-Pass { param([string]$Message) Write-Host "PASS: $Message" -ForegroundColor Green }
function Write-Fail { param([string]$Message) Write-Host "FAIL: $Message" -ForegroundColor Red; $script:failCount++ }
function Assert-True { param([bool]$Condition, [string]$Message) if ($Condition) { Write-Pass $Message } else { Write-Fail $Message } }

function New-CoverageFixture {
    param([string[]]$Receipts)
    $root = [System.IO.Path]::GetFullPath((Join-Path ([System.IO.Path]::GetTempPath()) ("hookcov-{0}" -f [guid]::NewGuid().ToString('N').Substring(0, 10))))
    $store = Join-Path $root '.specrew/runtime/hook-health'
    New-Item -ItemType Directory -Force -Path $store | Out-Null
    foreach ($name in @($Receipts)) {
        Set-Content -LiteralPath (Join-Path $store ($name + '.json')) -Value '{"schema_version":"3"}' -Encoding UTF8
    }
    return $root
}

Write-Host 'Case 1: a declared event with no receipt is named, not averaged away'
$f1 = New-CoverageFixture -Receipts @('codex-cli-sessionstart', 'codex-cli-stop')
$c1 = Get-SpecrewHookEventCoverage -ProjectRoot $f1 -HostKind 'codex'
Assert-True ($c1.determinable) 'the declared event set resolved, so the comparison means something'
Assert-True (@($c1.declared_events) -contains 'UserPromptSubmit') 'UserPromptSubmit is DECLARED for this host'
Assert-True (@($c1.missing_events) -contains 'UserPromptSubmit') 'and with no receipt for it, it is reported MISSING - the comparison nothing was making'
Assert-True (-not $c1.complete) 'coverage is not complete - the fact an aggregate liveness verdict cannot express'
Assert-True ($c1.prompt_capture_silent) 'the typed-capture path is flagged silent even though Stop is alive - Stop firing is not evidence that a typed reply can be recorded'

Write-Host 'Case 2: a fully wired host reports complete, so the guard cannot just always complain'
$f2 = New-CoverageFixture -Receipts @('codex-cli-sessionstart', 'codex-cli-userpromptsubmit', 'codex-cli-stop')
$c2 = Get-SpecrewHookEventCoverage -ProjectRoot $f2 -HostKind 'codex'
Assert-True ($c2.complete) 'every declared event has a receipt'
Assert-True (@($c2.missing_events).Count -eq 0) 'nothing is reported missing'
Assert-True (-not $c2.prompt_capture_silent) 'and the typed-capture path is not flagged'

Write-Host 'Case 3: no receipts at all is UNDETERMINED for capture, not a false all-clear'
$f3 = New-CoverageFixture -Receipts @()
$c3 = Get-SpecrewHookEventCoverage -ProjectRoot $f3 -HostKind 'codex'
Assert-True (-not $c3.complete) 'a project with no receipts is not complete'
Assert-True (@($c3.missing_events) -contains 'UserPromptSubmit') 'and every declared event is named as missing rather than assumed fine'

Write-Host 'Case 4: an unresolvable host declares nothing, and must NOT manufacture a refusal from that'
# Absence of a declaration is not evidence of absence of firing - the same absent-versus-unverifiable
# distinction the preflight owed-artifact check was missing (DRIFT-199-I002-023).
$c4 = Get-SpecrewHookEventCoverage -ProjectRoot $f1 -HostKind 'not-a-real-host'
Assert-True (-not $c4.determinable) 'nothing was declared, so nothing is determinable'
Assert-True (-not $c4.complete) 'and completeness is not claimed either - unknown is reported as unknown'

Write-Host 'Case 5: the refusal is state-aware - it does not send the reader to the host they are already on'
$refusal = Get-SpecrewHookEventCoverageRefusal -Coverage $c1
Assert-True ($refusal -match 'UserPromptSubmit') 'it names the declared event that has no receipt'
Assert-True ($refusal -match "on 'codex'") 'it names the host the reader is actually on'
Assert-True ($refusal -notmatch 'through the verified Codex CLI' -and $refusal -notmatch 'open this project through') 'it does NOT advise opening the project on the host it is already running on - unreachable-from-current-state advice, DRIFT-199-I002-026'
Assert-True ($refusal -match 'answers are safe') 'it says the human''s work is safe'
Assert-True ($refusal -match "host's behaviour, not something this project can repair") 'and it does not assert that Specrew is broken - it reports its own missing evidence and does not diagnose a cause it cannot establish'
Assert-True ($refusal -match 'continue this feature on a host whose capture path is live') 'it gives ONE action, reachable from where the reader actually is'

Write-Host 'Case 6: the guard is WIRED - a production health result carries the comparison and the report shows it'
# Round 3 found this helper with ZERO production callers. An absent guard is honest; a dead one is a false
# negative waiting for someone to trust it, which is the "a guard whose name overstates it retires the
# question" problem in its purest form. These assertions fail if it is ever unwired again.
$live = Resolve-SpecrewHookHealth -ProjectRoot $f1 -HostName 'codex' -Surface 'cli'
Assert-True ($null -ne $live.PSObject.Properties['missing_events']) 'the health result carries per-event coverage, so the comparison reaches production'
Assert-True (@($live.missing_events) -contains 'UserPromptSubmit') 'and names the declared event that produced no receipt'
Assert-True ([bool]$live.prompt_capture_silent) 'and flags that a typed approval cannot be recorded in this state'
$report = Format-SpecrewHookHealthReport -Rows @($live)
Assert-True ($report -match 'PER-EVENT COVERAGE') 'the human-facing report SHOWS it - a computed field nobody renders is the same defect one layer up'
Assert-True ($report -match 'UserPromptSubmit') 'naming the missing event'
Assert-True ($report -match 'Registered is not fired') 'and stating the distinction that made it invisible'

foreach ($f in @($f1, $f2, $f3)) { try { Remove-Item -LiteralPath $f -Recurse -Force -ErrorAction SilentlyContinue } catch { $null = $_ } }
if ($script:failCount -gt 0) { throw ("hook-event-coverage: {0} assertion(s) failed" -f $script:failCount) }
Write-Host 'hook-event-coverage: all assertions passed' -ForegroundColor Green
