# Iteration Plan: 003

**Schema**: v1
**Spec**: [../../spec.md](../../spec.md)
**Status**: executing
**Capacity**: 24.00/25 story_points
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

**Re-architecture (2026-06-20, D-197-I003-004/005):** the feature's own co-reviews found
the first gate model (diff-from-baseline) had two false-allows — HOLE A (gitignored-source
blindness) and HOLE B (unanchored operator baseline). Per the approved design revision, the
gate is re-architected to a **content-addressed reviewed-state tree-id** (includes
gitignored source minus secrets; HOLE A closed, empirically validated) and a **lineage
chain anchored to merge-base with the trunk** with producer auto-anchoring and a
human-authorized recorded override (HOLE B closed). This stays in Iteration 003; the cap is
raised to 25 SP rather than splitting.

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
| T058 | Record `reviewed_ref` and rebaseline each co-review to the last passing reviewed point. (Done; the `diff_hash` field is retained but superseded as the gate key by the T065 tree-id.) | FR-027, IMPL-009, TG-013 | Always-on Phase A | 1.50 | Implementer | `scripts/internal/continuous-co-review/checkpoint-diff-provider.ps1`; `scripts/internal/continuous-co-review/checkpoint-review-orchestrator.ps1`; `scripts/internal/continuous-co-review/review-run-index-writer.ps1` | done | Implementer | Committed `bd6ebebc`/`27343ce5`; resolver/rebaseline/spine tests green. | PASS |
| (fix) | Reviewer-spawn timeout/orphan robustness fix (bound stdin write; kill orphaned child). | NFR-001, INT-004 | Always-on Phase A | 1.00 | Reviewer | `scripts/internal/continuous-co-review/reviewer-host-adapter-claude-prompt.ps1` | done | Reviewer | Committed `3230e9e1`; adapter tests 4/4 incl. real-process shim. | PASS |
| T061 | First gate-floor decision logic (diff-from-baseline `diff_hash` freshness). Delivered, then INVALIDATED by the feature's own 145 co-review (HOLE A/B). Superseded by T067. | FR-025, NFR-001, TG-013 | Always-on Phase A | 2.00 | Reviewer | `scripts/internal/continuous-co-review/review-signoff-evidence-gate.ps1` | needs-rework | Reviewer | Committed `717c423f`/`e8493b8a` (8/8 unit tests), then HOLE A/B found; re-architected in T067. | SUPERSEDED |
| T065 | Reviewed-state digest helper: content-addressed tree-id via temp-index `write-tree`, including gitignored SOURCE minus the secret/ambient denylist; empty-tree no-content guard. With determinism / gitignored-in / secret-out / drift / empty tests. | FR-025, SEC-002, NFR-001, TG-013 | Always-on Phase A | 3.00 | Architect | `scripts/internal/continuous-co-review/reviewed-state-digest.ps1`; `tests/continuous-co-review/**` | planned | | | |
| T066 | Record `reviewed_tree_id` on the run record; replace the scope filter in the last-passing resolver with lineage (`git merge-base --is-ancestor`) plus chain-to-anchor verification. | FR-025, FR-027, TG-013 | Always-on Phase A | 2.50 | Architect | `scripts/internal/continuous-co-review/review-run-index-writer.ps1`; `tests/continuous-co-review/**` | planned | | | |
| T067 | Re-architect the gate (supersedes T061): tree-id-equality freshness + chain-to-merge-base-anchor verification + empty-tree guard + fail-closed git handling + human-authorized recorded override. Falsifying tests: HOLE A blocks, HOLE B blocks, cross-feature, empty, fail-closed. | FR-025, SC-019, SC-020, NFR-001, TG-013 | Always-on Phase A | 3.50 | Reviewer | `scripts/internal/continuous-co-review/review-signoff-evidence-gate.ps1`; `tests/continuous-co-review/**` | planned | | | |
| T068 | Producer auto-anchoring: orchestrator + `specrew-review.ps1` anchor signoff-bearing runs to the last-pass (merge-base-with-trunk fallback), record the digest, flag exploratory custom-baseline runs as non-signoff; configurable trunk name (default `main`). | FR-025, FR-027, INT-004, TG-013 | Always-on Phase A | 2.50 | Implementer | `scripts/internal/continuous-co-review/checkpoint-review-orchestrator.ps1`; `scripts/specrew-review.ps1`; `tests/continuous-co-review/**` | planned | | | |
| T069 | Retire the diff-hash freshness path as the gate key; keep the reviewable diff only for the reviewer's context bundle; remove the NEW-5 dead full-diff and reconcile the change-set provider. | FR-025, NFR-001, TG-013 | Always-on Phase A | 1.50 | Implementer | `scripts/internal/continuous-co-review/checkpoint-diff-provider.ps1`; `scripts/internal/continuous-co-review/review-signoff-evidence-gate.ps1`; `tests/continuous-co-review/**` | planned | | | |
| T059 | Gate-review dispatcher and gate-keyed registry: real-checkpoint-vs-casual-yield and gate detection, with code@implement as the sole registrant. | FR-032, SC-023, IMPL-004, TG-013 | Always-on Phase A | 2.50 | Architect | `scripts/internal/continuous-co-review/gate-review-dispatcher.ps1`; `scripts/internal/continuous-co-review/gate-review-registry.ps1`; `scripts/internal/continuous-co-review/_load.ps1`; `tests/continuous-co-review/**` | planned | | | |
| T060 | Wire the dispatcher to the checkpoint-review orchestrator so a registered implement checkpoint reviews its increment and writes durable evidence. | FR-024, INT-004, TG-013 | Always-on Phase A | 1.00 | Implementer | `scripts/internal/continuous-co-review/gate-review-dispatcher.ps1`; `scripts/internal/continuous-co-review/checkpoint-review-orchestrator.ps1`; `tests/continuous-co-review/**` | planned | | | |
| T062 | One-time per-project navigator authorization for automatic runs; blocking-finding escalation under the two-round convergence cap. | FR-028, FR-029, SC-021, NFR-005, SEC-004 | Always-on Phase A | 1.25 | Spec Steward | `scripts/internal/continuous-co-review/reviewer-authorization-gate.ps1`; `scripts/internal/continuous-co-review/inline-review-gate-evaluator.ps1`; `tests/continuous-co-review/**` | planned | | | |
| T063 | Delayed-stdin reviewer-spawn regression test proving the timeout bounds a stalled large-stdin child and no child is orphaned. | NFR-001, INT-004 | Always-on Phase A | 0.75 | Reviewer | `tests/continuous-co-review/**` | planned | | | |
| T064 | Iteration 003 closeout validation: full continuous-co-review suite green, the HOLE A and HOLE B repros now BLOCK, dispatcher fixtures, protected-surface guard (no F-184 edits), traceability. | FR-025, FR-032, SC-006, SC-019, SC-020, SC-023, TG-013 | Always-on Phase A | 1.00 | Reviewer | `tests/continuous-co-review/**`; `specs/197-continuous-co-review/iterations/003/**` | planned | | | |

## Effort Model

| Setting | Value | Notes |
| ------- | ----- | ----- |
| Effort Unit | story_points | Unit used in task effort, capacity, and retro variance. |
| Capacity per Iteration | 25 | Maximum planned effort; raised 20->25 (maintainer-authorized) to keep the gate re-architecture in Iteration 003 instead of splitting. |
| Iteration Bounding | scope | `scope` keeps requirements fixed; time varies. |
| Time Limit (hours) | n/a | Not used for this scope-bounded slice. |
| Overcommit Threshold | 1.0 | Planned effort must stay at or below 25 story_points. |
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
