# Review Scope: Feature 206, Iteration 002, Round 2

This file is for the reviewer: what this round covers, and what to attack first. It is passed with
`--design-context-ref`, so it comes first in the review frame. It adds to the spec, the plan, the design analysis and
the round 1 scope file (`review-scope-round-1.md`) and does not replace them.

- **Feature:** 206 (bug bash). **Iteration:** 002. **Round 1** reviewed Phase 5 at head `7c006d67` (run
  `run-20261115-233001030-c21b0c2f`, verdict findings, 10 findings, none blocking).
- **This round:** the nine round 1 fixes, then Phases 6 to 9 (T016, T017, T024's registration, T026 to T036), all
  since `7c006d67`. Every task except T038 (the sign-off records) is done.
- **Requirements:** FR-008 and FR-008a (closed iterations), FR-011 and FR-012 (the census and the scripts no lane ran),
  FR-015 to FR-018 (review and closeout records), SC-001, SC-007 (no test writes the real home folder) and SC-008 to
  SC-011.
- **Design:** Option B, decisions D1-a to D4-a (Phase 9): `specs/206-bug-bash/iterations/002/design-analysis.md`.
- **Mirrors:** `extensions/specrew-speckit/**` is the source. Each `.specify/extensions/specrew-speckit/**` change is a
  byte copy with its hash refreshed in `.specrew-extension-runtime.json`, which lane `f206-deployed-hash-record` checks.
- **Not in scope:** `scripts/internal/continuous-co-review/**`, the capture stores under `scripts/internal/bootstrap/`
  and `extensions/specrew-speckit/scripts/specrew-conformance-provider.ps1` are feature 203's and were not changed.

## Maintainer Answers This Round Rests On

All three were given on 2026-11-16 at 11:34 local, relayed by the reviewer session. The maintainer typed "OK for all"
to the line "206: all four abandoned, publish suite per push, per push".

1. **T026:** 197/002, 197/007, 197/008 and 198/005 are abandoned by the maintainer's ruling. Each state.md records it
   in a `## Disposition` sentence.
2. **T028:** `tests/integration/distribution-module-publish.ps1` runs on every push.
3. **T024:** SC-001's script runs on every push.

## What This Round Covers

### The nine round 1 fixes

Each fix has a failing test first and one finding per commit (DRIFT-206-I002-010):

- F1 `409df238`
- F2 `541708af`
- F3 `1553dbdc`
- F4 `79c3c224`
- F5 `0245115a`
- F6 `5bbaec3b`
- F7 `55d42b72`
- F9 `f87330bd`
- F10 `32244053`

F8 is noted and not changed.

### Phases 6 to 9

Each code fix landed with a failing test first, then the fix, one bug per commit:

| Task | Item | Change | Test |
| --- | --- | --- | --- |
| T016 | — | the empty `tests/integration/_ctl-spec.ps1` deleted with its census exclusion | the census guard |
| T017 | 6a | the stray root `package.json` removed; f049's stack assertion reads a fixture with its own | `tests/unit/no-node-preset-for-this-repo.tests.ps1` |
| T026 | DRIFT-206-I001-010 | `Test-SpecrewIterationClosed` counts `abandoned` as closed only when `Test-SpecrewIterationRulingRecorded` finds the ruling; group B's rulings recorded in the same commit | `tests/unit/iteration-closed-definition.tests.ps1`, `tests/unit/closed-check-since-and-ruling.tests.ps1` |
| T032 | 33 | a managed-block opener with `<<<` where `>>>` belongs is unbalanced, so the whole file is compared | `tests/unit/instruction-classifier-managed-blocks.tests.ps1` |
| T031 | 31, 32 | the census guard reads block scalars and job and step structure, and treats `;` as a comment boundary | `tests/unit/every-suite-is-named-by-a-lane.tests.ps1` and its fixtures |
| T030 | 30, 34 | every repository-level stop of the nightly check passes its message, so two messages give two fingerprints | `tests/unit/nightly-tracking-issue.tests.ps1` |
| T027 | 12 | `workflow_dispatch:` on Specrew CI | the workflow parses; CI runs |
| T028 | 17 | the release script refuses a live publish without `-ConfirmLivePublish`, which only `publish-module.yml` passes; the publish suite clears `PSGALLERY_API_KEY` itself and restores it and `SPECREW_BUILD_COMMIT` | `tests/unit/release-script-refuses-unasked-publish.tests.ps1`; the suite itself |
| T029 | 18 | `multi-host-smoke.ps1`'s loop variable no longer assigns to `$Host` (read and parsed, not run: it deploys hooks) | parse only |
| T034 | 39 | a review or retro record written while its boundary approval is pending is not stale; with no `start-context.json`, a warning naming the file | `tests/unit/record-before-approval.tests.ps1` |
| T033 | 37 | review.md accepts a `deferred` task verdict beside `accepted` when the row names a decision id in `.squad/decisions.md` | `tests/unit/deferred-task-verdict.tests.ps1` |
| T035 | 41 | the closeout tail redraws the dashboard after the mirrors and before the seal; a failed redraw warns `CLOSEOUT_DASHBOARD_NOT_REDRAWN` and still seals | `tests/unit/closeout-dashboard-redraw.tests.ps1` |
| T036 | 44 | the mirror write that moves plan.md to `complete` writes the Completed date once; the retro to iteration-closeout arrival lists the hardening gate's open items in the pending-verdict artifact | `tests/unit/closeout-completed-and-open-rows.tests.ps1` |
| T037 | — | the two reviewer-brief promotions (round 1's scope file) | — |

### Registrations

Both per-push registrations are in lane `f206-changed-integration` on this machine. In CI:

- `tests/integration/distribution-module-publish.ps1` (T028) runs in its own Specrew CI job `publish-suite-windows`
  (windows-latest, the OS of the real publish job), by the maintainer's answer of 2026-11-16 14:38 ("206 publish: A");
- `tests/integration/project-path-resolution-regression.ps1` (T024, SC-001) runs in job `deterministic-gate`, step
  "Integration - script suites no lane ran before the test census (F-206 T015)".

The census exclusions for both are removed. Both first failed on Linux CI at `792e432d` (DRIFT-206-I002-014). The
publish suite read a hidden dot-file without `-Force`, and SC-001's start met the tracked identity file's Windows path.
Both are fixed, with failing tests first. The publish suite then failed on Linux for a second cause: PowerShellGet's
own `Publish-Module -WhatIf` copy drops the hidden `.gitkeep` files that `Specrew.psd1`'s FileList names. That is why it
moved to Windows (bug list item 56).

**Known and deferred:**

- DRIFT-206-I002-013 (bug list item 52). A CI-mode full validator run in a worktree that has run a review round fails
  old accepted iterations on the local review store, while clean checkouts pass. It is not changed in this round.
- Bug list item 53, T034's CI blind spot.
  - With no `start-context.json` (CI, a fresh clone), the record is accepted with a warning. That holds even after the
    verdict is recorded, when the phase line really is stale. So CI cannot catch a stale phase line; a local run and
    the sync's mirror check can.
  - Design D2 weighed the missing file and rejected commit subjects (D2-b). It did not weigh the tracked ledger
    (`.squad/events/lifecycle-events.jsonl`, the verdict entries in `.squad/decisions.md`), which could answer in CI.
  - Judge D2-a knowing this.

## What to Attack First

0. **A path that one OS calls absolute and another does not (DRIFT-206-I002-014, `7f85bded`).** Specrew CI on Linux
   refused SC-001's start because the tracked identity file held a Windows path. `Get-SpecrewPathRootKind` now names
   the kind on every OS. Check these, on Windows and on Linux:
   - `C:\x` and `C:/x`;
   - a UNC path;
   - a POSIX absolute path;
   - a drive-relative `C:x`, which is not absolute, is never adopted, and is dropped with the warning;
   - a relative path that merely contains a colon. A single-letter folder followed by a colon (`a:b`) reads as
     drive-relative and is dropped: right on Windows, and harmless elsewhere. Judge it;
   - a tracked `now.md` carrying another machine's absolute path. It must not be adopted, it must not cause the
     stale-state refusal, and the warning must name the file and say it was not changed.

   RED of record: 14/27 at `1cb31e60`, the restored tests against the unfixed code. The "outside" case is red only on
   Linux (CI run `43851050990`); DRIFT-206-I002-014 lists each failing case and why it failed.

   `tests/integration/Test-LegacyStateReaders.Tests.ps1`:
   - no assertion changed. Its import list gained the two functions the reader uses, and it loads the path-identity
     and reparse helpers first. Its 0.23.0 fixture's `C:/example/...` path is now dropped with the warning, and the
     suite asserts nothing about it;
   - a real 0.23.0 project on Windows whose saved feature path is absolute and inside the project is still adopted:
     the reader keeps an absolute path that the inside check accepts.

   Also check every caller of the inside check for a path that still reaches `GetFullPath` or `Join-Path` before its
   kind is known. Known and unchanged: `specrew-start.ps1`'s `.specify/feature.json` auto path (about line 709) has no
   inside rule, and the FR-024 stale check in `session-recovery.ps1` decides inside with `-like`.
1. **Closed and not closed (T026).** A Disposition sentence that matches the affirmative form but denies, conditions or
   postdates the ruling. A ruling outside the `## Disposition` section. A Disposition heading of another level. An
   abandoned iteration that is also in the closed index or frozen list. Any caller of the closed definition that still
   reads `abandoned` as closed on its own: the validator's filter, the dashboard check and the renderer.
2. **The publish refusal (T028).** Any path to `Publish-Module` without `-ConfirmLivePublish`. A key that reaches the
   release script other than through its parameter. A run of the suite that leaves either environment variable changed.
   Whether the CI step that now runs the suite can see the secret. The facts to check, at `1edab530`:
   - only `.github/workflows/publish-module.yml:277` maps `secrets.PSGALLERY_API_KEY`, and `specrew-ci.yml` maps no
     secret at all;
   - the suite clears the key at `tests/integration/distribution-module-publish.ps1:91`, before its first release
     call;
   - its one `-ConfirmLivePublish` call (`:261` to `:266`) depends on that clear;
   - the `finally` at `:285` restores the key and `SPECREW_BUILD_COMMIT`.

   The new job `publish-suite-windows` in `specrew-ci.yml`:
   - Can it ever see the secret?
   - Does any path make it skip while the workflow still passes: a condition, a `needs`, `continue-on-error`, or a
     step that exits 0 without running the suite?
   - The unit suite pins no secret, windows-latest, its own timeout, and no `continue-on-error` or `if:`. Check what
     that reading of the YAML misses.
3. **Records judged before and after their approval (T034, T033).** A record accepted as pending when the crossing
   that is pending is a different one. A `deferred` row whose decision id is in a comment or a different section of
   `decisions.md`. A `deferred` row that hides a `needs-work`.
   - T034 accepts review.md beside `planning` as well as `executing` while review-signoff is pending. It kept the old
     condition and only gated it on the approval state. Feature 203's B5F-050 asked only for `executing`, and no
     legitimate review.md at `planning` is known. Is there a path where that acceptance hides a real error?
4. **The closeout tail (T035, T036).** A dashboard redraw that writes outside the iteration folder or reads the wrong
   feature. A Completed date overwritten on a later capture. A placeholder shape that is not filled. An open hardening
   row that the arrival does not list, or a recorded row that it lists.
5. **The census guard by structure (T031).** Each YAML and shell construct that can hide or fake a step: block scalars,
   flow sequences, anchors and aliases, keys of the same name at other levels, `;` and `&&` inside quotes.

**Two standing instructions from iteration 001's retro (T037):**

- **For any text-matching rule, try a phrasing that matches the pattern but denies or conditions it.** In iteration
  001, rounds 1 to 3 each found one.
- **For any test that reads workflow or script files, try each YAML and shell construct that can hide or fake a
  line:** comments, block scalars, keys of the same name at other levels, and statement delimiters (rounds 2 to 4).
