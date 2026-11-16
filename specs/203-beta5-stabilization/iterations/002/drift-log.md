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
