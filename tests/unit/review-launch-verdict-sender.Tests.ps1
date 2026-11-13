# Feature 203 iteration review, round A finding 1 (run-20261113-102531165-8671e9be; FR-024, B5F-066): A REVIEW LAUNCH SPENDS
# A BUDGET ONLY WHEN THE HUMAN TYPED THE VERDICT IT CAME FROM.
#
# The before-implement verdict is captured by the prompt hook, before the host writes the transcript record that says who
# sent it, and the budget snapshot is taken at that capture. The launch is where the budget is used, so the launch checks
# the verdict the budget cites - the stored grant's verdict entry, or the verdict the floor grant will cite - with the same
# sender check every other use of an authorization runs. A scheduled prompt whose whole text is the phrase grants nothing;
# neither does a verdict whose turn cannot be found or that the ledger no longer holds. A declared out-of-band verdict has
# no captured turn to check and is used as before.
BeforeAll {
    $script:RepoRoot = (Resolve-Path "$PSScriptRoot/../..").Path
    . (Join-Path $script:RepoRoot 'scripts/internal/continuous-co-review/_load.ps1')
    . (Join-Path $script:RepoRoot 'scripts/internal/bootstrap/ConversationCaptureAccessor.ps1')
    . (Join-Path $script:RepoRoot 'scripts/internal/bootstrap/HumanAuthorityStore.ps1')
    $shapes = @((Get-Content -LiteralPath (Join-Path $script:RepoRoot 'tests/fixtures/hook-payloads/claude/transcript-origins/record-shapes.json') -Raw | ConvertFrom-Json).shapes)
    $script:Typed = $shapes | Where-Object kind -eq 'typed'
    $script:Scheduled = $shapes | Where-Object kind -eq 'scheduled'
    $script:CampaignId = Get-ReviewCampaignIdForIteration -FeatureId '001-demo' -IterationNumber '001'
    $script:Phrase = 'approved for before-implement'

    # The turn the prompt hook registered for the verdict, and the transcript record the host wrote for it in the given shape.
    function script:New-VerdictTurn {
        param([Parameter(Mandatory)][string]$Root, $Shape, [switch]$Unfindable)
        New-Item -ItemType Directory -Path (Join-Path $Root '.specrew/authority') -Force | Out-Null
        $transcript = Join-Path $Root ('session-' + [guid]::NewGuid().ToString('N').Substring(0, 6) + '.jsonl')
        $messageId = 'prompt-' + [guid]::NewGuid().ToString('N').Substring(0, 12)
        $record = [ordered]@{ type = 'user'; uuid = [guid]::NewGuid().ToString(); promptId = $messageId; sessionId = 's'; timestamp = '2026-11-13T09:00:00.000Z'; message = [ordered]@{ role = 'user'; content = $script:Phrase } }
        if ($Shape.turnOrigin) { $record.turnOrigin = [string]$Shape.turnOrigin }
        if ($Shape.promptSource) { $record.promptSource = [string]$Shape.promptSource }
        if ($Shape.isMeta -eq $true) { $record.isMeta = $true }
        if ($Shape.origin_kind) { $record.origin = [ordered]@{ kind = [string]$Shape.origin_kind } }
        [IO.File]::WriteAllText($transcript, (($record | ConvertTo-Json -Depth 6 -Compress) + "`n"), [Text.UTF8Encoding]::new($false))
        $turnId = [string](Get-SpecrewTypedActIdentity -Turn ([pscustomobject]@{ host = 'claude'; message_id = $messageId; text = $script:Phrase })).Identity
        $splat = @{ ProjectRoot = $Root; TurnId = $turnId; HostKind = 'claude'; SourceEvent = 'UserPromptSubmit'; MintedWriters = ''; ContentHash = (Get-SpecrewHumanAuthorityHash -Text $script:Phrase); SessionId = 's'; Identity = 'typed-act'; TurnOrigin = 'typed-user' }
        if (-not $Unfindable) { $splat.TranscriptPath = $transcript; $splat.MessageId = $messageId }
        $null = Register-SpecrewExhaustedTurn @splat
        return $turnId
    }

    # The lifecycle ledger with this iteration's before-implement verdict, as the boundary sync records it.
    function script:New-LaunchProject {
        param([string]$Root, [string]$Evidence = 'hook-captured-user-prompt', [string]$TurnIdentity = '', [string]$AuthorizationId = 'auth-before-implement-0001')
        $root = if ([string]::IsNullOrWhiteSpace($Root)) { Join-Path $TestDrive ([guid]::NewGuid().ToString('N')) } else { $Root }
        New-Item -ItemType Directory -Path (Join-Path $root '.specrew') -Force | Out-Null
        $entry = [ordered]@{ from_boundary = 'tasks'; to_boundary = 'before-implement'; verdict_text = $script:Phrase; authorizing_human = 'unattributed'
            feature_ref = '001-demo'; recorded_at = '2026-11-13T09:00:01Z'; authorization_id = $AuthorizationId; evidence_source = $Evidence }
        if (-not [string]::IsNullOrWhiteSpace($TurnIdentity)) { $entry.turn_identity = $TurnIdentity }
        $context = [ordered]@{
            session_state = [ordered]@{ active = $true; boundary_type = 'before-implement'; feature_ref = '001-demo'; iteration_number = '001' }
            boundary_enforcement = [ordered]@{ last_authorized_boundary = 'before-implement'; verdict_history = @($entry) }
        }
        [IO.File]::WriteAllText((Join-Path $root '.specrew/start-context.json'), ($context | ConvertTo-Json -Depth 8), [Text.UTF8Encoding]::new($false))
        return $root
    }

    # The grant T007's snapshot writes at the verdict's capture, citing that verdict.
    function script:Add-Grant([string]$Root, [string]$VerdictEntry = 'auth-before-implement-0001') {
        $resolution = [pscustomobject]@{ budget_total = 4; host_order = @(); host_order_stated = $false; infra_failure_cap = 2
            budget_source = 'plan'; ceiling = 10; plan_path = 'specs/001-demo/plan.md'; plan_hash = ('a' * 64) }
        $fact = New-ReviewBudgetGrantFact -CampaignId $script:CampaignId -Resolution $resolution -VerdictEntry $VerdictEntry -ObservedAt '2026-11-13T09:00:02.0000000+00:00'
        $null = Add-ReviewCampaignBudgetGrantFact -StoreRoot (Join-Path $Root '.specrew/review/authority') -Fact $fact
    }

    function script:Resolve-Launch([string]$Root) {
        Resolve-ReviewCampaignLaunchAuthority -RepoRoot $Root -StoreRoot (Join-Path $Root '.specrew/review/authority') -CampaignId $script:CampaignId -FeatureId '001-demo' -IterationNumber '001' 2>$null
    }
}

