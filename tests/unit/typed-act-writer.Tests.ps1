# Feature 203 iteration 001, T004 (FR-021, FR-022, FR-025): the re-deriving writer and the supersession fact.
#
# Two cases this project met, each RED against the build before T004:
#   1 THE CITED TURN (spec US2 scenario 5, FR-022). An agent cites the maintainer's real `confirm` turn and asks a writer
#     for a verdict. Today the boundary writer takes a captured evidence label on the caller's word and records the
#     verdict. After T004 a captured label is honoured only by re-reading the cited turn and re-deriving its act through
#     the classifier (Resolve-SpecrewTypedAct): `confirm` is no verdict, so nothing is recorded; the real typed verdict
#     is recorded once and a second citation of it is already-recorded.
#   2 THE RE-TYPED ROUND APPROVAL (02:44 local, 2026-11-02; DRIFT-019, DRIFT-023; FR-021): removed with the per-round
#     approval by feature 203 T008 (FR-010; DRIFT-052), together with cases 3 to 6, 10b, 12 and 15, which were about
#     its slot. The cases that proved a general rule through it (a reply typed while the turn ends, a retype, recovery,
#     the ledger, the date a recovered act carries) now prove it through the allowance reset, the typed act that remains.
#
# Each case runs in a temporary project root. Never the
# repository's own stores: a host's project-root variables are cleared in this process and in every child launch (run
# inside a Claude session, CLAUDE_PROJECT_DIR names the real worktree), and the suite fails if the real worktree's
# round-approval store or the real ~/.specrew changed during the run.
Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'
$repoRoot = (Resolve-Path (Join-Path $PSScriptRoot '..\..')).Path
$script:failCount = 0
function Write-Pass { param([string]$Message) Write-Host "PASS: $Message" -ForegroundColor Green }
function Write-Fail { param([string]$Message) Write-Host "FAIL: $Message" -ForegroundColor Red; $script:failCount++ }
function Assert-True { param([bool]$Condition, [string]$Message) if ($Condition) { Write-Pass $Message } else { Write-Fail $Message } }
$script:roots = [System.Collections.Generic.List[string]]::new()

# The host project-root variables, as the T001 probes cleared them; any other *_PROJECT_DIR is cleared too.
$script:hostRootVariablePattern = '^(CLAUDE_PROJECT_DIR|CURSOR_PROJECT_DIR|COPILOT_PROJECT_DIR|\w+_PROJECT_DIR)$'
$script:clearedHostRoots = [ordered]@{}
foreach ($entry in @(Get-ChildItem Env: | Where-Object { $_.Name -match $script:hostRootVariablePattern })) {
    $script:clearedHostRoots[$entry.Name] = [string]$entry.Value
    Remove-Item -LiteralPath ('Env:' + $entry.Name) -ErrorAction SilentlyContinue
}

# The real stores this suite must never touch: the round-approval store of this checkout and of any project a cleared
# variable named (the real worktree when run inside a session), and the real user profile's .specrew, resolved from the
# OS rather than from USERPROFILE so a lane's redirected home does not hide it.
$script:guardedPaths = [System.Collections.Generic.List[string]]::new()
foreach ($projectRoot in @(@($repoRoot) + @($script:clearedHostRoots.Values) | Where-Object { $_ } | ForEach-Object { [IO.Path]::GetFullPath($_) } | Sort-Object -Unique)) {
    $script:guardedPaths.Add((Join-Path $projectRoot '.specrew\review\round-approval'))
}
$script:guardedPaths.Add((Join-Path ([Environment]::GetFolderPath('UserProfile')) '.specrew'))
function Get-GuardSnapshot {
    $lines = foreach ($path in $script:guardedPaths) {
        if (-not (Test-Path -LiteralPath $path)) { "$path|absent"; continue }
        foreach ($item in @(Get-ChildItem -LiteralPath $path -Recurse -Force -ErrorAction SilentlyContinue)) {
            if ($item.PSIsContainer) { "$($item.FullName)|dir" }
            else { '{0}|{1}|{2}' -f $item.FullName, $item.Length, $item.LastWriteTimeUtc.Ticks }
        }
    }
    return @($lines | Sort-Object)
}
$script:guardBefore = Get-GuardSnapshot

. (Join-Path $repoRoot 'extensions\specrew-speckit\scripts\shared-governance.ps1')
. (Join-Path $repoRoot 'scripts\internal\bootstrap\HumanAuthorityStore.ps1')
$reviewCli = Join-Path $repoRoot 'scripts\specrew-review.ps1'

# A writer parameter T004 adds is passed only when the writer has it, so the RED is the behaviour, not a binding error.
function Add-IfSupported {
    param([hashtable]$Splat, [string]$Command, [string]$Name, $Value)
    if ((Get-Command $Command).Parameters.ContainsKey($Name)) { $Splat[$Name] = $Value }
}

