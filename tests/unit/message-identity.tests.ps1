#requires -Version 7.0
Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

# Feature 202 iteration 002, T017 (FR-027, SC-010, DA-2; B4F-127).
#
# ONE HUMAN MESSAGE, ONE KEY. A typed approval is seen twice: by the message hook when it arrives, and by the
# turn-end path, which re-reads the newest human turn from the transcript at every turn end. Before this change
# each path hashed the message together with its own name, so the two could never match: one typed approval was
# recorded twice, and past the 500-line transcript window the turn-end copy was recorded again at every turn end.
#
# The key is the host's own message ID: Claude's `prompt_id` (the transcript entry's `promptId`, never its `uuid`),
# Codex's `turn_id` (the transcript's `turn_context`). Copilot sends no message ID with the prompt, so the message
# hook is its only recording path, and a typed approval that hook missed is reported instead of recorded.
#
# Every case drives the shipped handover provider as its own process, the way the dispatcher launches it.

BeforeAll {
    $script:RepoRoot = (Resolve-Path (Join-Path $PSScriptRoot '..\..')).Path
    $script:Provider = Join-Path $script:RepoRoot 'extensions/specrew-speckit/scripts/specrew-handover-provider.ps1'

    function script:New-Project {
        $root = Join-Path ([IO.Path]::GetTempPath()) ('f202-msgid-' + [guid]::NewGuid().ToString('N'))
        New-Item -ItemType Directory -Path (Join-Path $root '.specrew') -Force | Out-Null
        Set-Content -LiteralPath (Join-Path $root '.specrew/config.yml') -Value "specrew_version: `"0.40.0`"`nbootstrap_mode: `"fixture`"" -Encoding UTF8
        & git init -q -b 001-fixture $root 2>&1 | Out-Null
        $tp = Join-Path $root 'transcript.jsonl'
        Set-Content -LiteralPath $tp -Value $null -NoNewline -Encoding UTF8
        return [pscustomobject]@{ Root = $root; Transcript = $tp }
    }

    function script:Add-Line {
        param([Parameter(Mandatory)]$P, [Parameter(Mandatory)][hashtable]$Entry)
        Add-Content -LiteralPath $P.Transcript -Value ($Entry | ConvertTo-Json -Depth 8 -Compress) -Encoding UTF8
    }

    function script:Add-Filler {
        param([Parameter(Mandatory)]$P, [int]$Count = 620)
        $lines = for ($i = 0; $i -lt $Count; $i++) {
            (@{ type = 'assistant'; uuid = ('f' + $i); message = @{ role = 'assistant'; content = @(@{ type = 'text'; text = ('filler ' + $i) }) } } | ConvertTo-Json -Depth 6 -Compress)
        }
        Add-Content -LiteralPath $P.Transcript -Value $lines -Encoding UTF8
    }

    # One typed human entry, in the host's own transcript shape.
    function script:Add-Human {
        param([Parameter(Mandatory)]$P, [Parameter(Mandatory)][string]$HostKind, [Parameter(Mandatory)][string]$Text, [string]$MessageId, [switch]$NoMessageId,
            [int]$SecondsFromNow = 0)
        $arrival = [DateTimeOffset]::UtcNow.AddSeconds($SecondsFromNow).ToString('o')
        switch ($HostKind) {
            'claude' {
                $e = @{ type = 'user'; uuid = ([guid]::NewGuid().ToString()); timestamp = $arrival; sessionId = 's1'; message = @{ role = 'user'; content = $Text } }
                if (-not $NoMessageId) { $e['promptId'] = $MessageId }
                Add-Line -P $P -Entry $e
            }
            'codex' {
                # Every line of a Codex rollout carries a top-level timestamp.
                $ts = $arrival
                Add-Line -P $P -Entry @{ timestamp = $ts; type = 'turn_context'; payload = @{ turn_id = $MessageId; cwd = $P.Root } }
                Add-Line -P $P -Entry @{ timestamp = $ts; type = 'response_item'; payload = @{ type = 'message'; role = 'user'; content = @(@{ type = 'input_text'; text = $Text }) } }
            }
            'copilot' {
                Add-Line -P $P -Entry @{ type = 'user.message'; id = ([guid]::NewGuid().ToString()); timestamp = $arrival; data = @{ content = $Text; messageId = ([guid]::NewGuid().ToString()) } }
            }
        }
    }

    function script:Add-AssistantTurn {
        param([Parameter(Mandatory)]$P, [Parameter(Mandatory)][string]$HostKind, [string]$MessageId)
        switch ($HostKind) {
            'claude' {
                # The Stop-hook feedback entry Claude writes is isMeta and carries the SAME promptId as the human turn.
                Add-Line -P $P -Entry @{ type = 'user'; isMeta = $true; promptId = $MessageId; uuid = ([guid]::NewGuid().ToString()); message = @{ role = 'user'; content = 'Stop hook feedback: Specrew review - these files have not been reviewed yet.' } }
                Add-Line -P $P -Entry @{ type = 'assistant'; uuid = ([guid]::NewGuid().ToString()); message = @{ role = 'assistant'; content = @(@{ type = 'text'; text = 'Working on it.' }) } }
            }
            'codex' { Add-Line -P $P -Entry @{ type = 'response_item'; payload = @{ type = 'message'; role = 'assistant'; content = @(@{ type = 'output_text'; text = 'Working on it.' }) } } }
            'copilot' { Add-Line -P $P -Entry @{ type = 'assistant.message'; id = ([guid]::NewGuid().ToString()); data = @{ content = 'Working on it.' } } }
        }
    }

    # The message-identity declaration the dispatcher forwards from the host binding: Claude and Codex declare a
    # message ID field, Copilot declares none.
    function script:Get-Declaration { param([string]$HostKind) if ($HostKind -eq 'copilot') { 'none' } else { 'declared' } }

    function script:Invoke-Prompt {
        param([Parameter(Mandatory)]$P, [Parameter(Mandatory)][string]$HostKind, [Parameter(Mandatory)][string]$Text, [string]$MessageId,
            [string]$Session = 's1', [switch]$BeforeMessageIds)
        $a = @('-NoProfile', '-NonInteractive', '-File', $script:Provider, '--project-root', $P.Root, '--host-kind', $HostKind,
            '--source-event', 'UserPromptSubmit', '--last-user-message', $Text, '--turn-origin', 'typed-user', '--session-id', $Session)
        # -BeforeMessageIds replays the message hook as it ran before T017: no message ID, no declaration.
        if (-not $BeforeMessageIds) { $a += @('--message-identity', (Get-Declaration $HostKind)) }
        if (-not [string]::IsNullOrWhiteSpace($MessageId) -and -not $BeforeMessageIds) { $a += @('--message-id', $MessageId) }
        $env:SPECREW_MODULE_PATH = $script:RepoRoot
        $out = & pwsh @a 2>$null
        return (@($out) -join "`n")
    }

    function script:Invoke-TurnEnd {
        param([Parameter(Mandatory)]$P, [Parameter(Mandatory)][string]$HostKind, [string]$Session = 's1', [string]$Transcript)
        $event = if ($HostKind -eq 'copilot') { 'agentStop' } else { 'Stop' }
        $tp = if ([string]::IsNullOrWhiteSpace($Transcript)) { $P.Transcript } else { $Transcript }
        $a = @('-NoProfile', '-NonInteractive', '-File', $script:Provider, '--project-root', $P.Root, '--host-kind', $HostKind,
            '--source-event', $event, '--transcript-path', $tp, '--session-id', $Session, '--message-identity', (Get-Declaration $HostKind))
        $env:SPECREW_MODULE_PATH = $script:RepoRoot
        & pwsh @a *> $null
    }

    function script:Get-RoundCaptures {
        param([Parameter(Mandatory)]$P)
        $f = Join-Path $P.Root '.specrew/review/round-approval/captures.jsonl'
        if (-not (Test-Path -LiteralPath $f)) { return 0 }
        return @(Get-Content -LiteralPath $f | Where-Object { $_.Trim() }).Count
    }

    # Writer-agnostic: how many distinct turns the authority ledger reserved. One message must reserve one.
    function script:Get-ReservedTurns {
        param([Parameter(Mandatory)]$P)
        $f = Join-Path $P.Root '.specrew/authority/exhausted-turns.jsonl'
        if (-not (Test-Path -LiteralPath $f)) { return 0 }
        return @(Get-Content -LiteralPath $f | Where-Object { $_.Trim() } | ForEach-Object { ($_ | ConvertFrom-Json).turn_id } | Sort-Object -Unique).Count
    }

    function script:Set-RoundSpent {
        param([Parameter(Mandatory)]$P)
        $f = Join-Path $P.Root '.specrew/review/round-approval/pending-round-approval.json'
        $o = Get-Content -LiteralPath $f -Raw | ConvertFrom-Json
        $o.spent_at = '2026-10-17T05:01:00Z'
        $o.authorization_ref = 'run-test'
        Set-Content -LiteralPath $f -Value ($o | ConvertTo-Json -Depth 8) -Encoding UTF8
    }

    function script:Test-RoundUnspent {
        param([Parameter(Mandatory)]$P)
        $f = Join-Path $P.Root '.specrew/review/round-approval/pending-round-approval.json'
        if (-not (Test-Path -LiteralPath $f)) { return $false }
        $o = Get-Content -LiteralPath $f -Raw | ConvertFrom-Json
        return [string]::IsNullOrWhiteSpace([string]$o.spent_at)
    }

    function script:Get-NotRecordedReports {
        param([Parameter(Mandatory)]$P)
        $f = Join-Path $P.Root '.specrew/runtime/authority-capture-drops.jsonl'
        if (-not (Test-Path -LiteralPath $f)) { return @() }
        return @(Get-Content -LiteralPath $f | Where-Object { $_.Trim() } | ForEach-Object { $_ | ConvertFrom-Json } |
                Where-Object { [string]$_.event -eq 'authority-phrase-not-recorded' })
    }
}

