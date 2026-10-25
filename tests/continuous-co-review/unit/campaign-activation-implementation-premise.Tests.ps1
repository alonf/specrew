$ErrorActionPreference = 'Stop'

# Trace: T003 (landing early per the maintainer's 2026-08-10 in-scope ruling) / FR-007, FR-008 / SC-003.
#
# DRIFT-199-I001-006 pinned as a fixture. The campaign surface declares itself live from the
# 'before-implement' cursor onward on the STATED PREMISE that "there is implementation to
# review" (worktree-navigator.ps1, DRIFT pre-tag slice #2). At that cursor no implementation
# exists yet: the coverage delta holds only planning records. The consumer then meets a
# review-required block demanding a review of the PLANNING digest, and no disposition can
# decline it (every --remediate choice binds to a run id; zero runs exist).
#
# These tests pin the ALIGNMENT ONLY - activation must match the premise. They also pin the
# guard in the other direction: the moment implementation IS present the surface stays live,
# so the alignment can never be read as a gate bypass.
Describe 'Campaign activation matches its implementation premise (DRIFT-199-I001-006)' {
    BeforeAll {
        $script:RepoRoot = (Resolve-Path "$PSScriptRoot/../../..").Path
        . (Join-Path $script:RepoRoot 'scripts/internal/continuous-co-review/_load.ps1')
        . (Join-Path $script:RepoRoot 'scripts/internal/continuous-co-review/worktree-navigator.ps1')

        function script:New-ActivationRepo {
            param([Parameter(Mandatory)][string]$Path)
            New-Item -ItemType Directory -Path $Path -Force | Out-Null
            & git -C $Path init -q 2>&1 | Out-Null
            & git -C $Path branch -m main 2>&1 | Out-Null
            [IO.File]::WriteAllText((Join-Path $Path 'README.md'), 'trunk baseline')
            & git -C $Path -c user.name=a199 -c user.email=a199@example.invalid add -A 2>&1 | Out-Null
            & git -C $Path -c user.name=a199 -c user.email=a199@example.invalid commit -qm 'trunk baseline' 2>&1 | Out-Null
            & git -C $Path checkout -q -b 199-activation-fixture 2>&1 | Out-Null
            return $Path
        }

        function script:Add-ActivationPlanningRecords {
            param([Parameter(Mandatory)][string]$Repo)
            $feature = Join-Path $Repo 'specs/199-activation-fixture'
            New-Item -ItemType Directory -Path (Join-Path $feature 'iterations/001') -Force | Out-Null
            [IO.File]::WriteAllText((Join-Path $feature 'spec.md'), "# Spec`n`nplanning record only.`n")
            [IO.File]::WriteAllText((Join-Path $feature 'plan.md'), "# Plan`n`nplanning record only.`n")
            [IO.File]::WriteAllText((Join-Path $feature 'iterations/001/plan.md'), "# Iteration Plan`n`nplanning record only.`n")

            $startContext = [pscustomobject]@{
                schema         = 'v2'
                feature_path   = 'specs/199-activation-fixture'
                session_state  = [pscustomobject]@{
                    active           = $true
                    boundary_type    = 'before-implement'
                    feature_ref      = '199-activation-fixture'
                    feature_path     = 'specs/199-activation-fixture'
                    iteration_number = '001'
                }
                boundary_enforcement = [pscustomobject]@{
                    last_authorized_boundary = 'tasks'
                    pending_next_boundary    = 'before-implement'
                }
            }
            $specrewDir = Join-Path $Repo '.specrew'
            New-Item -ItemType Directory -Path $specrewDir -Force | Out-Null
            [IO.File]::WriteAllText((Join-Path $specrewDir 'start-context.json'), ($startContext | ConvertTo-Json -Depth 10), [Text.UTF8Encoding]::new($false))

            & git -C $Repo -c user.name=a199 -c user.email=a199@example.invalid add -A 2>&1 | Out-Null
            & git -C $Repo -c user.name=a199 -c user.email=a199@example.invalid commit -qm 'boundary(plan): planning records only' 2>&1 | Out-Null
        }

        function script:Add-ActivationImplementation {
            param([Parameter(Mandatory)][string]$Repo)
            $scriptsDir = Join-Path $Repo 'scripts'
            New-Item -ItemType Directory -Path $scriptsDir -Force | Out-Null
            [IO.File]::WriteAllText((Join-Path $scriptsDir 'tool.ps1'), "function Get-Thing { 'thing' }`n")
            & git -C $Repo -c user.name=a199 -c user.email=a199@example.invalid add -A 2>&1 | Out-Null
            & git -C $Repo -c user.name=a199 -c user.email=a199@example.invalid commit -qm 'boundary(implement): first code' 2>&1 | Out-Null
        }
    }

    BeforeEach {
        $script:Work = Join-Path ([IO.Path]::GetTempPath()) ('ccr-activation-' + [Guid]::NewGuid().ToString('N'))
        $script:Repo = script:New-ActivationRepo -Path $script:Work
    }

    AfterEach {
        if ($script:Work -and (Test-Path -LiteralPath $script:Work)) {
            Remove-Item -LiteralPath $script:Work -Recurse -Force -ErrorAction SilentlyContinue
        }
    }

    It 'is QUIET at before-implement when the coverage delta holds only planning records' {
        script:Add-ActivationPlanningRecords -Repo $script:Repo

        $scope = Get-ReviewCampaignNavigatorScopeApplicability -RepoRoot $script:Repo

        $scope.applicable | Should -BeFalse
        $scope.reason | Should -Match 'no-implementation'
    }

    It 'is LIVE at before-implement as soon as implementation exists in the coverage delta' {
        script:Add-ActivationPlanningRecords -Repo $script:Repo
        script:Add-ActivationImplementation -Repo $script:Repo

        $scope = Get-ReviewCampaignNavigatorScopeApplicability -RepoRoot $script:Repo

        $scope.applicable | Should -BeTrue
    }

    # Round-1 finding (major): the first implementation compared changed paths to the machinery and
    # `specs` roots with a HARDCODED OrdinalIgnoreCase, while this repository derives path case
    # semantics from the target volume. On a case-sensitive filesystem a case-distinct root is a
    # genuine reviewable path, so classifying it as records-only silences the gate. This is the
    # beta2 certify-round-3 path-identity class recurring.
    It 'derives its path comparison from the volume, never a hardcoded case rule' {
        $source = Get-Content -LiteralPath (Join-Path $script:RepoRoot 'scripts/internal/continuous-co-review/worktree-navigator.ps1') -Raw
        $predicate = [regex]::Match($source, '(?ms)^function Test-ReviewCampaignCoverageDeltaHasImplementation \{.*?^\}').Value

        $predicate | Should -Not -BeNullOrEmpty
        # The single source (path-identity.ps1) owns the case rule; the predicate must ask it.
        $predicate | Should -Match 'Get-ContinuousCoReviewPathComparison|Get-ContinuousCoReviewPathComparer'
        $predicate | Should -Match "WhenUndetermined\s+'?distinct'?"
        # No hand-rolled case decision may remain inside the predicate.
        $predicate | Should -Not -Match 'OrdinalIgnoreCase'
    }

    It 'classifies a case-distinct records root exactly as the volume oracle says it should' {
        script:Add-ActivationPlanningRecords -Repo $script:Repo
        # A case-distinct spelling of the records root. On a case-sensitive volume this is a
        # DIFFERENT directory and therefore reviewable; on a case-insensitive volume it is the
        # same directory and stays records-only.
        $distinct = Join-Path $script:Repo 'Specs/199-activation-fixture'
        New-Item -ItemType Directory -Path $distinct -Force -ErrorAction SilentlyContinue | Out-Null
        [IO.File]::WriteAllText((Join-Path $distinct 'note.md'), "case-distinct`n")
        & git -C $script:Repo -c user.name=a199 -c user.email=a199@example.invalid add -A 2>&1 | Out-Null
        & git -C $script:Repo -c user.name=a199 -c user.email=a199@example.invalid commit -qm 'case-distinct root' 2>&1 | Out-Null

        $caseSensitive = Get-ContinuousCoReviewPathCaseSensitive -Path $script:Repo
        $scope = Get-ReviewCampaignNavigatorScopeApplicability -RepoRoot $script:Repo

        if ($caseSensitive -eq $true) {
            # Reviewable content exists under a distinct root: the surface must stay live.
            $scope.applicable | Should -BeTrue
        }
        else {
            # Same directory (or undetermined-but-folded): still records-only.
            # NOTE (honest evidence label): on a case-INSENSITIVE volume this assertion cannot
            # distinguish the fixed predicate from the hardcoded one - the source guard above is
            # what fails on this machine. The behavioural half is what fails on a case-sensitive
            # volume, which is why both exist.
            $scope.applicable | Should -BeFalse
        }
    }

    It 'stays LIVE (fails closed) when the coverage anchor cannot be resolved' {
        script:Add-ActivationPlanningRecords -Repo $script:Repo
        # Remove the only pre-feature branch so the trunk resolver cannot anchor the delta.
        & git -C $script:Repo branch -D main 2>&1 | Out-Null

        $scope = Get-ReviewCampaignNavigatorScopeApplicability -RepoRoot $script:Repo

        $scope.applicable | Should -BeTrue
    }
}
