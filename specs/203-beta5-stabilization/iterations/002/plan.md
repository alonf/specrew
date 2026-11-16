# Iteration Plan: 002

**Schema**: v1
**Spec**: [../../spec.md](../../spec.md)
**Status**: planning
**Capacity**: 19.25/20 story_points
**Started**: 2026-11-16
**Completed**:

<!--
  Validator schema (canonical, enforced by validate-governance.ps1):
  - Iteration Status MUST be one of:
      planning | executing | reviewing | retro | complete | abandoned
  - Capacity format MUST be `<consumed>/<cap> <effort_unit>` with NO trailing prose on that line.
  - Task Status (in the Tasks table) MUST be one of:
      planned | in-progress | done | needs-rework | deferred | blocked
-->

## Scope Summary

Iteration 002 is the stabilization batch, and the last iteration of feature 203. The maintainer chose Option A,
A-buffered, with the merge shape (design-analysis.md, Human Decision, 2026-11-16 11:34 local, relayed) and then
option 1 for the scope (11:49 local, relayed): 203 closes after this iteration and merges into main. US4 to US7,
FR-012, FR-013 and the three-host walk FR-044 move to a follow-up feature (decision
`f203-i002-merge-then-follow-up`; the spec is amended with this plan).

Most of this iteration fixes defects in requirements iteration 001 delivered, and items placed by the maintainer
from iteration 001's Gap Ledger (decision `f203-i001-gap-ledger-deferrals`). The requirements those fixes touch:

| Requirement | Summary | Stories |
| ----------- | ------- | ------- |
| FR-005 | Within budget: clean ends the review; fix-needed fixes and runs the next round, no stop (T022) | US1 |
| FR-006 | Human stops only for (a) to (d) (T022: the ordinary review end takes one approval) | US1 |
| FR-007 | The top-up grants one window (T018: a second top-up with no round between grants no extra window) | US1 |
| FR-011 | Review stop layout and phrases (T022, T024: the sign-off packet states the coverage; T027) | US1 |
| FR-019 | Verdict pairing across a compaction (T020: a compaction summary is never the cited turn) | US2 |
| FR-022 | Writers re-derive the act from the cited turn (T020: exact identity across every window first) | US2 |
| FR-026 | Every no-record branch reports in the same turn (T021: the review-stop answer on the recovery path) | US3 |
| FR-027 | Visible line (T021; T025 carries T006's launcher half) | US3 |
| FR-042 | Cross-host replay (T028: the Copilot and Codex capture cases moved here from T013) | US2 |
| FR-043 | Budget economics fixtures (T018) | US1 |
| FR-045 | The capture check (T027: the live `stop the review here` owed from T014; T028 on Copilot and Codex) | US2 |
| TG-003 | Each requirement names its delivery window (T029: the spec amendment) | all |

The items with no requirement of their own, each traced to the maintainer's placement: site 13 and the
deterministic suites' time limits (T015), HookRenderDedupe (T016), `empty-result-retry` (T017), B5F-077 (T019),
the phase lines B5F-050, B5F-059 and B5F-083 (T023), the hook cost DRIFT-073 (T025) and the t008 lane time
DRIFT-087 (T026).

## Tasks

| Task | Title | Requirement | Story | Effort | Owner | Owner File Globs | Status | Agent | Actual | Verdict |
| ---- | ----- | ----------- | ----- | ------ | ----- | ---------------- | ------ | ----- | ------ | ------- |
| T015 | Site 13: wait for the stopped supervisor after `Stop-Process` (`co-review-service.ps1:216`), test red first; the deterministic suites get a per-suite time limit that names the suite and stops its process tree, and the step a `timeout-minutes` below the job's so a hang keeps its log | Gap Ledger: B5F-051 site 13; DRIFT-004, DRIFT-005 | US1 | 1.5 | Implementer | scripts/internal/continuous-co-review/co-review-service.ps1, tests/continuous-co-review/unit/co-review-service.Tests.ps1, .github/workflows/cross-platform-validation.yml, tests/continuous-co-review/** | planned | | | |
| T016 | HookRenderDedupe timing cases I3a and I4b: remove the wall-clock dependency, test red first | the maintainer's rerun rule, 2026-11-16 02:56 | US3 | 1.0 | Implementer | tests/bootstrap/HookRenderDedupe.Tests.ps1, scripts/internal/bootstrap/** | planned | | | |
| T017 | `empty-result-retry.Tests.ps1`: find and remove its timing dependency, test red first | the rerun exception, 2026-11-15 11:31 | US1 | 0.5 | Implementer | tests/continuous-co-review/unit/empty-result-retry.Tests.ps1, scripts/internal/continuous-co-review/** | planned | | | |
| T018 | F5: a second top-up with no round between grants no extra window, as a fixture through the shipped command | FR-007, FR-043 | US1 | 0.5 | Implementer | tests/continuous-co-review/unit/**, tests/unit/** | planned | | | |
| T019 | B5F-077: remove the tracked `.antigravitycli/` link into another machine's home folder; keep it from coming back | Gap Ledger: B5F-077 | US2 | 0.25 | Implementer | .antigravitycli/**, .gitignore | planned | | | |
| T020 | F1, round E `finding-cf1fe81e0398f883`: try the exact identity across every window before the message-ID fallback; a compaction summary is never the cited turn (DRIFT-083), test red first | FR-019, FR-022 | US2 | 1.5 | Implementer | scripts/internal/bootstrap/HumanAuthorityStore.ps1, scripts/internal/bootstrap/ConversationCaptureAccessor.ps1, tests/unit/** | planned | | | |
| T021 | F2, round E `finding-a537d3f72672e5f5`: a review-stop answer lost on the recovery path is reported; a stop-answer case in `typed-act-writer` case 9b (DRIFT-084), test red first | FR-026, FR-027 | US3 | 1.0 | Implementer | scripts/internal/bootstrap/HumanAuthorityStore.ps1, scripts/internal/bootstrap/HandoverStore.ps1, extensions/specrew-speckit/scripts/specrew-*-provider.ps1, tests/unit/** | planned | | | |
| T022 | F4, the sign-off gate: a human-accepted disposition for the reviewed digest covers a records-only difference after it (DRIFT-078); the ordinary review end takes one approval (DRIFT-091); a finding is resolved by the run that reviews its fix or by the human's stop (B5F-071); a typed override with a reason stays for product code no reviewer read and no test covers | FR-005, FR-006, FR-011 | US1 | 4.0 | Implementer | scripts/internal/continuous-co-review/signoff-gate-wiring.ps1, scripts/internal/continuous-co-review/*.ps1, scripts/internal/sync-boundary-state.ps1, .specify/extensions/specrew-speckit/**, tests/continuous-co-review/unit/**, tests/unit/** | planned | | | |
| T023 | Phase lines, one owner: the truth gate and the governance check read the authority record's cursor, so `review.md` beside `plan.md` at `executing` and `retro.md` beside `reviewing` pass with a warning (B5F-050, B5F-059); a scaffolded iteration's records can be pushed before its plan (B5F-083) | Gap Ledger: B5F-050, B5F-059, B5F-083 | US1 | 1.5 | Implementer | scripts/internal/sync-boundary-state.ps1, .specify/extensions/specrew-speckit/scripts/validate-governance.ps1, .specify/extensions/specrew-speckit/**, extensions/specrew-speckit/scripts/**, tests/unit/**, tests/integration/** | planned | | | |
| T024 | B5F-075: the sign-off coverage line counts records apart from source files and states no round budget nobody set | FR-011 | US1 | 0.5 | Implementer | scripts/internal/continuous-co-review/*.ps1, tests/continuous-co-review/unit/** | planned | | | |
| T025 | F3, the hook cost (DRIFT-073): one git snapshot and one transcript tail read per hook run, handed to the providers; the stores loaded once. Measured as DRIFT-073 measured it: the Stop and prompt hooks through the deployed launcher on a scratch copy of the tree, the same payload, a typed prompt appended to a copy of a real 53 MB transcript, ten turns per engine, median and worst; on `5cb83329` the medians were 14.1 s Stop and 4.8 s prompt per turn. Done when: structurally, proven by tests committed red first, each hook run takes one git snapshot and one transcript tail read and hands them to the providers, the stores load once, and every hook check still runs; measured, the before figures re-measured on the tree T025 starts from and the after figures reported, median and worst. If the medians do not fall, T025 is not done on the crew's say and goes to the maintainer with the numbers. No numeric target is set; one is the maintainer's to set if they want it. T006's launcher half (plain-text refusals, DRIFT-046) travels in the same push and sweep | Gap Ledger: DRIFT-073; FR-027 (launcher half) | US3 | 5.0 | Implementer | extensions/specrew-speckit/scripts/specrew-hook-dispatcher.ps1, extensions/specrew-speckit/scripts/specrew-*-provider.ps1, extensions/specrew-speckit/scripts/shared-governance.ps1, extensions/specrew-speckit/scripts/turn-end-store.ps1, scripts/internal/specrew-*.ps1, scripts/internal/bootstrap/*.ps1, scripts/internal/deploy-refocus-hooks.ps1, .specify/extensions/specrew-speckit/**, tests/unit/**, tests/integration/** | planned | | | |
| T026 | The t008 lane's time: measure `f203-i001-t008-suites` (838 of 900 s on `da78b600`) against round D finding 1's whole-transcript read before any limit moves | Gap Ledger: DRIFT-087 | US1 | 0.5 | Implementer | specs/203-beta5-stabilization/iterations/002/** | planned | | | |
| T027 | F6: the live `stop the review here` on the pin at `da78b600` (the engine advanced at T014, iteration 001) at this iteration's first review stop, reading its disposition's `authorization_ref` (owed from T014, DRIFT-092 departure B); see Notes, Review and pin sequence | FR-045, FR-011 | US2 | 0.25 | Implementer | specs/203-beta5-stabilization/iterations/002/** | planned | | | |
| T028 | Copilot and Codex capture walk before the merge, manual with records: a verdict typed after a compaction, a quoted phrase and a pasted phrase, on each host, after the pin advance; the maintainer types, the crew prepares and records (Notes, The walk) | FR-042, FR-045 | US2 | 1.0 | Implementer | specs/203-beta5-stabilization/iterations/002/** | planned | | | |
| T029 | Spec amendment: US4 to US7, FR-012, FR-013 and FR-044 marked moved to the follow-up feature; the traceability table and the capacity model amended | TG-003 | US1 | 0.25 | Spec Steward | specs/203-beta5-stabilization/spec.md, specs/203-beta5-stabilization/tasks.md | done | Claude | 0.25 | applied with this plan; the governance check accepts the moved requirements with no code change (dry run, DRIFT-007) |

## Effort Model

| Setting | Value | Notes |
| ------- | ----- | ----- |
| Effort Unit | story_points | Unit used in task effort, capacity, and retro variance. |
| Capacity per Iteration | 20 | Maximum planned effort before overcommit guidance applies. |
| Iteration Bounding | scope | The maintainer fixed the scope (option 1); any change to it is theirs. |
| Time Limit (hours) | n/a | Only applies when iteration bounding is `time`. |
| Overcommit Threshold | 1.0 | Task rows 19.25 of 20. The 2.0 SP review buffer is not a task row; with it the stated total is 21.25 SP. |
| Defer Strategy | manual | Any deferral is the maintainer's decision. |
| Calibration Enabled | true | Retro compares actuals to these estimates. |

## Concurrency Rationale

- **Roster:** Spec Steward, Planner, Implementer, Reviewer (codex, then copilot, then claude), Retro Facilitator.
- **Conflict risk:** high. T020 and T021 share `HumanAuthorityStore.ps1`; T022, T023 and T024 share the sign-off
  gate and the sync; T025 touches every provider.
- **Recommendation:** serial, in the order the maintainer accepted (design-analysis.md, Key Design Decision Point 4):
  1. T015, T016, T017 (the three flaky tests first in the batch), then T018 and T019.
  2. T020 and T021, the open round E findings.
  3. T022, T023 and T024, one design.
  4. T025 last; its push needs the full sweep and carries the launcher half.
  5. T026 before any lane limit changes; T027 at the iteration's first review stop; T028 after the pin advance.

## Phase Baseline

| Phase | Estimated Effort | Notes |
| ----- | ---------------- | ----- |
| Planning | 0.25 | Design analysis and decisions done; T029 (the spec amendment) applied with this plan |
| Discovery/Spikes | 0.5 | T026, the t008 measurement |
| Implementation | 17.25 | T015 to T025 |
| Review | budget | The feature plan's `## Review budget`, `iteration-002`: rounds 4, host order codex, copilot, claude, infra_failure_cap 2; T027 at the first stop |
| Rework | 2.0 | The review buffer, not a task row (option 1): stated total 21.25 SP |
| Walk | 1.25 | T027 and T028 |

## Traceability Summary

- **Requirement scope:** FR-005, FR-006, FR-007, FR-011, FR-019, FR-022, FR-026, FR-027, FR-042, FR-043, FR-045 (fixes
  and checks of what iteration 001 delivered) and TG-003 (the spec amendment). Moved to the follow-up feature: US4 to
  US7 (FR-028 to FR-040), FR-012, FR-013, FR-044.
- **User stories represented:** US1, US2, US3.
- Every task traces to a requirement or to the maintainer's placement of an item (decisions
  `f203-i001-gap-ledger-deferrals`, `f203-i002-merge-then-follow-up`, `f203-i002-scope-option-1`). Every requirement
  in scope has at least one task.

## Notes

- **Capacity:** task rows 19.25 of 20 SP. The review buffer of 2.0 SP is stated here and in the Phase Baseline, not
  as a task row, as the maintainer chose ("option 1 it is", 2026-11-16 11:49 local, relayed): **the stated total with
  the buffer is 21.25 SP**, 1.25 over the 20 baseline. The capacity check counts task rows only (DRIFT-007).
- **Moved out:** B5F-080 (the task writer rewrites state.md's Iteration Status after the boundary that owns it),
  B5F-076, B5F-073 and B5F-072, and the rest of B5F-051's census, to the follow-up feature. **B5F-080 will occur once
  more, at this iteration's last task; that is the known defect, not a new one.**
- **Review and pin sequence**, round by round (the budget is the feature plan's `iteration-002` entry: 4 rounds,
  codex, copilot, claude, snapshotted at before-implement):
  1. T015 to T026 are built and pushed. The hooks and review rounds run from the pin at `da78b600` throughout; that
     pin is the engine advanced at T014 in iteration 001, so it is the "advanced engine" T027 names.
  2. The review campaign runs on `da78b600` over the whole tree at the batch's tip: round 1, and after each
     fix-needed round a fix and the next round, with no stop (FR-005). A stop comes only for (a) to (d).
  3. **T027 lands at the first stop of this campaign**, on `da78b600`: the maintainer answers `stop the review here`
     if that is their answer, and the crew reads the disposition's `authorization_ref`. If the campaign ends with no
     stop (round 1 clean), T027 is recorded as not exercised live and the crew brings the maintainer one choice: a
     rehearsal on a scratch copy (as T014's, accepted 2026-11-16 02:13) or the live check in the follow-up feature.
     The crew does not provoke a stop to make room for it.
  4. When the campaign ends clean, or at a stop with only fail-closed findings the maintainer accepts: a full sweep
     of the reviewed tip (DRIFT-057, about 2 h), the home hook files hashed, then the maintainer's typed `advance the
     pin`. The pin moves to the reviewed tip. Until then T020's hook-side part, T021, T025 and the stop side of T022
     serve no one (design-analysis.md, "When each fix becomes live").
  5. T028, the walk, on the advanced pin (below).
  6. After the advance, what is reviewed: if the walk changes records only, nothing new is reviewed; T022's gate
     covers a records-only difference on the reviewed digest at the sign-off. If the walk needs a code fix, the fix
     gets a round on the advanced pin within the budget, test red first; T025's launcher redeploy is reviewed in step
     2, not after.
  7. Review sign-off, retro, iteration closeout and feature closeout, each at its own boundary.
- **The walk (T028)**: the maintainer types, on Copilot CLI and on Codex CLI, in a scratch copy of this project on
  the advanced pin that the crew prepares (never in this checkout; the agentic CLI probe rule). Per host: open the
  session, send three lines the crew gives in one paste block (a verdict at a waiting stop, the same phrase quoted
  mid-sentence, the same phrase inside pasted content), compact the session, then type the verdict again. About 15
  minutes per host, 30 to 40 minutes in all (judgment). The crew prepares the two scratch projects with a pending
  crossing through the governed sync, the paste block, and a script that reads what each line recorded; the crew
  writes the records. Expected: the verdict recorded once, the quoted and pasted phrases record nothing and are
  reported.
- **The merge is not a task of this iteration.** Merging 203 into main needs the maintainer's separate go; there is
  no pull request and no push to main without it. If 206 and 205 reach main first, in the maintainer's stated order
  206, 205, 203, then 203 merges main in (a merge, not a rebase), resolves the conflicts and runs the full sweep
  again. That work is not in the 19.25 SP; the crew's estimate, a judgment with no measurement behind it, is 1.0 to
  2.0 SP plus about 2 h of sweep, most of it in the shared scripts (the sync, the validator, the hooks).
- **Launcher:** T006's launcher half runs with T025's push (design decision 8, refining "launcher: wait" of 03:13).
  The crew asks the maintainer before running the deployer then.
- **Rerun rules while this iteration runs:** HookRenderDedupe (2026-11-16 02:56) and "203 rerun: yes" (11:34) apply
  to records-only pushes only; a push that touches code gets no exception. Each rule ends when its fix lands.
- **Out, evidence only:** the Windows `0xC0000142` and Pester-gallery CI sightings; B5F-081, B5F-082, B5F-084 and
  B5F-085 are candidates for feature 206's list.
- **Design:** see design-analysis.md (Option A, A-buffered, the merge variant; Human Decision and its scope
  addendum).
