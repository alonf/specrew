$ErrorActionPreference = 'Stop'
Set-StrictMode -Version Latest

# T111 (DEC-197-I010-004, maintainer send-back 2026-07-08): implementer TEST EVIDENCE for the reviewer.
#
# ROOT CAUSE this closes: the outbound budget policy told the reviewer to "use implementer validation
# evidence first" while the worktree carried NO such evidence, and the falsification stance (rightly)
# forbids trusting prose claims - so on a large change-set the reviewer re-ran the full test pyramid
# and died at the harness budget ceiling (four consecutive budget/quota deaths on 2026-07-08).
#
# The fix: the implementer's ACTUAL test runs are recorded here as MACHINE-OBSERVED evidence
# (suite, counts, exit code, duration, timestamp) bound to the reviewed-state DIGEST of the tree the
# tests ran against. The orchestrator injects the record into the reviewer worktree ONLY on an exact
# digest match (.review/implementer-evidence.json), and the slim prompt lets digest-matched evidence
# substitute for re-running those suites. Hand-written claims never gain evidence standing - only
# this recorder's output does, and only for the exact tree under review (a post-evidence edit changes
# the digest and orphans the record). Evidence lives under .specrew/review/ (digest-EXCLUDED runtime
# state), so recording evidence never changes the tree identity it certifies.

function Get-ContinuousCoReviewTestEvidenceDirectory {
    param([Parameter(Mandatory)][string]$RepoRoot)
    return (Join-Path $RepoRoot '.specrew/review/test-evidence')
}

function Write-ContinuousCoReviewTestEvidence {
    <#
        Records one MACHINE-OBSERVED suite run against the CURRENT working-tree digest. Call this
        right after the real test invocation, in the same session, with the numbers the runner
        reported (never hand-typed). FAIL-SOFT by contract: the recorder must never break a test
        run - any internal failure warns and returns $null.
    #>
    param(
        [Parameter(Mandatory)][string]$RepoRoot,
        [Parameter(Mandatory)][string]$Suite,
        [Parameter(Mandatory)][int]$Passed,
        [int]$Failed = 0,
        [int]$Skipped = 0,
        [Parameter(Mandatory)][int]$ExitCode,
        [double]$DurationSeconds = 0,
        [string]$Command,
        [datetime]$Now = [datetime]::UtcNow
    )
    try {
        $resolved = (Resolve-Path -LiteralPath $RepoRoot).Path
        if (-not (Get-Command -Name 'Get-ContinuousCoReviewReviewedStateDigest' -ErrorAction SilentlyContinue)) {
            $lp = Join-Path $PSScriptRoot '_load.ps1'
            if (Test-Path -LiteralPath $lp -PathType Leaf) { . $lp }
        }
        $dg = Get-ContinuousCoReviewReviewedStateDigest -RepoRoot $resolved
        if ($null -eq $dg -or -not [bool]$dg.ok) {
            $reason = if ($null -ne $dg) { [string]$dg.failure_reason } else { 'digest-unavailable' }
            [Console]::Error.WriteLine("[co-review] WARN TEST_EVIDENCE_NOT_RECORDED reviewed-state digest failed ($reason); the run stays valid but leaves no reviewer evidence.")
            return $null
        }
        $treeId = [string]$dg.tree_id

        $dir = Get-ContinuousCoReviewTestEvidenceDirectory -RepoRoot $resolved
        if (-not (Test-Path -LiteralPath $dir -PathType Container)) {
            $null = New-Item -ItemType Directory -Path $dir -Force
        }
        $path = Join-Path $dir ($treeId + '.json')

        $record = $null
        if (Test-Path -LiteralPath $path -PathType Leaf) {
            try { $record = Get-Content -LiteralPath $path -Raw | ConvertFrom-Json } catch { $record = $null }
        }
        if ($null -eq $record -or -not ($record.PSObject.Properties.Name -contains 'suites')) {
            $record = [pscustomobject]@{
                schema_version          = '1.0'
                reviewed_digest_tree_id = $treeId
                recorded_at             = $Now.ToUniversalTime().ToString('yyyy-MM-ddTHH:mm:ssZ')
                suites                  = @()
            }
        }

        $entry = [pscustomobject]@{
            suite            = $Suite
            passed           = $Passed
            failed           = $Failed
            skipped          = $Skipped
            exit_code        = $ExitCode
            duration_seconds = [math]::Round($DurationSeconds, 3)
            command          = if ([string]::IsNullOrWhiteSpace($Command)) { $null } else { $Command }
            recorded_at      = $Now.ToUniversalTime().ToString('yyyy-MM-ddTHH:mm:ssZ')
        }
        # Same-suite re-record REPLACES (the latest run for this exact tree wins); others accumulate.
        $kept = @(@($record.suites) | Where-Object { $null -ne $_ -and [string]$_.suite -ne $Suite })
        $record.suites = @($kept + $entry)
        $record.recorded_at = $entry.recorded_at

        [System.IO.File]::WriteAllText($path, ($record | ConvertTo-Json -Depth 8))
        return $record
    }
    catch {
        [Console]::Error.WriteLine("[co-review] WARN TEST_EVIDENCE_NOT_RECORDED $($_.Exception.Message)")
        return $null
    }
}

function Get-ContinuousCoReviewTestEvidenceForDigest {
    <# The digest-keyed lookup: returns the record ONLY when it certifies exactly this tree id. #>
    param(
        [Parameter(Mandatory)][string]$RepoRoot,
        [Parameter(Mandatory)][string]$DigestTreeId
    )
    $dir = Get-ContinuousCoReviewTestEvidenceDirectory -RepoRoot $RepoRoot
    $path = Join-Path $dir ($DigestTreeId + '.json')
    if (-not (Test-Path -LiteralPath $path -PathType Leaf)) { return $null }
    try {
        $record = Get-Content -LiteralPath $path -Raw | ConvertFrom-Json
        if ($null -eq $record) { return $null }
        if (-not ($record.PSObject.Properties.Name -contains 'reviewed_digest_tree_id')) { return $null }
        if ([string]$record.reviewed_digest_tree_id -ne $DigestTreeId) { return $null }
        if (-not ($record.PSObject.Properties.Name -contains 'suites') -or @($record.suites).Count -eq 0) { return $null }
        return $record
    }
    catch { return $null }
}

function Copy-ContinuousCoReviewImplementerEvidence {
    <#
        Injects digest-matched evidence into the reviewer worktree as .review/implementer-evidence.json.
        Returns $true only when a matching record was injected; a mismatch, a missing record, or any
        failure returns $false (the reviewer then simply has no evidence - never wrong evidence).
    #>
    param(
        [Parameter(Mandatory)][string]$RepoRoot,
        [Parameter(Mandatory)][string]$WorktreePath,
        [AllowEmptyString()][string]$DigestTreeId
    )
    try {
        if ([string]::IsNullOrWhiteSpace($DigestTreeId)) { return $false }
        $record = Get-ContinuousCoReviewTestEvidenceForDigest -RepoRoot $RepoRoot -DigestTreeId $DigestTreeId
        if ($null -eq $record) { return $false }
        $reviewDir = Join-Path $WorktreePath '.review'
        if (-not (Test-Path -LiteralPath $reviewDir -PathType Container)) { return $false }
        [System.IO.File]::WriteAllText((Join-Path $reviewDir 'implementer-evidence.json'), ($record | ConvertTo-Json -Depth 8))
        return $true
    }
    catch {
        [Console]::Error.WriteLine("[co-review] WARN IMPLEMENTER_EVIDENCE_NOT_INJECTED $($_.Exception.Message)")
        return $false
    }
}
