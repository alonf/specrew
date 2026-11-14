# Feature 203 iteration 001 review, Round E: the fixes since round D

This round's focus is the area below. The whole tree is frozen and in scope; spend your time on this area first.

## What this iteration changed

- **What changed**: feature 203 iteration 001, from `fca9067e` (the before-implement baseline). The full list of changed
  files with their line counts is in `docs/review-scope/changed-files.txt` (to `1377289a`, the tree round D reviewed).
  Since round D: eight commits of fixes, `a9a13583` to `671b2dfc`, the review records commits, then four commits fixing
  two defects in that batch's test code (`135b0b54` to `bfbbf649`, DRIFT-080) and a records commit.
- **The iteration's contract**: `specs/203-beta5-stabilization/spec.md` and
  `specs/203-beta5-stabilization/iterations/001/plan.md`. The engine resolves both automatically.
- **The review records are present by design.** `review.md`, `plan.md` at `reviewing` with T014 `blocked`, `state.md`,
  `tasks-progress.yml`, the drift log (DRIFT-075 to DRIFT-079) and these focus files are committed before this round on
  purpose: on this engine a records commit made after the stop cannot be signed off (DRIFT-078). `review.md` describes
  rounds A to D; this round's result is added after the sign-off. Do not report the records as premature.
- **Not defects of this iteration** (deferred by the maintainer's rulings; do not report them as missing):
  - FR-041: drift entries do not carry the turn identity yet (iteration 002).
  - FR-042: replay through Copilot's and Codex's real hooks across a compaction, and the Codex out-of-tail case
    (iteration-002 three-host walk).
  - The out-of-band boundary approval decision (iteration 002).
  - Two suites known red under B5F-036: `project-path-resolution-regression.ps1` and
    `validator-hardening-iteration2.ps1`.
  - T014 (pin advance) is blocked on the sign-off by plan: the live hooks still run engine `a56ac787`. This round
    reviews the source, not the deployed engine.
  - Already found and recorded: the hook cost (DRIFT-073); the three suites at or over 900 s and the start-command load
    timeout (DRIFT-073); the pin's stop citing a standing grant (DRIFT-075, pin only); a human-accepted stop never
    covering a later records commit (DRIFT-078, placement pending); the flaky tests `co-review-service.Tests.ps1:129`
    and `empty-result-retry.Tests.ps1:29`; a task scheduled after sign-off having no verdict value (feature 206's bug
    list item 37).
- **Stripped from the frozen tree**: `.specify/**`, `.specrew/**`, `.squad/**`. The `.specify` copies are mirrors of
  `extensions/specrew-speckit/`; review the `extensions/` source.
- **Severity**: a blocking or major finding states a concrete failure scenario. Prefer one proven defect over
  several suspicions. This is the last round of this iteration's review: what does not block sign-off goes to
  iteration 002.
- **If you have a shell**: `git diff 1377289a -- <path>` shows what changed since round D.

## Focus: Round E: the four fixes since round D

Each fix landed behind a test committed red first. Check that each fix is right and complete, and that its test can
fail.

1. **An approval followed by more than 2 MiB of conversation** (`99223e7d`, test `a9a13583`):
   `Resolve-SpecrewAuthorizationSender` and `Read-SpecrewCitedTypedTurn` in
   `scripts/internal/bootstrap/HumanAuthorityStore.ps1`. The 2 MiB tail is tried first; on a miss the whole transcript
   is read once more; assistant records are skipped before parsing. Attack: a cited turn the skip could drop; a
   transcript the whole read still misses; a caller on a hot path that now pays the whole read.
2. **A turn the ledger cannot reserve is reported** (`ef58deae`, test `328f2cf5`): `Invoke-SpecrewTypedAuthorityCapture`
   in `scripts/internal/bootstrap/HandoverStore.ps1` and `Write-SpecrewTypedAct` in `HumanAuthorityStore.ps1`. Attack:
   a reservation failure that still says nothing; a report that tells the human an approval was lost when it was not.
3. **The sweep's Pester verdict** (`2626f722`, test `9f2e9f3b`): `tools/maintenance/sweep/run-suites.ps1`. Attack: a
   failed or empty Pester run that still counts as passed; a passing one now counted as failed.
4. **`tests/unit/hook-command-length.tests.ps1`** (`671b2dfc`, test `a4c3222c`; then `07e1845f`, guard `135b0b54`): its
   cmd.exe commands run in their scratch projects, and it checks its checkout is unchanged, a clean checkout included.
   Attack: a command it still runs in the checkout; a change to the checkout the check cannot see.

The sweep-driver self-test's case 12 fixture is built from lines (`bfbbf649`, guard `8681c21c`) so run-suites runs the
self-test as a script; run-suites still classifies a suite as Pester by any line starting with Describe, a known
follow-up for iteration 002 (DRIFT-080).
