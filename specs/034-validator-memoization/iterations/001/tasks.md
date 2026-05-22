# Tasks: Validator Result Memoization (Proposal 086 Pillar 1)

**Feature**: 034-validator-memoization
**Proposal**: 086 (Pillar 1)
**Version**: v0.24.3
**Spec**: [spec.md](../../spec.md)
**Plan**: [plan.md](plan.md)
**Branch**: `chore-086-p1-memoization`
**Capacity**: 7 story_points

---

## Phase 1: Setup & Context

### T001: Verify Implementation Context (0.25 SP)

**Acceptance Criteria**:

- [X] On branch `chore-086-p1-memoization` off main (with F-032 merged)
- [X] Validator main entry flow + iteration loop located in `extensions/specrew-speckit/scripts/validate-governance.ps1`
- [X] Proposal 083's `Get-SpecrewLocalScopeBaseRef` confirmed available (composes with cache)

**Owner**: Spec Steward
**Trace**: All FRs (orientation)

---

## Phase 2: Cache Helpers

### T002: Add 4 Cache Helpers (2.0 SP)

**Acceptance Criteria**:

- [X] Add `Get-ValidatorCacheKey` to `shared-governance.ps1` (+ mirror): composes SHA256 from `(iteration content, validator code hash, rules config hash)`
- [X] Add `Get-ValidatorCacheEntry` to `shared-governance.ps1` (+ mirror): reads cache JSON file; returns entry or `$null`
- [X] Add `Set-ValidatorCacheEntry` to `shared-governance.ps1` (+ mirror): writes entry; LRU eviction at 500 entries
- [X] Add `Get-ValidatorCodeHash` to `shared-governance.ps1` (+ mirror): SHA256 of validator + shared-governance scripts; the cache-wide invalidation key

**Owner**: Implementer
**Trace**: FR-001, FR-002, FR-003, FR-004

---

### T003: Cache Path Resolution (0.25 SP)

**Acceptance Criteria**:

- [X] Add helper to resolve `.specrew/.cache/validator-cache.json` path under project root
- [X] Create `.specrew/.cache/` directory if missing on first write

**Owner**: Implementer
**Trace**: FR-002, FR-003

---

## Phase 3: Validator Integration

### T004: Validator Cache Integration (1.5 SP)

**Acceptance Criteria**:

- [X] At start of validator's per-iteration loop, compute cache key for the iteration
- [X] Check cache: if hit AND `validator_code_hash` matches current, skip `Test-IterationGovernance` and reuse cached error list
- [X] If miss or stale: run full validation, then write result to cache
- [X] Behavior preserved: validation outcomes identical to pre-cache behavior

**Owner**: Implementer
**Trace**: FR-005

---

### T005: -NoCacheRead Flag + .gitignore (0.5 SP)

**Acceptance Criteria**:

- [X] Add `-NoCacheRead` switch to `validate-governance.ps1`
- [X] When `-NoCacheRead` is set: skip cache read; still write results to cache
- [X] Add `.specrew/.cache/` to `.gitignore`

**Owner**: Implementer
**Trace**: FR-006, FR-007

---

## Phase 4: Testing

### T006: Integration Tests (1.5 SP)

**Acceptance Criteria**:

- [X] Create `tests/integration/validator-memoization.tests.ps1`
- [X] Test: helpers present in shared-governance.ps1 + mirror parity
- [X] Test: Get-ValidatorCacheKey returns deterministic SHA256 for same inputs
- [X] Test: Set-ValidatorCacheEntry creates `.specrew/.cache/validator-cache.json`
- [X] Test: Get-ValidatorCacheEntry retrieves stored entry
- [X] Test: LRU eviction at 500 entries
- [X] Test: Get-ValidatorCodeHash changes when validator script content changes
- [X] Test: `.gitignore` contains `.specrew/.cache/`

**Owner**: Test Owner
**Trace**: FR-009

---

## Phase 5: Closeout

### T007: Mirror Parity Sweep (0.25 SP)

- [X] `shared-governance.ps1` SHA256-matches primary and mirror
- [X] `validate-governance.ps1` SHA256-matches primary and mirror

**Owner**: Implementer
**Trace**: FR-008

---

### T008: CHANGELOG + INDEX + Closeout Artifacts (0.5 SP)

**Acceptance Criteria**:

- [X] CHANGELOG.md entry under `### Changed` referencing Proposal 086 Pillar 1
- [X] proposals/INDEX.md: note 086 (Pillar 1 only) shipped — full proposal stays in Candidate
- [X] iterations/001/review.md
- [X] iterations/001/retro.md
- [X] iterations/001/drift-log.md
- [X] iterations/001/state.md (final state)
- [X] iterations/001/dashboard.md
- [X] iterations/001/quality/hardening-gate.md
- [X] closeout-dashboard.md (feature-level)

**Owner**: Spec Steward + Retro Facilitator
**Trace**: FR-010

---

### T009: Branch Push + PR + Copilot Review + Merge (0.25 SP)

**Acceptance Criteria**:

- [X] Branch pushed to origin
- [X] PR opened with full description
- [X] Wait for GitHub Copilot PR review
- [X] Address every finding
- [X] CI passes
- [X] PR merged with `--merge`

**Owner**: Spec Steward
**Trace**: closeout

---

**Maintained by**: Alon Fliess | **Last Updated**: 2026-05-22
