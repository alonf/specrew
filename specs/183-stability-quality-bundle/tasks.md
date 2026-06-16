# Tasks: Stability and Quality Bundle

**Feature**: 183-stability-quality-bundle
**Plan**: plan.md
**Iteration**: 001
**Design-analysis verdict**: approved for plan with Option B
**Capacity**: 20/20 story_points

## Format

`- [ ] T### [P?] [US#] [Owner: role] [Capacity: N SP] Description (Trace: FR/SC/TG)`

`[P]` means the task is parallel-safe only when owner file globs do not overlap.
This iteration defaults to serial execution because T001 and T003 share hook
runtime/bootstrap surfaces and `tests/bootstrap/**`.

## Phase 1: SessionStart Delivery and State

**Goal**: Keep governed bootstrap visible when cap handling, provider failure,
or missing host session IDs would otherwise hide or corrupt lifecycle state.

**Independent test**: deterministic Pester coverage proves over-cap output keeps
bootstrap, provider failures emit a governed fallback, and missing/blank/
malformed session IDs use per-launch tokens instead of global `unknown`.

- [x] T001 [US1] [Owner: Implementer] [Capacity: 4 SP] Implement SessionStart cap policy and provider fallback in `extensions/specrew-speckit/scripts/**` with tests in `tests/bootstrap/**`; preserve bootstrap ahead of refocus, emit under-cap governed fallback on provider failure, exit 0, and include recovery guidance for `specrew where` or `/specrew-refocus` (Trace: FR-001, FR-002, SC-001, SC-002, LIR-007, LIR-008).
- [ ] T002 [US1] [Owner: Implementer, Reviewer] [Capacity: 2 SP] Rewrite `tests/bootstrap/DirectiveDeliveryCap.Tests.ps1` to measure a synthetic shipped SessionStart composite rather than ambient developer-machine refocus state (Trace: FR-004, SC-004).
- [x] T003 [US2] [Owner: Implementer] [Capacity: 3 SP] Implement the Session ID resolver and journal/status/dedupe/breaker state changes in `scripts/internal/bootstrap/**`, `scripts/internal/specrew-hook-dispatcher.ps1`, mirrored `extensions/specrew-speckit/scripts/**` and `.specify/extensions/specrew-speckit/scripts/**`, `tests/bootstrap/**`, and `tests/integration/refocus-dispatcher.tests.ps1`; sanitize host session IDs and generate filesystem-safe per-launch fallback tokens when IDs are missing, blank, or malformed (Trace: FR-003, SC-003, LIR-003, LIR-004, LIR-007).

**Sequencing constraint**: T001 and T003 are serial unless a before-implement
update narrows owner file globs enough to prove they can run in parallel.

## Phase 2: Closeout Truth and Local Test Hygiene

**Goal**: Make feature closeout sync and local red cleanup tests reflect the
actual repo state instead of stale, no-upstream, or dirty real-tree assumptions.

**Independent test**: closeout fixtures cover dirty `.specify` companion
surfaces, no-upstream wording, dashboard regeneration, scratch git isolation,
and module-internal lifecycle sync assertions.

- [ ] T004 [US3] [Owner: Implementer] [Capacity: 4 SP] Update closeout classification, upstream wording, and dashboard refresh behavior in `scripts/internal/sync-boundary-state.ps1` with fixtures in `tests/integration/**`; dirty `.specify/extensions/` plus companion `.specify` files classify coherently, no-upstream branches do not say "must be pushed", and auto-detect closeout regenerates dashboards from current artifacts (Trace: FR-005, SC-005, LIR-007).
- [ ] T005 [US3] [Owner: Implementer, Reviewer] [Capacity: 2 SP] Fix the two in-scope #1761 mechanical local tests in `tests/integration/closeout-lifecycle-sync-commands.tests.ps1` and related `tests/integration/**` fixtures so dirty-state tests use scratch repos and ValidateSet assertions target the module-internal sync script copy (Trace: FR-006, SC-006).

## Phase 3: Antigravity Verified Hook Support

**Goal**: Add Antigravity to the hook-capable path only where project-scoped
hook configuration, event mapping, and output semantics are verified.

**Independent test**: Antigravity hook install/remove/opt-out tests preserve
existing user hook entries in `.agents/hooks.json`, verified events invoke the
Specrew dispatcher/provider path, unsupported parity remains labeled degraded,
and fallback guidance still points to `specrew start --host antigravity`.

- [ ] T006 [US4] [Owner: Implementer, Reviewer] [Capacity: 4 SP] Implement bounded Antigravity hook binding and docs cleanup across `hosts/**`, `scripts/internal/deploy-refocus-hooks.ps1`, `scripts/specrew-hooks.ps1`, `docs/**`, `README.md`, `tests/integration/refocus-deploy.tests.ps1`, and `tests/integration/specrew-hooks-command.tests.ps1`; use project-scoped `.agents/hooks.json`, preserve user hook entries, map only verified events/output behavior, remove stale no-hooks wording, and keep `specrew start --host antigravity` as fallback (Trace: FR-007, SC-009, TG-004, LIR-004, LIR-005, LIR-007, LIR-008).

