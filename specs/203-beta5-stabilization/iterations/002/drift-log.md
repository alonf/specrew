# Drift Log: Iteration 002

**Schema**: v2

<!--
  Markdown authoring note (Specrew lifecycle convention):

  When you add new drift events to this file, watch for MD032 (blanks-around-lists).
  A sentence ending with a colon, immediately followed by a bullet list, is the most
  common violation. Always put a BLANK LINE between the colon line and the list:

      BAD:                              GOOD:
      Resolution steps:                 Resolution steps:
      - Step one                        <— blank line here
      - Step two                        - Step one
                                        - Step two

  The F-033 pre-boundary markdownlint gate runs markdownlint-cli --fix on .md
  changes before every boundary-sync write, so most violations auto-fix — but the
  blank line you write in the first place avoids the cleanup churn.
-->

## Summary

**Total drift events**: 4 (DRIFT-001 to DRIFT-004)
**Resolution rate**: 4 of 4 handled locally; each entry's Class closure line states its product class
**Specification drift**: None detected

## Events

### DRIFT-001 — Two maintainer decisions made before this folder existed (maintainer's decisions; pointer)

- **Where they are recorded**: in `docs/beta5-findings.md`, in the note dated 2026-11-16, pushed as `2cacad73` at 03:19
  local. This folder could not be pushed before its plan exists (B5F-083), and the reviewer session ruled that the
  decisions should not wait in a scratch note.
- **"203, here: \"launcher: wait\""** (03:13 local on 2026-11-16, relayed by the reviewer session). The project's Claude
  hook launcher is not redeployed until 203 merges or the maintainer decides otherwise. Still owed: T006's launcher
  half, the plain-text refusals (iteration 001's DRIFT-046). Its placement is in this iteration's design analysis.
- **"rerun: add HookRenderDedupe"** (02:56 local on 2026-11-16, relayed). For 203, which owns the test: one rerun only on
  a push of records only, with the sighting recorded; no exception on a push that changes code. The suite's timing
  cases are on this iteration's first-batch list.
- **Class closure**: NONE — process decisions; no code changed.

### DRIFT-002 — The before-plan resolve misread the stack again (finding, B5F-085)

- **What happened**: `resolve-quality-profile.ps1 -ProjectPath .` (2026-11-16, about 03:15 local) returned exit 0 and
  `quality-profile.custom-composition.v1`, built from `node-rest-with-postgres` (90) and `react-spa-public` (80), with
  surfaces api-runtime (Node.js) and browser-ui. It wrote no file. This repository is PowerShell scripts. It is the same
  misread as iteration 001's DRIFT-001; the maintainer said at the plan verdict of 2026-10-31 that it "will misread the
  next feature too".
- **Handling**: corrected by hand in this iteration's plan, as in iteration 001.
- **Class closure**: NONE — B5F-085, a candidate for feature 206's list.

### DRIFT-003 — The iteration scaffold's own defects, met while opening this iteration (findings, B5F-081 to B5F-084)

- **The scaffold** (`scaffold-iteration-artifacts.ps1 -SpecDirectory specs/203-beta5-stabilization -IterationNumber
  002`, run after a dry run and a trial on a scratch clone) wrote this folder's `state.md`, `drift-log.md` and `quality/`
  files, and also `specs/203-beta5-stabilization/contracts/mechanical-findings.schema.json` at feature level. That file is
  the scaffold's own shipped schema and is kept as shipped (the reviewer session's ruling; B5F-084).
- **On the scratch trial**: the fresh folder failed the governance lane on its own `hardening-gate.md` ("overall verdict
  should be 'ready' based on the concern rows but found 'blocked'", B5F-081); the template has 3 x MD038 in its own text
  (B5F-082); and the folder cannot be pushed without `plan.md` (B5F-083). So this folder is committed with the design
  analysis and pushed with `plan.md` at the plan boundary, as feature 205 did, and the hardening rows are filled by the
  planning that decides them.
- **Class closure**: NONE — B5F-081, B5F-082 and B5F-084 are candidates for feature 206's list; B5F-083 is placed with
  B5F-050 and B5F-059 in this iteration's design analysis.

<!--
  Every new ### DRIFT-... event includes:

  - **Class closure**: the executable mechanism that makes the next instance impossible or loud

  If the change fixes only this instance, write NONE — <why class closure is not in scope>.
  A bare Resolution: FIXED is not class closure.
-->

### Resolution Strategies (Unused)

The following resolution strategies remain available if drift is detected later in execution:

- **spec-updated**: Update the spec to reflect implementation choice
- **implementation-reverted**: Revert implementation to match spec
- **deferred**: Mark drift as deferred to next iteration
- **human-decision**: Escalate to Alon for resolution

### Notes

- This artifact was scaffolded before review starts so drift can be logged immediately when detected.
- Replace the zero-drift summary with real counts when the first drift event is recorded.

### DRIFT-004 — Site 13 failed alone on a docs-only push (CI sighting; evidence for the first-batch fix)

- **The run**: Specrew CI `43785562285` on `2cacad73` (one Markdown file, `docs/beta5-findings.md`), attempt 1. The
  Deterministic gate failed at 01:26:41Z (03:26 local, 2026-11-16) in the F-198 honesty regression suite, "1 of 132
  FAILED", and the Contract lane was skipped. Test and Cross-Platform Validation were green.
- **The case**: `tests/continuous-co-review/unit/co-review-service.Tests.ps1:129`, "a FAILED lease owner-handoff STOPS
  the spawned supervisor ...": "Expected $null or empty, because a supervisor whose lease handoff failed must not keep
  running unprotected, but got System.Diagnostics.Process (pwsh)." This is B5F-051's site 13 (`Stop-Process -Force` with
  no wait in `co-review-service.ps1:216`). It passed on `7daceb7d` an hour earlier.
- **Handling**: 203's own pushes have no rerun exception for it, so the crew asked. One rerun on the reviewer session's
  routine ruling, for this push only: attempt 2 green, every job run (Lint, the firewall, the Deterministic gate and the
  Contract lane). The reviewer session will ask the maintainer whether 203's records-only rule should cover site 13 and
  `empty-result-retry` as it covers HookRenderDedupe.
- **Class closure**: NONE — site 13's fix is proposed for this iteration's first batch (design-analysis.md).

### DRIFT-005 — A Windows hang in the deterministic suites step on feature 206's push (evidence; handed over)

- **The run**: on 206's push `fdb42f2d` (release script, publish workflow, publish test; nothing 203's suites read),
  Cross-Platform Validation `43793714104`, attempt 1, the Windows job "Deterministic fake-provider review runtime"
  (job `133057670105`) hung in the step "Run bounded deterministic review fault and conformance suites". It started at
  02:44:26Z (04:44 local, 2026-11-16), never completed, and was cancelled at 30 minutes against the job's
  `timeout-minutes: 25`. No log was kept (BlobNotFound). The same step took 133 s on `53bc6574` and 130 s on attempt 2
  (job `133068036828`, all 8 jobs green). Feature 206 records it as DRIFT-206-I002-012 at `eac9e210`; the reviewer
  session handed it over.
- **A possibility, not a finding**: a review process that does not exit on Windows, site 13's family (`Stop-Process`
  with no wait).
- **What the step has** (`.github/workflows/cross-platform-validation.yml:243`, `:299-364`): no per-suite time limit.
  On Windows it runs 14 suites one after another in the step's own `pwsh` through `Invoke-Pester -Output Detailed`,
  with no step-level `timeout-minutes`; only the job's 25 minutes bound it. It prints `--- deterministic suite: <path>`
  before each suite, so the live log would have named the suite and the last test; the job-level cancel lost that log.
  The cancel came five minutes after the job's limit.
- **Class closure**: NONE — the plan's flaky-test task takes a per-suite time limit that names the suite and stops its
  process tree, and a step-level `timeout-minutes` below the job's so a hang fails the step and keeps its log.

### DRIFT-006 — The maintainer's nine design decisions and "203 rerun: yes", relayed

- **The words**: "OK for all", typed by the maintainer to the reviewer session specrewreviewer-98 at 11:34 local on
  2026-11-16 and relayed under the wider delegation, answering two lines quoted in design-analysis.md's Human Decision.
- **What they decide**: Option A, A-buffered, merge then a follow-up feature, the first-batch order as recommended, the
  pin advance placed after the first batch's round (the advance itself still needs their typed `advance the pin`),
  B5F-077's link removed, the t008 lane measured first, T006's launcher half with F3's push (refining "launcher: wait"
  of 03:13), the rest of the census later. The merge shape is recorded in `.squad\decisions.md` as
  `f203-i002-merge-then-follow-up`.
- **"203 rerun: yes"**: on 203's records-only pushes, a sole failure of site 13 (`co-review-service.Tests.ps1:129`) or
  `empty-result-retry.Tests.ps1` is rerun once without asking and the sighting recorded; a second failure stops; no
  exception on a push that touches code. HookRenderDedupe stays as ruled at 02:56.
- **Not an approval**: no boundary is crossed by it; the plan boundary takes the maintainer's own typed verdict.
- **Class closure**: NONE — a record of a decision, not a defect.

### DRIFT-007 — The iteration's scope: option 1 (B5F-080 out, the buffer stated in the plan's text)

- **The words**: "option 1 it is", typed by the maintainer to the reviewer session at 11:49 local on 2026-11-16 and
  relayed, answering option 1 as shown: "B5F-080 out, full 2 SP buffer", task rows of 19.25 of 20 and a 2.0 SP buffer
  stated in the plan's text. Recorded in `.squad\decisions.md` as `f203-i002-scope-option-1`.
- **Why it was asked**: the merge shape adds the Copilot and Codex capture walk (1.0), the per-suite time limit and
  step-level `timeout-minutes` for the deterministic suites (0.5, DRIFT-005) and the spec amendment (0.25), which did
  not fit A-buffered's 20. The crew's first figures to the reviewer session left the 0.5 out and gave 18.75; the
  reviewer session caught it and the corrected figures went to the maintainer.
- **A dry run before the choice** (scratch worktree under the crew's scratchpad, removed by its path): the governance
  check accepts requirements marked as moved with no code change. Its capacity check (`validate-governance.ps1`,
  `Test-PlanningCapacity`) runs only at Status `planning`, sums the task rows, and fails a plan over 20 x 1.0 with no
  waiver; iteration 001's plan (32/20, then 28.5/20) turned Specrew CI red on it (run `41197840420`). So the buffer is
  not a task row.
- **B5F-080**: moves to the follow-up feature. It will occur once more at this iteration's last task; that is the
  known defect, not a new one.
- **Class closure**: NONE — a scope decision, not a defect.

### DRIFT-008 — The plan push goes under the records rule, on the reviewer session's ruling

- **The push**: the five held commits, `79d26013` to the plan commit. Nothing under `scripts/`, `extensions/`, `tests/`
  or `.github/`; Markdown under `specs/` and `.squad/`, and two JSON files the iteration scaffold wrote:
  `specs/203-beta5-stabilization/iterations/002/quality/mechanical-findings.json` and
  `specs/203-beta5-stabilization/contracts/mechanical-findings.schema.json`. The second sits outside the iteration
  folder because the scaffold writes it there (B5F-084), not by the crew's choice.
- **The ruling**: the reviewer session (specrewreviewer-98) checked the diff and ruled the two JSON files iteration
  records, so the records rule applies: markdownlint and the governance check, no lanes; CI is the test run. This
  replaces its earlier "lanes green first" for this push only.
- **The check it asked for**: both files parse, and `mechanical-findings.json` validates against the schema with
  `Test-Json` (True), the same check `run-mechanical-checks.ps1:1162` makes.
- **Class closure**: NONE — a record of how this push was checked.

### DRIFT-009 — The reviewer session's five comments on the plan, worked in before the plan sync

- **The comments** (specrewreviewer-98, on `8970a0e7`; none changes scope): (1) write out the review and pin sequence,
  and where T027 lands; (2) say what the maintainer does in T028; (3) say the merge is not a task, with its cost if
  205 and 206 reach main first; (4) name T025's measure and what counts as done; (5) correct the hardening gate's
  `Reviewed At`.
- **(1)**: the plan's "advanced engine" for T027 is the pin at `da78b600`, the engine advanced at T014 in iteration 001
  (iteration 001 DRIFT-092, departure B), not the advance this iteration plans after its review. The plan now says
  so and gives the sequence round by round, with what happens if the campaign ends with no stop.
- **(2) to (4)**: in the plan's Notes and T025's row; T025's measure is DRIFT-073's method, with no target, as the
  maintainer's "measure first" covers.
- **(5)**: `Reviewed At` was the scaffold's time (01:20:42Z); it is now the plan commit's time, `09:55:13Z`, when the
  rows were written. No check reads the hardening gate's `Reviewed At`: the validator reads that label only from
  `quality-evidence.md`, and only for presence (`validate-governance.ps1:3129`).
- **Class closure**: NONE — plan corrections before the plan stop.

### DRIFT-010 — T025's pass line attributed "no target" to the wrong decision; corrected

- **What was wrong**: `962cc8a6` wrote T025's pass line as "no target (design decision: measure first)", and DRIFT-009
  said the same. "Measure first" is design decision 7, the t008 lane's 900 s limit (design-analysis.md); it says
  nothing about the hook cost. The maintainer has set no target for T025 and has not said none is needed. The
  reviewer session caught it.
- **Corrected** (T025's row): done when, structurally and proven by tests committed red first, each hook run takes one
  git snapshot and one transcript tail read handed to the providers, the stores load once and every hook check still
  runs; measured by DRIFT-073's method, before (re-measured on the tree T025 starts from; 14.1 s Stop and 4.8 s prompt
  medians on `5cb83329`) and after, median and worst, reported. If the medians do not fall, T025 is not done on the
  crew's say and goes to the maintainer with the numbers. No numeric target is set; that is the maintainer's to set.
- **Class closure**: NONE — a plan correction before the plan stop. DRIFT-009's line on (4) stands corrected by this
  entry.

### DRIFT-011 — Feature 206 already fixed T023's governance-check half; main is merged in before the review (maintainer's decision)

- **The finding** (the reviewer session, on the plan): 206's T034 (`3a3ba803`, RED `4128585a`, manifest `8b23047a`,
  suite `tests/unit/record-before-approval.tests.ps1`) adds `Get-SpecrewRecordApprovalState` to
  `validate-governance.ps1`: `review.md` beside `planning` or `executing`, and `retro.md` beside `reviewing`, are
  accepted while the review-signoff or retro approval is pending, read through the start-context reader; with no
  start context (CI) the record is accepted with a warning. That is T023's governance-check half, in the same function.
- **The crew's read**: the sync's state-truth gate needs no change; the deadlock was the validator's refusal, and
  with 206's rule the crew keeps `executing` and the sync moves the lines. Not covered by 206: B5F-083, and a test of
  the sync and the check together. The two designs agree (both read the last authorized boundary); two observations
  went to the 206 crew through the reviewer session: in CI the record is accepted even after the verdict, and
  `review.md` beside `planning` is accepted too. A trial `git cherry-pick -n` of the three commits in a scratch
  worktree (removed by its path): the test applied, the fix conflicted, since 206 changed that file in 17 earlier
  commits and the fix calls a function 203 lacks.
