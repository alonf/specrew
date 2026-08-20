#requires -Version 7.0
Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

# W29-W32 (2026-08-19/20): the review must SEE what it claims to have reviewed, and must not CLAIM
# more than it saw. All four came out of one measured walk (KeyContextAI, feature 001-layout-autocorrect)
# in which a "clean, independent review of the implementation" was recorded, and was none of those things.
#
# The walk, in order of causation:
#   W29 An agent noticed the reviewer lacked iteration scope and passed the iteration plan via
#       --design-context-ref - the documented "INCLUDE in the review request context" flag. The
#       resolver REPLACED the resolved context with it, so spec, design analysis and every contract
#       silently vanished. The reviewer's frame became one planning document.
#   W30 Nothing would have supplied that plan automatically: the resolver knew the finished-feature
#       spec but not the iteration's own scope, which is what made reaching for the flag necessary.
#   W32 The resulting run's `failure_reason` read "completed" - the classifier's verdict word landed
#       in a fault field, so the immutable record says a successful run failed with success.
#   W31 review.md then cited a `partial`/`incomplete` run as the evidence for a review claim, and
#       nothing checked the citation against the run it named.
#
# Written against the real resolver and the real validator, not mocks: three of these defects are
# defects OF the resolution and validation layers, so mocking them would assert the bug.

BeforeAll {
    $script:RepoRoot = (Resolve-Path (Join-Path $PSScriptRoot '..\..\..')).Path
    . (Join-Path $script:RepoRoot 'scripts\internal\continuous-co-review\review-design-context.ps1')

    # A project shaped like the walk's: a feature with a spec, an iteration carrying its own plan and
    # design analysis, and a contract. Enough for the resolver to have something to lose.
    function New-WalkShapedProject {
        $root = Join-Path ([IO.Path]::GetTempPath()) ('w29-' + [guid]::NewGuid().ToString('N'))
        $feature = '001-layout-autocorrect'
        $iter = Join-Path $root "specs/$feature/iterations/001"
        New-Item -ItemType Directory -Path $iter -Force | Out-Null
        New-Item -ItemType Directory -Path (Join-Path $root "specs/$feature/contracts") -Force | Out-Null
        Set-Content -LiteralPath (Join-Path $root "specs/$feature/spec.md") -Value '# Spec' -Encoding UTF8
        Set-Content -LiteralPath (Join-Path $iter 'plan.md') -Value '# Iteration plan' -Encoding UTF8
        Set-Content -LiteralPath (Join-Path $iter 'design-analysis.md') -Value '# Design analysis' -Encoding UTF8
        Set-Content -LiteralPath (Join-Path $root "specs/$feature/contracts/findings.schema.json") -Value '{}' -Encoding UTF8
        return [pscustomobject]@{ Root = $root; FeatureId = $feature }
    }
}

