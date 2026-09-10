# Iteration 002, T024 (FR-010, SC-020): a verdict-shaped reply that did not capture SAYS SO, at prompt entry.
#
# Measured twice on 2026-08-29, both the maintainer's own text, both costing a retry (DRIFT-199-I002-004):
#   * a leading terminal quote bar before `approved for iteration-closeout`
#   * four paragraphs of prose before `approved for plan`
# In both, the leading text - not the phrase - decided the classification, and NOTHING said so until the
# agent happened to run a read-only check. The fix's real target is that "bare phrase first" means the first
# characters of the MESSAGE, not the first of the verdict lines, which a careful reader has no way to know.
#
# DRIFT-199-I002-008 measured where this belongs: the capture already runs at UserPromptSubmit on this host
# and wrote three of that day's five verdicts before the session's first tool call. So the disclosure fires
# THERE, in the same turn the human typed it, and reaches the turn through the handover provider's inject
# stdout.
#
# The recognizer is NOT widened: every case below still ends with the crossing un-authorized.
# PRED-BETA4-022 (cases 6-7): the phrase on line one with a transcript under it is refused BY REASON and the
# disclosure names the one-line retype - both the boundary path and the typed-authority path, in the turn.
# Mutations that turn this file red: remove the disclosure call from the prompt-submit branch (cases 1-3);
# remove the Write-Output from the provider (case 4); widen the trigger so it fires without the phrase (5).
Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'
$repoRoot = (Resolve-Path (Join-Path $PSScriptRoot '..\..')).Path
. (Join-Path $repoRoot 'extensions\specrew-speckit\scripts\shared-governance.ps1')
Get-ChildItem (Join-Path $repoRoot 'scripts\internal\bootstrap\*.ps1') | ForEach-Object { . $_.FullName }
$provider = (Join-Path $repoRoot 'scripts\internal\specrew-handover-provider.ps1')
$script:failCount = 0
function Write-Pass { param([string]$Message) Write-Host "PASS: $Message" -ForegroundColor Green }
function Write-Fail { param([string]$Message) Write-Host "FAIL: $Message" -ForegroundColor Red; $script:failCount++ }
function Assert-True { param([bool]$Condition, [string]$Message) if ($Condition) { Write-Pass $Message } else { Write-Fail $Message } }

function New-DisclosureFixture {
    param([switch]$NoPendingCrossing)
    $root = [System.IO.Path]::GetFullPath((Join-Path ([System.IO.Path]::GetTempPath()) ("disclose-{0}" -f [guid]::NewGuid().ToString('N').Substring(0, 10))))
    $feature = [System.IO.Path]::GetFullPath((Join-Path $root (Join-Path 'specs' '001-feat')))
    $iter = [System.IO.Path]::GetFullPath((Join-Path $feature (Join-Path 'iterations' '001')))
    New-Item -ItemType Directory -Force -Path (Join-Path $root '.specrew/runtime') | Out-Null
    New-Item -ItemType Directory -Force -Path (Join-Path $iter 'quality') | Out-Null
    Set-Content -LiteralPath (Join-Path $feature 'spec.md') -Value "# Feature Specification: Feat`n`nBody." -Encoding UTF8
    Set-Content -LiteralPath (Join-Path $iter 'plan.md') -Value "# Iteration Plan: 001`n`n**Status**: planning" -Encoding UTF8
    Set-Content -LiteralPath (Join-Path $iter 'state.md') -Value "# Iteration State: 001`n`n**Current Phase**: tasks" -Encoding UTF8
    Set-Content -LiteralPath (Join-Path $iter 'quality/hardening-gate.md') -Value "# Hardening Gate`n`n**Overall Verdict**: ready" -Encoding UTF8
    Set-Content -LiteralPath (Join-Path $root '.gitignore') -Value ".specrew/`n" -Encoding UTF8
    & git -C $root init -q -b main
    & git -C $root config user.email 't@t'
    & git -C $root config user.name 't'
    & git -C $root add -A
    & git -C $root commit -q -m fixture
    $head = ([string](& git -C $root rev-parse HEAD)).Trim()
    $ctx = [ordered]@{
        schema = 'v2'
        feature_path = $feature
        # -NoPendingCrossing is the router-skill shape: the cursor still AT the last authorized boundary, the
        # next boundary's sync not yet run - so no crossing is derivable, scoped or legacy.
        session_state = [ordered]@{ active = $true; boundary_type = $(if ($NoPendingCrossing) { 'tasks' } else { 'before-implement' }); feature_ref = '001-feat'; host = 'claude'; iteration_number = '001'; auth_commit_hash = $head; recorded_at = '2026-08-29T00:00:00Z' }
        boundary_enforcement = [ordered]@{ enabled = $true; last_authorized_boundary = 'tasks'; pending_next_boundary = $null; verdict_history = @(); bypass_history = @() }
    }
    [System.IO.File]::WriteAllText((Join-Path $root '.specrew/start-context.json'), ($ctx | ConvertTo-Json -Depth 12), [System.Text.UTF8Encoding]::new($false))
    if (-not $NoPendingCrossing) {
        $null = Set-SpecrewPendingBoundaryCrossingScope -ProjectRoot $root -WorkingBoundary 'before-implement' -BoundaryCommitHash $head -RecordedAt '2026-08-29T00:00:01Z'
    }
    return [pscustomobject]@{ Root = $root; Head = $head }
}
function Read-Enforcement { param([string]$Root) return (Get-Content -LiteralPath (Join-Path $Root '.specrew/start-context.json') -Raw -Encoding UTF8 | ConvertFrom-Json -Depth 12).boundary_enforcement }
function Read-Journal { param([string]$Root, [string]$Event)
    $p = Join-Path $Root '.specrew/runtime/handover-journal.jsonl'
    if (-not (Test-Path -LiteralPath $p)) { return @() }
    return @(Get-Content -LiteralPath $p -Encoding UTF8 | ForEach-Object { $_ | ConvertFrom-Json } | Where-Object { $_.event -eq $Event })
}

