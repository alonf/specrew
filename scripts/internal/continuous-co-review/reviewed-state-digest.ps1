$ErrorActionPreference = 'Stop'
Set-StrictMode -Version Latest

# T065 / FR-025 / SEC-002: content-addressed reviewed-state identity.
#
# A co-review run records a digest of the EXACT worktree content it reviewed, computed via
# a TEMPORARY git index (GIT_INDEX_FILE) so the real index/HEAD are never touched. The
# digest is a git tree-id over: tracked + untracked-non-ignored content (git add -A) PLUS
# gitignored SOURCE (git add -f), minus a secret/ambient denylist. The gate's freshness
# check is "current worktree tree-id == a passing run's recorded tree-id". This structurally
# closes HOLE A (gitignored source is IN the tree-id and its drift flips it), the untracked
# blind spot, the empty-diff trust (the empty tree has the well-known id below), and the
# diff path-parsing nits. Validated empirically 2026-06-20.

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
        # T017 INTERIM (2026-07-12, co-review f1 digest-false-allow): the SIX known review-closeout scaffolder
        # STAGING byproducts, PATH-AND-NAME specific under specs/*/iterations/*/. A GLOBAL `*.pending` rule was
        # WRONG - it would drop a genuine ignored SOURCE file (e.g. src/schema.pending) from the digest identity,
        # the exact FALSE-ALLOW that force-adding ignored source exists to prevent. These path+name patterns match
        # ONLY the closeout generator's own artifacts, so any OTHER ignored `.pending` (a real source file, or an
        # unlisted custom.md.pending under an iteration) stays IN the identity and its drift still flips the digest.
        # Consolidation into ONE digest/worktree machinery data file is the planned T017 task (NOT pulled ahead of
        # T016); this is the narrow interim fixture.
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
    # not the gate identity. (Gitignored ambient/secret junk is kept out of the tree by the
    # broader inclusion denylist below, applied only to the `git add -f` step.)
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
    foreach ($pattern in @($Denylist)) {
        if ([string]::IsNullOrWhiteSpace($pattern)) {
            continue
        }

        $normalizedPattern = ($pattern -replace '\\', '/')
        if ($normalizedPattern.EndsWith('/**')) {
            $prefix = $normalizedPattern.Substring(0, $normalizedPattern.Length - 3)
            if (($normalized -eq $prefix) -or $normalized.StartsWith("$prefix/", [System.StringComparison]::OrdinalIgnoreCase)) {
                return $true
            }
            continue
        }

        $wildcard = [System.Management.Automation.WildcardPattern]::new($normalizedPattern, [System.Management.Automation.WildcardOptions]::IgnoreCase)
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

        [int] $IncludedIgnoredCount = 0
    )

    return [pscustomobject][ordered]@{
        schema_version         = '1.0'
        ok                     = $Ok
        tree_id                = $TreeId
        is_empty               = ($Ok -and $TreeId -eq (Get-ContinuousCoReviewEmptyTreeId))
        included_ignored_count = $IncludedIgnoredCount
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
    # Two distinct lists: the BROAD inclusion denylist decides which GITIGNORED paths to
    # add (keeps ambient/secret junk out of the tree), while the MINIMAL strip list decides
    # what to remove from the FINAL index (only genuinely-non-source, so no tracked source is
    # ever stripped - the false-allow fix).
    $inclusionDenylist = @(Get-ContinuousCoReviewSecretAmbientDenylist) + @($ExcludedPathPatterns)
    $stripList = @(Get-ContinuousCoReviewDigestRuntimeStripList) + @($ExcludedPathPatterns)
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

        # A fresh (non-existent) GIT_INDEX_FILE is an EMPTY index, so `git add -A` stages
        # the full current working tree (every non-ignored file as an addition) WITHOUT
        # reading or writing the real .git/index. No HEAD dependency (works pre-commit).
        $env:GIT_INDEX_FILE = $tempIndex

        & git add -A 2>$null | Out-Null
        if ($LASTEXITCODE -ne 0) {
            return New-ContinuousCoReviewDigestResult -Ok $false -FailureReason 'git-add-all-failed'
        }
        if ($execBitPaths.Count -gt 0) {
            # Only restore paths still present in the working tree: update-index aborts a whole
            # chunk on the first missing path (deleted-in-worktree file), and the batch helper
            # swallows that failure — which would leave later paths in the chunk unrestored.
            $execBitPaths = @($execBitPaths | Where-Object { Test-Path -LiteralPath $_ -PathType Leaf })
            Invoke-ContinuousCoReviewGitPathBatch -GitArgs @('update-index', '--chmod=+x') -Paths $execBitPaths
        }

        $rawIgnored = & git ls-files -z --others --ignored --exclude-standard --directory 2>$null
        if ($LASTEXITCODE -ne 0) {
            return New-ContinuousCoReviewDigestResult -Ok $false -FailureReason 'git-ls-ignored-failed'
        }
        # Collect the non-denied gitignored SOURCE, then force-add it in BATCHED git calls (NOT one
        # subprocess per entry - see Invoke-ContinuousCoReviewGitPathBatch).
        $toInclude = @()
        foreach ($entry in (ConvertFrom-ContinuousCoReviewNulList -Raw $rawIgnored)) {
            if (-not (Test-ContinuousCoReviewDigestPathDenied -Path $entry -Denylist $inclusionDenylist)) {
                $toInclude += $entry
            }
        }
        $included = $toInclude.Count
        Invoke-ContinuousCoReviewGitPathBatch -GitArgs @('add', '-f') -Paths $toInclude

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
            return New-ContinuousCoReviewDigestResult -Ok $false -FailureReason 'git-write-tree-failed'
        }
        $treeId = ([string] (@($treeOutput) | Select-Object -First 1)).Trim()
        if ($treeId -notmatch '^[0-9a-f]{40}$') {
            return New-ContinuousCoReviewDigestResult -Ok $false -FailureReason 'git-write-tree-malformed'
        }

        return New-ContinuousCoReviewDigestResult -Ok $true -TreeId $treeId -IncludedIgnoredCount $included
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
