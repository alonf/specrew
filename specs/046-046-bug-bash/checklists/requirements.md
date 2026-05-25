# Requirements Checklist: F-046 Specrew Bug-Bash Bundle

**Feature**: `046-046-bug-bash`  

## Functional Requirements Checks

- [ ] **FR-001**: Stale-state detector allow-list includes `retro` boundary when `review.md` is accepted.
- [ ] **FR-002**: `sync-boundary-state.ps1` updates both `boundary_type` and `last_authorized_boundary` atomically and appends to `verdict_history`.
- [ ] **FR-003**: Idempotency check avoids duplicate history appends or backward-move errors on re-sync.
- [ ] **FR-004**: Scaffolders (`scaffold-reviewer-artifacts.ps1`, `scaffold-review-artifact.ps1`, `scaffold-retro-artifact.ps1`) preserve accepted/populated artifacts and write to `.pending`.
- [ ] **FR-005**: Parameter validation `[ValidateSet]` is removed from `sync-boundary-state.ps1` wrappers and internal handlers, and common prose aliases are mapped.
- [ ] **FR-006**: Ledger `findings.md` is fully created and checked.
- [ ] **FR-007**: Counterparts in `.specify/extensions/` mirror all `extensions/` script changes.

## Success Criteria Checks

- [ ] **SC-001**: 100% success on `specrew start` at `retro` boundary.
- [ ] **SC-002**: Atomic sync verified on mock state.
- [ ] **SC-003**: Scaffolders warn and output to `.pending` when run on accepted files.
- [ ] **SC-004**: Prose aliases successfully mapped.
- [ ] **SC-005**: All findings fully documented.
- [ ] **SC-006**: 0 failing integration tests.