AfterAll { Remove-Item env:SPECREW_MODULE_PATH -ErrorAction SilentlyContinue }

Describe 'One typed approval, both recording paths, N turn ends: exactly one recorded approval (SC-010)' {
    It '<HostKind>, <Size> transcript: the message hook and 4 turn ends record the round approval once' -ForEach @(
        @{ HostKind = 'claude'; Size = 'small' }, @{ HostKind = 'claude'; Size = 'large' },
        @{ HostKind = 'codex'; Size = 'small' }, @{ HostKind = 'codex'; Size = 'large' },
        @{ HostKind = 'copilot'; Size = 'small' }
    ) {
        $p = New-Project
        if ($Size -eq 'large') { Add-Filler -P $p }
        Add-Human -P $p -HostKind $HostKind -Text 'approved for review round' -MessageId 'msg-1'
        $id = if ($HostKind -eq 'copilot') { '' } else { 'msg-1' }
        Invoke-Prompt -P $p -HostKind $HostKind -Text 'approved for review round' -MessageId $id | Out-Null
        for ($i = 0; $i -lt 4; $i++) { Add-AssistantTurn -P $p -HostKind $HostKind -MessageId 'msg-1'; Invoke-TurnEnd -P $p -HostKind $HostKind }
        Get-RoundCaptures -P $p | Should -Be 1
        Get-ReservedTurns -P $p | Should -Be 1
    }

    It '<HostKind>: spent before the first turn end, nothing is spendable after 3 more turn ends in a long transcript' -ForEach @(
        @{ HostKind = 'claude' }, @{ HostKind = 'codex' }
    ) {
        $p = New-Project
        Add-Filler -P $p
        Add-Human -P $p -HostKind $HostKind -Text 'approved for review round' -MessageId 'msg-1'
        Invoke-Prompt -P $p -HostKind $HostKind -Text 'approved for review round' -MessageId 'msg-1' | Out-Null
        Set-RoundSpent -P $p
        for ($i = 0; $i -lt 3; $i++) { Add-AssistantTurn -P $p -HostKind $HostKind -MessageId 'msg-1'; Invoke-TurnEnd -P $p -HostKind $HostKind }
        Get-RoundCaptures -P $p | Should -Be 1
        Test-RoundUnspent -P $p | Should -BeFalse
    }

    It '<Phrase>: one message reserves one turn across the message hook and 3 turn ends (claude, long transcript)' -ForEach @(
        @{ Phrase = 'approved for allowance reset' }, @{ Phrase = 'stop the review here' },
        @{ Phrase = 'continue without coverage until the review phase' }
    ) {
        $p = New-Project
        Add-Filler -P $p
        Add-Human -P $p -HostKind 'claude' -Text $Phrase -MessageId 'msg-1'
        Invoke-Prompt -P $p -HostKind 'claude' -Text $Phrase -MessageId 'msg-1' | Out-Null
        for ($i = 0; $i -lt 3; $i++) { Add-AssistantTurn -P $p -HostKind 'claude' -MessageId 'msg-1'; Invoke-TurnEnd -P $p -HostKind 'claude' }
        Get-ReservedTurns -P $p | Should -Be 1
    }
}

