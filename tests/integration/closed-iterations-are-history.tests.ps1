#requires -Version 7.0
Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

# W51 (2026-08-24, maintainer ruling): a review->repair->stale->review loop, live on the walk, costing
# a human approval per cycle. Three parts:
#
#   1. Navigator/validator DISAGREEMENT on staleness: the validator ruled that recording a review
#      cannot invalidate it; the gate's records-only exemption staled on the very records the review
#      had just measured. The FR-009 boundary is refined INSIDE specs/: standard artifacts (spec.md,
#      plan design content, tasks.md, workshop records) stale; execution records (state.md,
#      tasks-progress.yml, review.md, drift-log.md) do not. ONE classification, BOTH consumers.
#   2. The before-implement readiness gate blocked iteration 002 on iteration 001's deliberately
#      preserved FAIL. A closed iteration's recorded state is history, not a gate input - and closed
#      is decided by the iteration's OWN state.md, whether or not the index heard about it.
#   3. A closed iteration's records accepted a silent edit (a session reopened review.md to chase a
#      green validator, undoing an explicit preserved-state ruling). The W43 shape applied: sealed at
#      closeout, refused on drift with the reachable paths named.

BeforeAll {
    $script:RepoRoot = (Resolve-Path (Join-Path $PSScriptRoot '..\..')).Path
    . (Join-Path $script:RepoRoot 'extensions\specrew-speckit\scripts\shared-governance.ps1')
    . (Join-Path $script:RepoRoot 'scripts\internal\continuous-co-review\review-signoff-evidence-gate.ps1')
    $script:Validator = Join-Path $script:RepoRoot 'extensions\specrew-speckit\scripts\validate-governance.ps1'

    function script:New-TwoIterationProject {
        # The walk's shape: iteration 001 closed with a deliberately-preserved FAIL-bearing record,
        # iteration 002 active. start-context names the active feature so resolution works.
        $root = Join-Path ([IO.Path]::GetTempPath()) ('w51-' + [guid]::NewGuid().ToString('N'))
        foreach ($iter in @('001', '002')) {
            New-Item -ItemType Directory -Path (Join-Path $root "specs/001-fixture/iterations/$iter") -Force | Out-Null
        }
        New-Item -ItemType Directory -Path (Join-Path $root '.specrew') -Force | Out-Null
        $i1 = Join-Path $root 'specs/001-fixture/iterations/001'
        Set-Content -LiteralPath (Join-Path $i1 'state.md') -Value "# State`n`n**Current Phase**: iteration-closeout`n`nRETRO COMPLETE`n" -Encoding UTF8
        Set-Content -LiteralPath (Join-Path $i1 'review.md') -Value "# Review: Iteration 001`n`n**Overall Verdict**: accepted`n`nPreserved FAIL: the stale citation stays by ruling.`n" -Encoding UTF8
        $ctx = [ordered]@{
            schema = 'v2'
            session_state = [ordered]@{ active = $true; boundary_type = 'before-implement'; feature_ref = '001-fixture'; iteration_number = '002'; recorded_at = '2026-08-24T00:00:00Z' }
        }
        [IO.File]::WriteAllText((Join-Path $root '.specrew/start-context.json'), ($ctx | ConvertTo-Json -Depth 8), [Text.UTF8Encoding]::new($false))
        return $root
    }
}

