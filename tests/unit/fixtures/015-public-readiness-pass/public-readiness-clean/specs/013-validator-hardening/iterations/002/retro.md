# Retrospective: Iteration 002

**Schema**: v1
**Date**: 2026-05-12

## Estimation Accuracy

| Task | Estimated | Actual | Delta |
| ---- | --------- | ------ | ----- |
| T014 | 1 | 1 | 0 |
| T015 | 1 | 1 | 0 |
| T016 | 2 | 2 | 0 |
| T017 | 0.5 | 0.5 | 0 |
| T018 | 1 | 1 | 0 |
| T019 | 1 | 1 | 0 |
| T020 | 2 | 2 | 0 |
| T021 | 0.5 | 0.5 | 0 |
| T022 | 1 | 1 | 0 |
| T023 | 1 | 1 | 0 |
| T024 | 1 | 1 | 0 |
| T025 | 0.5 | 0.5 | 0 |
| T026 | 0.5 | 0.5 | 0 |
| T027 | 0.5 | 0.5 | 0 |
| T028 | 1 | 1 | 0 |
| T029 | 1 | 1 | 0 |

**Average variance**: +/- 0  
**Utilization**: 15.5/20 story_points (77.5% of capacity)

All sixteen planned tasks landed at estimated effort. The three process repairs surfaced during the slice were handled inside the already-authorized task work, so the iteration never opened a separate rework lane.

### Grouped Calibration

| Task Range | Scope | Planned | Actual | Delta |
| --- | --- | --- | --- | --- |
| T014-T017 | Approval-reuse detection and corpus graduation | 4.5 | 4.5 | 0 |
| T018-T021 | Over-claim detection and dirty-tree enforcement | 4.5 | 4.5 | 0 |
| T022-T026 | Bookkeeping-vs-behavior classifier and evidence recording | 4 | 4 | 0 |
| T027-T029 | Canonical corpus graduation, documentation follow-through, and validation lane audit | 2.5 | 2.5 | 0 |

## Phase Variance

| Phase | Estimated | Actual | Delta | Notes |
| ----- | --------- | ------ | ----- | ----- |
| Planning | 1.5 | 1.5 | 0 | The slice stayed bounded to the approved iteration-002 scope; no replanning or scope split was needed after authorization. |
| Discovery/Spikes | 0 | 0 | 0 | Iteration 001 and the accepted hardening gate already bounded the implementation path clearly. |
| Implementation | 13 | 13 | 0 | Approval-reuse, over-claim, classifier, corpus graduation, and documentation updates all landed inside the planned execution window. |
| Review | 1 | 1 | 0 | Independent review accepted the implementation boundary and the retro boundary consumed the same evidence set without reopening scope. |
| Rework | 0 | 0 | 0 | Planner-output drift repair, repo-level dirt exclusion proof, and local-noise handling were absorbed into planned tasks rather than becoming a separate cycle. |

## Drift Summary

- **Total drift events**: 3
- Resolved via spec update: 0
- Resolved via revert: 2
- Deferred: 0
- Escalated to human decision: 1
- The iteration stayed inside the approved feature scope, but three bounded process frictions had to be named explicitly: planner-output drift in `.github/copilot-instructions.md`, a false-positive dirt pattern rechecked through the lockout-chain precedent, and ambient `.claude/settings.local.json` noise on the authorization boundary.

## What Went Well

1. **The final validator-hardening slice landed without estimate drift.** Approval-reuse detection, over-claim enforcement, the bookkeeping classifier, corpus graduation, and the documentation follow-through all completed at planned effort. The team did not need to reopen scope or add hidden polish tasks to get feature `013`, validator hardening, iteration `002` to accepted review.

2. **Replay-path proof covered the exact places the workflow had previously been fragile.** `tests\integration\validator-hardening-iteration2.ps1` proved duplicate approval rejection, blanket-scope acceptance, repo-level evidence-only dirt exclusion, and classifier behavior through the real validator and `specrew-start.ps1` paths. That made the accepted review stronger than a helper-only audit and turned the prior false-positive dirt risk into mechanically rechecked evidence.

3. **Corpus graduation told the truth instead of leaving the trap list advisory.** Approval-reuse, over-claim, canonical-schema, and canonical-concern rows are now marked `Validator-enforced` with live implementation and replay-path citations. The retro can talk about those patterns as enforced governance, not as hoped-for future discipline.

## What Didn't Go Well

