# Feature 203 T013 (B5F-066; maintainer rulings 2026-11-12): EVERY PLACE THAT USES AN AUTHORIZATION CHECKS WHO SENT IT, where
# the authorization is read from its store, so a place cannot skip the check and a new one gets it for free.
#
# Each consumer is shown the same authorization twice: once from a turn whose transcript record says the human typed it,
# once from a scheduled prompt whose whole text is the phrase (text the session wrote for itself). The first is used; the
# second is not, and the human is told what to do. A turn that cannot be found is not used either. The last case is the
# whole path: a scheduled prompt arrives through the prompt hook before its transcript record exists, is captured, and is
# refused when it is used.
BeforeAll {
    $script:RepoRoot = (Resolve-Path "$PSScriptRoot/../..").Path
    . (Join-Path $script:RepoRoot 'scripts/internal/bootstrap/HumanAuthorityStore.ps1')
    . (Join-Path $script:RepoRoot 'scripts/internal/bootstrap/ConversationCaptureAccessor.ps1')
    . (Join-Path $script:RepoRoot 'scripts/internal/bootstrap/HandoverStore.ps1')
    . (Join-Path $script:RepoRoot 'extensions/specrew-speckit/scripts/shared-governance.ps1')
    $shapes = @((Get-Content -LiteralPath (Join-Path $script:RepoRoot 'tests/fixtures/hook-payloads/claude/transcript-origins/record-shapes.json') -Raw | ConvertFrom-Json).shapes)
    $script:Typed = $shapes | Where-Object kind -eq 'typed'
    $script:Scheduled = $shapes | Where-Object kind -eq 'scheduled'

    # One project, one turn in its ledger, and that turn's transcript record in the given shape.
    function script:New-Turn {
        param([Parameter(Mandatory)][string]$Root, [Parameter(Mandatory)][string]$Text, $Shape, [switch]$Unfindable)
        New-Item -ItemType Directory -Path (Join-Path $Root '.specrew/authority') -Force | Out-Null
        $transcript = Join-Path $Root ('session-' + [guid]::NewGuid().ToString('N').Substring(0, 6) + '.jsonl')
        $messageId = 'prompt-' + [guid]::NewGuid().ToString('N').Substring(0, 12)
        $record = [ordered]@{ type = 'user'; uuid = [guid]::NewGuid().ToString(); promptId = $messageId; sessionId = 's'; timestamp = '2026-11-12T19:00:00.000Z'; message = [ordered]@{ role = 'user'; content = $Text } }
        if ($Shape.turnOrigin) { $record.turnOrigin = [string]$Shape.turnOrigin }
        if ($Shape.promptSource) { $record.promptSource = [string]$Shape.promptSource }
        if ($Shape.isMeta -eq $true) { $record.isMeta = $true }
        if ($Shape.origin_kind) { $record.origin = [ordered]@{ kind = [string]$Shape.origin_kind } }
        [IO.File]::WriteAllText($transcript, (($record | ConvertTo-Json -Depth 6 -Compress) + "`n"), [Text.UTF8Encoding]::new($false))
        $turnId = [string](Get-SpecrewTypedActIdentity -Turn ([pscustomobject]@{ host = 'claude'; message_id = $messageId; text = $Text })).Identity
        $splat = @{ ProjectRoot = $Root; TurnId = $turnId; HostKind = 'claude'; SourceEvent = 'UserPromptSubmit'; MintedWriters = ''; ContentHash = (Get-SpecrewHumanAuthorityHash -Text $Text); SessionId = 's'; Identity = 'typed-act'; TurnOrigin = 'typed-user' }
        if (-not $Unfindable) { $splat.TranscriptPath = $transcript; $splat.MessageId = $messageId }
        $null = Register-SpecrewExhaustedTurn @splat
        return $turnId
    }
    function script:New-Root { $r = Join-Path $TestDrive ([guid]::NewGuid().ToString('N')); New-Item -ItemType Directory -Path $r -Force | Out-Null; return $r }
}

