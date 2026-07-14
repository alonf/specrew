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

        # The opaque third command, PER PLATFORM (paired cross-platform evidence, maintainer 2026-07-14):
        # cmd.exe on Windows, sh on Linux/macOS - both bare names the pre-spawn resolver must resolve.
        $script:ShellExe = if ($IsWindows) { 'cmd' } else { 'sh' }
        $script:ShellEchoArgs = if ($IsWindows) { @('/c', 'echo ok') } else { @('-c', 'echo ok') }
        $script:ShellDoneArgs = if ($IsWindows) { @('/c', 'echo done') } else { @('-c', 'echo done') }

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
                [pscustomobject]@{ command_id = 'cmd-shell'; executable = $script:ShellExe; arguments = $script:ShellEchoArgs; provenance = [pscustomobject]@{ kind = 'project-config'; source = '.specrew/verify.yml' }; label = 'shell (opaque)' }
            )
        }
        $result = Invoke-ContinuousCoReviewVerificationPlan -RepoRoot $repo -Plan $plan

        $result.state | Should -Be 'configured'
        $result.command_count | Should -Be 3
        $result.all_succeeded | Should -BeTrue -Because 'all three commands exit 0'
        @($result.evidence).Count | Should -Be 3 -Because 'one evidence record per declared command'

        $ev = @($result.evidence)
        # ORDER preserved: evidence[i] corresponds to declared command[i]. The record carries the RESOLVED
        # full path (what actually executed) + the supplier-declared name (2026-07-14: pre-spawn resolution).
        [string]$ev[0].command.declared_executable | Should -Be 'git'
        [string]$ev[1].command.declared_executable | Should -Be 'pwsh'
        [string]$ev[2].command.declared_executable | Should -Be $script:ShellExe
        foreach ($e in $ev) { [System.IO.Path]::IsPathRooted([string]$e.command.executable) | Should -BeTrue }
        # each carries ITS command_id and provenance OBJECT, in order.
        [string]$ev[0].command_id | Should -Be 'cmd-git'
        [string]$ev[1].command_id | Should -Be 'cmd-pwsh'
        [string]$ev[2].command_id | Should -Be 'cmd-shell'
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
                [pscustomobject]@{ command_id = 'ok2'; executable = $script:ShellExe; arguments = $script:ShellDoneArgs; provenance = [pscustomobject]@{ kind = 'project-config'; source = 'cfg' } }
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

    It 'a SCHEMA-INVALID plan fails LOUDLY as verification-plan-invalid - never downgraded to the benign not-configured state (review finding f2, run 20260714T190233598)' {
        $repo = New-PlanRunRepo
        # {commands:[]} with NO schema_version: pre-fix the state gate ran first and classified this as the
        # benign 'not configured' state instead of a loud contract violation.
        $r1 = Invoke-ContinuousCoReviewVerificationPlan -RepoRoot $repo -Plan ([pscustomobject]@{ commands = @() })
        [string]$r1.state | Should -Be 'verification-plan-invalid'
        [string]$r1.reason | Should -Match 'schema_version'
        @($r1.evidence).Count | Should -Be 0
        # an ALL-INVALID commands list is a schema violation, not an unconfigured seam.
        $r2 = Invoke-ContinuousCoReviewVerificationPlan -RepoRoot $repo -Plan ([pscustomobject]@{ schema_version = '1.0'; plan_id = 'p'; commands = @([pscustomobject]@{ command_id = 'a' }) })
        [string]$r2.state | Should -Be 'verification-plan-invalid'
        @($r2.evidence).Count | Should -Be 0
        # a NULL plan stays the explicit no-supplier state.
        [string](Invoke-ContinuousCoReviewVerificationPlan -RepoRoot $repo -Plan $null).state | Should -Be 'verification-not-configured'
    }

    It 'a contract-valid timeout BEYOND Int32 (and beyond Int64) CLAMPS to engine policy and the command still executes - never an overflow abort with no attempt record (review finding f2, run 20260714T193411985)' {
        $repo = New-PlanRunRepo
        $plan = [pscustomobject]@{
            schema_version = '1.0'
            plan_id        = 'plan-wide-timeout'
            commands       = @(
                [pscustomobject]@{ command_id = 'int32max+1'; executable = 'pwsh'; arguments = @('-NoProfile', '-Command', 'exit 0'); timeout_seconds = 2147483648; provenance = [pscustomobject]@{ kind = 'project-config'; source = 'cfg' } },
                [pscustomobject]@{ command_id = 'beyond-int64'; executable = 'pwsh'; arguments = @('-NoProfile', '-Command', 'exit 0'); timeout_seconds = ([System.Numerics.BigInteger]::Parse('9223372036854775808')); provenance = [pscustomobject]@{ kind = 'project-config'; source = 'cfg' } }
            )
        }
        $result = Invoke-ContinuousCoReviewVerificationPlan -RepoRoot $repo -Plan $plan
        $result.all_succeeded | Should -BeTrue -Because 'over-policy timeouts CLAMP per FR-048; they never throw the plan away'
        @($result.evidence).Count | Should -Be 2
        foreach ($e in @($result.evidence)) { $e.command_succeeded | Should -BeTrue; $e.timed_out | Should -BeFalse }
        # and the resolver itself clamps both boundaries deterministically.
        $max = Get-ContinuousCoReviewMaxVerificationTimeoutSeconds
        (Resolve-ContinuousCoReviewVerificationTimeout -Requested 2147483648).effective_seconds | Should -Be $max
        (Resolve-ContinuousCoReviewVerificationTimeout -Requested ([System.Numerics.BigInteger]::Parse('9223372036854775808'))).effective_seconds | Should -Be $max
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
                [pscustomobject]@{ command_id = 'j2'; executable = $script:ShellExe; arguments = $script:ShellEchoArgs; provenance = [pscustomobject]@{ kind = 'project-config'; source = 'cfg' } }
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

    It 'ANCHORS working_directory + result_path to RepoRoot — CWD-independent execution; result_path never re-anchors to the working directory (finding f4, run 20260714T123137002)' {
        $repo = New-PlanRunRepo
        New-Item -ItemType Directory -Path (Join-Path $repo 'subdir') -Force | Out-Null
        $pwshExe = (Get-Process -Id $PID).Path
        # The command runs with working_directory='subdir' (repo-relative), proves its own cwd into
        # subdir/cwd.txt, and writes the REQUIRED result to '../rootresult.json' — i.e. to RepoRoot —
        # matching the schema's REPO-relative result_path 'rootresult.json'.
        $cmdText = 'Set-Content -LiteralPath cwd.txt -Value ((Get-Location).Path) -NoNewline; ' +
        '@{ schema_version = ''1.0''; result = ''passed'' } | ConvertTo-Json | Set-Content -LiteralPath ../rootresult.json'
        $plan = [pscustomobject]@{
            schema_version = '1.0'
            plan_id        = 'plan-anchor'
            commands       = @(
                [pscustomobject]@{ command_id = 'anchored'; executable = $pwshExe; arguments = @('-NoProfile', '-Command', $cmdText); working_directory = 'subdir'; result_path = 'rootresult.json'; require_result = $true; provenance = [pscustomobject]@{ kind = 'project-config'; source = 'cfg' } }
            )
        }
        # Invoke from OUTSIDE the repository: the old CWD-relative resolution would look for 'subdir'
        # under the CALLER cwd (and 'rootresult.json' under the working directory) and fail.
        Push-Location $TestDrive
        try { $result = Invoke-ContinuousCoReviewVerificationPlan -RepoRoot $repo -Plan $plan }
        finally { Pop-Location }
        $result.all_succeeded | Should -BeTrue -Because 'both paths anchor to RepoRoot, independent of the caller cwd'
        $ev = @($result.evidence)[0]
        $ev.command_succeeded | Should -BeTrue
        [string]$ev.test_result.result | Should -Be 'passed' -Because 'the REQUIRED result was found at RepoRoot/rootresult.json, not subdir/rootresult.json'
        $observedCwd = Get-Content -LiteralPath (Join-Path $repo 'subdir/cwd.txt') -Raw
        ([System.IO.Path]::GetFullPath($observedCwd.Trim())) | Should -Be ([System.IO.Path]::GetFullPath((Join-Path $repo 'subdir'))) -Because 'the child ran in RepoRoot/subdir'
    }

    It 'env_refs have EXECUTION semantics — a declared name is visible in the child; an unlisted ambient secret is ABSENT (finding f2, run 20260714T123137002)' {
        $repo = New-PlanRunRepo
        $pwshExe = (Get-Process -Id $PID).Path
        $env:CCR_TEST_ALLOWED = 'allowed-value-123'
        $env:CCR_TEST_SECRET = 'ambient-sentinel-secret-777'
        try {
            $cmdText = 'Set-Content -LiteralPath envprobe.txt -Value "allowed=[$env:CCR_TEST_ALLOWED] secret=[$env:CCR_TEST_SECRET]" -NoNewline'
            $plan = [pscustomobject]@{
                schema_version = '1.0'
                plan_id        = 'plan-env-exec'
                commands       = @(
                    [pscustomobject]@{ command_id = 'envx'; executable = $pwshExe; arguments = @('-NoProfile', '-Command', $cmdText); env_refs = @('CCR_TEST_ALLOWED'); provenance = [pscustomobject]@{ kind = 'project-config'; source = 'cfg' } }
                )
            }
            $result = Invoke-ContinuousCoReviewVerificationPlan -RepoRoot $repo -Plan $plan
            @($result.evidence)[0].command_succeeded | Should -BeTrue
            $probe = Get-Content -LiteralPath (Join-Path $repo 'envprobe.txt') -Raw
            $probe | Should -Match 'allowed=\[allowed-value-123\]' -Because 'a declared env_ref passes through to the child at spawn'
            $probe | Should -Match 'secret=\[\]' -Because 'an unlisted ambient value is structurally ABSENT from the child'
            # and the durable store never carries the values, listed or not.
            $storeDir = Join-Path $repo '.specrew/review/test-evidence'
            $raw = Get-Content -LiteralPath (@(Get-ChildItem -LiteralPath $storeDir -Filter '*.json')[0].FullName) -Raw
            $raw | Should -Not -Match 'allowed-value-123'
            $raw | Should -Not -Match 'ambient-sentinel-secret-777'
        }
        finally {
            Remove-Item Env:CCR_TEST_ALLOWED -ErrorAction SilentlyContinue
            Remove-Item Env:CCR_TEST_SECRET -ErrorAction SilentlyContinue
        }
    }

    It 'ENGINE BASELINE EVIDENCE (paired, cross-platform): a plan child launches and succeeds with the EMPTY-map constructed environment — the runtime proof behind the (empty) normative baseline (finding f1, run 20260714T130410888)' {
        $repo = New-PlanRunRepo
        $pwshExe = (Get-Process -Id $PID).Path
        # No env_refs declared -> the child receives EXACTLY the engine baseline (currently empty). The
        # command still launching + exiting 0 IS the evidence that the baseline needs nothing more on this
        # platform; this test runs on Windows AND Linux (the paired evidence the maintainer required).
        $plan = [pscustomobject]@{
            schema_version = '1.0'
            plan_id        = 'plan-baseline-evidence'
            commands       = @(
                [pscustomobject]@{ command_id = 'bare'; executable = $pwshExe; arguments = @('-NoProfile', '-NonInteractive', '-Command', 'Set-Content -LiteralPath launched.txt -Value ok -NoNewline; exit 0'); provenance = [pscustomobject]@{ kind = 'project-config'; source = 'cfg' } }
            )
        }
        $result = Invoke-ContinuousCoReviewVerificationPlan -RepoRoot $repo -Plan $plan
        $result.all_succeeded | Should -BeTrue -Because 'the engine baseline (empty) is sufficient to launch a child on this platform - runtime evidence, not assertion'
        Get-Content -LiteralPath (Join-Path $repo 'launched.txt') -Raw | Should -Be 'ok'
        # And the baseline function itself is EMPTY on this platform - any future addition demands new evidence.
        @(Get-ContinuousCoReviewVerificationEngineBaseline).Count | Should -Be 0
        # The constructed map carries ONLY declared refs that exist ambiently - nothing implicit.
        @((Get-ContinuousCoReviewVerificationChildEnvironment -EnvRefs @()).Keys).Count | Should -Be 0
    }

    It 'EXCLUDES user-identity + infrastructure ambient values from the child — HOME/USERPROFILE/APPDATA/LOCALAPPDATA/TEMP absent; a parent-PATH sentinel does NOT flow (maintainer decision 2026-07-14)' {
        $repo = New-PlanRunRepo
        $pwshExe = (Get-Process -Id $PID).Path
        $sentinelDir = 'ccr-path-sentinel-dir-5150'
        $origPath = [System.Environment]::GetEnvironmentVariable('PATH')
        [System.Environment]::SetEnvironmentVariable('PATH', ($origPath + [System.IO.Path]::PathSeparator + $sentinelDir))
        try {
            # Probe the child's view: the maintainer-excluded identity paths must be ABSENT, and the parent's
            # PATH content (carrying the sentinel) must NOT flow (the child may self-synthesize its own PATH;
            # what is forbidden is INHERITING the ambient one).
            $cmdText = 'Set-Content -LiteralPath childenv.txt -Value ("h=[$env:HOME] u=[$env:USERPROFILE] a=[$env:APPDATA] l=[$env:LOCALAPPDATA] t=[$env:TEMP] p=[$env:PATH]") -NoNewline'
            $plan = [pscustomobject]@{
                schema_version = '1.0'
                plan_id        = 'plan-exclusions'
                commands       = @(
                    [pscustomobject]@{ command_id = 'probe'; executable = $pwshExe; arguments = @('-NoProfile', '-NonInteractive', '-Command', $cmdText); provenance = [pscustomobject]@{ kind = 'project-config'; source = 'cfg' } }
                )
            }
            $result = Invoke-ContinuousCoReviewVerificationPlan -RepoRoot $repo -Plan $plan
            @($result.evidence)[0].command_succeeded | Should -BeTrue
            $probe = Get-Content -LiteralPath (Join-Path $repo 'childenv.txt') -Raw
            $probe | Should -Match 'h=\[\]' -Because 'HOME is excluded from the automatic baseline (maintainer ruling)'
            $probe | Should -Match 'u=\[\]' -Because 'USERPROFILE is excluded'
            $probe | Should -Match 'a=\[\]' -Because 'APPDATA is excluded'
            $probe | Should -Match 'l=\[\]' -Because 'LOCALAPPDATA is excluded'
            $probe | Should -Match 't=\[\]' -Because 'TEMP is a tool concern, declared via env_refs when needed'
            $probe | Should -Not -Match 'ccr-path-sentinel-dir-5150' -Because 'the ambient parent PATH does not flow to the child (the executable was resolved BEFORE spawn)'
        }
        finally { [System.Environment]::SetEnvironmentVariable('PATH', $origPath) }
    }

    It 'RESOLVES a bare-name executable BEFORE spawn (ambient PATH, full path recorded with the declared name); an UNRESOLVABLE executable is a RECORDED failure and the plan continues' {
        $repo = New-PlanRunRepo
        $plan = [pscustomobject]@{
            schema_version = '1.0'
            plan_id        = 'plan-resolution'
            commands       = @(
                [pscustomobject]@{ command_id = 'ghost'; executable = 'ccr-definitely-not-a-real-executable-0451'; arguments = @(); provenance = [pscustomobject]@{ kind = 'project-config'; source = 'cfg' } },
                [pscustomobject]@{ command_id = 'bare-pwsh'; executable = 'pwsh'; arguments = @('-NoProfile', '-NonInteractive', '-Command', 'exit 0'); provenance = [pscustomobject]@{ kind = 'project-config'; source = 'cfg' } }
            )
        }
        $result = Invoke-ContinuousCoReviewVerificationPlan -RepoRoot $repo -Plan $plan
        @($result.evidence).Count | Should -Be 2 -Because 'the unresolvable command is RECORDED, never dropped; the next command still runs'
        $result.all_succeeded | Should -BeFalse
        $ev = @($result.evidence)
        $ev[0].command_succeeded | Should -BeFalse
        [string]$ev[0].classification | Should -Be 'executable-not-resolvable'
        $ev[1].command_succeeded | Should -BeTrue -Because 'the bare name resolved to a full path against the AMBIENT parent environment before spawn'
        # the durable record carries the RESOLVED full path + the supplier-declared name.
        [System.IO.Path]::IsPathRooted([string]$ev[1].command.executable) | Should -BeTrue
        [string]$ev[1].command.declared_executable | Should -Be 'pwsh'
    }

    It 'CASE-VARIANT repo-relative EXECUTABLE containment on a case-sensitive platform: ../Repo/tool is refused (review finding f1, run 20260714T172315119)' -Skip:$IsWindows {
        $repo = New-PlanRunRepo
        $parent = Split-Path -Parent $repo
        # the sibling differs from the repo leaf ONLY BY CASE (guid 'N' format is lowercase hex): under the
        # pre-fix OrdinalIgnoreCase containment '../<LEAF-UPPERCASED>/tool.sh' canonicalized to a path that
        # READ as inside the repo root, so a REAL executable outside the repository would resolve + execute.
        $sibling = Join-Path $parent ((Split-Path -Leaf $repo).ToUpperInvariant())
        New-Item -ItemType Directory -Path $sibling -Force | Out-Null
        $tool = Join-Path $sibling 'tool.sh'
        Set-Content -LiteralPath $tool -Value "#!/bin/sh`ntouch escaped.txt`nexit 0" -NoNewline
        & chmod +x $tool 2>&1 | Out-Null
        $rel = '../' + (Split-Path -Leaf $sibling) + '/tool.sh'
        $plan = [pscustomobject]@{
            schema_version = '1.0'
            plan_id        = 'plan-case-exe'
            commands       = @(
                [pscustomobject]@{ command_id = 'esc'; executable = $rel; arguments = @(); provenance = [pscustomobject]@{ kind = 'project-config'; source = 'cfg' } }
            )
        }
        $result = Invoke-ContinuousCoReviewVerificationPlan -RepoRoot $repo -Plan $plan
        $result.all_succeeded | Should -BeFalse
        $ev = @($result.evidence)[0]
        $ev.command_succeeded | Should -BeFalse
        [string]$ev.classification | Should -Be 'executable-not-resolvable' -Because 'a repo-relative executable escaping via a path outside the root is refused before spawn'
        Test-Path -LiteralPath (Join-Path $sibling 'escaped.txt') | Should -BeFalse -Because 'the escaping tool never executed'
    }

    It 'plan-level DiagnosticDisclosure: applied ONLY to the named command_id; a malformed disclosure FAILS FAST with zero commands run' {
        $repo = New-PlanRunRepo
        $pwshExe = (Get-Process -Id $PID).Path
        $say = '[Console]::Out.WriteLine(''diagnostic-detail-for-reviewer''); exit 0'
        $plan = [pscustomobject]@{
            schema_version = '1.0'
            plan_id        = 'plan-disclosure'
            commands       = @(
                [pscustomobject]@{ command_id = 'quiet'; executable = $pwshExe; arguments = @('-NoProfile', '-Command', $say); provenance = [pscustomobject]@{ kind = 'project-config'; source = 'cfg' } },
                [pscustomobject]@{ command_id = 'disclosed'; executable = $pwshExe; arguments = @('-NoProfile', '-Command', $say); provenance = [pscustomobject]@{ kind = 'project-config'; source = 'cfg' } }
            )
        }
        $disclosure = [pscustomobject]@{ authorized_by = 'Alon Fliess'; reason = 'reviewer cannot conclude without the failing output'; command_id = 'disclosed' }
        $result = Invoke-ContinuousCoReviewVerificationPlan -RepoRoot $repo -Plan $plan -DiagnosticDisclosure $disclosure
        $result.all_succeeded | Should -BeTrue
        $ev = @($result.evidence)
        [string]$ev[0].stdout_meta.tail_disclosure | Should -Be 'suppressed' -Because 'the disclosure is scoped: the OTHER command stays private'
        [string]$ev[1].stdout_meta.tail_disclosure | Should -Be 'authorized-diagnostic'
        [string]$ev[1].stdout_meta.truncated_tail | Should -Match 'diagnostic-detail-for-reviewer'
        [string]$ev[1].diagnostic_disclosure.authorized_by | Should -Be 'Alon Fliess'
        # MALFORMED disclosure -> fail-fast, ZERO side effects (mirrors the malformed-identity gate).
        $repo2 = New-PlanRunRepo
        $plan2 = [pscustomobject]@{
            schema_version = '1.0'
            plan_id        = 'plan-disclosure-bad'
            commands       = @(
                [pscustomobject]@{ command_id = 'c1'; executable = $pwshExe; arguments = @('-NoProfile', '-Command', 'Set-Content -LiteralPath ran.txt -Value x'); provenance = [pscustomobject]@{ kind = 'project-config'; source = 'cfg' } }
            )
        }
        { Invoke-ContinuousCoReviewVerificationPlan -RepoRoot $repo2 -Plan $plan2 -DiagnosticDisclosure ([pscustomobject]@{ reason = 'r'; command_id = 'c1' }) } |
            Should -Throw -ExpectedMessage '*DiagnosticDisclosure*'
        Test-Path -LiteralPath (Join-Path $repo2 'ran.txt') | Should -BeFalse -Because 'a malformed authorization runs ZERO commands'
    }

    It 'persists NO output text for a plan command — a printed sentinel is absent from the digest-keyed store (finding f3, run 20260714T123137002)' {
        $repo = New-PlanRunRepo
        $pwshExe = (Get-Process -Id $PID).Path
        # The sentinels are ASSEMBLED at runtime so they exist ONLY in the command's OUTPUT — never as an
        # argument literal (declared arguments are plan content and are recorded by design).
        $cmdText = '[Console]::Out.WriteLine((''plan-stdout'' + ''-sentinel-'' + ''0451'')); [Console]::Error.WriteLine((''plan-stderr'' + ''-sentinel-'' + ''0452'')); exit 0'
        $plan = [pscustomobject]@{
            schema_version = '1.0'
            plan_id        = 'plan-no-tail'
            commands       = @(
                [pscustomobject]@{ command_id = 'printer'; executable = $pwshExe; arguments = @('-NoProfile', '-Command', $cmdText); provenance = [pscustomobject]@{ kind = 'project-config'; source = 'cfg' } }
            )
        }
        $result = Invoke-ContinuousCoReviewVerificationPlan -RepoRoot $repo -Plan $plan
        $result.all_succeeded | Should -BeTrue
        $storeDir = Join-Path $repo '.specrew/review/test-evidence'
        $raw = Get-Content -LiteralPath (@(Get-ChildItem -LiteralPath $storeDir -Filter '*.json')[0].FullName) -Raw
        $raw | Should -Not -Match 'plan-stdout-sentinel-0451' -Because 'supplier-declared command output is SUPPRESSED, not persisted'
        $raw | Should -Not -Match 'plan-stderr-sentinel-0452'
        # the integrity facts remain: byte counts + hashes describe the raw output.
        $rec = $raw | ConvertFrom-Json
        [int](@($rec.runs)[0].stdout_meta.byte_count) | Should -BeGreaterThan 0
        [string](@($rec.runs)[0].stdout_meta.truncated_tail) | Should -Be ''
    }

    It 'two plan commands with the SAME invocation but DIFFERENT command_ids persist as separately joinable durable runs (finding f5, run 20260714T123137002)' {
        $repo = New-PlanRunRepo
        $plan = [pscustomobject]@{
            schema_version = '1.0'
            plan_id        = 'plan-twin'
            commands       = @(
                [pscustomobject]@{ command_id = 'twin-a'; executable = 'git'; arguments = @('--version'); provenance = [pscustomobject]@{ kind = 'project-detected'; source = 'git' } },
                [pscustomobject]@{ command_id = 'twin-b'; executable = 'git'; arguments = @('--version'); provenance = [pscustomobject]@{ kind = 'project-config'; source = 'cfg' } }
            )
        }
        $result = Invoke-ContinuousCoReviewVerificationPlan -RepoRoot $repo -Plan $plan
        $result.all_succeeded | Should -BeTrue
        @($result.evidence).Count | Should -Be 2

        # RELOAD the durable digest-keyed store — the identity must survive serialization, not live only
        # on the in-memory return.
        $digest = [string](Get-ContinuousCoReviewReviewedStateDigest -RepoRoot $repo).tree_id
        $rec = Get-Content -LiteralPath (Join-Path $repo ".specrew/review/test-evidence/$digest.json") -Raw | ConvertFrom-Json
        @($rec.runs).Count | Should -Be 2 -Because 'same invocation + different command_id must NOT clobber'
        @(@($rec.runs) | ForEach-Object { [string]$_.command_id } | Sort-Object) | Should -Be @('twin-a', 'twin-b')
        foreach ($r in @($rec.runs)) {
            [string]$r.provenance.kind | Should -Not -BeNullOrEmpty -Because 'provenance survives serialization'
            [string]$r.reviewed_digest_tree_id | Should -Be $digest
        }
        # and the T019 join validator joins BOTH persisted records at the exact digest.
        $joined = @(Test-ContinuousCoReviewPlanEvidenceInjectable -PlanEvidence @($rec.runs) -Plan $plan -CurrentDigest $digest)
        @($joined).Count | Should -Be 2
        foreach ($j in $joined) { $j.injectable | Should -BeTrue; $j.classification | Should -Be 'exact-digest-command-joined' }
    }

    It 'SYNTHETIC failure records PERSIST to the digest-keyed store - every attempt is durable, joinable reviewer evidence (review finding f4, run 20260714T182921446)' {
        $repo = New-PlanRunRepo
        # Every RUNNABLE-plan synthetic classification (a structurally-invalid command cannot ride a runnable
        # plan - the whole-plan fail-fast gate precedes the per-command branch): pre-spawn resolution failure,
        # require_result with no result_path, and a runtime required-result miss (the recorder's fail-loud
        # caught + recorded as a synthetic failure).
        $plan = [pscustomobject]@{
            schema_version = '1.0'
            plan_id        = 'plan-synthetic-durable'
            commands       = @(
                [pscustomobject]@{ command_id = 'ghost'; executable = 'ccr-no-such-exe-7719'; arguments = @(); provenance = [pscustomobject]@{ kind = 'project-config'; source = 'cfg' } },
                [pscustomobject]@{ command_id = 'noresult'; executable = 'pwsh'; arguments = @('-NoProfile', '-Command', 'exit 0'); require_result = $true; provenance = [pscustomobject]@{ kind = 'project-config'; source = 'cfg' } },
                [pscustomobject]@{ command_id = 'missres'; executable = 'pwsh'; arguments = @('-NoProfile', '-Command', 'exit 0'); result_path = 'never-written.json'; require_result = $true; provenance = [pscustomobject]@{ kind = 'project-config'; source = 'cfg' } }
            )
        }
        $result = Invoke-ContinuousCoReviewVerificationPlan -RepoRoot $repo -Plan $plan
        @($result.evidence).Count | Should -Be 3
        $result.all_succeeded | Should -BeFalse

        # RELOAD from the DURABLE digest-keyed store - the in-memory return is not the reviewer's evidence.
        $digest = [string](Get-ContinuousCoReviewReviewedStateDigest -RepoRoot $repo).tree_id
        $rec = Get-Content -LiteralPath (Join-Path $repo ".specrew/review/test-evidence/$digest.json") -Raw | ConvertFrom-Json
        @($rec.runs).Count | Should -Be 3 -Because 'every attempted-but-failed command persists, never only the in-memory return'
        $byId = @{}; foreach ($r in @($rec.runs)) { $byId[[string]$r.command_id] = $r }
        [string]$byId['ghost'].classification | Should -Be 'executable-not-resolvable'
        [string]$byId['noresult'].classification | Should -Be 'required-result-missing-or-invalid'
        [string]$byId['missres'].classification | Should -Be 'required-result-missing-or-invalid'
        foreach ($r in @($rec.runs)) { $r.command_succeeded | Should -BeFalse; [string]$r.reviewed_digest_tree_id | Should -Be $digest }
        # the persisted failures JOIN at the exact digest and the PRODUCTION lookup accepts the record.
        $joined = @(Test-ContinuousCoReviewPlanEvidenceInjectable -PlanEvidence @($rec.runs) -Plan $plan -CurrentDigest $digest)
        foreach ($j in $joined) { $j.injectable | Should -BeTrue }
        (Get-ContinuousCoReviewTestEvidenceForDigest -RepoRoot $repo -DigestTreeId $digest) | Should -Not -BeNullOrEmpty
    }

    It 'the selected-plan RESOLVER: absent -> unavailable; schema-invalid -> unavailable (loud, never silently none or silently used); valid -> available (maintainer wiring directive 2026-07-15)' {
        $repo = New-PlanRunRepo
        $r1 = Get-ContinuousCoReviewSelectedVerificationPlan -RepoRoot $repo
        $r1.available | Should -BeFalse
        [string]$r1.reason | Should -Match 'supplier'
        New-Item -ItemType Directory -Path (Join-Path $repo '.specrew') -Force | Out-Null
        Set-Content -LiteralPath (Join-Path $repo '.specrew/verification-plan.json') -Value '{ "plan_id": "p" }' -Encoding UTF8
        $r2 = Get-ContinuousCoReviewSelectedVerificationPlan -RepoRoot $repo
        $r2.available | Should -BeFalse -Because 'a schema-invalid supplier output is refused - never silently none, never silently used'
        [string]$r2.reason | Should -Match 'schema-invalid'
        '{ "schema_version": "1.0", "plan_id": "p", "commands": [ { "command_id": "c1", "executable": "pwsh", "provenance": { "kind": "project-config", "source": "cfg" } } ] }' |
            Set-Content -LiteralPath (Join-Path $repo '.specrew/verification-plan.json') -Encoding UTF8
        $r3 = Get-ContinuousCoReviewSelectedVerificationPlan -RepoRoot $repo
        $r3.available | Should -BeTrue
        [string]$r3.plan.plan_id | Should -Be 'p'
        [string]$r3.source | Should -Match 'verification-plan\.json'
    }

    It 'FAIL-FAST: a DUPLICATE command_id is rejected at validation BEFORE any command runs — ZERO side effects (maintainer decision 2026-07-13)' {
        $repo = New-PlanRunRepo
        # Both commands are individually valid + would create a sentinel file if executed; the plan is structurally
        # invalid (duplicate command_id 'dup'), so the runner must reject it fail-fast and run NOTHING.
        $plan = [pscustomobject]@{
            schema_version = '1.0'
            plan_id        = 'plan-dup'
            commands       = @(
                [pscustomobject]@{ command_id = 'dup'; executable = 'pwsh'; arguments = @('-NoProfile', '-Command', 'Set-Content -LiteralPath ran-a.txt -Value a'); provenance = [pscustomobject]@{ kind = 'project-config'; source = 'cfg' } },
                [pscustomobject]@{ command_id = 'dup'; executable = 'pwsh'; arguments = @('-NoProfile', '-Command', 'Set-Content -LiteralPath ran-b.txt -Value b'); provenance = [pscustomobject]@{ kind = 'project-config'; source = 'cfg' } }
            )
        }
        $result = Invoke-ContinuousCoReviewVerificationPlan -RepoRoot $repo -Plan $plan
        $result.state | Should -Be 'verification-plan-invalid'
        [string]$result.reason | Should -Match 'duplicate command_id'
        @($result.evidence).Count | Should -Be 0 -Because 'a malformed identity graph runs ZERO commands'
        $result.all_succeeded | Should -BeFalse
        # PROOF of zero side effects: neither command's sentinel exists, and no digest-bound evidence was recorded.
        Test-Path -LiteralPath (Join-Path $repo 'ran-a.txt') | Should -BeFalse
        Test-Path -LiteralPath (Join-Path $repo 'ran-b.txt') | Should -BeFalse
        Test-Path -LiteralPath (Join-Path $repo '.specrew/review/test-evidence') | Should -BeFalse -Because 'no command ran, so no evidence was recorded'
    }
}
