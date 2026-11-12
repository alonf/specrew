# Feature 203 iteration 001, T013 (FR-042): every mint path has its no-human-turn fault fixtures and its non-approval phrase
# fixtures (quoted, in backticks, pasted), each paired with the legitimate path, in one table.
#
# Every typed act is read by one classifier, Resolve-SpecrewTypedAct (T003), and every writer re-derives its act through it
# from the cited turn (T004, Write-SpecrewTypedAct / Read-SpecrewCitedTypedTurn), so a case here is a case for the prompt
# hook, the turn end and the writer CLIs alike. typed-act-classifier.Tests.ps1 holds the cases this project met in the
# field; this suite is the matrix, so a mint path added later has to add a row, and a row with an empty cell fails.
#
# The mint paths (the T013 inventory, 2026-11-12): the boundary verdict, the top-up (allowance reset), the pause decision
# (`stop the review here`), the four phrased stop answers (defer, drop, fix, allow reviewer), a judgment answer, partial
# sign-off, the coverage deferral, the workshop repair and a workshop reply. A judgment answer and a workshop reply are
# any text, so they have no phrase to quote; their phrase cells are 'n/a' and only the no-human-turn cells apply. The
# design decision is minted from a cited turn by its own CLI and has its matrix in design-decision-cited-turn.tests.ps1.
Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'
$repoRoot = (Resolve-Path (Join-Path $PSScriptRoot '..\..')).Path
. (Join-Path $repoRoot 'scripts\internal\bootstrap\HumanAuthorityStore.ps1')
. (Join-Path $repoRoot 'scripts\internal\bootstrap\ConversationCaptureAccessor.ps1')
# The coverage deferral's recognizer lives in shared-governance, which every caller of the classifier has loaded.
. (Join-Path $repoRoot 'extensions\specrew-speckit\scripts\shared-governance.ps1')
$script:failCount = 0
$script:passCount = 0
function Write-Pass { param([string]$Message) $script:passCount++ }
function Write-Fail { param([string]$Message) Write-Host "FAIL: $Message" -ForegroundColor Red; $script:failCount++ }
function Assert-True { param([bool]$Condition, [string]$Message) if ($Condition) { Write-Pass $Message } else { Write-Fail $Message } }

function New-Turn {
    param([string]$Text, [string]$HostKind = 'claude', [string]$Id = 'msg-1', [string]$Origin = 'typed-user', [string]$Identity = 'declared', [switch]$Compact)
    $t = [pscustomobject]@{ host = $HostKind; message_id = $Id; message_identity = $Identity; origin = $Origin; text = $Text }
    if ($Compact) { $t | Add-Member -NotePropertyName is_compact_summary -NotePropertyValue $true }
    return $t
}
function New-Pending {
    param([string]$From, [string]$To, [string]$PauseKind, [string]$Question)
    [pscustomobject]@{
        Crossing         = if ($To) { [pscustomobject]@{ From = $From; To = $To; StageEvidenceAbsent = $false } } else { $null }
        Pause            = if ($PauseKind) { [pscustomobject]@{ Kind = $PauseKind; Id = 'pause-1' } } else { $null }
        WorkshopQuestion = if ($Question) { [pscustomobject]@{ Id = $Question } } else { $null }
    }
}

