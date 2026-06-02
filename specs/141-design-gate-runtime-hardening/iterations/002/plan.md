# Iteration Plan: 002

**Schema**: v1
**Spec**: [../../spec.md](../../spec.md)
**Status**: executing
**Capacity**: 16/20 story_points
**Started**: 2026-06-02
**Completed**:

<!--
  Validator schema: Iteration Status one of planning|executing|reviewing|retro|complete|abandoned.
  Capacity format `<consumed>/<cap> <unit>` with no trailing prose. Task Status one of
  planned|in-progress|done|needs-rework|deferred|blocked.
-->

## Iteration Theme

Start-packet correctness + stale-session-recovery hardening (smoke-bundle): fix the
generated start/handoff packet so it emits no empty `specs//...` path segments
(FR-011) and no non-selected-host wording (FR-014); clean up the two non-blocking
smoke-2 harness items; and fix the stale cross-worktree session-recovery bug
(FR-024) discovered in the Linux/native-install smoke — `specrew start` re-anchored
to a deleted/merged external worktree (Feature 051). This is a **bug-fix / hardening
slice**; the design-analysis gate is not required (defect repair with confirm-gated
cleanup and no architectural fork; the boundary state is post-closeout, not a
pre-plan substantive entry). Capacity 16/20 — within cap, nothing dropped.

## Scope Summary

| Requirement | Summary | Stories |
| ----------- | ------- | ------- |
| FR-011 | Generated start/handoff packets MUST NOT emit empty `specs//...` path segments | US4 |
| FR-014 | Generated launch/runtime guidance MUST present host-accurate wording (no leak) | US7 |
| FR-015 | Smoke defects stay in this feature | US0 |
| FR-024 | Stale cross-worktree session recovery: detect stale session state, do not re-anchor to a deleted/merged external worktree, confirm-gated safe cleanup | US0 |
| (smoke-2 cleanup) | Gate-harness trailing `$LASTEXITCODE` wrapper error after `GATE_VALID: True`; first quality/prereq command path self-correct | US0 |

Carried out of Iteration 2: FR-012/FR-013 (greenfield/downstream hygiene) -> Iteration 3; FR-009/FR-010 (lens) -> deferred lens slice.

## Tasks

| Task | Title | Requirement | Story | Effort | Owner | Owner File Globs | Status | Agent | Actual | Verdict |
| ---- | ----- | ----------- | ----- | ------ | ----- | ---------------- | ------ | ----- | ------ | ------- |
| T001 | Confirm scope; reproduce empty-path + host-wording in fixtures; record in drift-log | FR-011, FR-014, FR-015 | US0 | 1 | Spec Steward | specs/141-design-gate-runtime-hardening/** | done | claude | 1 | — |
| T002 | Fix empty `specs//` path construction in the start-packet generator (guard unresolved feature segment: omit or placeholder, never empty) | FR-011 | US4 | 2 | Implementer | scripts/specrew-start.ps1 | done | claude | 2 | — |
| T003 | Fix host-wording leak: host-conditional guidance (no Copilot approval-mode text on a Claude launch, etc.) | FR-014 | US7 | 2 | Implementer | scripts/specrew-start.ps1 | done | claude | 2 | — |
| T004 | Clean up gate-harness trailing `$LASTEXITCODE` wrapper error after `GATE_VALID: True`; quiet the first-run quality/prereq path self-correct | FR-015 | US0 | 1 | Implementer | scripts/internal/design-analysis-gate.ps1, scripts/specrew-start.ps1 | done | claude | 1 | — |
| T005 | Tests: no `specs//` in generated paths; per-host wording; clean harness exit | SC-007, SC-010 | US4 | 2 | Implementer | tests/unit/**, tests/integration/** | done | claude | 2 | — |
| T007 | Detect stale cross-worktree session: classify saved session stale when feature path missing OR completed/merged outside current worktree; never re-anchor to a deleted external worktree | FR-024 | US0 | 3 | Implementer | scripts/internal/session-recovery.ps1, scripts/specrew-start.ps1 | done | claude | 3 | — |
| T008 | Safe confirm-gated cleanup: clear stale active-sessions/start-context refs (no artifact touch, no lifecycle commits); report branch + stale refs + active-feature candidate; require human confirmation | FR-024 | US0 | 2 | Implementer | scripts/internal/session-recovery.ps1, scripts/specrew-start.ps1 | done | claude | 2 | — |
| T009 | Regression tests for the stale cross-worktree recovery scenario (deleted/merged external worktree -> stale -> no re-anchor -> confirm-gated cleanup) | FR-024 | US0 | 2 | Reviewer | tests/unit/**, tests/integration/** | done | claude | 2 | — |
| T006 | Docs + review evidence (quickstart/contract notes for start-packet + stale-session behavior) | TG-006 | US0 | 1 | Planner | specs/141-design-gate-runtime-hardening/** | done | claude | 1 | — |

## Effort Model

| Setting | Value | Notes |
| ------- | ----- | ----- |
| Effort Unit | story_points | |
| Capacity per Iteration | 20 | |
| Iteration Bounding | scope | |
| Time Limit (hours) | n/a | Only applies when iteration bounding is `time`. |
| Overcommit Threshold | 1.0 | 9/20 — comfortable headroom. |
| Defer Strategy | manual | |
| Calibration Enabled | true | |

## Phase Baseline

| Phase | Estimated Effort | Notes |
| ----- | ---------------- | ----- |
| Planning | 1 | T001 scope + reproduction (start-packet + stale-session). |
| Implementation | 10 | T002 path fix, T003 host wording, T004 harness cleanup, T007 stale-session detection, T008 safe confirm-gated cleanup. |
| Review | 5 | T005 start-packet tests, T009 stale-session regression tests, T006 docs/review evidence. |
| Rework | 0 | Buffer within the remaining 4 SP headroom. |

## Concurrency Rationale

- T002/T003/T004 edit the start-packet generator and the gate harness; sequence the `scripts/specrew-start.ps1` edits to avoid conflicts. Serial baseline team; no Junior/Senior expansion justified for a small-fix slice.

## Traceability Summary

- Iteration 2 scope: FR-011, FR-014, FR-015, FR-024 (stale cross-worktree session recovery), plus the two smoke-2 cleanup items; SC-007, SC-010.
- Design-analysis: not required (bug-fix / hardening slice; confirm-gated cleanup, no architectural fork; boundary state post-closeout).
- Estimate is 16 SP: 9 SP (start-packet correctness + harness cleanup) + 7 SP (FR-024 stale-session recovery: T007 detect 3, T008 safe cleanup 2, T009 regression 2). Within the 20 cap with 4 SP headroom; nothing dropped (per the 2026-06-02 directive to fold in the stale-session bug).

## Notes

- Reproduction first (T001): smoke-2 evidence (`iterations/001/manual-smoke.md`) showed `specs//spec.md` and `specs//iterations//dashboard.md`; reproduce in a fixture before fixing so the test proves the fix.
- This iteration writes code; it will stop at before-implement for the human start-implementation go-ahead, as usual.
