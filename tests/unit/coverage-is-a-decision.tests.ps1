#requires -Version 7.0
Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

# W52 (2026-08-24, maintainer ruling): EXHAUSTION IS A DECISION, NOT A CONDITION. There is no
# situation of no-review without the human saying so. Chosen absence is honest; accumulated absence
# is the thing this release exists to prevent.
#
#   1. ONE decision stop when the allowance is exhausted AND source drift exists - typed decisions:
#      replenish (`approved for allowance reset`) / `continue without coverage until the review
#      phase` (recorded, so the signoff gate can distinguish deliberate deferral from nobody
#      noticing) / `hold implementation here`.
#   2. A standing coverage line in every re-entry packet: last delivered review, tree covered,
#      source files changed since, rounds remaining. The number climbing is its own alarm.

BeforeAll {
    $script:RepoRoot = (Resolve-Path (Join-Path $PSScriptRoot '..\..')).Path
    . (Join-Path $script:RepoRoot 'extensions\specrew-speckit\scripts\shared-governance.ps1')
    . (Join-Path $script:RepoRoot 'scripts\internal\bootstrap\HumanAuthorityStore.ps1')
    # Loaded at SCRIPT scope: a dot-source inside a function dies with the function's scope, and the
    # coverage state then silently skips drift on bundle-less fixtures - measured by this suite's own
    # first red.
    . (Join-Path $script:RepoRoot 'scripts\internal\continuous-co-review\reviewed-state-digest.ps1')

    function script:New-CoveredProject {
        param([switch]$WithBundle)
        $root = Join-Path ([IO.Path]::GetTempPath()) ('w52-' + [guid]::NewGuid().ToString('N'))
        New-Item -ItemType Directory -Path (Join-Path $root 'src') -Force | Out-Null
        New-Item -ItemType Directory -Path (Join-Path $root '.specrew') -Force | Out-Null
        Set-Content -LiteralPath (Join-Path $root 'src/app.ts') -Value 'export const a = 1;' -Encoding UTF8
        if ($WithBundle) {
            New-Item -ItemType Directory -Path (Join-Path $root 'scripts/internal') -Force | Out-Null
            Copy-Item -LiteralPath (Join-Path $script:RepoRoot 'scripts/internal/continuous-co-review') `
                -Destination (Join-Path $root 'scripts/internal/continuous-co-review') -Recurse -Force
        }
        & git -C $root init -q 2>&1 | Out-Null
        & git -C $root config user.email 'f@x.invalid'; & git -C $root config user.name 'F'
        & git -C $root add -A 2>&1 | Out-Null; & git -C $root commit -q -m base 2>&1 | Out-Null
        $covered = [string](Get-ContinuousCoReviewReviewedStateDigest -RepoRoot $root).tree_id
        $runDir = Join-Path $root '.specrew/review/authority/campaigns/cmp-fixture-i001/runs/run-20260824-000000001-aaaaaaaa'
        New-Item -ItemType Directory -Path $runDir -Force | Out-Null
        $result = [ordered]@{
            schema_version = '1.0'; campaign_id = 'cmp-fixture-i001'; run_id = 'run-20260824-000000001-aaaaaaaa'
            target_digest = $covered; harness_id = 'fx'; completion = 'complete'; verdict = 'pass'
            runtime_outcome = 'completed'; termination_verified = $true; containment = 'verified'
            currentness = 'current'; validation = 'valid'; can_approve_current = $true; failure_reason = $null
            summary = 's'; findings = @(); started_at = '2026-08-24T00:00:00Z'; ended_at = '2026-08-24T00:01:00Z'
            duration_ms = 60000; examined_paths = @('src/app.ts')
        }
        [IO.File]::WriteAllText((Join-Path $runDir 'result.json'), ($result | ConvertTo-Json -Depth 12), [Text.UTF8Encoding]::new($false))
        return [pscustomobject]@{ Root = $root; Covered = $covered }
    }
}

Describe 'W52 the coverage state answers the one question' {
    It 'zero source drift after the delivered review reads clean - planning is not uncovered work' {
        $f = New-CoveredProject
        try {
            # Records-only movement after the review: execution records do not count as drift.
            New-Item -ItemType Directory -Path (Join-Path $f.Root 'specs/001-x/iterations/001') -Force | Out-Null
            Set-Content -LiteralPath (Join-Path $f.Root 'specs/001-x/iterations/001/drift-log.md') -Value "# Drift`n" -Encoding UTF8
            & git -C $f.Root add -A 2>&1 | Out-Null; & git -C $f.Root commit -q -m records 2>&1 | Out-Null
            $state = Get-SpecrewReviewCoverageState -ProjectRoot $f.Root
            $state.available | Should -BeTrue
            $state.source_drift_count | Should -Be 0
        }
        finally { Remove-Item -LiteralPath $f.Root -Recurse -Force -ErrorAction SilentlyContinue }
    }

    It 'source drift counts, and the standing line carries run, tree, count' {
        $f = New-CoveredProject
        try {
            Set-Content -LiteralPath (Join-Path $f.Root 'src/new.ts') -Value 'export const b = 2;' -Encoding UTF8
            & git -C $f.Root add -A 2>&1 | Out-Null; & git -C $f.Root commit -q -m drift 2>&1 | Out-Null
            $state = Get-SpecrewReviewCoverageState -ProjectRoot $f.Root
            $state.source_drift_count | Should -Be 1
            $line = Get-SpecrewReviewCoverageLine -ProjectRoot $f.Root
            $line | Should -Match 'run-20260824-000000001-aaaaaaaa'
            $line | Should -Match '1 source file\(s\) changed since'
        }
        finally { Remove-Item -LiteralPath $f.Root -Recurse -Force -ErrorAction SilentlyContinue }
    }

    It 'rounds come from the ONE production counter when the bundle is present' {
        $f = New-CoveredProject -WithBundle
        try {
            $state = Get-SpecrewReviewCoverageState -ProjectRoot $f.Root
            $state.budget_total | Should -Be 4 -Because 'the default budget, resolved by the engine, never a parallel counter'
            $state.rounds_used | Should -Be 1
            $state.exhausted | Should -BeFalse
        }
        finally { Remove-Item -LiteralPath $f.Root -Recurse -Force -ErrorAction SilentlyContinue }
    }
}

