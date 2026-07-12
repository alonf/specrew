# Iteration Plan: 003

**Schema**: v1
**Spec**: [../../spec.md](../../spec.md)
**Status**: executing
**Capacity**: 12/26 story_points
**Started**: 2026-07-11
**Completed**:

<!--
  Validator schema (canonical, enforced by validate-governance.ps1):
  - Iteration Status MUST be one of:
      planning | executing | reviewing | retro | complete | abandoned
    (Common mistakes the validator REJECTS: `approved`, `in-progress`, `done`, `ready`.)
  - Capacity format MUST be `<consumed>/<cap> <effort_unit>` with NO trailing prose on that line.
    Append explanatory notes in the Notes section at the bottom instead.
  - Task Status (in the Tasks table) MUST be one of:
      planned | in-progress | done | needs-rework | deferred | blocked
    (Note `in-progress` uses a hyphen, not an underscore. `done` not `completed`.)
-->

## Scope Summary

| Requirement | Summary | Stories |
| ----------- | ------- | ------- |
| FR-008 (W1) | Worktrees materialize outside the origin root | US2 |
| FR-009 (W2) | Origin-absolute paths stripped from reviewer context | US2 |
| FR-010 (W3) | Slim prompt + spawn contract carry worktree-only rules | US2 |
| FR-011 (W4) | Containment detector on the T100 registry, loud, never mid-flight kills | US2 |
| FR-012 (W5) | ONE path-granular machinery list: digest strip == worktree strip | US2 |
| FR-013 (W6) | Reviewer taught what is intentionally absent | US2 |
| FR-014 (W7) | Recorded-run duty via refocus floor | US3 |
| FR-015 (W8) | Recorded-run evidence wrapper; caller numbers rejected | US3 |
| FR-016 (W9) | Last-REVIEWED checkpoint identity as next baseline | US3 |
| FR-017 (W10) | Frozen-tree digest threading + in-flight dedup (T019 remainder) | US3 |
| FR-018 (W11) | Consumer-legible allowance halt | US3 |
| FR-019 (W12) | Every round counts; halt is the fix (amended) | US3 |
| FR-041 (GOV-001a) | Machinery-turn exclusion from verdict evidence | US1 |
| FR-042 (GOV-001b) | Approval tokenizer tightening + temporal-ordering guard | US1 |
| FR-043 (GOV-001c) | Exact-sequence fabrication regression fixtures | US1 |
| FR-044 (GOV-001d) | Append-only ledger correction door | US1 |

## Tasks

