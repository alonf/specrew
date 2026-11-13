# Feature 203 T008 step (iii) (FR-005, FR-006, FR-009, FR-011, FR-013, FR-043; DRIFT-052 items 3 and 5 as ruled
# 2026-11-08, and the 2026-11-09 ruling on stop (c)): the loop runs without a human until one of four stops, and each
# stop is a pause fact. A clean round ends the review; a fix-needed round within the budget writes no pause, and the next
# round is refused, spending nothing, until the files have moved. Pause facts are written only for (a) the budget spent
# with findings open, (b) a dispute or deferral, (c) a judgment call, including a reviewer that changed the frozen copy,
# and (d) a next reviewer outside the approved order. A run that collected no complete review is free, counts toward
# infra_failure_cap (an identity mismatch included), and its findings stay open until a fix or a typed line closes them.
# Every case enters at the command a consumer runs (Invoke-ReviewCampaignCommand); the reviewer is a fixture, the target
# a real Git repo.

BeforeAll {
    $script:RepoRoot = Split-Path -Parent (Split-Path -Parent $PSScriptRoot)
    . (Join-Path $script:RepoRoot 'scripts/internal/continuous-co-review/_load.ps1')
    . (Join-Path $script:RepoRoot 'scripts/internal/continuous-co-review/continuous-co-review-navigator.ps1')
    . (Join-Path $script:RepoRoot 'scripts/internal/continuous-co-review/signoff-gate-wiring.ps1')
    # Round A finding 1: a grant is spent only when its cited verdict was typed; the fixture records that verdict.
    foreach ($dependency in @('ConversationCaptureAccessor', 'HumanAuthorityStore')) { . (Join-Path $script:RepoRoot ('scripts/internal/bootstrap/' + $dependency + '.ps1')) }
    . (Join-Path $script:RepoRoot 'tests/support/cited-typed-turn.ps1')
    $script:CampaignId = Get-ReviewCampaignIdForIteration -FeatureId '001-demo' -IterationNumber '007'
    $script:Utf8 = [Text.UTF8Encoding]::new($false)
    $script:Releasing = @('boundary-clean', 'review-current', 'boundary-finalized', 'boundary-human-disposition')

    function script:Invoke-StopGit([string]$Root, [string[]]$Arguments) {
        $null = & git -C $Root -c user.name=t -c user.email=t@example.invalid @Arguments 2>&1
        if ($LASTEXITCODE -ne 0) { throw ('fixture-git-failed:' + ($Arguments -join ' ')) }
    }

    function script:New-StopRepo([string]$Root) {
        New-Item -ItemType Directory -Path (Join-Path $Root 'specs/001-demo/iterations/007') -Force | Out-Null
        New-Item -ItemType Directory -Path (Join-Path $Root 'src') -Force | Out-Null
        [IO.File]::WriteAllText((Join-Path $Root 'src/app.ps1'), "function Get-Answer { 42 }`n", $script:Utf8)
        [IO.File]::WriteAllText((Join-Path $Root 'specs/001-demo/spec.md'), '# Demo design context', $script:Utf8)
        [IO.File]::WriteAllText((Join-Path $Root '.gitignore'), ".specrew/review/`n", $script:Utf8)
        script:Invoke-StopGit $Root @('init', '-q')
        script:Invoke-StopGit $Root @('branch', '-m', 'main')
        script:Invoke-StopGit $Root @('add', '-A')
        script:Invoke-StopGit $Root @('commit', '-qm', 'initial')
        $config = Join-Path $Root 'authority.json'
        [IO.File]::WriteAllText($config, '{"schema_version":"1.0","mode":"campaign"}', $script:Utf8)
        return [pscustomobject]@{ root = $Root; config = $config; store = (Join-Path $Root '.specrew/review/authority'); external = ($Root + '-ext') }
    }

    # The crew's fix between rounds: the tree moves.
    function script:Add-StopFix([pscustomobject]$Repo, [int]$Number) {
        [IO.File]::WriteAllText((Join-Path $Repo.root 'src/app.ps1'), "function Get-Answer { 42 + $Number - $Number }`n", $script:Utf8)
        script:Invoke-StopGit $Repo.root @('add', '-A')
        script:Invoke-StopGit $Repo.root @('commit', '-qm', "fix $Number")
    }

    function script:Set-StopBudgetGrant([pscustomobject]$Repo, [int]$Total, [string[]]$HostOrder = @()) {
        $resolution = [pscustomobject]@{
            budget_total = $Total; host_order = @($HostOrder); host_order_stated = (@($HostOrder).Count -gt 0); infra_failure_cap = 2
            budget_source = 'plan'; ceiling = 10; plan_path = 'specs/001-demo/plan.md'; plan_hash = ('a' * 64)
        }
        $fact = New-ReviewBudgetGrantFact -CampaignId $script:CampaignId -Resolution $resolution -VerdictEntry 'auth-stop-verdict' -ObservedAt '2026-11-08T08:00:00.0000000+00:00'
        $null = Add-ReviewCampaignBudgetGrantFact -StoreRoot $Repo.store -Fact $fact
        $null = Add-SpecrewTestLedgerVerdict -ProjectRoot $Repo.root -AuthorizationId 'auth-stop-verdict'
    }

    # Three reviewers set up and authorized; the code's writer is claude, so the engine's own pick is codex, then copilot.
    function script:Set-StopReviewers([pscustomobject]$Repo) {
        $rows = foreach ($h in @(@{ host = 'codex'; rank = 90 }, @{ host = 'claude'; rank = 85 }, @{ host = 'copilot'; rank = 80 })) {
            [ordered]@{ host = $h.host; model = 'fixture'; adapter_id = ('reviewer-host-adapter-' + $h.host); allowed = $true; installed = $true
                review_class_rank = $h.rank; model_source = 'fixture'; cost_class = 'non-default'; authorization_ref = ('fixture-authorized-' + $h.host)
                fallback_allowed = $false; timeout_seconds = 0 }
        }
        New-Item -ItemType Directory -Path (Join-Path $Repo.root '.specrew') -Force | Out-Null
        [IO.File]::WriteAllText((Join-Path $Repo.root '.specrew/reviewer-hosts.json'), (([ordered]@{ schema_version = '1.0'; hosts = @($rows) }) | ConvertTo-Json -Depth 8), $script:Utf8)
    }

    # What the reviewer brings back. Kind: 'findings' (a complete review with one major finding), 'clean' (a complete review
    # with none, answering no open finding), 'resolved' / 'still-open' (a clean complete review that answers every open
    # finding it was given with that status), 'reworded' (a complete review reporting the same defect reworded, on a
    # shifted line, answering nothing), 'partial' (a timed-out run with half a review and one finding), 'mismatch' (a
    # complete review answering another run: an identity mismatch), 'violated' (a complete clean review from a reviewer
    # that changed the frozen copy). Every invocation's review scope is kept in $script:StopScopes.
    $script:StopScopes = [System.Collections.Generic.List[string]]::new()
    function script:New-StopPorts([pscustomobject]$Repo, [string]$Kind, [string]$HostName = '') {
        $findingCount = if ($Kind -cin @('clean', 'violated', 'resolved', 'still-open')) { 0 } else { 1 }
        $title = if ($Kind -ceq 'reworded') { 'Store lookup throws when empty' } else { 'Empty store {0}' }
        $line = if ($Kind -ceq 'reworded') { 'src/app.ps1:3' } else { 'src/app.ps1:1' }
        $findings = @(for ($i = 1; $i -le $findingCount; $i++) {
                [pscustomobject][ordered]@{ local_id = "local-$i"; severity = 'major'; title = ($title -f $i); description = "Get-Answer reads the store. Failure scenario: when the store is empty, step $i throws instead of returning null."; location = $line }
            })
        $answer = if ($Kind -cin @('resolved', 'still-open')) { $Kind } else { '' }
        $scopes = $script:StopScopes
        $completion = if ($Kind -ceq 'partial') { 'partial' } else { 'complete' }
        $verdict = if ($Kind -ceq 'partial') { 'incomplete' } elseif ($findingCount -gt 0) { 'findings' } else { 'pass' }
        $candidate = [pscustomobject][ordered]@{ schema_version = '1.0'; run_id = 'x'; target_digest = 'x'; completion = $completion; verdict = $verdict; summary = 'stop fixture'; findings = $findings; examined_paths = @('src/app.ps1') }
        $mismatch = ($Kind -ceq 'mismatch')
        $prompt = Join-Path $Repo.root 'prompt.txt'
        if (-not (Test-Path -LiteralPath $prompt)) { [IO.File]::WriteAllText($prompt, 'review the target', $script:Utf8) }
        $harness = [pscustomobject]@{
            id = $(if ($HostName) { 'fixture-' + $HostName } else { 'fixture-stop' })
            preflight = { param($invocation) [pscustomobject]@{ ok = $true; reason = 'fixture-ready' } }
            invoke = {
                param($invocation, $environment)
                $payload = $candidate | Select-Object *
                $payload.target_digest = [string]$invocation.target_digest
                $payload.run_id = $(if ($mismatch) { 'run-someone-else' } else { [string]$invocation.run_id })
                $scopes.Add([string]$invocation.review_scope) | Out-Null
                if ($answer) {
                    $given = @([regex]::Matches([string]$invocation.review_scope, 'finding-[0-9a-f]{16}') | ForEach-Object { $_.Value } | Select-Object -Unique)
                    $payload | Add-Member -NotePropertyName finding_resolutions -NotePropertyValue @($given | ForEach-Object { [pscustomobject][ordered]@{ finding_id = $_; status = $answer } })
                }
                [IO.File]::WriteAllText([string]$invocation.candidate_result_path, ($payload | ConvertTo-Json -Depth 20 -Compress), [Text.UTF8Encoding]::new($false))
                [pscustomobject]@{ exit_code = 0; output_activity = $true }
            }.GetNewClosure()
        }
        if ($HostName) { $harness | Add-Member -NotePropertyName host -NotePropertyValue $HostName -Force }
        $runtime = switch ($Kind) {
            'partial' { New-ReviewFixtureRuntimePort -Outcome timed-out }
            'violated' { New-ReviewFixtureRuntimePort -Outcome completed -Containment violated }
            default { New-ReviewFixtureRuntimePort -Outcome completed }
        }
        return [pscustomobject]@{
            target = New-GitReviewTargetPort -OriginRepo $Repo.root -ExternalRoot $Repo.external
            harness = $harness; runtime = $runtime; verification = New-ReviewFixtureVerificationPort
            clock = New-ReviewSystemClockPort; prompt_path = $prompt
        }
    }

    function script:Invoke-StopRound([pscustomobject]$Repo, [string]$RunId, [string]$Kind = 'findings') {
        return Invoke-ReviewCampaignCommand -RepoRoot $Repo.root -FeatureId '001-demo' -IterationNumber '007' -RunId $RunId `
            -AuthorityConfigPath $Repo.config -Ports (script:New-StopPorts -Repo $Repo -Kind $Kind)
    }

    # Ports for whichever reviewer the engine chose; $Behaviour maps a reviewer to the kind it brings back.
    function script:New-StopPortsFactory([pscustomobject]$Repo, [hashtable]$Behaviour, [System.Collections.Generic.List[string]]$Invoked) {
        $repoForPorts = $Repo
        $makePorts = ${function:script:New-StopPorts}
        return {
            param([string]$HostName)
            $Invoked.Add($HostName) | Out-Null
            $kind = if ($Behaviour.ContainsKey($HostName)) { [string]$Behaviour[$HostName] } else { 'findings' }
            return (& $makePorts -Repo $repoForPorts -Kind $kind -HostName $HostName)
        }.GetNewClosure()
    }

    function script:Invoke-StopHostRound([pscustomobject]$Repo, [string]$RunId, [scriptblock]$Factory) {
        return Invoke-ReviewCampaignCommand -RepoRoot $Repo.root -FeatureId '001-demo' -IterationNumber '007' -RunId $RunId `
            -AuthorityConfigPath $Repo.config -CodeWriterHost 'claude' -PortsFactory $Factory
    }

    function script:Get-StopCounter([pscustomobject]$Repo) {
        return Get-ReviewCampaignRoundBudgetState -StoreRoot $Repo.store -CampaignId $script:CampaignId -RepoRoot $Repo.root
    }

    function script:Get-StopPauseFacts([pscustomobject]$Repo) {
        return @(Get-ReviewCampaignPauseRecords -StoreRoot $Repo.store -CampaignId $script:CampaignId | ForEach-Object { $_.pause })
    }

    function script:Get-StopReservationCount([pscustomobject]$Repo) {
        return @(Get-ReviewAuthorityCampaignFacts -StoreRoot $Repo.store -CampaignId $script:CampaignId -Kind reservations).Count
    }

    function script:Get-StopSignoff([pscustomobject]$Repo) {
        return Get-ReviewCampaignVerdictPacketDecision -RepoRoot $Repo.root -FeatureId '001-demo' -IterationNumber '007'
    }
}

