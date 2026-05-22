# Plan: Closed-Iteration Index

**Spec**: [spec.md](spec.md)
**Proposal**: [Proposal 085](../../proposals/085-skip-closed-iterations-in-validator.md)
**Created**: 2026-05-22
**Status**: Approved

## Approach

Add a per-repo `.specrew/closed-iterations.yml` (committed) that records `{feature, iteration, closed_at}` for every closed iteration. Validator's full-repo target enumeration filters out closed iterations unless `-IncludeClosed`. Boundary sync at iteration-closeout appends. `-RebuildClosedIndex` regenerates from state.md walk.

### Phase 1 — Helpers in shared-governance.ps1

1. `Get-SpecrewClosedIterationIndex` — reads `.specrew/closed-iterations.yml`, returns hashtable keyed by `"<feature>/<iteration>"`.
2. `Add-SpecrewClosedIterationEntry` — appends a new entry; idempotent if entry already exists; uses `Invoke-WithFileLock` for concurrent-safe append.
3. `Test-SpecrewIterationClosed` — quick lookup against the index.

### Phase 2 — Validator integration

1. Add `[switch]$IncludeClosed` + `[switch]$RebuildClosedIndex` parameters.
2. After target enumeration on the full-repo path, filter out closed iterations unless `-IncludeClosed`.
3. Extend `[validator-scope]` banner with `(M closed-skipped)` count.
4. `-RebuildClosedIndex` walks `specs/*/iterations/*/state.md`, detects closed, regenerates index.

### Phase 3 — Boundary sync integration

1. In `Invoke-SpecrewBoundaryStateSync`, at `iteration-closeout` boundary, call `Add-SpecrewClosedIterationEntry` for the current iteration.

### Phase 4 — Initial backfill

1. Run `-RebuildClosedIndex` once during F-036 implementation to seed `.specrew/closed-iterations.yml` with all currently-closed iterations.
2. Commit the seeded file as part of this PR.

### Phase 5 — Testing + sign-off

1. `tests/integration/closed-iteration-index.tests.ps1` covering helpers, idempotency, validator integration, rebuild.
2. CHANGELOG entry; INDEX update.

## Risk + Mitigation

| Risk | Mitigation |
|---|---|
| Concurrent appends from two developers | `Invoke-WithFileLock` serializes; append-only + dedup makes the merge trivial |
| State.md detection misses an iteration class | `-RebuildClosedIndex` walks `Current Phase:` + `RETRO COMPLETE` + `Status: complete` (3-way recognizer) |
| Closed-iteration validator skip masks a legitimate cross-iteration drift | `-IncludeClosed` opt-in (CI push-to-main runs full truth-check); nightly truth-check workflow optional |
| Existing closed iterations not in index | Initial backfill via `-RebuildClosedIndex` run during this PR |

## Composition with Other Proposals

- **Proposal 083 (changed-only)**: orthogonal. -ChangedOnly path is unaffected because closed iterations naturally aren't in the diff.
- **Proposal 084 (parallelization)**: composes additively. With the index, parallel loop's `$targets` is smaller (closed filtered); same throttle, fewer items.
- **Proposal 086 P1 (memoization)**: composes orthogonally. Cache reduces re-validation cost; index reduces enumeration set.

## Out of Scope (explicit deferral)

- Cross-iteration validation rules opt-out path
- CI workflow `-IncludeClosed` flag (separate small-fix slice)
- Custom git merge driver for concurrent appends
