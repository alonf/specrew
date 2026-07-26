$ErrorActionPreference = 'Stop'
Set-StrictMode -Version Latest

# T065 / FR-025 / SEC-002: content-addressed reviewed-state identity.
#
# A co-review run records a digest of the EXACT worktree content it reviewed, computed via
# a TEMPORARY git index (GIT_INDEX_FILE) so the real index/HEAD are never touched. The
# digest is a git tree-id over tracked + untracked-non-ignored content (`git add -A`),
# minus methodology/runtime machinery and explicit human scope exclusions. Gitignored
# untracked files are excluded by Git's own repository policy; tracked files remain reviewable
# even when a later ignore rule matches them. The gate's freshness
# check is "current worktree tree-id == a passing run's recorded tree-id". This structurally
# closes the non-ignored untracked blind spot, the empty-diff trust (the empty tree has the
# well-known id below), and the diff path-parsing nits without pulling build/runtime artifacts
# into the review candidate.

function Get-ContinuousCoReviewSecretAmbientDenylist {
    # The DIGEST-IDENTITY denylist: paths kept OUT of the content-addressed tree-id.
    #
    # F1 (145 adversarial review): this list must exclude ONLY genuine non-source -
    # runtime/ambient directories and true secret/credential FILES (by exact name or
    # secret-file extension). It MUST NOT substring-match source names: a `*secret*` or
    # `*credential*` glob strips legitimate source like `src/credentials.ts` or
    # `lib/secret-rotation.go` from the gate identity, so a post-pass edit to that source
    # is invisible to freshness == a false-allow on un-reviewed source (the exact FR-025
    # defect this feature exists to prevent). Those two substring globs are intentionally
    # ABSENT here. (Confidentiality - not showing a secret FILE to the reviewer - is a
    # separate, broader concern owned by the reviewer-bundle path, not the gate identity.)
    return @(
        '.env', '.env.*', '*.pem', '*.pfx', '*.p12', '*.key', '*.token',
        'id_rsa', 'id_rsa.*', 'id_ed25519', 'id_ed25519.*', '.netrc', '.npmrc', '.pypirc',
        'node_modules/**', 'dist/**', 'build/**', 'out/**', 'target/**', 'bin/**', 'obj/**',
        '.venv/**', 'venv/**', '__pycache__/**', '.tox/**', '.gradle/**', '.next/**',
        '.git/**', '.specrew/**', '.squad/**', '.specify/**', '.scratch/**',
        # T017 INTERIM (2026-07-12): the SIX known review-closeout scaffolder staging
        # byproducts, path-and-name specific under specs/*/iterations/*. This classifier
        # remains narrow for reviewer-bundle compatibility; the digest now respects
        # `.gitignore` for every untracked path and never force-adds ignored content.
        # T017 REALIZED the ONE machinery source (Get-ContinuousCoReviewMachineryPaths, consumed by BOTH the digest
        # AND the worktree strip - see the $machineryPatterns wiring below). These .pending patterns are
        # digest-specific scaffolder-BYPRODUCT hygiene (NOT host machinery), so they correctly stay here, not in the
        # shared machinery list.
        'specs/*/iterations/*/code-map.md.pending',
        'specs/*/iterations/*/coverage-evidence.md.pending',
        'specs/*/iterations/*/dashboard.md.pending',
        'specs/*/iterations/*/dependency-report.md.pending',
        'specs/*/iterations/*/review-diagrams.md.pending',
        'specs/*/iterations/*/reviewer-index.md.pending'
    )
}

