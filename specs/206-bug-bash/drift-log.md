# Drift Log: 206-bug-bash

**Feature**: 206-bug-bash
**Scope**: feature-level findings recorded before the first iteration exists

## DRIFT-206-001 — the workshop hook stored a receipt for a message that answered no workshop question

- **Recorded**: 2026-11-10, at the maintainer's instruction. Evidence for feature 203's capture work; not
  fixed in 206.
- **What happened**: `.specrew/runtime/workshop-authority.jsonl` holds two `product-domain` receipts for this
  feature, both `human-confirmed` / `lens-question`:
  - `4c7eca3aec78a8a729bb723114182a366c9075e9e132f95eb858ae12da963c43`, recorded 03:28:23 local
    (01:28:23Z), for the maintainer's message beginning "Recovery: not an override yet…". That message
    ruled on the specify-gate recovery and the triage; no product-domain question had been asked yet.
  - `fa0b6d95b75e59ce61cf183afa0f0b64ee0d0b0459307e901910c1c2ddf38982`, recorded 03:30:24 local
    (01:30:24Z), for the maintainer's "confirm - Light depth and this picture are right…", the real answer
    to the product-domain question.
- **Consequence avoided**: only the second receipt is cited in `lens-applicability.json` and the
  product-domain record. A writer that took "any receipt for this lens" would have bound the lens to a
  message that never answered it.
- **Same class, next message**: on the maintainer's push approval ("Approved: push 206-bug-bash to
  origin…"), the prompt hook reported "your agenda confirmation was received but NOT bound". No agenda had
  been presented and none was confirmed; the hook read an approval of a push as an agenda confirmation.
  Nothing was recorded, so nothing needs undoing.
- **Owner**: feature 203's follow-up (capture work).

## DRIFT-206-002 — iteration 002's scope, decided by the maintainer (Amendment A1)

