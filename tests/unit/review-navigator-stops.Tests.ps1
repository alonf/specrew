# Feature 203 T008 step (iii) (FR-006; DRIFT-052 item 6 as ruled 2026-11-08): the navigator stops only on an open stop,
# (a) to (d), and only during implement. No stop asks for a round: there is no review-required or review-stale stop and
# no "What to do" line. The review-signoff boundary's coverage check is a boundary gate, not a round request, and stays
# (tests/unit/review-signoff-after-clean-round.Tests.ps1). Every case enters at the Stop hook's navigator entry
# (Invoke-ContinuousCoReviewWorktreeNavigator) on a real Git repo, with the shipped campaign authority.

BeforeAll {
    $script:RepoRoot = Split-Path -Parent (Split-Path -Parent $PSScriptRoot)
    $env:SPECREW_MODULE_PATH = $script:RepoRoot
    . (Join-Path $script:RepoRoot 'scripts/internal/continuous-co-review/_load.ps1')
    . (Join-Path $script:RepoRoot 'scripts/internal/continuous-co-review/continuous-co-review-navigator.ps1')
    . (Join-Path $script:RepoRoot 'scripts/internal/continuous-co-review/worktree-navigator.ps1')
    $script:CampaignId = Get-ReviewCampaignIdForIteration -FeatureId '001-demo' -IterationNumber '007'
    $script:Utf8 = [Text.UTF8Encoding]::new($false)

    function script:Invoke-NavGit([string]$Root, [string[]]$Arguments) {
        $null = & git -C $Root -c user.name=t -c user.email=t@example.invalid @Arguments 2>&1
        if ($LASTEXITCODE -ne 0) { throw ('fixture-git-failed:' + ($Arguments -join ' ')) }
    }

    # A project in the implement window (or at $Boundary) with feature work committed and nothing reviewed yet: before
    # step (iii) this was the review-required stop.
    function script:New-NavProject([string]$Name, [string]$Boundary = 'before-implement') {
        $root = Join-Path $TestDrive $Name
        New-Item -ItemType Directory -Path (Join-Path $root 'specs/001-demo/iterations/007'), (Join-Path $root 'src'), (Join-Path $root '.specify') -Force | Out-Null
        [IO.File]::WriteAllText((Join-Path $root 'specs/001-demo/spec.md'), '# Demo design context', $script:Utf8)
        [IO.File]::WriteAllText((Join-Path $root 'src/app.ps1'), "function Get-Answer { 42 }`n", $script:Utf8)
        [IO.File]::WriteAllText((Join-Path $root '.gitignore'), ".specrew/`n", $script:Utf8)
        [IO.File]::WriteAllText((Join-Path $root '.specify/feature.json'), '{ "feature_directory": "specs/001-demo" }', $script:Utf8)
        script:Invoke-NavGit $root @('init', '-q')
        script:Invoke-NavGit $root @('branch', '-m', 'main')
        script:Invoke-NavGit $root @('add', '-A')
        script:Invoke-NavGit $root @('commit', '-qm', 'trunk')
        script:Invoke-NavGit $root @('checkout', '-q', '-b', '001-demo')
        [IO.File]::WriteAllText((Join-Path $root 'src/feature.ps1'), "function Get-Feature { 'implemented' }`n", $script:Utf8)
        script:Invoke-NavGit $root @('add', '-A')
        script:Invoke-NavGit $root @('commit', '-qm', 'feature work')
        New-Item -ItemType Directory -Path (Join-Path $root '.specrew/runtime') -Force | Out-Null
        $context = [ordered]@{ session_state = [ordered]@{ boundary_type = $Boundary; feature_ref = '001-demo'; iteration_number = '007' } }
        [IO.File]::WriteAllText((Join-Path $root '.specrew/start-context.json'), ($context | ConvertTo-Json -Depth 6), $script:Utf8)
        return $root
    }

    # A stop the engine wrote: (a) with one open finding, through the engine's own fact writer.
    function script:Add-NavStop([string]$Root, [string]$Kind = 'a-budget-spent') {
        $store = Join-Path $Root '.specrew/review/authority'
        $decision = Resolve-ReviewCampaignPauseDecision -Findings @() -RoundsUsed 2 -BudgetTotal 2
        $fact = New-ReviewCampaignPendingPauseFact -CampaignId $script:CampaignId -RunId 'run-nav-stop-1' -TargetDigest ('a' * 40) -Decision $decision `
            -ObservedAt ([DateTimeOffset]::UtcNow.ToString('o')) -StopKind $Kind -StopReason 'budget-spent'
        $null = Write-ReviewCampaignPendingPauseFact -StoreRoot $store -Fact $fact
    }

    function script:Invoke-Nav([string]$Root) {
        return Invoke-ContinuousCoReviewWorktreeNavigator -RepoRoot $Root
    }
}

Describe 'the navigator stops only on an open stop, and only during implement (FR-006; DRIFT-052 item 6)' {
    It 'feature work nobody has reviewed yet is no stop: there is no review-required stop' {
        $root = script:New-NavProject -Name 'unreviewed'
        $decision = script:Invoke-Nav -Root $root
        $decision.stop_block | Should -BeNullOrEmpty -Because ([string]$decision.reason)
    }

    It 'files changed since the last round are no stop: there is no review-stale stop' {
        $root = script:New-NavProject -Name 'stale'
        $store = Join-Path $root '.specrew/review/authority'
        $result = [pscustomobject][ordered]@{
            schema_version = '1.0'; campaign_id = $script:CampaignId; run_id = 'run-nav-old'; target_digest = ('b' * 40); harness_id = 'fixture'
            completion = 'complete'; verdict = 'pass'; runtime_outcome = 'completed'; termination_verified = $true; containment = 'verified'
            currentness = 'current'; validation = 'valid'; can_approve_current = $true; summary = 'clean'; findings = @()
            started_at = '2026-11-09T08:00:00Z'; ended_at = '2026-11-09T08:01:00Z'; duration_ms = 60000; examined_paths = @('src/app.ps1'); review_collected = $true
        }
        Request-ReviewAuthorityClaim -StoreRoot $store -CampaignId $script:CampaignId -RunId 'run-nav-old' -TargetLineage 'lin-001-demo' -ObservedAt '2026-11-09T08:00:00Z' | Out-Null
        Publish-ReviewRunResultFact -StoreRoot $store -CampaignId $script:CampaignId -RunId 'run-nav-old' -Fact $result | Out-Null
        Complete-ReviewAuthorityClaim -StoreRoot $store -CampaignId $script:CampaignId -RunId 'run-nav-old' -TargetLineage 'lin-001-demo' -Disposition released -ObservedAt '2026-11-09T08:01:00Z' | Out-Null
        $decision = script:Invoke-Nav -Root $root
        $decision.stop_block | Should -BeNullOrEmpty -Because ([string]$decision.reason)
    }

    It 'an open stop during implement stops, rendering its FR-011 layout' {
        $root = script:New-NavProject -Name 'open-stop'
        script:Add-NavStop -Root $root
        $decision = script:Invoke-Nav -Root $root
        [string]$decision.stop_block | Should -Match 'Why: '
        [string]$decision.stop_block | Should -Match 'approved for allowance reset'
        [string]$decision.stop_block | Should -Match 'stop the review here'
        [string]$decision.stop_block | Should -Not -Match 'What to do'
        [string]$decision.agent_directives | Should -Not -BeNullOrEmpty
    }

    It 'an open stop outside implement does not stop: no review stop occurs outside implement' {
        $root = script:New-NavProject -Name 'signoff-stage' -Boundary 'review-signoff'
        script:Add-NavStop -Root $root
        $decision = script:Invoke-Nav -Root $root
        $decision.stop_block | Should -BeNullOrEmpty -Because ([string]$decision.reason)
    }

    It 'the navigator has no round request left: no "What to do" line, and no block built from a review-required or review-stale route' {
        $navigator = Get-Content -LiteralPath (Join-Path $script:RepoRoot 'scripts/internal/continuous-co-review/continuous-co-review-navigator.ps1') -Raw
        $navigator | Should -Not -Match "AppendLine\(\('What to do"
        Get-Command -Name Build-ReviewCampaignNavigatorStopBlock -ErrorAction SilentlyContinue | Should -BeNullOrEmpty
        $navigator | Should -Not -Match "'review-required'\s*\{"
        $navigator | Should -Not -Match "'review-stale'\s*\{"
    }
}
