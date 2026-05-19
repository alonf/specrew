---
proposal: 042
title: Specrew Integration Test Suite
status: candidate
phase: phase-2
estimated-sp: 30
discussion: tbd
---

# Specrew Integration Test Suite

## Why

Specrew currently has thin integration test coverage (`tests/integration/start-command.ps1`, `tests/integration/distribution-module-init.ps1`, etc.) that exercises specific scripts in narrow ways. There's no end-to-end test that runs a full lifecycle (`specrew init` → `specrew start` → `/speckit.specify` → ... → feature-closeout) in a headless / scripted way. **More urgently: there's no end-to-end test that exercises the user-facing command sequence (`specrew init → start → update → where → review`) on Linux, even though F-019's cross-platform workflow nominally claims Linux validation.**

Empirical motivation: F-019 Iter 2 surfaced a behavioral divergence between PowerShell script context and function context that DID NOT show up in the existing integration tests (those run scripts directly via `pwsh -File`, which doesn't reproduce the module-aliased invocation path). Behavioral-divergence tests would have caught the cross-platform issue before WSL manual verification.

**Stronger empirical motivation — 2026-05-19 WSL trial:** five Linux-only bugs (`MakeRelativeUri` crash in `specrew start`, `Get-SpecrewInstalledVersion` null in `specrew update --info`, `Get-Item -Force` crash in `specrew update`, `session_state` schema crash in `specrew start`, plus a sixth issue with the `[System.Uri]` constructor pattern across 6 sibling functions) all reached `main` despite F-019's `.github/workflows/cross-platform-validation.yml` claiming green on `ubuntu-latest`. The workflow runs validator + integration tests but NEVER actually invokes the command sequence a real user runs. That's the headline gap this proposal closes.

Also strategic: Specrew is a methodology product. A robust integration test suite IS marketing material — it demonstrates that Specrew's own development is trustworthy.

## What

### MVP scope (~20-25 SP)

- **Linux command-lifecycle E2E test (highest priority)**: a GHA workflow stage that, on Ubuntu and macOS, performs the actual user command sequence against a fresh synthetic project:

  ```
  specrew init
  specrew where                 # baseline dashboard
  specrew update --info         # all three platforms current, no crashes
  specrew start --dry-run       # exercises Get-RelativeDisplayPath, session-state readers, manifest-path resolution
  specrew update                # exercises Copy-MissingItem, deploy-speckit-extension, slash-surface refresh
  specrew where --json          # final state
  specrew review --help         # exercises Get-RelativePath
  ```

  Each command's exit code is asserted (0 unless the test expects failure). Output is captured to a transcript artifact. **This test would have caught all 5 bugs from the 2026-05-19 WSL trial** without any host-runtime mocking.
- **Headless lifecycle E2E test**: scripted fixture project that runs the full lifecycle from `specrew init` through `feature-closeout` without human input. Uses scripted Squad/Copilot responses (recorded vs replay) or a minimal mock host runtime.
- **CI matrix**: Windows + Ubuntu + macOS lanes, each running both the command-lifecycle and headless tests.
- **Behavioral-divergence tests**: explicitly test the function-vs-script context difference that surfaced in F-019. Run on every CI commit.
- **Flakiness handling**: retry policy + flaky-test quarantine + investigation flag.
- **Cross-version migration test**: for each shipped Specrew version pair `(0.NN.0, 0.NN+1.0)`, init at `0.NN.0`, then `specrew update` to `0.NN+1.0`, then run the command-lifecycle test. Composes with Proposal 059's legacy-state fixture corpus.

### Full scope (~25-30 SP)

- All of MVP plus:
- **Codespaces dev environment**: pre-configured Codespace with all dependencies (pwsh 7, uv, Node.js 24, Copilot CLI) so contributors can run the test suite without local setup.
- **Recorded Squad/Copilot fixture**: replayable Squad sessions for deterministic E2E testing without burning Premium quota on every CI run.
- **Property-based testing**: for path-handling, manifest parsing, validator rules — generate random inputs, check invariants.

### Out of scope

- Real-Squad / real-Copilot integration in CI (Premium quota cost prohibitive on every push)
- Coverage of every Specrew script — focus on lifecycle-critical paths
- Performance benchmarking (separate concern)

## Effort

- **Iteration 1 — Linux command-lifecycle E2E** (~8-10 SP): the new highest-priority scope. GHA workflow stage; assert-exit-code helper; command-lifecycle scenarios for `init → start --dry-run → update → where → review`. Catches the 2026-05-19 WSL trial bug class. **Recommend shipping this as its own iteration ahead of the rest of 042** so the bug-prevention return is realized fast.
- **Iteration 2 — Headless lifecycle E2E + CI matrix** (~10-12 SP): headless full-lifecycle test + Windows/Ubuntu/macOS matrix + behavioral-divergence + flakiness handling. Bulk of the original MVP scope.
- **Iteration 3 — Full scope** (~10 SP): Codespaces + recorded fixtures + property-based tests + cross-version migration tests (composes with [059](059-legacy-state-read-tolerance.md)).

**Total**: ~28-32 SP (revised up from ~25 to account for the explicit command-lifecycle scope and cross-version migration testing).

## Phase placement

**Phase 2**, before public flip. Strong predecessor to the [034](034-markdown-lint-strict-defaults-restoration.md) lint cleanup and [037](037-psscriptanalyzer-lint-cleanup.md) PSScriptAnalyzer cleanup — without a green CI baseline first, those cleanups can't be validated.

Recommend sequencing **after** [035](035-session-state-durability.md) (so state files have stable contract to test against) but **before** broader test-coverage work.

## Open questions

1. Recorded vs replay vs mock for Squad/Copilot interaction in E2E tests?
2. Codespaces config: official `.devcontainer.json` or unofficial Specrew-maintained fork?
3. Property-based test framework: PowerShell-native (PSGenericTester / similar) or external (FsCheck via .NET interop)?
4. Flakiness threshold: how many retries before a test is quarantined? When does quarantine expire?
5. Should CI run on every push or only on PR + main? (Cost vs feedback latency tradeoff.)

## Risks

- Recorded Squad fixtures can drift from real Squad behavior; need a "refresh fixtures" workflow on Squad upstream bumps (composes with [039](039-squad-upstream-reconciliation.md))
- E2E tests are slow; running them on every commit could slow CI feedback significantly

## Cross-references

- Composes with [009](009-velocity-dashboard.md) (dashboard rendering tests)
- Composes with [035](035-session-state-durability.md) (state-file contract testing)
- Composes with [039](039-squad-upstream-reconciliation.md) (behavioral-divergence tests bridge into upstream reconciliation)
- Composes with [059](059-legacy-state-read-tolerance.md) (Legacy-State Read-Tolerance) — legacy-state fixture corpus shares CI infrastructure; cross-version migration tests live here.
- Composes with [060](060-prerelease-channel-staging.md) (PSGallery Prerelease Channel) — the prerelease channel is the natural trigger for the full Integration Test Suite; every prerelease tag fires the matrix.
- Sibling of [037](037-psscriptanalyzer-lint-cleanup.md), [034](034-markdown-lint-strict-defaults-restoration.md) (all "green CI baseline" work)

## Status history

- 2026-05-16: captured as memory; promoted to candidate proposal 2026-05-18 during consolidation
- 2026-05-19: expanded scope to add Linux command-lifecycle E2E as Iteration 1 (highest priority), motivated by the 5-bug WSL trial cluster that F-019's existing cross-platform workflow failed to catch. Total SP revised from 25 to ~30.
