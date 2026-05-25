# Iteration Plan: 002

**Schema**: v1
**Spec**: [../../spec.md](../../spec.md)
**Status**: planning
**Capacity**: 20/20 story_points
**Started**: 2026-05-25
**Completed**:

<!--
  Validator schema (canonical, enforced by validate-governance.ps1):
  - Iteration Status MUST be one of:
      planning | executing | reviewing | retro | complete | abandoned
    (Common mistakes the validator REJECTS: `approved`, `in-progress`, `done`, `ready`.)
  - Capacity format MUST be `<consumed>/<cap> <effort_unit>` with NO trailing prose on that line.
    Append explanatory notes in the Notes section at the bottom instead.
  - Task Status (in the Tasks table) MUST be one of:
      planned | in-progress | done | needs-rework | deferred | blocked
    (Note `in-progress` uses a hyphen, not an underscore. `done` not `completed`.)
-->

## Scope Summary

| Requirement | Iteration 002 Treatment | Stories |
| ----------- | ----------------------- | ------- |
| FR-001 | Preserve iteration 001 version-alias behavior through final regression only; no new runtime change planned. | US1 regression |
| FR-002 | Preserve iteration 001 version-warning behavior through final regression only; no new runtime change planned. | US1 regression |
| FR-003 | Close remaining F5-F7 finding dispositions with explicit actionable-vs-stale evidence. | Setup, US2, US3, Polish |
| FR-004 | Preserve iteration 001 start auto-repair behavior through final regression only; no new runtime change planned. | US1 regression |
| FR-005 | Preserve iteration 001 init deployable-gap behavior through final regression only; no new runtime change planned. | US1 regression |
| FR-006 | Implement and verify brownfield `.squad/agents/` canonical-source classification for self-hosting projects. | US2 |
| FR-007 | Deliver operator update/redeploy guidance and guided doc-review evidence. | US3 |
| FR-008 | Preserve mirror/governance integrity across brownfield logic, docs, quality evidence, and closeout artifacts. | Cross-cutting |

## Tasks

