# Iteration Plan: 002

**Schema**: v1
**Spec**: [../../spec.md](../../spec.md)
**Status**: executing
**Capacity**: 20/20 story_points
**Started**: 2026-11-15
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

The work carried from iteration 001 and bug list items 37, 39, 41 and 44 (Amendment A1), by the maintainer's scope
decision (2026-11-15, 11:31 local, relayed; DRIFT-206-002). Design: Option B
([design-analysis.md](design-analysis.md)), chosen by the maintainer on 2026-11-15 with the cut as proposed. Items 15,
16, 19, 20, 28 and 35 move to iteration 003 (Notes).

| Requirement | Summary | Item |
| ----------- | ------- | ---- |
| FR-001 | a fresh clone with no session files starts; a resume path outside the project is refused | 22, 23 |
| FR-003 | `specrew start` treats whole files it wrote itself as bookkeeping; a malformed marker is unbalanced | 21, 33 |
| FR-008 | abandoned is closed only with a recorded ruling (DRIFT-206-I001-010) | DRIFT-010 |
| FR-008a | the one closed definition follows that rule | DRIFT-010 |
| FR-009 | every repository-level stop and the outer catch write their message hash | 30, 34 |
| FR-011 | the census guard reads YAML and shell by structure | 31, 32 |
| FR-012 | SC-001's and SC-002's scripts green and registered; three excluded scripts fixed; a manual trigger for Specrew CI | 12, 17, 18, 24, 29 |
| FR-013 | the empty `_ctl-spec.ps1` deleted (T016) | 5 |
| FR-014 | the stray root `package.json` removed; its assertion on a fixture (T017) | 6a |
| FR-015 | a `deferred` task verdict with its decision id, beside an `accepted` review | 37 |
| FR-016 | a record written before its approval is a normal state | 39 |
| FR-017 | the closeout dashboard is drawn after the verdict, before the seal | 41 |
| FR-018 | the Completed date written by the capture; open hardening rows named at the arrival | 44 |

## Tasks

