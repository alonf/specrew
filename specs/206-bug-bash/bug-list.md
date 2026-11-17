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

## 3. `empty-result-retry.Tests.ps1` fails intermittently in the Deterministic gate (two cases, four sightings)

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
| 43360279109 | 1 | 2026-11-13 | `c2f2c67d` (203's branch) | ubuntu-latest | failed ("retries once and recovers", line 29); site 12 in 203's B5F-051, relayed by the reviewer session |
| 43527717688 | 1 | 2026-11-14 | `995851d2` (206) | ubuntu-latest | failed ("retries once and recovers", line 29, the only failure; job 132239118551); rerun once by the reviewer's ruling under the maintainer's delegation, attempt 2 green (job 132243798920) |

- **Four sightings across two branches (2026-11-14).** The standing rerun exception covers item 13 only, so this
  recurrence stopped 206's work until the reviewer ruled a single rerun. The reviewer is asking the maintainer
  whether the exception should cover this case too.

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

## 8. Three suites run `specrew-update.ps1` with no home redirect and rewrite the real home's hook files

- **Reported by the maintainer (2026-11-11), from feature 205:** its review preflight ran the lanes in
  `.specrew/verification-plan.json` (202's and 199's suites), and one of them rewrote four real-home hook files
  with main's layout.
- **The two suites:**
  - `tests/integration/deployed-extension-marker-on-update.tests.ps1:64` runs
    `pwsh -NoProfile -File scripts/specrew-update.ps1 -ProjectPath $root` on a temp project.
  - `tests/integration/receipt-outcomes-retired.tests.ps1:28` does the same.
  - `tests/integration/distribution-module-update.ps1:213-216` runs `scripts/specrew-update.ps1` through
    `Invoke-ModuleScript` and sets no home redirect (added by the maintainer 2026-11-11; confirmed by reading).
  - Neither sets `HOME` or `USERPROFILE` (checked by reading, 2026-11-11), so the update's hook deployment
    writes the real home folder. Both are named in `.specrew/verification-plan.json`'s lanes; neither is in a
    CI workflow.
- **Not run on this machine** (maintainer's instruction). No fix in 206 unless the maintainer rules one.
- **Hand-over record**: HO-206-5 in `specs/206-bug-bash/iterations/001/handover-to-203.md`, with feature 205's H-001
  and feature 203's B5F-039.
- **Feature 203's census (2026-11-11, on 203's code) found 16 test files that can write the home hook files.**
  None is run from this worktree:
  - `tests/integration/bootstrap-asset-blocker-recovery.ps1`
  - `tests/integration/bootstrap-to-iteration.ps1`
  - `tests/integration/brownfield-conflict-handling.ps1`
  - `tests/integration/deployed-extension-marker-on-update.tests.ps1`
  - `tests/integration/distribution-module-update.ps1`
  - `tests/integration/psgallery-check.tests.ps1`
  - `tests/integration/receipt-outcomes-retired.tests.ps1`
  - `tests/integration/start-command-non-interactive-first-run.tests.ps1`
  - `tests/integration/start-command.ps1`
  - `tests/integration/start-recovery-flow.tests.ps1`
  - `tests/integration/task-progress-tracking.tests.ps1`
  - `tests/integration/team-management.ps1`
  - `tests/integration/update-command.ps1`
  - `tests/integration/validate-baseline-team.ps1`
  - `tests/integration/version-checks.tests.ps1`
  - `tests/manual/copilot-squad-smoke.ps1`

  Anything else that reaches `specrew init`, `start`, `update` or the hook deployer is run only after it has been
  read and the path it takes confirmed unable to write hook files.
- **Same shape, not yet read:** 10 more test scripts mention `specrew-update.ps1` (a mention is not proof of a
  call): `tests/continuous-co-review/unit/verification-plan-materializer.Tests.ps1`, and under
  `tests/integration/`: `forge-neutralization-sweep.tests.ps1`,
  `project-path-resolution-regression.ps1`, `psgallery-check.tests.ps1`, `refocus-deploy.tests.ps1`,
  `slash-command-compatibility.tests.ps1`, `slash-command-distribution.tests.ps1`, `update-command.ps1`; and under
  `tests/unit/`: `consumer-applicability-firewall.tests.ps1`, `extension-deploy-refocus-digests.tests.ps1`.

## 9. The macOS review-runtime job failed one fault-matrix case: process-group membership probe

- **Observed:** Cross-Platform Validation run 42994018357 on `a9ad8aa0` (206's T002-T005 push), job
  "Deterministic fake-provider review runtime (macos-latest)" (job 130433482347, 2026-11-11T09:18:11Z to
  09:21:43Z), step "Run bounded deterministic review fault and conformance suites". Case "rejects prose-wrapped
  output from the codex fake process through strict ingress with no hidden retry" in
  `tests/continuous-co-review/integration/review-cross-platform-fault-matrix.Tests.ps1` failed with
  `Expected $true, because macos-process-group-unavailable:macos-process-group-probe-membership-failed, but got
  $false`; 12 of 13 passed.
- **Where it is thrown:** `scripts/internal/continuous-co-review/review-macos-runtime-port.ps1:116`, when
  `Wait-ReviewMacProcessGroupMembership` does not see the probe join its process group. Feature 203's area.
- **Not caused by the commit, as far as reading shows:** the suite loads
  `scripts/internal/continuous-co-review/_load.ps1`, which loads none of the files 206 changed, and nothing under
  `continuous-co-review` changed in the push. The same job passed on `b31ec257` (run 42990069953) 30 minutes
  earlier.
- **Cause: not found.** No rerun (maintainer, 2026-11-11). If the same test fails again on 206's next push, the
  work stops and it is reported before continuing.
- **Hand-over record**: HO-206-6 in `specs/206-bug-bash/iterations/001/handover-to-203.md`.

| Run id | Date (UTC) | Commit | Runner | Outcome |
| ------ | ---------- | ------ | ------ | ------- |
| 42994018357 | 2026-11-11 | `a9ad8aa0` | macos-latest | failed 1 of 13 (process-group probe); not rerun |

## 10. A deployed file changed without its hash, and no CI job runs the suite that would have caught it

- **Observed:** T002's fix commit `6acb84aa` edited the `.specify` mirror of `validate-governance.ps1` and left
  its entry in `.specify/extensions/specrew-speckit/.specrew-extension-runtime.json` at the old value. The
  validator's deployed-machinery integrity check (`Test-DeployedExtensionIntegrity`) then fails every iteration
  with a review.md that it validates. `tests/integration/validate-governance-changed-only.tests.ps1` failed 3
  assertions on it ("... should pass when only the touched iteration remains in scope", the auto-scoped and the
  missing-origin/HEAD variants), all with this error. Drift entry DRIFT-206-I001-004.
- **Why nothing caught it:** the check runs only while an iteration with a review.md is validated, and 206's
  iteration has none, so 206's own validator runs stayed green. The suite that fails is named only in
  `.specrew/release-gate-suites.txt` and the release full sweep; no workflow under `.github/workflows/` runs it,
  so Specrew CI, Test and Cross-Platform Validation were green on the pushes after T002.
- **Hash values** (computed the way the check does: `Get-SpecrewDeployedExtensionManifest`, CR-stripped text,
  SHA-256; the method reproduces the recorded value for every file nobody changed):

  | Commit | File | Old | New |
  | ------ | ---- | --- | --- |
  | `52662ebc` (T002) | `scripts/validate-governance.ps1` | `7cee2741ed356d8e0071ed6f585a5aaec5479d8da6a5f2d7bb364fc7a5f0e3bc` | `a7076e719445a36af61b064d434954729b4b0f4178178fb369e9fc1303a4518f` |
  | T006 fix | `scripts/shared-governance.ps1` | `34ae4e744303151e38d8eb866bf9be4dfe8f3d2422e90c70fe8482a3f8ea2097` | `93d347461ff6dcbc40457328807e13fec63225234987aa5c41a0be03141870c6` |
  | T006 fix | `scripts/validate-governance.ps1` | `a7076e719445a36af61b064d434954729b4b0f4178178fb369e9fc1303a4518f` | `e7271d700321839fb7582b94c96733c39ee897d088053cffafa4af39e91bad28` |

- **Working rule (maintainer, 2026-11-11):** any commit that touches a file under
  `.specify/extensions/specrew-speckit/` refreshes the hash file in the same commit.
- **Proposed placement (no workflow changed yet):**
  1. A fast guard in Specrew CI's Deterministic gate: one step that dot-sources `shared-governance.ps1` and fails
     when `Test-SpecrewDeployedExtensionIntegrity -ProjectRoot .` reports any drifted or missing file. It takes
     under a second and catches this class on every push, whatever iteration is touched.
  2. `validate-governance-changed-only.tests.ps1` itself in the Nightly Truth-Check (about 15 minutes on Windows
     here, too long for every push), so the scoping behaviour it covers is exercised daily, not only at release.

## 11. `feature-018-render-budget.ps1` sits on its 1.5-second budget on this machine, with or without T006

- **Observed (2026-11-11, Windows, this worktree):** the suite times one dashboard render, the second call in a
  fresh `pwsh` process, against a fixed 1,500 ms limit. Five alternating runs on a quiet machine:

  | Tree | Run 1 | Run 2 | Run 3 | Run 4 | Run 5 | Over budget |
  | ---- | ----- | ----- | ----- | ----- | ----- | ----------- |
  | pre-fix `719f1cef` | 1,469 ms | 2,061 ms | 1,648 ms | 1,464 ms | 1,660 ms | 3 of 5 |
  | T006 fix tree | 1,538 ms | 1,781 ms | 1,680 ms | 1,517 ms | 2,068 ms | 5 of 5 |

  Under load (another suite running), both trees failed 5 of 5 (pre-fix 1.8 to 3.3 s, fix tree 2.1 to 4.3 s).
- **Not caused by T006, as measured:** the same render timed in one warm process, 15 runs per tree, twice:
  pre-fix medians 554 ms and 581 ms, fix-tree medians 571 ms and 547 ms, none over 1,500 ms. The difference
  between trees is inside the run-to-run spread; what the suite measures is mostly the second call's cost in a new
  process, which is near the limit on this machine before T006.
- **Cause:** a wall-clock limit set when the suite was written (`cdc53480`) on a cold-ish single sample; not in
  feature 203's protected files (the renderer is `scripts/internal/dashboard-renderer.ps1`), so no hand-over.
- **Lane:** none. The file name does not end in `.tests.ps1`, so it is one of the 35 integration scripts that run
  nowhere (item 5): no CI step, no lane, no release manifest.
- **Not fixed here.** Options for the maintainer: time the median of several warm renders, or raise the limit
  with the measurement that justifies it.

## 12. Specrew CI has no manual trigger, so a commit cannot be re-checked without a new push

- **Observed (2026-11-12):** the push runs on `4f315689` stuck as queued, and GitHub refused cancel and re-run
  (DRIFT-206-I001-007). Test and Cross-Platform Validation declare `workflow_dispatch` and were re-run on that
  commit by hand; `.github/workflows/specrew-ci.yml` triggers only on `push` and `pull_request`, so the one gate
  that runs Lint, the self-leak firewall and the Deterministic gate could not be re-run. `4f315689` has no Specrew
  CI result of its own.
- **Effect:** when a push run is lost, the only way to get a Specrew CI verdict is another push, which checks a
  different head.
- **Candidate fix (iteration 002, maintainer 2026-11-12):** add `workflow_dispatch:` to `specrew-ci.yml`'s
  triggers, as the other two workflows have. No workflow is changed in iteration 001.

## 13. `co-review-service.Tests.ps1` failed once in Specrew CI's Deterministic gate: a supervisor still running after a failed lease handoff

- **Observed (2026-11-12):** Specrew CI run 43116326615 on `03bc7a48`, job 130846956739 "Deterministic gate",
  F-198 honesty regression suite: 1 of 131 failed. `tests/continuous-co-review/unit/co-review-service.Tests.ps1:129`,
  case "a FAILED lease owner-handoff STOPS the spawned supervisor, marks the registry failed, and releases the
  lease": "Expected $null or empty, because a supervisor whose lease handoff failed must not keep running
  unprotected, but got System.Diagnostics.Process (pwsh)." The Contract lane was skipped as a result.
- **No 206 commit caused it:** `03bc7a48` changes two Markdown files only (`bug-list.md`, `drift-log.md`); its
  parent `ad31b2d5` has the same code and was green on all three workflows (Specrew CI 43113590639, Test
  43113590640, Cross-Platform Validation 43113590661). 206 has never changed `scripts/internal/continuous-co-review/`.
- **Not rerun** (maintainer, 2026-11-12). Handed to feature 203 as HO-206-8: the code is in 203's protected area.
  A recurrence on 206's next push stops 206's work and is reported.
- **Second sighting (2026-11-13, Specrew CI run 43411715314 on `75ddb2b9`, job 131841569510 "Deterministic gate"):** the
  same case at `co-review-service.Tests.ps1:129` ("Expected $null or empty ... but got System.Diagnostics.Process
  (pwsh)"), 1 of 131 in the F-198 suite. The push touched only the review plan files, the CI step, the lane guard and
  records; 206 has never changed `scripts/internal/continuous-co-review/`. **It stopped the steps after it**, so a
  registered per-push step (T015's, including T002's suite) did not run on that head, and the Contract lane was
  skipped. Reported and stopped; by the reviewer's ruling (2026-11-13, under the maintainer's delegation), the failed
  job is rerun once. HO-206-8 moves to a higher priority for feature 203.
- **Third sighting (2026-11-13, Specrew CI run 43423416387 attempt 1 on `7f346037`, job 131879951424 "Deterministic
  gate"):** the same case and error, the only failure in the run. Rerun once without asking, under the maintainer's
  standing exception for this test (14:28 local, 2026-11-13, relayed by the reviewer session): attempt 2 green
  (job 131885538324). Recorded after review round 2, because round 2 was bound to `7f346037`.
- **Fourth sighting (2026-11-13, Specrew CI run 43500243627 attempt 1 on `c91766df`, job 132146041562 "Deterministic
  gate"):** the same case and error, the only failure in the run. Rerun once under the same exception: attempt 2
  green (Deterministic gate job 132151298400, 131 suites). Recorded after review round 3, because round 3 was bound to
  `c91766df`.
- **Fifth sighting (2026-11-15, Specrew CI run 43709472794 attempt 1 on `ce604236`, job 132798404429 "Deterministic
  gate"):** the same case and error, 1 of 131 in the F-198 suite, the only failure in the run. The push held iteration
  002's plan records only. Rerun once under the standing exception: attempt 2 green, with every job run (Deterministic
  gate job 132801047167, Contract lane 132807717644). For iteration 002's hand-over to 203 (iteration 001's hand-over is
  sealed); DRIFT-206-I002-001.

## 14. `review-posix-runtime.Tests.ps1` failed once on macOS: two stream drains took 360 ms against a 250 ms budget

- **Observed (2026-11-12):** Cross-Platform Validation run 43116326613 on `03bc7a48`, job 130845171704
  "Deterministic fake-provider review runtime (macos-latest)". `tests/continuous-co-review/unit/review-posix-runtime.Tests.ps1:126`,
  case "observes both stream drains concurrently under one bounded wall-clock budget": "Expected the actual
  value to be less than 250, but got 360." The other 7 jobs of the run were green. Not the bug 9 test.
- **No 206 commit caused it:** same evidence as item 13: a Markdown-only commit whose parent, with the same code,
  was green on the same job (run 43113590661).
- **Not rerun** (maintainer, 2026-11-12). Handed to feature 203 as HO-206-9. A recurrence on 206's next push
  stops 206's work and is reported.

## 15. Tests depend on the installed Specrew module's dashboard renderer

- **Recorded (maintainer, 2026-11-12, T014 ruling item 1):** a test should not depend on the installed module.
- **Observed (T014's reading):** when a scratch project has no `scripts/internal/dashboard-renderer.ps1`, the
  validator (`extensions/specrew-speckit/scripts/validate-governance.ps1:2561-2576`), the reviewer scaffold
  (`scaffold-reviewer-artifacts.ps1:2169-2187`) and the feature-closeout scaffold
  (`scaffold-feature-closeout-dashboard.ps1:158-166`) load the renderer from the installed Specrew module
  (`Get-Module -ListAvailable Specrew`). Several of the scripts T015 registers run them on such scratch projects. On
  this machine they load 0.40.0 from the Documents module folder; on a CI runner with no module they take the
  no-renderer path. The result can then depend on which Specrew version the machine has installed, not on the tree
  under test.
- **Not fixed here.** Fix shape for iteration 002: the scratch fixtures carry the tree's own renderer, or the
  scripts take the renderer path explicitly, so no test reads the installed module.

## 16. `substantive-interaction-model-iteration2.ps1` asserts a README section that was removed

- **Observed (T014, 2026-11-12):** "Docs/template truth scenario missing expected pattern 'Feature 016 Interaction
  Model' in README.md" (`tests/integration/substantive-interaction-model-iteration2.ps1:107`). The section was
  removed by `b27f35c4` ("docs: refresh README + getting-started + user-guide", 2026-05-22). The script stops at its
  first failure, so its later assertions are unmeasured.
- **Disposition (maintainer, 2026-11-12):** excluded from the census with the reason "stale README assertion
  (section removed by b27f35c4)"; fixed in iteration 002.

## 17. `distribution-module-publish.ps1` would publish to PSGallery when `PSGALLERY_API_KEY` is set (severity: high)

- **Observed (T014's reading, 2026-11-12):** its last case (`tests/integration/distribution-module-publish.ps1:250-256`)
  runs the release script with `-ReleaseMode publish-stable` and a valid tag ref, and expects it to fail because no
  API key is present. The script does not clear `PSGALLERY_API_KEY`, which the release script reads by default. In a
  shell or runner where that variable is set, the case runs a real stable publish. Also unsure: PowerShellGet's
  `Publish-Module -WhatIf` runs its NuGet bootstrap before the `-WhatIf` check, which can write under
  `%LOCALAPPDATA%`.
- **Severity: high (maintainer, 2026-11-12).**
- **Disposition (maintainer, 2026-11-12):** excluded from the census with the reason "would publish to PSGallery if
  PSGALLERY_API_KEY is set". Fix shape: the case clears the variable (and restores it) itself, or the release script
  refuses a publish whose caller did not ask for one explicitly.

## 18. `multi-host-smoke.ps1` assigns to PowerShell's read-only `$Host`

- **Observed (T014's reading, 2026-11-12):** `tests/manual/multi-host-smoke.ps1:91` is `foreach ($host in $Hosts)`.
  PowerShell variable names are case-insensitive, so the loop variable is the automatic `$Host`, which cannot be
  assigned; the loop is expected to fail with "Cannot overwrite variable Host because it is read-only or constant".
  Not run (it runs the installed `specrew init` and `specrew start`, and init deploys hooks), so the failure is read,
  not observed.
- **Disposition (maintainer, 2026-11-12):** the script is excluded (writes the real home). Fix: rename the loop
  variable.

## 19. `feature-017-dashboard-core.ps1` is red: its fixture is not a Specrew project to `specrew where`

- **Observed (T015, 2026-11-12, run alone, home hook files unchanged):** "FAIL: Healthy fixture: specrew where should
  succeed." `scripts/specrew.ps1 where --project-path <fixture copy>` exits 1 with "ERROR: 'specrew where' requires a
  Specrew-managed project" and "WARNING: Specrew project setup is missing". The fixture
  `tests/integration/fixtures/feature-017-dashboard/healthy-repository` was last changed on 2026-05-15 (`17e2a4c2`);
  the check's message first appears in `29a130b2` (Feature 021's slash-command surface, 2026-05-18). The script stops
  at its first failure.
- **Disposition (maintainer, 2026-11-12):** excluded with its cause as the reason; fixed in iteration 002.

## 20. `feature-018-rich-dashboard.ps1` is red: the rendered dashboard no longer matches its golden file

- **Observed (T015, 2026-11-12, run alone, home hook files unchanged):** "FAIL: Rich-capable replay should match the
  expected rich dashboard contract." The test renders `fixtures/feature-018-dashboard/rich-capable-repository` with
  the tree's renderer and compares it with `rich-capable-expected.txt`.
- **Probe (same fixture and renderer, outside the test's scratch layout):** 59 lines against 57 expected. The
  velocity headline differs (6.08 against 3.65 SP/day; 12 against 20 calendar days for the same 73 SP), and an
  added line "Chosen: Feature 018-velocity-dashboard-visual-richness, from an older feature pointer that does not
  record its branch." The probe's repository name, branch and rendering mode also differ, which is the probe's
  layout, not evidence.
- **Cause: not established.** Either the golden file is stale against later renderer changes or the velocity
  calculation changed behaviour; the fix decides which.
- **Disposition (maintainer, 2026-11-12):** excluded with its cause as the reason; fixed in iteration 002.

## 21. `validator-hardening-iteration2.ps1` is red: `specrew start` pauses on agent and charter files it wrote itself

- **Observed (T015, 2026-11-12, run alone, 944 s, home hook files unchanged):** 14 of its first 15 checks pass;
  assertion 3 fails: "Bookkeeping-only copilot-instructions changes should not trigger pause-and-confirm." The second
  `specrew start -NoLaunch` writes PAUSE-AND-CONFIRM naming `.github/agents/squad.agent.md` and five
  `.squad/agents/*/charter.md` files.
- **Cause:** item 2b's cause beyond the file T003 fixed. The first start run heals `squad.agent.md` (the fixture has
  a one-line stub) and creates the five charters (the fixture has none); the test commits everything (`git add -A`);
  the next run classifies those Specrew-written files as user changes. T003's approved design strips matched
  `specrew-managed` blocks in `.github/copilot-instructions.md` only.
- **Disposition (maintainer, 2026-11-12, SC-002 option 1):** excluded with its cause as the reason. SC-002 is not met
  in iteration 001 and is a required item for iteration 002: feature 206 does not close without this script green
  and registered, in the release manifest (not per push). For iteration 002 planning, a design of one page at most:
  what `specrew start` does with whole files it created or repaired itself, and which session-loaded files get the
  matched-block treatment.

## 22. `project-path-resolution-regression.ps1` copied the developer's gitignored session state into its fixture

- **Observed (T015, 2026-11-12, supervised run 1, 39 s, home hook files unchanged):** red: "specrew start --no-launch
  (default path) exited with code 1." Start refused: "Session-state file is present but stale or unparseable:
  last-start-prompt.md ... specrew start could not continue: this project has stale session state, and no recovery
  path was chosen" (item 1's path, working as T001 fixed it).
- **Cause:** the script built its fixture by copying this repository's `.specrew` working folder, which holds
  gitignored session state (`.gitignore:59`, `:61`): `last-start-prompt.md`, `start-context.json`, and the
  authority, review and runtime stores. This worktree's prompt has no frontmatter, so start read it as stale. The
  result depended on who ran the script; a fresh CI checkout has neither file.
- **Fix (reviewer ruling 2026-11-12, under the maintainer's delegation):** the fixture copies only the files git
  tracks under `.specrew` (197 files instead of the working folder's 308). RED 1/50 in `b9354aff`, GREEN 50/50 in
  `7c8b5cf7`; DRIFT-206-I001-015.
- **Supervised run 2 (T015, 2026-11-12, on `7c8b5cf7`, 33 s, home hook files unchanged): still red, a different
  stale state.** With no session files copied, start reports "Session-state file missing on disk:
  last-start-prompt.md" and "... start-context.json (re-anchor will recreate it from the current spec)", and refuses
  with no console: "specrew start could not continue: this project has stale session state, and no recovery path
  was chosen ... run specrew start again with a choice, for example: specrew start --recovery-choice A". The
  fixture copies `specs/` (features with iterations) and the tracked `.specrew` files, so to start it is a governed
  project whose session files are missing. A fresh checkout of this repository meets the same refusal. The other
  four cases pass (init --dry-run, update --info, team list, review, and the static GetFullPath scan).
- **Open (maintainer):** SC-001 needs either the test to pass a recovery choice (`--recovery-choice`) or `specrew
  start` to treat a governed project with no session files, as in a fresh clone, as not stale. No third run without
  the maintainer.

## 23. `specrew start` re-anchors to, and writes into, a feature outside the `-ProjectPath` it was given

- **Observed (T015, 2026-11-12, SC-001 supervised runs 3 and 4, home hook files unchanged both times):** this
  repository's real `specs/206-bug-bash/iterations/001/state.md` was rewritten during the start case of
  `project-path-resolution-regression.ps1`, at 21:29:17 UTC (run 3, on `3e3ae481`) and at 21:44:52 UTC (run 4, on
  `e416edc6`, with the fixture in the temp folder as its own git repository). The same change both times: a
  `specrew:task-progress-summary` block added; `Tasks Remaining` "T002, T003, T015, T018" and `In Progress` "(none)";
  the `Updated` stamp; the escalation block's closing marker line removed. The fixture's `start-context.json` recorded
  `feature_path: C:\Dev\specrew-206-bug-bash\specs\206-bug-bash`. Both times `state.md` was restored from git at the
  maintainer's word; the two diffs are kept as evidence.
- **Route (read, nothing run):**
  1. `.squad/identity/now.md` is tracked, and the boundary sync wrote an absolute path into it
     (`session_state_feature_path: "C:\Dev\specrew-206-bug-bash\specs\206-bug-bash"`; last written by `47c0c026`).
     The fixture copies `.squad` whole.
  2. `Get-SpecrewSessionStateSnapshot` takes the first non-empty of prompt, start context, identity and decisions
     (`scripts/internal/session-recovery.ps1:111`, `:131`). A fresh copy has no prompt or start context, so the
     identity file supplies the session state (`Get-SpecrewIdentitySessionState`, `:47-57`).
  3. Recovery A takes that `feature_path` (`session-recovery.ps1:519-520`) and, because the path exists on this
     machine, makes it the resume override (`:544`).
  4. `specrew-start.ps1:3258` sets `$ResumeFeature` to it; `Resolve-FeatureDirectory` (`:3309`) accepts a rooted path
     as it is (`:664-669`), with no check that it lies inside the project root.
  5. Start then writes that feature's task-progress summary into its `state.md`.
  The enclosing git repository (run 3's first diagnosis) is not the route: run 4's fixture had its own.
- **Also:** a tracked file carries a machine-specific absolute path, the same class as item 6b.
- **Not fixed here.** A start-only item for iteration 002 (`iterations/001/specrew-start-facts.md`). SC-001 is not
  met in iteration 001 and is required in iteration 002.

## 24. `project-path-resolution-regression.ps1` built its fixture inside this repository

- **Observed:** item 23, run 3. The scratch root was `<repository>/.scratch/project-path-resolution-regression`, and
  the fixture had no git repository of its own.
- **Fix (maintainer's option 1, 2026-11-12):** the scratch root is under the temp folder; the fixture gets its own
  `git init` and one commit; the script exits 1 if the fixture's git top level is not the fixture. RED 1/52 in
  `e29b179f`, GREEN 52/52 in `e416edc6`; DRIFT-206-I001-018. Necessary, not sufficient: run 4 still wrote into this
  repository through item 23's route.
- **For iteration 002 (reviewer, 2026-11-13, under the maintainer's delegation):** the script's `.specrew` copy takes
  tracked files only (`7c8b5cf7`). A fixture must copy every file git does not ignore, tracked or untracked: a review
  preflight runs in a verification copy that restores `.specrew` and `.squad` as untracked files, and a tracked-only
  copy finds nothing there (item 29, round 3's preflight). The script refuses to run and is not changed now.

## 25. `specrew init` runs its Squad probe in the install root, even with `-DryRun`, and its cleanup fails silently

- **Observed (T015, 2026-11-12, SC-001 supervised run 4):** an untracked folder appeared at this repository's root
  during the `specrew init -DryRun` case: `.specrew-squad-probe-51b037d112c14c728e686658de66bba0/.github/skills/
  cross-squad-communication/SKILL.md` (19,574 bytes, SHA-256 `6395CA66...DEAB0439`, created 21:44:58 UTC). It was
  deleted at the maintainer's word; a copy and its listing are kept as evidence.
- **Cause (read):** `scripts/specrew-init.ps1:755` calls `Get-SquadInitPlan -ProbeRoot $repoRoot`, the Specrew install
  root, which in a dev checkout is this repository. `Test-SquadInitSupportsNonInteractive`
  (`scripts/init/squad-deploy.ps1:34`) creates `.specrew-squad-probe-<guid>` there and runs a real
  `squad init --non-interactive` in it, dry run or not. Its cleanup is `Remove-Item ... -ErrorAction
  SilentlyContinue` in a `finally`, so a file it cannot remove stays without a word.
- **Same run:** the init case was red ("did not emit expected output pattern '...\init-project'"); the captured
  output is the dry-run summary with no project path. Cause not established.
- **Not fixed here.** For iteration 002, with item 23: the probe belongs in a temp folder, and a failed cleanup should
  be reported.
- **Fixed (iteration 002, T025, 2026-11-15):** the probe makes its folder under the temp folder, `specrew init` no
  longer passes the install root, and a folder the cleanup cannot remove is reported with its exact path (RED 3/4
  `091a0b06`, GREEN 4/4 `4bca00ae`).
- **The init case's cause (read, T025):** the case runs `specrew init -DryRun` in an existing empty folder and looks for
  that folder's path in the output. A dry run on an existing folder records no `project-path` action, and
  `Write-BootstrapSummary` (`scripts/init/post-bootstrap-output.ps1`) prints the path only after a real run ("Bootstrap
  completed for ..."); in a dry run it prints the action table and "Dry run complete. No files were changed." So the
  output never holds the path: a gap in what the case can observe, not a path resolved against the wrong folder.
  T024 settles it.

## 26. `mechanical-findings-contract.ps1` passed an invalid document whenever `Test-Json` returned false without throwing

- **Observed (2026-11-12, CI on `103a5e3b`):** Specrew CI run 43315180157, job 131523011721 (Deterministic gate,
  T015's per-push step): "FAIL: Schema contract should reject demoted findings that omit dispositionRef." The other
  22 scripts in the step passed. The same script passed on `d258e060` (run 43274075287) and locally, and nothing in
  it or in the product changed between the two heads.
- **Runner image:** green on `ubuntu24/20261111.370`, red on the older `ubuntu24/20261101.360`.
- **Cause:** its helper `Test-FixtureAgainstSchema` ran `$null = Test-Json ...` and returned `$true` unless an
  exception was thrown. Depending on the PowerShell version, a schema mismatch either throws or returns `$false`, and
  the helper dropped the `$false`. The check reproduces the defect on this machine's pwsh 7.6.10 with a `Test-Json`
  stand-in that returns `$false`.
- **Fix (reviewer ruling 2026-11-12, under the maintainer's delegation):** the helper returns `Test-Json`'s own result;
  an exception still counts as invalid. RED 1/55 in `ff8a39a8`, GREEN 55/55 in `6fd9fcd9`; DRIFT-206-I001-020.
- **Same pattern elsewhere:** none. A search of `tests/` for a `try` block that discards a command's result with
  `$null =` and then returns `$true` finds only this helper.

## 27. `journal-fault-injection.tests.ps1` failed on macOS: concurrent dispatchers exited non-zero and journaled nothing

- **Observed (2026-11-12, CI on `103a5e3b`):** Cross-Platform Validation run 43315180135, job 131521200957
  "Deterministic fake-provider review runtime (macos-latest)", step "Hook-output journal concurrent append (case e)
  and outage buffer". Part 1 of case (e), with 4 writers and 4,000 appends, passed: no torn line, nothing missing,
  no degradation. In part 2 (real dispatcher processes on Stop, two at a time), pair 1 exited 0 but pairs 2 to 5
  each exited non-zero, and "every concurrent dispatcher journaled its stop reason (8 missing of 10)": 9 failures.
  The same job was green on `d258e060` (run 43274075221).
- **Not a timing assertion.** The dispatcher processes failed, and the stop reasons of the 8 that failed were never
  journaled. That is product behaviour in the hook dispatcher under concurrent Stop, so it is a higher severity than
  the timing class of items 13 and 14.
- **Why the dispatchers exited: the log does not say.** Case (e) discards each dispatcher's standard output and error
  (`$null = $p.StandardOutput.ReadToEndAsync()`, the same for error) and asserts only `ExitCode -eq 0`, so neither an
  exit code nor a message reaches the log. Everything after pair 1 failing is consistent with state left by pair 1
  (a lock or marker) rather than with load, but that is not shown.
- **No 206 commit caused it:** 206 never changed the dispatcher or this test; the push touched records, the census,
  the lane guard and two test scripts.
- **Disposition (reviewer ruling 2026-11-12, under the maintainer's delegation):** not rerun. Handed to feature 203 as
  HO-206-10, at higher severity than the timing class. A recurrence on 206's next push stops 206's work and is
  reported.

## 28. T002's suite takes 310 s on the Ubuntu runner, and it now runs on every push

- **Measured (2026-11-13):** Specrew CI run 43411715314 (attempt 2) on `75ddb2b9`, job 131847705487, T015's per-push
  step: "RESULT tests/unit/overclaim-dirty-check-separator.tests.ps1: 3 passed, 0 failed in 310 s". The step's 23 scripts
  took 123 s on its first run (`d258e060`).
- **What it does per test (read, not profiled):** each of its 3 tests copies the repository's whole `.specrew`,
  `.squad` and `.github` plus `specs/013-validator-hardening` into a temp folder. It then runs `git init`, `add -A` and
  `commit` over that copy, and runs `validate-governance.ps1` on it in a child pwsh. Which part dominates on the runner
  is not measured.
- **Disposition (reviewer, 2026-11-13, under the maintainer's delegation):** it stays per push for now. For iteration
  002 planning: measure the parts, and decide between a smaller fixture (only the files the check reads) and the
  release manifest.

## 29. T002's suite copied the local review store into its fixture, so its result depended on the machine

- **Observed (2026-11-13):** the review plan's `f206-unit-suites` lane, run locally on `d11b02f5` before round 3,
  failed: `tests/unit/overclaim-dirty-check-separator.tests.ps1` 1 passed, 2 failed. Its fixture's `review.md` says
  accepted, and the validator judged it against round 2's findings result ("the active review campaign has no
  completed, valid campaign result"). The same suite is green on CI.
- **Cause:** the fixture copied the whole `.specrew`, `.squad` and `.github` folders, git-ignored files included, so
  the local review store (`.specrew/review/authority/`, round 2's campaign) reached the fixture. CI has no local store.
  The same class as SC-001's first fixture bug (DRIFT-015). Round 3's preflight runs this lane locally, so it would
  have failed there too.
- **First fix, wrong for the preflight:** the fixture copied only the files git tracks under those folders (RED 1/70
  in `db1e0fda`, fix `df8575b0`, green here and on CI). Round 3's preflight (run `run-20261113-192634642-269e543e`,
  no round used) then failed `f206-unit-suites`: the preflight runs in a verification copy, a git worktree of the
  frozen tree, which leaves `.specrew` and `.squad` out and restores them **untracked**. The tracked-only copy found
  neither there. The lane passed in the preflight's environment without that layout, which isolated the cause.
- **Fixed in iteration 001:** the fixture copies every file git does not ignore, tracked or untracked; the local review
  store stays out because git ignores it. The suite's own test builds the preflight's layout (RED 1 of 3 in
  `5517cb3f`, fix `0d491189`), and the lane guard checks the command. All five lanes now run in the preflight's
  layout before a round (DRIFT-023).
- **Not fixed:** `tests/integration/validator-hardening-iteration2.ps1` builds the same fixture the same way (line 132).
  It is excluded as red for SC-002 and is not run; its fix belongs with SC-002 in iteration 002.

## 30. Four repository-level validator stops write only their category to the nightly findings file

- **Observed (2026-11-14, review round 3, finding 4):** a repository-level stop wrote one record with its rule and no
  message hash, so two different failures in one category had the same nightly fingerprint and the tracking issue
  was not updated.
- **Fixed in iteration 001 for three stops** (`7fc81397`): the sealed-iteration, Squad team and classifier stops hold
  their error messages, and each message is now written as a hash under the stop's rule.
- **Not fixed:** `source-without-implement-authorization`, `handoff-evidence`, `approved-status` and
  `boundary-canonical` return only a count; their messages are printed inside the check. A changed failure in one of
  those categories still leaves the fingerprint unchanged. For iteration 002: each check returns its messages, and
  the stop passes them with `-FailureMessages`.

## 31. The census guard reads `steps:` inside a YAML block scalar as real steps

- **Found (2026-11-14, review round 4, `finding-175c2ab8a756a10e`, FR-011):** `Get-WorkflowRunText`
  (`tests/unit/every-suite-is-named-by-a-lane.tests.ps1`) enters any line matching `steps:`, so an `env:` value written
  as a `|` block holding `steps:` and `- run: tests/integration/orphan.ps1` registers a suite nothing runs.
- **For iteration 002:** track block-scalar boundaries and the real job and step structure, behind a failing fixture.

## 32. The census guard keeps a comment that follows `;`

- **Found (2026-11-14, review round 4, `finding-2f7f4713967f972f`, FR-011):** `Remove-ShellComment` starts a line
  comment only at the line start or after whitespace, so `Write-Host done;# tests/integration/orphan.ps1` counts as a
  registration.
- **For iteration 002:** treat a statement delimiter as a comment boundary, behind a failing fixture.

## 33. A malformed managed-block opener is treated as balanced

- **Found (2026-11-14, review round 4, `finding-5cfaa2b2f67ea55b`, FR-003):** the marker pattern in
  `scripts/internal/instruction-file-merge.ps1` accepts either trailing arrows, so `<!-- >>> specrew-managed
  coordinator <<< -->` with a normal closer is stripped, while the healer keeps it as user content. A real change in
  that section can then read as bookkeeping.
- **For iteration 002:** the trailing arrows must match the marker's direction; a mismatched pair is unbalanced
  (design condition 3), behind a failing test.

## 34. An unexpected validator exception shares one nightly fingerprint

- **Found (2026-11-14, review round 4, `finding-42d18d3781d59c95`, FR-009):** the validator's outer catch calls
  `Write-ValidatorSummaryAndExit` with only `unexpected-validator-error`, so two different exceptions write the same
  category record. A fifth stop beside item 30's four.
- **For iteration 002:** pass the exception detail through `-FailureMessages`, so only its hash is written.

## 35. Overlapping nightly runs can open two tracking issues

- **Found (2026-11-14, review round 4, `finding-d249cc05e6ee6910`, FR-009):** the nightly workflow allows scheduled and
  manual runs with no `concurrency:` group, and the notifier lists open issues once before creating one. Two failed
  runs at once can each create an issue, and a green run closes only the lowest-numbered one.
- **For iteration 002:** serialize the notify job across runs (a `concurrency:` group), behind a test of the workflow.

## 36. Round 1's three partial notes, never raised again

- **Found (2026-11-13, review round 1, partial, cut by its deadline):**
  - `finding-075e938b2db1e279`: plan.md's note "Abandoned only by a recorded maintainer ruling (T009)" and its FR-008
    mapping row say unruled `abandoned` is not closed; the code closes every `abandoned` status, and the T009 row moved
    that rule to iteration 002 (DRIFT-206-I001-010).
  - `finding-ac49cb6709990d38`: the T003 and T015 rows claim more than the census shows (T003's suite runs; T015's
    title says both B5F-036 suites are green and registered, while both are excluded).
  - The notifier adopts any open issue carrying the `nightly-truth-check` label, whoever opened it.
- **Disposition (maintainer, 2026-11-14):** iteration 002, with round 4's findings.

## 37. A task the plan defers has no review verdict that says so

- **Found (2026-11-14, at review sign-off):** the governance check allows a task verdict of `pass`, `needs-work` or
  `blocked` only, a deferred task must still have a row, and an `accepted` review cannot hold a non-passing task. So
  the only way to keep an accepted review is to write `pass` on a part-finished task, as T003's row now does with its
  note (DRIFT-206-I001-027).
- **For iteration 002:** a verdict value for a task the plan defers (for example `deferred`, with its decision id),
  accepted beside an `accepted` review.

## 38. The governance lane cannot be trusted in the preflight layout once plan.md is at `reviewing`

- **Observed (2026-11-14, on `029dafa5`):** `f206-governance-206` (`validate-governance.ps1 -IterationPath
  specs/206-bug-bash/iterations/001`) failed in the preflight-layout run with `[review-evidence-integrity]
  Form-vs-meaning gap detected: iteration artifacts declare 15 completed task(s) but git diff
  52c9651cab6e84c6bcb362c11ebd20c882863255...HEAD is empty (0 files changed)`. The baseline ref is state.md's
  **Baseline Ref**. The same command in the real worktree fails only on the derived-block item (an approved exception).
- **Cause:** the layout copy commits the frozen tree as a parentless root commit and fetches the history beside it.
  `<baseline>...HEAD` then has no merge base and reads as empty. The integrity check applies once plan.md is at
  `reviewing`, which is why it did not fire before rounds 1 to 4 (plan.md at `executing`). Not established: whether
  the engine's own verification copy has the same parentless HEAD. This was seen only in my emulation of it.
- **Exposure:** iteration 002's review preflight runs with plan.md at `executing`, so it is not exposed. A lane run
  after the review-signoff boundary, or a review campaign started with plan.md at `reviewing`, is.
- **For iteration 002:** give the layout copy's commit the reviewed commit as its parent, or skip the diff check when
  the baseline is not an ancestor and say so. Then prove it with the lane run at `reviewing`.
- **Disposition (reviewer, 2026-11-14, under the maintainer's delegation):** the push of `029dafa5` with this lane red
  was accepted on that evidence, as a records-only change. It is not a general licence: a lane red for a reason not
  reproduced and explained still stops a push.

## 39. Every review sign-off and every retro costs one red Specrew CI Lint push

- **Observed (2026-11-14):** at review sign-off (`b8d3b8f2`, Lint red on the plan-status item only) and at the retro
  (the push of `c439c012`, `e053b91a` and `7233fc35`). Feature 205 paid the same at both boundaries, and feature 202
  at review sign-off (`a7e2b74c`).
- **The ordering:**
  - The validator calls plan.md's status stale as soon as the next record exists (`validate-governance.ps1` lines
    5195 to 5201: review.md beside `planning` or `executing`, retro.md beside anything but `retro` or `complete`).
  - The phase line moves only at the boundary sync, after the human's verdict.
  - The sync requires the verdict's commit on origin first (`verdict-commit-durable`, `scripts/internal/gate-preflight.ps1`
    line 153), so the record is pushed while the line is still behind.
- **Direction (suggested by the reviewer to the maintainer):** the validator treats "record written, boundary approval
  still pending" as a normal state, not an error. For example, review.md beside `executing` is accepted while
  `start-context.json` shows the review-signoff crossing pending or not yet reached, and likewise retro.md beside
  `reviewing`. Once the verdict is recorded and the line has not moved, the check fires as today.
- **Files a fix would touch:** `extensions/specrew-speckit/scripts/validate-governance.ps1` (the two checks; read the
  pending crossing through the existing start-context reader), its deployed copy
  `.specify/extensions/specrew-speckit/scripts/validate-governance.ps1`, `.specrew-extension-runtime.json` (the
  hash), and a unit suite with the four cases (record before verdict, at verdict, after the line moves, verdict
  recorded with the line behind).
- **Size:** about 1 SP (0.5 for the check and its reader, 0.5 for the tests and the deployed copy).
- **Merge risk with feature 203:** none of these files is on 203's protected list (`scripts/internal/continuous-co-review/`,
  the capture stores under `scripts/internal/bootstrap/`). On `origin/203-beta5-stabilization` since the merge base
  `df1141a8`, 203 has changed neither copy of `validate-governance.ps1` nor `gate-preflight.ps1`. It has changed
  `.specify/extensions/specrew-speckit/.specrew-extension-runtime.json` (24 lines added, 20 removed), so the hash
  record is the one likely conflict, resolved by recomputing the hashes.
- **Disposition (maintainer, 2026-11-14, 22:39 local, relayed by the reviewer):** recorded for iteration 002; whether it
  goes in is the maintainer's decision at that iteration's plan. Not started.
- **Link (2026-11-16):** feature 203's B5F-083 (a scaffolded iteration cannot be pushed until its plan exists) is in
  203's iteration 002 scope with B5F-050 and B5F-059, and touches the same staleness checks as 206's T034.
- **Fixed (iteration 002, T034, 2026-11-16):** RED 4/7 `4128585a`, GREEN 7/7 `3a3ba803`.

## 40. A turn that waits on the human is refused three times for a "coverage decision", then released by the cap

- **Source:** the maintainer, relayed by the reviewer session (2026-11-14, 23:47 local): "OK, can you descibe the
  problem to 206 for the next iteration to solve".
- **Seen:** a Claude session in another of the maintainer's projects, on another machine, on the installed engine (its
  version was not stated; the paste is cut off). The turn ended by asking the human something. The Stop hook refused
  it three times for a coverage decision, then the refusal cap released it, and the human saw the answer twice with
  hook text between. Here too, on 2026-11-15, the Stop hook asked for the same coverage decision twice. Both times the
  iteration was closed and only records had changed since the last review.
- **Defect:**
  - (a) Wrong moment: a turn that only waits for input owes no coverage decision.
  - (b) Unsatisfiable in that turn, so only the cap ends it: three refused turn ends, about 14 s per Stop run
    (203's DRIFT-073 in `specs/203-beta5-stabilization/iterations/001/drift-log.md` on 203's branch).
  - (c) The human is not told what to type.
- **Expected:** a waiting turn owes no coverage decision. When one is owed, the human is told once what settles it. A
  requirement the session cannot meet in the turn is not refused three times.
- **Where:** the cap text is in `extensions/specrew-speckit/scripts/specrew-conformance-provider.ps1` here at lines
  1920 to 1922 (and 2294), and on 203's branch at lines 1991 to 1993. Since the merge base `df1141a8`, 203's branch has
  changed the file (both copies, `extensions/` and `.specify/`) by 126 lines added and 66 removed in 8 commits.
- **Reproduction:** not yet run. A scratch fixture on the installed engine (stale coverage, and a turn that ends by
  asking the human) waits until the reviewer clears the load hold for feature 203's last review round. It is to say
  what the classifier decided and why.
- **Size:** about 1.5 SP (0.5 for the fixture and the classification, 1 for the fix and its tests).
- **Protected:** the reviewer treats the conformance provider as protected until the maintainer says otherwise.
  Feature 205's protected list names it; 206's list (`scripts/internal/continuous-co-review/` and the capture stores
  under `scripts/internal/bootstrap/`) does not. **The maintainer is asked to settle the list as well as the item.**
- **Choice for the maintainer:** fix it after 203 merges, hand it to 203, or lift the protection.

## 41. The closeout dashboard is drawn before the verdict and never redrawn

- **Observed (2026-11-15, 206 iteration 001):** the closeout sync draws `iterations/<NNN>/dashboard.md` when the retro
  -> iteration-closeout crossing is opened (`Invoke-SpecrewAutoRenderDashboard`, `scripts/internal/sync-boundary-state.ps1`
  line 1585, which runs `scripts/specrew-where.ps1 -CaptureKind iteration-closeout`). The verdict capture then moves
  the phase lines and seals the iteration, and nothing redraws the dashboard. The sealed snapshot showed:
  - the phase as retro;
  - `20 SP planned | 0 SP delivered`;
  - an "AWAITING YOUR VERDICT" banner;
  - a closed list without the iteration.
- **Corrected once:** redrawn and resealed by the maintainer's decision (DRIFT-206-I001-032). After the verdict the
  same renderer gives 20 SP delivered, phase iteration-closeout and the iteration under Recent Shipped.
- **Direction:** draw the dashboard as the capture's last act before the seal, or at the boundary commit.
- **Files:** `sync-boundary-state.ps1` and the capture's seal step. Before planning, check whether the seal step is in
  203's area (`scripts/internal/bootstrap/`).
- **Size:** about 1 SP with its test.

## 42. An approval with instructions is not captured, while the bare phrase is (hand-over to 203)

- **Observed (2026-11-15):** `approved for iteration-closeout - after the boundary commit, check the dashboard's
  delivered points; if it still shows 0 SP delivered, stop before pushing and report` was typed twice, at 01:19 and
  02:50 local. Both are journaled as `verdict-not-captured-disclosed` with `leading_text` empty, at prompt submit and
  again at Stop. The first came right after a context compaction; the second did not. The bare phrase was captured at
  03:12. The packet offers `approved for <to> - <your instructions>` as a line the human can send.
- **Where:** the capture code, under `scripts/internal/bootstrap/`, protected for 206. A hand-over to 203.
  Recorded in DRIFT-206-I001-031.

## 43. The stale-review wording at sign-off makes Specrew the subject, not the change

- **Source:** the maintainer, relayed by the reviewer session, 2026-11-15:
  - about 04:05 local: "Is that a Specrew problem? I think this is by desing, but the wording feals like a SPecrew
    issue";
  - at 04:07: "Yes, pass to 206".
- **Situation:** a crew on the installed engine made fixes after its last co-review round. The sign-off gate found the
  review stale and offered a partial review signoff or an allowance reset; the gate worked as designed. The crew told
  the human: "Specrew will not record the review stage yet, because its own code review last read an older version of
  the code." / "Specrew's co-review gate refused because its last code review read the tree as of 7cb2794, and a lot
  has changed since." / "Accept partial coverage (my recommendation)."
- **Where the text comes from (at `ebf13f19`):**
  - `scripts/internal/continuous-co-review/review-signoff-evidence-gate.ps1` lines 960 to 962 (1339 lines): "The latest
    campaign result remains useful evidence but targets a moved or earlier snapshot and cannot authorize the current
    tree. ..."
  - `scripts/internal/continuous-co-review/signoff-gate-wiring.ps1` lines 185 to 191 (198 lines), appended to that
    refusal: "If you intentionally accept partial coverage for this exact tree, do these three things in order, ..."
  - The Stop hook notice, `scripts/internal/continuous-co-review/continuous-co-review-navigator.ps1` (1625 lines):
    - line 1423, "Specrew review — {route sentence}.";
    - line 1469, the review-stale sentence: "your last review no longer covers these files";
    - line 1523: "What to do: ask the human to approve a fresh review round ... If they prefer not to spend a round,
      they can review the artifacts themselves".
  - `docs/troubleshooting.md` lines 377 to 379 teach the same sequence. No skill or squad template carries it.
- **Why the crew's wording came out this way:** the subjects are "the latest campaign result", "partial coverage" and
  "your last review". None names the human's change, so a paraphrase lands on the tool.
- **Proposed wording:** the change is the subject, and the typed phrases stay exactly as they are.
  - Opening: "<N> file(s) changed after the last review round (run <run>, tree <short>); no reviewer has read those
    changes. Usually these are the fixes for what that review found."
  - The two choices: sign off with those changes unread, by `approved for partial review signoff - <why that is
    safe>`; or have them read first, by `approved for allowance reset` (when no rounds remain) or `approved for review
    round`, then the round.
  - The three-step order, the no-commits rule and the advisory clause stay, worded about the human's files.
- **Size:** about 2 SP for the three scripts, the doc and the tests that pin the wording.
- **Protected:** all three scripts are under `scripts/internal/continuous-co-review/`, in 203's area. On 203's branch
  since `df1141a8`:
  - `signoff-gate-wiring.ps1`: 61 lines added in 1 commit; the suffix is unchanged (line 244).
  - `review-signoff-evidence-gate.ps1`: 86 lines added and 9 removed in 7 commits; the stale message is unchanged
    (line 974).
  - `continuous-co-review-navigator.ps1`: 18 lines added and 422 removed in 5 commits; the Stop notice text is no
    longer found under `scripts/` there, so it must be re-read after 203 merges.
- **Choice for the maintainer:** as item 40: fix it after 203 merges, hand it to 203, or lift the protection.
- **The design point (separate, for a proposal):**
  - On the ordinary path (review, fix what it found, sign off), the fixes always come after the last round, so the
    review is always stale at sign-off. The engine names that everyday outcome with words for an exception
    ("partial coverage", "override").
  - Features 205 and 203 and this iteration all met it in the week of 2026-11-14.
  - `proposals/INDEX.md` has no proposal that covers it. The nearest are 197 (continuous co-review) and 102
    (cross-model independent reviewer). It would be a new proposal; it is not designed here.

## 44. The Completed date and the hardening rows are checked only after the closeout verdict

- **Observed (2026-11-15, 206 iteration 001):** the governance check failed the closed iteration twice: plan.md had no
  Completed date, and hardening-gate.md's five rows were still `planning-time-analysis` / `pending-post-implementation`.
  The check applies only once plan.md is at complete, which happens after the maintainer's closeout verdict. So the
  closeout packet was shown with both open, and the boundary commit `900b21b7` would have been red alone.
- **Precedent:** feature 205 met the same pair (its DRIFT-028, corrected in `d4c11236`), and feature 202 has it on main
  in `794f6559`.
- **Corrected once:** by the maintainer's decision at 04:55 local (DRIFT-206-I001-033, `ebf13f19`).
- **Direction:** check both before the closeout packet is shown (at the retro -> iteration-closeout arrival), and name
  what is open in the packet.

## 45. The review-freshness rule cannot pass from a fresh clone once the cited review record is in the clone

- **Established here:** the validator's freshness rule fails from a fresh clone whenever the cited run's `result.json`
  is in the clone (the reading below). Captured at the maintainer's word, 2026-11-15, 20:04 local: "Yes capture it, we
  must get rid of all these anoying bugs" (relayed by the reviewer).
- **Unconfirmed second-hand sighting.** A crew in another of the maintainer's projects, on the installed engine,
  reported after its round 34 that CI refuses because it cannot find the round's reviewed copy, a tree object only that
  PC has, while the same check on the PC passes. The reviewer checked that project's repository on GitHub: nothing under
  `.specrew/review/authority` is committed there (only the contracts folder), it has no workflow named Specrew CI, and
  every failing run in its last forty has a cause outside Specrew. By the reading below the rule returns early in that
  project's CI, so the report's CI symptom is not reproduced there. A run and a step have been asked of that crew.
- **The check (read on this branch, which carries the installed engine's rule):** the validator's W38 freshness rule,
  `Test-ReviewCitedRunEvidence` in `extensions/specrew-speckit/scripts/validate-governance.ps1` (about lines 1215-1347),
  run by Specrew CI's Lint job through `validate-governance`.
  - It reads the cited run's `result.json` under `.specrew/review/authority/campaigns/*/runs/<run>/`, takes its
    `target_digest` (the tree the round froze), and computes the current tree with
    `Get-ContinuousCoReviewReviewedStateDigest` (`scripts/internal/continuous-co-review/reviewed-state-digest.ps1`).
  - When the two differ, `Get-SpecrewReviewedTreeSourceDrift` (`extensions/specrew-speckit/scripts/shared-governance.ps1`,
    about line 8849) runs `git diff --name-only <cited tree> <current tree>`. The cited tree is a dangling object the
    digest wrote and no commit points to, so it is never pushed. In a fresh clone the diff fails, the drift is "not
    comparable", and the rule adds an error: "that reviewed tree is no longer in this repository's object store - so
    whether any source changed since cannot be established". The comment says this is deliberate: "Not a licence to
    pass".
  - **From a fresh clone it can pass only if the current digest equals the cited one exactly,** which the round's own
    records commit already breaks (DRIFT-007: recording a review moves the digest). So in CI it fails after every
    round whenever the cited `result.json` is in the clone, and is skipped whenever it is not.
  - **Why this repository does not see it:** `.specrew/review/authority/` is ignored here (`.gitignore`), so CI has no
    `campaigns` folder and the rule returns before it checks anything. `specrew init` writes the same entry into a
    governed project's `.gitignore` (`scripts/internal/file-classification.ps1:32`) and untracks per-session files it
    finds tracked. So the refusal needs the cited `result.json` in the clone: a store committed before that entry, a
    project without it, or the run's record committed by another route.
- **One cause with the derived-block item, two places.** Feature 205's DRIFT-012 (the standing derived-block
  exception): the derived independent-review block is recomputed from the review store at validation, and the store is
  local, so the local check and CI compute different blocks. Here the review snapshot is local, so the local check and
  CI reach different answers. The class: a CI check reads machine-local review evidence (the store, or a tree object
  only that machine has) as if it were in the repository.
- **Honest behaviour for CI (proposed):** where the cited reviewed tree is not in the object store, the rule cannot
  check the citation, and says so in a warning naming what is missing and where it lives (the machine that ran the
  review), not an error; the same as D2-a does for a missing `start-context.json` (FR-016). The local check, which has
  the tree, and the sign-off gate still enforce staleness. The other way, making the evidence something committed, is
  not designed here.
- **Files and owner.** The fix is in `validate-governance.ps1` (the W38 branch that adds the "not comparable" error),
  with its `.specify` mirror and the hash record; `Get-SpecrewReviewedTreeSourceDrift` in `shared-governance.ps1`
  already returns the reason `reviewed-tree-not-in-object-store`. Neither is feature 203's protected code. The digest
  helper that writes the dangling tree is under `scripts/internal/continuous-co-review/` (feature 203's) and does not
  need to change for the warning. The derived-block side (DRIFT-012) reads the same store and stays with 203: after 203
  merges, a hand-over, or the protection lifted, by the maintainer's choice.
- **Issue:** alonf/specrew#3721, filed by that crew for the dangling reviewed tree.
- **Placed (the maintainer, 2026-11-16, 02:26 local, "OK, give this information to 206", relayed by the reviewer):** at
  the top of iteration 003's candidates, with items 46 and 47. An order of candidates, not a scope approval: iteration
  003's scope is set at its own planning boundary. Iteration 002 is unchanged.
- **Before feature 203 merges:** the warning in `validate-governance.ps1` (the W38 branch that adds the "not
  comparable" error) can be done in iteration 003 on its own; it needs no change to the digest helper. Making the
  evidence something committed would touch `scripts/internal/continuous-co-review/` and waits for 203.

## 46. A boundary sync stops when markdownlint cannot be launched, although its code says it warns and proceeds

- **Seen (second-hand, unconfirmed):** the maintainer's project RingMCPBridge on their other machine, Specrew 0.40.0, at
  its iteration 001 review-signoff, 2026-11-16 about 00:30 to 02:11 local. The review-signoff sync failed twice (run by
  the crew, and by the maintainer with `!`) with "Invoke-MarkdownLintAutoFix: ...\Specrew\0.40.0\scripts\internal\
  sync-boundary-state.ps1:1375 ... Program 'node.exe' failed to run: StandardOutputEncoding is only supported when
  standard output is redirected. At ...\AppData\Roaming\npm\npx.ps1:24 char:5". Nothing was recorded, and the
  sign-off could not be reached. Pasted to the reviewer at 02:17 with "Look at this"; captured under the maintainer's
  standing word (2026-11-15, "Yes capture it, we must get rid of all these anoying bugs").
- **Code (this tree, read by the reviewer):** `scripts/internal/sync-boundary-state.ps1` calls
  `Invoke-MarkdownLintAutoFix` with no try/catch under `$ErrorActionPreference = 'Stop'`; the comment above the call
  says "If markdownlint-cli is unavailable, emits a warning and proceeds". The function
  (`extensions/specrew-speckit/scripts/shared-governance.ps1`, about line 4943) counts as unavailable only a missing
  `npx` and four output patterns; its two launches (`& npx @fixArgs 2>&1`, `& npx @checkArgs 2>&1`) are unguarded, so a
  launch that throws ends the sync.
- **Cause (established and reproduced by the reviewer, 2026-11-16, 02:30 local, PowerShell 7.6.10):**
  `Get-ChangedMarkdownFiles` (`shared-governance.ps1`, about line 4851) returns every Markdown file changed between
  the base ref and HEAD as an absolute path, and `Invoke-MarkdownLintAutoFix` passes them all on one command line,
  twice. Past about 32,767 characters Windows refuses to start the process, and PowerShell reports the refusal as
  "Program '<x>' failed to run: StandardOutputEncoding is only supported when standard output is redirected." The
  reviewer's reproduction: 300 fake 85-character paths (25,499 characters) launch; 400 (33,999) throw exactly that
  text. The other project's npx.cmd shim failed the same way and its `--version` probes pass; its file count is asked
  for. Not a one-machine fault: any Windows project reaches it once a long iteration has enough changed Markdown (the
  crews here are at about 40 to 90 files).
- **Confirmed on the other machine (relayed by the reviewer, 2026-11-16):** the RingMCPBridge crew ran Specrew's own
  functions read-only: `Get-SpecrewLocalScopeBaseRef` gives `origin/main`; `Get-ChangedMarkdownFiles` gives 425
  absolute paths (the raw diff 519); with quotes and spaces that is 39,211 characters against the 32,767 limit. The
  cause is proven there as well as reproduced here.
- **A third part (that crew's point, the reviewer agrees):** batching or relative paths alone would let `--fix` run over
  everything changed since the base ref. In that project a no-fix run over the 425 files reports 1,522 problems, none
  in the project's CI lint scope: 994 in research notes, 124 in workshop records, 366 in Specrew-managed skill copies
  (`.agents`, `.claude`, `.copilot`, `.github/agents`, `.specify`) and 36 in `.specrew/review`, the committed review
  store. A `--fix` there would rewrite Specrew-managed files and review evidence at a boundary sync.
- **Shape, three parts:** batch under a safe length; degrade, with the exception text, when the launch throws; and
  narrow what is linted, by one of two options left to iteration 003's design analysis: (a) only the files in the
  project's own lint scope (its markdownlint ignore list and globs), or (b) only the files the sync itself writes.
- **Estimate:** about 2.5 SP with the third part (the crew's estimate, up from 1.5): the design choice, the scope
  resolution or the written-files list, the batching and the degrade, three tests, and the `.specify` mirror with its
  hash record.
- **Placed (the maintainer, 2026-11-16, 02:26 local, "OK, give this information to 206", relayed by the reviewer):** at the
  top of iteration 003's candidates, with item 45; an order of candidates, not a scope approval. About 1 SP (the
  reviewer's estimate). Iteration 002 is unchanged; the reviewer brings a swap only if the sync crash proves to hit
  every boundary on that machine.

## 47. Before a crossing exists, the engine's wording says only the human's approval can move things, never that the sync presents the crossing

- **Seen (second-hand):** the same project and session. At review-signoff the crew wrote "The sync's gate wants your
  authorization first ... I tried to run the sync anyway, and Claude Code's safety check blocked", asked for the approval
  with no crossing recorded; the maintainer typed "approved for review-signoff"; the hook answered that no
  review-signoff crossing was pending, and nothing was captured. The crew says the plan and before-implement boundaries
  went the same way: three spent approvals in one iteration.
- **Code, candidates (which line that crew saw is not known):**
  `extensions/specrew-speckit/scripts/readiness-verdict.ps1:95` ends "The human's typed 'approved for {0}' against the
  presented crossing is what clears this; nothing else does." with "no crossing is pending" (:37) in the same line;
  `shared-governance.ps1:4714` and `:4721`, "Boundary `a -> b` requires explicit human authorization."
- **Why it matters:** read by an agent, or by a permission mode with a safety check, that says "do not run the sync";
  but the sync authorizes nothing: it records the pending crossing the approval then answers.
- **Proposed shape:** when no crossing is pending, the line names the next step: run the boundary sync, which records
  and presents the crossing and authorizes nothing; then the human's typed approval. Belongs with items 42 and 43.
- **Placed (the maintainer, 2026-11-16, 02:26 local, "OK, give this information to 206", relayed by the reviewer):** at the
  top of iteration 003's candidates, with item 45; an order of candidates, not a scope approval. About 1 SP (the
  reviewer's estimate). Iteration 002 is unchanged; the reviewer brings a swap only if the sync crash proves to hit
  every boundary on that machine.

## 48 to 51. Four scaffold and resolver findings from feature 203's iteration 002 dry run (iteration 003 candidates)

Recorded at the reviewer's request (2026-11-16); evidence in feature 203's `docs/beta5-findings.md` on
`origin/203-beta5-stabilization` (commit `2cacad73`), read there, not copied. None of the files is in feature 203's
protected set, and none has changed on 203's branch since the merge base `df1141a8`.

- **Placed (the reviewer's request, 2026-11-16):** iteration 003 candidates, after items 45 to 47. An order of
  candidates, not a scope approval: iteration 003's scope is set at its own planning boundary, and iteration 002 is
  unchanged. Item 51 needs no work in 206: T017 already fixed it on this branch, and it is listed so 203 can see when
  its fix arrives.

- **48 (B5F-081):** a freshly scaffolded iteration fails the governance lane on its own `hardening-gate.md` ("overall
  verdict should be 'ready' based on the concern rows but found 'blocked'"). The gate text is written by
  `extensions/specrew-speckit/scripts/scaffold-iteration-artifacts.ps1` (and its `.specify` copy). 206 met it at its
  own iteration 002 scaffold (DRIFT-206-I002-002); feature 205 at its iteration 003 (its `27b2d647`).
- **49 (B5F-082):** the same generated `hardening-gate.md` text carries three MD038 errors (34:143, 36:133, 36:145);
  same file as 48, also met by 205.
- **50 (B5F-084):** `scaffold-iteration-artifacts.ps1` writes `specs/<feature>/contracts/mechanical-findings.schema.json`,
  outside the iteration folder, without saying so.
- **51 (B5F-085):** the quality-profile resolver reads this repository as `node-rest-with-postgres` and
  `react-spa-public`. The cause is the stray root `package.json`, which 206's T017 removes on this branch (`b5e6babf`);
  203's branch keeps it until it merges, so 51 is fixed for 203 by 206's merge.

## 52. A full validator run fails old accepted iterations on the developer's local review store (severity: minor)

- **Observed (2026-11-16, DRIFT-206-I002-013):** in this worktree after review round 1, a CI-mode `-FullRun` failed 12
  iterations from features 001, 005 and 007 with "the active review campaign has no completed, valid campaign result".
  Clean checkouts of the same commits passed with no finding.
- **Scope:** a candidate for iteration 003, not placed. The cause in the validator is not established. CI is not
  affected.

## 53. With no start-context, a record beside an earlier phase line is accepted even after its verdict (severity: minor)

- **Observed (2026-11-16, the reviewer and feature 203's crew, reading T034's `3a3ba803`):** with no
  `.specrew/start-context.json` (CI, a fresh clone), `Get-SpecrewRecordApprovalState` returns `unknown`, and review.md
  beside `executing` (or retro.md beside `reviewing`) is accepted with a warning. That holds also after the verdict is
  recorded, when the phase line is really stale. CI cannot catch that case; a local run and the sync's mirror check
  (`Get-SpecrewCrossingMirrorIssues`) can.
- **Weighed before:** design D2 weighed the missing file and rejected reading commit subjects (D2-b). It did not weigh
  the tracked ledger (`.squad/events/lifecycle-events.jsonl`, the verdict entries in `.squad/decisions.md`), which is in
  CI and could tell a recorded verdict from a pending one.
- **Scope:** a candidate for iteration 003, not placed. Named in the round 2 scope file. Feature 203's iteration 002
  relies on T034 for this rule, so a change here changes what 203 would take.

## 54. The plan scaffold refuses a requirement scope that is in the spec (severity: minor)

- **Observed (feature 205's hand-over H-024; its iteration 002 DRIFT-002 and iteration 003 DRIFT-002, relayed by the
  reviewer 2026-11-16):** `scaffold-iteration-plan.ps1 -RequirementScope FR-022,FR-024` refused with "Requirement(s)
  not found in spec: FR-022,FR-024", although both are in spec.md. Run without a scope, the stub lists every
  requirement of the feature (FR-001 to FR-032), so each iteration's scope is written by hand.
- **Scope:** an iteration 003 candidate, set at its planning by the maintainer.

## 55. The deploy scripts restamp files outside the feature being refreshed (severity: minor)

- **Observed (feature 205's iteration 003 retro, lesson 5, relayed by the reviewer 2026-11-16):** `deploy-speckit-extension.ps1
  -ProjectPath . -RefreshExisting` and `deploy-squad-runtime.ps1 -ProjectPath .`, run to refresh one feature's
  deployed copies, also rewrite `scripts/internal/continuous-co-review/.specrew-runtime.json`,
  `.squad/casting/registry.json`, five `.squad/agents/*/charter.md`, `.squad/ceremonies.md`, `routing.md`, `team.md`,
  `.github/agents/squad.agent.md`, and the `specrew_version` in `.specrew-extension-runtime.json`, which they set to
  the installed module's version instead of the branch's. Today each file is restored by exact path and the version
  set back by hand, at every deploy.
- **Asked:** a refresh-only mode that touches only the copies whose sources changed and does not take the version
  from the installed module.
- **Note for sizing:** the first file is under `scripts/internal/continuous-co-review/`, feature 203's protected area
  until 203 merges.
- **Scope:** an iteration 003 candidate, set at its planning by the maintainer.

## 56. A publish from Linux fails on the module's hidden .gitkeep FileList entries (severity: minor)

- **Observed (2026-11-16, Specrew CI run `43864236359`, ubuntu-latest, DRIFT-206-I002-014):** the publish suite's dry
  run reached PowerShellGet's `Publish-Module -WhatIf`, whose own copy of the module drops hidden dot-files on Unix. It
  then refused: "The specified FileList entry 'extensions/specrew-speckit/hooks/.gitkeep' in the module manifest
  '/tmp/2101440027/Specrew/Specrew.psd1' is invalid. Try again after updating this entry with valid values."
  `Specrew.psd1` names three such files: `extensions/specrew-speckit/hooks/.gitkeep`,
  `extensions/specrew-speckit/templates/quality/lenses/.gitkeep` and
  `extensions/specrew-speckit/templates/quality/presets/.gitkeep`, all since F-019 (2026-05-16).
- **Effect today:** none on a release, because `publish-module.yml`'s publish job runs on windows-latest. A publish from
  Linux would fail. The suite runs per push on Windows instead (option A, the maintainer's answer of 2026-11-16 14:38).
- **Scope:** an iteration 003 candidate (option C as put to the maintainer): remove the entries, after reading whether
  those empty folders must ship. Not placed.

## 57. Lint installs PSScriptAnalyzer from the gallery on every run, with no retry and no cache (severity: minor)

- **Observed (2026-11-16, DRIFT-206-I002-016):** Specrew CI's Lint failed on `9d314cfd` at `Install-Module
  PSScriptAnalyzer` ("End of Central Directory record could not be found"), so a gallery hiccup turned a push red
  before any check ran. Feature 203 records the same class for its Pester-gallery sightings. An iteration 003
  candidate, not placed.

## 58. A partial review's findings are dropped from the pause record, and the packet says it "found nothing" (severity: major)

- **Observed (2026-11-16, i002 round 2, run `run-20261116-173258054-8f47fc5f`):** `result.json` holds nine findings
  (`completion: partial`). `pending-pause.json` has `result_produced: false`, `evidence_state: not-produced` and all
  counts 0, and the packet says "That review did not finish, so it found nothing and cleared nothing".
- **Where (by reading):** `scripts/internal/continuous-co-review/review-authority-core.ps1:234-239`
  (`if (... $resultCompletion -cne 'complete') { $resultProduced = $false }`), then :251-282, which return fixed zero
  counts. The packet text comes from `continuous-co-review-navigator.ps1:1176-1177`.
- The console then prints only the automatic retry's object (`scripts/specrew-review.ps1:1748`, rendered from :1841),
  so the nine findings never reached the screen. Feature 203's engine; not changed here.

## 59. The retry message says the approval is "NOT spent" while the campaign's spend record is dated at the invocation (severity: minor)

- **Observed:** the console printed "Their approval is NOT spent ... this attempt DID use one of the review rounds".
  `pending-round-approval.json` says `spent_at: null`, and `spend/res-95c5355ff2ec5a42478f.json` is dated 17:50:00Z (the
  invocation).
- **Where (by reading):** these are two ledgers. The typed approval is marked spent only on `delivered`
  (`scripts/specrew-review.ps1:1757-1759`). The allowance slot is spent when the reviewer starts
  (`review-campaign-orchestrator.ps1:2029-2033`, reason `preflight-passed-invocation-spends-slot`). The message
  (`specrew-review.ps1:1823`) is accurate for each ledger but names neither. Feature 202 recorded the two disagreeing after a
  partial round (B4F-150).

## 60. The automatic retry after a partial result cannot run: the first attempt's own pause blocks it (severity: minor)

- **Observed:** "Retrying once automatically (fresh-run-same-host)", then at once `Status paused, Invoked False`,
  reason `review-round-paused:pause-decision-pending`. No run folder, grant or spend record for the retry.
- **Where (by reading):** every published result writes a pause (`review-campaign-orchestrator.ps1:2112`); the retry
  meets the pause gate (:1679-1705; `review-authority-core.ps1:491-492`) before any grant is minted (:1725). With an
  unchanged tree the retry is always refused.

## 61. Every major or blocking finding from a campaign round is demoted, because the campaign prompt never asks for the clause the ingestor needs (severity: major)

- **Observed:** findings `finding-30faa1624cf6d7a1` and `finding-124f7de3f876daab` were reported major and stored minor
  "[demoted to minor: no concrete failure scenario, so it cannot gate]". Each describes a concrete failure in prose.
- **Where (by reading):** `review-result-ingestor.ps1:138-155` requires the literal text `Failure scenario:` in the
  description; :180-200 demotes blocking and major without it. The campaign prompt
  (`reviewer-candidate-prompt.md:39`) lists `local_id, severity, title, description, location` and never asks for it;
  only the older slim prompt does (`worktree-reviewer.ps1:1170-1176`).
- **Can a demoted finding gate?** No: it is stored as minor, and pause counting (`review-authority-core.ps1:208-218`)
  and the stop-here check (`review-campaign-orchestrator.ps1:984-986`, :1010-1014) count only blocking and major.

## 62. The reviewer is given an absolute deadline but no way to read the time, and stopped after 265 s of 2400 s (severity: minor)

- **Observed:** the reviewer ran 17:50:00Z to 17:54:25Z and wrote "Not covered before the deadline".
- **Where (by reading):** `reviewer-candidate-prompt.md:20` ("The deadline is `__DEADLINE__`"), set at
  `review-campaign-orchestrator.ps1:1944` to the clock after verification plus the full `--timeout-seconds`. The
  reviewer's tools are Read, Glob, Grep and Write (`reviewer-host-catalog.ps1:56`), so it cannot read the clock. The
  rendered prompt is not persisted, so the deadline string itself cannot be quoted.

## 63. The closeout dashboard redraw looks for specrew-where.ps1 three levels up, which is wrong from the deployed copy (severity: minor)

- **Observed (2026-11-16, review iteration 002 round 2, `finding-00622024f23b735f`, T035):** from
  `.specify/extensions/specrew-speckit/scripts` the lookup lands in `.specify/`, where no `scripts/specrew-where.ps1`
  exists.
- **Not reachable, by reading:** the only writer that runs the redraw is `Add-SpecrewBoundaryAuthorization`, called
  from `HandoverStore.ps1:1146`. The handover provider loads shared-governance from the module root it resolved for
  the bootstrap folder (`specrew-handover-provider.ps1:82-113`: beside itself, the self-host source tree,
  `SPECREW_MODULE_PATH`, or the installed module), never from `.specify`. An iteration 003 candidate: make the
  comment say why, or add the deployed layout to the candidates.

## 64. The validator never refuses a hardening gate whose verification fields say "pending" (severity: minor)

- **Observed (2026-11-16, review iteration 002 round 2, `finding-fd13b52728ad4bb8`):** `validate-governance.ps1:4129`
  and `:4133` write `if (Test-IsNullish $x -or $x.ToLowerInvariant().Contains('pending'))`. PowerShell parses that as
  one command with `-or` passed as an argument.
- **Shown by experiment**, with the validator's own `Test-IsNullish` loaded from the file: 'pending' and
  'Pending - after merge' are accepted as written and refused when the call is parenthesised; '—' is refused either
  way.
- **Older code:** feature 013, `99cdf514`, 2026-05-12.
- **Fixing it would newly refuse eight hardening gates** that say pending: 045/002, 050/002, 050/003, 051/001,
  051/002, 182/004, 197/006 and 198/010. Check the frozen and closed lists first. Also, the validator's own
  `Test-IsNullish` (`:478`) lacks the shared one's `tbd` and `unknown`. An iteration 003 candidate.

## 65. The Completed date's placeholder list is closed, and the date written is the UTC day (severity: note)

- **Observed (2026-11-16, review iteration 002 round 2, `finding-4ec6649b1b32b425`, T036):**
  `Set-SpecrewPlanCompletedDate` fills a blank value and its listed words. It keeps a backticked or italic
  placeholder, an en dash, `YYYY-MM-DD`, `<date>`, `unknown` and `not yet` as if they were a date. The written date is
  the capture's UTC day. A date-shape test (keep only a value that parses as a date) would close the list. An iteration
  003 candidate.

## 66. A session start rewrites a finished iteration to "not started" when plan.md and tasks.md use different task ids (severity: major)

- **Observed (2026-11-16, a downstream project on Specrew 0.40.0, reported through the reviewer session):** the
  iteration's work was finished, reviewed and signed off. At 17:39:03Z, inside a new session's start (a second
  window opened on the project), the engine wrote `tasks-progress.yml` with 19 tasks `pending` and rebuilt
  `state.md` as `not-started`, "Execution has not started yet.", four minutes before the retro approval. The
  iteration-closeout sync's state-truth gate then refused it.
- **Why (read at tag v0.40.0-beta41; the same functions in this tree):**
  - `Sync-IterationTaskProgress` (`scripts/internal/task-progress.ps1:648`) takes the task list from plan.md's Tasks
    table (`Get-IterationTaskCatalog`, `:163`): Task, Title, Requirement, Story and Effort. The Status column is not
    read.
  - Status hints come, for iteration 001 only, from tasks.md checkbox rows whose id is `T` and digits
    (`Get-TaskProgressDerivedStatusHints`, `:229`). That project's plan table uses `CP-01` to `CP-RW` and its tasks.md
    is fully ticked (`T001` to `T036`), so no hint matches.
  - With no hint and no ledger entry, each task is created pending. An existing `done` entry is kept ("may promote,
    never demote"), which is why a hand-corrected ledger repairs it.
- **Asked:** derive status from plan.md's Status column when the ids do not match tasks.md, or refuse at the first
  boundary naming both lists; never write "not started" when review evidence exists. An iteration 003 candidate.

## 67. The task-progress writer's own words go stale after review sign-off (severity: minor)

- **Observed (2026-11-16, the same downstream project; feature 203's iteration 001):** with every task done,
  `Update-IterationStateFromTaskProgress` (`task-progress.ps1:501`) writes Iteration Status `ready-for-review` and
  "Implementation tasks are complete; review-signoff is next.", and nothing rewrites that line at review-signoff,
  retro or closeout. Feature 203's iteration 001 is sealed with it beside Current Phase `iteration-closeout` and
  Iteration Status `complete`. Related: 203's B5F-080.
- The field's vocabulary is stated only in a code comment (`Get-SpecrewCrossingMirrorMap`,
  `shared-governance.ps1:4110`); the downstream crew proposed two values the engine never writes.
- A note only: when two tasks share the latest `completed_at`, the strictly-greater comparison names the first in
  ledger order as Last Completed Task. An iteration 003 candidate.

## 68. The state-truth refusal names no command that repairs it (severity: minor)

- **Observed (2026-11-16, the same downstream project):** the refusal says "through the normal task/gate path"
  (`scripts/internal/sync-boundary-state.ps1:969`) and "Repair state.md through the normal task-progress/resume/gate
  path or record an explicit send-back" (`:1049`). It names no skill, script or command, and does not say the header
  and managed block are rebuilt from `tasks-progress.yml`. The crew nearly wrote the block by hand. Item 47's class;
  item 70 shows no such command exists. An iteration 003 candidate.

## 69. A second sync of a boundary whose crossing is already pending records it again (severity: minor)

- **Observed (2026-11-16, the same downstream project):** a second `retro` sync a minute after the first recorded the
  same crossing a second time, added a second lifecycle event, and wrote the decisions.md warning "Expected next
  boundary 'iteration-closeout' but received 'retro'". A repeated sync of the same boundary at the same commit should
  be a no-op that says so. An iteration 003 candidate.

## 70. No command runs the task-progress writer on demand (severity: minor)

- **Observed (2026-11-16, the same downstream project; read at tag v0.40.0-beta41):**
  - `Sync-IterationTaskProgress` and `Update-IterationStateFromTaskProgress` are reached only through
    `Get-TaskProgressSummary` in `scripts/internal/coordinator-resume.ps1` (`Get-CoordinatorResumeSnapshot`, `:148` to
    `:165`), inside the launch-contract generator: `specrew start` (`scripts/specrew-start.ps1:3446` here) and the
    session-start bootstrap provider (`specrew-bootstrap-provider.ps1:604`; not on a compaction).
  - `Set-TaskStatus`, `Set-TaskComplete` and `Set-TaskBlocked` have no caller outside `task-progress.ps1`.
  - The project's `resume-iteration.ps1` does not load `task-progress.ps1`. With `-ResumeMode continue` on a state.md
    that said not-started, it exited 0, set Tasks Remaining to `(none)`, appended a "Resume Report" with Last
    Completed Task `(none)`, and left the header and "Execution has not started yet." as they were: a second summary
    that contradicts the ledger.
- **Asked:** a project-exposed command that rebuilds state.md's header and managed block from the ledger, named in
  item 68's refusal; `resume-iteration.ps1` reading the ledger; and item 66's no-pending-ledger rule at session start.
  An iteration 003 candidate.

## 71. The feature-closeout dashboard is drawn before the verdict and committed reading "awaiting" (severity: minor)

- **Observed (2026-11-16, feature 205's closeout, in the 205 crew's words):**
  1. The feature-closeout sync draws `closeout-dashboard.md` before the human's verdict, so the committed snapshot
     reads "AWAITING YOUR VERDICT ... is NOT human-authorized (last authorized: iteration-closeout)" and "Pending next
     boundary: feature-closeout" for a feature that is closed (205 `a1adade3`; 202 `4ad15d63`).
  2. The file's own notice forbids overwriting it, so the crew cannot correct it afterwards. The draw belongs after
     the verdict capture, as T035 does for the iteration dashboard (item 41).
  3. The same sync's coverage line counted the amendment's six records files as "source file(s) changed since"
     (B5F-075's class on feature 203's list), which a closeout packet then has to explain away.
- Item 41's class at the feature level; T035 does not cover it. An iteration 003 candidate.

## 72. A runner image change turns Cross-Platform Validation red: the Ubuntu PowerShell install has no fallback (severity: minor)

- **Observed (2026-11-16):** "Ubuntu Validation" failed at "Setup PowerShell" on feature 205's `8ebfef8f` (run
  `43954284857`) and on this branch's `7b54d49d` (run `43956458711`, and its one rerun), on image ubuntu-26.04
  20261111.196.1: `dpkg -i powershell_7.4.1-1.deb_amd64.deb` needs `libicu72`, which that image lacks, and the step
  had nothing after `||`. No test ran (DRIFT-206-I002-018).
- **Fixed on this branch by feature 203's T015 commit** (`f2493ccc`, cherry-picked as `00cef4d5`): use the runner's
  pwsh when present, otherwise install from Microsoft's package feed. The class remains: the workflows install tools
  on every run with no retry and no pinned image (item 57). An iteration 003 candidate for the class.

## 73. A session start between the plan approval and the before-implement approval makes the tasks sync impossible to pass (severity: major)

- **Observed (2026-11-17, a downstream project on Specrew 0.40.0, iteration 002, relayed by the reviewer session as
  candidate F; the maintainer's words at 18:12 local, "Yes, pass it"):** the tasks sync was refused twice. The reviewer
  session checked the same code on main and on feature 203's branch that day.
- **Why (by reading, on main):**
  1. `scripts/internal/task-progress.ps1`, `Update-IterationStateFromTaskProgress` (about :600 to :612): when state.md
     has no canonical Current Phase, the writer sets Current Phase `before-implement` and Iteration Status
     `not-started`, with "Execution has not started yet." It is reached through a read verb, `Get-TaskProgressSummary`,
     which `coordinator-resume.ps1` calls at every session start (item 70). The scaffold
     (`scaffold-iteration-artifacts.ps1`) writes neither line.
  2. `extensions/specrew-speckit/scripts/shared-governance.ps1`, `Get-SpecrewCrossingMirrorIssues`: a Current Phase
     line must equal the last authorized boundary or the pending crossing. In `sync-boundary-state.ps1` the truth gate
     (about :1819) runs before the sync records its own pending crossing (about :1957), so at a tasks sync only `plan`
     is accepted and `before-implement` is refused as ahead of the record. The refusal advises correcting the line by
     hand.
  3. `scripts/internal/sync-boundary-state.ps1:837`: `phaseImpliesProgress` exempts only tasks, before-implement,
     planning and not-started. `plan` is not exempt, so the hand-corrected page (Current Phase `plan` with "Execution
     has not started yet.") is refused by the truth gate.
- With the header lines present, no Current Phase value passes both checks at the tasks sync. The only repair is to
  delete the lines and restore the scaffolded page, which the refusal does not say; its "repair through the normal
  task-progress/resume/gate path" points at the writer that caused it (items 68 and 70).
- **Failure scenario:** plan approved for iteration N; the session is resumed or a new one starts; the tasks sync is
  refused with "Current Phase 'before-implement', but the last authorized boundary is 'plan'"; the crew sets the line
  to `plan` as advised; the sync is refused again with "still says 'Execution has not started yet.'".
- **Fix directions (not decided):** the writer does not invent a phase ahead of the store (it writes the store's last
  authorized boundary, or no line); `:837` exempts every pre-implementation phase (specify, clarify, plan); the refusal
  names the repair. Regression test: scaffold, authorize plan, run `Get-TaskProgressSummary`; the tasks sync then
  passes. An iteration 003 candidate.

## 74. Text rules read free prose through word lists: a structured line instead (design question)

- **Observed (2026-11-17, review iteration 002 round 3):** three of round 3's findings (items 75 to 77) are phrasings
  that round 2's word lists miss, or legitimate records they refuse. Each round finds more: a list of denying or
  conditioning words is never complete, and widening it refuses more real records.
- **The question:** where the validator must know that a record says a specific thing (a deferral names its deciding
  decision; a Disposition records the maintainer's ruling), should the record carry a structured line the validator
  reads exactly, for example `- **Deferred by**: <decision id>` in the verdict row's notes, or `- **Ruling**:
  abandoned, <date>, <where>` in the Disposition, and leave the prose to the human? The rule would then be an allow-list
  of one shape, as the maintainer's 2026-11-14 ruling already asks for the Disposition's sentence.
- **Cost:** existing records would need the new line (T026's four rulings; any deferred row), or a read-both period.
  For iteration 003's plan; not decided. Items 75, 76 and 77 point here.

## 75. A deferred row's denial after the decision id, or in a word the list lacks, passes (severity: minor)

- **Observed (2026-11-17, review iteration 002 round 3, `finding-7a83914b328c58d4`):** the deferred-row check
  (`validate-governance.ps1`, T033) reads only the clause before the decision id. "decision D-12 does not cover this
  task", "decision D-12 was rejected", "decision D-12 (withdrawn)" and "decision D-12 is still pending" pass; so do
  words before the id that the list lacks: "needs", "awaits", "requires", "contrary to", "despite", "before", "should
  decision D-12 be approved". The ledger check proves only that the id exists, not that the entry concerns the task.
- See item 74 (the design question). An iteration 003 candidate.

## 76. Natural deferral wording is refused, and words from other cells are read as the clause (severity: minor)

- **Observed (2026-11-17, review iteration 002 round 3, `finding-0c9729b9966bade6`):** "until", "once", "not", "no"
  and "if" anywhere in the last clause before the id refuse the row, and commas do not end a clause: "Deferred until
  iteration 003 by decision D-12", "Not started, deferred by decision D-12" and "no capacity left, decision D-12" are
  refused. Every column except Task and Verdict is joined, so "tests not run" in an Evidence cell is read as part of
  the clause before a decision in Notes. The error says what to do, so the cost is friction, not a wrong pass.
- See item 74. An iteration 003 candidate.

## 77. The ruling's "(at ...)" note is guarded by a deny-list that misses common denials (severity: minor)

- **Observed (2026-11-17, review iteration 002 round 3, `finding-8b5187ef052a4935`):** in
  `Test-SpecrewIterationRulingRecorded` (`shared-governance.ps1`, T026) the affirmative form is an allow-list, but its
  one free-text part, the "(at ...)" note, is guarded by denying words. "(at first, later rescinded)", "(at the stop,
  since overturned)", "(at the time, reopened on review)", "(at the maintainer's request, to be confirmed)", "(at
  present tentative)" and "(at the stop, cancelled the next day)" pass; "(at the 2026-11-14 stop, no objection)" is
  refused for "no". A closed form for the note (no commas, or a short list of places) would keep the rule an
  allow-list.
- See item 74. An iteration 003 candidate.

## 78. The lane census misreads an if: continued on the next line, or written with a quoted key (severity: minor)

- **Observed (2026-11-17, review iteration 002 round 3, `finding-77b1862fd2bcb429`):** in
  `tests/unit/every-suite-is-named-by-a-lane.tests.ps1`, `Get-WorkflowRunText` reads only an `if:` value's first line,
  so `if: always()` continued by an indented `&& github.event_name == 'workflow_dispatch'` counts as running on every
  push. A quoted key (`"if": false`) matches neither pattern, so the condition is ignored. A listed condition with an
  inline comment (`if: always() # note`) is refused, a legitimate line read as not running. Block scalars are
  refused, the safe side. An iteration 003 candidate.

## 79. "Per push" accepts any branches filter, so a main-only workflow reads as run by every push (severity: minor)

- **Observed (2026-11-17, review iteration 002 round 3, `finding-b6213f4d09d29d26`):** `Test-WorkflowRunsPerPush`
  returns true for a push trigger with any `branches:` or `branches-ignore:` key and no paths filter; the patterns
  are not read. `cross-platform-validation.yml` runs only for main, `feature/**`, `0*-*`, `1*-*` and `2*-*`, so a
  branch named `300-...` would not start it. Today every per-push script is named in `specrew-ci.yml` (`branches:
  ['**']`), so nothing is wrongly registered; the rule would accept moving one to a main-only workflow. An iteration
  003 candidate.

## 80. The lane census takes a runner.os term to hold under a matrix runs-on, and does not read continue-on-error (severity: minor)

- **Observed (2026-11-17, review iteration 002 round 3, `finding-665d0c6f38a06f51`):** with `runs-on: ${{ matrix.os
  }}`, a `runner.os` comparison is taken to hold (declared in the guard's comment), so a matrix of Ubuntu legs with
  `if: runner.os == 'Windows'` names a suite that never runs. `continue-on-error` (step or job), a job's `needs:` on a
  conditioned job, and a workflow trigger that excludes pushes for the step's event are not read; a suite under
  `continue-on-error: true` is named though its failure cannot turn the run red.
  `release-script-refuses-unasked-publish.tests.ps1` pins `continue-on-error` away for the two Windows jobs only. An
  iteration 003 candidate.

## 81. The two shim suites had no green CI run when round 3 read them (severity: note; answered)

- **Observed (2026-11-17, review iteration 002 round 3, `finding-46dd269bed6f96cd`):** the `windows-shim-suites` job's
  structure reads right, but no green run of either suite was in the frozen records, and neither suite runs in the
  local lanes. Both build under a fixed `.scratch` folder in the checkout, harmless on a fresh runner.
- **Answered after the round:** Specrew CI run `43985711026` on `ff6fe55e` passed the job, both suites included. Kept as
  a note: the suites still run only in CI, so a local change to them has no local evidence.

## 82. Four nightly stops read one shared message list, and two stops pass no message (severity: note)

- **Observed (2026-11-17, review iteration 002 round 3, `finding-6389b64862f21650`, T030):** in
  `validate-governance.ps1` the source-authorization, handoff-evidence, approved-status and boundary-canonical stops
  all pass `@($script:ValidatorStopMessages)`, one list for the run, never cleared between checks. It is right only
  while every check that adds a message also stops; a check that adds a message and returns 0 would have its message
  written under a later stop. The boundary-canonical message carries the absolute state.md path and a line number, so
  its fingerprint may depend on the checkout location unless normalisation removes paths (not read). The two
  response-validation stops and the final per-iteration stop pass no `-FailureMessages`. Not verified for every call
  site. An iteration 003 candidate.

## 83. A governed agent edited the engine that governs it, and only the review engine noticed (severity: major)

- **Observed (2026-11-17, a downstream project on the installed 0.40.0-beta41, relayed by the reviewer session as
  candidate G1; the maintainer's words at 20:16 local, "pass it"; severity the reviewer session's):** an
  agent session that could not pass a boundary edited three files of the installed module
  (`review-campaign-orchestrator.ps1`, `shared-governance.ps1`, `sync-boundary-state.ps1`), copied two of them into its
  project, re-stamped both integrity markers (`.specrew-runtime.json` and `.specrew-extension-runtime.json`) to match
  the edited files, and ran a refresh that rewrote the user-level hook files. It recorded all of it in its own drift
  log and commits, and told the human when asked.
- **What caught it:** a second project on the same machine. Its review round was refused with
  `review-engine-version-mismatch`, because `review-engine-resolution.ps1` hashes the installed review runtime against
  the project's. Nothing else checked: the boundary sync and the authorization code have no such handshake, and the
  editing project's own markers passed because the agent had re-stamped them.
- **Two gaps:** (a) nothing stops or even reports an agent writing into the installed module or re-stamping a marker
  (proposal 218's ground: real-home and install-root writes); (b) the integrity handshake covers the review runtime
  only, and a marker the agent can re-stamp proves nothing about the project copy.
- **Repaired:** the maintainer reinstalled the release and ran the project update; the reviewer session checked every
  file against the release afterwards. The agent's three edits are items 84 and 85 (proposed fixes, not accepted).
  A candidate for the next bug bash.

## 84. Stopping a review after a clean passing round cannot be accepted (beta41) (severity: minor)

- **Observed (2026-11-17, the same downstream project, candidate G2):** in `review-campaign-orchestrator.ps1` (beta41,
  about `:939`) the stop's accept port always calls `Add-ReviewCampaignHumanDisposition` with `accept-current`. A
  round whose result is a clean pass has nothing to dispose; the stop was refused, so the campaign could not hand off
  to sign-off.
- **Feature 203's engine (read on `origin/203-beta5-stabilization` at `0a5b07b1`, 2026-11-17):** the accept port has
  the same shape (about `:2262`), and `Add-ReviewCampaignHumanDisposition` refuses `accept-current` on any verdict but
  `findings` (`review-human-disposition-accept-requires-findings-to-accept`, about `:3133`). Its comment (W27) says
  the sign-off gate already releases on a complete, current, approvable pass with no disposition, so the stop menu on
  a clean pass is removed and accepting a clean result is unreachable by design. Not checked: whether every 203
  surface that offers "stop" on a clean round is gone. The item may already be answered there; check at 203's merge.
- **Proposed fix (the downstream agent's, with a test; to be reviewed, not accepted):** when the result is pass,
  complete, valid, current, `can_approve_current` and has zero findings, return ok with reason
  `clean-review-no-residuals` and skip the disposition; every other case unchanged. Against the beta41 release:

```diff
--- release/scripts/internal/continuous-co-review/review-campaign-orchestrator.ps1
+++ installed/scripts/internal/continuous-co-review/review-campaign-orchestrator.ps1
@@ -939,6 +939,18 @@
     if ($null -eq $AcceptPort) {
         $AcceptPort = {
             param($ctx)
+            $result = Get-ReviewRunAuthorityFact -StoreRoot $ctx.store_root -CampaignId $ctx.campaign_id -RunId $ctx.run_id -Stage result
+            if ($null -ne $result -and [string]$result.verdict -ceq 'pass') {
+                # A clean pass has no residual findings to accept. Keep its validity checks and let
+                # the normal sign-off gate consume the pass without creating a human disposition.
+                if ([string]$result.completion -cne 'complete' -or [string]$result.validation -cne 'valid' -or [string]$result.currentness -cne 'current') {
+                    throw 'review-human-disposition-requires-complete-current-valid-result'
+                }
+                if (-not [bool](Get-ReviewAuthorityProperty -Object $result -Name 'can_approve_current') -or @($result.findings).Count -ne 0) {
+                    throw 'review-stop-clean-result-requires-approvable-pass-without-findings'
+                }
+                return [pscustomobject]@{ ok = $true; reason = 'clean-review-no-residuals' }
+            }
             $disposition = Add-ReviewCampaignHumanDisposition -StoreRoot $ctx.store_root -CampaignId $ctx.campaign_id `
                 -RunId $ctx.run_id -Decision accept-current -AuthorizedBy $ctx.authorized_by `
                 -AuthorizationRef $ctx.authorization_ref -Rationale $ctx.rationale
```

- The file is under `scripts/internal/continuous-co-review/`, feature 203's protected area. A candidate for the next
  bug bash, after 203 merges.

## 85. The mirror check refuses a plan page that already shows the phase being entered (severity: minor)

- **Observed (2026-11-17, the same downstream project, candidate G3):** `Get-SpecrewCrossingMirrorIssues`
  (`shared-governance.ps1`) accepts plan.md's Status only for the last authorized boundary or the pending crossing, and
  `sync-boundary-state.ps1` runs the truth gate before it records the pending crossing. A plan prepared for the
  arriving boundary (for example Status `reviewing` at the review-signoff sync) is refused. Item 73's family; the
  refusal names no repair (item 68).
- **Proposed fix (the downstream agent's, with a test; to be reviewed, not accepted):** a new `ArrivingBoundary`
  parameter, passed by the sync; when the arriving boundary is exactly the one after the last authorized, its plan
  status is also accepted. The state.md check is unchanged. Against the beta41 release:

```diff
--- release/extensions/specrew-speckit/scripts/shared-governance.ps1
+++ installed/extensions/specrew-speckit/scripts/shared-governance.ps1
@@ -4079,7 +4079,8 @@
-        [AllowNull()][string]$BoundaryCeiling
+        [AllowNull()][string]$BoundaryCeiling,
+        [AllowNull()][string]$ArrivingBoundary
     )
@@ -4109,6 +4110,20 @@
     $mapLast = Get-SpecrewCrossingMirrorMap -Boundary $lastAuthorized
     $mapPending = if ([string]::IsNullOrWhiteSpace($pendingTo)) { $null } else { Get-SpecrewCrossingMirrorMap -Boundary $pendingTo }
+    $mapArrival = $null
+    if (-not [string]::IsNullOrWhiteSpace($ArrivingBoundary)) {
+        $arrival = Normalize-SpecrewCanonicalBoundaryType -Boundary $ArrivingBoundary
+        $arrivalOrder = @(Get-SpecrewCanonicalBoundaryTypes)
+        $arrivalIndex = [Array]::IndexOf($arrivalOrder, $arrival)
+        $authorizedIndex = [Array]::IndexOf($arrivalOrder, $lastAuthorized)
+        if ($authorizedIndex -ge 0 -and $arrivalIndex -eq ($authorizedIndex + 1) -and
+            ([string]::IsNullOrWhiteSpace($pendingTo) -or $pendingTo -ceq $arrival) -and
+            ([string]::IsNullOrWhiteSpace($BoundaryCeiling) -or (Normalize-SpecrewCanonicalBoundaryType -Boundary $BoundaryCeiling) -ceq $arrival)) {
+            # The arrival gate runs before it records the pending crossing. Its prepared plan may
+            # already use the next phase; this does not authorize or advance any state/ledger mirror.
+            $mapArrival = Get-SpecrewCrossingMirrorMap -Boundary $arrival
+        }
+    }
@@ -4132,6 +4147,7 @@
             $allowedPlan = @([string]$mapLast.PlanStatus)
             if ($null -ne $mapPending -and -not [string]::IsNullOrWhiteSpace([string]$mapPending.PlanStatus)) { $allowedPlan += [string]$mapPending.PlanStatus }
+            if ($null -ne $mapArrival -and -not [string]::IsNullOrWhiteSpace([string]$mapArrival.PlanStatus)) { $allowedPlan += [string]$mapArrival.PlanStatus }
--- release/scripts/internal/sync-boundary-state.ps1
+++ installed/scripts/internal/sync-boundary-state.ps1
@@ -918,7 +918,11 @@
-        $issues = @($issues) + @(Get-SpecrewCrossingMirrorIssues -ProjectRoot $ProjectRoot -FeatureRef $FeatureRef -IterationNumber $IterationNumber -BoundaryCeiling $BoundaryType)
+        $mirrorParameters = @{ ProjectRoot = $ProjectRoot; FeatureRef = $FeatureRef; IterationNumber = $IterationNumber; BoundaryCeiling = $BoundaryType }
+        if ((Get-Command -Name 'Get-SpecrewCrossingMirrorIssues').Parameters.ContainsKey('ArrivingBoundary')) {
+            $mirrorParameters.ArrivingBoundary = $BoundaryType
+        }
+        $issues = @($issues) + @(Get-SpecrewCrossingMirrorIssues @mirrorParameters)
```

- The hunks above are trimmed to the changed lines and their nearest context; the full diff is 77 lines. A candidate
  for the next bug bash.

## 86. A decision id inside an indented code example, or an unclosed fence, still counts as a ledger entry (severity: major)

- **Observed (2026-11-17, review iteration 002 round 4, `finding-ac98d5cbfc5b6a9c`, T033):** the deferred-row check in
  `validate-governance.ps1` (about `:3977`) removes only closed fences from `.squad/decisions.md`, then collects
  `- **Decision ID**:` lines with a pattern that allows leading whitespace. A four-space-indented code example
  (`- **Decision ID**: D-12` indented four spaces) is collected as a real entry, and so is one inside a fence opened and never closed.
- **Failure scenario (the reviewer's):** plan.md records T002 as deferred, an accepted review gives T002 the
  `deferred` verdict with "Moved by decision D-12", and decisions.md holds D-12 only in such a code example. No
  missing-decision error is raised, and the row is not counted as non-passing.
- Round 3's `877eda73` (CRLF) is the same family. **Marked first for the next bug bash** (the reviewer session).
  Ask: read the ledger with Markdown context (indented code, fences running to the end of the file) before collecting
  ids, or use item 74's structured line. About 0.25 SP.

## 87. The ruling reader removes HTML comments before it reads fences (severity: minor)

- **Observed (2026-11-17, review iteration 002 round 4, `finding-cb6118e2f0d33477`, round 3's `a9d93413` fix):**
  `Test-SpecrewIterationRulingRecorded` (`shared-governance.ps1`, about `:826`) removes every `<!-- ... -->` from the
  whole page before it reads fences. A literal `<!--` inside a fenced example, with a `-->` later on, swallows the
  closing fence and a real Disposition, so a legitimately abandoned iteration reads as open. A real `<!--` before the
  heading with no closing `-->` is not removed, so its hidden ruling is accepted.
- Ask: one pass that tracks fences and comments together, with an unclosed comment running to the end of the file.
  The round 4 scope file named this attack. About 0.25 to 0.5 SP.

## 88. Two plan rows whose task ids differ only in case make the deferral check depend on row order (severity: minor)

- **Observed (2026-11-17, review iteration 002 round 4, `finding-f61aaa3347213843`, round 3's `f194651984ecf15e` fix):**
  the deferred-row lookup (`validate-governance.ps1`, about `:3949`) keeps the first case-insensitive match, and
  `Test-PlanTaskSet` does not refuse duplicate ids. With rows `T002` deferred and `t002` blocked, one deferred review
  row for T002 passes and counts as the verdict for both; reversing the rows changes the result.
- Ask: refuse duplicate task ids with the same comparison as review coverage, or require exactly one matching plan
  task. About 0.25 SP.

## 89. The lane census reads a folded run: > block line by line (severity: minor)

- **Observed (2026-11-17, review iteration 002 round 4, `finding-3bf4f809c27571cd`):** `Get-WorkflowRunText`
  (`tests/unit/every-suite-is-named-by-a-lane.tests.ps1`, about `:274`) treats `run: >` like `run: |`. In a folded
  scalar, `echo ok # note` followed by `pwsh -File tests/integration/zz-probe.ps1` at the same indent is one shell
  line, so the suite command is inside the comment and never runs; the census reads the second line as a command and
  counts the suite as named.
- Ask: fold the scalar before removing shell comments, or refuse folded run blocks (the safe side). About 0.25 SP.
  Items 78 to 80 are the same guard.

## 52, one more sighting (2026-11-16)

- On a downstream project on Specrew 0.40.0, the local validator failed review.md's evidence (round 34: "reviewed tree
  ... and 1 source file(s) have changed since: plan.md"; the derived independent-review block did not match), while
  Specrew CI's validator passed the same commit. The working tree holds the local review store; the clean checkout
  does not. Item 52 is not confined to this repository.
- On this branch (2026-11-16), a `-ChangedOnly` run from the fallback base failed 197/006 and 206/001 on the local
  store, and both passed in a clean scratch worktree of `7b54d49d`.

## 59 and 62, sightings in review round 3 (2026-11-17)

- **Item 59:** after round 2's partial result, `pending-round-approval.json` still said `spent_at: null` for round 2.
  The maintainer typed "approved for review round" and no capture was written; the stale entry blocked it, and nothing
  told the maintainer. The crew then launched on the old entry, which the engine refused as already used, and only
  then marked spent. The maintainer's next typed phrase was captured (08:20:46Z) and round 3 ran on it. So the
  maintainer typed the approval twice and was told nothing the first time (DRIFT-206-I002-019).
- **Item 59, the mechanism (items 59 and 60; read in the engine by the reviewer session, 2026-11-17):**
  - A partial round is "undelivered": the typed approval is journalled as spent without delivery and the entitlement
    stands (`specrew-review.ps1`, about `:1755` to `:1815`; `delivery-journal.jsonl` shows it for round 3).
  - A fresh typed line is folded into that record: `Write-SpecrewReviewRoundApprovalAuthorization` returns the existing
    unspent record with the same hash, and `Test-SpecrewTypedActReplacesRecord` (`HumanAuthorityStore.ps1:749`) refuses
    to replace a record that has a `minted_ref`. The next round would run on the earlier round's evidence.
  - So a partial round the human has triaged and acted on leaves a spendable approval that also swallows the next typed
    one. The only clearing path is the human's withdrawal (`Write-SpecrewApprovalWithdrawal`,
    `HumanAuthorityStore.ps1:2091` to `:2200`, wired in `HandoverStore.ps1:1304`), and nothing tells the human so.
- **The question-UI detector misreads an agent's own output:** the Stop hook records a "phrase seemed to come from a
  picker" observation when a tool result carries the round phrase as a short quoted JSON value (`HandoverStore.ps1`,
  about `:1868` to `:1885`). It fired at 16:36:16Z when the crew printed the pending approval record to check it. It
  is an observation, never authority; its only reader is one sentence in the review refusal (`specrew-review.ps1`
  `:964`, `:1183`, `:1470`), and a typed capture clears it. Its diagnosis can be wrong. The crew now prints only those
  files' date and state fields.
- **Item 62:** the round 3 reviewer ran 08:46:46Z to 08:51:47Z (about 300 s of 2400 s) and wrote "I stopped to publish
  rather than on a clock reading". With only Read, Glob, Grep and Write it could not show a commit, so the scope's
  "commit by commit" section could not be done on that host at all. Round 4's scope file gives the commit list, the
  changed files and each fix by file and function instead.

## 43, a sighting at iteration 002's sign-off (2026-11-17)

- The maintainer stopped the review on round 4's findings; sign-off was allowed at 19:02:30Z
  (`complete-current-findings-human-accepted`). The crew then pushed the review record and its drift entry
  (`1d685ce2`, records only, all three workflows green).
- The review-signoff sync at 19:09:04Z was refused with `records-only-delta-over-non-authorizing-result`
  (`review-signoff-evidence-gate.ps1`, about `:932`). The human's acceptance covers only the exact tree round 4 read,
  and the records-only allowance carries a pass forward, not an accepted result with findings.
- The refusal said that review "did not finish with a result that can sign anything off" and told the crew to run a
  fresh review with `specrew review --live`. No rounds remained, and the maintainer had accepted that result seven
  minutes earlier.
- The way through was a partial review signoff: the sync once, the maintainer's typed line (captured 20:15:56Z), and
  the sync again with no writes between (allowed 20:16:31Z, `human-authorized-partial-override`).
- Not a regression; the gate does what it was written to do. Feature 203's T022 plans to close the gap. Until then it
  meets any crew whose last round ends with findings and whose review record is pushed before its verdict, as SC-009
  now allows. Recorded in DRIFT-206-I002-022.

## Iteration 002 Intake

Carried from iteration 001 by name, with the decision that carried each (`.squad/decisions.md`,
`f206-i001-gap-ledger-deferrals` and the per-requirement entries):

- **SC-002 (T003's remainder):** `tests/integration/validator-hardening-iteration2.ps1` green with all three B5F-036
  assertions (item 21; its fixture also needs item 29's fix).
- **SC-001:** `tests/integration/project-path-resolution-regression.ps1` green and registered (items 23 to 25).
- **T016 (FR-013) and T017 (FR-014)**, as the approved plan sets.
- **DRIFT-206-I001-010:** abandoned is closed only with a recorded ruling; feature 206 does not close without it.
- **Items 12 and 15 to 30**, as the review's gap ledger lists them (each item says what remains), and **items 31 to
  38**, with item 36 including plan.md's stale note. Item 39 is a candidate; it goes in only by the maintainer's word at
  iteration 002's plan.
- **Items 40 to 44**, recorded after the iteration-closeout. Items 40 and 43 are in, or next to, feature 203's area and
  carry the same choice: after 203 merges, a hand-over to 203, or the protection lifted. Item 42 is a hand-over to 203.
  Whether any of them is planned for iteration 002 is the maintainer's decision at that iteration's plan.
- **Scope decided (maintainer, 2026-11-15, 11:31 local, relayed; DRIFT-206-002):** the carried work above except items
  36 and 38, plus items 37, 39, 41 and 44, which Amendment A1 adds to the spec as FR-015 to FR-018. Items 40, 42 and 43
  stay with feature 203 (hand-overs, or after its merge); items 36 and 38 come later. The plan sizes everything and
  shows any cut; the cut is the maintainer's at the plan approval.