| Task | Title | Requirement | Story | Effort | Owner | Owner File Globs | Status | Agent | Actual | Verdict |
| ---- | ----- | ----------- | ----- | ------ | ----- | ---------------- | ------ | ----- | ------ | ------- |
| T002 | Create iteration 002 traceability matrix mapping US1-US3 to FR-001..FR-008 and SC-001..SC-006 | TG-001, TG-002, TG-003, TG-004 | Setup | 1 | Reviewer | `specs/045-v0271-bugfix-bundle/iterations/002/traceability-matrix.md` | planned | Codex |  |  |
| T016 | Extend brownfield ownership regression fixtures for self-hosting and non-self-hosting `.squad/agents/` classification | FR-006, SC-004, SC-006, TG-002 | US2 tests | 2 | Implementer | `tests/integration/brownfield-conflict-handling.ps1` | planned | Codex |  |  |
| T017 | Update canonical-source classification logic for `.squad/agents/` when `extensions/specrew-speckit/` signal exists | FR-006, SC-004, TG-002 | US2 implementation | 2 | Implementer | `extensions/specrew-speckit/scripts/brownfield-merge.ps1` | planned | Codex |  |  |
| T018 | Mirror brownfield classification change in deployed governance copy | FR-006, FR-008, SC-004, TG-002, TG-004 | US2 implementation | 1 | Implementer | `.specify/extensions/specrew-speckit/scripts/brownfield-merge.ps1` | planned | Codex |  |  |
| T019 | Record F5/F6 closure disposition and evidence pointers in iteration 002 finding ledger | FR-003, FR-006, TG-002, TG-007 | US2 evidence | 1 | Reviewer | `specs/045-v0271-bugfix-bundle/iterations/002/finding-disposition.md` | planned | Codex |  |  |
| T020 | Execute brownfield regression suite and append pass evidence | SC-004, SC-006, TG-002 | US2 evidence | 1 | Reviewer | `tests/integration/brownfield-conflict-handling.ps1`, `specs/045-v0271-bugfix-bundle/iterations/002/quality/quality-evidence.md` | planned | Codex |  |  |
| T021 | Create doc validation checklist and timing rubric for SC-005 measurement | FR-007, SC-005, TG-003 | US3 tests | 1 | Doc Steward | `specs/045-v0271-bugfix-bundle/iterations/002/quality/update-guidance-review.md` | planned | Codex |  |  |
| T022 | Update update-path guidance covering normal update, `-Force`, and publisher-check bypass safety boundaries | FR-007, SC-005, TG-003 | US3 implementation | 2 | Doc Steward | `docs/getting-started.md` | planned | Codex |  |  |
| T023 | Update operator guidance with explicit init re-deployment triggers for missing skill-catalog/runtime gaps | FR-007, SC-005, TG-003 | US3 implementation | 2 | Doc Steward | `docs/user-guide.md` | planned | Codex |  |  |
| T024 | Add stale-finding closure narrative and bounded-scope note for v0.27.1 bundle | FR-003, FR-007, TG-003, TG-007 | US3 evidence | 1 | Doc Steward | `specs/045-v0271-bugfix-bundle/iterations/002/finding-disposition.md` | planned | Codex |  |  |
| T025 | Refresh verification walkthrough with post-update redeploy decision checks | FR-007, SC-005, TG-003 | US3 evidence | 1 | Doc Steward | `specs/045-v0271-bugfix-bundle/quickstart.md` | planned | Codex |  |  |
| T026 | Execute guided doc review and capture under-3-minute decision evidence | SC-005, TG-003 | US3 evidence | 1 | Reviewer | `specs/045-v0271-bugfix-bundle/iterations/002/quality/update-guidance-review.md` | planned | Codex |  |  |
| T027 | Run mechanical checks and confirm iteration 002 outputs | FR-008, SC-006, TG-004 | Polish | 1 | Reviewer | `specs/045-v0271-bugfix-bundle/iterations/002/quality/mechanical-findings.json`, `specs/045-v0271-bugfix-bundle/iterations/002/quality/quality-evidence.md` | planned | Codex |  |  |
| T028 | Execute governance validation and record result | FR-008, TG-004 | Polish | 1 | Reviewer | `specs/045-v0271-bugfix-bundle/iterations/002/quality/quality-evidence.md` | planned | Codex |  |  |
| T029 | Verify all patch regression suites pass and summarize zero failing P0/P1 status | SC-006, TG-001, TG-002, TG-003 | Polish | 1 | Reviewer | `tests/integration/validate-versions-cli-behavior.ps1`, `tests/integration/start-recovery-flow.tests.ps1`, `tests/integration/brownfield-conflict-handling.ps1`, `specs/045-v0271-bugfix-bundle/iterations/002/quality/quality-evidence.md` | planned | Codex |  |  |
| T030 | Update v0.27.1 patch notes with bundle closure summary and stale-finding disposition references | FR-003, FR-008, TG-006, TG-007 | Polish | 1 | Doc Steward | `CHANGELOG.md` | planned | Codex |  |  |

## Effort Model

| Setting | Value | Notes |
| ------- | ----- | ----- |
| Effort Unit | story_points | Canonical capacity unit for velocity and closeout math. |
| Capacity per Iteration | 20 | Per iteration 001 retro calibration; keep capacity stable for the brownfield/docs mix. |
| Iteration Bounding | scope | Iteration 002 closes the remaining approved F-045 bundle scope. |
| Time Limit (hours) | n/a | Only applies when iteration bounding is `time`. |
| Overcommit Threshold | 1.0 | Warn planners when total estimated effort exceeds 20 story_points. |
| Defer Strategy | manual | All remaining tasks T002 and T016-T030 fit exactly in the 20 SP cap, so no deferral is currently proposed. |
| Calibration Enabled | true | Retro should evaluate whether 20 SP remains accurate after this mixed implementation/docs slice. |

## Sequencing

1. Execute T002 first to lock iteration 002 traceability before runtime/doc changes.
2. Execute T016 before T017-T018 so brownfield classification tests fail or prove the intended gap before implementation.
3. Execute T017 then T018 in sequence; the second task mirrors the first into the deployed governance copy.
4. Execute T019-T020 to record US2 disposition and runtime evidence.
5. Execute T021 before T022-T026 so the operator-doc timing rubric exists before documentation changes are judged.
6. Execute T022-T023 before T025-T026 so quickstart and guided review validate finalized guidance.
7. Execute T027-T030 only after US2 and US3 are complete.

