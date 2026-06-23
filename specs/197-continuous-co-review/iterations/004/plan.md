# Iteration Plan: 004

**Schema**: v1
**Spec**: [../../spec.md](../../spec.md)
**Status**: executing
**Capacity**: 10.50/20 story_points
**Started**: 2026-06-23
**Completed**:

<!--
  Validator schema (canonical):
  - Iteration Status: planning | executing | reviewing | retro | complete | abandoned
  - Capacity: `<consumed>/<cap> <unit>` with NO trailing prose.
  - Task Status: planned | in-progress | done | needs-rework | deferred | blocked
-->

## Scope Summary

Iteration 004 (Phase B, part 1) on the post-185-merge base (`6c502c20`): the #2885 Stop-hook
latency fix (A) and the gate enforcement wiring (C). The async Stop-hook navigator (B) is
Iteration 005; the reviewer-runs-in-repo model (D) is dropped. No F-184 protected-surface
edits (confirmed by investigation; the registry, `sync-boundary-state.ps1`, the bootstrap
capture accessor, and the providers are all non-protected).

| Requirement / Issue | Summary | Slice |
| ------------------- | ------- | ----- |
| #2885 | Stop-hook latency: parse the transcript tail once per stop and share it. | A |
| FR-025 | Wire the deterministic gate floor into boundary-sync (opt-in) so signoff refuses without fresh co-review evidence. | C |

## Tasks

| Task | Title | Requirement | Effort | Owner | Owner File Globs | Status |
| ---- | ----- | ----------- | ------ | ----- | ---------------- | ------ |
| T070 | Parse-once-and-share: parse the transcript tail ONCE at the top of `Update-SpecrewRollingHandover` and pass the shared parsed turns to the verdict/packet/conversation-tail consumers (each keeps its own raw/flattened + synthetic-user-turn transform on a COPY). | #2885 | 3.00 | Implementer | `scripts/internal/bootstrap/ConversationCaptureAccessor.ps1` | done |
| T071 | Conformance-provider memo. SUBSUMED (measured, 2026-06-23): the conformance provider does NOT redundantly re-parse — its last-assistant read is a backward early-exit (`10 ms`, parses ~a few lines not 200), its packet read is gated by `$hasPending` AND already memoized by T070, and the whole expensive block is skipped on no-trigger/in-workshop stops (185's PERF gate). A forced memo would REGRESS the common case (full-500 parse vs 10 ms early-exit). No code warranted. | #2885 | 0.00 | Implementer | (none — subsumed) | deferred |
| T072 | Add the missing unit tests for the bootstrap parse functions: parse-once correctness (the 3 consumers' outputs are unchanged vs the per-consumer parse) + a timing/regression guard so the latency cannot silently return. | #2885 | 2.00 | Reviewer | `tests/continuous-co-review/unit/transcript-parse-once.Tests.ps1` | done |
| T073 | Gate enforcement wiring: call `Assert-ContinuousCoReviewSignoffGate` in `Invoke-SpecrewBoundaryStateSync` at the review-signoff boundary, gated by an opt-in config flag (default OFF). (Extensions copy is a thin dispatcher — no logic mirror needed; logic lives in a testable seam.) | FR-025, SC-019, SC-020 | 2.50 | Reviewer | `scripts/internal/sync-boundary-state.ps1`; `scripts/internal/continuous-co-review/signoff-gate-wiring.ps1` | done |
| T074 | Gate-wiring tests: with the flag ON, review-signoff is refused without fresh co-review evidence and allowed with it; with the flag OFF, no-op; the boundary-sync integration path. | FR-025, SC-019, SC-020 | 2.00 | Reviewer | `tests/continuous-co-review/unit/signoff-gate-wiring.Tests.ps1` | done |
| T075 | Iteration 004 closeout validation: full suite green, #2885 before/after latency measured + recorded, gate enforcement proven, protected-surface guard (no F-184 edits), Proposal 145 review. | #2885, FR-025, SC-006 | 1.00 | Reviewer | `tests/**`; `specs/197-continuous-co-review/iterations/004/**` | in-progress |

## Effort Model

| Setting | Value | Notes |
| ------- | ----- | ----- |
| Effort Unit | story_points | Unit used in task effort, capacity, and retro variance. |
| Capacity per Iteration | 20 | Maximum planned effort before overcommit guidance applies. |
| Iteration Bounding | scope | `scope` keeps requirements fixed; time varies. |
| Overcommit Threshold | 1.0 | Planned effort must stay at or below 20 story_points. |
| Calibration Enabled | true | Retro compares planned and actual effort. |

## Traceability Summary

- In-scope: #2885 (Stop-hook latency) + FR-025 (gate enforcement wiring, opt-in).
- Deferred: B async navigator (FR-026/030/031) -> Iteration 005; D reviewer-execution dropped.
- Subsumed: T071 (conformance memo) -> measured unwarranted (see the task row); -1.50 SP.
- Capacity status: PASS, 10.50/20 story_points.
- #2885 measured win (2026-06-23, 2000-line transcript): handover 3-consumer parse 1,400 ms -> 342 ms (75.5% / 1,057 ms saved per stop); conformance early-exit 10 ms.

## Notes

- No F-184 protected-surface edits. The #2885 fix touches the non-protected, non-mirrored
  bootstrap capture accessor + the providers; C touches the non-protected boundary-sync engine.
- The gate flag defaults OFF so existing governed projects are not abruptly blocked before B
  (the auto-fire) makes co-review seamless; 197's own dogfood can opt in.
