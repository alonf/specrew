# Feature Specification: Validator Iteration Parallelization

**Feature Branch**: `chore-084-validator-iteration-parallelization`
**Proposal**: [Proposal 084](../../proposals/084-validator-iteration-parallelization.md)
**Created**: 2026-05-22
**Status**: Draft
**Version**: v0.24.3 slice (process-optimization bundle, slot 4)

## Clarifications

### Session 2026-05-22

- **Q: In-process parallel (ForEach-Object -Parallel runspaces) vs subprocess invocation?** → **A: Subprocess via `pwsh -File validate-governance.ps1 -IterationPath X` invoked from ForEach-Object -Parallel. Avoids the ~50-helper-function refactor that in-process runspaces require. Each subprocess has its own isolated state; cache file is shared and must be file-locked.**

- **Q: How does this compose with Proposal 086 Pillar 1 (memoization)?** → **A: A serial pre-pass first reads the cache for all targets. Cache hits return immediately (~1ms each). Only cache MISSES go through parallel subprocess validation. This avoids paying subprocess overhead on warm-cache runs (where serial cache reads are faster).**

- **Q: How is output kept deterministic?** → **A: Parallel results are collected, then sorted by iteration path before rendering. Each iteration's diagnostic output is captured and rendered in sorted order. No interleaved output across iterations.**

## User Scenarios & Testing

### User Story 1 — Cold-cache validator on multi-iteration corpus drops from ~22min to ~4min (Priority: P1)

A developer runs `validate-governance.ps1` against a corpus of 44 iterations with no cache populated. Currently serial: ~22 min. With parallelization at throttle 6: ~4 min (~5× speedup on cache misses).

**Why this priority**: Primary perf win for cold-cache / fresh-clone scenarios.

**Independent Test**: Run validator on a 44-iteration corpus with empty cache, measure wall-clock. Expect ~4-6 min instead of ~22.

**Acceptance Scenarios**:

1. **Given** a corpus with no cache, **When** validator runs without `-NoParallel`, **Then** completes in roughly slowest-iteration-time × ceil(N/throttle) instead of sum-of-all-iterations (AC1).
2. **Given** validator runs in parallel mode, **When** complete, **Then** output is rendered in deterministic iteration-path order (AC2).

---

### User Story 2 — Warm-cache runs stay fast (parallel doesn't hurt) (Priority: P1)

A developer with a populated cache re-runs validator. Currently with 086 P1: ~4 seconds. With parallelization: should NOT regress. Pre-pass cache check handles cache hits serially (~1ms each), only cache misses go parallel.

**Why this priority**: Combined with Proposal 086 P1, the common warm-cache case must not regress.

**Acceptance Scenarios**:

1. **Given** a fully-populated cache, **When** validator runs, **Then** cache hits served from pre-pass; no subprocess spawns; completes in roughly the same time as serial (no regression) (AC3).
2. **Given** a partially-populated cache (some hits, some misses), **When** validator runs, **Then** hits served from pre-pass + misses parallelized (AC4).

---

### User Story 3 — `-NoParallel` opt-out works (Priority: P2)

A developer wants serial execution for debugging. They pass `-NoParallel`. The validator runs entirely serially.

**Acceptance Scenarios**:

1. **Given** `-NoParallel` is passed, **When** validator runs, **Then** no subprocesses spawn; behavior matches pre-084 baseline (AC5).

---

### User Story 4 — Cache writes survive concurrent processes (Priority: P1)

Parallel subprocesses write to the same `.specrew/.cache/validator-cache.json`. File locking prevents corruption.

**Acceptance Scenarios**:

1. **Given** N parallel validator subprocesses each write a new cache entry, **When** all complete, **Then** every entry is present in the cache file (no lost writes) (AC6).
2. **Given** N parallel subprocesses, **When** complete, **Then** cache file is valid JSON and not corrupted (AC7).

---

### User Story 5 — `-ThrottleLimit` controls concurrency (Priority: P2)

A developer wants to tune parallelism. `-ThrottleLimit 12` allows up to 12 concurrent subprocesses. Default 6.

**Acceptance Scenarios**:

1. **Given** `-ThrottleLimit 12`, **When** validator runs with 12+ iterations, **Then** up to 12 subprocesses run concurrently (AC8).

---

## Functional Requirements

- **FR-001**: System MUST add `Invoke-WithFileLock` helper to `extensions/specrew-speckit/scripts/shared-governance.ps1` (+ mirror) that takes a file path + script block, acquires an exclusive file lock, invokes the script block, releases the lock. Retries up to 10 times with 100ms backoff if lock is contended (AC6, AC7).

- **FR-002**: `Set-ValidatorCacheEntry` MUST use `Invoke-WithFileLock` around all cache file read/write operations to prevent concurrent-write corruption (AC6, AC7).

- **FR-003**: `validate-governance.ps1` MUST add `-NoParallel` switch and `-ThrottleLimit <N>` parameter (default 6) (AC5, AC8).

- **FR-004**: When `-NoParallel` is set: behavior matches pre-084 baseline (serial iteration loop) (AC5).

- **FR-005**: When parallel mode is active (default, PowerShell 7+, multi-iteration): pre-pass reads cache for all targets serially; cache hits collected immediately; cache misses partitioned for parallel subprocess validation (AC3, AC4).

- **FR-006**: Cache misses validated via `ForEach-Object -Parallel { ... } -ThrottleLimit $ThrottleLimit`. Each parallel branch invokes `pwsh -File validate-governance.ps1 -IterationPath <iter> -NoParallel` (the `-NoParallel` flag prevents recursion) (AC1).

- **FR-007**: Subprocess results captured as `{ Path, Errors, ExitCode }` objects. Failed-to-launch subprocesses generate a synthetic error entry rather than silently dropping the iteration (AC1, AC2).

- **FR-008**: Final results merged: cache hits + parallel results, sorted by path, rendered in deterministic order (AC2).

- **FR-009**: Mirror parity MUST be preserved across `extensions/specrew-speckit/` and `.specify/extensions/specrew-speckit/` for `shared-governance.ps1`.

- **FR-010**: Integration tests at `tests/integration/validator-parallelization.tests.ps1` MUST cover: `-NoParallel` falls back to serial; `-ThrottleLimit` parameter respected; deterministic output ordering; concurrent cache writes survive (no lost entries); file lock helper handles contention.

- **FR-011**: CHANGELOG.md MUST contain an entry under `Changed` referencing Proposal 084, the empirical motivation, and the parallel vs serial trade-off.

## Out of Scope

- In-process runspace parallelism (would require ~50-helper refactor; subprocess approach pragmatic for v1)
- Auto-tune of throttle limit based on iteration content size
- Per-rule parallelization within an iteration (Pillar 2 territory)
- Cross-machine distributed validation

## Acceptance Criteria Summary

| AC | Verifies | Trace |
|---|---|---|
| AC1 | Cold-cache run drops to ~slowest-iteration-time × ceil(N/throttle) | FR-005, FR-006 |
| AC2 | Output deterministic by iteration path | FR-008 |
| AC3 | Warm-cache runs don't regress | FR-005 |
| AC4 | Partial cache (mix hits + misses) works | FR-005, FR-006 |
| AC5 | `-NoParallel` matches pre-084 behavior | FR-003, FR-004 |
| AC6 | Concurrent cache writes preserved (no lost entries) | FR-001, FR-002 |
| AC7 | Cache file valid JSON after parallel run | FR-001, FR-002 |
| AC8 | `-ThrottleLimit` respected | FR-003 |

---

**Maintained by**: Alon Fliess | **Last Updated**: 2026-05-22
