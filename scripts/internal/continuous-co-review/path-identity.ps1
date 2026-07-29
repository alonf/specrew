$ErrorActionPreference = 'Stop'
Set-StrictMode -Version Latest

# The ONE path-identity primitive. Four independent OS-family shortcuts previously decided case
# semantics per call site, and every one of them was wrong on a case-insensitive macOS volume:
# case sensitivity is a property of the VOLUME, not the OS family. Route new comparisons through
# here rather than adding a fifth local rule.

# Ordinal on purpose. A plain `@{}` hashtable folds its string keys, which is the very defect this
# file exists to prevent (DRIFT-198-I009-024 / -030) - the primitive must not cache path answers in a
# map that cannot tell two case-distinct roots apart.
$script:ContinuousCoReviewCaseSensitivityCache = [Collections.Generic.Dictionary[string, object]]::new([StringComparer]::Ordinal)

function Get-ContinuousCoReviewCaseFlippedName {
    # The opposite-case spelling of a name, or $null when the name carries no cased letter and so
    # cannot answer the question.
    param([Parameter(Mandatory)][AllowEmptyString()][AllowNull()][string]$Name)
    if ([string]::IsNullOrEmpty($Name)) { return $null }
    if ($Name -cne $Name.ToUpperInvariant()) { return $Name.ToUpperInvariant() }
    if ($Name -cne $Name.ToLowerInvariant()) { return $Name.ToLowerInvariant() }
    return $null
}

function Get-ContinuousCoReviewOrdinalUniquePath {
    # The ONE dedup for PATH collections. `Sort-Object -Unique -CaseSensitive` is not a substitute:
    # -CaseSensitive flips only the case flag and the comparison stays CULTURE-aware, so byte-distinct
    # but culture-equivalent names - composed versus decomposed Unicode spellings, which Git and macOS
    # both produce - collapse into one entry and the dropped path is never compared again
    # (DRIFT-198-I009-033). Deduping is Ordinal, and so is the ORDERING: these lists feed digests, and
    # a culture-dependent order would make one tree hash differently on two runners.
    # AllowEmptyString is load-bearing: callers hand this raw normalized lists that can contain empty
    # entries, and a Mandatory [string[]] rejects an empty ELEMENT at the binder before the body can
    # filter it. The filtering belongs here rather than at each call site - that is the point.
    param([Parameter(Mandatory)][AllowNull()][AllowEmptyCollection()][AllowEmptyString()][string[]]$Path)

    $seen = [Collections.Generic.HashSet[string]]::new([StringComparer]::Ordinal)
    $kept = [Collections.Generic.List[string]]::new()
    foreach ($candidate in @($Path)) {
        if ([string]::IsNullOrWhiteSpace($candidate)) { continue }
        if ($seen.Add([string]$candidate)) { $kept.Add([string]$candidate) }
    }
    $kept.Sort([StringComparer]::Ordinal)
    return @($kept)
}

function Get-ContinuousCoReviewCaseVerdictFromListing {
    # Decide the volume's case rule from ONE entry whose spelling is AUTHORITATIVE because it came out
    # of a directory listing. $true = case-SENSITIVE, $false = case-INSENSITIVE, $null = this entry
    # cannot answer (its name carries no cased letter).
    #
    # Never pass a caller-supplied name here. Reading the caller's spelling back as if the filesystem
    # had confirmed it is precisely DRIFT-198-I009-032.
    param(
        [Parameter(Mandatory)][string]$Container,
        [Parameter(Mandatory)][AllowEmptyString()][string]$RealName,
        [Parameter(Mandatory)][AllowEmptyCollection()][string[]]$ListedNames
    )

    $flipped = Get-ContinuousCoReviewCaseFlippedName -Name $RealName
    if ([string]::IsNullOrEmpty($flipped)) { return $null }

    $listed = [Collections.Generic.HashSet[string]]::new([StringComparer]::Ordinal)
    foreach ($name in $ListedNames) { if (-not [string]::IsNullOrEmpty($name)) { $null = $listed.Add($name) } }

    # BOTH spellings genuinely present in the listing: two distinct entries, which a case-folding
    # volume could not hold at once. This is the case the earlier revisions read backwards.
    if ($listed.Contains($RealName) -and $listed.Contains($flipped)) { return $true }

    # Only the real spelling is listed. Ask whether a lookup of the ABSENT spelling still resolves.
    # It resolves => the volume folded case to reach the listed entry => INSENSITIVE.
    # It does not => the volume keeps the two spellings apart => SENSITIVE.
    $candidate = Join-Path $Container $flipped
    if ([IO.Directory]::Exists($candidate) -or [IO.File]::Exists($candidate)) { return $false }
    return $true
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
    #
    # THE RULE, and why the previous two revisions got it wrong (DRIFT-198-I009-026, -032):
    # every verdict must be derived from an on-disk spelling obtained by ENUMERATION. The caller's
    # spelling is not evidence. `[IO.Path]::GetFullPath` preserves whatever the caller typed and does
    # not canonicalise to the real entry, so a probe that flips the CALLER's leaf is comparing against
    # a name the filesystem may never have held - which is how a case-INSENSITIVE volume holding
    # `REPO`, asked about `repo`, was reported case-SENSITIVE. Given a real listed name and its
    # flipped spelling, two reads decide it: both spellings listed means two genuinely distinct
    # entries, which only a case-preserving volume can hold; exactly one listed, with the other still
    # RESOLVING, means the lookup folded case.
    $result = $null
    try {
        # (a) Prefer probing INSIDE the physical target. Its children's names come straight from the
        # directory listing, so no caller spelling can contaminate the answer.
        $childEntries = @([IO.Directory]::GetFileSystemEntries($probeDir))
        $childNames = @($childEntries | ForEach-Object { [IO.Path]::GetFileName($_) } | Where-Object { -not [string]::IsNullOrEmpty($_) })
        foreach ($childName in @($childNames | Select-Object -First 64)) {
            $result = Get-ContinuousCoReviewCaseVerdictFromListing -Container $probeDir -RealName $childName -ListedNames $childNames
            if ($null -ne $result) { break }
        }

        # (b) An empty target (or one whose entries carry no cased letter) still has its OWN entry in
        # the parent. Read the REAL spelling of that entry out of the parent's listing - never the
        # leaf the caller supplied - and apply the identical rule.
        if ($null -eq $result) {
            $parent = [IO.Path]::GetDirectoryName($probeDir)
            if (-not [string]::IsNullOrWhiteSpace($parent) -and [IO.Directory]::Exists($parent)) {
                $suppliedLeaf = [IO.Path]::GetFileName($probeDir.TrimEnd([IO.Path]::DirectorySeparatorChar, [IO.Path]::AltDirectorySeparatorChar))
                $parentNames = @([IO.Directory]::GetFileSystemEntries($parent) | ForEach-Object { [IO.Path]::GetFileName($_) } | Where-Object { -not [string]::IsNullOrEmpty($_) })
                $realLeaf = $null
                foreach ($name in $parentNames) { if ($name -ceq $suppliedLeaf) { $realLeaf = $name; break } }
                if ([string]::IsNullOrEmpty($realLeaf)) {
                    foreach ($name in $parentNames) {
                        if ([string]::Equals($name, $suppliedLeaf, [System.StringComparison]::OrdinalIgnoreCase)) { $realLeaf = $name; break }
                    }
                }
                if (-not [string]::IsNullOrEmpty($realLeaf)) {
                    $result = Get-ContinuousCoReviewCaseVerdictFromListing -Container $parent -RealName $realLeaf -ListedNames $parentNames
                }
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
