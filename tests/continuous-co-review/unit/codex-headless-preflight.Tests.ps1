$ErrorActionPreference = 'Stop'

# F-198 Prop-145: the Codex headless-governance PREFLIGHT rests on FRESH HOOK-LIVENESS + the existing config/trust
# prerequisites - NOT the version (a non-promoting diagnostic). Readiness is OPERATIONAL confidence, not tamper-proof
# host authentication. It NEVER writes ~/.codex, seeds a trusted_hash, or passes --dangerously-bypass-hook-trust.

Describe 'F-198 Prop-145 Codex headless-governance preflight' {
    BeforeAll {
        $script:RepoRoot = (Resolve-Path "$PSScriptRoot/../../..").Path
        . (Join-Path $script:RepoRoot 'scripts/internal/continuous-co-review/hook-health-receipt.ps1')
        $script:BaseTime = [datetime]::Parse('2026-07-14T12:00:00Z').ToUniversalTime()
        $script:TempRoots = New-Object System.Collections.Generic.List[string]
        function New-PreflightRoot { $r = Join-Path ([System.IO.Path]::GetTempPath()) ('hhr-pf-' + [guid]::NewGuid().ToString('N')); New-Item -ItemType Directory -Path $r -Force | Out-Null; $script:TempRoots.Add($r) | Out-Null; return $r }
        function Add-CodexReceipt { param([string]$Root, [datetime]$At = $script:BaseTime, [string]$Version = 'codex-cli 0.44.0', [string]$Event = 'SessionStart') Write-SpecrewHookHealthReceipt -ProjectRoot $Root -HostName 'codex' -Event $Event -Surface 'cli' -ObservedHostVersion $Version -TimestampUtc $At | Out-Null }
        function Get-TreeSnapshot { param([string]$Root) if (-not (Test-Path -LiteralPath $Root -PathType Container)) { return @() } return @(Get-ChildItem -LiteralPath $Root -Recurse -File -Force -ErrorAction SilentlyContinue | Sort-Object FullName | ForEach-Object { '{0}|{1}|{2}' -f $_.FullName.Substring($Root.Length), $_.Length, (Get-FileHash -LiteralPath $_.FullName -Algorithm SHA256).Hash }) }
        $script:Forbidden = @('trusted host version', 'actual host-process version', 'unforgeable', 'authenticated')
    }
    AfterAll { foreach ($r in $script:TempRoots) { Remove-Item -LiteralPath $r -Recurse -Force -ErrorAction SilentlyContinue } }

    Context 'readiness rests on FRESH hook liveness (not the version)' {
        It 'a fresh codex/cli receipt -> ready' {
            $root = New-PreflightRoot; Add-CodexReceipt -Root $root
            $pf = Test-SpecrewCodexHeadlessGovernanceReady -ProjectRoot $root -Now $script:BaseTime.AddHours(1)
            $pf.ready | Should -BeTrue
            $pf.hook_status | Should -Be 'healthy'
            $pf.host | Should -Be 'codex'; $pf.surface | Should -Be 'cli'
        }
        It 'ready even when the version diagnostic drifts (version never gates readiness)' {
            $root = New-PreflightRoot; Add-CodexReceipt -Root $root -Version 'codex-cli 0.44.0'
            $pf = Test-SpecrewCodexHeadlessGovernanceReady -ProjectRoot $root -ExpectedHostVersion 'codex-cli 9.9.9' -Now $script:BaseTime.AddHours(1)
            $pf.ready | Should -BeTrue
            $pf.version_status | Should -Be 'diagnostic-drift'
        }
        It 'ready even when the version is unavailable (probe failed at SessionStart)' {
            $root = New-PreflightRoot; Add-CodexReceipt -Root $root -Version 'unknown'
            (Test-SpecrewCodexHeadlessGovernanceReady -ProjectRoot $root -Now $script:BaseTime.AddHours(1)).ready | Should -BeTrue
        }
    }

    Context 'not-ready when liveness is missing / stale, with the actionable instruction' {
        It 'no receipt -> not ready (hook_status absent)' {
            $pf = Test-SpecrewCodexHeadlessGovernanceReady -ProjectRoot (New-PreflightRoot) -Now $script:BaseTime
            $pf.ready | Should -BeFalse
            $pf.hook_status | Should -Be 'absent'
        }
        It 'stale receipt -> not ready' {
            $root = New-PreflightRoot; Add-CodexReceipt -Root $root -At $script:BaseTime
            (Test-SpecrewCodexHeadlessGovernanceReady -ProjectRoot $root -FreshnessHours 24 -Now $script:BaseTime.AddHours(72)).ready | Should -BeFalse
        }
        It 'a FUTURE-dated receipt -> not ready (malformed liveness; never a false-green under clock skew or a tampered store) (review finding f2, run 20260714T172315119)' {
            $root = New-PreflightRoot; Add-CodexReceipt -Root $root -At $script:BaseTime.AddHours(6)
            $pf = Test-SpecrewCodexHeadlessGovernanceReady -ProjectRoot $root -FreshnessHours 24 -Now $script:BaseTime
            $pf.ready | Should -BeFalse -Because 'readiness must rest on FRESH observed evidence, and a future-dated receipt is not that'
            $pf.hook_status | Should -Be 'malformed'
        }
        It 'the instruction keeps the trust/config prerequisites + operational-confidence framing' {
            $pf = Test-SpecrewCodexHeadlessGovernanceReady -ProjectRoot (New-PreflightRoot) -Now $script:BaseTime
            $pf.instruction | Should -Match '(?i)interactiv'
            $pf.instruction | Should -Match '(?i)trust'
            $pf.instruction | Should -Match '(?i)codex'
            $pf.instruction | Should -Match '(?i)NOT'
            $pf.instruction | Should -Match '(?i)bypass'
            $pf.instruction | Should -Match '(?i)operational confidence'
        }
        It 'never claims authentication / unforgeability / host-process proof (ready or not)' {
            $rd = Test-SpecrewCodexHeadlessGovernanceReady -ProjectRoot (New-PreflightRoot) -Now $script:BaseTime
            $root2 = New-PreflightRoot; Add-CodexReceipt -Root $root2
            $ry = Test-SpecrewCodexHeadlessGovernanceReady -ProjectRoot $root2 -Now $script:BaseTime.AddHours(1)
            foreach ($bad in $script:Forbidden) {
                $rd.instruction | Should -Not -Match ([regex]::Escape($bad))
                $ry.instruction | Should -Not -Match ([regex]::Escape($bad))
            }
        }
    }

    Context 'the preflight is READ-ONLY (never writes ~/.codex, never mutates state)' {
        It 'creates no file when preflighting a missing-receipt project' {
            $root = New-PreflightRoot
            $before = Get-TreeSnapshot -Root $root
            $null = Test-SpecrewCodexHeadlessGovernanceReady -ProjectRoot $root -Now $script:BaseTime
            ((Get-TreeSnapshot -Root $root) -join "`n") | Should -Be ($before -join "`n")
            (Test-Path -LiteralPath (Join-Path $root '.codex')) | Should -BeFalse
        }
        It 'does not mutate an existing receipt store' {
            $root = New-PreflightRoot; Add-CodexReceipt -Root $root
            $before = Get-TreeSnapshot -Root $root
            $null = Test-SpecrewCodexHeadlessGovernanceReady -ProjectRoot $root -Now $script:BaseTime.AddHours(1)
            ((Get-TreeSnapshot -Root $root) -join "`n") | Should -Be ($before -join "`n")
        }
    }
}
