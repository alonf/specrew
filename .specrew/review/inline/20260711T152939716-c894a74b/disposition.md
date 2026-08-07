# Disposition: run 20260711T152939716-c894a74b

**Dispositioned**: 2026-07-11 (maintainer-instructed at the iteration-003
before-implement verdict: "disposition the untracked review directory; do not
begin implementation with unexplained review output in the worktree")
**Finding**: f1 (blocking, escalated_to_human) — five unannotated DEC-198-*
self-leak hits in the deployed governance scripts (shared-governance.ps1
lines 1791/1836/1925/1962; validate-governance.ps1 line 1567).

## Determination: RESOLVED-AGAINST-DISK (stale escalation of an already-fixed finding)

This run is a later escalation round of the SAME finding first raised by run
`20260711T151958279-1a7a611f`. It reviewed a tree that PREDATES the fix and
escalated to human when the autonomous loop reached its ceiling. The finding
does not reproduce on the current tree:

- **Fix commit**: `c96b9bcd` (reworded all five DEC-198-* internal decision
  IDs to project-relative FR references; dropped the internal run IDs;
  born-clean, not annotated). Verified `git merge-base --is-ancestor
  c96b9bcd HEAD` → true (the fix is in HEAD).
- **Re-verified against current disk**: `scripts/internal/lint-self-leak.ps1`
  exits 0 (198 files scanned, 25 legitimate annotations, zero unannotated
  hits); `tests/unit/self-leak-lint.tests.ps1` passes; the mirror is
  byte-identical. The blocking CI lane the finding cited is now green.

## Field evidence for T019 (recorded, not silently discarded)

This run's record carries NO `reviewed_tree_id`, so nothing bound its
finding to the tree it actually reviewed — the exact staleness gap
FR-016/FR-017 (T019) closes: stamp the reviewed tree id into every run
surface and digest-match before surfacing, so an escalation on a superseded
tree is labelled stale-vs-current instead of blocking already-fixed work.
Consistent with the Devin-crew field reports already banked in the spec
Clarifications. No further action on this finding; carried as a T019 fixture
shape.
