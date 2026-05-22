# Tasks: Closed-Iteration Index

**Spec**: [spec.md](spec.md)
**Plan**: [plan.md](plan.md)
**Proposal**: [Proposal 085](../../proposals/085-skip-closed-iterations-in-validator.md)

## T001 — Add helpers to shared-governance.ps1

**Files**: `extensions/specrew-speckit/scripts/shared-governance.ps1` (+ mirror)
**Verifies**: FR-001, FR-002, FR-003
**Done when**: `Get-SpecrewClosedIterationIndex`, `Add-SpecrewClosedIterationEntry`, `Test-SpecrewIterationClosed` present; Add idempotent + file-locked; Get returns empty hashtable on missing file.

## T002 — Add validator parameters + index integration

**Files**: `extensions/specrew-speckit/scripts/validate-governance.ps1` (+ mirror)
**Verifies**: FR-004, FR-005, FR-007, FR-008
**Done when**: `-IncludeClosed` + `-RebuildClosedIndex` switches added; target enumeration filters closed iterations unless override; banner extended.

## T003 — Boundary sync integration

**Files**: `scripts/internal/sync-boundary-state.ps1`
**Verifies**: FR-006
**Done when**: At `iteration-closeout` boundary, `Add-SpecrewClosedIterationEntry` invoked with feature + iteration + UTC timestamp.

## T004 — Initial backfill

**Files**: `.specrew/closed-iterations.yml` (new committed file)
**Verifies**: FR-009
**Done when**: `validate-governance.ps1 -RebuildClosedIndex` populates the file with all currently-closed iterations; file committed.

## T005 — Integration tests

**Files**: `tests/integration/closed-iteration-index.tests.ps1` (new)
**Verifies**: FR-011
**Done when**: Helpers present, mirror parity, idempotent append, `-IncludeClosed` overrides, `-RebuildClosedIndex` regenerates, banner extension present.

## T006 — CHANGELOG + INDEX update

**Files**: `CHANGELOG.md`, `proposals/INDEX.md`, `proposals/085-...md`
**Verifies**: FR-012
**Done when**: CHANGELOG entry under `Changed` references Proposal 085. INDEX moves 085 → Shipped. Proposal 085 frontmatter status → shipped.

## T007 — PR open + Copilot review + merge

**Done when**: PR opened, Copilot findings addressed, CI green, merged via merge commit.
