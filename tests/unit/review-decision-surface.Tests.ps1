# Feature 203 T008 step (iii) (FR-006, FR-010, FR-011; maintainer ruling 2026-11-09, DRIFT-052 "the old pause decision
# and its renderers"): the old numbered pause menu is gone. Its two renderers had no production caller and are deleted;
# the pause decision keeps only what something live reads (rounds_used, budget_total, recommendation) and carries none of
# the old menu's severity sentences, which never reach a stop surface. "Did a complete review come back" has one answer,
# review_collected, read by the engine and by the sign-off gate's review-partial route, whose words no longer ask for a
# separately authorized run (FR-010 removed per-round authorization).

BeforeAll {
    $script:RepoRoot = Split-Path -Parent (Split-Path -Parent $PSScriptRoot)
    . (Join-Path $script:RepoRoot 'scripts/internal/continuous-co-review/_load.ps1')
    . (Join-Path $script:RepoRoot 'scripts/internal/continuous-co-review/continuous-co-review-navigator.ps1')
    $script:OldMenuSentences = @(
        'Fix the blocking findings before you sign off', 'Look at the major findings', 'Nothing here blocks you',
        'Stopping here saves the minor findings', 'Stopping here completes your sign-off', 'reset it explicitly or abandon',
        'abandon this campaign', 'run another round'
    )
    function script:New-GateResult([string]$Completion = 'complete', [bool]$Collected = $true, [string]$Verdict = 'pass', [string]$Outcome = 'completed', [object[]]$Findings = @()) {
        return [pscustomobject][ordered]@{
            schema_version = '1.0'; campaign_id = 'cmp-demo-i007'; run_id = 'run-one'; target_digest = 'digest-current'; harness_id = 'fixture'
            completion = $Completion; verdict = $Verdict; runtime_outcome = $Outcome; termination_verified = $true; containment = 'verified'
            currentness = 'current'; validation = 'valid'; can_approve_current = ($Verdict -ceq 'pass' -and $Collected); failure_reason = 'killed after timeout'
            summary = 'fixture'; findings = @($Findings); started_at = '2026-11-09T08:00:00Z'; ended_at = '2026-11-09T08:01:00Z'; duration_ms = 60000
            examined_paths = @('src/app.ps1'); review_collected = $Collected
        }
    }
    function script:Resolve-Gate($Result) {
        return Resolve-ReviewCampaignVerdictPacketDecision -CampaignId 'cmp-demo-i007' -CurrentDigest 'digest-current' -OrderedRunIds @('run-one') -Results @($Result)
    }
    function script:New-Major { [pscustomobject][ordered]@{ finding_id = 'finding-0123456789abcdef'; severity = 'major'; title = 'Empty store'; location = 'src/app.ps1:1'; resolution = 'open' } }
}

