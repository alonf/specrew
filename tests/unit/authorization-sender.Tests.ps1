# Feature 203 T013 (B5F-066; maintainer rulings 2026-11-12): WHO SENT THE MESSAGE AN AUTHORIZATION CAME FROM, read from the
# transcript record when the authorization is used.
#
# The prompt hook runs before Claude Code writes the message's transcript record, and its input carries no origin
# (recorded 2026-11-12: typed, peer and scheduled prompts, Claude Code 2.1.322). So the prompt hook stores where the
# record will be (the transcript path and the host's message id) on the turn's ledger row, and the check runs at use time:
#   - the per-field rule: isMeta not true; origin.kind human where present; turnOrigin human where present; promptSource
#     typed or queued, or sdk only with origin.kind human. A combination outside it is refused.
#   - none of the fields present (an older host): the text rules decided at capture; that is journaled and shown on the
#     status health line, because it is the unprotected path.
#   - the turn cannot be found: refused, with a plain message.
#   - the check names the sender: human, a named peer session with its address, scheduled, task notification, the session's
#     own command output, or other. Text the session wrote for itself is refused at every level.
BeforeAll {
    $script:RepoRoot = (Resolve-Path "$PSScriptRoot/../..").Path
    . (Join-Path $script:RepoRoot 'scripts/internal/bootstrap/HumanAuthorityStore.ps1')
    . (Join-Path $script:RepoRoot 'scripts/internal/bootstrap/ConversationCaptureAccessor.ps1')
    . (Join-Path $script:RepoRoot 'extensions/specrew-speckit/scripts/shared-governance.ps1')
    $script:Shapes = @((Get-Content -LiteralPath (Join-Path $script:RepoRoot 'tests/fixtures/hook-payloads/claude/transcript-origins/record-shapes.json') -Raw | ConvertFrom-Json).shapes)

    # A project whose ledger holds one turn the prompt hook reserved, and whose transcript holds that turn's record in a
    # given shape. Returns the turn identity an authorization record would carry.
    function script:New-SenderFixture {
        param([string]$Text = 'approved for allowance reset', $Shape, [switch]$NoLedgerPath, [switch]$NoRecord)
        $root = Join-Path $TestDrive ([guid]::NewGuid().ToString('N'))
        New-Item -ItemType Directory -Path (Join-Path $root '.specrew/authority') -Force | Out-Null
        $transcript = Join-Path $root 'session.jsonl'
        $messageId = 'prompt-' + [guid]::NewGuid().ToString('N').Substring(0, 12)
        $record = [ordered]@{ type = 'user'; uuid = [guid]::NewGuid().ToString(); promptId = $messageId; sessionId = 'sender-fixture'; timestamp = '2026-11-12T19:00:00.000Z'; message = [ordered]@{ role = 'user'; content = $Text } }
        if ($null -ne $Shape) {
            if ($Shape.turnOrigin) { $record.turnOrigin = [string]$Shape.turnOrigin }
            if ($Shape.promptSource) { $record.promptSource = [string]$Shape.promptSource }
            if ($Shape.isMeta -eq $true) { $record.isMeta = $true }
            if ($Shape.origin_kind) {
                $origin = [ordered]@{ kind = [string]$Shape.origin_kind }
                if ([string]$Shape.origin_kind -ceq 'peer') { $origin.name = 'specrewreviewer-84'; $origin.from = 'uds:\\.\pipe\LOCAL\cc-msg-fixture' }
                $record.origin = $origin
            }
            if ($Shape.entrypoint) { $record.entrypoint = [string]$Shape.entrypoint }
            if ($Shape.version) { $record.version = [string]$Shape.version }
        }
        $lines = if ($NoRecord) { @() } else { @(($record | ConvertTo-Json -Depth 6 -Compress)) }
        [IO.File]::WriteAllText($transcript, (($lines -join "`n") + "`n"), [Text.UTF8Encoding]::new($false))
        $turnId = [string](Get-SpecrewTypedActIdentity -Turn ([pscustomobject]@{ host = 'claude'; message_id = $messageId; text = $Text })).Identity
        $splat = @{ ProjectRoot = $root; TurnId = $turnId; HostKind = 'claude'; SourceEvent = 'UserPromptSubmit'; MintedWriters = ''; ContentHash = (Get-SpecrewHumanAuthorityHash -Text $Text); SessionId = 'sender-fixture'; Identity = 'typed-act'; TurnOrigin = 'typed-user' }
        if (-not $NoLedgerPath) { $splat.TranscriptPath = $transcript; $splat.MessageId = $messageId }
        $null = Register-SpecrewExhaustedTurn @splat
        return [pscustomobject]@{ Root = $root; TurnIdentity = $turnId; Transcript = $transcript; MessageId = $messageId }
    }
}

