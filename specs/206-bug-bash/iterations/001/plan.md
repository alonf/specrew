# Iteration Plan: 001

**Schema**: v1
**Spec**: [../../spec.md](../../spec.md)
**Status**: planning
**Capacity**: 21.75/20 story_points
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

The whole feature in one iteration: items 1, 2a, 2b, 4, 5 and 6a fixed; item 3 handed over. Design:
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
| FR-013 | the empty `_ctl-spec.ps1` deleted | 5 |
| FR-014 | no Node or React preset for this repository | 6a |

## Tasks

| Task | Title | Requirement | Story | Effort | Owner | Owner File Globs | Status | Agent | Actual | Verdict |
| ---- | ----- | ----------- | ----- | ------ | ----- | ---------------- | ------ | ----- | ------ | ------- |
| T001 | No-console recovery refusal and three-try cap (failing test first) | FR-001 | US1 | 1.5 | Implementer | scripts/internal/session-recovery.ps1, scripts/specrew-start.ps1, tests/unit/** | planned | | | |
| T002 | Over-claim dirty check: one path separator (failing assertions 1 and 2 first) | FR-002 | US1 | 0.5 | Implementer | extensions/specrew-speckit/scripts/validate-governance.ps1, .specify/extensions/specrew-speckit/scripts/validate-governance.ps1, tests/integration/validator-hardening-iteration2.ps1 | planned | | | |
| T003 | Change classifier strips matched specrew-managed blocks only; unbalanced compares whole file (condition 3) | FR-003 | US1 | 1.5 | Implementer | scripts/specrew-start.ps1, scripts/internal/instruction-file-merge.ps1, tests/unit/**, tests/integration/validator-hardening-iteration2.ps1 | planned | | | |
| T004 | Item 3 hand-over record for 203, with the recurrence log | FR-004 | US2 | 0.5 | Implementer | specs/206-bug-bash/bug-list.md, specs/206-bug-bash/iterations/001/** | planned | | | |
| T005 | Closed-definition table: every iteration under the three current rules and the new function; changes listed with reasons (condition 1, before T006) | FR-008a | US2 | 1.0 | Implementer | specs/206-bug-bash/iterations/001/** | planned | | | |
| T006 | Test-SpecrewIterationClosed: one function for the validator filter, dashboard check and renderer; heuristic and verdict rule removed (failing test first) | FR-008a | US2 | 2.0 | Implementer | extensions/specrew-speckit/scripts/shared-governance.ps1, extensions/specrew-speckit/scripts/validate-governance.ps1, .specify/extensions/specrew-speckit/scripts/*.ps1, scripts/internal/dashboard-renderer.ps1, tests/unit/** | planned | | | |
| T007 | Mark 198/011 and 197/006 abandoned; the 203 finding (FR-066 mint guard, T091, T093); frozen list with its 18 entries | FR-005, FR-006 | US2 | 1.0 | Implementer | specs/198-beta2-hardening/iterations/011/state.md, specs/198-beta2-hardening/iterations/011/plan.md, specs/197-*/iterations/006/state.md, specs/197-*/iterations/006/plan.md, .specrew/legacy-frozen.yml, specs/206-bug-bash/** | planned | | | |
| T008 | Frozen means judged by no check; guard test for added keys; zero-findings test per entry; 197/006 resolved (condition 2) | FR-007 | US2 | 1.5 | Implementer | extensions/specrew-speckit/scripts/validate-governance.ps1, .specify/extensions/specrew-speckit/scripts/validate-governance.ps1, extensions/specrew-speckit/scripts/shared-governance.ps1, tests/unit/** | planned | | | |
| T009 | `since` on the dashboard check (complete only), closure stamp written at closeout (failing test first) | FR-008 | US2 | 1.5 | Implementer | extensions/specrew-speckit/scripts/validate-governance.ps1, extensions/specrew-speckit/scripts/shared-governance.ps1, .specify/extensions/specrew-speckit/scripts/*.ps1, tests/unit/** | planned | | | |
| T010 | Local nightly replay (CI mode, full repo): no new finding from any changed iteration, else stop for the maintainer (condition 1 acceptance) | FR-008a, FR-006 | US2 | 0.5 | Implementer | specs/206-bug-bash/iterations/001/** | planned | | | |
| T011 | Review-verdict finding names the iteration's actual status (failing test first) | FR-010 | US2 | 0.5 | Implementer | extensions/specrew-speckit/scripts/validate-governance.ps1, .specify/extensions/specrew-speckit/scripts/validate-governance.ps1, tests/unit/** | planned | | | |
| T012 | Notifier script with injectable gh, findings file, Pester (open, quiet, comment, close, no private text); notifier job alone has issues: write (condition 4) | FR-009 | US2 | 2.5 | Implementer | scripts/internal/nightly-tracking-issue.ps1, extensions/specrew-speckit/scripts/validate-governance.ps1, .specify/extensions/specrew-speckit/scripts/validate-governance.ps1, .github/workflows/specrew-nightly-truth-check.yml, tests/unit/** | planned | | | |
| T013 | Shared test census for the lane guard and the full sweep, content-classified, one exclusion list (failing guard first) | FR-011 | US3 | 2.0 | Implementer | tests/support/test-census.ps1, tests/unit/every-suite-is-named-by-a-lane.tests.ps1, tests/full-powershell-test-sweep.ps1 | planned | | | |
| T014 | The 35 scripts: read for home writes or hook deployment, run the safe ones with home hashes, durations; STOP with exclusions, red scripts and per-push total for the maintainer | FR-012 | US3 | 2.0 | Implementer | specs/206-bug-bash/iterations/001/** | planned | | | |
| T015 | Register the 35 per the maintainer's ruling; both B5F-036 suites green and registered | FR-012 | US3 | 1.0 | Implementer | .github/workflows/specrew-ci.yml, .specrew/release-gate-suites.txt, .specrew/verification-plan.json, tests/support/test-census.ps1 | planned | | | |
| T016 | Delete the empty tests/integration/_ctl-spec.ps1 | FR-013 | US3 | 0.25 | Implementer | tests/integration/_ctl-spec.ps1 | planned | | | |
| T017 | Resolver suggests no Node/React here (failing test first); f049 assertion onto a fixture; root package.json removed | FR-014 | US4 | 1.5 | Implementer | package.json, tests/integration/f049-i003-intake-engine-tests.ps1, tests/fixtures/**, tests/unit/** | planned | | | |
| T018 | Acceptance: no 203-protected path in the branch diff; .squad/active-features.yml not in it; home hashes unchanged across every run | SC-007 | US1 | 0.5 | Implementer | specs/206-bug-bash/iterations/001/** | planned | | | |

## FR to test mapping

| Requirement | Failing test written first | Negative path asserted |
| --- | --- | --- |
| FR-001 | unit: no console input + stale state returns the refusal; interactive: three invalid answers then refusal | no `Read-Host` call without console input; never a fourth prompt |
| FR-002 | `validator-hardening-iteration2.ps1` assertions 1 and 2 | a clean artifact gives no finding; the separator is asserted |
| FR-003 | `validator-hardening-iteration2.ps1` assertion 3, plus the classifier unit suite | unbalanced or missing marker pauses; user change outside markers pauses |
| FR-007 | frozen-list guard | an added key fails; every entry yields zero findings |
| FR-008 | dashboard check with and without a closure stamp, before and after `since` | an unstamped entry is not judged; an abandoned iteration owes no dashboard |
| FR-008a | `Test-SpecrewIterationClosed` unit suite over index, status and frozen cases | a review verdict alone never makes an iteration closed |
| FR-009 | notifier suite with recorded `gh` calls | same failures: no call; rendered text has no path, user or machine name |
| FR-010 | validator message for a `retro` iteration | a `complete` iteration still gets its message |
| FR-011 | lane guard with a probe script of any name | fixtures and support helpers stay excluded |
| FR-014 | resolver on this repository with 201's spec | the fixture with its own `package.json` still detects `nodejs` |

FR-004, FR-005, FR-006, FR-012 and FR-013 are records, rulings or deletions; their evidence is the bug
list, the frozen-list guard, the T010 replay and the T014 report.

## Effort Model

| Setting | Value | Notes |
| ------- | ----- | ----- |
| Effort Unit | story_points | Unit used in task effort, capacity, and retro variance. |
| Capacity per Iteration | 20 | Maximum planned effort before overcommit guidance applies. |
| Iteration Bounding | scope | The bug list is fixed by the maintainer; overcommit is surfaced, not auto-deferred. |
| Time Limit (hours) | n/a | Only applies when iteration bounding is `time`. |
| Overcommit Threshold | 1.0 | 21.75 planned exceeds 20 x 1.0; surfaced at the plan boundary. |
| Defer Strategy | manual | Any deferral is the maintainer's decision. |
| Calibration Enabled | true | Retro compares actuals to these estimates. |

## Concurrency Rationale

- **Roster:** Spec Steward, Planner, Implementer, Reviewer, Retro Facilitator.
- **Conflict risk:** high on `validate-governance.ps1` (T002, T006, T008, T009, T011, T012) and
  `shared-governance.ps1` (T006, T008, T009).
- **Recommendation:** run serially, one bug per commit. Order: T001-T004; T005 before T006; T007, T008,
  T009, T011, then T010's replay; T012; T013 before T014; the T014 stop; T015, T016; T017; T018 last.

## Phase Baseline

| Phase | Estimated Effort | Notes |
| ----- | ---------------- | ----- |
| Planning | done | Bug list, spec, clarify, design analysis complete |
| Discovery/Spikes | 1.5 | T005 table and T014's reading and timing of the 35 |
| Implementation | 20.25 | T001-T004, T006-T013, T015-T018 |
| Review | allowance | Not priced in SP |
| Rework | from slack | No buffer planned; the overcommit is surfaced instead |

## Traceability Summary

- **Requirement scope:** FR-001 to FR-014 and FR-008a. SC-001 to SC-007.
- Every task traces to an FR or SC; every FR in scope has at least one task.
- **Stories:** US1 start and checks (items 1, 2), US2 nightly and history (items 3, 4), US3 test census
  (item 5), US4 resolver (item 6a).

## Notes

- **Capacity:** 21.75 planned against 20, an overcommit of 1.75 SP, surfaced at the plan boundary.
- **Stops inside implement:** T010 stops if any changed iteration produces a new finding; T014 stops with
  the exclusion list, every red script with its failure, each script's duration and the per-push total
  before anything is registered.
- **197/006** is marked abandoned, not frozen; the dashboard check applies to `complete` iterations only
  (feature plan, "197/006, resolved").
- **Not touched:** `scripts/internal/continuous-co-review/**`, `scripts/internal/bootstrap/**`,
  `scripts/specrew-update.ps1`, `.squad/active-features.yml`.
