$ErrorActionPreference = 'Stop'

# F-198 Iteration 005 / T035 (FR-050): the truthful host+surface support-tier model.
# Paired-honesty tests (NFR-007): the legitimate mapping renders each seeded tier exactly, AND the abuse path
# (an unknown host/surface, a fabricated tier, a Copilot-VS-Code / cloud governance claim) fails closed to the
# honest classification - never a fabricated `verified`.
Describe 'F-198 T035 FR-050 host+surface support-tier model' {
    BeforeAll {
        $script:RepoRoot = (Resolve-Path "$PSScriptRoot/../../..").Path
        $script:ScratchTmp = Join-Path $script:RepoRoot '.scratch/tmp'
        New-Item -ItemType Directory -Path $script:ScratchTmp -Force | Out-Null
        $env:TEMP = $script:ScratchTmp
        $env:TMP = $script:ScratchTmp
        $env:SPECREW_MODULE_PATH = $script:RepoRoot
        Import-Module (Join-Path $script:RepoRoot 'Specrew.psd1') -Force
        . (Join-Path $script:RepoRoot 'scripts/internal/continuous-co-review/_load.ps1')

        # The maintainer-ruled seed - the EXACT tier each named host+surface must resolve to.
        $script:ExpectedTiers = @(
            @{ HostName = 'claude';  Surface = 'cli';     Tier = 'verified' }
            @{ HostName = 'claude';  Surface = 'vscode';  Tier = 'configuration-compatible' }
            @{ HostName = 'codex';   Surface = 'cli';     Tier = 'unverified' }
            @{ HostName = 'codex';   Surface = 'ide';     Tier = 'configuration-compatible' }
            @{ HostName = 'codex';   Surface = 'desktop'; Tier = 'configuration-compatible' }
            @{ HostName = 'copilot'; Surface = 'cli';     Tier = 'unverified' }
            @{ HostName = 'copilot'; Surface = 'vscode';  Tier = 'unsupported' }
            @{ HostName = 'cursor';  Surface = 'desktop'; Tier = 'unverified' }
        )
    }

    Context 'the closed classification set is enforced' {
        It 'exposes exactly the four allowed tiers' {
            $set = Get-SpecrewHostSupportTierSet
            @($set).Count | Should -Be 4
            $set | Should -Contain 'verified'
            $set | Should -Contain 'configuration-compatible'
            $set | Should -Contain 'unsupported'
            $set | Should -Contain 'unverified'
        }

        It 'accepts every closed-set member and rejects a fabricated or empty tier' {
            foreach ($tier in (Get-SpecrewHostSupportTierSet)) {
                Test-SpecrewHostSupportTierValue -Tier $tier | Should -BeTrue
            }
            Test-SpecrewHostSupportTierValue -Tier 'gated' | Should -BeFalse
            Test-SpecrewHostSupportTierValue -Tier 'certified' | Should -BeFalse
            Test-SpecrewHostSupportTierValue -Tier '' | Should -BeFalse
            Test-SpecrewHostSupportTierValue -Tier $null | Should -BeFalse
        }

        It 'seeds every row with a tier drawn only from the closed set' {
            $set = @(Get-SpecrewHostSupportTierSet)
            foreach ($row in (Get-SpecrewHostSupportTierRows)) {
                $set | Should -Contain $row.tier
            }
        }

        It 'never returns a tier outside the closed set - for seeded pairs, cloud, and unknowns alike' {
            $set = @(Get-SpecrewHostSupportTierSet)
            $probe = @(
                @{ HostName = 'claude'; Surface = 'cli' }
                @{ HostName = 'copilot'; Surface = 'vscode' }
                @{ HostName = 'anything'; Surface = 'cloud' }
                @{ HostName = 'totally-unknown'; Surface = 'made-up-surface' }
            )
            foreach ($p in $probe) {
                $result = Get-SpecrewHostSupportTier -HostName $p.HostName -Surface $p.Surface
                $set | Should -Contain $result.tier
            }
        }
    }

    Context 'each host+surface resolves to its exact seeded tier' {
        It 'maps <HostName>/<Surface> to <Tier>' -ForEach $script:ExpectedTiers {
            $result = Get-SpecrewHostSupportTier -HostName $HostName -Surface $Surface
            $result.tier | Should -Be $Tier
            $result.known | Should -BeTrue
            $result.rationale | Should -Not -BeNullOrEmpty
        }
    }

    Context 'CLI is authoritative but only PROVEN surfaces are verified (honesty)' {
        It 'classifies Claude CLI as verified (the exercised gated surface)' {
            (Get-SpecrewHostSupportTier -HostName 'claude' -Surface 'cli').tier | Should -Be 'verified'
        }

        It 'holds Codex CLI at unverified until its conformance probe passes - never a false verified' {
            $result = Get-SpecrewHostSupportTier -HostName 'codex' -Surface 'cli'
            $result.tier | Should -Be 'unverified'
            $result.tier | Should -Not -Be 'verified'
            $result.rationale | Should -Match '(?i)conformance probe|not yet passed'
        }

        It 'holds Copilot CLI at unverified until its conformance probe passes - never a false verified' {
            $result = Get-SpecrewHostSupportTier -HostName 'copilot' -Surface 'cli'
            $result.tier | Should -Be 'unverified'
            $result.tier | Should -Not -Be 'verified'
        }
    }

    Context 'Copilot VS Code MUST NOT claim hook-gated CLI compatibility' {
        It 'classifies Copilot VS Code as unsupported, never verified or configuration-compatible' {
            $result = Get-SpecrewHostSupportTier -HostName 'copilot' -Surface 'vscode'
            $result.tier | Should -Be 'unsupported'
            @('verified', 'configuration-compatible') | Should -Not -Contain $result.tier
        }

        It 'resolves the VS Code surface aliases (case + "vs code" + editor) to the same unsupported verdict' {
            (Get-SpecrewHostSupportTier -HostName 'Copilot' -Surface 'VS Code').tier | Should -Be 'unsupported'
            (Get-SpecrewHostSupportTier -HostName 'copilot' -Surface 'editor').tier | Should -Be 'unsupported'
        }
    }

    Context 'no cloud-agent support may be implied (categorical)' {
        It 'classifies cloud as unsupported for every host - known or unknown' {
            foreach ($h in @('claude', 'codex', 'copilot', 'cursor', 'some-future-host')) {
                $result = Get-SpecrewHostSupportTier -HostName $h -Surface 'cloud'
                $result.tier | Should -Be 'unsupported'
            }
        }

        It 'resolves the cloud surface aliases (cloud-agent, web) to unsupported' {
            (Get-SpecrewHostSupportTier -HostName 'claude' -Surface 'cloud-agent').tier | Should -Be 'unsupported'
            (Get-SpecrewHostSupportTier -HostName 'claude' -Surface 'web').tier | Should -Be 'unsupported'
        }

        It 'seeds no row that claims a cloud surface is verified or configuration-compatible' {
            foreach ($row in (Get-SpecrewHostSupportTierRows)) {
                if ($row.surface -eq 'cloud') {
                    @('verified', 'configuration-compatible') | Should -Not -Contain $row.tier
                }
            }
        }
    }

    Context 'an unknown host/surface fails honest to unverified (never fabricated verified)' {
        It 'resolves an unknown host to unverified with known=false' {
            $result = Get-SpecrewHostSupportTier -HostName 'nonexistent-host' -Surface 'cli'
            $result.tier | Should -Be 'unverified'
            $result.tier | Should -Not -Be 'verified'
            $result.known | Should -BeFalse
        }

        It 'resolves an unknown surface on a known host to unverified with known=false' {
            $result = Get-SpecrewHostSupportTier -HostName 'claude' -Surface 'holodeck'
            $result.tier | Should -Be 'unverified'
            $result.tier | Should -Not -Be 'verified'
            $result.known | Should -BeFalse
        }
    }

    Context 'host + surface normalization' {
        It 'normalizes host aliases and casing (cursor-agent -> cursor; Claude -> claude)' {
            (Get-SpecrewHostSupportTier -HostName 'cursor-agent' -Surface 'desktop').tier | Should -Be 'unverified'
            (Get-SpecrewHostSupportTier -HostName 'Claude' -Surface 'CLI').tier | Should -Be 'verified'
        }
    }

    Context 'the doctor/status renderer' {
        BeforeAll { $script:Report = Format-SpecrewHostSupportTierReport }

        It 'renders a non-empty report' {
            $script:Report | Should -Not -BeNullOrEmpty
        }

        It 'renders every seeded host+surface with its tier' {
            foreach ($e in $script:ExpectedTiers) {
                $script:Report | Should -Match ([regex]::Escape($e.HostName))
                $script:Report | Should -Match ([regex]::Escape($e.Surface))
            }
            $script:Report | Should -Match 'copilot\s+vscode\s+unsupported'
            $script:Report | Should -Match 'claude\s+cli\s+verified'
        }

        It 'states CLI is authoritative and cloud is unsupported, and references the Beta3 issue #3084' {
            $script:Report | Should -Match '(?i)CLI is the AUTHORITATIVE supported surface'
            $script:Report | Should -Match '(?i)Cloud agents are UNSUPPORTED'
            $script:Report | Should -Match '3084'
        }

        It 'carries the full tier legend (all four classifications defined)' {
            $script:Report | Should -Match 'verified'
            $script:Report | Should -Match 'configuration-compatible'
            $script:Report | Should -Match 'unsupported'
            $script:Report | Should -Match 'unverified'
            $script:Report | Should -Match '(?i)conformance probe has not passed'
        }

        It 'never renders Copilot VS Code or cloud as verified/configuration-compatible' {
            $script:Report | Should -Not -Match 'copilot\s+vscode\s+verified'
            $script:Report | Should -Not -Match 'copilot\s+vscode\s+configuration-compatible'
            $script:Report | Should -Not -Match 'cloud\s+.*(?:^|\s)verified'
        }

        It 'renders a caller-supplied row set when provided' {
            $custom = @([pscustomobject][ordered]@{ host = 'fixturehost'; surface = 'cli'; tier = 'verified'; rationale = 'fixture only' })
            $out = Format-SpecrewHostSupportTierReport -Rows $custom
            $out | Should -Match 'fixturehost\s+cli\s+verified'
        }
    }
}