Describe 'the sender of a transcript record, by the per-field rule (one check for every recorded shape)' {
    It '<kind> (Claude <version>, <entrypoint>) is <expected_sender>, accepted <accepted>' -ForEach @((Get-Content -LiteralPath (Join-Path (Resolve-Path "$PSScriptRoot/../..").Path 'tests/fixtures/hook-payloads/claude/transcript-origins/record-shapes.json') -Raw | ConvertFrom-Json).shapes | ForEach-Object { @{ kind = $_.kind; version = $_.version; entrypoint = $_.entrypoint; expected_sender = $_.expected_sender; accepted = $_.accepted; shape = $_ } }) {
        $queuedArgs = @{}
        if ($shape.PSObject.Properties['record']) { $queuedArgs = @{ RecordKind = [string]$shape.record; HumanTurn = $shape.human_turn; CommandMode = [string]$shape.command_mode } }
        $s = Get-SpecrewTranscriptRecordSender -TurnOrigin ([string]$shape.turnOrigin) -PromptSource ([string]$shape.promptSource) -IsMeta $shape.isMeta -OriginKind ([string]$shape.origin_kind) @queuedArgs
        [string]$s.sender | Should -BeExactly $expected_sender
        [bool]$s.accepted | Should -Be ([bool]$accepted)
    }

    It 'a peer names the session that sent it and its address' {
        $s = Get-SpecrewTranscriptRecordSender -TurnOrigin 'peer' -PromptSource 'system' -IsMeta $true -OriginKind 'peer' -PeerName 'specrewreviewer-84' -PeerAddress 'uds:\\.\pipe\LOCAL\cc-msg-x'
        [string]$s.sender | Should -BeExactly 'peer'
        [string]$s.peer_name | Should -BeExactly 'specrewreviewer-84'
        [string]$s.peer_address | Should -BeExactly 'uds:\\.\pipe\LOCAL\cc-msg-x'
    }
}

Describe 'the check when an authorization is used (Resolve-SpecrewAuthorizationSender)' {
    It 'a typed message is the human''s, and the sender is stored against the turn' {
        $f = script:New-SenderFixture -Shape ($script:Shapes | Where-Object kind -eq 'typed')
        $r = Resolve-SpecrewAuthorizationSender -ProjectRoot $f.Root -TurnIdentity $f.TurnIdentity -Purpose 'allowance reset'
        $r.accepted | Should -BeTrue
        [string]$r.sender | Should -BeExactly 'human'
        $rows = @(Get-Content -LiteralPath (Join-Path $f.Root '.specrew/authority/turn-senders.jsonl') | ForEach-Object { $_ | ConvertFrom-Json })
        [string]$rows[-1].turn_identity | Should -BeExactly $f.TurnIdentity
        [string]$rows[-1].sender | Should -BeExactly 'human'
    }

    It 'a scheduled prompt whose whole text is the phrase is refused, naming what to do next' {
        $f = script:New-SenderFixture -Shape ($script:Shapes | Where-Object kind -eq 'scheduled')
        $r = Resolve-SpecrewAuthorizationSender -ProjectRoot $f.Root -TurnIdentity $f.TurnIdentity -Purpose 'allowance reset'
        $r.accepted | Should -BeFalse
        [string]$r.sender | Should -BeExactly 'scheduled'
        [string]$r.message | Should -Match 'scheduled'
        [string]$r.message | Should -Match 'type the line yourself in the terminal session'
        [string]$r.message | Should -Match 'update Claude'
    }

    It 'a peer message is refused, and the stored sender names the session and its address' {
        $f = script:New-SenderFixture -Shape ($script:Shapes | Where-Object kind -eq 'peer')
        $r = Resolve-SpecrewAuthorizationSender -ProjectRoot $f.Root -TurnIdentity $f.TurnIdentity -Purpose 'allowance reset'
        $r.accepted | Should -BeFalse
        [string]$r.sender | Should -BeExactly 'peer'
        [string]$r.peer_name | Should -BeExactly 'specrewreviewer-84'
        $row = @(Get-Content -LiteralPath (Join-Path $f.Root '.specrew/authority/turn-senders.jsonl') | ForEach-Object { $_ | ConvertFrom-Json })[-1]
        [string]$row.peer_name | Should -BeExactly 'specrewreviewer-84'
        [string]$row.peer_address | Should -Match 'cc-msg-fixture'
    }

    It 'a turn that cannot be found is refused with a plain message: no ledger path, no record, no ledger row' {
        foreach ($case in @(
                (script:New-SenderFixture -Shape ($script:Shapes | Where-Object kind -eq 'typed') -NoLedgerPath),
                (script:New-SenderFixture -Shape ($script:Shapes | Where-Object kind -eq 'typed') -NoRecord))) {
            $r = Resolve-SpecrewAuthorizationSender -ProjectRoot $case.Root -TurnIdentity $case.TurnIdentity -Purpose 'allowance reset'
            $r.accepted | Should -BeFalse
            [string]$r.sender | Should -BeExactly 'not-found'
            [string]$r.message | Should -Match 'could not find the message'
        }
        $empty = script:New-SenderFixture -Shape ($script:Shapes | Where-Object kind -eq 'typed')
        (Resolve-SpecrewAuthorizationSender -ProjectRoot $empty.Root -TurnIdentity ('f' * 64) -Purpose 'allowance reset').accepted | Should -BeFalse
        (Resolve-SpecrewAuthorizationSender -ProjectRoot $empty.Root -TurnIdentity '' -Purpose 'allowance reset').accepted | Should -BeFalse
    }

    It 'a record with none of the fields is left to the text rules, journaled, and shown on the status health line' {
        $f = script:New-SenderFixture -Shape ($script:Shapes | Where-Object kind -eq 'no-fields')
        $r = Resolve-SpecrewAuthorizationSender -ProjectRoot $f.Root -TurnIdentity $f.TurnIdentity -Purpose 'allowance reset'
        $r.accepted | Should -BeTrue
        [string]$r.sender | Should -BeExactly 'unverified'
        Test-Path -LiteralPath (Join-Path $f.Root '.specrew/runtime/authorization-sender-unverified.jsonl') | Should -BeTrue
        [string](Get-SpecrewAuthorizationSenderHealthLine -ProjectRoot $f.Root) | Should -Match 'could not confirm'
        Get-SpecrewAuthorizationSenderHealthLine -ProjectRoot (script:New-SenderFixture -Shape ($script:Shapes | Where-Object kind -eq 'typed')).Root | Should -BeNullOrEmpty
    }
}

