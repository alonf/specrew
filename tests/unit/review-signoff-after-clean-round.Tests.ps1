# Feature 203 T008 (FR-013; DRIFT-052 item 6, ruled 2026-11-08): the review-signoff check refuses when the code changed
# after the last clean round, including a change that touches only tests (no test-only exemption). Written first in step
# (iii), before the navigator's round requests are removed, so the sign-off check keeps this property when they go.
# Enters at the sign-off check's decision (Get-ReviewCampaignVerdictPacketDecision), on a real Git repo.

BeforeAll {
    $script:RepoRoot = Split-Path -Parent (Split-Path -Parent $PSScriptRoot)
    . (Join-Path $script:RepoRoot 'scripts/internal/continuous-co-review/_load.ps1')
    . (Join-Path $script:RepoRoot 'scripts/internal/continuous-co-review/continuous-co-review-navigator.ps1')
    . (Join-Path $script:RepoRoot 'scripts/internal/continuous-co-review/signoff-gate-wiring.ps1')
    $script:Utf8 = [Text.UTF8Encoding]::new($false)
    $script:Releasing = @('boundary-clean', 'review-current', 'boundary-finalized', 'boundary-human-disposition')

    function script:Invoke-SignoffGit([string]$Root, [string[]]$Arguments) {
        $null = & git -C $Root -c user.name=t -c user.email=t@example.invalid @Arguments 2>&1
        if ($LASTEXITCODE -ne 0) { throw ('fixture-git-failed:' + ($Arguments -join ' ')) }
    }

    function script:Add-SignoffCommit([string]$Root, [string]$RelativePath, [string]$Content) {
        $path = Join-Path $Root $RelativePath
        [IO.Directory]::CreateDirectory((Split-Path -Parent $path)) | Out-Null
        [IO.File]::WriteAllText($path, $Content, $script:Utf8)
        script:Invoke-SignoffGit $Root @('add', '-A')
        script:Invoke-SignoffGit $Root @('commit', '-qm', $RelativePath)
    }

    # A project whose latest review round is clean and covers the tree exactly as it is.
    function script:New-CleanReviewedProject([string]$Root) {
        New-Item -ItemType Directory -Path (Join-Path $Root 'specs/001-demo/iterations/007') -Force | Out-Null
        [IO.File]::WriteAllText((Join-Path $Root 'specs/001-demo/spec.md'), '# Demo design context', $script:Utf8)
        New-Item -ItemType Directory -Path (Join-Path $Root 'src'), (Join-Path $Root 'tests') -Force | Out-Null
        [IO.File]::WriteAllText((Join-Path $Root 'src/app.ps1'), "function Get-Answer { 42 }`n", $script:Utf8)
        [IO.File]::WriteAllText((Join-Path $Root 'tests/app.Tests.ps1'), "Describe 'answer' { It 'is 42' { 42 | Should -Be 42 } }`n", $script:Utf8)
        [IO.File]::WriteAllText((Join-Path $Root '.gitignore'), ".specrew/review/`n", $script:Utf8)
        script:Invoke-SignoffGit $Root @('init', '-q')
        script:Invoke-SignoffGit $Root @('branch', '-m', 'main')
        script:Invoke-SignoffGit $Root @('add', '-A')
        script:Invoke-SignoffGit $Root @('commit', '-qm', 'initial')
        $store = Join-Path $Root '.specrew/review/authority'
        $campaign = 'cmp-demo-i007'; $run = 'run-signoff-clean'
        $digest = [string](Get-ContinuousCoReviewReviewedStateDigest -RepoRoot $Root).tree_id
        $result = [pscustomobject][ordered]@{
            schema_version = '1.0'; campaign_id = $campaign; run_id = $run; target_digest = $digest; harness_id = 'fixture'
            completion = 'complete'; verdict = 'pass'; runtime_outcome = 'completed'; termination_verified = $true; containment = 'verified'
            currentness = 'current'; validation = 'valid'; can_approve_current = $true; summary = 'clean'; findings = @()
            started_at = '2026-11-09T08:00:00Z'; ended_at = '2026-11-09T08:01:00Z'; duration_ms = 60000; examined_paths = @('src/app.ps1'); review_collected = $true
        }
        Request-ReviewAuthorityClaim -StoreRoot $store -CampaignId $campaign -RunId $run -TargetLineage 'lin-demo' -ObservedAt '2026-11-09T08:00:00Z' | Out-Null
        Publish-ReviewRunResultFact -StoreRoot $store -CampaignId $campaign -RunId $run -Fact $result | Out-Null
        Complete-ReviewAuthorityClaim -StoreRoot $store -CampaignId $campaign -RunId $run -TargetLineage 'lin-demo' -Disposition released -ObservedAt '2026-11-09T08:01:00Z' | Out-Null
        return [pscustomobject]@{ root = $Root; store = $store }
    }

    function script:Get-SignoffDecision([pscustomobject]$Project) {
        return Get-ReviewCampaignVerdictPacketDecision -RepoRoot $Project.root -CampaignId 'cmp-demo-i007' -TargetLineage 'lin-demo' `
            -StoreRoot $Project.store -FeatureId '001-demo' -IterationNumber '007'
    }
}

Describe 'the review-signoff check refuses code changed after the last clean round (FR-013)' {
    It 'control: with nothing changed since the clean round, the boundary is released' {
        $project = script:New-CleanReviewedProject -Root (Join-Path $TestDrive 'unchanged')
        $decision = script:Get-SignoffDecision -Project $project
        @($script:Releasing) | Should -Contain ([string]$decision.route) -Because ([string]$decision.reason)
    }

    It 'a source change after the clean round is refused' {
        $project = script:New-CleanReviewedProject -Root (Join-Path $TestDrive 'source')
        script:Add-SignoffCommit -Root $project.root -RelativePath 'src/app.ps1' -Content "function Get-Answer { 43 }`n"
        $decision = script:Get-SignoffDecision -Project $project
        @($script:Releasing) | Should -Not -Contain ([string]$decision.route) -Because 'the clean round reviewed other code'
        [bool]$decision.render_boundary_packet | Should -BeFalse
    }

    It 'a change that touches only tests is refused too: there is no test-only exemption' {
        $project = script:New-CleanReviewedProject -Root (Join-Path $TestDrive 'tests-only')
        script:Add-SignoffCommit -Root $project.root -RelativePath 'tests/app.Tests.ps1' -Content "Describe 'answer' { It 'is 43' { 43 | Should -Be 43 } }`n"
        $decision = script:Get-SignoffDecision -Project $project
        @($script:Releasing) | Should -Not -Contain ([string]$decision.route) -Because 'a test-only fix gets the next round within the budget (FR-013)'
        [bool]$decision.render_boundary_packet | Should -BeFalse
    }

    It 'control: a change to the feature''s own records only does not reopen the review' {
        $project = script:New-CleanReviewedProject -Root (Join-Path $TestDrive 'records')
        script:Add-SignoffCommit -Root $project.root -RelativePath 'specs/001-demo/iterations/007/drift-log.md' -Content "# drift`n"
        $decision = script:Get-SignoffDecision -Project $project
        @($script:Releasing) | Should -Contain ([string]$decision.route) -Because ([string]$decision.reason)
    }
}
