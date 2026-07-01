#requires -Version 7.0
# T092/R2 (FR-034): when the navigator reaps a 'done' run whose status.json says completeness=partial (it reached
# its time budget), it must surface a human-gated "more time" note alongside the real (T090-harvested) partial
# findings - additive, not "it failed, retry". A FULL run gets no such offer.

BeforeAll {
    $script:repoRoot = (Resolve-Path (Join-Path $PSScriptRoot '..' '..' '..')).Path
    $env:SPECREW_MODULE_PATH = $script:repoRoot
    . (Join-Path $script:repoRoot 'scripts/internal/continuous-co-review/_load.ps1')
    . (Join-Path $script:repoRoot 'scripts/internal/continuous-co-review/continuous-co-review-navigator.ps1')
}

Describe 'navigator "more time" note on a partial reap (T092/R2)' {

    BeforeEach {
        $script:root = Join-Path ([System.IO.Path]::GetTempPath()) ('ccr-moretime-' + [guid]::NewGuid().ToString('N'))
        $script:pendingDir = Join-Path $script:root '.specrew/review/pending'
        New-Item -ItemType Directory -Path $script:pendingDir -Force | Out-Null
    }
    AfterEach { Remove-Item -LiteralPath $script:root -Recurse -Force -ErrorAction SilentlyContinue }

    It '<completeness> run -> moreTimeNote present = <expect>' -ForEach @(
        @{ completeness = 'partial'; expect = $true },
        @{ completeness = 'full'; expect = $false }
    ) {
        $runId = "run-$completeness"
        $runDir = Join-Path $script:pendingDir $runId
        New-Item -ItemType Directory -Path $runDir -Force | Out-Null
        # result.out: a valid FindingsResult with one ADVISORY (non-blocking) finding -> verdict.ok, non-pass.
        $fr = [pscustomobject]@{
            schema_version = '1.0'; run_id = $runId; status = 'findings'
            findings       = @([pscustomobject]@{ finding_id = 'f1'; source_run_id = $runId; location = [pscustomobject]@{ line_start = $null; line_end = $null }; severity = 'advisory'; kind = 'note'; design_reference = 'FR-001'; comment = 'a partial note'; disposition = 'open'; resolution = [pscustomobject]@{ state = 'unresolved'; fix_evidence_ref = $null; rationale = $null } })
            created_at     = (Get-Date).ToUniversalTime().ToString('o')
        }
        [System.IO.File]::WriteAllText((Join-Path $runDir 'result.out'), ($fr | ConvertTo-Json -Depth 100))
        ([ordered]@{ schema_version = '1.0'; run_id = $runId; status = 'done'; completeness = $completeness; timeout_seconds = 900 } | ConvertTo-Json) | Set-Content -LiteralPath (Join-Path $runDir 'status.json') -Encoding UTF8
        # registry entry: a terminal 'done' run pointing at the run dir.
        ([ordered]@{ schema_version = '1.0'; run_id = $runId; supervisor_pid = 0; worktree_path = $runDir; run_dir = $runDir; result_path = (Join-Path $runDir 'result.out'); deadline = ((Get-Date).ToUniversalTime().AddMinutes(10).ToString('o')); status = 'done'; tree_id = 'deadbeefdeadbeefdeadbeefdeadbeefdeadbeef' } | ConvertTo-Json) | Set-Content -LiteralPath (Join-Path $script:pendingDir "$runId.json") -Encoding UTF8

        $reap = Invoke-ContinuousCoReviewNavigatorReap -RepoRoot $script:root -CrossSession:$false -TrunkName 'main' -Now ([datetime]::UtcNow)
        $hasNote = (@($reap.inject_notes | Where-Object { $_ -match 'PARTIAL review' -and $_ -match 'timeout-seconds 1800' }).Count -ge 1)
        $hasNote | Should -Be $expect
    }
}
