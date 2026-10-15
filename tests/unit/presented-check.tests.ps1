#requires -Version 7.0
# Feature 202 T007 (FR-012, FR-013, FR-015, SC-003; B4F-100, B4F-106): the Stop checks substance, not formatting.
#
# "The declared draft reached the reply" is checked over its meaning lines - headings, review-target links, the
# question line, the approval line and verdict options, the marker - declared once in turn-end-store.ps1 and
# recorded by declare-turn-end.ps1. The deterministic dials line is filled in by the system at turn start and is
# never demanded at Stop.
#
# Driven through the real conformance provider and the real declare-turn-end.ps1 in temp projects.
#
# Cases:
#   1. The meaning-line set of a packet: every heading, link, question, option and the marker; no prose.
#   2. A reworded conversational draft that keeps its question line: 0 blocks (B4F-100).
#   3. A reworded boundary packet that keeps every meaning line: 0 blocks.
#   4. A dropped verdict option: blocked, and the block names that option.
#   5. A dropped question line with no crossing pending: named, with no demand for an approval line or marker.
#   6. The dials line: supplied once at the first prompt, marked as system output; a reply without it is not
#      blocked (0 human-visible cycles, B4F-106).
#
# RED: run with SPECREW_T007_SCRIPTS_ROOT pointing at the pre-T007 scripts; cases 2, 3 and 6 block there.
Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'
$repoRoot = (Resolve-Path (Join-Path $PSScriptRoot '..\..')).Path
$scriptsRoot = if (-not [string]::IsNullOrWhiteSpace($env:SPECREW_T007_SCRIPTS_ROOT)) { $env:SPECREW_T007_SCRIPTS_ROOT } else { Join-Path $repoRoot 'extensions\specrew-speckit\scripts' }
$provider = Join-Path $scriptsRoot 'specrew-conformance-provider.ps1'
$declare = Join-Path $scriptsRoot 'declare-turn-end.ps1'
. (Join-Path $repoRoot 'extensions\specrew-speckit\scripts\shared-governance.ps1')
Get-ChildItem (Join-Path $repoRoot 'scripts\internal\bootstrap\*.ps1') | ForEach-Object { . $_.FullName }
. (Join-Path $repoRoot 'extensions\specrew-speckit\scripts\turn-end-store.ps1')
$savedModulePath = $env:SPECREW_MODULE_PATH
$savedProfilePath = $env:SPECREW_USER_PROFILE_PATH
$env:SPECREW_MODULE_PATH = $repoRoot
$script:failCount = 0

function Write-Pass { param([string]$Message) Write-Host "PASS: $Message" -ForegroundColor Green }
function Write-Fail { param([string]$Message) Write-Host "FAIL: $Message" -ForegroundColor Red; $script:failCount++ }
function Assert-True { param([bool]$Condition, [string]$Message) if ($Condition) { Write-Pass $Message } else { Write-Fail $Message } }

