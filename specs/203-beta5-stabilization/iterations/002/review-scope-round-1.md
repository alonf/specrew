# Review Scope: Feature 203, Iteration 002, Round 1

This file is for the reviewer: what changed, and what to attack first. It is passed with `--design-context-ref`, so
it comes first in the review frame. It adds to the spec and plan and does not replace them.

- **Feature:** 203 (beta5 stabilization). **Iteration:** 002.
- **Diff base:** the merge-base of HEAD with the trunk, which the review engine resolves itself (no `--baseline-ref`):
  `origin/main` at `551bf5cde`. Features 206 and 205 are already on main, so none of their changes are in this diff;
  their own reviews covered them.
- **What the diff holds:** 377 files outside `.specify/`, `.specrew/` and `.squad/` (which the frozen tree strips):
  - **Iteration 002's own work** (from `2cacad73d`, the iteration's baseline): 65 code and test files, +10,814 and
    -2,364 lines, and 14 records files. This is the round's focus.
  - **Iteration 001's work:** 298 files. They were reviewed in iteration 001's rounds A to E and signed off
    (`specs/203-beta5-stabilization/iterations/001/review.md`). Read them where iteration 002 builds on them; do not
    re-review them as new.
    That is about where to spend effort, not about silence: a defect you can prove in them is still reportable.
- **Reviewed head:** the commit that carries this version of the file, or later records. Rounds 1 and 2 reviewed
  `103c4247a` and `2f1f87309`; the fixes of their findings, below, are code.
- **The iteration's contract:** `specs/203-beta5-stabilization/spec.md` and
  `specs/203-beta5-stabilization/iterations/002/plan.md`. `.specify/**` is excluded from the frozen tree; its copies of
  the extension scripts are mirrors checked by their hash record. Review the sources under `extensions/`.
