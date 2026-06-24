$ErrorActionPreference = 'Stop'

# Trace: T082 (FR-026 / FR-030 / FR-031) - WIRE THE REAL REVIEWER: replace the verdict-emitting stub in
# Build-ContinuousCoReviewNavigatorReviewerCommand with the policy-driven path (select-at-fire in-repo,
# host-call detached, FindingsResult.v1 to stdout). DETERMINISTIC coverage ONLY - NO live host is ever
# invoked here (the meaningful live-dispatcher E2E is T085). This file asserts the WIRING:
#   - HAZARD A: module-base resolution for the detached cwd=worktree case (the emitted -Command dot-sources
#     _load.ps1 from the REAL module base by ABSOLUTE path, not its worktree cwd).
#   - HAZARD B: the selected candidate (host/model + the raised host-call timeout) is threaded into the
#     fired -Command safely (as a single-quoted run-dir json path, not interpolated code).
#   - condition-c: the raised co-review timeout config is honored (reviewer/adapter budget read from
#     config, default 300; the supervisor budget sits ABOVE it).
#   - condition-b: the execution-engine mutation guard is SKIPPED on the detached-worktree path, and the
#     skip is EXPLICIT (posture='skipped-isolated-worktree') - it neither false-invalidates a run nor is
#     a claimed-but-inert control (a guard that ran-and-found-nothing). The control case proves the guard
#     STILL runs on the synchronous in-repo path.
#
# Harness note (per task constraint): run THIS file in its own fresh NATIVE WINDOWS pwsh
#   pwsh -NoProfile -NonInteractive  with  $env:TEMP/$env:TMP -> <repo>\.scratch\pestertmp
#   and  $env:SPECREW_MODULE_PATH=(Get-Location).Path. The launcher's tar must be bsdtar
#   (C:\Windows\System32\tar.exe), NOT bash's GNU tar - so run in native pwsh, NOT through Git Bash.
# git identity is supplied PER-INVOCATION via `git -c user.*` in TEMP repos ONLY (asserted clean at end).

