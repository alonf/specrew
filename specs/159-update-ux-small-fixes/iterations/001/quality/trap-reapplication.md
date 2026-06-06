# Trap Reapplication: Iteration 001

**Feature**: 159-update-ux-small-fixes  
**Iteration**: 001  
**Phase**: before-implement planning

## Known Trap Checks

| Trap | Applicability | Planned Control |
| --- | --- | --- |
| Silent project downgrade | applicable | Stale-module preflight guard fails before mutation. |
| Smoke-only negative path | applicable | T003 requires deterministic protected-surface snapshots/hashes. |
| Generated-governance drift import | applicable | T004 restricts generated active-surface edits to stale `0.24.0` wording only. |
| Tool availability assumption | applicable | T005 requires `Select-String` fallback when `rg` is unavailable. |
| Parallel work collision | applicable | T006 requires changed-file collision review against Feature 141 and Proposal 160. |

## Status

Planning controls are ready. Runtime reapplication evidence is pending implementation/review.