Describe 'the loop runs without a human between rounds (FR-005, FR-006; DRIFT-052 item 5)' {
    It 'a fix-needed round within the budget writes no pause' {
        $repo = script:New-StopRepo -Root (Join-Path $TestDrive 'fix-needed')
        script:Set-StopBudgetGrant -Repo $repo -Total 3
        $round = script:Invoke-StopRound -Repo $repo -RunId 'run-stop-fix-1' -Kind findings
        $round.invoked | Should -BeTrue -Because ([string]$round.reason)
        @(script:Get-StopPauseFacts -Repo $repo).Count | Should -Be 0 -Because 'no stop asks for a round (FR-006)'
        Get-ReviewCampaignOpenStop -StoreRoot $repo.store -CampaignId $script:CampaignId | Should -BeNullOrEmpty
    }

    It 'the next round is refused, spending nothing, until the files have moved; after the fix it runs' {
        $repo = script:New-StopRepo -Root (Join-Path $TestDrive 'unchanged')
        script:Set-StopBudgetGrant -Repo $repo -Total 3
        $null = script:Invoke-StopRound -Repo $repo -RunId 'run-stop-same-1' -Kind findings
        $reservations = script:Get-StopReservationCount -Repo $repo
        $same = script:Invoke-StopRound -Repo $repo -RunId 'run-stop-same-2' -Kind findings
        $same.invoked | Should -BeFalse
        [string]$same.reason | Should -BeExactly 'review-tree-unchanged'
        [string]$same.status | Should -Not -Be 'paused' -Because 'an unchanged tree is the crew''s to fix, not a stop for the human'
        script:Get-StopReservationCount -Repo $repo | Should -Be $reservations -Because 'a refused launch reserves and spends nothing'
        (script:Get-StopCounter -Repo $repo).rounds_used | Should -Be 1
        script:Add-StopFix -Repo $repo -Number 1
        (script:Invoke-StopRound -Repo $repo -RunId 'run-stop-same-3' -Kind findings).invoked | Should -BeTrue
    }

    It 'a clean round ends the review with no stop: no pause, and no further round on the same files' {
        $repo = script:New-StopRepo -Root (Join-Path $TestDrive 'clean')
        script:Set-StopBudgetGrant -Repo $repo -Total 3
        $null = script:Invoke-StopRound -Repo $repo -RunId 'run-stop-clean-1' -Kind clean
        @(script:Get-StopPauseFacts -Repo $repo).Count | Should -Be 0
        $again = script:Invoke-StopRound -Repo $repo -RunId 'run-stop-clean-2' -Kind clean
        $again.invoked | Should -BeFalse
        [string]$again.reason | Should -BeExactly 'review-tree-unchanged'
        [string]$again.reason_detail | Should -Match 'ended clean'
        @($script:Releasing) | Should -Contain ([string](script:Get-StopSignoff -Repo $repo).route)
    }
}

