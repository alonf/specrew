$ErrorActionPreference = 'Stop'

# F-198 Iteration 005 / T038 (FR-053): minimum hook-health EVIDENCE - receipts + classification + renderer.
# Paired-honesty tests (NFR-007): a genuinely healthy fire reports `healthy`, and EVERY degraded condition
# (missing, stale, malformed, conflicting, host-version drift, adapter-contract drift) reports unverified/degraded
# and NEVER `healthy`. Plus the sanitization guarantee: a receipt carries EXACTLY the six allowed fields, so no
# prompt / argument / environment / secret can ever enter it.

BeforeDiscovery {
    # The full non-healthy scenario matrix, enumerated at discovery so each becomes its own -ForEach case.
    $script:NonHealthyScenarios = @(
        @{ Name = 'absent (no receipt at all)'; Kind = 'absent' }
        @{ Name = 'stale (older than the freshness bound)'; Kind = 'stale' }
        @{ Name = 'malformed (unparseable JSON)'; Kind = 'malformed-json' }
        @{ Name = 'malformed (extra injected field)'; Kind = 'malformed-extra' }
        @{ Name = 'malformed (missing required field)'; Kind = 'malformed-missing' }
        @{ Name = 'malformed (empty required field)'; Kind = 'malformed-empty' }
        @{ Name = 'malformed (bad timestamp)'; Kind = 'malformed-timestamp' }
        @{ Name = 'conflicting (two receipts disagree on host version)'; Kind = 'conflicting' }
        @{ Name = 'host-version drift'; Kind = 'host-drift' }
        @{ Name = 'adapter-contract drift'; Kind = 'contract-drift' }
    )
}

