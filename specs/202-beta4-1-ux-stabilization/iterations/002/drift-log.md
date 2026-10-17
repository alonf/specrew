# Drift Log: Iteration 002

**Schema**: v2

## Summary

**Total drift events**: 2 (DRIFT-001 to DRIFT-002)

## Events

### DRIFT-001 — the iteration-2 scope replaces Tier 2's review-ordering slice; spec amended at the plan (pending the plan stop)

- **Observed**: 2026-10-17, iteration-2 plan. The spec's Tier 2 held US7 (FR-022, the review-ordering slices of
  B4F-054/056/058/061, and FR-023, the B4F-103 package comparison). The maintainer's scope ruling ("scope as
  recommended") gave iteration 2 to "one human act, one record" instead: B4F-127 and B4F-129 (the release gate), B4F-125
  with B4F-128, B4F-130, B4F-131, and retro candidates 3 and 7.
- **Requirement citation**: spec.md Scope (Tier 2), US7, FR-022, FR-023; the out-of-scope line "any redesign of the hook
  dispatcher or stores".
- **Resolution**: spec-updated. The Scope line is amended, US7, FR-022 and FR-023 are marked as moved to beta5 and kept as
  the record, and US8 with FR-027 to FR-034, SC-010 and SC-011 is added. Iteration 2 touches the dispatcher and the stores
  only as far as FR-028 and FR-033 require, which the amended Scope line states. The amendment takes effect with the
  maintainer's plan approval. **Approved** with the plan (`09fcbe07`).
- **Class closure**: NONE - a scope change by ruling, not a defect; the amendment and this entry are the record.

### DRIFT-002 — the pre-review governance command still named iteration 001 (resolved)

- **Observed**: 2026-10-17, iteration-2 before-implement preparation. `.specrew/verification-plan.json` ran the
  governance validation against `iterations/001`, which is sealed. The fourth instance of the recurrence 202 DRIFT-011
  (iteration 001) recorded: the command names an iteration number instead of the active iteration.
- **Requirement citation**: the review's verification plan must validate the active iteration (iteration 001 DRIFT-011).
- **Resolution**: re-pointed to `iterations/002` (command `iteration-002-governance-202`). Run locally: PASS, exit 0, with
  six `handoff-block-missing` warnings for boundary commits whose packets were not saved as handoff evidence (B4F-136's
  Codex observation, seen here on Claude too; non-blocking).
- **Class closure**: NONE - making the command name the active iteration is beta5 work (the review engine), per the
  iteration-2 scope ruling.
