---
description: "Persist session-state metadata after /speckit.plan"
---

# Sync Plan Boundary State

## Record the arrival (before the advancement gate)

After `/speckit.plan` updates `plan.md`, record the boundary arrival FIRST — the sync mints the
pending crossing and writes `.specrew/runtime/pending-verdict-stop.md`, the controller truth the
verdict stop renders from. This arrival-first order prevents a stop with no artifact:

```powershell
$featureJson = Get-Content -LiteralPath .\.specify\feature.json -Raw -Encoding UTF8 | ConvertFrom-Json
$featureRef = Split-Path -Leaf $featureJson.feature_directory
pwsh -File .\.specify\extensions\specrew-speckit\scripts\sync-boundary-state.ps1 -ProjectPath . -BoundaryType plan -FeatureRef $featureRef
```

If the sync fails, stop and report the exact file-write error before continuing. If the sync is
refused because an earlier crossing is still unapproved (the ratchet), that refusal IS the stop —
surface it and wait for the human; do not work around it.

## Advancement gate (after the arrival is recorded)

The gate BLOCKS until the human's verdict authorizes this crossing:

```powershell
. .\.specify\extensions\specrew-speckit\scripts\shared-governance.ps1
$authorization = Test-SpecrewBoundaryAuthorization -ProjectRoot . -CurrentBoundary 'clarify' -RequestedBoundary 'plan'
if (-not $authorization.Authorized) {
  Write-Output (Write-SpecrewBoundaryAuthorizationDirective -CurrentBoundary $authorization.CurrentBoundary -RequestedBoundary $authorization.RequestedBoundary -DirectiveSentinel $authorization.DirectiveSentinel)
  throw $authorization.Reason
}
```

On a gate block, `.specrew/runtime/pending-verdict-stop.md` is the controller truth: render the
six-section boundary packet from its `Boundary to ask for`, `Human approval phrase`, and
`Marker last line exactly` values, then stop for the human's verdict. Do not infer a marker from
the phase you are in.
