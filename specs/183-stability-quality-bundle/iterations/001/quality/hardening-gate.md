# Hardening Gate: Iteration 001

**Schema**: v1
**Gate ID**: `pre-implementation-hardening`
**Feature Ref**: `specs/183-stability-quality-bundle/spec.md`
**Iteration Ref**: `specs/183-stability-quality-bundle/iterations/001`
**Requested Review Class**: `strongest-available`
**Effective Review Class**: `strongest-available`
**Overall Verdict**: `ready`
**Approval Ref**: `—`
**Reviewed By**: Reviewer
**Reviewed At**: 2026-06-16T00:37:03Z

## Concern Review

| Concern | Category | Status | Evidence Basis | Runtime Evidence Status | Expected Controls | Blocking | Rationale | Approval |
| --- | --- | --- | --- | --- | --- | --- | --- | --- |
| `security-surface` | `security` | `addressed` | `planning-time-analysis` | `pending-post-implementation` | Treat hook payloads and Antigravity hook config as untrusted input. Sanitize host session IDs before filesystem use; never write global `unknown` state for malformed IDs; preserve existing user entries in project-scoped `.agents/hooks.json`; abort hook config writes on unsafe parse/merge; do not use global Antigravity config; add no runtime dependency. | `true` | FR-003, FR-007, LIR-004, and LIR-005 make input/config safety load-bearing. T003 owns session-key sanitization and T006 owns Antigravity project config preservation; review must prove both before signoff. | `—` |
| `error-handling-expectations` | `error-handling` | `addressed` | `planning-time-analysis` | `pending-post-implementation` | Fail open but governed: over-cap SessionStart output keeps bootstrap and drops/shrinks lower-priority refocus first; provider failure emits a non-empty under-cap governed fallback on stdout and exits 0; unsafe Antigravity config work leaves user config untouched and reports fallback guidance; closeout no-upstream paths do not instruct impossible pushes. | `true` | The feature is a stability bundle; silent bootstrap loss, raw provider exceptions, user-config clobber, and false closeout wording are the principal failure modes. T001, T004, and T006 carry deterministic negative-path tests. | `—` |
| `retry-idempotency-requirements` | `retry-idempotency` | `addressed` | `planning-time-analysis` | `pending-post-implementation` | Hook provisioning must be re-runnable: Specrew-owned Antigravity entries are added or refreshed without duplication, remove/opt-out behavior is repeat-safe, and user entries are preserved. Closeout dashboard refresh is deterministic on auto-detect. No background retry loop, network retry, or new queue is introduced. | `true` | Retry-specific infrastructure is not added, but idempotent local-file/config behavior is material because `specrew hooks install`, closeout sync, and repeated test runs can be invoked multiple times. T004 and T006 must prove repeat-safe behavior. | `—` |
| `test-integrity-targets` | `test-integrity` | `addressed` | `planning-time-analysis` | `pending-post-implementation` | Tests must prove behavior, not file presence: synthetic SessionStart cap fixture, provider-failure fallback, missing/blank/malformed session IDs, dirty `.specify` classification, no-upstream wording, dashboard regeneration, #1761 scratch git isolation/module-internal assertion, Antigravity merge/remove/opt-out, and review-stage real-host pass/fail evidence. | `true` | FR-004 and the #1761 cleanup exist specifically because ambient-machine and wrong-copy tests were untrustworthy. T001-T006 provide deterministic Pester coverage; T009 records real-host validation after the implementation slices merge. | `—` |
| `operational-resilience-concerns` | `operational` | `addressed` | `planning-time-analysis` | `pending-post-implementation` | User-visible fallback text says governance is still active and points to `specrew where`, `/specrew-refocus`, `specrew hooks status`, and `specrew start --host <host>` where relevant. Source and `.specify` mirror parity are checked for touched extension/runtime files. Release beta target remains dynamic until local tags, origin tags, and published state are inspected. | `true` | Operational success is degraded-but-governed behavior, truthful partial Antigravity support, mirror parity, and release-readiness evidence. T007-T009 are review-stage controls and T006 carries the Antigravity split guard. | `—` |

## Notes

- Planning-time readiness is `ready`; runtime evidence remains pending until implementation/review records the named Pester, mirror, release-readiness, and real-host validation evidence.
- The quality-profile resolver still detects repository-level React signals, but this feature's approved scoped profile is `powershell-json-yaml-pester`.
- T001 and T003 remain serial by default because they share hook runtime/bootstrap surfaces and `tests/bootstrap/**`.
- If Antigravity verification expands beyond project-scoped `.agents/hooks.json` merge/remove/opt-out, verified event mapping, docs/status cleanup, and fallback guidance, pause for a human split/defer decision before continuing.
