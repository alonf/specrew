---
proposal: 042
title: Specrew Integration Test Suite
status: candidate
phase: phase-2
estimated-sp: 25
discussion: tbd
---

# Specrew Integration Test Suite

## Why

Specrew currently has thin integration test coverage (`tests/integration/start-command.ps1`, `tests/integration/distribution-module-init.ps1`, etc.) that exercises specific scripts in narrow ways. There's no end-to-end test that runs a full lifecycle (`specrew init` → `specrew start` → `/speckit.specify` → ... → feature-closeout) in a headless / scripted way.

Empirical motivation: F-019 Iter 2 surfaced a behavioral divergence between PowerShell script context and function context that DID NOT show up in the existing integration tests (those run scripts directly via `pwsh -File`, which doesn't reproduce the module-aliased invocation path). Behavioral-divergence tests would have caught the cross-platform issue before WSL manual verification.

Also strategic: Specrew is a methodology product. A robust integration test suite IS marketing material — it demonstrates that Specrew's own development is trustworthy.

## What

### MVP scope (~15-20 SP)

- **Headless E2E lifecycle test**: scripted fixture project that runs the full lifecycle from `specrew init` through `feature-closeout` without human input. Uses scripted Squad/Copilot responses (recorded vs replay) or a minimal mock host runtime.
- **CI matrix**: Windows + Ubuntu + macOS lanes, each running the headless E2E test.
- **Behavioral-divergence tests**: explicitly test the function-vs-script context difference that surfaced in F-019. Run on every CI commit.
- **Flakiness handling**: retry policy + flaky-test quarantine + investigation flag.

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

- **Iteration 1 — MVP** (~15-20 SP): headless E2E + CI matrix + behavioral-divergence + flakiness handling
- **Iteration 2 — Full scope** (~10 SP): Codespaces + recorded fixtures + property-based tests

**Total**: ~25-30 SP

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
- Sibling of [037](037-psscriptanalyzer-lint-cleanup.md), [034](034-markdown-lint-strict-defaults-restoration.md) (all "green CI baseline" work)

## Status history

- 2026-05-16: captured as memory; promoted to candidate proposal 2026-05-18 during consolidation
