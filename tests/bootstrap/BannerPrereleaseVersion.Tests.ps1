$ErrorActionPreference = 'Stop'

# Trace: T011 / FR-019 / SC-010 / ledger obs-2.
#
# The orientation banner dropped the prerelease tag, so a consumer running a beta build read
# "Specrew version 0.40.0" and could not tell they were on the beta channel. The version is
# resolved by the bootstrap provider from the module manifest; the reference composition already
# exists in scripts/specrew-start.ps1 (Get-ManifestSpecrewVersionText).
#
# Driven through the REAL event entry point (FR-023): the provider is invoked as the dispatcher
# invokes it, with --event-json, and the assertion reads its emitted directive.
#
# METHOD RULE, learned from the round-1 finding that caught this suite (major): the first version
# of this file DERIVED its expectation from the same manifest the code under test reads, and only
# checked that SOME prerelease suffix existed. It therefore passed while the manifest still said
# beta2 and SC-010 (0.40.0-beta3) was false - it verified plumbing, not the requirement.
# An acceptance criterion that fixes a LITERAL value gets a LITERAL assertion; derived assertions
# are for invariants only.
Describe 'Orientation banner renders the full prerelease version (T011 / FR-019)' {
    BeforeAll {
        $script:RepoRoot = (Resolve-Path "$PSScriptRoot/../..").Path
        $script:Provider = Join-Path $script:RepoRoot 'scripts/internal/specrew-bootstrap-provider.ps1'
        # SC-010 names this value. It is asserted LITERALLY, independent of the manifest under test.
        $script:ExpectedVersion = '0.40.0-beta3'
        $script:ModuleVersion = '0.40.0'
        $manifest = Import-PowerShellDataFile -Path (Join-Path $script:RepoRoot 'Specrew.psd1')
        $script:ManifestVersionText = '{0}-{1}' -f [string]$manifest.ModuleVersion, ([string]$manifest.PrivateData.PSData.Prerelease).Trim()

        function script:Invoke-BootstrapProvider {
            param([Parameter(Mandatory)][string]$ProjectRoot)
            $previous = $env:SPECREW_MODULE_PATH
            $env:SPECREW_MODULE_PATH = $script:RepoRoot
            try {
                return (& pwsh -NoProfile -File $script:Provider --event-json '{"source":"startup","session_id":"t011-banner"}' --project-root $ProjectRoot) -join "`n"
            }
            finally { $env:SPECREW_MODULE_PATH = $previous }
        }
    }

    BeforeEach {
        $script:Project = Join-Path ([IO.Path]::GetTempPath()) ('t011-banner-' + [Guid]::NewGuid().ToString('N'))
        New-Item -ItemType Directory -Path (Join-Path $script:Project '.specrew') -Force | Out-Null
    }

    AfterEach {
        if ($script:Project -and (Test-Path -LiteralPath $script:Project)) {
            Remove-Item -LiteralPath $script:Project -Recurse -Force -ErrorAction SilentlyContinue
        }
    }

    It 'the shipped manifest declares the version SC-010 requires' {
        # The literal check the derived version could not make: the source identity itself must be
        # beta3, or every build from this tree tells a consumer they are on the previous channel.
        $script:ManifestVersionText | Should -Be $script:ExpectedVersion
    }

    It 'the rendered directive carries the FULL prerelease version' {
        $output = script:Invoke-BootstrapProvider -ProjectRoot $script:Project

        $output | Should -Not -BeNullOrEmpty
        $output | Should -Match ([regex]::Escape($script:ExpectedVersion))
    }

    It 'the rendered directive never states the bare version without its prerelease tag' {
        $output = script:Invoke-BootstrapProvider -ProjectRoot $script:Project

        # Every occurrence of the module version must be followed by the prerelease suffix.
        $bare = [regex]::Matches($output, [regex]::Escape($script:ModuleVersion) + '(?!-)')
        $bare.Count | Should -Be 0
    }
}
