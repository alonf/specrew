# Iteration State: 006

**Schema**: v1
**Current Phase**: implement
**Iteration Status**: executing
**Last Completed Task**: T035 (extracted launch-contract.ps1; full specrew-start suite 11/11 green, byte-behavior-identical)
**Tasks Remaining**: T036-T042 (serial)
**In Progress**: T036 (SessionBootstrapManager calls the shared generator + boundary_enforcement preserve-merge)
**Baseline Ref**: ff52974c64770423a69a4a5d6ac9509bb6aa29ce
**Updated**: 2026-06-09T17:55:00Z

## Execution Summary

- **T035a DONE** (the honest re-baseline): the lead-with-characterization check (before-implement
  instruction #2) FOUND the specrew-start suite does NOT pin the contract -> built
  `tests/integration/launch-contract-characterization.tests.ps1` (9/9 green); split + re-baselined 19->20
  (drift D-010). This is the regression net the T035 extraction is guarded by.
- **T035 DONE** (full specrew-start suite 11/11 green, byte-behavior-identical; lib PSSA 0; specrew-start
  PSSA delta 0 vs HEAD). launch-contract.ps1 created (6 functions, AST-exact); specrew-start dot-sources it
  + the 6 inline defs removed one-at-a-time (parse + T035a green after each cut). The map below records how:
- **T035 extraction map (done):**
  - GOAL: move the contract generator into NEW `scripts/internal/launch-contract.ps1`, dot-sourced by BOTH
    `specrew-start.ps1` (behavior-preserving) AND the bootstrap provider (so the hook calls the SAME
    generator — FR-023, no drift).
  - MOVE these from `specrew-start.ps1`: `Get-StartPrompt` (~L2373-2532), `Get-TeamRosterPromptBlock`
    (L1093), `Get-ProjectStatePromptBlock` (L1216), `Get-BrownfieldDiscoveryPromptBlock` (L1676),
    `Get-DeliveryGuidancePromptBlock` (L2067), `Get-RoutingPlanPromptBlock` (L2245-2271, CONFIRMED a clean
    self-contained formatter). TODO: locate `Get-SpecrewBoundaryPolicyClassMap` (called at L2409) — grep;
    move it too if inline, leave if already in a lib.
  - SAFE-INCREMENTAL mechanism (no broken intermediate): (1) create launch-contract.ps1 with copies;
    (2) dot-source it at the TOP of specrew-start.ps1 (duplicate defs are SAFE — identical code, last def
    wins); (3) delete each inline def, re-running T035a after each; (4) bootstrap provider dot-sources it.
  - VERIFY each step with T035a (`launch-contract-characterization.tests.ps1`) + the specrew-start
    integration suite (`tests/integration/specrew-start-*.ps1`) staying GREEN. Confirm each of the 5
    helpers is a clean formatter (no deep specrew-start-internal deps) before/while moving — routing is
    confirmed clean; the hook passes NULL launcher-only inputs (roster/routing) so their null-paths must be
    self-contained.
- **T036 wiring point (next):** `SessionBootstrapManager.Invoke-SpecrewSessionBootstrap` builds the
  directive via `New-SpecrewBootstrapDirective` (DirectiveEngine). T036 inserts, BEFORE that build: call
  `Get-StartPrompt` (from launch-contract.ps1) with hook-available inputs (ProjectRoot, the resolved
  SessionState/anchor; NULL launcher-only roster/routing/brownfield/delivery — null-safe formatters) →
  write `last-start-prompt.md` (narrow atomic write, NOT Save-StartArtifacts) → ensure `boundary_enforcement`
  via `Get-/Initialize-SpecrewBoundaryEnforcementState` (preserve-merge the anchor). The provider/manager
  must dot-source `launch-contract.ps1` + its external deps (shared-governance for
  `Get-SpecrewBoundaryPolicyClassMap`; coordinator-resume for the resume/recovery blocks). Null roster/routing
  may need guards (Get-TeamRosterPromptBlock/Get-RoutingPlanPromptBlock access props without null checks —
  brownfield/delivery ARE null-safe). Surgery (`Invoke-SpecrewCoordinatorPromptSurgery`) is optional for the
  hook (host-specific; reuse if cheap).
- **THEN (serial):** T036 (manager calls the generator + boundary_enforcement preserve-merge), T037
  (provider injects read-and-follow), T038 (the LOAD-BEARING deployed live-wiring floor — installed-module
  scratch project, evidence_locus: deployed; dev-tree-only = send-back), T039 (enumerate per-host
  injection), T040 (evidence_locus carry), T041 (dormant-SessionEnd cleanup), T042 (docs honesty guard).
- Checkpoint state is validator-GREEN and nothing is broken (extraction not yet started — only the net
  exists). Scope 20/20; the multi-host injection re-tests are the tracked follow-on slice
  (f174-followup-multihost-injection-verification).

## Notes

- Update this file after each task completes.
- Keep task identifiers aligned to plan.md.

<!-- >>> specrew-managed escalation-state >>> -->
## Repair Escalation

- **Status**: inactive
- **Artifact**: (none)
- **Gate**: (none)
- **Failure Count**: 0
- **Current Tier**: efficiency
- **Current Owner**: (none)
- **Locked Out Agents**: (none)
- **Last Escalated**: (none)
- **Resolved At**: (none)
- **Notes**: (none)
<!-- <<< specrew-managed escalation-state <<< -->