# Bug List: 206 Bug Bash

**Feature**: 206-bug-bash
**Conduct**: bug-bash under the software-feature contract (no eight-lens workshop, as in feature 201)
**Diagnosed**: 2026-11-10, on main `d3e33550` (branch `206-bug-bash`)
**Status**: diagnosis complete for items 2 to 6 (item 3: cause not found, handed to 203); no fix written

## 1. `specrew start` with no console and stale session state loops forever

- **Root cause (known, B5F-036):** `Read-SpecrewRecoveryChoice` in `scripts/internal/session-recovery.ps1`
  runs `while ($true)` over `Read-Host`; with no console input every answer is empty, so it prints
  `WARN: Invalid recovery choice` forever.
- **Effect:** `tests/integration/project-path-resolution-regression.ps1` times out.
- **Fix shape (maintainer):** with no console input, refuse in plain words; never loop.

## 2. `validator-hardening-iteration2.ps1` fails three assertions

Two independent causes.

### 2a. Dirty canonical iteration artifacts are never detected (assertions 1 and 2)

- **Reproduced:** a closed iteration with an uncommitted edit to `plan.md` validates PASS, exit 0.
- **Root cause:** `Get-IterationDirtyCanonicalArtifacts`
  (`extensions/specrew-speckit/scripts/validate-governance.ps1:3874`) converts each `git status` path to
  backslashes and compares it with the canonical list, which `ef9c27d9` (T041 cross-platform path
  hardening, 2026-05-16) switched to forward slashes. No path can match, so the over-claim dirty-tree check
  has been inert on every platform since 2026-05-16.
- **Test note:** the assertion pattern expects backslashes in the message; the fix decides one separator for
  the message and the test follows it.

### 2b. A bookkeeping-only `copilot-instructions.md` change triggers PAUSE-AND-CONFIRM (assertion 3)

- **Reproduced in isolation (no `specrew start`):** the classifier says `bookkeeping`; after the start-time
  instruction heal runs it says `behavior`, restart required.
- **Root cause:** `specrew start` heals the coordinator section into every host's instructions file
  (`Invoke-SpecrewInstructionDeployment`, added to start by `c9c17b11`, F-184, 2026-06-17) before it
  classifies changes. `.github/copilot-instructions.md` is Copilot's instructions file, and the classifier
  compares the baseline commit with the working-tree file, which now carries the healed section. Specrew's
  own write is classified as a behavior change by the user.

## 3. `empty-result-retry.Tests.ps1` fails intermittently in the Deterministic gate (two cases, two sightings)

- **Observed (run 42715079692, attempt 1, ubuntu):** the retry's stdout was empty
  (`Expected '"run_id":"t108"' to match <empty>`), case "retries once and recovers".
- **Observed (run 42743719583, attempt 1, ubuntu; reported by the maintainer from feature 205's CI,
  confirmed in the run's log):** case "does NOT retry a non-empty result (single spawn, no retry
  telemetry)" failed at line 87 with `Expected 1, because a healthy result must not be re-run, but got 2`.
  Commit `cf01f599` on `205-workshop-lens-order` is records-only; the same code passed on `03bc4c5b` about
  40 minutes earlier. A second spawn for a non-empty result means the first attempt's output was read as
  empty: the same shape as the first sighting, now in a different case.
- **Cause: not found.** Not reproduced: the real test passed 200 of 200 cases on Linux (WSL Ubuntu 24.04,
  pinned to 2 cores, 25 runs idle and 25 under CPU load), and a standalone replay of the capture pattern
  lost no output in 300 runs on Windows.
- **Candidate, unproven:** `Invoke-ContinuousCoReviewAgentInWorktree`
  (`scripts/internal/continuous-co-review/worktree-reviewer.ps1:1598`) keeps stdout only if the
  `ReadToEndAsync` task already shows `RanToCompletion` when `WaitForExit(slice)` returns, and that wait does
  not wait for the reader to reach end-of-stream. The failure's shape (retry stdout empty) fits it, but it was
  never observed. Both sightings fit it: in each, output the fake agent wrote was read as empty (the retry's
  in the first, the first attempt's in the second). The file is in feature 203's protected area.
- **Disposition (maintainer, 2026-11-10):** no fix in 206. Hand over to feature 203 as "cause not found,
  one candidate", with the evidence above. Any recurrence is logged here with its run id.
- **Hand-over record**: HO-206-1 in `specs/206-bug-bash/iterations/001/handover-to-203.md`.

| Run id | Attempt | Date (UTC) | Commit | Runner | Outcome |
| ------ | ------- | ---------- | ------ | ------ | ------- |
| 42715079692 | 1 | 2026-11-09 | `700e6127` | ubuntu-latest | failed ("retries once and recovers"); passed on rerun (attempt 2) |
| 42743719583 | 1 | 2026-11-10 | `cf01f599` (205, records-only) | ubuntu-latest | failed ("does NOT retry a non-empty result", got 2 spawns); `03bc4c5b` passed ~40 min earlier |

## 4. The Nightly Truth-Check on main has been red since 2026-08-08

- **What fails today (replayed locally, CI mode, full repo, on `d3e33550`):** one iteration,
  `specs/198-beta2-hardening/iterations/011`: "Complete iterations require review.md overall verdict
  'accepted' (found 'needs-rework')". Identical to the 2026-11-09 CI run.
- **Root cause:** 198/011 is held at `Iteration Status: retro` with `review.md` `needs-rework` by the
  maintainer's 2026-08-06 ruling (closure waits on FR-066's mint guard). The validator requires an
  accepted review for any iteration at `retro`, so the honest state fails the rule. The message also says
  "Complete" for a `retro` iteration.
