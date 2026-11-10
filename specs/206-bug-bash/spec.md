# Feature Specification: 206-bug-bash

**Status**: authored, with a recorded deviation
**Work kind (project)**: `software-feature` · **This feature's conduct**: `bug-bash`
**Created**: 2026-11-10 · **Base**: main `d3e33550`

## What this feature is

A bug bash on main's test and run-cost debt: an endless loop in `specrew start`, three dead or wrong
checks, a nightly audit that has been red and unwatched since 2026-08-08, 35 test scripts that run
nowhere, and a stray file that makes Specrew's own quality resolver call this repository a Node/React app.

## Where the bug list and root causes live

**The bug list, with the root cause and evidence for every item**:
file:///C:/Dev/specrew-206-bug-bash/specs/206-bug-bash/bug-list.md

It was written and diagnosed before this specification, as bug-bash conduct requires. This specification
states what is fixed and how it is proved; it does not restate the diagnosis.

## THE RECORDED DEVIATION

**This feature runs bug-bash conduct under a software-feature contract, and no design workshop is held**,
as feature 201 did.

- **Its conduct is bug-bash.** The flow is bug list → root cause → failing test → fix → review →
  closeout. The bug list with root causes was complete before this specification.
- **No workshop is run, by the maintainer's explicit ruling (2026-11-10).** The scope is a list of
  diagnosed defects and maintainer rulings on each; there is no product question for eight lenses to
  answer.
- **The per-feature work-kind gap still stands** (B4F-006, B4F-020): `.specrew/work-kind.yml` is
  project-scoped, so this conduct cannot be declared anywhere but here. The lens-applicability record for
  this feature is therefore empty, and the specify boundary is crossed on the maintainer's verdict with this
  deviation stated, as 201 was.

## Product domain (Light depth, confirmed 2026-11-10)

The full record is file:///C:/Dev/specrew-206-bug-bash/specs/206-bug-bash/workshop/product-domain.md. In
short: the maintainer and release owner, unattended `specrew start` runs, Copilot consumer projects and
anyone closing an iteration are affected; the pain is false or missing signals (a red nightly nobody sees,
suites that never run, checks that pass while broken). Rollout: the branch merges to main by a pull request
only when the maintainer asks; afterwards **features 203 and 205 take the fixes by merging main, and 203
removes its temporary 60-second known-red limits for the two B5F-036 suites.**

## Scope

### In scope

| Item | What is fixed |
| ---- | ------------- |
| 1 | `specrew start` with no console and stale session state refuses in plain words and never loops |
| 2a | the over-claim check finds uncommitted canonical iteration artifacts again |
| 2b | `specrew start` stops classifying its own instruction heal as a behaviour change |
| 3 | no fix; hand-over record to feature 203, and a recurrence log |
| 4 | 198/011 marked abandoned; one-time triage of the nightly's reports; frozen legacy list; nightly notification; corrected message |
| 5 | the lane-coverage guard sees every test script; each of the 35 registered or excluded with a reason; empty file deleted |
| 6a | the stray root `package.json` removed; its dependent test moved onto a fixture |

### Out of scope

- **Item 3's fix.** The candidate is in `scripts/internal/continuous-co-review/worktree-reviewer.ps1`, in
  feature 203's area, and is unproven.
- **Item 6b (B5F-022).** It needs a design choice, and 203's FR-033 touches the same file.
  `.squad/active-features.yml` stays uncommitted in this worktree.
- **Anything in feature 204's init/bootstrap scope**, and anything in `scripts/internal/continuous-co-review/`
  or the bootstrap capture stores (`HumanAuthorityStore`, `HandoverStore`). A fix that needs one of those
  stops and is brought to the maintainer.

## Requirements

### Item 1 — the no-console recovery loop

- **FR-001**: When `specrew start` finds stale session state and no console input is available,
  `Read-SpecrewRecoveryChoice` MUST NOT prompt or loop. It refuses in plain words that say what could not
  be completed, that the human's work is safe, and the one command that recovers, and `specrew start` exits
  non-zero. With console input, behaviour is unchanged.

