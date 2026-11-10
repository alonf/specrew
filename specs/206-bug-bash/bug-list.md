# Bug List: 206 Bug Bash

**Feature**: 206-bug-bash
**Conduct**: bug-bash under the software-feature contract (no eight-lens workshop, as in feature 201)
**Diagnosed**: 2026-11-10, on main `d3e33550` (branch `206-bug-bash`)
**Status**: diagnosis complete for items 2 to 5 (item 3: cause not found); no fix written

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
- **Needed for green:** a maintainer decision on 198/011 (close, abandon, or let the validator accept a
  deliberately held-open retro) plus a failure signal that reaches a human.

## 5. Tests registered in no CI step and no verification lane

- **Inventory (520 candidate files under `tests/`, fixtures and support helpers excluded):**
  - 152 suites are in no per-push CI step and no lane, but all 152 are named in
    `.specrew/release-gate-suites.txt` and run in the release full sweep. Deliberate release cadence.
  - **35 integration scripts run nowhere:** no CI step, no lane, no release manifest, and invisible to the
    release full sweep, because the sweep and the lane guard
    (`tests/unit/every-suite-is-named-by-a-lane.tests.ps1`) both count only files named `*test.ps1` or
    `*tests.ps1`. Both B5F-036 suites are among them.
  - `tests/integration/_ctl-spec.ps1` is an empty 0-byte file committed by `2a5c042b`.
  - 4 manual or host-probe scripts are out of scope by design.
- **Root cause:** the suite definition is the file name, and script-style suites written before the
  `*.tests.ps1` convention were never renamed or listed. The guard that exists to catch an unregistered
  suite shares the same blind spot.

## 6. Smaller, already filed

- The quality resolver suggests node/react presets for this repository.
- `.squad/active-features.yml` records the Windows user and machine name (B5F-022). Not committed here
  until decided.
