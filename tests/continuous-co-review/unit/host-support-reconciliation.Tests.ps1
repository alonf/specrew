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

    Context 'the health closed sets + no health-washing' {
        It 'the hook-liveness set is EXACTLY {healthy, stale, malformed, conflicting, absent}' {
            $set = @(Get-SpecrewHookLivenessStatusSet)
            $set.Count | Should -Be 5
            foreach ($v in @('healthy', 'stale', 'malformed', 'conflicting', 'absent')) { $set | Should -Contain $v }
        }
        It 'the version-diagnostic set is EXACTLY {diagnostic-match, diagnostic-drift, unavailable, untrusted-source}' {
            $set = @(Get-SpecrewHookVersionStatusSet)
            $set.Count | Should -Be 4
            foreach ($v in @('diagnostic-match', 'diagnostic-drift', 'unavailable', 'untrusted-source')) { $set | Should -Contain $v }
        }
        It 'a project with NO receipt resolves hook_status=absent for every gated host - never healthy' {
            $root = New-ReconTempRoot
            foreach ($h in @('claude', 'codex', 'copilot')) {
                (Resolve-SpecrewHookHealth -ProjectRoot $root -HostName $h -Surface 'cli' -Now $script:BaseTime).hook_status | Should -Be 'absent'
            }
        }
        It 'a malformed receipt is hook_status=malformed, never healthy' {
            $root = New-ReconTempRoot
            $store = Join-Path $root '.specrew/runtime/hook-health'
            New-Item -ItemType Directory -Path $store -Force | Out-Null
            [System.IO.File]::WriteAllText((Join-Path $store 'claude-cli-stop.json'), 'THIS_IS_NOT_JSON {{{')
            (Resolve-SpecrewHookHealth -ProjectRoot $root -HostName 'claude' -Surface 'cli' -Now $script:BaseTime).hook_status | Should -Be 'malformed'
        }
        It 'a stale receipt is hook_status=stale, never healthy' {
            $root = New-ReconTempRoot
            $null = Write-SpecrewHookHealthReceipt -ProjectRoot $root -HostName 'claude' -Event 'SessionStart' -Surface 'cli' -ObservedHostVersion 'x 1.2.3' -TimestampUtc $script:BaseTime.AddHours(-100)
            (Resolve-SpecrewHookHealth -ProjectRoot $root -HostName 'claude' -Surface 'cli' -Now $script:BaseTime -FreshnessHours 24).hook_status | Should -Be 'stale'
        }
    }

    Context 'the dispatcher write path produces liveness-resolvable evidence (integration reconciliation)' {
        It 'a receipt from the dispatcher-called writer is hook_status=healthy when fresh, and carries EXACTLY the 7 sanitized fields incl version_source' {
            $root = New-ReconTempRoot
            $written = Write-SpecrewHookHealthReceipt -ProjectRoot $root -HostName 'claude' -Event 'SessionStart' -Surface 'cli' -ObservedHostVersion '1.2.3' -TimestampUtc $script:BaseTime
            $written | Should -Not -BeNullOrEmpty
            (Resolve-SpecrewHookHealth -ProjectRoot $root -HostName 'claude' -Surface 'cli' -Now $script:BaseTime.AddMinutes(5)).hook_status | Should -Be 'healthy'
            $keys = @($written.Receipt.PSObject.Properties | ForEach-Object { $_.Name }) | Sort-Object
            ($keys -join ',') | Should -Be ((@(Get-SpecrewHookHealthReceiptFields) | Sort-Object) -join ',') -Because 'exactly the seven sanitized fields, so no prompt/arg/env/secret can enter it'
        }
        It 'a dispatcher receipt stamped unknown (probe failed) is STILL hook_status=healthy but version_status=unavailable (liveness not erased)' {
            $root = New-ReconTempRoot
            $null = Write-SpecrewHookHealthReceipt -ProjectRoot $root -HostName 'claude' -Event 'SessionStart' -Surface 'cli' -ObservedHostVersion 'unknown' -TimestampUtc $script:BaseTime
            $h = Resolve-SpecrewHookHealth -ProjectRoot $root -HostName 'claude' -Surface 'cli' -ExpectedHostVersion '1.2.3' -Now $script:BaseTime.AddMinutes(5)
            $h.hook_status | Should -Be 'healthy'
            $h.version_status | Should -Be 'unavailable'
        }
    }

    Context 'a verified TIER never implies healthy hook-liveness (the two axes must not cross-contaminate)' {
        It 'codex/cli is verified in the tier model YET hook_status=absent when no receipt exists' {
            $root = New-ReconTempRoot
            (Get-SpecrewHostSupportTier -HostName 'codex' -Surface 'cli').tier | Should -Be 'verified'
            (Resolve-SpecrewHookHealth -ProjectRoot $root -HostName 'codex' -Surface 'cli' -Now $script:BaseTime).hook_status | Should -Be 'absent' -Because 'a verified surface-contract claim must never be read as live hook liveness'
        }
    }

    Context 'the doctor AGGREGATOR surfaces all three consistently and never upgrades a status' {
        It 'a no-receipt project renders verified tiers with provenance, absent hook-liveness (no healthy row), and a NOT-ready Codex preflight' {
            $root = New-ReconTempRoot
            $report = Format-SpecrewHostSupportDoctorReport -ProjectRoot $root -Hosts @('codex') -Now $script:BaseTime

            $report | Should -Match 'host-support tiers'
            $report | Should -Match 'Evidence provenance'
            $report | Should -Match 'codex/cli:'

            $report | Should -Match 'hook-health evidence'
            ($report -split "`r?`n" | Where-Object { $_ -match '^\s+(claude|codex|copilot)\s+cli\s+healthy\b' }) | Should -BeNullOrEmpty -Because 'a project with no receipts must never render a healthy hook-liveness row'

            $report | Should -Match 'governance preflight'
            $report | Should -Match 'ready to govern a headless run: NO'
        }

        It 'once a fresh codex/cli receipt exists, the aggregator reports hook liveness healthy AND the preflight flips ready (the version is only a diagnostic)' {
            $root = New-ReconTempRoot
            $null = Write-SpecrewHookHealthReceipt -ProjectRoot $root -HostName 'codex' -Event 'SessionStart' -Surface 'cli' -ObservedHostVersion '1.2.3' -TimestampUtc $script:BaseTime
            $report = Format-SpecrewHostSupportDoctorReport -ProjectRoot $root -Hosts @('codex') -Now $script:BaseTime.AddMinutes(5)
            ($report -split "`r?`n" | Where-Object { $_ -match '^\s+codex\s+cli\s+healthy\b' }) | Should -Not -BeNullOrEmpty
            $report | Should -Match 'ready to govern a headless run: YES'
        }
    }
}
