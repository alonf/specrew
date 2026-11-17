# Feature 203 T022, the gate half (F4: DRIFT-078, DRIFT-091, B5F-071; design-analysis Option A, "built small"). The ordinary
# review end takes one approval: the round comes back with findings, the human stops the review accepting them, the crew
# commits the review record the sign-off sync itself demands, and the sign-off sync passes - with no partial-sign-off line.
#
# Measured on feature 206 (2026-11-17, main's engine) and read on this engine: the stop lands an accept-current disposition
# for the reviewed digest, and then
#   (1) at that exact digest, a gating finding still open makes the sign-off "review-findings-open": the human's stop does
#       not count for the open ones (B5F-071's second half);
#   (2) after the records-only commit, the records-only rule preserves a findings result only when no gating finding is
#       open, and never reads the human's acceptance (DRIFT-078), so the sign-off refuses
#       "records-only-delta-over-non-authorizing-result" and the human types a second line (DRIFT-091).
# Entered at the sign-off check (Get-ContinuousCoReviewSignoffGateDecision, what the review-signoff boundary runs) on a real
# Git repository with a real authority store.

BeforeAll {
    $script:RepoRoot = Split-Path -Parent (Split-Path -Parent $PSScriptRoot)
    . (Join-Path $script:RepoRoot 'scripts/internal/continuous-co-review/_load.ps1')
    . (Join-Path $script:RepoRoot 'scripts/internal/continuous-co-review/continuous-co-review-navigator.ps1')
    . (Join-Path $script:RepoRoot 'scripts/internal/continuous-co-review/signoff-gate-wiring.ps1')
    $script:Utf8 = [Text.UTF8Encoding]::new($false)
    $script:Campaign = 'cmp-demo-i007'
    $script:RunId = 'run-end-1'

    function script:Invoke-EndGit([string]$Root, [string[]]$Arguments) {
        $null = & git -C $Root -c user.name=t -c user.email=t@example.invalid @Arguments 2>&1
        if ($LASTEXITCODE -ne 0) { throw ('fixture-git-failed:' + ($Arguments -join ' ')) }
    }

    function script:New-EndFinding([string]$Id, [string]$Severity, [string]$Title, [string]$Location) {
        return [pscustomobject][ordered]@{
            finding_id = $Id; source_local_id = 'l-' + $Id.Substring(8, 4); lineage_id = 'lin-' + $Id.Substring(8); severity = $Severity; title = $Title
            description = 'Failure scenario: it breaks.'; location = $Location; relevance = 'current'; resolution = 'open'; demoted = $false; demoted_from = ''
        }
    }

    # A project whose one round reviewed the files exactly as they are now and returned one open major finding and one minor.
    function script:New-EndProject([string]$Name) {
        $root = Join-Path $TestDrive $Name
        New-Item -ItemType Directory -Path (Join-Path $root 'specs/001-demo/iterations/007'), (Join-Path $root 'src') -Force | Out-Null
        [IO.File]::WriteAllText((Join-Path $root 'specs/001-demo/spec.md'), '# Demo design context', $script:Utf8)
        [IO.File]::WriteAllText((Join-Path $root 'src/app.ps1'), "function Get-Answer { 42 }`n", $script:Utf8)
        [IO.File]::WriteAllText((Join-Path $root '.gitignore'), ".specrew/review/`n", $script:Utf8)
        script:Invoke-EndGit $root @('init', '-q'); script:Invoke-EndGit $root @('branch', '-m', 'main')
        script:Invoke-EndGit $root @('add', '-A'); script:Invoke-EndGit $root @('commit', '-qm', 'initial')
        $store = Join-Path $root '.specrew/review/authority'
        $digest = [string](Get-ContinuousCoReviewReviewedStateDigest -RepoRoot $root).tree_id
        $result = [pscustomobject][ordered]@{
            schema_version = '1.0'; campaign_id = $script:Campaign; run_id = $script:RunId; target_digest = $digest; harness_id = 'fixture'
            completion = 'complete'; verdict = 'findings'; runtime_outcome = 'completed'; termination_verified = $true; containment = 'verified'
            currentness = 'current'; validation = 'valid'; can_approve_current = $false; summary = 'fixture'
            findings = @(
                (script:New-EndFinding -Id 'finding-00000000000000a1' -Severity 'major' -Title 'Retry never backs off' -Location 'src/poll.ps1:41'),
                (script:New-EndFinding -Id 'finding-00000000000000a2' -Severity 'minor' -Title 'Typo in help text' -Location 'src/app.ps1:3'))
            started_at = '2026-11-17T20:00:00Z'; ended_at = '2026-11-17T20:01:00Z'; duration_ms = 60000; examined_paths = @('src/app.ps1'); review_collected = $true
        }
        Request-ReviewAuthorityClaim -StoreRoot $store -CampaignId $script:Campaign -RunId $script:RunId -TargetLineage 'lin-demo' -ObservedAt '2026-11-17T20:00:00Z' | Out-Null
        Publish-ReviewRunResultFact -StoreRoot $store -CampaignId $script:Campaign -RunId $script:RunId -Fact $result | Out-Null
        Complete-ReviewAuthorityClaim -StoreRoot $store -CampaignId $script:Campaign -RunId $script:RunId -TargetLineage 'lin-demo' -Disposition released -ObservedAt '2026-11-17T20:01:00Z' | Out-Null
        return [pscustomobject]@{ root = $root; store = $store; digest = $digest }
    }

    # What the stop's landing records (the AcceptPort of the stop-here landing): the human's acceptance of this exact result.
    function script:Add-EndDisposition([pscustomobject]$Project, [string]$Decision = 'accept-current') {
        $null = Add-ReviewCampaignHumanDisposition -StoreRoot $Project.store -CampaignId $script:Campaign -RunId $script:RunId `
            -Decision $Decision -AuthorizedBy 'human' -AuthorizationRef 'turn-stop-1' -Rationale 'Remaining findings accepted at the stop' -TurnIdentity 'turn-stop-1'
    }

    # The review record the sign-off sync demands, committed after the stop: a records-only change.
    function script:Add-RecordsCommit([pscustomobject]$Project) {
        [IO.File]::WriteAllText((Join-Path $Project.root 'specs/001-demo/iterations/007/drift-log.md'), "# Drift`n`n- the review ended at the stop`n", $script:Utf8)
        [IO.File]::WriteAllText((Join-Path $Project.root 'specs/001-demo/iterations/007/review.md'), "# Review`n", $script:Utf8)
        script:Invoke-EndGit $Project.root @('add', '-A'); script:Invoke-EndGit $Project.root @('commit', '-qm', 'review record')
    }

    function script:Add-CodeCommit([pscustomobject]$Project) {
        [IO.File]::WriteAllText((Join-Path $Project.root 'src/app.ps1'), "function Get-Answer { 43 }`n", $script:Utf8)
        script:Invoke-EndGit $Project.root @('add', '-A'); script:Invoke-EndGit $Project.root @('commit', '-qm', 'code after the stop')
    }

    function script:Get-EndSignoff([pscustomobject]$Project) {
        return Get-ContinuousCoReviewSignoffGateDecision -RepoRoot $Project.root -CampaignId $script:Campaign -TargetLineage 'lin-demo' `
            -CampaignStoreRoot $Project.store -FeatureId '001-demo' -IterationNumber '007'
    }
}

Describe 'T022: the human''s stop counts for the findings it accepted (B5F-071, the open ones)' {
    It 'at the reviewed digest, a stop accepting an open major finding releases the sign-off' {
        $project = script:New-EndProject -Name 'stop-at-digest'
        script:Add-EndDisposition -Project $project
        $signoff = script:Get-EndSignoff -Project $project
        [string]$signoff.decision | Should -BeExactly 'allow' -Because 'the human read the open finding at the stop and accepted it; that is the answer the stop exists to record'
    }

    It 'the sign-off still names the accepted finding, as accepted at the stop and not fixed' {
        $project = script:New-EndProject -Name 'stop-listing'
        script:Add-EndDisposition -Project $project
        $message = [string](script:Get-EndSignoff -Project $project).message
        $message | Should -Match 'finding-00000000000000a1'
        $message | Should -Match 'Retry never backs off'
        $message | Should -Match '(?i)accepted at (your|the) stop'
        $message | Should -Match 'finding-00000000000000a2' -Because 'the minor stays listed as a follow-up'
    }

    It 'with no disposition, the open major still blocks (pinned)' {
        $project = script:New-EndProject -Name 'no-stop'
        [string](script:Get-EndSignoff -Project $project).decision | Should -BeExactly 'block'
    }

    It 'a require-correction disposition blocks (pinned)' {
        $project = script:New-EndProject -Name 'require-correction'
        script:Add-EndDisposition -Project $project -Decision 'require-correction'
        [string](script:Get-EndSignoff -Project $project).decision | Should -BeExactly 'block'
    }
}

Describe 'T022: the ordinary review end takes one approval (DRIFT-078, DRIFT-091)' {
    It 'after the stop, the review-record commit does not take the human''s acceptance away' {
        $project = script:New-EndProject -Name 'records-after-stop'
        script:Add-EndDisposition -Project $project
        script:Add-RecordsCommit -Project $project
        $signoff = script:Get-EndSignoff -Project $project
        [string]$signoff.decision | Should -BeExactly 'allow' -Because 'the record the sign-off sync demands must not cost the human a second typed line'
        [string]$signoff.reason | Should -Not -Be 'human-authorized-partial-override' -Because 'no override was given'
    }

    It 'a code commit after the stop still stales the acceptance (pinned)' {
        $project = script:New-EndProject -Name 'code-after-stop'
        script:Add-EndDisposition -Project $project
        script:Add-CodeCommit -Project $project
        [string](script:Get-EndSignoff -Project $project).decision | Should -BeExactly 'block' -Because 'the human accepted findings about code that has since moved unreviewed'
    }

    It 'a records commit with no stop does not promote a findings result (pinned)' {
        $project = script:New-EndProject -Name 'records-no-stop'
        script:Add-RecordsCommit -Project $project
        [string](script:Get-EndSignoff -Project $project).decision | Should -BeExactly 'block'
    }

    It 'a records commit after a require-correction stays blocked (pinned)' {
        $project = script:New-EndProject -Name 'records-after-correction'
        script:Add-EndDisposition -Project $project -Decision 'require-correction'
        script:Add-RecordsCommit -Project $project
        [string](script:Get-EndSignoff -Project $project).decision | Should -BeExactly 'block'
    }
}
