# Hardening Gate: Iteration 001

**Schema**: v1
**Gate ID**: `pre-implementation-hardening`
**Feature Ref**: `specs/174-hook-driven-session-bootstrap/spec.md`
**Iteration Ref**: `specs/174-hook-driven-session-bootstrap/iterations/001`
**Requested Review Class**: `strongest-available`
**Effective Review Class**: `strongest-available`
**Overall Verdict**: `ready`
**Approval Ref**: —
**Reviewed By**: Reviewer
**Reviewed At**: 2026-06-08T13:35:00Z

## Concern Review

| Concern | Category | Status | Evidence Basis | Runtime Evidence Status | Expected Controls | Blocking | Rationale | Approval |
| --- | --- | --- | --- | --- | --- | --- | --- | --- |
| `security-surface` | `security` | `addressed` | `planning-analysis` | `pending` | Trust boundary is the local project tree (security-compliance d1): hook event JSON strictly parsed, never evaluated; absolute-path anchors treated non-portable and re-resolved against the project root (FR-015), `..`/foreign paths refused; external state (handover next-step, anchor) is advisory and never auto-authorizes a boundary (security d2, Rule 1); no elevation, no network, no secrets. | `true` | Security lens trust-boundary decisions (local-tree trust + advisory-not-authorizing + fail-safe). Controls carried by T002 (SessionStateAccessor portability), T003 (ProjectMetadataAccessor), T005 (ValidationEngine clearing); denial paths in T002/T005 suites (SC-004). | `—` |
| `error-handling-expectations` | `error-handling` | `addressed` | `planning-analysis` | `pending` | Fail-open on availability, fail-closed on authority (security d3): an invalid/stale/merged/non-portable anchor is cleared and the user still gets the full menu (never blocked); a "cleared a stale anchor" reason line is surfaced from `validation_findings`; uncertainty never auto-advances a gate. | `true` | integration-api d3 (fail-open envelope) + security d3; the proof vehicle is the SC-004 stale/merged/non-portable anchor suite and the cleared-anchor classification path in T004/T005. | `—` |
| `retry-idempotency-requirements` | `retry-idempotency` | `not-applicable` | `planning-analysis` | `pending` | Launcher↔hook dedupe / exactly-once (FR-007, SC-002) is iteration 002 scope (T013); the iteration-001 direct-launch anchor-path slice is single-shot with no retry or cross-session race. Re-evaluated when 002 adds dedupe. | `false` | The quality-profile resolver auto-marked this n/a; for this slice it is genuinely n/a because dedupe lands in 002. Recorded here so the omission stays reviewable. | `—` |
| `test-integrity-targets` | `test-integrity` | `addressed` | `planning-analysis` | `pending` | Runtime claims require runtime evidence: pure ClassificationEngine + ValidationEngine get in-memory path tests for every anchor-stage mode (full / cleared-anchor) and each clearing reason (merged / closed / non-portable); no file-presence-only assertions; the basic journal record is asserted (SC-007 seed). | `true` | observability d2 (pure engines → per-path tests) + the plan test strategy; SC-004 is the proof vehicle. Full per-path journal-assertion + per-host empirical evidence land in 003. | `—` |
| `operational-resilience-concerns` | `operational` | `addressed` | `planning-analysis` | `pending` | Reuse the F-171 deployment loop, kill switch, breaker, and journal (devops d1); the B2 provider registers through that loop with no new install path; every new `.ps1` is added to the module FileList (install-break guard). The F-171 dispatcher is reused unchanged (B1/B3 regression safety, verified in 003). | `true` | devops-operations d1 + requirements-nfr; T007 registers via the F-171 loop and carries the FileList obligation; B1/B3 regression proof is T019 (iteration 003). | `—` |

## Notes

- Planning-time gate: evidence basis is `planning-analysis` with runtime evidence `pending`;
  it is recorded at iteration close once tests run. `Overall Verdict: ready` means iteration
  001 is ready to begin implementation, not that runtime proof exists yet.
- `retry-idempotency` is intentionally `not-applicable` for THIS slice only — dedupe /
  exactly-once (SC-002) is iteration 002 (T013); it returns as `addressed` there.
- Scope held: B4 pre-compaction capture and Antigravity binding are out of feature scope
  (FR-012); the FR-012 negative test lands in iteration 003 (T019).
