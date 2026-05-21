---
description: Persist session-state metadata after /speckit.clarify
---


<!-- Extension: specrew-speckit -->
<!-- Config: .specify/extensions/specrew-speckit/ -->
# Sync Clarify Boundary State

After `/speckit.clarify` updates the active spec, run:

```powershell
$featureJson = Get-Content -LiteralPath .\.specify\feature.json -Raw -Encoding UTF8 | ConvertFrom-Json
$featureRef = Split-Path -Leaf $featureJson.feature_directory
pwsh -File .\.specify\extensions\specrew-speckit\scripts\sync-boundary-state.ps1 -ProjectPath . -BoundaryType clarify -FeatureRef $featureRef
```

If the sync fails, stop and report the exact file-write error before continuing.