function Get-ContinuousCoReviewDigestRuntimeStripList {
    # The DIGEST-IDENTITY strip list: paths removed from the FINAL index (the tree-id).
    #
    # 145 correctness review: anything excluded from the identity is a FALSE-ALLOW vector (a
    # post-pass edit to an excluded path leaves the tree-id unchanged -> the gate allows
    # un-reviewed source). So this list excludes ONLY genuinely-non-source paths by anchored
    # subtree: the tool's own runtime trees and package-manager-managed dirs. It MUST NOT
    # contain secret-FILE/extension globs (`*.key`/`*.token`/`*.pem` strip real source like
    # `src/keymap.key`) or ambiguous build-output dirs (`bin/`/`obj/`/`dist/` are committed
    # source in polyglot repos). Secret CONFIDENTIALITY is the reviewer-bundle path's concern,
    # not the gate identity. Gitignored ambient/secret junk is kept out by normal Git semantics.
    return @(
        '.git/**', '.specrew/**', '.squad/**', '.specify/**', '.scratch/**',
        'node_modules/**', '.venv/**', 'venv/**', '__pycache__/**', '.tox/**', '.gradle/**', '.next/**'
    )
}

function Get-ContinuousCoReviewEmptyTreeId {
    # The well-known git SHA-1 of the empty tree; the no-content guard for the gate (NEW-2).
    return '4b825dc642cb6eb9a060e54bf8d69288fbee4904'
}

function Test-ContinuousCoReviewDigestPathDenied {
    param(
        [Parameter(Mandatory)]
        [string] $Path,

        [string[]] $Denylist = @()
    )

    $normalized = ($Path -replace '\\', '/').TrimEnd('/')
    if ([string]::IsNullOrWhiteSpace($normalized)) {
        return $true
    }

    $leaf = $normalized.Split('/')[-1]
    # Path identity follows the FILESYSTEM/Git rule of THIS host: Windows folds case, POSIX does not.
    # Folding case on a case-sensitive host let canonical machinery such as `.github/agents` strip a
    # DISTINCT reviewable path such as `.GitHub/agents` out of the identity, so an edit to the omitted
    # source left the tree-id unchanged - precisely the false-allow this denylist exists to prevent.
    $comparison = if ([OperatingSystem]::IsWindows()) { [System.StringComparison]::OrdinalIgnoreCase } else { [System.StringComparison]::Ordinal }
    $wildcardOptions = if ([OperatingSystem]::IsWindows()) { [System.Management.Automation.WildcardOptions]::IgnoreCase } else { [System.Management.Automation.WildcardOptions]::None }
    foreach ($pattern in @($Denylist)) {
        if ([string]::IsNullOrWhiteSpace($pattern)) {
            continue
        }

        $normalizedPattern = ($pattern -replace '\\', '/')
        if ($normalizedPattern.EndsWith('/**')) {
            $prefix = $normalizedPattern.Substring(0, $normalizedPattern.Length - 3)
            if ($normalized.Equals($prefix, $comparison) -or $normalized.StartsWith("$prefix/", $comparison)) {
                return $true
            }
            continue
        }

        $wildcard = [System.Management.Automation.WildcardPattern]::new($normalizedPattern, $wildcardOptions)
        if ($wildcard.IsMatch($normalized) -or $wildcard.IsMatch($leaf)) {
            return $true
        }
    }

    return $false
}

function New-ContinuousCoReviewDigestResult {
    param(
        [Parameter(Mandatory)]
        [bool] $Ok,

        [AllowNull()]
        [string] $TreeId,

        [AllowNull()]
        [string] $FailureReason,

        [int] $IncludedIgnoredCount = 0,

        [string[]] $MachineryPaths = @(),

        [string[]] $ExcludedPathPatterns = @()
    )

    $canonicalExclusions = @($ExcludedPathPatterns | ForEach-Object {
        $normalized = ([string]$_ -replace '\\', '/').Trim()
        while ($normalized.StartsWith('./', [StringComparison]::Ordinal)) { $normalized = $normalized.Substring(2) }
        $normalized
    } | Where-Object { -not [string]::IsNullOrWhiteSpace($_) } | Sort-Object -Unique)
    $exclusionBytes = [Text.Encoding]::UTF8.GetBytes(($canonicalExclusions -join "`n"))
    $exclusionSha256 = [Convert]::ToHexString([Security.Cryptography.SHA256]::HashData($exclusionBytes)).ToLowerInvariant()
    return [pscustomobject][ordered]@{
        schema_version         = '1.0'
        ok                     = $Ok
        tree_id                = $TreeId
        is_empty               = ($Ok -and $TreeId -eq (Get-ContinuousCoReviewEmptyTreeId))
        included_ignored_count = $IncludedIgnoredCount
        machinery_paths        = @($MachineryPaths)
        excluded_path_patterns = @($canonicalExclusions)
        excluded_path_patterns_sha256 = $exclusionSha256
        failure_reason         = $FailureReason
    }
}

