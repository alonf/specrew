# Hand-over to feature 203: findings 205 does not fix

**From**: feature 205 (workshop lens order), iteration 001 | **Written**: 2026-11-11

Feature 205 does not edit files under `scripts/internal/continuous-co-review/` or the review engine (maintainer rule,
2026-11-10). Findings that need a change there are recorded here for feature 203.

## H-001 — on main, the review preflight runs suites that write the real home hook files

**Severity**: high. A review launch rewrote the maintainer's own Codex, Cursor and Copilot hook configs and the
per-machine launcher, replacing a newer layout with an older one, with no warning.

**Failure scenario**: a project's `.specrew/verification-plan.json` names a suite that runs `scripts/specrew-update.ps1`
against a temp project. The human approves a review round. Before the reviewer starts, the preflight runs that suite.
`specrew-update.ps1` calls `Invoke-RefocusHookDeployment` without `-UserHomeOverride`, so
`deploy-refocus-hooks.ps1` writes `~/.specrew/specrew-hook-launch.ps1`, `~/.codex/hooks.json`,
`~/.cursor/hooks.json` and `~/.copilot/hooks/specrew-refocus.json` in the real home folder. Any host session started
after that runs the hook layout of whatever checkout ran the review.

**Observed**: 2026-11-11 in `C:\Dev\specrew-220-workshop-lens-order` (branched from main). Run
`run-20261110-221211306-a1cb90e2`, campaign `cmp-205-workshop-lens-order-i001`, `preflight-failed` after 1,745 s.

- The four files changed at 00:36:54 to 00:36:55 local, inside the preflight window.
- Before, the host files pointed at `~/.specrew/hooks/b958cbe133e6a88ee358f7c5f89d5a67/specrew-hook-launch.ps1`
  and the root launcher was 10,804 bytes with live-engine pin handling. After, they pointed at the root launcher,
  which was 6,772 bytes with no pin handling.
- The crew restored them from a backup, with the maintainer's permission for exactly those four files. The changed
  versions are kept, not deleted.

**Suites that write the real home** (read, not rerun):

| Suite | Line | Lane in the plan |
| --- | --- | --- |
| `tests/integration/deployed-extension-marker-on-update.tests.ps1` | 64 | `f199-slice-suites-a` |
| `tests/integration/receipt-outcomes-retired.tests.ps1` | 28 | `f202-slice-suites-a` |

Both run `scripts/specrew-update.ps1 -ProjectPath <temp>` and redirect neither `USERPROFILE`/`HOME` nor the hook home.
`cross-host-workshop` and `turn-record-contract` already pass `-UserHomeOverride` to a fixture home and are safe.

**Contributing cause**: the plan in this checkout is stale. `.specrew/verification-plan.json` (plan id
`f199.i003.slice.v1`, last re-pointed 2026-10-21) names features 202 and 199's 10 lanes, so a 205 review ran 102
suites of other features for 29 minutes before failing.

**Proposed class closure (for 203 to decide)**:

1. Give `specrew-update.ps1` a home override that reaches `Invoke-RefocusHookDeployment -UserHomeOverride`, and use
   it in both suites (or have them set a temp home for the child process).
2. Make the preflight refuse, or sandbox, any verification suite whose run changes a file under the real home hook
   paths: hash them before and after the preflight and fail loudly on a change.
3. Make the verification plan name the active feature and iteration, so a plan left from an earlier feature cannot
   run in a later one's review.

**Status**: open; owner feature 203. Recorded in 205's drift log as DRIFT-008.

## H-002 — no review.md can pass both the local governance check and CI

**Severity**: medium. Every review record written on the machine that ran the review either fails the local check or
turns CI Lint red.

**Failure scenario**: `validate-governance.ps1` derives an independent-review block for `review.md` from the review
authority store under `.specrew/review/`, which is gitignored. On the reviewing machine the store holds the runs, and
when the check observes the implementing session writing `review.md` it requires the derived block. In CI the store is
empty and the derived block is shorter. A record with the local block fails CI Lint on the mismatch; a record without
it fails locally.

**Observed**: 2026-11-11, feature 205 `cf173030`, Specrew CI run `43066362500`: Lint failed on the block, and the
Deterministic gate and Contract lane were skipped. Locally the block names tree `bf289776` as the last tree a
completed run read; CI derived two bullets.

**Proposed class closure (for 203 to decide)**: derive the block only where the store exists and skip the comparison
where it does not, or commit the evidence the block is derived from, so both runs derive the same text.

**Status**: open; owner feature 203. Recorded in 205's drift log as DRIFT-012.

## H-003 — the sync needs review.md with the pre-review phase lines; the governance check refuses that pair

**Severity**: medium. Every feature gets one red Specrew CI commit at review-signoff.