### Item 2 — dead and wrong checks

- **FR-002**: A closed iteration whose canonical artifacts have uncommitted changes MUST fail validation
  with an `over-claim` finding naming each dirty artifact, on Windows and Unix alike. The finding names
  paths with one separator, and the test asserts that separator.
- **FR-003**: `specrew start`'s session-loaded change check MUST NOT classify Specrew's own coordinator
  instruction heal of `.github/copilot-instructions.md` as a user behaviour change. A bookkeeping-only user
  change does not trigger PAUSE-AND-CONFIRM; a behavioural user change still does.

### Item 3 — the flaky retry test

- **FR-004**: The bug list records item 3 as "cause not found, one candidate", with its evidence, marked for
  hand-over to feature 203. Every recurrence is added to its log with the run id. No code changes.
  Sightings so far: run 42715079692 ("retries once and recovers") and run 42743719583 ("does NOT retry a
  non-empty result"), both Ubuntu, both a written output read as empty.

### Item 4 — the nightly and historic work

- **FR-005**: `specs/198-beta2-hardening/iterations/011` is marked **abandoned**. Its `review.md` is not
  changed. One record, written once alongside it, says where the undone work went: FR-066's mint guard,
  T091 and T093 become **one finding owned by feature 203's follow-up**, naming
  `tools/pending/fr066-first-boundary-arrival.pending.ps1` as its test. That check is not run in this
  feature.
- **FR-006**: Every failure and warning the nightly reports for closed iterations gets a one-time triage.
  Each ends in exactly one terminal answer: **fixed mechanically**, **marked abandoned**, or **placed on the
  frozen legacy list** with a one-line reason. **Abandoned means the work was not delivered; the frozen list
  is for work that was delivered but never formally closed.** Ruled answers (maintainer, 2026-11-10):
  - 198/011 and 197/006: marked abandoned. 174/007 stays abandoned.
  - 048/001, 197/001, 198/008: frozen list, each with a one-line true reason.
  - The 15 missing dashboards (141/006-008, 174/006 and 008-011, 182/002-004, 197/003-005, 198/003): frozen
    list, reason "closed before dashboards were rendered automatically". They are not rendered (see
    Clarifications).
- **FR-007**: The frozen legacy list is closed when the triage is applied. A test fails if an entry is
  added to it afterwards.
- **FR-008**: A validator rule applies only to iterations closed after the rule shipped; history is not
  re-judged. **Mechanism: option D (maintainer, 2026-11-10)** — closure freezes the judgement: a closed
  iteration is judged only by rules marked retroactive, and each check that looks at closed iterations
  carries the date it shipped; history before that is covered by the frozen list. A per-rule registry
  (options A or C) is a later item, not this feature.
- **FR-008a**: The validator has **one definition of "closed"**, used by every path. Evidence that it has
  two today: 048/001, 197/001, 197/006 and 198/008 are absent from `.specrew/closed-iterations.yml`, so the
  nightly validates them as open, while the dashboard check calls them closed from a state.md text
  heuristic.
- **FR-009**: The Nightly Truth-Check is silent when green and notifies a person only on a **new** failure:
  the first red after a green run, or a failure set that differs from the previous run's. A run that stays
  red with the same failures sends nothing new. **Channel (maintainer, 2026-11-10): a tracking issue**,
  opened by the workflow on the first red night, commented on only when the failure set changes, and closed
  on the next green run.
- **FR-010**: The validator's review-verdict finding names the iteration's actual status. A `retro`
  iteration is no longer told "Complete iterations require …".

### Item 5 — tests that run nowhere

- **FR-011**: The lane-coverage guard (`tests/unit/every-suite-is-named-by-a-lane.tests.ps1`) MUST count
  every test script under `tests/`, whatever its file name, so a script-style suite that no lane, CI step
  or release manifest names fails the guard. Fixtures and support helpers stay excluded by an explicit,
  listed rule. The release full sweep uses the same definition.
- **FR-012**: Each of the 35 unregistered integration scripts listed in the bug list is either registered
  in a lane or the release manifest, or listed as excluded with a one-line reason. Before any of them is
  run, it is read for writes outside its project or for hook deployment; one that has them is not run, and
  is reported instead. (Maintainer, 2026-11-10:)
  - A script that turns out **red** is either fixed here, if its cause is one of this feature's items, or
    brought to the maintainer with its failure. "Excluded" is never used for a red script without the
    maintainer's ruling, and the exclusion list is shown to the maintainer.
  - `project-path-resolution-regression.ps1` and `validator-hardening-iteration2.ps1` (the B5F-036 suites)
    end **green and registered**.
  - Each script's **duration is reported**. A slow script goes to the release manifest, not a per-push
    lane, and the total per-push time added is reported to the maintainer before anything is registered.
- **FR-013**: `tests/integration/_ctl-spec.ps1` (an empty file) is deleted.

### Item 6a — the stray root package.json

- **FR-014**: The quality resolver MUST NOT suggest a Node or React preset for this repository. The stray
  root `package.json` is removed, and `f049-i003-intake-engine-tests.ps1`'s stack-detection assertion moves
  onto a fixture that carries its own `package.json`.

## Constraints on how the work is done

- **A failing test first for every fix**, and one bug per commit.
- **The real home folder is never written.** Before and after any test run in this feature, the hook files
  are hashed: `~/.specrew/specrew-hook-launch.ps1`, every file inside `~/.specrew/hook-bindings/`,
  `~/.codex/hooks.json`, `~/.copilot/hooks/*.json`, `~/.cursor/hooks.json`. Any change stops the work.
- **`scripts/specrew-update.ps1` is never run here.**
- **Pushes:** the CI's own markdownlint command before every push; after every push, Specrew CI, Test and
  Cross-Platform Validation are followed to conclusion, and a skipped gate job counts as red. The first push
  is asked for. Never main; no pull request without asking.

## Success Criteria

- **SC-001**: `tests/integration/project-path-resolution-regression.ps1` completes, green, without a
  timeout, and a no-console `specrew start` against stale state exits with the plain refusal.
- **SC-002**: `tests/integration/validator-hardening-iteration2.ps1` is green, with all three of its
  B5F-036 assertions passing.
- **SC-003**: The Nightly Truth-Check, run in full-repo CI mode on the feature's head, reports no failure,
  and every warning it reports for a closed iteration is on the frozen list or gone.
- **SC-004**: A deliberately unregistered test script of any file name makes the lane-coverage guard fail;
  removing it makes the guard pass.
- **SC-005**: Adding an entry to the frozen legacy list makes its guard test fail.
- **SC-006**: The quality resolver, run on this repository with feature 201's spec, selects no Node or
  React preset, and the moved stack-detection assertion passes on its fixture.
- **SC-007**: The home hook-file hashes are identical before and after every test run in this feature.

## Clarifications

### Session 2026-11-10 (narrow clarify, by the maintainer's ruling at the specify verdict)

Clarify was held until Specrew CI, Test and Cross-Platform Validation were green on `1aebddc3` with no job
skipped (they were), and was scoped to the dashboard seal check. Every other question was settled by the
maintainer's rulings already written into the requirements above.

- Q: Does any evidence digest or seal cover the 15 iteration folders that lack `dashboard.md`?
  A: No. The repository holds six iteration seals (199/001-003, 202/001-003), none for these folders; the
  feature closeout records and the review evidence under `.specrew/review/` hash none of them; boundary
  verdicts bind to commits and trees in git history, which a new file would not change.
- Q: Render the 15 dashboards, or keep them on the frozen list?
  A: Frozen list, reason "closed before dashboards were rendered automatically". Not rendered: a dashboard
  generated today would carry today's date on a record that closed months ago. (Maintainer, 2026-11-10.)
- Settled at the specify verdict (recorded in FR-009 and FR-012): the nightly notifies through a tracking
  issue; a red script among the 35 is fixed here or brought to the maintainer, never excluded without a
  ruling; each script's duration is reported before anything is registered.
