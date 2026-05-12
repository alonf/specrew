# Trap Reapplication: Feature 012

**Schema**: v1
**Scan ID**: `trap-reapplication.feature-012-iteration-002`
**Recorded At**: 2026-05-12T10:15:00Z

## Scan Log

| Trap Ref | Scan Scope | Result | Matches |
| --- | --- | --- | --- |
| `known-traps.md#human-handoff-id-context` | Feature 012, descriptive references in handoffs, iteration 002 replay proof | `match-remediated` | The `human-handoff-id-context` corpus row is seeded, the new replay fixtures cover warn/pass and excluded-surface cases, and both replay scripts assert on validator `status`, `findings`, and `summary` output from the real governance review path. |
| `known-traps.md (user-facing handoff replay-path coverage row)` | Replay-path integrity for user-visible handoff checks | `match-remediated` | `tests\integration\descriptive-reference-authored-prose.ps1` and `tests\integration\descriptive-reference-excluded-surfaces.ps1` replay fixture text through `handoff-governance-validator.ps1` instead of inspecting helper state or fixture metadata alone. |
| `known-traps.md (feature 007 compatibility expectations)` | Regression preservation for the existing handoff-governance warnings and iteration 001 descriptive-reference detections | `no-match` | The recorded validation lane keeps the three feature 007 tests plus the narration and stop-message descriptive-reference tests green alongside the new replay coverage, so no compatibility drift was observed at the implementation boundary. |

## Notes

- This trap reapplication artifact records the closeout-boundary evidence for feature 012 after review, retrospective, and the green closeout lane are complete.
- The replay-path proof stays additive and non-blocking on the closeout tree: warn fixtures still exit zero, excluded verbatim fixtures remain pass cases, and the preserved feature 007 plus iteration 001 regressions still pass alongside the replay lane.
