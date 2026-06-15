# Iteration State: 006

**Schema**: v1
**Current Phase**: CLOSED (honestly-qualified) — parity deferred to iteration 007
**Iteration Status**: complete
**Last Completed Task**: T042 reached — but review-signoff SENT BACK (parity DISPROVEN); iter-6 closes honestly-qualified: the T035 generator extraction is KEPT (byte-identical), hook-parity is DEFERRED to iteration 007 (see "Review-Signoff SEND-BACK" below)
**Tasks Remaining**: (none in iter-6) — the parity rework is iteration 007 (T043–T047)
**In Progress**: (none) — iteration 007 opened
**Baseline Ref**: ff52974c64770423a69a4a5d6ac9509bb6aa29ce
**Updated**: 2026-06-09T23:00:00Z

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
- **T038 DONE - the LOAD-BEARING DEPLOYED floor is GREEN (evidence_locus: DEPLOYED).** `tests/integration/
  deployed-bootstrap-floor.tests.ps1` packs the dev tree FROM THE FILELIST into a temp module, isolates the
  child's PSModulePath to ONLY the packed module + `$PSHOME/Modules`, and asserts the full 3-part round-trip in
  a REAL installed-module scratch project (git repo on a feature branch) under tier-3 resolution
  (`Get-Module -ListAvailable`, SPECREW_MODULE_PATH UNSET, provider copied to a NON-co-located dir so
  `$PSScriptRoot/bootstrap` misses):
  - discovery-first probe: tier-3 resolves the PACKED module (not the published one);
  - Part 1: deployed SessionStart wrote the full contract (4 invariant markers) + boundary_enforcement on disk;
  - Part 2a: deployed Stop handover provider RESOLVED (tier-3, no PROVIDER_FAILED);
  - Part 2b: the working turn authored a rich handover body via the module's Write-SpecrewHandoverContext;
  - Part 3: a fresh deployed resume READ + SURFACED the authored handover. **The D-009 failure does NOT recur.**
  - **Version-collision DEFUSE (advisor catch, the trap that would have inverted the methodology):** the
    published 0.33.0-beta1 is installed at `...OneDrive/Documents/PowerShell/Modules/Specrew/0.33.0` - SAME
    ModuleVersion as the dev pack - so the tier-3 `Sort -Desc | Select -First 1` could resolve the published
    (launch-contract-less) module = a PROVIDER_FAILED that LOOKS like the finding but is the stale-install
    trap. Defused by PSModulePath isolation + a discovery-first assertion. The first run's RED was exactly this
    (isolation leaked via pwsh's startup re-add of the user scope) - fixed by setting PSModulePath IN the child
    post-startup. A later RED was a TEST-ASSERTION bug (rejecting a partially-authored body that legitimately
    keeps placeholders for unfilled sections) - Part 3 independently proved the body authored + surfaced, so
    the fix corrected the wrong expectation, NOT papered a real failure.
  - **SCOPE HONESTY (evidence_locus discipline applied to T038's OWN claim):** this floor is PROVIDER-DIRECT
    under tier-3 (the D-009 crux: component resolution + on-disk writes). It does NOT drive the full host ->
    SpecrewHookDispatcher -> refocus-scopes.json -> provider routing. The claim is "provider-direct deployed
    tier-3 round-trip," never "the full deployed hook chain." (Advisor-blessed scoped-honest green.)
- **T039 DONE** (per-host injection enumerate). Wrote `specs/174-hook-driven-session-bootstrap/iterations/006/
  injection-matrix.md`: the two-part model (host-agnostic on-disk writes auto-proven by T038 vs per-host
  injection-reaches-model manual). Matrix: **Claude = PARITY** (plumbing GREEN + injection-reaches-model
  PROVEN by direct observation this session); **codex/copilot/cursor = plumbing-ready but injection
  UNVERIFIED -> specrew start fallback** (the confounded Codex run is exactly why this can't be auto-claimed);
  **Antigravity = no hook -> specrew start**. The codex/copilot/cursor re-tests are the EXPLICIT tracked
  follow-on `f174-followup-multihost-injection-verification` (NOT silently dropped). Honors honesty guard (a):
  never all-host parity on Claude-only evidence.
- **T042 DONE** (docs repositioned with the honesty guard; getting-started.md markdownlint clean). Rewrote the
  "Hook-driven bootstrap (Feature 174)" section in `docs/getting-started.md` which had OVERCLAIMED ("auto-
  bootstraps on ANY host launch", "the hook is now the primary bootstrap", listing all four hosts as
  hook-driven). Now: Claude driving is PROVEN end-to-end; codex/copilot/cursor are plumbing-ready but
  injection-UNVERIFIED -> use `specrew start` until confirmed; Antigravity has NO hook -> `specrew start`;
  and `specrew start` is repositioned as the cross-host driver + host-selection + the reliable fallback (NOT a
  legacy compatibility shim). Swept docs/ for residual overclaim phrases - none remain (user-guide.md has no
  F-174 section; release-notes are immutable history).
- **ITERATION 006 IMPLEMENT COMPLETE — all tasks T035a, T035, T036, T037, T040, T041, T038, T039, T042 DONE
  (20/20 SP).** REMAINING before the review-signoff stop: re-run the specrew-start integration suite as the
  final behavior-preserving regression gate (no changes to specrew-start.ps1/launch-contract.ps1 since T035's
  11/11, but it is the contract for the cross-host driver). Then STOP at review-signoff and render the Rule 46
  packet for the maintainer's verdict. CARRIES for the review-signoff/closeout packet: (1) promote the
  Proposal-145 candidate draft to `proposals/` on MAIN (separate governance commit, not the feature branch);
  (2) the maintainer's on-Claude SC-008 validation of the iter-6 read-and-follow content (this repo's deployed
  hook is the STALE published module until the dev tree is installed - the stale-install trap); (3) the
  f174-followup-multihost-injection-verification slice delivers the real multi-host parity.
- Scope 20/20; the multi-host injection re-tests are the tracked follow-on slice
  (f174-followup-multihost-injection-verification). specrew-start integration suite unaffected by T036 (no
  changes to specrew-start.ps1 / launch-contract.ps1) — re-run as the final regression gate before review-signoff.

## Review-Signoff SEND-BACK (2026-06-10) — parity DISPROVEN

Iteration 006 was SENT BACK at review-signoff (maintainer verdict). A side-by-side (same prompt, hook vs
`specrew start`) disproved parity: with `specrew start` the agent's FIRST act is to READ last-start-prompt.md
and render the full Crew-coordinator contract (user-profile/expertise adaptation, clarify-budget,
re-entry-packet promise) before the workshop; with the hook the agent NEVER reads last-start-prompt.md — it
self-orients from git/config + the specify discipline and reaches the workshop on its own. "A workshop ran"
was BASELINE discipline-reading, NOT iter-6's contract-drive; iter-6's value-add was ABSENT.

Four gaps block re-claiming iter-6 (three maintainer requirements + one crew-self-review deployment gap):

1. **Read-and-follow IN PRACTICE** (maintainer #1): the hook must make the agent actually READ + FOLLOW
   last-start-prompt.md + start-context.json the way `specrew start` does. In the test the agent never
   touched the file. File existence (T038) is NOT read-and-follow.
2. **Content parity, not file existence** (maintainer #2): the hook's last-start-prompt.md must MATCH
   `specrew start`'s — including the user-profile/expertise adaptation + coordinator framing. ROOT CAUSE: the
   T036 "null launcher-only inputs" decision (empty roster/routing/projectstate stubs to Get-StartPrompt) was
   WRONG — user-profile/coordinator content is SESSION-AVAILABLE, not launcher-only; nulling it starved the
   generator → a thin contract. Get-StartPrompt has NO UserProfile param (confirmed) — trace where
   `specrew start`'s user-profile/coordinator content actually enters the contract (Save-StartArtifacts
   wrapping and/or a block I nulled) and thread the session-available inputs through the hook path.
3. **Acceptance test = SIDE-BY-SIDE** (maintainer #3): replace T038's on-disk file check as the acceptance
   GATE with a hook-vs-`specrew start` diff of the agent's LEAD-UP; they must be equivalent modulo genuinely
   launcher-only bits (host selection). T038 passing while the experiences differ is build≠live one level up.
4. **Deployment sync** (crew self-review, ground-truth confirmed): the deployed downstream provider is the
   EXTENSION-SOURCE copy `extensions/specrew-speckit/scripts/specrew-bootstrap-provider.ps1` (iter-4, 88
   lines, no contract-writer), NOT the iter-6 module copy `scripts/internal/...` (128 lines).
   Resolve-ProviderCommandPath resolves the `.specify/` copy FIRST downstream; the dev tree runs iter-6 only
   because its `.specify/` lacks the provider → falls back to scripts/internal/. Deploying THIS branch to a
   fresh project ships iter-4 and writes NO last-start-prompt.md (empirically confirmed). T038 copied the
   module copy, so it never exercised the copy downstream actually runs. FIX: sync the iter-6 provider into
   the extension source + extend the deployed floor to deploy-via-extension + resolve-via-dispatcher.

CONSEQUENCE: `specrew start` CANNOT be repositioned to "host-selection + fallback" (T042) until the hook
reaches content-parity AND read-and-follow — it still carries the contract the hook lacks. T042's docs
repositioning is PREMATURE and reverts until parity holds. The review-signoff packet's "T038 deployed-proven"
framing is RETRACTED — it proved the wrong provider copy + on-disk existence, not the live read-and-follow
experience.

Status: RESOLVED (maintainer direction, 2026-06-10) — iteration 006 CLOSED honestly-qualified (T035 generator
extraction KEPT, byte-identical; hook-parity NOT achieved → deferred). The parity rework is **iteration 007**
(design-pass-first → before-implement). The WIP checkpoints (02e843c4, 7657498f) + the citation-fix
(596aea7e) stay; T036/T037's contract-write + DRIVE directive landed but did NOT achieve parity (the hook
skips the coordinator-surgery step → thin contract; the agent does not read the file). iter-7's design pass
(`../007/plan.md`) traces the root cause to the skipped `Invoke-SpecrewCoordinatorPromptSurgery` step and
fixes both layers + the side-by-side acceptance gate. The T042 `specrew start` repositioning is reverted in
docs until the side-by-side passes.

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