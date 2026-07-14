$ErrorActionPreference = 'Stop'

# T019 / FR-048 (amended 2026-07-13) — the PURE verification-plan CONTRACT. These tests exercise the
# framework-NEUTRAL, order-preserving contract functions against inline cases and the mixed-technology /
# empty / bad / path-escape / duplicate-id / env-refs / evidence-join fixture family. Nothing here
# touches a live runtime path (the only I/O is path-safety's symlink dereference against TestDrive).
Describe 'T019 verification-plan contract (framework-neutral, ordered, FR-048 amended)' {
    BeforeAll {
        Set-StrictMode -Version Latest
        $script:RepoRoot = (Resolve-Path "$PSScriptRoot/../../..").Path
        . (Join-Path $script:RepoRoot 'scripts/internal/continuous-co-review/review-identity-contracts.ps1')
        . (Join-Path $script:RepoRoot 'scripts/internal/continuous-co-review/verification-plan-contract.ps1')
        $script:FixtureDir = Join-Path $script:RepoRoot 'tests/continuous-co-review/fixtures/t019'
        function Get-Fixture([string]$name) { Get-Content -LiteralPath (Join-Path $script:FixtureDir $name) -Raw | ConvertFrom-Json }
        # a reusable valid provenance object for inline cases that are not testing provenance itself.
        function New-Prov { param([string]$Kind = 'project-config', [string]$Source = 'src') [pscustomobject]@{ kind = $Kind; source = $Source } }
        # Create a REAL reparse link (junction, then symlink) and VERIFY it dereferences: on Linux, 'Junction'
        # can produce a plain non-link artifact instead of failing, which would vacuously pass every safety
        # assertion. Only a verified link counts as made; a non-link artifact is removed before the next attempt.
        function New-EscapeLink {
            param([Parameter(Mandatory)][string]$LinkPath, [Parameter(Mandatory)][string]$Target)
            foreach ($kind in @('Junction', 'SymbolicLink')) {
                try {
                    New-Item -ItemType $kind -Path $LinkPath -Target $Target -ErrorAction Stop | Out-Null
                    $it = Get-Item -LiteralPath $LinkPath -Force -ErrorAction Stop
                    if ($null -ne $it.ResolveLinkTarget($true)) { return $true }
                }
                catch { $null = $_ }
                Remove-Item -LiteralPath $LinkPath -Force -Recurse -ErrorAction SilentlyContinue
            }
            return $false
        }
    }

    Context 'provenance vocabulary + auditable object' {
        It 'exposes exactly the four canonical provenance KIND values' {
            $vals = Get-ContinuousCoReviewVerificationProvenanceValues
            @($vals).Count | Should -Be 4
            foreach ($k in 'project-config', 'project-detected', 'profile-selected', 'provider-gated') { $vals | Should -Contain $k }
        }
        It 'accepts each of the four kinds and rejects an unknown one' {
            foreach ($k in 'project-config', 'project-detected', 'profile-selected', 'provider-gated') {
                (Test-ContinuousCoReviewVerificationProvenance -Provenance ([pscustomobject]@{ kind = $k; source = 's'; provider = 'p'; profile = 'pr' })).valid |
                    Should -BeTrue -Because "kind '$k' is valid"
            }
            (Test-ContinuousCoReviewVerificationProvenance -Provenance ([pscustomobject]@{ kind = 'made-up'; source = 's' })).valid | Should -BeFalse
        }
        It 'rejects a bare-string provenance (must be an object)' {
            (Test-ContinuousCoReviewVerificationProvenance -Provenance 'project-detected').valid | Should -BeFalse
            (Test-ContinuousCoReviewVerificationProvenance -Provenance $null).valid | Should -BeFalse
        }
        It 'requires source, and requires provider/profile for the identity-bearing kinds' {
            (Test-ContinuousCoReviewVerificationProvenance -Provenance ([pscustomobject]@{ kind = 'project-detected' })).valid | Should -BeFalse -Because 'source is required'
            (Test-ContinuousCoReviewVerificationProvenance -Provenance ([pscustomobject]@{ kind = 'provider-gated'; source = 's' })).valid | Should -BeFalse -Because 'provider required for provider-gated'
            (Test-ContinuousCoReviewVerificationProvenance -Provenance ([pscustomobject]@{ kind = 'provider-gated'; source = 's'; provider = 'dotnet-sdk' })).valid | Should -BeTrue
            (Test-ContinuousCoReviewVerificationProvenance -Provenance ([pscustomobject]@{ kind = 'profile-selected'; source = 's' })).valid | Should -BeFalse -Because 'profile required for profile-selected'
            (Test-ContinuousCoReviewVerificationProvenance -Provenance ([pscustomobject]@{ kind = 'profile-selected'; source = 's'; profile = 'ci' })).valid | Should -BeTrue
        }
    }

    Context 'command validity' {
        It 'a well-formed command is valid' {
            $r = Test-ContinuousCoReviewVerificationCommand -Command ([pscustomobject]@{ command_id = 'c'; executable = 'pytest'; arguments = @('-q'); provenance = (New-Prov 'project-detected' 'pyproject.toml') })
            $r.valid | Should -BeTrue
            $r.reason | Should -BeNullOrEmpty
        }
        It 'requires a command_id and a non-empty executable' {
            (Test-ContinuousCoReviewVerificationCommand -Command ([pscustomobject]@{ executable = 'x'; provenance = (New-Prov) })).valid | Should -BeFalse -Because 'command_id required'
            (Test-ContinuousCoReviewVerificationCommand -Command ([pscustomobject]@{ command_id = 'c'; executable = ''; provenance = (New-Prov) })).valid | Should -BeFalse -Because 'executable required'
        }
        It 'rejects arguments that is a single shell string (must be a string array)' {
            (Test-ContinuousCoReviewVerificationCommand -Command ([pscustomobject]@{ command_id = 'c'; executable = 'bash'; arguments = 'echo hi && rm -rf /'; provenance = (New-Prov) })).valid |
                Should -BeFalse -Because 'a shell string is rejected; shell behaviour must be an explicit interpreter invocation'
            (Test-ContinuousCoReviewVerificationCommand -Command ([pscustomobject]@{ command_id = 'c'; executable = 'bash'; arguments = @('-lc', 'echo hi'); provenance = (New-Prov) })).valid | Should -BeTrue
        }
        It 'rejects a literal env/environment map but accepts env_refs NAMES' {
            (Test-ContinuousCoReviewVerificationCommand -Command ([pscustomobject]@{ command_id = 'c'; executable = 'x'; provenance = (New-Prov); env = [pscustomobject]@{ SECRET = 'example-not-a-real-secret' } })).valid | Should -BeFalse
            (Test-ContinuousCoReviewVerificationCommand -Command ([pscustomobject]@{ command_id = 'c'; executable = 'x'; provenance = (New-Prov); environment = [pscustomobject]@{ SECRET = 'x' } })).valid | Should -BeFalse
            (Test-ContinuousCoReviewVerificationCommand -Command ([pscustomobject]@{ command_id = 'c'; executable = 'x'; provenance = (New-Prov); env_refs = @('CI', 'BUILD_ID') })).valid | Should -BeTrue
            (Test-ContinuousCoReviewVerificationCommand -Command ([pscustomobject]@{ command_id = 'c'; executable = 'x'; provenance = (New-Prov); env_refs = @('FOO=bar') })).valid | Should -BeFalse -Because 'a NAME=value literal is forbidden; only names allowed'
        }
        It 'rejects a null command (never throws under StrictMode)' {
            (Test-ContinuousCoReviewVerificationCommand -Command $null).valid | Should -BeFalse
        }
        It 'rejects a path-escaping working_directory / rooted result_path' {
            (Test-ContinuousCoReviewVerificationCommand -RepoRoot $script:RepoRoot -Command ([pscustomobject]@{ command_id = 'c'; executable = 'bash'; provenance = (New-Prov); working_directory = '../evil' })).valid | Should -BeFalse
            (Test-ContinuousCoReviewVerificationCommand -RepoRoot $script:RepoRoot -Command ([pscustomobject]@{ command_id = 'c'; executable = 'x'; provenance = (New-Prov); result_path = '/etc/passwd' })).valid | Should -BeFalse
            (Test-ContinuousCoReviewVerificationCommand -RepoRoot $script:RepoRoot -Command ([pscustomobject]@{ command_id = 'c'; executable = 'x'; provenance = (New-Prov); working_directory = 'verification'; result_path = 'artifacts/r.json' })).valid | Should -BeTrue
        }
    }

    Context 'engine-bounded timeout resolver' {
        It 'a requested 0/absent resolves to the engine DEFAULT (never unlimited)' {
            $r = Resolve-ContinuousCoReviewVerificationTimeout -Requested 0
            $r.effective_seconds | Should -Be (Get-ContinuousCoReviewDefaultVerificationTimeoutSeconds)
            $r.effective_seconds | Should -BeGreaterThan 0
            $r.clamped | Should -BeFalse
        }
        It 'a request over the engine MAX is clamped to the max and flagged' {
            $max = Get-ContinuousCoReviewMaxVerificationTimeoutSeconds
            $r = Resolve-ContinuousCoReviewVerificationTimeout -Requested ($max + 10000)
            $r.effective_seconds | Should -Be $max
            $r.clamped | Should -BeTrue
        }
        It 'a request within bounds passes through unclamped' {
            $r = Resolve-ContinuousCoReviewVerificationTimeout -Requested 42
            $r.effective_seconds | Should -Be 42
            $r.clamped | Should -BeFalse
        }
    }

    Context 'path safety' {
        It 'rejects rooted + escaping paths; accepts a repo-relative one and returns its canonical form' {
            $root = Join-Path $TestDrive 'psroot'
            New-Item -ItemType Directory -Path $root -Force | Out-Null
            # A drive-letter path is ROOTED only on Windows; on Linux 'C:\Windows' is an ordinary (odd) relative
            # filename, so the Windows-form assertion is platform-scoped. The POSIX rooted form is rejected on
            # BOTH platforms (IsPathRooted('/x') is true on Windows too) - the cross-platform rooted coverage.
            if ($IsWindows) {
                (Test-ContinuousCoReviewVerificationPathSafe -RepoRoot $root -Path 'C:\Windows').safe | Should -BeFalse
            }
            (Test-ContinuousCoReviewVerificationPathSafe -RepoRoot $root -Path '/etc/passwd').safe | Should -BeFalse
            (Test-ContinuousCoReviewVerificationPathSafe -RepoRoot $root -Path '../escape').safe | Should -BeFalse
            (Test-ContinuousCoReviewVerificationPathSafe -RepoRoot $root -Path 'sub/../still-inside').safe | Should -BeTrue
            $ok = Test-ContinuousCoReviewVerificationPathSafe -RepoRoot $root -Path 'a/b/c.json'
            $ok.safe | Should -BeTrue
            $ok.canonical_relative | Should -Be 'a/b/c.json'
        }
        It 'rejects a symlink/junction that resolves OUTSIDE the repo root' {
            $root = Join-Path $TestDrive 'jroot'
            $outside = Join-Path $TestDrive 'joutside'
            New-Item -ItemType Directory -Path $root, $outside -Force | Out-Null
            # VERIFY the artifact is a REAL link (ResolveLinkTarget non-null): on Linux 'Junction' can produce a
            # plain non-link artifact instead of failing, which would vacuously pass the safety check.
            $made = New-EscapeLink -LinkPath (Join-Path $root 'link') -Target $outside
            if (-not $made) { Set-ItResult -Skipped -Because 'this environment cannot create a junction or symlink'; return }
            (Test-ContinuousCoReviewVerificationPathSafe -RepoRoot $root -Path 'link').safe | Should -BeFalse -Because 'the junction dereferences outside the repo root'
        }
        It 'rejects a path BELOW an escaping ancestor link - not only the link itself (finding f1, run 20260714T123137002)' {
            $root = Join-Path $TestDrive 'aroot'
            $outside = Join-Path $TestDrive 'aoutside'
            New-Item -ItemType Directory -Path $root, $outside -Force | Out-Null
            # real, ORDINARY content outside the repo, reachable only through the escaping link: the final
            # items are a normal directory + file whose own ResolveLinkTarget() is null.
            New-Item -ItemType Directory -Path (Join-Path $outside 'subdir') -Force | Out-Null
            Set-Content -LiteralPath (Join-Path $outside 'subdir/result.json') -Value '{}' -NoNewline
            $made = New-EscapeLink -LinkPath (Join-Path $root 'link') -Target $outside
            if (-not $made) { Set-ItResult -Skipped -Because 'this environment cannot create a junction or symlink'; return }
            (Test-ContinuousCoReviewVerificationPathSafe -RepoRoot $root -Path 'link/subdir').safe |
                Should -BeFalse -Because 'an escaping ancestor re-roots everything below it outside the repo'
            (Test-ContinuousCoReviewVerificationPathSafe -RepoRoot $root -Path 'link/subdir/result.json').safe |
                Should -BeFalse -Because 'a file below an escaping ancestor link would execute/write outside RepoRoot'
        }
        It 'accepts a link whose target stays INSIDE the repo root (containment, not link-phobia)' {
            $root = Join-Path $TestDrive 'iroot'
            New-Item -ItemType Directory -Path (Join-Path $root 'realdir') -Force | Out-Null
            Set-Content -LiteralPath (Join-Path $root 'realdir/f.txt') -Value 'x' -NoNewline
            $made = New-EscapeLink -LinkPath (Join-Path $root 'inlink') -Target (Join-Path $root 'realdir')
            if (-not $made) { Set-ItResult -Skipped -Because 'this environment cannot create a junction or symlink'; return }
            (Test-ContinuousCoReviewVerificationPathSafe -RepoRoot $root -Path 'inlink/f.txt').safe |
                Should -BeTrue -Because 'the link resolves inside the repo root; below-link content is validated, not refused'
        }
    }

    Context 'plan validity — plan_id, order preserved, unique command_id, count' {
        It 'a valid multi-command plan is valid with the correct command_count' {
            $plan = [pscustomobject]@{ schema_version = '1.0'; plan_id = 'p'; commands = @(
                    [pscustomobject]@{ command_id = 'a'; executable = 'a'; provenance = (New-Prov) },
                    [pscustomobject]@{ command_id = 'b'; executable = 'b'; provenance = (New-Prov) },
                    [pscustomobject]@{ command_id = 'c'; executable = 'c'; provenance = (New-Prov) }
                ) }
            $r = Test-ContinuousCoReviewVerificationPlan -Plan $plan
            $r.valid | Should -BeTrue
            $r.command_count | Should -Be 3
        }
        It 'requires a plan_id' {
            (Test-ContinuousCoReviewVerificationPlan -Plan ([pscustomobject]@{ schema_version = '1.0'; commands = @() })).valid | Should -BeFalse
        }
        It 'reports the FIRST invalid command BY ITS DECLARED INDEX (order preserved, never sorted)' {
            $plan = [pscustomobject]@{ schema_version = '1.0'; plan_id = 'p'; commands = @(
                    [pscustomobject]@{ command_id = 'a'; executable = 'a'; provenance = (New-Prov) },
                    [pscustomobject]@{ command_id = 'b'; executable = 'b'; provenance = (New-Prov) },
                    [pscustomobject]@{ command_id = 'c'; executable = ''; provenance = (New-Prov) }
                ) }
            $r = Test-ContinuousCoReviewVerificationPlan -Plan $plan
            $r.valid | Should -BeFalse
            $r.reason | Should -BeLike '*index 2*'
            $r.command_count | Should -Be 3
        }
        It 'rejects a plan with a DUPLICATE command_id' {
            $plan = [pscustomobject]@{ schema_version = '1.0'; plan_id = 'p'; commands = @(
                    [pscustomobject]@{ command_id = 'dup'; executable = 'a'; provenance = (New-Prov) },
                    [pscustomobject]@{ command_id = 'dup'; executable = 'b'; provenance = (New-Prov) }
                ) }
            $r = Test-ContinuousCoReviewVerificationPlan -Plan $plan
            $r.valid | Should -BeFalse
            $r.reason | Should -BeLike '*duplicate command_id*'
        }
        It 'a null plan and a non-list commands are invalid; an empty plan is structurally valid (count 0)' {
            (Test-ContinuousCoReviewVerificationPlan -Plan $null).valid | Should -BeFalse
            (Test-ContinuousCoReviewVerificationPlan -Plan ([pscustomobject]@{ plan_id = 'p'; commands = 'not-a-list' })).valid | Should -BeFalse
            $empty = Test-ContinuousCoReviewVerificationPlan -Plan ([pscustomobject]@{ schema_version = '1.0'; plan_id = 'p'; commands = @() })
            $empty.valid | Should -BeTrue
            $empty.command_count | Should -Be 0
        }
    }

    Context 'state resolution — configured vs the explicit verification-not-configured' {
        It 'configured when at least one command is valid' {
            $plan = [pscustomobject]@{ schema_version = '1.0'; plan_id = 'p'; commands = @([pscustomobject]@{ command_id = 'c'; executable = 'pytest'; provenance = (New-Prov) }) }
            (Resolve-ContinuousCoReviewVerificationPlanState -Plan $plan).state | Should -Be 'configured'
        }
        It 'verification-not-configured for null / empty / all-invalid (empty is never a silent success)' {
            (Resolve-ContinuousCoReviewVerificationPlanState -Plan $null).state | Should -Be 'verification-not-configured'
            $empty = Resolve-ContinuousCoReviewVerificationPlanState -Plan ([pscustomobject]@{ plan_id = 'p'; commands = @() })
            $empty.state | Should -Be 'verification-not-configured'
            $empty.reason | Should -BeLike '*silent success*'
            $allBad = [pscustomobject]@{ plan_id = 'p'; commands = @(
                    [pscustomobject]@{ command_id = 'c'; executable = ''; provenance = (New-Prov) },
                    [pscustomobject]@{ command_id = 'd'; executable = 'x'; provenance = 'bare-string-bad' }
                ) }
            (Resolve-ContinuousCoReviewVerificationPlanState -Plan $allBad).state | Should -Be 'verification-not-configured'
        }
    }

    Context 'mixed-technology / empty / bad fixture family (arbitrary technologies accepted)' {
        It 'validates every plan case exactly as the fixture specifies' {
            $fx = Get-Fixture 'verification-plans.json'
            foreach ($case in $fx.plan_cases) {
                $planCheck = Test-ContinuousCoReviewVerificationPlan -Plan $case.plan -RepoRoot $script:RepoRoot
                $planCheck.valid | Should -Be $case.expected_valid -Because "plan '$($case.name)' valid"
                $planCheck.command_count | Should -Be $case.expected_command_count -Because "plan '$($case.name)' command_count"
                (Resolve-ContinuousCoReviewVerificationPlanState -Plan $case.plan -RepoRoot $script:RepoRoot).state |
                    Should -Be $case.expected_state -Because "plan '$($case.name)' state"
            }
        }
        It 'validates every command case exactly as the fixture specifies' {
            $fx = Get-Fixture 'verification-plans.json'
            foreach ($case in $fx.command_cases) {
                (Test-ContinuousCoReviewVerificationCommand -Command $case.command -RepoRoot $script:RepoRoot).valid |
                    Should -Be $case.expected_valid -Because "command '$($case.name)'"
            }
        }
        It 'the mixed-technology plan proves ARBITRARY technologies + mixed provenance are accepted (pytest/cargo/dotnet/bash)' {
            $fx = Get-Fixture 'verification-plans.json'
            $mixed = @($fx.plan_cases | Where-Object { $_.name -eq 'mixed-technology-declared-plan' })[0]
            $execs = @($mixed.plan.commands | ForEach-Object { $_.executable })
            foreach ($e in 'pytest', 'cargo', 'dotnet', 'bash') { $execs | Should -Contain $e }
            @($mixed.plan.commands | ForEach-Object { $_.provenance.kind } | Sort-Object -Unique).Count | Should -Be 4 -Because 'four different provenance kinds in one plan'
        }
    }

    Context 'T019 evidence-join validator — digest-mismatch / duplicate / unjoinable are refused' {
        It 'classifies every evidence-join case exactly as the fixture specifies' {
            $fx = (Get-Fixture 'verification-plans.json').evidence_join
            foreach ($case in $fx.cases) {
                $res = @(Test-ContinuousCoReviewPlanEvidenceInjectable -PlanEvidence $case.records -Plan $fx.plan -CurrentDigest $fx.current_digest)
                @($res).Count | Should -Be @($case.expected).Count -Because "case '$($case.name)' record count"
                for ($i = 0; $i -lt @($case.expected).Count; $i++) {
                    $res[$i].injectable | Should -Be $case.expected[$i].injectable -Because "case '$($case.name)' rec $i injectable"
                    $res[$i].classification | Should -Be $case.expected[$i].classification -Because "case '$($case.name)' rec $i classification"
                }
            }
        }
        It 'digest precedence is absolute — a digest-mismatched record is refused even with a valid command_id' {
            $fx = (Get-Fixture 'verification-plans.json').evidence_join
            $r = @(Test-ContinuousCoReviewPlanEvidenceInjectable -PlanEvidence @([pscustomobject]@{ command_id = 'c1'; reviewed_digest_tree_id = 'zzzz' }) -Plan $fx.plan -CurrentDigest $fx.current_digest)
            $r[0].injectable | Should -BeFalse
            $r[0].classification | Should -Be 'digest-mismatch-not-injected'
        }
    }
}
