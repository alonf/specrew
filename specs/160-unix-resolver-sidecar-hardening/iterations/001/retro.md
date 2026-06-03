# Retrospective: Iteration 001

**Schema**: v1
**Date**: 2026-06-03

## Estimation Accuracy

| Task | Estimated | Actual | Delta |
| ---- | --------- | ------ | ----- |
| T001 | 0.5 | 0.5 | 0 |
| T002 | 0.5 | 0.5 | 0 |
| T003 | 1 | 1 | 0 |
| T004 | 2 | 2 | 0 |
| T005 | 1 | 1 | 0 |
| T006 | 1 | 1 | 0 |
| T007 | 2.5 | 2.5 | 0 |
| T008 | 1 | 1 | 0 |
| T009 | 1 | 1 | 0 |
| T010 | 1.5 | 1.5 | 0 |
| T011 | 1 | 1 | 0 |
| T012 | 1.5 | 1.5 | 0 |
| T013 | 1 | 1 | 0 |
| T014 | 1 | 1 | 0 |
| T015 | 1 | 1.5 | +0.5 |
| T016 | 0.75 | 0.75 | 0 |
| T017 | 0.5 | 0.5 | 0 |
| T018 | 0.75 | 1.5 | +0.75 |

**Average variance**: +0.07 SP/task (+1.25 SP total; ~6% over 19.5 planned). The
overrun concentrated in validation/readiness (T015/T018): scaffolder-defect
remediation (state.md canonical fields, lint halts) and the maintainer-directed
Proposal 145 structured review, which added evidence work and two in-review fixes.

## Phase Variance

| Phase | Estimated | Actual | Delta | Notes |
| ----- | --------- | ------ | ----- | ----- |
| Planning | 0 | 0 | 0 | Plan/tasks closed before the iteration; before-implement scaffolding only. |
| Discovery/Spikes | 9.5 | 9.5 | 0 | Both investigations landed dispositions on the first probe/fixture run. |
| Implementation | 5 | 5 | 0 | Both conditional fix paths activated; fixes were small and focused as planned. |
| Review | 2 | 3 | +1 | Proposal 145 structured pass (maintainer-directed) + reviewer-artifact reconciliation. |
| Rework | 3 | 3.25 | +0.25 | Scaffolder-defect remediation (lint halts, state.md schema) consumed part of the buffer. |

## Drift Summary

- Total drift events: 2
- Resolved via spec update: 0
- Resolved via revert: 0
- Deferred: 1 (D-001 — codebase-wide backslash pattern → follow-up proposal)
- Escalated to human decision: 0
- Resolved in-iteration (tooling fix-now): 1 (D-002 — self-host scaffolder defects worked around locally)

## What Went Well

- **Repro-first discipline held end-to-end**: both suspicions got failing tests before any source
  change, and the git history (`645f3f2a` repro → `b460f2d5` fix) makes the ordering auditable.
- **Deterministic cross-platform fixtures worked**: the POSIX-semantics proof was achievable on a
  Windows-only workspace without guessing, exactly as the clarify decision ratified — and the CI wiring
  upgrade then gave the same test a real-Linux execution path.
- **The Proposal 145 structured review demonstrably out-performed narrative review**: two real Phase-5
  catches (CI wiring gap; the tests' own embedded-backslash anti-pattern) plus the missing lens/quality
  runtime evidence — all found in one structured pass AFTER the narrative review had already concluded
  `accepted`. Strongest single-iteration empirical signal yet for promoting Proposal 145.
- **Honest dispositions resisted overclaim**: Finding 2 shipped as "mechanism confirmed, fix narrow,
  harm reachability uncertain" rather than "bug found, bug fixed" — with the keep/expand/revert decision
  surfaced to the maintainer instead of buried.
- **Scope discipline against a tempting sweep**: the ~105-occurrence backslash pattern was filed as a
  scope-boundary deferral + follow-up recommendation, not blind-fixed mid-iteration.

## What Didn't Go Well

- **Self-host scaffolder defects caused repeated friction** (all worked around, none feature-blocking):
  `scaffold-iteration-artifacts.ps1` emits `drift-log.md` without a trailing newline (markdownlint-gate
  halt) and `state.md` without the validator-required `Current Phase`/`Iteration Status` fields; its
  quality-artifact pass silently no-ops unless the iteration plan already references Phase 2 artifacts
  (ordering trap); `scaffold-reviewer-artifacts.ps1` emits non-lint-clean markdown
  (`current-architecture.md` halted a sync) and hardcodes `needs-rework`/`tasks=0/18` digests that do not
  read the actual review verdict, forcing manual reconciliation.
- **The F-140 "tests never wired into CI" lesson recurred** within one feature of being learned — the
  enumerated-test CI pattern makes the omission silent. A structural guard (validator rule: every
  `tests/integration/*.tests.ps1` referenced by at least one workflow, or an auto-discovery lane) would
  prevent the third recurrence.
- **Review-phase requirements were discovered reactively** (Effort Model section, terminal task states,
  review.md existence) by flipping `Iteration Status` and reading validator failures — a gate-local
  checklist for "entering reviewing" (Proposal 145's two-tier model) would have made these visible upfront.

## Improvement Actions

1. Owner: Spec Steward | Phase: next planning | Type: proposal | Expected effect: file the follow-up
   proposal for the codebase-wide Unix path-separator sweep + CI lint rejecting embedded-backslash
   ChildPaths (closes D-001 and the general class behind Proposal 160).
2. Owner: Implementer | Phase: next iteration (chore slice) | Type: tooling | Expected effect: fix the
   self-host scaffolder defects (trailing newlines, canonical state.md fields, lint-clean reviewer
   artifacts, verdict-aware digests, quality-scaffold ordering) so every future iteration skips this
   friction class.
3. Owner: Reviewer | Phase: next planning | Type: process | Expected effect: add a CI-wiring check
   (validator or review checklist item) asserting new test files are referenced by a workflow — third
   line of defense for the recurring F-140 lesson.

## Calibration Suggestion

- Suggested capacity adjustment: current baseline -> keep 20 SP cap; keep conditional-fix capacity
  modeling.
- Rationale: 19.5 planned vs ~20.75 actual (+6%) with the overrun fully attributable to one-off
  scaffolder defects and a maintainer-directed extra review pass — not to estimation error in the
  investigation/fix work itself, which landed on estimate. The conditional-capacity pattern (fund the
  fix, evidence-skip if not confirmed) worked and is worth reusing for future investigation features.

## Notes

- This artifact was scaffolded from plan.md, state.md, drift-log.md, and review.md for Squad's built-in
  Retrospective ceremony; all TBD placeholders replaced with evidence from the completed iteration.
