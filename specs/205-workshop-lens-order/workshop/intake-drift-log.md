# Intake drift record: 205-workshop-lens-order

## DRIFT-205-INTAKE-001 — co-review retry test failed once in the Deterministic gate on a docs-only commit

**Observed**: 2026-11-09 (local 2026-11-10 00:55), Specrew CI run 42715079692, attempt 1, on commit `700e6127`.

**Evidence**:

- In the Deterministic gate job, the "F-198 honesty regression suite (NFR-007)" step failed 1 of 131 files: `tests/continuous-co-review/unit/empty-result-retry.Tests.ps1`, case "retries once and recovers when the second attempt produces the result". The exact assertion was: `Expected regular expression '"run_id":"t108"' to match <empty>, because the retry recovered the result, but it did not match.`
- The Contract lane was skipped as a consequence.
- `700e6127` changed only `specs/205-workshop-lens-order/` documents and four `.squad` state files written by the specify sync. No script or test changed.
- The same suite passed in Specrew CI run 42713878979 on `7a4e6d7a`, about an hour earlier.

**Impact**: a red gate on a commit that cannot have caused it. Clarify was held until the maintainer decided.

**Disposition**: the maintainer approved one rerun of the failed jobs, with no further reruns if it fails the same way. Rerun result: attempt 2 of run 42715079692 concluded **success**. Deterministic gate, Lint, Self-leak firewall and Contract lane all passed, and no job was skipped. A single failure that passes on rerun with an unchanged tree points to an intermittent test, which this record does not prove.

**Not this feature's to fix.** The test belongs to the continuous co-review engine. The finding is a candidate for `docs/beta5-findings.md`, filed under the next free B5F id after feature 203 merges, since 203's branch owns ids B5F-016 to B5F-036 and editing that register here would collide with it.

## DRIFT-205-INTAKE-002 — specify-sync claim with user@machine was committed and pushed

**Observed**: 2026-11-10. Commit `700e6127` (pushed to origin `205-workshop-lens-order`, public repo) includes `.squad/active-features.yml`. The specify sync added a 205 claim with `claimed_by: "alon@ALONBLADE"`, which is the B5F-022 shape. main already carries ten claims in that form.

**Disposition (maintainer, option 1)**: `700e6127` is left as it is. `.squad/active-features.yml` is not committed again on this branch. If a boundary step refuses to run while that file is uncommitted, the crew stops and asks, and does not commit the file to get past the step. The identity fix belongs to B5F-022 (the 203/204 line).

## DRIFT-205-INTAKE-003 — B5F-005 recurred: a stale working directory produced a wrong-cause refusal

**Observed**: 2026-11-10, while closing the code-implementation lens. `confirm-workshop-lens.ps1 -ProjectRoot .` was invoked while the process working directory was `specs/205-workshop-lens-order` (the PowerShell location had been reset to the root, but the .NET current directory had not). It refused with "This feature has no recorded workshop plan yet ... confirm its agenda first", although the agenda was confirmed. Retrying once with an absolute `-ProjectRoot` closed the lens. This is the same shape as B5F-005 (already recorded on main). No new finding, recurrence evidence only.

## DRIFT-205-INTAKE-004 — iteration 002's workshop answers were given by the reviewer session, under the maintainer's delegation

**Observed**: 2026-11-13. The maintainer typed in the crew session that the reviewer session (`specrewreviewer-84`)
answers iteration 002's workshop questions on their behalf, and that every boundary approval stays theirs, typed in the
crew session.

**Evidence**:

- The crew asked two workshop questions (the shape of the fix, and which of four rules apply) after the research page
  the maintainer asked for.
- The reviewer first sent a hold: "This is not a workshop answer. Hold both pending questions; record nothing as
  answered." Nothing was recorded during the hold.
- The reviewer then sent the answers: option 4, and rules 1 to 4 with scope. It reports that the maintainer discussed
  and agreed them at about 01:20 local on 2026-11-13.
