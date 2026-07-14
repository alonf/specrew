$ErrorActionPreference = 'Stop'

# F-198 Prop-145: hook-health = INDEPENDENT hook-LIVENESS + a NON-PROMOTING ambient-path-binding version DIAGNOSTIC.
# Hook liveness is MONITORING evidence (the receipt store is project-writable and the dispatcher can be invoked
# directly, so a same-user process could write a receipt) - `healthy` is operational confidence, never proof of the
# host process. The version NEVER promotes liveness or readiness. These tests prove the separation, the byte-cap and
# shell-safety of the probe, and the maintainer's falsifications.

Describe 'F-198 Prop-145 hook-health (liveness + version diagnostic)' {
    BeforeAll {
        $script:RepoRoot = (Resolve-Path "$PSScriptRoot/../../..").Path
        . (Join-Path $script:RepoRoot 'scripts/internal/continuous-co-review/hook-health-receipt.ps1')
        $script:BaseTime = [datetime]::Parse('2026-07-14T12:00:00Z').ToUniversalTime()
        $script:TempRoots = New-Object System.Collections.Generic.List[string]
        $script:Forbidden = @('trusted host version', 'actual host-process version', 'unforgeable', 'authenticated')

        function New-HhrTempRoot {
            $root = Join-Path ([System.IO.Path]::GetTempPath()) ('hhr-' + [guid]::NewGuid().ToString('N'))
            New-Item -ItemType Directory -Path $root -Force | Out-Null
            $script:TempRoots.Add($root) | Out-Null
            return $root
        }
        function Write-RawReceipt {
            param([string]$Root, [string]$HostName, [string]$Surface = 'cli', [string]$Event, [string]$Content)
            $path = Get-SpecrewHookHealthReceiptPath -ProjectRoot $Root -HostName $HostName -Surface $Surface -Event $Event
            $dir = Split-Path -Parent $path
            if (-not (Test-Path -LiteralPath $dir -PathType Container)) { New-Item -ItemType Directory -Path $dir -Force | Out-Null }
            [System.IO.File]::WriteAllText($path, $Content, [System.Text.UTF8Encoding]::new($false))
            return $path
        }
        function New-FakeHostExe {
            # Cross-platform fake host executable (Windows .cmd shim OR POSIX shebang script +x), chosen by intent.
            param(
                [Parameter(Mandatory)][string]$Name,
                [string]$Version = 'codex-cli 0.44.0',
                [switch]$Garbage, [switch]$NonZeroExit, [switch]$Hang, [switch]$BigStdout, [switch]$BigStderr
            )
            $dir = New-HhrTempRoot
            if ($IsWindows) {
                $path = Join-Path $dir ($Name + '.cmd')
                $lines = @('@echo off')
                if ($Hang) { $lines += 'ping -n 30 127.0.0.1 >nul' }
                if ($BigStdout) { $lines += 'for /L %%i in (1,1,400) do @echo AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA' }
                if ($BigStderr) { $lines += ('echo ' + $Version); $lines += 'for /L %%i in (1,1,400) do @echo BBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBB 1>&2' }
                if (-not ($BigStdout -or $BigStderr)) { if ($Garbage) { $lines += 'echo not a version at all' } else { $lines += ('echo ' + $Version) } }
                if ($NonZeroExit) { $lines += 'exit /b 3' }
                [System.IO.File]::WriteAllText($path, ($lines -join "`r`n"), [System.Text.UTF8Encoding]::new($false))
            }
            else {
                $path = Join-Path $dir $Name
                $lines = @('#!/usr/bin/env sh')
                if ($Hang) { $lines += 'sleep 30' }
                if ($BigStdout) { $lines += 'i=0; while [ $i -lt 400 ]; do echo AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA; i=$((i+1)); done' }
                if ($BigStderr) { $lines += ("echo '" + $Version + "'"); $lines += 'i=0; while [ $i -lt 400 ]; do echo BBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBB 1>&2; i=$((i+1)); done' }
                if (-not ($BigStdout -or $BigStderr)) { if ($Garbage) { $lines += 'echo "not a version at all"' } else { $lines += ("echo '" + $Version + "'") } }
                if ($NonZeroExit) { $lines += 'exit 3' }
                [System.IO.File]::WriteAllText($path, (($lines -join "`n") + "`n"), [System.Text.UTF8Encoding]::new($false))
                [System.IO.File]::SetUnixFileMode($path, [System.IO.UnixFileMode]'UserRead,UserWrite,UserExecute,GroupRead,GroupExecute,OtherRead,OtherExecute')
            }
            return $path
        }
    }
    AfterAll {
        foreach ($root in $script:TempRoots) { Remove-Item -LiteralPath $root -Recurse -Force -ErrorAction SilentlyContinue }
    }

    Context 'closed sets + receipt schema v3' {
        It 'exposes the hook-liveness closed set (healthy | stale | malformed | conflicting | absent)' {
            $s = Get-SpecrewHookLivenessStatusSet
            @($s).Count | Should -Be 5
            foreach ($v in @('healthy', 'stale', 'malformed', 'conflicting', 'absent')) { $s | Should -Contain $v }
        }
        It 'exposes the version-diagnostic closed set (diagnostic-match | diagnostic-drift | unavailable | untrusted-source)' {
            $s = Get-SpecrewHookVersionStatusSet
            @($s).Count | Should -Be 4
            foreach ($v in @('diagnostic-match', 'diagnostic-drift', 'unavailable', 'untrusted-source')) { $s | Should -Contain $v }
        }
        It 'the receipt carries EXACTLY the seven allowed fields incl version_source, at contract v3' {
            $root = New-HhrTempRoot
            $w = Write-SpecrewHookHealthReceipt -ProjectRoot $root -HostName 'codex' -Event 'SessionStart' -ObservedHostVersion 'codex-cli 0.44.0' -TimestampUtc $script:BaseTime
            $keys = @($w.Receipt.PSObject.Properties.Name | Sort-Object)
            ($keys -join ',') | Should -Be (@(Get-SpecrewHookHealthReceiptFields | Sort-Object) -join ',')
            $w.Receipt.version_source | Should -Be 'ambient-path-binding'
            $w.Receipt.adapter_contract_version | Should -Be 3
        }
        It 'defaults version_source to unavailable when no real version is captured' {
            $root = New-HhrTempRoot
            (Write-SpecrewHookHealthReceipt -ProjectRoot $root -HostName 'codex' -Event 'Stop' -ObservedHostVersion 'unknown' -TimestampUtc $script:BaseTime).Receipt.version_source | Should -Be 'unavailable'
        }
        It 'sanitizes to exactly seven fields, no secret/arg/env keys survive' {
            $root = New-HhrTempRoot
            $w = Write-SpecrewHookHealthReceipt -ProjectRoot $root -HostName 'codex' -Event 'SessionStart' -ObservedHostVersion "1.2.3`nbuild`tmeta" -TimestampUtc $script:BaseTime
            @($w.Receipt.PSObject.Properties.Name).Count | Should -Be 7
            foreach ($forbidden in @('prompt', 'args', 'argv', 'command', 'env', 'environment', 'secret', 'token')) {
                @($w.Receipt.PSObject.Properties.Name) | Should -Not -Contain $forbidden
            }
            $w.Receipt.observed_host_version | Should -Not -Match "[\r\n\t]"
        }
        It 'a pre-v3 receipt (missing version_source) reads as malformed (retired)' {
            $root = New-HhrTempRoot
            Write-RawReceipt -Root $root -HostName 'codex' -Event 'SessionStart' -Content '{"host":"codex","surface":"cli","event":"SessionStart","observed_host_version":"codex-cli 0.44.0","timestamp":"2026-07-14T12:00:00.0000000Z","adapter_contract_version":2}' | Out-Null
            (Resolve-SpecrewHookHealth -ProjectRoot $root -HostName 'codex' -Now $script:BaseTime.AddHours(1)).hook_status | Should -Be 'malformed'
        }
    }

    Context 'hook LIVENESS is INDEPENDENT of the version diagnostic' {
        It 'a fresh, well-formed receipt is hook_status=healthy even when version_status=unavailable' {
            $root = New-HhrTempRoot
            Write-SpecrewHookHealthReceipt -ProjectRoot $root -HostName 'codex' -Event 'SessionStart' -ObservedHostVersion 'codex-cli 0.44.0' -TimestampUtc $script:BaseTime | Out-Null
            $h = Resolve-SpecrewHookHealth -ProjectRoot $root -HostName 'codex' -Now $script:BaseTime.AddHours(1)
            $h.hook_status | Should -Be 'healthy'
            $h.version_status | Should -Be 'unavailable'
        }
        It 'version probe failure (observed unknown) does NOT erase hook liveness' {
            $root = New-HhrTempRoot
            Write-SpecrewHookHealthReceipt -ProjectRoot $root -HostName 'codex' -Event 'SessionStart' -ObservedHostVersion 'unknown' -TimestampUtc $script:BaseTime | Out-Null
            $h = Resolve-SpecrewHookHealth -ProjectRoot $root -HostName 'codex' -ExpectedHostVersion 'codex-cli 0.44.0' -Now $script:BaseTime.AddHours(1)
            $h.hook_status | Should -Be 'healthy'
            $h.version_status | Should -Be 'unavailable'
        }
        It 'a version diagnostic-drift does NOT demote hook liveness' {
            $root = New-HhrTempRoot
            Write-SpecrewHookHealthReceipt -ProjectRoot $root -HostName 'codex' -Event 'SessionStart' -ObservedHostVersion 'codex-cli 0.44.0' -TimestampUtc $script:BaseTime | Out-Null
            $h = Resolve-SpecrewHookHealth -ProjectRoot $root -HostName 'codex' -ExpectedHostVersion 'codex-cli 9.9.9' -Now $script:BaseTime.AddHours(1)
            $h.hook_status | Should -Be 'healthy'
            $h.version_status | Should -Be 'diagnostic-drift'
        }
        It 'a matching current reading is version_status=diagnostic-match (still just a diagnostic)' {
            $root = New-HhrTempRoot
            Write-SpecrewHookHealthReceipt -ProjectRoot $root -HostName 'codex' -Event 'SessionStart' -ObservedHostVersion 'codex-cli 0.44.0' -TimestampUtc $script:BaseTime | Out-Null
            (Resolve-SpecrewHookHealth -ProjectRoot $root -HostName 'codex' -ExpectedHostVersion 'codex-cli 0.44.0' -Now $script:BaseTime.AddHours(1)).version_status | Should -Be 'diagnostic-match'
        }
    }

    Context 'non-healthy liveness (a forged-looking but malformed/stale/conflicting/wrong-host/wrong-contract receipt cannot be healthy)' {
        It 'absent -> hook_status=absent' {
            (Resolve-SpecrewHookHealth -ProjectRoot (New-HhrTempRoot) -HostName 'codex' -Now $script:BaseTime).hook_status | Should -Be 'absent'
        }
        It 'stale -> hook_status=stale' {
            $root = New-HhrTempRoot
            Write-SpecrewHookHealthReceipt -ProjectRoot $root -HostName 'codex' -Event 'SessionStart' -ObservedHostVersion 'codex-cli 0.44.0' -TimestampUtc $script:BaseTime.AddHours(-100) | Out-Null
            (Resolve-SpecrewHookHealth -ProjectRoot $root -HostName 'codex' -FreshnessHours 24 -Now $script:BaseTime).hook_status | Should -Be 'stale'
        }
        It 'malformed JSON -> hook_status=malformed' {
            $root = New-HhrTempRoot
            Write-RawReceipt -Root $root -HostName 'codex' -Event 'SessionStart' -Content 'NOT JSON {{{' | Out-Null
            (Resolve-SpecrewHookHealth -ProjectRoot $root -HostName 'codex' -Now $script:BaseTime.AddHours(1)).hook_status | Should -Be 'malformed'
        }
        It 'an extra injected field -> malformed' {
            $root = New-HhrTempRoot
            Write-RawReceipt -Root $root -HostName 'codex' -Event 'SessionStart' -Content '{"host":"codex","surface":"cli","event":"SessionStart","observed_host_version":"codex-cli 0.44.0","version_source":"ambient-path-binding","timestamp":"2026-07-14T12:00:00.0000000Z","adapter_contract_version":3,"secret":"leak"}' | Out-Null
            (Resolve-SpecrewHookHealth -ProjectRoot $root -HostName 'codex' -Now $script:BaseTime.AddHours(1)).hook_status | Should -Be 'malformed'
        }
        It 'wrong-host (receipt host field disagrees with the requested host) -> conflicting' {
            $root = New-HhrTempRoot
            Write-RawReceipt -Root $root -HostName 'codex' -Event 'SessionStart' -Content '{"host":"claude","surface":"cli","event":"SessionStart","observed_host_version":"x 0.1.0","version_source":"ambient-path-binding","timestamp":"2026-07-14T12:00:00.0000000Z","adapter_contract_version":3}' | Out-Null
            (Resolve-SpecrewHookHealth -ProjectRoot $root -HostName 'codex' -Now $script:BaseTime.AddHours(1)).hook_status | Should -Be 'conflicting'
        }
        It 'wrong-contract -> malformed' {
            $root = New-HhrTempRoot
            Write-RawReceipt -Root $root -HostName 'codex' -Event 'SessionStart' -Content '{"host":"codex","surface":"cli","event":"SessionStart","observed_host_version":"x 0.1.0","version_source":"ambient-path-binding","timestamp":"2026-07-14T12:00:00.0000000Z","adapter_contract_version":99}' | Out-Null
            (Resolve-SpecrewHookHealth -ProjectRoot $root -HostName 'codex' -Now $script:BaseTime.AddHours(1)).hook_status | Should -Be 'malformed'
        }
        It 'conflicting SessionStart versions -> conflicting' {
            $root = New-HhrTempRoot
            Write-RawReceipt -Root $root -HostName 'codex' -Event 'SessionStart' -Content '{"host":"codex","surface":"cli","event":"SessionStart","observed_host_version":"codex-cli 0.44.0","version_source":"ambient-path-binding","timestamp":"2026-07-14T12:00:00.0000000Z","adapter_contract_version":3}' | Out-Null
            Write-RawReceipt -Root $root -HostName 'codex' -Event 'sessionstart-b' -Content '{"host":"codex","surface":"cli","event":"SessionStart","observed_host_version":"codex-cli 0.99.9","version_source":"ambient-path-binding","timestamp":"2026-07-14T12:05:00.0000000Z","adapter_contract_version":3}' | Out-Null
            (Resolve-SpecrewHookHealth -ProjectRoot $root -HostName 'codex' -Now $script:BaseTime.AddHours(1)).hook_status | Should -Be 'conflicting'
        }
    }

    Context 'PATH substitution: a substituted shim is only a version DIAGNOSTIC, never promotes liveness/readiness' {
        It 'a version diagnostic-match cannot promote a STALE receipt to healthy (version never rescues liveness)' {
            $root = New-HhrTempRoot
            Write-SpecrewHookHealthReceipt -ProjectRoot $root -HostName 'codex' -Event 'SessionStart' -ObservedHostVersion 'shim 1.2.3' -TimestampUtc $script:BaseTime.AddHours(-100) | Out-Null
            $h = Resolve-SpecrewHookHealth -ProjectRoot $root -HostName 'codex' -ExpectedHostVersion 'shim 1.2.3' -FreshnessHours 24 -Now $script:BaseTime
            $h.version_status | Should -Be 'diagnostic-match'
            $h.hook_status | Should -Be 'stale'
        }
        It 'SessionStart and the current probe agreeing on the same substituted shim remain only diagnostic' {
            $root = New-HhrTempRoot
            Write-SpecrewHookHealthReceipt -ProjectRoot $root -HostName 'codex' -Event 'SessionStart' -ObservedHostVersion 'shim 9.9.9' -TimestampUtc $script:BaseTime | Out-Null
            $h = Resolve-SpecrewHookHealth -ProjectRoot $root -HostName 'codex' -ExpectedHostVersion 'shim 9.9.9' -Now $script:BaseTime.AddHours(1)
            $h.version_status | Should -Be 'diagnostic-match'
            $h.version_source | Should -Be 'ambient-path-binding'
        }
        It 'an unrecognized version_source reads version_status=untrusted-source, never a match' {
            $root = New-HhrTempRoot
            Write-RawReceipt -Root $root -HostName 'codex' -Event 'SessionStart' -Content '{"host":"codex","surface":"cli","event":"SessionStart","observed_host_version":"codex-cli 0.44.0","version_source":"forged-source","timestamp":"2026-07-14T12:00:00.0000000Z","adapter_contract_version":3}' | Out-Null
            (Resolve-SpecrewHookHealth -ProjectRoot $root -HostName 'codex' -ExpectedHostVersion 'codex-cli 0.44.0' -Now $script:BaseTime.AddHours(1)).version_status | Should -Be 'untrusted-source'
        }
    }

    Context 'no output claims authentication / unforgeability / host-process proof' {
        It 'the doctor report contains none of the forbidden claims' {
            $root = New-HhrTempRoot
            Write-SpecrewHookHealthReceipt -ProjectRoot $root -HostName 'codex' -Event 'SessionStart' -ObservedHostVersion 'codex-cli 0.44.0' -TimestampUtc $script:BaseTime | Out-Null
            $report = Format-SpecrewHookHealthReport -Rows @(Resolve-SpecrewHookHealth -ProjectRoot $root -HostName 'codex' -Now $script:BaseTime.AddHours(1))
            foreach ($bad in $script:Forbidden) { $report | Should -Not -Match ([regex]::Escape($bad)) }
        }
        It 'the preflight instruction states operational confidence, not authentication' {
            $root = New-HhrTempRoot
            Write-SpecrewHookHealthReceipt -ProjectRoot $root -HostName 'codex' -Event 'SessionStart' -Surface 'cli' -ObservedHostVersion 'codex-cli 0.44.0' -TimestampUtc $script:BaseTime | Out-Null
            $pf = Test-SpecrewCodexHeadlessGovernanceReady -ProjectRoot $root -Now $script:BaseTime.AddHours(1)
            $pf.instruction | Should -Match '(?i)operational confidence'
            foreach ($bad in $script:Forbidden) { $pf.instruction | Should -Not -Match ([regex]::Escape($bad)) }
        }
    }

    Context 'the version probe normalizes + is bounded, shell-safe, cross-platform, fail-closed' {
        It 'normalizes a clean single-line version verbatim' {
            ConvertTo-SpecrewNormalizedVersionLine -Stdout "codex-cli 0.44.0`n" | Should -Be 'codex-cli 0.44.0'
        }
        It 'returns empty (malformed) with no dotted-numeric version' {
            ConvertTo-SpecrewNormalizedVersionLine -Stdout "Usage: codex" | Should -Be ''
        }
        It 'returns empty (ambiguous) with more than one version line' {
            ConvertTo-SpecrewNormalizedVersionLine -Stdout "tool 1.2.3`nlib 4.5.6" | Should -Be ''
        }
        It 'probes a resolved fake executable (source ambient-path-binding)' {
            $p = Get-SpecrewHostVersionProbe -HostName 'codex' -CommandOverride (New-FakeHostExe -Name 'codex' -Version 'codex-cli 0.44.0')
            $p.ok | Should -BeTrue
            $p.version | Should -Be 'codex-cli 0.44.0'
            $p.source | Should -Be 'ambient-path-binding'
        }
        It 'fails to unknown when the executable does not resolve' {
            (Get-SpecrewHostVersionProbe -HostName 'codex' -CommandOverride (Join-Path (New-HhrTempRoot) 'absent-host-exe')).ok | Should -BeFalse
        }
        It 'fails to unknown on malformed (no-version) output' {
            (Get-SpecrewHostVersionProbe -HostName 'codex' -CommandOverride (New-FakeHostExe -Name 'codex' -Garbage)).version | Should -Be 'unknown'
        }
        It 'fails to unknown on a non-zero exit' {
            (Get-SpecrewHostVersionProbe -HostName 'codex' -CommandOverride (New-FakeHostExe -Name 'codex' -NonZeroExit)).ok | Should -BeFalse
        }
        It 'fails closed on OVERSIZED stdout (byte cap)' {
            $p = Get-SpecrewHostVersionProbe -HostName 'codex' -CommandOverride (New-FakeHostExe -Name 'codex' -BigStdout)
            $p.ok | Should -BeFalse
            $p.version | Should -Be 'unknown'
        }
        It 'fails closed on OVERSIZED stderr (byte cap), even with a valid version on stdout' {
            $p = Get-SpecrewHostVersionProbe -HostName 'codex' -CommandOverride (New-FakeHostExe -Name 'codex' -BigStderr)
            $p.ok | Should -BeFalse
            $p.version | Should -Be 'unknown'
        }
        It 'fails closed on timeout and kills the process tree promptly' {
            $sw = [System.Diagnostics.Stopwatch]::StartNew()
            $p = Get-SpecrewHostVersionProbe -HostName 'codex' -CommandOverride (New-FakeHostExe -Name 'codex' -Hang) -TimeoutSeconds 1
            $sw.Stop()
            $p.ok | Should -BeFalse
            $sw.Elapsed.TotalSeconds | Should -BeLessThan 8
        }
        It 'output-limit failure never becomes a version (stays unknown -> version_status unavailable)' {
            $root = New-HhrTempRoot
            Write-SpecrewHookHealthReceipt -ProjectRoot $root -HostName 'codex' -Event 'SessionStart' -ObservedHostVersion 'unknown' -TimestampUtc $script:BaseTime | Out-Null
            (Resolve-SpecrewHookHealth -ProjectRoot $root -HostName 'codex' -ExpectedHostVersion 'x 1.2.3' -Now $script:BaseTime.AddHours(1)).version_status | Should -Be 'unavailable'
        }
        It 'has no probe spec for an unknown host -> unknown' {
            (Get-SpecrewHostVersionProbe -HostName 'no-such-host').ok | Should -BeFalse
        }
        It 'invokes a NATIVE executable directly (shell-free, all platforms)' {
            if ($IsWindows) {
                $p = Get-SpecrewHostVersionProbe -HostName 'codex' -CommandOverride (Get-Command pwsh -CommandType Application).Source
                $p.ok | Should -BeTrue
                $p.version | Should -Match '\d+\.\d+'
            }
            else {
                (Get-SpecrewHostVersionProbe -HostName 'codex' -CommandOverride (New-FakeHostExe -Name 'codex' -Version 'codex-cli 0.44.0')).version | Should -Be 'codex-cli 0.44.0'
            }
        }
        It 'refuses a Windows shim path bearing a shell metacharacter (injection guard) and never executes it' -Skip:(-not $IsWindows) {
            $dir = New-HhrTempRoot
            $injDir = Join-Path $dir 'inj&x'
            New-Item -ItemType Directory -Path $injDir -Force | Out-Null
            $marker = Join-Path $dir 'INJECTED.txt'
            [System.IO.File]::WriteAllText((Join-Path $injDir 'codex.cmd'), "@echo off`r`necho pwned>`"$marker`"`r`necho codex-cli 9.9.9", [System.Text.UTF8Encoding]::new($false))
            $p = Get-SpecrewHostVersionProbe -HostName 'codex' -CommandOverride (Join-Path $injDir 'codex.cmd')
            $p.ok | Should -BeFalse
            $p.problem | Should -Match 'injection guard'
            (Test-Path -LiteralPath $marker) | Should -BeFalse
        }
        It 'ignores a hijacked $env:ComSpec and binds the shim interpreter to the trusted System32 cmd.exe' -Skip:(-not $IsWindows) {
            $dir = New-HhrTempRoot
            $shim = Join-Path $dir 'codex.cmd'
            [System.IO.File]::WriteAllText($shim, "@echo off`r`necho codex-cli 0.44.0", [System.Text.UTF8Encoding]::new($false))
            $evil = Join-Path $dir 'evil.exe'
            [System.IO.File]::WriteAllText($evil, 'not a real interpreter', [System.Text.UTF8Encoding]::new($false))
            $saved = $env:ComSpec
            try { $env:ComSpec = $evil; $p = Get-SpecrewHostVersionProbe -HostName 'codex' -CommandOverride $shim }
            finally { $env:ComSpec = $saved }
            $p.ok | Should -BeTrue
            $p.version | Should -Be 'codex-cli 0.44.0'
        }
    }

    Context 'the doctor report renders the independent fields truthfully' {
        It 'shows hook liveness + version diagnostic + source, never health-washing' {
            $root = New-HhrTempRoot
            Write-SpecrewHookHealthReceipt -ProjectRoot $root -HostName 'codex' -Event 'SessionStart' -ObservedHostVersion 'codex-cli 0.44.0' -TimestampUtc $script:BaseTime | Out-Null
            $codexRow = Resolve-SpecrewHookHealth -ProjectRoot $root -HostName 'codex' -ExpectedHostVersion 'codex-cli 0.44.0' -Now $script:BaseTime.AddHours(1)
            $claudeRow = Resolve-SpecrewHookHealth -ProjectRoot $root -HostName 'claude' -Now $script:BaseTime.AddHours(1)   # absent
            $report = Format-SpecrewHookHealthReport -Rows @($codexRow, $claudeRow)
            $report | Should -Match 'codex\s+cli\s+healthy\s+diagnostic-match'
            $report | Should -Match 'claude\s+cli\s+absent'
            $report | Should -Match '(?i)monitoring evidence'
            $report | Should -Match '(?i)non-authoritative'
        }
    }
}
