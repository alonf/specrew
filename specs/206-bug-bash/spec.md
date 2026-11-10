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

### Item 4 — the nightly and historic work

- **FR-005**: `specs/198-beta2-hardening/iterations/011` is marked **abandoned**. Its `review.md` is not
  changed. One record, written once alongside it, says where the undone work went: FR-066's mint guard,
  T091 and T093 become **one finding owned by feature 203's follow-up**, naming
  `tools/pending/fr066-first-boundary-arrival.pending.ps1` as its test. That check is not run in this
  feature.
- **FR-006**: Every failure and warning the nightly reports for closed iterations gets a one-time triage.
  Each ends in exactly one terminal answer: **fixed mechanically**, **marked abandoned**, or **placed on the
  frozen legacy list** with a one-line reason. The triage table is shown to the maintainer and approved
  before any of it is applied.
- **FR-007**: The frozen legacy list is closed when the triage is applied. A test fails if an entry is
  added to it afterwards.
- **FR-008**: A validator rule applies only to iterations closed after the rule shipped; history is not
  re-judged. **Its mechanism is an open decision** (see Open Decisions). If the chosen mechanism is large,
  FR-008 becomes its own item, and FR-006 and FR-007 ship first.
- **FR-009**: The Nightly Truth-Check is silent when green and notifies a person only on a **new** failure:
  the first red after a green run, or a failure set that differs from the previous run's. A run that stays
  red with the same failures sends nothing new.
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
  is reported instead.
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

## Open Decisions

- **FR-008's mechanism** (how the validator knows when a rule shipped). Options are in the bug list's item 4
  section; the maintainer chooses before it is designed.
- **The triage table's terminal answers** (FR-006), proposed in the bug list; the maintainer approves
  before they are applied.