# ---------------------------------------------------------------------------------------------------
# Case 1 fixture: a project waiting at tasks -> before-implement, and the host's record of two typed turns.
function New-CitedTurnFixture {
    $root = Join-Path ([System.IO.Path]::GetTempPath()) ('t004-cite-' + [guid]::NewGuid().ToString('N').Substring(0, 10))
    $script:roots.Add($root)
    $feature = Join-Path $root 'specs\001-feat'
    New-Item -ItemType Directory -Force -Path (Join-Path $root '.specrew') | Out-Null
    New-Item -ItemType Directory -Force -Path (Join-Path $feature 'iterations\001\quality') | Out-Null
    Set-Content -LiteralPath (Join-Path $feature 'spec.md') -Value "# Feature Specification: Feat`n`nBody." -Encoding UTF8
    foreach ($rel in 'plan.md', 'state.md', 'quality/hardening-gate.md') {
        Set-Content -LiteralPath (Join-Path $feature ('iterations\001\' + $rel)) -Value ("# {0}`n`n**Status**: fixture" -f $rel) -Encoding UTF8
    }
    Set-Content -LiteralPath (Join-Path $feature 'tasks.md') -Value "# Tasks`n`n- [ ] T001 fixture" -Encoding UTF8
    Set-Content -LiteralPath (Join-Path $root '.gitignore') -Value ".specrew/`n" -Encoding UTF8
    & git -C $root init -q -b main
    & git -C $root config user.email 't@t'
    & git -C $root config user.name 't'
    & git -C $root -c core.autocrlf=false add -A
    & git -C $root commit -q -m fixture
    $head = ([string](& git -C $root rev-parse HEAD)).Trim()
    $context = [ordered]@{
        schema = 'v2'
        boundary_enforcement = [ordered]@{
            enabled = $true; last_authorized_boundary = 'tasks'; pending_next_boundary = $null
            policy_classes = [ordered]@{
                specify = 'human-judgment-required'; clarify = 'human-judgment-required'; plan = 'human-judgment-required'
                tasks = 'human-judgment-required'; 'before-implement' = 'human-judgment-required'
                'review-signoff' = 'human-judgment-required'; retro = 'human-judgment-required'
                'iteration-closeout' = 'human-judgment-required'; 'feature-closeout' = 'human-judgment-required'
            }
            verdict_history = @(); bypass_history = @()
        }
        generated_at_utc = '2026-11-02T00:00:00Z'
        session_state = [ordered]@{
            active = $true; boundary_type = 'before-implement'; feature_ref = '001-feat'; feature_path = $feature
            iteration_number = '001'; auth_commit_hash = $head; recorded_at = '2026-11-02T00:00:00Z'
        }
    }
    [System.IO.File]::WriteAllText((Join-Path $root '.specrew\start-context.json'), ($context | ConvertTo-Json -Depth 12), [System.Text.UTF8Encoding]::new($false))
    $null = Set-SpecrewPendingBoundaryCrossingScope -ProjectRoot $root -WorkingBoundary 'before-implement' -BoundaryCommitHash $head -RecordedAt '2026-11-02T00:00:01Z' 2>$null

    # The host's record: Claude's transcript, in the recorded shape (tests/fixtures/hook-payloads/claude/queued).
    $session = 'session-t004'
    $lines = @(
        [ordered]@{ type = 'assistant'; uuid = 'a-1'; sessionId = $session; timestamp = '2026-11-02T08:00:00.000Z'
            message = [ordered]@{ role = 'assistant'; content = @([ordered]@{ type = 'text'; text = 'Does this agenda look right?' }) } }
        [ordered]@{ type = 'user'; uuid = 'u-confirm'; promptId = 'prompt-confirm'; sessionId = $session; timestamp = '2026-11-02T08:01:00.000Z'
            origin = [ordered]@{ kind = 'human' }; turnOrigin = 'human'; promptSource = 'typed'; message = [ordered]@{ role = 'user'; content = 'confirm' } }
        [ordered]@{ type = 'assistant'; uuid = 'a-2'; sessionId = $session; timestamp = '2026-11-02T08:02:00.000Z'
            message = [ordered]@{ role = 'assistant'; content = @([ordered]@{ type = 'text'; text = 'Type approved for before-implement to start.' }) } }
        [ordered]@{ type = 'user'; uuid = 'u-verdict'; promptId = 'prompt-verdict'; sessionId = $session; timestamp = '2026-11-02T08:03:00.000Z'
            origin = [ordered]@{ kind = 'human' }; turnOrigin = 'human'; promptSource = 'typed'; message = [ordered]@{ role = 'user'; content = 'approved for before-implement' } }
    )
    $transcript = Join-Path $root 'transcript.jsonl'
    [System.IO.File]::WriteAllLines($transcript, [string[]]@($lines | ForEach-Object { $_ | ConvertTo-Json -Depth 8 -Compress }), [System.Text.UTF8Encoding]::new($false))
    return [pscustomobject]@{ Root = $root; Transcript = $transcript; Session = $session }
}
function Get-VerdictHistory {
    param([string]$Root)
    $ctx = Get-Content -LiteralPath (Join-Path $Root '.specrew\start-context.json') -Raw -Encoding UTF8 | ConvertFrom-Json -Depth 12
    return @($ctx.boundary_enforcement.verdict_history | Where-Object { $null -ne $_ })
}
function Invoke-AgentBoundaryWrite {
    # What an agent can do today: dot-source the writer and call it with a captured evidence label.
    param($Fixture, [string]$TurnIdentity)
    $splat = @{
        ProjectRoot = $Fixture.Root; CurrentBoundary = 'tasks'; AuthorizedBoundary = 'before-implement'; AuthorizingHuman = 'unattributed'
        VerdictText = 'approved for before-implement'; EvidenceSource = 'hook-captured-from-transcript'
    }
    if ($TurnIdentity) {
        Add-IfSupported -Splat $splat -Command 'Add-SpecrewBoundaryAuthorization' -Name 'TurnIdentity' -Value $TurnIdentity
        Add-IfSupported -Splat $splat -Command 'Add-SpecrewBoundaryAuthorization' -Name 'TranscriptPath' -Value $Fixture.Transcript
        Add-IfSupported -Splat $splat -Command 'Add-SpecrewBoundaryAuthorization' -Name 'HostKind' -Value 'claude'
    }
    try { $null = Add-SpecrewBoundaryAuthorization @splat 2>$null; return 'returned' } catch { return ('refused: ' + $_.Exception.Message) }
}

Write-Host '--- case 1: an agent cites the real `confirm` turn to a writer (FR-022) ---'
$f1 = New-CitedTurnFixture
$outcome1 = Invoke-AgentBoundaryWrite -Fixture $f1 -TurnIdentity 'prompt-confirm'
Assert-True (@(Get-VerdictHistory -Root $f1.Root).Count -eq 0) "citing the 'confirm' turn records no verdict (writer $outcome1)"

$f1b = New-CitedTurnFixture
$outcome1b = Invoke-AgentBoundaryWrite -Fixture $f1b -TurnIdentity ''
Assert-True (@(Get-VerdictHistory -Root $f1b.Root).Count -eq 0) "a captured label with no cited turn records no verdict (writer $outcome1b)"

$hasWriter = $null -ne (Get-Command 'Write-SpecrewTypedAct' -ErrorAction SilentlyContinue)
Assert-True $hasWriter 'Write-SpecrewTypedAct exists: the only writer for the recovery paths'
if ($hasWriter) {
    $f1c = New-CitedTurnFixture
    $confirm = Write-SpecrewTypedAct -ProjectRoot $f1c.Root -HostKind 'claude' -TurnIdentity 'prompt-confirm' -TranscriptPath $f1c.Transcript
    Assert-True ([string]$confirm.Act.Kind -cne 'boundary-verdict' -and -not [bool]$confirm.Written) ("the re-derived act of 'confirm' is no verdict and nothing is written (got {0}/{1})" -f $confirm.Act.Kind, $confirm.Act.Reason)
    Assert-True (@(Get-VerdictHistory -Root $f1c.Root).Count -eq 0) "the ledger holds no verdict after citing 'confirm'"

    $typed = Write-SpecrewTypedAct -ProjectRoot $f1c.Root -HostKind 'claude' -TurnIdentity 'prompt-verdict' -TranscriptPath $f1c.Transcript
    $history = @(Get-VerdictHistory -Root $f1c.Root)
    Assert-True ([string]$typed.Act.Kind -ceq 'boundary-verdict' -and [bool]$typed.Written -and $history.Count -eq 1) 'the real typed verdict, cited, is recorded once'
    Assert-True ($history.Count -eq 1 -and $history[0].PSObject.Properties['turn_identity'] -and [string]$history[0].turn_identity -ceq [string]$typed.Act.TurnIdentity) 'the ledger entry carries the turn identity it was derived from'
    $again = Write-SpecrewTypedAct -ProjectRoot $f1c.Root -HostKind 'claude' -TurnIdentity 'prompt-verdict' -TranscriptPath $f1c.Transcript
    Assert-True (-not [bool]$again.Written -and [string]$again.Act.Reason -ceq 'already-recorded' -and @(Get-VerdictHistory -Root $f1c.Root).Count -eq 1) 'citing the same turn again records nothing (already-recorded)'
    $unknown = Write-SpecrewTypedAct -ProjectRoot $f1c.Root -HostKind 'claude' -TurnIdentity 'prompt-not-in-the-record' -TranscriptPath $f1c.Transcript
    Assert-True (-not [bool]$unknown.Written -and @(Get-VerdictHistory -Root $f1c.Root).Count -eq 1) ("a turn the host's record does not hold mints nothing (got {0})" -f $unknown.Act.Reason)
}

# ---------------------------------------------------------------------------------------------------
# ---------------------------------------------------------------------------------------------------
# The engine's facts are written here in the engine's own shapes (case 14 uses them). Feature 203 T008 removed the
# per-round approval, and with it cases 2 to 6 (the re-typed round approval, the round-7 shape and its routes).
function Write-EngineFact { param([string]$Path, [System.Collections.IDictionary]$Fact)
    New-Item -ItemType Directory -Force -Path (Split-Path -Parent $Path) | Out-Null
    Set-Content -LiteralPath $Path -Value ([pscustomobject]$Fact | ConvertTo-Json -Compress -Depth 8) -Encoding UTF8 -NoNewline
}
$campaignId = 'cmp-001-fixture-i001'

# ---------------------------------------------------------------------------------------------------
# Case 7 (maintainer's UX ruling, 2026-11-04, 19:05 local): A REPLY TYPED WHILE THE TURN IS STILL ENDING JUST WORKS. A
# human answers a question when they see it, which is often while the Stop hook is still running. Claude hands that
# queued reply to the prompt hook with the RUNNING turn's prompt id (DRIFT-006, measured on Claude Code 2.1.314), and
# its transcript entry may carry the same id. Keyed on the id alone, the reply read as the running turn, already
# recorded, and was dropped without a word. It must be recorded once as its own act, and the next turn acts on it: for
# an option answer such as `1` and for `approved for allowance reset`. Every step runs the real provider as its own
# process, as the hooks do; the running turn's Stop runs while the reply's prompt hook runs.
Write-Host '--- case 7: a reply typed while the turn is still ending is recorded once, as its own act ---'
$handoverProvider = Join-Path $repoRoot 'scripts\internal\specrew-handover-provider.ps1'
function New-QueuedReplyFixture {
    $root = Join-Path ([IO.Path]::GetTempPath()) ('typed-act-queued-' + [guid]::NewGuid().ToString('N').Substring(0, 12))
    New-Item -ItemType Directory -Force -Path (Join-Path $root '.specrew') | Out-Null
    Set-Content -LiteralPath (Join-Path $root '.specrew/config.yml') -Value "specrew_version: `"0.40.0`"`nbootstrap_mode: `"fixture`"" -Encoding UTF8
    & git init -q -b 001-fixture $root 2>&1 | Out-Null
    $script:roots.Add($root)
    return [pscustomobject]@{ Root = $root; Transcript = (Join-Path $root 'transcript.jsonl') }
}
function Add-ClaudeEntry {
    # Returns the entry's own uuid, the record Claude keeps the hook's output under.
    param($Fixture, [string]$Role, [string]$Text, [string]$PromptId)
    $uuid = [guid]::NewGuid().ToString()
    $entry = if ($Role -eq 'user') {
        @{ type = 'user'; uuid = $uuid; timestamp = [DateTimeOffset]::UtcNow.ToString('o'); sessionId = 's1'; promptId = $PromptId
            origin = @{ kind = 'human' }; message = @{ role = 'user'; content = $Text } }
    }
    else { @{ type = 'assistant'; uuid = $uuid; message = @{ role = 'assistant'; content = @(@{ type = 'text'; text = $Text }) } } }
    Add-Content -LiteralPath $Fixture.Transcript -Value ($entry | ConvertTo-Json -Depth 8 -Compress) -Encoding UTF8
    return $uuid
}
function Add-HookAttachment {
    # Claude stores the prompt hook's output as an attachment under the message's own record (measured on this project's
    # transcript, Claude Code 2.1.31x: every UserPromptSubmit output sits under the user entry, or under the queued_command
    # attachment of a message absorbed into a running turn).
    param($Fixture, [string]$ParentUuid, [AllowNull()][string[]]$Output)
    $entry = @{ type = 'attachment'; uuid = [guid]::NewGuid().ToString(); parentUuid = $ParentUuid; sessionId = 's1'; timestamp = [DateTimeOffset]::UtcNow.ToString('o')
        attachment = @{ type = 'hook_additional_context'; content = @((@($Output) | Where-Object { $_ }) -join "`n"); hookName = 'UserPromptSubmit'; hookEvent = 'UserPromptSubmit' } }
    Add-Content -LiteralPath $Fixture.Transcript -Value ($entry | ConvertTo-Json -Depth 8 -Compress) -Encoding UTF8
}
function Invoke-PromptHook {
    # The prompt hook as its own process; returns what it printed (the hook's output Claude records).
    param($Fixture, [string]$Text, [string]$PromptId)
    $process = Start-HookProcess -ArgList (Get-PromptHookArgs -Fixture $Fixture -Text $Text -PromptId $PromptId)
    return (Wait-HookProcess $process)
}
function Send-ClaudeMessage {
    # A typed message as Claude handles it: the prompt hook runs, then the entry and the hook's output under it.
    param($Fixture, [string]$Text, [string]$PromptId)
    $out = Invoke-PromptHook -Fixture $Fixture -Text $Text -PromptId $PromptId
    $uuid = Add-ClaudeEntry -Fixture $Fixture -Role 'user' -Text $Text -PromptId $PromptId
    Add-HookAttachment -Fixture $Fixture -ParentUuid $uuid -Output $out
}
function Get-PromptHookArgs {
    param($Fixture, [string]$Text, [string]$PromptId)
    return @('-NoProfile', '-File', $handoverProvider, '--project-root', $Fixture.Root, '--host-kind', 'claude', '--source-event', 'UserPromptSubmit',
        '--transcript-path', $Fixture.Transcript, '--last-user-message', $Text, '--turn-origin', 'typed-user', '--session-id', 's1',
        '--message-identity', 'declared', '--message-id', $PromptId)
}
function Get-StopHookArgs {
    param($Fixture)
    return @('-NoProfile', '-File', $handoverProvider, '--project-root', $Fixture.Root, '--host-kind', 'claude', '--source-event', 'Stop',
        '--transcript-path', $Fixture.Transcript, '--session-id', 's1', '--message-identity', 'declared')
}
function Start-HookProcess {
    param([string[]]$ArgList)
    $psi = [Diagnostics.ProcessStartInfo]::new('pwsh')
    foreach ($a in $ArgList) { $psi.ArgumentList.Add([string]$a) }
    $psi.UseShellExecute = $false; $psi.RedirectStandardOutput = $true; $psi.RedirectStandardError = $true; $psi.CreateNoWindow = $true
    $psi.Environment['SPECREW_MODULE_PATH'] = $repoRoot
    return [Diagnostics.Process]::Start($psi)
}
function Wait-HookProcess {
    param($Process)
    $stdout = $Process.StandardOutput.ReadToEnd(); [void]$Process.StandardError.ReadToEnd(); $Process.WaitForExit()
    return [string[]]@($stdout -split "`r?`n" | Where-Object { $_ })
}
function Get-ReplyKeys {
    param($Fixture, [string]$Text)
    $path = Join-Path $Fixture.Root '.specrew/authority/exhausted-turns.jsonl'
    if (-not (Test-Path -LiteralPath $path)) { return @() }
    $hash = Get-SpecrewHumanAuthorityHash -Text $Text.Trim()
    return @(Get-Content -LiteralPath $path | Where-Object { $_.Trim() } | ForEach-Object { $_ | ConvertFrom-Json } |
            Where-Object { $_.PSObject.Properties['content_hash'] -and [string]$_.content_hash -ceq $hash } | ForEach-Object { [string]$_.turn_id } | Sort-Object -Unique)
}
function Get-NotRecordedCount {
    param($Fixture)
    $path = Get-SpecrewAuthorityNotRecordedJournalPath -ProjectRoot $Fixture.Root
    if (-not (Test-Path -LiteralPath $path)) { return 0 }
    return @(Get-Content -LiteralPath $path | Where-Object { $_.Trim() }).Count
}
# Feature 203 T008: how many messages recorded the sample act (the allowance reset), read from the authority ledger: one
# line per turn that minted, naming the writer (the prompt hook) or the act (`top-up`, the turn end's re-deriving writer).
function Get-RoundCaptureCount {
    param($Fixture)
    $path = Join-Path $Fixture.Root '.specrew/authority/exhausted-turns.jsonl'
    if (-not (Test-Path -LiteralPath $path)) { return 0 }
    return @(Get-Content -LiteralPath $path | Where-Object { $_.Trim() } | ForEach-Object { $_ | ConvertFrom-Json } |
            Where-Object { $_.PSObject.Properties['minted'] -and [string]$_.minted -match 'Write-SpecrewAllowanceResetAuthorization|top-up' } |
            ForEach-Object { [string]$_.turn_id } | Sort-Object -Unique).Count
}

foreach ($reply in @('1', 'approved for allowance reset')) {
    $f7 = New-QueuedReplyFixture
    $running = 'prompt-running-' + [guid]::NewGuid().ToString('N').Substring(0, 8)
    $first = 'which review host should run the next round? show me the options'
    # The running turn: the human's message, recorded by the prompt hook, and the reply that asks the question.
    Send-ClaudeMessage -Fixture $f7 -Text $first -PromptId $running
    $null = Add-ClaudeEntry -Fixture $f7 -Role 'assistant' -Text 'Two hosts can run it. Type one: 1 - codex, 2 - copilot.'
    # The turn is ending: its Stop hook runs, and the human answers now. The queued reply carries the running turn's id;
    # its hook runs when it is sent, and Claude records it, with the hook's output under it, when it is dequeued.
    $stop = Start-HookProcess -ArgList (Get-StopHookArgs -Fixture $f7)
    $promptOut = Invoke-PromptHook -Fixture $f7 -Text $reply -PromptId $running
    $replyUuid = Add-ClaudeEntry -Fixture $f7 -Role 'user' -Text $reply -PromptId $running
    Add-HookAttachment -Fixture $f7 -ParentUuid $replyUuid -Output $promptOut
    $null = Wait-HookProcess $stop
    # The next turn acts on it, and ends.
    $null = Add-ClaudeEntry -Fixture $f7 -Role 'assistant' -Text 'Acting on your reply.'
    $null = & pwsh @(Get-StopHookArgs -Fixture $f7) *> $null

    $replyKeys = @(Get-ReplyKeys -Fixture $f7 -Text $reply)
    $firstKeys = @(Get-ReplyKeys -Fixture $f7 -Text $first)
    $ownKey = [string](Get-SpecrewTypedActIdentity -Turn ([pscustomobject]@{ host = 'claude'; message_id = $running; text = $reply })).Identity
    Assert-True ($replyKeys.Count -eq 1 -and $replyKeys[0] -ceq $ownKey) ("[{0}] the queued reply is recorded once, under its own key (got {1} key(s))" -f $reply, $replyKeys.Count)
    Assert-True ($firstKeys.Count -ge 1 -and @($firstKeys | Where-Object { $replyKeys -ccontains $_ }).Count -eq 0) ("[{0}] and not as the running turn's message" -f $reply)
    Assert-True ((Get-NotRecordedCount -Fixture $f7) -eq 0) ("[{0}] nothing is reported as not recorded" -f $reply)
    if ($reply -ne '1') {
        $pending = Get-SpecrewAllowanceResetAuthorization -ProjectRoot $f7.Root
        Assert-True ((Get-RoundCaptureCount -Fixture $f7) -eq 1) ("[{0}] one round approval is captured (got {1})" -f $reply, (Get-RoundCaptureCount -Fixture $f7))
        Assert-True ($null -ne $pending -and [string]$pending.turn_identity -ceq $ownKey) ("[{0}] and the next turn finds it waiting, as the reply's own act" -f $reply)
    }
}

function Get-PendingRoundTurn {
    param($Fixture)
    $pending = Get-SpecrewAllowanceResetAuthorization -ProjectRoot $Fixture.Root
    if ($null -eq $pending -or -not $pending.PSObject.Properties['turn_identity']) { return '' }
    return [string]$pending.turn_identity
}
function Get-RoundSupersessionCount {
    param($Fixture)
    $path = Join-Path $Fixture.Root '.specrew/review/allowance-reset/supersessions.jsonl'
    if (-not (Test-Path -LiteralPath $path)) { return 0 }
    return @(Get-Content -LiteralPath $path | Where-Object { $_.Trim() } | ForEach-Object { $_ | ConvertFrom-Json } | Where-Object { [string]$_.fact_type -ceq 'allowance-reset-approval-superseded' }).Count
}
$approval = 'approved for allowance reset'

# Case 7b (co-review round 8, finding 2; maintainer's instruction 2026-11-05): THE SAME LINE RETYPED UNDER THE SAME PROMPT ID
# IS A SECOND MESSAGE. The running turn's message was itself `approved for allowance reset`, and the human types it again
# while the turn ends: Claude hands the retype the running turn's prompt_id, so id and text are the first message's. The
# discriminator is the host's own record of each message, never a time window: Claude stores each prompt hook's output
# under that message's own transcript record, and the hook names its prompt event there.
Write-Host '--- case 7b: the same approval retyped while the turn ends, under the running prompt id, is its own act ---'
$f7b = New-QueuedReplyFixture
$running7b = 'prompt-running-' + [guid]::NewGuid().ToString('N').Substring(0, 8)
Send-ClaudeMessage -Fixture $f7b -Text $approval -PromptId $running7b
$firstTurn7b = Get-PendingRoundTurn -Fixture $f7b
$null = Add-ClaudeEntry -Fixture $f7b -Role 'assistant' -Text 'Launching the round.'
$stop7b = Start-HookProcess -ArgList (Get-StopHookArgs -Fixture $f7b)
$out7b = Invoke-PromptHook -Fixture $f7b -Text $approval -PromptId $running7b
$retype7b = Add-ClaudeEntry -Fixture $f7b -Role 'user' -Text $approval -PromptId $running7b
Add-HookAttachment -Fixture $f7b -ParentUuid $retype7b -Output $out7b
$null = Wait-HookProcess $stop7b
$null = Add-ClaudeEntry -Fixture $f7b -Role 'assistant' -Text 'Acting on your reply.'
$null = & pwsh @(Get-StopHookArgs -Fixture $f7b) *> $null
$keys7b = @(Get-ReplyKeys -Fixture $f7b -Text $approval)
$held7b = Get-PendingRoundTurn -Fixture $f7b
Assert-True ($keys7b.Count -eq 2) ("the retyped approval is recorded as a second act (got {0} key(s))" -f $keys7b.Count)
Assert-True ((Get-RoundCaptureCount -Fixture $f7b) -eq 2 -and -not [string]::IsNullOrWhiteSpace($held7b) -and $held7b -cne $firstTurn7b -and $keys7b -ccontains $held7b) ("and the next turn finds the retype waiting, not the first approval (captures {0})" -f (Get-RoundCaptureCount -Fixture $f7b))
Assert-True ((Get-RoundSupersessionCount -Fixture $f7b) -eq 1 -and (Get-NotRecordedCount -Fixture $f7b) -eq 0) 'with one fact naming the approval it retired, and nothing reported as not recorded'

# Case 7c: the entry is in the transcript before the hook's output is (Claude writes a typed entry first). The hook's
# reservation of a message with that text, under no record yet, stands for it; the turn end recovers nothing twice.
Write-Host '--- case 7c: an entry whose hook output is not written yet is not recovered a second time ---'
$f7c = New-QueuedReplyFixture
$id7c = 'prompt-' + [guid]::NewGuid().ToString('N').Substring(0, 8)
$out7c = Invoke-PromptHook -Fixture $f7c -Text $approval -PromptId $id7c
$entry7c = Add-ClaudeEntry -Fixture $f7c -Role 'user' -Text $approval -PromptId $id7c
$null = & pwsh @(Get-StopHookArgs -Fixture $f7c) *> $null
Add-HookAttachment -Fixture $f7c -ParentUuid $entry7c -Output $out7c
$null = & pwsh @(Get-StopHookArgs -Fixture $f7c) *> $null
Assert-True (@(Get-ReplyKeys -Fixture $f7c -Text $approval).Count -eq 1 -and (Get-RoundCaptureCount -Fixture $f7c) -eq 1) ("one key and one capture (got {0} key(s), {1} capture(s))" -f @(Get-ReplyKeys -Fixture $f7c -Text $approval).Count, (Get-RoundCaptureCount -Fixture $f7c))

# Case 7d (maintainer's instruction 2026-11-05): no double-fire tolerance folds a real retype on Claude. The approval typed
# twice as two messages a second apart is two acts.
Write-Host '--- case 7d: the same approval typed twice within a few seconds on Claude is two acts ---'
$f7d = New-QueuedReplyFixture
Send-ClaudeMessage -Fixture $f7d -Text $approval -PromptId ('prompt-' + [guid]::NewGuid().ToString('N').Substring(0, 8))
$first7d = Get-PendingRoundTurn -Fixture $f7d
Send-ClaudeMessage -Fixture $f7d -Text $approval -PromptId ('prompt-' + [guid]::NewGuid().ToString('N').Substring(0, 8))
$null = & pwsh @(Get-StopHookArgs -Fixture $f7d) *> $null
$held7d = Get-PendingRoundTurn -Fixture $f7d
Assert-True (@(Get-ReplyKeys -Fixture $f7d -Text $approval).Count -eq 2 -and (Get-RoundCaptureCount -Fixture $f7d) -eq 2 -and $held7d -cne $first7d) ("two keys, two captures, the second waiting (got {0} key(s))" -f @(Get-ReplyKeys -Fixture $f7d -Text $approval).Count)

# ---------------------------------------------------------------------------------------------------
# Case 9 (co-review round 8, finding 1): RESERVE BEFORE MINTING, on the recovery path too. A ledger that can be read but not
# appended: the recovery writer wrote the approval and then failed to register the turn, so after the approval was spent
# the next turn end recovered the same entry into a fresh one. No reservation, no approval.
Write-Host '--- case 9: a turn the ledger cannot record mints nothing on the recovery path ---'
$f9 = New-QueuedReplyFixture
$id9 = 'prompt-' + [guid]::NewGuid().ToString('N').Substring(0, 8)
$null = Add-ClaudeEntry -Fixture $f9 -Role 'user' -Text $approval -PromptId $id9
$ledger9 = Join-Path $f9.Root '.specrew/authority/exhausted-turns.jsonl'
New-Item -ItemType Directory -Force -Path (Split-Path -Parent $ledger9) | Out-Null
Set-Content -LiteralPath $ledger9 -Value '{"schema_version":"1.0","fact_type":"typed-turn-exhausted","turn_id":"unrelated"}' -Encoding UTF8
(Get-Item -LiteralPath $ledger9).IsReadOnly = $true
try {
    $cite9 = [string](Get-SpecrewTypedActIdentity -Turn ([pscustomobject]@{ host = 'claude'; message_id = $id9; text = $approval })).Identity
    $r9 = Write-SpecrewTypedAct -ProjectRoot $f9.Root -HostKind 'claude' -TurnIdentity $cite9 -TranscriptPath $f9.Transcript -SourceEvent 'stop-transcript' -SessionId 's1'
}
finally { (Get-Item -LiteralPath $ledger9).IsReadOnly = $false }
Assert-True (-not [bool]$r9.Written -and $null -eq (Get-SpecrewAllowanceResetAuthorization -ProjectRoot $f9.Root)) ("no approval is written when its turn cannot be reserved (written={0})" -f [bool]$r9.Written)

# Case 10 (co-review round 8, finding 3): A RECOVERED ACT IS DATED BY WHEN IT WAS TYPED. Approval B was captured at 10:10;
# an older missed approval A, typed at 10:00, is recovered at 10:20. A must not retire B.
Write-Host '--- case 10: an older approval recovered late does not retire a newer one ---'
$f10 = New-QueuedReplyFixture
$null = Write-SpecrewAllowanceResetAuthorization -ProjectRoot $f10.Root -Response $approval -HostKind 'claude' -SourceEvent 'UserPromptSubmit' -TurnIdentity 'turn-B' -NowUtc '2026-11-04T10:10:00.0000000Z'
$id10 = 'prompt-' + [guid]::NewGuid().ToString('N').Substring(0, 8)
$entry10 = @{ type = 'user'; uuid = [guid]::NewGuid().ToString(); timestamp = '2026-11-04T10:00:00.000Z'; sessionId = 's1'; promptId = $id10; origin = @{ kind = 'human' }; message = @{ role = 'user'; content = $approval } }
Add-Content -LiteralPath $f10.Transcript -Value ($entry10 | ConvertTo-Json -Depth 8 -Compress) -Encoding UTF8
$cite10 = [string](Get-SpecrewTypedActIdentity -Turn ([pscustomobject]@{ host = 'claude'; message_id = $id10; text = $approval })).Identity
$null = Write-SpecrewTypedAct -ProjectRoot $f10.Root -HostKind 'claude' -TurnIdentity $cite10 -TranscriptPath $f10.Transcript -SourceEvent 'stop-transcript' -SessionId 's1' -NowUtc '2026-11-04T10:20:00.0000000Z'
Assert-True ((Get-PendingRoundTurn -Fixture $f10) -ceq 'turn-B' -and (Get-RoundSupersessionCount -Fixture $f10) -eq 0) ("B stays waiting and no fact says A retired it (holds '{0}')" -f (Get-PendingRoundTurn -Fixture $f10))

# Case 10c: the same for the allowance reset, through the supersession rule the top-up, the deferral and the partial
# sign-off share: a reset typed at 10:10 and spent, then an older reset typed at 10:00 arriving late.
Write-Host '--- case 10c: an older allowance reset arriving late does not replace a newer one already spent ---'
$f10c = New-QueuedReplyFixture
$null = Write-SpecrewAllowanceResetAuthorization -ProjectRoot $f10c.Root -Response 'approved for allowance reset' -HostKind 'claude' -SourceEvent 'UserPromptSubmit' -TurnIdentity 'turn-B' -NowUtc '2026-11-04T10:10:00.0000000Z'
$null = Complete-SpecrewAllowanceResetAuthorization -ProjectRoot $f10c.Root -Reference 'reset-1'
$null = Write-SpecrewAllowanceResetAuthorization -ProjectRoot $f10c.Root -Response 'approved for allowance reset' -HostKind 'claude' -SourceEvent 'stop-transcript' -TurnIdentity 'turn-A' -NowUtc '2026-11-04T10:00:00.0000000Z'
$reset10c = Get-Content -LiteralPath (Join-Path $f10c.Root '.specrew/review/allowance-reset/pending-allowance-reset.json') -Raw | ConvertFrom-Json
Assert-True ($null -eq (Get-SpecrewAllowanceResetAuthorization -ProjectRoot $f10c.Root) -and [string]$reset10c.turn_identity -ceq 'turn-B') ("no reset is spendable and the record still holds the spent B (holds '{0}')" -f [string]$reset10c.turn_identity)

# Case 11 (co-review round 10, finding 1): AN ACT THE RECOVERY PATH DERIVES BUT NO WRITER TAKES IS SAID, NEVER DROPPED. The
# partial sign-off and the workshop repair are recorded only as the human sends them (their writers take a prompt event
# alone). Missed by the prompt hook, the turn end derived the sign-off, reserved the turn, and its writer recorded nothing:
# no report, and the reservation made every later attempt already-recorded. The human hears it at their next message, with
# the phrase to type again.
Write-Host '--- case 11: a derived act no writer records at the turn end is reported, with the phrase to retype ---'
$f11 = New-QueuedReplyFixture
$tree11 = 'b' * 40; $campaign11 = 'cmp-001-fixture-i001'
$request11 = 'override-' + (Get-SpecrewHumanAuthorityHash -Text ($tree11 + '|' + $campaign11)).Substring(0, 24)
$requestDir11 = Join-Path $f11.Root '.specrew/review/signoff-gate'
New-Item -ItemType Directory -Force -Path $requestDir11 | Out-Null
([pscustomobject]@{ schema_version = '1.0'; request_id = $request11; target_tree_id = $tree11; campaign_id = $campaign11; run_id = 'run-1'
    required_phrase = 'approved for partial review signoff - <why accepting partial coverage is safe>'; created_at = [DateTimeOffset]::UtcNow.AddMinutes(-5).ToString('o') } |
    ConvertTo-Json) | Set-Content -LiteralPath (Join-Path $requestDir11 'pending-override.json') -Encoding UTF8
$signoff11 = 'approved for partial review signoff - the remaining files are test data'
$id11 = 'prompt-' + [guid]::NewGuid().ToString('N').Substring(0, 8)
$null = Add-ClaudeEntry -Fixture $f11 -Role 'user' -Text $signoff11 -PromptId $id11
$cite11 = [string](Get-SpecrewTypedActIdentity -Turn ([pscustomobject]@{ host = 'claude'; message_id = $id11; text = $signoff11 })).Identity
$r11 = Write-SpecrewTypedAct -ProjectRoot $f11.Root -HostKind 'claude' -TurnIdentity $cite11 -TranscriptPath $f11.Transcript -SourceEvent 'stop-transcript' -SessionId 's1'
$reports11 = Get-NotRecordedCount -Fixture $f11
Assert-True (-not [bool]$r11.Written -and $reports11 -eq 1) ("the sign-off the turn end could not record is reported (written={0}, reports={1})" -f [bool]$r11.Written, $reports11)
$said11 = [string](Get-SpecrewAuthorityNotRecordedDisclosure -ProjectRoot $f11.Root -HostKind 'claude' -SessionId 's1')
Assert-True ($said11 -match [regex]::Escape('approved for partial review signoff') -and $said11 -match '(?i)type it again') ("and the human's next message says it, with the phrase to type again ('{0}')" -f $said11)

# The slot helpers case 14 uses (case 12, the round slot, went with the per-round approval in feature 203 T008).
$store12 = Join-Path $repoRoot 'scripts\internal\bootstrap\HumanAuthorityStore.ps1'
function Start-SlotChild {
    param([string]$Command)
    $psi = [Diagnostics.ProcessStartInfo]::new('pwsh')
    foreach ($a in @('-NoProfile', '-NonInteractive', '-Command', (". '$store12'; " + $Command))) { $psi.ArgumentList.Add($a) }
    $psi.UseShellExecute = $false; $psi.RedirectStandardOutput = $true; $psi.RedirectStandardError = $true; $psi.CreateNoWindow = $true
    return [Diagnostics.Process]::Start($psi)
}
function Wait-SlotChild { param($Process) [void]$Process.StandardOutput.ReadToEnd(); [void]$Process.StandardError.ReadToEnd(); $Process.WaitForExit() }

# Case 13 (co-review round 11, finding 1): A TRANSCRIPT ENTRY'S IDENTITY DOES NOT MOVE WITH THE CALLER'S HOST LABEL. A Claude
# approval the prompt hook missed was recovered and spent; cited again with HostKind codex (or none), the reader labelled the
# same entry with the caller's host, the identity changed with it, and the round writer took it for a new, unspent approval.
Write-Host '--- case 13: the same entry cited under another host label records nothing new ---'
$f13 = New-QueuedReplyFixture
$id13 = 'prompt-' + [guid]::NewGuid().ToString('N').Substring(0, 8)
$entry13 = Add-ClaudeEntry -Fixture $f13 -Role 'user' -Text $approval -PromptId $id13
$cite13 = [string](Get-SpecrewTypedActIdentity -Turn ([pscustomobject]@{ host = 'claude'; message_id = $id13; text = $approval })).Identity
$first13 = Write-SpecrewTypedAct -ProjectRoot $f13.Root -HostKind 'claude' -TurnIdentity $cite13 -TranscriptPath $f13.Transcript -SourceEvent 'stop-transcript' -SessionId 's1'
$null = Complete-SpecrewAllowanceResetAuthorization -ProjectRoot $f13.Root -Reference 'cmp-x-round-1'
Assert-True ([bool]$first13.Written -and $null -eq (Get-SpecrewAllowanceResetAuthorization -ProjectRoot $f13.Root)) 'setup: the missed approval is recovered once and spent'
foreach ($label in @('codex', '')) {
    foreach ($citation in @(('entry:' + $entry13), [string](Get-SpecrewTypedActIdentity -Turn ([pscustomobject]@{ host = $label; message_id = $id13; text = $approval })).Identity)) {
        $null = Write-SpecrewTypedAct -ProjectRoot $f13.Root -HostKind $label -TurnIdentity $citation -TranscriptPath $f13.Transcript -SourceEvent 'stop-transcript' -SessionId 's1'
    }
}
Assert-True ($null -eq (Get-SpecrewAllowanceResetAuthorization -ProjectRoot $f13.Root) -and (Get-RoundCaptureCount -Fixture $f13) -eq 1) ("no approval is spendable and one capture exists (captures {0})" -f (Get-RoundCaptureCount -Fixture $f13))

# Case 14 (co-review round 12, finding 2): THE RESET'S SLOT HAS THE ROUND SLOT'S RULE. The consumption read reset A and wrote
# its spent A back with no lock, so a newer B saved in between was lost, its turn already reserved; and it stamped whatever
# the slot held, so a reset applied from A spent B. While another process holds the slot the consumption waits; and a
# consumption told which capture it used leaves a newer act waiting, which the landed-reset guard does not take as paid.
Write-Host '--- case 14: the reset consumption waits for the slot, and spends only the capture it used ---'
function Read-PendingReset { param([string]$Root) return Get-Content -LiteralPath (Join-Path $Root '.specrew/review/allowance-reset/pending-allowance-reset.json') -Raw -Encoding UTF8 | ConvertFrom-Json -Depth 8 }
$f14 = New-QueuedReplyFixture
$null = Write-SpecrewAllowanceResetAuthorization -ProjectRoot $f14.Root -Response 'approved for allowance reset' -HostKind 'claude' -SourceEvent 'UserPromptSubmit' -TurnIdentity 'turn-A' -NowUtc '2026-11-04T10:00:00.0000000Z'
$lockPath14 = Join-Path $f14.Root '.specrew/review/allowance-reset/pending-allowance-reset.lock'
$held14 = [IO.File]::Open($lockPath14, [IO.FileMode]::OpenOrCreate, [IO.FileAccess]::ReadWrite, [IO.FileShare]::None)
try {
    $spend14 = Start-SlotChild "`$null = Complete-SpecrewAllowanceResetAuthorization -ProjectRoot '$($f14.Root)' -Reference 'reset-1'"
    Start-Sleep -Seconds 4
    Assert-True ([string]::IsNullOrWhiteSpace([string](Read-PendingReset -Root $f14.Root).spent_at)) 'while the reset slot is held, the consumption does not write it'
}
finally { $held14.Dispose() }
Wait-SlotChild $spend14
Assert-True (-not [string]::IsNullOrWhiteSpace([string](Read-PendingReset -Root $f14.Root).spent_at)) 'once released, the consumption completes'
$f14b = New-QueuedReplyFixture
$null = Write-SpecrewAllowanceResetAuthorization -ProjectRoot $f14b.Root -Response 'approved for allowance reset' -HostKind 'claude' -SourceEvent 'UserPromptSubmit' -TurnIdentity 'turn-A' -NowUtc '2026-11-04T10:00:00.0000000Z'
$used14b = Get-SpecrewAllowanceResetAuthorization -ProjectRoot $f14b.Root
$null = Write-SpecrewAllowanceResetAuthorization -ProjectRoot $f14b.Root -Response 'approved for allowance reset' -HostKind 'claude' -SourceEvent 'UserPromptSubmit' -TurnIdentity 'turn-B' -NowUtc '2026-11-04T10:10:00.0000000Z'
Write-EngineFact -Path (Join-Path $f14b.Root ".specrew/review/authority/campaigns/$campaignId/budget-resets/reset-1.json") -Fact ([ordered]@{
        campaign_id = $campaignId; fact_type = 'budget-reset'; reset_id = 'reset-1'; observed_at = '2026-11-04T10:15:00.0000000+00:00'; schema_version = '1.0' })
$complete14b = @{ ProjectRoot = $f14b.Root; Reference = 'reset-1' }
Add-IfSupported -Splat $complete14b -Command 'Complete-SpecrewAllowanceResetAuthorization' -Name 'Approval' -Value $used14b
$null = Complete-SpecrewAllowanceResetAuthorization @complete14b
$waiting14b = Get-SpecrewAllowanceResetAuthorization -ProjectRoot $f14b.Root
Assert-True ($null -ne $waiting14b -and [string]$waiting14b.turn_identity -ceq 'turn-B') ("the reset applied from A leaves B waiting, unspent (waiting '{0}')" -f $(if ($null -ne $waiting14b) { [string]$waiting14b.turn_identity } else { '' }))
$landed14b = if ($null -ne $waiting14b) { Get-SpecrewLandedResetForAllowanceCapture -ProjectRoot $f14b.Root -CampaignId $campaignId -CaptureObservedAt $waiting14b.observed_at } else { 'no B' }
Assert-True ($null -eq $landed14b) 'and the reset A paid for is not taken as the one B paid for'

# Case 8 (FR-021; tasks.md, "the same rule covers the top-up, the coverage deferral and the partial sign-off"): A NEWER
# TYPED ACT SUPERSEDES; IT NEVER FOLDS, for the three review acts beside the round approval. Today the top-up folds a
# re-typed reset into the older unspent record, the deferral overwrites with no record of what it replaced, and a second
# partial sign-off for the same request is refused as a conflict. After T004 each newer typed act (another turn
# identity) takes the record with an immutable supersession fact naming what it retired; the same act re-offered changes
# nothing; an older act arriving late never retires the newer one.
Write-Host '--- case 8: the top-up, the coverage deferral and the partial sign-off supersede, never fold ---'
$t0 = [DateTimeOffset]::Parse('2026-11-04T10:00:00Z')
function Invoke-ReviewActWriter {
    param([string]$Kind, [string]$Root, [string]$Text, [string]$TurnIdentity, [DateTimeOffset]$At)
    $command = switch ($Kind) { 'top-up' { 'Write-SpecrewAllowanceResetAuthorization' } 'coverage-deferral' { 'Write-SpecrewCoverageDeferralAuthorization' } 'partial-signoff' { 'Write-SpecrewReviewSignoffOverrideAuthorization' } }
    $splat = @{ ProjectRoot = $Root; Response = $Text; HostKind = 'claude'; SourceEvent = 'UserPromptSubmit'; NowUtc = $At.ToString('o') }
    Add-IfSupported -Splat $splat -Command $command -Name 'TurnIdentity' -Value $TurnIdentity
    try { return (& $command @splat) } catch { return $null }
}
function Read-ReviewActRecord {
    param([string]$Kind, [string]$Root)
    $path = switch ($Kind) {
        'top-up' { Join-Path $Root '.specrew/review/allowance-reset/pending-allowance-reset.json' }
        'coverage-deferral' { Join-Path $Root '.specrew/review/coverage-disposition/coverage-deferral.json' }
        'partial-signoff' { @(Get-ChildItem -LiteralPath (Join-Path $Root '.specrew/review/signoff-gate/override-authorizations') -Filter 'override-*.json' -ErrorAction SilentlyContinue)[0].FullName }
    }
    if ([string]::IsNullOrWhiteSpace($path) -or -not (Test-Path -LiteralPath $path)) { return $null }
    return (Get-Content -LiteralPath $path -Raw | ConvertFrom-Json -Depth 8)
}
function Get-SupersessionFacts {
    param([string]$Root)
    return @(Get-ChildItem -LiteralPath (Join-Path $Root '.specrew/review') -Recurse -Filter 'supersessions.jsonl' -ErrorAction SilentlyContinue |
            ForEach-Object { Get-Content -LiteralPath $_.FullName } | Where-Object { $_.Trim() } | ForEach-Object { $_ | ConvertFrom-Json })
}
$reviewActs = @(
    @{ Kind = 'top-up'; A = 'approved for allowance reset'; B = 'approved for allowance reset' }
    @{ Kind = 'coverage-deferral'; A = 'continue without coverage until the review phase'; B = 'continue without coverage until the review phase' }
    @{ Kind = 'partial-signoff'; A = 'approved for partial review signoff - the security checks are covered'; B = 'approved for partial review signoff - the remaining files are test data' }
)
foreach ($act in $reviewActs) {
    $root = Join-Path ([IO.Path]::GetTempPath()) ('typed-act-supersede-' + [guid]::NewGuid().ToString('N').Substring(0, 12))
    New-Item -ItemType Directory -Force -Path (Join-Path $root '.specrew') | Out-Null
    $script:roots.Add($root)
    if ($act.Kind -eq 'partial-signoff') {
        $tree = 'a' * 40; $campaign = 'cmp-001-fixture-i001'
        $requestId = 'override-' + (Get-SpecrewHumanAuthorityHash -Text ($tree + '|' + $campaign)).Substring(0, 24)
        $requestDir = Join-Path $root '.specrew/review/signoff-gate'
        New-Item -ItemType Directory -Force -Path $requestDir | Out-Null
        ([pscustomobject]@{ schema_version = '1.0'; request_id = $requestId; target_tree_id = $tree; campaign_id = $campaign; run_id = 'run-1'
            required_phrase = 'approved for partial review signoff - <why accepting partial coverage is safe>'; created_at = $t0.AddMinutes(-5).ToString('o') } |
            ConvertTo-Json) | Set-Content -LiteralPath (Join-Path $requestDir 'pending-override.json') -Encoding UTF8
    }
    $k = $act.Kind
    $null = Invoke-ReviewActWriter -Kind $k -Root $root -Text $act.A -TurnIdentity 'turn-A' -At $t0
    $null = Invoke-ReviewActWriter -Kind $k -Root $root -Text $act.B -TurnIdentity 'turn-B' -At $t0.AddMinutes(10)
    $record = Read-ReviewActRecord -Kind $k -Root $root
    $heldTurn = if ($null -ne $record -and $record.PSObject.Properties['turn_identity']) { [string]$record.turn_identity } else { '' }
    Assert-True ($heldTurn -ceq 'turn-B') ("[{0}] the newer typed act takes the record (holds '{1}')" -f $k, $heldTurn)
    $facts = @(Get-SupersessionFacts -Root $root)
    Assert-True ($facts.Count -eq 1 -and [string]$facts[0].superseded_turn_identity -ceq 'turn-A' -and [string]$facts[0].superseded_by_turn_identity -ceq 'turn-B') ("[{0}] and an immutable fact records that it retired the older one (got {1})" -f $k, $facts.Count)
    $null = Invoke-ReviewActWriter -Kind $k -Root $root -Text $act.B -TurnIdentity 'turn-B' -At $t0.AddMinutes(15)
    $null = Invoke-ReviewActWriter -Kind $k -Root $root -Text $act.A -TurnIdentity 'turn-old' -At $t0.AddMinutes(-30)
    $after = Read-ReviewActRecord -Kind $k -Root $root
    $afterTurn = if ($null -ne $after -and $after.PSObject.Properties['turn_identity']) { [string]$after.turn_identity } else { '' }
    Assert-True ($afterTurn -ceq 'turn-B' -and @(Get-SupersessionFacts -Root $root).Count -eq 1) ("[{0}] the same act again, or an older act arriving late, changes nothing" -f $k)
}

foreach ($root in $script:roots) { Remove-Item -LiteralPath $root -Recurse -Force -ErrorAction SilentlyContinue }

Write-Host '--- the real stores are unchanged ---'
$guardAfter = Get-GuardSnapshot
$guardDiff = @(Compare-Object -ReferenceObject $script:guardBefore -DifferenceObject $guardAfter)
foreach ($change in ($guardDiff | Select-Object -First 10)) { Write-Host ("  {0} {1}" -f $(if ($change.SideIndicator -eq '=>') { 'now' } else { 'was' }), $change.InputObject) }
Assert-True ($guardDiff.Count -eq 0) ("no file changed under {0}" -f ($script:guardedPaths -join '; '))
foreach ($name in $script:clearedHostRoots.Keys) { Set-Item -LiteralPath ('Env:' + $name) -Value $script:clearedHostRoots[$name] }

if ($script:failCount -gt 0) { Write-Host "typed-act-writer: $($script:failCount) failure(s)" -ForegroundColor Red; exit 1 }
Write-Host 'typed-act-writer: all passed' -ForegroundColor Green
