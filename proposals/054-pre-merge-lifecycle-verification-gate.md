---
proposal: 054
title: Pre-Merge End-to-End Lifecycle Verification Gate
status: candidate
phase: phase-2
estimated-sp: 15
discussion: tbd
---

# Pre-Merge End-to-End Lifecycle Verification Gate

## Why

F-020 (Session-State Durability) shipped to main on 2026-05-18 with three production bugs that blocked the very next feature start:

1. **Schema parity gap**: the Phase 0 closeout-pattern helper `Set-FeatureCloseoutIdentityNow` writes `.squad/identity/now.md` with human-readable frontmatter (`updated_at`, `focus_area`, `active_issues`). But F-020's stale-state validator `Get-SpecrewSessionStateFromFrontmatter` requires machine-readable `session_state_*` fields. Form-vs-meaning gap: helper writes one schema, validator reads another. Both were tested IN ISOLATION. The interaction wasn't tested.

2. **Boundary-sync hook-coverage gap**: F-020 FR-003 required `Invoke-SpecrewBoundaryStateSync` to fire at all 7 lifecycle boundaries. Empirical check after F-021 shipped: `.squad/decisions.md` only had boundary-sync entries through `plan`. Subsequent F-021 boundaries (tasks, before-implement, implement, review, retro, iteration-closeout, feature-closeout) never wrote sync entries. The function exists but isn't called at the right hooks. F-020's tests verified the function works when called; they didn't verify it gets called at the right times.

3. **Stale-state recovery UI gap**: when validator detects stale state, `specrew start` prints A/B/C options as text without accepting input and exits without starting Copilot. Users get stuck — the very thing that could fix the state needs the state to be valid to start. F-020's design called for this recovery flow but the implementation shipped without it being interactive.

**All three bugs share a pattern**: each was tested at the unit level. None were tested at the end-to-end level (ship a feature, restart Squad, verify clean start). The bug class is **integration drift between components** — each component works correctly in isolation but they don't compose correctly. Specrew's distinctive value is governing AI-assisted decision-making across a complex pipeline; without end-to-end pre-merge tests, the pipeline can drift component by component until a downstream failure surfaces it.

This proposal establishes a pre-merge end-to-end lifecycle verification gate that exercises Specrew's full ship-feature-then-restart cycle on every PR before merge to main. **The gate would have caught all three F-020 bugs before they reached main.**

## What

### Three test scenarios as the gate baseline

**Scenario A: Full lifecycle ship-and-restart**

Simulate a complete feature lifecycle:

1. Start from a clean post-feature-closeout state (no active feature)
2. Run `specrew start` — verify it launches cleanly
3. Initiate a minimal test feature (specify → clarify → plan → tasks → before-implement → implement → review → retro → iteration-closeout → feature-closeout)
4. Verify each boundary writes appropriate state to: `.squad/identity/now.md`, `.squad/decisions.md`, `.specrew/last-start-prompt.md`, `.specrew/start-context.json`, `.specify/feature.json`
5. After feature-closeout, restart Squad — verify clean start with NO stale-state errors

**Would have caught**: Bug 1 (closeout-helper schema mismatch surfaces when restart reads now.md), Bug 2 (boundary-sync hook coverage surfaces when decisions.md missing entries detected), Bug 3 (stale-state recovery UI surfaces if any earlier bug triggers recovery flow).

**Scenario B: Schema parity audit**

For every state-writer function in Specrew (helpers in `scripts/internal/`, scaffold scripts in `extensions/specrew-speckit/scripts/`), assert that its output can be parsed by every state-reader function that consumes it. This is a structural type-check applied to file-based interfaces:

- `Set-FeatureCloseoutIdentityNow` writes now.md → `Get-SpecrewIdentitySessionState` reads now.md → output of writer must parse cleanly with reader
- `Invoke-SpecrewBoundaryStateSync` writes decisions.md entry → `Get-LatestSpecrewBoundarySyncState` reads decisions.md → output must parse cleanly
- All other writer/reader pairs across the F-020 state-surface