- **The decision**: "203: 1", typed by the maintainer to the reviewer session at 12:22 local on 2026-11-16 and relayed,
  answering "203 merge: 1, 2 or 3"; option 1 is "merge main into 203 before 203's review". Recorded in
  `.squad\decisions.md` as `f203-i002-merge-main-before-review`, with the option text.
- **The plan**: T023 1.5 to 0.75 SP (B5F-083 through 206's reader, 0.5; the end-to-end test after the merge, 0.25);
  T030, merge main into 203 before the campaign, 1.5 SP (judgment), conditional on 206 being on main, with the
  fallback after closeout; rows 20.0 of 20, a stated 22.0 with the buffer; B5F-080 stays out.
- **Class closure**: NONE — a scope decision; the rule itself is fixed once, by 206.

### DRIFT-012 — The plan crossing's bookkeeping was committed before the verdict; the capture accepted it

- **What happened**: after the plan sync (crossing `crossing-9070951c`, boundary commit `af9df07d`, 2026-11-16T11:31Z),
  the crew committed and pushed the sync's `.squad` bookkeeping as `bc9a6249` before showing the packet, to keep the
  rule of no commit between an approval and its step. Under the pin, iteration 001's later boundaries had committed
  their bookkeeping after the verdict, so this order was untried on `da78b600`; the packet said so.
- **Why it holds**: the pin's crossing check (`extensions/specrew-speckit/scripts/shared-governance.ps1:2779-2783`
  in the pinned copy) resolves the artifact state from the crossing's own boundary commit, not from HEAD. The
  maintainer's typed `approved for plan` was captured at 12:03:12Z (14:03 local), `auth_commit_hash` `bc9a6249`,
  `hook-captured-from-transcript`. An earlier `approved for plan`, typed before the packet was shown, was correctly
  not recorded ("no record of showing you that decision's packet").
- **From now on**: a boundary sync's bookkeeping is committed after the verdict, as 205 does (the reviewer session's
  agreement).
- **Also recorded with this entry**: B5F-086 (the sync's "expected feature-closeout" warning on every next
  iteration's plan; candidate for 206's list); T030's expected conflicts gain 206's Linux drive-path fix.
- **Class closure**: NONE — a record of order; nothing failed.

### DRIFT-013 — T022 narrows the records-only rule; T024 moves out (maintainer's decision); the tasks are amended before their stop

- **The question** (the reviewer session, on tasks.md at `9b75ae7b`): T022 makes the records-only definition decide
  what reaches sign-off unread; does T022 reuse the gate's classifier unchanged, or change it? The crew's answer: it
  was drafted to reuse `Test-ReviewCampaignDeltaIsRecordsOnly` unchanged, but that classifier passes six cases that
  should stale in this repository (B5F-087), and under T022 they would reach sign-off unread.
- **The decision**: "203 T022: 1", typed by the maintainer to the reviewer session at 14:17 local on 2026-11-16 and
  relayed: narrow the rule inside T022 (4.0 to 4.5 SP) and move T024 (0.5 SP, B5F-075) to the follow-up feature.
  Recorded in `.squad\decisions.md` as `f203-i002-t022-narrowed-records-rule`, with the option text.
- **One statement in the option text, checked**: "T022 already makes the sign-off packet state records and code
  separately, which covers most of what T024 was for." T024's line is a different line: the coverage line the sync
  writes into every boundary stop. With T024 out it keeps counting records as source files and keeps stating the
  campaign's own round count; T022 covers records and code apart only in the sign-off packet. The tasks packet says
  so.
- **The amendment**: T022 names the narrowing, how the code knows it is the source repository (a tested case both
  ways), its effect on the two existing consumers, and every negative case, red or passing today. The reviewer
  session's four notes are folded in: a relative link in tasks.md; T019's `.gitignore` entry and that no check refuses
  a tracked link pointing outside the repository; T023 (i)'s CI blind spot; the 50-run batches announced first and the
  CI evidence taken from the first green pushes. Rows stay 20.0 of 20, a stated 22.0 with the buffer.
- **The tasks sync** is rerun at the amended head; the first tasks sync's bookkeeping (crossing `crossing-fa6d44ed` at
  `9b75ae7b`) stays uncommitted with the second's until after the verdict.
- **Class closure**: NONE — a scope decision; B5F-087 is closed by T022 when it lands.

### DRIFT-014 — Specrew CI red on the records-only push 9b75ae7b: reviewer-hook-suppression case 1 (sighting)

- **The run**: Specrew CI `43863692367` on `9b75ae7b` (tasks.md, plan.md, the drift log, docs; no code, no test).
  The Deterministic gate failed, F-198 suite "1 of 132 FAILED in 490.583s"; the Contract lane was skipped. Lint and
  the firewall green; Test and Cross-Platform Validation green.
- **The case**: `tests/continuous-co-review/unit/reviewer-hook-suppression.Tests.ps1:22-36`, "the reviewer launch
  path passes SPECREW_REFOCUS_DISABLE=1 to the spawned reviewer child process": "Expected regular expression
  'RD=\[1\]' to match <empty>". The stub child exited 0 (the exit-code assertion passed) and
  `Invoke-ContinuousCoReviewAgentInWorktree` returned empty stdout. Green on `bc9a6249`, `af9df07d` and `02aacdb9`.
- **A possibility, not a finding**: an exit-0-with-empty-stdout race in the agent invoker's output capture, the
  family of `empty-result-retry` (T017); if so, a product defect: a real reviewer whose output is lost reads as an
  empty result.
- **Handling**: not on any rerun list; reported to the reviewer session, which ruled option (2): no rerun of
  `43863692367`, which stays red on the record as a finding; the amendment's push is the next CI run and must be
  green with every job run before the tasks sync and the packet. If this case, or any case not on a rerun list, is
  red again on that push, the crew stops and reports. Attached to T017 as evidence; no change to T017's size or
  text. If T017's cause is in the agent invoker's output capture and its fix exceeds 0.5 SP, the crew comes back
  before building it.
- **Class closure**: NONE — evidence for T017.

### DRIFT-015 — T022's narrowing turned round for Markdown and text (the reviewer session's comment)

- **The comment** (on `5dd6b393`): a list of source places misses tracked Markdown and text that hosts execute or
  tests depend on: 978 `.md` and `.txt` fixtures under `tests/`, `.agents/skills` and agent text, `.github/prompts`
  and `.github/agents`, Markdown under `scripts/`, `hosts/` and `tools/`, `AGENTS.md` and `CLAUDE.md`. A list of
  source places is always one host directory behind.
- **The amendment**: in the source repository, a `.md` or `.txt` file is records only in a named records place (the
  active feature's output allowlist, the `.squad` records the syncs and the scribe write, two `.specrew` logs and the
  inline review output, `docs/**/*.md` except `docs/methodology/**`, `proposals/**`, root prose); everything else is
  source. T022's RED and Acceptance add the new refusing cases and one pinned records case per records place;
  B5F-087's case list matches. Within the maintainer's "203 T022: 1" and within 4.5 SP (the crew's judgment: one
  ordered rule and a list; the cases are one-line path assertions).
- **Left open, stated in B5F-087**: non-Markdown configuration under `.specrew/` and `.squad/`
  (`.specrew/verification-plan.json`, `.specrew/config.yml`, `.specrew/iteration-config.yml`) stays records as
  machinery; the reviewer session agreed it is a different class wanting its own design, a candidate, not scope.
- **Accepted with two additions** (the reviewer session): test `:112` is amended for the source repository and
  keeps a named downstream case; a pinned case shows the scaffold's `quality/mechanical-findings.json` in the
  iteration folder is records-only today, unchanged.
- **Class closure**: NONE — a task amendment before the tasks stop.

### DRIFT-016 — reviewer-hook-suppression case 1 red again; one product defect behind two flaky suites; T017 first (maintainer)

- **The second failure**: Specrew CI `43870780425` on `8ca144ab` (records only), attempt 1: the Deterministic gate
  failed on the same case and message as DRIFT-014 ("Expected regular expression 'RD=\[1\]' to match <empty>", 932
  ms), the Contract lane skipped; the crew stopped and reported, as the reviewer session had ruled. Two red in six
  Specrew CI runs on this branch that day, both on records-only pushes.
- **The reading** (read only, about 15 minutes): `Invoke-ContinuousCoReviewAgentInWorktree`
  (`worktree-reviewer.ps1`) starts `ReadToEndAsync()` on stdout and stderr (`:1551`), waits for exit
  (`:1560-1571`), then takes stdout only if the read task has already completed, without waiting for it (`:1598`,
  `:1599`): an exit-0 child whose output is still being read returns an empty string. The timeout path waits
  (`:1590`); the normal path does not. `empty-result-retry.Tests.ps1:29` fails the same way (its retry's stub
  writes and exits 0, and the retry's stdout comes back empty), so the two are likely one defect. On the campaign
  path (codex file-primary), stdout carries no authority, so a lost output cannot be recorded as a pass there; on the
  legacy path it costs a retry and then a failed round, never a pass.
- **What the logs show**: both failing runs on runner image ubuntu-24.04 20261111.127.1; the four greens since the
  morning on 20261111.370.1, and one earlier green (`2cacad73`) on .127.1. A correlation, not proof.
- **The decision**: the maintainer asked "What should we do, and how and when we will solve this issue?"; the crew
  recommended the rerun rule now and T017 first; the maintainer typed "203 rerun: add reviewer-hook-suppression; T017
  first" at 15:48 local. Recorded in `.squad\decisions.md` as
  `f203-i002-rerun-reviewer-hook-suppression-t017-first`. One rerun of `43870780425`'s failed jobs started under it.
- **Class closure**: NONE — T017 fixes it, first in the batch.
- **The rerun**: `43870780425` attempt 2 on `8ca144ab`, under the new rule: green with every job run (Lint, the
  firewall, the Deterministic gate, the Contract lane).

### DRIFT-017 — Main merged in before the before-implement packet, under the records rule (the reviewer session's ruling)

- **Why**: the custom rule `feature-203.rule.main-sync-before-implement-packet` (main is merged in before each
  iteration's before-implement packet if it has moved, never after the approval). Main had moved by 13 proposal
  merges since the merge base `df1141a8`. This is not T030 (the maintainer's merge of main once 206 is on main),
  which stays as planned.
- **The merge** (`459857b4`, a merge, not a rebase): no conflict; nine files, all under `proposals/`: 041, 053, 100,
  211, 217, 218, 219, 220 and `INDEX.md`. 203 had changed nothing under `proposals/`. The code tree is unchanged since
  `da78b600`'s full sweep.
- **The ruling**: the records rule, no full sweep, plus the checks that read `proposals/`. On the merged tree: the
  self-leak lint clean (215 shipped files, 12 deny-list entries); of the four suites that name `proposals/`, only
  `tests/unit/validate-governance.post-ship-proposal-amendment.tests.ps1` reads the real folder (`proposals/INDEX.md`),
  and it passes; `self-leak-lint.tests.ps1` and `non-specrew-session-bypass.tests.ps1` use fixtures, and
  `host-coupling-firewall.tests.ps1` skips `proposals/` wholesale, so they were not run here and CI is their evidence.
- **Class closure**: NONE — a record of how this merge was checked.

### DRIFT-018 — After the before-implement verdict the governance check failed on state.md; the task writer healed it at T017's start

- **The verdict**: the maintainer's typed `approved for before-implement`, captured at 17:31:23Z (19:31 local),
  `auth_commit_hash` `fa569443`, `hook-captured-from-transcript`. The review budget was snapshotted as
  `grant-d99cc3fd635ba27fcc3f` (budget 4, ceiling 4, codex, copilot, claude, infra cap 2). The capture moved
  `plan.md` to `executing`; the bookkeeping was committed after the verdict as `449b0b12`.
- **The failure, caught before any push**: the gated pre-push governance check failed: "state.md is missing canonical
  field 'Current Phase'" and "'Iteration Status'". The scaffolded `state.md` never had them, and the crossing's mirror
  writer did not add them (B5F-088).
- **Healed by the governed step**: T017 marked in progress, and T029 (done with the plan) marked done, through the task
  writer (`Set-TaskStatus`), which writes `Current Phase: before-implement` and `Iteration Status: executing`;
  `tasks-progress.yml` created. Not edited by hand.
- **Class closure**: NONE — B5F-088, candidate for 206's list.

### DRIFT-019 — One full sweep per phase, at the phase tip (the reviewer session's ruling); T017's drain and containment facts

- **The ruling** (specrewreviewer-98, routine; it changes no rule and no scope): every code push still sits on a green
  full sweep of exactly what it pushes (iteration 001 DRIFT-074, widened by DRIFT-090), but a sweep runs once per
  phase, at the phase tip, then one push: Phase 8 (T017, T015, T016, T018, T019), Phase 9 (T020, T021), Phase 10 (T022,
  T023 (i)), Phase 11 (T025, its own sweep). T026 rides with the records push after it. Inside a phase: each task's
  RED and fix commits, its own tests green locally, and the phase's earlier suites rerun after each new fix. At the
  tip: the 50-run batches, the full sweep with the home hook set hashed before and after, the gated push, CI with
  every job run; the reviewer session is asked before the batches and before the sweep. A red sweep stops, is
  bisected by commit and reported before fixing; no partial-phase push. Unpushed commits are kept in a bundle file
  under the crew's scratchpad after each fix commit.
- **What it costs**: the first CI evidence for T017, and the end of its rerun rule on 203's pushes, come some hours
  later; one sweep covers five fixes, so a red result is bisected by commit; a defect found at the tip means more
  rebuilding.
- **T017's drain bound, stated**: when the 10 s bound (per stream) expires, stdout is returned empty (the text read
  so far is lost: `ReadToEndAsync` yields nothing before EOF) and stderr carries `[co-review] output-drain-incomplete:
  ... still open 10 s after the reviewer exited`. The caller then takes the empty-exit0 branch: the file-primary
  check, one retry, and if still empty a failed invocation (`no-parseable-findings-json`) whose stderr tail carries
  the marker. A host whose helper holds the pipe costs at most 20 s and a named failure: not a hang, not a silent
  empty result. The campaign path does not read stdout.
- **Containment and the drain**: `Close-SpecrewProcessContainment` (`scripts/internal/agent-tasks/process-tree.ps1:307`)
  runs in the invoker's `finally`, after the result is built (Job Object close on Windows, a KILL to the process
  group on Unix). A grandchild outlives the child until then by design ("Straggler reap ... must not outlive the
  run"); the drain waits inside that window, and whatever still runs is killed at the reap.
- **Class closure**: NONE — a scheduling ruling and a record.

### DRIFT-020 — Phase 8 records: T016's I4b cause shown, I3a unconfirmed, a residual filed; T015's limit margin

- **T016, I4b: shown to be the cause by its own RED.** HookRenderDedupe I4b on Linux CI (205's run `43739142768`,
  2026-11-15): "expected '16', got '15'" with I4a passing, so sixteen appends reported success and one row was lost.
  The stale-claim reclaim in `HookJournalAccessor.ps1` read a vanished claim's age through the 1601 sentinel (RED
  `4a2dcd21`: 13,439,325,127 s), judged it stale, and could rename a third writer's live claim away (POSIX allows it).
  Fixed in `8823b864` (a vanished or sentinel time is no claim).
- **T016, I3a: unconfirmed.** 205's run `43670851775`, attempt 1, job `132681450478`, 2026-11-15 03:22:57Z: "I3a: two
  concurrent missing-id fires BOTH render ... (expected '2', got '1')". Not the same cause: the render claim is keyed
  by each fire's own per-launch token and has no stale-reclaim path, and the log shows nothing of the fire that did
  not render. So the HookRenderDedupe rerun rule for I3a does not end with T016. The suite now prints each fire's
  output when I3a's count is wrong (`HookRenderDedupe.Tests.ps1`), so the next sighting is diagnosable.
- **T016's residual**: two reclaimers on a truly stale claim can still both reclaim; filed as B5F-089 with the
  sequence, a candidate for the follow-up feature or 206's list.
- **T015's 300 s per-suite limit, against CI today** (Cross-Platform `43883686490` on `7a7b83df`, from the step's
  log timestamps): the longest suite is `review-public-campaign-command.Tests.ps1`, 83.5 s on macOS, 72.2 s on
  Windows, 26.2 s on Linux; the next is `review-cross-platform-fault-matrix.Tests.ps1`, 28.7 s on macOS. With each
  suite now in its own pwsh (a few seconds' start-up), the margin under 300 s is about 3.5 times the longest.
- **Class closure**: NONE — records of Phase 8 work in progress.

### DRIFT-021 — Phase 8 built locally: the 50-run batches, T018's mutation check, T019, and I3a's second sighting

- **The 50-run batches** (on the reviewer session's go-ahead after 206's round 2 ended; 19:57 to 20:26 local,
  sequential, one suite at a time), each 50 runs in a row on the Phase 8 tip: `reviewer-hook-suppression` 50/50
  (265 s), `empty-result-retry` 50/50 (158 s), `co-review-service` (site 13) 50/50 (194 s),
  `agent-invoker-output-drain` (T017) 50/50 (183 s), `bootstrap-journal-claim-age` (T016) 50/50 (3 s),
  `HookRenderDedupe` (I3a, I4b and the rest) 50/50 (888 s). Local evidence only; the CI evidence is the first green
  pushes after the fixes.
- **T018**: the double top-up case passes today (the control existed; its test did not). A mutant that gives each
  top-up its own window turned it red ("Expected 2 ... but got 4") while the single-reset case stayed green; the mutant
  was reverted and the file confirmed unchanged.
- **T019**: the tracked link `.antigravitycli/f95594b5-...json` (to `C:/Users/alon.HOME/.gemini/config/projects/...`)
  removed; `.antigravitycli/` ignored. No existing check refuses a tracked link that points outside the repository;
  none added.
- **I3a, the second sighting**: 205's closeout commit `cec8ee06`, Specrew CI `43919881259` attempt 1, job
  `133486978295`, image ubuntu-24.04 20261111.370.1: "I3a ... (expected '2', got '1')", the same as the first
  (`43670851775`, image 20261111.127.1). Two images, so not image-specific. Neither log shows a cause: the suite throws
  at I3a, so I3b to I3d (journal rows, distinct tokens) never ran. Not I4b's reclaim: the render claim
  (`Request-SpecrewHookRenderClaim`, `LauncherIntegration.ps1:86`) is keyed by each fire's own per-launch GUID and has
  no stale-reclaim path. Candidates by reading: one fire's `PROVIDER_FAILED` (the provider's catch exits 0 with no
  render, and I3 never counts failures, unlike I1a) or a lost job output. Still unconfirmed; the suite now prints both
  fires' output on the next failure, and the I3a rerun rule continues.
