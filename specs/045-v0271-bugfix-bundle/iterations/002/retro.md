# Retrospective: Iteration 002

**Schema**: v1
**Date**: 2026-05-25
**Completed At**: 2026-05-25T18:33:50Z
**Overall Verdict**: complete

## Estimation Accuracy

| Task | Estimated | Actual | Delta |
| ---- | --------- | ------ | ----- |
| T002 | 1 | 1 | 0 |
| T016 | 2 | 2 | 0 |
| T017 | 2 | 2 | 0 |
| T018 | 1 | 1 | 0 |
| T019 | 1 | 1 | 0 |
| T020 | 1 | 1 | 0 |
| T021 | 1 | 1 | 0 |
| T022 | 2 | 2 | 0 |
| T023 | 2 | 2 | 0 |
| T024 | 1 | 1 | 0 |
| T025 | 1 | 1 | 0 |
| T026 | 1 | 1 | 0 |
| T027 | 1 | 1 | 0 |
| T028 | 1 | 1 | 0 |
| T029 | 1 | 1 | 0 |
| T030 | 1 | 1 | 0 |

**Average variance**: +/- 0

## Phase Variance

| Phase | Estimated | Actual | Delta | Notes |
| ----- | --------- | ------ | ----- | ----- |
| Planning | 0 | 0 | 0 | Iteration scope was already authorized before implementation resumed. |
| Discovery/Spikes | 0 | 0 | 0 | No spike was required; tests-first brownfield fixtures carried the discovery risk. |
| Implementation | 13 | 13 | 0 | Runtime, docs, quickstart, and changelog work stayed within the approved task surface. |
| Review/Evidence | 7 | 7 | 0 | Review added the missing feature-root diagram artifact and replaced scaffold placeholders without widening scope. |
| Rework | 0 | 0 | 0 | All review gaps were fixed-now inside the review artifact pass; no new implementation rework was required. |

## Drift Summary

- Total drift events: 0
- Resolved via spec update: 0
- Resolved via revert: 0
- Deferred: 0
- Escalated to human decision: 0

## What Went Well

- The brownfield fix stayed narrow: self-hosting `.squad/agents/` paths are canonical only when the project has `extensions/specrew-speckit/`, while non-self-hosting conflicts still block.
- Tests-first coverage caught the intended classification gap and then proved both the new self-hosting path and the preserved conflict path.
- Mirror parity remained explicit through T018 and was independently checked by the human reviewer.
- The docs addressed the publisher-check bypass risk without normalizing unsafe use, closing the before-implement concern.
- Review caught real artifact hygiene issues and recorded them as fixed-now instead of hiding them.
- The phase-label correction during T028 prevented a repeat of earlier state-drift lessons.

## What Didn't Go Well

- The startup snapshot pointed at T002 even though on-disk artifacts already had T002-T029 complete and T030 in progress. The session recovered by treating disk state as authoritative, but the resume summary was stale.
- The review scaffolder and retro scaffolder both rewrote reviewer artifacts with generic summaries after accepted review content existed. Accepted artifacts had to be restored manually.
- SC-005 evidence remains structurally weaker than the code regressions because the same agent authored the docs and executed the guided review. The result is acceptable for this milestone but should be dogfooded by a human maintainer.
- Boundary sync was first attempted with the prose boundary name `implement`; the helper requires `review-signoff`, so the retry succeeded only after the validated boundary name was used.

## Improvement Actions

1. Owner: Reviewer | Phase: next review | Type: process | Expected effect: when scaffolders are rerun after accepted review artifacts exist, compare generated output before keeping it so accepted evidence is not downgraded to generic scaffolder text.
2. Owner: Retro Facilitator | Phase: post-release dogfooding | Type: validation | Expected effect: ask a human maintainer to execute the SC-005 update/redeploy decision review cold and record the elapsed time as post-release v0.27.1 evidence.
3. Owner: Spec Steward | Phase: next resume | Type: governance | Expected effect: compare startup summary task pointers against `iterations/<NNN>/plan.md` and `state.md` before selecting the next task, and record any resume drift.

## Calibration Suggestion

- Suggested capacity adjustment: current baseline -> keep 20 story_points
- Rationale: Iteration 002 delivered exactly 20 planned story points with 0 SP variance, 0 drift events, and no deferred gaps. The workload mix of tests, runtime logic, docs, and review evidence fit the current capacity model.

## Post-Release Watch

- SC-005 should receive a cold human-maintainer timing run during v0.27.1 dogfooding. The current 2m05s evidence is source-backed and defensible, but it is still an agent self-evaluation loop.
- Keep an eye on old-style `-Agents 'copilot'` usage in brownfield regression setup. It still works, but F-044 may have established a newer canonical host-selection idiom worth aligning in a later cleanup.
