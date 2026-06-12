<#
.SYNOPSIS
  Resolve a feature ref against project-local metadata and git merged-status.
.DESCRIPTION
  Resource accessor (IDesign): reads the feature's project-local presence (specs/<ref>/) and
  corroborates "not resumable" with git merged-status (data-storage d3). The feature ref is
  always re-resolved against the current project root - the committed absolute path is never
  trusted (FR-015). Git calls fail safe (a failure means "not provably merged", never a false
  clear). Feature 174 (FR-014, FR-015). Active-features registry + closeout-artifact signals
  are layered in later; presence + merged-status is the iteration-001 floor.
#>

function Test-SpecrewFeatureLocal {
    # specs/<ref>/ exists under the current project root.
    [CmdletBinding()]
    [OutputType([bool])]
    param([Parameter(Mandatory)][string] $SpecsRoot, [Parameter(Mandatory)][string] $FeatureRef)
    return (Test-Path -LiteralPath (Join-Path $SpecsRoot $FeatureRef) -PathType Container)
}

function Test-SpecrewBranchMergedToBase {
    # True when $Branch is fully merged into $BaseBranch (its tip is an ancestor of base).
    # Fails safe: any git error (missing branch/repo) returns $false, never a false "merged".
    [CmdletBinding()]
    [OutputType([bool])]
    param(
        [Parameter(Mandatory)][string] $RepoRoot,
        [Parameter(Mandatory)][string] $Branch,
        [Parameter(Mandatory)][string] $BaseBranch
    )
    try {
        & git -C $RepoRoot merge-base --is-ancestor $Branch $BaseBranch 2>$null
        return ($LASTEXITCODE -eq 0)
    }
    catch { return $false }
}

function Get-SpecrewFeatureResumable {
    # Compose project-local presence + git merged-status into a resumability verdict.
    [CmdletBinding()]
    [OutputType([pscustomobject])]
    param(
        [Parameter(Mandatory)][string] $ProjectRoot,
        [Parameter(Mandatory)][string] $FeatureRef,
        [Parameter()][string] $BaseBranch = 'main'
    )
    $present = Test-SpecrewFeatureLocal -SpecsRoot (Join-Path $ProjectRoot 'specs') -FeatureRef $FeatureRef
    $merged = $false
    if ($present) {
        $merged = Test-SpecrewBranchMergedToBase -RepoRoot $ProjectRoot -Branch $FeatureRef -BaseBranch $BaseBranch
    }
    [pscustomobject]@{
        feature_ref = $FeatureRef
        present     = $present
        merged      = $merged
        resumable   = ($present -and -not $merged)
    }
}

function Resolve-SpecrewBranchFeatureRef {
    # Resolve the active feature from the CURRENT git branch when no persisted anchor names one yet.
    # The pre-specify WORKSHOP window is the gap (F-174 T050): specs/<feature>/ already exists (Spec Kit's
    # create-new-feature scaffolds it before the workshop runs), but no boundary has crossed, so
    # start-context.json session_state.feature_ref is still blank. Without a feature, the Stop floor-writer
    # stamps an empty active_feature -> Test-SpecrewHandoverValidity returns 'no-feature' -> the handover is
    # NEVER surfaced on resume (the agent re-derives the whole situation from scratch - minutes). In Spec Kit
    # the branch name IS the feature slug (the specs dir shares its name), so the branch is the authoritative,
    # MULTI-FEATURE-SAFE key (a disk scan of specs/ would be ambiguous; the branch is not).
    #   Returns the branch as the feature ref ONLY when it matches the Spec Kit feature-branch contract
    #   (^\d{3}[-_]) AND specs/<branch>/ exists locally; else $null. So on main / a non-feature branch / a
    #   closed feature whose dir was deleted -> $null (no bogus stamp; identical to today's behavior). The
    #   read-side Test-SpecrewHandoverValidity still re-checks present + not-merged + the 24h freshness bound,
    #   so a feature merged AFTER the stamp is caught on resume. Git failure -> $null (fail-safe). F-174 (T050).
    [CmdletBinding()]
    [OutputType([string])]
    param([Parameter(Mandatory)][string] $ProjectRoot)

    $branch = $null
    try {
        $out = @(& git -C $ProjectRoot branch --show-current 2>$null)
        if ($LASTEXITCODE -eq 0 -and $out.Count -gt 0 -and -not [string]::IsNullOrWhiteSpace([string]$out[0])) {
            $branch = ([string]$out[0]).Trim()
        }
    }
    catch { return $null }

    if ([string]::IsNullOrWhiteSpace($branch)) { return $null }
    if ($branch -notmatch '^\d{3}[-_]') { return $null }
    if (-not (Test-SpecrewFeatureLocal -SpecsRoot (Join-Path $ProjectRoot 'specs') -FeatureRef $branch)) { return $null }
    return $branch
}

