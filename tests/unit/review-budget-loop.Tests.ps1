# Feature 203 T008 (FR-003, FR-004, FR-008, FR-010, FR-043; DRIFT-052 as ruled 2026-11-08): the review loop spends
# the campaign's one budget grant. No per-round approval exists: the grant (or, for a campaign whose before-implement
# verdict predates the snapshot, the FR-008 floor citing that verdict) is the only launch authority, a round is spent
# only when a complete review was collected, and no reviewer is invoked past the budget. Every case enters at the
# command a consumer runs (Invoke-ReviewCampaignCommand); the reviewer is a fixture, the target is a real Git repo.

BeforeAll {
    $script:RepoRoot = Split-Path -Parent (Split-Path -Parent $PSScriptRoot)
    . (Join-Path $script:RepoRoot 'scripts/internal/continuous-co-review/_load.ps1')
    . (Join-Path $script:RepoRoot 'scripts/internal/continuous-co-review/continuous-co-review-navigator.ps1')
    $script:CampaignId = Get-ReviewCampaignIdForIteration -FeatureId '001-demo' -IterationNumber '007'
    $script:Utf8 = [Text.UTF8Encoding]::new($false)

    function script:Invoke-LoopGit([string]$Root, [string[]]$Arguments) {
        $null = & git -C $Root -c user.name=t -c user.email=t@example.invalid @Arguments 2>&1
        if ($LASTEXITCODE -ne 0) { throw ('fixture-git-failed:' + ($Arguments -join ' ')) }
    }

    function script:New-LoopRepo([string]$Root) {
        New-Item -ItemType Directory -Path (Join-Path $Root 'specs/001-demo/iterations/007') -Force | Out-Null
        [IO.File]::WriteAllText((Join-Path $Root 'app.txt'), 'review me', $script:Utf8)
        [IO.File]::WriteAllText((Join-Path $Root 'specs/001-demo/spec.md'), '# Demo design context', $script:Utf8)
        [IO.File]::WriteAllText((Join-Path $Root '.gitignore'), ".specrew/review/`n", $script:Utf8)
        script:Invoke-LoopGit $Root @('init', '-q')
        script:Invoke-LoopGit $Root @('branch', '-m', 'main')
        script:Invoke-LoopGit $Root @('add', '-A')
        script:Invoke-LoopGit $Root @('commit', '-qm', 'initial')
        $config = Join-Path $Root 'authority.json'
        [IO.File]::WriteAllText($config, '{"schema_version":"1.0","mode":"campaign"}', $script:Utf8)
        return [pscustomobject]@{ root = $Root; config = $config; store = (Join-Path $Root '.specrew/review/authority'); external = ($Root + '-ext') }
    }

    # The crew's fix between rounds: the tree moves, so the previous round's pause no longer describes it.
    function script:Add-LoopFix([pscustomobject]$Repo, [int]$Number) {
        [IO.File]::WriteAllText((Join-Path $Repo.root 'app.txt'), "review me, fix $Number", $script:Utf8)
        script:Invoke-LoopGit $Repo.root @('add', 'app.txt')
        script:Invoke-LoopGit $Repo.root @('commit', '-qm', "fix $Number")
    }

    # The grant T007's before-implement snapshot writes, through its own writer.
    function script:Set-LoopBudgetGrant([pscustomobject]$Repo, [int]$Total) {
        $resolution = [pscustomobject]@{
            budget_total = $Total; host_order = @(); host_order_stated = $false; infra_failure_cap = 2
            budget_source = 'plan'; ceiling = 10; plan_path = 'specs/001-demo/plan.md'; plan_hash = ('a' * 64)
        }
        $fact = New-ReviewBudgetGrantFact -CampaignId $script:CampaignId -Resolution $resolution -VerdictEntry 'auth-loop-verdict' -ObservedAt '2026-11-08T08:00:00.0000000+00:00'
        $null = Add-ReviewCampaignBudgetGrantFact -StoreRoot $Repo.store -Fact $fact
        return $fact
    }

    # A lifecycle state whose ledger holds this feature's before-implement verdict for the active iteration.
    function script:Set-LoopVerdict([pscustomobject]$Repo, [string]$AuthorizationId = 'auth-0123456789abcdef', [string]$Iteration = '007', [switch]$NoVerdict) {
        $history = @(
            [ordered]@{ from_boundary = 'plan'; to_boundary = 'tasks'; verdict_text = 'approved for tasks'; feature_ref = '001-demo'; recorded_at = '2026-11-01T09:00:00Z'; authorization_id = 'auth-tasks-0001' }
        )
        if (-not $NoVerdict) {
            $history += [ordered]@{ from_boundary = 'tasks'; to_boundary = 'before-implement'; verdict_text = 'approved for before-implement'; feature_ref = '001-demo'; recorded_at = '2026-11-01T10:00:00Z'; authorization_id = $AuthorizationId }
        }
        $context = [ordered]@{
            session_state = [ordered]@{ active = $true; boundary_type = 'before-implement'; feature_ref = '001-demo'; iteration_number = $Iteration }
            boundary_enforcement = [ordered]@{ verdict_history = $history }
        }
        New-Item -ItemType Directory -Path (Join-Path $Repo.root '.specrew') -Force | Out-Null
        [IO.File]::WriteAllText((Join-Path $Repo.root '.specrew/start-context.json'), ($context | ConvertTo-Json -Depth 8), $script:Utf8)
    }

    function script:New-LoopPorts([pscustomobject]$Repo, [string]$Completion = 'complete', [string]$Outcome = 'completed', [int]$FindingCount = 1) {
        $findings = @(for ($i = 1; $i -le $FindingCount; $i++) {
                [pscustomobject][ordered]@{ local_id = "local-$i"; severity = 'major'; title = "Finding $i"; description = "When the store is empty, step $i throws instead of returning null."; location = 'app.txt:1' }
            })
        $verdict = if ($Completion -ceq 'partial') { 'incomplete' } elseif ($FindingCount -gt 0) { 'findings' } else { 'pass' }
        $candidate = [pscustomobject][ordered]@{ schema_version = '1.0'; run_id = 'x'; target_digest = 'x'; completion = $Completion; verdict = $verdict; summary = 'loop fixture'; findings = $findings }
        $prompt = Join-Path $Repo.root 'prompt.txt'
        if (-not (Test-Path -LiteralPath $prompt)) { [IO.File]::WriteAllText($prompt, 'review the target', $script:Utf8) }
        $harness = [pscustomobject]@{
            id = 'fixture-loop'
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
            target = New-GitReviewTargetPort -OriginRepo $Repo.root -ExternalRoot $Repo.external
            harness = $harness
            runtime = New-ReviewFixtureRuntimePort -Outcome $Outcome
            verification = New-ReviewFixtureVerificationPort
            clock = New-ReviewSystemClockPort
            prompt_path = $prompt
        }
    }

    function script:Invoke-LoopRound([pscustomobject]$Repo, [string]$RunId, [string]$Completion = 'complete', [string]$Outcome = 'completed', [int]$FindingCount = 1) {
        return Invoke-ReviewCampaignCommand -RepoRoot $Repo.root -FeatureId '001-demo' -IterationNumber '007' -RunId $RunId `
            -AuthorityConfigPath $Repo.config -Ports (script:New-LoopPorts -Repo $Repo -Completion $Completion -Outcome $Outcome -FindingCount $FindingCount)
    }

    function script:Get-LoopCounter([pscustomobject]$Repo) {
        return Get-ReviewCampaignRoundBudgetState -StoreRoot $Repo.store -CampaignId $script:CampaignId -RepoRoot $Repo.root
    }

    # The review command a consumer types, in its own process with stdin closed (B5F-034); text read back as words.
    function script:Invoke-LoopCli([pscustomobject]$Repo, [string[]]$Arguments) {
        $out = Join-Path $TestDrive ('cli-' + [guid]::NewGuid().ToString('N'))
        [IO.File]::WriteAllText("$out.in", '')
        $argumentList = @('-NoProfile', '-NonInteractive', '-File', (Join-Path $script:RepoRoot 'scripts/specrew-review.ps1'), '-ProjectPath', $Repo.root) + $Arguments
        $process = Start-Process -FilePath 'pwsh' -ArgumentList $argumentList -RedirectStandardInput "$out.in" `
            -RedirectStandardOutput "$out.out" -RedirectStandardError "$out.err" -NoNewWindow -PassThru -Wait
        $text = (Get-Content -LiteralPath "$out.out" -Raw -ErrorAction SilentlyContinue) + (Get-Content -LiteralPath "$out.err" -Raw -ErrorAction SilentlyContinue)
        $text = (($text -replace "`e\[[0-9;]*m", '') -replace '\s*\|\s+', ' ') -replace '\s+', ' '
        return [pscustomobject]@{ ExitCode = $process.ExitCode; Text = $text }
    }

    function script:Get-LoopSpendCount([pscustomobject]$Repo) {
        return @(Get-ReviewAuthorityCampaignFacts -StoreRoot $Repo.store -CampaignId $script:CampaignId -Kind spend).Count
    }
}

