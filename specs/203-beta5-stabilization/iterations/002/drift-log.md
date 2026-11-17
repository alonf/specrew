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
