# Iteration Plan: 001

**Schema**: v1
**Spec**: [../../spec.md](../../spec.md)
**Status**: executing
**Capacity**: 20/20 story_points
**Started**: 2026-11-10
**Completed**:

<!--
  Validator schema (canonical, enforced by validate-governance.ps1):
  - Iteration Status MUST be one of:
      planning | executing | reviewing | retro | complete | abandoned
  - Capacity format MUST be `<consumed>/<cap> <effort_unit>` with NO trailing prose on that line.
  - Task Status MUST be one of:
      planned | in-progress | done | needs-rework | deferred | blocked
-->

## Scope Summary

Items 1, 2a, 2b, 4 and 5 fixed, item 3 handed over; FR-013 and FR-014 (T016, T017) are deferred to
iteration 002 (Notes). Design:
modified-Option B ([design-analysis.md](design-analysis.md)); the four conditions of the design verdict are
tasks T003, T005, T008, T010 and T012, and acceptance check T018.

| Requirement | Summary | Item |
| ----------- | ------- | ---- |
| FR-001 | no-console stale state: plain refusal, non-zero exit, never a loop | 1 |
| FR-002 | over-claim finds dirty canonical artifacts on every platform, one separator | 2a |
| FR-003 | Specrew's own instruction heal is not a user behaviour change | 2b |
| FR-004 | item 3 hand-over to 203 with its recurrence log | 3 |
| FR-005 | 198/011 marked abandoned; one finding for 203's follow-up | 4 |
| FR-006 | one-time triage applied: abandoned or frozen, per the rulings | 4 |
| FR-007 | frozen list closed and guarded | 4 |
| FR-008 | closed iterations judged only by checks shipped before their closure | 4 |
| FR-008a | one definition of "closed" | 4 |
| FR-009 | nightly tracking issue, new failures only | 4 |
| FR-010 | the review-verdict finding names the real status | 4 |
| FR-011 | lane guard and full sweep count every test script | 5 |
| FR-012 | each of the 35 registered or excluded, by the maintainer's ruling | 5 |
| FR-013 | deferred to iteration 002 (T016) | 5 |
| FR-014 | deferred to iteration 002 (T017) | 6a |

## Tasks

