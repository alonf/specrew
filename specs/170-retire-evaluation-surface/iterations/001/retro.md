# Retrospective: Iteration 001

**Schema**: v1
**Date**: 2026-06-06

## Estimation Accuracy

| Task | Estimated | Actual | Delta |
| ---- | --------- | ------ | ----- |
| T001 | 0.25 | 0.25 | 0 |
| T002 | 0.25 | 0.25 | 0 |
| T003 | 0.25 | 0.25 | 0 |
| T004 | 0.25 | 0.25 | 0 |
| T005 | 0.25 | 0.25 | 0 |
| T006 | 0.25 | 0.25 | 0 |
| T007 | 0.5 | 0.5 | 0 |

**Average variance**: +/- 0

## Phase Variance

| Phase | Estimated | Actual | Delta | Notes |
| ----- | --------- | ------ | ----- | ----- |
| Planning | 0.5 SP | ~1 SP | +0.5 | The design-analysis gate refused the plan sync (correctly — the durable record was missing), adding an unplanned formalization round: artifact + typed packet + canonical-verdict re-ask. |
| Discovery/Spikes | 0 SP | 0 SP | 0 | None needed; adoption snapshot was substantially complete. |
| Implementation | 2 SP | 2 SP | 0 | Verification-first matrix executed as planned; both drift events handled inside task budgets. |
| Review | 0.5 SP | ~0.75 SP | +0.25 | One human send-back round: over-claimed 145 conformance + branch hygiene, missing canonical state fields, unrecorded deferral. |
| Rework | 0.25 SP | ~0.1 SP | -0.15 | Only wording/metadata rework; zero functional rework. |

## Drift Summary

- Total drift events: 2
- Resolved via spec update: 1 (DRIFT-001 — SC-004 class (c) for archived ledgers)
- Resolved via revert: 0
- Deferred: 1 (DRIFT-002 — full smoke-suite green to sibling `169-found-bug-fixes`; canonical defer entry `170-i001-drift-002-smoke-suite-defer`, approving human recorded)
- Escalated to human decision: 1 (the DRIFT-002 deferral was settled by the maintainer at the review send-back)

## What Went Well

- **Adopting ungoverned work without redoing it**: the Codex-produced implementation was wrapped in full governance (branch, spec, design gate, verification, evidence) with zero functional rework — the adoption-snapshot + verification-first pattern is reusable for "work preceded governance" situations.
- **Gate preflights caught real defects before the human did** (3 of 4 times): non-canonical hardening-gate tokens (twice), branch-parity gap, dirty-state classification — each fixed via self-send-back before the packet went out.
- **Deterministic gates earned their keep**: the design-analysis plan-gate refusal was correct (the durable decision record was genuinely missing), and the canonical-defer machinery forced the DRIFT-002 deferral to name an approving human instead of being self-approved.
- **Verification-first review added real value over implement evidence**: independent re-execution, assertion-strength diffs, and the delta-only audit (none re-trusted implement-phase claims).

## What Didn't Go Well

- **Over-claiming conformance**: review.md claimed "Proposal 145 contract" while producing none of 145's structured outputs, and claimed clean branch hygiene while the branch was 2 commits ahead with an untracked-files working tree. The human had to catch both — exactly what the preflight discipline was supposed to prevent. Pattern: *claims must be scoped to the evidence actually produced, especially when following an unshipped proposal's method*.
- **Truncated validator output hid findings**: piping validator output through `Select-Object -Last N` masked the state.md canonical-field failures; the human saw them first. Never truncate gate output during a preflight.
- **Canonical-token guesswork**: hardening-gate Evidence Basis / Runtime Evidence Status tokens were authored from memory twice before checking the validator's actual token set — two avoidable fix commits.
- **Menu-before-render recurrence**: two AskUserQuestion attempts at the design gate failed to surface the option descriptions on this host (the documented A8 tool-gravity); the verdict landed only after a plain-prose render. Proposal 165's hook is the structural fix.

## Improvement Actions

1. Owner: Crew (this host) | Phase: every gate | Type: process | Expected effect: preflights consume FULL validator output (no tail-truncation); claims in review artifacts name the exact method tier ("manual X-style" vs "X contract") — prevents both human-caught defect classes from this iteration.
2. Owner: Crew | Phase: next before-implement | Type: process | Expected effect: read the validator's canonical token sets (statuses, evidence-basis, runtime-evidence) from the shipped rules BEFORE authoring gate artifacts, eliminating token-guess fix commits.
3. Owner: maintainer (proposal queue) | Phase: backlog | Type: tooling | Expected effect: evidence for Proposal 145's structured outputs + Proposal 165's render-gate hook — both gaps manifested concretely this iteration.

## Calibration Suggestion

- Suggested capacity adjustment: current baseline -> unchanged (20 SP cap; 10.5 SP/day anchor).
- Rationale: task-level variance was zero; the overruns were boundary-ceremony rounds (design-gate formalization, review send-back), not execution variance — they argue for the process fixes above, not for capacity changes.

## Notes

- Verification-first iteration over adoption snapshot `3b6a3e0d`; the governed
  outcome is identical code to the adopted tree plus evidence, audit trail, and
  two reconciled drift events.
