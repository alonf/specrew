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
        session_state = [ordered]@{ active = $true; boundary_type = 'before-implement'; feature_ref = '001-feat'; host = 'claude'; iteration_number = '001'; auth_commit_hash = $head; recorded_at = '2026-08-29T00:00:00Z' }
        boundary_enforcement = [ordered]@{ enabled = $true; last_authorized_boundary = 'tasks'; pending_next_boundary = $null; verdict_history = @(); bypass_history = @() }
    }
    [System.IO.File]::WriteAllText((Join-Path $root '.specrew/start-context.json'), ($ctx | ConvertTo-Json -Depth 12), [System.Text.UTF8Encoding]::new($false))
    $null = Set-SpecrewPendingBoundaryCrossingScope -ProjectRoot $root -WorkingBoundary 'before-implement' -BoundaryCommitHash $head -RecordedAt '2026-08-29T00:00:01Z'
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

foreach ($f in @($f1, $f2, $f3, $f4, $f5)) { try { Remove-Item -LiteralPath $f.Root -Recurse -Force -ErrorAction SilentlyContinue } catch { $null = $_ } }
if ($script:failCount -gt 0) { throw ("capture-disclosure: {0} assertion(s) failed" -f $script:failCount) }
Write-Host 'capture-disclosure: all assertions passed' -ForegroundColor Green
