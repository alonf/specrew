# Drift Log: Iteration 003

**Schema**: v2

## Summary

**Total drift events**: 2 (DRIFT-001, DRIFT-002)

## Events

### DRIFT-001 — the pre-review governance command still named iteration 002 (resolved)

- **Observed**: 2026-10-21, before iteration 003's review round. `.specrew/verification-plan.json` ran the governance
  validation against `iterations/002`, which closed and was sealed earlier the same day. The fifth instance of the
  recurrence (202 DRIFT-011 in iteration 001 was the third, iteration 002 DRIFT-002 the fourth): the command names an
  iteration number instead of the active iteration.
- **Requirement citation**: the review's verification plan must validate the active iteration (iteration 001
  DRIFT-011).
- **Resolution**: re-pointed to `iterations/003` (command `iteration-003-governance-202`), before the round, so the
  round's pre-review check reads this iteration.
- **Class closure**: NONE - making the command name the active iteration is beta5 work (the review engine), as ruled
  at the fourth instance (iteration 002 DRIFT-002).

### DRIFT-002 — the re-walk row was written into closed iteration 002 (resolved)

- **Observed**: 2026-10-24, T030. The crew wrote the second re-walk's Record row into
  `iterations/002/copilot-rewalk.md` (`4783a721`, pushed), as that file's Record section says. Iteration 002 was sealed
  at its closeout on 2026-10-21 (`45f0d01c`), and the validator failed `closed-iteration-edited` on the file.
- **Requirement citation**: a closed iteration's records are preserved history, the state the maintainer's verdict
  accepted.
- **Resolution**: reverted by a new commit (`995bf705`; history not rewritten), and the row moved to
  `iterations/003/acceptance-evidence.md`. Iteration 002's records are again as sealed.
- **Cause**: the walk script tells the reader to fill the row in iteration 002's files, and T030's plan entry lists
  that file as owned. Both were written before iteration 002 closed and were not updated when the walk moved here. The
  crew ran the validator only after committing.
- **Class closure**: NONE in code. The crew runs the validator before committing a record outside the active
  iteration.
