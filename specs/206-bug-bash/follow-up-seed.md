# Follow-up Seed: the Next Bug Bash

**Schema**: v1
**From**: feature 206 (bug bash), closed 2026-11-18
**Source**: `specs/206-bug-bash/bug-list.md`; each item there carries its evidence, its file and line, and its proposed fix
**Status**: seed only; the next bug bash's spec and plan decide scope and order

The maintainer's plan, as the reviewer session relayed it on 2026-11-17 and confirmed: close 206 and 203, then open
a new bug bash for the remaining known bugs. This file is that bug bash's starting list. It can be read alone.

Feature 206 ended with 50 open items, counted by part (item 6 has two parts). The other 40 parts: 26 fixed, 13 handed
to feature 203, and 1 closed without a fix (81).

## Release Blocker for the Next Beta: the Squad Install Specrew Advises

The maintainer, 2026-11-22 01:50 local, relayed by the reviewer session: "CI squad pin: 206 crew, small PR off main".
CI pins the SDK; this part, option C, is recorded here as a release blocker for the next beta and is not built yet.
The reviewer session is asking the maintainer whether its three parts become bug-list items.

The cause: `@bradygaster/squad-cli` 0.11.0 declares `"@bradygaster/squad-sdk": "*"`. `squad-sdk` 2.0.0, published
2026-11-19, dropped `ensurePersonalSquadDir` and `resolvePersonalSquadDir`, which the CLI's `dist/cli/core/init.js`
imports, so every `squad` command fails at start with "does not provide an export named 'ensurePersonalSquadDir'". CI
now installs `squad-sdk@1.1.0` in the same `npm install -g` as the CLI (`SQUAD_SDK_VERSION` in the workflows). A
user who follows Specrew's own advice still gets the broken pair.

1. **The repair advice reinstalls the broken pair.** Every install Specrew runs or prints names the CLI alone:
   `validate-versions.ps1` lines 349 and 403, `scripts/init/dependency-install.ps1:44` and
   `scripts/specrew-update.ps1:620`. Measured in a sandbox on 2026-11-22: a later CLI-only `npm install -g` nests SDK
   2.0.0 inside the CLI again, even with SDK 1.1.0 installed beside it, and the CLI fails. The publish harness meets
   this: its phase 5 moves the baseline to the pinned CLI through the candidate's own `specrew update --all`
   (`tests/Dockerfile.publish-test`), so the next pre-publish run is red until this part is fixed.
2. **The probe keeps only the first output line.** `validate-versions.ps1:239` keeps the first non-empty line of a
   failed `squad --version`: the path to `init.js`, not the error. The real error is hidden.
3. **Two suites turn their assertions into skips when the toolchain is broken.** `bootstrap-to-iteration.ps1`
   (lines 82 and 138) and `brownfield-conflict-handling.ps1` (lines 179 and 362) print SKIP and pass when the
   bootstrap exits non-zero, so a broken CLI reads as green in both.

The CI pin is removed when Specrew moves to a squad release whose CLI and SDK agree; this part is fixed before then.

## Read First

