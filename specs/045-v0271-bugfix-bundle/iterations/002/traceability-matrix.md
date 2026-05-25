# Traceability Matrix: Iteration 002

**Schema**: v1
**Feature**: `045-v0271-bugfix-bundle`
**Iteration**: `002`
**Date**: 2026-05-25
**Scope**: T002 and T016-T030

## Story to Requirement Coverage

| Story / Area | Requirements | Success Criteria | Iteration 002 Tasks | Evidence Target |
| --- | --- | --- | --- | --- |
| US1 carried-forward regression | FR-001, FR-002, FR-004, FR-005 | SC-001, SC-002, SC-003, SC-006 | T029 | Version and start/init regression replay in `quality/quality-evidence.md` |
| US2 brownfield ownership | FR-003, FR-006, FR-008 | SC-004, SC-006 | T016, T017, T018, T019, T020 | Brownfield tests, mirror parity, finding-disposition update |
| US3 update guidance | FR-003, FR-007 | SC-005 | T021, T022, T023, T024, T025, T026 | Timing rubric, docs diffs, guided review evidence |
| Polish and release closure | FR-003, FR-008 | SC-006 | T027, T028, T029, T030 | Mechanical checks, governance validation, full regression replay, CHANGELOG |

## Requirement to Task Coverage

| Requirement | Covered By | Notes |
| --- | --- | --- |
| FR-001 | T029 | Iteration 001 implementation is preserved; iteration 002 replays the version regression suite. |
| FR-002 | T029 | Iteration 001 warning suppression is preserved; iteration 002 replays the version regression suite. |
| FR-003 | T019, T024, T030 | Remaining F5-F7 disposition closure plus release-note summary. |
| FR-004 | T029 | Iteration 001 start auto-repair is preserved; iteration 002 replays the start recovery suite. |
| FR-005 | T029 | Iteration 001 init deployable-gap behavior is preserved; iteration 002 replays the start recovery suite. |
| FR-006 | T016, T017, T018, T019, T020 | Tests-first brownfield classification, implementation, mirror parity, evidence. |
| FR-007 | T021, T022, T023, T024, T025, T026 | Rubric-first operator docs and guided under-3-minute review evidence. |
| FR-008 | T018, T027, T028, T030 | Mirror copy, mechanical checks, governance validation, release-note governance summary. |

## Success Criteria to Task Coverage

| Success Criterion | Covered By | Evidence |
| --- | --- | --- |
| SC-001 | T029 | `validate-versions-cli-behavior.ps1` replay |
| SC-002 | T029 | `validate-versions-cli-behavior.ps1` replay |
| SC-003 | T029 | `start-recovery-flow.tests.ps1` replay |
| SC-004 | T016, T017, T018, T020 | `brownfield-conflict-handling.ps1` self-hosting and non-self-hosting fixtures |
| SC-005 | T021, T022, T023, T025, T026 | Guided doc-review rubric with under-3-minute decision evidence |
| SC-006 | T016, T020, T027, T029 | Brownfield suite, mechanical checks, full patch regression replay |

## Ordering Constraints

- T016 must run before T017-T018.
- T021 must run before T022-T026.
- T027-T030 must run after US2 and US3 are complete.
- Proposal 119 is context only; no Proposal 119 implementation tasks are in this iteration.