- No answer was typed by the maintainer in the crew session. The workshop hook logged no receipt for the hold or the
  answers (last receipt 2026-11-10), so no reviewer message is recorded as a typed human reply (the B5F-064 risk did not
  occur here).

**Disposition**: the answers are recorded in `workshop/iteration-002-problem-space.md` as the reviewer's, given under
the maintainer's delegation. This record and the drift log are where that provenance lives. Iteration 002 has no
`plan.md` yet, so its records are kept in the feature-level `workshop/` folder rather than an iteration folder.

## DRIFT-205-INTAKE-005 — after a closed iteration, the clarify sync opens no approval point (finding for feature 203)

**Observed**: 2026-11-13. With iteration 001 closed (last authorized boundary `iteration-closeout`), the clarify sync
for Amendment A1 (`sync-boundary-state.ps1 -BoundaryType clarify -IterationNumber 002 -AuthCommitHash 881bc45b`) exited
0 and wrote its boundary records (decisions, lifecycle event, identity), but opened no crossing:
`pending_verdict_has_pending: false`, and `start-context.json` still names `iteration-closeout` as the last authorized
boundary.

**Impact**: a spec amendment for a later iteration reaches planning with no approval of its own.

**Disposition (maintainer, 2026-11-13)**: Amendment A1 is approved at the plan boundary; the plan packet carries A1,
the sizes, the split if needed, and the three length numbers. The clarify records are committed as bookkeeping. Nothing
is built before the plan verdict. Recorded for feature 203 as a finding; it goes into iteration 002's hand-over to 203
when that iteration's folder is created with its plan.

**Also for the 203 hand-over (records only)**: the reviewer's prompt calls the workshop records binding
(`worktree-reviewer.ps1:1139`), but `workshop/` is not among the files it is given (`review-design-context.ps1:104-133`).

## DRIFT-205-INTAKE-006 — the agenda grouping (iteration 002's DRIFT-014) joins iteration 003 as FR-032 (Amendment A2)

**Decided**: 2026-11-15, by the maintainer, relayed by the reviewer session under the wider delegation. The question
was whether the clarify amendment for iteration 003 adds DRIFT-014's agenda grouping as a new requirement or leaves
iteration 003 at FR-030 and FR-031. Their words, to the reviewer, at 11:18 local: "205: yes, lets do it, the 3 part
agenda". The reviewer held the relay until feature 203's stop had finished.

**Design**: the one agreed at DRIFT-014 (the maintainer, 19:48 local on 2026-11-14: "Agree with your recomandation of
3 parts, color per part."): the selected lenses under three headings from index.yml's `space` tag (problem, both,
solution), each heading with its text label and one coloured marker, the lens-open heading repeating its group's
marker, skipped lenses in their own list, and colour never carrying the meaning alone.

**Effect**: spec.md gains FR-032 and its Clarifications session; TG-001 and TG-003 list it in iteration 003. TG-003 is
also corrected to show FR-031 in iteration 003 (the approved iteration 002 plan moved it there), and the line under
Requirements now points the two-pass split at iteration 004. As with Amendment A1 (DRIFT-205-INTAKE-005), the
amendment is approved at the plan boundary; nothing is built before the plan verdict.

**Sizing and risks carried into the plan**: about 2 SP. The marker is a non-ASCII character, so the renderer must write
UTF-8. The change reaches the deployed copies of the skill and the agenda script, and the extension's hash record. The
conformance provider detects the agenda by its `Selected lenses:` line (`specrew-conformance-provider.ps1`, which
205 does not edit), so FR-032 keeps that line; if `conformance-detection.tests.ps1` still pins the old format, that
becomes a hand-over to 203.

**FR-032's wording accepted**: the crew session asked whether FR-032 is right as written, including its two
choices (a heading with no lenses is left out; each lens's opening heading repeats its group's marker). The reviewer
recommended accepting it as written. The maintainer's words, to the reviewer, at 13:27 local on 2026-11-15, answering
that and one decision on feature 203 together: "OK for both". FR-032 stands as written; the marker characters are
chosen in the plan, with how they render in a Claude Code terminal and the fallback.

