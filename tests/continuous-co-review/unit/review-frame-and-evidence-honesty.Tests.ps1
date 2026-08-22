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
        # W35 reads the derived block through Get-SpecrewEmbeddedIndependenceBlock, which the check
        # guards with Get-Command. Load the real module rather than stubbing it: without this the
        # guard silently skips the block path and the test passes while proving nothing.
        . (Join-Path $script:RepoRoot 'extensions\specrew-speckit\scripts\shared-governance.ps1')
        # W38 recomputes the current tree via Get-ContinuousCoReviewReviewedStateDigest, loading it
        # from the PROJECT when absent - which a governed project provides as part of its deployed
        # runtime, and a bare temp fixture does not. Loading it here is what a real project supplies,
        # and without it these cases would only ever exercise the fail-open path.
        . (Join-Path $script:RepoRoot 'scripts/internal/continuous-co-review/_load.ps1')
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
            # W35: evidence is DECLARED. The default body carries the marker, because a run id in a
            # sentence is narrative now and would assert nothing.
            $body = if ($PSBoundParameters.ContainsKey('ReviewBody')) { $ReviewBody }
            else { "## Independent review`n`n<!-- SPECREW-REVIEW-EVIDENCE: $runId -->`n`nThe independent review found no review-blocking issues." }
            return [pscustomobject]@{ Root = $root; RunId = $runId; Lines = @($body -split "`n") }
        }
        function script:New-ScaffoldFixture {
            # Shaped the way the scaffold actually reads a plan: a Requirement column, not Requirements.
            # A fixture that does not match the real shape proves nothing about the real path.
            param([switch]$WithQualifyingRun)
            $root = Join-Path ([IO.Path]::GetTempPath()) ('w35s-' + [guid]::NewGuid().ToString('N'))
            $iter = Join-Path $root (Join-Path 'specs' (Join-Path '001-thing' (Join-Path 'iterations' '001')))
            New-Item -ItemType Directory -Path $iter -Force | Out-Null
            Set-Content -LiteralPath (Join-Path $iter 'plan.md') -Encoding UTF8 -Value @(
                '# Iteration Plan', '', '## Tasks', '',
                '| Task | Requirement | Status | Effort | Owner |',
                '| --- | --- | --- | --- | --- |',
                '| T001 | FR-001 | done | 1 | src/** |')
            if ($WithQualifyingRun) {
                $runId = 'run-20260820-150735904-458c5888'
                $runDir = Join-Path $root (Join-Path '.specrew' (Join-Path 'review' (Join-Path 'authority' (Join-Path 'campaigns' (Join-Path 'cmp-a' (Join-Path 'runs' $runId))))))
                New-Item -ItemType Directory -Path $runDir -Force | Out-Null
                ([ordered]@{
                        schema_version = '1.0'; campaign_id = 'cmp-a'; run_id = $runId; harness_id = 'copilot-cli-file-primary'
                        completion = 'complete'; verdict = 'pass'; currentness = 'current'; validation = 'valid'
                        target_digest = '273c69bbabfb0044fc5b8b2a74fc65e739d1803f'; findings = @()
                        examined_paths = @('src/Engine.cs', 'src/Map.cs')
                    } | ConvertTo-Json -Depth 8 -Compress) | Set-Content -LiteralPath (Join-Path $runDir 'result.json') -Encoding UTF8
            }
            return [pscustomobject]@{ Root = $root; Iteration = $iter }
        }
        function script:Invoke-ReviewScaffold {
            param([Parameter(Mandatory)][string]$IterationDirectory)
            $scaffold = Join-Path $script:RepoRoot 'extensions/specrew-speckit/scripts/scaffold-review-artifact.ps1'
            & pwsh -NoProfile -ExecutionPolicy Bypass -File $scaffold -IterationDirectory $IterationDirectory *> $null
        }
        function script:Get-EmittedEvidenceMarker {
            # Three outcomes the string match could not tell apart: declared ids, an empty marker, or no
            # marker at all ($null).
            param([Parameter(Mandatory)][string]$IterationDirectory)
            $recordPath = Join-Path $IterationDirectory 'review.md'
            if (-not (Test-Path -LiteralPath $recordPath -PathType Leaf)) { return $null }
            $text = Get-Content -LiteralPath $recordPath -Raw -Encoding UTF8
            $pattern = '(?i)<!--\s*SPECREW-REVIEW-EVIDENCE\s*:(?<ids>[^>]*?)-->'
            $match = [regex]::Match($text, $pattern)
            if (-not $match.Success) { return $null }
            return [string]$match.Groups['ids'].Value
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

    # Measured 2026-08-20 at KeyContextAI's review-signoff boundary. The record rests on a clean 250s
    # run and PRESERVES a retraction naming the earlier partial run it wrongly relied on. The old check
    # scanned the whole document, could not tell reliance from retraction, and refused the record for
    # containing its own history - so its only available remedy was deleting the honesty it exists to
    # enforce. Second time a text-matching detector punished compliant output; W16 was the first.

    It 'accepts a record that leans on a clean run and names a partial one in a retraction' {
        # The real shape: the clean run declared, the failed run present only as narrative.
        $project = New-CitedRunProject -Verdict 'pass' -ReviewBody (@(
                '## Reviewer independence',
                '',
                '<!-- SPECREW-REVIEW-EVIDENCE: run-20260819-210747148-9bd5980b -->',
                '',
                'A valid independent campaign review of the code now exists.',
                '',
                'The history below is kept because the retraction it records must stay visible.',
                'An earlier revision claimed a valid independent review existed when none did:',
                'run-20260820-999999999-deadbeef returned incomplete/partial with 14 findings.') -join "`n")
        @(Invoke-CitedRunCheck -Project $project).Count | Should -Be 0
    }

    It 'STILL refuses a record that genuinely leans on a partial run' {
        # The half that matters more. Phrasing a weak citation as history must not launder it: what is
        # DECLARED is checked, whatever the surrounding prose says.
        $project = New-CitedRunProject -Completion 'partial' -Verdict 'incomplete' -ReviewBody (@(
                '## Reviewer independence',
                '',
                '<!-- SPECREW-REVIEW-EVIDENCE: run-20260819-210747148-9bd5980b -->',
                '',
                'Historical note only, nothing rests on this, purely narrative context.') -join "`n")
        $found = @(Invoke-CitedRunCheck -Project $project)
        $found.Count | Should -Be 1
        $found[0] | Should -Match "completion 'partial'"
    }

    It 'treats a run id that appears only in prose as narrative' {
        $project = New-CitedRunProject -Completion 'partial' -Verdict 'incomplete' -ReviewBody (@(
                '## Reviewer independence',
                '',
                'An earlier revision cited run-20260819-210747148-9bd5980b, which was wrong.') -join "`n")
        @(Invoke-CitedRunCheck -Project $project).Count | Should -Be 0
    }

    It 'checks the run the DERIVED block names, which no author chose' {
        # The block is computed from the store and recomputed at validation, so it is the one run id in
        # a record that cannot be authored. A record carrying it declares that run by construction.
        $project = New-CitedRunProject -Completion 'partial' -Verdict 'incomplete' -ReviewBody (@(
                '## Reviewer independence',
                '',
                '<!-- SPECREW-DERIVED-INDEPENDENT-REVIEW v1 -->',
                '- Run: run-20260819-210747148-9bd5980b (harness copilot-cli-file-primary)',
                '<!-- /SPECREW-DERIVED-INDEPENDENT-REVIEW -->') -join "`n")
        $found = @(Invoke-CitedRunCheck -Project $project)
        $found.Count | Should -Be 1
        $found[0] | Should -Match 'run-20260819-210747148-9bd5980b'
    }

    It 'checks the UNION, so declaring a run can only add scrutiny' {
        # Marker and block together. Naming something explicitly must never be a way to escape the
        # authoritative run.
        $project = New-CitedRunProject -Completion 'partial' -Verdict 'incomplete' -ReviewBody (@(
                '<!-- SPECREW-REVIEW-EVIDENCE: run-20260820-111111111-aaaaaaaa -->',
                '<!-- SPECREW-DERIVED-INDEPENDENT-REVIEW v1 -->',
                '- Run: run-20260819-210747148-9bd5980b (harness copilot-cli-file-primary)',
                '<!-- /SPECREW-DERIVED-INDEPENDENT-REVIEW -->') -join "`n")
        # The invented id is absent from the store and stays fail-open; the real one is still checked.
        $found = @(Invoke-CitedRunCheck -Project $project)
        $found.Count | Should -Be 1
        $found[0] | Should -Match 'run-20260819-210747148-9bd5980b'
    }

    It 'names only remedies that exist' {
        # The old message ended "or state in review.md what the cited run actually established", and no
        # code path implemented it - so a reader who followed the advice got the same refusal again.
        $project = New-CitedRunProject -Completion 'partial' -Verdict 'incomplete'
        $found = @(Invoke-CitedRunCheck -Project $project)
        $found.Count | Should -Be 1
        $found[0] | Should -Not -Match 'state in review\.md what the cited run actually established'
        $found[0] | Should -Match 'SPECREW-REVIEW-EVIDENCE'
    }


    It 'tells a block-sourced weak run only what it can actually do' {
        # The remedy must be one the READER can perform. The first version merged both sources into one
        # list of ids and then told everyone to "remove it from the SPECREW-REVIEW-EVIDENCE marker" -
        # which for a block-sourced run names an edit that is impossible (there is no marker) and
        # forbidden (the block is recomputed and must not be hand-edited). That is the painted-on-door
        # shape W35 had just fixed one layer up.
        $project = New-CitedRunProject -Completion 'partial' -Verdict 'incomplete' -ReviewBody (@(
                '## Reviewer independence',
                '',
                '<!-- SPECREW-DERIVED-INDEPENDENT-REVIEW v1 -->',
                '- Run: run-20260819-210747148-9bd5980b (harness copilot-cli-file-primary)',
                '<!-- /SPECREW-DERIVED-INDEPENDENT-REVIEW -->') -join "`n")
        $found = @(Invoke-CitedRunCheck -Project $project)
        $found.Count | Should -Be 1
        $found[0] | Should -Not -Match 'remove it from the SPECREW-REVIEW-EVIDENCE marker'
        $found[0] | Should -Match 'cannot be edited out by hand'
        $found[0] | Should -Match 'obtain a run that completed against the current tree'
    }

    It 'still offers the marker remedy when the run really is marker-sourced' {
        $project = New-CitedRunProject -Completion 'partial' -Verdict 'incomplete'
        $found = @(Invoke-CitedRunCheck -Project $project)
        $found.Count | Should -Be 1
        $found[0] | Should -Match 'remove it from the SPECREW-REVIEW-EVIDENCE marker'
    }

    It 'lets the block win when a run is named in both, since removing the marker would not help' {
        $project = New-CitedRunProject -Completion 'partial' -Verdict 'incomplete' -ReviewBody (@(
                '<!-- SPECREW-REVIEW-EVIDENCE: run-20260819-210747148-9bd5980b -->',
                '<!-- SPECREW-DERIVED-INDEPENDENT-REVIEW v1 -->',
                '- Run: run-20260819-210747148-9bd5980b (harness copilot-cli-file-primary)',
                '<!-- /SPECREW-DERIVED-INDEPENDENT-REVIEW -->') -join "`n")
        $found = @(Invoke-CitedRunCheck -Project $project)
        $found.Count | Should -Be 1
        $found[0] | Should -Not -Match 'remove it from the SPECREW-REVIEW-EVIDENCE marker'
    }

    It 'the evidence marker has a producer, so it is a control and not a comment' {
        # It shipped honoured by the validator and emitted by nothing, mentioned nowhere an agent reads.
        # No review record could declare its own evidence, so the union was always a union of one and
        # the authored half of the design never activated.
        #
        # BEHAVIOURAL, NOT A STRING MATCH. The first version of this pin grepped the scaffold source for
        # 'SPECREW-REVIEW-EVIDENCE' - which that file also contains at :305, in the COMMENT explaining
        # the emission - so deleting the emission at :348 left the test green. It asserted that the
        # source MENTIONS the marker, not that any record ever CARRIES one. So this runs the scaffold and
        # reads the record it produced.
        $project = New-ScaffoldFixture -WithQualifyingRun
        try {
            Invoke-ReviewScaffold -IterationDirectory $project.Iteration
            $declared = Get-EmittedEvidenceMarker -IterationDirectory $project.Iteration
            $null -eq $declared | Should -BeFalse -Because 'the scaffold must EMIT the marker, not merely mention it'
            ([string]$declared).Trim() | Should -Be 'run-20260820-150735904-458c5888' -Because 'and populate it with the run the record rests on'
        }
        finally { Remove-Item -LiteralPath $project.Root -Recurse -Force -ErrorAction SilentlyContinue }
    }

    It 'emits an EMPTY marker when no run qualifies, which declares nothing' {
        # Fail-open: a project with nothing to declare still gets the field, so an author can see it
        # exists, and an empty marker is exactly the prior behaviour.
        $project = New-ScaffoldFixture
        try {
            Invoke-ReviewScaffold -IterationDirectory $project.Iteration
            $declared = Get-EmittedEvidenceMarker -IterationDirectory $project.Iteration
            $null -eq $declared | Should -BeFalse -Because 'the marker is present even with nothing to declare'
            ([string]$declared).Trim() | Should -Be ''
        }
        finally { Remove-Item -LiteralPath $project.Root -Recurse -Force -ErrorAction SilentlyContinue }
    }

    It 'names the marker where an agent reads the record shape' {
        $guidance = Get-Content -LiteralPath (Join-Path $script:RepoRoot 'extensions/specrew-speckit/refocus/review-signoff.md') -Raw -Encoding UTF8
        $guidance | Should -Match 'SPECREW-REVIEW-EVIDENCE'
    }


    # `currentness` is a field the run wrote about the tree that existed THEN. It was computed at
    # ingest and never re-asked, so a record whose reviewed tree had since moved still validated
    # clean - which is how this project's own record kept reading as though a current independent
    # review covered it while three commits of review machinery landed after the reviewed tree.
    # The signoff gate catches that at the boundary; a record that reads clean in between is the
    # stored-fact-quietly-untrue shape W31 and W33 exist to stop.

    function script:New-GitBackedProject {
        # A REAL git repo, because the digest is computed from one. A fixture without git exercises
        # only the fail-open path and would prove nothing about the comparison.
        param([Parameter(Mandatory)][string]$CitedTreeId, [switch]$OmitEvidenceMarker)
        $root = Join-Path ([IO.Path]::GetTempPath()) ('w38-' + [guid]::NewGuid().ToString('N'))
        New-Item -ItemType Directory -Path (Join-Path $root 'src') -Force | Out-Null
        Set-Content -LiteralPath (Join-Path $root 'src/app.ps1') -Value '# one' -Encoding UTF8
        Push-Location $root
        try {
            & git init --quiet 2>&1 | Out-Null
            & git add -A 2>&1 | Out-Null
            & git -c user.email='t@t' -c user.name='t' commit -m init --quiet 2>&1 | Out-Null
        }
        finally { Pop-Location }
        $runId = 'run-20260821-104557253-97c3785a'
        $runDir = Join-Path $root (Join-Path '.specrew' (Join-Path 'review' (Join-Path 'authority' (Join-Path 'campaigns' (Join-Path 'cmp-w38' (Join-Path 'runs' $runId))))))
        New-Item -ItemType Directory -Path $runDir -Force | Out-Null
        ([ordered]@{
                schema_version = '1.0'; campaign_id = 'cmp-w38'; run_id = $runId
                completion = 'complete'; verdict = 'pass'; currentness = 'current'; validation = 'valid'
                target_digest = $CitedTreeId
            } | ConvertTo-Json -Depth 6 -Compress) | Set-Content -LiteralPath (Join-Path $runDir 'result.json') -Encoding UTF8
        $body = if ($OmitEvidenceMarker) { @('## Review', '', 'No run is cited here.') }
        else { @('## Review', '', "<!-- SPECREW-REVIEW-EVIDENCE: $runId -->", '', 'Rests on the run above.') }
        return [pscustomobject]@{ Root = $root; Lines = @($body) }
    }
    function script:CheckProject {
        param([Parameter(Mandatory)]$Project)
        $errors = [System.Collections.Generic.List[string]]::new()
        try { Test-ReviewCitedRunEvidence -ReviewLines $Project.Lines -ProjectRoot $Project.Root -Errors $errors }
        finally { Remove-Item -LiteralPath $Project.Root -Recurse -Force -ErrorAction SilentlyContinue }
        return @($errors)
    }
    function script:Get-CurrentTreeId {
        param([Parameter(Mandatory)][string]$Root)
        $state = Get-ContinuousCoReviewReviewedStateDigest -RepoRoot $Root
        if ($null -eq $state -or -not [bool]$state.ok) { return '' }
        return [string]$state.tree_id
    }

    It 'refuses a run whose reviewed tree is not the tree that exists now' {
        # The stored field says `current`; the trees disagree. The trees win.
        #
        # DRIFT-007 refined WHICH disagreement counts - a run stays current while only records have
        # moved - so this fixture's invented tree id now lands in the branch it always actually was:
        # `deadbeef...` is not an object in the repository, so nothing can be established about what
        # changed between the two trees. Still a refusal, and the assertion now names the reason
        # instead of a phrase, so a future change to the wording does not read as a behaviour change.
        $found = @(CheckProject -Project (New-GitBackedProject -CitedTreeId 'deadbeefdeadbeefdeadbeefdeadbeefdeadbeef'))
        $found.Count | Should -Be 1
        $found[0] | Should -Match 'it reviewed tree deadbeef'
        $found[0] | Should -Match 'the files now are tree'
        $found[0] | Should -Match 'no longer in this repository''s object store'
    }

    It 'accepts a run whose reviewed tree IS the tree that exists now' {
        # The fix must not refuse a genuinely current run - that would make every record unpassable.
        $project = New-GitBackedProject -CitedTreeId 'placeholder'
        try {
            $actual = Get-CurrentTreeId -Root $project.Root
            $actual | Should -Not -BeNullOrEmpty -Because 'the fixture must be a real repo for this to mean anything'
            $runPath = Join-Path $project.Root (Join-Path '.specrew' (Join-Path 'review' (Join-Path 'authority' (Join-Path 'campaigns' (Join-Path 'cmp-w38' (Join-Path 'runs' (Join-Path 'run-20260821-104557253-97c3785a' 'result.json')))))))
            $result = Get-Content -LiteralPath $runPath -Raw -Encoding UTF8 | ConvertFrom-Json
            $result.target_digest = $actual
            ($result | ConvertTo-Json -Depth 6 -Compress) | Set-Content -LiteralPath $runPath -Encoding UTF8
            $errors = [System.Collections.Generic.List[string]]::new()
            Test-ReviewCitedRunEvidence -ReviewLines $project.Lines -ProjectRoot $project.Root -Errors $errors
            @($errors).Count | Should -Be 0
        }
        finally { Remove-Item -LiteralPath $project.Root -Recurse -Force -ErrorAction SilentlyContinue }
    }

    It 'claims nothing when the current tree cannot be computed' {
        # FAIL-OPEN: "I could not tell" must never manufacture staleness. A project with no git repo
        # cannot yield a digest, and the check must stay silent rather than refuse everything.
        $root = Join-Path ([IO.Path]::GetTempPath()) ('w38ng-' + [guid]::NewGuid().ToString('N'))
        $runId = 'run-20260821-104557253-97c3785a'
        $runDir = Join-Path $root (Join-Path '.specrew' (Join-Path 'review' (Join-Path 'authority' (Join-Path 'campaigns' (Join-Path 'cmp-w38' (Join-Path 'runs' $runId))))))
        New-Item -ItemType Directory -Path $runDir -Force | Out-Null
        try {
            ([ordered]@{
                    schema_version = '1.0'; campaign_id = 'cmp-w38'; run_id = $runId
                    completion = 'complete'; verdict = 'pass'; currentness = 'current'; validation = 'valid'
                    target_digest = 'deadbeefdeadbeefdeadbeefdeadbeefdeadbeef'
                } | ConvertTo-Json -Depth 6 -Compress) | Set-Content -LiteralPath (Join-Path $runDir 'result.json') -Encoding UTF8
            $errors = [System.Collections.Generic.List[string]]::new()
            Test-ReviewCitedRunEvidence -ReviewLines @('## Review', '', "<!-- SPECREW-REVIEW-EVIDENCE: $runId -->") -ProjectRoot $root -Errors $errors
            @($errors).Count | Should -Be 0
        }
        finally { Remove-Item -LiteralPath $root -Recurse -Force -ErrorAction SilentlyContinue }
    }

}
