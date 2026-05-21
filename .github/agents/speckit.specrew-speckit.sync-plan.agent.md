---
description: Persist session-state metadata after /speckit.plan
---


<!-- Extension: specrew-speckit -->
<!-- Config: .specify/extensions/specrew-speckit/ -->
# Sync Plan Boundary State

After `/speckit.plan` updates `plan.md`, run:

```powershell
$featureJson = Get-Content -LiteralPath .\.specify\feature.json -Raw -Encoding UTF8 | ConvertFrom-Json
$featureRef = Split-Path -Leaf $featureJson.feature_directory
pwsh -File .\.specify\extensions\specrew-speckit\scripts\sync-boundary-state.ps1 -ProjectPath . -BoundaryType plan -FeatureRef $featureRef
```

If the sync fails, stop and report the exact file-write error before continuing.