# Retrospective: Iteration 001

**Schema**: v1
**Date**: 2026-05-25
**Overall Outcome**: accepted review, awaiting iteration-closeout verdict

## Estimation Accuracy

| Scope | Planned | Delivered | Variance | Notes |
| ----- | ------- | --------- | -------- | ----- |
| Iteration capacity | 20 SP | 20 SP | 0 SP | Authorized task set T001 and T003-T015 completed exactly within the planned 20/20 story-point scope. |
| Tests-first ordering | T007-T008 before T009-T013 | delivered | 0 | Version tests failed on the intended pre-implementation gaps; recovery tests were stabilized before implementation acceptance. |
| Deferred scope | T002, T016-T030 | deferred | 0 | Brownfield, operator docs, and CHANGELOG work stayed out of iteration 001. |

**Average variance**: 0 SP at iteration scope. Per-task actual effort was not captured as a separate `Actual` column, so task-level variance remains qualitative.

## Phase Variance

| Phase | Expected | Actual | Notes |
| ----- | -------- | ------ | ----- |
| Implementation | T001, T003-T015 | completed | Tests-first ordering preserved and evidence recorded. |
| Review | accepted review packet | completed | Review artifacts were scaffolded, corrected from placeholders, validated, and committed. |
| Retro | capture lessons and next-iteration signals | completed | Retro is intentionally stopping before iteration closeout. |

## Drift Summary

- Total drift events: 0
- Resolved via spec update: 0
- Resolved via revert: 0
- Deferred: 0
- Escalated to human decision: 0
- Documentation-only state drift was fixed during review sync: `Current Phase: review-signoff`, `Iteration Status: reviewing`.

## What Went Well

- The approved scope split held: US1 and foundational repair work landed without pulling in T002, T016-T030, FR-006, FR-007, or CHANGELOG changes.
- The tests-first gate caught the intended version alias and warning defects before implementation, then passed after the runtime fixes.
- Centralizing skill-catalog state avoided duplicating missing-root semantics across start and init.
- The review packet now gives iteration 002 a clean accepted baseline with explicit deferred requirements.

## What Didn't Go Well

- The retro scaffolder failed because it expects a task `Actual` column that this iteration plan does not contain. The retro artifact was authored manually instead of changing governance code inside the patch slice.
- The first recovery-test harness run exposed a hang risk around interactive process output; the test setup needed stabilization before it could serve as reliable evidence.
- Review scaffolding initially produced broad form-vs-meaning warnings and placeholder verdicts that needed manual replacement with actual task evidence.
- Iteration 001 used numeric Effort values (`1`/`2`) as a temporary validator workaround rather than the intended t-shirt convention.

## Improvement Actions

1. Owner: Planner | Phase: iteration 002 planning | Type: process | Expected effect: Do not treat numeric Effort values from iteration 001 as a new convention. Proposal 119 (`proposals/119-effort-convention-conversion-table.md`) documents the temporary workaround; once Slice 1 ships, iteration 002 may use t-shirt letters directly or remain numeric, because both forms should validate.
2. Owner: Implementer | Phase: iteration 002 or governance hardening | Type: tooling | Expected effect: Make `scaffold-retro-artifact.ps1` tolerate plans without an `Actual` task column, or add a canonical actual-effort capture field before retro.
3. Owner: Reviewer | Phase: review scaffolding | Type: evidence | Expected effect: Treat scaffolded review warnings as prompts, not facts; replace them with artifact-specific evidence before validation.

## Calibration Suggestion

- Suggested capacity adjustment: keep 20 SP for iteration 002.
- Rationale: Iteration 001 completed its 20 SP scope, but the slice was governance-heavy and included artifact repair overhead. Keep the same capacity until iteration 002 proves whether the brownfield/docs mix has similar overhead.

## Signals For Iteration 002

- Start with T002 traceability if still needed by the canonical plan, then proceed to the approved US2/US3 work.
- FR-006 brownfield ownership work and FR-007 operator documentation must remain explicitly traceable to SC-004 and SC-005.
- Carry forward the Proposal 119 transition note so the Planner does not preserve the numeric-effort workaround as policy.
