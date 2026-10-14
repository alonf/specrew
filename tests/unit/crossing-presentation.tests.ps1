#requires -Version 7.0
# Feature 202 T006 (FR-011, SC-004, DA-2, DRIFT-008): an unchanged pending crossing is presented ONCE per
# session, and again only after a context gap - while a crossing whose verdict the capture missed can always
# be presented again.
#
# Driven through the real conformance provider and the real declare-turn-end.ps1 in a temp project that
# carries a real scoped pending crossing (tasks -> before-implement). A Stop block is what the host shows as
# "Stop hook error" and what forces the packet to be painted again, so "0 repaints and 0 Stop errors" is
# measured as 0 blocks.
#
# Cases:
#   1. Presentation: a verified boundary declaration records the crossing for this session.
#   2. The three recorded B4F-104 triggers (side question, wrong verdict, orientation request): 0 blocks.
#   3. A bookkeeping commit (a drift entry, HEAD moves): 0 blocks.
#   4. A compaction (SessionStart compact): exactly one block, then quiet again after the re-presentation.
#   5. Capture miss (DRIFT-008): a typed reply carrying the approval phrase after a pasted block, crossing
#      still pending -> the packet is owed again; the re-presented marker then captures the next typed verdict.
#   6. The other gaps: a changed review target, the 8-hour gap, another session, an unanchored session.
#   7. The reply matcher: the phrase is found after a paste, a different boundary is not.
#
# RED: run with SPECREW_T006_SCRIPTS_ROOT pointing at the pre-T006 scripts; cases 2 and 3 block there, which
# is B4F-104 itself, and the case-5 recovery is the behavior that must survive T006.
Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'
$repoRoot = (Resolve-Path (Join-Path $PSScriptRoot '..\..')).Path
$scriptsRoot = if (-not [string]::IsNullOrWhiteSpace($env:SPECREW_T006_SCRIPTS_ROOT)) { $env:SPECREW_T006_SCRIPTS_ROOT } else { Join-Path $repoRoot 'extensions\specrew-speckit\scripts' }
$provider = Join-Path $scriptsRoot 'specrew-conformance-provider.ps1'
$declare = Join-Path $scriptsRoot 'declare-turn-end.ps1'
$handover = Join-Path $scriptsRoot 'specrew-handover-provider.ps1'
. (Join-Path $repoRoot 'extensions\specrew-speckit\scripts\shared-governance.ps1')
Get-ChildItem (Join-Path $repoRoot 'scripts\internal\bootstrap\*.ps1') | ForEach-Object { . $_.FullName }
. (Join-Path $repoRoot 'extensions\specrew-speckit\scripts\turn-end-store.ps1')
$savedModulePath = $env:SPECREW_MODULE_PATH
$env:SPECREW_MODULE_PATH = $repoRoot
$script:failCount = 0

function Write-Pass { param([string]$Message) Write-Host "PASS: $Message" -ForegroundColor Green }
function Write-Fail { param([string]$Message) Write-Host "FAIL: $Message" -ForegroundColor Red; $script:failCount++ }
function Assert-True { param([bool]$Condition, [string]$Message) if ($Condition) { Write-Pass $Message } else { Write-Fail $Message } }