Describe 'a host whose hook input carries no transcript path (maintainer ruling 2026-11-12)' {
    It 'a Copilot approval is unverified: the text rules decide, it is journaled by host and shown on the health line; a Claude turn with no path is still refused' {
        $root = Join-Path $TestDrive 'copilot'
        New-Item -ItemType Directory -Path (Join-Path $root '.specrew/authority') -Force | Out-Null
        $turnId = [string](Get-SpecrewTypedActIdentity -Turn ([pscustomobject]@{ host = 'copilot'; message_id = ('0' * 64); text = 'approved for allowance reset' })).Identity
        $null = Register-SpecrewExhaustedTurn -ProjectRoot $root -TurnId $turnId -HostKind 'copilot' -SourceEvent 'userPromptSubmitted' -MintedWriters '' -ContentHash (Get-SpecrewHumanAuthorityHash -Text 'approved for allowance reset') -SessionId 'c' -Identity 'typed-act' -TurnOrigin 'typed-user'
        $r = Resolve-SpecrewAuthorizationSender -ProjectRoot $root -TurnIdentity $turnId -Purpose 'allowance reset' -HostKind 'copilot'
        $r.accepted | Should -BeTrue
        [string]$r.sender | Should -BeExactly 'unverified'
        $row = @(Get-Content -LiteralPath (Join-Path $root '.specrew/runtime/authorization-sender-unverified.jsonl') | ForEach-Object { $_ | ConvertFrom-Json })[-1]
        [string]$row.host_kind | Should -BeExactly 'copilot'
        [string](Get-SpecrewAuthorizationSenderHealthLine -ProjectRoot $root) | Should -Match 'copilot'
        $claude = script:New-SenderFixture -Shape ($script:Shapes | Where-Object kind -eq 'typed') -NoLedgerPath
        (Resolve-SpecrewAuthorizationSender -ProjectRoot $claude.Root -TurnIdentity $claude.TurnIdentity -Purpose 'allowance reset' -HostKind 'claude').accepted | Should -BeFalse
    }
}

