$ErrorActionPreference = 'Stop'

#Requires -Modules @{ ModuleName = 'Pester'; ModuleVersion = '5.0' }

# T019 / FR-048 (amended 2026-07-13) — the EXECUTION side. Proves the runner EXECUTES a mixed,
# order-declared plan through the universal T018 recorded-run runner and returns per-command,
# digest+command_id-bound, provenance-object-tagged evidence IN ORDER; RECORDS EVERY ATTEMPT including
# failures (never dropped, never made clean); records a required-result miss as a failed command rather
# than throwing; redacts env (records env_ref NAMES, never values); and treats an EMPTY plan as the
# explicit verification-not-configured state. Uses REAL opaque cross-platform commands that exist under
# Windows/pwsh (git/pwsh/cmd) so it runs without pytest/cargo/dotnet installed.
Describe 'T019 verification-plan runner (executes a mixed plan; records every attempt)' {
    BeforeAll {
        $script:RepoRoot = (Resolve-Path "$PSScriptRoot/../../..").Path
        $env:SPECREW_MODULE_PATH = $script:RepoRoot
        Import-Module (Join-Path $script:RepoRoot 'Specrew.psd1') -Force
        . (Join-Path $script:RepoRoot 'scripts/internal/continuous-co-review/_load.ps1')
        . (Join-Path $script:RepoRoot 'scripts/internal/continuous-co-review/worktree-reviewer.ps1')   # machinery resolver for the digest
        . (Join-Path $script:RepoRoot 'scripts/internal/continuous-co-review/verification-plan-contract.ps1')
        . (Join-Path $script:RepoRoot 'scripts/internal/continuous-co-review/verification-plan-runner.ps1')

        function New-PlanRunRepo {
            $repo = Join-Path $TestDrive ([guid]::NewGuid().ToString('N'))
            New-Item -ItemType Directory -Path $repo -Force | Out-Null
            Push-Location $repo
            try {
                & git init -q 2>&1 | Out-Null
                & git config user.email 't@e.c' 2>&1 | Out-Null
                & git config user.name 'Test' 2>&1 | Out-Null
                Set-Content -LiteralPath (Join-Path $repo 'src.txt') -Value 'v0' -NoNewline
                & git add -A 2>&1 | Out-Null
                & git commit -qm base 2>&1 | Out-Null
            }
            finally { Pop-Location }
            return $repo
        }
    }

    It 'EXECUTES a 3-command mixed plan IN ORDER; digest+command_id-bound, provenance-object-tagged evidence; all_succeeded' {
        $repo = New-PlanRunRepo
        $plan = [pscustomobject]@{
            schema_version = '1.0'
            plan_id        = 'plan-run-001'
            commands       = @(
                [pscustomobject]@{ command_id = 'cmd-git'; executable = 'git'; arguments = @('--version'); provenance = [pscustomobject]@{ kind = 'project-detected'; source = 'git-detected' }; label = 'git (opaque)' },
                [pscustomobject]@{ command_id = 'cmd-pwsh'; executable = 'pwsh'; arguments = @('-NoProfile', '-Command', 'exit 0'); provenance = [pscustomobject]@{ kind = 'profile-selected'; source = 'verify-profile'; profile = 'pwsh-ci' }; label = 'pwsh (opaque)' },
                [pscustomobject]@{ command_id = 'cmd-cmd'; executable = 'cmd'; arguments = @('/c', 'echo ok'); provenance = [pscustomobject]@{ kind = 'project-config'; source = '.specrew/verify.yml' }; label = 'cmd (opaque)' }
            )
        }
        $result = Invoke-ContinuousCoReviewVerificationPlan -RepoRoot $repo -Plan $plan

        $result.state | Should -Be 'configured'
        $result.command_count | Should -Be 3
        $result.all_succeeded | Should -BeTrue -Because 'all three commands exit 0'
        @($result.evidence).Count | Should -Be 3 -Because 'one evidence record per declared command'

        $ev = @($result.evidence)
        # ORDER preserved: evidence[i] corresponds to declared command[i].
        [string]$ev[0].command.executable | Should -Be 'git'
        [string]$ev[1].command.executable | Should -Be 'pwsh'
        [string]$ev[2].command.executable | Should -Be 'cmd'
        # each carries ITS command_id and provenance OBJECT, in order.
        [string]$ev[0].command_id | Should -Be 'cmd-git'
        [string]$ev[1].command_id | Should -Be 'cmd-pwsh'
        [string]$ev[2].command_id | Should -Be 'cmd-cmd'
        [string]$ev[0].provenance.kind | Should -Be 'project-detected'
        [string]$ev[1].provenance.kind | Should -Be 'profile-selected'
        [string]$ev[1].provenance.profile | Should -Be 'pwsh-ci'
        [string]$ev[2].provenance.kind | Should -Be 'project-config'
        # each carries a digest-bound command_succeeded fact (all three exit 0).
        foreach ($e in $ev) {
            $e.command_succeeded | Should -BeTrue
            [string]$e.reviewed_digest_tree_id | Should -Match '^[0-9a-f]{40}$'
        }
        # all three ran against the SAME reviewed-tree digest (recording evidence never moved it).
        [string]$ev[1].reviewed_digest_tree_id | Should -Be ([string]$ev[0].reviewed_digest_tree_id)
        [string]$ev[2].reviewed_digest_tree_id | Should -Be ([string]$ev[0].reviewed_digest_tree_id)
    }

    It 'RECORDS EVERY ATTEMPT including a FAILURE — the failing command is not dropped and not made clean' {
        $repo = New-PlanRunRepo
        $plan = [pscustomobject]@{
            schema_version = '1.0'
            plan_id        = 'plan-run-fail'
            commands       = @(
                [pscustomobject]@{ command_id = 'ok1'; executable = 'git'; arguments = @('--version'); provenance = [pscustomobject]@{ kind = 'project-detected'; source = 'git' } },
                [pscustomobject]@{ command_id = 'boom'; executable = 'pwsh'; arguments = @('-NoProfile', '-Command', 'exit 7'); provenance = [pscustomobject]@{ kind = 'project-config'; source = 'cfg' } },
                [pscustomobject]@{ command_id = 'ok2'; executable = 'cmd'; arguments = @('/c', 'echo done'); provenance = [pscustomobject]@{ kind = 'project-config'; source = 'cfg' } }
            )
        }
        $result = Invoke-ContinuousCoReviewVerificationPlan -RepoRoot $repo -Plan $plan

        @($result.evidence).Count | Should -Be 3 -Because 'every attempt is recorded, including the failure — later commands still run'
        $result.all_succeeded | Should -BeFalse -Because 'one command failed'
        $ev = @($result.evidence)
        $ev[0].command_succeeded | Should -BeTrue
        $ev[1].command_succeeded | Should -BeFalse -Because 'exit 7'
        [int]$ev[1].exit_code | Should -Be 7
        $ev[1].command_id | Should -Be 'boom'
        $ev[2].command_succeeded | Should -BeTrue -Because 'execution continues past a failure'
    }

    It 'records a REQUIRED-result miss as a FAILED command (not thrown, not a clean claim)' {
        $repo = New-PlanRunRepo
        $plan = [pscustomobject]@{
            schema_version = '1.0'
            plan_id        = 'plan-run-req'
            commands       = @(
                [pscustomobject]@{ command_id = 'needs-result'; executable = 'pwsh'; arguments = @('-NoProfile', '-Command', 'exit 0'); result_path = 'result.json'; require_result = $true; provenance = [pscustomobject]@{ kind = 'provider-gated'; source = 'prov'; provider = 'dotnet-sdk' } }
            )
        }
        # The runner must NOT throw even though the universal runner fails loud on the missing result.
        $result = Invoke-ContinuousCoReviewVerificationPlan -RepoRoot $repo -Plan $plan
        @($result.evidence).Count | Should -Be 1
        $result.all_succeeded | Should -BeFalse
        $ev = @($result.evidence)[0]
        $ev.command_succeeded | Should -BeFalse
        $ev.command_id | Should -Be 'needs-result'
        [string]$ev.classification | Should -Be 'required-result-missing-or-invalid'
    }

    It 'REDACTS env — records only env_ref NAMES, never values' {
        $repo = New-PlanRunRepo
        $plan = [pscustomobject]@{
            schema_version = '1.0'
            plan_id        = 'plan-run-env'
            commands       = @(
                [pscustomobject]@{ command_id = 'envd'; executable = 'git'; arguments = @('--version'); env_refs = @('CI', 'SOME_TOKEN_NAME'); provenance = [pscustomobject]@{ kind = 'project-config'; source = 'cfg' } }
            )
        }
        $ev = @((Invoke-ContinuousCoReviewVerificationPlan -RepoRoot $repo -Plan $plan).evidence)[0]
        @($ev.env_refs) | Should -Contain 'CI'
        @($ev.env_refs) | Should -Contain 'SOME_TOKEN_NAME'
        # no literal env value surface exists on the record.
        $ev.PSObject.Properties.Name | Should -Not -Contain 'env'
        $ev.PSObject.Properties.Name | Should -Not -Contain 'environment'
    }

    It 'applies an ENGINE-BOUNDED timeout — a requested 0 or an absurd value both run to completion (never unlimited, never broken)' {
        $repo = New-PlanRunRepo
        $plan = [pscustomobject]@{
            schema_version = '1.0'
            plan_id        = 'plan-run-timeout'
            commands       = @(
                [pscustomobject]@{ command_id = 'zero'; executable = 'git'; arguments = @('--version'); timeout_seconds = 0; provenance = [pscustomobject]@{ kind = 'project-config'; source = 'cfg' } },
                [pscustomobject]@{ command_id = 'absurd'; executable = 'git'; arguments = @('--version'); timeout_seconds = 99999999; provenance = [pscustomobject]@{ kind = 'project-config'; source = 'cfg' } }
            )
        }
        $result = Invoke-ContinuousCoReviewVerificationPlan -RepoRoot $repo -Plan $plan
        $result.all_succeeded | Should -BeTrue
        foreach ($e in @($result.evidence)) { $e.timed_out | Should -BeFalse }
    }

    It 'an EMPTY plan runs NOTHING and returns the explicit verification-not-configured state (no fabricated success)' {
        $repo = New-PlanRunRepo
        $result = Invoke-ContinuousCoReviewVerificationPlan -RepoRoot $repo -Plan ([pscustomobject]@{ schema_version = '1.0'; plan_id = 'plan-empty'; commands = @() })
        $result.state | Should -Be 'verification-not-configured'
        $result.command_count | Should -Be 0
        @($result.evidence).Count | Should -Be 0
        $result.all_succeeded | Should -BeFalse -Because 'nothing ran; not-configured is never a fabricated pass'
        # PROOF nothing executed: the universal runner writes evidence under .specrew/review/test-evidence
        # only when a command runs; an unconfigured plan must leave NO such record.
        Test-Path -LiteralPath (Join-Path $repo '.specrew/review/test-evidence') | Should -BeFalse -Because 'no command ran, so no digest-bound evidence was recorded'
    }

    It 'T019 evidence-join accepts the real digest-bound records and REFUSES a digest-mismatch' {
        $repo = New-PlanRunRepo
        $plan = [pscustomobject]@{
            schema_version = '1.0'
            plan_id        = 'plan-join-run'
            commands       = @(
                [pscustomobject]@{ command_id = 'j1'; executable = 'git'; arguments = @('--version'); provenance = [pscustomobject]@{ kind = 'project-detected'; source = 'git' } },
                [pscustomobject]@{ command_id = 'j2'; executable = 'cmd'; arguments = @('/c', 'echo ok'); provenance = [pscustomobject]@{ kind = 'project-config'; source = 'cfg' } }
            )
        }
        $result = Invoke-ContinuousCoReviewVerificationPlan -RepoRoot $repo -Plan $plan
        $digest = [string](Get-ContinuousCoReviewReviewedStateDigest -RepoRoot $repo).tree_id

        $joined = @(Test-ContinuousCoReviewPlanEvidenceInjectable -PlanEvidence $result.evidence -Plan $plan -CurrentDigest $digest)
        @($joined).Count | Should -Be 2
        foreach ($j in $joined) { $j.injectable | Should -BeTrue; $j.classification | Should -Be 'exact-digest-command-joined' }

        $mismatched = @(Test-ContinuousCoReviewPlanEvidenceInjectable -PlanEvidence $result.evidence -Plan $plan -CurrentDigest 'deadbeefdeadbeefdeadbeefdeadbeefdeadbeef')
        foreach ($j in $mismatched) { $j.injectable | Should -BeFalse; $j.classification | Should -Be 'digest-mismatch-not-injected' }

        # an UNJOINABLE record (a command_id not in the plan) is refused even at the right digest.
        $foreign = [pscustomobject]@{ command_id = 'not-in-plan'; reviewed_digest_tree_id = $digest }
        (@(Test-ContinuousCoReviewPlanEvidenceInjectable -PlanEvidence @($foreign) -Plan $plan -CurrentDigest $digest))[0].classification |
            Should -Be 'unjoinable-no-matching-command'
    }
}
