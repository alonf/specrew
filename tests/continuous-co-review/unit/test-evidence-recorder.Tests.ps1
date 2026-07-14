#Requires -Modules @{ ModuleName = 'Pester'; ModuleVersion = '5.0' }
<#
    T111 (DEC-197-I010-004): implementer test-evidence recorder + digest-matched worktree injection +
    the gated prompt block. The load-bearing properties under test:
      - evidence is BOUND to the reviewed-state digest of the tree the tests ran against;
      - recording evidence never changes the digest it certifies (.specrew is digest-excluded);
      - injection happens ONLY on an exact digest match (never wrong evidence, never stale);
      - the prompt instructs evidence-substitution ONLY when the file was actually injected.
#>

BeforeAll {
    . (Join-Path $PSScriptRoot '..\..\..\scripts\internal\continuous-co-review\_load.ps1')
    . (Join-Path $PSScriptRoot '..\..\..\scripts\internal\continuous-co-review\worktree-reviewer.ps1')

    function New-EvidenceTestRepo {
        param([Parameter(Mandatory)][string]$Root)
        $null = New-Item -ItemType Directory -Path $Root -Force
        & git -C $Root init --initial-branch=main 2>$null | Out-Null
        & git -C $Root config user.email 'specrew-test@example.invalid' 2>$null | Out-Null
        & git -C $Root config user.name 'Specrew Test' 2>$null | Out-Null
        [System.IO.File]::WriteAllText((Join-Path $Root 'src.ps1'), "function Get-Thing { 'v1' }`n")
        & git -C $Root add . 2>$null | Out-Null
        & git -C $Root commit -m 'baseline' 2>$null | Out-Null
        return (Resolve-Path -LiteralPath $Root).Path
    }
}

Describe 'Write-ContinuousCoReviewTestEvidence' {
    It 'records a digest-bound suite entry and leaves the digest it certifies UNCHANGED' {
        $repo = New-EvidenceTestRepo -Root (Join-Path $TestDrive 'repo-record')
        $before = Get-ContinuousCoReviewReviewedStateDigest -RepoRoot $repo
        $before.ok | Should -BeTrue

        $record = Write-ContinuousCoReviewTestEvidence -RepoRoot $repo -Suite 'unit' -Passed 12 -Failed 0 -Skipped 1 -ExitCode 0 -DurationSeconds 3.21 -Command 'Invoke-Pester tests/unit'
        $record | Should -Not -BeNullOrEmpty
        $record.reviewed_digest_tree_id | Should -Be ([string]$before.tree_id)
        @($record.suites).Count | Should -Be 1
        @($record.suites)[0].passed | Should -Be 12
        @($record.suites)[0].exit_code | Should -Be 0

        $path = Join-Path (Get-ContinuousCoReviewTestEvidenceDirectory -RepoRoot $repo) ([string]$before.tree_id + '.json')
        Test-Path -LiteralPath $path -PathType Leaf | Should -BeTrue

        # THE property: writing evidence must not move the tree identity it certifies.
        $after = Get-ContinuousCoReviewReviewedStateDigest -RepoRoot $repo
        [string]$after.tree_id | Should -Be ([string]$before.tree_id)
    }

    It 'replaces a re-recorded suite and accumulates distinct suites' {
        $repo = New-EvidenceTestRepo -Root (Join-Path $TestDrive 'repo-merge')
        $null = Write-ContinuousCoReviewTestEvidence -RepoRoot $repo -Suite 'unit' -Passed 5 -ExitCode 0
        $null = Write-ContinuousCoReviewTestEvidence -RepoRoot $repo -Suite 'integration' -Passed 7 -ExitCode 0
        $record = Write-ContinuousCoReviewTestEvidence -RepoRoot $repo -Suite 'unit' -Passed 6 -ExitCode 0

        @($record.suites).Count | Should -Be 2
        $unit = @($record.suites) | Where-Object { $_.suite -eq 'unit' }
        @($unit).Count | Should -Be 1
        @($unit)[0].passed | Should -Be 6
    }

    It 'fails SOFT (warns, returns null) when the repo root is not a resolvable repo' {
        $result = Write-ContinuousCoReviewTestEvidence -RepoRoot (Join-Path $TestDrive 'does-not-exist') -Suite 'unit' -Passed 1 -ExitCode 0 2>$null
        $result | Should -BeNullOrEmpty
    }
}