| Item | Severity | What | Where |
| ---- | -------- | ---- | ----- |
| 86 | major | A decision id inside an indented code example, or an unclosed fence, still counts as a ledger entry | `validate-governance.ps1`, the deferred-row check |
| 66 | major | A session start rewrites a finished iteration to "not started" when plan.md and tasks.md use different task ids | session start, task progress |
| 73 | major | A session start between the plan approval and the before-implement approval makes the tasks sync impossible to pass | session start, boundary sync |
| 83 | major | A governed agent edited the engine that governs it, and only the review engine noticed | install root, integrity markers (proposal 218's ground) |
| 74 | design question | Text rules read free prose through word lists; a structured line instead | the validator's free-text rules |

Item 74 comes before its family below: iteration 002's retro found that word-list fixes do not close the class.
T033, T026 and T031 drew 18 of iteration 002's 35 review findings.

## The Open Items, Grouped

### Validator text rules (item 74's family)

- 75, 76, 77: deferred-row and ruling wording read through word lists (minor).
- 86 (major), 87, 88: ledger and ruling readers misread Markdown structure or duplicate ids (minor).
- 53: with no start-context, a record beside an earlier phase line is accepted after its verdict (minor).
- 64, 65: hardening-gate "pending" fields are not refused; the Completed date's placeholder list and its UTC day
  (minor, note).

### Workflow and census readers, and CI

- 78, 79, 80, 89: the lane census reads YAML by lines (continued `if:`, branch filters, matrix `runs-on`, folded
  `run: >`). Iteration 002's retro suggests refusing what it cannot read.
- 10: a deployed file changed without its hash, and no CI job runs the suite that would catch it.
- 28: T002's suite takes 310 s on the Ubuntu runner on every push.
- 57: Lint installs PSScriptAnalyzer on every run, with no retry and no cache.
- 35: overlapping nightly runs can open two tracking issues.
- 82: four nightly stops share one message list (note).

### Session start, boundary sync and state truth

- 66 (major), 73 (major): session start against plan and task state.
- 85: the mirror check refuses a plan page already showing the phase being entered.
- 67, 70: the task-progress writer's words go stale, and no command runs it on demand. Met at every boundary of
  iteration 002.
- 68: the state-truth refusal names no repairing command.
- 69: a second sync of a pending crossing records it again. Met at iteration 002's closeout (DRIFT-206-006).
- 46, 47: sync wording and behaviour when markdownlint is missing, or before a crossing exists.
- 63, 71: the closeout dashboard path from the deployed copy, and the feature-closeout dashboard drawn before the
  verdict.
- 38, 45, 52: the governance lane in the preflight layout, review freshness from a fresh clone, and the validator on
  a local review store.

### The review engine and engine integrity (feature 203's area: wait for its merge)

- 83 (major): an agent edited the installed engine and re-stamped its integrity markers.
- 84: stopping after a clean passing round cannot be accepted. Feature 203's W27 may already answer it; check at its
  merge.
- 40: a waiting turn refused three times for a coverage decision, then released by the cap.
- 43: the stale-review wording at sign-off. Its 2026-11-17 sighting is the records-only refusal after a stop on
  findings; feature 203's T022 plans the fix.

### Red or stale tests

- 11: `feature-018-render-budget.ps1` sits on its 1.5 s budget.
- 15: tests depend on the installed module's dashboard renderer.
- 16, 19, 20: three suites red on removed or changed fixtures.
- 36: round 1's three partial notes from iteration 001.

### Scaffolds, deploy and publish

- 48, 49, 50: scaffold and resolver findings from feature 203's dry run.
- 54: the plan scaffold refuses a requirement scope that is in the spec.
- 55: the deploy scripts restamp files outside the feature being refreshed.
- 56: a publish from Linux fails on hidden `.gitkeep` entries.
- 6b: `.squad/active-features.yml` records the Windows user and machine name.

## Not in This Seed

- **With feature 203 (13):** 3, 7, 8, 9, 13, 14, 27, 42, 58, 59, 60, 61, 62. Each was handed over by name, and 203
  fixes them or hands them back.
  - **As of 2026-11-18, per the reviewer session:** feature 203 hands back 9, 14, 27, 42 and 62; the other 8 are fixed
    on its branch. Its note is `specs/203-beta5-stabilization/handback-to-next-bug-bash.md` on 203's branch. The next
    bug bash reads both this seed and that note.
- **Candidates the maintainer has not ruled on:** the retro scaffold refusing an explained verdict line (iteration
  002's DRIFT-023, the third sighting) and iteration 002's retro improvement actions. Both are in
  `iterations/002/retro.md`.
  - **A feature-specific pin left in a repository-wide guard** (candidate, 2026-11-18, found after 206 reached main):
    `tests/unit/every-suite-is-named-by-a-lane.tests.ps1` ended with feature 206's review plan pinned. The active plan
    had to name exactly 206's six lanes, and the parked file had to equal the plan at `d3e33550` byte for byte. On
    main that failed every branch taking main in with its own lanes: 203 and 205 both stopped on it. Four review
    rounds and the reviewer session missed it. Fixed on `fix/lane-guard-feature-pin`, where the guard judges the plan's
    shape for any feature: at least one active lane, and lane ids unique across both files. The open question for the
    next bug bash is the class, not this instance: a guard written while one feature is active should be checked for
    that feature's names before it reaches main.