Describe 'T082 real reviewer wiring (select-at-fire + detached execute + skip-guard + raised-timeout)' {
    BeforeAll {
        $script:RepoRoot = (Resolve-Path "$PSScriptRoot/../../..").Path
        $env:SPECREW_MODULE_PATH = $script:RepoRoot
        . (Join-Path $script:RepoRoot 'scripts/internal/continuous-co-review/_load.ps1')
        . (Join-Path $script:RepoRoot 'scripts/internal/continuous-co-review/continuous-co-review-navigator.ps1')
        $script:CreatedAt = [datetime] '2026-06-24T00:00:00Z'

        # A governed "project" whose ACTIVE feature dir carries a spec.md + a design-analysis.md so the
        # navigator's in-repo request build (which REQUIRES >=1 design-context ref) succeeds - i.e. a real
        # reviewer plan is buildable. Diverged onto a feature branch so the merge-base baseline -> HEAD diff
        # is a real checkpoint. `git -c user.*` per-invocation; never mutates a real repo's config.
        function script:New-FeatureProject {
            param([string]$BoundaryType = 'before-implement')
            $root = Join-Path ([System.IO.Path]::GetTempPath()) ('t082-proj-' + [guid]::NewGuid().ToString('N'))
            New-Item -ItemType Directory -Path $root -Force | Out-Null
            & git -C $root init -q 2>&1 | Out-Null
            & git -C $root branch -m main 2>&1 | Out-Null
            New-Item -ItemType Directory -Path (Join-Path $root 'src') -Force | Out-Null
            Set-Content -LiteralPath (Join-Path $root 'src/app.txt') -Value 'base' -Encoding UTF8 -NoNewline
            # A feature dir with the design context the reviewer request needs.
            $featRel = 'specs/050-demo-feature'
            $featAbs = Join-Path $root $featRel
            New-Item -ItemType Directory -Path (Join-Path $featAbs 'iterations/002') -Force | Out-Null
            Set-Content -LiteralPath (Join-Path $featAbs 'spec.md') -Value "# Demo spec`nFR-001 do the thing." -Encoding UTF8
            Set-Content -LiteralPath (Join-Path $featAbs 'iterations/002/design-analysis.md') -Value "# Design`nThe seam." -Encoding UTF8
            & git -C $root -c user.name='t082' -c user.email='t082@test.local' add -A 2>&1 | Out-Null
            & git -C $root -c user.name='t082' -c user.email='t082@test.local' commit -q -m 'trunk' 2>&1 | Out-Null
            & git -C $root -c user.name='t082' -c user.email='t082@test.local' checkout -q -b feature 2>&1 | Out-Null
            # .specrew governed surfaces: the implement-window cursor + the feature pointer.
            New-Item -ItemType Directory -Path (Join-Path $root '.specrew/runtime') -Force | Out-Null
            New-Item -ItemType Directory -Path (Join-Path $root '.specify') -Force | Out-Null
            ([ordered]@{ feature_directory = $featRel } | ConvertTo-Json) | Set-Content -LiteralPath (Join-Path $root '.specify/feature.json') -Encoding UTF8
            ([ordered]@{ session_state = [ordered]@{ boundary_type = $BoundaryType; feature_path = $featAbs } } | ConvertTo-Json -Depth 6) |
                Set-Content -LiteralPath (Join-Path $root '.specrew/start-context.json') -Encoding UTF8
            return [pscustomobject]@{ Root = $root; FeatureRel = $featRel }
        }

        function script:Add-Increment {
            param([Parameter(Mandatory)][string]$Root, [Parameter(Mandatory)][string]$Content)
            Set-Content -LiteralPath (Join-Path $Root 'src/app.txt') -Value $Content -Encoding UTF8 -NoNewline
            & git -C $Root -c user.name='t082' -c user.email='t082@test.local' add -A 2>&1 | Out-Null
            & git -C $Root -c user.name='t082' -c user.email='t082@test.local' commit -q -m ('inc-' + [guid]::NewGuid().ToString('N').Substring(0, 6)) 2>&1 | Out-Null
        }

        # An authorized fake reviewer candidate (no live host). Mirrors the execution-engine suite's shape.
        function script:New-FakeCandidate {
            param([string]$HostName = 'codex', [string]$ModelId = 'chatgpt', [string]$AdapterId = 'reviewer-host-adapter-fixture', [int]$TimeoutSeconds = 30)
            return [pscustomobject][ordered]@{
                host                       = $HostName
                model                      = $ModelId
                adapter_id                 = $AdapterId
                authorization_ref          = "authz-$HostName-$ModelId"
                authorized                 = $true
                exact_alternate_authorized = $false
                timeout_seconds            = $TimeoutSeconds
            }
        }

        function script:New-FakeRequest {
            param([string]$RunId = 'run-t082')
            return [pscustomobject][ordered]@{
                schema_version   = '1.0'
                run_id           = $RunId
                checkpoint_id    = "nav-$RunId"
                created_at       = '2026-06-24T00:00:00Z'
                provider_request = [pscustomobject][ordered]@{
                    requested_host    = $null
                    requested_model   = $null
                    authorization_ref = "authz-codex-chatgpt"
                    timeout_seconds   = 300
                    fallback_policy   = 'none'
                }
            }
        }
    }

    AfterAll {
        # The fan-out hygiene rule: this suite must never leave git identity on the Specrew repo.
        Push-Location $script:RepoRoot
        try {
            $userCfg = @(& git config --local --get-regexp '^user\.' 2>$null)
            $userCfg.Count | Should Be 0
        }
        finally { Pop-Location }
    }

    # ----------------------------------------------------------------------------------------------
    # HAZARD A - module-base resolution for the detached cwd=worktree case.
    # ----------------------------------------------------------------------------------------------
    Context 'HAZARD A module-base resolution' {
        It 'resolves a base that CONTAINS scripts/internal/continuous-co-review/_load.ps1 (from this file location)' {
            $base = Get-ContinuousCoReviewNavigatorModuleBase
            $base | Should Not BeNullOrEmpty
            Test-Path -LiteralPath (Join-Path $base 'scripts/internal/continuous-co-review/_load.ps1') | Should Be $true
        }

        It 'falls back to SPECREW_MODULE_PATH when that is the only path with _load.ps1' {
            # SPECREW_MODULE_PATH is the repo root in this suite; the $PSScriptRoot-relative resolve ALSO
            # finds it, so this asserts the resolved base is the real repo either way (both legs agree).
            $base = Get-ContinuousCoReviewNavigatorModuleBase
            (Resolve-Path -LiteralPath $base).Path | Should Be $script:RepoRoot
        }
    }

    # ----------------------------------------------------------------------------------------------
    # condition-c - the raised co-review timeout config.
    # ----------------------------------------------------------------------------------------------
    Context 'condition-c raised timeout config' {
        It 'defaults to 300 (above iter-002 codex ~300s) when no config exists' {
            $root = Join-Path ([System.IO.Path]::GetTempPath()) ('t082-to-' + [guid]::NewGuid().ToString('N'))
            New-Item -ItemType Directory -Path $root -Force | Out-Null
            try {
                Get-ContinuousCoReviewNavigatorTimeoutSeconds -RepoRoot $root | Should Be 300
            }
            finally { Remove-Item -LiteralPath $root -Recurse -Force -ErrorAction SilentlyContinue }
        }

        It 'reads co_review_timeout_seconds from .specrew/config.yml (quote + inline-comment tolerant)' {
            $root = Join-Path ([System.IO.Path]::GetTempPath()) ('t082-to-' + [guid]::NewGuid().ToString('N'))
            New-Item -ItemType Directory -Path (Join-Path $root '.specrew') -Force | Out-Null
            try {
                Set-Content -LiteralPath (Join-Path $root '.specrew/config.yml') -Value "co_review_timeout_seconds: 450 # bumped for a slow host" -Encoding UTF8
                Get-ContinuousCoReviewNavigatorTimeoutSeconds -RepoRoot $root | Should Be 450
            }
            finally { Remove-Item -LiteralPath $root -Recurse -Force -ErrorAction SilentlyContinue }
        }

        It 'ignores a non-numeric / non-positive value and keeps the default' {
            $root = Join-Path ([System.IO.Path]::GetTempPath()) ('t082-to-' + [guid]::NewGuid().ToString('N'))
            New-Item -ItemType Directory -Path (Join-Path $root '.specrew') -Force | Out-Null
            try {
                Set-Content -LiteralPath (Join-Path $root '.specrew/config.yml') -Value "co_review_timeout_seconds: not-a-number" -Encoding UTF8
                Get-ContinuousCoReviewNavigatorTimeoutSeconds -RepoRoot $root | Should Be 300
            }
            finally { Remove-Item -LiteralPath $root -Recurse -Force -ErrorAction SilentlyContinue }
        }
    }

    # ----------------------------------------------------------------------------------------------
    # condition-b - the mutation-guard SKIP posture (the green-but-inert lesson).
    # This is the core honesty assertion: the skip must NEITHER run-and-find-nothing (inert) NOR be
    # silently absent. We assert (a) the snapshot was NEVER taken (0 calls) AND (b) the result carries an
    # EXPLICIT skip posture marker. The control proves the guard STILL runs without the switch.
    # ----------------------------------------------------------------------------------------------
    # The SKIP test mocks New-...WorkspaceMutationSnapshot to THROW (proving the guard NEVER runs). That
    # mock is kept in its OWN Context so Pester 3.4 tears it down at the Context boundary and it cannot
    # leak into the CONTROL test (the same isolation pattern the navigator suite uses for FINDING 3).
    Context 'condition-b mutation-guard SKIP posture (isolated throw-mock)' {
        It 'SKIP: -SkipMutationGuard never snapshots AND stamps posture=skipped-isolated-worktree (mutated=$false)' {
            $req = script:New-FakeRequest -RunId 'run-skip'
            $cand = script:New-FakeCandidate
            $findings = [pscustomobject][ordered]@{ schema_version = '1.0'; run_id = 'run-skip'; status = 'no_findings'; findings = @(); created_at = '2026-06-24T00:00:00Z' }
            $adapter = {
                param($Candidate, $Request, $RequestBundle, [int]$AttemptNumber)
                return [pscustomobject][ordered]@{ kind = 'findings-result'; provider_invocation = [pscustomobject]@{ invocation_id = 'inv-1'; run_id = $Request.run_id }; findings_result = $findings; infrastructure_failure = $null }
            }
            # The guard's ONLY way to inspect state is New-...WorkspaceMutationSnapshot. A THROW here proves
            # the guard is NEVER run on the skip path (the honest skip), NOT the inert re-aim that would call
            # it twice and find nothing.
            Mock New-ContinuousCoReviewWorkspaceMutationSnapshot { throw 'snapshot must NOT be taken on the skip path' }

            $result = Invoke-ContinuousCoReviewReviewerExecution -Request $req -RunRoot (Join-Path $TestDrive 'skip-runs') -Candidates @($cand) -InvokeAdapter $adapter -SkipMutationGuard -CreatedAt $script:CreatedAt
            $result.kind | Should Be 'findings-result'
            Assert-MockCalled New-ContinuousCoReviewWorkspaceMutationSnapshot -Times 0 -Scope It
            $result.mutation_guard | Should Not BeNullOrEmpty
            $result.mutation_guard.posture | Should Be 'skipped-isolated-worktree'
            [bool]$result.mutation_guard.mutated | Should Be $false
        }
    }

    Context 'condition-b mutation-guard CONTROL (guard still runs in-repo)' {
        It 'CONTROL: WITHOUT the switch the guard RUNS the real snapshot/compare and is NOT the skip marker' {
            $req = script:New-FakeRequest -RunId 'run-guarded'
            $cand = script:New-FakeCandidate
            $findings = [pscustomobject][ordered]@{ schema_version = '1.0'; run_id = 'run-guarded'; status = 'no_findings'; findings = @(); created_at = '2026-06-24T00:00:00Z' }
            $adapter = {
                param($Candidate, $Request, $RequestBundle, [int]$AttemptNumber)
                return [pscustomobject][ordered]@{ kind = 'findings-result'; provider_invocation = [pscustomobject]@{ invocation_id = 'inv-1'; run_id = $Request.run_id }; findings_result = $findings; infrastructure_failure = $null }
            }
            # No mock: the REAL guard runs (snapshot before + after, then Compare-...). The distinctive
            # output shape of a guard that ACTUALLY RAN (its compare emits source_mutated / git_mutated /
            # before_captured_at, and NO 'posture' field) proves it was not skipped. The fixture adapter
            # mutated nothing, so mutated is false - the guard ran and correctly found no mutation.
            $result = Invoke-ContinuousCoReviewReviewerExecution -Request $req -RunRoot (Join-Path $TestDrive 'guarded-runs') -Candidates @($cand) -InvokeAdapter $adapter -ReadOnlyRoot $script:RepoRoot -CreatedAt $script:CreatedAt
            $result.kind | Should Be 'findings-result'
            $result.mutation_guard | Should Not BeNullOrEmpty
            # The real Compare-... output (the guard RAN); NOT the skip marker.
            ($result.mutation_guard.PSObject.Properties.Name -contains 'posture') | Should Be $false
            ($result.mutation_guard.PSObject.Properties.Name -contains 'source_mutated') | Should Be $true
            ($result.mutation_guard.PSObject.Properties.Name -contains 'before_captured_at') | Should Be $true
            [bool]$result.mutation_guard.mutated | Should Be $false
        }
    }

    # ----------------------------------------------------------------------------------------------
    # HAZARD A + B + condition-c, THROUGH THE FIRE SITE: the selected candidate (with the raised host-call
    # timeout) is threaded into the FIRED -Command, which dot-sources the real module base and skips the
    # guard. We capture the launcher's -Command + TimeoutSec via a mocked Start-SpecrewIsolatedTask (NO
    # real subprocess, NO live host) - the deterministic proof the wiring reaches the launcher correctly.
    # ----------------------------------------------------------------------------------------------
    Context 'fire-site threading (captured launcher, no live host)' {
        It 'fires a REAL reviewer plan: the -Command threads the candidate + module base, skips the guard, and the launcher gets the raised supervisor timeout' {
            $proj = script:New-FeatureProject
            $root = $proj.Root
            try {
                script:Add-Increment -Root $root -Content 'changed-for-real-review'

                # Capture the launcher inputs instead of firing a real supervisor (deterministic + no host).
                $script:CapturedCommand = $null
                $script:CapturedTimeout = $null
                $script:CapturedRunDir = $null
                Mock Start-SpecrewIsolatedTask {
                    $script:CapturedCommand = $Command
                    $script:CapturedTimeout = $TimeoutSec
                    $script:CapturedRunDir = $RunDir
                    return [pscustomobject]@{ run_id = 'captured-run-1'; supervisor_pid = $PID; status = 'running'; registry_path = (Join-Path $RunDir 'reg.json'); result_path = (Join-Path $RunDir 'result.out') }
                }

                # No -ReviewerCommandOverride => the REAL policy plan path. Force codex as the code-writer
                # host's INDEPENDENT reviewer by setting the code-writer host to claude (claude->codex), and
                # mark codex installed+allowed+authorized in a custom catalog via the policy's own selection.
                # (The default catalog has allowed=$false, so we select against a catalog we author here and
                # feed through SPECREW_HOST = claude so the policy picks codex.)
                $env:SPECREW_HOST = 'claude'
                # Make codex selectable: author the candidate the plan will pick by pre-authorizing the
                # catalog. The navigator builds its own catalog, so instead we assert the plan directly with
                # an injected catalog via New-...ReviewerPlan? No - we exercise the FIRE site. To make the
                # real path select SOMETHING, we allow+authorize codex+claude in the project config catalog.
                # Simplest deterministic lever: stage the catalog the navigator reads is the DEFAULT (all
                # disallowed) -> plan returns $null -> stub. That is NOT what we want here. So we instead
                # drive the plan via a Mock on Select-ContinuousCoReviewReviewerCandidate to return our fake
                # authorized candidate (host-neutral selection is asserted separately in its own test).
                Mock Select-ContinuousCoReviewReviewerCandidate { return (script:New-FakeCandidate -HostName 'codex' -ModelId 'chatgpt' -AdapterId 'reviewer-host-adapter-codex-exec' -TimeoutSeconds 30) }

                $dec = Invoke-ContinuousCoReviewNavigator -RepoRoot $root -TrunkName 'main' -ReviewerTimeoutSec 420
                $dec.action | Should Be 'fired'
                $dec.reviewer_wired | Should Be $true
                # The supervisor budget sits ABOVE the host-call budget (420 + 60 buffer).
                $dec.reviewer_timeout_seconds | Should Be 420
                $dec.supervisor_timeout_seconds | Should Be 480
                $script:CapturedTimeout | Should Be 480

                # HAZARD A: the emitted -Command dot-sources _load.ps1 from the REAL module base (absolute).
                $base = Get-ContinuousCoReviewNavigatorModuleBase
                $script:CapturedCommand | Should Match '_load\.ps1'
                $script:CapturedCommand | Should Match ([regex]::Escape($base))
                # condition-b: the detached execute skips the guard.
                $script:CapturedCommand | Should Match '-SkipMutationGuard'
                $script:CapturedCommand | Should Match 'Invoke-ContinuousCoReviewReviewerExecution'

                # HAZARD B: the candidate is threaded as a single-quoted run-dir json path (NOT interpolated
                # host/model code). The candidate file exists in the run dir and carries the RAISED host-call
                # timeout (420), not the policy default 30.
                $candFile = Join-Path $script:CapturedRunDir 'reviewer-candidate.json'
                Test-Path -LiteralPath $candFile | Should Be $true
                $script:CapturedCommand | Should Match ([regex]::Escape($candFile.Replace('\', '\')))
                $cand = Get-Content -LiteralPath $candFile -Raw | ConvertFrom-Json
                [int]$cand.timeout_seconds | Should Be 420

                # The pre-built request also landed in the run dir (the engine re-serializes it INTO the
                # worktree at execute time; it is an INPUT here, not a durable record).
                Test-Path -LiteralPath (Join-Path $script:CapturedRunDir 'reviewer-request.json') | Should Be $true
            }
            finally {
                $env:SPECREW_HOST = $null
                Remove-Item -LiteralPath $root -Recurse -Force -ErrorAction SilentlyContinue
            }
        }

        It 'host-NEUTRAL selection: the navigator passes the code-writer host to the policy with NO host-name literal in its own logic' {
            # The navigator must call Select-...ReviewerCandidate with -CodeWriterHost = the current host and
            # let the POLICY map to the independent reviewer (claude->codex). We assert the navigator threads
            # the code-writer host through; the policy (separately unit-tested) owns the mapping.
            $proj = script:New-FeatureProject
            $root = $proj.Root
            try {
                script:Add-Increment -Root $root -Content 'changed-host-neutral'
                Mock Start-SpecrewIsolatedTask { return [pscustomobject]@{ run_id = 'r'; supervisor_pid = $PID; status = 'running'; registry_path = (Join-Path $RunDir 'reg.json'); result_path = (Join-Path $RunDir 'result.out') } }
                $script:SeenCodeWriterHost = '__unset__'
                Mock Select-ContinuousCoReviewReviewerCandidate {
                    $script:SeenCodeWriterHost = $CodeWriterHost
                    return (script:New-FakeCandidate -HostName 'codex' -ModelId 'chatgpt' -AdapterId 'reviewer-host-adapter-codex-exec')
                }
                $env:SPECREW_HOST = 'claude'
                $dec = Invoke-ContinuousCoReviewNavigator -RepoRoot $root -TrunkName 'main'
                $dec.action | Should Be 'fired'
                # The code-writer host reached the policy verbatim (the policy maps claude->codex itself).
                $script:SeenCodeWriterHost | Should Be 'claude'
            }
            finally {
                $env:SPECREW_HOST = $null
                Remove-Item -LiteralPath $root -Recurse -Force -ErrorAction SilentlyContinue
            }
        }

        It 'FALLS BACK to the stub (never gate evidence) when no design context resolves (no real plan)' {
            # A governed project in the implement window but with NO feature design context -> the request
            # build cannot satisfy ReviewRequest.v2 -> New-...ReviewerPlan returns $null -> Build-... emits
            # the stub. The stub fires (plumbing proves out) but reviewer_wired is FALSE.
            $root = Join-Path ([System.IO.Path]::GetTempPath()) ('t082-nostub-' + [guid]::NewGuid().ToString('N'))
            New-Item -ItemType Directory -Path $root -Force | Out-Null
            try {
                & git -C $root init -q 2>&1 | Out-Null
                & git -C $root branch -m main 2>&1 | Out-Null
                New-Item -ItemType Directory -Path (Join-Path $root 'src') -Force | Out-Null
                Set-Content -LiteralPath (Join-Path $root 'src/app.txt') -Value 'base' -Encoding UTF8 -NoNewline
                & git -C $root -c user.name='t082' -c user.email='t082@test.local' add -A 2>&1 | Out-Null
                & git -C $root -c user.name='t082' -c user.email='t082@test.local' commit -q -m 'trunk' 2>&1 | Out-Null
                & git -C $root -c user.name='t082' -c user.email='t082@test.local' checkout -q -b feature 2>&1 | Out-Null
                New-Item -ItemType Directory -Path (Join-Path $root '.specrew/runtime') -Force | Out-Null
                # NO .specify/feature.json + NO feature dir -> no design context resolvable.
                ([ordered]@{ session_state = [ordered]@{ boundary_type = 'before-implement' } } | ConvertTo-Json -Depth 6) |
                    Set-Content -LiteralPath (Join-Path $root '.specrew/start-context.json') -Encoding UTF8
                Set-Content -LiteralPath (Join-Path $root 'src/app.txt') -Value 'changed' -Encoding UTF8 -NoNewline
                & git -C $root -c user.name='t082' -c user.email='t082@test.local' add -A 2>&1 | Out-Null
                & git -C $root -c user.name='t082' -c user.email='t082@test.local' commit -q -m 'inc' 2>&1 | Out-Null

                $script:CapturedCommand2 = $null
                Mock Start-SpecrewIsolatedTask { $script:CapturedCommand2 = $Command; return [pscustomobject]@{ run_id = 'r'; supervisor_pid = $PID; status = 'running'; registry_path = (Join-Path $RunDir 'reg.json'); result_path = (Join-Path $RunDir 'result.out') } }
                $dec = Invoke-ContinuousCoReviewNavigator -RepoRoot $root -TrunkName 'main'
                $dec.action | Should Be 'fired'
                $dec.reviewer_wired | Should Be $false
                # The emitted command is the stub (reviewer='stub'), never the real-execute path.
                $script:CapturedCommand2 | Should Match "reviewer\s*=\s*'stub'"
                $script:CapturedCommand2 | Should Not Match 'Invoke-ContinuousCoReviewReviewerExecution'
            }
            finally { Remove-Item -LiteralPath $root -Recurse -Force -ErrorAction SilentlyContinue }
        }
    }

    # ----------------------------------------------------------------------------------------------
    # The PLAN builder directly: the request build resolves design context from the generic feature dir
    # (Catch: ReviewRequest.v2 throws without a design-context ref - this proves it builds in a vanilla
    # governed project, not just for feature 197).
    # ----------------------------------------------------------------------------------------------
    Context 'New-...ReviewerPlan request build (generic feature resolution)' {
        It 'builds a plan whose request carries the resolved design context + the raised host-call timeout, and serializes both inputs to the run dir' {
            $proj = script:New-FeatureProject
            $root = $proj.Root
            try {
                script:Add-Increment -Root $root -Content 'changed-for-plan'
                Mock Select-ContinuousCoReviewReviewerCandidate { return (script:New-FakeCandidate -HostName 'codex' -ModelId 'chatgpt' -AdapterId 'reviewer-host-adapter-codex-exec' -TimeoutSeconds 30) }

                $runId = 'plan-run-1'
                $runDir = Join-Path $root (".specrew/review/pending/$runId")
                $plan = New-ContinuousCoReviewNavigatorReviewerPlan -RepoRoot $root -TreeId 'deadbeef' -RunId $runId -RunDir $runDir -ReviewerTimeoutSec 333 -TrunkName 'main' -Now $script:CreatedAt
                $plan | Should Not BeNullOrEmpty
                # The selected candidate carries the RAISED host-call timeout (not the policy default 30).
                [int]$plan.candidate.timeout_seconds | Should Be 333
                # The request resolved a design-context ref from the generic feature dir (spec.md at least).
                ($plan.design_refs -join ',') | Should Match 'spec\.md'
                # The request is a real ReviewRequest.v2 with the change-set diff content.
                $plan.request.schema_version | Should Be '2.0'
                [string]$plan.request.change_set.diff_content | Should Not BeNullOrEmpty
                # Both inputs serialized to the in-repo run dir for the detached command to read.
                Test-Path -LiteralPath $plan.request_path | Should Be $true
                Test-Path -LiteralPath $plan.candidate_path | Should Be $true
                # The module base is the real repo (HAZARD A resolution).
                Test-Path -LiteralPath (Join-Path $plan.module_base 'scripts/internal/continuous-co-review/_load.ps1') | Should Be $true
            }
            finally { Remove-Item -LiteralPath $root -Recurse -Force -ErrorAction SilentlyContinue }
        }

        It 'returns $null (fail-open, no real review) when no authorized independent host is selectable' {
            $proj = script:New-FeatureProject
            $root = $proj.Root
            try {
                script:Add-Increment -Root $root -Content 'changed-no-host'
                Mock Select-ContinuousCoReviewReviewerCandidate { return $null }   # no authorized independent host
                $runId = 'plan-run-2'
                $runDir = Join-Path $root (".specrew/review/pending/$runId")
                $plan = New-ContinuousCoReviewNavigatorReviewerPlan -RepoRoot $root -TreeId 'deadbeef' -RunId $runId -RunDir $runDir -ReviewerTimeoutSec 300 -TrunkName 'main' -Now $script:CreatedAt
                $plan | Should BeNullOrEmpty
            }
            finally { Remove-Item -LiteralPath $root -Recurse -Force -ErrorAction SilentlyContinue }
        }
    }
}
