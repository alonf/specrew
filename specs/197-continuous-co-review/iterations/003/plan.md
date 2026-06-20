# Iteration Plan: 003

**Schema**: v1
**Spec**: [../../spec.md](../../spec.md)
**Status**: planning
**Capacity**: 9.50/20 story_points
**Started**: 2026-06-20
**Completed**:

<!--
  Validator schema (canonical, enforced by validate-governance.ps1):
  - Iteration Status MUST be one of:
      planning | executing | reviewing | retro | complete | abandoned
  - Capacity format MUST be `<consumed>/<cap> <effort_unit>` with NO trailing prose on that line.
  - Task Status MUST be one of:
      planned | in-progress | done | needs-rework | deferred | blocked
-->

## Scope Summary

Iteration 003 is Phase A of the always-on extension: the 197-owned deterministic gate
floor plus the gate-keyed dispatcher, with no F-184 protected-surface edits. The live
Stop-hook trigger (Phase B) is deferred to Iteration 004.

| Requirement | Summary | Stories |
| ----------- | ------- | ------- |
| FR-024 | Co-review runs at every implement checkpoint via the dispatcher, on the incremental diff. | Always-on Phase A |
| FR-025 | Deterministic gate floor in boundary-sync refuses signoff without per-increment evidence. | Always-on Phase A |
| FR-027 | Per-checkpoint incremental baseline rebaselined to the prior checkpoint. | Always-on Phase A |
| FR-028 | One-time per-project navigator authorization; no per-run reauthorization. | Always-on Phase A |
| FR-029 | Blocking finding stops advancement and escalates under the two-round cap. | Always-on Phase A |
| FR-032 | One-call gate-review dispatcher + gate-keyed registry; single registrant code@implement. | Always-on Phase A |

## Tasks

| Task | Title | Requirement | Story | Effort | Owner | Owner File Globs | Status | Agent | Actual | Verdict |
| ---- | ----- | ----------- | ----- | ------ | ----- | ---------------- | ------ | ----- | ------ | ------- |
| T058 | Rebaseline each co-review to the last passing reviewed point (derived from existing `.specrew/review/inline` evidence, no separate ledger) and record `reviewed_ref` + `diff_hash` so the baseline advances only on a pass. | FR-027, IMPL-009, TG-013 | Always-on Phase A | 1.50 | Implementer | `scripts/internal/continuous-co-review/checkpoint-diff-provider.ps1`; `scripts/internal/continuous-co-review/checkpoint-review-orchestrator.ps1`; `scripts/internal/continuous-co-review/review-run-index-writer.ps1`; `tests/continuous-co-review/**` | planned | | | |
| T059 | Implement the gate-review dispatcher and gate-keyed registry, including real-checkpoint-vs-casual-yield and gate detection, with code@implement as the sole registrant. | FR-032, SC-023, IMPL-004, TG-013 | Always-on Phase A | 2.50 | Architect | `scripts/internal/continuous-co-review/gate-review-dispatcher.ps1`; `scripts/internal/continuous-co-review/gate-review-registry.ps1`; `scripts/internal/continuous-co-review/_load.ps1`; `tests/continuous-co-review/**` | planned | | | |
| T060 | Wire the dispatcher to the existing checkpoint-review orchestrator so a registered implement checkpoint reviews its incremental diff and writes durable evidence. | FR-024, INT-004, TG-013 | Always-on Phase A | 1.00 | Implementer | `scripts/internal/continuous-co-review/gate-review-dispatcher.ps1`; `scripts/internal/continuous-co-review/checkpoint-review-orchestrator.ps1`; `tests/continuous-co-review/**` | planned | | | |
| T061 | Add the deterministic co-review evidence gate floor (throw-to-refuse) to `Invoke-SpecrewBoundaryStateSync`, refusing review-signoff unless a pass/escalated run's `diff_hash` (recomputed from its `baseline_ref` to the current working tree) still matches; missing/stale/malformed/blocking blocks. | FR-025, SC-019, SC-020, NFR-001, TG-013 | Always-on Phase A | 2.00 | Reviewer | `scripts/internal/sync-boundary-state.ps1`; `extensions/specrew-speckit/scripts/sync-boundary-state.ps1`; `tests/continuous-co-review/**` | planned | | | |
| T062 | Confirm one-time per-project navigator authorization for automatic runs and wire blocking-finding escalation under the two-round convergence cap. | FR-028, FR-029, SC-021, NFR-005, SEC-004 | Always-on Phase A | 1.25 | Spec Steward | `scripts/internal/continuous-co-review/reviewer-authorization-gate.ps1`; `scripts/internal/continuous-co-review/inline-review-gate-evaluator.ps1`; `tests/continuous-co-review/**` | planned | | | |
| T063 | Add the owed delayed-stdin reviewer-spawn regression test proving the timeout bounds a stalled large-stdin child and no child is orphaned. | NFR-001, INT-004 | Always-on Phase A | 0.75 | Reviewer | `tests/continuous-co-review/**` | planned | | | |
| T064 | Run Iteration 003 Phase A closeout validation: dispatcher fixtures, gate-floor blocking, traceability, and the protected-surface guard proving no F-184 edits. | FR-025, FR-032, SC-006, SC-019, SC-020, SC-023, TG-013 | Always-on Phase A | 0.50 | Reviewer | `tests/continuous-co-review/**`; `specs/197-continuous-co-review/iterations/003/**` | planned | | | |

