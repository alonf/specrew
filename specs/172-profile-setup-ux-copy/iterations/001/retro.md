# Retrospective: Iteration 001

**Schema**: v1
**Date**: 2026-06-07

## Estimation Accuracy

| Task | Estimated | Actual | Delta |
| ---- | --------- | ------ | ----- |
| T001 | 0.5 | 0.5 | 0 |
| T002 | 1.0 | 1.0 | 0 |
| T003 | 1.0 | 1.0 | 0 |
| T004 | 0.5 | 0.5 | 0 |

**Average variance**: +/- 0

## Phase Variance

| Phase | Estimated | Actual | Delta | Notes |
| ----- | --------- | ------ | ----- | ----- |
| Planning | 0.5 SP | 0.5 SP | 0 | Proposal/spec/task artifacts were lightweight. |
| Discovery/Spikes | 0 SP | 0 SP | 0 | The issue was directly reproducible from first-run setup copy. |
| Implementation | 2 SP | 2 SP | 0 | Prompt metadata, parser helper, and tests stayed scoped. |
| Review | 0.5 SP | 0.5 SP | 0 | Manual 145-style review was sufficient for this small-fix slice. |
| Rework | 0.25 SP | 0.25 SP | 0 | Artifact-shape repair added canonical review/retro/closeout files. |

## Drift Summary

- Total drift events: 0
- Resolved via spec update: 0
- Deferred: 0
- Escalated to human decision: 0

## What Went Well

- The maintainer's new-machine dogfood surfaced a real onboarding wording gap:
  the profile prompt still felt like self-rating expertise despite Proposal 141.
- The fix preserved the stable profile schema and persona IDs while improving
  first-run comprehension.
- Producer-consumer test coverage landed with the change: metadata exists,
  questions ask for guidance, and the prompt parser accepts Enter as `auto`.

## What Didn't Go Well

- The first implementation stop did not include full Specrew iteration closeout
  artifacts. The maintainer had to ask whether review, closeout, and beta were
  followed.
- The first artifact pass used a non-canonical task table missing the `Story`
  column, which the scoped validator exposed.
- The feature initially lacked the mechanical-findings schema needed by the
  mechanical preflight.

## Improvement Actions

1. Owner: Crew | Phase: implement | Type: process | Expected effect: for small-fix slices, create the minimum canonical artifact set before the first final answer: spec, plan, tasks, state, coverage-evidence, review, reviewer artifacts, retro, dashboard, hardening gate, and quality evidence.
2. Owner: Crew | Phase: every gate | Type: process | Expected effect: run the scoped validator before claiming Specrew artifact shape is complete; do not rely on hand-authored tables.
3. Owner: Crew | Phase: review | Type: process | Expected effect: explicitly separate iteration closeout claims from beta/release claims.
4. Owner: CI follow-up | Phase: backlog | Type: test-integrity | Expected effect: Proposal 171 wires `f049-i003-intake-engine-tests.ps1` into the appropriate CI lane only after Linux-safety audit; prevents local-only profile/intake assertions from being mistaken for CI-reached proof.

## Process Notes

- Workshop artifacts intentionally omitted per maintainer instruction.
- Beta was not run; that is correct for iteration closeout and remains part of
  the later release train.
- The local-only status of `f049-i003-intake-engine-tests.ps1` is a
  pre-existing inert-test pattern, not a 172 regression; filed as Proposal 171.

## Calibration Suggestion

- Suggested capacity adjustment: unchanged.
- Rationale: the product fix was correctly sized; the additional work was
  artifact repair caused by incomplete lifecycle follow-through.
