#requires -Version 7.0
Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

# W33 (2026-08-20): a complete code review must have examined code.
#
# Measured 2026-08-19/20 (KeyContextAI, feature 001-layout-autocorrect). Two runs recorded
# `pass`/`complete`/`current` with zero findings against a frozen target holding the whole
# implementation, and neither read any of it:
#
#   run-...210747148   186s  incomplete/partial  14 findings   <- walked the source
#   run-...211204294    57s  pass/complete        0 findings   <- read the iteration plan
#   run-...083412478    67s  pass/complete        0 findings   <- read governance artifacts
#
# The reviewer was HONEST every time. Both hollow runs described their own narrowness in the
# summary - "the frozen iteration 001 plan", "the frozen iteration artifacts" - and nothing
# consumed it, so a review of a planning document was recorded as the independent review of an
# implementation. Because a passing run becomes the baseline the next round advances from, every
# later round inherited the hollow one.
#
# W29/W30 stop the FRAME from collapsing. They do not make a hollow pass detectable, which is what
# this does: the candidate declares what it examined, and the controller checks that declaration
# against the target it froze. It catches the honest-but-misframed reviewer, which is the case that
# occurred; it does not pretend to catch a lying one.

BeforeAll {
    $script:RepoRoot = (Resolve-Path (Join-Path $PSScriptRoot '..\..\..')).Path
    . (Join-Path $script:RepoRoot 'scripts\internal\continuous-co-review\review-result-ingestor.ps1')

    function script:Invoke-CoverageIngress {
        param(
            [object[]]$ExaminedPaths,
            [bool]$TargetHasSource = $true,
            [string]$Completion = 'complete',
            [string]$Verdict = 'pass',
            [switch]$OmitExaminedPaths
        )
        $store = Join-Path ([IO.Path]::GetTempPath()) ('w33s-' + [guid]::NewGuid().ToString('N'))
        $staging = Join-Path ([IO.Path]::GetTempPath()) ('w33g-' + [guid]::NewGuid().ToString('N'))
        try {
            $candidate = [ordered]@{
                schema_version = '1.0'; run_id = 'run-one'; target_digest = 'digest-one'
                completion = $Completion; verdict = $Verdict
                summary = 'No review-blocking issues found in the frozen iteration 001 plan.'
                findings = @()
            }
            if (-not $OmitExaminedPaths) { $candidate['examined_paths'] = @($ExaminedPaths) }
            $paths = Initialize-ReviewRunStaging -StagingRoot $staging -CampaignId 'cmp-demo' -RunId 'run-one'
            [IO.File]::WriteAllText($paths.candidate_result_path, ($candidate | ConvertTo-Json -Depth 20 -Compress), [Text.UTF8Encoding]::new($false))
            $p = @{
                StoreRoot = $store; StagingRoot = $staging; CampaignId = 'cmp-demo'; RunId = 'run-one'
                TargetDigest = 'digest-one'; HarnessId = 'fixture'; RuntimeOutcome = 'completed'
                Invoked = $true; TerminationVerified = $true; Containment = 'verified'; Currentness = 'current'
                StartedAt = '2026-08-20T00:00:00Z'; EndedAt = '2026-08-20T00:00:57Z'; DurationMs = 57000
                TargetHasSource = $TargetHasSource
            }
            return Invoke-ReviewResultIngress @p
        }
        finally {
            Remove-Item -LiteralPath $store -Recurse -Force -ErrorAction SilentlyContinue
            Remove-Item -LiteralPath $staging -Recurse -Force -ErrorAction SilentlyContinue
        }
    }
}

Describe 'W33 the source classifier' {
    It 'treats anything unrecognised as source, so an unexpected language is never mistaken for paperwork' {
        foreach ($p in @('src/App.cs', 'Program.fs', 'tools/build.py', 'lib/x.rb', 'a/b/c.zig')) {
            Test-ReviewExaminedPathIsSource -Path $p | Should -BeTrue -Because "$p is source"
        }
    }

    It 'treats records and documents as not-source' {
        foreach ($p in @('specs/001-x/spec.md', 'specs/001-x/iterations/001/review.md', 'docs/guide.md',
                'README.md', '.specrew/config.yml', '.squad/team.md',
                '.github/copilot-instructions.md', '.github/skills/specrew-review/SKILL.md')) {
            Test-ReviewExaminedPathIsSource -Path $p | Should -BeFalse -Because "$p is a record or document"
        }
    }

    It 'treats an executable workflow as source, so declaring only CI is not declaring code coverage' {
        # Round-16 finding (DRIFT-199-I001-126): `.github/` was non-source wholesale here too, so a
        # review that declared it examined only workflows counted as having examined no source - the
        # mirror image of the records-only defect, in the coverage classifier that shares the rule.
        foreach ($p in @('.github/workflows/ci.yml', '.github/actions/setup/action.yml')) {
            Test-ReviewExaminedPathIsSource -Path $p | Should -BeTrue -Because "$p is executable"
        }
    }

    It 'strips a leading ./ without eating the dot of a dot-directory' {
        # `TrimStart('./')` trims those two CHARACTERS repeatedly, so '.specrew/config.yml' arrived as
        # 'specrew/config.yml' and a governance file classified as SOURCE - which would have made the
        # degrade silently unreachable for exactly the files the walk's hollow run examined. Caught by
        # running the classifier over real paths rather than by reading it.
        Test-ReviewExaminedPathIsSource -Path './src/App.cs' | Should -BeTrue
        Test-ReviewExaminedPathIsSource -Path '.specrew/config.yml' | Should -BeFalse
    }
}

