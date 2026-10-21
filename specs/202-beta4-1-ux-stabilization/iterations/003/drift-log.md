# Drift Log: Iteration 003

**Schema**: v2

## Summary

**Total drift events**: 1 (DRIFT-001)

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
- **Class closure**: NONE in this iteration. Making the command name the active iteration is beta5 work (the review
  engine), as ruled at the fourth instance (iteration 002 DRIFT-002).
