$ErrorActionPreference = 'Stop'
Set-StrictMode -Version Latest

# T034b / FR-012 / FR-017: one shared design-context resolution and physical-containment
# implementation for both the historical worktree path and the production campaign path.

function Get-ContinuousCoReviewPhysicalPath {
    # THE shared physical-path canonicalizer (FR-008 + FR-010 containment). Resolves a path to its REAL
    # physical location by walking EVERY component and following each existing symlink/junction to its
    # target - intermediate DIRECTORY links included, not just the final component. Both worktree
    # containment and strict design-context validation use this helper so their semantics cannot drift.
    # FAIL-CLOSED: an existing but unresolvable component returns $null. A not-yet-existing trailing
    # component is retained lexically so an external worktree path can be checked before creation.
    param([Parameter(Mandatory)][AllowEmptyString()][string]$Path)
    if ([string]::IsNullOrWhiteSpace($Path)) { return $null }
    $full = try { [System.IO.Path]::GetFullPath($Path) } catch { return $null }
    $root = [System.IO.Path]::GetPathRoot($full)
    if ([string]::IsNullOrEmpty($root)) { return $null }
    $segs = @($full.Substring($root.Length) -split '[\\/]' | Where-Object { $_ -ne '' })
    $cur = $root.TrimEnd([char]'\', [char]'/')
    if ([string]::IsNullOrEmpty($cur)) { $cur = [string]$root }
    for ($i = 0; $i -lt $segs.Count; $i++) {
        $cur = Join-Path $cur $segs[$i]
        $item = try { Get-Item -LiteralPath $cur -Force -ErrorAction Stop } catch { $null }
        if ($null -eq $item) {
            for ($j = $i + 1; $j -lt $segs.Count; $j++) { $cur = Join-Path $cur $segs[$j] }
            break
        }
        $tgt = $null
        try { $tgt = $item.ResolveLinkTarget($true) } catch { return $null }
        if ($null -ne $tgt) { $cur = [System.IO.Path]::GetFullPath($tgt.FullName).TrimEnd([char]'\', [char]'/') }
    }
    return [System.IO.Path]::GetFullPath($cur).TrimEnd([char]'\', [char]'/')
}

function Test-ContinuousCoReviewPathUnderRoot {
    # Physical equality/descendance uses platform-appropriate case comparison: Windows is
    # case-insensitive; POSIX is case-sensitive. Unresolvable paths fail closed.
    param([Parameter(Mandatory)][AllowEmptyString()][string]$Path, [Parameter(Mandatory)][AllowEmptyString()][string]$Root)
    $pReal = Get-ContinuousCoReviewPhysicalPath -Path $Path
    $rReal = Get-ContinuousCoReviewPhysicalPath -Path $Root
    if ([string]::IsNullOrEmpty($pReal) -or [string]::IsNullOrEmpty($rReal)) { return $false }
    $cmp = if ($IsWindows) { [System.StringComparison]::OrdinalIgnoreCase } else { [System.StringComparison]::Ordinal }
    return ($pReal.Equals($rReal, $cmp) -or $pReal.StartsWith($rReal + [System.IO.Path]::DirectorySeparatorChar, $cmp))
}

function Resolve-ContinuousCoReviewWorktreeDesignContext {
    # Auto-resolve the active feature spec, latest design analysis, and formal contracts. The
    # result is repo-relative; a genuinely unresolved context returns an empty array so callers
    # can apply the explicit DESIGN_CONTEXT_EMPTY partial-evidence degrade.
    param(
        [Parameter(Mandatory)][string]$RepoRoot,
        [ValidatePattern('^[0-9]+-[a-z0-9][a-z0-9-]*$')][string]$FeatureId
    )
    $out = New-Object System.Collections.Generic.List[string]
    # A public campaign already carries an exact FeatureId. Prefer that immutable command
    # identity over ignored, mutable session files so a clean detached review worktree resolves
    # the same design context as the origin. Legacy callers omit it and retain the existing
    # feature.json -> start-context -> single-unambiguous-spec fallback chain.
    $featureIdentitySupplied = -not [string]::IsNullOrWhiteSpace($FeatureId)
    $featureDir = if ($featureIdentitySupplied) { 'specs/' + $FeatureId } else { $null }
    if ($featureIdentitySupplied -and -not (Test-Path -LiteralPath (Join-Path $RepoRoot $featureDir) -PathType Container)) { return @() }
    $fj = Join-Path $RepoRoot '.specify/feature.json'
    if ([string]::IsNullOrWhiteSpace($featureDir) -and (Test-Path -LiteralPath $fj -PathType Leaf)) {
        try { $featureDir = ([string]((Get-Content $fj -Raw -Encoding UTF8 | ConvertFrom-Json).feature_directory)).Replace('\', '/').TrimEnd('/') } catch { $featureDir = $null }
    }
    if ([string]::IsNullOrWhiteSpace($featureDir)) {
        try {
            $scPath = Join-Path $RepoRoot '.specrew/start-context.json'
            if (Test-Path -LiteralPath $scPath -PathType Leaf) {
                $sc = Get-Content -LiteralPath $scPath -Raw -Encoding UTF8 | ConvertFrom-Json
                if ($sc.PSObject.Properties['session_state'] -and $null -ne $sc.session_state) {
                    $ref = if ($sc.session_state.PSObject.Properties['feature_ref']) { [string]$sc.session_state.feature_ref } else { '' }
                    if (-not [string]::IsNullOrWhiteSpace($ref) -and (Test-Path -LiteralPath (Join-Path $RepoRoot (Join-Path 'specs' $ref)) -PathType Container)) {
                        $featureDir = ('specs/' + $ref)
                    }
                }
            }
        }
        catch { $null = $_ }
    }
    if ([string]::IsNullOrWhiteSpace($featureDir)) {
        try {
            $specDirs = @(Get-ChildItem -LiteralPath (Join-Path $RepoRoot 'specs') -Directory -ErrorAction Stop | Where-Object { Test-Path -LiteralPath (Join-Path $_.FullName 'spec.md') -PathType Leaf })
            if ($specDirs.Count -eq 1) { $featureDir = ('specs/' + $specDirs[0].Name) }
        }
        catch { $null = $_ }
    }
    if ([string]::IsNullOrWhiteSpace($featureDir)) { return @() }
    if (Test-Path -LiteralPath (Join-Path $RepoRoot (Join-Path $featureDir 'spec.md')) -PathType Leaf) { [void]$out.Add("$featureDir/spec.md") }
    $iterRoot = Join-Path $RepoRoot (Join-Path $featureDir 'iterations')
    if (Test-Path -LiteralPath $iterRoot -PathType Container) {
        $latest = @(Get-ChildItem -LiteralPath $iterRoot -Directory -EA SilentlyContinue |
            Where-Object { $_.Name -match '^\d+$' -and (Test-Path -LiteralPath (Join-Path $_.FullName 'design-analysis.md') -PathType Leaf) } |
            Sort-Object { [int]$_.Name } -Descending | Select-Object -First 1)
        if ($latest) {
            [void]$out.Add(([System.IO.Path]::GetRelativePath($RepoRoot, (Join-Path $latest[0].FullName 'design-analysis.md')).Replace('\', '/')))
        }
    }
    $contractsDir = Join-Path $RepoRoot (Join-Path $featureDir 'contracts')
    if (Test-Path -LiteralPath $contractsDir -PathType Container) {
        foreach ($cf in @(Get-ChildItem -LiteralPath $contractsDir -File -Recurse -ErrorAction SilentlyContinue | Where-Object { $_.Extension -match '(?i)^\.(json|ya?ml|proto|graphql|avsc|xsd)$' })) {
            [void]$out.Add(([System.IO.Path]::GetRelativePath($RepoRoot, $cf.FullName)).Replace('\', '/'))
        }
    }
    return @($out)
}

function Resolve-ContinuousCoReviewDesignContextSelection {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)][string]$RepoRoot,
        [AllowEmptyCollection()][string[]]$DesignContextFiles = @(),
        [ValidatePattern('^[0-9]+-[a-z0-9][a-z0-9-]*$')][string]$FeatureId
    )
    $explicit = ($null -ne $DesignContextFiles -and @($DesignContextFiles).Count -gt 0)
    $resolved = if ($explicit) {
        @($DesignContextFiles)
    }
    elseif ([string]::IsNullOrWhiteSpace($FeatureId)) {
        @(Resolve-ContinuousCoReviewWorktreeDesignContext -RepoRoot $RepoRoot)
    }
    else {
        @(Resolve-ContinuousCoReviewWorktreeDesignContext -RepoRoot $RepoRoot -FeatureId $FeatureId)
    }
    $resolved = @($resolved)
    $unresolved = [System.Collections.Generic.List[string]]::new()
    if ($explicit) {
        foreach ($dc in $resolved) {
            $ref = [string]$dc
            $ok = $false
            if (-not [string]::IsNullOrWhiteSpace($ref) -and -not [System.IO.Path]::IsPathRooted($ref)) {
                $full = try { [System.IO.Path]::GetFullPath((Join-Path $RepoRoot $ref)) } catch { $null }
                if ($full -and (Test-Path -LiteralPath $full -PathType Leaf) -and (Test-ContinuousCoReviewPathUnderRoot -Path $full -Root $RepoRoot)) { $ok = $true }
            }
            if (-not $ok) { [void]$unresolved.Add($ref) }
        }
    }
    if ($unresolved.Count -gt 0) {
        $reason = ('design-context-unresolved: explicit design-context ref(s) did not resolve to a file whose physical path is UNDER the repo root (no rooted paths, no ../ traversal, no symlink/junction escape - intermediate components included): {0} (fix the path(s) or omit the flag to use auto-resolution)' -f (@($unresolved) -join ', '))
        return [pscustomobject][ordered]@{
            valid = $false; explicit = $true; classification = 'unresolved'; reason = $reason
            resolved_refs = @(); unresolved_refs = @($unresolved); design_context_empty = $false
        }
    }
    return [pscustomobject][ordered]@{
        valid = $true; explicit = $explicit; classification = $(if ($resolved.Count -eq 0) { 'empty' } else { 'resolved' }); reason = $null
        resolved_refs = @($resolved); unresolved_refs = @(); design_context_empty = ($resolved.Count -eq 0)
    }
}

function Add-ContinuousCoReviewDesignContextToScope {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)][string]$ReviewScope,
        [Parameter(Mandatory)]$Selection,
        [ValidateRange(1, 16000)][int]$MaximumLength = 16000
    )
    if (-not [bool]$Selection.valid) { throw [string]$Selection.reason }
    $contextBlock = if ([bool]$Selection.design_context_empty) {
        'DESIGN_CONTEXT_EMPTY: No spec, design analysis, or formal contract resolved. Review the frozen code, report the missing context, and return partial/incomplete evidence; it cannot approve the current target.'
    }
    else {
        $refsJson = ConvertTo-Json -InputObject @($Selection.resolved_refs) -Compress
        "Design context refs in the frozen snapshot (repo-relative JSON): $refsJson"
    }
    $composed = $ReviewScope.TrimEnd() + "`n`n" + $contextBlock
    if ($composed.Length -gt $MaximumLength) { throw "review-scope-too-large:$($composed.Length):$MaximumLength" }
    return $composed
}
