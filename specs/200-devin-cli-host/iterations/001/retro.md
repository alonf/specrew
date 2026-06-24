# Retrospective: Iteration 001

**Schema**: v1
**Date**: 2026-06-24

## Estimation Accuracy

| Task | Estimated | Actual | Delta |
| ---- | --------- | ------ | ----- |
| T001 | 3 | 3 | 0 |
| T002 | 2 | 2 | 0 |
| T003 | 3 | 3 | 0 |
| T004 | 3 | 3 | 0 |
| T005 | 2 | 2 | 0 |
| T006 | 1 | 1 | 0 |

**Average variance**: +/- 0

## Phase Variance

| Phase | Estimated | Actual | Delta | Notes |
| ----- | --------- | ------ | ----- | ----- |
| Planning and artifact authoring | 2 | 2 | 0 | Design gate, feature/iteration plans, and Wave B artifacts landed as scoped. |
| Discovery/spike | 3 | 3 | 0 | T001 proved outcome-2 byte-for-byte through the unchanged accessor; pinned-build sh.exe prerequisite captured. |
| Implementation | 6 | 6 | 0 | Registry seam, FileList generator, and firewall cleanup delivered without re-scoping. |
| Review and deterministic validation | 2 | 2 | 0 | 5 Slice A suites green (76 assertions); 0 mechanical findings; 0 drift. |
| Expected rework | 1 | 0 | -1 | Reserve unused; line-ending/cross-platform fixture repairs were folded into T002/T004, not a separate rework cycle. |
| **Total** | **14** | **13** | **-1** | Came in one point under the planned baseline; well within the 20-SP cap. |

## Drift Summary

- Total drift events: 0
- Resolved via spec update: 0
- Resolved via revert: 0
- Deferred: 0
- Escalated to human decision: 0

## What Went Well

- Clean Option B slice: registry-driven validation, generated FileList, and the
  purity firewall landed as one coherent extensibility seam with zero spec drift.
- The purity negative test exercises the **production** scanner path (both
  planted host literals must fail; clean tree must pass), so the firewall proof
  is behavioral, not ceremonial — confirmed independently on the maintainer run.
- The allow-list shrank 11 -> 8 with no Devin exception, proving a host is added
  by package folder rather than shared-core literals (the feature's whole point).
- FR-012 honored throughout: `ConversationCaptureAccessor.ps1` untouched; the
  Slice B parser-collision boundary preserved.
- All five Slice A deterministic suites green at review time (76 assertions, 0
  failures); CI/prepublish wiring added so the checks are enforced, not optional.

## What Didn't Go Well

- The prior session ended at `review-signoff` **without authoring review.md or
  the reviewer artifact set**, so resume had to produce the entire review before
  the human could sign off. Review-artifact authoring should be part of the
  implement -> review transition, not deferred to the next session.
- A prior-session write **clobbered redundant lifecycle-state fields**: state.md
  `Current Phase` went `before-implement` -> non-canonical `implement` and the
  iteration plan stayed `Status: executing` after review.md existed, producing a
  hard validator FAIL on resume. This is precisely the **Proposal 193** drift
  class (redundant/derivable lifecycle-state fields that hand-edits desync) — a
  data point for 193, not a Slice A defect. The repair restored canonical values.
- Local test execution relies on plain `pwsh -File` suites (Pester 3.4.0 only is
  installed); newcomers may assume `Invoke-Pester` works. Minor, but worth a note
  in quickstart/test docs for the Devin package iterations.

## Improvement Actions

1. Owner: Crew (implement phase) | Phase: implement -> review transition | Type: process | Expected effect: author review.md + reviewer artifacts as the closing step of implement so a session boundary never lands at review-signoff with no review to sign off.
2. Owner: maintainer (Proposal 193) | Phase: next planning | Type: process | Expected effect: feed the state.md/plan.md clobber into Proposal 193's redundant-lifecycle-state-field drift class so derivable fields stop desyncing on hand-edit.
3. Owner: Crew (Devin package iteration) | Phase: docs | Type: documentation | Expected effect: note the `pwsh -File` test-execution convention (vs Pester) in quickstart/test docs.

## Calibration Suggestion

- Suggested capacity adjustment: current baseline 20 SP -> 20 SP (no change)
- Rationale: iteration consumed 13 of a planned 14 within a 20 cap with zero
  drift and zero estimation variance; the model is well-calibrated for this work
  class. The 6-SP reserve was correctly not pulled forward.

## Notes

- This retro covers Slice A only. Slices C (Devin package) and D (coordinator
  eligibility + config migration) are iteration 002+ per the Option B split;
  Slice B stays deferred until Feature 197 merges.
- Signals for next iteration: carry Improvement Action 1 into the iteration-002
  plan; the registry/firewall seam established here is the foundation the Devin
  package builds on.