# ---------------------------------------------------------------------------------------------------
Write-Host 'Case 1: the maintainer''s FIRST instance - a leading terminal quote bar'
$f1 = New-DisclosureFixture
$barText = ([char]0x258E) + " approved for before-implement - one correction to the gate and two answers."
$d1 = Get-SpecrewVerdictCaptureDisclosure -ProjectRoot $f1.Root -HumanText $barText -NowUtc '2026-08-29T00:00:02Z' -Source 'UserPromptSubmit'
Assert-True (-not [string]::IsNullOrWhiteSpace($d1)) 'the quote-bar turn produces a disclosure instead of silence'
Assert-True ($d1 -match 'NOT recorded as a verdict' -and $d1 -match "tasks -> before-implement") 'it names what did not happen and which crossing'
Assert-True ($d1 -match 'comes before the phrase') 'it names the leading text that decided the classification'
Assert-True ($d1 -match 'FIRST characters are: approved for before-implement') 'it names the one reachable action, with the phrase position spelled out'
Assert-True ($d1 -match 'Nothing you wrote is lost and no approval was changed') 'it reassures: the human''s work is safe'
$j1 = @(Read-Journal -Root $f1.Root -Event 'verdict-not-captured-disclosed')
Assert-True ($j1.Count -eq 1 -and [string]$j1[0].to -eq 'before-implement') 'the non-capture is journaled, so it is diagnosable after the fact'

Write-Host 'Case 2: the SECOND instance - four paragraphs of prose before the phrase'
$f2 = New-DisclosureFixture
$proseText = "Don't confirm prompt 1's map as written - it would ship the TB-4 defect inside the fix for TB-8.`n`nVerified against source.`n`napproved for before-implement - three instructions."
$d2 = Get-SpecrewVerdictCaptureDisclosure -ProjectRoot $f2.Root -HumanText $proseText -NowUtc '2026-08-29T00:00:02Z' -Source 'UserPromptSubmit'
Assert-True (-not [string]::IsNullOrWhiteSpace($d2)) 'the leading-prose turn produces a disclosure'
Assert-True ($d2 -match "Don't confirm prompt 1") 'it quotes the leading text back, so the human can see exactly what decided it'
Assert-True ($d2 -match 'not by the first of the verdict lines') 'it names the distinction a careful reader cannot otherwise know'

Write-Host 'Case 3: a clean verdict discloses NOTHING (the disclosure is for silence, not for success)'
$f3 = New-DisclosureFixture
$d3 = Get-SpecrewVerdictCaptureDisclosure -ProjectRoot $f3.Root -HumanText 'approved for before-implement' -NowUtc '2026-08-29T00:00:02Z' -Source 'UserPromptSubmit'
Assert-True ([string]::IsNullOrWhiteSpace($d3)) 'a leading approval phrase produces no disclosure'
$d3b = Get-SpecrewVerdictCaptureDisclosure -ProjectRoot $f3.Root -HumanText 'What is the status of the tests directory?' -NowUtc '2026-08-29T00:00:02Z' -Source 'UserPromptSubmit'
Assert-True ([string]::IsNullOrWhiteSpace($d3b)) 'ordinary conversation produces no disclosure - the trigger is narrow by construction'
$d3c = Get-SpecrewVerdictCaptureDisclosure -ProjectRoot $f3.Root -HumanText 'changes needed: rework the plan table' -NowUtc '2026-08-29T00:00:02Z' -Source 'UserPromptSubmit'
Assert-True ([string]::IsNullOrWhiteSpace($d3c)) 'a send-back without the phrase produces no disclosure - it is not a missed verdict'