Describe 'stop (a): the budget spent with findings open is a pause fact in the FR-011 layout (FR-006(a), FR-011)' {
    It 'writes stop a on the round that spends the last of the budget with a finding open, and refuses the next launch' {
        $repo = script:New-StopRepo -Root (Join-Path $TestDrive 'stop-a')
        script:Set-StopBudgetGrant -Repo $repo -Total 2
        $null = script:Invoke-StopRound -Repo $repo -RunId 'run-stop-a-1' -Kind findings
        script:Add-StopFix -Repo $repo -Number 1
        $null = script:Invoke-StopRound -Repo $repo -RunId 'run-stop-a-2' -Kind findings
        $open = Get-ReviewCampaignOpenStop -StoreRoot $repo.store -CampaignId $script:CampaignId
        $open | Should -Not -BeNullOrEmpty
        [string]$open.stop_kind | Should -BeExactly 'a-budget-spent'
        [string]$open.run_id | Should -BeExactly 'run-stop-a-2'
        script:Add-StopFix -Repo $repo -Number 2
        $next = script:Invoke-StopRound -Repo $repo -RunId 'run-stop-a-3' -Kind findings
        $next.invoked | Should -BeFalse
        [string]$next.status | Should -BeExactly 'paused'
        [string]$next.reason | Should -BeExactly 'review-stop-open:a-budget-spent'
        $surface = (@($next.pause_surface) -join "`n")
        # FR-011: why; what happened, counted; the one decision; sendable lines each stating its consequence.
        $surface | Should -Match 'Why'
        $surface | Should -Match '2 of 2 rounds'
        $surface | Should -Match 'approved for allowance reset'
        $surface | Should -Match 'stop the review here'
        $surface | Should -Match 'defer finding \S+ to'
        $surface | Should -Match 'drop finding \S+'
        $surface | Should -Not -Match 'run another round' -Because 'no stop asks for a round (FR-006)'
    }

    It 'the budget spent on a clean round that resolves the open finding ends the review with no stop' {
        $repo = script:New-StopRepo -Root (Join-Path $TestDrive 'stop-a-clean')
        script:Set-StopBudgetGrant -Repo $repo -Total 2
        $null = script:Invoke-StopRound -Repo $repo -RunId 'run-stop-ac-1' -Kind findings
        script:Add-StopFix -Repo $repo -Number 1
        $null = script:Invoke-StopRound -Repo $repo -RunId 'run-stop-ac-2' -Kind resolved
        (script:Get-StopCounter -Repo $repo).rounds_used | Should -Be 2 -Because 'the answering round collected a complete review'
        Get-ReviewCampaignOpenStop -StoreRoot $repo.store -CampaignId $script:CampaignId | Should -BeNullOrEmpty
        @(script:Get-StopPauseFacts -Repo $repo).Count | Should -Be 0
    }
}