Describe 'W33 a declared docs-only review cannot approve code' {
    It 'degrades a passing review that declares it examined only records' {
        # The walk's shape exactly: a clean pass whose declared coverage is the iteration plan.
        $r = Invoke-CoverageIngress -ExaminedPaths @(
            'specs/001-layout-autocorrect/iterations/001/plan.md',
            'specs/001-layout-autocorrect/iterations/001/review.md')
        [string]$r.result.completion | Should -Be 'partial'
        [string]$r.result.verdict | Should -Be 'incomplete'
        [bool]$r.result.can_approve_current | Should -BeFalse
        [string]$r.result.failure_reason | Should -Match 'REVIEW_EXAMINED_NO_SOURCE'
    }

    It 'leaves a review that examined source alone' {
        $r = Invoke-CoverageIngress -ExaminedPaths @('src/DetectionEngine.cs', 'specs/001-x/spec.md')
        [string]$r.result.completion | Should -Be 'complete'
        [string]$r.result.verdict | Should -Be 'pass'
        [string]$r.result.failure_reason | Should -BeNullOrEmpty
    }

    It 'does not degrade a docs-only review of a target that holds no source' {
        # A genuinely documentation-only target reviewed as documentation is a CORRECT review, and
        # degrading it would punish the honest case the rule exists to protect.
        $r = Invoke-CoverageIngress -ExaminedPaths @('docs/guide.md') -TargetHasSource $false
        [string]$r.result.completion | Should -Be 'complete'
        [string]$r.result.verdict | Should -Be 'pass'
    }

    It 'stays silent when the reviewer declared nothing' {
        # FAIL-OPEN ON ABSENCE. Every reviewer already deployed emits no examined_paths; failing
        # closed would wedge the signoff gate shut on every project in flight, which is worse than
        # the defect being fixed.
        $r = Invoke-CoverageIngress -OmitExaminedPaths
        [string]$r.result.completion | Should -Be 'complete'
        [string]$r.result.verdict | Should -Be 'pass'
        [string]$r.result.failure_reason | Should -BeNullOrEmpty
    }

    It 'degrades a PRESENT empty declaration on a source target - declared zero coverage is not silence' {
        # Round-11 blocking finding (DRIFT-199-I001-118), superseding the case that stood here: an
        # explicitly present examined_paths=[] mapped to declared=false, so a reviewer that honestly
        # reported opening NO files stayed complete/pass and could sign off code it never inspected.
        # A present empty list IS a declaration - of zero coverage. Only ABSENCE of the field keeps
        # the legacy fail-open above.
        $r = Invoke-CoverageIngress -ExaminedPaths @()
        [string]$r.result.completion | Should -Be 'partial'
        [string]$r.result.verdict | Should -Be 'incomplete'
        [bool]$r.result.can_approve_current | Should -BeFalse
        [string]$r.result.failure_reason | Should -Match 'REVIEW_EXAMINED_NO_SOURCE'
        [string]$r.result.failure_reason | Should -Match 'no files at all' -Because 'the empty case must not render an empty parenthetical list'
    }

    It 'an empty declaration against a target that holds no source stays a correct review' {
        # The docs-only-target carve-out applies the same way it does for a populated docs-only list.
        $r = Invoke-CoverageIngress -ExaminedPaths @() -TargetHasSource $false
        [string]$r.result.completion | Should -Be 'complete'
        [string]$r.result.verdict | Should -Be 'pass'
    }

    It 'carries the declared coverage into the terminal record' {
        # The projection is an explicit field list - the same one that once dropped the demotion
        # marks - so a field nobody names there reaches no reader at all.
        $r = Invoke-CoverageIngress -ExaminedPaths @('src/DetectionEngine.cs')
        @($r.result.examined_paths) | Should -Contain 'src/DetectionEngine.cs'
    }
}
