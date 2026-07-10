# Tracker honesty check (F-198 FR-020 / proposal 203-W13, design mechanism b).
#
# The digest identity formula is UNCHANGED - trackers stay identity. This module lets the
# signoff gate ACCEPT a passing run's evidence as fresh when the only delta between the
# reviewed tree and the current tree is machine-managed tracker bookkeeping whose claims are
# consistent with (a subset of) the review record that run already accepted. The bypass is a
# gate-level, ANNOUNCED decision - never a change to what gets digested.
#
# Fail direction (binding, I3): any parse ambiguity, any unknown file shape, any claim the
# check cannot map to the accepted record -> NOT honest -> the digest stales exactly as
# today (costs at worst one re-review; fail-open here would be a false-green door).

Set-StrictMode -Version Latest

$script:TrackerPathPattern = '^specs/[^/]+/iterations/[^/]+/(state\.md|tasks-progress\.yml)$'

function Get-ContinuousCoReviewTrackerOnlyDelta {
    # The name-only delta between two REVIEWED trees (git tree objects persist, so both sides
    # are always materializable). TrackerOnly is true only when every changed path is a
    # machine-managed tracker AND at least one path changed (identical-looking ids with an
    # empty visible delta are suspicious -> not tracker-only, fail-closed).
    param(
        [Parameter(Mandatory)][string]$RepoRoot,
        [Parameter(Mandatory)][string]$FromTreeId,
        [Parameter(Mandatory)][string]$ToTreeId
    )

    $result = Invoke-ContinuousCoReviewGit -RepoRoot $RepoRoot -Arguments @('diff', '--name-only', $FromTreeId, $ToTreeId)
    if ($result.ExitCode -ne 0) {
        return [pscustomobject]@{ Ok = $false; TrackerOnly = $false; Paths = @(); Reason = 'delta-unresolvable' }
    }
    $paths = @($result.Output | Where-Object { $_ -and ($_ -notmatch '^(fatal|error):') })
    if ($paths.Count -eq 0) {
        return [pscustomobject]@{ Ok = $true; TrackerOnly = $false; Paths = @(); Reason = 'empty-delta' }
    }
    $trackerOnly = $true
    foreach ($p in $paths) {
        if (($p -replace '\\', '/') -notmatch $script:TrackerPathPattern) { $trackerOnly = $false; break }
    }
    [pscustomobject]@{ Ok = $true; TrackerOnly = $trackerOnly; Paths = $paths; Reason = $(if ($trackerOnly) { 'tracker-only' } else { 'non-tracker-paths' }) }
}

function Get-ContinuousCoReviewTreeFileContent {
    param(
        [Parameter(Mandatory)][string]$RepoRoot,
        [Parameter(Mandatory)][string]$TreeId,
        [Parameter(Mandatory)][string]$Path
    )
    $result = Invoke-ContinuousCoReviewGit -RepoRoot $RepoRoot -Arguments @('show', ("{0}:{1}" -f $TreeId, (($Path) -replace '\\', '/')))
    if ($result.ExitCode -ne 0) { return $null }
    return ($result.Output -join "`n")
}

function Get-ContinuousCoReviewStateClaims {
    # Parse the claiming fields of a state.md. Returns $null when the shape is not the
    # canonical one (fail-closed at the caller).
    param([AllowNull()][string]$Content)
    if ([string]::IsNullOrWhiteSpace($Content)) { return $null }
    $status = if ($Content -match '(?m)^\*\*Iteration Status\*\*:\s*(?<v>[a-z-]+)\s*$') { $Matches['v'] } else { $null }
    $lastTask = if ($Content -match '(?m)^\*\*Last Completed Task\*\*:\s*(?<v>\S[^\r\n]*)$') { $Matches['v'].Trim() } else { $null }
    if ($null -eq $status -and $null -eq $lastTask) { return $null }
    [pscustomobject]@{ IterationStatus = $status; LastCompletedTask = $lastTask }
}

function Get-ContinuousCoReviewAcceptedReviewRecord {
    # The accepted review record FROM THE REVIEWED TREE: overall verdict + per-task verdicts.
    # $null when review.md is absent or unparseable (fail-closed at the caller).
    param(
        [Parameter(Mandatory)][string]$RepoRoot,
        [Parameter(Mandatory)][string]$TreeId,
        [Parameter(Mandatory)][string]$IterationDirRelative
    )
    $reviewPath = ("{0}/review.md" -f ($IterationDirRelative -replace '\\', '/')).TrimStart('/')
    $content = Get-ContinuousCoReviewTreeFileContent -RepoRoot $RepoRoot -TreeId $TreeId -Path $reviewPath
    if ([string]::IsNullOrWhiteSpace($content)) { return $null }
    $overall = if ($content -match '(?m)^\*\*Overall Verdict\*\*:\s*(?<v>[a-z-]+)\s*$') { $Matches['v'] } else { $null }
    if ($null -eq $overall) { return $null }
    $taskVerdicts = @{}
    foreach ($m in [regex]::Matches($content, '(?m)^\|\s*(?<task>T\d{3})\s*\|[^|]*\|\s*(?<verdict>pass|needs-work|locked)\s*\|')) {
        $taskVerdicts[$m.Groups['task'].Value] = $m.Groups['verdict'].Value
    }
    [pscustomobject]@{ OverallVerdict = $overall; TaskVerdicts = $taskVerdicts }
}

