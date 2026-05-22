# Feature Specification: Validator Repetition Detector (Proposal 086 Pillar 5)

**Feature Branch**: `chore-086-p5-repetition-detector`
**Proposal**: [Proposal 086 Pillar 5](../../proposals/086-validation-pipeline-performance-bundle.md)
**Created**: 2026-05-22
**Status**: Draft
**Version**: v0.24.3 slice (process-optimization bundle, slot 6)

## Clarifications

### Session 2026-05-22

- **Q: Which pillars of Proposal 086 ship here?** → **A: Pillar 5 only (Repetition Detector). Pillars 2 (Rule applicability), 3 (Metadata cache), and 4 (Batched state writes) require larger refactors and are deferred to follow-up features. F-037 ships the most user-visible methodology win standalone.**

- **Q: How is "repetition" detected?** → **A: Validator entry logs each invocation to `.specrew/.cache/last-commands.log` with `(target_hash, code_hash, invoked_at)`. On invocation, look back at last 5 entries; if 3+ consecutive entries have same `(target_hash, code_hash)` (meaning code AND content unchanged), emit a warning.**

- **Q: How does this compose with Proposal 086 P1 (memoization)?** → **A: Composes additively. Cache + repetition detector are orthogonal. Cache makes the repetition cheap; detector flags the repetition. The combination tells the developer "you ran validator 3x with no change — cache served all 3 in <1s each; consider what you're trying to verify."**

## User Scenarios & Testing

### User Story 1 — 3rd consecutive identical validator invocation emits a warning (Priority: P1)

A developer runs `validate-governance.ps1` 3 times against the same target with no code or content changes. On the 3rd invocation, the validator emits `[validator-repetition-warning] Detected 3rd consecutive invocation against unchanged code. Cache served all 3.`

**Acceptance Scenarios**:

1. **Given** 2 prior invocations with same target+code hashes, **When** validator runs a 3rd time with same hashes, **Then** warning emitted (AC1).
2. **Given** the target or code changed between invocations, **When** validator runs, **Then** NO warning (the streak is broken) (AC2).

---

### User Story 2 — Log is bounded and gitignored (Priority: P2)

The log file `.specrew/.cache/last-commands.log` lives under the existing `.specrew/.cache/` (gitignored, per-developer). Capped at 20 entries with FIFO eviction.

**Acceptance Scenarios**:

1. **Given** 25 invocations, **When** log inspected, **Then** only the most recent 20 entries are present (AC3).
2. **Given** the log file, **When** gitignore inspected, **Then** `.specrew/.cache/` is gitignored (AC4 — already covered by Proposal 086 P1).

---

### User Story 3 — Detector failure is non-fatal (Priority: P2)

If the log file is corrupt or unreadable, the validator must still run and complete normally — the detector is diagnostic, not blocking.

**Acceptance Scenarios**:

1. **Given** a corrupt log file, **When** validator runs, **Then** validation completes; no exception propagates (AC5).

---

## Functional Requirements

- **FR-001**: System MUST add `Add-SpecrewCommandInvocation` helper to `shared-governance.ps1` (+ mirror) that appends `{target_hash, code_hash, invoked_at, command}` to `.specrew/.cache/last-commands.log` (JSON Lines format). Uses `Invoke-WithFileLock` for concurrent-safe append. FIFO eviction at 20 entries.

- **FR-002**: System MUST add `Get-SpecrewRecentCommandInvocations` helper to `shared-governance.ps1` (+ mirror) that reads the log and returns the most-recent N entries (default 5).

- **FR-003**: System MUST add `Test-SpecrewCommandRepetition` helper to `shared-governance.ps1` (+ mirror) that takes a target hash + code hash and returns the count of recent CONSECUTIVE invocations with the same hashes. Returns 0 if streak broken (different hashes appeared).

- **FR-004**: `validate-governance.ps1` (+ mirror) MUST log every invocation via `Add-SpecrewCommandInvocation` AND check repetition via `Test-SpecrewCommandRepetition` AT THE START of the main flow. If repetition count >= 2 (this would be the 3rd consecutive), emit `[validator-repetition-warning] ...` to stdout. Continue execution normally regardless.

- **FR-005**: Repetition detector failure (e.g., corrupt log, file permission error) MUST NOT propagate exceptions. Validator completes normally.

- **FR-006**: target_hash is computed as SHA256 of the canonical iteration paths (sorted) being validated. code_hash reuses `Get-ValidatorCodeHash` from Proposal 086 Pillar 1.

- **FR-007**: Mirror parity MUST be preserved across `extensions/specrew-speckit/` and `.specify/extensions/specrew-speckit/` for `shared-governance.ps1` and `validate-governance.ps1`.

- **FR-008**: Integration tests at `tests/integration/validator-repetition-detector.tests.ps1` MUST cover: helpers present + mirror parity; Add appends new entry; FIFO eviction at 20; Test returns correct consecutive count; corrupt log handled gracefully.

- **FR-009**: CHANGELOG.md MUST contain an entry under `Changed` referencing Proposal 086 Pillar 5, motivation, and composition with Pillar 1.

## Out of Scope

- **Pillar 2 (Rule applicability filter)**: deferred to future feature; requires touching every rule definition. Larger refactor.
- **Pillar 3 (Metadata cache)**: deferred to future feature; requires touching every rule that reads artifacts.
- **Pillar 4 (Batched state writes)**: deferred to future feature; requires multi-file transactional write primitive.
- **Auto-suggesting `-NoCacheRead`**: warning text just notes that re-running may not surface new findings; doesn't auto-add flags.
- **Cross-CI repetition detection**: log is per-developer; CI doesn't track its own repetitions (CI is typically push-triggered, not interactive).

## Acceptance Criteria Summary

| AC | Verifies | Trace |
|---|---|---|
| AC1 | 3rd consecutive identical invocation emits warning | FR-004 |
| AC2 | Different hashes break the streak | FR-003 |
| AC3 | FIFO eviction at 20 entries | FR-001 |
| AC4 | Log is gitignored (via existing `.specrew/.cache/` rule) | (covered by P1) |
| AC5 | Corrupt log doesn't crash validator | FR-005 |

---

**Maintained by**: Alon Fliess | **Last Updated**: 2026-05-22