- **This round reviews the source.** The hooks and the review rounds run from the engine pinned at `da78b600`
  (iteration 001's), so iteration 002's changes are not live during the campaign; the pin advances after sign-off.

## What Changed, by Task

| Task | Requirement | Code and tests (records under `specs/` left out) |
| --- | --- | --- |
| T015 | Site 13: wait for the stopped supervisor after `Stop-Process`; the deterministic CI suites each run under a time limit that names a hung suite and stops its process tree | `scripts/internal/continuous-co-review/co-review-service.ps1`, `tools/ci/invoke-bounded-suites.ps1`, `.github/workflows/cross-platform-validation.yml`, `tests/continuous-co-review/unit/co-review-service.Tests.ps1`, `tests/continuous-co-review/unit/bounded-suite-runner.Tests.ps1`, `tests/f198-regression-suite.ps1` |
| T016 | The HookRenderDedupe timing cases I3a and I4b without a wall-clock dependency | `scripts/internal/bootstrap/HookJournalAccessor.ps1`, `tests/bootstrap/HookRenderDedupe.Tests.ps1`, `tests/unit/bootstrap-journal-claim-age.Tests.ps1` |
| T017 | The agent invoker waits, bounded, for both reads of an exited child's output, and reports an unfinished read | `scripts/internal/continuous-co-review/worktree-reviewer.ps1`, `tests/continuous-co-review/unit/agent-invoker-output-drain.Tests.ps1` |
| T018 | F5: a second top-up with no round between grants no extra window (a fixture through the shipped command) | `tests/unit/review-budget-loop.Tests.ps1` |
| T019 | B5F-077: the tracked `.antigravitycli/` link into another machine's home removed and kept out | `.antigravitycli/f95594b5-b180-4b4d-b9e9-93dd0b5890b8.json` (removed), `.gitignore` |
| T020 | F1 (round E): the cited typed turn is found by its exact identity across every transcript window before the message-ID fallback; a compaction summary is never the cited turn | `scripts/internal/bootstrap/HumanAuthorityStore.ps1`, `tests/unit/authorization-consumers.Tests.ps1` |
| T021 | F2 (round E): a review-stop answer lost on the recovery path is reported | `scripts/internal/bootstrap/HumanAuthorityStore.ps1`, `tests/unit/typed-act-writer.Tests.ps1` |
| T022 | F4, the sign-off gate: a human-accepted disposition for the reviewed digest covers a records-only difference after it; the ordinary review end takes one approval; a finding is resolved by the run that reviews its fix or by the human's stop | `scripts/internal/continuous-co-review/review-campaign-orchestrator.ps1`, `review-signoff-evidence-gate.ps1`, `tests/continuous-co-review/unit/records-only-covers-what-deployment-writes.Tests.ps1`, `records-only-source-repo-narrowed.Tests.ps1`, `tests/unit/review-end-one-approval.Tests.ps1` |
| T023 | B5F-083: a scaffolded iteration folder with no `plan.md` is accepted with a warning while its plan crossing is the next one pending; the sync and the governance check together over the sign-off and retro sequences | `extensions/specrew-speckit/scripts/validate-governance.ps1`, `tests/unit/plan-crossing-pending.tests.ps1`, `tests/integration/record-phase-line-sync-and-check.tests.ps1` |
| T025 | F3, the hook cost: one git snapshot and one transcript tail read per hook run, handed to the providers; the stores loaded once | `extensions/specrew-speckit/scripts/specrew-hook-dispatcher.ps1`, `specrew-conformance-provider.ps1`, `conformance-turn-delta.ps1`, `deploy-refocus-hooks.ps1`; `scripts/internal/specrew-hook-dispatcher.ps1`, `deploy-refocus-hooks.ps1`; `scripts/internal/bootstrap/ConversationCaptureAccessor.ps1`, `HandoverStore.ps1`, `ProjectMetadataAccessor.ps1`; `scripts/internal/continuous-co-review/worktree-navigator.ps1`; `tests/unit/hook-git-snapshot-reader.tests.ps1`, `hook-transcript-tail.tests.ps1`, `hook-command-plain-refusal.tests.ps1`, `tests/integration/hook-run-git-snapshot.tests.ps1`, `tests/continuous-co-review/unit/continuous-co-review-navigator.Tests.ps1` |
| T026 | The t008 lane's time and the three slow suites measured (DRIFT-026) | No code in the diff. The measurement is in the drift log; its one change is the t008 lane's limit, 900 to 1,500 s, in `.specrew/verification-plan.json` (`424630ffb`, the maintainer's decision, DRIFT-027), which the frozen tree strips |
| T030 | Main merged into 203 (features 206 and 205, then pull request 4097); 203's tests brought in line with what main changed | `tests/unit/every-suite-is-named-by-a-lane.tests.ps1`, `fresh-clone-first-start.tests.ps1`, `recovery-choice-no-console.tests.ps1`, `workshop-agenda-grouping.tests.ps1`, `closeout-dashboard-redraw.tests.ps1`, `closeout-records-on-approval.tests.ps1`, `instruction-classifier-managed-blocks.tests.ps1`, `resume-path-inside-project.tests.ps1`, `squad-probe-temp-folder.tests.ps1`, `start-written-files-record.tests.ps1`, `tests/integration/workshop-agenda-confirmation.tests.ps1`; `tools/maintenance/sweep/known-red.txt` (in a records commit, `876874a72`) |
| T031 | The boundary sync reader answers for the session's own feature (B5F-093): `Get-LatestSpecrewBoundarySyncState -FeatureRef`, and its four callers pass their feature | `scripts/internal/sync-boundary-state.ps1`, `session-recovery.ps1`, `coordinator-resume.ps1`, `scripts/specrew-review.ps1`, `tests/unit/boundary-sync-reader-feature-aware.tests.ps1` |
| DRIFT-048 | A review link's four-slash file URL reads as its local path on Linux and macOS, not as a UNC host (FR-046 rework) | `extensions/specrew-speckit/scripts/turn-end-store.ps1` (`6fd9b6518`), `tests/unit/review-link-file-url-local-path.tests.ps1` (`7823c0cfd`) |
| DRIFT-050 | SC-001's fixture without its own feature claim, and a case pinning the claim decline (test-only) | `tests/integration/project-path-resolution-regression.ps1`, `tests/unit/sc001-fixture-identity.tests.ps1`, `tests/unit/every-suite-is-named-by-a-lane.tests.ps1` |
| Other | A source checkout's build id is eight characters (`5cec4bf60`); three test fixes for timing and the sealed iteration (`eee6946a6`, `a0c2e6046`, `2d6590f61`) | `scripts/internal/version-check.ps1`; `tests/continuous-co-review/unit/review-posix-runtime.Tests.ps1`, `tests/integration/self-repo-review-integrity.tests.ps1`, `tools/maintenance/sweep/sweep-driver.tests.ps1` |

## Found in Earlier Rounds

Round 1 (`103c4247a`, Codex) and round 2 (`2f1f87309`, Codex) found three majors, each fixed with its failing test
committed first:

- `finding-80a86c770ffb9e76` (T020): a tail read took a pending reservation's inferred identity as the exact cited
  turn. Red `99867e215`, fix `adc19c77d`.
- `finding-a0cc0ae3cd9703dc` (T022): on a case-sensitive volume, a path the shared classifier exempts only by ignoring
  case read as records. Red `21d6fc625`, fix `8bbb4c908`; the guard that holds the gate's list equal to the classifier
  `5e2ee6f95` (it also runs the suite on Specrew CI's Linux job); comment `2f1f87309`.
- `finding-7a5e1b6f01a5008d` (T022): a script under the active iteration's `quality/` (and `checklists/`,
  `dashboards/`, `gates/`) read as records. Red `98aaa8e92`, fix `23056509c`.
- A gap in that fix, found by the crew's own reading before round 3, not by a reviewer: the review stop answers
  (`.specrew/review/stop-answer/`, the one review-authority folder that is not gitignored) and the bypass audit were
  missing from the named records places. Red `ab98fa3ae`, fix `59dc51c2e`.

The two T022 findings were one defect: the records-only decision asked where a path is and not what it is. The fix
closes the class, not the instance. Every way `Test-ReviewCampaignDeltaIsRecordsOnly` can answer "records" is listed
in the inventory in `23056509c`'s commit message and in the iteration's drift log (DRIFT-052), row by row, with what now
decides it: a record kind for the feature's record folders and `closeout*`, a named records place for every path
outside `specs/` in this repository, and a record kind under `docs/` downstream. Attack the table, not the last hole:
a row where something that runs can still read as records.

- **Open design question put to the maintainer on 2026-11-23, not decided:** downstream, deployed machinery and host
  mirrors are records by design (DRIFT-007's twin). A finding about that row is a finding, and its disposition is the
  maintainer's.

## What to Attack First

1. **The sign-off gate accepting what it must not** (T022). In `review-signoff-evidence-gate.ps1` and the campaign
   orchestrator: a difference after the reviewed digest that is not records-only but passes as records (a script, a
   lens, a skill or a `.specify` file under a records path); a human-accepted disposition that covers a later digest it
   never saw; a finding marked resolved by a run that did not review its fix.
2. **The wrong typed turn read as the human's** (T020, T021). In `HumanAuthorityStore.ps1`: a cited turn matched by
   message ID when its exact identity exists in another window; a compaction summary, an assistant record or a pasted
   block taken as the typed turn; a stop answer dropped on the recovery path without a report.
3. **A hook acting on a stale or shared snapshot** (T025). The one git snapshot and one transcript tail per hook run:
   a provider that needs state written after the snapshot was taken; a failure in the snapshot that a provider treats
   as "nothing changed"; the deployer writing a command line the hosts cannot run.
4. **The feature-aware reader answering for the wrong feature** (T031). A feature reference given as a path or a leaf
   that matches another feature; a caller that can tell its feature but still reads by position; a session whose own
   records disagree and are not reported.
5. **A child's output or a hung suite lost** (T017, T015). The bounded wait after exit: output that arrives after the
   bound, an unfinished read not reported, a process tree that survives the stop, a suite reported green after its
   time limit.

## Not Defects of This Iteration

Deferred or decided by the maintainer; do not report them as missing. This list covers only the absence of the
deferred work and the known items named here: a new failure you find in the code around them is a finding.

- T024 (B5F-075, the boundary coverage line), B5F-076, B5F-073, B5F-072, the rest of B5F-051's census, and the hook
  providers in one process (B5F-092): moved to the follow-up feature. US4 to US7, FR-012, FR-013 and FR-044 are marked
  moved by T029's spec amendment.
- B5F-080 occurs once more, at this iteration's last task: the known defect.
- B5F-096: a `specrew start` declined on someone else's claim writes the profile and repairs the project before it
  declines. The order is the maintainer's to change; the test pins only the decline (DRIFT-050).
- `project-path-resolution-regression`'s update --info case writes the real npm cache (a hand-back item).
- The known flaky tests: `co-review-service.Tests.ps1:129`, `empty-result-retry.Tests.ps1`, and HookRenderDedupe I3a
  on records-only pushes.

## Severity

A blocking or major finding states a concrete failure scenario. Prefer one proven defect over several suspicions.
If you have a shell: `git diff 2cacad73d -- <path>` shows iteration 002's change to a file, and `git diff 551bf5cde --
<path>` the whole branch's.
