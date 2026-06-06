# Tasks: Managed-Skill "Stuck Preserving" Guard

**Feature**: 161-managed-skill-preserving-guard
**Branch**: 161-managed-skill-preserving-guard
**Total Tasks**: 9
**Iterations**: 1
**Total Effort**: 8 SP
**Status**: Ready for before-implement approval

## Overview

Repro-first investigation closing Proposal 161 on top of the Feature 160
baseline. Every task maps to at least one functional requirement or success
criterion from `spec.md`.

The tasking gate is explicit: **no deploy-script behavior may change before
the repro harness and reachability evidence produce a CONFIRMED verdict**
(misclassified AND reachable, per the approved plan). The conditional fix
tasks (T006, T007) are **blocked unless the T005 verdict is CONFIRMED** and
are skipped with REFUTED evidence otherwise — the fix budget stays unspent.

## Iteration 001: Deploy-Level Repro, Verdict, Conditional Fix (8/20 SP)

**User Stories**: US1 (Confirm or refute the residual risk), US2 (Managed
skills refresh when provenance says managed — conditional), US3 (Evidence and
tests survive regardless of outcome)
**Functional Requirements**: FR-001 through FR-007
**Success Criteria**: SC-001 through SC-005

### Phase 0: Hygiene and Evidence Setup

- [ ] T001 Verify boundary hygiene at implementation start: working tree clean
  except the two classified untracked generated outputs (`.cursor/rules`,
  `.specrew/version-check-cache.json`); record in the evidence note that
  F-141/F-159/F-160 surfaces are untouched. [effort: 0.5 SP] [FR-007] [SC-005]
  [owner: Spec Steward]
- [ ] T002 Create the Iteration 001 implementation evidence note tracking:
  scenario outcomes S1–S6, reachability findings, verdict, and any conditional
  source changes. Starts with empty headings; updated as tasks run.
  [effort: 0.5 SP] [FR-003] [SC-002] [owner: Spec Steward] [deps: T001]

### Phase 1: Deploy-Level Repro Harness (US1)

- [ ] T003 Build `tests/integration/managed-skill-stuck-preserving.tests.ps1`:
  isolated temp scratch project (`.squad` dir, seeded
  `.copilot/skills/specrew-*` fixtures, active skill roots), executing the real
  `extensions/specrew-speckit/scripts/deploy-squad-runtime.ps1` end-to-end and
  asserting scenarios S1 (marker-present → removed), S2 (user-authored →
  preserved, byte-identical afterwards), S3 (current-canonical no-marker →
  removed; F-160 deploy-level regression guard), S4 (stale older-canonical
  front-matter, no marker → outcome captured as probe, not pre-asserted),
  S5 (second run idempotent), S6 (all four active roots carry SKILL.md +
  `.specrew-managed`). Deterministic across consecutive runs; zero writes
  outside the sandbox; cleanup in `finally`. [effort: 2 SP] [FR-001, FR-002]
  [SC-001] [owner: Implementer] [deps: T002]
- [ ] T004 Reachability analysis: from git history of
  `extensions/specrew-speckit/squad-templates/skills/` and
  `deploy-squad-runtime.ps1`, determine whether any shipped Specrew version
  could leave a marker-less legacy `.copilot/skills/specrew-*` dir holding
  front-matter canonical content that later diverged from current canonical
  (when legacy deploys existed, whether they wrote markers, when templates
  gained front matter). Record the upgrade-path evidence in the evidence note.
  No source edits in this task. [effort: 1 SP] [FR-003] [SC-002]
  [owner: Implementer] [deps: T002]

### Phase 2: Verdict Gate (US1/US3)

- [ ] T005 Combine the S4 probe outcome (T003) with the reachability evidence
  (T004) into the recorded verdict: CONFIRMED (exact code path + reachable
  triggering scenario) or REFUTED (evidence that every reachable deploy path
  refreshes/cleans managed skills). Write the verdict with code-path citation
  into the iteration quality evidence. This task gates all fix work.
  [effort: 1 SP] [FR-003] [SC-002] [owner: Reviewer] [deps: T003, T004]

### Phase 3: Conditional Narrow Fix (US2) — BLOCKED unless T005 = CONFIRMED

- [ ] T006 (conditional) Implement the narrow classification/marker fix per
  the confirmed code path: provenance authoritative for Specrew-owned skills,
  heuristic strictly a fallback for genuinely pre-marker legacy dirs; scope
  limited to the legacy-cleanup classification (contract invariant I6); apply
  the same change to the `.specify` mirror (parity). Skip with REFUTED
  evidence if T005 is not CONFIRMED. [effort: 2 SP] [FR-004] [SC-003]
  [owner: Implementer] [deps: T005]
- [ ] T007 (conditional) Pre/post fix evidence: S4 flips to managed/cleaned
  with the fix (failing-before/passing-after captured in the evidence note),
  S2 user-authored preservation passes unchanged in both states, and the
  harness assertion for S4 is promoted from probe to regression assertion.
  Skip if T006 skipped. [effort: 0.5 SP] [FR-004, FR-005] [SC-003]
  [owner: Implementer] [deps: T006]

### Phase 4: Regression and Review Evidence (US3)

- [ ] T008 Run the full regression set and record logs: the new harness
  (twice, proving identical outcomes), the existing
  `tests/integration/managed-runtime-sidecar.tests.ps1` (all F-160 cases must
  pass unchanged), `run-mechanical-checks.ps1`, and
  `validate-governance.ps1`. [effort: 1 SP] [FR-005, FR-006] [SC-001, SC-004]
  [owner: Implementer] [deps: T005; T007 when fix path taken]
- [ ] T009 Assemble review evidence: verdict record, scenario outcome table,
  reachability citations, contract invariants I1–I6 check, scope guard proof
  (git diff touches only planned surfaces; no release/tag/merge/PR/push to
  main), and the developer-facing implementation briefing. [effort: 0.5 SP]
  [FR-003, FR-007] [SC-002, SC-005] [owner: Reviewer] [deps: T008]

## Traceability Matrix

| FR/SC | Tasks |
| --- | --- |
| FR-001 | T003 |
| FR-002 | T003 |
| FR-003 | T002, T004, T005, T009 |
| FR-004 | T006, T007 |
| FR-005 | T007, T008 |
| FR-006 | T008 |
| FR-007 | T001, T009 |
| SC-001 | T003, T008 |
| SC-002 | T002, T004, T005, T009 |
| SC-003 | T006, T007 |
| SC-004 | T008 |
| SC-005 | T001, T009 |

## Capacity

Capacity: 8/20 SP

## Notes

- Conditional tasks T006–T007 (2.5 SP) are part of the declared 8 SP but are
  released only by a CONFIRMED T005 verdict; on REFUTED the iteration closes
  at 5.5 SP consumed with the fix budget recorded as unspent.
- Effort arithmetic: T001 0.5 + T002 0.5 + T003 2 + T004 1 + T005 1 + T006 2 +
  T007 0.5 + T008 1 + T009 0.5 = 8 SP.