- **First cause of the streak (now known):** the last green night ran on `d95cca51`; the only commit
  between it and the first red night is `c90df33e`, the merge of PR #3090 (feature 198). Replayed at
  `c90df33e`, two iterations fail: 198/011 (as today) and 001/011 (deferred gap without a canonical defer
  entry; fixed on 2026-10-25 by `27a04a25`).
- **Why nobody saw it:** the workflow has no failure notification of any kind; 94 red nights went
  unnoticed.
- **What the needs-rework review asked for** (`specs/198-beta2-hardening/iterations/011/review.md`):
  - T092 certification of FR-066/FR-068/FR-018, not achieved in three rounds. Closure trigger:
    "iteration 011 closes when beta3 delivers FR-066's mint guard from its design spike".
  - T091 (FR-068, SC-025 composition clause), deferred to beta3's hook-machinery cluster
    (decision `f198-i011-t091-defer-sc025-beta3-vehicle`).
  - T093 (FR-018 campaign-mode halt text), deferred to beta3's first row
    (decision `f198-i011-t093-defer-relief-valve-back-registration`).
- **Whether that rework was done later: no evidence that any of the three was delivered.**
  - FR-066's mint guard entered beta3 only as a carry-ledger line ("mint-guard design spike (FR-066
    residual)", `beta3-carry-ledger.md` at `b9c5bacb`, section F). 199's spec has no requirement for it.
    Its RED-by-design specification was moved out of `tests/` by 199 on 2026-09-02 and is still at
    `tools/pending/fr066-first-boundary-arrival.pending.ps1`. Features 201 to 205 do not mention FR-066.
  - Beta3's FR-024 is a different guard: no crossing until the stage it leaves has its owed artifacts.
    FR-066 is about a project's first boundary arrival. Not run here: whether FR-024's code happens to
    satisfy FR-066 (the pending file would show it, but it exercises the boundary machinery).
  - T091 and T093: no trace in 199, 201 or 202 artifacts.
- **Already on record:** decision `f198-i011-waive-accepted-verdict-finding-release-gate` waived this exact
  finding "for the v0.40.0-beta2 release gate only", saying the red sits on the rule, not on a false field.
- **Ruling (maintainer, 2026-11-10):** mark 198/011 abandoned, review unchanged; FR-066's mint guard, T091
  and T093 become one finding owned by feature 203's follow-up, with the parked check as its test (not run).

### Triage of what the nightly reports today (proposed, not applied)

The nightly on main reports one failure and 20 warnings, nothing else (CI run 42570733031, matched by a
local full-repo CI-mode replay). The dashboard rule shipped on 2026-05-26 (`d4284c8a`); every row below
last changed on or after that day, so the rule is not retroactive for any of them.

| Iteration | Report | Status today | Proposed terminal answer |
| --------- | ------ | ------------ | ------------------------ |
| 198/011 | FAIL: review verdict | retro, needs-rework | marked abandoned (ruled) |
| 141/006, 141/007, 141/008 | WARN: no dashboard.md | complete, in closed index | fixed mechanically: render dashboard.md from its own artifacts |
| 174/006, 174/008, 174/009, 174/010, 174/011 | WARN: no dashboard.md | complete, in closed index | fixed mechanically: render |
| 182/002, 182/003, 182/004 | WARN: no dashboard.md | complete, in closed index | fixed mechanically: render |
| 197/003, 197/004, 197/005 | WARN: no dashboard.md | complete, in closed index | fixed mechanically: render |
| 198/003 | WARN: no dashboard.md | complete, in closed index | fixed mechanically: render |
| 174/007 | WARN: no dashboard.md | abandoned (superseded by 008), in closed index | frozen list: "abandoned before closeout; no dashboard was owed" |
| 197/006 | WARN: no dashboard.md | retro; state says superseded by 007 before closeout | marked abandoned |
| 048/001 | WARN: no dashboard.md | retro, review accepted, not in closed index | maintainer's call: frozen list ("reached retro with an accepted review, never formally closed") or formal closure |
| 197/001 | WARN: no dashboard.md | retro, review accepted, not in closed index | maintainer's call, as 048/001 |
| 198/008 | WARN: no dashboard.md | blocked at review-signoff (T029 merge handoff, T067 post-publication validation) | maintainer's call: abandoned, or frozen list ("blocked on release steps that happened outside the iteration") |