Describe 'W52 the chosen-absence disposition' {
    It 'captures the typed deferral with the coverage state it was chosen against' {
        $f = New-CoveredProject
        try {
            $fact = Write-SpecrewCoverageDeferralAuthorization -ProjectRoot $f.Root -Response 'continue without coverage until the review phase' -HostKind 'claude' -SourceEvent 'UserPromptSubmit'
            $fact | Should -Not -BeNullOrEmpty
            [string]$fact.covered_tree_at_deferral | Should -Be $f.Covered -Because 'the deferral binds to the coverage state the human saw'
            (Get-SpecrewCoverageDeferralAuthorization -ProjectRoot $f.Root).verdict_text | Should -Be 'continue without coverage until the review phase'
        }
        finally { Remove-Item -LiteralPath $f.Root -Recurse -Force -ErrorAction SilentlyContinue }
    }

    It 'rejects questions, negations, and machinery envelopes' {
        foreach ($text in @('continue without coverage?', 'do not continue without coverage', '<system-reminder>continue without coverage</system-reminder>')) {
            (Test-SpecrewCoverageDeferralPhrase -Text $text).Matched | Should -BeFalse -Because $text
        }
        (Test-SpecrewCoverageDeferralPhrase -Text 'continue without coverage until the review phase').Matched | Should -BeTrue
    }
}

Describe 'W52 the decision stop and the packet line, wired' {
    It 'the stop fires only on exhaustion AND drift, silenced by a CURRENT deferral' {
        $provider = Get-Content -LiteralPath (Join-Path $script:RepoRoot 'extensions\specrew-speckit\scripts\specrew-conformance-provider.ps1') -Raw -Encoding UTF8
        $signal = [regex]::Match($provider, '(?s)\$coverageDecisionBlock = \$false.+?catch \{ \$coverageDecisionBlock = \$false \}').Value
        $signal | Should -Not -BeNullOrEmpty
        $signal.Contains('[bool]$coverageDecisionState.exhausted') | Should -BeTrue
        $signal.Contains('[int]$coverageDecisionState.source_drift_count -gt 0') | Should -BeTrue -Because 'exhaustion with zero source drift stays silent'
        $signal.Contains('covered_tree_at_deferral') | Should -BeTrue -Because 'a deferral against a superseded coverage state does not silence a new one'
        $provider | Should -Match "elseif \(\`$coverageDecisionBlock\) \{ 'coverage-decision' \}"
    }

    It 'the decision packet offers the three typed decisions, never numbered' {
        $provider = Get-Content -LiteralPath (Join-Path $script:RepoRoot 'extensions\specrew-speckit\scripts\specrew-conformance-provider.ps1') -Raw -Encoding UTF8
        # Anchored on the branch's own W52 comment - the advance-key branch shares the kind test.
        $block = [regex]::Match($provider, "(?s)elseif \(\`$blockKind -eq 'coverage-decision'\) \{\s*\r?\n\s*# W52.+?\r?\n            \}").Value
        $block | Should -Not -BeNullOrEmpty
        $block.Contains('`approved for allowance reset`') | Should -BeTrue
        $block.Contains('`continue without coverage until the review phase`') | Should -BeTrue
        $block.Contains('`hold implementation here`') | Should -BeTrue
        $block.Contains('never numbered') | Should -BeTrue
        $block.Contains('never record a decision on their behalf') | Should -BeTrue
    }

    It 'every packet source carries the standing coverage line' {
        $sync = Get-Content -LiteralPath (Join-Path $script:RepoRoot 'scripts\internal\sync-boundary-state.ps1') -Raw -Encoding UTF8
        $sync.Contains('Get-SpecrewReviewCoverageLine') | Should -BeTrue -Because 'boundary packets render from the pending-verdict artifact'
        $provider = Get-Content -LiteralPath (Join-Path $script:RepoRoot 'extensions\specrew-speckit\scripts\specrew-conformance-provider.ps1') -Raw -Encoding UTF8
        ([regex]::Matches($provider, [regex]::Escape('Get-SpecrewReviewCoverageLine'))).Count | Should -BeGreaterOrEqual 2 -Because 'material packets carry it too'
        $contract = Get-Content -LiteralPath (Join-Path $script:RepoRoot 'scripts\internal\launch-contract.ps1') -Raw -Encoding UTF8
        $contract.Contains('review-coverage line') | Should -BeTrue -Because 'the packet contract names it'
    }

    It 'the signoff gate names a recorded deferral, so chosen absence is not mistaken for unnoticed absence' {
        $gate = Get-Content -LiteralPath (Join-Path $script:RepoRoot 'scripts\internal\continuous-co-review\review-signoff-evidence-gate.ps1') -Raw -Encoding UTF8
        $gate.Contains('Get-SpecrewCoverageDeferralAuthorization') | Should -BeTrue
        $gate.Contains('the review phase is now, so the round is due') | Should -BeTrue
    }
}
