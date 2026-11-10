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
#   12. Feature 203 T011 (FR-046): the decision parts come from pending-verdict-stop.md, not the draft - options
#       reworded within their starts pass; an option the draft also lacks blocks; the approval phrase inside a
#       sentence is not the approval line.
#   13. The record fails closed: missing, unreadable, without its approval line or marker, or naming another crossing,
#       the Stop blocks and says which - also for a turn that declares itself conversational.
#   14. An approval line naming another boundary blocks (markup stripped, anchored at the line start); the same
#       phrase inside a sentence does not.
#   15. One source for the four response lines: turn-end-store.ps1's and the gate-stop skill's are equal.
#
# RED: run with SPECREW_T007_SCRIPTS_ROOT pointing at the pre-T007 scripts; cases 2, 3 and 6 block there.
# Cases 12 to 15 were written before their fix (203 T011).
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
    # -Record (203 T011): which pending-verdict-stop.md the fixture writes beside a pending crossing.
    param([switch]$PendingCrossing, [ValidateSet('good', 'missing', 'unreadable', 'no-approval', 'no-marker', 'other-crossing')][string]$Record = 'good')
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
        $recordLines = switch ($Record) {
            'no-approval' { @('# Specrew Pending Verdict Stop', '', 'Boundary to ask for: tasks -> before-implement', 'Marker last line exactly:', '<!-- SPECREW-VERDICT-BOUNDARY: tasks -> before-implement -->') }
            'no-marker' { @('# Specrew Pending Verdict Stop', '', 'Boundary to ask for: tasks -> before-implement', 'Human approval phrase: approved for before-implement') }
            'other-crossing' { @('# Specrew Pending Verdict Stop', '', 'Boundary to ask for: clarify -> plan', 'Human approval phrase: approved for plan', 'Marker last line exactly:', '<!-- SPECREW-VERDICT-BOUNDARY: clarify -> plan -->') }
            default { @('# Specrew Pending Verdict Stop', '', 'Boundary to ask for: tasks -> before-implement', 'Human approval phrase: approved for before-implement', 'Marker last line exactly:', '<!-- SPECREW-VERDICT-BOUNDARY: tasks -> before-implement -->') }
        }
        $recordPath = Join-Path $root '.specrew/runtime/pending-verdict-stop.md'
        if ($Record -eq 'unreadable') {
            # Not UTF-8: 0xC3 opens a two-byte sequence that 0x28 cannot continue.
            $bytes = [System.Collections.Generic.List[byte]]::new([System.Text.Encoding]::UTF8.GetBytes(($recordLines -join "`n")))
            $bytes.InsertRange(2, [byte[]]@(0xC3, 0x28))
            [System.IO.File]::WriteAllBytes($recordPath, $bytes.ToArray())
        }
        elseif ($Record -ne 'missing') {
            [System.IO.File]::WriteAllText($recordPath, ($recordLines -join "`n"), [System.Text.UTF8Encoding]::new($false))
        }
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
    # Declares the turn as the agent does (203 T011 follow-up: no draft, from a file or stdin), then shows the host's
    # transcript holding the REPLY, which is all the Stop reads.
    param($Project, [string]$Session, [string]$Token, [string]$Kind, [string]$Reply)
    $script:Turn++
    $null = Invoke-Pwsh -Root $Project.Root -Script $declare -Arguments @('-Kind', $Kind, '-Summary', ('turn {0}' -f $script:Turn), '-Token', $Token)
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
    # 203 T011 follow-up (FR-046; maintainer ruling 2026-11-11): the draft and its meaning lines are gone. What these
    # cases checked against a draft is checked against the reply itself, or not at all: cases 1 and 8 to 11 tested only
    # the draft comparison (the meaning-line set, and how closely a reworded heading or question had to match its
    # draft) and were removed with it.
    $p1 = New-Project; $projects.Add($p1)

    # -----------------------------------------------------------------------------------------------
    Write-Host 'Case 2: a conversational reply is not compared with anything (B4F-100)'
    $t2 = Start-Turn -Project $p1 -Session 'sess-2' -UserText 'Where are we?'
    $reply2 = "Tasks are written and committed; next up is the first task.`n`nShould I start with T001 now?"
    $r2 = Complete-Turn -Project $p1 -Session 'sess-2' -Token $t2.Token -Kind 'conversational' -Reply $reply2
    Assert-True (-not $r2.Blocked) 'a conversational reply: 0 blocks'

    # -----------------------------------------------------------------------------------------------
    Write-Host 'Case 3: a boundary packet in its own words, with every part, is not blocked'
    $p3 = New-Project -PendingCrossing; $projects.Add($p3)
    $t3 = Start-Turn -Project $p3 -Session 'sess-3' -UserText 'Continue.'
    $reply3 = Get-Packet -Project $p3 -Opening 'Wrote and committed the iteration 001 tasks.' -Reason 'Code waits for your before-implement verdict.'
    $r3 = Complete-Turn -Project $p3 -Session 'sess-3' -Token $t3.Token -Kind 'boundary' -Reply $reply3
    Assert-True (-not $r3.Blocked) ("every part present: 0 blocks ({0})" -f (($r3.Output -split "`n" | Select-Object -First 4) -join ' | '))

    # -----------------------------------------------------------------------------------------------
    Write-Host 'Case 4: a dropped verdict option is named'
    $p4 = New-Project -PendingCrossing; $projects.Add($p4)
    $t4 = Start-Turn -Project $p4 -Session 'sess-4' -UserText 'Continue.'
    $reply4 = Get-Packet -Project $p4 -Opening 'Wrote the tasks.' -Reason 'The boundary needs your verdict.' -DropDiscuss
    $r4 = Complete-Turn -Project $p4 -Session 'sess-4' -Token $t4.Token -Kind 'boundary' -Reply $reply4
    Assert-True ($r4.Blocked) 'the reply without one offered response is blocked'
    Assert-True ($r4.Output -match 'missing: discuss prompt 1') 'the block names the dropped option'

    # Co-review round 6 (202, FR-015): options written as bullets, quotes, numbers, bold or inline code are still the
    # options; the wrapper is formatting.
    Write-Host 'Case 4b: verdict options written as bullets or inline code are still the options'
    $bulleted = ((Get-Packet -Project $p4 -Opening 'Wrote the tasks.' -Reason 'The boundary needs your verdict.') -replace "`r`n", "`n") -replace '(?m)^  changes needed: <what to change>$', '- changes needed: <what to change>' -replace '(?m)^  discuss prompt 1$', '- `discuss prompt 1`'
    Assert-True ($bulleted.Contains('- `discuss prompt 1`') -and $bulleted.Contains('- changes needed:')) 'the fixture really carries the bulleted options'
    $marker4 = '<!-- SPECREW-VERDICT-BOUNDARY: tasks -> before-implement -->'
    $parts4 = Get-SpecrewReplyDecisionParts -Reply $bulleted -ApprovalPhrase 'approved for before-implement' -Marker $marker4
    Assert-True (@($parts4.Missing).Count -eq 0) ("bulleted and inline-code options count ({0})" -f (@($parts4.Missing) -join ' | '))
    $starred = "* approved for before-implement`n> approved for before-implement - keep the order`n1. discuss prompt 3`n**changes needed:** say what`n$marker4"
    $partsStar = Get-SpecrewReplyDecisionParts -Reply $starred -ApprovalPhrase 'approved for before-implement' -Marker $marker4
    Assert-True (@($partsStar.Missing).Count -eq 0) ("star bullets, quotes, numbered items and bold labels count too ({0})" -f (@($partsStar.Missing) -join ' | '))
    $droppedBullets = $bulleted -replace '(?m)^- changes needed: <what to change>\n', '' -replace '(?m)^- `discuss prompt 1`\n', ''
    $missing4b = @((Get-SpecrewReplyDecisionParts -Reply $droppedBullets -ApprovalPhrase 'approved for before-implement' -Marker $marker4).Missing)
    Assert-True ($missing4b -contains 'discuss prompt 1' -and $missing4b -contains 'changes needed: <what to change>') ("a reply that drops the bulleted options misses them ({0})" -f ($missing4b -join ' | '))

    # -----------------------------------------------------------------------------------------------
    Write-Host 'Case 5: with no crossing pending, a reply is not held to a draft'
    $t5 = Start-Turn -Project $p1 -Session 'sess-5' -UserText 'Where are we?'
    $r5 = Complete-Turn -Project $p1 -Session 'sess-5' -Token $t5.Token -Kind 'conversational' -Reply 'The spec is drafted.'
    Assert-True (-not $r5.Blocked) 'a conversational reply is not blocked for a question it does not ask'
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
    $r6 = Complete-Turn -Project $p6 -Session 'sess-6' -Token $t6.Token -Kind 'conversational' -Reply $orientation
    Assert-True (-not $r6.Blocked) 'an orientation reply without the dials line is not blocked: 0 human-visible cycles'
    $t6b = Start-Turn -Project $p6 -Session 'sess-6' -UserText 'Thanks.'
    Assert-True (-not $t6b.Output.Contains($dials)) 'the line is supplied once per session, not every turn'

    # -----------------------------------------------------------------------------------------------
    # Co-review round 3 (202): a Markdown review link to an absolute path is a review link wherever one is read - the
    # packet check and the reviewed-artifact memory alike.
    Write-Host 'Case 7: a Markdown review link is a review link everywhere one is read'
    $p7 = New-Project -PendingCrossing; $projects.Add($p7)
    $specUrl7 = ([System.Uri]::new($p7.Spec)).AbsoluteUri
    $forms = @(('[the spec]({0})' -f $p7.Spec)) + @(if ($IsWindows) { '[the spec](/{0})' -f ($p7.Spec -replace '\\', '/') })
    foreach ($form in $forms) {
        $reply7f = (Get-Packet -Project $p7 -Opening 'Wrote the tasks.' -Reason 'The boundary needs your verdict.').Replace("The specification: $specUrl7", "The specification: $form")
        $check7 = Test-SpecrewReplyPacket -Reply $reply7f
        Assert-True ([bool]$check7.present) ("the packet check accepts the link: {0} ({1})" -f $form, (@($check7.problems) -join ' | '))
        $state7 = @(Get-SpecrewReviewedArtifactState -Message $reply7f)
        Assert-True (@($state7 | Where-Object { [IO.Path]::GetFullPath([string]$_.path) -eq [IO.Path]::GetFullPath($p7.Spec) -and $_.kind -eq 'file' }).Count -eq 1) ("the linked file is fingerprinted: {0}" -f $form)
    }
    $t7 = Start-Turn -Project $p7 -Session 'sess-7' -UserText 'Continue.'
    $reply7 = (Get-Packet -Project $p7 -Opening 'Wrote the tasks.' -Reason 'The boundary needs your verdict.').Replace("The specification: $specUrl7", 'The specification is in the feature folder.')
    $r7 = Complete-Turn -Project $p7 -Session 'sess-7' -Token $t7.Token -Kind 'boundary' -Reply $reply7
    Assert-True ($r7.Blocked -and $r7.Output.Contains('What Needs Your Review has no file link')) 'a reply whose review section has no link is blocked, saying so'

    # ===============================================================================================
    # Feature 203 T011 (FR-046; maintainer ruling 2026-11-10). The Stop checks a boundary reply's decision parts from
    # the pending-verdict record, not from the declared draft: the approval line and the marker as the record gives
    # them, and the four responses by their fixed starts. Three additions: the record fails closed; a foreign approval
    # line blocks; the four lines have one source, held equal to the gate-stop skill.
    $optionWords = @('  approved for before-implement - <your instructions>', '  changes needed: <what to change>', '  discuss prompt 1')

    Write-Host 'Case 12a: options reworded within their starts pass'
    $p12 = New-Project -PendingCrossing; $projects.Add($p12)
    $t12a = Start-Turn -Project $p12 -Session 'sess-12a' -UserText 'Continue.'
    $draft12 = Get-Packet -Project $p12 -Opening 'Wrote the tasks.' -Reason 'The boundary needs your verdict.'
    $reply12a = $draft12.Replace($optionWords[0], '- approved for before-implement - start with T001 and keep the order').Replace($optionWords[1], '- changes needed: say what to change').Replace($optionWords[2], '- discuss prompt 2')
    Assert-True ($reply12a.Contains('start with T001') -and -not $reply12a.Contains('<your instructions>')) 'the fixture really rewords the three option lines'
    $r12a = Complete-Turn -Project $p12 -Session 'sess-12a' -Token $t12a.Token -Kind 'boundary' -Reply $reply12a
    Assert-True (-not $r12a.Blocked) ("a reply whose options keep their starts is not blocked ({0})" -f (($r12a.Output -split "`n" | Where-Object { $_ -match 'missing' }) -join ' | '))

    Write-Host 'Case 12b: the options come from the record, not the draft'
    $t12b = Start-Turn -Project $p12 -Session 'sess-12b' -UserText 'Continue.'
    $both12b = $draft12.Replace($optionWords[1] + "`n", '').Replace($optionWords[1] + "`r`n", '')
    Assert-True (-not $both12b.Contains('changes needed')) 'the fixture drops the changes-needed option from draft and reply alike'
    $r12b = Complete-Turn -Project $p12 -Session 'sess-12b' -Token $t12b.Token -Kind 'boundary' -Reply $both12b
    Assert-True ($r12b.Blocked -and $r12b.Output.Contains('missing: changes needed: <what to change>')) 'a draft and reply that both lack an option are blocked, naming it'

    Write-Host 'Case 12c: the approval phrase inside a sentence is not the approval line'
    $t12c = Start-Turn -Project $p12 -Session 'sess-12c' -UserText 'Continue.'
    $both12c = ($draft12 -replace '(?m)^  approved for before-implement\r?$', 'Type approved for before-implement when the order is right.')
    Assert-True (-not ($both12c -match '(?m)^\s*approved for before-implement\s*$') -and $both12c.Contains('Type approved for before-implement')) 'the fixture carries the phrase only inside a sentence'
    $r12c = Complete-Turn -Project $p12 -Session 'sess-12c' -Token $t12c.Token -Kind 'boundary' -Reply $both12c
    Assert-True ($r12c.Blocked -and $r12c.Output.Contains('missing: approved for before-implement')) 'the approval line is required on a line of its own'

    Write-Host 'Case 13: the record fails closed - a broken pending-verdict record blocks and says which'
    $recordCases = [ordered]@{
        'missing'        = 'pending-verdict-stop.md is missing'
        'unreadable'     = 'pending-verdict-stop.md cannot be read'
        'no-approval'    = "pending-verdict-stop.md has no 'Human approval phrase:' line"
        'no-marker'      = 'pending-verdict-stop.md has no marker line'
        'other-crossing' = 'pending-verdict-stop.md names the crossing clarify -> plan'
    }
    foreach ($rc in $recordCases.GetEnumerator()) {
        $p13 = New-Project -PendingCrossing -Record $rc.Key; $projects.Add($p13)
        $t13 = Start-Turn -Project $p13 -Session ('sess-13-' + $rc.Key) -UserText 'Continue.'
        $packet13 = Get-Packet -Project $p13 -Opening 'Wrote the tasks.' -Reason 'The boundary needs your verdict.'
        $r13 = Complete-Turn -Project $p13 -Session ('sess-13-' + $rc.Key) -Token $t13.Token -Kind 'boundary' -Reply $packet13
        Assert-True ($r13.Blocked -and $r13.Output.Contains($rc.Value)) ("record {0}: blocked, saying '{1}'" -f $rc.Key, $rc.Value)
    }
    $p13c = New-Project -PendingCrossing -Record 'missing'; $projects.Add($p13c)
    $t13c = Start-Turn -Project $p13c -Session 'sess-13-conv' -UserText 'Where are we?'
    $r13c = Complete-Turn -Project $p13c -Session 'sess-13-conv' -Token $t13c.Token -Kind 'conversational' -Reply 'We are at the tasks stage.'
    Assert-True ($r13c.Blocked -and $r13c.Output.Contains('pending-verdict-stop.md is missing')) 'a turn that declares itself conversational does not make the owed verdict go away'

    Write-Host 'Case 14: an approval line for another boundary blocks; the phrase inside a sentence does not'
    $foreign = [ordered]@{
        'approved for review-signoff'          = '  approved for review-signoff'
        'approved for tasks'                   = '- `approved for tasks`'
        'approved for before-implementation'   = '> approved for before-implementation'
    }
    $i14 = 0
    foreach ($fc in $foreign.GetEnumerator()) {
        $i14++
        $t14 = Start-Turn -Project $p12 -Session ('sess-14-' + $i14) -UserText 'Continue.'
        $reply14 = $draft12.Replace('  discuss prompt 1', ("  discuss prompt 1`n" + $fc.Value))
        Assert-True ($reply14.Contains($fc.Value)) ("the fixture carries the foreign line: {0}" -f $fc.Value)
        $r14 = Complete-Turn -Project $p12 -Session ('sess-14-' + $i14) -Token $t14.Token -Kind 'boundary' -Reply $reply14
        Assert-True ($r14.Blocked -and $r14.Output.Contains($fc.Key)) ("a reply offering '{0}' is blocked, naming it" -f $fc.Key)
    }
    $t14s = Start-Turn -Project $p12 -Session 'sess-14-sentence' -UserText 'Continue.'
    $reply14s = $draft12.Replace('Wrote the tasks.', 'Wrote the tasks; you typed approved for tasks earlier, which is recorded.')
    $r14s = Complete-Turn -Project $p12 -Session 'sess-14-sentence' -Token $t14s.Token -Kind 'boundary' -Reply $reply14s
    Assert-True (-not $r14s.Blocked) 'another boundary named inside a sentence is not an approval line'

    Write-Host 'Case 15: one source for the four lines - the hook''s and the gate-stop skill''s are equal'
    $optionsDefined = Test-Path variable:script:SpecrewVerdictOptions
    Assert-True $optionsDefined 'turn-end-store.ps1 defines the four verdict options'
    $skillCopies = @(
        (Join-Path $repoRoot 'extensions/specrew-speckit/squad-templates/skills/gate-stop.md'),
        (Join-Path $repoRoot '.specify/extensions/specrew-speckit/squad-templates/skills/gate-stop.md'),
        (Join-Path $repoRoot '.claude/skills/specrew-gate-stop/SKILL.md')) | Where-Object { Test-Path -LiteralPath $_ -PathType Leaf }
    Assert-True ($skillCopies.Count -ge 1) 'the gate-stop skill source is found'
    foreach ($copy in $skillCopies) {
        $skillText = [System.IO.File]::ReadAllText($copy) -replace "`r`n", "`n"
        $block = [regex]::Match($skillText, '(?s)Type one of these:\n\n(?<lines>(?:[ \t]+\S[^\n]*\n)+)')
        $skillLines = @(if ($block.Success) { $block.Groups['lines'].Value -split "`n" | ForEach-Object { $_.Trim() } | Where-Object { $_ } })
        $hookLines = @(if ($optionsDefined) { $script:SpecrewVerdictOptions | ForEach-Object { [string]$_.Shown } })
        Assert-True ($skillLines.Count -eq 4 -and ($skillLines -join '|') -ceq ($hookLines -join '|')) ("{0}: the skill's four lines equal the hook's ({1})" -f (Split-Path -Leaf (Split-Path -Parent $copy)), ($skillLines -join ' | '))
        if ($optionsDefined) {
            for ($k = 0; $k -lt $skillLines.Count; $k++) {
                $line = $skillLines[$k].Replace('<to>', 'before-implement')
                $hit = @(Get-SpecrewVerdictOptionIndex -Line $line -ApprovalPhrase 'approved for before-implement')
                Assert-True ($hit.Count -eq 1 -and $hit[0] -eq $k) ("skill line {0} is matched by its own start and no other: '{1}'" -f ($k + 1), $line)
            }
        }
    }

    # ===============================================================================================
    # Feature 203 T011 follow-up (FR-046; maintainer ruling 2026-11-11, item 1). There is no draft any more: the Stop
    # reads the packet from the reply itself. The packet is present when the six section headings each start a line
    # (any heading level, words may follow) and each has text before the next; a section whose only content is stock
    # placeholder text is empty. What Needs Your Review carries at least one file link, and every one resolves to an
    # existing file. "recommend" no longer blocks: it is written to the Stop's history line. Nothing is checked
    # against a draft, and declare-turn-end reads none.
    Write-Host 'Case 16a: a packet with no draft, headings at other levels with words after them, passes'
    $p16 = New-Project -PendingCrossing; $projects.Add($p16)
    $base16 = Get-Packet -Project $p16 -Opening 'Wrote the tasks.' -Reason 'The boundary needs your verdict.'
    $reply16a = $base16.Replace('## What I Just Did', '### What I Just Did (tasks)').Replace('## Why I Stopped', '# Why I Stopped here')
    $t16a = Start-Turn -Project $p16 -Session 'sess-16a' -UserText 'Continue.'
    $r16a = Complete-Turn -Project $p16 -Session 'sess-16a' -Token $t16a.Token -Kind 'boundary' -Reply $reply16a
    Assert-True (-not $r16a.Blocked) ("a complete packet declared with no draft is not blocked ({0})" -f (($r16a.Output -split "`n" | Select-Object -First 6) -join ' | '))

    Write-Host 'Case 16b: a missing section, and a section of stock placeholder text only, block naming the section'
    $sections16 = [ordered]@{
        'missing section: Why I Stopped'     = ($base16 -replace '(?m)^## Why I Stopped\r?\n', '')
        'empty section: What Happens Next'   = $base16.Replace('Implementation starts with the first task on approval.', 'On approval the next stage starts.')
        'empty section: Discussion Prompts'  = $base16.Replace('1. Is the task order right?', '1. Anything above you want changed, questioned, or done differently.')
        'empty section: What I Just Did'     = $base16.Replace('Wrote the tasks.', '')
    }
    $n16 = 0
    foreach ($sc in $sections16.GetEnumerator()) {
        $n16++
        $t16 = Start-Turn -Project $p16 -Session ("sess-16b-{0}" -f $n16) -UserText 'Continue.'
        $r16 = Complete-Turn -Project $p16 -Session ("sess-16b-{0}" -f $n16) -Token $t16.Token -Kind 'boundary' -Reply $sc.Value
        Assert-True ($r16.Blocked -and $r16.Output.Contains($sc.Key)) ("blocked, saying '{0}'" -f $sc.Key)
    }

    Write-Host 'Case 16c: the review link must resolve to an existing file'
    $specUrl16 = ([System.Uri]::new($p16.Spec)).AbsoluteUri
    $goneUrl16 = ([System.Uri]::new((Join-Path $p16.Root 'specs/001-feat/gone.md'))).AbsoluteUri
    $t16c = Start-Turn -Project $p16 -Session 'sess-16c' -UserText 'Continue.'
    $r16c = Complete-Turn -Project $p16 -Session 'sess-16c' -Token $t16c.Token -Kind 'boundary' -Reply ($base16.Replace($specUrl16, $goneUrl16))
    Assert-True ($r16c.Blocked -and $r16c.Output.Contains('review link to a missing file: ' + $goneUrl16)) 'a review link to a missing file blocks, naming it'
    $t16c2 = Start-Turn -Project $p16 -Session 'sess-16c2' -UserText 'Continue.'
    $r16c2 = Complete-Turn -Project $p16 -Session 'sess-16c2' -Token $t16c2.Token -Kind 'boundary' -Reply ($base16.Replace('The specification: ' + $specUrl16, 'The specification, as discussed.'))
    Assert-True ($r16c2.Blocked -and $r16c2.Output.Contains('What Needs Your Review has no file link')) 'a review section without a file link blocks'

    Write-Host 'Case 16d: "recommend" does not block; the Stop records whether it was there'
    $t16d = Start-Turn -Project $p16 -Session 'sess-16d' -UserText 'Continue.'
    $r16d = Complete-Turn -Project $p16 -Session 'sess-16d' -Token $t16d.Token -Kind 'boundary' -Reply ($base16.Replace(' My recommendation: approve.', ''))
    Assert-True (-not $r16d.Blocked) 'a packet without the word recommend is not blocked'
    $journal16 = Join-Path $p16.Root '.specrew/runtime/conformance-journal.jsonl'
    $last16 = if (Test-Path -LiteralPath $journal16) { @(Get-Content -LiteralPath $journal16 | Where-Object { $_ -match '"event":"observe"' }) | Select-Object -Last 1 } else { '' }
    $last16 = "$last16"
    Assert-True ($last16 -match '"recommendation_present":false') ("the Stop's history line records no recommendation ({0})" -f $last16.Substring(0, [Math]::Min(160, $last16.Length)))
    $t16d2 = Start-Turn -Project $p16 -Session 'sess-16d2' -UserText 'Continue.'
    $null = Complete-Turn -Project $p16 -Session 'sess-16d2' -Token $t16d2.Token -Kind 'boundary' -Reply $base16
    $last16b = @(Get-Content -LiteralPath $journal16 | Where-Object { $_ -match '"event":"observe"' }) | Select-Object -Last 1
    Assert-True ([string]$last16b -match '"recommendation_present":true') 'and records one when it is there'

    Write-Host 'Case 16e: declare-turn-end reads no draft, from a file or from stdin'
    $t16e = Start-Turn -Project $p16 -Session 'sess-16e' -UserText 'Continue.'
    $draft16e = Join-Path $p16.Root '.specrew/runtime/draft-16e.md'
    [System.IO.File]::WriteAllText($draft16e, $base16, [System.Text.UTF8Encoding]::new($false))
    $json16e = Invoke-Pwsh -Root $p16.Root -Script $declare -Arguments @('-Kind', 'boundary', '-MessagePath', $draft16e, '-Summary', 'turn 16e', '-Token', $t16e.Token, '-AsJson')
    $d16e = $json16e | ConvertFrom-Json
    $rec16e = Get-Content -LiteralPath ([string]$d16e.record_path) -Raw | ConvertFrom-Json
    Assert-True ([string]$d16e.draft_source -eq 'none' -and -not ($rec16e.PSObject.Properties['message'] -and -not [string]::IsNullOrEmpty([string]$rec16e.message))) ("-MessagePath is not read (draft_source '{0}')" -f [string]$d16e.draft_source)
    $t16e2 = Start-Turn -Project $p16 -Session 'sess-16e2' -UserText 'Continue.'
    Push-Location -LiteralPath $p16.Root
    try { $json16e2 = (@($base16 | & pwsh -NoProfile -NonInteractive -File $declare -Kind boundary -Summary 'turn 16e2' -Token $t16e2.Token -AsJson 2>&1) -join "`n") }
    finally { Pop-Location }
    $d16e2 = $json16e2 | ConvertFrom-Json
    Assert-True ([string]$d16e2.draft_source -eq 'none') ("stdin is not read (draft_source '{0}')" -f [string]$d16e2.draft_source)
    $lines16e = @(([string]$d16e2.text) -split '\r?\n')
    Assert-True (($lines16e -join '|') -ceq (@('approved for before-implement', 'approved for before-implement - <your instructions>', 'changes needed: <what to change>', 'discuss prompt 1', '<!-- SPECREW-VERDICT-BOUNDARY: tasks -> before-implement -->') -join '|')) ("a boundary declaration returns the four response lines and the marker from the record ({0})" -f ($lines16e -join ' | '))
}
finally {
    foreach ($px in $projects) { try { Remove-Item -LiteralPath $px.Root -Recurse -Force -ErrorAction SilentlyContinue } catch { $null = $_ } }
    $env:SPECREW_MODULE_PATH = $savedModulePath
    $env:SPECREW_USER_PROFILE_PATH = $savedProfilePath
}
if ($script:failCount -gt 0) { throw ("presented-check: {0} assertion(s) failed" -f $script:failCount) }
Write-Host 'presented-check: all assertions passed' -ForegroundColor Green