function ConvertFrom-ContinuousCoReviewNulList {
    param(
        [AllowNull()]
        $Raw
    )

    $text = if ($null -eq $Raw) { '' } elseif ($Raw -is [array]) { $Raw -join "`n" } else { [string] $Raw }
    return @($text -split "`0" | Where-Object { $_ -ne '' })
}

function Invoke-ContinuousCoReviewGitPathBatch {
    # Run `git <GitArgs> -- <paths>` in CHUNKS from the CURRENT location (+ the ambient GIT_INDEX_FILE).
    # Replaces an O(files) subprocess-PER-PATH fan-out: the reviewed-state digest staged/stripped one
    # path per git call, which was ~24s on a real .specify-deployed tree (172 files) -> the navigator
    # blew the dispatcher's ~20s provider budget and NEVER fired (the iter-006 live-e2e third first-run
    # failure). Identity-preserving: the SAME paths reach the index, so git write-tree yields the SAME
    # tree-id. Chunked to stay under the OS command-line length limit.
    param(
        [Parameter(Mandatory)]
        [string[]] $GitArgs,

        [string[]] $Paths = @(),

        [int] $ChunkSize = 200
    )

    if ($null -eq $Paths -or $Paths.Count -eq 0) { return }
    for ($i = 0; $i -lt $Paths.Count; $i += $ChunkSize) {
        $end = [Math]::Min($i + $ChunkSize, $Paths.Count) - 1
        $chunk = @($Paths[$i..$end])
        & git @GitArgs -- @chunk 2>$null | Out-Null
    }
}