Describe 'the allowance reset (top-up) is used only when the human typed it' {
    It '<label>' -ForEach @(
        @{ label = 'typed: used'; shape = 'Typed'; unfindable = $false; usable = $true }
        @{ label = 'a scheduled prompt whose whole text is the phrase: not used'; shape = 'Scheduled'; unfindable = $false; usable = $false }
        @{ label = 'a turn that cannot be found: not used'; shape = 'Typed'; unfindable = $true; usable = $false }
    ) {
        $root = script:New-Root
        $turn = script:New-Turn -Root $root -Text 'approved for allowance reset' -Shape (Get-Variable -Name $shape -Scope Script -ValueOnly) -Unfindable:$unfindable
        $null = Write-SpecrewAllowanceResetAuthorization -ProjectRoot $root -Response 'approved for allowance reset' -HostKind 'claude' -SourceEvent 'UserPromptSubmit' -TurnIdentity $turn
        $got = Get-SpecrewAllowanceResetAuthorization -ProjectRoot $root 2>$null
        ($null -ne $got) | Should -Be $usable
    }
}

Describe 'the pause decision (stop the review here) is used only when the human typed it' {
    It '<label>' -ForEach @(
        @{ label = 'typed: used'; shape = 'Typed'; usable = $true }
        @{ label = 'scheduled: not used'; shape = 'Scheduled'; usable = $false }
    ) {
        $root = script:New-Root
        $turn = script:New-Turn -Root $root -Text 'stop the review here' -Shape (Get-Variable -Name $shape -Scope Script -ValueOnly)
        $null = Write-SpecrewPauseDecisionAuthorization -ProjectRoot $root -Response 'stop the review here' -HostKind 'claude' -SourceEvent 'UserPromptSubmit' -TurnIdentity $turn
        $got = Get-SpecrewPauseDecisionAuthorization -ProjectRoot $root -Choice 'stop-here' 2>$null
        ($null -ne $got) | Should -Be $usable
    }
}

Describe 'a stop answer is used only when the human typed it' {
    It '<label>' -ForEach @(
        @{ label = 'typed: used'; shape = 'Typed'; usable = 1 }
        @{ label = 'scheduled: not used'; shape = 'Scheduled'; usable = 0 }
    ) {
        $root = script:New-Root
        $text = 'drop finding F1'
        $turn = script:New-Turn -Root $root -Text $text -Shape (Get-Variable -Name $shape -Scope Script -ValueOnly)
        $dir = Join-Path (Get-SpecrewStopAnswerRoot -ProjectRoot $root) 'run-stop-1'
        New-Item -ItemType Directory -Path $dir -Force | Out-Null
        $fact = [ordered]@{ schema_version = '1.0'; fact_type = 'review-stop-answer'; authority_kind = 'human'; authorized_by = 'unattributed-human'; answer = 'drop'; finding = 'F1'
            verdict_text = $text; response_hash = (Get-SpecrewHumanAuthorityHash -Text $text); run_id = 'run-stop-1'; host_kind = 'claude'; source_event = 'UserPromptSubmit'
            observed_at = '2026-11-12T19:00:01Z'; spent_at = $null; turn_identity = $turn }
        [IO.File]::WriteAllText((Join-Path $dir 'answer-1.json'), ($fact | ConvertTo-Json -Depth 6), [Text.UTF8Encoding]::new($false))
        @(Get-SpecrewStopAnswerAuthorizations -ProjectRoot $root -RunId 'run-stop-1' 2>$null).Count | Should -Be $usable
    }
}

Describe 'the partial sign-off is used only when the human typed it' {
    It '<label>' -ForEach @(
        @{ label = 'typed: used'; shape = 'Typed'; usable = $true }
        @{ label = 'scheduled: not used'; shape = 'Scheduled'; usable = $false }
    ) {
        $root = script:New-Root
        $tree = ('a' * 64); $campaign = 'cmp-001-sender-i001'
        $text = 'approved for partial review signoff - provider unavailable; the maintainer accepts the residual risk'
        Write-SpecrewReviewSignoffOverrideRequest -ProjectRoot $root -TargetTreeId $tree -CampaignId $campaign -RunId 'run-001' -NowUtc '2026-11-12T18:00:00Z' | Out-Null
        $turn = script:New-Turn -Root $root -Text $text -Shape (Get-Variable -Name $shape -Scope Script -ValueOnly)
        $null = Write-SpecrewReviewSignoffOverrideAuthorization -ProjectRoot $root -Response $text -HostKind 'claude' -SourceEvent 'UserPromptSubmit' -TurnIdentity $turn -NowUtc '2026-11-12T19:00:00Z'
        $got = Get-SpecrewReviewSignoffOverrideAuthorization -ProjectRoot $root -ExpectedTargetTreeId $tree -ExpectedCampaignId $campaign 2>$null
        ($null -ne $got) | Should -Be $usable
    }
}

