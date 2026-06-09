# Iteration State: 006

**Schema**: v1
**Current Phase**: implement
**Iteration Status**: executing
**Last Completed Task**: T041 (deleted dormant SessionEnd code; 3 files removed, bootstrap tests 4/4 + rolling round-trip green post-deletion, PSSA 0)
**Tasks Remaining**: T038, T039, T042 (T038 = the LOAD-BEARING deployed floor)
**In Progress**: T038 (DEPLOYED live-wiring floor — installed-module scratch project, evidence_locus: deployed; dev-tree-only = send-back)
**Baseline Ref**: ff52974c64770423a69a4a5d6ac9509bb6aa29ce
**Updated**: 2026-06-09T22:00:00Z

## Execution Summary

- **T035a DONE** (the honest re-baseline): the lead-with-characterization check (before-implement
  instruction #2) FOUND the specrew-start suite does NOT pin the contract -> built
  `tests/integration/launch-contract-characterization.tests.ps1` (9/9 green); split + re-baselined 19->20
  (drift D-010). This is the regression net the T035 extraction is guarded by.
- **T035 DONE** (full specrew-start suite 11/11 green, byte-behavior-identical; lib PSSA 0; specrew-start
  PSSA delta 0 vs HEAD). launch-contract.ps1 created (6 functions, AST-exact); specrew-start dot-sources it
  and the 6 inline defs were removed one-at-a-time (parse + T035a green after each cut). The map records how:
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
- **T036 DONE** (manager calls the generator + boundary_enforcement preserve-merge; bootstrap tests 4/4 +
  real provider smoke green; provider+manager PSSA 0). What landed:
  - `SessionBootstrapManager.ps1` NEW `Write-SpecrewLaunchContractArtifact` — calls `Get-StartPrompt` with
    the hook's project/session inputs + EMPTY-SHAPED launcher-only stubs (NOT null: Get-RoutingPlanPromptBlock
    does `$RoutingPlan.roles.GetEnumerator()` which throws on a null `.roles`; shaped-empty keeps the SHARED
    generator on its self-contained path untouched) → atomic-writes `.specrew/last-start-prompt.md` (43.7K, all
    7 invariant contract markers) → ensures `boundary_enforcement` via Get-/Initialize- (preserve-merge: init
    ONLY when `.State` is null, never clobber an existing block).
  - Wiring is **(b1)**: the function LIVES in the manager (plan's file assignment) but is INVOKED by the
    PROVIDER (adapter) right after `Invoke-SpecrewSessionBootstrap` returns — NOT inside the pure
    classification function. Rationale: `coordinator-resume.ps1` + `shared-governance.ps1` set
    `Set-StrictMode -Version Latest` at file scope; routing the write through the classification fn would push
    StrictMode-Latest into the 3 existing manager unit tests and risk spurious failures. (b1) keeps
    `Invoke-SpecrewSessionBootstrap` + its 3 tests UNCHANGED and still green; the StrictMode dep tree is
    isolated to the provider path + the new `LaunchContractWrite.Tests.ps1`.
  - Provider dot-sources the 3 deps via DERIVE-FROM-$bdir (`$internalDir = Split-Path $bdir`;
    `$moduleRoot = Split-Path (Split-Path $internalDir)`): launch-contract.ps1 + coordinator-resume.ps1 from
    scripts/internal; shared-governance.ps1 from extensions/specrew-speckit/scripts. ONE resolution contract
    (the proven bootstrap-component 3-tier chain) for T038 to validate.
- **T036 findings (the FileList audit the advisor mandated before any T038 infra):**
  1. **D-009 sub-cause #1 REFUTED:** all 11 `scripts/internal/bootstrap/*` components ARE in the FileList
     (psd1 215-225). The iter-5 D-009 failure was RUNTIME RESOLUTION (tier-3: `Get-Module -ListAvailable` in
     the host-spawned hook child, SPECREW_MODULE_PATH absent), NOT a missing-from-manifest problem. That tier
     is what T038 must settle. No new-scope split.
  2. **launch-contract.ps1 was NOT in the FileList** (the directional blind-spot, exactly as flagged) → ADDED
     (manifest now 279 entries, Test-ModuleManifest OK). The transitive closure is EXACTLY 3 files (empirically:
     dot-source the 3 → zero further unresolved); coordinator-resume + shared-governance already ship.
  3. **Real production bug caught by the unit floor BEFORE T038:** the hook anchor (`Get-SpecrewSessionAnchor`)
     and the generator's resume block use DIFFERENT field names — anchor `boundary`/`iteration`, no `task_id`;
     generator `boundary_type`/`iteration_number`/`task_id`. Passing the raw anchor throws on THREE fields under
     StrictMode → provider fail-open → silent no-contract = the exact D-009 shape. FIXED by mapping the anchor →
     generator shape at the seam via `Get-SpecrewProp` (StrictMode-safe). `task_id` degrades to null (the anchor
     never captured it; the handover is the real resume signal) — acceptable, noted.
- **T041 note:** `SessionEndHandoverManager.ps1` is in the FileList (psd1 223). Its deletion (T041) must ALSO
  remove that manifest line + the dormant SessionEnd dot-source.
- **T037 DONE** (provider injects the read-and-follow DRIVE; bootstrap tests 4/4 + provider smoke green;
  provider+manager PSSA 0). What landed:
  - The manager populates `required_reads = @('.specrew/last-start-prompt.md', '.specrew/start-context.json')`
    on the directive (the DirectiveEngine already had the param — no engine change). The provider's
    `Format-BootstrapDirective` now leads with a DRIVE instruction: "READ {contract} + {state} BEFORE acting;
    follow the governed lifecycle EXACTLY; do NOT bypass clarify/governance gates or drive from raw Spec Kit."
  - **Interpretation (maintainer confirms at review-signoff):** "replace the iter-5 thin orient/menu directive"
    was read as "ADD the read-and-follow DRIVE on top of the PRESERVED FR-002 Resume/New/Pick menu + FR-004
    render-first prose" — NOT "remove the menu" (which would violate FR-002, which mandates the menu
    semantics). Smoke confirms the DRIVE line + the menu + the render-first framing all render together.
  - The provider now runs `Format-BootstrapDirective` + the manager under StrictMode-Latest (T036 dot-sourced
    the strict-setting deps). The no-handover path is smoke-verified strict-clean. The handover-render path is
    VERIFIED strict-safe (advisor twin-bug check, not deferred): `ConvertFrom-SpecrewHandoverFile` returns a
    LITERAL pscustomobject with schema/source/from_host/recorded_at/active_feature/active_boundary/sections —
    ALL consumed fields ALWAYS present (null-valued at worst; StrictMode throws only on ABSENT props). Unlike
    the anchor there is NO name mismatch (the manager + Format use the parser's exact field names). EMPIRICALLY
    confirmed: a seeded-handover probe exercised Get-SpecrewRollingHandover, Test-SpecrewHandoverBodyPlaceholder,
    the handoverDirective construction, and Format's `.sections.Keys` loop under `Set-StrictMode -Version Latest`
    → clean (placeholder=False, sections=2, rendered=2). T038 still exercises it end-to-end in the deployed run.
- **T040 DONE** (evidence_locus carry; right-sized per advisor — no shared-validator cascade, no multi-home
  charter sync). What landed:
  - **In-branch (light):** a doc-comment in the shipped schema generator
    `extensions/specrew-speckit/scripts/run-hardening-gate.ps1` (at the `RuntimeEvidenceStatus` cell) lifting
    the evidence_locus convention out of iteration-local prose: at review the cell records the evidence + its
    LOCUS (`deployed` vs `dev-tree`), and the review REFUSES "delivered-live" on dev-tree-only evidence. The
    cell is FREE-TEXT + PRESERVED across re-runs (no enum, no 10th column → zero cascade across the ~60 existing
    hardening-gate.md files). Comment-only: PSSA delta 0, parse 0.
  - **The real deliverable (to MAIN, NOT this branch):** the Proposal-145 reviewer-family candidate is DRAFTED
    at `specs/174-hook-driven-session-bootstrap/iterations/006/proposal-145-evidence-locus-candidate.md`
    (iteration workspace, clearly labeled DRAFT — does NOT contaminate the feature branch's proposals/ tree).
    It carries the generalized rule: a structured `evidence_locus` field on the 145 claim ledger + the
    structured-reviewer refusal of delivered-live on dev-tree evidence, reconciled INTO Proposal 145 on the
    #2216 rebase. **CARRY for closeout:** promote this draft to `proposals/` on `main` as a separate governance
    commit (proposals-go-to-main discipline) — do NOT commit it on the feature branch.
  - Rationale (advisor): coded enforcement in the shared validator would itself be an unevidenced
    "delivered-live" governance claim — so it is deferred to the 145 family, not hand-coded now.
- **T041 DONE** (dormant SessionEnd cleanup; deletion proven safe post-deletion). What landed:
  - DELETED (git rm): `scripts/internal/bootstrap/SessionEndHandoverManager.ps1` (the dormant
    `Invoke-SpecrewSessionEndHandover`), `tests/bootstrap/SessionEndHandover.Tests.ps1`,
    `tests/bootstrap/HandoverStore.Tests.ps1` (tested ONLY the timestamped funcs — zero rolling coverage lost;
    the rolling model is covered by AgentAuthoredHandover.Tests).
  - REMOVED from HandoverStore.ps1 (AST-offset surgery, in-memory re-parse verified): the timestamped
    `Write-SpecrewHandover` + `Get-SpecrewHandover`. KEPT `Get-SpecrewHandoverSectionOrder` (still used by the
    rolling writer L120/L196), ConvertFrom-SpecrewHandoverFile, and all rolling funcs.
  - FIXED dangling refs: Specrew.psd1 FileList entry removed; HandoverStore.ps1 header rewritten (the
    timestamped path is now documented as SUPERSEDED, the SessionEndHandoverManager reference removed);
    ValidationEngine.ps1 param comment `Get-SpecrewHandover` → `Get-SpecrewRollingHandover`; the inaccurate
    "reuse SessionEnd write-logic" design-record phrase corrected in iter-004/plan.md T025 (retro-flagged).
  - SAFETY PROVEN: all 4 remaining bootstrap tests green post-deletion, including AgentAuthoredHandover (the
    rolling Stop round-trip STILL fires) — exactly the user's deletion-safety criterion. PSSA 0. The kept
    `Get-SpecrewHandoverSectionOrder` orphan-check confirmed it is shared with the rolling writer.
  - Historical iter-002 artifacts (review-report.yml/code-map.md/coverage-evidence.md) still reference the
    deleted test files — LEFT UNCHANGED (immutable closed-iteration history; they accurately record what
    existed then). The `.squad/decisions.md` follow-on `f174-followup-remove-dormant-sessionend-code` is now
    resolved by this task.
- **NEXT — T038, the LOAD-BEARING deployed floor (the entire iteration rides on it).** Pack the JUST-BUILT
  dev tree as the module FROM the updated FileList (NEVER published 0.33.0-beta1 — it predates launch-contract.ps1
  + the inline specrew-start), install it, create a REAL scratch project, and assert the 3-part round-trip via
  `Get-Module -ListAvailable Specrew` tier-3 resolution (SPECREW_MODULE_PATH UNSET — the host-spawned-child path
  that failed in iter-5). evidence_locus: deployed. A red T038 reported = the methodology working; a
  green-via-dev-tree-fallback = the iter-5 D-009 failure repeating. Then T039 (per-host injection enumerate) →
  T042 (docs honesty guard). Stop at review-signoff.
- Scope 20/20; the multi-host injection re-tests are the tracked follow-on slice
  (f174-followup-multihost-injection-verification). specrew-start integration suite unaffected by T036 (no
  changes to specrew-start.ps1 / launch-contract.ps1) — re-run as the final regression gate before review-signoff.

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