function Get-ContinuousCoReviewReviewedStateDigest {
    param(
        [Parameter(Mandatory)]
        [string] $RepoRoot,

        [string[]] $ExcludedPathPatterns = @()
    )

    $resolvedRepoRoot = (Resolve-Path -LiteralPath $RepoRoot).Path
    # T017 (FR-012): the METHODOLOGY MACHINERY excluded from the digest identity is the SAME single source the
    # WORKTREE strip uses - Get-ContinuousCoReviewMachineryPaths (core tool dirs + marker-detected + host-mirror
    # subdirs, context-aware). By construction the digest and worktree strip the SAME machinery, so they cannot
    # drift, and the identity covers EXACTLY the reviewable content the reviewer sees (machinery stripped from the
    # worktree is also out of the identity - NOT a false-allow: the reviewer never sees machinery, so it is not
    # reviewed source; .github/workflows and all non-machinery source stay IN both). Converted to strip patterns
    # (<path> for a file, <path>/** for a subtree). Applied to BOTH digest lists.
    # The ONE machinery source (Get-ContinuousCoReviewMachineryPaths) lives in worktree-reviewer.ps1, which _load.ps1
    # does NOT dot-source (it loads only shared leaf-modules). BOOTSTRAP it if absent (same pattern as the T100
    # process-tree helper). FAIL LOUDLY if it cannot be LOADED or EXECUTED - a silent no-strip would let the digest
    # identity DIVERGE from the worktree strip (both must derive machinery from the SAME resolver; maintainer
    # acceptance 2026-07-12). The worktree strip likewise throws if the resolver fails.
    if (-not (Get-Command -Name 'Get-ContinuousCoReviewMachineryPaths' -ErrorAction SilentlyContinue)) {
        $wrPath = Join-Path $PSScriptRoot 'worktree-reviewer.ps1'
        if (Test-Path -LiteralPath $wrPath -PathType Leaf) { try { . $wrPath } catch { $null = $_ } }
    }
    if (-not (Get-Command -Name 'Get-ContinuousCoReviewMachineryPaths' -ErrorAction SilentlyContinue)) {
        return New-ContinuousCoReviewDigestResult -Ok $false -FailureReason 'machinery-resolver-unavailable (the ONE FR-012 machinery resolver could not be loaded - refusing a digest that would diverge from the worktree strip)'
    }
    $machineryPatterns = @()
    $machineryPaths = @()
    try {
        foreach ($m in @(Get-ContinuousCoReviewMachineryPaths -RepoRoot $resolvedRepoRoot)) {
            if ([string]::IsNullOrWhiteSpace($m)) { continue }
            $normalized = ([string]$m -replace '\\', '/').Trim('/')
            if ([string]::IsNullOrWhiteSpace($normalized)) { continue }
            $machineryPaths += $normalized
            $machineryPatterns += $normalized; $machineryPatterns += ("{0}/**" -f $normalized)
        }
        $machineryPaths = @($machineryPaths | Sort-Object -Unique)
    }
    catch {
        return New-ContinuousCoReviewDigestResult -Ok $false -FailureReason ('machinery-resolver-failed: ' + [string]$_.Exception.Message)
    }
    $canonicalExclusions = @($ExcludedPathPatterns | ForEach-Object {
        $normalized = ([string]$_ -replace '\\', '/').Trim()
        while ($normalized.StartsWith('./', [StringComparison]::Ordinal)) { $normalized = $normalized.Substring(2) }
        $normalized
    } | Where-Object { -not [string]::IsNullOrWhiteSpace($_) } | Sort-Object -Unique)
    $stripList = @(Get-ContinuousCoReviewDigestRuntimeStripList) + @($machineryPatterns) + @($canonicalExclusions)
    $tempIndex = Join-Path ([System.IO.Path]::GetTempPath()) ('ccr-idx-' + [System.Guid]::NewGuid().ToString('N'))

    $hadPreviousIndex = Test-Path env:GIT_INDEX_FILE
    $previousIndex = if ($hadPreviousIndex) { $env:GIT_INDEX_FILE } else { $null }

    Push-Location -LiteralPath $resolvedRepoRoot
    try {
        # core.filemode=false hosts (the Windows default): the filesystem carries NO executable bit,
        # so git preserves modes from the PRIOR index entry — but this digest stages into a FRESH
        # EMPTY index, where no prior entry exists. `git add -A` then stages every file as 100644,
        # silently stripping the bit from tracked 100755 entrypoints (bin/*, install.sh), and the
        # reviewer's baseline->digest diff fabricates a mode regression on every shipped Unix
        # wrapper (the recurring co-review phantom / DRIFT-198-I001-001). Capture the REAL index's
        # 100755 paths BEFORE switching indexes, and restore them after staging. Applied only when
        # filemode is off: on Unix the filesystem bit is authoritative and a deliberate working-tree
        # chmod must keep flowing into the digest. (Reused verbatim from Devin ec90e1b6, T034b partial.)
        $execBitPaths = @()
        $coreFilemode = ([string](& git config --get core.filemode 2>$null)).Trim()
        if ($coreFilemode -ieq 'false') {
            $rawIndexEntries = & git ls-files -z -s 2>$null
            if ($LASTEXITCODE -eq 0) {
                foreach ($indexEntry in (ConvertFrom-ContinuousCoReviewNulList -Raw $rawIndexEntries)) {
                    if ($indexEntry -match '^100755 [0-9a-f]{40,64} \d\t(.+)$') { $execBitPaths += $Matches[1] }
                }
            }
        }

        # Seed the temporary index from the repository's real index. This preserves every
        # tracked path (including a tracked file later matched by .gitignore), staged additions,
        # and executable modes without mutating the caller's index. `git add -A` then overlays
        # the current working tree and adds only untracked NON-IGNORED files. Starting from an
        # empty temporary index would incorrectly drop tracked-but-ignored paths.
        $realIndexOutput = & git rev-parse --git-path index 2>$null
        if ($LASTEXITCODE -ne 0) {
            return New-ContinuousCoReviewDigestResult -Ok $false -FailureReason 'git-index-path-unavailable' -ExcludedPathPatterns $canonicalExclusions
        }
        $realIndexPath = ([string](@($realIndexOutput) | Select-Object -First 1)).Trim()
        if (-not [IO.Path]::IsPathRooted($realIndexPath)) {
            $realIndexPath = [IO.Path]::GetFullPath((Join-Path $resolvedRepoRoot $realIndexPath))
        }
        if ([IO.File]::Exists($realIndexPath)) {
            Copy-Item -LiteralPath $realIndexPath -Destination $tempIndex -Force
        }
        $env:GIT_INDEX_FILE = $tempIndex

        & git add -A 2>$null | Out-Null
        if ($LASTEXITCODE -ne 0) {
            return New-ContinuousCoReviewDigestResult -Ok $false -FailureReason 'git-add-all-failed' -ExcludedPathPatterns $canonicalExclusions
        }
        if ($execBitPaths.Count -gt 0) {
            # Only restore paths still present in the working tree: update-index aborts a whole
            # chunk on the first missing path (deleted-in-worktree file), and the batch helper
            # swallows that failure — which would leave later paths in the chunk unrestored.
            $execBitPaths = @($execBitPaths | Where-Object { Test-Path -LiteralPath $_ -PathType Leaf })
            Invoke-ContinuousCoReviewGitPathBatch -GitArgs @('update-index', '--chmod=+x') -Paths $execBitPaths
        }

        # Deliberately do not force-add ignored files. `.gitignore` is the repository's product
        # source boundary for untracked content; build outputs, local settings, and runtime
        # databases must never inflate or destabilize a review candidate.
        $included = 0

        # Strip only the genuinely-non-source runtime/dep paths from the final index (e.g. the
        # gate's own .specrew/review evidence, which must NEVER perturb the digest it checks).
        # This uses the MINIMAL strip list, NOT the broad denylist, so tracked SOURCE - even a
        # file named `keymap.key` or a script in `bin/` - stays in the tree-id and its drift is
        # detected (the 145 correctness false-allow fix).
        $rawStaged = & git ls-files -z 2>$null
        if ($LASTEXITCODE -eq 0) {
            # Collect the genuinely-non-source staged paths, then drop them from the index in BATCHED
            # git calls (NOT one `git rm --cached` per path - the ~24s O(files) fan-out on .specify).
            $toStrip = @()
            foreach ($staged in (ConvertFrom-ContinuousCoReviewNulList -Raw $rawStaged)) {
                if (Test-ContinuousCoReviewDigestPathDenied -Path $staged -Denylist $stripList) {
                    $toStrip += $staged
                }
            }
            Invoke-ContinuousCoReviewGitPathBatch -GitArgs @('rm', '--cached', '--quiet') -Paths $toStrip
        }

        $treeOutput = & git write-tree 2>$null
        if ($LASTEXITCODE -ne 0) {
            return New-ContinuousCoReviewDigestResult -Ok $false -FailureReason 'git-write-tree-failed' -ExcludedPathPatterns $canonicalExclusions
        }
        $treeId = ([string] (@($treeOutput) | Select-Object -First 1)).Trim()
        if ($treeId -notmatch '^[0-9a-f]{40}$') {
            return New-ContinuousCoReviewDigestResult -Ok $false -FailureReason 'git-write-tree-malformed' -ExcludedPathPatterns $canonicalExclusions
        }

        return New-ContinuousCoReviewDigestResult -Ok $true -TreeId $treeId -IncludedIgnoredCount $included -MachineryPaths $machineryPaths -ExcludedPathPatterns $canonicalExclusions
    }
    catch {
        return New-ContinuousCoReviewDigestResult -Ok $false -FailureReason 'digest-exception'
    }
    finally {
        Pop-Location
        if ($hadPreviousIndex) {
            $env:GIT_INDEX_FILE = $previousIndex
        }
        else {
            Remove-Item env:GIT_INDEX_FILE -ErrorAction SilentlyContinue
        }
        Remove-Item -LiteralPath $tempIndex -Force -ErrorAction SilentlyContinue
    }
}
