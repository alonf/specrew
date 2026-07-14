$ErrorActionPreference = 'Stop'

# F-198 Iteration 005 / T036 (FR-051, maintainer decision 2026-07-14): the Codex untrusted-headless governance
# PREFLIGHT. The Codex trust gate is NO-PERSISTENT-MUTATION - Codex owns its trust decision. So the preflight
# ONLY consults hook-health evidence and:
#   - reports ready ONLY when a current trusted/observed receipt exists (healthy);
#   - on absent/stale/drifted health, reports NOT ready + the actionable instruction (start Codex interactively
#     once, approve the NATIVE trust prompt) - it NEVER silently continues as governed;
#   - NEVER writes ~/.codex, NEVER seeds a trusted_hash, NEVER passes --dangerously-bypass-hook-trust;
#   - NEVER reports ready on a missing receipt (missing health is not healthy).

Describe 'F-198 T036 FR-051 Codex untrusted-headless governance preflight' {
    BeforeAll {
        $script:RepoRoot = (Resolve-Path "$PSScriptRoot/../../..").Path
        . (Join-Path $script:RepoRoot 'scripts/internal/continuous-co-review/hook-health-receipt.ps1')

        $script:BaseTime = [datetime]::Parse('2026-07-14T12:00:00Z').ToUniversalTime()
        $script:CodexVersion = 'codex-cli 0.144.1'
        $script:TempRoots = New-Object System.Collections.Generic.List[string]

        function New-PreflightRoot {
            $root = Join-Path ([System.IO.Path]::GetTempPath()) ('hhr-pf-' + [guid]::NewGuid().ToString('N'))
            New-Item -ItemType Directory -Path $root -Force | Out-Null
            $script:TempRoots.Add($root) | Out-Null
            return $root
        }

        function Get-TreeSnapshot {
            # Deterministic snapshot of every file under a root: relative path + length + content hash.
            param([string]$Root)
            if (-not (Test-Path -LiteralPath $Root -PathType Container)) { return @() }
            return @(Get-ChildItem -LiteralPath $Root -Recurse -File -Force -ErrorAction SilentlyContinue |
                    Sort-Object FullName |
                    ForEach-Object { '{0}|{1}|{2}' -f $_.FullName.Substring($Root.Length), $_.Length, (Get-FileHash -LiteralPath $_.FullName -Algorithm SHA256).Hash })
        }

        function Add-HealthyCodexReceipt {
            param([string]$Root, [datetime]$At = $script:BaseTime, [string]$Version = $script:CodexVersion)
            Write-SpecrewHookHealthReceipt -ProjectRoot $Root -HostName 'codex' -Event 'SessionStart' -ObservedHostVersion $Version -TimestampUtc $At | Out-Null
        }

        # Deterministically control the version the preflight INDEPENDENTLY probes: a fake `codex` on PATH that
        # self-reports $script:CodexVersion. This makes the internal live probe deterministic (no dependency on
        # whether/which real codex is installed) so these tests exercise the RECEIPT + readiness logic, not the host.
        # (The probe WIRING itself is also proven end to end by the production-path suite with its own PATH fakes;
        # the probe-FAILURE branch is proven below by temporarily emptying PATH.)
        $script:FakeHostDir = Join-Path ([System.IO.Path]::GetTempPath()) ('hhr-pf-bin-' + [guid]::NewGuid().ToString('N'))
        New-Item -ItemType Directory -Path $script:FakeHostDir -Force | Out-Null
        if ($IsWindows) {
            [System.IO.File]::WriteAllText((Join-Path $script:FakeHostDir 'codex.cmd'), ("@echo off`r`necho " + $script:CodexVersion), [System.Text.UTF8Encoding]::new($false))
        }
        else {
            $fk = Join-Path $script:FakeHostDir 'codex'
            [System.IO.File]::WriteAllText($fk, ("#!/usr/bin/env sh`necho '" + $script:CodexVersion + "'`n"), [System.Text.UTF8Encoding]::new($false))
            [System.IO.File]::SetUnixFileMode($fk, [System.IO.UnixFileMode]'UserRead,UserWrite,UserExecute,GroupRead,GroupExecute,OtherRead,OtherExecute')
        }
        $script:SavedPath = $env:PATH
        $env:PATH = $script:FakeHostDir + [System.IO.Path]::PathSeparator + $env:PATH
    }

    AfterAll {
        if ($null -ne $script:SavedPath) { $env:PATH = $script:SavedPath }
        if ($script:FakeHostDir -and (Test-Path -LiteralPath $script:FakeHostDir)) { Remove-Item -LiteralPath $script:FakeHostDir -Recurse -Force -ErrorAction SilentlyContinue }
        foreach ($root in $script:TempRoots) { Remove-Item -LiteralPath $root -Recurse -Force -ErrorAction SilentlyContinue }
    }

    Context 'a current trusted/observed receipt -> ready' {
        It 'reports ready = true when a fresh codex/cli receipt exists' {
            $root = New-PreflightRoot
            Add-HealthyCodexReceipt -Root $root
            $pf = Test-SpecrewCodexHeadlessGovernanceReady -ProjectRoot $root -ExpectedHostVersion $script:CodexVersion -Now $script:BaseTime.AddHours(1)
            $pf.ready | Should -BeTrue
            $pf.status | Should -Be 'healthy'
            $pf.host | Should -Be 'codex'
            $pf.surface | Should -Be 'cli'
            $pf.instruction | Should -Match '(?i)relied upon'
        }
    }

    Context 'no receipt -> NOT ready + the actionable instruction (never silent-govern)' {
        It 'reports ready = false with status unverified when NO receipt exists' {
            $root = New-PreflightRoot
            $pf = Test-SpecrewCodexHeadlessGovernanceReady -ProjectRoot $root -Now $script:BaseTime
            $pf.ready | Should -BeFalse
            $pf.status | Should -Be 'unverified'
        }

        It 'the instruction tells the user to start Codex interactively and approve the NATIVE trust prompt' {
            $root = New-PreflightRoot
            $pf = Test-SpecrewCodexHeadlessGovernanceReady -ProjectRoot $root -Now $script:BaseTime
            $pf.instruction | Should -Match '(?i)interactiv'
            $pf.instruction | Should -Match '(?i)trust'
            $pf.instruction | Should -Match '(?i)codex'
        }

        It 'the instruction explicitly refuses to write trust or bypass the gate (no-persistent-mutation)' {
            $root = New-PreflightRoot
            $pf = Test-SpecrewCodexHeadlessGovernanceReady -ProjectRoot $root -Now $script:BaseTime
            $pf.instruction | Should -Match '(?i)NOT'
            $pf.instruction | Should -Match '(?i)bypass'
            $pf.instruction | Should -Match '(?i)not proceed as governed'
        }

        It 'never reports ready on a missing receipt (missing health is not healthy)' {
            $root = New-PreflightRoot
            (Test-SpecrewCodexHeadlessGovernanceReady -ProjectRoot $root -Now $script:BaseTime).ready | Should -BeFalse
        }
    }

    Context 'a stale or drifted receipt is NOT current -> NOT ready' {
        It 'reports NOT ready when the only receipt is stale' {
            $root = New-PreflightRoot
            Add-HealthyCodexReceipt -Root $root -At $script:BaseTime
            $pf = Test-SpecrewCodexHeadlessGovernanceReady -ProjectRoot $root -FreshnessHours 24 -Now $script:BaseTime.AddHours(72)
            $pf.ready | Should -BeFalse
            $pf.status | Should -Be 'degraded'
        }

        It 'reports NOT ready when the observed host version drifted from the receipt' {
            $root = New-PreflightRoot
            Add-HealthyCodexReceipt -Root $root -Version 'codex-cli 0.144.1'
            $pf = Test-SpecrewCodexHeadlessGovernanceReady -ProjectRoot $root -ExpectedHostVersion 'codex-cli 0.144.3' -Now $script:BaseTime.AddHours(1)
            $pf.ready | Should -BeFalse
            $pf.status | Should -Be 'unverified'
        }
    }

    Context 'the preflight INDEPENDENTLY probes the live codex version (never trusts a bare receipt)' {
        It 'when the live codex probe cannot resolve, it is NOT ready even with a fresh receipt (never defaults to accept)' {
            $root = New-PreflightRoot
            Add-HealthyCodexReceipt -Root $root   # a fresh, real SessionStart receipt exists...
            $empty = New-PreflightRoot
            $saved = $env:PATH
            try {
                $env:PATH = $empty   # ...but codex cannot be resolved to independently confirm the CURRENT version
                $pf = Test-SpecrewCodexHeadlessGovernanceReady -ProjectRoot $root -Now $script:BaseTime.AddHours(1)
            }
            finally { $env:PATH = $saved }
            $pf.ready | Should -BeFalse
            $pf.status | Should -Be 'unverified'
            $pf.instruction | Should -Match '(?i)could not independently probe'
        }
    }

    Context 'the preflight is READ-ONLY (no-persistent-mutation: never writes trust, never mutates state)' {
        It 'creates no file and no .codex/trust store when preflighting a missing-receipt project' {
            $root = New-PreflightRoot
            $before = Get-TreeSnapshot -Root $root
            $null = Test-SpecrewCodexHeadlessGovernanceReady -ProjectRoot $root -Now $script:BaseTime
            $after = Get-TreeSnapshot -Root $root
            ($after -join "`n") | Should -Be ($before -join "`n")
            (Test-Path -LiteralPath (Join-Path $root '.codex')) | Should -BeFalse
            (Test-Path -LiteralPath (Get-SpecrewHookHealthStorePath -ProjectRoot $root)) | Should -BeFalse
        }

        It 'does not mutate an existing receipt store when preflighting a healthy project' {
            $root = New-PreflightRoot
            Add-HealthyCodexReceipt -Root $root
            $before = Get-TreeSnapshot -Root $root
            $null = Test-SpecrewCodexHeadlessGovernanceReady -ProjectRoot $root -Now $script:BaseTime.AddHours(1)
            $after = Get-TreeSnapshot -Root $root
            ($after -join "`n") | Should -Be ($before -join "`n")
        }
    }
}
