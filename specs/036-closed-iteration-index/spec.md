# Feature Specification: Closed-Iteration Index

**Feature Branch**: `chore-085-closed-iteration-index`
**Proposal**: [Proposal 085](../../proposals/085-skip-closed-iterations-in-validator.md)
**Created**: 2026-05-22
**Status**: Draft
**Version**: v0.24.3 slice (process-optimization bundle, slot 5)

## Clarifications

### Session 2026-05-22

- **Q: Where does the index live and what's its format?** → **A: `.specrew/closed-iterations.yml`, committed to repo. Append-only list of `{feature, iteration, closed_at}` entries.**

- **Q: How is the index populated?** → **A: Boundary sync at iteration-closeout AND feature-closeout boundary appends one entry. `validate-governance.ps1 -RebuildClosedIndex` walks state.md files to regenerate from scratch.**

- **Q: How does the validator use it?** → **A: Full-repo fallback path skips iterations whose `(feature, iteration)` appears in the index UNLESS `-IncludeClosed` is set. Common path (changed-only, via Proposal 083) is unaffected — closed iterations naturally aren't in the diff.**

- **Q: How does this compose with Proposal 084 (parallelization)?** → **A: Composes additively. With the index, the parallel loop's `$targets` is smaller (closed iterations filtered out). Same throttle, fewer items.**

## User Scenarios & Testing

### User Story 1 — Full-repo validator on a 44-iter corpus skips 36 closed iterations (Priority: P1)

A developer or CI runs full-repo validator. Currently: validates all 44 iterations. With the index: 36 are closed and skipped; only 8 active validated. Runtime drops by ~80%.

**Acceptance Scenarios**:

1. **Given** a populated `closed-iterations.yml`, **When** validator runs full-repo without `-IncludeClosed`, **Then** closed iterations are skipped (`[validator-scope]` banner shows N active validated, M closed skipped) (AC1).
2. **Given** `-IncludeClosed` is passed, **When** validator runs, **Then** all iterations validated including closed (AC2).

---

### User Story 2 — Iteration-closeout boundary appends to the index (Priority: P1)

When the Crew runs the iteration-closeout sync command, the index gains a new entry for that iteration.

**Acceptance Scenarios**:

1. **Given** an iteration without an entry in the index, **When** boundary sync fires at iteration-closeout, **Then** `.specrew/closed-iterations.yml` gains `{feature, iteration, closed_at}` (AC3).
2. **Given** an entry already exists for that iteration, **When** boundary sync fires again, **Then** the entry is NOT duplicated (append-only with dedup) (AC4).

---

### User Story 3 — `-RebuildClosedIndex` regenerates the index from state.md walk (Priority: P2)

A developer deletes the index or wants to recover from a stale state. `-RebuildClosedIndex` walks all state.md files in the corpus and reconstructs the index.

**Acceptance Scenarios**:

1. **Given** missing or corrupt index, **When** `validate-governance.ps1 -RebuildClosedIndex` runs, **Then** index regenerated from state.md walk (AC5).

---

### User Story 4 — Banner shows the index breakdown (Priority: P3)

`[validator-scope]` banner is extended to include closed-skipped count when in full-repo mode.

**Acceptance Scenarios**:

1. **Given** full-repo validation runs, **When** index has entries, **Then** banner shows `N iterations (M closed-skipped)` (AC6).

---

## Functional Requirements

- **FR-001**: System MUST add `Get-SpecrewClosedIterationIndex` helper to `shared-governance.ps1` (+ mirror). Returns a hashtable keyed by `"<feature>/<iteration>"` → `@{closed_at}`. Reads `.specrew/closed-iterations.yml`. Returns empty hashtable if file missing.

- **FR-002**: System MUST add `Add-SpecrewClosedIterationEntry` helper to `shared-governance.ps1` (+ mirror). Appends a new `{feature, iteration, closed_at}` to the index file. Skips if entry already exists (idempotent / dedupe). Uses `Invoke-WithFileLock` to serialize concurrent appends across developers/processes.

- **FR-003**: System MUST add `Test-SpecrewIterationClosed` helper to `shared-governance.ps1` (+ mirror). Returns `$true` if `(feature, iteration)` is in the index.

- **FR-004**: `validate-governance.ps1` MUST add `[switch]$IncludeClosed` parameter. When NOT set: skip closed iterations on full-repo path. When set: validate all iterations including closed.

- **FR-005**: `validate-governance.ps1` MUST add `[switch]$RebuildClosedIndex` parameter. When set: walk `specs/*/iterations/*/state.md`, detect closed iterations (state.md status contains "complete" OR phase contains "feature-closeout" OR "iteration-closeout"), regenerate `.specrew/closed-iterations.yml` from scratch.

- **FR-006**: `Invoke-SpecrewBoundaryStateSync` MUST append the iteration's entry to the index at `iteration-closeout` boundary (after state files are written, before script exits). Idempotent on re-sync.

- **FR-007**: Validator's full-repo target enumeration MUST filter out closed iterations unless `-IncludeClosed` is set. Composes with `-ChangedOnly` (Proposal 083): -ChangedOnly path is unaffected because closed iterations naturally aren't in the diff.

- **FR-008**: `[validator-scope]` banner MUST be extended to show `(M closed-skipped)` when applicable. Format: `[validator-scope] full-repo (N iterations, M closed-skipped)`.

- **FR-009**: Initial backfill: `.specrew/closed-iterations.yml` MUST be populated with all currently-closed iterations (one-time data migration via `-RebuildClosedIndex` run during F-036 implementation).

- **FR-010**: Mirror parity MUST be preserved across `extensions/specrew-speckit/` and `.specify/extensions/specrew-speckit/` for `shared-governance.ps1` (and any other touched mirror files).

- **FR-011**: Integration tests at `tests/integration/closed-iteration-index.tests.ps1` MUST cover: helpers present + mirror parity; index read returns hashtable; Add is idempotent; Test-IterationClosed returns correct value; `-IncludeClosed` overrides skip; `-RebuildClosedIndex` regenerates; banner extension.

- **FR-012**: CHANGELOG.md MUST contain an entry under `Changed` referencing Proposal 085, empirical motivation, and composition with Proposals 083 + 084.

## Out of Scope

- **Cross-iteration validation rules**: rules that compare across iterations (e.g., proposal-to-feature mapping) need ALL iterations — those rules opt out of the closed-skip path. Marked as future enhancement.
- **CI workflow `-IncludeClosed` flag**: separate small-fix slice. F-036 ships the validator surface only; CI workflow yaml edit can follow.
- **Custom git merge driver for concurrent appends**: default conflict-marker resolution is trivial for append-only lists. Custom driver deferred.
- **Time-based pruning**: rejected per Proposal 085. Status, not time, is the right discriminator.

## Acceptance Criteria Summary

| AC | Verifies | Trace |
|---|---|---|
| AC1 | Full-repo skips closed iterations | FR-004, FR-007 |
| AC2 | `-IncludeClosed` validates all | FR-004 |
| AC3 | iteration-closeout boundary appends | FR-006 |
| AC4 | Append is idempotent | FR-002 |
| AC5 | `-RebuildClosedIndex` regenerates | FR-005 |
| AC6 | Banner shows closed-skipped | FR-008 |

---

**Maintained by**: Alon Fliess | **Last Updated**: 2026-05-22