Two findings came out of the triage:

- **The closed-iteration test disagrees with itself.** 048/001, 197/001, 197/006 and 198/008 are not in
  `.specrew/closed-iterations.yml`, so the nightly validates them as open, yet the dashboard check calls each
  a closed iteration (a state.md text heuristic). 198/011 is the same shape and is the one that fails.
- **The nightly never re-judges most of history already**: it skips the 136 iterations in the closed index
  (`[validator-scope] closed-iteration filter`). The dashboard check is the exception, which is why all 20
  warnings are about closed iterations.

### How the validator could know when a rule shipped (FR-008, options)

Facts first:

- **Closure dates on record are mostly wrong.** 131 of the 137 entries in `.specrew/closed-iterations.yml`
  carry `closed_at: 2026-08-06T14:49:04Z`, the moment the index was rebuilt, not when each iteration closed.
  Real closure dates exist only in git (the closeout commit of each `state.md`).
- **Rules have no stable identity.** Some findings carry a category (`over-claim`,
  `missing-dashboard-auto-render-regression`); many are bare message strings added to an error list.
- **Consumer projects do not have Specrew's git history**, so anything derived from git at validation time
  works only in this repository.

Options:

| Option | How it knows the rule's date | How it knows the closure date | Cost |
| ------ | ---------------------------- | ----------------------------- | ---- |
| A. Rule registry, hand-kept | every rule gets an id and a `since` version in a registry file | closure records the Specrew version that closed it (new field) | large: inventory every rule in a ~6,000-line validator, give each an id |
| B. Git at run time | `git log -S` on the rule's text | git log of the closeout commit | small code, but works only in this repo, needs full history, breaks when a message is reworded |
| C. Registry generated at release | the release diffs rule ids against the previous release and stamps new ones | as A | as A for the ids, then low upkeep |
| D. Closure freezes judgement | no per-rule dates; a closed iteration is judged only by rules marked retroactive, plus the validation it passed at closure | closure stamp written at closeout from now on; history covered by the frozen list | small: mostly how the closed filter already behaves; only the few checks that look at closed iterations (today: the dashboard check) need a `since` |

Recommendation: D in this feature; A or C as its own item only if per-rule dates are wanted later.

## 5. Tests registered in no CI step and no verification lane

- **Inventory (520 candidate files under `tests/`, fixtures and support helpers excluded):**
  - 152 suites are in no per-push CI step and no lane, but all 152 are named in
    `.specrew/release-gate-suites.txt` and run in the release full sweep. Deliberate release cadence.
  - **35 integration scripts run nowhere:** no CI step, no lane, no release manifest, and invisible to the
    release full sweep, because the sweep and the lane guard
    (`tests/unit/every-suite-is-named-by-a-lane.tests.ps1`) both count only files named `*test.ps1` or
    `*tests.ps1`. Both B5F-036 suites are among them.
  - `tests/integration/_ctl-spec.ps1` is an empty 0-byte file committed by `2a5c042b`; to be deleted.
  - 4 manual or host-probe scripts are out of scope by design.
- **Root cause:** the suite definition is the file name, and script-style suites written before the
  `*.tests.ps1` convention were never renamed or listed. The guard that exists to catch an unregistered
  suite shares the same blind spot.

## 6. Smaller, already filed

### 6a. The quality resolver suggests node/react presets for this repository

- **Root cause:** a stray `package.json` at the repository root declaring `react`, `express` and `pg`,
  added inside a broad commit (`8666bad1`, "Tighten quality roadmap specs", 2026-05-07). Nothing in the
  product uses it. `resolve-quality-profile.ps1` scores presets from that file plus words in the spec:
  20 for `package.json`, 25 to 35 for each dependency, 25 for words such as "api", "browser", "component"
  or "database". Any spec using those words crosses the threshold.
- **Reproduced:** with feature 201's spec the resolver selects `node-rest-with-postgres@v1.0.0`.
- **Dependent test:** `tests/integration/f049-i003-intake-engine-tests.ps1:126` asserts that this repository
  detects as `nodejs` ("stack detection falls back to repository package.json"), pinning the stray file.
  Removing the file needs that test moved to a fixture.