Describe 'W29/W30 what the reviewer is given to review against' {
    It 'adds an explicit design-context ref to the resolved frame instead of replacing it' {
        # The walk's exact command shape: one --design-context-ref naming the iteration plan.
        $p = New-WalkShapedProject
        try {
            $sel = Resolve-ContinuousCoReviewDesignContextSelection -RepoRoot $p.Root -FeatureId $p.FeatureId `
                -DesignContextFiles @("specs/$($p.FeatureId)/iterations/001/plan.md")
            $resolved = @($sel.resolved_refs)
            # Before the fix this was exactly 1 - the frame collapsed to the named file.
            $resolved.Count | Should -BeGreaterThan 1
            $resolved | Should -Contain "specs/$($p.FeatureId)/spec.md"
            $resolved | Should -Contain "specs/$($p.FeatureId)/iterations/001/design-analysis.md"
            @($sel.unresolved_refs).Count | Should -Be 0
        }
        finally { Remove-Item -LiteralPath $p.Root -Recurse -Force -ErrorAction SilentlyContinue }
    }

    It 'does not duplicate a ref that the resolver would have found anyway' {
        $p = New-WalkShapedProject
        try {
            $sel = Resolve-ContinuousCoReviewDesignContextSelection -RepoRoot $p.Root -FeatureId $p.FeatureId `
                -DesignContextFiles @("specs/$($p.FeatureId)/spec.md")
            @(@($sel.resolved_refs) | Where-Object { $_ -eq "specs/$($p.FeatureId)/spec.md" }).Count | Should -Be 1
        }
        finally { Remove-Item -LiteralPath $p.Root -Recurse -Force -ErrorAction SilentlyContinue }
    }

    It 'resolves the iteration plan on its own, so reaching for the flag is unnecessary' {
        # W30. The reason the walk's agent used --design-context-ref at all: without this, a slice is
        # reviewed against the finished-feature spec and never against the scope it was built to.
        $p = New-WalkShapedProject
        try {
            $sel = Resolve-ContinuousCoReviewDesignContextSelection -RepoRoot $p.Root -FeatureId $p.FeatureId
            @($sel.resolved_refs) | Should -Contain "specs/$($p.FeatureId)/iterations/001/plan.md"
        }
        finally { Remove-Item -LiteralPath $p.Root -Recurse -Force -ErrorAction SilentlyContinue }
    }
}

Describe 'W32 a fault field carries faults, not verdict words' {
    BeforeAll {
        . (Join-Path $script:RepoRoot 'scripts/internal/continuous-co-review/review-result-ingestor.ps1')
    }

    It 'records no failure_reason when a completed run merely declared partial coverage' {
        # The walk's real record: runtime_outcome 'completed', and failure_reason 'completed' beside it.
        # `$classification.reason` is the classifier's word for WHAT HAPPENED; routing it into a fault
        # field makes the immutable store say a successful run failed with success. Partiality is
        # already carried honestly by `completion` and `verdict`, which this asserts stay truthful.
        $store = Join-Path ([IO.Path]::GetTempPath()) ('w32s-' + [guid]::NewGuid().ToString('N'))
        $staging = Join-Path ([IO.Path]::GetTempPath()) ('w32g-' + [guid]::NewGuid().ToString('N'))
        try {
            $candidate = [pscustomobject][ordered]@{
                schema_version = '1.0'; run_id = 'run-one'; target_digest = 'digest-one'
                completion = 'partial'; verdict = 'incomplete'
                summary = 'Reviewed the changed files; could not reach the generated sources.'
                findings = @()
            }
            $paths = Initialize-ReviewRunStaging -StagingRoot $staging -CampaignId 'cmp-demo' -RunId 'run-one'
            [IO.File]::WriteAllText($paths.candidate_result_path, ($candidate | ConvertTo-Json -Depth 20 -Compress), [Text.UTF8Encoding]::new($false))
            $result = $p = @{
                StoreRoot = $store; StagingRoot = $staging; CampaignId = 'cmp-demo'; RunId = 'run-one'
                TargetDigest = 'digest-one'; HarnessId = 'fixture'; RuntimeOutcome = 'completed'
                Invoked = $true; TerminationVerified = $true; Containment = 'verified'; Currentness = 'current'
                StartedAt = '2026-08-19T00:00:00Z'; EndedAt = '2026-08-19T00:00:57Z'; DurationMs = 57000
            }
            $result = Invoke-ReviewResultIngress @p
            # Before the fix: 'completed'.
            [string]$result.result.failure_reason | Should -BeNullOrEmpty
            # The partiality itself must survive - suppressing the word must not suppress the truth.
            [string]$result.result.completion | Should -Be 'partial'
            [string]$result.result.verdict | Should -Be 'incomplete'
        }
        finally {
            Remove-Item -LiteralPath $store -Recurse -Force -ErrorAction SilentlyContinue
            Remove-Item -LiteralPath $staging -Recurse -Force -ErrorAction SilentlyContinue
        }
    }

    It 'still records a real fault when one occurred' {
        $store = Join-Path ([IO.Path]::GetTempPath()) ('w32s-' + [guid]::NewGuid().ToString('N'))
        $staging = Join-Path ([IO.Path]::GetTempPath()) ('w32g-' + [guid]::NewGuid().ToString('N'))
        try {
            $paths = Initialize-ReviewRunStaging -StagingRoot $staging -CampaignId 'cmp-demo' -RunId 'run-one'
            [IO.File]::WriteAllText($paths.candidate_result_path, 'not json at all', [Text.UTF8Encoding]::new($false))
            $result = $p = @{
                StoreRoot = $store; StagingRoot = $staging; CampaignId = 'cmp-demo'; RunId = 'run-one'
                TargetDigest = 'digest-one'; HarnessId = 'fixture'; RuntimeOutcome = 'completed'
                Invoked = $true; TerminationVerified = $true; Containment = 'verified'; Currentness = 'current'
                StartedAt = '2026-08-19T00:00:00Z'; EndedAt = '2026-08-19T00:00:57Z'; DurationMs = 57000
            }
            $result = Invoke-ReviewResultIngress @p
            [string]$result.result.failure_reason | Should -Not -BeNullOrEmpty
        }
        finally {
            Remove-Item -LiteralPath $store -Recurse -Force -ErrorAction SilentlyContinue
            Remove-Item -LiteralPath $staging -Recurse -Force -ErrorAction SilentlyContinue
        }
    }
}