Describe 'stop (c): a reviewer that changed the frozen copy (the 2026-11-09 ruling on DRIFT-052 item 5)' {
    It 'a containment-violated complete review spends its round and stops at (c)' {
        $repo = script:New-StopRepo -Root (Join-Path $TestDrive 'stop-c')
        script:Set-StopBudgetGrant -Repo $repo -Total 3
        $round = script:Invoke-StopRound -Repo $repo -RunId 'run-stop-c-1' -Kind violated
        $round.invoked | Should -BeTrue -Because ([string]$round.reason)
        (script:Get-StopCounter -Repo $repo).rounds_used | Should -Be 1 -Because 'a complete review was collected'
        $open = Get-ReviewCampaignOpenStop -StoreRoot $repo.store -CampaignId $script:CampaignId
        [string]$open.stop_kind | Should -BeExactly 'c-judgment'
        [string]$open.stop_reason | Should -BeExactly 'containment-violated'
    }

    It 'never counts as clean: it does not end the review, and the sign-off check does not release it' {
        $repo = script:New-StopRepo -Root (Join-Path $TestDrive 'stop-c-clean')
        script:Set-StopBudgetGrant -Repo $repo -Total 3
        $null = script:Invoke-StopRound -Repo $repo -RunId 'run-stop-cc-1' -Kind violated
        (Get-ReviewCampaignLoopState -StoreRoot $repo.store -CampaignId $script:CampaignId).ended_clean | Should -BeFalse
        @($script:Releasing) | Should -Not -Contain ([string](script:Get-StopSignoff -Repo $repo).route)
        $next = script:Invoke-StopRound -Repo $repo -RunId 'run-stop-cc-2' -Kind clean
        $next.invoked | Should -BeFalse
        [string]$next.reason | Should -BeExactly 'review-stop-open:c-judgment'
    }
}

