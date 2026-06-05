# Hardening Gate: Iteration 011

**Schema**: v1
**Gate ID**: `pre-implementation-hardening`
**Feature Ref**: `specs/141-design-gate-runtime-hardening/spec.md`
**Iteration Ref**: `specs/141-design-gate-runtime-hardening/iterations/011`
**Requested Review Class**: `strongest-available`
**Effective Review Class**: `claude`
**Overall Verdict**: `ready`
**Approval Ref**: `—`
**Reviewed By**: Reviewer
**Reviewed At**: 2026-06-05T22:30:00Z

**Pre-Implementation Readiness**: Iteration 11 (Amendment A7) fixes the testLenses7codex Squad blocker — the
workshop backfilled synthetic "Human agreed" for un-surfaced lenses because the coordinator's stopping
judgment declared intake "specific enough" after ~3 questions. Option B (decision `3ea67b32`): a structural
per-lens provenance floor (SC-026, grandfather-gated by `confirmation_required`) under the FR-038 integrity
invariant + the `squad.agent.md` stopping-completeness rule (the root-cause lever) + the FR-040 intake UX.
18/20 SP. The floor is deterministic + LLM/network-free; the deploy is unchanged (the skill is edited in
place). SC-027 (does the agent stop manufacturing agreement on the Squad host?) is behavioral → the **Squad
re-dogfood** is the acceptance, not the unit floor.

## Concern Review

| Concern | Category | Status | Evidence Basis | Runtime Evidence Status | Expected Controls | Blocking | Rationale | Approval |
| --- | --- | --- | --- | --- | --- | --- | --- | --- |
| `security-surface` | `security` | `not-applicable` | `not-applicable` | `not-needed` | `—` | `false` | The change is a deterministic JSON/enum gate check, markdown skill conduct, and a coordinator-prompt rule; no auth, secrets, network, eval, or credential persistence. | `—` |
| `error-handling-expectations` | `robustness` | `addressed` | `design-analysis` | `pending-implementation` | The floor degrades gracefully (malformed/missing `lens-applicability.json` → no-op `catch`, the existing pattern); the `confirmation_required` marker keeps pre-A7 artifacts no-op (grandfather-safe); the FR-038 delegate/skip exception means the agent is never stuck — it can honestly record delegated/skipped rather than fabricate. | `true` | Defect class is a malformed artifact or a pre-A7 artifact being retroactively failed; controls are the no-op catch + the marker gate, verified by the grandfather test. | `—` |
| `retry-idempotency-requirements` | `resilience` | `not-applicable` | `not-applicable` | `not-needed` | `—` | `false` | No retries/transactions/idempotency surface; the floor is a pure read of the artifact, re-running is idempotent; the provenance field is an additive JSON key. | `—` |
| `test-integrity-targets` | `verification` | `addressed` | `design-analysis` | `pending-implementation` | SC-026 floor tests (positive valid provenance / missing / invalid enum / grandfather no-op) PLUS the **wiring integration test** that proves the floor FAILS through the real gate entry point for a missing/invalid provenance (the i7 lesson — isolation tests + a dogfood cannot catch a fail-open floor), PLUS presence-locks for the FR-038 invariant + count + exception, the FR-040 UX conduct, and the `squad.agent.md` stopping rule. | `true` | The floor is pure/deterministic → unit-provable; the behavioral payoff (the agent stops manufacturing agreement) is NOT unit-provable → the SC-027 Squad re-dogfood. | `—` |
| `operational-resilience-concerns` | `operability` | `addressed` | `design-analysis` | `pending-implementation` | The floor + conduct + coordinator rule are LLM/network-free; `index.yml` stays pure; the deploy is unchanged (the skill is edited in place; the existing flat-`.md` auto-discovery covers it); grandfather-safe; no release/publish/push; the deferred Proposal 156 scope stays out. | `true` | Operability = no network/LLM, additive + grandfather-safe schema, unchanged deploy, honest framing that the reliability payoff is the dogfood's. | `—` |

## Release-Blocking Items

- No beta/stable publishing in scope; no push/PR while Feature 141 is in progress.
- Implementation review must confirm: the floor is grandfather-safe (pre-A7 `workshop_intake` artifacts no-op),
  the wiring integration test proves the floor fires through the real gate entry, the deploy is unchanged,
  `index.yml` is NOT modified, and the deferred Proposal 156 scope stays out.
- The review MUST include the **SC-027 Squad re-dogfood** — a real Copilot/Squad run where synthetic agreements
  do not recur — not only the structural unit tests.

## Notes

- The three `addressed` concerns carry `pending-implementation` runtime-evidence at this pre-implementation gate;
  they promote to `runtime-evidence` at review-signoff on the strength of the floor tests + the wiring test.
- Overall Verdict `ready`; the integrity bar is the SC-027 dogfood, not the unit floor (the i6–i10 lesson, and
  the testLenses7 finding that only a real Squad run surfaced the blocker).
