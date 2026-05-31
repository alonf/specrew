# Review: Iteration 002 — Iteration 2a: Collision Detection & Feature Claims

**Schema**: v1
**Reviewed**: 2026-05-31
**Overall Verdict**: accepted

## Review Summary

Iteration 2a is accepted. The implementation adds the local active-session lock
surface, the committed feature-claim surface, start-time collision warnings, claim
conflict continue/decline behavior, boundary claim refresh, and feature-closeout
cleanup. No manifest dependencies were added.

Reviewer notes:

- The implementation preserves the blessed D-003 split: rich machine fingerprints
  stay in gitignored `.specrew/active-sessions.yml`; committed claims use coarse
  `user@machine`.
- Claim conflict "continue" preserves the existing committed claim and records the
  current local session lock. That is consistent with the hardening-gate decision
  that claims remain upsert-by-feature rather than duplicate-by-developer.
- One adjacent regression, `tests/integration/lifecycle-boundary-sync.tests.ps1`,
  was attempted but blocked by a pre-existing fixture/installed-module
  feature-closeout gate issue. Focused 2a evidence is unaffected.

## Task Verdicts

| Task | Requirement | Verdict | Notes |
| ---- | ----------- | ------- | ----- |
| T020 | FR-007 | pass | `session-management.ps1` and shared `atomic-write.ps1` are present and exercised by unit tests. |
| T020b | FR-007, FR-043 | pass | `Get-MachineFingerprint` is local-only and stable under focused tests. |
| T020c | FR-005, FR-007 | pass | `.specrew/active-sessions.yml` is included in the per-session pattern set and reconciled in the data model. |
| T021 | FR-008 | pass | `specrew start` registers the current session lock; integration replay verifies the file is written. |
| T022 | FR-009 | pass | Feature-closeout removes active session locks for the feature. |
| T023 | FR-010 | pass | Active lock collisions surface a user-visible warning in start replay. |
| T024 | FR-011 | pass | Stale locks are cleared before collision checks and covered in unit + call-site replay. |
| T025 | FR-010 | pass | Real temp-repo start replay verifies collision warning on the start path. |
| T026 | FR-011 | pass | Stale-lock and corrupt-YAML safe degradation are covered in focused tests. |
| T026b | FR-007, FR-012 | pass | Deterministic atomic-write race tests keep files parseable and document last-write-wins honestly. |
| T027 | FR-012 | pass | `feature-claims.ps1` persists claims through the shared atomic/yaml helpers. |
| T028 | FR-013 | pass | Specify boundary adds the active feature claim in integration replay. |
| T029 | FR-014 | pass | Boundary sync refreshes `last_refresh_time` monotonically. |
| T030 | FR-015 | pass | Claim conflict warning, decline, and continue variants are replayed. |
| T031 | FR-016 | pass | Feature-closeout removes the claim when the feature appears in main merge history. |
| T032 | FR-013, FR-014, FR-016 | pass | Claim lifecycle create, refresh, re-add, and removal paths are covered by module and call-site tests. |
| T033 | FR-015 | pass | Concurrent-claim warning variants are covered, including no-session decline. |
| T033b | FR-007, FR-016 | pass | Focused tests and validator-as-audit were run; coverage evidence and data model were reconciled. |

## Gap Ledger

- No requirement (FR/SC) gaps: all in-scope requirements verified: fixed-now.

## Evidence

- `tests/unit/feature-051-session-management.tests.ps1`: pass
- `tests/unit/feature-051-feature-claims.tests.ps1`: pass
- `tests/integration/feature-051-iteration2a-callsite-wiring.tests.ps1`: pass
- `tests/integration/stale-state-detection.tests.ps1`: pass
- `tests/integration/boundary-sync-atomicity.tests.ps1`: pass
- `validate-governance.ps1 -ProjectPath .`: rerun after review artifact reconciliation