| Task | Title | Requirement | Story | Effort | Owner | Owner File Globs | Status | Agent | Actual | Verdict |
| ---- | ----- | ----------- | ----- | ------ | ----- | ---------------- | ------ | ----- | ------ | ------- |
| T020 | Start records the hash of each whole file it creates or repairs, in a git-ignored record; a matching file is bookkeeping, an edited one the user's (D5-a; failing test first) | FR-003, SC-002 | US1 | 3.0 | Implementer | scripts/specrew-start.ps1, scripts/internal/instruction-file-merge.ps1, .gitignore, tests/unit/** | done | | | |
| T021 | `validator-hardening-iteration2.ps1`: fixture copies every file git does not ignore, tested in the preflight layout; run green; registered in the release manifest (item 29's remainder) | SC-002, FR-012 | US1 | 0.5 | Implementer | tests/integration/validator-hardening-iteration2.ps1, .specrew/release-gate-suites.txt, tests/support/test-census.ps1 | done | | | |
| T022 | A governed project with no session files starts as a first start; an unreadable one still refuses (D6-a); the fresh-clone combination test with T020 (failing tests first) | FR-001, SC-001 | US1 | 1.25 | Implementer | scripts/internal/session-recovery.ps1, scripts/specrew-start.ps1, tests/unit/** | done | | | |
| T023 | A resume path outside `-ProjectPath` is refused; the identity file stops carrying an absolute feature path (item 23; failing test first) | FR-001, SC-001 | US1 | 1.0 | Implementer | scripts/internal/session-recovery.ps1, scripts/specrew-start.ps1, scripts/internal/sync-boundary-state.ps1, .squad/identity/now.md, tests/unit/** | done | | | |
| T024 | `project-path-resolution-regression.ps1`: fixture copies every file git does not ignore; green and registered (item 24, SC-001) | SC-001, FR-012 | US1 | 0.5 | Implementer | tests/integration/project-path-resolution-regression.ps1, .github/workflows/specrew-ci.yml, .specrew/release-gate-suites.txt, tests/support/test-census.ps1 | done | | | |
| T025 | `specrew init`'s Squad probe runs in a temp folder; a failed cleanup is reported; the init case's cause found (item 25; failing test first) | SC-001, SC-007 | US1 | 1.0 | Implementer | scripts/specrew-init.ps1, scripts/init/squad-deploy.ps1, tests/unit/** | done | | | |
| T016 | Delete the empty `tests/integration/_ctl-spec.ps1` | FR-013 | US3 | 0.25 | Implementer | tests/integration/_ctl-spec.ps1, tests/support/test-census.ps1 | done | | | |
| T017 | Remove the stray root `package.json`; the f049 stack-detection assertion onto a fixture with its own `package.json`; the resolver selects no Node or React preset (failing test first) | FR-014, SC-006 | US4 | 1.5 | Implementer | package.json, tests/integration/f049-i003-intake-engine-tests.ps1, tests/integration/fixtures/** | done | | | |
| T026 | Abandoned is closed only with a recorded ruling (DRIFT-206-I001-010; failing test first) | FR-008, FR-008a | US2 | 1.0 | Implementer | extensions/specrew-speckit/scripts/shared-governance.ps1, extensions/specrew-speckit/scripts/validate-governance.ps1, .specify/extensions/specrew-speckit/scripts/*.ps1, .specify/extensions/specrew-speckit/.specrew-extension-runtime.json, tests/unit/** | done | | | |
| T032 | A managed-block opener's trailing arrows must match its direction; a mismatched pair is unbalanced (item 33; failing test first) | FR-003 | US1 | 0.75 | Implementer | scripts/internal/instruction-file-merge.ps1, tests/unit/** | done | | | |
| T031 | Census guard tracks YAML block scalars and job and step structure, and treats `;` as a comment boundary; one fixture per construct (items 31, 32; failing fixtures first) | FR-011, SC-004 | US3 | 1.5 | Implementer | tests/unit/every-suite-is-named-by-a-lane.tests.ps1, tests/support/test-census.ps1, tests/unit/fixtures/** | done | | | |
| T030 | The four repository-level stops and the outer catch pass their messages with `-FailureMessages` (items 30, 34; failing test first) | FR-009 | US2 | 1.25 | Implementer | extensions/specrew-speckit/scripts/validate-governance.ps1, .specify/extensions/specrew-speckit/scripts/validate-governance.ps1, .specify/extensions/specrew-speckit/.specrew-extension-runtime.json, tests/unit/** | done | | | |
| T027 | `workflow_dispatch:` on Specrew CI, as the other two workflows have (item 12) | FR-012 | US3 | 0.25 | Implementer | .github/workflows/specrew-ci.yml | done | | | |
| T028 | `distribution-module-publish.ps1` clears and restores `PSGALLERY_API_KEY` itself; the release script refuses a publish nobody asked for; run or keep excluded by the maintainer's ruling (item 17, high; failing test first) | FR-012, SC-007 | US3 | 0.75 | Implementer | tests/integration/distribution-module-publish.ps1, scripts/release/** | done | | | |
| T029 | `multi-host-smoke.ps1`: rename the loop variable that collides with `$Host` (item 18; read, not run: it deploys hooks) | FR-012 | US3 | 0.25 | Implementer | tests/manual/multi-host-smoke.ps1 | done | | | |
| T033 | review.md accepts a `deferred` task verdict naming an existing decision id, beside `accepted` (D1-a; failing test first) | FR-015, SC-008 | US2 | 1.0 | Implementer | extensions/specrew-speckit/scripts/validate-governance.ps1, .specify/extensions/specrew-speckit/scripts/validate-governance.ps1, .specify/extensions/specrew-speckit/.specrew-extension-runtime.json, tests/unit/** | done | | | |
| T034 | Staleness checks accept a record before its verdict; with no `start-context.json`, a warning (D2-a; five cases, failing first) | FR-016, SC-009 | US2 | 1.0 | Implementer | extensions/specrew-speckit/scripts/validate-governance.ps1, .specify/extensions/specrew-speckit/scripts/validate-governance.ps1, .specify/extensions/specrew-speckit/.specrew-extension-runtime.json, tests/unit/** | done | | | |
| T035 | The capture redraws the closeout dashboard after the mirrors and before the seal; a failed redraw warns and never blocks the seal (D3-a; failing test first) | FR-017, SC-010 | US2 | 1.25 | Implementer | extensions/specrew-speckit/scripts/shared-governance.ps1, .specify/extensions/specrew-speckit/scripts/shared-governance.ps1, .specify/extensions/specrew-speckit/.specrew-extension-runtime.json, tests/unit/** | done | | | |
| T036 | The mirror write that moves plan.md to complete writes the Completed date; the closeout arrival lists open hardening rows in the pending-verdict artifact (D4-a; failing tests first) | FR-018, SC-011 | US2 | 1.5 | Implementer | extensions/specrew-speckit/scripts/shared-governance.ps1, .specify/extensions/specrew-speckit/scripts/shared-governance.ps1, scripts/internal/sync-boundary-state.ps1, .specify/extensions/specrew-speckit/.specrew-extension-runtime.json, tests/unit/** | done | | | |
| T037 | The two reviewer-brief promotions from iteration 001's retro, in this iteration's review brief | FR-003, FR-011 | US3 | 0.25 | Implementer | specs/206-bug-bash/iterations/002/** | done | | | |
| T038 | Review sign-off records; the record is pushed before its verdict and Lint stays green (SC-009 in use) | SC-009 | US2 | 0.25 | Implementer | specs/206-bug-bash/iterations/002/** | planned | | | |

## FR to test mapping

| Requirement | Failing test written first | Negative path asserted |
| --- | --- | --- |
| FR-003 (T020) | `validator-hardening-iteration2.ps1` assertion 3, plus a start unit suite over healed and created whole files | an edited healed file pauses; a file with no record pauses once an earlier snapshot exists |
| FR-003 (T032) | classifier unit suite with `>>>` / `<<<` mismatched openers | a matched pair still strips; a mismatched pair compares the whole file |
| FR-001 (T022) | start with neither session file, no console: first start, exit 0 | an unreadable `last-start-prompt.md` still refuses |
| FR-001 (T022, combination) | a fresh clone whose committed files include a healed `squad.agent.md` and the five charters neither refuses nor pauses at its first start | a user edit to one of them after that start pauses |
| FR-001 (T023) | a rooted resume path outside `-ProjectPath` is refused | a path inside the project resumes; no write lands outside the fixture |
| SC-001 (T025) | `specrew init -DryRun` leaves no probe folder in the install root | a probe cleanup that fails is reported |
| FR-008 (T026) | closed-definition suite: `abandoned` without a recorded ruling is open | `abandoned` with a ruling is closed |
| FR-009 (T030) | two different messages in one stop category give two fingerprints | the same message gives one |
| FR-011 (T031) | one fixture per construct: block scalar holding `steps:`, `;#` comment | a real step still registers |
| FR-012 (T028) | the publish case with `PSGALLERY_API_KEY` set makes no publish call | the case still fails with no key |
| FR-014 (T017) | resolver on this repository with feature 201's spec | the fixture with its own `package.json` still detects `nodejs` |
| FR-015 (T033) | `accepted` with a `deferred` row naming an existing decision passes | no decision id fails; a missing decision fails; `needs-work` beside `accepted` still fails |
| FR-016 (T034) | review.md beside `executing` with the review-signoff crossing pending passes | verdict recorded with the line behind fails; no start-context gives a warning, not an error |
| FR-017 (T035) | fixture closeout: the sealed dashboard shows the delivered points, `iteration-closeout` and the iteration under Recent Shipped | a redraw that throws still seals, with a warning |
| FR-018 (T036) | fixture closeout: plan.md gets the Completed date with `complete`; the arrival names an open hardening row | a second capture leaves the date unchanged; all rows recorded gives no owed line |

FR-013, item 12 (T027), item 18 (T029), T037 and T038 are deletions, configuration or records. Their evidence is the
census, the workflow run list, the diff and the green Lint push.

## Effort Model

| Setting | Value | Notes |
| ------- | ----- | ----- |
| Effort Unit | story_points | Unit used in task effort, capacity, and retro variance. |
| Capacity per Iteration | 20 | Maximum planned effort before overcommit guidance applies. |
| Iteration Bounding | scope | The scope is the maintainer's; overcommit is surfaced, not auto-deferred. |
| Time Limit (hours) | n/a | Only applies when iteration bounding is `time`. |
| Overcommit Threshold | 1.0 | 20 planned against 20 x 1.0; no slack. |
| Defer Strategy | manual | Any deferral is the maintainer's decision. |
| Calibration Enabled | true | Retro compares actuals to these estimates. |

## Concurrency Rationale

- **Roster:** Spec Steward, Planner, Implementer, Reviewer, Retro Facilitator.
- **Conflict risk:** high on `validate-governance.ps1` (T026, T030, T033, T034), `shared-governance.ps1` (T026, T035,
  T036) and `specrew-start.ps1` / `session-recovery.ps1` (T020, T022, T023).
- **Recommendation:** run serially, one bug per commit. Order: T020, T021 (SC-002 first); T022 to T025 (SC-001); T016,
  T017; T026; T032, T031; T030; T027 to T029; T034 before T033, so the sign-off push uses it; T035, T036; T037 before
  the first review round; T038 last.

## Phase Baseline

| Phase | Estimated Effort | Notes |
| ----- | ---------------- | ----- |
| Planning | done | Spec amendment A1, clarify, design analysis (Option B) |
| Discovery/Spikes | 0.5 | T025's init-case cause; T028's release-script reading |
| Implementation | 19.75 | T016, T017, T020 to T037, including the discovery above |
| Review | allowance | Not priced in SP, apart from T038's records |
| Rework | from slack | No buffer planned. Taken so far: round 1's nine fixes (about 1.5, DRIFT-206-I002-010); the Linux rework of the per-push suites, about 1.0 estimated (0.75, plus 0.25 for the Windows publish job), actual recorded at T038 (DRIFT-206-I002-014) |

## Traceability Summary

- **Requirement scope:** FR-001, FR-003, FR-008, FR-008a, FR-009, FR-011 to FR-018; SC-001, SC-002, SC-004, SC-006 to
  SC-011.
- Every task traces to an FR or SC; every requirement in scope has at least one task.
- **Stories:** US1 start and checks (SC-001, SC-002, items 21 to 25, 33), US2 nightly, validator and closeout
  (DRIFT-010, items 30, 34, 37, 39, 41, 44), US3 test census and scripts (items 12, 17, 18, 31, 32, FR-013), US4
  resolver (FR-014).

## Notes

- **Moved to iteration 003 (the maintainer's cut, with Option B):** items 15 (1.5), 16 (0.5), 19 (0.75), 20 (1.0),
  28 (0.75) and 35 (0.75), 5.25 SP. The reviewer told the maintainer that item 35 is the one cut worth a second look.
- **Not in this iteration:** items 40, 42 and 43 (feature 203's code; hand-overs or after its merge); items 36 and 38
  (later); item 7's candidate T019.
- **The reviewer's condition (2026-11-15):** D5-a and D6-a meet on a fresh clone. T022 owns the combination test
  (FR to test mapping). Its 0.25 SP comes from T038, which is 0.25 rather than the 0.5 in the design analysis: with
  T034 landed before sign-off, T038 is the records and one green push.
- **Design analysis:** Option B, D1-a to D6-a ([design-analysis.md](design-analysis.md)). FR-015 and FR-016 were
  corrected in the spec as D1-a and D2-a require.
- **Feature 203:** T035 and T036 change `shared-governance.ps1` in parts its branch has not changed. The nearest of its
  hunks is about 100 lines from the seal call, and `Sync-SpecrewCrossingMirrors` is untouched. T026 changes
  `Test-SpecrewIterationClosed`, which 206 wrote in iteration 001. Nothing under `scripts/internal/continuous-co-review/`
  or the capture stores is touched.
- **Unchanged rules:** a failing test first and one bug per commit; home hook-file hashes before and after every
  run; `scripts/specrew-update.ps1` never run; `.squad/active-features.yml` never committed; a commit touching
  `.specify/extensions/specrew-speckit/` refreshes `.specrew-extension-runtime.json`.
- **Quality profile:** the resolver again selects a React preset (bug 6a, fixed by T017). The plan uses iteration
  001's custom PowerShell composition.
- **Load:** no test suite, lane or Pester runs while feature 203's sweeps run, until the reviewer says so.
