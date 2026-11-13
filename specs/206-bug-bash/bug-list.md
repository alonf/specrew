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
- **Fixed in iteration 001:** the fixture copies only the files git tracks under those folders. The lane guard checks
  it (RED 1/70 in `db1e0fda`).
- **Not fixed:** `tests/integration/validator-hardening-iteration2.ps1` builds the same fixture the same way (line 132).
  It is excluded as red for SC-002 and is not run; its fix belongs with SC-002 in iteration 002.