| Task | Title | Requirement | Story | Effort | Owner | Owner File Globs | Status | Agent | Actual | Verdict |
| ---- | ----- | ----------- | ----- | ------ | ----- | ---------------- | ------ | ----- | ------ | ------- |
| T034a | Devin-seam inspection (runs FIRST per Option B) | FR-012, FR-017 | US2 | 0.25 | Implementer | specs/198-beta2-hardening/iterations/003/** | done | — | 0.25 | — |
| T013 | Worktree relocation (system temp; no upward-walk) | FR-008 | US2 | 1.0 | Implementer | scripts/internal/continuous-co-review/worktree-review-orchestrator.ps1, scripts/internal/continuous-co-review/worktree-reviewer.ps1, tests/** | done | — | 1 | — |
| T014 | Bundle origin-path hygiene (composes with Devin design-ref plumbing) | FR-009 | US2 | 1.0 | Implementer | scripts/internal/continuous-co-review/worktree-reviewer.ps1, tests/** | done | — | 1 | — |
| T015 | Confinement contract + REQUIRED bounded in-worktree verification | FR-010, FR-013 | US2 | 0.5 | Implementer | scripts/internal/continuous-co-review/**, .specrew/review/process/** | done | — | 2.5 | — |
| T016 | Containment detector (T100 registry; loud; false-kill guard) | FR-011 | US2 | 1.0 | Implementer | scripts/internal/continuous-co-review/**, tests/** | planned | — | — | — |
| T017 | ONE machinery list (digest strip == worktree strip by construction) | FR-012 | US2 | 1.5 | Implementer | scripts/internal/continuous-co-review/**, extensions/specrew-speckit/data/**, tests/** | planned | — | — | — |
| T018 | Recorded-run evidence wrapper | FR-014, FR-015 | US3 | 1.0 | Implementer | scripts/internal/continuous-co-review/**, extensions/specrew-speckit/refocus/**, tests/** | planned | — | — | — |
| T019 | Checkpoint baselines + frozen digest threading + in-flight dedup | FR-016, FR-017 | US3 | 1.5 | Implementer | scripts/internal/continuous-co-review/continuous-co-review-navigator.ps1, tests/** | planned | — | — | — |
| T020 | Spend-allowance halt UX + two-budget accounting + resolved-against-disk disposition (pulled forward, maintainer-directed) | FR-018, FR-019 | US3 | 1.0 | Implementer | scripts/internal/continuous-co-review/**, scripts/specrew-review.ps1, tests/** | done | — | 1.5 | — |
| T030 | Machinery-turn exclusion from verdict evidence | FR-041 | US1 | 0.75 | Implementer | scripts/internal/bootstrap/ConversationCaptureAccessor.ps1, tests/integration/** | planned | — | — | — |
| T031 | Approval-tokenizer tightening + temporal-ordering + cursor-invariant guards | FR-042 | US1 | 0.5 | Implementer | scripts/internal/bootstrap/ConversationCaptureAccessor.ps1, tests/integration/** | planned | — | — | — |
| T032 | Fabrication-sequence regression fixtures (re-enable acceptance surface) | FR-043 | US1 | 0.5 | Implementer | tests/integration/verdict-capture-blocks.tests.ps1 | planned | — | — | — |
| T033 | Ledger correction door (append-only invalidation records) | FR-044 | US1 | 1.0 | Implementer | extensions/specrew-speckit/scripts/shared-governance.ps1, .specify/**, tests/** | planned | — | — | — |
| T034b | Devin cherry-pick + regression set + live-round compat (AT LANDING) | FR-012, FR-017 | US2 | 0.5 | Implementer | scripts/internal/continuous-co-review/**, tests/continuous-co-review/** | in-progress | — | — | — |

## Effort Model

| Setting | Value | Notes |
| ------- | ----- | ----- |
| Effort Unit | story_points | Unit used in task effort, capacity, and retro variance. |
| Capacity per Iteration | 26 | Maximum planned effort before overcommit guidance applies. |
| Iteration Bounding | scope | `scope` keeps requirements fixed; `time` enforces a time ceiling. |
| Time Limit (hours) | n/a | Only applies when iteration bounding is `time`. |
| Overcommit Threshold | 1.0 | Warn planners when total estimated effort exceeds 26 story_points (capacity 26 x threshold 1.0). |
| Defer Strategy | manual | Defer order if a slice spills: T033 first, then T032 — never T013-T017/T020 (priority instruction) nor T030/T031 (live fabrication class). |
| Calibration Enabled | true | When true, retrospectives should suggest future capacity adjustments. |

## Concurrency Rationale

- Current roster snapshot: Spec Steward, Planner, Implementer, Reviewer, Retro Facilitator
- Execution is serial under one Implementer in the Option B order: T034a
  first (seam inspection), then T013→T017 (containment, priority), then
  T018→T020 (round economy), then T030→T033 (capture integrity, disjoint
  files). T034b is an at-landing checkpoint, not a position: it executes
  the moment the Devin crew's design-context validation commit is
  available, wherever the iteration then stands.
- Shared-surface risk is BETWEEN CREWS, not between our tasks: our
  T013/T014/T017 edit worktree-reviewer.ps1 and the digest surfaces their
  commits also touch. Doctrine (maintainer-typed): mechanical conflicts
  resolve toward the Devin-owned design-context seam; semantic conflicts
  touching containment, authorization, evidence integrity, or fail-closed
  behavior escalate to the maintainer, never auto-resolved.
- No same-specialty parallelism proposed.

## Phase Baseline

| Phase | Estimated Effort | Notes |
| ----- | ---------------- | ----- |
| Planning | light | Design-analysis 003 (Option B) + this plan; gate passed before the plan boundary sync. |
| Discovery/Spikes | 0.25 | T034a seam inspection is the only discovery slice. |
| Implementation | 11.75 | All task execution: containment 5.0 (T013-T017) + round economy 3.5 (T018-T020) + capture integrity 2.75 (T030-T033) + T034b 0.5 at the landing checkpoint. Partition check: 0.25 + 11.75 = 12.0, the planned task total. |
| Review | 1.0 | Wall-clock allowance ABOVE the 12.0 planned task SP, at the 002 calibration (~2x historic) until T020 lands mid-iteration. |
| Rework | 0.25 | Wall-clock allowance ABOVE the planned task SP; reviewer-catch buffer at the 002 observed rate (same-day fixes). |

## Traceability Summary

- Requirement scope: FR-008..FR-019 (containment + round economy),
  FR-041..FR-044 (capture integrity), with T034 as the maintainer-instructed
  two-crew verification surface on FR-012/FR-017.
- User stories: US1 (one approval advances one boundary — capture
  integrity), US2 (reviewer containment), US3 (review rounds spend human
  budget honestly).
- Overcommit: 12.0 planned SP against the 26 cap — no deferrals required at
  planning; the defer order stands recorded in the Effort Model.

## Notes

- Option B per the recorded Human Decision (design-analysis.md), with the
  maintainer's conflict-escalation doctrine binding on T034b.
- Effort accounting: the 12.0 planned task SP partition into Discovery
  0.25 + Implementation 11.75; the Review 1.0 and Rework 0.25 rows are
  wall-clock ALLOWANCES beyond the planned task SP, giving the honest
  forecast of ~13.25 SP wall-clock (the design-analysis states ~14 as the
  conservative round; the allowance arithmetic here is the precise floor).
- The pending-artifact fallback capture remains DISABLED (DEC-198-GOV-003
  interim) throughout this iteration; re-enable only when T030-T033 pass
  the documented acceptance criteria.
- Implementation starts only on the before-implement verdict (maintainer
  instruction at the planning approval).
- Phase Baseline corrected at the maintainer's 2026-07-11 send-back: the
  first authored table summed 11.5 against the 12.0 task total and
  double-booked the review allowance as an implementation subtraction.
