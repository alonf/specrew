# Hardening Gate: Iteration 003

**Schema**: v1
**Gate ID**: `pre-implementation-hardening`
**Feature Ref**: `specs/174-hook-driven-session-bootstrap/spec.md`
**Iteration Ref**: `specs/174-hook-driven-session-bootstrap/iterations/003`
**Requested Review Class**: `strongest-available`
**Effective Review Class**: `strongest-available`
**Overall Verdict**: `ready`
**Approval Ref**: —
**Reviewed By**: Reviewer
**Reviewed At**: 2026-06-08T20:45:00Z

## Concern Review

| Concern | Category | Status | Evidence Basis | Runtime Evidence Status | Expected Controls | Blocking | Rationale | Approval |
| --- | --- | --- | --- | --- | --- | --- | --- | --- |
| `security-surface` | `security` | `addressed` | `runtime-evidence` | `recorded` | The downstream deploy (T021) places provider + components under the deployed extension tree via the F-171 loop only; the SessionEnd dispatch (T022) parses event JSON defensively, never evaluates it, and the write stays write-only (no `git add -A`). Local-tree trust boundary unchanged; per-host event shapes normalized before use. | `true` | Live-wiring widens the deploy + event surface; controls carried by T021/T022, proven by real dispatcher smokes. | `—` |
| `error-handling-expectations` | `error-handling` | `addressed` | `runtime-evidence` | `recorded` | Fail-open everywhere: a host whose per-host normalization fails degrades to no-bootstrap-for-that-host (not a block); SessionEnd write failure never breaks session exit (exit 0 + stderr warn); concurrency signals are advisory and never block. | `true` | integration-api d3 + security d3; per-host empirical verification (T017) and the SessionEnd round-trip smoke (T022) are the proof vehicles. | `—` |
| `retry-idempotency-requirements` | `retry-idempotency` | `addressed` | `runtime-evidence` | `recorded` | The SessionStart marker write is idempotent per session; the journal record is one-per-mode (no double-surface); the launcher<->hook dedupe (iteration 002) keeps exactly-once across launcher+hook. | `true` | The marker + journal additions must not reintroduce double-injection; T014/T018 assert single-record-per-event. | `—` |
| `test-integrity-targets` | `test-integrity` | `addressed` | `runtime-evidence` | `recorded` | Runtime claims need runtime evidence - and for the two live-wiring closures (D-001/D-002) test-only is explicitly NOT sufficient: T021 requires a REAL cross-host SessionStart dispatcher smoke, T022 a REAL SessionEnd->SessionStart round-trip dispatcher smoke. Plus per-path journal-assertion tests (SC-007), per-host empirical evidence (T017), and B1/B3 regression (T019). | `true` | The live-wiring proof bar (decisions `f174-i003-livewiring-first`) and the build+test!=live review-signoff check; SC-007/SC-001/SC-005 are the proof vehicles. | `—` |
| `operational-resilience-concerns` | `operational` | `addressed` | `runtime-evidence` | `recorded` | The downstream deploy rides the F-171 deployment loop + kill switch + managed markers (no new install path); the SessionEnd handling is added to the dispatcher ADDITIVELY and must leave B1/B3 byte-unchanged (FR-011), verified by T019. | `true` | devops d1 + requirements-nfr; T019 regression proves B1/B3 unchanged after the dispatcher edit. | `—` |

## Notes

- Planning-time gate (before-implement): evidence basis `planning-time-analysis`, runtime evidence
  `pending-post-implementation`; recorded at iteration-003 review.
- Live-wiring proof bar: T021 + T022 require REAL dispatcher smokes (not unit-test-only) - the
  iteration-001 D-001 self-host bar applied to both D-001 and D-002.
- FR-012 stays out of scope (B4 + Antigravity): a negative test (T019) proves no such path executes.
