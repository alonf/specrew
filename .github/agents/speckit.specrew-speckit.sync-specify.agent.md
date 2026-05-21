---
description: Persist session-state metadata after /speckit.specify
---


<!-- Extension: specrew-speckit -->
<!-- Config: .specify/extensions/specrew-speckit/ -->
# Sync Specify Boundary State

After `/speckit.specify` writes `.specify/feature.json` and the active spec artifact, run:

```powershell
$featureJson = Get-Content -LiteralPath .\.specify\feature.json -Raw -Encoding UTF8 | ConvertFrom-Json
$featureRef = Split-Path -Leaf $featureJson.feature_directory
pwsh -File .\.specify\extensions\specrew-speckit\scripts\sync-boundary-state.ps1 -ProjectPath . -BoundaryType specify -FeatureRef $featureRef
```

If the sync fails, stop and report the exact file-write error before continuing.