Describe 'the review loop spends the budget grant, and nothing else (FR-003, FR-004, FR-010)' {
    It 'takes no per-round approval: the command has no approval parameter and the CLI no --approve-round' {
        (Get-Command -Name Invoke-ReviewCampaignCommand).Parameters.Keys | Should -Not -Contain 'GrantAuthorizationRef'
        # --authorization-ref stays only to record a reviewer host's provider authorization (--host X --authorization-ref Y);
        # --ack-reason stays for the degraded-evidence acknowledgement. Neither launches a round (the CLI case below).
        (Get-Command -Name (Join-Path $script:RepoRoot 'scripts/specrew-review.ps1')).Parameters.Keys | Should -Not -Contain 'ApproveRound'
    }

    It 'through the review command: --approve-round is refused in plain words, and nothing is written' {
        $repo = script:New-LoopRepo -Root (Join-Path $TestDrive 'cli-approve')
        $result = script:Invoke-LoopCli -Repo $repo -Arguments @('--live', '--feature', '001-demo', '--iteration', '007', '--approve-round')
        $result.ExitCode | Should -Not -Be 0
        $result.Text | Should -BeLike '*--approve-round no longer exists*the review budget approved with the implementation pays for them*'
        Test-Path -LiteralPath $repo.store | Should -BeFalse
    }

    It 'through the review command: --authorization-ref without --host buys no round, and nothing is written' {
        $repo = script:New-LoopRepo -Root (Join-Path $TestDrive 'cli-ref')
        $result = script:Invoke-LoopCli -Repo $repo -Arguments @('--live', '--feature', '001-demo', '--iteration', '007', '--authorization-ref', 'external-approval-1', '--ack-reason', 'scripted')
        $result.ExitCode | Should -Be 1
        $result.Text | Should -BeLike '*--authorization-ref only records which reviewer host is authorized*'
        Test-Path -LiteralPath $repo.store | Should -BeFalse
    }

    It 'launches the first round on the budget grant alone, and records which grant the round spent' {
        $repo = script:New-LoopRepo -Root (Join-Path $TestDrive 'first')
        $budget = script:Set-LoopBudgetGrant -Repo $repo -Total 2
        $run = script:Invoke-LoopRound -Repo $repo -RunId 'run-loop-first-1'
        $run.invoked | Should -BeTrue -Because ([string]$run.reason)
        $grants = @(Get-ReviewAuthorityCampaignFacts -StoreRoot $repo.store -CampaignId $script:CampaignId -Kind grants)
        $grants.Count | Should -Be 1
        [int]$grants[0].slots | Should -Be 1
        [string]$grants[0].authorization_ref | Should -BeExactly ([string]$budget.grant_id)
        (script:Get-LoopCounter -Repo $repo).rounds_used | Should -Be 1
        (script:Get-LoopCounter -Repo $repo).budget_total | Should -Be 2
    }

    It 'the July shape: with a budget of 2, the third round is refused and no reviewer is invoked past the cap' {
        $repo = script:New-LoopRepo -Root (Join-Path $TestDrive 'july')
        $null = script:Set-LoopBudgetGrant -Repo $repo -Total 2
        (script:Invoke-LoopRound -Repo $repo -RunId 'run-loop-july-1').invoked | Should -BeTrue
        script:Add-LoopFix -Repo $repo -Number 1
        (script:Invoke-LoopRound -Repo $repo -RunId 'run-loop-july-2').invoked | Should -BeTrue
        script:Add-LoopFix -Repo $repo -Number 2
        $third = script:Invoke-LoopRound -Repo $repo -RunId 'run-loop-july-3'
        $third.invoked | Should -BeFalse
        [string]$third.reason | Should -Match 'review-round-budget-exhausted'
        script:Get-LoopSpendCount -Repo $repo | Should -Be 2
    }

    It 'after a reset, counts from the reset against one fix and one verification round (FR-007)' {
        $repo = script:New-LoopRepo -Root (Join-Path $TestDrive 'reset')
        $null = script:Set-LoopBudgetGrant -Repo $repo -Total 2
        (script:Invoke-LoopRound -Repo $repo -RunId 'run-loop-reset-1').invoked | Should -BeTrue
        script:Add-LoopFix -Repo $repo -Number 1
        (script:Invoke-LoopRound -Repo $repo -RunId 'run-loop-reset-2').invoked | Should -BeTrue
        $reset = [pscustomobject][ordered]@{
            schema_version = '1.0'; fact_type = 'round-budget-reset'; campaign_id = $script:CampaignId; reset_id = 'reset-loop-0001'
            authority_kind = 'human'; authorized_by = 'maintainer'; reason = ''; observed_at = [DateTimeOffset]::UtcNow.AddSeconds(1).ToString('o')
        }
        $null = Write-ReviewCampaignBudgetResetFact -StoreRoot $repo.store -Fact $reset
        Start-Sleep -Milliseconds 1100
        (script:Get-LoopCounter -Repo $repo).rounds_used | Should -Be 0
        (script:Get-LoopCounter -Repo $repo).budget_total | Should -Be 2
        script:Add-LoopFix -Repo $repo -Number 2
        (script:Invoke-LoopRound -Repo $repo -RunId 'run-loop-reset-3').invoked | Should -BeTrue
        script:Add-LoopFix -Repo $repo -Number 3
        (script:Invoke-LoopRound -Repo $repo -RunId 'run-loop-reset-4').invoked | Should -BeTrue
        script:Add-LoopFix -Repo $repo -Number 4
        (script:Invoke-LoopRound -Repo $repo -RunId 'run-loop-reset-5').invoked | Should -BeFalse
        script:Get-LoopSpendCount -Repo $repo | Should -Be 4
    }
}

