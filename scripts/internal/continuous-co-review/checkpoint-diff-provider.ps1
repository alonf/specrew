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

function Get-ContinuousCoReviewProviderConfigScalar {
    # Read a single scalar value from .specrew/config.yml (quote-strip + inline-comment-tolerant grammar,
    # mirroring Get-ContinuousCoReviewNavigatorTimeoutSeconds). Returns $null when the key is absent or the
    # config is unreadable (fail-open to the caller's default). Used for the co-review exclusion override +
    # the diff byte budget, so a project can tune both without code changes.
    param(
        [Parameter(Mandatory)] [string] $RepoRoot,
        [Parameter(Mandatory)] [string] $Key
    )
    $configPath = Join-Path $RepoRoot '.specrew/config.yml'
    if (-not (Test-Path -LiteralPath $configPath -PathType Leaf)) { return $null }
    try {
        foreach ($line in Get-Content -LiteralPath $configPath -Encoding UTF8) {
            if ($line -match ("^\s*" + [regex]::Escape($Key) + ":\s*[''""]?(?<value>[^''""#]*?)[''""]?\s*(?:#.*)?$")) {
                return ([string]$Matches['value']).Trim()
            }
        }
    }
    catch { $null = $_ }
    return $null
}

function Get-ContinuousCoReviewDefaultExcludedPathPatterns {
    # The PRINCIPLED default exclusion for the auto-fired co-review: paths that SPECREW OR A HOST DEPLOYS
    # into a governed project (scaffolding / tool config / governance tooling) rather than the project's own
    # work. Without this the navigator reviewed the WHOLE deployed tree - on a real dogfood (EnglishIntake)
    # 706 files / 5.1 MB, ~690 of it deployed scaffolding, which blew the reviewer host's input limit and
    # yielded an unparseable verdict. Patterns are PROJECT-RELATIVE (matched against the subtree-relative
    # path, so they are nesting-agnostic and behave identically for an own-repo or a nested governance root).
    #
    # CONFIG OVERRIDE (the safety valve, NOT polish - SEC/green-but-inert guard): the generic default is
    # provably wrong for two real cases - `scripts/internal/continuous-co-review/**` is PRODUCT SOURCE in the
    # Specrew repo itself (self-host co-review would go blind on exactly this code), and `.github/**` is
    # commonly USER-OWNED CI elsewhere. So a project tunes the list via .specrew/config.yml:
    #   co_review_excluded_paths_add:    "extra/**, more/**"      (added to the default)
    #   co_review_excluded_paths_remove: "scripts/internal/continuous-co-review/**, .github/**"  (dropped)
    # The `scripts/internal` pattern is NARROW (only the deployed co-review copy, the one EnglishIntake
    # actually carries) not all of scripts/internal/**, so the self-host collision is shrunk to one dir a
    # remove-override clears.
    param([Parameter(Mandatory)] [string] $RepoRoot)

    $defaults = @(
        '.specify/**', '.squad/**', '.github/**', '.claude/**', '.agents/**', '.specrew/**',
        '.cursor/**', '.copilot/**', '.vscode/**', '.antigravity/**', '.gemini/**',
        'scripts/internal/continuous-co-review/**',
        'CLAUDE.md', 'AGENTS.md', 'GEMINI.md', '.markdownlint.json'
    )

    $splitList = {
        param($raw)
        if ([string]::IsNullOrWhiteSpace([string]$raw)) { return @() }
        @(([string]$raw) -split '[,;]' | ForEach-Object { $_.Trim() } | Where-Object { -not [string]::IsNullOrWhiteSpace($_) })
    }
    $add = & $splitList (Get-ContinuousCoReviewProviderConfigScalar -RepoRoot $RepoRoot -Key 'co_review_excluded_paths_add')
    $remove = & $splitList (Get-ContinuousCoReviewProviderConfigScalar -RepoRoot $RepoRoot -Key 'co_review_excluded_paths_remove')

    $removeSet = [System.Collections.Generic.HashSet[string]]::new([System.StringComparer]::OrdinalIgnoreCase)
    foreach ($r in @($remove)) { [void]$removeSet.Add(([string]$r).Replace('\', '/').Trim()) }

    $merged = New-Object System.Collections.Generic.List[string]
    $seen = [System.Collections.Generic.HashSet[string]]::new([System.StringComparer]::OrdinalIgnoreCase)
    foreach ($p in (@($defaults) + @($add))) {
        $norm = ([string]$p).Replace('\', '/').Trim()
        if ([string]::IsNullOrWhiteSpace($norm)) { continue }
        if ($removeSet.Contains($norm)) { continue }
        if ($seen.Add($norm)) { [void]$merged.Add($norm) }
    }
    return @($merged.ToArray())
}

function Get-ContinuousCoReviewDiffByteBudget {
    # The per-review diff_inline byte budget. The reviewer host caps its piped input (claude -p: a hard
    # 10 MB stdin limit) and the composed prompt embeds the diff ~3x (raw + JSON-escaped in the request),
    # so an unbounded diff blows the limit -> the reviewer exits without a verdict. This bounds the COMMON
    # case under the host guard so reviews actually run; the adapter's prompt-size guard is the hard,
    # host-accurate bound. Default 2 MB (-> ~6 MB prompt contribution, comfortably under 10 MB); override
    # via .specrew/config.yml co_review_diff_byte_budget. <= 0 disables the cap.
    param([Parameter(Mandatory)] [string] $RepoRoot, [int] $Default = 2000000)
    $raw = Get-ContinuousCoReviewProviderConfigScalar -RepoRoot $RepoRoot -Key 'co_review_diff_byte_budget'
    if ([string]::IsNullOrWhiteSpace([string]$raw)) { return $Default }
    $parsed = 0
    if ([int]::TryParse(([string]$raw).Trim(), [ref]$parsed)) { return $parsed }
    return $Default
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

    # SUBDIR FIX (Proposal-145 review, iter-007 / subtree-scoping un-deferred): the change-set MUST be
    # computed from the git TOPLEVEL, scoped to the governance SUBTREE, with consistent repo-root-relative
    # paths. A governance root that is a SUBDIR of a larger repo (a Specrew project NESTED in a monorepo,
    # e.g. EnglishIntake under iTeach-Avatar) broke this TWO ways: (1) UNSCOPED `git diff --name-only -- `
    # returned the WHOLE monorepo's divergence (727 files), not the project's 706; (2) `git diff` run from
    # the subdir cwd emits REPO-ROOT-relative paths, but the batched `git diff -- <those paths>` ALSO run
    # from the subdir reinterpreted them as subdir-relative pathspecs -> Tools/EnglishIntake/Tools/
    # EnglishIntake/... -> ZERO matches (only a path existing at BOTH levels survived -> the reviewer saw
    # 1 of 706 files, none the actual work). Running from the TOPLEVEL + scoping to the prefix makes
    # name-only and the batched diff share one repo-root-relative frame. Own-repo projects (toplevel ==
    # governance root, empty prefix) are unaffected: $gitCwd == $resolvedRepoRoot, scope = whole repo.
    $topLevelResult = Invoke-ContinuousCoReviewGit -RepoRoot $resolvedRepoRoot -Arguments @('rev-parse', '--show-toplevel')
    $gitCwd = if ($topLevelResult.ExitCode -eq 0 -and -not [string]::IsNullOrWhiteSpace(($topLevelResult.Output -join ''))) { ([string]($topLevelResult.Output -join '')).Trim() } else { $resolvedRepoRoot }
    $prefixResult = Invoke-ContinuousCoReviewGit -RepoRoot $resolvedRepoRoot -Arguments @('rev-parse', '--show-prefix')
    $subtreePrefix = if ($prefixResult.ExitCode -eq 0) { ([string]($prefixResult.Output -join '')).Trim().TrimEnd('/') } else { '' }
    $subtreeScope = if ([string]::IsNullOrWhiteSpace($subtreePrefix)) { @() } else { @("$subtreePrefix/") }

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
    $nameResult = Invoke-ContinuousCoReviewGit -RepoRoot $gitCwd -Arguments (@('diff', '--name-only', '--no-ext-diff', $BaselineRef, '--') + $subtreeScope)
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
        # Exclusion is tested against the PROJECT-RELATIVE path (the subtree prefix stripped) so patterns
        # are nesting-agnostic - `.specrew/**` matches whether the governance root is the git root (empty
        # prefix -> no-op strip) or a subdir (e.g. Tools/EnglishIntake/.specrew/...). changed_paths /
        # excluded_paths keep the TOPLEVEL-relative path: the batched `git diff -- <paths>` below runs from
        # the toplevel and needs repo-root-relative pathspecs (the 81b7070e subtree frame).
        $projectRelativePath = $normalizedPath
        if (-not [string]::IsNullOrWhiteSpace($subtreePrefix) -and $normalizedPath.StartsWith("$subtreePrefix/")) {
            $projectRelativePath = $normalizedPath.Substring($subtreePrefix.Length + 1)
        }
        if (Test-ContinuousCoReviewPathExcluded -Path $projectRelativePath -ExcludedPathPatterns $ExcludedPathPatterns) {
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
            $r = Invoke-ContinuousCoReviewGit -RepoRoot $gitCwd -Arguments (@('diff', '--no-ext-diff', '--src-prefix=a/', '--dst-prefix=b/', $BaselineRef, '--') + @($batch))
            ($r.Output -join "`n")
        }
        (@($parts) -join "`n")
    }
    else {
        ''
    }

    # LARGE-DIFF GRACEFUL CAP (independent of the exclusion above): bound diff_inline so the composed
    # reviewer prompt cannot blow the host's input limit and SILENTLY yield no verdict (the EnglishIntake
    # dogfood: a 14.9 MB prompt made `claude -p` exit 1 with empty stdout - "piped stdin input exceeds
    # 10MB"). When over budget, truncate on a BYTE boundary at a newline (0x0A) and append an explicit
    # marker; the FULL changed-paths list stays in the change-set, so the reviewer sees every changed file
    # + the shown diff + a stated reason -> a parseable verdict with HONEST partial coverage, never a silent
    # unparseable. Byte-accurate truncation is load-bearing: the reviewed tree carries multi-byte UTF-8
    # (Hebrew), so a char-index cut at a byte budget could overshoot; cutting at a 0x0A byte also never
    # splits a multi-byte sequence. The adapter prompt-size guard is the hard host-accurate bound; this keeps
    # the common case under it so reviews still run. <=0 budget disables.
    $diffBudget = Get-ContinuousCoReviewDiffByteBudget -RepoRoot $resolvedRepoRoot
    $diffBytes = [System.Text.Encoding]::UTF8.GetBytes($diffText)
    $diffFullBytes = $diffBytes.Length
    $diffTruncated = $false
    if ($diffBudget -gt 0 -and $diffFullBytes -gt $diffBudget) {
        $cutBytes = $diffBudget
        for ($i = [Math]::Min($diffBudget, $diffFullBytes) - 1; $i -ge 0; $i--) {
            if ($diffBytes[$i] -eq 10) { $cutBytes = $i; break }
        }
        $shown = [System.Text.Encoding]::UTF8.GetString($diffBytes, 0, $cutBytes)
        $marker = "`n`n[specrew co-review: diff truncated at $cutBytes of $diffFullBytes bytes to fit the reviewer input budget ($diffBudget bytes). The FULL list of $($changedPaths.Count) changed file(s) is in change_set.changed_paths - review the shown diff plus that file list and record PARTIAL coverage in your verdict.]`n"
        $diffText = $shown + $marker
        $diffTruncated = $true
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
        diff_truncated         = $diffTruncated
        diff_full_bytes        = $diffFullBytes
        diff_budget_bytes      = $diffBudget
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