# One row per mint path. Phrase: the line the human types; Pending: what waits for it; Kind and Answer: the act the
# legitimate path yields. Phrase $null: the act is any text, so the phrase cells do not apply.
$paths = @(
    @{ Id = 'boundary-verdict'; Phrase = 'approved for tasks'; Text = 'approved for tasks'; Pending = (New-Pending -From 'plan' -To 'tasks'); Kind = 'boundary-verdict'; Answer = '' }
    @{ Id = 'top-up'; Phrase = 'approved for allowance reset'; Text = 'approved for allowance reset'; Pending = (New-Pending -PauseKind 'a-budget-spent'); Kind = 'top-up'; Answer = '' }
    @{ Id = 'pause-decision'; Phrase = 'stop the review here'; Text = 'stop the review here'; Pending = (New-Pending -PauseKind 'b-dispute-or-defer'); Kind = 'stop-answer'; Answer = 'stop-review' }
    @{ Id = 'stop-answer-defer'; Phrase = 'defer finding F2 to B5F-030'; Text = 'defer finding F2 to B5F-030'; Pending = (New-Pending -PauseKind 'b-dispute-or-defer'); Kind = 'stop-answer'; Answer = 'defer' }
    @{ Id = 'stop-answer-drop'; Phrase = 'drop finding F1'; Text = 'drop finding F1'; Pending = (New-Pending -PauseKind 'b-dispute-or-defer'); Kind = 'stop-answer'; Answer = 'drop' }
    @{ Id = 'stop-answer-fix'; Phrase = 'fix finding F1'; Text = 'fix finding F1'; Pending = (New-Pending -PauseKind 'b-dispute-or-defer'); Kind = 'stop-answer'; Answer = 'fix' }
    @{ Id = 'stop-answer-allow-reviewer'; Phrase = 'allow reviewer claude'; Text = 'allow reviewer claude'; Pending = (New-Pending -PauseKind 'd-host-outside-order'); Kind = 'stop-answer'; Answer = 'allow-reviewer' }
    @{ Id = 'stop-answer-judgment'; Phrase = $null; Text = 'keep the stricter check; the reviewer is right'; Pending = (New-Pending -PauseKind 'c-judgment'); Kind = 'stop-answer'; Answer = 'judgment' }
    @{ Id = 'partial-signoff'; Phrase = 'approved for partial review signoff - the tree moved after records-only fixes'; Text = 'approved for partial review signoff - the tree moved after records-only fixes'; Pending = (New-Pending); Kind = 'partial-signoff'; Answer = '' }
    @{ Id = 'coverage-deferral'; Phrase = 'continue without coverage until the review phase'; Text = 'continue without coverage until the review phase'; Pending = (New-Pending); Kind = 'coverage-deferral'; Answer = '' }
    @{ Id = 'workshop-repair'; Phrase = 'approved for workshop repair'; Text = 'approved for workshop repair'; Pending = (New-Pending); Kind = 'workshop-repair'; Answer = '' }
    @{ Id = 'workshop-reply'; Phrase = $null; Text = 'two kinds of user: admins and guests'; Pending = (New-Pending -Question 'pd-users'); Kind = 'workshop-reply'; Answer = '' }
)

function Get-Act { param($Turn, $Pending) Resolve-SpecrewTypedAct -Turn $Turn -Pending $Pending }

# A cross-session (peer) message: another Claude session's message, delivered to the prompt hook as a prompt (reviewer
# ruling 2026-11-12, under the maintainer's delegation). The wrapper is verbatim from a real transcript record
# (fixtures claude/peer-message; assembled, see its provenance.json). The dispatcher gives it origin typed-user today
# (turn-record-contract.tests.ps1 proves that seam), so the cell feeds it to the classifier with that origin: whatever
# the origin rule says, a peer message must mint nothing.
$peerShape = Get-Content -LiteralPath (Join-Path $repoRoot 'tests\fixtures\hook-payloads\claude\peer-message\peer-message-shape.json') -Raw | ConvertFrom-Json
function New-PeerText { param([string]$Body) return ([string]$peerShape.prefix + $Body + [string]$peerShape.suffix) }
$peerHookPrompt = [string]((Get-Content -LiteralPath (Join-Path $repoRoot 'tests\fixtures\hook-payloads\claude\tui-userpromptsubmit-peer-message.json') -Raw | ConvertFrom-Json).prompt)
$peerHookPrefix = $peerHookPrompt.Substring(0, $peerHookPrompt.IndexOf("`n") + 1)
$recordShapes = @((Get-Content -LiteralPath (Join-Path $repoRoot 'tests\fixtures\hook-payloads\claude\transcript-origins\record-shapes.json') -Raw | ConvertFrom-Json).shapes)
function Test-Minted { param($Act) [string]$Act.Kind -cne 'none' }

