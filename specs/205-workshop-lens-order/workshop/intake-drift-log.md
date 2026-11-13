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