function Get-SpecrewWorkshopProgress {
    # Deterministic DISK-TRUTH scan of a feature's in-flight intent + status, for the bootstrap directive
    # (F-174 T050 round-2 finding): on resume, the intent (spec.md) and status (workshop records +
    # lens-applicability.json moved_on flags) ARE on disk, but nothing SURFACED them - so copilot asked
    # "what do you want to build" with the answer sitting in spec.md, and codex reported the hollow handover
    # then stopped ("re-derive from the artifacts" as an abstract pointer gets skimmed; surfaced CONTENT gets
    # followed - the iter-7 inline-the-contract lesson again). This accessor reads, the directive renders.
    # Fail open: any read error -> the empty shape (never blocks the bootstrap).
    [CmdletBinding()]
    [OutputType([pscustomobject])]
    param(
        [Parameter(Mandatory)][string] $ProjectRoot,
        [Parameter(Mandatory)][string] $FeatureRef
    )

    $featureDir = Join-Path (Join-Path $ProjectRoot 'specs') $FeatureRef
    $specPath = Join-Path $featureDir 'spec.md'
    $specExists = Test-Path -LiteralPath $specPath -PathType Leaf

    # Lens records persisted under the workshop folder (the per-lens durable checkpoints).
    $lensRecords = @()
    try {
        $wdir = Join-Path $featureDir 'workshop'
        if (Test-Path -LiteralPath $wdir -PathType Container) {
            $lensRecords = @(Get-ChildItem -LiteralPath $wdir -Filter '*.md' -File |
                    ForEach-Object { [System.IO.Path]::GetFileNameWithoutExtension($_.Name) } |
                    Where-Object { $_ -ne 'lens-applicability' } | Sort-Object)
        }
    }
    catch { $lensRecords = @() }

    # lens-applicability.json: selected lenses + per-lens moved_on (done) flags. Hosts have written it both
    # feature-level (the skill's contract) and under workshop/ - accept either.
    $selected = @(); $done = @(); $applicabilityFound = $false
    foreach ($cand in @((Join-Path $featureDir 'lens-applicability.json'), (Join-Path (Join-Path $featureDir 'workshop') 'lens-applicability.json'))) {
        if (-not (Test-Path -LiteralPath $cand -PathType Leaf)) { continue }
        try {
            $la = Get-Content -LiteralPath $cand -Raw -ErrorAction Stop | ConvertFrom-Json -ErrorAction Stop
            $applicabilityFound = $true
            # StrictMode-safe local reads (this accessor stays self-contained; no SessionStateAccessor dep).
            $selProp = $la.PSObject.Properties['selected']
            if ($selProp -and $null -ne $selProp.Value) { $selected = @($selProp.Value | ForEach-Object { [string]$_ }) }
            $wProp = $la.PSObject.Properties['workshop']
            if ($wProp -and $null -ne $wProp.Value) {
                foreach ($p in $wProp.Value.PSObject.Properties) {
                    $mo = $p.Value.PSObject.Properties['moved_on']
                    if ($mo -and [bool]$mo.Value) { $done += [string]$p.Name }
                }
            }
            break
        }
        catch { continue }
    }

    # done = the union of moved_on records and persisted lens files (a host that writes the file but not the
    # json - codex - still counts as progressed); remaining = selected minus done, in selected order.
    $doneAll = @(@($done) + @($lensRecords) | Select-Object -Unique)
    $remaining = @($selected | Where-Object { $doneAll -notcontains $_ })

    [pscustomobject]@{
        feature_ref    = $FeatureRef
        spec_exists    = $specExists
        spec_path      = if ($specExists) { "specs/$FeatureRef/spec.md" } else { $null }
        selected       = $selected
        done           = $doneAll
        remaining      = $remaining
        has_applicability = $applicabilityFound
        in_flight      = ($specExists -or ($doneAll.Count -gt 0))
    }
}

function Test-SpecrewIsGitRepoRoot {
    # F-174 iter-10 (Prop-145 round-6, HIGH): is $ProjectRoot the TOP-LEVEL of its own git repo (or a worktree
    # root)? `git rev-parse --show-prefix` answers in O(repo-depth), NOT O(tree): empty output + exit 0 ==
    # $ProjectRoot IS the top-level (a linked worktree root also returns empty -> passes); a NON-empty prefix ==
    # $ProjectRoot sits BELOW some repo's root (nested); a non-zero exit == not a git repo at all. Why this and
    # not `--show-toplevel` + a path-compare: the toplevel path comes back in git's casing/slash form and a temp
    # root under an 8.3-short HOME ($env:TEMP = C:\Users\ALON~1.HOM) never string-equals git's C:\Users\alon.HOME
    # -> a false "nested" on the developer's own machine. --show-prefix sidesteps all path normalization. The
    # gate exists so Get-SpecrewSessionDelta never runs `git status` against a PARENT repo it merely lives inside
    # (e.g. a non-repo project root under a HOME that is itself a worktree) - that scan walks the WHOLE parent
    # tree and can hang the hook. Fail-safe: any error -> $false (treat as "not a clean repo root", skip the scan).
    [CmdletBinding()]
    [OutputType([bool])]
    param([Parameter(Mandatory)][string] $ProjectRoot)
    try {
        $prefix = (& git -C $ProjectRoot rev-parse --show-prefix 2>$null)
        return (($LASTEXITCODE -eq 0) -and [string]::IsNullOrEmpty(([string]$prefix).Trim()))
    }
    catch { return $false }
}

