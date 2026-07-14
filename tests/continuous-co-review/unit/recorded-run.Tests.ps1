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

    It 'REDACTS credential-shaped output on an EXPLICITLY opted-in tail — a sentinel secret printed to stdout AND stderr is absent from the durable record (finding f3, run 20260714T123137002; opt-in per the 2026-07-14 default flip)' {
        $repo = New-RunRepo
        # The secret VALUES are assembled at runtime so they exist ONLY in the output streams — never as an
        # argument literal (declared arguments are recorded by design; output is the f3 leak channel).
        # -OutputTailBytes is EXPLICIT here: the default is now 0 (suppression), so redaction is the
        # defense-in-depth layer for callers who opt into a tail.
        $cmd = '[Console]::Out.WriteLine(''MY_API_TOKEN='' + (''stdout-sentinel'' + ''-secret-'' + ''9731'')); [Console]::Error.WriteLine(''password: '' + (''stderr-sentinel'' + ''-secret-'' + ''9732'')); exit 0'
        $e = Invoke-ContinuousCoReviewRecordedRun -RepoRoot $repo -Executable $script:Pwsh -Arguments @('-NoProfile', '-Command', $cmd) -OutputTailBytes 2048
        $e.command_succeeded | Should -BeTrue
        # the DURABLE record — reload from the digest-keyed store, not the in-memory return.
        $storePath = Join-Path $repo ('.specrew/review/test-evidence/' + [string]$e.reviewed_digest_tree_id + '.json')
        $raw = Get-Content -LiteralPath $storePath -Raw
        $raw | Should -Not -Match 'stdout-sentinel-secret-9731' -Because 'a credential-shaped stdout value is redacted before serialization'
        $raw | Should -Not -Match 'stderr-sentinel-secret-9732' -Because 'a credential-shaped stderr value is redacted before serialization'
        $raw | Should -Match '\[redacted\]'
        [string]$e.stdout_meta.tail_disclosure | Should -Be 'bounded-redacted-tail' -Because 'an explicit caller opt-in is labeled honestly'
        # the integrity facts still describe the RAW output.
        [int]$e.stdout_meta.byte_count | Should -BeGreaterThan 0
        [int]$e.stderr_meta.byte_count | Should -BeGreaterThan 0
    }

    It 'the DEFAULT path persists NO output text — an UNSTRUCTURED secret printed alone is absent from the durable record (maintainer decision 2026-07-14: private by default)' {
        $repo = New-RunRepo
        # The sentinel is deliberately NOT credential-shaped (no KEY=VALUE, no bearer/header syntax): a bare
        # token printed on its own line is exactly what no pattern redactor can recognize — the falsification
        # the default-suppression decision exists for.
        $cmd = '[Console]::Out.WriteLine((''svE9'' + ''kQ2rT8'' + ''xW4bare'')); [Console]::Error.WriteLine((''nZ7p'' + ''M3cJ6'' + ''hL1bare'')); exit 0'
        $e = Invoke-ContinuousCoReviewRecordedRun -RepoRoot $repo -Executable $script:Pwsh -Arguments @('-NoProfile', '-Command', $cmd)
        $e.command_succeeded | Should -BeTrue
        [string]$e.stdout_meta.truncated_tail | Should -Be ''
        [string]$e.stdout_meta.tail_disclosure | Should -Be 'suppressed'
        [string]$e.stderr_meta.tail_disclosure | Should -Be 'suppressed'
        $raw = Get-Content -LiteralPath (Join-Path $repo ('.specrew/review/test-evidence/' + [string]$e.reviewed_digest_tree_id + '.json')) -Raw
        $raw | Should -Not -Match 'svE9kQ2rT8xW4bare' -Because 'the default path persists NO output text, so an unrecognizable secret cannot leak'
        $raw | Should -Not -Match 'nZ7pM3cJ6hL1bare'
        # the integrity facts remain.
        [int]$e.stdout_meta.byte_count | Should -BeGreaterThan 0
        [string]$e.stdout_meta.sha256 | Should -Match '^[0-9a-f]{64}$'
    }

    It 'a FAILED command with suppressed output states failure_diagnostics=insufficient-without-disclosure — and stays a FAILURE (never a clean result)' {
        $repo = New-RunRepo
        $e = Invoke-ContinuousCoReviewRecordedRun -RepoRoot $repo -Executable $script:Pwsh -Arguments @('-NoProfile', '-Command', '[Console]::Error.WriteLine(''the real cause''); exit 9')
        $e.command_succeeded | Should -BeFalse
        [int]$e.exit_code | Should -Be 9
        [string]$e.failure_diagnostics | Should -Be 'insufficient-without-disclosure' -Because 'missing diagnostics are surfaced honestly, never papered over'
    }

    It 'HUMAN-AUTHORIZED diagnostic disclosure is command-SCOPED, BOUNDED, AUDITABLE, labeled sensitive, and DURABLE (maintainer decision 2026-07-14)' {
        $repo = New-RunRepo
        $cmd = '[Console]::Out.WriteLine(''diagnostic line for the reviewer''); exit 0'
        $disclosure = [pscustomobject]@{ authorized_by = 'Alon Fliess'; reason = 'failure not diagnosable from exit code alone'; command_id = 'target-cmd'; max_tail_bytes = 10485760 }
        # SCOPED: a run whose CommandId does NOT match the disclosure stays suppressed.
        $other = Invoke-ContinuousCoReviewRecordedRun -RepoRoot $repo -Executable $script:Pwsh -Arguments @('-NoProfile', '-Command', $cmd) -CommandId 'other-cmd' -DiagnosticDisclosure $disclosure
        [string]$other.stdout_meta.tail_disclosure | Should -Be 'suppressed' -Because 'disclosure is scoped to the ONE named command_id'
        $other.PSObject.Properties.Name | Should -Not -Contain 'diagnostic_disclosure'
        # APPLIED: the named command persists a bounded, redacted, sensitive-labeled tail + the audit record.
        $e = Invoke-ContinuousCoReviewRecordedRun -RepoRoot $repo -Executable $script:Pwsh -Arguments @('-NoProfile', '-Command', $cmd) -CommandId 'target-cmd' -DiagnosticDisclosure $disclosure
        [string]$e.stdout_meta.tail_disclosure | Should -Be 'authorized-diagnostic'
        [string]$e.stdout_meta.truncated_tail | Should -Match 'diagnostic line for the reviewer'
        [int]$e.diagnostic_disclosure.tail_bytes | Should -Be 8192 -Because 'a 10MB request is CLAMPED to the engine cap - disclosure is bounded, never a dump'
        [string]$e.diagnostic_disclosure.authorized_by | Should -Be 'Alon Fliess'
        [string]$e.diagnostic_disclosure.reason | Should -Not -BeNullOrEmpty
        $e.diagnostic_disclosure.potentially_sensitive | Should -BeTrue
        [string]$e.diagnostic_disclosure.durability | Should -Be 'durable-digest-bound'
        # DURABLE: the disclosure survives serialization (that is what makes it auditable).
        $rec = Get-Content -LiteralPath (Join-Path $repo ('.specrew/review/test-evidence/' + [string]$e.reviewed_digest_tree_id + '.json')) -Raw | ConvertFrom-Json
        $persisted = @($rec.runs) | Where-Object { [string]$_.command_id -eq 'target-cmd' }
        [string]$persisted.diagnostic_disclosure.authorized_by | Should -Be 'Alon Fliess'
        [string]$persisted.stdout_meta.truncated_tail | Should -Match 'diagnostic line for the reviewer'
    }

    It 'a MALFORMED disclosure authorization FAILS LOUD — never silently honored, never silently dropped' {
        $repo = New-RunRepo
        { Invoke-ContinuousCoReviewRecordedRun -RepoRoot $repo -Executable $script:Pwsh -Arguments @('-NoProfile', '-Command', 'exit 0') -CommandId 'c1' -DiagnosticDisclosure ([pscustomobject]@{ reason = 'r'; command_id = 'c1' }) } |
            Should -Throw -ExpectedMessage '*authorized_by*' -Because 'disclosure without a human authorizer is not a disclosure'
        { Invoke-ContinuousCoReviewRecordedRun -RepoRoot $repo -Executable $script:Pwsh -Arguments @('-NoProfile', '-Command', 'exit 0') -CommandId 'c1' -DiagnosticDisclosure ([pscustomobject]@{ authorized_by = 'a'; command_id = 'c1' }) } |
            Should -Throw -ExpectedMessage '*reason*'
        { Invoke-ContinuousCoReviewRecordedRun -RepoRoot $repo -Executable $script:Pwsh -Arguments @('-NoProfile', '-Command', 'exit 0') -CommandId 'c1' -DiagnosticDisclosure ([pscustomobject]@{ authorized_by = 'a'; reason = 'r' }) } |
            Should -Throw -ExpectedMessage '*command_id*' -Because 'an unscoped (blanket) disclosure is refused'
    }

    It 'a present-but-NULL counts is schema-INVALID - never treated as absent to grant structured standing (review finding f3, run 20260714T180554025)' {
        $repo = New-RunRepo
        $rp = (Join-Path $repo 'result.json') -replace '\\', '/'
        # counts:null is written literally into the artifact; the schema types counts as an OBJECT when present.
        $cmd = "Set-Content -LiteralPath '$rp' -Value '{ `"schema_version`": `"1.0`", `"result`": `"passed`", `"counts`": null }'; exit 0"
        { Invoke-ContinuousCoReviewRecordedRun -RepoRoot $repo -Executable $script:Pwsh -Arguments @('-NoProfile', '-Command', $cmd) -ResultPath 'result.json' -RequireResult } |
            Should -Throw -ExpectedMessage '*INVALID*' -Because 'counts:null must fail the required-result gate, not read as counts-absent'
    }

    It 'schema-valid counts BEYOND Int32 are recorded VERBATIM - the schema has no maximum (review finding f3, run 20260714T180554025)' {
        $repo = New-RunRepo
        $rp = (Join-Path $repo 'result.json') -replace '\\', '/'
        $big = 2147483648   # Int32.MaxValue + 1: schema-valid, previously threw in the [int] narrowing
        $cmd = "@{ schema_version='1.0'; result='passed'; counts=@{ passed=[long]$big; failed=0; skipped=0 } } | ConvertTo-Json | Set-Content -LiteralPath '$rp'; exit 0"
        $e = Invoke-ContinuousCoReviewRecordedRun -RepoRoot $repo -Executable $script:Pwsh -Arguments @('-NoProfile', '-Command', $cmd) -ResultPath 'result.json' -RequireResult
        $e.counts_available | Should -BeTrue
        [long]$e.test_result.counts.passed | Should -Be $big -Because 'a schema-valid Int64 count is recorded verbatim per FR-015, never narrowed into a throw'
        # and it survives the durable store round-trip.
        $rec = Get-Content -LiteralPath (Join-Path $repo ('.specrew/review/test-evidence/' + [string]$e.reviewed_digest_tree_id + '.json')) -Raw | ConvertFrom-Json
        [long](@($rec.runs)[0].test_result.counts.passed) | Should -Be $big
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