function New-Project {
    param([switch]$PendingCrossing)
    $root = [System.IO.Path]::GetFullPath((Join-Path ([System.IO.Path]::GetTempPath()) ("t007-{0}" -f [guid]::NewGuid().ToString('N').Substring(0, 10))))
    $feature = Join-Path $root 'specs/001-feat'
    $iter = Join-Path $feature 'iterations/001'
    New-Item -ItemType Directory -Force -Path (Join-Path $root '.specrew/runtime') | Out-Null
    New-Item -ItemType Directory -Force -Path (Join-Path $iter 'quality') | Out-Null
    Set-Content -LiteralPath (Join-Path $feature 'spec.md') -Value "# Feature Specification: Feat`n`nBody." -Encoding UTF8
    Set-Content -LiteralPath (Join-Path $iter 'plan.md') -Value "# Iteration Plan: 001`n`n**Status**: executing" -Encoding UTF8
    Set-Content -LiteralPath (Join-Path $iter 'state.md') -Value "# Iteration State: 001`n`n**Current Phase**: tasks" -Encoding UTF8
    Set-Content -LiteralPath (Join-Path $iter 'quality/hardening-gate.md') -Value "# Hardening Gate`n`n**Overall Verdict**: ready" -Encoding UTF8
    Set-Content -LiteralPath (Join-Path $root '.gitignore') -Value ".specrew/`n" -Encoding UTF8
    & git -C $root init -q -b main
    & git -C $root config user.email 't@t'
    & git -C $root config user.name 't'
    & git -C $root config core.autocrlf false
    & git -C $root add -A
    & git -C $root commit -q -m fixture
    if ($PendingCrossing) {
        $head = ([string](& git -C $root rev-parse HEAD)).Trim()
        $ctx = [ordered]@{
            schema = 'v2'
            feature_path = $feature
            session_state = [ordered]@{ active = $true; boundary_type = 'before-implement'; feature_ref = '001-feat'; host = 'claude'; iteration_number = '001'; auth_commit_hash = $head; recorded_at = '2026-10-14T00:00:00Z' }
            boundary_enforcement = [ordered]@{ enabled = $true; last_authorized_boundary = 'tasks'; pending_next_boundary = $null; verdict_history = @(); bypass_history = @() }
        }
        [System.IO.File]::WriteAllText((Join-Path $root '.specrew/start-context.json'), ($ctx | ConvertTo-Json -Depth 12), [System.Text.UTF8Encoding]::new($false))
        $tree = Get-SpecrewGitArtifactStateId -ProjectRoot $root -BoundaryCommitHash $head
        $scope = New-SpecrewPendingCrossingScope -LastAuthorizedBoundary 'tasks' -WorkingBoundary 'before-implement' -BoundaryCommitHash $head -ArtifactStateId $tree -RecordedAt '2026-10-14T00:00:01Z' -ExistingScope $null
        $st = Get-SpecrewBoundaryEnforcementState -ProjectRoot $root
        $upd = [ordered]@{ enabled = $true; last_authorized_boundary = 'tasks'; pending_next_boundary = [string]$scope['to_boundary']; pending_crossing = $scope; verdict_history = @(); correction_history = @(); bypass_history = @() }
        Set-SpecrewBoundaryEnforcementState -ProjectRoot $root -BoundaryEnforcement $upd -Context $st.Context | Out-Null
        [System.IO.File]::WriteAllText((Join-Path $root '.specrew/runtime/pending-verdict-stop.md'), (@('# Specrew Pending Verdict Stop', '', 'Boundary to ask for: tasks -> before-implement', 'Human approval phrase: approved for before-implement', 'Marker last line exactly:', '<!-- SPECREW-VERDICT-BOUNDARY: tasks -> before-implement -->') -join "`n"), [System.Text.UTF8Encoding]::new($false))
    }
    return [pscustomobject]@{ Root = $root; Spec = (Join-Path $feature 'spec.md'); Iter = $iter }
}

function Get-Packet {
    param($Project, [string]$Opening, [string]$Reason, [switch]$DropDiscuss)
    $specUrl = ([System.Uri]::new($Project.Spec)).AbsoluteUri
    $discuss = if ($DropDiscuss) { '' } else { '  discuss prompt 1' }
    return @"
## What I Just Did

$Opening

## Why I Stopped

$Reason My recommendation: approve.

## What Needs Your Review

The specification: $specUrl

## What Happens Next

Implementation starts with the first task on approval.

## Discussion Prompts

1. Is the task order right?

## What I Need From You

What would you like to do? Type one of these:

  approved for before-implement
  approved for before-implement - <your instructions>
  changes needed: <what to change>
$discuss

<!-- SPECREW-VERDICT-BOUNDARY: tasks -> before-implement -->
"@
}

$script:Turn = 0
function Invoke-Pwsh {
    param([string]$Root, [string]$Script, [string[]]$Arguments)
    Push-Location -LiteralPath $Root
    # The providers write UTF-8; decode their output as UTF-8 whatever the caller's console is (a Git Bash caller's is
    # not, and case 6's em dash then never matched - 202 DRIFT-030).
    $savedEncoding = [Console]::OutputEncoding
    try {
        [Console]::OutputEncoding = [System.Text.UTF8Encoding]::new($false)
        return (@(& pwsh -NoProfile -NonInteractive -ExecutionPolicy Bypass -File $Script @Arguments 2>&1) -join "`n")
    }
    finally { [Console]::OutputEncoding = $savedEncoding; Pop-Location }
}