Describe 'the coverage deferral is used only when the human typed it' {
    It '<label>' -ForEach @(
        @{ label = 'typed: used'; shape = 'Typed'; usable = $true }
        @{ label = 'scheduled: not used'; shape = 'Scheduled'; usable = $false }
    ) {
        $root = script:New-Root
        $text = 'continue without coverage until the review phase'
        $turn = script:New-Turn -Root $root -Text $text -Shape (Get-Variable -Name $shape -Scope Script -ValueOnly)
        $null = Write-SpecrewCoverageDeferralAuthorization -ProjectRoot $root -Response $text -HostKind 'claude' -SourceEvent 'UserPromptSubmit' -TurnIdentity $turn
        $got = Get-SpecrewCoverageDeferralAuthorization -ProjectRoot $root 2>$null
        ($null -ne $got) | Should -Be $usable
    }
}

Describe 'a boundary verdict covers its crossing only when the human typed it (the shared matcher: the gate and the sync ratchet)' {
    It '<label>' -ForEach @(
        @{ label = 'typed: covers plan -> tasks'; shape = 'Typed'; covers = $true; evidence = 'hook-captured-user-prompt' }
        @{ label = 'scheduled: does not'; shape = 'Scheduled'; covers = $false; evidence = 'hook-captured-user-prompt' }
        @{ label = 'a captured verdict with no turn: does not'; shape = $null; covers = $false; evidence = 'hook-captured-from-transcript' }
        @{ label = 'a declared out-of-band authorization (no capture to check): still covers'; shape = $null; covers = $true; evidence = 'fixture-out-of-band' }
    ) {
        $root = script:New-Root
        $turn = if ($null -ne $shape) { script:New-Turn -Root $root -Text 'approved for tasks' -Shape (Get-Variable -Name $shape -Scope Script -ValueOnly) } else { '' }
        $entry = [ordered]@{ from_boundary = 'plan'; to_boundary = 'tasks'; verdict_text = 'approved for tasks'; authorizing_human = 'Alon'; recorded_at = '2026-11-12T19:00:00Z'; evidence_source = $evidence; turn_identity = $turn }
        $match = Find-SpecrewCycleScopedAuthorization -ProjectRoot $root -History @($entry) -ToBoundary 'tasks' -FromBoundary 'plan' -LastAuthorizedBoundary 'plan' 2>$null
        ($null -ne $match) | Should -Be $covers
    }
}

Describe 'workshop repair and workshop replies are used only when the human typed them' {
    BeforeAll {
        . (Join-Path $script:RepoRoot 'extensions/specrew-speckit/scripts/workshop-authority-store.ps1')
        $script:WsHash = { param([string]$t) ([Convert]::ToHexString([Security.Cryptography.SHA256]::HashData([Text.Encoding]::UTF8.GetBytes($t)))).ToLowerInvariant() }
    }

    It 'the writers record the turn identity they are handed' {
        (Get-Command Write-SpecrewWorkshopRepairAuthorization).Parameters.ContainsKey('TurnIdentity') | Should -BeTrue
        (Get-Command Write-SpecrewWorkshopAuthorityReceipt).Parameters.ContainsKey('TurnIdentity') | Should -BeTrue
    }

    It 'workshop repair, <label>' -ForEach @(
        @{ label = 'typed: used'; shape = 'Typed'; usable = $true }
        @{ label = 'scheduled: not used'; shape = 'Scheduled'; usable = $false }
    ) {
        $root = script:New-Root
        $text = 'approved for workshop repair'
        $turn = script:New-Turn -Root $root -Text $text -Shape (Get-Variable -Name $shape -Scope Script -ValueOnly)
        $proposal = ('b' * 64)
        $path = Get-SpecrewWorkshopRepairAuthorityPath -ProjectRoot $root
        New-Item -ItemType Directory -Path (Split-Path -Parent $path) -Force | Out-Null
        $record = [ordered]@{ schema_version = '1'; proposal_id = $proposal; authorization = 'human-approved'; response_hash = (& $script:WsHash $text); host_kind = 'claude'; turn_identity = $turn }
        [IO.File]::WriteAllText($path, (($record | ConvertTo-Json -Compress) + "`n"), [Text.UTF8Encoding]::new($false))
        $got = Get-SpecrewWorkshopRepairAuthorization -ProjectRoot $root -ProposalId $proposal 2>$null
        ($null -ne $got) | Should -Be $usable
    }

    It 'a workshop reply receipt, <label>' -ForEach @(
        @{ label = 'typed: used'; shape = 'Typed'; usable = $true }
        @{ label = 'scheduled: not used'; shape = 'Scheduled'; usable = $false }
    ) {
        $root = script:New-Root
        $text = 'two kinds of user: admins and guests'
        $turn = script:New-Turn -Root $root -Text $text -Shape (Get-Variable -Name $shape -Scope Script -ValueOnly)
        $path = Get-SpecrewWorkshopAuthorityReceiptPath -ProjectRoot $root
        New-Item -ItemType Directory -Path (Split-Path -Parent $path) -Force | Out-Null
        $record = [ordered]@{ schema_version = '1'; feature_ref = '001-demo'; phase = 'product-domain'; lens = ''; receipt_id = ('c' * 64); confirmation = 'human-confirmed'
            response_hash = (& $script:WsHash $text); host_kind = 'claude'; turn_identity = $turn }
        [IO.File]::WriteAllText($path, (($record | ConvertTo-Json -Compress) + "`n"), [Text.UTF8Encoding]::new($false))
        $got = Get-SpecrewWorkshopAuthorityReceipt -ProjectRoot $root -FeatureRef '001-demo' -Phase 'product-domain' 2>$null
        ($null -ne $got) | Should -Be $usable
    }
}

