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
    # Secret + ambient patterns excluded from BOTH the reviewer bundle and the digest
    # (SEC-002 + the maintainer "leave .env out" decision). `/**` = directory subtree;
    # bare globs match the path and its basename.
    return @(
        '.env', '.env.*', '*.key', '*.pem', '*.pfx', '*.p12', '*secret*', '*credential*',
        '*.token', 'id_rsa*', 'id_ed25519*', '.netrc', '.npmrc', '.pypirc',
        'node_modules/**', 'dist/**', 'build/**', 'out/**', 'target/**', 'bin/**', 'obj/**',
        '.venv/**', 'venv/**', '__pycache__/**', '.tox/**', '.gradle/**', '.next/**',
        '.git/**', '.specrew/**', '.squad/**', '.specify/**', '.scratch/**'
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

function Get-ContinuousCoReviewReviewedStateDigest {
    param(
        [Parameter(Mandatory)]
        [string] $RepoRoot,

        [string[]] $ExcludedPathPatterns = @()
    )

    $resolvedRepoRoot = (Resolve-Path -LiteralPath $RepoRoot).Path
    $denylist = @(Get-ContinuousCoReviewSecretAmbientDenylist) + @($ExcludedPathPatterns)
    $tempIndex = Join-Path ([System.IO.Path]::GetTempPath()) ('ccr-idx-' + [System.Guid]::NewGuid().ToString('N'))

    $hadPreviousIndex = Test-Path env:GIT_INDEX_FILE
    $previousIndex = if ($hadPreviousIndex) { $env:GIT_INDEX_FILE } else { $null }

    Push-Location -LiteralPath $resolvedRepoRoot
    try {
        # A fresh (non-existent) GIT_INDEX_FILE is an EMPTY index, so `git add -A` stages
        # the full current working tree (every non-ignored file as an addition) WITHOUT
        # reading or writing the real .git/index. No HEAD dependency (works pre-commit).
        $env:GIT_INDEX_FILE = $tempIndex

        & git add -A 2>$null | Out-Null
        if ($LASTEXITCODE -ne 0) {
            return New-ContinuousCoReviewDigestResult -Ok $false -FailureReason 'git-add-all-failed'
        }

        $included = 0
        $rawIgnored = & git ls-files -z --others --ignored --exclude-standard --directory 2>$null
        if ($LASTEXITCODE -ne 0) {
            return New-ContinuousCoReviewDigestResult -Ok $false -FailureReason 'git-ls-ignored-failed'
        }
        foreach ($entry in (ConvertFrom-ContinuousCoReviewNulList -Raw $rawIgnored)) {
            if (Test-ContinuousCoReviewDigestPathDenied -Path $entry -Denylist $denylist) {
                continue
            }

            & git add -f -- $entry 2>$null | Out-Null
            if ($LASTEXITCODE -eq 0) {
                $included++
            }
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