Implementation pattern: a generic parity-test framework that takes a writer + a reader and asserts round-trip equivalence on canonical fixtures.

**Would have caught**: Bug 1 (schema-mismatch surfaces immediately).

**Scenario C: Boundary-sync hook-coverage**

For each of the 7 lifecycle boundaries (specify, clarify, plan, tasks, review-signoff, iteration-closeout, feature-closeout), verify that running the boundary's scaffolding script invokes `Invoke-SpecrewBoundaryStateSync` with the correct boundary type. Static analysis + integration test combination:

- Static: grep each scaffold script for `Invoke-SpecrewBoundaryStateSync` call; flag missing
- Integration: run each boundary script with a minimal fixture; check `.squad/decisions.md` for the expected sync entry

**Would have caught**: Bug 2 (hook-coverage surfaces immediately).

### CI / PR gate integration

Add a new GitHub Actions workflow `.github/workflows/lifecycle-verification.yml` that:

- Triggers on every PR targeting `main`
- Runs Scenarios A, B, C in sequence
- Reports clearly which scenario failed (per-bug-class diagnostic, not generic "tests failed")
- **Marks the check as required for merge** via GitHub branch protection rules
- Composes with existing CI workflows (`specrew-ci.yml`, `cross-platform-validation.yml`)

PR merge to main blocked until lifecycle verification passes.

### Per-PR confidence scoring

Beyond pass/fail, the gate produces a confidence score for each PR:

- **Schema parity coverage**: percentage of writer/reader pairs covered by the parity audit
- **Boundary hook coverage**: percentage of boundaries with verified sync calls
- **Lifecycle scenario count**: how many distinct end-to-end paths were exercised
- **Time-to-detect**: at which scenario step did the failure surface (earlier = easier to diagnose)

Surface the score on the PR via a comment so reviewers see "this PR has X% coverage of the F-020 surface" before merge.

## Effort

~15 SP, single iteration:

- Scenario A implementation (full lifecycle simulator + assertions) — ~5 SP
- Scenario B implementation (parity audit framework + writer/reader pairs registry) — ~4 SP
- Scenario C implementation (boundary hook-coverage check) — ~2 SP
- CI workflow (`lifecycle-verification.yml`) — ~2 SP
- PR comment script (confidence scoring) — ~1 SP
- Documentation: `docs/lifecycle-verification-gate.md` explaining the gate and how authors write new scenarios — ~1 SP

## Phase placement

**Phase 2, HIGH-PRIORITY**, post-F-022 (the F-020 bug hotfix). F-022 fixes the three specific bugs that exposed this gap. Proposal 054 prevents the next class of bug from reaching main.

Sequence:

- F-022 (hotfix) ships first — restores Specrew to working state
- Proposal 054 ships next as a Phase 2 priority — makes the gate the durable enforcement
- All subsequent features pass through the gate before merge

## Composition with existing proposals

- **Proposal 030 (Quality Hardening Bundle — Form-vs-Meaning Verification)**: Scenario B (schema parity) IS one of Proposal 030's sub-components. Could absorb 054 Scenario B into 030, or 030 absorbs 054 entirely. Either way, both proposals target the same bug class.
- **Proposal 042 (Specrew Integration Test Suite)**: 042 is the broader integration test ambition. 054 is the gate (PR-blocking) layer on top of 042's tests. Could ship 042 first as the test infrastructure, then 054 as the gate that uses it.
- **Proposal 045 (CI Watchdog & Recurrence Prevention)**: 054 plugs into 045's watchdog — failed lifecycle verification is exactly the recurrence pattern 045 detects.
- **Proposal 014 (Red Team Agent)**: could incorporate 054's scenarios as adversarial-mode targets — Red Team agent tries to break the lifecycle, verification gate proves it can't.
- **F-022 (Reactive Hotfix)**: F-022 ships the three specific bug fixes + minimal regression tests. F-022's tests are SCENARIO-SHAPED (catch these bugs) but not yet generalized into the structural gate. Proposal 054 generalizes F-022's tests into the durable infrastructure.

