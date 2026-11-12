# Feature 203 T012 (FR-024, FR-041): AUDIT AND CORRELATION. Every authority record joins a typed human turn: the record names
# the turn identity, and the turn ledger (.specrew/authority/exhausted-turns.jsonl) holds that turn as one the human typed.
# A record that names no turn, names a turn the ledger lacks, or names a turn only the turn-end backstop registered without
# a confirmed typed origin, fails the audit. Run facts (spend, release, claim, run state, result, pause fact) join through
# their run's reservation. A reservation cites the budget grant and the reset that opened the current window, and the turn
# that authorized it (the round-4 shape, DRIFT-019: grant-2ea3d06fc52ba0d3f381 named no turn at all).

BeforeAll {
    $script:RepoRoot = Split-Path -Parent (Split-Path -Parent $PSScriptRoot)
    . (Join-Path $script:RepoRoot 'scripts/internal/continuous-co-review/_load.ps1')
    . (Join-Path $script:RepoRoot 'extensions/specrew-speckit/scripts/shared-governance.ps1')
    foreach ($dependency in @('HumanAuthorityStore', 'ConversationCaptureAccessor', 'ClassificationEngine', 'ProjectMetadataAccessor', 'HandoverStore')) {
        . (Join-Path $script:RepoRoot ('scripts/internal/bootstrap/' + $dependency + '.ps1'))
    }
    # Written first: the audit does not exist yet, so its cases fail one by one instead of failing the container.
    $script:AuditPath = Join-Path $script:RepoRoot 'scripts/internal/bootstrap/AuthorityAudit.ps1'
    if (Test-Path -LiteralPath $script:AuditPath -PathType Leaf) { . $script:AuditPath }
    $script:CampaignId = Get-ReviewCampaignIdForIteration -FeatureId '001-demo' -IterationNumber '007'
    $script:Utf8 = [Text.UTF8Encoding]::new($false)

    function script:Invoke-AuditGit([string]$Root, [string[]]$Arguments) {
        $null = & git -C $Root -c user.name=t -c user.email=t@example.invalid @Arguments 2>&1
        if ($LASTEXITCODE -ne 0) { throw ('fixture-git-failed:' + ($Arguments -join ' ')) }
    }

    function script:New-AuditProject([string]$Name) {
        $root = Join-Path $TestDrive $Name
        New-Item -ItemType Directory -Path (Join-Path $root 'specs/001-demo/iterations/007'), (Join-Path $root '.specrew') -Force | Out-Null
        [IO.File]::WriteAllText((Join-Path $root 'app.txt'), 'review me', $script:Utf8)
        [IO.File]::WriteAllText((Join-Path $root 'specs/001-demo/spec.md'), '# Demo design context', $script:Utf8)
        [IO.File]::WriteAllText((Join-Path $root '.gitignore'), ".specrew/`n", $script:Utf8)
        [IO.File]::WriteAllText((Join-Path $root '.specrew/config.yml'), "specrew_version: `"0.40.0`"`nbootstrap_mode: `"fixture`"", $script:Utf8)
        script:Invoke-AuditGit $root @('init', '-q')
        script:Invoke-AuditGit $root @('branch', '-m', 'main')
        script:Invoke-AuditGit $root @('add', '-A')
        script:Invoke-AuditGit $root @('commit', '-qm', 'initial')
        $config = Join-Path $root 'authority.json'
        [IO.File]::WriteAllText($config, '{"schema_version":"1.0","mode":"campaign"}', $script:Utf8)
        return [pscustomobject]@{ root = $root; config = $config; store = (Join-Path $root '.specrew/review/authority'); external = ($root + '-ext') }
    }

    # The prompt hook's reservation of a message the human typed (the real ledger writer).
    function script:Add-TypedTurn([pscustomobject]$Project, [string]$TurnId) {
        $null = Register-SpecrewExhaustedTurn -ProjectRoot $Project.root -TurnId $TurnId -HostKind 'claude' -SourceEvent 'UserPromptSubmit' `
            -MintedWriters 'fixture' -ContentHash ('c' * 64) -SessionId 's1' -Identity 'typed-act' -TurnOrigin 'typed-user' -PromptEvent ('evt-' + $TurnId)
    }

    # A stop answer the capture wrote (field shape of Write-SpecrewStopAnswerAuthorization), naming $TurnIdentity.
    function script:Add-StopAnswerCapture([pscustomobject]$Project, [string]$TurnIdentity, [string]$RunId = 'run-audit-stop') {
        $dir = Join-Path $Project.root ".specrew/review/stop-answer/$RunId"
        New-Item -ItemType Directory -Path $dir -Force | Out-Null
        $path = Join-Path $dir 'allow-reviewer-0123456789abcdef.json'
        $capture = [ordered]@{
            schema_version = '1.0'; fact_type = 'review-stop-answer'; authority_kind = 'human'; answer = 'allow-reviewer'; argument = 'copilot'
            verdict_text = 'allow reviewer copilot'; response_hash = ('d' * 64); turn_identity = $TurnIdentity; campaign_id = $script:CampaignId
            run_id = $RunId; stop_kind = 'd-host-exhausted'; observed_at = '2026-11-12T08:00:00Z'; spent_at = $null; authorization_ref = $null
        }
        [IO.File]::WriteAllText($path, ($capture | ConvertTo-Json -Depth 6), $script:Utf8)
        return $path
    }

    function script:Set-BudgetGrant([pscustomobject]$Project, [string]$TurnIdentity, [int]$Total = 2) {
        $resolution = [pscustomobject]@{
            budget_total = $Total; host_order = @(); host_order_stated = $false; infra_failure_cap = 2
            budget_source = 'plan'; ceiling = 10; plan_path = 'specs/001-demo/plan.md'; plan_hash = ('a' * 64)
        }
        $fact = New-ReviewBudgetGrantFact -CampaignId $script:CampaignId -Resolution $resolution -VerdictEntry 'auth-audit-verdict' `
            -ObservedAt '2026-11-08T08:00:00.0000000+00:00' -TurnIdentity $TurnIdentity
        $null = Add-ReviewCampaignBudgetGrantFact -StoreRoot $Project.store -Fact $fact
        return $fact
    }

    function script:New-AuditPorts([pscustomobject]$Project) {
        $candidate = [pscustomobject][ordered]@{ schema_version = '1.0'; run_id = 'x'; target_digest = 'x'; completion = 'complete'; verdict = 'pass'; summary = 'audit fixture'; findings = @() }
        $prompt = Join-Path $Project.root 'prompt.txt'
        if (-not (Test-Path -LiteralPath $prompt)) { [IO.File]::WriteAllText($prompt, 'review the target', $script:Utf8) }
        $harness = [pscustomobject]@{
            id = 'fixture-audit'
            preflight = { param($invocation) [pscustomobject]@{ ok = $true; reason = 'fixture-ready' } }
            invoke = {
                param($invocation, $environment)
                $payload = $candidate | Select-Object *
                $payload.target_digest = [string]$invocation.target_digest
                $payload.run_id = [string]$invocation.run_id
                [IO.File]::WriteAllText([string]$invocation.candidate_result_path, ($payload | ConvertTo-Json -Depth 20 -Compress), [Text.UTF8Encoding]::new($false))
                [pscustomobject]@{ exit_code = 0; output_activity = $true }
            }.GetNewClosure()
        }
        return [pscustomobject]@{
            target = New-GitReviewTargetPort -OriginRepo $Project.root -ExternalRoot $Project.external
            harness = $harness; runtime = New-ReviewFixtureRuntimePort -Outcome completed; verification = New-ReviewFixtureVerificationPort
            clock = New-ReviewSystemClockPort; prompt_path = $prompt
        }
    }

    function script:Invoke-AuditRound([pscustomobject]$Project, [string]$RunId) {
        return Invoke-ReviewCampaignCommand -RepoRoot $Project.root -FeatureId '001-demo' -IterationNumber '007' -RunId $RunId `
            -AuthorityConfigPath $Project.config -Ports (script:New-AuditPorts -Project $Project)
    }

    function script:Invoke-Audit([pscustomobject]$Project) {
        if (-not (Get-Command -Name 'Invoke-SpecrewAuthorityAudit' -ErrorAction SilentlyContinue)) { throw 'Invoke-SpecrewAuthorityAudit does not exist' }
        return Invoke-SpecrewAuthorityAudit -ProjectRoot $Project.root
    }

    function script:Get-AuditReasons($Audit) { return (@($Audit.failures | ForEach-Object { '{0}:{1}' -f $_.kind, $_.reason }) -join '; ') }
}

Describe 'the audit joins every authority record to a typed human turn (FR-024, FR-041)' {
    It 'passes a record whose turn the prompt hook reserved as typed by the human' {
        $project = script:New-AuditProject -Name 'typed'
        script:Add-TypedTurn -Project $project -TurnId 'turn-typed-1'
        $null = script:Add-StopAnswerCapture -Project $project -TurnIdentity 'turn-typed-1'
        $audit = script:Invoke-Audit -Project $project
        $audit.passed | Should -BeTrue -Because (script:Get-AuditReasons $audit)
        [int]$audit.records_checked | Should -BeGreaterThan 0
    }

    It 'fails a backstop-minted record: its only ledger row is the turn end''s, with no confirmed typed origin' {
        $project = script:New-AuditProject -Name 'backstop'
        $null = Register-SpecrewExhaustedTurn -ProjectRoot $project.root -TurnId 'turn-backstop-1' -HostKind 'claude' -SourceEvent 'stop-transcript' `
            -MintedWriters 'top-up' -ContentHash ('c' * 64) -SessionId 's1' -Identity 'typed-act'
        $path = script:Add-StopAnswerCapture -Project $project -TurnIdentity 'turn-backstop-1'
        $audit = script:Invoke-Audit -Project $project
        $audit.passed | Should -BeFalse
        $failure = @($audit.failures | Where-Object { [string]$_.path -eq $path })
        $failure.Count | Should -Be 1 -Because (script:Get-AuditReasons $audit)
        [string]$failure[0].reason | Should -BeExactly 'turn-not-typed'
    }

    It 'fails a record that names no turn, and one whose turn the ledger does not hold' {
        $project = script:New-AuditProject -Name 'unnamed'
        $none = script:Add-StopAnswerCapture -Project $project -TurnIdentity '' -RunId 'run-audit-none'
        $absent = script:Add-StopAnswerCapture -Project $project -TurnIdentity 'turn-nobody-typed' -RunId 'run-audit-absent'
        $audit = script:Invoke-Audit -Project $project
        $audit.passed | Should -BeFalse
        [string](@($audit.failures | Where-Object { [string]$_.path -eq $none })[0].reason) | Should -BeExactly 'no-turn-identity'
        [string](@($audit.failures | Where-Object { [string]$_.path -eq $absent })[0].reason) | Should -BeExactly 'turn-not-in-ledger'
    }

    It 'fails a boundary verdict recorded with no turn (the out-of-band shape)' {
        $project = script:New-AuditProject -Name 'verdict'
        $context = [ordered]@{ boundary_enforcement = [ordered]@{ verdict_history = @(
                    [ordered]@{ from_boundary = 'plan'; to_boundary = 'tasks'; verdict_text = 'approved for tasks'; authorization_id = 'auth-no-turn'; out_of_band = $true; recorded_at = '2026-11-01T09:00:00Z' }
                ) } }
        [IO.File]::WriteAllText((Join-Path $project.root '.specrew/start-context.json'), ($context | ConvertTo-Json -Depth 8), $script:Utf8)
        $audit = script:Invoke-Audit -Project $project
        $audit.passed | Should -BeFalse
        @($audit.failures | Where-Object { [string]$_.kind -eq 'boundary-verdict' -and [string]$_.id -eq 'auth-no-turn' -and [string]$_.reason -eq 'no-turn-identity' }).Count | Should -Be 1 -Because (script:Get-AuditReasons $audit)
    }

    It 'the round-4 shape: a launch grant and its reservation naming no turn fail, though the budget grant names one' {
        $project = script:New-AuditProject -Name 'round4'
        script:Add-TypedTurn -Project $project -TurnId 'turn-before-implement'
        $budget = script:Set-BudgetGrant -Project $project -TurnIdentity 'turn-before-implement'
        $grant = [pscustomobject][ordered]@{
            schema_version = '1.0'; fact_type = 'grant'; campaign_id = $script:CampaignId; grant_id = 'grant-2ea3d06fc52ba0d3f381'
            slots = 1; authority_kind = 'human'; authorization_ref = [string]$budget.grant_id; observed_at = '2026-11-01T19:48:00Z'
        }
        $null = Add-ReviewCampaignGrantFact -StoreRoot $project.store -Fact $grant
        $reservation = Request-ReviewCampaignReservationFact -StoreRoot $project.store -CampaignId $script:CampaignId -RunId 'run-round-4' `
            -ReservationId 'reservation-round-4-000001' -ObservedAt '2026-11-02T10:00:00Z'
        $reservation.acquired | Should -BeTrue
        $audit = script:Invoke-Audit -Project $project
        $audit.passed | Should -BeFalse
        @($audit.failures | Where-Object { [string]$_.kind -eq 'launch-grant' -and [string]$_.id -eq 'grant-2ea3d06fc52ba0d3f381' }).Count | Should -Be 1 -Because (script:Get-AuditReasons $audit)
        @($audit.failures | Where-Object { [string]$_.kind -eq 'reservation' -and [string]$_.id -eq 'reservation-round-4-000001' }).Count | Should -Be 1 -Because (script:Get-AuditReasons $audit)
        @($audit.failures | Where-Object { [string]$_.kind -eq 'budget-grant' }).Count | Should -Be 0 -Because (script:Get-AuditReasons $audit)
    }

    It 'fails a run fact whose run has no reservation joined to a typed turn' {
        $project = script:New-AuditProject -Name 'orphan-run'
        $null = Write-ReviewRunAuthorityFact -StoreRoot $project.store -CampaignId $script:CampaignId -RunId 'run-orphan' -Stage requested `
            -Fact (New-ReviewRunStateFact -CampaignId $script:CampaignId -RunId 'run-orphan' -TargetDigest 'pending-target' -HarnessId 'fixture' -State requested)
        $audit = script:Invoke-Audit -Project $project
        $audit.passed | Should -BeFalse
        @($audit.failures | Where-Object { [string]$_.kind -eq 'run-fact' -and [string]$_.reason -eq 'run-without-authorized-reservation' }).Count | Should -Be 1 -Because (script:Get-AuditReasons $audit)
    }
}

