# Tasks: Validator Repetition Detector

**Spec**: [spec.md](spec.md)
**Plan**: [plan.md](plan.md)
**Proposal**: [Proposal 086 Pillar 5](../../proposals/086-validation-pipeline-performance-bundle.md)

## T001 — Add helpers to shared-governance.ps1

**Files**: `extensions/specrew-speckit/scripts/shared-governance.ps1` (+ mirror)
**Verifies**: FR-001, FR-002, FR-003
**Done when**: 3 helpers present (Add, Get, Test); JSONL append; FIFO at 20; file-locked.

## T002 — Validator entry-point integration

**Files**: `extensions/specrew-speckit/scripts/validate-governance.ps1` (+ mirror)
**Verifies**: FR-004, FR-005, FR-006
**Done when**: validator logs invocation + tests repetition at start of main flow; emits `[validator-repetition-warning]` when count >= 2; wrapped in try/catch (non-blocking).

## T003 — Integration tests

**Files**: `tests/integration/validator-repetition-detector.tests.ps1` (new)
**Verifies**: FR-008
**Done when**: helpers present; mirror parity; FIFO at 20; Test-SpecrewCommandRepetition returns correct count; corrupt log handled gracefully.

## T004 — CHANGELOG + INDEX + proposal status

**Files**: `CHANGELOG.md`, `proposals/INDEX.md`, `proposals/086-...md`
**Verifies**: FR-009
**Done when**: CHANGELOG entry under `Changed` references Pillar 5. INDEX move 086 to Shipped (note: Pillars 1+5 only — 2/3/4 remain candidate). Proposal 086 frontmatter notes pillar-5-shipped-as: feature-037.

## T005 — PR open + Copilot review + merge

**Done when**: PR opened, Copilot findings addressed, CI green, merged via merge commit.
