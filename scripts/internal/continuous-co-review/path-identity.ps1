$ErrorActionPreference = 'Stop'
Set-StrictMode -Version Latest

# The ONE path-identity primitive. Four independent OS-family shortcuts previously decided case
# semantics per call site, and every one of them was wrong on a case-insensitive macOS volume:
# case sensitivity is a property of the VOLUME, not the OS family. Route new comparisons through
# here rather than adding a fifth local rule.

$script:ContinuousCoReviewCaseSensitivityCache = @{}

function Get-ContinuousCoReviewCaseFlippedName {
    # The opposite-case spelling of a name, or $null when the name carries no cased letter and so
    # cannot answer the question.
    param([Parameter(Mandatory)][AllowEmptyString()][AllowNull()][string]$Name)
    if ([string]::IsNullOrEmpty($Name)) { return $null }
    if ($Name -cne $Name.ToUpperInvariant()) { return $Name.ToUpperInvariant() }
    if ($Name -cne $Name.ToLowerInvariant()) { return $Name.ToLowerInvariant() }
    return $null
}

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

    # Determined by ASKING THE FILESYSTEM, with no subprocess. An earlier revision consulted
    # `git config core.ignorecase` first; that call is reached from the digest's per-path loop and
    # hung the Linux CI review suite silently, with the process killed and no failing assertion.
    # A direct probe measures the volume itself rather than git's cached init-time answer, works for
    # directories outside any repository (the external target root), and cannot block. It only
    # reads, so it stays safe against an OS-protected read-only reviewer target.
    $result = $null
    try {
        # Prefer the directory's OWN name: it needs no children and cannot be perturbed by them.
        $leaf = [IO.Path]::GetFileName($probeDir.TrimEnd([IO.Path]::DirectorySeparatorChar, [IO.Path]::AltDirectorySeparatorChar))
        $parent = [IO.Path]::GetDirectoryName($probeDir)
        $flipped = Get-ContinuousCoReviewCaseFlippedName -Name $leaf
        if (-not [string]::IsNullOrEmpty($flipped) -and -not [string]::IsNullOrWhiteSpace($parent)) {
            # Existence of the flipped spelling ALONE proves nothing. A case-sensitive volume may
            # legitimately hold BOTH `Repo` and `REPO` as distinct directories, and an earlier
            # revision read that as proof of case-INSENSITIVITY - exactly backwards, and it handed
            # the wrong comparer to every downstream identity (co-review finding, run
            # run-f198-i009-aab37c3b-codex-2). Distinguish the two cases by asking what the
            # directory listing actually CONTAINS: a folded lookup resolves a name the parent does
            # not list, whereas two real siblings are both listed. Enumeration returns true on-disk
            # names, so this stays a pure read and needs no probe file.
            $flippedPath = Join-Path $parent $flipped
            if ([IO.Directory]::Exists($flippedPath)) {
                $listed = $false
                foreach ($entry in [IO.Directory]::EnumerateDirectories($parent)) {
                    if ([IO.Path]::GetFileName($entry) -ceq $flipped) { $listed = $true; break }
                }
                # Listed => two distinct directories => the volume preserves case.
                # Not listed => the lookup folded case to reach this directory.
                $result = $listed
            }
            else {
                $result = $true
            }
        }
        if ($null -eq $result) {
            # Same rule as above, applied to a child: a listed flipped name means two real entries
            # on a case-preserving volume; an unlisted one that still resolves means a folded lookup.
            $entries = @([IO.Directory]::GetFileSystemEntries($probeDir))
            $names = [Collections.Generic.HashSet[string]]::new([StringComparer]::Ordinal)
            foreach ($entry in $entries) { $null = $names.Add([IO.Path]::GetFileName($entry)) }
            foreach ($entry in @($entries | Select-Object -First 8)) {
                $childLeaf = [IO.Path]::GetFileName($entry)
                $childFlipped = Get-ContinuousCoReviewCaseFlippedName -Name $childLeaf
                if ([string]::IsNullOrEmpty($childFlipped)) { continue }
                $candidate = Join-Path $probeDir $childFlipped
                if ([IO.File]::Exists($candidate) -or [IO.Directory]::Exists($candidate)) {
                    $result = $names.Contains($childFlipped)
                }
                else { $result = $true }
                break
            }
        }
    }
    catch { $result = $null }

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
