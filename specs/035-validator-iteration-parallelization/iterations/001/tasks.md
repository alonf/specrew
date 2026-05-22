# Tasks: Validator Iteration Parallelization (Proposal 084)

**Feature**: 035-validator-iteration-parallelization
**Proposal**: 084
**Version**: v0.24.3
**Spec**: [spec.md](../../spec.md)
**Plan**: [plan.md](plan.md)
**Branch**: `chore-084-validator-iteration-parallelization`
**Capacity**: 7 story_points

---

## Phase 1: Setup & Context

### T001: Verify Implementation Context (0.25 SP)

**Acceptance Criteria**:

- [X] On branch `chore-084-validator-iteration-parallelization` off main (with F-034 merged at 9f2bd44)
- [X] Validator iteration loop located in `extensions/specrew-speckit/scripts/validate-governance.ps1` (lines 3940-4024)
- [X] Cache helpers from F-034 confirmed available (`Set-ValidatorCacheEntry` is the function that needs file-lock protection)

**Owner**: Spec Steward
**Trace**: All FRs (orientation)

---

## Phase 2: File Lock Helper + Cache Concurrency Safety

### T002: Add Invoke-WithFileLock helper (1.0 SP)

**Acceptance Criteria**:

- [ ] Add `Invoke-WithFileLock` function to `shared-governance.ps1` (+ mirror)
- [ ] Parameters: `-FilePath <string>` (lock file path), `-ScriptBlock <scriptblock>` (work to do inside lock)
- [ ] Acquires exclusive lock via `[System.IO.FileStream]::new($lockPath, 'OpenOrCreate', 'ReadWrite', 'None')`
- [ ] Retries up to 10 times with 100ms backoff if `IOException` (lock contended)
- [ ] Releases lock in `finally` block
- [ ] Lock file path is `<FilePath>.lock` (in same directory)
- [ ] Throws if all retries exhausted

**Owner**: Implementer
**Trace**: FR-001

---

### T003: Wrap Set-ValidatorCacheEntry in file lock (0.5 SP)

**Acceptance Criteria**:

- [ ] `Set-ValidatorCacheEntry` body wrapped in `Invoke-WithFileLock` block
- [ ] Lock file at `<cachePath>.lock`
- [ ] Read → mutate → write happens atomically inside the lock
- [ ] Existing behavior preserved (LRU eviction, code-hash wipe, etc.)

**Owner**: Implementer
**Trace**: FR-002, AC6, AC7

---

## Phase 3: Parallel Validator Path

### T004: Add -NoParallel + -ThrottleLimit parameters (0.5 SP)

**Acceptance Criteria**:

- [ ] `[switch]$NoParallel` parameter added to `validate-governance.ps1` (+ mirror)
- [ ] `[int]$ThrottleLimit = 6` parameter added (+ mirror)
- [ ] Parameter help text describes purpose
- [ ] Backwards compatibility: existing invocations work without specifying these

**Owner**: Implementer
**Trace**: FR-003, AC5, AC8

---

### T005: Pre-pass + parallel-misses subprocess invocation (2.5 SP)

**Acceptance Criteria**:

- [ ] PowerShell version gate: if `$PSVersionTable.PSVersion.Major -lt 7` OR `$NoParallel` OR `$targets.Count -le 1`, run original serial path
- [ ] Otherwise pre-pass: walk all targets serially, compute cache keys, partition into `$cacheHits` (with cached errors) + `$missTargets`
- [ ] Parallel pass: `$missTargets | ForEach-Object -Parallel { ... } -ThrottleLimit $using:throttleLimit`
- [ ] Each parallel branch invokes `pwsh -NoProfile -File $using:validatorScript -ProjectPath $using:resolvedProjectPath -IterationPath $_ -NoParallel`
- [ ] Subprocess captures stdout + exit code → result object `{ Path, ExitCode, Output }`
- [ ] Banner emitted: `[validator-parallelism] N targets, M cache hits served from pre-pass, K misses validated in parallel (throttle=…)`
- [ ] Failed-to-launch subprocess generates synthetic error entry rather than silently dropping
- [ ] Results merged + sorted by path
- [ ] Error count aggregated from cache hits + parallel results for final exit code
- [ ] Existing diagnostic output rendered in path-sorted order

**Owner**: Implementer
**Trace**: FR-004..FR-008, AC1, AC2, AC3, AC4

---

## Phase 4: Testing

### T006: Integration Tests (1.5 SP)

**Acceptance Criteria**:

- [ ] Create `tests/integration/validator-parallelization.tests.ps1`
- [ ] Test: `Invoke-WithFileLock` helper exists in shared-governance.ps1
- [ ] Test: mirror parity for shared-governance.ps1
- [ ] Test: mirror parity for validate-governance.ps1
- [ ] Test: `Invoke-WithFileLock` handles 8 concurrent writers without lost entries (spawn subprocesses, each writes to shared file inside lock, verify all 8 writes preserved)
- [ ] Test: `Set-ValidatorCacheEntry` under 8 concurrent writes preserves all entries
- [ ] Test: validate-governance.ps1 has `-NoParallel` switch
- [ ] Test: validate-governance.ps1 has `-ThrottleLimit` parameter (default 6)
- [ ] Test: validate-governance.ps1 has parallelism banner string

**Owner**: Test Owner
**Trace**: FR-010

---

## Phase 5: Closeout

### T007: Mirror Parity + CHANGELOG (0.5 SP)

**Acceptance Criteria**:

- [ ] `shared-governance.ps1` SHA256-matches primary and mirror
- [ ] `validate-governance.ps1` SHA256-matches primary and mirror
- [ ] CHANGELOG entry under `### Changed` referencing Proposal 084 + motivation

**Owner**: Spec Steward
**Trace**: FR-009, FR-011

---

### T008: INDEX + Closeout Artifacts (0.25 SP)

**Acceptance Criteria**:

- [ ] proposals/INDEX.md: note 084 shipped → Shipped section
- [ ] iterations/001/review.md
- [ ] iterations/001/retro.md
- [ ] iterations/001/drift-log.md
- [ ] iterations/001/state.md (final)
- [ ] iterations/001/dashboard.md
- [ ] iterations/001/quality/hardening-gate.md
- [ ] closeout-dashboard.md (feature-level)

**Owner**: Spec Steward + Retro Facilitator
**Trace**: closeout

---

### T009: Branch Push + PR + Copilot Review + Merge (0.25 SP)

**Acceptance Criteria**:

- [ ] Branch pushed to origin
- [ ] PR opened with full description
- [ ] Wait for GitHub Copilot PR review
- [ ] Address every finding
- [ ] CI passes
- [ ] PR merged with `--merge`

**Owner**: Spec Steward
**Trace**: closeout

---

**Maintained by**: Alon Fliess | **Last Updated**: 2026-05-22