$matrix = [ordered]@{}
foreach ($p in $paths) {
    $id = [string]$p.Id
    $cells = [ordered]@{}

    # (e) The legitimate path, which every fault cell is paired with.
    $legit = Get-Act (New-Turn -Text $p.Text) $p.Pending
    $ok = ([string]$legit.Kind -ceq [string]$p.Kind) -and ([string]::IsNullOrEmpty([string]$p.Answer) -or [string]$legit.Answer -ceq [string]$p.Answer)
    Assert-True $ok ("{0}: the typed line mints {1} (got {2}/{3}/{4})" -f $id, $p.Kind, $legit.Kind, $legit.Answer, $legit.Reason)
    $cells['legitimate'] = $ok

    # (a) No human turn: host-injected text, a compaction summary quoting it, an origin the dispatcher could not confirm.
    $a = Get-Act (New-Turn -Text $p.Text -Origin 'host-injected') $p.Pending
    Assert-True ((-not (Test-Minted $a)) -and [string]$a.Reason -ceq 'not-human' -and -not [bool]$a.Report) ("{0}: host-injected mints nothing and is not reported (got {1}/{2})" -f $id, $a.Kind, $a.Reason)
    $c = Get-Act (New-Turn -Text $p.Text -Compact) $p.Pending
    Assert-True ((-not (Test-Minted $c)) -and [string]$c.Reason -ceq 'not-human' -and -not [bool]$c.Report) ("{0}: a compaction summary mints nothing and is not reported (got {1}/{2})" -f $id, $c.Kind, $c.Reason)
    $u = Get-Act (New-Turn -Text $p.Text -Origin 'unknown') $p.Pending
    Assert-True (-not (Test-Minted $u)) ("{0}: an unconfirmed origin mints nothing (got {1}/{2})" -f $id, $u.Kind, $u.Reason)
    if ($null -ne $p.Phrase) {
        Assert-True ([string]$u.Reason -ceq 'origin-unconfirmed' -and [bool]$u.Report) ("{0}: an unconfirmed origin with the act's shape is reported (got {1}/{2})" -f $id, $u.Reason, $u.Report)
    }
    $cells['no-human-turn'] = -not ((Test-Minted $a) -or (Test-Minted $c) -or (Test-Minted $u))

    # (a') A peer message whose body is the act's text alone on its own line, on Claude, with the origin it gets today.
    $peer = Get-Act (New-Turn -Text (New-PeerText -Body ([string]$p.Text))) $p.Pending
    Assert-True (-not (Test-Minted $peer)) ("{0}: a cross-session (peer) message mints nothing (got {1}/{2}/{3})" -f $id, $peer.Kind, $peer.Answer, $peer.Reason)
    # The prompt hook's input for the same message is the wrapper alone (recorded, claude/tui-userpromptsubmit-peer-message.json).
    $peerHook = Get-Act (New-Turn -Text ([string]$peerHookPrefix + [string]$p.Text + "`n</cross-session-message>")) $p.Pending
    Assert-True (-not (Test-Minted $peerHook)) ("{0}: a peer message as the prompt hook receives it mints nothing (got {1}/{2}/{3})" -f $id, $peerHook.Kind, $peerHook.Answer, $peerHook.Reason)
    $cells['peer-message'] = -not ((Test-Minted $peer) -or (Test-Minted $peerHook))

    # (a'') The transcript record decides (maintainer ruling 2026-11-12): a turn is the human's only when its record says
    # turnOrigin human with promptSource typed or queued. A scheduled prompt is raw text the session wrote when it
    # scheduled the task, with no wrapper, so no text rule can see it; it reaches the classifier with the origin the
    # dispatcher gives every prompt today (typed-user) and its whole text the act. Shapes from a real transcript
    # (fixtures claude/transcript-origins/record-shapes.json); no live phrase is typed in this repository.
    $recordOk = $true
    foreach ($shape in @($recordShapes)) {
        $t = New-Turn -Text ([string]$p.Text)
        $t | Add-Member -NotePropertyName record_turn_origin -NotePropertyValue ([string]$shape.turnOrigin)
        $t | Add-Member -NotePropertyName record_prompt_source -NotePropertyValue $(if ($null -eq $shape.promptSource) { '' } else { [string]$shape.promptSource })
        $t | Add-Member -NotePropertyName record_origin_kind -NotePropertyValue $(if ($null -eq $shape.origin_kind) { '' } else { [string]$shape.origin_kind })
        $t | Add-Member -NotePropertyName record_is_meta -NotePropertyValue $shape.isMeta
        if ($shape.PSObject.Properties['record']) {
            # B5F-070: a message typed mid-turn is a queued_command record, not a user record.
            $t | Add-Member -NotePropertyName record_kind -NotePropertyValue ([string]$shape.record)
            $t | Add-Member -NotePropertyName record_human_turn -NotePropertyValue $shape.human_turn
            $t | Add-Member -NotePropertyName record_command_mode -NotePropertyValue ([string]$shape.command_mode)
        }
        $got = Get-Act $t $p.Pending
        # The shape's expected answer (maintainer ruling 2026-11-12). A record with no fields leaves the text rules to decide,
        # and this typed line passes them.
        $human = [bool]$shape.accepted
        $ok = if ($human) { [string]$got.Kind -ceq [string]$p.Kind } else { -not (Test-Minted $got) }
        Assert-True $ok ("{0}: a turn whose transcript record is {1} {2} (got {3}/{4}/{5})" -f $id, $shape.kind, $(if ($human) { 'mints' } else { 'mints nothing' }), $got.Kind, $got.Answer, $got.Reason)
        if (-not $ok) { $recordOk = $false }
    }
    $cells['record-origin'] = $recordOk

    if ($null -eq $p.Phrase) {
        $cells['quoted'] = 'n/a'; $cells['backticks'] = 'n/a'; $cells['pasted'] = 'n/a'
        $matrix[$id] = $cells
        continue
    }
    $phrase = [string]$p.Phrase

    # (b) Quoted, as the human cites the phrase rather than says it.
    $quoted = @(('"{0}"' -f $phrase), ("'{0}'" -f $phrase), ('you said "{0}" earlier' -f $phrase))
    $quotedMinted = @($quoted | Where-Object { Test-Minted (Get-Act (New-Turn -Text $_) $p.Pending) })
    Assert-True ($quotedMinted.Count -eq 0) ("{0}: a quoted phrase mints nothing (minted: {1})" -f $id, ($quotedMinted -join ' | '))
    $cells['quoted'] = ($quotedMinted.Count -eq 0)

    # (c) In backticks, alone and inside a sentence.
    $ticked = @(('`{0}`' -f $phrase), ('type `{0}` when ready' -f $phrase))
    $tickedMinted = @($ticked | Where-Object { Test-Minted (Get-Act (New-Turn -Text $_) $p.Pending) })
    Assert-True ($tickedMinted.Count -eq 0) ("{0}: a phrase in backticks mints nothing (minted: {1})" -f $id, ($tickedMinted -join ' | '))
    $cells['backticks'] = ($tickedMinted.Count -eq 0)

    # (d) Pasted. Claude marks a paste; a phrase inside one is not the human's own line, alone or with a paste around it.
    # Copilot and Codex do not mark pastes; a paste reaches them as one message of many lines, which the one-line rule
    # refuses. Paired with the legitimate path below: the phrase typed on its own line under a Claude paste mints.
    $pasteBody = "line one of a pasted log`nline two of a pasted log"
    $pastes = @(
        @{ Host = 'claude'; Text = ('<pasted_content id="p1">{0}{1}{0}</pasted_content id="p1">' -f "`n", $phrase) }
        @{ Host = 'claude'; Text = ('<pasted_content id="p2">{0}{1}{0}{2}{0}</pasted_content id="p2">' -f "`n", $phrase, $pasteBody) }
        @{ Host = 'claude'; Text = ('<pasted_content id="p3">{0}{1}{0}{2}{0}' -f "`n", $phrase, $pasteBody) }
        @{ Host = 'copilot'; Text = ('{0}{1}{2}' -f $phrase, "`n", $pasteBody); Identity = 'stand-in' }
        @{ Host = 'codex'; Text = ('{0}{1}{2}' -f $phrase, "`n", $pasteBody) }
    )
    $pasteMinted = @()
    foreach ($paste in $pastes) {
        $identity = if ($paste.ContainsKey('Identity')) { [string]$paste.Identity } else { 'declared' }
        $act = Get-Act (New-Turn -Text ([string]$paste.Text) -HostKind ([string]$paste.Host) -Identity $identity) $p.Pending
        if (Test-Minted $act) { $pasteMinted += ('{0}: {1}' -f $paste.Host, ($paste.Text -replace "`n", ' / ')) }
    }
    Assert-True ($pasteMinted.Count -eq 0) ("{0}: a pasted phrase mints nothing on Claude, Copilot or Codex (minted: {1})" -f $id, ($pasteMinted -join ' || '))
    $below = Get-Act (New-Turn -Text ('<pasted_content id="p4">{0}{1}{0}</pasted_content id="p4">{0}{2}' -f "`n", $pasteBody, $phrase)) $p.Pending
    Assert-True ([string]$below.Kind -ceq [string]$p.Kind) ("{0}: the phrase typed on its own line under a Claude paste mints {1} (got {2}/{3})" -f $id, $p.Kind, $below.Kind, $below.Reason)
    $continuesOk = $true
    if ($id -ceq 'partial-signoff') {
        # Maintainer ruling 2026-11-12: the partial sign-off's reason is the phrase's own line on every host. On Claude, text
        # typed on the lines after it (no paste marks) refuses as it does on Copilot and Codex, and the human is told.
        $typedOn = Get-Act (New-Turn -Text ($phrase + "`nand one more thought typed below it")) $p.Pending
        $continuesOk = (-not (Test-Minted $typedOn)) -and [bool]$typedOn.Report
        Assert-True $continuesOk ("{0}: on Claude a message typed on past the phrase's line mints nothing and is reported (got {1}/{2}/report={3})" -f $id, $typedOn.Kind, $typedOn.Reason, $typedOn.Report)
    }
    $cells['pasted'] = ($pasteMinted.Count -eq 0) -and ([string]$below.Kind -ceq [string]$p.Kind) -and $continuesOk
    $matrix[$id] = $cells
}