function New-PendingFixture {
    $root = [System.IO.Path]::GetFullPath((Join-Path ([System.IO.Path]::GetTempPath()) ("t006-{0}" -f [guid]::NewGuid().ToString('N').Substring(0, 10))))
    $feature = Join-Path $root 'specs/001-feat'
    $iter = Join-Path $feature 'iterations/001'
    New-Item -ItemType Directory -Force -Path (Join-Path $root '.specrew/runtime') | Out-Null
    New-Item -ItemType Directory -Force -Path (Join-Path $iter 'quality') | Out-Null
    Set-Content -LiteralPath (Join-Path $feature 'spec.md') -Value "# Feature Specification: Feat`n`nBody." -Encoding UTF8
    Set-Content -LiteralPath (Join-Path $iter 'plan.md') -Value "# Iteration Plan: 001`n`n**Status**: executing" -Encoding UTF8
    Set-Content -LiteralPath (Join-Path $iter 'state.md') -Value "# Iteration State: 001`n`n**Current Phase**: tasks" -Encoding UTF8
    Set-Content -LiteralPath (Join-Path $iter 'quality/hardening-gate.md') -Value "# Hardening Gate`n`n**Overall Verdict**: ready" -Encoding UTF8
    Set-Content -LiteralPath (Join-Path $iter 'drift-log.md') -Value "# Drift Log`n" -Encoding UTF8
    Set-Content -LiteralPath (Join-Path $root '.gitignore') -Value ".specrew/`n" -Encoding UTF8
    & git -C $root init -q -b main
    & git -C $root config user.email 't@t'
    & git -C $root config user.name 't'
    & git -C $root config core.autocrlf false
    & git -C $root add -A
    & git -C $root commit -q -m fixture
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
    $stopArtifact = Join-Path $root '.specrew/runtime/pending-verdict-stop.md'
    [System.IO.File]::WriteAllText($stopArtifact, (@('# Specrew Pending Verdict Stop', '', 'Boundary to ask for: tasks -> before-implement', 'Human approval phrase: approved for before-implement', 'Marker last line exactly:', '<!-- SPECREW-VERDICT-BOUNDARY: tasks -> before-implement -->') -join "`n"), [System.Text.UTF8Encoding]::new($false))
    $pv = Get-SpecrewPendingVerdictState -ProjectRoot $root
    if (-not [bool]$pv.HasPendingVerdict) { throw ("fixture: the crossing is not pending ({0})" -f [string]$pv.IntegrityStatus) }
    return [pscustomobject]@{ Root = $root; Spec = (Join-Path $feature 'spec.md'); Iter = $iter; DriftLog = (Join-Path $iter 'drift-log.md') }
}

function Get-Packet {
    param($Fixture, [string]$Note)
    $specUrl = ([System.Uri]::new($Fixture.Spec)).AbsoluteUri
    $iterUrl = ([System.Uri]::new($Fixture.Iter + [System.IO.Path]::DirectorySeparatorChar)).AbsoluteUri
    return @"
## What I Just Did

Wrote the tasks for iteration 001 and committed them. $Note

## Why I Stopped

The before-implement boundary needs your verdict before any code is written. My recommendation: approve; every task traces to a requirement.

## What Needs Your Review

The specification: $specUrl
The iteration folder: $iterUrl

## What Happens Next

Implementation starts with the first task on approval.

## Discussion Prompts

1. Is the task order right?

## What I Need From You

What would you like to do? Type one of these:

  approved for before-implement
  approved for before-implement - <your instructions>
  changes needed: <what to change>
  discuss prompt 1

<!-- SPECREW-VERDICT-BOUNDARY: tasks -> before-implement -->
"@
}

$script:Turn = 0
function Invoke-Pwsh {
    param([string]$Root, [string]$Script, [string[]]$Arguments)
    Push-Location -LiteralPath $Root
    try { return (@(& pwsh -NoProfile -NonInteractive -ExecutionPolicy Bypass -File $Script @Arguments 2>&1) -join "`n") }
    finally { Pop-Location }
}

function Start-SessionTurn {
    # The prompt event: issues this turn's token and, for a typed reply, registers whether it carried the
    # presented crossing's approval phrase.
    param($Fixture, [string]$Session, [string]$UserText, [string]$Origin = 'typed-user')
    $arguments = @('--host-kind', 'claude', '--source-event', 'UserPromptSubmit')
    if (-not [string]::IsNullOrWhiteSpace($Session)) { $arguments += @('--session-id', $Session) }
    if (-not [string]::IsNullOrWhiteSpace($UserText)) { $arguments += @('--last-user-message', $UserText, '--turn-origin', $Origin) }
    $out = Invoke-Pwsh -Root $Fixture.Root -Script $provider -Arguments $arguments
    $m = [regex]::Match($out, '-Token\s+([0-9a-f]{16,})')
    return $(if ($m.Success) { $m.Groups[1].Value } else { '' })
}