Describe 'the record is bound to what the cited turn said (maintainer ruling 2026-11-12)' {
    It 'a record citing a real typed turn about something else is refused; its own turn is used' {
        $f = script:New-SenderFixture -Text 'thanks, that looks right' -Shape ($script:Shapes | Where-Object kind -eq 'typed')
        $forged = [pscustomobject]@{ fact_type = 'allowance-reset-approval'; verdict_text = 'approved for allowance reset'; turn_identity = $f.TurnIdentity; host_kind = 'claude' }
        Test-SpecrewAuthorizationRecordSender -ProjectRoot $f.Root -Record $forged -Purpose 'allowance reset' 2>$null | Should -BeFalse
        $own = script:New-SenderFixture -Text 'approved for allowance reset' -Shape ($script:Shapes | Where-Object kind -eq 'typed')
        $real = [pscustomobject]@{ fact_type = 'allowance-reset-approval'; verdict_text = 'approved for allowance reset'; turn_identity = $own.TurnIdentity; host_kind = 'claude' }
        Test-SpecrewAuthorizationRecordSender -ProjectRoot $own.Root -Record $real -Purpose 'allowance reset' | Should -BeTrue
    }

    It 'a record whose kind is not the cited turn''s act is refused (a stop line cited for a top-up)' {
        $f = script:New-SenderFixture -Text 'stop the review here' -Shape ($script:Shapes | Where-Object kind -eq 'typed')
        $wrongKind = [pscustomobject]@{ fact_type = 'allowance-reset-approval'; verdict_text = 'stop the review here'; turn_identity = $f.TurnIdentity; host_kind = 'claude' }
        Test-SpecrewAuthorizationRecordSender -ProjectRoot $f.Root -Record $wrongKind -Purpose 'allowance reset' 2>$null | Should -BeFalse
    }

    It 'a boundary verdict entry citing a typed turn that said something else covers nothing' {
        $f = script:New-SenderFixture -Text 'can you explain the plan?' -Shape ($script:Shapes | Where-Object kind -eq 'typed')
        $entry = @{ from_boundary = 'plan'; to_boundary = 'tasks'; verdict_text = 'approved for tasks'; evidence_source = 'hook-captured-user-prompt'; turn_identity = $f.TurnIdentity }
        Test-SpecrewAuthorizationRecordSender -ProjectRoot $f.Root -Record $entry -Purpose 'approval for tasks' 2>$null | Should -BeFalse
    }
}

Describe 'a message typed while the crew is working: a queued_command record (B5F-070; maintainer ruling 2026-11-13)' {
    BeforeAll {
        $script:QueuedDir = Join-Path $script:RepoRoot 'tests/fixtures/hook-payloads/claude/queued-mid-turn'
        # The maintainer's recorded mid-turn message, its hook output, and the ledger row the prompt hook wrote for it; the
        # engine that recorded the row predates the transcript path on ledger rows, which the current prompt hook adds.
        function script:New-QueuedProject([string]$OriginKind = '') {
            $root = Join-Path $TestDrive ([guid]::NewGuid().ToString('N'))
            New-Item -ItemType Directory -Path (Join-Path $root '.specrew/authority') -Force | Out-Null
            $lines = @(Get-Content -LiteralPath (Join-Path $script:QueuedDir 'tui-transcript-queued-mid-turn.jsonl'))
            if ($OriginKind) {
                $q = $lines[0] | ConvertFrom-Json -Depth 40
                $q.attachment.origin.kind = $OriginKind
                $lines[0] = $q | ConvertTo-Json -Depth 40 -Compress
            }
            $transcript = Join-Path $root 'session.jsonl'
            [IO.File]::WriteAllText($transcript, (($lines -join "`n") + "`n"), [Text.UTF8Encoding]::new($false))
            $row = Get-Content -LiteralPath (Join-Path $script:QueuedDir 'ledger-row.jsonl') -Raw | ConvertFrom-Json
            $row | Add-Member -NotePropertyName transcript_path -NotePropertyValue $transcript -Force
            [IO.File]::WriteAllText((Join-Path $root '.specrew/authority/exhausted-turns.jsonl'), (($row | ConvertTo-Json -Compress) + "`n"), [Text.UTF8Encoding]::new($false))
            $text = [string](($lines[0] | ConvertFrom-Json -Depth 40).attachment.prompt)
            $hash = ([Convert]::ToHexString([Security.Cryptography.SHA256]::HashData([Text.Encoding]::UTF8.GetBytes($text)))).ToLowerInvariant()
            return [pscustomobject]@{ Root = $root; TurnIdentity = [string]$row.turn_id; Text = $text; Hash = $hash }
        }
    }

    It 'the maintainer''s recorded mid-turn message is found and is the human''s' {
        $p = script:New-QueuedProject
        $r = Resolve-SpecrewAuthorizationSender -ProjectRoot $p.Root -TurnIdentity $p.TurnIdentity -Purpose 'workshop answer'
        $r.accepted | Should -BeTrue -Because ([string]$r.message)
        [string]$r.sender | Should -BeExactly 'human'
        # The text binding applies: a record of what the message said is used; one of something else is not.
        $record = [pscustomobject]@{ response_hash = $p.Hash; turn_identity = $p.TurnIdentity; host_kind = 'claude' }
        Test-SpecrewAuthorizationRecordSender -ProjectRoot $p.Root -Record $record -Purpose 'workshop answer' | Should -BeTrue
        $other = [pscustomobject]@{ response_hash = ('0' * 64); turn_identity = $p.TurnIdentity; host_kind = 'claude' }
        Test-SpecrewAuthorizationRecordSender -ProjectRoot $p.Root -Record $other -Purpose 'workshop answer' 2>$null | Should -BeFalse
    }

    It 'the same queued record with any other origin is refused' {
        $p = script:New-QueuedProject -OriginKind 'task-notification'
        $r = Resolve-SpecrewAuthorizationSender -ProjectRoot $p.Root -TurnIdentity $p.TurnIdentity -Purpose 'workshop answer'
        $r.accepted | Should -BeFalse
        [string]$r.sender | Should -BeExactly 'task-notification'
    }
}