Describe 'the typed per-round approval is retired: it records nothing and the human is told why (FR-010)' {
    BeforeAll {
        # The hook's own capture router, in its own process as the hooks run it, against a fixture project.
        $script:CaptureRunner = Join-Path $TestDrive 'capture-runner.ps1'
        $runner = @'
param([string]$RepoRoot, [string]$Root, [string]$Text, [string]$HostKind)
$ErrorActionPreference = 'Stop'
foreach ($dependency in @('HumanAuthorityStore', 'ConversationCaptureAccessor', 'ClassificationEngine', 'ProjectMetadataAccessor', 'HandoverStore')) {
    . (Join-Path $RepoRoot ('scripts/internal/bootstrap/' + $dependency + '.ps1'))
}
Invoke-SpecrewTypedAuthorityCapture -ProjectRoot $Root -Response $Text -HostKind $HostKind -SourceEvent 'UserPromptSubmit' `
    -MessageId ('msg-' + [guid]::NewGuid().ToString('N').Substring(0, 8)) -SessionId 's1' -TurnOrigin 'typed-user' | Out-Null
'DISCLOSURE:' + [string](Get-SpecrewAuthorityNotRecordedDisclosure -ProjectRoot $Root -HostKind $HostKind -SessionId 's1')
'@
        [IO.File]::WriteAllText($script:CaptureRunner, $runner, [Text.UTF8Encoding]::new($false))

        function script:Invoke-TypedCapture([string]$Text, [string]$HostKind) {
            $root = Join-Path $TestDrive ('typed-' + [guid]::NewGuid().ToString('N').Substring(0, 12))
            New-Item -ItemType Directory -Path (Join-Path $root '.specrew') -Force | Out-Null
            Set-Content -LiteralPath (Join-Path $root '.specrew/config.yml') -Value "specrew_version: `"0.40.0`"`nbootstrap_mode: `"fixture`"" -Encoding UTF8
            $null = & git init -q -b 001-fixture $root 2>&1
            $output = @(& pwsh -NoProfile -NonInteractive -File $script:CaptureRunner -RepoRoot $script:RepoRoot -Root $root -Text $Text -HostKind $HostKind 2>&1 | ForEach-Object { [string]$_ })
            $disclosure = (@($output | Where-Object { $_ -like 'DISCLOSURE:*' }) | Select-Object -Last 1)
            return [pscustomobject]@{
                Root = $root
                Disclosure = $(if ($disclosure) { $disclosure.Substring('DISCLOSURE:'.Length) } else { '' })
                RoundApprovalStore = (Join-Path $root '.specrew/review/round-approval/pending-round-approval.json')
            }
        }
    }

    It '<HostKind>: "<Text>" records no approval, and the next message says it changed nothing' -ForEach @(
        @{ HostKind = 'claude'; Text = 'approved for review round' }
        @{ HostKind = 'codex'; Text = 'approved for review round' }
        @{ HostKind = 'claude'; Text = 'withdraw the approval' }
    ) {
        $capture = script:Invoke-TypedCapture -Text $Text -HostKind $HostKind
        Test-Path -LiteralPath $capture.RoundApprovalStore | Should -BeFalse -Because 'there is no per-round approval to record'
        $capture.Disclosure | Should -BeLike '*changed nothing - review rounds no longer need an approval of their own*'
    }
}