Describe 'the whole path: a scheduled prompt through the prompt hook, before its transcript record exists' {
    It 'is captured when it arrives, and refused when it is used, with the message saying what to do next' {
        $root = script:New-Root
        New-Item -ItemType Directory -Path (Join-Path $root '.specrew') -Force | Out-Null
        $transcript = Join-Path $root 'session.jsonl'
        [IO.File]::WriteAllText($transcript, '', [Text.UTF8Encoding]::new($false))
        # Recorded input (claude/tui-userpromptsubmit-scheduled.json), with the phrase as its whole text.
        $payload = Get-Content -LiteralPath (Join-Path $script:RepoRoot 'tests/fixtures/hook-payloads/claude/tui-userpromptsubmit-scheduled.json') -Raw | ConvertFrom-Json
        $messageId = [string]$payload.prompt_id
        $null = Invoke-SpecrewTypedAuthorityCapture -ProjectRoot $root -Response 'approved for allowance reset' -HostKind 'claude' -SourceEvent 'UserPromptSubmit' `
            -NowUtc '2026-11-12T19:00:00Z' -TurnPosition 'prompt-entry' -TurnArrival '2026-11-12T19:00:00Z' -MessageId $messageId -SessionId ([string]$payload.session_id) -TurnOrigin 'typed-user' -TranscriptPath $transcript
        (Get-SpecrewAllowanceResetAuthorization -ProjectRoot $root 2>$null) | Should -BeNullOrEmpty -Because 'the record does not exist yet, so the turn cannot be found'
        # The host writes the record after the hook: a scheduled prompt.
        $record = [ordered]@{ type = 'user'; uuid = [guid]::NewGuid().ToString(); promptId = $messageId; sessionId = [string]$payload.session_id; timestamp = '2026-11-12T19:00:00.000Z'
            turnOrigin = 'scheduled'; promptSource = 'system'; isMeta = $true; message = [ordered]@{ role = 'user'; content = 'approved for allowance reset' } }
        [IO.File]::AppendAllText($transcript, (($record | ConvertTo-Json -Depth 6 -Compress) + "`n"), [Text.UTF8Encoding]::new($false))
        Get-SpecrewAllowanceResetAuthorization -ProjectRoot $root 2>$null | Should -BeNullOrEmpty
        # The refusal names the sender, stored against the turn; its message is Get-SpecrewAuthorizationSenderRefusal's.
        $row = @(Get-Content -LiteralPath (Join-Path $root '.specrew/authority/turn-senders.jsonl') | ForEach-Object { $_ | ConvertFrom-Json })[-1]
        [string]$row.sender | Should -BeExactly 'scheduled'
        $row.accepted | Should -BeFalse
        (Get-SpecrewAuthorizationSenderRefusal -Sender 'scheduled' -Purpose 'allowance reset') | Should -Match 'scheduled prompt'
    }
}
