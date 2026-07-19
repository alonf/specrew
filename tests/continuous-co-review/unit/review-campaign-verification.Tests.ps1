$ErrorActionPreference = 'Stop'

# Trace: T064 / FR-048, FR-049 / SC-015, NFR-002, NFR-007.
Describe 'Frozen-target verification and exact-digest campaign injection (T064)' {
    BeforeAll {
        $script:RepoRoot = (Resolve-Path "$PSScriptRoot/../../..").Path
        . (Join-Path $script:RepoRoot 'scripts/internal/continuous-co-review/_load.ps1')
        . (Join-Path $script:RepoRoot 'scripts/internal/continuous-co-review/worktree-reviewer.ps1')

        function script:New-T064Repo {
            param([Parameter(Mandatory)][string]$Path)
            New-Item -ItemType Directory -Path $Path -Force | Out-Null
            & git -C $Path init -q 2>&1 | Out-Null
            & git -C $Path branch -m main 2>&1 | Out-Null
            [IO.File]::WriteAllText((Join-Path $Path 'app.txt'), 'v1')
            & git -C $Path -c user.name=t064-test -c user.email=t064@example.invalid add -A 2>&1 | Out-Null
            & git -C $Path -c user.name=t064-test -c user.email=t064@example.invalid commit -qm initial 2>&1 | Out-Null
            return $Path
        }

        function script:New-T064Plan {
            param([object[]]$Commands)
            return [pscustomobject]@{ schema_version = '1.0'; plan_id = 't064.fixture-plan.v1'; commands = @($Commands) }
        }

        function script:New-T064Command {
            param([string]$Id, [string]$Executable, [string[]]$Arguments)
            return [pscustomobject]@{
                command_id = $Id; executable = $Executable; arguments = @($Arguments); timeout_seconds = 30
                provenance = [pscustomobject]@{ kind = 'project-config'; source = '.specrew/verification-plan.json' }
                label = "T064 $Id"
            }
        }

        function script:Set-T064Plan {
            param([Parameter(Mandatory)][string]$Repo, [Parameter(Mandatory)]$Plan)
            $path = Join-Path $Repo '.specrew/verification-plan.json'
            [IO.Directory]::CreateDirectory((Split-Path -Parent $path)) | Out-Null
            [IO.File]::WriteAllText($path, ($Plan | ConvertTo-Json -Depth 20), [Text.UTF8Encoding]::new($false))
        }

        function script:New-T064Context {
            param([Parameter(Mandatory)][string]$Root)
            $store = Join-Path $Root 'store'; $staging = Join-Path $Root 'staging'; $targets = Join-Path $Root 'targets'
            New-Item -ItemType Directory -Path $Root -Force | Out-Null
            $prompt = Join-Path $Root 'prompt.md'; [IO.File]::WriteAllText($prompt, 'bounded T064 fixture prompt')
            $config = Join-Path $Root 'authority.json'; [IO.File]::WriteAllText($config, '{"schema_version":"1.0","mode":"campaign"}')
            $grant = [pscustomobject][ordered]@{
                schema_version = '1.0'; fact_type = 'grant'; campaign_id = 'cmp-t064'; grant_id = 'grant-t064'
                slots = 1; authority_kind = 'human'; authorization_ref = 'human-t064'; observed_at = '2026-07-18T00:00:00Z'
            }
            Add-ReviewCampaignGrantFact -StoreRoot $store -Fact $grant | Out-Null
            return [pscustomobject]@{ store = $store; staging = $staging; targets = $targets; prompt = $prompt; config = $config }
        }

        function script:New-T064CapturingHarness {
            param([Parameter(Mandatory)]$Capture)
            $preflight = {
                param($invocation)
                $Capture.preflight_count++
                $Capture.review_scope = [string]$invocation.review_scope
                $visibleSupport = @(
                    '.specify/support.txt', '.specify/generated-by-verification.txt', '.squad/team.yml',
                    '.specrew/iteration-config.yml', '.specrew/verification-plan.json' |
                        Where-Object { Test-Path -LiteralPath (Join-Path ([string]$invocation.snapshot_path) $_) }
                )
                $Capture | Add-Member -NotePropertyName verification_support_visible_at_preflight -NotePropertyValue @($visibleSupport) -Force
                $path = Join-Path ([string]$invocation.snapshot_path) '.review/implementer-evidence.json'
                if ([IO.File]::Exists($path)) { $Capture.evidence = [IO.File]::ReadAllText($path) | ConvertFrom-Json }
                return [pscustomobject]@{ ok = $true; reason = 'fixture-ready' }
            }.GetNewClosure()
            $invoke = {
                param($invocation, $environment)
                $Capture.invoke_count++
                $candidate = [pscustomobject][ordered]@{
                    schema_version = '1.0'; run_id = [string]$invocation.run_id; target_digest = [string]$invocation.target_digest
                    completion = 'complete'; verdict = 'pass'; summary = 'fixture pass'; findings = @()
                }
                [IO.File]::WriteAllText([string]$invocation.candidate_result_path, ($candidate | ConvertTo-Json -Depth 20 -Compress), [Text.UTF8Encoding]::new($false))
                return [pscustomobject]@{ exit_code = 0; output_activity = $true }
            }.GetNewClosure()
            return [pscustomobject]@{ id = 'fixture-t064'; contract_version = '1.0'; preflight = $preflight; invoke = $invoke }
        }

        function script:Invoke-T064Campaign {
            param([string]$Repo, $Context, $Harness)
            return Invoke-ReviewCampaignRun -StoreRoot $Context.store -StagingRoot $Context.staging -CampaignId cmp-t064 -RunId run-t064 `
                -ReservationId res-t064 -TargetLineage lin-t064 -TargetPort (New-GitReviewTargetPort -OriginRepo $Repo -ExternalRoot $Context.targets) `
                -HarnessPort $Harness -RuntimePort (New-ReviewFixtureRuntimePort) -VerificationPort (New-ReviewProductionVerificationPort) `
                -ClockPort (New-ReviewSystemClockPort) -PromptPath $Context.prompt -TimeoutSeconds 60 -AuthorityConfigPath $Context.config
        }
    }

    It 'executes a mixed frozen plan in order and injects every exact-digest command exactly once' {
        $root = Join-Path $TestDrive 'success'; $repo = New-T064Repo -Path (Join-Path $root 'origin')
        Set-T064Plan -Repo $repo -Plan (New-T064Plan -Commands @(
                (New-T064Command -Id 'first-git' -Executable 'git' -Arguments @('--version')),
                (New-T064Command -Id 'second-pwsh' -Executable 'pwsh' -Arguments @('-NoProfile', '-Command', 'exit 0'))
            ))
        $context = New-T064Context -Root (Join-Path $root 'controller')
        $capture = [pscustomobject]@{ preflight_count = 0; invoke_count = 0; review_scope = ''; evidence = $null }
        $headBefore = (& git -C $repo rev-parse HEAD).Trim(); $statusBefore = @(& git -C $repo status --porcelain=v1 --untracked-files=all)

        $result = Invoke-T064Campaign -Repo $repo -Context $context -Harness (New-T064CapturingHarness -Capture $capture)

        $result.status | Should -Be 'terminal' -Because $result.reason
        $result.result.can_approve_current | Should -BeTrue
        $capture.invoke_count | Should -Be 1
        ([regex]::Matches($capture.review_scope, 'CONTROLLER VERIFICATION EVIDENCE')).Count | Should -Be 1
        @($capture.evidence.runs | ForEach-Object { [string]$_.command_id }) | Should -Be @('first-git', 'second-pwsh')
        @($capture.evidence.runs | Where-Object { -not [bool]$_.command_succeeded }).Count | Should -Be 0
        @(Get-ReviewAuthorityCampaignFacts -StoreRoot $context.store -CampaignId cmp-t064 -Kind spend).Count | Should -Be 1
        (& git -C $repo rev-parse HEAD).Trim() | Should -Be $headBefore
        @(& git -C $repo status --porcelain=v1 --untracked-files=all) | Should -Be $statusBefore
    }

    It 'stages pinned tracked machinery for verification and removes it before harness preflight' {
        $root = Join-Path $TestDrive 'verification-support'; $repo = New-T064Repo -Path (Join-Path $root 'origin')
        foreach ($entry in @(
                @{ path = '.specify/support.txt'; content = 'pinned' },
                @{ path = '.squad/team.yml'; content = 'team: pinned' },
                @{ path = '.specrew/iteration-config.yml'; content = 'capacity_per_iteration: 26' }
            )) {
            $path = Join-Path $repo $entry.path
            [IO.Directory]::CreateDirectory((Split-Path -Parent $path)) | Out-Null
            [IO.File]::WriteAllText($path, [string]$entry.content)
        }
        & git -C $repo -c user.name=t064-test -c user.email=t064@example.invalid add -f .specify/support.txt .squad/team.yml .specrew/iteration-config.yml 2>&1 | Out-Null
        & git -C $repo -c user.name=t064-test -c user.email=t064@example.invalid commit -qm support 2>&1 | Out-Null
        [IO.File]::WriteAllText((Join-Path $repo '.specify/support.txt'), 'dirty-origin-must-not-be-staged')
        $probe = @'
$required = @('.specify/support.txt', '.squad/team.yml', '.specrew/iteration-config.yml')
if (@($required | Where-Object { -not (Test-Path -LiteralPath (Join-Path (Get-Location) $_)) }).Count -gt 0) { exit 8 }
if ([IO.File]::ReadAllText((Join-Path (Get-Location) '.specify/support.txt')) -cne 'pinned') { exit 9 }
[IO.File]::WriteAllText((Join-Path (Get-Location) '.specify/generated-by-verification.txt'), 'must-be-purged')
exit 0
'@
        Set-T064Plan -Repo $repo -Plan (New-T064Plan -Commands @(
                (New-T064Command -Id 'requires-pinned-support' -Executable 'pwsh' -Arguments @('-NoProfile', '-Command', $probe))
            ))
        $context = New-T064Context -Root (Join-Path $root 'controller')
        $capture = [pscustomobject]@{ preflight_count = 0; invoke_count = 0; review_scope = ''; evidence = $null }

        $result = Invoke-T064Campaign -Repo $repo -Context $context -Harness (New-T064CapturingHarness -Capture $capture)

        $result.status | Should -Be 'terminal' -Because $result.reason
        $capture.invoke_count | Should -Be 1
        @($capture.verification_support_visible_at_preflight).Count | Should -Be 0 -Because 'methodology support is controller-only and never reviewer-visible'
        $capture.review_scope | Should -Match 'Tracked methodology support used by verification came only from pinned commit'
        @($capture.evidence.runs | Where-Object { -not [bool]$_.command_succeeded }).Count | Should -Be 0
        [IO.File]::ReadAllText((Join-Path $repo '.specify/support.txt')) | Should -Be 'dirty-origin-must-not-be-staged'
    }

    It 'removes staged machinery after a red verification command before returning' {
        $root = Join-Path $TestDrive 'verification-support-failure'; $repo = New-T064Repo -Path (Join-Path $root 'origin')
        $support = Join-Path $repo '.specify/support.txt'; [IO.Directory]::CreateDirectory((Split-Path -Parent $support)) | Out-Null
        [IO.File]::WriteAllText($support, 'pinned')
        & git -C $repo -c user.name=t064-test -c user.email=t064@example.invalid add -f .specify/support.txt 2>&1 | Out-Null
        & git -C $repo -c user.name=t064-test -c user.email=t064@example.invalid commit -qm support 2>&1 | Out-Null
        $probe = "if (-not (Test-Path -LiteralPath '.specify/support.txt')) { exit 8 }; [IO.File]::WriteAllText('.specify/generated-by-verification.txt', 'must-be-purged'); exit 7"
        Set-T064Plan -Repo $repo -Plan (New-T064Plan -Commands @(
                (New-T064Command -Id 'red-with-support' -Executable 'pwsh' -Arguments @('-NoProfile', '-Command', $probe))
            ))
        $snapshot = New-GitReviewTargetSnapshot -OriginRepo $repo -RunId run-support-cleanup -ExternalRoot (Join-Path $root 'targets')
        try {
            $result = Invoke-ReviewCampaignFrozenVerification -Snapshot $snapshot
            $result.ok | Should -BeFalse
            $result.reason | Should -Be 'verification-command-failed:red-with-support:diagnostics-require-command-scoped-disclosure'
            Test-Path -LiteralPath (Join-Path $snapshot.snapshot_path '.specify/support.txt') | Should -BeFalse
            Test-Path -LiteralPath (Join-Path $snapshot.snapshot_path '.specify/generated-by-verification.txt') | Should -BeFalse
            Test-Path -LiteralPath (Join-Path $snapshot.snapshot_path '.specrew/verification-plan.json') | Should -BeFalse
            $after = Get-ContinuousCoReviewReviewedStateDigest -RepoRoot $snapshot.snapshot_path
            $treeDelta = @(& git -C $snapshot.snapshot_path diff --name-status $snapshot.target_digest $after.tree_id 2>&1)
            $after.tree_id | Should -Be $snapshot.target_digest -Because ($treeDelta -join '; ')
        }
        finally { Remove-GitReviewTargetSnapshot -Snapshot $snapshot | Out-Null }
    }

    It 'stops a <case> selected plan before provider spend' -ForEach @(
        @{ case = 'missing'; content = $null; reason = 'verification-not-configured*' },
        @{ case = 'invalid'; content = '{}'; reason = 'verification-not-configured:*schema-invalid*' }
    ) {
        $root = Join-Path $TestDrive "plan-$case"; $repo = New-T064Repo -Path (Join-Path $root 'origin')
        if ($null -ne $content) {
            $path = Join-Path $repo '.specrew/verification-plan.json'; [IO.Directory]::CreateDirectory((Split-Path -Parent $path)) | Out-Null
            [IO.File]::WriteAllText($path, $content, [Text.UTF8Encoding]::new($false))
        }
        $context = New-T064Context -Root (Join-Path $root 'controller')
        $capture = [pscustomobject]@{ preflight_count = 0; invoke_count = 0; review_scope = ''; evidence = $null }

        $result = Invoke-T064Campaign -Repo $repo -Context $context -Harness (New-T064CapturingHarness -Capture $capture)

        $result.status | Should -Be 'failed'
        $result.reason | Should -BeLike $reason
        $result.invoked | Should -BeFalse
        $capture.preflight_count | Should -Be 0 -Because 'verification stops before provider harness preflight'
        $capture.invoke_count | Should -Be 0
        @(Get-ReviewAuthorityCampaignFacts -StoreRoot $context.store -CampaignId cmp-t064 -Kind spend).Count | Should -Be 0
    }

    It 'stops a configured command failure before harness preflight or provider spend' {
        $root = Join-Path $TestDrive 'configured-failure'; $repo = New-T064Repo -Path (Join-Path $root 'origin')
        Set-T064Plan -Repo $repo -Plan (New-T064Plan -Commands @(
                (New-T064Command -Id 'failing-check' -Executable 'pwsh' -Arguments @('-NoProfile', '-Command', 'exit 7'))
            ))
        $context = New-T064Context -Root (Join-Path $root 'controller')
        $capture = [pscustomobject]@{ preflight_count = 0; invoke_count = 0; review_scope = ''; evidence = $null }

        $result = Invoke-T064Campaign -Repo $repo -Context $context -Harness (New-T064CapturingHarness -Capture $capture)

        $result.status | Should -Be 'failed'
        $result.reason | Should -Be 'verification-command-failed:failing-check:diagnostics-require-command-scoped-disclosure'
        $result.invoked | Should -BeFalse
        $capture.preflight_count | Should -Be 0 -Because 'a red controller verification never reaches the paid harness'
        $capture.invoke_count | Should -Be 0
        $capture.evidence | Should -BeNullOrEmpty
        $result.result.completion | Should -Be 'none' -Because 'no reviewer candidate exists before provider invocation'
        $result.result.verdict | Should -Be 'failed' -Because 'controller preflight failure has no reviewer verdict'
        $result.result.can_approve_current | Should -BeFalse
        $result.result.failure_reason | Should -Be $result.reason
        @(Get-ReviewAuthorityCampaignFacts -StoreRoot $context.store -CampaignId cmp-t064 -Kind spend).Count | Should -Be 0
        @(Get-ReviewAuthorityCampaignFacts -StoreRoot $context.store -CampaignId cmp-t064 -Kind releases).Count | Should -Be 1
    }

    It 'refuses a verification command that mutates the frozen source before provider spend' {
        $root = Join-Path $TestDrive 'mutation'; $repo = New-T064Repo -Path (Join-Path $root 'origin')
        $mutation = '$p = Join-Path (Get-Location) ''app.txt''; [IO.File]::WriteAllText($p, ''mutated'')'
        Set-T064Plan -Repo $repo -Plan (New-T064Plan -Commands @(
                (New-T064Command -Id 'mutator' -Executable 'pwsh' -Arguments @('-NoProfile', '-Command', $mutation))
            ))
        $context = New-T064Context -Root (Join-Path $root 'controller')
        $capture = [pscustomobject]@{ preflight_count = 0; invoke_count = 0; review_scope = ''; evidence = $null }

        $result = Invoke-T064Campaign -Repo $repo -Context $context -Harness (New-T064CapturingHarness -Capture $capture)

        $result.reason | Should -Be 'verification-mutated-frozen-target'
        $result.invoked | Should -BeFalse
        $capture.invoke_count | Should -Be 0
        @(Get-ReviewAuthorityCampaignFacts -StoreRoot $context.store -CampaignId cmp-t064 -Kind spend).Count | Should -Be 0
        [IO.File]::ReadAllText((Join-Path $repo 'app.txt')) | Should -Be 'v1'
    }

    It 'binds target currentness to the frozen verification-plan bytes as well as the code digest' {
        $root = Join-Path $TestDrive 'plan-currentness'; $repo = New-T064Repo -Path (Join-Path $root 'origin')
        $plan = New-T064Plan -Commands @((New-T064Command -Id 'one' -Executable 'git' -Arguments @('--version')))
        Set-T064Plan -Repo $repo -Plan $plan
        $snapshot = New-GitReviewTargetSnapshot -OriginRepo $repo -RunId run-plan-currentness -ExternalRoot (Join-Path $root 'targets')
        try {
            [IO.File]::Exists((Join-Path $snapshot.snapshot_path '.specrew/verification-plan.json')) | Should -BeTrue
            $initial = Test-GitReviewTargetCurrentness -Snapshot $snapshot
            $initial.exact | Should -BeTrue
            $plan.plan_id = 't064.changed-plan.v1'; Set-T064Plan -Repo $repo -Plan $plan
            $moved = Test-GitReviewTargetCurrentness -Snapshot $snapshot
            $moved.exact | Should -BeFalse
            $moved.reason | Should -Be 'verification-plan-changed'
        }
        finally { Remove-GitReviewTargetSnapshot -Snapshot $snapshot | Out-Null }
    }

    It 'rejects stale or unjoinable runner evidence before injection' {
        $snapshot = Join-Path $TestDrive 'join-refusal'; New-Item -ItemType Directory -Path $snapshot -Force | Out-Null
        $plan = New-T064Plan -Commands @((New-T064Command -Id 'declared' -Executable 'git' -Arguments @('--version')))
        Mock Get-ContinuousCoReviewSelectedVerificationPlan { [pscustomobject]@{ available = $true; plan = $plan; reason = $null } }
        Mock Get-ContinuousCoReviewReviewedStateDigest { [pscustomobject]@{ ok = $true; tree_id = ('a' * 40) } }
        Mock Invoke-ContinuousCoReviewVerificationPlan {
            [pscustomobject]@{
                state = 'configured'; command_count = 1; all_succeeded = $true
                evidence = @([pscustomobject]@{ command_id = 'foreign'; reviewed_digest_tree_id = ('b' * 40); command_succeeded = $true })
            }
        }
        Mock Copy-ContinuousCoReviewImplementerEvidence { throw 'must-not-copy' }
        $result = Invoke-ReviewCampaignFrozenVerification -Snapshot ([pscustomobject]@{ snapshot_path = $snapshot; target_digest = ('a' * 40) })
        $result.ok | Should -BeFalse
        $result.reason | Should -Be 'verification-evidence-not-exactly-joinable'
        Assert-MockCalled Copy-ContinuousCoReviewImplementerEvidence -Times 0
    }
}
