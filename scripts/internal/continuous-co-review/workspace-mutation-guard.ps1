$ErrorActionPreference = 'Stop'
Set-StrictMode -Version Latest

function Get-ContinuousCoReviewMutationRelativePath {
    param(
        [Parameter(Mandatory)]
        [string] $Root,

        [Parameter(Mandatory)]
        [string] $Path
    )

    $rootFull = [System.IO.Path]::GetFullPath($Root).TrimEnd([System.IO.Path]::DirectorySeparatorChar, [System.IO.Path]::AltDirectorySeparatorChar)
    $pathFull = [System.IO.Path]::GetFullPath($Path)
    if ($pathFull.StartsWith($rootFull, [System.StringComparison]::OrdinalIgnoreCase)) {
        $relative = $pathFull.Substring($rootFull.Length).TrimStart([System.IO.Path]::DirectorySeparatorChar, [System.IO.Path]::AltDirectorySeparatorChar)
        return $relative.Replace('\', '/')
    }

    return $pathFull.Replace('\', '/')
}

function Test-ContinuousCoReviewMutationPathExcluded {
    param(
        [Parameter(Mandatory)]
        [string] $CandidatePath,

        [string[]] $ExcludeRoots = @()
    )

    $candidateFull = [System.IO.Path]::GetFullPath($CandidatePath).TrimEnd([System.IO.Path]::DirectorySeparatorChar, [System.IO.Path]::AltDirectorySeparatorChar)
    foreach ($excludeRoot in @($ExcludeRoots)) {
        if ([string]::IsNullOrWhiteSpace($excludeRoot)) { continue }
        if (-not (Test-Path -LiteralPath $excludeRoot)) { continue }
        $excludeFull = [System.IO.Path]::GetFullPath((Resolve-Path -LiteralPath $excludeRoot).Path).TrimEnd([System.IO.Path]::DirectorySeparatorChar, [System.IO.Path]::AltDirectorySeparatorChar)
        if ($candidateFull.Equals($excludeFull, [System.StringComparison]::OrdinalIgnoreCase) -or $candidateFull.StartsWith($excludeFull + [System.IO.Path]::DirectorySeparatorChar, [System.StringComparison]::OrdinalIgnoreCase) -or $candidateFull.StartsWith($excludeFull + [System.IO.Path]::AltDirectorySeparatorChar, [System.StringComparison]::OrdinalIgnoreCase)) {
            return $true
        }
    }

    return $false
}

function Get-ContinuousCoReviewMutationFileInventory {
    param(
        [Parameter(Mandatory)]
        [string] $RepoRoot,

        [string[]] $Roots = @(),

        [string[]] $ExcludeRoots = @()
    )

    $inventory = [ordered]@{}
    foreach ($root in @($Roots)) {
        if ([string]::IsNullOrWhiteSpace($root)) { continue }
        $rootPath = if ([System.IO.Path]::IsPathRooted($root)) { $root } else { Join-Path $RepoRoot $root }
        if (-not (Test-Path -LiteralPath $rootPath)) { continue }
        if (Test-ContinuousCoReviewMutationPathExcluded -CandidatePath $rootPath -ExcludeRoots $ExcludeRoots) { continue }
        $files = @()
        if (Test-Path -LiteralPath $rootPath -PathType Leaf) {
            $files = @(Get-Item -LiteralPath $rootPath)
        }
        else {
            $files = @(Get-ChildItem -LiteralPath $rootPath -File -Recurse -Force | Where-Object {
                $fullName = $_.FullName
                -not (Test-ContinuousCoReviewMutationPathExcluded -CandidatePath $fullName -ExcludeRoots $ExcludeRoots)
            })
        }

        foreach ($file in $files) {
            $relative = Get-ContinuousCoReviewMutationRelativePath -Root $RepoRoot -Path $file.FullName
            $hash = (Get-FileHash -LiteralPath $file.FullName -Algorithm SHA256).Hash.ToLowerInvariant()
            $inventory[$relative] = $hash
        }
    }

    return [pscustomobject]$inventory
}

function Invoke-ContinuousCoReviewMutationGitStatus {
    param(
        [Parameter(Mandatory)]
        [string] $RepoRoot,

        [scriptblock] $GitCommand
    )

    try {
        if ($GitCommand) {
            return @(& $GitCommand @('status', '--short'))
        }
        $gitDir = & git -C $RepoRoot rev-parse --git-dir 2>$null
        if ($LASTEXITCODE -ne 0 -or [string]::IsNullOrWhiteSpace([string] $gitDir)) {
            return @()
        }
        return @(& git -C $RepoRoot --no-pager status --short)
    }
    catch {
        return @("git-status-unavailable:$($_.Exception.GetType().Name)")
    }
}

function New-ContinuousCoReviewWorkspaceMutationSnapshot {
    param(
        [Parameter(Mandatory)]
        [string] $RepoRoot,

        [string[]] $SourceRoots = @('scripts/internal/continuous-co-review', 'tests/continuous-co-review'),

        [string[]] $SpecrewStateRoots = @('specs/197-continuous-co-review', '.specrew'),

        [string[]] $ExcludeRoots = @(),

        [scriptblock] $GitCommand,

        [datetime] $CreatedAt = [datetime]::UtcNow
    )

    $resolvedRepoRoot = (Resolve-Path -LiteralPath $RepoRoot).Path
    $resolvedExcludes = @(
        foreach ($excludeRoot in @($ExcludeRoots)) {
            if ([string]::IsNullOrWhiteSpace($excludeRoot)) { continue }
            $candidate = if ([System.IO.Path]::IsPathRooted($excludeRoot)) { $excludeRoot } else { Join-Path $resolvedRepoRoot $excludeRoot }
            if (Test-Path -LiteralPath $candidate) { (Resolve-Path -LiteralPath $candidate).Path }
        }
    )

    return [pscustomobject][ordered]@{
        schema_version      = '1.0'
        repo_root           = $resolvedRepoRoot
        source_roots        = @($SourceRoots)
        specrew_state_roots = @($SpecrewStateRoots)
        exclude_roots       = @($resolvedExcludes)
        source_files        = Get-ContinuousCoReviewMutationFileInventory -RepoRoot $resolvedRepoRoot -Roots $SourceRoots -ExcludeRoots $resolvedExcludes
        specrew_state_files = Get-ContinuousCoReviewMutationFileInventory -RepoRoot $resolvedRepoRoot -Roots $SpecrewStateRoots -ExcludeRoots $resolvedExcludes
        git_status          = @(Invoke-ContinuousCoReviewMutationGitStatus -RepoRoot $resolvedRepoRoot -GitCommand $GitCommand)
        captured_at         = $CreatedAt.ToUniversalTime().ToString('yyyy-MM-ddTHH:mm:ssZ', [System.Globalization.CultureInfo]::InvariantCulture)
    }
}

function Compare-ContinuousCoReviewMutationInventory {
    param(
        [Parameter(Mandatory)]
        $Before,

        [Parameter(Mandatory)]
        $After,

        [Parameter(Mandatory)]
        [string] $Scope
    )

    $changes = New-Object System.Collections.ArrayList
    $beforeNames = @($Before.PSObject.Properties.Name)
    $afterNames = @($After.PSObject.Properties.Name)
    foreach ($name in @($beforeNames + $afterNames | Sort-Object -Unique)) {
        $beforeValue = if ($beforeNames -contains $name) { [string] $Before.PSObject.Properties[$name].Value } else { $null }
        $afterValue = if ($afterNames -contains $name) { [string] $After.PSObject.Properties[$name].Value } else { $null }
        if ($beforeValue -ne $afterValue) {
            $kind = if ($null -eq $beforeValue) { 'added' } elseif ($null -eq $afterValue) { 'removed' } else { 'modified' }
            [void] $changes.Add([pscustomobject][ordered]@{ scope = $Scope; path = $name; change = $kind })
        }
    }

    return @($changes)
}

function Compare-ContinuousCoReviewWorkspaceMutationSnapshot {
    param(
        [Parameter(Mandatory)]
        $Before,

        [Parameter(Mandatory)]
        $After
    )

    $sourceChanges = @(Compare-ContinuousCoReviewMutationInventory -Before $Before.source_files -After $After.source_files -Scope 'source')
    $specrewChanges = @(Compare-ContinuousCoReviewMutationInventory -Before $Before.specrew_state_files -After $After.specrew_state_files -Scope 'specrew-state')
    $beforeGit = @($Before.git_status) -join "`n"
    $afterGit = @($After.git_status) -join "`n"
    $gitChanged = ($beforeGit -ne $afterGit)
    $changes = @($sourceChanges + $specrewChanges)
    if ($gitChanged) {
        $changes += [pscustomobject][ordered]@{ scope = 'git'; path = 'status --short'; change = 'changed' }
    }

    return [pscustomobject][ordered]@{
        schema_version         = '1.0'
        mutated               = (@($changes).Count -gt 0)
        source_mutated        = (@($sourceChanges).Count -gt 0)
        specrew_state_mutated = (@($specrewChanges).Count -gt 0)
        git_mutated           = $gitChanged
        changes               = @($changes)
        before_captured_at    = $Before.captured_at
        after_captured_at     = $After.captured_at
    }
}
