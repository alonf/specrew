Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

function New-SpecrewGatePreflightCheck {
    param(
        [Parameter(Mandatory)][string]$Name,
        [Parameter(Mandatory)][ValidateSet('pass', 'fail', 'not-applicable')][string]$Status,
        [Parameter(Mandatory)][string]$Message,
        [AllowNull()][object]$Evidence
    )

    return [pscustomobject][ordered]@{
        name = $Name
        status = $Status
        message = $Message
        evidence = $Evidence
    }
}

function Get-SpecrewGatePreflightMarkdownValue {
    param([Parameter(Mandatory)][string]$Path, [Parameter(Mandatory)][string]$Label)
    if (-not (Test-Path -LiteralPath $Path -PathType Leaf)) { return $null }
    $pattern = '^\*\*' + [regex]::Escape($Label) + '\*\*:\s*(.+?)\s*$'
    foreach ($line in Get-Content -LiteralPath $Path -Encoding UTF8) {
        if ($line -match $pattern) { return $Matches[1].Trim() }
    }
    return $null
}

function Get-SpecrewGatePreflightStatus {
    param([Parameter(Mandatory)][string]$ProjectRoot)

    $records = New-Object System.Collections.Generic.List[object]
    $lines = @(& git -C $ProjectRoot status --porcelain=v1 --untracked-files=all 2>$null)
    if ($LASTEXITCODE -ne 0) { throw "git status failed for '$ProjectRoot'." }
    foreach ($line in $lines) {
        $text = [string]$line
        if ($text.Length -lt 4) { continue }
        $path = $text.Substring(3).Trim()
        if ($path -match ' -> (?<destination>.+)$') { $path = $Matches['destination'].Trim() }
        $normalized = $path.Replace('\', '/')
        $writer = if ($normalized -match '^(?:\.specrew|\.specify|\.squad)(?:/|$)' -or
            $normalized -match '^specs/[^/]+/iterations/[0-9]+/(?:state\.md|tasks-progress\.yml|drift-log\.md|review\.md|retro\.md|dashboard\.md|quality(?:/|$))') {
            'governance-record'
        }
        else { 'product-or-methodology' }
        $records.Add([pscustomobject][ordered]@{ status = $text.Substring(0, 2); path = $normalized; writer = $writer }) | Out-Null
    }
    return $records.ToArray()
}

function Get-SpecrewGatePreflightTaskState {
    param([Parameter(Mandatory)][string]$Path)
    $tasks = [ordered]@{}
    $current = $null
    foreach ($line in Get-Content -LiteralPath $Path -Encoding UTF8) {
        if ($line -match '^  (?<id>T\d+):\s*$') {
            $current = $Matches['id']
            $tasks[$current] = $null
            continue
        }
        if ($null -ne $current -and $line -match '^    status:\s*["'']?(?<status>[^"''#\s]+)') {
            $tasks[$current] = $Matches['status'].Trim().ToLowerInvariant()
        }
    }
    return $tasks
}

function ConvertFrom-SpecrewGatePreflightIdList {
    param([AllowNull()][string]$Value)
    if ([string]::IsNullOrWhiteSpace($Value) -or $Value -match '^\(?none\)?$') { return @() }
    return @($Value -split '\s*,\s*' | ForEach-Object { $_.Trim() } | Where-Object { $_ -match '^T\d+$' })
}

function Invoke-SpecrewGatePreflight {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)][string]$ProjectRoot,
        [Parameter(Mandatory)][ValidateSet('specify', 'clarify', 'plan', 'tasks', 'before-implement', 'review-signoff', 'retro', 'iteration-closeout', 'feature-closeout')][string]$BoundaryType,
        [AllowNull()][string]$FeatureRef,
        [AllowNull()][string]$IterationNumber,
        [switch]$FailOnError
    )

    $root = (Resolve-Path -LiteralPath $ProjectRoot).Path
    $checks = New-Object System.Collections.Generic.List[object]
    $head = [string](@(& git -C $root rev-parse --verify HEAD 2>$null) | Select-Object -First 1)
    if ($LASTEXITCODE -ne 0 -or $head -notmatch '^[0-9a-f]{40,64}$') {
        $checks.Add((New-SpecrewGatePreflightCheck -Name 'pushed-head' -Status fail -Message 'HEAD could not be resolved; boundary evidence cannot be bound to a commit.' -Evidence $null)) | Out-Null
    }

    $release = Resolve-SpecrewReleaseModel -ProjectRoot $root
    $branch = [string](@(& git -C $root branch --show-current 2>$null) | Select-Object -First 1)
    if ([string]$release.Model -eq 'local-only') {
        $checks.Add((New-SpecrewGatePreflightCheck -Name 'pushed-head' -Status not-applicable -Message 'The recorded release model is local-only; no remote push is owed.' -Evidence @{ release_model = $release.Model })) | Out-Null
    }
    elseif ([string]::IsNullOrWhiteSpace($branch)) {
        $checks.Add((New-SpecrewGatePreflightCheck -Name 'pushed-head' -Status fail -Message 'A remote-delivered boundary cannot use a detached HEAD.' -Evidence @{ release_model = $release.Model })) | Out-Null
    }
    else {
        $remote = @(& git -C $root remote get-url origin 2>$null)
        if ($LASTEXITCODE -ne 0 -or $remote.Count -eq 0) {
            $checks.Add((New-SpecrewGatePreflightCheck -Name 'pushed-head' -Status fail -Message "Release model '$($release.Model)' requires origin, but origin is not configured." -Evidence $null)) | Out-Null
        }
        else {
            $remoteLine = [string](@(& git -C $root ls-remote --heads origin ("refs/heads/{0}" -f $branch) 2>$null) | Select-Object -First 1)
            $remoteHash = if ($remoteLine -match '^(?<hash>[0-9a-f]{40,64})\s+') { $Matches['hash'] } else { '' }
            if ([string]::IsNullOrWhiteSpace($remoteHash) -or $remoteHash -cne $head) {
                $checks.Add((New-SpecrewGatePreflightCheck -Name 'pushed-head' -Status fail -Message "Branch '$branch' is not pushed to origin at the current HEAD." -Evidence @{ local_head = $head; remote_head = $remoteHash; branch = $branch })) | Out-Null
            }
            else {
                $checks.Add((New-SpecrewGatePreflightCheck -Name 'pushed-head' -Status pass -Message "origin/$branch matches the current HEAD." -Evidence @{ head = $head; branch = $branch })) | Out-Null
            }
        }
    }

    $governancePath = Join-Path $root '.specrew/repository-governance.yml'
    $trunkName = $null
    if (Test-Path -LiteralPath $governancePath -PathType Leaf) {
        foreach ($line in Get-Content -LiteralPath $governancePath -Encoding UTF8) {
            if ($line -match '^\s*release_truth_branch:\s*["'']?(?<value>[^"''#\s]+)') { $trunkName = $Matches['value']; break }
        }
    }
    $trunkCandidates = New-Object System.Collections.Generic.List[string]
    if (-not [string]::IsNullOrWhiteSpace($trunkName)) {
        $trunkCandidates.Add("origin/$trunkName") | Out-Null
        $trunkCandidates.Add($trunkName) | Out-Null
    }
    foreach ($fallback in @('origin/main', 'origin/master', 'main', 'master')) { $trunkCandidates.Add($fallback) | Out-Null }
    $trunkRef = $null
    foreach ($candidate in $trunkCandidates) {
        if ([string]::IsNullOrWhiteSpace([string]$candidate)) { continue }
        & git -C $root rev-parse --verify --quiet ([string]$candidate) 2>$null | Out-Null
        if ($LASTEXITCODE -eq 0) { $trunkRef = [string]$candidate; break }
    }
    if ($null -eq $trunkRef) {
        $checks.Add((New-SpecrewGatePreflightCheck -Name 'ahead-count' -Status not-applicable -Message 'No trunk ref is present yet; ahead count is not applicable to this greenfield history.' -Evidence $null)) | Out-Null
    }
    else {
        $aheadRaw = [string](@(& git -C $root rev-list --count ("{0}..HEAD" -f $trunkRef) 2>$null) | Select-Object -First 1)
        if ($LASTEXITCODE -ne 0 -or $aheadRaw -notmatch '^\d+$') {
            $checks.Add((New-SpecrewGatePreflightCheck -Name 'ahead-count' -Status fail -Message "Ahead count could not be computed from '$trunkRef'." -Evidence $null)) | Out-Null
        }
        else {
            $checks.Add((New-SpecrewGatePreflightCheck -Name 'ahead-count' -Status pass -Message "HEAD is $aheadRaw commit(s) ahead of $trunkRef." -Evidence @{ ahead_count = [int]$aheadRaw; trunk_ref = $trunkRef })) | Out-Null
        }
    }

    $statusRecords = @(Get-SpecrewGatePreflightStatus -ProjectRoot $root)
    $nonRecordStatus = @($statusRecords | Where-Object { $_.writer -ne 'governance-record' })
    if ($nonRecordStatus.Count -gt 0) {
        $checks.Add((New-SpecrewGatePreflightCheck -Name 'working-tree' -Status fail -Message ("The boundary tree has {0} uncommitted product/methodology path(s); commit or dispose them before rendering a packet." -f $nonRecordStatus.Count) -Evidence $statusRecords)) | Out-Null
    }
    elseif ($statusRecords.Count -gt 0) {
        $checks.Add((New-SpecrewGatePreflightCheck -Name 'working-tree' -Status pass -Message ("Only {0} writer-owned governance record path(s) are uncommitted; they are classified explicitly and do not disguise product work." -f $statusRecords.Count) -Evidence $statusRecords)) | Out-Null
    }
    else {
        $checks.Add((New-SpecrewGatePreflightCheck -Name 'working-tree' -Status pass -Message 'The working tree is clean.' -Evidence @())) | Out-Null
    }

    $featurePath = if ([string]::IsNullOrWhiteSpace($FeatureRef)) { $null } else { Join-Path $root ('specs/' + (Split-Path -Leaf $FeatureRef)) }
    $iterationPath = if ($null -eq $featurePath -or [string]::IsNullOrWhiteSpace($IterationNumber)) { $null } else { Join-Path $featurePath ('iterations/' + $IterationNumber) }
    $taskPath = if ($null -eq $iterationPath) { $null } else { Join-Path $iterationPath 'tasks-progress.yml' }
    $statePath = if ($null -eq $iterationPath) { $null } else { Join-Path $iterationPath 'state.md' }
    if ($null -ne $taskPath -and (Test-Path -LiteralPath $taskPath -PathType Leaf) -and (Test-Path -LiteralPath $statePath -PathType Leaf)) {
        $tasks = Get-SpecrewGatePreflightTaskState -Path $taskPath
        $allowed = @('pending', 'in-progress', 'done', 'blocked', 'needs-rework', 'deferred')
        $bad = @($tasks.GetEnumerator() | Where-Object { [string]::IsNullOrWhiteSpace([string]$_.Value) -or [string]$_.Value -notin $allowed })
        $expectedRemaining = @($tasks.GetEnumerator() | Where-Object { [string]$_.Value -ne 'done' } | ForEach-Object { [string]$_.Key } | Sort-Object)
        $expectedProgress = @($tasks.GetEnumerator() | Where-Object { [string]$_.Value -eq 'in-progress' } | ForEach-Object { [string]$_.Key } | Sort-Object)
        $remainingValue = Get-SpecrewGatePreflightMarkdownValue -Path $statePath -Label 'Tasks Remaining'
        $progressValue = Get-SpecrewGatePreflightMarkdownValue -Path $statePath -Label 'In Progress'
        $actualRemaining = @(ConvertFrom-SpecrewGatePreflightIdList -Value $remainingValue | Sort-Object)
        $actualProgress = @(ConvertFrom-SpecrewGatePreflightIdList -Value $progressValue | Sort-Object)
        $consistent = $bad.Count -eq 0 -and ($expectedRemaining -join ',') -ceq ($actualRemaining -join ',') -and ($expectedProgress -join ',') -ceq ($actualProgress -join ',')
        if ($consistent) {
            $checks.Add((New-SpecrewGatePreflightCheck -Name 'task-state' -Status pass -Message 'Task status values and state.md summaries agree.' -Evidence @{ task_count = $tasks.Count })) | Out-Null
        }
        else {
            $checks.Add((New-SpecrewGatePreflightCheck -Name 'task-state' -Status fail -Message 'tasks-progress.yml contains an invalid status or disagrees with state.md Tasks Remaining/In Progress.' -Evidence @{ invalid = @($bad | ForEach-Object { "{0}:{1}" -f $_.Key, $_.Value }); expected_remaining = $expectedRemaining; actual_remaining = $actualRemaining; expected_in_progress = $expectedProgress; actual_in_progress = $actualProgress })) | Out-Null
        }
    }
    else {
        $checks.Add((New-SpecrewGatePreflightCheck -Name 'task-state' -Status not-applicable -Message 'No paired tasks-progress.yml/state.md exists at this stage.' -Evidence $null)) | Out-Null
    }

    $contract = @(Get-SpecrewBoundaryStageEvidenceContract | Where-Object { $_.Boundary -ceq $BoundaryType })
    $missing = New-Object System.Collections.Generic.List[string]
    if ($contract.Count -eq 1 -and [string]$contract[0].Kind -ne 'none') {
        $base = if ([string]$contract[0].Kind -eq 'iteration-file') { $iterationPath } else { $featurePath }
        foreach ($relative in @($contract[0].Paths)) {
            $path = if ($null -eq $base) { $null } else { Join-Path $base ([string]$relative) }
            if ($null -eq $path -or -not (Test-Path -LiteralPath $path -PathType Leaf)) { $missing.Add([string]$relative) | Out-Null }
        }
        if ([string]$contract[0].Kind -eq 'content' -and $missing.Count -eq 0) {
            $content = Get-Content -LiteralPath (Join-Path $featurePath ([string]$contract[0].Paths[0])) -Raw -Encoding UTF8
            $markerMatches = @($contract[0].Markers | Where-Object { $content -match [string]$_ })
            if ($markerMatches.Count -eq 0) { $missing.Add(([string]$contract[0].Paths[0] + ' required content')) | Out-Null }
        }
    }
    if ($missing.Count -gt 0) {
        $checks.Add((New-SpecrewGatePreflightCheck -Name 'owed-artifact' -Status fail -Message ("Boundary '$BoundaryType' is missing owed evidence: {0}." -f ($missing -join ', ')) -Evidence $missing.ToArray())) | Out-Null
    }
    else {
        $checks.Add((New-SpecrewGatePreflightCheck -Name 'owed-artifact' -Status pass -Message "Boundary '$BoundaryType' has its owed artifact floor." -Evidence $null)) | Out-Null
    }

    $result = [pscustomobject][ordered]@{
        schema_version = '1.0'
        ok = @($checks | Where-Object { $_.status -eq 'fail' }).Count -eq 0
        project_root = $root
        boundary = $BoundaryType
        feature_ref = $FeatureRef
        iteration = $IterationNumber
        checks = $checks.ToArray()
    }
    if ($FailOnError.IsPresent -and -not $result.ok) {
        $failures = @($result.checks | Where-Object { $_.status -eq 'fail' } | ForEach-Object { "[{0}] {1}" -f $_.name, $_.message })
        throw ("Boundary gate preflight failed before packet/state mutation:`n - " + ($failures -join "`n - "))
    }
    return $result
}
