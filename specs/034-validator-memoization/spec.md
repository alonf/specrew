# Feature Specification: Validator Result Memoization

**Feature Branch**: `chore-086-p1-memoization`
**Proposal**: [Proposal 086 Pillar 1](../../proposals/086-validation-pipeline-performance-bundle.md)
**Created**: 2026-05-22
**Status**: Draft
**Version**: v0.24.3 slice (process-optimization bundle, slot 3)

## Clarifications

### Session 2026-05-22

- **Q: Where does the cache live?** → **A: `.specrew/.cache/validator-cache.json`, gitignored (per-developer cache). Cache is local to each clone; no cross-developer sharing in v1.**

- **Q: What invalidates the cache?** → **A: Three keys form the cache identity: iteration content hash (SHA256 of all files in iteration dir), validator code hash (SHA256 of `validate-governance.ps1` + `shared-governance.ps1`), and rules hash (governance rule config). Any change invalidates only that entry; a validator-code change invalidates the WHOLE cache.**

- **Q: What's the cache size policy?** → **A: Cap at 500 entries with LRU eviction. Cache lives in gitignored `.specrew/.cache/` so growth doesn't pollute git history.**

## User Scenarios & Testing

### User Story 1 — Edit-validate-edit loop drops to ~1ms on cache hit (Priority: P1)

The Crew (or developer) runs the validator on an iteration. First invocation populates the cache. Subsequent invocations with unchanged iteration content + unchanged validator code + unchanged rules return the cached PASS/FAIL result in milliseconds without re-running per-rule checks.

**Why this priority**: This is the primary performance win — the F-030/083 session burned ~80 of 113 minutes on 4× redundant validator integration test runs that would have been cache hits with this slice.

**Independent Test**: Run validator on a clean iteration twice in a row. Second invocation completes in <100ms for the cached iteration (vs ~30s without cache).

**Acceptance Scenarios**:

1. **Given** validator runs successfully on iteration N, **When** validator runs again with no changes to N's content, validator code, or rules, **Then** the cached result is returned in <100ms (AC1).
2. **Given** iteration N's `state.md` is edited, **When** validator runs, **Then** the cache entry for N is invalidated and full validation runs (AC2).

---

### User Story 2 — Validator code change wipes entire cache (Priority: P1)

A developer modifies `validate-governance.ps1` (adds a new rule, fixes a bug). The cache should not return stale results from before the code change.

**Why this priority**: Correctness. Stale cache results would produce wrong validation outcomes.

**Acceptance Scenarios**:

1. **Given** validator runs and populates cache, **When** `validate-governance.ps1` is edited, **Then** subsequent validator invocations re-validate ALL iterations (cache wiped) (AC3).
2. Same for `shared-governance.ps1`.

---

### User Story 3 — `-NoCacheRead` flag forces fresh validation (Priority: P2)

A developer wants to bypass the cache for debugging. They pass `-NoCacheRead`. The validator runs without consulting the cache; new results are still written to the cache.

**Why this priority**: Diagnostics. Developers need an escape hatch when investigating cache-related bugs.

**Acceptance Scenarios**:

1. **Given** cache contains a valid entry for iteration N, **When** validator runs with `-NoCacheRead`, **Then** full validation runs (cache read skipped) and result is written (AC4).

---

### User Story 4 — Cache file is gitignored (Priority: P1)

The cache file lives at `.specrew/.cache/validator-cache.json`. The `.gitignore` ensures it never gets committed.

**Acceptance Scenarios**:

1. **Given** a fresh clone with no cache, **When** validator runs and creates cache, **Then** `git status` does not show the cache file as tracked or stageable (AC5).

---

## Functional Requirements

- **FR-001**: System MUST add helper `Get-ValidatorCacheKey` to `shared-governance.ps1` (+ mirror) that computes a composite SHA256 hash from: iteration content (all files in iteration dir), validator code (`validate-governance.ps1` + `shared-governance.ps1`), and rules config. Returns a string key (AC1, AC2, AC3).

- **FR-002**: System MUST add helper `Get-ValidatorCacheEntry` to `shared-governance.ps1` (+ mirror) that reads `.specrew/.cache/validator-cache.json` and returns the cached entry for a given key, or `$null` if absent (AC1).

- **FR-003**: System MUST add helper `Set-ValidatorCacheEntry` to `shared-governance.ps1` (+ mirror) that writes an entry to the cache file with LRU eviction at 500 entries (AC1).

- **FR-004**: System MUST add helper `Get-ValidatorCodeHash` to `shared-governance.ps1` (+ mirror) that computes SHA256 of validator + shared-governance scripts. Cached result invalidates wholesale when this hash changes (AC3).

- **FR-005**: `validate-governance.ps1` MUST integrate cache lookup at the start of per-iteration validation: if cache hit AND validator code hash matches, skip `Test-IterationGovernance` and use the cached error list (AC1, AC2).

- **FR-006**: `validate-governance.ps1` MUST add `-NoCacheRead` switch parameter that forces fresh validation while still writing the result to the cache (AC4).

- **FR-007**: `.gitignore` MUST include `.specrew/.cache/` to prevent the cache from being committed (AC5).

- **FR-008**: Mirror parity MUST be preserved across `extensions/specrew-speckit/` and `.specify/extensions/specrew-speckit/` for `shared-governance.ps1` and `validate-governance.ps1`.

- **FR-009**: Integration tests at `tests/integration/validator-memoization.tests.ps1` MUST cover: cache hit returns fast; cache miss runs full validation; iteration content change invalidates that entry; validator code change wipes cache; `-NoCacheRead` flag skips read but still writes; cache file is created at `.specrew/.cache/`.

- **FR-010**: CHANGELOG.md MUST contain an entry under `Changed` referencing Proposal 086 Pillar 1, the empirical motivation (~80 min wasted on F-030/083 cache-missable runs), and the new cache behavior.

## Out of Scope

- Cross-developer / cross-machine cache sharing (per-developer cache only in v1)
- Cache persistence to git (gitignored)
- Cache prefetch on `specrew start` (lazy on first validator invocation)
- Per-rule memoization (whole-iteration only; per-rule is Pillar 2 territory)
- Compression of cache file (JSON is small enough at 500-entry cap)
- Cache eviction policies beyond LRU (no TTL, no manual purge UI)

## Acceptance Criteria Summary

| AC | Verifies | Trace |
|---|---|---|
| AC1 | Cache hit returns <100ms | FR-001, FR-002, FR-005 |
| AC2 | Iteration content change invalidates that entry | FR-001, FR-005 |
| AC3 | Validator code change wipes cache | FR-004, FR-005 |
| AC4 | `-NoCacheRead` forces fresh validation | FR-006 |
| AC5 | Cache is gitignored | FR-007 |

---

**Maintained by**: Alon Fliess | **Last Updated**: 2026-05-22