function Complete-SessionTurn {
    # Declares the turn end with the draft, writes the transcript the host would hold (the typed reply, then
    # the draft as the visible reply), and runs the Stop. Returns whether the Stop blocked.
    param($Fixture, [string]$Session, [string]$Token, [string]$Kind, [string]$UserText, [string]$Reply)
    $script:Turn++
    $draft = Join-Path $Fixture.Root (".specrew/runtime/draft-{0}.md" -f $script:Turn)
    [System.IO.File]::WriteAllText($draft, $Reply, [System.Text.UTF8Encoding]::new($false))
    $declareArgs = @('-Kind', $Kind, '-MessagePath', $draft, '-Summary', ('turn {0}' -f $script:Turn))
    if (-not [string]::IsNullOrWhiteSpace($Token)) { $declareArgs += @('-Token', $Token) }
    $null = Invoke-Pwsh -Root $Fixture.Root -Script $declare -Arguments $declareArgs
    $transcript = Join-Path $Fixture.Root (".specrew/runtime/transcript-{0}.jsonl" -f $script:Turn)
    $lines = @(
        ([pscustomobject]@{ type = 'user'; message = [pscustomobject]@{ role = 'user'; content = @([pscustomobject]@{ type = 'text'; text = $UserText }) } } | ConvertTo-Json -Depth 8 -Compress),
        ([pscustomobject]@{ type = 'assistant'; message = [pscustomobject]@{ role = 'assistant'; content = @([pscustomobject]@{ type = 'text'; text = $Reply }) } } | ConvertTo-Json -Depth 8 -Compress)
    )
    [System.IO.File]::WriteAllLines($transcript, [string[]]$lines, [System.Text.UTF8Encoding]::new($false))
    $arguments = @('--host-kind', 'claude', '--source-event', 'Stop', '--transcript-path', $transcript)
    if (-not [string]::IsNullOrWhiteSpace($Session)) { $arguments += @('--session-id', $Session) }
    $out = Invoke-Pwsh -Root $Fixture.Root -Script $provider -Arguments $arguments
    return [pscustomobject]@{ Blocked = ($out -match '<<<SPECREW-STOP-BLOCK>>>'); Output = $out; Transcript = $transcript }
}

function Invoke-SessionTurn {
    param($Fixture, [string]$Session, [string]$UserText, [string]$Kind, [string]$Reply)
    $token = Start-SessionTurn -Fixture $Fixture -Session $Session -UserText $UserText
    return (Complete-SessionTurn -Fixture $Fixture -Session $Session -Token $token -Kind $Kind -UserText $UserText -Reply $Reply)
}

function Get-LastJournal {
    param($Fixture)
    $path = Join-Path $Fixture.Root '.specrew/runtime/conformance-journal.jsonl'
    if (-not (Test-Path -LiteralPath $path -PathType Leaf)) { return $null }
    $last = @(Get-Content -LiteralPath $path -Encoding UTF8 | Where-Object { -not [string]::IsNullOrWhiteSpace($_) }) | Select-Object -Last 1
    return $(if ($null -eq $last) { $null } else { $last | ConvertFrom-Json })
}

function Get-JournalField {
    param($Record, [string]$Name)
    if ($null -eq $Record -or -not $Record.PSObject.Properties[$Name]) { return '' }
    return [string]$Record.$Name
}

