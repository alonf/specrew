# Trap Reapplication: Feature 013

**Schema**: v1
**Scan ID**: `trap-reapplication.feature-013-iteration-002-implementation-boundary`
**Recorded At**: 2026-05-12T23:30:00Z

## Scan Log

| Trap Ref | Scan Scope | Result | Matches |
| --- | --- | --- | --- |
| `known-traps.md (canonical iteration state schema trap)` | Feature 013 iteration 002 implementation boundary | `match-remediated` | `extensions/specrew-speckit/scripts/validate-governance.ps1` continues to enforce the canonical eight-field `state.md` metadata schema, `tests/integration/validator-hardening-iteration1.ps1` still proves the rule on the replay path, and the corpus row is now marked `validator-enforced`. |
| `known-traps.md (canonical hardening-gate concerns trap)` | Feature 013 iteration 002 implementation boundary | `match-remediated` | `validate-governance.ps1` still enforces the canonical first-five concern order, the iteration-001 replay harness remains green, and `.specrew/quality/known-traps.md` now classifies the trap as `validator-enforced`. |
| `known-traps.md (approval-reuse row)` | Feature 013 iteration 002 approval-evidence reuse hardening | `match-remediated` | `shared-governance.ps1` now normalizes implementation-authorization quotes, `validate-governance.ps1` emits structured `approval-reuse` failures for sibling iterations, and `tests/integration/validator-hardening-iteration2.ps1` proves duplicate, blanket-scope, and distinct-quote scenarios. |
| `known-traps.md (over-claim row)` | Feature 013 iteration 002 closeout-truthfulness hardening | `match-remediated` | `validate-governance.ps1` now blocks closure claims that lack accepted review, retro, recorded hardening-gate verification, or a clean canonical iteration directory, while the replay harness proves repo-level evidence-only dirt remains excluded from the dirty-tree blocker. |

## Notes

- This artifact was updated at the Iteration 002 implementation boundary to capture the four targeted corpus traps that are now validator-enforced on the live tree.
- Review, retrospective, and final closeout evidence remain future lifecycle steps; this artifact intentionally stops at implementation-boundary proof and does not claim feature closure.