Write-Host 'Case 4: end to end - the provider surfaces the disclosure into the turn, and captures nothing'
$f4 = New-DisclosureFixture
$before4 = (Read-Enforcement -Root $f4.Root).last_authorized_boundary
$out4 = ((& pwsh -NoProfile -File $provider --project-root $f4.Root --host-kind claude --source-event UserPromptSubmit --last-user-message $barText 2>&1) -join "`n")
$after4 = (Read-Enforcement -Root $f4.Root).last_authorized_boundary
Assert-True ($out4 -match 'NOT recorded as a verdict' -and $out4 -match 'FIRST characters are: approved for before-implement') 'the provider writes the disclosure to its inject stdout, so it reaches the same turn'
Assert-True ([string]$before4 -eq 'tasks' -and [string]$after4 -eq 'tasks') 'and the recognizer is NOT widened: the crossing stays un-authorized'

Write-Host 'Case 5: the same provider path with a clean verdict captures, and says nothing extra'
$f5 = New-DisclosureFixture
$out5 = ((& pwsh -NoProfile -File $provider --project-root $f5.Root --host-kind claude --source-event UserPromptSubmit --last-user-message 'approved for before-implement' 2>&1) -join "`n")
$after5 = (Read-Enforcement -Root $f5.Root).last_authorized_boundary
Assert-True ([string]$after5 -eq 'before-implement') 'a clean phrase at prompt entry authorizes the crossing (the path this disclosure sits beside)'
Assert-True ($out5 -notmatch 'NOT recorded as a verdict') 'and nothing is disclosed when there is nothing to disclose'

Write-Host 'Case 6 (PRED-BETA4-022): the phrase on line one and a transcript under it - refused BY REASON, and the disclosure names the one-line retype'
$f6 = New-DisclosureFixture
$pasteLines = [System.Collections.Generic.List[string]]::new()
$pasteLines.Add('approved for before-implement'); $pasteLines.Add('Thought for 1s'); $pasteLines.Add('')
$pasteLines.Add("I'll run the approved round against the iteration 002 planning artifacts.")
1..40 | ForEach-Object { $pasteLines.Add(('PS> pwsh -File scripts/specrew-review.ps1 --live   # attempt {0}: exit 1' -f $_)) }
$pasteText = ($pasteLines -join "`n")
$d6 = Get-SpecrewVerdictCaptureDisclosure -ProjectRoot $f6.Root -HumanText $pasteText -NowUtc '2026-09-10T18:28:54Z' -Source 'UserPromptSubmit'
Assert-True (-not [string]::IsNullOrWhiteSpace($d6)) 'the pasted-transcript turn produces a disclosure instead of silence'
Assert-True ($d6 -match 'NOT recorded as a verdict' -and $d6 -match 'tasks -> before-implement') 'it names what did not happen and which crossing'
Assert-True ($d6 -match 'a verdict is ONE line') 'it names the rule, not a code word'
Assert-True ($d6 -match "exactly one line: 'approved for before-implement' or 'approved for before-implement - <your instructions>'") 'it names the one reachable action: the same-line form'
Assert-True ($d6 -notmatch 'what comes FIRST in the message') 'and it does NOT blame the first line, which was right - the diagnosis is the continuation'
$j6 = @(Read-Journal -Root $f6.Root -Event 'verdict-not-captured-disclosed')
Assert-True ($j6.Count -eq 1 -and [string]$j6[0].action -eq 'refused-multi-line') 'the non-capture is journaled with its reason'
$out6 = ((& pwsh -NoProfile -File $provider --project-root $f6.Root --host-kind claude --source-event UserPromptSubmit --last-user-message $pasteText 2>&1) -join "`n")
$after6 = (Read-Enforcement -Root $f6.Root).last_authorized_boundary
Assert-True ($out6 -match 'a verdict is ONE line') 'the provider puts the disclosure in the turn'
Assert-True ([string]$after6 -eq 'tasks') 'and the crossing stays un-authorized: the paste minted nothing'