Describe 'W31 a review record may not claim more than its cited run supports' {
    BeforeAll {
        # The validator is an ENTRY script (running it validates a project), so extract JUST the check via an
        # AST parse - no full validation run, no subprocess. Same pattern as boundary-reader-conformance.
                $script:W31ValidatorPath = Join-Path $script:RepoRoot 'extensions\specrew-speckit\scripts\validate-governance.ps1'
        $w31Tokens = $null; $w31Errors = $null
        $w31Ast = [System.Management.Automation.Language.Parser]::ParseFile($script:W31ValidatorPath, [ref]$w31Tokens, [ref]$w31Errors)
        $w31Fn = $w31Ast.FindAll({ param($n) ($n -is [System.Management.Automation.Language.FunctionDefinitionAst]) -and $n.Name -eq 'Test-ReviewCitedRunEvidence' }, $true) | Select-Object -First 1
        if (-not $w31Fn) { throw "Test-ReviewCitedRunEvidence not found in $script:W31ValidatorPath" }
        . ([scriptblock]::Create($w31Fn.Extent.Text))

        # A project holding one authority-store run plus a review.md that cites it.
        function script:New-CitedRunProject {
            param(
                [string]$Completion = 'complete', [string]$Verdict = 'pass',
                [string]$Currentness = 'current', [string]$Validation = 'valid',
                [switch]$OmitRun, [string]$ReviewBody,
                [object[]]$ExaminedPaths, [switch]$DeclareExamined
            )
            $root = Join-Path ([IO.Path]::GetTempPath()) ('w31-' + [guid]::NewGuid().ToString('N'))
            $runId = 'run-20260819-210747148-9bd5980b'
            if (-not $OmitRun) {
                $runDir = Join-Path $root ".specrew/review/authority/campaigns/cmp-w31/runs/$runId"
                New-Item -ItemType Directory -Path $runDir -Force | Out-Null
                $result = [ordered]@{
                    schema_version = '1.0'; campaign_id = 'cmp-w31'; run_id = $runId
                    completion = $Completion; verdict = $Verdict; currentness = $Currentness; validation = $Validation
                }
                if ($DeclareExamined) { $result['examined_paths'] = @($ExaminedPaths) }
                [IO.File]::WriteAllText((Join-Path $runDir 'result.json'), ($result | ConvertTo-Json -Depth 6 -Compress), [Text.UTF8Encoding]::new($false))
            }
            $body = if ($PSBoundParameters.ContainsKey('ReviewBody')) { $ReviewBody }
            else { "## Independent review`n`nThe independent review ($runId) found no review-blocking issues." }
            return [pscustomobject]@{ Root = $root; RunId = $runId; Lines = @($body -split "`n") }
        }
        function script:Invoke-CitedRunCheck {
            param([Parameter(Mandatory)]$Project)
            $errors = [System.Collections.Generic.List[string]]::new()
            try { Test-ReviewCitedRunEvidence -ReviewLines $Project.Lines -ProjectRoot $Project.Root -Errors $errors }
            finally { Remove-Item -LiteralPath $Project.Root -Recurse -Force -ErrorAction SilentlyContinue }
            return @($errors)
        }
    }

    It 'flags a review that cites a partial, incomplete run as its evidence' {
        # The measured KeyContextAI record: review.md presented run-20260819-210747148-9bd5980b as the
        # independent review; that run is completion 'partial', verdict 'incomplete'. Nothing checked.
        $found = @(Invoke-CitedRunCheck -Project (New-CitedRunProject -Completion 'partial' -Verdict 'incomplete'))
        $found.Count | Should -Be 1
        $found[0] | Should -Match 'run-20260819-210747148-9bd5980b'
        $found[0] | Should -Match "completion 'partial'"
    }

    It 'flags a citation of a stale or unvalidated run' {
        @(Invoke-CitedRunCheck -Project (New-CitedRunProject -Currentness 'stale')).Count | Should -Be 1
        @(Invoke-CitedRunCheck -Project (New-CitedRunProject -Validation 'invalid')).Count | Should -Be 1
    }

    It 'accepts a citation of a complete, current run - pass or findings alike' {
        # `findings` is a REVIEWED outcome, not a failed one. A review that cites the run which produced
        # its findings is doing exactly the right thing, and must not be nagged for it.
        @(Invoke-CitedRunCheck -Project (New-CitedRunProject -Verdict 'pass')).Count | Should -Be 0
        @(Invoke-CitedRunCheck -Project (New-CitedRunProject -Verdict 'findings')).Count | Should -Be 0
    }

    It 'stays silent when the review cites no run at all' {
        # Fail-open on absence is deliberate: this check exists to catch OVERSTATED citations, not to
        # make citation mandatory. Turning it into a citation requirement would add paperwork to every
        # review record for no evidentiary gain.
        $project = New-CitedRunProject -ReviewBody "## Review`n`nAll tasks verified against the plan."
        @(Invoke-CitedRunCheck -Project $project).Count | Should -Be 0
    }

    It 'stays silent when the cited run is not in this project store' {
        # A run id copied from another project, or a store pruned since - unknowable, so unjudged.
        @(Invoke-CitedRunCheck -Project (New-CitedRunProject -OmitRun)).Count | Should -Be 0
    }

    It 'flags a complete, passing run that declares it examined only records (W33)' {
        # The case W31 alone could not see. run-...211204294 was complete, current, valid and passing
        # by every stored fact, and had read a planning document. Now the run says what it read, and
        # a claim resting on it is measured against that.
        $found = @(Invoke-CitedRunCheck -Project (New-CitedRunProject -DeclareExamined -ExaminedPaths @(
                    'specs/001-layout-autocorrect/iterations/001/plan.md',
                    'specs/001-layout-autocorrect/iterations/001/review.md')))
        $found.Count | Should -Be 1
        $found[0] | Should -Match 'examined only records or documents'
    }

    It 'accepts a run that declares it examined source' {
        @(Invoke-CitedRunCheck -Project (New-CitedRunProject -DeclareExamined -ExaminedPaths @(
                    'src/DetectionEngine.cs', 'specs/001-x/spec.md'))).Count | Should -Be 0
    }

    It 'stays silent on a run that declared no coverage at all' {
        # Same fail-open posture as the rest of this check: it catches an overstated claim, it does
        # not make declaring coverage a condition of being cited.
        @(Invoke-CitedRunCheck -Project (New-CitedRunProject)).Count | Should -Be 0
    }
}
