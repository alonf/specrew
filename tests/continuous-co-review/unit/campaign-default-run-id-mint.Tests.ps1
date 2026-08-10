$ErrorActionPreference = 'Stop'

# Trace: T001/T008 surface (maintainer in-scope ruling 2026-08-10) / FR-013, FR-023.
#
# DRIFT-199-I001-007. The campaign minted its own run id from the timestamp format
# `yyyyMMddTHHmmssfff`, whose literal UPPERCASE 'T' can never satisfy the identifier rule
# `^run-[a-z0-9][a-z0-9-]{0,63}$` (case-SENSITIVE). Every campaign run that did not receive an
# explicit --run-id therefore died at identity resolution, before any reviewer was invoked.
#
# The rule is NOT relaxed: run ids become filesystem path segments, so lowercase-only is a
# path-identity containment rule (the beta2 certify-round-3 class). The MINTER is what changes.
#
# COVERAGE LESSON (maintainer, 2026-08-10): this stayed latent since cbd7b615 because every
# observed run supplied an explicit id, so no fixture ever exercised the DEFAULT path. These
# tests pin the default path specifically — invoked with NO run id.
Describe 'Campaign default run-id mint (DRIFT-199-I001-007)' {
    BeforeAll {
        $script:RepoRoot = (Resolve-Path "$PSScriptRoot/../../..").Path
        . (Join-Path $script:RepoRoot 'scripts/internal/continuous-co-review/_load.ps1')

        function script:New-MintFixtureRepo {
            param([Parameter(Mandatory)][string]$Path)
            New-Item -ItemType Directory -Path $Path -Force | Out-Null
            & git -C $Path init -q 2>&1 | Out-Null
            & git -C $Path branch -m main 2>&1 | Out-Null
            $feature = Join-Path $Path 'specs/199-mint-fixture'
            New-Item -ItemType Directory -Path (Join-Path $feature 'iterations/001') -Force | Out-Null
            [IO.File]::WriteAllText((Join-Path $feature 'spec.md'), "# Spec`n")
            [IO.File]::WriteAllText((Join-Path $Path 'README.md'), 'base')
            & git -C $Path -c user.name=mint -c user.email=mint@example.invalid add -A 2>&1 | Out-Null
            & git -C $Path -c user.name=mint -c user.email=mint@example.invalid commit -qm base 2>&1 | Out-Null
            return $Path
        }
    }

    BeforeEach {
        $script:Work = Join-Path ([IO.Path]::GetTempPath()) ('ccr-mint-' + [Guid]::NewGuid().ToString('N'))
        $script:Repo = script:New-MintFixtureRepo -Path $script:Work
    }

    AfterEach {
        if ($script:Work -and (Test-Path -LiteralPath $script:Work)) {
            Remove-Item -LiteralPath $script:Work -Recurse -Force -ErrorAction SilentlyContinue
        }
    }

    It 'THE DEFAULT PATH: resolving identity with NO run id mints one that satisfies the identifier rule' {
        $identity = Resolve-ReviewCampaignPublicIdentity -RepoRoot $script:Repo -FeatureId '199-mint-fixture' -IterationNumber '001'

        $identity.run_id | Should -Not -BeNullOrEmpty
        (Test-ReviewAuthorityIdentifier -Value $identity.run_id -Kind run) | Should -BeTrue
    }

    It 'the minted id carries no uppercase character (the containment rule stays lowercase-only)' {
        $identity = Resolve-ReviewCampaignPublicIdentity -RepoRoot $script:Repo -FeatureId '199-mint-fixture' -IterationNumber '001'

        $identity.run_id | Should -Be $identity.run_id.ToLowerInvariant()
        $identity.run_id | Should -Match '^run-[a-z0-9][a-z0-9-]*$'
    }

    It 'minted ids stay unique across successive resolutions (the stamp still discriminates runs)' {
        $first = Resolve-ReviewCampaignPublicIdentity -RepoRoot $script:Repo -FeatureId '199-mint-fixture' -IterationNumber '001'
        $second = Resolve-ReviewCampaignPublicIdentity -RepoRoot $script:Repo -FeatureId '199-mint-fixture' -IterationNumber '001'

        $second.run_id | Should -Not -Be $first.run_id
    }

    It 'an explicit UPPERCASE run id is still refused (the validator is not relaxed)' {
        {
            Resolve-ReviewCampaignPublicIdentity -RepoRoot $script:Repo -FeatureId '199-mint-fixture' `
                -IterationNumber '001' -RunId 'run-20260810T072512585-18f6c6e4'
        } | Should -Throw '*review-campaign-invalid-run-id*'
    }
}
