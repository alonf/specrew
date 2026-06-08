<#
.SYNOPSIS
  Decide the bootstrap mode (full | welcome-back | cleared-anchor) from validated state.
.DESCRIPTION
  Stable, PURE engine (IDesign): no filesystem, git, or accessor calls - the caller passes
  the already-validated state in. This is the handover-first, two-stage classification from
  architecture-core decision 2; iteration 001 implements the anchor stage (handover stage is
  added in iteration 002, T010). Keeping this pure is what makes every mode path unit-testable
  (observability decision 2). Feature 174 (FR-001, FR-017).
.OUTPUTS
  [pscustomobject] { mode, reason }
    mode: 'full' | 'welcome-back' | 'cleared-anchor'
#>
function Resolve-SpecrewBootstrapMode {
    [CmdletBinding()]
    [OutputType([pscustomobject])]
    param(
        # True when the session anchor resolved project-local, active, fresh, not merged/closed.
        [Parameter(Mandatory)][bool] $AnchorValid,
        # Non-null reason when an anchor was present but cleared (merged|closed|non-portable|mismatch).
        [Parameter()][string] $AnchorClearedReason,
        # Iteration 002 adds the handover-first stage; default false keeps the anchor-only path.
        [Parameter()][bool] $HandoverValid = $false
    )

    if ($HandoverValid -or $AnchorValid) {
        return [pscustomobject]@{ mode = 'welcome-back'; reason = $null }
    }
    if (-not [string]::IsNullOrWhiteSpace($AnchorClearedReason)) {
        return [pscustomobject]@{ mode = 'cleared-anchor'; reason = "cleared a stale anchor: $AnchorClearedReason" }
    }
    return [pscustomobject]@{ mode = 'full'; reason = 'no valid active session' }
}
