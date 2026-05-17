# Retrospective: Iteration 001

**Schema**: v1
**Date**: 2026-05-18
**Review Boundary Ref**: `9508faf` approved review-verdict-signoff on the repaired Iteration 001 tree

## Estimation Accuracy

| Task | Estimated | Actual | Delta |
| ---- | --------- | ------ | ----- |
| I1-T001 | 1 | 1 | 0 |
| I1-T002 | 1.5 | 1.5 | 0 |
| I1-T003 | 2 | 2 | 0 |
| I1-T004 | 2 | 2 | 0 |
| I1-T005 | 1 | 1 | 0 |
| I1-T006 | 1.5 | 1.5 | 0 |
| I1-T007 | 0.5 | 0.5 | 0 |
| I1-T008 | 1 | 1 | 0 |
| I1-T009 | 1.5 | 1.5 | 0 |
| I1-T010 | 1.5 | 1.5 | 0 |
| I1-T011 | 1 | 1 | 0 |
| I1-T012 | 0.5 | 0.5 | 0 |
| I1-T013 | 0.5 | 0.5 | 0 |
| I1-T014 | 0.5 | 0.5 | 0 |

**Total Estimated**: 16 story_points  
**Total Actual**: 16 story_points  
**Average variance**: +/- 0

The iteration held zero variance even after two bounded repairs (`87bac84`, `71768e8`) and the corrected-scope review rerun because the repair work stayed inside the already-authorized Iteration 001 slice.

## Phase Variance

| Phase | Estimated | Actual | Delta | Notes |
| ----- | --------- | ------ | ----- | ----- |
| Planning | 1 | 1 | 0 | `0e90d1f` restored the dropped planning artifacts, and the retro boundary repaired the missing per-iteration `Phase Baseline` table so lifecycle scaffolds remained usable. |
| Discovery/Spikes | 0.5 | 0.5 | 0 | Discovery stayed bounded to concrete failures instead of widening into Iteration 002 exploration. |
| Implementation | 12 | 12 | 0 | Boundary sync, stale-state detection, and module-version warning work all landed inside the planned Iteration 001 scope. |
| Review | 1.5 | 1.5 | 0 | The reviewer reran the exact authorized scope, validator lane, and three integration suites without reopening deferred requirements. |
| Rework | 1 | 1 | 0 | The literal-`HEAD` repair and version-warning observability repair consumed the reserved repair lane without spilling into a new task band. |

## Drift Summary

- **Total drift events**: 1
- **Implementation-repaired**: 1
- **Resolved via spec update**: 0
- **Resolved via revert**: 0
- **Deferred**: 0
- **Escalated to human decision**: 0

## Key Lessons Captured

### 1. Missing planning-artifact recovery needs a second check for canonical iteration scaffolds

`0e90d1f` correctly restored the feature-level planning artifacts (`research.md`, `data-model.md`, `quickstart.md`, `contracts/`) after the merge drop, and that preserved Iteration 001 authorization. But the retro boundary still failed on the first scaffold attempt because `iterations/001/plan.md` lacked the canonical `## Phase Baseline` table required by `scaffold-retro-artifact.ps1`.

**Process lesson**: recovering missing planning artifacts is not complete until both layers are green: feature-level design artifacts **and** the canonical per-iteration bookkeeping tables that downstream ceremonies depend on.

### 2. Boundary-state automation must persist concrete commit hashes, not symbolic refs

The sync-boundary-state wrapper initially allowed literal `HEAD` to flow into `auth_commit_hash`, which is a fragile truth surface for durable session-state files. Commit `87bac84` repaired that by resolving literal `HEAD` to the concrete commit hash before the boundary write lands.

**Process lesson**: lifecycle state should only record stable commit identities. Wrapper-path tests must exercise symbolic-ref inputs explicitly, because boundary commands often receive `HEAD` in real operation even when downstream artifacts require immutable hashes.

### 3. Warning correctness is not enough; observability in CI is part of the contract

