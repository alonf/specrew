# Feature 203 iteration 001 review, Round B: review engine (`scripts/internal/continuous-co-review`, `scripts/specrew-review.ps1`)

This round's focus is the area below. The whole tree is frozen and in scope; spend your time on this area first.

## What this iteration changed

- **What changed**: feature 203 iteration 001, from `fca9067e` (the before-implement baseline) to `32d2af39`:
  298 commits, 330 files, +25,215 / -6,885 lines. The frozen tree has no diff in it. The full list of
  changed files with their line counts is in `docs/review-scope/changed-files.txt`. Read that list before
  choosing what to open.
- **The iteration's contract**: `specs/203-beta5-stabilization/spec.md` and
  `specs/203-beta5-stabilization/iterations/001/plan.md` (the task table: T001 to T013 done, T014 planned).
  The engine resolves both automatically.
- **Not defects of this iteration** (deferred by the maintainer's rulings; do not report them as missing):
  - FR-041: drift entries do not carry the turn identity yet (iteration 002).
  - FR-042: replay through Copilot's and Codex's real hooks across a compaction, and the Codex out-of-tail
    case (iteration-002 three-host walk).
  - The out-of-band boundary approval decision (iteration 002).
  - Two suites known red under B5F-036: `project-path-resolution-regression.ps1` and
    `validator-hardening-iteration2.ps1`.
  - T014 (pin advance): the live hooks still run engine `a56ac787`. This round reviews the source, not the
    deployed engine.
- **Stripped from the frozen tree**: `.specify/**`, `.specrew/**`, `.squad/**`. The `.specify` copies are mirrors of
  `extensions/specrew-speckit/`; review the `extensions/` source.
- **Severity**: a blocking or major finding states a concrete failure scenario. Prefer one proven defect over
  several suspicions.
- **If you have a shell**: the frozen tree is a git worktree at `32d2af39`; `git diff fca9067e -- <path>` shows the
  iteration's change to a file.

## Focus: Round B: review engine (`scripts/internal/continuous-co-review`, `scripts/specrew-review.ps1`)

**Files changed in this area:**

| File | +/- | Tasks (requirements) |
|---|---|---|
| `review-campaign-orchestrator.ps1` | +1480 / -267 | T007 (FR-001, 002, 003, 008), T008 (FR-004 to 007, 009 to 011) |
| `scripts/specrew-review.ps1` | +183 / -621 | T004, T008 |
| `review-authority-core.ps1` | +207 / -288 | T008, T012 |
| `continuous-co-review-navigator.ps1` | +18 / -422 | T008 (navigator routes) |
| `review-signoff-evidence-gate.ps1` | +86 / -9 | T008 |
| `verification-plan-runner.ps1` | +82 / -2 | B5F-042 (preflight home isolation) |
| `signoff-gate-wiring.ps1` | +61 / -0 | T008 |
| `worktree-navigator.ps1` | +35 / -69 | T008 |
| `review-result-ingestor.ps1` | +19 / -2 | T008 |
| `review-authority-store.ps1` | +9 / -4 | T012 |
| `reviewer-candidate-prompt.md` | +5 / -0 | T008 |
| `scripts/internal/sync-boundary-state.ps1` | +3 / -0 | T007 |

**Attack these:**

1. **A reservation spent without a budget grant.**
   - Can a reviewer be invoked with no grant?
   - Can it be invoked with a reservation that a top-up, release or retry has already used?
   - Can it be invoked after the budget is exhausted?
2. **Delivery accounting.**
   - Can an undelivered attempt (timeout, partial, empty result) be counted as delivered?
   - Can attempts be retried past the infrastructure cap?
   - Can a preflight failure be charged as a spend?
3. **Budget declaration and ceilings (FR-001 to 003, 008).**
   - A missing declaration must default to zero rounds. Look for a path that reads it as unlimited.
   - A ceiling must be enforced at plan sync and at snapshot. Look for a path that skips it.
4. **Navigator and sign-off routes.** Look for any route that reads as clean while the latest result's digest
   differs from the current tree, or that applies a pause or stop decision to the wrong campaign or round.