function Start-Turn {
    param($Project, [string]$Session, [string]$UserText)
    $out = Invoke-Pwsh -Root $Project.Root -Script $provider -Arguments @('--host-kind', 'claude', '--source-event', 'UserPromptSubmit', '--session-id', $Session, '--last-user-message', $UserText, '--turn-origin', 'typed-user')
    $m = [regex]::Match($out, '-Token\s+([0-9a-f]{16,})')
    return [pscustomobject]@{ Token = $(if ($m.Success) { $m.Groups[1].Value } else { '' }); Output = $out }
}

function Complete-Turn {
    # Declares the DRAFT, then shows the host's transcript holding the REPLY - which may differ from the draft.
    param($Project, [string]$Session, [string]$Token, [string]$Kind, [string]$Draft, [string]$Reply)
    $script:Turn++
    $draftPath = Join-Path $Project.Root (".specrew/runtime/draft-{0}.md" -f $script:Turn)
    [System.IO.File]::WriteAllText($draftPath, $Draft, [System.Text.UTF8Encoding]::new($false))
    $null = Invoke-Pwsh -Root $Project.Root -Script $declare -Arguments @('-Kind', $Kind, '-MessagePath', $draftPath, '-Summary', ('turn {0}' -f $script:Turn), '-Token', $Token)
    $transcript = Join-Path $Project.Root (".specrew/runtime/transcript-{0}.jsonl" -f $script:Turn)
    $lines = @(
        ([pscustomobject]@{ type = 'user'; message = [pscustomobject]@{ role = 'user'; content = @([pscustomobject]@{ type = 'text'; text = 'Continue.' }) } } | ConvertTo-Json -Depth 8 -Compress),
        ([pscustomobject]@{ type = 'assistant'; message = [pscustomobject]@{ role = 'assistant'; content = @([pscustomobject]@{ type = 'text'; text = $Reply }) } } | ConvertTo-Json -Depth 8 -Compress)
    )
    [System.IO.File]::WriteAllLines($transcript, [string[]]$lines, [System.Text.UTF8Encoding]::new($false))
    $out = Invoke-Pwsh -Root $Project.Root -Script $provider -Arguments @('--host-kind', 'claude', '--source-event', 'Stop', '--session-id', $Session, '--transcript-path', $transcript)
    return [pscustomobject]@{ Blocked = ($out -match '<<<SPECREW-STOP-BLOCK>>>'); Output = $out }
}