- **B5F-090** filed: the campaign reviewer's absolute deadline with no clock on hosts without a shell (206's round 2).
- **Class closure**: NONE — Phase 8's tip goes to the sweep next.

### DRIFT-022 — The Phase 8 sweep of `aa06b3e5b` was red; four of its causes fixed (maintainer's "Fix them")

- **The sweep** (20:31 to 22:40 local, 283 suites, wall 7,751 s, 6 at a time, 1,500 s suite limit): 6 suites failed
  and lane `f203-i001-verdict-review` failed; 2 known red (B5F-036). Home hook files: 0 changed (the sweep's check and
  the crew's 12-file hash). Nothing pushed. Each failure was checked on the pushed tip `5f82692e7` in a scratch worktree
  (removed by its path):
  1. `tests/continuous-co-review/invoke-bounded-suites.ps1`, exit 1 in 1 s: Phase 8's own. T015 made
     `cross-platform-validation.yml` call the runner with `-Suite`; the sweep's CI collector takes every `tests/*.ps1` a
     push workflow names and ran it bare.
  2. The lane's `self-repo-review-integrity.tests.ps1`: red on `5f82692e7` too. It put the sealed iteration 001 into
     reviewing status in a copy, and since 001's closeout seal (`2caa32a17`) the validator stops on
     `closed-iteration-edited` before the W43 check the case exists for. The product is right; the test was stale.
  3. `version-info-states.tests.ps1`: red on `5f82692e7` too ("expected '5f82692e', got '5f82692e7'"). A source
     checkout's build id used git's default short length, now nine characters in this clone; the packager stamps eight.
  4. `start-command-non-interactive-first-run.tests.ps1`: its 300 s limit, as in every sweep since `f6478946`.
  5. `review-posix-runtime.Tests.ps1`, one case: its own 100 ms wall budget under load; 3 of 3 green alone.
  6. `review-budget-loop` and `review-loop-stops` at the 1,500 s cap. Neither reaches T017's or T015's code; their
     times have climbed every sweep. Not yet measured.
- **Decision** (the maintainer, typed in this session, about 22:50 local on 2026-11-16, after the reviewer session's
  questions were answered): "Fix them" — items 1, 2, 3 and 5, the four the crew recommended fixing before the push.
- **The fixes** (each run alone, one suite at a time, while 206's lanes ran):
  - Item 3: `5cec4bf6`, `version-check.ps1` asks for `--short=8`; `version-info-states` green. A packaged install was
    never affected (it reads `build-stamp.json`); a module run from a git checkout, the live-engine pin included,
    printed nine characters.
  - Item 5: `eee6946a`, the case's budget 30,000 ms (the reader and the sleep stay injected); 7 passed, 4 skipped.
  - Item 2: `a0c2e604`, the case checks the feature's newest numbered iteration; both cases pass on 002.
  - Item 1: RED `2d6590f6` (the sweep self-test: every file CI's list names runs with no arguments; red 3 of 58), fix
    `9b491ac5` (the runner moves to `tools/ci/`; the workflow and `bounded-suite-runner.Tests.ps1` follow; 4 of 4 and
    58 of 58 green).
  - Items 2, 3 and 5 have no separate RED commit: each was red on the pushed tip, recorded above.
- **Open, for the maintainer through the reviewer session**: item 4 and the 1,500 s suite limit. Both were ruled for
  iteration 001 only (DRIFT-077 of iteration 001, "203: bothe yes", 20:49 local on 2026-11-14); this sweep carried the
  1,500 s limit over with no iteration 002 record, which the crew disclosed. Item 6 waits for the timing measurement
  (`review-budget-loop` at `5f82692e7` and the new tip, `review-loop-stops` at the new tip), on the reviewer session's
  go; widening T026 to these suites was recommended (+0.25 SP), not decided.
- **Capacity, an overrun on record** (the reviewer session's instruction, routine): the four fixes are about 0.7 SP
  with no task row of their own, taken from the stated buffer (the plan's Effort Model, Rework 2.0 SP, the review
  buffer, option 1), so about 1.3 SP of it is left for the campaign's rework. Where they sit: item 1 (about 0.25) beside
  T015, whose runner it moves; items 2, 3 and 5 (about 0.45 together: 0.25, 0.1, 0.1) beside no Phase 8 row, since they
  were red on the pushed tip before Phase 8, and next to T026 as the sweep-health work of this phase. The task table's
  20/20 is unchanged.
- **Class closure**: item 1 by the sweep self-test's new case; items 2, 3 and 5 by their own suites, now green; items
  4 and 6 NONE yet.

### DRIFT-023 — Both sweep allowances renewed for iteration 002, T026 widened, a new full sweep tonight (maintainer's decision)

- **Decision** (the maintainer, relayed by the reviewer session under the wider delegation, "203 sweep: yes", 23:07
  local on 2026-11-16), answering the answer line the reviewer session defined. As it was shown to them: "My
  recommendation, as one answer: "203 sweep: yes". It means: 1. Fix items 1, 2, 3 and 5 before the phase is pushed: 0.7
  SP, taken from the 2 SP review buffer and recorded as such. 2. Renew both 14 Nov allowances for iteration 002 on the
  same terms. 3. Widen T026 to the three slow suites (+0.25 SP from the buffer) and run it before the next phase, so any
  limit question comes to you with a cause. 4. Run a new full sweep on the fixed tip overnight, then the push if it is
  green." A later shorter form, "203 sweep: renew both, widen T026", was answered with the first, which contains it.
- **The renewed allowances, for iteration 002** (terms from iteration 001's DRIFT-077, as the reviewer session
  described them to the maintainer): "The 1,500 s per-suite limit in full sweeps"; and "the start-command test: when it
  times out under sweep load, it counts as green if it passes alone and in CI, recorded each time". Nothing else red
  counts as green.
- **Capacity**: task rows unchanged at 20.0 SP. Buffer use on record: 0.7 SP for DRIFT-022's four fixes and 0.25 SP
  for T026's widening; about 1.05 SP of the 2.0 left for the campaign's rework.
- **T026**: widened in tasks.md and plan.md to the t008 lane plus `message-identity`, `review-loop-stops` and
  `review-budget-loop`; run after Phase 8's push and before Phase 9, whose start waits for the reviewer session to see
  T026's result.
- **The overnight sequence** (the reviewer session's, routine): the timing measurement ends and is reported; this
  records commit; the full sweep of the new tip at 1,500 s per suite with the home hook set hashed before and after;
  if green (the start-command allowance only on its terms), the gated push of Phase 8 and CI with every job, then the
  rerun rules that end, in the drift log; if red for any other reason, stop, sort by cause, push nothing, report.
- **Class closure**: NONE — a ruling and a scope decision, not a boundary approval.

### DRIFT-024 — The timing measurement, and the Ubuntu runner image that moved under the CI

- **The measurement** (on the reviewer session's go after 206's lanes, 23:05 to 23:28 local on 2026-11-16, one suite at
  a time through `run-suites.ps1 -Throttle 1` with a 2,400 s limit, each commit in a scratch worktree removed by its
  path; the home hook set identical before and after; 0 files written to the redirected home):

  | Suite | Commit | Alone | In the `aa06b3e5b` sweep | Tests |
  | --- | --- | --- | --- | --- |
  | `review-budget-loop` | `5f82692e7` | 356 s | (not swept) | 23 of 23 |
  | `review-budget-loop` | `9779a4b33` | 390 s | over 1,500 s | 24 of 24 |
  | `review-loop-stops` | `9779a4b33` | 382 s | over 1,500 s | 21 of 21 |
  | `start-command-non-interactive-first-run` | `9779a4b33` | 235 s | 301 s (its own 300 s limit) | passed |

  T018's one new case costs about 34 s (the suite averages about 15 s a case), so Phase 8 explains none of tonight's two
  caps: alone, both suites take about 6.5 minutes; in the sweep, 6 suites at a time, about 4 times that. Why the sweep
  times have climbed sweep after sweep is T026's question, as widened.
- **The start-command allowance** (DRIFT-023's terms): the "passes alone" fact for this tip is the 235 s run above; it
  is used only if the next sweep times it out and CI on the push passes it, and is recorded then.
- **The CI fault** (the reviewer session's ruling, routine; T015 owns the file): Cross-Platform Validation's "Ubuntu
  Validation" failed at "Setup PowerShell" on 205's `8ebfef8f` (run `43954284857`, job `133604592995`) and 206's
  `7b54d49d` (run `43956458711`, job `133612182895`, 21:05:31Z): "powershell depends on libicu72 | ... | libicu52",
  every later step skipped. It ran on image `ubuntu-26.04`, version 20261111.196.1: `ubuntu-latest` is moving to
  26.04. The same run's green wrapper-proof job (`133612182422`, same image) shows why it stayed green: dpkg "Selecting
  previously unselected package powershell" (the image ships no pwsh), the 7.4.1 package failed on libicu, and its
  `|| apt-get install -f -y` upgraded it to 7.7.0 from `packages.microsoft.com/ubuntu/26.04/prod`, so that job ran
  PowerShell 7.7.0, not 7.4.1.
- **The fix**: `f2493ccc` (workflow file only). All three Ubuntu "Setup PowerShell" steps use the runner's pwsh when it
  has one and otherwise install `powershell` from Microsoft's package feed, failing with an `::error::` naming the OS.
  Each prints its version. The RED is the two runs above; no local test can reproduce a runner image. No test reads the
  step; the sweep self-test, which reads this workflow, is 58 of 58. Nothing in the repository depends on 7.4.x (every
  script requires 7.0). The Ubuntu jobs will run 7.7.0 on 26.04 runners.
- **Not changed, for the maintainer**: `runs-on: ubuntu-latest` (four jobs in this workflow, and specrew-ci.yml's
  jobs). The label moved under the project's CI without notice. Whether to pin an image is a separate decision. The
  reviewer session will ask whether 205 and 206 take `f2493ccc` by cherry-pick, so the text is the same everywhere.
- **In the reviewer session's words** (routine, on reading the fix): that green job was already running 7.7.0 from
  the feed, so the 7.4.1 pin was fiction on the new image. The Ubuntu jobs now run whatever pwsh the runner or
  Microsoft's feed provides; nothing in the tree depends on 7.4.x (checked with `git grep` over every `.ps1`, `.psd1`,
  `.psm1` and `.sh` for `7.4.<n>`, a `PSVersion` test against 7.4 and `-Version 7.<n>` above 7.0: no match outside the
  removed download lines).
- **Class closure**: NONE — whether to pin the runner image is the maintainer's decision, not taken here; the setup
  step itself no longer depends on one image's library versions.

### DRIFT-025 — Phase 8 pushed; two T015 defects found by CI and fixed; the CI fixes pushed without a green sweep (maintainer's decision)

- **The first push**: the sweep of `0e8ccd890` (23:34 to 01:38 local, 2026-11-16/17) was green but for the
  start-command allowance (301 s in the sweep, 209 s alone at `0e8ccd890`, 01:42); all ten lanes exit 0;
  `review-budget-loop` 1,478 s and `review-loop-stops` 1,461 s under the 1,500 s limit; home hook files 0 changed.
  Pushed `5f82692e7..0e8ccd890` at 01:43. Markdownlint ran on the changed Markdown outside `.squad/` and
  `.specify/`, as CI and `.markdownlintignore` scope it; `.squad/decisions.md` has two MD003 errors that were already
  on origin.
- **CI on `0e8ccd890`**: Test green; Cross-Platform Validation red (run `43981760363`); Specrew CI red (run
  `43981760146`, Deterministic gate; Contract lane skipped). Two separate T015 defects, neither visible to a sweep:
  1. The Cross-Platform step passed its suite array through `pwsh -File ... -Suite $suites`, which does not bind an
     array: "A positional parameter cannot be found that accepts argument
     './tests/continuous-co-review/unit/path-identity-volume-differential.Tests.ps1'" on all three legs (jobs
     `133699729756`, `133699729901`, `133699729799`); no suite ran. The runner's own test only ever passed one suite.
     RED `396825b3b` (the runner tested through the workflow step's own call line and exit check, read from the
     workflow, with two or more suites; red 3 of 8 with CI's error), fix `95f9bb764` (the step calls the runner in
     its own process; 8 of 8).
  2. The runner's child always imported Pester 5.7.1; the Deterministic gate has Pester 5.9.0 only ("The specified
     module 'Pester' with version '5.7.1' was not loaded", job `133701210065`). RED `527dbc439` (red 1 of 9 under
     Pester 5.8.0), fix `72ffa5500` (the child imports the caller's Pester, else 5.7.1; 9 of 9 under 5.8.0 and
     5.7.1).
  Both reported to the reviewer session before fixing; built on its routine ruling ("203: yes. Build the fix now").
- **The sweep of `72ffa5500`** (02:12 to 04:27): red on the stop condition. `review-budget-loop` and
  `review-loop-stops` timed out at 1,500 s and lane `f203-i001-t008-suites` at 900 s; no other failure but the
  start-command allowance; home 0 changed. Nothing of feature 205 or 206 ran on this machine in that window (the reviewer
  session, 04:28). What did run is in DRIFT-026. Nothing was pushed.
- **Decision** (the maintainer, typed directly in this session at about 18:13 local on 2026-11-17): "203: push the CI
  fixes". A one-time exception to the green-sweep rule for `72ffa5500`. The sweep cannot execute the workflow steps
  these two fixes change; only CI can. Gate: clean tree, no changed Markdown, governance `-ChangedOnly` green. Pushed
  `0e8ccd890..72ffa5500` at 18:14.
- **CI on `72ffa5500`, every job green**: Test `44123440977`; Cross-Platform Validation `44123441228` (all eight jobs,
  Ubuntu Validation on `ubuntu-26.04`); Specrew CI `44123440978` (Lint, Self-leak firewall, Deterministic gate
  `134184229332`, Contract lane `134194251903`). The three deterministic jobs ran their suites, each named with its
  count and time. One line per leg:
  - Ubuntu (`134180684839`, `ubuntu-26.04`): "--- deterministic suite:
    ./tests/continuous-co-review/integration/review-cross-platform-fault-matrix.Tests.ps1 | Tests completed in 22.79s
    | Tests Passed: 13, Failed: 0", 15 suites in all.
  - Windows (`134180684547`, `windows-2025-vs2026`): "--- deterministic suite:
    ./tests/continuous-co-review/unit/review-public-campaign-command.Tests.ps1 | Tests completed in 63.14s | Tests
    Passed: 40, Failed: 0", 15 suites.
  - macOS (`134180685099`, `macos-26-arm64`): "--- deterministic suite:
    ./tests/continuous-co-review/unit/review-posix-runtime.Tests.ps1 | Tests completed in 19.9s | Tests Passed: 11,
    Failed: 0", 15 suites.
- **The start-command allowance** (DRIFT-023's terms), used for the sweeps of `0e8ccd890` and `72ffa5500` (301 s
  each): it passed alone at `0e8ccd890` in 209 s, and it passed in CI's Contract lane on `72ffa5500` (job
  `134194251903`, "PASS: Bootstrap completed successfully", 16:36Z). Home hook files 0 changed in every sweep and solo
  run.
- **The rerun rules that end** (the reviewer session's wording): on 203's own pushes, reviewer-hook-suppression and
  empty-result-retry (T017), site 13 (T015) and HookRenderDedupe I4b (T016) end with CI green on this push; I3a
  continues; for 205 and 206 nothing ends until this reaches main.
- **Tasks**: T017, T015, T016, T018 and T019 marked done through the task writer, and T026 with DRIFT-026.
- **Capacity**: the two T015 fixes about 0.5 SP from the stated buffer, an overrun on record beside T015.
- **Class closure**: the array-binding defect is covered by the runner test that reads and runs the workflow's own call
  line, and the Pester-version defect by the caller's-Pester case. The sweep's blindness to workflow steps is NONE —
  it is a property of the sweep that is not fixed here, so a change that only CI can execute still needs CI to show it.

### DRIFT-026 — T026 as widened: the slow suites do not grow alone; in a sweep they wait on something not shown

- **Run alone** (04:30 to 06:19 local, 2026-11-17, one at a time; `a9a13583e` / `da78b600c` / `72ffa5500`):
  `review-budget-loop` 445 / 440 / 496 s; `review-loop-stops` 486 / 485 / 528 s; `message-identity` 585 / 584 / 620
  s. There is no growth from `a9a13583e` (just before round D's whole-transcript fix `99223e7d`) to `da78b600c`, so
  that read, the suspect T026 was opened for, is ruled out. The tip's extra 36 to 56 s is partly T018's case and partly
  outside disk activity during two of its runs. Lane `f203-i001-t008-suites` alone exceeded its 900 s limit at
  `da78b600c` and at `72ffa5500`, although it took 837 to 846 s inside earlier sweeps.
- **The machine, not the code**: `review-budget-loop` at the same suite code took 390 s at 23:05 and 496 to 511 s from
  04:30 on.
- **Six at once** (Throttle 6, 06:20 to 06:44): `review-budget-loop` 1,459 s (2.9 times its alone time),
  `review-loop-stops` 1,454 s (2.75), `message-identity` 1,421 s (2.3). Total CPU averaged 22.8 %, the same as one
  suite alone, and never reached 90 %; the disk was idle.
- **Separate homes** (06:47 to 07:12, six `run-suites` processes, each with its own `SPECREW_USER_HOME_OVERRIDE`):
  within 2 % of the shared-home run, as predicted from reading. These suites keep their repositories under `TestDrive`
  and never read the home. In the same run: processor performance 167 % of base, no parked cores, processor queue 0,
  Defender about 20 % of one core, and pwsh about 1.25 cores for all six suites. So there is no CPU cap and no CPU
  queue: the time is spent waiting.
- **The temp folder** (07:15 to 07:32): `review-budget-loop` alone took 511 s with TEMP and TMP pointed at a new empty
  folder and 506 s with the normal one, so it is not the cause. By reading, `%TEMP%\specrew-cited-turns` (7,538 files,
  2.2 MB) is only written with unique names, and neither the helper nor the product lists it. Separately, the tests
  leave about 20,000 folders in `%TEMP%` (14,235 `f202-form-*`, 6,031 `f202-msgid-*`): a hygiene finding, not shown
  to cost time, left to the maintainer.
- **What else ran during the `72ffa5500` sweep** (Windows logs; the sweep driver logs no process list): a Visual Studio
  background download (02:31 to 02:50), the 03:29 maintenance batch, and a Defender intelligence update at 04:05.
  This shows overlap only, not cost. The Kernel-Power log shows Modern Standby entered at 20:57:53 on 2026-11-16 with
  no exit since.
- **Mine, for the record**: the first six-way attempt passed its suite array through `pwsh -File`, the defect fixed
  in T015 the same night, and ran nothing; the rerun used a list file.
- **Left for the maintainer**: a Windows Performance Recorder trace of a six-way run, or one run with a Defender
  exclusion on the test temp roots, to find the shared wait. Also the t008 lane's 900 s limit, which the review
  campaign's preflight would hit today. Also the two suites' cap; splitting each into two files keeps them under it
  whatever the cause. No throttle, limit or test was changed.
- **Capacity**: about 1.0 SP against the 0.75 planned (0.5 in the row and 0.25 from the buffer), so a further 0.25
  from the buffer. About 0.3 SP of the 2.0 SP buffer is left.
- **Class closure**: NONE — the cause of the shared wait is not shown; the measurement is recorded and the decisions
  are the maintainer's.

### DRIFT-027 — The t008 lane's limit raised to 1,500 s (maintainer's decision)

- **Decision** (the maintainer, relayed by the reviewer session under the wider delegation, "203 t008 lane: 1500",
  18:50 local on 2026-11-17, answering the reviewer session's recommended line): in `.specrew/verification-plan.json`,
  `timeout_seconds` of command `f203-i001-t008-suites` goes from 900 to 1,500. Only that value; no other lane, suite or
  cap in the sweep driver.
- **Why** (DRIFT-026): the lane took 838 s on `da78b600` and over 900 s alone at `da78b600c` and at `72ffa5500`, with no
  code cause found; the limit had no margin, and the review campaign's preflight reads the same field.
- **Where the value is read**: the review preflight resolves it through `Resolve-ContinuousCoReviewVerificationTimeout`
  (`verification-plan-contract.ps1:82`; the engine allows up to 3,600 s), and the sweep's `run-lane.ps1:20` reads the
  same field. Nothing hashes the plan to bind this value: the review campaign records a `verification_plan_sha256` per
  round (`review-authority-core.ps1:567`), and iteration 002's campaign has not started; the tests that read the real
  plan check lane names, not timeouts. No second file changed.
- **Landing**: its own commit, before the Phase 9 sweep, so that sweep runs with it and Phase 9's gated push carries it
  (not a records-only change).
- **Class closure**: NONE — a limit change on the maintainer's word; the lane's time is reported against 1,500 s in the
  Phase 9 sweep.

### DRIFT-028 — The sweep runs at Throttle 3 (maintainer's decision); the split of the two slow suites waits for a measured trigger (the reviewer session's judgment)

- **Throttle** (the maintainer, relayed by the reviewer session under the wider delegation, "203 throttle: 3", 18:49
  local on 2026-11-17, answering the reviewer session's recommended line): the next full sweep (Phase 9's) runs with
  `-Throttle 3` as a launch option. No default changes in `sweep-full.ps1` or `run-suites.ps1`, and no test or cap
  changes. It is measured against DRIFT-026's Throttle 6 figures: the suite phase's total and each slow suite's time.
- **Split** (the maintainer, relayed, 18:58 local: "203: split, if you think that it is beneficial and eventually save
  time, do it now"). The reviewer session's judgment, marked as theirs: not now, with a measured trigger. Today the
  split is not shown to save time: at Throttle 3 the two suites should return near their alone time (about 500 s
  against the 1,500 s cap), and then it buys nothing. It would cost about 1 SP with about 0.3 SP of buffer left, and it
  would add test-file changes to the review campaign's scope.
- **The trigger** (the reviewer session's): in the Phase 9 sweep at Throttle 3, if `review-budget-loop` or
  `review-loop-stops` takes more than 1,000 s, or the suite phase's total is more than 1.5 times the Throttle 6
  total, the crew stops after the sweep and reports the numbers; the reviewer session takes the split to the maintainer
  as a sized task. Otherwise the split is recorded as a deferred item with the measurement beside it.
- **T020** done: round E `finding-cf1fe81e0398f883` in two RED-and-fix pairs (`86c320fb5` red 2 of 28, `a9c791614`;
  `282e655b3` red 1 of 29, `43cc5c5bf`).
- **Class closure**: the T020 halves by their cases in `authorization-consumers`. The throttle and the split are
  NONE — process decisions measured in the Phase 9 sweep.

### DRIFT-029 — A Codex-writer trial (maintainer's decision); T021 done on Claude, the trial moves to T022

- **Decision** (the maintainer, relayed by the reviewer session under the wider delegation, "203: yes, lets do a single
  round of implementation and see if it works", 19:11 local on 2026-11-17, answering the reviewer session's line "203:
  Codex writer trial on T021"): one task's implementation written by Codex under the crew's supervision, to learn
  whether the pattern saves Claude budget. The crew writes the failing test; Codex makes it green in a plain local clone
  outside every governed folder; only a patch limited to the task's files comes back; the crew runs the suites, reads
  the whole diff and commits, and the commit names Codex and its model as the writer.
- **The task changed from T021 to T022** (the reviewer session's ruling, routine, marked as theirs): the trial message
  reached the crew after T021's fix was written and green (RED `3151dc407`; fix `8eb755d07`, written by Claude). T021
  was the reviewer session's choice of task, not the maintainer's, and a six-line fix already written cannot show
  whether the pattern saves budget; T022 is a real code task and a fair test. T022 starts only after Phase 9 is pushed.
- **Measurement windows** (local, first tool call to the green commit, on Claude): T020 about 18:44 to 19:03 (green
  `43cc5c5bf`); T021 about 19:05 to 19:16 (fix written; committed `8eb755d07` at 19:18 after the ruling). T022's
  window will be noted the same way. The reviewer session computes the Claude tokens per window from the transcripts.
- **T021 done**: round E `finding-a537d3f72672e5f5`, the stop-answer fallback on the recovery path, reported at the
  next message, with nothing recorded (`typed-act-writer` case 9b, 52 of 52).
- **Class closure**: T021 by case 9b's stop-answer case. The trial is NONE — a process decision, measured on T022.
- **The trial round on T022** (records-rule half; accepted by the reviewer session as reported): RED `ddafb0009`
  (22:55 local; `records-only-source-repo-narrowed` red 16 of 31, the FR-009 case `:112` amended, red 1 of 11); Codex
  (CLI 0.166.0, `gpt-6.1-sol`, reasoning high) ran 22:58:58 to 23:02:25, exit 0, first try, no fallback and no
  follow-up brief; its patch changed only the two named functions and one private helper beside them (+49/−2); the
  crew's runs: 31 of 31, 11 of 11, the nine other suites that load the gate, and `path-identity` 18 green; committed
  `adedce10e` at 23:09:32 naming Codex and its model. Codex's tokens: 912,232 input (862,720 cached), 5,101 output.
- **The method, as run**: a plain clone at the RED commit in a temp folder the crew created, deleted afterwards by
  its exact path. Removed from the clone before the run: `.agents` (the reviewer session's rule), and the tracked
  `.specrew` (so that no `.specrew` afterwards proves no hook wrote there), `.codex` (Codex agent definitions) and
  `AGENTS.md` (Codex loads it as instructions) — the reviewer session ruled these right and part of the method. TEMP
  and TMP inside the clone; `SPECREW_REFOCUS_DISABLE=1` and `SPECREW_DISABLE_EVENTS` set; the brief limited Codex to
  two functions and forbade commits, specrew commands and the governed folders. Proof: no `.specrew`, `.codex` or
  `.agents` in the clone after the run; no hook journal entry with the clone's path; the 12 home hook files identical;
  the `--json` log shows 14 commands, all in the clone, only the two named test files run, and a read-only probe for
  `AGENTS.md` up the folder chain to the home folder.
- **Codex wrote to the user's Codex config**: despite `--ignore-user-config`, `~/.codex/config.toml` gained
  `[projects.'c:\users\alon\appdata\local\temp\t022-codex-cbf94547'] trust_level = "trusted"` at the run's start
  (lower-cased, while the `-c` override was mixed case). The `-c` trust override, or Codex itself, persisted an entry
  for a temp path, so each such run would add one. Left in place; removing it is the maintainer's (the reviewer session
  is telling them).
- **The measurement** (the reviewer session's, from the crew's transcript by time window): T020 21 replies and 18,164
  output tokens; T021 17 replies and 12,006; the trial round 52 replies and 49,442, of which the RED 23 replies and
  25,377, and the setup, Codex run, verification, commit and report 29 replies and 24,065. The supervision alone cost
  more than either task the crew wrote whole.
- **Conclusion** (the reviewer session's, for the maintainer): the pattern is safe and the patch was good, but it does
  not save Claude budget at this task size, because test-first puts the work in the tests. Unless the maintainer says
  otherwise, no further Codex-writer rounds in this iteration. T022's gate half is the crew's, with 206's stop-on-
  findings sequence as its RED, and takes the two minor points of the patch: the helper's header comment, and the
  extension check on a case-sensitive volume, with a test.

### DRIFT-030 — Phase 9 swept green at Throttle 3; the split of the two slow suites is deferred with its measurement

- **The sweep of `5d1f3c1d1`** (Throttle 3, `-SuiteTimeoutSeconds 1500`, 20:14 to 22:39 local, 2026-11-17): 282 suites,
  1 failed, 2 known red (B5F-036), 0 spanned standby, 0 CI suites missing; all ten lanes exit 0; home hook files 0
  changed before and during the sweep, 0 files written to the redirected home. The one failure is the start-command
  allowance (below).
- **The slow suites** (Throttle 3 against DRIFT-026's Throttle 6 figures, cap 1,500 s): `review-budget-loop` 1,000 s
  (1,459 s), `review-loop-stops` 940 s (1,454 s), `message-identity` 752 s (1,421 s). Lane `f203-i001-t008-suites` took
  932 s against its 1,500 s limit (DRIFT-027).
- **Overlap with feature 206** (the crew's process sampler, every 30 s; it cannot tell 206's suites from the sweep's by
  name): 206's final check ran 20:33:23 to 21:02:30. `review-budget-loop` ran about 20:50:31 to 21:06:57 and
  `review-loop-stops` about 20:53:37 to 21:09:00, almost wholly inside that window; neither failed nor reached its cap.
  `message-identity` and the start-command suite were not seen before the sampler stopped at 21:14, so they ran after
  it.
- **The suite phase** (sweep wall minus lanes): 8,685 − 3,034 = 5,651 s, against 4,814 s at `72ffa5500` and 4,619 s at
  `0e8ccd890`, both Throttle 6: 1.17 and 1.22 times.
- **The split trigger** (DRIFT-028) is not tripped: the reviewer session's call, under the maintainer's words of 18:58.
  `review-budget-loop` is at 1,000 s, not more than 1,000 s, and ran almost wholly inside 206's window;
  `review-loop-stops` is under; the suite phase is under 1.5 times. Throttle 3 stays the setting for this crew's sweeps:
  every slow suite has 500 s or more of margin under the cap, at about a fifth more suite-phase time.
- **Deferred item**: splitting `review-budget-loop.Tests.ps1` and `review-loop-stops.Tests.ps1` into two files each,
  about 1 SP, with the measurement above beside it (1,000 s and 940 s at Throttle 3; 1,459 s and 1,454 s at Throttle
  6; about 445 to 528 s alone, DRIFT-026). It is taken to the maintainer as a sized task if a later sweep trips the
  trigger.
- **The start-command allowance** (DRIFT-023's terms), used for this sweep (301 s, its own 300 s limit): it passed
  alone at `5d1f3c1d1` in 219 s (22:41:39 to 22:45:18, scratch worktree under the crew's temp root, removed by its
  path; home hook files identical before and after; 0 files written to the redirected home). The CI half: the
  Contract lane on `dfe675eea` ran it, "PASS: Bootstrap completed successfully" (job `134368805377`, 21:10:08Z).
- **CI on `dfe675eea`, every job green** (concluded 23:12 local): Specrew CI `44172885150` (Lint, Self-leak firewall,
  Deterministic gate `134359629939`, Contract lane `134368805377`); Test `44172885148`; Cross-Platform Validation
  `44172885295` (all eight jobs).
- **Next** (the reviewer session's routine rulings): the gated push of Phase 9 and CI on every job; T022's trial starts
  after the push, with CI followed in parallel and the trial stopped where it is if any job goes red.
- **Class closure**: NONE — a measurement and process decisions; the split stays a deferred item, not a fix.

### DRIFT-031 — T022's gate half: the human's stop counts for the findings it accepted and survives the review record; the packet's coverage statement deferred (DRIFT-032)

- **The sequence** (feature 206 on main's engine, 2026-11-17, relayed by the reviewer session; read on this engine): a
  round with an open major finding, the stop's `accept-current` disposition for the reviewed digest, then the review
  record the sign-off sync demands. On this engine (and the pin `da78b600`, `review-signoff-evidence-gate.ps1:1211`) the
  sign-off already blocked at the reviewed digest, `review-findings-open`: the acceptance never counted for the open
  findings. After the records commit it refused `records-only-delta-over-non-authorizing-result`: the records-only
  branch never read the acceptance (DRIFT-078). Either way the human typed a second line (DRIFT-091). The crew's earlier
  answer to the reviewer session (only the records commit costs a line) was corrected the same evening.
- **RED** `37e4c0f33` (`tests/unit/review-end-one-approval.Tests.ps1`, a real repository and authority store, entered at
  `Get-ContinuousCoReviewSignoffGateDecision`): red 3 of 8.
- **Fix 1** `1cbdb12d5`: when the latest result has a valid `accept-current` disposition for the digest it reviewed
  (`require-correction` still wins), the findings still open do not hold the sign-off. They stay listed as not covered,
  rendered "Not covered (open, accepted at your stop)" (an `accepted` flag on the item; the kind stays `not-covered`,
  so the retro scaffolder in the `.specify` mirror is unchanged). A later round makes a newer latest result, so an
  earlier stop never covers a finding a later round reports. 7 of 8.
- **Fix 2** `4f8e4691b`: in the records-only branch the same acceptance authorizes the result, as it does on the
  reviewed digest. A code commit after the stop still stales. 8 of 8.
- **Pinned** (passing): no stop, `require-correction`, a code commit after the stop, and a records commit with no stop
  all block. B5F-071's first half (`70530c56d`): the next round's explicit `resolved` on moved files closes a fixed
  finding and the sign-off releases without listing it; `still-open` keeps it open. Passing since T008 (`845e212dc`,
  "an open finding closes only on the reviewer's explicit resolved on moved files"); 203 iteration 001's rounds were
  launched from a pin older than that. So every case in T022's acceptance list has a named test.
- **The Codex patch's two minor points** (the reviewer session's ruling): RED `c2781c8ad` (red 1 of 32), fix
  `9191a8403`: the extension check ignores case on every volume (an upper-case `.MD` no longer falls back to records on
  a case-sensitive volume), and the helper has its header comment.
- **Not built: the sign-off packet's coverage statement**, deferred by the maintainer (DRIFT-032). T022 is done
  without it.
- **Batch** (local check, not the push gate; the reviewer session's go-ahead): 23 suites at Throttle 3 (the 14 that call the sign-off gate, packet or listing, and the 11 that load the classifier, two shared), 23:32 to 23:57 local, 0 failed, 0 spanned standby, home hook files identical before and after; the longest `review-public-campaign-command` 704 s and `review-loop-stops` 621 s.
- **Class closure**: the stop's authority by `review-end-one-approval`'s cases; the coverage statement is DRIFT-032's.

### DRIFT-032 — T022's sign-off packet coverage statement is deferred to the follow-up feature (maintainer's decision)

- **Decision** (the maintainer, relayed by the reviewer session under the wider delegation, "203 T022 packet statement:
  defer", 23:43 local on 2026-11-17, answering the reviewer session's recommended line): the statement in T022's Work
  text - fixed findings and their failing-first tests, open findings and where they go, records and code changed since
  the last round, apart - is not built in iteration 002. It moves to the follow-up feature, to sit with the coverage
  line (B5F-075, the work that was T024) as one design. T022 closes without it.
- **Why** (the reviewer session's two reasons, given to the maintainer): the engine keeps no link from a finding to the
  test that fixed it, so "fixed behind which failing-first test" has no data to come from; and the statement overlaps
  the coverage line already in the follow-up, so building both now would build one thing twice.
- **What changes**: T022's Work text in tasks.md and the plan (its row and the FR-011 line) name the statement as
  deferred with this entry's id; B5F-075 names the deferred statement beside the coverage line, so the follow-up's
  triage sees one item (the reviewer session will put it in the first group there). No other wording changes.
- **Class closure**: NONE — a scope decision; the work is recorded where the follow-up's triage reads it.

### DRIFT-033 — T023 (i): a folder waiting for its plan verdict is not missing its plan (B5F-083); notes for T030's merge

- **RED** `1b682f1b2` (`tests/unit/plan-crossing-pending.tests.ps1`, the validator on temp fixtures): red 4 of 10. The
  governance check refused an iteration folder with no `plan.md` while its plan crossing was the next one pending.
- **Fix** `df3ff11cd`: `Get-SpecrewPlanCrossingState` (`validate-governance.ps1`, beside `Test-IterationGovernance`)
  reads the last authorized boundary through the same enforcement-state reader as feature 206's T034 and asks
  `Get-SpecrewPendingBoundaryCrossing` whether the pending crossing is the plan crossing itself (after `clarify`, or after
  `iteration-closeout` for a new iteration). Written to 206's round-2 rule from the start (the reviewer session's terms):
  only the crossing that comes next is pending, and the iteration is compared even when the session names none (then
  only the feature's newest folder can be pending). A missing start context accepts with a warning naming the file, so in
  CI the refusing half does not hold (206's item 53). Pinned refusals: `plan` or a later boundary authorized, `specify`
  with `clarify` still to come, another iteration, an older folder with no session iteration, another feature. The
  `.specify` mirror and its hash record were refreshed in the same commit (`specify-mirror-record` 6 of 6). 10 of 10.
- **T023 stays in progress**: (ii), the sync and the check together over the sign-off and retro sequences, waits on
  main merged in (T030).
- **Notes for T030's merge** (owed to the reviewer session): 206's T034 brings `Get-SpecrewRecordApprovalState` into the
  same file; the two functions sit apart (206's after `Add-ValidatorStopMessage`, this one before
  `Test-IterationGovernance`) and keep separate names, so the merge is expected to take both. 206's round-2 finding
  `finding-e2ef0515b3bc7a8f` (minor; that function returned 'pending' under any earlier boundary and skipped the
  iteration when the number was blank) is on T030's expected-conflict list; it was fixed on 206 in `d1e428b98`, and this
  function follows the fixed rule.
- **Class closure**: the plan crossing by `plan-crossing-pending`'s cases; CI's blind spot is NONE here — it is 206's
  item 53, recorded there.

### DRIFT-034 — The Visual Studio Installer replaced Git twice under the Phase 10 sweep; both sweep starts stopped, nothing retried

- **What replaced Git**: an overnight Visual Studio Installer update (the orchestrator `setup.exe update`, PID 79988,
  started 00:27:07 local on 2026-11-18; logs `%TEMP%\dd_setup_20261118002722*.log` and
  `%TEMP%\dd_setup_20261118010827*.log`). Each Visual Studio installation carries its own `GitV2` package, and each
  session's plan uninstalls the version it recorded and installs the new one, by running Git for Windows' own
  uninstaller over whatever is installed.
- **Window 1** (the Enterprise 2026 session): planned at 00:27:48 "GitV2,version=2.55.0.5 ... Uninstall" and
  "GitV2,version=2.56.0.4 ... Install"; ran `C:\Program Files\Git\unins000.exe /VERYSILENT` at 00:38:38, after which
  `C:\Program Files\Git\mingw64\bin` was empty and every git command failed "error launching git: The system cannot
  find the path specified"; 2.56.0.4 was installed at 01:03 to 01:04 (`git version 2.56.0.windows.4`). The session
  finished at 01:06:54. Git 2.56 keeps its binaries under `ucrt64`, not `mingw64`.
- **Window 2** (the Enterprise 2022 session, 17.14.45, started 01:08:26): planned "GitV2,version=2.51.1.2 ...
  Uninstall" and "2.56.0.4 ... Install"; its uninstall at 01:12:28 removed the 2.56 just installed; Git worked again at
  about 01:21 and the session finished at 01:21:49. Build Tools 2019 and Enterprise 2026 Preview were not updated.
  Version strings: 2.55.0.5 out at 00:38:38; 2.56.0.4 in at 01:04; out at 01:12:28 (that session recorded 2.51.1.2); in
  at about 01:21. The reviewer session is asking the maintainer to start no further updates during sweeps.
- **The Phase 10 sweep of `3ced8938b`** (Throttle 3): the first start (about 00:07) was stopped at 00:44 by the
  reviewer session's ruling, as invalid from 00:38:36; the second (about 01:05) was stopped at 01:13 when git failed
  again. Neither wrote per-suite results (the listing is written when the suite phase ends), so the suites that failed
  for this reason are not known by name; the only named failure is the crew's own single run of
  `tests/bootstrap/RollingHandover.Tests.ps1` at 00:40 and 00:41 ("error launching git"), which passed at 00:29 and
  again alone at 01:05 on 2.56. Nothing was retried; both sweep checkouts were removed by their exact paths once Git was
  back, at 01:05 and 01:34. The crew's git commands all completed before each break (the T025 commit `7f601b9e9` at
  01:09:05); no lock file was left.
- **On Git 2.56**, alone, before the restart: `RollingHandover`, `HookPacketCapture`, `hook-run-git-snapshot` 5,
  `dispatcher-stop-block`, `ProviderMirrorParity`, `conformance-material-turn-gate` 3, `flush-race-forensic` 2,
  `hook-transcript-tail` 6, `hook-git-snapshot-reader` 6, all green (01:05 to 01:07), and again before the third start.
- **"Back" means no installer activity** (the reviewer session's rule, corrected): no child setup or msiexec and no new
  installer log, plus a working `git --version`. The orchestrator's window can stay open idle, so "no setup.exe" is the
  wrong test; the crew's own watcher used a path pattern that missed that process, and the crew went by the reviewer
  session's word. During the third sweep the crew samples `git --version` every few minutes and stops the sweep at once
  if it fails.
- **Class closure**: NONE — a machine event outside the project; the guard is the sampler during sweeps.

### DRIFT-035 — New suites were added with no lane, and the pre-push batch did not run the class-guard lanes; found by the Phase 10 sweep before any push

- **What happened**: T022 and T023 added three suites (`records-only-source-repo-narrowed`,
  `review-end-one-approval`, `plan-crossing-pending`), and no lane in `.specrew/verification-plan.json` named them.
  The crew's pre-push batch ran the new suites and their neighbours, but not the class-guard lanes. The Phase 10 sweep
  of `3ced8938b` (282 suites, 0 failed, 2 known red B5F-036; ended 02:45 local on 2026-11-18) failed lane
  `f199-class-guards-a` on `tests/unit/every-suite-is-named-by-a-lane.tests.ps1`, the check that every test file on
  disk is named by a lane. Nothing was pushed. The same check on the local T025 line found T025's three suites
  (`hook-run-git-snapshot`, `hook-git-snapshot-reader`, `hook-transcript-tail`) unnamed too.
- **The fix** (the reviewer session's routine ruling, Option 1): the branch was rebuilt on `3ced8938b`. Phase 10
  gained one commit, `c108f00e5`, which adds the three T022/T023 suites to lane `f203-i001-suites` (only that command's
  suite list and label changed). T025's four commits and DRIFT-034 were replayed on top with no conflicts, and
  `597c653c1` adds T025's three suites to the same lane. That keeps T025 local, out of the Phase 10 push. Before the
  rebuild, the old tip was kept as the local branch `203-backup-before-rebuild` and a bundle of the unpushed commits.
  The rebuilt tip differs from the old tip only in `.specrew/verification-plan.json`. The only test that reads this
  repository's own plan is the class guard; other tests build their own copies, and none pins the plan's hash.
- **Checks on `c108f00e5`**: fail-fast in a temp worktree with a redirected home: `f199-class-guards-a` exit 0 in
  116 s, `f203-i001-suites` exit 0 in 464 s (under the reviewer session's 700 s mark). Then the full sweep (03:02 to
  04:05 local, 3 at a time, 1,500 s per suite): 282 suites, 0 failed, 2 known red (B5F-036), all 10 lanes exit 0
  (`f203-i001-suites` 393 s). Home hook files: 0 changed before or during, 0 written to the redirected home. The
  crew's 12-file hash was identical before and after. `git --version` was sampled every 2 minutes, 32 samples, all ok.
  markdownlint and `validate-governance -ChangedOnly` were green on `c108f00e5`, and it was pushed at 04:05:53
  (`dfe675eea..c108f00e5`).
- **Standing practice from now** (the reviewer session's ruling): any commit that adds a test file runs the
  class-guard lanes (`f199-class-guards-a` and `-b`) in its own batch, before the push.
- **Where this entry lands** (the reviewer session's routine ruling): on T025's local line; there is no records-only
  push on `c108f00e5`, so the Phase 10 push stays exactly the swept revision.
- **Class closure**: the guard already existed and caught it; the gap was in the crew's batch, now closed by the
  standing practice above.

### DRIFT-036 — 206's 13 hand-over items checked against 203; five handed back; the records tidied

- **The check** (the reviewer session's request, 2026-11-18, for 206's closeout seed): each of the 13 items feature 206
  handed to 203 (206's bug-list items 3, 7, 8, 9, 13, 14, 27, 42, 58 to 62) was read against 203's records and code on
  `597c653c1`. Result: 8 fixed on the 203 branch, none planned in iteration 002, 5 handed back (9, 14, 27, 42, 62).
- **The hand-back note** (the reviewer session's routine ruling): `specs/203-beta5-stabilization/handback-to-next-bug-bash.md`,
  readable alone. It lists the five items handed back with their reasons and 203 findings, and the fixed but thinly
  guarded items as test candidates: 59 and 60 have no named test, 58 is guarded only by the partial case and not by
  206's sequence, 3's cause is "likely", and 7's hang is unexplained. 206's seed stays as written.
- **The records behind 58 to 61**, which name no 206 item. 58, 59 and 60 were fixed by T008's redesign in iteration
  001 (DRIFT-052: "Partial findings", RED `047cd6a0e` and fix `8b98e2ef7`; item 3, what spends a round; one launch per
  invocation and no automatic retry). That drift log is sealed, so the link to 206's items is this entry:
  - **206 item 58** (partial findings dropped, "found nothing") is closed by DRIFT-052 "Partial findings".
  - **206 item 59** (the retry message says "NOT spent" while the spend record says spent) is closed by DRIFT-052
    item 3 and FR-010.
  - **206 item 60** (the automatic retry blocked by the first attempt's pause) is closed by the one-launch design
    (`scripts/specrew-review.ps1:1375-1377`).
  - **206 item 61** (campaign findings demoted for a missing "Failure scenario:" clause) is B5F-017's cause, fixed by
    `d3ab3f21c`. B5F-017 now names it.

  All four fixes predate 206's sightings, which ran main's engine.
- **Headings matched to their bodies** in `docs/beta5-findings.md`:
  - B5F-039 now reads fixed (`77bd4a2e`, `b69cc5ca`) and names 206's item 8.
  - B5F-042 now reads fixed (DRIFT-056, and DRIFT-057's case-folding defect). It stays open only for the maintainer's
    iteration 002 wording item: the changed-real-home refusal should say the change may have come from another
    session. No iteration 002 task carries that item, and the runner does not say it yet.
- **Not done: T015 and T017 checked in tasks.md through the task writer.** `Set-TaskStatus ... -Status done` does not
  change `tasks.md`. On tasks already done, it re-stamped `completed_at` with the time of the call (2026-11-17 16:39 UTC
  became 2026-11-18 02:14 UTC) and moved state.md's "Last Completed Task". The crew restored both files from HEAD
  before any commit. In iteration 002, no done task is checked in tasks.md (T015 to T024 are all `- [ ]`), and
  `tasks-progress.yml` is the record of status. The question of how to check them went back to the reviewer session.
  **Ruling** (the reviewer session's, routine): leave `tasks.md` as it is; `tasks-progress.yml` is the record of task
  status in iteration 002, and no boxes are checked by hand. If a later gate asks for checked boxes, its exact message
  goes to the reviewer session then. The re-stamp is filed as B5F-091 (candidate, not planned), with a line in the
  hand-back note.
- **Class closure**: NONE — records only; the open questions are listed above.

### DRIFT-037 — T025 measured: the Stop hook is about 1.1 s faster per turn; the prompt hook is unchanged

- **Method** (iteration 001's DRIFT-073, unchanged): two scratch worktrees, `c108f00e5` (before T025) and `07ee3efed`
  (the T025 tip), neither with a pin record, so each runs its own `.specify` dispatcher. Each turn appends a typed prompt
  to a copy of the same real 53 MB transcript, then runs the prompt hook and the Stop hook through that copy's own
  `.claude/specrew-hook-launch.ps1` with the same payload. Engines alternate turn by turn: one first turn each, then ten
  steady turns each. Run from 04:24:16 to 04:30:07 local on 2026-11-18, on the reviewer session's go after its load check
  (04:22 to 04:23).
- **Results** (median / worst / best):

  | Turn | Hook | Before (`c108f00e5`) | After (`07ee3efed`) |
  | --- | --- | --- | --- |
  | steady, n=10 | Stop | 9.82 / 10.59 / 9.52 s | 8.69 / 8.78 / 8.59 s |
  | steady, n=10 | prompt | 4.01 / 4.06 / 3.98 s | 3.97 / 4.05 / 3.91 s |
  | first, n=1 | Stop | 13.42 s | 10.87 s |
  | first, n=1 | prompt | 8.71 s | 7.71 s |

  - The Stop hook's median is 1.13 s lower (11.5%), its worst 1.8 s lower, and its spread narrows from 1.07 s to 0.19 s.
  - The prompt hook is unchanged, as expected: T025 hands the snapshot and the tail only to the Stop providers.
  - Every exit was 0, and every Stop turn returned an empty output on both engines, so the behaviour is the same.
  - The first-turn numbers are single runs and indicative only.
- **Load** (the reviewer session's conditions): total CPU was sampled before each turn (24 logical processors): 13% at
  the start, 3% at the end, 0 to 9% between. No sweep, lane or installer appeared. A VS Code updater was present and near
  idle. Outliers: none. The before engine's slowest Stop turn (10.59 s) was 0.77 s over its median and is kept in the
  numbers. Home hook files: the crew's 12-file hash was identical before and after. Both worktrees and the temp folder
  were removed by their exact paths.
- **Against DRIFT-073's estimate** (about 14 s to about 5 s with all three proposed changes): T025 built two of the
  three, one git snapshot per hook run (23 to 12 git processes) and one transcript tail read per hook run, and they
  give about 1.1 s. The third is named in T025's Work ("the stores load once", `tasks.md:834`) but not in its
  Acceptance line (`:841`), and it is not built. By DRIFT-073's breakdown, each provider is its own `pwsh` process, and
  script loading before each provider's work took 0.75, 1.07 and 1.75 s, so most of the remaining Stop time is there.
  The reviewer session declined to rule that part away: dropping a named part of a task's Work is the maintainer's
  decision. The crew is answering the reviewer session's scope questions (what the line meant, a cheap form inside the
  current process layout, the one-process form, a recommendation), and T025 is not done until that is decided.
- **Class closure**: NONE — a measurement; T025's third change, its launcher half (T006) and its own sweep are still to
  come.

### DRIFT-038 — T006 left a thrown refusal in the generated Claude hook command; no test named it; fixed on T025's line

- **Found** (2026-11-18, while preparing T025's launcher half, the plain-text launcher refusals of iteration 001's
  DRIFT-046): T006 (`e85dff7fc`) made the generated project launcher's refusals plain text. The deployer, however,
  also writes the guarded-project-encoded hook command into Claude's `.claude/settings.local.json`
  (`deploy-refocus-hooks.ps1:407`, in all three copies). That command still threw
  `"Specrew hook launcher not found at '<path>'."` when the project launcher was missing. It runs through
  `pwsh -EncodedCommand`, so the host got CLIXML with ANSI color codes, one of the forms DRIFT-018 names and T006's
  acceptance covers ("a hook refusal is written as plain text"). No test named that line, and a redeploy would have
  kept it. Measured on today's command: stderr `#< CLIXML ... _x001B_[31;1mException: ...`, exit 1.
- **Ruling** (the reviewer session's, routine, inside the plan): T025's Work carries T006's launcher half and T025
  owns the deployer, so the fix closes T006's own acceptance and adds no scope. The conditions: RED first, a pinned
  launcher-present case, all three copies with the hash record, the class-guard lanes in the batch, the command-length
  limit checked, the hosts covered or named.
- **RED** `43dffe38f` (`tests/unit/hook-command-plain-refusal.tests.ps1`, red 3 of 12, one per copy). It builds the
  command from each copy's own functions by parsing them, and never runs the deployer. It is pinned on three points:
  - With the launcher present, the command runs it with `-Event` and no other arguments, passes its output through,
    and keeps today's exit (1 for a launcher exiting 3, 0 for 0).
  - With no project root, it does nothing and exits 0.
  - Every event's command stays within half of cmd.exe's 8,191 characters.
- **Fix** `4d750cfc2`: plain text on stderr with exit 1, in the sentence style of the launcher's other refusals, in
  all three copies, with the `.specify` hash record. The test is 12 of 12. Command length: Stop 996 to 1,588 characters,
  UserPromptSubmit 1,620 (the commit message's "about 1,560" was an estimate), within the 4,095 the length test
  allows.
- **Hosts**: only Claude's hosts use the guarded-project-encoded command.
  - Codex, Copilot and Cursor run the per-machine launcher with `-File`. A missing launcher there gets pwsh's own
    `-File` error, not a Specrew throw. Not covered here.
  - Antigravity's `launcher-encoded` command (`& '<launcher>' ...`) is a separate line of the same class and is not
    covered here. Candidate for the hand-back note if the maintainer does not place it.
- **A stray command, recorded**: while staging the fix, the crew's command line also ran
  `. ./scripts/internal/deploy-refocus-hooks.ps1 -?`, which was not intended. It deployed nothing: the crew's 12-file home
  hash was identical before and after, `.claude/settings.local.json` and the project launcher were unchanged since
  2026-11-13, and the only recent home writes were the Codex app's own log and model-cache files, before the call.
- **Not live**: the maintainer's "launcher: wait" (2026-11-16 03:13) stands. No deployer run on the real project; the
  maintainer is asked in session when the build is ready, with a scratch dry run's file list, the
  `settings.local.json` diff and the home hash before and after.
- **Class closure**: the new suite, in lane `f203-i001-suites`, holds the generated command to plain-text refusals.

### DRIFT-039 — The scratch dry run of the Claude hook deploy for T025's launcher half (evidence for the maintainer's question)

- **What ran** (the reviewer session's ruling, 05:13:42 to 05:13:47 local on 2026-11-18): the deployer ran in a temp
  worktree of `fc286aeca` holding copies of the project's ignored state (`start-context.json`, `last-start-prompt.md`,
  and the pin record and its bindings). It was the tip's own deployer, run with `-HostKind claude`, with the home
  redirected by both `-UserHomeOverride` and `SPECREW_USER_HOME_OVERRIDE`. Nothing ran on the real project, whose
  `.claude/settings.local.json` and `.claude/specrew-hook-launch.ps1` are still dated 2026-11-13 00:52:32. The
  deployer reads no pin at deploy time: its live-engine text is only written into the launchers it generates.
- **What it wrote**: exit 0, "claude hooks deployed ... (SessionStart + UserPromptSubmit + Stop + PostToolUse;
  PreToolUse dormant)". Exactly two files changed, both in the project's `.claude` folder:
  - `.claude/settings.local.json`: the four hook commands. Each is the same encoded command with the plain-text
    missing-launcher refusal (DRIFT-038).
  - `.claude/specrew-hook-launch.ps1`: the three pin refusals and the dispatcher refusal become plain text on
    stderr with exit 1 (T006, `e85dff7fc`). The baked `$HostBinding` gains one origin rule: a cross-session
    message counts as host-injected. The new baked binding is byte-identical to the pin's own Claude binding
    (`.specrew/runtime/live-engine-bindings.json`). The launcher uses the pin's binding whenever a pin record exists,
    so on this pinned project the baked change has no effect.

  Nothing was written to the redirected home, and the crew's 12-file hash of the real home was identical before and
  after. The diffs are kept in the crew's scratchpad (`t025-dryrun-settings.diff`, `t025-dryrun-launcher.diff`). The
  temp copy was removed by its exact path.
- **For the maintainer**: the deploy writes only the project's two `.claude` files and nothing in the home folder.
  The maintainer's "launcher: wait" (2026-11-16 03:13) stands until they answer. The question is asked in session,
  separately from T025's push.
- **Class closure**: NONE — evidence for a decision.

### DRIFT-040 — The T025 sweep of `77d9b511d` was red on the home-isolation guard: the new suite did not say it writes no home

- **The sweep** (05:16 to 06:30 local on 2026-11-18, Throttle 3, 1,500 s per suite; git sampled every 2 minutes,
  37 samples, all ok): 282 suites, 1 failed, 2 known red (B5F-036). Nine lanes exit 0, and `f203-i001-t008-suites`
  exit 1 on the same suite. Home hook files: 0 changed before or during, 0 written to the redirected home, and the
  crew's 12-file hash identical. Nothing pushed.
- **The one cause**: `tests/unit/test-home-isolation.Tests.ps1` holds every test file that names a hook-writing entry
  point to a private home, or to a `# specrew-test-home: not-a-writer - <why>` line. The new
  `hook-command-plain-refusal.tests.ps1` (DRIFT-038) names the deployer, because it parses its three copies, and had
  neither. It never runs the deployer; it runs only the hook command it builds, against a stub launcher in a temp
  folder.
- **Why the batch missed it**: the commit's batch on `0eaf94b41` ran the class-guard lanes, `f203-i001-suites`,
  `f203-i001-carried` and seven single suites, but not `f203-i001-t008-suites`, where the home-isolation guard lives.
  DRIFT-035's standing practice names only the class-guard lanes.
- **Fix** `cbc50e869`: the not-a-writer line, saying why. There is no separate RED commit, because the guard was red
  on the swept tip, as recorded here. Alone: `test-home-isolation` exit 0, `hook-command-plain-refusal` 12 of 12,
  `every-suite-is-named-by-a-lane` exit 0.
- **Proposed practice** (for the reviewer session): a commit that adds a test file runs the class-guard lanes and
  `test-home-isolation.Tests.ps1` in its own batch, the home-isolation guard being the other repository-wide check a
  new test file can fail.
- **Ruled** (the reviewer session, routine, 06:34 local): a commit that adds or renames a test file runs, in its own
  batch, every guard that judges test files by their existence, name, location, header or content. The inventory
  (the crew's search of `tests/`, `tools/` and the workflows on `9f1605749`, for checks that walk the whole `tests`
  tree):
  1. `tests/unit/every-suite-is-named-by-a-lane.tests.ps1`: every test file is named by a lane. In lane
     `f199-class-guards-a` (with `-b` beside it).
  2. `tests/unit/test-home-isolation.Tests.ps1`: a test that names a hook-writing entry point has a private home, or
     a not-a-writer line saying why. In lane `f203-i001-t008-suites`.
  3. `tests/integration/host-coupling-firewall.tests.ps1`: no host-name enumeration outside `hosts/`. It scans every
     `.ps1` under the repository, `tests/` included. No lane; it runs in CI.
  4. Specrew CI's Lint, PSScriptAnalyzer with the PSGallery settings, errors only: every `.ps1`, `tests/` included.
     Only in CI.

  The other candidates scan only `scripts/`, `extensions/` or fixtures they build, and do not judge test files:
  `no-internal-ids-in-emitted-strings`, `no-automatic-variable-collisions`, `path-identity`, `twin-copy-parity`,
  `regression-harness-isolation`, `full-sweep-direct-exit`, `authority-control-consumer-guard` and
  `forge-neutralization-sweep`. On `9f1605749`, against the seven test files added in iteration 002
  (`hook-command-plain-refusal`, `hook-run-git-snapshot`, `hook-git-snapshot-reader`, `hook-transcript-tail`,
  `records-only-source-repo-narrowed`, `review-end-one-approval`, `plan-crossing-pending`), each was run alone:
  - guards 1 to 3 exit 0;
  - PSScriptAnalyzer: 0 errors, and one warning each in `hook-run-git-snapshot` and `plan-crossing-pending`
    (warnings do not block).

  Nothing to fix. A candidate for the hand-back note: one "new test file" lane that runs all four.
- **Next**: a full sweep of the new tip, then the gated push of that exact revision.
- **Class closure**: the existing guard caught it before any push; the batch gap is the proposed practice above.

### DRIFT-041 — T025's scope decided by the maintainer: build the navigator reorder; "the stores load once" is met; one process deferred

- **Decision** (the maintainer, typed in the reviewer session at 11:36 local on 2026-11-18, relayed by the reviewer
  session under the wider delegation): "203 T025: build the navigator reorder; stores load once is met; defer one
  process". It answers the reviewer session's scope question, which DRIFT-037's correction raised: T025's Work named
  "the stores load once", its Acceptance did not, and dropping a named part of a task is the maintainer's.
- **"The stores load once" is met per provider process.** The crew measured it on 2026-11-18 on an instrumented
  scratch copy of `1696482a3`. Each provider loads its stores once; the only repeats are five files loaded twice inside
  one process (`ProjectMetadataAccessor` in conformance; `path-identity`, `process-tree`, `hook-health-receipt` and
  `host-support-tier` in the navigator), together under about 0.1 s. Loading inside a process is cheap:
  `shared-governance.ps1` (506 KB) 72 ms, the HumanAuthorityStore chain 216 ms. DRIFT-073's "script loading 0.75,
  1.07 and 1.75 s" turned out to be mostly pwsh start-up, the navigator's whole co-review stack (1.1 s) and first-call
  compilation.
- **The navigator reorder** (built in T025, RED first): on a Stop, the navigator's scope check took 1.2 to 1.3 s, and
  nearly all of it is `Test-ReviewCampaignCoverageDeltaHasImplementation`: 0.8 to 1.0 s and eight git calls
  (merge-base with the trunk, a diff, a whole-tree status, check-ignore). It ran before the 25 ms read of whether a stop
  is open. The reviewer session's routine conditions:
  - authority, stage and identity keep today's order;
  - only the coverage check moves after the open-stop read;
  - an open stop still gets the scope check, and the scope check still decides;
  - an unreadable store keeps today's order and note;
  - every test that pins a changed reason is listed, with the reasons before and after.

  About 0.5 SP, taken from the stated buffer as an overrun on record (as DRIFT-022); T025's row stays 5.0 SP.
- **One process deferred** to the follow-up feature: B5F-092 (`docs/beta5-findings.md`) carries the numbers, the
  size and what could break, and the plan's "Moved out" list names it.
- **Records amended**: T025's Work, Acceptance and Owns in `tasks.md`, and its row and the "Moved out" list in
  `plan.md`, each quoting the decision.
- **Class closure**: NONE — a scope decision; the reorder lands as its own RED and fix, then its own measurement,
  sweep and push.

### DRIFT-042 — T025's navigator reorder built and measured: the Stop hook about 0.9 s faster, a quiet Stop 12 git calls to 4

- **Built** (DRIFT-041's decision; the reviewer session's routine conditions, accepted at 11:47 local on 2026-11-18):
  RED `ae1ca8e74`, red 3 of 7 in `continuous-co-review-navigator.Tests.ps1`, no new test file. Fix `2de23bb06`:
  `Get-ReviewCampaignNavigatorScopeApplicability -DeferImplementationCheck` leaves only the coverage check to the
  Stop navigator, which runs it once a stop is found open (where it decides as before) and on an unreadable store
  (today's order kept). The function's default is unchanged.
- **The open-stop decision is byte-identical**: captured on the same fixture before (on `d3e89633d`) and after,
  1,158 identical bytes; the suite pins the block as a literal.
- **Reasons that change** (both stay quiet, with no block):
  1. No stop open, at before-implement or implement, over a records-only delta:
     `campaign-not-applicable:no-implementation-yet (<reason>)` becomes `no-open-stop`.
  2. A stage after implement where the scope applies (for example review-signoff), over a records-only delta, stop
     open or not: the same old reason becomes `not-implement-stage`, because the stage check now comes before the
     coverage check.

  Every other reason is unchanged. The only test that pinned a changed reason is the navigator suite's "an empty
  stage (fully-resolved records-only delta) is quiet" case. Its expectations are amended in the RED commit, from
  `-Match 'no-implementation-yet'` to `no-open-stop` (before-implement) and `not-implement-stage` (review-signoff).
- **Tests alone**:
  - `continuous-co-review-navigator` 41 of 41;
  - `campaign-activation-implementation-premise` 5;
  - `review-navigator-stops` 11;
  - `campaign-stop-authority` 22;
  - `review-advisory-session-scope` green.

  Batch: lane `f203-i001-t008-suites` on `2de23bb06` exit 0 in 450 s, in a temp worktree with the home redirected.
  The crew's 12-file hash was unchanged, and nothing was written to the redirected home.
- **Measured** (DRIFT-073's method, both engines now, alternating, 11:58:50 to 12:04:12 local; `608b21ba6` before and
  `2de23bb06` after; one warm-up turn each, not counted):

  | Hook, n=10 | Before (`608b21ba6`) median / worst / best | After (`2de23bb06`) median / worst / best |
  | --- | --- | --- |
  | Stop | 8.87 / 8.95 / 8.66 s | 7.97 / 8.15 / 7.81 s |
  | prompt | 3.98 / 4.05 / 3.93 s | 4.10 / 4.13 / 4.04 s |

  - The Stop median is 0.90 s (10.1%) lower. The before spread was 0.29 s, under the reviewer session's 1.5 s mark.
  - The prompt hook does not run the navigator. Its 0.11 s difference is in the other direction and is not
    explained by this change.
  - A quiet Stop made 12 git calls before and 4 after. The coverage check's eight calls are gone: rev-parse three
    times, symbolic-ref, merge-base, diff, status and check-ignore. Left are the dispatcher's snapshot (three) and
    the handover's log.
  - Every exit was 0, and every Stop output was empty on both engines.
- **Load** (the reviewer session's conditions): the first start was refused at 11:57:05 (46% on one sample taken
  during setup). The start check was then made an average of eight samples after setup: 12.2% (18, 3, 21, 29, 14, 6,
  1, 6). The samples before each turn were 2 to 27%, and the end 6%. No sweep, lane or installer appeared, and nothing
  was removed as an outlier.
- **Not comparable with DRIFT-037's 8.69 s**: that was measured at night under 0 to 13% load. This run is daytime, with
  the maintainer at the machine and the 206 crew active. Only the before and after of this run are compared.
- **Live only after a pin advance**: the pin (`da78b600`) still runs the old navigator. The pin advance is the
  maintainer's.
- **Class closure**: T025's Acceptance is met on the crew's say: the Stop median fell again. The navigator suite's
  T025 context holds the reorder. The full sweep and the push follow.

### DRIFT-043 — T025 done; the deployer question carried to the review-signoff packet

- **The last T025 sweep and push**: the full sweep of `638551594` (12:06 to 13:15 local on 2026-11-18, Throttle 3,
  1,500 s per suite; git sampled every 2 minutes, 35 samples, all ok): 282 suites, 0 failed, 2 known red (B5F-036),
  all 10 lanes exit 0. Home hook files: 0 changed before or during, 0 written to the redirected home, and the crew's
  12-file hash identical. markdownlint and `validate-governance -ChangedOnly` passed, and `638551594` was pushed as
  swept at 13:16:15 (`608b21ba6..638551594`). CI was green on every job:
  - Specrew CI `44293149770`: Lint, Self-leak firewall, Deterministic gate and Contract lane;
  - Cross-Platform Validation `44293149642`: all eight jobs;
  - Test `44293149835`.
- **T025 done** (the reviewer session's ruling: the deployer question does not block "done", because T025's Work
  says the crew asks the maintainer before the deployer runs, and the maintainer's "launcher: wait" is their answer
  until they give another). It was set done once through the task writer (B5F-091 in mind). T025 had never been set
  in progress, so the writer stamped both `started_at` and `completed_at` with the call's time (2026-11-18 11:46:51
  UTC). The work began with the RED `634785049` at 00:17 local on 2026-11-18. The file is left as the writer wrote it.
- **Carried to the review-signoff packet (open item)**: whether to redeploy this project's Claude hooks.
  - The maintainer's "launcher: wait" (2026-11-16 03:13) stands until they answer.
  - The dry run (DRIFT-039) showed the deploy writes only `.claude/settings.local.json` and
    `.claude/specrew-hook-launch.ps1`, and nothing in the home folder.
  - Until then the plain-text refusals (T006's launcher half, `4d750cfc2` and `e85dff7fc`) are in the branch, not in
    the live launcher.
  - The navigator reorder (`2de23bb06`) reaches the live hooks only at a pin advance (DRIFT-042), which is also the
    maintainer's.
- **Class closure**: NONE — a task closure and an open item.

### DRIFT-044 — T030 part one: main (206 and its lane guard fix) merged in; three cross-feature findings; T031 added and built

- **The merge** (the reviewer session's word, 13:48 local on 2026-11-18, "206 is on main"; part one is local only):
  - The first attempt merged `d5f4af878` and stopped on a rule disagreement. Main's
    `every-suite-is-named-by-a-lane` pinned 206's review layout: the plan names exactly 206's six lanes, and the
    parked file equals `d3e33550`'s plan byte for byte. That bound every branch taking main in.
  - The reviewer session confirmed it as a defect in 206's guard. The maintainer decided "main guard fix: 206 crew,
    small PR off main" (20:13 local, relayed), and it landed as `e6732b278`.
  - The staged merge was aborted and redone once on `e6732b278`, reusing the six resolved blobs byte for byte (the
    conflicted files are identical at both heads). It is merge commit `2f0032da8`, whose message lists each
    resolution.
  - The hash record was regenerated from the merged blobs, with all 174 entries checked. The plan files follow the
    ruled layout: active = 203's ten lanes, unchanged; parked = 203's parked file plus `iteration-003-governance-202`
    and 206's six lanes, with no lane id in both files.
  - One slip, corrected before any commit: my first union of `lifecycle-events.jsonl` dropped events. ConvertFrom-Json
    had already turned `recorded_at` into a date, and the date parse failed. The file was restored from the merge
    stages and redone reading `recorded_at` as text: 35 events.
- **The reading** (the reviewer session's condition): three functions were changed by both sides, in disjoint regions:
  `Add-SpecrewBoundaryAuthorization`, `Test-IterationGovernance` and `Invoke-SpecrewBoundaryStateSync`. 206's
  `Get-SpecrewRecordApprovalState` and 203's `Get-SpecrewPlanCrossingState` follow one rule, and
  `finding-e2ef0515b3bc7a8f` is fixed on main (`d1e428b98`).
- **Finding 1, a 206 test that 203's engine refuses**: `closeout-dashboard-redraw` (206 T035) recorded a captured
  closeout verdict with no cited turn, which FR-022 refuses. It was adapted as T004 adapted its own callers, in
  `34366dba0` (2 of 2). This is the reviewer session's ruling: it cannot be made on main.
- **Finding 3, main's tests under 203's home guard**: `test-home-isolation` flagged seven files from main. Each was read
  for what it runs: none deploys hooks, and the three that run `specrew-start.ps1 -NoLaunch` point
  `SPECREW_USER_PROFILE_PATH` at a temp file first. One not-a-writer line each, in `da6701012`; the guard passes 5 of 5.
- **Finding 2, the latest boundary sync is another feature's** (B5F-093): after the merge the decisions ledger ended
  with 206's feature-closeout, and four readers took it as 203's state. `project-path-resolution-regression`, now in
  per-push CI, refused a fresh clone as stale.
  - The facts: re-anchor rewrites only per-machine files, and no governed action writes a 203 sync before
    review-signoff.
  - **The maintainer added T031** ("203 add task: feature-aware boundary sync reader, about 1 SP", typed in the
    reviewer session at 20:08 local on 2026-11-18, relayed), inside T030's merge work.
  - RED `7a3a803e5` (red 10 of 12), fix `b4450c497` (12 of 12); the four test-file guards pass on the new suite.
  - **The expected-next check changed:** the boundary sync's expected-next check now reads the feature's own last sync,
    so a feature's first sync after another feature's closeout expects the first boundary (specify), and a first
    recorded sync elsewhere writes a warning entry instead of passing silently. This is pinned in the suite.
- **B5F-036's two suites** on the merged tree, alone: `validator-hardening-iteration2` green (206 fixed it) in 889 s,
  near the 900 s limit that run used; it leaves the sweep's known-red list and runs under the sweep's 1,500 s suite
  limit. `project-path-resolution-regression` no longer loops (206's fix) and is green once T031 is in.
- **Capacity**:
  - T031 is a new row at 1.0 SP: task rows 21.0 of 20, over capacity by the maintainer's scope addition.
  - **Correction to DRIFT-041**: its "about 0.5 SP, taken from the stated buffer" was wrong. The buffer stood at
    about 0.3 SP after DRIFT-022, DRIFT-023, DRIFT-025 and DRIFT-026, so T025's navigator reorder overran it by about
    0.2 SP. The buffer is spent.
- **Records**: T031 in `tasks.md` and the plan (traced to B5F-093 and proposal 166 FR-008; the maintainer prioritised
  166 at 20:14). B5F-093 is in `docs/beta5-findings.md`. The hand-back note gains two lines: main's tests before 203
  merges need the cite and the marker, and the two home-safety rules should become one (proposal 166).
- **Next**: part one's batch in a temp worktree. Part two (205 on main, the full sweep, the push) waits for the
  reviewer session's word.
- **Class closure**: findings 1 and 3 by their own suites, now green; finding 2 by T031's suite.

### DRIFT-045 — T030 part two: main with 205 merged in; the reviewer catalog's codex reference kept as 203's; the known-red list emptied

- **The merge** (the reviewer session's word at 00:40 local on 2026-11-19: "205 is on main", `a78ac54cf`, under the
  maintainer's merge go of 00:06): merge commit `93b36d034` (parents `3531a5515`, `a78ac54cf`). The home hook files were
  hashed first. Six conflicts, each resolution listed in the merge message:
  - `.squad/active-features.yml` and `.specrew/closed-iterations.yml`: both features' entries.
  - `.squad/events/lifecycle-events.jsonl`: two blocks, each the deduplicated union in `recorded_at` order. 206's
    event of 15 Nov 16:47 was on both sides, because 205 had merged 206 too.
  - The parked-lanes file: 203's 14 lanes plus 205's two, none also active.
  - One hash-record entry (`design-workshop.md`) recomputed from the merged blob, and all 174 entries checked.
  - `.specrew/reviewer-hosts.json` (below).
- **The reviewer catalog** (a stop, then the reviewer session's ruling, option 1): both sides changed only codex's
  `authorization_ref`:
  - base: `workshop-202-beta4-1-ux-stabilization`;
  - 203's workshop (`fe1b9ac0c`): `9cf4941286e3612614fee43468e0ec6d4f5c551ca184e07ee52b4bab3b7c16e8`, which 203's
    records cite;
  - 205's workshop (`7a4e6d7ad`): `workshop-205-workshop-lens-order`.

  Everything the engine acts on (model, adapter, allowed, rank, fallback) is identical on both sides, and
  `Test-ContinuousCoReviewReviewerAuthorization` accepts any non-empty reference without resolving it. So the campaign
  behaves the same either way: the difference is provenance. 203's value is kept, because 203 uses the catalog next and
  205 is closed. For proposal 166: a per-project catalog that each feature's workshop rewrites (the last merge wins),
  and a gate that never resolves the reference. The second is a hand-back candidate, not fixed here.
- **On the merged tip**: every-suite-is-named-by-a-lane, test-home-isolation and host-coupling-firewall exit 0.
  test-home-isolation flags none of 205's tests, so there was no marker commit. PSScriptAnalyzer found 0 errors in the
  nine changed scripts, and T031's suite passed 12 of 12.
- **The known-red list emptied** (the reviewer session's ruling, before the sweep): both B5F-036 entries were removed
  from `tools/maintenance/sweep/known-red.txt`, so the sweep runs both suites under its own 1,500 s limit and is the
  evidence that they are green on the merged tree. B5F-036 is closed by 206's fixes, which arrived through the merge.
  Alone on the part-one tree, `validator-hardening-iteration2` took 835 to 889 s. Its time under the sweep's load is
  reported, and above 1,200 s it goes to the reviewer session before the push.
- **Class closure**: NONE — a merge record; the full sweep, the push and CI follow and are recorded when they conclude.

### DRIFT-046 — The sweep of `876874a72` was red on three suites from two cross-feature causes; both fixed test-only

- **The sweep** (01:09 to 02:37 local on 2026-11-19, Throttle 3, 1,500 s per suite; git sampled every 2 minutes, 44
  samples, all ok): 338 suites, 3 failed, 0 known red. Nine lanes exit 0; `f203-i001-carried` exit 1, on one of the
  three suites. Home hook files: 0 changed before or during, 0 written to the redirected home, and the crew's 12-file
  hash identical. Nothing was pushed.
- **B5F-036, off the known-red list**: `project-path-resolution-regression` green in 134 s, and
  `validator-hardening-iteration2` green in 951 s under load, under the reviewer session's 1,200 s mark. The empty
  known-red list held.
- **Cause 1, 205's workshop fixtures under 203's cited-turn rule** (203 T013, B5F-066):
  - `workshop-agenda-grouping` (205 T031) wrote its product-domain receipt with no typed turn, so the three
    real-catalog renders were refused at `confirm-workshop-agenda.ps1:145` ("Product-domain has no typed human reply
    receipt").
  - `workshop-agenda-confirmation`'s FR-013 case (205) appended hand-written lens receipts with no turn and a
    placeholder `response_hash`, so the lens writer refused them.
  - The receipt rule itself is from beta3 and on both sides. What refused is 203's sender check: a receipt is used only
    when its typed turn is found, and its text says what the turn said.
  - Fixed in `6e462b6ec`: the fixtures write a typed turn with 203's helper (`tests/support/cited-typed-turn.ps1`), and
    the FR-013 receipts carry the reply's own hash.
  - **The product check** (the reviewer session's condition): 205's product changes are the grouped agenda's
    presentation, `index.yml` as the one lens order, and read-only stack freshness lines. None writes a workshop
    answer, a skipped reason or an agenda decision. The writers 205's paths use require typed receipts:
    `confirm-workshop-agenda.ps1:143-147` (product-domain) and `:253-267` (the agenda's receipt, bound to its digest),
    and `confirm-workshop-lens.ps1:208-224`, which 205 did not change. So it is a fixture, not a product disagreement.
- **Cause 2, a 203 test broken by 206's validator change**:
  - `closeout-records-on-approval` lifted `Test-SessionStateBoundaryCanonical` by text. 206 made that rule call its
    new `Add-ValidatorStopMessage`, which reads `$script:ValidatorStopMessages`, so case 7 failed ("The term
    'Add-ValidatorStopMessage' is not recognized").
  - Fixed in `9a6e7f092`: the suite lifts by dependency (the rule, every validator function it calls, through the
    AST, and the top-level assignments of the script variables they use), so the next helper is lifted the same way.
  - **On main** (`a78ac54cf`, a temp worktree, the home redirected), the unmodified suite is red the same way. There
    it is named only by the parked lane `f202-i003-suites`: no active lane, no CI step and no release list runs it, so
    the parked lane hid the red. It goes to the hand-back note and is not fixed on main.
- **Reruns on `9a6e7f092`** (a temp worktree, the home redirected): `f203-i001-carried` exit 0 (208 s), and the three
  suites green alone. No test file was added, so the inventory guards are not owed.
- **Class closure**: cause 1 and cause 2 by their own suites, now green; the parked-lane blind spot is a hand-back
  candidate.

### DRIFT-047 — The sweep of `f30f5ea3d`: one wall-clock budget red, pushed on the reviewer session's ruling; the reviewer order kept (the maintainer); desktop candidates H to K passed on

- **The sweep** (02:41 to 04:20 local on 2026-11-19, Throttle 3, 1,500 s per suite; git sampled every 2 minutes, 49
  samples, all ok):
  - 338 suites, 1 failed, 0 known red, 0 spanned standby.
  - All ten lanes exit 0: `f203-i001-suites` 555 s, the t008 lane 597 s, `f203-i001-carried` 208 s.
  - Home hook files: 0 changed before or during, 0 written to the redirected home, and the crew's 12-file hash
    identical.
  - The three suites DRIFT-046 fixed are green. B5F-036's two suites are green: `project-path-resolution-regression`
    143 s, `validator-hardening-iteration2` 976 s, under the 1,200 s mark.
- **The one red**: `tests/integration/feature-018-render-budget.ps1`, a wall-clock budget of 1,500 ms for one dashboard
  snapshot and render.
  - It took 2,113 ms in the sweep, and 1,894 ms (red) then 1,292 ms (green) alone on the same revision.
  - It was green in the sweep of `876874a72` with the same renderer. `f30f5ea3d` differs from that revision only by
    two test-only fixes and records, and the renderer's only change since 203's last push is 206's `4c543c1a3`, already
    in `876874a72`.
  - It is 206's bug-list item 11 ("sits on its 1.5 s budget"), carried in 206's seed for the next bug bash.
- **Ruling** (the reviewer session's, routine, options (a) with (d)): `f30f5ea3d` is pushed as swept, with no
  re-sweep. If CI fails only on this suite, that is a timing case under the maintainer's standing rerun exception: one
  rerun of the failed job, recorded. Anything else red stops the push. The absolute budget inside a per-push CI step is
  a hand-back line.
- **The reviewer order** (the maintainer, typed in the reviewer session at 02:48 local on 2026-11-19, relayed): "203
  reviewer order: A".
  - The granted order is kept: codex, copilot, claude, 4 rounds. There is no re-grant and no lifecycle step back.
  - It was decided on the crew's facts: the order is in the before-implement grant; both hosts launch on this machine;
    a failed launch spends nothing; a clean round ends the review.
  - Codex's own lines in `adedce10e` have two other reads: the crew's review and correction, and the reviewer
    session's own read.
  - The campaign starts after this push is green on CI and T023 (ii) is done, on the reviewer session's word. If
    Codex's round 1 is clean, the crew tells the reviewer session before anything moves toward sign-off.
- **Desktop candidates** (the maintainer, typed in the reviewer session at 02:48, "Desktop H, I and J: pass them", and
  at 03:10, "Desktop K: pass it", relayed): defects met on a released 0.40.0-beta41 install. They are recorded in the
  hand-back note's new section "Seen on a released install, 0.40.0-beta41", each with whether the merged tree still has
  it. None is fixed in 203.
- **Class closure**: NONE — a sweep record, two maintainer decisions and hand-back candidates; the push and CI follow.

### DRIFT-048 — CI after the merge push: a Linux-only red in 203's own review-link reader (FR-046 rework), found by a suite that reached 203's CI through main

- **The push** `9cd5a134e..16756e2fd` (04:18:57 local on 2026-11-19): Cross-Platform and Test green on every job.
  Specrew CI's Deterministic gate (ubuntu, job 135292628066) failed `agent-led-workshop-replay.tests.ps1` (one failure,
  `:223`), and the Contract lane was skipped after it. The render-budget ruling (DRIFT-047) did not apply.
- **A diagnostic rerun** of the gate (job 135299486082, the reviewer session's ruling; not a use of the standing rerun
  exception): red on the same case, so the failure is deterministic on Linux. No further rerun.
- **Facts:**
  - The suite was not in Specrew CI on 203 before. 205's `8d8700984` (named CI steps) added it on main, and it reached
    203 with the merge. Main's run on `a78ac54cf` passed it.
  - In WSL (pwsh 7.4.6 already installed; nothing installed; each tree copied into WSL's own `/tmp` by `git archive`,
    HOME in a WSL temp folder, nothing under the Windows profile read or written, the copies removed by exact path),
    the suite fails the same way on `16756e2fd` and on `9cd5a134e`, 203 before the merges. It passes on Windows (both
    full sweeps).
- **Cause:** the fixture's review link is `'file:///'` plus the spec's path with forward slashes. On Linux the path
  starts with `/`, so the URL has four slashes. 203's T011 reader (`Get-SpecrewReviewTargetLinks`, FR-046) resolved
  it with `[System.Uri]::new($url).LocalPath`, which on Linux .NET is a UNC host `tmp` (`\tmp\x\spec.md`). So a
  spec that exists was "review link to a missing file", and the complete packet was blocked.
  - It was the fourth consecutive block; the cap (3) released it with the generic subject "verdict marker"
    (`specrew-conformance-provider.ps1:1972`), which named the wrong requirement.
  - Main passes because main has no "every review link resolves" check: it is 203's.
  - It is a product defect, not a fixture: the engine itself writes that form on Linux and macOS at six sites.
- **Ruling** (the reviewer session's, routine): go, a failing test first and then the fix, in the one reader. Recorded
  as rework on 203's own requirement, found by CI before the review: about 0.5 SP, so the iteration's overrun over the
  spent buffer is about 0.7 (plan.md's Rework row).
  - `7823c0cfd`: the failing test, `review-link-file-url-local-path.tests.ps1`, with 22 red on Windows. It tests
    `ConvertTo-SpecrewFileUrlLocalPath` with `-Platform`, so every case runs on every OS: three, four and five
    slashes, `%20`, a literal `%`, `%25`, localhost (supported, RFC 8089), another host and an empty path (no local
    path), and the Windows forms equal to System.Uri's. It also covers the packet reader on a real temp file through
    the engine's own URL form, and the missing-file refusal unchanged. Named in lane `f203-i001-suites`.
  - `6fd9b6518`: the fix, with 25 green. Windows is unchanged; elsewhere a file URL is `/` plus its path with the
    leading slashes collapsed, then percent-decoded. The `.specify` mirror and its hash record are in the same commit.
    The inventory guards, the mirror record, crossing-presentation and PSScriptAnalyzer are clean.
- **Hand-back** (not fixed here): the cap's generic subject for a packet block; the six engine sites that build
  `'file:///'` plus a POSIX path; and the class itself, that a Windows sweep cannot see a Linux-only red and a suite can
  reach a feature's Linux CI first through a merge. Also added to the hand-back note: desktop candidate L ("Desktop L:
  pass it", 04:33 local, relayed).
- **Before the push** (the reviewer session's order, fail fast):
  1. In WSL: the new suite, `agent-led-workshop-replay`, the turn-end and packet suites, and whatever of the gate's
     remaining steps and the Contract lane runs there without network, secrets or a real home.
  2. On Windows: the reader's, turn-end, packet and conformance suites, then the full sweep of the pushed revision.
  3. The push, with CI on every job; the Deterministic gate and the Contract lane must both run green.
- **Class closure**: the review-link reader's local-path reading is pinned on every OS by
  `review-link-file-url-local-path`; the class of a Linux-only red that a Windows sweep cannot see is handed back.
- **The Linux checks in WSL** on `491d0f4c9` (the reviewer session's ruling to go on, routine):
  - The method: the tree went in by `git archive` through stdin, PATH held Linux paths only, HOME was a WSL temp
    folder, nothing was installed and nothing under the Windows profile was touched.
  - Phase A, 9 of 9 green: the new suite (24 passed, 1 skipped, the Windows-host case), `agent-led-workshop-replay`
    (32 PASS) and the turn-end and packet suites.
  - Phase B, 103 of 108 green: every gate step after the replay in workflow order, the bootstrap loop, the F-206
    census step, the Pester step and the Contract lane's two suites.
  - Four suites did not run on Linux locally, and CI is their evidence: `task-progress-tracking`, `version-checks`,
    `project-path-resolution-regression` and `brownfield-conflict-handling`. Each stops at the bootstrap's dependency
    check ("uv not installed", "Node.js not installed"), because WSL has neither and nothing was installed. The
    Contract lane's start suite skipped its main cases for want of `specify` and `squad`; its no-hang case passed.
  - One sighting: `tests/bootstrap/MarkerAtomicWrite.Tests.ps1`, "after the race the marker is a single VALID object
    (no persistent corruption)". It was red once, under the load of phase B's run: one suite at a time, after about
    100 suites, with Windows otherwise idle (0 to 12% CPU before the run). Alone it was 3 of 3 green (about 1,500 reader
    samples each, 0 exceptions). 203 has touched neither the suite nor its writer. It is not on the standing exception:
    if it goes red in CI, the push stops and is reported, with no rerun. Hand-back candidate.
  - Two limits of the check: WSL clears `/tmp` when the distro idles, so the first run's logs were lost and the checks
    keep their logs under `/var/tmp`; and WSL has Pester 6.0.0 where CI likely has 5.x, a known unknown of this check.
- **Standing practice from now** (the reviewer session's ruling): when a change touches path, URL, process-launch or
  line-ending handling, or after a merge of main that brings new per-push CI suites, the Linux subset runs in WSL
  before the push, by this method.
