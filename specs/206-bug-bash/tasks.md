# Tasks: 206-bug-bash (iteration 001; iteration 002 listed)

**Feature**: 206-bug-bash
**Plan**: file:///C:/Dev/specrew-206-bug-bash/specs/206-bug-bash/plan.md
**Iteration plan**: file:///C:/Dev/specrew-206-bug-bash/specs/206-bug-bash/iterations/001/plan.md
**Date**: 2026-11-11
**Effort unit**: story points. Iteration 001 is 20/20 with no slack (maintainer, plan verdict 2026-11-11): any
task that grows so the total would pass 20 stops the work for the maintainer. Review is not priced in SP.

Conduct is bug-bash. **Every fix lands with a failing test first, one bug per commit.** On every commit:
mirror parity (`extensions/` ↔ `.specify/`), the CI markdownlint command, and `validate-governance -ChangedOnly`
against the push base CI will use (DRIFT-206-I001-001). Before and after every test run, the home hook files are
hashed: `~/.specrew/specrew-hook-launch.ps1`, every file in `~/.specrew/hook-bindings/`, `~/.codex/hooks.json`,
`~/.copilot/hooks/*.json`, `~/.cursor/hooks.json`. Any change stops the work.

**Never run on this machine:** `tests/integration/deployed-extension-marker-on-update.tests.ps1` and
`tests/integration/receipt-outcomes-retired.tests.ps1` (bug list item 8), and no lane from
`.specrew/verification-plan.json`. No review round starts until a verification plan naming only 206's own checks,
each read for home writes first, has been brought to the maintainer.

## Execution order

T001, T002, T003, T004, T005 (stop), T006, T007, T008, T009, T011, T010, T012, T013, T014 (stop), T015, T018.

- T005 (the closed/open table) comes before T006 changes the definition (design condition 1), and **ends in a
  stop**: the table goes to the maintainer, who rules on 198/010, before T006 and T007 start (tasks verdict,
  2026-11-11).
- T010 runs after T011, out of number order, so the replay sees the corrected message too (tasks verdict).
- T007, T008, T009 and T011 land before T010's replay, which checks that none of them produced a new finding.
- T013 (the census) comes before T014, so T014 reads the scripts the census will count.
- T014 ends in a stop for the maintainer; T015 registers nothing before that ruling.
- T018 is the last acceptance check.
- No task touches a full-validation trigger path (`.specrew/config.yml`, `constitution.md`, `iteration-config.yml`,
  `role-assignments.yml`, `presets/**`, `lenses/**`, `roadmap.yml`, `.squad/identity/wisdom.md`).

## Phase 1: Start and checks (US1, items 1 and 2)