Describe 'Get-ContinuousCoReviewTestEvidenceForDigest' {
    It 'returns the record only for the exact digest it certifies' {
        $repo = New-EvidenceTestRepo -Root (Join-Path $TestDrive 'repo-lookup')
        $digest = [string](Get-ContinuousCoReviewReviewedStateDigest -RepoRoot $repo).tree_id
        $null = Write-ContinuousCoReviewTestEvidence -RepoRoot $repo -Suite 'unit' -Passed 3 -ExitCode 0

        (Get-ContinuousCoReviewTestEvidenceForDigest -RepoRoot $repo -DigestTreeId $digest) | Should -Not -BeNullOrEmpty
        (Get-ContinuousCoReviewTestEvidenceForDigest -RepoRoot $repo -DigestTreeId ('0' * 40)) | Should -BeNullOrEmpty
    }

    It 'accepts and injects a T018 runs-only exact-digest record (Prop-145 / T019 step-6 unblock)' {
        $repo = New-EvidenceTestRepo -Root (Join-Path $TestDrive 'repo-runs')
        $digest = [string](Get-ContinuousCoReviewReviewedStateDigest -RepoRoot $repo).tree_id
        # Invoke-ContinuousCoReviewRecordedRun writes a `runs` record (never `suites`), keyed by the reviewed digest.
        $ev = Invoke-ContinuousCoReviewRecordedRun -RepoRoot $repo -Executable 'pwsh' -Arguments @('-NoProfile', '-Command', 'exit 0') -TimeoutSeconds 60
        $ev | Should -Not -BeNullOrEmpty
        [string]$ev.reviewed_digest_tree_id | Should -Be $digest

        # the reader now returns a runs-only record (previously suites-only -> rejected)...
        $record = Get-ContinuousCoReviewTestEvidenceForDigest -RepoRoot $repo -DigestTreeId $digest
        $record | Should -Not -BeNullOrEmpty
        @($record.runs).Count | Should -BeGreaterThan 0
        (Get-ContinuousCoReviewTestEvidenceForDigest -RepoRoot $repo -DigestTreeId ('0' * 40)) | Should -BeNullOrEmpty

        # ...and it INJECTS into the reviewer worktree as authoritative reviewer input on an exact digest match.
        $wt = Join-Path $TestDrive 'worktree-runs'
        $null = New-Item -ItemType Directory -Path (Join-Path $wt '.review') -Force
        (Copy-ContinuousCoReviewImplementerEvidence -RepoRoot $repo -WorktreePath $wt -DigestTreeId $digest) | Should -BeTrue
        $injected = Get-Content -LiteralPath (Join-Path $wt '.review/implementer-evidence.json') -Raw | ConvertFrom-Json
        [string]$injected.reviewed_digest_tree_id | Should -Be $digest
        @($injected.runs).Count | Should -BeGreaterThan 0
    }

    It 'REFUSES a mixed-digest record on the PRODUCTION lookup/copy path - envelope AND every embedded digest must match (review finding f3, run 20260714T172315119)' {
        $repo = New-EvidenceTestRepo -Root (Join-Path $TestDrive 'repo-mixed')
        $digest = [string](Get-ContinuousCoReviewReviewedStateDigest -RepoRoot $repo).tree_id
        $null = Invoke-ContinuousCoReviewRecordedRun -RepoRoot $repo -Executable 'pwsh' -Arguments @('-NoProfile', '-Command', 'exit 0') -TimeoutSeconds 60
        $storePath = Join-Path $repo ('.specrew/review/test-evidence/' + $digest + '.json')
        # TAMPER: smuggle a run recorded at a FOREIGN digest into the digest-B-keyed record. Pre-fix the
        # lookup validated only the envelope and this record injected as digest-B evidence.
        $rec = Get-Content -LiteralPath $storePath -Raw | ConvertFrom-Json
        $foreign = ($rec.runs | Select-Object -First 1) | ConvertTo-Json -Depth 12 | ConvertFrom-Json
        $foreign.reviewed_digest_tree_id = ('a' * 40)
        $rec.runs = @(@($rec.runs) + $foreign)
        ($rec | ConvertTo-Json -Depth 12) | Set-Content -LiteralPath $storePath -Encoding UTF8
        (Get-ContinuousCoReviewTestEvidenceForDigest -RepoRoot $repo -DigestTreeId $digest) | Should -BeNullOrEmpty -Because 'a record carrying ANY foreign embedded digest is refused fail-closed'
        $wt = Join-Path $TestDrive 'worktree-mixed'
        $null = New-Item -ItemType Directory -Path (Join-Path $wt '.review') -Force
        (Copy-ContinuousCoReviewImplementerEvidence -RepoRoot $repo -WorktreePath $wt -DigestTreeId $digest) | Should -BeFalse -Because 'the reviewer gets NO evidence, never wrong evidence'
        Test-Path -LiteralPath (Join-Path $wt '.review/implementer-evidence.json') | Should -BeFalse
    }

    It 'the INJECTED evidence copy is ORIGIN-RELATIVIZED - zero origin-absolute paths reach the reviewer (review finding f5, run 20260714T190233598)' {
        $repo = New-EvidenceTestRepo -Root (Join-Path $TestDrive 'repo-relativize')
        $digest = [string](Get-ContinuousCoReviewReviewedStateDigest -RepoRoot $repo).tree_id
        # a real run: the recorder stamps the ABSOLUTE working directory; the argument vector carries a
        # docker-style volume mount naming the origin root (the exact leak the reviewer demonstrated).
        $null = Invoke-ContinuousCoReviewRecordedRun -RepoRoot $repo -Executable 'pwsh' -Arguments @('-NoProfile', '-Command', 'exit 0', ('-v'), ($repo + ':/repo')) -TimeoutSeconds 60
        $wt = Join-Path $TestDrive 'worktree-relativize'
        $null = New-Item -ItemType Directory -Path (Join-Path $wt '.review') -Force
        (Copy-ContinuousCoReviewImplementerEvidence -RepoRoot $repo -WorktreePath $wt -DigestTreeId $digest) | Should -BeTrue
        $raw = Get-Content -LiteralPath (Join-Path $wt '.review/implementer-evidence.json') -Raw
        $resolvedRepo = (Resolve-Path -LiteralPath $repo).Path
        $raw | Should -Not -Match ([regex]::Escape($resolvedRepo)) -Because 'the reviewer-visible copy must carry no origin-absolute path'
        $raw | Should -Not -Match ([regex]::Escape($resolvedRepo.Replace('\', '\\'))) -Because 'the JSON-escaped backslash form must be relativized too'
        $raw | Should -Match ([regex]::Escape('<project>')) -Because 'structure stays reviewable; only the origin prefix is neutralized'
        # the ORIGIN-side durable record is untouched (relativization applies to the copy only).
        $originRaw = Get-Content -LiteralPath (Join-Path $repo ('.specrew/review/test-evidence/' + $digest + '.json')) -Raw
        $originRaw | Should -Match ([regex]::Escape($resolvedRepo.Replace('\', '\\')))
        # and the scrubbed copy still parses with its digest identity intact.
        $injected = $raw | ConvertFrom-Json
        [string]$injected.reviewed_digest_tree_id | Should -Be $digest
    }

    It 'a same-digest FAIL-then-PASS re-run keeps BOTH attempts durable and visible - a failure never becomes missing evidence (review finding f2, run 20260714T201103653)' {
        $repo = New-EvidenceTestRepo -Root (Join-Path $TestDrive 'repo-attempts')
        $digest = [string](Get-ContinuousCoReviewReviewedStateDigest -RepoRoot $repo).tree_id
        $null = Invoke-ContinuousCoReviewRecordedRun -RepoRoot $repo -Executable 'pwsh' -Arguments @('-NoProfile', '-Command', 'exit 7') -CommandId 'flaky' -TimeoutSeconds 60
        $null = Invoke-ContinuousCoReviewRecordedRun -RepoRoot $repo -Executable 'pwsh' -Arguments @('-NoProfile', '-Command', 'exit 0') -CommandId 'flaky' -TimeoutSeconds 60
        $rec = Get-Content -LiteralPath (Join-Path $repo ('.specrew/review/test-evidence/' + $digest + '.json')) -Raw | ConvertFrom-Json
        $flaky = @(@($rec.runs) | Where-Object { [string]$_.command_id -eq 'flaky' } | Sort-Object { [int]$_.attempt })
        @($flaky).Count | Should -Be 2 -Because 'the later success must NOT erase the earlier failed attempt'
        [int]$flaky[0].attempt | Should -Be 1
        $flaky[0].command_succeeded | Should -BeFalse -Because 'the failure stays durable, never a clean-only history'
        [int]$flaky[1].attempt | Should -Be 2
        $flaky[1].command_succeeded | Should -BeTrue
        # the join treats the LATEST attempt as authoritative; the earlier one is HISTORY, never ambiguity.
        $plan = [pscustomobject]@{ commands = @([pscustomobject]@{ command_id = 'flaky' }) }
        $joined = @(Test-ContinuousCoReviewPlanEvidenceInjectable -PlanEvidence $flaky -Plan $plan -CurrentDigest $digest)
        [string]$joined[0].classification | Should -Be 'attempt-superseded-history'
        [string]$joined[1].classification | Should -Be 'exact-digest-command-joined'
        $joined[1].injectable | Should -BeTrue
        # and the PRODUCTION injection keeps BOTH visible under the SELECTED plan (history is evidence, not noise).
        $wt = Join-Path $TestDrive 'worktree-attempts'
        $null = New-Item -ItemType Directory -Path (Join-Path $wt '.review') -Force
        (Copy-ContinuousCoReviewImplementerEvidence -RepoRoot $repo -WorktreePath $wt -DigestTreeId $digest -Plan $plan) | Should -BeTrue
        $injected = Get-Content -LiteralPath (Join-Path $wt '.review/implementer-evidence.json') -Raw | ConvertFrom-Json
        @(@($injected.runs) | Where-Object { [string]$_.command_id -eq 'flaky' }).Count | Should -Be 2
    }

    It 'plan-identified evidence with NO selected plan is withheld FAIL-CLOSED as selected-plan-unavailable - the validating plan is never derived from the evidence (maintainer wiring directive 2026-07-15)' {
        $repo = New-EvidenceTestRepo -Root (Join-Path $TestDrive 'repo-no-plan')
        $digest = [string](Get-ContinuousCoReviewReviewedStateDigest -RepoRoot $repo).tree_id
        $null = Invoke-ContinuousCoReviewRecordedRun -RepoRoot $repo -Executable 'pwsh' -Arguments @('-NoProfile', '-Command', 'exit 0') -TimeoutSeconds 60
        $null = Invoke-ContinuousCoReviewRecordedRun -RepoRoot $repo -Executable 'pwsh' -Arguments @('-NoProfile', '-Command', 'exit 0', '-planrun') -CommandId 'orphan-plan-run' -TimeoutSeconds 60
        $wt = Join-Path $TestDrive 'worktree-no-plan'
        $null = New-Item -ItemType Directory -Path (Join-Path $wt '.review') -Force
        (Copy-ContinuousCoReviewImplementerEvidence -RepoRoot $repo -WorktreePath $wt -DigestTreeId $digest) | Should -BeTrue -Because 'the identity-less self-evidence still injects'
        $injected = Get-Content -LiteralPath (Join-Path $wt '.review/implementer-evidence.json') -Raw | ConvertFrom-Json
        @(@($injected.runs) | Where-Object { (@($_.PSObject.Properties.Name) -contains 'command_id') -and [string]$_.command_id -eq 'orphan-plan-run' }).Count | Should -Be 0 -Because 'without a SELECTED plan there is nothing authoritative to join against - fail closed, never self-derived'
        @(@($injected.withheld_runs) | Where-Object { [string]$_.command_id -eq 'orphan-plan-run' }).Count | Should -Be 1
        [string](@($injected.withheld_runs) | Where-Object { [string]$_.command_id -eq 'orphan-plan-run' }).classification | Should -Be 'selected-plan-unavailable'
    }

    It 'the PRODUCTION sequence resolver -> injection joins against the ACTUAL selected plan from .specrew/verification-plan.json (paired production path, maintainer wiring directive 2026-07-15)' {
        $repo = New-EvidenceTestRepo -Root (Join-Path $TestDrive 'repo-selected-plan')
        $digest = [string](Get-ContinuousCoReviewReviewedStateDigest -RepoRoot $repo).tree_id
        # the FR-049 supplier's canonical output: a schema-valid selected plan naming ONE command.
        $planDoc = [ordered]@{
            schema_version = '1.0'; plan_id = 'selected-p1'
            commands       = @([ordered]@{ command_id = 'named-by-plan'; executable = 'pwsh'; arguments = @('-NoProfile', '-Command', 'exit 0'); provenance = [ordered]@{ kind = 'project-config'; source = '.specrew/verification-plan.json' } })
        }
        New-Item -ItemType Directory -Path (Join-Path $repo '.specrew') -Force | Out-Null
        ($planDoc | ConvertTo-Json -Depth 8) | Set-Content -LiteralPath (Join-Path $repo '.specrew/verification-plan.json') -Encoding UTF8
        $null = Invoke-ContinuousCoReviewRecordedRun -RepoRoot $repo -Executable 'pwsh' -Arguments @('-NoProfile', '-Command', 'exit 0') -CommandId 'named-by-plan' -TimeoutSeconds 60
        $null = Invoke-ContinuousCoReviewRecordedRun -RepoRoot $repo -Executable 'pwsh' -Arguments @('-NoProfile', '-Command', 'exit 0', '-x') -CommandId 'smuggled-id' -TimeoutSeconds 60
        # the SAME sequence the orchestrator runs: resolve the selected plan, pass it to the injection.
        $sel = Get-ContinuousCoReviewSelectedVerificationPlan -RepoRoot $repo
        $sel.available | Should -BeTrue
        $wt = Join-Path $TestDrive 'worktree-selected-plan'
        $null = New-Item -ItemType Directory -Path (Join-Path $wt '.review') -Force
        (Copy-ContinuousCoReviewImplementerEvidence -RepoRoot $repo -WorktreePath $wt -DigestTreeId $digest -Plan $sel.plan) | Should -BeTrue
        $injected = Get-Content -LiteralPath (Join-Path $wt '.review/implementer-evidence.json') -Raw | ConvertFrom-Json
        @(@($injected.runs) | Where-Object { (@($_.PSObject.Properties.Name) -contains 'command_id') -and [string]$_.command_id -eq 'named-by-plan' }).Count | Should -Be 1 -Because 'the plan-named run joins'
        @(@($injected.runs) | Where-Object { (@($_.PSObject.Properties.Name) -contains 'command_id') -and [string]$_.command_id -eq 'smuggled-id' }).Count | Should -Be 0 -Because 'an id absent from the SELECTED plan never injects - the plan is authoritative, not the evidence'
        [string](@($injected.withheld_runs) | Where-Object { [string]$_.command_id -eq 'smuggled-id' }).classification | Should -Be 'unjoinable-no-matching-command'
    }

    It 'AMBIGUOUS duplicate plan runs are WITHHELD at the PRODUCTION injection boundary and surfaced - never silently injected (review finding f1, run 20260714T201103653)' {
        $repo = New-EvidenceTestRepo -Root (Join-Path $TestDrive 'repo-join-boundary')
        $digest = [string](Get-ContinuousCoReviewReviewedStateDigest -RepoRoot $repo).tree_id
        # one legitimate identity-less self-evidence run...
        $null = Invoke-ContinuousCoReviewRecordedRun -RepoRoot $repo -Executable 'pwsh' -Arguments @('-NoProfile', '-Command', 'exit 0') -TimeoutSeconds 60
        # ...then TAMPER: two runs with the SAME command_id and NO attempt discrimination (the ambiguous
        # duplicate the join contract refuses), smuggled into the digest-keyed store.
        $storePath = Join-Path $repo ('.specrew/review/test-evidence/' + $digest + '.json')
        $rec = Get-Content -LiteralPath $storePath -Raw | ConvertFrom-Json
        $dupA = ($rec.runs | Select-Object -First 1) | ConvertTo-Json -Depth 12 | ConvertFrom-Json
        $dupA | Add-Member -NotePropertyName 'command_id' -NotePropertyValue 'dup' -Force
        $dupB = ($rec.runs | Select-Object -First 1) | ConvertTo-Json -Depth 12 | ConvertFrom-Json
        $dupB | Add-Member -NotePropertyName 'command_id' -NotePropertyValue 'dup' -Force
        $rec.runs = @(@($rec.runs) + $dupA + $dupB)
        ($rec | ConvertTo-Json -Depth 12) | Set-Content -LiteralPath $storePath -Encoding UTF8

        $wt = Join-Path $TestDrive 'worktree-join-boundary'
        $null = New-Item -ItemType Directory -Path (Join-Path $wt '.review') -Force
        $dupPlan = [pscustomobject]@{ commands = @([pscustomobject]@{ command_id = 'dup' }) }
        (Copy-ContinuousCoReviewImplementerEvidence -RepoRoot $repo -WorktreePath $wt -DigestTreeId $digest -Plan $dupPlan) | Should -BeTrue -Because 'the legitimate identity-less run still injects'
        $injected = Get-Content -LiteralPath (Join-Path $wt '.review/implementer-evidence.json') -Raw | ConvertFrom-Json
        @(@($injected.runs) | Where-Object { (@($_.PSObject.Properties.Name) -contains 'command_id') -and [string]$_.command_id -eq 'dup' }).Count | Should -Be 0 -Because 'ambiguous duplicates never reach the reviewer'
        @($injected.withheld_runs).Count | Should -Be 2 -Because 'the refusal is SURFACED in the injected artifact, never silent'
        foreach ($w in @($injected.withheld_runs)) { [string]$w.classification | Should -Be 'duplicate-command-id-surfaced' }
        # the ORIGIN-side durable record is untouched by the withholding (copy-only surgery).
        $originRec = Get-Content -LiteralPath $storePath -Raw | ConvertFrom-Json
        @(@($originRec.runs) | Where-Object { (@($_.PSObject.Properties.Name) -contains 'command_id') -and [string]$_.command_id -eq 'dup' }).Count | Should -Be 2
        # with a REAL plan that does not name the id, the runs are withheld as unjoinable.
        $wt2 = Join-Path $TestDrive 'worktree-join-boundary2'
        $null = New-Item -ItemType Directory -Path (Join-Path $wt2 '.review') -Force
        $foreignPlan = [pscustomobject]@{ commands = @([pscustomobject]@{ command_id = 'something-else' }) }
        (Copy-ContinuousCoReviewImplementerEvidence -RepoRoot $repo -WorktreePath $wt2 -DigestTreeId $digest -Plan $foreignPlan) | Should -BeTrue
        $injected2 = Get-Content -LiteralPath (Join-Path $wt2 '.review/implementer-evidence.json') -Raw | ConvertFrom-Json
        foreach ($w in @($injected2.withheld_runs)) { [string]$w.classification | Should -Be 'unjoinable-no-matching-command' }
    }

    It 'REFUSES an embedded entry with NO digest identity (fail closed on missing, not only foreign)' {
        $repo = New-EvidenceTestRepo -Root (Join-Path $TestDrive 'repo-missing-id')
        $digest = [string](Get-ContinuousCoReviewReviewedStateDigest -RepoRoot $repo).tree_id
        $null = Write-ContinuousCoReviewTestEvidence -RepoRoot $repo -Suite 'unit' -Passed 3 -ExitCode 0
        # the CURRENT writer stamps the digest into every suite entry - the record is injectable as written...
        (Get-ContinuousCoReviewTestEvidenceForDigest -RepoRoot $repo -DigestTreeId $digest) | Should -Not -BeNullOrEmpty
        # ...but stripping an embedded identity (the legacy pre-fix shape / a tampered entry) refuses it.
        $storePath = Join-Path $repo ('.specrew/review/test-evidence/' + $digest + '.json')
        $rec = Get-Content -LiteralPath $storePath -Raw | ConvertFrom-Json
        @($rec.suites)[0].PSObject.Properties.Remove('reviewed_digest_tree_id')
        ($rec | ConvertTo-Json -Depth 12) | Set-Content -LiteralPath $storePath -Encoding UTF8
        (Get-ContinuousCoReviewTestEvidenceForDigest -RepoRoot $repo -DigestTreeId $digest) | Should -BeNullOrEmpty -Because 'an identity-less embedded entry cannot certify any digest'
    }
}

Describe 'Copy-ContinuousCoReviewImplementerEvidence' {
    It 'injects into the worktree .review dir on an exact digest match' {
        $repo = New-EvidenceTestRepo -Root (Join-Path $TestDrive 'repo-inject')
        $digest = [string](Get-ContinuousCoReviewReviewedStateDigest -RepoRoot $repo).tree_id
        $null = Write-ContinuousCoReviewTestEvidence -RepoRoot $repo -Suite 'unit' -Passed 9 -ExitCode 0

        $wt = Join-Path $TestDrive 'worktree-match'
        $null = New-Item -ItemType Directory -Path (Join-Path $wt '.review') -Force

        (Copy-ContinuousCoReviewImplementerEvidence -RepoRoot $repo -WorktreePath $wt -DigestTreeId $digest) | Should -BeTrue
        $injected = Get-Content -LiteralPath (Join-Path $wt '.review\implementer-evidence.json') -Raw | ConvertFrom-Json
        $injected.reviewed_digest_tree_id | Should -Be $digest
        @($injected.suites)[0].passed | Should -Be 9
    }

    It 'injects NOTHING on a digest mismatch, an empty digest, or a missing .review dir' {
        $repo = New-EvidenceTestRepo -Root (Join-Path $TestDrive 'repo-noinject')
        $null = Write-ContinuousCoReviewTestEvidence -RepoRoot $repo -Suite 'unit' -Passed 2 -ExitCode 0

        $wt = Join-Path $TestDrive 'worktree-nomatch'
        $null = New-Item -ItemType Directory -Path (Join-Path $wt '.review') -Force

        (Copy-ContinuousCoReviewImplementerEvidence -RepoRoot $repo -WorktreePath $wt -DigestTreeId ('f' * 40)) | Should -BeFalse
        (Copy-ContinuousCoReviewImplementerEvidence -RepoRoot $repo -WorktreePath $wt -DigestTreeId '') | Should -BeFalse
        Test-Path -LiteralPath (Join-Path $wt '.review\implementer-evidence.json') | Should -BeFalse

        $bare = Join-Path $TestDrive 'worktree-bare'
        $null = New-Item -ItemType Directory -Path $bare -Force
        $digest = [string](Get-ContinuousCoReviewReviewedStateDigest -RepoRoot $repo).tree_id
        (Copy-ContinuousCoReviewImplementerEvidence -RepoRoot $repo -WorktreePath $bare -DigestTreeId $digest) | Should -BeFalse
    }
}

Describe 'Get-ContinuousCoReviewSlimPrompt implementer-evidence block' {
    It 'instructs evidence-substitution ONLY when the evidence was actually injected' {
        $with = Get-ContinuousCoReviewSlimPrompt -RunId 'r1' -ImplementerEvidencePresent
        # 203-W8 honesty (codex f1): the prompt must say IMPLEMENTER-recorded (never machine-observed),
        # arm the spot-check as forgery detection, and keep the substitution rule for budget purposes.
        $with | Should -Match 'IMPLEMENTER TEST EVIDENCE \(implementer-recorded, digest-matched\)'
        $with | Should -Match 'IMPLEMENTER-SUPPLIED, not independently observed'
        $with | Should -Match 'do NOT re-run whole covered suites by default'
        $with | Should -Match 'mismatch between a spot-check and the record is itself a BLOCKING honesty finding'
        $with | Should -Not -Match 'machine-recorded'
        $with | Should -Match 'falsification stance applies to them unchanged'

        $without = Get-ContinuousCoReviewSlimPrompt -RunId 'r1'
        $without | Should -Not -Match 'IMPLEMENTER TEST EVIDENCE'
        # The standing posture is untouched either way.
        $without | Should -Match 'REPORT-FALSIFICATION STANCE'
        $with | Should -Match 'NEVER-FALSE-GREEN'
    }

    It 'teaches RESOLVED-BY-DEFERRAL on fix-verification rounds (the T106 human-close missing half)' {
        $round2 = Get-ContinuousCoReviewSlimPrompt -RunId 'r1' -RoundNumber 2 -MaxRounds 2 -PriorFindings '{"findings":[{"finding_id":"f1"}]}'
        # A recorded human deferral resolves a finding for round purposes - verified in-tree, never a claim.
        $round2 | Should -Match 'RESOLVED-BY-DEFERRAL'
        $round2 | Should -Match 'RECORDED HUMAN DEFERRAL'
        $round2 | Should -Match 'deferral CLAIM without a verifiable worktree-visible record is itself a blocking finding'
        $round2 | Should -Match 'not covered by a verified recorded deferral'
        # Deferral awareness applies on EVERY round (a fresh round-1 review of a diff containing
        # deferred issues must not re-raise them as blocking), and escalation items never self-perpetuate.
        $round1 = Get-ContinuousCoReviewSlimPrompt -RunId 'r1'
        $round1 | Should -Match 'RECORDED HUMAN DEFERRALS \(applies on EVERY round\)'
        $round1 | Should -Match 'as ADVISORY with the decision id'
        $round2 | Should -Match "kind 'escalation' is itself RESOLVED"
        $round2 | Should -Match 'do not copy an escalation forward'
        # Downstream field bug (2026-07-09, tesr197local): deferral records must be WORKTREE-VISIBLE -
        # .squad/decisions.md is machinery-stripped from review worktrees, so the teaching must name
        # drift-log/specs/proposals as the verifiable homes and treat machinery-only records as
        # unverifiable-here rather than false.
        $round1 | Should -Match 'WORKTREE-VISIBLE artifact'
        $round1 | Should -Match 'UNVERIFIABLE-HERE'
        $round2 | Should -Match 'WORKTREE-VISIBLE artifact'
        $round2 | Should -Not -Match '\(\.squad/decisions\.md, a drift-log event'
    }
}