1. **Planner-output drift had to be repaired mid-iteration before restart guidance became noisy.** The slice exposed that `/speckit.plan` churn in `.github/copilot-instructions.md` can look behavior-affecting unless the workflow distinguishes timestamp, `## Active Technologies`, and `## Recent Changes` updates from real behavior edits. Iteration 002 fixed this with a reusable classifier and replay fixtures, but the lesson is process-level: planner-generated housekeeping needs an explicit low-noise rule before implementation starts.

2. **The lockout-chain fixture false-positive dirt incident had to be carried forward deliberately or the same pattern would have repeated.** Prior lockout-chain work showed how easy it is for evidence-only repository changes to get mistaken for closeout-blocking dirt. Iteration 002 repaired that risk by proving the exclusion path directly: dirty canonical iteration artifacts fail, while repo-level evidence traces such as `.squad\decisions.md` stay outside the blocker. The workflow only stayed honest because the team remembered to encode the old failure mode as a new replay case.

3. **Commit `c3ac63a` carried `.claude/settings.local.json` minor noise alongside the real authorization-boundary changes.** That file did not change validator truth, but it made the commit noisier than the lifecycle boundary itself needed. The retro lesson is to call out local agent-config churn explicitly as environmental noise and keep it from competing with the governed artifact story.

## Improvement Actions

1. **Owner:** Planner and restart-policy steward | **Phase:** next planning boundary | **Type:** process | **Action:** Name planner-generated `.github/copilot-instructions.md` sections up front and require the bookkeeping-vs-behavior distinction to be fixture-backed before restart guidance ships.  
   **Expected effect:** `/speckit.plan` output drift stops surfacing as a mid-iteration ambiguity and remains low-noise by design.

2. **Owner:** Test maintainer and Reviewer | **Phase:** next closeout-truth or dirt-scope change | **Type:** process | **Action:** Pair every dirty-tree blocker change with one canonical-artifact fail fixture and one repo-level evidence-only pass fixture, using the lockout-chain false-positive dirt incident as the standing precedent.  
   **Expected effect:** Future enforcement changes cannot silently reintroduce evidence-only false positives.

3. **Owner:** Coordinator and implementers | **Phase:** next lifecycle boundary commit | **Type:** process | **Action:** Keep `.claude/settings.local.json` and similar workstation-local noise out of boundary commits when possible, or explicitly label it as non-governing noise when it must travel with the tree.  
   **Expected effect:** Review, retro, and closeout boundaries stay focused on governed artifacts instead of ambient local-config churn.

## Corpus-Row Candidates

1. **Bookkeeping classifier drift for planner output** — Candidate governance row: planner-generated changes inside `.github/copilot-instructions.md` timestamp / `## Active Technologies` / `## Recent Changes` sections should not trigger restart guidance or be narrated as behavior drift. Detection would scan diffs by section and fail only when edits escape the bookkeeping-only surface.

2. **Boundary-commit local-noise exclusion** — Candidate governance row: workstation-local agent files such as `.claude/settings.local.json` can add minor noise to lifecycle-boundary commits without changing project truth. Detection would flag the presence of local-noise files in boundary commits so authors either isolate them or name them explicitly as excluded noise.

3. **No new row needed for the dirt false-positive lesson itself** — The lockout-chain incident is now covered by the strengthened `over-claim` trap row and by the iteration-2 replay harness. Reapply the existing row rather than seeding a duplicate trap.

## Calibration Suggestion

- **Suggested capacity adjustment**: keep the 20 story_point baseline unchanged.
- **Rationale**: The iteration delivered 15.5/15.5 planned story_points with zero task variance, no separate rework phase, and a clean accepted review. The observed friction was about workflow precision and noise filtering, not about over-commitment.

## Notes

- This retrospective stays specific to feature `013`, validator hardening, iteration `002`, the approval-reuse / over-claim / bookkeeping-classifier final slice.
- The retrospective boundary is complete on the current tree. Iteration closeout and feature closeout remain separate steps and are intentionally not claimed here.
- Review and regression evidence come from `specs\013-validator-hardening\iterations\002\review.md`, `specs\013-validator-hardening\iterations\002\quality\hardening-gate.md`, `specs\013-validator-hardening\quickstart.md`, `tests\integration\validator-hardening-iteration1.ps1`, `tests\integration\validator-hardening-iteration2.ps1`, the `specrew-start` regression suite, and `extensions\specrew-speckit\scripts\validate-governance.ps1 -ProjectPath .`.