Write-Host 'Case 7 (PRED-BETA4-022): a typed ROUND approval with a transcript under it, at prompt entry - disclosed in the turn beside the verdict path'
$f7 = New-DisclosureFixture
$roundPaste = 'approved for review round' + "`n" + (($pasteLines | Select-Object -Skip 1) -join "`n")
$out7 = ((& pwsh -NoProfile -File $provider --project-root $f7.Root --host-kind claude --source-event UserPromptSubmit --last-user-message $roundPaste 2>&1) -join "`n")
Assert-True ($out7 -match 'NOT recorded as a review-round-approval' -and $out7 -match "exactly one line: 'approved for review round'") 'the typed-authority refusal is said in the turn with the retype'
Assert-True (-not (Test-Path -LiteralPath (Join-Path $f7.Root '.specrew/review/round-approval/pending-round-approval.json'))) 'no pending round approval was minted from the paste'
Assert-True ((Test-Path -LiteralPath (Join-Path $f7.Root '.specrew/runtime/authority-capture-drops.jsonl')) -and ((Get-Content -LiteralPath (Join-Path $f7.Root '.specrew/runtime/authority-capture-drops.jsonl') -Raw) -match '"reason":"multi-line"')) 'the drop is journaled where the partial-signoff drops already live'

Write-Host 'Case 8 (PRED-BETA4-026, B4F-043 third instance): a verdict typed with NO crossing pending gets one line back naming that nothing is pending'
$f8 = New-DisclosureFixture -NoPendingCrossing
$d8 = Get-SpecrewVerdictCaptureDisclosure -ProjectRoot $f8.Root -HumanText 'approved for before-implement' -NowUtc '2026-09-11T00:00:00Z' -Source 'UserPromptSubmit'
Assert-True (-not [string]::IsNullOrWhiteSpace($d8)) 'a verdict with no crossing pending produces a disclosure instead of silence (the router-skill''s three retypes)'
Assert-True ($d8 -match 'NO crossing is pending' -and $d8 -match "last authorized boundary is 'tasks'") 'it says nothing is pending and names the last authorized boundary'
Assert-True ($d8 -match 'send the phrase again: approved for before-implement') 'and names the one move: send it again when the crossing is presented'
$j8 = @(Read-Journal -Root $f8.Root -Event 'verdict-not-captured-disclosed')
Assert-True ($j8.Count -eq 1 -and [string]$j8[0].action -eq 'no-pending-crossing' -and [string]$j8[0].to -eq 'before-implement') 'journaled with its reason'
Assert-True ([string](Read-Enforcement -Root $f8.Root).last_authorized_boundary -eq 'tasks') 'and the ledger is unchanged'
$out8 = ((& pwsh -NoProfile -File $provider --project-root $f8.Root --host-kind claude --source-event UserPromptSubmit --last-user-message 'approved for before-implement' 2>&1) -join "`n")
Assert-True ($out8 -match 'NO crossing is pending') 'the provider puts it in the turn'
$d8b = Get-SpecrewVerdictCaptureDisclosure -ProjectRoot $f8.Root -HumanText 'What is the status of the tests directory?' -NowUtc '2026-09-11T00:00:01Z' -Source 'UserPromptSubmit'
Assert-True ([string]::IsNullOrWhiteSpace($d8b)) 'ordinary conversation with nothing pending still discloses nothing'
$d8c = Get-SpecrewVerdictCaptureDisclosure -ProjectRoot $f8.Root -HumanText 'changes needed: rework the plan table' -NowUtc '2026-09-11T00:00:02Z' -Source 'UserPromptSubmit'
Assert-True ([string]::IsNullOrWhiteSpace($d8c)) 'a send-back with nothing pending discloses nothing - it is not a lost approval'

Write-Host 'Case 9 (PRED-BETA4-026): a verdict naming ANOTHER boundary than the pending crossing gets one line back naming the pending one'
$f9 = New-DisclosureFixture
$d9 = Get-SpecrewVerdictCaptureDisclosure -ProjectRoot $f9.Root -HumanText 'approved for plan' -NowUtc '2026-09-11T00:00:03Z' -Source 'UserPromptSubmit'
Assert-True (-not [string]::IsNullOrWhiteSpace($d9)) 'a verdict for the wrong boundary produces a disclosure'
Assert-True ($d9 -match "verdict for 'plan'" -and $d9 -match "pending right now is 'tasks -> before-implement'" -and $d9 -match 'send: approved for before-implement') 'it names the boundary typed, the crossing pending, and the phrase that authorizes it'
$j9 = @(Read-Journal -Root $f9.Root -Event 'verdict-not-captured-disclosed')
Assert-True ($j9.Count -eq 1 -and [string]$j9[0].action -eq 'other-boundary-named') 'journaled with its reason'
Assert-True ([string](Read-Enforcement -Root $f9.Root).last_authorized_boundary -eq 'tasks') 'and the ledger is unchanged'

foreach ($f in @($f1, $f2, $f3, $f4, $f5, $f6, $f7, $f8, $f9)) { try { Remove-Item -LiteralPath $f.Root -Recurse -Force -ErrorAction SilentlyContinue } catch { $null = $_ } }
if ($script:failCount -gt 0) { throw ("capture-disclosure: {0} assertion(s) failed" -f $script:failCount) }
Write-Host 'capture-disclosure: all assertions passed' -ForegroundColor Green
