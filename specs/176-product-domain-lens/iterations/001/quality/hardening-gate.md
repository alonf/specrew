# Hardening Gate: Iteration 001

**Schema**: v1
**Gate ID**: `pre-implementation-hardening`
**Feature Ref**: `specs/176-product-domain-lens/spec.md`
**Iteration Ref**: `specs/176-product-domain-lens/iterations/001`
**Requested Review Class**: `strongest-available`
**Effective Review Class**: `strongest-available`
**Overall Verdict**: `ready`
**Approval Ref**: —
**Reviewed By**: Reviewer
**Reviewed At**: 2026-06-09T20:30:00Z

## Concern Review

| Concern | Category | Status | Evidence Basis | Runtime Evidence Status | Expected Controls | Blocking | Rationale | Approval |
| --- | --- | --- | --- | --- | --- | --- | --- | --- |
| `security-surface` | `security` | `addressed` | `planning-time-analysis` | `pending-post-implementation` | No auth, secrets, PII, or network surface. The only new trust surface is evidence-integrity at the specify gate: a batch/agenda "confirm all" can NEVER satisfy product-domain confirmation (FR-009), and the record's `confirmation` / `confirmation_scope` must be a genuine `human-confirmed` / `lens-question` (reused SC-026 enum). The record path is repo-relative under `specs/<feature>/workshop/` (no session-id or external path injection). Denial-path test: a batch-approved record FAILS the gate (T011). | `true` | The lens machinery introduces no privilege/secret/network; the security concern reduces to "can the grounding be faked or skipped", confined by the gate floor (T010) + the FR-009 denial path (T011) + the graceful-degradation no-silent-skip test (T015). | `—` |
| `error-handling-expectations` | `error-handling` | `addressed` | `planning-time-analysis` | `pending-post-implementation` | Graceful degradation, never a silent skip: an absent lens catalog, host skill copy, or deploy surface surfaces a `[product-domain] WARN` and fails the gate CLOSED on a substantive feature rather than passing silently (T015). Schema-version mismatch is a fail-open WARN (additive evolution). A malformed/partial record fails the gate with the missing/invalid reason (T010). | `true` | The robustness driver is "the grounding cannot be silently bypassed"; T015 fixture-proves the no-silent-skip behavior across catalog/skill/deploy absence, and T010 proves the fail-closed reason path. | `—` |
| `retry-idempotency-requirements` | `retry-idempotency` | `not-applicable` | `not-applicable` | `not-needed` | No retry logic and no concurrent writers. Record writes are idempotent (re-running with the same inputs rewrites an equivalent record, UTF-8 no-BOM); there is no network, queue, or shared mutable runtime state. | `false` | The feature is a synchronous, single-writer, design-time artifact writer; retry/idempotency-keys/conflict-detection have no material surface here (recorded explicitly so the omission stays reviewable). | `—` |
| `test-integrity-targets` | `test-integrity` | `addressed` | `planning-time-analysis` | `pending-post-implementation` | Behavior-proving Pester suites, not file-presence: depth selection across L/S/D (T007), evidence tags + conditional load-bearing research-needed blocking (T008), dual-artifact persistence (T009), batch-approval rejection (T011), the runs-before-questionnaire ordering (T006), schema conformance incl. the hooks (T013), host-skill parity (T014), and graceful degradation (T015). PSScriptAnalyzer + mechanical-checks + the governance validator round out the bar. | `true` | The plan's verification gate names each suite to a behavior; SC-001..SC-009 are the acceptance bars, and FR-009/FR-010 carry explicit denial paths so "passes" cannot mean "file exists". | `—` |
| `operational-resilience-concerns` | `operational` | `addressed` | `planning-time-analysis` | `pending-post-implementation` | Multi-host conduct parity: the lens md is one shared catalog file; the conduct deploys to the host-managed skill surfaces of all five supported hosts (four on-disk surfaces) via the managed-skill path, guarded by a host-parity test (T014). No host is silently unsupported. Graceful degradation (T015) keeps a missing surface loud, not silent. | `true` | The portability story is the deploy-parity test (T014) + the 5-host/4-surface deploy coverage (T012); operationally the only failure mode is a missing surface, which T015 forces to be surfaced. | `—` |

## Notes

- This is a PLANNING-TIME pre-implementation gate: Status reflects planned controls and expected
  test coverage; Runtime Evidence Status is `pending` for all concerns until the implementation/review
  slice collects the Pester + mechanical-checks + validator evidence (no runtime proof is claimed yet).
- The `retry-idempotency` row is `not-applicable` with explicit rationale (synchronous single-writer
  design-time artifact writer) — recorded so the omission stays reviewable, per the no-silent-skip
  discipline.
- Deferred (not blocking): FR-007 (Proposal 156 emission) and FR-008 (Proposal 162 inheritance) ship
  as forward-compatible shape only; runtime wiring is out of scope this iteration (drift D-001/D-002).
- No product code is written until the human's explicit "start implementation" go-ahead at the
  before-implement boundary.
