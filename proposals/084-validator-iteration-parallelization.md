---
proposal: 084
title: Validator Iteration Parallelization (PowerShell ForEach-Object -Parallel)
status: shipped
shipped-as: feature-035
shipped-at: 2026-05-22
phase: phase-2
estimated-sp: 7
actual-sp: 7
discussion: tbd
---

# Validator Iteration Parallelization (PowerShell `ForEach-Object -Parallel`)

## Why

Proposal 083 (Local Validator Speedup, in flight as of 2026-05-22) reduces validator scope from full-repo to changed-iterations-only via auto-applied `-ChangedOnly` on feature branches. This is a major win on the **scope** axis. The next bottleneck is the **per-iteration** axis: each iteration's validation runs sequentially in a single PowerShell loop.

For features touching multiple iterations, the per-iteration time multiplies. Empirical data from 083's own implementation (2026-05-22) shows individual validator integration test runs of **~23m 37s and ~15m+** within a single implementation phase. Even when scoped down to a handful of changed iterations via 083's work, each iteration still takes meaningful time and they run one-at-a-time.

### Empirical motivation

The Crew building 083 itself paid the sequential-validation cost in spades. Observed during 083's implementation phase:

- One validator integration test run: **23m 37s**
- A subsequent run (final integration tests): **15m+ still running at the time of observation**
- Aggregate validator-burn in 083's implementation phase alone: **~40+ minutes**

This is BEFORE 083 even ships its auto-scope. Once 083 lands, scope drops dramatically — but the per-iteration loop remains serial. For multi-iteration features, the serial loop becomes the next bottleneck.

### User direction (2026-05-22)

> "So we validate each changed file. Can we validate them concurrently?"

Answer: yes. PowerShell 7+'s `ForEach-Object -Parallel -ThrottleLimit <N>` runs each iteration's validation in its own runspace concurrently. Independent iterations make parallelization safe.

## What

### Pillar 1: Parallel iteration loop in `validate-governance.ps1`

Replace the current sequential `foreach` loop over changed iterations:

```powershell
# Today (post-083):
foreach ($iteration in $changedIterations) {
    Test-IterationGovernance -Path $iteration
}
```

with `ForEach-Object -Parallel`:

```powershell
# This proposal:
$results = $changedIterations | ForEach-Object -Parallel {
    . $using:sharedGovernancePath   # source helpers into the runspace
    $iterResult = Test-IterationGovernance -Path $_
    [pscustomobject]@{ Iteration = $_; Result = $iterResult }
} -ThrottleLimit (Get-SpecrewValidatorParallelism)
```

Each runspace is independent. Results are collected post-parallel and rendered in deterministic order (sorted by iteration path) so output remains stable.

### Pillar 2: Throttle-limit configuration

Configurable throttle limit via priority chain:

1. Explicit `-ThrottleLimit <N>` parameter to `validate-governance.ps1`
2. `.specrew/iteration-config.yml` key `validator.parallelism: N`
3. Default: `[Environment]::ProcessorCount` capped at 6 (conservative for memory budget)

Setting `-ThrottleLimit 1` effectively disables parallelization (single thread), useful for debugging when interleaved output is unhelpful.

### Pillar 3: Output ordering + error reporting

Parallel runspaces produce results in non-deterministic order. The validator must render results in a stable, human-friendly order:

- Collect all `[pscustomobject]@{ Iteration = $path; Result = $...}` from the parallel block
- Sort by `Iteration` path ascending
- Render serial output (PASS / FAIL / WARN per iteration) in sorted order
- Aggregate exit codes: if ANY iteration fails, validator exit code is non-zero

Each iteration's diagnostic messages stay grouped under its iteration heading; no interleaved output across iterations. This preserves the existing UX of "validator emits sections per iteration."

### Pillar 4: `-NoParallel` opt-out flag

Add `-NoParallel` flag to `validate-governance.ps1` that forces single-threaded execution. Use cases:

- Debugging when parallel runspaces obscure failure context
- Low-memory environments where the throttle-limit budget exceeds available memory
- CI configurations that prefer serial output for log readability

When `-NoParallel` is passed, falls through to the existing sequential `foreach` path. Behavior identical to pre-084.

### Pillar 5: `[validator-parallelism]` stdout banner

Compose with 083's `[validator-scope]` banner. Add a `[validator-parallelism]` line:

```
[validator-scope] auto-scoped to origin/main...HEAD (3 iterations, 5 files in diff)
[validator-parallelism] parallel mode, throttle-limit=6, iteration runspaces=3
[validator-timing] mode=scoped elapsed_ms=12340 iterations_validated=3 trigger_source=local
```

Stable order across the three banners. Each line is one-shot informational; no other formatting changes.

## How (implementation plan)

