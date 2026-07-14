$ErrorActionPreference = 'Stop'

# F-198 Iteration 005 / T039 (FR-050 + FR-053 + FR-051): the RECONCILIATION suite.
#
# Its job is NOT to re-test the tier model (T035) or the receipt classifier (T038) in isolation - those have
# their own suites. It reconciles the THREE artifacts against each other and against the committed evidence, so
# a future edit that makes one of them lie relative to the others fails LOUD:
#   1. the host+surface TIER model (host-support-tier.ps1),
#   2. the hook-health RECEIPTS + closed status set (hook-health-receipt.ps1, the SAME writer the dispatcher calls),
#   3. the committed EVIDENCE (iterations/005/evidence/*.md) that justifies each `verified` flip,
#   4. the doctor AGGREGATOR (host-support-doctor.ps1) that surfaces all three.
#
# The load-bearing honesty invariants (NFR-001):
#   * codex/cli + copilot/cli = verified AND each carries its evidence PROVENANCE (a bare verified is the false-green).
#   * cloud (any host) = unsupported; Copilot VS Code = unsupported; an unknown host/surface = unverified.
#   * the health closed set is EXACTLY {healthy, unverified, degraded} and MISSING/stale/malformed is NEVER healthy.
#   * a `verified` TIER never implies `healthy` HEALTH - the two axes must not cross-contaminate (no health-washing
#     of a live receipt from a surface-contract claim, and no downgrade of a surface claim from a missing receipt).