Describe 'a campaign with no budget grant gets the FR-008 floor, citing its before-implement verdict (DRIFT-052 item 2)' {
    It 'records the floor grant: 2 rounds, the engine''s pick, the default cap, the verdict it cites, and why' {
        $repo = script:New-LoopRepo -Root (Join-Path $TestDrive 'floor')
        script:Set-LoopVerdict -Repo $repo -AuthorizationId 'auth-floor-verdict-0001'
        $run = script:Invoke-LoopRound -Repo $repo -RunId 'run-loop-floor-1'
        $run.invoked | Should -BeTrue -Because ([string]$run.reason)
        $grant = Get-ReviewCampaignBudgetGrant -StoreRoot $repo.store -CampaignId $script:CampaignId
        $grant | Should -Not -BeNullOrEmpty
        [int]$grant.budget_total | Should -Be 2
        [string]$grant.budget_source | Should -BeExactly 'floor-no-grant'
        [string]$grant.verdict_entry | Should -BeExactly 'auth-floor-verdict-0001'
        @($grant.host_order).Count | Should -Be 0
        [bool]$grant.host_order_stated | Should -BeFalse
        [int]$grant.infra_failure_cap | Should -Be 2
        [string]$grant.plan_path | Should -BeExactly '' -Because 'the floor never reads the plan'
        [string]$grant.floor_reason | Should -Match 'before-implement'
        Get-ReviewCampaignLatestBudgetReset -StoreRoot $repo.store -CampaignId $script:CampaignId | Should -BeNullOrEmpty -Because 'the floor is not a reset'
    }

    It 'the floor is spent like any budget: the third round is refused' {
        $repo = script:New-LoopRepo -Root (Join-Path $TestDrive 'floor-cap')
        script:Set-LoopVerdict -Repo $repo
        (script:Invoke-LoopRound -Repo $repo -RunId 'run-loop-floorcap-1').invoked | Should -BeTrue
        script:Add-LoopFix -Repo $repo -Number 1
        (script:Invoke-LoopRound -Repo $repo -RunId 'run-loop-floorcap-2').invoked | Should -BeTrue
        script:Add-LoopFix -Repo $repo -Number 2
        (script:Invoke-LoopRound -Repo $repo -RunId 'run-loop-floorcap-3').invoked | Should -BeFalse
    }

    It 'with no before-implement verdict recorded, refuses in plain words and writes nothing' {
        $repo = script:New-LoopRepo -Root (Join-Path $TestDrive 'no-verdict')
        script:Set-LoopVerdict -Repo $repo -NoVerdict
        $run = script:Invoke-LoopRound -Repo $repo -RunId 'run-loop-noverdict-1'
        $run.invoked | Should -BeFalse
        [string]$run.reason | Should -BeExactly 'review-budget-no-verdict'
        [string]$run.reason_detail | Should -Match 'before-implement'
        [string]$run.reason_detail | Should -Match 'Nothing was launched'
        Test-Path -LiteralPath $repo.store | Should -BeFalse -Because 'a refused launch touches no review state'
    }

    It 'a verdict for another iteration is not this campaign''s verdict' {
        $repo = script:New-LoopRepo -Root (Join-Path $TestDrive 'other-iteration')
        script:Set-LoopVerdict -Repo $repo -Iteration '008'
        $run = script:Invoke-LoopRound -Repo $repo -RunId 'run-loop-otheriter-1'
        $run.invoked | Should -BeFalse
        [string]$run.reason | Should -BeExactly 'review-budget-no-verdict'
    }
}

