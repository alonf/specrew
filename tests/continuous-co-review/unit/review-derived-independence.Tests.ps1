#requires -Version 7.0
Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

# W34-A (2026-08-20): the independence claim is derived from the store; the judgement around it is not.
#
# The KeyContextAI falsity was one sentence - "the independent review ran and passed against this exact
# tree" - and it is entirely a function of the authority store, so nothing should be writing it by hand.
# The per-task verdicts are NOT derivable and stay authored: a campaign result carries verdict,
# completion, findings, summary and examined_paths, nothing that reconstructs a row citing two live
# observations and an exact contract-violation string. Deriving that table from a run that never saw the
# tasks would trade a false independence claim for a false evidence table.
#
# Integrity is recomputation, not trust in the writer: anything may emit the block, and the validator
# derives it again and refuses a mismatch.

BeforeAll {
    $script:RepoRoot = (Resolve-Path (Join-Path $PSScriptRoot '..\..\..')).Path
    . (Join-Path $script:RepoRoot 'extensions\specrew-speckit\scripts\shared-governance.ps1')

    $t = $null; $e = $null
    $ast = [System.Management.Automation.Language.Parser]::ParseFile(
        (Join-Path $script:RepoRoot 'extensions\specrew-speckit\scripts\validate-governance.ps1'), [ref]$t, [ref]$e)
    $fn = $ast.FindAll({ param($n) $n -is [System.Management.Automation.Language.FunctionDefinitionAst] -and
            $n.Name -eq 'Test-ReviewDerivedIndependenceBlock' }, $true) | Select-Object -First 1
    if (-not $fn) { throw 'Test-ReviewDerivedIndependenceBlock not found' }
    . ([scriptblock]::Create($fn.Extent.Text))

    # Extract the REAL warning writer rather than stubbing it. A stub would let the warn path pass
    # even if the real writer threw, which is the shape this project keeps finding.
    $warnFn = $ast.FindAll({ param($n) $n -is [System.Management.Automation.Language.FunctionDefinitionAst] -and
            $n.Name -eq 'Write-TrustHardeningWarning' }, $true) | Select-Object -First 1
    if (-not $warnFn) { throw 'Write-TrustHardeningWarning not found' }
    . ([scriptblock]::Create($warnFn.Extent.Text))
    $script:ValidatorSoftWarnings = 0

    function script:New-RecordProject {
        # A project holding a real review.md at a governed iteration path, so the authorship reader can
        # key on it. The store shape comes from New-StoreProject.
        param([switch]$Observed, [switch]$NoRun)
        $root = if ($NoRun) { New-StoreProject -NoRun } else { New-StoreProject -DeclareExamined -ExaminedPaths @('src/Engine.cs') }
        $iterDir = Join-Path $root 'specs/001-thing/iterations/001'
        New-Item -ItemType Directory -Path $iterDir -Force | Out-Null
        Set-Content -LiteralPath (Join-Path $iterDir 'review.md') -Encoding UTF8 -Value @(
            '# Review: Iteration 001', '', 'An independent review found no substantive defects.')
        if ($Observed) {
            # What a record written after W34-A landed carries by construction.
            # W37: an observation must state HOW the turn was attributed, or it mints nothing. This
            # fixture models a record whose authorship WAS observed, so it says exact-turn.
            Write-SpecrewReviewAuthorshipObservation -ProjectRoot $root -HostKind 'claude' -SessionId 'sess-x' `
                -AttributionMode 'exact-turn' -ChangedPaths @('specs/001-thing/iterations/001/review.md')
        }
        return [pscustomobject]@{ Root = $root; IterationDirectory = $iterDir }
    }
    function script:CheckRecord {
        param([Parameter(Mandatory)]$Project, [string[]]$Lines)
        if (-not $Lines) { $Lines = @(Get-Content -LiteralPath (Join-Path $Project.IterationDirectory 'review.md') -Encoding UTF8) }
        $errors = [System.Collections.Generic.List[string]]::new()
        $before = $script:ValidatorSoftWarnings
        Test-ReviewDerivedIndependenceBlock -ReviewLines $Lines -ProjectRoot $Project.Root `
            -IterationDirectory $Project.IterationDirectory -Errors $errors
        return [pscustomobject]@{ errors = @($errors); warnings = ($script:ValidatorSoftWarnings - $before) }
    }

    function script:New-StoreProject {
        param(
            [string]$Completion = 'complete', [string]$Verdict = 'pass',
            [string]$Currentness = 'current', [string]$Validation = 'valid',
            [object[]]$ExaminedPaths, [switch]$DeclareExamined, [switch]$NoRun,
            [string]$RunId = 'run-20260820-083412478-d85dda20'
        )
        $root = Join-Path ([IO.Path]::GetTempPath()) ('w34a-' + [guid]::NewGuid().ToString('N'))
        New-Item -ItemType Directory -Path $root -Force | Out-Null
        if (-not $NoRun) {
            $runDir = Join-Path $root ".specrew/review/authority/campaigns/cmp-a/runs/$RunId"
            New-Item -ItemType Directory -Path $runDir -Force | Out-Null
            $result = [ordered]@{
                schema_version = '1.0'; campaign_id = 'cmp-a'; run_id = $RunId; harness_id = 'copilot-cli-file-primary'
                completion = $Completion; verdict = $Verdict; currentness = $Currentness; validation = $Validation
                target_digest = 'b64dbee0fc94b608be2dc32d19871c010632e6be'; findings = @()
            }
            if ($DeclareExamined) { $result['examined_paths'] = @($ExaminedPaths) }
            [IO.File]::WriteAllText((Join-Path $runDir 'result.json'), ($result | ConvertTo-Json -Depth 8 -Compress), [Text.UTF8Encoding]::new($false))
        }
        return $root
    }
    function script:CheckBlock {
        param([Parameter(Mandatory)][string]$Root, [Parameter(Mandatory)][string]$Block)
        $errors = [System.Collections.Generic.List[string]]::new()
        Test-ReviewDerivedIndependenceBlock -ReviewLines @($Block -split "`n") -ProjectRoot $Root -Errors $errors
        return @($errors)
    }
}

Describe 'W34-A deriving the independence claim' {
    It 'names the qualifying run and the tree it reviewed' {
        $root = New-StoreProject -DeclareExamined -ExaminedPaths @('src/Engine.cs', 'src/Map.cs')
        try {
            $block = Get-SpecrewDerivedIndependenceBlock -ProjectRoot $root
            $block | Should -Match 'run-20260820-083412478-d85dda20'
            $block | Should -Match 'b64dbee0'
            $block | Should -Match '2 source path\(s\) of 2 declared'
        }
        finally { Remove-Item -LiteralPath $root -Recurse -Force -ErrorAction SilentlyContinue }
    }

    It 'says coverage is UNKNOWN for a run that predates the declared-coverage contract' {
        # Derived from the real KeyContextAI store this names run-...083412478 - the 67-second run that
        # read governance artifacts. Such a run stays eligible so the gate does not wedge shut on the
        # past, so the block must LABEL it rather than lend it derived authority.
        $root = New-StoreProject
        try {
            $block = Get-SpecrewDerivedIndependenceBlock -ProjectRoot $root
            $block | Should -Match 'Coverage: UNKNOWN'
            $block | Should -Match 'evidence that a review RAN, not evidence'
        }
        finally { Remove-Item -LiteralPath $root -Recurse -Force -ErrorAction SilentlyContinue }
    }

    It 'refuses to count a run whose declared coverage holds no source' {
        $root = New-StoreProject -DeclareExamined -ExaminedPaths @('specs/001-x/iterations/001/plan.md')
        try {
            Get-SpecrewDerivedIndependenceBlock -ProjectRoot $root |
                Should -Match 'No run in this project'
        }
        finally { Remove-Item -LiteralPath $root -Recurse -Force -ErrorAction SilentlyContinue }
    }

    It 'says so plainly when nothing qualifies' {
        foreach ($project in @(
                (New-StoreProject -NoRun),
                (New-StoreProject -Completion 'partial' -Verdict 'incomplete'),
                (New-StoreProject -Currentness 'stale'),
                (New-StoreProject -Validation 'invalid'))) {
            try {
                $block = Get-SpecrewDerivedIndependenceBlock -ProjectRoot $project
                $block | Should -Match 'No run in this project'
                $block | Should -Match 'must say what'
            }
            finally { Remove-Item -LiteralPath $project -Recurse -Force -ErrorAction SilentlyContinue }
        }
    }

    It 'counts a findings verdict, which is a reviewed outcome' {
        $root = New-StoreProject -Verdict 'findings' -DeclareExamined -ExaminedPaths @('src/Engine.cs')
        try { Get-SpecrewDerivedIndependenceBlock -ProjectRoot $root | Should -Match 'run-20260820' }
        finally { Remove-Item -LiteralPath $root -Recurse -Force -ErrorAction SilentlyContinue }
    }
}

Describe 'W34-A the block cannot be authored by hand' {
    It 'accepts a record carrying exactly the derived block' {
        $root = New-StoreProject -DeclareExamined -ExaminedPaths @('src/Engine.cs')
        try { @(CheckBlock -Root $root -Block (Get-SpecrewDerivedIndependenceBlock -ProjectRoot $root)).Count | Should -Be 0 }
        finally { Remove-Item -LiteralPath $root -Recurse -Force -ErrorAction SilentlyContinue }
    }

    It 'refuses a block edited to name a run the store does not support' {
        # The KeyContextAI shape, mechanised: a record asserting an independent pass it does not have.
        $root = New-StoreProject -Completion 'partial' -Verdict 'incomplete'
        try {
            $forged = @(
                '<!-- SPECREW-DERIVED-INDEPENDENT-REVIEW v1 -->',
                '<!-- Derived from the review authority store. Do not hand-edit: the validator recomputes it. -->',
                '- Run: run-20260819-211204294-86de8c6e (harness copilot-cli-file-primary)',
                '- Outcome: pass, complete, current, valid - 0 finding(s)',
                '- Reviewed tree: b8585be9fc94b608be2dc32d19871c010632e6be',
                '<!-- /SPECREW-DERIVED-INDEPENDENT-REVIEW -->') -join "`n"
            $found = @(CheckBlock -Root $root -Block $forged)
            $found.Count | Should -Be 1
            $found[0] | Should -Match 'does not match what this project'
        }
        finally { Remove-Item -LiteralPath $root -Recurse -Force -ErrorAction SilentlyContinue }
    }

    It 'is not fooled by CRLF, so a Windows checkout does not read as tampering' {
        $root = New-StoreProject -DeclareExamined -ExaminedPaths @('src/Engine.cs')
        try {
            $crlf = (Get-SpecrewDerivedIndependenceBlock -ProjectRoot $root).Replace("`n", "`r`n")
            @(CheckBlock -Root $root -Block $crlf).Count | Should -Be 0
        }
        finally { Remove-Item -LiteralPath $root -Recurse -Force -ErrorAction SilentlyContinue }
    }

    It 'stays silent on a record that carries no block at all' {
        # Fail-open on absence, like W33 and W34-B: every record written before this has none.
        $root = New-StoreProject
        try { @(CheckBlock -Root $root -Block "# Review: Iteration 001`n`nAll tasks verified.").Count | Should -Be 0 }
        finally { Remove-Item -LiteralPath $root -Recurse -Force -ErrorAction SilentlyContinue }
    }
}

Describe 'Item 6 the ramp promotes itself' {
    # The exposure is not the boundary - the signoff gate is fail-closed and its override phrase is
    # tree-bound and prompt-captured. It is the MAINTAINER'S DECISION: the override asks whether
    # accepting partial coverage is safe, and the only input to that judgement was prose written by the
    # party under review. So the derived truth is put on the same page, and the standard promotes
    # itself: a record written after W34-A carries an observed authorship fact by construction.

    It 'warns, and does not refuse, a record that predates the block' {
        $project = New-RecordProject
        try {
            $outcome = CheckRecord -Project $project
            @($outcome.errors).Count | Should -Be 0
            $outcome.warnings | Should -Be 1
        }
        finally { Remove-Item -LiteralPath $project.Root -Recurse -Force -ErrorAction SilentlyContinue }
    }

    It 'refuses a record whose authorship was observed but carries no block' {
        # Written after the block existed, so it is held to the full standard with no migration date
        # and no hand-touched list.
        $project = New-RecordProject -Observed
        try {
            $outcome = CheckRecord -Project $project
            @($outcome.errors).Count | Should -Be 1
            $outcome.errors[0] | Should -Match 'written after the block existed'
            $outcome.warnings | Should -Be 0
        }
        finally { Remove-Item -LiteralPath $project.Root -Recurse -Force -ErrorAction SilentlyContinue }
    }

    It 'has no false-positive path, because the block always renders' {
        # Even with nothing qualifying, the derivation produces "No run qualifies" - so there is no
        # legitimate case where authorship is observed and nothing can be derived.
        $project = New-RecordProject -Observed -NoRun
        try {
            $outcome = CheckRecord -Project $project
            @($outcome.errors).Count | Should -Be 1
            $outcome.errors[0] | Should -Match 'No run in this project'
        }
        finally { Remove-Item -LiteralPath $project.Root -Recurse -Force -ErrorAction SilentlyContinue }
    }

    It 'says nothing when the record carries the correct block, whatever its authorship' {
        $project = New-RecordProject -Observed
        try {
            $block = Get-SpecrewDerivedIndependenceBlock -ProjectRoot $project.Root
            $outcome = CheckRecord -Project $project -Lines @(($block -split "`n"))
            @($outcome.errors).Count | Should -Be 0
            $outcome.warnings | Should -Be 0
        }
        finally { Remove-Item -LiteralPath $project.Root -Recurse -Force -ErrorAction SilentlyContinue }
    }
}

Describe 'W67 the block derives currentness the way the validator does, not from the frozen field' {
    # Maintainer ruling, 2026-08-26. The generator selected a run on `currentness` FROZEN into
    # result.json at ingest, while the validator recomputes the same question against the tree that
    # exists now (W38, source-aware per DRIFT-007). So the block would put a present-tense claim into
    # review.md that a run covers a tree it does not - in the signoff evidence of the feature whose
    # subject is evidence honesty - and the validator's recompute would contradict it on the same page.
    #
    # One reader's rule, asked at every reader. These cases use a REAL git fixture, because the rule is
    # a tree diff: a fixture with no object store exercises only the fail-open arm, which is the arm
    # that was never broken.

    BeforeAll {
        # The digest helper is what turns a working tree into the tree-id the rule compares, so these
        # cases need it loaded; the suites above never did, which is why they only ever reached the
        # fail-open arm.
        . (Join-Path $script:RepoRoot 'scripts/internal/continuous-co-review/reviewed-state-digest.ps1')

        function script:New-GitTreeProject {
            $root = Join-Path ([IO.Path]::GetTempPath()) ('w67-' + [guid]::NewGuid().ToString('N'))
            New-Item -ItemType Directory -Path (Join-Path $root 'src') -Force | Out-Null
            New-Item -ItemType Directory -Path (Join-Path $root '.specrew') -Force | Out-Null
            Set-Content -LiteralPath (Join-Path $root '.specrew/config.yml') -Encoding UTF8 -Value 'specrew_version: "0.40.0"'
            Set-Content -LiteralPath (Join-Path $root 'src/Engine.cs') -Encoding UTF8 -Value 'class Engine { }'
            & git init -q -b main $root 2>&1 | Out-Null
            & git -C $root add -A 2>&1 | Out-Null
            & git -C $root -c user.name=t -c user.email=t@t commit -q -m init 2>&1 | Out-Null
            return $root
        }
        function script:Get-FixtureTreeId {
            param([Parameter(Mandatory)][string]$Root)
            $state = Get-ContinuousCoReviewReviewedStateDigest -RepoRoot $Root
            if ($null -eq $state -or -not [bool]$state.ok) { throw 'fixture digest failed' }
            return [string]$state.tree_id
        }
        function script:Add-FixtureRun {
            param([Parameter(Mandatory)][string]$Root, [Parameter(Mandatory)][string]$TreeId,
                [string]$RunId = 'run-20260826-111111111-aabbccdd')
            $runDir = Join-Path $Root ".specrew/review/authority/campaigns/cmp-w67/runs/$RunId"
            New-Item -ItemType Directory -Path $runDir -Force | Out-Null
            $result = [ordered]@{
                schema_version = '1.0'; campaign_id = 'cmp-w67'; run_id = $RunId
                harness_id = 'codex-cli-file-primary'; completion = 'complete'; verdict = 'pass'
                currentness = 'current'; validation = 'valid'; target_digest = $TreeId
                examined_paths = @('src/Engine.cs'); findings = @()
            }
            [IO.File]::WriteAllText((Join-Path $runDir 'result.json'), ($result | ConvertTo-Json -Depth 8 -Compress), [Text.UTF8Encoding]::new($false))
            return $RunId
        }
    }

    It 'PRECONDITION: a run against the tree that exists now still qualifies and is named' {
        # Without this control the case below could pass because the fixture never qualified at all.
        $root = New-GitTreeProject
        try {
            $tree = Get-FixtureTreeId -Root $root
            $runId = Add-FixtureRun -Root $root -TreeId $tree
            $block = Get-SpecrewDerivedIndependenceBlock -ProjectRoot $root
            $block | Should -Match ([regex]::Escape($runId)) -Because 'a covering run is exactly what the block exists to name'
            $block | Should -Match '1 source path\(s\)'
        }
        finally { Remove-Item -LiteralPath $root -Recurse -Force -ErrorAction SilentlyContinue }
    }

    It 'RED-FIRST: a run whose SOURCE has moved since no longer qualifies, and the block says so' {
        $root = New-GitTreeProject
        try {
            $tree = Get-FixtureTreeId -Root $root
            $runId = Add-FixtureRun -Root $root -TreeId $tree
            # The code the run read is not the code that is here now.
            Set-Content -LiteralPath (Join-Path $root 'src/Engine.cs') -Encoding UTF8 -Value 'class Engine { void Added() { } }'

            Get-SpecrewQualifyingIndependentRun -ProjectRoot $root |
                Should -BeNullOrEmpty -Because 'the frozen field says current; the tree says otherwise, and the tree is the fact'
            $block = Get-SpecrewDerivedIndependenceBlock -ProjectRoot $root
            $block | Should -Match 'does not cover the current source'
            $block | Should -Match ([regex]::Escape($tree.Substring(0, 8))) -Because 'naming the tree it DID review is what makes the claim checkable'
            # THE RUN ID MUST NOT APPEAR. The validator reads any run id in the block as the evidence
            # the record rests on, so a non-coverage arm that names one would be refused as a stale
            # citation - the block would state non-coverage and be read as a claim of coverage.
            $block | Should -Not -Match 'run-\d{8}-\d{9}-[0-9a-f]{8}'
            $runId | Should -Not -BeNullOrEmpty
        }
        finally { Remove-Item -LiteralPath $root -Recurse -Force -ErrorAction SilentlyContinue }
    }

    It 'a run stays qualifying when only RECORDS moved, so writing the record cannot stale it' {
        # DRIFT-007's rule, which the generator must inherit along with the recompute. Without this the
        # fix would wedge every project at the commit that records its own review.
        $root = New-GitTreeProject
        try {
            $tree = Get-FixtureTreeId -Root $root
            $runId = Add-FixtureRun -Root $root -TreeId $tree
            New-Item -ItemType Directory -Path (Join-Path $root 'specs/001-thing/iterations/001') -Force | Out-Null
            Set-Content -LiteralPath (Join-Path $root 'specs/001-thing/iterations/001/state.md') -Encoding UTF8 -Value '# State'
            $block = Get-SpecrewDerivedIndependenceBlock -ProjectRoot $root
            $block | Should -Match ([regex]::Escape($runId)) -Because 'recording a review must not invalidate it'
            $block | Should -Not -Match 'does not cover the current source'
        }
        finally { Remove-Item -LiteralPath $root -Recurse -Force -ErrorAction SilentlyContinue }
    }

    It 'FAILS OPEN when the tree cannot be resolved: absence of proof is not staleness' {
        # Every fixture in this file that predates W67 lives in a directory with no git object store.
        # The rule must stay quiet there, the same posture the validator takes - "I could not tell"
        # must never manufacture staleness.
        $root = New-StoreProject -DeclareExamined -ExaminedPaths @('src/Engine.cs')
        try {
            $block = Get-SpecrewDerivedIndependenceBlock -ProjectRoot $root
            $block | Should -Match 'run-20260820-083412478-d85dda20' -Because 'no object store means no answer, and no answer is not a refusal'
        }
        finally { Remove-Item -LiteralPath $root -Recurse -Force -ErrorAction SilentlyContinue }
    }

    It 'a reviewed tree that has LEFT the object store is not-knowing, and is left for the validator to refuse' {
        # My first cut excluded these too, and review-record-survives-its-own-commit went red: the
        # block would have said "no run qualifies", the record would have validated CLEAN, and a record
        # whose only evidence cannot be checked would have quietly received a pass. W38 reports
        # not-comparable as a WEAK claim and refuses it at the validator; staleness is a different
        # answer from not knowing, and only staleness belongs to this selector.
        $root = New-GitTreeProject
        try {
            $runId = Add-FixtureRun -Root $root -TreeId ('0' * 40)
            $qualifying = Get-SpecrewQualifyingIndependentRun -ProjectRoot $root
            $qualifying | Should -Not -BeNullOrEmpty -Because 'dropping it here would silence the refusal that is supposed to fire downstream'
            (Get-SpecrewDerivedIndependenceBlock -ProjectRoot $root) | Should -Match ([regex]::Escape($runId)) -Because 'the validator refuses what the block names, and it can only name what it is given'
        }
        finally { Remove-Item -LiteralPath $root -Recurse -Force -ErrorAction SilentlyContinue }
    }

    It 'RED-FIRST: a run stored as snapshot-moved still qualifies when no SOURCE moved' {
        # W67 kept the run's FROZEN `currentness` as a "floor" on top of the recomputed answer. The
        # floor is the pre-W67 question, and keeping it makes it decisive: the field is snapshot-EXACT,
        # so it reads snapshot-moved after ANY commit in the review window - including a records-only
        # one, which DRIFT-007 exists to make harmless. A round could therefore be disqualified by the
        # act of writing down what it found.
        #
        # Measured on run-20260826-194901162-77511bab: the recomputed answer named two source files,
        # and the floor excluded the run from the candidate list before that answer was ever consulted.
        # Reading the frozen field as the answer is exactly the reading W67 exists to replace.
        $root = New-GitTreeProject
        try {
            $tree = Get-FixtureTreeId -Root $root
            $runId = Add-FixtureRun -Root $root -TreeId $tree
            # The run recorded itself as snapshot-moved; only RECORDS have changed since.
            $resultPath = Join-Path $root ".specrew/review/authority/campaigns/cmp-w67/runs/$runId/result.json"
            $result = Get-Content -LiteralPath $resultPath -Raw | ConvertFrom-Json
            $result.currentness = 'snapshot-moved'
            [IO.File]::WriteAllText($resultPath, ($result | ConvertTo-Json -Depth 8 -Compress), [Text.UTF8Encoding]::new($false))
            New-Item -ItemType Directory -Path (Join-Path $root 'specs/001-thing/iterations/001') -Force | Out-Null
            Set-Content -LiteralPath (Join-Path $root 'specs/001-thing/iterations/001/drift-log.md') -Value '# recorded what it found' -Encoding UTF8

            $qualifying = Get-SpecrewQualifyingIndependentRun -ProjectRoot $root
            $qualifying | Should -Not -BeNullOrEmpty -Because 'the recomputed source-aware answer is the answer; the frozen field is the question it replaced'
            [string]$qualifying.result.run_id | Should -Be $runId
        }
        finally { Remove-Item -LiteralPath $root -Recurse -Force -ErrorAction SilentlyContinue }
    }

    It 'the generator and the validator answer the currentness question with the SAME rule' {
        # The structural half of the ruling: not "both are correct today" but "there is one rule".
        $governance = Get-Content -LiteralPath (Join-Path $script:RepoRoot 'extensions\specrew-speckit\scripts\shared-governance.ps1') -Raw -Encoding UTF8
        $validator = Get-Content -LiteralPath (Join-Path $script:RepoRoot 'extensions\specrew-speckit\scripts\validate-governance.ps1') -Raw -Encoding UTF8
        $selector = [regex]::Match($governance, '(?s)function Get-SpecrewQualifyingIndependentRun.*?\r?\n\}').Value
        $selector | Should -Not -BeNullOrEmpty
        $selector | Should -Match 'Get-SpecrewReviewRunCoversCurrentSource' -Because 'the selector must ASK the question rather than read a field that answered it once'
        $validator | Should -Match 'Get-SpecrewReviewedTreeSourceDrift' -Because 'the validator already asks it; the point is that both ask the same thing'
        # And the shared rule is the one place the source-awareness lives.
        $shared = [regex]::Match($governance, '(?s)function Get-SpecrewReviewRunCoversCurrentSource.*?\r?\n\}').Value
        $shared | Should -Match 'Get-SpecrewReviewedTreeSourceDrift'
    }
}
