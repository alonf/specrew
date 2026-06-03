# Tasks: Unix Resolver Sidecar Hardening Investigations

**Feature**: 160-unix-resolver-sidecar-hardening
**Branch**: 160-unix-resolver-sidecar-hardening
**Total Tasks**: 18
**Iterations**: 1
**Total Effort**: 19.5 SP
**Status**: Ready for before-implement approval

## Overview

This task list implements a repro-first investigation for two Feature-140
fast-follow suspicions. Every task maps to at least one functional requirement
or success criterion from `spec.md`.

The tasking gate is explicit: **no resolver, sidecar, host-runtime, deploy
helper, or docs behavior may be changed before the relevant repro/evidence tasks
run and produce a confirmed finding**. Conditional fix tasks are skipped with
not-confirmed evidence when the suspected behavior is not reproduced.

## Iteration 001: Repro Evidence and Conditional Focused Fixes (19.5/20 SP)

**User Stories**: US1 (Prove Resolver Path Behavior), US2 (Prove Managed Refresh
Marker Behavior), US3 (Close Unconfirmed Findings Without Fixes)
**Functional Requirements**: FR-001 through FR-010
**Success Criteria**: SC-001 through SC-005

### Phase 0: Boundary Hygiene and Evidence Setup

- [ ] T001 Classify the current dirty working tree before implementation and
  record unrelated pre-existing files that must not be staged or modified.
  Include `.codex`, `.squad`, `.cursor`, `.specrew`, and prior Feature-140
  runtime artifacts in the exclusion review if still present. [effort: 0.5 SP]
  [FR-010] [SC-005] [owner: Implementer]
- [ ] T002 Create an implementation evidence note for Iteration 001 that will
  track each suspected issue, repro command, result, disposition, and any
  conditional source changes. This note starts empty except for the two finding
  headings and is updated as tasks run. [effort: 0.5 SP] [FR-001, FR-005,
  FR-009] [SC-001, SC-002] [owner: Spec Steward]

### Phase 1: Resolver Path Investigation Before Any Fix

- [ ] T003 Inspect resolver/module-loading path surfaces and record the exact
  candidate expressions under test. Include `Specrew.psm1`,
  `scripts/specrew.ps1`, and any helper discovered from those entrypoints that
  affects dev-tree versus installed-module resolution. Do not edit resolver
  behavior in this task. [effort: 1 SP] [FR-001, FR-002] [SC-001, SC-002]
  [owner: Implementer] [deps: T001, T002]
- [ ] T004 Add a focused resolver path semantics test or probe that exercises
  the current path construction before any fix. Prefer real Unix/macOS
  PowerShell evidence first; use a deterministic cross-platform fixture only
  when it proves equivalent embedded-backslash path semantics. [effort: 2 SP]
  [FR-001, FR-002] [SC-001, SC-002] [owner: Implementer] [deps: T003]
- [ ] T005 Run the resolver probe on the strongest available surface and record
  actual output as `confirmed`, `not-confirmed`, or `environment-blocked`. If
  using fallback fixture evidence, explicitly state why it proves equivalent
  path semantics. No resolver fix is allowed before this disposition exists.
  [effort: 1 SP] [FR-001, FR-002, FR-009] [SC-001, SC-002] [owner:
  Reviewer] [deps: T004]

### Phase 2: Managed Refresh Sidecar Investigation Before Any Fix

- [ ] T006 Inspect managed-refresh and host-runtime marker surfaces and record
  the exact source/mirror files under test. Include
  `extensions/specrew-speckit/scripts/deploy-squad-runtime.ps1`,
  `hosts/_team-canonical.ps1`, and relevant `hosts/*/handlers.ps1` files. Do
  not edit sidecar or runtime behavior in this task. [effort: 1 SP] [FR-005,
  FR-006] [SC-001, SC-002] [owner: Implementer] [deps: T001, T002]
- [ ] T007 Add focused direct deploy-logic fixture coverage for marker creation
  and marker recognition. The fixture must prove managed files refresh from
  canonical sources when markers are valid and unmanaged/user-edited files are
  preserved when markers are absent. Escalate to full init/update/start
  lifecycle fixtures only if direct deploy-logic fixtures cannot prove the
  behavior. [effort: 2.5 SP] [FR-005, FR-006, FR-008] [SC-001, SC-004] [owner:
  Implementer] [deps: T006]
