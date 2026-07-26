$ErrorActionPreference = 'Stop'
Set-StrictMode -Version Latest

# The ONE path-identity primitive. Four independent OS-family shortcuts previously decided case
# semantics per call site, and every one of them was wrong on a case-insensitive macOS volume:
# case sensitivity is a property of the VOLUME, not the OS family. Route new comparisons through
# here rather than adding a fifth local rule.

$script:ContinuousCoReviewCaseSensitivityCache = @{}

function Get-ContinuousCoReviewPathCaseSensitive {
    # $true = case-SENSITIVE volume, $false = case-INSENSITIVE, $null = undetermined.
    param([Parameter(Mandatory)][AllowEmptyString()][string]$Path)

    if ([string]::IsNullOrWhiteSpace($Path)) { return $null }
    $probeDir = $null
    try {
        $probeDir = [IO.Path]::GetFullPath($Path)
        while (-not [string]::IsNullOrWhiteSpace($probeDir) -and -not [IO.Directory]::Exists($probeDir)) {
            $parent = [IO.Path]::GetDirectoryName($probeDir)
            if ([string]::IsNullOrWhiteSpace($parent) -or $parent -ceq $probeDir) { break }
            $probeDir = $parent
        }
    }
    catch { return $null }
    if ([string]::IsNullOrWhiteSpace($probeDir) -or -not [IO.Directory]::Exists($probeDir)) { return $null }
    if ($script:ContinuousCoReviewCaseSensitivityCache.ContainsKey($probeDir)) {
        return $script:ContinuousCoReviewCaseSensitivityCache[$probeDir]
    }

    $result = $null
    # 1. Git already probed the working tree at init and recorded the answer. core.ignorecase=true
    #    means the filesystem folds case, so case-sensitive is its negation.
    try {
        $raw = & git -C $probeDir config --get core.ignorecase 2>$null
        $code = $LASTEXITCODE
        if ($code -eq 0) {
            $text = ([string](@($raw) | Select-Object -First 1)).Trim()
            if ($text -ieq 'true') { $result = $false }
            elseif ($text -ieq 'false') { $result = $true }
        }
    }
    catch { $result = $null }

    # 2. Side-effect-free fallback: flip the case of an existing entry and ask whether it still
    #    resolves. Never writes, so it is safe against an OS-protected read-only reviewer target.
    if ($null -eq $result) {
        try {
            foreach ($entry in @([IO.Directory]::GetFileSystemEntries($probeDir) | Select-Object -First 8)) {
                $leaf = [IO.Path]::GetFileName($entry)
                if ([string]::IsNullOrEmpty($leaf)) { continue }
                $flipped = if ($leaf -cne $leaf.ToUpperInvariant()) { $leaf.ToUpperInvariant() }
                elseif ($leaf -cne $leaf.ToLowerInvariant()) { $leaf.ToLowerInvariant() }
                else { $null }
                if ($null -eq $flipped) { continue }
                $candidate = Join-Path $probeDir $flipped
                $result = -not ([IO.File]::Exists($candidate) -or [IO.Directory]::Exists($candidate))
                break
            }
        }
        catch { $result = $null }
    }

    $script:ContinuousCoReviewCaseSensitivityCache[$probeDir] = $result
    return $result
}

function Get-ContinuousCoReviewPathComparison {
    # WhenUndetermined names the SAFE direction for THIS caller, because there is no single safe
    # default. A containment check that must REFUSE an aliased path needs variants treated as the
    # SAME so it rejects more; machinery stripping needs them DISTINCT so it can never remove real
    # source from the reviewed identity. Passing the wrong one is silently unsafe, so it is required.
    param(
        [Parameter(Mandatory)][AllowEmptyString()][string]$Path,
        [Parameter(Mandatory)][ValidateSet('same', 'distinct')][string]$WhenUndetermined
    )

    $sensitive = Get-ContinuousCoReviewPathCaseSensitive -Path $Path
    if ($null -eq $sensitive) {
        return $(if ($WhenUndetermined -ceq 'same') { [StringComparison]::OrdinalIgnoreCase } else { [StringComparison]::Ordinal })
    }
    return $(if ($sensitive) { [StringComparison]::Ordinal } else { [StringComparison]::OrdinalIgnoreCase })
}

function Get-ContinuousCoReviewPathComparer {
    param(
        [Parameter(Mandatory)][AllowEmptyString()][string]$Path,
        [Parameter(Mandatory)][ValidateSet('same', 'distinct')][string]$WhenUndetermined
    )

    $comparison = Get-ContinuousCoReviewPathComparison -Path $Path -WhenUndetermined $WhenUndetermined
    return $(if ($comparison -eq [StringComparison]::OrdinalIgnoreCase) { [StringComparer]::OrdinalIgnoreCase } else { [StringComparer]::Ordinal })
}

function ConvertTo-ContinuousCoReviewLiteralPathspec {
    # A literal repository identity must never reach Git as a glob: a legal directory name holding
    # pathspec metacharacters would otherwise select unrelated source.
    param([Parameter(Mandatory)][AllowEmptyString()][string]$Path)
    return ':(literal)' + (([string]$Path) -replace '\\', '/')
}