## Open questions

1. **Gate strictness**: should the gate be REQUIRED for merge (blocks PR) or RECOMMENDED (PR comment but doesn't block)? Recommend REQUIRED for main; could be relaxed for feature branches.
2. **CI duration budget**: full lifecycle simulation could take 5-10 minutes per PR. Acceptable? Or should fast-path / smoke-test mode exist for trivial PRs?
3. **Fixture maintenance**: lifecycle scenarios need fixture data (minimal test feature, mock state files, etc.). Where do fixtures live, how are they updated?
4. **Cross-platform matrix**: should the gate run on Windows + Linux + macOS, or just one? Recommend matrix to catch path-handling bugs (F-019's repair history shows this matters).
5. **Per-PR vs per-merge**: gate on every PR push vs only on the final pre-merge commit? Per-push is heavier but catches regressions sooner.
6. **Bug-specific guards**: should the gate include guard tests for past bugs (F-019, F-020) so they never regress? Recommend yes as a separate test-suite within the gate.
7. **Schema registry maintenance**: the writer/reader pairs list needs upkeep as Specrew evolves. Should this be auto-generated, hand-maintained, or community-contributed?
8. **Test isolation**: lifecycle tests need to write to a sandbox, not the real repo. How is sandboxing implemented? Recommend per-test temporary clones.
9. **F-022 dependency**: should Proposal 054 be implemented only after F-022 fixes the underlying bugs, or in parallel? Recommend after F-022 — let F-022 fix the bugs, then 054 prevents the next ones.
10. **Failure communication**: when the gate fails, what's the diagnostic UX? Plain text? Annotated PR diff? Detailed log + summary?

## Risks

- **CI infrastructure overhead**: 15 SP feature + ongoing maintenance + every PR pays 5-10 min CI cost. Worth it given the cost of bugs reaching main (F-020 bugs cost roughly 3 hours of human reconciliation work). Mitigation: design for fast-path / smoke mode.
- **False positives blocking valid PRs**: a too-strict gate could block legitimate work. Mitigation: clear bypass mechanism for explicit human override + rapid iteration on false-positive feedback.
- **Test fragility**: end-to-end tests are notoriously flaky. Mitigation: per-test sandboxing; deterministic fixtures; retry logic at the CI level.
- **Specrew is updating ITS OWN test infrastructure**: meta-bug class. Mitigation: test infrastructure tests itself with a known-failing fixture (canary test that should always fail; if it passes, the gate is broken).
- **Scenario coverage gaps**: the gate is only as good as the scenarios. Mitigation: every new feature must add scenarios to the gate; Spec Steward checklist requires it.

## Cross-references

- **F-020 (Session-State Durability)** — the feature whose implementation bugs motivated this proposal; F-020 retro lessons feed into 054's scenario design
- **F-022 (F-020 Implementation Hotfix)** — fixes the specific bugs; 054 generalizes the test coverage
- **Proposal 030 (Quality Hardening Bundle — Form-vs-Meaning Verification)** — Scenario B (schema parity) directly addresses 030's core concern
- **Proposal 042 (Specrew Integration Test Suite)** — 042 is the broader test infrastructure; 054 is the PR-gate layer using it
- **Proposal 045 (CI Watchdog & Recurrence Prevention)** — 054 plugs into 045
- **Proposal 053 (Autopilot Decision Transparency)** — composes; gate failures should be transparent in PR comments

## Status history

- 2026-05-18: candidate captured after F-020 implementation bugs shipped to main and blocked the next feature start. Three bugs (schema mismatch, hook-coverage gap, recovery-UI broken) all shipped despite F-020 having unit tests. Pattern: each component tested in isolation; integration drift undetected. Proposal targets the gap with a pre-merge end-to-end lifecycle verification gate that would have caught all three bugs.