$projects = [System.Collections.Generic.List[object]]::new()
try {
    # -----------------------------------------------------------------------------------------------
    Write-Host 'Case 1: the meaning-line set of a packet'
    $p1 = New-Project; $projects.Add($p1)
    $lines1 = @(Get-SpecrewTurnMeaningLines -Message (Get-Packet -Project $p1 -Opening 'Wrote the tasks.' -Reason 'The boundary needs your verdict.'))
    $specUrl = ([System.Uri]::new($p1.Spec)).AbsoluteUri
    Assert-True (@($lines1 | Where-Object { $_ -like '## *' }).Count -eq 6) 'all six headings are meaning lines'
    Assert-True ($lines1 -contains $specUrl) 'the review-target link is a meaning line'
    Assert-True ($lines1 -contains 'What would you like to do? Type one of these:') 'the question line is a meaning line'
    Assert-True (($lines1 -contains 'approved for before-implement') -and ($lines1 -contains 'changes needed: <what to change>') -and ($lines1 -contains 'discuss prompt 1')) 'the approval line and verdict options are meaning lines'
    Assert-True ($lines1 -contains '<!-- SPECREW-VERDICT-BOUNDARY: tasks -> before-implement -->') 'the marker is a meaning line'
    Assert-True (-not ($lines1 -contains 'Wrote the tasks.')) 'prose between them is not'

    # -----------------------------------------------------------------------------------------------
    Write-Host 'Case 2: a reworded conversational draft that keeps its question line is not blocked (B4F-100)'
    $t2 = Start-Turn -Project $p1 -Session 'sess-2' -UserText 'Where are we?'
    $draft2 = "The tasks are written and committed. The next step is the first task.`n`nShould I start with T001 now?"
    $reply2 = "Tasks are written and committed; next up is the first task.`n`nShould I start with T001 now?"
    $r2 = Complete-Turn -Project $p1 -Session 'sess-2' -Token $t2.Token -Kind 'conversational' -Draft $draft2 -Reply $reply2
    Assert-True (-not $r2.Blocked) 'a tightened sentence around an unchanged question line: 0 blocks'

    # -----------------------------------------------------------------------------------------------
    Write-Host 'Case 3: a reworded boundary packet that keeps every meaning line is not blocked'
    $p3 = New-Project -PendingCrossing; $projects.Add($p3)
    $t3 = Start-Turn -Project $p3 -Session 'sess-3' -UserText 'Continue.'
    $draft3 = Get-Packet -Project $p3 -Opening 'Wrote the tasks for iteration 001 and committed them.' -Reason 'The before-implement boundary needs your verdict before any code is written.'
    $reply3 = Get-Packet -Project $p3 -Opening 'Wrote and committed the iteration 001 tasks.' -Reason 'Code waits for your before-implement verdict.'
    $r3 = Complete-Turn -Project $p3 -Session 'sess-3' -Token $t3.Token -Kind 'boundary' -Draft $draft3 -Reply $reply3
    Assert-True (-not $r3.Blocked) 'every meaning line kept, prose tightened: 0 blocks'

    # -----------------------------------------------------------------------------------------------
    Write-Host 'Case 4: a dropped verdict option is named'
    $p4 = New-Project -PendingCrossing; $projects.Add($p4)
    $t4 = Start-Turn -Project $p4 -Session 'sess-4' -UserText 'Continue.'
    $draft4 = Get-Packet -Project $p4 -Opening 'Wrote the tasks.' -Reason 'The boundary needs your verdict.'
    $reply4 = Get-Packet -Project $p4 -Opening 'Wrote the tasks.' -Reason 'The boundary needs your verdict.' -DropDiscuss
    $r4 = Complete-Turn -Project $p4 -Session 'sess-4' -Token $t4.Token -Kind 'boundary' -Draft $draft4 -Reply $reply4
    Assert-True ($r4.Blocked) 'the reply without one offered response is blocked'
    Assert-True ($r4.Output -match 'missing: discuss prompt 1') 'the block names the dropped option'

    # -----------------------------------------------------------------------------------------------
    Write-Host 'Case 5: with no crossing pending, a dropped question line is named without asking for an approval line or marker'
    $t5 = Start-Turn -Project $p1 -Session 'sess-5' -UserText 'Where are we?'
    $draft5 = "The spec is drafted.`n`nDo you want the plan next, or a second pass on the spec?"
    $reply5 = 'The spec is drafted.'
    $r5 = Complete-Turn -Project $p1 -Session 'sess-5' -Token $t5.Token -Kind 'conversational' -Draft $draft5 -Reply $reply5
    Assert-True ($r5.Blocked -and $r5.Output -match [regex]::Escape('Do you want the plan next, or a second pass on the spec?')) 'the missing question line is named'
    Assert-True ($r5.Output -notmatch '(?i)approval line|marker') 'no approval line or marker is asked for when none can exist'

    # -----------------------------------------------------------------------------------------------
    Write-Host 'Case 6: the dials line is filled in by the system, and its absence costs no cycle (B4F-106)'
    $p6 = New-Project; $projects.Add($p6)
    $profile6 = Join-Path $p6.Root 'user-profile.yml'
    [System.IO.File]::WriteAllText($profile6, "expertise:`n  product_management: 3`n  software_architecture: 9`n", [System.Text.UTF8Encoding]::new($false))
    $env:SPECREW_USER_PROFILE_PATH = $profile6
    # A bootstrap was delivered to this session, so the orientation lane is live.
    [System.IO.File]::WriteAllText((Join-Path $p6.Root '.specrew/runtime/hook-bootstrap-render-sess-6-startup.json'), '{"rendered":true}', [System.Text.UTF8Encoding]::new($false))
    $t6 = Start-Turn -Project $p6 -Session 'sess-6' -UserText 'Hi, what is going on here?'
    $dials = "What I know about you: I'll treat you as learning on Product Strategy, auto on UX/UI Design, expert on Software Architecture, auto on AI Delivery Planning — correct me if that's off (``/specrew-user-profile edit``), and I'll match how much I ask and explain to it."
    Assert-True ($t6.Output -match '\[specrew-system\]' -and $t6.Output.Contains($dials)) 'the first prompt supplies the finished dials line, marked as system output'
    $orientation = "Specrew 0.40.0-beta4 is active here, on Claude Code. Feature 001 is at the tasks stage; your artifacts are under specs/001-feat."
    $r6 = Complete-Turn -Project $p6 -Session 'sess-6' -Token $t6.Token -Kind 'conversational' -Draft $orientation -Reply $orientation
    Assert-True (-not $r6.Blocked) 'an orientation reply without the dials line is not blocked: 0 human-visible cycles'
    $t6b = Start-Turn -Project $p6 -Session 'sess-6' -UserText 'Thanks.'
    Assert-True (-not $t6b.Output.Contains($dials)) 'the line is supplied once per session, not every turn'

    # -----------------------------------------------------------------------------------------------
    # Co-review round 3 (202): the packet validator accepts a Markdown review link to an absolute path, so every reader
    # of review links must accept it too. The meaning lines and the reviewed-artifact memory read only file:/// URLs:
    # such a link could be dropped from the reply unnoticed, and a change to its file never lifted suppression.
    Write-Host 'Case 7: a Markdown review link is a review link everywhere the validator accepts it'
    $p7 = New-Project -PendingCrossing; $projects.Add($p7)
    $specUrl7 = ([System.Uri]::new($p7.Spec)).AbsoluteUri
    $forms = @(('[the spec]({0})' -f $p7.Spec)) + @(if ($IsWindows) { '[the spec](/{0})' -f ($p7.Spec -replace '\\', '/') })
    foreach ($form in $forms) {
        $draft7 = (Get-Packet -Project $p7 -Opening 'Wrote the tasks.' -Reason 'The boundary needs your verdict.').Replace("The specification: $specUrl7", "The specification: $form")
        Assert-True (@(Test-SpecrewAuthoredPacket -Message $draft7).Count -eq 0 -or -not (@(Test-SpecrewAuthoredPacket -Message $draft7) -contains 'specific review targets with file links')) ("the validator accepts the link: {0}" -f $form)
        $target = ([regex]::Match($form, '\]\((?<t>[^)]+)\)')).Groups['t'].Value
        Assert-True (@(Get-SpecrewTurnMeaningLines -Message $draft7) -contains $target) ("the link is a meaning line: {0}" -f $form)
        $state7 = @(Get-SpecrewReviewedArtifactState -Message $draft7)
        Assert-True (@($state7 | Where-Object { [IO.Path]::GetFullPath([string]$_.path) -eq [IO.Path]::GetFullPath($p7.Spec) -and $_.kind -eq 'file' }).Count -eq 1) ("the linked file is fingerprinted: {0}" -f $form)
    }
    $t7 = Start-Turn -Project $p7 -Session 'sess-7' -UserText 'Continue.'
    $draft7 = (Get-Packet -Project $p7 -Opening 'Wrote the tasks.' -Reason 'The boundary needs your verdict.').Replace("The specification: $specUrl7", ('The specification: [the spec]({0})' -f $p7.Spec))
    $reply7 = $draft7.Replace(('The specification: [the spec]({0})' -f $p7.Spec), 'The specification is in the feature folder.')
    $r7 = Complete-Turn -Project $p7 -Session 'sess-7' -Token $t7.Token -Kind 'boundary' -Draft $draft7 -Reply $reply7
    Assert-True ($r7.Blocked -and $r7.Output.Contains($p7.Spec)) 'a reply that drops the Markdown review link is blocked, naming it'

    # -----------------------------------------------------------------------------------------------
    # 202 DRIFT-030: the first live run of T007 with T014 blocked a reply whose two headings differed from the stdin
    # draft by a function word, and the whole message was rendered again - the B4F-104 repaint class. A heading is
    # present when its meaning matches: the same numbers and identifiers, the same negations, and the same content words
    # up to small wording. The exact lines from that turn come first.
    Write-Host 'Case 8: a reworded heading with the same meaning is present; a changed number, negation or subject is not'
    $p8 = New-Project; $projects.Add($p8)
    $declared8 = @('## The lock: kept at 1000 ms, now as one budget per hook fire', '## T014: turn drafts come in over stdin, stored per session (done)')
    $replied8 = @('## The lock: kept at 1000 ms, now one budget per hook fire', '## T014: turn drafts come in over stdin and are stored per session (done)')
    $body8 = "Body text that the author may reword.`n`nShall I start round 4?"
    $draft8 = ($declared8 -join "`n`nSome prose.`n`n") + "`n`n" + $body8
    $reply8 = ($replied8 -join "`n`nOther prose.`n`n") + "`n`n" + $body8
    Assert-True (@(Get-SpecrewTurnMeaningLinesMissing -Reply $reply8 -MeaningLines @(Get-SpecrewTurnMeaningLines -Message $draft8)).Count -eq 0) 'the two headings from the live turn count as present'
    $t8 = Start-Turn -Project $p8 -Session 'sess-8' -UserText 'Continue.'
    $r8 = Complete-Turn -Project $p8 -Session 'sess-8' -Token $t8.Token -Kind 'conversational' -Draft $draft8 -Reply $reply8
    Assert-True (-not $r8.Blocked) 'the live turn''s reply is not blocked by the Stop (0 repaints)'
    $mustBlock = [ordered]@{
        'a changed number'   = @('## Round 4 starts now', '## Round 3 starts now')
        'a changed id'       = @('## T014 is done', '## T013 is done')
        'an added negation'  = @('## The lock budget holds per hook fire', '## The lock budget does not hold per hook fire')
        'a different subject' = @('## The lock: kept at 1000 ms', '## The validator: kept at 17 failures')
        'a dropped heading'  = @('## What Happens Next', '')
    }
    foreach ($case in $mustBlock.GetEnumerator()) {
        $d = $case.Value[0] + "`n`n" + $body8
        $r = $case.Value[1] + "`n`n" + $body8
        $missing = @(Get-SpecrewTurnMeaningLinesMissing -Reply $r -MeaningLines @(Get-SpecrewTurnMeaningLines -Message $d))
        Assert-True ($missing -contains $case.Value[0]) ("{0} is still missing: '{1}'" -f $case.Key, $case.Value[0])
    }
    $twoDeclared = "## The lock: kept at 1000 ms, now as one budget per hook fire`n`n## The lock: kept at 1000 ms, as one budget per fire`n`n" + $body8
    $oneReplied = "## The lock: kept at 1000 ms, now one budget per hook fire`n`n" + $body8
    Assert-True (@(Get-SpecrewTurnMeaningLinesMissing -Reply $oneReplied -MeaningLines @(Get-SpecrewTurnMeaningLines -Message $twoDeclared)).Count -eq 1) 'one reply heading answers for one declared heading, not two'
}
finally {
    foreach ($px in $projects) { try { Remove-Item -LiteralPath $px.Root -Recurse -Force -ErrorAction SilentlyContinue } catch { $null = $_ } }
    $env:SPECREW_MODULE_PATH = $savedModulePath
    $env:SPECREW_USER_PROFILE_PATH = $savedProfilePath
}
if ($script:failCount -gt 0) { throw ("presented-check: {0} assertion(s) failed" -f $script:failCount) }
Write-Host 'presented-check: all assertions passed' -ForegroundColor Green
