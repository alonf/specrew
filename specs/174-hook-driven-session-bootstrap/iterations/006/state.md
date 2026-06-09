# Iteration State: 006

**Schema**: v1
**Current Phase**: implement
**Iteration Status**: executing
**Last Completed Task**: T035a (launch-contract characterization floor — 9/9 assertions green)
**Tasks Remaining**: T035, T036-T042 (serial)
**In Progress**: T035 (extraction MAPPED + net-ready; not yet started — see the Execution Summary map for the resume plan)
**Baseline Ref**: ff52974c64770423a69a4a5d6ac9509bb6aa29ce
**Updated**: 2026-06-09T17:30:00Z

## Execution Summary

- **T035a DONE** (the honest re-baseline): the lead-with-characterization check (before-implement
  instruction #2) FOUND the specrew-start suite does NOT pin the contract -> built
  `tests/integration/launch-contract-characterization.tests.ps1` (9/9 green); split + re-baselined 19->20
  (drift D-010). This is the regression net the T035 extraction is guarded by.
- **T035 IN-PROGRESS — extraction map (resume here):**
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