### 6b. `.squad/active-features.yml` records the Windows user and machine name (B5F-022)

- **Root cause:** `Get-SpecrewCoarseIdentity` (`scripts/internal/feature-claims.ps1:30`, `85f524bd`,
  2026-05-31, F-051 FR-043) writes `claimed_by` as `[Environment]::UserName@[Environment]::MachineName`.
  The file is committed by design ("claims ARE committed - this is the cross-machine coordination
  surface"), and is not git-ignored.
- **Writers:** `specrew start` and the boundary sync (`sync-boundary-state.ps1`, `shared-governance.ps1`)
  through `feature-claims.ps1`. `claimed_by` is compared for equality to find claims held by someone else,
  so any replacement needs a stable token, not a blank.
- **Constraint:** feature 203's FR-033 changes how claims leave this file at merge (B5F-022).
- Not committed here until decided.

## 7. The Windows review-runtime job hung past its timeout and left no log

- **Observed:** Cross-Platform Validation run 42913380735 on `435332da`, job "Deterministic fake-provider review
  runtime (windows-latest) — never live support evidence", step "Run bounded deterministic review fault and
  conformance suites". The job started 2026-11-10T22:18:51Z and was cancelled at 22:48:51Z: 30 minutes, against
  5 minutes for the same job on `7f9cf310` (run 42740875424). The job's own limit is `timeout-minutes: 25`.
- **The step is called "bounded" and was not:** it has no `timeout-minutes` of its own, so only the job limit
  stopped it, and a cancelled job keeps no log. GitHub returned `BlobNotFound` for the job's log, so where it
  stopped is unknown.
- **Not caused by the commit:** `435332da` changed only Markdown files and `.specrew/iteration-config.yml`.
- **Cause: not found.** The step runs the continuous co-review suites (`tests/continuous-co-review/**`), feature
  203's area.
- **Disposition (maintainer, 2026-11-11):** no fix in the review-runtime tests. Handed over to feature 203 with
  item 3 (FR-004), as its own item. Candidate for this feature: give the step its own `timeout-minutes`, shorter
  than the job's, so a hang fails with its log kept. `.github/workflows/cross-platform-validation.yml` is not in
  203's protected paths and 203's branch does not change it, so the candidate is on iteration 002's list (T019).
- **Hand-over record**: HO-206-2 in `specs/206-bug-bash/iterations/001/handover-to-203.md`.

| Run id | Date (UTC) | Commit | Runner | Outcome |
| ------ | ---------- | ------ | ------ | ------- |
| 42913380735 | 2026-11-10 | `435332da` | windows-latest | cancelled after 30 min in the bounded step; no log kept |

## 8. Two suites run `specrew-update.ps1` with no home redirect and rewrite the real home's hook files

- **Reported by the maintainer (2026-11-11), from feature 205:** its review preflight ran the lanes in
  `.specrew/verification-plan.json` (202's and 199's suites), and one of them rewrote four real-home hook files
  with main's layout.
- **The two suites:**
  - `tests/integration/deployed-extension-marker-on-update.tests.ps1:64` runs
    `pwsh -NoProfile -File scripts/specrew-update.ps1 -ProjectPath $root` on a temp project.
  - `tests/integration/receipt-outcomes-retired.tests.ps1:28` does the same.
  - Neither sets `HOME` or `USERPROFILE` (checked by reading, 2026-11-11), so the update's hook deployment
    writes the real home folder. Both are named in `.specrew/verification-plan.json`'s lanes; neither is in a
    CI workflow.
- **Not run on this machine** (maintainer's instruction). No fix in 206 unless the maintainer rules one.
- **Hand-over record**: HO-206-5 in `specs/206-bug-bash/iterations/001/handover-to-203.md`, with feature 205's H-001
  and feature 203's B5F-039.
- **Same shape, not yet read:** 11 more test scripts mention `specrew-update.ps1` (a mention is not proof of a
  call): `tests/continuous-co-review/unit/verification-plan-materializer.Tests.ps1`, and under
  `tests/integration/`: `distribution-module-update.ps1`, `forge-neutralization-sweep.tests.ps1`,
  `project-path-resolution-regression.ps1`, `psgallery-check.tests.ps1`, `refocus-deploy.tests.ps1`,
  `slash-command-compatibility.tests.ps1`, `slash-command-distribution.tests.ps1`, `update-command.ps1`; and under
  `tests/unit/`: `consumer-applicability-firewall.tests.ps1`, `extension-deploy-refocus-digests.tests.ps1`.
