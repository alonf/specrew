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

## 3. `empty-result-retry.Tests.ps1` "retries once and recovers" failed once in the Deterministic gate

- **Observed (run 42715079692, attempt 1, ubuntu):** the retry's stdout was empty
  (`Expected '"run_id":"t108"' to match <empty>`).
- **Cause: not found.** Not reproduced: the real test passed 200 of 200 cases on Linux (WSL Ubuntu 24.04,
  pinned to 2 cores, 25 runs idle and 25 under CPU load), and a standalone replay of the capture pattern
  lost no output in 300 runs on Windows.
- **Candidate, unproven:** `Invoke-ContinuousCoReviewAgentInWorktree`
  (`scripts/internal/continuous-co-review/worktree-reviewer.ps1:1598`) keeps stdout only if the
  `ReadToEndAsync` task already shows `RanToCompletion` when `WaitForExit(slice)` returns, and that wait does
  not wait for the reader to reach end-of-stream. The failure's shape (retry stdout empty) fits it, but it was
  never observed. The file is in feature 203's protected area.
- **Disposition (maintainer, 2026-11-10):** no fix in 206. Hand over to feature 203 as "cause not found,
  one candidate", with the evidence above. Any recurrence is logged here with its run id.

| Run id | Attempt | Date (UTC) | Commit | Runner | Outcome |
| ------ | ------- | ---------- | ------ | ------ | ------- |
| 42715079692 | 1 | 2026-11-09 | `700e6127` | ubuntu-latest | failed; passed on rerun (attempt 2) |

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
- **Needed for green:** the maintainer's choice for 198/011: close it with a pointer, or make an explicit,
  recorded hold a state the validator accepts. In scope either way: the wrong "Complete iterations" message
  corrected, and a nightly failure notification that reaches a person.

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
