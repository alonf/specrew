$ErrorActionPreference = 'Stop'

# Trace: T011 / FR-019 / SC-010 / ledger obs-2.
#
# The orientation banner dropped the prerelease tag, so a consumer running a beta build read
# "Specrew version 0.40.0" and could not tell they were on the beta channel. The version is
# resolved by the bootstrap provider from the module manifest; the reference composition already
# exists in scripts/specrew-start.ps1 (Get-ManifestSpecrewVersionText).
#
# Driven through the REAL event entry point (FR-023): the provider is invoked as the dispatcher
# invokes it, with --event-json, and the assertion reads its emitted directive. The expected text
# is COMPUTED from the manifest at test time, so this keeps holding after the release bumps the
# prerelease tag.
Describe 'Orientation banner renders the full prerelease version (T011 / FR-019)' {
    BeforeAll {
        $script:RepoRoot = (Resolve-Path "$PSScriptRoot/../..").Path
        $script:Provider = Join-Path $script:RepoRoot 'scripts/internal/specrew-bootstrap-provider.ps1'
        $manifest = Import-PowerShellDataFile -Path (Join-Path $script:RepoRoot 'Specrew.psd1')
        $script:ModuleVersion = [string]$manifest.ModuleVersion
        $script:Prerelease = [string]$manifest.PrivateData.PSData.Prerelease
        $script:ExpectedVersion = if ([string]::IsNullOrWhiteSpace($script:Prerelease)) {
            $script:ModuleVersion
        }
        else {
            '{0}-{1}' -f $script:ModuleVersion, $script:Prerelease.Trim()
        }

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

    It 'the manifest under test actually carries a prerelease tag (otherwise this suite proves nothing)' {
        $script:Prerelease | Should -Not -BeNullOrEmpty
        $script:ExpectedVersion | Should -Match '^\d+\.\d+\.\d+-\w+'
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