## Concurrency Rationale

- Current roster snapshot: Spec Steward, Planner, Implementer, Reviewer, Retro Facilitator.
- No supplemental specialist is required before implementation. The source task list names Doc Steward for US3 work, but the active Specrew roster has no supplemental Doc Steward member; Codex will execute that task ownership under the baseline role routing unless the human explicitly adds a specialist.
- T017 and T018 touch mirrored copies of the same brownfield logic and should stay serial to avoid divergence.
- T022 and T023 are separable documentation files, but docs should remain serial in this iteration because T025 and T026 judge the operator decision path as a single flow.
- T027-T030 are polish/evidence tasks and must remain last to avoid stale evidence.

## Phase Baseline

| Phase | Estimated Effort | Notes |
| ----- | ---------------- | ----- |
| Planning | 0 | Scaffolding and planning only; not counted against delivery capacity. |
| Discovery/Spikes | 0 | No spike planned; tests-first brownfield coverage is the risk-reduction step. |
| Implementation | 13 | T016-T018, T021-T025, T030. |
| Review/Evidence | 7 | T002, T019-T020, T026-T029. |
| Rework | 0 | No pre-allocated buffer; any rework must stay within the approved task surface or return for human verdict. |

## Traceability Summary

- Iteration 002 active scope: T002 and T016-T030.
- Requirement coverage:
  - FR-003: T019, T024, T030
  - FR-006: T016, T017, T018, T019, T020
  - FR-007: T021, T022, T023, T024, T025, T026
  - FR-008: T018, T027, T028, T030
  - SC-004: T016, T017, T018, T020
  - SC-005: T021, T022, T023, T025, T026
  - SC-006: T016, T020, T027, T029
- Carried-forward US1 behavior is covered by T029 regression replay; no new FR-001, FR-002, FR-004, or FR-005 implementation is planned.
- T002 will produce the full US1-US3 to FR/SC traceability matrix before implementation tasks start.

## Proposal 119 Note

- Proposal 119 (`proposals/119-effort-convention-conversion-table.md`) is the canonical effort-convention follow-up.
- This plan uses numeric story-point Effort values because the active repository validator still consumes numeric capacity ledgers. This is not a policy convention for future plans; Proposal 119 defines the intended model where numeric and t-shirt inputs are both valid through a shared conversion table.
- Do not carry forward any reference to `proposals/117-validator-effort-convention-parser.md`; local duplicate Proposal 117 was reverted from main, and main's actual Proposal 117 is unrelated iteration-level lifecycle enforcement work.

## Scope and Deferred Items

- Authorized iteration 002 scope is T002 and T016-T030 only.
- Iteration 001 artifacts remain closed; iteration 002 evidence files are written under `iterations/002/`.
- Proposal 119 implementation slices are out of scope for this feature iteration; F-045 only references Proposal 119 to avoid repeating the effort-convention workaround as policy.
- No lifecycle command expansion, new boundary type, or non-bug feature work is planned.

## Planned Runtime Evidence

- `pwsh -NoProfile -ExecutionPolicy Bypass -File tests/integration/brownfield-conflict-handling.ps1`
- `pwsh -NoProfile -ExecutionPolicy Bypass -File tests/integration/validate-versions-cli-behavior.ps1`
- `pwsh -NoProfile -ExecutionPolicy Bypass -File tests/integration/start-recovery-flow.tests.ps1`
- Guided operator documentation review recorded in `specs/045-v0271-bugfix-bundle/iterations/002/quality/update-guidance-review.md`
- `pwsh -NoProfile -ExecutionPolicy Bypass -File .specify/extensions/specrew-speckit/scripts/run-mechanical-checks.ps1 -ProjectPath . -IterationPath specs/045-v0271-bugfix-bundle/iterations/002`
- `pwsh -NoProfile -ExecutionPolicy Bypass -File .specify/extensions/specrew-speckit/scripts/validate-governance.ps1 -ProjectPath . -NoCacheRead`

## Notes

- Iteration 002 scope: T002 (1 SP) + T016-T020 (7 SP) + T021-T026 (8 SP) + T027-T030 (4 SP) = 20 SP exactly.
- Plan status remains `planning` until a human before-implement verdict authorizes execution; at execution start, flip Status to `executing`.
