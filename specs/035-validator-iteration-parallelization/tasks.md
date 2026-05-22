# Tasks: Validator Iteration Parallelization

**Spec**: [spec.md](spec.md)
**Plan**: [plan.md](plan.md)
**Proposal**: [Proposal 084](../../proposals/084-validator-iteration-parallelization.md)

## T001 — Phase 1: Add `Invoke-WithFileLock` helper to shared-governance.ps1

**Files**: `extensions/specrew-speckit/scripts/shared-governance.ps1` (+ mirror)
**Verifies**: FR-001
**Done when**: Function exported; takes `-FilePath` + `-ScriptBlock`; acquires exclusive file lock via `[System.IO.FileStream]` with `[System.IO.FileShare]::None`; retries up to 10× with 100ms backoff; releases lock in `finally`.

## T002 — Phase 1: Wrap Set-ValidatorCacheEntry body with file lock

**Files**: `extensions/specrew-speckit/scripts/shared-governance.ps1` (+ mirror)
**Verifies**: FR-002, AC6, AC7
**Done when**: Cache file read + mutate + write executes inside `Invoke-WithFileLock` block. Lock file at `<cache>.lock`. Test: 8 concurrent subprocess writes all preserved.

## T003 — Phase 3: Add `-NoParallel` switch + `-ThrottleLimit` parameter

**Files**: `extensions/specrew-speckit/scripts/validate-governance.ps1` (+ mirror)
**Verifies**: FR-003, AC5, AC8
**Done when**: New params present at top of script. `-NoParallel` defaults to false. `-ThrottleLimit` defaults to 6.

## T004 — Phase 2: Pre-pass cache check + parallel-misses path

**Files**: `extensions/specrew-speckit/scripts/validate-governance.ps1` (+ mirror)
**Verifies**: FR-005, FR-006, AC1, AC3, AC4
**Done when**:

- Iteration loop refactored to pre-pass serial + parallel misses
- Pre-pass reads cache for each target; partitions into hits vs misses
- Parallel pass uses `$missTargets | ForEach-Object -Parallel { pwsh -NoProfile -File $using:validatorScript -IterationPath $_ -NoParallel } -ThrottleLimit $ThrottleLimit`
- PowerShell version check (PS 7+ required); fallback to serial otherwise
- `-NoParallel` flag short-circuits to original serial path

## T005 — Phase 2: Subprocess result capture + deterministic sort

**Files**: `extensions/specrew-speckit/scripts/validate-governance.ps1` (+ mirror)
**Verifies**: FR-007, FR-008, AC2
**Done when**:

- Subprocess invocation captures stdout/stderr + exit code per iteration
- Failed-to-launch subprocesses generate a synthetic error rather than dropping silently
- Results merged: cache hits + parallel results
- Results sorted by iteration path before rendering
- Banner emitted: `[validator-parallelism] N targets, M cache hits, K misses parallelized (throttle=…)`

## T006 — Phase 4: Integration tests

**Files**: `tests/integration/validator-parallelization.tests.ps1` (new)
**Verifies**: FR-010
**Done when**:

- Test: `Invoke-WithFileLock` handles 8 concurrent writers without lost entries
- Test: `Set-ValidatorCacheEntry` with file lock preserves all entries under contention
- Test: `validate-governance.ps1` has `-NoParallel` switch parameter
- Test: `validate-governance.ps1` has `-ThrottleLimit` parameter (default 6)
- Test: Banner string present in validator code
- Test: Mirror parity for shared-governance.ps1 + validate-governance.ps1

## T007 — Phase 4: CHANGELOG entry

**Files**: `CHANGELOG.md`
**Verifies**: FR-011
**Done when**: Entry under `Changed` references Proposal 084, motivation, and serial-vs-parallel trade-off.

## T008 — Phase 4: PR open + Copilot review + merge

**Files**: PR description, review.md, retro.md, drift-log.md
**Done when**:

- PR opened against main
- Copilot review findings addressed (or accepted with justification)
- CI green (Lint + Ubuntu + macOS + Deterministic gate + Contract lane)
- Merged via merge commit (not squash)
