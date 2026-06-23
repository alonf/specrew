$ErrorActionPreference = 'Stop'
Set-StrictMode -Version Latest

function ConvertTo-ContinuousCoReviewRelativePath {
    param(
        [Parameter(Mandatory)]
        [string] $Path
    )

    return $Path.Trim().Replace('\', '/')
}

function Test-ContinuousCoReviewPathExcluded {
    param(
        [Parameter(Mandatory)]
        [string] $Path,

        [string[]] $ExcludedPathPatterns = @()
    )

    $normalizedPath = ConvertTo-ContinuousCoReviewRelativePath -Path $Path
    foreach ($pattern in @($ExcludedPathPatterns)) {
        if ([string]::IsNullOrWhiteSpace($pattern)) {
            continue
        }

        $normalizedPattern = ConvertTo-ContinuousCoReviewRelativePath -Path $pattern
        if ($normalizedPattern.EndsWith('/**')) {
            $prefix = $normalizedPattern.Substring(0, $normalizedPattern.Length - 3)
            if (($normalizedPath -eq $prefix) -or $normalizedPath.StartsWith("$prefix/")) {
                return $true
            }
        }

        if ([System.Management.Automation.WildcardPattern]::new($normalizedPattern, [System.Management.Automation.WildcardOptions]::IgnoreCase).IsMatch($normalizedPath)) {
            return $true
        }
    }

    return $false
}

function Invoke-ContinuousCoReviewGit {
    param(
        [Parameter(Mandatory)]
        [string] $RepoRoot,

        [Parameter(Mandatory)]
        [string[]] $Arguments
    )

    # Robust git invocation IMMUNE to the ambient [Console]::OutputEncoding state. PowerShell's `& git`
    # throws "StandardOutputEncoding is only supported when standard output is redirected" in the hook
    # provider context (the dispatcher's providers set a non-console UTF-8 [Console]::OutputEncoding and
    # the provider's stdout is itself redirected). A dedicated Process with EXPLICIT redirect + UTF-8
    # output encoding dodges that entirely. Caught by the F-197 iter-005 navigator dogfood; same lesson
    # as the launcher's spawn. (Contract preserved: ExitCode + Output = lines, stdout then stderr.)
    $psi = [System.Diagnostics.ProcessStartInfo]::new()
    $psi.FileName = 'git'
    foreach ($a in $Arguments) { [void]$psi.ArgumentList.Add([string]$a) }
    $psi.WorkingDirectory = $RepoRoot
    $psi.UseShellExecute = $false
    $psi.CreateNoWindow = $true
    $psi.RedirectStandardOutput = $true
    $psi.RedirectStandardError = $true
    $psi.StandardOutputEncoding = [System.Text.UTF8Encoding]::new($false)
    $psi.StandardErrorEncoding = [System.Text.UTF8Encoding]::new($false)

    $proc = [System.Diagnostics.Process]::new()
    $proc.StartInfo = $psi
    [void]$proc.Start()
    $stdout = $proc.StandardOutput.ReadToEnd()
    $stderr = $proc.StandardError.ReadToEnd()
    $proc.WaitForExit()
    $exitCode = $proc.ExitCode
    $proc.Dispose()

    $toLines = {
        param($s)
        if ([string]::IsNullOrEmpty($s)) { return @() }
        $l = @(($s -replace "`r`n", "`n") -split "`n")
        if ($l.Count -gt 0 -and $l[-1] -eq '') { $l = @($l[0..($l.Count - 2)]) }
        return $l
    }
    $output = @(& $toLines $stdout) + @(& $toLines $stderr)

    return [pscustomobject]@{
        ExitCode = $exitCode
        Output   = @($output)
    }
}

function New-ContinuousCoReviewSkippedRun {
    param(
        [Parameter(Mandatory)]
        [string] $RunId,

        [Parameter(Mandatory)]
        [string] $CheckpointId,

        [Parameter(Mandatory)]
        [string] $BaselineRef,

        [Parameter(Mandatory)]
        [string] $DiffHash
    )

    return [pscustomobject][ordered]@{
        schema_version = '1.0'
        run_id         = $RunId
        checkpoint_id  = $CheckpointId
        baseline_ref   = $BaselineRef
        reason         = 'no-reviewable-diff'
        diff_hash      = $DiffHash
    }
}

function Get-ContinuousCoReviewSha256Hex {
    param(
        [AllowNull()]
        [string] $Text
    )

    $resolvedText = if ($null -eq $Text) { '' } else { $Text }
    $bytes = [System.Text.Encoding]::UTF8.GetBytes($resolvedText)
    $hashBytes = [System.Security.Cryptography.SHA256]::HashData($bytes)
    return ([System.BitConverter]::ToString($hashBytes) -replace '-', '').ToLowerInvariant()
}

function Get-ContinuousCoReviewCheckpointDiff {
    param(
        [Parameter(Mandatory)]
        [string] $RepoRoot,

        [Parameter(Mandatory)]
        [string] $BaselineRef,

        [Parameter(Mandatory)]
        [string] $CheckpointId,

        [string[]] $ExcludedPathPatterns = @(),

        [string] $RunId
    )

    $resolvedRepoRoot = (Resolve-Path -LiteralPath $RepoRoot).Path
    $resolvedRunId = if ([string]::IsNullOrWhiteSpace($RunId)) {
        "run-$CheckpointId"
    }
    else {
        $RunId
    }

    $baselineCheck = Invoke-ContinuousCoReviewGit -RepoRoot $resolvedRepoRoot -Arguments @('rev-parse', '--verify', "$BaselineRef^{commit}")
    if ($baselineCheck.ExitCode -ne 0) {
        return [pscustomobject][ordered]@{
            schema_version = '1.0'
            run_id         = $resolvedRunId
            checkpoint_id  = $CheckpointId
            baseline_ref   = $BaselineRef
            status         = 'infrastructure_failure'
            failure        = New-ContinuousCoReviewInfrastructureFailure `
                -RunId $resolvedRunId `
                -Category 'command-invocation-failure' `
                -Message 'Checkpoint baseline could not be resolved as a git commit.' `
                -SafeDetails ([pscustomobject]@{ baseline_ref = $BaselineRef; checkpoint_id = $CheckpointId })
        }
    }

    # T069 (NEW-5): the gate no longer keys on diff_hash (it uses the content-addressed
    # reviewed-state tree-id), so the former full `git diff` whose output was discarded (only
    # its exit code probed) is removed. The name-only call below is the exit probe AND drives
    # changed_paths; the reviewable diff further down produces diff_inline (the reviewer's
    # context) and a provenance diff_hash.
    $nameResult = Invoke-ContinuousCoReviewGit -RepoRoot $resolvedRepoRoot -Arguments @('diff', '--name-only', '--no-ext-diff', $BaselineRef, '--')
    if ($nameResult.ExitCode -ne 0) {
        return [pscustomobject][ordered]@{
            schema_version = '1.0'
            run_id         = $resolvedRunId
            checkpoint_id  = $CheckpointId
            baseline_ref   = $BaselineRef
            status         = 'infrastructure_failure'
            failure        = New-ContinuousCoReviewInfrastructureFailure `
                -RunId $resolvedRunId `
                -Category 'command-invocation-failure' `
                -Message 'Checkpoint changed paths could not be produced.' `
                -SafeDetails ([pscustomobject]@{ baseline_ref = $BaselineRef; checkpoint_id = $CheckpointId })
        }
    }

    $changedPaths = [System.Collections.Generic.List[string]]::new()
    $excludedPaths = [System.Collections.Generic.List[string]]::new()

    # Trust-boundary decision (maintainer, 2026-06-20): the reviewer is a TRUSTED component
    # (SEC-001) inside Specrew's boundary and needs the FULL diff (including secret/config
    # content) plus repo read access + inherited env to review correctly and run tests. So the
    # change-set is NOT secret-stripped; only caller-supplied --exclude-path applies. See the
    # SEC-002 trust-boundary clause in spec.md.
    foreach ($path in @($nameResult.Output)) {
        if ([string]::IsNullOrWhiteSpace([string] $path)) {
            continue
        }

        $normalizedPath = ConvertTo-ContinuousCoReviewRelativePath -Path ([string] $path)
        if (Test-ContinuousCoReviewPathExcluded -Path $normalizedPath -ExcludedPathPatterns $ExcludedPathPatterns) {
            $excludedPaths.Add($normalizedPath)
        }
        else {
            $changedPaths.Add($normalizedPath)
        }
    }

    # Reviewable (post-exclusion) diff -> diff_inline (the reviewer's context) + a provenance
    # diff_hash. (F7: keyed to exactly the reviewable change-set; no longer the gate freshness
    # key - see T069 above.)
    $diffText = if ($changedPaths.Count -gt 0) {
        # Batch the post-exclusion paths so a real repo's large change-set does not blow the OS
        # command-line limit ("filename or extension is too long"). git diff has NO --pathspec-from-file,
        # so we chunk the explicit `-- <paths>` form. A small set (the common case) is ONE batch =
        # the original single command (byte-identical output + hash); larger sets concatenate batches
        # deterministically. (Caught by the F-197 iter-005 navigator dogfood on the real repo.)
        $batches = New-Object System.Collections.Generic.List[object]
        $cur = New-Object System.Collections.Generic.List[string]
        $curLen = 0
        foreach ($p in $changedPaths) {
            if ($cur.Count -gt 0 -and ($curLen + $p.Length + 1) -gt 20000) {
                $batches.Add(@($cur.ToArray())); $cur = New-Object System.Collections.Generic.List[string]; $curLen = 0
            }
            $cur.Add([string]$p); $curLen += $p.Length + 1
        }
        if ($cur.Count -gt 0) { $batches.Add(@($cur.ToArray())) }
        $parts = foreach ($batch in $batches) {
            $r = Invoke-ContinuousCoReviewGit -RepoRoot $resolvedRepoRoot -Arguments (@('diff', '--no-ext-diff', '--src-prefix=a/', '--dst-prefix=b/', $BaselineRef, '--') + @($batch))
            ($r.Output -join "`n")
        }
        (@($parts) -join "`n")
    }
    else {
        ''
    }
    $diffHash = "sha256:$(Get-ContinuousCoReviewSha256Hex -Text $diffText)"

    $status = if ($changedPaths.Count -eq 0) { 'skipped' } else { 'reviewable' }
    $changeSet = [ordered]@{
        schema_version         = '1.0'
        run_id                 = $resolvedRunId
        checkpoint_id          = $CheckpointId
        baseline_ref           = $BaselineRef
        status                 = $status
        review_kind            = 'code-change-set'
        diff_inline            = $diffText
        diff_hash              = $diffHash
        changed_paths          = @($changedPaths)
        reviewable_path_count  = $changedPaths.Count
        excluded_paths         = @($excludedPaths)
        excluded_path_patterns = @($ExcludedPathPatterns)
    }

    if ($status -eq 'skipped') {
        $changeSet['skip_reason'] = 'no-reviewable-diff'
        $changeSet['skipped_run'] = New-ContinuousCoReviewSkippedRun -RunId $resolvedRunId -CheckpointId $CheckpointId -BaselineRef $BaselineRef -DiffHash $diffHash
    }

    return [pscustomobject] $changeSet
}
