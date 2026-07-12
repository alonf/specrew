#requires -Version 7.0
$ErrorActionPreference = 'Stop'

# FILE-PRIMARY acceptance (maintainer option-1 with strict qualification, 2026-07-12). A reviewer host that
# DELIVERS its review by writing .review/findings.jsonl and exits 0 with EMPTY stdout (codex exec) has produced a
# COMPLETE review; the engine must accept it (no T108 retry, completeness='full') ONLY when every strict condition
# holds, and FAIL CLOSED otherwise (keeping the retry/lenient-harvest/partial path). These are the paired tests the
# maintainer asked for: complete file-primary, malformed/truncated file, stale/mismatched run_id, absent-file empty
# stdout, and the unchanged normal stdout-primary host.
Describe 'file-primary reviewer result (codex empty-stdout, file-delivered review)' {
    BeforeAll {
        $script:RepoRoot = (Resolve-Path "$PSScriptRoot/../../..").Path
        $env:SPECREW_MODULE_PATH = $script:RepoRoot
        . (Join-Path $script:RepoRoot 'scripts/internal/continuous-co-review/_load.ps1')
        . (Join-Path $script:RepoRoot 'scripts/internal/continuous-co-review/worktree-reviewer.ps1')
        $script:SchemaRoot = Join-Path $script:RepoRoot 'specs/197-continuous-co-review/contracts'

        function script:New-FpWorktree {
            $wt = Join-Path ([System.IO.Path]::GetTempPath()) ('fp-' + [guid]::NewGuid().ToString('N'))
            New-Item -ItemType Directory -Path (Join-Path $wt '.review') -Force | Out-Null
            return $wt
        }
        function script:New-ValidFindingLine {
            param([string]$RunId, [string]$FindingId = 'f1', [string]$Comment = 'a specific, actionable review comment')
            ([pscustomobject][ordered]@{
                    finding_id       = $FindingId
                    source_run_id    = $RunId
                    location         = [ordered]@{ path = 'scripts/x.ps1'; line_start = 1; line_end = 2 }
                    severity         = 'advisory'
                    kind             = 'test-finding'
                    design_reference = 'FR-010'
                    comment          = $Comment
                    disposition      = 'open'
                    resolution       = [ordered]@{ state = 'unresolved'; fix_evidence_ref = $null; rationale = $null }
                }) | ConvertTo-Json -Depth 10 -Compress
        }
    }

    Context 'Get-ContinuousCoReviewFilePrimaryResult - strict, fail-closed acceptance' {
        It 'ACCEPTS a complete, current-run, schema-valid findings.jsonl (happy path -> full result)' {
            $wt = New-FpWorktree
            try {
                Set-Content -LiteralPath (Join-Path $wt '.review/findings.jsonl') -Value (New-ValidFindingLine -RunId 'RUN-1') -Encoding utf8
                $res = Get-ContinuousCoReviewFilePrimaryResult -WorktreePath $wt -RunId 'RUN-1' -RunStartUtc ([datetime]::UtcNow.AddMinutes(-1)) -ExistedBefore:$false -SchemaRoot $script:SchemaRoot
                $res | Should -Not -BeNullOrEmpty
                $obj = $res | ConvertFrom-Json
                $obj.status | Should -Be 'findings'
                $obj.run_id | Should -Be 'RUN-1'
                @($obj.findings).Count | Should -Be 1
                $obj.findings[0].source_run_id | Should -Be 'RUN-1'
            }
            finally { Remove-Item -LiteralPath $wt -Recurse -Force -ErrorAction SilentlyContinue }
        }

        It 'REJECTS (fail-closed) a findings.jsonl with a malformed / truncated line - no partial accept' {
            $wt = New-FpWorktree
            try {
                Set-Content -LiteralPath (Join-Path $wt '.review/findings.jsonl') -Value @(
                    (New-ValidFindingLine -RunId 'RUN-1' -FindingId 'f1'),
                    '{"finding_id":"f2","source_run_id":"RUN-1","location":{'   # truncated / malformed tail
                ) -Encoding utf8
                Get-ContinuousCoReviewFilePrimaryResult -WorktreePath $wt -RunId 'RUN-1' -RunStartUtc ([datetime]::UtcNow.AddMinutes(-1)) -ExistedBefore:$false -SchemaRoot $script:SchemaRoot | Should -BeNullOrEmpty
            }
            finally { Remove-Item -LiteralPath $wt -Recurse -Force -ErrorAction SilentlyContinue }
        }

        It 'REJECTS (fail-closed) findings whose source_run_id belongs to a DIFFERENT run (stale / mixed run)' {
            $wt = New-FpWorktree
            try {
                Set-Content -LiteralPath (Join-Path $wt '.review/findings.jsonl') -Value (New-ValidFindingLine -RunId 'OTHER-RUN') -Encoding utf8
                Get-ContinuousCoReviewFilePrimaryResult -WorktreePath $wt -RunId 'RUN-1' -RunStartUtc ([datetime]::UtcNow.AddMinutes(-1)) -ExistedBefore:$false -SchemaRoot $script:SchemaRoot | Should -BeNullOrEmpty
            }
            finally { Remove-Item -LiteralPath $wt -Recurse -Force -ErrorAction SilentlyContinue }
        }

        It 'REJECTS (fail-closed) a PRE-EXISTING findings.jsonl not written during THIS run (stale mtime)' {
            $wt = New-FpWorktree
            try {
                Set-Content -LiteralPath (Join-Path $wt '.review/findings.jsonl') -Value (New-ValidFindingLine -RunId 'RUN-1') -Encoding utf8
                # RunStartUtc in the FUTURE + ExistedBefore=$true -> the file was NOT created/written during this run
                Get-ContinuousCoReviewFilePrimaryResult -WorktreePath $wt -RunId 'RUN-1' -RunStartUtc ([datetime]::UtcNow.AddMinutes(5)) -ExistedBefore:$true -SchemaRoot $script:SchemaRoot | Should -BeNullOrEmpty
            }
            finally { Remove-Item -LiteralPath $wt -Recurse -Force -ErrorAction SilentlyContinue }
        }

        It 'returns NULL for an ABSENT findings.jsonl - file-only delivery can never become no_findings' {
            $wt = New-FpWorktree
            try {
                Get-ContinuousCoReviewFilePrimaryResult -WorktreePath $wt -RunId 'RUN-1' -RunStartUtc ([datetime]::UtcNow.AddMinutes(-1)) -ExistedBefore:$false -SchemaRoot $script:SchemaRoot | Should -BeNullOrEmpty
            }
            finally { Remove-Item -LiteralPath $wt -Recurse -Force -ErrorAction SilentlyContinue }
        }

        It 'returns NULL for an EMPTY findings.jsonl (a zero-finding review cannot be proven via file-only delivery)' {
            $wt = New-FpWorktree
            try {
                Set-Content -LiteralPath (Join-Path $wt '.review/findings.jsonl') -Value '' -Encoding utf8
                Get-ContinuousCoReviewFilePrimaryResult -WorktreePath $wt -RunId 'RUN-1' -RunStartUtc ([datetime]::UtcNow.AddMinutes(-1)) -ExistedBefore:$false -SchemaRoot $script:SchemaRoot | Should -BeNullOrEmpty
            }
            finally { Remove-Item -LiteralPath $wt -Recurse -Force -ErrorAction SilentlyContinue }
        }

        It 'REJECTS (fail-closed) a line that PARSES but VIOLATES the FindingsResult contract (bad severity enum)' {
            $wt = New-FpWorktree
            try {
                # severity 'CRITICAL' is not in the schema enum {blocking, advisory, nit}
                $bad = '{"finding_id":"f1","source_run_id":"RUN-1","location":{"path":"x"},"severity":"CRITICAL","kind":"k","design_reference":"d","comment":"c","disposition":"open","resolution":{"state":"unresolved","fix_evidence_ref":null,"rationale":null}}'
                Set-Content -LiteralPath (Join-Path $wt '.review/findings.jsonl') -Value $bad -Encoding utf8
                Get-ContinuousCoReviewFilePrimaryResult -WorktreePath $wt -RunId 'RUN-1' -RunStartUtc ([datetime]::UtcNow.AddMinutes(-1)) -ExistedBefore:$false -SchemaRoot $script:SchemaRoot | Should -BeNullOrEmpty
            }
            finally { Remove-Item -LiteralPath $wt -Recurse -Force -ErrorAction SilentlyContinue }
        }
    }

    Context 'Invoke-ContinuousCoReviewWorktreeReviewer - retry gating + tagging (integration)' {
        It 'does NOT retry and TAGS file-primary when the reviewer delivers a valid findings.jsonl with empty stdout (codex)' {
            $script:FP_WT = New-FpWorktree
            $script:FP_RUNID = 'WRAP-RUN-1'
            try {
                Mock -CommandName Invoke-ContinuousCoReviewAgentInWorktree -MockWith {
                    Set-Content -LiteralPath (Join-Path $WorktreePath '.review/findings.jsonl') -Value (New-ValidFindingLine -RunId $script:FP_RUNID) -Encoding utf8
                    [pscustomobject]@{ exit_code = 0; stdout = ''; stderr = ''; telemetry = [pscustomobject]@{ elapsed_seconds = 1.0 } }
                }
                $r = Invoke-ContinuousCoReviewWorktreeReviewer -WorktreePath $script:FP_WT -RunId $script:FP_RUNID -HostName 'codex' -TimeoutSeconds 30
                Should -Invoke -CommandName Invoke-ContinuousCoReviewAgentInWorktree -Times 1 -Exactly
                $r.PSObject.Properties['file_primary_result'] | Should -Not -BeNullOrEmpty
                $r.telemetry.result_source | Should -Be 'file-primary'
                $r.telemetry.PSObject.Properties['empty_result_retry'] | Should -BeNullOrEmpty
            }
            finally { Remove-Item -LiteralPath $script:FP_WT -Recurse -Force -ErrorAction SilentlyContinue }
        }

        It 'RETRIES once (T108) when the result is genuinely empty (no valid file delivered)' {
            $script:FP_WT = New-FpWorktree
            $script:FP_RUNID = 'WRAP-RUN-2'
            try {
                Mock -CommandName Invoke-ContinuousCoReviewAgentInWorktree -MockWith {
                    [pscustomobject]@{ exit_code = 0; stdout = ''; stderr = ''; telemetry = [pscustomobject]@{ elapsed_seconds = 1.0 } }   # NO file written
                }
                $r = Invoke-ContinuousCoReviewWorktreeReviewer -WorktreePath $script:FP_WT -RunId $script:FP_RUNID -HostName 'codex' -TimeoutSeconds 30
                Should -Invoke -CommandName Invoke-ContinuousCoReviewAgentInWorktree -Times 2 -Exactly
                $r.PSObject.Properties['file_primary_result'] | Should -BeNullOrEmpty
                $r.telemetry.empty_result_retry.retried | Should -Be $true
            }
            finally { Remove-Item -LiteralPath $script:FP_WT -Recurse -Force -ErrorAction SilentlyContinue }
        }

        It 'leaves a NORMAL stdout-primary host unchanged (non-empty stdout: no retry, no file-primary tag)' {
            $script:FP_WT = New-FpWorktree
            $script:FP_RUNID = 'WRAP-RUN-3'
            try {
                Mock -CommandName Invoke-ContinuousCoReviewAgentInWorktree -MockWith {
                    # claude-style: authoritative FindingsResult on stdout (it may ALSO write the incremental file)
                    Set-Content -LiteralPath (Join-Path $WorktreePath '.review/findings.jsonl') -Value (New-ValidFindingLine -RunId $script:FP_RUNID) -Encoding utf8
                    [pscustomobject]@{ exit_code = 0; stdout = '{"schema_version":"1.0","run_id":"x","status":"findings","findings":[],"created_at":"2026-07-12T00:00:00Z"}'; stderr = ''; telemetry = [pscustomobject]@{ elapsed_seconds = 1.0 } }
                }
                $r = Invoke-ContinuousCoReviewWorktreeReviewer -WorktreePath $script:FP_WT -RunId $script:FP_RUNID -HostName 'claude' -TimeoutSeconds 30
                Should -Invoke -CommandName Invoke-ContinuousCoReviewAgentInWorktree -Times 1 -Exactly
                # non-empty stdout => stdout-primary path (orchestrator parses stdout); NEVER tagged file-primary
                $r.PSObject.Properties['file_primary_result'] | Should -BeNullOrEmpty
            }
            finally { Remove-Item -LiteralPath $script:FP_WT -Recurse -Force -ErrorAction SilentlyContinue }
        }
    }
}