- [ ] T008 Run the managed-refresh fixture and record actual output as
  `confirmed`, `not-confirmed`, or `environment-blocked`. If direct fixtures are
  insufficient, record the reason and run the minimal broader lifecycle fixture
  needed. No sidecar or runtime fix is allowed before this disposition exists.
  [effort: 1 SP] [FR-005, FR-006, FR-009] [SC-001, SC-002, SC-004] [owner:
  Reviewer] [deps: T007]

### Phase 3: No-Blind-Fix Gate

- [ ] T009 Apply the no-blind-fix gate before source changes: verify T005 and
  T008 dispositions exist, verify no resolver or sidecar behavior changed
  before those dispositions, and mark each conditional fix path as active or
  skipped. If a finding is not confirmed, record not-confirmed evidence and do
  not change shipped behavior for that finding. [effort: 1 SP] [FR-001,
  FR-005, FR-009, FR-010] [SC-001, SC-002, SC-005] [owner: Reviewer] [deps:
  T005, T008]

### Phase 4: Conditional Resolver Fix

- [ ] T010 Conditional resolver fix: only if T009 marks the resolver issue
  confirmed, replace the proven unsafe resolver path construction with
  separator-safe multi-segment `Join-Path`, `[System.IO.Path]::Combine`, or an
  equivalent platform-safe API. If T009 marks the resolver issue not confirmed
  or environment-blocked, skip this task with evidence and make no resolver
  behavior change. [effort: 1.5 SP] [FR-003, FR-009] [SC-002, SC-003] [owner:
  Implementer] [deps: T009]
- [ ] T011 Conditional resolver regression proof: only if T010 changes resolver
  behavior, run Windows and Unix/macOS or deterministic Unix-equivalent
  regression coverage proving the corrected path behavior. If T010 is skipped,
  record no-fix evidence instead. [effort: 1 SP] [FR-004, FR-009] [SC-001,
  SC-003] [owner: Reviewer] [deps: T010]

### Phase 5: Conditional Managed Refresh Fix

- [ ] T012 Conditional sidecar fix: only if T009 marks managed-refresh marker
  behavior confirmed broken, apply the smallest marker-controlled
  refresh/preserve fix to the proven source surface. Avoid unrelated
  deploy-runtime, host-runtime, or template refactors. If T009 marks the sidecar
  issue not confirmed or environment-blocked, skip this task with evidence and
  make no sidecar behavior change. [effort: 1.5 SP] [FR-007, FR-009] [SC-002,
  SC-004] [owner: Implementer] [deps: T009]
- [ ] T013 Conditional sidecar regression proof: only if T012 changes sidecar
  behavior, run focused tests proving managed files refresh and unmanaged or
  user-edited files are preserved. If T012 is skipped, record no-fix evidence
  instead. [effort: 1 SP] [FR-008, FR-009] [SC-001, SC-004] [owner:
  Reviewer] [deps: T012]

### Phase 6: Documentation, Validation, and Review Readiness

- [ ] T014 Conditional docs update: only if a confirmed fix changes
  maintainer-visible or user-visible behavior, update the minimal relevant docs
  to describe the confirmed behavior. If no behavior change is confirmed, skip
  docs with evidence. [effort: 1 SP] [FR-010] [SC-005] [owner: Spec Steward]
  [deps: T011, T013]
- [ ] T015 Run focused test commands selected by T004/T007 plus governance
  validation. Record exact commands, exit codes, and outcomes in the iteration
  evidence note. [effort: 1 SP] [FR-004, FR-008, FR-010] [SC-003, SC-004,
  SC-005] [owner: Reviewer] [deps: T011, T013, T014]
- [ ] T016 Prepare review evidence identifying every source, mirror, test, and
  docs file touched; confirm unrelated runtime/untracked files were not staged;
  and list final dispositions for `resolver-path` and
  `managed-refresh-sidecar`. [effort: 0.75 SP] [FR-009, FR-010] [SC-001,
  SC-002, SC-005] [owner: Reviewer] [deps: T015]
- [ ] T017 Update the drift log if implementation discovers scope drift,
  environment blockers, source/mirror disagreement, or a requirement that cannot
  be satisfied without changing the approved plan. [effort: 0.5 SP] [FR-009,
  FR-010, TG-004, TG-005] [SC-001, SC-005] [owner: Spec Steward] [deps: T015]