Describe 'The key never wedges and the backup path still works' {
    It 'a genuine retype (a new message ID) after the first is spent records a second approval' {
        $p = New-Project
        Add-Human -P $p -HostKind 'claude' -Text 'approved for review round' -MessageId 'msg-1'
        Invoke-Prompt -P $p -HostKind 'claude' -Text 'approved for review round' -MessageId 'msg-1' | Out-Null
        Add-AssistantTurn -P $p -HostKind 'claude' -MessageId 'msg-1'; Invoke-TurnEnd -P $p -HostKind 'claude'
        Set-RoundSpent -P $p
        Add-Human -P $p -HostKind 'claude' -Text 'approved for review round' -MessageId 'msg-2'
        Invoke-Prompt -P $p -HostKind 'claude' -Text 'approved for review round' -MessageId 'msg-2' | Out-Null
        Add-AssistantTurn -P $p -HostKind 'claude' -MessageId 'msg-2'; Invoke-TurnEnd -P $p -HostKind 'claude'
        Get-RoundCaptures -P $p | Should -Be 2
        Test-RoundUnspent -P $p | Should -BeTrue
    }

    It '<HostKind>: when the message hook never ran, the turn end records the approval once, and later turn ends nothing' -ForEach @(
        @{ HostKind = 'claude' }, @{ HostKind = 'codex' }
    ) {
        $p = New-Project
        Add-Filler -P $p
        Add-Human -P $p -HostKind $HostKind -Text 'approved for review round' -MessageId 'msg-1'
        for ($i = 0; $i -lt 3; $i++) { Add-AssistantTurn -P $p -HostKind $HostKind -MessageId 'msg-1'; Invoke-TurnEnd -P $p -HostKind $HostKind }
        Get-RoundCaptures -P $p | Should -Be 1
    }

    It 'claude: a typed transcript entry with no promptId is not recorded by the turn end (no second key)' {
        $p = New-Project
        Add-Human -P $p -HostKind 'claude' -Text 'approved for review round' -NoMessageId
        Invoke-Prompt -P $p -HostKind 'claude' -Text 'approved for review round' -MessageId 'msg-1' | Out-Null
        for ($i = 0; $i -lt 2; $i++) { Add-AssistantTurn -P $p -HostKind 'claude' -MessageId 'msg-1'; Invoke-TurnEnd -P $p -HostKind 'claude' }
        Get-RoundCaptures -P $p | Should -Be 1
        Get-ReservedTurns -P $p | Should -Be 1
    }
}