# The matrix itself: a row with a cell that is neither proven nor 'n/a' fails, so a mint path added without its fixtures
# cannot pass by having none.
foreach ($id in $matrix.Keys) {
    foreach ($cell in $matrix[$id].Keys) {
        $value = $matrix[$id][$cell]
        Assert-True ((($value -is [bool]) -and $value) -or (($value -is [string]) -and $value -ceq 'n/a')) ("matrix {0} / {1}: proven" -f $id, $cell)
    }
}
Write-Host ''
Write-Host ('{0,-28} {1,-11} {2,-14} {3,-6} {4,-7} {5,-7} {6,-10} {7}' -f 'mint path', 'legitimate', 'no-human-turn', 'peer', 'record', 'quoted', 'backticks', 'pasted')
foreach ($id in $matrix.Keys) {
    $r = $matrix[$id]
    $show = { param($v) if ($v -is [string]) { [string]$v } elseif ($v -eq $true) { 'ok' } else { 'FAIL' } }
    Write-Host ('{0,-28} {1,-11} {2,-14} {3,-6} {4,-7} {5,-7} {6,-10} {7}' -f $id, (& $show $r['legitimate']), (& $show $r['no-human-turn']), (& $show $r['peer-message']), (& $show $r['record-origin']), (& $show $r['quoted']), (& $show $r['backticks']), (& $show $r['pasted']))
}

if ($script:failCount -gt 0) { Write-Host "mint-path-fixtures: $($script:failCount) failure(s), $($script:passCount) passed" -ForegroundColor Red; exit 1 }
Write-Host "mint-path-fixtures: all $($script:passCount) passed" -ForegroundColor Green
exit 0
