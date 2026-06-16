# Hardening Gate: Iteration 001

**Schema**: v1
**Gate ID**: `pre-implementation-hardening`
**Feature Ref**: `specs/183-stability-quality-bundle/spec.md`
**Iteration Ref**: `specs/183-stability-quality-bundle/iterations/001`
**Requested Review Class**: `strongest-available`
**Effective Review Class**: `strongest-available`
**Overall Verdict**: `deferred-with-approval`
**Approval Ref**: `f183-i001-before-implement-approved`
**Reviewed By**: Reviewer
**Reviewed At**: 2026-06-16T05:43:30Z

## Concern Review

| Concern | Category | Status | Evidence Basis | Runtime Evidence Status | Expected Controls | Blocking | Rationale | Approval |
| --- | --- | --- | --- | --- | --- | --- | --- | --- |
| `security-surface` | `security` | `addressed` | `planning-time-analysis` | `pending-post-implementation` | Treat hook payloads and Antigravity hook config as untrusted input. Sanitize host session IDs before filesystem use; never write global `unknown` state for malformed IDs; preserve existing user entries in project-scoped `.agents/hooks.json`; abort hook config writes on unsafe parse/merge; do not use global Antigravity config; add no runtime dependency. | `true` | FR-003, FR-007, LIR-004, and LIR-005 make input/config safety load-bearing. T003 owns session-key sanitization and T006 owns Antigravity project config preservation; review must prove both before signoff. | `—` |
| `error-handling-expectations` | `error-handling` | `addressed` | `planning-time-analysis` | `pending-post-implementation` | Fail open but governed: over-cap SessionStart output keeps bootstrap and drops/shrinks lower-priority refocus first; provider failure emits a non-empty under-cap governed fallback on stdout and exits 0; unsafe Antigravity config work leaves user config untouched and reports fallback guidance; closeout no-upstream paths do not instruct impossible pushes. | `true` | The feature is a stability bundle; silent bootstrap loss, raw provider exceptions, user-config clobber, and false closeout wording are the principal failure modes. T001, T004, and T006 carry deterministic negative-path tests. | `—` |
| `retry-idempotency-requirements` | `retry-idempotency` | `addressed` | `planning-time-analysis` | `pending-post-implementation` | Hook provisioning must be re-runnable: Specrew-owned Antigravity entries are added or refreshed without duplication, remove/opt-out behavior is repeat-safe, and user entries are preserved. Closeout dashboard refresh is deterministic on auto-detect. No background retry loop, network retry, or new queue is introduced. | `true` | Retry-specific infrastructure is not added, but idempotent local-file/config behavior is material because `specrew hooks install`, closeout sync, and repeated test runs can be invoked multiple times. T004 and T006 must prove repeat-safe behavior. | `—` |
| `test-integrity-targets` | `test-integrity` | `deferred-with-approval` | `planning-time-analysis` | `pending-post-implementation` | Tests must prove behavior, not file presence: synthetic SessionStart cap fixture, provider-failure fallback, missing/blank/malformed session IDs, dirty `.specify` classification, no-upstream wording, dashboard regeneration, #1761 scratch git isolation/module-internal assertion, Antigravity merge/remove/opt-out, and review-stage real-host pass/fail evidence. | `true` | FR-004 and the #1761 cleanup exist specifically because ambient-machine and wrong-copy tests were untrustworthy. T001-T006 provide deterministic Pester coverage; T002 must clear the known-red delivery-cap fixture before review-signoff, and T009 records real-host validation after the implementation slices merge. | `f183-i001-before-implement-approved` |
| `operational-resilience-concerns` | `operational` | `deferred-with-approval` | `planning-time-analysis` | `pending-post-implementation` | User-visible fallback text says governance is still active and points to `specrew where`, `/specrew-refocus`, `specrew hooks status`, and `specrew start --host <host>` where relevant. Source and `.specify` mirror parity are checked for touched extension/runtime files. Release beta target remains dynamic until local tags, origin tags, and published state are inspected. | `true` | Operational success is degraded-but-governed behavior, truthful partial Antigravity support, mirror parity, and release-readiness evidence. Availability cleared the entry bar only; no Antigravity parity claim is allowed until T006/T009 prove verified hook behavior, including a hook-firing Antigravity host before T009. | `f183-i001-before-implement-approved` |

## Before-Implement Conditions

| Condition | Status | Evidence | Decision |
| --- | --- | --- | --- |
| `condition-a-host-availability` | `closed` | 2026-06-16 local checks: `pwsh -NoProfile -ExecutionPolicy Bypass -File scripts/specrew-hooks.ps1 status --project-path .` reported `claude`, `cursor`, `codex`, and `copilot` installed; `Get-SpecrewHookCapableHosts` returned `claude`, `cursor`, `codex`, and `copilot`; `agy --version` returned `1.0.8`; file:///C:/Dev/183-stability-quality-bundle/.antigravitycli exists. | Real hook-capable host availability is present through the existing hook-capable hosts. An Antigravity environment is reachable through `agy`, so the FR-007 split guard is not tripped by host availability. T006/T009 still must prove only verified Antigravity hook events/output behavior and real-host validation before any Antigravity parity claim. |

## Notes

- Before-implement is approved with instructions by `f183-i001-before-implement-approved`; runtime evidence remains pending until implementation/review records the named Pester, mirror, release-readiness, and real-host validation evidence.
- The quality-profile resolver still detects repository-level React signals, but this feature's approved scoped profile is `powershell-json-yaml-pester`.
- T001 and T003 remain serial by default because they share hook runtime/bootstrap surfaces and `tests/bootstrap/**`.
- If Antigravity verification expands beyond project-scoped `.agents/hooks.json` merge/remove/opt-out, verified event mapping, docs/status cleanup, and fallback guidance, pause for a human split/defer decision before continuing.
- Protocol correction: before-implement is a human-judgment stop. The T001 gate slip is logged and fully resolved in file:///C:/Dev/183-stability-quality-bundle/specs/183-stability-quality-bundle/iterations/001/drift-log.md by the explicit approval `f183-i001-before-implement-approved`; this approval ratifies T001 and authorizes T003 onward.
