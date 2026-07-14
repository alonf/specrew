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
                    $resolveArgs.ExpectedHostVersion = 'codex-cli 0.144.1'   # pass the version match so the receipt reaches the STALE check (not the no-expected gate)
                    $resolveArgs.Now = $script:BaseTime.AddHours(72)
                }
                'malformed-json' { Write-RawReceipt -Root $root -HostName 'codex' -Event 'SessionStart' -Content 'THIS_IS_NOT_JSON {{{ <<<' | Out-Null }
                'malformed-extra' { Write-RawReceipt -Root $root -HostName 'codex' -Event 'SessionStart' -Content '{"host":"codex","surface":"cli","event":"SessionStart","observed_host_version":"codex-cli 0.144.1","timestamp":"2026-07-14T12:00:00.0000000Z","adapter_contract_version":1,"secret":"leaked-token"}' | Out-Null }
                'malformed-missing' { Write-RawReceipt -Root $root -HostName 'codex' -Event 'SessionStart' -Content '{"host":"codex","surface":"cli","event":"SessionStart","timestamp":"2026-07-14T12:00:00.0000000Z","adapter_contract_version":1}' | Out-Null }
                'malformed-empty' { Write-RawReceipt -Root $root -HostName 'codex' -Event 'SessionStart' -Content '{"host":"codex","surface":"cli","event":"SessionStart","observed_host_version":"","timestamp":"2026-07-14T12:00:00.0000000Z","adapter_contract_version":1}' | Out-Null }
                'malformed-timestamp' { Write-RawReceipt -Root $root -HostName 'codex' -Event 'SessionStart' -Content '{"host":"codex","surface":"cli","event":"SessionStart","observed_host_version":"codex-cli 0.144.1","timestamp":"not-a-time","adapter_contract_version":1}' | Out-Null }
                'conflicting' {
                    # Two well-formed SessionStart receipts (both glob-matching codex-cli-*.json, both event=SessionStart)
                    # that disagree on the observed version = internally inconsistent version evidence. A Stop receipt
                    # carries no version, so a conflict is between SessionStart receipts ONLY - constructed via raw
                    # files at the CURRENT adapter contract so the conflict (step 3b) is reached before contract drift.
                    $c = Get-SpecrewHookHealthAdapterContractVersion
                    Write-RawReceipt -Root $root -HostName 'codex' -Event 'SessionStart' -Content ('{{"host":"codex","surface":"cli","event":"SessionStart","observed_host_version":"codex-cli 0.144.1","timestamp":"2026-07-14T12:00:00.0000000Z","adapter_contract_version":{0}}}' -f $c) | Out-Null
                    Write-RawReceipt -Root $root -HostName 'codex' -Event 'sessionstart-b' -Content ('{{"host":"codex","surface":"cli","event":"SessionStart","observed_host_version":"codex-cli 0.144.3","timestamp":"2026-07-14T12:05:00.0000000Z","adapter_contract_version":{0}}}' -f $c) | Out-Null
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
            Write-SpecrewHookHealthReceipt -ProjectRoot $root -HostName 'codex' -Event 'SessionStart' -ObservedHostVersion 'codex-cli 0.144.1' -TimestampUtc $script:BaseTime | Out-Null
            (Resolve-SpecrewHookHealth -ProjectRoot $root -HostName 'codex' -ExpectedHostVersion 'codex-cli 0.144.1' -FreshnessHours 24 -Now $script:BaseTime.AddHours(24)).status | Should -Be 'healthy'
            (Resolve-SpecrewHookHealth -ProjectRoot $root -HostName 'codex' -ExpectedHostVersion 'codex-cli 0.144.1' -FreshnessHours 24 -Now $script:BaseTime.AddHours(24.5)).status | Should -Be 'degraded'
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
            # observed_host_version (NEVER as a new key), and the sanitizer flattens CR/LF/TAB. The observed version
            # itself is no longer sourced from ambient input at all - the dispatcher records ONLY a BOUNDED
            # SessionStart `--version` probe fact (Get-SpecrewHostVersionProbe), and SPECREW_OBSERVED_HOST_VERSION is
            # gone; that probe boundary is exercised by the F-198 iter-005 production-path suite (finding 3). So this
            # test feeds BENIGN multi-line content and asserts the writer's structural guarantees only.
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
            # Build the rows explicitly and render them: this asserts the RENDER is truthful (a healthy row shows
            # healthy; a receipt-less host shows unverified). The live per-host `--version` probe that a
            # ProjectRoot render performs is exercised deterministically by the production-path suite (PATH fakes),
            # not here - a unit render must not depend on which real CLI happens to be installed.
            $root = New-HhrTempRoot
            Write-SpecrewHookHealthReceipt -ProjectRoot $root -HostName 'codex' -Event 'SessionStart' -ObservedHostVersion 'codex-cli 0.144.1' -TimestampUtc $script:BaseTime | Out-Null
            $codexRow = Resolve-SpecrewHookHealth -ProjectRoot $root -HostName 'codex' -ExpectedHostVersion 'codex-cli 0.144.1' -Now $script:BaseTime.AddHours(1)
            $claudeRow = Resolve-SpecrewHookHealth -ProjectRoot $root -HostName 'claude' -Now $script:BaseTime.AddHours(1)   # no receipt -> unverified
            $report = Format-SpecrewHookHealthReport -Rows @($codexRow, $claudeRow)
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

    Context 'the host-version probe (Get-SpecrewHostVersionProbe) is bounded, shell-safe, cross-platform, and fails closed' {
        BeforeAll {
            function New-FakeHostExe {
                # Cross-platform fake host executable: a Windows .cmd shim, or a POSIX shebang script (chmod +x). The
                # behavior is chosen by INTENT so each OS emits the right script; the resolved path is returned to probe.
                param(
                    [Parameter(Mandatory)][string]$Name,
                    [string]$Version = 'codex-cli 0.44.0',
                    [switch]$Garbage, [switch]$NonZeroExit, [switch]$Hang
                )
                $dir = New-HhrTempRoot
                if ($IsWindows) {
                    $path = Join-Path $dir ($Name + '.cmd')
                    $lines = @('@echo off')
                    if ($Hang) { $lines += 'ping -n 30 127.0.0.1 >nul' }
                    if ($Garbage) { $lines += 'echo not a version at all' } else { $lines += ('echo ' + $Version) }
                    if ($NonZeroExit) { $lines += 'exit /b 3' }
                    [System.IO.File]::WriteAllText($path, ($lines -join "`r`n"), [System.Text.UTF8Encoding]::new($false))
                }
                else {
                    $path = Join-Path $dir $Name
                    $lines = @('#!/usr/bin/env sh')
                    if ($Hang) { $lines += 'sleep 30' }
                    if ($Garbage) { $lines += 'echo "not a version at all"' } else { $lines += ("echo '" + $Version + "'") }
                    if ($NonZeroExit) { $lines += 'exit 3' }
                    [System.IO.File]::WriteAllText($path, (($lines -join "`n") + "`n"), [System.Text.UTF8Encoding]::new($false))
                    [System.IO.File]::SetUnixFileMode($path, [System.IO.UnixFileMode]'UserRead,UserWrite,UserExecute,GroupRead,GroupExecute,OtherRead,OtherExecute')
                }
                return $path
            }
        }

        It 'normalizes a clean single-line version verbatim' {
            ConvertTo-SpecrewNormalizedVersionLine -Stdout "codex-cli 0.44.0`n" | Should -Be 'codex-cli 0.44.0'
        }
        It 'returns empty (malformed) when no dotted-numeric version is present' {
            ConvertTo-SpecrewNormalizedVersionLine -Stdout "Usage: codex [options]`nRuns codex" | Should -Be ''
        }
        It 'returns empty (ambiguous) when more than one line carries a version' {
            ConvertTo-SpecrewNormalizedVersionLine -Stdout "tool 1.2.3`nlib 4.5.6" | Should -Be ''
        }
        It 'probes a resolved fake executable and returns its self-reported version' {
            $exe = New-FakeHostExe -Name 'codex' -Version 'codex-cli 0.44.0'
            $p = Get-SpecrewHostVersionProbe -HostName 'codex' -CommandOverride $exe
            $p.ok | Should -BeTrue
            $p.version | Should -Be 'codex-cli 0.44.0'
        }
        It 'fails to unknown when the executable does not resolve' {
            $p = Get-SpecrewHostVersionProbe -HostName 'codex' -CommandOverride (Join-Path (New-HhrTempRoot) 'absent-host-exe')
            $p.ok | Should -BeFalse
            $p.version | Should -Be 'unknown'
        }
        It 'fails to unknown on malformed (no-version) output' {
            $exe = New-FakeHostExe -Name 'codex' -Garbage
            (Get-SpecrewHostVersionProbe -HostName 'codex' -CommandOverride $exe).version | Should -Be 'unknown'
        }
        It 'fails to unknown on a non-zero exit' {
            $exe = New-FakeHostExe -Name 'codex' -NonZeroExit
            (Get-SpecrewHostVersionProbe -HostName 'codex' -CommandOverride $exe).ok | Should -BeFalse
        }
        It 'fails to unknown on timeout (a hung probe is killed)' {
            $exe = New-FakeHostExe -Name 'codex' -Hang
            $p = Get-SpecrewHostVersionProbe -HostName 'codex' -CommandOverride $exe -TimeoutSeconds 1
            $p.ok | Should -BeFalse
            $p.version | Should -Be 'unknown'
        }
        It 'has no probe spec for an unknown host -> unknown' {
            (Get-SpecrewHostVersionProbe -HostName 'no-such-host').ok | Should -BeFalse
        }

        It 'invokes a NATIVE executable directly and returns its version (shell-free, all platforms)' {
            # A real native executable is exec'd directly (no shell). On Windows use pwsh.exe (a real .exe - the same
            # direct invocation path codex/claude take here); elsewhere the POSIX shebang fake IS the direct-exec path.
            if ($IsWindows) {
                $exe = (Get-Command pwsh -CommandType Application).Source
                $p = Get-SpecrewHostVersionProbe -HostName 'codex' -CommandOverride $exe
                $p.ok | Should -BeTrue
                $p.version | Should -Match '\d+\.\d+'
            }
            else {
                $exe = New-FakeHostExe -Name 'codex' -Version 'codex-cli 0.44.0'
                $p = Get-SpecrewHostVersionProbe -HostName 'codex' -CommandOverride $exe
                $p.ok | Should -BeTrue
                $p.version | Should -Be 'codex-cli 0.44.0'
            }
        }
        It 'refuses a Windows .cmd shim whose resolved path bears a shell metacharacter (injection guard) and never executes it' -Skip:(-not $IsWindows) {
            $dir = New-HhrTempRoot
            $injDir = Join-Path $dir 'inj&x'
            New-Item -ItemType Directory -Path $injDir -Force | Out-Null
            $marker = Join-Path $dir 'INJECTED.txt'
            $shim = Join-Path $injDir 'codex.cmd'
            [System.IO.File]::WriteAllText($shim, "@echo off`r`necho pwned>`"$marker`"`r`necho codex-cli 9.9.9", [System.Text.UTF8Encoding]::new($false))
            $p = Get-SpecrewHostVersionProbe -HostName 'codex' -CommandOverride $shim
            $p.ok | Should -BeFalse
            $p.version | Should -Be 'unknown'
            $p.problem | Should -Match 'injection guard'
            (Test-Path -LiteralPath $marker) | Should -BeFalse   # the shim never ran
        }
        It 'ignores a hijacked $env:ComSpec and binds the shim interpreter to the trusted System32 cmd.exe' -Skip:(-not $IsWindows) {
            $dir = New-HhrTempRoot
            $shim = Join-Path $dir 'codex.cmd'
            [System.IO.File]::WriteAllText($shim, "@echo off`r`necho codex-cli 0.44.0", [System.Text.UTF8Encoding]::new($false))
            $evil = Join-Path $dir 'evil.exe'
            [System.IO.File]::WriteAllText($evil, 'not a real interpreter', [System.Text.UTF8Encoding]::new($false))
            $saved = $env:ComSpec
            try {
                $env:ComSpec = $evil   # a caller controlling the environment points the "interpreter" at attacker code...
                $p = Get-SpecrewHostVersionProbe -HostName 'codex' -CommandOverride $shim
            }
            finally { $env:ComSpec = $saved }
            # ...but the probe resolves cmd.exe from the trusted System32, ignores the hijacked ComSpec, and still works.
            $p.ok | Should -BeTrue
            $p.version | Should -Be 'codex-cli 0.44.0'
        }
    }

    Context 'healthy REQUIRES a SessionStart version probe AND an independently supplied current version' {
        It 'a valid SessionStart receipt WITHOUT a supplied current version is unverified (never defaulted to accept)' {
            $root = New-HhrTempRoot
            Write-SpecrewHookHealthReceipt -ProjectRoot $root -HostName 'codex' -Event 'SessionStart' -ObservedHostVersion 'codex-cli 0.44.0' -TimestampUtc $script:BaseTime | Out-Null
            $h = Resolve-SpecrewHookHealth -ProjectRoot $root -HostName 'codex' -Now $script:BaseTime.AddHours(1)
            $h.status | Should -Be 'unverified'
            $h.status | Should -Not -Be 'healthy'
        }
        It 'a matching supplied current version yields healthy' {
            $root = New-HhrTempRoot
            Write-SpecrewHookHealthReceipt -ProjectRoot $root -HostName 'codex' -Event 'SessionStart' -ObservedHostVersion 'codex-cli 0.44.0' -TimestampUtc $script:BaseTime | Out-Null
            (Resolve-SpecrewHookHealth -ProjectRoot $root -HostName 'codex' -ExpectedHostVersion 'codex-cli 0.44.0' -Now $script:BaseTime.AddHours(1)).status | Should -Be 'healthy'
        }
        It 'a Stop-only receipt (no SessionStart version probe) is unverified even with a supplied current version' {
            $root = New-HhrTempRoot
            Write-SpecrewHookHealthReceipt -ProjectRoot $root -HostName 'codex' -Event 'Stop' -ObservedHostVersion 'unknown' -TimestampUtc $script:BaseTime | Out-Null
            (Resolve-SpecrewHookHealth -ProjectRoot $root -HostName 'codex' -ExpectedHostVersion 'codex-cli 0.44.0' -Now $script:BaseTime.AddHours(1)).status | Should -Be 'unverified'
        }
        It 'a later Stop receipt does NOT overwrite or promote the SessionStart version fact' {
            $root = New-HhrTempRoot
            Write-SpecrewHookHealthReceipt -ProjectRoot $root -HostName 'codex' -Event 'SessionStart' -ObservedHostVersion 'codex-cli 0.44.0' -TimestampUtc $script:BaseTime | Out-Null
            Write-SpecrewHookHealthReceipt -ProjectRoot $root -HostName 'codex' -Event 'Stop' -ObservedHostVersion 'unknown' -TimestampUtc $script:BaseTime.AddMinutes(30) | Out-Null
            $h = Resolve-SpecrewHookHealth -ProjectRoot $root -HostName 'codex' -ExpectedHostVersion 'codex-cli 0.44.0' -Now $script:BaseTime.AddHours(1)
            $h.status | Should -Be 'healthy'
            $h.receipt.observed_host_version | Should -Be 'codex-cli 0.44.0'   # the version fact came from SessionStart, not the later Stop
        }
        It 'a SessionStart receipt whose probe failed (observed unknown) is unverified even with a supplied current version' {
            $root = New-HhrTempRoot
            Write-SpecrewHookHealthReceipt -ProjectRoot $root -HostName 'codex' -Event 'SessionStart' -ObservedHostVersion 'unknown' -TimestampUtc $script:BaseTime | Out-Null
            (Resolve-SpecrewHookHealth -ProjectRoot $root -HostName 'codex' -ExpectedHostVersion 'codex-cli 0.44.0' -Now $script:BaseTime.AddHours(1)).status | Should -Be 'unverified'
        }
    }
}