## DRIFT-205-INTAKE-007 — the standing rerun exception also covers empty-result-retry.Tests.ps1, until feature 203 merges

**Decided**: 2026-11-15, by the maintainer, relayed by the reviewer session under the wider delegation. The reviewer put
it to them as: the standing rerun exception also covers `tests/continuous-co-review/unit/empty-result-retry.Tests.ps1`,
on the same terms as `co-review-service.Tests.ps1:129`, until feature 203 merges, and recommended yes. Their words, at
11:31 local, to that recommendation and the one for feature 206's scope together: "OK, agree, do it".

**Rule**: when Specrew CI fails only in that test, on a push that could not have caused it, the failed job is rerun
once without asking. Each use is recorded as a sighting with the run and job and added to the hand-over to 203. A
second failure stops the work. It does not cover HookRenderDedupe, the Windows Pester install or anything else; those
still go to the reviewer session.

**Background**: the test's failure on `b15c5dd1` (iteration 002, DRIFT-020) was one of three different CI failures
outside 205's pushes in one night; it needed a ruled rerun then.

## DRIFT-205-INTAKE-008 — the feature closes at iteration 003; iteration 004's scope becomes a follow-up feature (Amendment A4)

**Decided**: 2026-11-16, by the maintainer, relayed by the reviewer session under the wider delegation. Their words,
typed to the reviewer at 20:56 local: "OK for both". They were answering the reviewer's list of open answers. For 205
the list read "205: close now, 004 as follow-up" (recommended) or "205: wait for 203", and "both" covers the two
crews. The option as the reviewer showed it:

- "205 closes as a feature with iterations 001 to 003 and merges after 206. Your order 206, 205, 203 holds."
- "Iteration 004's scope becomes a follow-up feature after 203 is on main, the same shape you chose for 203 this
  morning."
- "The work is records only: a spec amendment, the corrected lines, proposal 220 marked as partly shipped, then the
  feature-closeout stop."
- "One caution with closing now: the merge into main still needs your separate go for each feature, and 206 must land
  first."

This is a scope decision. It is not a boundary approval and not a go to merge.

**Background**: the spec had iteration 004 (the two-pass split, the back-check, the amendment flow, the sweeps) waiting
for feature 203 to merge (spec.md, Iterations and TG-003; plan.md, Explicit Phase 2+ Deferrals and the iteration 002
plan). The maintainer's stated merge order, 206 then 205 then 203, could not hold while 205 waited for 203. The crew
reported the facts to the reviewer session: only the amendment flow needs 203's code (the typed receipts in
`workshop-authority-store.ps1`), two carried items sit in 203's protected review-engine folder, and the rest is only
scheduled after 203.

**Resolution (records only; the sealed iteration folders are not touched)**:

- spec.md: the Amendment A4 session under Clarifications, plus amendment lines under the Iterations summary, TG-003 and
  the Assumptions line. The earlier rulings' wording is kept.
- plan.md: amendment lines under Explicit Phase 2+ Deferrals and the iteration 002 plan's "Iterations after this one".
- Proposal 220: `status: partially-shipped` (a value the governance validator accepts), `shipped-as` naming
  iterations 1 to 3, and a status-history line in FR-031's form.
- `proposals/INDEX.md`: a Shipped row for iterations 1 to 3, the Draft row narrowed to the remaining scope, and the
  summary line corrected.
- `follow-up-seed.md`: the follow-up's scope, its one dependency on 203, the shared merge surface, the carried items,
  and the practice notes iteration 004 would have carried.
- The decision ledger, `.squad/decisions.md`: a ruling entry.

## DRIFT-205-INTAKE-009 — iteration 003's closeout: no dashboard drawn, and a HookRenderDedupe I3a rerun