Describe 'Entries that are not a human message never record (claude)' {
    # A guard more than a RED: the one-line rule already refuses this summary. T018 lets a phrase on its own line
    # count, and this case is what keeps a summary out of authority then.
    It 'a compaction summary that quotes an approval line, under the /compact entry promptId, records nothing at the turn end' {
        $p = New-Project
        Add-Line -P $p -Entry @{ type = 'user'; isCompactSummary = $true; isVisibleInTranscriptOnly = $true; promptId = 'msg-compact'; uuid = ([guid]::NewGuid().ToString()); timestamp = ([DateTimeOffset]::UtcNow.ToString('o')); message = @{ role = 'user'; content = "This session is being continued from a previous conversation.`napproved for review round`nThe maintainer approved the round earlier." } }
        for ($i = 0; $i -lt 2; $i++) { Add-AssistantTurn -P $p -HostKind 'claude' -MessageId 'msg-compact'; Invoke-TurnEnd -P $p -HostKind 'claude' }
        Get-RoundCaptures -P $p | Should -Be 0
    }
}

Describe 'Copilot: the message hook is the only recording path, and a miss is reported, never dropped (DA-2)' {
    It 'an approval the message hook recorded is not reported' {
        $p = New-Project
        Add-Human -P $p -HostKind 'copilot' -Text 'approved for review round'
        Invoke-Prompt -P $p -HostKind 'copilot' -Text 'approved for review round' | Out-Null
        Add-AssistantTurn -P $p -HostKind 'copilot'; Invoke-TurnEnd -P $p -HostKind 'copilot'
        @(Get-NotRecordedReports -P $p).Count | Should -Be 0
    }

    It 'an approval the message hook missed is not recorded by the turn end, is reported once, and the next message shows one line' {
        $p = New-Project
        Add-Human -P $p -HostKind 'copilot' -Text 'approved for review round'
        for ($i = 0; $i -lt 3; $i++) { Add-AssistantTurn -P $p -HostKind 'copilot'; Invoke-TurnEnd -P $p -HostKind 'copilot' }
        Get-RoundCaptures -P $p | Should -Be 0
        @(Get-NotRecordedReports -P $p).Count | Should -Be 1
        $shown = Invoke-Prompt -P $p -HostKind 'copilot' -Text 'what is next?'
        $shown | Should -Match 'was not recorded'
        $shown | Should -Match 'approved for review round'
        $again = Invoke-Prompt -P $p -HostKind 'copilot' -Text 'and now?'
        $again | Should -Not -Match 'was not recorded'
    }
}