- [ ] T018 Complete reviewer readiness: verify each task is done or
  evidence-skipped, each finding has a final disposition, and each confirmed fix
  has matching regression coverage before review signoff. [effort: 0.75 SP]
  [FR-001, FR-004, FR-008, FR-009, FR-010] [SC-001, SC-002, SC-003, SC-004,
  SC-005] [owner: Reviewer] [deps: T016, T017]

## Dependency Graph

```text
T001,T002 -> T003 -> T004 -> T005
T001,T002 -> T006 -> T007 -> T008
T005,T008 -> T009
T009 -> T010 -> T011
T009 -> T012 -> T013
T011,T013 -> T014 -> T015 -> T016,T017 -> T018
```

## Parallel Opportunities

- T003/T004/T005 and T006/T007/T008 can proceed independently after T001/T002,
  because resolver and sidecar investigations use separate fixtures.
- T010/T011 and T012/T013 can proceed independently after T009, but only for
  findings marked confirmed by the no-blind-fix gate.
- T016 and T017 can proceed in parallel after T015.

## Quality Gates and Acceptance Criteria

### Before Implementation

- Human approves tasks and explicitly starts implementation.
- T001/T002 prepare branch hygiene and evidence tracking before code changes.
- T009 is treated as the tasking gate: conditional fix tasks are inactive until
  matching repro/evidence exists.

### No-Blind-Fix Gate

- Resolver fix task T010 is allowed only after T005 records a confirmed resolver
  disposition and T009 activates the resolver fix path.
- Sidecar fix task T012 is allowed only after T008 records a confirmed sidecar
  disposition and T009 activates the sidecar fix path.
- If either finding is not confirmed, the corresponding fix task is skipped with
  evidence and shipped behavior is unchanged.

### Implementation Complete

- Both suspected issues have final dispositions.
- Confirmed resolver fixes have Windows and Unix/macOS or deterministic
  Unix-equivalent regression proof.
- Confirmed sidecar fixes have managed-refresh and unmanaged-preserve
  regression proof.
- Documentation changes appear only when confirmed behavior changes need them.
- Review evidence proves unrelated untracked/runtime files were not staged.

## Traceability Matrix

| Requirement / Criterion | Covered by |
| --- | --- |
| FR-001 | T002, T003, T004, T005, T009, T018 |
| FR-002 | T003, T004, T005 |
| FR-003 | T010 |
| FR-004 | T011, T015, T018 |
| FR-005 | T002, T006, T007, T008, T009 |
| FR-006 | T006, T007, T008 |
| FR-007 | T012 |
| FR-008 | T007, T013, T015, T018 |
| FR-009 | T002, T005, T008, T009, T010, T011, T012, T013, T016, T017, T018 |
| FR-010 | T001, T009, T014, T015, T016, T017, T018 |
| TG-001 | this matrix |
| TG-002 | owner metadata on every task |
| TG-003 | Iteration 001 task section and delivery scope |
| TG-004 | T017 |
| TG-005 | T009, T017, T018 |
| SC-001 | T002, T005, T008, T009, T011, T013, T016, T018 |
| SC-002 | T002, T003, T004, T005, T008, T009, T010, T012, T016, T018 |
| SC-003 | T010, T011, T015, T018 |
| SC-004 | T007, T008, T012, T013, T015, T018 |
| SC-005 | T001, T009, T014, T015, T016, T017, T018 |

Every task maps to at least one FR/SC, and every in-scope FR/SC maps to at
least one task.

## Effort Verification

| Phase | Tasks | Planned SP |
| --- | --- | --- |
| Boundary hygiene and evidence setup | T001-T002 | 1.0 |
| Resolver investigation before fix | T003-T005 | 4.0 |
| Sidecar investigation before fix | T006-T008 | 4.5 |
| No-blind-fix gate | T009 | 1.0 |
| Conditional resolver fix | T010-T011 | 2.5 |
| Conditional sidecar fix | T012-T013 | 2.5 |
| Docs, validation, review readiness | T014-T018 | 4.0 |

The summed work intentionally includes conditional fix capacity. If a finding is
not confirmed, the related fix task is evidence-skipped rather than repurposed
for speculative changes.

## Next Steps

1. Run after-tasks traceability validation.
2. Scaffold Iteration 001 hardening and iteration-plan artifacts after explicit
   human approval to proceed toward implementation.
3. Start implementation only after the before-implement gate is approved.