Describe 'F-198 T039 host-support / hook-health / evidence reconciliation' {
    BeforeAll {
        $script:RepoRoot = (Resolve-Path "$PSScriptRoot/../../..").Path
        # The aggregator self-loads its two siblings fail-open; dot-source it, then the siblings explicitly too so
        # every function under test is present regardless of load order.
        . (Join-Path $script:RepoRoot 'scripts/internal/continuous-co-review/host-support-tier.ps1')
        . (Join-Path $script:RepoRoot 'scripts/internal/continuous-co-review/hook-health-receipt.ps1')
        . (Join-Path $script:RepoRoot 'scripts/internal/continuous-co-review/host-support-doctor.ps1')

        $script:EvidenceDir = Join-Path $script:RepoRoot 'specs/198-beta2-hardening/iterations/005/evidence'
        $script:BaseTime = [datetime]::Parse('2026-07-14T12:00:00Z').ToUniversalTime()
        $script:TempRoots = New-Object System.Collections.Generic.List[string]

        function New-ReconTempRoot {
            $root = Join-Path ([System.IO.Path]::GetTempPath()) ('recon-' + [guid]::NewGuid().ToString('N'))
            New-Item -ItemType Directory -Path $root -Force | Out-Null
            $script:TempRoots.Add($root) | Out-Null
            return $root
        }
    }

    AfterAll {
        foreach ($r in $script:TempRoots) {
            if (Test-Path -LiteralPath $r) { Remove-Item -LiteralPath $r -Recurse -Force -ErrorAction SilentlyContinue }
        }
    }

    Context 'the TIER model matches the maintainer ruling' {
        It 'codex/cli and copilot/cli are verified AND carry a non-empty evidence provenance' {
            foreach ($h in @('codex', 'copilot')) {
                $row = Get-SpecrewHostSupportTier -HostName $h -Surface 'cli'
                $row.tier | Should -Be 'verified' -Because "$h/cli flipped to verified once its conformance probe passed"
                [string]::IsNullOrWhiteSpace([string]$row.provenance) | Should -BeFalse -Because "$h/cli is a gated flip - a bare verified with no recorded evidence is the false-green this feature prevents"
            }
        }

        It 'codex/cli records its NARROWER headless-trust limitation separately (not a whole-CLI downgrade)' {
            $row = Get-SpecrewHostSupportTier -HostName 'codex' -Surface 'cli'
            [string]::IsNullOrWhiteSpace([string]$row.limitation) | Should -BeFalse
            ([string]$row.limitation) | Should -Match 'untrusted'
        }

        It 'claude/cli is verified (the original authoritative gated surface)' {
            (Get-SpecrewHostSupportTier -HostName 'claude' -Surface 'cli').tier | Should -Be 'verified'
        }

        It 'cloud is unsupported for EVERY host (known and unknown)' {
            foreach ($h in @('claude', 'codex', 'copilot', 'cursor', 'totally-unknown-host')) {
                (Get-SpecrewHostSupportTier -HostName $h -Surface 'cloud').tier | Should -Be 'unsupported'
            }
        }

        It 'Copilot VS Code is unsupported (no CLI Stop-hook enforcement claim)' {
            $row = Get-SpecrewHostSupportTier -HostName 'copilot' -Surface 'vscode'
            $row.tier | Should -Be 'unsupported'
            ([string]$row.rationale) | Should -Match 'different surface|no reliable gated'
        }

        It 'an unknown host/surface fails honest to unverified (never a fabricated verified)' {
            $row = Get-SpecrewHostSupportTier -HostName 'mystery-host' -Surface 'mystery-surface'
            $row.tier | Should -Be 'unverified'
            $row.known | Should -BeFalse
        }

        It 'every seeded tier is a member of the closed set (no fabricated tier can enter the model)' {
            $set = Get-SpecrewHostSupportTierSet
            foreach ($row in (Get-SpecrewHostSupportTierRows)) {
                $set | Should -Contain $row.tier
            }
        }
    }

    Context 'the committed EVIDENCE corroborates each verified flip' {
        It 'the Codex Stop-contract characterization exists and records the runner+human observed flip' {
            $f = Join-Path $script:EvidenceDir 'codex-stop-contract-characterization.md'
            Test-Path -LiteralPath $f -PathType Leaf | Should -BeTrue
            $body = Get-Content -LiteralPath $f -Raw
            $body | Should -Match 'unverified.*verified|verified'
            $body | Should -Match 'RUNNER-OBSERVED'
            $body | Should -Match 'HUMAN-OBSERVED'
            $body | Should -Match 'decision.{0,3}block'
        }

        It 'the Copilot CLI characterization exists and records the observed 1.0.70 contract' {
            $f = Join-Path $script:EvidenceDir 'copilot-cli-contract-characterization.md'
            Test-Path -LiteralPath $f -PathType Leaf | Should -BeTrue
            $body = Get-Content -LiteralPath $f -Raw
            $body | Should -Match '1\.0\.70'
            $body | Should -Match 'agentStop'
            $body | Should -Match 'USER-level hooks are NOT trust-gated|user hook'
        }

        It 'the tier rationale for codex/cli and copilot/cli references the probe that justified the flip' {
            (Get-SpecrewHostSupportTier -HostName 'codex' -Surface 'cli').provenance | Should -Match 'T036|runner-observed|RUNNER-OBSERVED'
            (Get-SpecrewHostSupportTier -HostName 'copilot' -Surface 'cli').provenance | Should -Match 'T037|1\.0\.70|RUNNER-OBSERVED'
        }
    }

    Context 'the HEALTH closed set never health-washes' {
        It 'the status set is EXACTLY {healthy, unverified, degraded}' {
            $set = @(Get-SpecrewHookHealthStatusSet)
            $set.Count | Should -Be 3
            $set | Should -Contain 'healthy'
            $set | Should -Contain 'unverified'
            $set | Should -Contain 'degraded'
        }

        It 'a project with NO receipt resolves unverified for every gated host - never healthy' {
            $root = New-ReconTempRoot
            foreach ($h in @('claude', 'codex', 'copilot')) {
                $health = Resolve-SpecrewHookHealth -ProjectRoot $root -HostName $h -Surface 'cli' -Now $script:BaseTime
                $health.status | Should -Be 'unverified'
                $health.status | Should -Not -Be 'healthy'
            }
        }

        It 'a malformed receipt is degraded, never healthy' {
            $root = New-ReconTempRoot
            $store = Join-Path $root '.specrew/runtime/hook-health'
            New-Item -ItemType Directory -Path $store -Force | Out-Null
            [System.IO.File]::WriteAllText((Join-Path $store 'claude-cli-stop.json'), 'THIS_IS_NOT_JSON {{{')
            $health = Resolve-SpecrewHookHealth -ProjectRoot $root -HostName 'claude' -Surface 'cli' -Now $script:BaseTime
            $health.status | Should -Be 'degraded'
            $health.status | Should -Not -Be 'healthy'
        }

        It 'a stale receipt is degraded, never healthy' {
            $root = New-ReconTempRoot
            # A receipt written the SAME way the dispatcher writes it, but far in the past -> stale.
            $stale = $script:BaseTime.AddHours(-100)
            $null = Write-SpecrewHookHealthReceipt -ProjectRoot $root -HostName 'claude' -Event 'Stop' -Surface 'cli' -ObservedHostVersion 'x' -TimestampUtc $stale
            $health = Resolve-SpecrewHookHealth -ProjectRoot $root -HostName 'claude' -Surface 'cli' -Now $script:BaseTime -FreshnessHours 24
            $health.status | Should -Be 'degraded'
            $health.status | Should -Not -Be 'healthy'
        }
    }

    Context 'the DISPATCHER write path produces health-resolvable evidence (integration reconciliation)' {
        It 'a receipt from the dispatcher-called writer resolves healthy when fresh + a REAL observed version, and carries EXACTLY the 6 sanitized fields' {
            $root = New-ReconTempRoot
            # The SAME entry point the hook dispatcher invokes on a real SessionStart/Stop fire - here with a REAL
            # observed host version (the launch path stamped SPECREW_OBSERVED_HOST_VERSION), which is what a healthy
            # receipt REQUIRES (F-198 iter-005 finding 5: an 'unknown' observed version can never read healthy).
            $written = Write-SpecrewHookHealthReceipt -ProjectRoot $root -HostName 'claude' -Event 'SessionStart' -Surface 'cli' -ObservedHostVersion '1.2.3' -TimestampUtc $script:BaseTime
            $written | Should -Not -BeNullOrEmpty
            $health = Resolve-SpecrewHookHealth -ProjectRoot $root -HostName 'claude' -Surface 'cli' -Now $script:BaseTime.AddMinutes(5)
            $health.status | Should -Be 'healthy'

            $keys = @($written.Receipt.PSObject.Properties | ForEach-Object { $_.Name }) | Sort-Object
            $expected = @(Get-SpecrewHookHealthReceiptFields) | Sort-Object
            ($keys -join ',') | Should -Be ($expected -join ',') -Because 'the receipt must be sanitized by construction - exactly the six allowed fields, so no prompt/arg/env/secret can enter it'
        }

        It 'a dispatcher receipt stamped ''unknown'' (no launch-supplied host version) resolves UNVERIFIED, never healthy (finding 5)' {
            $root = New-ReconTempRoot
            # The dispatcher stamps observed_host_version='unknown' whenever no launch path supplied
            # SPECREW_OBSERVED_HOST_VERSION. Such a receipt proves the hook fired but cannot attest WHICH host
            # version fired it, so the default doctor/preflight path (no expected version) must read it unverified -
            # NEVER healthy. This is the finding-5 false-green guard on the reconciliation surface.
            $null = Write-SpecrewHookHealthReceipt -ProjectRoot $root -HostName 'claude' -Event 'SessionStart' -Surface 'cli' -ObservedHostVersion 'unknown' -TimestampUtc $script:BaseTime
            $health = Resolve-SpecrewHookHealth -ProjectRoot $root -HostName 'claude' -Surface 'cli' -Now $script:BaseTime.AddMinutes(5)
            $health.status | Should -Be 'unverified'
            $health.status | Should -Not -Be 'healthy'
        }
    }

    Context 'a verified TIER never implies healthy HEALTH (the two axes must not cross-contaminate)' {
        It 'codex/cli is verified in the tier model YET unverified in hook-health when no receipt exists' {
            $root = New-ReconTempRoot
            (Get-SpecrewHostSupportTier -HostName 'codex' -Surface 'cli').tier | Should -Be 'verified'
            $health = Resolve-SpecrewHookHealth -ProjectRoot $root -HostName 'codex' -Surface 'cli' -Now $script:BaseTime
            $health.status | Should -Be 'unverified' -Because 'a verified surface-contract claim must NEVER be read as a live firing hook - that is the health-washing this reconciliation forbids'
        }
    }

    Context 'the doctor AGGREGATOR surfaces all three consistently and never upgrades a status' {
        It 'a no-receipt project renders verified tiers with provenance, unverified health (no healthy), and a NOT-ready Codex preflight' {
            $root = New-ReconTempRoot
            $report = Format-SpecrewHostSupportDoctorReport -ProjectRoot $root -Now $script:BaseTime

            # tiers section: the verified flips + their provenance are present.
            $report | Should -Match 'host-support tiers'
            $report | Should -Match 'Evidence provenance'
            $report | Should -Match 'codex/cli:'
            $report | Should -Match 'copilot/cli:'

            # health section: no receipts -> unverified, and NOT a single healthy row.
            $report | Should -Match 'hook-health evidence'
            ($report -split "`r?`n" | Where-Object { $_ -match '^\s+(claude|codex|copilot)\s+cli\s+healthy\b' }) | Should -BeNullOrEmpty -Because 'a project with no receipts must never render a healthy health row'

            # codex preflight: NOT ready without a current receipt.
            $report | Should -Match 'governance preflight'
            $report | Should -Match 'ready to govern a headless run: NO'
        }

        It 'once a fresh codex/cli receipt with a REAL observed version exists, the aggregator reports it healthy AND the preflight flips ready' {
            $root = New-ReconTempRoot
            # A REAL observed host version is required for healthy (finding 5) - an 'unknown' receipt stays unverified.
            $null = Write-SpecrewHookHealthReceipt -ProjectRoot $root -HostName 'codex' -Event 'Stop' -Surface 'cli' -ObservedHostVersion '1.2.3' -TimestampUtc $script:BaseTime
            $report = Format-SpecrewHostSupportDoctorReport -ProjectRoot $root -Now $script:BaseTime.AddMinutes(5)
            ($report -split "`r?`n" | Where-Object { $_ -match '^\s+codex\s+cli\s+healthy\b' }) | Should -Not -BeNullOrEmpty
            $report | Should -Match 'ready to govern a headless run: YES'
        }
    }
}
