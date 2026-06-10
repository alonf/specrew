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
