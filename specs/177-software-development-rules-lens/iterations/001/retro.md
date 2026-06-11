# Retrospective: Iteration 001

**Schema**: v1
**Date**: 2026-06-10

## Estimation Accuracy

(Agent-driven session; "Actual" = scope completion, not wall-clock SP burndown. All nine tasks delivered
their scope with no per-task rework; the variance this iteration was in the REVIEW phase, not implementation.)

| Task | Estimated | Actual | Delta |
| ---- | --------- | ------ | ----- |
| T001 | 3 | 3 | 0 |
| T002 | 1.5 | 1.5 | 0 |
| T003 | 2.5 | 2.5 | 0 |
| T004 | 0.5 | 0.5 | 0 |
| T005 | 2.5 | 2.5 | 0 |
| T006 | 1 | 1 | 0 |
| T007 | 1 | 1 | 0 |
| T008 | 1 | 1 | 0 |
| T009 | 0.5 | 0.5 | 0 |

**Average variance**: ~0 on implementation; REVIEW phase ran over (two send-backs on review-artifact consistency).

## Phase Variance

| Phase | Estimated | Actual | Delta | Notes |
| ----- | --------- | ------ | ----- | ----- |
| Planning | baseline | baseline | 0 | clean; design-analysis co-design + plan-stage additions absorbed without churn. |
| Discovery/Spikes | n/a | n/a | n/a | none. |
| Implementation | 13.5 SP | 13.5 SP | 0 | on scope; constrained-YAML pattern reused from product-domain; no blockers. |
| Review | light | OVER | + | two human send-backs: stale sibling reviewer artifacts + missing Phase 0-7 structure. The real cost of the iteration. |
| Rework | 0 | review-only | + | no implementation rework; all rework was review-artifact reconciliation. |

## Drift Summary

- Total drift events: 1 (D-001, conduct-driven registration vs the deterministic applicability-map).
- Resolved via implementation-choice: 1 (conduct-driven, matching the product-domain precedent).
- Deferred: 0 · Escalated: 0.

## What Went Well

- The intake **design workshop co-design** caught the load-bearing decisions early (data-driven catalog vs
  prose; one guidance skill + a thin system-prompt pointer; baseline+overlay; guideline-first ingestion).
- The **data-driven catalog + constrained-YAML writer** reused the proven product-domain pattern (no new
  powershell-yaml dependency); round-trip + schema validation + overlay-never-drops are unit-proven.
- The **human review worked as designed**: it caught real review-artifact inconsistencies (stale siblings,
  baseline drift, missing 145 structure) that the validator's PASS did not — evidence over form.
- State-truth self-healing: the form-vs-meaning check surfaced the `planned`-vs-`done` gap, which was then
  corrected.

## What Didn't Go Well

- **Reviewer-artifact staleness (the dominant friction)**: regenerating only `code-map.md` left its
  siblings (coverage-evidence / reviewer-index / dependency-report) preserved-stale from the first scaffold
  run — an internally inconsistent packet that took two send-backs to fully reconcile.
- The **scaffolder `-Force` defect** (`ShouldProcess` null-ref) blocked clean regeneration, forcing a
  delete-all-then-regenerate workaround.
- The **review-packet self-reference problem**: a packet that records a file count / commit range is
  invalidated the moment the packet itself is committed (its own commit changes HEAD + branch metadata).

## Methodology learning (carried from the review-signoff verdict)

**Classification (maintainer ruling):** the two remaining review mismatches are **review-artifact
self-reference / branch-metadata drift, NOT implementation defects** — committing the review packet
immediately makes its own count/commit-range/ahead-behind metadata stale; that is inherent to the packet
committing itself, not a fault in F-177.

**Fix for future Proposal-145-style packets (carried instruction):** the packet schema needs three
*separate* fields so committing it does not make its own metadata stale:

- `reviewed_implementation_head` — the implementation HEAD the review actually covers.
- `artifact_commit` — the commit that holds the review packet itself (expected to be HEAD+1).
- `current_branch_status` — the live ahead/behind, understood to drift after the artifact commit.

This is a **proposal candidate** (a Proposal 145 amendment, or a small slice): separate
what-was-reviewed from where-the-packet-lives from live-branch-state, and have the form-vs-meaning check
diff against `reviewed_implementation_head`, not raw HEAD.

## Improvement Actions

1. Owner: Implementer | Phase: review | Type: process | **Always regenerate ALL reviewer artifacts together** (delete-all + re-scaffold), never just one — siblings preserved-stale was the dominant friction this iteration.
2. Owner: maintainer | Phase: next | Type: proposal | **File the 145-packet self-reference fix** (`reviewed_implementation_head` / `artifact_commit` / `current_branch_status`) — the carried learning above.
3. Owner: maintainer | Phase: next | Type: tooling | **File the scaffolder `-Force` defect** (`ShouldProcess` null-ref) so regeneration does not need the delete-all workaround.

## Calibration Suggestion

- Suggested capacity adjustment: current baseline (20 SP) -> no change. i1 ran at 13.5 SP on scope.
- Rationale: implementation variance ~0; the iteration's real cost was review-artifact reconciliation, a
  process/tooling fix (above), not a sizing miss.

## Signals for Next Iteration (i2)

- The **deployed runtime dogfood** (SC-004/SC-007/SC-008) is i2's gate — installed-module layout, fresh
  `specrew init`, not the dev tree.
- Carry the tracked follow-ups: the `Deploy-SpecrewSkill` extraction sibling + planned Proposal 178
  (dependency-selection automation) + the 145-packet-fields proposal above.

## Notes

- Scaffolded from plan.md/state.md/drift-log.md/review.md; placeholders replaced with iteration evidence.
- Review verdict: accepted (with instructions, carried above).
