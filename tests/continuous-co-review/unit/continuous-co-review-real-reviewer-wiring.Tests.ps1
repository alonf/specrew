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
            $userCfg.Count | Should -Be 0
        }
        finally { Pop-Location }
    }
    Context 'navigator implement-stage detection across start-context schemas' {
        BeforeAll {
            function script:New-NavStageContext {
                        param([string]$Json)
                        $r = Join-Path $env:TEMP ('navstage-' + [guid]::NewGuid().ToString('N').Substring(0, 8))
                        New-Item -ItemType Directory -Path (Join-Path $r '.specrew') -Force | Out-Null
                        $Json | Set-Content -LiteralPath (Join-Path $r '.specrew/start-context.json') -Encoding UTF8
                        return $r
                    }
        }

                It 'v2 schema (boundary_enforcement.last_authorized_boundary=before-implement) -> implement' {
            $r = script:New-NavStageContext '{"schema":"v2","boundary_enforcement":{"last_authorized_boundary":"before-implement"}}'
            try { Get-ContinuousCoReviewNavigatorImplementStage -RepoRoot $r | Should -Be 'implement' } finally { Remove-Item $r -Recurse -Force -ErrorAction SilentlyContinue }
        }
        It 'old schema (session_state.boundary_type=before-implement) -> implement (no regression)' {
            $r = script:New-NavStageContext '{"session_state":{"boundary_type":"before-implement"}}'
            try { Get-ContinuousCoReviewNavigatorImplementStage -RepoRoot $r | Should -Be 'implement' } finally { Remove-Item $r -Recurse -Force -ErrorAction SilentlyContinue }
        }
        It 'v2 non-implement boundary (review-signoff) -> empty (must NOT over-fire reviews)' {
            $r = script:New-NavStageContext '{"schema":"v2","boundary_enforcement":{"last_authorized_boundary":"review-signoff"}}'
            try { Get-ContinuousCoReviewNavigatorImplementStage -RepoRoot $r | Should -BeNullOrEmpty } finally { Remove-Item $r -Recurse -Force -ErrorAction SilentlyContinue }
        }
    }
}