- [ ] T001 [owner: Implementer] [sp: 1.5] **No-console recovery refusal and a three-try cap.**
  - **RED:** a unit test calls `Read-SpecrewRecoveryChoice` with console input unavailable and stale session state;
    today it loops on `Read-Host`. A second case gives an interactive console three invalid answers.
  - **Work:** refuse in plain words when console input is not available (what could not be completed, that the
    human's work is safe, the one recovering command `--recovery-choice A|B|C`); `specrew start` exits non-zero.
    Interactive: at most three invalid answers, then the same refusal. No stdin read (the B5F-034 hang class).
  - **Acceptance:** both cases green; with console input and a valid answer, behaviour unchanged; no fourth prompt.
  - **Trace:** FR-001; SC-001 (refusal half).
  - **Owns:** `scripts/internal/session-recovery.ps1`, `scripts/specrew-start.ps1`, `tests/unit/**`.
- [ ] T002 [owner: Implementer] [sp: 0.5] **Over-claim dirty check: one path separator.**
  - **RED:** `tests/integration/validator-hardening-iteration2.ps1` assertions 1 and 2 (failing today).
  - **Work:** the git-path normalization and the canonical artifact list use one separator; the finding names
    paths with it, and the test asserts it.
  - **Acceptance:** assertions 1 and 2 green on Windows and Unix; a clean artifact gives no finding.
  - **Trace:** FR-002; SC-002.
  - **Owns:** `extensions/specrew-speckit/scripts/validate-governance.ps1` and its `.specify` mirror,
    `tests/integration/validator-hardening-iteration2.ps1`.
- [ ] T003 [owner: Implementer] [sp: 1.5] **Change classifier ignores Specrew's matched marker blocks only.**
  - **RED:** assertion 3 of `validator-hardening-iteration2.ps1`, plus a classifier unit suite.
  - **Work:** before comparing, strip every `specrew-managed` block from both sides **only when its opening and
    closing markers form a matched pair**; any missing or unbalanced marker compares the whole file as today.
  - **Acceptance (design condition 3):** a matched block is stripped and the heal does not pause; a missing or
    unbalanced marker pauses; a user change outside the markers is still classified as the user's.
  - **Trace:** FR-003; SC-002.
  - **Owns:** `scripts/specrew-start.ps1`, `scripts/internal/instruction-file-merge.ps1` (marker constants, read if
    shared), `tests/unit/**`, `tests/integration/validator-hardening-iteration2.ps1`.

## Phase 2: Nightly and history (US2, items 3 and 4)

- [ ] T004 [owner: Implementer] [sp: 0.5] **Open the hand-over record for feature 203.**
  - **Work (tasks verdict, 2026-11-11):** one record, with a separate section per item, each with its own
    evidence and proposed owner:
    1. bug list item 3: the flaky retry test, cause not found, one candidate, its recurrence log;
    2. bug list item 7: the Windows review-runtime hang, run 42913380735, no log kept;
    3. the FR-066 mint guard with T091 and T093, one finding, with
       `tools/pending/fr066-first-boundary-arrival.pending.ps1` as its test (not run);
    4. DRIFT-198-I010-004, whatever the maintainer rules for 198/010;
    5. bug list item 8: the two update-calling suites, cross-referenced to feature 205's H-001 and feature 203's
       B5F-039.
  - **Closed by T018**, after adding anything T014 or the other tasks find that belongs to 203.
  - **Acceptance:** each section names its evidence, run ids and proposed owner; no code changes.
  - **Trace:** FR-004, FR-005.
  - **Owns:** `specs/206-bug-bash/bug-list.md`, `specs/206-bug-bash/iterations/001/**`.
- [ ] T005 [owner: Implementer] [sp: 1.0] **Closed/open table before the definition changes (design condition 1).**
  - **Work:** every iteration with its answer under the closed index, the state.md heuristic, the renderer rule and
    the new function; every iteration whose answer changes, listed with the reason. **198/010 is included as
    awaiting the maintainer's ruling**, with its status, T082 and DRIFT-198-I010-004; it is marked nothing.
  - **Acceptance:** the table is committed and brought to the maintainer; **STOP** for the ruling on 198/010.
    T006 and T007 do not start before it.
  - **Trace:** FR-008a.
  - **Owns:** `specs/206-bug-bash/iterations/001/**`.
- [ ] T006 [owner: Implementer] [sp: 2.0] **One definition of "closed".**
  - **RED:** a unit suite for `Test-SpecrewIterationClosed` over index, status and frozen cases; a review verdict
    alone never makes an iteration closed.
  - **Work:** closed = in the closed index, or `Iteration Status` `complete` / `abandoned` (abandoned only with a
    recorded ruling, T009); frozen entries are not closed. Used by the validator's closed filter, the dashboard
    check and the renderer; the state.md heuristic and the review-verdict rule are removed.
  - **Trace:** FR-008a.
  - **Depends:** T005.
  - **Owns:** `extensions/specrew-speckit/scripts/shared-governance.ps1`,
    `extensions/specrew-speckit/scripts/validate-governance.ps1`, their `.specify` mirrors,
    `scripts/internal/dashboard-renderer.ps1`, `tests/unit/**`.
- [ ] T007 [owner: Implementer] [sp: 1.0] **The triage applied: abandoned and frozen.**
  - **Work:** 198/011 and 197/006 marked `abandoned`, each recording the maintainer's ruling of 2026-11-10;
    198/011's `review.md` unchanged. `.specrew/legacy-frozen.yml` with exactly 18 entries and one true reason each:
    048/001, 197/001, 198/008, and the 15 dashboards ("closed before dashboards were rendered automatically").
  - **Acceptance:** the nightly's 198/011 failure is gone in a CI-mode full-repository run.
  - **Trace:** FR-005, FR-006.
  - **Owns:** `specs/198-beta2-hardening/iterations/011/{state,plan}.md`,
    `specs/197-continuous-co-review/iterations/006/{state,plan}.md`, `.specrew/legacy-frozen.yml`.
- [ ] T008 [owner: Implementer] [sp: 1.5] **Frozen means judged by nothing (design condition 2).**
  - **RED:** a guard test pinning the 18 keys fails on an added key; a test runs the validator over each frozen
    entry and asserts zero findings.
  - **Work:** the validator skips frozen entries in both open-iteration and closed-iteration checks. 197/006 is
    abandoned, not frozen; the dashboard check applies to `complete` iterations only (maintainer, plan verdict).
  - **Trace:** FR-007; SC-005.
  - **Depends:** T007.
  - **Owns:** `extensions/specrew-speckit/scripts/validate-governance.ps1`,
    `extensions/specrew-speckit/scripts/shared-governance.ps1`, their `.specify` mirrors, `tests/unit/**`.
- [ ] T009 [owner: Implementer] [sp: 1.5] **`since`, the closure stamp, and abandonment by ruling.**
  - **RED:** the dashboard check with and without a `closed_at_source: closeout` stamp, before and after
    `since: 2026-05-26`; an `abandoned` status with no recorded ruling is not closed.
  - **Work:** the dashboard check declares `since` and `applies_to_status: complete`, replacing the feature-number
    cut-off; iteration closeout writes `closed_at_source: closeout`; an unstamped entry is not judged by a `since`
    check. The tests pin the rulings for 198/011 and 197/006 (2026-11-10) and 174/007 (2026-06-14).
  - **Trace:** FR-008.
  - **Owns:** `extensions/specrew-speckit/scripts/validate-governance.ps1`,
    `extensions/specrew-speckit/scripts/shared-governance.ps1`, their `.specify` mirrors, `tests/unit/**`.
- [ ] T011 [owner: Implementer] [sp: 0.5] **The review-verdict finding names the real status.**
  - **RED:** the validator's message for a `retro` iteration says "Complete iterations require …".
  - **Acceptance:** a `retro` iteration is named as such; a `complete` iteration keeps its message.
  - **Trace:** FR-010.
  - **Owns:** `extensions/specrew-speckit/scripts/validate-governance.ps1` and its `.specify` mirror,
    `tests/unit/**`.
- [ ] T010 [owner: Implementer] [sp: 0.5] **Local nightly replay (design condition 1, acceptance).**
  - **Work:** `$env:CI='true'`, `validate-governance.ps1 -FullRun` on the branch head.
  - **Acceptance:** no failure; no iteration whose answer changed in T005 produces a new finding; every warning for
    a closed iteration names a frozen entry or is gone. **If a changed iteration produces a new finding, the work
    stops and that iteration goes to the maintainer; it is not added to the frozen list.**
  - **Trace:** FR-006, FR-008a; SC-003.
  - **Depends:** T006, T007, T008, T009, T011.
  - **Owns:** `specs/206-bug-bash/iterations/001/**`.
- [ ] T012 [owner: Implementer] [sp: 2.5] **Nightly tracking issue (design condition 4).**
  - **RED:** a Pester suite with recorded `gh` calls: the first red opens, the same failures stay quiet, changed
    failures comment, green closes; the rendered title, body and comments contain no path, user or machine name.
  - **Work:** `scripts/internal/nightly-tracking-issue.ps1` with injectable `gh`; the validator writes a findings
    file (`-FindingsJsonPath`); a separate notifier job alone holds `issues: write`, the workflow default stays
    `contents: read`.
  - **Trace:** FR-009.
  - **Owns:** `scripts/internal/nightly-tracking-issue.ps1`, `extensions/specrew-speckit/scripts/validate-governance.ps1`
    and its `.specify` mirror, `.github/workflows/specrew-nightly-truth-check.yml`, `tests/unit/**`.

## Phase 3: Test census (US3, item 5)

- [ ] T013 [owner: Implementer] [sp: 2.0] **One shared test census.**
  - **RED:** the lane guard passes today with an unregistered `tests/integration/zz-probe.ps1`.
  - **Work:** `tests/support/test-census.ps1`, used by the lane guard and the release full sweep: every `.ps1`
    under `tests/`, classified by content (`Describe` makes a Pester suite), fixtures and support helpers excluded
    by one listed rule, and one exclusion list with a reason per entry.
  - **Acceptance:** SC-004 both ways.
  - **Trace:** FR-011; SC-004.
  - **Owns:** `tests/support/test-census.ps1`, `tests/unit/every-suite-is-named-by-a-lane.tests.ps1`,
    `tests/full-powershell-test-sweep.ps1`.
- [ ] T014 [owner: Implementer] [sp: 2.0] **The 35 scripts: read, run the safe ones, then stop for the maintainer.**
  - **Read first:** each script for writes outside its project or hook deployment. **Any script that calls
    `specrew-update.ps1` or the hook deployment is not run and is listed for the maintainer.**
  - **`project-path-resolution-regression.ps1`** (maintainer, plan verdict): it calls `specrew-update.ps1` only
    with `-InfoMode`, plus `specrew start -NoLaunch` and `specrew init -DryRun` on fixtures. Before it runs, those
    three code paths are read and the answer is stated: does any write the home folder or deploy hooks? If all
    three are read-only, it runs with the home hook files hashed before and after. If not, it goes to the
    maintainer before SC-001.
  - **Run:** each safe script, with the home hashes before and after, recording its duration and result.
  - **STOP:** the exclusion list with reasons, every red script with its failure (fixed here only if its cause is
    one of this feature's items), every not-run script, each duration, and the per-push time registration would
    add. Nothing is registered before the maintainer rules.
  - **Trace:** FR-012; SC-001, SC-007.
  - **Depends:** T013.
  - **Owns:** `specs/206-bug-bash/iterations/001/**`.
- [ ] T015 [owner: Implementer] [sp: 1.0] **Register the 35 per the maintainer's ruling.**
  - **Work:** a per-push lane or the release manifest per the ruling; slow scripts to the release manifest; a
    suite added to a verification lane is read under T014's rule first.
  - **Acceptance:** `project-path-resolution-regression.ps1` and `validator-hardening-iteration2.ps1` green and
    registered (unless the maintainer ruled otherwise at T014); the census guard green.
  - **Trace:** FR-012; SC-001, SC-002.
  - **Depends:** T014 and the maintainer's ruling.
  - **Owns:** `.github/workflows/specrew-ci.yml`, `.specrew/release-gate-suites.txt`,
    `.specrew/verification-plan.json`, `tests/support/test-census.ps1`.

## Phase 4: Acceptance

- [ ] T018 [owner: Implementer] [sp: 0.5] **Acceptance checks.**
  - The branch diff against `main` touches nothing under `scripts/internal/continuous-co-review/**` or
    `scripts/internal/bootstrap/**`.
  - `.squad/active-features.yml` is in no commit.
  - No commit touches a full-validation trigger path.
  - The home hook-file hashes match before and after every run (SC-007).
  - **Close the 203 hand-over record** opened by T004, after adding anything T014 or the other tasks found that
    belongs to 203.
  - **Trace:** SC-007.
  - **Owns:** `specs/206-bug-bash/iterations/001/**`.

## Iteration 002 (listed, not planned)

Deferred from iteration 001 by the maintainer (2026-11-11), not cut: T016 (FR-013, delete the empty
`tests/integration/_ctl-spec.ps1`, 0.25 SP), T017 (FR-014 and SC-006, the resolver suggests no Node or React
preset; the f049 assertion onto a fixture; the root `package.json` removed, 1.5 SP). Candidate: T019 (the
Cross-Platform review-runtime step gets its own `timeout-minutes`; bug list item 7, 0.25 SP; a requirement is added
when iteration 002 is planned).

## Traceability

| Requirement | Tasks | | Success criterion | Tasks |
| --- | --- | --- | --- | --- |
| FR-001 | T001 | | SC-001 | T001, T014, T015 |
| FR-002 | T002 | | SC-002 | T002, T003, T015 |
| FR-003 | T003 | | SC-003 | T010 |
| FR-004 | T004 | | SC-004 | T013 |
| FR-005 | T004, T007 | | SC-005 | T008 |
| FR-006 | T007, T010 | | SC-006 | T017 (iteration 002) |
| FR-007 | T008 | | SC-007 | T014, T018 |
| FR-008 | T009 | | | |
| FR-008a | T005, T006, T010 | | | |
| FR-009 | T012 | | | |
| FR-010 | T011 | | | |
| FR-011 | T013 | | | |
| FR-012 | T014, T015 | | | |
| FR-013 | T016 (iteration 002) | | | |
| FR-014 | T017 (iteration 002) | | | |

Every iteration-001 task traces to an FR or SC; every FR and SC has a task, in iteration 001 or listed for 002.
Sum of iteration-001 effort: 20.0 SP.