## Effort Model

| Setting | Value | Notes |
| ------- | ----- | ----- |
| Effort Unit | story_points | Unit used in task effort, capacity, and retro variance. |
| Capacity per Iteration | 20 | Maximum planned effort before overcommit guidance applies. |
| Iteration Bounding | scope | `scope` keeps requirements fixed; time varies. |
| Time Limit (hours) | n/a | Not used for this scope-bounded slice. |
| Overcommit Threshold | 1.0 | Planned effort must stay at or below 20 story_points. |
| Defer Strategy | manual | Any overcommit requires explicit human deferral. |
| Calibration Enabled | true | Retro should compare planned and actual effort. |

## Concurrency Rationale

- T058 is foundational: the per-checkpoint incremental baseline is consumed by the
  dispatcher (T059/T060) and the gate floor (T061).
- T059 builds the dispatcher/registry seam and can proceed after T058 fixes the
  checkpoint/baseline shape.
- T060 wires the dispatcher to the existing orchestrator after T059's seam exists.
- T061 (gate floor) depends on the evidence shape produced by T060 but can be developed
  against fixtures in parallel once the evidence schema is fixed.
- T062 reuses the existing authorization gate and evaluator and can run after T060.
- T063 (spawn regression test) is independent and may run any time.
- T064 is the closeout validation and remains last.

## Phase Baseline

| Phase | Estimated Effort | Notes |
| ----- | ---------------- | ----- |
| Planning | 0.50 | Always-on design-analysis and artifact authoring. |
| Discovery/Spikes | 1.00 | Per-task checkpoint concept and incremental baseline shaping. |
| Implementation | 5.50 | Dispatcher, registry, navigator wiring, gate floor, authorization/escalation. |
| Review | 1.25 | Dispatcher and gate-floor deterministic fixtures plus the spawn regression test. |
| Rework | 1.25 | Reserved for evidence-shape or boundary-sync gate corrections within the 9.50 SP slice. |

## Traceability Summary

- Iteration 003 (Phase A) in-scope requirements: FR-024, FR-025, FR-027, FR-028,
  FR-029, FR-032.
- Success criteria covered in this iteration: SC-019, SC-020, SC-021, SC-023, plus
  SC-006 (no protected-surface edits) as a guardrail.
- Deferred to Iteration 004 (Phase B): FR-026, FR-030, FR-031 and SC-022 (the live
  Stop-hook trigger, host-neutral wiring, FR-008 relaxation, and cross-host proof).
- Every task references `specs/197-continuous-co-review/implementation-rules.yml`
  through the authoritative root `tasks.md`.
- Capacity status: PASS, 9.50/20 story_points.

## Notes

- Phase A touches NO F-184 protected files. `sync-boundary-state.ps1` (T061) is the
  shared but non-protected boundary-sync engine and already hosts throw-to-refuse
  gates; the new co-review gate follows that pattern. The `.specify/` deployed mirror
  is regenerated by deploy tooling, not hand-edited.
- The live Stop-hook trigger (Phase B / Iteration 004) is the only part that touches
  the protected hook surface and must prove per-host block-and-feedback capability
  across all five harnesses before the maintainer manual real-host validation.
- The maintainer manual real-host validation (SC-012-class) runs AFTER both Phase A and
  Phase B, since Phase A has no live hook to exercise; Phase A closes on deterministic
  fixtures only.
- Do not start the Stop-hook wiring, host-abstraction edits, FR-008 relaxation, or
  cross-host hook fixtures in this iteration; those are Iteration 004.
- Runtime implementation starts only after human before-implement approval.
