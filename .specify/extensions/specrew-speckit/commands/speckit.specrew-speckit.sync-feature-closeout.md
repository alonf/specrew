---
description: "Persist session-state metadata after feature-closeout boundary work is committed"
---

# Sync Feature Closeout Boundary State

## Boundary authorization gate

Before any boundary-advancing work, run:

```powershell
. .\.specify\extensions\specrew-speckit\scripts\shared-governance.ps1
$authorization = Test-SpecrewBoundaryAuthorization -ProjectRoot . -CurrentBoundary 'iteration-closeout' -RequestedBoundary 'feature-closeout'
if (-not $authorization.Authorized) {
  Write-Output (Write-SpecrewBoundaryAuthorizationDirective -CurrentBoundary $authorization.CurrentBoundary -RequestedBoundary $authorization.RequestedBoundary -DirectiveSentinel $authorization.DirectiveSentinel)
  throw $authorization.Reason
}
```

After feature-closeout artifacts are committed to the feature branch, run:

```powershell
$featureJson = Get-Content -LiteralPath .\.specify\feature.json -Raw -Encoding UTF8 | ConvertFrom-Json
$featureRef = Split-Path -Leaf $featureJson.feature_directory
$iterationsRoot = Join-Path $featureJson.feature_directory 'iterations'
$iterationNumber = if (Test-Path -LiteralPath $iterationsRoot -PathType Container) {
    @(Get-ChildItem -LiteralPath $iterationsRoot -Directory | Sort-Object Name -Descending | Select-Object -First 1)[0].Name
}
pwsh -File .\.specify\extensions\specrew-speckit\scripts\sync-boundary-state.ps1 -ProjectPath . -BoundaryType feature-closeout -FeatureRef $featureRef -IterationNumber $iterationNumber
```

If the sync fails, stop and report the exact file-write error before continuing.

This command replaces inline PowerShell invocation of sync-boundary-state.ps1 for the feature-closeout boundary. Use this command (not inline PowerShell, and not manual state-file edits) so the canonical sync logic fires correctly and state files end up in the canonical post-boundary state.