Describe 'Co-review round 1 (iteration 002): the six findings, each as its own replay' {
    It 'finding 1, <HostKind>: a spent approval recorded before the message-ID key is not recorded again by the first turn ends after an update' -ForEach @(
        @{ HostKind = 'claude' }, @{ HostKind = 'codex' }
    ) {
        $p = New-Project
        Add-Human -P $p -HostKind $HostKind -Text 'approved for review round' -MessageId 'msg-1'
        Invoke-Prompt -P $p -HostKind $HostKind -Text 'approved for review round' -BeforeMessageIds | Out-Null
        Set-RoundSpent -P $p
        for ($i = 0; $i -lt 3; $i++) { Add-AssistantTurn -P $p -HostKind $HostKind -MessageId 'msg-1'; Invoke-TurnEnd -P $p -HostKind $HostKind }
        Get-RoundCaptures -P $p | Should -Be 1
        Test-RoundUnspent -P $p | Should -BeFalse
    }

    It 'finding 1: a genuine retype after the update still records' {
        $p = New-Project
        Add-Human -P $p -HostKind 'claude' -Text 'approved for review round' -MessageId 'msg-1'
        Invoke-Prompt -P $p -HostKind 'claude' -Text 'approved for review round' -BeforeMessageIds | Out-Null
        Set-RoundSpent -P $p
        Add-AssistantTurn -P $p -HostKind 'claude' -MessageId 'msg-1'; Invoke-TurnEnd -P $p -HostKind 'claude'
        Add-Human -P $p -HostKind 'claude' -Text 'approved for review round' -MessageId 'msg-2'
        Invoke-Prompt -P $p -HostKind 'claude' -Text 'approved for review round' -MessageId 'msg-2' | Out-Null
        Add-AssistantTurn -P $p -HostKind 'claude' -MessageId 'msg-2'; Invoke-TurnEnd -P $p -HostKind 'claude'
        Get-RoundCaptures -P $p | Should -Be 2
        Test-RoundUnspent -P $p | Should -BeTrue
    }

    It 'finding 2, copilot: a withdrawal the message hook missed is still recorded by the turn end, once' {
        $p = New-Project
        Add-Human -P $p -HostKind 'copilot' -Text 'approved for review round'
        Invoke-Prompt -P $p -HostKind 'copilot' -Text 'approved for review round' | Out-Null
        Add-AssistantTurn -P $p -HostKind 'copilot'; Invoke-TurnEnd -P $p -HostKind 'copilot'
        Test-RoundUnspent -P $p | Should -BeTrue
        Add-Human -P $p -HostKind 'copilot' -Text 'withdraw the approval'
        for ($i = 0; $i -lt 3; $i++) { Add-AssistantTurn -P $p -HostKind 'copilot'; Invoke-TurnEnd -P $p -HostKind 'copilot' }
        Test-RoundUnspent -P $p | Should -BeFalse
        $w = Join-Path $p.Root '.specrew/authority/withdrawals.jsonl'
        @(Get-Content -LiteralPath $w | Where-Object { $_.Trim() }).Count | Should -Be 1
    }

    It 'finding 2, copilot: a missed <Kind> is reported too' -ForEach @(
        @{ Kind = 'workshop-repair'; Text = 'approved for workshop repair' }
        @{ Kind = 'partial-review-signoff'; Text = 'approved for partial review signoff - the open finding is a wording note' }
    ) {
        $p = New-Project
        Add-Human -P $p -HostKind 'copilot' -Text $Text
        Add-AssistantTurn -P $p -HostKind 'copilot'; Invoke-TurnEnd -P $p -HostKind 'copilot'
        $r = @(Get-NotRecordedReports -P $p)
        $r.Count | Should -Be 1
        [string]$r[0].phrase | Should -Be $Kind
    }

    It 'finding 3, copilot: the same phrase typed again and missed is reported, though the first was recorded' {
        $p = New-Project
        Add-Human -P $p -HostKind 'copilot' -Text 'approved for review round'
        Invoke-Prompt -P $p -HostKind 'copilot' -Text 'approved for review round' | Out-Null
        Add-AssistantTurn -P $p -HostKind 'copilot'; Invoke-TurnEnd -P $p -HostKind 'copilot'
        Set-RoundSpent -P $p
        Add-Human -P $p -HostKind 'copilot' -Text 'approved for review round'
        Add-AssistantTurn -P $p -HostKind 'copilot'; Invoke-TurnEnd -P $p -HostKind 'copilot'
        @(Get-NotRecordedReports -P $p).Count | Should -Be 1
    }

    It 'finding 3, copilot: another session recording the same phrase does not vouch for this one' {
        $p = New-Project
        Invoke-Prompt -P $p -HostKind 'copilot' -Text 'approved for review round' -Session 's2' | Out-Null
        Add-Human -P $p -HostKind 'copilot' -Text 'approved for review round'
        Add-AssistantTurn -P $p -HostKind 'copilot'; Invoke-TurnEnd -P $p -HostKind 'copilot'
        @(Get-NotRecordedReports -P $p).Count | Should -Be 1
    }

    It 'finding 4, copilot: a miss in one session is said in that session, and never in another' {
        $p = New-Project
        $t2 = Join-Path $p.Root 'transcript-s2.jsonl'
        Add-Content -LiteralPath $t2 -Value ((@{ type = 'user.message'; id = 'e-s2'; timestamp = ([DateTimeOffset]::UtcNow.ToString('o')); data = @{ content = 'approved for review round'; messageId = 'm-s2' } } | ConvertTo-Json -Depth 6 -Compress)) -Encoding UTF8
        Add-Content -LiteralPath $t2 -Value ((@{ type = 'assistant.message'; id = 'a-s2'; data = @{ content = 'Working on it.' } } | ConvertTo-Json -Depth 6 -Compress)) -Encoding UTF8
        Invoke-TurnEnd -P $p -HostKind 'copilot' -Session 's2' -Transcript $t2
        @(Get-NotRecordedReports -P $p).Count | Should -Be 1
        Invoke-Prompt -P $p -HostKind 'copilot' -Text 'what is next?' -Session 's1' | Should -Not -Match 'was not recorded'
        Invoke-Prompt -P $p -HostKind 'copilot' -Text 'what is next?' -Session 's2' | Should -Match 'was not recorded'
    }

    It 'finding 5, copilot: a missed abandon is reported with its own retype, never stop-here' {
        $p = New-Project
        Add-Human -P $p -HostKind 'copilot' -Text 'abandon this review campaign'
        Add-AssistantTurn -P $p -HostKind 'copilot'; Invoke-TurnEnd -P $p -HostKind 'copilot'
        $r = @(Get-NotRecordedReports -P $p)
        $r.Count | Should -Be 1
        [string]$r[0].retype | Should -Be 'abandon this review campaign'
        [string]$r[0].choice | Should -Be 'abandon'
        Invoke-Prompt -P $p -HostKind 'copilot' -Text 'what is next?' | Should -Match 'abandon this review campaign'
    }

    It 'finding 6, copilot: an approval recorded with a trailing space is not reported as missing' {
        $p = New-Project
        Add-Human -P $p -HostKind 'copilot' -Text 'approved for review round '
        Invoke-Prompt -P $p -HostKind 'copilot' -Text 'approved for review round ' | Out-Null
        Add-AssistantTurn -P $p -HostKind 'copilot'; Invoke-TurnEnd -P $p -HostKind 'copilot'
        Get-RoundCaptures -P $p | Should -Be 1
        @(Get-NotRecordedReports -P $p).Count | Should -Be 0
    }

    It 'under a message-ID key, a retype is not logged as a double mint' {
        $p = New-Project
        Add-Human -P $p -HostKind 'claude' -Text 'approved for review round' -MessageId 'msg-1'
        Add-AssistantTurn -P $p -HostKind 'claude' -MessageId 'msg-1'; Invoke-TurnEnd -P $p -HostKind 'claude'
        Set-RoundSpent -P $p
        Add-Human -P $p -HostKind 'claude' -Text 'approved for review round' -MessageId 'msg-2'
        Invoke-Prompt -P $p -HostKind 'claude' -Text 'approved for review round' -MessageId 'msg-2' | Out-Null
        $f = Join-Path $p.Root '.specrew/authority/exhausted-turns.jsonl'
        (Get-Content -LiteralPath $f -Raw) | Should -Not -Match 'cross-channel-double-mint'
    }
}

