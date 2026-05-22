---
description: "Persist session-state metadata after /speckit.plan"
---

# Sync Plan Boundary State

## Boundary authorization gate

Before any boundary-advancing work, run:

```powershell
. .\.specify\extensions\specrew-speckit\scripts\shared-governance.ps1
$authorization = Test-SpecrewBoundaryAuthorization -ProjectRoot . -CurrentBoundary 'clarify' -RequestedBoundary 'plan'
if (-not $authorization.Authorized) {
  Write-Output (Write-SpecrewBoundaryAuthorizationDirective -CurrentBoundary $authorization.CurrentBoundary -RequestedBoundary $authorization.RequestedBoundary -DirectiveSentinel $authorization.DirectiveSentinel)
  throw $authorization.Reason
}
```

After `/speckit.plan` updates `plan.md`, run:

```powershell
$featureJson = Get-Content -LiteralPath .\.specify\feature.json -Raw -Encoding UTF8 | ConvertFrom-Json
$featureRef = Split-Path -Leaf $featureJson.feature_directory
pwsh -File .\.specify\extensions\specrew-speckit\scripts\sync-boundary-state.ps1 -ProjectPath . -BoundaryType plan -FeatureRef $featureRef
```

If the sync fails, stop and report the exact file-write error before continuing.