function Test-ContinuousCoReviewTrackerReconcileHonest {
    # THE honesty decision for one tracker-only delta: every claiming change in the new
    # tracker content must be covered by the accepted review record already inside the
    # reviewed tree. Claim-INCREASING edits (done/complete beyond the accepted record) and
    # every parse ambiguity return Honest=$false.
    param(
        [Parameter(Mandatory)][string]$RepoRoot,
        [Parameter(Mandatory)][string]$FromTreeId,
        [Parameter(Mandatory)][string]$ToTreeId,
        [Parameter(Mandatory)][string[]]$TrackerPaths
    )

    foreach ($path in $TrackerPaths) {
        $normalized = $path -replace '\\', '/'
        if ($normalized -notmatch $script:TrackerPathPattern) {
            return [pscustomobject]@{ Honest = $false; Reason = ("non-tracker path '{0}' in a tracker-only check" -f $normalized) }
        }
        $iterationDir = $normalized -replace '/(state\.md|tasks-progress\.yml)$', ''
        $accepted = Get-ContinuousCoReviewAcceptedReviewRecord -RepoRoot $RepoRoot -TreeId $FromTreeId -IterationDirRelative $iterationDir
        if ($null -eq $accepted) {
            return [pscustomobject]@{ Honest = $false; Reason = ("no parseable accepted review record beside '{0}' in the reviewed tree" -f $normalized) }
        }

        if ($normalized -like '*state.md') {
            $oldClaims = Get-ContinuousCoReviewStateClaims -Content (Get-ContinuousCoReviewTreeFileContent -RepoRoot $RepoRoot -TreeId $FromTreeId -Path $normalized)
            $newClaims = Get-ContinuousCoReviewStateClaims -Content (Get-ContinuousCoReviewTreeFileContent -RepoRoot $RepoRoot -TreeId $ToTreeId -Path $normalized)
            if ($null -eq $newClaims) {
                return [pscustomobject]@{ Honest = $false; Reason = ("unparseable new state claims in '{0}'" -f $normalized) }
            }
            # Iteration Status: 'complete' is a claim - it needs the accepted overall verdict.
            if ([string]$newClaims.IterationStatus -eq 'complete' -and [string]$accepted.OverallVerdict -ne 'accepted') {
                return [pscustomobject]@{ Honest = $false; Reason = 'state.md claims complete but the accepted review verdict is not accepted' }
            }
            # Last Completed Task: claiming a NEW task needs that task's pass verdict.
            $newTask = [string]$newClaims.LastCompletedTask
            $oldTask = if ($null -ne $oldClaims) { [string]$oldClaims.LastCompletedTask } else { '' }
            if ($newTask -match '^(?<id>T\d{3})' -and $newTask -ne $oldTask) {
                $taskId = $Matches['id']
                if (-not $accepted.TaskVerdicts.ContainsKey($taskId) -or [string]$accepted.TaskVerdicts[$taskId] -ne 'pass') {
                    return [pscustomobject]@{ Honest = $false; Reason = ("state.md claims '{0}' completed but the accepted review has no pass verdict for it" -f $taskId) }
                }
            }
            continue
        }

        # tasks-progress.yml: canonical simple map lines `Tnnn: <status>`; anything else is
        # ambiguous -> fail-closed. A task newly claimed 'done' needs its accepted pass verdict.
        $oldContent = Get-ContinuousCoReviewTreeFileContent -RepoRoot $RepoRoot -TreeId $FromTreeId -Path $normalized
        $newContent = Get-ContinuousCoReviewTreeFileContent -RepoRoot $RepoRoot -TreeId $ToTreeId -Path $normalized
        if ([string]::IsNullOrWhiteSpace($newContent)) {
            return [pscustomobject]@{ Honest = $false; Reason = ("unreadable new tracker content '{0}'" -f $normalized) }
        }
        $parseMap = {
            param($content)
            $map = @{}
            foreach ($line in ($content -split "`r?`n")) {
                if ([string]::IsNullOrWhiteSpace($line) -or $line.TrimStart().StartsWith('#')) { continue }
                if ($line -match '^\s*(?<task>T\d{3})\s*:\s*(?<status>[a-z-]+)\s*$') {
                    $map[$Matches['task']] = $Matches['status']
                }
                else { return $null }
            }
            $map
        }
        $newMap = & $parseMap $newContent
        if ($null -eq $newMap) {
            return [pscustomobject]@{ Honest = $false; Reason = ("non-canonical tasks-progress shape in '{0}'" -f $normalized) }
        }
        $oldMap = if ([string]::IsNullOrWhiteSpace($oldContent)) { @{} } else { & $parseMap $oldContent }
        if ($null -eq $oldMap) { $oldMap = @{} }
        foreach ($taskId in $newMap.Keys) {
            if ([string]$newMap[$taskId] -ne 'done') { continue }
            if ($oldMap.ContainsKey($taskId) -and [string]$oldMap[$taskId] -eq 'done') { continue }
            if (-not $accepted.TaskVerdicts.ContainsKey($taskId) -or [string]$accepted.TaskVerdicts[$taskId] -ne 'pass') {
                return [pscustomobject]@{ Honest = $false; Reason = ("tasks-progress claims '{0}' done but the accepted review has no pass verdict for it" -f $taskId) }
            }
        }
    }

    [pscustomobject]@{ Honest = $true; Reason = 'claims are a subset of the accepted review record' }
}