| Task | Title | Requirement | Story | Effort | Owner | Owner File Globs | Status | Agent | Actual | Verdict |
| ---- | ----- | ----------- | ----- | ------ | ----- | ---------------- | ------ | ----- | ------ | ------- |
| T001 | No-console recovery refusal and three-try cap (failing test first) | FR-001 | US1 | 1.5 | Implementer | scripts/internal/session-recovery.ps1, scripts/specrew-start.ps1, tests/unit/** | done | | | |
| T002 | Over-claim dirty check: one path separator (failing assertions 1 and 2 first) | FR-002 | US1 | 0.5 | Implementer | extensions/specrew-speckit/scripts/validate-governance.ps1, .specify/extensions/specrew-speckit/scripts/validate-governance.ps1, tests/integration/validator-hardening-iteration2.ps1 | in-progress | | | |
| T003 | Change classifier strips matched specrew-managed blocks only; unbalanced compares whole file (condition 3) | FR-003 | US1 | 1.5 | Implementer | scripts/specrew-start.ps1, scripts/internal/instruction-file-merge.ps1, tests/unit/**, tests/integration/validator-hardening-iteration2.ps1 | in-progress | | | |
| T004 | Item 3 hand-over record for 203, with the recurrence log | FR-004 | US2 | 0.5 | Implementer | specs/206-bug-bash/bug-list.md, specs/206-bug-bash/iterations/001/** | done | | | |
| T005 | Closed-definition table: every iteration under the three current rules and the new function; changes listed with reasons; 198/010 included as awaiting the maintainer's ruling (condition 1, before T006) | FR-008a | US2 | 1.0 | Implementer | specs/206-bug-bash/iterations/001/** | done | | | |
| T006 | Test-SpecrewIterationClosed: one function for the validator filter, dashboard check and renderer; heuristic and verdict rule removed (failing test first) | FR-008a | US2 | 2.0 | Implementer | extensions/specrew-speckit/scripts/shared-governance.ps1, extensions/specrew-speckit/scripts/validate-governance.ps1, .specify/extensions/specrew-speckit/scripts/*.ps1, scripts/internal/dashboard-renderer.ps1, tests/unit/**, .specify/extensions/specrew-speckit/.specrew-extension-runtime.json | done | | | |
| T007 | Mark 198/011, 197/006 and 198/010 abandoned (198/010 by the T005 ruling); the 203 finding (FR-066 mint guard, T091, T093); frozen list with its 18 entries | FR-005, FR-006 | US2 | 1.0 | Implementer | specs/198-beta2-hardening/iterations/011/state.md, specs/198-beta2-hardening/iterations/011/plan.md, specs/198-beta2-hardening/iterations/010/state.md, specs/198-beta2-hardening/iterations/010/plan.md, specs/197-*/iterations/006/state.md, specs/197-*/iterations/006/plan.md, .specrew/legacy-frozen.yml, specs/206-bug-bash/** | in-progress | | | |
| T008 | Frozen means judged by no check; guard test for added keys; zero-findings test per entry; 197/006 resolved (condition 2) | FR-007 | US2 | 1.5 | Implementer | extensions/specrew-speckit/scripts/validate-governance.ps1, .specify/extensions/specrew-speckit/scripts/validate-governance.ps1, extensions/specrew-speckit/scripts/shared-governance.ps1, tests/unit/** | done | | | |
| T009 | `since` on the dashboard check (complete only), closure stamp written at closeout; abandoned only by a recorded maintainer ruling, and abandoned by ruling is not held to the plan-status or review-verdict rule (failing tests first); 198/011's abandonment lands with it | FR-008 | US2 | 1.5 | Implementer | extensions/specrew-speckit/scripts/validate-governance.ps1, extensions/specrew-speckit/scripts/shared-governance.ps1, .specify/extensions/specrew-speckit/scripts/*.ps1, tests/unit/** | planned | | | |
| T010 | Local nightly replay (CI mode, full repo): no new finding from any changed iteration, else stop for the maintainer (condition 1 acceptance) | FR-008a, FR-006 | US2 | 0.5 | Implementer | specs/206-bug-bash/iterations/001/** | planned | | | |
| T011 | Review-verdict finding names the iteration's actual status (failing test first) | FR-010 | US2 | 0.5 | Implementer | extensions/specrew-speckit/scripts/validate-governance.ps1, .specify/extensions/specrew-speckit/scripts/validate-governance.ps1, tests/unit/** | planned | | | |
| T012 | Notifier script with injectable gh, findings file, Pester (open, quiet, comment, close, no private text); notifier job alone has issues: write (condition 4) | FR-009 | US2 | 2.5 | Implementer | scripts/internal/nightly-tracking-issue.ps1, extensions/specrew-speckit/scripts/validate-governance.ps1, .specify/extensions/specrew-speckit/scripts/validate-governance.ps1, .github/workflows/specrew-nightly-truth-check.yml, tests/unit/** | planned | | | |
| T013 | Shared test census for the lane guard and the full sweep, content-classified, one exclusion list (failing guard first) | FR-011 | US3 | 2.0 | Implementer | tests/support/test-census.ps1, tests/unit/every-suite-is-named-by-a-lane.tests.ps1, tests/full-powershell-test-sweep.ps1 | planned | | | |
| T014 | The 35 scripts: read for home writes or hook deployment (any call to specrew-update.ps1 or the hook deployment = not run, listed for the maintainer), run the safe ones with home hashes, durations; STOP with exclusions, red scripts and per-push total for the maintainer | FR-012 | US3 | 2.0 | Implementer | specs/206-bug-bash/iterations/001/** | planned | | | |
| T015 | Register the 35 per the maintainer's ruling; both B5F-036 suites green and registered | FR-012 | US3 | 1.0 | Implementer | .github/workflows/specrew-ci.yml, .specrew/release-gate-suites.txt, .specrew/verification-plan.json, tests/support/test-census.ps1 | planned | | | |
| T018 | Acceptance: no 203-protected path in the branch diff; .squad/active-features.yml not in it; home hashes unchanged across every run; no commit touches a full-validation trigger path | SC-007 | US1 | 0.5 | Implementer | specs/206-bug-bash/iterations/001/** | planned | | | |

## FR to test mapping

| Requirement | Failing test written first | Negative path asserted |
| --- | --- | --- |
| FR-001 | unit: no console input + stale state returns the refusal; interactive: three invalid answers then refusal | no `Read-Host` call without console input; never a fourth prompt |
| FR-002 | `validator-hardening-iteration2.ps1` assertions 1 and 2 | a clean artifact gives no finding; the separator is asserted |
| FR-003 | `validator-hardening-iteration2.ps1` assertion 3, plus the classifier unit suite | unbalanced or missing marker pauses; user change outside markers pauses |
| FR-007 | frozen-list guard | an added key fails; every entry yields zero findings |
| FR-008 | dashboard check with and without a closure stamp, before and after `since`; abandonment-ruling suite (T009) | an unstamped entry is not judged; an abandoned iteration owes no dashboard; `abandoned` with no recorded ruling is not closed |
| FR-008a | `Test-SpecrewIterationClosed` unit suite over index, status and frozen cases | a review verdict alone never makes an iteration closed |
| FR-009 | notifier suite with recorded `gh` calls | same failures: no call; rendered text has no path, user or machine name |
| FR-010 | validator message for a `retro` iteration | a `complete` iteration still gets its message |
| FR-011 | lane guard with a probe script of any name | fixtures and support helpers stay excluded |
| FR-014 | iteration 002: resolver on this repository with 201's spec | iteration 002: the fixture with its own `package.json` still detects `nodejs` |

FR-004, FR-005, FR-006 and FR-012 are records, rulings or deletions; their evidence is the bug
list, the frozen-list guard, the T010 replay and the T014 report.

## Effort Model

| Setting | Value | Notes |
| ------- | ----- | ----- |
| Effort Unit | story_points | Unit used in task effort, capacity, and retro variance. |
| Capacity per Iteration | 20 | Maximum planned effort before overcommit guidance applies. |
| Iteration Bounding | scope | The bug list is fixed by the maintainer; overcommit is surfaced, not auto-deferred. |
| Time Limit (hours) | n/a | Only applies when iteration bounding is `time`. |
| Overcommit Threshold | 1.0 | 20 planned against 20 x 1.0; no slack. |
| Defer Strategy | manual | Any deferral is the maintainer's decision. |
| Calibration Enabled | true | Retro compares actuals to these estimates. |

## Concurrency Rationale

- **Roster:** Spec Steward, Planner, Implementer, Reviewer, Retro Facilitator.
- **Conflict risk:** high on `validate-governance.ps1` (T002, T006, T008, T009, T011, T012) and
  `shared-governance.ps1` (T006, T008, T009).
- **Recommendation:** run serially, one bug per commit. Order: T001-T004; T005 before T006; T007, T008,
  T009, T011, then T010's replay; T012; T013 before T014; the T014 stop; T015; T018 last.

## Phase Baseline

| Phase | Estimated Effort | Notes |
| ----- | ---------------- | ----- |
| Planning | done | Bug list, spec, clarify, design analysis complete |
| Discovery/Spikes | 1.5 | T005 table and T014's reading and timing of the 35 |
| Implementation | 20.25 | T001-T004, T006-T013, T015-T018 |
| Review | allowance | Not priced in SP |
| Rework | from slack | No buffer planned; the overcommit is surfaced instead |

## Traceability Summary

- **Requirement scope:** FR-001 to FR-012 and FR-008a; FR-013 and FR-014 in iteration 002. SC-001 to SC-005
  and SC-007; SC-006 in iteration 002.
- Every task traces to an FR or SC; every FR in scope has at least one task.
- **Stories:** US1 start and checks (items 1, 2), US2 nightly and history (items 3, 4), US3 test census
  (item 5), US4 resolver (item 6a).

## Notes

- **Capacity:** 20 planned against 20. OVERRIDE 5 was reverted on the maintainer's verdict (2026-11-11,
  "changes needed: a"): `.specrew/iteration-config.yml` is identical to `main`. **No raise:** if any task grows
  so the total would pass 20, work stops and goes to the maintainer.
- **Deferred to iteration 002, not cut** (maintainer, 2026-11-11). Reason: iteration 001 was 1.75 SP over its
  20 SP cap, and raising the cap changes a file that makes CI validate the whole repository. These two were
  the maintainer's own drop order. Both keep their ids and estimates:

  | Task | Title | Requirement | Effort |
  | ---- | ----- | ----------- | ------ |
  | T016 | Delete the empty tests/integration/_ctl-spec.ps1 | FR-013 | 0.25 |
  | T017 | Resolver suggests no Node/React here (failing test first); f049 assertion onto a fixture; root package.json removed | FR-014 | 1.5 |
  | T019 | Cross-Platform review-runtime step gets its own `timeout-minutes`, shorter than the job's, so a hang fails with its log kept (bug list item 7) | none yet: a requirement is added when iteration 002 is planned | 0.25 |

  | T020 | The 12 iterations that count as closed today only by an accepted review (T005 table, group C: 001/002, 001/005-012, 005/001-002, 007/002) show as open on dashboards after T006; option: add them to the closed index | none yet | 0.5 |

  T019 and T020 were added on 2026-11-11 as candidates, not deferred from 001. T020: the display change is
  accepted for iteration 001 (maintainer, T005 ruling).
- **198/009's index entry contradicts its state file** (T005 table, group E): neither is changed (maintainer,
  2026-11-11); it stays in the 203 hand-over record as HO-206-7.
  Until T017 lands, the quality resolver keeps suggesting a React preset for this repository (bug 6a); the
  custom PowerShell profile in the feature plan stands in the meantime.
- **Stops inside implement:** T010 stops if any changed iteration produces a new finding; T014 stops with
  the exclusion list, every red script with its failure, each script's duration and the per-push total
  before anything is registered.
- **Abandoned only by a recorded maintainer ruling (T009).** `Test-SpecrewIterationClosed` counts status
  `abandoned` as closed only when the iteration records the ruling that abandoned it; `abandoned` with no
  recorded ruling is not closed and stays judged as open. Index membership is unchanged. The rulings, pinned by
  T009's tests:
  - **198/011**: maintainer ruling 2026-11-10 in this feature (spec FR-005, FR-006; bug list item 4): abandoned,
    review unchanged; the undone work is one finding for 203's follow-up.
  - **197/006**: maintainer ruling 2026-11-10 in this feature (spec FR-006): abandoned, superseded by 197/007
    before closeout.
  - **174/007**: maintainer decision 2026-06-14 at feature 174's iteration 011 closeout, recorded in its
    `state.md` Disposition: abandoned-superseded by 174/008, closed without a ratified review.
- **198/010: ruled abandoned and superseded (maintainer, 2026-11-11, option 1 at the T005 stop); applied in
  T007**, within T007's estimate, with two conditions: its `state.md` says in plain words that
  DRIFT-198-I010-004 stays open and was handed to feature 203 as HO-206-4, with the hand-over record's path; T082
  stays `needs-rework` in the record, neither done nor dropped. Found by the full-repo run during OVERRIDE 5; it
  was never in the nightly's reports because it passes at capacity 20.
  - **Status**: open. `state.md` says `Iteration Status: reviewing`, phase `review-signoff`, last updated
    2026-08-01; `plan.md` still says `planning`. Not in the closed index; no `review.md`.
  - **Needs-rework task**: T082, "DRIFT-198-I009-041 — authority-store containment against reparse points"
    (FR-008, 5.0 SP), status corrected from `done` to `needs-rework` on 2026-08-01: path resolution is
    contained, but paths obtained by enumeration bypass the check.
  - **Blocking finding**: DRIFT-198-I010-004, "T082's containment covers path RESOLUTION, not ENUMERATION;
    -041 is NOT delivered", open and blocking, a security defect on the read path at four enumeration sites in
    `scripts/internal/continuous-co-review/review-authority-store.ps1` (lines 200, 309, 362, 447 at the time).
    That file is in feature 203's protected area, so **whatever the maintainer rules for the iteration, the
    defect itself is handed to feature 203.**
- **197/006** is marked abandoned, not frozen; the dashboard check applies to `complete` iterations only
  (feature plan, "197/006, resolved").
- **Which changed paths make CI validate the whole repository.** CI runs `validate-governance.ps1
  -ChangedOnly` against the previous push. It falls back to the whole repository when the diff touches any of
  these paths (`Get-ValidatorGlobalStatePathspecs`, `shared-governance.ps1`): `.specrew/config.yml`,
  `.specrew/constitution.md`, `.specrew/iteration-config.yml`, `.specrew/role-assignments.yml`,
  `.specrew/presets/**`, `.specrew/lenses/**`, `.specrew/roadmap.yml`, `.squad/identity/wisdom.md`. It also does
  so when the base cannot be resolved or the diff fails. **The validator scripts are not among them**, and
  neither are `.specrew/closed-iterations.yml` or the new `.specrew/legacy-frozen.yml`. **No task in this
  iteration touches a trigger path**, so no reordering is needed; T018 checks that no commit does. On `main`,
  and in the nightly, the validator always runs the whole repository.
- **What the whole-repository run reports on this branch today** (CI mode, `-FullRun`, with OVERRIDE 5
  reverted): see the T005 evidence. Its only failure is 198/011's review-verdict finding, which T007 removes,
  plus the 20 dashboard warnings on the frozen and abandoned entries.
- **Review preflight: no inherited lanes run here** (maintainer, 2026-11-11, after feature 205's review
  preflight ran the lanes in `.specrew/verification-plan.json`, 202's and 199's suites, and one rewrote four
  real-home hook files). In this worktree no review round starts and none of those lanes runs. Before 206's
  review round, a verification plan naming **only 206's own checks**, each first read for writes to the home
  folder or hook deployment (T014's read-before-run rule, applied to everything the review preflight would
  run), is brought to the maintainer. T015 registers suites for CI and the release manifest; a suite added to a
  verification lane is read under the same rule first. This is review-stage work, not priced in SP (Phase
  Baseline).
- **Never run on this machine** (maintainer, 2026-11-11; bug list item 8): the 16 test files feature 203's census
  found able to write the home hook files:
  - `tests/integration/bootstrap-asset-blocker-recovery.ps1`
  - `tests/integration/bootstrap-to-iteration.ps1`
  - `tests/integration/brownfield-conflict-handling.ps1`
  - `tests/integration/deployed-extension-marker-on-update.tests.ps1`
  - `tests/integration/distribution-module-update.ps1`
  - `tests/integration/psgallery-check.tests.ps1`
  - `tests/integration/receipt-outcomes-retired.tests.ps1`
  - `tests/integration/start-command-non-interactive-first-run.tests.ps1`
  - `tests/integration/start-command.ps1`
  - `tests/integration/start-recovery-flow.tests.ps1`
  - `tests/integration/task-progress-tracking.tests.ps1`
  - `tests/integration/team-management.ps1`
  - `tests/integration/update-command.ps1`
  - `tests/integration/validate-baseline-team.ps1`
  - `tests/integration/version-checks.tests.ps1`
  - `tests/manual/copilot-squad-smoke.ps1`

  The census was made on feature 203's code, so the read-first rule still applies to anything else that reaches
  `specrew init`, `start`, `update` or the hook deployer: it is not run unless it has been read and the path it takes
  confirmed unable to write hook files. In
  T014, and for anything the review preflight would run, a script that calls `specrew-update.ps1` or the hook
  deployment is **not run, and is listed for the maintainer**.
- **Not touched:** `scripts/internal/continuous-co-review/**`, `scripts/internal/bootstrap/**`,
  `scripts/specrew-update.ps1`, `.squad/active-features.yml`.
