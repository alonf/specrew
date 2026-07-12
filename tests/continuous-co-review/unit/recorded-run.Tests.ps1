$ErrorActionPreference = 'Stop'

# T018 (FR-015 amended 2026-07-13): the LANGUAGE/FRAMEWORK-NEUTRAL universal recorded-run runner. These tests use
# generic commands (pwsh exit codes, sleeps, file writes) + one Pester ADAPTER that emits the universal
# SpecrewTestResult - the core runner carries NO framework knowledge.
Describe 'T018 universal recorded-run runner (FR-015 amended - language/framework-neutral)' {
    BeforeAll {
        $script:RepoRoot = (Resolve-Path "$PSScriptRoot/../../..").Path
        $env:SPECREW_MODULE_PATH = $script:RepoRoot
        . (Join-Path $script:RepoRoot 'scripts/internal/continuous-co-review/_load.ps1')
        . (Join-Path $script:RepoRoot 'scripts/internal/continuous-co-review/worktree-reviewer.ps1')   # machinery resolver for the digest
        $script:Pwsh = (Get-Process -Id $PID).Path

        function New-RunRepo {
            $repo = Join-Path $TestDrive ([guid]::NewGuid().ToString('N'))
            New-Item -ItemType Directory -Path $repo -Force | Out-Null
            Push-Location $repo
            try {
                & git init -q 2>&1 | Out-Null
                & git config user.email 't@e.c' 2>&1 | Out-Null
                & git config user.name 'Test' 2>&1 | Out-Null
                Set-Content -LiteralPath (Join-Path $repo 'src.txt') -Value 'v0' -NoNewline
                & git add -A 2>&1 | Out-Null
                & git commit -qm base 2>&1 | Out-Null
            }
            finally { Pop-Location }
            return $repo
        }
    }

    It '1. generic SUCCESS command, no structured result -> command_succeeded, counts UNAVAILABLE (exit 0 is not "all tests passed")' {
        $repo = New-RunRepo
        $e = Invoke-ContinuousCoReviewRecordedRun -RepoRoot $repo -Executable $script:Pwsh -Arguments @('-NoProfile', '-Command', 'exit 0')
        $e.command_succeeded | Should -BeTrue
        $e.exit_code | Should -Be 0
        $e.timed_out | Should -BeFalse
        $e.counts_available | Should -BeFalse -Because 'no SpecrewTestResult -> NO counts are inferred'
        $e.test_result | Should -BeNullOrEmpty
        [string]$e.reviewed_digest_tree_id | Should -Match '^[0-9a-f]{40}$'
    }

    It '2. generic FAILING command -> command_succeeded false, real exit code recorded (no console parsing)' {
        $repo = New-RunRepo
        $e = Invoke-ContinuousCoReviewRecordedRun -RepoRoot $repo -Executable $script:Pwsh -Arguments @('-NoProfile', '-Command', 'exit 3')
        $e.command_succeeded | Should -BeFalse
        $e.exit_code | Should -Be 3
        $e.counts_available | Should -BeFalse
    }

    It '3. TIMEOUT + process-tree cleanup -> timed_out recorded, run bounded (killed at ~2s, not the full 30s)' {
        $repo = New-RunRepo
        $e = Invoke-ContinuousCoReviewRecordedRun -RepoRoot $repo -Executable $script:Pwsh -Arguments @('-NoProfile', '-Command', 'Start-Sleep -Seconds 30') -TimeoutSeconds 2
        $e.timed_out | Should -BeTrue
        $e.command_succeeded | Should -BeFalse
        $e.exit_code | Should -BeNullOrEmpty -Because 'a timed-out process has no clean exit code'
        [double]$e.duration_seconds | Should -BeLessThan 15 -Because 'the process tree was killed at ~2s, not left to run 30s'
    }

    It '4. valid SpecrewTestResult produced DURING the run -> counts recorded verbatim from the contract' {
        $repo = New-RunRepo
        $rp = (Join-Path $repo 'result.json') -replace '\\', '/'
        $cmd = "@{ schema_version='1.0'; result='passed'; counts=@{ passed=42; failed=0; skipped=3 } } | ConvertTo-Json | Set-Content -LiteralPath '$rp'; exit 0"
        $e = Invoke-ContinuousCoReviewRecordedRun -RepoRoot $repo -Executable $script:Pwsh -Arguments @('-NoProfile', '-Command', $cmd) -ResultPath 'result.json'
        $e.counts_available | Should -BeTrue
        [string]$e.test_result.source | Should -Be 'specrew-test-result'
        [string]$e.test_result.result | Should -Be 'passed'
        [int]$e.test_result.counts.passed | Should -Be 42
        [int]$e.test_result.counts.skipped | Should -Be 3
    }

    It '5. a REQUIRED result that is MISSING or MALFORMED FAILS LOUDLY (never degrades to a richer claim)' {
        $repo = New-RunRepo
        { Invoke-ContinuousCoReviewRecordedRun -RepoRoot $repo -Executable $script:Pwsh -Arguments @('-NoProfile', '-Command', 'exit 0') -ResultPath 'result.json' -RequireResult } |
            Should -Throw -ExpectedMessage '*REQUIRED*'
        $bp = (Join-Path $repo 'bad.json') -replace '\\', '/'
        $cmd = "Set-Content -LiteralPath '$bp' -Value 'not json {'; exit 0"
        { Invoke-ContinuousCoReviewRecordedRun -RepoRoot $repo -Executable $script:Pwsh -Arguments @('-NoProfile', '-Command', $cmd) -ResultPath 'bad.json' -RequireResult } |
            Should -Throw -ExpectedMessage '*INVALID*'
    }

    It '6. CALLER-SUPPLIED counts are structurally FORBIDDEN -> the runner exposes NO count parameter' {
        $params = @((Get-Command Invoke-ContinuousCoReviewRecordedRun).Parameters.Keys)
        $params | Should -Not -Contain 'Passed'
        $params | Should -Not -Contain 'Failed'
        $params | Should -Not -Contain 'Skipped'
        $params | Should -Not -Contain 'Counts'
    }

    It '7. STALE/pre-existing result is REJECTED (deleted before the run, never read as this run''s)' {
        $repo = New-RunRepo
        $rp = Join-Path $repo 'result.json'
        Set-Content -LiteralPath $rp -Value '{ "schema_version": "1.0", "result": "passed", "counts": { "passed": 999 } }'   # a STALE valid result
        { Invoke-ContinuousCoReviewRecordedRun -RepoRoot $repo -Executable $script:Pwsh -Arguments @('-NoProfile', '-Command', 'exit 0') -ResultPath 'result.json' -RequireResult } |
            Should -Throw -ExpectedMessage '*REQUIRED*' -Because 'the run produced no result; the stale one must NOT be read'
        (Test-Path -LiteralPath $rp) | Should -BeFalse -Because 'the stale result was deleted BEFORE the run'
    }

    It '8. EXACT-DIGEST binding -> evidence carries + is keyed by the current digest; a source change re-keys it' {
        $repo = New-RunRepo
        $dg = (Get-ContinuousCoReviewReviewedStateDigest -RepoRoot $repo).tree_id
        $e = Invoke-ContinuousCoReviewRecordedRun -RepoRoot $repo -Executable $script:Pwsh -Arguments @('-NoProfile', '-Command', 'exit 0')
        [string]$e.reviewed_digest_tree_id | Should -Be $dg
        (Test-Path -LiteralPath (Join-Path $repo ".specrew/review/test-evidence/$dg.json")) | Should -BeTrue -Because 'the record is keyed by the EXACT digest'
        Set-Content -LiteralPath (Join-Path $repo 'src.txt') -Value 'v1' -NoNewline   # source change -> digest flips
        $e2 = Invoke-ContinuousCoReviewRecordedRun -RepoRoot $repo -Executable $script:Pwsh -Arguments @('-NoProfile', '-Command', 'exit 0')
        [string]$e2.reviewed_digest_tree_id | Should -Not -Be $dg -Because 'a source change moves the evidence to a different digest key (the old record is orphaned)'
    }

    It '9. BOUNDED/REDACTED output -> large stdout is truncated to a bounded tail + digested, never dumped in full' {
        $repo = New-RunRepo
        $cmd = "Write-Output ('X' * 20000); exit 0"   # ~20KB stdout
        $e = Invoke-ContinuousCoReviewRecordedRun -RepoRoot $repo -Executable $script:Pwsh -Arguments @('-NoProfile', '-Command', $cmd) -OutputTailBytes 1024
        [int]$e.stdout_meta.byte_count | Should -BeGreaterThan 15000 -Because 'the FULL byte count is recorded'
        $e.stdout_meta.truncated | Should -BeTrue
        ([System.Text.Encoding]::UTF8.GetByteCount([string]$e.stdout_meta.truncated_tail)) | Should -BeLessOrEqual 1024 -Because 'only a BOUNDED tail is kept, not the 20KB dump'
        [string]$e.stdout_meta.sha256 | Should -Match '^[0-9a-f]{64}$'
    }

    It '10. a PESTER adapter emits the universal SpecrewTestResult with NO Pester logic in the core runner (adapter is downstream)' {
        $repo = New-RunRepo
        Set-Content -LiteralPath (Join-Path $repo 'sample.Tests.ps1') -Value "Describe 'x' { It 'passes' { 1 | Should -Be 1 }; It 'skips' -Skip { 1 | Should -Be 2 } }"
        # A downstream ADAPTER script runs Pester and TRANSLATES its result into the universal contract. The core
        # runner never sees Pester - it only reads the schema-valid JSON the adapter produced.
        Set-Content -LiteralPath (Join-Path $repo 'pester-adapter.ps1') -Value @'
$c = New-PesterConfiguration
$c.Run.Path = (Join-Path $PSScriptRoot 'sample.Tests.ps1')
$c.Run.PassThru = $true
$c.Output.Verbosity = 'None'
$r = Invoke-Pester -Configuration $c
$result = if ($r.FailedCount -eq 0) { 'passed' } else { 'failed' }
@{ schema_version = '1.0'; result = $result; counts = @{ passed = [int]$r.PassedCount; failed = [int]$r.FailedCount; skipped = [int]$r.SkippedCount } } |
    ConvertTo-Json | Set-Content -LiteralPath (Join-Path $PSScriptRoot 'result.json')
exit $r.FailedCount
'@
        $e = Invoke-ContinuousCoReviewRecordedRun -RepoRoot $repo -Executable $script:Pwsh -Arguments @('-NoProfile', '-File', (Join-Path $repo 'pester-adapter.ps1')) -ResultPath 'result.json' -RequireResult
        $e.command_succeeded | Should -BeTrue
        $e.counts_available | Should -BeTrue
        [string]$e.test_result.result | Should -Be 'passed'
        [int]$e.test_result.counts.passed | Should -Be 1
        [int]$e.test_result.counts.skipped | Should -Be 1
    }
}