**Observed**: 2026-11-16, at iteration 003's closeout (boundary commit `cec8ee06`). Recorded here because iteration
003's folder is sealed and the feature has no iteration 004.

- **No dashboard.md**: the closeout sync drew no dashboard for iteration 003; in iteration 002 it drew one. Governance
  now warns: "WARN [dashboard] missing-dashboard-auto-render-regression: Specrew-managed closed iteration is missing
  dashboard.md; auto-render regression suspected: closed iteration '205-workshop-lens-order 003'." It is a warning, not
  a failure. It is item 41 on feature 206's bug list, fixed there as T035 (the closeout tail redraws the dashboard
  after the mirrors and before the seal), and it reaches this branch when main is merged in after 206 lands. Drawing it
  now would change a sealed folder, which is the maintainer's decision (iteration 002's DRIFT-027). The reviewer
  session's recommendation is to leave it; the dashboard is not drawn and the folder is not resealed.
- **HookRenderDedupe I3a**: Specrew CI run 43919881259, attempt 1, failed only in the Deterministic gate, job
  133486978295: "I3a: two concurrent missing-id fires BOTH render (per-launch fallback keys, never shared
  suppression) (expected '2', got '1')". The Contract lane was skipped as a result. The push touched no hook code. It
  was rerun once under the standing exception, and attempt 2 was green on every job: Deterministic gate 133499337002,
  Self-leak firewall 133499339212, Lint 133499404531, Contract lane 133509366042. Test 43919881344 and Cross-Platform
  Validation 43919881310 were green on their first attempt. The reviewer session passed the log to the 203 crew, who
  found that I3a is not the journal defect fixed that day; its rerun rule stays.

**Class closure**: NONE. The dashboard belongs to feature 206 (T035) and the test belongs to feature 203; 205 changes
neither.

## DRIFT-205-INTAKE-010 — the feature-closeout dashboard is drawn before the verdict and committed as drawn

**Observed**: 2026-11-16. The feature-closeout sync at `7f841071` drew `closeout-dashboard.md` before the maintainer's
verdict. It reads: "AWAITING YOUR VERDICT: crossing 'crossing-2aab4e2f…' (iteration-closeout -> feature-closeout) at
commit 7f841071…, Git tree 88ed1bf8…, is NOT human-authorized (last authorized: iteration-closeout)", followed by
"Pending next boundary: feature-closeout". Its own notice says: "Historical snapshot captured during feature closeout.
Re-running the dashboard later produces a new live view and must not overwrite this file."

**Precedent**: feature 202's committed closeout dashboard (boundary commit `4ad15d63`) reads the same.

**Decided**: the reviewer session ruled (a): commit it as drawn in the boundary commit (`a1adade3`), and say so in the
packet; the packet did. Overwriting a snapshot whose notice forbids it would be the maintainer's decision, and nobody
asked them for it. The maintainer typed "approved for feature-closeout" on that packet.