Describe 'a round is spent only when a complete review was collected (DRIFT-052 item 3)' {
    It 'a run with no complete review spends nothing, and the budget still buys two complete rounds' {
        $repo = script:New-LoopRepo -Root (Join-Path $TestDrive 'partial')
        $null = script:Set-LoopBudgetGrant -Repo $repo -Total 2
        $partial = script:Invoke-LoopRound -Repo $repo -RunId 'run-loop-partial-1' -Completion partial -Outcome timed-out
        $partial.invoked | Should -BeTrue
        (script:Get-LoopCounter -Repo $repo).rounds_used | Should -Be 0
        script:Add-LoopFix -Repo $repo -Number 1
        (script:Invoke-LoopRound -Repo $repo -RunId 'run-loop-partial-2').invoked | Should -BeTrue
        script:Add-LoopFix -Repo $repo -Number 2
        (script:Invoke-LoopRound -Repo $repo -RunId 'run-loop-partial-3').invoked | Should -BeTrue
        (script:Get-LoopCounter -Repo $repo).rounds_used | Should -Be 2
        script:Add-LoopFix -Repo $repo -Number 3
        (script:Invoke-LoopRound -Repo $repo -RunId 'run-loop-partial-4').invoked | Should -BeFalse
    }

    It 'a complete review is spent whatever the exit: a terminated run that delivered one counts' {
        $repo = script:New-LoopRepo -Root (Join-Path $TestDrive 'terminated')
        $null = script:Set-LoopBudgetGrant -Repo $repo -Total 2
        (script:Invoke-LoopRound -Repo $repo -RunId 'run-loop-term-1' -Outcome terminated).invoked | Should -BeTrue
        (script:Get-LoopCounter -Repo $repo).rounds_used | Should -Be 1
    }
}