This slice ships AFTER v0.24.2 bundle merges (083 + 082 T1 + PR #423 + 081 Pillar 6 + chore-gate ext). The new auto-scope (083) becomes the baseline this proposal builds on.

| Step | File | Effort |
|---|---|---|
| Refactor `validate-governance.ps1` iteration loop to `ForEach-Object -Parallel` | `extensions/specrew-speckit/scripts/validate-governance.ps1` (+ mirrors) | 2 SP |
| Add `Get-SpecrewValidatorParallelism` helper with priority chain (param → config → default) | `extensions/specrew-speckit/scripts/shared-governance.ps1` (+ mirrors) | 1 SP |
| Add `-ThrottleLimit` parameter + `-NoParallel` opt-out to `validate-governance.ps1` | same | 0.5 SP |
| Output ordering: collect parallel results, sort by iteration, render serial | same | 1 SP |
| `[validator-parallelism]` stdout banner | same | 0.25 SP |
| `.specrew/iteration-config.yml` schema: `validator.parallelism` key | template + downstream sync | 0.5 SP |
| Tests: parallel output equivalence (same results as sequential); throttle-limit=1 falls back to serial; -NoParallel opt-out works | `tests/integration/validate-governance-parallel.tests.ps1` (new) | 1.5 SP |
| Mirror parity sweep | both mirrors | 0.5 SP |
| CHANGELOG entry + INDEX update | docs | 0.25 SP |

Total: **~7-8 SP**. Small-fix-or-feature slice depending on test scope.

**Ship target**: v0.25.0 alongside Proposal 078 (Handoff Conversation Quality), OR v0.25.1 as a fast follow-up to v0.25.0.

## Composition with other proposals

| Proposal | Relationship |
|---|---|
| **Proposal 083 (Local Validator Speedup)** | Direct predecessor. 083 ships auto-scope (scope axis); 084 ships parallelization (per-iteration axis). Together: ~40× speedup for typical multi-iteration features (auto-scope ~5×, parallelization ~6×, multiplied). |
| **Proposal 042 (Specrew Integration Test Suite)** | 042 already absorbs Contract lane parallelization (different surface — 6 sequential lane scripts, not validator iteration loop). 084 is the SIBLING work for the validator's iteration loop. Both apply `ForEach-Object -Parallel`; different call sites. |
| **Proposal 030 (Quality Hardening Bundle)** | Could absorb 084 if shipped together later. 084 standalone is the cleaner ship path. |
| **Proposal 040/070 (Token Economy)** | If `validator.parallelism` is exposed via `iteration-config.yml`, it composes with the broader configuration surface 040/070 envision. |
| **Proposal 045 (CI Watchdog & Recurrence Prevention)** | Adjacent; 045 watches for regressions, 084 speeds local detection. Orthogonal. |
| **Empirical data from 083's own implementation** | 2026-05-22 observation of ~40 min validator-burn in 083's implementation phase directly motivates this slice. |

## Acceptance signals

- **AC1**: `validate-governance.ps1` runs iteration loop in parallel via `ForEach-Object -Parallel` by default on PowerShell 7+. Verified by running on a multi-iteration feature branch and observing parallel runspace creation in `[validator-parallelism]` banner.
- **AC2**: `-ThrottleLimit <N>` parameter respects priority chain (param > config > default).
- **AC3**: `-NoParallel` opt-out falls through to existing sequential `foreach` path. Verified by test.
- **AC4**: Output order is deterministic — same iteration order regardless of parallel scheduling. Verified by running parallel + serial against same input, diffing output.
- **AC5**: Aggregate exit code matches sequential semantics — any failed iteration → non-zero exit.
- **AC6**: `[validator-parallelism]` stdout banner appears with accurate parallelism info.
- **AC7**: Empirical perf — validator on a feature touching 3-5 iterations completes in roughly the slowest single-iteration time (not the sum). Captured in CHANGELOG with before/after numbers.
- **AC8**: No regression in error reporting — diagnostic messages stay grouped by iteration; no interleaved log lines across iterations.
- **AC9**: Mirror parity across `extensions/specrew-speckit/` + `.specify/extensions/specrew-speckit/`.

## Out of scope

- **CI-side parallelization**: PR-CI Lint job is already scoped via `ci(lint-scoping)`; CI parallelization would compose with this work but isn't required as part of this slice.
- **Cross-host parallelism (multi-machine)**: PowerShell `ForEach-Object -Parallel` is single-host multi-threaded. Distributed validation across machines (e.g., GitHub Actions matrix) is out of scope.
- **Per-rule parallelization within an iteration**: `Test-IterationGovernance` invokes many rules sequentially within an iteration. Parallelizing within an iteration is possible but more complex (shared state, output ordering). Out of scope; can be a future Tier 2 if 084 itself isn't sufficient.
- **Auto-tuning the throttle limit based on iteration content size**: 084 ships with a static cap (`[Environment]::ProcessorCount` capped at 6). Future work could auto-tune based on iteration size/complexity.

## Cross-references

- **User direction**: 2026-05-22 conversation, "So we validate each changed file. Can we validate them concurrently?"
- **Empirical evidence**: 2026-05-22 observation of ~40+ min validator burn in 083's own implementation phase (one 23m 37s run + one 15m+ ongoing run); the Crew building the auto-scope feature was bottlenecked by the same loop this proposal parallelizes.
- **Proposal 083**: file:///C:/Dev/Specrew/proposals/083-local-validator-speedup.md
- **Proposal 042**: file:///C:/Dev/Specrew/proposals/042-specrew-integration-test-suite.md (Contract lane parallelization is the sibling work)
- **Memory `[[project-velocity-tracking-post-v0-24-2-2026-05-22]]`**: empirical baseline that 084 will improve further
- **Memory `[[project-post-f029-sequencing-2026-05-21]]`**: current canonical queue; 084 slots post-v0.24.2 bundle
- INDEX: file:///C:/Dev/Specrew/proposals/INDEX.md