function Get-SpecrewEmptySessionDelta {
    # The empty/zero delta shape Get-SpecrewSessionDelta returns when there is no git scan to run (not a repo
    # root). Single source of truth so the gate and the happy path can never drift in shape.
    [OutputType([pscustomobject])]
    param()
    [pscustomobject]@{
        branch                = ''
        head_short            = ''
        head_subject          = ''
        uncommitted_count     = 0
        uncommitted_files     = @()
        uncommitted_truncated = $false
        has_uncommitted       = $false
        user_file_count       = 0
        user_files            = @()
        managed_file_count    = 0
        new_commits           = @()
        new_commit_count      = 0
    }
}

function Get-SpecrewSessionDelta {
    # F-174 iter-9: the git/filesystem delta the Stop hook captures as the rolling handover's MECHANICAL
    # body - host-universal, needs NO transcript and NO agent cooperation (the iter-8 dogfood proved the
    # agent-/gate-dependent author is hollow in practice; the git delta is always available). Fail-safe: any
    # git error yields the empty/zero shape so the handover degrades, never throws. $SinceCommit (the prior
    # handover's from_commit) bounds "new commits this session"; $null/unresolvable -> no new-commit list.
    [CmdletBinding()]
    [OutputType([pscustomobject])]
    param(
        [Parameter(Mandatory)][string] $ProjectRoot,
        [Parameter()][AllowNull()][string] $SinceCommit,
        [Parameter()][int] $MaxFiles = 12,
        [Parameter()][int] $MaxCommits = 8
    )
    # Prop-145 round-6 (HIGH): gate the scan on "$ProjectRoot is its own repo root". When it is NOT (a non-repo
    # project root that merely sits under a parent git repo / worktree), `git status --untracked-files=all`
    # would scan the entire PARENT tree - unbounded, hangs the hook, and reports the parent's files as this
    # project's delta. Returning the empty shape here is the same fail-safe degrade as any git error.
    if (-not (Test-SpecrewIsGitRepoRoot -ProjectRoot $ProjectRoot)) { return Get-SpecrewEmptySessionDelta }

    $branch = ''; $headShort = ''; $headSubject = ''
    try { $branch = ([string](& git -C $ProjectRoot rev-parse --abbrev-ref HEAD 2>$null)).Trim() } catch { $null = $_ }
    try { $headShort = ([string](& git -C $ProjectRoot rev-parse --short HEAD 2>$null)).Trim() } catch { $null = $_ }
    try { $headSubject = ([string](& git -C $ProjectRoot log -1 --format=%s 2>$null)).Trim() } catch { $null = $_ }

    $uncommittedFiles = @()
    try {
        # --untracked-files=all expands untracked DIRECTORIES (e.g. specs/) into their individual files so the
        # user's real work (specs/<feature>/spec.md, workshop/<lens>.md) surfaces instead of a bare "specs/".
        $porcelain = @(& git -C $ProjectRoot status --porcelain --untracked-files=all 2>$null) | Where-Object { -not [string]::IsNullOrWhiteSpace($_) }
        $uncommittedFiles = @($porcelain | ForEach-Object { ($_ -replace '^..\s+', '').Trim() } | Where-Object { $_ })
    }
    catch { $uncommittedFiles = @() }

    # F-174 dogfood fix: the Specrew/Squad/Spec-Kit managed scaffolding (.agents/.claude/.copilot/.cursor/
    # .github/.specify/.squad/.specrew + the init config files) sorts first in `git status` and was filling
    # the MaxFiles cap, capping OUT the user's REAL work (specs/, src/) - so the rolling handover surfaced
    # the same ~53 scaffolding paths every refresh and never the actual workshop/spec files. Partition
    # managed vs user and surface USER files FIRST so the real work is never drowned or capped.
    $managedRegex = '^\.(agents|claude|copilot|cursor|github|specify|squad|specrew)[/\\]|^\.(gitattributes|gitignore|markdownlint\.json)$'
    $userFiles = @($uncommittedFiles | Where-Object { ($_ -replace '\\', '/') -notmatch $managedRegex })
    $managedFiles = @($uncommittedFiles | Where-Object { ($_ -replace '\\', '/') -match $managedRegex })
    $prioritized = @(@($userFiles) + @($managedFiles))

    $newCommits = @()
    if (-not [string]::IsNullOrWhiteSpace($SinceCommit)) {
        try {
            $log = @(& git -C $ProjectRoot log --oneline ("{0}..HEAD" -f $SinceCommit) 2>$null) | Where-Object { -not [string]::IsNullOrWhiteSpace($_) }
            if ($LASTEXITCODE -eq 0) { $newCommits = @($log) }
        }
        catch { $newCommits = @() }
    }

    [pscustomobject]@{
        branch                = $branch
        head_short            = $headShort
        head_subject          = $headSubject
        uncommitted_count     = $uncommittedFiles.Count
        uncommitted_files     = @($prioritized | Select-Object -First $MaxFiles)
        uncommitted_truncated = ($uncommittedFiles.Count -gt $MaxFiles)
        has_uncommitted       = ($uncommittedFiles.Count -gt 0)
        user_file_count       = $userFiles.Count
        user_files            = @($userFiles | Select-Object -First $MaxFiles)
        managed_file_count    = $managedFiles.Count
        new_commits           = @($newCommits | Select-Object -First $MaxCommits)
        new_commit_count      = $newCommits.Count
    }
}

