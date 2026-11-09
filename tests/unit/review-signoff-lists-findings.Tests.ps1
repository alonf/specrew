# Feature 203 T008 step (iii) (FR-011, FR-013; maintainer rulings 2026-11-09): the review sign-off names what the review
# leaves behind, finding by finding (id, title, where), never only a count: every finding still open as not covered (after
# `stop the review here` too), every non-gating finding of the reviewed head as a follow-up, and every finding the
# ingestor demoted, with the reviewer's original severity and why. A blocker the ingestor demotes never opens a finding,
# so the loop can end clean with no stop; the sign-off must still name it. Entered at the sign-off check
# (Get-ContinuousCoReviewSignoffGateDecision, what the review-signoff boundary runs) on a real Git repo.

BeforeAll {
    $script:RepoRoot = Split-Path -Parent (Split-Path -Parent $PSScriptRoot)
    . (Join-Path $script:RepoRoot 'scripts/internal/continuous-co-review/_load.ps1')
    . (Join-Path $script:RepoRoot 'scripts/internal/continuous-co-review/continuous-co-review-navigator.ps1')
    . (Join-Path $script:RepoRoot 'scripts/internal/continuous-co-review/signoff-gate-wiring.ps1')
    $script:Utf8 = [Text.UTF8Encoding]::new($false)
    $script:Campaign = 'cmp-demo-i007'
    $script:CrossingCampaign = 'cmp-001-demo-i007'
    $script:ListingName = 'review-signoff-listing.json'

    function script:Invoke-ListGit([string]$Root, [string[]]$Arguments) {
        $null = & git -C $Root -c user.name=t -c user.email=t@example.invalid @Arguments 2>&1
        if ($LASTEXITCODE -ne 0) { throw ('fixture-git-failed:' + ($Arguments -join ' ')) }
    }

    function script:New-Finding([string]$Id, [string]$Severity, [string]$Title, [string]$Location, [switch]$Demoted) {
        return [pscustomobject][ordered]@{
            finding_id = $Id; source_local_id = 'l-' + $Id.Substring(8, 4); lineage_id = 'lin-' + $Id.Substring(8); severity = $Severity; title = $Title
            description = $(if ($Demoted) { '[demoted to minor: no concrete failure scenario, so it cannot gate; reported as blocking by the reviewer] the cache is never invalidated' } else { 'Failure scenario: it breaks.' })
            location = $Location; relevance = 'current'; resolution = 'open'; demoted = [bool]$Demoted; demoted_from = $(if ($Demoted) { 'blocking' } else { '' })
        }
    }

    # A project whose one round reviewed the files exactly as they are now and returned $Findings. -WithLifecycle records
    # the active feature and iteration the way a real project does, so the review-signoff crossing resolves them itself.
    function script:New-ListProject([string]$Name, [object[]]$Findings, [string]$Verdict, [switch]$WithLifecycle) {
        $campaign = if ($WithLifecycle) { $script:CrossingCampaign } else { $script:Campaign }
        $lineage = if ($WithLifecycle) { 'lin-001-demo' } else { 'lin-demo' }
        $root = Join-Path $TestDrive $Name
        New-Item -ItemType Directory -Path (Join-Path $root 'specs/001-demo/iterations/007'), (Join-Path $root 'src') -Force | Out-Null
        [IO.File]::WriteAllText((Join-Path $root 'specs/001-demo/spec.md'), '# Demo design context', $script:Utf8)
        if ($WithLifecycle) {
            New-Item -ItemType Directory -Path (Join-Path $root '.specrew') -Force | Out-Null
            [IO.File]::WriteAllText((Join-Path $root '.specrew/start-context.json'), (([ordered]@{
                            schema = 'v2'; feature_path = (Join-Path $root 'specs/001-demo')
                            session_state = [ordered]@{ active = $true; boundary_type = 'implement'; feature_ref = '001-demo'; feature_path = (Join-Path $root 'specs/001-demo'); iteration_number = '007' }
                        }) | ConvertTo-Json -Depth 6), $script:Utf8)
        }
        [IO.File]::WriteAllText((Join-Path $root 'src/app.ps1'), "function Get-Answer { 42 }`n", $script:Utf8)
        [IO.File]::WriteAllText((Join-Path $root '.gitignore'), ".specrew/review/`n", $script:Utf8)
        script:Invoke-ListGit $root @('init', '-q'); script:Invoke-ListGit $root @('branch', '-m', 'main')
        script:Invoke-ListGit $root @('add', '-A'); script:Invoke-ListGit $root @('commit', '-qm', 'initial')
        $store = Join-Path $root '.specrew/review/authority'
        $digest = [string](Get-ContinuousCoReviewReviewedStateDigest -RepoRoot $root).tree_id
        $result = [pscustomobject][ordered]@{
            schema_version = '1.0'; campaign_id = $campaign; run_id = 'run-list-1'; target_digest = $digest; harness_id = 'fixture'
            completion = 'complete'; verdict = $Verdict; runtime_outcome = 'completed'; termination_verified = $true; containment = 'verified'
            currentness = 'current'; validation = 'valid'; can_approve_current = ($Verdict -ceq 'pass'); summary = 'fixture'; findings = @($Findings)
            started_at = '2026-11-09T08:00:00Z'; ended_at = '2026-11-09T08:01:00Z'; duration_ms = 60000; examined_paths = @('src/app.ps1'); review_collected = $true
        }
        Request-ReviewAuthorityClaim -StoreRoot $store -CampaignId $campaign -RunId 'run-list-1' -TargetLineage $lineage -ObservedAt '2026-11-09T08:00:00Z' | Out-Null
        Publish-ReviewRunResultFact -StoreRoot $store -CampaignId $campaign -RunId 'run-list-1' -Fact $result | Out-Null
        Complete-ReviewAuthorityClaim -StoreRoot $store -CampaignId $campaign -RunId 'run-list-1' -TargetLineage $lineage -Disposition released -ObservedAt '2026-11-09T08:01:00Z' | Out-Null
        return [pscustomobject]@{ root = $root; store = $store }
    }

    function script:Get-Signoff([pscustomobject]$Project) {
        return Get-ContinuousCoReviewSignoffGateDecision -RepoRoot $Project.root -CampaignId $script:Campaign -TargetLineage 'lin-demo' `
            -CampaignStoreRoot $Project.store -FeatureId '001-demo' -IterationNumber '007'
    }
}

Describe 'the review sign-off names what the review leaves behind, finding by finding (FR-011, FR-013)' {
    It 'a non-gating finding of the reviewed head is listed as a follow-up, with id, title and where it is' {
        $project = script:New-ListProject -Name 'follow-up' -Verdict 'findings' -Findings @((script:New-Finding -Id 'finding-00000000000000f1' -Severity 'minor' -Title 'Typo in help text' -Location 'src/app.ps1:3'))
        $signoff = script:Get-Signoff -Project $project
        @(Get-ReviewCampaignOpenFindings -StoreRoot $project.store -CampaignId $script:Campaign).Count | Should -Be 0 -Because 'a minor never opens a finding'
        [string]$signoff.decision | Should -BeExactly 'allow' -Because 'a minor never blocks sign-off; it is listed instead'
        [string]$signoff.message | Should -Match 'follow-up'
        [string]$signoff.message | Should -Match 'finding-00000000000000f1'
        [string]$signoff.message | Should -Match 'Typo in help text'
        [string]$signoff.message | Should -Match 'src/app\.ps1:3'
    }

    It 'when the only blocking finding was demoted and the loop ends clean, the sign-off still names it, with the reviewer''s severity and why' {
        $project = script:New-ListProject -Name 'demoted-only' -Verdict 'findings' -Findings @((script:New-Finding -Id 'finding-00000000000000d1' -Severity 'minor' -Title 'Cache never invalidated' -Location 'src/cache.ps1:9' -Demoted))
        (Get-ReviewCampaignLoopState -StoreRoot $project.store -CampaignId $script:Campaign).ended_clean | Should -BeTrue -Because 'a demoted blocker opens no finding, so nothing stops the loop'
        $signoff = script:Get-Signoff -Project $project
        [string]$signoff.decision | Should -BeExactly 'allow'
        [string]$signoff.message | Should -Match 'finding-00000000000000d1'
        [string]$signoff.message | Should -Match 'Cache never invalidated'
        [string]$signoff.message | Should -Match 'src/cache\.ps1:9'
        [string]$signoff.message | Should -Match '(?i)reported (it )?as blocking'
        [string]$signoff.message | Should -Match '(?i)no concrete failure scenario'
    }

    It 'after stop the review here, each finding still open is named as not covered, with id, title and where it is' {
        $project = script:New-ListProject -Name 'stopped' -Verdict 'findings' -Findings @((script:New-Finding -Id 'finding-00000000000000b1' -Severity 'major' -Title 'Retry never backs off' -Location 'src/poll.ps1:41'))
        $decision = Resolve-ReviewCampaignPauseDecision -Findings @() -RoundsUsed 2 -BudgetTotal 2
        $stop = New-ReviewCampaignPendingPauseFact -CampaignId $script:Campaign -RunId 'run-list-stop' -TargetDigest ('a' * 40) -Decision $decision -ObservedAt '2026-11-09T08:05:00Z' -StopKind 'a-budget-spent' -StopReason 'budget-spent'
        $null = Write-ReviewCampaignPendingPauseFact -StoreRoot $project.store -Fact $stop
        $null = Write-ReviewCampaignPauseDecisionFact -StoreRoot $project.store -Fact (New-ReviewCampaignPauseDecisionFact -CampaignId $script:Campaign -RunId 'run-list-stop' -Choice stop-here -ObservedAt '2026-11-09T08:06:00Z')
        $signoff = script:Get-Signoff -Project $project
        [string]$signoff.message | Should -Match '(?i)not covered'
        [string]$signoff.message | Should -Match 'finding-00000000000000b1'
        [string]$signoff.message | Should -Match 'Retry never backs off'
        [string]$signoff.message | Should -Match 'src/poll\.ps1:41'
    }
}

Describe 'corrections to the sign-off listing (maintainer, 2026-11-09)' {
    It 'if the listing cannot be built, the sign-off refuses in plain words and says what could not be read' {
        $project = script:New-ListProject -Name 'listing-fails' -Verdict 'pass' -Findings @()
        Mock -CommandName Get-ReviewCampaignSignoffFindings -MockWith { throw 'review-store-corruption:result-unreadable:run-list-1' }
        $signoff = script:Get-Signoff -Project $project
        [string]$signoff.decision | Should -BeExactly 'block' -Because 'a sign-off that cannot list what the review leaves behind must not release'
        [string]$signoff.message | Should -Match '(?i)could not (read|list)'
        [string]$signoff.message | Should -Match 'result-unreadable'
    }

    It 'with a demoted finding, the clean route leads with the demotion, never with "found nothing that blocks"' {
        $project = script:New-ListProject -Name 'demoted-lead' -Verdict 'findings' -Findings @((script:New-Finding -Id 'finding-00000000000000d4' -Severity 'minor' -Title 'Cache never invalidated' -Location 'src/cache.ps1:9' -Demoted))
        $signoff = script:Get-Signoff -Project $project
        [string]$signoff.message | Should -Match '^The reviewer reported 1 blocking finding'
        [string]$signoff.message | Should -Match 'no concrete failure scenario'
        [string]$signoff.message | Should -Match 'Read (it|them) below before you approve'
        [string]$signoff.message | Should -Not -Match 'found nothing that blocks'
    }

    It 'without a demotion, the clean route keeps its wording' {
        $project = script:New-ListProject -Name 'plain-lead' -Verdict 'findings' -Findings @((script:New-Finding -Id 'finding-00000000000000f5' -Severity 'minor' -Title 'Typo' -Location 'src/app.ps1:2'))
        [string](script:Get-Signoff -Project $project).message | Should -Match '^Your review found nothing that blocks sign-off'
    }
}

Describe 'the sign-off listing is stored at the review-signoff crossing (correction 3, maintainer 2026-11-09; FR-013)' {
    It 'crossing review-signoff writes one file in the iteration folder naming each finding with id, title, location and severity' {
        $project = script:New-ListProject -Name 'stored' -Verdict 'findings' -WithLifecycle -Findings @(
            (script:New-Finding -Id 'finding-00000000000000f7' -Severity 'minor' -Title 'Typo in help text' -Location 'src/app.ps1:3'),
            (script:New-Finding -Id 'finding-00000000000000d7' -Severity 'minor' -Title 'Cache never invalidated' -Location 'src/cache.ps1:9' -Demoted))
        { Invoke-ContinuousCoReviewSignoffGateIfEnabled -ProjectRoot $project.root -BoundaryType 'review-signoff' } | Should -Not -Throw
        $path = Join-Path $project.root ('specs/001-demo/iterations/007/' + $script:ListingName)
        Test-Path -LiteralPath $path -PathType Leaf | Should -BeTrue -Because 'the listing is written once, at the crossing, into the iteration folder'
        $listing = Get-Content -LiteralPath $path -Raw | ConvertFrom-Json
        [string]$listing.feature_id | Should -BeExactly '001-demo'
        [string]$listing.iteration | Should -BeExactly '007'
        $followUp = @($listing.items | Where-Object { [string]$_.finding_id -ceq 'finding-00000000000000f7' })
        $followUp.Count | Should -Be 1
        [string]$followUp[0].kind | Should -BeExactly 'follow-up'
        [string]$followUp[0].title | Should -BeExactly 'Typo in help text'
        [string]$followUp[0].location | Should -BeExactly 'src/app.ps1:3'
        [string]$followUp[0].severity | Should -BeExactly 'minor'
        $demoted = @($listing.items | Where-Object { [string]$_.finding_id -ceq 'finding-00000000000000d7' })
        [string]$demoted[0].kind | Should -BeExactly 'demoted'
        [string]$demoted[0].severity | Should -BeExactly 'minor'
        [string]$demoted[0].demoted_from | Should -BeExactly 'blocking' -Because 'the reviewer''s own severity travels with the record'
    }

    It 'a clean review with nothing left behind still records an empty listing, so the retro can tell "nothing" from "not recorded"' {
        $project = script:New-ListProject -Name 'stored-empty' -Verdict 'pass' -WithLifecycle -Findings @()
        Invoke-ContinuousCoReviewSignoffGateIfEnabled -ProjectRoot $project.root -BoundaryType 'review-signoff' | Out-Null
        $listing = Get-Content -LiteralPath (Join-Path $project.root ('specs/001-demo/iterations/007/' + $script:ListingName)) -Raw | ConvertFrom-Json
        @($listing.items).Count | Should -Be 0
    }

    It 'a sign-off the gate refuses writes no listing: the crossing did not happen' {
        $project = script:New-ListProject -Name 'stored-refused' -Verdict 'findings' -WithLifecycle -Findings @(
            (script:New-Finding -Id 'finding-00000000000000b7' -Severity 'major' -Title 'Retry never backs off' -Location 'src/poll.ps1:41'))
        { Invoke-ContinuousCoReviewSignoffGateIfEnabled -ProjectRoot $project.root -BoundaryType 'review-signoff' } | Should -Throw
        Test-Path -LiteralPath (Join-Path $project.root ('specs/001-demo/iterations/007/' + $script:ListingName)) | Should -BeFalse
    }

    It 'signing off again after the listing is written still releases: the listing is a record, not reviewable content' {
        $project = script:New-ListProject -Name 'stored-twice' -Verdict 'findings' -WithLifecycle -Findings @(
            (script:New-Finding -Id 'finding-00000000000000f8' -Severity 'minor' -Title 'Typo' -Location 'src/app.ps1:2'))
        Invoke-ContinuousCoReviewSignoffGateIfEnabled -ProjectRoot $project.root -BoundaryType 'review-signoff' | Out-Null
        { Invoke-ContinuousCoReviewSignoffGateIfEnabled -ProjectRoot $project.root -BoundaryType 'review-signoff' } | Should -Not -Throw
    }

    It 'the crossing still emits nothing on the allow path (the boundary-sync result stays one object)' {
        $project = script:New-ListProject -Name 'stored-silent' -Verdict 'findings' -WithLifecycle -Findings @(
            (script:New-Finding -Id 'finding-00000000000000f9' -Severity 'minor' -Title 'Typo' -Location 'src/app.ps1:2'))
        $out = Invoke-ContinuousCoReviewSignoffGateIfEnabled -ProjectRoot $project.root -BoundaryType 'review-signoff'
        $out | Should -BeNullOrEmpty
    }

    It 'one writer: only Write-ReviewCampaignSignoffListing writes the file, and only the crossing calls it' {
        # Every engine script that names the file: the writer, and the records allowlist that classifies it as review
        # OUTPUT (FR-009) so storing it does not make the review it records look stale.
        $naming = @(Get-ChildItem -LiteralPath (Join-Path $script:RepoRoot 'scripts') -Recurse -Filter '*.ps1' |
                Where-Object { (Get-Content -LiteralPath $_.FullName -Raw) -match [regex]::Escape($script:ListingName) } | ForEach-Object { $_.Name } | Sort-Object)
        $naming | Should -Be @('review-signoff-evidence-gate.ps1', 'signoff-gate-wiring.ps1')
        $gate = Get-Content -LiteralPath (Join-Path $script:RepoRoot 'scripts/internal/continuous-co-review/review-signoff-evidence-gate.ps1') -Raw
        @([regex]::Matches($gate, [regex]::Escape($script:ListingName))).Count | Should -Be 1 -Because 'the gate only lists the name as a record'
        $callers = @(Get-ChildItem -LiteralPath (Join-Path $script:RepoRoot 'scripts'), (Join-Path $script:RepoRoot 'extensions') -Recurse -Filter '*.ps1' |
                ForEach-Object { [regex]::Matches((Get-Content -LiteralPath $_.FullName -Raw), '(?m)^(?!\s*function\s)(?!\s*#).*\bWrite-ReviewCampaignSignoffListing\b').Count } | Measure-Object -Sum).Sum
        $callers | Should -Be 1 -Because 'the review-signoff crossing is the one place the listing is written'
    }

    It 'the structured listing carries the severity of a finding still open' {
        $project = script:New-ListProject -Name 'structured-open' -Verdict 'findings' -Findings @(
            (script:New-Finding -Id 'finding-00000000000000b8' -Severity 'major' -Title 'Retry never backs off' -Location 'src/poll.ps1:41'))
        $items = @(Get-ReviewCampaignSignoffFindings -StoreRoot $project.store -CampaignId $script:Campaign)
        $open = @($items | Where-Object { [string]$_.kind -ceq 'not-covered' })
        $open.Count | Should -Be 1
        [string]$open[0].finding_id | Should -BeExactly 'finding-00000000000000b8'
        [string]$open[0].severity | Should -BeExactly 'major'
        [string]$open[0].location | Should -BeExactly 'src/poll.ps1:41'
    }
}

Describe 'the demotion lead reads the structured demoted_from, not the rendered line (maintainer, 2026-11-09)' {
    It 'a demoted finding whose own title reads "reported it as major;" still leads with the severity the reviewer used' {
        $project = script:New-ListProject -Name 'lead-structured' -Verdict 'findings' -Findings @(
            (script:New-Finding -Id 'finding-00000000000000d9' -Severity 'minor' -Title 'log says the probe reported it as major; nothing checks it' -Location 'src/probe.ps1:4' -Demoted))
        [string](script:Get-Signoff -Project $project).message | Should -Match '^The reviewer reported 1 blocking finding\.'
    }
}

Describe 'a review whose findings are all non-gating still covers the files after a records-only commit (cf2285d7''s sibling, FR-009)' {
    It 'recording review.md after a minor-only review does not ask for a fresh review: the sign-off still releases' {
        $project = script:New-ListProject -Name 'records-after-minor' -Verdict 'findings' -Findings @(
            (script:New-Finding -Id 'finding-00000000000000fa' -Severity 'minor' -Title 'Typo' -Location 'src/app.ps1:2'))
        [string](script:Get-Signoff -Project $project).decision | Should -BeExactly 'allow' -Because 'the exact-digest case released already (cf2285d7)'
        [IO.File]::WriteAllText((Join-Path $project.root 'specs/001-demo/iterations/007/review.md'), "# Review`n", $script:Utf8)
        script:Invoke-ListGit $project.root @('add', '-A'); script:Invoke-ListGit $project.root @('commit', '-qm', 'record the review')
        $signoff = script:Get-Signoff -Project $project
        [string]$signoff.decision | Should -BeExactly 'allow' -Because 'a record of what the review found cannot invalidate the review (FR-009)'
        [string]$signoff.message | Should -Match 'finding-00000000000000fa' -Because 'the follow-up is still listed'
    }

    It 'a gating finding is not released by a records-only commit: the exemption preserves, it never promotes' {
        $project = script:New-ListProject -Name 'records-after-major' -Verdict 'findings' -Findings @(
            (script:New-Finding -Id 'finding-00000000000000bb' -Severity 'major' -Title 'Retry never backs off' -Location 'src/poll.ps1:41'))
        [IO.File]::WriteAllText((Join-Path $project.root 'specs/001-demo/iterations/007/review.md'), "# Review`n", $script:Utf8)
        script:Invoke-ListGit $project.root @('add', '-A'); script:Invoke-ListGit $project.root @('commit', '-qm', 'record the review')
        [string](script:Get-Signoff -Project $project).decision | Should -BeExactly 'block'
    }
}