The version-mismatch lane already had the right FR-026 warning text, but the warning was invisible to the integration harness until `71768e8` added the running-manifest fallback and emitted the message on standard output. The feature was logically close, yet the contract was still incomplete because CI could not observe the exact user-facing warning.

**Process lesson**: non-blocking warnings still need explicit observability tests. If CI cannot see the exact message, the user-facing requirement is only partially delivered.

### 4. The reviewer was right to trust the iteration plan over memory

The human scope-correction authorization paste restated FR ranges from memory and drifted beyond the actual Iteration 001 contract. The reviewer caught the mistake by checking `specs\020-session-state-durability\iterations\001\plan.md` Scope Guardrails instead of trusting recollection, and the corrected review rerun stayed bounded to FR-001..005, FR-015..020, and FR-025..028.

**Process lesson**: human-authored authorization pastes must cite the iteration plan as the authoritative scope source. Memory is not a governance surface.

## What Went Well

1. **Zero-variance execution survived real repair pressure.** The bounded repairs stayed inside the Iteration 001 envelope, so truthful task actuals remained 16/16 story points.
2. **The reviewer enforced scope truth instead of narrative convenience.** Checking the iteration plan against the authorization paste prevented accidental widening into Iteration 002 requirements.
3. **Validation stayed green at the review→retro transition.** Governance validation plus `boundary-sync-atomicity.tests.ps1`, `stale-state-detection.tests.ps1`, and `version-checks.tests.ps1` all reran cleanly on the approved tree.

## What Didn't Go Well

1. **Planning-artifact recovery looked complete too early.** Restoring the big missing files was necessary, but the missing `Phase Baseline` table still blocked the first retro scaffold attempt.
2. **Two defects were only proven at the integration boundary.** The literal-`HEAD` durability bug and the version-warning observability gap both required repair after the initial implementation pass.
3. **A human authorization paste drifted because it cited memory instead of the iteration plan.** That is a repeatable governance failure mode, not a one-off typo.

## Improvement Actions

1. **Owner:** Planner + Retro Facilitator | **Phase:** next planning boundary | **Type:** process | **Action:** Add a pre-review / pre-retro checklist step that verifies the iteration plan still contains the canonical scaffold sections required by downstream artifacts, especially `## Phase Baseline`.  
   **Expected effect:** Future retro scaffolds do not fail after feature-level artifact recovery appears complete.

2. **Owner:** Implementer + Test steward | **Phase:** next session-state automation change | **Type:** implementation | **Action:** Keep wrapper-path regression coverage that feeds literal `HEAD` through the public sync script and asserts a concrete hash is persisted.  
   **Expected effect:** Durable session-state files cannot regress back to symbolic-ref truth.

3. **Owner:** Reviewer + authorization requester | **Phase:** next review authorization | **Type:** process | **Action:** Cite `iterations/<NNN>/plan.md` Scope Guardrails directly in any human authorization paste rather than restating FR ranges from memory.  
   **Expected effect:** Scope-correction drift is caught before review starts instead of during repair.

4. **Owner:** Implementer + Reviewer | **Phase:** next warning-surface feature | **Type:** testability | **Action:** Treat stdout/stderr capture as part of the requirement when warning text must be observable in CI or automation.  
   **Expected effect:** User-facing warnings remain exact and test-visible without another observability repair.

## Calibration Suggestion

- **Suggested capacity adjustment**: keep the 20 story_point baseline unchanged.
- **Rationale**: Iteration 001 delivered 16 planned vs 16 actual story_points. The friction came from artifact truth and observability discipline, not from over-commitment.

## Notes

- This artifact was scaffolded from plan.md, state.md, drift-log.md, and review.md for Squad's built-in Retrospective ceremony.
- The key repair-cycle lessons captured here are: missing planning-artifact recovery, literal-`HEAD` durability repair, version-check warning observability repair, and corrected-scope authorization source-of-truth discipline.
- Retro boundary is complete. Iteration-closeout may begin, but Iteration 002 remains unopened and separately authorized.