Describe 'W51 part 1: one specs-tree classification, both consumers' {
    It 'execution records are records-only for the gate even when the caller passed no feature id' {
        # The live hole: a null FeatureId killed the allowlist, and the overlay excludes specs/, so
        # review.md, state.md and the progress sync staled the review that had just measured them.
        $root = New-TwoIterationProject
        try {
            Test-ReviewCampaignDeltaIsRecordsOnly -ChangedPaths @(
                'specs/001-fixture/iterations/002/review.md',
                'specs/001-fixture/iterations/002/state.md',
                'specs/001-fixture/iterations/002/tasks-progress.yml') -RepoRoot $root -FeatureId '' |
                Should -BeTrue -Because 'the active feature is lifecycle state the project already holds - resolve, do not require'
        }
        finally { Remove-Item -LiteralPath $root -Recurse -Force -ErrorAction SilentlyContinue }
    }

    It 'standard artifacts still stale the gate - the refinement is a boundary, not a blanket' {
        $root = New-TwoIterationProject
        try {
            foreach ($path in @('specs/001-fixture/spec.md', 'specs/001-fixture/plan.md', 'specs/001-fixture/tasks.md', 'specs/001-fixture/workshop/security-compliance.md')) {
                Test-ReviewCampaignDeltaIsRecordsOnly -ChangedPaths @($path) -RepoRoot $root -FeatureId '001-fixture' |
                    Should -BeFalse -Because "$path is the standard the code is judged against"
            }
        }
        finally { Remove-Item -LiteralPath $root -Recurse -Force -ErrorAction SilentlyContinue }
    }

    It 'the validator citation check answers from the SAME classification: spec.md stales, review.md does not' {
        # The disagreement that cost an approval per loop: both consumers now call one function.
        $root = New-TwoIterationProject
        try {
            & git -C $root init -q 2>&1 | Out-Null
            & git -C $root config user.email f@x.invalid; & git -C $root config user.name F
            & git -C $root add -A 2>&1 | Out-Null; & git -C $root commit -q -m base 2>&1 | Out-Null
            $treeA = (& git -C $root rev-parse 'HEAD^{tree}').Trim()
            Set-Content -LiteralPath (Join-Path $root 'specs/001-fixture/iterations/002/review.md') -Value "# Review recorded`n" -Encoding UTF8
            & git -C $root add -A 2>&1 | Out-Null; & git -C $root commit -q -m record 2>&1 | Out-Null
            $treeB = (& git -C $root rev-parse 'HEAD^{tree}').Trim()
            $recordsDrift = Get-SpecrewReviewedTreeSourceDrift -ProjectRoot $root -CitedTreeId $treeA -CurrentTreeId $treeB
            @($recordsDrift.source) | Should -BeNullOrEmpty -Because 'recording a review cannot invalidate the review - the validator ruling, now shared'

            Set-Content -LiteralPath (Join-Path $root 'specs/001-fixture/spec.md') -Value "# Spec changed`n" -Encoding UTF8
            & git -C $root add -A 2>&1 | Out-Null; & git -C $root commit -q -m spec 2>&1 | Out-Null
            $treeC = (& git -C $root rev-parse 'HEAD^{tree}').Trim()
            $standardDrift = Get-SpecrewReviewedTreeSourceDrift -ProjectRoot $root -CitedTreeId $treeB -CurrentTreeId $treeC
            @($standardDrift.source) | Should -Contain 'specs/001-fixture/spec.md' -Because 'changing the standard changes what the review concluded'
        }
        finally { Remove-Item -LiteralPath $root -Recurse -Force -ErrorAction SilentlyContinue }
    }
}

Describe 'W51 part 2: a closed iteration is history, not a gate input' {
    It 'ACCEPTANCE: the full-repo validator skips iteration 001 by its OWN state.md, no index needed' {
        $root = New-TwoIterationProject
        try {
            # Give both iterations a plan.md so both are candidate targets; 001 carries content that
            # would FAIL live validation, exactly like the preserved FAIL on the walk.
            Set-Content -LiteralPath (Join-Path $root 'specs/001-fixture/iterations/001/plan.md') -Value "# Plan`n`nStatus: bogus-enum`n" -Encoding UTF8
            $output = @(& pwsh -NoProfile -File $script:Validator -ProjectPath $root 2>&1 | ForEach-Object { [string]$_ }) -join "`n"
            $output | Should -Match 'closed-iteration filter: 1 closed iterations skipped'
        }
        finally { Remove-Item -LiteralPath $root -Recurse -Force -ErrorAction SilentlyContinue }
    }

    It '-IncludeClosed still reaches history on demand - skipping is a default, not a wall' {
        $root = New-TwoIterationProject
        try {
            Set-Content -LiteralPath (Join-Path $root 'specs/001-fixture/iterations/001/plan.md') -Value "# Plan`n" -Encoding UTF8
            $output = @(& pwsh -NoProfile -File $script:Validator -ProjectPath $root -IncludeClosed 2>&1 | ForEach-Object { [string]$_ }) -join "`n"
            $output | Should -Not -Match 'closed-iteration filter'
        }
        finally { Remove-Item -LiteralPath $root -Recurse -Force -ErrorAction SilentlyContinue }
    }
}

