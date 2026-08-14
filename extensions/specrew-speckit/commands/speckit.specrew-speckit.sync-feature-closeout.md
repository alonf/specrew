---
description: "Persist session-state metadata after feature-closeout boundary work is committed"
---

# Sync Feature Closeout Boundary State

## Record the arrival (before the advancement gate)

After feature-closeout artifacts are committed to the feature branch, record the boundary arrival
FIRST — the sync mints the pending crossing and writes `.specrew/runtime/pending-verdict-stop.md`,
the controller truth the verdict stop renders from. This arrival-first order prevents a stop with
no artifact:

```powershell
$featureJson = Get-Content -LiteralPath .\.specify\feature.json -Raw -Encoding UTF8 | ConvertFrom-Json
$featureRef = Split-Path -Leaf $featureJson.feature_directory
$iterationsRoot = Join-Path $featureJson.feature_directory 'iterations'
$iterationNumber = if (Test-Path -LiteralPath $iterationsRoot -PathType Container) {
    @(Get-ChildItem -LiteralPath $iterationsRoot -Directory | Sort-Object Name -Descending | Select-Object -First 1)[0].Name
}
pwsh -File .\.specify\extensions\specrew-speckit\scripts\sync-boundary-state.ps1 -ProjectPath . -BoundaryType feature-closeout -FeatureRef $featureRef -IterationNumber $iterationNumber
```

If the sync fails, stop and report the exact file-write error before continuing. If the sync is
refused because an earlier crossing is still unapproved (the ratchet), that refusal IS the stop —
surface it and wait for the human; do not work around it.

## Advancement gate (after the arrival is recorded)

The gate BLOCKS until the human's verdict authorizes this crossing:

```powershell
. .\.specify\extensions\specrew-speckit\scripts\shared-governance.ps1
$authorization = Test-SpecrewBoundaryAuthorization -ProjectRoot . -CurrentBoundary 'iteration-closeout' -RequestedBoundary 'feature-closeout'
if (-not $authorization.Authorized) {
  Write-Output (Write-SpecrewBoundaryAuthorizationDirective -CurrentBoundary $authorization.CurrentBoundary -RequestedBoundary $authorization.RequestedBoundary -DirectiveSentinel $authorization.DirectiveSentinel)
  throw $authorization.Reason
}
```

On a gate block, `.specrew/runtime/pending-verdict-stop.md` is the controller truth: render the
six-section boundary packet from its `Boundary to ask for`, `Human approval phrase`, and
`Marker last line exactly` values, then stop for the human's verdict. Do not infer a marker from
the phase you are in.

This command replaces inline PowerShell invocation of sync-boundary-state.ps1 for the feature-closeout boundary. Use this command (not inline PowerShell, and not manual state-file edits) so the canonical sync logic fires correctly and state files end up in the canonical post-boundary state.