Describe 'a stored budget grant is spent only when the human typed the verdict it cites' {
    It '<label>' -ForEach @(
        @{ label = 'typed: the grant is spent'; shape = 'Typed'; unfindable = $false; ok = $true }
        @{ label = 'a scheduled prompt whose whole text is the phrase: refused'; shape = 'Scheduled'; unfindable = $false; ok = $false }
        @{ label = 'a turn that cannot be found: refused'; shape = 'Typed'; unfindable = $true; ok = $false }
    ) {
        $root = Join-Path $TestDrive ([guid]::NewGuid().ToString('N'))
        $turn = script:New-VerdictTurn -Root $root -Shape (Get-Variable -Name $shape -Scope Script -ValueOnly) -Unfindable:$unfindable
        $null = script:New-LaunchProject -Root $root -TurnIdentity $turn
        script:Add-Grant -Root $root
        $got = script:Resolve-Launch -Root $root
        [bool]$got.ok | Should -Be $ok
        if (-not $ok) {
            [string]$got.reason | Should -BeExactly 'review-budget-verdict-not-confirmed'
            [string]$got.detail | Should -Match 'Nothing was launched, recorded or spent'
        }
        else { [string]$got.reason | Should -BeExactly 'budget-grant' }
    }

    It 'a grant whose cited verdict the ledger does not hold is refused' {
        $root = script:New-LaunchProject -AuthorizationId 'auth-some-other-verdict'
        script:Add-Grant -Root $root -VerdictEntry 'auth-before-implement-0001'
        $got = script:Resolve-Launch -Root $root
        [bool]$got.ok | Should -BeFalse
        [string]$got.reason | Should -BeExactly 'review-budget-verdict-not-confirmed'
    }

    It 'a grant citing a declared out-of-band verdict (no captured turn to check) is spent as before' {
        $root = script:New-LaunchProject -Evidence 'fixture-out-of-band'
        script:Add-Grant -Root $root
        $got = script:Resolve-Launch -Root $root
        [bool]$got.ok | Should -BeTrue
        [string]$got.reason | Should -BeExactly 'budget-grant'
    }
}

Describe 'the floor grant is recorded only when the human typed the verdict it will cite' {
    It '<label>' -ForEach @(
        @{ label = 'typed: the floor is granted'; shape = 'Typed'; ok = $true }
        @{ label = 'scheduled: refused'; shape = 'Scheduled'; ok = $false }
    ) {
        $root = Join-Path $TestDrive ([guid]::NewGuid().ToString('N'))
        $turn = script:New-VerdictTurn -Root $root -Shape (Get-Variable -Name $shape -Scope Script -ValueOnly)
        $null = script:New-LaunchProject -Root $root -TurnIdentity $turn
        $got = script:Resolve-Launch -Root $root
        [bool]$got.ok | Should -Be $ok
        if ($ok) { [string]$got.reason | Should -BeExactly 'budget-floor' } else { [string]$got.reason | Should -BeExactly 'review-budget-verdict-not-confirmed' }
    }
}