Describe 'W51 part 3: sealed history refuses silent edits' {
    It 'ACCEPTANCE: an edit to a sealed closed iteration FAILS validation naming the reachable paths' {
        $root = New-TwoIterationProject
        try {
            $i1 = Join-Path $root 'specs/001-fixture/iterations/001'
            $null = Write-SpecrewIterationSeal -IterationDirectory $i1 -Feature '001-fixture' -Iteration '001'
            # The walk's exact move: reopen the closed review.md to chase a green validator.
            Set-Content -LiteralPath (Join-Path $i1 'review.md') -Value "# Review: Iteration 001`n`n**Overall Verdict**: accepted`n`nEdited to look clean.`n" -Encoding UTF8
            $run = @(& pwsh -NoProfile -File $script:Validator -ProjectPath $root 2>&1 | ForEach-Object { [string]$_ }) -join "`n"
            $run | Should -Match 'closed-iteration-edited'
            $run | Should -Match 'review\.md'
            $run | Should -Match 'preserved history'
            $run | Should -Match 'drift entry in the ACTIVE iteration' -Because 'the refusal names paths that exist today; the governed supersede is beta4'
        }
        finally { Remove-Item -LiteralPath $root -Recurse -Force -ErrorAction SilentlyContinue }
    }

    It 'an untouched sealed iteration stays silent, and an unsealed closed iteration fails open' {
        $root = New-TwoIterationProject
        try {
            $i1 = Join-Path $root 'specs/001-fixture/iterations/001'
            $null = Write-SpecrewIterationSeal -IterationDirectory $i1 -Feature '001-fixture' -Iteration '001'
            $clean = @(& pwsh -NoProfile -File $script:Validator -ProjectPath $root 2>&1 | ForEach-Object { [string]$_ }) -join "`n"
            $clean | Should -Not -Match 'closed-iteration-edited'
            # Unsealed: remove the seal (a pre-seal closeout), edit freely, no refusal.
            Remove-Item -LiteralPath (Join-Path $i1 '.specrew-iteration-seal.json') -Force
            Add-Content -LiteralPath (Join-Path $i1 'review.md') -Value 'post-hoc note' -Encoding UTF8
            $open = @(& pwsh -NoProfile -File $script:Validator -ProjectPath $root 2>&1 | ForEach-Object { [string]$_ }) -join "`n"
            $open | Should -Not -Match 'closed-iteration-edited' -Because 'iterations closed before the seal existed are not refused for a check they never had'
        }
        finally { Remove-Item -LiteralPath $root -Recurse -Force -ErrorAction SilentlyContinue }
    }

    It 'a file ADDED to sealed history is drift too - history does not grow' {
        $root = New-TwoIterationProject
        try {
            $i1 = Join-Path $root 'specs/001-fixture/iterations/001'
            $null = Write-SpecrewIterationSeal -IterationDirectory $i1 -Feature '001-fixture' -Iteration '001'
            Set-Content -LiteralPath (Join-Path $i1 'late-addendum.md') -Value 'slipped in' -Encoding UTF8
            $state = Test-SpecrewIterationSealIntegrity -IterationDirectory $i1
            @($state.added) | Should -Contain 'late-addendum.md'
        }
        finally { Remove-Item -LiteralPath $root -Recurse -Force -ErrorAction SilentlyContinue }
    }
}