Describe 'the check loads where a project runs it: the deployed .specify copy of shared-governance' {
    It 'finds the engine from the deployed copy, through SPECREW_MODULE_PATH or the project above it, and loads it once' {
        # T013 triage, gap 1: from .specify/extensions/specrew-speckit/scripts the store was looked for under .specify\ and
        # then in the installed module, which may predate the check, so every captured approval was refused.
        $f = script:New-SenderFixture -Shape ($script:Shapes | Where-Object kind -eq 'typed')
        $probe = Join-Path $TestDrive 'load-probe.ps1'
        @'
param([string]$Repo, [string]$Project, [string]$Turn)
$env:SPECREW_MODULE_PATH = $Repo
. (Join-Path $Repo '.specify/extensions/specrew-speckit/scripts/shared-governance.ps1')
$record = [pscustomobject]@{ fact_type = 'allowance-reset-approval'; verdict_text = 'approved for allowance reset'; turn_identity = $Turn; host_kind = 'claude' }
$first = Test-SpecrewAuthorizationSenderForUse -ProjectRoot $Project -Record $record -Purpose 'probe'
$loaded = [bool](Get-Command Test-SpecrewAuthorizationRecordSender -ErrorAction SilentlyContinue)
'first={0} loaded-after={1}' -f $first, $loaded
'@ | Set-Content -LiteralPath $probe -Encoding utf8
        $out = & pwsh -NoProfile -NonInteractive -File $probe -Repo $script:RepoRoot -Project $f.Root -Turn $f.TurnIdentity 2>&1
        ($out -join ' ') | Should -Match 'first=True loaded-after=True'
    }
}

Describe 'the prompt hook keeps where the record will be on the turn''s ledger row' {
    It 'the reservation carries the transcript path and the host''s message id' {
        $root = Join-Path $TestDrive 'prompt-hook'
        New-Item -ItemType Directory -Path (Join-Path $root '.specrew') -Force | Out-Null
        . (Join-Path $script:RepoRoot 'scripts/internal/bootstrap/HandoverStore.ps1')
        $transcript = Join-Path $root 'session.jsonl'
        [IO.File]::WriteAllText($transcript, '', [Text.UTF8Encoding]::new($false))
        $null = Invoke-SpecrewTypedAuthorityCapture -ProjectRoot $root -Response 'approved for allowance reset' -HostKind 'claude' -SourceEvent 'UserPromptSubmit' `
            -NowUtc '2026-11-12T19:00:00Z' -TurnPosition 'prompt-entry' -TurnArrival '2026-11-12T19:00:00Z' -MessageId 'prompt-hook-1' -SessionId 's1' -TurnOrigin 'typed-user' -TranscriptPath $transcript
        $rows = @(Get-Content -LiteralPath (Join-Path $root '.specrew/authority/exhausted-turns.jsonl') | ForEach-Object { $_ | ConvertFrom-Json })
        $rows.Count | Should -BeGreaterThan 0
        [string]$rows[-1].transcript_path | Should -BeExactly $transcript
        [string]$rows[-1].message_id | Should -BeExactly 'prompt-hook-1'
    }
}
