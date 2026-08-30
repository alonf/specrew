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

function Get-SpecrewGatePreflightEnforcementMode {
    # FR-025 (T016): repository_governance.enforcement_mode is a schema enum
    # (branch-protection | rulesets | ci-only | manual) that carries exactly the
    # intended-vs-active distinction the delivery check needs. It sat in the same file the check
    # already reads and was never consulted. Same line-oriented read as release_truth_branch.
    [CmdletBinding()]
    param([Parameter(Mandatory = $true)][string]$ProjectRoot)
    $governancePath = Join-Path $ProjectRoot '.specrew/repository-governance.yml'
    if (-not (Test-Path -LiteralPath $governancePath -PathType Leaf)) { return '' }
    foreach ($line in Get-Content -LiteralPath $governancePath -Encoding UTF8) {
        if ($line -match '^\s*enforcement_mode:\s*["'']?(?<value>[^"''#\s]+)') { return $Matches['value'].Trim().ToLowerInvariant() }
    }
    return ''
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

    # FR-025 (iteration 002, T016): ONE CHECK, ONE JOB. `pushed-head` used to carry two: release-model
    # DELIVERY (what the schema says it governs - "release_model controls only applicable closeout delivery
    # steps") and, silently, the DURABILITY of the commit a verdict binds to. Aimed at delivery, it fired at
    # `specify` and demanded a published repository to clear a SPECIFICATION (the HelloWinUIReactive walk,
    # blocked there). Split into two named checks, each with its own message and its own job.
    $release = Resolve-SpecrewReleaseModel -ProjectRoot $root
    $branch = [string](@(& git -C $root branch --show-current 2>$null) | Select-Object -First 1)
    $originUrl = @(& git -C $root remote get-url origin 2>$null)
    $hasOrigin = ($LASTEXITCODE -eq 0 -and $originUrl.Count -gt 0)
    $remoteHeadForBranch = ''
    if ($hasOrigin -and -not [string]::IsNullOrWhiteSpace($branch)) {
        $remoteLine = [string](@(& git -C $root ls-remote --heads origin ("refs/heads/{0}" -f $branch) 2>$null) | Select-Object -First 1)
        if ($remoteLine -match '^(?<hash>[0-9a-f]{40,64})\s+') { $remoteHeadForBranch = $Matches['hash'] }
    }
    $enforcementMode = Get-SpecrewGatePreflightEnforcementMode -ProjectRoot $root

    # --- DELIVERY: pushed-head, at the boundaries that actually deliver -----------------------------------
    $deliveryBoundaries = @('iteration-closeout', 'feature-closeout')
    if ($BoundaryType -notin $deliveryBoundaries) {
        $checks.Add((New-SpecrewGatePreflightCheck -Name 'pushed-head' -Status not-applicable -Message ("Release model '{0}' governs closeout delivery only; nothing is owed to origin at the '{1}' boundary." -f $release.Model, $BoundaryType) -Evidence @{ release_model = $release.Model; boundary = $BoundaryType })) | Out-Null
    }
    elseif ([string]$release.Model -eq 'local-only') {
        $checks.Add((New-SpecrewGatePreflightCheck -Name 'pushed-head' -Status not-applicable -Message 'The recorded release model is local-only; no remote push is owed.' -Evidence @{ release_model = $release.Model })) | Out-Null
    }
    elseif (-not $hasOrigin) {
        # The declared-but-not-yet-created remote: the DevOps lens records the agreed future posture and says
        # honestly, in the same file, that it is not active yet (enforcement_mode: manual). Reading only
        # release_model made that honesty the thing that blocked the walk - the inert-fact shape, where the
        # fact needed to decide is present and unread.
        if ([string]::IsNullOrWhiteSpace($enforcementMode) -or $enforcementMode -eq 'manual') {
            $checks.Add((New-SpecrewGatePreflightCheck -Name 'pushed-head' -Status not-applicable -Message ("Release model '{0}' is recorded with enforcement_mode '{1}' and no origin exists yet: the remote posture is a declared intention, not an active obligation. Nothing is owed now; delivery to origin becomes owed at the first closeout after the remote exists. To activate it, create the repository and add it as 'origin' - the recorded decision itself needs no change." -f $release.Model, $(if ([string]::IsNullOrWhiteSpace($enforcementMode)) { 'manual (no repository_governance block)' } else { $enforcementMode })) -Evidence @{ release_model = $release.Model; enforcement_mode = $enforcementMode })) | Out-Null
        }
        else {
            $checks.Add((New-SpecrewGatePreflightCheck -Name 'pushed-head' -Status fail -Message ("Release model '{0}' with enforcement_mode '{1}' requires origin, but origin is not configured: the record claims active remote enforcement, and that cannot be true without a remote. Add the remote as 'origin', or record enforcement_mode: manual until it exists." -f $release.Model, $enforcementMode) -Evidence @{ release_model = $release.Model; enforcement_mode = $enforcementMode })) | Out-Null
        }
    }
    elseif ([string]::IsNullOrWhiteSpace($branch)) {
        $checks.Add((New-SpecrewGatePreflightCheck -Name 'pushed-head' -Status fail -Message 'A remote-delivered boundary cannot use a detached HEAD.' -Evidence @{ release_model = $release.Model })) | Out-Null
    }
    elseif ([string]::IsNullOrWhiteSpace($remoteHeadForBranch) -or $remoteHeadForBranch -cne $head) {
        $checks.Add((New-SpecrewGatePreflightCheck -Name 'pushed-head' -Status fail -Message "Branch '$branch' is not pushed to origin at the current HEAD." -Evidence @{ local_head = $head; remote_head = $remoteHeadForBranch; branch = $branch })) | Out-Null
    }
    else {
        $checks.Add((New-SpecrewGatePreflightCheck -Name 'pushed-head' -Status pass -Message "origin/$branch matches the current HEAD." -Evidence @{ head = $head; branch = $branch })) | Out-Null
    }

    # --- DURABILITY: verdict-commit-durable, at EVERY boundary --------------------------------------------
    # The second job, now named. Every boundary records an auth_commit_hash and THREE readers resolve it back
    # against git: Get-SpecrewGitArtifactStateId derives the crossing's tree from it, Get-SpecrewBoundaryStage-
    # Evidence reads that tree, and the constraint-change path diffs it against the previous boundary commit.
    # A verdict bound to a commit that exists only locally is one rebase away from naming nothing. With an
    # origin this is exactly the requirement pushed-head used to impose everywhere - unchanged in strength,
    # only renamed to its job; without one it is an honest note, not a demand to publish.
    if (-not $hasOrigin) {
        $checks.Add((New-SpecrewGatePreflightCheck -Name 'verdict-commit-durable' -Status not-applicable -Message ("Boundary verdicts bind to commit '{0}' and later gates resolve it back. No origin is configured, so this local history is the only copy: do not rewrite or drop this commit. When a remote exists, pushing the branch makes the record durable." -f $(if ($head.Length -ge 8) { $head.Substring(0, 8) } else { $head })) -Evidence @{ head = $head })) | Out-Null
    }
    elseif ([string]::IsNullOrWhiteSpace($branch)) {
        $checks.Add((New-SpecrewGatePreflightCheck -Name 'verdict-commit-durable' -Status fail -Message 'Boundary verdicts bind to the current commit and later gates resolve it back, but HEAD is detached: there is no branch whose remote copy could preserve it. Check out the feature branch before recording a boundary.' -Evidence @{ head = $head })) | Out-Null
    }
    elseif ([string]::IsNullOrWhiteSpace($remoteHeadForBranch) -or $remoteHeadForBranch -cne $head) {
        $checks.Add((New-SpecrewGatePreflightCheck -Name 'verdict-commit-durable' -Status fail -Message ("Boundary verdicts bind to commit '{0}' and later gates resolve it back (stage evidence, constraint diffs, review coverage). It exists only in this local history: origin/{1} is at '{2}'. Push the branch so the commit the verdict names survives a rebase or a lost checkout: git push origin {1}" -f $(if ($head.Length -ge 8) { $head.Substring(0, 8) } else { $head }), $branch, $(if ([string]::IsNullOrWhiteSpace($remoteHeadForBranch)) { 'no such branch' } elseif ($remoteHeadForBranch.Length -ge 8) { $remoteHeadForBranch.Substring(0, 8) } else { $remoteHeadForBranch })) -Evidence @{ local_head = $head; remote_head = $remoteHeadForBranch; branch = $branch })) | Out-Null
    }
    else {
        $checks.Add((New-SpecrewGatePreflightCheck -Name 'verdict-commit-durable' -Status pass -Message ("origin/{0} carries the commit this boundary binds to." -f $branch) -Evidence @{ head = $head; branch = $branch })) | Out-Null
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
    $owedUnverifiable = $false
    if ($contract.Count -eq 1 -and [string]$contract[0].Kind -ne 'none') {
        $base = if ([string]$contract[0].Kind -eq 'iteration-file') { $iterationPath } else { $featurePath }
        # ABSENT AND UNVERIFIABLE ARE DIFFERENT ANSWERS, and this check used to give the first for both.
        #
        # Found in the HelloWinUIReactive walk, 2026-08-30: with no resolvable feature - the ordinary state
        # of a project whose start-context carries no feature_ref - $base is null, every owed path was added
        # to $missing, and the gate reported `Boundary 'specify' is missing owed evidence: spec.md` for a
        # spec.md THAT EXISTS ON DISK. Naming the same project with -Feature makes the identical check pass.
        # A consumer is told a file they are looking at is missing, which is the worst kind of refusal: it
        # is specific, confident and false.
        #
        # The sibling implementation of this exact question already draws the distinction. FR-024's
        # Test-SpecrewBoundaryOwedArtifactsOnDisk returns Absent=$false with no feature identity, because a
        # positive ABSENT reading refuses loudly while UNVERIFIABLE keeps today's behaviour - method rule 12,
        # fail open on the diagnosis and say so. Two readers of one contract disagreed, and the one a human
        # meets at a boundary was the wrong one.
        if ($null -eq $base) {
            $owedUnverifiable = $true
        }
        else {
            foreach ($relative in @($contract[0].Paths)) {
                $path = Join-Path $base ([string]$relative)
                if (-not (Test-Path -LiteralPath $path -PathType Leaf)) { $missing.Add([string]$relative) | Out-Null }
            }
        }
        if ([string]$contract[0].Kind -eq 'content' -and $missing.Count -eq 0) {
            $content = Get-Content -LiteralPath (Join-Path $featurePath ([string]$contract[0].Paths[0])) -Raw -Encoding UTF8
            $markerMatches = @($contract[0].Markers | Where-Object { $content -match [string]$_ })
            if ($markerMatches.Count -eq 0) { $missing.Add(([string]$contract[0].Paths[0] + ' required content')) | Out-Null }
        }
    }
    if ($owedUnverifiable) {
        $checks.Add((New-SpecrewGatePreflightCheck -Name 'owed-artifact' -Status not-applicable -Message ("Boundary '$BoundaryType' owes evidence, but this run could not resolve which feature it belongs to, so nothing was checked. Name the feature to check it: pass -Feature <feature-ref>, or record the active feature in .specrew/start-context.json.") -Evidence $null)) | Out-Null
    }
    elseif ($missing.Count -gt 0) {
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