$mention = 'The tasks decision is still open; type "approved for before-implement" when you are ready.'
$fixtures = [System.Collections.Generic.List[object]]::new()
try {
    # -----------------------------------------------------------------------------------------------
    Write-Host 'Case 1: a verified presentation records the crossing for this session'
    $f = New-PendingFixture; $fixtures.Add($f)
    $s = 'sess-a'
    $p1 = Invoke-SessionTurn -Fixture $f -Session $s -UserText 'Continue.' -Kind 'boundary' -Reply (Get-Packet -Fixture $f -Note 'First presentation.')
    Assert-True (-not $p1.Blocked) 'the presented packet ends the turn without a block'
    $ownerHash = Get-SpecrewTurnEndOwnerHash -HostKind 'claude' -SessionId $s
    $recordPath = Join-Path $f.Root (".specrew/runtime/turn-end/{0}/presented-crossings.json" -f $ownerHash)
    $hasRecord = Test-Path -LiteralPath $recordPath -PathType Leaf
    Assert-True $hasRecord 'presented-crossings.json is written in this session''s turn-end directory'
    if ($hasRecord) {
        $rec = Get-Content -LiteralPath $recordPath -Raw -Encoding UTF8 | ConvertFrom-Json
        $pv = Get-SpecrewPendingVerdictState -ProjectRoot $f.Root
        Assert-True ([string]$rec.crossing_id -eq [string]$pv.CrossingId) 'the record names the pending crossing id'
        $specEntry = @($rec.reviewed_artifact_state | Where-Object { [string]$_.kind -eq 'file' })
        $dirEntry = @($rec.reviewed_artifact_state | Where-Object { [string]$_.kind -eq 'directory' })
        Assert-True ($specEntry.Count -eq 1 -and $dirEntry.Count -eq 1) 'the linked spec is content-hashed and the linked folder is recorded, not hashed'
        Assert-True ([string]$rec.approval_phrase -eq 'approved for before-implement') 'the record carries the approval phrase it presented'
    }

    # -----------------------------------------------------------------------------------------------
    Write-Host 'Case 2: the three recorded B4F-104 triggers do not repaint and raise no Stop error'
    $triggers = @(
        @{ Name = 'side question'; User = 'Quick question: which file holds the retry window?'; Reply = "The retry window is in the dispatcher, beside the journal writer.`n`n$mention" },
        @{ Name = 'wrong verdict'; User = 'approved for implement'; Reply = "That phrase names a different decision, so nothing was recorded. The open decision is the tasks boundary.`n`n$mention" },
        @{ Name = 'orientation request'; User = 'Where are we?'; Reply = "Feature 001 is at the tasks boundary, waiting for your verdict.`n`n$mention" }
    )
    foreach ($t in $triggers) {
        $r = Invoke-SessionTurn -Fixture $f -Session $s -UserText $t.User -Kind 'conversational' -Reply $t.Reply
        $j = Get-LastJournal -Fixture $f
        Assert-True (-not $r.Blocked) ("{0}: 0 blocks (no repaint, no Stop hook error)" -f $t.Name)
        Assert-True ((Get-JournalField $j 'presented_crossing') -eq 'presented-unchanged') ("{0}: the journal names the reason: presented-unchanged" -f $t.Name)
    }

    # -----------------------------------------------------------------------------------------------
    Write-Host 'Case 3: a bookkeeping commit (HEAD moves, no review target changes) does not repaint'
    $token3 = Start-SessionTurn -Fixture $f -Session $s -UserText 'Record that as drift and carry on.'
    Add-Content -LiteralPath $f.DriftLog -Value "`n### DRIFT-001 - recorded mid-session`n" -Encoding UTF8
    & git -C $f.Root add -A; & git -C $f.Root commit -q -m 'docs: drift entry'
    $r3 = Complete-SessionTurn -Fixture $f -Session $s -Token $token3 -Kind 'conversational' -UserText 'Record that as drift and carry on.' -Reply "Recorded as DRIFT-001 and committed.`n`n$mention"
    Assert-True (-not $r3.Blocked) 'a bookkeeping commit: 0 blocks'

    # -----------------------------------------------------------------------------------------------
    Write-Host 'Case 4: a compaction owes exactly one repaint'
    $null = Invoke-Pwsh -Root $f.Root -Script $provider -Arguments @('--host-kind', 'claude', '--source-event', 'SessionStart', '--session-id', $s, '--session-start-source', 'compact')
    $blocks4 = 0
    $r4a = Invoke-SessionTurn -Fixture $f -Session $s -UserText 'Continue.' -Kind 'conversational' -Reply "Picking up after the compaction.`n`n$mention"
    if ($r4a.Blocked) { $blocks4++ }
    $token4 = Start-SessionTurn -Fixture $f -Session $s -UserText 'Continue.'
    $r4b = Complete-SessionTurn -Fixture $f -Session $s -Token $token4 -Kind 'boundary' -UserText 'Continue.' -Reply (Get-Packet -Fixture $f -Note 'Presented again after the compaction.')
    if ($r4b.Blocked) { $blocks4++ }
    $r4c = Invoke-SessionTurn -Fixture $f -Session $s -UserText 'And the next file?' -Kind 'conversational' -Reply "The next file is the store.`n`n$mention"
    if ($r4c.Blocked) { $blocks4++ }
    Assert-True ($r4a.Blocked) 'the first turn after the compaction owes the packet'
    Assert-True ($blocks4 -eq 1) ("exactly one repaint after the compaction (measured {0})" -f $blocks4)
    if (Test-Path -LiteralPath $recordPath -PathType Leaf) {
        $rec4 = Get-Content -LiteralPath $recordPath -Raw -Encoding UTF8 | ConvertFrom-Json
        Assert-True ([string]$rec4.session_start_kind -eq 'compact') 'the new record says which gap it followed (compact)'
    }
    else { Write-Fail 'the re-presentation after the compaction wrote no record' }

    # -----------------------------------------------------------------------------------------------
    Write-Host 'Case 5: a capture miss reopens the packet (DRIFT-008), and the re-presented marker captures the next verdict'
    $pasted = "Here is the log you asked for:`n``````n2026-10-14 12:00 run ok`n``````n`napproved for before-implement"
    $token5 = Start-SessionTurn -Fixture $f -Session $s -UserText $pasted
    # No capture runs in this fixture, so the crossing stays pending exactly as it did when the paste hid the phrase.
    $r5a = Complete-SessionTurn -Fixture $f -Session $s -Token $token5 -Kind 'conversational' -UserText $pasted -Reply "Thanks for the log.`n`n$mention"
    Assert-True ($r5a.Blocked) 'a pending crossing whose verdict was not captured is owed again in the same session'
    Assert-True ($r5a.Output -match 'was not recorded') 'the block tells the agent the human''s approval did not register'
    Assert-True ((Get-JournalField (Get-LastJournal -Fixture $f) 'presented_crossing') -eq 'capture-miss') 'the journal names the reason: capture-miss'
    # The block force-continues the same turn, so the same token re-presents.
    $r5b = Complete-SessionTurn -Fixture $f -Session $s -Token $token5 -Kind 'boundary' -UserText $pasted -Reply (Get-Packet -Fixture $f -Note 'Your approval did not register, so here is the decision again.')
    Assert-True (-not $r5b.Blocked) 'the re-presentation ends the turn'
    $r5c = Invoke-SessionTurn -Fixture $f -Session $s -UserText 'One more question first: is the plan committed?' -Kind 'conversational' -Reply "Yes, it is committed.`n`n$mention"
    Assert-True (-not $r5c.Blocked) 'after the re-presentation, a presented and unchanged crossing with no capture miss is suppressed again'
    # Co-review round 3 (202): a question that MENTIONS the phrase is not an approval attempt, so its pending crossing is
    # not a capture miss - the question gets its answer without a repaint and without "your approval did not register".
    $r5q = Invoke-SessionTurn -Fixture $f -Session $s -UserText "What does 'approved for before-implement' mean?" -Kind 'conversational' -Reply "It authorizes implementation.`n`n$mention"
    Assert-True (-not $r5q.Blocked) 'a question quoting the approval phrase is answered without a repaint'
    $r5n = Invoke-SessionTurn -Fixture $f -Session $s -UserText 'I have not approved for before-implement yet; I am still reading.' -Kind 'conversational' -Reply "Take your time.`n`n$mention"
    Assert-True (-not $r5n.Blocked) 'a negated mention is not a capture miss either'
    # The next typed verdict, captured against the re-presented marker by the real prompt-time capture.
    $captureTranscript = Join-Path $f.Root '.specrew/runtime/transcript-capture.jsonl'
    $captureLines = @(
        ([pscustomobject]@{ type = 'assistant'; message = [pscustomobject]@{ role = 'assistant'; content = @([pscustomobject]@{ type = 'text'; text = (Get-Packet -Fixture $f -Note 'Your approval did not register, so here is the decision again.') }) } } | ConvertTo-Json -Depth 8 -Compress),
        ([pscustomobject]@{ type = 'user'; message = [pscustomobject]@{ role = 'user'; content = @([pscustomobject]@{ type = 'text'; text = 'approved for before-implement' }) } } | ConvertTo-Json -Depth 8 -Compress)
    )
    [System.IO.File]::WriteAllLines($captureTranscript, [string[]]$captureLines, [System.Text.UTF8Encoding]::new($false))
    $null = Invoke-Pwsh -Root $f.Root -Script $handover -Arguments @('--host-kind', 'claude', '--source-event', 'UserPromptSubmit', '--session-id', $s, '--transcript-path', $captureTranscript, '--last-user-message', 'approved for before-implement', '--turn-origin', 'typed-user')
    $pvAfter = Get-SpecrewPendingVerdictState -ProjectRoot $f.Root
    $authAfter = [string]$pvAfter.LastAuthorizedBoundary
    Assert-True ($authAfter -eq 'before-implement' -and -not [bool]$pvAfter.HasPendingVerdict) ("the re-presented marker captures the next typed verdict (last authorized: {0})" -f $authAfter)

    # -----------------------------------------------------------------------------------------------
    Write-Host 'Case 6: the other context gaps each owe the packet again'
    $g = New-PendingFixture; $fixtures.Add($g)
    $sg = 'sess-g'
    $null = Invoke-SessionTurn -Fixture $g -Session $sg -UserText 'Continue.' -Kind 'boundary' -Reply (Get-Packet -Fixture $g -Note 'Presented.')
    Add-Content -LiteralPath $g.Spec -Value "`nA requirement changed after the packet was shown.`n" -Encoding UTF8
    $r6a = Invoke-SessionTurn -Fixture $g -Session $sg -UserText 'Anything else?' -Kind 'conversational' -Reply "Nothing else.`n`n$mention"
    Assert-True ($r6a.Blocked -and (Get-JournalField (Get-LastJournal -Fixture $g) 'presented_crossing') -eq 'reviewed-artifacts-changed') 'a changed review target owes the packet (reviewed-artifacts-changed)'
    $null = Invoke-SessionTurn -Fixture $g -Session $sg -UserText 'Continue.' -Kind 'boundary' -Reply (Get-Packet -Fixture $g -Note 'Presented with the changed spec.')
    $gHash = Get-SpecrewTurnEndOwnerHash -HostKind 'claude' -SessionId $sg
    $gRecordPath = Join-Path $g.Root (".specrew/runtime/turn-end/{0}/presented-crossings.json" -f $gHash)
    $gRec = Get-Content -LiteralPath $gRecordPath -Raw -Encoding UTF8 | ConvertFrom-Json
    $gRec.presented_ms = [DateTimeOffset]::UtcNow.AddHours(-9).ToUnixTimeMilliseconds()
    $gRec.presented_at = [DateTimeOffset]::UtcNow.AddHours(-9).ToString('o')
    [System.IO.File]::WriteAllText($gRecordPath, ($gRec | ConvertTo-Json -Depth 8 -Compress), [System.Text.UTF8Encoding]::new($false))
    $r6b = Invoke-SessionTurn -Fixture $g -Session $sg -UserText 'Back after a long break.' -Kind 'conversational' -Reply "Welcome back.`n`n$mention"
    Assert-True ($r6b.Blocked -and (Get-JournalField (Get-LastJournal -Fixture $g) 'presented_crossing') -eq 'long-gap') 'nine hours after the presentation, the packet is owed (long-gap)'
    $r6c = Invoke-SessionTurn -Fixture $g -Session 'sess-other' -UserText 'Where are we?' -Kind 'conversational' -Reply "At the tasks boundary.`n`n$mention"
    Assert-True ($r6c.Blocked) 'another session owes its own presentation'
    $r6d = Invoke-SessionTurn -Fixture $g -Session '' -UserText 'Where are we?' -Kind 'conversational' -Reply "At the tasks boundary, unanchored.`n`n$mention"
    Assert-True ($r6d.Blocked) 'a session the host did not identify keeps today''s per-turn demand'

    # -----------------------------------------------------------------------------------------------
    Write-Host 'Case 7: the reply matcher'
    Assert-True (Test-SpecrewReplyCarriesApprovalPhrase -Reply $pasted -ApprovalPhrase 'approved for before-implement') 'finds the phrase after a pasted block'
    Assert-True (Test-SpecrewReplyCarriesApprovalPhrase -Reply 'APPROVED  for before-implement - start with T001' -ApprovalPhrase 'approved for before-implement') 'is case- and spacing-insensitive and allows instructions after the phrase'
    Assert-True (-not (Test-SpecrewReplyCarriesApprovalPhrase -Reply 'approved for implement' -ApprovalPhrase 'approved for before-implement')) 'does not read a different boundary as this one'
    Assert-True (-not (Test-SpecrewReplyCarriesApprovalPhrase -Reply 'approved for before-implementation' -ApprovalPhrase 'approved for before-implement')) 'does not match inside a longer word'
    foreach ($mention in "What does 'approved for before-implement' mean?", 'Should I type approved for before-implement now?', 'I have not approved for before-implement yet.', "Don't record approved for before-implement.", 'approved for before-implement?', 'approved for before-implement? I am still deciding.') {
        Assert-True (-not (Test-SpecrewReplyCarriesApprovalPhrase -Reply $mention -ApprovalPhrase 'approved for before-implement')) ("a mention, question or refusal is not an approval attempt: '{0}'" -f $mention)
    }
    foreach ($attempt in 'Yes, approved for before-implement', "  approved for before-implement.`nAlso run the lint.", 'approved for before-implement - is the plan committed?') {
        Assert-True (Test-SpecrewReplyCarriesApprovalPhrase -Reply $attempt -ApprovalPhrase 'approved for before-implement') ("an approval attempt still counts: '{0}'" -f ($attempt -replace "`n", ' / '))
    }
}
finally {
    foreach ($fx in $fixtures) { try { Remove-Item -LiteralPath $fx.Root -Recurse -Force -ErrorAction SilentlyContinue } catch { $null = $_ } }
    $env:SPECREW_MODULE_PATH = $savedModulePath
}
if ($script:failCount -gt 0) { throw ("crossing-presentation: {0} assertion(s) failed" -f $script:failCount) }
Write-Host 'crossing-presentation: all assertions passed' -ForegroundColor Green
