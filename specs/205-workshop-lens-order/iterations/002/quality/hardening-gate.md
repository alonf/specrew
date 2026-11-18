# Hardening Gate: Iteration 002

**Schema**: v1
**Gate ID**: `pre-implementation-hardening`
**Feature Ref**: `specs/205-workshop-lens-order/spec.md`
**Iteration Ref**: `specs/205-workshop-lens-order/iterations/002`
**Requested Review Class**: `strongest-available`
**Effective Review Class**: `(pending hardening review)`
**Overall Verdict**: `ready`
**Approval Ref**: `—`
**Reviewed By**: Reviewer (pending)
**Reviewed At**: 2026-11-13T10:27:01Z

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
| `security-surface` | `security` | `not-applicable` | `not-applicable` | `not-needed` | `—` | `false` | No identity, secret, sensitive data or new trust boundary: the iteration edits lens text, the spec template and the product-domain record's free-form areas, and adds two tests. Copies refresh through the two project-only deploy scripts. | `—` |
| `error-handling-expectations` | `robustness` | `addressed` | `runtime-evidence` | `recorded` | Length test: reports all three numbers for every depth before it fails, and names which number broke which cap or which recorded value changed (negative self-tests: a Light cap breach; a Standard number changed without its record). Consumer test: reports every question with a missing or non-existent consumer in one run (negative fixture with several). A missing product-domain area shows as "product-domain: not stated", never as an error to the human. Post-implementation evidence (`quality/quality-evidence.md`): `tests/unit/workshop-length-budget.tests.ps1` (T018, `b29ba4e5`) ran red first on 2026-11-13 with 22 of 22 self-tests passing, among them a Light cap breach, a changed Standard or Deep number and nine consumer problems reported in one run, and the repository check failing on the 5 recorded numbers before T019 to T025. It passes at T025 (`0b3fc589`). The three review round 1 fixes each landed behind a red self-test commit (`8347d9d5` 6 failing, `3a13eaa4` 4, `335de732` 3); the fixes are `598d0836`, `22c0a583` and `398e9520`. A fact received without a stated answer reads "not stated" (operators' default). The test runs in CI as the named step `Workshop length budget and question consumers (FR-028/FR-029)`, green on `00273e84` and `57f14996`. | `true` | Report-all for both tests, as the iteration 001 parity test does; nothing in the workshop path gains a new failure mode. | `—` |
| `retry-idempotency-requirements` | `resilience` | `not-applicable` | `not-applicable` | `not-needed` | `—` | `false` | No retries, idempotency keys, transactional state or shared resources: lens text, the spec template and two read-only tests. | `—` |
| `test-integrity-targets` | `verification` | `addressed` | `runtime-evidence` | `recorded` | FR-028 -> a new length test (run red-first against recorded numbers, then green); FR-029 -> a new consumer test (red-first on the first added question without a consumer); FR-023/FR-024 -> SC-009 fixture (compliance asked, five lines with defaults, hand-forward incl. "not stated"); FR-025 -> the iteration 001 parity and FR-005 tests still pass, extractor counts change by exactly the added questions; every existing workshop test run locally and in CI. Post-implementation evidence (`quality/quality-evidence.md`): the length and consumer test was red first at T018 (`b29ba4e5`) and green at T025 (`0b3fc589`); SC-009 is checked fact by fact against FR-023 and FR-024 since `598d0836`, with the reviewer's swap proven on a copy of the real catalog; the extractor counts grew by exactly the added questions (SC-010) and lens-order-parity passes; the screened workshop set ran 32 of 32 at T025 and again before each push after it, the last on `57f14996`; all three workflows are green on `00273e84` and `57f14996`. Review round 2 (`run-20261114-205542888-e1efcdea`) found nothing. | `true` | Each check has a positive and a negative case and is proven able to fail before it is trusted. | `—` |
| `operational-resilience-concerns` | `operability` | `not-applicable` | `not-applicable` | `not-needed` | `—` | `false` | No server, SLO, telemetry pipeline or on-call surface: lens text, the spec template and tests, delivered through the existing deploy scripts and CI. | `—` |

## Lens Activation (Planning Baseline)

| Lens Ref | Activation | Planned Evidence Path |
| --- | --- | --- |
| `security-baseline@v1.0.0` | required | `specs/205-workshop-lens-order/iterations/002/quality/lenses/security-baseline.md` |
| `robustness-baseline@v1.0.0` | required | `specs/205-workshop-lens-order/iterations/002/quality/lenses/robustness-baseline.md` |
| `test-integrity@v1.0.0` | required | `specs/205-workshop-lens-order/iterations/002/quality/lenses/test-integrity.md` |

## Notes

- Replace every `<placeholder>` and every angle-bracketed instruction with iteration-specific content before crossing the `before-implement` boundary.
- After every row in the table is filled in with a canonical Status, flip the metadata `Overall Verdict` to `ready` (if every concern is `addressed` / `not-applicable` / `deferred-with-approval`) or keep `blocked`.
- Runtime evidence (lens execution, test counts, mechanical-findings results) is collected after implementation lands; the gate is a PLANNING-time artifact and that deferral is intentional.
