<#
.SYNOPSIS
  Validate the session anchor against current project state and clear it when stale.
.DESCRIPTION
  Engine (IDesign). Per the co-designed engine call-rule, ValidationEngine MAY call accessors
  directly (the reads are predictable and the underlying data - git history, the project tree -
  is large), so it composes SessionStateAccessor + ProjectMetadataAccessor. It returns a verdict
  with an explicit cleared_reason and human-readable findings so the cleared/full path is
  observable (security d2, ui-ux d3). An anchor is valid ONLY when active, portable,
  project-local, and not merged. Feature 174 (FR-013, FR-015, FR-017, SC-004).
  Depends on SessionStateAccessor.ps1 + ProjectMetadataAccessor.ps1 (co-loaded by the module).
.OUTPUTS
  [pscustomobject] { valid, cleared_reason, findings, anchor }
    cleared_reason: $null | 'non-portable' | 'missing' | 'merged'
#>

function Test-SpecrewAnchorValidity {
    [CmdletBinding()]
    [OutputType([pscustomobject])]
    param(
        [Parameter(Mandatory)][string] $StatePath,
        [Parameter(Mandatory)][string] $ProjectRoot,
        [Parameter()][string] $BaseBranch = 'main'
    )

    $anchor = Get-SpecrewSessionAnchor -StatePath $StatePath
    if ($null -eq $anchor) {
        return [pscustomobject]@{ valid = $false; cleared_reason = $null; findings = @('no active session anchor'); anchor = $null }
    }
    if (-not $anchor.active) {
        return [pscustomobject]@{ valid = $false; cleared_reason = $null; findings = @('anchor is not active'); anchor = $anchor }
    }

    # FR-015: a non-portable absolute path (different worktree) is never trusted.
    if (-not (Test-SpecrewAnchorPortable -Anchor $anchor -ProjectRoot $ProjectRoot)) {
        return [pscustomobject]@{
            valid = $false; cleared_reason = 'non-portable'
            findings = @("anchor path is non-portable (different worktree): $($anchor.feature_path)"); anchor = $anchor
        }
    }

    # FR-013: re-resolve project-local + git merged-status.
    $res = Get-SpecrewFeatureResumable -ProjectRoot $ProjectRoot -FeatureRef $anchor.feature_ref -BaseBranch $BaseBranch
    if (-not $res.present) {
        return [pscustomobject]@{
            valid = $false; cleared_reason = 'missing'
            findings = @("feature not present in this project: $($anchor.feature_ref)"); anchor = $anchor
        }
    }
    if ($res.merged) {
        return [pscustomobject]@{
            valid = $false; cleared_reason = 'merged'
            findings = @("feature is already merged: $($anchor.feature_ref)"); anchor = $anchor
        }
    }

    return [pscustomobject]@{ valid = $true; cleared_reason = $null; findings = @(); anchor = $anchor }
}
