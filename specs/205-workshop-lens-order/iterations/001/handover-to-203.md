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