Describe 'Co-review round 2 (iteration 002): the four findings, each as its own replay' {
    It 'finding 1: a spent pre-update approval typed with a trailing space is not recorded again after the update' {
        $p = New-Project
        Add-Human -P $p -HostKind 'claude' -Text 'approved for review round ' -MessageId 'msg-1'
        Invoke-Prompt -P $p -HostKind 'claude' -Text 'approved for review round ' -BeforeMessageIds | Out-Null
        # As the old message hook wrote it: the content hash of the UNTRIMMED text, and no identity field.
        $ledger = Join-Path $p.Root '.specrew/authority/exhausted-turns.jsonl'
        $untrimmed = ([Convert]::ToHexString([Security.Cryptography.SHA256]::HashData([Text.Encoding]::UTF8.GetBytes('approved for review round ')))).ToLowerInvariant()
        $rows = foreach ($line in [IO.File]::ReadAllLines($ledger)) {
            $o = $line | ConvertFrom-Json
            $o.content_hash = $untrimmed
            $o.PSObject.Properties.Remove('identity'); $o.PSObject.Properties.Remove('session_id')
            $o | ConvertTo-Json -Compress
        }
        [IO.File]::WriteAllLines($ledger, [string[]]$rows)
        Set-RoundSpent -P $p
        for ($i = 0; $i -lt 3; $i++) { Add-AssistantTurn -P $p -HostKind 'claude' -MessageId 'msg-1'; Invoke-TurnEnd -P $p -HostKind 'claude' }
        Get-RoundCaptures -P $p | Should -Be 1
        Test-RoundUnspent -P $p | Should -BeFalse
    }

    It 'finding 2, <HostKind>: an approval the message hook received but could not save is reported, and said in that same turn' -ForEach @(
        @{ HostKind = 'copilot' }, @{ HostKind = 'claude' }
    ) {
        $p = New-Project
        $dir = Join-Path $p.Root '.specrew/review/round-approval'
        New-Item -ItemType Directory -Path $dir -Force | Out-Null
        $locked = Join-Path $dir 'pending-round-approval.json'
        Set-Content -LiteralPath $locked -Value '{}' -Encoding UTF8
        $id = if ($HostKind -eq 'copilot') { '' } else { 'msg-1' }
        Add-Human -P $p -HostKind $HostKind -Text 'approved for review round' -MessageId 'msg-1'
        $hold = [IO.File]::Open($locked, 'Open', 'ReadWrite', 'None')
        $shown = $null
        try { $shown = Invoke-Prompt -P $p -HostKind $HostKind -Text 'approved for review round' -MessageId $id }
        finally { $hold.Dispose() }
        $shown | Should -Match 'could not be saved'
        Add-AssistantTurn -P $p -HostKind $HostKind -MessageId 'msg-1'; Invoke-TurnEnd -P $p -HostKind $HostKind
        $r = @(Get-NotRecordedReports -P $p)
        $r.Count | Should -Be 1
        [string]$r[0].reason | Should -Be 'not-saved'
        Invoke-Prompt -P $p -HostKind $HostKind -Text 'what is next?' -MessageId 'msg-2' | Should -Not -Match 'could not be saved'
    }

    It 'finding 3, copilot: an identical approval outside the transcript window never vouches for a missed one typed 30 seconds later' {
        $p = New-Project
        Add-Human -P $p -HostKind 'copilot' -Text 'approved for review round'
        Invoke-Prompt -P $p -HostKind 'copilot' -Text 'approved for review round' | Out-Null
        Set-RoundSpent -P $p
        Add-Filler -P $p
        Add-Human -P $p -HostKind 'copilot' -Text 'approved for review round' -SecondsFromNow 30
        Add-AssistantTurn -P $p -HostKind 'copilot'; Invoke-TurnEnd -P $p -HostKind 'copilot'
        @(Get-NotRecordedReports -P $p).Count | Should -Be 1
    }

    It 'finding 4: a not-recorded line whose output was withheld is said again at the next message' {
        $p = New-Project
        $journal = Join-Path $p.Root '.specrew/runtime/authority-capture-drops.jsonl'
        New-Item -ItemType Directory -Path (Split-Path -Parent $journal) -Force | Out-Null
        $now = [DateTimeOffset]::UtcNow.ToString('o')
        [IO.File]::WriteAllLines($journal, [string[]]@(
                (@{ event = 'authority-phrase-not-recorded'; phrase = 'review-round-approval'; reason = 'message-hook-did-not-record'; retype = 'approved for review round'; choice = ''; entry_key = 'e1'; host_kind = 'copilot'; session_id = 's1'; recorded_at = $now } | ConvertTo-Json -Compress)
                (@{ event = 'authority-phrase-not-recorded-disclosed'; entry_key = 'e1'; host_kind = 'copilot'; session_id = 's1'; recorded_at = $now } | ConvertTo-Json -Compress)
                (@{ event = 'authority-phrase-not-recorded-undelivered'; entry_key = 'e1'; host_kind = 'copilot'; session_id = 's1'; recorded_at = $now } | ConvertTo-Json -Compress)))
        Invoke-Prompt -P $p -HostKind 'copilot' -Text 'what is next?' | Should -Match 'was not recorded'
        Invoke-Prompt -P $p -HostKind 'copilot' -Text 'and now?' | Should -Not -Match 'was not recorded'
    }
}

