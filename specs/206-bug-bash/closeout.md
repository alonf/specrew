# Feature Closeout: 206 Bug Bash

**Schema**: v1
**Feature**: 206-bug-bash
**Branch**: 206-bug-bash
**Closed**: 2026-11-18
**Status**: COMPLETE — branch-ready evidence only; merge, PR, release and tag each need their own human authorization
**Closer**: Claude (code writer), authorized by the maintainer: iteration 002's review-signoff, retro and
iteration-closeout verdicts captured 2026-11-17 and 2026-11-18; the feature-closeout gate presented at this closeout

## Summary

Feature 206 was a bug bash: diagnose and fix the defects found around the 0.40.0 betas, each behind a test that
failed first, one bug per fix commit. It ran two iterations, each reviewed in four rounds, and ends with:

- **26 fixed** (3 in iteration 001, 23 in iteration 002);
- **13 handed to feature 203** by name;
- **1 closed without a fix** (81);
- **50 open**, carried as the seed of the next bug bash (`follow-up-seed.md`).

Across both iterations, every fix commit followed its own failing-test commit, and nothing this work ran changed the
maintainer's home folder. The hook files were hashed before and after every suite, lane, round and sync.

## Delivered Scope

| Iteration | Closed | Scope | Review | Status |
| --- | --- | --- | --- | --- |
| 001 | 2026-11-15 | 16 tasks, 20 SP: the no-console recovery refusal, one definition of "closed" for iterations (the closed-definition table, abandoned 197/006 and 198/010 and 198/011, the frozen list), the nightly's tracking issue, the shared test census and its lane guard, 35 held scripts read and registered, the hand-over record to feature 203 | four Codex rounds, 23 findings, 12 fixed | complete |
| 002 | 2026-11-18 | 21 tasks, 20 SP plus about 7.5 SP of rework: SC-001 and SC-002 green and registered per push (fresh-clone start, resume paths, the start-written record, init's probe), abandoned closed only with a ruling, the census guard reading structure, the publish suite in its own Windows job with no secret, Amendment A1's FR-015 to FR-018 (a `deferred` task verdict, a record before its verdict, the closeout dashboard redrawn after the verdict, the Completed date and open hardening rows at capture) | four rounds (three Claude, one Codex), 35 findings, 19 fixed; the maintainer stopped on round 4 | complete |

## Tests and Validation

- **CI**: Specrew CI, Test and Cross-Platform Validation were followed to their end on every push.
  - Iteration 002's review record, retro and closeout heads were green on all three.
  - Iteration 001's review-signoff push was red on Lint, for the phase-line order its retro names.
  - Reruns were made only under the standing exception (items 3 and 13 and the timing cases, feature 203's to fix),
    each recorded in a drift entry.
- **Review layout**: the six review lanes passed in the review preflight's layout on `266bb3af` (1025 s) before
  iteration 002's last round.
- **Governance validator**: PASS on each pushed head, scoped to the changed iterations; both iteration seals are in
  place.
- **Not run at this closeout**: the full release sweep. The REAL CI sets ran on every push; whether a full sweep runs
  before any merge is the maintainer's call, scheduled with feature 203's sweep.
  - **The maintainer's answer**, typed in the reviewer session at 11:46 local on 2026-11-18 and relayed:
    "206 closeout sweep: no". There is no full sweep on 206 before the merge. The reasons given and accepted: CI ran
    the real test sets on every push and the closing head `eca038de` is green on all three workflows; a full local
    sweep from this worktree cannot run the home-writing files while feature 203 is unmerged; and feature 203 sweeps
    206's code on the combined tree when it takes main in (its T030).

## Known Warnings, with Dispositions

- **No derived independence block in either review record**: the block is computed from the local review store, so
  the local check and CI derive different text (feature 205's DRIFT-012). The maintainer approved leaving it out; each
  record says in words what its independence rests on.
- **The review-coverage line counts three changed "source" files since round 4**: they are bookkeeping (the
  sign-off gate record, the lifecycle event log, `tasks-progress.yml`), not code. No round remained.
- **Flaky suites rerun under the standing exception**: `empty-result-retry.Tests.ps1` twice on 2026-11-17/18
  (DRIFT-206-I002-025, DRIFT-206-006). Bug list item 3, feature 203's.
- **The retro scaffold refuses an explained verdict line** (third sighting, DRIFT-206-I002-023). Both retros were
  written by hand. Not yet a bug list item; that is the maintainer's word.
- **Git for Windows was removed twice by Visual Studio installer runs on 2026-11-18** (DRIFT-206-I002-024). No git
  step ran in either window, and nothing was left half-written.

## Branch Hygiene

- The branch `206-bug-bash` is pushed and in sync with `origin/206-bug-bash`.
- The one dirty path is `.squad/active-features.yml`. It is machine-local, never committed by this feature's rule,
  and records the Windows user and machine name (bug list item 6b).
- Feature 206 commits touched no files in `scripts/internal/continuous-co-review/`, the capture stores or
  `specrew-conformance-provider.ps1` (protected for 203). Items needing them are listed as feature 203's or wait for
  its merge.

## What This Closeout Does Not Authorize

Merge to main, a PR, a release, a tag or a publish. Each needs its own typed authorization. The maintainer's stated
order is to close 206 and 203, then open the next bug bash.

## Carried Items

- **The next bug bash**: `follow-up-seed.md`, the 50 open items grouped. The majors come first (86, 66, 73, 83),
  then the design question (74), and the items that wait on feature 203's merge are marked.
- **Feature 203**: 13 items handed over by name (3, 7, 8, 9, 13, 14, 27, 42, 58 to 62), and its T022 for the
  sign-off gap met at iteration 002's sign-off (item 43's sighting).
- **Iteration 002's retro improvement actions**: listed in `iterations/002/retro.md`, owners named; they go to the
  next bug bash's plan.
