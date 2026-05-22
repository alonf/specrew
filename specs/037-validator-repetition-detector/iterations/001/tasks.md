# Tasks: Validator Repetition Detector (Proposal 086 Pillar 5)

**Feature**: 037-validator-repetition-detector
**Proposal**: 086 Pillar 5
**Version**: v0.24.3
**Spec**: [../../spec.md](../../spec.md)
**Plan**: [plan.md](plan.md)
**Branch**: `chore-086-p5-repetition-detector`
**Capacity**: 4 story_points

---

## T001: Add 4 Helpers to shared-governance.ps1 (1.5 SP)

**Acceptance Criteria**:

- [X] Get-SpecrewCommandLogPath: returns `.specrew/.cache/last-commands.log`
- [X] Add-SpecrewCommandInvocation: JSONL append; FIFO at 20; file-locked
- [X] Get-SpecrewRecentCommandInvocations: returns last N entries; empty on missing; leading-comma wrap to prevent unrolling
- [X] Test-SpecrewCommandRepetition: counts consecutive matching `(target_hash, code_hash)` from most-recent backwards

**Owner**: Implementer
**Trace**: FR-001, FR-002, FR-003

---

## T002: Validator Entry-Point Integration (1.0 SP)

**Acceptance Criteria**:

- [X] At start of validator main flow: compute target_hash + code_hash, test repetition, emit warning if count >= 2, then log invocation
- [X] target_hash = SHA256 of sorted iteration paths (or `<all>` if none specified)
- [X] code_hash via Get-ValidatorCodeHash (reuses Proposal 086 P1 helper)
- [X] Entire detector wrapped in try/catch — never propagate exceptions
- [X] Warning format: `[validator-repetition-warning] Detected N-consecutive invocation against unchanged code (target_hash=AAAAAAAA). Cache served prior runs; re-running is unlikely to surface new findings. To force fresh validation: -NoCacheRead.`

**Owner**: Implementer
**Trace**: FR-004, FR-005, FR-006

---

## T003: Integration Tests (1.0 SP)

**Acceptance Criteria**:

- [X] tests/integration/validator-repetition-detector.tests.ps1 with 8 assertions
- [X] Tests: helpers present + mirror parity + warning string + Add/Get round-trip + FIFO at 20 + consecutive count correctness + streak reset + corrupt log handled
- [X] All assertions pass

**Owner**: Test Owner
**Trace**: FR-008

---

## T004: CHANGELOG + INDEX + Closeout Artifacts (0.25 SP)

**Acceptance Criteria**:

- [X] CHANGELOG.md entry under `### Changed` referencing Proposal 086 Pillar 5
- [X] proposals/INDEX.md: 086 stays in Shipped (was P1; now P1 + P5 noted)
- [X] proposals/086 frontmatter: add `pillar-5-shipped-as: feature-037`
- [X] iteration artifacts: plan + tasks + review + retro + drift-log + state + dashboard + quality/hardening-gate
- [X] closeout-dashboard.md

**Owner**: Spec Steward + Retro Facilitator
**Trace**: FR-009

---

## T005: Branch Push + PR + Copilot Review + Merge (0.25 SP)

**Acceptance Criteria**:

- [X] Branch pushed to origin
- [X] PR opened
- [X] Wait for GitHub Copilot review
- [X] Address every finding
- [X] CI passes
- [X] PR merged via merge commit

**Owner**: Spec Steward
**Trace**: closeout

---

**Maintained by**: Alon Fliess | **Last Updated**: 2026-05-22