**Failure scenario**: the review-signoff sync binds to a commit on origin that must hold `review.md` (owed artifact)
with state.md and plan.md still at the last authorized boundary (`before-implement` / `executing`, the state-truth
gate). The governance check refuses plan Status `executing` once `review.md` exists, locally and in CI. So the commit
the sync needs always fails the check and turns Specrew CI Lint red, skipping the gates behind it.

**Observed**: 2026-11-11 and 2026-11-12, feature 205 iteration 001 (DRIFT-011, DRIFT-013). Feature 202 iteration 003
took the same path in `a7e2b74c`. Note also that the sync's preflight-only run does not check owed artifacts, so it
passes where the real sync refuses.

**Proposed class closure (for 203 to decide)**: let the governance check accept `executing` with a `review.md` while
the review-signoff crossing is pending, and make the preflight-only run check owed artifacts too.

**Status**: open; owner feature 203. Recorded in 205's drift log as DRIFT-013.

## H-004 — the deployed-file check names 5 of 18 drifted files and offers only specrew update

**Severity**: low. The message understates the drift and points at a remedy that can undo intended changes.

**Failure scenario**: `Test-DeployedExtensionIntegrity` in `validate-governance.ps1` lists only the first 5 drifted
files, with no total, and its only remedy is `specrew update --project-path ...`. When a feature has deliberately
refreshed the deployed copies through the sync scripts, the right fix is to refresh the hash record, and the message
does not say so.

**Observed**: 2026-11-11, feature 205: 18 files drifted, 5 named (DRIFT-010, DRIFT-014). Feature 206 hit the same
check the same day.

**Proposed class closure (for 203 to decide)**: print the total and every drifted path, and name both remedies:
`specrew update` when the deployed copies were edited by mistake, and a hash-record refresh when they were deployed on
purpose. Better still, have the deploy scripts write the hash record.

**Status**: open; owner feature 203. Recorded in 205's drift log as DRIFT-014.

## H-005 — a session resume rewrote a tracked governance file

**Severity**: medium. Opening a session changed a tracked file that the boundary sync checks, with no command run.

**Failure scenario**: the session-start hook runs the bootstrap provider in welcome-back mode. It calls
`coordinator-resume.ps1` (`Get-TaskProgressSummary`, line 165), which runs `Sync-IterationTaskProgress` in
`scripts/internal/task-progress.ps1`. That writes `tasks-progress.yml`, and `Update-IterationStateFromTaskProgress`
rewrites `state.md`, including its Iteration Status. The boundary sync's state-truth gate then reads a status that
neither the human nor the crew chose, and a later commit can carry it unnoticed.

**Observed**: 2026-11-12 00:18:28 local, feature 205 iteration 001, after a machine restart. state.md moved from
`executing` to `ready-for-review` and gained a managed summary block; `tasks-progress.yml` was created untracked.

**Proposed class closure (for 203 to decide)**: make the resume summary read-only, computing the summary without
writing, and leave state.md and tasks-progress.yml to the commands that own them.

**Status**: open; owner feature 203. Recorded in 205's drift log as DRIFT-017.

## H-006 — review-runtime tests depend on runner speed; one production wait is too short

**Severity**: high for the class. Five different review-runtime tests failed in two days on shared runners, each on a
commit that could not have caused it.

**Observed failures**:

- macOS process-group probe: feature 206, `a9ad8aa0`, Cross-Platform `42994018357`
  (`macos-process-group-unavailable:macos-process-group-probe-membership-failed`).
- Windows journal-fault-injection 1,000 ms budget: feature 205, `cf173030`, Cross-Platform `43066363241` (2,650 ms).
- co-review-service lease handoff: feature 206, `03bc7a48`, Specrew CI `43116326615` (Linux; the stopped supervisor
  was still listed).
- macOS stream-drain 250 ms budget: feature 206, `03bc7a48` (reported by the maintainer; not confirmed from the log).
- empty-result-retry, earlier (reported by the maintainer; its failure output was not read).

### Product defect, separate from the test items

**Item 8 is a product defect.** `Wait-ReviewMacProcessGroupMembership` (`review-macos-runtime-port.ps1:79`) defaults to
1,000 ms, polling every 25 ms, and each poll runs a live `ps` membership probe. The macOS runtime preflight
(`Test-ReviewMacProcessGroupAvailability`, about line 116) uses that default, so a loaded machine, a user's laptop as
much as a shared runner, can report the macOS runtime unavailable. The ready-file handshake before it already allows
`ReviewPosixContainmentHandshakeTimeoutMilliseconds` (15,000 ms).

### The census

Counted: checks that fail when a runner is slow. Not counted: generous safety deadlines (15 to 180 s) and lower bounds
("at least 4.5 s elapsed"), which fail only if something is truly wrong. Paths are under `tests/continuous-co-review/`
unless they start with `tests/`.

**A. Speed caps: a stopwatch measures a fast path and asserts an upper bound.**

