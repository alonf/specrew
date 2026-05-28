# Tasks: Iteration 004 — Proposal 120 Five-Pillar Bypass Detection (completion + certification)

**Schema**: v1
**Spec**: [../../spec.md](../../spec.md)
**Plan**: [plan.md](plan.md)
**Scope**: FR-018..FR-022, SC-004 (TG-004, TG-008, TG-016)

> Pillars 1–3 (FR-018..FR-020) shipped in F-047 (`d4284c8a`); this iteration certifies them and
> completes Pillar 4 (FR-021) + Pillar 5 (FR-022). Two items (T005, T006) depend on human decisions
> recorded at the before-implement gate (see plan.md "Human Decisions Required").

## Tasks

### T001 — Create Iteration 004 audit scaffold and evidence envelope

- **Requirement**: FR-018, FR-019, FR-020, FR-021, FR-022, SC-004, TG-008, TG-016
- **Story**: US4 · **Owner**: Reviewer · **Effort**: 0.4
- **Deliverable**: `iterations/004/quality/quality-evidence.md` + `mechanical-findings.json` (hand-authored; A-001).
- **Acceptance**: evidence envelope present with a gate matrix covering all five pillars + SC-004.

### T002 — Pillar 5 helper `Test-ReviewCitedFilesInTree`

- **Requirement**: FR-022, TG-008 · **Story**: US4 · **Owner**: Implementer · **Effort**: 1.2
- **Surfaces**: `shared-governance.ps1` (+ `.specify` mirror).
- **Acceptance**: helper parses `**Tree Under Review**: <hash>` + cited evidence paths, runs `git ls-tree -r <hash>`, returns per-file presence with production-vs-test classification; pure/strict-safe; no false throw on missing fields.

### T003 — Pillar 5 validator rule + iteration-closeout hard-gate

- **Requirement**: FR-022, SC-004, TG-008 · **Story**: US4 · **Owner**: Implementer · **Effort**: 1.5
- **Surfaces**: `validate-governance.ps1` (+ mirror).
- **Acceptance**: production file cited but absent from cited tree → FAIL (AC9) blocking iteration-closeout (AC11); test file absent → WARN (AC10); clear repair message; backward-compatible otherwise (AC4).

### T004 — Pillar 4 validator-side state-advance-without-verdict cross-check

- **Requirement**: FR-021 · **Story**: US4 · **Owner**: Implementer · **Effort**: 1.2
- **Surfaces**: `validate-governance.ps1` (+ mirror).
- **Acceptance**: when state.md `Current Phase` advances across a human-verdict boundary with no matching `verdict_history` entry (non-empty `authorizing_human`), emit WARN (AC7); pre-2026-05-26 iterations grandfathered by timestamp.

### T005 — Pillar 4 sync short-circuit repair (fork A)

- **Requirement**: FR-021 · **Story**: US4 · **Owner**: Implementer · **Effort**: 1.3
- **Surfaces**: `scripts/internal/sync-boundary-state.ps1`, `shared-governance.ps1`.
- **Depends on**: human approval of plan fork (Pillar 4: fix vs detection-only).
- **Acceptance**: a stale/ahead `last_authorized_boundary` no longer silently skips recording a real crossing nor bypasses the AC8 hard-block; the breach is detected/surfaced and recording is corrected.

### T006 — Pillar 1 live handoff-evidence signal (blocker option a/b)

- **Requirement**: FR-018 · **Story**: US4 · **Owner**: Implementer · **Effort**: 1.7
- **Surfaces**: `scripts/internal/sync-boundary-state.ps1`, `validate-governance.ps1`.
- **Depends on**: human decision (live producer vs live re-derivation vs defer).
- **Acceptance**: FR-018 missing-handoff detection fires in a real lifecycle run (not only the synthesized fixture); a real boundary stop lacking a handoff block surfaces a WARN.

### T007 — Certify Pillars 2–3 live + FR traceability markers

- **Requirement**: FR-018, FR-019, FR-020 · **Story**: US4 · **Owner**: Reviewer · **Effort**: 0.5
- **Surfaces**: `validate-governance.ps1` (+ mirror).
- **Acceptance**: documented evidence that Pillars 2–3 fire in real validation; FR-018..FR-020 traceability markers added without reshaping shipped logic (TG-016).

### T008 — SC-004 fixtures (all five shapes)

- **Requirement**: FR-018, FR-019, FR-020, FR-021, FR-022, SC-004 · **Story**: US4 · **Owner**: Reviewer · **Effort**: 1.6
- **Surfaces**: `tests/integration/non-specrew-session-bypass.tests.ps1`.
- **Acceptance**: tests cover Pillar 4 (state-advance-without-verdict) + Pillar 5 (production FAIL / test WARN) + live Pillar 1; a single run surfaces all five shapes (SC-004).

### T009 — Mirror parity + Proposal 120 evidence

- **Requirement**: TG-008, SC-004 · **Story**: US4 · **Owner**: Reviewer · **Effort**: 0.6
- **Surfaces**: tests + `iterations/004/quality/quality-evidence.md`.
- **Acceptance**: modified `validate-governance.ps1` + `shared-governance.ps1` (+ sync helper) SHA256-equal across `extensions/` ↔ `.specify/` (AC6); evidence records all five pillars surfacing + the Pillar 5 closeout gate.

## Traceability

- FR-018 → T006, T007, T008 · FR-019 → T007, T008 · FR-020 → T007, T008
- FR-021 → T004, T005, T008 · FR-022 → T002, T003, T008
- SC-004 → T001, T003, T008, T009 · TG-008 → T002, T003, T009 · TG-016 → T001, T007
- Every task maps to ≥1 FR/SC; every in-scope requirement (FR-018..FR-022, SC-004) has ≥1 task.
