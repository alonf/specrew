# Hardening Gate: Iteration 001

**Schema**: v1
**Gate ID**: `pre-implementation-hardening`
**Feature Ref**: `specs/199-beta3-stabilization/spec.md`
**Iteration Ref**: `specs/199-beta3-stabilization/iterations/001`
**Requested Review Class**: `strongest-available`
**Effective Review Class**: `(pending hardening review)`
**Overall Verdict**: `ready`
**Approval Ref**: `—`
**Reviewed By**: Coordinator (planning-time fill; runtime evidence pending post-implementation)
**Reviewed At**: 2026-08-10T01:35:00Z

<!--
  Concern Review schema (validator-enforced):
  - Status MUST be one of: `addressed` | `not-applicable` | `deferred-with-approval`. The validator
    rejects placeholder values like `tbd`. Pick a real status per concern before implementation.
  - When Status is `addressed`: EvidenceBasis = `planning-time-analysis`, RuntimeEvidenceStatus =
    `pending-post-implementation`, ExpectedControls = concrete controls you will enforce.
  - When Status is `not-applicable`: EvidenceBasis = `not-applicable`, RuntimeEvidenceStatus =
    `not-needed`, ExpectedControls = `—`. Rationale must explain WHY this concern does not apply.
  - When Status is `deferred-with-approval`: same evidence fields as `addressed`, AND the Approval
    column must reference an approval record (decision or defer) with a recorded human approval.
  - Overall Verdict is computed: `ready` when every concern is addressed/not-applicable/deferred-
    with-approval; `blocked` otherwise. Update the metadata above when you change the table.
-->

## Concern Review

| Concern | Category | Status | Evidence Basis | Runtime Evidence Status | Expected Controls | Blocking | Rationale | Approval |
| --- | --- | --- | --- | --- | --- | --- | --- | --- |
| `security-surface` | `security` | `addressed` | `planning-time-analysis` | `pending-post-implementation` | Reparse-tag allowlist fail-closed (cloud family only, hydrate-then-hash-verify; junction/symlink refusal untouched, denial fixtures stay green); continuation authority human-only (single-run grants, agents cannot mint; budget reset is an explicit human action); env_refs names-only pass-through (no environment persisted); capture authorizes only from a human verdict turn | `true` | Trust boundary: the containment roots (module install, authority store, frozen snapshot) and the continuation-authority path. T006 must not weaken the beta2 link refusal; T001/T004 keep spend and authorization provenance human-only | `—` |
| `error-handling-expectations` | `robustness` | `addressed` | `planning-time-analysis` | `pending-post-implementation` | Structured terminal outcomes per failure class (preflight-failed, claim-contended, launch-failed, timed-out, hydration-unavailable, hash-mismatch); authority contradictions fail closed and loudly; consumer-shaped failure messages name the missing piece and the exact next step; positive + negative fixtures per failure mode | `true` | Infra failures publish honest run records without consuming allowance (T008); hydration-unavailable is distinct from hash-mismatch corruption (clarified default); no failure class is sealed behind diagnostics (FR-013) | `—` |
| `retry-idempotency-requirements` | `resilience` | `addressed` | `planning-time-analysis` | `pending-post-implementation` | Pause/decision facts written with atomic FileMode.CreateNew (identical existing fact = idempotent success; conflicting fact = corruption, fail closed); no secret provider retries — every rerun is a new run_id consuming a visible human-authorized slot; schema/invariant failures never retried | `true` | The pending-pause fact introduces new shared-state writes into the authority store; the store's existing write-conflict semantics govern them (inherited code rules: write-conflict-semantics, careful-retries) | `—` |
| `test-integrity-targets` | `verification` | `addressed` | `planning-time-analysis` | `pending-post-implementation` | FR-to-named-fixture mapping recorded per task (tasks.md T001–T013 each name their test file); RED-first ordering per FR-023; paired honesty tests (legitimate + abuse) for every economics invariant; negative-path coverage for refusals (budget exhaustion, unknown reparse tags, unglossed IDs, banned nouns); the one manual measurement (OneDrive hydration) recorded with a transcribed, scoped proof line | `true` | Positive + negative per FR; smoke-only disallowed for failure-mode FRs; evidence tools verified before their output is trusted (198 method rules, FR-023) | `—` |
| `operational-resilience-concerns` | `operability` | `not-applicable` | `not-applicable` | `not-needed` | `—` | `false` | No server, SLO, telemetry pipeline, oncall surface, or operational dependency ships in this iteration — the product is a locally-run PowerShell module; release operations are the human-gated beta-stable train recorded at the devops lens | `—` |

## Lens Activation (Planning Baseline)

| Lens Ref | Activation | Planned Evidence Path |
| --- | --- | --- |
| `security-baseline@v1.0.0` | required | `specs/199-beta3-stabilization/iterations/001/quality/lenses/security-baseline.md` |
| `robustness-baseline@v1.0.0` | required | `specs/199-beta3-stabilization/iterations/001/quality/lenses/robustness-baseline.md` |
| `test-integrity@v1.0.0` | required | `specs/199-beta3-stabilization/iterations/001/quality/lenses/test-integrity.md` |

## Notes

- Replace every `<placeholder>` and every angle-bracketed instruction with iteration-specific content before crossing the `before-implement` boundary.
- After every row in the table is filled in with a canonical Status, flip the metadata `Overall Verdict` to `ready` (if every concern is `addressed` / `not-applicable` / `deferred-with-approval`) or keep `blocked`.
- Runtime evidence (lens execution, test counts, mechanical-findings results) is collected after implementation lands; the gate is a PLANNING-time artifact and that deferral is intentional.
