# Iteration Plan: 003

**Schema**: v1
**Spec**: [../../spec.md](../../spec.md)
**Status**: planning
**Capacity**: 3.25/20 story_points
**Started**: 2026-10-21
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

Iteration 003 is the fix for the failed Copilot re-walk (SC-011, B4F-144), moved here from iteration 002 by the
maintainer's ruling of 2026-10-21 (`move the fixes to iteration 003`). Iteration 002 closed with T016 to T024 and SC-011
recorded as failed. This iteration reviews the fixes, finishes their acceptance, and runs the re-walk. **Beta4.1's
release gate sits at feature 202's closeout: no feature closeout, merge or publish until this iteration's re-walk
passes.**

| Requirement | Summary | Stories |
| ----------- | ------- | ------- |
| FR-027 | One human message, at most one recorded approval; a sub-agent's task text is never the human's (B4F-147) | US8 |
| FR-028 | A hook stands down only on a positive match with another host, on every channel the host runs, Claude's hooks under Copilot included (B4F-144, B4F-145 layer 1) | US8 |
| FR-032 | No instruction lets a question tool carry a workshop question, the product-domain question included (B4F-131) | US8 |

## Tasks

T025 to T029 were implemented and committed in iteration 002 (`2fd7f2d6`) on the maintainer's `go with the fix plan`,
before the move. They are `done` in code and not yet reviewed: this iteration's review round is their review. T030 is in
progress.

| Task | Title | Requirement | Story | Effort | Owner | Owner File Globs | Status | Agent | Actual | Verdict |
| ---- | ----- | ----------- | ----- | ------ | ----- | ---------------- | ------ | ----- | ------ | ------- |
| T025 | Committed payload probe on Copilot, Claude and Codex, with sub-agents; the deployed-hook test harness; the captured payloads as fixtures (B4F-145 layer 1) | FR-028 | US8 | 1.0 | Implementer | `tests/host-probes/**`, `tests/fixtures/hook-payloads/probe/**` | done | | | |
| T026 | Copilot's second payload shape: failing test on the probe payloads first, signature alternatives in the dispatcher and deployer, Copilot's rule for Claude's hooks, Claude's rules refuse `timestamp` (B4F-144) | FR-028 | US8 | 0.75 | Implementer | `hosts/*/host.psd1`, dispatcher and deployer twins, `tests/unit/host-binding-match.tests.ps1` | done | | | |
| T027 | A reader for the unrecognized-payload record: the binding suite, the probe and the re-walk each fail on any record | FR-028 | US8 | 0.25 | Implementer | `tests/unit/host-binding-match.tests.ps1`, `tests/host-probes/**`, `iterations/002/copilot-rewalk.md` | done | | | |
| T028 | A payload carrying a sub-agent field is never typed by the human and never records an approval, on every channel (B4F-147) | FR-027 | US8 | 0.5 | Implementer | `hosts/*/host.psd1`, dispatcher twins, `tests/unit/subagent-prompt-authority.tests.ps1` | done | | | |
| T029 | Product-domain and grounding questions are workshop questions in prose on every host; the text test reaches every shipped instruction (B4F-131, T021's rule) | FR-032 | US8 | 0.5 | Implementer | host bindings, launch and coordinator guidance, templates, `tests/unit/workshop-question-tool.tests.ps1` | done | | | |
| T030 | Acceptance: evidence for T025 to T029, and the maintainer's Copilot re-walk with the capture hook; captured shapes replayed as fixtures (SC-011) | SC-011 | US8 | 0.25 | Implementer | `iterations/003/`, `iterations/002/copilot-rewalk.md`, `tests/host-probes/walk-capture-hook.ps1` | in-progress | | | |

## Effort Model

| Setting | Value | Notes |
| ------- | ----- | ----- |
| Effort Unit | story_points | Unit used in task effort, capacity, and retro variance. |
| Capacity per Iteration | 20 | Maximum planned effort before overcommit guidance applies. |
| Iteration Bounding | scope | `scope` keeps requirements fixed; `time` enforces a time ceiling. |
| Time Limit (hours) | n/a | Only applies when iteration bounding is `time`. |
| Overcommit Threshold | 1.0 | Warn planners when total estimated effort exceeds 20 story_points (capacity 20 x threshold 1.0). |
| Defer Strategy | manual | How planning should choose deferrals when the iteration is over capacity. |
| Calibration Enabled | true | When true, retrospectives should suggest future capacity adjustments. |

## Concurrency Rationale

- Roster: Spec Steward, Planner, Implementer, Reviewer, Retro Facilitator.
- Dependencies: `T025 -> T026 -> T027; T028; T029 -> [one review round] -> T030`. T025 to T029 are already in code;
  the round reviews them together, and its fixes land before T030's re-walk.
- One implementer, serial. The re-walk is the maintainer's.

## Phase Baseline

| Phase | Estimated Effort | Notes |
| ----- | ---------------- | ----- |
| Planning | done | The fix plan was approved in iteration 002 (DRIFT-006); this plan carries it over unchanged |
| Discovery/Spikes | 0 | The payload probe (T025) was the discovery; 108 of 108 checks pass live |
| Implementation | 3.0 | T025 to T029, in code since `2fd7f2d6` |
| Review | rounds, not SP | One round over T025 to T029, under the codex round allowance |
| Rework | inside the round allowance | Fixes from the round land before the re-walk |
| Acceptance | 0.25 | T030 and the maintainer's re-walk |

## Traceability Summary

- Requirement scope: FR-027, FR-028 and FR-032 (US8); SC-011.
- Every task maps to one requirement, and every requirement has a task. T025 to T030 keep their IDs from tasks.md
  Phase 14.

## Notes

- **Moved from iteration 002 on 2026-10-21** (`move the fixes to iteration 003`, iteration 002 DRIFT-006). The review
  round could not run inside iteration 002, which was past its retro.
- The re-walk script stays `iterations/002/copilot-rewalk.md`; it already carries the capture-hook steps, the
  hook-rows-under-`claude` check and the unrecognized-payload check. Its result is recorded in this iteration.
- Not in this iteration, unless the maintainer adds them at this stop: B4F-146 (the closeout step lists an iteration as
  closed before the closeout is approved; seen again at iteration 002's closeout on 2026-10-21), B4F-148 (a store
  writer that finds its project from its working directory) and B4F-149 (the withdrawal record's time format).