function Get-SpecrewResumeReconciliation {
    # F-174 iter-10 (T001): the SHARED, CHEAP resume reconciliation. On RESUME, re-compute the CURRENT git
    # delta (one `git status` via Get-SpecrewSessionDelta) bounded by the handover's from_commit, so the
    # resuming agent is handed the ACTUAL tree state - NOT a stale last-stop snapshot - and is DIRECTED to
    # read what changed since and continue from the real state (the snapshot may predate the latest work; a
    # hard kill / no-PostToolUse host / antigravity all leave the handover behind the disk). Called by BOTH
    # the SessionStart hook (Invoke-SpecrewSessionBootstrap) AND `specrew start` (T008) so recovery is
    # host-universal. Lean by contract: ONE delta computation; the agent does the reading (the resume budget
    # is already spent on the launch contract). Fail-safe: any error yields $null and the resume degrades to
    # the snapshot, never throws.
    [OutputType([pscustomobject])]
    param(
        [Parameter(Mandatory)][string] $ProjectRoot,
        [Parameter()][AllowNull()][pscustomobject] $Handover
    )
    $sinceCommit = if ($null -ne $Handover) { [string]$Handover.from_commit } else { $null }
    $delta = $null
    try { $delta = Get-SpecrewSessionDelta -ProjectRoot $ProjectRoot -SinceCommit $sinceCommit } catch { $delta = $null }
    if ($null -eq $delta) { return $null }

    $lastStop = if ($null -ne $Handover) { [string]$Handover.recorded_at } else { '' }
    $lastBoundary = if ($null -ne $Handover) { [string]$Handover.active_boundary } else { '' }
    $changedNow = @($delta.user_files)
    $newCommits = @($delta.new_commits)

    $lines = New-Object System.Collections.Generic.List[string]
    if (-not [string]::IsNullOrWhiteSpace($lastStop)) {
        $bn = if (-not [string]::IsNullOrWhiteSpace($lastBoundary)) { " (boundary $lastBoundary)" } else { '' }
        $lines.Add(("Last captured stop: {0}{1}." -f $lastStop, $bn)) | Out-Null
    }
    if ($changedNow.Count -gt 0) {
        $more = if (([int]$delta.user_file_count) -gt $changedNow.Count) { ', +more' } else { '' }
        $lines.Add(("Files changed since (re-computed NOW - may post-date the last stop): {0}{1}." -f ($changedNow -join ', '), $more)) | Out-Null
        $lines.Add('READ those files to recover the true current state (the handover snapshot may predate your latest work), THEN continue.') | Out-Null
    }
    elseif (([int]$delta.managed_file_count) -gt 0) {
        $lines.Add(("No user files changed since the last commit ({0} Specrew-managed scaffolding uncommitted); continue the next lifecycle step." -f $delta.managed_file_count)) | Out-Null
    }
    else {
        $lines.Add('Working tree is clean since the last commit; continue the next lifecycle step.') | Out-Null
    }
    if ($newCommits.Count -gt 0) { $lines.Add(("New commits since the handover: {0}." -f ($newCommits -join ' | '))) | Out-Null }

    [pscustomobject]@{
        last_stop_recorded_at = $lastStop
        last_boundary         = $lastBoundary
        branch                = [string]$delta.branch
        head_short            = [string]$delta.head_short
        changed_user_files    = $changedNow
        user_file_count       = [int]$delta.user_file_count
        managed_file_count    = [int]$delta.managed_file_count
        new_commits           = $newCommits
        directive_text        = ($lines -join ' ')
    }
}