Describe 'the records name the turn that authorized them (FR-024, FR-041)' {
    It 'a governed launch: the launch grant and the reservation name the budget grant''s turn, the reservation cites the budget grant, and the audit passes' {
        $project = script:New-AuditProject -Name 'launch'
        script:Add-TypedTurn -Project $project -TurnId 'turn-before-implement'
        $budget = script:Set-BudgetGrant -Project $project -TurnIdentity 'turn-before-implement'
        [string]$budget.turn_identity | Should -BeExactly 'turn-before-implement'
        $run = script:Invoke-AuditRound -Project $project -RunId 'run-audit-launch-1'
        $run.invoked | Should -BeTrue -Because ([string]$run.reason)
        $grant = @(Get-ReviewAuthorityCampaignFacts -StoreRoot $project.store -CampaignId $script:CampaignId -Kind grants)[0]
        [string]$grant.turn_identity | Should -BeExactly 'turn-before-implement'
        $reservation = @(Get-ReviewAuthorityCampaignFacts -StoreRoot $project.store -CampaignId $script:CampaignId -Kind reservations)[0]
        [string]$reservation.turn_identity | Should -BeExactly 'turn-before-implement'
        [string]$reservation.budget_grant_id | Should -BeExactly ([string]$budget.grant_id)
        $reservation.PSObject.Properties['reset_id'] | Should -BeNullOrEmpty
        $audit = script:Invoke-Audit -Project $project
        $audit.passed | Should -BeTrue -Because (script:Get-AuditReasons $audit)
    }

    It 'after a reset, the next reservation cites the reset that opened the window and names the reset''s turn' {
        $project = script:New-AuditProject -Name 'reset'
        script:Add-TypedTurn -Project $project -TurnId 'turn-before-implement'
        script:Add-TypedTurn -Project $project -TurnId 'turn-allowance-reset'
        $budget = script:Set-BudgetGrant -Project $project -TurnIdentity 'turn-before-implement'
        (script:Invoke-AuditRound -Project $project -RunId 'run-audit-reset-1').invoked | Should -BeTrue
        $reset = New-ReviewCampaignBudgetResetFact -CampaignId $script:CampaignId -AuthorizedBy 'maintainer' -Reason 'one more fix' `
            -ObservedAt ([DateTimeOffset]::UtcNow.AddSeconds(1).ToString('o')) -TurnIdentity 'turn-allowance-reset'
        $null = Write-ReviewCampaignBudgetResetFact -StoreRoot $project.store -Fact $reset
        Start-Sleep -Milliseconds 1100
        [IO.File]::WriteAllText((Join-Path $project.root 'app.txt'), 'review me, fixed', $script:Utf8)
        script:Invoke-AuditGit $project.root @('commit', '-qam', 'fix')
        (script:Invoke-AuditRound -Project $project -RunId 'run-audit-reset-2').invoked | Should -BeTrue
        $second = @(Get-ReviewAuthorityCampaignFacts -StoreRoot $project.store -CampaignId $script:CampaignId -Kind reservations | Where-Object { [string]$_.run_id -ceq 'run-audit-reset-2' })[0]
        [string]$second.reset_id | Should -BeExactly ([string]$reset.reset_id)
        [string]$second.budget_grant_id | Should -BeExactly ([string]$budget.grant_id)
        [string]$second.turn_identity | Should -BeExactly 'turn-allowance-reset'
        $audit = script:Invoke-Audit -Project $project
        $audit.passed | Should -BeTrue -Because (script:Get-AuditReasons $audit)
    }

    It 'a landed stop answer: the allowed reviewer and the finding disposition name the answer''s turn' {
        $project = script:New-AuditProject -Name 'answers'
        $store = $project.store
        $partial = [pscustomobject][ordered]@{
            schema_version = '1.0'; campaign_id = $script:CampaignId; run_id = 'run-answer-partial'; target_digest = ('a' * 40); harness_id = 'fixture'
            completion = 'partial'; verdict = 'incomplete'; runtime_outcome = 'timed-out'; termination_verified = $true; containment = 'verified'
            currentness = 'current'; validation = 'valid'; can_approve_current = $false; summary = 'half'
            findings = @([pscustomobject][ordered]@{ finding_id = 'finding-0123456789abcdef'; source_local_id = 'l1'; lineage_id = 'lin-0123456789abcdef'; severity = 'major'; title = 'Empty store'; description = 'Failure scenario: an empty store throws.'; location = 'app.txt:1'; relevance = 'current'; resolution = 'open'; demoted = $false; demoted_from = '' })
            started_at = '2026-11-09T08:00:00Z'; ended_at = '2026-11-09T08:01:00Z'; duration_ms = 60000; examined_paths = @('app.txt'); review_collected = $false
        }
        Request-ReviewAuthorityClaim -StoreRoot $store -CampaignId $script:CampaignId -RunId 'run-answer-partial' -TargetLineage 'lin-001-demo' -ObservedAt '2026-11-09T08:00:00Z' | Out-Null
        Publish-ReviewRunResultFact -StoreRoot $store -CampaignId $script:CampaignId -RunId 'run-answer-partial' -Fact $partial | Out-Null
        $decision = Resolve-ReviewCampaignPauseDecision -Findings @() -RoundsUsed 1 -BudgetTotal 2
        $stop = New-ReviewCampaignPendingPauseFact -CampaignId $script:CampaignId -RunId 'run-answer-stop' -TargetDigest ('a' * 40) -Decision $decision `
            -ObservedAt ([DateTimeOffset]::UtcNow.ToString('o')) -StopKind 'b-dispute-or-defer' -StopReason 'dispute'
        $null = Write-ReviewCampaignPendingPauseFact -StoreRoot $store -Fact $stop
        $answers = @(
            [pscustomobject]@{ answer = 'allow-reviewer'; argument = 'copilot'; finding = ''; response_hash = ('e' * 64); turn_identity = 'turn-allow'; path = '' }
            [pscustomobject]@{ answer = 'defer'; argument = 'iteration 002'; finding = 'finding-0123456789abcdef'; response_hash = ('f' * 64); turn_identity = 'turn-defer'; path = '' }
        )
        $landing = Invoke-ReviewCampaignStopAnswerLanding -ProjectRoot $project.root -StoreRoot $store -CampaignId $script:CampaignId `
            -ReadAnswers { param($runId) $answers }.GetNewClosure() -CompleteAnswer { param($answer, $ref) $true }
        @($landing.landed).Count | Should -Be 2 -Because (@($landing.skipped | ForEach-Object { $_.reason }) -join ',')
        $campaignDir = Join-Path $store "campaigns/$script:CampaignId"
        $allowed = @(Get-ChildItem -LiteralPath (Join-Path $campaignDir 'allowed-reviewers') -Filter '*.json')[0]
        [string]((Get-Content -LiteralPath $allowed.FullName -Raw | ConvertFrom-Json).turn_identity) | Should -BeExactly 'turn-allow'
        $disposition = @(Get-ChildItem -LiteralPath (Join-Path $campaignDir 'finding-dispositions') -Filter '*.json')[0]
        [string]((Get-Content -LiteralPath $disposition.FullName -Raw | ConvertFrom-Json).turn_identity) | Should -BeExactly 'turn-defer'
        $answered = Join-Path $store ("campaigns/{0}/runs/run-answer-stop/pause-decision.json" -f $script:CampaignId)
        [string]((Get-Content -LiteralPath $answered -Raw | ConvertFrom-Json).turn_identity) | Should -BeExactly 'turn-defer'
    }

    It 'the typed "stop the review here" names its turn on the capture and on the pause decision it lands' {
        $project = script:New-AuditProject -Name 'halt'
        $capture = Write-SpecrewPauseDecisionAuthorization -ProjectRoot $project.root -Response 'stop the review here' -HostKind 'claude' `
            -SourceEvent 'UserPromptSubmit' -TurnIdentity 'turn-halt'
        $capture | Should -Not -BeNullOrEmpty
        [string]((Get-Content -LiteralPath (Join-Path $project.root '.specrew/review/pause-decision/stop-here.json') -Raw | ConvertFrom-Json).turn_identity) | Should -BeExactly 'turn-halt'
        $null = Invoke-ReviewCampaignHaltLanding -ProjectRoot $project.root -StoreRoot $project.store -CampaignId $script:CampaignId
        $decision = @(Get-ChildItem -LiteralPath (Join-Path $project.store "campaigns/$script:CampaignId/runs") -Recurse -Filter 'pause-decision.json')[0]
        [string]((Get-Content -LiteralPath $decision.FullName -Raw | ConvertFrom-Json).turn_identity) | Should -BeExactly 'turn-halt'
    }

    It 'the turn end registers an act it recovered from the transcript as a typed turn, so the audit joins it' {
        $project = script:New-AuditProject -Name 'turn-end'
        $transcript = Join-Path $project.root 'transcript.jsonl'
        $promptId = 'prompt-' + [guid]::NewGuid().ToString('N').Substring(0, 8)
        $text = 'approved for allowance reset'
        $entry = @{ type = 'user'; uuid = [guid]::NewGuid().ToString(); timestamp = [DateTimeOffset]::UtcNow.ToString('o'); sessionId = 's1'; promptId = $promptId
            origin = @{ kind = 'human' }; message = @{ role = 'user'; content = $text } }
        [IO.File]::WriteAllText($transcript, (($entry | ConvertTo-Json -Depth 8 -Compress) + "`n"), $script:Utf8)
        $cite = [string](Get-SpecrewTypedActIdentity -Turn ([pscustomobject]@{ host = 'claude'; message_id = $promptId; text = $text })).Identity
        $written = Write-SpecrewTypedAct -ProjectRoot $project.root -HostKind 'claude' -TurnIdentity $cite -TranscriptPath $transcript -SourceEvent 'stop-transcript' -SessionId 's1'
        [bool]$written.Written | Should -BeTrue -Because ([string]$written.Act.Reason)
        $recorded = [string]$written.Act.TurnIdentity
        $rows = @(Get-Content -LiteralPath (Join-Path $project.root '.specrew/authority/exhausted-turns.jsonl') | ForEach-Object { $_ | ConvertFrom-Json } | Where-Object { [string]$_.turn_id -ceq $recorded })
        $rows.Count | Should -BeGreaterThan 0
        @($rows | Where-Object { $_.PSObject.Properties['turn_origin'] -and [string]$_.turn_origin -ceq 'typed-user' }).Count | Should -Be $rows.Count
        $audit = script:Invoke-Audit -Project $project
        $audit.passed | Should -BeTrue -Because (script:Get-AuditReasons $audit)
    }
}