Describe 'the old pause menu is gone, and nothing reads it (maintainer ruling 2026-11-09)' {
    It 'its two renderers are deleted' {
        Get-Command -Name Format-ReviewCampaignPauseSurface -ErrorAction SilentlyContinue | Should -BeNullOrEmpty
        Get-Command -Name Format-ReviewCampaignOutstandingPause -ErrorAction SilentlyContinue | Should -BeNullOrEmpty
    }

    It 'the pause decision keeps only rounds_used, budget_total and recommendation, and its recommendation carries no old menu sentence' {
        foreach ($case in @(
                @{ Findings = @([pscustomobject]@{ severity = 'blocking'; title = 'x' }); Result = $null }
                @{ Findings = @([pscustomobject]@{ severity = 'major'; title = 'x' }); Result = $null }
                @{ Findings = @([pscustomobject]@{ severity = 'minor'; title = 'x' }); Result = $null }
                @{ Findings = @(); Result = $null }
                @{ Findings = @(); Result = [pscustomobject]@{ completion = 'none'; validation = 'not-produced' } }
            )) {
            $decision = Resolve-ReviewCampaignPauseDecision -Findings $case.Findings -RoundsUsed 2 -BudgetTotal 2 -Result $case.Result
            @($decision.PSObject.Properties.Name | Sort-Object) | Should -Be @('budget_total', 'recommendation', 'rounds_used')
            foreach ($sentence in $script:OldMenuSentences) { [string]$decision.recommendation | Should -Not -Match ([regex]::Escape($sentence)) }
        }
    }

    It 'a pause fact without the unread counts is valid, so a stop written now is too; one written before is still valid' {
        $decision = Resolve-ReviewCampaignPauseDecision -Findings @() -RoundsUsed 1 -BudgetTotal 2
        $fact = New-ReviewCampaignPendingPauseFact -CampaignId 'cmp-demo-i007' -RunId 'run-one' -TargetDigest ('a' * 40) -Decision $decision `
            -ObservedAt '2026-11-09T08:00:00Z' -StopKind 'c-judgment' -StopReason 'containment-violated'
        (Test-ReviewAuthorityContractObject -ContractName PendingPauseFact -InputObject $fact -ExpectedCampaignId 'cmp-demo-i007').valid | Should -BeTrue
        $older = $fact | Select-Object *
        foreach ($name in @('blocking_count', 'major_count', 'minor_count', 'demoted_count')) { $older | Add-Member -NotePropertyName $name -NotePropertyValue 0 -Force }
        (Test-ReviewAuthorityContractObject -ContractName PendingPauseFact -InputObject $older -ExpectedCampaignId 'cmp-demo-i007').valid | Should -BeTrue
    }

    It 'a stop''s recommendation is written by that stop''s own writer: stop (c) for a reviewer that changed the frozen copy carries its own reason' {
        $store = Join-Path $TestDrive 'stop-c'
        $result = [pscustomobject]@{ findings = @(); duration_ms = 1000; completion = 'complete'; review_collected = $true; containment = 'violated'; runtime_outcome = 'containment-violated' }
        $stop = Add-ReviewCampaignRoundPause -StoreRoot $store -CampaignId 'cmp-demo-i007' -RunId 'run-c' -TargetDigest ('a' * 40) -ProjectName 'demo' -Result $result -ObservedAt '2026-11-09T08:00:00Z'
        [string]$stop.fact.recommendation | Should -Match 'changed the frozen copy'
        foreach ($sentence in $script:OldMenuSentences) { [string]$stop.fact.recommendation | Should -Not -Match ([regex]::Escape($sentence)) }
    }
}

Describe 'one answer to "did a complete review come back": review_collected, in the engine and at sign-off (FR-010)' {
    It 'the sign-off''s review-partial route reads review_collected: a result whose completion reads complete but that collected no review is partial' {
        (script:Resolve-Gate (script:New-GateResult -Completion 'complete' -Collected $false)).route | Should -BeExactly 'review-partial'
    }

    It 'the review-partial route tells the human the latest review did not complete, in consumer language, with no per-round authorization' {
        $decision = script:Resolve-Gate (script:New-GateResult -Completion 'partial' -Collected $false -Verdict 'incomplete' -Outcome 'terminated')
        $decision.route | Should -BeExactly 'review-partial'
        [string]$decision.message | Should -Match 'did not complete'
        [string]$decision.message | Should -Not -Match 'authoriz'
    }

    It 'the timeout route asks for no rerun grant, and neither does the actionable route' {
        $timeout = script:Resolve-Gate (script:New-GateResult -Completion 'partial' -Collected $false -Verdict 'incomplete' -Outcome 'timed-out')
        $timeout.route | Should -BeExactly 'review-timeout'
        [string]$timeout.implementer_action | Should -Not -Match 'grant'
        [string]$timeout.message | Should -Not -Match 'authoriz'
        $actionable = script:Resolve-Gate (script:New-GateResult -Verdict 'findings' -Findings @((script:New-Major)))
        $actionable.route | Should -BeExactly 'review-actionable'
        [string]$actionable.message | Should -Not -Match 'separately authorized'
    }
}