| # | File:line | What it asserts | Failed |
| --- | --- | --- | --- |
| 1 | `tests/unit/journal-fault-injection.tests.ps1:89-91, 97, 104` | First lock wait 950 to 1,500 ms; later waits under 100 ms; total under 1,600 ms; append after budget under 100 ms; free lock under 100 ms | 205, Windows, `cf173030` |
| 2 | `unit/review-posix-runtime.Tests.ps1:126` | A drain wait with a 25 ms timeout returns in under 250 ms | 206, macOS, `03bc7a48` |
| 3 | `integration/timeout-partial-stdout.Tests.ps1:34` | A 3 s timeout run ends in under 20 s | |
| 4 | `unit/isolated-task-launcher.Tests.ps1:104`, `:173` | Detached start under 8 s; a 3 s timeout ends in under 35 s | |
| 5 | `unit/review-target-port.Tests.ps1:72` | A 1 s timeout ends in under 8 s | |
| 6 | `unit/hook-health-receipt.Tests.ps1:297` | A 1 s probe timeout ends in under 8 s | |
| 7 | `integration/detached-spawn-no-block.Tests.ps1:55` (Windows only) | The host read returns in under 4 s | |

**B. Real deadlines that must succeed: a slow runner turns success into a timeout.**

| # | File:line | What it depends on | Failed |
| --- | --- | --- | --- |
| 8 | `integration/review-cross-platform-fault-matrix.Tests.ps1:150` | The macOS runtime preflight's 1,000 ms membership wait (the product defect above) | 206, macOS, `a9ad8aa0` |
| 9 | `unit/review-posix-runtime.Tests.ps1:169` | Three injected probe calls within 100 ms (lines 174-178 were already loosened for this; 169 was not) | |
| 10 | `unit/review-posix-runtime.Tests.ps1:103` | Two ready-file reads within 100 ms | |
| 11 | `tests/unit/hook-output-journal.tests.ps1:203, 266, 300, 326, 351-422` | A 4,000 ms lock hold must outlast the 1,000 ms budget, leaving about 3 s for the dispatcher to reach the lock | |
| 12 | `unit/empty-result-retry.Tests.ps1` (all four cases) | Each attempt starts a real `pwsh` under a 30 s timeout; the retry needs two cold starts (inferred) | earlier |

**C. Kill, then check at once.**

| # | File:line | What it does | Failed |
| --- | --- | --- | --- |
| 13 | `unit/co-review-service.Tests.ps1:127-129` | Production (`co-review-service.ps1:216`) runs `Stop-Process -Force` without waiting; the test calls `Get-Process` immediately | 206, Linux, `03bc7a48` |
| 14 | `unit/bounded-verification.Tests.ps1:60-63` | A fixed 800 ms sleep, then the grandchild must be gone | |

**Sleeps used as barriers (lower risk)**: `unit/lineage-lease.Tests.ps1:54` (500 ms) and
`tests/unit/journal-fault-injection.tests.ps1:149` (1,500 ms). A racer whose cold start takes longer misses the
barrier.

**Already speed-proof, the model to copy**: `unit/isolated-task-containment.Tests.ps1:174-179` and `:259-264` kill, poll
until the process is gone with a 10 s deadline, then assert.

### Proposals (for 203 to decide)

1. **Inject the clock into budget logic.** The lock-wait budget, the drain wait and both membership waits take a clock
   and sleep parameter (`Wait-ReviewPosixReadyFile -Sleep` and `-MembershipProbe` half-exist). Tests assert the
   accounting, not milliseconds: the first wait used up the budget, later waits tried once, the spent-budget counter
   reads 1,000. Covers 1, 2, 9 and 10.
2. **Assert outcomes, not durations, for timeouts.** "Timed out, not slept to completion" becomes: `timed_out` is true,
   the child tree is gone (polled with a deadline), and a marker the child writes after its long sleep does not exist.
   Covers 3 to 7.
3. **Wait for exit after a kill, in production and in tests.** `Stop-Process` is followed by a bounded `WaitForExit`,
   and production reports a survivor. Tests poll until gone, as the containment test does. Covers 13 and 14.
4. **Handshakes instead of sleeps.** Each racer or writer writes a ready file and the test waits for all of them before
   releasing the barrier. Covers the two sleep barriers, and item 11 once the dispatcher signals that it is waiting
   before the holder's clock starts.
5. **Fix the product defect in item 8.** Give the membership wait the handshake's budget (15 s), or bound it by
   observation count instead of time.
6. **Keep one coarse check where wall-clock time is the rule.** DRIFT-023's 1,000 ms lock budget is a product rule:
   keep a lower bound (first wait at least 950 ms) and an upper bound with real slack (under 10 s), and move the exact
   accounting to the fake-clock test.
7. **Class closure.** A static test that fails on any new elapsed-time upper bound (`Should -BeLessThan` on a
   stopwatch, or `-lt` on `Elapsed…`) in the review-runtime suites, unless the line carries an explicit allow
   annotation.

**Status**: open; owner feature 203. Recorded in 205's drift log as DRIFT-018. Feature 205 does no further work on it.
