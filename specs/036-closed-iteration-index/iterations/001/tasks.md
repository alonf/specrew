# Tasks: Closed-Iteration Index (Proposal 085)

**Feature**: 036-closed-iteration-index
**Proposal**: 085
**Version**: v0.24.3
**Spec**: [../../spec.md](../../spec.md)
**Plan**: [plan.md](plan.md)
**Branch**: `chore-085-closed-iteration-index`
**Capacity**: 5 story_points

---

## T001: Add 4 Closed-Iteration-Index Helpers (1.5 SP)

**Acceptance Criteria**:

- [X] Get-SpecrewClosedIterationIndexPath: returns `.specrew/closed-iterations.yml`
- [X] Get-SpecrewClosedIterationIndex: reads YAML; returns hashtable keyed by `<feature>/<iteration>`
- [X] Add-SpecrewClosedIterationEntry: appends entry; idempotent; uses Invoke-WithFileLock
- [X] Test-SpecrewIterationClosed: returns $true if (feature, iteration) is indexed
- [X] Get-SpecrewClosedIterationFromStateFile: heuristic detector for closed iterations

**Owner**: Implementer
**Trace**: FR-001, FR-002, FR-003

---

## T002: Validator Parameters + Filter + Banner (1.5 SP)

**Acceptance Criteria**:

- [X] -IncludeClosed switch parameter added
- [X] -RebuildClosedIndex switch parameter added
- [X] -RebuildClosedIndex early-exit walks state.md files + regenerates index
- [X] Full-repo target enumeration filters closed iterations unless -IncludeClosed
- [X] Banner extension: `[validator-scope] closed-iteration filter: N closed iterations skipped`

**Owner**: Implementer
**Trace**: FR-004, FR-005, FR-007, FR-008

---

## T003: Boundary Sync at Iteration-Closeout (0.5 SP)

**Acceptance Criteria**:

- [X] At iteration-closeout boundary, Invoke-SpecrewBoundaryStateSync calls Add-SpecrewClosedIterationEntry
- [X] Wrapped in try/catch with Write-Warning fallback (non-fatal if write fails)
- [X] Idempotent on re-sync (handled at helper layer)

**Owner**: Implementer
**Trace**: FR-006

---

## T004: Initial Backfill (0.25 SP)

**Acceptance Criteria**:

- [X] `.specrew/closed-iterations.yml` populated with 41 currently-closed iterations
- [X] File committed to repo (NOT gitignored)
- [X] Detector heuristic catches: `Current Phase: complete/closed/feature-closeout/iteration-closeout`, `RETRO COMPLETE`, `Status: complete`, `iteration closed`, `Retrospective complete`

**Owner**: Implementer
**Trace**: FR-009

---

## T005: Integration Tests + Mirror Parity (1.0 SP)

**Acceptance Criteria**:

- [X] tests/integration/closed-iteration-index.tests.ps1 created with 10 assertions
- [X] Tests verify: helpers present + mirror parity + params present + filter banner + initial backfill + idempotency + Test-Closed correctness + boundary-sync integration
- [X] All assertions pass

**Owner**: Test Owner
**Trace**: FR-010, FR-011

---

## T006: CHANGELOG + INDEX + Closeout Artifacts (0.25 SP)

**Acceptance Criteria**:

- [X] CHANGELOG.md entry under `### Changed` referencing Proposal 085
- [X] proposals/INDEX.md: move 085 to Shipped
- [X] proposals/085 frontmatter status → shipped
- [X] iteration artifacts: plan + tasks + review + retro + drift-log + state + dashboard + quality/hardening-gate
- [X] feature-level closeout-dashboard.md

**Owner**: Spec Steward + Retro Facilitator
**Trace**: FR-012

---

## T007: Branch Push + PR + Copilot Review + Merge (0.25 SP)

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
