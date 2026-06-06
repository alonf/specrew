# Hardening Gate: Iteration 001

**Schema**: v1
**Gate ID**: `pre-implementation-hardening`
**Feature Ref**: `specs/171-specrew-refocus/spec.md`
**Iteration Ref**: `specs/171-specrew-refocus/iterations/001`
**Requested Review Class**: `strongest-available`
**Effective Review Class**: `strongest-available`
**Overall Verdict**: `ready`
**Approval Ref**: —
**Reviewed By**: Reviewer
**Reviewed At**: 2026-06-07T07:55:00Z

## Concern Review

| Concern | Category | Status | Evidence Basis | Runtime Evidence Status | Expected Controls | Blocking | Rationale | Approval |
| --- | --- | --- | --- | --- | --- | --- | --- | --- |
| `security-surface` | `security` | `addressed` | `runtime-evidence` | `pending-post-implementation` | Hooks auto-execute only the Specrew-deployed dispatcher (same trust class as existing lifecycle scripts; no elevation, no network, no secrets). `session_id` sanitized to `[a-zA-Z0-9-]` before filename use; catalog/digest sources repo-relative only (absolute/`..` refused with `SOURCE_CONFINED`); provider commands must resolve under the deployed tree (deploy-time validation); hook registration deploys ONLY to per-user `settings.local.json` (no clone-time execution surface); event JSON strictly parsed, never evaluated. Denial-path tests required (SC-007). | `true` | Lens-5 trust-boundary walk (workshop record) identified exactly two injection vectors — session-id→filename and catalog→file-reads — each with a concrete confinement control; T001/T006 carry the controls, T001/T006 suites carry the denial paths. | `—` |
| `error-handling-expectations` | `error-handling` | `addressed` | `runtime-evidence` | `pending-post-implementation` | Fail-open everywhere: a trigger failure NEVER blocks a session (P1, SC-001); every failure emits exactly one visible `[specrew-refocus] WARN <CODE>` with one of 8 enumerated reason codes; missing canonical files yield partial payload + `SOURCE_MISSING`; catalog schema mismatch yields `CATALOG_SCHEMA` fail-open; injection failures degrade to silence + one WARN ("fail-open for the session, fail-quiet-but-loud-once for the automation"). | `true` | The refuse-to-do register (lens 3) and the failure-trace design (lens 7) define the complete failure surface; SC-001 fault-injection suite (missing catalog, corrupt digest, locked state, dead provider, malformed event JSON) is the proof vehicle in T001/T006/T009. | `—` |
| `retry-idempotency-requirements` | `retry-idempotency` | `addressed` | `runtime-evidence` | `pending-post-implementation` | Exactly-once injection per boundary crossing across BOTH channels (wrapper-stdout fingerprint + hook state-diff dedupe, SC-002); per-session dedupe state keyed by sanitized session id (no cross-session races); re-fire allowed only after real context loss (compact/restart); hook handlers re-entrant; deploy re-runs byte-idempotent (SC-009). | `true` | The resolver auto-marked this dimension n/a, but the feature's dedupe/exactly-once semantics ARE idempotency concerns — explicitly covered per the plan's quality note via SC-002 fixtures (both channel orders) in T004/T007/T008 and deploy idempotence in T010/T011. | `—` |
| `test-integrity-targets` | `test-integrity` | `addressed` | `runtime-evidence` | `pending-post-implementation` | Runtime claims require runtime evidence: engine suites assert golden payloads/caps/refusals (not file presence); dispatcher suites drive simulated event JSON through the REAL dispatcher; breaker trip fixtures assert trip scope + single WARN + journal records; SC-008 beta validation exercises a REAL compaction + REAL boundary cross on ≥2 hook-bound hosts — file-presence evidence explicitly does not satisfy it. | `true` | The lens-7 binding review rule ("runtime claims cite journal or live-host evidence, never file presence") is the F-054 lesson built into this feature's success criteria; FR-020 enumerates the suites and every task carries its tests. | `—` |
| `operational-resilience-concerns` | `operational` | `addressed` | `runtime-evidence` | `pending-post-implementation` | Automatic per-session circuit breaker (per-trigger trip for runaway; global for token-cap/state-loss; dispatcher path only — slash + channel 1 constitutionally exempt); three manual kill-switch levels (env var first-line check / per-trigger catalog flags / hook de-registration with remembered opt-out); `specrew update` never silently flips a human disable decision; `--status` + bounded injection journal give operators the full failure trace where every branch ends in one named action. | `true` | The lens-6 kill-switch/breaker design (human-probed twice in the workshop) plus the lens-7 journal/reason-code design are the operator story; T009 implements and fixture-proves them (SC-005, SC-006, SC-010). | `—` |

## Notes

- Planning-time gate: all five concerns addressed with feature-specific controls bound in the 7-lens intake workshop (records under `specs/171-specrew-refocus/workshop/`); runtime evidence lands during T001-T012 and is re-verified at review-signoff.
- The retry-idempotency row intentionally OVERRIDES the quality-profile resolver's n/a auto-detection — dedupe/exactly-once is this feature's core correctness property (see plan.md quality note).
- Release-blocking: SC-008 runtime beta validation gates stable promotion; TG-004 (latency fallback) returns to the human with measurements if the P4 bar is missed.
- Forward-compat: the dormant gate-kind provider path (F-165 seat) ships fixture-tested but UNREGISTERED — no PreToolUse registration until the first gate row exists (maintainer-directed 2026-06-07).