Describe 'stop (d) and infra_failure_cap: a free run still counts, and an exhausted order is a pause fact (FR-009, FR-006(d))' {
    It 'an identity mismatch is free and writes no stop, but counts toward infra_failure_cap: two move the round to the next reviewer' {
        $repo = script:New-StopRepo -Root (Join-Path $TestDrive 'mismatch')
        script:Set-StopReviewers -Repo $repo
        script:Set-StopBudgetGrant -Repo $repo -Total 2 -HostOrder @('codex', 'copilot')
        $invoked = [System.Collections.Generic.List[string]]::new()
        $factory = script:New-StopPortsFactory -Repo $repo -Behaviour @{ codex = 'mismatch' } -Invoked $invoked
        foreach ($n in 1..3) { $null = script:Invoke-StopHostRound -Repo $repo -RunId "run-stop-mm-$n" -Factory $factory }
        @($invoked) | Should -Be @('codex', 'codex', 'copilot')
        (script:Get-StopCounter -Repo $repo).rounds_used | Should -Be 1 -Because 'the two mismatched runs collected no complete review'
        @(script:Get-StopPauseFacts -Repo $repo | Where-Object { [string]$_.stop_kind -ceq 'c-judgment' }).Count | Should -Be 0 -Because 'an identity mismatch is not stop (c)'
    }

    It 'repeated mismatches on every reviewer in the order end at (d), written as a pause fact naming the next reviewer; they never loop for free' {
        $repo = script:New-StopRepo -Root (Join-Path $TestDrive 'mismatch-d')
        script:Set-StopReviewers -Repo $repo
        script:Set-StopBudgetGrant -Repo $repo -Total 2 -HostOrder @('codex')
        $invoked = [System.Collections.Generic.List[string]]::new()
        $factory = script:New-StopPortsFactory -Repo $repo -Behaviour @{ codex = 'mismatch'; copilot = 'mismatch' } -Invoked $invoked
        $results = @(foreach ($n in 1..4) { script:Invoke-StopHostRound -Repo $repo -RunId "run-stop-mmd-$n" -Factory $factory })
        @($invoked) | Should -Be @('codex', 'codex')
        [string]$results[2].reason | Should -BeExactly 'review-stop-open:d-host-outside-order'
        $open = Get-ReviewCampaignOpenStop -StoreRoot $repo.store -CampaignId $script:CampaignId
        [string]$open.stop_kind | Should -BeExactly 'd-host-outside-order'
        [string]$open.next_host | Should -BeExactly 'copilot'
        (@($results[2].pause_surface) -join "`n") | Should -Match 'allow reviewer copilot'
        [string]$results[3].reason | Should -BeExactly 'review-stop-open:d-host-outside-order' -Because 'the same stop stays open; nothing more is written or run'
        @(script:Get-StopPauseFacts -Repo $repo | Where-Object { [string]$_.stop_kind -ceq 'd-host-outside-order' }).Count | Should -Be 1
    }

    # Iteration review round B finding 3 (run-20261113-172304585-393b6102; FR-009, FR-006(d)): no reviewer catalog and a
    # budget with no host order, and the human runs `specrew review --host codex`. The engine resolved no first reviewer, so
    # nothing was enforced: every timed-out attempt was free and invoked Codex again, past infra_failure_cap, never at (d).
    It 'with no reviewer catalog, an explicit --host is the approved first reviewer, and infra_failure_cap still ends at (d)' {
        $repo = script:New-StopRepo -Root (Join-Path $TestDrive 'no-catalog')
        script:Set-StopBudgetGrant -Repo $repo -Total 2
        Test-Path -LiteralPath (Join-Path $repo.root '.specrew/reviewer-hosts.json') | Should -BeFalse
        $invoked = [System.Collections.Generic.List[string]]::new()
        $factory = script:New-StopPortsFactory -Repo $repo -Behaviour @{ codex = 'partial' } -Invoked $invoked
        # The explicit host must be installed for the command to accept it; a stand-in on PATH for this case only.
        $hadCodex = $null -ne (Get-Command -Name codex -ErrorAction SilentlyContinue)
        if (-not $hadCodex) { function global:codex { } }
        try {
            $results = @(foreach ($n in 1..3) {
                    Invoke-ReviewCampaignCommand -RepoRoot $repo.root -FeatureId '001-demo' -IterationNumber '007' -RunId "run-stop-nc-$n" `
                        -AuthorityConfigPath $repo.config -CodeWriterHost 'claude' -ReviewerHost 'codex' -ReviewerHostExplicit -PortsFactory $factory
                })
        }
        finally { if (-not $hadCodex) { Remove-Item -LiteralPath Function:\codex -ErrorAction SilentlyContinue } }
        @($invoked) | Should -Be @('codex', 'codex') -Because 'infra_failure_cap is 2; the third attempt must not invoke Codex'
        [string]$results[2].reason | Should -BeExactly 'review-stop-open:d-host-outside-order'
        $grants = @(Get-ReviewAuthorityCampaignFacts -StoreRoot $repo.store -CampaignId $script:CampaignId -Kind grants | Where-Object { [string](Get-ReviewAuthorityProperty -Object $_ -Name 'reviewer_host') })
        [string](Get-ReviewAuthorityProperty -Object $grants[0] -Name 'reviewer_host') | Should -BeExactly 'codex' -Because 'the first reviewer is recorded on the launch grant'
    }

    It 'allow reviewer closes stop (d), and the round continues on that reviewer' {
        $repo = script:New-StopRepo -Root (Join-Path $TestDrive 'allow-d')
        script:Set-StopReviewers -Repo $repo
        script:Set-StopBudgetGrant -Repo $repo -Total 2 -HostOrder @('codex')
        $invoked = [System.Collections.Generic.List[string]]::new()
        $factory = script:New-StopPortsFactory -Repo $repo -Behaviour @{ codex = 'partial' } -Invoked $invoked
        foreach ($n in 1..3) { $null = script:Invoke-StopHostRound -Repo $repo -RunId "run-stop-ad-$n" -Factory $factory }
        [string](Get-ReviewCampaignOpenStop -StoreRoot $repo.store -CampaignId $script:CampaignId).stop_kind | Should -BeExactly 'd-host-outside-order'
        Start-Sleep -Milliseconds 20
        $null = Add-ReviewCampaignAllowedReviewerFact -StoreRoot $repo.store -CampaignId $script:CampaignId -HostName 'copilot' -AuthorizationRef 'typed-allow-reviewer-copilot' -ObservedAt ([DateTimeOffset]::UtcNow.ToString('o'))
        Get-ReviewCampaignOpenStop -StoreRoot $repo.store -CampaignId $script:CampaignId | Should -BeNullOrEmpty
        (script:Invoke-StopHostRound -Repo $repo -RunId 'run-stop-ad-4' -Factory $factory).invoked | Should -BeTrue
        @($invoked)[-1] | Should -BeExactly 'copilot'
    }
}

Describe 'partial findings stay open until a fix or a typed line closes them (DRIFT-052 item 3, second half)' {
    It 'a partial run''s finding is open, and a complete clean round on the same files does not close it' {
        $repo = script:New-StopRepo -Root (Join-Path $TestDrive 'partial-open')
        script:Set-StopBudgetGrant -Repo $repo -Total 3
        $null = script:Invoke-StopRound -Repo $repo -RunId 'run-stop-po-1' -Kind partial
        @(Get-ReviewCampaignOpenFindings -StoreRoot $repo.store -CampaignId $script:CampaignId).Count | Should -Be 1
        $null = script:Invoke-StopRound -Repo $repo -RunId 'run-stop-po-2' -Kind clean
        @(Get-ReviewCampaignOpenFindings -StoreRoot $repo.store -CampaignId $script:CampaignId).Count | Should -Be 1 -Because 'nothing was fixed'
        (Get-ReviewCampaignLoopState -StoreRoot $repo.store -CampaignId $script:CampaignId).ended_clean | Should -BeFalse
        @($script:Releasing) | Should -Not -Contain ([string](script:Get-StopSignoff -Repo $repo).route)
    }

    It 'a fix closes it: a complete round on moved files whose reviewer marks it resolved' {
        $repo = script:New-StopRepo -Root (Join-Path $TestDrive 'partial-fixed')
        script:Set-StopBudgetGrant -Repo $repo -Total 3
        $null = script:Invoke-StopRound -Repo $repo -RunId 'run-stop-pf-1' -Kind partial
        script:Add-StopFix -Repo $repo -Number 1
        $null = script:Invoke-StopRound -Repo $repo -RunId 'run-stop-pf-2' -Kind resolved
        @(Get-ReviewCampaignOpenFindings -StoreRoot $repo.store -CampaignId $script:CampaignId).Count | Should -Be 0
        (Get-ReviewCampaignLoopState -StoreRoot $repo.store -CampaignId $script:CampaignId).ended_clean | Should -BeTrue
    }

    It 'a typed drop closes it' {
        $repo = script:New-StopRepo -Root (Join-Path $TestDrive 'partial-dropped')
        script:Set-StopBudgetGrant -Repo $repo -Total 3
        $null = script:Invoke-StopRound -Repo $repo -RunId 'run-stop-pd-1' -Kind partial
        $finding = @(Get-ReviewCampaignOpenFindings -StoreRoot $repo.store -CampaignId $script:CampaignId)[0]
        $null = Add-ReviewCampaignFindingDisposition -StoreRoot $repo.store -CampaignId $script:CampaignId -FindingKey ([string]$finding.finding_key) `
            -Answer drop -Argument '' -AuthorizationRef 'typed-drop-finding' -ObservedAt ([DateTimeOffset]::UtcNow.ToString('o'))
        @(Get-ReviewCampaignOpenFindings -StoreRoot $repo.store -CampaignId $script:CampaignId).Count | Should -Be 0
    }
}

Describe 'an open finding closes only on the reviewer''s explicit resolved on moved files, or the human''s defer or drop (2026-11-09 ruling)' {
    BeforeEach { $script:StopScopes.Clear() }

    It 'the next round''s reviewer is given the open findings, by id' {
        $repo = script:New-StopRepo -Root (Join-Path $TestDrive 'given')
        script:Set-StopBudgetGrant -Repo $repo -Total 3
        $null = script:Invoke-StopRound -Repo $repo -RunId 'run-id-given-1' -Kind findings
        $open = @(Get-ReviewCampaignOpenFindings -StoreRoot $repo.store -CampaignId $script:CampaignId)[0]
        script:Add-StopFix -Repo $repo -Number 1
        $null = script:Invoke-StopRound -Repo $repo -RunId 'run-id-given-2' -Kind clean
        $script:StopScopes[-1] | Should -Match ([regex]::Escape([string]$open.finding_id))
    }

    It 'a reworded finding on a shifted line does not close the original' {
        $repo = script:New-StopRepo -Root (Join-Path $TestDrive 'reworded')
        script:Set-StopBudgetGrant -Repo $repo -Total 3
        $null = script:Invoke-StopRound -Repo $repo -RunId 'run-id-reword-1' -Kind findings
        $original = [string]@(Get-ReviewCampaignOpenFindings -StoreRoot $repo.store -CampaignId $script:CampaignId)[0].finding_id
        script:Add-StopFix -Repo $repo -Number 1
        $null = script:Invoke-StopRound -Repo $repo -RunId 'run-id-reword-2' -Kind reworded
        @(Get-ReviewCampaignOpenFindings -StoreRoot $repo.store -CampaignId $script:CampaignId | ForEach-Object { [string]$_.finding_id }) | Should -Contain $original
    }

    It 'no answer keeps it open: a clean round on moved files that does not answer it' {
        $repo = script:New-StopRepo -Root (Join-Path $TestDrive 'no-answer')
        script:Set-StopBudgetGrant -Repo $repo -Total 3
        $null = script:Invoke-StopRound -Repo $repo -RunId 'run-id-none-1' -Kind findings
        script:Add-StopFix -Repo $repo -Number 1
        $null = script:Invoke-StopRound -Repo $repo -RunId 'run-id-none-2' -Kind clean
        @(Get-ReviewCampaignOpenFindings -StoreRoot $repo.store -CampaignId $script:CampaignId).Count | Should -Be 1
        (Get-ReviewCampaignLoopState -StoreRoot $repo.store -CampaignId $script:CampaignId).ended_clean | Should -BeFalse
    }

    It 'still-open keeps it open' {
        $repo = script:New-StopRepo -Root (Join-Path $TestDrive 'still-open')
        script:Set-StopBudgetGrant -Repo $repo -Total 3
        $null = script:Invoke-StopRound -Repo $repo -RunId 'run-id-still-1' -Kind findings
        script:Add-StopFix -Repo $repo -Number 1
        $null = script:Invoke-StopRound -Repo $repo -RunId 'run-id-still-2' -Kind still-open
        (script:Get-StopCounter -Repo $repo).rounds_used | Should -Be 2 -Because 'the answering round collected a complete review'
        @(Get-ReviewCampaignOpenFindings -StoreRoot $repo.store -CampaignId $script:CampaignId).Count | Should -Be 1
    }

    It 'resolved on files that did not move keeps it open' {
        $repo = script:New-StopRepo -Root (Join-Path $TestDrive 'resolved-same')
        script:Set-StopBudgetGrant -Repo $repo -Total 3
        $null = script:Invoke-StopRound -Repo $repo -RunId 'run-id-same-1' -Kind partial
        $null = script:Invoke-StopRound -Repo $repo -RunId 'run-id-same-2' -Kind resolved
        (script:Get-StopCounter -Repo $repo).rounds_used | Should -Be 1 -Because 'the answering round collected a complete review'
        @(Get-ReviewCampaignOpenFindings -StoreRoot $repo.store -CampaignId $script:CampaignId).Count | Should -Be 1 -Because 'nothing was changed, so nothing was fixed'
    }

    It 'resolved on moved files closes it, and the review ends clean' {
        $repo = script:New-StopRepo -Root (Join-Path $TestDrive 'resolved-moved')
        script:Set-StopBudgetGrant -Repo $repo -Total 3
        $null = script:Invoke-StopRound -Repo $repo -RunId 'run-id-moved-1' -Kind findings
        script:Add-StopFix -Repo $repo -Number 1
        $null = script:Invoke-StopRound -Repo $repo -RunId 'run-id-moved-2' -Kind resolved
        @(Get-ReviewCampaignOpenFindings -StoreRoot $repo.store -CampaignId $script:CampaignId).Count | Should -Be 0
        (Get-ReviewCampaignLoopState -StoreRoot $repo.store -CampaignId $script:CampaignId).ended_clean | Should -BeTrue
    }
}
