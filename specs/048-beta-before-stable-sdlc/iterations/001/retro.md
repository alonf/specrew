# Retrospective: Iteration 001

**Schema**: v1
**Date**: 2026-05-26
**Completed At**: 2026-05-26T18:31:32Z
**Overall Outcome**: review accepted; retro pending signoff; iteration 001 scope delivered with one resolved review finding

## Estimation Accuracy

| Task | Estimated | Actual | Delta |
| ---- | --------- | ------ | ----- |
| T001 | 1 | 1 | 0 |
| T002 | 2 | 2 | 0 |
| T003 | 1 | 1 | 0 |
| T004 | 2 | 2 | 0 |
| T005 | 1 | 1 | 0 |
| T006 | 1 | 1 | 0 |
| T007 | 1 | 2 | +1 |

**Average task variance**: +0.14 SP. **Capacity utilization**: 10/20 SP
actual against 9/20 SP planned.

The +1 SP variance belongs to review rework: Step 13 originally said to tag the
merge commit as stable. Review caught that a failed beta loop would make that
wording tag stale pre-fix code. Commit `ffd56d08` changed Step 13 to tag the
PASS-validated commit and added focused assertions.

## Phase Variance

| Phase | Estimated | Actual | Delta | Notes |
| ----- | --------- | ------ | ----- | ----- |
| Planning | 0 | 0 | 0 | Scope and hardening gate were already approved before implementation continued. |
| Implementation | 9 | 9 | 0 | T001-T007 delivered the planned prompt/docs/tests/metadata/mirror-verification slice. |
| Review | 0 | 1 | +1 | Review found and fixed the Step 13 stable-tag target ambiguity. |
| Rework | 0 | 0 | 0 | The only rework is counted in review because it was found before retro. |

## Drift Summary

- Total requirement drift events: 0.
- Total review findings: 1, resolved before retro.
- Deferred by design: release audit helper, CLI/schema, and
  `release_audit_direct_to_main` behavior remain iteration 002 scope.
- Out-of-scope cleanup candidate: [README.md](file:///C:/Dev/Specrew/README.md)
  stale version pointer for `0.27.5`; consider refreshing it in the v0.27.6
  cleanup path or automating README version stamping.

## What Went Well

- The TDD sequence stayed useful: T001 and T003 failed red, then T002 and T004
  made the coordinator and docs fixtures green.
- The coordinator template split landed in the right places: generated start
  handoff, response guidance, decision guidance, source governance template,
  and deployed `.specify/` mirror.
- Mirror parity was verified explicitly, including the v0.27.5 deploy-script
  pattern where only `hooks/` is optional and all other missing items stay
  corrupt-package failures.
- Review found a real semantic bug in prose-only release instructions before
  it became lifecycle behavior.

## What Did Not Go Well

### Linear release prose hid a fail-loop edge case

Step 13's original "tag the merge commit" phrasing was acceptable only for the
happy path where `beta.1` passes. Once Step 12 allows `beta.2` after a fix on
main, stable must tag the commit that produced the passing beta. The focused
test now catches this, but it shows that SDLC prose needs branch-state and
loop-state assertions, not just step labels.

### Metadata updates need careful scope language

Proposal 060 and Proposal 131 now record active-branch shipped work without
claiming iteration 002 audit automation. That distinction took extra attention
because proposal metadata can easily overstate delivery when one feature bundles
part of several proposals.

### Validator WARNs are useful but noisy before closeout

Governance validation passed, but repeated runs surfaced the known
[README.md](file:///C:/Dev/Specrew/README.md) version WARN and a missing
dashboard WARN once review artifacts existed. The README warning is a real
cleanup candidate outside this scope. The dashboard warning is expected until
iteration closeout auto-render work happens, but it still adds noise during the
review/retro window.

## Improvement Actions

1. **Owner**: Planner / Implementer | **Phase**: F-048 iteration 002 planning |
   **Type**: release-state model | **Expected effect**: Model beta loops as
   "candidate commit" state in the release audit schema so stable promotion
   always points to the PASS-validated commit.
2. **Owner**: Spec Steward | **Phase**: v0.27.6 cleanup | **Type**:
   documentation hygiene | **Expected effect**: Refresh the README version
   pointer or add an automated README version stamp so hotfix releases do not
   leave stale public-readiness WARNs.
3. **Owner**: Reviewer | **Phase**: future prompt/docs slices | **Type**:
   test-design | **Expected effect**: Add at least one non-happy-path assertion
   whenever lifecycle prose includes a loop or retry path.
4. **Owner**: Implementer / Proposal 132 | **Phase**: future mirror-parity
   hardening | **Type**: validation | **Expected effect**: Convert the T006
   manual SHA256 parity check into validator-backed mirror parity for mirrored
   extension files.
5. **Owner**: Reviewer / Implementer | **Phase**: F-048 iteration 001 retro closeout | **Type**: FileList packaging integrity | **Expected effect**: Any new file added under a FileList-shipped directory MUST be added to FileList in the same commit + verified via Save-Module spot-check before tagging. Prevents shipping incomplete/broken module packages due to FileList omissions (e.g., hooks/ omissions in v0.27.4, release-discipline.md in v0.27.6-beta.1).

## Calibration Suggestion

- **Suggested capacity adjustment for next iteration**: keep 20 SP.
- **Rationale**: The iteration landed at 10/20 SP after review rework. The +1
  variance was a valuable semantic correction, not evidence of overcommit.
  Iteration 002 has more implementation risk because it introduces audit
  schema/CLI/config behavior, so keep the same cap but preserve explicit
  hardening review before code.

## Signals For Next Iteration

- Treat the release audit record as a state machine, not a flat checklist:
  merge commit, beta tag commit, PASS-validated commit, stable tag commit, and
  audit commit may differ.
- Keep the locked-main trailing one-file PR path as the default design and the
  direct-main path as an explicit shortcut.
- Do not start new feature work after stable publication until release audit
  capture and Step 14 stop are complete.
