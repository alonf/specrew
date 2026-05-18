# Retrospective: Iteration 002

**Schema**: v1
**Date**: 2026-05-18
**Review Boundary Ref**: `2b35621` recorded review-verdict-signoff after the accepted rerun on HEAD `5845b73`

## Estimation Accuracy

| Task | Estimated | Actual | Delta |
| ---- | --------- | ------ | ----- |
| I2-T001 | 0.5 | 0.5 | 0 |
| I2-T002 | 1.5 | 1.5 | 0 |
| I2-T003 | 1 | 1 | 0 |
| I2-T004 | 1 | 1 | 0 |
| I2-T005 | 1.5 | 1.5 | 0 |
| I2-T006 | 1 | 1 | 0 |
| I2-T007 | 1 | 1 | 0 |
| I2-T008 | 1 | 1 | 0 |
| I2-T009 | 0.5 | 0.5 | 0 |
| I2-T010 | 1.5 | 1.5 | 0 |
| I2-T011 | 0.5 | 0.5 | 0 |
| I2-T012 | 0.5 | 0.5 | 0 |
| I2-T013 | 1 | 1 | 0 |
| I2-T014 | 0.5 | 0.5 | 0 |
| I2-T015 | 0.5 | 0.5 | 0 |
| I2-T016 | 0.5 | 0.5 | 0 |
| I2-T017 | 1 | 1 | 0 |

**Average variance**: +/- 0

## Phase Variance

| Phase | Estimated | Actual | Delta | Notes |
| ----- | --------- | ------ | ----- | ----- |
| Planning | 1 | 1 | 0 | Iteration-start, validator replay, and the canonical bookkeeping scaffold all landed inside the planned ceremony lane. |
| Discovery/Spikes | 0.5 | 0.5 | 0 | Discovery stayed bounded to concrete failing-test diagnoses instead of widening into new scope. |
| Implementation | 11.5 | 11.5 | 0 | Durable task progress, cross-worktree awareness, recovery prompts, and PSGallery checks all shipped inside the planned Iteration 002 slice. |
| Review | 1.5 | 1.5 | 0 | The reviewer reran the authoritative plan scope, closed the bookkeeping-only review gap, and produced the full reviewer closeout packet without reopening execution. |
| Rework | 0.5 | 0.5 | 0 | Three distinct repair lanes each resolved in 1/3 attempts, consuming the reserved bounded-repair allowance without overrunning the iteration. |

## Drift Summary

- Total drift events: 3
- Resolved via spec update: 0
- Resolved via revert: 0
- Deferred: 0
- Escalated to human decision: 0

## What Went Well

1. **The 3-cycle repair budget worked exactly as designed.** Cross-worktree, task-progress, and PSGallery regressions each resolved in 1/3 attempts, every attempt stayed logged in `drift-log.md`, and no lane widened into another F-019-style cascade.
2. **Zero-variance delivery held even with real repair pressure.** Planned and actual story points stayed aligned because each fix remained inside the already authorized Iteration 002 scope.
3. **The accepted review stayed anchored to the iteration plan instead of memory.** The rerun closed only the real bookkeeping gaps and did not reopen already green behavior.

## What Didn't Go Well

1. **Stream-capture observability bit the team again.** Iteration 001 already surfaced the `Write-Host` versus capturable output problem, and Iteration 002 spent real diagnosis time re-checking the same failure mode on the PSGallery lane.
2. **PowerShell case-insensitive variable collisions are easy to miss.** The `$worktrees` versus `[switch]$Worktrees` bug cost a repair cycle before the review packet was green again.
3. **Closed iterations were still load-bearing for helper logic.** `task-progress.ps1` should not have treated a missing closed-iteration plan as fatal, and the permissive run also let bookkeeping in `plan.md` / `state.md` drift behind the code commits until review caught it.

## Improvement Actions

1. **Owner:** Retro Facilitator + governance maintainers | **Phase:** next governance-profile proposal | **Type:** process | **Action:** Capture the 3-cycle repair budget as a reusable governance pattern in Proposal 047 so bounded autonomous repair has an explicit default playbook.  
   **Expected effect:** Future repair lanes stay auditable and bounded without improvising the policy under pressure.

2. **Owner:** Implementer + Reviewer | **Phase:** next warning-surface or extraction change | **Type:** testability | **Action:** Add a guardrail or lint/checklist rule for capturable warning emission (`Write-Output` / pipeline-visible output) and rerun the owning suites immediately after extracting shared helpers from parent scripts.  
   **Expected effect:** Stream-capture regressions and extracted-path bugs are caught before they reach the boundary tests.

3. **Owner:** Implementer + tooling maintainers | **Phase:** next PowerShell governance hardening pass | **Type:** implementation | **Action:** Add a lint rule or explicit checklist item for case-insensitive variable collisions involving parameters and locals.  
   **Expected effect:** Switch-parameter binding bugs like `$worktrees` versus `$Worktrees` are prevented before review.

4. **Owner:** Implementer + Spec Steward | **Phase:** next session-state helper change | **Type:** implementation | **Action:** Make helpers prefer open/active iteration artifacts and consider extending `sync-boundary-state.ps1` or adjacent tooling so `plan.md` / `state.md` stay in sync at task completion, not only at boundary completion.  
   **Expected effect:** Closed iterations stop being load-bearing inputs, and long permissive runs do not accumulate bookkeeping drift that the reviewer has to correct late.

## Calibration Suggestion

- **Suggested capacity adjustment**: keep the 20 story_point baseline unchanged.
- **Rationale**: Iteration 002 delivered 15 planned versus 15 actual story_points. The main friction came from observability, PowerShell edge cases, and bookkeeping discipline rather than over-commitment.

## Notes

- This artifact was scaffolded from plan.md, state.md, drift-log.md, and review.md for Squad's built-in Retrospective ceremony.
- The key lessons captured here are: the successful 3-cycle repair-budget policy, repeated stream-capture observability pitfalls, PowerShell case-insensitive variable-collision risk, closed-iteration helper discipline, extraction-time regression replay, and bookkeeping decay during long permissive runs.
- Defensive tolerance fixed the stale-state lane, but the retro keeps the follow-up question open: future helper work should prefer open iterations rather than merely tolerating missing closed-iteration files.

**Iteration Closeout**: Pending — iteration-closeout is the only remaining authorized boundary after this completed retro.
