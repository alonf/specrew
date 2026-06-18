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

function Test-SpecrewHandoverValidity {
    # Handover recency is necessary but NOT sufficient (architecture-core d2): a fresh handover
    # must still validate against current project state before it is treated as resume truth.
    # Composes ProjectMetadataAccessor (Get-SpecrewFeatureResumable). Feature 174 (FR-010, FR-017).
    [CmdletBinding()]
    [OutputType([pscustomobject])]
    param(
        [Parameter()][AllowNull()]$Handover,            # from Get-SpecrewRollingHandover, or $null
        [Parameter(Mandatory)][string] $ProjectRoot,
        [Parameter()][string] $BaseBranch = 'main',
        [Parameter()][AllowNull()][string] $ExpectedFeatureRef
    )
    if ($null -eq $Handover) {
        return [pscustomobject]@{ valid = $false; reason = $null; findings = @('no handover present') }
    }
    if (-not [bool]$Handover.fresh) {
        return [pscustomobject]@{ valid = $false; reason = 'stale'; findings = @("handover older than the freshness window: $($Handover.recorded_at)") }
    }
    $feature = $Handover.active_feature
    if ([string]::IsNullOrWhiteSpace($feature)) {
        return [pscustomobject]@{ valid = $false; reason = 'no-feature'; findings = @('handover names no active feature') }
    }
    if (-not [string]::IsNullOrWhiteSpace($ExpectedFeatureRef) -and $feature -ne $ExpectedFeatureRef) {
        return [pscustomobject]@{
            valid = $false
            reason = 'feature-mismatch'
            findings = @("handover feature '$feature' does not match the current active feature '$ExpectedFeatureRef'; ignored the stale handover")
        }
    }
    $res = Get-SpecrewFeatureResumable -ProjectRoot $ProjectRoot -FeatureRef $feature -BaseBranch $BaseBranch
    if (-not $res.present) {
        return [pscustomobject]@{ valid = $false; reason = 'missing'; findings = @("handover feature not present: $feature") }
    }
    if ($res.merged) {
        return [pscustomobject]@{ valid = $false; reason = 'merged'; findings = @("handover feature already merged: $feature") }
    }
    return [pscustomobject]@{ valid = $true; reason = $null; findings = @() }
}
