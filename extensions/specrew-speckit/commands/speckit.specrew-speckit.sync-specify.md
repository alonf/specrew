---
description: "Persist session-state metadata after /speckit.specify"
---

# Sync Specify Boundary State

## Workshop readiness gate (before the spec work)

The design workshop is MANDATORY — the specify boundary cannot advance without its lens records
(`lens-applicability.json` with per-lens human confirmation). Deterministic: a missing or unworked
workshop throws here, BEFORE the spec work begins (Feature 185):

```powershell
. .\.specify\extensions\specrew-speckit\scripts\shared-governance.ps1
$workshopRecords = Test-SpecrewWorkshopRecordsPresent -ProjectRoot .
if (-not $workshopRecords.Present) {
  throw ("SPECREW WORKSHOP GATE: {0} Run the specrew-design-workshop skill and work the lenses WITH the human, then retry." -f $workshopRecords.Reason)
}
```

## Record the arrival (before the advancement gate)

After `/speckit.specify` writes `.specify/feature.json` and the active spec artifact, record the
boundary arrival FIRST. At a first boundary this sync is what mints the pending crossing and writes
`.specrew/runtime/pending-verdict-stop.md` — the controller truth the verdict stop renders from
(DRIFT-198-I011-012: gating before this sync made FR-066's arrival state unreachable and left the
stop with no artifact, the marker-invention precondition):

```powershell
$featureJson = Get-Content -LiteralPath .\.specify\feature.json -Raw -Encoding UTF8 | ConvertFrom-Json
$featureRef = Split-Path -Leaf $featureJson.feature_directory
pwsh -File .\.specify\extensions\specrew-speckit\scripts\sync-boundary-state.ps1 -ProjectPath . -BoundaryType specify -FeatureRef $featureRef
```

If the sync fails, stop and report the exact file-write error before continuing. If the sync is
refused because an earlier crossing is still unapproved (the ratchet), that refusal IS the stop —
surface it and wait for the human; do not work around it.

## Advancement gate (after the arrival is recorded)

The gate BLOCKS until the human's verdict authorizes the crossing. Blocking is correct — and it
runs AFTER the arrival sync so the stop always has controller truth to render:

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

On a gate block, `.specrew/runtime/pending-verdict-stop.md` is the controller truth: render the
six-section boundary packet from its `Boundary to ask for`, `Human approval phrase`, and
`Marker last line exactly` values, then stop for the human's verdict. Do not infer a marker from
the phase you are in.
