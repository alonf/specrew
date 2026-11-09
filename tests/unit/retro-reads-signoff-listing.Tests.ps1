#requires -Version 7.0
# Feature 203 T008, correction 3 (DRIFT-052, maintainer 2026-11-09; FR-013): the follow-ups are stored. At the
# review-signoff crossing one writer stores what the review leaves behind (not covered, follow-ups, demoted; each with id,
# title, location and severity) in review-signoff-listing.json in the iteration folder, and the retro reads it. The retro
# scaffold names every item; it says so when no listing was recorded, says so when the review left nothing behind, and
# refuses in plain words when the listing cannot be read, rather than scaffolding a retro that silently drops it.

BeforeAll {
    $script:RepoRoot = Split-Path -Parent (Split-Path -Parent $PSScriptRoot)
    $script:Scaffold = Join-Path $script:RepoRoot 'extensions/specrew-speckit/scripts/scaffold-retro-artifact.ps1'
    $script:Utf8 = [Text.UTF8Encoding]::new($false)

    # An iteration whose review is accepted, the inputs the retro scaffold requires, and optionally a stored listing.
    function script:New-RetroIteration([string]$Name, [AllowNull()][string]$ListingJson) {
        $dir = Join-Path $TestDrive "$Name/specs/001-demo/iterations/007"
        New-Item -ItemType Directory -Path $dir -Force | Out-Null
        [IO.File]::WriteAllText((Join-Path $dir 'plan.md'), "# Iteration Plan: 007`n`n## Tasks`n`n| Task | Effort | Actual |`n| ---- | ------ | ------ |`n| T001 | 2 | 3 |`n", $script:Utf8)
        [IO.File]::WriteAllText((Join-Path $dir 'state.md'), "# State`n", $script:Utf8)
        [IO.File]::WriteAllText((Join-Path $dir 'drift-log.md'), "# Drift Log`n", $script:Utf8)
        [IO.File]::WriteAllText((Join-Path $dir 'review.md'), "# Review`n`n**Overall Verdict**: accepted`n`n## Task Verdicts`n`n| Task | Verdict | Notes |`n| ---- | ------- | ----- |`n| T001 | pass | Delivered and reviewed. |`n", $script:Utf8)
        if ($null -ne $ListingJson) { [IO.File]::WriteAllText((Join-Path $dir 'review-signoff-listing.json'), $ListingJson, $script:Utf8) }
        return $dir
    }

    function script:Invoke-RetroScaffold([string]$Directory) {
        $output = & pwsh -NoProfile -File $script:Scaffold -IterationDirectory $Directory -RetroDate '2026-11-09' 2>&1 | Out-String
        $retro = Join-Path $Directory 'retro.md'
        return [pscustomobject]@{
            output = $output
            retro  = $(if (Test-Path -LiteralPath $retro) { Get-Content -LiteralPath $retro -Raw } else { $null })
        }
    }

    $script:Listing = ([ordered]@{
            schema_version = '1.0'; feature_id = '001-demo'; iteration = '007'; campaign_id = 'cmp-001-demo-i007'; run_id = 'run-list-1'
            decision = 'complete-current-follow-ups-only'; recorded_at = '2026-11-09T20:00:00+00:00'
            items = @(
                [ordered]@{ kind = 'not-covered'; finding_id = 'finding-00000000000000b1'; title = 'Retry never backs off'; location = 'src/poll.ps1:41'; severity = 'major'; demoted_from = '' },
                [ordered]@{ kind = 'follow-up'; finding_id = 'finding-00000000000000f1'; title = 'Typo in help text'; location = 'src/app.ps1:3'; severity = 'minor'; demoted_from = '' },
                [ordered]@{ kind = 'demoted'; finding_id = 'finding-00000000000000d1'; title = 'Cache never invalidated'; location = 'src/cache.ps1:9'; severity = 'minor'; demoted_from = 'blocking' })
        } | ConvertTo-Json -Depth 6)
}

Describe 'the retro reads the sign-off listing stored at the review-signoff crossing (correction 3; FR-013)' {
    It 'names each item the review left behind, with id, title, location and severity' {
        $run = script:Invoke-RetroScaffold -Directory (script:New-RetroIteration -Name 'listed' -ListingJson $script:Listing)
        $run.retro | Should -Not -BeNullOrEmpty -Because $run.output
        $run.retro | Should -Match '## What the Review Left Behind'
        $run.retro | Should -Match ([regex]::Escape('Not covered (still open): finding-00000000000000b1 (major) Retry never backs off at src/poll.ps1:41'))
        $run.retro | Should -Match ([regex]::Escape('Follow-up: finding-00000000000000f1 (minor) Typo in help text at src/app.ps1:3'))
        $run.retro | Should -Match ([regex]::Escape('Demoted: finding-00000000000000d1 Cache never invalidated at src/cache.ps1:9 - the reviewer reported it as blocking; it was recorded as minor'))
    }

    It 'says so when the review left nothing behind' {
        $empty = ([ordered]@{ schema_version = '1.0'; feature_id = '001-demo'; iteration = '007'; campaign_id = 'cmp-001-demo-i007'; run_id = 'run-list-1'; decision = 'complete-current-clean-result'; recorded_at = '2026-11-09T20:00:00+00:00'; items = @() } | ConvertTo-Json -Depth 6)
        $run = script:Invoke-RetroScaffold -Directory (script:New-RetroIteration -Name 'empty' -ListingJson $empty)
        $run.retro | Should -Match '## What the Review Left Behind'
        $run.retro | Should -Match 'The review left nothing behind'
    }

    It 'says so when no listing was recorded, rather than implying the review left nothing' {
        $run = script:Invoke-RetroScaffold -Directory (script:New-RetroIteration -Name 'absent' -ListingJson $null)
        $run.retro | Should -Match '## What the Review Left Behind'
        $run.retro | Should -Match 'No sign-off listing was recorded for this iteration'
        $run.retro | Should -Not -Match 'The review left nothing behind'
    }

    It 'refuses in plain words when the listing cannot be read, and writes no retro that drops it' {
        $dir = script:New-RetroIteration -Name 'unreadable' -ListingJson '{ "items": [ { "kind": '
        $run = script:Invoke-RetroScaffold -Directory $dir
        $run.retro | Should -BeNullOrEmpty
        $run.output | Should -Match 'review-signoff-listing\.json'
        $run.output | Should -Match '(?i)could not read'
    }
}
