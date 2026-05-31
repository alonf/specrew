# Hardening Gate: Iteration 003 (Iteration 2b)

**Schema**: v1  
**Gate ID**: `pre-implementation-hardening`  
**Feature Ref**: `specs/051-multi-session-foundation/spec.md`  
**Iteration Ref**: `specs/051-multi-session-foundation/iterations/003`  
**Requested Review Class**: `phase-1-custom-composition` + state/concurrency review lens  
**Effective Review Class**: phase-1-custom-composition + state/concurrency review lens (planning-time)  
**Overall Verdict**: ready  
**Approval Ref**: -  
**Reviewed By**: Specrew Crew Coordinator  
**Reviewed At**: 2026-06-01  
**Post-Implementation Verification**: pending — implementation has not started; per-concern Runtime Evidence Status rows remain `pending-post-implementation` because Evidence Basis is `planning-time-analysis`.  
**Verified At**: pending

## Concern Review

| Concern | Category | Status | Evidence Basis | Runtime Evidence Status | Expected Controls | Blocking | Rationale | Approval |
| --- | --- | --- | --- | --- | --- | --- | --- | --- |
| `security-surface` | `security` | `addressed` | `planning-time-analysis` | `pending-post-implementation` | Multi-developer detection may count unique machine fingerprints from local/gitignored surfaces but must not commit rich fingerprints or transmit them. Recommendation outputs use counts/coarse explanations only. | `false` | FR-020 consumes identity-bearing signals; privacy controls from Iteration 2a must remain intact. | - |
| `error-handling-expectations` | `error-handling` | `addressed` | `planning-time-analysis` | `pending-post-implementation` | Decisions split, JSON Lines reads, and signal detection tolerate missing files, invalid log lines, empty git history, absent active-sessions files, and unavailable branch metadata with warnings or empty results rather than start/sync crashes. | `false` | This iteration runs at `specrew start`, `specrew where`, and boundary sync; advisory detection must degrade safely. | - |
| `retry-idempotency-requirements` | `retry-idempotency` | `addressed` | `planning-time-analysis` | `pending-post-implementation` | Re-running boundary sync must not duplicate decision entries, re-sort FileList into a different order, or emit duplicate lifecycle events. JSON Lines appends one complete object per event; decisions split paths are deterministic (`iteration-NNN`). | `false` | FR-017 through FR-019 are repeated boundary-time operations, so they must be stable across retries and resumed sessions. | - |
| `test-integrity-targets` | `test-integrity` | `addressed` | `planning-time-analysis` | `pending-post-implementation` | Acceptance tests cover decisions split, FileList sorting, two-git-author recommendation, and `session_mode: multi` suppression. T054 reruns the 2a+2b focused suite; T055 runs the governance validator. | `false` | This slice has multiple shared surfaces; tests must exercise observable behavior, not only helper presence. | - |
| `operational-resilience-concerns` | `operational-resilience` | `addressed` | `planning-time-analysis` | `pending-post-implementation` | Recommendations appear only when signals exist and `session_mode` is `single`; FR-024 suppresses redundant prompts once `session_mode` is `multi`; boundary-sync and dashboard output stay advisory, not blocking. | `false` | False-positive multi-dev warnings would make `specrew start` noisy and reduce trust in the signal. | - |
| `shared-state-conflict-reduction` | `concurrency` | `addressed` | `planning-time-analysis` | `pending-post-implementation` | Decisions split only when multi-session mode is enabled; legacy `.squad/decisions.md` remains readable; boundary sync must not duplicate or lose entries during transition. | `false` | FR-017 changes a durable shared artifact; the control must reduce merge conflicts without breaking existing decision history. | - |
| `manifest-sort-safety` | `maintainability` | `addressed` | `planning-time-analysis` | `pending-post-implementation` | `Specrew.psd1` FileList sorting preserves membership, comments/manifest validity, and alphabetical order; tests compare before/after membership and validate PowerShell manifest import. | `false` | FR-019 touches module packaging. A sort helper must not drop files or produce an invalid manifest. | - |

## Planning Evidence Notes

- **Scope**: Iteration 2b — conflict reduction (US5, FR-017-019) + multi-developer auto-detection (US6, FR-020-024), 13 SP (T034-T055). See iterations/003/plan.md.
- **Risk focus**: shared-state conflict reduction, append-only log integrity, manifest sorting safety, recommendation noise, and fingerprint privacy.
- **Capacity precondition**: 13 SP, within the <=20 SP cap.

## Hardening-Gate Status

**Overall Verdict**: ready — all 2b planning-time concerns have named controls and test targets. Implementation may begin only after the human approves the before-implement boundary.

**Scope**: Iteration 2b — conflict reduction + multi-developer auto-detection, 13 story_points.
