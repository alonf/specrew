---
description: "Persist session-state metadata after /speckit.specify"
---

# Sync Specify Boundary State

## Boundary authorization gate

Before any boundary-advancing work, run:

```powershell
. .\.specify\extensions\specrew-speckit\scripts\shared-governance.ps1
$contextState = Get-SpecrewStartContextState -ProjectRoot .
$currentBoundary = if ($contextState.Context.Contains('session_state') -and $null -ne $contextState.Context['session_state'] -and -not [string]::IsNullOrWhiteSpace([string]$contextState.Context['session_state']['boundary_type'])) {
  [string]$contextState.Context['session_state']['boundary_type']
}
else {
  'specify'
}
$authorization = Test-SpecrewBoundaryAuthorization -ProjectRoot . -CurrentBoundary $currentBoundary -RequestedBoundary 'specify'
if (-not $authorization.Authorized) {
  Write-Output (Write-SpecrewBoundaryAuthorizationDirective -CurrentBoundary $authorization.CurrentBoundary -RequestedBoundary $authorization.RequestedBoundary -DirectiveSentinel $authorization.DirectiveSentinel)
  throw $authorization.Reason
}
```

After `/speckit.specify` writes `.specify/feature.json` and the active spec artifact, run:

```powershell
$featureJson = Get-Content -LiteralPath .\.specify\feature.json -Raw -Encoding UTF8 | ConvertFrom-Json
$featureRef = Split-Path -Leaf $featureJson.feature_directory
pwsh -File .\.specify\extensions\specrew-speckit\scripts\sync-boundary-state.ps1 -ProjectPath . -BoundaryType specify -FeatureRef $featureRef
```

If the sync fails, stop and report the exact file-write error before continuing.
