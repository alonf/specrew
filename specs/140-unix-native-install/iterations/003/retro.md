# Retrospective: Iteration 003

**Schema**: v1
**Date**: 2026-06-03
**Review verdict**: acceptable (Crew Reviewer) — *with macOS manual validation WAIVED per maintainer decision* → maintainer review-signoff

## Estimation Accuracy

| Task | Estimated | Actual | Delta | Notes |
| ---- | --------- | ------ | ----- | ----- |
| T018 | 3 | 3 | 0 | macOS Homebrew `pwsh` auto-install. |
| T019 | 2 | 2 | 0 | `install.sh --prerelease`. |
| T020 | 3 | 3 | 0 | macOS wrapper-runtime CI lane. |
| T021 | 3 | 0 | -3 | macOS manual proof — **WAIVED** (maintainer reactive-fix decision); SP not consumed. |
| T022 | 3 | 3 | 0 | Native-first docs. |
| T023 | 2 | 2 | 0 | Docs-parity cascade arm. |
| T024 | 3 | 3 | 0 | Release gate — executed as the beta1→beta4 cycle. |

**Planned**: 19/20 SP. **Consumed**: ~16 SP (T021 waived). The big variance was **not** in the task
estimates — it was the **unplanned beta-validation bug-fix cycle** (beta1→beta4), which lived inside T024's
release-gate scope. Each published beta surfaced real bugs invisible to clean-container CI; fixing them was
the iteration's true cost and its true value.

## Phase Variance

| Phase | Estimated | Actual | Delta | Notes |
| ----- | --------- | ------ | ----- | ----- |
| Implementation (T018-T023) | 13 | 13 | 0 | All passed; no task overflowed scope. |
| Release gate (T024) | 3 | ~3 + 4 beta cycles | +large | beta1 (3 install bugs) → beta2 (interactive-start headless) → beta3 (validated) → beta4 (fast-follow). The fixes were small individually; the **cycle count** was the cost. |
| macOS manual (T021) | 3 | 0 | -3 | Waived. |

## Drift Summary

- Total drift events: 0 (no spec drift). The beta-cycle fixes were defects in the *delivered* surface, not scope drift.
- Resolved via spec update: 0 · revert: 0 · deferred: 0 · escalated to human: 1 (macOS-waiver decision).

## What Went Well

- **Beta-before-stable did exactly its job.** Four classes of bug shipped past green CI and were caught only
  by real-host validation: (beta1) install-if-absent/side-by-side false-"Done", wrapper exec-bit
  `Permission denied`, clone-mode `pwsh -File` guidance; (beta2) **interactive `specrew start` ran the host
  headless**. None were reachable by clean-container CI (no prior install, no TTY). The mandate paid for itself.
- **A no-publish discriminator settled the highest-stakes fix.** Rather than burn a publish cycle guessing
  whether the beta2 fix worked, we replicated its exact runtime chain (`pwsh -File` → `Import-Module` by path
  → `Invoke-Specrew start` → function-body launch) on the *already-installed* older module — it opened
  interactive Copilot, proving the mechanism on the real host before tagging beta3.
- **The advisor caught a hollow test before it could mislead.** The first interactive-`start` regression
  proved *routing* (re-dispatch engaged) but not the load-bearing property (TTY survived). It was strengthened
  to run under a PTY and assert a controlling terminal — now green on Ubuntu *and* macOS, so the guard means
  what its name says.
- **Faithful CI-vs-manual split held throughout.** The release gate never overstated coverage; macOS stayed
  honestly labelled (CI-covered surface vs the un-CI-reachable live Homebrew install).

## What Didn't Go Well

- **`specrew version` hid the build identity → three rounds of "tested the wrong build."** It printed the bare
  base `0.31.0` for every prerelease, so the maintainer repeatedly installed an *older published* beta while
  believing they were testing the fix. Root causes compounded: (a) the label was never surfaced, and (b)
  `install.sh --prerelease` installs the **published** module from PSGallery, not branch code — so an
  unpublished fix is simply not installable, no matter how fresh `install.sh` is. Fixed in beta4 (finding #2).
- **CI green ≠ property proven (again).** The routing-only regression test is the same form-vs-meaning trap
  seen earlier this project; only an explicit "name the load-bearing property and test *that*" pass caught it.
- **Native wrapper bypassed a proven mechanism.** Feature 140's wrapper ran the dispatcher via `pwsh -File`
  (script context), routing *around* the module-function TTY launch validated in R-019-V2 — re-introducing a
  latent bug by changing the default entry path.

## Improvement Actions

1. Owner: Implementer | Phase: design | Type: process | Effect: when a feature adds a *new entry path* to an
   existing command, audit which proven mechanisms the old path relied on (here: the deferred-launch TTY
   handoff) and re-route through them, rather than re-deriving in the new path.
2. Owner: Reviewer | Phase: review | Type: process | Effect: for any "the fix works" test, state the
   load-bearing property in the test name and assert it directly (PTY for TTY, not just routing). A test that
   can pass with the bug present is not a guard.
3. Owner: Maintainer/Crew | Phase: release-gate | Type: process | Effect: before on-host beta validation,
   confirm the build identity first (`specrew version` now shows the label; else `Get-Module … Prerelease`) —
   never judge a fix without confirming the installed build is the one carrying it.

## Calibration Suggestion

- Suggested capacity adjustment: 20 → 20 (no change).
- Rationale: implementation tracked estimates exactly; the overage was the beta-cycle count, which is
  inherent to validating an intrinsically-runtime install surface and is *the point* of beta-before-stable —
  not an estimation miss. Budget release-gate tasks with explicit headroom for ≥2 beta iterations on
  install/runtime features.

## Carry-forward (fast-follows, non-blocking)

- **Charter-sidecar "Preserving user-edited file" notices** (5 per `start`): possible latent bug if first
  deploy never writes the `.specrew-managed` sidecar (sync stuck in "preserve"). Investigate.
- **`version-checks.tests.ps1`**: dev-box-only (asserts a mocked installed `0.19.0`; resolves the real
  install); give it a proper installed-version seam or retire it. Not run in CI.

## Notes

- Scaffolded from plan.md, review.md, coverage-evidence.md, drift-log.md, and the release-gate evidence.
- macOS manual (T021) is **waived, not validated** — the `acceptable` verdict is explicitly conditioned on it.