## Phase 4: Review Evidence and Release Readiness

**Goal**: Record the evidence needed to close the iteration honestly without
claiming unverified host parity or hard-coding the beta suffix.

**Independent test**: review evidence names the exact mirror files checked,
release target selection inputs, real-host pass/fail result, and fixing commit
links for issues #2446, #1627, and #1761.

- [ ] T007 [US1-US4] [Owner: Reviewer] [Capacity: 0.25 SP] Record mirror parity for every touched extension/runtime file under `extensions/specrew-speckit/**` and `.specify/extensions/specrew-speckit/**`; pass only when touched source and deployed mirror files are byte-aligned or the drift is explicitly recorded and resolved before review-signoff (Trace: SC-007, TG-003).
- [ ] T008 [US1-US4] [Owner: Spec Steward] [Capacity: 0.25 SP] Record release readiness for the dynamic beta target in `specs/183-stability-quality-bundle/**`; inspect local tags, origin tags, and published release/package state before naming the next valid `0.37.0-beta<N>` (Trace: SC-007, LIR-006).
- [ ] T009 [US1, US4] [Owner: Reviewer] [Capacity: 0.25 SP] Run and record real-host validation after T001, T003, and T006 are merged; PASS requires a real hook-capable host to show SessionStart bootstrap or degraded-governed fallback reaching the agent, and Antigravity validation to prove only the verified event/output behavior claimed by T006. FAIL if the host drops the payload silently, no governed fallback reaches the agent, Antigravity clobbers user hook entries, or docs/status claim unverified SessionStart/Stop parity (Trace: SC-008, SC-009, TG-004).
- [ ] T010 [US3] [Owner: Spec Steward, Reviewer] [Capacity: 0.25 SP] Record closeout issue linkage for the fixing commits in `specs/183-stability-quality-bundle/**`; link fixes to issues #2446, #1627, and #1761, reference proposals without silently editing them, and include the traceability-check result before before-implement readiness is requested (Trace: TG-001, TG-002, TG-005).

## Dependencies and Execution Order

- T001, T002, and T003 form the P1 SessionStart reliability lane. T001 and T003
  are serial unless owner globs are narrowed before implementation.
- T004 and T005 can begin after the implementer has a clean working tree and
  scratch-repo fixtures are available; they do not depend on Antigravity work.
- T006 depends on official Antigravity schema/event/output verification staying
  inside the bounded adapter/config/docs/test slice. If it grows beyond that
  slice, pause for a human split/defer decision before implementation continues.
- T007 and T008 run during review after touched files and release inputs are
  known.
- T009 is review-stage evidence after T001, T003, and T006 are merged.
- T010 runs during closeout/readiness evidence assembly after fixing commits are
  known.

## Traceability Check

**Task -> authority**: every task above includes at least one FR, SC, or TG trace.

**FR coverage**:

- FR-001: T001
- FR-002: T001
- FR-003: T003
- FR-004: T002
- FR-005: T004
- FR-006: T005
- FR-007: T006

**SC coverage**:

- SC-001: T001
- SC-002: T001
- SC-003: T003
- SC-004: T002
- SC-005: T004
- SC-006: T005
- SC-007: T007, T008
- SC-008: T009
- SC-009: T006, T009

**TG coverage**:

- TG-001: T010 plus this Traceability Check section
- TG-002: T010 plus this Traceability Check section
- TG-003: T007
- TG-004: T006, T009
- TG-005: T010

**Capacity check**: 4 + 2 + 3 + 4 + 2 + 4 + 0.25 + 0.25 + 0.25 + 0.25 = 20 story_points.

**Parallelism check**: no tasks are marked `[P]` because the approved iteration
defaults to serial execution. Parallel work requires narrowed owner file globs
and a recorded safety proof before implementation.

## Before-Implement Readiness Inputs

- Governance validator must pass after this file is committed.
- Bidirectional traceability must remain PASS for FR-001 through FR-007,
  SC-001 through SC-009, and TG-001 through TG-005.
- The before-implement approval `f183-i001-before-implement-approved` ratifies
  T001 on its merits and authorizes T003, serial after T001.
- T001/T003 are serial by default, and T009 is review-stage real-host evidence.
- DR-002 is a separate non-blocking governance-only follow-up outside F-183's
  20 SP scope; it is not bound to T004 and has no FR/SC trace in this sprint.
- Carry-forward task constraints from the protocol correction: T002 must clear
  the known-red `DirectiveDeliveryCap.Tests.ps1` before review-signoff; T003
  must replace any `Get-SanitizedSessionId` global `unknown` return with the
  per-launch token path; fallback coverage must include non-zero provider exit,
  command-unresolved provider launch, dispatcher outer-catch, and
  bootstrap-over-cap; T006 must surface Antigravity schema/event/output
  verification early and stop for split/defer if it exceeds the bounded
  `.agents/hooks.json` adapter/config/docs/test slice; T009 must validate a
  hook-firing Antigravity host and non-Claude host behavior because the inner
  payload cap does not guarantee the final host JSON envelope stays under 10k.
