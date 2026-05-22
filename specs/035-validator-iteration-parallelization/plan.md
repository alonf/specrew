# Plan: Validator Iteration Parallelization

**Spec**: [spec.md](spec.md)
**Proposal**: [Proposal 084](../../proposals/084-validator-iteration-parallelization.md)
**Created**: 2026-05-22
**Status**: Approved

## Approach

Augment `validate-governance.ps1` with optional subprocess-based parallelization of the iteration validation loop. Use PowerShell 7+ `ForEach-Object -Parallel` with `-ThrottleLimit` to control concurrency. Cache the same `validator-cache.json` file but protect concurrent writes with a file lock helper.

### Phase 1 — Cache concurrency safety

Subprocess parallelism means N validator processes can hit `Set-ValidatorCacheEntry` simultaneously. Without protection, last-writer-wins causes lost cache entries.

1. **Add `Invoke-WithFileLock` helper to `shared-governance.ps1` (and mirror)**: Acquires exclusive file lock via `[System.IO.FileStream]` with `[System.IO.FileShare]::None`. Retries up to 10× with 100ms backoff. Releases lock on exit (`finally`).
2. **Wrap `Set-ValidatorCacheEntry` body in `Invoke-WithFileLock`**: Read → mutate → write happens inside the lock atomically.
3. **Test**: Spin up 8 concurrent subprocesses each writing a distinct cache key. Verify cache file is valid JSON and contains all 8 entries.

### Phase 2 — Pre-pass cache check + parallel-misses path

The current iteration loop sequentially calls cache lookup → validation → cache store. To avoid paying subprocess overhead on warm-cache iterations, split into:

1. **Pre-pass (serial, ~1ms per iteration)**: For each iteration target, compute cache key, read cache. Collect cache hits into `$cacheHitResults`. Collect cache misses into `$missTargets`.
2. **Parallel pass (subprocess, only for misses)**: `$missTargets | ForEach-Object -Parallel { pwsh -NoProfile -File $using:validatorScript -IterationPath $_.Path -ProjectPath $using:projectPath -NoParallel } -ThrottleLimit $ThrottleLimit`.
3. **Merge + sort**: Cache hits + parallel results → sort by path → render diagnostics in deterministic order.

### Phase 3 — Parameter wiring

1. Add `[switch]$NoParallel` parameter to `validate-governance.ps1`.
2. Add `[int]$ThrottleLimit = 6` parameter.
3. Banner: when parallel mode is engaged, print `[validator-parallelism] N targets, M cache hits served from pre-pass, K misses validated in parallel (throttle=$ThrottleLimit)`.
4. PowerShell version check: skip parallel path if `$PSVersionTable.PSVersion.Major -lt 7` (fall back to serial with a warning).

### Phase 4 — Testing + sign-off

1. Integration tests in `tests/integration/validator-parallelization.tests.ps1`:
   - File-lock helper handles N=8 concurrent writers (no lost entries)
   - `-NoParallel` falls back to serial path (no subprocess spawns)
   - `-ThrottleLimit` parameter is wired through
   - Deterministic output ordering verified across parallel + serial runs
2. CHANGELOG entry under `Changed` referencing Proposal 084
3. Mirror parity verification (SHA256 of `shared-governance.ps1` matches across both trees)

## Risk + Mitigation

| Risk | Mitigation |
|---|---|
| Subprocess spawn overhead (~1s) overshadows cache-hit speed | Pre-pass cache check; parallel only on misses |
| Concurrent cache writes corrupt the file | `Invoke-WithFileLock` with retry-on-contention |
| Recursive parallel calls (subprocess invokes another parallel loop) | Subprocess invocation always passes `-NoParallel` |
| Subprocess output interleaved | Captured per-subprocess; rendered after sort |
| ForEach-Object -Parallel unavailable on PS 5.x | Version check + serial fallback |

## Composition with Other Proposals

- **Proposal 086 P1 (memoization)**: F-035 builds directly on top. Pre-pass uses the cache; parallel pass writes back through the file-locked Set-ValidatorCacheEntry.
- **Proposal 085 (skip closed iterations)**: Future composition — closed iterations skipped from `$targets`; parallelization applies to remaining open iterations.
- **Proposal 086 P3 (metadata cache)**: When P3 ships, the pre-pass also reads metadata cache; parallel subprocesses also write through file lock.

## Out of Scope (explicit deferral)

- Per-rule parallelization within a single iteration validation (Pillar 2 territory)
- Auto-tune of ThrottleLimit
- In-process runspace parallelism (avoid ~50-helper refactor for v1)
- Distributed validation across machines
