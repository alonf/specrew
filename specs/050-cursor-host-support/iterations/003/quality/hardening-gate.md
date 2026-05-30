# Hardening Gate: Iteration 003

**Schema**: v1  
**Gate ID**: `pre-implementation-hardening`  
**Feature Ref**: `specs/050-cursor-host-support/spec.md`  
**Iteration Ref**: `specs/050-cursor-host-support/iterations/003`  
**Requested Review Class**: `phase-1-custom-composition`  
**Effective Review Class**: phase-1-custom-composition  
**Overall Verdict**: ready  
**Approval Ref**: —  
**Reviewed By**: Specrew Crew Coordinator  
**Reviewed At**: 2026-05-30  
**Post-Implementation Verification**: pending — docs added; manual live-Cursor smoke (`specrew start --host cursor`) human-verified; full host suite stays green.  
**Verified At**: —

## Concern Review

| Concern | Category | Status | Evidence Basis | Runtime Evidence Status | Expected Controls | Blocking | Rationale | Approval |
| --- | --- | --- | --- | --- | --- | --- | --- | --- |
| `security-surface` | `security` | `not-applicable` | `not-applicable` | `not-needed` | Iteration 003 is docs + a manual smoke; no production code, no auth/secret surface. Docs MUST NOT instruct users to embed `CURSOR_API_KEY` in commands. | `false` | Documentation iteration; the only security-relevant control is not teaching insecure secret handling, which the docs respect. | — |
| `error-handling-expectations` | `error-handling` | `addressed` | `planning-time-analysis` | `pending-post-implementation` | The quickstart documents the binary-missing path (InstallGuidance) and the no-slash-palette caveat so users are not surprised by absent autocomplete. | `false` | The dominant user-confusion paths (binary absent; no slash palette) are explicitly documented. | — |
| `retry-idempotency-requirements` | `retry-idempotency` | `not-applicable` | `not-applicable` | `not-needed` | No retry surface in docs. | `false` | N/A for a docs iteration. | — |
| `test-integrity-targets` | `test-integrity` | `addressed` | `planning-time-analysis` | `pending-post-implementation` | The quickstart commands must be accurate and runnable (the manual smoke T016 is the live verification that the documented `specrew start --host cursor` flow actually launches Cursor). | `false` | Docs that can't be followed are worse than none; the manual smoke is the integrity check that the quickstart is true. | — |
| `operational-resilience-concerns` | `operational-resilience` | `addressed` | `planning-time-analysis` | `pending-post-implementation` | Docs-only changes plus a manual smoke; no code touched, so the green host suite is unaffected. | `false` | Zero blast radius on runtime behavior. | — |
| `maintainability` | `maintainability` | `addressed` | `planning-time-analysis` | `pending-post-implementation` | The Cursor docs sit alongside the existing per-host docs in getting-started/user-guide for consistency; the interaction-model section is clearly scoped. | `false` | Keeps host docs uniform and discoverable. | — |
| `concurrency-correctness` | `concurrency` | `not-applicable` | `not-applicable` | `not-needed` | No concurrency surface. | `false` | Docs + manual smoke. | — |

## Planning Evidence Notes

- Iteration 003 scope: T014 (getting-started quickstart) + T015 (user-guide interaction model) + T016 (manual live-Cursor smoke — HUMAN-verified, SC-001/002/003/005/007).
- The five canonical hardening concerns appear first in the required order.
- This iteration provides the human-verified end-to-end evidence the earlier (test-only) iterations could not: actually launching `specrew start --host cursor` in a live Cursor session.
- No production code changes; the iter-001 mirror-parity item remains the tracked feature-closeout action; feature-closeout also rebases onto post-F-049 main (169-commit lag) before the PR.

## Hardening-Gate Status

**Overall Verdict**: ready — a docs + manual-smoke iteration with all material risks addressed or not-applicable; the manual smoke (T016) is the live integrity check that the documented launch flow works.

**Scope**: Iteration 003 — Cursor documentation (getting-started quickstart + user-guide interaction model) + manual live-Cursor end-to-end smoke, ~3 story_points.
