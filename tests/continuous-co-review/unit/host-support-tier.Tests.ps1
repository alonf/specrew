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

        # The maintainer-ruled seed - the EXACT tier each named host+surface must resolve to. codex/cli and
        # copilot/cli FLIPPED unverified->verified in iter-005 (2026-07-14) once their T036/T037 conformance
        # probes passed; each now carries an honest evidence provenance (asserted separately below).
        $script:ExpectedTiers = @(
            @{ HostName = 'claude';  Surface = 'cli';     Tier = 'verified' }
            @{ HostName = 'claude';  Surface = 'vscode';  Tier = 'configuration-compatible' }
            @{ HostName = 'codex';   Surface = 'cli';     Tier = 'verified' }
            @{ HostName = 'codex';   Surface = 'ide';     Tier = 'configuration-compatible' }
            @{ HostName = 'codex';   Surface = 'desktop'; Tier = 'configuration-compatible' }
            @{ HostName = 'copilot'; Surface = 'cli';     Tier = 'verified' }
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

    Context 'CLI is authoritative and every PROVEN gated surface is verified WITH honest provenance' {
        It 'classifies Claude CLI as verified (the exercised gated surface)' {
            (Get-SpecrewHostSupportTier -HostName 'claude' -Surface 'cli').tier | Should -Be 'verified'
        }

        It 'classifies Codex CLI as verified (probe passed) carrying its runner-observed + human-observed provenance' {
            $result = Get-SpecrewHostSupportTier -HostName 'codex' -Surface 'cli'
            $result.tier | Should -Be 'verified'
            # Honest provenance TRAVELS with the flip: what was runner-observed vs human-observed is recorded,
            # not a bare `verified`. The Stop response-shape gating is runner-observed; the interactive trust
            # prompt + hook execution is human-observed (maintainer, iter-005).
            $result.provenance | Should -Not -BeNullOrEmpty
            $result.provenance | Should -Match 'RUNNER-OBSERVED'
            $result.provenance | Should -Match 'HUMAN-OBSERVED'
            $result.provenance | Should -Match '(?i)decision.*block'
            # The Codex-manual continue/stopReason/systemMessage shape does NOT gate - the provenance says so.
            $result.provenance | Should -Match '(?i)does NOT gate'
            $result.rationale | Should -Match '(?i)runner-observed'
            $result.rationale | Should -Match '(?i)human-observed'
        }

        It 'records the NARROWER Codex untrusted-headless limitation SEPARATELY, not as a whole-CLI downgrade' {
            $result = Get-SpecrewHostSupportTier -HostName 'codex' -Surface 'cli'
            $result.tier | Should -Be 'verified'   # still verified - the caveat does NOT downgrade the surface
            $result.limitation | Should -Not -BeNullOrEmpty
            $result.limitation | Should -Match '(?i)untrusted'
            $result.limitation | Should -Match '(?i)headless'
            $result.limitation | Should -Match '(?i)NOT a whole-CLI downgrade'
        }

        It 'classifies Copilot CLI as verified (probe passed) carrying its runner-observed provenance' {
            $result = Get-SpecrewHostSupportTier -HostName 'copilot' -Surface 'cli'
            $result.tier | Should -Be 'verified'
            $result.provenance | Should -Not -BeNullOrEmpty
            $result.provenance | Should -Match 'RUNNER-OBSERVED'
            # both `-p` and interactive user-hook firing were runner-observed; the block gate + fail-open confirmed.
            $result.provenance | Should -Match '(?i)-p'
            $result.provenance | Should -Match '(?i)interactive'
            $result.provenance | Should -Match '(?i)fail-open'
            $result.provenance | Should -Match '(?i)decision.*block'
        }

        It 'records the Copilot repo-hook trustedFolders limitation and keeps reviewer suppression DISTINCT from bypass' {
            $result = Get-SpecrewHostSupportTier -HostName 'copilot' -Surface 'cli'
            $result.limitation | Should -Not -BeNullOrEmpty
            $result.limitation | Should -Match '(?i)trustedFolders'
            # intentional reviewer suppression (fires then no-ops) MUST stay distinct from an accidental bypass.
            $result.limitation | Should -Match '(?i)INTENTIONAL'
            $result.limitation | Should -Match '(?i)DISTINCT'
        }

        It 'leaves the non-flipped rows without a fabricated provenance (empty provenance/limitation)' {
            foreach ($pair in @(
                    @{ h = 'claude'; s = 'vscode' }
                    @{ h = 'codex'; s = 'ide' }
                    @{ h = 'copilot'; s = 'vscode' }
                    @{ h = 'cursor'; s = 'desktop' })) {
                $r = Get-SpecrewHostSupportTier -HostName $pair.h -Surface $pair.s
                $r.provenance | Should -BeNullOrEmpty
                $r.limitation | Should -BeNullOrEmpty
            }
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

        It 'renders an evidence-provenance section for the verified gated CLI surfaces (codex + copilot)' {
            $script:Report | Should -Match '(?i)Evidence provenance \(verified gated surfaces\)'
            $script:Report | Should -Match 'codex/cli:\s+.*RUNNER-OBSERVED'
            $script:Report | Should -Match 'copilot/cli:\s+.*RUNNER-OBSERVED'
            # the human-observed half of the Codex proof is surfaced (not hidden in a bare `verified`).
            $script:Report | Should -Match '(?i)HUMAN-OBSERVED'
            # the narrower limitations travel with the claim on the doctor surface.
            $script:Report | Should -Match '(?i)limitation:\s+.*untrusted'
            $script:Report | Should -Match '(?i)limitation:\s+.*trustedFolders'
        }

        It 'renders NO provenance section for a caller-supplied row set that records no provenance (StrictMode-safe)' {
            $custom = @([pscustomobject][ordered]@{ host = 'fixturehost'; surface = 'cli'; tier = 'verified'; rationale = 'fixture only' })
            $out = Format-SpecrewHostSupportTierReport -Rows $custom
            $out | Should -Not -Match '(?i)Evidence provenance \(verified gated surfaces\)'
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