Describe 'F-198 T038 FR-053 hook-health receipts' {
    BeforeAll {
        $script:RepoRoot = (Resolve-Path "$PSScriptRoot/../../..").Path
        . (Join-Path $script:RepoRoot 'scripts/internal/continuous-co-review/hook-health-receipt.ps1')

        $script:BaseTime = [datetime]::Parse('2026-07-14T12:00:00Z').ToUniversalTime()
        $script:TempRoots = New-Object System.Collections.Generic.List[string]

        function New-HhrTempRoot {
            $root = Join-Path ([System.IO.Path]::GetTempPath()) ('hhr-' + [guid]::NewGuid().ToString('N'))
            New-Item -ItemType Directory -Path $root -Force | Out-Null
            $script:TempRoots.Add($root) | Out-Null
            return $root
        }

        function Write-RawReceipt {
            # Write RAW receipt content directly into the store (bypassing the sanitizing writer) so a malformed /
            # tampered receipt can be exercised.
            param([string]$Root, [string]$HostName, [string]$Surface = 'cli', [string]$Event, [string]$Content)
            $path = Get-SpecrewHookHealthReceiptPath -ProjectRoot $Root -HostName $HostName -Surface $Surface -Event $Event
            $dir = Split-Path -Parent $path
            if (-not (Test-Path -LiteralPath $dir -PathType Container)) { New-Item -ItemType Directory -Path $dir -Force | Out-Null }
            [System.IO.File]::WriteAllText($path, $Content, [System.Text.UTF8Encoding]::new($false))
            return $path
        }

        function Get-ScenarioHealth {
            # Materialize a named non-healthy scenario into a fresh root, resolve it, and return the health result.
            param([string]$Kind)
            $root = New-HhrTempRoot
            $resolveArgs = @{ ProjectRoot = $root; HostName = 'codex'; Now = $script:BaseTime.AddHours(1) }
            switch ($Kind) {
                'absent' { }
                'stale' {
                    Write-SpecrewHookHealthReceipt -ProjectRoot $root -HostName 'codex' -Event 'SessionStart' -ObservedHostVersion 'codex-cli 0.144.1' -TimestampUtc $script:BaseTime | Out-Null
                    $resolveArgs.Now = $script:BaseTime.AddHours(72)
                }
                'malformed-json' { Write-RawReceipt -Root $root -HostName 'codex' -Event 'SessionStart' -Content 'THIS_IS_NOT_JSON {{{ <<<' | Out-Null }
                'malformed-extra' { Write-RawReceipt -Root $root -HostName 'codex' -Event 'SessionStart' -Content '{"host":"codex","surface":"cli","event":"SessionStart","observed_host_version":"codex-cli 0.144.1","timestamp":"2026-07-14T12:00:00.0000000Z","adapter_contract_version":1,"secret":"leaked-token"}' | Out-Null }
                'malformed-missing' { Write-RawReceipt -Root $root -HostName 'codex' -Event 'SessionStart' -Content '{"host":"codex","surface":"cli","event":"SessionStart","timestamp":"2026-07-14T12:00:00.0000000Z","adapter_contract_version":1}' | Out-Null }
                'malformed-empty' { Write-RawReceipt -Root $root -HostName 'codex' -Event 'SessionStart' -Content '{"host":"codex","surface":"cli","event":"SessionStart","observed_host_version":"","timestamp":"2026-07-14T12:00:00.0000000Z","adapter_contract_version":1}' | Out-Null }
                'malformed-timestamp' { Write-RawReceipt -Root $root -HostName 'codex' -Event 'SessionStart' -Content '{"host":"codex","surface":"cli","event":"SessionStart","observed_host_version":"codex-cli 0.144.1","timestamp":"not-a-time","adapter_contract_version":1}' | Out-Null }
                'conflicting' {
                    Write-SpecrewHookHealthReceipt -ProjectRoot $root -HostName 'codex' -Event 'SessionStart' -ObservedHostVersion 'codex-cli 0.144.1' -TimestampUtc $script:BaseTime | Out-Null
                    Write-SpecrewHookHealthReceipt -ProjectRoot $root -HostName 'codex' -Event 'Stop' -ObservedHostVersion 'codex-cli 0.144.3' -TimestampUtc $script:BaseTime.AddMinutes(5) | Out-Null
                }
                'host-drift' {
                    Write-SpecrewHookHealthReceipt -ProjectRoot $root -HostName 'codex' -Event 'SessionStart' -ObservedHostVersion 'codex-cli 0.144.1' -TimestampUtc $script:BaseTime | Out-Null
                    $resolveArgs.ExpectedHostVersion = 'codex-cli 0.144.3'
                }
                'contract-drift' {
                    Write-SpecrewHookHealthReceipt -ProjectRoot $root -HostName 'codex' -Event 'SessionStart' -ObservedHostVersion 'codex-cli 0.144.1' -AdapterContractVersion 99 -TimestampUtc $script:BaseTime | Out-Null
                }
            }
            return (Resolve-SpecrewHookHealth @resolveArgs)
        }
    }

    AfterAll {
        foreach ($root in $script:TempRoots) { Remove-Item -LiteralPath $root -Recurse -Force -ErrorAction SilentlyContinue }
    }

    Context 'a genuine host-fired receipt reports healthy' {
        It 'classifies present + fresh + well-formed + version-matched as healthy' {
            $root = New-HhrTempRoot
            Write-SpecrewHookHealthReceipt -ProjectRoot $root -HostName 'codex' -Event 'SessionStart' -ObservedHostVersion 'codex-cli 0.144.1' -TimestampUtc $script:BaseTime | Out-Null
            $health = Resolve-SpecrewHookHealth -ProjectRoot $root -HostName 'codex' -ExpectedHostVersion 'codex-cli 0.144.1' -Now $script:BaseTime.AddHours(2)
            $health.status | Should -Be 'healthy'
            $health.receipt | Should -Not -BeNullOrEmpty
            $health.receipt.observed_host_version | Should -Be 'codex-cli 0.144.1'
        }

        It 'still healthy at the exact freshness boundary but degraded just past it' {
            $root = New-HhrTempRoot
            Write-SpecrewHookHealthReceipt -ProjectRoot $root -HostName 'codex' -Event 'Stop' -ObservedHostVersion 'codex-cli 0.144.1' -TimestampUtc $script:BaseTime | Out-Null
            (Resolve-SpecrewHookHealth -ProjectRoot $root -HostName 'codex' -FreshnessHours 24 -Now $script:BaseTime.AddHours(24)).status | Should -Be 'healthy'
            (Resolve-SpecrewHookHealth -ProjectRoot $root -HostName 'codex' -FreshnessHours 24 -Now $script:BaseTime.AddHours(24.5)).status | Should -Be 'degraded'
        }
    }

    Context 'each non-healthy condition reports the right non-healthy status' {
        It 'absent -> unverified' {
            (Get-ScenarioHealth -Kind 'absent').status | Should -Be 'unverified'
        }
        It 'stale -> degraded' {
            (Get-ScenarioHealth -Kind 'stale').status | Should -Be 'degraded'
        }
        It 'malformed (unparseable) -> degraded' {
            (Get-ScenarioHealth -Kind 'malformed-json').status | Should -Be 'degraded'
        }
        It 'malformed (extra injected field) -> degraded' {
            $r = Get-ScenarioHealth -Kind 'malformed-extra'
            $r.status | Should -Be 'degraded'
            $r.reason | Should -Match '(?i)malformed'
        }
        It 'malformed (missing required field) -> degraded' {
            (Get-ScenarioHealth -Kind 'malformed-missing').status | Should -Be 'degraded'
        }
        It 'malformed (empty required field) -> degraded' {
            (Get-ScenarioHealth -Kind 'malformed-empty').status | Should -Be 'degraded'
        }
        It 'malformed (bad timestamp) -> degraded' {
            (Get-ScenarioHealth -Kind 'malformed-timestamp').status | Should -Be 'degraded'
        }
        It 'conflicting -> degraded' {
            $r = Get-ScenarioHealth -Kind 'conflicting'
            $r.status | Should -Be 'degraded'
            $r.reason | Should -Match '(?i)conflict'
        }
        It 'host-version drift -> unverified' {
            $r = Get-ScenarioHealth -Kind 'host-drift'
            $r.status | Should -Be 'unverified'
            $r.reason | Should -Match '(?i)drift'
        }
        It 'adapter-contract drift -> unverified' {
            $r = Get-ScenarioHealth -Kind 'contract-drift'
            $r.status | Should -Be 'unverified'
            $r.reason | Should -Match '(?i)contract'
        }
    }

    Context 'NEVER healthy for any non-healthy case (the false-green guard)' {
        It '<Name> is never healthy and is a closed-set member' -ForEach $script:NonHealthyScenarios {
            $r = Get-ScenarioHealth -Kind $Kind
            $r.status | Should -Not -Be 'healthy'
            @('unverified', 'degraded') | Should -Contain $r.status
            (Get-SpecrewHookHealthStatusSet) | Should -Contain $r.status
        }
    }

    Context 'the closed status set has no assume-healthy member' {
        It 'exposes exactly healthy | unverified | degraded' {
            $set = Get-SpecrewHookHealthStatusSet
            @($set).Count | Should -Be 3
            $set | Should -Contain 'healthy'
            $set | Should -Contain 'unverified'
            $set | Should -Contain 'degraded'
        }
    }

    Context 'sanitization: the receipt carries EXACTLY the six allowed fields (no secrets/args/env)' {
        It 'writes exactly host, surface, event, observed_host_version, timestamp, adapter_contract_version' {
            $root = New-HhrTempRoot
            $w = Write-SpecrewHookHealthReceipt -ProjectRoot $root -HostName 'codex' -Event 'SessionStart' -ObservedHostVersion 'codex-cli 0.144.1' -TimestampUtc $script:BaseTime
            $parsed = Get-Content -LiteralPath $w.Path -Raw | ConvertFrom-Json
            $keys = @($parsed.PSObject.Properties.Name | Sort-Object)
            $expected = @(Get-SpecrewHookHealthReceiptFields | Sort-Object)
            ($keys -join ',') | Should -Be ($expected -join ',')
            $parsed.surface | Should -Be 'cli'
        }

        It 'sanitizes to EXACTLY the six fields and flattens control chars even when fed multi-line text (structural safety only)' {
            $root = New-HhrTempRoot
            # The WRITER's guarantee is STRUCTURAL: the field-set allow-list means caller text can only ever land in
            # observed_host_version (NEVER as a new key), and the sanitizer flattens CR/LF/TAB. VALUE-level
            # version-shape gating (collapsing a secret / argument-bearing / whitespace-laden value to 'unknown') is
            # enforced at the UNTRUSTED ambient boundary - Get-DispatcherObservedHostVersion in the dispatcher,
            # exercised by the F-198 iter-005 production-path suite (finding 3) - NOT here, because the writer cannot
            # tell a legitimate spaced host version from a secret. So feed BENIGN multi-line content (no secret) and
            # assert the structural guarantees only. (Previously this fed 'SECRET=... TOKEN=...' and accepted it
            # surviving in the value - the finding-3 false claim that the writer was the secret boundary.)
            $multiline = "1.2.3`nbuild`tmeta"
            $w = Write-SpecrewHookHealthReceipt -ProjectRoot $root -HostName 'codex' -Event 'Stop' -ObservedHostVersion $multiline -TimestampUtc $script:BaseTime
            $raw = Get-Content -LiteralPath $w.Path -Raw
            $parsed = $raw | ConvertFrom-Json
            @($parsed.PSObject.Properties.Name).Count | Should -Be 6
            foreach ($forbidden in @('prompt', 'args', 'argv', 'command', 'env', 'environment', 'secret', 'token')) {
                @($parsed.PSObject.Properties.Name) | Should -Not -Contain $forbidden
            }
            # control chars flattened (no raw CR/LF/TAB survive in the stored value)
            $parsed.observed_host_version | Should -Not -Match "[\r\n\t]"
        }

        It 'rejects a receipt that smuggles an extra field - it reads as malformed, never healthy' {
            $root = New-HhrTempRoot
            Write-RawReceipt -Root $root -HostName 'codex' -Event 'SessionStart' -Content '{"host":"codex","surface":"cli","event":"SessionStart","observed_host_version":"codex-cli 0.144.1","timestamp":"2026-07-14T12:00:00.0000000Z","adapter_contract_version":1,"secret":"leaked"}' | Out-Null
            $read = Read-SpecrewHookHealthReceiptFile -Path (Get-SpecrewHookHealthReceiptPath -ProjectRoot $root -HostName 'codex' -Event 'SessionStart')
            $read.WellFormed | Should -BeFalse
            (Resolve-SpecrewHookHealth -ProjectRoot $root -HostName 'codex' -Now $script:BaseTime.AddHours(1)).status | Should -Not -Be 'healthy'
        }
    }

    Context 'the doctor/status renderer reports the health result truthfully' {
        It 'renders each host with its resolved status and never healthy-washes a non-healthy row' {
            $root = New-HhrTempRoot
            Write-SpecrewHookHealthReceipt -ProjectRoot $root -HostName 'codex' -Event 'SessionStart' -ObservedHostVersion 'codex-cli 0.144.1' -TimestampUtc $script:BaseTime | Out-Null
            # claude has NO receipt -> must render unverified.
            $report = Format-SpecrewHookHealthReport -ProjectRoot $root -Hosts @('codex', 'claude') -Now $script:BaseTime.AddHours(1)
            $report | Should -Match 'codex\s+cli\s+healthy'
            $report | Should -Match 'claude\s+cli\s+unverified'
            $report | Should -Not -Match 'claude\s+cli\s+healthy'
        }

        It 'carries the FR-053 framing and the full status legend' {
            $report = Format-SpecrewHookHealthReport -Rows @(
                [pscustomobject]@{ host = 'codex'; surface = 'cli'; status = 'degraded'; reason = 'stale' }
            )
            $report | Should -Match '(?i)deployed hook config is NOT proof'
            $report | Should -Match '(?i)NEVER healthy'
            $report | Should -Match 'healthy'
            $report | Should -Match 'unverified'
            $report | Should -Match 'degraded'
            $report | Should -Match 'codex\s+cli\s+degraded'
        }
    }
}