- **Recorded**: 2026-11-15, after iteration 001's closeout and before iteration 002's folder exists.
- **Decision** (maintainer, 11:31 local, to the reviewer session, relayed under the wider delegation; a decision, not
  an approval): "OK, agree, do it", answering the reviewer's recommendation:
  - in scope: the carried work (SC-002 first, SC-001, T016, T017, DRIFT-206-I001-010, items 12 and 15 to 35) plus
    items 37, 39, 41 and 44;
  - the four need requirements, so the spec is amended through clarify first (Amendment A1, FR-015 to FR-018);
  - everything is sized; if it exceeds capacity, the plan shows what moves out and why; the cut is the maintainer's
    at the plan approval;
  - item 37 links feature 203's T014 case and proposal 206, and says how far the fix goes;
  - not in scope: items 40, 42 and 43 (feature 203's code) and items 36 and 38 (later).
- **Where it is applied**: `spec.md` (scope tables, FR-015 to FR-018, SC-008 to SC-011, Clarifications session
  2026-11-15) and the bug list's Iteration 002 Intake.

## DRIFT-206-003 — the rerun exception also covers `empty-result-retry.Tests.ps1` (standing rule)

- **Recorded**: 2026-11-15.
- **Decision** (maintainer, 11:31 local, the same "OK, agree, do it", relayed by the reviewer session under the wider
  delegation): the standing rerun exception for `tests/continuous-co-review/unit/co-review-service.Tests.ps1:129`
  also covers `tests/continuous-co-review/unit/empty-result-retry.Tests.ps1` (bug list item 3), on the same terms,
  until feature 203 merges.
- **Terms**: when Specrew CI fails only in that test, on a push that could not have caused it, the failed job may be
  rerun once without asking. Each use is recorded as a sighting with the run and the job, and added to the hand-over
  to 203. A second failure stops the work. It covers nothing else.

## DRIFT-206-004 — after a closed iteration, the clarify sync for Amendment A1 opened no approval point (second sighting, for feature 203)

- **Observed**: 2026-11-15, 12:54 local (10:54Z). With iteration 001 closed, `sync-boundary-state.ps1 -BoundaryType
  clarify -FeatureRef 206-bug-bash -IterationNumber 002 -AuthCommitHash e827a9af` (run after CI was green on
  `e827a9af` in all three workflows, every job run) exited 0 and wrote its bookkeeping (`.squad/decisions.md`, a
  lifecycle event, `.squad/identity/now.md`), but opened no crossing: there is no
  `.specrew/runtime/pending-verdict-stop.md`, and `start-context.json` still names `iteration-closeout` as the last
  authorized boundary with nothing pending.
- **Also written**: a decisions entry "Boundary sync warning: clarify — Expected next boundary 'feature-closeout' but
  received 'clarify'". After an iteration closeout the sync knows only the feature closeout as next; a later
  iteration's amendment has no route of its own.
- **Same as**: feature 205's DRIFT-205-INTAKE-005 (2026-11-13), where the maintainer ruled that Amendment A1 is
  approved at the plan boundary and the clarify records are committed as bookkeeping.
- **Impact**: a spec amendment for a later iteration reaches planning with no approval of its own.
- **Owner**: feature 203's follow-up; it goes into iteration 002's hand-over to 203.
- **Here (reviewer, 2026-11-15, routine ruling under the maintainer's delegation, on feature 205's precedent)**: the
  clarify bookkeeping (`.squad/decisions.md`, `.squad/events/lifecycle-events.jsonl`, `.squad/identity/now.md`) is
  committed as a `boundary(clarify)` bookkeeping commit with this entry; `.squad/active-features.yml` stays out.
  Amendment A1 is approved by the maintainer at iteration 002's plan boundary, and the plan packet says so.

## DRIFT-206-005 — the records-only push rule widened to records in general (maintainer, relayed)

- **Decision**: the maintainer's words to the reviewer, at 19:02 local on 2026-11-15, "Yes for all", answering feature
  203's question whether the records-only push rule covers records in general and not only Markdown. Relayed by the
  reviewer (specrewreviewer-98) for all three crews; a decision, not a boundary approval.
- **The rule**: when the only difference from the last commit on which the full pre-push checks were green is records,
  run markdownlint and the governance check, push, and follow CI to its end. Records are Markdown under `specs/` or
  `docs/`; the files a boundary sync writes (the `.squad` records, the sign-off gate's record and listing, `state.md`,
  the closed-iterations index and the seal); and the iteration's own record files such as `tasks-progress.yml`.
  Anything else (any script, test, workflow, configuration file, deployed copy or hash record) still gets the five
  lanes in the preflight layout. Before using it, the changed files are printed and each confirmed a record of those
  kinds; one that is not clearly so is not.
- **Unchanged**: `.squad/active-features.yml` is in no commit; the rule does not relax a review round's head or widen
  the item 13 rerun exception.

## DRIFT-206-006 — iteration 002's closeout: two arrival syncs (bug list item 69, a sighting) and one rerun of empty-result-retry

- **Recorded**: 2026-11-18, after the iteration-closeout verdict, here rather than in iteration 002's drift log,
  which the closeout seal covers (iteration 001's post-seal drift entry forced a reseal, DRIFT-206-I001-031 to -033).
- **Two arrival syncs**: the first iteration-closeout sync (23:46:14Z, at `c26f9990`) named two open items in
  `quality/hardening-gate.md`: Post-Implementation Verification pending, and Verified At not recorded. This is the
  arrival listing T036 built. The crew filled both before the verdict (`44d7c71b`) so the seal taken at capture covers
  them. One sync attempt before the push refused on `pushed-head` with no write. After the push, the sync ran again
  (23:49:28Z, at `44d7c71b`).
  - The second sync wrote a second "Boundary sync: iteration-closeout" entry in `.squad/decisions.md`, a "Boundary
    sync warning" ("Expected next boundary 'feature-closeout' but received 'iteration-closeout'") and a second
    lifecycle event. Bug list item 69, a sighting.
  - The maintainer's verdict (captured 01:07:19Z) authorized the second crossing; the boundary commit is `0f6313ed`.
- **CI**: Specrew CI run `44202679172` on `44d7c71b`, job Deterministic gate `134463069183`, failed 1 of 131. The only
  failure was `tests/continuous-co-review/unit/empty-result-retry.Tests.ps1`. It was rerun once under the standing
  exception (DRIFT-206-003), and attempt 2 succeeded. This is the second sighting that night, after `1b40bb44`
  (DRIFT-206-I002-025); bug list item 3, feature 203's to fix.
- **Class closure**: NONE — sightings of bug list items 69 and 3.

## DRIFT-206-007 — feature closeout: the closeout dashboard drawn before the verdict (bug list item 71, a sighting)

- **Recorded**: 2026-11-18, after the feature-closeout verdict (captured 09:50:21Z, crossing iteration-closeout ->
  feature-closeout, authorization commit `eca038de`).
- **What happened**: the arrival sync (01:14:05Z) drew `closeout-dashboard.md` before the verdict. The capture
  rewrote `start-context.json`, `last-start-prompt.md` and `.squad/identity/now.md` and did not redraw the dashboard.
  It was committed as drawn in the boundary commit `68cd0707`, as feature 205 did (its DRIFT-205-INTAKE-010).
- **Held records**: the maintainer's sweep answer (11:46 local) and feature 203's hand-back (items 9, 14, 27, 42, 62)
  were held until after the verdict, because the crossing was recorded against the tree. They are written in
  `closeout.md` and `follow-up-seed.md` in the commit after the boundary commit.
- **Class closure**: NONE — a sighting of bug list item 71.

## DRIFT-206-008 — the merge to main bypassed the required review (the maintainer's word, this pull request only)

- **Recorded**: 2026-11-18, after the merge, on the 206 branch only.
- **What happened**: pull request #3722 (206-bug-bash to main) was green on every check, 30 of 30, including the
  four required ones, and had no conflict. GitHub still reported it BLOCKED: main's branch protection requires one
  approving review, and the PR's author cannot give it. The crew stopped without merging and reported. The bypass was
  not in the merge go ("206 merge: open the PR, merge commit", 11:47 local).
- **The maintainer's word**: "206 merge: use --admin for PR 3722", typed in the reviewer session at 13:08 local on
  2026-11-18 and relayed by it. Scope: this one pull request and this one merge, not a standing permission for any
  other pull request or other use of `--admin`.
- **The merge**: just before merging, the crew re-checked that the head was still `62497cf9`, all 30 checks were
  green, the PR was mergeable and main was still at `d3e33550f`. It then ran `gh pr merge 3722 --merge --admin`:
  a merge commit, no squash, no rebase, the branch kept. The merge commit is `d5f4af87` (11:08:32Z), first parent
  `d3e33550f`, second parent `62497cf9`.
- **Class closure**: NONE — a recorded, maintainer-authorized exception.

## DRIFT-206-009 — CI on main after the merge: one rerun of co-review-service under the standing exception

- **Recorded**: 2026-11-18, after the merge, on the 206 branch only.
- **What happened**: Specrew CI run `44291950782` on main's merge commit `d5f4af87`, Deterministic gate job
  `134761766660`, failed 1 of 131 suites. The only failure was `tests/continuous-co-review/unit/co-review-service.Tests.ps1:129`
  ("a FAILED lease owner-handoff STOPS the spawned supervisor": a supervisor process was still alive). The Contract lane was
  skipped because it depends on the gate.
- **Rerun**: once, under the standing exception (DRIFT-206-003), with `gh run rerun 44291950782 --failed`. Attempt 2
  succeeded on all six jobs. The other workflows on main were green on their first attempt: Test `44291950961`,
  Cross-Platform Validation `44291950876` (8 of 8) and Specrew Project Sync `44291950875`. The publish workflow runs on
  tags only and did not run.
- **Class closure**: NONE — a sighting of bug list item 13 (HO-206-8), feature 203's to fix.

## DRIFT-206-010 — the records commit after the merge: two different failures, two reruns, then green

- **Recorded**: 2026-11-18, on the 206 branch only. `a847b2b0` is records-only (DRIFT-206-009). Main, at `d5f4af87`,
  was green and unaffected throughout.
- **Attempt 1**: Specrew CI run `44299443481`, Lint job `134785017100`, failed in "Setup PowerShell" with exit 100.
  apt got HTTP 429 "Too Many Requests" from packages.microsoft.com fetching the PowerShell package, before any test
  ran. Deterministic gate and Contract lane were skipped. This was outside the standing exception, so the crew stopped
  and asked.
  - The reviewer session ruled one rerun, because no test result was hidden. It did not count as a use of the
    exception, and it is a sighting beside bug list item 57 and feature 205's DRIFT-205-INTAKE-011.
- **Attempt 2**: Lint `134788980801` passed. Deterministic gate `134791308128` failed 1 of 131 suites, only
  `tests/continuous-co-review/unit/empty-result-retry.Tests.ps1`, case "does NOT retry a non-empty result"
  (expected 1 spawn, got 2). The crew stopped and asked again.
  - The reviewer session ruled the standing exception's one rerun for this head (item 3).
- **Attempt 3**: green on all six jobs: Deterministic gate `134798023244` and Contract lane `134807650505` among them.
  Test `44299443587` and Cross-Platform Validation `44299443482` were green on their first attempt.
- **Class closure**: NONE. These are sightings of bug list item 3 (the new case is recorded there with the reviewer
  session's reading) and of item 57.

## DRIFT-206-011 — the lane guard fix: a pull request off main, merged past the required review by the maintainer's word

- **Recorded**: 2026-11-18, on the 206 branch only. The fix itself is outside feature 206: it was done after the
  closeout, in its own worktree, on `fix/lane-guard-feature-pin`, as #3713 was.
- **Why**: `tests/unit/every-suite-is-named-by-a-lane.tests.ps1` ended with 206's review plan pinned. The active plan
  had to name exactly 206's six lanes, and the parked file had to equal the plan at `d3e33550`. On main that failed
  every branch taking main in with its own lanes, so 203 and 205 both stopped.
  - The maintainer's word, at 20:13 local: "main guard fix: 206 crew, small PR off main".
  - The class is recorded as an unruled candidate in `follow-up-seed.md`.
- **The commits**:
  - `21f7d388` RED: 6 of 95 fail.
  - `04f5f5b2` fix: 95 of 95 pass.
  - `f70a7918` records.
  The guard now judges the plan's shape for any feature: at least one active lane, and lane ids unique across both
  files. The suites named by lanes must still exist, and the census comparison is unchanged. Main's plan files did not
  change.
- **Pull request #3916**: 22 of 22 checks green and mergeable, but BLOCKED on the required approving review, which the
  PR's author cannot give.
  - The maintainer's word: "lane guard merge: go, use --admin for PR 3916", typed in the reviewer session at 23:25
    local on 2026-11-18 and relayed by it. It covers this one pull request and this one merge only.
  - Re-checked just before merging: head `f70a7918`, 22 of 22 green, mergeable, main at `d5f4af87`.
  - Merged with `gh pr merge 3916 --merge --admin`: merge commit `e6732b27` (21:26:18Z), parents `d5f4af87` and
    `f70a7918`. The branch was kept.
- **Class closure**: NONE — a recorded, maintainer-authorized exception, the second after DRIFT-206-008.

## DRIFT-206-012 — the proposal 166 amendment: merged past the required review by the maintainer's word

- **Recorded**: 2026-11-19, on the 206 branch only. The amendment is outside feature 206: it is documentation only, on
  `proposal/166-concurrent-hygiene-evidence` off main, in the #3720 form.
- **The work**: the maintainer's words were "OK, lets do it. And this fix gets priority now since we will work on
  multiple features concurrently" (20:14 local, 2026-11-18) and "proposal 166 amendment: open the PR" (23:25 local).
  - Amendment A1 adds the evidence from the first merge with features open side by side (205: 5 conflicting files,
    203: 8, confirmed with `git merge-tree`).
  - It also adds six surfaces Pillar 1 did not name, FR-008a (feature-aware "latest entry" readers), FR-010 (no
    repository-wide guard may assert one feature's names) and the priority.
  - Three contradictions with current practice are left as open questions for 166's design workshop.
  - `proposals/INDEX.md` changed only in 166's own row.
- **Pull request #3917**: 22 of 22 checks green and mergeable, but BLOCKED on the required approving review.
  - The maintainer's word: "proposal 166 merge: go, use --admin for PR 3917", typed in the reviewer session at 00:02
    local on 2026-11-19 and relayed by it. It covers this one pull request and this one merge only.
  - Re-checked just before merging: head `00cc646b`, 22 of 22 green, mergeable, main at `e6732b27`.
  - Merged with `gh pr merge 3917 --merge --admin`: merge commit `c35392cd` (22:03:07Z, 2026-11-18), parents
    `e6732b27` and `00cc646b`. The branch was kept.
  - Main gained exactly two files: the proposal and the index.
- **Class closure**: NONE — a recorded, maintainer-authorized exception, the third after DRIFT-206-008 and -011.

## DRIFT-206-013 — the closing CI record: one rerun on `31370299`; main green on both merges

- **Recorded**: 2026-11-19, on the 206 branch only. This is the last 206 records commit.
- **Rerun**: Specrew CI run `44401878043` on `31370299` (DRIFT-206-011's commit), Deterministic gate job
  `135149798942`, failed 1 of 131 suites. The only failure was `empty-result-retry.Tests.ps1`, case "retries once and
  recovers". It was rerun once under the standing exception. Attempt 2 was green on all six jobs (gate
  `135158138435`, Contract lane `135168262754`). Bug list item 3's table has the row.
- **Main, first attempt each**:
  - `e6732b27` (#3916): Specrew CI `44401470911` 6/6, Cross-Platform Validation `44401470714` 8/8, Test
    `44401470592`.
  - `c35392cd` (#3917): Specrew CI `44407730253` 6/6, Cross-Platform Validation `44407730214` 8/8, Test
    `44407730351`.
- **206 branch**: `d372578b` (DRIFT-206-012) was green on all three workflows on its first attempt.
- **Class closure**: NONE — a sighting of bug list item 3.

## DRIFT-206-014 — the CI squad pin: a pull request off main; the home npm cache changed during the sandbox proof, not by this crew

- **Recorded**: 2026-11-22, on the 206 branch only.
- **The decision**: the maintainer, 2026-11-22 01:50 local, relayed by the reviewer session: "CI squad pin: 206 crew,
  small PR off main". The reviewer session's name changed after a reboot, and the maintainer confirmed it in this
  session before the work began: "The reviewer session is now named specrewreviewer-4a. My delegations to
  specrewreviewer-98 apply to it unchanged, and no longer apply to specrewreviewer-98".
- **The work**: pull request #4097, branch `ci/squad-sdk-pin` off main `a78ac54c`. Not merged.
  - `d28fa4fa` pins `squad-sdk` 1.1.0 beside `squad-cli` 0.11.0 in the four workflow installs, adds a health check
    after each, and records option C in the follow-up seed as a release blocker for the next beta.
  - `4c092579`, on the reviewer session's routine ruling: Cross-Platform Validation's Ubuntu job was red on the pull
    request event (run 44978335973). It had no install step of its own: `specrew init` installed the CLI alone
    through the product's path and refused it as unhealthy. This crew's first inventory searched only for install
    lines and missed it. That job now pre-installs the pinned pair and runs the same health check before init, and
    prints a `::warning` that it no longer proves the product's own Squad install. The seed gained that as a fourth
    line, and its wording now says the released install path itself fails, not only the advice.
  - No product code changed.
- **CI on `4c092579`**: every check on the pull request green, 22 of 22.
  - Specrew CI `44980226970` (push) and `44980231405` (pull request), 6 of 6 each. The task-progress-tracking step
    passed and the Contract lane ran.
  - Cross-Platform Validation `44980231353`, 8 of 8. Ubuntu Validation's init installed only Spec Kit and completed.
  - Test `44980226905` and `44980231417`.
- **The home npm cache**: during the sandbox proof, new debug logs appeared in the real home npm cache at 04:07:49,
  04:10:53 and 04:16:00 local, and more from the same suite while the pull request's checks ran. Each records `npm view @bradygaster/squad-cli version`, run from a
  `project-path-resolution-regression` test fixture with the real user `.npmrc`. That is the suite's "specrew update
  --info" case. The reviewer session confirmed that the 203 crew ran that suite with its go, and that 203's own home
  hash was unchanged. This crew's sandbox ran only `npm install` and `npm root -g`, with cache, userconfig,
  globalconfig, prefix and home inside it. The home hook-file hash was unchanged before and after every run. The
  work paused on the first change and resumed on the reviewer's ruling.
- **Two logs rotated out**: npm keeps the last ten logs and deleted the oldest as the new ones arrived. One of them was
  the 897-byte `2026-11-19T19_57_53_765Z` log that this crew wrote and self-reported, from an `npm config get` run
  outside a sandbox. The other was `2026-11-20T01_11_19_871Z`. Both went through npm's rotation, not through any
  cleanup by a crew. Nothing was restored.
- **Class closure**: NONE. The suite's real-home `npm view` call is the 203 crew's hand-back line, per the reviewer
  session.

## DRIFT-206-015 — the 206 branch's records push `c1caf58e` is red from the squad break, left red on the reviewer's ruling

- **Recorded**: 2026-11-22, on the 206 branch only. Committed locally; pushed only with the next records commit that
  has its own reason.
- **The runs**:
  - Specrew CI `44982794986`: the Deterministic gate failed at "Integration - task progress tracking", and the Contract
    lane was skipped behind it.
  - Cross-Platform Validation `44982794973`: Ubuntu Validation failed at "Test specrew init".
  - Test `44982794974`: green. Every other job: green.
- **The cause**: the squad break, not the diff, which was one Markdown file. The 206 branch's workflows let
  `specrew init` install `squad-cli` 0.11.0 alone, which pulls `squad-sdk` 2.0.0. Both steps stop on "Squad is installed
  but the 'squad' command is not healthy (…/init.js:13)". The previous head, `ee525f16` (2026-11-18), was green on all
  three workflows.
- **The ruling**: the reviewer session (routine): left red. No rerun, since no exception covers it and it would fail
  the same way. No merge of main into this closed feature's branch. No push for this alone. The fix is pull request
  #4097 on main, which turns both failing steps green.
- **Said in advance**: the push that carries this entry will be red the same way, on the same two steps, for the
  same cause. It is not a new failure.
- **Class closure**: NONE. A known upstream break; see the follow-up seed's release-blocker section.

## DRIFT-206-016 — the CI squad pin merged to main past the required review, by the maintainer's word; main green

- **Recorded**: 2026-11-22, on the 206 branch only. Pushed together with DRIFT-206-015.
- **The decision**: the maintainer, 2026-11-22 23:18 local, relayed by the reviewer session: "CI pin merge: go, use
  --admin for PR 4097". The administrator bypass was named for this one pull request, not as a standing permission.
- **Before the merge**: pull request #4097 was open at head `4c092579`, mergeable, with 22 of 22 checks green. Its
  merge state was blocked only on the required review, which the bypass passes.
- **The merge**: `gh pr merge 4097 --merge --admin`, a merge commit, as for #3722, #3916, #3917 and #3918. Merge
  commit `551bf5cd` on main, 23:19 local. The `ci/squad-sdk-pin` branch and its worktree are kept; their removal is
  the maintainer's word.
- **Main's push CI on `551bf5cd`**: every job green.
  - Specrew CI `45071463729`, 6 of 6. The Deterministic gate and the Contract lane each passed their "Check squad CLI
    health" step.
  - Cross-Platform Validation `45071463773`, 8 of 8. Ubuntu Validation pre-installed the pinned pair, printed the
    bypass warning, passed the health step, and passed `specrew init`.
  - Test `45071463797`.
- **This push**: it carries this entry and DRIFT-206-015. The 206 branch does not take main in, so it stays red on the
  same two steps that DRIFT-206-015 names, for the same cause.
- **Class closure**: NONE. Option C stays a release blocker for the next beta, in the follow-up seed.

## DRIFT-206-017 — the proposal 142 amendment merged; two rerun-exception sightings; the Squad install fix opened; parts 2 and 3 passed to the next bug bash

- **Recorded**: 2026-11-23, on the 206 branch only.
- **Proposal 142's branch took main in**: on the reviewer session's routine ruling, `proposal/142-state-doctor-detect-and-repair`
  merged main (`551bf5cd`, the CI squad pin) as `32a9189e`. Specrew CI and Test were green on push. Cross-Platform
  Validation does not run on pushes to `proposal/**`.
- **Pull request #4098 merged past the required review, by the maintainer's word**: "proposal 142 amendment: open the
  PR, merge commit, use --admin" (2026-11-23 02:19 local, relayed). The administrator bypass was for that pull request
  only. It changed proposals only, two files. All 22 checks were green at `32a9189e` with main unmoved. It was merged
  with `gh pr merge 4098 --merge --admin`, merge commit `334e1188` on main, 02:50 local. The branch and its worktree are
  kept.
- **Main's push CI on `334e1188`**: Test `45091080045` and Cross-Platform Validation `45091080038` (8 of 8) were green.
  Specrew CI `45091080177` failed the Deterministic gate on attempt 1, with the Contract lane skipped. It was green,
  6 of 6, on attempt 2.
  - **Sighting (rerun exception)**: `reviewer-hook-suppression.Tests.ps1` case 1 failed alone, 1 of 131 in the F-198
    honesty regression suite: "the reviewer launch path passes SPECREW_REFOCUS_DISABLE=1 to the spawned reviewer child
    process". One rerun. The reviewer session accepted it.
- **The Squad install fix, pull request #4099**: "squad install fix: 206 crew, small PR off main" (02:21 local,
  relayed) and "squad install fix: include the update repair" (02:32 local, relayed). Branch `fix/squad-install-pair`
  off `551bf5cd`, head `31d3e613`.
  - Commits: `7e8fb79b` test (red 19); `47c2024b` fix; `0108ba06` test (red 8); `c1a3f624` fix; `31d3e613` records.
  - Every Squad install Specrew runs or prints now names `squad-sdk` beside the CLI, from `squad.sdk` in
    `scripts/internal/supported-versions.yml`. `specrew update` reinstalls a Squad that is installed but not working,
    and says so. Cross-Platform Validation's Ubuntu job again proves that `specrew init` installs Squad by itself.
  - The deployed copy of `validate-versions.ps1` changed, and its entry in `.specrew-extension-runtime.json` was
    refreshed in place with the value `Get-SpecrewDeployedExtensionManifest` computes. No update or deploy script was
    run.
  - The reading corrected by measurement: on a broken 0.11.0 pair, update did not report "already-current". The probe
    read Node's version (24.15.0) from the crash output, and update printed "Current 24.15.0 is beyond
    Specrew-validated max_tested 0.11.0. Use --upstream-latest to target upstream. No action taken."
  - The pull request's CI: all 22 checks green at `31d3e613`. Ubuntu Validation `45094583500` printed "no squad on
    PATH: specrew init must install it", "==> Installing missing dependency: Squad", "added 222 packages" (the pair;
    the CLI alone adds 220), and "squad CLI healthy: squad-cli 0.11.0, squad-sdk 1.1.0".
  - **Sighting (rerun exception)**: the push-event Specrew CI `45094533810` failed the Deterministic gate on attempt 1.
    `co-review-service.Tests.ps1:129` failed alone, 1 of 131 (bug list item 3, feature 203's). One rerun; attempt 2 was
    6 of 6. The reviewer session accepted it.
  - Not merged; the merge is the maintainer's word.
- **The local-run hold**: the reviewer session held local test runs from about 02:45 to 03:25 local, for the 203
  crew's review preflight. This crew's last runs before it were the update-repair sandbox measurement (ended about
  02:40) and a targeted batch (ended about 02:30). Nothing of this crew's ran during the hold.
- **Parts 2 and 3 passed to the next bug bash**: the maintainer, 2026-11-23 03:39 local, relayed: "You should auto
  pass any finding: again: pass it". It is a standing decision to pass findings to the list that holds them; it does
  not cover fixing, scope changes, merges or approvals.
  - **Item 90 (minor)**: the Squad version probe keeps only the first output line of a failed `squad --version`
    (`validate-versions.ps1:239` and `:300`). It also reads Node's version out of the crash output as Squad's, so
    `specrew update --info` on a broken pair reports Squad as 24.15.0, "ahead-of-supported".
  - **Item 91 (minor)**: `bootstrap-to-iteration` and `brownfield-conflict-handling` print SKIP and pass when the
    bootstrap exits non-zero, so a broken toolchain reads as green.
  - Numbering continues 206's list, which ends at 89; the next bug bash may renumber.
  - **Where the seed text waits**: commit `1dd59c3e` on `fix/squad-install-pair`, local only. On the reviewer
    session's ruling, it rides with the next push this crew makes to main for its own reason: a further push of #4099,
    or the next pull request off main. There is no records-only pull request for it. Until it lands, this entry is
    the record of items 90 and 91.
- **This push**: the 206 branch still does not take main in, so its CI is red on the same two steps DRIFT-206-015
  names (the Deterministic gate's task-progress step and Ubuntu Validation's "Test specrew init"), for the same cause.
- **Class closure**: NONE.

## DRIFT-206-018 — the Squad install fix merged to main past the required review, by the maintainer's word; main green after one rerun

- **Recorded**: 2026-11-23, on the 206 branch only.
- **The decision**: the maintainer, 2026-11-23 04:26 local, relayed by the reviewer session: "squad install fix merge:
  go, use --admin for PR 4099". The administrator bypass was for that pull request only.
- **Before the merge**: pull request #4099 was open at head `31d3e613`, mergeable, with all 22 checks green and main at
  `334e1188`.
- **The merge**: `gh pr merge 4099 --merge --admin`, a merge commit, at 04:26 local. Merge commit `49076072` on main.
  - The held seed commit `1dd59c3e` (items 90 and 91) was not pushed. It still waits on `fix/squad-install-pair`,
    local only, for the next change this crew sends to main (DRIFT-206-017).
  - The branch and its worktree are kept; their removal is the maintainer's word.
- **Main's push CI on `49076072`**: every job green after one rerun.
  - Cross-Platform Validation `45100272455`: 8 of 8. Ubuntu Validation proved a clean machine's `specrew init`
    installs a healthy Squad by itself: "no squad on PATH: specrew init must install it", "==> Installing missing
    dependency: Squad", "added 222 packages in 14s" (the pair; the CLI alone adds 220), "squad CLI healthy:
    squad-cli 0.11.0, squad-sdk 1.1.0".
  - Test `45100272447`: green.
  - Specrew CI `45100272504`: on attempt 1 the Deterministic gate failed; the Contract lane and the gate's later steps
    were skipped. Attempt 2 was 6 of 6. The Deterministic gate passed, including "Unit - Squad install names the
    paired SDK (init, update, printed repair)", and the Contract lane passed.
  - **Sighting (rerun exception)**: `co-review-service.Tests.ps1:129` failed alone, 1 of 131 in the F-198 honesty
    regression suite ("a FAILED lease owner-handoff STOPS the spawned supervisor ... got System.Diagnostics.Process").
    This is bug list item 3, feature 203's. One rerun; the reviewer session accepted it.
- **Tonight's rerun-exception sightings, in all**: `co-review-service.Tests.ps1:129` alone twice (4099's push run
  `45094533810`, and main on `49076072`); `reviewer-hook-suppression` case 1 alone once (main on `334e1188`). Each
  took one rerun, and each passed on it.
- **Feature 203's trial merge**, reported by the reviewer session: 203's branch merged against `49076072` without
  conflict. Git auto-merged all four files both sides changed, including `.specrew-extension-runtime.json` (174
  entries, each sha256 checked against its file in the merged tree, 0 mismatched). The 203 crew still regenerates that
  record at its final merge, as the pull request says.
- **What stays open**: items 90 and 91, passed to the next bug bash (DRIFT-206-017). The CI pin in the four workflows,
  and `squad.sdk` with it, stays until Specrew moves to a squad release whose CLI and SDK agree.
- **This push**: red on the two known steps (DRIFT-206-015), for the same cause; the 206 branch does not take main in.
- **Class closure**: NONE.
