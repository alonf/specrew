# Feature 203 iteration 001 review, Round D: the whole tree, tests included

This round's focus is the area below. The whole tree is frozen and in scope; spend your time on this area first.

## What this iteration changed

- **What changed**: feature 203 iteration 001, from `fca9067e` (the before-implement baseline) to `1377289a`:
  330 commits, 331 files, +26,207 / -6,885 lines. The frozen tree has no diff in it. The full list of
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
  - Already found and recorded (do not spend the round rediscovering them):
    - Hook cost (DRIFT-073): about 19 s of hooks per turn (Stop hook about 14 s on this tree); a proposal is with the
      maintainer.
    - `tests/unit/hook-command-length.tests.ps1:90` runs a launcher with no working directory, so run inside a checkout
      it starts that project's real dispatcher and rewrites `iterations/001/state.md` and `tasks-progress.yml`
      (DRIFT-072; fix open).
    - Three suites at or over 900 s under sweep load: `message-identity`, `review-loop-stops`, `review-budget-loop`
      (DRIFT-073).
    - `start-command-non-interactive-first-run.tests.ps1` hitting its 300 s limit under sweep load (202 s alone;
      DRIFT-073).
    - Known flaky tests: `co-review-service.Tests.ps1:129` (lease handoff) and `empty-result-retry.Tests.ps1:29`.
- **Stripped from the frozen tree**: `.specify/**`, `.specrew/**`, `.squad/**`. The `.specify` copies are mirrors of
  `extensions/specrew-speckit/`; review the `extensions/` source.
- **Severity**: a blocking or major finding states a concrete failure scenario. Prefer one proven defect over
  several suspicions.
- **If you have a shell**: the frozen tree is a git worktree at `1377289a`; `git diff fca9067e -- <path>` shows the
  iteration's change to a file.

## Focus: Round D: the whole tree, tests included

The tree as a whole: how the three areas above compose, plus the tests and tools that claim to prove them. Read
`changed-files.txt`.

**Attack these:**

1. **Proofs that cannot fail.** T013 claims these fixtures turn red when the rule they guard is broken:
   - the mint-path matrix (`tests/unit/mint-path-fixtures.Tests.ps1`);
   - the sender suites (`authorization-sender`, `authorization-consumers`);
   - the budget invariants (FR-043).

   Find a case that passes whatever the product does, or a fixture shape no real host produces.
2. **Composition across the areas.** An approval refused in round A's store and accepted by round B's engine or
   round C's matcher, or the reverse.
3. **Home isolation.** Can any suite or lane write the real user home (`SPECREW_USER_HOME_OVERRIDE` unset or
   ignored)?
4. **Maintenance tools** (`tools/maintenance/sweep/*`, `refresh-specify-mirror-record.ps1`):
   - a destructive operation outside its own temp folder, or one selected by pattern instead of exact path;
   - a mirror-record refresh that hides drift between `extensions/` and `.specify/`.
