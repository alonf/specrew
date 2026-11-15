# Hardening Gate: Iteration 003

**Schema**: v1
**Gate ID**: `pre-implementation-hardening`
**Feature Ref**: `specs/205-workshop-lens-order/spec.md`
**Iteration Ref**: `specs/205-workshop-lens-order/iterations/003`
**Requested Review Class**: `strongest-available`
**Effective Review Class**: `(pending hardening review)`
**Overall Verdict**: `blocked`
**Approval Ref**: `—`
**Reviewed By**: Reviewer (pending)
**Reviewed At**: 2026-11-15T11:29:44Z

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
| `security-surface` | `security` | `addressed` | `planning-time-analysis` | `pending-post-implementation` | release notes fetched only from the vendors' official pages, each with URL and date; no fetched text executed; the agenda renderer writes only inside the project (`.specrew/handover/`) as today | `true` | the trust boundary is unchanged: lens text, a YAML catalog and the agenda script's output; the new facts come from fetched web pages, so unconfirmed facts are left out (FR-030) | `—` |
| `error-handling-expectations` | `robustness` | `addressed` | `planning-time-analysis` | `pending-post-implementation` | a per-stack rule with no date is a test failure, not a silent skip; a date older than 90 days renders the stale marker; non-UTF-8 output is prevented by the script setting its output encoding, and a test round-trips the markers | `true` | failure semantics: a missing or stale date is shown, never hidden; an agenda whose pasted block does not match the stored canonical text still refuses to bind, as today | `—` |
| `retry-idempotency-requirements` | `resilience` | `not-applicable` | `not-applicable` | `not-needed` | `—` | `false` | no retries, keys or shared state: the line function is pure and the agenda renderer keeps its atomic single write | `—` |
| `test-integrity-targets` | `verification` | `addressed` | `planning-time-analysis` | `pending-post-implementation` | FR-030: SC-011 test (date per stack rule, no version in rule text, 91-day fixture stale, 90-day not); FR-032: grouping on the real catalog and a changed-tag fixture, the kept `Selected lenses:` line, UTF-8 round trip; each red first; self-tests swap, remove and reword per item | `true` | positive and negative per FR, checked per item rather than by totals (iteration 002 retro action 1); results in `quality-evidence.md` | `—` |
| `operational-resilience-concerns` | `operability` | `not-applicable` | `not-applicable` | `not-needed` | `—` | `false` | no server, SLO or telemetry: lens text, a catalog, a local script and tests; no calendar-driven CI gate under the recommended design Option A | `—` |

## Lens Activation (Planning Baseline)

| Lens Ref | Activation | Planned Evidence Path |
| --- | --- | --- |
| `security-baseline@v1.0.0` | required | `specs/205-workshop-lens-order/iterations/003/quality/lenses/security-baseline.md` |
| `robustness-baseline@v1.0.0` | required | `specs/205-workshop-lens-order/iterations/003/quality/lenses/robustness-baseline.md` |
| `test-integrity@v1.0.0` | required | `specs/205-workshop-lens-order/iterations/003/quality/lenses/test-integrity.md` |

## Notes

- Replace every `<placeholder>` and every angle-bracketed instruction with iteration-specific content before crossing the `before-implement` boundary.
- After every row in the table is filled in with a canonical Status, flip the metadata `Overall Verdict` to `ready` (if every concern is `addressed` / `not-applicable` / `deferred-with-approval`) or keep `blocked`.
- Runtime evidence (lens execution, test counts, mechanical-findings results) is collected after implementation lands; the gate is a PLANNING-time artifact and that deferral is intentional.