Describe 'Co-review round 3 (iteration 002): the three findings, each as its own replay' {
    It 'finding 1, copilot: a recovered withdrawal runs once as the window slides, and never revokes a later approval from another session' {
        $p = New-Project
        Add-Filler -P $p
        Add-Human -P $p -HostKind 'copilot' -Text 'approved for review round'
        Invoke-Prompt -P $p -HostKind 'copilot' -Text 'approved for review round' | Out-Null
        Add-Human -P $p -HostKind 'copilot' -Text 'withdraw the approval'
        Add-AssistantTurn -P $p -HostKind 'copilot'; Invoke-TurnEnd -P $p -HostKind 'copilot'
        Test-RoundUnspent -P $p | Should -BeFalse
        # Another session records a new approval; this session's conversation grows, sliding the window.
        Invoke-Prompt -P $p -HostKind 'copilot' -Text 'approved for review round' -Session 's2' | Out-Null
        Test-RoundUnspent -P $p | Should -BeTrue
        for ($i = 0; $i -lt 3; $i++) { Add-AssistantTurn -P $p -HostKind 'copilot'; Add-AssistantTurn -P $p -HostKind 'copilot'; Invoke-TurnEnd -P $p -HostKind 'copilot' }
        Test-RoundUnspent -P $p | Should -BeTrue
        $w = Join-Path $p.Root '.specrew/authority/withdrawals.jsonl'
        @(Get-Content -LiteralPath $w | Where-Object { $_.Trim() }).Count | Should -Be 1
    }

    It 'finding 2, <HostKind>: a workshop repair approval whose save failed is reported, though its writer handles its own errors' -ForEach @(
        @{ HostKind = 'copilot' }, @{ HostKind = 'claude' }
    ) {
        $p = New-Project
        # The provider loads the workshop store from the project's own deployed copy, as in a real project.
        $deployed = Join-Path $p.Root '.specify/extensions/specrew-speckit/scripts'
        New-Item -ItemType Directory -Path $deployed -Force | Out-Null
        Copy-Item -LiteralPath (Join-Path $script:RepoRoot 'extensions/specrew-speckit/scripts/workshop-authority-store.ps1') -Destination $deployed
        $feature = '001-fixture'
        $controller = Join-Path $p.Root ('specs/' + $feature + '/lens-applicability.json')
        New-Item -ItemType Directory -Path (Split-Path -Parent $controller) -Force | Out-Null
        Set-Content -LiteralPath $controller -Value '{"schema_version":"1"}' -Encoding UTF8 -NoNewline
        $sha = ([Convert]::ToHexString([Security.Cryptography.SHA256]::HashData([IO.File]::ReadAllBytes($controller)))).ToLowerInvariant()
        $proposal = Join-Path $p.Root '.specrew/handover/workshop-controller-repair-proposal.json'
        New-Item -ItemType Directory -Path (Split-Path -Parent $proposal) -Force | Out-Null
        Set-Content -LiteralPath $proposal -Value (@{ schema_version = '1.0'; feature_ref = $feature; proposal_id = ('a' * 64); controller_sha256 = $sha } | ConvertTo-Json -Compress) -Encoding UTF8
        $lockPath = Join-Path $p.Root '.specrew/runtime/workshop-controller-repair-authority.jsonl.lock'
        New-Item -ItemType Directory -Path (Split-Path -Parent $lockPath) -Force | Out-Null
        $id = if ($HostKind -eq 'copilot') { '' } else { 'msg-1' }
        Add-Human -P $p -HostKind $HostKind -Text 'approved for workshop repair' -MessageId 'msg-1'
        $hold = [IO.File]::Open($lockPath, 'OpenOrCreate', 'ReadWrite', 'None')
        $shown = $null
        try { $shown = Invoke-Prompt -P $p -HostKind $HostKind -Text 'approved for workshop repair' -MessageId $id }
        finally { $hold.Dispose() }
        Test-Path -LiteralPath (Join-Path $p.Root '.specrew/runtime/workshop-controller-repair-authority.jsonl') | Should -BeFalse
        $r = @(Get-NotRecordedReports -P $p)
        $r.Count | Should -Be 1
        [string]$r[0].reason | Should -Be 'not-saved'
        $shown | Should -Match 'could not be saved'
    }
}