**Bug-list candidate** (passed to feature 206's crew through the reviewer session): the feature-closeout dashboard is
drawn before the verdict and is committed reading "awaiting your verdict". The iteration-closeout case is 206's item 41.

**Class closure**: NONE. The ordering belongs to the lifecycle engine (feature 206's area). 205 changes nothing there.

## DRIFT-205-INTAKE-011 — the closeout push's Ubuntu job failed installing PowerShell; one ruled rerun

**Observed**: 2026-11-16, CI on `8ebfef8f` (the feature-closeout records push).

- Cross-Platform Validation run 43954284857 failed in job "Ubuntu Validation" (133604592995), at step "Setup
  PowerShell". The log lists "Package libicu72 is not installed." through "Package libicu52 is not installed.", then
  "dpkg: error processing package powershell (--install): dependency problems - leaving unconfigured", "Errors were
  encountered while processing: powershell", and "##[error]Process completed with exit code 1."
- No check of the change ran in that job. The other seven Cross-Platform jobs, Specrew CI 43954284899 and Test
  43954284922 were green. The push changed records only.

**Decided**: the reviewer session's ruling, for this push only and not a standing exception: one rerun of the failed
job. If "Setup PowerShell" fails again, or anything else is red, the work stops, with no second rerun.

**Attempt 2** (the ruled rerun) failed the same way: job "Ubuntu Validation" (133624011633), step "Setup PowerShell",
"powershell depends on libicu72 | libicu71 | … | libicu52; however: Package libicu72 is not installed. …", then
"dpkg: error processing package powershell (--install)". The work stopped there, with no second rerun. Feature 206's
Cross-Platform run 43956458711 on `7b54d49d` (21:05Z) fails at the same job and step. The last green Ubuntu runs were
205's `7f841071` (19:26Z) and 203's `5f82692e` (17:34Z). The reviewer session found that 206's failing attempt ran on
the `ubuntu-26.04` runner image (20261111.196.1): `ubuntu-latest` is moving to 26.04, and the pinned PowerShell 7.4.1
package cannot install there. It is a rollout, not a flake, and it hits every branch and main. The fix is being written
on feature 203, in `cross-platform-validation.yml` (its T015).

**Closing state of the feature**: Specrew CI and Test are green on `8ebfef8f`. Cross-Platform Validation is red on one
job, which cannot install PowerShell on the new runner image. No test of 205's change is affected. The feature closed
on the maintainer's verdict, and that stands. This entry stays uncommitted until the commit that brings the workflow
fix to this branch: either a cherry-pick of 203's fix, or main merged in after 206 lands. The maintainer chooses which.

**Fix taken (2026-11-17)**: the maintainer, relayed by the reviewer session under the wider delegation. Their words, at
10:21 local: "CI fix: cherry-pick to 205". They were answering the option "CI fix: cherry-pick to 205 (recommended), so
the closed feature's branch goes green too", after the reviewer told them the fix was proven on feature 203 (Ubuntu
Validation green on ubuntu-26.04 with `f2493ccc1`) and on feature 206 (cherry-picked as `00cef4d5`, all three
workflows green on `ff6fe55e`). This is not a boundary approval and not a go to merge.

- `0050aacc` is a cherry-pick of `f2493ccc1` from `origin/203-beta5-stabilization`, taken as the commit and not as a
  patch file. It changes `.github/workflows/cross-platform-validation.yml` only: the three Ubuntu "Setup PowerShell"
  steps use the runner's pwsh when present, and otherwise install it from Microsoft's package feed. It applied
  cleanly, and its 38 changed lines are identical to `f2493ccc1`'s.
- Checks before the push, by the reviewer's ruling for this workflow-only push after the feature's closeout (no full
  lanes):
  - the CI-wiring case of `review-cross-platform-fault-matrix.Tests.ps1` (1 passed);
  - `github-actions-node-runtime-pins.tests.ps1` and `forge-neutralization-sweep.tests.ps1`, the two tests that scan
    the workflow folder;
  - markdownlint;
  - the governance check, which failed only on the standing derived-block item.

  The home hook files showed 0 differences.
- CI on `0050aacc` was green on all three workflows: Specrew CI 44046637244, Test 44046637280 and Cross-Platform
  Validation 44046637250. Ubuntu Validation (job 133913839392) ran on "Image: ubuntu-26.04", "Version:
  20261111.196.1", and logged "Using the runner's PowerShell: /usr/bin/pwsh" and "PowerShell 7.6.10".**Bug-list candidate** (for feature 206's list, through the reviewer session): the Ubuntu validation job installs
PowerShell with dpkg on every run. It fails when the runner image's libicu version is not one the package accepts,
and it has no retry, no pinned image and no fallback install.

**Also recorded**: after the feature-closeout verdict was captured, the maintainer typed `approved for
feature-closeout` a second time. The hook recorded nothing, because no crossing was pending. The engine behaved
correctly: a typed phrase is refused when nothing is waiting for it.

**Class closure**: NONE. The CI workflow's install step belongs to the repository's CI (feature 206's list), not to 205.
